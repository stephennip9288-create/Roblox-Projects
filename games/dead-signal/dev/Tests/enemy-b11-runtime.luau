-- Executes delivered modules/retained rigs with controlled services, not physics.
local harness=require('./Support/InfectedHarness');local r=harness.roblox;local V=r.Vector3;local CF=r.CFrame
local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local specs={{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}}
do
 local h=harness.new();local e=h:enemy('Shambler');local face=function(p) return CF.lookAt(p,p+V.zAxis) end
 e.window.entry={schema=1,id='seam',room=1,kind='Window',approach=face(V.new(0,0,-9)),breach=face(V.new(0,1.8,0)),landing=face(V.new(0,0,8)),clearance={radius=6,height=12}}
 h.floorFunction=function(p) return math.abs(p.X)<.001 and -2 or 0 end
 local d=h.N.entryDescriptor(h.ctx.map,e.window)
 check(d and math.abs(d.landing.X-.05)<.0001 and d.landing.Y==0,'narrow wedge seam selects a real supported neighboring target')
 check((d.approach-e.window.entry.approach.Position).Magnitude<=.0501 and (d.landing-e.window.entry.landing.Position).Magnitude<=.0501,'seam target shift is bounded in world studs')
 check(h.N.entryPlan(h.enemies,e,e.window)~=nil,'seam-adjusted target still passes full rig and actual foot support')
 h.floorFunction=function(p) return math.abs(p.X)<.2 and -2 or 0 end
 check(not h.N.entryDescriptor(h.ctx.map,e.window),'a broader unsupported landing cannot be patched by nearby floor projection')
 h.floorFunction=function() return -12 end
 check(not h.N.entryDescriptor(h.ctx.map,e.window),'unsupported elevation cannot silently become a ground entry')
end
do
 local h=harness.new();local other=h:enemy('Shambler');local e=h:enemy('Shambler')
 other.traversal={plan={style='Vault',forward=V.zAxis},stage='Cross'}
 local center,size=h.N.worldBox(other,other.root.Position,h.N.rigBounds(other,'Vault','Cross'),V.zAxis)
 local bounds=h.N.rigBounds(e);local ownCenter,ownSize=h.N.worldBox(e,V.zero,bounds,V.zAxis)
 local at=center+V.zAxis*(size.Z*.5+ownSize.Z*.5-.05)-ownCenter
 local clear,reason=h.N.traversalClear(h.enemies,e,at,at,e.window,true,bounds,V.zAxis)
 check(not clear and reason=='Occupied','converging entrances reserve the other climber\'s complete active pose')
 other.traversal=nil
 check(h.N.traversalClear(h.enemies,e,at,at,e.window,true,bounds,V.zAxis),'active-pose occupancy is released when the other actor is no longer climbing')
end
for _,spec in ipairs(specs) do
 local h=harness.new();h:player(1,V.new(25,3,35));local e=h:enemy(spec[1],spec[2]);local collider=e.model.BodyCollider
 check(collider.CanCollide and collider:FindFirstChildOfClass('WeldConstraint').Part0==e.root,'live collider stays on the root, not the leaning torso')
 local bounds=h.N.rigBounds(e)
 local center,size=h.N.worldBox(e,e.root.Position,bounds,V.new(0,0,-1))
 check(size.X>0 and size.Y>0 and size.Z>0 and center.Y==center.Y,'complete finite rig bounds')
 local plan=h.N.entryPlan(h.enemies,e,e.window);check(plan~=nil,spec[1]..' supported entry plan')
 local origin=e.root.Position;check(h.enemies:startTraversal(e,plan,h.time),'entry starts')
 for _=1,300 do
  local before=e.root.Position;h:step(1/30)
  check((before-e.root.Position).Magnitude<=h.N.traversalTuning.maxStep+.001,'entry motion is bounded')
  if e.traversal then check(collider.CanCollide and e.root.Anchored and not e.entered,'live collision and attack gate remain during climbing') end
  if not e.traversal then break end
 end
 check(e.entered and e.model.Parent and (e.root.Position-plan.landing).Magnitude<.001 and (origin-plan.landing).Magnitude>5,'full animated trajectory ends at its supported landing')
 check(not e.root.Anchored and not e.hum.PlatformStand and collider.CanCollide and e.hum.AutoRotate,'native locomotion resumes')
 check(h:activeClocks()==0 and not e.window.activeEntry and #h.hits==0,'no leaked clock/reservation or traversal damage')
end
-- Real crowd geometry is retained, including long crawler/K9 bodies.
for _,density in ipairs({4,12,24}) do
 local h=harness.new();h:player(1,V.new(55,3,55));local w=h:window();local actors={}
 local face=function(p) return CF.lookAt(p,p+V.zAxis) end
 w.entry={schema=1,id='crowd',room=1,kind='Window',approach=face(V.new(0,0,-6)),breach=face(V.new(0,1.8,0)),landing=face(V.new(0,0,8)),clearance={radius=6,height=12}}
 -- The fake navmesh supplies a straight exterior route in this empty world.
 -- Every simulated step is still checked against actual retained body bounds.
 h.N.compute=function(_,e,goal) e.path={{Position=goal-V.yAxis*h.N.rootHeight(e)}};e.index=1;e.pathFailures=0 end
 for index=1,density do
  local spec=specs[(index-1)%6+1];local e=h:enemy(spec[1],spec[2],w)
  local p=h.N.queuePosition(h.enemies,e,w);check(p~=nil,'supported unoccupied queue position for density '..density)
  e.model:PivotTo(CF.lookAt(p,p+V.zAxis));actors[#actors+1]=e
 end
 local entered=0
 for _=1,2200 do
  h.enemies:tick(h.time);h:step(1/15)
  for _,e in ipairs(actors) do if not e.entered and not e.root.Anchored and not e.traversal then
   local to=e.hum:GetAttribute('TestMoveTo')
   if to then
    local d=to-e.root.Position;local at=e.root.Position+(d.Magnitude>.001 and d.Unit*math.min(d.Magnitude,e.hum.WalkSpeed/15) or V.zero)
    if h.N.traversalClear(h.enemies,e,e.root.Position,at,w,true,h.N.rigBounds(e,'Walk','Approach'),V.zAxis) then e.model:PivotTo(CF.lookAt(at,at+V.zAxis)) end
   end
  end end
  for _,e in ipairs(actors) do if e.entered and not e.testCleared then
   check(not e.root.Anchored and not e.traversal,'queue member completes before simulated pursuit moves it away')
   e.testCleared=true;entered+=1
   -- Controlled pursuit movement, after the checked landing (no physics claim).
   e.model:PivotTo(CF.new(80+e.id*8,h.N.rootHeight(e),70))
  end end
  if entered==density then break end
 end
 check(entered==density and h.enemies:count()==density,'all queued wave units enter without retirement at density '..density)
 check(not w.activeEntry and h:activeClocks()==0,'crowd drains reservation and clock')
end
do
 local h=harness.new();h:player(1,V.new(25,3,35));local e=h:enemy('Shambler');local plan=h.N.entryPlan(h.enemies,e,e.window)
 check(h.enemies:startTraversal(e,plan,h.time),'block fixture starts')
 for _=1,18 do h:step(1/30) end
 h.blocked=true;h.blockForward=true
 for _=1,500 do h:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.entered and not e.dead and h.enemies:count()==1,'blocked forward path retreats without quota loss')
 check(not e.window.activeEntry and h:activeClocks()==0,'interrupted route closes ownership')
 local cancels=0;for _,cue in ipairs(h.cues) do if cue.cue=='Enemy.Entry.Cancel' then cancels+=1 end end
 check(cancels==1,'single cancellation cue')
end
do
 local h=harness.new();h:player(1,V.new(25,3,35));local e=h:enemy('Shambler');local plan=h.N.entryPlan(h.enemies,e,e.window)
 h.enemies:startTraversal(e,plan,h.time);for _=1,18 do h:step(1/30) end;h.blocked=true
 for _=1,550 do h:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.root.Anchored and not e.hum.PlatformStand,'both blocked directions cannot keep script ownership indefinitely')
 check(e.model.BodyCollider.CanCollide and h:activeClocks()==0 and h.enemies:count()==1,'physical recovery preserves live collision and wave unit')
 check(e.model:GetAttribute('NavigationState')=='EntryPhysicsRecovery','physical handoff is explicit for Studio retesting')
end
do
 local h=harness.new();local p,pr=h:player(1,V.new(0,3,30));local e=h:enemy('Runner',{Armored=true,Enraged=true})
 local other=h:window(100);h.ctx.map.windows={e.window,other};h.ctx.director={window=function() return other end}
 e.hp=73;e.hum.Health=73;e.armor.Head=0;e.armor.Body=17;e.reactor=9;e.hitRewards={a=true};e.nextCharge=h.time+3;e.nextAmbush=h.time+7
 local original=e.root.Position;local model=e.model;local id=e.id
 h.enemies.clearSight=function() return true end
 check(h.enemies:recover(e) and e.entryRerouting and e.root.Position==original,'visible recovery walks, never pops')
 check(h.enemies.list[id]==e and e.model==model and e.hp==73 and e.hum.Health==73 and e.armor.Body==17 and e.reactor==9 and e.hitRewards.a,'recovery preserves actor and damaged state')
 check(e.nextCharge==103 and e.nextAmbush==107 and h.enemies:count()==1,'recovery retains special cooldowns and quota')
 h.time+=5;pr.Position=V.new(-120,3,-120);pr.CFrame=CF.new(pr.Position);h.enemies.clearSight=function() return false end
 h.ctx.director.window=function() return h.ctx.map.windows[1] end
 check(h.enemies:recover(e) and e.root.Position~=original and not e.entered,'occluded recovery stays exterior and requires a climb')
 check(e.id==id and e.model==model and e.hp==73,'occluded recovery does not respawn/reset health')
 h.ctx.director.window=function() return nil end
 for _=1,8 do h.time+=9;h.enemies:recover(e) end
 check(not e.dead and h.enemies:count()==1 and not h.enemies.retired,'all-invalid geometry never silently deletes a wave unit')
 check(e.model:GetAttribute('NavigationState')=='EntryUnavailable','all-invalid geometry is a release blocker')
end
do
 local h=harness.new();h:player(1,V.new(25,3,35));local e=h:enemy('Shambler');local plan=h.N.entryPlan(h.enemies,e,e.window)
 h.enemies:startTraversal(e,plan,h.time);for _=1,30 do h:step(1/30) end;e.window.count=1
 for _=1,300 do h:step(1/30);if not e.traversal then break end end
 check(not e.entered and not e.traversal and not e.window.activeEntry,'repair interrupts and reverses the entrance')
end
do
 local h=harness.new();h:player(1,V.new(25,3,35));h.ctx.game.aliveCount=function() return 1 end
 local original=h.Rigs.build
 h.Rigs.build=function(...)
  local model,root,hum=original(...);hum.PlatformStand=false
  local proxy=setmetatable({},{__index=function(_,key)
   if key=='Died' then return {Connect=function() return {} end} end
   if key=='SetStateEnabled' then return function() end end
   if key=='MoveTo' then return function(_,p) hum:SetAttribute('TestMoveTo',p) end end
   return hum[key]
  end,__newindex=function(_,key,value) hum[key]=value end})
  return model,root,proxy
 end
 local w=h:window();h.noFloor=true
 local ticket=h.enemies:spawn('Runner',w)
 check(ticket.pending and h.enemies:count()==1 and not next(h.enemies.list),'unsafe admission keeps a pending wave unit')
 check(#h.enemies.folder:GetChildren()==0,'no model replicates into an unsupported fallback slot')
 local id=ticket.id;local hp=ticket.stats.hp
 h.noFloor=false;h.time+=1;h.enemies:tick(h.time)
 local e=h.enemies.list[id]
 check(e and not e.dead and e.hp==hp and h.enemies:count()==1 and #h.enemies.pending==0,'safe admission preserves its ticket identity/stats and total quota')
 h.enemies:clear();check(h.enemies:count()==0,'reset clears admitted and pending units')
 h.noFloor=true;h.enemies:spawn('Warden',w);h.enemies:clear()
 check(h.enemies:count()==0 and #h.enemies.pending==0,'reset also cancels unadmitted Warden tickets')
end
print('Batch 1.1 enemy runtime assertions passed:',count)
