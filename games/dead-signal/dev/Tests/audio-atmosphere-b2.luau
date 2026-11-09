-- Actual Config/Effects. Test IDs are offline fixtures, never live mappings.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local setup=require('./Fixtures/audio-corrections-env')
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function config(universe)
    local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
    return luau.load(fs.readFile('Source/Runtime/shared/Config.lua'),{environment={game={GameId=universe or 10771141095},script={Parent={ControlSettings='c'}},require=function() return controls end},injectGlobals=true})()
end
local function ready(e,value)
    if type(value)=='string' and value:match('^rbxassetid://%d+$') then e.loaded[value]=true
    elseif type(value)=='table' then for _,v in pairs(value) do ready(e,v) end end
end
local function approved(e,key,n)
    local id='rbxassetid://'..tostring(800000+n)
    e.config.AudioAtmosphere.assets[key]={id=id,rightsCleared=true,creatorReviewed=true,listeningApproved=true,
        robloxApproved=true,permissions={[tostring(e.config.AudioAtmosphere.universeId)]=true}}
    e.loaded[id]=true;return e.config.AudioAtmosphere.assets[key]
end
local function scene(e,map,phase,extra)
    local value={map=map or 'Station',phase=phase or 'Exploration',status='Alive',active=true,runId=1,token='run1',
        atmosphereAnchors={r.Vector3.new(90,0,0),r.Vector3.new(-100,0,0)},intensity=.3}
    for k,v in pairs(extra or {}) do value[k]=v end;e.fx:audioState(value)
end
local function music(e)
    local rows={};for _,v in ipairs(e.fx.audio.voices) do if v.spec.music and not v.retired then rows[#rows+1]=v end end;return rows
end
-- No Batch1 bank is replaced, including production, unknown universes or upgrades.
local old=fs.readFile('Reviews/audio-atmosphere-b2/Config-before.txt')
local function original(id)
    local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
    return luau.load(old,{environment={game={GameId=id},script={Parent={ControlSettings='c'}},require=function() return controls end},injectGlobals=true})()
end
local function same(a,b)
    if type(a)~=type(b) then return false end;if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end;return true
end
for _,id in ipairs({10771141095,10770732078,0,1}) do
    local c=config(id);local before=original(id)
    check(same(c.SoundIds,before.SoundIds),'All accepted banks preserved in universe '..id)
    c.AudioAtmosphere=nil;check(same(c,before),'All non-B2 Config exactly preserved '..id)
end
-- New samples remain silent unless every review/permission flag is explicit.
do
    local e=setup(false,config());local key='Music.Station.Calm'
    e.fx:audioInit()
    check(e.fx:audioSample(e.config.AudioAtmosphere.assets[key].id,e.service)==nil,'Cold reviewed music remains silent while loading')
    local row=approved(e,key,1)
    for _,flag in ipairs({'rightsCleared','creatorReviewed','listeningApproved','robloxApproved'}) do
        row[flag]=false;check(not e.fx:audioAvailable(key),'Gate '..flag);row[flag]=true
    end
    row.permissions={['10770732078']=true};check(not e.fx:audioAvailable(key),'Wrong experience rejected')
    row.permissions={['10771141095']=true};row.id='not-an-asset';check(not e.fx:audioAvailable(key),'Invalid ID rejected')
    row.id='rbxassetid://800001';check(e.fx:audioAvailable(key),'Exact reviewed staging permission accepted')
    local inventory={};for _,entry in ipairs(e.fx:audioInventory()) do inventory[entry.key]=entry end
    check(inventory[key].configured and inventory['Atmosphere.Station.Radio'].configured,'Inventory resolves reviewed new slots and approved aliases')
    row.creatorReviewed=false
    for _,entry in ipairs(e.fx:audioInventory()) do if entry.key==key then check(not entry.configured,'Inventory never advertises an unapproved new asset') end end
    e.fx:audioDestroy()
end
-- Crossfades coalesce rapid authoritative changes; Low never stacks music voices.
for _,low in ipairs({false,true}) do
    local e=setup(low,config());ready(e,e.config.SoundIds)
    for n,key in ipairs({'Music.Station.Calm','Music.Station.Pressure','Music.Warden','Music.Extraction','Music.Lobby.Calm'}) do approved(e,key,n) end
    scene(e);e:advance(4)
    check(#music(e)==1 and music(e)[1].key=='Music.Station.Calm','Exploration starts calm score')
    local calm=music(e)[1];scene(e,'Station','Wave');e:advance(.2)
    check(calm.targetFade==0 and #music(e)<=(low and 1 or 2),'Bounded crossfade')
    scene(e,'Station','Wave',{boss=true});e:advance(.2);scene(e,'Station','Exfil')
    for _=1,70 do
        e:advance(.1);check(#music(e)<=(low and 1 or 2),'No transition voice pile-up')
        check(e.fx:audioDiagnostics().voices<=(low and 12 or 20),'Global native voice limit unchanged')
    end
    check(#music(e)==1 and music(e)[1].key=='Music.Extraction','Rapid changes settle to latest phase')
    scene(e,'Station','Intermission');e:advance(7)
    check(#music(e)==1 and music(e)[1].key=='Music.Station.Calm','Intermission returns to calm')
    local score=music(e)[1];local before=e.fx:audioGain(score)
    local reload=e.fx:sound('Weapon.Reload',nil,{weaponId='Kestrel',phase='mag-in',token='reload',firstPerson=true})
    check(reload and e.fx:audioGain(score)<before*.5,'Reload foreground ducks music')
    local warning=e.fx:sound('ShockCharge',nil,{sourceId='warning'})
    check(warning and warning.priority>=4 and e.fx.audio.duck==.28,'Critical warning retains priority and instant duck')
    check(e.fx:audioDiagnostics().peakBudget<=.820001,'Owned peak ceiling retained')
    scene(e,'Station','Results');e:advance(1)
    check(e.fx.audio.state.mode=='results' and not e.fx:sound('Zombie.Attack',r.Vector3.zero),'Results quiets stale threat cues')
    e.fx.settings.volume=0;e:advance(4)
    check(#music(e)==0,'Muted score releases native loops')
    for _,v in ipairs(e.fx.audio.voices) do check(v.sound.Volume==0,'Master mute includes beds') end
    e.fx.settings.volume=.65;scene(e);e:advance(4)
    check(#music(e)==1 and (e.fx.audio.scareEvents or 0)==0,'Unmute has no stale scare backlog')
    e.fx:audioReset('new-run');check(#e.fx.audio.voices==0 and e.fx.audio.nextScare==nil,'Run reset clears score/scare state')
    e.fx:audioDestroy();check(e:live('Sound')==0 and e:connections()==0,'Full cleanup')
end
-- Long simulated sessions validate pauses, positions and distinct map event pools.
for _,low in ipairs({false,true}) do
    local e=setup(low,config());ready(e,e.config.SoundIds);approved(e,'Music.Station.Calm',70)
    scene(e);e:advance(8);local calm=music(e)[1];check(calm~=nil,'Working score before a cold transition')
    local pressure=approved(e,'Music.Station.Pressure',71);e.loaded[pressure.id]=nil
    scene(e,'Station','Wave');e:advance(3)
    check(not calm.retired and calm.targetFade==1,'Cold incoming score does not cut working music')
    if e.pending[pressure.id] then e:complete(pressure.id:match('(%d+)$'),false) end
    e:advance(3);check(not calm.retired and calm.targetFade==1,'Denied score retains working fallback')
    e.loaded[pressure.id]=true;e:advance(40)
    check(#music(e)==1 and music(e)[1].key=='Music.Station.Pressure','A later successful load follows current state, not a stale event')
    e.fx:audioDestroy();check(e:live('Sound')==0,'Cold/failed transition teardown')
end
for _,newAudio in ipairs({false,true}) do for _,low in ipairs({false,true}) do for _,map in ipairs({'Station','Foundry','Frost','Lobby'}) do
    local e=setup(low,config());ready(e,e.config.SoundIds)
    if newAudio then ready(e,e.config.AudioAtmosphere.assets)
    else for _,entry in pairs(e.config.AudioAtmosphere.assets) do entry.robloxApproved=false end end
    scene(e,map)
    local seen={};local times={};local previous
    for _=1,1800 do
        e:advance(.5)
        local d=e.fx:audioDiagnostics();check(d.atmosphereVoices<=1,'One distant atmosphere voice maximum')
        for _,v in ipairs(e.fx.audio.voices) do if v.spec.atmosphere and not seen[v] then
            seen[v]=true;times[#times+1]=v.born
            check(v.priority==0 and v.custom and not v.sound.Looped,'Atmosphere is a quiet recording one-shot')
            check(v.position.Magnitude>=(low and 80 or 64),'Only distant authored positions')
            check(v.sound.PlaybackSpeed==1 and v.occluded,'Distant filter, no pitch imitation')
            if previous then check(v.key~=previous.key,'No repeated identical atmospheric event') end
            previous=v
        end end
    end
    if map=='Lobby' then check(#times==0,'Dispatch has intentional calm/no scare schedule')
    else
        check(#times>=3,(newAudio and 'Functioning reviewed new atmosphere ' or 'Functioning accepted-Batch1 atmosphere fallback ')..map)
        for n=2,#times do check(times[n]-times[n-1]>=35*(low and 1.5 or 1),'Natural minimum intervals') end
    end
    e.fx:audioDestroy();check(e:live('Sound')==0,'Long-session teardown '..map)
end end end
for _,extra in ipairs({{phase='Preparing',special=true},{phase='Wave',boss=true},{phase='Exfil'},{phase='Results'},{status='Eliminated'},{intensity=1}}) do
    local e=setup(false,config());ready(e,e.config.SoundIds);scene(e,'Station',extra.phase,extra);e:advance(180)
    check((e.fx.audio.scareEvents or 0)==0,'No random scares during warnings/end states/high pressure');e.fx:audioDestroy()
end
-- Dense actual-mixer traffic with the new music layer enabled. Native perceived
-- readability remains pending, but critical admission and owned budgets cannot
-- be displaced by a crowd's routine requests.
for _,low in ipairs({false,true}) do
    local e=setup(low,config());ready(e,e.config.SoundIds);approved(e,'Music.Station.Pressure',90)
    scene(e,'Station','Wave');e:advance(5)
    for tick=1,30 do
        e:advance(.2)
        for actor=1,40 do
            local p=r.Vector3.new(actor+2,0,0)
            e.fx:sound('Zombie.Groan',p,{sourceId='crowd:'..actor,routine=true})
            e.fx:sound('Zombie.Footstep',p,{sourceId='crowd:'..actor,material='Concrete'})
            e.fx:sound('Zombie.Attack',p,{sourceId='crowd:'..actor})
        end
        e.fx:sound('Weapon.Report',nil,{weaponId='Kestrel',firstPerson=true,sourceId='local-weapon'})
        if tick%5==0 then
            local warning=e.fx:sound('ShockCharge',r.Vector3.new(4,0,0),{sourceId='critical:'..tick})
            check(warning and warning.priority==4,'Crowded mixer preserves new critical warning admission')
        end
        local d=e.fx:audioDiagnostics()
        check(d.voices<=(low and 12 or 20) and d.musicVoices<=(low and 1 or 2),'Dense score plus SFX respects native voice caps')
        check(d.peakBudget<=.820001 and d.pending<=2,'Dense score plus SFX respects peak/load bounds')
    end
    e.fx:audioDestroy();check(e:live('Sound')==0,'Dense score/SFX session cleanup')
end
do
    local e=setup(false,config());ready(e,e.config.SoundIds);scene(e,'Station',nil,{atmosphereAnchors={r.Vector3.new(10,0,0)}});e:advance(180)
    check((e.fx.audio.scareEvents or 0)==0,'No fabricated close enemy direction');e.fx:audioDestroy()
end
-- Auditable inventory of real source/default banks, never the test IDs above.
local serde=require('@lune/serde');local inventories={nativePlaybackVerified=false,universes={}}
for _,universe in ipairs({10771141095,10770732078}) do
    local e=setup(false,config(universe));local rows=e.fx:audioInventory()
    for _,row in ipairs(rows) do row.available=e.fx:audioAvailable(row.key);row.defaultBank=e.fx:audioBank(row.key,{}) end
    inventories.universes[tostring(universe)]=rows;e.fx:audioDestroy()
end
if not fs.isDir('Validation') then fs.writeDir('Validation') end
fs.writeFile('Validation/Audio-B2-Event-Inventory.json',serde.encode('json',inventories,true))
print('Batch2 atmosphere assertions passed:',count)
