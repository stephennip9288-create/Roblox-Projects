"""Reproducible offline source previews; not Roblox screenshots or art acceptance."""
from pathlib import Path
import html
import itertools
import json
import shutil
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
data = json.loads((ROOT / 'Validation/EnemyB1Followup/Visual.json').read_text())
out = ROOT / 'Reviews/enemy-b1-r6-followup'
out.mkdir(parents=True, exist_ok=True)

def png(source, target):
    renderer = shutil.which('inkscape')
    if renderer:
        subprocess.run([renderer,str(source),'--export-type=png','--export-filename='+str(target)],check=True,capture_output=True)

def color(v):
    return '#' + ''.join(f'{round(c * 255):02x}' for c in v)

def text(x, y, value, size=14, fill='#d0d7d2'):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}">{html.escape(value)}</text>'

def begin(w, h, title, subtitle):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
            '<rect width="100%" height="100%" fill="#17201e"/>',
            '<g font-family="DejaVu Sans,sans-serif">', text(28, 38, title, 25), text(28, 65, subtitle, 13, '#9eafa6')]

def hull(points):
    points = sorted(set(map(tuple, points)))
    def cross(a,b,c):
        return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lower,upper=[],[]
    for p in points:
        while len(lower)>1 and cross(lower[-2],lower[-1],p)<=0: lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper)>1 and cross(upper[-2],upper[-1],p)<=0: upper.pop()
        upper.append(p)
    return lower[:-1]+upper[:-1]

def draw(row, x, y, scale=38, side=False):
    pieces = []
    for part in row['parts']:
        cf = np.array(part['cf']); rot = cf[3:].reshape(3, 3); size = np.array(part['size'])
        pts = np.array([cf[:3] + rot @ (np.array(v) * size / 2) for v in itertools.product((-1, 1), repeat=3)])
        # Convex bounds only, including meshes and rounded Roblox parts.
        proj = pts[:, [2 if side else 0, 1]]
        coords = ' '.join(f'{x+a*scale:.2f},{y-b*scale:.2f}' for a,b in hull(proj))
        depth = -pts[:, 0].mean() if side else pts[:, 2].mean()
        pieces.append((depth, f'<polygon points="{coords}" fill="{color(part["color"])}" fill-opacity="{.45 if part["mesh"] else 1}" stroke="#111a17" stroke-width=".6"/>'))
    for gui in ([] if side else row['guis']):
        cf = np.array(gui['cf']); rot = cf[3:].reshape(3,3); size = np.array(gui['size'])
        top = cf[:3] + rot @ np.array([-size[0]/2, size[1]/2, -size[2]/2-.007])
        a,b = rot[0,0]*size[0]*scale/192, -rot[1,0]*size[0]*scale/192
        c,d = -rot[0,1]*size[1]*scale/192, rot[1,1]*size[1]*scale/192
        g = [f'<g transform="matrix({a:.5f} {b:.5f} {c:.5f} {d:.5f} {x+top[0]*scale:.3f} {y-top[1]*scale:.3f})">']
        for m in gui['marks']:
            radius = min(m['w'],m['h'])*.38 if m['rounded'] else 0
            g.append(f'<rect x="{m["x"]}" y="{m["y"]}" width="{m["w"]}" height="{m["h"]}" rx="{radius}" fill="{color(m["color"])}" opacity="{m["alpha"]:.3f}" transform="rotate({m["rotation"]} {m["x"]+m["w"]/2} {m["y"]+m["h"]/2})"/>')
        g.append('</g>');pieces.append((top[2], ''.join(g)))
    return ''.join(p[1] for p in sorted(pieces, key=lambda p:p[0], reverse=True))

svg = begin(1440, 1235, 'Dead Signal · R6 infected source review',
            'OFFLINE ORTHOGRAPHIC BOUNDS + VECTOR FACE MARKS · No engine materials, lighting, mesh triangles or gameplay evidence')
names = {'Station':'Blackwater · military / communications','Foundry':'Cinderworks · industrial / security','Frost':'Whiteout · worn winter equipment'}
for mi, map_id in enumerate(names):
    top = 100 + mi*365
    svg.append(text(28, top, names[map_id], 20, '#e4d4ac'))
    for vi in range(6):
        row = next(r for r in data['families'] if r['map']==map_id and r['id']==vi+1)
        x = 120+vi*235
        svg.append(draw(row,x,top+142))
        svg.append(text(x-88,top+283,row['role'],13))
        svg.append(text(x-88,top+304,f'{row["counts"]["parts"]} parts · 6 driving joints',12,'#9eafa6'))
svg += [text(28,1211,'Studio review pending: facial projection, joint motion, silhouettes, collision, crowds, multiplayer and mobile cost.',13),'</g></svg>']
(out/'R6-families.svg').write_text(''.join(svg))
png(out/'R6-families.svg', ROOT/'Validation/EnemyB1Followup/R6-families.png')

svg = begin(1380,850,'Dead Signal · before / R6 pose bounds',
            'Blackwater representatives · c80d55a before / source under review · mesh geometry shown only as transparent boxes')
for ri,rev in enumerate(('before','after')):
    for ai,action in enumerate(('idle','run','attack','climb')):
        row=next((r for r in data['comparisons'] if r['map']=='Station' and r['revision']==rev and r['action']==action),None)
        if row is None: continue
        x,y=175+ai*335,240+ri*350
        svg.append(text(x-130,y-120,f'{rev.title()} · {action} · {row["kind"]}',16))
        svg.append(draw(row,x,y,32,side=True))
        svg.append(text(x-130,y+170,f'{row["counts"]["parts"]} parts · {row["counts"]["motors"]} joints',13))
svg += [text(28,825,'OFFLINE SOURCE COMPARISON · Not Roblox screenshots, animation playback or proof of traversal/visual acceptance.',13),'</g></svg>']
(out/'Before-after-poses.svg').write_text(''.join(svg))
png(out/'Before-after-poses.svg', ROOT/'Validation/EnemyB1Followup/Before-after-poses.png')
print('Rendered two explicitly labeled source review sheets')
