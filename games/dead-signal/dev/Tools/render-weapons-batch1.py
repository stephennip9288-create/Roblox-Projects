"""Orthographic/bounds diagnostics from actual model exports, never Studio screenshots."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parent.parent
data=json.loads((root/'Validation/WeaponsBatch1/Geometry.json').read_text())
dest=root/'Reviews/weapons-batch1';dest.mkdir(parents=True,exist_ok=True)
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def font(size):return ImageFont.truetype(font_path,size)
def hull(points):
 points=sorted(set(points))
 if len(points)<3:return points
 def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
 lo=[];hi=[]
 for p in points:
  while len(lo)>1 and cross(lo[-2],lo[-1],p)<=0:lo.pop()
  lo.append(p)
 for p in reversed(points):
  while len(hi)>1 and cross(hi[-2],hi[-1],p)<=0:hi.pop()
  hi.append(p)
 return lo[:-1]+hi[:-1]
def color(p):return tuple(min(220,max(35,int(v*255*1.3))) for v in p['color'])
def draw_parts(canvas,parts,project):
 draw=ImageDraw.Draw(canvas)
 for p in sorted(parts,key=lambda p:sum(v[0] for v in p['corners'])):
  points=[project(v) for v in p['corners'] if v[2]<-.01 or not getattr(project,'perspective',False)]
  poly=hull(points)
  if len(poly)<3:continue
  if p['nativeMesh']:
   # Mesh bounds are deliberately unfilled: these exports do not contain triangles.
   xs=[v[0] for v in poly];ys=[v[1] for v in poly]
   draw.rectangle((min(xs),min(ys),max(xs),max(ys)),outline='#c9a46d',width=2)
  else:draw.polygon(poly,fill=color(p),outline='#394644')

ids=sorted({m['weapon'] for m in data['models']})
models={(m['weapon'],m['version'],m['tier']):m for m in data['models']}
columns=[('before',0,'Parent #20 / base'),('after',0,'Batch 1 / base'),('after',1,'Batch 1 / tier 1'),('after',2,'Batch 1 / tier 2'),('after',3,'Batch 1 / tier 3')]
for page in range(2):
 image=Image.new('RGB',(1420,1620),'#101a20');draw=ImageDraw.Draw(image)
 draw.text((32,22),f'DEAD SIGNAL  |  WEAPON CONSTRUCTION  {page+1}/2',font=font(27),fill='#dbe6e6')
 draw.text((32,64),'Actual source parts + native mesh bounds. Orthographic projection; NOT Roblox renders or art acceptance.',font=font(18),fill='#9cafa9')
 draw.text((32,94),'Same stud scale throughout. Gold outline = retained native mesh bounds; surface triangles/textures are unavailable offline.',font=font(16),fill='#c9a46d')
 for col,(_,_,label) in enumerate(columns):draw.text((160+col*250,142),label,font=font(18),fill='#7fd4c5')
 for row,id in enumerate(ids[page*10:page*10+10]):
  y=186+row*140
  draw.text((24,y+45),id,font=font(18),fill='#dce6e3')
  for col,(version,tier,_) in enumerate(columns):
   m=models[id,version,tier];x=154+col*250
   tile=Image.new('RGB',(242,126),'#17242b')
   draw_parts(tile,m['parts'],lambda v:(int(78-v[2]*42),int(48-v[1]*42)))
   td=ImageDraw.Draw(tile);td.text((7,105),f"{len(m['parts'])} visible parts",font=font(13),fill='#819791')
   image.paste(tile,(x,y))
 image.save(dest/f'Construction-{page+1}.png')

image=Image.new('RGB',(1420,1010),'#101a20');draw=ImageDraw.Draw(image)
draw.text((30,20),'DEAD SIGNAL  |  ADS AXIS / CONSERVATIVE BOUNDS',font=font(27),fill='#dce6e3')
draw.text((30,62),'Full ADS at tier 3. Source projection only; native rendered sight pictures and movement still require Studio.',font=font(18),fill='#9cafa9')
for index,m in enumerate(data['ads']):
 row=index//3;col=index%3;x=30+col*465;y=110+row*290
 vw,vh=m['viewport'];scale=min(420/vw,225/vh);width,height=round(vw*scale),round(vh*scale)
 tile=Image.new('RGB',(width,height),'#253c43')
 focal=height/(2*math.tan(math.radians(m['fov']/2)))
 def project(v):return (width/2+v[0]/-v[2]*focal,height/2-v[1]/-v[2]*focal)
 project.perspective=True
 draw_parts(tile,m['parts'],project);td=ImageDraw.Draw(tile)
 cx,cy=width//2,height//2
 if m['optic']=='scope':
  mask=Image.new('L',(width,height),255);md=ImageDraw.Draw(mask);radius=int(min(width,height)*.42)
  md.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),fill=0)
  tile.paste((3,6,9),(0,0,width,height),mask);td=ImageDraw.Draw(tile)
  td.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline='#b0c4c0',width=2)
 td.line((cx-12,cy,cx+12,cy),fill='#7bf3c0',width=1);td.line((cx,cy-12,cx,cy+12),fill='#7bf3c0',width=1)
 image.paste(tile,(x+(420-width)//2,y+35))
 draw.text((x,y),f"{m['weapon']} / {m['optic']} / {vw}x{vh} / {m['fov']} deg",font=font(16),fill='#dae5e2')
draw.text((30,980),'The geometric tests cover all 20 weapons, four tiers, nine viewports and five FOVs. These nine panels illustrate the method.',font=font(16),fill='#9cafa9')
image.save(dest/'ADS-Projection.png')

summary={k:v for k,v in data.items() if k not in ('models','ads')}
summary['models']=[{k:v for k,v in m.items() if k!='parts'}|{'visibleParts':len(m['parts']),'nativeMeshParts':sum(p['nativeMesh'] for p in m['parts'])} for m in data['models']]
(dest/'Geometry-Report.json').write_text(json.dumps(summary,indent=2)+'\n')
lines=['# Wall-display bounds for Maps','',
 'Conservative world-stud spans of tier-3 Factory wall models at identity Root, including native MeshPart bounds and all visible source geometry. No arms/casings. X = width, Y = up, -Z = muzzle. Model origin/pivot and muzzle remain authored by WeaponModels; Maps owns mounting and placement. Do not apply map.scale to the gun itself. Base and every upgrade bounds are in Geometry-Report.json.','',
 '| Weapon | Width X | Height Y | Length Z | Local Y range | Local Z range |',
 '| --- | ---: | ---: | ---: | --- | --- |']
for id in ids:
 m=models[id,'after',3];a,b=m['min'],m['max'];s=m['size']
 lines.append(f'| {id} | {s[0]:.3f} | {s[1]:.3f} | {s[2]:.3f} | {a[1]:.3f} to {b[1]:.3f} | {a[2]:.3f} to {b[2]:.3f} |')
lines+=['','Retain front approach, prompt/sign clearances and non-queryable decoration. Validate the rotated bounding envelope against the mounting wall in Studio. These source measurements do not establish actual mesh contact, readable signs, navigation clearance or native visual acceptance.','']
(dest/'MOUNT-BOUNDS.md').write_text('\n'.join(lines))
print('Wrote two gun-by-gun construction sheets, ADS projection, geometry report and Maps dimensions.')
