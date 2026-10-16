-- Original rescue transports built from shaped panels, chassis and fitted trim.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Art=require(RS.DeadSignal.ArtAssets)
local V={}
function V.build(parent,cf,accent,id)
    local m=U.make("Model",parent,{Name="RescueTransport"})
    local paint=Color3.fromRGB(66,76,67) local black=Color3.fromRGB(22,25,24)
    local steel=Color3.fromRGB(95,102,99) local glass=Color3.fromRGB(69,88,87)
    local function p(name,size,pos,col,mat,rot,solid,class)
        return U.make(class or "Part",m,{Name=name,Size=size,CFrame=cf*CFrame.new(pos)*(rot or CFrame.new()),Color=col or paint,
            Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=solid==true,CanQuery=false,CanTouch=false})
    end
    local function cylinder(name,length,diameter,pos,col)
        local q=p(name,Vector3.new(length,diameter,diameter),pos,col,Enum.Material.SmoothPlastic) q.Shape=Enum.PartType.Cylinder return q
    end
    p("Chassis",Vector3.new(8,.6,19),Vector3.new(0,1.45,-4.7),black,nil,nil,true)
    -- High body shell and separate lower panels leave actual wheel openings.
    p("CargoBody",Vector3.new(9.5,2.80,12.7),Vector3.new(0,5.13,-2),paint,nil,nil,true)
    p("CargoRoof",Vector3.new(8.85,.28,12.8),Vector3.new(0,6.75,-2),paint)
    for side=-1,1,2 do
        local shoulder=p("RoundedRoofShoulder",Vector3.new(12.8,.64,.64),Vector3.new(side*4.44,6.51,-2),paint,nil,CFrame.Angles(0,math.pi/2,0))
        shoulder.Shape=Enum.PartType.Cylinder
        p("LowerQuarterPanel",Vector3.new(.25,1.75,6.0),Vector3.new(side*4.65,2.83,-5.25),paint)
        p("RearQuarterPanel",Vector3.new(.25,1.75,1.25),Vector3.new(side*4.65,2.83,4.02),paint)
        p("CargoShoulderLine",Vector3.new(.035,.045,12.2),Vector3.new(side*4.777,5.35,-2),steel)
        p("CargoDoorSeam",Vector3.new(.035,2.10,.025),Vector3.new(side*4.78,5.05,-6.0),black)
        p("CargoLatch",Vector3.new(.13,.14,.67),Vector3.new(side*4.85,4.55,-5.5),black)
        p("RearBodySeam",Vector3.new(.035,2.75,.028),Vector3.new(side*4.78,5.1,3.78),black)
    end
    p("CabFloor",Vector3.new(9.4,.55,4.3),Vector3.new(0,2.6,-10.25),paint,nil,nil,true)
    p("CabBack",Vector3.new(9.4,3.6,.5),Vector3.new(0,4.7,-8.55),paint,nil,nil,true)
    p("CabRoof",Vector3.new(9.6,.34,4.2),Vector3.new(0,6.77,-10.35),paint)
    p("Hood",Vector3.new(8.6,.72,3.2),Vector3.new(0,3.65,-12.35),paint,nil,CFrame.Angles(.09,0,0),true)
    p("HoodNose",Vector3.new(8.65,.65,.4),Vector3.new(0,3.19,-14.05),paint)
    for side=-1,1,2 do
        p("HoodShoulder",Vector3.new(.45,.52,3.2),Vector3.new(side*4.33,3.49,-12.35),paint,nil,CFrame.Angles(0,0,-side*.25))
        p("BonnetPressing",Vector3.new(.05,.025,2.4),Vector3.new(side*2.9,4.03,-12.35),Color3.fromRGB(78,88,77),nil,CFrame.Angles(.09,0,0))
        p("BonnetGap",Vector3.new(.026,.026,3.08),Vector3.new(side*4.09,3.98,-12.35),black,nil,CFrame.Angles(.09,0,0))
    end
    p("FrontBumper",Vector3.new(10.25,.6,.65),Vector3.new(0,2.05,-14.2),black)
    p("RearBumper",Vector3.new(10.25,.5,.7),Vector3.new(0,1.8,4.72),black)
    local wind=p("Windshield",Vector3.new(8.8,2.2,.09),Vector3.new(0,5.28,-12.05),glass,Enum.Material.Glass,CFrame.Angles(-.24,0,0)) wind.Transparency=.23
    for side=-1,1,2 do
        p("WindshieldPillar",Vector3.new(.27,2.6,.32),Vector3.new(side*4.56,5.28,-12.05),paint,nil,CFrame.Angles(-.24,0,0))
        p("CabDoor",Vector3.new(.24,1.10,3.5),Vector3.new(side*4.77,4.325,-10.1),paint)
        p("CabDoorHeel",Vector3.new(.24,1.15,.48),Vector3.new(side*4.77,3.1,-8.18),paint)
        local q=p("SideGlass",Vector3.new(.09,1.45,3.35),Vector3.new(side*4.79,5.66,-10.1),glass,Enum.Material.Glass) q.Transparency=.22
        p("GlassSeal",Vector3.new(.15,.12,3.55),Vector3.new(side*4.88,4.96,-10.1),black)
        p("DoorHandle",Vector3.new(.22,.14,.8),Vector3.new(side*4.98,4.5,-9.0),steel)
        p("DoorSeam",Vector3.new(.05,2.1,.055),Vector3.new(side*4.92,3.85,-8.55),black)
        p("MirrorArm",Vector3.new(1.3,.12,.14),Vector3.new(side*5.2,5.35,-11.0),black)
        p("MirrorHousing",Vector3.new(.35,.86,.65),Vector3.new(side*5.83,5.35,-11.0),black)
        p("MirrorGlass",Vector3.new(.035,.72,.52),Vector3.new(side*6.02,5.35,-11.0),steel)
        p("RescueStripe",Vector3.new(.05,.25,12.4),Vector3.new(side*4.78,4.35,-2),accent,Enum.Material.SmoothPlastic)
        p("RescueStripeKeyline",Vector3.new(.045,.045,12.4),Vector3.new(side*4.79,4.59,-2),Color3.fromRGB(158,165,149),Enum.Material.SmoothPlastic)
        for _,z in ipairs({-5.4,4.05}) do p("SideRubRail",Vector3.new(.18,.18,z<0 and 5.8 or 1.15),Vector3.new(side*4.85,2.68,z),black) end
        p("RunningBoard",Vector3.new(1,.2,4),Vector3.new(side*4.98,1.9,-8.3),black)
        p("CabSeat",Vector3.new(2.5,1.1,2.8),Vector3.new(side*2.7,3.24,-10.2),black,Enum.Material.Fabric)
        p("SeatBack",Vector3.new(2.5,2,.5),Vector3.new(side*2.7,4.6,-9.2),black,Enum.Material.Fabric,CFrame.Angles(-.1,0,0))
        for _,z in ipairs({-10.45,1.25}) do
            cylinder("TransportWheel",.95,3.65,Vector3.new(side*5.2,1.83,z),black)
            cylinder("TyreShoulder",1.03,3.35,Vector3.new(side*5.2,1.83,z),Color3.fromRGB(29,31,28))
            cylinder("SteelRim",1.05,2.15,Vector3.new(side*5.2,1.83,z),steel)
            cylinder("WheelHub",1.13,.82,Vector3.new(side*5.2,1.83,z),black)
            cylinder("RimWell",1.08,1.74,Vector3.new(side*5.2,1.83,z),Color3.fromRGB(52,58,55))
            cylinder("HubCover",1.16,.67,Vector3.new(side*5.2,1.83,z),steel)
            for j=1,8 do local angle=j*math.pi/4
                local hole=p("WheelVent",Vector3.new(.025,.27,.35),Vector3.new(side*5.75,1.83+math.cos(angle)*.72,z+math.sin(angle)*.72),black,Enum.Material.SmoothPlastic,CFrame.Angles(angle,0,0))
                U.make("SpecialMesh",hole,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)})
            end
            for j=1,20 do local a=j*math.pi/10
                p("TyreTread",Vector3.new(.93,.055,.20),Vector3.new(side*5.2,1.83+math.cos(a)*1.81,z+math.sin(a)*1.81),Color3.fromRGB(33,35,31),Enum.Material.SmoothPlastic,CFrame.Angles(a,0,0))
            end
            for j=1,6 do local angle=j*math.pi/3
                cylinder("WheelLug",1.15,.13,Vector3.new(side*5.2,1.83+math.cos(angle)*.61,z+math.sin(angle)*.61),Color3.fromRGB(162,166,154))
            end
            for j=0,12 do local a=(j+.5)*math.pi/13
                p("WheelArchLip",Vector3.new(.22,.16,.48),Vector3.new(side*4.87,1.83+math.sin(a)*1.98,z+math.cos(a)*1.98),paint,nil,CFrame.Angles(-a-math.pi/2,0,0))
                p("WheelWellLiner",Vector3.new(.32,.13,.47),Vector3.new(side*4.77,1.83+math.sin(a)*1.84,z+math.cos(a)*1.84),black,Enum.Material.SmoothPlastic,CFrame.Angles(-a-math.pi/2,0,0))
            end
        end
        local lamp=p("Headlamp",Vector3.new(1.4,.65,.09),Vector3.new(side*3.65,2.8,-14.28),Color3.fromRGB(221,215,179),Enum.Material.Neon)
        U.make("PointLight",lamp,{Color=Color3.fromRGB(232,220,175),Range=10,Brightness=.28,Shadows=false})
        p("Indicator",Vector3.new(.55,.28,.09),Vector3.new(side*4.35,3.36,-14.28),Color3.fromRGB(214,151,50),Enum.Material.Glass)
        p("TailLamp",Vector3.new(.38,1.0,.1),Vector3.new(side*4.55,2.95,4.58),Color3.fromRGB(147,41,35),Enum.Material.Glass)
        p("RearDoor",Vector3.new(4.7,4.25,.13),Vector3.new(side*2.39,4.25,4.54),paint)
        for y=2.9,5.4,2.5 do p("DoorHinge",Vector3.new(.22,.42,.23),Vector3.new(side*4.63,y,4.68),steel) end
        p("RearDoorHandle",Vector3.new(.2,.65,.18),Vector3.new(side*.4,3.6,4.7),black)
        local rearGlass=p("RearObservationGlass",Vector3.new(3.45,1.2,.04),Vector3.new(side*2.37,5.36,4.63),glass,Enum.Material.Glass) rearGlass.Transparency=.10
        for _,y in ipairs({4.71,6.0}) do p("RearGlassSeal",Vector3.new(3.57,.065,.05),Vector3.new(side*2.37,y,4.67),black) end
        p("DoorPressLine",Vector3.new(4.15,.035,.025),Vector3.new(side*2.38,2.71,4.64),black)
        p("CabBeltline",Vector3.new(.04,.05,3.2),Vector3.new(side*4.91,4.74,-10.1),steel)
        p("CabDoorLowerSeam",Vector3.new(.04,.025,3.15),Vector3.new(side*4.91,2.70,-10.1),black)
        p("SeatHeadrest",Vector3.new(1.35,.72,.46),Vector3.new(side*2.7,5.65,-9.16),black,Enum.Material.Fabric)
        p("Seatbelt",Vector3.new(.12,1.9,.06),Vector3.new(side*2.7,4.8,-9.49),Color3.fromRGB(53,57,51),Enum.Material.Fabric,CFrame.Angles(0,0,side*.30))
    end
    p("Dashboard",Vector3.new(8.5,.6,1.25),Vector3.new(0,4.7,-11.75),black)
    p("InstrumentHood",Vector3.new(2.3,.38,.7),Vector3.new(-2.6,5.08,-11.45),black)
    p("InstrumentGlass",Vector3.new(1.8,.3,.035),Vector3.new(-2.6,5.05,-11.07),glass,Enum.Material.Glass)
    for j=1,2 do
        local dial=p("Gauge",Vector3.new(.07,.23,.23),Vector3.new(-3.05+j*.32,5.04,-11.04),Color3.fromRGB(168,171,142),Enum.Material.SmoothPlastic,CFrame.Angles(0,math.pi/2,0)) dial.Shape=Enum.PartType.Cylinder
    end
    p("SteeringColumn",Vector3.new(.23,.23,.75),Vector3.new(-2.7,4.67,-11.04),black,nil,CFrame.Angles(.2,0,0))
    for j=1,12 do local a=j*math.pi/6
        p("SteeringRim",Vector3.new(.13,.13,.39),Vector3.new(-2.7+math.cos(a)*.68,4.95+math.sin(a)*.68,-10.63),black,Enum.Material.SmoothPlastic,CFrame.Angles(0,math.pi/2,a))
    end
    p("SteeringHub",Vector3.new(.42,.33,.14),Vector3.new(-2.7,4.95,-10.63),black)
    p("SteeringSpoke",Vector3.new(1.1,.09,.1),Vector3.new(-2.7,4.95,-10.63),steel)
    for _,z in ipairs({-10.45,1.25}) do
        cylinder("Axle",9.3,.30,Vector3.new(0,1.83,z),black)
        cylinder("BrakeDrum",8.9,1.35,Vector3.new(0,1.83,z),Color3.fromRGB(54,59,54))
        p("LeafSpring",Vector3.new(6.7,.15,1.5),Vector3.new(0,1.4,z),steel)
    end
    p("FuelTank",Vector3.new(3,.9,3.4),Vector3.new(-2.5,1.45,-4.6),black)
    p("Exhaust",Vector3.new(.18,.18,9.4),Vector3.new(3.1,1.42,-.8),steel)
    p("RadiatorRecess",Vector3.new(5.8,1.15,.09),Vector3.new(0,2.95,-14.22),black)
    p("Wiper",Vector3.new(2.4,.055,.08),Vector3.new(-2,4.65,-12.27),black,nil,CFrame.Angles(0,0,-.15))
    p("Wiper",Vector3.new(2.4,.055,.08),Vector3.new(2,4.65,-12.27),black,nil,CFrame.Angles(0,0,-.15))
    for j=1,8 do p("GrilleSlat",Vector3.new(5.5,.055,.12),Vector3.new(0,2.45+j*.11,-14.31),black) end
    p("GrilleBadge",Vector3.new(.5,.28,.15),Vector3.new(0,2.95,-14.45),steel)
    local plate=p("NumberPlate",Vector3.new(1.8,.52,.09),Vector3.new(0,1.99,-14.57),Color3.fromRGB(191,185,157))
    local gui=U.make("SurfaceGui",plate,{Face=Enum.NormalId.Front,PixelsPerStud=70,MaxDistance=32})
    U.make("TextLabel",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="DS / "..tostring(id),Font=Enum.Font.GothamBold,TextSize=19,TextColor3=black})
    p("RoofVent",Vector3.new(2.2,.18,3.7),Vector3.new(0,7.03,-.3),black)
    for j=1,5 do p("VentFin",Vector3.new(2.0,.07,.07),Vector3.new(0,7.15,-2+j*.55),steel) end
    m:SetAttribute("ArtRevision",4) m:SetAttribute("WheelOpenings",true)
    Art.transport(m,cf)
    return m
end
return V
