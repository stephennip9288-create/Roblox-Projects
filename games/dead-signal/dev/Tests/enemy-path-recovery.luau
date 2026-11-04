-- Actual asynchronous Navigation decisions with deliberately unusable native path responses.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local V=r.Vector3 local now=10 local count=0 local queue={} local mode='empty' local disconnected=0 local reads=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local testOs=table.clone(os);testOs.clock=function() return now end
local pf={CreatePath=function()
 local selected=mode
 return {Status=r.Enum.PathStatus.Success,ComputeAsync=function() if selected=='computeError' then error('controlled compute error') end end,
  GetWaypoints=function()
   reads+=1
   if selected=='readError' then error('controlled waypoint read error') end
   if selected=='empty' then return {} end
   return {{Position=V.zero,Action=r.Enum.PathWaypointAction.Walk},
    {Position=V.new(10,0,0),Action=selected=='jump' and r.Enum.PathWaypointAction.Jump or r.Enum.PathWaypointAction.Walk}}
  end,Blocked={Connect=function() return {Disconnect=function() disconnected+=1 end} end}}
end}
local world={Raycast=function(_,pos) return {Position=V.new(pos.X,0,pos.Z)} end,Blockcast=function() return {} end}
local hints=0 local graph={route=function() hints+=1;return {V.new(8,0,0)} end}
local load=loader.new(dm,{services={PathfindingService=pf},modules={NavigationGraph=graph},globals={workspace=world,os=testOs,
 RaycastParams={new=function() return {} end},task={spawn=function(fn) queue[#queue+1]=fn end}}})
local N=load(f.server.Navigation)
local function setup()
 local model=r.Instance.new('Model');model:SetAttribute('NavigationRootHeight',3);model:SetAttribute('NavigationRadius',1)
 local e={id=1,model=model,root={Position=V.new(0,3,0)},hum={MoveTo=function(self,p) self.destination=p end},
  lastMoved=now,lastPosition=V.new(0,3,0),index=1,nextPath=0,kind='Shambler',navRevision=1}
 local owner={ctx={map={model=r.Instance.new('Model'),floorParts={},navigationRevision=1},run={id=1}},pathBudget=10,activePaths=0,list={[1]=e}}
 return e,owner
end
local function finish() local fn=table.remove(queue,1);check(fn~=nil,'path request enqueued');fn() end
for _,result in ipairs({'empty','jump','computeError','readError'}) do
 mode=result;local e,owner=setup()
 for attempt=1,2 do
  N.compute(owner,e,V.new(40,3,0),now);finish()
  check(not e.computing and owner.activePaths==0,result..' releases request/concurrency budget')
  check(e.pathFailures==attempt and e.nextPath>now,result..' counts failure and backs off')
  check(e.path==nil,result..' never installs an unusable route')
 end
 local before=hints;N.move(owner,e,V.new(40,3,0),now)
 check(hints==before+1,result..' reaches portal fallback after repeated native failures')
end
do
 mode='valid';local e,owner=setup();N.compute(owner,e,V.new(40,3,0),now);finish()
 local path=e.path;check(path and #path==2 and e.pathFailures==0,'walk path remains usable')
 local before=disconnected;mode='jump';N.compute(owner,e,V.new(50,3,0),now);finish()
 check(e.path==path and disconnected==before,'failed refresh retains the usable route and its blocked listener')
 N.move(owner,e,V.new(80,3,0),now)
 check(#queue==0,'moving target cannot bypass failed-refresh backoff and flood the path budget')
 N.invalidate(e);check(not e.path and disconnected==before+1,'invalidation disconnects the accepted path listener exactly once')
end
do
 mode='valid';local e,owner=setup();local before=reads;N.compute(owner,e,V.new(40,3,0),now)
 e.dead=true;finish();check(not e.path and owner.activePaths==0 and reads==before,'dead NPC discards late native result before waypoint work')
 e,owner=setup();N.compute(owner,e,V.new(40,3,0),now);owner.ctx.run.id+=1
 finish();check(not e.path and owner.activePaths==0 and reads==before,'previous run discards late native result before waypoint work')
 e,owner=setup();N.compute(owner,e,V.new(40,3,0),now);N.invalidate(e)
 finish();check(not e.path and owner.activePaths==0 and reads==before,'cancelled request cannot resurrect a path or do waypoint work')
end
print('Enemy path recovery regression assertions passed:',count)
