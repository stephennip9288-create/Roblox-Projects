local RS=game:GetService("ReplicatedStorage")
local PF=game:GetService("PathfindingService")
local Run=game:GetService("RunService")
local U=require(RS.DeadSignal.Util)
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local Rigs=require(script.Parent.EnemyRigs)
local Navigation=require(script.Parent.Navigation)
local Movement=require(RS.DeadSignal.Movement)
local DirectorRules=require(RS.DeadSignal.DirectorRules)
local T=C.Evolution
local E={} E.__index=E
-- Selection and damage must agree, including during the travel/disconnect handoff.
local function living(ctx,player)
    local p=player and ctx.players[player]
    if player and player.Parent and p and p.participating and p.status=="Alive" and not p.travelling then
        return p,U.root(player)
    end
end
function E.new(ctx)
    local old=workspace:FindFirstChild("DeadSignalEnemies") if old then old:Destroy() end
    local bodies=workspace:FindFirstChild("DeadSignalCorpses") if bodies then bodies:Destroy() end
    return setmetatable({ctx=ctx,list={},nextId=0,folder=U.make("Folder",workspace,{Name="DeadSignalEnemies"}),
        corpses=U.make("Folder",workspace,{Name="DeadSignalCorpses"}),hazards={},hazardId=0,pathBudget=0,pathTokens=4,pathBudgetAt=os.clock(),recovered=0,targetLoads={}},E)
end
function E:spawn(kind,window,position,mods,failedEntries)
    mods=kind=="Warden" and {} or mods or {}
    if not position and self.ctx.director then
        window=self.ctx.director:window(os.clock(),kind,failedEntries) or window
    end
    self.nextId=self.nextId+1 local id=self.nextId
    local entry=window and Navigation.entryDescriptor and Navigation.entryDescriptor(self.ctx.map,window)
    local origin=entry and entry.approach
    local pos=position or U.finiteVector(origin) and origin+Vector3.new(0,3.5*(self.ctx.map.scale or 1),0) or window.outside
    if not position then
        local outward=Vector3.new(pos.X-window.inside.X,0,pos.Z-window.inside.Z)
        outward=outward.Magnitude>.05 and outward.Unit or Vector3.new(0,0,-1)
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
    local model,root,hum=Rigs.build(self.folder,kind,pos,id,self.ctx.map.id)
    local stats=self.ctx.director and self.ctx.director:stats(kind,mods)
    local hp=stats and stats.hp or R.enemyHealth(self.ctx.run.round,kind,C.Modes[self.ctx.run.mode],math.max(1,self.ctx.game:aliveCount()),C.Warden)
    Movement.noJump(hum)
    hum.MaxHealth=hp hum.Health=hp hum.WalkSpeed=stats and stats.speed or R.enemySpeed(self.ctx.run.round,kind)
    model:SetAttribute("EnemyId",id) model:SetAttribute("MaxHP",hp) model:SetAttribute("HP",hp)
    local now=os.clock()
    local enemy={id=id,model=model,root=root,hum=hum,kind=kind,hp=hp,maxHP=hp,window=window,
        entered=position~=nil,attack=0,nextPath=0,index=1,path=nil,computing=false,
        shock=now+8,lastPosition=pos,lastMoved=now,spawned=now,runId=self.ctx.run.id,
        damage=stats and stats.damage or R.enemyDamage(self.ctx.run.round,kind,C.Modes[self.ctx.run.mode]),targetAt=now+(id%7)*.07,phase=1,attackDamage={},damageWindow=now,windowDamage=0}
    enemy.mods=mods enemy.baseSpeed=hum.WalkSpeed enemy.failedEntries=failedEntries
    enemy.armor=mods.Armored and {Head=hp*T.armored.plateHealth,Body=hp*T.armored.plateHealth} or nil
    enemy.reactor=mods.Volatile and hp*T.volatile.reactorHealth or nil
    enemy.packRole=mods.Alpha and "Alpha" or id%3==0 and "Flanker" or "Charger"
    if kind=="Stalker" then enemy.damage=math.min(T.stalker.damageCap,enemy.damage) end
    Rigs.evolve(enemy)
    if not position then
        local ground=entry and entry.approach or Navigation.floor(self.ctx.map,pos) or Navigation.floor(self.ctx.map,window.inside)
        if ground then
            pos=Vector3.new(pos.X,ground.Y+Navigation.rootHeight(enemy),pos.Z)
            model:PivotTo(CFrame.lookAt(pos,pos+Vector3.new(window.inside.X-pos.X,0,window.inside.Z-pos.Z)))
            enemy.lastPosition=pos
        end
        enemy.entryQueued=true root.Anchored=true hum.AutoRotate=false
        model:SetAttribute("TraversalStage","Waiting")
    end
    self.list[id]=enemy
    hum.Died:Connect(function() if self.list[id] then self:kill(enemy,nil,false,false) end end)
    return enemy
end
function E:count() return U.count(self.list) end
function E:damage(enemy,amount,player,head,attack,damageKind,hitPart)
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
            for _=1,2 do if self:count()<C.MaxEnemies then
                local entrance=self.ctx.director and self.ctx.director:window(now,"Runner") or enemy.window
                self:spawn("Runner",entrance or enemy.window)
            end end
        end
    end
    enemy.lastFeedback=nil
    if enemy.kind~="Warden" then
        local zone=hitPart and hitPart:GetAttribute("ArmorZone")
        local weak=hitPart and hitPart:GetAttribute("WeakZone")
        local hitZone=hitPart and hitPart:GetAttribute("HitZone")
        if damageKind=="Melee" then zone="Body" end
        if enemy.armor then
            local absorbed=0
            for key,hp in pairs(enemy.armor) do
                if hp>0 and (zone==key or damageKind=="Explosion" or damageKind=="Energy") then
                    local impact=amount*(damageKind=="Explosion" and .5 or 1)
                    local soak=math.min(hp,impact*T.armored.resistance)
                    enemy.armor[key]=math.max(0,hp-impact) absorbed=math.max(absorbed,soak)
                    enemy.lastFeedback="Armor"
                    if enemy.armor[key]<=0 then
                        Rigs.breakArmor(enemy,key) self:stun(enemy,T.precision.armorStun)
                        self.ctx.feed:FireAllClients("ArmorBreak",{position=enemy.root.Position,zone=key,id=enemy.id})
                        enemy.lastFeedback="ArmorBreak"
                    end
                end
            end
            amount=math.max(0,amount-absorbed)
            if weak and (enemy.armor[weak] or 0)<=0 then amount*=T.armored.exposed enemy.lastFeedback="Weakpoint" end
        end
        if enemy.reactor and hitZone=="Reactor" then
            enemy.reactor-=amount amount*=1.25 enemy.lastFeedback="Reactor"
            if enemy.reactor<=0 then self:reaction(enemy,player,head,amount,true);self:kill(enemy,player,head,true);return true end
        end
        local now=os.clock()
        if head and damageKind=="Bullet" and amount>=enemy.maxHP*T.precision.fraction and now>=(enemy.precisionAt or 0) then
            self:stun(enemy,T.precision.stun);enemy.precisionAt=now+T.precision.cooldown
        end
    end
    self:reaction(enemy,player,head,amount,enemy.hp-amount<=0)
    enemy.hp=math.max(0,enemy.hp-amount)
    enemy.model:SetAttribute("HP",enemy.hp)
    if enemy.hp<=0 then self:kill(enemy,player,head,true) return true end
    enemy.hum.Health=math.max(1,enemy.hp)
    return false
end
function E:reaction(e,player,head,amount,lethal)
    local now=os.clock()
    if not lethal and now<(e.reactionAt or 0) then return end
    e.reactionAt=now+.18
    local source=player and U.root(player)
    local forward=e.root.CFrame and e.root.CFrame.LookVector or Vector3.new(0,0,-1)
    local delta=source and e.root.Position-source.Position or -forward
    local direction=Vector3.new(delta.X,0,delta.Z)
    if direction.Magnitude<.01 then direction=-forward end
    direction=direction.Unit
    e.model:SetAttribute("HitVector",direction);e.model:SetAttribute("HitAt",workspace:GetServerTimeNow())
    e.model:SetAttribute("HitStrength",math.clamp(amount/math.max(1,e.maxHP)*2,.12,.75))
    e.model:SetAttribute("HitHead",head==true)
    if lethal then e.model:SetAttribute("DeathVector",direction) end
end
function E:kill(enemy,player,head,drops)
    if enemy.dead then return end enemy.dead=true self:stopTraversal(enemy,false) Navigation.invalidate(enemy) self.list[enemy.id]=nil
    if player and self.ctx.players[player] then
        local p=self.ctx.players[player]
        if p.participating then
            p.stats.kills=p.stats.kills+1 if head then p.stats.headshots=p.stats.headshots+1 end
            self.ctx.game:addPoints(player,head and C.Economy.headshot or C.Economy.kill)
        end
    end
    if enemy.kind=="Warden" then self.ctx.run.bossAlive=false end
    local pos=enemy.root.Position
    if drops and (enemy.kind=="Hound" or enemy.mods and enemy.mods.Volatile) then self:queueBlast(enemy,player) end
    self.ctx.feed:FireAllClients("EnemyDeath",{id=enemy.id,position=pos,kind=enemy.kind,headshot=head,look=enemy.root.CFrame.LookVector})
    Rigs.corpse(enemy.model,self.corpses)
    if drops and math.random()<.055 and self.ctx.run.phase=="Wave" then self.ctx.game:drop(pos) end
end
function E:clear(keepCorpses)
    self:clearHazards()
    for _,e in pairs(self.list) do e.dead=true self:stopTraversal(e,false) Navigation.invalidate(e) e.model:Destroy() end
    self.list={}
    if self.traversalConnection then self.traversalConnection:Disconnect();self.traversalConnection=nil end
    if not keepCorpses then for _,m in ipairs(self.corpses:GetChildren()) do m:Destroy() end end
end
function E:target(enemy,now)
    local current=enemy.target local _,root=living(self.ctx,current)
    local replaced=current and enemy.targetRoot and enemy.targetRoot~=root
    if root and not replaced and now<(enemy.targetAt or 0) then
        enemy.targetRoot=root return current,(root.Position-enemy.root.Position).Magnitude
    end
    enemy.targetAt=now+DirectorRules.tuning.targetSeconds+(enemy.id%5)*.035
    local target,targetRoot,distance,minimum=nil,nil,math.huge,math.huge
    for plr in pairs(self.ctx.players) do
        local _,pr=living(self.ctx,plr)
        if pr then
            local d=(pr.Position-enemy.root.Position).Magnitude
            local load=math.max(0,(self.targetLoads[plr] or 0)-(current==plr and 1 or 0))
            local score=d*(1+math.min(load,10)*DirectorRules.tuning.targetLoadWeight)*(current==plr and DirectorRules.tuning.targetStickiness or 1)
            if enemy.packLeader and not enemy.packLeader.dead and enemy.packLeader.target==plr then score*=.72 end
            if enemy.kind=="Stalker" then
                local ally=math.huge
                for other in pairs(self.ctx.players) do if other~=plr then
                    local _,ort=living(self.ctx,other) if ort then ally=math.min(ally,(ort.Position-pr.Position).Magnitude) end
                end end
                if ally>25 then score*=.6 end
            end
            if score<minimum then target=plr targetRoot=pr distance=d minimum=score end
        end
    end
    if current~=target or replaced then
        if current then self.targetLoads[current]=math.max(0,(self.targetLoads[current] or 0)-1) end
        if target then self.targetLoads[target]=(self.targetLoads[target] or 0)+1 end
        self:cancelActions(enemy)
        enemy.target=target enemy.route=nil Navigation.invalidate(enemy)
    end
    enemy.targetRoot=targetRoot
    return target,distance
end
function E:cancelActions(e)
    -- Keep nextCharge/nextAmbush: losing a target or being interrupted is not a
    -- free cooldown reset. A replacement target needs its own fresh warning.
    e.windup=nil e.windupTarget=nil e.chargeUntil=nil e.chargeAt=nil e.chargeGoal=nil
    e.ambushAt=nil e.ambushUntil=nil e.cover=nil e.coverAt=nil
    e.flankGoal=nil e.flankUntil=nil
    if e.model and e.model.SetAttribute then
        e.model:SetAttribute("ChargeUntil",0) e.model:SetAttribute("AmbushAt",0)
    end
end
function E:clearSight(a,b)
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
    params.CollisionGroup="DeadSignalShots"
    params.FilterDescendantsInstances={self.ctx.map.model}
    return not workspace:Raycast(a,b-a,params)
end
function E:recover(enemy)
    if enemy.dead then return end
    self:stopTraversal(enemy,false)
    local failedEntries=enemy.failedEntries or {}
    if not enemy.entered and enemy.window then
        -- A rejected sill/ceiling or blocked landing must not keep selecting
        -- the same entrance for this species. This is transient, never a quota
        -- change or an interior reposition, and does not blacklist other kinds.
        enemy.window.entryBlockedUntil=enemy.window.entryBlockedUntil or {}
        enemy.window.entryBlockedUntil[enemy.kind]=os.clock()+8
        failedEntries[enemy.window]=self.ctx.map.navigationRevision or 0
    end
    local attempts=(enemy.recoveryAttempts or 0)+1
    if attempts>=3 and enemy.kind~="Warden" then
        -- A broken final route must not hold an ordinary wave forever. No kill,
        -- points or drop is credited for navigation retirement.
        self.retired=(self.retired or 0)+1 self:kill(enemy,nil,false,false) return
    end
    local hp=enemy.hp local rewards=enemy.hitRewards local kind=enemy.kind local window=enemy.window
    local maxHP,phase,overload=enemy.maxHP,enemy.phase,enemy.overloadUntil
    enemy.dead=true Navigation.invalidate(enemy) self.list[enemy.id]=nil enemy.model:Destroy()
    local nextWindow=window
    if self.ctx.director then
        nextWindow=self.ctx.director:window(os.clock(),kind,failedEntries)
        if not nextWindow then
            -- Try each eligible entrance before repeating one. A fresh bounded
            -- cycle lets temporary occupancy clear without permanent exclusions.
            failedEntries={};nextWindow=self.ctx.director:window(os.clock(),kind)
        end
    end
    local replacement=self:spawn(kind,nextWindow or window,nil,enemy.mods,failedEntries)
    replacement.armor=enemy.armor replacement.reactor=enemy.reactor
    if enemy.armor then for zone,value in pairs(enemy.armor) do if value<=0 then Rigs.breakArmor(replacement,zone) end end end
    replacement.recoveryAttempts=attempts
    replacement.nextCharge=enemy.nextCharge replacement.nextAmbush=enemy.nextAmbush
    replacement.nextFlank=enemy.nextFlank replacement.precisionAt=enemy.precisionAt
    replacement.traversalUses=enemy.traversalUses
    -- A smaller crew can produce a lower fresh MaxHealth. Restore the original
    -- maximum before Health so the engine cannot clamp surviving HP on recovery.
    replacement.damage=enemy.damage replacement.maxHP=maxHP replacement.hum.MaxHealth=maxHP replacement.phase=phase replacement.overloadUntil=overload
    replacement.hp=hp replacement.hum.Health=math.max(1,hp) replacement.hitRewards=rewards
    replacement.model:SetAttribute("MaxHP",maxHP) replacement.model:SetAttribute("BossPhase",phase)
    replacement.model:SetAttribute("HP",hp) self.recovered=self.recovered+1
end
function E:stun(e,seconds)
    if e.dead or e.kind=="Warden" then return end
    e.stunnedUntil=math.max(e.stunnedUntil or 0,os.clock()+seconds)
    self:cancelActions(e)
    e.model:SetAttribute("StunnedUntil",workspace:GetServerTimeNow()+math.max(0,e.stunnedUntil-os.clock()))
end
function E:pendingBlasts()
    local n=0 for _,h in ipairs(self.hazards or {}) do if not h.detonated then n+=1 end end return n
end
function E:clearHazards()
    self.hazards={} self.ctx.feed:FireAllClients("HazardClear",{})
end
function E:queueBlast(e,owner)
    self.hazards=self.hazards or {}
    if #self.hazards>=T.hazards.maxActive then return end -- Excess deaths fizzle; never deal unannounced damage.
    local cfg=e.mods and e.mods.Volatile and T.volatileBlast or T.houndBlast
    local now=os.clock() local ground=Navigation.floor(self.ctx.map,e.root.Position)
    local pos=ground and ground+Vector3.new(0,.12,0) or e.root.Position
    self.hazardId=(self.hazardId or 0)+1
    local h={id=self.hazardId,position=pos,cfg=cfg,owner=owner,at=now+cfg.warning,runId=self.ctx.run.id,nextBurn=now+cfg.warning,
        damage=DirectorRules.blastDamage(self.ctx.run.round,cfg,C.Modes[self.ctx.run.mode]),enemyDamage=e.maxHP*cfg.enemyFraction}
    table.insert(self.hazards,h)
    self.ctx.feed:FireAllClients("HazardWarning",{id=h.id,position=pos,radius=cfg.radius,duration=cfg.warning,cue=e.kind=="Hound" and "Howl" or "Volatile"})
end
function E:counter(kind,center,now)
    local radius=T.counters.radius*(self.ctx.map.scale or 1)
    self.ctx.map.counterFields=self.ctx.map.counterFields or {}
    self.ctx.map.counterFields[kind]={center=center,untilAt=now+T.counters.duration,radius=radius}
    for _,h in ipairs(self.hazards or {}) do if (h.position-center).Magnitude<radius then
        h[kind=="Vent" and "smokeCleared" or "fireSuppressed"]=true
        self.ctx.feed:FireAllClients("HazardCounter",{id=h.id,kind=kind})
    end end
    self.ctx.feed:FireAllClients("CounterActive",{kind=kind,position=center,radius=radius,duration=T.counters.duration})
end
function E:tickHazards(now)
    self.hazards=self.hazards or {}
    for i=#self.hazards,1,-1 do
        local h=self.hazards[i] local cfg=h.cfg
        if h.runId~=self.ctx.run.id then table.remove(self.hazards,i)
        else
            for kind,field in pairs(self.ctx.map.counterFields or {}) do
                if now<field.untilAt and (h.position-field.center).Magnitude<field.radius then
                    local key=kind=="Vent" and "smokeCleared" or "fireSuppressed"
                    if not h[key] then h[key]=true self.ctx.feed:FireAllClients("HazardCounter",{id=h.id,kind=kind}) end
                end
            end
            if not h.detonated and now>=h.at then
                h.detonated=true
                self.ctx.feed:FireAllClients("HazardBlast",{id=h.id,position=h.position,radius=cfg.radius,smoke=h.smokeCleared and 0 or cfg.smoke,
                    flames=h.fireSuppressed and 0 or cfg.flames,opacity=cfg.opacity})
                for player in pairs(self.ctx.players) do local _,root=living(self.ctx,player)
                    local distance=root and (root.Position-h.position).Magnitude or math.huge
                    if distance<cfg.radius and self:clearSight(h.position+Vector3.new(0,2,0),root.Position) then
                        self.ctx.combat:hurt(player,h.damage*(1-.4*distance/cfg.radius),h.position,"Enemy")
                    end
                end
                -- Chain deaths enqueue their own full warning, never an immediate recursive blast.
                local victims={} for _,e in pairs(self.list) do victims[#victims+1]=e end
                for _,e in ipairs(victims) do if not e.dead and (e.root.Position-h.position).Magnitude<cfg.radius and self:clearSight(h.position+Vector3.new(0,2,0),e.root.Position) then
                    self:damage(e,h.enemyDamage,h.owner,false,"hazard:"..h.id,"Explosion")
                end end
            end
            if h.detonated and not h.fireSuppressed and now<h.at+cfg.flames and now>=h.nextBurn then
                h.nextBurn=now+T.hazards.tick
                for player in pairs(self.ctx.players) do local p,root=living(self.ctx,player)
                    if root and not p.perks.Insulator and (root.Position-h.position).Magnitude<cfg.radius*.65
                        and self:clearSight(h.position+Vector3.new(0,2,0),root.Position) then self.ctx.combat:hurt(player,T.hazards.flameDamage*T.hazards.tick,h.position,"Enemy") end
                end
            end
            if now>=h.at+math.max(cfg.smoke,cfg.flames) then table.remove(self.hazards,i) end
        end
    end
end
function E:coordinate(now)
    if now<(self.packAt or 0) then return end self.packAt=now+.7
    local alpha
    for _,e in pairs(self.list) do if not e.dead and e.kind=="Hound" and e.mods and e.mods.Alpha then alpha=e break end end
    for _,e in pairs(self.list) do if e.kind=="Hound" then
        e.packRole=e.mods and e.mods.Alpha and "Alpha" or e.id%10<math.min(6,2+math.floor(self.ctx.run.round/10)) and "Flanker" or "Charger"
        e.model:SetAttribute("PackRole",e.packRole)
        local leader=alpha and (alpha.root.Position-e.root.Position).Magnitude<T.alpha.rallyRadius and alpha or nil
        e.packLeader=leader e.model:SetAttribute("PackLeader",leader and leader.id or 0)
    end end
end
function E:traversalCue(e,stage,now)
    local t=e.traversal;if not t or t.cues[stage] then return end
    t.cues[stage]=true
    if e.model.Parent then
        e.model:SetAttribute("EntryCue","Enemy.Entry."..stage)
        e.model:SetAttribute("EntryCueAt",workspace:GetServerTimeNow())
    end
    -- Existing Board payload is a bounded stock contact/landing fallback.
    -- Semantic attributes are ready for the integrator's client audio adapter;
    -- no new remote fields or gated Controller/Effects edits are made here.
    if stage~="Contact" and stage~="Land" then return end
    if now<(self.entryCueAt or 0) then return end self.entryCueAt=now+.25
    self.ctx.feed:FireAllClients("Board",{position=e.root.Position})
end
function E:startTraversal(e,plan,now)
    if e.dead or e.traversal or now<(e.stunnedUntil or 0) then return false end
    self.traversals=self.traversals or {}
    local n=0 for _ in pairs(self.traversals) do n+=1 end
    if n>=Navigation.traversalTuning.maxConcurrent then return false end
    self:cancelActions(e);Navigation.invalidate(e)
    local collider=e.model:FindFirstChild("BodyCollider")
    local t={plan=plan,elapsed=0,last=now,started=now,runId=self.ctx.run.id,map=self.ctx.map,stage="Approach",cues={},
        autoRotate=e.hum.AutoRotate,platform=e.hum.PlatformStand,anchored=e.root.Anchored,collider=collider,collides=collider and collider.CanCollide}
    e.traversal=t;self.traversals[e.id]=e
    e.entrySerial=(e.entrySerial or 0)+1
    e.model:SetAttribute("EntrySourceId","enemy:"..tostring(self.ctx.run.id)..":"..e.id..":"..e.entrySerial)
    self:traversalCue(e,"Approach",now)
    if plan.window then plan.window.activeEntry=e.id;plan.window.nextEntry=now+.35 end
    if plan.key then e.traversalUses=e.traversalUses or {};e.traversalUses[plan.key]=(e.traversalUses[plan.key] or 0)+1 end
    e.root.Anchored=true;e.root.AssemblyLinearVelocity=Vector3.zero;e.root.AssemblyAngularVelocity=Vector3.zero
    e.hum.AutoRotate=false;e.hum.PlatformStand=true;e.hum:MoveTo(e.root.Position)
    if collider then collider.CanCollide=false end
    e.model:SetAttribute("TraversalStyle",plan.style);e.model:SetAttribute("TraversalSpeed",8)
    e.model:SetAttribute("TraversalStage","Approach");e.model:SetAttribute("TraversalStageAt",workspace:GetServerTimeNow())
    e.model:SetAttribute("TraversalStageDuration",plan.stages[1].duration);e.model:SetAttribute("TraversalHeld",false)
    if not self.traversalConnection then
        local accumulated=0
        self.traversalConnection=Run.Heartbeat:Connect(function(dt)
            accumulated+=dt;if accumulated<1/30 then return end accumulated=0
            self:tickTraversals(os.clock())
        end)
    end
    return true
end
function E:stopTraversal(e,success)
    local t=e.traversal;if not t then return end
    if not success then self:traversalCue(e,"Cancel",os.clock()) end
    e.traversal=nil;if self.traversals then self.traversals[e.id]=nil end
    if t.plan.window and t.plan.window.activeEntry==e.id then t.plan.window.activeEntry=nil end
    if e.root.Parent then
        e.root.Anchored=not success and t.anchored or false
        e.root.AssemblyLinearVelocity=Vector3.zero;e.root.AssemblyAngularVelocity=Vector3.zero
    end
    if e.model.Parent then
        e.hum.PlatformStand=t.platform;e.hum.AutoRotate=success and true or t.autoRotate
        e.hum.WalkSpeed=e.baseSpeed or e.hum.WalkSpeed
    end
    if t.collider and t.collider.Parent then t.collider.CanCollide=t.collides end
    if e.model.Parent and e.dead then
        local _,_,phase=Navigation.traversalSample(t.plan,t.elapsed)
        e.model:SetAttribute("TraversalHoldPhase",phase);e.model:SetAttribute("TraversalHeld",true)
    elseif e.model.Parent then
        e.model:SetAttribute("TraversalStage",success and "Pursuit" or "Waiting");e.model:SetAttribute("TraversalHeld",false)
    end
    e.nextTraversal=os.clock()+3;e.entryRetryAt=os.clock()+Navigation.traversalTuning.retrySeconds
    if success then
        e.entered=true;e.entryQueued=nil;e.entryFailures=0
        e.lastPosition=e.root.Position;e.lastMoved=os.clock()
    end
    if self.traversalConnection and not next(self.traversals) then self.traversalConnection:Disconnect();self.traversalConnection=nil end
end
function E:tickTraversals(now)
    local pending={} for _,e in pairs(self.traversals or {}) do pending[#pending+1]=e end
    for _,e in ipairs(pending) do
        local t=e.traversal;if not t then continue end
        if e.dead or not e.root.Parent or t.runId~=self.ctx.run.id or t.map~=self.ctx.map
            or self.ctx.run.phase~="Wave" and self.ctx.run.phase~="Exfil" then self:stopTraversal(e,false);continue end
        local target=self:target(e,now)
        if not target or t.plan.window and t.plan.window.count>0 or t.plan.descriptor.door and not t.plan.descriptor.door.open then t.retreat=true end
        if t.retreat then self:traversalCue(e,"Cancel",now) end
        local dt=math.clamp(now-t.last,0,Navigation.traversalTuning.stepSeconds);t.last=now
        if now>t.started+t.plan.duration+Navigation.traversalTuning.timeout then
            self:stopTraversal(e,false);e.entryFailures=3;self:recover(e);continue
        end
        if now<(e.stunnedUntil or 0) then
            local _,_,phase=Navigation.traversalSample(t.plan,t.elapsed)
            e.model:SetAttribute("TraversalHoldPhase",phase);e.model:SetAttribute("TraversalHeld",true);continue
        end
        local elapsed=math.clamp(t.elapsed+(t.retreat and -dt*1.3 or dt),0,t.plan.duration)
        local at,stage,phase,index=Navigation.traversalSample(t.plan,elapsed)
        for _=1,5 do
            if (at-e.root.Position).Magnitude<=Navigation.traversalTuning.maxStep*(self.ctx.map.scale or 1) then break end
            elapsed=(elapsed+t.elapsed)*.5;at,stage,phase,index=Navigation.traversalSample(t.plan,elapsed)
        end
        if not Navigation.traversalClear(self,e,e.root.Position,at,t.plan.window,elapsed==t.plan.duration) then
            t.blockedAt=t.blockedAt or now
            local _,_,heldPhase=Navigation.traversalSample(t.plan,t.elapsed)
            e.model:SetAttribute("TraversalHoldPhase",heldPhase)
            e.model:SetAttribute("TraversalHeld",true)
            if now-t.blockedAt>=Navigation.traversalTuning.blockedSeconds then t.retreat=true;self:traversalCue(e,"Cancel",now) end
            continue
        end
        t.blockedAt=nil;t.elapsed=elapsed;e.lastMoved=now
        e.model:PivotTo(CFrame.lookAt(at,at+t.plan.forward))
        if t.stage~=stage or t.retreat~=t.retreatPose or e.model:GetAttribute("TraversalHeld") then
            t.stage=stage;t.retreatPose=t.retreat
            e.model:SetAttribute("TraversalStage",t.retreat and "Retreat" or stage)
            e.model:SetAttribute("TraversalStageAt",workspace:GetServerTimeNow()-phase*t.plan.stages[index].duration)
            e.model:SetAttribute("TraversalStageDuration",t.plan.stages[index].duration);e.model:SetAttribute("TraversalHeld",false)
            if not t.retreat and stage=="Contact" then self:traversalCue(e,"Contact",now)
            elseif not t.retreat and stage=="Settle" then self:traversalCue(e,"Land",now) end
        end
        if t.retreat and elapsed<=0 then
            self:stopTraversal(e,false);e.entryFailures=(e.entryFailures or 0)+1
            if e.entryFailures>=3 then self:recover(e) end
        elseif elapsed>=t.plan.duration then self:stopTraversal(e,true) end
    end
end
function E:behavior(e,tr,now,distance)
    local destination=tr.Position local hold=false local allow=true
    if e.kind=="Hound" then destination=Navigation.goal(self.ctx,e,destination,now) end
    e.hum.WalkSpeed=e.baseSpeed or e.hum.WalkSpeed
    if now<(e.stunnedUntil or 0) then e.hum.WalkSpeed=0 return destination,true,false end
    if e.kind=="Hound" then
        if e.chargeAt and now>=e.chargeAt then e.chargeAt=nil e.chargeUntil=now+T.pack.chargeSeconds end
        if e.chargeUntil and now>=e.chargeUntil then e.chargeUntil=nil e.recoverUntil=now+.4 end
        if e.chargeAt then hold=true allow=false
        elseif e.chargeUntil then
            destination=e.chargeGoal e.hum.WalkSpeed=T.pack.chargeSpeed
            if not Navigation.clearRoute(self.ctx,e,destination) then
                e.chargeUntil=nil e.chargeGoal=nil e.recoverUntil=now+.4
                e.model:SetAttribute("ChargeUntil",0)
                destination=Navigation.goal(self.ctx,e,tr.Position,now) hold=true allow=false
            end
        elseif now<(e.recoverUntil or 0) then hold=true allow=false
        elseif distance>8 and distance<21 and now>=(e.nextCharge or 0) and e.packRole~="Flanker" and Navigation.clearRoute(self.ctx,e,destination) then
            e.nextCharge=now+T.pack.chargeCooldown+(e.id%3)*.5 e.chargeAt=now+T.pack.chargeWarning e.chargeGoal=destination
            e.model:SetAttribute("ChargeUntil",workspace:GetServerTimeNow()+T.pack.chargeWarning+T.pack.chargeSeconds)
            self.ctx.feed:FireAllClients("EnemyTelegraph",{position=e.root.Position,finish=tr.Position,radius=2,duration=T.pack.chargeWarning,cue="Howl"})
            hold=true allow=false
        elseif e.packRole=="Flanker" and self.ctx.run.round>=T.pack.flankStart then
            if e.flankGoal and (now>=(e.flankUntil or 0) or distance<=6 or distance>=32 or now-e.lastMoved>=1.4
                or (e.root.Position-e.flankGoal).Magnitude<2 or not Navigation.clearRoute(self.ctx,e,e.flankGoal)) then
                e.flankGoal=nil e.flankUntil=nil e.nextFlank=now+DirectorRules.tuning.flankCooldown
            end
            if not e.flankGoal and now>=(e.nextFlank or 0) and distance>6 and distance<32 and now-e.lastMoved<1.4 then
                local side=e.id%2==0 and 1 or -1 local radius=math.min(T.pack.flankMax,5+self.ctx.run.round*.12)
                local candidate=tr.Position+tr.CFrame.RightVector*side*radius-tr.CFrame.LookVector*3
                candidate=Navigation.goal(self.ctx,e,candidate,now)
                if Navigation.clearRoute(self.ctx,e,candidate) then
                    e.flankGoal=candidate e.flankUntil=now+DirectorRules.tuning.flankSeconds
                else e.nextFlank=now+DirectorRules.tuning.flankCooldown end
            end
            if e.flankGoal then destination=e.flankGoal end
        end
        -- Nearby Alpha directs the pack's focus, without overriding fair target validation.
        if e.packLeader and not e.packLeader.dead and e.packLeader~=e and e.packRole=="Flanker" then e.hum.WalkSpeed=math.min(24,e.hum.WalkSpeed*1.06) end
    elseif e.kind=="Stalker" then
        allow=now<(e.ambushUntil or 0)
        if e.ambushAt and now>=e.ambushAt then e.ambushAt=nil e.ambushUntil=now+T.stalker.ambushSeconds allow=true end
        if e.ambushAt then hold=true
        elseif allow then e.hum.WalkSpeed=T.stalker.speed
        elseif distance<14 and now>=(e.nextAmbush or 0) then
            e.ambushAt=now+T.stalker.warning e.nextAmbush=now+T.stalker.cooldown
            e.model:SetAttribute("AmbushAt",workspace:GetServerTimeNow()+T.stalker.warning)
            self.ctx.feed:FireAllClients("EnemyTelegraph",{position=e.root.Position,radius=3,duration=T.stalker.warning,cue="Stalker"})
            hold=true
        elseif now>=(e.coverAt or 0) then
            e.coverAt=now+1.5 e.cover=nil
            for _,side in ipairs({e.id%2==0 and 1 or -1,e.id%2==0 and -1 or 1}) do
                local candidate=tr.Position+tr.CFrame.RightVector*side*10-tr.CFrame.LookVector*7
                candidate=Navigation.goal(self.ctx,e,candidate,now)
                if Navigation.clearRoute(self.ctx,e,candidate) and not self:clearSight(tr.Position,candidate) then e.cover=candidate break end
            end
        end
        if not allow and not hold and e.cover and now-e.lastMoved<1.4 then destination=e.cover end
        if distance<5 and not allow and not hold then hold=true end -- Readable cooldown instead of constant ambushes.
    end
    return destination,hold,allow
end
function E:tick(now)
    if not self.ctx.map then return end
    self:tickHazards(now)
    self:coordinate(now)
    self.entryPlanBudget=1
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
        if enemy.dead or self.list[enemy.id]~=enemy then continue end
        if not enemy.root.Parent or enemy.root.Position.Y < -15 then self:recover(enemy)
        elseif enemy.traversal then enemy.lastMoved=now
        elseif not enemy.entered then
            local window=enemy.window
            enemy.hum:MoveTo(enemy.root.Position)
            if window.count<=0 then
                if now>=(window.nextEntry or 0) and now>=(enemy.entryRetryAt or 0) and now>=(enemy.entryPlanAt or 0) and self.entryPlanBudget>0 then
                    self.entryPlanBudget-=1;enemy.entryPlanAt=now+Navigation.traversalTuning.planInterval
                    local plan=Navigation.entryPlan(self,enemy,window)
                    if plan then self:startTraversal(enemy,plan,now) end
                end
            elseif now>window.nextTear then
                window.nextTear=now+R.breachInterval(self.ctx.run.round) window.boards[window.count].Transparency=1 window.count=window.count-1
                enemy.lastMoved=now
                enemy.model:SetAttribute("AttackAt",workspace:GetServerTimeNow())
                self.ctx.feed:FireAllClients("Board",{position=window.part.Position,count=window.count})
            end
            if not enemy.entered and now-enemy.lastMoved>DirectorRules.tuning.entryRecoverySeconds then self:recover(enemy) end
        else
            local target,distance=self:target(enemy,now) local tr=target and U.root(target)
            if tr then
                local destination,hold,allowAttack=self:behavior(enemy,tr,now,distance)
                local stunned=now<(enemy.stunnedUntil or 0)
                if stunned or not allowAttack then enemy.windup=nil enemy.windupTarget=nil end
                local direct=distance<R.enemyAttackRange(enemy.kind)+1 and self:clearSight(enemy.root.Position,tr.Position)
                if enemy.windup and now>=enemy.windup then
                    enemy.windup=nil
                    local victim=enemy.windupTarget local _,vr=living(self.ctx,victim)
                    enemy.windupTarget=nil
                    if victim==target and vr and (vr.Position-enemy.root.Position).Magnitude<R.enemyAttackRange(enemy.kind)+.5
                        and self:clearSight(enemy.root.Position,vr.Position) then
                        self.ctx.combat:hurt(victim,enemy.damage,enemy.root.Position,"Enemy")
                    end
                elseif not stunned and allowAttack and not enemy.windup and distance<R.enemyAttackRange(enemy.kind) and direct and now>enemy.attack then
                    enemy.attack=now+R.enemyAttackInterval(self.ctx.run.round,enemy.kind)*(enemy.mods and enemy.mods.Enraged and .88 or 1)
                    enemy.windupTarget=target enemy.windup=now+(enemy.kind=="Hound" and .32 or enemy.kind=="Stalker" and .6 or enemy.kind=="Warden" and .65 or .45)
                    enemy.model:SetAttribute("AttackAt",workspace:GetServerTimeNow())
                    self.ctx.feed:FireAllClients("EnemyAttack",{id=enemy.id,position=enemy.root.Position,kind=enemy.kind,enraged=enemy.mods and enemy.mods.Enraged})
                end
                if enemy.kind=="Warden" then
                    if enemy.shockAt and now>=enemy.shockAt then
                        enemy.shockAt=nil enemy.model:SetAttribute("Charging",false)
                        local radius=20+(enemy.phase-1)*2
                        self.ctx.feed:FireAllClients("Shock",{position=enemy.shockPosition,radius=radius})
                        for plr in pairs(self.ctx.players) do
                            local _,pr=living(self.ctx,plr)
                            if pr and (pr.Position-enemy.shockPosition).Magnitude<radius and self:clearSight(enemy.shockPosition,pr.Position) then
                                self.ctx.combat:hurt(plr,32+(enemy.phase-1)*6,enemy.shockPosition,"Enemy")
                            end
                        end
                    elseif not enemy.shockAt and now>enemy.shock then
                        enemy.shock=now+11-(enemy.phase-1)*2 enemy.shockAt=now+1.8 enemy.shockPosition=enemy.root.Position
                        enemy.model:SetAttribute("Charging",true)
                        self.ctx.feed:FireAllClients("ShockWarning",{position=enemy.shockPosition,radius=20+(enemy.phase-1)*2,duration=1.8})
                    end
                end
                if stunned or hold or enemy.shockAt or enemy.windup then enemy.hum:MoveTo(enemy.root.Position) enemy.movingTo=nil enemy.lastMoved=now
                else
                    local plan=self.ctx.map.traversals and self.entryPlanBudget>0 and Navigation.contextPlan(self,enemy,destination,now)
                    if plan then self.entryPlanBudget-=1;self:startTraversal(enemy,plan,now)
                    else Navigation.move(self,enemy,destination,now) end
                end
                if now-enemy.lastMoved>16 then self:recover(enemy) end
            else
                self:cancelActions(enemy)
                if enemy.shockAt then enemy.shockAt=nil enemy.model:SetAttribute("Charging",false) end
                enemy.hum:MoveTo(enemy.root.Position) enemy.movingTo=nil enemy.lastMoved=now
            end
        end
    end
    self.scheduleCursor=start
    self.pathTokens=math.max(0,self.pathTokens-(math.floor(self.pathTokens)-self.pathBudget))
end
return E
