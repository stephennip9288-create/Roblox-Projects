-- Real Effects, actual staging Config and actual WeaponModels reload timeline.
-- Sound/ContentProvider objects are offline doubles; native listening is pending.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox') local serde=require('@lune/serde')
local setup=require('./Fixtures/audio-corrections-env')
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function config(universe)
    local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
    return luau.load(fs.readFile('Source/Runtime/shared/Config.lua'),{environment={
        game={GameId=universe or 10771141095},script={Parent={ControlSettings='controls'}},require=function() return controls end,
    },injectGlobals=true})()
end
local function ready(e)
    local function add(value)
        if type(value)=='string' then if value:match('^rbxassetid://%d+$') then e.loaded[value]=true end
        elseif type(value)=='table' then for _,v in pairs(value) do add(v) end end
    end
    add(e.config.SoundIds)
end
local uploads=serde.decode('json',fs.readFile('Reviews/audio-quality-b11/OWNER-UPLOADS-UNVERIFIED.json'))
local function id(name) return 'rbxassetid://'..uploads[name].asset_id end
local banned={'swordslash.wav','swordlunge.wav','unsheath.wav','impact_water.mp3'}
local function safe(e)
    for _,n in ipairs(e.nodes) do if n.ClassName=='Sound' and n.Playing and not n.destroyed then
        for _,file in ipairs(banned) do check(n.SoundId~='rbxasset://sounds/'..file,'never play '..file) end
    end end
end
local function ended(e)
    for _,v in ipairs(table.clone(e.fx.audio.voices)) do v.sound.Ended:Fire();if v.farSound then v.farSound.Ended:Fire() end end
    e.fx:audioUpdate(0)
end
-- Negative reproduction uses the immutable pre-correction audition Effects.
do
    local before=fs.readFile('Tests/Fixtures/Effects-audio-corrections-before.txt')
    for _,item in ipairs({{'Reload','begin','unsheath.wav'},{'Equip','equip','unsheath.wav'},{'Board',nil,'impact_water.mp3'},{'Enemy.Entry.Contact',nil,'impact_water.mp3'},{'Enemy.Entry.Land',nil,'impact_water.mp3'}}) do
        local e=setup(false,config(),before)
        local v=e.fx:sound(item[1],nil,{weaponId='Kestrel',phase=item[2],token='before'})
        check(v and v.sound.SoundId=='rbxasset://sounds/'..item[3],'frozen source reproduces reported '..item[1])
        e.fx:audioDestroy()
    end
end
-- The actual acknowledgement prewarms but never invents a reload-start swish.
for _,key in ipairs({'Reload','Weapon.Reload'}) do
    local e=setup(false,config());local ok,reason=e.fx:sound(key,nil,{weaponId='Kestrel',phase='begin',token='reload'})
    check(ok and reason=='prepare' and e.plays==0 and #e.fx.audio.voices==0,'acknowledged start prepares only: '..key)
    local d=e.fx:audioDiagnostics();check(d.pending<=2 and d.queued<=32 and d.pending+d.queued>0,'preparation respects existing load limits')
    e.fx:audioCancel('reload');local plays=e.plays
    check(not e.fx:sound(key,nil,{weaponId='Kestrel',phase='begin',token='reload'}) and e.plays==plays,'cancelled start cannot prepare again')
    e.fx:audioDestroy();check(e:live('Sound')==0,'preparation teardown removes probes')
end
do
    local e=setup(false,config());e.fx:audioInit()
    for n=1,32 do e.fx:audioRequest('rbxassetid://'..(60000+n)) end
    e.fx:sound('Reload',nil,{weaponId='Kestrel',phase='begin',token='busy'})
    local d=e.fx:audioDiagnostics();check(d.pending<=2 and d.queued<=32 and e.plays==0,'saturated warmup remains bounded and silent')
    check(e.fx.audio.queued[id('mag_out')] or e.fx.audio.loading[id('mag_out')],'reload phase enters saturated queue')
    e.fx:audioDestroy()
end
-- Uploaded mechanical recordings are selected by real caller keys and phases.
local cases={
    {'Equip','equip','Kestrel','equip','Weapon.Equip'},{'Empty','empty','Kestrel','empty','Weapon.Empty'},
    {'Weapon.Reload','mag-out','Kestrel','mag_out','Weapon.Magazine'}, {'Weapon.Reload','mag-in','Kestrel','mag_in','Weapon.Magazine'},
    {'Weapon.Reload','action-open','Longwatch','bolt_open','Weapon.Bolt'}, {'Weapon.Reload','action-close','Longwatch','bolt_close','Weapon.Bolt'},
    {'Weapon.Reload','action-open','Trench','pump_open','Weapon.Pump'}, {'Weapon.Reload','action-close','Trench','pump_close','Weapon.Pump'},
    {'Weapon.Reload','action-open','Sable','pump_open','Weapon.Pump'}, {'Weapon.Reload','shell-in','Trench','shell_in','Weapon.Shell'},
    {'Weapon.Reload','feed-open','Anchor','feed_open','Weapon.Feed'}, {'Weapon.Reload','feed-close','Anchor','feed_close','Weapon.Feed'},
    {'Weapon.Reload','action-open','Cyclone','bolt_open','Weapon.Bolt'}, {'Weapon.Reload','action-close','Cyclone','bolt_close','Weapon.Bolt'},
}
for _,row in ipairs(cases) do
    local e=setup(false,config());ready(e)
    local v=e.fx:sound(row[1],r.Vector3.new(10,0,0),{weaponId=row[3],phase=row[2],token='accepted',sourceId='operator',firstPerson=true})
    check(v and v.key==row[5] and v.sound.SoundId==id(row[4]),row[3]..' '..row[2]..' exact uploaded mechanical asset')
    check(v.sound.PlaybackSpeed==1 and not v.anchor and v.born==e.now,'authored speed and acknowledged first-person onset')
    check(not e.fx:sound(row[1],nil,{weaponId=row[3],phase=row[2],token='accepted',sourceId='operator'}),'same phase replay deduplicated')
    safe(e);e.fx:audioDestroy()
end
-- A pistol/shotgun action cannot turn into an unsuitable generic reload/equip.
for _,row in ipairs({{'Breaker','action-open'},{'Breaker','action-close'},{'Vigil','action-open'},{'Vigil','action-close'},{'Vigil','shell-in'},{'Signal','cell-out'},{'Signal','cell-in'},{'Arc','charge'}}) do
    local e=setup(false,config());ready(e);e:approve('Reload',81001);e:approve('Equip',81002)
    local v,reason=e.fx:sound('Weapon.Reload',nil,{weaponId=row[1],phase=row[2],token='missing'})
    check(not v and reason=='asset' and e.plays==0,'missing appropriate mechanism is explicit: '..row[1]..' '..row[2])
    check(e.fx:audioDiagnostics().missing==1,'missing recording is diagnosable')
    e.fx:audioDestroy()
end
-- Cold, denied and empty physical banks never fall back to a splash or sword.
for _,low in ipairs({false,true}) do
    for _,key in ipairs({'Board','Enemy.Entry.Contact','Enemy.Entry.Land','Weapon.Hit','Hit','Grenade','ArmorBreak','Vent','Rifle','Weapon.Magazine'}) do
        local e=setup(low,config());local v=e.fx:sound(key,r.Vector3.new(5,0,0),{phase=key=='Weapon.Magazine' and 'mag-out' or nil,sourceId='physical'})
        check(not v and e.plays==0,'cold physical cue is never substituted: '..key)
        for asset in pairs(e.fx.audio.loading) do e:complete(asset:match('(%d+)$'),false) end
        e:advance(.7);e.fx:sound(key,r.Vector3.new(5,0,0),{sourceId='physical'})
        check(e.plays==0,'failed/empty physical cue stays quiet: '..key)
        safe(e);e.fx:audioDestroy();check(e:live('Part')==0 and e:live('Sound')==0,'unavailable event cleans its anchors/probes')
    end
end
-- A landing never borrows the wood-strike/entry-contact bank.
do
    local c=config();c.SoundIds['Enemy.Entry.Land']=nil
    local e=setup(false,c);ready(e)
    check(not e.fx:sound('Enemy.Entry.Land',r.Vector3.zero,{sourceId='entry'}),'missing land cannot borrow board/contact')
    local contact=e.fx:sound('Enemy.Entry.Contact',r.Vector3.zero,{sourceId='entry'})
    check(contact and contact.sound.SoundId==id('entry_contact_1') or contact and contact.sound.SoundId==id('entry_contact_2') or contact and contact.sound.SoundId==id('entry_contact_3'),'dedicated contact remains available')
    e.fx:audioDestroy()
end
for _,low in ipairs({false,true}) do
    local e=setup(low,config());ready(e)
    local family={Board={entry_contact_1=true,entry_contact_2=true,entry_contact_3=true},['Enemy.Entry.Contact']={entry_contact_1=true,entry_contact_2=true,entry_contact_3=true},['Enemy.Entry.Land']={entry_land_1=true,entry_land_2=true,entry_land_3=true}}
    for key,names in pairs(family) do
        local expected={};for name in pairs(names) do expected[id(name)]=true end
        local previous
        for n=1,9 do
            local v=e.fx:sound(key,r.Vector3.new(8,0,0),{sourceId='window',token='entry-'..n})
            check(v and expected[v.sound.SoundId] and v.sound.SoundId~=previous,'correct varied '..key..' recording')
            check(v.anchor and v.sound.RollOffMaxDistance<=115 and v.born==e.now,'physical contact/landing spatial and on-time')
            previous=v.sound.SoundId;ended(e);e:advance(.7)
        end
    end
    -- Fast acknowledged shell inserts keep onsets despite long old tails.
    for n=1,30 do
        local v=e.fx:sound('Weapon.Reload',nil,{weaponId='Trench',phase='shell-in',token='tube',sourceId='operator'})
        check(v and v.sound.SoundId==id('shell_in'),'accepted fast shell insert '..n)
        check(e.fx:audioDiagnostics().voices<=(low and 1 or 2),'shell tail pool is bounded')
        e:advance(.08)
    end
    e.fx:audioCancel('tube');check(not e.fx:sound('Weapon.Reload',nil,{weaponId='Trench',phase='shell-in',token='tube'}),'late cancelled shell rejected')
    e.fx:audioDestroy();check(e:live('Sound')==0 and e:live('Part')==0,'physical suite cleanup')
end
-- Actual immutable weapon presentation supplies all 20 per-weapon timelines.
do
    local c=config();local bp=luau.load(fs.readFile('Source/Runtime/shared/WeaponBlueprints.lua'))()
    local rules=luau.load(fs.readFile('Source/Runtime/shared/Rules.lua'))()
    local modules={Config=c,Rules=rules,WeaponBlueprints=bp,Util={},WeaponDetail={},ThirdPerson={},ArtAssets={}}
    local names={};for name in pairs(modules) do names[name]=name end
    local w=luau.load(fs.readFile('Source/Runtime/shared/WeaponModels.lua'),{environment={
        game={GetService=function() return {DeadSignal=names} end},require=function(name) return modules[name] end,
        Vector3=r.Vector3,CFrame=r.CFrame,Color3=r.Color3,Enum=r.Enum,
    },injectGlobals=true})()
    local total=0
    for weapon,def in pairs(c.Weapons) do
        total+=1
        local e=setup(false,config());ready(e);local missing=rules.weaponStats(def,3,{}).mag
        local stages=w.reloadEvents(weapon,0,1,missing);local previous=0
        for _,stage in ipairs(stages) do
            check(stage.at>=previous and stage.at>0 and stage.at<=1,'actual animation stage ordering: '..weapon)
            e:advance((stage.at-previous)*def.reload);previous=stage.at
            if stage.phase~='eject' then
                local voice,reason=e.fx:sound('Weapon.Reload',nil,{weaponId=weapon,phase=stage.phase,token='animation',sourceId='operator'})
                local absent=bp[weapon].reloadStyle=='cell' or bp[weapon].reloadStyle=='cylinder' or (bp[weapon].reloadStyle=='break' and stage.phase~='shell-in')
                check(absent and not voice and reason=='asset' or not absent and voice and voice.born==e.now,'phase mapping or explicit asset gap: '..weapon..' '..stage.phase)
                safe(e);ended(e)
            end
        end
        e.fx:audioDestroy()
    end
    check(total==20,'all existing weapons audited; no Batch 2 weapons')
end
-- Staging-only permission boundary remains unchanged; approvals are not inferred.
do
    local staging=config();local production=config(10770732078);local other=config(0)
    check(staging.AudioAudition and not production.AudioAudition and not other.AudioAudition,'audition remains staging-only')
    for _,name in ipairs({'Board','Weapon.Equip','Enemy.Entry.Contact','Enemy.Entry.Land'}) do
        check(staging.SoundIds[name] and not production.SoundIds[name] or staging.SoundIds[name] and production.SoundIds[name]=='','no uploaded bank in production: '..name)
    end
    local e=setup(false,production)
    check(not e.fx:sound('Board',r.Vector3.zero) and not e.fx:sound('Reload') and e.plays==0,'unconfigured universe has no prohibited physical fallback')
    local v=e.fx:sound('Hound.Charge',r.Vector3.zero)
    check(v and v.sound.Playing and v.priority==4,'critical warning remains immediate under missing assets')
    safe(e);e.fx:audioDestroy()
    for _,row in pairs(uploads) do for _,field in ipairs({'creator_reviewed','moderation_approved','sample_listening_approved','experience_permission_verified'}) do check(row[field]==false,'offline test cannot grant approval') end end
end
print('Batch 1 audio correction assertions passed:',count)
