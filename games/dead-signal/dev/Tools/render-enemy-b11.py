"""Render labeled pose comparisons. Mesh parts are bounds, never textured art."""
from pathlib import Path
import itertools
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

ROOT = Path(__file__).resolve().parent.parent
data = json.loads((ROOT / 'Validation/EnemyB11/Visual.json').read_text())
out = ROOT / 'Reviews/enemies-batch1-1'
out.mkdir(parents=True, exist_ok=True)
plt.rcParams.update({'svg.fonttype': 'none', 'font.family': 'DejaVu Sans', 'font.size': 9})

def hull(points):
    pts = sorted(set(map(tuple, points)))
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) > 1 and cross(lower[-2], lower[-1], p) <= 0: lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) > 1 and cross(upper[-2], upper[-1], p) <= 0: upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]

def draw(ax, row):
    for part in sorted(row['parts'], key=lambda p: p['cf'][0], reverse=True):
        cf = np.array(part['cf']); rot = cf[3:].reshape(3, 3)
        pts = np.array([cf[:3] + rot @ (np.array(v) * part['size'] / 2)
                        for v in itertools.product((-1, 1), repeat=3)])
        # Side view: the -Z forward axis points left. Convex bounds are explicit proxies.
        xy = pts[:, [2, 1]]
        ax.add_patch(Polygon(hull(xy), facecolor=part['color'],
                             alpha=.18 if part['mesh'] else .45,
                             edgecolor='#62716e', linewidth=.25))
    color = '#247aa3' if row['revision'] == 'before' else '#914b28'
    for joint in row['joints']:
        a, b = joint['a'], joint['b']
        ax.plot([a[2], b[2]], [a[1], b[1]], color=color, lw=1.7, marker='o', ms=2)
    ax.set(xlim=(-3.8, 2.8), ylim=(-4.8, 5.5), aspect='equal')
    ax.axhline(0, color='#bac5c3', lw=.5); ax.set_xticks([]); ax.set_yticks([])
    for spine in ax.spines.values(): spine.set_color('#c6cdca')

for map_id, title in [('Station', 'Blackwater'), ('Foundry', 'Cinderworks'), ('Frost', 'Whiteout')]:
    fig, axs = plt.subplots(2, 4, figsize=(14, 9))
    for y, revision in enumerate(('before', 'after')):
        for x, action in enumerate(('idle', 'run', 'attack', 'climb')):
            row = next(r for r in data['snapshots'] if r['map'] == map_id and
                       r['revision'] == revision and r['action'] == action)
            draw(axs[y, x], row)
            axs[y, x].set_title(f"{revision.title()} · {action} · {row['kind']}")
    fig.suptitle(f'{title} — retained rig pose comparison', fontsize=16)
    fig.text(.5, .018, 'OFFLINE PART BOUNDS + JOINTS · -Z forward points left · '
             'Not native triangles, textures, lighting or gameplay evidence. Studio review pending.',
             ha='center', fontsize=10)
    fig.tight_layout(rect=(0, .045, 1, .95))
    fig.savefig(out / f'{map_id.lower()}-poses.svg')
    fig.savefig(ROOT / f'Validation/EnemyB11/{map_id.lower()}-poses.png', dpi=110)
    plt.close(fig)
print('Rendered three explicitly labeled offline comparisons')
