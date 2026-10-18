local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local NPCPose=require(RS.DeadSignal.NPCPose)
local FX={} FX.__index=FX
-- AUDIO-ONLY INLINE IMPLEMENTATION. Not a new runtime ModuleScript.
-- Batch 1.1 audio-only ownership renewed by MAIN DEV in #37 / 206ae616.
-- All asset IDs still come from Config; no uploads or permission claims.
local ContentProvider=game:GetService("ContentProvider")
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
    cue(key,"weapons",2,(key=="Pistol" or key=="Rifle" or key=="SMG") and "swordslash.wav" or "swordlunge.wav",pitch,.17,180,.045,4)
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
semantic("Zombie.Gear","Board",{group="infected",priority=1,gain=.10,cooldown=.7,range=35,stock=false,alias=false,config="Zombie.Gear"})
semantic("Zombie.Entry","Board",{group="infected",priority=3,gain=.24,cooldown=.6,range=85})
semantic("Zombie.Attack","Attack",{priority=3,gain=.21,cooldown=.55,range=65})
semantic("Hound.Breath","Enemy",{priority=1,pitch=.8,gain=.12,range=42,cooldown=1.2,stock=false,alias=false,config="Hound.Breath"})
semantic("Hound.Snarl","Howl",{priority=1,cooldown=1.1,range=70,gain=.18})
semantic("Hound.Charge","Howl",{cooldown=.4})
semantic("Hound.Alpha","Howl",{priority=3,pitch=.38,cooldown=1.8,gain=.26})
semantic("Hound.Attack","Howl",{priority=3,gain=.23,cooldown=.35,range=65})
semantic("Hound.Death","Enemy",{priority=2,gain=.16,cooldown=.3,stock=false,alias=false,config="Hound.Death"})
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
semantic("Hound.Footstep","Zombie.Footstep",{gain=.08,cooldown=.18,range=38,alias=false,config="Hound.Footstep"})
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
-- Initial calibration for the prepared, peak-controlled recordings. Stock
-- fallback levels stay separate. Native/device listening still sets acceptance.
for key,spec in pairs(audioCatalog) do
    spec.recordingGain=spec.gain
    if spec.group=="ambience" then spec.recordingGain=.30
    elseif spec.group=="mechanics" then spec.recordingGain=.22
    elseif spec.group=="infected" then spec.recordingGain=spec.priority>=3 and .30 or .20 end
    if spec.priority>=4 then spec.recordingGain=.42 end
    if spec.report then spec.recordingGain=({Pistol=.35,Rifle=.38,SMG=.32,Shotgun=.43,Heavy=.42,Sniper=.43,Energy=.38})[key] end
end
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
local function asset(value)
    if type(value)=="number" then
        if value~=value or value<1 or value==math.huge or value%1~=0 then return nil end
        value=string.format("%.0f",value)
    end
    if type(value)~="string" then return nil end
    local digits=value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
    if not digits or #digits>20 or not digits:find("[1-9]") then return nil end
    return "rbxassetid://"..digits
end
-- Banks accept legacy IDs/arrays plus {variants={}, near={}, far={}, indoor={},
-- outdoor={}, gain=0..1}. Recordings retain authored speed: variation is samples.
local function bankList(value)
    if asset(value) then return {value} end
    if type(value)~="table" then return {} end
    if asset(value.id) then return {value.id} end
    if type(value.variants)=="table" then value=value.variants end
    local result={}
    for i=1,math.min(#value,12) do local id=asset(value[i]);if id then result[#result+1]=id end end
    return result
end
local function hasBank(value)
    if #bankList(value)>0 then return true end
    if type(value)=="table" then
        for _,field in ipairs({"near","far","indoor","outdoor"}) do if #bankList(value[field])>0 then return true end end
    end
    return false
end
local function bankSide(value,field)
    if type(value)=="table" and hasBank(value[field]) then return value[field] end
    return value
end
function FX:audioVariant(value,family,source)
    local a=self.audio;local ids=bankList(value)
    if #ids==0 then return nil end
    local rotation=a.variation[family]
    if not rotation then
        local count=0;local first
        for key in pairs(a.variation) do count+=1;first=first or key end
        if count>=128 then a.variation[first]=nil end
        local seed=0;for i=1,#source do seed=(seed*31+string.byte(source,i))%65521 end
        rotation={index=seed%#ids};a.variation[family]=rotation
    end
    rotation.index=rotation.index%#ids+1
    local id=asset(ids[rotation.index])
    if id==rotation.last and #ids>1 then rotation.index=rotation.index%#ids+1;id=asset(ids[rotation.index]) end
    rotation.last=id
    return id
end
function FX:audioLoadClear()
    local a=self.audio
    for _,job in pairs(a.loading) do
        if job.thread then pcall(task.cancel,job.thread) end
        job.sound:Destroy()
    end
    for _,entry in pairs(a.ready) do entry.sound:Destroy() end
    a.loading={};a.ready={};a.loadQueue={};a.queued={}
end
function FX:audioRequest(id)
    local a=self.audio
    if not id or not ContentProvider or not task or not task.spawn or a.destroyed
        or a.ready[id] or a.loading[id] or a.queued[id] or (a.failed[id] or 0)>os.clock() then return end
    if #a.loadQueue<32 then a.loadQueue[#a.loadQueue+1]=id;a.queued[id]=true end
end
function FX:audioLoadTick(now)
    local a=self.audio
    if not ContentProvider or not task or not task.spawn then return end
    local cacheLimit=self.settings and self.settings.lowEffects and 16 or 32
    local cached=0;for _ in pairs(a.ready) do cached+=1 end
    while cached>cacheLimit do
        local oldest,at
        for key,entry in pairs(a.ready) do if not at or entry.at<at then oldest=key;at=entry.at end end
        a.ready[oldest].sound:Destroy();a.ready[oldest]=nil;cached-=1
    end
    local pending=0
    for id,job in pairs(a.loading) do
        if now-job.born>=8 then
            a.loading[id]=nil;if job.thread then pcall(task.cancel,job.thread) end
            job.sound:Destroy();self:audioFailed(id,now);a.metrics.loadFailed+=1
        else pending+=1 end
    end
    while pending<2 and #a.loadQueue>0 do
        local id=table.remove(a.loadQueue,1);a.queued[id]=nil
        if a.ready[id] or (a.failed[id] or 0)>now then continue end
        local probe=U.make("Sound",a.flat,{Name="AudioPreload",SoundId=id,Volume=0})
        local job={sound=probe,born=now,epoch=a.epoch};a.loading[id]=job;pending+=1
        job.thread=task.spawn(function()
            local success=probe.IsLoaded
            local ok=true
            if not success then ok=pcall(function()
                ContentProvider:PreloadAsync({probe},function(_,status) success=status==Enum.AssetFetchStatus.Success end)
            end) end
            if a.destroyed or a.loading[id]~=job or a.epoch~=job.epoch then return end
            a.loading[id]=nil
            if ok and success and probe.IsLoaded then
                local limit=self.settings and self.settings.lowEffects and 16 or 32
                local total=0;local oldest,at
                for key,entry in pairs(a.ready) do total+=1;if not at or entry.at<at then oldest=key;at=entry.at end end
                if total>=limit and oldest then a.ready[oldest].sound:Destroy();a.ready[oldest]=nil end
                a.ready[id]={sound=probe,at=os.clock()};a.failed[id]=nil;a.metrics.loaded+=1
            else probe:Destroy();self:audioFailed(id,os.clock());a.metrics.loadFailed+=1 end
        end)
    end
end
-- Warm known cue slots in priority order, with a fixed queue and two requests.
-- Completion only caches a silent Sound. It never replays an old game event.
function FX:audioWarm()
    local a=self.audio
    if not ContentProvider or finite(self.settings and self.settings.volume,.65,0,1)==0 then return end
    local keys={}
    for key in pairs(audioCatalog) do keys[#keys+1]=key end
    table.sort(keys,function(x,y) local p,q=audioCatalog[x].priority,audioCatalog[y].priority;return p==q and x<y or p>q end)
    local ids=C.SoundIds or {};local evolution=C.Evolution and C.Evolution.audio or {}
    local function request(id)
        if a.warmed[id] or a.warmCount>=96 then return end
        self:audioRequest(id)
        if a.queued[id] or a.loading[id] or a.ready[id] then a.warmed[id]=true;a.warmCount+=1 end
    end
    local function enqueue(value)
        for _,id in ipairs(bankList(value)) do request(asset(id)) end
        if type(value)=="table" then for _,field in ipairs({"near","far","indoor","outdoor"}) do
            for _,id in ipairs(bankList(value[field])) do request(asset(id)) end
        end end
    end
    -- Current map beds get reserved queue space before general gameplay slots.
    for _,key in ipairs(worldBeds[a.state.map] or {}) do enqueue(ids[key]) end
    for _,key in ipairs(keys) do
        local spec=audioCatalog[key]
        if not spec.loop then enqueue(evolution[key]);enqueue(ids[key]);enqueue(ids[key..".Far"]) end
    end
    local configured={}
    for key in pairs(ids) do if type(key)=="string" and #key<=128 then configured[#configured+1]=key end end
    table.sort(configured)
    for i=1,math.min(#configured,256) do
        local key=configured[i]
        -- Includes class/phase/material overrides without inspecting arbitrary data.
        local base=key:match("^(Weapon%.[^.]+)%.") or key:match("^(Zombie%.[^.]+)%.")
        if base and audioCatalog[base] then enqueue(ids[key]) end
    end
    self:audioLoadTick(os.clock())
end
function FX:audioSample(id,parent)
    local a=self.audio;local entry=a.ready[id]
    if entry then
        a.ready[id]=nil
        if entry.sound.Parent and entry.sound.IsLoaded then entry.sound.Parent=parent;return entry.sound end
        entry.sound:Destroy()
    end
    if (a.failed[id] or 0)>os.clock() then return nil end
    local sound=U.make("Sound",parent,{Name="AudioSample",SoundId=id,Volume=0})
    if sound.IsLoaded then return sound end
    sound:Destroy();self:audioRequest(id)
    -- No preload service is a genuine unsupported-backend failure. A normal
    -- cold sample is NOT a permission failure and does not get negative cached.
    if not ContentProvider then self:audioFailed(id,os.clock()) end
    return nil
end
function FX:audioDiagnostics()
    local a=self:audioInit();local result=table.clone(a.metrics)
    result.voices=0;for _,v in ipairs(a.voices) do if not v.retired then result.voices+=v.cost or 1 end end
    result.pending=0;for _ in pairs(a.loading) do result.pending+=1 end
    result.cached=0;for _ in pairs(a.ready) do result.cached+=1 end
    result.queued=#a.loadQueue;result.epoch=a.epoch
    result.peakBudget=a.peakSum or 0
    return result
end
function FX:audioInventory()
    local result={};local ids=C.SoundIds or {};local evolution=C.Evolution and C.Evolution.audio or {}
    for key,spec in pairs(audioCatalog) do
        local configured=hasBank(ids[key]) or hasBank(evolution[key]) or hasBank(ids[spec.alias]) or hasBank(evolution[spec.alias]) or hasBank(ids[spec.config])
        result[#result+1]={key=key,group=spec.group,priority=spec.priority,range=spec.range,cooldown=spec.cooldown,
            seconds=spec.seconds,loop=spec.loop==true,configured=configured,
            fallback=spec.stock and "rbxasset://sounds/"..spec.stock or "silent-until-upload",fallbackPitch=spec.pitch,
            fallbackGain=spec.gain,recordingGain=spec.recordingGain}
    end
    table.sort(result,function(x,y) return x.key<y.key end)
    return result
end
local acousticProfiles={outdoor={wet=-80,decay=.2},room={wet=-22,decay=.55},corridor={wet=-19,decay=.8},hall={wet=-17,decay=1.4}}
function FX:audioReadRooms()
    local a=self.audio
    if a.rooms then return end
    a.rooms={}
    -- Read only the published bounded map semantics; no new world query system.
    pcall(function()
        local semantics=a.map and a.map:FindFirstChild("MapSemantics")
        local zones=semantics and semantics:FindFirstChild("Zones")
        for i,item in ipairs(zones and zones:GetChildren() or {}) do
            if i>32 then break end
            local center=item:GetAttribute("Position")
            if not validPosition(center) then continue end
            local info={id=item.Name,center=center,level=item:GetAttribute("Level") or 0,priority=item:GetAttribute("Priority") or 0,
                indoors=item:GetAttribute("Indoors")==true,regions={}}
            local area=0;local purpose=string.lower(tostring(item:GetAttribute("Purpose") or ""))
            for j,region in ipairs(item:GetChildren()) do
                if j>32 then break end
                local n=region:GetAttribute("PointCount")
                if type(n)~="number" or n<3 or n>16 then continue end
                local points={}
                for k=1,n do local point=region:GetAttribute("Point"..k);if validPosition(point) then points[#points+1]=point end end
                if #points==n then
                    local signed=0
                    for k,p in ipairs(points) do local q=points[k%n+1];signed+=p.X*q.Z-q.X*p.Z end
                    area+=math.abs(signed)*.5;info.regions[#info.regions+1]=points
                end
            end
            info.space=not info.indoors and "outdoor" or (purpose:find("corridor",1,true) or purpose:find("service walk",1,true)) and "corridor" or area>=1000 and "hall" or "room"
            a.rooms[#a.rooms+1]=info
        end
        table.sort(a.rooms,function(x,y) return x.priority==y.priority and x.id<y.id or x.priority>y.priority end)
    end)
end
function FX:audioSpace(position)
    local a=self.audio;self:audioReadRooms()
    for _,room in ipairs(a.rooms) do
        if not position then if room.id==a.state.room then return room.space end
        else
            local floor=room.level==1 and room.center.Y or 0
            if position.Y<floor-.8 or position.Y>floor+9 then continue end
            for _,points in ipairs(room.regions) do
                local inside=false;local previous=points[#points]
                for _,p in ipairs(points) do
                    if (p.Z>position.Z)~=(previous.Z>position.Z) and position.X<(previous.X-p.X)*(position.Z-p.Z)/(previous.Z-p.Z)+p.X then inside=not inside end
                    previous=p
                end
                if inside then return room.space end
            end
        end
    end
    return position and "outdoor" or a.state.indoors and "room" or "outdoor"
end
function FX:audioTreat(v,dt)
    if not v.custom or v.priority>=4 or v.spec.loop or v.spec.group=="ui" then return end
    local low=self.settings and self.settings.lowEffects
    if low and not v.reverb then return end
    if not v.acousticSpace or (v.position and v.acousticPosition~=v.position)
        or (not v.position and v.roomRevision~=self.audio.roomRevision) then
        v.acousticSpace=self:audioSpace(v.position);v.acousticPosition=v.position;v.roomRevision=self.audio.roomRevision
    end
    local profile=acousticProfiles[v.acousticSpace]
    local wet=low and -80 or profile.wet
    if wet>-70 and not v.reverb then v.reverb=U.make("ReverbSoundEffect",v.sound,{DryLevel=0,WetLevel=wet,DecayTime=profile.decay,Density=.65,Diffusion=.8}) end
    if v.reverb then
        v.reverb.WetLevel+=(wet-v.reverb.WetLevel)*(1-math.exp(-dt*5))
        v.reverb.DecayTime=profile.decay
    end
end
function FX:audioOcclusion(now,dt)
    local a=self.audio;local camera=workspace.CurrentCamera
    if not camera or not a.map then return end
    if now>=(a.nextOcclusion or 0) and #a.voices>0 then
        a.nextOcclusion=now+.2
        local budget=self.settings and self.settings.lowEffects and 1 or 2
        for _=1,#a.voices do
            a.occlusionCursor=(a.occlusionCursor or 0)%#a.voices+1
            local v=a.voices[a.occlusionCursor]
            if not v.custom or not v.position or v.priority>=4 or v.spec.loop or v.occluded then continue end
            budget-=1
            pcall(function()
                local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
                params.FilterDescendantsInstances={a.map};params.RespectCanCollide=true
                local origin=camera.CFrame.Position;local delta=v.position-origin
                local hit=delta.Magnitude>.5 and workspace:Raycast(origin,delta,params)
                v.blocked=hit and (hit.Position-origin).Magnitude<delta.Magnitude-.5 and 1 or 0
            end)
            if budget<=0 then break end
        end
    end
    for _,v in ipairs(a.voices) do if v.custom and v.priority<4 and not v.occluded then
        v.muffle=(v.muffle or 0)+((v.blocked or 0)-(v.muffle or 0))*(1-math.exp(-dt*8))
        v.occlusionGain=1-v.muffle*.2
        if v.muffle>.01 and not v.equalizer then v.equalizer=U.make("EqualizerSoundEffect",v.sound,{HighGain=0,MidGain=0,LowGain=0}) end
        if v.equalizer then v.equalizer.HighGain=-9*v.muffle;v.equalizer.MidGain=-2*v.muffle end
        if v.farSound and v.muffle>.01 and not v.farEqualizer then v.farEqualizer=U.make("EqualizerSoundEffect",v.farSound,{HighGain=0,MidGain=0,LowGain=0}) end
        if v.farEqualizer then v.farEqualizer.HighGain=-9*v.muffle;v.farEqualizer.MidGain=-2*v.muffle end
    end end
end
function FX.new()
    local self=setmetatable({settings=U.copy(C.DefaultSettings),rigs=setmetatable({},{__mode="k"}),animTime=0,shake=0},FX)
    self.folder=U.make("Folder",workspace,{Name="DeadSignalLocalEffects"}) return self
end
function FX:audioInit()
    if self.audio then return self.audio end
    local a={voices={},last={},lastCount=0,failed={},cancelled={},epoch=0,serial=0,gains={},duck=1,duckUntil=0,lastTick=os.clock(),state={},world={},worldNext={},nextWorld=0,nextClean=0,
        variation={},loading={},ready={},loadQueue={},queued={},warmed={},warmCount=0,metrics={loaded=0,loadFailed=0,fallbacks=0,custom=0,paired=0},nextVocal=0}
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
    if voice.farConnection then voice.farConnection:Disconnect();voice.farConnection=nil end
    pcall(function() voice.sound:Stop() end)
    if voice.farSound then pcall(function() voice.farSound:Stop() end) end
    if voice.anchor then voice.anchor:Destroy() else voice.sound:Destroy() end
    if voice.farSound and not voice.anchor then voice.farSound:Destroy() end
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
    self:audioLoadClear()
    a.retiredRunId=a.runId or a.retiredRunId
    a.voices={};a.last={};a.lastCount=0;a.world={};a.worldNext={};a.state={};a.token=textToken(token)
    a.epoch+=1;a.cancelled={};a.runId=nil;a.suspended=false
    a.duck=1;a.duckUntil=0;a.nextWorld=0;a.nextActivity=0;a.lastTick=os.clock();a.nextClean=0;a.peakSum=0
    a.variation={};a.nextVocal=0;a.nextWarm=0;a.rooms=nil;a.warmed={};a.warmCount=0;a.nextOcclusion=0;a.occlusionCursor=0;a.roomRevision=0
end
function FX:audioDestroy()
    local a=self.audio
    if not a or a.destroyed then return end
    a.destroyed=true
    if a.ownerConnection then a.ownerConnection:Disconnect();a.ownerConnection=nil end
    for _,v in ipairs(a.voices) do self:audioRetire(v) end
    self:audioLoadClear()
    a.voices={};a.last={};a.lastCount=0;a.world={};a.state={};a.failed={};a.gains={};a.cancelled={};a.epoch+=1
    a.rooms=nil;a.variation={};a.warmed={};a.warmCount=0;a.worldNext={};a.peakSum=0
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
    return math.clamp(master*v.gain*(a.gains[group] or 1)*v.fade*zone*duck*headroom*(v.occlusionGain or 1),0,.65)
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
    if key=="Enemy.Death" and options.kind=="Hound" then key="Hound.Death" end
    if key=="Zombie.Footstep" and options.kind=="Hound" then key="Hound.Footstep" end
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
    local phase=textToken(options.phase) or ""
    local dedup=key.."/"..source.."/"..(token or "").."/"..phase
    local entry=a.last[dedup]
    if entry and now<entry.untilTime then return false,"cooldown" end
    local configKey=spec.config or key
    local ids=C.SoundIds or {};local evolution=C.Evolution and C.Evolution.audio or {}
    local serial=a.serial+1
    local bank
    local function prefer(value) if not bank and hasBank(value) then bank=value end end
    prefer(evolution[key])
    if phase~="" then
        if type(options.class)=="string" then prefer(ids[key.."."..options.class:sub(1,24).."."..phase]) end
        prefer(ids[key.."."..phase])
    end
    if type(options.variant)=="string" then prefer(ids[key.."."..options.variant:sub(1,32)]) end
    if options.upgraded==true then prefer(ids[key..".Upgraded"]) end
    if type(options.weapon)=="string" and C.Weapons and C.Weapons[options.weapon] then prefer(ids[key.."."..options.weapon]) end
    if type(options.material)=="string" then prefer(ids[key.."."..options.material:sub(1,32)]) end
    if type(options.class)=="string" then prefer(ids[key.."."..options.class:sub(1,24)]) end
    prefer(ids[key]);prefer(evolution[spec.alias]);prefer(ids[spec.alias]);prefer(evolution[configKey]);prefer(ids[configKey])
    local bankGain=type(bank)=="table" and finite(bank.gain,1,0,1) or 1
    local interval=spec.group=="ambience" and type(bank)=="table" and finite(bank.interval,0,0,60) or 0
    if interval>=8 then
        spec=table.clone(spec);spec.loop=false;spec.seconds=finite(bank.duration,4,.05,8)
    end
    local space=a.state.indoors and "indoor" or "outdoor"
    local zoneVariant=type(bank)=="table" and (hasBank(bank.indoor) or hasBank(bank.outdoor))
    bank=bankSide(bank,space)
    local family=key.."/"..phase.."/"..(textToken(options.class) or "")
    local custom=self:audioVariant(bankSide(bank,"near"),family,source)
    local farBank=type(bank)=="table" and bank.far
    if not hasBank(farBank) then farBank=ids[key..".Far"] end
    local farCustom=spec.report and self:audioVariant(farBank,family.."/far",source) or nil
    -- Low Effects selects one real recording. Normal mode can blend two ready
    -- recordings, both counted in the existing native voice budgets.
    if farCustom and (not custom or (self.settings and self.settings.lowEffects and distance>=70)) then custom=farCustom;farCustom=nil end
    if not custom and not spec.stock then return false,"asset" end
    local routineVocal=key=="Zombie.Groan" or (key=="Hound.Snarl" and options.routine==true)
    if routineVocal and now<a.nextVocal then return false,"cadence" end
    -- Critical cues preempt lower priorities immediately; there is no late queue.
    local low=self.settings and self.settings.lowEffects
    local limit=low and 12 or 20;local reserve=low and 6 or 8
    local groupCap=({ambience=low and 2 or 3,world=2,weapons=low and 3 or 5,mechanics=low and 2 or 3,infected=low and 2 or 4,ui=3})[spec.group]
    local priority=finite(options.priority,spec.priority,0,spec.priority)
    local routine,group,total,sourceReports=0,0,0,0
    local victim,victimScore
    for i,v in ipairs(a.voices) do
        local cost=v.cost or 1;total+=cost
        if v.priority<4 then routine+=cost end
        if v.spec.group==spec.group and v.targetFade>0 then group+=cost end
        if v.spec.report and v.source==source then sourceReports+=1 end
        local score=v.priority*1000-(v.distance or 0)
        if v.priority<priority and (not victimScore or score<victimScore) then victim=i;victimScore=score end
    end
    local restrike=spec.report and sourceReports>=(low and 1 or 2)
    if priority<4 and (routine>=limit-reserve or group>=groupCap or restrike) then
        -- Actual entry/attack facts can displace a routine groan or footstep.
        -- They still obey category caps and leave the critical reservation intact.
        victim=nil;victimScore=nil
        for i,v in ipairs(a.voices) do
            local ownReport=spec.report and v.spec.report and v.source==source
            local distantReport=spec.report and v.spec.report and v.distance>distance+8
            local eligible=(v.priority<priority or ownReport or distantReport) and (group<groupCap or v.spec.group==spec.group)
                and (not restrike or ownReport)
            local score=v.priority*1000-(v.distance or 0)
            if eligible and (not victimScore or score<victimScore) then victim=i;victimScore=score end
        end
        if not victim then return false,"budget" end
        local old=a.voices[victim];local cost=old.cost or 1
        routine-=cost;total-=cost
        if old.spec.group==spec.group and old.targetFade>0 then group-=cost end
        self:audioRetire(old);table.remove(a.voices,victim);victim=nil;victimScore=nil
    end
    if total>=limit then
        -- With all slots critical, retain nearby danger rather than distant warnings.
        if not victim and priority>=4 then
            for i,v in ipairs(a.voices) do if v.priority==priority and v.distance>distance+8 and (not victim or v.distance>a.voices[victim].distance) then victim=i end end
        end
        if not victim then return false,"budget" end
        self:audioRetire(a.voices[victim]);table.remove(a.voices,victim)
    end
    a.serial=serial
    local anchor,parent
    if position then
        anchor=U.make("Part",a.spatial,{Name="AudioSource",Size=Vector3.new(.05,.05,.05),Position=position,Transparency=1,Anchored=true,
            CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false})
        parent=anchor
    else parent=a.flat end
    local sound=custom and self:audioSample(custom,parent)
    local farSound
    if not sound and farCustom then sound=self:audioSample(farCustom,parent);custom=farCustom;farCustom=nil end
    if not sound and not spec.stock then if anchor then anchor:Destroy() end;return false,"loading" end
    local usingStock=not sound
    if usingStock then
        sound=U.make("Sound",parent,{SoundId="rbxasset://sounds/"..spec.stock,Volume=0});a.metrics.fallbacks+=1
    elseif farCustom and farCustom~=custom and position and not low and routine+2<=limit-reserve and total+2<=limit and group+2<=groupCap then
        farSound=self:audioSample(farCustom,parent)
    end
    for _,clip in ipairs(farSound and {sound,farSound} or {sound}) do
        clip.Name=key;clip.Looped=spec.loop==true;clip.PlaybackSpeed=usingStock and spec.pitch or 1
        clip.RollOffMode=Enum.RollOffMode.InverseTapered;clip.RollOffMinDistance=8;clip.RollOffMaxDistance=spec.range
    end
    if not usingStock and spec.loop then sound.TimePosition=finite(sound.TimeLength,0,0,120)*(serial%29)/29 end
    self:audioRemember(dedup,now,spec.cooldown,token)
    if routineVocal then a.nextVocal=now+(low and .65 or .35) end
    local gain=finite(options.gain,1,0,1)*(usingStock and spec.gain or spec.recordingGain)*bankGain
    local v={sound=sound,anchor=anchor,spec=spec,key=key,priority=priority,token=token,source=source,gain=gain,distance=distance,
        position=position,born=now,epoch=a.epoch,expires=not spec.loop and now+finite(options.duration,spec.seconds,.05,spec.seconds) or math.huge,loadUntil=now+5,
        cutAt=usingStock and spec.cut and now+spec.cut or nil,fade=spec.loop and 0 or 1,targetFade=1,
        farSound=farSound,cost=farSound and 2 or 1,custom=not usingStock,zoneVariant=zoneVariant,bankSpace=space,occluded=options.occluded==true,interval=interval}
    if not usingStock then a.metrics.custom+=1;if farSound then a.metrics.paired+=1 end end
    if usingStock and position and spec.report and distance>70 then sound.PlaybackSpeed*=.92 end
    -- Explicit approximation only. Roblox walls do not automatically occlude sounds.
    if position and options.occluded==true and priority<4 then
        v.equalizer=U.make("EqualizerSoundEffect",sound,{HighGain=-7,MidGain=-1,LowGain=0});v.gain*=.8
    end
    a.voices[#a.voices+1]=v
    pcall(function() v.connection=sound.Ended:Connect(function() v.nearEnded=true;if not farSound or v.farEnded then self:audioRetire(v) end end) end)
    if farSound then pcall(function() v.farConnection=farSound.Ended:Connect(function() v.farEnded=true;if v.nearEnded then self:audioRetire(v) end end) end) end
    if priority>=4 then a.duck=.28;a.duckUntil=now+.25 end
    self:audioUpdate(0,true)
    local ok=pcall(function() sound:Play();if farSound then farSound:Play() end end)
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
    local room=textToken(state.room);local indoors=state.indoors==true
    if room~=a.state.room or indoors~=a.state.indoors then a.roomRevision=(a.roomRevision or 0)+1 end
    a.state={map=state.map,room=room,indoors=indoors,active=state.active~=false,
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
            if v and not v.retired and v.zoneVariant and v.bankSpace~=(state.indoors and "indoor" or "outdoor") then v.targetFade=0;v=nil end
            if not v or v.retired then
                if now>=(a.worldNext[key] or 0) then
                    local result=self:sound(key,position,{token=a.token,source="world"})
                    if result then
                        a.world[key]=result
                        if result.interval>=8 then a.worldNext[key]=now+result.interval+(a.serial%7) end
                    end
                end
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
    self:audioLoadTick(now)
    if now>=(a.nextWarm or 0) then a.nextWarm=now+5;self:audioWarm() end
    local low=self.settings and self.settings.lowEffects;local limit=low and 12 or 20
    -- Apply quality changes to sounds already playing, preserving critical slots first.
    local total=0;for _,v in ipairs(a.voices) do total+=v.cost or 1 end
    while total>limit do
        local victim=1
        for i,v in ipairs(a.voices) do if v.priority<a.voices[victim].priority or (v.priority==a.voices[victim].priority and v.distance>a.voices[victim].distance) then victim=i end end
        total-=a.voices[victim].cost or 1;self:audioRetire(a.voices[victim]);table.remove(a.voices,victim)
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
        elseif v.priority>=4 then critical+=v.cost or 1 else routine+=v.cost or 1 end
    end
    a.criticalCount=critical;a.routineCount=routine
    local target=(critical>0 or now<a.duckUntil) and .28 or 1
    a.duck=target< a.duck and target or a.duck+(target-a.duck)*(1-math.exp(-dt*5))
    self:audioOcclusion(now,dt)
    local criticalPeak,routinePeak=0,0
    for _,v in ipairs(a.voices) do
        local gain=self:audioGain(v)
        if v.farSound then
            local blend=math.clamp(((v.distance or 0)-40)/70,0,1)
            v.sound.Volume=gain*math.cos(blend*math.pi*.5);v.farSound.Volume=gain*math.sin(blend*math.pi*.5)
        else v.sound.Volume=gain end
        local sum=v.sound.Volume+(v.farSound and v.farSound.Volume or 0)
        if v.priority>=4 then criticalPeak+=sum else routinePeak+=sum end
        self:audioTreat(v,dt)
    end
    -- Conservative owned-FX peak ceiling, including both report layers. Real
    -- recordings are mastered below unity; this also bounds simultaneous stock
    -- fallbacks on a mono phone speaker. Critical voices receive first headroom.
    local criticalScale=criticalPeak>0 and math.min(1,.68/criticalPeak) or 1
    local routineScale=routinePeak>0 and math.min(1,(.82-criticalPeak*criticalScale)/routinePeak) or 1
    a.peakSum=criticalPeak*criticalScale+routinePeak*routineScale
    for _,v in ipairs(a.voices) do
        local scale=v.priority>=4 and criticalScale or routineScale
        v.sound.Volume*=scale;if v.farSound then v.farSound.Volume*=scale end
    end
    if now>=a.nextClean then
        a.nextClean=now+1
        for key,entry in pairs(a.last) do if now>=entry.untilTime then a.last[key]=nil;a.lastCount-=1 end end
        for id,untilTime in pairs(a.failed) do if now>=untilTime then a.failed[id]=nil end end
    end
    if not skipWorld then self:audioWorld(now) end
end
function FX:part(size,cf,color,shape)
    return U.make("Part",self.folder,{Size=size,CFrame=cf,Color=color,Shape=shape or Enum.PartType.Block,
        Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
end
function FX:tracer(a,b,energy)
    local dist=(b-a).Magnitude if dist<.05 then return end
    local p=self:part(Vector3.new(energy and .18 or .055,energy and .18 or .055,dist),CFrame.lookAt((a+b)*.5,b),energy and Color3.fromRGB(71,216,232) or Color3.fromRGB(255,210,127))
    Debris:AddItem(p,self.settings.lowEffects and .035 or .075)
    if not self.settings.lowEffects then
        self:particles(b,3,.38,.24,Color3.fromRGB(137,126,107),false)
    end
end
function FX:particles(position,count,lifetime,size,color,hot)
    local anchor=U.make("Part",self.folder,{Name=hot and "HotDebris" or "ImpactDust",Size=Vector3.new(.05,.05,.05),CFrame=CFrame.new(position),
        Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
    local emitter=U.make("ParticleEmitter",anchor,{Name="TransientParticles",Texture=hot and "rbxasset://textures/particles/fire_main.dds" or "rbxasset://textures/particles/smoke_main.dds",
        Rate=0,Lifetime=NumberRange.new(lifetime*.65,lifetime),Speed=NumberRange.new(hot and 7 or .7,hot and 15 or 2.5),
        SpreadAngle=Vector2.new(65,65),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-35,35),
        Acceleration=Vector3.new(0,hot and -12 or .8,0),Drag=hot and 4 or 1.5,LightEmission=hot and .7 or 0,LightInfluence=hot and .1 or .9,
        Color=ColorSequence.new(color),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.25),NumberSequenceKeypoint.new(.25,size),NumberSequenceKeypoint.new(1,hot and 0 or size*1.6)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,hot and .05 or .55),NumberSequenceKeypoint.new(.2,hot and .15 or .65),NumberSequenceKeypoint.new(1,1)})})
    emitter:Emit(count) Debris:AddItem(anchor,lifetime+.15) return anchor
end
function FX:muzzle(muzzle)
    if self.settings.lowEffects then return end
    local emitter=muzzle:FindFirstChild("MuzzleSmoke")
    if not emitter then emitter=U.make("ParticleEmitter",muzzle,{Name="MuzzleSmoke",Texture="rbxasset://textures/particles/smoke_main.dds",Rate=0,
        Lifetime=NumberRange.new(.12,.26),Speed=NumberRange.new(1,2.5),EmissionDirection=Enum.NormalId.Front,SpreadAngle=Vector2.new(12,12),
        Drag=2,Color=ColorSequence.new(Color3.fromRGB(142,140,130)),LightInfluence=1,
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.07),NumberSequenceKeypoint.new(1,.3)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.72),NumberSequenceKeypoint.new(1,1)})}) end
    emitter:Emit(2)
end
function FX:burst(position,radius,color)
    local anchor=self:particles(position,self.settings.lowEffects and 3 or 14,.8,math.min(radius*.4,3),Color3.fromRGB(88,84,76),false)
    local light=U.make("PointLight",anchor,{Color=color,Brightness=4,Range=math.min(radius*2,30),Shadows=false})
    Tween:Create(light,TweenInfo.new(.18),{Brightness=0}):Play()
    if not self.settings.lowEffects then self:particles(position,10,.5,.4,Color3.fromRGB(241,175,87),true) end
end
function FX:enemyDeath(data)
    if self.settings.lowEffects then return end
    -- The server retains the actual ragdoll for 30 seconds. Only dust is local.
    self:particles(data.position,5,.65,.45,Color3.fromRGB(112,106,92),false)
end
function FX:warning(data)
    local duration=data.duration or 1.8
    local parts={}
    local y=data.floorY or data.position.Y-3
    local map=workspace:FindFirstChild("DeadSignalMap")
    if not data.floorY and map then
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map};params.RespectCanCollide=true
        local hit=workspace:Raycast(data.position+Vector3.new(0,2,0),Vector3.new(0,-30,0),params)
        if hit then y=hit.Position.Y end
    end
    for i=1,(self.settings.lowEffects and 12 or 24) do
        local a=i*math.pi*2/(self.settings.lowEffects and 12 or 24)
        local p=self:part(Vector3.new(2.1,.06,.5),CFrame.new(data.position.X+math.cos(a)*data.radius,y+.06,data.position.Z+math.sin(a)*data.radius)*CFrame.Angles(0,-a,0),Color3.fromRGB(234,144,61))
        parts[#parts+1]=p
        p.Transparency=.25 Tween:Create(p,TweenInfo.new(duration),{Color=Color3.fromRGB(244,70,57)}):Play() Debris:AddItem(p,duration)
    end
    return parts
end
function FX:event(data)
    local id=data and data.id
    if self.eventId==id then return end
    for _,v in ipairs(self.eventLights or {}) do if v.light.Parent then v.light.Color=v.color;v.light.Brightness=v.brightness end end
    self.eventLights={} self.eventId=id
    if not id then return end
    local spec for _,e in ipairs(C.Evolution.events) do if e.id==id then spec=e break end end
    self:sound(data.cue or spec and spec.cue or "Round")
    local map=workspace:FindFirstChild("DeadSignalMap")
    if map then for _,p in ipairs(map:GetDescendants()) do
        if p.Name=="EmergencyLight" then
            local light=p:FindFirstChildOfClass("PointLight")
            if light and #self.eventLights<8 then
                self.eventLights[#self.eventLights+1]={light=light,color=light.Color,brightness=light.Brightness}
                light.Color=Color3.fromRGB(241,137,66);light.Brightness=math.max(.7,light.Brightness)
            end
        end
    end end
end
function FX:telegraph(data)
    self:sound(data.cue,data.position)
    local camera=workspace.CurrentCamera
    if camera and (camera.CFrame.Position-data.position).Magnitude>160 then return end
    if data.finish then
        local d=data.finish-data.position local flat=Vector3.new(d.X,0,d.Z)
        if flat.Magnitude>.1 then
            for n=1,5 do
                local at=data.position+flat*(n/5)-Vector3.new(0,1.4,0)
                local p=self:part(Vector3.new(.6,.08,.8),CFrame.lookAt(at,at+flat),Color3.fromRGB(248,179,86));Debris:AddItem(p,data.duration)
            end
        end
    else self:warning(data) end
end
function FX:hazardWarning(data)
    self.hazards=self.hazards or {}
    local camera=workspace.CurrentCamera
    self:sound(data.cue,data.position)
    if camera and (camera.CFrame.Position-data.position).Magnitude>160 then return end
    local ring=table.clone(data);ring.floorY=data.position.Y
    local parts=self:warning(ring)
    local anchor=self:part(Vector3.new(.1,.1,.1),CFrame.new(data.position),Color3.new(1,1,1));anchor.Transparency=1
    local gui=U.make("BillboardGui",anchor,{Size=UDim2.fromOffset(135,28),StudsOffset=Vector3.new(0,1.3,0),MaxDistance=70,AlwaysOnTop=false})
    U.make("TextLabel",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(24,24,20),BackgroundTransparency=.2,Text="!  BLAST ZONE  !",TextColor3=Color3.fromRGB(255,213,137),Font=Enum.Font.GothamBold,TextSize=13})
    parts[#parts+1]=anchor;Debris:AddItem(anchor,data.duration)
    self.hazards[data.id]={warnings=parts}
end
function FX:hazardBlast(data)
    self.hazards=self.hazards or {} local h=self.hazards[data.id] or {} self.hazards[data.id]=h
    for _,p in ipairs(h.warnings or {}) do p:Destroy() end h.warnings={}
    local camera=workspace.CurrentCamera
    if camera and (camera.CFrame.Position-data.position).Magnitude>130 then return end
    self:burst(data.position+Vector3.new(0,1,0),data.radius,Color3.fromRGB(248,157,71));self:sound("Grenade",data.position)
    if data.smoke>0 then
        local p=self:part(Vector3.new(.1,.1,.1),CFrame.new(data.position+Vector3.new(0,1.1,0)),Color3.new(1,1,1));p.Transparency=1;h.smoke=p
        local opacity=math.min(self.settings.lowEffects and .18 or .32,data.opacity)
        local emitter=U.make("ParticleEmitter",p,{Texture="rbxasset://textures/particles/smoke_main.dds",Rate=0,Lifetime=NumberRange.new(data.smoke*.7,data.smoke),
            Speed=NumberRange.new(.8,1.5),SpreadAngle=Vector2.new(65,65),Drag=2,Acceleration=Vector3.new(0,.9,0),
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,math.min(6,data.radius))}),
            Color=ColorSequence.new(Color3.fromRGB(72,71,66)),LightInfluence=.8,
            Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1-opacity),NumberSequenceKeypoint.new(.6,1-opacity*.6),NumberSequenceKeypoint.new(1,1)})})
        emitter:Emit(self.settings.lowEffects and 2 or 5);Debris:AddItem(p,data.smoke+.1)
    end
    if data.flames>0 then
        local p=self:part(Vector3.new(.1,.1,.1),CFrame.new(data.position),Color3.new(1,1,1));p.Transparency=1;h.fire=p
        U.make("ParticleEmitter",p,{Texture="rbxasset://textures/particles/fire_main.dds",Rate=self.settings.lowEffects and 4 or 10,Lifetime=NumberRange.new(.35,.6),
            Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(80,80),LightEmission=.8,LightInfluence=.1,
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.4),NumberSequenceKeypoint.new(.4,2.8),NumberSequenceKeypoint.new(1,0)}),
            Color=ColorSequence.new(Color3.fromRGB(255,166,68)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)})})
        Debris:AddItem(p,data.flames)
    end
    task.delay(math.max(data.smoke,data.flames)+.3,function() if self.hazards[data.id]==h then self.hazards[data.id]=nil end end)
end
function FX:hazardCounter(data)
    local h=self.hazards and self.hazards[data.id] if not h then return end
    local p if data.kind=="Vent" then p=h.smoke else p=h.fire end
    if p then p:Destroy() end
    if data.kind=="Vent" then h.smoke=nil else h.fire=nil end
end
function FX:clearHazards()
    for _,h in pairs(self.hazards or {}) do
        for _,p in ipairs(h.warnings or {}) do p:Destroy() end
        if h.smoke then h.smoke:Destroy() end if h.fire then h.fire:Destroy() end
    end self.hazards={}
end
function FX:animate(dt)
    self:audioUpdate(dt)
    self.animTime=self.animTime+dt local time=self.animTime
    local folder=workspace:FindFirstChild("DeadSignalEnemies") if not folder then return end
    local camera=workspace.CurrentCamera
    for _,model in ipairs(folder:GetChildren()) do
        local root=model:FindFirstChild("HumanoidRootPart") local torso=model:FindFirstChild("Torso")
        if root and torso and (root.Position-camera.CFrame.Position).Magnitude<180 then
            local cache=self.rigs[model]
            if not cache then
                cache={} for _,j in ipairs(model:GetDescendants()) do if j:IsA("Motor6D") then cache[#cache+1]=j end end
                self.rigs[model]=cache
            end
            if not model:GetAttribute("Dead") then
                local poses=NPCPose.sample(model,root,workspace:GetServerTimeNow())
                for _,j in ipairs(cache) do if j.Enabled then j.Transform=poses[j.Name] or CFrame.identity end end
            end
        end
    end
    for model,cache in pairs(self.rigs) do
        if model:GetAttribute("Dead") then
            for _,joint in ipairs(cache) do if joint.Parent then joint.Transform=CFrame.identity end end
            self.rigs[model]=nil
        elseif not model.Parent then self.rigs[model]=nil end
    end
    local map=workspace:FindFirstChild("DeadSignalMap")
    if map then
        if self.map~=map then
            if self.mapConnection then self.mapConnection:Disconnect() end
            self.map=map self.pickups={}
            local function added(p) if p:IsA("BasePart") and p.Name:sub(1,5)=="Drop_" then self.pickups[p]=true end end
            for _,p in ipairs(map:GetChildren()) do added(p) end
            self.mapConnection=map.ChildAdded:Connect(added)
        end
        local rescue=map:FindFirstChild("Rescue")
        if rescue and rescue:FindFirstChild("Rotor") then rescue.Rotor.CFrame=rescue.PrimaryPart.CFrame*CFrame.new(0,4,0)*CFrame.Angles(0,time*30,0) end
        -- Only a handful of drops are animated; no map-wide per-frame traversal.
        for p in pairs(self.pickups) do if not p.Parent then self.pickups[p]=nil else p.CFrame=CFrame.new(p.Position)*CFrame.Angles(time*.9,time*1.5,0) end end
    end
end
return FX
