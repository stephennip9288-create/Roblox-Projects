-- Check the test broadphase against the unpruned existing SAT implementation.
local fs=require('@lune/fs');local r=require('@lune/roblox');local loader=require('./Support/RuntimeLoader')
local slow=require('./Support/SourceGeometry');local fast=require('./Support/EnemyB11Geometry');local V=r.Vector3
local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local f=loader.install(dm)
 local map=loader.new(dm)(f.server.MapBuilder).build(id);map.floorRegions={}
 local a,b=slow.world(map),fast.world(map)
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={map.model},CollisionGroup='DeadSignalEnemies',RespectCanCollide=true}
 for _,w in ipairs(map.windows) do for _,size in ipairs({V.new(2.4,6,2.4),V.new(4,8.4,7)}) do
  for _,d in ipairs({V.new(0,0,14),V.new(7,2,-3),V.new(-8,-3,5)}) do
   local cf=r.CFrame.new(w.entry.approach.Position+V.new(0,3,0))
   check((a:Blockcast(cf,size,d,params)~=nil)==(b:Blockcast(cf,size,d,params)~=nil),'broadphase preserves every blocking result')
   local one=a:GetPartBoundsInBox(cf,size,params);local two=b:GetPartBoundsInBox(cf,size,params);local set={}
   for _,p in ipairs(one) do set[p]=true end
   check(#one==#two,'overlap count preserved')
   for _,p in ipairs(two) do check(set[p],'overlap identity preserved') end
  end
 end end
 map.model:Destroy()
end
print('Batch 1.1 spatial parity assertions passed:',count)
