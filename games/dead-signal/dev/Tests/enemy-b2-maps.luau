-- Actual generated maps/rigs, controlled movement and NoPath responses.
-- Source hull/support checks only, not Roblox physics or native navmesh acceptance.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader');local B=require('./Support/EnemyB2World')
local process=require('@lune/process')
local V,CF=r.Vector3,r.CFrame;local count=0;local failures={};local now=0
local function check(ok,msg) assert(ok,msg);count+=1 end
r.implementMethod('Humanoid','MoveTo',function(h,p) h:SetAttribute('TestMoveTo',p) end)
local specs={{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}}
local report={engine=false,logicalFloorFill=false,maps={},failures=failures}
local onlyMap=process.args[2];local mode=process.args[3] or 'all';local onlyProfile=process.args[5]
local sourceBefore={}
for _,group in ipairs({'server','shared','client'}) do for _,file in ipairs(fs.readDir('Source/Runtime/'..group)) do
 if file:sub(-4)=='.lua' then local path='Source/Runtime/'..group..'/'..file;sourceBefore[path]=fs.readFile(path) end
end end
local output='Validation/EnemyB2/Maps-'..(onlyMap or 'All')..'-'..mode..'-'..(onlyProfile or 'all')..'.json';fs.writeDir('Validation/EnemyB2')
local function save() report.assertions=count;fs.writeFile(output,serde.encode('json',report)) end
local function selected(spec) return not onlyProfile or (onlyProfile=='Alpha' and spec[2].Alpha) or (onlyProfile==spec[1] and not spec[2].Alpha) end
-- Verify the new test helper distinguishes a ramp surface from its bounding box.
do
 local model=r.Instance.new('Model');local ramp=r.Instance.new('WedgePart');ramp.Size=V.new(10,10,20);ramp.CFrame=CF.new(0,5,0);ramp.CanCollide=true;ramp.Parent=model
 local world=B.world({model=model,floorParts={ramp},floorRegions={}})
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={model}}
 check(not world:Blockcast(CF.new(0,3,-8),V.new(1,2,1),V.new(0,2,4),params),'exact ramp hull admits a box above the slope')
 check(world:Blockcast(CF.new(0,1,-8),V.new(1,2,1),V.new(0,2,4),params)~=nil,'exact ramp hull rejects penetration')
 check(math.abs(world:Raycast(V.new(0,15,-8),V.new(0,-20,0),params).Position.Y-1)<.001,'ramp support uses actual inclined plane')
 model:Destroy()
end
for _,id in ipairs(onlyMap and {onlyMap} or {'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local f=loader.install(dm)
 if process.args[1] and process.args[1]~='base' then f.server.Architecture.Source=fs.readFile(process.args[1]) end
 local build=loader.new(dm);local map=build(f.server.MapBuilder).build(id);local Graph=build(f.shared.NavigationGraph)
 local row={id=id,graphCases=0,corridorCases=0,corridorPass=0,stairCases=0,stairPass=0};report.maps[#report.maps+1]=row
 for _,room in ipairs(map.rooms) do room.unlocked=true end
 for _,door in ipairs(map.doors) do
  door.open=true;door.part.CanCollide=false
  for _,p in ipairs(door.part:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=false end end
 end
 local locations={}
 for i,room in ipairs(map.rooms) do locations[#locations+1]={room=i,level=0,at=room.center}
  if room.upperCenter then locations[#locations+1]={room=i,level=1,at=room.upperCenter} end
 end
 for _,a in ipairs(locations) do for _,b in ipairs(locations) do
  local plan=Graph.plan(map,a.at,b.at);row.graphCases+=1
  check(plan~=nil,id..' all unlocked room/level pairs have a structural route')
  for _,key in ipairs(plan.ids) do check(map.navigation.nodes[key].kind~='center',id..' never routes through a room-center surrogate') end
 end end
 for _,door in ipairs(map.doors) do door.open=false end
 for a=1,6 do for b=1,6 do if a~=b then
  check(Graph.plan(map,map.rooms[a].center,map.rooms[b].center)==nil,id..' closed portals disconnect rooms')
 end end end
 for _,door in ipairs(map.doors) do door.open=true end
 for b=2,6 do map.rooms[b].unlocked=false
  check(Graph.plan(map,map.rooms[1].center,map.rooms[b].center)==nil,id..' locked room access is semantic')
  map.rooms[b].unlocked=true
 end
 local world=B.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local clock=table.clone(os);clock.clock=function() return now end
 local pf={CreatePath=function() return {Status=r.Enum.PathStatus.NoPath,ComputeAsync=function() end} end}
 local load=loader.new(dm,{services={PathfindingService=pf},globals={workspace=world,os=clock,
  RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end},task={spawn=function(fn) fn() end}}})
 local N,R=load(f.server.Navigation),load(f.server.EnemyRigs);local parent=r.Instance.new('Folder')
 local function simulate(kind,mods,start,target,label,steps)
  now=0;local model,root,hum=R.build(parent,kind,start,1,id)
  local e={id=1,kind=kind,mods=mods,model=model,root=root,hum=hum,entered=true,hp=137,lastPosition=start,lastMoved=0,index=1,nextPath=0}
  R.evolve(e);model:PivotTo(CF.new(start.X,start.Y+N.rootHeight(e),start.Z))
  local owner={ctx={map=map,run={id=1},players={}},list={[1]=e},pathBudget=4,activePaths=0}
  local arrived=false
  -- Whiteout's longest real corridor exceeds 240 studs. The bounded mover
  -- needs enough ticks for that route; a 160-tick cap falsely fails progress.
  steps=math.max(steps,math.ceil((target-start).Magnitude/1.5)*2+80)
  for tick=1,steps do
   now=tick*.15;owner.pathBudget=4;world.lastBlock=nil
   N.move(owner,e,target+V.yAxis*N.rootHeight(e),now)
   local destination=hum:GetAttribute('TestMoveTo');local delta=destination-root.Position
   if delta.Magnitude>.005 then
    check(N.clearRoute(owner.ctx,e,destination),'every issued command has a supported collision-checked segment')
    local at=root.Position+delta.Unit*math.min(1.5,delta.Magnitude)
    local floor=N.floor(map,at+V.yAxis*2)
    if floor then at=V.new(at.X,floor.Y+N.rootHeight(e),at.Z) end
    -- Follow a prefix of that checked command. Revalidating the shorter prefix
    -- with a different set of support samples wrongly treats a ramp ahead of
    -- the leading sole as an unrelated obstruction in this non-physics mover.
    model:PivotTo(CF.lookAt(at,at+V.new(delta.X,0,delta.Z)))
   end
   if process.args[6]=='trace' and tick<=12 then print(label,kind,tick,root.Position,destination,e.routeNode,world.lastBlock and world.lastBlock.Name) end
   if (V.new(root.Position.X,0,root.Position.Z)-V.new(target.X,0,target.Z)).Magnitude<1.8 and math.abs(root.Position.Y-N.rootHeight(e)-target.Y)<1.4 then arrived=true;break end
   if now-(e.lastMoved or 0)>8 then break end
  end
  check(owner.list[1]==e and e.hp==137 and model.Parent~=nil,'simulation preserves actor and HP '..label)
  if not arrived then failures[#failures+1]={map=id,label=label,kind=kind,alpha=mods.Alpha==true,at={root.Position.X,root.Position.Y,root.Position.Z},
   target={target.X,target.Y,target.Z},node=e.routeNode,reason=e.navFailure,block=world.lastBlock and world.lastBlock:GetFullName() or nil,
   destination=e.movingTo and {e.movingTo.X,e.movingTo.Y,e.movingTo.Z},floor=N.floor(map,root.Position) and N.floor(map,root.Position).Y};save() end
  model:Destroy();return arrived
 end
 if mode~='stairs' then for di,door in ipairs(map.doors) do if not process.args[4] or process.args[4]=='all' or di==tonumber(process.args[4]) then for _,spec in ipairs(specs) do if selected(spec) then for _,reverse in ipairs({false,true}) do
  local a,b=door.waypoints[1],door.waypoints[#door.waypoints];if reverse then a,b=b,a end
  row.corridorCases+=1
  if simulate(spec[1],spec[2],a,b,'door '..di..(reverse and ' reverse' or ' forward'),160) then row.corridorPass+=1 end
 end end end end end end
 if mode~='doors' then for ri,room in ipairs(map.rooms) do if not process.args[4] or process.args[4]=='all' or ri==tonumber(process.args[4]) then for si,stair in ipairs(room.stairs or {}) do for _,spec in ipairs(specs) do if selected(spec) then for _,reverse in ipairs({false,true}) do
  local a,b=stair.base,stair.top;if reverse then a,b=b,a end
  row.stairCases+=1
  if simulate(spec[1],spec[2],a,b,'room '..ri..' stair '..si..(reverse and ' down' or ' up'),180) then row.stairPass+=1 end
 end end end end end end end
 parent:Destroy();map.model:Destroy()
 print(id..': graph '..row.graphCases..'; corridors '..row.corridorPass..'/'..row.corridorCases..'; stairs '..row.stairPass..'/'..row.stairCases)
 assert(mode~='stairs' or row.stairCases>0,'No staircase matched the supplied filter')
 assert(mode~='doors' or row.corridorCases>0,'No doorway matched the supplied filter')
end
for path,source in pairs(sourceBefore) do assert(fs.readFile(path)==source,'Runtime changed during map test: '..path) end
report.sourceStable=true;save()
assert(#failures==0,'Actual-map pursuit source failures: '..#failures..'; see Validation/EnemyB2/Maps.json')
print('Batch 2 actual-map navigation assertions passed:',count)
