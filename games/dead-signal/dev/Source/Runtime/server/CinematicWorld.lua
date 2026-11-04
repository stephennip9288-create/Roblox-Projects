-- Fitted set dressing: detailed surfaces without adding navigation obstacles.
local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local F={}
function F.apply(map,def,layout)
    local folder=U.make("Model",map.model,{Name="CinematicDressing"}) local s=map.scale
    local dark=Color3.fromRGB(28,33,32) local steel=Color3.fromRGB(86,95,91) local rust=Color3.fromRGB(104,76,52)
    local function p(name,size,cf,col,mat,round)
        local q=U.make("Part",folder,{Name=name,Size=size,CFrame=cf,Color=col or steel,Material=mat or Enum.Material.Metal,
            Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        if round then U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) end return q
    end
    local function fitted(base,name,size,at,col,mat,round) return p(name,size*s,base.CFrame*CFrame.new(at*s),col,mat,round) end
    local source=map.model:GetDescendants()
    for _,base in ipairs(source) do if base:IsA("BasePart") then
        local size=base.Size/s
        if base.Name=="Locker" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do
                fitted(base,"LockerFoldedEdge",Vector3.new(.08,size.Y-.15,.09),Vector3.new(x,0,size.Z/2+.08),dark)
                for _,y in ipairs({-size.Y*.34,size.Y*.34}) do fitted(base,"DoorHinge",Vector3.new(.10,.35,.13),Vector3.new(x,y,size.Z/2+.12),steel) end
            end
            fitted(base,"LockerPlinth",Vector3.new(size.X+.08,.18,size.Z+.06),Vector3.new(0,-size.Y/2+.12,0),dark)
        elseif base.Name=="ShippingCrate" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do for _,z in ipairs({-size.Z/2-.02,size.Z/2+.02}) do
                fitted(base,"CrateCornerStrap",Vector3.new(.27,size.Y+.08,.08),Vector3.new(x,0,z),rust)
                for _,y in ipairs({-size.Y*.38,size.Y*.38}) do fitted(base,"CrateRivet",Vector3.new(.075,.075,.04),Vector3.new(x,y,z-.05),steel,nil,true) end
            end end
            fitted(base,"RecessedCarryGrip",Vector3.new(.75,.17,.08),Vector3.new(0,.35,-size.Z/2-.03),dark)
        elseif base.Name=="WornDeskTop" then
            for _,z in ipairs({-size.Z/2,size.Z/2}) do fitted(base,"DeskEdgeBand",Vector3.new(size.X,.12,.055),Vector3.new(0,0,z),Color3.fromRGB(64,54,41),Enum.Material.Wood) end
            fitted(base,"DeskDrawerCase",Vector3.new(2.1,1.3,2.8),Vector3.new(size.X/2-1.35,-.8,.15),Color3.fromRGB(67,72,64))
            for j=1,2 do
                fitted(base,"DeskDrawerFace",Vector3.new(1.94,.52,.08),Vector3.new(size.X/2-1.35,-.35-j*.54,-1.30),steel)
                fitted(base,"DeskDrawerPull",Vector3.new(.58,.07,.12),Vector3.new(size.X/2-1.35,-.35-j*.54,-1.39),dark)
            end
        elseif base.Name=="RadioCabinet" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do for _,y in ipairs({-size.Y/2+.12,size.Y/2-.12}) do
                fitted(base,"RadioCaseScrew",Vector3.new(.08,.08,.04),Vector3.new(x,y,size.Z/2+.04),steel,nil,true)
            end end
            for x=-1.3,1.3,.26 do fitted(base,"RadioTopVent",Vector3.new(.11,.018,.5),Vector3.new(x,size.Y/2+.012,0),dark) end
        elseif base.Name=="CanvasSandbag" then
            local mesh=base:FindFirstChildOfClass("SpecialMesh")
            if not mesh then U.make("SpecialMesh",base,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) end
        end
    end end
    for i,r in ipairs(layout) do
        local origin=CFrame.new(Vector3.new(r.x,0,r.z)*s)
        -- Truss and cable silhouettes create layered ceilings and directional light.
        for _,z in ipairs({-r.d*.24,r.d*.24}) do
            for _,y in ipairs({r.h-.75,r.h-2.0}) do p("RoofTrussChord",Vector3.new(r.w-2,.16,.16)*s,origin*CFrame.new(0,y*s,z*s),dark) end
            for x=-r.w/2+3,r.w/2-3,4 do
                p("RoofTrussDiagonal",Vector3.new(4.1,.09,.10)*s,origin*CFrame.new(x*s,(r.h-1.38)*s,z*s)*CFrame.Angles(0,0,x%8<4 and .31 or -.31),steel)
            end
        end
        local lamp=p("CagedWallLamp",Vector3.new(1.2,.43,.5)*s,origin*CFrame.new((r.w/2-1.2)*s,(r.h-4)*s,0),dark)
        p("FrostedLampLens",Vector3.new(1,.18,.32)*s,lamp.CFrame*CFrame.new(0,-.25*s,0),Color3.fromRGB(210,192,153),Enum.Material.Neon)
        for x=-.4,.4,.2 do p("LampGuardWire",Vector3.new(.035,.30,.47)*s,lamp.CFrame*CFrame.new(x*s,-.16*s,0),dark) end
        local light=U.make("SpotLight",lamp,{Face=Enum.NormalId.Bottom,Angle=75,Range=20*s,Brightness=.55,Color=def.theme=="Foundry" and Color3.fromRGB(234,167,91) or Color3.fromRGB(185,207,202),Shadows=i%2==0})
        light:SetAttribute("PoweredBrightness",1.9)
    end
    folder:SetAttribute("ArtRevision",5)
end
-- Source-authored nonplayable extensions. Existing complete native assets stay untouched.
function F.exterior(map,def,layout)
    local s=map.scale local b=map.bounds
    local world=U.make("Model",map.model,{Name="BeyondThePerimeter"})
    world:SetAttribute("SceneryOnly",true) world:SetAttribute("NeverNavigationFloor",true)
    local steel=Color3.fromRGB(66,78,78) local dark=Color3.fromRGB(28,37,38)
    local snow=Color3.fromRGB(189,211,218) local amber=Color3.fromRGB(214,170,101)
    local counts={Near=0,Middle=0,Far=0} map.landmarks={} map.audioZones={} map.visualEvents={}
    local function p(name,size,at,col,material,rot,shape,tier,class)
        tier=tier or "Near"
        local q=U.make(class or "Part",world,{Name=name,Size=size*s,CFrame=CFrame.new(at*s)*(rot or CFrame.identity),Color=col or steel,
            Material=material or Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=tier=="Near"})
        if shape then q.Shape=shape end
        q:SetAttribute("SceneryOnly",true) q:SetAttribute("DistanceTier",tier) counts[tier]+=1 return q
    end
    local function beam(name,a,b,width,col,tier)
        local direction=(b-a).Unit local up=math.abs(direction.Y)>.98 and Vector3.xAxis or Vector3.yAxis
        return p(name,Vector3.new(width,width,(b-a).Magnitude),(a+b)*.5,col,nil,CFrame.lookAt(Vector3.zero,direction,up),nil,tier)
    end
    local function landmark(id,kind,position,tier,event)
        local item={id=map.id.."_"..id,kind=kind,position=position*s,tier=tier,event=event}
        table.insert(map.landmarks,item) return item.id
    end
    local function event(id,kind,part,period,duration)
        part:SetAttribute("AmbientOnly",true)
        local item={id=map.id.."_"..id,kind=kind,part=part,base=part.CFrame,period=period,duration=duration}
        table.insert(map.visualEvents,item) return item
    end
    local center=Vector3.new((b.minX+b.maxX)/2,0,(b.minZ+b.maxZ)/2)
    local corners={Vector3.new(b.minX-29,0,b.minZ-29),Vector3.new(b.maxX+29,0,b.minZ-29),
        Vector3.new(b.maxX+29,0,b.maxZ+29),Vector3.new(b.minX-29,0,b.maxZ+29)}
    if map.id=="Station" then
        for i,at in ipairs(corners) do
            for _,x in ipairs({-4,4}) do for _,z in ipairs({-4,4}) do
                beam("WatchtowerLeg",at+Vector3.new(x,0,z),at+Vector3.new(x*.85,22,z*.85),.6,steel)
            end end
            p("WatchtowerDeck",Vector3.new(11,.7,11),at+Vector3.new(0,22,0),steel)
            p("WatchtowerCabin",Vector3.new(8,6,8),at+Vector3.new(0,25.4,0),Color3.fromRGB(72,87,68))
            p("WatchtowerViewingGlass",Vector3.new(8.15,2,8.15),at+Vector3.new(0,26.5,0),Color3.fromRGB(95,131,126),Enum.Material.Glass).Transparency=.28
            p("WatchtowerRoof",Vector3.new(11,.6,11),at+Vector3.new(0,29,0),steel)
            for _,x in ipairs({-4.8,4.8}) do p("WatchtowerRail",Vector3.new(.16,3,10),at+Vector3.new(x,23.8,0),steel) end
            local beacon=p("DistantCarrierLamp",Vector3.new(.6,.6,.6),at+Vector3.new(0,30,0),amber,Enum.Material.Neon,nil,Enum.PartType.Ball)
            if i==1 then event("carrier_sweep","CarrierSweep",beacon,43,3) end
            landmark("guard_"..i,"GuardTower",at+Vector3.new(0,26,0),"Near",i==1 and "CarrierSweep" or nil)
        end
        -- Fence rhythm reinforces the explicit scenery boundary without adding playable floors.
        for side=1,4 do
            local a,c=corners[side],corners[side%4+1]
            local length=(c-a).Magnitude local n=math.ceil(length/20)
            for j=0,n do
                local at=a+(c-a)*j/n
                p("PerimeterFencePost",Vector3.new(.25,8,.25),at+Vector3.new(0,4,0),steel)
                if j<n then
                    local finish=a+(c-a)*(j+1)/n local q=beam("FenceMesh",at+Vector3.new(0,4,0),finish+Vector3.new(0,4,0),.1,dark)
                    q.Size=Vector3.new((finish-at).Magnitude*s,7*s,.05*s)
                    local tangent=(finish-at).Unit q.CFrame=CFrame.fromMatrix((at+finish)*.5*s+Vector3.new(0,4*s,0),tangent,Vector3.yAxis,tangent:Cross(Vector3.yAxis));q.Transparency=.56
                end
            end
        end
        local at=Vector3.new(center.X,0,b.minZ-82)
        for _,x in ipairs({-7,7}) do beam("BroadcastMastLeg",at+Vector3.new(x,0,0),at+Vector3.new(x*.12,78,0),.65,steel,"Middle") end
        for y=8,72,8 do
            beam("BroadcastMastBrace",at+Vector3.new(-7,y,0),at+Vector3.new(7,y+7,0),.2,steel,"Middle")
            p("AntennaArray",Vector3.new(16,.15,.15),at+Vector3.new(0,y,0),steel,nil,nil,nil,"Middle")
        end
        landmark("broadcast_mast","AntennaField",at+Vector3.new(0,50,0),"Middle","CarrierSweep")
        for i=1,32 do
            local a=i*math.pi/16 local at=center+Vector3.new(math.cos(a)*(b.maxX-b.minX+165)*.58,0,math.sin(a)*(b.maxZ-b.minZ+165)*.58)
            p("PineTrunk",Vector3.new(1,15,1),at+Vector3.new(0,7,0),Color3.fromRGB(61,52,40),Enum.Material.Wood,nil,nil,"Far")
            p("PineSilhouette",Vector3.new(12,24,10),at+Vector3.new(0,22,0),Color3.fromRGB(39,60,49),Enum.Material.Grass,CFrame.Angles(0,a,0),nil,"Far","WedgePart")
        end
        for i=1,3 do
            local at=Vector3.new(b.minX-55,0,center.Z-55+i*35)
            p("AbandonedFieldTruck",Vector3.new(7,5,14),at+Vector3.new(0,3,0),Color3.fromRGB(74,87,61))
            p("FieldTruckCab",Vector3.new(6.8,3,5),at+Vector3.new(0,6,-4),Color3.fromRGB(70,83,61))
            p("TruckWindshield",Vector3.new(5.9,1.5,.12),at+Vector3.new(0,6.4,-6.55),Color3.fromRGB(81,111,116),Enum.Material.Glass).Transparency=.22
            p("TruckHood",Vector3.new(6.6,1.8,3),at+Vector3.new(0,3.9,-7),Color3.fromRGB(75,91,65),Enum.Material.Metal,CFrame.Angles(0,math.pi,0),nil,"Near","WedgePart")
            p("TruckBumper",Vector3.new(7.4,.6,.7),at+Vector3.new(0,2.4,-8.6),steel)
            for _,x in ipairs({-2.5,2.5}) do p("FieldTruckLens",Vector3.new(1,.7,.12),at+Vector3.new(x,3.5,-8.52),Color3.fromRGB(176,183,139),Enum.Material.Glass) end
            for _,x in ipairs({-3.5,3.5}) do for _,z in ipairs({-4.5,4.5}) do
                p("FieldTruckWheel",Vector3.new(1,3,3),at+Vector3.new(x,1.7,z),dark,Enum.Material.Rubber,nil,Enum.PartType.Cylinder)
            end end
        end
    elseif map.id=="Foundry" then
        -- The rail siding wraps two sides of the steelworks; no rail is a support floor.
        for _,z in ipairs({b.minZ-38,b.maxZ+38}) do
            for _,offset in ipairs({-3,3}) do p("RailSiding",Vector3.new(b.maxX-b.minX+90,.3,.25),Vector3.new(center.X,.15,z+offset),steel,nil,nil,nil,"Near") end
            for x=b.minX-35,b.maxX+35,9 do p("RailSleeper",Vector3.new(1.3,.2,8),Vector3.new(x,.1,z),Color3.fromRGB(88,68,43),Enum.Material.WoodPlanks,nil,nil,"Near") end
        end
        for i=1,4 do
            local at=Vector3.new(b.minX-65+(i-1)*(b.maxX-b.minX+130)/3,0,b.minZ-82)
            local height=64+i%2*16
            p("SmelterStack",Vector3.new(height,9,9),at+Vector3.new(0,height/2,0),Color3.fromRGB(103,79,57),Enum.Material.Brick,CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder,"Middle")
            for y=12,height-3,18 do p("StackBand",Vector3.new(.5,9.4,9.4),at+Vector3.new(0,y,0),steel,nil,CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder,"Middle") end
            landmark("stack_"..i,"Smokestack",at+Vector3.new(0,height,0),"Middle","FurnaceBreath")
            if i<=2 then
                local anchor=p("StackExhaustAnchor",Vector3.new(.3,.3,.3),at+Vector3.new(0,height+1,0),steel,nil,nil,nil,"Middle");anchor.Transparency=1
                U.make("ParticleEmitter",anchor,{Name="DistantExhaust",Texture="rbxasset://textures/particles/smoke_main.dds",Rate=1.5,Lifetime=NumberRange.new(3),Speed=NumberRange.new(1,2),SpreadAngle=Vector2.new(8,8),
                    Size=NumberSequence.new(3,7),Transparency=NumberSequence.new(.88,1),Color=ColorSequence.new(Color3.fromRGB(95,98,91)),LightInfluence=1})
            end
        end
        for i,at in ipairs({corners[2],corners[4]}) do
            for _,x in ipairs({-20,20}) do
                for _,z in ipairs({-5,5}) do beam("CranePortalLeg",at+Vector3.new(x,0,z),at+Vector3.new(x,44,z),1.1,steel) end
                p("CraneEndTruck",Vector3.new(5,2,13),at+Vector3.new(x,43,0),Color3.fromRGB(139,98,48))
            end
            p("CraneBridge",Vector3.new(48,3,9),at+Vector3.new(0,46,0),Color3.fromRGB(151,109,54))
            local trolley=p("DistantCraneTrolley",Vector3.new(5,4,5),at+Vector3.new(0,43,0),steel)
            local cable=beam("CraneHangingCable",at+Vector3.new(0,42,0),at+Vector3.new(0,30,0),.14,dark)
            local motion=event("crane_"..i,"CraneCycle",trolley,61,8);motion.cable=cable;motion.cableBase=cable.CFrame landmark("crane_"..i,"GantryCrane",at+Vector3.new(0,42,0),"Near","CraneCycle")
        end
        for i=1,6 do
            local at=Vector3.new(b.maxX+65,0,b.minZ+25+i*38)
            p("PipeYardBunker",Vector3.new(22,10+i%2*4,26),at+Vector3.new(0,5+i%2*2,0),Color3.fromRGB(91,81,63),Enum.Material.Brick,nil,nil,"Middle")
            p("PipeYardHeader",Vector3.new(29,3,3),at+Vector3.new(0,14,0),steel,nil,nil,Enum.PartType.Cylinder,"Middle")
        end
        for i=1,8 do
            local at=Vector3.new(b.minX-90,0,b.minZ+(b.maxZ-b.minZ)*(i-1)/7)
            p("DistantRollingMill",Vector3.new(36,25+i%3*7,38),at+Vector3.new(0,12.5+i%3*3.5,0),Color3.fromRGB(76,77,70),Enum.Material.Brick,nil,nil,"Far")
        end
    else
        for i,at in ipairs(corners) do
            p("PolarUtilityHut",Vector3.new(15,8,18),at+Vector3.new(0,4,0),Color3.fromRGB(113,142,153))
            p("HutSnowCap",Vector3.new(17,1.4,20),at+Vector3.new(0,8.4,0),snow,Enum.Material.Snow)
            for _,x in ipairs({-4,4}) do p("HutWindow",Vector3.new(2.5,2,.1),at+Vector3.new(x,5,-9.1),Color3.fromRGB(183,208,207),Enum.Material.Glass) end
            landmark("remote_hut_"..i,"RemotePolarFacility",at+Vector3.new(0,6,0),"Near")
            local mast=at+Vector3.new(i%2==0 and 22 or -22,0,0)
            beam("PolarRadioMast",mast,mast+Vector3.new(0,44,0),.7,steel)
            for y=12,39,9 do p("PolarCrossArray",Vector3.new(12,.15,.15),mast+Vector3.new(0,y,0),steel) end
            local marker=p("RelayStatusLamp",Vector3.new(.5,.5,.5),mast+Vector3.new(0,45,0),Color3.fromRGB(136,197,216),Enum.Material.Neon,nil,Enum.PartType.Ball)
            if i==2 then event("relay_scan","RelaySweep",marker,47,4) end
        end
        for i=1,24 do
            local a=i*math.pi/12 local at=center+Vector3.new(math.cos(a)*(b.maxX-b.minX+145)*.6,0,math.sin(a)*(b.maxZ-b.minZ+145)*.6)
            p("DistantIceRidge",Vector3.new(55,26+i%4*8,30),at+Vector3.new(0,8,0),snow,Enum.Material.Snow,CFrame.Angles(0,a,0),nil,"Far","WedgePart")
        end
        for i=1,2 do
            local at=Vector3.new(i==1 and b.minX-65 or b.maxX+65,0,center.Z)
            p("FrozenCrawlerChassis",Vector3.new(10,4,17),at+Vector3.new(0,2.5,0),Color3.fromRGB(110,132,137))
            p("CrawlerCab",Vector3.new(7,5,7),at+Vector3.new(0,6,-3),Color3.fromRGB(130,153,162))
            p("CrawlerViewingGlass",Vector3.new(5.8,2.2,.12),at+Vector3.new(0,6.7,-6.56),Color3.fromRGB(90,137,155),Enum.Material.Glass).Transparency=.25
            beam("CrawlerRadioWhip",at+Vector3.new(2.8,8,0),at+Vector3.new(2.8,13,0),.08,steel)
            for _,x in ipairs({-5,5}) do p("CrawlerTrack",Vector3.new(2.3,3,18),at+Vector3.new(x,1.5,0),dark,Enum.Material.Rubber) end
            p("CrawlerSnowDrift",Vector3.new(14,4,9),at+Vector3.new(0,1,5),snow,Enum.Material.Snow,CFrame.Angles(0,math.pi,0),nil,"Near","WedgePart")
            landmark("frozen_rover_"..i,"FrozenResearchVehicle",at+Vector3.new(0,5,0),"Near")
            local anchor=p("FarStormAnchor",Vector3.new(.2,.2,.2),at+Vector3.new(0,18,0),snow);anchor.Transparency=1
            local emitter=U.make("ParticleEmitter",anchor,{Name="FarPolarGust",Texture="rbxasset://textures/particles/smoke_main.dds",Rate=0,Lifetime=NumberRange.new(2),Speed=NumberRange.new(10,14),SpreadAngle=Vector2.new(12,20),
                Size=NumberSequence.new(.7,1.7),Transparency=NumberSequence.new(.87,1),Color=ColorSequence.new(snow),LightInfluence=0})
            table.insert(map.visualEvents,{id=map.id.."_gust_"..i,kind="PolarGust",part=anchor,emitter=emitter,base=anchor.CFrame,period=53,duration=5})
        end
    end
    -- Stable semantic producers; AUDIO DEV owns all sound creation and transitions.
    for i,r in ipairs(layout) do
        local polygon={} for _,v in ipairs(map.rooms[i].polygon) do polygon[#polygon+1]={v.X*s,v.Z*s} end
        table.insert(map.audioZones,{id=map.id.."_sector_"..i,kind="Room",room=i,name=def.rooms[i],purpose=r.purpose,indoors=not r.outdoor,level=0,
            center=map.rooms[i].center,min=Vector3.new(r.x-r.w/2,0,r.z-r.d/2)*s,max=Vector3.new(r.x+r.w/2,r.h,r.z+r.d/2)*s,polygon=polygon})
        if r.upper then table.insert(map.audioZones,{id=map.id.."_upper_"..i,kind="ServiceWalk",room=i,name=r.purpose,indoors=true,level=1,center=map.rooms[i].upperCenter,regions=map.rooms[i].upperFloorRegions}) end
    end
    for i,corridor in ipairs(map.corridors) do
        table.insert(map.audioZones,{id=map.id.."_transfer_"..i,kind="Corridor",name=map.doors[i].name,indoors=true,door=i,level=0,center=map.doors[i].position,regions=corridor.areas})
    end
    map.scenery={model=world,counts=counts,parts=counts.Near+counts.Middle+counts.Far,maxParticleRate=map.id=="Foundry" and 3 or map.id=="Frost" and 8 or 0,
        clearanceFromRoomBounds=29*s,lodPolicy="Near assemblies / middle silhouettes / far silhouettes; no navigation or combat query"}
    world:SetAttribute("SceneryParts",map.scenery.parts) world:SetAttribute("VisualEventCount",#map.visualEvents)
end
-- Replicated producer metadata lets Audio/Enemy read source-authored regions without a new remote.
-- Consumer/mix integration remains MAIN/AUDIO/ENEMY-owned; these folders play no sounds.
function F.publishSemantics(map)
    local root=U.make("Folder",map.model,{Name="MapSemantics"})
    root:SetAttribute("SchemaVersion",1) root:SetAttribute("Coordinates","WorldStuds")
    local zones=U.make("Folder",root,{Name="Zones"}) local landmarks=U.make("Folder",root,{Name="Landmarks"})
    local events=U.make("Folder",root,{Name="VisualEvents"})
    local function polygon(parent,index,points)
        local item=U.make("Folder",parent,{Name="Region"..index})
        item:SetAttribute("PointCount",#points)
        for i,v in ipairs(points) do item:SetAttribute("Point"..i,Vector3.new(v[1],0,v[2])) end
    end
    for _,zone in ipairs(map.audioZones) do
        local item=U.make("Folder",zones,{Name=zone.id})
        item:SetAttribute("Kind",zone.kind) item:SetAttribute("Room",zone.room or 0) item:SetAttribute("Door",zone.door or 0)
        item:SetAttribute("Level",zone.level) item:SetAttribute("Indoors",zone.indoors) item:SetAttribute("Position",zone.center)
        item:SetAttribute("Purpose",zone.purpose or zone.name) item:SetAttribute("Priority",zone.level==1 and 20 or zone.kind=="Room" and 10 or 5)
        if zone.min then item:SetAttribute("BoundsMin",zone.min) item:SetAttribute("BoundsMax",zone.max) end
        if zone.polygon then polygon(item,1,zone.polygon) end
        for i,region in ipairs(zone.regions or {}) do polygon(item,i,region.polygon or region) end
    end
    for _,point in ipairs(map.landmarks) do
        local item=U.make("Folder",landmarks,{Name=point.id})
        item:SetAttribute("Kind",point.kind) item:SetAttribute("DistanceTier",point.tier) item:SetAttribute("Position",point.position)
        if point.event then item:SetAttribute("AmbientEvent",point.event) end
    end
    for _,event in ipairs(map.visualEvents) do
        local item=U.make("Folder",events,{Name=event.id})
        item:SetAttribute("Kind",event.kind) item:SetAttribute("Period",event.period) item:SetAttribute("Duration",event.duration)
        item:SetAttribute("Position",event.base.Position) item:SetAttribute("Active",false) event.metadata=item
    end
    for _,window in ipairs(map.windows) do local entry=window.entry
        for key,value in pairs({EntrySchema=entry.schema,EntryId=entry.id,EntryKind=entry.kind,EntryRoom=entry.room,
            Approach=entry.approach,Breach=entry.breach,Landing=entry.landing,AllowedKinds=table.concat(entry.allowedKinds,","),
            Inward=entry.inward,ClearRadius=entry.clearance.radius,ClearWidth=entry.width,ClearHeight=entry.height,SillHeight=entry.sillHeight}) do window.part:SetAttribute(key,value) end
    end
    map.semantics=root
end

function F.worldStep(map,now)
    if not map.model.Parent then return false end
    for _,barrier in ipairs(map.barriers or {}) do
        local open=map.doors[barrier.id].open
        barrier.state=open and "Open" or "Blocked" barrier.part:SetAttribute("BarrierState",barrier.state)
    end
    for _,event in ipairs(map.visualEvents or {}) do if event.part.Parent then
        local phase=now%event.period local active=phase<event.duration
        event.part:SetAttribute("AmbientEvent",event.id) event.part:SetAttribute("AmbientActive",active)
        if event.metadata then event.metadata:SetAttribute("Active",active) end
        if event.kind=="CraneCycle" then
            local shift=CFrame.new(active and math.sin(phase/event.duration*math.pi)*8*map.scale or 0,0,0)
            event.part.CFrame=event.base*shift event.cable.CFrame=event.cableBase*shift
        elseif event.kind=="PolarGust" then event.emitter.Rate=active and 4 or 0
        else event.part.Transparency=active and .05 or .6 end
    end end
    return true
end

return F
