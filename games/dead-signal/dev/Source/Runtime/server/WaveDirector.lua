local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local Rules=require(RS.DeadSignal.DirectorRules)
local D={} D.__index=D
function D.new(ctx) return setmetatable({ctx=ctx,lastRecovery=-100,stage="Build",windowUse={},spawned=0},D) end
function D:crew()
    local alive,downed,health,gear,list=0,0,0,0,{}
    for player,p in pairs(self.ctx.players) do
        if player.Parent and p.participating and not p.travelling then
            local root=U.root(player)
            if p.status=="Alive" and root then
                alive=alive+1 health=health+p.health/R.health(p.perks) local tier=0
                for _,g in ipairs(p.guns or {}) do tier=math.max(tier,g.tier or 0) end
                gear=gear+tier table.insert(list,{player=player,root=root})
            elseif p.status=="Down" then downed=downed+1 end
        end
    end
    return alive,downed,alive>0 and health/alive or 0,alive>0 and gear/alive or 0,list
end
function D:begin(now)
    self.started=now self.lastRecovery=-100 self.windowUse={} self.spawned=0 self.stage="Build"
    local crew=self:crew()
    self.crewAtStart=math.max(1,crew) self.quotaCrew=self.crewAtStart self.changeAt=nil
end
function D:stats(kind,mods)
    local crew,_,_,gear=self:crew() local run=self.ctx.run local threat=Rules.threat(crew,gear,run.round)
    local hp=R.enemyHealth(run.round,kind,C.Modes[run.mode],math.max(1,crew),C.Warden)
    local stats={hp=kind=="Warden" and hp or math.floor(hp*threat.health),
        speed=math.min(kind=="Hound" and 23 or kind=="Runner" and 22 or 16,R.enemySpeed(run.round,kind)*threat.speed),
        damage=math.floor(R.enemyDamage(run.round,kind,C.Modes[run.mode])*threat.damage+.5)}
    return kind=="Warden" and stats or Rules.modifiers(stats,mods or {},C.Evolution)
end
function D:budget(now)
    local crew,downed,health=self:crew() local run=self.ctx.run
    if crew~=self.quotaCrew then
        if self.pendingCrew~=crew then self.pendingCrew=crew self.changeAt=now end
        if crew>self.quotaCrew or now-(self.changeAt or now)>=Rules.tuning.quotaSettleSeconds then
            self.quotaCrew=crew self.changeAt=nil self.pendingCrew=nil
        end
    else self.changeAt=nil self.pendingCrew=nil end
    if run.phase=="Wave" then
        local total=R.waveCount(run.round,math.max(1,self.quotaCrew),C.Modes[run.mode])
        total=run.event and Rules.specialQuota(total,run.event) or run.special and math.floor(total*.6) or total
        run.spawnRemaining=Rules.quota(total,self.spawned) run.directorTotal=math.max(total,self.spawned)
    end
    local stage,interval,cap,recover=Rules.pacing(now-(self.started or now),health,downed,self.lastRecovery,now,run.phase)
    if recover then self.lastRecovery=now self.recoverUntil=now+Rules.tuning.recoverySeconds end
    if now<(self.recoverUntil or 0) and run.phase~="Exfil" then stage="Recover" interval=2.1 cap=.72 end
    self.stage=stage run.directorStage=stage run.activeCrew=crew
    local limit=math.max(2,math.floor(R.activeLimit(run.round,math.max(1,crew),C.MaxEnemies)*cap))
    return crew>0 and limit or 0,R.spawnInterval(run.round,math.max(1,crew),run.phase=="Exfil")*interval
end
function D:window(now)
    local _,_,_,_,players=self:crew() local best,score,fallback,farthest=nil,-math.huge,nil,-math.huge
    for _,window in ipairs(self.ctx.map.windows) do if self.ctx.map.rooms[window.room].unlocked then
        local distance,visible=math.huge,false
        for _,p in ipairs(players) do
            distance=math.min(distance,(p.root.Position-window.inside).Magnitude)
            if self.ctx.enemies:clearSight(window.inside,p.root.Position) then visible=true end
        end
        local nearby=0 for _,e in pairs(self.ctx.enemies.list) do if (e.root.Position-window.inside).Magnitude<18 then nearby=nearby+1 end end
        local value=Rules.spawnScore(distance,visible,now-(self.windowUse[window] or -30),nearby)
        if value and distance>farthest then fallback=window farthest=distance end
        if value and distance>=Rules.tuning.minSpawnDistance and value>score then best=window score=value end
    end end
    local chosen=best or fallback
    if chosen then self.windowUse[chosen]=now end
    return chosen
end
function D:spawnedOne() self.spawned=self.spawned+1 end
return D
