-- Server-owned world weapon and arm targets. Cosmetic look data never changes hits.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local T={}
local rigs=setmetatable({},{__mode="k"})
local function rotationTo(vector)
    local v=vector.Unit local up=math.abs(v:Dot(Vector3.new(0,1,0)))>.96 and Vector3.new(0,0,1) or Vector3.new(0,1,0)
    return CFrame.lookAt(Vector3.new(),v,up)
end
function T.clear(char)
    if not char then return end
    local r=rigs[char]
    if r then
        for joint,c0 in pairs(r.original) do if joint.Parent then joint.C0=c0 joint.Transform=CFrame.new() end end
        for _,obj in ipairs(r.controls) do obj:Destroy() end
        rigs[char]=nil
    end
    local motor=char:FindFirstChild("WeaponShoulder",true) if motor then motor:Destroy() end
    local model=char:FindFirstChild("CarriedWeapon") if model then model:Destroy() end
    char:SetAttribute("DeadSignalArmed",false)
end
function T.attach(char,model,id,pistol)
    local torso=char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then model:Destroy() return end
    local root=model.PrimaryPart local scale=.78 local origin=root.CFrame
    for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then
        local localCF=origin:Inverse()*part.CFrame
        part.Size=part.Size*scale part.CFrame=CFrame.new(localCF.Position*scale)*(localCF-localCF.Position)
        part.Anchored=false part.Massless=true part.CanCollide=false part.CanQuery=false part.CanTouch=false
        if part~=root then U.make("WeldConstraint",part,{Part0=root,Part1=part}) end
    end end
    local motor=U.make("Motor6D",torso,{Name="WeaponShoulder",Part0=torso,Part1=root,C0=CFrame.new(),C1=CFrame.new()})
    local r={model=model,torso=torso,motor=motor,original={},controls={},pistol=pistol,id=id}
    rigs[char]=r
    local right=U.make("Attachment",root,{Name="RightGripTarget",Position=Vector3.new(0,-.32,pistol and .19 or .21)*scale})
    local left=U.make("Attachment",root,{Name="LeftGripTarget",Position=Vector3.new(pistol and -.16 or -.06,-.20,pistol and .13 or -.78)*scale})
    for _,side in ipairs({"Right","Left"}) do
        local arm=char:FindFirstChild(side.."UpperArm") local hand=char:FindFirstChild(side.."Hand")
        if arm and hand then
            local pole=U.make("Attachment",torso,{Name="DeadSignal"..side.."Elbow",Position=Vector3.new(side=="Right" and 1.8 or -1.8,-.7,-.25)})
            r.controls[#r.controls+1]=pole
            local ik=U.make("IKControl",char:FindFirstChildOfClass("Humanoid"),{Name="DeadSignal"..side.."Grip",Type=Enum.IKControlType.Transform,
                ChainRoot=arm,EndEffector=hand,Target=side=="Right" and right or left,Pole=pole,Weight=1,SmoothTime=.12,Priority=2})
            local grip=hand:FindFirstChild(side.."GripAttachment") if grip then ik.EndEffectorOffset=grip.CFrame end
            r.controls[#r.controls+1]=ik
        else
            local joint=torso:FindFirstChild(side.." Shoulder") if joint then r.original[joint]=joint.C0 end
        end
    end
    char:SetAttribute("DeadSignalArmed",true) char:SetAttribute("DeadSignalAim",false)
    T.update(char,false,0,0,false)
    model:PivotTo(torso.CFrame*motor.C0)
end
function T.update(char,aim,pitch,yaw,sprint)
    local r=char and rigs[char] if not r or not r.model.Parent then return end
    if char:GetAttribute("DeadSignalCrawling") then return end
    local pos=aim and Vector3.new(.30,.95,-1.17) or Vector3.new(.67,.62,-1.18)
    if r.pistol then pos=aim and Vector3.new(.12,.90,-1.55) or Vector3.new(.48,.45,-1.5) end
    local cf=CFrame.new(pos)*CFrame.Angles(pitch or 0,yaw or 0,sprint and -.18 or 0)
    r.motor.C0=cf
    for joint,original in pairs(r.original) do
        local target=r.model.PrimaryPart:FindFirstChild(joint.Name:sub(1,5)=="Right" and "RightGripTarget" or "LeftGripTarget")
        local at=(cf*target.Position)-original.Position
        local hand=joint.C1:PointToObjectSpace(Vector3.new(0,-joint.Part1.Size.Y*.45,0))
        joint.C0=CFrame.new(original.Position)*rotationTo(at)*rotationTo(hand):Inverse()
    end
    char:SetAttribute("DeadSignalAim",aim==true)
    char:SetAttribute("DeadSignalAimPitch",pitch or 0) char:SetAttribute("DeadSignalAimYaw",yaw or 0)
end
function T.client(char)
    if not char or not char:GetAttribute("DeadSignalArmed") or char:GetAttribute("DeadSignalCrawling") then return end
    local torso=char:FindFirstChild("Torso")
    if torso then for _,name in ipairs({"Right Shoulder","Left Shoulder"}) do local j=torso:FindFirstChild(name) if j then j.Transform=CFrame.new() end end end
end
return T
