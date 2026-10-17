-- Optional offline visual exporter. Does not serialize or rewrite a place binary.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader')
local folder='Validation/MapRemaster'
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl')) local f=loader.install(dm)
 -- Baseline sources are extracted from the recorded starting SHA by the reviewer.
 for _,group in ipairs({'server','shared'}) do
  local dir=folder..'/BeforeSource/'..group
  for _,file in ipairs(fs.readDir(dir)) do
   local module=f[group]:FindFirstChild(file:gsub('%.lua$',''))
   assert(module,'Baseline module missing');module.Source=fs.readFile(dir..'/'..file)
  end
 end
 local load=loader.new(dm) local M=load(f.server.MapBuilder) local map=M.build(id)
 local out={id=id,scale=map.scale,layout=map.layout,parts={},doors={}}
 for _,door in ipairs(map.doors) do out.doors[#out.doors+1]={cf={door.part.CFrame:GetComponents()}} end
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then
  local row={name=p.Name,class=p.ClassName,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,variant=p.MaterialVariant,transparency=p.Transparency}
  if p:IsA('Part') then row.shape=p.Shape.Name end
  if p:FindFirstChildOfClass('SpecialMesh') then row.shape='Ball' end
  local gui=p:FindFirstChildOfClass('SurfaceGui')
  if gui then local label=gui:FindFirstChildOfClass('TextLabel');if label then row.text=label.Text;row.textColor={label.TextColor3.R,label.TextColor3.G,label.TextColor3.B};row.face=gui.Face.Name end end
  out.parts[#out.parts+1]=row
 end end
 fs.writeFile(folder..'/Before-'..id..'.json',serde.encode('json',out))
 print('Baseline visual export: '..id..' / '..#out.parts..' parts')
end
