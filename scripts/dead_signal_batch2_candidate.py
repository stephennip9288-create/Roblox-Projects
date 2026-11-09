"""Exact Batch 2 source/build intake, independent of immutable Batch 1 admission.

Source review and offline build verification never authorize a publication.
Only main-trusted controls may admit a separately owner-authorized staging SHA.
"""
import argparse
import csv
from functools import lru_cache
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from common import ROOT

BASE = '7aaf323de6153134df2154c7ae3b1613a596495b'
PREFIX = 'games/dead-signal/dev/'
REVIEW = PREFIX + 'Reviews/batch2-integration/'
MANIFEST = REVIEW + 'REVIEWED-RUNTIME.json'
BUILDS = REVIEW + 'REVIEWED-BUILDS.json'
MANIFEST_BLOB = '06d588c5603496b92cfdae123af1add570a4248a'
BUILDS_BLOB = 'b3b2d607b5da267fd518443f9b271ca4af87d684'
RECORD = 'batch-2-staging.json'
GAMEPLAY_RECORD = 'batch-2-gameplay-staging.json'
GAMEPLAY_RELEASE = 'dead-signal-batch-2-gameplay-only-private-staging'
HEADS = {
    'maps': '7b8c2442530c11afc47cd40f50c03a03349f6c39',
    'audio': '4807fd25193bc721a3473858d2c744250614aaaf',
    'enemies': 'f8b2c49f88046af43a8133f7bfeec5e4437c34a9',
    'combat_ui': '26bcbfe5558f6fc0ff6e067c200649578a5502be',
}
ROLES = {'dispatch', 'blackwater', 'cinderworks', 'whiteout'}


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


@lru_cache(maxsize=4)
def _document(data, pin):
    if blob(data) != pin:
        raise ValueError('Batch 2 review document differs from its independently reviewed pin')
    return json.loads(data)


def manifest(root=ROOT):
    result = _document((Path(root) / MANIFEST).read_bytes(), MANIFEST_BLOB)
    if (result.get('schema') != 1 or result.get('kind') != 'reviewed-batch-2-source-intake'
            or result.get('baseline') != BASE or result.get('integrated_heads') != HEADS
            or result.get('scope') != [f'B2-{i:02}' for i in range(1, 9)]
            or result.get('publication_authorized') is not False
            or len(result.get('records', {})) != 61):
        raise ValueError('Batch 2 provenance header/inventory changed')
    return result


def baseline(name, data, root=ROOT):
    """Normalize only an exact reviewed delta for retained historical tests.

    This is not a shape-based exemption. Every new byte has a frozen blob pin;
    verify_tree separately rejects dropping a reviewed delta back to Batch 1.
    """
    root = Path(root)
    row = manifest(root)['records'].get(name)
    if not row or blob(data) not in {row['base_blob'], row['blob_sha']}:
        raise ValueError('Unreviewed Batch 2 runtime bytes: ' + name)
    if row['base_blob'] == row['blob_sha']:
        return data
    old = (root / REVIEW / row['baseline_file']).read_bytes()
    if blob(old) != row['base_blob']:
        raise ValueError('Frozen Batch 1 source snapshot changed: ' + name)
    return old


def verify_tree(root=ROOT):
    root = Path(root).resolve()
    doc = manifest(root)
    dev = root / PREFIX
    actual = {str(p.relative_to(dev)): p for p in (dev / 'Source/Runtime').rglob('*.lua')}
    if set(actual) != set(doc['records']):
        raise ValueError('Fixed 61-record runtime inventory changed')
    for name, path in actual.items():
        if path.is_symlink() or not path.resolve().is_relative_to(root):
            raise ValueError('Unsafe runtime path: ' + name)
        data = path.read_bytes()
        if blob(data) != doc['records'][name]['blob_sha']:
            raise ValueError('Runtime differs from reviewed Batch 2 candidate: ' + name)
        baseline(name, data, root)
    for name, expected in doc['protected_batch1_files'].items():
        path = root / name
        if path.is_symlink() or not path.is_file() or blob(path.read_bytes()) != expected:
            raise ValueError('Immutable Batch 1/native/recovery evidence changed: ' + name)
    verify_audio(root)
    return doc


def verify_audio(root=ROOT, require_active=False):
    root = Path(root)
    doc = manifest(root)
    raw = (root / REVIEW / 'AUDIO-INTAKE.json').read_bytes()
    if blob(raw) != doc['audio_intake_blob']:
        raise ValueError('Reviewed sixteen-asset intake changed')
    intake = json.loads(raw)
    for name, key in [('AUDIO-SOURCE-REVIEW.json', 'audio_source_review_blob'),
                      ('HOSTED-CONTENT-COMPARISON.json', 'hosted_content_comparison_blob')]:
        if blob((root / REVIEW / name).read_bytes()) != doc.get(key):
            raise ValueError('Reviewed source/content evidence changed: ' + name)
    rows = intake['recordings']
    if (len(rows) != 16 or len({r['event'] for r in rows}) != 16
            or len({r['roblox_asset_id'] for r in rows}) != 16
            or any(not r['roblox_asset_id'].isascii() or not r['roblox_asset_id'].isdigit()
                   or int(r['roblox_asset_id']) < 1 for r in rows)
            or intake.get('owner_listening_reconfirmation_required') is not False):
        raise ValueError('Invalid or duplicated Batch 2 audio intake')
    for environment, universe in [('staging', '10771141095'), ('production', '10770732078')]:
        spec = intake['permissions'][environment]
        path = root / REVIEW / spec['reviewed_subset_file']
        if (spec.get('universe_id') != universe or spec.get('permissions_modified') is not False
                or blob(path.read_bytes()) != spec['subset_blob']):
            raise ValueError('Independent experience grant evidence changed')
        with path.open(newline='') as stream:
            exported = list(csv.DictReader(stream))
        if len(exported) != 16:
            raise ValueError('Sixteen independently exported audio grants required')
        by_id = {r['ID']: r for r in exported}
        for row in rows:
            grant = by_id.get(row['roblox_asset_id'], {})
            if (grant.get('Asset') != row['name'] or grant.get('Asset Type') != 'Audio'
                    or grant.get('Owner') != row['uploader'] or row['permissions'].get(universe) is not True
                    or row.get('listeningApproved') is not True):
                raise ValueError('Wrong asset/event/universe/owner approval: ' + row['event'])
    policy = (root / REVIEW / 'CONFIG-POLICY.luau.txt').read_bytes()
    if blob(policy) != doc['config_policy_blob']:
        raise ValueError('Exact reviewed Config intake policy required')
    if require_active and any(not all(r.get(k) is True for k in (
            'rightsCleared', 'creatorReviewed', 'listeningApproved', 'robloxApproved')) for r in rows):
        raise ValueError('Unresolved asset rights/source, creator review or moderation/playback gate')
    return intake


def verify_audio_disabled(root=ROOT):
    """Separate gameplay QA requires all sixteen exact banks to remain gated."""
    root = Path(root)
    intake = verify_audio(root)
    policy = (root / REVIEW / 'CONFIG-POLICY.luau.txt').read_text()
    config = (root / PREFIX / 'Source/Runtime/shared/Config.lua').read_text()
    if config.count(policy) != 1 or policy.count(',robloxApproved=false,') != 16:
        raise ValueError('Gameplay-only QA requires the exact sixteen-bank disabled Config policy')
    for row in intake['recordings']:
        line = next((s for s in policy.splitlines() if '["' + row['event'] + '"]=' in s), '')
        if (row.get('activated') is not False or row.get('robloxApproved') is not False
                or ('id="rbxassetid://' + row['roblox_asset_id'] + '"') not in line
                or 'robloxApproved=false' not in line):
            raise ValueError('Gameplay-only QA cannot activate a new audio bank: ' + row['event'])
    return {r['event']: r['roblox_asset_id'] for r in intake['recordings']}


def build_record(root=ROOT):
    row = _document((Path(root) / BUILDS).read_bytes(), BUILDS_BLOB)
    if (row.get('schema') != 1 or row.get('runtime_manifest_blob') != MANIFEST_BLOB
            or row.get('publication_authorized') is not False
            or set(row.get('builds', {})) != {'staging', 'production'}
            or any(set(v) != ROLES for v in row['builds'].values())):
        raise ValueError('Batch 2 eight-build review is incomplete')
    return row


def verify_builds(root=ROOT, environments=('staging', 'production')):
    root = Path(root)
    verify_tree(root)
    row = build_record(root)
    if not environments or any(e not in ('staging', 'production') for e in environments):
        raise ValueError('Explicit known candidate environments required')
    for environment in environments:
        places = row['builds'][environment]
        for place, expected in places.items():
            data = (root / 'build/dead-signal-lossless' / environment / (place + '.rbxl')).read_bytes()
            if len(data) != expected['bytes'] or hashlib.sha256(data).hexdigest() != expected['sha256']:
                raise ValueError('Built Batch 2 candidate differs from reviewed pin: ' + environment + '/' + place)
    return row


def verify_historical_builds(record, root=ROOT):
    """Reproduce original Batch 1 pins without comparing new builds to old ones.

    Use frozen pre-change bytes and the unchanged native patcher. Historical
    production admission and all eight original hash comparisons still execute.
    Current candidate files, native inputs, recovery pointers and ledgers stay put.
    """
    import dead_signal_production_admission as admission
    import patch_dead_signal_rbxl as patcher
    root = Path(root)
    verify_tree(root)
    roots = {'shared': 'ReplicatedStorage/DeadSignal',
             'server': 'ServerScriptService/DeadSignalServer',
             'client': 'StarterPlayer/StarterPlayerScripts/DeadSignalClient'}
    originals = {}
    for name in manifest(root)['records']:
        path = Path(name)
        filename = path.name
        instance = filename.removesuffix('.server.lua').removesuffix('.client.lua').removesuffix('.lua')
        if instance != 'PlaceConfig':
            originals[roots[path.parent.name] + '/' + instance] = baseline(name, (root / PREFIX / name).read_bytes(), root)
    with tempfile.TemporaryDirectory(prefix='dead-signal-batch1-reproduction-') as temporary:
        for environment in ('staging', 'production'):
            output = Path(temporary) / 'build/dead-signal-lossless' / environment
            output.mkdir(parents=True)
            for place in sorted(ROLES):
                replacements = patcher.desired_scripts(place, environment)
                replacements = {name: (kind, originals.get(name, data)) for name, (kind, data) in replacements.items()}
                native = (root / 'games/dead-signal/full-baselines/v1.8.0' / (place + '.rbxl')).read_bytes()
                built, _ = patcher.patch_bytes(native, replacements)
                (output / (place + '.rbxl')).write_bytes(built)
        admission.verify_builds(record, temporary)
    return True


def _staging_identity(record, source_sha, release):
    from dead_signal_release_guard import full_sha
    import dead_signal_production_admission as admission
    if (record.get('schema') != 1 or record.get('release') != release
            or not full_sha(source_sha) or record.get('source_sha') != source_sha
            or record.get('owner_staging_authorization') is not True
            or not record.get('owner_authorization_evidence')
            or record.get('ready_for_staging') is not True
            or record.get('production_authorization') is not False
            or record.get('staging_universe_id') != '10771141095'
            or record.get('profile_store') != 'DeadSignal_Profile_v1'
            or record.get('runtime_manifest_blob') != MANIFEST_BLOB
            or record.get('build_manifest_blob') != BUILDS_BLOB
            or record.get('integrated_heads') != HEADS
            or record.get('engine_gameplay_verified') is not False):
        raise ValueError('Batch 2 has no exact separately authorized private-staging admission')


def staging_completion(record, source_sha, records, now=None):
    """Full-audio admission is unchanged: all sixteen approvals are required."""
    _staging_identity(record, source_sha, 'dead-signal-batch-2-private-staging')
    audio = record.get('audio', {})
    if (audio.get('asset_count') != 16 or audio.get('fully_approved_assets') != 16
            or audio.get('independent_staging_grants_verified') is not True
            or audio.get('rights_and_source_verified') is not True
            or audio.get('moderation_and_playback_eligible') is not True):
        raise ValueError('All sixteen Batch 2 audio intake gates must pass before staging')
    verify_audio(require_active=True)
    return _staging_evidence(record, source_sha, records, now)


def gameplay_staging_completion(record, source_sha, records, now=None):
    """Distinct owner-approved gameplay test, never a full-audio acceptance."""
    if record.get('proposal_withdrawn') is True:
        raise ValueError('Gameplay-only proposal withdrawn; owner requires all sixteen new audio assets enabled')
    _staging_identity(record, source_sha, GAMEPLAY_RELEASE)
    disabled = verify_audio_disabled()
    audio = record.get('audio', {})
    if (record.get('approval_scope') != 'GAMEPLAY_QA_NEW_AUDIO_DISABLED'
            or record.get('owner_accepts_audio_exclusion') is not True
            or record.get('full_batch2_accepted') is not False
            or audio.get('asset_count') != 16 or audio.get('fully_approved_assets') != 0
            or audio.get('enabled_new_assets') != 0 or audio.get('disabled_assets') != disabled
            or audio.get('independent_staging_grants_verified') is not True
            or audio.get('moderation_and_playback_eligible') is not False):
        raise ValueError('Gameplay-only staging needs explicit audio exclusion and all sixteen banks disabled')
    return _staging_evidence(record, source_sha, records, now)


def _staging_evidence(record, source_sha, records, now=None):
    import dead_signal_production_admission as admission
    from datetime import datetime, timezone, timedelta
    if set(record.get('ci', {})) != admission.FAMILIES:
        raise ValueError('Five source-specific Batch 2 CI families are required')
    for family, check in record['ci'].items():
        if (check.get('source_sha') != source_sha or check.get('conclusion') != 'success'
                or type(check.get('run_id')) is not int or check['run_id'] <= 0):
            raise ValueError('Incomplete Batch 2 source CI: ' + family)
    reviewed = build_record()['builds']['staging']
    if (record.get('staging_binary_sha256') != {p: r['sha256'] for p, r in reviewed.items()}
            or record.get('staging_binary_bytes') != {p: r['bytes'] for p, r in reviewed.items()}):
        raise ValueError('Exact four-place Batch 2 staging build pins required')
    recovery = json.loads((Path(records) / 'recovery-staging.json').read_text())
    if record.get('rollback') != recovery:
        raise ValueError('Batch 2 must retain the current staging rollback provenance')
    expiry = datetime.fromisoformat(recovery['artifact']['expires_at'].replace('Z', '+00:00'))
    if expiry <= (now or datetime.now(timezone.utc)) + timedelta(days=14):
        raise ValueError('Refresh staging rollback before Batch 2 deployment')
    return record


def verify_staging_source(candidate, source_sha, records, record_name=RECORD):
    from dead_signal_release_guard import verify_checkout
    from dead_signal_production_admission import verify_ci
    if record_name not in (RECORD, GAMEPLAY_RECORD):
        raise ValueError('Unknown Batch 2 staging admission')
    record = json.loads((Path(records) / record_name).read_text())
    completion = gameplay_staging_completion if record_name == GAMEPLAY_RECORD else staging_completion
    completion(record, source_sha, records)
    verify_checkout(candidate, source_sha)
    verify_tree(candidate)
    for lane, ancestor in {**HEADS, 'baseline': BASE}.items():
        result = subprocess.run(['git', '-C', str(candidate), 'merge-base', '--is-ancestor', ancestor, source_sha], capture_output=True)
        if result.returncode:
            raise ValueError('Batch 2 source omits reviewed ancestor: ' + lane)
    verify_ci(record, os.getenv('GH_TOKEN', ''))
    return record


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-builds', action='store_true')
    parser.add_argument('--verify-historical-builds', action='store_true')
    args = parser.parse_args()
    verify_tree()
    if args.verify_builds:
        verify_builds()
    if args.verify_historical_builds:
        import dead_signal_production_admission as admission
        record = json.loads((ROOT / 'games/dead-signal/releases' / admission.RECORD).read_text())
        verify_historical_builds(record)
    print('Exact reviewed Batch 2 source and requested build checks passed; no publishing')
