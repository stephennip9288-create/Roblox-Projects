local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local Blueprints=require(RS.DeadSignal.WeaponBlueprints)
local Detail=require(RS.DeadSignal.WeaponDetail)
local ThirdPerson=require(RS.DeadSignal.ThirdPerson)
local ArtAssets=require(RS.DeadSignal.ArtAssets)
local W={} local poses=setmetatable({},{__mode="k"})
function W.aimHeight(id) return Blueprints[id].sight end
function W.aimFov(id) return Blueprints[id].aimFov or 57 end
function W.scoped(id) return Blueprints[id].scope==true end
function W.build(id,skin,tier,parent,arms)
    local def=C.Weapons[id] local bp=Blueprints[id] assert(bp,"Missing weapon blueprint: "..tostring(id))
    local m=U.make("Model",parent,{Name="Weapon_"..id})
    local paint=U.color(def.color) local metal=Color3.fromRGB(54,60,61) local dark=Color3.fromRGB(22,26,27)
    local edge=Color3.fromRGB(107,115,115) local wood=Color3.fromRGB(115,76,42) local rubber=Color3.fromRGB(33,36,34)
    for _,s in ipairs(C.Skins) do if s.id==skin and skin~="Factory" then paint=U.color(s.color) wood=paint end end
    local pose={parts={},bp=bp} poses[m]=pose
    local function raw(name,size,pos,color,material,group,rot,class)
        local part=U.make(class or "Part",m,{Name=name,Size=size,CFrame=CFrame.new(pos)*(rot or CFrame.new()),Color=color or paint,
            Material=material or Enum.Material.Metal,Reflectance=material==Enum.Material.SmoothPlastic and 0 or .035,
            Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        table.insert(pose.parts,{part=part,cf=part.CFrame,group=group or "body"}) return part
    end
    -- Extruded octagonal sections replace the old square receiver/stock silhouettes.
    -- Every chamfer belongs to the same moving group as its parent component.
    local shaped={Receiver=true,Slide=true,PistolFrame=true,WoodStock=true,IntegralStock=true,
        AdjustableStock=true,Handguard=true,PumpForend=true,EnclosedForend=true,CeramicHousing=true}
    local function p(name,size,pos,color,material,group,rot,class)
        if not shaped[name] or class then return raw(name,size,pos,color,material,group,rot,class) end
        local b=math.min(size.X,size.Y)*.16 local base=CFrame.new(pos)*(rot or CFrame.identity)
        local core=raw(name,Vector3.new(size.X-2*b,size.Y,size.Z),pos,color,material,group,rot)
        raw(name.."Web",Vector3.new(size.X,size.Y-2*b,size.Z),pos,color,material,group,rot)
        for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
            local cf=base*CFrame.new(x*(size.X/2-b),y*(size.Y/2-b),0)*CFrame.Angles(0,math.pi/2,0)
            local cap=raw(name.."Radius",Vector3.new(size.Z,b*2,b*2),cf.Position,color,material,group,cf-cf.Position)
            cap.Shape=Enum.PartType.Cylinder
        end end
        return core
    end
    local function tube(name,radius,length,pos,color,group)
        local t=p(name,Vector3.new(length,radius*2,radius*2),pos,color,Enum.Material.Metal,group,CFrame.Angles(0,math.pi/2,0))
        t.Shape=Enum.PartType.Cylinder return t
    end
    local function ball(name,radius,pos,color,group)
        local b=p(name,Vector3.new(radius*2,radius*2,radius*2),pos,color,nil,group) b.Shape=Enum.PartType.Ball return b
    end
    local root=p("Root",Vector3.new(.05,.05,.05),Vector3.new(),dark) root.Transparency=1 m.PrimaryPart=root
    local kind=bp.kind local pistol=kind=="Pistol" or kind=="Revolver" or kind=="MachinePistol"
    local longWood=kind=="WoodCarbine" or kind=="WoodBolt" or kind=="Pump" or kind=="Double"
    local energy=kind=="Signal" or kind=="Arc"
    local barrelEnd=-.55-bp.barrel
    if pistol then
        if kind=="Revolver" then
            p("RevolverFrame",Vector3.new(.27,.3,.8),Vector3.new(0,.02,-.25),metal)
            p("TopStrap",Vector3.new(.23,.12,.85),Vector3.new(0,.24,-.35),edge)
            tube("Cylinder",.24,.53,Vector3.new(0,.02,-.19),metal,"cylinder")
            for n=1,6 do local a=n*math.pi/3
                tube("CylinderChamber",.064,.035,Vector3.new(math.cos(a)*.155,.02+math.sin(a)*.155,-.475),dark,"cylinder")
                p("CylinderFlute",Vector3.new(.04,.04,.43),Vector3.new(math.cos(a)*.239,.02+math.sin(a)*.239,-.19),edge,nil,"cylinder")
            end
            p("Hammer",Vector3.new(.12,.17,.15),Vector3.new(0,.20,.23),metal)
            p("Grip",Vector3.new(.32,.65,.32),Vector3.new(0,-.43,.27),wood,Enum.Material.Wood,nil,CFrame.Angles(-.32,0,0))
            tube("Barrel",.095,bp.barrel,Vector3.new(0,.09,-.52-bp.barrel/2),metal)
        else
            p("PistolFrame",Vector3.new(.31,.27,.93),Vector3.new(0,-.11,-.19),paint,Enum.Material.SmoothPlastic)
            p("Slide",Vector3.new(.33,.25,kind=="MachinePistol" and .8 or 1.13),Vector3.new(0,.09,-.24),metal,nil,"slide")
            p("Grip",Vector3.new(.3,.65,.32),Vector3.new(0,-.42,.17),rubber,Enum.Material.SmoothPlastic,nil,CFrame.Angles(-.22,0,0))
            tube("Barrel",.07,bp.barrel,Vector3.new(0,.085,-.43-bp.barrel/2),metal)
            for side=-1,1,2 do for n=1,5 do
                p("SlideSerration",Vector3.new(.017,.19,.035),Vector3.new(side*.177,.1,.24-n*.075),dark,nil,"slide")
            end end
            p("EjectionPort",Vector3.new(.017,.12,.2),Vector3.new(.175,.1,-.3),dark,nil,"slide")
        end
        for side=-1,1,2 do
            for n=1,5 do p("GripCheckering",Vector3.new(.017,.02,.27),Vector3.new(side*.16,-.22-n*.067,.2),metal,Enum.Material.SmoothPlastic) end
            ball("GripScrew",.027,Vector3.new(side*.17,-.26,.2),edge)
        end
        p("TriggerGuardLower",Vector3.new(.25,.075,.43),Vector3.new(0,-.42,-.22),metal)
        p("TriggerGuardFront",Vector3.new(.25,.25,.07),Vector3.new(0,-.29,-.42),metal)
        p("Trigger",Vector3.new(.055,.17,.07),Vector3.new(0,-.25,-.22),dark)
        p("Magazine",Vector3.new(.24,bp.mag,.24),Vector3.new(0,-.46,.15),metal,nil,"mag")
        if kind=="Revolver" then m.Magazine.Transparency=1 end
        if kind=="MachinePistol" then
            p("MagazineFoot",Vector3.new(.29,.1,.32),Vector3.new(0,-1,.15),dark,nil,"mag")
            p("MuzzleBrake",Vector3.new(.33,.27,.32),Vector3.new(0,.07,barrelEnd-.02),metal)
            for _,x in ipairs({-.24,.24}) do p("WireStockRail",Vector3.new(.065,.065,.9),Vector3.new(x,-.02,.76),edge) end
            p("WireButt",Vector3.new(.5,.5,.08),Vector3.new(0,-.2,1.2),dark)
        end
    else
        local receiverWidth=(kind=="Belt" or kind=="DrumLMG" or energy) and .48 or .34
        local receiverLength=(kind=="Bullpup" or kind=="TopPDW") and 1.5 or 1.1
        p("Receiver",Vector3.new(receiverWidth,.38,receiverLength),Vector3.new(0,0,-.05),longWood and metal or paint)
        p("ReceiverBevel",Vector3.new(receiverWidth*.75,.035,receiverLength*.93),Vector3.new(0,.20,-.05),metal)
        p("LowerReceiver",Vector3.new(receiverWidth*.87,.22,.62),Vector3.new(0,-.25,.09),metal)
        p("EjectionPort",Vector3.new(.018,.16,.34),Vector3.new(receiverWidth/2+.015,.07,-.2),dark)
        p("ChargingHandle",Vector3.new(.23,.07,.09),Vector3.new(receiverWidth/2+.1,.11,.25),edge,nil,"bolt")
        for side=-1,1,2 do for z=-.38,.3,.34 do ball("ReceiverPin",.025,Vector3.new(side*(receiverWidth/2+.018),-.08,z),edge) end end
        if longWood then
            p("StockWrist",Vector3.new(.3,.36,.64),Vector3.new(0,-.18,.56),wood,Enum.Material.Wood,nil,CFrame.Angles(-.13,0,0))
            p("WoodStock",Vector3.new(.35,.57,1.02),Vector3.new(0,-.25,1.12),wood,Enum.Material.Wood)
            p("StockComb",Vector3.new(.31,.15,.88),Vector3.new(0,.06,1.04),wood,Enum.Material.Wood)
            p("WoodStockToe",Vector3.new(.34,.24,.67),Vector3.new(0,-.59,1.17),wood,Enum.Material.Wood,nil,nil,"WedgePart")
            p("ButtPad",Vector3.new(.37,.65,.12),Vector3.new(0,-.24,1.68),rubber,Enum.Material.SmoothPlastic)
        elseif kind=="Bullpup" or kind=="TopPDW" then
            p("IntegralStock",Vector3.new(.47,.64,.95),Vector3.new(0,-.11,.7),paint,Enum.Material.SmoothPlastic)
            p("ButtPad",Vector3.new(.48,.7,.1),Vector3.new(0,-.14,1.21),rubber,Enum.Material.SmoothPlastic)
            p("Grip",Vector3.new(.29,.62,.3),Vector3.new(0,-.43,-.43),rubber,Enum.Material.SmoothPlastic,nil,CFrame.Angles(-.16,0,0))
            p("ThumbholeUpper",Vector3.new(.14,.14,.57),Vector3.new(0,-.42,.1),paint,Enum.Material.SmoothPlastic)
        elseif kind=="Compact" or kind=="TubeSMG" then
            for side=-1,1,2 do p("FoldingStockStrut",Vector3.new(.075,.08,.95),Vector3.new(side*.22,0,.85),edge) end
            p("SkeletonButt",Vector3.new(.5,.5,.12),Vector3.new(0,-.16,1.37),dark)
            p("Grip",Vector3.new(.3,.64,.32),Vector3.new(0,-.46,.23),rubber,Enum.Material.SmoothPlastic,nil,CFrame.Angles(-.16,0,0))
        else
            tube("StockBuffer",.11,.72,Vector3.new(0,0,.82),metal)
            p("AdjustableStock",Vector3.new(.36,.52,.68),Vector3.new(0,-.19,1.13),paint,Enum.Material.SmoothPlastic)
            p("StockLowerBevel",Vector3.new(.33,.28,.6),Vector3.new(0,-.55,1.2),paint,Enum.Material.SmoothPlastic,nil,nil,"WedgePart")
            p("ButtPad",Vector3.new(.4,.65,.1),Vector3.new(0,-.19,1.5),rubber,Enum.Material.SmoothPlastic)
            p("Grip",Vector3.new(.29,.65,.3),Vector3.new(0,-.46,.21),rubber,Enum.Material.SmoothPlastic,nil,CFrame.Angles(-.2,0,0))
        end
        p("TriggerGuard",Vector3.new(.28,.08,.46),Vector3.new(0,-.44,-.12),metal)
        p("TriggerGuardFront",Vector3.new(.28,.23,.08),Vector3.new(0,-.3,-.34),metal)
        p("Trigger",Vector3.new(.055,.15,.065),Vector3.new(0,-.3,-.09),dark)
        local magZ=(kind=="Bullpup") and .45 or -.3
        local mag=p("Magazine",Vector3.new(.24,bp.mag,.36),Vector3.new(0,-.38-bp.mag/2,magZ),metal,nil,"mag",CFrame.Angles(-.1,0,0))
        for side=-1,1,2 do for n=1,3 do p("MagazineRib",Vector3.new(.016,bp.mag*.74,.02),Vector3.new(side*.135,-.4-bp.mag/2,magZ-.16+n*.08),edge,nil,"mag") end end
        tube("Barrel",.085,bp.barrel,Vector3.new(0,.03,-.55-bp.barrel/2),metal)
        tube("MuzzleCrown",.108,.14,Vector3.new(0,.03,barrelEnd-.055),edge)
        tube("MuzzleBore",.072,.018,Vector3.new(0,.03,barrelEnd-.13),dark)
        if kind=="Double" then
            mag.Transparency=1 m.Barrel.Transparency=1 m.MuzzleCrown.Transparency=1 m.MuzzleBore.Transparency=1
            for side=-1,1,2 do
                tube("TwinBarrel",.105,bp.barrel,Vector3.new(side*.115,.025,-.55-bp.barrel/2),metal,"front")
                tube("TwinBore",.07,.022,Vector3.new(side*.115,.025,barrelEnd-.01),dark,"front")
                p("TwinHammer",Vector3.new(.06,.16,.14),Vector3.new(side*.12,.27,.29),metal)
            end
            p("DoubleRib",Vector3.new(.06,.05,bp.barrel),Vector3.new(0,.14,-.55-bp.barrel/2),edge,nil,"front")
            p("WoodForend",Vector3.new(.4,.26,1.05),Vector3.new(0,-.16,-1.06),wood,Enum.Material.Wood,"front")
            p("BreakLever",Vector3.new(.06,.05,.25),Vector3.new(.09,.26,.08),metal)
        elseif kind=="Pump" or kind=="TacticalShot" or kind=="AutoShot" then
            if kind~="AutoShot" then mag.Transparency=1 end
            tube("MagazineTube",.105,bp.barrel-.15,Vector3.new(0,-.18,-.55-(bp.barrel-.15)/2),metal)
            p("PumpForend",Vector3.new(.4,.31,.82),Vector3.new(0,-.14,-1.18),kind=="Pump" and wood or rubber,kind=="Pump" and Enum.Material.Wood or Enum.Material.SmoothPlastic,"pump")
            for n=1,7 do p("PumpGroove",Vector3.new(.43,.027,.026),Vector3.new(0,-.28,-.79-n*.1),dark,nil,"pump") end
            p("ShellPort",Vector3.new(.2,.02,.31),Vector3.new(0,-.38,-.03),dark)
            if arms then tube("ReloadShell",.063,.25,Vector3.new(-.27,-.3,-.15),Color3.fromRGB(174,66,44),"shell").Transparency=1 end
        elseif energy then
            mag.Transparency=1 m.Barrel.Transparency=1
            p("CeramicHousing",Vector3.new(.52,.46,.93),Vector3.new(0,-.015,-1),Color3.fromRGB(175,176,160),Enum.Material.SmoothPlastic)
            tube("EnergyCell",.24,.74,Vector3.new(0,-.44,-.2),metal,"mag")
            for n=1,6 do
                local ring=tube("InductionRing",.28,.055,Vector3.new(0,.035,-.73-n*.19),paint)
                ring.Material=Enum.Material.Neon
                tube("CoilCore",.105,.15,Vector3.new(0,.035,-.73-n*.19),dark)
            end
            for side=-1,1,2 do
                p("EmitterProng",Vector3.new(.11,.15,kind=="Arc" and 1.05 or .66),Vector3.new(side*.28,.03,barrelEnd+.18),metal)
                p("EnergyBus",Vector3.new(.06,.06,1.3),Vector3.new(side*.26,.24,-1.12),paint,Enum.Material.Neon)
            end
            ball("FieldLens",.18,Vector3.new(0,.03,barrelEnd-.08),paint).Material=Enum.Material.Neon
        elseif kind=="TubeSMG" or kind=="Compact" then
            if kind=="TubeSMG" then m.Receiver.Transparency=1 m.ReceiverBevel.Transparency=1 tube("TubularReceiver",.21,1.1,Vector3.new(0,0,-.05),paint) end
            tube("BarrelShroud",.16,.7,Vector3.new(0,.03,-.88),paint)
            for n=1,5 do for side=-1,1,2 do p("ShroudSlot",Vector3.new(.018,.09,.04),Vector3.new(side*.167,.035,-.54-n*.12),dark) end end
        elseif kind=="TopPDW" then
            mag.Transparency=1
            local top=p("HorizontalMagazine",Vector3.new(.33,.14,1.35),Vector3.new(0,.28,-.14),Color3.fromRGB(153,128,75),Enum.Material.Glass,"mag") top.Transparency=.2
            for n=1,10 do tube("VisibleCartridge",.04,.25,Vector3.new(0,.3,.49-n*.105),Color3.fromRGB(162,132,65),"mag") end
            p("EnclosedForend",Vector3.new(.49,.55,.8),Vector3.new(0,-.13,-.98),paint,Enum.Material.SmoothPlastic)
        else
            local length=kind=="WoodCarbine" and 1.25 or kind=="WoodBolt" and 1.5 or 1.05
            p("Handguard",Vector3.new(.38,.3,length),Vector3.new(0,-.07,-.62-length/2),longWood and wood or paint,longWood and Enum.Material.Wood or Enum.Material.Metal)
            for n=1,8 do
                p("HandguardGroove",Vector3.new(.41,.021,.032),Vector3.new(0,-.21,-.57-n*.12),dark)
                if not longWood then for side=-1,1,2 do p("CoolingSlot",Vector3.new(.015,.075,.08),Vector3.new(side*.2,.03,-.57-n*.12),dark) end end
            end
        end
        if kind=="DrumLMG" or kind=="AutoShot" then
            mag.Transparency=1
            local drum=p("MagazineDrum",Vector3.new(.72,.85,.85),Vector3.new(0,-.64,-.31),metal,nil,"mag") drum.Shape=Enum.PartType.Cylinder
            local cap=p("DrumCap",Vector3.new(.76,.62,.62),Vector3.new(0,-.64,-.31),edge,nil,"mag") cap.Shape=Enum.PartType.Cylinder
        elseif kind=="Belt" then
            mag.Transparency=1
            p("AmmoBox",Vector3.new(.74,.68,.62),Vector3.new(.25,-.57,-.27),paint,nil,"mag")
            p("FeedCover",Vector3.new(.51,.14,.9),Vector3.new(0,.26,-.04),metal)
            for n=1,6 do tube("FeedRound",.045,.33,Vector3.new(.24+n*.075,-.04,-.3),Color3.fromRGB(175,141,62)) end
        end
        if kind=="WoodBolt" or kind=="Precision" or kind=="DMR" then
            p("ScopeMount",Vector3.new(.2,.2,.62),Vector3.new(0,.28,-.1),metal)
            tube("ScopeTube",.14,.86,Vector3.new(0,bp.sight,-.08),dark)
            tube("ScopeBell",.19,.3,Vector3.new(0,bp.sight,-.57),metal)
            tube("ScopeEyecup",.17,.16,Vector3.new(0,bp.sight,.42),rubber)
            local lens=tube("ScopeLens",.133,.021,Vector3.new(0,bp.sight,.508),Color3.fromRGB(77,124,131)) lens.Material=Enum.Material.Glass lens.Transparency=.2
            for _,z in ipairs({-.33,.19}) do tube("ScopeRing",.16,.055,Vector3.new(0,bp.sight,z),edge) end
            p("ScopeTurret",Vector3.new(.15,.15,.15),Vector3.new(0,bp.sight+.19,-.08),metal)
            p("BoltLever",Vector3.new(.28,.07,.07),Vector3.new(.25,-.025,.27),metal,nil,"bolt",CFrame.Angles(0,0,-.25)) ball("BoltKnob",.064,Vector3.new(.4,-.06,.27),dark,"bolt")
        end
        if kind=="Precision" or kind=="Belt" or kind=="DrumLMG" then
            for side=-1,1,2 do
                p("FoldedBipod",Vector3.new(.06,.08,.9),Vector3.new(side*.27,-.23,-1.78),metal)
                p("BipodFoot",Vector3.new(.17,.1,.09),Vector3.new(side*.27,-.22,-2.22),dark)
            end
        end
        if not longWood then for n=1,11 do p("TopRail",Vector3.new(.32,.035,.03),Vector3.new(0,.25,.4-n*.09),edge) end end
    end
    if m.Magazine.Transparency==1 then
        for _,q in ipairs(m:GetChildren()) do if q.Name=="MagazineRib" then q.Transparency=1 end end
    end
    -- Iron sights, serial plaque and finish details exist on every model.
    -- A true open rear notch leaves the shot axis visible; the front post ends below it.
    p("SightRear",Vector3.new(.27,.045,.08),Vector3.new(0,bp.sight-.115,.37),dark)
    for side=-1,1,2 do p("RearSightEar",Vector3.new(.06,.12,.08),Vector3.new(side*.105,bp.sight-.05,.37),dark) end
    p("SightNotch",Vector3.new(.055,.02,.025),Vector3.new(0,bp.sight-.086,.319),edge)
    p("FrontSightTower",Vector3.new(.11,bp.sight-.045,.10),Vector3.new(0,(bp.sight-.045)/2,barrelEnd+.1),metal)
    p("SightFront",Vector3.new(.045,.11,.07),Vector3.new(0,bp.sight-.075,barrelEnd+.1),dark)
    p("FrontSightDot",Vector3.new(.024,.021,.015),Vector3.new(0,bp.sight-.025,barrelEnd+.144),Color3.fromRGB(212,213,173))
    local plaque=p("SerialPlate",Vector3.new(.018,.09,.27),Vector3.new(pistol and .175 or .252,-.07,-.06),edge)
    local gui=U.make("SurfaceGui",plaque,{Face=Enum.NormalId.Right,PixelsPerStud=120,MaxDistance=18})
    U.make("TextLabel",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="09.6 / "..id:upper(),TextColor3=dark,Font=Enum.Font.Code,TextScaled=true})
    local muzzle=p("Muzzle",Vector3.new(.025,.025,.025),Vector3.new(0,.03,barrelEnd-.15),dark) muzzle.Transparency=1
    U.make("PointLight",muzzle,{Name="Flash",Brightness=0,Range=9,Color=Color3.fromRGB(255,206,113)})
    if tier>0 then
        for side=-1,1,2 do p("ResonanceConduit",Vector3.new(.035,.035,.65),Vector3.new(side*(pistol and .182 or .26),.14,-.28),Color3.fromRGB(83,220,229),Enum.Material.Neon) end
    end
    Detail.build(m,bp,p,tube,ball,{paint=paint,metal=metal,dark=dark,edge=edge,wood=wood,rubber=rubber},arms)
    if arms then
        local glove=Color3.fromRGB(43,50,48) local cuff=Color3.fromRGB(80,89,76)
        local function soft(name,size,at,color,mat,group,rot)
            local q=p(name,size,at,color,mat,group,rot)
            U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) return q
        end
        soft("RightArm",Vector3.new(.40,.43,1.36),Vector3.new(.36,-.65,.86),cuff,Enum.Material.Fabric,"right",CFrame.Angles(-.08,.08,-.04))
        soft("RightGlove",Vector3.new(.36,.34,.41),Vector3.new(.14,-.37,.24),glove,Enum.Material.SmoothPlastic,"right")
        soft("LeftArm",Vector3.new(.40,.39,1.16),Vector3.new(-.36,-.44,-.19),cuff,Enum.Material.Fabric,"left",CFrame.Angles(-.1,-.14,.08))
        soft("LeftGlove",Vector3.new(.36,.3,.46),Vector3.new(-.22,-.23,pistol and -.29 or -1.03),glove,Enum.Material.SmoothPlastic,"left")
        soft("RightThumb",Vector3.new(.13,.23,.16),Vector3.new(-.02,-.31,.21),glove,Enum.Material.SmoothPlastic,"right",CFrame.Angles(.1,0,-.28))
        soft("LeftThumb",Vector3.new(.14,.16,.3),Vector3.new(-.09,-.20,pistol and -.25 or -.98),glove,Enum.Material.SmoothPlastic,"left",CFrame.Angles(.1,.2,.2))
        soft("WristCuff",Vector3.new(.39,.38,.15),Vector3.new(.28,-.53,.56),Color3.fromRGB(56,64,54),Enum.Material.Fabric,"right")
        soft("WristCuff",Vector3.new(.37,.33,.14),Vector3.new(-.29,-.34,pistol and -.10 or -.72),Color3.fromRGB(56,64,54),Enum.Material.Fabric,"left")
        for n=1,3 do
            soft("RightFinger",Vector3.new(.075,.20,.14),Vector3.new(.16+n*.06,-.36,.075),glove,Enum.Material.SmoothPlastic,"right")
            soft("LeftFinger",Vector3.new(.075,.12,.23),Vector3.new(-.33+n*.06,-.34,pistol and -.34 or -1.12),glove,Enum.Material.SmoothPlastic,"left")
            soft("GloveKnuckle",Vector3.new(.07,.055,.09),Vector3.new(.16+n*.06,-.26,.12),Color3.fromRGB(62,69,64),Enum.Material.SmoothPlastic,"right")
        end
        p("MeleeBlade",Vector3.new(.07,.07,.91),Vector3.new(.2,-.16,-.75),edge,nil,"knife").Transparency=1
        p("KnifeGuard",Vector3.new(.3,.06,.08),Vector3.new(.2,-.16,-.26),dark,nil,"knife").Transparency=1
    end
    m:SetAttribute("Blueprint",kind) m:SetAttribute("SightHeight",bp.sight)
    m:SetAttribute("Scoped",bp.scope==true)
    for _,entry in ipairs(pose.parts) do entry.transparency=entry.part.Transparency
        entry.optic=entry.part.Name:find("Scope")~=nil end
    local imported=ArtAssets.family("Weapon_"..id)
    if arms then ArtAssets.viewArms(m,pose,pistol) end
    if id=="Kestrel" or id=="Longwatch" then
        ArtAssets.weapon(m,id,pose,skin~="Factory" and paint or nil)
    end
    -- Continuous bevels and fixed receiver webs replace the open chamfer shells.
    for _,entry in ipairs(pose.parts) do local q=entry.part
        if q:IsA("MeshPart") then q.DoubleSided=true
        elseif q.Material==Enum.Material.Metal then q.MaterialVariant="DS_Steel"
        elseif q.Material==Enum.Material.Wood then q.Material=Enum.Material.WoodPlanks q.MaterialVariant="DS_Wood"
        elseif q.Material==Enum.Material.Rubber then q.MaterialVariant="DS_Rubber" end
    end
    m:SetAttribute("WeaponArtRevision",8)
    return m
end
function W.groups(model)
    local out={} for _,entry in ipairs((poses[model] or {}).parts or {}) do out[entry.part.Name]=entry.group end return out
end
function W.aim(model,enabled)
    local data=poses[model] if not data then return end
    for _,entry in ipairs(data.parts) do
        if entry.optic then entry.part.LocalTransparencyModifier=enabled and 1 or 0 end
    end
end
function W.pose(model,reload,melee,equip,recoil)
    local data=poses[model] if not data or not model.PrimaryPart then return end
    local root=model.PrimaryPart.CFrame local out=reload>0 and math.sin(math.pi*math.clamp((reload-.07)/.7,0,1)) or 0
    local hand=reload>0 and math.sin(reload*math.pi) or 0
    local rack=reload>.78 and math.sin((reload-.78)/.22*math.pi)*.2 or 0
    for _,entry in ipairs(data.parts) do local p=entry.part if p.Parent and p~=model.PrimaryPart then
        local cf=entry.cf local g=entry.group
        if g=="mag" then cf=CFrame.new(0,-out*.7,out*.13)*cf*CFrame.Angles(0,0,out*.18)
        elseif g=="cylinder" then cf=CFrame.new(-out*.32,0,0)*cf*CFrame.Angles(0,0,out*.5)
        elseif g=="bolt" then cf=CFrame.new(0,0,rack)*cf
        elseif g=="slide" then cf=CFrame.new(0,0,(recoil or 0)*.045)*cf
        elseif g=="front" then cf=CFrame.new(0,0,-.4)*CFrame.Angles(-hand*.55,0,0)*CFrame.new(0,0,.4)*cf
        elseif g=="pump" then cf=CFrame.new(0,0,(recoil or 0)*.025+hand*.08)*cf
        elseif g=="left" then cf=CFrame.new(hand*.24,-hand*.5,hand*.52)*cf*CFrame.Angles(hand*.5,0,-hand*.28)
        elseif g=="knife" then p.Transparency=melee>0 and 0 or 1
        elseif g=="shell" then p.Transparency=reload>.12 and reload<.77 and 0 or 1 end
        p.CFrame=root*cf
    end end
end
function W.attach(player,id,skin,tier)
    local char=player.Character if not char then return end
    ThirdPerson.clear(char)
    local model=W.build(id,skin,tier,char,false) model.Name="CarriedWeapon"
    ThirdPerson.attach(char,model,id,C.Weapons[id].class=="Pistol")
end
return W
