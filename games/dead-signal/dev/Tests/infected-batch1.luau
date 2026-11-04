local harness=require('./Support/InfectedHarness');local r=harness.roblox;local V=r.Vector3;local CF=r.CFrame
local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local h=harness.new();local A=h.load(harness.folders.server.RigAnatomy);local Wardrobe=h.load(harness.folders.server.InfectedWardrobe)
local function hitboxes(model)
 local out={};for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p:GetAttribute('AuthoritativeHitbox') then
  out[p.Name]={size=p.Size,cf=p.CFrame,zone=p:GetAttribute('HitZone'),query=p.CanQuery}
 end end;return out
end
local parent=r.Instance.new('Folder')
for _,map in ipairs({'Station','Foundry','Frost'}) do
 local families={};local stages={}
 for id=1,18 do
  local model=h.Rigs.build(parent,'Shambler',V.zero,id,map)
  families[model:GetAttribute('OutfitName')]=true;stages[model:GetAttribute('InfectionStage')]=true
  check(model:GetAttribute('MilitaryOrigin')==Wardrobe.themes[map].name,'map-specific outbreak origin')
  check(model:GetAttribute('MilitaryDetailCount')<=Wardrobe.maxParts,'bounded uniform detail')
  local old=#model:GetDescendants();Wardrobe.apply(model,id,1,map,'Shambler')
  check(#model:GetDescendants()==old,'uniform application is idempotent')
  for _,p in ipairs(model:GetDescendants()) do if p:GetAttribute('MilitaryDetail') then
   check(p:IsA('BasePart') and not p.CanCollide and not p.CanQuery and p.Massless,'uniform cannot snag or absorb shots')
  end end
  model:Destroy()
 end
 for _,name in ipairs(Wardrobe.types) do check(families[name],map..' '..name..' exists') end
 check(stages[1] and stages[2] and stages[3],'three deterministic wear/infection stages')
 for _,kind in ipairs({'Shambler','Runner','Crawler','Hound','Stalker','Warden'}) do
  local before=kind=='Hound' and A.build(parent,kind,V.zero,5) or h.Rigs.base(parent,kind,V.zero,5)
  local model,root,hum=h.Rigs.build(parent,kind,V.zero,5,map)
  local baseline=hitboxes(before);local current=hitboxes(model);local total=0
  for name,p in pairs(baseline) do
   total+=1;check(current[name] and current[name].size==p.size and current[name].cf==p.cf and current[name].zone==p.zone and current[name].query==p.query,kind..' authoritative volume retained '..name)
  end
  local actual=0;for _ in pairs(current) do actual+=1 end;check(actual==total,'no duplicate/new damage volumes')
  for _,key in ipairs({'NavigationRadius','NavigationHeight','NavigationRootHeight'}) do check(model:GetAttribute(key)==before:GetAttribute(key),'base navigation envelope retained') end
  if kind=='Hound' then
   check(model:GetAttribute('K9Revision')==1 and model:FindFirstChild('K9Nose') and model:FindFirstChild('K9Mandible'),'recognizable canine muzzle/jaw')
   check(model.Head:FindFirstChild('Jaw') and model.Head:FindFirstChild('Left Ear'),'articulated jaw and ears')
   check(model:GetAttribute('K9DetailCount')<=34,'bounded K9 detail')
  end
  for _,j in ipairs(model:GetDescendants()) do if j:IsA('Motor6D') then
   check(((j.Part0.CFrame*j.C0).Position-(j.Part1.CFrame*j.C1).Position).Magnitude<.001,'new visual joints have coincident rest frames')
  end end
  local reopened=r.deserializeModel(r.serializeModel({model}))[1];check(reopened:GetAttribute(kind=='Hound' and 'K9Revision' or 'MilitaryRevision')==(kind=='Hound' and 1 or 2),'presentation survives native serialization')
  before:Destroy();model:Destroy();reopened:Destroy()
 end
end
do
 local e=h:enemy('Shambler',{Armored=true});local plate=e.armorParts.Head
 local helmet=e.model:FindFirstChild('DamagedHelmet');check(not helmet or helmet.Transparency==1,'decorative helmet cannot hide actual elite armor')
 h.enemies:damage(e,200,nil,true,'plate','Bullet',plate)
 check(e.armor.Head==0 and not e.model:FindFirstChild('DamagedHelmet') and e.weakParts.Head.CanQuery,'helmet break degrades cosmetic equipment and exposes only the intended weak zone')
end
for _,kind in ipairs({'Shambler','Crawler','Hound','Warden'}) do
 local w=harness.new();w:player(1,V.new(15,3,30));local e=w:enemy(kind);local start=e.root.Position
 local plan=w.N.entryPlan(w.enemies,e,e.window);check(plan~=nil,kind..' real window plan')
 check(w.enemies:startTraversal(e,plan,w.time),'start legitimate exterior entry')
 check(e.root.Position==start and not e.entered,'starting entry does not teleport into the room')
 local seen={};local moves=0;local previous=start
 for tick=1,260 do
  w:step(1/30);local delta=(e.root.Position-previous).Magnitude
  check(delta<=w.N.traversalTuning.maxStep+.001,'every visible traversal displacement is bounded')
  if delta>.001 then moves+=1 end
  previous=e.root.Position;seen[e.model:GetAttribute('TraversalStage')]=true
  if e.traversal then check(not e.entered and e.model.BodyCollider.CanCollide and e.root.Anchored and e.model.BodyCollider:FindFirstChildOfClass('WeldConstraint').Part0==e.root,'checked transit retains root-bound live collision and attack gating') end
  if not e.traversal then break end
 end
 check(e.entered and (e.root.Position-plan.landing).Magnitude<.001,'landing precedes pursuit')
 check(not e.root.Anchored and e.model.BodyCollider.CanCollide and e.hum.AutoRotate and not e.hum.PlatformStand,'landing restores locomotion/collision')
 check(seen.Approach and seen.Contact and seen.Cross and seen.Land and seen.Settle and moves>20,'approach/contact/cross/landing are visible phases')
 check(w:activeClocks()==0 and not next(w.enemies.traversals) and not e.window.activeEntry,'completed animation releases clock/reservation')
 local approach,contact,land;local cues={}
 for _,event in ipairs(w.cues) do
  cues[event.cue]=(cues[event.cue] or 0)+1
  if event.cue=='Enemy.Entry.Approach' then approach=event.time
  elseif event.cue=='Enemy.Entry.Contact' then contact=event.time
  elseif event.cue=='Enemy.Entry.Land' then land=event.time;check((event.position-plan.landing).Magnitude<.001,'land cue occurs at physical landing, after descent') end
 end
 check(approach and contact and land and contact>approach and land>contact,'semantic cue timing follows actual state, not delayed timers')
 check(cues['Enemy.Entry.Approach']==1 and cues['Enemy.Entry.Contact']==1 and cues['Enemy.Entry.Land']==1,'cue transitions are emitted once per traversal')
 check(#w.hits==0,'no damage is delivered during traversal')
end
do
 local w=harness.new();w:player(1,V.new(15,3,30));local e=w:enemy('Shambler');local plan=w.N.entryPlan(w.enemies,e,e.window)
 w.enemies:startTraversal(e,plan,w.time);local old=e.root.Position;w:step(1)
 check((e.root.Position-old).Magnitude<=w.N.traversalTuning.maxStep+.001 and not e.entered,'a server hitch cannot skip an entry')
 w.blocked=true;w.blockForward=true
 for _=1,180 do w:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.entered and (e.root.Position-plan.stages[1].a).Magnitude<.001,'new obstruction causes an animated retreat, not a room teleport')
 check(e.entryFailures==1 and not e.window.activeEntry and w:activeClocks()==0,'blocked retry is bounded and releases reservations')
end
for _,change in ipairs({'Down','Disconnect','Travel','Run','Destroy'}) do
 local w=harness.new();local p=w:player(1,V.new(15,3,30));local e=w:enemy('Hound');local plan=w.N.entryPlan(w.enemies,e,e.window)
 w.enemies:startTraversal(e,plan,w.time);for _=1,15 do w:step(1/30) end
 if change=='Down' then w.ctx.players[p].status='Down'
 elseif change=='Disconnect' then p.Parent=false
 elseif change=='Travel' then w.ctx.players[p].travelling=true
 elseif change=='Run' then w.ctx.run.id+=1
 else e.model:Destroy() end
 for _=1,230 do w:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.entered and w:activeClocks()==0,change..' cancels safely without resuming pursuit')
 check(not e.window.activeEntry and #w.hits==0,change..' leaves no reservation or inherited attack')
end
do
 local w=harness.new();local p=w:player(1,V.new(15,3,30));local e=w:enemy('Shambler')
 local plan=w.N.entryPlan(w.enemies,e,e.window);w.enemies:startTraversal(e,plan,w.time)
 w:step(.05);w.ctx.players[p].status='Down'
 for _=1,80 do w:step(1/30) end
 check(e.model:GetAttribute('EntryCue')=='Enemy.Entry.Cancel','abandoned approach closes its source lifecycle immediately')
 local contact,land=false,false
 for _,cue in ipairs(w.cues) do contact=contact or cue.cue=='Enemy.Entry.Contact';land=land or cue.cue=='Enemy.Entry.Land' end
 check(not contact and not land and #w.events==0,'cancelled approach leaves no delayed contact/landing stock cue')
end
do
 local w=harness.new();w:player(1,V.new(15,3,30));local e=w:enemy('Hound')
 local plan=w.N.entryPlan(w.enemies,e,e.window);w.enemies:startTraversal(e,plan,w.time)
 for _=1,100 do w:step(1/30);if e.model:GetAttribute('TraversalStage')=='Contact' then break end end
 e.stunnedUntil=w.time+.15
 for _=1,150 do w:step(1/30);if not e.traversal then break end end
 local contacts=0;for _,cue in ipairs(w.cues) do if cue.cue=='Enemy.Entry.Contact' then contacts+=1 end end
 check(e.entered and contacts==1,'holding and resuming contact does not duplicate semantic cues')
end
do
 local w=harness.new();w:player(1,V.new(15,3,30));local e=w:enemy('Shambler',{Volatile=true});local plan=w.N.entryPlan(w.enemies,e,e.window)
 w.enemies:startTraversal(e,plan,w.time);for _=1,20 do w:step(1/30) end
 w.enemies:kill(e,nil,false,true)
 check(e.dead and e.model:GetAttribute('Ragdoll') and not e.root.Anchored,'death during traversal releases the anchored rig into ragdoll')
 check(not e.model.BodyCollider.CanCollide and not e.window.activeEntry and w:activeClocks()==0,'death never leaves a pinning collider/clock')
 check(w.enemies:pendingBlasts()==1 and w.enemies.hazards[1].at>=w.time+w.C.Evolution.volatileBlast.warning,'traversal death preserves full advertised volatile fuse')
 local pos=e.root.Position;w:step(2);check(e.root.Position==pos,'no orphan callback moves the corpse')
 w.enemies:clear();check(#w.enemies.hazards==0,'reset removes hazards created during entry')
end
do
 local w=harness.new();local p,root=w:player(1,V.new(-8,3,0));local e=w:enemy('Shambler',{},nil,true)
 e.model:SetAttribute('TraversalStage','Pursuit');e.root.CFrame=CF.new(e.root.Position)
 w.enemies:damage(e,20,p,true,'hit1','Bullet',e.model.Head)
 local hp=e.hp;local at=e.model:GetAttribute('HitAt');local stun=e.stunnedUntil
 w:step(.05);w.enemies:damage(e,20,p,true,'hit2','Bullet',e.model.Head)
 check(e.hp==hp-20 and e.model:GetAttribute('HitAt')==at and e.stunnedUntil==stun,'visual flinch throttle neither suppresses damage nor adds stun-lock')
 local strength=e.model:GetAttribute('HitStrength');e.model:SetAttribute('HitStrength',0)
 local neutral=w.Pose.sample(e.model,e.root,at+.15);e.model:SetAttribute('HitStrength',strength)
 local poses=w.Pose.sample(e.model,e.root,at+.15)
 check(poses.RootJoint.UpVector.X>neutral.RootJoint.UpVector.X+.001,'left-side shot bends away from the incoming hit')
 root.Position=V.new(8,3,0);w:step(.2);w.enemies:damage(e,20,p,true,'hit3','Bullet',e.model.Head)
 strength=e.model:GetAttribute('HitStrength');e.model:SetAttribute('HitStrength',0)
 neutral=w.Pose.sample(e.model,e.root,w.time+.15);e.model:SetAttribute('HitStrength',strength)
 poses=w.Pose.sample(e.model,e.root,w.time+.15)
 check(poses.RootJoint.UpVector.X<neutral.RootJoint.UpVector.X-.001,'right-side shot produces an opposite directional reaction')
 w.enemies:damage(e,10000,p,false,'kill','Bullet',e.model.Torso)
 check(e.dead and e.model:GetAttribute('DeathVector').X<0,'lethal reaction preserves the force direction for ragdoll')
end
do
 local w=harness.new();w:player(1,V.new(0,3,100))
 for index=1,5 do
  local e=w:enemy('Shambler',{},w:window(index*30));local plan=w.N.entryPlan(w.enemies,e,e.window)
  check(plan~=nil,'separate doorway plan')
  check(w.enemies:startTraversal(e,plan,w.time)==(index<=4),'four simultaneous traversals is a hard cap')
 end
 check(w:activeClocks()==1,'all active entries share one bounded animation clock')
 w.enemies:clear();check(w:activeClocks()==0,'round clear stops all animation callbacks')
end
print('Batch 1 infected assertions passed:',count)
