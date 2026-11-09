local RS=game:GetService("ReplicatedStorage")
local Layouts=require(RS.DeadSignal.MapLayouts)
local U=require(RS.DeadSignal.Util)
local A={} local UP=Vector3.new(0,1,0)
local function rotation(tangent) return CFrame.fromMatrix(Vector3.zero,tangent,UP,tangent:Cross(UP)) end
function A.build(map,layout,P,S,light,def)
    local s=map.scale local concrete=Color3.fromRGB(111,108,93) local steel=Color3.fromRGB(50,60,59)
    map.areas={} map.floorParts={} map.layout=layout map.corridors={} map.floorRegions={} map.barriers={}
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
        -- Split perpendicular to the longest edge. For an obtuse triangle the
        -- old arbitrary base put the foot outside it and both wedges spilled
        -- beyond the polygon, including into the stair opening.
        local ab,bc,ca=(pb-pa).Magnitude,(pc-pb).Magnitude,(pa-pc).Magnitude
        if ab>=bc and ab>=ca then pa,pb,pc=pc,pa,pb
        elseif ca>=bc then pa,pb,pc=pb,pc,pa end
        local edge=pc-pb local length=edge.Magnitude if length<.01 then return end
        local foot=pb+edge.Unit*(pa-pb):Dot(edge.Unit)
        local height=(pa-foot).Magnitude if height<.01 then return end
        for _,endPoint in ipairs({pb,pc}) do
            local len=(endPoint-foot).Magnitude
            if len>.015 then
                local up=(pa-foot).Unit local back=(foot-endPoint).Unit local right=up:Cross(back)
                local cf=CFrame.fromMatrix(Vector3.zero,right,up,back)
                local snowy=name=="SectorFloor" and def.theme=="Frost" and parent and parent:GetAttribute("Outdoor")
                local q=P(name,Vector3.new(1,height,len),(pa+endPoint)*.5+Vector3.new(0,y-.5,0),snowy and Color3.fromRGB(184,203,213) or U.color(def.floor),snowy and Enum.Material.Snow or Enum.Material.Concrete,true,cf,"WedgePart")
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
    local function clip(poly,axis,bound,less)
        local out={} if #poly==0 then return out end
        local previous=poly[#poly] local function coord(v) return axis=="X" and v.X or v.Z end
        local function kept(v) return less and coord(v)<=bound or not less and coord(v)>=bound end
        for _,current in ipairs(poly) do
            if kept(previous)~=kept(current) then
                out[#out+1]=previous+(current-previous)*((bound-coord(previous))/(coord(current)-coord(previous)))
            end
            if kept(current) then out[#out+1]=current end previous=current
        end return out
    end
    local function withoutRamp(poly,cut)
        -- Subtract a ramp opening as convex pieces; an uncut deck would form a lip above its slope.
        local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
        for _,v in ipairs(poly) do minX=math.min(minX,v.X) maxX=math.max(maxX,v.X) minZ=math.min(minZ,v.Z) maxZ=math.max(maxZ,v.Z) end
        if maxX<=cut.minX or minX>=cut.maxX or maxZ<=cut.minZ or minZ>=cut.maxZ then return {poly} end
        local pieces={} local remainder=poly
        for _,plane in ipairs({{"X",cut.minX,false},{"X",cut.maxX,true},{"Z",cut.minZ,false},{"Z",cut.maxZ,true}}) do
            local outside=clip(remainder,plane[1],plane[2],not plane[3])
            if #outside>=3 then pieces[#pieces+1]=outside end
            remainder=clip(remainder,plane[1],plane[2],plane[3])
        end return pieces
    end
    for i,r in ipairs(layout) do
        local room=U.make("Model",map.model,{Name=def.rooms[i]}) local polygon={} edges[i]={}
        for _,v in ipairs(Layouts.polygon(r)) do polygon[#polygon+1]=Vector3.new(r.x+v[1],0,r.z+v[2]) end
        for n,a in ipairs(polygon) do
            local b=polygon[n%#polygon+1] local tangent=(b-a).Unit
            edges[i][n]={a=a,b=b,mid=(a+b)*.5,tangent=tangent,normal=Vector3.new(tangent.Z,0,-tangent.X),length=(b-a).Magnitude,slots={}}
        end
        map.rooms[i]={model=room,center=Vector3.new(r.x,0,r.z)*s,unlocked=i==1,name=def.rooms[i],width=r.w*s,depth=r.d*s,height=r.h*s,polygon=polygon,shape=r.shape,wallFaces={}}
        room:SetAttribute("Outdoor",r.outdoor==true)
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
        local hint=Layouts.PortalHints[map.id] and Layouts.PortalHints[map.id][index]
        local da=hint and Vector3.new(hint.a[1],0,hint.a[2])*100 or b-a
        local db=hint and Vector3.new(hint.b[1],0,hint.b[2])*100 or a-b
        local ea=edgeFor(link[1],da,16,"door") local eb=edgeFor(link[2],db,16,"door")
        portals[index]={ea=ea,eb=eb,link=link}
    end
    for _,w in ipairs(Layouts.Windows) do
        local dir=w[2]=="N" and Vector3.new(0,0,-1) or w[2]=="S" and Vector3.new(0,0,1) or w[2]=="E" and Vector3.new(1,0,0) or Vector3.new(-1,0,0)
        edgeFor(w[1],dir*100,11,"window")
    end
    -- Offset polyline strips have mitered joints, closed side walls and a door on the middle leg.
    local function dressBarrier(gate,index,spec)
        local kind,title=spec[1],spec[2]
        local paint=def.theme=="Frost" and Color3.fromRGB(132,167,181) or def.theme=="Foundry" and Color3.fromRGB(134,87,44) or Color3.fromRGB(91,108,82)
        gate.Transparency=1 gate:SetAttribute("BarrierKind",kind) gate:SetAttribute("BarrierTitle",title)
        gate:SetAttribute("BarrierState","Blocked") gate:SetAttribute("DoorId",index)
        local function prop(name,size,offset,color,material,rot,class)
            local cf=gate.CFrame*CFrame.new(offset*s)*(rot or CFrame.identity)
            local q=P(name,size,Vector3.zero,color or paint,material or Enum.Material.Metal,false,nil,class)
            q.CFrame=cf q.Parent=gate q:SetAttribute("BarrierDecoration",true) return q
        end
        if kind=="Rubble" then
            for row=0,3 do for col=-1,1 do
                local q=prop("CollapsedMasonry",Vector3.new(4.6,3.3,2.6),Vector3.new(col*4.1,row*3.15-5.2,.1*math.sin(index+col)),Color3.fromRGB(113+row*7,109+row*5,91+row*4),Enum.Material.Concrete,CFrame.Angles(.03*col,.1*col,.07*(col+row%2)))
            end end
            prop("CollapsedHeader",Vector3.new(14,.8,1.8),Vector3.new(0,5.6,0),steel,Enum.Material.CorrodedMetal,CFrame.Angles(0,0,.08))
        elseif kind=="Cargo" then
            for row=0,2 do for col=-1,1 do
                local cf=Vector3.new(col*4.25,row*4.25-4.7,0)
                prop("ObstructingCargo",Vector3.new(4.3,4.3,2.8),cf,paint,def.theme=="Station" and Enum.Material.WoodPlanks or Enum.Material.Metal)
                prop("CargoTieDown",Vector3.new(.22,4.35,2.85),cf+Vector3.new(.8,0,0),steel)
            end end
        elseif kind=="Machinery" then
            prop("DisabledMachineChassis",Vector3.new(13,9.5,2.8),Vector3.new(0,-2,0),paint,Enum.Material.CorrodedMetal)
            prop("MachineUpperRack",Vector3.new(13.4,3.5,2.1),Vector3.new(0,4.4,0),steel)
            for _,x in ipairs({-4,4}) do
                local q=prop("JammedMachineDrum",Vector3.new(2.7,4.7,4.7),Vector3.new(x,-2,-1.2),steel,nil,CFrame.Angles(0,math.pi/2,0));q.Shape=Enum.PartType.Cylinder
                prop("MachineWarningStripe",Vector3.new(.55,7,.08),Vector3.new(x,0,-2),Color3.fromRGB(218,175,87),Enum.Material.SmoothPlastic,CFrame.Angles(0,0,.2))
            end
        elseif kind=="Ice" then
            local ice=prop("FrozenPassage",Vector3.new(14,13.5,1.8),Vector3.new(0,-.25,0),Color3.fromRGB(157,199,216),Enum.Material.Ice);ice.Transparency=.15
            for n=1,7 do
                prop("IceFracture",Vector3.new(.12,7+n%3,1.85),Vector3.new(-6+n*1.6,0,0),Color3.fromRGB(211,232,235),Enum.Material.SmoothPlastic,CFrame.Angles(0,0,.18*math.sin(n)))
            end
            for _,x in ipairs({-4.5,0,4.5}) do prop("IceSpur",Vector3.new(3.6,5,2),Vector3.new(x,-3.5,-.8),Color3.fromRGB(184,216,224),Enum.Material.Ice,CFrame.Angles(0,0,x*.035),"WedgePart") end
        elseif kind=="Gantry" then
            prop("CollapsedCladding",Vector3.new(13.8,13.5,1.2),Vector3.new(0,-.25,0),paint,Enum.Material.CorrodedMetal)
            for _,side in ipairs({-1,1}) do
                prop("CollapsedGirder",Vector3.new(16,.9,1.5),Vector3.new(0,side*2,side*.4),steel,nil,CFrame.Angles(0,0,side*.58))
                prop("GantryEndPlate",Vector3.new(2.1,12,1.5),Vector3.new(side*5.5,-.4,0),paint)
            end
        else
            for _,x in ipairs({-3.35,3.35}) do
                prop("SecurityLeaf",Vector3.new(6.6,13.7,1),Vector3.new(x,-.1,0),paint)
                for y=-5,5,2 do prop("BulkheadReinforcement",Vector3.new(6.4,.22,1.2),Vector3.new(x,y,0),steel) end
            end
            for _,z in ipairs({-.72,.72}) do
                prop("BulkheadLatch",Vector3.new(2,.28,.25),Vector3.new(0,-2,z),Color3.fromRGB(210,181,119))
            end
        end
        return {id=index,kind=kind,title=title,part=gate,state="Blocked",action=kind=="Bulkhead" and "UNLOCK" or "CLEAR"}
    end
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
        local corridorHeight=(layout[link[1]].upper or layout[link[2]].upper) and (def.theme=="Station" and 21 or 22) or 18
        for n=1,#path-1 do
            local quad={left[n],right[n],right[n+1],left[n+1]}
            polygonFloor("CorridorFloor",quad,0)
            local ar=area(quad,nil,d,-1,17.5*s) corridor.areas[#corridor.areas+1]=ar
            for _,side in ipairs({left,right}) do
                local start,finish=side[n],side[n+1] local tangent=(finish-start).Unit local center=(start+finish)*.5
                local material=def.theme=="Frost" and (index==8 and Enum.Material.Ice or Enum.Material.Metal) or def.theme=="Foundry" and Enum.Material.CorrodedMetal or Enum.Material.Concrete
                P("CorridorWall",Vector3.new((finish-start).Magnitude,corridorHeight,.9),center+UP*corridorHeight/2,def.theme=="Frost" and Color3.fromRGB(149,179,191) or concrete,material,true,rotation(tangent))
                P("ServiceCableTray",Vector3.new((finish-start).Magnitude,.22,.4),center+UP*(corridorHeight-2.6),steel,Enum.Material.Metal,false,rotation(tangent))
            end
            local center=(path[n]+path[n+1])*.5 local length=(path[n+1]-path[n]).Magnitude
            P("CorridorRoof",Vector3.new(15.5,.65,length+1),center+UP*(corridorHeight+.3),concrete,Enum.Material.Concrete,true,CFrame.lookAt(Vector3.zero,path[n+1]-path[n]))
        end
        corridor.minX=math.min(ea.mid.X,eb.mid.X)*s-9*s corridor.maxX=math.max(ea.mid.X,eb.mid.X)*s+9*s
        corridor.minZ=math.min(ea.mid.Z,eb.mid.Z)*s-9*s corridor.maxZ=math.max(ea.mid.Z,eb.mid.Z)*s+9*s
        map.corridors[index]=corridor
        local barrier=dressBarrier(gate,index,Layouts.Barriers[map.id][index])
        map.barriers[index]=barrier d.name=barrier.title
        local signDepth=gate.Size.Z/2+.2*s
        for _,part in ipairs(gate:GetChildren()) do if part:IsA("BasePart") then
            local localCF=gate.CFrame:ToObjectSpace(part.CFrame) local half=part.Size*.5
            local extent=math.abs(localCF.RightVector.Z)*half.X+math.abs(localCF.UpVector.Z)*half.Y+math.abs(localCF.LookVector.Z)*half.Z
            signDepth=math.max(signDepth,math.abs(localCF.Position.Z)+extent+.22*s)
        end end
        -- Both approaches see a sign at actual first-person eye height, including on scaled maps.
        for _,side in ipairs({-1,1}) do
            local cf=CFrame.new(gate.Position)*rot*CFrame.new(0,5.4-gate.Position.Y,side*signDepth)*CFrame.Angles(0,side==1 and math.pi or 0,0)
            local yaw=math.atan2(-cf.LookVector.X,-cf.LookVector.Z)
            local sign=S(barrier.action.." / "..barrier.title.."\n"..link[3].." POINTS",cf.Position/s,Vector3.new(12.5,2.6,.12),yaw,Color3.fromRGB(245,219,159))
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
                    local window={room=i,part=barrier,boards=boards,count=5,outside=(mid+e.normal*6+UP*3.5)*s,inside=(mid-e.normal*8+UP*3.5)*s,nextTear=0}
                    -- Canonical traversal anchors describe feet/sill, unlike the
                    -- retained legacy inside/outside body-height hints. Enemies
                    -- adds each evolved rig's actual root height exactly once.
                    local approach=(mid+e.normal*11)*s local breach=(mid+UP*1.8)*s
                    local landing=(mid-e.normal*8)*s
                    window.entry={schema=1,id=map.id.."_entry_"..(#map.windows+1),kind="Window",room=i,
                        approach=CFrame.lookAt(approach,approach-e.normal),breach=CFrame.lookAt(breach,breach-e.normal),
                        landing=CFrame.lookAt(landing,landing-e.normal),clearance={radius=(gap*s-1)/2,height=9*s},
                        allowedKinds={"Shambler","Runner","Crawler","Hound","Stalker","Warden"},
                        inward=-e.normal,width=gap*s,height=9*s,sillHeight=1.8*s}
                    -- Real support for the canonical foot-floor approach, not
                    -- just a logical region or the lower exterior scenery floor.
                    -- Remains outside the player BoundaryGuard footprint.
                    local apron=q("EntryApproachFloor",Vector3.new(gap+6,1,26),mid+e.normal*13-UP*.5,
                        concrete,def.theme=="Frost" and Enum.Material.Snow or Enum.Material.Concrete,true,Layouts.wallFrame(Vector3.zero,e.normal))
                    apron:SetAttribute("EntryId",window.entry.id) apron:SetAttribute("NPCEntrySupport",true)
                    map.floorParts[#map.floorParts+1]=apron window.approachFloor=apron
                    -- Crucible Lab's south entry sits on the paired room-floor
                    -- wedge seam. Keep actual support continuous from the sill
                    -- through the landing, rather than relying on an AI offset.
                    -- Flush with the existing floor; 1/32 overlap at the apron.
                    if window.entry.id=="Foundry_entry_10" then
                        local floor=q("EntryLandingFloor",Vector3.new(gap,1,14+.0625),mid-e.normal*7-UP*.5,
                            U.color(def.floor),Enum.Material.Concrete,true,Layouts.wallFrame(Vector3.zero,e.normal))
                        floor.Transparency=1 floor.CastShadow=false -- preserve the existing visible floor, without coplanar flicker
                        floor:SetAttribute("EntryId",window.entry.id) floor:SetAttribute("NPCEntrySupport",true)
                        map.floorParts[#map.floorParts+1]=floor
                    end
                    map.windows[#map.windows+1]=window
                end
            end
            wall(cursor,e.length/2)
            -- Repeated structural rhythm follows the actual angled walls.
            local inward=e.mid-e.normal*1.2
            local practical=def.theme=="Frost" and Color3.fromRGB(185,216,230) or def.theme=="Foundry" and Color3.fromRGB(238,183,105) or Color3.fromRGB(196,214,184)
            local lamp=q("WallPractical",Vector3.new(1,.45,.5),inward+UP*11,practical,Enum.Material.Neon,false,rot)
            U.make("PointLight",lamp,{Brightness=.35,Range=18*s,Color=practical,Shadows=false})
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
            -- A continuous perimeter service walk has two ground-level approaches.
            -- Both ramps are real support geometry; no jump or teleport is required.
            local rise=12 local run=26 local width=10 -- leaves the swept Warden vault below the service deck
            local stairX=r.x-r.w*.17 local returnX=r.x+r.w*.17
            local center=map.rooms[i].center/s local inner={} local ring={}
            local innerRatio=math.min(.72,1-40/r.d)
            for n,v in ipairs(map.rooms[i].polygon) do
                inner[n]=center+(v-center)*innerRatio
                ring[n]=(v+inner[n])*.5+UP*rise
            end
            local function innerSection(x)
                local lo,hi=math.huge,-math.huge
                for n,a in ipairs(inner) do local b=inner[n%#inner+1]
                    if math.abs(b.X-a.X)>.001 and x>=math.min(a.X,b.X) and x<=math.max(a.X,b.X) then
                        local z=a.Z+(b.Z-a.Z)*(x-a.X)/(b.X-a.X) lo=math.min(lo,z) hi=math.max(hi,z)
                    end
                end return lo,hi
            end
            local _,south=innerSection(stairX) local north=innerSection(returnX)
            -- Land just beyond the actual inner edge; nominal rectangle edges fail on asymmetric shells.
            local front=south+3 local back=north-3
            local stairCuts={{minX=stairX-width/2,maxX=stairX+width/2,minZ=front-run,maxZ=front},
                {minX=returnX-width/2,maxX=returnX+width/2,minZ=back,maxZ=back+run}}
            map.rooms[i].upperRing={} map.rooms[i].stairs={} map.rooms[i].upperFloorRegions={}
            for n,a in ipairs(map.rooms[i].polygon) do
                local j=n%#inner+1 local quad={a,map.rooms[i].polygon[j],inner[j],inner[n]}
                local pieces={quad}
                for _,cut in ipairs(stairCuts) do
                    local nextPieces={}
                    for _,piece in ipairs(pieces) do for _,outside in ipairs(withoutRamp(piece,cut)) do nextPieces[#nextPieces+1]=outside end end
                    pieces=nextPieces
                end
                for _,piece in ipairs(pieces) do
                    polygonFloor("UpperGalleryDeck",piece,rise,room)
                    local region={} for _,v in ipairs(piece) do region[#region+1]={v.X*s,v.Z*s} end
                    table.insert(map.rooms[i].upperFloorRegions,region)
                end
                table.insert(map.rooms[i].upperRing,ring[n]*s)
            end
            for index,spec in ipairs({{x=stairX,z=front,direction=1},{x=returnX,z=back,direction=-1}}) do
                local direction=spec.direction local yaw=direction==1 and 0 or math.pi
                local ramp=q("StairRamp",Vector3.new(width,rise,run),Vector3.new(spec.x,rise/2,spec.z-direction*run/2),concrete,Enum.Material.Concrete,true,CFrame.Angles(0,yaw,0),"WedgePart")
                ramp.Transparency=1 map.floorParts[#map.floorParts+1]=ramp
                -- A flush landing bridges the ramp/deck seam across its entire
                -- width. The 1/32 overlap avoids a numeric knife-edge contact;
                -- its maximum rise above the final slope is below .015 studs.
                local landing=q("StairLanding",Vector3.new(width,.5,6+.0625),Vector3.new(spec.x,rise-.25,spec.z+direction*3),concrete,Enum.Material.Concrete,true)
                map.floorParts[#map.floorParts+1]=landing
                for n=1,22 do local height=n*rise/22 local z=spec.z-direction*(run-(n-.5)*run/22)
                    q("StairTread",Vector3.new(width,height,run/22+.03),Vector3.new(spec.x,height/2,z),concrete,Enum.Material.Concrete,false)
                    q("StairNosing",Vector3.new(width,.06,.12),Vector3.new(spec.x,height+.025,z-direction*run/44),Color3.fromRGB(186,174,131),Enum.Material.SmoothPlastic,false)
                end
                local stair={base=Vector3.new(spec.x,0,spec.z-direction*(run+3))*s,
                    top=Vector3.new(spec.x,rise,spec.z+direction*3)*s,width=width*s,rise=rise*s,run=run*s,landing=landing}
                map.rooms[i].stairs[index]=stair
                if index==1 then
                    map.rooms[i].stairBase=stair.base map.rooms[i].stairTop=stair.top map.rooms[i].rise=stair.rise
                    map.rooms[i].upperCenter=Vector3.new(r.x,rise,front+7)*s
                end
            end
            -- Rails follow the actual inner polygon, with openings aligned to both ramps.
            for n,a in ipairs(inner) do
                local b=inner[n%#inner+1] local length=(b-a).Magnitude local tangent=(b-a).Unit
                local count=math.max(1,math.ceil(length/4))
                for segment=1,count do
                    local lo=a+(b-a)*(segment-1)/count local hi=a+(b-a)*segment/count local mid=(lo+hi)*.5 local clear=true
                    for _,stair in ipairs(map.rooms[i].stairs) do
                        local base,top=stair.base/s,stair.top/s
                        if math.max(lo.X,hi.X)>top.X-width/2-3 and math.min(lo.X,hi.X)<top.X+width/2+3
                            and math.max(lo.Z,hi.Z)>math.min(base.Z,top.Z)-3 and math.min(lo.Z,hi.Z)<math.max(base.Z,top.Z)+3 then clear=false end
                    end
                    if clear then
                        q("GalleryRail",Vector3.new((hi-lo).Magnitude+.06,.18,.18),mid+UP*(rise+3.1),steel,Enum.Material.Metal,true,rotation(tangent))
                        -- A continuous panel prevents squeezing between posts or onto low props.
                        local panel=q("GalleryGuard",Vector3.new((hi-lo).Magnitude+.06,3.1,.15),mid+UP*(rise+1.55),steel,Enum.Material.Metal,true,rotation(tangent))
                        panel.Transparency=.6
                    end
                end
            end
        end
    end
    map.bounds=Layouts.bounds(layout) local b=map.bounds
    local function hull(name,size,pos) local p=P(name,size,pos,concrete,nil,true) p.Transparency=1 p.CanQuery=false p.CollisionGroup="DeadSignalBounds" p.CastShadow=false end
    for _,x in ipairs({b.minX-12,b.maxX+12}) do hull("ExteriorContainment",Vector3.new(2,100,b.maxZ-b.minZ+28),Vector3.new(x,48,(b.minZ+b.maxZ)/2)) end
    for _,z in ipairs({b.minZ-12,b.maxZ+12}) do hull("ExteriorContainment",Vector3.new(b.maxX-b.minX+28,100,2),Vector3.new((b.minX+b.maxX)/2,48,z)) end
    hull("ContainmentUnderfloor",Vector3.new(b.maxX-b.minX+28,1,b.maxZ-b.minZ+28),Vector3.new((b.minX+b.maxX)/2,-2.5,(b.minZ+b.maxZ)/2))
end
return A
