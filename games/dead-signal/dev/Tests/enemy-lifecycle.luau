-- Runs actual enemy decisions with controlled rigs/spatial services, never engine physics.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local V=r.Vector3 local CF=r.CFrame local now=100 local events={} local hits={} local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local function place(root,pos) root.Position=pos;root.CFrame=CF.new(pos) end
local testOs=table.clone(os);testOs.clock=function() return now end
local routeClear=true local entry=nil
local nav={invalidate=function(e) e.invalidated=(e.invalidated or 0)+1 end,rootHeight=function() return 3 end,
 traversalTuning={planInterval=.8},entryPlan=function() return entry and {} or nil end,contextPlan=function() return nil end,
 goal=function(_,_,target) return target end,clearRoute=function() return routeClear end,
 floor=function(_,pos) return V.new(pos.X,0,pos.Z) end,entryPoint=function() return entry end,
 move=function(_,e,target,time) e.hum:MoveTo(target);e.lastMoved=time end}
local rigs={build=function(parent,kind,pos,id)
 local model=r.Instance.new('Model');model.Name=kind..id;model.Parent=parent
 local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=model;place(root,pos);model.PrimaryPart=root
 local fields={MaxHealth=100,Health=100,HipHeight=0,Died={Connect=function() end},SetStateEnabled=function() end,
  MoveTo=function(self,pos) self.destination=pos end}
 -- Enforce the Health/MaxHealth property boundary in this controlled rig.
 local hum=setmetatable({},{__index=fields,__newindex=function(_,key,value)
  fields[key]=key=='Health' and math.clamp(value,0,fields.MaxHealth) or value
 end})
 return model,root,hum
end,evolve=function(e) if e.mods.Armored then e.armorParts={Head=true,Body=true} end end,
 breakArmor=function(e,zone) e.armorParts[zone]=nil;e.model:SetAttribute(zone..'ArmorBroken',true) end,
 corpse=function(model,parent) model.Parent=parent end}
local world={GetServerTimeNow=function() return now end,Raycast=function() return nil end}
local load=loader.new(dm,{modules={Navigation=nav,EnemyRigs=rigs},globals={workspace=world,os=testOs,
 RaycastParams={new=function() return {} end}}})
local E=load(f.server.Enemies) local C=load(f.shared.Config) local D=load(f.shared.DirectorRules) local R=load(f.shared.Rules)
local T=C.Evolution
local function player(id,pos)
 local character=r.Instance.new('Model');local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=character;place(root,pos)
 return {Parent=true,UserId=id,Character=character},root
end
local function state() return {participating=true,status='Alive',perks={},health=100,guns={},stats={kills=0,headshots=0}} end
local function setup()
 local p1,root1=player(1,V.new(0,3,-10));local p2,root2=player(2,V.new(8,3,-10))
 local window={inside=V.new(0,3,0),outside=V.new(0,3,-20),count=0,nextTear=0,boards={},part={Position=V.zero}}
 local ctx={players={[p1]=state(),[p2]=state()},map={scale=1,model=r.Instance.new('Model')},
  run={id=1,round=25,mode='Standard',phase='Wave'},feed={FireAllClients=function(_,kind,data) events[#events+1]={kind=kind,data=data} end},
  combat={hurt=function(_,p,damage) hits[#hits+1]={player=p,damage=damage} end},game={aliveCount=function() return 2 end,drop=function() end}}
 local e=setmetatable({ctx=ctx,list={},nextId=0,folder=r.Instance.new('Folder'),corpses=r.Instance.new('Folder'),
  hazards={},hazardId=0,targetLoads={},pathTokens=4,pathBudgetAt=now,recovered=0},E)
 ctx.enemies=e;events={};hits={};entry=nil;routeClear=true
 local function spawn(kind,mods,entered)
  local position=V.new(0,3,0);if entered==false then position=nil end
  return e:spawn(kind,window,position,mods)
 end
 return e,ctx,p1,root1,p2,root2,spawn,window
end
local function prime(e,who,p1)
 who.target=p1;who.targetRoot=p1.Character.HumanoidRootPart;who.targetAt=now+100
 who.windup=now+.1;who.windupTarget=p1;who.chargeAt=now+.2;who.chargeUntil=now+1;who.chargeGoal=V.zero
 who.ambushAt=now+.2;who.ambushUntil=now+2;who.cover=V.zero;who.flankGoal=V.zero
 who.nextCharge=now+6;who.nextAmbush=now+11
 who.model:SetAttribute('ChargeUntil',now+1);who.model:SetAttribute('AmbushAt',now+.2)
end
for name,change in pairs({down=function(ctx,p) ctx.players[p].status='Down' end,
 dead=function(ctx,p) ctx.players[p].status='Eliminated' end,
 spectator=function(ctx,p) ctx.players[p].participating=false end,
 travelling=function(ctx,p) ctx.players[p].travelling=true end,
 disconnect=function(_,p) p.Parent=false end,
 missingCharacter=function(_,p) p.Character=nil end}) do
 local e,ctx,p1,_,p2,_,spawn=setup();local who=spawn('Stalker');prime(e,who,p1);change(ctx,p1)
 check(e:target(who,now)==p2,name..' immediately rejects cached target')
 check(not who.windup and not who.windupTarget and not who.chargeAt and not who.chargeUntil and not who.chargeGoal,name..' cancels pending attacks/charge')
 check(not who.ambushAt and not who.ambushUntil and not who.cover and not who.flankGoal,name..' cannot transfer ambush/flank preparation')
 check(who.nextCharge==now+6 and who.nextAmbush==now+11,name..' preserves ability cooldowns')
 check(who.model:GetAttribute('ChargeUntil')==0 and who.model:GetAttribute('AmbushAt')==0,name..' clears replicated pose timers')
 local _,hold,allow=e:behavior(who,p2.Character.HumanoidRootPart,now,10)
 check(not allow and not who.ambushAt and not hold,name..' new target waits for a fresh ambush warning')
end
do
 local e,ctx,p1,_,p2,_,spawn=setup();local who=spawn('Hound');prime(e,who,p1)
 local _,replacement=player(3,V.new(0,3,-10));replacement.Parent=p1.Character
 p1.Character:FindFirstChild('HumanoidRootPart'):Destroy();replacement.Name='HumanoidRootPart'
 ctx.players[p2].participating=false
 check(e:target(who,now)==p1 and not who.chargeUntil and not who.windup,'same player with a replacement character cannot inherit attacks')
 prime(e,who,p1);e:stun(who,1)
 check(not who.ambushAt and not who.ambushUntil and not who.chargeGoal and not who.cover,'stun cancels all committed special actions')
 check(who.model:GetAttribute('ChargeUntil')==0,'stun clears charge pose immediately')
end
do
 local e,ctx,p1,root1,p2,_,spawn=setup();ctx.players[p2].participating=false
 local who=spawn('Stalker');e:target(who,now);place(root1,V.new(0,3,-3))
 who.ambushUntil=now-.01;who.nextAmbush=now+10;who.windup=now-.01;who.windupTarget=p1
 e:tick(now);check(#hits==0 and not who.windup,'strike cannot finish after the Stalker ambush window expires')
 who.hum:MoveTo(V.new(50,3,0));who.windup=now+.1;who.windupTarget=p1;ctx.players[p1].travelling=true
 e:tick(now+.01)
 check(who.hum.destination==who.root.Position and not who.windup,'no valid target stops movement and cancels pending hits')
end
do
 local e,ctx,p1,root1,p2,_,spawn=setup();local boss=spawn('Warden');boss.shockAt=now-.1;boss.shock=now-1
 boss.shockPosition=boss.root.Position;boss.model:SetAttribute('Charging',true)
 ctx.players[p1].status='Down';ctx.players[p2].travelling=true;e:tick(now)
 check(not boss.shockAt and not boss.model:GetAttribute('Charging'),'no living target cancels a suspended Warden shock warning')
 ctx.players[p1].status='Alive';place(root1,V.new(0,3,-10));e:tick(now+.1)
 check(#hits==0 and boss.shockAt and boss.shockAt>now+.1,'revived target gets a fresh Warden shock warning, never an expired blast')
end
do
 local e,ctx,p1,root1,p2,_,spawn=setup();local who=spawn('Hound');who.packRole='Flanker'
 local first=e:behavior(who,root1,now,10)
 place(root1,V.new(2,3,-10));root1.CFrame=CF.lookAt(root1.Position,root1.Position+V.new(1,0,0))
 local locked=e:behavior(who,root1,now+.1,10)
 check(first==locked,'flank approach is fixed while a survivor turns/moves')
 now+=2;who.lastMoved=now;local direct=e:behavior(who,root1,now,10)
 check(direct==root1.Position and not who.flankGoal,'flank has a bounded duration then closes on target')
 check(e:behavior(who,root1,now+.1,10)==root1.Position,'flank cannot restart every tick and circle forever')
 who.nextFlank=0;who.lastMoved=now;routeClear=true;e:behavior(who,root1,now+.2,10);routeClear=false
 check(e:behavior(who,root1,now+.3,10)==root1.Position and not who.flankGoal,'obstructed flank immediately returns to native pursuit')
 routeClear=true;who.packRole='Charger';who.nextCharge=0;who.flankGoal=nil
 local _,hold,allow=e:behavior(who,root1,now,12)
 check(hold and not allow,'charge always starts with a stationary warning')
 local goal=who.chargeGoal;place(root1,V.new(12,3,-10));now+=T.pack.chargeWarning+.01
 check(e:behavior(who,root1,now,16)==goal,'charge endpoint remains the announced location')
 routeClear=false;_,hold,allow=e:behavior(who,root1,now+.1,16)
 check(not who.chargeUntil and hold and not allow,'blocked charge pays its recovery instead of immediately attacking')
 routeClear=true
end
do
 local e,ctx,p1,root1,_,_,spawn=setup();local stalker=spawn('Stalker')
 e.clearSight=function() return false end
 local dest,hold,allow=e:behavior(stalker,root1,now,20)
 check(stalker.cover==dest and dest~=root1.Position and not hold and not allow,'Stalker selects a clear approach hidden from its target')
 stalker.lastMoved=now-2;dest=e:behavior(stalker,root1,now+.1,20)
 check(dest==root1.Position,'Stalker abandons stalled cover and resumes pursuit')
 stalker.coverAt=0;stalker.cover=nil;routeClear=false;stalker.lastMoved=now
 dest=e:behavior(stalker,root1,now+.2,20)
 check(dest==root1.Position and not stalker.cover,'no available cover never strands the Stalker')
 routeClear=true
 local flanker=spawn('Hound');flanker.packRole='Flanker';flanker.packLeader={dead=true,target=p1}
 e:behavior(flanker,root1,now,10)
 check(flanker.hum.WalkSpeed==flanker.baseSpeed,'dead Alpha cannot buff a cached follower before the next coordination tick')
end
do
 local e,ctx,p1,_,p2,_,spawn,window=setup();local who=spawn('Shambler',{},false)
 check(not who.entered,'entry recovery fixture starts outside')
 who.lastMoved=now-17;e:tick(now)
 check(who.dead and e.recovered==1 and e:count()==1,'blocked breach slot relocates instead of holding a wave forever')
 check(window.entryBlockedUntil.Shambler==now+8,'failed exterior route temporarily excludes that window for the same species')
 for attempt=2,3 do
  local nextEnemy=next(e.list) and select(2,next(e.list));nextEnemy.lastMoved=now-17;e:tick(now)
 end
 check(e:count()==0 and e.retired==1 and #e.hazards==0,'repeated impossible entry retires without a blast/drop/reward')
 local tearing=spawn('Shambler',{},false);window.count=1;window.boards={r.Instance.new('Part')};window.nextTear=now-1
 tearing.lastMoved=now-15;e:tick(now)
 check(not tearing.dead and tearing.lastMoved==now,'tearing a board counts as legitimate entry progress')
 window.count=0;entry=V.new(0,3,0);local began=false
 e.startTraversal=function() began=true end;e:tick(now+.5)
 check(began and not tearing.entered,'free slot starts traversal while the enemy remains outside until landing')
end
do
 local e,ctx,_,_,_,_,spawn,window=setup()
 ctx.director={stats=function() return {hp=1000,speed=10,damage=25} end,window=function() return window end}
 local who=spawn('Shambler',{Armored=true,Enraged=true})
 who.armor.Head=0;who.armor.Body=17;who.hp=73;who.reactor=9;who.hitRewards={test=true}
 ctx.director.stats=function() return {hp=20,speed=10,damage=25} end
 who.nextCharge=now+3;who.nextAmbush=now+7;e:recover(who)
 local replacement=select(2,next(e.list))
 check(replacement.hp==73 and replacement.hum.Health==73 and replacement.maxHP==who.maxHP and replacement.hum.MaxHealth==who.maxHP,'crew reduction during recovery preserves exact engine health/max health')
 check(replacement.armor.Head==0 and replacement.armor.Body==17 and not replacement.armorParts.Head,'recovery preserves broken and partially damaged armor')
 check(replacement.reactor==9 and replacement.hitRewards==who.hitRewards,'recovery preserves weakpoint and hit reward accounting')
 check(replacement.nextCharge==who.nextCharge and replacement.nextAmbush==who.nextAmbush,'recovery cannot reset special cooldowns')
end
do
 local e,ctx,p1,root1,p2,root2,spawn=setup();local who=spawn('Hound')
 place(root1,V.new(0,3,1));place(root2,V.new(0,3,-1))
 e:queueBlast(who,p1);ctx.players[p1].travelling=true;p2.Parent=false
 now=e.hazards[1].at+.01;e:tickHazards(now)
 check(#hits==0,'blast and flame cannot hurt travelling or disconnected operators')
 e:clearHazards();check(#e.hazards==0 and events[#events].kind=='HazardClear','clear removes warnings and all server hazards')
end
do
 local cfg=table.clone(T);cfg.events={}
 check(D.event(5,'Wave',cfg,false)==nil,'empty configurable event rotation safely disables special waves')
 -- Reconcile a special quota through a down, settled disconnect and revive.
 local e,ctx,p1,_,p2=setup();local Director=load(f.server.WaveDirector);local d=Director.new(ctx)
 ctx.director=d;ctx.run.event=T.events[1];d:begin(now);d:budget(now)
 local total=ctx.run.spawnRemaining;for _=1,5 do d:spawnedOne() end
 ctx.players[p2].status='Down';d:budget(now+1)
 check(ctx.run.spawnRemaining==total-5,'special wave down does not duplicate committed spawn quota')
 p2.Parent=false;d:budget(now+8)
 check(ctx.run.spawnRemaining==math.max(0,D.specialQuota(R.waveCount(25,1,C.Modes.Standard),T.events[1])-5),'special quota settles to remaining crew')
 p2.Parent=true;ctx.players[p2].status='Alive';d:budget(now+9)
 check(ctx.run.spawnRemaining==total-5,'revive restores only the unspent special quota')
 ctx.run.phase='Exfil';ctx.run.spawnRemaining=7;d:budget(now+10)
 check(ctx.run.spawnRemaining==7,'extraction escorts never inherit adaptive special-wave reconciliation')
end
print('Enemy lifecycle regression assertions passed:',count)
