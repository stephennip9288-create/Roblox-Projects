"""Reproducible source diagrams/cutaways, not Roblox screenshots.

Run Tests/map_batch11.luau in before/default modes first. NumPy/Pillow required.
Retained meshes use their bounds. Native art, materials, physics and UI need Studio.
"""
from pathlib import Path
import ast
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent.parent
DATA=ROOT/'Validation/MapBatch11';OUT=ROOT/'Reviews/map-batch1-1'
BG=(18,27,33);FG=(233,239,235);MUTED=(164,184,191)
TEAL=(87,204,179);RED=(229,110,100);GOLD=(231,187,108);BLUE=(122,185,227)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

# Reuse the established primitive/sign projector without executing its historic
# #21/Batch1 top-level export driver. Only these pure function definitions load.
source=ast.parse((ROOT/'Tools/review-map-batch1.py').read_text())
names={'font','cf','polygon','clip_height','sign_texture','first_person'}
selected=[n for n in source.body if isinstance(n,(ast.Import,ast.ImportFrom)) or isinstance(n,ast.FunctionDef) and n.name in names]
exec(compile(ast.Module(body=selected,type_ignores=[]),'review-map-batch1-helpers','exec'),globals())

def write(d,xy,text,size=17,color=FG,bold=False):
    d.text(xy,text,font=ImageFont.truetype(BOLD if bold else FONT,size),fill=color)

def inside(poly,q):
    p=np.array(poly);e=np.roll(p,-1,axis=0)-p;v=q-p;c=e[:,0]*v[:,1]-e[:,1]*v[:,0]
    return not (np.any(c>.03) and np.any(c<-.03))

def footprint(row):
    p=np.unique(np.round(np.concatenate(polygon(row))[:,[0,2]],4),axis=0);c=p.mean(axis=0)
    return p[np.argsort(np.arctan2(p[:,1]-c[1],p[:,0]-c[0]))]

def stairs(before,after):
    im=Image.new('RGB',(1800,1100),BG);d=ImageDraw.Draw(im)
    write(d,(24,15),after['id']+' / ACTUAL STAIR COLLISION FOOTPRINTS',25,bold=True)
    write(d,(24,58),'STAGED SOURCE / BEFORE',19)
    write(d,(914,58),'BATCH 1.1 / AFTER',19)
    ramps=[(room,s) for room in after['rooms'] for s in room['stairs']]
    for index,(room,s) in enumerate(ramps):
        for phase,data in enumerate((before,after)):
            panel=Image.new('RGB',(870,215),BG);pd=ImageDraw.Draw(panel)
            a,b=np.array(s['base'])[[0,2]],np.array(s['top'])[[0,2]]
            lo=np.minimum(a,b)-[s['width']/2+7,7];hi=np.maximum(a,b)+[s['width']/2+7,7]
            scale=min(600/(hi[0]-lo[0]),190/(hi[1]-lo[1]))
            def xy(p):return tuple((np.array(p)-lo)*scale+[260,12])
            rr=next(r for r in data['rooms'] if r['room']==room['room'])
            for p in rr['regions'] or []:pd.polygon([xy(v) for v in p],fill=(44,64,71))
            for p in data['parts']:
                if p['name']!='UpperGalleryDeck' or p.get('room')!=room['room']:continue
                points=footprint(p)
                if np.any(points.max(axis=0)<lo) or np.any(points.min(axis=0)>hi):continue
                leak=any(not any(inside(poly,q) for poly in rr['regions']) for q in points)
                pd.polygon([xy(q) for q in points],outline=RED if leak else (72,118,112),width=2)
            half=s['width']/2
            pd.rectangle((*xy([a[0]-half,min(a[1],b[1])]),*xy([a[0]+half,max(a[1],b[1])])),outline=GOLD,width=2)
            for x in [-half+2.4,0,half-2.4]:pd.line([xy(a+[x,0]),xy(b+[x,0])],fill=TEAL,width=2)
            write(pd,(0,40),'ROOM '+str(room['room']),18,bold=True)
            write(pd,(0,70),'ASCEND / REVERSE',14,MUTED)
            write(pd,(0,96),'WIDTH / LANDING',14,MUTED)
            im.paste(panel,(24+phase*890,94+index*225))
    write(d,(24,1020),'Red: wedge leaves clipped deck region. Gold: travel envelope. Teal: off-center support/headroom probes.',17,GOLD)
    write(d,(24,1060),'OFFLINE SOURCE DIAGRAM / not a Studio collision, humanoid or navmesh test.',17,MUTED)
    im.save(OUT/(after['id']+'-Stair-Collision.png'))

def room_view(data,room):
    image=Image.new('RGB',(870,275),BG);d=ImageDraw.Draw(image);s=data['scale']
    center=np.mean(np.array(room['polygon']),axis=0);basis=np.array([[.707,0,-.707],[.32,-.85,.32]])
    outline=(np.array(room['polygon'])-center)@basis.T
    lo,hi=outline.min(axis=0)-[2,7*s],outline.max(axis=0)+[2,2]
    scale=min(850/(hi[0]-lo[0]),255/(hi[1]-lo[1]));faces=[]
    for p in data['parts']:
        if p['transparency']>.92 or p['name'] in ('SectorRoof','ExteriorGround','ContainmentUnderfloor'):continue
        at=np.array(p['cf'][:3])
        if p.get('room')!=room['room'] and (p.get('room') is not None or not inside(np.array(room['polygon'])[:,[0,2]],at[[0,2]])):continue
        wall=p['name'] in ('BunkerWall','PlasterFacing','WallBase','WallTrim')
        for points in polygon(p):
            points=clip_height(points,1.1*s if wall else 7*s)
            if len(points)<3:continue
            xy=(points-center)@basis.T
            faces.append((np.mean(points[:,0]+points[:,2]),xy,tuple(int(c*205+12) for c in p['color']),p.get('dressing')))
    for _,points,col,new in sorted(faces,key=lambda row:row[0]):
        d.polygon([tuple((p-lo)*scale+[10,10]) for p in points],fill=col,outline=TEAL if new else None,width=1)
    return image

def rooms(before,after):
    im=Image.new('RGB',(1800,2070),BG);d=ImageDraw.Draw(im)
    write(d,(24,15),after['id']+' / ROOM PURPOSE AND DRESSING',25,bold=True)
    write(d,(24,55),'STAGED SOURCE / BEFORE',18)
    write(d,(919,55),'PATCH / AFTER (new dressing outlined teal)',18)
    for index,room in enumerate(after['rooms']):
        y=95+315*index;write(d,(24,y),str(room['room'])+' / '+room['purpose'],20,bold=True)
        kit=next(p['dressing'] for p in after['parts'] if p.get('room')==room['room'] and p.get('dressing'))
        write(d,(919,y),kit+' equipment + wall services',17,TEAL)
        for phase,data in enumerate((before,after)):im.paste(room_view(data,room),(24+895*phase,y+28))
    write(d,(24,2010),'OFFLINE CUTAWAYS / roofs and upper floors omitted; walls lowered; mesh bounds only. Native art/lighting pending.',17,GOLD)
    im.save(OUT/(after['id']+'-Rooms-Before-After.png'))

def wall_views(before,after):
    im=Image.new('RGB',(1800,1160),BG);d=ImageDraw.Draw(im)
    write(d,(24,16),after['id']+' / WALL FRAMES AND FIRST-PERSON GATE SIGN',25,bold=True)
    key=next(b for b in after['mounts'] if b['key'].startswith('WallBuy_'))
    old=next(b for b in before['mounts'] if b['key']==key['key'] and b['room']==key['room'])
    for i,bay in enumerate((old,key)):
        matrix=np.array(bay['frame'][3:]).reshape(3,3);det=np.linalg.det(matrix);origin=np.array([400+i*890,190])
        write(d,(24+i*890,70),('BEFORE' if i==0 else 'AFTER')+f' / determinant {det:+.1f}',20,RED if det<0 else TEAL,True)
        for axis,label,col in [(matrix[:,0],'local X',GOLD),(matrix[:,2],'outward Z',TEAL)]:
            end=origin+axis[[0,2]]*75;d.line([tuple(origin),tuple(end)],fill=col,width=4);write(d,tuple(end),label,15,col)
        write(d,(24+i*890,285),'Reflected source basis; engine coercion is not simulated.' if i==0 else 'Proper rotation; fixtures and SurfaceGui front face inward.',16,MUTED)
    metrics=[]
    for i,size in enumerate(((1280,720),(844,390))):
        image,rows=first_person(after,size);metrics.append({'viewport':list(size),'signs':rows})
        write(d,(24+i*900,340),f'PATCH / {size[0]} x {size[1]} / 65-degree vertical FOV',18,bold=True)
        image.thumbnail((870,700));im.paste(image,(24+i*900,380))
    write(d,(24,1030),'5.4-stud eye, 12 studs from gate. Source text and transforms; DejaVu font approximation. Native GUI acceptance pending.',17,MUTED)
    write(d,(24,1080),'OFFLINE PROJECTION / no Roblox materials, physics, controls or device-performance measurements.',17,GOLD)
    im.save(OUT/(after['id']+'-Wall-Viewports.png'))
    return {'map':after['id'],'projections':metrics,'eyeHeight':5.4,'distance':12,'nativeGui':False,'phoneTested':False}

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True);metrics=[]
    for key in ('Station','Foundry','Frost'):
        before=json.loads((DATA/f'Before-{key}-Geometry.json').read_text());after=json.loads((DATA/f'After-{key}-Geometry.json').read_text())
        stairs(before,after);rooms(before,after);metrics.append(wall_views(before,after));print(key,'review sheets saved',flush=True)
    (OUT/'Projection-Measurements.json').write_text(json.dumps(metrics,indent=2)+'\n')
