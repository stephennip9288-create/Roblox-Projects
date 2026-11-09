-- Actual integrated Config/Effects: accurate owner approvals never unlock missing reviews.
-- Service doubles establish policy behavior, not Roblox moderation or playback.
local fs=require('@lune/fs') local luau=require('@lune/luau') local serde=require('@lune/serde')
local setup=require('./Fixtures/audio-corrections-env')
local intake=serde.decode('json',fs.readFile('Reviews/batch2-integration/AUDIO-INTAKE.json'))
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function config(id,text)
    local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
    return luau.load(text or fs.readFile('Source/Runtime/shared/Config.lua'),{environment={game={GameId=id},
        script={Parent={ControlSettings='controls'}},require=function() return controls end},injectGlobals=true})()
end
local function same(a,b)
    if type(a)~=type(b) then return false end;if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end;return true
end
check(#intake.recordings==16,'Sixteen unique owner-supplied mappings retained')
for _,universe in ipairs({10771141095,10770732078,0,1}) do
    local c=config(universe)
    local before=config(universe,fs.readFile('Reviews/batch2-integration/Baseline/shared/Config.lua.txt'))
    check(same(c.SoundIds,before.SoundIds),'Every accepted Batch1 bank preserved '..universe)
    local e=setup(false,c);local seen={};local mapped=0
    for _ in pairs(c.AudioAtmosphere.assets) do mapped+=1 end
    check(mapped==16,'No extra or missing live-ID mappings')
    for _,row in ipairs(intake.recordings) do
        local bank=c.AudioAtmosphere.assets[row.event]
        check(not seen[row.event],'Unique event');seen[row.event]=true
        check(bank.id=='rbxassetid://'..row.roblox_asset_id,'Exact owner ID for '..row.event)
        check(bank.listeningApproved==true,'Existing owner listening acceptance carried forward')
        check(bank.permissions['10771141095']==true and bank.permissions['10770732078']==true,'Both independently exported grants retained')
        check(bank.rightsCleared==true and bank.creatorReviewed==true and bank.robloxApproved==false,'Reviewed originals and owner rights retained; Roblox approval remains unresolved')
        e.loaded[bank.id]=true
        check(not e.fx:audioAvailable(row.event),'Even a loaded asset cannot bypass unresolved review gates')
    end
    e.fx:audioDestroy()
    c.AudioAtmosphere=nil
    check(same(c,before),'All non-Batch2 Config and profile settings exactly retained')
end
check(intake.owner_listening_reconfirmation_required==false,'Do not repeat completed listening acceptance')
count+=require('./Fixtures/audio-b2-native-probe-test')()
print('Batch 2 integrated intake assertions passed:',count)
