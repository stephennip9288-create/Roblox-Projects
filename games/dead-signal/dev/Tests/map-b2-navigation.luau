-- B2-03 producer metadata regression on actual source-built maps/retained rigs.
-- Offline convex collision/support tests, not Roblox physics or native navmesh.
-- Negative capture: before <baseline Architecture.lua>.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local process=require('@lune/process');local loader=require('./Support/RuntimeLoader')
local Geometry=require('./Support/EnemyB11Geometry');local V=r.Vector3
local before=process.args[1]=='before';local phase=before and 'Before' or 'After'
local root='Validation/B2MapNavigation';fs.writeDir(root)
local out={base='7aaf323de6153134df2154c7ae3b1613a596495b',phase=phase,engine=false,logicalFloorFill=false,maps={},failures={},assertions=0}
local consumed={}
for _,group in ipairs({'server','shared','client'}) do for _,name in ipairs(fs.readDir('Source/Runtime/'..group)) do
 if name:sub(-4)=='.lua' then local path='Source/Runtime/'..group..'/'..name;consumed[path]=fs.readFile(path) end
end end
local function check(ok,msg) out.assertions+=1;if not ok then out.failures[#out.failures+1]=msg end end
local function vec(p) return {p.X,p.Y,p.Z} end
local specs={{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}}
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local f=loader.install(dm)
 if before then assert(process.args[2],'Provide exact baseline Architecture source');f.server.Architecture.Source=fs.readFile(process.args[2]) end
 local map=loader.new(dm)(f.server.MapBuilder).build(id)
 local snapshot={parts={},doors={},windows={},mounts={},nodes={},edges={},stairs={}}
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then
  local row={path=p:GetFullName(),class=p.ClassName,cf={p.CFrame:GetComponents()},size=vec(p.Size),
   color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,variant=p.MaterialVariant,transparency=p.Transparency,
   collide=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,shadow=p.CastShadow,anchored=p.Anchored,group=p.CollisionGroup}
  if p:IsA('MeshPart') then
   local meshOK,mesh=pcall(function()return p.MeshId end);local textureOK,texture=pcall(function()return p.TextureID end)
   row.mesh=meshOK and tostring(mesh) or 'unavailable-in-lune';row.texture=textureOK and tostring(texture) or 'unavailable-in-lune'
  end
  snapshot.parts[#snapshot.parts+1]=row
 end end
 for di,d in ipairs(map.doors) do
  local points={};for _,p in ipairs(d.waypoints) do points[#points+1]=vec(p) end
  snapshot.doors[#snapshot.doors+1]={id=di,a=d.a,b=d.b,cost=d.cost,name=d.name,position=vec(d.position),waypoints=points}
 end
 for _,w in ipairs(map.windows) do local e=w.entry
  snapshot.windows[#snapshot.windows+1]={id=e.id,room=e.room,kind=e.kind,schema=e.schema,width=e.width,height=e.height,sillHeight=e.sillHeight,
   approach={e.approach:GetComponents()},breach={e.breach:GetComponents()},landing={e.landing:GetComponents()},inside=vec(w.inside),outside=vec(w.outside),clearance=e.clearance,allowedKinds=e.allowedKinds}
 end
 for _,m in ipairs(map.mounts) do snapshot.mounts[#snapshot.mounts+1]={key=m.key,room=m.room,frame={m.cf:GetComponents()},wall=vec(m.wall),approach=vec(m.approach)} end
 for key,n in pairs(map.navigation.nodes) do
  snapshot.nodes[key]={room=n.room,level=n.level,kind=n.kind,position=vec(n.position)}
  snapshot.edges[key]={};for _,edge in ipairs(map.navigation.edges[key]) do snapshot.edges[key][#snapshot.edges[key]+1]={to=edge.to,door=edge.door and edge.door.part.Name} end
 end
 for ri,room in ipairs(map.rooms) do for si,s in ipairs(room.stairs or {}) do
  snapshot.stairs[#snapshot.stairs+1]={room=ri,index=si,base=vec(s.base),top=vec(s.top),width=s.width,run=s.run,rise=s.rise}
 end end
 fs.writeFile(root..'/'..phase..'-'..id..'-Snapshot.json',serde.encode('json',snapshot))
 local world=Geometry.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local load=loader.new(dm,{globals={workspace=world,RaycastParams={new=function()return{}end},OverlapParams={new=function()return{}end}}})
 local N=load(f.server.Navigation);local Rigs=load(f.server.EnemyRigs);local Graph=load(f.shared.NavigationGraph);local Game=load(f.server.Game)
 local folder=r.Instance.new('Folder');local owner={ctx={map=map,players={}},list={},folder=folder}
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={map.model}}
 local report={id=id,parts=#snapshot.parts,doors={},profiles={},bodySweeps=0,rejectedSweeps={},graphCases=0,graphFailures={},
  graphNodeSupportDiagnostics={},corridorSupportDiagnostics={}}
 check(#map.doors==9 and #map.windows==10 and #map.rooms==6,id..' accepted map inventory')
 local callbacks={};local ctx={map=map,run={round=1,power=false,peak=1},interact={bind=function(_,part,_,_,_,callback)callbacks[part]=callback;return{}end}}
 local g=setmetatable({ctx=ctx,makeBox=function()end,broadcast=function()end,pay=function()return true end},Game);g:bindMap()
 for di,d in ipairs(map.doors) do
  local a,b=d.waypoints[2]+V.yAxis*4,d.waypoints[3]+V.yAxis*4
  local hit=world:Blockcast(r.CFrame.new(a),V.new(1,2,1),b-a,params)
  check(hit and hit.Instance==d.part,id..' door '..di..' actual closed gate blocks the route')
  local revision=map.navigationRevision;callbacks[d.part]({DisplayName='Offline audit'})
  check(d.open and not d.part.CanCollide and not d.part.CanQuery,id..' door '..di..' actual purchase clears the gate')
  check(map.navigationRevision==revision+1,id..' door '..di..' purchase invalidates navigation')
  for _,p in ipairs(d.part:GetDescendants()) do if p:IsA('BasePart') then
   check(not p.CanCollide and not p.CanQuery,id..' door '..di..' no invisible purchased barrier')
  end end
  check(d.part.Size.X>=14*map.scale-.001 and d.part.Size.Y>=14*map.scale-.001,id..' door '..di..' retains opening clearance')
  local points={};for _,p in ipairs(d.waypoints) do points[#points+1]=vec(p) end
  report.doors[#report.doors+1]={id=di,a=d.a,b=d.b,width=d.part.Size.X,height=d.part.Size.Y,waypoints=points}
  for ni,p in ipairs(d.waypoints) do
   check((map.navigation.nodes['door'..di..'p'..ni].position-p).Magnitude<.0001,id..' door '..di..' published node matches producer waypoint')
  end
 end
 for _,room in ipairs(map.rooms) do room.unlocked=true end
 for si,spec in ipairs(specs) do
  local model,enemyRoot,hum=Rigs.build(folder,spec[1],V.zero,si,id)
  local e={id=si,kind=spec[1],model=model,root=enemyRoot,hum=hum,mods=spec[2]};Rigs.evolve(e);owner.list={[si]=e}
  local bounds=N.rigBounds(e,'Walk','Approach');local height=N.rootHeight(e)
  report.profiles[#report.profiles+1]={kind=e.kind,alpha=spec[2].Alpha==true,rootHeight=height,low=vec(bounds.low),high=vec(bounds.high)}
  for di,d in ipairs(map.doors) do for _,reverse in ipairs({false,true}) do
   local path=table.clone(d.waypoints)
   if reverse then local p={};for n=#path,1,-1 do p[#p+1]=path[n]end;path=p end
   for seg=1,#path-1 do
    local a,b=path[seg],path[seg+1];local direction=(b-a).Unit
    local steps=math.max(2,math.ceil((b-a).Magnitude/.5));local previous=a+V.yAxis*height
    for sample=0,steps do
     local feet=a:Lerp(b,sample/steps);local at=feet+V.yAxis*height
     local clear,reason=N.traversalClear(owner,e,previous,at,nil,true,bounds,direction);report.bodySweeps+=1
     check(clear,id..' door '..di..' '..e.kind..' '..(reverse and 'reverse' or 'forward')..' full walking rig clears segment '..seg..' sample '..sample)
     if not clear then report.rejectedSweeps[#report.rejectedSweeps+1]={door=di,segment=seg,reverse=reverse,kind=e.kind,alpha=spec[2].Alpha==true,
      at=vec(feet),reason=reason,collider=world.lastBlock and world.lastBlock:GetFullName()} end
     previous=at
     if si==1 and not reverse then
      local floor=world:Raycast(feet+V.yAxis*.5,-V.yAxis*2,params)
      if not floor or math.abs(floor.Position.Y-feet.Y)>.03 then report.corridorSupportDiagnostics[#report.corridorSupportDiagnostics+1]={door=di,segment=seg,at=vec(feet),floor=floor and floor.Position.Y} end
     end
    end
   end
  end end
  model:Destroy()
 end
 -- Every gate combination: distinguish room reachability from collision-free
 -- straight hints; the consumer still owns native paths around room cover.
 for mask=0,511 do
  for di,d in ipairs(map.doors) do d.open=bit32.band(mask,bit32.lshift(1,di-1))~=0 end
  for start=1,6 do
   local reachable={[start]=true}
   for _=1,6 do for _,d in ipairs(map.doors) do if d.open then
    if reachable[d.a] then reachable[d.b]=true end;if reachable[d.b] then reachable[d.a]=true end
   end end end
   for target=1,6 do if start~=target then
    local route=Graph.route(map,map.rooms[start].center+V.yAxis*3,map.rooms[target].center+V.yAxis*3)
    local ok=(route~=nil)==(reachable[target]==true);report.graphCases+=1
    check(ok,id..' door mask '..mask..' room reachability '..start..' -> '..target)
    if not ok then report.graphFailures[#report.graphFailures+1]={mask=mask,from=start,to=target} end
   end end
  end
 end
 for key,node in pairs(map.navigation.nodes) do
  local floor=world:Raycast(node.position+V.yAxis*.5,-V.yAxis*2,params)
  if not floor or math.abs(floor.Position.Y-node.position.Y)>.03 then
   report.graphNodeSupportDiagnostics[#report.graphNodeSupportDiagnostics+1]={id=key,level=node.level,kind=node.kind,at=vec(node.position),floor=floor and floor.Position.Y}
  end
 end
 if id=='Frost' then
  local at=map.doors[7].waypoints[3];local floor=world:Raycast(at+V.yAxis*.5,-V.yAxis*2,params)
  check(floor and math.abs(floor.Position.Y-at.Y)<.02,'Frost7 corrected approach has exact actual-part support')
  report.frost7Approach={at=vec(at),floor=floor and vec(floor.Position),part=floor and floor.Instance.Name}
 end
 out.maps[#out.maps+1]=report
 print(id..': '..report.bodySweeps..' complete-rig sweeps; '..#report.rejectedSweeps..' rejected; '..report.graphCases..' graph cases; '..#report.graphFailures..' topology mismatches')
 map.model:Destroy();folder:Destroy()
end
for path,source in pairs(consumed) do check(fs.readFile(path)==source,'Runtime stable during audit: '..path) end
fs.writeFile(root..'/'..phase..'-Report.json',serde.encode('json',out))
print('Batch 2 map navigation checks:',out.assertions,'failures:',#out.failures)
if before then assert(#out.failures>0,'Negative capture must reproduce the baseline rejected route')
else assert(#out.failures==0,'B2 map navigation regression; see '..root..'/'..phase..'-Report.json') end
return out.assertions
