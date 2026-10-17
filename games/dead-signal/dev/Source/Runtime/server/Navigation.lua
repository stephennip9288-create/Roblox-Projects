-- Engine paths pursue the live player. Portals are recovery hints, never room centers.
local RS=game:GetService("ReplicatedStorage")
local Graph=require(RS.DeadSignal.NavigationGraph)
local PF=game:GetService("PathfindingService")
local U=require(RS.DeadSignal.Util)
local R=require(RS.DeadSignal.Rules)
local Rules=require(RS.DeadSignal.DirectorRules)
local T=Rules.tuning
local N={} local UP=Vector3.new(0,1,0)
N.traversalTuning={maxConcurrent=4,planInterval=.8,maxStep=1.1,stepSeconds=.08,blockedSeconds=.45,retrySeconds=1.2,timeout=7}
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
        local points={}
        -- Waypoint retrieval/normalization can fail as well as ComputeAsync.
        -- Reject empty and jumping paths without replacing a usable old route.
        if ok and path.Status==Enum.PathStatus.Success then ok=pcall(function()
            for _,point in ipairs(path:GetWaypoints()) do
                if point.Action==Enum.PathWaypointAction.Jump then error("Jumping route rejected") end
                local ground=owner.ctx.map and N.floor(owner.ctx.map,point.Position+UP*3)
                points[#points+1]={Position=ground or point.Position,Action=point.Action}
            end
        end) end
        if not ok or not path or path.Status~=Enum.PathStatus.Success or #points==0 then
            e.pathFailures=(e.pathFailures or 0)+1 e.nextPath=os.clock()+.65
            e.model:SetAttribute("NavigationState","Retrying") return
        end
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
function N.entryPoint(owner,e,window,accept)
    if not U.finiteVector(window.inside) or not U.finiteVector(window.outside) then return nil end
    local direction=flat(window.inside-window.outside);if direction.Magnitude<.05 then return nil end
    local into=direction.Unit local tangent=Vector3.new(into.Z,0,-into.X)
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
            for plr,state in pairs(owner.ctx.players or {}) do if state.participating and (state.status=="Alive" or state.status=="Down") then
                local root=U.root(plr)
                if root and flat(position-root.Position).Magnitude<N.agent(e).AgentRadius+1.2 and math.abs(position.Y-root.Position.Y)<4 then free=false break end
            end end
        end
        if free and (not accept or accept(position)) then return position end
    end return nil
end
local function entryIgnore(owner,e,window)
    local list={e.model}
    if owner.folder then list[#list+1]=owner.folder end
    if owner.corpses then list[#list+1]=owner.corpses end
    -- Only the designated NPC breach barrier is bypassed. Ordinary walls, doors,
    -- floors, player bounds policy and all other barriers retain collision rules.
    if window and window.part and window.part.CollisionGroup=="DeadSignalWindow" and (window.count<=0 or window.activeEntry==e.id) then list[#list+1]=window.part end
    return list
end
function N.traversalClear(owner,e,a,b,window,overlap)
    if not U.finiteVector(a) or not U.finiteVector(b) then return false end
    local agent=N.agent(e) local size=Vector3.new(agent.AgentRadius*2,agent.AgentHeight-.25,agent.AgentRadius*2)
    local offset=UP*(agent.AgentHeight*.5-N.rootHeight(e)+.16)
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=entryIgnore(owner,e,window);params.CollisionGroup="DeadSignalEnemies";params.RespectCanCollide=true
    local delta=b-a
    if delta.Magnitude>.005 and workspace:Blockcast(CFrame.new(a+offset),size,delta,params) then return false end
    if overlap then
        local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Exclude
        op.FilterDescendantsInstances=params.FilterDescendantsInstances;op.CollisionGroup=params.CollisionGroup;op.RespectCanCollide=true
        for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(b+offset),size,op)) do if part.CanCollide then return false end end
    end
    local function occupied(root,radius,height,bodyHeight)
        if not root then return false end
        local feet=b.Y-N.rootHeight(e) local otherFeet=root.Position.Y-height
        return flat(root.Position-b).Magnitude<agent.AgentRadius+radius+.2 and feet<otherFeet+bodyHeight and otherFeet<feet+agent.AgentHeight
    end
    for player,state in pairs(owner.ctx.players or {}) do
        if player.Parent and state.participating and not state.travelling and (state.status=="Alive" or state.status=="Down")
            and occupied(U.root(player),1.15,3,6) then return false end
    end
    for _,other in pairs(owner.list or {}) do if other~=e and not other.dead and other.root.Parent
        and occupied(other.root,N.agent(other).AgentRadius,N.rootHeight(other),N.agent(other).AgentHeight) then return false end end
    return true
end
function N.traversalSample(plan,elapsed)
    elapsed=math.clamp(elapsed,0,plan.duration)
    for index,stage in ipairs(plan.stages) do
        if elapsed<=stage.duration or index==#plan.stages then
            local u=math.clamp(elapsed/stage.duration,0,1) local t=u*u*(3-2*u)
            local pos=stage.control and stage.a*(1-t)^2+stage.control*(2*(1-t)*t)+stage.b*t^2 or stage.a:Lerp(stage.b,t)
            return pos,stage.name,u,index
        end
        elapsed-=stage.duration
    end
end
local function planPath(owner,e,landing,descriptor,window)
    if type(descriptor)~="table" then return nil end
    for _,key in ipairs({"approach","contact","landing"}) do if descriptor[key] and not U.finiteVector(descriptor[key]) then return nil end end
    for _,key in ipairs({"width","height","rise"}) do if descriptor[key] and not R.finite(descriptor[key]) then return nil end end
    if descriptor.kinds and type(descriptor.kinds)~="table" then return nil end
    if descriptor.door and type(descriptor.door)~="table" then return nil end
    local s=owner.ctx.map.scale or 1 local h=N.rootHeight(e) local kind=descriptor.kind or "Window"
    if not ({Window=true,Door=true,Tunnel=true,Vent=true,LowVault=true,Ledge=true})[kind] then return nil end
    if descriptor.kinds and descriptor.kinds[e.kind]~=true then return nil end
    if kind=="Vent" and e.kind~="Crawler" and e.kind~="Hound" then return nil end
    local agent=N.agent(e)
    if descriptor.width and agent.AgentRadius*2+.2>descriptor.width or descriptor.height and agent.AgentHeight+.2>descriptor.height then return nil end
    local outside=descriptor.approach and descriptor.approach+UP*h or window and window.outside or e.root.Position
    if not U.finiteVector(outside) or not U.finiteVector(landing) or flat(landing-outside).Magnitude<.5 or (landing-e.root.Position).Magnitude>36*s then return nil end
    local forward=flat(landing-outside).Unit
    local floorY=landing.Y-h
    local ground=N.floor(owner.ctx.map,outside)
    outside=Vector3.new(outside.X,(descriptor.authored and descriptor.approach.Y or ground and ground.Y or floorY)+h,outside.Z)
    local center=descriptor.contact or window and window.part and window.part.Position or (outside+landing)*.5
    if not U.finiteVector(center) then return nil end
    local breachY=center.Y
    center=Vector3.new(center.X,outside.Y-h,center.Z)
    local raise=descriptor.authored and math.max(0,breachY-center.Y+.35) or descriptor.rise or (kind=="Window" and 2.15*s or kind=="LowVault" and 1.5*s or 0)
    if not R.finite(raise) or raise<0 or raise>6*s then return nil end
    if kind=="Ledge" then raise=math.max(raise,landing.Y-outside.Y+.3*s) end
    if raise>6*s then return nil end
    -- Keep the complete swept agent outside the sill before lifting, and hold
    -- that height until the trailing edge has cleared it. Angled walls need
    -- the axis-aligned sweep's projected radius, including evolved agents.
    local projected=agent.AgentRadius*(math.abs(forward.X)+math.abs(forward.Z))
    local standOff=projected+.75*s+.3
    local before=center-forward*math.max(2.2*s,standOff)+UP*h
    local lifted=before+UP*raise
    local after=center+forward*math.max(3*s,standOff)+UP*(h+math.max(landing.Y-outside.Y+.15,raise))
    if kind=="Door" or kind=="Tunnel" or kind=="Vent" then before=outside;lifted=outside;after=landing end
    local fast=e.kind=="Hound" local crawl=e.kind=="Crawler" or kind=="Vent"
    local stages={}
    local function stage(name,a,b,seconds,control) stages[#stages+1]={name=name,a=a,b=b,duration=seconds,control=control} end
    stage("Approach",e.root.Position,before,math.clamp((before-e.root.Position).Magnitude/(fast and 10 or 7),.45,1.35))
    stage("Contact",before,lifted,fast and .18 or crawl and .36 or .30)
    local control=kind~="Door" and kind~="Tunnel" and kind~="Vent" and center+UP*(h+raise+.45*s) or nil
    stage("Cross",lifted,after,fast and .48 or crawl and .85 or .65,control)
    stage("Land",after,landing,fast and .24 or .38)
    stage("Settle",landing,landing,.18)
    local plan={stages=stages,duration=0,landing=landing,forward=forward,window=window,kind=kind,descriptor=descriptor,
        style=crawl and "Crawl" or fast and "Leap" or "Vault"}
    if kind=="Door" or kind=="Tunnel" then plan.style="Walk" end
    for _,v in ipairs(stages) do plan.duration+=v.duration end
    local previous=e.root.Position
    for index=0,16 do
        local at=N.traversalSample(plan,plan.duration*index/16)
        if not N.traversalClear(owner,e,previous,at,window,index==0 or index==16) then return nil end
        previous=at
    end
    return plan
end
function N.entryPlan(owner,e,window)
    if not window or window.count>0 or window.activeEntry and window.activeEntry~=e.id then return nil end
    local entry=Rules.windowEntry(window);if not entry then return nil end
    local descriptor={kind="Window"}
    local slots=window
    if not entry.legacy then
        local kinds
        if entry.allowedKinds then kinds={} for _,kind in ipairs(entry.allowedKinds) do kinds[kind]=true end end
        descriptor={kind=entry.kind,approach=entry.approach.Position,contact=entry.breach.Position,landing=entry.landing.Position,
            width=entry.clearance.radius*2,height=entry.clearance.height,kinds=kinds,authored=true}
        local floor=N.floor(owner.ctx.map,descriptor.landing+UP*1.5)
        -- An upper landing must never project onto a ground-floor recovery slot.
        if not floor or math.abs(floor.Y-descriptor.landing.Y)>.6 then return nil end
        slots=table.clone(window);slots.inside=descriptor.landing+UP*1.5;slots.outside=descriptor.approach+UP*1.5
    end
    local selected
    N.entryPoint(owner,e,slots,function(landing)
        if descriptor.authored and math.abs(landing.Y-N.rootHeight(e)-descriptor.landing.Y)>.6 then return false end
        local plan=planPath(owner,e,landing,descriptor,window)
        if plan then selected=plan;return true end return false
    end)
    return selected
end
function N.contextPlan(owner,e,target,now)
    if now<(e.nextTraversal or 0) then return nil end
    for _,link in ipairs(owner.ctx.map.traversals or {}) do
        local room=link.room and owner.ctx.map.rooms[link.room]
        local key=tostring(link.id)..":"..tostring(owner.ctx.map.navigationRevision or 0)
        if link.id and U.finiteVector(link.approach) and U.finiteVector(link.landing) and (not room or room.unlocked)
            and (not link.door or type(link.door)=="table" and link.door.open) and flat(e.root.Position-link.approach).Magnitude<3
            and (link.landing-target).Magnitude+2<(link.approach-target).Magnitude
            and ((e.traversalUses or {})[key] or 0)<2 then
            local ground=N.floor(owner.ctx.map,link.landing+UP*3)
            if ground then
                local plan=planPath(owner,e,ground+UP*N.rootHeight(e),link,nil)
                if plan then plan.key=key;return plan end
            end
        end
    end
    return nil
end
function N.move(owner,e,target,now)
    local goal=N.goal(owner.ctx,e,target,now) local revision=owner.ctx.map.navigationRevision or 0
    if e.navRevision~=revision then N.invalidate(e) e.navRevision=revision end
    local destination
    if N.clearRoute(owner.ctx,e,goal) then
        if e.path or e.computing then N.invalidate(e) end
        destination=goal e.model:SetAttribute("NavigationState","Direct")
    else
        if now>=(e.nextPath or 0) or (e.pathFailures or 0)==0 and e.pathGoal and flat(e.pathGoal-goal).Magnitude>6 then N.compute(owner,e,goal,now) end
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
