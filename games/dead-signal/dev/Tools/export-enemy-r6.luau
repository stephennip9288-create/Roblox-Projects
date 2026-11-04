-- Offline source review only: part bounds, six-joint poses and vector GUI marks.
-- Optional before source: c80d55aeeae4b51ef8d836949a33bf440890c6b7 modules
-- in Validation/EnemyB1Followup/BeforeSource/{server,shared}/.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local process=require('@lune/process');local loader=require('../Tests/Support/RuntimeLoader')
local out='Validation/EnemyB1Followup';fs.writeDir(out)
local report={engine=false,source=process.args[1] or 'working',before='c80d55aeeae4b51ef8d836949a33bf440890c6b7',
 render='orthographic part bounds and original vector marks; no engine materials, mesh triangles or lighting',families={},comparisons={},budgets={}}
local function vec(v) return {v.X,v.Y,v.Z} end
local function snapshot(R,P,map,kind,id,action)
 local m,root,hum=R.build(nil,kind,r.Vector3.zero,id,map)
 R.evolve({id=id,kind=kind,model=m,root=root,hum=hum,mods={}})
 root.AssemblyLinearVelocity=r.Vector3.new(0,0,action=='run' and -12 or 0)
 if action=='attack' then m:SetAttribute('AttackAt',100) end
 if action=='climb' then
  m:SetAttribute('TraversalStage','Cross');m:SetAttribute('TraversalStyle','Vault')
  m:SetAttribute('TraversalStageAt',100);m:SetAttribute('TraversalStageDuration',1)
 end
 local frames=P.frames(m,P.sample(m,root,100.5))
 local function frame(p)
  if frames[p] then return frames[p] end
  local weld=p:FindFirstChildOfClass('WeldConstraint')
  if weld and weld.Part0 then return frame(weld.Part0)*weld.Part0.CFrame:ToObjectSpace(p.CFrame) end
  return root.CFrame:ToObjectSpace(p.CFrame)
 end
 local row={map=map,kind=kind,id=id,action=action,role=m:GetAttribute('InfectedRole'),parts={},guis={},counts={parts=0,instances=0,motors=0,frames=0,meshes=0}}
 for _,p in ipairs(m:GetDescendants()) do
  row.counts.instances+=1
  if p:IsA('BasePart') then
   row.counts.parts+=1;if p:IsA('MeshPart') then row.counts.meshes+=1 end
   if p.Transparency<.95 then row.parts[#row.parts+1]={name=p.Name,cf={frame(p):GetComponents()},size=vec(p.Size),color={p.Color.R,p.Color.G,p.Color.B},mesh=p:IsA('MeshPart'),round=p:IsA('Part') and p.Shape==r.Enum.PartType.Ball or p:FindFirstChildOfClass('CylinderMesh')~=nil} end
  elseif p:IsA('Motor6D') then row.counts.motors+=1
  elseif p:IsA('Frame') then row.counts.frames+=1
  elseif p:IsA('SurfaceGui') then
   local b=p.Adornee or p.Parent
   if b and b:IsA('BasePart') and p.Face==r.Enum.NormalId.Front then
    local g={name=p.Name,cf={frame(b):GetComponents()},size=vec(b.Size),marks={}}
    for _,mark in ipairs(p:GetChildren()) do if mark:IsA('Frame') then
     g.marks[#g.marks+1]={name=mark.Name,x=mark.Position.X.Offset,y=mark.Position.Y.Offset,w=mark.Size.X.Offset,h=mark.Size.Y.Offset,
      color={mark.BackgroundColor3.R,mark.BackgroundColor3.G,mark.BackgroundColor3.B},alpha=1-mark.BackgroundTransparency,
      rotation=mark.Rotation,rounded=mark:FindFirstChildOfClass('UICorner')~=nil}
    end end
    row.guis[#row.guis+1]=g
   end
  end
 end
 m:Destroy();return row
end
for _,map in ipairs({'Station','Foundry','Frost'}) do
 for _,revision in ipairs(fs.isDir(out..'/BeforeSource') and {'before','after'} or {'after'}) do
  local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
  if revision=='before' then
   for group,names in pairs({server={'EnemyRigs','InfectedWardrobe'},shared={'NPCPose'}}) do for _,name in ipairs(names) do
    f[group][name].Source=fs.readFile(out..'/BeforeSource/'..group..'/'..name..'.lua')
   end end
  end
  local load=loader.new(dm);local R,P=load(f.server.EnemyRigs),load(f.shared.NPCPose)
  if revision=='after' then for id=1,18 do
   local row=snapshot(R,P,map,'Shambler',id,'idle');report.budgets[#report.budgets+1]={map=map,id=id,counts=row.counts}
   if id<=6 then report.families[#report.families+1]=row end
  end end
  for _,spec in ipairs({{'idle','Shambler',1},{'run','Runner',2},{'attack','Shambler',4},{'climb','Warden',6}}) do
   local row=snapshot(R,P,map,spec[2],spec[3],spec[1]);row.revision=revision;report.comparisons[#report.comparisons+1]=row
  end
 end
end
fs.writeFile(out..'/Visual.json',serde.encode('json',report))
print('Exported R6 source geometry/vector art; native Studio appearance and motion remain pending')
