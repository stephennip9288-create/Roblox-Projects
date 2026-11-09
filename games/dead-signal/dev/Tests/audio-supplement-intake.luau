-- Executes actual Effects/Config with MAIN's proposed staging-only supplement.
-- Engine doubles cannot establish native moderation, decoding, permissions or quality.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox') local serde=require('@lune/serde')
local setup=require('./Fixtures/audio-corrections-env')
local root='Reviews/audio-supplement-intake-b1/'
local before=require('./Fixtures/audio-b2-config').original(fs.readFile('Source/Runtime/shared/Config.lua'))
local productionBlock=fs.readFile('Reviews/production-batch1/PRODUCTION-BINDINGS.luau.txt')
local pf,pl=string.find(before,productionBlock,1,true);assert(pf and pl,'Reviewed production block')
before=string.sub(before,1,pf-1)..string.sub(before,pl+1)
assert(before==fs.readFile('Reviews/production-batch1/STAGED-CONFIG.lua.txt'),'Accepted staging snapshot preserved')
local block=fs.readFile(root..'STAGING-BINDINGS.luau.txt')
local installedFirst,installedLast=string.find(before,block,1,true)
if installedFirst then
    before=string.sub(before,1,installedFirst-1)..string.sub(before,installedLast+1)
    assert(not string.find(before,block,1,true),'Supplemental block cannot be installed twice')
end
local marker='-- END DS-B1-001 84-ASSET PRIVATE STAGING AUDITION\n'
local first,last=string.find(before,marker,1,true);assert(first and last,'Exact baseline boundary')
assert(not string.find(before,marker,last+1,true),'Unique boundary')
local after=string.sub(before,1,last)..block..string.sub(before,last+1)
local approval=serde.decode('json',fs.readFile(root..'OWNER-APPROVALS.json'))
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function config(source,universe)
    local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
    return luau.load(source,{environment={game={GameId=universe},script={Parent={ControlSettings='controls'}},require=function() return controls end},injectGlobals=true})()
end
local newIds={}
for _,row in ipairs(approval.recordings) do
    check(row.owner_sample_listening_approved and row.owner_reported_staging_access_granted,'Owner confirms '..row.name)
    check(not row.experience_permission_verified and not row.native_gameplay_listening_passed and not row.activated,'Native/deployed acceptance remains pending '..row.name)
    newIds['rbxassetid://'..row.roblox_asset_id]=row.name
end
for _,universe in ipairs({10770732078,0,1,10771141096}) do
    check(same(config(before,universe),config(after,universe)),'Non-staging Config exactly preserved '..universe)
end
local old=config(before,10771141095);local c=config(after,10771141095)
for key,value in pairs(old) do if key~='SoundIds' then check(same(value,c[key]),'Non-audio Config preserved '..key) end end
local changed={['Board.Break']=true,['Enemy.Entry.Contact']=true}
for key,value in pairs(old.SoundIds) do if not changed[key] then check(same(value,c.SoundIds[key]),'Existing bank preserved '..key) end end
for key in pairs(c.SoundIds) do check(old.SoundIds[key]~=nil or key=='Board.Break','Only new bank is Board.Break') end
check(same(c.SoundIds['Enemy.Entry.Land'],old.SoundIds['Enemy.Entry.Land']),'Landing is independent')
check(c.SoundIds['Board.Stress']==nil and c.SoundIds['Board.Debris']==nil,'Untriggered components stay unbound')
local allowed={Board={['rbxassetid://121376790132442']=true,['rbxassetid://91133693743569']=true},['Enemy.Entry.Contact']={['rbxassetid://128395906553592']=true,['rbxassetid://126280091004313']=true}}
local function ready(e,value)
    if type(value)=='string' and value:match('^rbxassetid://%d+$') then e.loaded[value]=true
    elseif type(value)=='table' then for _,v in pairs(value) do ready(e,v) end end
end
for _,low in ipairs({false,true}) do
    local e=setup(low,config(after,10771141095));ready(e,e.config.SoundIds)
    local seen={}
    for key,bank in pairs(allowed) do
        for n=1,16 do
            local v=e.fx:sound(key,r.Vector3.new(8,0,0),{sourceId='window-'..n,token=key..n})
            check(v and v.custom and bank[v.sound.SoundId],'Correct prepared bank '..key)
            check(v.anchor and v.sound.RollOffMaxDistance<=115 and v.born==e.now,'Spatial/event timing retained '..key)
            check(v.sound.PlaybackSpeed==1 and not v.sound.Looped,'Natural-speed one-shot '..key)
            seen[v.sound.SoundId]=true
            v.sound.Ended:Fire();e.fx:audioUpdate(0);e:advance(.7)
        end
        for id in pairs(bank) do check(seen[id],'Both accepted variants exercised '..id) end
    end
    for _,name in ipairs({'wood_stress_3','wood_debris_1'}) do
        local id
        for asset,recording in pairs(newIds) do if recording==name then id=asset end end
        check(id and not seen[id],'No duplicate component playback '..name)
    end
    e.fx.settings.volume=0
    check(not e.fx:sound('Board',r.Vector3.zero,{sourceId='muted'}),'Master mute retained')
    e.fx:audioDestroy();check(e:live('Sound')==0,'No retained sounds after teardown')
end
do
    local e=setup(false,config(after,10771141095))
    check(not e.fx:sound('Board',r.Vector3.zero,{sourceId='cold'}) and e.plays==0,'Cold recording skips without a stock substitute')
    e.fx:audioDestroy();check(e:live('Sound')==0,'Cold-request teardown')
end
print('Supplemental audio candidate assertions passed:',count)
