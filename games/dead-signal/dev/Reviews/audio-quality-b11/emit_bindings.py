"""Prepare MAIN's Config proposal from verified creator upload records. No upload/publish."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STAGING_UNIVERSE = '10771141095'


def proposal(uploads, allow_partial=False):
    records = json.loads((ROOT / 'RECORDINGS.json').read_text())['recordings']
    banks = {}; blocked = []
    for record in records:
        upload = uploads.get(record['name'], {}); value = str(upload.get('asset_id') or '')
        valid = value.isascii() and value.isdigit() and 0 < len(value) <= 20 and int(value) > 0
        valid = valid and all(upload.get(flag) is True for flag in ['creator_reviewed', 'moderation_approved', 'sample_listening_approved'])
        valid = valid and str(upload.get('permission_universe_id')) == STAGING_UNIVERSE and upload.get('experience_permission_verified') is True
        valid = valid and upload.get('wav_sha256') == record['wav_sha256']
        if not valid:
            blocked.append(record['name']); continue
        for slot in record['slots']:
            root, side = slot, 'variants'
            if slot.endswith(('.near', '.far')):
                root, side = slot.rsplit('.', 1)
            bank = banks.setdefault(root, {'gain': 1})
            bank.setdefault(side, []).append('rbxassetid://' + value)
            if record.get('interval'):
                bank['interval'] = record['interval']; bank['duration'] = record['seconds']
    if blocked and not allow_partial:
        return None, blocked
    lines = ['-- MAIN review proposal only; not gameplay acceptance or publication.',
             '-- Assets checked for staging universe ' + STAGING_UNIVERSE + '; no production grant inferred.',
             '-- DS-B1-001 stays Open until integrated gameplay listening passes.']
    for key in sorted(banks):
        fields = []
        for name, value in sorted(banks[key].items()):
            fields.append(name + '={' + ','.join(json.dumps(x) for x in value) + '}' if isinstance(value, list) else name + '=' + str(value))
        lines.append('C.SoundIds[' + json.dumps(key) + ']={' + ','.join(fields) + '}')
    return '\n'.join(lines) + '\n', blocked


def template():
    records = json.loads((ROOT / 'RECORDINGS.json').read_text())['recordings']
    return {r['name']: {'asset_id': None, 'creator_reviewed': False, 'moderation_approved': False,
                       'sample_listening_approved': False, 'permission_universe_id': STAGING_UNIVERSE,
                       'experience_permission_verified': False, 'wav_sha256': r['wav_sha256']} for r in records}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--uploads', type=Path); parser.add_argument('--template', type=Path)
    parser.add_argument('--output', type=Path); parser.add_argument('--allow-partial', action='store_true')
    args = parser.parse_args()
    for path in [args.output, args.template]:
        if path and ('Source' in path.resolve().parts or 'Runtime' in path.resolve().parts):
            parser.error('This review helper never writes runtime source.')
    if args.template:
        args.template.parent.mkdir(parents=True, exist_ok=True)
        args.template.write_text(json.dumps(template(), indent=2) + '\n')
    if args.uploads:
        text, blocked = proposal(json.loads(args.uploads.read_text()), args.allow_partial)
        print('Unapproved/unavailable recording inputs:', len(blocked))
        if text is None:
            print('No activation proposal emitted: actual creator uploads/permissions are required.'); raise SystemExit(2)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True); args.output.write_text(text)
        else:
            print(text)
        print('Review proposal only; no upload, publication or listening pass.')
