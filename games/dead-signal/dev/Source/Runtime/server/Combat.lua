local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local W=require(RS.DeadSignal.WeaponModels)
local B={} B.__index=B
function B.new(ctx) return setmetatable({ctx=ctx,projectiles={},attackSerial=0},B) end
function B:attackKey(player)
    self.attackSerial=self.attackSerial+1 return tostring(player and player.UserId or 0)..":"..self.attackSerial
end
function B:gun(state) return state.guns and state.guns[state.slot] end
function B:give(player,id,tier)
    local p=self.ctx.players[player] if not p then return end
    local stat=R.weaponStats(C.Weapons[id],tier or 0,p.perks)
    local slot=#p.guns<2 and (#p.guns+1) or p.slot
    p.guns[slot]={id=id,tier=tier or 0,mag=stat.mag,reserve=stat.reserve,reloadUntil=0}
    p.slot=slot p.nextShot=0
    self:visual(player) self:ammo(player)
    self.ctx.feed:FireClient(player,"Toast",{text=stat.name,color="cyan"})
end
function B:visual(player)
    local p=self.ctx.players[player] local g=p and self:gun(p)
    if g then local profile=self.ctx.data.profiles[player] W.attach(player,g.id,profile and profile.data.skin or "Factory",g.tier) end
end
function B:ammo(player,ack)
    local p=self.ctx.players[player] local g=p and self:gun(p)
    if p and R.finite(ack) then p.ack=math.max(p.ack or 0,math.floor(ack)) end
    if g and player.Parent then self.ctx.feed:FireClient(player,"Ammo",{slot=p.slot,guns=U.copy(p.guns),accepted=p.ack or 0}) end
end
function B:ready(player)
    local p=self.ctx.players[player] local root=U.root(player)
    return p and p.participating and p.status=="Alive" and root and self.ctx.game:isCombat(),p,root
end
function B:enemyFor(part)
    local model=part and part:FindFirstAncestorOfClass("Model")
    return model and self.ctx.enemies.list[model:GetAttribute("EnemyId")]
end
function B:ray(origin,direction,range,ignore)
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
    params.CollisionGroup="DeadSignalShots"
    local include={self.ctx.map.model}
    for _,e in pairs(self.ctx.enemies.list) do if not (ignore and ignore[e.id]) then table.insert(include,e.model) end end
    params.FilterDescendantsInstances=include params.IgnoreWater=true
    return workspace:Raycast(origin,direction*range,params)
end
-- Per enemy and per operator: damaging an enemy indefinitely cannot farm points.
function B:hitReward(player,enemy,amount)
    enemy.hitRewards=enemy.hitRewards or {}
    local used=enemy.hitRewards[player.UserId] or 0
    local reward=math.min(amount,math.max(0,C.Economy.hitCap-used))
    if reward>0 then enemy.hitRewards[player.UserId]=used+reward self.ctx.game:addPoints(player,reward) end
end
-- Muzzle clearance is server-owned. A barrel poked through a near wall cannot
-- start a shot on the far side. View rays choose a point, never a client target.
function B:muzzle(player,head)
    local carried=player.Character and player.Character:FindFirstChild("CarriedWeapon")
    local muzzle=carried and carried:FindFirstChild("Muzzle",true)
    local origin=head
    if muzzle and muzzle:IsA("BasePart") and (muzzle.Position-head).Magnitude<9 then origin=muzzle.Position end
    local delta=origin-head
    if delta.Magnitude>.01 then
        local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances={self.ctx.map.model} params.CollisionGroup="DeadSignalShots"
        local blocked=workspace:Raycast(head,delta,params)
        if blocked then return head,blocked end
    end
    return origin,nil
end
function B:fire(player,args)
    local valid,p,root=self:ready(player)
    if not valid or type(args)~="table" or not U.finiteVector(args.direction) then return end
    if not R.finite(args.seq) or args.seq%1~=0 or args.seq<1 or args.seq>2147483647 or args.seq<=(p.lastFireSeq or 0) then return end
    local magnitude=args.direction.Magnitude
    if magnitude<.98 or magnitude>1.02 then return end
    local g=self:gun(p) if not g then return end
    local head=player.Character:FindFirstChild("Head")
    local eye=head and head.Position or root.Position+Vector3.new(0,1.5,0)
    if args.viewOrigin~=nil and (not U.finiteVector(args.viewOrigin) or (args.viewOrigin-eye).Magnitude>6) then return end
    if args.viewOrigin and (args.viewOrigin-eye).Magnitude>.05 then
        local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances={self.ctx.map.model} params.CollisionGroup="DeadSignalShots"
        if workspace:Raycast(eye,args.viewOrigin-eye,params) then return end
    end
    p.lastFireSeq=args.seq
    local now=os.clock() local def=C.Weapons[g.id] local stats=R.weaponStats(def,g.tier,p.perks)
    if now<(p.nextShot or 0) or g.reloadUntil>now or g.mag<=0 or p.sprinting then self:ammo(player,args.seq) return end
    p.nextShot=now+stats.interval*.97 g.mag=g.mag-1 p.accepted=R.finite(args.seq) and math.floor(args.seq) or 0
    local origin,obstruction=self:muzzle(player,eye)
    if obstruction then
        self.ctx.feed:FireAllClients("Shot",{player=player.UserId,origin=eye,ends={obstruction.Position},weapon=g.id})
        self:ammo(player,args.seq) return
    end
    local dir=args.direction.Unit
    local view=args.viewOrigin or eye
    local viewHit=self:ray(view,dir,def.range)
    local aimPoint=viewHit and viewHit.Position or view+dir*def.range
    local delta=aimPoint-origin
    if delta.Magnitude>.02 then dir=delta.Unit end
    local pellets=def.pellets or 1 local ends={} local hitAny,killAny,headAny=false,false,false
    local rewarded={} local hitTotal=0
    local attack=self:attackKey(player)
    for i=1,pellets do
        local spread=math.rad(def.spread*(p.aiming and .35 or 1))
        local aim=CFrame.lookAt(Vector3.new(0,0,0),dir)*CFrame.Angles((math.random()-.5)*spread,(math.random()-.5)*spread,0)
        local shot=aim.LookVector local current=origin local remaining=def.range local ignore={}
        for pierce=1,(def.pierce or 1) do
            local hit=self:ray(current,shot,remaining,ignore)
            local endpoint=hit and hit.Position or current+shot*remaining
            table.insert(ends,endpoint)
            if not hit then break end
            local e=self:enemyFor(hit.Instance)
            if e then
                local armorZone=hit.Instance:GetAttribute("ArmorZone")
                local isHead=not armorZone and (hit.Instance.Name=="Head" or hit.Instance.Name=="Weakpoint" or hit.Instance:GetAttribute("HitZone")=="Head" or hit.Instance:GetAttribute("HitZone")=="Weakpoint")
                local damage=stats.damage*(isHead and (e.kind=="Warden" and C.Warden.weakpoint or def.head) or 1)
                if e.kind=="Warden" then
                    damage=damage*(hit.Instance.Name=="Armor" and C.Warden.armor or .8)
                elseif hit.Instance.Name=="Armor" then damage=damage*.45 end
                local falloff=1-R.clamp((hit.Position-origin).Magnitude/def.range-.45,0,.5)
                damage=damage*falloff
                if (self.ctx.run.effects.Instant or 0)>now and e.kind~="Warden" then damage=e.hp end
                local before=e.hp local killed=self.ctx.enemies:damage(e,damage,player,isHead,attack,"Bullet",hit.Instance)
                if e.lastFeedback then self.ctx.feed:FireClient(player,"EliteHit",{kind=e.lastFeedback}) end
                hitAny=true killAny=killAny or killed headAny=headAny or isHead hitTotal=hitTotal+before-e.hp
                if not rewarded[e.id] then rewarded[e.id]=true self:hitReward(player,e,C.Economy.hit) end
                ignore[e.id]=true
                if def.splash then self:explode(hit.Position,def.splash,stats.damage*.7,player,e.id,false,attack) end
                if def.chain then
                    local links=0
                    for _,other in pairs(self.ctx.enemies.list) do
                        if other.id~=e.id and (other.root.Position-hit.Position).Magnitude<12 and self.ctx.enemies:clearSight(hit.Position,other.root.Position) then
                            links=links+1 local finish=other.root.Position
                            self.ctx.enemies:damage(other,stats.damage*.55,player,false,attack,"Energy")
                            self.ctx.feed:FireAllClients("ArcLink",{origin=hit.Position,finish=finish})
                            if links>=def.chain then break end
                        end
                    end
                end
                remaining=remaining-(endpoint-current).Magnitude current=endpoint+shot*.15
            else
                if def.splash then self:explode(endpoint,def.splash,stats.damage*.7,player,nil,false,attack) end
                break
            end
        end
    end
    self.ctx.feed:FireAllClients("Shot",{player=player.UserId,origin=origin,ends=ends,weapon=g.id})
    if hitAny then self.ctx.feed:FireClient(player,"Hit",{kill=killAny,head=headAny,damage=math.floor(hitTotal)}) end
    self:ammo(player,args.seq)
end
function B:reload(player)
    local p=self.ctx.players[player] if not p or p.status~="Alive" or not p.participating then return end
    local g=self:gun(p) if not g then return end
    local stats=R.weaponStats(C.Weapons[g.id],g.tier,p.perks)
    if g.mag>=stats.mag or g.reserve<=0 or g.reloadUntil>os.clock() then return end
    g.reloadUntil=os.clock()+stats.reload p.sprinting=false
    self.ctx.feed:FireClient(player,"Reload",{duration=stats.reload,weapon=g.id}) self:ammo(player)
end
function B:swap(player,slot)
    local p=self.ctx.players[player] if not p or p.status~="Alive" or not p.participating then return end
    local index=tonumber(slot) if index~=1 and index~=2 then index=p.slot==1 and 2 or 1 end
    if not p.guns[index] or p.slot==index then return end
    local old=self:gun(p) if old then old.reloadUntil=0 end
    p.slot=index p.nextShot=os.clock()+.28
    self:visual(player) self:ammo(player)
end
function B:hurt(player,amount,source,kind)
    local p=self.ctx.players[player] if not p or not p.participating or p.status~="Alive" then return end
    local now=os.clock() if now<(p.invulnerableUntil or 0) then return end
    if kind=="Enemy" then
        if now<(p.nextEnemyDamage or 0) then return end
        p.nextEnemyDamage=now+R.enemyHitGrace(self.ctx.run.round)
    end
    p.health=math.max(0,p.health-amount) p.lastHurt=now self.ctx.interact:cancel(player)
    self.ctx.feed:FireClient(player,"Hurt",{health=p.health,source=source})
    if p.health<=0 then self.ctx.game:down(player) else
        local hum=U.humanoid(player) if hum then hum.Health=math.max(1,p.health) end
    end
end
function B:melee(player)
    local valid,p,root=self:ready(player) if not valid or os.clock()<(p.nextMelee or 0) then return end
    p.nextMelee=os.clock()+.85 p.nextShot=os.clock()+.3
    local closest,dist=nil,7
    for _,e in pairs(self.ctx.enemies.list) do
        local delta=e.root.Position-root.Position local d=delta.Magnitude
        if d<dist and d>.001 and root.CFrame.LookVector:Dot(delta.Unit)>.35 and self.ctx.enemies:clearSight(root.Position,e.root.Position) then closest=e dist=d end
    end
    self.ctx.feed:FireAllClients("Melee",{player=player.UserId})
    if closest then
        local damage=(self.ctx.run.effects.Instant or 0)>os.clock() and closest.kind~="Warden" and closest.hp or 140
        local kill=self.ctx.enemies:damage(closest,damage,player,false,self:attackKey(player),"Melee")
        if kill then self.ctx.game:addPoints(player,C.Economy.meleeKill) else self:hitReward(player,closest,C.Economy.meleeHit) end
        self.ctx.feed:FireClient(player,"Hit",{kill=kill,head=false,damage=damage})
    end
end
function B:explode(position,radius,damage,owner,ignore,selfDamage,attack)
    local now=os.clock()
    attack=attack or self:attackKey(owner)
    for _,e in pairs(self.ctx.enemies.list) do
        local distance=(e.root.Position-position).Magnitude
        if e.id~=ignore and distance<radius and self.ctx.enemies:clearSight(position+Vector3.new(0,.5,0),e.root.Position) then
            local amount=damage*(1-distance/radius*.6)
            if (self.ctx.run.effects.Instant or 0)>now and e.kind~="Warden" then amount=e.hp end
            self.ctx.enemies:damage(e,amount,owner,false,attack,"Explosion")
        end
    end
    local p=owner and self.ctx.players[owner] local root=owner and U.root(owner)
    if selfDamage and p and root and not p.perks.Insulator then
        local d=(root.Position-position).Magnitude
        if d<radius and self.ctx.enemies:clearSight(position+Vector3.new(0,.5,0),root.Position) then self:hurt(owner,math.floor(100*(1-d/radius)),position) end
    end
    self.ctx.feed:FireAllClients("Explosion",{position=position,radius=radius})
end
function B:grenade(player,args)
    local valid,p,root=self:ready(player)
    if not valid or p.grenades<=0 or os.clock()<(p.nextGrenade or 0) or type(args)~="table" or not U.finiteVector(args.direction) then return end
    local m=args.direction.Magnitude if m<.98 or m>1.02 then return end
    p.nextGrenade=os.clock()+.7 p.grenades=p.grenades-1
    local pos=root.Position+Vector3.new(0,1.5,0)
    local obj=U.make("Part",workspace,{Name="DeadSignalGrenade",Shape=Enum.PartType.Ball,Size=Vector3.new(.6,.6,.6),
        Position=pos,Color=Color3.fromRGB(73,96,62),Material=Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false})
    self.projectiles[#self.projectiles+1]={part=obj,position=pos,velocity=args.direction.Unit*60+Vector3.new(0,16,0),expires=os.clock()+2.4,owner=player,runId=self.ctx.run.id}
end
function B:tick(now,dt)
    for player,p in pairs(self.ctx.players) do
        if p.participating and p.status=="Alive" then
            for _,g in ipairs(p.guns) do
                if g.reloadUntil>0 and now>=g.reloadUntil then
                    g.reloadUntil=0 local stats=R.weaponStats(C.Weapons[g.id],g.tier,p.perks)
                    local n=math.min(stats.mag-g.mag,g.reserve) g.mag=g.mag+n g.reserve=g.reserve-n self:ammo(player)
                end
            end
        end
    end
    for i=#self.projectiles,1,-1 do
        local g=self.projectiles[i]
        if g.runId~=self.ctx.run.id or not self.ctx.game:isCombat() then g.part:Destroy() table.remove(self.projectiles,i)
        elseif now>=g.expires then self:explode(g.position,15,800+80*self.ctx.run.round,g.owner,nil,true) g.part:Destroy() table.remove(self.projectiles,i)
        else
            g.velocity=g.velocity+Vector3.new(0,-workspace.Gravity,0)*dt
            local step=g.velocity*dt
            local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={self.ctx.map.model}
            local hit=workspace:Raycast(g.position,step,params)
            if hit then g.position=hit.Position+hit.Normal*.32 g.velocity=(g.velocity-2*g.velocity:Dot(hit.Normal)*hit.Normal)*.4
            else g.position=g.position+step end
            if g.position.Y<.35 then g.position=Vector3.new(g.position.X,.35,g.position.Z) g.velocity=Vector3.new(g.velocity.X*.9,math.abs(g.velocity.Y)*.25,g.velocity.Z*.9) end
            g.part.Position=g.position
        end
    end
end
function B:clear()
    for _,g in ipairs(self.projectiles) do g.part:Destroy() end self.projectiles={}
end
return B
