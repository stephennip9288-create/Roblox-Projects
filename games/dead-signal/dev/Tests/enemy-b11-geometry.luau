-- Strict actual part collision/support audit, with no logical floor-region fill.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader');local G=require('./Support/EnemyB11Geometry');local V=r.Vector3
local process=require('@lune/process')
local report={engine=false,logical_floor_fill=false,base='206ae616a7de4fe8dd69b1c8019bae6ea8b6863d',profiles=7,windows=0,plans=0,passed=0,failures={},envelopes={}}
report.map_ref=process.args[1] or report.base
report.enemy_ref=process.args[2] or "working"
local specs={{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}}
local function vec(v) return {v.X,v.Y,v.Z} end
for _,id in ipairs(process.args[3] and {process.args[3]} or {'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local folders=loader.install(dm)
 local map=loader.new(dm)(folders.server.MapBuilder).build(id)
 local strict=table.clone(map);strict.floorRegions={};strict.floorParts=table.clone(map.floorParts)
 local exterior=map.model:FindFirstChild('ExteriorGround');if exterior then strict.floorParts[#strict.floorParts+1]=exterior end
 local world=G.world(strict)
 local load=loader.new(dm,{globals={workspace=world,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}})
 local N=load(folders.server.Navigation);local Rigs=load(folders.server.EnemyRigs);local parent=r.Instance.new('Folder')
 local owner={ctx={map=map,players={}},list={},folder=parent}
 for wi,w in ipairs(map.windows) do
  if process.args[4] and wi~=tonumber(process.args[4]) then continue end
  report.windows+=1;w.count=0
  for si,spec in ipairs(specs) do
   report.plans+=1;local model,root,hum=Rigs.build(parent,spec[1],w.outside,wi,id)
   local e={id=si,kind=spec[1],model=model,root=root,hum=hum,mods=spec[2]};Rigs.evolve(e);owner.list={[si]=e}
   local b=N.rigBounds(e);report.envelopes[#report.envelopes+1]={map=id,window=wi,kind=spec[1],alpha=spec[2].Alpha==true,low=vec(b.low),high=vec(b.high)}
   local approach=w.entry.approach.Position
   model:PivotTo(r.CFrame.lookAt(approach+V.yAxis*N.rootHeight(e),approach+V.yAxis*N.rootHeight(e)+w.entry.approach.LookVector))
   local floor=N.floor(map,approach+V.yAxis*1.5)
   world.lastBlock=nil;world.lastFailure=nil
   local descriptor=N.entryDescriptor(map,w);local plan,reason=N.entryPlan(owner,e,w);local issue
   if not floor or math.abs(floor.Y-approach.Y)>.6 then issue='approach-floor'
   elseif not descriptor then issue='descriptor-support'
   elseif not plan then issue=reason or 'rejected' end
   if plan then
    local previous=root.Position
    for sample=0,120 do
     local at,stage=N.traversalSample(plan,plan.duration*sample/120)
     if not N.traversalClear(owner,e,previous,at,w,true,N.rigBounds(e,plan.style,stage),plan.forward) then issue='whole-rig-sweep:'..stage;break end
     previous=at
    end
   end
   if issue then report.failures[#report.failures+1]={map=id,window=wi,kind=spec[1],alpha=spec[2].Alpha==true,reason=issue,
    approach=vec(approach),actualFloor=floor and vec(floor),landing=vec(w.entry.landing.Position),landingFloor=N.floor(map,w.entry.landing.Position+V.yAxis*1.5) and vec(N.floor(map,w.entry.landing.Position+V.yAxis*1.5)),probe=world.lastFailure,collider=world.lastBlock and world.lastBlock:GetFullName() or nil}
   else report.passed+=1 end
   model:Destroy()
  end
 end
 print(id..': strict physical support audit complete')
 parent:Destroy();map.model:Destroy()
end
fs.writeDir('Validation/EnemyB11');fs.writeFile('Validation/EnemyB11/'..(process.args[3] and 'Geometry-'..process.args[3]..'-'..(process.args[4] or 'all') or 'Geometry')..'.json',serde.encode('json',report))
print('Strict window/profile plans:',report.passed,'/',report.plans,'windows:',report.windows)
local expected=process.args[4] and 1 or process.args[3] and 10 or 30
assert(report.windows==expected and report.plans==expected*7 and #report.failures==0,'Strict map/entry integration gate failed; see Validation/EnemyB11/Geometry.json')
print('Batch 1.1 enemy geometry assertions passed:',report.passed)
