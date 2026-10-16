-- OFFLINE AUTHORING ONLY. Material map/BaseMaterial writes require Studio/Plugin privileges.
local r=require('@lune/roblox')
local A={}
function A.install(dm)
    local root=dm.ReplicatedStorage.DeadSignalArt local service=dm.MaterialService
    local function make(name,family,partName,base,tile)
        local source=root:FindFirstChild(family):FindFirstChild(partName) assert(source,'Missing source for '..name)
        local surface=source:FindFirstChildOfClass('SurfaceAppearance')
        local old=service:FindFirstChild(name) if old then old:Destroy() end
        local v=r.Instance.new('MaterialVariant');v.Name=name;v.BaseMaterial=base;v.StudsPerTile=tile
        if surface then
            for _,property in ipairs({'ColorMapContent','NormalMapContent','RoughnessMapContent','MetalnessMapContent'}) do
                local ok,value=pcall(function() return surface[property] end) if ok then v[property]=value end
            end
        else v.ColorMapContent=source.TextureContent end
        v:SetAttribute('AuthoredRevision',8) v.Parent=service
    end
    make('DS_Canine','Hound','DSG_Hound_Head_239',r.Enum.Material.Fabric,1.6)
    make('DS_InfectedSkin','Infected_1','DSG_Infected_1_Head_001',r.Enum.Material.SmoothPlastic,.85)
end
return A
