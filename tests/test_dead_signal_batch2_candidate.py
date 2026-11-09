"""Review, preservation, exact-build and fail-closed Batch 2 release boundaries."""
import ast
from copy import deepcopy
import json
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import dead_signal_batch2_candidate as gate


class Batch2Candidate(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (ROOT / gate.MANIFEST).is_file():
            raise unittest.SkipTest('Historical Batch 1 source does not include a Batch 2 intake')
        cls.temp = tempfile.TemporaryDirectory(prefix='dead-signal-b2-gate-tests-')
        cls.root = Path(cls.temp.name)
        cls.doc = gate.manifest()
        paths = set(cls.doc['protected_batch1_files'])
        paths.update(gate.PREFIX + name for name in cls.doc['records'])
        paths.update(str(p.relative_to(ROOT)) for p in (ROOT / gate.REVIEW).rglob('*') if p.is_file())
        for name in paths:
            target = cls.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def corrupt(self, name, data=None):
        path = self.root / name
        old = path.read_bytes()
        try:
            path.write_bytes(data if data is not None else old + b'\n-- unexpected edit\n')
            with self.assertRaises((ValueError, KeyError)):
                gate.verify_tree(self.root)
        finally:
            path.write_bytes(old)

    def test_exact_combined_source_and_all_historical_evidence(self):
        self.assertEqual(len(gate.verify_tree(self.root)['records']), 61)
        self.assertEqual(sum(r['base_blob'] != r['blob_sha'] for r in self.doc['records'].values()), 13)
        self.assertEqual(len(self.doc['protected_batch1_files']), 393)

    def test_each_reviewed_delta_cannot_change_or_revert(self):
        for name, row in self.doc['records'].items():
            if row['base_blob'] != row['blob_sha']:
                with self.subTest(file=name):
                    self.corrupt(gate.PREFIX + name)
                    self.corrupt(gate.PREFIX + name, (self.root / gate.REVIEW / row['baseline_file']).read_bytes())

    def test_unrelated_runtime_and_fixed_inventory_are_protected(self):
        name = next(n for n, r in self.doc['records'].items() if r['base_blob'] == r['blob_sha'])
        self.corrupt(gate.PREFIX + name)
        extra = self.root / gate.PREFIX / 'Source/Runtime/shared/Unreviewed.lua'
        extra.write_text('return {}')
        try:
            with self.assertRaises(ValueError):
                gate.verify_tree(self.root)
        finally:
            extra.unlink()

    def test_historical_ledgers_native_assets_and_recovery_are_immutable(self):
        for name in ('games/dead-signal/dev/Reviews/batch1-1/REVIEWED-RUNTIME.json',
                     'games/dead-signal/dev/Reviews/audio-immersion/Effects-audio.luau',
                     'games/dead-signal/full-baselines/v1.8.0/whiteout.rbxl',
                     'games/dead-signal/releases/recovery-production.json'):
            with self.subTest(path=name):
                self.corrupt(name)

    def test_manifest_baseline_and_audio_evidence_cannot_be_rewritten(self):
        for name in (gate.MANIFEST, gate.REVIEW + 'Baseline/client/Controller.lua.txt',
                     gate.REVIEW + 'AUDIO-INTAKE.json', gate.REVIEW + 'STAGING-GRANTS.csv',
                     gate.REVIEW + 'PRODUCTION-GRANTS.csv', gate.REVIEW + 'CONFIG-POLICY.luau.txt',
                     gate.REVIEW + 'ROBLOX-REVIEW-STATUS.json', gate.REVIEW + 'TRANSCODE-CONTENT-RECHECK.json',
                     gate.REVIEW + 'NATIVE-AUDIO-OWNER-REPORT.json', gate.REVIEW + 'NATIVE-AUDIO-REVIEW.json',
                     gate.REVIEW + 'AUDIO-ACTIVATION-MATRIX.json'):
            with self.subTest(path=name):
                self.corrupt(name)

    def test_separate_rights_content_moderation_and_owner_native_evidence_are_pinned(self):
        intake = gate.verify_audio(require_active=True)
        self.assertEqual(len(intake['recordings']), 16)
        self.assertTrue(all(r['listeningApproved'] for r in intake['recordings']))
        self.assertFalse(intake['owner_listening_reconfirmation_required'])
        self.assertTrue(all(r['rightsCleared'] and r['creatorReviewed'] for r in intake['recordings']))
        self.assertEqual(sum(r['hosted_content_strict_match'] for r in intake['recordings']), 14)
        self.assertTrue(all(r['activated'] is True and r['native_playback_verified'] is True
                            for r in intake['recordings']))
        self.assertEqual(intake['activation_universe_id'], '10771141095')
        self.assertFalse(intake['native_in_game_playback_verified'])
        self.assertTrue(all(r['production_activation_authorized'] is False for r in intake['recordings']))

    def gameplay_fixture(self):
        """Synthetic authorization exercises the gate; never edits a real admission."""
        records = ROOT / 'games/dead-signal/releases'
        row = json.loads((records / gate.GAMEPLAY_RECORD).read_text())
        source = '1' * 40
        row.update(source_sha=source, owner_staging_authorization=True,
                   owner_authorization_evidence='synthetic unit-test evidence',
                   owner_accepts_audio_exclusion=True, ready_for_staging=True,
                   proposal_withdrawn=False)
        import dead_signal_production_admission as admission
        row['ci'] = {family: {'source_sha': source, 'conclusion': 'success', 'run_id': 1}
                     for family in admission.FAMILIES}
        builds = gate.build_record()['builds']['staging']
        row['staging_binary_sha256'] = {p: r['sha256'] for p, r in builds.items()}
        row['staging_binary_bytes'] = {p: r['bytes'] for p, r in builds.items()}
        return row, source, records

    def staging_fixture(self):
        """Synthetic final approval exercises full audio, never approves a real release."""
        row, source, records = self.gameplay_fixture()
        row = json.loads((records / gate.RECORD).read_text())
        row.update(source_sha=source, owner_staging_authorization=True,
                   owner_authorization_evidence='synthetic unit-test evidence', ready_for_staging=True)
        import dead_signal_production_admission as admission
        row['ci'] = {family: {'source_sha': source, 'conclusion': 'success', 'run_id': 1}
                     for family in admission.FAMILIES}
        return row, source, records

    def test_full_audio_gate_accepts_only_explicit_source_authorization_and_all_assets(self):
        row, source, records = self.staging_fixture()
        self.assertEqual(gate.staging_completion(row, source, records), row)
        changes = {'owner_staging_authorization': False,
                   'owner_authorization_evidence': None, 'ready_for_staging': False,
                   'production_authorization': True, 'engine_gameplay_verified': True,
                   'source_sha': 'main', 'release': gate.GAMEPLAY_RELEASE}
        for key, value in changes.items():
            with self.subTest(field=key), self.assertRaises(ValueError):
                gate.staging_completion({**row, key: value}, source, records)
        for key, value in {'enabled_new_assets': 15, 'fully_approved_assets': 15,
                           'activation_universe_id': '10770732078',
                           'rights_and_source_verified': False,
                           'moderation_and_playback_eligible': False}.items():
            mutated = deepcopy(row)
            mutated['audio'][key] = value
            with self.subTest(audio=key), self.assertRaises(ValueError):
                gate.staging_completion(mutated, source, records)

    def test_full_audio_scope_preserves_ci_build_rollback_and_native_evidence_gates(self):
        row, source, records = self.staging_fixture()
        for key, value in {'ci': {}, 'staging_binary_sha256': {}, 'rollback': {}}.items():
            with self.subTest(field=key), self.assertRaises(ValueError):
                gate.staging_completion({**row, key: value}, source, records)
        from datetime import datetime, timezone
        with self.assertRaisesRegex(ValueError, 'Refresh staging rollback'):
            gate.staging_completion(row, source, records,
                                             now=datetime(2027, 1, 20, tzinfo=timezone.utc))
        with patch.object(gate, 'verify_audio', side_effect=ValueError('Unresolved native/source evidence')):
            with self.assertRaisesRegex(ValueError, 'native/source'):
                gate.staging_completion(row, source, records)

    def test_active_policy_cannot_enter_the_withdrawn_disabled_audio_release(self):
        with self.assertRaisesRegex(ValueError, 'disabled Config policy'):
            gate.verify_audio_disabled(self.root)
        row, source, records = self.gameplay_fixture()
        row.update(runtime_manifest_blob=gate.MANIFEST_BLOB, build_manifest_blob=gate.BUILDS_BLOB)
        with self.assertRaisesRegex(ValueError, 'disabled Config policy'):
            gate.gameplay_staging_completion(row, source, records)
        row['proposal_withdrawn'] = True
        with self.assertRaisesRegex(ValueError, 'withdrawn'):
            gate.gameplay_staging_completion(row, source, records)

    def test_real_gameplay_record_requires_every_separate_authorization(self):
        records = ROOT / 'games/dead-signal/releases'
        record = json.loads((records / gate.GAMEPLAY_RECORD).read_text())
        # Main-trusted controls install the final authorization into the selected
        # source before running tests. Legitimate owner approval must not require
        # deleting a test that hard-codes today's unauthorized record forever.
        required = ('owner_staging_authorization', 'owner_accepts_audio_exclusion', 'ready_for_staging')
        if all(record.get(key) is True for key in required):
            gate.gameplay_staging_completion(record, record['source_sha'], records)
        else:
            with self.assertRaises(ValueError):
                gate.gameplay_staging_completion(record, record['source_sha'], records)
        for key in required:
            with self.subTest(missing=key), self.assertRaises(ValueError):
                gate.gameplay_staging_completion({**record, key: False}, record['source_sha'], records)

    def test_trusted_router_selects_the_distinct_gameplay_record(self):
        import dead_signal_release_guard as release
        row, source, _ = self.gameplay_fixture()
        with tempfile.TemporaryDirectory() as directory:
            records = Path(directory)
            (records / gate.GAMEPLAY_RECORD).write_text(json.dumps(row))
            with patch.object(gate, 'verify_staging_source', return_value=row) as verify:
                self.assertEqual(release.verify_staging_deploy_source(ROOT, source, records), row)
                verify.assert_called_once_with(ROOT, source, records, gate.GAMEPLAY_RECORD)

    def test_gameplay_upload_gate_rejects_a_changed_binary_before_any_publish(self):
        import dead_signal_staging_rollout as rollout
        row, _, _ = self.gameplay_fixture()
        approved = {p: {'candidate_sha256': row['staging_binary_sha256'][p],
                        'candidate_bytes': row['staging_binary_bytes'][p]} for p in rollout.ORDER}
        approved['whiteout']['candidate_sha256'] = '0' * 64
        with patch.dict('os.environ', {'GITHUB_REF': 'refs/heads/main',
                                       'GITHUB_REPOSITORY': 'stephennip9288-create/Roblox-Projects',
                                       'ROBLOX_API_KEY': 'synthetic-not-a-key'}), \
             patch.object(rollout, 'approved_release_source', return_value=row), \
             patch.object(rollout, 'preflight', return_value=approved), \
             patch.object(rollout, 'publish') as network:
            with self.assertRaisesRegex(ValueError, 'binary SHA256 mismatch: whiteout'):
                rollout.run('deploy', 'DEPLOY-PRIVATE-STAGING')
            network.assert_not_called()

    def test_staging_is_not_admitted_by_source_review_or_owner_listening(self):
        records = ROOT / 'games/dead-signal/releases'
        record = json.loads((records / gate.RECORD).read_text())
        self.assertIs(record['production_authorization'], False)
        if record.get('owner_staging_authorization') is True and record.get('ready_for_staging') is True:
            gate.staging_completion(record, record['source_sha'], records)
        else:
            with self.assertRaises(ValueError):
                gate.staging_completion(record, record.get('source_sha'), records)
        for sha in ('main', '', '1' * 40):
            with self.subTest(sha=sha), self.assertRaises(ValueError):
                gate.staging_completion(record, sha, records)
        for key in ('owner_staging_authorization', 'ready_for_staging'):
            with self.subTest(missing=key), self.assertRaises(ValueError):
                gate.staging_completion({**record, key: False}, record.get('source_sha'), records)

    def test_wrong_candidate_build_and_forged_build_review_are_rejected(self):
        reviewed = gate.build_record()
        for environment, places in reviewed['builds'].items():
            output = self.root / 'build/dead-signal-lossless' / environment
            output.mkdir(parents=True, exist_ok=True)
            for place in places:
                (output / (place + '.rbxl')).write_bytes(b'wrong candidate')
        with self.assertRaisesRegex(ValueError, 'differs from reviewed pin'):
            gate.verify_builds(self.root)
        path = self.root / gate.BUILDS
        data = path.read_bytes()
        try:
            path.write_bytes(data + b'\n')
            with self.assertRaises(ValueError):
                gate.build_record(self.root)
        finally:
            path.write_bytes(data)

    def test_current_builds_retain_separate_exact_pins(self):
        # The root Python suite runs before CI produces binaries. Hash comparison
        # itself is exercised with corrupt candidates above and real artifacts in
        # the readiness/lossless workflows, never reported as a skipped success.
        row = gate.build_record()
        self.assertEqual(set(row['builds']), {'staging', 'production'})
        for environment in row['builds'].values():
            self.assertEqual(set(environment), gate.ROLES)
            for spec in environment.values():
                self.assertEqual(len(spec['sha256']), 64)
                self.assertGreater(spec['bytes'], 100000)

    def test_all_specialist_and_prior_suites_are_registered_once(self):
        source = (ROOT / gate.PREFIX / 'Tests/run.py').read_text()
        names = ast.literal_eval(re.search(r'for name in (\[.*?\]):', source)[1])
        required = {'map-b2-navigation', 'enemy-b2-navigation', 'enemy-b2-awareness',
                    'enemy-b2-budget', 'enemy-b2-maps', 'audio-atmosphere-b2',
                    'audio-bindings-b2', 'movement-batch2', 'batch2-integration'}
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(len(names), 48)
        self.assertTrue(required.issubset(names))
        self.assertEqual(len(set(names) - required), 39)

    def test_actual_lossless_workflow_loads_and_invokes_the_candidate_guard(self):
        workflow = (ROOT / '.github/workflows/dead-signal-lossless-patch.yml').read_text()
        step = workflow.split('      - name: Verify patch reports and no unexpected output files\n', 1)[1]
        step = step.split('      - name:', 1)[0]
        program = textwrap.dedent(step.split("python - <<'PY'\n", 1)[1].split('\n          PY', 1)[0])
        with tempfile.TemporaryDirectory(prefix='dead-signal-workflow-import-') as folder:
            root = Path(folder)
            scripts = root / 'scripts'
            scripts.mkdir()
            # Isolate the wrapper's module lookup and call contract. Real guard
            # behavior/native bytes are covered separately; these are mock files.
            (scripts / 'dead_signal_batch2_candidate.py').write_text(
                "from pathlib import Path\n"
                "def verify_builds(*, environments):\n"
                "    assert environments == ('staging',)\n"
                "    Path('VERIFIER-CALLED').write_text('yes')\n")
            review = root / gate.MANIFEST
            review.parent.mkdir(parents=True)
            review.write_text('{}')
            directory = root / 'build/dead-signal-lossless/staging'
            directory.mkdir(parents=True)
            report = {}
            for place in gate.ROLES:
                (directory / (place + '.rbxl')).write_bytes(b'x' * 100001)
                report[place] = {'all_untouched_chunks_byte_identical': True,
                                 'expected_replacement_count': 61,
                                 'publish_approved': False, 'studio_tested': False}
            (directory / 'LOSSLESS-REPORT.json').write_text(json.dumps(report))
            (directory / 'BINARY-FIDELITY-REPORT.json').write_text('{}')
            result = subprocess.run([sys.executable, '-'], input=program, cwd=root,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((root / 'VERIFIER-CALLED').read_text(), 'yes')
            broken = program.replace("sys.path.insert(0, 'scripts')", '', 1)
            self.assertNotEqual(broken, program)
            result = subprocess.run([sys.executable, '-'], input=broken, cwd=root,
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('ModuleNotFoundError', result.stderr)


if __name__ == '__main__':
    unittest.main()
