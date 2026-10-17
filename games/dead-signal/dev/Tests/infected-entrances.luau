local harness=require('./Support/InfectedHarness');local r=harness.roblox;local V=r.Vector3;local CF=r.CFrame
local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
for _,kind in ipairs({'Door','Tunnel','Vent','LowVault','Ledge'}) do
 local h=harness.new();h:player(1,V.new(15,3,30));local species=kind=='Vent' and 'Crawler' or 'Shambler';local e=h:enemy(species,{},nil,true)
 local link={id='link-1',kind=kind,approach=V.new(0,0,-9),contact=V.zero,landing=V.new(0,0,8),room=1,width=5,height=9}
 if kind=='Ledge' then link.landing=V.new(0,4,8);h.floorFunction=function(pos) return pos.Z>5 and 4 or 0 end end
 h.ctx.map.traversals={link}
 local plan=h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time)
 check(plan and plan.kind==kind,kind..' consumes an explicit geometry-authored link')
 check(h.enemies:startTraversal(e,plan,h.time),'start contextual traversal')
 for _=1,400 do h:step(1/30);if not e.traversal then break end end
 check(not e.traversal and (e.root.Position-plan.landing).Magnitude<.001 and not e.root.Anchored,kind..' reaches the actual landing and releases locomotion')
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),kind..' cannot immediately repeat the same traversal')
end
do
 local h=harness.new();h:player(1,V.new(15,3,30));local e=h:enemy('Shambler',{},nil,true)
 local link={id='door',kind='Door',approach=V.new(0,0,-9),landing=V.new(0,0,8),room=1,door={open=false}}
 h.ctx.map.traversals={link}
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'closed doors cannot be bypassed by traversal')
 link.door.open=true;h.ctx.map.rooms[1].unlocked=false
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'locked sectors cannot be bypassed by traversal')
 h.ctx.map.rooms[1].unlocked=true;link.kind='Vent';link.kinds={Crawler=true}
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'humanoid cannot squeeze through a species-restricted vent')
 link.kind='Door';link.kinds=nil;link.width=1
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'agent body width is respected')
 link.width=5;link.height=2
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'agent body height is respected')
 link.height=9;link.rise=100
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'unbounded authored leaps are rejected')
 link.rise=0;link.height=9;link.kinds=nil
 local key='door:1';e.traversalUses={[key]=2}
 check(not h.N.contextPlan(h.enemies,e,V.new(0,3,30),h.time),'link retry budget prevents recovery loops')
 e.traversalUses={};h.enemies:tick(h.time)
 check(e.traversal~=nil,'normal pursuit uses an authored contextual link before requesting a native path')
 link.door.open=false
 for _=1,240 do h:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.root.Anchored,'closing a door cancels/retreats and restores the previously entered actor')
end
do
 local h=harness.new();local p,root=h:player(1,V.new(0,3,8));h.ctx.players[p].status='Down';h:player(2,V.new(15,3,30))
 local e=h:enemy('Shambler');local plan=h.N.entryPlan(h.enemies,e,e.window)
 check(plan~=nil,'available landing chosen')
 check((V.new(plan.landing.X,0,plan.landing.Z)-V.new(root.Position.X,0,root.Position.Z)).Magnitude>=2.5,'downed body is protected from landing overlap')
 h.overlap=true;check(not h.N.entryPlan(h.enemies,e,e.window),'occupied landing volume is rejected')
 h.overlap=false;h.blocked=true;check(not h.N.entryPlan(h.enemies,e,e.window),'static wall cannot be bypassed by entry animation')
 h.blocked=false;h.noFloor=true;check(not h.N.entryPlan(h.enemies,e,e.window),'entry requires real landing floor support')
 h.noFloor=false;e.window.inside=e.window.outside
 check(not h.N.entryPlan(h.enemies,e,e.window),'zero-length legacy entrance is rejected without NaN direction')
end
do
 local h=harness.new();h:player(1,V.new(15,3,30));local e=h:enemy('Shambler');local original=e.window
 for _,bad in ipairs({true,{kind='Teleport'},{kind='Window',height='huge'},{kind='Window',approach=4},{kind='Window',kinds=true},{kind='Window',rise=0/0}}) do
  original.entry=bad;check(not h.N.entryPlan(h.enemies,e,original),'malformed descriptor fails closed')
 end
 original.entry=nil;local plan=h.N.entryPlan(h.enemies,e,original);h.enemies:startTraversal(e,plan,h.time)
 for _=1,10 do h:step(1/30) end;original.count=1
 for _=1,240 do h:step(1/30);if not e.traversal then break end end
 check(not e.traversal and not e.entered and not original.activeEntry,'repaired barricade abandons a pending entry cleanly')
 check(not h.N.entryPlan(h.enemies,e,original),'repaired barricade cannot immediately reenter')
 original.count=0;h.time=e.entryRetryAt+.01
 plan=h.N.entryPlan(h.enemies,e,original);check(plan~=nil,'cleared route can retry after cancellation')
 h.enemies:startTraversal(e,plan,h.time);h.enemies:clear()
 check(h:activeClocks()==0 and not original.activeEntry,'reset during retry cleans all state')
end
do
 local h=harness.new();local Director=h.load(harness.folders.server.WaveDirector)
 local function entry(id,height,kinds)
  local function face(p) return CF.lookAt(p,p+V.new(0,0,1)) end
  return {schema=1,id=id,kind='Window',room=1,approach=face(V.new(0,0,-9)),breach=face(V.new(0,1.8,0)),
   landing=face(V.new(0,0,8)),clearance={radius=2.5,height=height},allowedKinds=kinds}
 end
 local restricted=h:window();restricted.entry=entry('restricted',5,{'Crawler','Hound'})
 check(not Director.entranceEligible(restricted,nil) and not Director.entranceEligible(restricted,'Warden'),'generic/Warden selection excludes restricted entrances')
 check(Director.entranceEligible(restricted,'Hound') and Director.entranceEligible(restricted,'Crawler'),'eligible K9/crawler can use an authored window')
 restricted.entry.clearance.height=2;check(not Director.entranceEligible(restricted,'Hound'),'director rejects undersized hound entrance')
 local large=h:window(30);large.entry=entry('large',10)
 check(Director.entranceEligible(large,nil) and Director.entranceEligible(large,'Warden'),'large window remains compatible with generic/Warden spawns')
 h.ctx.map.windows={restricted,large};h.ctx.map.windows[1].inside=V.new(0,3,35);h.ctx.map.windows[2].inside=V.new(40,3,35)
 h:player(1,V.new(0,3,0));local director=Director.new(h.ctx);h.ctx.director=director
 check(director:window(h.time,'Warden')==large,'actual director selects a valid Warden entrance')
 large.entryBlockedUntil={Warden=h.time+8}
 check(not director:window(h.time,'Warden'),'temporarily blocked Warden entrance is not selected again')
 check(director:window(h.time,'Runner')==large,'blocked species does not exclude smaller agents')
 check(director:window(h.time+8.1,'Warden')==large,'entrance suppression expires without permanent exclusion')
 large.entryBlockedUntil=nil
 local failed={[large]=h.ctx.map.navigationRevision}
 check(not director:window(h.time+20,'Warden',failed),'a recovery cycle does not repeat a rejected entrance merely because its short cooldown expired')
 h.ctx.map.navigationRevision+=1
 check(director:window(h.time+20,'Warden',failed)==large,'a purchased-door revision invalidates recovery entrance exclusions')
 local boss=h:enemy('Warden',{},large,true);boss.hp=boss.maxHP*.71
 local spawned={};h.enemies.spawn=function(_,kind,window,position) spawned[#spawned+1]={kind=kind,window=window,position=position} end
 h.enemies:damage(boss,100000,nil,true,'phase','Bullet')
 check(boss.phase==2 and #spawned==2,'existing Warden phase/escort count is preserved')
 for _,s in ipairs(spawned) do check(s.kind=='Runner' and s.window==large and s.position==nil,'phase escorts use the exterior entrance') end
end
do
 local h=harness.new();h:player(1,V.new(15,3,30));local e=h:enemy('Hound',{Alpha=true})
 local function face(p) return CF.lookAt(p,p+V.new(0,0,1)) end
 local d={schema=1,id='north-1',kind='Window',room=1,approach=face(V.new(0,0,-9)),breach=face(V.new(0,1.8,0)),
  landing=face(V.new(0,0,8)),clearance={radius=2.1,height=5},allowedKinds={'Hound'}}
 e.window.entry=d
 check(h.N.entryPlan(h.enemies,e,e.window)~=nil,'canonical world-space CFrame descriptor is consumed without double scaling')
 d.clearance.radius=1.7;check(not h.N.entryPlan(h.enemies,e,e.window),'actual Alpha radius is checked after evolution')
 d.clearance.radius=2.1;d.clearance.height=3.5;check(not h.N.entryPlan(h.enemies,e,e.window),'actual Alpha height is checked after evolution')
 d.clearance.height=5;d.allowedKinds={'Crawler'};check(not h.N.entryPlan(h.enemies,e,e.window),'allowedKinds list is authoritative')
 d.allowedKinds={'Hound'};d.landing=face(V.new(0,5,8));check(not h.N.entryPlan(h.enemies,e,e.window),'unsupported upper anchor cannot project to ground')
 d.landing=face(V.new(0,0,8));d.approach=CF.new(0,0,-9);check(not h.N.entryPlan(h.enemies,e,e.window),'backwards anchor fails closed')
 d.approach=face(V.new(0,0,-9));d.kind='Vent';check(not h.N.entryPlan(h.enemies,e,e.window),'vent spawning remains gated until kind-specific map review')
 d.kind='Window';d.allowedKinds={Hound=true};check(not h.N.entryPlan(h.enemies,e,e.window),'dictionary is not silently accepted as a canonical allowedKinds list')
end
do
 local h=harness.new();h:player(1,V.new(15,3,30));local e=h:enemy('Hound',{Alpha=true})
 local function face(p) return CF.lookAt(p,p+V.new(0,0,1)) end
 h.ctx.map.scale=1.2
 e.window.entry={schema=1,id='producer-29',kind='Window',room=1,approach=face(V.new(0,4.2,-13.2)),
  breach=face(V.new(0,7.56,0)),landing=face(V.new(0,4.2,9.6)),clearance={radius=6.1,height=10.8},
  allowedKinds={'Shambler','Runner','Crawler','Hound','Stalker','Warden'}}
 local d=h.N.entryDescriptor(h.ctx.map,e.window)
 check(d and math.abs(d.approach.Y)<.001 and math.abs(d.landing.Y)<.001,'Maps navigation reference frames normalize to physical feet without double scale')
 check(math.abs(d.contact.Y-2.16)<.001,'Maps opening-center breach resolves the physical sill top')
 local plan=h.N.entryPlan(h.enemies,e,e.window)
 check(plan and math.abs(plan.landing.Y-h.N.rootHeight(e))<.001,'Maps producer schema supports the actual evolved K9 root height')
 h.floorFunction=function() return 12 end
 e.window.entry.approach=face(V.new(0,16.2,-13.2));e.window.entry.breach=face(V.new(0,19.56,0));e.window.entry.landing=face(V.new(0,16.2,9.6))
 d=h.N.entryDescriptor(h.ctx.map,e.window)
 check(d and math.abs(d.landing.Y-12)<.001 and math.abs(d.approach.Y-12)<.001,'navigation reference normalization retains supported upper floor')
 h.floorFunction=nil
 check(not h.N.entryDescriptor(h.ctx.map,e.window),'lost upper floor cannot silently become a ground entry')
end
print('Batch 1 entrance contract assertions passed:',count)
