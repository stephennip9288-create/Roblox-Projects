-- Reproducible source geometry evidence only. Never writes a place/native asset.
-- BeforeSource is extracted from parent #20 (5336149) by the reviewer.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader')
local folder='Validation/WeaponsBatch1'
local out={baseline='533614972cd0c17212203d3099202f534a75aed8',models={},ads={},engineRender=false}
local function geometry(model)
 local parts={} local lo=r.Vector3.new(math.huge,math.huge,math.huge) local hi=-lo
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p.Transparency<.95 and p.LocalTransparencyModifier<.95 then
  local corners={}
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=p.CFrame:PointToWorldSpace(r.Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2))
   lo=r.Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
   hi=r.Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
   corners[#corners+1]={v.X,v.Y,v.Z}
  end end end
  parts[#parts+1]={name=p.Name,corners=corners,nativeMesh=p:IsA('MeshPart'),color={p.Color.R,p.Color.G,p.Color.B}}
 end end
 if #parts==0 then lo=r.Vector3.zero hi=r.Vector3.zero end
 return {parts=parts,min={lo.X,lo.Y,lo.Z},max={hi.X,hi.Y,hi.Z},size={hi.X-lo.X,hi.Y-lo.Y,hi.Z-lo.Z}}
end
for _,version in ipairs({'before','after'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl')) local f=loader.install(dm)
 if version=='before' then for _,name in ipairs({'WeaponModels','WeaponBlueprints','WeaponDetail'}) do
  f.shared:FindFirstChild(name).Source=fs.readFile(folder..'/BeforeSource/'..name..'.lua')
 end end
 local load=loader.new(dm) local W=load(f.shared.WeaponModels) local C=load(f.shared.Config) local B=load(f.shared.WeaponBlueprints)
 local ids={} for id in pairs(C.Weapons) do ids[#ids+1]=id end table.sort(ids)
 for _,id in ipairs(ids) do for tier=0,3 do
  local model=W.build(id,'Factory',tier,nil,false);W.aim(model,false,0) local g=geometry(model)
  g.weapon=id g.version=version g.tier=tier g.action=B[id].action g.reloadStyle=B[id].reloadStyle
  g.optic=B[id].optic or (W.scoped(id) and 'scope' or 'iron') g.sightHeight=W.aimHeight(id)
  out.models[#out.models+1]=g model:Destroy()
 end end
 if version=='after' then for _,id in ipairs({'Kestrel','Vandal','Longwatch'}) do
  for _,size in ipairs({{568,280},{360,740},{3440,1440}}) do
   local model=W.build(id,'Factory',3,nil,true) local fov=W.aimFov(id)
   model:PivotTo(r.CFrame.new(W.viewOffset(id,r.Vector3.new(.64,-.67,-1.1),1,fov,r.Vector2.new(size[1],size[2]))))
   W.pose(model,0,0,0,0);W.aim(model,W.scoped(id),1)
   local g=geometry(model);g.weapon=id;g.viewport=size;g.fov=fov;g.optic=W.optic(id)
   out.ads[#out.ads+1]=g model:Destroy()
  end
 end end
end
fs.writeFile(folder..'/Geometry.json',serde.encode('json',out))
print('Exported 160 before/after wall models and nine ADS geometry projections. No engine renders or native changes.')
