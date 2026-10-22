-- DS-B1-002: actual produced support, independent of Navigation's seam fallback.
-- Source geometry only: no Roblox physics/navmesh/device claim.
-- Negative capture: `before <exact pre-patch Architecture.lua>`; records failures.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local process=require('@lune/process');local loader=require('./Support/RuntimeLoader')
local Geometry=require('./Support/EnemyB11Geometry');local V=r.Vector3
local before=process.args[1]=='before';local phase=before and 'Before' or 'After'
local out={engine=false,logicalFloorFill=false,phase=phase,maps={},failures={},assertions=0}
local function check(ok,message)
 out.assertions+=1;if not ok then out.failures[#out.failures+1]=message end
end
local function vec(p) return {p.X,p.Y,p.Z} end
local function frame(cf) return {cf:GetComponents()} end
local root='Validation/MapWindowGeometry';fs.writeDir(root)
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'))
 local folders=loader.install(dm)
 if before then
  assert(process.args[2],'Provide exact pre-patch Architecture.lua for negative capture')
  folders.server.Architecture.Source=fs.readFile(process.args[2])
 end
 local map=loader.new(dm)(folders.server.MapBuilder).build(id)
 local world=Geometry.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local load=loader.new(dm,{globals={workspace=world,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}})
 local N=load(folders.server.Navigation);local Layouts=load(folders.shared.MapLayouts)
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={map.model}}
 local report={id=id,scale=map.scale,windows={},parts=0,landingFloors=0,supportSamples=0,badSupportSamples=0}
 local snapshot={parts={},entries={},doors={},mounts={},nodes={},stairs={},areas={},dressing=map.dressingManifest}
 local function support(p,label,row)
  -- Actual parts only, cast far enough to expose a fall to ExteriorGround.
  local hit=world:Raycast(p+V.yAxis*.5,-V.yAxis*2,params)
  local ok=hit~=nil and math.abs(hit.Position.Y-p.Y)<.02
  report.supportSamples+=1
  if not ok then
   report.badSupportSamples+=1
   row.failures[#row.failures+1]={at=vec(p),floor=hit and vec(hit.Position),part=hit and hit.Instance.Name or 'none',probe=label}
  end
  check(ok,id..' '..row.id..' '..label..' actual foot-floor support')
  return hit
 end
 check(#map.windows==10,id..' retain ten designated windows')
 for wi,w in ipairs(map.windows) do
  local e=w.entry;local row={id=e.id,room=w.room,approach=vec(e.approach.Position),landing=vec(e.landing.Position),failures={}}
  check(e.schema==1 and e.id==id..'_entry_'..wi and e.room==w.room,id..' stable schema/id/room')
  check(e.approach.LookVector:Dot(e.inward)>.9999 and e.breach.LookVector:Dot(e.inward)>.9999
   and e.landing.LookVector:Dot(e.inward)>.9999,id..' '..e.id..' inward-facing canonical frames')
  local contact=w.part.CFrame:PointToObjectSpace(e.breach.Position)
  check(math.abs(contact.X)<.001 and math.abs(contact.Z)<.001 and math.abs(contact.Y+w.part.Size.Y/2)<.001,id..' '..e.id..' breach on physical sill top')
  check(math.abs(e.width-w.part.Size.X)<.001 and e.clearance.radius*2<=e.width
   and e.clearance.height<=w.part.Size.Y+.001,id..' '..e.id..' clearance fits produced opening')
  local approachHit=support(e.approach.Position,'approach',row)
  row.approachFloor=approachHit and vec(approachHit.Position)
  local hit=support(e.landing.Position,'canonical landing',row)
  row.landingFloor=hit and vec(hit.Position)
  -- Seventeen lanes through the complete interior landing run. A single
  -- center ray plus Navigation's +/- .05 fallback hid Foundry10's seam.
  local sill=e.breach.Position-V.yAxis*e.sillHeight
  for lane=-8,8 do for depth=1,12 do
   local p=sill+e.inward*depth*map.scale+e.landing.RightVector*lane*.5*map.scale
   support(p,'interior lane '..lane..' depth '..depth,row)
  end end
  -- World-axis perturbations reproduce the exact reported float seam and
  -- prevent a fix that merely nudges the anchor onto one of its neighbors.
  for _,dx in ipairs({-.1,-.05,-.01,-.001,0,.001,.01,.05,.1}) do
   for _,dz in ipairs({-.1,0,.1}) do support(e.landing.Position+V.new(dx,0,dz),'landing precision neighborhood',row) end
  end
  local descriptor=N.entryDescriptor(map,w)
  check(descriptor and (descriptor.landing-e.landing.Position).Magnitude<.001,id..' '..e.id..' canonical landing needs no consumer adjustment')
  row.resolvedLanding=descriptor and vec(descriptor.landing)
  snapshot.entries[#snapshot.entries+1]={entry=e,inside=vec(w.inside),outside=vec(w.outside),frame=frame(w.part.CFrame),size=vec(w.part.Size)}
  -- Convert CFrames/Vector3s to plain records for reproducible comparison.
  snapshot.entries[#snapshot.entries].entry={schema=e.schema,id=e.id,room=e.room,kind=e.kind,allowedKinds=e.allowedKinds,
   approach=frame(e.approach),breach=frame(e.breach),landing=frame(e.landing),inward=vec(e.inward),clearance=e.clearance,width=e.width,height=e.height,sillHeight=e.sillHeight}
  report.windows[#report.windows+1]=row
 end
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then
  report.parts+=1
  if p.Name=='EntryLandingFloor' then
   report.landingFloors+=1
   check(id=='Foundry' and p:GetAttribute('EntryId')=='Foundry_entry_10',id..' only the reproduced entry changes')
   check(p.CanCollide and p.CanQuery and not p.CanTouch and p.Anchored and table.find(map.floorParts,p),id..' real queryable registered support')
   check(math.abs(p.CFrame.Y+p.Size.Y/2)<.001,id..' repair is flush, no new step/perch')
   local e=map.windows[10].entry;local localAt=p.CFrame:PointToObjectSpace(e.landing.Position)
   check(math.abs(localAt.X)+2.4<p.Size.X/2 and math.abs(localAt.Z)+2.4<p.Size.Z/2,id..' whole landing footprint inside continuous slab')
   for _,x in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
    local corner=p.CFrame:PointToWorldSpace(V.new(p.Size.X*x,p.Size.Y/2,p.Size.Z*z))
    if (corner-(e.breach.Position-V.yAxis*e.sillHeight)):Dot(e.inward)>0 then
     check(Layouts.contains(map.layout[e.room],corner.X/map.scale,corner.Z/map.scale,0),id..' patch stays inside existing room')
    end
   end end
   local apron=map.windows[10].approachFloor
   local outer=apron.CFrame:PointToObjectSpace(p.CFrame.Position)+V.new(0,0,p.Size.Z/2)
   check(outer.Z>-apron.Size.Z/2 and outer.Z<-apron.Size.Z/2+.1*map.scale
    and math.abs((p.CFrame.Y+p.Size.Y/2)-(apron.CFrame.Y+apron.Size.Y/2))<.001,id..' apron seam overlaps at matching height')
  else
   snapshot.parts[#snapshot.parts+1]={path=p:GetFullName(),class=p.ClassName,frame=frame(p.CFrame),size=vec(p.Size),
    color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,variant=p.MaterialVariant,transparency=p.Transparency,
    collide=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,group=p.CollisionGroup}
  end
 end end
 check(report.landingFloors==((id=='Foundry' and not before) and 1 or 0),id..' minimal repair inventory')
 check(report.parts<6500,id..' retained static part budget')
 for _,d in ipairs(map.doors) do
  local points={};for _,p in ipairs(d.waypoints) do points[#points+1]=vec(p) end
  snapshot.doors[#snapshot.doors+1]={a=d.a,b=d.b,cost=d.cost,position=vec(d.position),frame=frame(d.part.CFrame),points=points}
 end
 for _,m in ipairs(map.mounts) do snapshot.mounts[#snapshot.mounts+1]={key=m.key,room=m.room,frame=frame(m.cf),wall=vec(m.wall),approach=vec(m.approach)} end
 for key,n in pairs(map.navigation.nodes) do snapshot.nodes[key]={room=n.room,level=n.level,position=vec(n.position)} end
 for _,a in ipairs(map.areas) do snapshot.areas[#snapshot.areas+1]={room=a.room,door=a.door and a.door.part.Name,
  minX=a.minX,maxX=a.maxX,minZ=a.minZ,maxZ=a.maxZ,minY=a.minY,maxY=a.maxY,polygon=a.polygon} end
 for ri,room in ipairs(map.rooms) do for si,stair in ipairs(room.stairs or {}) do
  snapshot.stairs[#snapshot.stairs+1]={room=ri,index=si,base=vec(stair.base),top=vec(stair.top),width=stair.width,run=stair.run,rise=stair.rise}
 end end
 fs.writeFile(root..'/'..phase..'-'..id..'-Snapshot.json',serde.encode('json',snapshot))
 out.maps[#out.maps+1]=report
 print(id..': '..report.supportSamples..' actual support probes; '..report.badSupportSamples..' misses; '..report.landingFloors..' added landing slabs')
 map.model:Destroy()
end
fs.writeFile(root..'/'..phase..'-Report.json',serde.encode('json',out))
print('Map window geometry assertions:',out.assertions,'failures:',#out.failures)
if not before then assert(#out.failures==0,'DS-B1-002 produced geometry failed; see '..root..'/'..phase..'-Report.json') end
return out.assertions
