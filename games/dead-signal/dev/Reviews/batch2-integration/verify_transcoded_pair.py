"""Supplement two inconclusive strict comparisons; original criteria stay intact.

Local/private inputs only. Decode to 48 kHz stereo and examine a fixed 100–6000 Hz
band, both full tracks and non-silent half-second segments, with zero alignment
change. Reject unrelated physical sources and phase-scrambled spectral controls.
This checks content correspondence, not byte equality, moderation or engine QA.
Requires ffmpeg, numpy and scipy; it never uploads or changes Config.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np
from scipy.signal import butter, sosfiltfilt

HERE = Path(__file__).resolve().parent
TARGETS = {'101059835221623': 'cinderworks_steam_release_1',
           '92629845353488': 'infected_clothing_drag_1'}
CRITERIA = {'band_hz': [100, 6000], 'sample_rate': 48000, 'filter_order': 6,
            'minimum_full_channel_correlation': .98,
            'minimum_half_second_segment_channel_correlation': .95,
            'minimum_source_frame_coverage': .99,
            'maximum_absolute_negative_control_correlation': .30,
            'minimum_positive_negative_correlation_margin': .60}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decode(path):
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
                                   '-ar', '48000', '-ac', '2', '-f', 'f32le', '-'])
    return np.frombuffer(raw, dtype='<f4').reshape(-1, 2).astype(np.float64)


def correlation(a, b):
    a = a - a.mean(axis=0)
    b = b - b.mean(axis=0)
    denominator = np.sqrt(np.sum(a*a, axis=0) * np.sum(b*b, axis=0))
    return np.divide(np.sum(a*b, axis=0), denominator,
                     out=np.zeros(2), where=denominator > 1e-15)


def main(originals, hosted, output):
    source = json.loads((HERE/'AUDIO-SOURCE-REVIEW.json').read_text())
    strict = {r['roblox_asset_id']: r for r in json.loads(
        (HERE/'HOSTED-CONTENT-COMPARISON.json').read_text())['recordings']}
    physical = {}
    for row in source['physical_recordings']:
        path = originals/row['filename']
        assert sha(path) == row['sha256'], 'Private original differs: '+path.name
        physical[path.stem] = decode(path)
    filt = butter(CRITERIA['filter_order'], CRITERIA['band_hz'],
                  btype='bandpass', fs=48000, output='sos')
    band = {n: sosfiltfilt(filt, a, axis=0) for n, a in physical.items()}
    results = []
    for asset_id, name in TARGETS.items():
        path = hosted/(name+'.hosted')
        assert sha(path) == strict[asset_id]['hosted_sha256'], 'Hosted revision changed'
        x = physical[name]
        y = decode(path)
        # Earlier strict analysis found zero lag; do not optimize a new alignment.
        assert strict[asset_id]['lag_samples_48000'] == 0
        length = min(len(x), len(y))
        a = band[name][:length]
        b = sosfiltfilt(filt, y, axis=0)[:length]
        full = correlation(a, b)
        segments = []
        for start in range(0, length, 24000):
            end = min(start+24000, length)
            if end-start < 12000 or np.sqrt(np.mean(a[start:end]**2)) < 1e-5:
                continue
            segments.append({'start_seconds': start/48000, 'end_seconds': end/48000,
                             'channel_correlations': correlation(a[start:end], b[start:end]).tolist()})
        controls = []
        for other, reference in band.items():
            if other == name:
                continue
            size = min(length, len(reference))
            controls.append({'kind': 'different owner physical recording', 'name': other,
                             'channel_correlations': correlation(reference[:size], b[:size]).tolist()})
        rng = np.random.default_rng(620205)
        spectrum = np.fft.rfft(a, axis=0)
        randomized = np.fft.irfft(np.abs(spectrum)*np.exp(1j*rng.uniform(
            -np.pi, np.pi, spectrum.shape)), n=length, axis=0)
        controls.append({'kind': 'same spectrum / randomized phase',
                         'channel_correlations': correlation(randomized, b).tolist()})
        worst_negative = max(abs(c) for r in controls for c in r['channel_correlations'])
        worst_segment = min(c for r in segments for c in r['channel_correlations']) if segments else 0
        coverage = length/len(x)
        passed = bool(min(full) >= CRITERIA['minimum_full_channel_correlation']
                      and worst_segment >= CRITERIA['minimum_half_second_segment_channel_correlation']
                      and coverage >= CRITERIA['minimum_source_frame_coverage']
                      and worst_negative <= CRITERIA['maximum_absolute_negative_control_correlation']
                      and min(full)-worst_negative >= CRITERIA['minimum_positive_negative_correlation_margin'])
        results.append({'asset_id': asset_id, 'name': name, 'source_sha256': strict[asset_id]['source_sha256'],
                        'hosted_sha256': sha(path), 'original_strict_comparison': strict[asset_id],
                        'original_strict_pass_unchanged': strict[asset_id]['decoded_content_match'],
                        'alignment_samples_48000': 0, 'source_coverage': coverage,
                        'band_limited_channel_correlations': full.tolist(),
                        'worst_segment_correlation': worst_segment,
                        'strongest_absolute_negative_control_correlation': worst_negative,
                        'segments': segments, 'negative_controls': controls,
                        'supplemental_content_correspondence_passed': passed,
                        'byte_identical': False, 'native_playback_verified': False})
    report = {'schema': 1, 'observed_at': datetime.now(timezone.utc).isoformat(),
              'kind': 'supplemental-transcode-aware-content-correspondence',
              'criteria_fixed_before_execution': CRITERIA,
              'original_strict_criteria_or_results_modified': False,
              'method': 'Both channels, full tracks and half-second segments in fixed 100–6000 Hz band; six negative controls per target; same original/hosted hashes; no new time-shift fitting.',
              'limitations': ['Does not prove compressed-byte identity or preservation above 6 kHz.',
                              'Does not establish Roblox moderation, native loading, audibility or gameplay quality.'],
              'records': results}
    output.write_text(json.dumps(report, indent=2)+'\n')
    for r in results:
        print(r['asset_id'], r['name'], 'supplemental_pass', r['supplemental_content_correspondence_passed'],
              'full', r['band_limited_channel_correlations'], 'segment_min', r['worst_segment_correlation'],
              'negative_max', r['strongest_absolute_negative_control_correlation'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--original-dir', required=True, type=Path)
    parser.add_argument('--hosted-dir', required=True, type=Path)
    parser.add_argument('--output', type=Path, default=HERE/'TRANSCODE-CONTENT-RECHECK.json')
    args = parser.parse_args()
    main(args.original_dir, args.hosted_dir, args.output)
