local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local Evolution=require(RS.DeadSignal.DirectorRules)
local U=require(RS.DeadSignal.Util)
local Movement=require(RS.DeadSignal.Movement)
local Downed=require(RS.DeadSignal.DownedPose)
local Extraction=require(RS.DeadSignal.Extraction)
local ExtractionZone=require(script.Parent.ExtractionZone)
local W=require(RS.DeadSignal.WeaponModels)
local ThirdPerson=require(RS.DeadSignal.ThirdPerson)
local Map=require(script.Parent.MapBuilder)
local Bounds=require(script.Parent.BoundaryGuard)
local PC=require(RS.DeadSignal.PlaceConfig)
local RunService=game:GetService("RunService")
local G={} G.__index=G
local function freshStats() return {kills=0,headshots=0,revives=0,rounds=0,bestRound=0} end
function G.new(ctx)
    local self=setmetatable({ctx=ctx,drops={},box=nil},G)
    ctx.run={id=0,phase=ctx.role=="Match" and "Arriving" or "Lobby",round=0,mode="Standard",map=PC.Map,effects={},peak=0,admitted={},deadline=0}
    ctx.holding=Map.holding()
    ctx.lobby=ctx.role=="Match" and ctx.holding or Map.lobby() Map.environment(ctx.role=="Match" and PC.Map or "Lobby")
    if ctx.role=="Lobby" then local old=workspace:FindFirstChild("DeadSignalMap") if old then old:Destroy() end end
    if not ctx.role then ctx.interact:bind(ctx.lobby.kiosk,"DISPATCH","Choose operation",0,function(player) ctx.feed:FireClient(player,"OpenLobby",{}) end,{lobby=true,distance=13}) end
    return self
end
function G:toast(player,text,color) if player.Parent then self.ctx.feed:FireClient(player,"Toast",{text=text,color=color or "amber"}) end end
function G:broadcast(text,color) self.ctx.feed:FireAllClients("Banner",{text=text,color=color or "red"}) end
function G:isCombat() local phase=self.ctx.run.phase return phase=="Wave" or phase=="Intermission" or phase=="Preparing" or phase=="Exfil" end
function G:participantCount()
    local n=0 for _,p in pairs(self.ctx.players) do if p.participating then n=n+1 end end return n
end
function G:aliveCount()
    local n=0 for _,p in pairs(self.ctx.players) do if p.participating and p.status=="Alive" then n=n+1 end end return n
end
function G:spawnCharacter(player,position)
    local p=self.ctx.players[player] if not p then return end
    ThirdPerson.clear(player.Character) Downed.clear(p)
    p.motion=nil p.moveIntent=nil p.moveAt=nil p.inputBlocked=false p.sprintRequested=false p.movementFeedback=nil
    p.spawnToken=(p.spawnToken or 0)+1 local token=p.spawnToken
    task.spawn(function()
        local ok=pcall(function() player:LoadCharacterAsync() end)
        if not player.Parent or self.ctx.players[player]~=p or p.spawnToken~=token then return end
        if not ok then
            if p.participating then self:eliminate(player)
            else task.delay(3,function() if self.ctx.players[player]==p and p.status=="Lobby" then self:spawnCharacter(player,self.ctx.lobby.position) end end) end
            return
        end
        local char=player.Character if not char then return end
        local root=char:WaitForChild("HumanoidRootPart",8) local hum=char:FindFirstChildOfClass("Humanoid")
        if p.spawnToken~=token then return end
        if not root or not hum then if p.participating then self:eliminate(player) end return end
        char:PivotTo(CFrame.new(position)*CFrame.Angles(0,math.pi,0))
        hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.MaxHealth=p.health>100 and p.health or 100 hum.Health=hum.MaxHealth
        hum.WalkSpeed=p.status=="Results" and 0 or 16 hum.UseJumpPower=true hum.JumpPower=0 Movement.noJump(hum,player)
        local function collision(obj) if obj:IsA("BasePart") then obj.CollisionGroup="DeadSignalPlayers" end end
        for _,obj in ipairs(char:GetDescendants()) do collision(obj) end
        char.DescendantAdded:Connect(collision)
        hum.Died:Connect(function()
            if self.ctx.players[player]~=p or p.spawnToken~=token then return end
            if p.status=="Eliminated" or p.status=="Results" or p.status=="Waiting" then
                task.delay(2,function() if self.ctx.players[player]==p and (p.status=="Eliminated" or p.status=="Results" or p.status=="Waiting") then self:spawnCharacter(player,self.ctx.holding.position) end end)
            elseif p.participating and self:isCombat() then self:eliminate(player)
            elseif p.status=="Lobby" or p.status=="Rejected" or p.status=="Waiting" or p.status=="Arriving" then task.delay(2,function() if self.ctx.players[player]==p and not p.participating then self:spawnCharacter(player,self.ctx.lobby.position) end end)
            elseif p.status=="Eliminated" then task.delay(2,function() if self.ctx.players[player]==p and p.status=="Eliminated" then self:spawnCharacter(player,self.ctx.lobby.position) end end) end
        end)
        p.lastPosition=root.Position p.lastSample=os.clock() p.invulnerableUntil=os.clock()+4
        p.safePosition=p.participating and root.Position or nil
        if p.participating and p.status=="Alive" then self.ctx.combat:visual(player) end
        if p.bay and self.ctx.lobbyService and not p.participating then self.ctx.lobbyService:seat(player,self.ctx.lobbyService.bays[p.bay]) end
    end)
end
function G:addPlayer(player)
    if self.ctx.players[player] then return end
    local p={status="Lobby",participating=false,ready=false,vote="Station",mode="Standard",health=100,points=0,
        stamina=100,perks={},guns={},slot=1,grenades=0,stats=freshStats(),nextShot=0,lastHurt=0,spawnToken=0}
    self.ctx.players[player]=p
    player:SetAttribute("DeadSignalStatus","Lobby")
    self:spawnCharacter(player,self.ctx.lobby.position)
    if self.ctx.role=="Match" then p.status="Arriving" end
    task.spawn(function()
        self.ctx.data:load(player)
        if not player.Parent or self.ctx.players[player]~=p then return end
        if self.ctx.travel then if self.ctx.role=="Match" then self.ctx.travel:acceptMatch(player) else self.ctx.travel:acceptReturn(player) end end
    end)
end
function G:queue(player,ready,mapId,modeId)
    if self.ctx.role then self:toast(player,"Walk into a dispatch bay to form your crew.") return end
    local p=self.ctx.players[player] local profile=self.ctx.data.profiles[player]
    if not p or p.participating then return end
    if not profile or not profile.loaded then self:toast(player,"Operator profile is still loading. Try again in a moment.") return end
    if self.ctx.run.admitted[player.UserId] and self:isCombat() then self:toast(player,"You can deploy again after this operation.") return end
    p.ready=ready==true
    if C.Maps[mapId] then p.vote=mapId end if C.Modes[modeId] then p.mode=modeId end
    if p.ready then self:toast(player,self:isCombat() and "Queued for the next round, when a slot opens." or "Deployment queued.","cyan") end
end
function G:pay(player,amount)
    local p=self.ctx.players[player] if p.points<amount then self:toast(player,"Need "..amount.." points.") return false end
    p.points=p.points-amount return true
end
function G:addPoints(player,amount,ignoreDouble)
    local p=self.ctx.players[player] if not p or not p.participating then return end
    if not ignoreDouble and (self.ctx.run.effects.Double or 0)>os.clock() then amount=amount*2 end
    p.points=p.points+math.floor(amount)
    self.ctx.feed:FireClient(player,"Points",{amount=amount,total=p.points})
end
function G:admit(player)
    local p=self.ctx.players[player] if not p or self:participantCount()>=C.MaxPlayers then return false end
    if self.ctx.role=="Match" and not p.matchAllowed then return false end
    local root=U.root(player) if root then root.Anchored=false end
    p.ready=false p.participating=true p.status="Alive" p.health=100 p.stamina=100 p.perks={} p.guns={} p.slot=1
    p.grenades=2 p.points=C.StartPoints+math.max(0,self.ctx.run.round-1)*60 p.stats=freshStats() p.rewarded=false
    p.selfRevives=0 p.selfAt=nil p.repairReward=0 p.sprinting=false p.aiming=false p.accepted=0 p.nextEnemyDamage=0
    self.ctx.run.admitted[player.UserId]=true self.ctx.run.peak=math.max(self.ctx.run.peak,self:participantCount())
    self.ctx.combat:give(player,"Kestrel",0)
    self:spawnCharacter(player,self.ctx.map.spawnPoints[(self:participantCount()-1)%4+1])
    player:SetAttribute("DeadSignalStatus","Alive")
    self.ctx.feed:FireClient(player,"Deploy",{map=self.ctx.run.map})
    return true
end
function G:start(mapId,modeId)
    if self:isCombat() or self.ctx.run.phase=="Results" then return false end
    local ctx=self.ctx
    ctx.run={id=ctx.run.id+1,phase="Preparing",round=0,map=C.Maps[mapId] and mapId or "Station",
        mode=C.Modes[modeId] and modeId or "Standard",effects={},peak=0,admitted={},deadline=os.clock()+7,
        power=false,fuses=0,linked=false,signal=false,code={math.random(1,4),math.random(1,4),math.random(1,4)},spawnRemaining=0}
    ctx.interact:clearMap() ctx.enemies:clear() ctx.combat:clear()
    ctx.map=Map.build(ctx.run.map) Map.environment(ctx.run.map) self:bindMap()
    for _,player in ipairs(Players:GetPlayers()) do local p=ctx.players[player] if p and p.ready then self:admit(player) end end
    if self:participantCount()==0 then self:finish(false,"No operators deployed.") return false end
    self:broadcast(C.Maps[ctx.run.map].name.." / "..C.Modes[ctx.run.mode].name,"amber")
    return true
end
function G:bindMap()
    local ctx=self.ctx local map=ctx.map
    for _,door in ipairs(map.doors) do
        ctx.interact:bind(door.part,door.name or "SECTOR ACCESS",tostring(door.cost).." points",.5,function(player)
            if door.open or not (map.rooms[door.a].unlocked or map.rooms[door.b].unlocked) or not self:pay(player,door.cost) then return end
            door.open=true map.navigationRevision=(map.navigationRevision or 0)+1 map.rooms[door.a].unlocked=true map.rooms[door.b].unlocked=true
            local function hide(obj) if obj:IsA("BasePart") then obj.Transparency=1 obj.CanCollide=false obj.CanQuery=false elseif obj:IsA("SurfaceGui") then obj.Enabled=false elseif obj:IsA("ProximityPrompt") then obj.Enabled=false end end
            hide(door.part) for _,obj in ipairs(door.part:GetDescendants()) do hide(obj) end
            self:broadcast(player.DisplayName.." opened a new route.","amber")
        end,{allowWall=true})
    end
    for _,window in ipairs(map.windows) do
        ctx.interact:bind(window.part,"BARRICADE","Repair board",.65,function(player,p)
            if window.count>=5 or not map.rooms[window.room].unlocked then return end
            window.count=window.count+1 window.boards[window.count].Transparency=0
            if p.repairReward<C.Economy.repairCap then
                local reward=math.min(C.Economy.repair,C.Economy.repairCap-p.repairReward)
                p.repairReward=p.repairReward+reward self:addPoints(player,reward)
            end
        end,{allowWall=true,distance=9})
    end
    for key,machine in pairs(map.perks) do
        local perk=C.Perks[key]
        ctx.interact:bind(machine.part,perk.name,"Round "..perk.round.." / "..perk.price.."+ points",.65,function(player,p)
            local solo=ctx.run.peak<=1 and self:participantCount()==1
            if not ctx.run.power then self:toast(player,"Restore the power first.") return end
            local unlock=solo and key=="Lifeline" and perk.soloRound or perk.round
            if ctx.run.round<unlock then self:toast(player,perk.name.." becomes available at round "..unlock..".") return end
            if key=="Lifeline" and solo and not C.Modes[ctx.run.mode].selfRevive then self:toast(player,"Automatic revives are disabled in Lockdown.") return end
            if p.perks[key] then self:toast(player,"You already have this perk.") return end
            if U.count(p.perks)>=C.MaxPerks then self:toast(player,"Four perk limit. Choose your build carefully.") return end
            if key=="Lifeline" and solo and p.selfRevives>=3 then self:toast(player,"All three solo Lifelines have been used.") return end
            local price=(key=="Lifeline" and solo and perk.soloPrice or perk.price)+U.count(p.perks)*C.PerkExtraCost
            if not self:pay(player,price) then return end
            p.perks[key]=true if key=="Lifeline" and solo then p.selfRevives=p.selfRevives+1 end
            if key=="Ironheart" then p.health=200 local hum=U.humanoid(player) if hum then hum.MaxHealth=200 hum.Health=200 end end
            self:toast(player,perk.name..": "..perk.description,"cyan") ctx.feed:FireClient(player,"Cue",{name="Perk"})
        end,{allowWall=true})
    end
    for _,buy in ipairs(map.wallBuys) do
        local def=C.Weapons[buy.id]
        ctx.interact:bind(buy.part,def.name,"Buy "..def.cost.." / refill",.35,function(player,p)
            for _,gun in ipairs(p.guns) do if gun.id==buy.id then
                local stat=R.weaponStats(def,gun.tier,p.perks)
                if gun.reserve>=stat.reserve and gun.mag>=stat.mag then self:toast(player,"Ammunition is already full.") return end
                if self:pay(player,R.refillPrice(def,gun.tier)) then gun.mag=stat.mag gun.reserve=stat.reserve gun.reloadUntil=0 ctx.combat:ammo(player) end
                return
            end end
            if self:pay(player,def.cost) then ctx.combat:give(player,buy.id,0) end
        end,{allowWall=true})
    end
    ctx.interact:bind(map.power,"MAIN BREAKER","Restore power",1.8,function(player,_,prompt)
        if ctx.run.power then return end ctx.run.power=true prompt.Enabled=false Map.power(map)
        self:broadcast("POWER ONLINE / Machines and traps restored.","cyan") ctx.feed:FireAllClients("Cue",{name="Power"})
    end,{allowWall=true})
    for _,fuse in ipairs(map.fuses) do
        ctx.interact:bind(fuse.part,"SIGNAL FUSE","Collect",.25,function(player,_,prompt)
            if fuse.collected then return end fuse.collected=true fuse.part.Transparency=1 prompt.Enabled=false ctx.run.fuses=ctx.run.fuses+1
            self:broadcast("SIGNAL FUSE "..ctx.run.fuses.." / 3", "cyan")
        end,{allowWall=true})
    end
    ctx.interact:bind(map.relay,"TRANSMITTER","Install / verify frequencies",1.2,function(player)
        if not ctx.run.power then self:toast(player,"Restore the generator first.") return end
        if ctx.run.fuses<3 then self:toast(player,"Find all three glowing fuses.") return end
        if not ctx.run.linked then
            ctx.run.linked=true
            local code=table.concat(ctx.run.code," – ")
            map.relay.Sign.SurfaceGui.TextLabel.Text="SET DIALS: "..code.."\nTHEN VERIFY HERE"
            self:broadcast("FORGE ONLINE / Signal code: "..code,"cyan") return
        end
        if ctx.run.signal then self:toast(player,"Signal restored. Extraction opens at round 15.","cyan") return end
        for i,panel in ipairs(map.panels) do if panel.value~=ctx.run.code[i] then self:toast(player,"Frequency mismatch. Read the code above the transmitter.") return end end
        ctx.run.signal=true map.relay.Sign.SurfaceGui.TextLabel.Text="SIGNAL RESTORED\nRESCUE CHANNEL OPEN AT ROUND 15"
        self:broadcast("THE SIGNAL IS BROKEN / Rescue can hear you.","cyan")
    end,{allowWall=true})
    for i,panel in ipairs(map.panels) do
        ctx.interact:bind(panel.part,"FREQUENCY DIAL "..i,"Cycle 1–4",0,function(player)
            if not ctx.run.linked then self:toast(player,"Install the transmitter fuses first.") return end
            if ctx.run.signal then return end panel.value=panel.value%4+1
            panel.screen.SurfaceGui.TextLabel.Text="FREQUENCY "..i.."\n"..panel.value
        end,{allowWall=true})
    end
    ctx.interact:bind(map.upgrade,"RESONANCE FORGE","Upgrade held weapon",1.4,function(player,p)
        if not ctx.run.power or not ctx.run.linked then self:toast(player,"Power the station and install three transmitter fuses.") return end
        local gun=ctx.combat:gun(p) if not gun or gun.tier>=2 then self:toast(player,"This weapon is fully resonant.") return end
        if not self:pay(player,gun.tier==0 and 5000 or 7500) then return end
        gun.tier=gun.tier+1 local stat=R.weaponStats(C.Weapons[gun.id],gun.tier,p.perks)
        gun.mag=stat.mag gun.reserve=stat.reserve gun.reloadUntil=0
        ctx.combat:visual(player) ctx.combat:ammo(player) self:toast(player,stat.name.." / Resonance "..gun.tier,"cyan") ctx.feed:FireClient(player,"Cue",{name="Power"})
    end,{allowWall=true})
    for _,trap in ipairs(map.traps) do
        ctx.interact:bind(trap.part,"ARC FENCE","1000 / hazardous field",.6,function(player)
            local now=os.clock()
            if not ctx.run.power then self:toast(player,"Restore the power first.") return end
            if now<trap.cooldownUntil then self:toast(player,"Trap cooling down: "..math.ceil(trap.cooldownUntil-now).."s") return end
            if not self:pay(player,1000) then return end
            trap.activeUntil=now+25 trap.cooldownUntil=now+70 trap.owner=player trap.beam.Transparency=.4
            self:broadcast("ARC FENCE ACTIVE / Keep clear without Insulator.","cyan")
        end,{allowWall=true})
    end
    ctx.interact:bind(map.radio,"RESCUE CHANNEL","Vote for extraction",1,function(player)
        if not ctx.run.signal or ctx.run.round<15 then self:toast(player,"Restore the signal and reach round 15.") return end
        if ctx.run.phase=="Exfil" then return end
        local now=os.clock()
        if not ctx.run.exfilVoteUntil or ctx.run.exfilVoteUntil<now then ctx.run.exfilVotes={} ctx.run.exfilVoteUntil=now+25 end
        ctx.run.exfilVotes[player.UserId]=true
        local n=0 for plr,p in pairs(ctx.players) do if p.participating and p.status=="Alive" and ctx.run.exfilVotes[plr.UserId] then n=n+1 end end
        local needed=R.majority(self:aliveCount()) self:broadcast("EXTRACTION VOTE "..n.." / "..needed,"amber")
        if n>=needed then self:exfil() end
    end,{allowWall=true})
    for _,counter in ipairs(map.counters or {}) do
        ctx.interact:bind(counter.part,counter.kind=="Vent" and "VENTILATION" or "FIRE SUPPRESSION","Activate for 12 seconds",.65,function(player)
            local now=os.clock()
            if not ctx.run.power then self:toast(player,"Restore the power first.") return end
            if not map.rooms[counter.room].unlocked then return end
            if now<counter.cooldownUntil then self:toast(player,"System cooling down: "..math.ceil(counter.cooldownUntil-now).."s") return end
            counter.cooldownUntil=now+C.Evolution.counters.cooldown
            ctx.enemies:counter(counter.kind,counter.part.Position,now)
            self:toast(player,counter.kind=="Vent" and "Ventilation clearing nearby smoke." or "Suppression clearing nearby flames.","cyan")
        end)
    end
    self:makeBox()
end
function G:makeBox()
    local map=self.ctx.map local spot=map.boxSpots[2]
    local model=U.make("Model",map.model,{Name="SupplyBox"})
    local p=Map.part(model,"Crate",Vector3.new(7,3,3),spot.cf,Color3.fromRGB(116,85,53),Enum.Material.WoodPlanks,true)
    model.PrimaryPart=p
    local lids={}
    local steel=Color3.fromRGB(57,66,66)
    for _,x in ipairs({-2.6,2.6}) do
        Map.part(model,"CrateStrap",Vector3.new(.28,3.1,3.12),spot.cf*CFrame.new(x,0,0),steel,Enum.Material.Metal,false).CanQuery=false
        Map.part(model,"CrateHandle",Vector3.new(.14,.65,.85),spot.cf*CFrame.new(x<0 and -3.57 or 3.57,.25,0),steel,Enum.Material.Metal,false).CanQuery=false
    end
    local function lid(name,size,cf,col,mat)
        local q=Map.part(model,name,size,spot.cf*cf,col,mat,false) q.CanQuery=false
        table.insert(lids,{part=q,cf=cf}) return q
    end
    lid("HingedLid",Vector3.new(7.2,.35,3.2),CFrame.new(0,1.68,0),Color3.fromRGB(126,95,59),Enum.Material.WoodPlanks)
    for _,x in ipairs({-2.6,2.6}) do lid("LidStrap",Vector3.new(.3,.4,3.26),CFrame.new(x,1.68,0),steel,Enum.Material.Metal) end
    for _,x in ipairs({-3.25,3.25}) do for _,z in ipairs({-1.55,1.55}) do
        Map.part(model,"CornerPlate",Vector3.new(.35,2.8,.18),spot.cf*CFrame.new(x,0,z),steel,Enum.Material.Metal,false).CanQuery=false
    end end
    local lidGlow=lid("SupplyGlow",Vector3.new(6.5,.03,2.5),CFrame.new(0,1.48,0),Color3.fromRGB(93,158,211),Enum.Material.Neon)
    lidGlow.Transparency=.3
    local label=Map.sign(model,"UNKNOWN SUPPLY / 950",spot.cf*CFrame.new(0,3,0),Vector3.new(13,2,.2),Color3.fromRGB(222,180,84))
    U.make("PointLight",p,{Color=Color3.fromRGB(102,154,240),Brightness=1.5,Range=15})
    self.box={model=model,part=p,label=label,lids=lids,spot=2,uses=0,readyAt=0,expires=0,result=nil,owner=nil}
    self.box.prompt=self.ctx.interact:bind(p,"UNKNOWN SUPPLY","Roll / take weapon",.45,function(player)
        local b=self.box local now=os.clock()
        if b.owner then
            if b.owner~=player then self:toast(player,"This supply roll belongs to another operator.") return end
            if now<b.readyAt then return end
            if b.result then self.ctx.combat:give(player,b.result,0) self:clearBox() end
            return
        end
        if not self:pay(player,R.boxPrice(self.ctx.run.effects,now)) then return end
        local total=0 for _,id in ipairs(C.BoxPool) do total=total+C.Weapons[id].weight end
        local roll=math.random()*total
        for _,id in ipairs(C.BoxPool) do roll=roll-C.Weapons[id].weight if roll<=0 then b.result=id break end end
        b.result=b.result or "Vandal" b.owner=player b.readyAt=now+3 b.expires=now+18 b.uses=b.uses+1
        self:boxLid(true)
        b.label.SurfaceGui.TextLabel.Text="SEARCHING THE STATIC..." self.ctx.feed:FireAllClients("Cue",{name="Box"})
    end,{allowWall=true})
end
function G:boxLid(open)
    local b=self.box if not b then return end
    local hinge=CFrame.new(0,1.5,1.5)*CFrame.Angles(open and 1.12 or 0,0,0)*CFrame.new(0,-1.5,-1.5)
    for _,q in ipairs(b.lids or {}) do q.part.CFrame=b.part.CFrame*hinge*q.cf end
end
function G:clearBox()
    local b=self.box if not b then return end
    if b.preview then b.preview:Destroy() b.preview=nil end
    self:boxLid(false)
    b.owner=nil b.result=nil b.readyAt=0 b.expires=0
    b.label.SurfaceGui.TextLabel.Text="UNKNOWN SUPPLY / 950" b.prompt.ObjectText="UNKNOWN SUPPLY"
    if b.uses>=5 then
        local choices={} for i,spot in ipairs(self.ctx.map.boxSpots) do if i~=b.spot and self.ctx.map.rooms[spot.room].unlocked then table.insert(choices,i) end end
        if #choices>0 then
            b.spot=choices[math.random(1,#choices)] b.model:PivotTo(self.ctx.map.boxSpots[b.spot].cf) b.uses=0
            self:broadcast("UNKNOWN SUPPLY relocated. Follow the blue glow.","cyan")
        end
    end
end
function G:revive(target,reviver)
    local p=self.ctx.players[target] if not p or p.status~="Down" then return end
    Downed.clear(p)
    local root=U.root(target)
    if root then root.CFrame=root.CFrame+Vector3.new(0,2,0) root.AssemblyLinearVelocity=Vector3.new() p.lastPosition=root.Position p.lastSample=os.clock() end
    p.status="Alive" p.selfAt=nil p.health=R.health(p.perks) p.invulnerableUntil=os.clock()+4 p.lastHurt=os.clock()
    p.motion=nil p.moveIntent=nil p.moveAt=nil p.sprintRequested=false p.sprinting=false p.movementFeedback=nil
    if p.revivePrompt then p.revivePrompt:Destroy() p.revivePrompt=nil end
    local hum=U.humanoid(target) if hum then hum.MaxHealth=p.health hum.Health=p.health hum.JumpPower=0 Movement.noJump(hum) end
    target:SetAttribute("DeadSignalStatus","Alive")
    self.ctx.combat:visual(target)
    if reviver and self.ctx.players[reviver] then self.ctx.players[reviver].stats.revives=self.ctx.players[reviver].stats.revives+1 self:addPoints(reviver,C.Economy.revive,true) end
    self:broadcast(target.DisplayName.." is back on their feet.","cyan") self.ctx.feed:FireAllClients("Cue",{name="Revive"})
end
function G:down(player)
    local p=self.ctx.players[player] if p.status~="Alive" then return end
    local solo=self.ctx.run.peak<=1 and self:participantCount()==1
    local automatic=solo and p.perks.Lifeline and C.Modes[self.ctx.run.mode].selfRevive
    p.status="Down" p.health=0 p.downUntil=os.clock()+C.DownTime p.selfAt=automatic and os.clock()+6 or nil
    p.perks={} p.sprinting=false p.aiming=false p.sprintRequested=false p.movementFeedback=nil
    for _,gun in ipairs(p.guns) do gun.reloadUntil=0 end
    local hum=U.humanoid(player) if hum then hum.Health=1 hum.WalkSpeed=3 hum.JumpPower=0 end
    player:SetAttribute("DeadSignalStatus","Down")
    ThirdPerson.clear(player.Character) Downed.begin(player,p)
    local root=U.root(player)
    if root then
        p.revivePrompt=self.ctx.interact:bind(root,player.DisplayName,"Revive operator",3,function(reviver)
            if reviver~=player then self:revive(player,reviver) end
        end,{distance=8,allowWall=false,required=function(reviver) return R.reviveTime(self.ctx.players[reviver].perks) end})
        p.revivePrompt:SetAttribute("RevivePrompt",true)
    end
    self:broadcast(player.DisplayName.." is down!", "red") self.ctx.feed:FireClient(player,"Cue",{name="Down"})
end
function G:eliminate(player)
    local p=self.ctx.players[player] if not p or not p.participating or p.status=="Eliminated" then return end
    ThirdPerson.clear(player.Character) Downed.clear(p)
    p.status="Eliminated" p.perks={} p.selfAt=nil p.sprinting=false p.sprintRequested=false p.movementFeedback=nil
    if p.revivePrompt then p.revivePrompt:Destroy() p.revivePrompt=nil end
    local hum=U.humanoid(player) if hum then hum.WalkSpeed=0 hum.JumpPower=0 end
    player:SetAttribute("DeadSignalStatus","Eliminated")
    self:spawnCharacter(player,self.ctx.holding.position)
    self:toast(player,"Spectating. You return when the crew clears this round.")
end
function G:wave()
    local run=self.ctx.run run.round=run.round+1 run.phase="Wave" run.bossSpawned=false run.bossAlive=false
    for _,player in ipairs(Players:GetPlayers()) do
        local p=self.ctx.players[player]
        if p and p.ready and not p.participating and not run.admitted[player.UserId] then self:admit(player) end
    end
    for player,p in pairs(self.ctx.players) do
        if p.participating then
            if p.status=="Eliminated" then
                p.status="Alive" p.health=100 p.perks={} p.guns={} p.slot=1 p.points=math.max(p.points,300+run.round*45)
                self.ctx.combat:give(player,"Kestrel",0) self:spawnCharacter(player,self.ctx.map.spawnPoints[1])
                player:SetAttribute("DeadSignalStatus","Alive")
            elseif p.status=="Down" then self:revive(player,nil) end
            p.stats.bestRound=math.max(p.stats.bestRound,run.round) p.repairReward=0 p.grenades=math.min(4,p.grenades+2)
        end
    end
    self.ctx.director:begin(os.clock())
    run.event=Evolution.event(run.round,run.phase,C.Evolution,R.isWardenRound(run.round))
    run.special=run.event~=nil run.eventRewarded=false run.evolutionCounts={stalkers=0,alphas=0,combined=0}
    run.spawnRemaining=Evolution.specialQuota(R.waveCount(run.round,math.max(1,self:aliveCount()),C.Modes[run.mode]),run.event)
    run.nextSpawn=os.clock()+(run.event and C.Evolution.preparation or 3)
    run.eventReadyAt=run.nextSpawn
    local event=run.event and run.event.name or R.isWardenRound(run.round) and "WARDEN SIGNAL DETECTED" or ""
    if run.event then self.ctx.feed:FireAllClients("SpecialWave",{id=run.event.id,name=run.event.name,hint=run.event.hint,cue=run.event.cue,preparation=C.Evolution.preparation}) end
    self:broadcast("ROUND "..run.round..(event~="" and " / "..event or ""),"red")
    self.ctx.feed:FireAllClients("Cue",{name="Round"})
end
function G:selectWindow() return self.ctx.director:window(os.clock()) end
function G:spawnEnemy(now)
    local run=self.ctx.run
    local limit,interval=self.ctx.director:budget(now)
    if run.spawnRemaining<=0 or now<run.nextSpawn or self.ctx.enemies:count()>=limit then return end
    local window=self.ctx.director:window(now)
    if not window then run.nextSpawn=now+.5 return end
    local kind,mods="Shambler",{}
    if not run.bossSpawned and (run.phase=="Exfil" or R.isWardenRound(run.round)) then kind="Warden"
    elseif run.phase~="Exfil" and not R.isWardenRound(run.round) then
        kind,mods=Evolution.evolution(run.round,run.event,(self.ctx.director.spawned or 0)+1,C.Evolution,math.random(),math.random(),run.evolutionCounts)
        if not run.event and kind=="Shambler" then
            if math.random()<R.crawlerChance(run.round) then kind="Crawler" elseif math.random()<R.runnerChance(run.round) then kind="Runner" end
        end
    elseif math.random()<R.runnerChance(run.round) then kind="Runner" end
    local counts=run.evolutionCounts or {} run.evolutionCounts=counts
    if kind=="Stalker" then counts.stalkers=(counts.stalkers or 0)+1 end
    if mods.Alpha then counts.alphas=(counts.alphas or 0)+1 end
    if mods.Armored and mods.Enraged then counts.combined=(counts.combined or 0)+1 end
    self.ctx.enemies:spawn(kind,window,nil,mods)
    if kind=="Warden" then run.bossSpawned=true run.bossAlive=true end
    self.ctx.director:spawnedOne()
    run.spawnRemaining=math.max(0,run.spawnRemaining-1) run.nextSpawn=now+interval
end
function G:rewardSpecial()
    local run=self.ctx.run
    if not Evolution.canReward(run) then return false end
    run.eventRewarded=true
    for player,p in pairs(self.ctx.players) do if p.participating then
        self:addPoints(player,Evolution.specialReward(run.round,C.Evolution.rewards),true)
        for _,gun in ipairs(p.guns) do local stats=R.weaponStats(C.Weapons[gun.id],gun.tier,p.perks)
            gun.reserve=math.min(stats.reserve,gun.reserve+math.ceil(stats.reserve*C.Evolution.rewards.ammoFraction))
        end
        self.ctx.combat:ammo(player)
    end end
    self:broadcast(run.event.name.." CLEARED / Bonus points and reserve ammunition.","cyan")
    return true
end
function G:exfil()
    local run=self.ctx.run self.ctx.enemies:clear()
    self.ctx.director:begin(os.clock())
    run.phase="Exfil" run.deadline=os.clock()+C.Extraction.seconds run.exfilProgress=0
    run.spawnRemaining=C.Extraction.escorts+C.Extraction.escortsPerPlayer*math.max(1,self:aliveCount())
    run.exfilStage="Warden" run.bossDefeatedAt=nil run.exfilStats=nil
    run.bossSpawned=false run.bossAlive=false run.special=false run.event=nil run.eventReadyAt=nil run.nextSpawn=os.clock()+1
    self.ctx.feed:FireAllClients("SpecialWave",{active=false})
    for _,window in ipairs(self.ctx.map.windows) do window.count=0 for _,b in ipairs(window.boards) do b.Transparency=1 end end
    ExtractionZone.begin(self.ctx.map)
    self:broadcast("EXTRACTION / Defeat the Warden, then bring the crew to the marked beacon and hold for 12 seconds.","amber")
end
function G:drop(position,forced)
    local pool={"Ammo","Double","Instant","Nuke","Repair","Sale"} local key=forced or pool[math.random(1,#pool)] local def=C.Powerups[key]
    local part=U.make("Part",self.ctx.map.model,{Name="Drop_"..key,Size=Vector3.new(1.8,1.8,1.8),Position=Vector3.new(position.X,math.max(2.2,position.Y-1),position.Z),Color=U.color(def.color),Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false})
    part:SetAttribute("Pickup",true)
    local gui=U.make("BillboardGui",part,{Size=UDim2.fromOffset(160,25),StudsOffset=Vector3.new(0,2,0),MaxDistance=65,AlwaysOnTop=false})
    U.make("TextLabel",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=def.name,TextColor3=U.color(def.color),Font=Enum.Font.GothamBold,TextSize=14})
    self.drops[#self.drops+1]={part=part,key=key,expires=os.clock()+25}
end
function G:powerup(key)
    local run=self.ctx.run local def=C.Powerups[key]
    if def.duration then run.effects[key]=os.clock()+def.duration
    elseif key=="Ammo" then
        for player,p in pairs(self.ctx.players) do if p.participating then
            for _,gun in ipairs(p.guns) do local stat=R.weaponStats(C.Weapons[gun.id],gun.tier,p.perks) gun.mag=stat.mag gun.reserve=stat.reserve gun.reloadUntil=0 end
            p.grenades=4 self.ctx.combat:ammo(player)
        end end
    elseif key=="Nuke" then
        for _,enemy in pairs(self.ctx.enemies.list) do self.ctx.enemies:damage(enemy,enemy.kind=="Warden" and enemy.maxHP*.3 or enemy.hp,nil,false) end
        for player,p in pairs(self.ctx.players) do if p.participating then self:addPoints(player,400,true) end end
    elseif key=="Repair" then
        for _,window in ipairs(self.ctx.map.windows) do window.count=5 for _,board in ipairs(window.boards) do board.Transparency=0 end end
        for player,p in pairs(self.ctx.players) do if p.participating then self:addPoints(player,200,true) end end
    end
    self:broadcast(def.name,"cyan") self.ctx.feed:FireAllClients("Cue",{name="Power"})
end
function G:award(player,win)
    local p=self.ctx.players[player] if not p or p.rewarded then return nil end p.rewarded=true
    return self.ctx.data:award(player,p.stats,self.ctx.run.mode,self.ctx.run.peak>1 and "Squad" or "Solo",win,self.ctx.run.signal)
end
function G:leave(player,disconnect)
    local p=self.ctx.players[player] if not p then return end
    if not disconnect and self.ctx.role=="Match" then
        if not p.travelling then task.spawn(function() self.ctx.travel:returnPlayers({player}) end) end return
    end
    if self.ctx.lobbyService and not p.travelling then self.ctx.lobbyService:leave(player,disconnect) end
    if disconnect and self.ctx.travel then self.ctx.travel:removed(player) end
    p.ready=false
    ThirdPerson.clear(player.Character) Downed.clear(p)
    if p.participating then self:award(player,false) p.participating=false p.status="Lobby" p.perks={} p.guns={}
        if p.revivePrompt then p.revivePrompt:Destroy() p.revivePrompt=nil end
        self.ctx.interact:cancel(player)
        if not disconnect then self:spawnCharacter(player,self.ctx.lobby.position) player:SetAttribute("DeadSignalStatus","Lobby") end
    end
    if disconnect then
        task.spawn(function() self.ctx.data:save(player,true) self.ctx.data.profiles[player]=nil end)
        self.ctx.players[player]=nil
    end
end
function G:finish(win,reason)
    local run=self.ctx.run if run.phase=="Results" or run.phase=="Lobby" then return end
    run.phase="Results" run.win=win run.deadline=os.clock()+C.ReturnCountdown run.spawnRemaining=0
    run.event=nil run.special=false
    self.ctx.feed:FireAllClients("SpecialWave",{active=false})
    self.ctx.enemies:clear(true) self.ctx.combat:clear()
    for _,d in ipairs(self.drops) do d.part:Destroy() end self.drops={}
    if win then Map.helicopter(self.ctx.map) end
    local crew={}
    for player,p in pairs(self.ctx.players) do if p.participating and not p.travelling then
        ThirdPerson.clear(player.Character) Downed.clear(p)
        local reward=self:award(player,win) p.status="Results" p.sprinting=false p.sprintRequested=false p.movementFeedback=nil
        if p.revivePrompt then p.revivePrompt:Destroy() p.revivePrompt=nil end
        local hum=U.humanoid(player) if hum then hum.WalkSpeed=0 hum.JumpPower=0 end
        table.insert(crew,{name=player.DisplayName,kills=p.stats.kills,headshots=p.stats.headshots,revives=p.stats.revives})
        self.ctx.feed:FireClient(player,"Results",{win=win,reason=reason,round=run.round,extraction=run.exfilStage and {stage=run.exfilStage,progress=run.exfilProgress,wardenDefeated=run.bossDefeatedAt~=nil} or nil,stats=U.copy(p.stats),reward=reward or {xp=0,credits=0,achievements={}}})
    end end
    self:broadcast(reason,win and "cyan" or "red") self.ctx.feed:FireAllClients("Cue",{name=win and "Victory" or "Down"})
end
function G:reset()
    if self.ctx.role=="Match" and not RunService:IsStudio() then
        local roster={} for player,p in pairs(self.ctx.players) do if not p.travelling then table.insert(roster,player) end end
        self.ctx.run.deadline=os.clock()+20
        task.spawn(function() self.ctx.travel:returnPlayers(roster) end) return
    end
    if self.ctx.map then self.ctx.map.model:Destroy() self.ctx.map=nil end self.box=nil
    self.ctx.interact:clearMap()
    for player,p in pairs(self.ctx.players) do if p.participating then
        p.participating=false p.status="Lobby" p.perks={} p.guns={} p.ready=false p.health=100
        player:SetAttribute("DeadSignalStatus","Lobby") self:spawnCharacter(player,self.ctx.lobby.position)
    end end
    local id=self.ctx.run.id self.ctx.run={id=id,phase="Lobby",round=0,mode="Standard",map="Station",effects={},peak=0,admitted={},deadline=0}
    if self.ctx.previewBay and self.ctx.lobbyService then self.ctx.lobbyService:returnPreview() end
end
function G:objective()
    local run=self.ctx.run
    if run.phase=="Exfil" then return run.exfilHint or "Eliminate the Warden, then rally at the rescue beacon." end
    if not run.power then return "Restore power in "..C.Maps[run.map].rooms[3] end
    if run.fuses<3 then return "Collect signal fuses: "..run.fuses.." / 3" end
    if not run.linked then return "Install fuses at the transmitter" end
    if not run.signal then return "Set frequency dials: "..table.concat(run.code," / ").." • Verify at transmitter" end
    if run.round<15 then return "Signal restored • Rescue available at round 15" end
    return "Vote at the courtyard radio to extract • or keep surviving"
end
function G:movementInput(player,args)
    local p=self.ctx.players[player]
    if not p or not p.participating or p.status~="Alive" or p.travelling or p.returningBusy then return false end
    local move=Movement.input(args.move)
    if not move then return false end
    p.moveIntent=move p.moveAt=os.clock()
    if type(args.blocked)=="boolean" then p.inputBlocked=args.blocked end
    return true
end
function G:movePlayer(player,p,hum,root,now,dt)
    local gun=self.ctx.combat:gun(p)
    local stale=not p.moveAt or now-p.moveAt>Movement.tuning.inputLifetime
    local options={alive=p.status=="Alive" and p.participating,blocked=p.inputBlocked or p.travelling or p.returningBusy or not self:isCombat(),
        aiming=p.aiming,reloading=gun and gun.reloadUntil>now,stamina=p.stamina,marathon=p.perks.Marathon,
        requested=p.sprintRequested,wasSprinting=p.sprinting,stale=stale}
    local facing=root.CFrame.LookVector
    local result=Movement.policy(p.moveIntent or Vector3.zero,facing,options)
    p.motion=p.motion or {position=p.lastPosition or root.Position,at=p.lastSample or now,debt=0,speed=0}
    if now>=(p.motion.pingAt or 0) then
        local ping=0
        if player.GetNetworkPing then local ok,value=pcall(function() return player:GetNetworkPing() end)
            if ok and R.finite(value) then ping=math.clamp(value,0,.3) end
        end
        p.motion.allowance=Movement.tuning.burstAllowance+Movement.tuning.marathonSprint*ping
        p.motion.pingAt=now+1
    end
    local actual=Movement.flat(root.Position-p.motion.position)
    -- Observe displacement rather than trusting a client's intended direction.
    if actual.Magnitude>.05 then
        local observed=Movement.policy(actual,facing,options)
        result.speed=math.min(result.speed,observed.speed)
        if not observed.sprinting then result.sprinting=false result.reason=observed.reason end
    end
    if not result.sprinting and (result.reason=="aiming" or result.reason=="reload" or result.reason=="blocked" or result.reason=="stamina") then p.sprintRequested=false end
    p.sprinting=result.sprinting
    p.stamina=Movement.stamina(p.stamina,R.stamina(p.perks),p.sprinting,dt)
    if p.stamina<=1 then p.sprinting=false p.sprintRequested=false result.reason="stamina"
        options.requested=false result.speed=math.min(result.speed,Movement.policy(p.moveIntent or Vector3.zero,facing,options).speed) end
    local previous=p.motion.speed or 0
    p.motion.speed=Movement.approach(previous,result.speed,dt) hum.WalkSpeed=p.motion.speed
    local ok,safe=Movement.audit(p.motion,root.Position,now,p.motion.speed)
    if not ok and safe then
        root.CFrame=CFrame.new(safe)*(root.CFrame-root.CFrame.Position) root.AssemblyLinearVelocity=Vector3.zero
        p.safePosition=p.motion.safePosition or safe
    else p.motion.safePosition=p.safePosition end
    p.movementFeedback={sprinting=p.sprinting,speed=p.motion.speed,reason=result.reason}
    p.lastPosition=root.Position p.lastSample=now
    ThirdPerson.update(player.Character,p.aiming,now-(p.lookAt or 0)<1 and p.lookPitch or 0,now-(p.lookAt or 0)<1 and p.lookYaw or 0,p.sprinting)
end
function G:tick(now,dt)
    local ctx=self.ctx local run=ctx.run
    if run.phase=="Arriving" then return end
    if ctx.role and (run.phase=="Lobby" or run.phase=="Countdown") then return end
    if run.phase=="Lobby" or run.phase=="Countdown" then
        local ready={} local votes={} local modes={}
        for player,p in pairs(ctx.players) do if p.ready then table.insert(ready,player) votes[p.vote]=(votes[p.vote] or 0)+1 modes[p.mode]=(modes[p.mode] or 0)+1 end end
        if #ready==0 then run.phase="Lobby"
        elseif run.phase=="Lobby" then run.phase="Countdown" run.deadline=now+C.Countdown
        elseif now>=run.deadline then
            local mapId,best="Station",-1 for _,id in ipairs(C.MapOrder) do if (votes[id] or 0)>best then mapId=id best=votes[id] or 0 end end
            local modeId=(modes.Lockdown or 0)>(modes.Standard or 0) and "Lockdown" or "Standard"
            self:start(mapId,modeId)
        end
        return
    end
    if run.phase=="Results" then if now>=run.deadline then self:reset() end return end
    for player,p in pairs(ctx.players) do if p.participating then
        local hum=U.humanoid(player) local root=U.root(player)
        if Bounds.enforce(ctx,player,p) and p.motion then
            -- Rescue rebases position without granting renewable speed credit.
            p.motion.position=root.Position p.motion.at=now p.motion.safePosition=p.safePosition
        end
        if p.status=="Down" then
            Downed.step(p,now)
            if p.selfAt and now>=p.selfAt then self:revive(player,nil) elseif now>=p.downUntil then self:eliminate(player) end
        elseif p.status=="Alive" and hum and root then
            if now-p.lastHurt>C.RegenDelay and p.health<R.health(p.perks) then p.health=math.min(R.health(p.perks),p.health+C.RegenRate*dt) hum.MaxHealth=R.health(p.perks) hum.Health=math.max(1,p.health) end
            self:movePlayer(player,p,hum,root,now,dt)
        end
    end end
    if self:aliveCount()==0 then
        local pending=false for _,p in pairs(ctx.players) do if p.participating and p.status=="Down" and p.selfAt then pending=true end end
        if not pending then self:finish(false,"THE CREW WENT SILENT") return end
    end
    if run.phase=="Preparing" or run.phase=="Intermission" then if now>=run.deadline then self:wave() end
    elseif run.phase=="Wave" then
        self:spawnEnemy(now)
        if run.spawnRemaining<=0 and ctx.enemies:count()==0 and ctx.enemies:pendingBlasts()==0 then
            for player,p in pairs(ctx.players) do if p.participating then p.stats.rounds=p.stats.rounds+1 self:addPoints(player,C.Economy.roundBase+run.round*C.Economy.roundGrowth,true) end end
            local specialPaid=self:rewardSpecial()
            ctx.enemies:clearHazards()
            run.event=nil self.ctx.feed:FireAllClients("SpecialWave",{active=false})
            run.phase="Intermission" run.deadline=now+C.Intermission
            if not specialPaid then self:broadcast("ROUND CLEARED / Resupply and open new routes.","amber") end
        end
    elseif run.phase=="Exfil" then
        if run.bossSpawned and not run.bossAlive then run.spawnRemaining=0 end
        self:spawnEnemy(now)
        local center=ctx.map.exfilCenter local stats={alive=0,insideAlive=0,downOutside=0,contested=false}
        for player,p in pairs(ctx.players) do local root=U.root(player) if p.participating and root then
            local inside=(Vector3.new(root.Position.X,0,root.Position.Z)-center).Magnitude<=C.Extraction.radius*ctx.map.scale and math.abs(root.Position.Y-center.Y)<9*ctx.map.scale
            if p.status=="Alive" then stats.alive=stats.alive+1 if inside then stats.insideAlive=stats.insideAlive+1 end
            elseif p.status=="Down" and not inside then stats.downOutside=stats.downOutside+1 end
        end end
        for _,e in pairs(ctx.enemies.list) do
            if (Vector3.new(e.root.Position.X,0,e.root.Position.Z)-center).Magnitude<C.Extraction.contestRadius*ctx.map.scale and math.abs(e.root.Position.Y-center.Y)<8*ctx.map.scale
                and ctx.enemies:clearSight(center+Vector3.new(0,3,0),e.root.Position) then stats.contested=true break end
        end
        local outcome,reason=Extraction.step(run,stats,C.Extraction,now,dt) ExtractionZone.update(ctx.map,run)
        if outcome~=nil then self:finish(outcome,reason) return end
    end
    for _,trap in ipairs(ctx.map.traps) do
        if now<trap.activeUntil then
            for _,e in pairs(ctx.enemies.list) do local d=e.root.Position-trap.center if math.abs(d.X)<9*ctx.map.scale and math.abs(d.Z)<2.5*ctx.map.scale then
                if e.kind~="Warden" and e.elite and now>=(e.trapStunAt or 0) then ctx.enemies:stun(e,C.Evolution.counters.trapStun) e.trapStunAt=now+3 end
                ctx.enemies:damage(e,e.kind=="Warden" and e.maxHP*.02*dt or 3000*dt,trap.owner,false,nil,"Trap")
            end end
            for player,p in pairs(ctx.players) do local root=U.root(player) if root and p.participating and p.status=="Alive" and not p.perks.Insulator then local d=root.Position-trap.center if math.abs(d.X)<9*ctx.map.scale and math.abs(d.Z)<2.5*ctx.map.scale then ctx.combat:hurt(player,35*dt,trap.center) end end end
        else trap.beam.Transparency=1 end
    end
    for i=#self.drops,1,-1 do local drop=self.drops[i] local collected=false
        for player,p in pairs(ctx.players) do local root=U.root(player) if root and p.participating and p.status=="Alive" and (root.Position-drop.part.Position).Magnitude<5 then self:powerup(drop.key) collected=true break end end
        if collected or now>drop.expires then drop.part:Destroy() table.remove(self.drops,i) end
    end
    local b=self.box
    if b and b.owner then
        if not b.owner.Parent or now>b.expires then self:clearBox()
        elseif now>=b.readyAt and not b.preview then
            b.preview=W.build(b.result,"Factory",0,b.model,false) b.preview:PivotTo(b.part.CFrame*CFrame.new(0,3,0)*CFrame.Angles(0,math.pi/2,0))
            b.prompt.ObjectText=C.Weapons[b.result].name.." / "..b.owner.DisplayName b.label.SurfaceGui.TextLabel.Text="TAKE: "..C.Weapons[b.result].name
        end
    end
end
function G:snapshot(player)
    local ctx=self.ctx local p=ctx.players[player] if not p then return end local run=ctx.run local now=os.clock() local team={} local queued=0 local boss
    for _,e in pairs(self.ctx.enemies.list) do if e.kind=="Warden" then boss={hp=e.hp,max=e.maxHP,phase=e.phase,overload=(e.overloadUntil or 0)>now} break end end
    for plr,state in pairs(self.ctx.players) do if state.ready then queued=queued+1 end if state.participating then table.insert(team,{id=plr.UserId,name=plr.DisplayName,status=state.status,health=state.health,points=state.points,kills=state.stats.kills}) end end
    self.ctx.feed:FireClient(player,"State",{runId=run.id,phase=run.phase,round=run.round,map=run.map,mode=run.mode,status=p.status,director=run.directorStage,activeCrew=run.activeCrew,
        participating=p.participating,ready=p.ready,queued=queued,team=team,accepted=p.ack or 0,points=p.points,health=math.floor(p.health),maxHealth=R.health(p.perks),
        stamina=p.stamina,maxStamina=R.stamina(p.perks),movement=p.movementFeedback,perks=U.copy(p.perks),guns=U.copy(p.guns),slot=p.slot,grenades=p.grenades,
        left=(run.spawnRemaining or 0)+self.ctx.enemies:count(),timer=math.max(0,math.ceil((run.deadline or 0)-now)),
        objective=self:isCombat() and self:objective() or "Walk into a solo or crew bay at Dispatch",
        effects=U.copy(run.effects),serverTime=now,downLeft=p.status=="Down" and math.max(0,math.ceil(p.downUntil-now)) or 0,
        autoRevive=p.selfAt~=nil,exfilProgress=run.exfilProgress or 0,
        extraction=run.phase=="Exfil" and {stage=run.exfilStage,title=Extraction.title(run.exfilStage),hint=run.exfilHint,progress=run.exfilProgress,
            inside=(run.exfilStats or {}).insideAlive or 0,alive=(run.exfilStats or {}).alive or 0,contested=(run.exfilStats or {}).contested==true,
            distance=U.root(player) and math.floor((Vector3.new(U.root(player).Position.X,0,U.root(player).Position.Z)-ctx.map.exfilCenter).Magnitude) or 0} or nil,
        signal=run.signal==true,power=run.power==true,boss=boss,
        special=run.event and {id=run.event.id,name=run.event.name,hint=run.event.hint,preparation=math.max(0,math.ceil((run.eventReadyAt or 0)-now))} or nil,
        role=ctx.role or "Preview",dispatch=ctx.lobbyService and ctx.lobbyService:state(player) or nil,travelling=p.travelling==true})
end
return G
