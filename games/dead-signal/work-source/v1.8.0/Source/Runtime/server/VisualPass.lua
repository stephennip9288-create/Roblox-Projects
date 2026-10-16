-- Architectural art direction follows the authored polygon, with static geometry and practical light.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Layouts=require(RS.DeadSignal.MapLayouts)
local V={}
function V.apply(map,def,layout)
    local s=map.scale local folder=U.make("Model",map.model,{Name="VisualPass8"})
    local steel=Color3.fromRGB(71,80,80) local shadow=Color3.fromRGB(28,35,36)
    local warm=Color3.fromRGB(232,188,113) local cool=Color3.fromRGB(156,195,208)
    local function p(name,size,at,col,mat,rot,shape)
        local q=U.make("Part",folder,{Name=name,Size=size*s,CFrame=CFrame.new(at*s)*(rot or CFrame.identity),Color=col or steel,
            Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        if shape then q.Shape=shape end return q
    end
    local function beam(name,a,b,width,col)
        return p(name,Vector3.new(width,width,(b-a).Magnitude),(a+b)*.5,col,nil,CFrame.lookAt(Vector3.zero,b-a))
    end
    local function free(room,at,margin)
        local r=layout[room] if not Layouts.contains(r,at.X,at.Z,margin or 5) then return false end
        local world=at*s
        for _,zone in ipairs(map.interactionZones) do
            if world.X>zone.minX-2*s and world.X<zone.maxX+2*s and world.Z>zone.minZ-2*s and world.Z<zone.maxZ+2*s then return false end
        end return true
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
    folder:SetAttribute("ArtRevision",8) map.model:SetAttribute("VisualRevision",8)
end
return V
