local DS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local P={} P.__index=P
local function day() return os.date("!%Y-%m-%d") end
local function defaults()
    return {schema=1,xp=0,credits=0,kills=0,headshots=0,revives=0,runs=0,extractions=0,
        best={StandardSolo=0,StandardSquad=0,LockdownSolo=0,LockdownSquad=0},
        skins={Factory=true},skin="Factory",achievements={},settings=U.copy(C.DefaultSettings),
        daily={date=day(),Kills=0,Rounds=0,Headshots=0,claimed={}}}
end
local function sanitize(value)
    local d=defaults() if type(value)~="table" then return d end
    for _,k in ipairs({"xp","credits","kills","headshots","revives","runs","extractions"}) do
        if R.finite(value[k]) then d[k]=R.clamp(math.floor(value[k]),0,1000000000) end
    end
    for k in pairs(d.best) do if type(value.best)=="table" and R.finite(value.best[k]) then d.best[k]=R.clamp(math.floor(value.best[k]),0,10000) end end
    if type(value.skins)=="table" then for _,s in ipairs(C.Skins) do if value.skins[s.id]==true then d.skins[s.id]=true end end end
    if type(value.skin)=="string" and d.skins[value.skin] then d.skin=value.skin end
    if type(value.achievements)=="table" then for k in pairs(C.Achievements) do if value.achievements[k]==true then d.achievements[k]=true end end end
    if type(value.settings)=="table" then for k,v in pairs(value.settings) do if R.validSetting(k,v) then d.settings[k]=v end end end
    if type(value.daily)=="table" and value.daily.date==day() then
        for _,g in ipairs(C.DailyGoals) do if R.finite(value.daily[g.id]) then d.daily[g.id]=math.max(0,math.floor(value.daily[g.id])) end end
        if type(value.daily.claimed)=="table" then for _,g in ipairs(C.DailyGoals) do d.daily.claimed[g.id]=value.daily.claimed[g.id]==true end end
    end
    return d
end
P.defaults=defaults P.sanitize=sanitize
function P.new(ctx)
    local self=setmetatable({ctx=ctx,profiles={},boards={},job=game.JobId~="" and game.JobId or Http:GenerateGUID(false)},P)
    -- Never touch DataStore APIs when using session-only Studio progress.
    -- GetDataStore itself can throw in an unpublished place, before load() runs.
    if RunService:IsStudio() and not C.StudioPersistence then
        self.sessionStatus="Studio session • cloud saving off"
    elseif game.PlaceId==0 or game.GameId==0 then
        self.sessionStatus="Unpublished place • session progress only"
    else
        local ok,store=pcall(function() return DS:GetDataStore(C.ProfileStore) end)
        if ok and store then self.store=store
        else self.sessionStatus="Cloud stats unavailable • this session will not overwrite your saved progress" end
    end
    return self
end
function P:load(player)
    local profile={data=defaults(),loaded=false,safe=false,busy=false}
    self.profiles[player]=profile
    if not self.store then
        profile.loaded=true profile.status=self.sessionStatus or "Session progress only • cloud saving unavailable"
    else
        local ok,result=pcall(function()
            return self.store:UpdateAsync(tostring(player.UserId),function(old)
                local lease=type(old)=="table" and old._lease or nil
                if type(lease)=="table" and lease.job~=self.job and type(lease.time)=="number" and os.time()-lease.time<C.LeaseSeconds then return nil end
                local d=sanitize(old) d._lease={job=self.job,time=os.time()} return d
            end)
        end)
        if ok and type(result)=="table" then
            profile.data=sanitize(result) profile.safe=true profile.acquired=true profile.status="Cloud stats ready"
        else profile.status="Cloud stats unavailable • this session will not overwrite your saved progress" end
        profile.loaded=true
    end
    if not player.Parent then self:save(player,true) self.profiles[player]=nil return end
    self:send(player)
end
function P:send(player)
    local p=self.profiles[player] if not p or not p.loaded then return end
    local d=U.copy(p.data)
    d.rank=R.rank(d.xp) d.status=p.status
    self.ctx.feed:FireClient(player,"Profile",d)
end
function P:save(player,release)
    local p=self.profiles[player] if not self.store or not p or not p.loaded or not p.safe then return false end
    local deadline=os.clock()+10
    while p.busy and os.clock()<deadline do task.wait(.1) end
    if p.busy then return false end
    p.busy=true
    local snapshot=U.copy(p.data)
    local ok,result=pcall(function()
        return self.store:UpdateAsync(tostring(player.UserId),function(old)
            if type(old)~="table" or type(old._lease)~="table" or old._lease.job~=self.job then return nil end
            if release then snapshot._lease=nil else snapshot._lease={job=self.job,time=os.time()} end
            return snapshot
        end)
    end)
    p.busy=false
    if ok and result then
        if release then p.safe=false p.released=true end
        p.status=release and "Saved" or "Cloud stats ready"
        return true
    end
    if ok then p.safe=false p.status="Profile opened elsewhere • saving paused"
    else p.status="Cloud save delayed • retrying automatically" end
    if player.Parent then self:send(player) end
    return false
end
function P:releaseForTravel(player)
    local p=self.profiles[player]
    if not p or not p.loaded then return false end
    if not self.store then return RunService:IsStudio() end
    if p.released then return true end
    if not p.safe and not p.acquired then
        -- Live operations require a loaded cloud profile. Retry a failed lobby
        -- load without replacing saved progress with session defaults.
        self:load(player) p=self.profiles[player]
        if not p or not p.safe then return false end
    end
    for _=1,3 do if self:save(player,true) then return true end task.wait(.5) end
    return false
end
function P:resume(player)
    local p=self.profiles[player]
    if not p or not self.store or not p.acquired then return false end
    if p.safe then return true end
    local ok,result=pcall(function()
        return self.store:UpdateAsync(tostring(player.UserId),function(old)
            if type(old)~="table" then return nil end
            local lease=old._lease
            if type(lease)=="table" and lease.job~=self.job and os.time()-lease.time<C.LeaseSeconds then return nil end
            old._lease={job=self.job,time=os.time()} return old
        end)
    end)
    if ok and result then
        p.data=sanitize(result) p.safe=true p.released=false p.status="Cloud stats ready" self:send(player) return true
    end
    p.status="Profile handoff delayed • departure paused" self:send(player) return false
end
function P:award(player,stats,modeId,category,win,signal)
    local profile=self.profiles[player] if not profile or not profile.loaded then return end
    local d=profile.data local mode=C.Modes[modeId]
    local xp,credits=R.runRewards(stats,mode,win)
    d.xp=d.xp+xp d.credits=d.credits+credits d.kills=d.kills+stats.kills d.headshots=d.headshots+stats.headshots
    d.revives=d.revives+stats.revives d.runs=d.runs+1 d.extractions=d.extractions+(win and 1 or 0)
    local key=modeId..category
    d.best[key]=math.max(d.best[key] or 0,stats.bestRound)
    local earned={}
    local function achieve(k,condition)
        if condition and not d.achievements[k] then d.achievements[k]=true d.credits=d.credits+C.Achievements[k].credits table.insert(earned,C.Achievements[k].name) end
    end
    achieve("FirstShift",stats.rounds>=5) achieve("LongNight",stats.rounds>=15)
    achieve("Deadeye",stats.headshots>=50) achieve("Guardian",stats.revives>=5)
    achieve("Technician",signal) achieve("Homebound",win) achieve("LoneWolf",category=="Solo" and stats.rounds>=10)
    if d.daily.date~=day() then d.daily=defaults().daily end
    d.daily.Kills=d.daily.Kills+stats.kills d.daily.Headshots=d.daily.Headshots+stats.headshots d.daily.Rounds=d.daily.Rounds+stats.rounds
    for _,g in ipairs(C.DailyGoals) do
        if d.daily[g.id]>=g.target and not d.daily.claimed[g.id] then d.daily.claimed[g.id]=true d.credits=d.credits+g.credits table.insert(earned,"Daily: "..g.name) end
    end
    if profile.safe then
        task.spawn(function()
            pcall(function()
                DS:GetOrderedDataStore(C.ProfileStore.."_Round_"..key):UpdateAsync(tostring(player.UserId),function(old) return math.max(tonumber(old) or 0,d.best[key]) end)
            end)
            self:save(player,false)
        end)
    end
    self:send(player)
    self.ctx.feed:FireClient(player,"Reward",{xp=xp,credits=credits,achievements=earned})
    return {xp=xp,credits=credits,achievements=earned}
end
function P:refreshBoards()
    if not self.store then return end
    local Players=game:GetService("Players")
    for _,mode in ipairs({"Standard","Lockdown"}) do for _,category in ipairs({"Solo","Squad"}) do
        local key=mode..category local rows={}
        local ok,page=pcall(function() return DS:GetOrderedDataStore(C.ProfileStore.."_Round_"..key):GetSortedAsync(false,10) end)
        if ok then
            for _,item in ipairs(page:GetCurrentPage()) do
                local userId=tonumber(item.key) local name="Operator "..item.key
                local named,value=pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
                if named then name=value end
                table.insert(rows,{name=name,round=item.value,userId=userId})
            end
            self.boards[key]=rows
        end
    end end
end
return P
