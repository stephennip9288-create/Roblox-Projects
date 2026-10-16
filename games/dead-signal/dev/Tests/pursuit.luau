-- Regression cases for floor/root mismatch, live target movement, obstruction and physical crowd steering.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Station.rbxl')) local folders=loader.install(dm)
local V=r.Vector3 local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local blocked=false local floorY=0 local requested={} local queue={} local fail=false local now=10
local world={Raycast=function(_,pos) return {Position=V.new(pos.X,pos.Y>=floorY and floorY or 0,pos.Z)} end,Blockcast=function() return blocked and {} or nil end}
local pf={CreatePath=function(_,agent) return {Status=fail and r.Enum.PathStatus.NoPath or r.Enum.PathStatus.Success,
 ComputeAsync=function(_,start,goal) requested[#requested+1]={start=start,goal=goal,agent=agent} end,
 GetWaypoints=function() return {{Position=V.new(0,3,0),Action=r.Enum.PathWaypointAction.Walk},{Position=V.new(12,3,0),Action=r.Enum.PathWaypointAction.Walk}} end} end}
local testOs=table.clone(os);testOs.clock=function() return now end
local load=loader.new(dm,{services={PathfindingService=pf},globals={workspace=world,os=testOs,RaycastParams={new=function() return {} end},task={spawn=function(fn) queue[#queue+1]=fn end}}})
local N=load(folders.server.Navigation)
local function enemy(kind,height,id)
 local model=r.Instance.new('Model');model:SetAttribute('NavigationRootHeight',height);model:SetAttribute('NavigationRadius',1.18);model:SetAttribute('NavigationHeight',6)
 local root={Position=V.new(0,height,0),Size=V.new(2,2,1)} local hum={HipHeight=0,MoveTo=function(self,p) self.destination=p end}
 return {id=id or 1,kind=kind,root=root,hum=hum,model=model,lastPosition=root.Position,lastMoved=10,nextPath=0,index=1,navRevision=8}
end
local map={model=r.Instance.new('Model'),floorParts={},navigationRevision=8}
local e=enemy('Shambler',3.08) local owner={ctx={map=map,run={id=1}},list={[1]=e},pathBudget=10,activePaths=0}
local goal=N.goal(owner.ctx,e,V.new(30,3,40),now)
check(goal==V.new(30,3.08,40),'live target coordinates retained without a room center')
check(N.waypointReached(e,V.zero),'a rig standing on its waypoint advances regardless of root height')
e.root.Position=V.new(0,13.08,0);check(not N.waypointReached(e,V.zero),'same XZ on upper gallery does not skip lower waypoint')
e.root.Position=V.new(13.2,3.08,0);check(N.waypointReached(e,V.new(12,0,0),V.zero),'crossed waypoint plane advances')
e.root.Position=V.new(14,3.08,4);check(not N.waypointReached(e,V.new(12,0,0),V.zero),'plane test cannot cut a corner far from path')
e.root.Position=V.new(0,3.08,0);N.move(owner,e,V.new(10,3,0),now)
check(e.hum.destination==V.new(10,3.08,0),'clear same-room movement goes directly to player')
N.move(owner,e,V.new(10,3,9),now+.1);check(e.hum.destination==V.new(10,3.08,9),'moving player updates goal in same room immediately')
blocked=true;N.move(owner,e,V.new(80,3,100),now+.2)
check(#queue==1,'cross-room obstruction requests native route to live player')
queue[1]();check(requested[1].goal==V.new(80,3.08,100),'path destination is player, never source-room center')
check(e.path[1].Position.Y==0,'engine waypoint heights normalized onto actual floor')
N.move(owner,e,V.new(80,3,100),now+.3);check(e.index==2 and e.hum.destination==V.new(12,3.08,0),'first floor waypoint skipped; next root-normalized waypoint followed')
local previous=e.path;now=12;fail=true;N.compute(owner,e,V.new(90,3.08,100),now)
check(e.path==previous and e.computing,'usable route retained during asynchronous refresh')
queue[2]();check(e.path==previous and e.pathFailures==1,'failed refresh does not strand an existing route')
fail=false;floorY=12;goal=N.goal(owner.ctx,e,V.new(100,15,100),now)
check(math.abs(goal.Y-15.08)<.001,'gallery pursuit projects onto gallery instead of ground')
for _,kind in ipairs({'Hound','Crawler','Warden'}) do
 local height=kind=='Hound' and 1.8 or kind=='Crawler' and 1.05 or 4.312
 local f=enemy(kind,height);floorY=0
 check(N.waypointReached(f,V.zero),kind..' waypoint clearance regression')
end
-- Navmesh samples can be below the actual ramp surface; project from above it.
floorY=4.5;e.root.Position=V.new(0,7.58,0);now=14;fail=false
N.compute(owner,e,V.new(20,7.58,20),now);queue[3]()
check(e.path[1].Position.Y==4.5,'waypoint floor cast accounts for voxel height error on ramps')
e.root.Position=V.new(0,3.08,0)
-- A breached window cannot place several NPCs or a player into the same body volume.
floorY=0
local window={inside=V.new(0,3,0),outside=V.new(0,3,-14)}
local other=enemy('Shambler',3.08,2);other.entered=true;owner.list={[1]=e,[2]=other}
local at=N.entryPoint(owner,e,window)
check(at and (at-other.root.Position).Magnitude>2.5,'entry chooses a separated slot beside an existing enemy')
owner.list={[1]=e}
local char=r.Instance.new('Model');local playerRoot=r.Instance.new('Part');playerRoot.Name='HumanoidRootPart';playerRoot.Position=V.new(0,3,0);playerRoot.Parent=char
local player={Character=char};owner.ctx.players={[player]={participating=true,status='Alive'}}
at=N.entryPoint(owner,e,window);check(at and (at-playerRoot.Position).Magnitude>2.3,'entry does not teleport inside a survivor')
owner.ctx.players={};owner.list={[1]=e}
-- The recovery graph has unique edges and never emits a source-room center.
local actualLoad=loader.new(dm) local M=actualLoad(folders.server.MapBuilder) local actual=M.build('Station') local Graph=actualLoad(folders.shared.NavigationGraph)
local seen={}
for _,door in ipairs(actual.doors) do local key=math.min(door.a,door.b)..':'..math.max(door.a,door.b) check(not seen[key],'unique sector connection');seen[key]=true;door.open=true end
for _,room in ipairs(actual.rooms) do room.unlocked=true end
check(seen['1:5'] and seen['3:5'],'diagonal links join different sectors')
for from=1,6 do for to=1,6 do if from~=to then
 local start=actual.rooms[from].center+V.new(2,3,1) local route=Graph.route(actual,start,actual.rooms[to].center+V.new(0,3,0))
 check(route and #route>0,'connected sectors')
 check((route[1]-actual.rooms[from].center).Magnitude>3,'no source-center detour')
end end end
print('Pursuit regression assertions passed:',count)
