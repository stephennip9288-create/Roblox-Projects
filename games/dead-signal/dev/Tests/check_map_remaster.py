"""Projected clearance of actual runtime colliders; never a Roblox navmesh/physics test.
Run Tests/map_remaster.luau first; writes Clearance-Report.json.
"""
from pathlib import Path
import itertools, json, math
import numpy as np
from scipy.spatial import ConvexHull
from scipy.ndimage import label

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'Validation/MapRemaster'

def audit(data,radius,opened=None):
    scale=data['scale']; step=.75
    layout=data['layout']; minx=min(r['x']-r['w']/2 for r in layout)*scale-10; maxx=max(r['x']+r['w']/2 for r in layout)*scale+10
    minz=min(r['z']-r['d']/2 for r in layout)*scale-10; maxz=max(r['z']+r['d']/2 for r in layout)*scale+10
    xs=np.arange(minx,maxx+step,step); zs=np.arange(minz,maxz+step,step); X,Z=np.meshgrid(xs,zs)
    def inpoly(poly):
        inside=np.zeros(X.shape,dtype=bool)
        for a,b in zip(poly,poly[1:]+poly[:1]):
            if abs(b[1]-a[1])>1e-8:inside^=((a[1]>Z)!=(b[1]>Z))&(X<(b[0]-a[0])*(Z-a[1])/(b[1]-a[1])+a[0])
        return inside
    floor=np.zeros(X.shape,dtype=bool); blocked=np.zeros_like(floor)
    for poly in data['floorRegions']:floor|=inpoly(poly)
    shapes=[]
    for p in data['colliders']:
        if p['group']=='DeadSignalBounds' or p['name']=='StairRamp':continue
        if p['name'].startswith('Gate') and (opened is None or int(p['name'][4:]) in opened):continue
        cf=np.array(p['cf']); rot=cf[3:].reshape(3,3); half=np.array(p['size'])/2
        extent=np.abs(rot)@half
        if cf[1]+extent[1]<=.18 or cf[1]-extent[1]>=6.5*scale:continue
        points=np.array([(cf[:3]+rot@(np.array(signs)*half))[[0,2]] for signs in itertools.product([-1,1],repeat=3)])
        hull=points[ConvexHull(points).vertices]; shapes.append((p,hull))
        # Restrict math to the collider's local grid rectangle.
        ix0=max(0,int((hull[:,0].min()-radius-minx)/step)-1);ix1=min(len(xs),int((hull[:,0].max()+radius-minx)/step)+2)
        iz0=max(0,int((hull[:,1].min()-radius-minz)/step)-1);iz1=min(len(zs),int((hull[:,1].max()+radius-minz)/step)+2)
        x=X[iz0:iz1,ix0:ix1];z=Z[iz0:iz1,ix0:ix1];mask=np.ones(x.shape,dtype=bool)
        for a,b in zip(hull,np.roll(hull,-1,axis=0)):
            dx,dz=b-a;mask&=dx*(z-a[1])-dz*(x-a[0])>=-radius*np.hypot(dx,dz)
        blocked[iz0:iz1,ix0:ix1]|=mask
    walk=floor&~blocked; regions,nregions=label(walk)
    def sample(x,z):
        return min(len(zs)-1,max(0,round((z-minz)/step))), min(len(xs)-1,max(0,round((x-minx)/step)))
    spawn=next(o['position'] for o in data['objectives'] if o['name']=='Spawn 1'); root=regions[sample(spawn[0],spawn[2])]
    assert root,f"{data['id']} blocked spawn at radius {radius}"
    seen=regions==root
    reachable=np.column_stack((X[seen],Z[seen]))
    def distance(x,z):return float(np.hypot(reachable[:,0]-x,reachable[:,1]-z).min())
    failures=[]
    # Gallery landings are audited by their own ramp contract, not projected onto ground obstacles.
    for goal in data['objectives']:
        if goal['name'].startswith('Gallery'):continue
        x,_,z=goal['position']; nearest=distance(x,z)
        if nearest>1.15:failures.append({'type':'approach','target':goal['name'],'nearest':round(nearest,2),'position':goal['position']})
    samples=0
    for i,door in enumerate(data['doors'],1):
        for a,b in zip(door['waypoints'],door['waypoints'][1:]):
            length=math.dist(a,b)
            for t in np.linspace(0,1,max(2,math.ceil(length/1.0))):
                x,y,z=np.array(a)*(1-t)+np.array(b)*t; samples+=1
                nearest=distance(x,z)
                if nearest>1.15:failures.append({'type':'corridor','door':i,'nearest':round(nearest,2),'position':[x,y,z]});break
    # A downed teammate has space for another operator beside each reserved standing approach.
    for bay in data['mounts']:
        cf=np.array(bay['cf']);rot=cf[3:].reshape(3,3);right=rot[:,0];at=np.array(bay['approach'])
        for side in (-1,1):
            q=at+right*side*1.6
            if distance(q[0],q[2])>1.15:failures.append({'type':'revive','target':bay['key'],'position':q.tolist()})
    reachable_sectors=[i for i,r in enumerate(data['layout'],1) if seen[sample(r['x']*scale,r['z']*scale)]]
    report={'map':data['id'],'reachableSectors':reachable_sectors,'radius':radius,'grid':step,'reachableCells':int(seen.sum()),'corridorSamples':samples,'failures':failures,'robloxNavmesh':False}
    return report,(minx,minz,step,floor,blocked,seen,shapes)

if __name__=='__main__':
    results=[]
    for key in ('Station','Foundry','Frost'):
        data=json.loads((OUT/f'{key}-Geometry.json').read_text())
        result,_=audit(data,1.85*data['scale']);results.append(result)
        progression=[]
        for opened in [set(range(1,n+1)) for n in range(8)]+[{2},{8}]:
            # Compare physical reachability to the exact purchased door graph.
            expected={1}
            for _ in range(6):
                for i in opened:
                    door=data['doors'][i-1]
                    if door['a'] in expected or door['b'] in expected:expected.update([door['a'],door['b']])
            stage,_=audit(data,1.85*data['scale'],opened)
            assert set(stage['reachableSectors'])==expected,(key,opened,stage['reachableSectors'],expected)
            progression.append({'opened':sorted(opened),'reachable':stage['reachableSectors']})
        result['purchaseStages']=progression
        print(json.dumps(result))
    (OUT/'Clearance-Report.json').write_text(json.dumps({'checks':results,'engine':False},indent=2))
    assert all(not x['failures'] for x in results),'Projected map clearance failed'
