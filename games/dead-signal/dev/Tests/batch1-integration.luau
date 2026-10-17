-- Actual cross-lane adapter behavior with deterministic replicated facts.
-- The sound engine/mix is covered separately by audio.luau; this is no listening claim.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
for _,class in ipairs({'ReplicatedStorage','Folder'}) do r.implementMethod(class,'WaitForChild',function(item,name) return assert(item:FindFirstChild(name),name) end) end
local now=100 local ws=dm.Workspace local count=0
for _,name in ipairs({'DeadSignalMap','DeadSignalEnemies'}) do local old=ws:FindFirstChild(name) if old then old:Destroy() end end
local function check(ok,message) assert(ok,message);count+=1 end
local function make(class,name,parent,attributes)
 local item=r.Instance.new(class);item.Name=name;item.Parent=parent
 for key,value in pairs(attributes or {}) do item:SetAttribute(key,value) end return item
end
local function position(part,p) part.Position=p;part.CFrame=r.CFrame.new(p) end
local world={FindFirstChild=function(_,name) return ws:FindFirstChild(name) end,GetServerTimeNow=function() return now end}
local load=loader.new(dm,{modules={Effects={},UI={},Scope={},MobileControls={},AimAssist={}},
 globals={workspace=world,os={clock=function() return now end}}})
local Controller=load(f.client.Controller)
local states,events,cancelled={},{},{}
local fx={settings={},audioState=function(_,state) states[#states+1]=state end,
 audioEvent=function(_,key,context) events[#events+1]={key=key,context=context} end,
 audioCancel=function(_,token) cancelled[token]=true end,audioReset=function() end}
local character=make('Model','Operator',ws);local root=make('Part','HumanoidRootPart',character);position(root,r.Vector3.new(10,3,10))
local player={UserId=17,Character=character}
local running=make('Sound','Running',root);running.Volume=.8
local map=make('Model','DeadSignalMap',ws)
local semantics=make('Folder','MapSemantics',map,{SchemaVersion=1,Coordinates='WorldStuds'})
local zones=make('Folder','Zones',semantics)
local function zone(id,level,priority,outdoors,purpose,lo,hi)
 local item=make('Folder',id,zones,{Position=r.Vector3.new(10,level==1 and 12 or 0,10),Level=level,Priority=priority,Indoors=not outdoors,Room=1,Purpose=purpose})
 local region=make('Folder','Region1',item,{PointCount=4})
 for index,p in ipairs({{lo,lo},{hi,lo},{hi,hi},{lo,hi}}) do region:SetAttribute('Point'..index,r.Vector3.new(p[1],0,p[2])) end
end
zone('ground',0,10,false,'Diesel generation',0,20)
zone('upper',1,20,false,'Carrier control watch',0,20)
zone('outside',0,10,true,'Antenna switching field',25,45)
local landmarks=make('Folder','Landmarks',semantics)
make('Folder','mast',landmarks,{Kind='AntennaField',Position=r.Vector3.new(70,24,80)})
local visual=make('Folder','VisualEvents',semantics)
local sweep=make('Folder','sweep',visual,{Kind='CarrierSweep',Position=r.Vector3.new(80,20,80),Active=false})
local actors=make('Folder','DeadSignalEnemies',ws)
local bridge=Controller.audioBindings(fx,player)
local state={runId=7,map='Station',participating=true,status='Alive',phase='Wave',round=6,signal=false}
bridge:set(state,false)
check(states[#states].room=='ground' and states[#states].indoors,'ground listener resolves source-authored room polygon')
check(running.SoundGroup and running.SoundGroup.Name=='DeadSignalCharacterMix','default character sounds join the master mix without duplicate footsteps')
fx.settings.volume=0;now+=.2;bridge:tick(now)
check(running.SoundGroup.Volume==0 and math.abs(running.Volume-.8)<.001,'master mute reaches default footsteps without rewriting their own dynamic volume')
fx.settings.volume=.4;now+=.2;bridge:tick(now)
check(math.abs(running.SoundGroup.Volume-.4)<.001,'live master volume updates the character group')
check(states[#states].anchors['World.Station.radio']==r.Vector3.new(70,24,80),'radio anchor is actual authored landmark')
check(states[#states].anchors['World.Station.contact']==nil,'unsynchronized auto-world activity remains disabled')
position(root,r.Vector3.new(10,15,10));now+=.2;bridge:tick(now)
check(states[#states].room=='upper','upper gallery wins only at supported listener height')
position(root,r.Vector3.new(30,3,30));now+=.2;bridge:tick(now)
check(states[#states].room=='outside' and not states[#states].indoors,'outdoor polygon updates the mix state')
sweep:SetAttribute('Active',true);now+=.2;bridge:tick(now)
check(events[#events].key=='World.Landmark' and events[#events].context.position==sweep:GetAttribute('Position'),'visible world event supplies real cue position')
local before=#events;now+=.2;bridge:tick(now);check(#events==before,'held visual activity cannot repeat its start cue')
position(root,r.Vector3.new(0,3,0))
local npcModels={}
for id=1,42 do
 local actor=make('Model','Actor'..id,actors,{EnemyId=id,EnemyRunId=7,EnemyType=id==1 and 'Hound' or 'Shambler',Alpha=id==1,
  EntrySourceId='enemy:7:'..id..':1',EntryCue='Enemy.Entry.Contact',EntryCueAt=now})
 local part=make('Part','HumanoidRootPart',actor);position(part,r.Vector3.new(id*2,3,1));npcModels[id]=actor
end
now+=.2;before=#events;bridge:tick(now)
local tracked=0;for _ in pairs(bridge.actors) do tracked+=1 end
check(tracked==40,'client actor cache never exceeds authoritative live-enemy ceiling')
local entry,alpha=0,0
for i=before+1,#events do
 if events[i].key=='Enemy.Entry.Contact' then entry+=1 end
 if events[i].key=='Enemy.Alpha' then alpha+=1 end
end
check(entry==4 and alpha==1,'dense entry catch-up is bounded and Alpha is announced once')
before=#events;now+=.2;bridge:tick(now);check(#events==before,'unchanged replicated entry facts are one-shot')
local stepper=npcModels[2]:FindFirstChild('HumanoidRootPart')
local hum=make('Humanoid','Humanoid',npcModels[2]);hum.FloorMaterial=r.Enum.Material.Concrete
position(stepper,stepper.Position+r.Vector3.new(1,0,0));now+=.6;before=#events;bridge:tick(now)
local footstep=false for i=before+1,#events do if events[i].key=='Zombie.Footstep' then footstep=events[i].context.material=='Concrete' end end
check(footstep,'moving grounded NPC foley uses the physical material and actor lifecycle')
local token=bridge.actors[npcModels[1]].token;local life=bridge.actors[npcModels[1]].life
npcModels[1]:SetAttribute('EntryCue','Enemy.Entry.Cancel');npcModels[1]:SetAttribute('EntryCueAt',now)
now+=.2;bridge:tick(now);check(cancelled[token],'server traversal cancellation invalidates entry voice token')
npcModels[1]:Destroy();now+=.2;bridge:tick(now)
check(cancelled[life] and bridge.actors[npcModels[1]]==nil,'removed actor retires its routine voices and cache')
before=#events;state=table.clone(state);state.phase='Intermission';bridge:set(state,false)
check(#events==before+1 and events[#events].key=='Wave.Complete','wave completion follows one acknowledged phase edge')
before=#events;bridge:set(state,false);check(#events==before,'repeated state cannot repeat a phase cue')
state=table.clone(state);state.phase='Exfil';bridge:set(state,false)
check(events[#events].key=='Extraction.Warn','extraction warning is authoritative and distinct')
state=table.clone(state);state.signal=true;bridge:set(state,false)
check(events[#events].key=='Objective.Signal','signal completion emits on its accepted transition')
state=table.clone(state);state.boss={phase=1};bridge:set(state,false)
state=table.clone(state);state.boss={phase=2};bridge:set(state,false)
check(events[#events].key=='Warden.Phase','Warden phase edge has a separate cue')
bridge:set(state,true);check(states[#states].active==false and next(bridge.actors)==nil,'travel immediately retires map and actor presentation')
before=#events;now+=1;bridge:tick(now);check(#events==before,'blocked lifecycle produces no delayed actor/world cue')
map:Destroy();map=make('Model','DeadSignalMap',ws)
state=table.clone(state);state.runId=8;state.phase='Wave';state.round=1;state.boss=nil;state.signal=false
bridge:set(state,false)
check(states[#states].runId=='8' and next(bridge.actors)==nil,'new run excludes prior-run actor replication')
local activeToken=bridge.token;character:Destroy();player.Character=make('Model','Replacement',ws)
now+=.2;bridge:tick(now);check(bridge.token~=activeToken,'character replacement creates a new presentation epoch')
-- Consume the real remastered semantic producers on all three maps.
local build=loader.new(dm)(f.server.MapBuilder).build
for mapIndex,id in ipairs({'Station','Foundry','Frost'}) do
 local built=build(id)
 state={runId=20+mapIndex,map=id,participating=true,status='Alive',phase='Wave',round=6}
 local listener=make('Part','HumanoidRootPart',player.Character)
 for index,room in ipairs(built.rooms) do
  position(listener,room.center+r.Vector3.new(0,3,0));now+=1.1;bridge:set(state,false)
  check(states[#states].room==id..'_sector_'..index,id..' actual source sector metadata matches listener')
  if room.upperCenter then
   position(listener,room.upperCenter+r.Vector3.new(0,3,0));now+=.2;bridge:tick(now)
   check(states[#states].room==id..'_upper_'..index,id..' actual service-walk regions are complete and prioritized')
  end
 end
 built.model:Destroy();listener:Destroy()
end
bridge:destroy();check(bridge.destroyed and next(bridge.actors)==nil,'owner teardown clears adapter state')
print('Batch 1 integration assertions passed:',count)
