-- PBR surfaces and fitted props never participate in navigation or combat queries.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local A=require(RS.DeadSignal.ArtAssets)
local W={}
local materialNames={Floor=Enum.Material.Concrete,Concrete=Enum.Material.Concrete,Plaster=Enum.Material.Plaster,Brick=Enum.Material.Brick,
    Steel=Enum.Material.Metal,Rust=Enum.Material.CorrodedMetal,Canvas=Enum.Material.Fabric,Leather=Enum.Material.Leather,
    Rubber=Enum.Material.Rubber,Wood=Enum.Material.WoodPlanks,Snow=Enum.Material.Snow}
function W.surface(p)
    local n=p.Name:lower()
    if p.Material==Enum.Material.Neon or p.Material==Enum.Material.Glass or n:find("sign") or n:find("marker") or n:find("hitbox") or p.Transparency>.8 then return nil end
    if p.Material==Enum.Material.Snow then return "Snow" end
    if n:find("floor") and not n:find("joint") then return "Floor" end
    if n:find("plaster") or n:find("repair") then return "Plaster" end
    if p.Material==Enum.Material.Brick then return "Brick" end
    if p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks then return "Wood" end
    if p.Material==Enum.Material.CorrodedMetal then return "Rust" end
    if p.Material==Enum.Material.Fabric then return "Canvas" end
    if n:find("wall") or n:find("pillar") or n:find("column") or n:find("concrete") then return "Concrete" end
    if p.Material==Enum.Material.Concrete then return "Concrete" end
    if p.Material==Enum.Material.Metal then return "Steel" end
end
function W.fit(parent,family,cf,target)
    local template=A.family(family) if not template then return false end
    local native=template:GetAttribute("ArtSize") if typeof(native)~="Vector3" then return false end
    local factor=Vector3.new(target.X/native.X,target.Y/native.Y,target.Z/native.Z)
    local count=0 local model=U.make("Model",parent,{Name="Realism_"..family})
    for _,source in ipairs(template:GetChildren()) do if source:IsA("MeshPart") and typeof(source:GetAttribute("ArtBind"))=="CFrame" then
        local q=source:Clone() local bind=source:GetAttribute("ArtBind")
        q.Size=source.Size*factor q.CFrame=cf*CFrame.new(bind.Position*factor)*(bind-bind.Position)
        q.Anchored=true q.Massless=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q.Parent=model count=count+1
    end end
    if count==0 then model:Destroy() return false end
    model:SetAttribute("ArtRevision",6) return true
end
local replacements={ShippingCrate={"SupplyCrate",4.5,3.2,3.8},RadioCabinet={"FieldRadio",3.6,2.3,1.8},
    WornDeskTop={"OfficeDesk",8,3.2,4.1},ExtractionRadio={"FieldRadio",5,3.3,3},StarterAmmunition={"SupplyCrate",3.4,2,2.1},
    SupplyTin={"SupplyCrate",2.2,1.5,2.2},InstrumentHousing={"FieldRadio",2.5,2,1.5},WorkIslandCabinet={"Cabinet",6,2.6,3.2}}
function W.apply(parent,theme)
    local source=parent:GetDescendants() local service=game:GetService("MaterialService")
    for _,p in ipairs(source) do if p:IsA("BasePart") and not p:IsA("MeshPart") then
        if service:FindFirstChild("DS_Concrete") and not p.CanCollide and (p.Name=="WaterStain" or p.Name=="PlasterChip" or p.Name=="PlasterRepair" or p.Name=="FloorCrack") then p.Transparency=1 end
        local key=W.surface(p) local variant=key and service:FindFirstChild("DS_"..key)
        if variant then
            p.Material=materialNames[key] p.MaterialVariant=variant.Name
            p.Color=(key=="Steel" or key=="Rust" or key=="Canvas") and p.Color:Lerp(Color3.new(1,1,1),.55) or Color3.new(1,1,1)
        end
        local spec=replacements[p.Name]
        if spec then
            local extent=Vector3.new(spec[2],spec[3],spec[4]) local ratio=p.Name=="WornDeskTop" and p.Size.Z/4.1 or p.Size.Y/spec[3]
            extent=extent*ratio if p.Name=="WornDeskTop" then extent=Vector3.new(p.Size.X,extent.Y,extent.Z) end
            local foot=p.CFrame*CFrame.new(0,p.Name=="WornDeskTop" and -3*ratio or -p.Size.Y/2,0)
            if W.fit(parent,spec[1],foot,extent) then
                p.Transparency=1
                for _,q in ipairs(p:GetDescendants()) do if q:IsA("BasePart") and not q:FindFirstChildOfClass("SurfaceGui") then q.Transparency=1 end end
                -- Detail generators store companion pieces beside their base part.
                for _,q in ipairs(source) do if q:IsA("BasePart") and q~=p and q.Parent==p.Parent and not q:FindFirstChildOfClass("SurfaceGui") then
                    local localPos=foot:PointToObjectSpace(q.Position)
                    local related=(p.Name=="ShippingCrate" and q.Name:find("Crate")) or (p.Name=="WornDeskTop" and q.Name:find("Desk")) or (p.Name=="RadioCabinet" and q.Name:find("Radio"))
                    if related and math.abs(localPos.X)<extent.X*.6 and math.abs(localPos.Z)<extent.Z*.6 and localPos.Y>=0 and localPos.Y<extent.Y+.3 then q.Transparency=1 end
                end end
            end
        end
    end end
    parent:SetAttribute("GraphicsRevision",6)
end
function W.setDressing(map,layout)
    local s=map.scale
    -- New dressing lives on existing machine plinths, desks and ceiling mounts.
    for _,p in ipairs(map.model:GetDescendants()) do if p:IsA("BasePart") and not p:IsA("MeshPart") then
        if p.Name=="CeilingFixture" then
            if W.fit(map.model,"PendantLamp",p.CFrame*CFrame.new(0,-.4*s,0),Vector3.new(1.4,.8,1.1)*s) then p.Transparency=1 end
        elseif p.Name=="CagedWallLamp" then
            W.fit(map.model,"WallLamp",p.CFrame*CFrame.new(0,-.2*s,0),Vector3.new(1.2,.5,.5)*s)
        end
    end end
end
function W.lobby(parent,center)
    local placements={{"CoveredCar",Vector3.new(-101,0,-36),Vector3.new(7.4,5.2,16.8)},
        {"CoveredCar",Vector3.new(101,0,-36),Vector3.new(7.4,5.2,16.8)},
        {"Generator",Vector3.new(-104,0,-58),Vector3.new(5,3.8,4)},
        {"ToolCart",Vector3.new(106,0,18),Vector3.new(3.6,3.2,2.2)},
        {"StorageCart",Vector3.new(106,0,56),Vector3.new(3.5,4,3.5)},
        {"Barrel",Vector3.new(-104,0,18),Vector3.new(2.5,3.7,2.5)}}
    for _,spec in ipairs(placements) do
        local cf=CFrame.new(center+spec[2])
        if W.fit(parent,spec[1],cf,spec[3]) then
            U.make("Part",parent,{Name="ParkedEquipmentCollider",Size=spec[3],CFrame=cf*CFrame.new(0,spec[3].Y/2,0),
                Transparency=1,Anchored=true,CanCollide=true,CanQuery=true,CanTouch=false})
        end
    end
end
return W
