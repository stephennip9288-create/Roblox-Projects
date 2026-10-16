-- Deterministic per-contact gesture machine. No GUI callbacks or server remotes.
local T={} T.__index=T
local function distance(x,y) return math.sqrt(x*x+y*y) end
local function slopOrDefault(settings) return math.max(18,settings.tapSlop) end
function T.new(settings)
    return setmetatable({settings=settings,touches={},events={},moveX=0,moveY=0,
        fire=false,toggle=false,lookX=0,lookY=0,metrics={taps=0,swipes=0,holds=0,cancels=0,outerArms=0}},T)
end
function T:emit(kind,data) self.events[#self.events+1]={kind=kind,data=data} end
function T:drain() local out=self.events self.events={} return out end
function T:cancel(reason)
    self.touches={} self.moveOwner=nil self.lookOwner=nil self.fireOwner=nil
    self.moveX=0 self.moveY=0 self.fire=false self.toggle=false self.lookX=0 self.lookY=0
    self.events={} self.metrics.cancels=self.metrics.cancels+1 self.reason=reason
end
function T:cancelFire(reason)
    -- Reload/swap must stop shooting without making the movement thumb lift.
    self.toggle=false self.fire=false self.events={} self.reason=reason
    if self.fireOwner then self.touches[self.fireOwner]=nil self.fireOwner=nil end
    for _,t in pairs(self.touches) do
        if t.role=="move" then t.armed=false t.outerAt=nil t.fireLocked=true
        elseif t.role=="look" then t.held=false t.forbidFire=true t.swipe=true end
    end
end
function T:begin(id,x,y,now,role,radius,auto)
    if self.touches[id] or role=="reserved" then return end
    if role=="move" and self.moveOwner or role=="look" and self.lookOwner or role=="fire" and self.fireOwner then return end
    local t={x=x,y=y,sx=x,sy=y,px=x,py=y,at=now,role=role,radius=radius or 50,auto=auto,travel=0}
    self.touches[id]=t
    if role=="move" then self.moveOwner=id
    elseif role=="look" then self.lookOwner=id
    elseif role=="fire" then
        self.fireOwner=id
        if self.settings.fireLayout=="Left" and self.settings.leftGesture=="Toggle" then
            self.toggle=not self.toggle if self.toggle then self:emit("shot",{}) end
        else self:emit("shot",{}) end
    end
end
function T:move(id,x,y,now)
    local t=self.touches[id] if not t then return end
    local dx,dy=x-t.sx,y-t.sy
    t.travel=math.max(t.travel,distance(dx,dy)) t.x=x t.y=y
    local slop=self.settings.tapSlop
    if t.role=="move" then
        local length=distance(dx,dy) local r=t.radius
        local power=math.min(1,math.max(0,(length/r-.12)/.88))
        self.moveX=length>0 and dx/length*power or 0 self.moveY=length>0 and dy/length*power or 0
        if self.settings.fireLayout=="Left" and self.settings.leftGesture=="Outer" then
            if length<r*.95 then t.fireLocked=false end
            if not t.fireLocked and not t.armed and dy < -r*1.45 and math.abs(dx)<r*.85 then t.outerAt=t.outerAt or now else t.outerAt=nil end
            if t.armed and length<r*.45 then t.armed=false end
        end
    elseif t.role=="look" then
        if not t.held and not t.swipe and t.travel>slop then
            t.swipe=true self.metrics.swipes=self.metrics.swipes+1
            self.lookX=self.lookX+dx self.lookY=self.lookY+dy
        elseif t.swipe then self.lookX=self.lookX+x-t.px self.lookY=self.lookY+y-t.py end
    elseif t.role=="fire" and self.settings.fireLayout=="Classic" then
        self.lookX=self.lookX+x-t.px self.lookY=self.lookY+y-t.py
    end
    t.px=x t.py=y
end
function T:finish(id,x,y,now,cancelled)
    local t=self.touches[id] if not t then return end
    self:move(id,x,y,now)
    if not cancelled then
        if t.role=="look" and self.settings.fireLayout=="Tap" and not t.swipe and not t.held and not t.forbidFire
            and now-t.at<=self.settings.tapTime and t.travel<=self.settings.tapSlop then
            self.metrics.taps=self.metrics.taps+1 self:emit("shot",{x=x,y=y,screen=true})
        elseif t.role~="move" and t.role~="look" and t.role~="fire" and t.travel<slopOrDefault(self.settings) then
            self:emit("action",t.role)
        end
    end
    if self.moveOwner==id then self.moveOwner=nil self.moveX=0 self.moveY=0 end
    if self.lookOwner==id then self.lookOwner=nil end
    if self.fireOwner==id then self.fireOwner=nil end
    self.touches[id]=nil
end
function T:step(now,auto)
    local held=nil local moving=self.moveOwner and self.touches[self.moveOwner]
    if moving and moving.outerAt and now-moving.outerAt>=.22 then
        moving.armed=true moving.outerAt=nil self.metrics.outerArms=self.metrics.outerArms+1 self:emit("shot",{})
    end
    local pad=self.fireOwner and self.touches[self.fireOwner]
    if self.settings.leftGesture~="Toggle" or self.settings.fireLayout~="Left" then
        if pad then held={} end
    elseif self.toggle then held={} end
    if moving and moving.armed then held={} end
    local look=self.lookOwner and self.touches[self.lookOwner]
    if look and self.settings.fireLayout=="Tap" and self.settings.tapHold and auto
        and not look.swipe and not look.forbidFire and look.travel<=self.settings.tapSlop and now-look.at>=self.settings.tapHoldTime and not look.held then
        look.held=true self.metrics.holds=self.metrics.holds+1
    end
    if look and look.held then held={x=look.x,y=look.y,screen=true} end
    self.fire=held~=nil
    local result={x=self.moveX,y=self.moveY,lookX=self.lookX,lookY=self.lookY,held=auto and held or nil,
        sprint=moving~=nil and not self.fire and distance(self.moveX,self.moveY)>.94}
    self.lookX=0 self.lookY=0
    return result
end
return T
