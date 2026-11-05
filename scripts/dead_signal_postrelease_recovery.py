"""Strict post-publication Batch 1 recovery verification (never authorizes a deploy).

Historical production admission remains pinned to the actual *previous* rollback,
so it cannot silently be reused to deploy the old source after publication.
This validation recognizes only the one fully reviewed, owner-tested release.
"""
from datetime import datetime, timezone, timedelta
import json
from pathlib import Path

import dead_signal_production_admission as admission

SOURCE = 'c2d4fb020c3893cae569d346d2886862d8fe8401'
CONTROL = 'e7287ffc86f7427a1470290b41657c73265cfb2b'
RUN = 41800682585
ARTIFACT = 13309518810
ZIP_SHA256 = 'e4e6da7fb0e97aa380a847a27aacea29b704febce166a021c00387233163b06a'
PRIOR_ARTIFACT = 13283390341
VERSIONS = {'dispatch': 29, 'blackwater': 23, 'cinderworks': 22, 'whiteout': 22}
EVIDENCE = ('https://github.com/stephennip9288-create/Roblox-Projects/'
            'issues/63#issuecomment-6653072353')
ROOT_RECORDS = Path(__file__).resolve().parents[1] / 'games/dead-signal/releases'


def completion(record, historical, current, permissions, acceptance, now=None):
    """Validate new operational rollback, previous known good, and real owner QA.

    The original prepublication admission is validated against its historical
    recovery, never rewritten. New recovery must match exactly published source,
    production build pins, artifact/run and owner-accepted versions.
    """
    admission.completion(record, SOURCE, historical, permissions, now=now)
    if historical.get('artifact', {}).get('id') != PRIOR_ARTIFACT:
        raise ValueError('Previous known-good production recovery was lost')
    if (record.get('source_sha') != SOURCE
            or current.get('schema') != 1
            or current.get('environment') != 'production'
            or current.get('universe_id') != '10770732078'
            or current.get('source_sha') != SOURCE):
        raise ValueError('Post-release recovery must match approved production universe/source')

    deployment = current.get('deployment', {})
    artifact = current.get('artifact', {})
    if (deployment.get('run_id') != RUN
            or deployment.get('attempt') != 1
            or deployment.get('workflow_id') != 386320766
            or deployment.get('control_sha') != CONTROL
            or deployment.get('versions') != VERSIONS):
        raise ValueError('Published four-place deployment provenance changed')
    if (artifact.get('id') != ARTIFACT
            or artifact.get('run_id') != RUN
            or artifact.get('head_sha') != CONTROL
            or artifact.get('sha256') != ZIP_SHA256):
        raise ValueError('New production recovery archive is not the reviewed release')
    expiry = datetime.fromisoformat(artifact.get('expires_at', '').replace('Z', '+00:00'))
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)
    now = now or datetime.now(timezone.utc)
    if expiry <= now + timedelta(days=14):
        raise ValueError('Published recovery artifact requires renewal')

    places = current.get('places', {})
    if set(places) != admission.ROLES:
        raise ValueError('New production recovery must contain all four places')
    previous_places = historical.get('places', {})
    for name in admission.ROLES:
        row = places[name]
        expected = record['builds']['production'][name]
        if (row.get('member') != name + '.rbxl'
                or row.get('place_id') != previous_places[name].get('place_id')
                or row.get('sha256') != expected.get('sha256')
                or row.get('bytes') != expected.get('bytes')):
            raise ValueError('Published native member differs from reviewed build: ' + name)
    if (acceptance.get('schema') != 1
            or acceptance.get('release') != 'dead-signal-batch-1-production-smoke-acceptance'
            or acceptance.get('production_run_id') != RUN
            or acceptance.get('source_sha') != SOURCE
            or acceptance.get('reviewed_published_versions') != VERSIONS
            or acceptance.get('owner_reported_production_gameplay_accepted') is not True
            or acceptance.get('owner_words') != 'It works'
            or acceptance.get('evidence') != EVIDENCE
            or acceptance.get('independent_exhaustive_device_testing_claimed') is not False
            or acceptance.get('known_silent_reload_mechanism_stages') != 11
            or acceptance.get('no_additional_publication_requested') is not True
            or acceptance.get('batch_2_or_3_included') is not False):
        raise ValueError('Post-release acceptance must match real owner report and scope')
    return record


def validate_current_records(records=ROOT_RECORDS):
    """Used exclusively by a No Publish readiness test after an owner release."""
    def read(name):
        return json.loads((records / name).read_text())
    record = read(admission.RECORD)
    current = read('recovery-production.json')
    historical = read('history/production-41800682585-previous.json')
    accepted = read('history/production-41800682585-acceptance.json')
    permissions = read('batch-1-production-audio-permissions.json')
    completion(record, historical, current, permissions, accepted)
    return record
