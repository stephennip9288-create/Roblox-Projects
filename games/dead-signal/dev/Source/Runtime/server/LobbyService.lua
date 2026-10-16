local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local C=require(RS.DeadSignal.Config)
local PC=require(RS.DeadSignal.PlaceConfig)
local D=require(RS.DeadSignal.DeploymentRules)
local U=require(RS.DeadSignal.Util)
local Movement=require(RS.DeadSignal.Movement)
local L={} L.__index=L
function L.new(ctx)
    local self=setmetatable({ctx=ctx,bays={},scanAt=0},L)
    for _,def in ipairs(D.Bays) do
        local b=U.copy(def) b.members={} b.state="Open" b.map="Station" b.mode="Standard" b.friendsOnly=false b.epoch=0
        self.bays[b.id]=b
        local geo=ctx.lobby.bays[b.id]
        ctx.interact:bind(geo.console,def.name,"Crew controls",0,function(player)
            local p=ctx.players[player]
            if p.bay==b.id then ctx.feed:FireClient(player,"OpenBay",{})
            else self:join(player,b.id) end
        end,{lobby=true,distance=12})
    end
    for _,item in ipairs({{ctx.lobby.armory,"ARMORY","Armory"},{ctx.lobby.record,"RECORDS","Records"},{ctx.lobby.manual,"FIELD MANUAL","Manual"}}) do
        ctx.interact:bind(item[1],item[2],"Open",0,function(player) ctx.feed:FireClient(player,"OpenTerminal",{tab=item[3]}) end,{lobby=true,distance=12})
    end
    return self
end
function L:count(b)
    local n=0 for _,id in ipairs(b.members) do
        local pl=Players:GetPlayerByUserId(id) local p=pl and self.ctx.players[pl]
        if p and p.bay==b.id and not p.travelling then n=n+1 end
    end return n
end
function L:seat(player,b)
    local p=self.ctx.players[player] local root=U.root(player) local hum=U.humanoid(player)
    if not p or not root then return end
    local index=1 for i,id in ipairs(b.members) do if id==player.UserId then index=i break end end
    local geo=self.ctx.lobby.bays[b.id]
    root.Anchored=true
    root.CFrame=CFrame.new(geo.spots[index])*CFrame.Angles(0,math.pi,0)
    if hum then hum.WalkSpeed=0 hum.JumpPower=0 end
end
function L:join(player,id,returning)
    local p=self.ctx.players[player] local b=self.bays[id] local profile=self.ctx.data.profiles[player]
    if not p or p.participating or p.travelling or p.bay or not b then return false end
    if not profile or not profile.loaded then return false end
    if not returning then
        if b.state~="Open" and b.state~="Forming" then return false end
        local root=U.root(player) local center=self.ctx.lobby.bays[id].entry
        if not root or (root.Position-center).Magnitude>18 then return false end
        if #b.members>=b.max then return false end
        if b.friendsOnly and b.leader~=player.UserId then
            local ok,friend=pcall(function() return player:IsFriendsWith(b.leader) end)
            if not ok or not friend then self.ctx.game:toast(player,"This bay is for the leader's friends.") return false end
        end
    elseif not D.has(b.members,player.UserId) then return false end
    if b.state=="Open" then b.epoch=b.epoch+1 b.leader=player.UserId b.state="Forming" end
    if not D.has(b.members,player.UserId) then table.insert(b.members,player.UserId) end
    p.bay=id p.ready=false p.status="Lobby" p.regroupTrip=returning and b.tripId or nil
    self:seat(player,b)
    if not returning then self.ctx.feed:FireClient(player,"OpenBay",{}) end
    return true
end
function L:clear(b)
    b.members={} b.leader=nil b.tripId=nil b.state="Open" b.deadline=nil b.error=nil b.reservedCode=nil b.pending=nil
    b.map="Station" b.mode="Standard" b.friendsOnly=false
end
function L:leave(player,disconnect)
    local p=self.ctx.players[player] local b=p and self.bays[p.bay]
    if not b then return end
    if p.travelling then return end
    p.bay=nil p.regroupTrip=nil p.boardAfter=os.clock()+2
    for i=#b.members,1,-1 do if b.members[i]==player.UserId then table.remove(b.members,i) end end
    if b.state=="Countdown" then b.state="Forming" b.deadline=nil end
    if b.leader==player.UserId then
        b.leader=nil for _,id in ipairs(b.members) do if Players:GetPlayerByUserId(id) then b.leader=id break end end
        b.leader=b.leader or b.members[1]
    end
    if #b.members==0 then self:clear(b) end
    local root=U.root(player) local hum=U.humanoid(player)
    if root then root.Anchored=false root.CFrame=CFrame.new(self.ctx.lobby.position) end
    if hum then hum.WalkSpeed=16 hum.JumpPower=0 Movement.noJump(hum) end
    if not disconnect then self.ctx.feed:FireClient(player,"CloseBay",{}) end
end
function L:configure(player,args)
    local p=self.ctx.players[player] local b=p and self.bays[p.bay]
    if not b or b.leader~=player.UserId or (b.state~="Forming" and b.state~="Held") then return end
    if C.Maps[args.map] then b.map=args.map end
    if C.Modes[args.mode] then b.mode=args.mode end
    if type(args.friendsOnly)=="boolean" then b.friendsOnly=args.friendsOnly end
end
function L:start(player)
    local p=self.ctx.players[player] local b=p and self.bays[p.bay]
    if not b then return end
    local ok,why=D.canStart(b,player.UserId,self:count(b))
    if not ok then self.ctx.game:toast(player,why) return end
    -- A partial return holds the original roster until everyone arrives or is released.
    if b.tripId and self:count(b)<#b.members then self.ctx.game:toast(player,"Waiting for the rest of the crew. Release missing seats to start a new trip.") return end
    if RunService:IsStudio() and PC.StudioPreview and self.ctx.game:isCombat() then
        self.ctx.game:toast(player,"Studio can preview one operation at a time. Live bays use separate servers.") return
    end
    b.state="Countdown" b.deadline=os.clock()+C.Countdown b.error=nil
end
function L:releaseMissing(player)
    local p=self.ctx.players[player] local b=p and self.bays[p.bay]
    if not b or b.leader~=player.UserId or b.state~="Held" then return end
    local present={} for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) local st=pl and self.ctx.players[pl] if st and st.bay==b.id then table.insert(present,id) end end
    b.members=present b.tripId=nil b.epoch=b.epoch+1 -- Old late returns cannot board this new crew.
end
function L:cancel(player)
    local p=self.ctx.players[player] local b=p and self.bays[p.bay]
    if b and b.leader==player.UserId and b.state=="Countdown" then b.state=b.tripId and "Held" or "Forming" b.deadline=nil end
end
function L:restore(player,ticket,id)
    local b=self.bays[ticket.bayId]
    if b and (b.state=="Away" or b.state=="Held") and b.tripId==id and b.epoch==ticket.epoch then
        b.state="Held" b.holdUntil=os.clock()+C.BayHoldSeconds
        if not Players:GetPlayerByUserId(b.leader) then b.leader=player.UserId end
        return self:join(player,b.id,true)
    end
    -- The original lobby may have gone away. Claim one entirely empty bay once.
    for _,candidate in ipairs(self.bays) do if candidate.state=="Held" and candidate.tripId==id then return self:join(player,candidate.id,true) end end
    for _,candidate in ipairs(self.bays) do if candidate.state=="Open" and candidate.max>=(#ticket.roster==1 and 1 or 4) then
        candidate.epoch=candidate.epoch+1 candidate.members=U.copy(ticket.roster) candidate.leader=player.UserId
        candidate.tripId=id candidate.state="Held" candidate.map=ticket.map candidate.mode=ticket.mode candidate.holdUntil=os.clock()+C.BayHoldSeconds
        return self:join(player,candidate.id,true)
    end end
    self.ctx.game:toast(player,"Dispatch bays are full. Your progress is saved; choose another bay when one opens.")
    return false
end
function L:preview(b)
    self.ctx.previewBay=b.id b.state="Away" b.holdUntil=os.clock()+C.BayHoldSeconds
    for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) if pl then self.ctx.players[pl].ready=true local root=U.root(pl) if root then root.Anchored=false end end end
    self.ctx.game:start(b.map,b.mode)
end
function L:returnPreview()
    local b=self.bays[self.ctx.previewBay] self.ctx.previewBay=nil
    if not b then return end
    if #b.members==0 then self:clear(b) return end
    b.state="Held" b.holdUntil=os.clock()+C.BayHoldSeconds
    for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) if pl then self.ctx.players[pl].bay=b.id self:seat(pl,b) end end
end
function L:state(player)
    local rows={} local p=self.ctx.players[player]
    for _,b in ipairs(self.bays) do
        local roster={} for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) table.insert(roster,{id=id,name=pl and pl.DisplayName or "Returning operator",present=pl~=nil}) end
        table.insert(rows,{id=b.id,name=b.name,min=b.min,max=b.max,state=b.state,map=b.map,mode=b.mode,leader=b.leader,
            friendsOnly=b.friendsOnly,members=roster,timer=math.max(0,math.ceil((b.deadline or 0)-os.clock())),error=b.error})
    end
    return {bays=rows,own=p and p.bay,preview=RunService:IsStudio() and PC.StudioPreview}
end
function L:tick(now)
    for _,b in ipairs(self.bays) do
        if b.state=="Countdown" and now>=b.deadline then
            b.state="Departing"
            if RunService:IsStudio() and PC.StudioPreview then self:preview(b)
            else task.spawn(function() self.ctx.travel:depart(b) end) end
        elseif (b.state=="Away" or b.state=="Held") and b.holdUntil and now>b.holdUntil then
            local occupied=false for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) if pl and self.ctx.players[pl] and self.ctx.players[pl].bay==b.id then occupied=true end end
            if not occupied then self:clear(b) end
        end
        local geo=self.ctx.lobby.bays[b.id]
        geo.label.SurfaceGui.TextLabel.Text=b.name.."  /  "..#b.members.." OF "..b.max.."\n"..(b.state=="Open" and "WALK IN TO BOARD" or b.state=="Countdown" and "DEPARTING IN "..math.max(0,math.ceil(b.deadline-now)) or b.state:upper()).."\n"..C.Maps[b.map].name
    end
    if now<self.scanAt then return end self.scanAt=now+.4
    for player,p in pairs(self.ctx.players) do
        if p.status=="Lobby" and not p.participating and not p.bay and not p.travelling and now>(p.boardAfter or 0) then
            local root=U.root(player)
            if root then for _,b in ipairs(self.bays) do
                local pos=self.ctx.lobby.bays[b.id].entry local delta=root.Position-pos
                if math.abs(delta.X)<10 and math.abs(delta.Z)<5 and math.abs(delta.Y)<8 then self:join(player,b.id) break end
            end end
        elseif p.bay and not p.participating and not p.travelling then self:seat(player,self.bays[p.bay]) end
    end
end
return L
