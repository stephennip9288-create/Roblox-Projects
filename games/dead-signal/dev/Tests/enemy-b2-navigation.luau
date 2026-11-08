-- Controlled native responses exercise actual Navigation; not an engine/navmesh test.
local fs=require('@lune/fs');local r=require('@lune/roblox');local loader=require('./Support/RuntimeLoader')
local process=require('@lune/process');local V=r.Vector3;local count=0
local before=process.args[1]=='before';local function check(ok,msg) assert(ok,msg);count+=1 end
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
if before then for _,spec in ipairs({{'server','Navigation'},{'shared','NavigationGraph'}}) do
 f[spec[1]][spec[2]].Source=fs.readFile('Validation/EnemyB2/BeforeSource/'..spec[1]..'/'..spec[2]..'.lua')
end end
r.implementMethod('Humanoid','MoveTo',function(hum,p) hum:SetAttribute('TestMoveTo',p) end)
local now=100;local blocked=true;local queue={};local requests={};local result='success'
local world={Raycast=function(_,pos) return {Position=V.new(pos.X,0,pos.Z)} end,
 Blockcast=function() return blocked and {} or nil end,GetPartBoundsInBox=function() return {} end}
local pf={CreatePath=function()
 local path={Status=result=='success' and r.Enum.PathStatus.Success or r.Enum.PathStatus.NoPath}
 function path:ComputeAsync(start,goal) self.start=start;self.goal=goal;requests[#requests+1]={start=start,goal=goal} end
 function path:GetWaypoints() return {{Position=self.start,Action=r.Enum.PathWaypointAction.Walk},{Position=self.goal,Action=r.Enum.PathWaypointAction.Walk}} end
 return path
end}
local clock=table.clone(os);clock.clock=function() return now end
local load=loader.new(dm,{services={PathfindingService=pf},globals={workspace=world,os=clock,
 RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end},task={spawn=function(fn) queue[#queue+1]=fn end}}})
local N=load(f.server.Navigation);local G=load(f.shared.NavigationGraph);local Rigs=load(f.server.EnemyRigs)
local parent=r.Instance.new('Folder');local model,root,hum=Rigs.build(parent,'Shambler',V.new(0,3.08,0),1,'Station')
local e={id=1,model=model,root=root,hum=hum,kind='Shambler',entered=true,hp=321,mods={Enraged=true},lastMoved=now,lastPosition=root.Position,nextPath=0,index=1}
local map={model=r.Instance.new('Model'),floorParts={},navigationRevision=9}
local owner={ctx={map=map,run={id=1},players={}},list={[1]=e},pathBudget=4,activePaths=0}
local function finish() local fn=table.remove(queue,1);assert(fn,'path queued');fn() end
local target=V.new(12,3.08,0)
N.move(owner,e,target,now);finish();N.move(owner,e,target,now+.15)
if before then
 check((hum:GetAttribute('TestMoveTo')-target).Magnitude<.001,'negative control reproduces an unchecked native waypoint through a wall')
 print('Before Batch 2: native Success waypoint commanded across a blocked segment');return
end
check(hum:GetAttribute('TestMoveTo')==root.Position,'unusable native segment holds instead of pushing a wall')
check(e.hp==321 and e.mods.Enraged and owner.list[1]==e,'route failure preserves actor identity, HP, modifiers and live quota')
blocked=false;now+=3;owner.pathBudget=4;N.move(owner,e,target,now)
check((hum:GetAttribute('TestMoveTo')-target).Magnitude<.001,'cleared obstruction resumes physically valid pursuit')
-- Exact semantic graph: two rooms, a four-point corridor and a closed central door.
map.scale=1;map.rooms={{unlocked=true},{unlocked=true}}
map.layout={{x=0,z=0,w=40,d=40},{x=40,z=0,w=40,d=40}}
map.rooms[1].center=V.zero;map.rooms[2].center=V.new(40,0,0)
local door={a=1,b=2,open=false,position=V.new(20,0,12),waypoints={V.new(15,0,12),V.new(18,0,12),V.new(22,0,12),V.new(25,0,12)}}
map.doors={door};G.build(map)
check(not G.plan(map,V.zero,V.new(40,0,0)),'closed doorway is unreachable even without a physical gate mock')
door.open=true;local plan=G.plan(map,V.zero,V.new(40,0,0))
check(plan and #plan.points>0 and plan.fromRoom==1 and plan.toRoom==2,'normal pursuit chooses an actual room transition')
for _,p in ipairs(plan.points) do check(p.Z==12,'corridor turns are retained instead of aiming at the survivor through a wall') end
local key=G.stateKey(map);door.open=false
check(G.stateKey(map)~=key,'door state change invalidates routes without relying on a producer revision increment')
door.open=true;map.rooms[2].unlocked=false
check(not G.plan(map,V.zero,V.new(40,0,0)),'locked target room cannot be entered through an open door')
map.rooms[2].unlocked=true
-- Late paths from a previous access state cannot resurrect a closed route.
e.navRevision=nil;N.invalidate(e);blocked=true;now+=1;owner.pathBudget=4
N.move(owner,e,V.new(40,3.08,0),now)
check(#queue==1,'different-room pursuit uses the existing native request budget')
check(owner.activePaths==1 and e.computing,'request remains asynchronous')
door.open=false;finish()
check(not e.path and not e.computing and owner.activePaths==0,'door closure rejects a late asynchronous result')
N.move(owner,e,V.new(40,3.08,0),now+.2)
check(hum:GetAttribute('TestMoveTo')==root.Position,'locked path never falls back to a direct player MoveTo')
print('Batch 2 navigation assertions passed:',count)
