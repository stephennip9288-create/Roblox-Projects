"""Renew exact preserved live-production recovery; never build or publish places."""
import io
import json
import os
from pathlib import Path
import urllib.request
from zipfile import ZipFile

import dead_signal_release_guard as guard

EXPECTED_SOURCE = '1a5b9f3b811137b6881090ad634a13624d33dd71'
EXPECTED_ARTIFACT = 12081841244
EXPECTED_ARCHIVE = 'e0b7d00fb64641afa33cbd68fb34b8282c92079adf811b6661897d82785c7910'
EXPECTED_BYTES = 9940446
ARCHIVE = guard.ROOT / 'games/dead-signal/releases/dead-signal-current-production-1a5b9f3b.zip'


def original_record():
    record = guard.recovery_record('production')
    if (record['source_sha'] != EXPECTED_SOURCE
            or record['artifact']['id'] != EXPECTED_ARTIFACT
            or record['artifact']['sha256'] != EXPECTED_ARCHIVE):
        raise ValueError('Production recovery changed; review the new live source before renewal')
    return record


def current_deployment(record, token, get=None):
    if not token:
        raise ValueError('Read-only GitHub token is required for current deployment verification')
    if get is None:
        def get(url):
            request = urllib.request.Request(url, headers={
                'Authorization': 'Bearer ' + token,
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28'})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
    deployment = record['deployment']
    latest = get(f'https://api.github.com/repos/{guard.REPOSITORY}/actions/workflows/'
                 f'{deployment["workflow_id"]}/runs?branch=main&per_page=10')
    runs = latest.get('workflow_runs', [])
    if (not runs or runs[0].get('id') != deployment['run_id']
            or runs[0].get('run_attempt') != deployment['attempt']
            or runs[0].get('head_sha') != deployment['control_sha']
            or runs[0].get('status') != 'completed'
            or runs[0].get('conclusion') != 'success'):
        raise ValueError('A newer/failed production release exists; reconcile live recovery first')


def archive_members(path, record):
    path = Path(path)
    if path.is_symlink() or not path.is_file() or path.stat().st_size != EXPECTED_BYTES:
        raise ValueError('Exact independently preserved original ZIP is required')
    blob = path.read_bytes()
    if len(blob) != EXPECTED_BYTES or guard.digest(blob) != EXPECTED_ARCHIVE:
        raise ValueError('Preserved original production archive hash mismatch')
    result = {}
    with ZipFile(io.BytesIO(blob)) as archive:
        names = archive.namelist()
        for place, spec in record['places'].items():
            member = spec['member']
            if names.count(member) != 1 or archive.getinfo(member).file_size != spec['bytes']:
                raise ValueError('Missing/ambiguous/oversized production member: ' + place)
            data = archive.read(member)
            if len(data) != spec['bytes'] or guard.digest(data) != spec['sha256']:
                raise ValueError('Preserved production member hash mismatch: ' + place)
            result[place] = data
    return result


def refresh():
    record = original_record()
    current_deployment(record, os.getenv('GH_TOKEN', ''))
    members = archive_members(ARCHIVE, record)
    directory = guard.RECOVERY / 'production'
    directory.mkdir(parents=True, exist_ok=True)
    for place, data in members.items():
        (directory / f'{place}.rbxl').write_bytes(data)
    guard.verify_recovery('production')
    output = guard.ROOT / 'build/dead-signal-production-recovery-refresh'
    (output / 'production').mkdir(parents=True, exist_ok=True)
    for place, data in members.items():
        (output / 'production' / f'{place}.rbxl').write_bytes(data)
    report = {
        'schema': 1, 'environment': 'production',
        'kind': 'exact-existing-recovery-preservation',
        'original_recovery_record': record,
        'original_archive_sha256': EXPECTED_ARCHIVE,
        'original_archive_bytes': EXPECTED_BYTES,
        'original_archive_path': str(ARCHIVE.relative_to(guard.ROOT)),
        'original_actions_artifact_expired': True,
        'latest_recorded_production_deployment_verified': True,
        'refresh_workflow_run': os.getenv('GITHUB_RUN_ID'),
        'refresh_head_sha': os.getenv('GITHUB_SHA'),
        'recreated_or_rebuilt': False, 'production_touched': False,
        'roblox_requests': False, 'all_four_bytes_unchanged': True}
    (output / 'PRESERVATION.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Verified and retained four unchanged current production rollback files; no Roblox requests')


if __name__ == '__main__':
    refresh()
