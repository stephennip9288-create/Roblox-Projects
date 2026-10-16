local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Pose=require(RS.DeadSignal.NPCPose)
local Anatomy=require(script.Parent.RigAnatomy)
local R={build=Anatomy.build}
-- Original welded details follow the shared articulated skeleton and its ragdoll.
function R.evolve(e)
    local model=e.model local mods=e.mods or {} local torso=model.Torso local head=model.Head
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
        local p=U.make("Part",model,{Name=name,Size=size*s,CFrame=b.CFrame*CFrame.new(at*s)*(rotation or CFrame.identity),
            Color=color or metal,Material=material or Enum.Material.Metal,Shape=shape or Enum.PartType.Block,
            CanCollide=false,CanQuery=false,CanTouch=false,Anchored=false,Massless=true,CollisionGroup="DeadSignalEnemies"})
        U.make("WeldConstraint",p,{Part0=b,Part1=p}) return p
    end
    for _,key in ipairs({"Enraged","Armored","Volatile","Alpha"}) do model:SetAttribute(key,mods[key]==true) end
    e.elite=mods.Enraged or mods.Armored or mods.Volatile or mods.Alpha
    model:SetAttribute("Elite",e.elite==true) model:SetAttribute("EvolutionRevision",9)
    if mods.Enraged then
        for _,side in ipairs({-1,1}) do
            detail("OvergrownClavicle",torso,Vector3.new(.30,.75,.28),Vector3.new(side*.85,1.45,-.08),bone,Enum.Material.Slate,Enum.PartType.Ball,CFrame.Angles(0,0,side*-.6))
            detail("EnragedEye",head,Vector3.new(.20,.075,.10),Vector3.new(side*.19,.12,-.46),hot,Enum.Material.Neon)
        end
        detail("TornRestraint",torso,Vector3.new(1.56,.17,1),Vector3.new(0,.8,0),Color3.fromRGB(59,42,33),Enum.Material.Leather)
    end
    if mods.Armored then
        e.armorParts={} e.weakParts={}
        for _,def in ipairs({{zone="Body",b=torso,size=Vector3.new(1.62,1.65,.26),at=Vector3.new(0,.75,-.61)},
            {zone="Head",b=head,size=Vector3.new(1.12,.9,.23),at=Vector3.new(0,.16,-.57)}}) do
            local p=detail("Breakable"..def.zone,def.b,def.size,def.at,metal)
            p.CanQuery=true p:SetAttribute("ArmorZone",def.zone);p:SetAttribute("HitZone","Armor")
            e.armorParts[def.zone]=p
            local weak=detail("Exposed"..def.zone,def.b,def.size*Vector3.new(.45,.65,.55),def.at+Vector3.new(0,0,.18),hot,Enum.Material.Neon)
            weak.Transparency=1 weak:SetAttribute("HitZone","Weakpoint");weak:SetAttribute("WeakZone",def.zone);e.weakParts[def.zone]=weak
            -- Plate hardware and scored seams convey armor without relying on hue.
            for _,side in ipairs({-1,1}) do local rivet=detail("PlateRivet",def.b,Vector3.new(.12,.12,.08),def.at+Vector3.new(side*def.size.X*.36,def.size.Y*.3,-.17),bone)
                rivet.Parent=p
            end
        end
        for _,side in ipairs({-1,1}) do detail("ShoulderGuard",torso,Vector3.new(.55,.33,.9),Vector3.new(side*.85,1.55,0),metal) end
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
            if mods.Alpha then detail("AlphaAntler",head,Vector3.new(.22,.9,.25),Vector3.new(side*.42,.65,.05),bone,Enum.Material.Slate,Enum.PartType.Ball,CFrame.Angles(-.3,0,-side*.35)) end
        end
        model:SetAttribute("PackRole",mods.Alpha and "Alpha" or e.id%3==0 and "Flanker" or "Charger")
    elseif e.kind=="Stalker" then
        detail("AmbushCowl",head,Vector3.new(1.08,1.27,1.03),Vector3.new(0,.10,.25),Color3.fromRGB(27,35,36),Enum.Material.Fabric,Enum.PartType.Ball)
        for _,side in ipairs({-1,1}) do
            detail("SplitCowl",torso,Vector3.new(.38,2.5,.14),Vector3.new(side*.58,.55,.62),metal,Enum.Material.Fabric,nil,CFrame.Angles(0,0,side*.12))
            detail("SignalWhisker",head,Vector3.new(.04,.04,.8),Vector3.new(side*.35,.1,-.55),bone,Enum.Material.Metal,nil,CFrame.Angles(0,side*.45,0))
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
            local core=obj:GetAttribute("RagdollBody")==true
            obj.CollisionGroup="DeadSignalCorpses" obj.CanQuery=false obj.CanTouch=false obj.CanCollide=core obj.Massless=not core
            if core then bodies[#bodies+1]=obj end
            pcall(function() obj:SetNetworkOwner(nil) end)
        end
    end
    local torso=model:FindFirstChild("Torso")
    if torso then pcall(function() torso:ApplyImpulse((-torso.CFrame.LookVector*3+Vector3.new(.4,.4,0))*torso.AssemblyMass) end) end
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
