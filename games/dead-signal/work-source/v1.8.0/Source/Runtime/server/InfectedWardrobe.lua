local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local V={}
V.types={"Civilian","Mechanic","Medic","Security","Surveyor","Soldier"}
function V.apply(model,id,scale)
    local variant=(id-1)%#V.types+1 model:SetAttribute("OutfitVariant",variant) model:SetAttribute("OutfitName",V.types[variant])
    local torso=model.Torso local head=model.Head local origin=torso.CFrame
    local function p(name,size,at,color,mat,round,bone)
        bone=bone or torso
        local q=U.make("Part",model,{Name=name,Size=size*scale,CFrame=origin*CFrame.new(at*scale),Color=color,
            Material=mat or Enum.Material.Fabric,Anchored=false,CanCollide=false,CanQuery=true,CanTouch=false,Massless=true,CollisionGroup="DeadSignalEnemies"})
        if round then U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) end
        q:SetAttribute("HitZone",bone==head and "Head" or "Body") U.make("WeldConstraint",q,{Part0=bone,Part1=q}) return q
    end
    local dark=Color3.fromRGB(30,34,32) local canvas=Color3.fromRGB(104,101,78)
    if variant==1 then
        p("CivilianJacketLapels",Vector3.new(.25,.85,.10),Vector3.new(-.30,.28,-.53),Color3.fromRGB(68,57,45))
        p("CivilianJacketLapels",Vector3.new(.25,.85,.10),Vector3.new(.30,.28,-.53),Color3.fromRGB(68,57,45))
        p("TornUndershirt",Vector3.new(.33,.65,.035),Vector3.new(0,.22,-.60),Color3.fromRGB(135,131,108))
    elseif variant==2 then
        p("MechanicBib",Vector3.new(1.27,1.05,.07),Vector3.new(0,.04,-.59),Color3.fromRGB(53,66,67))
        for _,x in ipairs({-.53,.53}) do p("OverallStrap",Vector3.new(.17,.90,.1),Vector3.new(x,.55,-.50),canvas) end
        p("ToolPocket",Vector3.new(.48,.42,.18),Vector3.new(-.65,-.46,-.5),canvas)
    elseif variant==3 then
        for _,x in ipairs({-.67,.67}) do p("LabCoatTail",Vector3.new(.7,1.04,.14),Vector3.new(x,-.66,-.48),Color3.fromRGB(154,157,140)) end
        p("MedicalSatchel",Vector3.new(.65,.55,.32),Vector3.new(.77,-.61,-.4),Color3.fromRGB(96,98,70))
        p("MedicalPatchVertical",Vector3.new(.08,.29,.02),Vector3.new(-.54,.42,-.65),Color3.fromRGB(128,67,54))
        p("MedicalPatchHorizontal",Vector3.new(.28,.08,.02),Vector3.new(-.54,.42,-.66),Color3.fromRGB(128,67,54))
    elseif variant==4 or variant==6 then
        p("BallisticVest",Vector3.new(1.65,1.18,.19),Vector3.new(0,.11,-.56),dark,Enum.Material.Fabric,true)
        for j=-1,1 do p("MagazinePouch",Vector3.new(.35,.50,.19),Vector3.new(j*.43,-.05,-.74),canvas) end
        p("ShoulderRadio",Vector3.new(.23,.34,.18),Vector3.new(.69,.69,-.52),dark,Enum.Material.Metal)
        p("RadioAntenna",Vector3.new(.035,.39,.035),Vector3.new(.69,1.02,-.52),dark,Enum.Material.Metal)
    elseif variant==5 then
        p("WeatherHood",Vector3.new(1.39,.70,1.20),Vector3.new(0,1.83,.10),canvas,Enum.Material.Fabric,true,head)
        p("Respirator",Vector3.new(.69,.33,.19),Vector3.new(0,1.20,-.53),dark,Enum.Material.SmoothPlastic,true,head)
        p("RespiratorCanister",Vector3.new(.24,.27,.25),Vector3.new(-.33,1.19,-.63),canvas,Enum.Material.Metal,true,head)
    end
    -- Irregular injuries and wear follow the same head/torso bones.
    p("CheekInjury",Vector3.new(.12,.23,.035),Vector3.new(.35,1.30,-.48),Color3.fromRGB(105,78,65),Enum.Material.SmoothPlastic,true,head)
    p("BrowScar",Vector3.new(.055,.21,.025),Vector3.new(-.28,1.82,-.48),Color3.fromRGB(112,94,77),Enum.Material.SmoothPlastic,true,head)
end
return V
