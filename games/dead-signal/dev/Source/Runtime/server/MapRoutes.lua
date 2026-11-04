-- Additive recovery links use the existing room/level/node/edge contracts.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Layouts=require(RS.DeadSignal.MapLayouts)
local R={}
-- Three optional flank links use real low cover and a supported service pad.
-- Main circulation stays open; the pad also has a normal no-jump side ramp.
function R.traversalPads(map)
    local s=map.scale or 1 local room,layout,roomIndex
    local colliders={}
    for _,p in ipairs(map.model:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide and p.CollisionGroup~="DeadSignalBounds" then
        local half=p.Size*.5 local cf=p.CFrame
        local extent=Vector3.new(math.abs(cf.RightVector.X)*half.X+math.abs(cf.UpVector.X)*half.Y+math.abs(cf.LookVector.X)*half.Z,
            math.abs(cf.RightVector.Y)*half.X+math.abs(cf.UpVector.Y)*half.Y+math.abs(cf.LookVector.Y)*half.Z,
            math.abs(cf.RightVector.Z)*half.X+math.abs(cf.UpVector.Z)*half.Y+math.abs(cf.LookVector.Z)*half.Z)
        if cf.Position.Y+extent.Y>.2*s and cf.Position.Y-extent.Y<13*s then
            colliders[#colliders+1]={min=cf.Position-extent,max=cf.Position+extent}
        end
    end end
    local origin,frame,reservation
    for _,candidateRoom in ipairs({2,3,6,1,4,5}) do
        room=map.rooms[candidateRoom] layout=map.layout[candidateRoom]
        for _,yaw in ipairs({0,math.pi/2}) do
            for _,dx in ipairs({0,.18,-.18,.30,-.30}) do
                for _,dz in ipairs({0,.18,-.18,.30,-.30}) do
                    local at=room.center+Vector3.new(dx*layout.w,0,dz*layout.d)*s
                    local cf=CFrame.new(at)*CFrame.Angles(0,yaw,0)
                    local lo=Vector3.new(math.huge,0,math.huge) local hi=Vector3.new(-math.huge,13*s,-math.huge) local free=true
                    for _,x in ipairs({-15,24}) do for _,z in ipairs({-13,10}) do
                        local point=cf:PointToWorldSpace(Vector3.new(x,0,z)*s)
                        if not Layouts.contains(layout,point.X/s,point.Z/s,2/s) then free=false end
                        lo=Vector3.new(math.min(lo.X,point.X),0,math.min(lo.Z,point.Z))
                        hi=Vector3.new(math.max(hi.X,point.X),13*s,math.max(hi.Z,point.Z))
                    end end
                    for _,zone in ipairs(map.interactionZones or {}) do
                        if lo.X<zone.maxX and hi.X>zone.minX and lo.Z<zone.maxZ and hi.Z>zone.minZ then free=false break end
                    end
                    if free then for _,box in ipairs(colliders) do
                        if lo.X<box.max.X and hi.X>box.min.X and lo.Z<box.max.Z and hi.Z>box.min.Z then free=false break end
                    end end
                    if free then origin=at frame=cf roomIndex=candidateRoom reservation={minX=lo.X,maxX=hi.X,minZ=lo.Z,maxZ=hi.Z,minY=-1,maxY=13*s} break end
                end
                if origin then break end
            end
            if origin then break end
        end
        if origin then break end
    end
    assert(origin,"No clear authored traversal bay: "..map.id)
    local folder=U.make("Folder",room.model,{Name="TraversalServiceBay"})
    local color=map.id=="Foundry" and Color3.fromRGB(104,89,70) or map.id=="Frost" and Color3.fromRGB(118,136,140) or Color3.fromRGB(94,105,88)
    local function part(name,size,offset,material,rotation,class)
        local p=U.make(class or "Part",folder,{Name=name,Size=size*s,CFrame=frame*CFrame.new(offset*s)*(rotation or CFrame.identity),
            Color=color,Material=material or Enum.Material.Concrete,Anchored=true,CanCollide=true,CanTouch=false,CanQuery=true})
        p:SetAttribute("ContextTraversal",true) return p
    end
    local hurdle=part("LowServiceDivider",Vector3.new(8,1.25,1.3),Vector3.new(-8,.625,0),Enum.Material.Metal)
    local pad=part("ServicePad",Vector3.new(8,2,10),Vector3.new(8,1,1))
    local ramp=part("ServicePadRamp",Vector3.new(7,2,8),Vector3.new(16,1,1),Enum.Material.Concrete,CFrame.Angles(0,-math.pi/2,0),"WedgePart")
    for _,p in ipairs({pad,ramp}) do map.floorParts[#map.floorParts+1]=p end
    map.routeObstacles[#map.routeObstacles+1]=hurdle
    for _,p in ipairs({hurdle,pad}) do
        local strip=U.make("Part",folder,{Name="ServiceEdgeMark",Size=Vector3.new(p.Size.X,.04*s,.12*s),CFrame=p.CFrame*CFrame.new(0,p.Size.Y/2+.025*s,-p.Size.Z/2),
            Color=Color3.fromRGB(181,166,111),Material=Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false})
        strip:SetAttribute("ContextTraversal",true)
    end
    local function point(x,y,z) return frame:PointToWorldSpace(Vector3.new(x,y,z)*s) end
    local kinds={Shambler=true,Runner=true,Crawler=true,Hound=true,Stalker=true,Warden=true}
    local function link(id,kind,a,b,contact,rise)
        return {schema=1,id=map.id.."_"..id,kind=kind,room=roomIndex,approach=a,landing=b,contact=contact,
            width=8*s,height=9.3*s,rise=rise*s,kinds=kinds}
    end
    map.traversals={link("divider","LowVault",point(-8,0,-5),point(-8,0,5),point(-8,0,0),1.7),
        link("service_up","Ledge",point(8,0,-10),point(8,2,2),point(8,0,-4),2.35),
        link("service_down","Ledge",point(8,2,2),point(8,0,-10),point(8,2,-4),0)}
    map.traversalBay={origin=origin,frame=frame,room=roomIndex,folder=folder,pad=pad,ramp=ramp,hurdle=hurdle}
    map.interactionZones[#map.interactionZones+1]=reservation
end
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
    R.traversalPads(map)
end
return R
