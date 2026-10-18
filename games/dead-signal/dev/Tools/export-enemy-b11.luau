-- Review-only: exact retained part bounds and joints, not mesh triangles or textures.
-- Run from dev after extracting EnemyRigs, InfectedWardrobe and NPCPose at
-- 206ae616a7de4fe8dd69b1c8019bae6ea8b6863d into Validation/EnemyB11/BeforeSource/.
-- This tool never serializes or mutates a native place on disk.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local process=require('@lune/process');local loader=require('../Tests/Support/RuntimeLoader')
local out='Validation/EnemyB11';fs.writeDir(out)
local report={engine=false,render='part bounds and Motor6D frames only',
 before_ref='206ae616a7de4fe8dd69b1c8019bae6ea8b6863d',after_ref=process.args[1] or 'working',snapshots={}}
local reference={native_render_inspected=false,families={}}
local function vec(v) return {v.X,v.Y,v.Z} end
for _,map in ipairs({'Station','Foundry','Frost'}) do
 for _,revision in ipairs({'before','after'}) do
  local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
  local currentFrames=loader.new(dm)(f.shared.NPCPose).frames
  if revision=='before' then for _,name in ipairs({'EnemyRigs','InfectedWardrobe','NPCPose'}) do
   local module=(name=='NPCPose' and f.shared or f.server):FindFirstChild(name)
   module.Source=fs.readFile(out..'/BeforeSource/'..name..'.lua')
  end end
  local load=loader.new(dm);local R=load(f.server.EnemyRigs);local P=load(f.shared.NPCPose)
  if map=='Station' and revision=='after' then
   local art=dm.ReplicatedStorage:FindFirstChild('DeadSignalArt')
   if art then reference.artRevision=art:GetAttribute('ArtRevision')
    for _,family in ipairs(art:GetChildren()) do
     if not (family.Name:match('^Infected_[1-6]$') or family.Name=='Warden' or family.Name=='Crawler' or family.Name=='Hound') then continue end
     local rows={}
     for _,p in ipairs(family:GetDescendants()) do if p:IsA('MeshPart') then
      local mesh,texture;pcall(function() mesh=tostring(p.MeshContent) end);pcall(function() texture=tostring(p.TextureContent) end)
      rows[#rows+1]={name=p.Name,mesh=mesh,texture=texture,artBone=p:GetAttribute('ArtBone'),size=vec(p.Size)}
     end end
     if #rows>0 then reference.families[#reference.families+1]={name=family.Name,meshes=rows} end
    end
   end
  end
  for _,spec in ipairs({{'idle','Shambler',1,0},{'run','Runner',2,12},{'attack','Shambler',4,0},{'climb','Warden',6,0}}) do
   local model,root,hum=R.build(nil,spec[2],r.Vector3.zero,spec[3],map)
   local e={id=spec[3],kind=spec[2],model=model,root=root,hum=hum,mods={}};R.evolve(e)
   root.AssemblyLinearVelocity=r.Vector3.new(0,0,-spec[4])
   if spec[1]=='attack' then model:SetAttribute('AttackAt',100) end
   if spec[1]=='climb' then
    model:SetAttribute('TraversalStage','Cross');model:SetAttribute('TraversalStyle','Vault')
    model:SetAttribute('TraversalStageAt',100);model:SetAttribute('TraversalStageDuration',1)
   end
   local frames=currentFrames(model,P.sample(model,root,100.5))
   local row={map=map,revision=revision,action=spec[1],kind=spec[2],parts={},joints={}}
   for _,p in ipairs(model:GetDescendants()) do
    if p:IsA('BasePart') and p.Transparency<.95 then
     local weld=p:FindFirstChildOfClass('WeldConstraint');local bone=weld and weld.Part0 or p
     local bind=weld and weld.Part0 and weld.Part0.CFrame:ToObjectSpace(p.CFrame) or r.CFrame.identity
     local cf=(frames[bone] or root.CFrame:ToObjectSpace(bone.CFrame))*bind
     row.parts[#row.parts+1]={name=p.Name,cf={cf:GetComponents()},size=vec(p.Size),
      color={p.Color.R,p.Color.G,p.Color.B},mesh=p:IsA('MeshPart')}
    elseif p:IsA('Motor6D') and p.Part0 and p.Part1 and frames[p.Part0] and frames[p.Part1] then
     row.joints[#row.joints+1]={name=p.Name,a=vec(frames[p.Part0].Position),b=vec(frames[p.Part1].Position)}
    end
   end
   report.snapshots[#report.snapshots+1]=row;model:Destroy()
  end
 end
end
fs.writeFile(out..'/Visual.json',serde.encode('json',report))
fs.writeDir('Reviews/enemies-batch1-1')
fs.writeFile('Reviews/enemies-batch1-1/Rig-Reference.json',serde.encode('json',reference))
print('Exported 24 labeled before/after pose snapshots; native art acceptance remains pending')
