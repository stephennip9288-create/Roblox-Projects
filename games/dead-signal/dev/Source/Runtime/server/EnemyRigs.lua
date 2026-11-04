local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Pose=require(RS.DeadSignal.NPCPose)
local Wardrobe=require(script.Parent.InfectedWardrobe)
local Hound=require(script.Parent.HoundRig)
local R={}
-- Six visible R6 bodies, six driving motors. The eight rigid query proxies
-- retain the existing fourteen named server hit regions without deform meshes.
function R.base(parent,kind,position,id)
    local s=kind=="Warden" and 1.4 or 1 local crawl=kind=="Crawler"
    local model=U.make("Model",parent,{Name=kind})
    for key,value in pairs({EnemyType=kind,ArtRevision=8,ArticulatedRig=true,ForwardAxis="-Z",PoseSeed=id*.73,
        PresentationRig="R6",R6PresentationRevision=1,ImportedArt=false}) do model:SetAttribute(key,value) end
    local function part(name,size,at,visible,head)
        local p=U.make("Part",model,{Name=name,Size=size*s,CFrame=CFrame.new(position+at*s),
            Transparency=visible and 0 or 1,Anchored=false,Massless=name~="HumanoidRootPart",CanCollide=false,
            CanQuery=name~="HumanoidRootPart",CanTouch=false,CollisionGroup="DeadSignalEnemies",
            Color=Color3.fromRGB(112,126,101),Material=visible and Enum.Material.Fabric or Enum.Material.SmoothPlastic,
            Reflectance=0,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth,
            CustomPhysicalProperties=PhysicalProperties.new(.65,.4,0)})
        if name~="HumanoidRootPart" then
            p:SetAttribute("AuthoritativeHitbox",true);p:SetAttribute("HitZone",head and "Head" or "Body")
            p:SetAttribute("RagdollBody",visible);p:SetAttribute("R6Body",visible)
        end
        return p
    end
    local root=part("HumanoidRootPart",Vector3.new(2,crawl and 1 or 2,1),Vector3.zero,false);root.RootPriority=127
    local torso=part("Torso",crawl and Vector3.new(2,.85,2.2) or Vector3.new(2,2,1),Vector3.zero,true)
    local head=part("Head",Vector3.new(1.15,1.1,1.05),crawl and Vector3.new(0,.12,-1.65) or Vector3.new(0,1.55,0),true,true)
    U.make("CylinderMesh",head,{Scale=Vector3.new(1,1,1)})
    local function joint(name,a,b,at,angle)
        local cf=CFrame.new(position+at*s)
        local j=U.make("Motor6D",a,{Name=name,Part0=a,Part1=b,C0=a.CFrame:ToObjectSpace(cf),C1=b.CFrame:ToObjectSpace(cf)})
        j:SetAttribute("RestC0",j.C0);j:SetAttribute("RagdollAngle",angle or 50)
    end
    local function proxy(name,b,size,offset)
        local p=part(name,size,(b.Position-position)/s+offset,false)
        p:SetAttribute("R6HitProxy",true);U.make("WeldConstraint",p,{Part0=b,Part1=p})
    end
    joint("RootJoint",root,torso,Vector3.zero,10)
    joint("Neck",torso,head,crawl and Vector3.new(0,.10,-1.1) or Vector3.new(0,1,0),35)
    for _,side in ipairs({-1,1}) do
        local name=side==1 and "Right" or "Left"
        local arm=part(name.." Arm",crawl and Vector3.new(.76,.68,2.1) or Vector3.new(1,2,1),
            crawl and Vector3.new(side*1.32,-.23,-1.15) or Vector3.new(side*1.5,0,0),true)
        local leg=part(name.." Leg",crawl and Vector3.new(.8,.65,2) or Vector3.new(1,2,1),
            crawl and Vector3.new(side*.55,-.28,1.75) or Vector3.new(side*.5,-2,0),true)
        joint(name.." Shoulder",torso,arm,crawl and Vector3.new(side,0,-.65) or Vector3.new(side,.65,0),70)
        joint(name.." Hip",torso,leg,crawl and Vector3.new(side*.5,0,.7) or Vector3.new(side*.5,-1,0),50)
        proxy(name.." Forearm",arm,crawl and Vector3.new(.72,.50,.8) or Vector3.new(.94,.75,.94),crawl and Vector3.new(0,-.08,-.25) or Vector3.new(0,-.35,0))
        proxy(name.." Hand",arm,crawl and Vector3.new(.72,.45,.7) or Vector3.new(.94,.42,.94),crawl and Vector3.new(0,-.24,-.8) or Vector3.new(0,-.76,0))
        proxy(name.." Shin",leg,crawl and Vector3.new(.76,.5,.8) or Vector3.new(.94,.75,.94),crawl and Vector3.new(0,-.08,.25) or Vector3.new(0,-.35,0))
        proxy(name.." Foot",leg,crawl and Vector3.new(.76,.38,.7) or Vector3.new(.94,.30,1),crawl and Vector3.new(0,-.24,.8) or Vector3.new(0,-.82,-.03))
    end
    local collider=U.make("Part",model,{Name="BodyCollider",Size=(crawl and Vector3.new(2.05,1.35,3.10) or Vector3.new(2.05,5.35,1.25))*s,
        CFrame=CFrame.new(position+Vector3.new(0,crawl and .105 or -.255,crawl and -.12 or 0)*s),Shape=Enum.PartType.Ball,
        Transparency=1,CanCollide=true,CanQuery=false,CanTouch=false,Anchored=false,Massless=true,CollisionGroup="DeadSignalEnemies",
        CustomPhysicalProperties=PhysicalProperties.new(.65,.15,0)})
    collider:SetAttribute("AliveCollider",true);U.make("WeldConstraint",collider,{Part0=root,Part1=collider})
    local clearance=(crawl and .72 or 3.08)*s
    local hum=U.make("Humanoid",model,{RigType=Enum.HumanoidRigType.R6,MaxHealth=100,Health=100,WalkSpeed=10,
        HipHeight=clearance-root.Size.Y*.5-model["Left Leg"].Size.Y,BreakJointsOnDeath=false,RequiresNeck=false,
        DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None,AutoRotate=true})
    model.PrimaryPart=root;model:SetAttribute("ColliderRootBound",true)
    model:SetAttribute("NavigationRootHeight",clearance);model:SetAttribute("NavigationRadius",(crawl and 1.70 or 1.18)*s)
    model:SetAttribute("NavigationHeight",(crawl and 2.35 or 5.95)*s)
    pcall(function() root:SetNetworkOwner(nil) end)
    return model,root,hum
end
function R.build(parent,kind,position,id,mapId)
    local model,root,hum
    if kind=="Hound" then model,root,hum=Hound.build(parent,position,id,mapId)
    else
        model,root,hum=R.base(parent,kind,position,id)
        Wardrobe.apply(model,id,kind=="Warden" and 1.4 or 1,mapId,kind)
    end
    -- Visual torso lean must not tip/lift the live physical collider. Retain
    -- its exact rest size/position and collision group, bound to the root.
    local collider=model:FindFirstChild("BodyCollider")
    local weld=collider and collider:FindFirstChildOfClass("WeldConstraint")
    if weld then weld.Part0=root;model:SetAttribute("ColliderRootBound",true) end
    return model,root,hum
end
-- Original welded details follow the shared articulated skeleton and its ragdoll.
function R.evolve(e)
    local model=e.model local mods=e.mods or {} local torso=model.Torso local head=model.Head local crawler=e.kind=="Crawler"
    local metal=Color3.fromRGB(51,58,59) local bone=Color3.fromRGB(176,170,138)
    local hot=Color3.fromRGB(255,144,67) local s=mods.Alpha and 1.16 or mods.Armored and mods.Enraged and 1.08 or 1
    if s~=1 then
        local origin=e.root.CFrame
        for _,p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then local cf=origin:ToObjectSpace(p.CFrame);p.Size*=s;p.CFrame=origin*CFrame.new(cf.Position*s)*(cf-cf.Position);p.Position=p.CFrame.Position
            elseif p:IsA("Motor6D") then
                p.C0=CFrame.new(p.C0.Position*s)*(p.C0-p.C0.Position);p.C1=CFrame.new(p.C1.Position*s)*(p.C1-p.C1.Position);p:SetAttribute("RestC0",p.C0)
            end
        end
        e.hum.HipHeight*=s
        for _,key in ipairs({"NavigationRadius","NavigationHeight","NavigationRootHeight"}) do model:SetAttribute(key,model:GetAttribute(key)*s) end
    end
    local function detail(name,b,size,at,color,material,shape,rotation)
        if model:GetAttribute("PresentationRig")=="R6" and not crawler and b==torso then at=at-Vector3.new(0,.45,0) end
        local p=U.make("Part",model,{Name=name,Size=size*s,CFrame=b.CFrame*CFrame.new(at*s)*(rotation or CFrame.identity),
            Color=color or metal,Material=material or Enum.Material.Metal,Shape=shape or Enum.PartType.Block,
            CanCollide=false,CanQuery=false,CanTouch=false,Anchored=false,Massless=true,CollisionGroup="DeadSignalEnemies"})
        U.make("WeldConstraint",p,{Part0=b,Part1=p}) return p
    end
    for _,key in ipairs({"Enraged","Armored","Volatile","Alpha"}) do model:SetAttribute(key,mods[key]==true) end
    local face=model:FindFirstChild("InfectedFace",true)
    if face and mods.Enraged then for _,name in ipairs({"LeftIris","RightIris"}) do
        local iris=face:FindFirstChild(name);if iris then iris.BackgroundColor3=hot end
    end end
    e.elite=mods.Enraged or mods.Armored or mods.Volatile or mods.Alpha
    model:SetAttribute("Elite",e.elite==true) model:SetAttribute("EvolutionRevision",9)
    if mods.Enraged then
        for _,side in ipairs({-1,1}) do
            detail("OvergrownClavicle",torso,Vector3.new(.30,crawler and .4 or .75,.28),crawler and Vector3.new(side*.85,.12,-.7) or Vector3.new(side*.85,1.45,-.08),bone,Enum.Material.Slate,Enum.PartType.Ball,CFrame.Angles(0,0,side*-.6))
            detail("EnragedEye",head,Vector3.new(.20,.075,.10),Vector3.new(side*.19,.12,-.46),hot,Enum.Material.Neon)
        end
        detail("TornRestraint",torso,crawler and Vector3.new(1.56,.85,.17) or Vector3.new(1.56,.17,1),crawler and Vector3.new(0,.1,.25) or Vector3.new(0,.8,0),Color3.fromRGB(59,42,33),Enum.Material.Leather)
    end
    if mods.Armored then
        Wardrobe.armor(model)
        e.armorParts={} e.weakParts={}
        for _,def in ipairs({{zone="Body",b=torso,size=crawler and Vector3.new(1.62,.22,1.65) or Vector3.new(1.62,1.65,.26),at=crawler and Vector3.new(0,.49,.10) or Vector3.new(0,.75,-.61)},
            {zone="Head",b=head,size=Vector3.new(1.12,.9,.23),at=Vector3.new(0,.16,-.57)}}) do
            local p=detail("Breakable"..def.zone,def.b,def.size,def.at,metal)
            p.CanQuery=true p:SetAttribute("ArmorZone",def.zone);p:SetAttribute("HitZone","Armor")
            e.armorParts[def.zone]=p
            if not crawler and def.zone=="Body" then
                p.Transparency=1
                for _,plate in ipairs({{Vector3.new(1.23,.78,.23),Vector3.new(0,1.11,-.65),CFrame.Angles(-.12,0,0)},
                    {Vector3.new(1.08,.57,.23),Vector3.new(0,.39,-.64),CFrame.Angles(.10,0,0)},
                    {Vector3.new(.37,1.37,.22),Vector3.new(-.66,.74,-.52),CFrame.Angles(0,-.26,.06)},
                    {Vector3.new(.37,1.37,.22),Vector3.new(.66,.74,-.52),CFrame.Angles(0,.26,-.06)}}) do
                    detail("SegmentedBreastplate",torso,plate[1],plate[2],metal,nil,nil,plate[3]).Parent=p
                end
                for n=1,3 do detail("PlateScore",torso,Vector3.new(.73,.035,.045),Vector3.new(0,.92+n*.11,-.79),Color3.fromRGB(109,115,107)).Parent=p end
            elseif def.zone=="Head" then
                -- The face remains visible between the brow and respirator. Query
                -- surfaces follow actual protective components, including the crown.
                p.Size=Vector3.new(1.04,.22,.23)*s;p.CFrame=head.CFrame*CFrame.new(Vector3.new(0,.30,-.55)*s)
                for _,piece in ipairs({{Vector3.new(1.02,.30,.94),Vector3.new(0,.49,.03),Enum.PartType.Ball},
                    {Vector3.new(.17,.67,.74),Vector3.new(-.49,.12,.02),Enum.PartType.Block},
                    {Vector3.new(.17,.67,.74),Vector3.new(.49,.12,.02),Enum.PartType.Block},
                    {Vector3.new(.76,.30,.22),Vector3.new(0,-.26,-.53),Enum.PartType.Block}}) do
                    local shell=detail("HelmetProtection",head,piece[1],piece[2],metal,nil,piece[3]);shell.Parent=p;shell.CanQuery=true;shell:SetAttribute("ArmorZone","Head")
                end
                for n=-2,2 do detail("RespiratorVent",head,Vector3.new(.055,.14,.03),Vector3.new(n*.1,-.26,-.66),Color3.fromRGB(17,23,23)).Parent=p end
            end
            local horizontal=crawler and def.zone=="Body"
            local exposure=horizontal and Vector3.new(0,.18,0) or Vector3.new(0,0,.18)
            if model:GetAttribute("PresentationRig")=="R6" then
                if def.zone=="Head" then exposure=Vector3.zero
                elseif not horizontal then exposure=Vector3.new(0,0,.06) end
            end
            local weak=detail("Exposed"..def.zone,def.b,def.size*Vector3.new(.45,.65,.55),def.at+exposure,hot,Enum.Material.Neon)
            weak.Transparency=1 weak:SetAttribute("HitZone","Weakpoint");weak:SetAttribute("WeakZone",def.zone);e.weakParts[def.zone]=weak
            -- Plate hardware and scored seams convey armor without relying on hue.
            for _,side in ipairs({-1,1}) do local rivet=detail("PlateRivet",def.b,Vector3.new(.12,.12,.08),def.at+Vector3.new(side*def.size.X*.36,def.size.Y*.3,-.17),bone)
                rivet.Parent=p
            end
        end
        for _,side in ipairs({-1,1}) do detail("ShoulderGuard",torso,Vector3.new(.55,.33,.9),crawler and Vector3.new(side*.85,.15,-.7) or Vector3.new(side*.85,1.55,0),metal) end
    end
    if mods.Volatile then
        e.reactorParts={}
        for n=-1,1 do
            local p=detail("PressureCanister",torso,Vector3.new(.38,1.5,.38),Vector3.new(n*.46,.7,.7),Color3.fromRGB(96,111,91),Enum.Material.CorrodedMetal,Enum.PartType.Cylinder,CFrame.Angles(0,0,math.pi/2))
            for _,y in ipairs({.25,1.15}) do detail("TankClamp",torso,Vector3.new(1.48,.12,.17),Vector3.new(0,y,.91),metal) end
            p.CanQuery=true p:SetAttribute("HitZone","Reactor");e.reactorParts[#e.reactorParts+1]=p
        end
        local core=detail("PressureCore",torso,Vector3.new(.42,.65,.22),Vector3.new(0,.7,-.58),hot,Enum.Material.Neon)
        core.CanQuery=true core:SetAttribute("HitZone","Reactor");e.reactorParts[#e.reactorParts+1]=core
        for _,x in ipairs({-.3,.3}) do detail("PressureCage",torso,Vector3.new(.08,.96,.32),Vector3.new(x,.7,-.59),metal,nil,nil,CFrame.Angles(0,0,x*.5)) end
    end
    if e.kind=="Hound" then
        for n=1,4 do
            detail("CinderSpine",torso,Vector3.new(.24,.32+n*.06,.38),Vector3.new(0,.68,-.8+n*.43),bone,Enum.Material.Slate,Enum.PartType.Ball)
            detail("EmberFissure",torso,Vector3.new(.10,.10,.35),Vector3.new(n%2==0 and .55 or -.55,.28,-1+n*.47),hot,Enum.Material.Neon)
        end
        for _,side in ipairs({-1,1}) do
            detail("CanineFang",head,Vector3.new(.09,.35,.09),Vector3.new(side*.32,-.35,-.55),bone,Enum.Material.Slate,Enum.PartType.Ball)
            if mods.Alpha then
                detail("AlphaAntler",head,Vector3.new(.25,.55,.25),Vector3.new(side*.42,.55,.08),Color3.fromRGB(99,91,70),Enum.Material.Slate,Enum.PartType.Ball,CFrame.Angles(-.3,0,-side*.35))
                detail("AntlerTip",head,Vector3.new(.13,.38,.13),Vector3.new(side*.55,.82,.14),bone,Enum.Material.Slate,Enum.PartType.Ball,CFrame.Angles(-.4,0,-side*.4))
            end
        end
        model:SetAttribute("PackRole",mods.Alpha and "Alpha" or e.id%3==0 and "Flanker" or "Charger")
    elseif e.kind=="Stalker" then
        detail("AmbushCowl",head,Vector3.new(1.08,1.27,1.03),Vector3.new(0,.10,.25),Color3.fromRGB(27,35,36),Enum.Material.Fabric,Enum.PartType.Ball)
        for _,side in ipairs({-1,1}) do
            detail("SplitCowl",torso,Vector3.new(.38,2.5,.14),Vector3.new(side*.58,.55,.62),metal,Enum.Material.Fabric,nil,CFrame.Angles(0,0,side*.12))
            detail("SignalWhisker",head,Vector3.new(.045,.7,.045),Vector3.new(side*.52,.43,.22),bone,Enum.Material.Metal,nil,CFrame.Angles(0,0,side*.45))
        end
        model:SetAttribute("EnemyTitle","Stalker")
    end
    if mods.Armored and mods.Enraged then model:SetAttribute("EnemyTitle","Ironbound")
    elseif mods.Alpha then model:SetAttribute("EnemyTitle","Alpha Hound") end
end
function R.breakArmor(e,zone)
    local p=e.armorParts and e.armorParts[zone] if p then p:Destroy();e.armorParts[zone]=nil end
    local weak=e.weakParts and e.weakParts[zone]
    if weak then weak.Transparency=0 weak.CanQuery=true end
    e.model:SetAttribute(zone.."ArmorBroken",true)
    Wardrobe.degrade(e.model,zone)
    -- Exposed query geometry and destroyed plates change the actual envelope.
    e.entryGeometry=nil;e.entryBounds=nil;e.entrySupport=nil
end
function R.corpse(model,folder)
    if model:GetAttribute("Dead") then return end
    Pose.capture(model,workspace:GetServerTimeNow())
    model:SetAttribute("Dead",true) model:SetAttribute("Ragdoll",true) model.Parent=folder
    local hum=model:FindFirstChildOfClass("Humanoid")
    if hum then hum.RequiresNeck=false hum.BreakJointsOnDeath=false hum.AutoRotate=false hum.PlatformStand=true hum.Health=0 pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
    local bodies={}
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("Motor6D") and obj.Part0 and obj.Part1 and obj.Name~="RootJoint" then
            local world=obj.Part0.CFrame*obj.C0
            local a=U.make("Attachment",obj.Part0,{Name="RagdollA",CFrame=obj.Part0.CFrame:ToObjectSpace(world)})
            local b=U.make("Attachment",obj.Part1,{Name="RagdollB",CFrame=obj.Part1.CFrame:ToObjectSpace(world)})
            U.make("BallSocketConstraint",obj.Part0,{Name="Ragdoll_"..obj.Name,Attachment0=a,Attachment1=b,LimitsEnabled=true,UpperAngle=obj:GetAttribute("RagdollAngle") or 50,
                TwistLimitsEnabled=true,TwistLowerAngle=-25,TwistUpperAngle=25,MaxFrictionTorque=2,Restitution=0})
            obj.Enabled=false
        elseif obj:IsA("BasePart") then
            obj.Anchored=false
            local core=obj:GetAttribute("RagdollBody")==true
            obj.CollisionGroup="DeadSignalCorpses" obj.CanQuery=false obj.CanTouch=false obj.CanCollide=core obj.Massless=not core
            if core then bodies[#bodies+1]=obj end
            pcall(function() obj:SetNetworkOwner(nil) end)
        end
    end
    local torso=model:FindFirstChild("Torso")
    if torso then pcall(function()
        local direction=model:GetAttribute("DeathVector") or model:GetAttribute("HitVector") or -torso.CFrame.LookVector
        if typeof(direction)~="Vector3" or not U.finiteVector(direction) or direction.Magnitude<.01 then direction=-torso.CFrame.LookVector end
        torso:ApplyImpulse((direction.Unit*3+Vector3.new(0,.65,0))*torso.AssemblyMass)
    end) end
    -- Freeze only a supported, motionless pose after six seconds; never suspend a falling corpse.
    local quiet=0 local checks=0
    local function settle()
        if not model.Parent then return end checks+=1 local still=true
        for _,p in ipairs(bodies) do if p.AssemblyLinearVelocity.Magnitude>.35 or p.AssemblyAngularVelocity.Magnitude>.45 then still=false break end end
        quiet=still and quiet+1 or 0
        if quiet>=3 then
            for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true end end
            model:SetAttribute("CorpseSettled",true)
        elseif checks<15 then task.delay(1.2,settle) end
    end
    task.delay(6,settle)
    game:GetService("Debris"):AddItem(model,30)
    local old=folder:GetChildren() if #old>50 then old[1]:Destroy() end
end
return R
