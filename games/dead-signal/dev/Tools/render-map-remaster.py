"""Optional EGL source-geometry review, never an engine/mobile capture.
Requires numpy, Pillow, trimesh, pyrender; set PYOPENGL_PLATFORM=egl.
An optional --art-directory points at the owner's existing modular glTF originals.
"""
import argparse,json,math,os,re
from pathlib import Path
os.environ.setdefault('PYOPENGL_PLATFORM','egl')
import numpy as np
np.infty=np.inf
from PIL import Image,ImageDraw,ImageFont
import trimesh,pyrender
P=argparse.ArgumentParser();P.add_argument('--art-directory',type=Path);args=P.parse_args()
ROOT=Path(__file__).resolve().parent.parent;DATA=ROOT/'Validation/MapRemaster';OUT=DATA/'Review';OUT.mkdir(exist_ok=True)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
geometry={};cache={}
if args.art_directory:
 for filename in ('04-Sidearms-SMG','05-Rifles','06-Shotguns','07-Heavy-Special','08-World-Props'):
  try:scene=trimesh.load(args.art_directory/(filename+'.gltf'),force='scene',process=False)
  except (ValueError,AssertionError):
   print('Optional art unavailable, using exported bounds:',filename,flush=True);continue
  for node in scene.graph.nodes_geometry:
   transform,name=scene.graph[node];geometry[node]=scene.geometry[name]
def matrix(c):
 m=np.eye(4);m[:3,3]=c[:3];m[:3,:3]=np.array(c[3:]).reshape(3,3);return m

def primitive(row):
 size=np.array(row['size']);shape=row.get('shape','Block')
 if row['class']=='WedgePart':
  h=size/2;v=np.array([[-h[0],-h[1],-h[2]],[h[0],-h[1],-h[2]],[-h[0],-h[1],h[2]],[h[0],-h[1],h[2]],[-h[0],h[1],h[2]],[h[0],h[1],h[2]]]);f=[[0,2,3],[0,3,1],[2,4,5],[2,5,3],[0,4,2],[1,3,5],[0,1,5],[0,5,4]]
  g=trimesh.Trimesh(v,f,process=False);g.fix_normals();return g
 if shape=='Ball':g=trimesh.creation.uv_sphere(count=[8,12]);g.apply_scale(size/2);return g
 if shape=='Cylinder':
  g=trimesh.creation.cylinder(radius=.5,height=1,sections=12);g.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[0,1,0]));g.apply_scale(size);return g
 return trimesh.creation.box(extents=size)
def sign_texture(row):
 im=Image.new('RGB',(1024,256),(18,26,29));d=ImageDraw.Draw(im);color=tuple(int(c*255) for c in row.get('textColor',[.9,.94,.9]))
 lines=row['text'].splitlines();size=70
 while size>12:
  font=ImageFont.truetype(BOLD,size)
  if all(d.textbbox((0,0),line,font=font)[2]<940 for line in lines) and len(lines)*size*1.25<210:break
  size-=1
 d.line((35,14,989,14),fill=color,width=3)
 for i,line in enumerate(lines):d.text((512,128+(i-(len(lines)-1)/2)*size*1.2),line,fill=color,font=font,anchor='mm')
 return np.array(im)
def add(scene,row):
 cf=matrix(row['cf']);name=row['name'];source=re.search(r'DSG_.*',name)
 key=(tuple(round(x,4) for x in row['size']),row['class'],row.get('shape'),tuple(row['color']),row['material'],row.get('variant'),row.get('text'))
 if source and source.group() in geometry:
  g=geometry[source.group()].copy();g.apply_scale(np.array(row['size'])/np.maximum(g.extents,1e-8));mesh=pyrender.Mesh.from_trimesh(g,smooth=True)
 else:
  if key not in cache:
   g=primitive(row);col=row['color'];material=pyrender.MetallicRoughnessMaterial(baseColorFactor=(*col,1),metallicFactor=.2 if row['material'] in ('Metal','CorrodedMetal') else 0,roughnessFactor=.8,doubleSided=True,emissiveFactor=[c*.5 for c in col] if row['material']=='Neon' else [0,0,0])
   cache[key]=pyrender.Mesh.from_trimesh(g,material=material,smooth=row.get('shape') in ('Ball','Cylinder'))
  mesh=cache[key]
 scene.add(mesh,pose=cf)
 if row.get('text') and row.get('face')=='Front':
  sx,sy,sz=row['size'];v=np.array([[-sx/2,-sy/2,-sz/2-.012],[sx/2,-sy/2,-sz/2-.012],[sx/2,sy/2,-sz/2-.012],[-sx/2,sy/2,-sz/2-.012]])
  g=trimesh.Trimesh(v,[[0,2,1],[0,3,2]],process=False);g.visual=trimesh.visual.TextureVisuals(uv=np.array([[1,0],[0,0],[0,1],[1,1]]))
  material=pyrender.MetallicRoughnessMaterial(baseColorTexture=pyrender.Texture(source=sign_texture(row),source_channels='RGB'),emissiveTexture=pyrender.Texture(source=sign_texture(row),source_channels='RGB'),emissiveFactor=(.8,.8,.8),metallicFactor=0,roughnessFactor=1,doubleSided=True)
  scene.add(pyrender.Mesh.from_trimesh(g,material=material),pose=cf)
def pose(eye,target):
 eye=np.array(eye,dtype=float);back=eye-target;back/=np.linalg.norm(back);right=np.cross([0,1,0],back);right/=np.linalg.norm(right);up=np.cross(back,right);m=np.eye(4);m[:3,:3]=np.column_stack((right,up,back));m[:3,3]=eye;return m
def render(data,size,eye,target,cutaway=False):
 scene=pyrender.Scene(bg_color=[.04,.055,.065,1],ambient_light=[.65,.68,.70]);cache.clear()
 for row in data['parts']:
  if row['transparency']>.92:continue
  if any(v is None or not math.isfinite(v) for v in row['cf']):continue
  if cutaway and (row['name'].startswith(('SectorRoof','CorridorRoof','ExteriorGround','SignFastener','FoundrySawtooth','PolarFaceted')) or row['cf'][1]>22*data['scale']):continue
  # Omit geometry far from the first-person camera without altering nearby transforms.
  if not cutaway and math.dist(row['cf'][:3],eye)>65 and max(row['size'])<100:continue
  add(scene,row)
 scene.add(pyrender.PerspectiveCamera(yfov=math.radians(65),zfar=1400),pose=pose(eye,np.array(target)))
 for at,power,col in [((-40,100,-60),2.4,(1,.94,.84)),((80,80,40),1.3,(.7,.83,1))]:scene.add(pyrender.DirectionalLight(color=col,intensity=power),pose=pose(at,np.array(target)))
 renderer=pyrender.OffscreenRenderer(*size);color,depth=renderer.render(scene);renderer.delete();return Image.fromarray(color)
def footer(im,text):
 d=ImageDraw.Draw(im);d.rectangle((0,im.height-28,im.width,im.height),fill=(11,20,26));d.text((12,im.height-21),text,font=ImageFont.truetype(FONT,11),fill=(194,210,215));return im
for key,title in [('Station','BLACKWATER STATION'),('Foundry','CINDERWORKS'),('Frost','WHITEOUT RELAY')]:
 before=json.loads((DATA/f'Before-{key}.json').read_text());after=json.loads((DATA/f'{key}-Geometry.json').read_text())
 def view(data):
  center=np.mean([[r['x']*data['scale'],0,r['z']*data['scale']] for r in data['layout']],axis=0)
  return render(data,(900,720),center+np.array([220,280,260]),center,True)
 collage=Image.new('RGB',(1800,780),(11,20,26));collage.paste(view(before),(0,40));collage.paste(view(after),(900,40));d=ImageDraw.Draw(collage)
 for x,label in [(18,title+' / BEFORE'),(918,'REMASTER / SOURCE GEOMETRY')]:d.text((x,12),label,font=ImageFont.truetype(BOLD,18),fill=(230,236,228))
 footer(collage,'OFFLINE CUTAWAY - exact source transforms / simplified materials and missing mesh bounds / not a Roblox capture').save(OUT/f'{key}-Before-After.png');print('Saved cutaway',key,flush=True)
 # Same eye height, distance and FOV, at a representative gate in each source revision.
 mobile=Image.new('RGB',(844,850),(11,20,26))
 for i,data in enumerate((before,after)):
  cf=matrix(data['doors'][0]['cf']) if 'cf' in data['doors'][0] else next(matrix(p['cf']) for p in data['parts'] if p['name']=='Gate1')
  direction=-cf[:3,2];target=cf[:3,3].copy();target[1]=5.4;eye=target+direction*12
  im=render(data,(844,390),eye,target);mobile.paste(im,(0,30+i*415));d=ImageDraw.Draw(mobile);d.text((12,7+i*415),'BEFORE' if i==0 else 'AFTER - 5.4 STUD EYE HEIGHT',font=ImageFont.truetype(BOLD,14),fill=(222,234,228))
 footer(mobile,'844 x 390 OFFLINE PROJECTION / same eye height, distance and FOV / native GUI, lighting and phone test pending').save(OUT/f'{key}-Mobile-Gate.png');print('Saved mobile projection',key,flush=True)
