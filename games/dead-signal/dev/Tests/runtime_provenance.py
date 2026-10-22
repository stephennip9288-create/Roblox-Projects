"""Additive MAIN intake of explicitly reviewed runtime blobs; no baseline regeneration."""
import hashlib
import json
from pathlib import Path

DEV = Path(__file__).resolve().parents[1]
BASE = 'c80d55aeeae4b51ef8d836949a33bf440890c6b7'
HISTORICAL_BLOB = 'dcf56e871bb56f809df77515b73cfaa60fa32638'
CORRECTION_BASELINE_BLOB = 'a5f6c619624fa5a1372327c978cc4df86b08987b'
# Frozen from GitHub's exact #49/#52/#53/#54 source trees, not current files.
APPROVED = {
    "Source/Runtime/shared/Config.lua": [
        49,
        "409ae5118981ff5c9ba82802eb41c6a8326a4bc1",
        "1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2"
    ],
    "Source/Runtime/server/Architecture.lua": [
        52,
        "7bf748868a6963f84a52dc8931c866689ea9fa34",
        "c5b5294dfd7f6f981ef73f17256868d9e5235652"
    ],
    "Source/Runtime/server/Enemies.lua": [
        53,
        "09fa91eec648c67cfc7c4e3c7481469285dd1a03",
        "cfaa77d5d92927a4e0dd561e96569ff510373f50"
    ],
    "Source/Runtime/server/EnemyRigs.lua": [
        53,
        "09fa91eec648c67cfc7c4e3c7481469285dd1a03",
        "634f3bee0aa21d341814d6585881aee69eb8c402"
    ],
    "Source/Runtime/server/InfectedWardrobe.lua": [
        53,
        "09fa91eec648c67cfc7c4e3c7481469285dd1a03",
        "490d85b05242d5a3d9b5805d1ce89f4295a46c0e"
    ],
    "Source/Runtime/server/Navigation.lua": [
        53,
        "09fa91eec648c67cfc7c4e3c7481469285dd1a03",
        "bc0def04621503103c2c9d792392ee432a8ac40b"
    ],
    "Source/Runtime/shared/NPCPose.lua": [
        53,
        "09fa91eec648c67cfc7c4e3c7481469285dd1a03",
        "3a003e8abaad63c5ffa7c4a19117d28e151771d1"
    ],
    "Source/Runtime/client/Effects.lua": [
        54,
        "495b1350db04bde356f36a0a9cd8551ede73ccb3",
        "eba3364383e7bef7fc7fbe831287b257bdd0d43a"
    ]
}

def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def assert_reviewed_runtime(test):
    historical_bytes = (DEV / 'Reviews/batch1-1/REVIEWED-RUNTIME.json').read_bytes()
    test.assertEqual(blob(historical_bytes), HISTORICAL_BLOB, 'Historical review must remain immutable')
    historical = json.loads(historical_bytes)['records']
    base_bytes = (DEV / 'Reviews/audio-corrections-b1/BASELINE-RUNTIME.json').read_bytes()
    test.assertEqual(blob(base_bytes), CORRECTION_BASELINE_BLOB, 'Frozen c80 runtime inventory')
    base = json.loads(base_bytes)
    lock = json.loads((DEV / 'Reviews/batch1-1-followup/REVIEWED-RUNTIME.json').read_text())
    test.assertEqual(lock['historical_ledger_blob'], HISTORICAL_BLOB)
    test.assertEqual(lock['integration_base'], BASE)
    current = {str(p.relative_to(DEV)): p for p in (DEV / 'Source/Runtime').rglob('*.lua')}
    test.assertEqual(len(current), 61)
    test.assertEqual(set(current), set(historical))
    test.assertEqual(set(current), set(base))
    test.assertEqual(set(current), set(lock['records']))
    for name, path in current.items():
        # c80 differs from the historical ledger only in staging-audition Config.
        expected_base = APPROVED[name][2] if name.endswith('/Config.lua') else historical[name]['blob_sha']
        test.assertEqual(base[name], expected_base, name + ' c80 provenance')
        expected = dict(historical[name])
        if name in APPROVED:
            pr, head, sha = APPROVED[name]
            expected = {'blob_sha': sha, 'review_pr': pr, 'source_head': head}
        test.assertEqual(lock['records'][name], expected, name + ' reviewed owner/head/blob')
        test.assertEqual(blob(path.read_bytes()), expected['blob_sha'], name + ' current bytes')
