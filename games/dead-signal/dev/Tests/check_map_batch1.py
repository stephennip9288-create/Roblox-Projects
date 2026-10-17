"""Conservative 3D route-envelope audit of exported source geometry, not Roblox physics.

Run map_remaster.luau first. NumPy/SciPy are optional local audit dependencies.
Floor continuity and ramp openings are checked by map_batch1.luau; this checks
other colliders alongside/above both ramps and the entire elevated circuit.
"""
from pathlib import Path
import itertools
import json
import math
import numpy as np
from scipy.spatial import ConvexHull

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'Validation/MapRemaster'
OUT = ROOT / 'Validation/MapBatch1'


def audit(data, contract):
    radius = contract['agentRadius'] + .15
    height = contract['agentHeight']
    shapes = []
    for p in data['colliders']:
        if p['group'] == 'DeadSignalBounds' or p['name'].startswith('Gate'):
            continue
        if p['name'] in ('StairRamp', 'SectorFloor', 'CorridorFloor', 'UpperGalleryDeck', 'ExteriorGround'):
            continue
        cf = np.array(p['cf']); rotation = cf[3:].reshape(3, 3); half = np.array(p['size']) / 2
        extent = np.abs(rotation) @ half
        signs = [(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)] if p['class']=='WedgePart' else list(itertools.product((-1, 1), repeat=3))
        points = np.array([(cf[:3] + rotation @ (np.array(s) * half))[[0, 2]] for s in signs])
        hull = points[ConvexHull(points).vertices]
        edges = np.roll(hull, -1, axis=0) - hull
        shapes.append((p['name'], cf[1] - extent[1], cf[1] + extent[1], hull, edges,
                       points.min(axis=0) - radius, points.max(axis=0) + radius))
    samples = 0; failures = []
    def sweep(a, b, label):
        nonlocal samples
        a, b = np.array(a), np.array(b)
        for t in np.linspace(0, 1, max(2, math.ceil(np.linalg.norm(b-a) / .65))):
            p = a * (1-t) + b * t; samples += 1
            for name, bottom, top, hull, edges, lo, hi in shapes:
                if top <= p[1] + .35 or bottom >= p[1] + height - .15:
                    continue
                q = p[[0, 2]]
                if np.any(q < lo) or np.any(q > hi):
                    continue
                offset = q - hull
                distance = edges[:, 0]*offset[:, 1] - edges[:, 1]*offset[:, 0]
                if np.all(distance >= -radius*np.linalg.norm(edges, axis=1)):
                    failures.append({'route': label, 'collider': name, 'position': p.tolist()})
                    break
    for g in contract['galleries']:
        for i, stair in enumerate(g['stairs'], 1):
            sweep(stair['base'], stair['top'], f"room {g['room']} ramp {i}")
        for i, a in enumerate(g['ring']):
            sweep(a, g['ring'][(i+1) % len(g['ring'])], f"room {g['room']} circuit {i+1}")
    return {'map': data['id'], 'samples': samples, 'agentRadius': radius,
            'agentHeight': height, 'sampleSpacing': .65, 'failures': failures,
            'method': 'inflated oriented collider hulls and vertical intervals; excludes support geometry',
            'robloxPhysics': False}


if __name__ == '__main__':
    contracts = json.loads((OUT/'Contracts-Report.json').read_text())
    reports = [audit(json.loads((DATA/f"{c['id']}-Geometry.json").read_text()), c)
               for c in contracts['maps']]
    (OUT/'Elevated-Clearance-Report.json').write_text(json.dumps({'checks': reports, 'engine': False}, indent=2))
    for r in reports:
        print(r['map'], r['samples'], 'swept samples;', len(r['failures']), 'obstructions')
        for f in r['failures'][:8]: print(f)
    assert all(not r['failures'] for r in reports), 'Elevated source envelope audit failed'
