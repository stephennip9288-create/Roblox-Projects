local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local ControlSettings=require(RS.DeadSignal.ControlSettings)
local N={} N.__index=N
local limits={Fire={28,36},Ready={1,3},Queue={2,4},Reload={3,5},Swap={4,6},Aim={8,10},Sprint={8,10},Melee={3,4},Grenade={3,4},Leave={1,2},Setting={4,8},BuySkin={1,2},EquipSkin={2,4},Boards={.1,2},BaySetting={2,4},BayStart={1,2},BayLeave={1,2},BayRelease={1,2},BayCancel={1,2}}
function N.new(ctx)
    limits.ControlSettings={1,3}
    limits.Look={12,16}
    limits.TravelReady={2,4}
    local self=setmetatable({ctx=ctx,buckets={}},N)
    ctx.action.OnServerEvent:Connect(function(player,op,args)
        if type(op)~="string" or not limits[op] or not self:allow(player,op,os.clock()) then return end
        if args~=nil and type(args)~="table" then return end
        if args then local n=0 for k in pairs(args) do n=n+1 if n>8 or type(k)~="string" or #k>32 then return end end end
        self:dispatch(player,op,args or {})
    end)
    return self
end
function N:allow(player,op,now)
    local limit=limits[op] if not limit then return false end
    local buckets=self.buckets[player] if not buckets then buckets={} self.buckets[player]=buckets end
    local b=buckets[op] or {tokens=limit[2],time=now}
    b.tokens=math.min(limit[2],b.tokens+math.max(0,now-b.time)*limit[1]) b.time=now buckets[op]=b
    if b.tokens<1 then return false end b.tokens=b.tokens-1 return true
end
function N:dispatch(player,op,a)
    local ctx=self.ctx local p=ctx.players[player] if not p then return end
    if (p.travelling or p.returningBusy) and op~="Ready" and op~="Boards" and op~="TravelReady" then return end
    if op=="TravelReady" then if ctx.travel and type(a.token)=="string" then ctx.travel:ready(player,a.token) end return end
    if op=="BaySetting" and ctx.lobbyService then ctx.lobbyService:configure(player,a) return
    elseif op=="BayStart" and ctx.lobbyService then ctx.lobbyService:start(player) return
    elseif op=="BayLeave" and ctx.lobbyService then ctx.lobbyService:leave(player,false) return
    elseif op=="BayRelease" and ctx.lobbyService then ctx.lobbyService:releaseMissing(player) return
    elseif op=="BayCancel" and ctx.lobbyService then ctx.lobbyService:cancel(player) return end
    if op=="Ready" then ctx.data:send(player) ctx.game:snapshot(player)
    elseif op=="Queue" then ctx.game:queue(player,a.ready,a.map,a.mode)
    elseif op=="Fire" then ctx.combat:fire(player,a)
    elseif op=="Reload" then ctx.combat:reload(player)
    elseif op=="Swap" then ctx.combat:swap(player,a.slot)
    elseif op=="Aim" then if p.status=="Alive" and p.participating and type(a.enabled)=="boolean" then p.aiming=a.enabled if p.aiming then p.sprinting=false end end
    elseif op=="Look" then if p.status=="Alive" and p.participating and R.finite(a.pitch) and R.finite(a.yaw) then
        p.lookPitch=R.clamp(a.pitch,-.9,.9) p.lookYaw=R.clamp(a.yaw,-1.05,1.05) p.lookAt=os.clock()
        if ctx.game.movementInput then ctx.game:movementInput(player,a) end
    end
    elseif op=="Sprint" then if p.status=="Alive" and p.participating and type(a.enabled)=="boolean" then
        if ctx.game.movementInput then ctx.game:movementInput(player,a) end
        p.sprintRequested=a.enabled
        if not a.enabled then p.sprinting=false end
    end
    elseif op=="Melee" then ctx.combat:melee(player)
    elseif op=="Grenade" then ctx.combat:grenade(player,a)
    elseif op=="Leave" then ctx.game:leave(player,false)
    elseif op=="Boards" then ctx.feed:FireClient(player,"Boards",ctx.data.boards)
    elseif op=="Setting" then
        local profile=ctx.data.profiles[player]
        if profile and profile.loaded and R.validSetting(a.key,a.value) then profile.data.settings[a.key]=a.value ctx.data:send(player) end
    elseif op=="ControlSettings" then
        local profile=ctx.data.profiles[player]
        if not profile or not profile.loaded or type(a.settings)~="table" then return end
        local n=0
        for key,value in pairs(a.settings) do n=n+1 if n>60 or not ControlSettings.valid(key,value) then return end end
        for key,value in pairs(a.settings) do profile.data.settings[key]=value end
        ctx.data:send(player)
    elseif op=="BuySkin" or op=="EquipSkin" then
        local profile=ctx.data.profiles[player]
        if not profile or not profile.loaded or p.participating or type(a.id)~="string" then return end
        for _,skin in ipairs(C.Skins) do if skin.id==a.id then
            if op=="BuySkin" and not profile.data.skins[a.id] then
                if profile.data.credits<skin.cost then ctx.game:toast(player,"Not enough field credits.") return end
                profile.data.credits=profile.data.credits-skin.cost profile.data.skins[a.id]=true
            end
            if profile.data.skins[a.id] then profile.data.skin=a.id ctx.data:send(player) ctx.game:toast(player,skin.name.." equipped.","cyan") end
            return
        end end
    end
end
return N
