-- Additive recovery links use the existing room/level/node/edge contracts.
local R={}
function R.apply(map,_P,_S)
    local g=map.navigation
    local function node(id,position,room,level,kind)
        g.nodes[id]={id=id,position=position,room=room,level=level,kind=kind} g.edges[id]={} return id
    end
    local function edge(a,b)
        table.insert(g.edges[a],{to=b}) table.insert(g.edges[b],{to=a})
    end
    for i,room in ipairs(map.rooms) do if room.upperRing then
        local ids={}
        for n,position in ipairs(room.upperRing) do ids[n]=node("service"..i.."_"..n,position,i,1,"gallery") end
        for n,id in ipairs(ids) do edge(id,ids[n%#ids+1]) end
        local function nearest(position)
            local best,distance
            for _,id in ipairs(ids) do local d=(g.nodes[id].position-position).Magnitude if not distance or d<distance then best=id distance=d end end
            return best
        end
        edge("gallery"..i,nearest(room.upperCenter))
        edge("stair"..i.."top",nearest(room.stairTop))
        for n,stair in ipairs(room.stairs) do if n>1 then
            local base=node("return"..i.."_"..n.."base",stair.base,i,0,"stair")
            local top=node("return"..i.."_"..n.."top",stair.top,i,1,"stair")
            edge(base,top) edge(top,nearest(stair.top)) edge(base,g.rooms[i].lower)
            for _,portal in ipairs(g.rooms[i].portals) do edge(base,portal) end
        end end
    end end
    map.routeObstacles={} map.navigationRevision=9
end
return R
