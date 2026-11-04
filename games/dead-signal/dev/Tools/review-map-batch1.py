"""Offline plans, cutaways and first-person sign projections; never a Roblox capture.

Requires NumPy and Pillow. Uses exact source transforms with flat colors and
primitive bounds for retained meshes. Native materials, GUI, lighting, physics,
particle appearance, streaming and device performance must be reviewed in Studio.
"""
from pathlib import Path
import itertools
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent.parent
DATA=ROOT/'Validation/MapRemaster'; BATCH=ROOT/'Validation/MapBatch1'
OUT=ROOT/'Reviews/map-batch1'; OUT.mkdir(parents=True,exist_ok=True)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
BG=(16,24,29); FG=(227,234,228); MUTED=(163,184,190)
TEAL=(102,198,175); GOLD=(230,184,99); RED=(233,129,104); BLUE=(122,185,227)

def font(size,bold=False):return ImageFont.truetype(BOLD if bold else FONT,size)
def title(draw,xy,text,size=22,color=FG):draw.text(xy,text,font=font(size,True),fill=color)
def cf(row):return np.array(row['cf'][:3]),np.array(row['cf'][3:]).reshape(3,3)
def polygon(row):
    center,rot=cf(row);h=np.array(row['size'])/2
    if row['class']=='WedgePart':
        v=[(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)]
        faces=[[0,2,3,1],[2,4,5,3],[0,4,2],[1,3,5],[0,1,5,4]]
    else:
        v=list(itertools.product((-1,1),repeat=3));faces=[[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]
    vertices=np.array([center+rot@(np.array(q)*h) for q in v])
    return [vertices[f] for f in faces]

def plans(before,after,contract):
    im=Image.new('RGB',(1800,1060),BG);d=ImageDraw.Draw(im)
    title(d,(24,18),after['id'].upper()+' / PLAYABLE FACILITY AND ACCESS RISKS')
    pts=np.array([p for data in (before,after) for poly in data['floorRegions'] for p in poly])
    lo=pts.min(axis=0)-16; hi=pts.max(axis=0)+16
    factor=min(810/(hi[0]-lo[0]),650/(hi[1]-lo[1]))
    for index,data in enumerate((before,after)):
        xoff=35+index*890; offset=np.array([xoff,100])
        def xy(p):return tuple(offset+(np.array(p)-lo)*factor)
        title(d,(xoff,62),'PARENT #21' if index==0 else 'BATCH 1 / NEW SOURCE',18)
        for poly in data['floorRegions'][6:]:d.polygon([xy(v) for v in poly],fill=(67,83,89))
        for i,poly in enumerate(data['floorRegions'][:6],1):
            d.polygon([xy(v) for v in poly],fill=(44,68,69) if i==2 else (49,60,67),outline=(140,162,164),width=2)
        if index==1:
            for g in contract['galleries']:
                for poly in g['regions']:d.polygon([xy(v) for v in poly],fill=(105,91,56))
                for s in g['stairs']:
                    a=xy([s['base'][0],s['base'][2]]);b=xy([s['top'][0],s['top'][2]])
                    d.line([a,b],fill=TEAL,width=7);d.ellipse((b[0]-5,b[1]-5,b[0]+5,b[1]+5),fill=TEAL)
            for entry in contract['entries']:
                p=xy([entry['breach'][0],entry['breach'][2]]);d.rectangle((p[0]-4,p[1]-4,p[0]+4,p[1]+4),fill=RED)
            for bay in after['mounts']:
                p=xy([bay['approach'][0],bay['approach'][2]]);d.ellipse((p[0]-2,p[1]-2,p[0]+2,p[1]+2),fill=BLUE)
        for i,door in enumerate(data['doors'],1):
            points=[xy([v[0],v[2]]) for v in door['waypoints']]
            d.line(points,fill=(133,153,161),width=2)
            p=np.mean(np.array(points[1:3]),axis=0)
            d.rounded_rectangle((p[0]-14,p[1]-11,p[0]+14,p[1]+11),radius=4,fill=(103,50,41))
            d.text(tuple(p),str(i),font=font(13,True),fill=FG,anchor='mm')
        for i,r in enumerate(data['layout'],1):
            p=xy([r['x']*data['scale'],r['z']*data['scale']])
            d.ellipse((p[0]-15,p[1]-15,p[0]+15,p[1]+15),fill=BG,outline=TEAL,width=2)
            d.text(p,str(i),font=font(16,True),fill=FG,anchor='mm')
        p=xy([lo[0]+8,hi[1]-7]);length=50*factor
        d.line((p[0],p[1],p[0]+length,p[1]),fill=MUTED,width=3);d.text((p[0],p[1]+6),'50 world studs',font=font(13),fill=MUTED)
    d.line((25,790,1775,790),fill=(68,84,91),width=1)
    for i,r in enumerate(after['layout']):
        title(d,(35+(i%3)*590,811+(i//3)*66),str(i+1)+'  '+r['purpose'],17)
        d.text((35+(i%3)*590,838+(i//3)*66),r['shape']+' / '+('open sky' if r.get('outdoor') else 'enclosed'),font=font(14),fill=MUTED)
    d.text((35,959),'Gold: supported service walk   Green: no-jump ramps   Red: entry / numbered purchase gate   Blue: reserved interaction approach',font=font(15),fill=FG)
    d.text((35,991),'Risk review: outside polygons is inaccessible scenery; every gallery has two exits; every closed gate retains progression collision.',font=font(15),fill=MUTED)
    d.text((35,1023),'EXACT SOURCE PLAN / NOT NAVMESH OR GAMEPLAY ACCEPTANCE / Native crowding, revive, exploit and phone checks remain pending.',font=font(14,True),fill=GOLD)
    im.save(OUT/(after['id']+'-Access-Plan.png'))

def cutaway(data,contract):
    right=np.array([1,0,-1])/math.sqrt(2);back=np.array([1,1.5,1]);back/=np.linalg.norm(back);up=np.cross(back,right)
    faces=[];allpoints=[]
    for row in data['parts']:
        if row['transparency']>.92 or row['name'].startswith(('SectorRoof','CorridorRoof','ExteriorGround','PolarFaceted','FoundrySawtooth')):continue
        for vertices in polygon(row):
            if not row.get('scenery'):
                vertices=clip_height(vertices,16*data['scale'])
                if len(vertices)<3:continue
            points=np.column_stack((vertices@right,-vertices@up));allpoints.extend(points)
            normal=np.cross(vertices[1]-vertices[0],vertices[2]-vertices[0]);length=np.linalg.norm(normal)
            shade=.62+.32*abs(np.dot(normal/max(length,1e-8),np.array([-.4,.8,-.4])))
            color=tuple(int(np.clip(c*shade*255,0,255)) for c in row['color'])
            faces.append((np.mean(vertices@back),points,color))
    points=np.array(allpoints);lo=points.min(axis=0);hi=points.max(axis=0);scale=min(1450/(hi[0]-lo[0]),820/(hi[1]-lo[1]))
    origin=np.array([768,505])-(lo+hi)*scale/2
    im=Image.new('RGB',(1536,1080),BG);d=ImageDraw.Draw(im)
    title(d,(25,20),data['id'].upper()+' / LAYERED WORLD CUTAWAY')
    d.text((25,58),'Near assemblies / middle skyline / far silhouettes. Roofs removed; interiors cut at 16 authoring studs.',font=font(15),fill=MUTED)
    for _,points,color in sorted(faces,key=lambda f:f[0]):d.polygon([tuple(origin+p*scale) for p in points],fill=color)
    line=940
    for i,point in enumerate(contract['landmarks']):
        if i>=8:break
        text=point['kind']+' / '+point['tier'];d.text((25+(i%4)*380,line+(i//4)*30),text,font=font(14),fill=TEAL)
    d.text((25,1014),'OFFLINE PRIMITIVE GEOMETRY / flat color; retained mesh bounds / no native materials, fog, shadows or particle rendering',font=font(14,True),fill=GOLD)
    d.text((25,1044),'Scenery is excluded from collision, combat queries, navigation and support floors. This is a review view, not a Roblox screenshot.',font=font(14),fill=MUTED)
    im.save(OUT/(data['id']+'-World-Cutaway.png'))

def clip_height(vertices,y):
    out=[];previous=vertices[-1]
    for current in vertices:
        if (previous[1]<=y)!=(current[1]<=y):out.append(previous+(current-previous)*((y-previous[1])/(current[1]-previous[1])))
        if current[1]<=y:out.append(current)
        previous=current
    return np.array(out)

def sign_texture(row):
    im=Image.new('RGBA',(1024,256),(24,28,30,255));d=ImageDraw.Draw(im)
    lines=row['text'].splitlines();size=70
    while size>12:
        f=font(size,True)
        if max(d.textlength(line,font=f) for line in lines)<940 and len(lines)*size*1.22<210:break
        size-=1
    color=tuple(int(c*255) for c in row.get('textColor',[.94,.95,.88]))
    for i,line in enumerate(lines):d.text((512,128+(i-(len(lines)-1)/2)*size*1.2),line,font=f,fill=color,anchor='mm')
    d.line((40,15,984,15),fill=color,width=2)
    return im,size

def first_person(data,size):
    gate=next(p for p in data['parts'] if p['name']=='Gate1');at,rot=cf(gate)
    target=at.copy();target[1]=5.4;eye=target-rot[:,2]*12
    back=(eye-target)/np.linalg.norm(eye-target);right=np.cross([0,1,0],back);right/=np.linalg.norm(right);up=np.cross(back,right)
    basis=np.column_stack((right,up,-back));focal=size[1]/(2*math.tan(math.radians(65/2)))
    def project(world):
        view=(world-eye)@basis
        if np.any(view[:,2]<.12):return None
        return np.column_stack((size[0]/2+focal*view[:,0]/view[:,2],size[1]/2-focal*view[:,1]/view[:,2]))
    faces=[];metrics=[]
    for row in data['parts']:
        at,rot=cf(row)
        if row['transparency']>.92 or np.linalg.norm(at-eye)>75 and max(row['size'])<100:continue
        for vertices in polygon(row):
            points=project(vertices)
            if points is None:continue
            if points[:,0].max()<0 or points[:,0].min()>size[0] or points[:,1].max()<0 or points[:,1].min()>size[1]:continue
            faces.append((np.linalg.norm(vertices.mean(axis=0)-eye),points,row,None))
        if row.get('text') and row.get('face')=='Front' and np.dot(-rot[:,2],eye-at)>0:
            sx,sy,sz=np.array(row['size'])/2
            vertices=np.array([at+rot@v for v in [(sx,sy,-sz-.015),(-sx,sy,-sz-.015),(-sx,-sy,-sz-.015),(sx,-sy,-sz-.015)]])
            points=project(vertices)
            if points is not None:faces.append((np.linalg.norm(vertices.mean(axis=0)-eye),points,row,True))
    im=Image.new('RGBA',size,(46,52,51,255));d=ImageDraw.Draw(im)
    for _,points,row,is_sign in sorted(faces,key=lambda x:x[0],reverse=True):
        if not is_sign:
            color=tuple(int(c*205) for c in row['color']);d.polygon([tuple(p) for p in points],fill=color);continue
        texture,text_size=sign_texture(row)
        # Pillow maps destination pixels into the original sign rectangle.
        src=[(0,0),(1024,0),(1024,256),(0,256)];a=[];b=[]
        for (x,y),(u,v) in zip(points,src):
            a.extend([[x,y,1,0,0,0,-u*x,-u*y],[0,0,0,x,y,1,-v*x,-v*y]]);b.extend([u,v])
        try:coeff=np.linalg.solve(np.array(a),np.array(b))
        except np.linalg.LinAlgError:continue
        layer=texture.transform(size,Image.Transform.PERSPECTIVE,coeff,Image.Resampling.BICUBIC)
        im=Image.alpha_composite(im,layer);d=ImageDraw.Draw(im)
        if 'POINTS' in row['text']:metrics.append({'text':row['text'],'projectedTextPixels':round(text_size*np.linalg.norm(points[1]-points[0])/1024,1),'panelWidthPixels':round(np.linalg.norm(points[1]-points[0]),1)})
    return im.convert('RGB'),metrics

contracts=json.loads((BATCH/'Contracts-Report.json').read_text())
measurements=[]
for contract in contracts['maps']:
    key=contract['id'];before=json.loads((BATCH/f'Before-{key}.json').read_text());after=json.loads((DATA/f'{key}-Geometry.json').read_text())
    plans(before,after,contract);cutaway(after,contract)
    desktop,dm=first_person(after,(1280,720));mobile,mm=first_person(after,(844,390))
    im=Image.new('RGB',(1280,1220),BG);im.paste(desktop,(0,40));im.paste(mobile,(0,800));d=ImageDraw.Draw(im)
    title(d,(18,8),key.upper()+' / 1280 x 720 DESKTOP PROPORTION',20)
    title(d,(18,770),'844 x 390 MOBILE LANDSCAPE PROPORTION',18)
    for i,text in enumerate(['65 degree vertical FOV','5.4 stud eye height','12 studs from gate','Source text + transforms','DejaVu font approximation','Native GUI / HUD pending']):d.text((868,825+i*39),text,font=font(17),fill=MUTED)
    d.text((18,1198),'OFFLINE PROJECTION / flat primitive bounds; native font fitting, sight lines, lighting and phone acceptance remain pending.',font=font(13,True),fill=GOLD)
    im.save(OUT/(key+'-Sign-Projections.png'))
    measurements.append({'map':key,'desktop':dm,'mobileLandscape':mm,'eyeHeight':5.4,'distance':12,'verticalFov':65,'nativeGui':False})
    print('Saved source review images:',key,flush=True)
(BATCH/'Projection-Measurements.json').write_text(json.dumps(measurements,indent=2))
