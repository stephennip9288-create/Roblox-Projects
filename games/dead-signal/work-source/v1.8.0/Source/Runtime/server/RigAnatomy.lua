-- Articulated anatomy. Every visible joint has a connected rest frame and death constraint.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Art=require(RS.DeadSignal.ArtAssets)
local A={}
function A.build(parent,kind,position,id)
    local hound=kind=="Hound" local crawler=kind=="Crawler" local scale=kind=="Warden" and 1.4 or 1
    local model=U.make("Model",parent,{Name=kind})
    model:SetAttribute("EnemyType",kind) model:SetAttribute("ArtRevision",8) model:SetAttribute("ArticulatedRig",true)
    model:SetAttribute("ForwardAxis","-Z") model:SetAttribute("PoseSeed",id*.73)
    local outfits={{82,84,65},{56,76,81},{158,159,133},{42,53,58},{95,90,65},{67,80,59}}
    local cloth=kind=="Warden" and Color3.fromRGB(41,48,48) or U.color(outfits[(id-1)%6+1])
    local skin=Color3.fromRGB(135,137,111) local leather=Color3.fromRGB(37,34,29)
    local fur=Color3.fromRGB(148+id%3*3,151+id%3*3,141+id%3*3)
    local function bone(name,size,at,head)
        local q=U.make("Part",model,{Name=name,Size=size*scale,CFrame=CFrame.new(position+at*scale),
            Transparency=1,Anchored=false,Massless=name~="HumanoidRootPart",CanCollide=false,CanQuery=name~="HumanoidRootPart",CanTouch=false,
            CollisionGroup="DeadSignalEnemies",CustomPhysicalProperties=PhysicalProperties.new(.65,.4,0)})
        if name~="HumanoidRootPart" then q:SetAttribute("HitZone",head and "Head" or "Body") q:SetAttribute("AuthoritativeHitbox",true) q:SetAttribute("RagdollBody",true) end
        return q
    end
    local function joint(name,a,b,at,angle)
        local world=CFrame.new(position+at*scale)
        local j=U.make("Motor6D",a,{Name=name,Part0=a,Part1=b,C0=a.CFrame:ToObjectSpace(world),C1=b.CFrame:ToObjectSpace(world)})
        j:SetAttribute("RestC0",j.C0) j:SetAttribute("RagdollAngle",angle or 50) return j
    end
    local function shell(b,name,size,at,color,material,rot,shape)
        local q=U.make("Part",model,{Name=name,Size=size*scale,CFrame=CFrame.new(position+at*scale)*(rot or CFrame.identity),
            Color=color or cloth,Material=material or Enum.Material.Fabric,Anchored=false,Massless=true,CanCollide=false,CanQuery=false,CanTouch=false,CollisionGroup="DeadSignalEnemies"})
        q.Shape=shape or Enum.PartType.Ball
        if q.Material==Enum.Material.Fabric then q.MaterialVariant=hound and "DS_Canine" or "DS_Canvas" elseif q.Material==Enum.Material.Leather then q.MaterialVariant="DS_Leather" end
        if color==skin then q.MaterialVariant="DS_InfectedSkin" q.Color=Color3.fromRGB(180,185,163) end
        U.make("WeldConstraint",q,{Part0=b,Part1=q}) return q
    end
    local root=bone("HumanoidRootPart",Vector3.new(1.7,hound and 1.2 or crawler and 1 or 2,1.3),Vector3.zero)
    local torso=bone("Torso",hound and Vector3.new(1.35,1.2,2.4) or crawler and Vector3.new(1.55,.75,2.25) or Vector3.new(1.45,2.1,.85),Vector3.zero)
    joint("RootJoint",root,torso,Vector3.zero,10)
    local headAt=hound and Vector3.new(0,.35,-1.42) or crawler and Vector3.new(0,.30,-1.62) or Vector3.new(0,2.20,-.04)
    local head=bone("Head",hound and Vector3.new(.92,1,1.18) or Vector3.new(.82,.98,.85),headAt,true)
    joint("Neck",torso,head,hound and Vector3.new(0,.2,-1.05) or crawler and Vector3.new(0,.12,-1.20) or Vector3.new(0,1.75,0),35)
    local function limb(side,front,upperAt,elbowAt,lowerAt,wristAt,handAt,upperSize,lowerSize)
        local prefix=side==1 and "Right" or "Left"
        local upper=bone(prefix..(front and " Arm" or " Leg"),upperSize,upperAt)
        local lower=bone(prefix..(front and " Forearm" or " Shin"),lowerSize,lowerAt)
        local endPart=bone(prefix..(front and " Hand" or " Foot"),hound and Vector3.new(.38,.24,.56) or front and Vector3.new(.30,.36,.32) or Vector3.new(.48,.40,.88),handAt)
        local shoulder=front and " Shoulder" or " Hip" local middle=front and " Elbow" or " Knee" local endName=front and " Wrist" or " Ankle"
        local origin=hound and Vector3.new(side*.48,.30,front and -.82 or .86) or crawler and Vector3.new(side*(front and .68 or .33),0,front and -.72 or .55) or Vector3.new(side*(front and .69 or .34),front and 1.52 or -.27,0)
        joint(prefix..shoulder,torso,upper,origin,front and 75 or 50)
        joint(prefix..middle,upper,lower,elbowAt,65) joint(prefix..endName,lower,endPart,wristAt,25)
        if hound then
            local function segment(b,name,a,c,width,depth)
                local delta=c-a
                local rot=CFrame.lookAt(Vector3.zero,delta)*CFrame.Angles(math.pi/2,0,0)
                return shell(b,name,Vector3.new(width,delta.Magnitude+.20,depth),(a+c)*.5,fur,nil,rot)
            end
            segment(upper,front and "ScapularMuscle" or "HaunchMuscle",origin,elbowAt,front and .46 or .58,front and .55 or .68)
            segment(lower,"CanineLowerLeg",elbowAt,wristAt,.26,.30)
            shell(lower,"CanineJoint",Vector3.new(.35,.39,.37),elbowAt,fur)
            shell(endPart,"PasternJoint",Vector3.new(.27,.29,.31),wristAt,fur)
            shell(endPart,"CaninePaw",Vector3.new(.43,.27,.61),handAt,leather,Enum.Material.Leather)
            for toe=-1,1 do
                shell(endPart,"Toe",Vector3.new(.14,.15,.28),handAt+Vector3.new(toe*.12,-.01,-.20),fur)
                shell(endPart,"Claw",Vector3.new(.055,.07,.13),handAt+Vector3.new(toe*.12,-.03,-.34),Color3.fromRGB(116,111,88),Enum.Material.SmoothPlastic)
            end
        else
            shell(upper,front and "TornJacketSleeve" or "TrouserThigh",upperSize*Vector3.new(1.08,1.08,1.1),upperAt,cloth)
            shell(lower,front and "ForearmAnatomy" or "TrouserCalf",lowerSize*Vector3.new(.97,1.07,1.04),lowerAt,front and skin or cloth,front and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
            shell(lower,front and "ElbowContour" or "KneeContour",front and Vector3.new(.32,.28,.35) or Vector3.new(.44,.29,.48),elbowAt,front and skin or leather,front and Enum.Material.SmoothPlastic or Enum.Material.Leather)
            if front then
                shell(endPart,"Palm",Vector3.new(.33,.34,.30),handAt,skin,Enum.Material.SmoothPlastic)
                for finger=1,4 do
                    local at=handAt+Vector3.new(-.17+finger*.071,crawler and -.05 or -.22,crawler and -.23 or -.03)
                    shell(endPart,"FingerProximal",Vector3.new(.072,.22,.09),at,skin,Enum.Material.SmoothPlastic,CFrame.Angles(crawler and math.pi/2 or -.18,0,0))
                    shell(endPart,"FingerDistal",Vector3.new(.065,.15,.08),at+(crawler and Vector3.new(0,-.01,-.13) or Vector3.new(0,-.13,-.04)),skin,Enum.Material.SmoothPlastic,CFrame.Angles(crawler and math.pi/2 or -.45,0,0))
                end
                shell(endPart,"Thumb",Vector3.new(.115,.28,.13),handAt+Vector3.new(-side*.21,-.03,-.03),skin,Enum.Material.SmoothPlastic,CFrame.Angles(0,0,-side*.45))
            else
                shell(endPart,"LeatherBoot",Vector3.new(.48,.43,.94),handAt+Vector3.new(0,0,-.1),leather,Enum.Material.Leather)
                shell(endPart,"BootSole",Vector3.new(.49,.10,.97),handAt+Vector3.new(0,-.20,-.10),Color3.fromRGB(21,23,21),Enum.Material.Rubber,nil,Enum.PartType.Block)
                for lace=1,3 do shell(endPart,"BootLace",Vector3.new(.30,.025,.04),handAt+Vector3.new(0,.17,-.18-lace*.1),Color3.fromRGB(84,79,61),Enum.Material.Fabric,nil,Enum.PartType.Block) end
            end
        end
        return upper,lower,endPart
    end
    for _,side in ipairs({-1,1}) do
        if hound then
            limb(side,true,Vector3.new(side*.48,-.04,-.84),Vector3.new(side*.48,-.40,-.88),Vector3.new(side*.48,-.90,-.88),Vector3.new(side*.48,-1.39,-.91),Vector3.new(side*.48,-1.49,-1.04),Vector3.new(.44,.72,.55),Vector3.new(.25,.98,.30))
            limb(side,false,Vector3.new(side*.46,-.04,.78),Vector3.new(side*.46,-.40,.63),Vector3.new(side*.46,-.85,.93),Vector3.new(side*.46,-1.30,.78),Vector3.new(side*.46,-1.49,.63),Vector3.new(.60,.72,.72),Vector3.new(.27,.95,.35))
        elseif crawler then
            limb(side,true,Vector3.new(side*.88,-.15,-1.02),Vector3.new(side*1.02,-.28,-1.39),Vector3.new(side*.94,-.40,-1.88),Vector3.new(side*.88,-.50,-2.35),Vector3.new(side*.88,-.53,-2.49),Vector3.new(.44,.46,.95),Vector3.new(.34,.35,1.02))
            limb(side,false,Vector3.new(side*.37,-.17,1.02),Vector3.new(side*.43,-.24,1.60),Vector3.new(side*.46,-.33,2.13),Vector3.new(side*.49,-.42,2.63),Vector3.new(side*.49,-.48,2.82),Vector3.new(.52,.50,1.18),Vector3.new(.41,.45,1.05))
        else
            limb(side,true,Vector3.new(side*.70,.96,-.05),Vector3.new(side*.72,.40,-.08),Vector3.new(side*.72,-.12,-.11),Vector3.new(side*.72,-.65,-.14),Vector3.new(side*.72,-.82,-.14),Vector3.new(.43,1.14,.52),Vector3.new(.34,1.05,.43))
            limb(side,false,Vector3.new(side*.42,-.94,0),Vector3.new(side*.49,-1.58,0),Vector3.new(side*.53,-2.14,0),Vector3.new(side*.56,-2.70,0),Vector3.new(side*.56,-2.83,-.18),Vector3.new(.53,1.25,.61),Vector3.new(.43,1.12,.50))
        end
    end
    -- Reuse the creator's textured facial/jacket meshes; replace the rigid limb shells.
    local family=hound and "Hound" or crawler and "Crawler" or kind=="Warden" and "Warden" or "Infected_"..((id-1)%6+1)
    local template=Art.family(family) local fitted=0
    if template then for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") then
        local b=source:GetAttribute("ArtBone") local bind=source:GetAttribute("ArtBind")
        if typeof(bind)=="CFrame" and (b=="Head" or b=="Torso" and not hound) then
            local target=b=="Head" and head or torso local factor=hound and Vector3.new(1.18,1.05,1.13) or crawler and Vector3.new(1.12,1.12,1.12) or Vector3.new(1.12,1,1.12)
            local q=source:Clone() q.DoubleSided=true q.Name="Fitted_"..source.Name q.Size*=factor*scale
            local localBind=bind
            if crawler and b=="Head" then
                -- The old crawler face pointed into the floor. Fit an upright infected head instead below.
                q:Destroy()
            else
                q.CFrame=target.CFrame*CFrame.new(localBind.Position*factor*scale)*(localBind-localBind.Position)
                q.Anchored=false q.Massless=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model
                U.make("WeldConstraint",q,{Part0=target,Part1=q}) fitted+=1
            end
        end
    end end end
    if crawler then
        local face=Art.family("Infected_"..((id-1)%6+1))
        if face then for _,source in ipairs(face:GetChildren()) do if source:IsA("MeshPart") and source:GetAttribute("ArtBone")=="Head" then
            local bind=source:GetAttribute("ArtBind") local q=source:Clone() q.Name="CrawlerFace_"..source.Name
            q.Size*=1.14 q.CFrame=head.CFrame*CFrame.new(bind.Position*1.14)*(bind-bind.Position)
            q.Anchored=false q.Massless=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model U.make("WeldConstraint",q,{Part0=head,Part1=q}) fitted+=1
        end end end
    end
    if hound then
        shell(torso,"ThoracicRibcage",Vector3.new(1.17,1.27,2.08),Vector3.new(0,.13,-.26),fur)
        shell(torso,"TuckedAbdomen",Vector3.new(.81,.72,1.55),Vector3.new(0,.18,.66),fur)
        shell(torso,"HaunchBridge",Vector3.new(1.04,1.05,1.25),Vector3.new(0,.12,.98),fur)
        shell(torso,"NeckRuff",Vector3.new(.88,.98,1.08),Vector3.new(0,.42,-1.01),fur,nil,CFrame.Angles(-.4,0,0))
        local last=torso
        for n=1,3 do
            local at=Vector3.new(0,.30-n*.20,1.30+n*.48)
            local tail=bone("Tail"..n,Vector3.new(.27-n*.045,.28-n*.04,.66),at)
            joint("Tail"..n.."Joint",last,tail,at-Vector3.new(0,0,.31),38)
            shell(tail,"FurTail",tail.Size/scale,at,fur) last=tail
        end

    elseif fitted==0 then
        shell(torso,"Jacket",Vector3.new(1.4,2.1,.86),Vector3.new(0,.65,0),cloth)
        shell(head,"Cranium",Vector3.new(.82,1,.83),headAt,skin,Enum.Material.SmoothPlastic)
    end
    if not hound then
        for _,side in ipairs({-1,1}) do
            shell(torso,"CollarFold",Vector3.new(.29,.13,.39),crawler and Vector3.new(side*.23,.17,-1.65) or Vector3.new(side*.22,1.72,-.25),cloth,nil,CFrame.Angles(0,side*.5,0))
            shell(torso,"BeltPouch",Vector3.new(.29,.34,.20),crawler and Vector3.new(side*.43,.12,.32) or Vector3.new(side*.45,-.20,-.39),leather,Enum.Material.Leather,nil,Enum.PartType.Block)
        end
        if kind=="Warden" then
            shell(torso,"Armor",Vector3.new(1.25,1.08,.15),Vector3.new(0,.85,-.54),Color3.fromRGB(42,49,48),Enum.Material.Metal,nil,Enum.PartType.Block)
            local weak=shell(torso,"Weakpoint",Vector3.new(.23,.36,.07),Vector3.new(0,.85,-.66),Color3.fromRGB(226,163,78),Enum.Material.Neon,nil,Enum.PartType.Block)
            weak.CanQuery=true weak:SetAttribute("HitZone","Weakpoint")
        end
    end
    -- Textured shells are rebound to the new articulated limbs. Their cloth is continuous
    -- over the joint caps; the invisible skeleton remains authoritative for hits/physics.
    local function fitShell(source,b,size,cf)
        local q=source:Clone() q.Name=source.Name q:SetAttribute("SourceMeshName",source.Name)
        q.Size=size*scale q.CFrame=CFrame.new(position)*cf
        q.DoubleSided=true q.Anchored=false q.Massless=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model
        U.make("WeldConstraint",q,{Part0=b,Part1=q}) return q
    end
    local replacements={}
    if template and not hound then
        for _,side in ipairs({"Right","Left"}) do
            local upper,lower,trouser
            for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") then
                local b=source:GetAttribute("ArtBone")
                if b==side.." Arm" and not crawler then
                    if source.Size.Y>1.1 then upper=source elseif source.Size.Y>.6 then lower=source end
                elseif b==side.." Leg" and (crawler and source.Size.Z>2 or not crawler and source.Size.Y>2) then trouser=source end
            end end
            for _,entry in ipairs({{upper,side.." Arm",Vector3.new(.44,1.19,.54),"TornJacketSleeve"},{lower,side.." Forearm",Vector3.new(.35,1.09,.44),"ForearmAnatomy"},
                {trouser,side.." Leg",crawler and Vector3.new(.55,.52,1.22) or Vector3.new(.55,1.29,.63),"TrouserThigh"},
                {trouser,side.." Shin",crawler and Vector3.new(.43,.47,1.09) or Vector3.new(.45,1.16,.53),"TrouserCalf"}}) do
                if entry[1] then
                    local b=model:FindFirstChild(entry[2]) local cf=CFrame.new(b.Position-position)
                    fitShell(entry[1],b,entry[3],cf) replacements[entry[4]]=true
                    if entry[2]:find("Forearm") then replacements.Palm=true replacements.FingerProximal=true replacements.FingerDistal=true replacements.Thumb=true end
                end
            end
        end
    elseif hound then
        -- Worn harness gives a readable chest/waist silhouette without obscuring the face.
        for _,z in ipairs({-.45,.65}) do for n=1,18 do
            local a=(n-1)*math.pi/9 local b=n*math.pi/9
            local pa=Vector3.new(math.cos(a)*.51,-.13+math.sin(a)*.43,z)
            local pb=Vector3.new(math.cos(b)*.51,-.13+math.sin(b)*.43,z)
            shell(torso,"HarnessStrap",Vector3.new(.11,.09,(pb-pa).Magnitude+.02),(pa+pb)*.5,leather,Enum.Material.Leather,CFrame.lookAt(Vector3.zero,pb-pa),Enum.PartType.Block)
        end end
    end
    for _,q in ipairs(model:GetChildren()) do if q:IsA("BasePart") and replacements[q.Name] then q:Destroy() end end
    local collider=shell(torso,"BodyCollider",hound and Vector3.new(1.9,2.75,2.9) or crawler and Vector3.new(2.05,1.35,3.10) or Vector3.new(2.05,5.35,1.25),hound and Vector3.new(0,-.135,-.10) or crawler and Vector3.new(0,.105,-.12) or Vector3.new(0,-.255,0),cloth,nil,nil,Enum.PartType.Ball)
    collider.Transparency=1 collider.CanCollide=true collider.Massless=true collider.CustomPhysicalProperties=PhysicalProperties.new(.65,.15,0)
    collider:SetAttribute("AliveCollider",true)
    local clearance=(hound and 1.66 or crawler and .72 or 3.08)*scale
    local left=model:FindFirstChild("Left Leg") local hip=clearance-root.Size.Y*.5-left.Size.Y
    local hum=U.make("Humanoid",model,{MaxHealth=100,Health=100,WalkSpeed=10,HipHeight=hip,BreakJointsOnDeath=false,RequiresNeck=false,DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None,AutoRotate=true})
    model.PrimaryPart=root model:SetAttribute("NavigationRootHeight",clearance)
    model:SetAttribute("NavigationRadius",(hound and 1.60 or crawler and 1.70 or 1.18)*scale)
    model:SetAttribute("NavigationHeight",(hound and 3.45 or crawler and 2.35 or 5.95)*scale)
    model:SetAttribute("ImportedArt",fitted>0) model:SetAttribute("OutfitVariant",(id-1)%6+1)
    pcall(function() root:SetNetworkOwner(nil) end)
    return model,root,hum
end
return A
