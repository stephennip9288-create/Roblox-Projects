-- One explicit extraction state machine; a cleared combat wave cannot end it.
local X={}
function X.step(run,stats,config,now,dt)
    if run.phase~="Exfil" then return end
    run.exfilStats=stats
    if run.bossSpawned and not run.bossAlive and not run.bossDefeatedAt then
        run.bossDefeatedAt=now run.spawnRemaining=0
        run.deadline=math.max(run.deadline,now+config.afterBossGrace)
    end
    if not run.bossDefeatedAt then run.exfilStage="Warden" run.exfilHint="Eliminate the Warden. The rescue beacon marks the boarding zone."
    elseif stats.contested then run.exfilStage="Clear" run.exfilHint="Clear infected from the marked boarding zone. Progress is paused."
    elseif stats.insideAlive<stats.alive or stats.downOutside>0 or stats.alive==0 then
        run.exfilStage="Rally" run.exfilHint="Bring the surviving crew to the beacon. Revive anyone stranded outside."
    else
        run.exfilStage="Board" run.exfilHint="Hold the marked zone until boarding reaches 100%."
        run.exfilProgress=math.min(100,(run.exfilProgress or 0)+math.clamp(dt,0,1)*100/config.holdSeconds)
    end
    if run.exfilProgress>=100 and run.bossDefeatedAt then return true,"RESCUE CONFIRMED / YOUR CREW EXTRACTED" end
    if now>=run.deadline then
        local reason=not run.bossDefeatedAt and "EXTRACTION FAILED / THE WARDEN HELD THE SIGNAL"
            or stats.contested and "EXTRACTION FAILED / THE BOARDING ZONE WAS OVERRUN"
            or "EXTRACTION FAILED / THE CREW DID NOT BOARD BEFORE THE WINDOW CLOSED"
        return false,reason
    end
end
function X.title(stage)
    return ({Warden="ELIMINATE THE WARDEN",Clear="CLEAR THE BOARDING ZONE",Rally="RALLY AT THE BEACON",Board="BOARDING"})[stage] or "EXTRACTION"
end
return X
