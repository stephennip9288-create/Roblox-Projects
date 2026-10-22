"""Reproduce dry physical recording candidates. No Roblox upload, IDs or Config writes."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import urllib.request
import wave
import zipfile

import numpy as np
from scipy.signal import resample_poly

HERE = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def decode(data):
    raw = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', 'pipe:0', '-ac', '1', '-ar', '48000',
        '-f', 'f32le', 'pipe:1'], input=data)
    samples = np.frombuffer(raw, dtype='<f4').astype(np.float64)
    if not len(samples) or not np.isfinite(samples).all():
        raise ValueError('Invalid source PCM')
    return samples


def prepare(cache, output, fetch=False):
    sources = json.loads((HERE / 'SUPPLEMENTAL-SOURCES.json').read_text())
    recipes = json.loads((HERE / 'SUPPLEMENTAL-RECIPES.json').read_text())
    cache.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    wav_dir, ogg_dir = output / 'WAV', output / 'Auditions'
    wav_dir.mkdir(exist_ok=True); ogg_dir.mkdir(exist_ok=True)
    archives = {}
    for name in ('wood', 'scrapes'):
        source = sources[name]; path = cache / source['cache_name']
        if not path.exists() and fetch:
            with urllib.request.urlopen(source['download_url'], timeout=40) as stream:
                path.write_bytes(stream.read())
        data = path.read_bytes()
        if len(data) != source['bytes'] or sha(data) != source['sha256']:
            raise ValueError('Pinned source mismatch: ' + name)
        archives[name] = zipfile.ZipFile(io.BytesIO(data))
    existing = json.loads((HERE / '../audio-quality-b11/RECORDINGS.json').read_text())['recordings']
    expected = {item['name'] + '.ogg': item['audition_sha256'] for item in existing}
    records = []
    for recipe in recipes:
        layers, ingredients = [], []
        for spec in recipe['layers']:
            if spec['source'] == 'existing_contact':
                raw = (HERE / sources['existing_contact']['path'] / spec['member']).read_bytes()
                if sha(raw) != expected[spec['member']]:
                    raise ValueError('Existing contact pin mismatch')
            else:
                raw = archives[spec['source']].read(spec['member'])
            pcm = decode(raw); peak = float(np.max(np.abs(pcm)))
            # Cut only leading silence, preserve original speed, retain a short
            # anti-click ramp. The timeline is the gameplay caller's authority.
            nonquiet = np.flatnonzero(np.abs(pcm) >= max(.0001, peak * .015))
            start = max(0, int(nonquiet[0]) - 96) if len(nonquiet) else 0
            pcm = pcm[start:start + int(spec['max_seconds'] * 48000)].copy()
            ramp = min(48, len(pcm) // 4)
            pcm[:ramp] *= np.linspace(0, 1, ramp)
            pcm[-min(240, len(pcm)): ] *= np.linspace(1, 0, min(240, len(pcm)))
            pcm *= spec['gain']
            offset = round(spec['offset'] * 48000)
            layers.append((offset, pcm))
            ingredients.append(dict(spec, member_sha256=sha(raw), source_trim_seconds=start / 48000))
        mixed = np.zeros(max(offset + len(pcm) for offset, pcm in layers))
        for offset, pcm in layers:
            mixed[offset:offset + len(pcm)] += pcm
        peak = float(np.max(np.abs(mixed)))
        gain = .48 / peak
        mixed *= gain
        quantized = np.round(mixed * 32767).astype('<i2')
        true_peak = float(np.max(np.abs(resample_poly(quantized.astype(np.float64) / 32768, 4, 1))))
        if true_peak > .56 or np.max(np.abs(quantized.astype(np.int32))) >= 32767:
            raise ValueError('Peak check failed: ' + recipe['name'])
        name = recipe['name']; wav_path = wav_dir / (name + '.wav'); ogg_path = ogg_dir / (name + '.ogg')
        with wave.open(str(wav_path), 'wb') as stream:
            stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(48000)
            stream.writeframes(quantized.tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav_path), '-c:a', 'libvorbis', '-q:a', '5', str(ogg_path)], check=True)
        records.append({
            'name': name, 'role': recipe['role'], 'proposed_slots': recipe['proposed_slots'],
            'ingredients': ingredients, 'master_gain_db': round(20 * np.log10(gain), 4),
            'seconds': len(quantized) / 48000, 'channels': 1, 'sample_rate': 48000, 'pcm_bits': 16,
            'wav_sha256': sha(wav_path.read_bytes()), 'ogg_sha256': sha(ogg_path.read_bytes()),
            'wav_bytes': wav_path.stat().st_size, 'ogg_bytes': ogg_path.stat().st_size,
            'true_peak_dbfs_4x': round(20 * np.log10(true_peak), 4), 'clipped_samples': 0,
            'roblox_asset_id': None, 'creator_reviewed': False, 'moderation_approved': False,
            'sample_listening_approved': False, 'experience_permission_verified': False,
            'permission_universe_id': '10771141095', 'license': 'CC0-1.0', 'activated': False,
        })
    report = {'source_base': 'c80d55aeeae4b51ef8d836949a33bf440890c6b7', 'recordings': records,
              'roblox_uploaded': False, 'native_listening': False,
              'ffmpeg': subprocess.check_output(['ffmpeg', '-version'], text=True).splitlines()[0]}
    (output / 'SUPPLEMENTAL-RECORDINGS.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args()
    report = prepare(args.cache, args.output, args.fetch)
    print('Prepared', len(report['recordings']), 'candidates; no upload or activation.')
