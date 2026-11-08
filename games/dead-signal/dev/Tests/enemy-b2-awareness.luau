-- Actual R6/server/Diagnostics modules with controlled services; native review pending.
local H=require('./Support/InfectedHarness');local r=H.roblox;local V=r.Vector3
local loader=require('./Support/RuntimeLoader');local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local function setup()
 local h=H.new();local e=h:enemy('Shambler',{},nil,true);local p,tr=h:player(1,e.root.Position+V.new(8,0,-8))
 h.enemies.clearSight=function() return true end
 return h,e,p,tr
end
for _,reason in ipairs({'wall','far','down','travelling','entry','stunned','attack','hound'}) do
 local h,e,p,tr=setup()
 if reason=='wall' then h.enemies.clearSight=function() return false end
 elseif reason=='far' then tr.Position=e.root.Position+V.new(90,0,0)
 elseif reason=='down' then h.ctx.players[p].status='Down'
 elseif reason=='travelling' then h.ctx.players[p].travelling=true
 elseif reason=='entry' then e.entered=false
 elseif reason=='stunned' then e.stunnedUntil=h.time+2
 elseif reason=='attack' then e.windup=h.time+.4
 elseif reason=='hound' then e.model:SetAttribute('PresentationRig','Canine') end
 h.enemies:awareness(e,p,tr,h.time)
 check(not e.model:GetAttribute('AwarenessAt') and #h.events==0,'no false awareness for '..reason)
end
do
 local h,e,p,tr=setup();local original=e.root.CFrame;local hp=e.hp
 h.enemies:awareness(e,p,tr,h.time)
 local event=h.events[1]
 check(event and event.kind=='EnemyAwareness' and event.data.runId==1 and event.data.id==e.id,'genuine detection uses the existing server feed')
 check(event.data.sourceId=='enemy:1:1' and event.data.token=='awareness:1:1:1','run/source/sequence permit AUDIO deduplication')
 check(math.abs(e.model:GetAttribute('AwarenessYaw'))<=.55 and math.abs(e.model:GetAttribute('AwarenessPitch'))<=.15,'bounded look angles')
 check(e.root.CFrame==original and e.hp==hp and not e.windup and not e.root.Anchored,'awareness changes no movement, health, attack or physics authority')
 for i=1,100 do h.time+=.1;h.enemies:awareness(e,p,tr,h.time) end
 check(#h.events==1,'a continuing visible target never repeats growls/gestures')
 local otherPlayer,other=h:player(2,e.root.Position+V.new(-8,0,-8));h.time=111;h.enemies:awareness(e,otherPlayer,other,h.time)
 check(#h.events==1,'target changes cannot bypass per-enemy cooldown')
 h.time=115;h.enemies:awareness(e,otherPlayer,other,h.time)
 check(#h.events==2 and h.events[2].data.token=='awareness:1:1:2','a later genuine new acquisition gets a new monotonic event token')
end
do
 local h,e,p,tr=setup();local before=h.Pose.sample(e.model,e.root,h.time+.425)
 h.enemies:awareness(e,p,tr,h.time);local peak=h.Pose.sample(e.model,e.root,h.time+.425)
 check(peak.Neck~=before.Neck and peak.RootJoint~=before.RootJoint,'R6 look affects head and upper body')
 check(peak.RootJoint.Position==before.RootJoint.Position,'subtle torso rotation adds no translation')
 local atStart=h.Pose.sample(e.model,e.root,h.time);local atEnd=h.Pose.sample(e.model,e.root,h.time+.85)
 e.model:SetAttribute('AwarenessAt',nil)
 check(atStart.Neck==h.Pose.sample(e.model,e.root,h.time).Neck,'look begins at the existing pose')
 check(atEnd.Neck==h.Pose.sample(e.model,e.root,h.time+.85).Neck,'look returns to the existing pose')
 for _,mode in ipairs({'vault','hit','attack','stun'}) do
  e.model:SetAttribute('AttackAt',nil);e.model:SetAttribute('HitAt',nil);e.model:SetAttribute('StunnedUntil',nil);e.model:SetAttribute('TraversalStage',nil)
  if mode=='vault' then e.model:SetAttribute('TraversalStage','Cross');e.model:SetAttribute('TraversalStyle','Vault');e.model:SetAttribute('TraversalStageAt',h.time);e.model:SetAttribute('TraversalStageDuration',1)
  elseif mode=='attack' then e.model:SetAttribute('AttackAt',h.time)
  elseif mode=='hit' then e.model:SetAttribute('HitAt',h.time+.3);e.model:SetAttribute('HitVector',V.xAxis)
  else e.model:SetAttribute('StunnedUntil',h.time+2) end
  local plain=h.Pose.sample(e.model,e.root,h.time+.425);e.model:SetAttribute('AwarenessAt',h.time)
  local aware=h.Pose.sample(e.model,e.root,h.time+.425)
  check(plain.Neck==aware.Neck and plain.RootJoint==aware.RootJoint,'priority pose is retained during '..mode)
  e.model:SetAttribute('AwarenessAt',nil)
 end
end
do
 local h=H.new();h.enemies.clearSight=function() return true end;local p,tr=h:player(1,V.new(8,3,-12))
 for i=1,40 do local e=h:enemy('Runner',{},nil,true);h.enemies:awareness(e,p,tr,h.time) end
 check(#h.events==2,'forty simultaneous acquisitions consume at most the two initial presentation tokens')
 local original=0;for _,e in pairs(h.enemies.list) do if e.model:GetAttribute('AwarenessAt') then original+=1 end end
 check(original==2 and h.enemies:count()==40,'presentation cap preserves all forty live wave units')
end
do
 local h,e=setup();check(not h.N.snapshot(h.enemies,h.time).enabled,'normal gameplay diagnostics are disabled')
 h.N.trace(h.enemies,e,'test','discarded',h.time);check(not h.enemies.navigationDebug,'disabled trace allocates no ring')
 local studio=false;local clock=table.clone(os);clock.clock=function() return h.time end
 local fs=require('@lune/fs');local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
 local load=loader.new(dm,{services={RunService={IsStudio=function() return studio end}},globals={os=clock}})
 local D=load(f.server.Diagnostics);D.init(h.ctx)
 check(not pcall(function() D.navigation(true) end) and not h.enemies.navigationDebug,'production cannot enable QA diagnostics')
 studio=true;local snapshot=D.navigation(true);check(snapshot.enabled and #snapshot.actors==1,'Studio explicitly enables snapshots')
 for i=1,500 do h.N.trace(h.enemies,e,'probe','bounded',h.time+i*.01) end
 snapshot=D.navigation();check(#snapshot.events==128 and snapshot.counters.probe==500,'trace history has a fixed 128-event bound')
 check(snapshot.actors[1].id==e.id and snapshot.actors[1].secondsWithoutMovement==0,'snapshot includes actual actor/progress')
 check(not D.navigation(false).enabled and not h.enemies.navigationDebug,'disabling diagnostics releases trace storage')
end
print('Batch 2 awareness/diagnostic assertions passed:',count)
