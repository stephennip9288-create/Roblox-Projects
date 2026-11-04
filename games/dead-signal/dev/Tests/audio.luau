-- Execute the exact inline candidate with deterministic sound/clock/signal doubles.
-- This does NOT establish native mixing, asset permissions, latency or device FPS.
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local r=require('@lune/roblox')
local source=fs.readFile('Source/Runtime/client/Effects.lua')
local candidate=source
if not source:find('function FX:audioInit()',1,true) then
    local proposal=fs.readFile('Reviews/audio-immersion/Effects-audio.luau')
    local first=assert(source:find('local stock=',1,true))
    local last=assert(source:find('function FX:part(',1,true))
    candidate=source:sub(1,first-1)..proposal..'\n'..source:sub(last)
    candidate=candidate:gsub('function FX:animate%(dt%)\n','function FX:animate(dt)\n    self:audioUpdate(dt)\n',1)
end
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function near(a,b,message) check(math.abs(a-b)<.00001,message) end
local function signal()
    local s={entries={}}
    function s:Connect(fn)
        local entry={fn=fn,active=true};self.entries[#self.entries+1]=entry
        return {Disconnect=function() entry.active=false end}
    end
    function s:Fire()
        for _,entry in ipairs(table.clone(self.entries)) do if entry.active then entry.fn() end end
    end
    return s
end
local function setup(low)
    local env={now=100,nodes={},loaded={},plays=0,fail=false}
    local function node(class,parent,props)
        local p={ClassName=class,Parent=parent,children={},Destroying=signal(),Ended=signal()}
        local obj={}
        local methods={}
        function methods:Destroy()
            if p.destroyed then return end
            p.Destroying:Fire();p.destroyed=true;p.Parent=nil
            for _,child in ipairs(p.children) do child:Destroy() end
        end
        function methods:Play() if env.fail then error('simulated denied playback') end;p.Playing=true;env.plays+=1 end
        function methods:Stop() p.Playing=false end
        function methods:GetChildren() return p.children end
        function methods:FindFirstChild() return nil end
        setmetatable(obj,{__index=function(_,key) return methods[key] or p[key] end,__newindex=function(_,key,value)
            p[key]=value
            if key=='SoundId' then p.IsLoaded=value:sub(1,11)=='rbxasset://' or env.loaded[value]==true end
        end})
        for key,value in pairs(props or {}) do obj[key]=value end
        if parent and parent.children then parent.children[#parent.children+1]=obj end
        env.nodes[#env.nodes+1]=obj
        return obj
    end
    local settings={volume=.65,lowEffects=low==true}
    local config={DefaultSettings=settings,SoundIds={},Evolution={audio={}},Weapons={Kestrel={class='Pistol'},Trench={class='Shotgun'},Anchor={class='Heavy'}}}
    local util={copy=table.clone,make=node}
    local soundService=node('SoundService')
    local world={CurrentCamera={CFrame=r.CFrame.new(0,0,0)},FindFirstChild=function(_,name) return name=='DeadSignalMap' and env.map or nil end}
    local rs={DeadSignal={Config='Config',Util='Util',NPCPose='NPCPose'}}
    local services={ReplicatedStorage=rs,SoundService=soundService,TweenService={},Debris={AddItem=function() end}}
    local clock=table.clone(os);clock.clock=function() return env.now end
    local FX=luau.load(candidate,{debugName='ProposedEffects',environment={
        game={GetService=function(_,name) return services[name] end},workspace=world,
        require=function(key) if key=='Config' then return config elseif key=='Util' then return util else return {} end end,
        Vector3=r.Vector3,Enum=r.Enum,os=clock,typeof=typeof,
    },injectGlobals=true})()
    env.fx=FX.new();env.config=config;env.world=world;env.service=soundService;env.FX=FX
    function env:advance(seconds)
        local steps=math.max(1,math.ceil(seconds/.1))
        for _=1,steps do self.now+=seconds/steps;self.fx:audioUpdate(seconds/steps) end
    end
    function env:approve(key,id)
        -- IDs here are arbitrary test fixtures; no network/Roblox asset lookup occurs.
        self.config.SoundIds[key]=tostring(id);self.loaded['rbxassetid://'..tostring(id)]=true
    end
    function env:live(class)
        local total=0
        for _,n in ipairs(self.nodes) do if n.Parent and not n.destroyed and (not class or n.ClassName==class) then total+=1 end end
        return total
    end
    function env:connections()
        local total=0
        for _,n in ipairs(self.nodes) do for _,entry in ipairs(n.Ended.entries) do if entry.active then total+=1 end end end
        return total
    end
    return env
end
local V=r.Vector3
-- Legacy signatures remain valid. Inappropriate physical stock is intentionally silent.
local legacy={'Click','Equip','Board','Attack','ShockCharge','Reload','Empty','Hit','Kill','Down','Revive','Grenade','Round','Power','Box','Perk','Victory','Enemy','Pistol','Rifle','SMG','Shotgun','Heavy','Sniper','Energy','Howl','Redline','IronMarch','Volatile','Stalker','ArmorBreak','Vent'}
local needsRecording={Equip=true,Board=true,Reload=true,Empty=true,Hit=true,Grenade=true,Pistol=true,Rifle=true,SMG=true,Shotgun=true,Heavy=true,Sniper=true,Energy=true,IronMarch=true,ArmorBreak=true,Vent=true}
for _,key in ipairs(legacy) do
    local e=setup();local v=e.fx:sound(key)
    if needsRecording[key] then
        check(not v,'missing physical asset is explicit '..key)
        check(e.plays==0 and e:live('Part')==0,'no incorrect replacement '..key)
        e:approve(key,70001);v=e.fx:sound(key)
        check(v and v.custom and v.sound.PlaybackSpeed==1,'legacy caller uses an authored recording '..key)
    else
        check(v and v.sound.Playing,'legacy sound '..key)
        check(v.sound.SoundId:sub(1,11)=='rbxasset://','bundled attention/UI fallback '..key)
        check(v.sound.Volume>0 and v.sound.Volume<=.65,'bounded gain '..key)
    end
    e.fx:audioDestroy();check(e:live('Sound')==0 and e:connections()==0,'cleanup '..key)
end
do
    local e=setup();local fx=e.fx
    check(not fx:sound('unknown'),'unknown event ignored')
    check(not fx:sound('Hit',{}),'non-vector rejected')
    check(not fx:sound('Hit',V.new(0/0,0,0)),'nonfinite position rejected')
    check(not fx:sound('Weapon.Fire',nil,{class='not a weapon'}),'invalid class rejected')
    check(not fx:sound('Rifle',V.new(1000,0,0)),'distance culls before source allocation')
    check(e:live('Sound')==0 and e:live('Part')==0,'rejections allocate no sounds/anchors')
    local v=fx:sound('Hound.Charge',V.new(10,0,0),{source='k9-1'})
    check(v.anchor and v.sound.Parent==v.anchor,'world cue is spatial')
    check(not v.anchor.CanQuery and not v.anchor.CanCollide and not v.anchor.CanTouch,'source never affects combat/pathing')
    check(v.sound.RollOffMode==r.Enum.RollOffMode.InverseTapered and v.sound.RollOffMinDistance==8,'explicit rolloff')
    check(not fx:sound('Hound.Charge',V.new(10,0,0),{source='k9-1'}),'same source cooldown')
    check(fx:sound('Hound.Charge',V.new(-10,0,0),{source='k9-2'}),'independent warning direction not globally debounced')
    e:advance(.41);check(fx:sound('Hound.Charge',V.new(10,0,0),{source='k9-1'}),'source can warn again after cooldown')
end
do
    local e=setup();e:approve('Howl',101);e.config.Evolution.audio.Howl=''
    local v=e.fx:sound('Howl')
    check(v.sound.SoundId=='rbxassetid://101','blank evolution slot allows configured SoundIds fallback')
    check(v.sound.PlaybackSpeed==1,'creator recording retains its authored pitch')
    e.fx:audioReset('assets');e.config.SoundIds.Howl='https://unapproved.test/audio';v=e.fx:sound('Howl')
    check(v.sound.SoundId=='rbxasset://sounds/action_get_up.mp3','malformed warning asset preserves generic attention cue')
    e.fx:audioReset('zero');e.config.SoundIds.Howl='000';v=e.fx:sound('Howl')
    check(v.sound.SoundId=='rbxasset://sounds/action_get_up.mp3','zero ID is not treated as custom')
    e.fx:audioReset('variation');e:approve('Reload',102);e:approve('Reload',103);e.config.SoundIds.Reload={'102','103'}
    local seen={}
    for i=1,6 do local voice=e.fx:sound('Reload',nil,{source=i});seen[voice.sound.SoundId]=true;e:advance(3.1) end
    check(seen['rbxassetid://102'] and seen['rbxassetid://103'],'bounded asset variation')
    e.fx:audioReset('far');e:approve('Rifle.Far',104)
    v=e.fx:sound('Rifle',V.new(90,0,0))
    check(v.sound.SoundId=='rbxassetid://104' and v.sound.PlaybackSpeed<1.65,'optional far report uses same event, no extra remote')
    e.fx:audioReset('critical');e.config.SoundIds['Stalker.Warning']='105'
    v=e.fx:sound('Stalker.Warning')
    check(v.sound.SoundId=='rbxasset://sounds/uuhhh.mp3' and v.sound.Playing,'unloaded custom warning falls back immediately')
    check(e.fx.audio.failed['rbxassetid://105']>e.now,'failed custom warning gets retry backoff')
    e.fx:audioReset('material');e:approve('Player.Footstep',106);e:approve('Player.Footstep.Metal',107)
    v=e.fx:sound('Player.Footstep',V.zero,{material='Metal'})
    check(v.sound.SoundId=='rbxassetid://107','material-specific recording preferred over generic footstep')
end
-- Forty-NPC full-density overlap at both quality levels, with no delayed warning queue.
for _,low in ipairs({false,true}) do
    local e=setup(low);local fx=e.fx;local max=low and 12 or 20;local reserve=low and 6 or 8
    e:approve('Zombie.Groan',71001);e:approve('Rifle',71002);e:approve('Reload',71003)
    for i=1,40 do fx:sound('Zombie.Groan',V.new(i,0,0),{source='z'..i}) end
    for i=1,40 do fx:sound('Rifle',V.new(-i,0,0),{source='p'..i}) end
    for i=1,20 do fx:sound('Reload',nil,{source=i}) end
    check(#fx.audio.voices<=max-reserve,'routine voices preserve reserved threat capacity')
    local routine=fx.audio.voices[1];local oldGain=routine.sound.Volume
    local first=fx:sound('Warden.Warning',V.new(30,0,0),{source='warden'})
    check(first and first.born==e.now and first.sound.Playing,'critical warning starts immediately')
    check(routine.sound.Volume<oldGain,'urgent cue immediately ducks routine mix')
    for i=1,40 do fx:sound('Elite.VolatileFuse',V.new(60+i,0,0),{source='hazard'..i}) end
    check(#fx.audio.voices<=max and e:live('Sound')<=max and e:live('Part')<=max,'hard voice/anchor budget at 40 NPCs')
    local close=fx:sound('Stalker.Warning',V.new(2,0,0),{source='closest'})
    check(close and close.sound.Playing,'nearest urgent warning replaces more distant/lower priority voice')
    check(close.priority==4,'catalog priority retained')
    for _,v in ipairs(fx.audio.voices) do check(v.sound.Volume<=.65,'headroom cap during overlap') end
    e:advance(4.1)
    check(#fx.audio.voices==0 and e:live('Sound')==0 and e:connections()==0,'all crowded-wave sources and connections end')
    e:advance(1);check(fx.audio.duck>.9,'mix recovers after threats')
end
do
    local e=setup();local fx=e.fx
    for i=1,900 do
        local v=fx:sound('Hound.Charge',V.zero,{source='burst-'..i})
        check(v~=false,'instant-ended cues admit without delayed queue')
        v.sound.Ended:Fire();fx:audioUpdate(0)
    end
    check(fx.audio.lastCount==256,'same-tick distinct-source burst reaches bounded cache cap')
    check(e:connections()==0 and e:live('Sound')==0,'distinct-source burst has no retained sounds')
    e:advance(1.1);check(fx.audio.lastCount==0,'bounded burst cache expires')
end
do
    local e=setup();local fx=e.fx
    e:approve('Pistol',72001);e:approve('Rifle',72002);e:approve('Zombie.Groan',72003)
    local ui=fx:sound('Click');local weapon=fx:sound('Weapon.Fire',V.new(12,0,0),{class='Pistol',priority=99,gain=100})
    check(ui.sound.Parent==fx.audio.flat and ui.sound.Parent.Parent==e.service,'UI audio owned under SoundService')
    check(weapon.priority==2 and weapon.gain<=.35,'caller cannot raise catalog priority or gain')
    e:advance(.11);check(not weapon.retired,'authored report has a natural tail');weapon.sound.Ended:Fire();fx:audioUpdate(0)
    fx:audioMix({ui=.4,weapons=0,unknown=999})
    local gain=ui.sound.Volume
    fx.settings={volume=.2,lowEffects=false};fx:audioUpdate(0)
    near(ui.sound.Volume,gain*(.2/.65),'replacing saved settings updates playing voices')
    fx.settings.volume=0;fx:audioUpdate(0);check(ui.sound.Volume==0,'live master mute')
    local plays=e.plays;check(not fx:sound('Hit') and e.plays==plays,'mute never queues new sound')
    fx.settings.volume=.8;fx:audioUpdate(0);check(ui.sound.Volume>0,'unmute restores valid ongoing cue')
    check(not fx:sound('Rifle'),'transient category mute')
    fx:audioMix({weapons=1});check(fx:sound('Rifle'),'category unmute')
    local filtered=fx:sound('Zombie.Groan',V.new(8,0,0),{occluded=true})
    check(#filtered.sound.children==1 and filtered.sound.children[1].HighGain==-7,'explicit routine occlusion approximation')
    local warning=fx:sound('Hound.Charge',V.new(8,0,0),{occluded=true})
    check(#warning.sound.children==0,'critical warning never low-pass filtered')
    e.world.CurrentCamera.CFrame=r.CFrame.new(1000,0,0);fx:audioUpdate(0)
    check(filtered.retired and warning.retired,'moving listener retires out-of-range spatial sources')
end
do
    local e=setup();local fx=e.fx;e:approve('Weapon.Reload',73001);e:approve('Weapon.Magazine',73002)
    local one=fx:sound('Weapon.Reload',nil,{token='reload-1'})
    local two=fx:sound('Weapon.Magazine',nil,{token='reload-2'})
    fx:audioCancel('reload-1');check(one.retired and not two.retired,'reload/swap cancellation scoped to acknowledged lifecycle')
    check(not fx:sound('Weapon.Reload',nil,{token='reload-1'}),'cancel invalidates token for late acknowledged-phase callback')
    check(fx:sound('Weapon.Reload',nil,{token='reload-3'}),'fresh acknowledged reload token is independent')
    two.sound.Ended:Fire();check(two.retired,'Ended cleans immediately')
    fx:audioUpdate(0);check(e:connections()==#fx.audio.voices,'Ended connection removed')
    fx:audioReset('new-character');check(#fx.audio.voices==0 and fx.audio.lastCount==0 and e:connections()==0,'respawn/session reset cleans voice/cooldown state')
    fx:sound('Round');fx.folder:Destroy()
    check(fx.audio.destroyed and e:live('Sound')==0 and e:connections()==0,'owner folder teardown also cleans nonspatial audio')
    check(not fx:sound('Round'),'destroyed owner cannot be revived by late cue')
    fx:audioDestroy();check(e:live('Sound')==0,'repeat teardown safe')
end
-- Realistic assets are intentionally silent until creator-approved IDs are configured.
do
    local e=setup();local fx=e.fx
    fx:audioState({map='Station',token='none',active=true,indoors=false});e:advance(30)
    check(e.plays==0 and e:live('Sound')==0,'no fabricated world loops or background transmission')
    check(not fx:sound('Player.Footstep',V.zero,{material='Metal'}),'default character footsteps not duplicated by empty slots')
    for i=1,20 do fx:audioState({map='Station',token='missing-'..i,active=true}) end
    check(e:live('Sound')==0,'repeated unavailable map transitions remain silent and bounded')
end
local maps={Station={'wind','radio','power'},Foundry={'machinery','furnace','vent'},Frost={'wind','relay','structure'}}
do
    local e=setup();local fx=e.fx;local id=201
    for map,names in pairs(maps) do for _,name in ipairs(names) do e:approve('World.'..map..'.'..name,id);id+=1 end end
    for n=1,60 do
        local map=({'Station','Foundry','Frost'})[(n-1)%3+1]
        fx:audioState({map=map,token='run-'..n,room='Room '..n,active=true,indoors=n%2==0,intensity=.6})
        e:advance(1)
        check(#fx.audio.voices==3 and e:live('Sound')==3,'map beds bounded through travel '..n)
        for _,v in ipairs(fx.audio.voices) do check(v.key:find('World.'..map..'.',1,true)==1,'distinct map key '..n) end
    end
    local wind=fx.audio.world['World.Frost.wind'];local old=wind.sound.Volume
    fx:audioState({map='Frost',token='run-60',active=true,indoors=false,intensity=.6});e:advance(.1)
    check(wind.sound.Volume>old,'indoor/outdoor transition fades exterior bed')
    local after=wind.sound.Volume;e:advance(1)
    check(wind.sound.Volume>after and wind.fade==1,'zone transition converges without fade oscillation')
    fx.settings.lowEffects=true;e:advance(1.2)
    check(#fx.audio.voices==2,'low effects reduces ambient beds')
    fx.settings.lowEffects=false;e:advance(1.2)
    check(#fx.audio.voices==3,'restored quality resumes missing bed')
    fx.settings.volume=0;e:advance(.1)
    for _,v in ipairs(fx.audio.voices) do check(v.sound.Volume==0,'loop mute') end
    fx:audioState({map='Frost',token='run-60',active=false});check(#fx.audio.voices==0,'results/travel/elimination clears loops')
    fx:audioState({map='Station',token='respawn',active=true});fx.settings.volume=.65;e:advance(1)
    check(#fx.audio.voices==3,'clean restart after respawn')
    fx:audioDestroy();check(e:live('Sound')==0 and e:live('Part')==0 and e:connections()==0,'final world teardown')
end
do
    local e=setup();local fx=e.fx
    e:approve('World.Station.wind',301);e:approve('World.Station.contact',302)
    fx:audioState({map='Station',token='landmark',active=true,anchors={}});e:advance(1)
    check(e:live('Sound')==1 and e:live('Part')==0,'no distant cue without authored landmark')
    fx:audioState({map='Station',token='landmark2',active=true,anchors={['World.Station.wind']=V.new(20,0,0),['World.Station.contact']=V.new(-40,0,0)}})
    e:advance(.1)
    check(e:live('Part')==2,'authored world bed and distant activity are spatial')
    fx:audioState({map='Station',token='landmark2',active=true,anchors={['World.Station.wind']=V.new(30,0,0)}})
    e:advance(.1)
    check(fx.audio.world['World.Station.wind'].anchor.Position==V.new(30,0,0),'room/landmark source updates safely')
end
do
    local e=setup();local fx=e.fx
    e.config.SoundIds['World.Frost.wind']='401' -- unloaded/denied, no fallback invented
    fx:audioState({map='Frost',token='denied',active=true});e:advance(6)
    check(e:live('Sound')==0 and e:live('Part')==0,'unavailable custom loop retires after load deadline')
    local nodes=#e.nodes;e:advance(20)
    check(#e.nodes==nodes,'permission failure backoff prevents per-second allocation churn')
    fx:audioDestroy();check(e:connections()==0,'failed load leaves no connection')
end
do
    local e=setup();local fx=e.fx;e.fail=true
    check(not fx:sound('Hound.Charge',V.zero),'playback failure returns safely')
    fx:audioUpdate(0);check(e:live('Sound')==0 and e:live('Part')==0 and e:connections()==0,'playback failure cleanup')
end
do
    local e=setup();local fx=e.fx;e:approve('Zombie.Entry',74001)
    -- Long-lived loops keep cooldown dictionary churn independent of TTL cleanup.
    for i=1,1500 do
        fx:sound('Zombie.Entry',nil,{source='unique-'..i,token='t'..i})
        e:advance(.11)
        check(fx.audio.lastCount<=256,'dedup cache remains bounded')
        check(#fx.audio.voices<=20 and e:live('Sound')<=20,'repeated wave transition budget')
    end
    e:advance(4);check(fx.audio.lastCount==0 and e:connections()==0,'cooldown cache and sources eventually empty')
    for i=1,40 do fx:sound('Hound.Charge',V.new(i+20,0,0),{source=i}) end
    fx.settings.lowEffects=true;fx:audioUpdate(0)
    check(#fx.audio.voices<=12,'live quality switch enforces smaller hard limit')
    for _,v in ipairs(fx.audio.voices) do check(v.priority==4,'quality switch preserves threats first') end
end
do
    local e=setup();local fx=e.fx
    for i,key in ipairs({'Pistol','Shotgun','Weapon.Magazine','Weapon.Pump','Weapon.Shell','Weapon.Cell','Weapon.Charge','Weapon.Feed','Weapon.Equip','Weapon.Empty','Enemy.Armor.Break'}) do e:approve(key,75000+i) end
    fx:audioEvent('World.Zone',{map='Station',runId=10,room=2,active=true})
    check(fx.audio.runId=='10' and fx.audio.state.room=='2','canonical zone normalizes optional run/room facts')
    local voice=fx:audioEvent('Enemy.Charge.Warn',{position=V.new(8,0,0),sourceId='k9',runId=10,eventId='charge-1',duration=.65})
    check(voice and voice.source=='k9' and voice.epoch==fx.audio.epoch and voice.priority==4,'canonical warning context and epoch')
    near(voice.expires-e.now,.65,'warning duration bounded to advertised cue lifetime')
    check(not fx:audioEvent('Enemy.Charge.Warn',{position=V.new(9,0,0),sourceId='k9',runId=10}),'sourceId alias deduplicates repeated warning')
    check(not fx:audioEvent('Combat.Hit',{runId=9}),'prior-run confirmation rejected after zone state')
    local oldEpoch=fx.audio.epoch
    fx:audioState({map='Station',runId=11,active=true})
    check(fx.audio.epoch>oldEpoch and voice.retired,'new run epoch cleans old warning immediately')
    local report=fx:audioEvent('Weapon.Report',{weaponId='Kestrel',position=V.new(4,0,0),firstPerson=true,runId=11,tier=1})
    check(report and report.key=='Pistol' and not report.anchor,'canonical weapon ID and first-person routing')
    e:advance(.2)
    local remote=fx:sound('Weapon.Report',nil,{weapon='Trench',position=V.new(12,0,0),sourceId=2,runId=11})
    check(remote and remote.key=='Shotgun' and remote.anchor,'legacy weapon alias and third-context position')
    local phases={'mag-out','mag-in','action-open','action-close','shell-in','cell-out','cell-in','charge','feed-open','feed-close','equip','fire','empty'}
    for _,phase in ipairs(phases) do
        fx:audioReset('phase-'..phase)
        local result=fx:audioEvent('Weapon.Mechanism',{weaponId='Trench',phase=phase,action='reload',token='accepted-'..phase,firstPerson=true})
        check(result and result.sound.Playing,'approved #24 stage '..phase)
        if phase=='action-open' or phase=='action-close' then check(result.key=='Weapon.Pump','shotgun action uses pump') end
    end
    check(not fx:audioEvent('Weapon.Mechanism',{phase='unapproved'}),'unknown weapon phase stays silent')
    fx:audioEvent('Weapon.Mechanism',{phase='cancel',token='late'})
    check(not fx:audioEvent('Weapon.Mechanism',{phase='mag-in',token='late'}),'cancel stage invalidates delayed foley')
    for i=1,400 do fx:audioCancel('cancel-'..i) end
    local cancelled=0;for _ in pairs(fx.audio.cancelled) do cancelled+=1 end
    check(cancelled<=256,'cancelled lifecycle tokens are bounded')
    fx:audioState({active=false,runId=11})
    check(#fx.audio.voices==0 and not fx:audioEvent('Weapon.Report',{weaponId='Kestrel',runId=11}),'map-less travel stop rejects late gameplay')
    check(fx:sound('Victory'),'legacy results/UI cue still works during travel stop')
    fx:audioState({map='Station',runId=12})
    local current=fx:audioEvent('Enemy.Armor.Break',{position=V.zero,sourceId='elite',runId=12})
    check(current and current.sound.Playing,'new run resumes canonical enemy facts')
    e.map={};fx:audioUpdate(0)
    check(current.retired and #fx.audio.voices==0,'native map identity change cleans legacy callers without new state hook')
end
do
    local e=setup();e.fx:audioCancel('before-first-sound')
    check(not e.fx:sound('Weapon.Magazine',nil,{token='before-first-sound'}),'pre-initialization cancellation rejects late phase')
end
do
    local e=setup();local fx=e.fx
    fx:audioState({map='Station',runId=20})
    e.map={}
    check(not fx:audioEvent('Weapon.Mechanism',{phase='mag-in',runId=20,token='old-reload'}),'map replacement rejects old phase before next animation tick')
    check(not fx:audioEvent('Enemy.Charge.Warn',{position=V.zero,runId=20}),'retired run stays closed until fresh state')
    fx:audioState({map='Station',runId=21})
    check(fx:audioEvent('Enemy.Charge.Warn',{position=V.zero,runId=21}),'new map state admits current run warning')
end
do
    local e=setup();local fx=e.fx
    fx:audioState({map='Station',runId=30})
    e.map={};e:approve('World.Foundry.machinery',601)
    fx:audioState({map='Foundry',runId=31,anchors={['World.Foundry.machinery']=V.new(0/0,0,0)}})
    e:advance(.1)
    check(fx.audio.state.map=='Foundry' and fx.audio.runId=='31','fresh map state survives next native-map watch tick')
    local bed=fx.audio.world['World.Foundry.machinery']
    check(bed and not bed.anchor,'nonfinite zone anchor omitted before touching instance Position')
    fx:audioState({map='Foundry',runId=31,anchors={['World.Foundry.machinery']=V.new(10,0,0)}})
    e:advance(.1)
    check(fx.audio.world['World.Foundry.machinery'].anchor~=nil,'valid zone anchor replaces listener bed safely')
end
print('Audio runtime assertions passed:',count)
