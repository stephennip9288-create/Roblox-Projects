-- Optional review-only exporter. Never serializes or edits a native place.
-- Extract the parent #21 server/shared sources to Validation/MapBatch1/BeforeSource first.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader') local out='Validation/MapBatch1'
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl')) local f=loader.install(dm)
 for _,group in ipairs({'server','shared'}) do
  local files=fs.readDir(out..'/BeforeSource/'..group) assert(#files>10,'Parent extraction is incomplete')
  for _,file in ipairs(files) do
   local module=f[group]:FindFirstChild(file:gsub('%.server%.lua$',''):gsub('%.lua$',''))
   assert(module,'Missing retained parent module '..file);module.Source=fs.readFile(out..'/BeforeSource/'..group..'/'..file)
  end
 end
 local load=loader.new(dm) local map=load(f.server.MapBuilder).build(id)
 assert(not map.model:GetAttribute('Batch1MapRevision'),'Parent export must not use Batch 1 sources')
 local data={id=id,scale=map.scale,layout=map.layout,floorRegions=map.floorRegions,doors={},parts={},galleries={}}
 for _,d in ipairs(map.doors) do local points={}
  for _,p in ipairs(d.waypoints) do points[#points+1]={p.X,p.Y,p.Z} end
  data.doors[#data.doors+1]={a=d.a,b=d.b,cost=d.cost,waypoints=points,cf={d.part.CFrame:GetComponents()}}
 end
 for i,room in ipairs(map.rooms) do if room.stairTop then data.galleries[#data.galleries+1]={room=i} end end
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') then
  local row={name=p.Name,class=p.ClassName,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,transparency=p.Transparency}
  if p:IsA('Part') then row.shape=p.Shape.Name end
  local gui=p:FindFirstChildOfClass('SurfaceGui')
  if gui then local label=gui:FindFirstChildOfClass('TextLabel');if label then row.text=label.Text;row.textColor={label.TextColor3.R,label.TextColor3.G,label.TextColor3.B};row.face=gui.Face.Name end end
  data.parts[#data.parts+1]=row
 end end
 fs.writeFile(out..'/Before-'..id..'.json',serde.encode('json',data))
 print('Parent #21 visual export:',id,#data.parts)
end
