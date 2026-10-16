local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Pose=require(RS.DeadSignal.NPCPose)
local Anatomy=require(script.Parent.RigAnatomy)
local R={build=Anatomy.build}
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
