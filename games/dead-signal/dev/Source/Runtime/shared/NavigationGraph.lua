-- Portal connectivity supports recovery/debugging. Native paths own normal pursuit.
local Layouts=require(script.Parent.MapLayouts)
local N={}
local function connect(g,a,b,door)
    table.insert(g.edges[a],{to=b,door=door}) table.insert(g.edges[b],{to=a,door=door})
end
function N.build(map)
    local g={nodes={},edges={},rooms={}}
    local function node(id,pos,room,level,kind)
        g.nodes[id]={id=id,position=pos,room=room,level=level or 0,kind=kind} g.edges[id]={} return id
    end
    for i,room in ipairs(map.rooms) do
        local center=node("room"..i,room.center,i,0,"center") g.rooms[i]={lower=center,portals={}}
        if room.stairBase then
            local base=node("stair"..i.."base",room.stairBase,i,0,"stair")
            local top=node("stair"..i.."top",room.stairTop,i,1,"stair")
            local upper=node("gallery"..i,room.upperCenter,i,1,"gallery")
            connect(g,center,base) connect(g,base,top) connect(g,top,upper)
            g.rooms[i].upper=upper g.rooms[i].rise=room.rise g.rooms[i].stairBase=base g.rooms[i].stairTop=top
        end
    end
    for i,d in ipairs(map.doors) do
        local ids={}
        for n,pos in ipairs(d.waypoints or {d.position}) do
            local room=n<=2 and d.a or d.b
            ids[n]=node("door"..i.."p"..n,pos,room,0,"portal")
            if n>1 then connect(g,ids[n-1],ids[n],n==3 and d or nil) end
        end
        table.insert(g.rooms[d.a].portals,ids[1]) table.insert(g.rooms[d.b].portals,ids[#ids])
    end
    for i,room in ipairs(g.rooms) do
        local anchors={room.lower} if room.stairBase then anchors[#anchors+1]=room.stairBase end
        for _,id in ipairs(room.portals) do anchors[#anchors+1]=id end
        for a=1,#anchors do for b=a+1,#anchors do connect(g,anchors[a],anchors[b]) end end
    end
    map.navigation=g return g
end
function N.locate(map,pos)
    local s=map.scale
    for i,r in ipairs(map.layout) do if Layouts.contains(r,pos.X/s,pos.Z/s) then
        local room=map.navigation.rooms[i] return i,room.upper and pos.Y>=room.rise-.5 and 1 or 0
    end end
    local best,distance
    for _,n in pairs(map.navigation.nodes) do if n.level==0 then
        local d=(pos-n.position).Magnitude if not distance or d<distance then best=n.room distance=d end
    end end return best or 1,0
end
function N.route(map,start,target)
    local g=map.navigation if not g then return {} end
    local from,fl=N.locate(map,start) local to,tl=N.locate(map,target)
    if from==to and fl==tl then return {} end
    local cost={} local previous={} local done={}
    for key,n in pairs(g.nodes) do if n.room==from and n.level==fl and n.kind~="center" and (fl==0 or n.kind=="gallery" or n.kind=="stair") then cost[key]=(start-n.position).Magnitude end end
    local best,finishCost
    while true do
        local cur,minimum
        for key,value in pairs(cost) do if not done[key] and (not minimum or value<minimum) then cur=key minimum=value end end
        if not cur or finishCost and minimum>finishCost then break end done[cur]=true
        local n=g.nodes[cur]
        if n.room==to and n.level==tl then
            local full=minimum+(target-n.position).Magnitude
            if not finishCost or full<finishCost then best=cur finishCost=full end
        end
        for _,edge in ipairs(g.edges[cur]) do
            local dest=g.nodes[edge.to]
            if dest.kind~="center" and (not edge.door or edge.door.open) and map.rooms[dest.room].unlocked then
                local nextCost=minimum+(n.position-dest.position).Magnitude
                if not cost[edge.to] or nextCost<cost[edge.to] then cost[edge.to]=nextCost previous[edge.to]=cur end
            end
        end
    end
    if not best then return nil end
    local sequence={} local cur=best
    while cur do table.insert(sequence,1,g.nodes[cur].position) cur=previous[cur] end
    return sequence
end
function N.reached(pos,goal,height)
    local delta=goal-pos return Vector3.new(delta.X,0,delta.Z).Magnitude<1.7 and math.abs(delta.Y)<(height or 2)
end
return N
