local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local L=require('../Tests/Support/RuntimeLoader');local G=require('../Tests/Support/EnemyB11Geometry');local V=r.Vector3
local out={engine=false,cases=0,failures={},maps={}}
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local f=L.install(dm);local map=L.new(dm)(f.server.MapBuilder).build(id)
 for _,d in ipairs(map.doors)do d.part.CanCollide=false;d.open=true end
 local world=G.world({model=map.model,floorParts=map.floorParts,floorRegions={}})
 local load=L.new(dm,{globals={workspace=world,RaycastParams={new=function()return{}end},OverlapParams={new=function()return{}end}}})
 local N=load(f.server.Navigation);local Rigs=load(f.server.EnemyRigs);local folder=r.Instance.new('Folder');local owner={ctx={map=map,players={}},list={},folder=folder};local row={id=id,cases=0,failed=0}
 for si,spec in ipairs({{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}})do
  local model,root,hum=Rigs.build(folder,spec[1],V.zero,si,id);local e={id=si,kind=spec[1],model=model,root=root,hum=hum,mods=spec[2]};Rigs.evolve(e);owner.list={[si]=e};local b=N.rigBounds(e,'Walk','Approach')
  for di,d in ipairs(map.doors)do for corner=2,3 do
   local at=d.waypoints[corner]+V.yAxis*N.rootHeight(e);local incoming=(d.waypoints[corner]-d.waypoints[corner-1]).Unit;local outgoing=(d.waypoints[corner+1]-d.waypoints[corner]).Unit
   for _,reverse in ipairs({false,true})do for sample=0,24 do
    local forward=incoming:Lerp(outgoing,sample/24).Unit;if reverse then forward=-forward end
    local ok=N.traversalClear(owner,e,at,at,nil,true,b,forward);out.cases+=1;row.cases+=1
    if not ok then row.failed+=1;out.failures[#out.failures+1]={map=id,door=di,corner=corner,kind=e.kind,alpha=spec[2].Alpha==true,sample=sample,reverse=reverse,part=world.lastBlock and world.lastBlock:GetFullName()}end
   end end
  end end
  model:Destroy()
 end
 print(id,row.cases,row.failed);out.maps[#out.maps+1]=row;map.model:Destroy();folder:Destroy()
end
fs.writeFile('Validation/B2MapNavigation/Turns.json',serde.encode('json',out));assert(#out.failures==0,'Turn envelope blockers require review')
