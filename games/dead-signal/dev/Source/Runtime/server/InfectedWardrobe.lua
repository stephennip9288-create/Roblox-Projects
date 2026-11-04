-- Original uniform and injury details fitted to the retained articulated skeleton.
-- Cosmetic shells never extend authoritative hit/query volumes.
local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local V={types={"Infantry","Security","SpecialOps","Officer","Hazmat","Heavy"},maxParts=66}
V.themes={
    Station={name="Blackwater Signal Corps",cloth={71,82,62},trim={111,111,85},patch={152,158,130}},
    Foundry={name="Cinderworks Containment",cloth={71,72,65},trim={126,108,75},patch={180,150,82}},
    Frost={name="Whiteout Expedition",cloth={137,145,139},trim={86,102,109},patch={160,181,190}}}
-- Original R6 face/cloth art uses ordinary Roblox parts and vector SurfaceGui
-- marks. No imported character mesh, texture upload, stock smile or asset ID.
local function r6(model,id,scale,mapId,kind)
    local theme=V.themes[mapId] or V.themes.Station;local variant=(id-1)%6+1;local wear=math.floor((id-1)/6)%3
    local crawler=kind=="Crawler";local torso,head=model.Torso,model.Head
    local faceVariant=(id-1)%4
    local palettes={Station={{70,79,54},{42,55,65},{49,59,52},{75,76,55},{115,112,76},{55,65,53}},
        Foundry={{128,83,43},{46,59,63},{139,124,62},{101,91,65},{130,131,104},{68,60,48}},
        Frost={{107,125,126},{66,84,101},{121,133,128},{85,100,107},{158,162,145},{89,103,100}}}
    local cloth=U.color((palettes[mapId] or palettes.Station)[variant]);local trim=U.color(theme.trim)
    local skin=mapId=="Frost" and Color3.fromRGB(139+wear*5,158,157-wear*5)
        or Color3.fromRGB(139+wear*4,150-wear*3,113+wear*2)
    local dark=Color3.fromRGB(35,40,34);local stain=mapId=="Foundry" and Color3.fromRGB(46,43,36) or Color3.fromRGB(72,80,57)
    for _,p in ipairs({torso,model["Left Arm"],model["Right Arm"],model["Left Leg"],model["Right Leg"]}) do
        p.Color=cloth;p.Material=Enum.Material.Fabric;p.MaterialVariant="";p.Reflectance=0
    end
    head.Color=skin;head.Material=Enum.Material.Sandstone;head.MaterialVariant="";head.Reflectance=0
    local n=0
    local function detail(b,name,size,at,color,material,rotation,round)
        n+=1
        local p=U.make("Part",model,{Name=name,Size=size*scale,CFrame=b.CFrame*CFrame.new(at*scale)*(rotation or CFrame.identity),
            Color=color,Material=material or Enum.Material.Fabric,Reflectance=0,Shape=round and Enum.PartType.Ball or Enum.PartType.Block,
            CanCollide=false,CanQuery=false,CanTouch=false,Anchored=false,Massless=true,CollisionGroup="DeadSignalEnemies"})
        p:SetAttribute("MilitaryDetail",true);U.make("WeldConstraint",p,{Part0=b,Part1=p});return p
    end
    local function front(name,size,at,color,material,rotation)
        if crawler then at=Vector3.new(at.X,.45,-at.Y*.7);rotation=CFrame.Angles(-math.pi/2,0,0)*(rotation or CFrame.identity) end
        return detail(torso,name,size,at,color,material,rotation)
    end
    local function canvas(b,name)
        return U.make("SurfaceGui",b,{Name=name,Face=Enum.NormalId.Front,CanvasSize=Vector2.new(192,192),
            SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,AlwaysOnTop=false,LightInfluence=1,MaxDistance=70,ZOffset=.005})
    end
    local function mark(gui,name,x,y,w,h,color,rotation,alpha)
        local p=U.make("Frame",gui,{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundColor3=color,BackgroundTransparency=alpha or 0,BorderSizePixel=0,Rotation=rotation or 0})
        if gui.Name=="InfectedFace" and not name:find("Tooth") and not name:find("Fissure") or name:find("Grime") then
            U.make("UICorner",p,{CornerRadius=UDim.new(.38,0)})
        end
        return p
    end
    local face=canvas(head,"InfectedFace")
    -- Off-centre recessed sockets, cloudy mismatched eyes, damaged brow/jaw and
    -- a broken irregular tooth line make the face visibly infected at close range.
    mark(face,"LeftSocket",28,60,53,27,dark,-8-wear*2-faceVariant);mark(face,"RightSocket",111,55+wear*3+faceVariant*2,48,25,stain,8)
    mark(face,"LeftIris",43,67,22,10,Color3.fromRGB(187,183,132),-7)
    mark(face,"RightIris",124,63+wear*3+faceVariant*2,18,8,mapId=="Frost" and Color3.fromRGB(166,191,191) or Color3.fromRGB(159,164,126),9)
    mark(face,"LeftPupil",52,68,4,8,dark,-7);mark(face,"RightPupil",131,64+wear*3+faceVariant*2,3,6,dark,9)
    mark(face,"Brow",27,52,58,9,stain,-11);mark(face,"BrokenBrow",114,49,40,7,stain,13)
    mark(face,"NoseShade",87,84,17,33,stain,-7,.25);mark(face,"Nostril",88,109,23,5,dark,5)
    mark(face,"CheekHollow",22,101,27,17,stain,-20,.20);mark(face,"SunkenCheek",139,96,24,25,stain,14,.18)
    mark(face,"DamagedMouth",58,136,83,19,dark,3+wear*3+faceVariant*2);mark(face,"JawShadow",64,156,66,7,stain,5,.15)
    for tooth=1,5 do if tooth~=2+wear then
        mark(face,"BrokenTooth"..tooth,61+tooth*12,136+tooth%2*2,7,5+tooth%3,Color3.fromRGB(181,174,133),tooth%2==0 and -9 or 8)
    end end
    for k=1,5 do
        mark(face,"Mottle"..k,15+(id*17+k*31)%155,18+(k*23+id*7)%110,8+k*2,5+k,stain,k*13,.38)
    end
    for k=1,3+wear do mark(face,"DryFissure"..k,145-k*5,108+k*10,3,14,Color3.fromRGB(80,75,57),-15+k*9) end
    local print=canvas(torso,"WornUniformPrint")
    if crawler then print.Face=Enum.NormalId.Top end
    mark(print,"Placket",96,8,6,170,dark,0,.15);mark(print,"ChestSeam",10,48,166,4,trim,-3,.1)
    for _,x in ipairs({25,123}) do
        mark(print,"Pocket"..x,x,56,41,37,trim,0,.18);mark(print,"PocketFlap"..x,x-2,56,45,6,dark,-3,.1)
    end
    for k=1,5 do mark(print,"Grime"..k,13+(id*13+k*29)%140,40+k*22,18+k*4,9+k*2,stain,k*11,.18) end
    mark(print,"TornPanel",id%2==0 and 34 or 134,116,24,49,dark,12)
    mark(print,"InfectedSkinThroughTear",id%2==0 and 40 or 139,123,10,34,skin,9)
    for _,side in ipairs({-1,1}) do
        local name=side==1 and "Right" or "Left";local arm=model[name.." Arm"];local leg=model[name.." Leg"]
        detail(arm,"ExposedR6Hand",crawler and Vector3.new(.76,.4,.7) or Vector3.new(1.01,.46,1.01),
            crawler and Vector3.new(0,-.24,-.8) or Vector3.new(0,-.76,0),skin,Enum.Material.Sandstone)
        detail(arm,"FrayedCuff",crawler and Vector3.new(.78,.08,.8) or Vector3.new(1.02,.11,1.02),
            crawler and Vector3.new(0,-.10,-.52) or Vector3.new(0,-.51,0),stain,Enum.Material.Fabric,CFrame.Angles(0,0,side*.055))
        detail(leg,"WornBoot",crawler and Vector3.new(.82,.36,.7) or Vector3.new(1.03,.48,1.10),
            crawler and Vector3.new(0,-.24,.8) or Vector3.new(0,-.74,-.03),dark,Enum.Material.Leather)
        detail(leg,"BootSole",crawler and Vector3.new(.83,.08,.73) or Vector3.new(1.04,.10,1.12),
            crawler and Vector3.new(0,-.40,.8) or Vector3.new(0,-.98,-.04),Color3.fromRGB(25,29,25),Enum.Material.Rubber)
        detail(arm,"WornUnitTab",crawler and Vector3.new(.06,.35,.4) or Vector3.new(.04,.28,.42),
            crawler and Vector3.new(side*.40,.02,.38) or Vector3.new(side*.51,.52,-.12),trim)
        front("LooseWebbing",Vector3.new(.14,1.35,.08),Vector3.new(side*.64,.20,-.56),trim,nil,CFrame.Angles(0,0,side*.07))
    end
    front("SplitLoadVest",Vector3.new(1.42,.62,.13),Vector3.new(0,.19,-.58),cloth)
    front("RetentionPouch",Vector3.new(.35,.44,.20),Vector3.new(id%2==0 and .65 or -.65,-.58,-.60),trim,nil,CFrame.Angles(0,0,.14))
    front("BrokenStrapTail",Vector3.new(.12,.5,.06),Vector3.new(-.72,-.60,-.57),trim,nil,CFrame.Angles(0,0,-.22))
    front("FrayedUniformTear",Vector3.new(.20,.40,.025),Vector3.new(.32,-.38,-.515),stain)
    if mapId=="Foundry" then
        local apron=front("HeatApron",Vector3.new(1.05,1.36,.07),Vector3.new(-.10,-.39,-.61),Color3.fromRGB(65,55,43),Enum.Material.Leather)
        print.Adornee=apron;print.Face=Enum.NormalId.Front
        for _,x in ipairs({-.68,.68}) do front("WornReflector",Vector3.new(.18,1.20,.04),Vector3.new(x,.05,-.63),Color3.fromRGB(172,161,100)) end
        front("SootAbrasion",Vector3.new(.72,.16,.03),Vector3.new(-.23,.69,-.65),dark)
        detail(head,"DentedHardhat",Vector3.new(1.30,.33,1.17),Vector3.new(0,.52,0),variant%2==0 and trim or cloth,Enum.Material.Fabric,CFrame.Angles(.04,0,.08),true)
        detail(head,"HardhatRim",Vector3.new(1.33,.08,1.20),Vector3.new(0,.36,-.02),stain,Enum.Material.Rubber)
    elseif mapId=="Frost" then
        front("ParkaStormFlap",Vector3.new(.20,1.72,.10),Vector3.new(.08,0,-.62),trim)
        for _,side in ipairs({-1,1}) do
            detail(torso,"WornWinterCollar",Vector3.new(.55,.25,.78),Vector3.new(side*.70,crawler and .43 or .96,crawler and -.58 or .02),trim,Enum.Material.Fabric,CFrame.Angles(0,0,-side*.13))
        end
        detail(head,"FrostedKnitCap",Vector3.new(1.21,.38,1.12),Vector3.new(0,.45,.04),trim,Enum.Material.Fabric,CFrame.Angles(0,0,-.07),true)
        detail(head,"FrozenCapEdge",Vector3.new(1.23,.10,1.15),Vector3.new(0,.29,.04),Color3.fromRGB(168,183,177),Enum.Material.Snow)
    else
        if variant==1 or variant==3 then
            detail(head,"BrokenFieldHeadset",Vector3.new(.16,.35,.34),Vector3.new(-.63,.03,.03),dark,Enum.Material.Rubber)
            detail(head,"BentMicrophone",Vector3.new(.04,.04,.40),Vector3.new(-.52,-.20,-.31),dark,Enum.Material.Rubber,CFrame.Angles(.18,.3,0))
        else
            detail(head,"DamagedHelmet",Vector3.new(1.24,.38,1.14),Vector3.new(0,.48,.02),trim,Enum.Material.Fabric,CFrame.Angles(.04,0,.08),true)
            detail(head,"HelmetRim",Vector3.new(1.28,.08,1.17),Vector3.new(0,.29,.02),dark,Enum.Material.Rubber)
        end
        front("CommsRadio",Vector3.new(.28,.44,.19),Vector3.new(.62,.47,-.62),dark,Enum.Material.Rubber)
        front("SignalCable",Vector3.new(.06,.58,.06),Vector3.new(.73,.24,-.59),dark,Enum.Material.Rubber)
    end
    if variant==3 then
        detail(model["Right Arm"],"TornShoulderPad",Vector3.new(1.04,.26,.94),Vector3.new(0,crawler and .27 or .89,0),stain)
    elseif variant==4 then
        front("OfficerBars",Vector3.new(.30,.07,.04),Vector3.new(-.34,.64,-.68),U.color(theme.patch))
        detail(head,"WornCapBrim",Vector3.new(1.30,.07,.50),Vector3.new(0,.26,-.46),trim,Enum.Material.Fabric,CFrame.Angles(-.08,0,-.04))
    elseif variant==5 then
        front("ContainmentMark",Vector3.new(.50,.20,.04),Vector3.new(-.34,.52,-.69),U.color(theme.patch))
        detail(head,"LoweredRespirator",Vector3.new(.60,.20,.30),Vector3.new(0,-.60,-.36),dark,Enum.Material.Rubber)
    elseif variant==6 then
        front("PaddedCarrier",Vector3.new(1.44,.36,.22),Vector3.new(0,.18,-.69),dark)
        detail(torso,"WornBackpack",Vector3.new(1.24,1.32,.40),Vector3.new(0,crawler and .35 or -.08,crawler and .75 or .71),trim)
    end
    if kind=="Warden" then
        for _,side in ipairs({-1,1}) do
            detail(torso,"WardenShoulderMantle",Vector3.new(.52,.38,.98),Vector3.new(side*1.03,.96,.02),dark,Enum.Material.Fabric,CFrame.Angles(0,0,-side*.10))
        end
        front("WardenBreachCarrier",Vector3.new(1.55,.74,.18),Vector3.new(0,.03,-.68),stain)
    end
    model:SetAttribute("OutfitVariant",variant);model:SetAttribute("OutfitName",V.types[variant]);model:SetAttribute("InfectionStage",wear+1)
    model:SetAttribute("MilitaryOrigin",theme.name);model:SetAttribute("MilitaryRevision",2);model:SetAttribute("MilitaryDetailCount",n)
    model:SetAttribute("R6FaceVariant",(id-1)%4+1);model:SetAttribute("VisualAcceptance","StudioGameplayPending")
    local roles={Station={"SignalOperator","StationGuard","ResponseTeam","WatchOfficer","ContainmentMedic","BreachTrooper"},
        Foundry={"MaintenanceCrew","PlantSecurity","FireResponder","ShiftForeman","DeconResponder","FurnaceCrew"},
        Frost={"RelayPatrol","WinterSecurity","SurveyCrew","RelayOfficer","PolarResearcher","HeavyExpedition"}}
    model:SetAttribute("InfectedRole",(roles[mapId] or roles.Station)[variant])
end
function V.apply(model,id,scale,mapId,kind)
    if model:GetAttribute("MilitaryRevision") then return end
    if model:GetAttribute("PresentationRig")=="R6" then return r6(model,id,scale,mapId,kind) end
    local theme=V.themes[mapId] or V.themes.Station local variant=(id-1)%#V.types+1
    local archetype=V.types[variant] local wear=math.floor((id-1)/6)%3
    local torso=model.Torso local head=model.Head local crawler=kind=="Crawler"
    local cloth=U.color(theme.cloth) local trim=U.color(theme.trim) local dark=Color3.fromRGB(32,39,37)
    local skin=Color3.fromRGB(151+wear*7,158+wear*4,130+wear*3) local n=0
    local function detail(b,name,size,at,color,material,round,rotation)
        if not b or n>=V.maxParts then return end n+=1
        local p=U.make("Part",model,{Name=name,Size=size*scale,CFrame=b.CFrame*CFrame.new(at*scale)*(rotation or CFrame.identity),
            Color=color or cloth,Material=material or Enum.Material.Fabric,Shape=round and Enum.PartType.Ball or Enum.PartType.Block,
            Anchored=false,Massless=true,CanCollide=false,CanQuery=false,CanTouch=false,CollisionGroup="DeadSignalEnemies"})
        p.MaterialVariant=p.Material==Enum.Material.Fabric and "DS_Canvas" or p.Material==Enum.Material.Leather and "DS_Leather" or ""
        if color==skin then p.MaterialVariant="DS_InfectedSkin" end
        p:SetAttribute("MilitaryDetail",true);U.make("WeldConstraint",p,{Part0=b,Part1=p});return p
    end
    -- Retain imported texture/SurfaceAppearance data and recolor only generated cloth.
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and not p:GetAttribute("AuthoritativeHitbox") and p.Name~="BodyCollider" then
        if p.Material==Enum.Material.Fabric then p.Color=cloth
        elseif p.MaterialVariant=="DS_InfectedSkin" then p.Color=skin end
    end end
    local function front(name,size,at,color,material,round,rotation)
        if crawler then at=Vector3.new(at.X,.49+at.Z*-.10,-.35-at.Y*.65);rotation=CFrame.Angles(-math.pi/2,0,0)*(rotation or CFrame.identity) end
        return detail(torso,name,size,at,color,material,round,rotation)
    end
    for _,side in ipairs({-1,1}) do
        front("LoadBearingStrap",Vector3.new(.16,1.5,.10),Vector3.new(side*.55,.65,-.58),trim)
        front("VestSideBinding",Vector3.new(.12,.90,.19),Vector3.new(side*.69,.55,-.45),dark)
        detail(head,"SunkenTemple",Vector3.new(.13,.24,.09),Vector3.new(side*.34,.10,-.40),skin,Enum.Material.SmoothPlastic,true)
        detail(head,"JawTendon",Vector3.new(.11,.38,.12),Vector3.new(side*.30,-.23,-.33),skin,Enum.Material.SmoothPlastic,true,CFrame.Angles(0,0,side*.17))
        local arm=model:FindFirstChild(side==1 and "Right Arm" or "Left Arm")
        detail(arm,"UnitShoulderTab",Vector3.new(.43,.31,.10),Vector3.new(0,.20,-.27),trim)
        detail(arm,"TornSleeveEdge",Vector3.new(.46,.10,.53),Vector3.new(0,-.37,0),dark,Enum.Material.Fabric,true)
    end
    front("SplitLoadVest",Vector3.new(1.12,1.04,.17),Vector3.new(0,.62,-.60),archetype=="SpecialOps" and dark or cloth,nil,true)
    for j=-1,1 do
        if j~=(wear==0 and 2 or id%2==0 and -1 or 1) then
            front("RetentionPouch",Vector3.new(.27,.43,.18),Vector3.new(j*.36,.40,-.74),trim,nil,false,CFrame.Angles(0,0,j*.08*wear))
        end
    end
    front("Buckle",Vector3.new(.22,.15,.10),Vector3.new(0,-.04,-.62),dark,Enum.Material.Metal)
    front("NameTape",Vector3.new(.48,.08,.045),Vector3.new(-.24,1.04,-.73),U.color(theme.patch))
    front("UnitBars",Vector3.new(.23,.055,.04),Vector3.new(.40,1.02,-.73),U.color(theme.patch))
    front("Radio",Vector3.new(.22,.33,.17),Vector3.new(.60,1.27,-.49),dark,Enum.Material.Metal)
    front("Antenna",Vector3.new(.025,.40,.025),Vector3.new(.60,1.64,-.49),dark,Enum.Material.Metal)
    if archetype=="Infantry" or archetype=="Security" or archetype=="Heavy" then
        if archetype~="Infantry" then
            detail(head,"DamagedHelmet",Vector3.new(1.05,.50,.99),Vector3.new(0,.42,.02),archetype=="Security" and dark or trim,Enum.Material.Metal,true,CFrame.Angles(.08,0,id%2==0 and -.12 or .10))
            detail(head,"HelmetRim",Vector3.new(1.08,.08,1.02),Vector3.new(0,.24,.01),dark,Enum.Material.Rubber,true)
            detail(head,"LooseChinStrap",Vector3.new(.10,.47,.08),Vector3.new(.43,-.02,-.29),trim,Enum.Material.Fabric,false,CFrame.Angles(0,0,-.20))
        else
            -- Expose the retained textured face on communications personnel;
            -- avoid covering every infected silhouette with clean soldier gear.
            detail(head,"BrokenFieldHeadset",Vector3.new(.14,.29,.28),Vector3.new(-.44,.10,.02),dark,Enum.Material.Rubber,true)
        end
        if archetype=="Security" then
            detail(head,"RaisedVisor",Vector3.new(.79,.30,.08),Vector3.new(0,.40,-.53),Color3.fromRGB(86,103,106),Enum.Material.Glass,true,CFrame.Angles(-.35,0,0))
            front("SecurityWebbing",Vector3.new(.82,.12,.08),Vector3.new(0,.78,-.74),U.color(theme.patch))
        elseif archetype=="Heavy" then
            for _,side in ipairs({-1,1}) do
                front("HeavyFabricGuard",Vector3.new(.52,.37,.74),Vector3.new(side*.77,1.45,.03),trim,nil,true)
                front("HeavyWebLoop",Vector3.new(.40,.08,.10),Vector3.new(side*.42,.77,-.80),dark)
            end
            detail(torso,"HeavyBreachPack",Vector3.new(.99,1.22,.39),Vector3.new(0,crawler and .2 or .60,crawler and 1.15 or .65),trim,nil,true)
        end
    elseif archetype=="SpecialOps" then
        detail(head,"BalaclavaCrown",Vector3.new(.96,.46,.93),Vector3.new(0,.40,.02),dark,nil,true)
        detail(head,"CommsEarCup",Vector3.new(.17,.35,.35),Vector3.new(-.49,.11,.03),dark,Enum.Material.SmoothPlastic,true)
        detail(head,"RaisedGoggleFrame",Vector3.new(.76,.18,.14),Vector3.new(0,.39,-.48),trim,Enum.Material.Rubber,true)
        for _,x in ipairs({-.19,.19}) do detail(head,"GoggleLens",Vector3.new(.27,.12,.06),Vector3.new(x,.39,-.57),Color3.fromRGB(76,87,82),Enum.Material.Glass,true) end
    elseif archetype=="Officer" then
        detail(head,"FieldCap",Vector3.new(.97,.26,.93),Vector3.new(0,.42,.01),cloth,nil,true)
        detail(head,"CapPeak",Vector3.new(.70,.07,.41),Vector3.new(0,.32,-.50),dark,Enum.Material.Leather,true)
        for n=1,3 do front("RankChevrons",Vector3.new(.20,.045,.04),Vector3.new(.37,.95+n*.075,-.75),U.color(theme.patch)) end
        front("DispatchCase",Vector3.new(.57,.65,.21),Vector3.new(-.74,-.30,-.16),trim,Enum.Material.Leather)
    else
        detail(head,"SplitHazmatHood",Vector3.new(1.16,1.16,.91),Vector3.new(0,.15,.18),trim,nil,true)
        detail(head,"RespiratorMuzzle",Vector3.new(.60,.30,.22),Vector3.new(0,-.20,-.48),dark,Enum.Material.Rubber,true)
        for _,side in ipairs({-1,1}) do
            detail(head,"FilterCanister",Vector3.new(.23,.27,.26),Vector3.new(side*.34,-.19,-.50),trim,Enum.Material.Metal,true)
            front("HazardBand",Vector3.new(.15,.74,.07),Vector3.new(side*.47,.75,-.73),U.color(theme.patch))
        end
        detail(torso,"ContainmentAirPack",Vector3.new(.70,1.16,.40),Vector3.new(0,crawler and .2 or .70,crawler and 1.15 or .65),dark,Enum.Material.Metal,true)
    end
    if mapId=="Frost" then
        front("ParkaStormFlap",Vector3.new(.19,1.60,.10),Vector3.new(.08,.65,-.82),trim)
        detail(head,"InsulatedCollar",Vector3.new(1.02,.25,.94),Vector3.new(0,-.43,.07),trim,nil,true)
        for _,side in ipairs({-1,1}) do front("SnowEncrustation",Vector3.new(.45,.10,.31),Vector3.new(side*.58,1.49,.05),Color3.fromRGB(190,204,203),Enum.Material.Snow,true) end
    elseif mapId=="Foundry" then
        front("HeatApron",Vector3.new(.77,.79,.08),Vector3.new(0,-.16,-.64),Color3.fromRGB(70,59,45),Enum.Material.Leather)
        front("SootAbrasion",Vector3.new(.52,.16,.04),Vector3.new(-.28,1.10,-.76),Color3.fromRGB(31,33,30))
    else
        front("SignalCable",Vector3.new(.065,.67,.065),Vector3.new(-.62,.83,-.61),dark,Enum.Material.Rubber)
        front("CommsBattery",Vector3.new(.27,.36,.17),Vector3.new(.68,-.15,-.34),trim,Enum.Material.Metal)
    end
    -- Asymmetry and dry, non-graphic infection marks remain visible on every family.
    for index=1,3+wear do
        detail(head,"InfectionFissure",Vector3.new(.035,.12+index*.018,.025),Vector3.new(-.26+index*.09,-.28+index*.06,-.46),Color3.fromRGB(82,92,69),Enum.Material.SmoothPlastic,false,CFrame.Angles(0,0,index*.24))
    end
    front("FrayedUniformTear",Vector3.new(.22,.43,.035),Vector3.new(id%2==0 and .27 or -.27,.18,-.77),Color3.fromRGB(90,95,74),Enum.Material.Fabric,false,CFrame.Angles(0,0,.20))
    front("CollapsedVestFold",Vector3.new(.37,.52,.085),Vector3.new(.35,.68,-.76),dark,Enum.Material.Fabric,false,CFrame.Angles(.08,0,.22))
    front("BrokenStrapTail",Vector3.new(.11,.49,.08),Vector3.new(-.62,.06,-.59),trim,Enum.Material.Fabric,false,CFrame.Angles(0,0,-.28))
    local forearm=model:FindFirstChild(id%2==0 and "Left Forearm" or "Right Forearm")
    detail(forearm,"ExposedTendon",Vector3.new(.085,.53,.055),Vector3.new(.09,0,-.23),skin,Enum.Material.SmoothPlastic,true)
    model:SetAttribute("OutfitVariant",variant) model:SetAttribute("OutfitName",archetype)
    model:SetAttribute("MilitaryOrigin",theme.name) model:SetAttribute("InfectionStage",wear+1)
    model:SetAttribute("MilitaryRevision",2) model:SetAttribute("MilitaryDetailCount",n)
    model:SetAttribute("VisualAcceptance","StudioAndAuthoredArtPending")
end
local equipment={DamagedHelmet="Head",HelmetRim="Head",LooseChinStrap="Head",RaisedVisor="Head",
    DentedHardhat="Head",HardhatRim="Head",FrostedKnitCap="Head",FrozenCapEdge="Head",WornCapBrim="Head",
    HeatApron="Body",PaddedCarrier="Body",ParkaStormFlap="Body",WornReflector="Body",CommsRadio="Body",LooseWebbing="Body",
    SplitLoadVest="Body",RetentionPouch="Body",NameTape="Body",UnitBars="Body",RankChevrons="Body",FrayedUniformTear="Body"}
function V.armor(model)
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and equipment[p.Name] then
        p.Transparency=1;p:SetAttribute("ArmorOverlayHidden",true)
    end end
end
function V.degrade(model,zone)
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and equipment[p.Name]==zone then p:Destroy() end end
    if zone=="Body" and model:GetAttribute("PresentationRig")=="R6" then
        local print=model.Torso:FindFirstChild("WornUniformPrint")
        if print then print.Adornee=model.Torso;print.Face=model:GetAttribute("EnemyType")=="Crawler" and Enum.NormalId.Top or Enum.NormalId.Front end
    end
end
return V
