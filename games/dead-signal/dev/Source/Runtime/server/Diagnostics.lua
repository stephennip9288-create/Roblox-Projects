-- Command Bar helpers work only in a running Studio server session.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local D={} local ctx
function D.init(context) ctx=context end
local function ready()
    assert(RunService:IsStudio(),"DEAD SIGNAL diagnostics are available only in Studio.")
    assert(ctx and ctx.game,"Press Play / Start Server before using diagnostics.")
    return ctx
end
function D.status()
    local c=ready() local info={version=C.Version,phase=c.run.phase,map=c.run.map,mode=c.run.mode,round=c.run.round,enemies=c.enemies:count(),pending=c.run.spawnRemaining or 0,power=c.run.power,signal=c.run.signal,pathRecoveries=c.enemies.recovered,players={}}
    info.role=c.role or "Preview" info.placeId=game.PlaceId
    info.corpses=#c.enemies.corpses:GetChildren() info.activePaths=c.enemies.activePaths or 0
    info.retiredNavigation=c.enemies.retired or 0
    info.director=c.run.directorStage info.activeCrew=c.run.activeCrew info.plannedTotal=c.run.directorTotal
    info.routeLinks=c.map and #c.map.doors or 0
    info.routes={} for _,e in pairs(c.enemies.list) do table.insert(info.routes,{id=e.id,kind=e.kind,replans=e.replans or 0,pathFailures=e.pathFailures or 0,
        target=e.target and e.target.UserId or nil,secondsWithoutMovement=os.clock()-e.lastMoved,recoveries=e.recoveryAttempts or 0,
        entered=e.entered,hasPath=e.path~=nil,computing=e.computing,waypoint=e.index,navigationState=e.model:GetAttribute("NavigationState")}) end
    if c.lobbyService then info.dispatch=c.lobbyService:state(Players:GetPlayers()[1]) end
    for player,p in pairs(c.players) do table.insert(info.players,{name=player.Name,status=p.status,health=p.health,points=p.points,bay=p.bay,travelling=p.travelling,escapeCorrections=p.escapeCorrections or 0}) end
    print(game:GetService("HttpService"):JSONEncode(info)) return info
end
-- Opt-in only. No remote, automatic loop or production-visible attributes.
function D.navigation(enabled)
    local c=ready();assert(c.enemies and c.map,"Start a match first.")
    if enabled==false then c.enemies.navigationDebug=nil
    elseif enabled==true then
        c.enemies.navigationDebug={started=os.clock(),events={},cursor=0,count=0,counters={}}
    end
    return require(script.Parent.Navigation).snapshot(c.enemies,os.clock())
end
function D.start(map,mode)
    local c=ready()
    if c.game:isCombat() or c.run.phase=="Results" then c.game:finish(false,"Studio reset") c.game:reset() end
    for _,player in ipairs(Players:GetPlayers()) do local p=c.players[player] if p then p.ready=true end end
    return c.game:start(map or "Station",mode or "Standard")
end
function D.points(amount)
    local c=ready() amount=math.clamp(tonumber(amount) or 25000,0,1000000)
    for _,p in pairs(c.players) do if p.participating then p.points=amount end end return D.status()
end
function D.openAll()
    local c=ready() assert(c.map,"Start a match first.")
    c.map.navigationRevision=(c.map.navigationRevision or 0)+1
    for _,room in ipairs(c.map.rooms) do room.unlocked=true end
    for _,door in ipairs(c.map.doors) do
        door.open=true door.part.Transparency=1 door.part.CanCollide=false door.part.CanQuery=false
        for _,obj in ipairs(door.part:GetDescendants()) do if obj:IsA("BasePart") then obj.Transparency=1 obj.CanCollide=false obj.CanQuery=false elseif obj:IsA("SurfaceGui") or obj:IsA("ProximityPrompt") then obj.Enabled=false end end
    end
end
function D.round(number)
    local c=ready() assert(c.map,"Start a match first.") c.enemies:clear() c.run.round=math.clamp(math.floor(tonumber(number) or 1),1,100)-1 c.game:wave() return D.status()
end
function D.clearWave()
    local c=ready() c.run.spawnRemaining=0 c.enemies:clear()
    if c.director then c.director.spawned=100000 end
end
function D.hurt(name,amount)
    local c=ready() local player=name and Players:FindFirstChild(name) or Players:GetPlayers()[1]
    assert(player,"No player found.") c.players[player].invulnerableUntil=0 c.combat:hurt(player,tonumber(amount) or 200) return D.status()
end
function D.weapon(id,tier)
    local c=ready() assert(C.Weapons[id],"Use a weapon ID from Config.Weapons.")
    for player,p in pairs(c.players) do if p.participating and p.status=="Alive" then c.combat:give(player,id,math.clamp(tonumber(tier) or 0,0,2)) end end
end
function D.quest()
    local c=ready() assert(c.map,"Start a match first.") D.openAll()
    c.run.power=true c.run.fuses=3 c.run.linked=true c.run.signal=true
    require(script.Parent.MapBuilder).power(c.map)
    c.game:broadcast("Studio: quest complete. Use round(15) to test rescue.","cyan")
end
function D.extract()
    local c=ready() D.quest() if c.run.round<15 then c.run.round=15 end c.game:exfil()
end
function D.mobile(layout)
    local c=ready() assert(layout=="Tap" or layout=="Left" or layout=="Classic","Use Tap, Left or Classic.")
    for player,profile in pairs(c.data.profiles) do
        profile.data.settings.fireLayout=layout c.data:send(player)
    end
    return D.status()
end
function D.pursuit(kind)
    local c=ready() assert(c.map,"Start a match first.") D.openAll()
    local windows=c.map.windows local _,_,_,_,crew=c.director:crew() local farthest,distance
    for _,w in ipairs(windows) do local nearest=math.huge
        for _,p in ipairs(crew) do nearest=math.min(nearest,(p.root.Position-w.inside).Magnitude) end
        if not distance or nearest>distance then farthest=w distance=nearest end
    end
    assert(farthest,"No spawn window.") c.enemies:spawn(kind or "Shambler",farthest,farthest.inside)
    print("Pursuit trial initial distance",distance) return D.status()
end
function D.ragdoll(kind)
    local c=ready() assert(c.map,"Start a match first.")
    local valid={Shambler=true,Runner=true,Hound=true,Crawler=true,Warden=true}
    assert(valid[kind],"Use Shambler, Runner, Hound, Crawler or Warden.")
    local root=require(RS.DeadSignal.Util).root(Players:GetPlayers()[1]) assert(root,"No player character.")
    local offset=root.CFrame.LookVector*8 local at=root.Position+offset
    local enemy=c.enemies:spawn(kind,c.map.windows[1],at)
    task.delay(.8,function() if not enemy.dead then c.enemies:kill(enemy,nil,false,false) end end)
    return enemy.id
end
return D
