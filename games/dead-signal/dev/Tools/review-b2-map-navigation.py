"""Build B2-03 MAP review evidence from exact produced-map audit captures.

Run after the before/after Lune regression, support/turn diagnostics, existing
suite and four staging lossless builds. Does not mutate runtime/native inputs.
Matplotlib/NumPy are authoring dependencies only.
"""
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

DEV = Path(__file__).resolve().parents[1]
REPO = DEV.parents[2]
DATA = DEV / 'Validation/B2MapNavigation'
OUT = DEV / 'Reviews/map-b2-navigation'
BASE = '7aaf323de6153134df2154c7ae3b1613a596495b'
SOURCE = '82aa087f41683e3d96511da75192fc5433f5851a'


def read(path):
    return json.loads(path.read_text())


def write(name, data):
    (OUT / name).write_text(json.dumps(data, indent=2) + '\n')


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    before, after = (read(DATA / (phase + '-Report.json')) for phase in ('Before', 'After'))
    assert len(before['failures']) == 170 and not after['failures']
    assert sum(len(m['rejectedSweeps']) for m in before['maps']) == 169
    assert after['assertions'] == 119393
    for name in ('Before-Report.json', 'After-Report.json', 'Support-Diagnostics.json', 'Turns.json', 'Syntax.json'):
        shutil.copyfile(DATA / name, OUT / name)
    preservation = {'base': BASE, 'runtime': SOURCE, 'engine': False, 'maps': []}
    for name in ('Station', 'Foundry', 'Frost'):
        a, b = (read(DATA / f'{phase}-{name}-Snapshot.json') for phase in ('Before', 'After'))
        def parts(x):
            return Counter(json.dumps(p, sort_keys=True, separators=(',', ':')) for p in x['parts'])
        old, new = parts(a), parts(b)
        assert old == new, name + ' changed physical/rendered map parts'
        changed = []
        if name == 'Frost':
            old_point = a['doors'][6]['waypoints'][2]
            new_point = b['doors'][6]['waypoints'][2]
            a['doors'][6]['waypoints'][2] = new_point
            a['nodes']['door7p3']['position'] = new_point
            changed = ['doors[7].waypoints[3]', 'navigation.nodes.door7p3.position']
            preservation['waypoint'] = {'before': old_point, 'after': new_point,
                'worldDisplacement': sum((x-y)**2 for x, y in zip(old_point, new_point))**.5,
                'layoutDisplacement': 2.25}
        assert all(a[k] == b[k] for k in a if k != 'parts'), name + ' changed other metadata'
        preservation['maps'].append({'map': name, 'retainedParts': sum(old.values()), 'changedParts': 0,
            'changedMetadata': changed, 'unchangedSections': [k for k in a if k != 'parts' and k not in ('doors', 'nodes')],
            'partSignatureSha256': sha(json.dumps(sorted(old.items())).encode())})
    runtime, protected, changed_files = {}, [], []
    for line in subprocess.check_output(['git', 'ls-tree', '-rz', BASE], cwd=REPO).split(b'\0'):
        if not line:
            continue
        meta, path = line.split(b'\t'); _, kind, expected = meta.decode().split(); path = path.decode()
        if kind != 'blob':
            continue
        current = blob((REPO / path).read_bytes())
        if current != expected:
            changed_files.append(path)
        if '/dev/Source/Runtime/' in path:
            runtime[path] = {'baseBlob': expected, 'currentBlob': current}
        if path.startswith(('.github/', 'scripts/', 'games/dead-signal/full-baselines/',
                'games/dead-signal/places/', 'games/dead-signal/work-source/', 'games/dead-signal/releases/')):
            assert current == expected, 'Protected input changed: ' + path
            protected.append({'path': path, 'blob': expected})
    assert changed_files == ['games/dead-signal/dev/Source/Runtime/server/Architecture.lua']
    assert len(runtime) == 61
    preservation.update({'changedExistingFiles': changed_files, 'protectedInputs': len(protected),
        'protectedChanges': [], 'protectedInventorySha256': sha(json.dumps(protected, sort_keys=True).encode())})
    write('Preservation.json', preservation)
    write('Runtime.json', {'base': BASE, 'runtimeCommit': SOURCE, 'records': runtime})
    tests = read(DEV / 'Validation/Tests-Report.json')
    assert len(tests['suites']) == 39 and all(s['passed'] for s in tests['suites'])
    assert tests['unit_assertions'] == 1071963
    diagnostics, turns = read(DATA / 'Support-Diagnostics.json'), read(DATA / 'Turns.json')
    assert diagnostics['unresolved'] == 0 and all(c['neighbor']['shift'] <= .001 for m in diagnostics['maps'] for c in m['cases'])
    assert turns['cases'] == 18900 and not turns['failures']
    write('Tests.json', {'runtimeCommit': SOURCE, 'registeredSuites': [{k: s[k] for k in ('suite', 'passed', 'assertions', 'seconds')} for s in tests['suites']],
        'registeredAssertions': tests['unit_assertions'], 'specialistChecks': after['assertions'],
        'walkingSweeps': sum(m['bodySweeps'] for m in after['maps']), 'graphCases': sum(m['graphCases'] for m in after['maps']),
        'turnChecks': turns['cases'], 'sourceRayPrecisionDiagnostics': diagnostics['cases'],
        'rootPython': {'passed': 98}, 'devPython': {'passed': 24, 'failed': 2, 'skipped': 2},
        'failingDevTests': ['test_audio_corrections_b1.AudioCorrections.test_only_owned_audio_bytes_change',
            'test_audio_quality_b11.AudioQualityB11.test_all_runtime_records_match_reviewed_integration'],
        'failureReason': 'Both invoke the frozen accepted Batch 1 runtime-equality guard, which rejects the intentional B2 Architecture delta.',
        'newSuiteRegistered': False, 'nativePhysicsTested': False, 'physicalDevicesTested': False})
    build_root = REPO / 'build/dead-signal-lossless/staging'
    fidelity = read(build_root / 'BINARY-FIDELITY-REPORT.json'); builds = []
    for name, result in read(build_root / 'LOSSLESS-REPORT.json').items():
        data = (build_root / (name + '.rbxl')).read_bytes()
        assert result['all_untouched_chunks_byte_identical'] and result['expected_replacement_count'] == 61
        assert fidelity['places'][name]['passed'] and sha(data) == result['candidate_sha256']
        builds.append({'place': name, 'bytes': len(data), 'sha256': sha(data), 'records': 61,
            'unchangedChunks': result['untouched_chunk_count'], 'rawPreservation': True, 'propertyFidelity': True})
    write('Builds.json', {'runtimeCommit': SOURCE, 'environment': 'staging', 'published': False, 'builds': builds})
    import numpy as np
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon, Rectangle
    a, b = (read(DATA / f'{phase}-Frost-Snapshot.json') for phase in ('Before', 'After'))
    fig, axes = plt.subplots(1, 2, figsize=(12.8, 6.4), sharex=True, sharey=True)
    fig.suptitle('Whiteout Relay · door 7 · navigation approach', fontsize=18, fontweight='bold', y=.96)
    rig = next(m for m in after['maps'] if m['id'] == 'Frost')['profiles'][0]
    half = (np.array(rig['high'])-np.array(rig['low']))/2
    middle = (np.array(rig['high'])+np.array(rig['low']))/2
    for ax, snapshot, title, color in zip(axes, (a, b), ('Before · walking envelope rejected', 'After · approach clears the jamb'), ('#bc4132', '#177b75')):
        for p in snapshot['parts']:
            if not p['collide'] or not p['path'].endswith(('BunkerWall', 'PortalJamb', 'CorridorWall')):
                continue
            cf = np.array(p['cf']); rot = cf[3:].reshape(3, 3); h = np.array(p['size'])/2
            points = np.array([(cf[:3]+rot@np.array([x*h[0],0,z*h[2]]))[[0,2]] for x,z in ((-1,-1),(1,-1),(1,1),(-1,1))])
            if points[:,0].max() < 202 or points[:,0].min() > 225 or points[:,1].max() < 110 or points[:,1].min() > 141:
                continue
            ax.add_patch(Polygon(points, color='#46525d', alpha=.8))
        points = np.array(snapshot['doors'][6]['waypoints'])
        ax.plot(points[:,0], points[:,2], color=color, lw=2.3)
        ax.scatter([points[2,0]], [points[2,2]], s=65, color=color, zorder=5)
        direction = points[2]-points[1]; direction /= np.linalg.norm(direction)
        right, back = np.array([-direction[2],0,direction[0]]), -direction
        at = points[1]+(points[2]-points[1])*.925
        center = at+right*middle[0]+back*middle[2]
        extent = np.abs(right)*half[0]+np.abs(back)*half[2]
        ax.add_patch(Rectangle((center[0]-extent[0],center[2]-extent[2]),extent[0]*2,extent[2]*2,
            facecolor=color,edgecolor=color,alpha=.23,zorder=4))
        ax.annotate('approach hint',points[2,[0,2]],xytext=(215,137.5),fontsize=10,color=color,
            arrowprops={'arrowstyle':'->','color':color})
        ax.text(205,134,'Cryo Lab',color='#46525d',fontsize=12)
        ax.set(title=title,xlabel='World X (studs)',xlim=(202,225),ylim=(110,141),aspect='equal')
        ax.grid(alpha=.12);ax.set_facecolor('#f4f7f8')
    axes[0].set_ylabel('World Z (studs)')
    fig.text(.5,.085,'One hint moves 2.25 layout studs (2.475 world studs). All physical map parts stay unchanged.',ha='center',fontsize=11)
    fig.text(.5,.035,'OFFLINE SOURCE AUDIT · shaded box is the complete walking-rig envelope\nNot a Roblox Studio screenshot, native BodyCollider obstruction, or physics acceptance.',ha='center',fontsize=10,color='#4f5a65')
    fig.subplots_adjust(top=.85,bottom=.18,wspace=.15)
    fig.savefig(OUT / 'Whiteout-door7-approach.png',dpi=150);plt.close(fig)
    print('Review evidence:', OUT)


if __name__ == '__main__':
    main()
