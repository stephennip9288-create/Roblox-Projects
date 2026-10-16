from pathlib import Path
import json, math
import numpy as np
from collections import deque
from scipy.spatial import ConvexHull
from itertools import product
results=[]
for file in sorted(Path('Validation').glob('*-Geometry.json')):
 data=json.loads(file.read_text());key=data['key'];scale=data['scale'];step=1.0*scale
 layout=data['layout'];minx=min(r['x']-r['w']/2 for r in layout)*scale;maxx=max(r['x']+r['w']/2 for r in layout)*scale
 minz=min(r['z']-r['d']/2 for r in layout)*scale;maxz=max(r['z']+r['d']/2 for r in layout)*scale
 xs=np.arange(minx,maxx+.01,step);zs=np.arange(minz,maxz+.01,step);X,Z=np.meshgrid(xs,zs)
 floor=np.zeros(X.shape,dtype=bool);blocked=np.zeros_like(floor)
 def bounds(part):
  c=np.array(part['cf']);rot=c[3:].reshape((3,3));extent=np.abs(rot)@(np.array(part['size'])/2)
  return c[:3]-extent,c[:3]+extent
 def inpoly(poly):
  inside=np.zeros(X.shape,dtype=bool)
  for a,b in zip(poly,poly[1:]+poly[:1]):
   if abs(b[1]-a[1])>1e-8:
    inside^=((a[1]>Z)!=(b[1]>Z))&(X<(b[0]-a[0])*(Z-a[1])/(b[1]-a[1])+a[0])
  return inside
 for poly in data['floorRegions']:floor|=inpoly(poly)
 radius=1.70*scale
 for p in data['colliders']:
  lo,hi=bounds(p)
  if hi[1]<=.15 or lo[1]>=5.7*scale or p['name'].startswith('Gate') or p['name']=='StairRamp':continue
  c=np.array(p['cf']);rot=c[3:].reshape((3,3));half=np.array(p['size'])/2
  points=np.array([(c[:3]+rot@(np.array(signs)*half))[[0,2]] for signs in product([-1,1],repeat=3)])
  hull=points[ConvexHull(points).vertices]
  mask=np.ones(X.shape,dtype=bool)
  for a,b in zip(hull,np.roll(hull,-1,axis=0)):
   dx,dz=b-a;mask&=dx*(Z-a[1])-dz*(X-a[0])>=-radius*np.hypot(dx,dz)
  blocked|=mask
 walk=floor&~blocked
 start=next(x for x in data['objectives'] if x['name']=='Spawn 1')['position']
 ix=int(round((start[0]-minx)/step));iz=int(round((start[2]-minz)/step))
 assert walk[iz,ix],f'{key} spawn is geometrically obstructed'
 seen=np.zeros_like(walk);seen[iz,ix]=True;q=deque([(iz,ix)])
 while q:
  j,i=q.popleft()
  for dj,di in [(-1,0),(1,0),(0,-1),(0,1)]:
   nj,ni=j+dj,i+di
   if 0<=nj<walk.shape[0] and 0<=ni<walk.shape[1] and walk[nj,ni] and not seen[nj,ni]:seen[nj,ni]=True;q.append((nj,ni))
 bad=[]
 for goal in data['objectives']+[{'name':x['id'],'position':x['position']} for x in data['graph'] if x['id'].startswith('door')]:
  x,y,z=goal['position'];dist=np.sqrt((X-x)**2+(Z-z)**2)
  nearest=float(dist[seen].min())
  if nearest>7.5*scale:bad.append((goal['name'],round(nearest,2)))
 samples=0;badPaths=[]
 for doorIndex,door in enumerate(data['doors'],1):
  points=[next(g['position'] for g in data['graph'] if g['id']==f'door{doorIndex}p{n}') for n in range(1,5)]
  for a,b in zip(points,points[1:]):
   length=np.linalg.norm(np.array(b)[[0,2]]-np.array(a)[[0,2]])
   for t in np.linspace(0,1,max(2,int(np.ceil(length/(1.5*scale))))):
    x,z=(np.array(a)*(1-t)+np.array(b)*t)[[0,2]];distance=np.hypot(X-x,Z-z);nearest=float(distance[seen].min());samples+=1
    if nearest>1.65*scale:badPaths.append({'door':doorIndex,'nearest_reachable':round(nearest,2)});break
 assert not badPaths,f'{key} blocked corridor centerline with largest-agent clearance: {badPaths}'
 result={'map':key,'grid_cell_studs':step,'reachable_cells':int(seen.sum()),'objectives':len(data['objectives']),'unreachable_approaches':bad,'engine_navmesh':False,'polygon_floors':True,'oriented_wall_projection':True,'portal_approaches':len([x for x in data['graph'] if x['id'].startswith('door')]),'corridor_samples':samples,'corridor_failures':badPaths,'inflation_radius_studs':radius}
 print(json.dumps(result));results.append(result)
 assert not bad,f'{key} ground approaches unreachable in conservative collider audit: {bad}'
Path('Validation/Geometry-Report.json').write_text(json.dumps(results,indent=2))
