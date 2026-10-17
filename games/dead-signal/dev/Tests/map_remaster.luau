-- Actual source construction and stable map contracts. Geometry projection is checked separately.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader')
local V=r.Vector3 local count=0 local reports={}
local function check(ok,msg) assert(ok,msg);count+=1 end
local function vector(v) return {v.X,v.Y,v.Z} end
local function horizontal(v) return V.new(v.X,0,v.Z).Magnitude end
fs.writeDir('Validation/MapRemaster')
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'))
 local f=loader.install(dm) local load=loader.new(dm) local M=load(f.server.MapBuilder)
 local C=load(f.shared.Config) local L=load(f.shared.MapLayouts) local Graph=load(f.shared.NavigationGraph)
 local Bounds=load(f.server.BoundaryGuard) local before=dm.Workspace:FindFirstChild('DeadSignalMap')
 local started=os.clock() local map=M.build(id) local buildSeconds=os.clock()-started
 check(map.model~=before and (not before or not before.Parent),id..' replaces native preview at run start')
 check(#map.rooms==6 and #map.doors==9 and #map.windows==10,id..' sector/door/window contract')
 check(#map.spawnPoints==4 and #map.wallBuys==7 and #map.boxSpots==6,id..' loadout and crew contract')
 check(#map.fuses==3 and #map.panels==3 and #map.traps==2 and #map.counters==2,id..' objectives and environmental counters')
 check(map.model:GetAttribute('MapReady') and map.model:GetAttribute('LayoutRevision')==9,id..' ready revision')
 local report={id=id,scale=map.scale,layout=map.layout,floorRegions=map.floorRegions,colliders={},parts={},doors={},mounts={},objectives={},windows={},graph={},galleries={},buildSeconds=buildSeconds}
 local function objective(name,p) table.insert(report.objectives,{name=name,position=vector(p)}) end
 for i,p in ipairs(map.spawnPoints) do check(Bounds.contains(map,p),id..' initial spawn inside unlocked sector');objective('Spawn '..i,p) end
 check(not Bounds.contains(map,V.new(10000,4,10000)),id..' exterior cannot become a safe floor')
 for i,room in ipairs(map.rooms) do
  check(room.unlocked==(i==1),id..' initial progression unchanged')
  room.unlocked=true
  if room.stairBase then
   check(horizontal(room.stairTop-room.stairBase)>=29*map.scale,id..' no-jump ramp run')
   table.insert(report.galleries,{room=i,base=vector(room.stairBase),top=vector(room.stairTop),center=vector(room.upperCenter),rise=room.rise})
   objective('Ramp base '..i,room.stairBase) objective('Gallery '..i,room.stairTop)
  end
 end
 for i,d in ipairs(map.doors) do
  local link=L.links(id)[i]
  check(d.cost==L.Links[i][3] and d.a==link[1] and d.b==link[2],id..' progression costs and authored optional loop')
  check(#d.waypoints==4,id..' four-point portal navigation')
  local faces=0
  for _,p in ipairs(d.part:GetChildren()) do if p:GetAttribute('DoorReadHeight') then
   faces+=1;check(math.abs(p.CFrame.Position.Y-5.4)<.001,id..' door sign at physical eye height')
   check(p:FindFirstChildOfClass('SurfaceGui').LightInfluence==0,id..' gate text is independent of unpowered lighting')
  end end
  check(faces==2,id..' readable gate sign from both approaches')
  local points={} for _,p in ipairs(d.waypoints) do points[#points+1]=vector(p) end
  table.insert(report.doors,{a=d.a,b=d.b,position=vector(d.position),waypoints=points}) d.open=true
 end
 for a=1,6 do for b=1,6 do if a~=b then
  check(Graph.route(map,map.rooms[a].center+V.new(0,3,0),map.rooms[b].center+V.new(0,3,0))~=nil,id..' connected unlocked graph')
 end end end
 for i,bay in ipairs(map.mounts) do
  local rdef=map.layout[bay.room] local cf=bay.cf local depth=(cf.Position*map.scale-bay.wall):Dot(cf.LookVector)
  check(math.abs(depth-(.82+bay.depth/2)*map.scale)<.01,id..' bay backed by actual polygon wall')
  check(L.contains(rdef,bay.approach.X/map.scale,bay.approach.Z/map.scale,2.8/map.scale),id..' standing/revive approach stays inside footprint')
  check(Bounds.contains(map,bay.approach+V.new(0,2,0)),id..' bay approach belongs to playable boundary')
  for j=i+1,#map.mounts do local other=map.mounts[j]
   if other.room==bay.room then check(horizontal((cf.Position-other.cf.Position)*map.scale)>=20.49,id..' independent prompt targets separated') end
  end
  table.insert(report.mounts,{key=bay.key,room=bay.room,width=bay.width,depth=bay.depth,cf={cf:GetComponents()},wall=vector(bay.wall),approach=vector(bay.approach)})
  objective(bay.key,bay.approach)
 end
 for _,w in ipairs(map.windows) do
  table.insert(report.windows,{room=w.room,inside=vector(w.inside),outside=vector(w.outside),part=vector(w.part.Position)}) objective('Window approach',w.inside)
 end
 for key,n in pairs(map.navigation.nodes) do table.insert(report.graph,{id=key,position=vector(n.position)}) end
 for _,p in ipairs(map.floorParts) do check(p.Name~='SectorRoof' and p.Name~='CorridorRoof',id..' roofs are never navigation/support floors') end
 for _,buy in ipairs(map.wallBuys) do
  check(not buy.part.CanCollide,id..' buy display never blocks a travel lane')
  if buy.id~='Kestrel' then
   local gun=buy.part:FindFirstChild('Weapon_'..buy.id);check(gun~=nil,id..' visible purchased weapon')
   for _,p in ipairs(gun:GetDescendants()) do if p:IsA('BasePart') then
    local cf=buy.part.CFrame:ToObjectSpace(p.CFrame) local sz=p.Size*.5
    local z=math.abs(cf.RightVector.Z)*sz.X+math.abs(cf.UpVector.Z)*sz.Y+math.abs(cf.LookVector.Z)*sz.Z
    check(cf.Position.Z+z<=-.10,id..' gun is fully in front of its plaque')
   end end
  end
 end
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then
  local finite=true
  for _,value in ipairs({p.CFrame:GetComponents()}) do if value~=value or math.abs(value)==math.huge then finite=false end end
  check(finite,id..' finite transform for '..p.Name)
  local row={name=p.Name,class=p.ClassName,size=vector(p.Size),cf={p.CFrame:GetComponents()},color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,variant=p.MaterialVariant,transparency=p.Transparency,collision=p.CanCollide,group=p.CollisionGroup}
  row.scenery=p:GetAttribute('SceneryOnly') row.tier=p:GetAttribute('DistanceTier')
  if p:IsA('Part') then row.shape=p.Shape.Name end
  if p:FindFirstChildOfClass('SpecialMesh') then row.shape='Ball' end
  local gui=p:FindFirstChildOfClass('SurfaceGui')
  if gui then local label=gui:FindFirstChildOfClass('TextLabel');if label then row.text=label.Text;row.textColor={label.TextColor3.R,label.TextColor3.G,label.TextColor3.B};row.face=gui.Face.Name end end
  table.insert(report.parts,row)
  if p.CanCollide then table.insert(report.colliders,row) end
  if p.Name=='TrapEmitter' then check(not p.CanCollide and p.Size.Y<=.1*map.scale,id..' flush trap emitter') end
 end end
 objective('Extraction center',map.exfilCenter)
 check(#report.parts<6500,id..' bounded static geometry budget')
 fs.writeFile('Validation/MapRemaster/'..id..'-Geometry.json',serde.encode('json',report))
 table.insert(reports,{map=id,parts=#report.parts,colliders=#report.colliders,mounts=#map.mounts,buildSeconds=buildSeconds,galleries=#report.galleries})
 print(id..' map constructed: '..#report.parts..' parts / '..#report.colliders..' colliders / '..string.format('%.3f',buildSeconds)..' offline seconds')
end
fs.writeFile('Validation/MapRemaster/Construction-Report.json',serde.encode('json',{maps=reports,assertions=count,engine=false}))
print('Map remaster contract assertions passed:',count)
local batchCount=require('./map_batch1')
print('Combined map assertions passed:',count+batchCount)
