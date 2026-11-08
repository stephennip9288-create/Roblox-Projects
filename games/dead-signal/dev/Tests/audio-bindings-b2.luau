-- Actual Controller.audioBindings, not a duplicate of its detection/foley logic.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local source=fs.readFile('Source/Runtime/client/Controller.lua')
local first=assert(source:find('function Controller.audioBindings(',1,true));local last=assert(source:find('function Controller.start(',first,true))
local count=0;local function check(ok,message) assert(ok,message);count+=1 end
local clock=100;local models={};local root={Position=r.Vector3.zero}
local player={UserId=42,Character={},root=root}
local calls,states,cancelled={},{},{}
local fx={settings={volume=.65}}
function fx:audioEvent(key,context) calls[#calls+1]={key=key,context=context} end
function fx:audioState(state) states[#states+1]=state end
function fx:audioCancel(token) cancelled[#cancelled+1]=token end
function fx:audioReset() end
function fx:audioAvailable() return false end
local world={}
function world:FindFirstChild(name) if name=='DeadSignalEnemies' then return {GetChildren=function() return models end} end end
function world:GetServerTimeNow() return clock+1000 end
local env={workspace=world,Players={GetPlayers=function() return {} end},SoundService={},Enum=r.Enum,Vector3=r.Vector3,
    U={root=function(p) return p.root end,finiteVector=function(v) return typeof(v)=='Vector3' end},R={finite=function(v) return type(v)=='number' and v==v end},
    os={clock=function() return clock end}}
local Controller=luau.load('local Controller={}\n'..source:sub(first,last-1)..'\nreturn Controller',{environment=env,injectGlobals=true})()
local b=Controller.audioBindings(fx,player)
local function model(id,kind)
    local m={attributes={EnemyId=id,EnemyRunId=1,EnemyType=kind or 'Zombie'},root={Position=r.Vector3.new(id+4,0,0)},reads=0}
    function m:GetAttribute(k) self.reads+=1;return self.attributes[k] end
    function m:FindFirstChild(name) return name=='HumanoidRootPart' and self.root or nil end
    function m:FindFirstChildOfClass() return {FloorMaterial=r.Enum.Material.Concrete} end
    return m
end
for id=1,50 do models[id]=model(id) end
local state={participating=true,map='Station',runId=1,phase='Wave',status='Alive',round=3}
local function tick(seconds) clock+=seconds;b:tick(clock,true) end
local function events(key)
    local result={};for _,row in ipairs(calls) do if row.key==key then result[#result+1]=row end end;return result
end
b:set(state,false)
check(states[#states].phase=='Wave' and states[#states].boss==false,'Authoritative state reaches mixer')
check(#events('Enemy.Awareness')==0,'Client proximity/actor discovery never invents acquisition')
local actors=0;for _ in pairs(b.actors) do actors+=1 end;check(actors==40,'Bounded nearest40 actor pass')
local m=models[1];m.attributes.AwarenessAt=clock+1000;m.attributes.AwarenessRunId=1;m.attributes.AwarenessTargetUserId=42
tick(.1);check(#events('Enemy.Awareness')==1,'Fresh matching real detection fact')
tick(.1);check(#events('Enemy.Awareness')==1,'Replicated timestamp deduplicated')
for id,change in pairs({[2]={AwarenessAt=clock+997},[3]={AwarenessAt=clock+1000,AwarenessRunId=99},[4]={AwarenessAt=clock+1000,AwarenessTargetUserId=99}}) do
    local a=models[id].attributes;a.AwarenessAt=clock+1000;a.AwarenessRunId=1;a.AwarenessTargetUserId=42;for k,v in pairs(change) do a[k]=v end
end
tick(3);check(#events('Enemy.Awareness')==1,'Stale/wrong-run/wrong-target detection ignored')
models[2].attributes.EnemyType='Hound';models[2].attributes.AwarenessRunId=1;models[2].attributes.AwarenessTargetUserId=42;models[2].attributes.AwarenessAt=clock+1000
tick(.1);check(#events('Hound.Snarl')>=1 and #events('Enemy.Awareness')==1,'Canine detection never borrows human groan')
calls={};tick(1)
for _=1,20 do m.root.Position+=r.Vector3.new(.01,0,0);tick(.1) end
check(#events('Zombie.Footstep')==0,'Idle jitter does not make footsteps')
m.root.Position+=r.Vector3.new(3,0,0);tick(.6)
check(#events('Zombie.Footstep')==1 and #events('Zombie.Gear')==1,'Real grounded movement produces spatial foley')
check(events('Zombie.Footstep')[1].context.material=='Concrete','Actual material forwarded')
models[3].attributes.EnemyType='Crawler';models[3].root.Position+=r.Vector3.new(3,0,0);tick(.6)
check(#events('Zombie.Drag')==1,'Crawler movement selects dedicated drag slot')
local before=#calls;b:results(state)
check(states[#states].phase=='Results' and #cancelled>0,'Results transitions calmly and cancels actor lifecycles')
tick(1);check(#calls==before,'No actor foley after Results')
b:set(state,true);check(states[#states].active==false,'Loading/travel lock suspends sound scene')
local nextState=table.clone(state);nextState.runId=2;b:set(nextState,false)
check(states[#states].runId=='2','New run changes scene identity')
check(next(b.actors)==nil,'Old-run actors cannot emit after restart')
b:destroy();check(b.destroyed,'Binding cleanup')
print('Batch2 audio binding assertions passed:',count)
