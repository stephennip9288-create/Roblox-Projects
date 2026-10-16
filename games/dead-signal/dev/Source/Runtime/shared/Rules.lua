-- Pure gameplay rules: no Roblox services, so these are independently testable.
local R = {}
function R.clamp(v, a, b) return math.max(a, math.min(b, v)) end
-- Tuned above v1.6 pressure, with interpolated milestones and a bounded opening.
R.RoundCurve = {
    {round=1, count=8, hp=65, walk=5, damage=16, attack=1.95, spawn=2.4, breach=1.8, grace=.85, active=5},
    {round=3, count=14, hp=95, walk=6, damage=19, attack=1.85, spawn=2.15, breach=1.7, grace=.8, active=7},
    {round=5, count=20, hp=150, walk=7.4, damage=22, attack=1.7, spawn=1.9, breach=1.55, grace=.75, active=9},
    {round=8, count=32, hp=220, walk=9.5, damage=27, attack=1.5, spawn=1.65, breach=1.4, grace=.65, active=13},
    {round=10, count=42, hp=300, walk=11, damage=30, attack=1.4, spawn=1.4, breach=1.3, grace=.6, active=17},
    {round=15, count=70, hp=570, walk=13, damage=36, attack=1.2, spawn=.95, breach=1.15, grace=.5, active=24},
    {round=20, count=105, hp=900, walk=14.5, damage=41, attack=1.1, spawn=.8, breach=1.05, grace=.45, active=28},
    {round=30, count=170, hp=1800, walk=15.6, damage=46, attack=1.05, spawn=.65, breach=1, grace=.4, active=32},
}
function R.roundValue(round, key)
    round = math.max(1, round)
    for i=2,#R.RoundCurve do
        local a,b=R.RoundCurve[i-1],R.RoundCurve[i]
        if round<=b.round then return a[key]+(b[key]-a[key])*(round-a.round)/(b.round-a.round) end
    end
    local last=R.RoundCurve[#R.RoundCurve] local extra=round-last.round
    if key=="hp" then return math.min(60000,last.hp*1.055^extra) end
    if key=="count" then return math.min(320,last.count+extra*5.2) end
    if key=="walk" then return math.min(16,last.walk+extra*.08) end
    if key=="spawn" then return math.max(.45,last.spawn-extra*.006) end
    if key=="active" then return math.min(40,last.active+extra*.5) end
    return last[key]
end
function R.waveCount(round, players, mode)
    return math.min(320, math.ceil(R.roundValue(round,"count")*(1+(math.clamp(players,1,4)-1)*.65)*mode.enemies))
end
function R.enemyHealth(round, kind, mode, players, warden)
    local base = R.roundValue(round,"hp") * mode.health
    if kind == "Hound" then base = base * 0.7 elseif kind == "Crawler" then base = base * 0.65 elseif kind=="Stalker" then base=base*.9
    elseif kind == "Warden" then
        local c=warden or {baseHealth=60000,roundHealth=90,extraPlayerHealth=.65}
        base=math.max(c.baseHealth,R.roundValue(round,"hp")*c.roundHealth)*mode.health*(1+math.max(0,(players or 1)-1)*c.extraPlayerHealth)
    end
    return math.floor(base)
end
function R.enemySpeed(round, kind)
    local walk=R.roundValue(round,"walk")
    if kind=="Stalker" then return math.min(17,walk+4) end
    if kind=="Warden" then return 10 elseif kind=="Hound" then return math.min(22,walk+3.5)
    elseif kind=="Crawler" then return math.min(9,walk*.65) elseif kind=="Runner" then return math.min(21,walk+4) end
    return walk
end
function R.enemyDamage(round,kind,mode)
    local damage=R.roundValue(round,"damage")
    if kind=="Warden" then damage=damage+25 elseif kind=="Hound" or kind=="Crawler" then damage=damage*.85 end
    return math.floor(damage*mode.damage+.5)
end
function R.enemyAttackInterval(round,kind)
    local interval=R.roundValue(round,"attack")
    return kind=="Hound" and math.max(1,interval*.85) or interval
end
function R.enemyAttackRange(kind) return kind=="Warden" and 5 or 3.3 end
function R.enemyHitGrace(round) return R.roundValue(round,"grace") end
function R.breachInterval(round) return R.roundValue(round,"breach") end
function R.spawnInterval(round,players,exfil)
    local interval=R.roundValue(round,"spawn")/(1+(players-1)*.12)
    return exfil and math.max(.65,interval*.75) or interval
end
function R.activeLimit(round,players,maxEnemies)
    return math.min(maxEnemies or 40,math.floor(R.roundValue(round,"active"))+4*(math.clamp(players,1,4)-1))
end
function R.isWardenRound(round) return round>=20 and round%10==0 end
function R.isHoundRound(round) return round>=12 and (round-12)%6==0 and not R.isWardenRound(round) end
function R.runnerChance(round) return round<8 and 0 or math.min(.35,.04+(round-8)*.018) end
function R.crawlerChance(round) return round<10 and 0 or math.min(.13,.05+(round-10)*.01) end
function R.eventName(round)
    if R.isHoundRound(round) then return "THE HOUNDS ARE LOOSE" end
    if R.isWardenRound(round) then return "WARDEN SIGNAL DETECTED" end
    return ""
end
function R.weaponStats(def, tier, perks)
    local p = perks or {}
    local damage = def.damage * (tier > 0 and 3.6 or 1) * (tier > 1 and 1.65 or 1) * (p.Overdrive and 1.25 or 1)
    return {damage=damage, mag=math.floor(def.mag * (tier > 0 and 1.5 or 1)),
        reserve=math.floor(def.reserve * (tier > 0 and 1.5 or 1)),
        reload=def.reload * (p.FastHands and 0.5 or 1), interval=60 / def.rpm,
        name=tier > 0 and def.upgraded or def.name}
end
function R.health(perks) return perks.Ironheart and 200 or 100 end
function R.stamina(perks) return perks.Marathon and 200 or 100 end
function R.reviveTime(perks) return perks.Lifeline and 1.4 or 3 end
function R.boxPrice(effects, now) return (effects.Sale or 0) > now and 10 or 950 end
function R.refillPrice(def, tier) return tier > 0 and 2500 or math.floor(def.cost * 0.45) end
function R.rank(xp) return math.floor(math.sqrt(math.max(0, xp) / 160)) + 1 end
function R.rankFloor(rank) return (rank - 1) ^ 2 * 160 end
function R.runRewards(stats, mode, win)
    local xp = math.floor((stats.kills * 8 + stats.headshots * 5 + stats.rounds * 80 + stats.revives * 75 + (win and 700 or 0)) * mode.xp)
    local credits = math.floor(stats.kills / 6) + stats.rounds * 8 + (win and 160 or 0)
    return xp, credits
end
function R.finite(x) return type(x) == "number" and x == x and x > -math.huge and x < math.huge end
function R.majority(n) return math.max(1, math.ceil(n * 0.6)) end
function R.validSetting(key, value)
    if key == "volume" then return R.finite(value) and value >= 0 and value <= 1 end
    if key == "fov" then return R.finite(value) and value >= 70 and value <= 95 end
    if key == "shake" then return R.finite(value) and value >= 0 and value <= 1 end
    if key == "aimAssist" or key == "hitmarkers" or key == "lowEffects" then return type(value) == "boolean" end
    return require(script.Parent.ControlSettings).valid(key,value)
end
return R
