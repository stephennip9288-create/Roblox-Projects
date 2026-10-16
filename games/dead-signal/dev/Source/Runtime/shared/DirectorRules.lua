-- Tuning and decisions are separated from Roblox objects for repeatable tests.
local D={}
D.tuning={minSpawnDistance=22,fallbackSpawnDistance=14,pathRequestsPerSecond=12,
    maxConcurrentPaths=3,targetSeconds=.65,quotaSettleSeconds=6,recoverySeconds=4,
    recoveryCooldown=22,crewHealth=.14,crewDamage=.05,crewSpeed=.025,weaponHealth=.12,
    gearStartRound=6,targetLoadWeight=.13,targetStickiness=.83}
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
return D
