-- Only passive art owned by the experience creator is loaded; gameplay is local source.
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local A=require(RS.DeadSignal.ArtAssets)
local G={}
function G.valid(root)
    if not root or root:GetAttribute("ArtRevision")~=6 then return false end
    for _,name in ipairs({"Infected_1","Infected_2","Infected_3","Infected_4","Infected_5","Infected_6","Warden","Crawler","Hound"}) do
        if not A.complete(root:FindFirstChild(name)) then return false end
    end
    local parts=0
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("LuaSourceContainer") then return false end
        if p:IsA("MeshPart") then
            parts=parts+1
            if typeof(p:GetAttribute("ArtBind"))~="CFrame" then return false end
        end
    end
    return parts>50 and parts<1800
end
function G.materials(root)
    local folder=root and root:FindFirstChild("Materials") if not folder then return end
    local service=game:GetService("MaterialService")
    for _,source in ipairs(folder:GetChildren()) do if source:IsA("MaterialVariant") and source.Name:sub(1,3)=="DS_" then
        local old=service:FindFirstChild(source.Name) if old then old:Destroy() end
        source:Clone().Parent=service
    end end
    -- Anatomy variants are baked into MaterialService by Tools/AnatomyMaterials.
    -- Runtime scripts clone installed materials; they never write protected map properties.

end
function G.load()
    local installed=RS:FindFirstChild("DeadSignalArt")
    if G.valid(installed) then G.materials(installed) return true end
    if installed and installed:GetAttribute("ArtRevision")==6 then
        installed.Name="DeadSignalArtIncomplete_"..os.time() installed.Parent=game:GetService("ServerStorage") installed=nil
    end
    local id=tonumber(C.GraphicsBundleId) or 0 if id<=0 then return false end
    local ok,container=pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if not ok or not container then warn("Dead Signal: graphics bundle unavailable; using built-in art.") return false end
    -- Nothing is parented to a running service before scripts are removed and data validated.
    for _,q in ipairs(container:GetDescendants()) do if q:IsA("LuaSourceContainer") then q:Destroy() end end
    local root=container.Name=="DeadSignalArt" and container or container:FindFirstChild("DeadSignalArt",true)
    if not G.valid(root) then container:Destroy() warn("Dead Signal: graphics bundle is incomplete; using built-in art.") return false end
    root.Parent=nil
    if installed then installed:Destroy() end
    root.Parent=RS G.materials(root)
    if container~=root then container:Destroy() end
    return true
end
return G
