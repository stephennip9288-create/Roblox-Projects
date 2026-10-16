-- BUILD CANDIDATES ONLY. This script never publishes to Roblox.
-- Uses the committed complete staging place files as asset/world preservation baselines,
-- then overlays editable Source/Runtime scripts and generated staging PlaceConfig.
-- Output is not approved for deployment without Studio/mobile multiplayer acceptance.
local fs = require('@lune/fs')
local r = require('@lune/roblox')
local serde = require('@lune/serde')
local loader = require('../Tests/Support/RuntimeLoader')

local srcRoot = 'Source/Runtime/'
local configs = '../../../build/dead-signal-place-configs/'
local output = '../../../build/dead-signal-candidates/staging/'
local sourcePlaces = {
    {slug='dispatch', key='Lobby', role='Lobby', map='Station'},
    {slug='blackwater', key='Station', role='Match', map='Station'},
    {slug='cinderworks', key='Foundry', role='Match', map='Foundry'},
    {slug='whiteout', key='Frost', role='Match', map='Frost'},
}

local stageIds = serde.decode('json', fs.readFile(configs .. 'staging/PLACE-IDS.json'))
local liveIds = serde.decode('json', fs.readFile(configs .. 'production/PLACE-IDS.json'))
local expected = {
    shared = {'ReplicatedStorage', 'DeadSignal'},
    server = {'ServerScriptService', 'DeadSignalServer'},
    client = {'StarterPlayer', 'StarterPlayerScripts', 'DeadSignalClient'},
}

local function round(n)
    if n >= 0 then return math.floor(n * 1000 + .5) end
    return math.ceil(n * 1000 - .5)
end
local function vec(v)
    return table.concat({round(v.X),round(v.Y),round(v.Z)},',')
end
local function cf(v)
    local comps = {v:GetComponents()}
    for i, item in ipairs(comps) do comps[i] = round(item) end
    return table.concat(comps, ',')
end
local function safeProperty(instance, property)
    local ok, value = pcall(function() return instance[property] end)
    if not ok or value == nil then return '' end
    return tostring(value)
end

-- A conservative multiset of all non-code objects in the place, and selected
-- geometry/material properties. The baseline and round-tripped candidate must
-- retain EXACTLY the same signatures. Not a full Roblox binary fidelity proof:
-- unsupported serialized properties and engine-only behaviors remain untested.
local function inventory(dm)
    local result = {}
    local counts = {nonScripts=0, parts=0, meshes=0, appearances=0, terrain=0, scripts=0}
    for _, obj in ipairs(dm:GetDescendants()) do
        if obj:IsA('LuaSourceContainer') then
            counts.scripts += 1
        else
            local bits = {obj:GetFullName(),obj.ClassName}
            counts.nonScripts += 1
            if obj:IsA('BasePart') then
                counts.parts += 1
                table.insert(bits, vec(obj.Size))
                table.insert(bits, cf(obj.CFrame))
                table.insert(bits, safeProperty(obj,'Material'))
                table.insert(bits, safeProperty(obj,'Color'))
                table.insert(bits, safeProperty(obj,'Transparency'))
                table.insert(bits, safeProperty(obj,'CanCollide'))
                table.insert(bits, safeProperty(obj,'MeshId'))
                table.insert(bits, safeProperty(obj,'TextureID'))
                if obj:IsA('MeshPart') then counts.meshes += 1 end
            elseif obj:IsA('SurfaceAppearance') then
                counts.appearances += 1
                for _, prop in ipairs({'ColorMap','NormalMap','MetalnessMap','RoughnessMap'}) do
                    table.insert(bits,safeProperty(obj,prop))
                end
            elseif obj:IsA('Terrain') then
                counts.terrain += 1
            elseif obj:IsA('MaterialVariant') then
                for _, prop in ipairs({'BaseMaterial','ColorMap','NormalMap','MetalnessMap','RoughnessMap'}) do
                    table.insert(bits,safeProperty(obj,prop))
                end
            end
            local key = table.concat(bits,'|')
            result[key] = (result[key] or 0) + 1
        end
    end
    return result, counts
end
local function equalInventory(original, candidate, name)
    local diffs={}
    for k, count in pairs(original) do
        if candidate[k] ~= count then
            table.insert(diffs, 'Changed/removed '..tostring(count)..' vs '..tostring(candidate[k] or 0)..': '..string.sub(k,1,165))
        end
    end
    for k, count in pairs(candidate) do
        if original[k] == nil then
            table.insert(diffs, 'Unexpected '..tostring(count)..': '..string.sub(k,1,165))
        end
    end
    if #diffs > 0 then
        print('ASSET PARITY FAILED: '..name..' ('..#diffs..' differences)')
        for i=1,math.min(12,#diffs) do print(diffs[i]) end
    end
    assert(#diffs == 0, 'Non-script world/asset inventory mismatch: '..name)
end
local function serviceFolder(dm, group)
    local obj=dm
    for _, name in ipairs(expected[group]) do
        obj=obj:FindFirstChild(name)
        assert(obj,'Missing expected hierarchy '..group..'/'..name)
    end
    return obj
end
local function assertScripts(dm, config)
    local num=0
    for _, group in ipairs({'shared','server','client'}) do
        local folder=serviceFolder(dm,group)
        for _, filename in ipairs(fs.readDir(srcRoot..group)) do
            if string.sub(filename,-4)=='.lua' then
                local name=filename:gsub('%.server%.lua$',''):gsub('%.client%.lua$',''):gsub('%.lua$','')
                if name~='PlaceConfig' then
                    local mod=folder:FindFirstChild(name)
                    assert(mod and mod.Source == fs.readFile(srcRoot..group..'/'..filename), 'Source not preserved in built place: '..group..'/'..name)
                    num+=1
                end
            end
        end
    end
    assert(serviceFolder(dm,'shared'):FindFirstChild('PlaceConfig').Source == config,'Wrong/modified PlaceConfig in candidate')
    assert(num >= 60,'Unexpectedly few runtime source modules')
    return num
end
local function profileName(lua)
    return string.match(lua, 'ProfileStore%s*=%s*"([^"]+)"')
end

local reports={}
for _, place in ipairs(sourcePlaces) do
    local source='Places/DeadSignal-v1.8.0-'..place.key..'.rbxl'
    local originalBytes=fs.readFile(source)
    assert(string.sub(originalBytes,1,8)=='<roblox!', 'Expected full binary place backup: '..source)
    local dm=r.deserializePlace(originalBytes)
    local before, priorCounts=inventory(dm)
    local baselineConfig=serviceFolder(dm,'shared'):FindFirstChild('Config')
    assert(baselineConfig, 'Config module absent in source place')
    local profile=profileName(baselineConfig.Source)
    assert(profile and profile ~= '', 'Missing original data store setting')
    local developmentConfig=fs.readFile(srcRoot .. 'shared/Config.lua')
    assert(profileName(developmentConfig)==profile, 'Refusing to change ProfileStore from '..profile)

    local placeConfig=fs.readFile(configs..'staging/'..place.slug..'/PlaceConfig.lua')
    assert(string.find(placeConfig,'Role = "'..place.role..'"',1,true), 'Wrong staging role')
    assert(string.find(placeConfig,'Map = "'..place.map..'"',1,true), 'Wrong staging map')
    assert(string.find(placeConfig,tostring(stageIds.places.dispatch),1,true), 'Missing staging lobby ID')
    for map, slug in pairs({Station='blackwater',Foundry='cinderworks',Frost='whiteout'}) do
        assert(string.find(placeConfig,map..' = '..tostring(stageIds.places[slug]),1,true),'Missing staging map ID '..map)
    end
    for _,productionId in pairs(liveIds.places) do
        assert(not string.find(placeConfig,tostring(productionId),1,true),'PRODUCTION PLACE ID IN STAGING CONFIG')
    end

    local installed=loader.install(dm)
    installed.shared.PlaceConfig.Source=placeConfig
    local bytes=r.serializePlace(dm)
    assert(string.sub(bytes,1,8)=='<roblox!', 'Candidate binary header invalid')
    local reopened=r.deserializePlace(bytes)
    local after, currentCounts=inventory(reopened)
    equalInventory(before,after,place.slug)
    assert(currentCounts.terrain == priorCounts.terrain,'Terrain object count mismatch')
    assert(currentCounts.meshes == priorCounts.meshes,'Mesh count mismatch')
    assert(currentCounts.nonScripts == priorCounts.nonScripts,'World non-script count mismatch')
    local updated=assertScripts(reopened,placeConfig)
    local fname=output .. place.slug .. '.rbxl'
    fs.writeFile(fname,bytes)
    table.insert(reports,{
        place=place.slug,
        environment='staging',
        baselineBytes=#originalBytes,
        candidateBytes=#bytes,
        updatedScripts=updated,
        baseline=priorCounts,
        candidate=currentCounts,
        result='offline_inventory_pass',
        engineValidated=false,
        playable=false,
        safeToPublish=false,
        warning='Candidate only. Lune serialization is not a full property-level fidelity or Roblox Studio/phone test. Preserve the original complete-place assets and examine unsupported Roblox properties before any staged publish.',
    })
    print('OFFLINE CANDIDATE '..place.slug..': '..#bytes..' bytes, '..updated..' runtime sources; asset inventory MATCH')
end
fs.writeFile(output..'CANDIDATE-REPORT.json', serde.encode('json',reports,true))
print('Four staging candidate place files generated for review only. NO ROBLOX PUBLISH.')
