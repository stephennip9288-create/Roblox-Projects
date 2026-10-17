local RS=game:GetService("ReplicatedStorage")
local Layouts=require(RS.DeadSignal.MapLayouts)
local U=require(RS.DeadSignal.Util)
local A={} local UP=Vector3.new(0,1,0)
local function rotation(tangent) return CFrame.fromMatrix(Vector3.zero,tangent,UP,tangent:Cross(UP)) end
function A.build(map,layout,P,S,light,def)
    local s=map.scale local concrete=Color3.fromRGB(111,108,93) local steel=Color3.fromRGB(50,60,59)
    map.areas={} map.floorParts={} map.layout=layout map.corridors={} map.floorRegions={}
    local wallMaterial=def.theme=="Station" and Enum.Material.Brick or def.theme=="Foundry" and Enum.Material.CorrodedMetal or Enum.Material.Metal
    local edges={} local portals={}
    local function area(poly,room,door,ymin,ymax)
        local a={room=room,door=door,minX=math.huge,maxX=-math.huge,minZ=math.huge,maxZ=-math.huge,minY=ymin or -1,maxY=ymax or 18*s,polygon={}}
        for _,v in ipairs(poly) do
            local q=v*s a.minX=math.min(a.minX,q.X) a.maxX=math.max(a.maxX,q.X) a.minZ=math.min(a.minZ,q.Z) a.maxZ=math.max(a.maxZ,q.Z)
            a.polygon[#a.polygon+1]={q.X,q.Z}
        end map.areas[#map.areas+1]=a return a
    end
    local function triangle(name,pa,pb,pc,y,parent)
        local edge=pc-pb local length=edge.Magnitude if length<.01 then return end
        local foot=pb+edge.Unit*(pa-pb):Dot(edge.Unit)
        local height=(pa-foot).Magnitude if height<.01 then return end
        for _,endPoint in ipairs({pb,pc}) do
            local len=(endPoint-foot).Magnitude
            if len>.015 then
                local up=(pa-foot).Unit local back=(foot-endPoint).Unit local right=up:Cross(back)
                local cf=CFrame.fromMatrix(Vector3.zero,right,up,back)
                local q=P(name,Vector3.new(1,height,len),(pa+endPoint)*.5+Vector3.new(0,y-.5,0),U.color(def.floor),Enum.Material.Concrete,true,cf,"WedgePart")
                q.Parent=parent or map.model map.floorParts[#map.floorParts+1]=q
            end
        end
    end
    local function polygonFloor(name,poly,y,parent)
        -- Convex room or corridor quad; exact triangular floor slabs, no rectangular backing.
        local center=Vector3.zero for _,v in ipairs(poly) do center+=v end center/=#poly
        for i,a in ipairs(poly) do triangle(name,center,a,poly[i%#poly+1],y,parent) end
        if y==0 then local p={} for _,v in ipairs(poly) do p[#p+1]={v.X*s,v.Z*s} end map.floorRegions[#map.floorRegions+1]=p end
    end
    for i,r in ipairs(layout) do
        local room=U.make("Model",map.model,{Name=def.rooms[i]}) local polygon={} edges[i]={}
        for _,v in ipairs(Layouts.polygon(r)) do polygon[#polygon+1]=Vector3.new(r.x+v[1],0,r.z+v[2]) end
        for n,a in ipairs(polygon) do
            local b=polygon[n%#polygon+1] local tangent=(b-a).Unit
            edges[i][n]={a=a,b=b,mid=(a+b)*.5,tangent=tangent,normal=Vector3.new(tangent.Z,0,-tangent.X),length=(b-a).Magnitude,slots={}}
        end
        map.rooms[i]={model=room,center=Vector3.new(r.x,0,r.z)*s,unlocked=i==1,name=def.rooms[i],width=r.w*s,depth=r.d*s,height=r.h*s,polygon=polygon,shape=r.shape,wallFaces={}}
        polygonFloor("SectorFloor",polygon,0,room) area(polygon,i,nil,-1,(r.h-.5)*s)
        room:SetAttribute("Footprint",r.shape) room:SetAttribute("SectorId",i)
    end
    local function edgeFor(room,direction,width,kind)
        local best,score
        for _,e in ipairs(edges[room]) do
            local limit=e.length/2-width/2-2
            if limit>=0 then
                local preferred=math.clamp((map.rooms[room].center/s+direction-e.mid):Dot(e.tangent),-limit,limit)
                local candidates={preferred,0,-limit,limit}
                for offset=-limit,limit,2 do candidates[#candidates+1]=offset end
                for _,offset in ipairs(candidates) do
                    local clear=true
                    for _,slot in ipairs(e.slots) do if math.abs(offset-slot.offset)<(width+slot.width)/2+4 then clear=false break end end
                    local value=e.normal:Dot(direction.Unit)*100-math.abs(offset-preferred)*.1
                    if clear and (not score or value>score) then
                        best={edge=e,mid=e.mid+e.tangent*offset,normal=e.normal,tangent=e.tangent,offset=offset} score=value
                    end
                end
            end
        end
        assert(best,"No clear polygon edge for a portal")
        table.insert(best.edge.slots,{kind=kind,width=width,offset=best.offset,mid=best.mid,room=room})
        return best
    end
    for index,link in ipairs(Layouts.links(map.id)) do
        local a,b=map.rooms[link[1]].center/s,map.rooms[link[2]].center/s
        local ea=edgeFor(link[1],b-a,16,"door") local eb=edgeFor(link[2],a-b,16,"door")
        portals[index]={ea=ea,eb=eb,link=link}
    end
    for _,w in ipairs(Layouts.Windows) do
        local dir=w[2]=="N" and Vector3.new(0,0,-1) or w[2]=="S" and Vector3.new(0,0,1) or w[2]=="E" and Vector3.new(1,0,0) or Vector3.new(-1,0,0)
        edgeFor(w[1],dir*100,11,"window")
    end
    -- Offset polyline strips have mitered joints, closed side walls and a door on the middle leg.
    for index,p in ipairs(portals) do
        local ea,eb,link=p.ea,p.eb,p.link
        local between=eb.mid-ea.mid
        -- Short connectors must not overshoot into a 180-degree fold.
        local leadA=math.clamp(between:Dot(ea.normal)*.25,.5,8)
        local leadB=math.clamp((-between):Dot(eb.normal)*.25,.5,8)
        local path={ea.mid-ea.normal*.8,ea.mid+ea.normal*leadA,eb.mid+eb.normal*leadB,eb.mid-eb.normal*.8}
        local left,right={},{} local half=7
        for i,v in ipairs(path) do
            local prev=i>1 and (v-path[i-1]).Unit local next=i<#path and (path[i+1]-v).Unit
            local function side(dir) return Vector3.new(-dir.Z,0,dir.X) end
            local n=prev and next and (side(prev)+side(next)).Unit or side(prev or next)
            local factor=prev and next and half/math.max(.55,n:Dot(side(next))) or half
            left[i]=v+n*factor right[i]=v-n*factor
        end
        local mid=(path[2]+path[3])*.5 local direction=(path[3]-path[2]).Unit local rot=CFrame.lookAt(Vector3.zero,direction)
        local gate=P("Gate"..index,Vector3.new(14,14,.65),mid+UP*7,Color3.fromRGB(66,73,66),Enum.Material.CorrodedMetal,true,rot)
        local d={part=gate,a=link[1],b=link[2],cost=link[3],name=link[4],open=false,position=mid*s,waypoints={}}
        for _,v in ipairs(path) do d.waypoints[#d.waypoints+1]=v*s end map.doors[index]=d
        local corridor={door=d,waypoints=d.waypoints,areas={}}
        for n=1,#path-1 do
            local quad={left[n],right[n],right[n+1],left[n+1]}
            polygonFloor("CorridorFloor",quad,0)
            local ar=area(quad,nil,d,-1,17.5*s) corridor.areas[#corridor.areas+1]=ar
            for _,side in ipairs({left,right}) do
                local start,finish=side[n],side[n+1] local tangent=(finish-start).Unit local center=(start+finish)*.5
                P("CorridorWall",Vector3.new((finish-start).Magnitude,18,.9),center+UP*9,concrete,Enum.Material.Concrete,true,rotation(tangent))
                P("ServiceCableTray",Vector3.new((finish-start).Magnitude,.22,.4),center+UP*15.4,steel,Enum.Material.Metal,false,rotation(tangent))
            end
            local center=(path[n]+path[n+1])*.5 local length=(path[n+1]-path[n]).Magnitude
            P("CorridorRoof",Vector3.new(15.5,.65,length+1),center+UP*18.3,concrete,Enum.Material.Concrete,true,CFrame.lookAt(Vector3.zero,path[n+1]-path[n]))
        end
        corridor.minX=math.min(ea.mid.X,eb.mid.X)*s-9*s corridor.maxX=math.max(ea.mid.X,eb.mid.X)*s+9*s
        corridor.minZ=math.min(ea.mid.Z,eb.mid.Z)*s-9*s corridor.maxZ=math.max(ea.mid.Z,eb.mid.Z)*s+9*s
        map.corridors[index]=corridor
        for x=-5.8,5.8,1.45 do local rib=P("GateRib",Vector3.new(.12,13,.12),mid+UP*7,steel,Enum.Material.Metal,false) rib.CFrame=gate.CFrame*CFrame.new(x,0,-.4) rib.Parent=gate end
        -- Both approaches see a sign at actual first-person eye height, including on scaled maps.
        for _,side in ipairs({-1,1}) do
            local cf=CFrame.new(gate.Position)*rot*CFrame.new(0,5.4-gate.Position.Y,side*.5*s)*CFrame.Angles(0,side==1 and math.pi or 0,0)
            local yaw=math.atan2(-cf.LookVector.X,-cf.LookVector.Z)
            local sign=S(link[4].."\n"..link[3].." POINTS",cf.Position/s,Vector3.new(12.5,2.6,.12),yaw,Color3.fromRGB(245,219,159))
            sign:SetAttribute("DoorReadHeight",5.4) sign.Parent=gate
        end
        P("DoorLintel",Vector3.new(14,4,.9),mid+UP*16,concrete,Enum.Material.Concrete,true,rot)
        light(map.model,CFrame.new((mid+UP*16.7)*s),Color3.fromRGB(221,185,121),false)
    end
    for i,r in ipairs(layout) do
        local room=map.rooms[i].model
        local function q(name,size,at,color,mat,solid,rot,class)
            local p=P(name,size,at,color,mat,solid,rot,class) p.Parent=room return p
        end
        for _,e in ipairs(edges[i]) do
            local rot=rotation(e.tangent)
            local function wall(lo,hi)
                if hi-lo<.05 then return end local center=e.mid+e.tangent*((lo+hi)/2)
                q("BunkerWall",Vector3.new(hi-lo,r.h,1.2),center+UP*r.h/2,concrete,wallMaterial,true,rot)
                table.insert(map.rooms[i].wallFaces,{center=center,tangent=e.tangent,normal=e.normal,length=hi-lo})
                q("PlasterFacing",Vector3.new(hi-lo-.03,r.h-5,.08),center+UP*(r.h+5)/2-e.normal*.66,U.color(def.wall),def.theme=="Station" and Enum.Material.Plaster or wallMaterial,false,rot)
                q("WallBase",Vector3.new(hi-lo,1.3,.14),center+UP*.65-e.normal*.72,steel,Enum.Material.Metal,false,rot)
                q("WallTrim",Vector3.new(hi-lo,.12,.18),center+UP*4.8-e.normal*.76,steel,Enum.Material.Metal,false,rot)
                if hi-lo>4 then q("ConcreteRepair",Vector3.new(math.min(4,hi-lo-1),1.3,.06),center+UP*6.8-e.normal*.74,Color3.fromRGB(129,122,101),Enum.Material.Concrete,false,rot) end
            end
            table.sort(e.slots,function(a,b) return a.offset<b.offset end)
            local cursor=-e.length/2
            for _,slot in ipairs(e.slots) do
                local gap=slot.width local mid=slot.mid
                wall(cursor,slot.offset-gap/2) cursor=slot.offset+gap/2
                for _,side in ipairs({-1,1}) do q("PortalJamb",Vector3.new(.25,14,1.5),mid+e.tangent*(side*(gap/2+.13))+UP*7,steel,Enum.Material.Metal,true,rot) end
                local height=slot.kind=="window" and 11 or 14
                q("PortalHeader",Vector3.new(gap,r.h-height,1.2),mid+UP*(r.h+height)/2,concrete,Enum.Material.Concrete,true,rot)
                if slot.kind=="window" then
                    q("WindowSill",Vector3.new(gap,1.8,1.5),mid+UP*.9,concrete,Enum.Material.Concrete,true,rot)
                    local barrier=q("WindowBarrier",Vector3.new(gap,9,1.3),mid+UP*6.3,concrete,nil,true,rot)
                    barrier.Transparency=1 barrier.CollisionGroup="DeadSignalWindow" local boards={}
                    for n=1,5 do boards[n]=q("BarricadeBoard",Vector3.new(gap-.2,1.1,.30),mid+UP*(1.8+n*1.55)-e.normal*.85,Color3.fromRGB(111,84,55),Enum.Material.WoodPlanks,false,rot*CFrame.Angles(0,0,n%2==0 and .045 or -.055)) end
                    map.windows[#map.windows+1]={room=i,part=barrier,boards=boards,count=5,outside=(mid+e.normal*6+UP*3.5)*s,inside=(mid-e.normal*8+UP*3.5)*s,nextTear=0}
                end
            end
            wall(cursor,e.length/2)
            -- Repeated structural rhythm follows the actual angled walls.
            local inward=e.mid-e.normal*1.2
            local lamp=q("WallPractical",Vector3.new(1,.45,.5),inward+UP*11,Color3.fromRGB(232,189,113),Enum.Material.Neon,false,rot)
            U.make("PointLight",lamp,{Brightness=.35,Range=18*s,Color=def.theme=="Frost" and Color3.fromRGB(157,196,209) or Color3.fromRGB(229,194,139),Shadows=false})
            q("WallRib",Vector3.new(.5,r.h,.7),e.a-e.normal*.35+UP*r.h/2,steel,Enum.Material.Metal,false,rot)
        end
        -- Ceiling shape matches the footprint; an invisible cap retains containment above outdoor sectors.
        for n,a in ipairs(map.rooms[i].polygon) do
            local b=map.rooms[i].polygon[n%#map.rooms[i].polygon+1] local center=map.rooms[i].center/s
            local before=#map.floorParts triangle("SectorRoof",center,a,b,r.h+.7,room)
            for j=before+1,#map.floorParts do local cap=map.floorParts[j] cap.CollisionGroup="DeadSignalBounds" cap.CanQuery=false
                if r.outdoor then cap.Transparency=1 cap.CastShadow=false else cap.Transparency=0 end
            end
            -- Roof slabs are collision caps, not navigation floors.
            for j=#map.floorParts,before+1,-1 do table.remove(map.floorParts,j) end
        end
        if r.upper then
            local rise=def.theme=="Station" and 10 or 12 local front=r.z+r.d/2-17 local run=26 local stairX=r.x-r.w*.17
            local polygon={} local original=map.rooms[i].polygon
            for n,a in ipairs(original) do local b=original[n%#original+1] local aIn=a.Z>=front local bIn=b.Z>=front
                if aIn then polygon[#polygon+1]=a end
                if aIn~=bIn then local t=(front-a.Z)/(b.Z-a.Z) polygon[#polygon+1]=a+(b-a)*t end
            end
            polygonFloor("UpperGalleryDeck",polygon,rise,room)
            local ramp=q("StairRamp",Vector3.new(8,rise,run),Vector3.new(stairX,rise/2,front-run/2),concrete,Enum.Material.Concrete,true,nil,"WedgePart")
            ramp.Transparency=1 map.floorParts[#map.floorParts+1]=ramp
            for n=1,22 do local height=n*rise/22 local z=front-run+(n-.5)*run/22
                q("StairTread",Vector3.new(8,height,run/22+.03),Vector3.new(stairX,height/2,z),concrete,Enum.Material.Concrete,false)
                q("StairNosing",Vector3.new(8,.06,.12),Vector3.new(stairX,height+.025,z-run/44),Color3.fromRGB(164,150,116),Enum.Material.Metal,false)
            end
            local base=Vector3.new(stairX,0,front-run-3) local top=Vector3.new(stairX,rise,front+3)
            map.rooms[i].stairBase=base*s map.rooms[i].stairTop=top*s map.rooms[i].rise=rise*s
            map.rooms[i].upperCenter=Vector3.new(r.x,rise,front+7)*s
            local left=math.huge local right=-math.huge for _,v in ipairs(polygon) do left=math.min(left,v.X) right=math.max(right,v.X) end
            for _,span in ipairs({{left+1,stairX-4.6},{stairX+4.6,right-1}}) do if span[2]>span[1] then
                q("GalleryRail",Vector3.new(span[2]-span[1],.18,.18),Vector3.new((span[1]+span[2])/2,rise+3,front),steel,Enum.Material.Metal,true)
                for x=span[1],span[2],5 do q("GalleryPost",Vector3.new(.18,3,.18),Vector3.new(x,rise+1.5,front),steel,Enum.Material.Metal,true) end
            end end
        end
    end
    map.bounds=Layouts.bounds(layout) local b=map.bounds
    local function hull(name,size,pos) local p=P(name,size,pos,concrete,nil,true) p.Transparency=1 p.CanQuery=false p.CollisionGroup="DeadSignalBounds" p.CastShadow=false end
    for _,x in ipairs({b.minX-12,b.maxX+12}) do hull("ExteriorContainment",Vector3.new(2,100,b.maxZ-b.minZ+28),Vector3.new(x,48,(b.minZ+b.maxZ)/2)) end
    for _,z in ipairs({b.minZ-12,b.maxZ+12}) do hull("ExteriorContainment",Vector3.new(b.maxX-b.minX+28,100,2),Vector3.new((b.minX+b.maxX)/2,48,z)) end
    hull("ContainmentUnderfloor",Vector3.new(b.maxX-b.minX+28,1,b.maxZ-b.minZ+28),Vector3.new((b.minX+b.maxX)/2,-2.5,(b.minZ+b.maxZ)/2))
end
return A
