"""Review source silhouettes and entry envelopes, never native appearance/physics.

Run Tests/infected-geometry.luau first. Meshes are bounding proxies; textured
surfaces, engine lighting, animation replication and audio require Studio.
"""
from pathlib import Path
import itertools
import json
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Ellipse, Rectangle

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path, default=ROOT / 'Reviews/infected-batch1')
args = parser.parse_args()
args.out.mkdir(parents=True, exist_ok=True)
data = json.loads((ROOT / 'Validation/InfectedBatch1/Geometry.json').read_text())
plt.rcParams.update({'svg.fonttype': 'none', 'font.family': 'DejaVu Sans',
                     'font.size': 9, 'figure.facecolor': '#111b22',
                     'text.color': '#e5ebeb', 'axes.facecolor': '#16232c'})
eye = np.array([.62, .23, -1.0]); eye /= np.linalg.norm(eye)
right = np.cross(-eye, [0, 1, 0]); right /= np.linalg.norm(right)
up = np.cross(right, -eye)
project = np.array([right, up])

def model(ax, rows, limits=(-2.3, 2.3, -3.8, 4.2)):
    shapes = []
    for p in rows:
        if p['transparency'] >= .85 or p['name'] == 'HumanoidRootPart':
            continue
        cf = np.array(p['cf']); center = cf[:3]; rot = cf[3:].reshape(3, 3)
        half = np.array(p['size']) / 2; color = np.array(p['color'])
        if p.get('shape') == 'Ball':
            cov = project @ rot @ np.diag(half ** 2) @ rot.T @ project.T
            vals, vecs = np.linalg.eigh(cov)
            xy = project @ center
            angle = np.degrees(np.arctan2(vecs[1, 1], vecs[0, 1]))
            patch = Ellipse(xy, 2 * np.sqrt(vals[1]), 2 * np.sqrt(vals[0]),
                            angle=angle, facecolor=np.clip(color * .85, 0, 1),
                            edgecolor='#1a2528', linewidth=.15)
            shapes.append((center @ eye, patch))
            continue
        for axis in range(3):
            other = [i for i in range(3) if i != axis]
            for sign in (-1, 1):
                normal = rot[:, axis] * sign
                if normal @ eye <= 0:
                    continue
                points = []
                for a, b in ((-1, -1), (-1, 1), (1, 1), (1, -1)):
                    q = np.zeros(3); q[axis] = sign * half[axis]
                    q[other[0]] = a * half[other[0]]
                    q[other[1]] = b * half[other[1]]
                    points.append(center + rot @ q)
                points = np.array(points)
                shade = .65 + .35 * max(0, normal @ eye)
                patch = Polygon(points @ project.T, facecolor=np.clip(color * shade, 0, 1),
                                edgecolor='#1a2528', linewidth=.15)
                shapes.append((points.mean(axis=0) @ eye, patch))
    for _, patch in sorted(shapes, key=lambda x: x[0]):
        ax.add_patch(patch)
    ax.set(xlim=limits[:2], ylim=limits[2:], aspect='equal')
    ax.set_xticks([]); ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_color('#334852')

def save(fig, name):
    fig.savefig(args.out / f'{name}.svg', bbox_inches='tight', pad_inches=.2)
    fig.savefig(args.out / f'{name}.png', bbox_inches='tight', pad_inches=.2, dpi=145)
    plt.close(fig)

station = [x for x in data['rigs'] if x['map'] == 'Station' and x['kind'] == 'Shambler']
fig, axes = plt.subplots(2, 6, figsize=(12, 7))
for col, rig in enumerate(station):
    for row, field in enumerate(('before', 'after')):
        model(axes[row, col], rig[field])
    axes[0, col].set_title(rig['family'], pad=8)
axes[0, 0].set_ylabel('Parent #19', color='#9fb4bd', labelpad=12)
axes[1, 0].set_ylabel('Batch 1 candidate', color='#a8c0ab', labelpad=12)
fig.suptitle('Blackwater military infected — comparable source silhouettes', fontsize=15, y=.98)
fig.text(.5, .02, 'Offline geometry study. Imported mesh bounds are proxies; textures and native appearance are unverified.', ha='center', color='#a8bac2')
fig.subplots_adjust(left=.055, right=.99, top=.90, bottom=.07, wspace=.08, hspace=.08)
save(fig, 'uniforms-before-after')

fig, axes = plt.subplots(2, 4, figsize=(12, 6.5))
for col, (map_id, family) in enumerate((('Station', 'K9'), ('Station', 'Alpha'), ('Foundry', 'K9'), ('Frost', 'K9'))):
    rig = next(x for x in data['rigs'] if x['map'] == map_id and x['family'] == family)
    for row, field in enumerate(('before', 'after')):
        model(axes[row, col], rig[field], (-3.6, 3.6, -2.8, 3.8))
    axes[0, col].set_title(f'{map_id} / {family}', pad=8)
axes[0, 0].set_ylabel('Retained canine base', color='#9fb4bd', labelpad=12)
axes[1, 0].set_ylabel('Batch 1 candidate', color='#a8c0ab', labelpad=12)
fig.suptitle('Military K9 — muzzle, ears, harness and retained Alpha evolution', fontsize=15, y=.98)
fig.text(.5, .02, 'Same viewing scale in each panel. Mesh bounds are proxies. Gait/leap/damage animation requires Studio review.', ha='center', color='#a8bac2')
fig.subplots_adjust(left=.055, right=.99, top=.9, bottom=.07, wspace=.08, hspace=.08)
save(fig, 'k9-before-after')

fig, axes = plt.subplots(1, 3, figsize=(12, 5))
colors = {'Approach': '#8dd0cc', 'Contact': '#efd68b', 'Cross': '#dba17b', 'Land': '#a3c997', 'Settle': '#a3c997'}
for ax, site in zip(axes, data['maps']):
    paths = [p for p in site['paths'] if p['window'] == 1]
    window = site['windows'][0]
    origin = np.array(window['barrier']); inward = np.array(window['inside']) - np.array(window['outside'])
    inward[1] = 0; inward /= np.linalg.norm(inward)
    # Project the actual path and colliders onto the breach's vertical section.
    for p in site['colliders']:
        if p['group'] in ('DeadSignalBounds', 'DeadSignalWindow'):
            continue
        cf = np.array(p['cf']); rot = cf[3:].reshape(3, 3); half = np.array(p['size']) / 2
        tangent = np.cross(inward, [0, 1, 0])
        if abs((cf[:3] - origin) @ tangent) > abs(tangent @ rot) @ half + .2:
            continue
        verts = np.array([cf[:3] + rot @ (np.array(signs) * half) for signs in itertools.product((-1, 1), repeat=3)])
        x = (verts - origin) @ inward; y = verts[:, 1]
        if x.max() >= -12 and x.min() <= 15:
            ax.add_patch(Rectangle((x.min(), y.min()), np.ptp(x), np.ptp(y), facecolor='#34444c', alpha=.7))
    for path in paths:
        positions = np.array([s['position'] for s in path['samples']])
        x = (positions - origin) @ inward
        feet = positions[:, 1] - path['rootHeight']
        if path['kind'] == 'Warden':
            ax.fill_between(x, feet, feet + path['height'], color='#b18bd0', alpha=.16, label='Warden envelope')
        if path['kind'] in ('Shambler', 'Warden') or path['alpha']:
            label = 'Alpha' if path['alpha'] else path['kind']
            ax.plot(x, feet, lw=1.6, label=label + ' feet')
    human = next(p for p in paths if p['kind'] == 'Shambler')
    for stage in ('Approach', 'Contact', 'Cross', 'Land'):
        s = next(s for s in human['samples'] if s['stage'] == stage)
        point = np.array(s['position']); x = (point - origin) @ inward
        ax.scatter([x], [point[1] - human['rootHeight']], color=colors[stage], s=22, zorder=10)
    ax.set(title=site['id'] + ' / breach 1', xlim=(-12, 15), ylim=(-1, 21), xlabel='Studs along approach', ylabel='World Y (studs)')
    ax.tick_params(colors='#b9c9cf'); ax.xaxis.label.set_color('#b9c9cf'); ax.yaxis.label.set_color('#b9c9cf')
    for spine in ax.spines.values(): spine.set_color('#334852')
    ax.grid(alpha=.15); ax.legend(fontsize=7, facecolor='#16232c', labelcolor='#e5ebeb')
fig.suptitle('Exterior → contact → cross → landing: actual generated-map source paths', fontsize=14)
fig.text(.5, .01, 'Conservative source collider projection. 3D swept boxes are tested separately; this view does not establish native physics.', ha='center', color='#a8bac2')
fig.tight_layout(rect=(0, .05, 1, .94))
save(fig, 'entry-sections')
print('Wrote three source review SVG/PNG pairs to', args.out)
