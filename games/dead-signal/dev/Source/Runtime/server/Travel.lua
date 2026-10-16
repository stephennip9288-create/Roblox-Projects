local Players=game:GetService("Players")
local Teleport=game:GetService("TeleportService")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local PC=require(RS.DeadSignal.PlaceConfig)
local D=require(RS.DeadSignal.DeploymentRules)
local U=require(RS.DeadSignal.Util)
local Registry=require(script.Parent.TripRegistry)
local T={} T.__index=T
function T.new(ctx)
    local self=setmetatable({ctx=ctx,registry=Registry.new(),pending={},batches={},accepted={},arrivals={},started=false},T)
    Teleport.TeleportInitFailed:Connect(function(player,result,_,placeId,options)
        local r=self.pending[player]
        if not r or r.placeId~=placeId then return end
        -- Ignore a stale event belonging to an earlier trip.
        local ok,data=pcall(function() return options:GetTeleportData() end)
        if ok and data and data.trip~=r.trip then return end
        if r.returning and result~=Enum.TeleportResult.Flooded and result~=Enum.TeleportResult.IsTeleporting and result~=Enum.TeleportResult.Unauthorized then
            self:publicDispatch(player,r)
        end
        if result==Enum.TeleportResult.Unauthorized then self:failed(player,r) return end
        self:retry(player,r,result==Enum.TeleportResult.Flooded and 15 or 2)
    end)
    return self
end
function T:notice(player,text)
    self.ctx.game:toast(player,text)
    self.ctx.feed:FireClient(player,"Travel",{active=false,message=text})
end
function T:options(id,code,job)
    local options=Instance.new("TeleportOptions")
    if code then options.ReservedServerAccessCode=code elseif job and job~="" then options.ServerInstanceId=job end
    options:SetTeleportData({protocol=2,trip=id}) return options
end
function T:publicDispatch(player,r)
    if not r or not r.returning or r.options.ServerInstanceId=="" or r.publicFallback then return false end
    r.options=self:options(r.trip) r.publicFallback=true r.attempts=0
    self.ctx.feed:FireClient(player,"Travel",{active=true,map="Lobby",message="Finding an available Dispatch server. Your progress is saved."})
    return true
end
function T:failed(player,r)
    if self.pending[player]~=r then return end self.pending[player]=nil
    local p=self.ctx.players[player] if not p then return end
    p.travelling=false
    self.ctx.data:resume(player)
    if r.returning then
        p.status=r.previousStatus or "Results"
        self:notice(player,"Return travel is delayed. Your progress is saved. Use Return to Dispatch to retry.")
    else
        local b=self.ctx.lobbyService.bays[p.bay]
        if b then b.state="Held" b.error="Travel delayed. Retry departure or leave this bay." b.holdUntil=os.clock()+C.BayHoldSeconds end
        self:notice(player,"Deployment could not finish. Your bay is held; retry or leave when ready.")
    end
end
function T:attempt(player,r)
    if not player.Parent or self.pending[player]~=r or r.inFlight then return end
    r.inFlight=true r.attempts=r.attempts+1 r.sentAt=os.clock()
    local ok=pcall(function() Teleport:TeleportAsync(r.placeId,{player},r.options) end)
    r.inFlight=false
    if not ok then self:publicDispatch(player,r) self:retry(player,r,2) end
end
function T:retry(player,r,delay)
    if self.pending[player]~=r or r.retryAt then return end
    if r.attempts>=C.TravelAttempts then
        -- Try one public dispatch when the old server is full, shut down or stale.
        if r.returning and r.options.ServerInstanceId~="" and not r.publicFallback then
            self:publicDispatch(player,r)
        else self:failed(player,r) return end
    end
    r.retryAt=os.clock()+delay
end
function T:begin(players,placeId,options,id,returning)
    local roster={} local token=Http:GenerateGUID(false)
    local batch={players=roster,placeId=placeId,options=options,token=token,expires=os.clock()+3}
    self.batches[token]=batch
    for _,player in ipairs(players) do if player.Parent then
        local p=self.ctx.players[player]
        if p then
            local code=options.ReservedServerAccessCode local job=options.ServerInstanceId
            local own=self:options(id,type(code)=="string" and code~="" and code or nil,job)
            local r={placeId=placeId,options=own,trip=id,returning=returning,attempts=0,sentAt=os.clock(),previousStatus=p.status,batch=batch,token=token}
            self.pending[player]=r p.travelling=true
            if returning then p.status="Returning" end
            local map=returning and "Lobby" or self.ctx.lobbyService.bays[p.bay].map
            self.ctx.feed:FireClient(player,"Travel",{active=true,map=map,token=token,message=returning and "Returning to Dispatch" or "Deploying to "..C.Maps[map].name})
            table.insert(roster,player)
        end
    end end
    if #roster==0 then self.batches[token]=nil end
end
function T:ready(player,token)
    local r=self.pending[player] if not r or r.token~=token or not r.batch then return end
    r.guiReady=true local batch=r.batch
    for _,pl in ipairs(batch.players) do local pending=self.pending[pl] if pl.Parent and pending and pending.batch==batch and not pending.guiReady then return end end
    self:launch(batch)
end
function T:launch(batch)
    if self.batches[batch.token]~=batch then return end self.batches[batch.token]=nil
    local roster={}
    for _,pl in ipairs(batch.players) do local r=self.pending[pl] if pl.Parent and r and r.batch==batch then
        r.batch=nil r.attempts=1 r.sentAt=os.clock() r.inFlight=true table.insert(roster,pl)
    end end
    if #roster==0 then return end
    local ok=pcall(function() Teleport:TeleportAsync(batch.placeId,roster,batch.options) end)
    for _,pl in ipairs(roster) do local r=self.pending[pl] if r then
        r.inFlight=false if not ok then self:publicDispatch(pl,r) self:retry(pl,r,2) end
    end end
end
function T:depart(b)
    local placeId=PC.MapPlaceIds[b.map]
    if type(placeId)~="number" or placeId<=0 or PC.LobbyPlaceId<=0 or placeId==PC.LobbyPlaceId then
        b.state="Forming" b.error="Map places need to be configured. See the setup guide."
        for _,id in ipairs(b.members) do local pl=Players:GetPlayerByUserId(id) if pl then self:notice(pl,b.error) end end return
    end
    local roster={} local released={}
    for _,id in ipairs(b.members) do
        local pl=Players:GetPlayerByUserId(id) local p=pl and self.ctx.players[pl]
        if not p or p.bay~=b.id or p.participating then b.state="Forming" b.error="Crew changed. Start again when ready." return end
        table.insert(roster,pl)
    end
    for _,pl in ipairs(roster) do self.ctx.players[pl].travelling=true end
    local function restore(reason)
        for _,pl in ipairs(released) do self.ctx.data:resume(pl) end
        for _,pl in ipairs(roster) do local p=self.ctx.players[pl] if p then p.travelling=false self:notice(pl,reason) end end
        b.state="Forming" b.error=reason
    end
    for _,pl in ipairs(roster) do
        if not self.ctx.data:releaseForTravel(pl) then restore("Your profile could not be saved. Departure paused; try again shortly.") return end
        table.insert(released,pl)
    end
    local ok,code=pcall(function() return Teleport:ReserveServerAsync(placeId) end)
    if not ok or type(code)~="string" then restore("Map server unavailable. Your crew is still together; try again.") return end
    for _,pl in ipairs(roster) do if not pl.Parent then restore("An operator disconnected. Reform the crew before departing.") return end end
    local id=Http:GenerateGUID(false) b.epoch=b.epoch+1
    local ticket={map=b.map,mode=b.mode,placeId=placeId,lobbyPlaceId=PC.LobbyPlaceId,lobbyJob=game.JobId,
        bayId=b.id,epoch=b.epoch,roster=U.copy(b.members),leader=b.leader,expires=os.time()+C.TripLeaseSeconds,returnAllowed={}}
    if not self.registry:write(id,ticket) then restore("Dispatch could not confirm the trip. Departure paused; try again shortly.") return end
    b.tripId=id b.reservedCode=code b.state="Away" b.holdUntil=os.clock()+C.BayHoldSeconds
    self:begin(roster,placeId,self:options(id,code),id,false)
end
function T:acceptMatch(player)
    local p=self.ctx.players[player] if not p then return end
    if RunService:IsStudio() and PC.StudioPreview then
        p.matchAllowed=true p.ready=true p.status="Arriving" self.arrivals[player.UserId]=true
        if not self.arrivalDeadline then self.arrivalDeadline=os.clock()+3 end return
    end
    local profile=self.ctx.data.profiles[player]
    if not profile or not profile.safe then
        p.status="Rejected" self:notice(player,"Your saved profile could not be loaded. Return to Dispatch and retry.") return
    end
    local ok,join=pcall(function() return player:GetJoinData() end)
    local data=ok and join.TeleportData local id=type(data)=="table" and data.protocol==2 and data.trip
    local ticket=id and self.registry:get(id)
    if not D.ticketValid(ticket,player.UserId,game.PlaceId,PC.Map,os.time()) or join.SourcePlaceId~=PC.LobbyPlaceId or (self.tripId and self.tripId~=id) then
        p.status="Rejected" self:notice(player,"No valid deployment was found. Return to Dispatch to form a crew.") return
    end
    local claimed=self.registry:update(id,function(t)
        if not D.ticketValid(t,player.UserId,game.PlaceId,PC.Map,os.time()) or (t.matchJob and t.matchJob~=game.JobId) then return nil end
        t.matchJob=game.JobId t.arrived=t.arrived or {} t.arrived[tostring(player.UserId)]=true return t
    end)
    if not claimed then p.status="Rejected" self:notice(player,"This trip belongs to a different server. Return to Dispatch to try again.") return end
    self.tripId=id self.ticket=claimed self.arrivals[player.UserId]=true
    self.arrivalDeadline=self.arrivalDeadline or os.clock()+C.ArrivalGrace
    p.matchAllowed=true p.ready=true p.status="Arriving"
    if self.ctx.game:isCombat() then p.status="Waiting" self.ctx.game:toast(player,"Crew confirmed. You will join at the next cleared round.") end
end
function T:acceptReturn(player)
    if RunService:IsStudio() then return end
    local ok,join=pcall(function() return player:GetJoinData() end)
    local data=ok and join.TeleportData local id=type(data)=="table" and data.protocol==2 and data.trip
    local ticket=id and self.registry:get(id)
    if not D.regroupValid(ticket,player.UserId,game.PlaceId,ok and join.SourcePlaceId or 0,os.time()) then return end
    local oldJob=ticket.regroupJob local oldLive=self.registry:liveLobby(PC.LobbyPlaceId,oldJob)
    local restored=self.registry:update(id,function(t)
        if not D.regroupValid(t,player.UserId,game.PlaceId,join.SourcePlaceId,os.time()) then return nil end
        if t.regroupJob and t.regroupJob~=game.JobId and (t.regroupJob~=oldJob or oldLive) then return nil end
        t.regroupJob=game.JobId t.returned=t.returned or {} t.returned[tostring(player.UserId)]=true return t
    end)
    if restored then self.ctx.lobbyService:restore(player,restored,id)
    else
        ticket=self.registry:get(id) or ticket
        if ticket.regroupJob and ticket.regroupJob~=game.JobId then
        -- Route a split fallback to the dispatch already claimed by its crew.
        if self.ctx.data:releaseForTravel(player) then self:begin({player},PC.LobbyPlaceId,self:options(id,nil,ticket.regroupJob),id,true) end
        end
    end
end
function T:returnPlayers(players)
    if RunService:IsStudio() then self.ctx.game:reset() return end
    if PC.LobbyPlaceId<=0 then for _,pl in ipairs(players) do self:notice(pl,"Dispatch place needs to be configured. See the setup guide.") end return end
    local roster={} local id=self.tripId
    for _,pl in ipairs(players) do
        local p=self.ctx.players[pl]
        if p and not p.travelling and not p.returningBusy then
            p.returningBusy=true
            if p.participating then self.ctx.game:award(pl,self.ctx.run.phase=="Results" and self.ctx.run.win==true) end
            if p.participating and self.ctx.run.phase~="Results" then
                p.participating=false p.ready=false p.status="Waiting" p.perks={} p.guns={}
                self.ctx.interact:cancel(pl) self.ctx.game:spawnCharacter(pl,self.ctx.holding.position)
            end
            if self.ctx.data:releaseForTravel(pl) then
                table.insert(roster,pl)
            else p.returningBusy=false self:notice(pl,"Your progress could not be saved. Return paused; try again shortly.") end
        end
    end
    if #roster==0 then return end
    if id then
        local updated=self.registry:update(id,function(t)
            if not t or t.matchJob~=game.JobId then return nil end
            t.returnAllowed=t.returnAllowed or {} for _,pl in ipairs(roster) do t.returnAllowed[tostring(pl.UserId)]=true end return t
        end)
        if not updated then
            for _,pl in ipairs(roster) do self.ctx.players[pl].returningBusy=false self.ctx.data:resume(pl) self:notice(pl,"Dispatch link is temporarily unavailable. Your progress is saved; retry return.") end return
        end
        self.ticket=updated
    end
    for _,pl in ipairs(roster) do self.ctx.players[pl].returningBusy=false end
    local job=self.ticket and (self.ticket.regroupJob or self.ticket.lobbyJob)
    if not self.registry:liveLobby(PC.LobbyPlaceId,job) then job="" end
    self:begin(roster,PC.LobbyPlaceId,self:options(id or "",nil,job),id or "",true)
end
function T:tick(now)
    for _,batch in pairs(self.batches) do if now>=batch.expires then task.spawn(function() self:launch(batch) end) end end
    if self.ctx.role=="Lobby" and not RunService:IsStudio() and now>(self.lobbyHeartbeatAt or 0) then
        self.lobbyHeartbeatAt=now+15
        self.registry:heartbeatLobby(game.PlaceId,game.JobId,#Players:GetPlayers())
    end
    for player,r in pairs(self.pending) do
        if not player.Parent then self.pending[player]=nil
        elseif not r.batch and r.retryAt and now>=r.retryAt then r.retryAt=nil task.spawn(function() self:attempt(player,r) end)
        elseif not r.batch and not r.inFlight and not r.retryAt and now-r.sentAt>20 then self:publicDispatch(player,r) self:retry(player,r,2) end
    end
    if self.tripId and self.ctx.role=="Match" and now>(self.refreshAt or 0) then
        self.refreshAt=now+60
        task.spawn(function()
            self.registry:update(self.tripId,function(t)
                if not t or t.matchJob~=game.JobId then return nil end t.expires=os.time()+C.TripLeaseSeconds return t
            end)
        end)
    end
    if self.ctx.role=="Match" and not self.started and self.arrivalDeadline then
        local count=0 for pl,p in pairs(self.ctx.players) do if p.matchAllowed and p.ready and pl.Parent then count=count+1 end end
        local expected=self.ticket and #self.ticket.roster or count
        if count>0 and (count>=expected or now>=self.arrivalDeadline) then
            self.started=true self.ctx.game:start(PC.Map,self.ticket and self.ticket.mode or "Standard")
        end
    end
end
function T:removed(player)
    self.pending[player]=nil
end
return T
