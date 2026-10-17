-- Source, lifecycle and physical contract tests for MAP-01..12. No Roblox engine is simulated.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader') local V=r.Vector3 local count=0 local reports={}
local function check(ok,msg) assert(ok,msg);count+=1 end
local function vec(p) return {p.X,p.Y,p.Z} end
local function inside(poly,p)
 local hit=false local j=#poly
 for i,a in ipairs(poly) do local b=poly[j]
  if (a[2]>p.Z)~=(b[2]>p.Z) and p.X<(b[1]-a[1])*(p.Z-a[2])/(b[2]-a[2])+a[1] then hit=not hit end j=i
 end return hit
end
local function supported(room,p)
 for _,region in ipairs(room.upperFloorRegions or {}) do if inside(region,p) then return true end end return false
end
fs.writeDir('Validation/MapBatch1')
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl')) local f=loader.install(dm)
 local delayed={} local testTask={spawn=function(fn) fn() end,delay=function(seconds,fn) table.insert(delayed,{seconds=seconds,callback=fn}) end,wait=function() end}
 local load=loader.new(dm,{globals={task=testTask},services={Players={GetPlayers=function() return {} end}}})
 local M=load(f.server.MapBuilder) local F=load(f.server.CinematicWorld) local L=load(f.shared.MapLayouts)
 local Graph=load(f.shared.NavigationGraph) local Bounds=load(f.server.BoundaryGuard) local G=load(f.server.Game)
 local C=load(f.shared.Config) local map=M.build(id)
 local report={id=id,parts=0,scenery=map.scenery.counts,particleRate=map.scenery.maxParticleRate,barriers={},zones={},landmarks={},galleries={},entries={},facility={},engine=false}
 check(map.model:GetAttribute('Batch1MapRevision')==1,id..' batch source marker')
 check(#delayed==1 and delayed[1].seconds==1,id..' one bounded world update queued')
 check(#map.facilityDisplays==6,id..' every sector has functional outbreak equipment')
 for _,display in ipairs(map.facilityDisplays) do
  check(display.purpose==map.layout[display.room].purpose and #display.trace>5,id..' trace belongs to facility function')
  check(display.part.CanCollide,id..' facility cabinet retains its single physical body')
  table.insert(report.facility,{id=display.id,room=display.room,purpose=display.purpose,trace=display.trace,position=vec(display.part.CFrame.Position)})
 end
 for _,part in ipairs(map.model:GetDescendants()) do if part:IsA('BasePart') and part:GetAttribute('FacilityDetail') and part.Name~='FacilityInstrumentCabinet' then
  check(not part.CanCollide and not part.CanQuery,id..' facility handles, gauges and paper are nonblocking detail')
 end end
 local kinds={}
 for i,barrier in ipairs(map.barriers) do
  kinds[barrier.kind]=true
  check(barrier.part==map.doors[i].part and barrier.part.CanCollide,id..' closed barrier retains actual purchase collider')
  check(barrier.part:GetAttribute('BarrierKind')==L.Barriers[id][i][1],id..' exact themed barrier vocabulary')
  for _,sign in ipairs(barrier.part:GetChildren()) do if sign:GetAttribute('DoorReadHeight') then
   local outward=sign.CFrame.LookVector local depth=(sign.CFrame.Position-barrier.part.CFrame.Position):Dot(outward)
   for _,prop in ipairs(barrier.part:GetChildren()) do if prop:IsA('BasePart') and not prop:GetAttribute('DoorReadHeight') then
    local half=prop.Size*.5 local cf=prop.CFrame
    local extent=math.abs(cf.RightVector:Dot(outward))*half.X+math.abs(cf.UpVector:Dot(outward))*half.Y+math.abs(cf.LookVector:Dot(outward))*half.Z
    check(depth>(cf.Position-barrier.part.CFrame.Position):Dot(outward)+extent+.1*map.scale,id..' purchase panel stands beyond barrier geometry on both faces')
   end end
  end end
  table.insert(report.barriers,{id=i,kind=barrier.kind,title=barrier.title,a=map.doors[i].a,b=map.doors[i].b,cost=map.doors[i].cost})
 end
 local variety=0 for _ in pairs(kinds) do variety+=1 end check(variety>=4,id..' multiple physical barrier families')
 -- Exercise actual Game:bindMap purchase handlers; no duplicated copy of its hide implementation.
 local callbacks={} local payments=0 local player={DisplayName='Offline Operator',points=30000}
 local ctx={map=map,run={round=1,power=false,peak=1},interact={bind=function(_,part,_,_,_,callback) callbacks[part]=callback;return {} end}}
 local g=setmetatable({ctx=ctx,makeBox=function() end,broadcast=function() end,pay=function(_,who,price)
  if who.points<price then return false end who.points-=price payments+=1 return true
 end},G)
 g:bindMap()
 callbacks[map.doors[3].part](player)
 check(payments==0 and not map.doors[3].open,id..' inaccessible sector purchase is rejected')
 for i,door in ipairs(map.doors) do
  callbacks[door.part](player) local spent=payments callbacks[door.part](player)
  check(door.open and payments==spent and not door.part.CanCollide,id..' each purchase opens once')
  for _,part in ipairs(door.part:GetDescendants()) do
   if part:IsA('BasePart') then check(not part.CanCollide and not part.CanQuery and part.Transparency==1,id..' no hidden collision/decor after purchase') end
   if part:IsA('SurfaceGui') then check(not part.Enabled,id..' gate labels clear with passage') end
  end
 end
 check(payments==9,id..' all nine routes purchase without deadlock')
 local collisionBefore={} for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then collisionBefore[p]=p.CanCollide end end
 for _,now in ipairs({0,2,6,8,24,43,48,53,61,67,200}) do
  check(F.worldStep(map,now),id..' current-map visual update')
  for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then check(p.CanCollide==collisionBefore[p],id..' ambient event cannot mutate collision') end end
  for _,event in ipairs(map.visualEvents) do
   check(event.part:GetAttribute('AmbientOnly') or event.kind=='PolarGust',id..' event isolated from game lights')
   check((event.part.CFrame.Position-event.base.Position).Magnitude<=8.01*map.scale,id..' bounded scenery movement')
   if event.emitter then check(event.emitter.Rate<=4 and event.emitter.Lifetime.Max<=2,id..' capped far-weather particles') end
  end
 end
 for _,barrier in ipairs(map.barriers) do check(barrier.state=='Open',id..' visual state follows authoritative door') end
 -- Use the delivered Warden rig's navigation envelope, not guessed human proportions.
 local Rig=load(f.server.EnemyRigs) local radius,height=0,0 local envelopes={}
 for index,spec in ipairs({{kind='Shambler'},{kind='Runner'},{kind='Crawler'},{kind='Hound'},
  {kind='Stalker'},{kind='Warden'},{kind='Hound',mods={Alpha=true}},{kind='Runner',mods={Armored=true,Enraged=true}}}) do
  local rig,root,hum=Rig.build(dm.Workspace,spec.kind,V.zero,index)
  Rig.evolve({id=index,kind=spec.kind,model=rig,root=root,hum=hum,mods=spec.mods or {}})
  local r=rig:GetAttribute('NavigationRadius') local h=rig:GetAttribute('NavigationHeight')
  check(r>0 and h>0,id..' actual rig envelope') radius=math.max(radius,r) height=math.max(height,h)
  table.insert(envelopes,{kind=spec.kind,title=rig:GetAttribute('EnemyTitle'),radius=r,height=h});rig:Destroy()
 end
 report.agents=envelopes
 for i,room in ipairs(map.rooms) do if room.stairs then
  check(#room.stairs==2,id..' service walk has two ground approaches')
  check(room.rise-map.scale>=height+.4,id..' Warden fits below service deck')
  check(room.height-room.rise>=height+.5,id..' Warden fits above service deck')
  local entry={room=i,rise=room.rise,headroom=room.height-room.rise,ring={},regions=room.upperFloorRegions,stairs={}}
  for _,stair in ipairs(room.stairs) do
   check(stair.width>=2*radius+2.5,id..' Warden and crawl clearance on ramp')
   check(math.deg(math.atan2(stair.rise,stair.run))<27,id..' walkable no-jump slope')
   check((stair.top-stair.base).Magnitude>30*map.scale,id..' separated ingress and landing')
   for step=0,16 do
    local p=stair.base:Lerp(stair.top,step/16)
    check(L.contains(map.layout[i],p.X/map.scale,p.Z/map.scale,radius/map.scale+.1),id..' ramp body stays inside facility shell')
   end
   for n=1,12 do local angle=n*math.pi/6 local p=stair.top+V.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
    check(supported(room,p),id..' full-body landing joins elevated floor without gap')
   end
   local direction=V.new(0,0,stair.top.Z>stair.base.Z and 1 or -1)
   local rampStart=stair.base+direction*3*map.scale local rampEnd=stair.top-direction*3*map.scale
   for n=0,31 do local at=rampStart:Lerp(rampEnd,n/32)
    if room.rise-at.Y<height+.5 then check(not supported(room,at),id..' ramp opening removes overhead deck and premature landing lip') end
   end
   local route=Graph.route(map,stair.base+V.new(0,3,0),room.upperCenter+V.new(0,3,0))
   check(route and #route>0,id..' lower-to-upper recovery is connected')
   table.insert(entry.stairs,{base=vec(stair.base),top=vec(stair.top),width=stair.width,run=stair.run})
  end
  for n,a in ipairs(room.upperRing) do
   table.insert(entry.ring,vec(a));local b=room.upperRing[n%#room.upperRing+1]
   for step=0,12 do local at=a:Lerp(b,step/12)
    for side=1,8 do local angle=side*math.pi/4 local p=at+V.new(math.cos(angle)*(radius+.2),0,math.sin(angle)*(radius+.2))
     check(supported(room,p),string.format('%s room %d ring %d sample %d/%d at %.2f,%.2f: Warden can use full service circuit',id,i,n,step,side,p.X,p.Z))
    end
   end
  end
  for key,node in pairs(map.navigation.nodes) do if node.room==i and node.level==1 then
   check(supported(room,node.position),id..' elevated recovery node is on a real deck')
   for _,edge in ipairs(map.navigation.edges[key]) do local dest=map.navigation.nodes[edge.to]
    if dest.room==i and dest.level==1 then for step=0,24 do
     check(supported(room,node.position:Lerp(dest.position,step/24)),id..' elevated recovery edge never shortcuts through the atrium or ramp opening')
    end end
   end
  end end
  table.insert(report.galleries,entry)
 end end
 local support={} for _,p in ipairs(map.floorParts) do support[p]=true end
 for _,p in ipairs(map.scenery.model:GetDescendants()) do if p:IsA('BasePart') then
  check(not p.CanCollide and not p.CanQuery and not p.CanTouch and not support[p],id..' scenery never enters movement, shots or support floors')
  check(not Bounds.contains(map,p.CFrame.Position),id..' scenery lies outside playable regions')
 end end
 check(map.scenery.parts<450,id..' bounded layered exterior detail')
 for _,point in ipairs(map.landmarks) do table.insert(report.landmarks,{id=point.id,kind=point.kind,tier=point.tier,position=vec(point.position),event=point.event}) end
 check(#report.landmarks>=4,id..' stable surrounding landmark inventory')
 check(map.semantics:GetAttribute('Coordinates')=='WorldStuds',id..' replicated metadata coordinate contract')
 for _,zone in ipairs(map.audioZones) do
  check(map.semantics.Zones:FindFirstChild(zone.id)~=nil,id..' semantic zone available without remote/script')
  table.insert(report.zones,{id=zone.id,kind=zone.kind,room=zone.room,purpose=zone.purpose or zone.name,level=zone.level,indoors=zone.indoors})
 end
 for _,w in ipairs(map.windows) do
  local e=w.entry
  check(e.schema==1 and e.room==w.room and (e.landing.Position-w.inside).Magnitude<.001,id..' legacy-compatible entry envelope')
  check(e.clearance.radius>=radius+.5 and e.clearance.height>=height+.5,id..' entry opening accommodates the actual Warden envelope')
  check(#e.allowedKinds==6 and table.find(e.allowedKinds,'Warden'),id..' explicit eligible species; elite rig envelope tested below')
  for _,frame in ipairs({e.approach,e.breach,e.landing}) do check(frame.LookVector:Dot(e.inward)>.999,id..' entry frame -Z points inward') end
  check(w.part:GetAttribute('EntryId')==e.id and (w.part:GetAttribute('Landing').Position-w.inside).Magnitude<.001,id..' entry anchor replication')
  check(not Bounds.contains(map,e.approach.Position),id..' exterior spawn approach not a player-safe balcony')
  table.insert(report.entries,{id=e.id,kind=e.kind,room=w.room,approach=vec(e.approach.Position),breach=vec(e.breach.Position),landing=vec(e.landing.Position),clearance=e.clearance,allowedKinds=e.allowedKinds})
 end
 local lights=0 local shadows=0 local sounds=0
 for _,p in ipairs(map.model:GetDescendants()) do
  if p:IsA('BasePart') then report.parts+=1 end
  if p:IsA('Light') then lights+=1;if p.Shadows then shadows+=1 end end
  if p:IsA('Sound') then sounds+=1 end
  check(not p:IsA('LuaSourceContainer') and not p:IsA('RemoteEvent'),id..' no added runtime script/remote records')
 end
 check(sounds==0 and shadows<=3,id..' no duplicate audio path and capped shadow lights')
 check(report.parts<6500,id..' retain parent static-part ceiling')
 report.lights=lights report.shadowLights=shadows report.agentRadius=radius report.agentHeight=height
 local signature={} for _,bay in ipairs(map.mounts) do signature[bay.room..':'..bay.key]={bay.cf:GetComponents()} end
 local old=map;local nextMap=M.build(id)
 check(not old.model.Parent,id..' new run destroys prior world')
 for _,bay in ipairs(nextMap.mounts) do
  local before=signature[bay.room..':'..bay.key] local now={bay.cf:GetComponents()}
  for i,value in ipairs(now) do check(math.abs(value-before[i])<.0001,id..' deterministic wall placement across rebuild') end
 end
 check(not F.worldStep(old,10),id..' stale visual update stops after map destruction')
 local pending=#delayed delayed[1].callback();check(#delayed==pending,id..' destroyed-map callback cannot requeue')
 table.insert(reports,report)
 print(id..' Batch 1: '..report.parts..' parts, '..map.scenery.parts..' scenery parts, '..#report.galleries..' two-ended service walks')
end
fs.writeFile('Validation/MapBatch1/Contracts-Report.json',serde.encode('json',{maps=reports,assertions=count,robloxStudio=false,phone=false,published=false}))
print('Batch 1 map assertions passed:',count)
return count
