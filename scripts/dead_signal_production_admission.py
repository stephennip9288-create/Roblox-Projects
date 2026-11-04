"""Main-trusted Batch 1 production admission, separate from historical staging QA."""
import argparse
from datetime import datetime, timezone, timedelta
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.request

from common import ROOT

RECORD = 'batch-1-production.json'
STAGED = 'f4a7d6ba0c6981a3ebe3679e64b5eea37e1dce2d'
STAGED_CONFIG = '88cccbed93fabff62c72c170a595ea7f6338216e'
PRODUCTION_CONFIG = '8a314e4cec13a3d1f3e231628be203c36a493412'
PRODUCTION_BLOCK = 'd4c907b38e250ebf8a92c07d4885b03dd2156616'
PREFIX = 'games/dead-signal/dev/Source/Runtime/'
CONFIG = PREFIX + 'shared/Config.lua'
FAMILIES = {'validate.yml', 'dead-signal-source-ci.yml', 'dead-signal-lossless-patch.yml',
            'dead-signal-production-readiness.yml', 'dead-signal-staging-preflight.yml'}
ROLES = {'dispatch', 'blackwater', 'cinderworks', 'whiteout'}
REPOSITORY = 'stephennip9288-create/Roblox-Projects'


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def full_sha(value):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{40}', value) is not None


def completion(record, source_sha, recovery, permissions, now=None):
    if (record.get('schema') != 1 or record.get('release') != 'dead-signal-batch-1-production'
            or not full_sha(source_sha) or record.get('source_sha') != source_sha
            or record.get('ready_for_production') is not True
            or record.get('owner_production_authorization') is not True
            or record.get('production_universe_id') != '10770732078'
            or record.get('profile_store') != 'DeadSignal_Profile_v1'):
        raise ValueError('Exact reviewed Batch 1 production source is not ready/authorized')
    environment = record.get('environment_checks', {})
    if (environment.get('environment') != 'dead-signal-production'
            or environment.get('allowed_branch_patterns') != ['main']
            or environment.get('allowed_tag_patterns') != []
            or environment.get('required_reviewer_protection_verified') is not True
            or environment.get('repository_production_secret_name_present') is not True):
        raise ValueError('Main-only production environment, reviewer protection and credential presence must be verified')
    accepted = record.get('staging_acceptance', {})
    if (accepted.get('source_sha') != STAGED or accepted.get('deployment_run') != 40054332185
            or accepted.get('owner_gameplay_accepted') is not True
            or accepted.get('evidence') != 'https://github.com/stephennip9288-create/Roblox-Projects/issues/37#issuecomment-6403467780'
            or accepted.get('independent_exhaustive_device_testing_claimed') is not False):
        raise ValueError('Owner acceptance must retain its actual source and scope')
    if (record.get('staged_config_blob') != STAGED_CONFIG
            or record.get('production_config_blob') != PRODUCTION_CONFIG
            or record.get('production_block_blob') != PRODUCTION_BLOCK
            or record.get('silent_reload_stage_count') != 11
            or record.get('reload_gap_disposition') != 'retain-tested-silent-skip-no-substitutes'
            or record.get('unbound_components') != ['117834744541770', '117522141638495']):
        raise ValueError('Reviewed audio scope or known limitations changed')
    grants = permissions.get('grants', [])
    ids = [row.get('asset_id') for row in grants]
    if (permissions.get('universe_id') != 10770732078
            or permissions.get('bound_asset_count') != 88 or len(ids) != 88 or len(set(ids)) != 88
            or any(not isinstance(i, str) or re.fullmatch('[0-9]+', i) is None for i in ids)
            or any(row.get('result') != 'Already added' for row in grants)
            or set(ids) != set(record.get('production_permission_asset_ids', []))
            or permissions.get('native_production_playback_verified') is not False
            or permissions.get('permission_page') != 'https://create.roblox.com/dashboard/creations/experiences/10770732078/permissions'
            or not permissions.get('verified_at')):
        raise ValueError('Independent production audio permission evidence is incomplete')
    checks = record.get('ci', {})
    if set(checks) != FAMILIES:
        raise ValueError('All five required CI workflow families must pass on the source')
    for family, check in checks.items():
        if (check.get('source_sha') != source_sha or check.get('conclusion') != 'success'
                or type(check.get('run_id')) is not int or check['run_id'] <= 0):
            raise ValueError('Required CI evidence incomplete: ' + family)
    for environment in ('staging', 'production'):
        rows = record.get('builds', {}).get(environment, {})
        if (set(rows) != ROLES or any(not re.fullmatch('[0-9a-f]{64}', r.get('sha256', ''))
                or type(r.get('bytes')) is not int or r['bytes'] < 100000 for r in rows.values())):
            raise ValueError('Exact eight-place build pins are required')
    rollback = record.get('rollback', {})
    if (rollback.get('refreshed') is not True or rollback.get('source_sha') != recovery.get('source_sha')
            or rollback.get('deployment') != recovery.get('deployment')
            or rollback.get('artifact') != recovery.get('artifact')
            or rollback.get('places') != recovery.get('places')):
        raise ValueError('Current refreshed production recovery provenance is required')
    expiry = datetime.fromisoformat(recovery['artifact']['expires_at'].replace('Z', '+00:00'))
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)
    now = now or datetime.now(timezone.utc)
    if expiry <= now + timedelta(days=14):
        raise ValueError('Refresh production rollback: fewer than 14 days remain')
    return record


def verify_source(candidate, source_sha, records=None):
    # Imported here to avoid a circular import when install_controls calls us.
    from dead_signal_release_guard import verify_checkout
    candidate = Path(candidate).resolve()
    records = Path(records) if records is not None else ROOT / 'games/dead-signal/releases'
    record = json.loads((records / RECORD).read_text())
    permissions = json.loads((records / 'batch-1-production-audio-permissions.json').read_text())
    recovery = json.loads((records / 'recovery-production.json').read_text())
    completion(record, source_sha, recovery, permissions)
    verify_checkout(candidate, source_sha)
    def git(*args):
        return subprocess.check_output(['git', '-C', str(candidate), *args])
    subprocess.run(['git', '-C', str(candidate), 'merge-base', '--is-ancestor', STAGED, source_sha], check=True, capture_output=True)
    paths = git('ls-tree', '-r', '--name-only', source_sha, '--', PREFIX).decode().splitlines()
    old_paths = git('ls-tree', '-r', '--name-only', STAGED, '--', PREFIX).decode().splitlines()
    if paths != old_paths:
        raise ValueError('Runtime inventory changed from accepted staging')
    for path in paths:
        data = (candidate / path).read_bytes()
        previous = git('show', STAGED + ':' + path)
        if path != CONFIG and data != previous:
            raise ValueError('Unexpected non-audio runtime delta: ' + path)
        if path == CONFIG:
            start = b'-- START DS-B1-001 REVIEWED PRODUCTION AUDIO ACTIVATION\n'
            end = b'-- END DS-B1-001 REVIEWED PRODUCTION AUDIO ACTIVATION\n'
            if data.count(start) != 1 or data.count(end) != 1:
                raise ValueError('Missing or duplicated production audio block')
            begin, finish = data.index(start), data.index(end) + len(end)
            block = data[begin:finish]
            if (blob(data) != PRODUCTION_CONFIG or blob(previous) != STAGED_CONFIG
                    or blob(block) != PRODUCTION_BLOCK or data[:begin] + data[finish:] != previous
                    or set(re.findall(rb'rbxassetid://(\d+)', block)) != {i.encode() for i in record['production_permission_asset_ids']}):
                raise ValueError('Production activation does not exactly preserve accepted staging audio')
    return record


def verify_builds(record, root=ROOT):
    for environment in ('staging', 'production'):
        for place, row in record['builds'][environment].items():
            data = (Path(root) / 'build/dead-signal-lossless' / environment / (place + '.rbxl')).read_bytes()
            if len(data) != row['bytes'] or hashlib.sha256(data).hexdigest() != row['sha256']:
                raise ValueError('Built candidate differs from reviewed pin: ' + environment + '/' + place)


def verify_ci(record, token, get=None):
    if not token:
        raise ValueError('Read-only GitHub token required for current CI evidence')
    if get is None:
        def get(url):
            request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token,
                'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
    for family, spec in record['ci'].items():
        row = get(f'https://api.github.com/repos/{REPOSITORY}/actions/runs/{spec["run_id"]}')
        if (row.get('id') != spec['run_id'] or row.get('head_sha') != record['source_sha']
                or row.get('path') != '.github/workflows/' + family
                or row.get('status') != 'completed' or row.get('conclusion') != 'success'
                or row.get('repository', {}).get('full_name') != REPOSITORY):
            raise ValueError('Current GitHub CI evidence failed: ' + family)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--verify-builds', action='store_true')
    args = parser.parse_args()
    selected = verify_source(ROOT, args.source_sha)
    verify_ci(selected, os.getenv('GH_TOKEN', ''))
    if args.verify_builds:
        verify_builds(selected)
    print('Exact production acceptance, permissions, CI and requested build gates passed; no publishing')
