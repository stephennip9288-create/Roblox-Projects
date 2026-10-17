-- Six sectors retain their IDs/objectives; footprints and connectivity are authored independently.
local L={}
-- Blackwater: compact rectilinear station blocks, one maintenance watch gallery.
L.Station={
    {x=-94,z=-14,w=78,d=106,h=22,shape="rectangle"},
    {x=0,z=-20,w=72,d=70,h=24,shape="rectangle",outdoor=true},
    {x=88,z=-8,w=62,d=84,h=23,shape="rectangle"},
    {x=-96,z=130,w=82,d=124,h=25,shape="rectangle",upper=true},
    {x=0,z=100,w=70,d=80,h=24,shape="octagon"},
    {x=94,z=118,w=72,d=106,h=25,shape="rectangle"},
}
L.Foundry={
    {x=-126,z=-24,w=84,d=68,h=27,shape="rectangle"},
    {x=0,z=-34,w=122,d=96,h=36,shape="rectangle",outdoor=true},
    {x=132,z=-14,w=84,d=104,h=34,shape="rectangle"},
    {x=-126,z=138,w=84,d=150,h=32,shape="rectangle",upper=true},
    {x=0,z=134,w=112,d=110,h=35,shape="rectangle",upper=true},
    {x=144,z=158,w=98,d=138,h=34,shape="octagon"},
}
L.Frost={
    {x=-108,z=-32,w=78,d=82,h=23,shape="hexagon"},
    {x=0,z=-64,w=102,d=104,h=27,shape="octagon",outdoor=true},
    {x=124,z=-26,w=78,d=100,h=25,shape="hexagon"},
    {x=-104,z=128,w=94,d=116,h=24,shape="octagon"},
    {x=14,z=122,w=96,d=100,h=30,shape="rotunda",upper=true},
    {x=148,z=150,w=84,d=116,h=26,shape="hexagon"},
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
function L.polygon(r)
    local w,d=r.w/2,r.d/2 local shape=r.shape local v={}
    if shape=="rectangle" then return {{-w,-d},{w,-d},{w,d},{-w,d}} end
    if shape=="hexagon" then return {{-w*.50,-d},{w*.50,-d},{w,0},{w*.50,d},{-w*.50,d},{-w,0}} end
    if shape=="rotunda" then
        for n=0,11 do local a=-math.pi/2-math.pi/12+n*math.pi/6 v[#v+1]={math.cos(a)*w,math.sin(a)*d} end
        return v
    end
    local cut=.4
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
