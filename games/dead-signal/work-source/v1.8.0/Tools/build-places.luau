local fs=require('@lune/fs')
local r=require('@lune/roblox')
local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader')
local anatomyMaterials=require('./AnatomyMaterials')
fs.writeDir('Places') fs.writeDir('Validation') fs.writeDir('Source/Places')
local reports={}
for _,key in ipairs({'Lobby','Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Rollback/v1.7.0/DeadSignal-v1.7.0-'..key..'.rbxl'))
 local folders=loader.install(dm)
 fs.writeFile('Source/Places/'..key..'-PlaceConfig.lua',folders.shared.PlaceConfig.Source)
 local load=loader.new(dm)
 load(folders.server.GraphicsService).materials(dm.ReplicatedStorage.DeadSignalArt)
 anatomyMaterials.install(dm)
 local M=load(folders.server.MapBuilder)
 local map=M.build(key=='Lobby' and 'Station' or key)
 map.model:SetAttribute('PreviewBuild','1.8.0')
 local snapshot={key=key,scale=map.scale,layout=map.layout,doors={},colliders={},floors={},objectives={},graph={},routeObstacles=map.routeObstacles,floorRegions=map.floorRegions}
 local function vec(v) return {v.X,v.Y,v.Z} end
 for _,d in ipairs(map.doors) do
  table.insert(snapshot.doors,{a=d.a,b=d.b,position=vec(d.position),cost=d.cost,name=d.name})
  d.open=true;d.part.CanCollide=false
 end
 local floorSet={} for _,part in ipairs(map.floorParts) do floorSet[part]=true end
 for _,obj in ipairs(map.model:GetDescendants()) do if obj:IsA('BasePart') then
  local data={name=obj.Name,class=obj.ClassName,size=vec(obj.Size),cf={obj.CFrame:GetComponents()},floor=floorSet[obj]==true}
  if floorSet[obj] then table.insert(snapshot.floors,data) end
  if obj.CanCollide then table.insert(snapshot.colliders,data) end
 end end
 for _,name in ipairs({'power','radio','relay','upgrade'}) do table.insert(snapshot.objectives,{name=name,position=vec(map[name].CFrame.Position)}) end
 for _,group in ipairs({'perks','fuses','wallBuys','panels','traps'}) do for i,v in pairs(map[group]) do table.insert(snapshot.objectives,{name=group..'/'..tostring(i),position=vec(v.part.CFrame.Position)}) end end
 for i,v in ipairs(map.spawnPoints) do table.insert(snapshot.objectives,{name='Spawn '..i,position=vec(v),spawn=true}) end
 local Graph=load(folders.shared.NavigationGraph)
 local graphChecks=0
 for _,room in ipairs(map.rooms) do room.unlocked=true end
 for _,node in pairs(map.navigation.nodes) do
  local route=Graph.route(map,map.spawnPoints[1],node.position)
  assert(route~=nil,'Missing authored graph path '..key..' '..node.id)
  graphChecks+=1 table.insert(snapshot.graph,{id=node.id,position=vec(node.position),room=node.room,level=node.level})
 end
 -- Restore locked gates in the saved editor scene. Play rebuilds the live graph.
 for _,door in ipairs(map.doors) do door.open=false;door.part.CanCollide=true end
 local file='Places/DeadSignal-v1.8.0-'..key..'.rbxl'
 local bytes=r.serializePlace(dm)
 fs.writeFile(file,bytes)
 local reopened=r.deserializePlace(bytes)
 local art=reopened:FindFirstChild('ReplicatedStorage').DeadSignalArt
 local meshes=0 local appearances=0
 for _,obj in ipairs(art:GetDescendants()) do if obj:IsA('MeshPart') then meshes+=1 elseif obj:IsA('SurfaceAppearance') then appearances+=1 end end
 assert(meshes==614,'Missing art after reopen')
 assert(#reopened:FindFirstChild('MaterialService'):GetChildren()==13,'Missing material variants')
 local scripts=0
 for _,obj in ipairs(reopened:GetDescendants()) do if obj:IsA('LuaSourceContainer') then scripts+=1 end end
 reports[#reports+1]={key=key,bytes=#bytes,instances=#reopened:GetDescendants(),artMeshes=meshes,artAppearances=appearances,
  routes=#map.doors,partitions=#map.routeObstacles,graphChecks=graphChecks,scripts=scripts,enginePlaytest=false}
 fs.writeFile('Validation/'..key..'-Geometry.json',serde.encode('json',snapshot,true))
 print('Built and reopened',key,#bytes,'bytes',meshes,'art meshes',#map.doors,'links',#map.routeObstacles,'partitions')
end
fs.writeFile('Validation/Build-Report.json',serde.encode('json',reports,true))
