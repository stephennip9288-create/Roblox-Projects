"""Build pinned CC0 review/upload candidates. Never uploads or edits runtime Config.

Needs numpy/scipy, ffmpeg/ffprobe and Linux libarchive for 7z sources.
--fetch downloads only SOURCES.json entries and verifies exact byte/hash pins.
"""
import argparse
import ctypes as c
import hashlib
import html
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import urllib.request
import wave
import zipfile

import numpy as np
from scipy.signal import resample_poly

ROOT = Path(__file__).resolve().parent
RATE = 48000


def sha(data):
    return hashlib.sha256(data).hexdigest()


def archive_member(path, name):
    assert not PurePosixPath(name).is_absolute() and '..' not in PurePosixPath(name).parts
    if path.suffix == '.zip':
        with zipfile.ZipFile(path) as archive:
            assert archive.getinfo(name).file_size < 100 * 1024 * 1024
            return archive.read(name)
    lib = c.CDLL('libarchive.so.13'); ptr = c.c_void_p
    lib.archive_read_new.restype = ptr
    for key, args in {
        'archive_read_support_filter_all': [ptr], 'archive_read_support_format_all': [ptr],
        'archive_read_open_filename': [ptr, c.c_char_p, c.c_size_t],
        'archive_read_next_header': [ptr, c.POINTER(ptr)], 'archive_read_data_skip': [ptr],
        'archive_read_data': [ptr, c.c_void_p, c.c_size_t], 'archive_read_free': [ptr],
        'archive_entry_pathname': [ptr],
    }.items():
        getattr(lib, key).argtypes = args
    lib.archive_read_data.restype = c.c_ssize_t
    lib.archive_entry_pathname.restype = c.c_char_p
    archive = lib.archive_read_new()
    try:
        lib.archive_read_support_filter_all(archive); lib.archive_read_support_format_all(archive)
        assert lib.archive_read_open_filename(archive, str(path).encode(), 65536) == 0
        entry = ptr()
        while lib.archive_read_next_header(archive, c.byref(entry)) == 0:
            if lib.archive_entry_pathname(entry).decode() != name:
                lib.archive_read_data_skip(archive); continue
            output = bytearray(); buffer = c.create_string_buffer(65536)
            while True:
                count = lib.archive_read_data(archive, buffer, 65536)
                assert count >= 0, 'Corrupt archive'
                if not count:
                    return bytes(output)
                output.extend(buffer.raw[:count]); assert len(output) < 100 * 1024 * 1024
        raise ValueError('Missing member: ' + name)
    finally:
        lib.archive_read_free(archive)


def decode(data):
    info = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-of', 'json', '-i', 'pipe:0'], input=data))
    channels = next(s['channels'] for s in info['streams'] if s['codec_type'] == 'audio')
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', 'pipe:0', '-ar', str(RATE), '-f', 'f32le', '-'], input=data)
    # Explicit arithmetic mono downmix, avoiding the default +3dB stereo matrix.
    return np.frombuffer(pcm, '<f4').reshape(-1, channels).mean(axis=1).astype(np.float64)


def shot_onsets(samples):
    size = 480
    envelope = np.max(np.pad(np.abs(samples), (0, (-len(samples)) % size)).reshape(-1, size), axis=1)
    starts = []
    for frame in np.flatnonzero(envelope > envelope.max() * .45):
        at = int(frame * size)
        if not starts or at - starts[-1] > RATE * 1.5:
            starts.append(at)
    return starts


def render(samples, recipe):
    start = int(recipe.get('start', 0) * RATE)
    if 'take' in recipe:
        starts = shot_onsets(samples)
        assert len(starts) >= recipe['take'], ('Missing separate recorded shot', starts)
        start = max(0, starts[recipe['take'] - 1] - int(.008 * RATE))
    length = int(recipe.get('seconds', min(2.5, len(samples) / RATE)) * RATE)
    if recipe.get('loop'):
        overlap = int(.35 * RATE); working = samples[start:]
        assert len(working) > RATE * .1
        working = np.tile(working, int(np.ceil((length + overlap) / len(working))))[:length + overlap]
        output = working[overlap:].copy(); blend = np.linspace(0, 1, overlap)
        output[-overlap:] = working[-overlap:] * (1 - blend) + working[:overlap] * blend
    else:
        output = samples[start:start + length].copy(); assert len(output) > 100
        output -= output.mean()
        fade_in = min(int(.002 * RATE), len(output) // 4); fade_out = min(int(.04 * RATE), len(output) // 4)
        output[:fade_in] *= np.linspace(0, 1, fade_in); output[-fade_out:] *= np.linspace(1, 0, fade_out)
    output -= output.mean()
    true_peak = float(np.max(np.abs(resample_poly(output, 4, 1))))
    rms = float(np.sqrt(np.mean(output * output)))
    assert true_peak > .000001, 'Silent source/cut'
    gain = recipe.get('peak', .5) / true_peak
    if recipe.get('loop'):
        gain = min(gain, .065 / max(rms, .000001))
    output *= gain
    pcm = np.rint(output * 32767).clip(-32767, 32767).astype('<i2'); data = io.BytesIO()
    with wave.open(data, 'wb') as stream:
        stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(RATE); stream.writeframes(pcm.tobytes())
    return data.getvalue(), {
        'seconds': round(len(pcm) / RATE, 6), 'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16,
        'source_start_seconds': round(start / RATE, 6), 'master_gain_db': round(20 * np.log10(gain), 3),
        'peak_dbfs': round(20 * np.log10(max(abs(pcm.astype(np.float64))) / 32768), 3),
        'true_peak_dbfs_4x': round(20 * np.log10(float(np.max(np.abs(resample_poly(pcm.astype(np.float64) / 32768, 4, 1))))), 3),
        'rms_dbfs': round(float(20 * np.log10(np.sqrt(np.mean((pcm / 32768) ** 2)))), 3),
        'clipped_samples': int(np.sum(np.abs(pcm.astype(np.int32)) >= 32767)),
        'loop_seam_delta': round(abs(int(pcm[0]) - int(pcm[-1])) / 32768, 6) if recipe.get('loop') else None,
    }


def build(cache, output, fetch=False):
    sources = json.loads((ROOT / 'SOURCES.json').read_text()); recipes = json.loads((ROOT / 'RECORDING-RECIPES.json').read_text())
    cache.mkdir(parents=True, exist_ok=True); recordings = {}
    for key, spec in sources.items():
        path = cache / spec['cache_name']
        if not path.exists() and fetch:
            request = urllib.request.Request(spec['download_url'], headers={'User-Agent': 'DeadSignal-AudioReview/1.1'})
            with urllib.request.urlopen(request, timeout=120) as response, path.with_suffix('.part').open('wb') as stream:
                total = 0
                while chunk := response.read(1024 * 1024):
                    total += len(chunk); assert total <= spec['bytes'], 'Changed/oversize source'
                    stream.write(chunk)
            path.with_suffix('.part').replace(path)
        data = path.read_bytes()
        assert len(data) == spec['bytes'] and sha(data) == spec['sha256'], 'Source hash mismatch: ' + key
        recordings[key] = path
    (output / 'WAV').mkdir(parents=True, exist_ok=True); (output / 'Auditions').mkdir(exist_ok=True)
    decoded = {}; result = []
    for index, spec in enumerate(recipes, 1):
        identity = (spec['source'], spec.get('member'))
        if identity not in decoded:
            path = recordings[spec['source']]
            raw = archive_member(path, spec['member']) if spec.get('member') else path.read_bytes()
            decoded[identity] = (decode(raw), sha(raw))
        samples, member_hash = decoded[identity]; data, stats = render(samples, spec); name = spec['name']
        assert name.replace('_', '').replace('-', '').isalnum()
        wav = output / 'WAV' / (name + '.wav'); wav.write_bytes(data)
        audition = output / 'Auditions' / (name + '.ogg')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav), '-map_metadata', '-1', '-fflags', '+bitexact',
                        '-flags:a', '+bitexact', '-c:a', 'libvorbis', '-q:a', '4', str(audition)], check=True)
        result.append({**spec, **stats, 'source_member_sha256': member_hash, 'wav_sha256': sha(data),
                       'audition_sha256': sha(audition.read_bytes()), 'wav_bytes': len(data), 'roblox_asset_id': None,
                       'creator_approved': False, 'permissions_verified': False, 'listening_approved': False,
                       'license': sources[spec['source']]['license']})
        if index % 20 == 0:
            print('Prepared', index, 'recordings', flush=True)
    report = {'recordings': result, 'native_listening': False, 'uploaded': False,
              'ffmpeg': subprocess.check_output(['ffmpeg', '-version'], text=True).splitlines()[0]}
    (output / 'RECORDINGS.json').write_text(json.dumps(report, indent=2) + '\n')
    cards = []
    for item in result:
        name = html.escape(item['name'])
        cards.append(f'<article><h2>{name}</h2><p>{html.escape(item["role"])}</p><audio controls preload="none" src="Auditions/{name}.ogg"></audio><p>{item["seconds"]}s · CC0 · review candidate · not uploaded</p></article>')
    (output / 'LISTEN.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Dead Signal audio review</title><style>body{font:16px system-ui;max-width:900px;margin:32px auto;padding:0 16px;background:#10171b;color:#e7edef}article{padding:16px;margin:12px 0;background:#1e2b33;border-radius:8px}h2{font-size:18px}audio{width:100%}p{line-height:1.5}</style><h1>Dead Signal Batch 1.1 · recording review</h1><p>These are prepared CC0 recording candidates, not the Roblox mix. Use moderate listening volume. No asset is uploaded or approved.</p>' + ''.join(cards) + '</html>')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True); parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args(); report = build(args.cache, args.output, args.fetch)
    print('Prepared recording candidates:', len(report['recordings']), 'No uploads or runtime changes.')
