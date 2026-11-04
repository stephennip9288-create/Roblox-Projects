-- Read-only native reader check. Never serializes or publishes a place.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local report={robloxEngineTested=false,serialized=false,places={}}
for _,place in ipairs({'dispatch','blackwater','cinderworks','whiteout'}) do
    local path='../../../build/dead-signal-lossless/staging/'..place..'.rbxl'
    local dm=r.deserializePlace(fs.readFile(path))
    local folders={shared=dm.ReplicatedStorage.DeadSignal,server=dm.ServerScriptService.DeadSignalServer,
        client=dm.StarterPlayer.StarterPlayerScripts.DeadSignalClient}
    local scripts=0
    for group,folder in pairs(folders) do
        for _,file in ipairs(fs.readDir('Source/Runtime/'..group)) do if file:sub(-4)=='.lua' then
            local name=file:gsub('%.server%.lua$',''):gsub('%.client%.lua$',''):gsub('%.lua$','')
            local source=name=='PlaceConfig' and fs.readFile('../../../build/dead-signal-place-configs/staging/'..place..'/PlaceConfig.lua')
                or fs.readFile('Source/Runtime/'..group..'/'..file)
            local object=assert(folder:FindFirstChild(name),'Missing source target '..name)
            assert(object.Source==source,'Native reader source differs: '..place..'/'..name)
            scripts+=1
        end end
    end
    assert(scripts==61,'Runtime inventory changed')
    local counts={}
    for _,object in ipairs(dm:GetDescendants()) do counts[object.ClassName]=(counts[object.ClassName] or 0)+1 end
    assert((counts.MeshPart or 0)>600 and (counts.SurfaceAppearance or 0)>600,'Native artwork inventory missing')
    assert(folders.shared.Config.Source:find('DeadSignal_Profile_v1',1,true),'Profile namespace changed')
    report.places[place]={scripts=scripts,meshParts=counts.MeshPart,surfaceAppearances=counts.SurfaceAppearance,
        materialVariants=counts.MaterialVariant,terrain=counts.Terrain,sourcesExactlyMatch=true}
    print('Native reader/source check passed:',place,scripts,'scripts')
end
fs.writeFile('Validation/Integration-Native-Reopen.json',serde.encode('json',report))
