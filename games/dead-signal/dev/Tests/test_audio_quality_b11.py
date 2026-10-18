"""Audio scope, source/asset inventory and actual prepared PCM checks; no network or upload."""
import argparse
import array
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest
import wave

DEV = Path(__file__).resolve().parents[1]
REVIEW = DEV / 'Reviews/audio-quality-b11'
WAV_DIR = None


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


class AudioQualityB11(unittest.TestCase):
    def test_frozen_baseline_and_effects_ownership(self):
        before = (DEV / 'Tests/Fixtures/Effects-audio-b11-before.txt').read_bytes()
        self.assertEqual(blob(before), 'fb7601ac0d1250639f8f51a34434e0e632328943')
        after = (DEV / 'Source/Runtime/client/Effects.lua').read_bytes()
        start, end = b'-- AUDIO-ONLY INLINE IMPLEMENTATION.', b'function FX:part('
        self.assertEqual(before[:before.index(start)], after[:after.index(start)])
        self.assertEqual(before[before.index(end):], after[after.index(end):])
        self.assertNotEqual(before, after)
        block = after[after.index(start):after.index(end)]
        for forbidden in [b'FireServer', b'InvokeServer', b'DataStore', b'LoadAsset', b'InsertService']:
            self.assertNotIn(forbidden, block)

    def test_other_sixty_runtime_records_are_identical(self):
        baseline = json.loads((REVIEW / 'BASELINE-RUNTIME.json').read_text())
        current = {str(p.relative_to(DEV)): p for p in (DEV / 'Source/Runtime').rglob('*.lua')}
        self.assertEqual(set(current), set(baseline)); self.assertEqual(len(current), 61)
        for name, path in current.items():
            if name != 'Source/Runtime/client/Effects.lua':
                self.assertEqual(blob(path.read_bytes()), baseline[name], name)

    def test_primary_provenance_and_license_inventory(self):
        sources = json.loads((REVIEW / 'SOURCES.json').read_text()); self.assertEqual(len(sources), 22)
        for name, item in sources.items():
            with self.subTest(source=name):
                self.assertEqual(item['license'], 'CC0-1.0')
                self.assertEqual(item['license_url'], 'https://creativecommons.org/publicdomain/zero/1.0/')
                self.assertTrue(item['page'].startswith(('https://opengameart.org/content/', 'https://kenney.nl/assets/')))
                self.assertTrue(item['download_url'].startswith(('https://opengameart.org/sites/default/files/', 'https://kenney.nl/media/')))
                self.assertTrue(item['author'] and item['provenance']); self.assertRegex(item['sha256'], r'^[a-f0-9]{64}$')
                self.assertGreater(item['bytes'], 0); self.assertFalse(item['roblox_upload'] or item['experience_permission_verified'])

    def test_every_recipe_matches_a_real_prepared_record(self):
        sources = json.loads((REVIEW / 'SOURCES.json').read_text())
        recipes = json.loads((REVIEW / 'RECORDING-RECIPES.json').read_text())
        report = json.loads((REVIEW / 'RECORDINGS.json').read_text())
        records = {r['name']: r for r in report['recordings']}
        self.assertEqual(len(recipes), len(records)); self.assertEqual(len(records), 84)
        self.assertFalse(report['uploaded'] or report['native_listening'])
        for recipe in recipes:
            record = records[recipe['name']]; self.assertIn(recipe['source'], sources)
            for key, value in recipe.items():
                if key == 'seconds':
                    self.assertGreater(record[key], 0); self.assertLessEqual(record[key], value)
                else:
                    self.assertEqual(record[key], value)
            for flag in ['creator_approved', 'permissions_verified', 'listening_approved']:
                self.assertFalse(record[flag], recipe['name'])
            self.assertIsNone(record['roblox_asset_id'])
            self.assertEqual((record['channels'], record['sample_rate'], record['pcm_bits']), (1, 48000, 16))
            self.assertEqual(record['clipped_samples'], 0); self.assertLessEqual(record['true_peak_dbfs_4x'], -5)

    def test_discharge_variants_are_recordings_not_pitch_placeholders(self):
        recipes = json.loads((REVIEW / 'RECORDING-RECIPES.json').read_text())
        for family in ['Pistol', 'Rifle', 'SMG', 'Shotgun', 'Heavy', 'Sniper']:
            for side in ['near', 'far']:
                matches = [r for r in recipes if f'{family}.{side}' in r['slots']]
                self.assertGreaterEqual(len(matches), 2, family + side)
                for item in matches:
                    self.assertEqual(item['source'], 'firearms'); self.assertIn('Prepared SFX Library/', item['member'])
                    self.assertNotIn('pitch', item); self.assertNotIn('synthesis', item)

    def test_audition_files_match_the_inventory(self):
        records = json.loads((REVIEW / 'RECORDINGS.json').read_text())['recordings']
        self.assertEqual({p.name for p in (REVIEW / 'Auditions').glob('*.ogg')}, {r['name'] + '.ogg' for r in records})
        for item in records:
            data = (REVIEW / 'Auditions' / (item['name'] + '.ogg')).read_bytes()
            self.assertTrue(data.startswith(b'OggS')); self.assertEqual(hashlib.sha256(data).hexdigest(), item['audition_sha256'])

    def test_complete_event_fallback_audit(self):
        events = json.loads((REVIEW / 'EVENT-INVENTORY.json').read_text())
        self.assertEqual(len(events), len({r['key'] for r in events})); self.assertEqual(len(events), 100)
        for item in events:
            self.assertFalse(item['configured'], item['key'])
            self.assertTrue(item['fallback'] == 'silent-until-upload' or item['fallback'].startswith('rbxasset://sounds/'))
        self.assertTrue({'Hound.Attack', 'Hound.Breath', 'Enemy.Entry.Contact', 'Enemy.Entry.Land', 'Weapon.Magazine', 'World.Frost.wind'} <= {r['key'] for r in events})

    def test_activation_refuses_unapproved_or_wrong_experience_assets(self):
        spec = importlib.util.spec_from_file_location('audio_bindings_b11', REVIEW / 'emit_bindings.py')
        helper = importlib.util.module_from_spec(spec); spec.loader.exec_module(helper)
        uploads = helper.template(); result, blocked = helper.proposal(uploads)
        self.assertIsNone(result); self.assertEqual(len(blocked), 84)
        first = next(iter(uploads))
        # Arbitrary fixture only; never a real Roblox asset or runtime value.
        uploads[first].update(asset_id='19001', creator_reviewed=True, moderation_approved=True,
                              sample_listening_approved=True, experience_permission_verified=True, permission_universe_id='10770732078')
        result, _ = helper.proposal(uploads, allow_partial=True); self.assertNotIn('rbxassetid://19001', result)
        uploads[first]['permission_universe_id'] = helper.STAGING_UNIVERSE
        result, _ = helper.proposal(uploads, allow_partial=True); self.assertIn('rbxassetid://19001', result)
        uploads[first]['wav_sha256'] = 'wrong file'
        result, _ = helper.proposal(uploads, allow_partial=True); self.assertNotIn('rbxassetid://19001', result)

    def test_prepared_wav_fidelity_and_transient_timing(self):
        if WAV_DIR is None:
            self.skipTest('Pass --wav-dir to test actual prepared PCM')
        for item in json.loads((REVIEW / 'RECORDINGS.json').read_text())['recordings']:
            path = WAV_DIR / (item['name'] + '.wav')
            with self.subTest(recording=item['name']):
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), item['wav_sha256'])
                with wave.open(str(path)) as stream:
                    self.assertEqual((stream.getnchannels(), stream.getsampwidth(), stream.getframerate()), (1, 2, 48000))
                    pcm = array.array('h', stream.readframes(stream.getnframes()))
                if sys.byteorder != 'little': pcm.byteswap()
                self.assertTrue(pcm and max(abs(x) for x in pcm) < 32767)
                if item['source'] == 'firearms':
                    threshold = max(abs(x) for x in pcm) * .15
                    onset = next(i for i, x in enumerate(pcm) if abs(x) >= threshold) / 48000
                    self.assertLess(onset, .035, 'File leading silence must not delay acknowledged discharge')
                    self.assertLess(item['seconds'], 4, 'Report tail fits catalog TTL')
                raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-af', 'aresample=192000', '-f', 'f32le', '-'])
                values = array.array('f', raw)
                if sys.byteorder != 'little': values.byteswap()
                self.assertLess(max(abs(x) for x in values), .57, 'Independent 4x PCM peak check')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--wav-dir', type=Path)
    args, rest = parser.parse_known_args(); WAV_DIR = args.wav_dir
    unittest.main(argv=[sys.argv[0], *rest])
