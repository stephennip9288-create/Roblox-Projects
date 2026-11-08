-- Characterize strict source-ray disagreements without changing floor geometry
-- or consumer tolerances. This is not an engine raycast/physics measurement.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader');local Geometry=require('../Tests/Support/EnemyB11Geometry');local V=r.Vector3
local root='Validation/B2MapNavigation';local input=serde.decode('json',fs.readFile(root..'/After-Report.json'))
local report={engine=false,maps={},cases=0,unresolved=0}
for _,m in ipairs(input.maps) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..m.id..'.rbxl'));local f=loader.install(dm)
 local map=loader.new(dm)(f.server.MapBuilder).build(m.id)
 local world=Geometry.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local params={FilterType=r.Enum.RaycastFilterType.Include,FilterDescendantsInstances={map.model}}
 local row={id=m.id,cases={}}
 for _,group in ipairs({'corridorSupportDiagnostics','graphNodeSupportDiagnostics'}) do
  for _,p in pairs(m[group]) do
   local at=V.new(p.at[1],p.at[2],p.at[3]);local found
   for _,epsilon in ipairs({.001,.01,.05}) do
    for _,v in ipairs({V.xAxis,-V.xAxis,V.zAxis,-V.zAxis}) do
     local point=at+v*epsilon;local hit=world:Raycast(point+V.yAxis*.5,-V.yAxis*2,params)
     if hit and math.abs(hit.Position.Y-at.Y)<.03 then found={shift=epsilon,offset={v.X*epsilon,0,v.Z*epsilon},height=hit.Position.Y,part=hit.Instance.Name};break end
    end
    if found then break end
   end
   report.cases+=1;if not found then report.unresolved+=1 end
   row.cases[#row.cases+1]={group=group,id=p.id,door=p.door,at=p.at,exactRayFloor=p.floor,neighbor=found}
  end
 end
 report.maps[#report.maps+1]=row
 print(m.id,#row.cases,'exact-ray disagreements characterized')
 map.model:Destroy()
end
fs.writeFile(root..'/Support-Diagnostics.json',serde.encode('json',report))
assert(report.unresolved==0,'Unresolved broad support defect requires investigation')
print('All',report.cases,'diagnostics have adjacent real same-height support within .05 world studs; no logical fill or runtime change')
