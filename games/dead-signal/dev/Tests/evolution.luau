-- Executes real v1.9 modules with controlled spatial services; not engine physics.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local V=r.Vector3 local CF=r.CFrame local now=100 local blocked=false local routeBlocked=false
local events={} local hurts={} local points=0 local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local map={model=r.Instance.new('Model'),floorParts={r.Instance.new('Part')},scale=1,rooms={{unlocked=true}}}
local world={GetServerTimeNow=function() return now end,Blockcast=function() return routeBlocked and {} or nil end,
 Raycast=function(_,pos,delta,params)
  if params.FilterDescendantsInstances[1]==map.model then return blocked and {Position=pos+delta*.5} or nil end
  return {Position=V.new(pos.X,0,pos.Z)}
 end}
local testOs=table.clone(os);testOs.clock=function() return now end
local load=loader.new(dm,{globals={workspace=world,os=testOs,RaycastParams={new=function() return {} end}},services={Debris={AddItem=function() end}}})
local D=load(f.shared.DirectorRules) local C=load(f.shared.Config) local R=load(f.shared.Rules) local T=C.Evolution
local E=load(f.server.Enemies) local Rigs=load(f.server.EnemyRigs) local N=load(f.server.Navigation)
local function player(id,pos)
 local char=r.Instance.new('Model');local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.CFrame=CF.new(pos);root.Position=pos;root.Parent=char
 return {Parent=true,UserId=id,Character=char},root
end
local p1,pr1=player(1,V.new(0,3,-3));local p2,pr2=player(2,V.new(0,3,-5))
local function state() return {participating=true,status='Alive',perks={},health=100,stats={kills=0,headshots=0},guns={},points=0} end
local ctx={players={[p1]=state(),[p2]=state()},map=map,run={id=1,round=15,phase='Wave',mode='Standard',effects={}},
 feed={FireAllClients=function(_,kind,data) events[#events+1]={kind=kind,data=data,time=now} end,FireClient=function() end},
 combat={hurt=function(_,player,damage) hurts[#hurts+1]={player=player,damage=damage} end},
 game={addPoints=function(_,_,value) points+=value end,drop=function() end}}
local parent=r.Instance.new('Folder');local corpses=r.Instance.new('Folder')
local e=setmetatable({ctx=ctx,list={},hazards={},corpses=corpses,folder=parent,targetLoads={}},E);ctx.enemies=e
local serial=0
local function enemy(kind,mods,hp,pos)
 serial+=1;local m,root,hum=Rigs.build(parent,kind,pos or V.new(0,kind=='Hound' and 1.66 or 3.08,0),serial);root.AssemblyLinearVelocity=V.zero
 local who={id=serial,kind=kind,model=m,root=root,hum=hum,hp=hp or 1000,maxHP=hp or 1000,mods=mods or {},baseSpeed=10,damage=25,
  lastMoved=now,lastPosition=root.Position,runId=ctx.run.id,packRole='Charger',attack=0,window={}}
 hum.MaxHealth=who.maxHP;hum.Health=who.hp
 who.armor=who.mods.Armored and {Body=who.maxHP*T.armored.plateHealth,Head=who.maxHP*T.armored.plateHealth} or nil
 who.reactor=who.mods.Volatile and who.maxHP*T.volatile.reactorHealth or nil
 Rigs.evolve(who);e.list[who.id]=who;return who
end
local seen={}
for round=1,250 do
 local event=D.event(round,'Wave',T,R.isWardenRound(round))
 check(not event or round>=T.firstRound and (round-T.firstRound)%T.interval==0,'configured wave cadence')
 check(not R.isWardenRound(round) or not event,'boss wave takes precedence')
 check(D.event(round,'Exfil',T,false)==nil,'extraction has no event overlay')
 if event then seen[event.id]=true end
end
for _,event in ipairs(T.events) do check(seen[event.id],'all five events reachable') end
local cfg=table.clone(T);cfg.enabled=false
check(D.event(5,'Wave',cfg,false)==nil,'feature switch suppresses scheduling')
local disabled,disabledMods=D.evolution(50,T.events[1],1,cfg,0,0,{})
check(disabled=='Shambler' and next(disabledMods)==nil,'feature switch suppresses enemies')
cfg=table.clone(T);cfg.interval=4;check(D.event(9,'Wave',cfg,false)~=nil,'configurable interval')
local previous=0
for round=1,150 do local rate=D.eliteRate(round,T);check(rate>=previous and rate<=T.eliteMax,'elite rate grows to ceiling');previous=rate end
for _,event in ipairs(T.events) do
 local counts={stalkers=0,alphas=0,combined=0}
 for i=1,80 do
  local kind,mods=D.evolution(25,event,i,T,.5,0,counts)
  if kind=='Stalker' then counts.stalkers+=1 end
  if mods.Alpha then counts.alphas+=1 end
  if mods.Armored and mods.Enraged then counts.combined+=1 end
  local n=0;for _,yes in pairs(mods) do if yes then n+=1 end end
  check(n<=2,'no triple modifiers');check(not mods.Alpha or kind=='Hound','alpha is canine only');check(kind~='Warden','no extra Warden')
 end
 check(counts.stalkers<=T.maxStalkers and counts.alphas<=T.maxAlphas and counts.combined<=T.maxCombined,'per-wave rarity caps')
 check(D.specialQuota(40,event)<40 and D.specialQuota(1,event)>=6,'bounded special quota')
end
local _,combo=D.evolution(17,T.events[3],1,T,0,0,{});check(not combo.Enraged,'late-round combined gate')
local _,rare=D.evolution(25,T.events[3],1,T,0,.5,{});check(not rare.Enraged,'ordinary roll has no Ironbound')
local normal=D.modifiers({hp=100,speed=10,damage=20},{},T);check(normal.hp==100 and normal.speed==10 and normal.damage==20,'ordinary stats preserved')
check(D.modifiers({hp=100000,speed=100,damage=1000},{Armored=true,Enraged=true},T).damage<=65,'combined damage capped')
for round=1,150 do check(D.blastDamage(round,T.volatileBlast,C.Modes.Standard)<=T.volatileBlast.maxDamage,'blast scaling capped') end
check(D.specialReward(1000,T.rewards)==T.rewards.maxPoints,'reward capped')
check(D.canReward({phase='Wave',event=T.events[1],spawnRemaining=0}) and not D.canReward({phase='Wave',event=T.events[1],spawnRemaining=0,eventRewarded=true}),'reward once')
for _,spec in ipairs({{'Shambler',{Enraged=true}},{'Runner',{Armored=true}},{'Crawler',{Volatile=true}},{'Crawler',{Armored=true}},{'Crawler',{Enraged=true}},
 {'Shambler',{Armored=true,Enraged=true}},{'Hound',{Alpha=true}},{'Hound',{}},{'Stalker',{}}}) do
 local who=enemy(spec[1],spec[2]);local m=who.model
 check(m:GetAttribute('EvolutionRevision')==9 and m.BodyCollider.CanCollide,'variant keeps live collision')
 check(N.agent(who).AgentRadius>=math.max(m.BodyCollider.Size.X,m.BodyCollider.Size.Z)*.5+.1,'scaled agent covers collider')
 local clearance=who.root.Size.Y*.5+m['Left Leg'].Size.Y+who.hum.HipHeight
 check(math.abs(N.rootHeight(who)-clearance)<.001,'scaled root clearance')
 for _,part in ipairs(m:GetChildren()) do if part:IsA('BasePart') and part.Name~='BodyCollider' then check(not part.CanCollide,'detail cannot snag') end end
 if spec[2].Armored then check(who.armorParts.Head.CanQuery and not who.weakParts.Head.CanQuery,'armor shields seam') end
 if spec[2].Volatile then check(#who.reactorParts==4,'visible canisters and core') end
 if spec[2].Alpha then check(m:FindFirstChild('AlphaAntler') and m:GetAttribute('EnemyTitle')=='Alpha Hound','alpha silhouette') end
 if spec[1]=='Stalker' then check(m:FindFirstChild('SplitCowl') and m:FindFirstChild('SignalWhisker'),'stalker silhouette') end
 local reopened=r.deserializeModel(r.serializeModel({m}))[1];check(reopened:GetAttribute('EvolutionRevision')==9,'variant native serialization')
 Rigs.corpse(m,corpses);check(m:GetAttribute('Ragdoll') and not m.BodyCollider.CanCollide,'all variants ragdoll');e.list[who.id]=nil
end
local armored=enemy('Shambler',{Armored=true});local plate=armored.armorParts.Body
local before=armored.hp;e:damage(armored,100,p1,false,'a','Bullet',plate)
check(armored.hp==before-28 and armored.armor.Body<320,'plate resists and takes damage')
e:damage(armored,300,p1,false,'b','Bullet',plate)
check(armored.armor.Body==0 and armored.armorParts.Body==nil and armored.weakParts.Body.CanQuery,'break exposes seam')
check(armored.stunnedUntil>now and armored.model:GetAttribute('BodyArmorBroken'),'break interrupts attack')
before=armored.hp;e:damage(armored,40,p1,false,'c','Bullet',armored.weakParts.Body)
check(armored.hp==before-50,'exposed seam bonus');check(armored.armor.Head==320,'helmet independent')
armored.windup=now+.1;armored.windupTarget=p1;e:stun(armored,1);check(not armored.windup and not armored.windupTarget,'stun cancels pending strike')
local enraged=enemy('Runner',{Enraged=true});e:damage(enraged,130,p1,true,'p','Bullet',enraged.model.Head);check(enraged.stunnedUntil>now,'precision interrupt')
local firstStun=enraged.stunnedUntil;now+=.1;e:damage(enraged,130,p1,true,'p2','Bullet',enraged.model.Head);check(enraged.stunnedUntil==firstStun,'precision cooldown')
e.list={};e:clearHazards();events={};hurts={};points=0
local volatile=enemy('Shambler',{Volatile=true},100);e:damage(volatile,30,p1,false,'r','Bullet',volatile.reactorParts[1])
check(volatile.dead and e:pendingBlasts()==1,'reactor triggers delayed blast');check(#hurts==0 and events[1].kind=='HazardWarning','warning before all damage')
local killPoints=points;e:kill(volatile,p1,true,true);check(points==killPoints,'no duplicate kill rewards')
local warning=e.hazards[1];now=warning.at-.01;e:tickHazards(now);check(#hurts==0,'no early damage')
local chain=enemy('Hound',{},10,V.new(1,1.66,0));now=warning.at+.01;e:tickHazards(now)
check(#hurts>0 and chain.dead,'blast affects exposed players and enemies');check(e:pendingBlasts()==1,'chain has fresh warning')
local last=e.hazards[#e.hazards];check(last.at>=now+T.houndBlast.warning-.001,'full chain avoidance window')
local n=#hurts;blocked=true;now=last.at+.01;e:tickHazards(now);check(#hurts==n,'walls block explosion and fire');blocked=false
e:clearHazards();e.list={};local hound=enemy('Hound',{},100);e:queueBlast(hound,p1)
e:counter('Vent',V.zero,now);e:counter('Sprinkler',V.zero,now)
check(e.hazards[1].smokeCleared and e.hazards[1].fireSuppressed,'counter clears current hazard')
e:queueBlast(hound,p1);e:tickHazards(now+.01);check(e.hazards[2].smokeCleared and e.hazards[2].fireSuppressed,'counter clears subsequent hazard')
for _=1,20 do e:queueBlast(hound,p1) end
check(#e.hazards==T.hazards.maxActive,'bounded server hazard work');ctx.run.id+=1;e:tickHazards(now+.1);check(#e.hazards==0,'no cross-run hazards')
e.list={};map.counterFields={};now=200
local charger=enemy('Hound',{},100,V.new(0,1.66,0));charger.packRole='Charger';pr1.Position=V.new(0,3,-12);pr1.CFrame=CF.new(pr1.Position)
local dest,hold,allow=e:behavior(charger,pr1,now,12);check(hold and not allow and charger.chargeAt,'stationary charge warning')
local locked=charger.chargeGoal;pr1.Position=V.new(8,3,-12);pr1.CFrame=CF.new(pr1.Position);now+=T.pack.chargeWarning+.01
dest,hold,allow=e:behavior(charger,pr1,now,14);check(dest==locked and not hold and charger.hum.WalkSpeed==T.pack.chargeSpeed,'charge commits to warned location')
check(math.abs(dest.Y-1.66)<.001,'canine charge floor clearance')
routeBlocked=true;dest=e:behavior(charger,pr1,now+.1,14);check(not charger.chargeUntil and dest.X==pr1.Position.X,'blocked charge returns to pursuit');routeBlocked=false
local flanker=enemy('Hound',{},100,V.new(0,1.66,0));flanker.packRole='Flanker';dest=e:behavior(flanker,pr1,now,15);check(dest.X~=pr1.Position.X or dest.Z~=pr1.Position.Z,'separate flank')
flanker.lastMoved=now-2;dest=e:behavior(flanker,pr1,now,15);check(dest.X==pr1.Position.X and dest.Z==pr1.Position.Z,'stalled flank abandons offset')
local alpha=enemy('Hound',{Alpha=true},100,V.new(1,1.9256,0));alpha.target=p1;e:coordinate(now);check(flanker.packLeader==alpha and flanker.model:GetAttribute('PackLeader')==alpha.id,'alpha coordinates pack')
local stalker=enemy('Stalker',{},100,V.new(0,3.08,0));pr1.Position=V.new(0,3,-10);pr1.CFrame=CF.new(pr1.Position)
dest,hold,allow=e:behavior(stalker,pr1,now,10);check(hold and not allow and stalker.ambushAt,'stalker warning')
now+=T.stalker.warning+.01;dest,hold,allow=e:behavior(stalker,pr1,now,10);check(allow and stalker.hum.WalkSpeed==T.stalker.speed,'bounded ambush window')
now+=T.stalker.ambushSeconds+.01;dest,hold,allow=e:behavior(stalker,pr1,now,10);check(not allow and not stalker.ambushAt,'ambush cooldown')
pr2.Position=V.new(2,3,-10);pr1.Position=V.new(0,3,-10)
local p3,pr3=player(3,V.new(35,3,0));ctx.players[p3]=state();stalker.root.Position=V.new(20,3.08,0);stalker.target=nil;stalker.targetAt=0
check(e:target(stalker,now)==p3,'isolated target priority');ctx.players[p3].status='Down';check(e:target(stalker,now+.01)~=p3,'downed target rejected')
local actualLoad=loader.new(dm);local M=actualLoad(f.server.MapBuilder)
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local actual=M.build(id);check(#actual.counters==2,id..' both counters exist')
 for _,counter in ipairs(actual.counters) do
  check(not counter.part.CanCollide,id..' counter cannot obstruct movement')
  local overlap=0
  for _,z in ipairs(actual.interactionZones) do local p=counter.part.Position
   if p.X>=z.minX and p.X<=z.maxX and p.Z>=z.minZ and p.Z<=z.maxZ then overlap+=1 end
  end
  check(overlap==1,id..' counter only overlaps own reservation')
 end
end
print('Evolution integration assertions passed:',count)
