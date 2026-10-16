-- Six sectors retain their IDs/objectives; footprints and connectivity are authored independently.
local L={}
L.Station={
    {x=-86,z=-12,w=60,d=68,h=25,shape="octagon",upper=true},
    {x=0,z=-32,w=78,d=78,h=27,shape="rotunda",outdoor=true},
    {x=92,z=-4,w=66,d=72,h=25,shape="hexagon"},
    {x=-84,z=92,w=72,d=78,h=27,shape="rectangle",upper=true},
    {x=0,z=94,w=78,d=74,h=27,shape="octagon"},
    {x=100,z=100,w=72,d=86,h=28,shape="hexagon"},
}
L.Foundry={
    {x=-108,z=-18,w=72,d=82,h=29,shape="octagon"},
    {x=0,z=-40,w=102,d=92,h=33,shape="hexagon",outdoor=true},
    {x=112,z=-2,w=78,d=84,h=31,shape="rotunda"},
    {x=-104,z=112,w=82,d=112,h=32,shape="rectangle",upper=true},
    {x=0,z=116,w=94,d=96,h=32,shape="octagon",upper=true},
    {x=120,z=122,w=82,d=108,h=32,shape="octagon"},
}
L.Frost={
    {x=-102,z=-18,w=72,d=86,h=28,shape="hexagon"},
    {x=0,z=-46,w=98,d=96,h=30,shape="rotunda",outdoor=true},
    {x=108,z=-6,w=74,d=86,h=28,shape="octagon"},
    {x=-100,z=114,w=84,d=112,h=29,shape="octagon"},
    {x=0,z=112,w=96,d=90,h=31,shape="hexagon",upper=true},
    {x=116,z=124,w=80,d=110,h=30,shape="rectangle",upper=true},
}
-- Each pair appears once. Diagonal links join different sectors and create two new flanking loops.
L.Links={{1,2,750,"CONCOURSE ACCESS"},{1,4,900,"WEST SERVICE PASSAGE"},{2,3,1250,"POWER ANNEX"},
    {2,5,1000,"CENTRAL SERVICE SPINE"},{4,5,750,"LOWER TRANSFER"},{5,6,1500,"FORGE ACCESS"},{3,6,1000,"EAST PROCESS PASSAGE"},
    {1,5,1100,"DIAGONAL / SIGNAL UNDERPASS"},{3,5,900,"DIAGONAL / AUXILIARY RETURN"}}
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
