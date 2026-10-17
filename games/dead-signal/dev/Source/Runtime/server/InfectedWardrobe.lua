-- Original uniform and injury details fitted to the retained articulated skeleton.
-- Cosmetic shells never extend authoritative hit/query volumes.
local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local V={types={"Infantry","Security","SpecialOps","Officer","Hazmat","Heavy"},maxParts=66}
V.themes={
    Station={name="Blackwater Signal Corps",cloth={71,82,62},trim={111,111,85},patch={152,158,130}},
    Foundry={name="Cinderworks Containment",cloth={71,72,65},trim={126,108,75},patch={180,150,82}},
    Frost={name="Whiteout Expedition",cloth={137,145,139},trim={86,102,109},patch={160,181,190}}}
function V.apply(model,id,scale,mapId,kind)
    if model:GetAttribute("MilitaryRevision") then return end
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
    for j=-1,1 do front("RetentionPouch",Vector3.new(.27,.43,.18),Vector3.new(j*.36,.40,-.74),trim) end
    front("Buckle",Vector3.new(.22,.15,.10),Vector3.new(0,-.04,-.62),dark,Enum.Material.Metal)
    front("NameTape",Vector3.new(.48,.08,.045),Vector3.new(-.24,1.04,-.73),U.color(theme.patch))
    front("UnitBars",Vector3.new(.23,.055,.04),Vector3.new(.40,1.02,-.73),U.color(theme.patch))
    front("Radio",Vector3.new(.22,.33,.17),Vector3.new(.60,1.27,-.49),dark,Enum.Material.Metal)
    front("Antenna",Vector3.new(.025,.40,.025),Vector3.new(.60,1.64,-.49),dark,Enum.Material.Metal)
    if archetype=="Infantry" or archetype=="Security" or archetype=="Heavy" then
        detail(head,"DamagedHelmet",Vector3.new(1.05,.50,.99),Vector3.new(0,.42,.02),archetype=="Security" and dark or trim,Enum.Material.Metal,true)
        detail(head,"HelmetRim",Vector3.new(1.08,.08,1.02),Vector3.new(0,.24,.01),dark,Enum.Material.Rubber,true)
        detail(head,"LooseChinStrap",Vector3.new(.10,.47,.08),Vector3.new(.43,-.02,-.29),trim,Enum.Material.Fabric,false,CFrame.Angles(0,0,-.20))
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
    local forearm=model:FindFirstChild(id%2==0 and "Left Forearm" or "Right Forearm")
    detail(forearm,"ExposedTendon",Vector3.new(.085,.53,.055),Vector3.new(.09,0,-.23),skin,Enum.Material.SmoothPlastic,true)
    model:SetAttribute("OutfitVariant",variant) model:SetAttribute("OutfitName",archetype)
    model:SetAttribute("MilitaryOrigin",theme.name) model:SetAttribute("InfectionStage",wear+1)
    model:SetAttribute("MilitaryRevision",1) model:SetAttribute("MilitaryDetailCount",n)
end
local equipment={DamagedHelmet="Head",HelmetRim="Head",LooseChinStrap="Head",RaisedVisor="Head",
    SplitLoadVest="Body",RetentionPouch="Body",NameTape="Body",UnitBars="Body",RankChevrons="Body",FrayedUniformTear="Body"}
function V.armor(model)
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and equipment[p.Name] then
        p.Transparency=1;p:SetAttribute("ArmorOverlayHidden",true)
    end end
end
function V.degrade(model,zone)
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and equipment[p.Name]==zone then p:Destroy() end end
end
return V
