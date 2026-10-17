-- Tuning and decisions are separated from Roblox objects for repeatable tests.
local D={}
D.tuning={minSpawnDistance=22,fallbackSpawnDistance=14,pathRequestsPerSecond=12,
    maxConcurrentPaths=3,targetSeconds=.65,quotaSettleSeconds=6,recoverySeconds=4,
    recoveryCooldown=22,crewHealth=.14,crewDamage=.05,crewSpeed=.025,weaponHealth=.12,
    gearStartRound=6,targetLoadWeight=.13,targetStickiness=.83,
    flankSeconds=1.75,flankCooldown=2.5,entryRecoverySeconds=16}
-- Canonical, optional map-owned window.entry schema. No alternate map schema.
function D.windowEntry(window)
    local d=window.entry
    if d==nil then return {kind="Window",legacy=true} end
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
    if type(d)~="table" or d.schema~=1 or type(d.id)~="string" or #d.id<1 or #d.id>96
        or d.kind~="Window" or d.room~=window.room or type(d.clearance)~="table" then return nil end
    for _,key in ipairs({"approach","breach","landing"}) do
        local cf=d[key];if typeof(cf)~="CFrame" then return nil end
        for _,n in ipairs({cf:GetComponents()}) do if not finite(n) then return nil end end
        if cf.UpVector.Y<.9 or math.abs(cf.LookVector.Y)>.35 then return nil end
    end
    local travel=d.landing.Position-d.approach.Position
    travel=Vector3.new(travel.X,0,travel.Z);if travel.Magnitude<.5 then return nil end
    for _,key in ipairs({"approach","breach","landing"}) do if d[key].LookVector:Dot(travel.Unit)<.7 then return nil end end
    if not finite(d.clearance.radius) or d.clearance.radius<=0 or d.clearance.radius>16
        or not finite(d.clearance.height) or d.clearance.height<=0 or d.clearance.height>32 then return nil end
    if d.allowedKinds~=nil then
        if type(d.allowedKinds)~="table" then return nil end
        local known={Shambler=true,Runner=true,Crawler=true,Hound=true,Stalker=true,Warden=true}
        local seen={} local count=0
        for key,kind in pairs(d.allowedKinds) do
            if type(key)~="number" or key%1~=0 or key<1 or key>#d.allowedKinds or not known[kind] or seen[kind] then return nil end
            seen[kind]=true;count+=1
        end
        if count~=#d.allowedKinds then return nil end
    end
    return d
end
function D.threat(crew,weaponTier,round)
    crew=math.clamp(crew,1,4)
    local gear=round>=D.tuning.gearStartRound and math.clamp(weaponTier or 0,0,2)*D.tuning.weaponHealth or 0
    return {health=1+(crew-1)*D.tuning.crewHealth+gear,damage=1+(crew-1)*D.tuning.crewDamage,speed=1+(crew-1)*D.tuning.crewSpeed}
end
function D.pacing(elapsed,health,downed,lastRecovery,now,phase)
    if phase=="Exfil" then return "Finale",1,1,false end
    if (health<.45 or downed>0) and now-lastRecovery>=D.tuning.recoveryCooldown then return "Recover",2.1,.72,true end
    local cycle=elapsed%27
    if cycle>=23 then return "Breathe",1.65,.8,false end
    if cycle>=9 then return "Pressure",.8,1,false end
    return "Build",1,1,false
end
function D.quota(base,spawned) return math.max(0,base-spawned) end
function D.spawnScore(distance,visible,usedAgo,nearby)
    if distance<D.tuning.fallbackSpawnDistance then return nil end
    return math.min(distance,120)*.14+(visible and -14 or 12)+math.min(usedAgo,15)-nearby*8
end
function D.event(round,phase,cfg,bossRound)
    if not cfg.enabled or phase=="Exfil" or bossRound or round<cfg.firstRound or #cfg.events==0 then return nil end
    if (round-cfg.firstRound)%math.max(1,cfg.interval)~=0 then return nil end
    return cfg.events[(math.floor((round-cfg.firstRound)/math.max(1,cfg.interval)))%#cfg.events+1]
end
function D.eliteRate(round,cfg)
    return round<cfg.eliteStart and 0 or math.min(cfg.eliteMax,cfg.eliteBase+(round-cfg.eliteStart)*cfg.eliteGrowth)
end
-- Roll inputs make rarity/composition decisions reproducible in tests.
function D.evolution(round,event,index,cfg,roll,comboRoll,counts)
    counts=counts or {} roll=roll or 1 comboRoll=comboRoll or 1
    if not cfg.enabled then return "Shambler",{} end
    local id=event and event.id local kind="Shambler" local mods={}
    if id=="Hunt" then kind="Hound";mods.Alpha=index==1 and (counts.alphas or 0)<cfg.maxAlphas
    elseif id=="Redline" then kind=index%3==0 and "Shambler" or "Runner";mods.Enraged=true
    elseif id=="IronMarch" then mods.Armored=true
    elseif id=="Critical" then kind=index%4==0 and "Crawler" or "Shambler";mods.Volatile=true
    elseif id=="Breach" then
        kind=index%3==0 and "Hound" or index%2==0 and "Runner" or "Shambler"
        if index%5==0 then mods.Enraged=true end
    end
    local stalkerAllowed=round>=cfg.stalkerStart and (counts.stalkers or 0)<cfg.maxStalkers
    if stalkerAllowed and ((id=="Breach" and index==7) or not event and roll<cfg.stalkerChance) then return "Stalker",{} end
    if not event then
        if round>=cfg.houndStart and roll>=.7 and roll<.7+cfg.houndChance then kind="Hound" end
        if comboRoll<D.eliteRate(round,cfg) then
            if kind=="Hound" then mods.Alpha=(counts.alphas or 0)<cfg.maxAlphas
            else local variants={"Enraged","Armored","Volatile"};mods[variants[index%3+1]]=true end
        end
    end
    -- One rare Ironbound per wave; no Volatile/Alpha stacking or triple modifiers.
    if round>=cfg.combinedStart and kind~="Hound" and mods.Armored and comboRoll<cfg.combinedChance and (counts.combined or 0)<cfg.maxCombined then mods.Enraged=true end
    return kind,mods
end
function D.modifiers(stats,mods,cfg)
    local out={hp=stats.hp,speed=stats.speed,damage=stats.damage}
    if not (mods.Enraged or mods.Armored or mods.Volatile or mods.Alpha) then return out end
    for key,name in pairs({Enraged="enraged",Armored="armored",Volatile="volatile",Alpha="alpha"}) do
        if mods[key] then local t=cfg[name];out.hp*=t.health;out.speed*=t.speed;out.damage*=t.damage end
    end
    out.hp=math.max(1,math.floor(out.hp));out.speed=math.min(24,out.speed);out.damage=math.min(65,math.floor(out.damage+.5))
    return out
end
function D.specialQuota(base,event) return event and math.max(6,math.floor(base*event.quota)) or base end
function D.blastDamage(round,cfg,mode) return math.min(cfg.maxDamage,cfg.damage+round*cfg.roundDamage)*(mode.damage or 1) end
function D.specialReward(round,cfg) return math.min(cfg.maxPoints,cfg.points+round*cfg.perRound) end
function D.canReward(run)
    return run.event~=nil and not run.eventRewarded and run.phase=="Wave" and run.spawnRemaining<=0 and not run.bossAlive
end
return D
