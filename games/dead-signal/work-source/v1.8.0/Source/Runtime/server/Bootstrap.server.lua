local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Physics=game:GetService("PhysicsService")
local C=require(RS:WaitForChild("DeadSignal"):WaitForChild("Config"))
local PC=require(RS.DeadSignal.PlaceConfig)
local U=require(RS.DeadSignal.Util)
if RS.DeadSignal:FindFirstChild("ServerRunning") then return end
U.make("BoolValue",RS.DeadSignal,{Name="ServerRunning",Value=true})
Players.CharacterAutoLoads=false
require(script.Parent.CollisionPolicy).setup(Physics)
local old=RS.DeadSignal:FindFirstChild("Remotes") if old then old:Destroy() end
local remotes=U.make("Folder",RS.DeadSignal,{Name="Remotes"})
local ctx={players={},role=PC.Role,action=U.make("RemoteEvent",remotes,{Name="Action"}),feed=U.make("RemoteEvent",remotes,{Name="Feed"})}
require(script.Parent.GraphicsService).load()
ctx.data=require(script.Parent.Persistence).new(ctx)
ctx.interact=require(script.Parent.Interactions).new(ctx)
ctx.enemies=require(script.Parent.Enemies).new(ctx)
ctx.combat=require(script.Parent.Combat).new(ctx)
ctx.game=require(script.Parent.Game).new(ctx)
ctx.director=require(script.Parent.WaveDirector).new(ctx)
ctx.travel=require(script.Parent.Travel).new(ctx)
if ctx.role=="Lobby" then ctx.lobbyService=require(script.Parent.LobbyService).new(ctx) end
ctx.network=require(script.Parent.Network).new(ctx)
require(script.Parent.Diagnostics).init(ctx)
Players.PlayerAdded:Connect(function(player) ctx.game:addPlayer(player) end)
Players.PlayerRemoving:Connect(function(player) ctx.game:leave(player,true) ctx.network.buckets[player]=nil end)
for _,player in ipairs(Players:GetPlayers()) do ctx.game:addPlayer(player) end
local accumulated,snapshots=0,0
RunService.Heartbeat:Connect(function(dt)
    accumulated=accumulated+dt snapshots=snapshots+dt
    if accumulated>=.15 then
        local elapsed=math.min(accumulated,.4) accumulated=0 local now=os.clock()
        ctx.interact:tick() ctx.game:tick(now,elapsed)
        ctx.travel:tick(now)
        if ctx.lobbyService then ctx.lobbyService:tick(now) end
        if ctx.game:isCombat() then ctx.combat:tick(now,elapsed) ctx.enemies:tick(now) end
    end
    if snapshots>=.35 then snapshots=0 for player in pairs(ctx.players) do if player.Parent then ctx.game:snapshot(player) end end end
end)
task.spawn(function()
    while task.wait(C.Autosave) do for player,p in pairs(ctx.data.profiles) do if p.loaded and p.safe then task.spawn(function() ctx.data:save(player,false) end) end end end
end)
task.spawn(function()
    while true do ctx.data:refreshBoards() task.wait(180) end
end)
game:BindToClose(function()
    local pending=0
    for player,p in pairs(ctx.players) do
        if p.participating then ctx.game:award(player,false) end
        pending=pending+1 task.spawn(function() ctx.data:save(player,true) pending=pending-1 end)
    end
    local deadline=os.clock()+25 while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
print("DEAD SIGNAL / "..C.Version.." / server ready")
