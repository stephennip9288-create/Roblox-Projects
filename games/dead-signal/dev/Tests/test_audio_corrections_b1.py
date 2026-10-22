"""Audio scope and actual supplemental PCM/provenance; no network or Roblox upload."""
import argparse
import array
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import wave

DEV = Path(__file__).resolve().parents[1]
REVIEW = DEV / 'Reviews/audio-corrections-b1'
ORIGINAL = DEV / 'Reviews/audio-quality-b11'
SOURCE_CACHE = None


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


class AudioCorrections(unittest.TestCase):
    def test_only_owned_audio_bytes_change(self):
        base = json.loads((REVIEW / 'BASELINE-RUNTIME.json').read_text())
        current = {str(p.relative_to(DEV)): p for p in (DEV / 'Source/Runtime').rglob('*.lua')}
        self.assertEqual(set(base), set(current)); self.assertEqual(len(current), 61)
        for name, path in current.items():
            if name != 'Source/Runtime/client/Effects.lua':
                self.assertEqual(blob(path.read_bytes()), base[name], name)
        before = (DEV / 'Tests/Fixtures/Effects-audio-corrections-before.txt').read_bytes()
        self.assertEqual(blob(before), '4f8f6613c7a87eaf81f782605145be3739a1b25e')
        after = current['Source/Runtime/client/Effects.lua'].read_bytes()
        start, end = b'-- AUDIO-ONLY INLINE IMPLEMENTATION.', b'function FX:part('
        self.assertEqual(before[:before.index(start)], after[:after.index(start)])
        self.assertEqual(before[before.index(end):], after[after.index(end):])
        self.assertNotEqual(before, after)

    def test_owner_ids_and_84_original_recordings_unchanged(self):
        config = (DEV / 'Source/Runtime/shared/Config.lua').read_bytes()
        self.assertEqual(blob(config), '1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2')
        uploads = (ORIGINAL / 'OWNER-UPLOADS-UNVERIFIED.json').read_bytes()
        self.assertEqual(blob(uploads), '94aac65175bbe8790b5740f6c9fb288e6e71ebbd')
        for row in json.loads((ORIGINAL / 'RECORDINGS.json').read_text())['recordings']:
            data = (ORIGINAL / 'Auditions' / (row['name'] + '.ogg')).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), row['audition_sha256'], row['name'])

    def test_supplemental_provenance_and_unapproved_status(self):
        sources = json.loads((REVIEW / 'SUPPLEMENTAL-SOURCES.json').read_text())
        recipes = json.loads((REVIEW / 'SUPPLEMENTAL-RECIPES.json').read_text())
        report = json.loads((REVIEW / 'SUPPLEMENTAL-RECORDINGS.json').read_text())
        self.assertEqual(len(recipes), 14); self.assertEqual(len(report['recordings']), 14)
        self.assertFalse(report['roblox_uploaded'] or report['native_listening'])
        for name in ['wood', 'scrapes']:
            row = sources[name]
            self.assertEqual(row['license'], 'CC0-1.0'); self.assertTrue(row['author'])
            self.assertTrue(row['page'].startswith('https://opengameart.org/content/'))
            self.assertTrue(row['download_url'].startswith('https://opengameart.org/sites/default/files/'))
            self.assertRegex(row['sha256'], '^[a-f0-9]{64}$')
        by_name = {r['name']: r for r in recipes}
        for row in report['recordings']:
            self.assertIn(row['name'], by_name)
            self.assertEqual(row['proposed_slots'], by_name[row['name']]['proposed_slots'])
            self.assertIsNone(row['roblox_asset_id'])
            self.assertEqual(row['permission_universe_id'], '10771141095')
            for field in ['creator_reviewed', 'moderation_approved', 'sample_listening_approved', 'experience_permission_verified', 'activated']:
                self.assertFalse(row[field], field)
            self.assertEqual(row['clipped_samples'], 0)
            for ingredient in row['ingredients']:
                self.assertIn(ingredient['source'], sources)
                self.assertRegex(ingredient['member_sha256'], '^[a-f0-9]{64}$')

    def test_all_14_wavs_and_oggs_match_exact_inventory(self):
        rows = json.loads((REVIEW / 'SUPPLEMENTAL-RECORDINGS.json').read_text())['recordings']
        self.assertEqual({r['name'] + '.wav' for r in rows}, {p.name for p in (REVIEW / 'WAV').glob('*.wav')})
        self.assertEqual({r['name'] + '.ogg' for r in rows}, {p.name for p in (REVIEW / 'Auditions').glob('*.ogg')})
        for row in rows:
            for ext, directory, field in [('wav', 'WAV', 'wav_sha256'), ('ogg', 'Auditions', 'ogg_sha256')]:
                data = (REVIEW / directory / (row['name'] + '.' + ext)).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), row[field], row['name'])

    def test_actual_pcm_and_independent_4x_peak(self):
        for row in json.loads((REVIEW / 'SUPPLEMENTAL-RECORDINGS.json').read_text())['recordings']:
            path = REVIEW / 'WAV' / (row['name'] + '.wav')
            with self.subTest(name=row['name']):
                with wave.open(str(path)) as stream:
                    self.assertEqual((stream.getnchannels(), stream.getsampwidth(), stream.getframerate()), (1, 2, 48000))
                    pcm = array.array('h', stream.readframes(stream.getnframes()))
                if sys.byteorder != 'little': pcm.byteswap()
                self.assertTrue(pcm); self.assertLess(max(abs(x) for x in pcm), 32767)
                self.assertLess(path.stat().st_size, 1000000)
                self.assertAlmostEqual(len(pcm) / 48000, row['seconds'])
                raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-af', 'aresample=192000', '-f', 'f32le', '-'])
                oversampled = array.array('f', raw)
                if sys.byteorder != 'little': oversampled.byteswap()
                self.assertLess(max(abs(x) for x in oversampled), .57)
                if row['name'].startswith(('board_fracture_', 'window_contact_')):
                    threshold = max(abs(x) for x in pcm) * .10
                    onset = next(i for i, x in enumerate(pcm) if abs(x) >= threshold) / 48000
                    self.assertLess(onset, .040, 'Edited-file onset only; not engine timing')

    def test_reproduce_all_14_pcm_files_from_pinned_sources(self):
        if SOURCE_CACHE is None:
            self.skipTest('Supply --source-cache for exact PCM reproduction')
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([sys.executable, str(REVIEW / 'prepare_supplemental.py'), '--cache', str(SOURCE_CACHE), '--output', tmp], check=True, capture_output=True)
            rows = json.loads((REVIEW / 'SUPPLEMENTAL-RECORDINGS.json').read_text())['recordings']
            for row in rows:
                data = (Path(tmp) / 'WAV' / (row['name'] + '.wav')).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), row['wav_sha256'], row['name'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--source-cache', type=Path)
    args, rest = parser.parse_known_args(); SOURCE_CACHE = args.source_cache
    unittest.main(argv=[sys.argv[0], *rest])
