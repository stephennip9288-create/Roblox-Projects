-- Engine paths pursue the live player. Portals are recovery hints, never room centers.
local RS=game:GetService("ReplicatedStorage")
local Graph=require(RS.DeadSignal.NavigationGraph)
local PF=game:GetService("PathfindingService")
local T=require(RS.DeadSignal.DirectorRules).tuning
local N={} local UP=Vector3.new(0,1,0)
local function flat(v) return Vector3.new(v.X,0,v.Z) end
function N.rootHeight(e)
    local h=e.model:GetAttribute("NavigationRootHeight") if h then return h end
    local leg=e.model:FindFirstChild("Left Leg")
    return e.root.Size.Y*.5+(leg and leg.Size.Y or 0)+(e.hum.HipHeight or 0)
end
function N.agent(e)
    return {AgentRadius=e.model:GetAttribute("NavigationRadius") or (e.kind=="Warden" and 1.65 or 1.15),
        AgentHeight=e.model:GetAttribute("NavigationHeight") or (e.kind=="Warden" and 8.4 or e.kind=="Hound" and 3.5 or e.kind=="Crawler" and 2.5 or 5.9),
        AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=3,Costs={DeadSignalHazard=8}}
end
local function release(e)
    if e.blockedConnection then e.blockedConnection:Disconnect() e.blockedConnection=nil end
    e.pathObject=nil e.path=nil e.index=1
end
function N.invalidate(e,keepPending)
    if not keepPending then e.requestToken=(e.requestToken or 0)+1 e.computing=false end
    release(e) e.nextPath=0 e.pathGoal=nil
end
function N.floor(map,pos)
    local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances=map.floorParts or {}
    local hit=workspace:Raycast(pos+UP,Vector3.new(0,-40,0),p) return hit and hit.Position
end
function N.goal(ctx,e,target,_now)
    local ground=N.floor(ctx.map,target)
    local goal=ground and Vector3.new(target.X,ground.Y+N.rootHeight(e),target.Z) or target
    e.liveGoal=goal return goal
end
function N.clearRoute(ctx,e,target)
    local delta=target-e.root.Position
    if flat(delta).Magnitude>30 or math.abs(delta.Y)>1.3 then return false end
    if delta.Magnitude<.05 then return true end
    local a=N.agent(e) local p=RaycastParams.new()
    p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={ctx.map.model}
    p.CollisionGroup="DeadSignalEnemies" p.RespectCanCollide=true
    local center=e.root.Position+UP*(a.AgentHeight*.5-N.rootHeight(e)+.35)
    if workspace:Blockcast(CFrame.lookAt(center,center+flat(delta)),Vector3.new(a.AgentRadius*2,a.AgentHeight-.7,.6),flat(delta),p) then return false end
    local feet=e.root.Position.Y-N.rootHeight(e)
    for _,t in ipairs({.25,.5,.75,1}) do
        local ground=N.floor(ctx.map,e.root.Position+delta*t)
        if not ground or math.abs(ground.Y-feet)>1.2 then return false end
    end return true
end
function N.waypointReached(e,point,previous)
    local feet=e.root.Position-UP*N.rootHeight(e)
    if math.abs(feet.Y-point.Y)>2.25 then return false end
    local delta=flat(point-feet) if delta.Magnitude<1.65 then return true end
    if previous then
        local segment=flat(point-previous)
        if segment.Magnitude>.1 then
            local past=flat(feet-point):Dot(segment.Unit)
            local lateral=(flat(feet-point)-segment.Unit*past).Magnitude
            return past>=0 and past<4 and lateral<1.8
        end
    end return false
end
function N.compute(owner,e,goal,now)
    if e.computing or owner.pathBudget<=0 or (owner.activePaths or 0)>=T.maxConcurrentPaths then return end
    owner.pathBudget-=1 owner.activePaths=(owner.activePaths or 0)+1
    e.computing=true e.nextPath=now+.8+(e.id%7)*.025 e.requestToken=(e.requestToken or 0)+1
    local token=e.requestToken local run=owner.ctx.run.id local start=e.root.Position
    task.spawn(function()
        local path local ok=pcall(function() path=PF:CreatePath(N.agent(e)) path:ComputeAsync(start,goal) end)
        owner.activePaths=math.max(0,owner.activePaths-1)
        if e.dead or owner.ctx.run.id~=run or e.requestToken~=token then return end
        e.computing=false
        if not ok or path.Status~=Enum.PathStatus.Success then
            e.pathFailures=(e.pathFailures or 0)+1 e.nextPath=os.clock()+.65
            e.model:SetAttribute("NavigationState","Retrying") return
        end
        local raw=path:GetWaypoints() local points={}
        for _,point in ipairs(raw) do
            local ground=owner.ctx.map and N.floor(owner.ctx.map,point.Position+UP*3)
            points[#points+1]={Position=ground or point.Position,Action=point.Action}
        end
        for _,point in ipairs(points) do if point.Action==Enum.PathWaypointAction.Jump then e.nextPath=os.clock()+.7 return end end
        release(e) e.path=points e.index=1 e.pathGoal=goal e.pathObject=path e.pathFailures=0
        e.nextPath=os.clock()+1.05+(e.id%7)*.035 e.model:SetAttribute("NavigationState","Pursuing")
        if path.Blocked then e.blockedConnection=path.Blocked:Connect(function(index)
            if not e.dead and index>=e.index then N.invalidate(e) e.model:SetAttribute("NavigationState","Blocked") end
        end) end
    end)
end
function N.steer(owner,e,destination)
    local towards=flat(destination-e.root.Position) if towards.Magnitude<.25 then return destination end
    local push=Vector3.zero local gx,gz=math.floor(e.root.Position.X/8),math.floor(e.root.Position.Z/8)
    if owner.crowd then for x=gx-1,gx+1 do for z=gz-1,gz+1 do
        for _,other in ipairs(owner.crowd[x..":"..z] or {}) do if other~=e and not other.dead then
            local d=flat(e.root.Position-other.root.Position) local distance=d.Magnitude
            local spacing=N.agent(e).AgentRadius+N.agent(other).AgentRadius+.5
            if distance<spacing+1 and math.abs(e.root.Position.Y-other.root.Position.Y)<2 then
                local direction=distance>.05 and d.Unit or Vector3.new(e.id%2==0 and 1 or -1,0,0)
                push+=direction*math.clamp((spacing+.7-distance)/spacing,0,1)
            end
        end end
    end end end
    local lateral=push-towards.Unit*push:Dot(towards.Unit)
    if lateral.Magnitude>.01 then
        local adjusted=e.root.Position+towards.Unit*math.min(4,towards.Magnitude)+lateral.Unit*math.min(.85,lateral.Magnitude)
        if N.clearRoute(owner.ctx,e,adjusted) then return adjusted end
    end return destination
end
function N.entryPoint(owner,e,window)
    local into=flat(window.inside-window.outside).Unit local tangent=Vector3.new(into.Z,0,-into.X)
    local scale=owner.ctx.map.scale or 1
    for _,offset in ipairs({Vector3.zero,-into*3.3*scale,tangent*3.3*scale,-tangent*3.3*scale,into*3.3*scale}) do
        local position=window.inside+offset local ground=N.floor(owner.ctx.map,position)
        local free=ground~=nil
        if free then position=Vector3.new(position.X,ground.Y+N.rootHeight(e),position.Z) end
        for _,other in pairs(owner.list) do if free and other~=e and not other.dead and other.entered then
            local spacing=N.agent(e).AgentRadius+N.agent(other).AgentRadius+.45
            if flat(position-other.root.Position).Magnitude<spacing and math.abs(position.Y-other.root.Position.Y)<4 then free=false end
        end end
        if free then
            local U=require(RS.DeadSignal.Util)
            for plr,state in pairs(owner.ctx.players or {}) do if state.participating and state.status=="Alive" then
                local root=U.root(plr)
                if root and flat(position-root.Position).Magnitude<N.agent(e).AgentRadius+1.2 and math.abs(position.Y-root.Position.Y)<4 then free=false break end
            end end
        end
        if free then return position end
    end return nil
end
function N.move(owner,e,target,now)
    local goal=N.goal(owner.ctx,e,target,now) local revision=owner.ctx.map.navigationRevision or 0
    if e.navRevision~=revision then N.invalidate(e) e.navRevision=revision end
    local destination
    if N.clearRoute(owner.ctx,e,goal) then
        if e.path or e.computing then N.invalidate(e) end
        destination=goal e.model:SetAttribute("NavigationState","Direct")
    else
        if now>=(e.nextPath or 0) or e.pathGoal and flat(e.pathGoal-goal).Magnitude>6 then N.compute(owner,e,goal,now) end
        local point=e.path and e.path[e.index]
        while point and N.waypointReached(e,point.Position,e.index>1 and e.path[e.index-1].Position) do e.index+=1 point=e.path[e.index] end
        if point then destination=point.Position+UP*N.rootHeight(e)
        elseif (e.pathFailures or 0)>=2 then
            local route=Graph.route(owner.ctx.map,e.root.Position,target)
            for _,hint in ipairs(route or {}) do
                local ground=N.floor(owner.ctx.map,hint+UP*3) local p=ground and ground+UP*N.rootHeight(e) or hint
                if flat(p-e.root.Position).Magnitude>2 and N.clearRoute(owner.ctx,e,p) then destination=p break end
            end
        end
    end
    if destination then destination=N.steer(owner,e,destination) end
    e.movingTo=destination e.hum:MoveTo(destination or e.root.Position)
    if flat(e.root.Position-e.lastPosition).Magnitude>.45 then e.lastMoved=now e.lastPosition=e.root.Position
    elseif destination and now-e.lastMoved>1.65 and now>(e.replanAt or 0) then
        e.replanAt=now+.8 e.replans=(e.replans or 0)+1 N.invalidate(e) e.model:SetAttribute("NavigationState","Recovering")
    end
end
return N
