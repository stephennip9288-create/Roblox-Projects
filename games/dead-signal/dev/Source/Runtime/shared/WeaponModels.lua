local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local Rules=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local Blueprints=require(RS.DeadSignal.WeaponBlueprints)
local Detail=require(RS.DeadSignal.WeaponDetail)
local ThirdPerson=require(RS.DeadSignal.ThirdPerson)
local ArtAssets=require(RS.DeadSignal.ArtAssets)
local W={} local poses=setmetatable({},{__mode="k"})
local cosmeticSources=setmetatable({},{__mode="k"})
local tubeCapacities={}
for id,bp in pairs(Blueprints) do if bp.reloadStyle=="tube" then
    tubeCapacities[id]=Rules.weaponStats(C.Weapons[id],3,{}).mag
end end
local function tubeRounds(id,missing) return math.clamp(math.floor(missing or 3),1,tubeCapacities[id]) end
function W.aimHeight(id) return Blueprints[id].sight end
function W.aimFov(id) return Blueprints[id].aimFov or 57 end
function W.scoped(id) return Blueprints[id].scope==true end
function W.optic(id) return Blueprints[id].optic or (W.scoped(id) and "scope" or "iron") end
-- Keep the authored sight axis on the camera ray while FOV/aspect change.
-- Moving the eye back (rather than moving the sights sideways) also keeps a
-- narrow portrait viewport from cropping the rear notch and operator's hands.
function W.viewOffset(id,hip,alpha,fov,viewport)
    local bp=Blueprints[id]
    local aspect=viewport and math.max(1,viewport.Y/math.max(1,viewport.X)) or 1
    local depth=.78*math.tan(math.rad(57/2))/math.tan(math.rad(math.clamp(fov,30,110)/2))*aspect
    return hip:Lerp(Vector3.new(0,-bp.sight,-.37-depth),math.clamp(alpha,0,1))
end
function W.build(id,skin,tier,parent,arms)
    local def=C.Weapons[id] local bp=Blueprints[id] assert(bp,"Missing weapon blueprint: "..tostring(id))
    local m=U.make("Model",parent,{Name="Weapon_"..id})
    local paint=U.color(def.color)
    local metal=bp.finish=="blued" and Color3.fromRGB(36,43,51) or bp.finish=="alloy" and Color3.fromRGB(70,76,78) or Color3.fromRGB(54,60,61)
    local dark=Color3.fromRGB(22,26,27)
    local edge=Color3.fromRGB(107,115,115) local wood=Color3.fromRGB(115,76,42) local rubber=Color3.fromRGB(33,36,34)
    for _,s in ipairs(C.Skins) do if s.id==skin and skin~="Factory" then paint=U.color(s.color) wood=paint end end
    local pose={parts={},bp=bp,arms=arms,capacity=Rules.weaponStats(def,tier,{}).mag} poses[m]=pose
    local function raw(name,size,pos,color,material,group,rot,class)
        local part=U.make(class or "Part",m,{Name=name,Size=size,CFrame=CFrame.new(pos)*(rot or CFrame.new()),Color=color or paint,
            Material=material or Enum.Material.Metal,Reflectance=material==Enum.Material.SmoothPlastic and 0 or .035,
            Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        table.insert(pose.parts,{part=part,cf=part.CFrame,group=group or "body"}) return part
    end
    -- Extruded octagonal sections replace the old square receiver/stock silhouettes.
    -- Every chamfer belongs to the same moving group as its parent component.
    local shaped={Receiver=true,Slide=true,PistolFrame=true,WoodStock=true,IntegralStock=true,
        AdjustableStock=true,Handguard=true,PumpForend=true,AutoForend=true,EnclosedForend=true,CeramicHousing=true}
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
            for n=1,pose.capacity do local a=n*math.pi*2/pose.capacity
                tube("CylinderChamber",math.min(.064,math.pi*.155/pose.capacity*.78),.035,Vector3.new(math.cos(a)*.155,.02+math.sin(a)*.155,-.475),dark,"cylinder")
                p("CylinderFlute",Vector3.new(.04,.04,.43),Vector3.new(math.cos(a)*.239,.02+math.sin(a)*.239,-.19),edge,nil,"cylinder")
            end
            p("Hammer",Vector3.new(.12,.17,.15),Vector3.new(0,.20,.23),metal,nil,"hammer")
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
        p("Trigger",Vector3.new(.055,.17,.07),Vector3.new(0,-.25,-.22),dark,nil,"trigger")
        p("Magazine",Vector3.new(.24,bp.mag,.24),Vector3.new(0,-.46,.15),metal,nil,"mag")
        if kind=="Revolver" then m.Magazine.Transparency=1 end
        if kind=="MachinePistol" then
            p("MagazineFoot",Vector3.new(.29,.1,.32),Vector3.new(0,-1,.15),dark,nil,"mag")
            p("MuzzleBrake",Vector3.new(.33,.27,.32),Vector3.new(0,.07,barrelEnd-.02),metal)
            for _,x in ipairs({-.24,.24}) do p("WireStockRail",Vector3.new(.065,.065,.9),Vector3.new(x,-.02,.76),edge) end
            p("WireButt",Vector3.new(.5,.5,.08),Vector3.new(0,-.2,1.2),dark)
        end
    else
        local receiverWidth=bp.bodyWidth local receiverLength=bp.bodyLength local receiverHeight=bp.bodyHeight
        p("Receiver",Vector3.new(receiverWidth,receiverHeight,receiverLength),Vector3.new(0,0,-.05),longWood and metal or paint)
        p("ReceiverBevel",Vector3.new(receiverWidth*.75,.035,receiverLength*.93),Vector3.new(0,receiverHeight/2+.01,-.05),metal)
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
        p("Trigger",Vector3.new(.055,.15,.065),Vector3.new(0,-.3,-.09),dark,nil,"trigger")
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
            local actionGroup=kind=="AutoShot" and "body" or "pump"
            p(kind=="AutoShot" and "AutoForend" or "PumpForend",Vector3.new(.4,.31,.82),Vector3.new(0,-.14,-1.18),kind=="Pump" and wood or rubber,kind=="Pump" and Enum.Material.Wood or Enum.Material.SmoothPlastic,actionGroup)
            for n=1,7 do p("PumpGroove",Vector3.new(.43,.027,.026),Vector3.new(0,-.28,-.79-n*.1),dark,nil,actionGroup) end
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
            p("FeedCover",Vector3.new(.51,.14,.9),Vector3.new(0,.26,-.04),metal,nil,"feed")
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
    local function sights(front)
        p("SightRear",Vector3.new(.27,.045,.08),Vector3.new(0,bp.sight-.115,.37),dark)
        for side=-1,1,2 do
            p("RearSightEar",Vector3.new(.06,.12,.08),Vector3.new(side*.105,bp.sight-.05,.37),dark)
            p("RearSightIndex",Vector3.new(.021,.022,.012),Vector3.new(side*.105,bp.sight-.017,.416),Color3.fromRGB(212,213,173))
            p("FrontSightGuard",Vector3.new(.025,.10,.08),Vector3.new(side*.095,bp.sight-.07,front),metal)
        end
        p("SightNotch",Vector3.new(.055,.02,.025),Vector3.new(0,bp.sight-.086,.319),edge)
        p("FrontSightTower",Vector3.new(.11,bp.sight-.045,.10),Vector3.new(0,(bp.sight-.045)/2,front),metal)
        p("SightFront",Vector3.new(.035,.11,.07),Vector3.new(0,bp.sight-.075,front),dark)
        p("FrontSightDot",Vector3.new(.019,.018,.015),Vector3.new(0,bp.sight-.029,front+.044),Color3.fromRGB(212,213,173))
    end
    sights(barrelEnd+.1)
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
        if bp.reloadStyle=="break" then for side=-1,1,2 do
            local shell=tube("BreechLoadShell",.064,.26,Vector3.new(side*.115,.025,-.30),Color3.fromRGB(155,58,40),"loadshell") shell.Transparency=1
        end end
        if bp.reloadStyle=="cylinder" then for n=1,pose.capacity do local a=n*math.pi*2/pose.capacity
            tube("SpeedLoadRound",math.min(.045,math.pi*.155/pose.capacity*.6),.23,Vector3.new(math.cos(a)*.155,.02+math.sin(a)*.155,.16),Color3.fromRGB(166,135,72),"loadshell").Transparency=1
        end end
    end
    m:SetAttribute("WeaponId",id) m:SetAttribute("Blueprint",kind) m:SetAttribute("SightHeight",bp.sight)
    m:SetAttribute("Scoped",bp.scope==true)
    for _,entry in ipairs(pose.parts) do entry.transparency=entry.part.Transparency
        entry.optic=entry.part.Name:find("Scope")~=nil end
    if arms then ArtAssets.viewArms(m,pose,pistol) end
    if id=="Kestrel" or id=="Longwatch" then
        if ArtAssets.weapon(m,id,pose,skin~="Factory" and paint or nil) then
            -- Imported geometry replaces the procedural sights. Restore the open
            -- sight assembly against its actual muzzle, not the fallback barrel.
            sights(m.Muzzle.Position.Z+.2)
            for _,entry in ipairs(pose.parts) do
                if entry.transparency==nil then entry.transparency=entry.part.Transparency end
                if entry.optic==nil then entry.optic=entry.part.Name:find("Scope")~=nil end
            end
        end
    end
    Detail.fidelity(m,id,bp,p,tube,ball,{paint=paint,metal=metal,dark=dark,edge=edge,wood=wood,rubber=rubber},tier)
    if bp.optic=="reflex" then
        -- Four rails surround a truly open aperture. The dot is a centered GUI
        -- reticle, so neither a solid glass disk nor a neon part hides a target.
        for side=-1,1,2 do p("ReflexSide",Vector3.new(.025,.23,.065),Vector3.new(side*.145,bp.sight,.10),dark) end
        for side=-1,1,2 do p("ReflexBridge",Vector3.new(.29,.025,.065),Vector3.new(0,bp.sight+side*.115,.10),dark) end
        p("ReflexMount",Vector3.new(.22,.045,.24),Vector3.new(0,bp.sight-.16,.10),metal)
    end
    -- The complete break-action front and belt feed follow their real hinges.
    for _,entry in ipairs(pose.parts) do
        local name=entry.part.Name
        if kind=="Double" and (name:find("FrontSight") or name=="SightFront" or name=="BarrelCollar" or name=="MuzzleRecess" or name=="Muzzle" or name=="UpgradeHeatFin") then entry.group="front" end
        if kind=="Belt" and (name=="FeedRound" or name=="BeltLink") then entry.group="feed" end
        if kind=="AutoShot" and entry.group=="pump" then entry.group="body" end
        if entry.transparency==nil then entry.transparency=entry.part.Transparency end
        if entry.optic==nil then entry.optic=name:find("Scope")~=nil end
    end
    -- Runtime-only authoring references: no new script/native asset records.
    U.make("Attachment",root,{Name="SightAxis",CFrame=CFrame.new(0,bp.sight,.37)})
    U.make("Attachment",root,{Name="EjectionAxis",CFrame=CFrame.new(bp.bodyWidth/2+.055,m.Muzzle.Position.Y+.06,-.18)})
    -- Continuous bevels and fixed receiver webs replace the open chamfer shells.
    for _,entry in ipairs(pose.parts) do local q=entry.part
        if q:IsA("MeshPart") then q.DoubleSided=true
        elseif q.Material==Enum.Material.Metal then q.MaterialVariant="DS_Steel"
        elseif q.Material==Enum.Material.Wood then q.Material=Enum.Material.WoodPlanks q.MaterialVariant="DS_Wood"
        elseif q.Material==Enum.Material.Rubber then q.MaterialVariant="DS_Rubber" end
    end
    m:SetAttribute("WeaponArtRevision",10)
    return m
end
function W.groups(model)
    local out={} for _,entry in ipairs((poses[model] or {}).parts or {}) do out[entry.part.Name]=entry.group end return out
end
function W.aim(model,enabled,alpha)
    local data=poses[model] if not data then return end
    local fade=math.clamp(((alpha or (enabled and 1 or 0))-.35)/.45,0,1)
    if data.aimEnabled==enabled and data.opticFade==fade then return end
    data.aimEnabled=enabled data.opticFade=fade
    for _,entry in ipairs(data.parts) do
        -- The full model leaves the circular scope view clear at full ADS.
        -- Fade its solid optic housing before the hip crosshair disappears.
        entry.part.LocalTransparencyModifier=enabled and 1 or (entry.optic and fade or 0)
    end
end
local function smooth(a,b,t)
    local x=math.clamp((t-a)/(b-a),0,1) return x*x*(3-2*x)
end
local function pulse(a,b,c,t) return smooth(a,b,t)*(1-smooth(b,c,t)) end
function W.reloadFrame(id,progress,missing)
    local bp=Blueprints[id] local style=bp.reloadStyle local t=math.clamp(progress,0,1)
    local out=smooth(.10,.30,t)*(1-smooth(.58,.78,t))
    local frame={mag=CFrame.new(0,-out*.70,out*.12)*CFrame.Angles(0,0,out*.15),
        left=Vector3.new(out*.22,-out*.44,out*.58),right=Vector3.zero,
        action=pulse(.76,.87,.99,t),open=0,shell=false,shellOffset=Vector3.zero}
    if style=="bullpup" then frame.left=Vector3.new(out*.22,-out*.42,out*1.13)
    elseif style=="top" then
        frame.mag=CFrame.new(0,out*.43,out*.32) frame.left=Vector3.new(-out*.1,out*.45,out*.48)
    elseif style=="drum" then frame.mag=CFrame.new(0,-out*.76,out*.12)*CFrame.Angles(out*.14,0,0)
    elseif style=="cell" then
        frame.mag=CFrame.new(0,-out*.28,out*.65)*CFrame.Angles(0,0,out*.12)
        frame.left=Vector3.new(out*.15,-out*.25,out*.68) frame.action=pulse(.78,.89,1,t)
    elseif style=="belt" then
        frame.open=smooth(.05,.20,t)*(1-smooth(.78,.94,t))
        frame.left=Vector3.new(out*.22,frame.open*.23-out*.25,out*.45)
    elseif style=="cylinder" then
        frame.open=smooth(.05,.22,t)*(1-smooth(.78,.95,t))
        frame.left=Vector3.new(-frame.open*.22,-out*.18,out*.38) frame.action=0
        frame.shell=t>.40 and t<.72 frame.shellOffset=Vector3.new(-frame.open*.32,0,(1-smooth(.42,.70,t))*.30)
    elseif style=="break" then
        frame.open=smooth(.04,.24,t)*(1-smooth(.78,.97,t))
        frame.left=Vector3.new(out*.2,-out*.26,out*.62) frame.action=0
        frame.shell=t>.36 and t<.70 frame.shellOffset=Vector3.new(0,0,(1-smooth(.38,.68,t))*.32)
    elseif style=="tube" then
        local rounds=tubeRounds(id,missing)
        local raw=math.clamp((t-.12)/.68,0,.9999)*rounds local q=raw%1
        local feed=pulse(0,.52,1,q)
        frame.left=Vector3.new(feed*.12,-feed*.24,feed*.84)
        frame.shell=t>.12 and t<.80 and q<.78
        frame.shellOffset=Vector3.new(-.16*(1-feed),-.18*(1-feed),.14*(1-feed))
        frame.action=pulse(.82,.91,1,t)
    end
    return frame
end
-- Normalized presentation facts; Controller owns the approved audio adapter.
function W.reloadEvents(id,from,to,missing)
    local style=Blueprints[id].reloadStyle local stages
    if style=="tube" then
        stages={{.84,"action-open"},{.97,"action-close"}}
        local rounds=tubeRounds(id,missing)
        for n=1,rounds do
            stages[#stages+1]={.12+.68*(n-.25)/rounds,"shell-in"}
        end
    elseif style=="cylinder" or style=="break" then stages={{.08,"action-open"},{.26,"eject"},{.58,"shell-in"},{.93,"action-close"}}
    elseif style=="belt" then stages={{.08,"feed-open"},{.30,"mag-out"},{.65,"mag-in"},{.91,"feed-close"},{.96,"action-close"}}
    elseif style=="cell" then stages={{.22,"cell-out"},{.68,"cell-in"},{.9,"charge"}}
    else stages={{.22,"mag-out"},{.69,"mag-in"},{.83,"action-open"},{.97,"action-close"}} end
    local result={}
    for _,stage in ipairs(stages) do if stage[1]>from and stage[1]<=to then result[#result+1]={at=stage[1],phase=stage[2]} end end
    table.sort(result,function(a,b) return a.at<b.at end) return result
end
local function record(data,phase,acknowledged)
    data.events=data.events or {}
    if #data.events>=16 then table.remove(data.events,1) end
    data.events[#data.events+1]={weaponId=data.id,phase=phase,token=data.token or 0,acknowledged=acknowledged==true}
end
function W.bindEffects(model,parent)
    local data=poses[model] if not data or not data.arms then return end
    data.id=model:GetAttribute("WeaponId")
    if data.cosmetics then return end
    data.cosmetics={folder=U.make("Folder",parent,{Name="WeaponCosmetics"}),pool={},queue={},cursor=0}
    cosmeticSources[data.cosmetics]=true
end
function W.beginReload(model,missing,acknowledged,startProgress)
    local data=poses[model] if not data then return end
    data.clean=false data.token=(data.token or 0)+1 data.reloadActive=true data.reloadMissing=missing or 3
    data.reloadAcknowledged=acknowledged==true data.lastReload=startProgress or 0 data.firedAt=nil
    if data.cosmetics then data.cosmetics.queue={} end
end
function W.clearEffects(model,destroy)
    local data=poses[model] if not data then return end
    if data.clean and not destroy then return end data.clean=true
    data.token=(data.token or 0)+1 data.firedAt=nil data.shots=0 data.reloadActive=false data.lastReload=0 data.events={}
    local muzzle=model:FindFirstChild("Muzzle")
    if muzzle then
        local light=muzzle:FindFirstChild("Flash") if light then light.Brightness=0 end
        for _,name in ipairs({"WeaponFlash","WeaponSmoke"}) do local e=muzzle:FindFirstChild(name) if e then e:Clear() end end
    end
    local fx=data.cosmetics if not fx then return end
    if destroy then cosmeticSources[fx]=nil fx.folder:Destroy() data.cosmetics=nil return end
    fx.queue={}
    for _,v in ipairs(fx.pool) do v.at=nil v.part.Transparency=1 v.rim.Transparency=1 end
end
local function muzzleEmitter(muzzle,name,smoke,energy)
    local emitter=muzzle:FindFirstChild(name) if emitter then return emitter end
    return U.make("ParticleEmitter",muzzle,{Name=name,Rate=0,
        Texture=smoke and "rbxasset://textures/particles/smoke_main.dds" or "rbxasset://textures/particles/fire_main.dds",
        Lifetime=NumberRange.new(smoke and .10 or .025,smoke and .20 or .055),Speed=NumberRange.new(smoke and .7 or 0,smoke and 1.5 or .4),
        EmissionDirection=Enum.NormalId.Front,SpreadAngle=Vector2.new(8,8),LightEmission=smoke and 0 or .85,LightInfluence=smoke and 1 or 0,
        Color=ColorSequence.new(smoke and Color3.fromRGB(135,133,125) or energy and Color3.fromRGB(110,222,230) or Color3.fromRGB(255,199,110)),
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,smoke and .05 or .07),NumberSequenceKeypoint.new(1,smoke and .22 or 0)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,smoke and .88 or .25),NumberSequenceKeypoint.new(1,1)})})
end
function W.shot(model,now,lowEffects,interval)
    local data=poses[model] if not data or not data.arms then return end
    data.clean=false data.id=model:GetAttribute("WeaponId") data.firedAt=now data.shots=((data.shots or 0)+1)%data.capacity
    data.cycleDuration=math.min(.12,(interval or .16)*.8)
    record(data,"fire",false)
    local muzzle=model:FindFirstChild("Muzzle") if not muzzle then return end
    local energy=data.bp.action=="energy"
    muzzleEmitter(muzzle,"WeaponFlash",false,energy):Emit(lowEffects and 1 or 2)
    if not lowEffects then muzzleEmitter(muzzle,"WeaponSmoke",true,energy):Emit(energy and 1 or 2) end
    local light=muzzle:FindFirstChild("Flash") if light then light.Brightness=lowEffects and .6 or 1.4 light.Range=5 light.Shadows=false end
    local fx=data.cosmetics
    if fx and data.bp.action~="energy" and data.bp.action~="revolver" and data.bp.action~="break" then
        if #fx.queue>=8 then table.remove(fx.queue,1) end
        local delay=data.bp.ejectDelay
        if data.bp.action=="carrier" or data.bp.action=="slide" then delay=math.min(delay,(interval or .16)*.35) end
        fx.queue[#fx.queue+1]={at=now+delay,count=1}
    end
end
-- A shared active budget also covers a transient overlap during VM replacement.
local function casingBudget(cap,reserve)
    local active={}
    for source in pairs(cosmeticSources) do for _,item in ipairs(source.pool) do
        if item.at then active[#active+1]=item end
    end end
    table.sort(active,function(a,b) return a.at<b.at end)
    for i=1,math.max(0,#active-cap+(reserve or 0)) do
        local item=active[i] item.at=nil item.part.Transparency=1 item.rim.Transparency=1
    end
end
local function eject(model,data,now,lowEffects,count)
    local fx=data.cosmetics if not fx then return end
    local cap=lowEffects and 2 or 8
    local origin=model.PrimaryPart.CFrame*model.Root.EjectionAxis.CFrame
    for n=1,math.min(count,cap) do
        fx.cursor=fx.cursor%cap+1 local item=fx.pool[fx.cursor]
        if not item then
            local function brass(name) return U.make("Part",fx.folder,{Name=name,Shape=Enum.PartType.Cylinder,Size=Vector3.new(.12,.05,.05),
                Material=Enum.Material.Metal,Color=Color3.fromRGB(166,135,72),Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false}) end
            item={part=brass("Casing"),rim=brass("CasingRim")};fx.pool[fx.cursor]=item
        end
        local shell=C.Weapons[data.id].class=="Shotgun"
        item.part.Size=shell and Vector3.new(.21,.075,.075) or Vector3.new(.12,.05,.05)
        item.part.Color=shell and Color3.fromRGB(142,53,38) or Color3.fromRGB(166,135,72)
        item.rim.Size=Vector3.new(.025,shell and .082 or .058,shell and .082 or .058)
        item.at=nil casingBudget(cap,1)
        item.at=now item.origin=origin*CFrame.new(0,(n-1)*.025,0)
        item.velocity=origin:VectorToWorldSpace(Vector3.new(2.6+n*.12,1.5+n*.10,.5))
        item.part.Transparency=0 item.rim.Transparency=0
    end
end
function W.updateEffects(model,now,lowEffects,progress)
    local data=poses[model] local fx=data and data.cosmetics if not fx then return end
    if data.reloadActive and progress and progress>0 then
        if progress<(data.lastReload or 0) then data.lastReload=progress end
        for _,event in ipairs(W.reloadEvents(data.id,data.lastReload or 0,progress,data.reloadMissing)) do
            record(data,event.phase,data.reloadAcknowledged)
            if event.phase=="eject" then eject(model,data,now,lowEffects,data.bp.reloadStyle=="cylinder" and data.capacity or 2) end
        end
        data.lastReload=progress
    elseif data.lastReload and data.lastReload>0 then data.reloadActive=false data.lastReload=0 end
    for i=#fx.queue,1,-1 do if now>=fx.queue[i].at then
        eject(model,data,fx.queue[i].at,lowEffects,fx.queue[i].count) table.remove(fx.queue,i)
    end end
    local cap=lowEffects and 2 or 8
    casingBudget(cap)
    for i,item in ipairs(fx.pool) do
        local age=item.at and now-item.at
        if not age or age>.48 or i>cap then item.at=nil item.part.Transparency=1 item.rim.Transparency=1
        else
            local position=item.origin.Position+item.velocity*age+Vector3.new(0,-9*age*age,0)
            item.part.CFrame=CFrame.new(position)*(item.origin-item.origin.Position)*CFrame.Angles(age*7,age*5,age*9)
            item.rim.CFrame=item.part.CFrame*CFrame.new(-item.part.Size.X/2,0,0)
        end
    end
    local muzzle=model:FindFirstChild("Muzzle") local light=muzzle and muzzle:FindFirstChild("Flash")
    if light and (not data.firedAt or now-data.firedAt>.045) then light.Brightness=0 end
    if lowEffects and fx.lowEffects~=lowEffects and muzzle then local smoke=muzzle:FindFirstChild("WeaponSmoke") if smoke then smoke:Clear() end end
    fx.lowEffects=lowEffects
end
function W.effectStats(model)
    local data=poses[model] local fx=data and data.cosmetics local active=0
    if fx then for _,v in ipairs(fx.pool) do if v.at then active+=1 end end end
    return {active=active,pool=fx and #fx.pool or 0,queued=fx and #fx.queue or 0,events=data and data.events and #data.events or 0}
end
function W.drainPresentationEvents(model)
    local data=poses[model] if not data then return {} end
    local events=data.events or {} data.events={} return events
end
function W.kickOffset(model,now)
    local data=poses[model] if not data or not data.firedAt then return 0 end
    return data.bp.kick*pulse(0,.025,.18,now-data.firedAt)
end
function W.pose(model,reload,melee,equip,recoil,empty,context)
    local data=poses[model] if not data or not model.PrimaryPart then return end
    local root=model.PrimaryPart.CFrame local bp=data.bp
    local frame=W.reloadFrame(model:GetAttribute("WeaponId"),reload,context and context.missing)
    local age=data.firedAt and context and context.now-data.firedAt
    local duration=data.cycleDuration or .12
    local cycle=age and pulse(0,duration*.25,duration,age) or math.clamp((recoil or 0)/1.7,0,1)
    local action=age and pulse(.08,.24,bp.action=="pump" and .40 or .55,age) or 0
    local cylinder=frame.open
    for _,entry in ipairs(data.parts) do local p=entry.part if p.Parent and p~=model.PrimaryPart then
        local cf=entry.cf local g=entry.group
        if g=="mag" then cf=frame.mag*cf
        elseif g=="cylinder" then
            local turn=(data.shots or 0)-(age and 1-smooth(0,.12,age) or 0)
            cf=CFrame.new(-cylinder*.32,0,0)*CFrame.Angles(0,0,cylinder*.2+turn*math.pi*2/data.capacity)*cf
        elseif g=="bolt" then cf=CFrame.new(0,0,frame.action*.20+(bp.action=="bolt" and action*.20 or cycle*.09))*cf
        elseif g=="slide" then cf=CFrame.new(0,0,empty and reload==0 and .14 or cycle*.14)*cf
        elseif g=="trigger" then cf=cf*CFrame.Angles(cycle*.18,0,0)
        elseif g=="hammer" then cf=CFrame.new(0,.16,.21)*CFrame.Angles(-cycle*.28,0,0)*CFrame.new(0,-.16,-.21)*cf
        elseif g=="feed" then cf=CFrame.new(0,.26,.41)*CFrame.Angles(-frame.open*.8,0,0)*CFrame.new(0,-.26,-.41)*cf
        elseif g=="front" then cf=CFrame.new(0,0,-.4)*CFrame.Angles(-frame.open*.55,0,0)*CFrame.new(0,0,.4)*cf
        elseif g=="pump" then cf=CFrame.new(0,0,(action+frame.action)*.32)*cf
        elseif g=="left" then cf=CFrame.new(frame.left+Vector3.new(0,0,bp.action=="pump" and action*.32 or 0))*cf
        elseif g=="right" and bp.action=="bolt" then cf=CFrame.new((frame.action+action)*.07,(frame.action+action)*.05,(frame.action+action)*.16)*cf
        elseif g=="knife" then p.Transparency=melee>0 and 0 or 1
        elseif g=="shell" or g=="loadshell" then p.Transparency=frame.shell and 0 or 1 cf=CFrame.new(frame.shellOffset)*cf end
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
