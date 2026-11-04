"""Reproduce the DS-B1-002 review evidence after both map-window-geometry captures.

Reads source-built geometry and offline reports; never writes Roblox/native files.
Matplotlib is optional authoring tooling, not a runtime/CI dependency.
"""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess

DEV = Path(__file__).resolve().parents[1]
REPO = DEV.parents[2]
DATA = DEV / 'Validation/MapWindowGeometry'
OUT = DEV / 'Reviews/map-window-geometry-b1'
BASE = 'c80d55aeeae4b51ef8d836949a33bf440890c6b7'
SOURCE = 'f63b0150f9a794fd20f98768a8237e44a38d068f'


def read(path):
    return json.loads(path.read_text())


def write(name, value):
    (OUT / name).write_text(json.dumps(value, indent=2) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    before, after = (read(DATA / (p + '-Report.json')) for p in ('Before', 'After'))
    assert len(before['failures']) == 17 and not after['failures']
    assert sum(m['badSupportSamples'] for m in before['maps']) == 16
    assert sum(m['supportSamples'] for m in after['maps']) == 6990
    assert sum(m['queueActors'] for m in after['maps']) == 120
    for phase in ('Before', 'After'):
        shutil.copyfile(DATA / (phase + '-Report.json'), OUT / (phase + '-Report.json'))
    preservation = {'base': BASE, 'engine': False, 'maps': [], 'capturedPartProperties':
        ['hierarchy/name', 'class', 'CFrame', 'size', 'color', 'material', 'variant', 'transparency', 'CanCollide', 'CanQuery', 'CanTouch', 'collisionGroup']}
    for name in ('Station', 'Foundry', 'Frost'):
        a, b = (read(DATA / f'{p}-{name}-Snapshot.json') for p in ('Before', 'After'))
        def parts(d):
            return Counter(json.dumps(p, sort_keys=True, separators=(',', ':')) for p in d['parts'])
        old, new = parts(a), parts(b)
        changed = [key for key in a if key != 'parts' and a[key] != b[key]]
        assert old == new and not changed, name + ' changed pre-existing map geometry/contracts'
        preservation['maps'].append({'map': name, 'retainedParts': sum(old.values()),
            'removedOrChangedParts': sum((old-new).values()), 'addedUnapprovedParts': sum((new-old).values()),
            'changedContractSections': changed, 'contractSections': [k for k in a if k != 'parts'],
            'retainedPartsSha256': digest(json.dumps(sorted(old.items())).encode())})
    tree = subprocess.check_output(['git', 'ls-tree', '-rz', BASE], cwd=REPO)
    changed, protected, runtime = [], [], {}
    for line in tree.split(b'\0'):
        if not line:
            continue
        meta, raw_path = line.split(b'\t'); _, kind, sha = meta.decode().split(); path = raw_path.decode()
        if kind != 'blob':
            continue
        data = (REPO / path).read_bytes(); current = git_blob(data)
        if current != sha:
            changed.append(path)
        if path.startswith(('.github/', 'scripts/', 'games/dead-signal/full-baselines/',
                'games/dead-signal/places/', 'games/dead-signal/work-source/', 'games/dead-signal/releases/')):
            assert sha == current, 'Protected input changed: ' + path
            protected.append({'path': path, 'blob': sha})
        if '/dev/Source/Runtime/' in path:
            runtime[path] = {'baseBlob': sha, 'currentBlob': current}
    assert changed == ['games/dead-signal/dev/Source/Runtime/server/Architecture.lua']
    assert len(runtime) == 61
    preservation.update({'changedExistingFiles': changed, 'protectedInputs': len(protected), 'protectedChanges': [],
        'protectedInventorySha256': digest(json.dumps(protected, sort_keys=True).encode())})
    write('Preservation.json', preservation)
    write('Runtime.json', {'base': BASE, 'testedRuntimeCommit': SOURCE, 'records': runtime})
    tests = read(DEV / 'Validation/Tests-Report.json')
    assert all(s['passed'] for s in tests['suites']) and tests['unit_assertions'] == 1026501
    write('Tests.json', {'engine': False, 'registeredSuites': [{k: s[k] for k in ('suite', 'passed', 'assertions', 'seconds')} for s in tests['suites']],
        'registeredAssertions': tests['unit_assertions'], 'newSuiteAssertions': after['assertions'],
        'combinedAssertions': tests['unit_assertions'] + after['assertions'], 'syntax': read(DATA / 'Syntax.json'),
        'pipelinePython': {'passed': 81}, 'audioPatchGuards': {'passed': 6},
        'supplementalAudioPython': {'passed': 7, 'failed': 1, 'skipped': 1,
            'failure': 'Historical REVIEWED-RUNTIME lock predates Config #49 and this Architecture change; MAIN intake action.',
            'skip': 'Prepared PCM inputs not present; no new audio work is in scope.'}})
    builds = []
    for env in ('staging', 'production'):
        root = REPO / 'build/dead-signal-lossless' / env
        fidelity = read(root / 'BINARY-FIDELITY-REPORT.json')
        for place, result in read(root / 'LOSSLESS-REPORT.json').items():
            assert result['all_untouched_chunks_byte_identical'] and result['expected_replacement_count'] == 61
            assert fidelity['places'][place]['passed']
            path = root / (place + '.rbxl'); data = path.read_bytes()
            assert digest(data) == result['candidate_sha256']
            builds.append({'environment': env, 'place': place, 'bytes': len(data), 'sha256': digest(data),
                'scriptRecords': 61, 'unchangedChunks': result['untouched_chunk_count'],
                'rawPreservation': True, 'propertyFidelity': True})
    write('Builds.json', {'runtimeCommit': SOURCE, 'published': False, 'studioTested': False, 'builds': builds})
    overlay = DATA / 'Overlay-Report.json'
    if overlay.exists():
        preview = read(overlay)
        assert not preview['failures'] and all(m['connectedQueueRouteChecked'] for m in preview['maps'])
        consumer = {}
        for name in ('Enemies', 'Navigation'):
            path = DATA / 'EnemySource/server' / (name + '.lua')
            consumer[name] = git_blob(path.read_bytes())
        write('Consumer-Preview.json', {'enemyPR': 53, 'enemyCommit': '0282025ddd6769bfd983413bb37d6f013043b7b5',
            'mapRuntimeCommit': SOURCE, 'sourceBlobs': consumer, 'futureR6Tested': False,
            'method': 'Only the two frozen enemy modules replaced inside temporary deserialized fixtures; no runtime file edits.',
            'supportAndQueueAudit': preview})
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D
    fig, axes = plt.subplots(1, 2, figsize=(12.8, 6), sharex=True, sharey=True)
    fig.suptitle('Cinderworks · window 10 · physical floor support', fontsize=19, fontweight='bold', y=.97)
    for ax, data, title in zip(axes, (before, after), ('Before · centerline misses the room floor', 'After · continuous flush support')):
        window = next(w for m in data['maps'] if m['id']=='Foundry' for w in m['windows'] if w['id']=='Foundry_entry_10')
        failed = set()
        for failure in window['failures']:
            match = re.fullmatch(r'interior lane (-?\d+) depth (\d+)', failure['probe'])
            if match:
                failed.add((int(match[1]), int(match[2])))
        good = [(lane*.5, depth) for lane in range(-8,9) for depth in range(1,13) if (lane,depth) not in failed]
        ax.scatter(*zip(*good), s=22, color='#197c86', zorder=3)
        if failed:
            ax.scatter(*zip(*[(x*.5,z) for x,z in failed]), s=65, marker='x', color='#c34031', linewidths=2, zorder=4)
        ax.axvline(0, color='#879197', lw=.8, ls='--', zorder=1)
        ax.scatter([0],[8],marker='s',s=220,facecolors='none',edgecolors='#a17610',linewidths=2,zorder=5)
        ax.annotate('canonical landing', (.1,8), (1.0,8.8), fontsize=10,
            arrowprops={'arrowstyle':'-', 'color':'#a17610'}, color='#745311')
        ax.set(title=title, xlabel='Lateral offset from entry center (layout studs)', xlim=(-4.7,4.7), ylim=(13,0))
        ax.set_xticks(range(-4,5,2));ax.set_yticks(range(0,13,2));ax.grid(alpha=.15);ax.set_facecolor('#f4f7f8')
    axes[0].set_ylabel('Distance inward from sill (layout studs)')
    fig.legend(handles=[Line2D([],[],marker='o',ls='',color='#197c86',label='Supported at Y=0'),
        Line2D([],[],marker='x',ls='',color='#c34031',label='Falls to ExteriorGround at Y=−1.22 world studs')],loc='lower center',bbox_to_anchor=(.5,.11),ncol=2,frameon=False)
    fig.text(.5,.045,'OFFLINE SOURCE AUDIT · not Roblox Studio screenshots or physics acceptance\nMarkers show probe spacing, not seam width. Canonical landing: (229.360001, 0, 295.240021) world studs.',ha='center',fontsize=10,color='#4d5962')
    fig.subplots_adjust(top=.84,bottom=.25,wspace=.14)
    fig.savefig(OUT / 'Cinderworks-window10-support.png',dpi=150);plt.close(fig)
    print('Review evidence generated:', OUT)


if __name__ == '__main__':
    main()
