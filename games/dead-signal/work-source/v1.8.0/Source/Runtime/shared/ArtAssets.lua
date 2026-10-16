-- Imported meshes are optional templates outside the updater's source folders.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local A={}
function A.family(name)
    local root=RS:FindFirstChild("DeadSignalArt") return root and root:FindFirstChild(name)
end
function A.complete(template)
    if not template then return false end
    local bones={}
    for _,p in ipairs(template:GetChildren()) do
        if p:IsA("MeshPart") and typeof(p:GetAttribute("ArtBind"))=="CFrame" then bones[p:GetAttribute("ArtBone") or ""]=true end
    end
    for _,name in ipairs({"Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}) do if not bones[name] then return false end end
    return true
end
local function anatomicalRig(model,scale)
    local root=model:FindFirstChild("HumanoidRootPart") local torso=model:FindFirstChild("Torso")
    if not root or not torso then return end
    local positions={Head=Vector3.new(0,2.25,0),["Right Arm"]=Vector3.new(.85,.30,0),["Left Arm"]=Vector3.new(-.85,.30,0),["Right Leg"]=Vector3.new(.35,-1.5,0),["Left Leg"]=Vector3.new(-.35,-1.5,0)}
    torso.Size=Vector3.new(1.4,2,.85)*scale
    for name,at in pairs(positions) do
        local p=model:FindFirstChild(name)
        p.CFrame=root.CFrame*CFrame.new(at*scale)
        p.Size=(name=="Head" and Vector3.new(.78,.95,.8) or name:find("Arm") and Vector3.new(.5,1.8,.6) or Vector3.new(.55,2,.7))*scale
    end
    for _,j in ipairs(torso:GetChildren()) do if j:IsA("Motor6D") then
        local side=j.Name:find("Right") and 1 or -1
        if j.Name=="Neck" then j.C0=CFrame.new(0,1.8*scale,0) j.C1=CFrame.new(0,-.45*scale,0)
        elseif j.Name:find("Shoulder") then j.C0=CFrame.new(side*.7*scale,1.35*scale,0) j.C1=CFrame.new(-side*.15*scale,1.05*scale,0)
        elseif j.Name:find("Hip") then j.C0=CFrame.new(side*.35*scale,-.3*scale,0) j.C1=CFrame.new(0,1.2*scale,0) end
    end end
    local upper=U.make("Part",model,{Name="UpperTorsoHitbox",Size=Vector3.new(1.7,1.15,.85)*scale,CFrame=root.CFrame*CFrame.new(0,1.3*scale,0),
        Transparency=1,Anchored=false,Massless=true,CanCollide=false,CanQuery=true,CanTouch=false,CollisionGroup="DeadSignalEnemies"})
    upper:SetAttribute("HitZone","Body") upper:SetAttribute("AuthoritativeHitbox",true)
    U.make("WeldConstraint",upper,{Part0=torso,Part1=upper})
    for _,side in ipairs({-1,1}) do
        local name=side==1 and "Right" or "Left"
        local foot=U.make("Part",model,{Name=name.."BootHitbox",Size=Vector3.new(.5,.52,1.1)*scale,CFrame=root.CFrame*CFrame.new(side*.61*scale,-2.76*scale,-.25*scale),
            Transparency=1,Anchored=false,Massless=true,CanCollide=false,CanQuery=true,CanTouch=false,CollisionGroup="DeadSignalEnemies"})
        foot:SetAttribute("HitZone","Body") foot:SetAttribute("AuthoritativeHitbox",true)
        U.make("WeldConstraint",foot,{Part0=model:FindFirstChild(name.." Leg"),Part1=foot})
    end
    for _,name in ipairs({"Armor","BackArmor"}) do local p=model:FindFirstChild(name) if p then p.Transparency=1 end end
    local weak=model:FindFirstChild("Weakpoint")
    if weak then weak.Size=Vector3.new(.28,.35,.045)*scale weak.CFrame=root.CFrame*CFrame.new(0,.8*scale,-.6*scale) weak.Color=Color3.fromRGB(233,165,77) end
    model:SetAttribute("RealismRig",true)
end
function A.enemy(model,kind,id,scale)
    local family=kind=="Hound" and "Hound" or kind=="Warden" and "Warden" or kind=="Crawler" and "Crawler" or "Infected_"..((id-1)%6+1)
    local template=A.family(family) if not template or #template:GetChildren()==0 then return false end
    if not A.complete(template) then return false end
    if template:GetAttribute("ArtRevision")==6 and kind~="Hound" and kind~="Crawler" then anatomicalRig(model,scale) end
    local fitted=0
    for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") then
        local bone=model:FindFirstChild(source:GetAttribute("ArtBone") or "Torso")
        local bind=source:GetAttribute("ArtBind")
        if bone and typeof(bind)=="CFrame" then
            local q=source:Clone() q.Name="Imported"..source.Name q.Size=q.Size*scale
            q.CFrame=bone.CFrame*CFrame.new(bind.Position*scale)*(bind-bind.Position)
            q.Anchored=false q.Massless=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model
            U.make("WeldConstraint",q,{Part0=bone,Part1=q}) fitted=fitted+1
        end
    end end
    if fitted>0 then
        for _,q in ipairs(model:GetDescendants()) do if q:IsA("BasePart") and q:GetAttribute("HitZone") and not q:GetAttribute("AuthoritativeHitbox") and not q.Name:find("Imported") and q.Name~="Weakpoint" and q.Name~="Armor" and q.Name~="BackArmor" then q.Transparency=1 q.CanQuery=false end end
        model:SetAttribute("ImportedArt",true)
    end
    return fitted>0
end
function A.weapon(model,id,pose,finish)
    local template=A.family("Weapon_"..id) if not template or #template:GetChildren()==0 then return false end
    local body=false for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") and source:GetAttribute("ArtGroup")=="body" and typeof(source:GetAttribute("ArtBind"))=="CFrame" then body=true end end
    if not body then return false end
    local meshes={}
    for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") and typeof(source:GetAttribute("ArtBind"))=="CFrame" then
        local q=source:Clone() q.Name="Imported"..source.Name q.CFrame=source:GetAttribute("ArtBind")
        q.Anchored=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model
        if finish and template:GetAttribute("ArtRevision")==6 and not source:GetAttribute("ArtOptic") then
            local surface=q:FindFirstChildOfClass("SurfaceAppearance")
            if surface then surface.Color=(surface.Color or Color3.new(1,1,1)):Lerp(finish,.55) else q.Color=q.Color:Lerp(finish,.55) end
        end
        meshes[#meshes+1]={part=q,cf=q.CFrame,group=source:GetAttribute("ArtGroup") or "body",optic=source:GetAttribute("ArtOptic")==true,transparency=0}
    end end
    if #meshes==0 then return false end
    local keep={}
    for _,entry in ipairs(pose.parts) do
        local p=entry.part
        if p==model.PrimaryPart or p.Name=="Muzzle" or p.Name=="ResonanceConduit" or entry.group=="left" or entry.group=="right" or entry.group=="knife" or entry.group=="shell" then keep[#keep+1]=entry
        else p:Destroy() end
    end
    for _,entry in ipairs(meshes) do keep[#keep+1]=entry end pose.parts=keep model:SetAttribute("ImportedArt",true)
    local marker=template:GetAttribute("ArtMuzzle")
    if typeof(marker)=="Vector3" then
        for _,entry in ipairs(keep) do if entry.part.Name=="Muzzle" then entry.cf=CFrame.new(marker) entry.part.CFrame=entry.cf end end
    end
    return true
end
function A.viewArms(model,pose,pistol)
    local template=A.family(pistol and "ViewArms_Pistol" or "ViewArms_Rifle")
    if not template or template:GetAttribute("ArtRevision")~=6 then return false end
    local groups={}
    for _,p in ipairs(template:GetChildren()) do if p:IsA("MeshPart") and typeof(p:GetAttribute("ArtBind"))=="CFrame" then groups[p:GetAttribute("ArtGroup") or ""]=true end end
    if not groups.left or not groups.right then return false end
    local keep={}
    for _,entry in ipairs(pose.parts) do if entry.group=="left" or entry.group=="right" then entry.part:Destroy() else keep[#keep+1]=entry end end
    for _,p in ipairs(template:GetChildren()) do if p:IsA("MeshPart") and typeof(p:GetAttribute("ArtBind"))=="CFrame" then
        local q=p:Clone() q.Name="Operator"..p.Name q.CFrame=p:GetAttribute("ArtBind")
        q.Anchored=true q.CanCollide=false q.CanTouch=false q.CanQuery=false q.Parent=model
        keep[#keep+1]={part=q,cf=q.CFrame,group=p:GetAttribute("ArtGroup"),optic=false,transparency=0}
    end end
    pose.parts=keep model:SetAttribute("ImportedViewArms",true) return true
end
function A.transport(model,cf)
    local template=A.family("TransportVan") if not template or #template:GetChildren()==0 then return false end
    local old=model:GetDescendants() local count=0
    for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") and typeof(source:GetAttribute("ArtBind"))=="CFrame" then
        local q=source:Clone() q.Name="Imported"..source.Name q.CFrame=cf*source:GetAttribute("ArtBind")
        q.Anchored=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model count=count+1
    end end
    if count==0 then return false end
    for _,p in ipairs(old) do if p:IsA("BasePart") and p.Name~="HeadlightLens" and p.Name~="TailLightLens" and not p:FindFirstChildOfClass("SurfaceGui") then p.Transparency=1 end end
    model:SetAttribute("ImportedArt",true) return true
end
return A
