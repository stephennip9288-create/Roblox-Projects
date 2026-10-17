-- Architectural art direction follows the authored polygon, with static geometry and practical light.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Layouts=require(RS.DeadSignal.MapLayouts)
local V={}
function V.apply(map,def,layout)
    local s=map.scale local folder=U.make("Model",map.model,{Name="MapIdentity9"})
    local steel=Color3.fromRGB(71,80,80) local shadow=Color3.fromRGB(28,35,36)
    local warm=Color3.fromRGB(232,188,113) local cool=Color3.fromRGB(156,195,208)
    local function p(name,size,at,col,mat,rot,shape)
        local q=U.make("Part",folder,{Name=name,Size=size*s,CFrame=CFrame.new(at*s)*(rot or CFrame.identity),Color=col or steel,
            Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        if shape then q.Shape=shape end return q
    end
    local function beam(name,a,b,width,col)
        local direction=(b-a).Unit
        local up=math.abs(direction:Dot(Vector3.yAxis))>.98 and Vector3.xAxis or Vector3.yAxis
        return p(name,Vector3.new(width,width,(b-a).Magnitude),(a+b)*.5,col,nil,CFrame.lookAt(Vector3.zero,direction,up))
    end
    local function free(room,at,margin)
        local r=layout[room] if not Layouts.contains(r,at.X,at.Z,margin or 5) then return false end
        local world=at*s
        for _,zone in ipairs(map.interactionZones) do
            if world.X>zone.minX-2*s and world.X<zone.maxX+2*s and world.Z>zone.minZ-2*s and world.Z<zone.maxZ+2*s then return false end
        end return true
    end
    -- Architectural identity is built in source, not baked into a replacement place.
    -- All additions are scenery/query-free; the tested structural shell owns collision.
    for i,r in ipairs(layout) do
        local origin=Vector3.new(r.x,0,r.z)
        for _,face in ipairs(map.rooms[i].wallFaces) do
            local rot=CFrame.fromMatrix(Vector3.zero,face.tangent,Vector3.yAxis,face.normal)
            local inward=-face.normal local span=face.length
            if def.theme=="Station" then
                -- Ceramic dado, brick piers and the station's broken 03:17 clockwork.
                p("StationTileDado",Vector3.new(span-.08,2.4,.08),face.center+Vector3.new(0,1.6,0)+inward*.78,Color3.fromRGB(132,155,137),Enum.Material.SmoothPlastic,rot)
                for x=-span/2+2,span/2-1,7 do
                    p("StationTileJoint",Vector3.new(.035,2.4,.025),face.center+face.tangent*x+Vector3.new(0,1.6,0)+inward*.84,shadow,Enum.Material.SmoothPlastic,rot)
                end
                p("StationPictureRail",Vector3.new(span-.1,.16,.24),face.center+Vector3.new(0,8.8,0)+inward*.85,Color3.fromRGB(130,111,77),nil,rot)
            elseif def.theme=="Foundry" then
                -- Deep corrugated steel and pipe headers read as a working industrial shed.
                for x=-span/2+1,span/2-1,3.5 do
                    p("FoundryCladdingFold",Vector3.new(.24,r.h-3,.3),face.center+face.tangent*x+Vector3.new(0,r.h/2,0)+inward*.78,steel,nil,rot)
                end
                p("SteamHeader",Vector3.new(span,.65,.65),face.center+Vector3.new(0,r.h-5,0)+inward*1.2,Color3.fromRGB(133,96,61),Enum.Material.CorrodedMetal,rot,Enum.PartType.Cylinder)
            else
                -- Raised insulated panels and sloped caps make a low polar module silhouette.
                p("PolarInsulationBand",Vector3.new(span-.1,1.6,.13),face.center+Vector3.new(0,9.2,0)+inward*.84,Color3.fromRGB(156,183,188),Enum.Material.SmoothPlastic,rot)
                for x=-span/2+2,span/2-1,6 do
                    p("PolarPanelSeam",Vector3.new(.09,r.h-2,.12),face.center+face.tangent*x+Vector3.new(0,r.h/2,0)+inward*.79,shadow,nil,rot)
                    for _,y in ipairs({1.2,r.h-1.2}) do p("PolarPanelLatch",Vector3.new(.45,.18,.12),face.center+face.tangent*x+Vector3.new(0,y,0)+inward*.92,steel,nil,rot) end
                end
                p("PolarSnowEave",Vector3.new(span+.4,.7,2.6),face.center+Vector3.new(0,r.h+1.5,0),Color3.fromRGB(204,216,218),Enum.Material.Snow,rot*CFrame.Angles(.20,0,0))
            end
        end
        if def.theme=="Station" then
            if i==1 then
                for _,z in ipairs({-r.d*.22,r.d*.22}) do
                    p("StationTransomBeam",Vector3.new(r.w-2,.7,1),origin+Vector3.new(0,r.h-2,z),Color3.fromRGB(102,112,97))
                    for x=-r.w/2+6,r.w/2-4,6 do p("StationTransomPane",Vector3.new(4.9,2.3,.15),origin+Vector3.new(x,r.h-3.8,z),Color3.fromRGB(143,174,163),Enum.Material.Glass).Transparency=.4 end
                end
                local clock=p("StationStoppedClock",Vector3.new(.3,4,4),origin+Vector3.new(0,r.h-5,-r.d/2+.9),Color3.fromRGB(219,211,179),Enum.Material.SmoothPlastic,CFrame.Angles(0,math.pi/2,0),Enum.PartType.Cylinder)
                p("StationClockHour0317",Vector3.new(.15,1,.08),clock.Position/s+Vector3.new(.55,0,.2),shadow,Enum.Material.SmoothPlastic,CFrame.Angles(0,0,-1.57))
                p("StationClockMinute0317",Vector3.new(.10,1.5,.08),clock.Position/s+Vector3.new(.5,-.4,.21),shadow,Enum.Material.SmoothPlastic,CFrame.Angles(0,0,-1.78))
            end
            -- Dashed platform bands mark the long axis without creating a low ledge.
            for z=-r.d/2+10,r.d/2-8,8 do
                local at=origin+Vector3.new(r.w*.18,.035,z)
                if free(i,at,6) then p("StationAisleDash",Vector3.new(.3,.02,3.5),at,Color3.fromRGB(183,163,111),Enum.Material.SmoothPlastic) end
            end
        elseif def.theme=="Foundry" then
            if not r.outdoor then
                for z=-r.d/2+14,r.d/2-12,24 do
                    local at=origin+Vector3.new(0,r.h-3,z)
                    p("FoundryGantryWeb",Vector3.new(r.w-3,1.4,.3),at,Color3.fromRGB(151,103,49))
                    for _,dy in ipairs({-.75,.75}) do p("FoundryGantryFlange",Vector3.new(r.w-3,.17,1.4),at+Vector3.new(0,dy,0),steel) end
                    -- Sawtooth clerestories are visible above the sealed roof from the yard.
                    p("FoundrySawtoothRoof",Vector3.new(r.w-1,1.7,13),origin+Vector3.new(0,r.h+3.4,z),Color3.fromRGB(91,94,87),Enum.Material.CorrodedMetal,CFrame.Angles(-.22,0,0))
                    p("FoundryClerestoryGlass",Vector3.new(r.w-7,2.7,.2),origin+Vector3.new(0,r.h+3.4,z+6),Color3.fromRGB(193,154,94),Enum.Material.Glass).Transparency=.25
                end
            end
            for _,x in ipairs({-r.w*.18,r.w*.18}) do
                p("FoundryCastingChannel",Vector3.new(1.2,.025,r.d*.5),origin+Vector3.new(x,.03,0),Color3.fromRGB(35,30,25),Enum.Material.SmoothPlastic)
                for z=-r.d*.24,r.d*.24,5 do p("FoundryChannelGrate",Vector3.new(1.15,.03,.13),origin+Vector3.new(x,.05,z),steel) end
            end
        else
            if not r.outdoor then
                for _,side in ipairs({-1,1}) do
                    p("PolarFacetedRoof",Vector3.new(r.w*.53,.8,r.d*.78),origin+Vector3.new(side*r.w*.24,r.h+3,0),Color3.fromRGB(178,198,205),Enum.Material.Snow,CFrame.Angles(0,0,side*.19))
                end
            end
            -- An interrupted tracking line and anchor plates distinguish the listening post.
            for n=1,8 do
                local at=origin+Vector3.new(0,.04,-r.d*.3+n*r.d*.065)
                if free(i,at,7) then p("PolarTrackingMark",Vector3.new(n%3==0 and 2.8 or .7,.025,.3),at,Color3.fromRGB(164,203,208),Enum.Material.SmoothPlastic) end
            end
        end
    end
    for i,r in ipairs(layout) do
        local poly=map.rooms[i].polygon local origin=Vector3.new(r.x,0,r.z)
        for n,a in ipairs(poly) do
            local b=poly[n%#poly+1] local tangent=(b-a).Unit local normal=Vector3.new(tangent.Z,0,-tangent.X)
            local rot=CFrame.fromMatrix(Vector3.zero,tangent,Vector3.yAxis,tangent:Cross(Vector3.yAxis))
            local center=(a+b)*.5 local span=(b-a).Magnitude
            p("CopingCap",Vector3.new(span+.25,.45,1.55),center+Vector3.new(0,r.h+.9,0),steel,nil,rot)
            for _,height in ipairs({r.h-2.3,r.h-3}) do
                local q=p("ServiceConduit",Vector3.new(span-.2,.12,.12),center+Vector3.new(0,height,0)-normal*.85,shadow,nil,rot)
                q.Shape=Enum.PartType.Cylinder
            end
            for x=-span/2+2,span/2-1,5 do
                p("ConduitClamp",Vector3.new(.11,.95,.20),center+tangent*x+Vector3.new(0,r.h-2.7,0)-normal*.9,steel,nil,rot)
            end
            -- Slim columns and diagonal ceiling ties make the nonrectangular silhouette readable.
            if not r.outdoor then
                beam("CeilingRadialTie",origin+Vector3.new(0,r.h-.8,0),a+Vector3.new(0,r.h-.8,0),.17,shadow)
                beam("CeilingRadialBrace",origin+Vector3.new(0,r.h-2.2,0),a+Vector3.new(0,r.h-.8,0),.09,steel)
            end
            for stain=1,2 do
                local pos=center+tangent*((stain==1 and -.21 or .22)*span)+Vector3.new(0,7+stain*1.3,0)-normal*.73
                local q=p("DampRun",Vector3.new(.35+stain*.16,3.8+stain*.7,.025),pos,Color3.fromRGB(42,47,40),Enum.Material.Concrete,rot)
                q.Transparency=.55 q.CastShadow=false
            end
        end
        local key=def.theme=="Frost" and cool or warm
        for _,dx in ipairs({-.22,.22}) do
            local at=origin+Vector3.new(r.w*dx,r.h-2.7,0)
            local mount=p("PendantHousing",Vector3.new(3.1,.32,1.4),at,shadow)
            local lens=p("PendantLens",Vector3.new(2.7,.08,1.1),at-Vector3.new(0,.22,0),key,Enum.Material.Neon)
            for _,dz in ipairs({-.59,.59}) do p("PendantGuard",Vector3.new(3,.09,.08),at+Vector3.new(0,-.25,dz),steel) end
            local light=U.make("SurfaceLight",lens,{Face=Enum.NormalId.Bottom,Angle=115,Range=math.min(38,r.h+8)*s,Brightness=.55,Color=key,Shadows=dx<0})
            light:SetAttribute("PoweredBrightness",1.5)
            beam("HangerCable",at+Vector3.new(0,.3,0),at+Vector3.new(0,2.1,0),.045,shadow)
        end
        -- Controlled floor storytelling, clear of interactions and portal lanes.
        for n=1,8 do
            local a=n*2.399+i local radius=math.min(r.w,r.d)*(.16+(n%3)*.075)
            local at=origin+Vector3.new(math.cos(a)*radius,.035,math.sin(a)*radius)
            if free(i,at,7) then
                if n%3==0 then
                    local puddle=p("StandingWater",Vector3.new(4+n*.3,.035,1.8+n*.2),at,Color3.fromRGB(39,52,52),Enum.Material.Glass,CFrame.Angles(0,a,0),Enum.PartType.Ball)
                    puddle.Transparency=.38 puddle.Reflectance=.12 puddle.CastShadow=false
                else
                    for j=1,3 do
                        p("ConcreteSpall",Vector3.new(.20+j*.15,.08+j*.025,.25+j*.12),at+Vector3.new(j*.24,.04,j*.18),Color3.fromRGB(100+j*5,101+j*4,89+j*3),Enum.Material.Concrete,CFrame.Angles(0,j*a,0))
                    end
                end
            end
        end
        if r.shape=="rotunda" then
            for n=1,24 do
                local a=n*math.pi/12 local radius=math.min(r.w,r.d)*.39
                local at=origin+Vector3.new(math.cos(a)*radius,r.h-3.7,math.sin(a)*radius)
                p("RotundaRingRib",Vector3.new(radius*.27,.30,.40),at,steel,nil,CFrame.Angles(0,-a+math.pi/2,0))
            end
        end
    end
    -- Exterior silhouettes establish each location without placing obstacles in playable routes.
    local b=map.bounds local center=Vector3.new((b.minX+b.maxX)/2,0,b.minZ-25)
    if def.theme=="Station" then
        for n=1,4 do
            local at=center+Vector3.new(-70+n*28,0,-10-n%2*13)
            p("StationServiceBlock",Vector3.new(23,18+n*3,16),at+Vector3.new(0,9+n*1.5,0),Color3.fromRGB(60,66,64),Enum.Material.Brick)
            for window=1,3 do p("DistantStationWindow",Vector3.new(2,3,.06),at+Vector3.new(-8+window*4,11,8.05),Color3.fromRGB(150,131,87),Enum.Material.Neon) end
        end
        local at=center+Vector3.new(0,0,-18)
        for _,x in ipairs({-4,4}) do beam("RelayTowerLeg",at+Vector3.new(x,0,0),at+Vector3.new(x*.3,62,0),.40,steel) end
        for y=6,60,6 do beam("RelayCrossBracing",at+Vector3.new(-4,y,0),at+Vector3.new(4,y+5,0),.16,steel) end
        p("TowerBeacon",Vector3.new(.8,.8,.8),at+Vector3.new(0,64,0),Color3.fromRGB(198,66,43),Enum.Material.Neon,nil,Enum.PartType.Ball)
    elseif def.theme=="Foundry" then
        for n=1,4 do
            local at=center+Vector3.new(-66+n*28,0,-12)
            p("FoundryStack",Vector3.new(55+n*3,6,6),at+Vector3.new(0,(55+n*3)/2,0),Color3.fromRGB(77,71,61),Enum.Material.CorrodedMetal,CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
            for y=9,48,13 do p("StackBand",Vector3.new(.55,6.35,6.35),at+Vector3.new(0,y,0),steel,nil,CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder) end
        end
        local r=layout[3] local at=Vector3.new(r.x,r.h-1,r.z)
        p("OverheadCraneBridge",Vector3.new(r.w*.65,1.7,3),at,Color3.fromRGB(151,111,53),Enum.Material.CorrodedMetal)
        beam("CraneCable",at-Vector3.new(0,1,0),at-Vector3.new(0,8,0),.08,shadow)
        p("CraneHook",Vector3.new(.8,1.1,.5),at-Vector3.new(0,8.4,0),steel)
    else
        local at=center+Vector3.new(12,0,-12)
        p("RadarPedestal",Vector3.new(8,30,8),at+Vector3.new(0,15,0),steel,Enum.Material.Metal)
        for n=1,8 do
            local radius=n*1.5
            for j=1,24 do
                local a=j*math.pi/12
                p("RadarParabolicRib",Vector3.new(.16,.12,radius*.27),at+Vector3.new(math.cos(a)*radius,33+radius*radius*.025,math.sin(a)*radius),Color3.fromRGB(163,179,174),Enum.Material.Metal,CFrame.Angles(0,-a,0))
            end
        end
        beam("RadarFeed",at+Vector3.new(0,33,0),at+Vector3.new(0,41,0),.25,steel)
        for n=1,7 do
            local at2=center+Vector3.new(-100+n*30,3,-22-n%3*9)
            p("SnowRidge",Vector3.new(43,8+n%3*4,22),at2,Color3.fromRGB(194,204,202),Enum.Material.Snow,CFrame.Angles(0,n*.6,0),Enum.PartType.Ball)
        end
    end
    folder:SetAttribute("ArtRevision",9) map.model:SetAttribute("VisualRevision",9)
end
return V
