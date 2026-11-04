-- Six sectors retain their IDs/objectives; footprints and connectivity are authored independently.
local L={}
-- Local -Z faces the usable room. Tangent/up/outward is a reflection on a
-- counter-clockwise footprint; derive X from Y cross Z instead.
function L.wallFrame(position,outward)
    local back=Vector3.new(outward.X,0,outward.Z).Unit local up=Vector3.yAxis
    return CFrame.fromMatrix(position,up:Cross(back),up,back)
end
-- Independent facility blockouts: bent bunker wings, industrial crescent, polar listening spine.
-- Sector IDs and purchased connectivity remain the same as parent #21.
L.Station={
    {x=-112,z=-68,w=88,d=112,h=24,shape="bastion",purpose="Checkpoint and triage"},
    {x=8,z=-26,w=90,d=100,h=26,shape="hexagon",outdoor=true,purpose="Antenna switching field"},
    {x=126,z=18,w=84,d=96,h=26,shape="octagon",chamfer=.23,purpose="Diesel generation"},
    {x=-158,z=108,w=98,d=130,h=29,shape="bastion",upper=true,purpose="Field repair and stores"},
    {x=-14,z=148,w=102,d=102,h=30,shape="hexagon",upper=true,purpose="Carrier control watch"},
    {x=124,z=176,w=88,d=118,h=28,shape="octagon",chamfer=.21,purpose="Signal analysis lab"},
}
L.Foundry={
    {x=-158,z=-18,w=88,d=84,h=28,shape="octagon",chamfer=.18,purpose="Shift clock and PPE"},
    {x=-22,z=-82,w=126,d=100,h=38,shape="hexagon",outdoor=true,purpose="Rail and casting yard"},
    {x=132,z=-6,w=92,d=120,h=36,shape="bastion",purpose="Boiler pressure house"},
    {x=-126,z=172,w=106,d=160,h=36,shape="hexagon",upper=true,purpose="Machine hall catwalk"},
    {x=22,z=132,w=120,d=112,h=36,shape="octagon",chamfer=.22,upper=true,purpose="Furnace dispatch gallery"},
    {x=188,z=182,w=108,d=136,h=36,shape="octagon",chamfer=.20,purpose="Metallurgy and crucibles"},
}
L.Frost={
    {x=-146,z=-52,w=90,d=94,h=25,shape="hexagon",purpose="Polar arrival and deicing"},
    {x=-22,z=-126,w=116,d=106,h=28,shape="rotunda",outdoor=true,purpose="Ice apron and rescue"},
    {x=130,z=-50,w=88,d=104,h=28,shape="hexagon",purpose="Reactor thermal plant"},
    {x=-174,z=146,w=104,d=130,h=27,shape="bastion",purpose="Storm supply depot"},
    {x=-24,z=100,w=106,d=106,h=32,shape="rotunda",upper=true,purpose="Listening array watch"},
    {x=166,z=172,w=96,d=130,h=30,shape="hexagon",upper=true,purpose="Cryogenic research stacks"},
}
-- Each pair appears once. Diagonal links join different sectors and create two new flanking loops.
L.Links={{1,2,750,"CONCOURSE ACCESS"},{1,4,900,"WEST SERVICE PASSAGE"},{2,3,1250,"POWER ANNEX"},
    {2,5,1000,"CENTRAL SERVICE SPINE"},{4,5,750,"LOWER TRANSFER"},{5,6,1500,"FORGE ACCESS"},{3,6,1000,"EAST PROCESS PASSAGE"},
    {1,5,1100,"DIAGONAL / SIGNAL UNDERPASS"},{3,5,900,"DIAGONAL / AUXILIARY RETURN"}}
-- Preserve the seven progression purchases. Each site authors its optional flanking loops.
function L.links(id)
    if id~="Foundry" and id~="Frost" then return L.Links end
    local links={} for i=1,7 do links[i]=L.Links[i] end
    links[8]=id=="Foundry" and {2,4,1100,"GANTRY TRANSFER"} or {1,5,1100,"LISTENING TUNNEL"}
    links[9]=id=="Foundry" and {3,5,900,"BOILER RETURN"} or {2,6,900,"EAST AIRLOCK"}
    return links
end
L.Windows={{1,"N"},{1,"W"},{2,"N"},{3,"N"},{3,"E"},{4,"S"},{4,"W"},{5,"S"},{6,"S"},{6,"E"}}
-- Keep the polar reactor return east of the long listening tunnel; their walls must not cross.
L.PortalHints={Frost={[7]={a={1,1},b={1,-1}},[9]={a={1,1},b={-1,-1}}}}
-- Door order/prices are unchanged; each entry supplies an original visual obstruction.
L.Barriers={
 Station={{"Rubble","CHECKPOINT DEBRIS"},{"Rubble","COLLAPSED MASONRY"},{"Bulkhead","GENERATOR SHUTTER"},
  {"Machinery","FALLEN CABLE RACK"},{"Bulkhead","BLAST BULKHEAD"},{"Rubble","SERVICE CAVE-IN"},
  {"Machinery","GENERATOR WRECK"},{"Gantry","BROKEN AERIAL"},{"Cargo","SEALED FIELD STORES"}},
 Foundry={{"Cargo","STEEL PALLET STACK"},{"Gantry","COLLAPSED GANTRY"},{"Bulkhead","FURNACE BULKHEAD"},
  {"Machinery","SLAG HOPPER"},{"Bulkhead","FREIGHT SHUTTER"},{"Cargo","ROLLED STEEL LOAD"},
  {"Machinery","DERAILED TRANSFER"},{"Gantry","PIPE TRANSFER"},{"Machinery","BOILER MACHINERY"}},
 Frost={{"Ice","ICED PRESSURE DOOR"},{"Ice","ICE FALL"},{"Bulkhead","SAFETY BULKHEAD"},
  {"Gantry","COLLAPSED MAST"},{"Cargo","FROZEN CARGO"},{"Bulkhead","CRYO SHUTTER"},
  {"Machinery","SNOWBOUND HAULER"},{"Ice","LISTENING TUNNEL ICE"},{"Bulkhead","RESEARCH BULKHEAD"}},
}
function L.polygon(r)
    local w,d=r.w/2,r.d/2 local shape=r.shape local v={}
    if shape=="bastion" then
        return {{-w*.55,-d},{w*.9,-d*.8},{w,d*.45},{w*.5,d},{-w*.6,d},{-w,d*.4},{-w,-d*.5}}
    end
    if shape=="rectangle" then return {{-w,-d},{w,-d},{w,d},{-w,d}} end
    if shape=="hexagon" then return {{-w*.50,-d},{w*.50,-d},{w,0},{w*.50,d},{-w*.50,d},{-w,0}} end
    if shape=="rotunda" then
        for n=0,11 do local a=-math.pi/2-math.pi/12+n*math.pi/6 v[#v+1]={math.cos(a)*w,math.sin(a)*d} end
        return v
    end
    local cut=r.chamfer or .4
    return {{-w*(1-cut),-d},{w*(1-cut),-d},{w,-d*(1-cut)},{w,d*(1-cut)},
        {w*(1-cut),d},{-w*(1-cut),d},{-w,d*(1-cut)},{-w,-d*(1-cut)}}
end
function L.contains(r,x,z,margin)
    margin=margin or 0 local p=L.polygon(r)
    for i,a in ipairs(p) do local b=p[i%#p+1] local dx,dz=b[1]-a[1],b[2]-a[2]
        if dx*(z-r.z-a[2])-dz*(x-r.x-a[1])<margin*math.sqrt(dx*dx+dz*dz) then return false end
    end return true
end
function L.inset(r,x,z,margin)
    -- Pull authored object centers inside the new footprint; retain their intended side.
    for _=1,40 do if L.contains(r,x,z,margin or 5) then return x,z end x=r.x+(x-r.x)*.93 z=r.z+(z-r.z)*.93 end
    return r.x,r.z
end
function L.bounds(layout)
    local b={minX=math.huge,maxX=-math.huge,minZ=math.huge,maxZ=-math.huge}
    for _,r in ipairs(layout) do b.minX=math.min(b.minX,r.x-r.w/2) b.maxX=math.max(b.maxX,r.x+r.w/2) b.minZ=math.min(b.minZ,r.z-r.d/2) b.maxZ=math.max(b.maxZ,r.z+r.d/2) end
    return b
end
return L
