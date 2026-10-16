local RS=game:GetService("ReplicatedStorage")
local PF=game:GetService("PathfindingService")
local U=require(RS.DeadSignal.Util)
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local Rigs=require(script.Parent.EnemyRigs)
local Navigation=require(script.Parent.Navigation)
local Movement=require(RS.DeadSignal.Movement)
local DirectorRules=require(RS.DeadSignal.DirectorRules)
local E={} E.__index=E
function E.new(ctx)
    local old=workspace:FindFirstChild("DeadSignalEnemies") if old then old:Destroy() end
    local bodies=workspace:FindFirstChild("DeadSignalCorpses") if bodies then bodies:Destroy() end
    return setmetatable({ctx=ctx,list={},nextId=0,folder=U.make("Folder",workspace,{Name="DeadSignalEnemies"}),
        corpses=U.make("Folder",workspace,{Name="DeadSignalCorpses"}),pathBudget=0,pathTokens=4,pathBudgetAt=os.clock(),recovered=0,targetLoads={}},E)
end
function E:spawn(kind,window,position)
    self.nextId=self.nextId+1 local id=self.nextId
    local pos=position or window.outside
    if not position then
        local outward=Vector3.new(pos.X-window.inside.X,0,pos.Z-window.inside.Z).Unit
        local tangent=Vector3.new(outward.Z,0,-outward.X) local scale=self.ctx.map.scale or 1
        for slot=0,24 do
            local column=slot%5 local lateral=column==0 and 0 or (column%2==1 and 1 or -1)*math.ceil(column/2)
            local candidate=pos+tangent*(lateral*4*scale)+outward*(math.floor(slot/5)*4*scale)
            local free=true
            for _,other in pairs(self.list) do
                local d=candidate-other.root.Position
                if not other.dead and Vector3.new(d.X,0,d.Z).Magnitude<3.6*scale then free=false break end
            end
            if free then pos=candidate break end
        end
    end
    local model,root,hum=Rigs.build(self.folder,kind,pos,id)
    local stats=self.ctx.director and self.ctx.director:stats(kind)
    local hp=stats and stats.hp or R.enemyHealth(self.ctx.run.round,kind,C.Modes[self.ctx.run.mode],math.max(1,self.ctx.game:aliveCount()),C.Warden)
    Movement.noJump(hum)
    hum.MaxHealth=hp hum.Health=hp hum.WalkSpeed=stats and stats.speed or R.enemySpeed(self.ctx.run.round,kind)
    model:SetAttribute("EnemyId",id) model:SetAttribute("MaxHP",hp) model:SetAttribute("HP",hp)
    local now=os.clock()
    local enemy={id=id,model=model,root=root,hum=hum,kind=kind,hp=hp,maxHP=hp,window=window,
        entered=position~=nil,attack=0,nextPath=0,index=1,path=nil,computing=false,
        shock=now+8,lastPosition=pos,lastMoved=now,spawned=now,runId=self.ctx.run.id,
        damage=stats and stats.damage or R.enemyDamage(self.ctx.run.round,kind,C.Modes[self.ctx.run.mode]),targetAt=now+(id%7)*.07,phase=1,attackDamage={},damageWindow=now,windowDamage=0}
    self.list[id]=enemy
    hum.Died:Connect(function() if self.list[id] then self:kill(enemy,nil,false,false) end end)
    return enemy
end
function E:count() return U.count(self.list) end
function E:damage(enemy,amount,player,head,attack,damageKind)
    if not enemy or enemy.dead or not self.list[enemy.id] then return false end
    if not R.finite(amount) or amount<=0 then return false end
    if enemy.kind=="Warden" then
        local now=os.clock()
        if now-enemy.damageWindow>=1 then enemy.damageWindow=now enemy.windowDamage=0 enemy.attackDamage={} end
        -- Pellets, splash and chain effects from one trigger share the same cap.
        local key=attack or "environment"
        local used=enemy.attackDamage[key] or 0
        amount=math.min(amount,enemy.maxHP*C.Warden.attackCap-used,enemy.maxHP*C.Warden.secondCap-enemy.windowDamage)
        if enemy.overloadUntil and now<enemy.overloadUntil then amount=amount*.45 end
        local threshold=enemy.phase==1 and .70 or enemy.phase==2 and .35 or 0
        amount=math.max(0,math.min(amount,enemy.hp-enemy.maxHP*threshold))
        enemy.attackDamage[key]=used+amount enemy.windowDamage=enemy.windowDamage+amount
        if amount<=0 then return false end
        if threshold>0 and enemy.hp-amount<=enemy.maxHP*threshold+.001 then
            enemy.phase=enemy.phase+1 enemy.overloadUntil=now+C.Warden.overloadSeconds
            enemy.model:SetAttribute("BossPhase",enemy.phase) enemy.model:SetAttribute("OverloadUntil",workspace:GetServerTimeNow()+C.Warden.overloadSeconds)
            enemy.hum.WalkSpeed=10+(enemy.phase-1)*1.2
            self.ctx.feed:FireAllClients("Banner",{text="WARDEN PHASE "..enemy.phase.." · ARMOR OVERLOAD",color="amber"})
            self.ctx.feed:FireAllClients("ShockWarning",{position=enemy.root.Position,radius=22,duration=2})
            enemy.shockAt=now+2 enemy.shockPosition=enemy.root.Position enemy.shock=now+7
            for _=1,2 do if self:count()<C.MaxEnemies then self:spawn("Runner",enemy.window,enemy.root.Position+Vector3.new(math.random(-4,4),0,math.random(-4,4))) end end
        end
    end
    enemy.hp=math.max(0,enemy.hp-amount)
    enemy.model:SetAttribute("HP",enemy.hp)
    if enemy.hp<=0 then self:kill(enemy,player,head,true) return true end
    enemy.hum.Health=math.max(1,enemy.hp)
    return false
end
function E:kill(enemy,player,head,drops)
    if enemy.dead then return end enemy.dead=true Navigation.invalidate(enemy) self.list[enemy.id]=nil
    if player and self.ctx.players[player] then
        local p=self.ctx.players[player]
        if p.participating then
            p.stats.kills=p.stats.kills+1 if head then p.stats.headshots=p.stats.headshots+1 end
            self.ctx.game:addPoints(player,head and C.Economy.headshot or C.Economy.kill)
        end
    end
    if enemy.kind=="Warden" then self.ctx.run.bossAlive=false end
    local pos=enemy.root.Position
    self.ctx.feed:FireAllClients("EnemyDeath",{id=enemy.id,position=pos,kind=enemy.kind,headshot=head,look=enemy.root.CFrame.LookVector})
    Rigs.corpse(enemy.model,self.corpses)
    if drops and math.random()<.055 and self.ctx.run.phase=="Wave" then self.ctx.game:drop(pos) end
end
function E:clear(keepCorpses)
    for _,e in pairs(self.list) do e.dead=true Navigation.invalidate(e) e.model:Destroy() end
    self.list={}
    if not keepCorpses then for _,m in ipairs(self.corpses:GetChildren()) do m:Destroy() end end
end
function E:target(enemy,now)
    local current=enemy.target local state=current and self.ctx.players[current] local root=current and U.root(current)
    local valid=state and current.Parent and state.participating and state.status=="Alive" and not state.travelling and root
    if valid and now<(enemy.targetAt or 0) then return current,(root.Position-enemy.root.Position).Magnitude end
    enemy.targetAt=now+DirectorRules.tuning.targetSeconds+(enemy.id%5)*.035
    local target,distance,minimum=nil,math.huge,math.huge
    for plr,p in pairs(self.ctx.players) do
        local pr=U.root(plr)
        if plr.Parent and p.participating and p.status=="Alive" and not p.travelling and pr then
            local d=(pr.Position-enemy.root.Position).Magnitude
            local load=math.max(0,(self.targetLoads[plr] or 0)-(current==plr and 1 or 0))
            local score=d*(1+math.min(load,10)*DirectorRules.tuning.targetLoadWeight)*(current==plr and DirectorRules.tuning.targetStickiness or 1)
            if score<minimum then target=plr distance=d minimum=score end
        end
    end
    if current~=target then
        if current then self.targetLoads[current]=math.max(0,(self.targetLoads[current] or 0)-1) end
        if target then self.targetLoads[target]=(self.targetLoads[target] or 0)+1 end
        enemy.target=target enemy.route=nil Navigation.invalidate(enemy)
    end
    return target,distance
end
function E:clearSight(a,b)
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
    params.CollisionGroup="DeadSignalShots"
    params.FilterDescendantsInstances={self.ctx.map.model}
    return not workspace:Raycast(a,b-a,params)
end
function E:recover(enemy)
    if enemy.dead then return end
    local attempts=(enemy.recoveryAttempts or 0)+1
    if attempts>=3 and enemy.kind~="Warden" then
        -- A broken final route must not hold an ordinary wave forever. No kill,
        -- points or drop is credited for navigation retirement.
        self.retired=(self.retired or 0)+1 self:kill(enemy,nil,false,false) return
    end
    local hp=enemy.hp local rewards=enemy.hitRewards local kind=enemy.kind local window=enemy.window
    local maxHP,phase,overload=enemy.maxHP,enemy.phase,enemy.overloadUntil
    enemy.dead=true Navigation.invalidate(enemy) self.list[enemy.id]=nil enemy.model:Destroy()
    local nextWindow=self.ctx.director and self.ctx.director:window(os.clock()) or window
    local replacement=self:spawn(kind,nextWindow or window)
    replacement.recoveryAttempts=attempts
    replacement.hp=hp replacement.hum.Health=math.max(1,hp) replacement.hitRewards=rewards
    replacement.damage=enemy.damage replacement.maxHP=maxHP replacement.hum.MaxHealth=maxHP replacement.phase=phase replacement.overloadUntil=overload
    replacement.model:SetAttribute("MaxHP",maxHP) replacement.model:SetAttribute("BossPhase",phase)
    replacement.model:SetAttribute("HP",hp) self.recovered=self.recovered+1
end
function E:tick(now)
    if not self.ctx.map then return end
    self.pathTokens=math.min(4,self.pathTokens+math.max(0,now-self.pathBudgetAt)*DirectorRules.tuning.pathRequestsPerSecond)
    self.pathBudgetAt=now self.pathBudget=math.floor(self.pathTokens)
    self.targetLoads={}
    for _,e in pairs(self.list) do if e.target then self.targetLoads[e.target]=(self.targetLoads[e.target] or 0)+1 end end
    self.crowd={}
    for _,e in pairs(self.list) do
        local pos=e.root.Position local key=math.floor(pos.X/8)..":"..math.floor(pos.Z/8)
        self.crowd[key]=self.crowd[key] or {} table.insert(self.crowd[key],e)
    end
    local scheduled={}
    for _,enemy in pairs(self.list) do table.insert(scheduled,enemy) end
    table.sort(scheduled,function(a,b) return a.id<b.id end)
    local start=#scheduled>0 and (self.scheduleCursor or 0)%#scheduled+1 or 1
    -- Rotate budget access so low IDs cannot consume every path request forever.
    for offset=1,#scheduled do
        local enemy=scheduled[(start+offset-2)%#scheduled+1]
        if not enemy.root.Parent then self:recover(enemy)
        elseif not enemy.entered then
            local window=enemy.window
            enemy.hum:MoveTo(enemy.root.Position)
            if window.count<=0 then
                if now>=(window.nextEntry or 0) then
                    local at=Navigation.entryPoint(self,enemy,window)
                    if at then
                        window.nextEntry=now+.35
                        enemy.model:PivotTo(CFrame.lookAt(at,at+(window.inside-window.outside).Unit))
                        enemy.entered=true enemy.lastMoved=now enemy.lastPosition=at
                        self.ctx.feed:FireAllClients("Vault",{position=at})
                    end
                end
            elseif now>window.nextTear then
                window.nextTear=now+R.breachInterval(self.ctx.run.round) window.boards[window.count].Transparency=1 window.count=window.count-1
                self.ctx.feed:FireAllClients("Board",{position=window.part.Position,count=window.count})
            end
        else
            local target,distance=self:target(enemy,now) local tr=target and U.root(target)
            if tr then
                local direct=distance<R.enemyAttackRange(enemy.kind)+1 and self:clearSight(enemy.root.Position,tr.Position)
                if enemy.windup and now>=enemy.windup then
                    enemy.windup=nil
                    local victim=enemy.windupTarget local vp=victim and self.ctx.players[victim] local vr=victim and U.root(victim)
                    enemy.windupTarget=nil
                    if vp and vp.participating and vp.status=="Alive" and vr and (vr.Position-enemy.root.Position).Magnitude<R.enemyAttackRange(enemy.kind)+.5
                        and self:clearSight(enemy.root.Position,vr.Position) then
                        self.ctx.combat:hurt(victim,enemy.damage,enemy.root.Position,"Enemy")
                    end
                elseif not enemy.windup and distance<R.enemyAttackRange(enemy.kind) and direct and now>enemy.attack then
                    enemy.attack=now+R.enemyAttackInterval(self.ctx.run.round,enemy.kind)
                    enemy.windupTarget=target enemy.windup=now+(enemy.kind=="Hound" and .32 or enemy.kind=="Warden" and .65 or .45)
                    enemy.model:SetAttribute("AttackAt",workspace:GetServerTimeNow())
                    self.ctx.feed:FireAllClients("EnemyAttack",{id=enemy.id,position=enemy.root.Position,kind=enemy.kind})
                end
                if enemy.kind=="Warden" then
                    if enemy.shockAt and now>=enemy.shockAt then
                        enemy.shockAt=nil enemy.model:SetAttribute("Charging",false)
                        local radius=20+(enemy.phase-1)*2
                        self.ctx.feed:FireAllClients("Shock",{position=enemy.shockPosition,radius=radius})
                        for plr,p in pairs(self.ctx.players) do
                            local pr=U.root(plr)
                            if p.participating and p.status=="Alive" and pr and (pr.Position-enemy.shockPosition).Magnitude<radius and self:clearSight(enemy.shockPosition,pr.Position) then
                                self.ctx.combat:hurt(plr,32+(enemy.phase-1)*6,enemy.shockPosition,"Enemy")
                            end
                        end
                    elseif not enemy.shockAt and now>enemy.shock then
                        enemy.shock=now+11-(enemy.phase-1)*2 enemy.shockAt=now+1.8 enemy.shockPosition=enemy.root.Position
                        enemy.model:SetAttribute("Charging",true)
                        self.ctx.feed:FireAllClients("ShockWarning",{position=enemy.shockPosition,radius=20+(enemy.phase-1)*2,duration=1.8})
                    end
                end
                if enemy.shockAt or enemy.windup then enemy.hum:MoveTo(enemy.root.Position) enemy.movingTo=nil enemy.lastMoved=now
                else Navigation.move(self,enemy,tr.Position,now) end
                if now-enemy.lastMoved>16 or enemy.root.Position.Y < -15 then self:recover(enemy) end
            end
        end
    end
    self.scheduleCursor=start
    self.pathTokens=math.max(0,self.pathTokens-(math.floor(self.pathTokens)-self.pathBudget))
end
return E
