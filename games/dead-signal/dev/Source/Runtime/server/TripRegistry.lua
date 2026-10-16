-- Trust server-side tickets, never currency or a roster supplied by the client.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local T={} T.__index=T
function T.new()
    local self=setmetatable({localTickets={}},T)
    if not RunService:IsStudio() and game.GameId~=0 then
        local ok,store=pcall(function() return game:GetService("MemoryStoreService"):GetHashMap(C.ProfileStore.."_Trips_v1") end)
        if ok then self.store=store end
    end
    return self
end
function T:get(id)
    if type(id)~="string" or #id>80 then return nil end
    if RunService:IsStudio() then return self.localTickets[id] and U.copy(self.localTickets[id]) or nil end
    if not self.store then return nil end
    local ok,value=pcall(function() return self.store:GetAsync(id) end)
    return ok and value or nil
end
function T:write(id,value)
    if RunService:IsStudio() then self.localTickets[id]=U.copy(value) return true end
    if not self.store then return false end
    return pcall(function() self.store:SetAsync(id,value,C.TripLeaseSeconds) end)
end
function T:update(id,fn)
    if RunService:IsStudio() then
        local value=fn(self.localTickets[id] and U.copy(self.localTickets[id]) or nil)
        if value then self.localTickets[id]=U.copy(value) end return value
    end
    if not self.store then return nil end
    local ok,value=pcall(function() return self.store:UpdateAsync(id,fn,C.TripLeaseSeconds) end)
    return ok and value or nil
end
function T:heartbeatLobby(placeId,jobId,count)
    if type(jobId)~="string" or jobId=="" then return false end
    local value={placeId=placeId,jobId=jobId,count=count,expires=os.time()+50}
    if RunService:IsStudio() then self.localTickets["lobby:"..jobId]=value return true end
    if not self.store then return false end
    return pcall(function() self.store:SetAsync("lobby:"..jobId,value,60) end)
end
function T:liveLobby(placeId,jobId)
    if type(jobId)~="string" or jobId=="" then return false end
    local v=self:get("lobby:"..jobId)
    return type(v)=="table" and v.placeId==placeId and type(v.expires)=="number" and v.expires>os.time() and (v.count or 0)>0
end
return T
