"""Recovery renewal must retain exact bytes and reject ambiguous or stale input."""
import copy
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings
from zipfile import ZipFile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import refresh_dead_signal_production_recovery as renewal


class RecoveryRenewalTests(unittest.TestCase):
    def fixture(self, fault=None):
        members = {'dispatch': b'known dispatch', 'blackwater': b'known blackwater',
                   'cinderworks': b'known cinderworks', 'whiteout': b'known whiteout'}
        record = {'places': {place: {'member': 'production/' + place + '.rbxl',
            'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
            for place, data in members.items()}}
        out = io.BytesIO()
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with ZipFile(out, 'w') as archive:
                for place, data in members.items():
                    if fault == 'missing' and place == 'dispatch':
                        continue
                    member = record['places'][place]['member']
                    actual = data + b'tamper' if fault == 'oversized' and place == 'dispatch' else data
                    actual = b'X' * len(data) if fault == 'hash' and place == 'dispatch' else actual
                    archive.writestr(member, actual)
                    if fault == 'duplicate' and place == 'dispatch':
                        archive.writestr(member, data)
        return record, members, out.getvalue()

    def read(self, record, blob, tamper=False):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'original.zip'
            path.write_bytes(blob + (b'tamper' if tamper else b''))
            with patch.object(renewal, 'EXPECTED_BYTES', path.stat().st_size), patch.object(
                    renewal, 'EXPECTED_ARCHIVE', hashlib.sha256(blob).hexdigest()):
                return renewal.archive_members(path, record)

    def test_four_exact_members_retained(self):
        record, members, blob = self.fixture()
        self.assertEqual(self.read(record, blob), members)

    def test_changed_archive_or_missing_archive_rejected(self):
        record, _, blob = self.fixture()
        with self.assertRaises(ValueError):
            self.read(record, blob, tamper=True)
        with self.assertRaises(ValueError):
            renewal.archive_members(Path('/nonexistent/production-rollback.zip'), record)

    def test_missing_duplicate_oversized_and_changed_members_rejected(self):
        for fault in ('missing', 'duplicate', 'oversized', 'hash'):
            with self.subTest(fault=fault):
                record, _, blob = self.fixture(fault)
                with self.assertRaises(ValueError):
                    self.read(record, blob)

    def test_current_deployment_must_be_latest_successful_exact_attempt(self):
        record = {'deployment': {'workflow_id': 10, 'run_id': 20, 'attempt': 4, 'control_sha': 'a' * 40}}
        run = {'id': 20, 'run_attempt': 4, 'head_sha': 'a' * 40, 'status': 'completed', 'conclusion': 'success'}
        renewal.current_deployment(record, 'synthetic-read-token', lambda url: {'workflow_runs': [run]})
        changes = ({'id': 21}, {'run_attempt': 5}, {'head_sha': 'b' * 40},
                   {'status': 'in_progress'}, {'conclusion': 'failure'})
        for change in changes:
            with self.subTest(change=change), self.assertRaises(ValueError):
                renewal.current_deployment(record, 'synthetic-read-token',
                    lambda url: {'workflow_runs': [{**run, **change}, run]})
        with self.assertRaises(ValueError):
            renewal.current_deployment(record, '', lambda url: {'workflow_runs': [run]})

    def test_changed_original_provenance_rejected(self):
        record = json.loads((renewal.guard.RECORDS / 'recovery-production.json').read_text())
        for field in ('source', 'id', 'sha256'):
            changed = copy.deepcopy(record)
            if field == 'source':
                changed['source_sha'] = 'b' * 40
            else:
                changed['artifact'][field] = 999 if field == 'id' else 'b' * 64
            with self.subTest(field=field), patch.object(renewal.guard, 'recovery_record', return_value=changed):
                with self.assertRaises(ValueError):
                    renewal.original_record()


if __name__ == '__main__':
    unittest.main()
