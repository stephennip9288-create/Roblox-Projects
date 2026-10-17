-- Real generated maps + retained rigs; conservative offline collider sweeps.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader') local Geometry=require('./Support/SourceGeometry')
local V=r.Vector3 local count=0 local out={engine=false,maps={},rigs={},failures={},rejected={}}
local function check(ok,message) assert(ok,message);count+=1 end
local function vector(v) return {v.X,v.Y,v.Z} end
local function parts(model)
 local rows={}
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local row={name=p.Name,class=p.ClassName,size=vector(p.Size),cf={p.CFrame:GetComponents()},color={p.Color.R,p.Color.G,p.Color.B},
   transparency=p.Transparency,query=p.CanQuery,collide=p.CanCollide,authoritative=p:GetAttribute('AuthoritativeHitbox')==true}
  if p:IsA('MeshPart') then
   local ok,mesh=pcall(function() return p.MeshId end);row.meshId=ok and mesh or ''
   local got,texture=pcall(function() return p.TextureID end);row.textureId=got and texture or ''
  end
  if p:IsA('Part') then row.shape=p.Shape.Name end
  rows[#rows+1]=row
 end end;return rows
end
fs.writeDir('Validation/InfectedBatch1')
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local folders=loader.install(dm)
 local map=loader.new(dm)(folders.server.MapBuilder).build(id)
 print(id..': source map built')
 local world=Geometry.world(map)
 local load=loader.new(dm,{globals={workspace=world,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}})
 local N=load(folders.server.Navigation);local Rigs=load(folders.server.EnemyRigs);local Anatomy=load(folders.server.RigAnatomy)
 local parent=r.Instance.new('Folder') local owner={ctx={map=map,players={}},list={},folder=parent}
 local report={id=id,scale=map.scale,colliders={},paths={},windows={}}
 for _,shape in ipairs(world.shapes) do local p=shape.part;report.colliders[#report.colliders+1]={name=p.Name,size=vector(p.Size),cf={p.CFrame:GetComponents()},group=p.CollisionGroup} end
 local specs={{kind='Shambler'},{kind='Runner',mods={Armored=true,Enraged=true}},{kind='Crawler'},
  {kind='Hound'},{kind='Hound',mods={Alpha=true}},{kind='Stalker'},{kind='Warden'}}
 for index,w in ipairs(map.windows) do
  w.count=0
  report.windows[#report.windows+1]={inside=vector(w.inside),outside=vector(w.outside),barrier=vector(w.part.CFrame.Position)}
  for si,spec in ipairs(specs) do
   local model,root,hum=Rigs.build(parent,spec.kind,w.outside,index,id)
   local e={id=si,kind=spec.kind,model=model,root=root,hum=hum,mods=spec.mods or {}}
   Rigs.evolve(e);owner.list={[si]=e}
   local floor=N.floor(map,w.inside) or N.floor(map,map.rooms[w.room].center+V.new(0,3,0))
   check(floor~=nil,id..' window '..index..' has source floor support')
   model:PivotTo(r.CFrame.new(V.new(w.outside.X,floor.Y+N.rootHeight(e),w.outside.Z)))
   world.lastBlock=nil
   local plan=N.entryPlan(owner,e,w)
   local label=id..' window '..index..' '..spec.kind..(spec.mods and spec.mods.Alpha and ' Alpha' or spec.mods and ' Ironbound' or '')
   if not plan then
    out.rejected[#out.rejected+1]={label=label,block=world.lastBlock and world.lastBlock:GetFullName() or 'support/clearance'}
    check(world.lastBlock~=nil,label..' rejection identifies a real collider')
   else
    check((root.Position-plan.stages[1].a).Magnitude<.001,label..' starts at actual root')
    local previous=root.Position;local path={label=label,window=index,kind=spec.kind,alpha=spec.mods and spec.mods.Alpha or false,
     radius=N.agent(e).AgentRadius,height=N.agent(e).AgentHeight,rootHeight=N.rootHeight(e),samples={}}
    for sample=0,90 do
     local p,stage=N.traversalSample(plan,plan.duration*sample/90)
     if not N.traversalClear(owner,e,previous,p,w,sample==0 or sample==90) then
      out.failures[#out.failures+1]={label=label,stage=stage,sample=sample,block=world.lastBlock and world.lastBlock:GetFullName() or 'overlap'};break
     end
     check(true,label..' swept sample '..sample)
     path.samples[#path.samples+1]={position=vector(p),stage=stage};previous=p
    end
    report.paths[#report.paths+1]=path
   end
   model:Destroy()
  end
 end
 for _,spec in ipairs(specs) do for room=1,6 do
  local available=0
  for _,path in ipairs(report.paths) do if path.kind==spec.kind and path.alpha==(spec.mods and spec.mods.Alpha or false) and map.windows[path.window].room==room then available+=1 end end
  check(available>0,id..' '..spec.kind..' has a path in sector '..room..'; no wave/Warden soft lock')
 end
 end
 owner.list={}
 print(id..': '..#report.paths..'/70 entry plans; '..#world.shapes..' source colliders; '..world.probes..' sweeps')
 for variant=1,6 do
  local before=Anatomy.build(parent,'Shambler',V.zero,variant)
  local after=Rigs.build(parent,'Shambler',V.zero,variant,id)
  out.rigs[#out.rigs+1]={map=id,kind='Shambler',family=after:GetAttribute('OutfitName'),before=parts(before),after=parts(after)}
  before:Destroy();after:Destroy()
 end
 for _,spec in ipairs({{kind='Hound'},{kind='Hound',mods={Alpha=true}}}) do
  local before,br,bh=Anatomy.build(parent,spec.kind,V.zero,1)
  -- Parent #19 already has Alpha scaling/spines/antlers: show them on both
  -- sides so the review does not attribute existing evolution to Batch 1.
  Rigs.evolve({id=1,model=before,root=br,hum=bh,kind=spec.kind,mods=spec.mods or {}})
  local model,root,hum=Rigs.build(parent,spec.kind,V.zero,1,id)
  local e={id=1,model=model,root=root,hum=hum,kind=spec.kind,mods=spec.mods or {}};Rigs.evolve(e)
  out.rigs[#out.rigs+1]={map=id,kind='Hound',family=spec.mods and 'Alpha' or 'K9',before=parts(before),after=parts(model)}
  before:Destroy();model:Destroy()
 end
 out.maps[#out.maps+1]=report
 map.model:Destroy();parent:Destroy()
end
out.assertions=count
fs.writeFile('Validation/InfectedBatch1/Geometry.json',serde.encode('json',out))
for _,failure in ipairs(out.failures) do print(serde.encode('json',failure)) end
for _,failure in ipairs(out.rejected) do print('Safely rejected:',serde.encode('json',failure)) end
check(#out.failures==0,'Source geometry entry failures; see Validation/InfectedBatch1/Geometry.json')
print('Batch 1 source-geometry assertions passed:',count)
