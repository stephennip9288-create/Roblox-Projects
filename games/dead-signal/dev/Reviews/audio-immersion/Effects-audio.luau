-- AUDIO-ONLY INLINE IMPLEMENTATION. Not a new runtime ModuleScript.
-- Scoped Effects ownership granted by MAIN DEV in #23 (2026-10-17).
-- All asset IDs still come from Config; no uploads or permission claims.
local audioCatalog={}
local function cue(key,group,priority,stock,pitch,gain,range,cooldown,seconds)
    audioCatalog[key]={key=key,group=group,priority=priority,stock=stock,pitch=pitch or 1,
        gain=gain or .17,range=range or 115,cooldown=cooldown or .12,seconds=seconds or 3}
end
for _,key in ipairs({"Click","Equip","Reload","Empty","Power","Box","Perk","Revive","Victory","Round","Down","Hit","Kill","Board","Attack","Enemy","Grenade","ShockCharge"}) do
    local file=({Hit="impact_water.mp3",Board="impact_water.mp3",Grenade="impact_water.mp3",
        Attack="uuhhh.mp3",Enemy="uuhhh.mp3",Down="uuhhh.mp3",Kill="uuhhh.mp3",
        Revive="action_get_up.mp3",Victory="action_get_up.mp3",Round="action_get_up.mp3",Perk="action_get_up.mp3"})[key] or "unsheath.wav"
    local group=(key=="Attack" or key=="Enemy") and "infected" or (key=="Reload" or key=="Equip" or key=="Empty") and "mechanics" or key=="Grenade" and "weapons" or "ui"
    local priority=(key=="ShockCharge" or key=="Down") and 4 or (key=="Attack" or key=="Enemy" or key=="Board") and 1 or 2
    cue(key,group,priority,file,1,key=="ShockCharge" and .32 or .17,115,.1,3)
end
for key,pitch in pairs({Pistol=1.8,Rifle=1.65,SMG=1.95,Shotgun=.85,Heavy=.72,Sniper=.62,Energy=1.25}) do
    cue(key,"weapons",2,(key=="Pistol" or key=="Rifle" or key=="SMG") and "swordslash.wav" or "swordlunge.wav",pitch,.17,180,.045,2)
    audioCatalog[key].report=true
    audioCatalog[key].cut=(key=="Pistol" or key=="Rifle" or key=="SMG" or key=="Heavy") and .1 or nil
end
for key,info in pairs({Howl={"uuhhh.mp3",.48},Redline={"action_get_up.mp3",.72},IronMarch={"unsheath.wav",.55},
    Volatile={"unsheath.wav",1.8},Stalker={"uuhhh.mp3",.65},ArmorBreak={"impact_water.mp3",1.35},Vent={"impact_water.mp3",.65}}) do
    cue(key,key=="Vent" and "world" or "infected",(key=="Howl" or key=="Volatile" or key=="Stalker") and 4 or 2,info[1],info[2],.30,125,.3,3)
end
-- Legacy ambience stays finite: Controller currently requests it every 20 seconds.
for _,key in ipairs({"Ambient","Radio","Machinery","Wind","Dispatch"}) do cue(key,"ambience",0,nil,1,.12,160,8,12) end
local function semantic(key,from,changes)
    local spec=table.clone(audioCatalog[from]);spec.key=key;spec.alias=from;spec.config=spec.config or from
    for k,v in pairs(changes or {}) do spec[k]=v end
    audioCatalog[key]=spec
end
semantic("Zombie.Groan","Enemy",{gain=.14,cooldown=1.6,range=70})
semantic("Zombie.Gear","Board",{group="infected",priority=1,gain=.10,cooldown=.7,range=35,stock=false})
semantic("Zombie.Entry","Board",{group="infected",priority=3,gain=.24,cooldown=.6,range=85})
semantic("Zombie.Attack","Attack",{cooldown=.55})
semantic("Hound.Breath","Enemy",{priority=1,pitch=.8,gain=.12,range=42,cooldown=1.2,stock=false})
semantic("Hound.Snarl","Howl",{priority=1,cooldown=1.1,range=70,gain=.18})
semantic("Hound.Charge","Howl",{cooldown=.4})
semantic("Hound.Alpha","Howl",{priority=3,pitch=.38,cooldown=1.8,gain=.26})
semantic("Stalker.Warning","Stalker")
semantic("Elite.ArmorBreak","ArmorBreak",{cooldown=.16})
semantic("Elite.VolatileFuse","Volatile",{cooldown=.3})
semantic("Warden.Warning","ShockCharge",{range=160})
semantic("Warden.Phase","ShockCharge",{priority=3,pitch=.7,cooldown=1,range=160})
semantic("Wave.Prepare","Round",{priority=3,cooldown=1})
semantic("Wave.Complete","Victory",{cooldown=1})
semantic("Objective.Extraction","Round",{priority=4,pitch=.8,gain=.32,cooldown=1})
semantic("Objective.Signal","Power",{priority=3,gain=.26,cooldown=1})
semantic("Radio.Transmission","Radio",{group="world",priority=1,seconds=10,cooldown=8})
semantic("Weapon.Equip","Equip")
semantic("Weapon.Reload","Reload")
semantic("Weapon.Magazine","Reload",{pitch=.8,gain=.12,cooldown=.12})
semantic("Weapon.Bolt","Equip",{pitch=1.3,gain=.14,cooldown=.12})
semantic("Weapon.Pump","Equip",{pitch=.85,gain=.14,cooldown=.18})
semantic("Weapon.Cell","Reload",{pitch=1.2,gain=.14,cooldown=.15})
semantic("Weapon.Feed","Equip",{pitch=.75,gain=.14,cooldown=.15})
semantic("Weapon.Charge","Power",{pitch=.9,gain=.14,cooldown=.2})
semantic("Weapon.Shell","Reload",{pitch=1.15,gain=.11,cooldown=.15})
semantic("Weapon.Empty","Empty")
semantic("Weapon.Hit","Hit")
semantic("Weapon.Kill","Kill")
for _,key in ipairs({"Player.Footstep","Zombie.Footstep","Weapon.Impact"}) do cue(key,key=="Zombie.Footstep" and "infected" or "mechanics",1,nil,1,.10,45,.16,1.5) end
local worldBeds={
    Lobby={"World.Dispatch.room"},
    Station={"World.Station.wind","World.Station.radio","World.Station.power"},
    Foundry={"World.Foundry.machinery","World.Foundry.furnace","World.Foundry.vent"},
    Frost={"World.Frost.wind","World.Frost.relay","World.Frost.structure"},
}
for map,keys in pairs(worldBeds) do for i,key in ipairs(keys) do
    cue(key,"ambience",0,nil,1,.09,150,0,0)
    audioCatalog[key].loop=true
    audioCatalog[key].exterior=i==1 and map~="Foundry" and map~="Lobby"
end end
for _,key in ipairs({"World.Station.contact","World.Foundry.impact","World.Frost.ice"}) do cue(key,"world",1,nil,1,.12,180,12,4) end
local worldEvents={Station="World.Station.contact",Foundry="World.Foundry.impact",Frost="World.Frost.ice"}
for key,from in pairs({["Enemy.Entry.Approach"]="Zombie.Gear",["Enemy.Entry.Contact"]="Zombie.Entry",["Enemy.Entry.Land"]="Zombie.Entry",
    ["Enemy.Charge.Warn"]="Hound.Charge",["Enemy.Ambush.Warn"]="Stalker.Warning",["Enemy.Blast.Warn"]="Elite.VolatileFuse",
    ["Enemy.Alpha"]="Hound.Alpha",["Enemy.Armor.Break"]="Elite.ArmorBreak",["Enemy.Death"]="Enemy",
    ["Combat.Hit"]="Hit",["Combat.Kill"]="Kill",["Wave.Start"]="Round",["Warden.Warn"]="Warden.Warning",["Extraction.Warn"]="Objective.Extraction"}) do semantic(key,from) end
local audioGroups={ambience=true,world=true,weapons=true,mechanics=true,infected=true,ui=true}
local function finite(value,default,minimum,maximum)
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return default end
    return math.clamp(value,minimum,maximum)
end
local function textToken(value)
    if type(value)~="string" and type(value)~="number" then return nil end
    return tostring(value):sub(1,96)
end
local function validPosition(position)
    return typeof(position)=="Vector3" and position.X==position.X and position.Y==position.Y
        and position.Z==position.Z and position.Magnitude~=math.huge
end
local function asset(value,serial)
    if type(value)=="table" then value=value[(serial-1)%math.max(1,#value)+1] end
    if type(value)=="number" then
        if value~=value or value<1 or value==math.huge or value%1~=0 then return nil end
        value=string.format("%.0f",value)
    end
    if type(value)~="string" then return nil end
    local digits=value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
    if not digits or #digits>20 or not digits:find("[1-9]") then return nil end
    return "rbxassetid://"..digits
end
function FX.new()
    local self=setmetatable({settings=U.copy(C.DefaultSettings),rigs=setmetatable({},{__mode="k"}),animTime=0,shake=0},FX)
    self.folder=U.make("Folder",workspace,{Name="DeadSignalLocalEffects"}) return self
end
function FX:audioInit()
    if self.audio then return self.audio end
    local a={voices={},last={},lastCount=0,failed={},cancelled={},epoch=0,serial=0,gains={},duck=1,duckUntil=0,lastTick=os.clock(),state={},world={},nextWorld=0,nextClean=0}
    a.flat=U.make("Folder",SoundService,{Name="DeadSignalAudio"})
    a.spatial=U.make("Folder",self.folder,{Name="AudioAnchors"})
    a.map=workspace:FindFirstChild("DeadSignalMap")
    self.audio=a
    -- The existing effects folder is the owning lifecycle. Explicit destroy also works.
    pcall(function() a.ownerConnection=self.folder.Destroying:Connect(function() self:audioDestroy() end) end)
    return a
end
function FX:audioRetire(voice)
    if voice.retired then return end
    voice.retired=true
    if voice.connection then voice.connection:Disconnect();voice.connection=nil end
    pcall(function() voice.sound:Stop() end)
    if voice.anchor then voice.anchor:Destroy() else voice.sound:Destroy() end
end
function FX:audioCancel(token)
    local a=self:audioInit();token=textToken(token)
    if a.destroyed or not token then return end
    local total=0;local oldest,when
    for key,at in pairs(a.cancelled) do total+=1;if not when or at<when then oldest=key;when=at end end
    if total>=256 and not a.cancelled[token] then a.cancelled[oldest]=nil end
    a.cancelled[token]=os.clock()
    for i=#a.voices,1,-1 do
        local v=a.voices[i]
        if v.token==token then self:audioRetire(v);table.remove(a.voices,i) end
    end
    for key,entry in pairs(a.last) do if entry.token==token then a.last[key]=nil;a.lastCount-=1 end end
end
function FX:audioReset(token)
    local a=self:audioInit()
    if a.destroyed then return end
    for _,v in ipairs(a.voices) do self:audioRetire(v) end
    a.retiredRunId=a.runId or a.retiredRunId
    a.voices={};a.last={};a.lastCount=0;a.world={};a.state={};a.token=textToken(token)
    a.epoch+=1;a.cancelled={};a.runId=nil;a.suspended=false
    a.duck=1;a.duckUntil=0;a.nextWorld=0;a.nextActivity=0;a.lastTick=os.clock();a.nextClean=0
end
function FX:audioDestroy()
    local a=self.audio
    if not a or a.destroyed then return end
    a.destroyed=true
    if a.ownerConnection then a.ownerConnection:Disconnect();a.ownerConnection=nil end
    for _,v in ipairs(a.voices) do self:audioRetire(v) end
    a.voices={};a.last={};a.lastCount=0;a.world={};a.state={};a.failed={};a.gains={};a.cancelled={};a.epoch+=1
    a.flat:Destroy();a.spatial:Destroy()
end
function FX:audioMix(gains)
    local a=self:audioInit()
    if type(gains)~="table" or a.destroyed then return end
    for group in pairs(audioGroups) do
        if gains[group]~=nil then a.gains[group]=finite(gains[group],1,0,1) end
    end
    self:audioUpdate(0)
end
function FX:audioRemember(key,now,cooldown,token)
    local a=self.audio;local previous=a.last[key]
    if previous and now<previous.untilTime then return false end
    if not previous then
        if a.lastCount>=256 then
            local oldest,when
            for k,entry in pairs(a.last) do if not when or entry.untilTime<when then oldest=k;when=entry.untilTime end end
            if oldest then a.last[oldest]=nil;a.lastCount-=1 end
        end
        a.lastCount+=1
    end
    a.last[key]={untilTime=now+cooldown,token=token}
    return true
end
function FX:audioFailed(id,now)
    if not id:match("^rbxassetid://") then return end
    local a=self.audio;local total=0;local oldest,when
    for key,untilTime in pairs(a.failed) do
        total+=1
        if not when or untilTime<when then oldest=key;when=untilTime end
    end
    if total>=128 and not a.failed[id] then a.failed[oldest]=nil end
    a.failed[id]=now+30
end
local function audioZone(v,state)
    local zone=1
    if v.spec.loop then
        zone=v.spec.exterior and (state.indoors and .28 or 1) or (state.indoors and 1 or .65)
        zone*=.70+.30*finite(state.intensity,0,0,1)
    end
    return zone
end
function FX:audioGain(v)
    local a=self.audio;local group=v.spec.group;local master=finite(self.settings and self.settings.volume,.65,0,1)
    local zone=v.zoneGain or audioZone(v,a.state)
    local duck=v.priority>=4 and 1 or a.duck
    local headroom=v.priority>=4 and math.min(1,math.sqrt(2/math.max(2,a.criticalCount or 0))) or math.min(1,math.sqrt(3/math.max(3,a.routineCount or 0)))
    return math.clamp(master*v.gain*(a.gains[group] or 1)*v.fade*zone*duck*headroom,0,.65)
end
function FX:sound(key,position,options)
    if type(key)~="string" then return false,"event" end
    options=type(options)=="table" and options or {}
    options=table.clone(options)
    options.source=options.sourceId or options.source or options.eventId
    options.weapon=options.weaponId or options.weapon
    local weapon=type(options.weapon)=="string" and C.Weapons and C.Weapons[options.weapon]
    options.class=options.class or weapon and weapon.class
    options.upgraded=options.upgraded==true or finite(options.tier,0,0,10)>0
    if position==nil then position=options.position end
    if key=="World.Zone" or key=="World.Ambient" then self:audioState(options);return true end
    if key=="World.Landmark" then
        key=worldEvents[options.map]
        if not key or not position then return false,"landmark" end
    end
    if key=="Weapon.Mechanism" or (key=="Weapon.Reload" and options.phase~=nil) then
        local phase=options.phase
        if phase=="cancel" then
            if not textToken(options.token) then return false,"token" end
            self:audioCancel(options.token);return true
        end
        key=({["mag-out"]="Weapon.Magazine",["mag-in"]="Weapon.Magazine",["action-open"]=options.class=="Shotgun" and "Weapon.Pump" or "Weapon.Bolt",
            ["action-close"]=options.class=="Shotgun" and "Weapon.Pump" or "Weapon.Bolt",["shell-in"]="Weapon.Shell",
            ["cell-out"]="Weapon.Cell",["cell-in"]="Weapon.Cell",charge="Weapon.Charge",["feed-open"]="Weapon.Feed",["feed-close"]="Weapon.Feed",
            equip="Weapon.Equip",fire="Weapon.Report",empty="Weapon.Empty"})[phase]
        if not key then return false,"phase" end
    end
    if key=="Weapon.Fire" or key=="Weapon.Report" then
        if not audioCatalog[options.class] or not audioCatalog[options.class].report then return false,"class" end
        key=options.class
    end
    local spec=audioCatalog[key]
    if not spec then return false,"event" end
    if options.firstPerson==true and (spec.report or key:sub(1,7)=="Weapon.") then position=nil end
    if position~=nil and not validPosition(position) then return false,"position" end
    local a=self:audioInit();local now=os.clock()
    if a.destroyed then return false,"destroyed" end
    -- Resolve a native map replacement before admitting a possibly delayed cue.
    self:audioUpdate(0,true)
    if options.runId~=nil and ((a.runId~=nil and textToken(options.runId)~=a.runId)
        or (a.runId==nil and textToken(options.runId)==a.retiredRunId)) then return false,"epoch" end
    if a.suspended and (spec.group~="ui" or options.runId~=nil) then return false,"inactive" end
    local master=finite(self.settings and self.settings.volume,.65,0,1)
    if master==0 or (a.gains[spec.group] or 1)==0 then return false,"muted" end
    local camera=workspace.CurrentCamera
    local distance=position and camera and (camera.CFrame.Position-position).Magnitude or 0
    if distance>spec.range then return false,"distance" end
    local source=textToken(options.source)
    if not source then source=position and string.format("%d:%d:%d",math.floor(position.X/8),math.floor(position.Y/8),math.floor(position.Z/8)) or "local" end
    local token=textToken(options.token) or a.token
    if token and a.cancelled[token] then return false,"cancelled" end
    local dedup=key.."/"..source.."/"..(token or "")
    local entry=a.last[dedup]
    if entry and now<entry.untilTime then return false,"cooldown" end
    local configKey=spec.config or key
    local ids=C.SoundIds or {};local evolution=C.Evolution and C.Evolution.audio or {}
    local serial=a.serial+1
    local custom=asset(evolution[key],serial)
    if not custom and type(options.phase)=="string" then custom=asset(ids[key.."."..options.phase:sub(1,32)],serial) end
    if not custom and type(options.variant)=="string" then custom=asset(ids[key.."."..options.variant:sub(1,32)],serial) end
    if not custom and options.upgraded==true then custom=asset(ids[key..".Upgraded"],serial) end
    if not custom and type(options.weapon)=="string" and C.Weapons and C.Weapons[options.weapon] then
        custom=asset(ids[key.."."..options.weapon],serial)
    end
    if not custom and type(options.material)=="string" then custom=asset(ids[key.."."..options.material:sub(1,32)],serial) end
    if not custom and type(options.class)=="string" then custom=asset(ids[key.."."..options.class:sub(1,24)],serial) end
    custom=custom or asset(ids[key],serial) or asset(evolution[spec.alias],serial) or asset(ids[spec.alias],serial)
        or asset(evolution[configKey],serial) or asset(ids[configKey],serial)
    if spec.report and distance>70 then custom=asset(ids[key..".Far"],serial) or custom end
    if custom and (a.failed[custom] or 0)>now then
        if spec.stock then custom=nil else return false,"unavailable" end
    end
    if not custom and not spec.stock then return false,"asset" end
    -- Critical cues preempt lower priorities immediately; there is no late queue.
    local low=self.settings and self.settings.lowEffects
    local limit=low and 12 or 20;local reserve=low and 6 or 8
    local groupCap=({ambience=low and 2 or 3,world=2,weapons=low and 3 or 5,mechanics=low and 2 or 3,infected=low and 2 or 4,ui=3})[spec.group]
    local priority=finite(options.priority,spec.priority,0,spec.priority)
    local routine,group=0,0
    local victim,victimScore
    for i,v in ipairs(a.voices) do
        if v.priority<4 then routine+=1 end
        if v.spec.group==spec.group and v.targetFade>0 then group+=1 end
        local score=v.priority*1000-(v.distance or 0)
        if v.priority<priority and (not victimScore or score<victimScore) then victim=i;victimScore=score end
    end
    if priority<4 and (routine>=limit-reserve or group>=groupCap) then return false,"budget" end
    if #a.voices>=limit then
        -- With all slots critical, retain nearby danger rather than distant warnings.
        if not victim and priority>=4 then
            for i,v in ipairs(a.voices) do if v.priority==priority and v.distance>distance+8 and (not victim or v.distance>a.voices[victim].distance) then victim=i end end
        end
        if not victim then return false,"budget" end
        self:audioRetire(a.voices[victim]);table.remove(a.voices,victim)
    end
    a.serial=serial
    self:audioRemember(dedup,now,spec.cooldown,token)
    local anchor,parent
    if position then
        anchor=U.make("Part",a.spatial,{Name="AudioSource",Size=Vector3.new(.05,.05,.05),Position=position,Transparency=1,Anchored=true,
            CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false})
        parent=anchor
    else parent=a.flat end
    local sound=U.make("Sound",parent,{Name=key,SoundId=custom or "rbxasset://sounds/"..spec.stock,Volume=0,Looped=spec.loop==true,
        PlaybackSpeed=custom and 1 or spec.pitch,RollOffMode=Enum.RollOffMode.InverseTapered,RollOffMinDistance=8,RollOffMaxDistance=spec.range})
    local usingStock=not custom
    -- Never wait for an unloaded custom danger cue. Bundled treatment is immediate.
    if custom and spec.stock and not sound.IsLoaded then
        self:audioFailed(custom,now);sound.SoundId="rbxasset://sounds/"..spec.stock;sound.PlaybackSpeed=spec.pitch;usingStock=true
    end
    local gain=finite(options.gain,1,0,1)*spec.gain
    local v={sound=sound,anchor=anchor,spec=spec,key=key,priority=priority,token=token,source=source,gain=gain,distance=distance,
        position=position,born=now,epoch=a.epoch,expires=not spec.loop and now+finite(options.duration,spec.seconds,.05,spec.seconds) or math.huge,loadUntil=now+5,
        cutAt=usingStock and spec.cut and now+spec.cut or nil,fade=spec.loop and 0 or 1,targetFade=1}
    if usingStock and position and spec.report and distance>70 then sound.PlaybackSpeed*=.92 end
    -- Explicit approximation only. Roblox walls do not automatically occlude sounds.
    if position and options.occluded==true and priority<4 then
        U.make("EqualizerSoundEffect",sound,{HighGain=-7,MidGain=-1,LowGain=0});v.gain*=.8
    end
    a.voices[#a.voices+1]=v
    pcall(function() v.connection=sound.Ended:Connect(function() self:audioRetire(v) end) end)
    if priority>=4 then a.duck=.28;a.duckUntil=now+.25 end
    self:audioUpdate(0,true)
    local ok=pcall(function() sound:Play() end)
    if not ok then self:audioFailed(sound.SoundId,now);self:audioRetire(v);return false,"playback" end
    if not spec.loop then Debris:AddItem(anchor or sound,spec.seconds+.25) end
    return v
end
function FX:audioState(state)
    if type(state)~="table" then return end
    local a=self:audioInit()
    if a.destroyed then return end
    local token=textToken(state.token) or textToken(state.runId)
    if state.active==false then self:audioReset(token);a.state.active=false;a.suspended=true;return end
    if type(state.map)~="string" or not worldBeds[state.map] then return end
    local runId=textToken(state.runId)
    local map=workspace:FindFirstChild("DeadSignalMap")
    if token~=a.token or state.map~=a.state.map or runId~=a.runId or map~=a.map then self:audioReset(token) end
    a.runId=runId;a.map=map
    local anchors={}
    if type(state.anchors)=="table" then
        for _,key in ipairs(worldBeds[state.map] or {}) do if validPosition(state.anchors[key]) then anchors[key]=state.anchors[key] end end
        local event=worldEvents[state.map]
        if event and validPosition(state.anchors[event]) then anchors[event]=state.anchors[event] end
    end
    a.state={map=state.map,room=textToken(state.room),indoors=state.indoors==true,active=state.active~=false,
        intensity=finite(state.intensity,0,0,1),anchors=anchors}
    a.nextWorld=0
end
function FX:audioEvent(key,context)
    return self:sound(key,nil,context)
end
function FX:audioWorld(now)
    local a=self.audio;local state=a.state
    if now<a.nextWorld or not state.active then return end
    a.nextWorld=now+1
    local maxBeds=self.settings and self.settings.lowEffects and 2 or 3
    local wanted={}
    for i,key in ipairs(worldBeds[state.map] or {}) do
        if i<=maxBeds then
            wanted[key]=true
            local v=a.world[key]
            local position=state.anchors[key]
            if v and not v.retired and ((v.position~=nil)~=(position~=nil)) then self:audioRetire(v) end
            if not v or v.retired then
                local result=self:sound(key,position,{token=a.token,source="world"})
                if result then a.world[key]=result end
            else
                v.targetFade=1;v.position=position
                if v.anchor and position then v.anchor.Position=position end
            end
        end
    end
    for key,v in pairs(a.world) do
        if not wanted[key] then v.targetFade=0 end
        if v.retired then a.world[key]=nil end
    end
    if now>=(a.nextActivity or 0) then
        a.nextActivity=now+18+(a.serial%11)
        local key=worldEvents[state.map]
        -- A distant landmark cue must have an explicitly authored world position.
        if key and state.anchors[key] then self:sound(key,state.anchors[key],{source="landmark",token=a.token}) end
    end
end
function FX:audioUpdate(_,skipWorld)
    local a=self.audio
    if not a or a.destroyed then return end
    local map=workspace:FindFirstChild("DeadSignalMap")
    if map~=a.map then self:audioReset(a.token);a.map=map end
    local now=os.clock();local dt=math.clamp(now-a.lastTick,0,.25);a.lastTick=now
    local low=self.settings and self.settings.lowEffects;local limit=low and 12 or 20
    -- Apply quality changes to sounds already playing, preserving critical slots first.
    while #a.voices>limit do
        local victim=1
        for i,v in ipairs(a.voices) do if v.priority<a.voices[victim].priority or (v.priority==a.voices[victim].priority and v.distance>a.voices[victim].distance) then victim=i end end
        self:audioRetire(a.voices[victim]);table.remove(a.voices,victim)
    end
    local critical,routine=0,0;local camera=workspace.CurrentCamera
    for i=#a.voices,1,-1 do
        local v=a.voices[i]
        if v.position and camera then v.distance=(v.position-camera.CFrame.Position).Magnitude end
        if v.targetFade>v.fade then v.fade=math.min(v.targetFade,v.fade+dt/.8)
        else v.fade=math.max(v.targetFade,v.fade-dt/.8) end
        local zone=audioZone(v,a.state)
        v.zoneGain=(v.zoneGain or zone)+(zone-(v.zoneGain or zone))*(1-math.exp(-dt*3))
        local unavailable=not v.retired and v.sound.Parent and now>=v.loadUntil and not v.sound.IsLoaded
        if unavailable then self:audioFailed(v.sound.SoundId,now) end
        if v.retired or v.epoch~=a.epoch or not v.sound.Parent or now>=v.expires or (v.cutAt and now>=v.cutAt) or v.distance>v.spec.range
            or (v.targetFade==0 and v.fade<=0) or unavailable then
            self:audioRetire(v);table.remove(a.voices,i)
        elseif v.priority>=4 then critical+=1 else routine+=1 end
    end
    a.criticalCount=critical;a.routineCount=routine
    local target=(critical>0 or now<a.duckUntil) and .28 or 1
    a.duck=target< a.duck and target or a.duck+(target-a.duck)*(1-math.exp(-dt*5))
    for _,v in ipairs(a.voices) do v.sound.Volume=self:audioGain(v) end
    if now>=a.nextClean then
        a.nextClean=now+1
        for key,entry in pairs(a.last) do if now>=entry.untilTime then a.last[key]=nil;a.lastCount-=1 end end
        for id,untilTime in pairs(a.failed) do if now>=untilTime then a.failed[id]=nil end end
    end
    if not skipWorld then self:audioWorld(now) end
end
