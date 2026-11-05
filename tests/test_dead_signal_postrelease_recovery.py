"""No-publish post-release recovery validation, including negative controls."""
import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import dead_signal_production_admission as admission
import dead_signal_postrelease_recovery as post

RECORDS = Path(__file__).resolve().parents[1] / 'games/dead-signal/releases'
NOW = datetime(2026, 11, 5, tzinfo=timezone.utc)


def fixtures():
    def read(path):
        return json.loads((RECORDS / path).read_text())
    return (read(admission.RECORD),
            read('history/production-41800682585-previous.json'),
            read('recovery-production.json'),
            read('batch-1-production-audio-permissions.json'),
            read('history/production-41800682585-acceptance.json'))


class PostReleaseRecovery(unittest.TestCase):
    def test_real_owner_accepted_publication_and_both_rollbacks(self):
        record, prior, current, permissions, acceptance = fixtures()
        self.assertIs(post.completion(record, prior, current, permissions, acceptance, NOW), record)
        # The original deploy gate must NOT be silently repinned to new release.
        with self.assertRaisesRegex(ValueError, 'Current refreshed production recovery'):
            admission.completion(record, record['source_sha'], current, permissions, NOW)

    def test_bad_release_metadata_and_missing_qa_rejected(self):
        record, prior, current, permissions, acceptance = fixtures()
        mutants = [
            ('source changed', lambda a, b, c: a.update(source_sha='0'*40)),
            ('wrong run', lambda a, b, c: a['deployment'].update(run_id=RUN_WRONG)),
            ('missing place', lambda a, b, c: a['places'].pop('dispatch')),
            ('wrong size', lambda a, b, c: a['places']['whiteout'].update(bytes=1)),
            ('bad sha', lambda a, b, c: a['places']['blackwater'].update(sha256='0'*64)),
            ('wrong artifact', lambda a, b, c: a['artifact'].update(id=1)),
            ('missing previous backup', lambda a, b, c: b['artifact'].update(id=1)),
            ('no smoke acceptance', lambda a, b, c: c.update(owner_reported_production_gameplay_accepted=False)),
            ('invented device testing', lambda a, b, c: c.update(independent_exhaustive_device_testing_claimed=True)),
            ('wrong versions', lambda a, b, c: c['reviewed_published_versions'].update(dispatch=99)),
            ('forgot reload gaps', lambda a, b, c: c.update(known_silent_reload_mechanism_stages=0))
        ]
        for label, change in mutants:
            a, b, c = copy.deepcopy(current), copy.deepcopy(prior), copy.deepcopy(acceptance)
            change(a, b, c)
            with self.subTest(label=label):
                with self.assertRaises(ValueError):
                    post.completion(record, b, a, permissions, c, NOW)

    def test_cannot_reuse_stale_or_failed_original_admission(self):
        record, prior, current, permissions, acceptance = fixtures()
        record['ready_for_production'] = False
        with self.assertRaises(ValueError):
            post.completion(record, prior, current, permissions, acceptance, NOW)
        record['ready_for_production'] = True
        record['rollback']['artifact']['id'] = 1
        with self.assertRaises(ValueError):
            post.completion(record, prior, current, permissions, acceptance, NOW)


RUN_WRONG = 999

if __name__ == '__main__':
    unittest.main()
