-- Produced geometry regressions for DS-B1-002/003/004/005. Source evidence only.
-- `lune run Tests/map_batch11.luau before` records defects without asserting.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local process=require('@lune/process') local loader=require('./Support/RuntimeLoader')
local Geometry=require('./Support/SourceGeometry') local V=r.Vector3
local before=process.args[1]=='before' local phase=before and 'Before' or 'After'
local count=0 local out={engine=false,phase=phase,maps={},failures={}}
local function check(ok,msg) count+=1;if not ok then out.failures[#out.failures+1]=msg end end
local function vec(v) return {v.X,v.Y,v.Z} end
local function contains(poly,p)
 local positive,negative=false,false
 for i,a in ipairs(poly) do local b=poly[i%#poly+1]
  local cross=(b[1]-a[1])*(p.Z-a[2])-(b[2]-a[2])*(p.X-a[1])
  positive=positive or cross>.02;negative=negative or cross<-.02
 end return not (positive and negative)
end
local function supported(room,p)
 for _,poly in ipairs(room.upperFloorRegions or {}) do if contains(poly,p) then return true end end return false
end
local function footprint(part)
 local h=part.Size*.5 local points={}
 for _,localAt in ipairs({V.new(-h.X,-h.Y,-h.Z),V.new(h.X,-h.Y,-h.Z),V.new(-h.X,-h.Y,h.Z),V.new(h.X,-h.Y,h.Z),V.new(-h.X,h.Y,h.Z),V.new(h.X,h.Y,h.Z)}) do
  local at=part.CFrame:PointToWorldSpace(localAt) local unique=true
  for _,p in ipairs(points) do if V.new(p.X-at.X,0,p.Z-at.Z).Magnitude<.01 then unique=false end end
  if unique then points[#points+1]=at end
 end return points
end
fs.writeDir('Validation/MapBatch11')
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl')) local f=loader.install(dm)
 local load=loader.new(dm) local map=load(f.server.MapBuilder).build(id)
 local world=Geometry.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={map.model}}
 local report={id=id,scale=map.scale,parts=0,mounts=0,reflectedFrames=0,leakingDecks=0,ramps={},windows={},rooms={},dressing=map.dressingManifest or {},lights=0,shadowLights=0}
 local visual={id=id,scale=map.scale,rooms={},parts={},mounts={}}
 for _,bay in ipairs(map.mounts) do
  local cf=bay.cf local determinant=cf.RightVector:Cross(cf.UpVector):Dot(-cf.LookVector)
  check(determinant>.999,id..' '..bay.key..' right-handed wall mount');report.mounts+=1
  if determinant<0 then report.reflectedFrames+=1 end
  local inward=V.new(bay.approach.X-bay.wall.X,0,bay.approach.Z-bay.wall.Z).Unit
  check(cf.LookVector:Dot(inward)>.999,id..' '..bay.key..' front faces room approach')
  visual.mounts[#visual.mounts+1]={room=bay.room,key=bay.key,frame={cf:GetComponents()},wall=vec(bay.wall),approach=vec(bay.approach)}
 end
 for _,part in ipairs(map.model:GetDescendants()) do
  if part:IsA('BasePart') then
   report.parts+=1
   local determinant=part.CFrame.RightVector:Cross(part.CFrame.UpVector):Dot(-part.CFrame.LookVector)
   check(determinant>.999,id..' '..part.Name..' produced proper rotation')
   local room=part.Parent
   while room and room~=map.model and not room:GetAttribute('SectorId') do room=room.Parent end
   local row={name=part.Name,class=part.ClassName,cf={part.CFrame:GetComponents()},size=vec(part.Size),color={part.Color.R,part.Color.G,part.Color.B},transparency=part.Transparency,collide=part.CanCollide,query=part.CanQuery,dressing=part:GetAttribute('RoomDressing'),room=room and room:GetAttribute('SectorId')}
   local gui=part:FindFirstChildOfClass('SurfaceGui')
   if gui then local label=gui:FindFirstChildOfClass('TextLabel');if label then row.text=label.Text;row.face=gui.Face.Name;row.textColor={label.TextColor3.R,label.TextColor3.G,label.TextColor3.B} end end
   visual.parts[#visual.parts+1]=row
   if part:GetAttribute('RoomDressing') then check(not part.CanCollide and not part.CanQuery and not part.CanTouch,id..' incidental dressing cannot create perches or query cost') end
  end
  if part:IsA('Light') then report.lights+=1;if part.Shadows then report.shadowLights+=1 end end
 end
 check(#report.dressing==12,id..' two functional dressing assemblies in every room')
 for index,room in ipairs(map.rooms) do
  local assemblies=0
  for _,item in ipairs(report.dressing) do if item.room==index then
   assemblies+=1
   check(item.purpose==map.layout[index].purpose and item.parts>=8 and item.parts<=25,id..' purpose-specific bounded dressing '..index)
   -- Independent output audit of the reservation, not planner return values.
   local b=item.bounds local s=map.scale
   for _,zones in ipairs({map.interactionZones,map.detailZones}) do for _,z in ipairs(zones) do
    check(not (b.minX*s<z.maxX and b.maxX*s>z.minX and b.minZ*s<z.maxZ and b.maxZ*s>z.minZ and b.minY*s<z.maxY and b.maxY*s>z.minY),id..' dressing keeps route/interaction reservation')
   end end
  end end
  check(assemblies==2,id..' room '..index..' is intentionally dressed')
 end
 for index,room in ipairs(map.rooms) do
  local row={room=index,purpose=map.layout[index].purpose,details=0,deckParts=0,leakingDecks=0}
  local shape={room=index,purpose=row.purpose,polygon={},regions=room.upperFloorRegions,stairs={}}
  for _,p in ipairs(room.polygon) do shape.polygon[#shape.polygon+1]=vec(p*map.scale) end
  for _,p in ipairs(room.model:GetDescendants()) do if p:IsA('BasePart') then
   if p:GetAttribute('DeadSignalFurnishing') or p:GetAttribute('FacilityDetail') or p:GetAttribute('RoomDressing') then row.details+=1 end
   if p.Name=='UpperGalleryDeck' then
    row.deckParts+=1 local tri=footprint(p) local leak=false
    check(#tri==3,id..' deck is an actual triangular prism')
    if #tri==3 then for a=0,8 do for b=0,8-a do
     local at=tri[1]*(a/8)+tri[2]*(b/8)+tri[3]*(1-(a+b)/8)
     if not supported(room,at) then leak=true end
    end end end
    if leak then row.leakingDecks+=1;report.leakingDecks+=1 end
    check(not leak,id..' room '..index..' actual deck wedge stays within clipped floor polygon')
   end
  end end
  for si,stair in ipairs(room.stairs or {}) do
   local direction=V.new(0,0,stair.top.Z>stair.base.Z and 1 or -1)
   local start=stair.base+direction*3*map.scale
   local edge=stair.width/2-2.05-.35 local bad={} local samples=0
   -- Largest current NPC radius plus shoulder margin, five full-width lanes.
   -- Ray starts at head height: a protruding upper slab must fail as well as a gap.
   for _,lateral in ipairs({-edge,-edge/2,0,edge/2,edge}) do for n=0,48 do
    local distance=-3*map.scale+(stair.run+6*map.scale)*n/48
    local at=start+direction*distance+V.new(lateral,math.clamp(distance/stair.run,0,1)*stair.rise,0)
    local hit=world:Raycast(at+V.new(0,8.75,0),V.new(0,-9,0),params);samples+=1
    if not hit or math.abs(hit.Position.Y-at.Y)>.08 then bad[#bad+1]={at=vec(at),part=hit and hit.Instance.Name or 'none',height=hit and hit.Position.Y or -999} end
   end end
   check(#bad==0,id..' room '..index..' ramp '..si..' actual support/head clearance across whole travel width')
   report.ramps[#report.ramps+1]={room=index,stair=si,samples=samples,badSamples=#bad,failures=bad}
   shape.stairs[#shape.stairs+1]={base=vec(stair.base),top=vec(stair.top),width=stair.width,run=stair.run,rise=stair.rise}
  end
  report.rooms[#report.rooms+1]=row;visual.rooms[#visual.rooms+1]=shape
 end
 for _,w in ipairs(map.windows) do
  local e=w.entry local at=e.approach.Position
  local hit=world:Raycast(at+V.new(0,.5,0),V.new(0,-1,0),params)
  check(hit and math.abs(hit.Position.Y-at.Y)<.02,id..' '..e.id..' exterior feet have actual floor support')
  check(e.approach.LookVector:Dot(e.inward)>.999 and e.landing.LookVector:Dot(e.inward)>.999,id..' '..e.id..' inward transforms')
  report.windows[#report.windows+1]={id=e.id,room=w.room,approach=vec(at),supported=hit~=nil}
  local apron=w.approachFloor
  check(apron and apron.CanCollide and table.find(map.floorParts,apron),id..' '..e.id..' real apron registered as support')
  if apron then
   -- Three disjoint waiting footprints: lead actor and two rear queue slots.
   -- Engine movement, live queue ownership and separation remain ENEMY's tests.
   for _,offset in ipairs({V.zero,V.new(-3.3,0,6),V.new(3.3,0,6)}) do
    local center=e.approach:PointToWorldSpace(V.new(offset.X,0,offset.Z)*map.scale)
    for angle=1,12 do
     local point=center+V.new(math.cos(angle*math.pi/6),0,math.sin(angle*math.pi/6))*2.4
     local localAt=apron.CFrame:PointToObjectSpace(point) local h=apron.Size*.5
     check(math.abs(localAt.X)<h.X and math.abs(localAt.Z)<h.Z and math.abs(localAt.Y-h.Y)<.02,id..' '..e.id..' supported 2.4-stud-radius queue footprint')
    end
   end
  end
 end
 check(report.parts<6500,id..' retained 6500 static-part ceiling')
 check(report.shadowLights<=3,id..' retained shadow-light ceiling')
 out.maps[#out.maps+1]=report
 fs.writeFile('Validation/MapBatch11/'..phase..'-'..id..'-Geometry.json',serde.encode('json',visual))
 print(id..': '..report.leakingDecks..' leaking deck wedges; '..#report.ramps..' ramps; '..report.parts..' parts')
 map.model:Destroy()
end
out.assertions=count
fs.writeFile('Validation/MapBatch11/'..phase..'-Report.json',serde.encode('json',out))
print(phase..' Batch 1.1 map checks: '..count..'; failures: '..#out.failures)
if not before then assert(#out.failures==0,table.concat(out.failures,'\n')) end
return count
