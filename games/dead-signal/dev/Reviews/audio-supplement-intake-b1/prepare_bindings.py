"""Render MAIN's review candidate from the exact Config; no upload or publication."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
BASE_BLOB = '1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2'
ANCHOR = '-- END DS-B1-001 84-ASSET PRIVATE STAGING AUDITION\n'
CONFIG_PATH = 'games/dead-signal/dev/Source/Runtime/shared/Config.lua'


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def render(source):
    if blob(source) != BASE_BLOB:
        raise ValueError('Config changed: MAIN must review the new base before applying this proposal')
    approval = json.loads((REVIEW / 'OWNER-APPROVALS.json').read_text())
    if approval['staging_universe_id'] != '10771141095':
        raise ValueError('Wrong staging universe')
    for row in approval['recordings']:
        if not row['owner_sample_listening_approved'] or not row['owner_reported_staging_access_granted']:
            raise ValueError('Missing owner confirmation: ' + row['name'])
    text = source.decode('utf-8')
    if text.count(ANCHOR) != 1:
        raise ValueError('Expected exactly one original audition boundary')
    block = (REVIEW / 'STAGING-BINDINGS.luau.txt').read_text()
    return text.replace(ANCHOR, ANCHOR + block, 1).encode('utf-8')


def patch(source):
    return ''.join(difflib.unified_diff(
        source.decode().splitlines(keepends=True), render(source).decode().splitlines(keepends=True),
        fromfile='a/' + CONFIG_PATH, tofile='b/' + CONFIG_PATH,
    ))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--patch', action='store_true')
    args = parser.parse_args()
    if args.output.resolve() == args.source.resolve():
        parser.error('Choose a separate output file; MAIN applies the reviewed patch explicitly')
    source = args.source.read_bytes()
    if args.patch:
        args.output.write_text(patch(source))
    else:
        args.output.write_bytes(render(source))
    print('Wrote review proposal:', args.output, '(runtime unchanged; no publication)')
