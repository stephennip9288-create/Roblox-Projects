local fs=require('@lune/fs')
local r=require('@lune/roblox')
local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local folders=loader.install(dm)
local count=0
local function check(v,m) assert(v,m);count+=1 end
local queue={};local created=0
local blockedCallback
local pf={CreatePath=function(_,agent)
 created+=1;check(agent.AgentCanJump==false and agent.AgentCanClimb==false,'no-jump path agent')
 return {ComputeAsync=function() end,Status=r.Enum.PathStatus.Success,GetWaypoints=function() return {{Position=r.Vector3.new(0,3,0),Action=r.Enum.PathWaypointAction.Walk},{Position=r.Vector3.new(10,3,0),Action=r.Enum.PathWaypointAction.Walk}} end,
 Blocked={Connect=function(_,fn) blockedCallback=fn;return {Disconnect=function() blockedCallback=nil end} end}}
end}
local load=loader.new(dm,{services={PathfindingService=pf},globals={task={spawn=function(fn) table.insert(queue,fn) end}}})
local N=load(folders.server.Navigation)
local model=r.Instance.new('Model')
local enemy={id=1,model=model,root={Position=r.Vector3.new(0,3,0)},kind='Shambler',requestToken=0,nextPath=0,index=1}
local owner={ctx={run={id=1}},pathBudget=2,activePaths=0}
N.compute(owner,enemy,r.Vector3.new(10,3,0),0)
check(owner.pathBudget==1 and owner.activePaths==1 and enemy.computing,'budget consumed without blocking tick')
N.compute(owner,enemy,r.Vector3.new(11,3,0),.1);check(#queue==1,'one pending request per NPC')
N.invalidate(enemy);queue[1]();check(enemy.path==nil and owner.activePaths==0,'late invalidated path discarded')
N.compute(owner,enemy,r.Vector3.new(10,3,0),1);queue[2]();check(enemy.path~=nil and enemy.pathObject~=nil,'successful asynchronous route accepted')
enemy.index=2;blockedCallback(1);check(enemy.path~=nil,'blockage behind NPC ignored')
blockedCallback(2);check(enemy.path==nil,'forward blockage invalidates')
owner.pathBudget=0;enemy.computing=false;N.compute(owner,enemy,r.Vector3.new(15,3,0),2);check(#queue==2,'budget exhaustion defers work')
owner.pathBudget=1;owner.activePaths=3;N.compute(owner,enemy,r.Vector3.new(15,3,0),2);check(#queue==2,'concurrency cap')
owner.activePaths=0;N.compute(owner,enemy,r.Vector3.new(15,3,0),3);owner.ctx.run.id=2;queue[3]();check(enemy.path==nil,'stale previous-run path cannot leak into next match')
print('Navigation scheduling assertions passed:',count)
-- All ready NPCs receive budget access, even when early IDs always ask again.
local served={}
local navigationDouble={invalidate=function() end,move=function(owner,enemy,_,now)
 if owner.pathBudget>0 then served[enemy.id]=true;owner.pathBudget-=1 end
 enemy.lastMoved=now
end}
local loadEnemies=loader.new(dm,{modules={Navigation=navigationDouble}})
local E=loadEnemies(folders.server.Enemies)
local char=r.Instance.new('Model');local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.Position=r.Vector3.new(0,3,0);root.Parent=char
local player={Parent=true,UserId=1,Character=char}
local ctx={map={},players={[player]={participating=true,status='Alive'}},run={id=1,round=15,mode='Standard'}}
local horde=setmetatable({ctx=ctx,list={},pathTokens=4,pathBudgetAt=0,targetLoads={}},E)
for id=1,40 do horde.list[id]={id=id,entered=true,root={Parent=true,Position=r.Vector3.new(100+id,3,0)},model={},hum={},kind='Shambler',attack=100,shock=100,lastMoved=0} end
for tick=1,42 do horde:tick(tick*.15) end
local total=0;for _ in pairs(served) do total+=1 end
check(total==40,'rotating scheduler serves all forty ready NPCs')
print('Navigation fairness total assertions:',count)
