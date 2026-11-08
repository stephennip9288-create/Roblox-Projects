-- Room/portal intent plus physically checked native pursuit; accepted entry paths stay separate.
local RS=game:GetService("ReplicatedStorage")
local Graph=require(RS.DeadSignal.NavigationGraph)
local PF=game:GetService("PathfindingService")
local U=require(RS.DeadSignal.Util)
local R=require(RS.DeadSignal.Rules)
local Rules=require(RS.DeadSignal.DirectorRules)
local Pose=require(RS.DeadSignal.NPCPose)
local T=Rules.tuning
local N={} local UP=Vector3.new(0,1,0)
N.traversalTuning={maxConcurrent=4,planInterval=.8,maxStep=1.1,stepSeconds=.08,blockedSeconds=.45,retrySeconds=1.2,timeout=7,failedEntrySeconds=30,queueLevelTolerance=.25}
N.pursuitTuning={retryMax=4,stuckSeconds=2,reacquireSeconds=6,avoidSeconds=6,maxWaypoints=128,roomPlansPerTick=4}
local floorInventories=setmetatable({},{__mode="k"})
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
function N.invalidate(e,keepPending,keepIntent)
    if not keepPending then e.requestToken=(e.requestToken or 0)+1 e.computing=false end
    release(e) e.nextPath=0 e.pathGoal=nil
    if not keepIntent then e.roomRoute=nil end
end
function N.floor(map,pos)
    local source=map.floorParts or {};local exterior=map.model and map.model:FindFirstChild("ExteriorGround")
    local inventory=floorInventories[map]
    if not inventory or inventory.source~=source or inventory.count~=#source or inventory.exterior~=exterior or inventory.revision~=map.navigationRevision then
        local floors=table.clone(source);if exterior then floors[#floors+1]=exterior end
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances=floors;params.RespectCanCollide=true
        local ids={};for i,part in ipairs(floors) do ids[part]=i end
        inventory={source=source,count=#source,exterior=exterior,revision=map.navigationRevision,params=params,ids=ids,supportFilters={},filterOrder={}};floorInventories[map]=inventory
    end
    local hit=workspace:Raycast(pos+UP,Vector3.new(0,-40,0),inventory.params) return hit and hit.Position,hit and hit.Instance
end
local function supportFilter(map,support)
    local inventory=floorInventories[map];local ids={}
    for part in pairs(support) do if inventory.ids[part] then ids[#ids+1]=inventory.ids[part] end end
    table.sort(ids);local key=table.concat(ids,",");local cached=inventory.supportFilters[key]
    if cached then return cached end
    -- Partition the map hierarchy around only the sampled supporting parts.
    -- Walls, unrelated decks/ceilings, props and closed gates remain included.
    local include={}
    local function visit(instance)
        if support[instance] then return end
        local split=false
        for floor in pairs(support) do if floor:IsDescendantOf(instance) then split=true;break end end
        if split then for _,child in ipairs(instance:GetChildren()) do visit(child) end else include[#include+1]=instance end
    end
    visit(map.model)
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=include
    params.CollisionGroup="DeadSignalEnemies";params.RespectCanCollide=true
    if #inventory.filterOrder>=64 then inventory.supportFilters[table.remove(inventory.filterOrder,1)]=nil end
    inventory.filterOrder[#inventory.filterOrder+1]=key;inventory.supportFilters[key]=params
    return params
end
-- Complete retained rig bounds, sampled once per stage. Mesh bounds are
-- conservative; they include art, gear, hit zones and the live body collider.
function N.rigBounds(e,style,stage)
    e.entryBounds=e.entryBounds or {} local key=(style or "Rest")..":"..(stage or "Rest")
    if e.entryBounds[key] then return e.entryBounds[key] end
    local root=e.root
    if not e.entryGeometry then
        local rest=Pose.frames(e.model,{}) local groups={}
        for _,p in ipairs(e.model:GetDescendants()) do
            if p:IsA("BasePart") and p~=root and (p.Transparency<.95 or p.CanQuery or p:GetAttribute("AliveCollider")) then
                local weld=p:FindFirstChildOfClass("WeldConstraint")
                local bone=weld and weld.Part0 or p
                local bind=weld and weld.Part0 and weld.Part0.CFrame:ToObjectSpace(p.CFrame) or CFrame.identity
                if not rest[bone] then bone=root;bind=root.CFrame:ToObjectSpace(p.CFrame) end
                local group=groups[bone]
                if not group then group={low=Vector3.new(math.huge,math.huge,math.huge)};group.high=-group.low;groups[bone]=group end
                for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
                    local v=bind:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)
                    group.low=Vector3.new(math.min(group.low.X,v.X),math.min(group.low.Y,v.Y),math.min(group.low.Z,v.Z))
                    group.high=Vector3.new(math.max(group.high.X,v.X),math.max(group.high.Y,v.Y),math.max(group.high.Z,v.Z))
                end end end
            end
        end
        e.entryGeometry=groups
    end
    local low=Vector3.new(math.huge,math.huge,math.huge) local high=-low
    for sample=0,8 do
        local u=sample/8 local poses={}
        if stage then
            local r6=e.model:GetAttribute("PresentationRig")=="R6"
            poses=Pose.transforms(e.kind,u*math.pi*2,stage=="Approach" and 8 or 0,0,e.model:GetAttribute("PoseSeed"),r6)
            for name,pose in pairs(Pose.traversal(e.kind,style,stage,u,r6)) do poses[name]=pose end
        end
        local frames=Pose.frames(e.model,poses)
        for bone,group in pairs(e.entryGeometry) do
            local cf=frames[bone] or CFrame.identity
            for _,x in ipairs({group.low.X,group.high.X}) do for _,y in ipairs({group.low.Y,group.high.Y}) do for _,z in ipairs({group.low.Z,group.high.Z}) do
                local v=cf:PointToWorldSpace(Vector3.new(x,y,z))
                low=Vector3.new(math.min(low.X,v.X),math.min(low.Y,v.Y),math.min(low.Z,v.Z))
                high=Vector3.new(math.max(high.X,v.X),math.max(high.Y,v.Y),math.max(high.Z,v.Z))
            end end end
        end
    end
    local bounds={low=low,high=high};e.entryBounds[key]=bounds return bounds
end
function N.supported(owner,e,position,forward)
    local cf=CFrame.lookAt(position,position+forward) local feetY=position.Y-N.rootHeight(e)
    local names={"Left Foot","Right Foot"}
    if e.kind=="Hound" or e.kind=="Crawler" then names[#names+1]="Left Hand";names[#names+1]="Right Hand" end
    if not e.entrySupport then
        e.entrySupport={} local frames=Pose.frames(e.model,{})
        for _,name in ipairs(names) do local foot=e.model:FindFirstChild(name)
            if foot then e.entrySupport[name]={frame=frames[foot] or e.root.CFrame:ToObjectSpace(foot.CFrame),size=foot.Size} end
        end
    end
    local tested=0
    for _,name in ipairs(names) do local foot=e.entrySupport[name]
        if foot then
            tested+=1 local bind=foot.frame
            for _,offset in ipairs({Vector3.zero,Vector3.new(-foot.size.X*.4,0,-foot.size.Z*.4),Vector3.new(foot.size.X*.4,0,foot.size.Z*.4)}) do
                local p=cf:PointToWorldSpace(bind.Position+offset)
                local floor=N.floor(owner.ctx.map,Vector3.new(p.X,feetY+1.5,p.Z))
                if not floor or math.abs(floor.Y-feetY)>.6 then return false end
            end
        end
    end
    return tested>0
end
function N.queueHead(owner,e,window)
    if window.activeEntry then
        local active=owner.list[window.activeEntry]
        if not active or active.dead or not active.traversal or active.traversal.plan.window~=window then window.activeEntry=nil
        else return window.activeEntry==e.id end
    end
    local descriptor=N.entryDescriptor(owner.ctx.map,window)
    if not descriptor then return false end
    local approach=descriptor.approach or window.outside local best,score
    local into=flat(window.inside-window.outside).Unit
    local tangent=Vector3.new(into.Z,0,-into.X)
    for _,other in pairs(owner.list) do
        if not other.dead and not other.entered and not other.entryRerouting and other.window==window then
            -- Drain the front row before letting a nearer diagonal from the
            -- next row cut across its waiting bodies.
            local delta=flat(other.root.Position-approach)
            local distance=math.max(0,-delta:Dot(into))*1024+math.abs(delta:Dot(tangent))
            if not score or distance<score-.05 or math.abs(distance-score)<=.05 and other.id<best.id then best=other;score=distance end
        end
    end
    return best==e
end
function N.expireEntryFailures(e,now)
    for window,untilAt in pairs(e.failedEntryUntil or {}) do if now>=untilAt then
        if e.failedEntries then e.failedEntries[window]=nil end
        e.failedEntryUntil[window]=nil
        if e.window==window then e.entryFailure=nil;e.entryFailures=0 end
    end end
end
function N.goal(ctx,e,target,_now)
    local ground=N.floor(ctx.map,target)
    local goal=ground and Vector3.new(target.X,ground.Y+N.rootHeight(e),target.Z) or target
    e.liveGoal=goal return goal
end
function N.accessSegment(map,e,target)
    if e.entered==false or not map.navigation or not Graph.plan then return true end
    local a=e.root.Position;local delta=target-a
    local locked=false;for _,room in ipairs(map.rooms) do if not room.unlocked then locked=true;break end end
    if locked then for _,t in ipairs({0,.25,.5,.75,1}) do
        local room=Graph.locate(map,a+delta*t-UP*N.rootHeight(e))
        if map.rooms[room] and not map.rooms[room].unlocked then e.navFailure="LockedRoom";return false end
    end end
    for index,door in ipairs(map.doors or {}) do if not door.open then
        local points=door.waypoints or {};local normal=door.part and flat(door.part.CFrame.LookVector)
            or points[2] and points[3] and flat(points[3]-points[2])
        if normal and normal.Magnitude>.01 then
            normal=normal.Unit;local center=door.position
            local da=flat(a-center):Dot(normal);local db=flat(target-center):Dot(normal)
            if da*db<=0 and math.abs(da-db)>.001 then
                local t=math.clamp(da/(da-db),0,1);local at=a+delta*t
                local tangent=Vector3.new(normal.Z,0,-normal.X)
                local width=door.part and door.part.Size.X*.5 or 7*(map.scale or 1)
                if math.abs(flat(at-center):Dot(tangent))<=width+N.agent(e).AgentRadius then
                    e.navFailure="ClosedDoor";e.blockedDoor=index;return false
                end
            end
        end
    end end
    return true
end
function N.clearRoute(ctx,e,target)
    local delta=target-e.root.Position
    local distance=flat(delta).Magnitude
    if distance>30 or math.abs(delta.Y)>math.max(1.3,distance*.65) then return false end
    if delta.Magnitude<.05 then return true end
    if not N.accessSegment(ctx.map,e,target) then return false end
    local a=N.agent(e) local p=RaycastParams.new()
    p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={ctx.map.model}
    p.CollisionGroup="DeadSignalEnemies" p.RespectCanCollide=true
    local low=-N.rootHeight(e)+.35;local high=a.AgentHeight-N.rootHeight(e)-.35
    local width,depth=a.AgentRadius*2,.6
    if e.model:FindFirstChild("HumanoidRootPart") then
        local b=N.rigBounds(e,"Walk","Approach");width=math.max(width,b.high.X-b.low.X)
        -- Long noncolliding hands, canine muzzles and tails must not become
        -- invisible walls against the slope behind/below a walking actor.
        -- Keep the retained radius and root-bound physical collider for depth;
        -- retain lateral silhouette/head clearance and the stricter full-rig
        -- traversal sweeps for accepted window animations.
        local collider=e.model:FindFirstChild("BodyCollider")
        depth=math.max(a.AgentRadius*2,collider and collider.Size.Z or 0)
        high=math.max(high,b.high.Y)
        -- Walkable slope contact needs step skin at the leading sole. Upper
        -- body, head and full lateral/longitudinal art envelope are still swept.
        low=-N.rootHeight(e)+math.min(1.2,.35+math.abs(delta.Y)/math.max(.1,distance)*depth*.5)
    end
    local direction=distance>.01 and flat(delta).Unit or (e.root.CFrame and e.root.CFrame.LookVector or Vector3.new(0,0,-1))
    local center=e.root.Position+UP*(low+high)*.5
    local size=Vector3.new(math.abs(direction.Z)*width+math.abs(direction.X)*depth,high-low,
        math.abs(direction.X)*width+math.abs(direction.Z)*depth)
    local feet=e.root.Position.Y-N.rootHeight(e)
    local support={};local samples={}
    for _,t in ipairs({0,.25,.5,.75,1}) do
        local ground,part=N.floor(ctx.map,e.root.Position+delta*t)
        if not ground or math.abs(ground.Y-(feet+delta.Y*t))>1.2 then return false end
        if part then support[part]=true end
        samples[#samples+1]={position=e.root.Position+delta*t,height=ground.Y}
    end
    local inventory=floorInventories[ctx.map]
    for _=1,6 do
        local hit=workspace:Blockcast(CFrame.new(center),size,delta,p)
        if not hit then return true end
        local part=hit.Instance
        if not part or not inventory.ids[part] then return false end
        if not support[part] then
            -- Flush landings intentionally overlap deck pieces. A support ray
            -- returns only one of them; confirm the other floor independently.
            local floorParams=RaycastParams.new();floorParams.FilterType=Enum.RaycastFilterType.Include
            floorParams.FilterDescendantsInstances={part};floorParams.RespectCanCollide=true
            for _,sample in ipairs(samples) do
                local contact=workspace:Raycast(sample.position+UP,Vector3.new(0,-40,0),floorParams)
                if contact and math.abs(contact.Position.Y-sample.height)<.05 then support[part]=true;break end
            end
            -- At the foot of a slope the centerline can already be on flat
            -- ground while the rear of the physical collider still touches
            -- the ramp. Confirm real support beneath its longitudinal ends,
            -- within the same bounded step allowance; never ignore a ceiling.
            if not support[part] then for _,t in ipairs({0,1}) do for _,offset in ipairs({-depth*.5,depth*.5}) do
                local at=e.root.Position+delta*t+direction*offset
                local contact=workspace:Raycast(at+UP*2,Vector3.new(0,-40,0),floorParams)
                if contact and math.abs(contact.Position.Y-(feet+delta.Y*t))<=1.2 then support[part]=true end
            end end end
        end
        if not support[part] then return false end
        p=supportFilter(ctx.map,support)
    end
    return false
end
function N.pursuitAgent(e)
    local agent=N.agent(e)
    if e.entered~=false and e.model:FindFirstChild("HumanoidRootPart") then
        local b=N.rigBounds(e,"Walk","Approach")
        local collider=e.model:FindFirstChild("BodyCollider")
        agent.AgentRadius=math.ceil(math.max(agent.AgentRadius,collider and math.max(collider.Size.X,collider.Size.Z)*.5 or 0))
        agent.AgentHeight=math.ceil(math.max(agent.AgentHeight,b.high.Y+N.rootHeight(e)))
    end
    return agent
end
function N.segmentTarget(ctx,e,target)
    local delta=target-e.root.Position;local distance=flat(delta).Magnitude
    if distance<=24 then return target end
    local at=e.root.Position+delta*(24/distance);local floor=N.floor(ctx.map,at+UP*2)
    return floor and Vector3.new(at.X,floor.Y+N.rootHeight(e),at.Z) or at
end
local function accessKey(map)
    return map and (Graph.stateKey and Graph.stateKey(map) or tostring(map.navigationRevision or 0)) or ""
end
function N.trace(owner,e,event,reason,now)
    local debug=owner.navigationDebug;if not debug then return end
    local row={time=now or os.clock(),id=e.id,event=event,reason=reason}
    debug.cursor=debug.cursor%128+1;debug.events[debug.cursor]=row
    debug.count=math.min(128,debug.count+1)
    debug.counters[event]=(debug.counters[event] or 0)+1
end
function N.sync(owner)
    local map=owner.ctx.map;local key=accessKey(map)
    if owner.accessMap~=map or owner.accessKey~=key then
        owner.accessMap=map;owner.accessKey=key;owner.accessCache={}
    end
    return key
end
function N.beginTick(owner)
    N.sync(owner);owner.roomPlanBudget=N.pursuitTuning.roomPlansPerTick
end
function N.canPursue(owner,e,target,now)
    local map=owner.ctx.map
    if not map.navigation or not Graph.plan then return true end
    N.sync(owner)
    local from,fl=Graph.locate(map,e.root.Position-UP*N.rootHeight(e));local to,tl=Graph.locate(map,target)
    local key=from..":"..fl..":"..to..":"..tl
    local cached=owner.accessCache[key]
    if cached==nil then
        cached=Graph.reachable and Graph.reachable(map,e.root.Position-UP*N.rootHeight(e),target)
            or not Graph.reachable and Graph.plan(map,e.root.Position-UP*N.rootHeight(e),target)~=nil
        owner.accessCache[key]=cached
    end
    return cached
end
function N.intent(owner,e,goal,now)
    local map=owner.ctx.map
    if e.entered==false or not map.navigation or not Graph.plan then return goal end
    local key=N.sync(owner);local from,fl=Graph.locate(map,e.root.Position-UP*N.rootHeight(e))
    local to,tl=Graph.locate(map,goal-UP*N.rootHeight(e));local route=e.roomRoute
    e.currentRoom=from;e.targetRoom=to;e.targetLevel=tl
    local failedKey=key..":"..to..":"..tl
    if e.intentFailedKey==failedKey and now<(e.intentRetryAt or 0) then return nil end
    for id,untilAt in pairs(e.avoidNodes or {}) do if now>=untilAt then e.avoidNodes[id]=nil end end
    if not route or route.key~=key or route.toRoom~=to or route.toLevel~=tl or route.target~=e.target
        or route.fromLevel~=fl and route.fromRoom==from then
        if owner.roomPlanBudget then
            if owner.roomPlanBudget<=0 then e.navFailure="RouteBudget";N.trace(owner,e,"route-deferred",e.navFailure,now);return nil end
            owner.roomPlanBudget-=1
        end
        route=Graph.plan(map,e.root.Position-UP*N.rootHeight(e),goal-UP*N.rootHeight(e),{avoid=e.avoidNodes})
        if not route then
            e.intentFailedKey=failedKey;e.intentRetryAt=now+.8
            e.navFailure="NoRoomRoute";N.trace(owner,e,"route-failure",e.navFailure,now);return nil
        end
        e.intentFailedKey=nil
        route.index=1;route.target=e.target;e.roomRoute=route;e.routeBuilds=(e.routeBuilds or 0)+1
        N.trace(owner,e,"room-route",nil,now)
    end
    local at=route.points[route.index]
    while at and N.waypointReached(e,at) do route.index+=1;at=route.points[route.index] end
    local id=at and route.ids[route.index] or "target"
    if e.pathLeg~=id then N.invalidate(e,false,true);e.pathLeg=id end
    e.currentRoom=from;e.targetRoom=to;e.targetLevel=tl;e.routeNode=at and id or nil
    return at and at+UP*N.rootHeight(e) or goal
end
function N.failure(owner,e,reason,now)
    e.pathFailures=(e.pathFailures or 0)+1;e.navFailure=reason
    e.nextPath=now+math.min(N.pursuitTuning.retryMax,.65*2^math.min(3,e.pathFailures-1))
    if e.pathFailures>=3 and e.routeNode and now-(e.progressAt or now)>N.pursuitTuning.stuckSeconds then
        e.avoidNodes=e.avoidNodes or {};e.avoidNodes[e.routeNode]=now+N.pursuitTuning.avoidSeconds;e.roomRoute=nil
    end
    N.trace(owner,e,"path-failure",reason,now);e.model:SetAttribute("NavigationState","Retrying")
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
    local map=owner.ctx.map;local topology=accessKey(map);local target=e.targetRoot
    e.pathRequests=(e.pathRequests or 0)+1;N.trace(owner,e,"path-request",nil,now)
    task.spawn(function()
        local path local ok=pcall(function() path=PF:CreatePath(N.pursuitAgent(e)) path:ComputeAsync(start,goal) end)
        owner.activePaths=math.max(0,owner.activePaths-1)
        if e.dead or owner.ctx.run.id~=run or e.requestToken~=token then return end
        e.computing=false
        if owner.ctx.map~=map or accessKey(map)~=topology or e.targetRoot~=target then
            e.nextPath=0;N.trace(owner,e,"stale-result","AccessOrTargetChanged");return
        end
        local points={};local reason=not ok and "ComputeError" or path.Status~=Enum.PathStatus.Success and "NativeNoPath" or "EmptyNativePath"
        -- Waypoint retrieval/normalization can fail as well as ComputeAsync.
        -- Reject empty and jumping paths without replacing a usable old route.
        if ok and path.Status==Enum.PathStatus.Success then ok=pcall(function()
            for _,point in ipairs(path:GetWaypoints()) do
                if point.Action==Enum.PathWaypointAction.Jump then reason="JumpWaypoint";error("Jumping route rejected") end
                if not U.finiteVector(point.Position) then reason="InvalidWaypoint";error("Invalid native waypoint") end
                local ground=owner.ctx.map and N.floor(owner.ctx.map,point.Position+UP*3)
                if map and not ground then reason="UnsupportedWaypoint";error("Unsupported native waypoint") end
                if e.entered~=false and map and map.navigation then
                    local room=Graph.locate(map,ground or point.Position)
                    if not map.rooms[room].unlocked then reason="LockedWaypoint";error("Locked native waypoint") end
                end
                points[#points+1]={Position=ground or point.Position,Action=point.Action}
                if #points>=N.pursuitTuning.maxWaypoints then break end
            end
        end) end
        if ok and map and #points>0 then
            local nextPoint
            for _,point in ipairs(points) do if not N.waypointReached(e,point.Position) then nextPoint=point;break end end
            if nextPoint then ok=N.clearRoute(owner.ctx,e,N.segmentTarget(owner.ctx,e,nextPoint.Position+UP*N.rootHeight(e)));reason=ok and reason or "BlockedNativeSegment"
            elseif flat(goal-e.root.Position).Magnitude>2 then ok=false end
        end
        if not ok or not path or path.Status~=Enum.PathStatus.Success or #points==0 then
            N.failure(owner,e,reason,os.clock());return
        end
        release(e) e.path=points e.index=1 e.pathGoal=goal e.pathObject=path e.pathFailures=0
        e.nextPath=os.clock()+1.05+(e.id%7)*.035 e.model:SetAttribute("NavigationState","Pursuing")
        N.trace(owner,e,"path-accepted")
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
function N.worldBox(e,position,bounds,forward)
    bounds=bounds or N.rigBounds(e)
    forward=flat(forward or e.root.CFrame.LookVector)
    if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) end
    local rotation=CFrame.lookAt(Vector3.zero,forward.Unit)
    local half=(bounds.high-bounds.low)*.5
    local right,back=rotation.RightVector,-rotation.LookVector
    local size=Vector3.new(math.abs(right.X)*half.X+math.abs(back.X)*half.Z,half.Y,
        math.abs(right.Z)*half.X+math.abs(back.Z)*half.Z)*2
    return position+rotation:VectorToWorldSpace((bounds.low+bounds.high)*.5),size
end
function N.traversalClear(owner,e,a,b,window,overlap,bounds,forward)
    if not U.finiteVector(a) or not U.finiteVector(b) then return false end
    local center,size=N.worldBox(e,b,bounds,forward)
    -- Contact skin only: a sole touching its supporting floor is permitted.
    size-=UP*.02;center+=UP*.01
    local offset=center-b
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=entryIgnore(owner,e,window);params.CollisionGroup="DeadSignalEnemies";params.RespectCanCollide=true
    local delta=b-a
    if delta.Magnitude>.005 and workspace:Blockcast(CFrame.new(a+offset),size,delta,params) then return false,"Geometry" end
    if overlap then
        local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Exclude
        op.FilterDescendantsInstances=params.FilterDescendantsInstances;op.CollisionGroup=params.CollisionGroup;op.RespectCanCollide=true
        for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(b+offset),size,op)) do if part.CanCollide then return false,"Geometry" end end
    end
    local function occupied(otherCenter,otherSize)
        local d=otherCenter-center local half=(otherSize+size)*.5
        return math.abs(d.X)<half.X+.1 and math.abs(d.Y)<half.Y and math.abs(d.Z)<half.Z+.1
    end
    for player,state in pairs(owner.ctx.players or {}) do
        if player.Parent and state.participating and not state.travelling and (state.status=="Alive" or state.status=="Down")
            and U.root(player) and occupied(U.root(player).Position,Vector3.new(2.3,6,2.3)) then return false,"Occupied" end
    end
    for _,other in pairs(owner.list or {}) do if other~=e and not other.dead and other.root.Parent then
        local traversal=other.traversal
        local otherBounds=N.rigBounds(other,traversal and traversal.plan.style or "Walk",traversal and traversal.stage or "Approach")
        local otherCenter,otherSize=N.worldBox(other,other.root.Position,otherBounds,traversal and traversal.plan.forward)
        if occupied(otherCenter,otherSize) then return false,"Occupied" end
    end end
    return true
end
function N.queueRoute(owner,e,position,descriptor,window,bounds)
    local approach=(descriptor.approach or N.floor(owner.ctx.map,window.outside))
    if not approach then return false end
    local forward=descriptor.inward or flat(window.inside-window.outside)
    if not U.finiteVector(forward) or forward.Magnitude<.05 then return false end
    forward=forward.Unit
    local destination=approach+UP*N.rootHeight(e);local delta=destination-position
    -- A valid endpoint below the raised apron is not a no-jump route. Check
    -- physical continuity before admitting the unit, not after it gets stuck.
    local samples=math.max(1,math.ceil(flat(delta).Magnitude/2))
    for sample=0,samples do
        local at=position+delta*(sample/samples)
        local floor=N.floor(owner.ctx.map,at)
        if not floor or math.abs(floor.Y-approach.Y)>N.traversalTuning.queueLevelTolerance then return false end
    end
    local center,size=N.worldBox(e,position,bounds,forward);size-=UP*.02;center+=UP*.01
    local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Include;p.FilterDescendantsInstances={owner.ctx.map.model}
    p.CollisionGroup="DeadSignalEnemies";p.RespectCanCollide=true
    -- This predicts static access through the queue; actual placement and
    -- traversal still check live players/NPCs separately.
    return delta.Magnitude<.005 or not workspace:Blockcast(CFrame.new(center),size,delta,p)
end
function N.queuePosition(owner,e,window)
    local d=N.entryDescriptor(owner.ctx.map,window);if not d then return nil end
    local into=flat(window.inside-window.outside).Unit
    local origin=d.approach or N.floor(owner.ctx.map,window.outside)
    if not origin then return nil end
    local tangent=Vector3.new(into.Z,0,-into.X) local s=owner.ctx.map.scale or 1
    local bounds=N.rigBounds(e,"Walk","Approach")
    -- A short shambler at the front must reserve enough depth for the next
    -- crawler/Alpha, whose complete animated body is much longer.
    local step=math.max(8*s,bounds.high.X-bounds.low.X+.4,bounds.high.Z-bounds.low.Z+.4)
    for slot=0,44 do
        local column=slot%5 local lateral=column==0 and 0 or (column%2==1 and 1 or -1)*math.ceil(column/2)
        local feet=origin+tangent*(lateral*step)-into*(math.floor(slot/5)*step)
        local floor=N.floor(owner.ctx.map,feet+UP*2)
        if floor and math.abs(floor.Y-origin.Y)<=N.traversalTuning.queueLevelTolerance then
            local position=Vector3.new(feet.X,floor.Y+N.rootHeight(e),feet.Z)
            if N.traversalClear(owner,e,position,position,window,true,bounds,into) and N.supported(owner,e,position,into)
                and N.queueRoute(owner,e,position,d,window,bounds) then return position end
        end
    end
    return nil
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
    -- Mount perpendicular to the actual opening. A free offset landing must
    -- not turn the approach/vault diagonally into a jamb.
    local forward=descriptor.inward or window and flat(window.inside-window.outside).Unit or flat(landing-outside).Unit
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
    local front,back,lowest=agent.AgentRadius,agent.AgentRadius,-h
    local style=e.kind=="Crawler" and "Crawl" or e.kind=="Hound" and "Leap" or "Vault"
    for _,name in ipairs({"Contact","Cross","Land"}) do
        local bounds=N.rigBounds(e,style,name)
        local offset,size=N.worldBox(e,Vector3.zero,bounds,forward)
        local projected=(math.abs(forward.X)*size.X+math.abs(forward.Z)*size.Z)*.5
        front=math.max(front,offset:Dot(forward)+projected)
        back=math.max(back,-offset:Dot(forward)+projected);lowest=math.min(lowest,bounds.low.Y)
    end
    raise+=math.max(0,-lowest-h)
    if raise>6*s then return nil,"Geometry" end
    local before=center-forward*math.max(2.2*s,front+.75*s+.3)+UP*h
    local lifted=before+UP*raise
    local after=center+forward*math.max(3*s,back+.75*s+.3)+UP*(h+math.max(landing.Y-outside.Y+.15,raise))
    if kind=="Door" or kind=="Tunnel" or kind=="Vent" then before=outside;lifted=outside;after=landing end
    local fast=e.kind=="Hound" local crawl=e.kind=="Crawler" or kind=="Vent"
    local stages={}
    local function stage(name,a,b,seconds,control) stages[#stages+1]={name=name,a=a,b=b,duration=seconds,control=control} end
    stage("Approach",e.root.Position,before,math.clamp((before-e.root.Position).Magnitude/(fast and 10 or 7),.45,1.35))
    stage("Contact",before,lifted,fast and .18 or crawl and .36 or .30)
    local control=kind~="Door" and kind~="Tunnel" and kind~="Vent" and center+UP*(h+raise+.45*s) or nil
    stage("Cross",lifted,after,fast and .48 or crawl and .85 or .65,control)
    -- Clear the opening before sidestepping toward a free landing. A straight
    -- diagonal descent can sweep through the downed player that caused the
    -- lateral alternative to be selected in the first place.
    local lateral=flat(landing-after)-forward*flat(landing-after):Dot(forward)
    local landingControl=kind=="Window" and lateral.Magnitude>.1 and after+lateral or nil
    stage("Land",after,landing,fast and .24 or .38,landingControl)
    stage("Settle",landing,landing,.18)
    local plan={stages=stages,duration=0,landing=landing,forward=forward,window=window,kind=kind,descriptor=descriptor,
        style=crawl and "Crawl" or fast and "Leap" or "Vault"}
    if kind=="Door" or kind=="Tunnel" then plan.style="Walk" end
    for _,v in ipairs(stages) do plan.duration+=v.duration end
    local previous=e.root.Position
    for index=0,32 do
        local at,name=N.traversalSample(plan,plan.duration*index/32)
        local clear,reason=N.traversalClear(owner,e,previous,at,window,true,N.rigBounds(e,plan.style,name),forward)
        if not clear then return nil,reason end
        previous=at
    end
    if not N.supported(owner,e,e.root.Position,forward) or not N.supported(owner,e,landing,forward) then return nil,"Support" end
    return plan
end
function N.entryDescriptor(map,window)
    local entry=Rules.windowEntry(window);if not entry then return nil end
    if entry.legacy then return {kind="Window",legacy=true} end
    local rootReference=3.5*(map.scale or 1)
    local function support(anchor,allowReference)
        -- A canonical center ray can fall through the narrow seam between
        -- paired floor wedges. Move the target at most .05 world studs onto
        -- an actual supported point; never synthesize a floor across a hole.
        for _,offset in ipairs({Vector3.zero,Vector3.new(.05,0,0),Vector3.new(-.05,0,0),Vector3.new(0,0,.05),Vector3.new(0,0,-.05)}) do
            local floor=N.floor(map,anchor+offset+UP*1.5)
            if floor then
                local reference=anchor.Y-floor.Y
                if math.abs(reference)<=.6 then return floor,false,0 end
                if allowReference and math.abs(reference-rootReference)<.25 then return floor,true,reference end
            end
        end
    end
    local landing,centered,reference=support(entry.landing.Position,true)
    if not landing then return nil end
    -- Maps #29 preserves legacy navigation-reference anchors (3.5*scale over
    -- the supported floor, breach at opening center). Also accept explicit
    -- foot/contact frames. Reject every other height instead of projecting an
    -- unsupported gallery onto the ground floor.
    local approach=entry.approach.Position-UP*(centered and reference or 0)
    local approachFloor=support(approach,false);if not approachFloor then return nil end
    local kinds
    if entry.allowedKinds then kinds={} for _,kind in ipairs(entry.allowedKinds) do kinds[kind]=true end end
    return {kind=entry.kind,approach=approachFloor,
        contact=entry.breach.Position-UP*(centered and entry.clearance.height*.5 or 0),
        landing=landing,width=entry.clearance.radius*2,height=entry.clearance.height,
        kinds=kinds,authored=true,inward=flat(entry.breach.LookVector).Unit,referenceHeight=centered and reference or 0}
end
function N.entryPlan(owner,e,window)
    if not window or window.count>0 or window.activeEntry and window.activeEntry~=e.id then return nil end
    N.expireEntryFailures(e,os.clock())
    if e.failedEntries and e.failedEntries[window]==(owner.ctx.map.navigationRevision or 0) then return nil,"Geometry" end
    local descriptor=N.entryDescriptor(owner.ctx.map,window);if not descriptor then return nil,"Support" end
    local slots=window
    if descriptor.authored then slots=table.clone(window);slots.inside=descriptor.landing+UP*1.5;slots.outside=descriptor.approach+UP*1.5 end
    local selected local failure
    N.entryPoint(owner,e,slots,function(landing)
        if descriptor.authored and math.abs(landing.Y-N.rootHeight(e)-descriptor.landing.Y)>.6 then return false end
        local plan,reason=planPath(owner,e,landing,descriptor,window)
        if plan then selected=plan;return true end
        if failure~="Occupied" then failure=reason or "Geometry" end
        return false
    end)
    return selected,selected and nil or failure or "Occupied"
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
function N.portal(owner,e,now)
    local index=e.routeNode and tonumber(e.routeNode:match("^door(%d+)p"))
    local door=index and owner.ctx.map.doors[index]
    if not door or flat(e.root.Position-door.position).Magnitude>12*(owner.ctx.map.scale or 1) then
        local old=e.portalDoor and owner.portalQueues and owner.portalQueues[e.portalDoor]
        if old then old.waiting[e.id]=nil;if old.lease and old.lease.id==e.id then old.lease=nil end end
        e.portalDoor=nil;return true
    end
    owner.portalQueues=owner.portalQueues or {};local q=owner.portalQueues[index]
    if not q then q={waiting={}};owner.portalQueues[index]=q end
    e.portalDoor=index;e.portalSeenAt=now;q.waiting[e.id]=q.waiting[e.id] or now
    if q.lease then
        local actor=owner.list[q.lease.id]
        if not actor or actor.dead or not actor.root.Parent or now>=q.lease.untilAt then
            if actor then actor.portalBackoffUntil=now+1;q.waiting[actor.id]=now end
            q.lease=nil
        end
    end
    if not q.lease then
        local best,at
        for id,since in pairs(q.waiting) do
            local actor=owner.list[id]
            if not actor or actor.dead or actor.portalDoor~=index or now-(actor.portalSeenAt or since)>2 then q.waiting[id]=nil
            elseif now>=(actor.portalBackoffUntil or 0) and (not at or since<at or since==at and id<best) then best=id;at=since end
        end
        if best then q.lease={id=best,untilAt=now+1.25,progressAt=now} end
    end
    if q.lease and q.lease.id==e.id then
        if (e.progressAt or 0)>q.lease.progressAt then q.lease.progressAt=e.progressAt;q.lease.untilAt=now+1.25 end
        return true
    end
    e.navFailure="CrowdedDoor";e.blockedDoor=index;e.model:SetAttribute("NavigationState","WaitingDoor")
    return false
end
function N.watchdog(owner,e,destination,now,waiting)
    if e.entered==false then
        if flat(e.root.Position-e.lastPosition).Magnitude>.45 then e.lastMoved=now;e.lastPosition=e.root.Position end
        return
    end
    local goal=destination or e.liveGoal or e.root.Position
    e.progressAt=e.progressAt or now;e.progressPosition=e.progressPosition or e.root.Position
    local before=flat(goal-e.progressPosition).Magnitude;local after=flat(goal-e.root.Position).Magnitude
    if flat(e.root.Position-e.progressPosition).Magnitude>.4 and after<before-.2 then
        e.progressAt=now;e.progressPosition=e.root.Position;e.lastMoved=now;e.lastPosition=e.root.Position
    end
    if waiting then e.progressAt=now;e.progressPosition=e.root.Position;return end
    local stuck=now-e.progressAt
    if stuck>N.pursuitTuning.stuckSeconds and not e.computing and now>=(e.replanAt or 0) then
        e.replanAt=now+.8;e.replans=(e.replans or 0)+1
        local retry=e.nextPath or 0;N.invalidate(e,false,true);e.nextPath=math.max(retry,e.nextPath)
        e.model:SetAttribute("NavigationState","Recovering");N.trace(owner,e,"stuck-replan",e.navFailure,now)
    end
    if stuck>N.pursuitTuning.reacquireSeconds and now>=(e.nextRouteRecovery or 0) then
        e.nextRouteRecovery=now+N.pursuitTuning.reacquireSeconds;e.recoveryAttempts=(e.recoveryAttempts or 0)+1
        if e.routeNode then e.avoidNodes=e.avoidNodes or {};e.avoidNodes[e.routeNode]=now+N.pursuitTuning.avoidSeconds end
        e.roomRoute=nil;e.targetAt=0;e.avoidTarget=e.target;e.avoidTargetUntil=now+2
        N.trace(owner,e,"route-recovery","ReacquireAndAlternate",now)
    end
end
function N.snapshot(owner,now)
    local debug=owner.navigationDebug
    if not debug then return {enabled=false} end
    local function vec(v) return v and {v.X,v.Y,v.Z} or nil end
    local rows={};local actors={}
    for _,e in pairs(owner.list or {}) do if not e.dead then actors[#actors+1]=e end end
    table.sort(actors,function(a,b) return a.id<b.id end)
    for index=1,math.min(40,#actors) do
        local e=actors[index];local path={};local route={}
        for i=e.index or 1,math.min(#(e.path or {}),(e.index or 1)+15) do path[#path+1]=vec(e.path[i].Position) end
        for i=e.roomRoute and e.roomRoute.index or 1,math.min(#(e.roomRoute and e.roomRoute.points or {}),(e.roomRoute and e.roomRoute.index or 1)+15) do
            route[#route+1]=vec(e.roomRoute.points[i])
        end
        rows[#rows+1]={id=e.id,kind=e.kind,target=e.target and e.target.UserId or nil,room=e.currentRoom,targetRoom=e.targetRoom,targetLevel=e.targetLevel,
            position=vec(e.root.Position),destination=vec(e.movingTo),waypoints=path,route=route,routeNode=e.routeNode,
            state=e.model:GetAttribute("NavigationState"),failure=e.navFailure,blockedDoor=e.blockedDoor,
            secondsWithoutMovement=math.max(0,now-(e.lastMoved or now)),secondsWithoutProgress=math.max(0,now-(e.progressAt or now)),
            pathRequests=e.pathRequests or 0,replans=e.replans or 0,routeBuilds=e.routeBuilds or 0,failures=e.pathFailures or 0,
            computing=e.computing==true,recoveries=e.recoveryAttempts or 0,retryIn=math.max(0,(e.nextPath or now)-now),entered=e.entered==true}
    end
    local events={}
    for i=debug.count,1,-1 do local at=(debug.cursor-i)%128+1;events[#events+1]=debug.events[at] end
    local blocked={}
    for i,door in ipairs(owner.ctx.map.doors or {}) do if not door.open then blocked[#blocked+1]={id=i,a=door.a,b=door.b} end end
    return {enabled=true,actors=rows,blockedDoors=blocked,events=events,counters=table.clone(debug.counters),
        seconds=math.max(0,now-debug.started),activePaths=owner.activePaths or 0,pathBudget=owner.pathBudget or 0,
        live=#actors,pending=#(owner.pending or {}),topology=accessKey(owner.ctx.map)}
end
function N.move(owner,e,target,now)
    local goal=N.goal(owner.ctx,e,target,now) local revision=owner.ctx.map.navigationRevision or 0
    local topology=N.sync(owner)
    if e.navRevision~=revision or e.navTopology and e.navTopology~=topology then N.invalidate(e);e.navRevision=revision;e.clearRetryAt=nil end
    e.navTopology=topology
    local leg=N.intent(owner,e,goal,now)
    local destination
    if not leg then
        e.model:SetAttribute("NavigationState",e.navFailure=="RouteBudget" and "WaitingRouteBudget" or "NoRoomRoute")
    elseif not N.portal(owner,e,now) then
        e.movingTo=nil;e.hum:MoveTo(e.root.Position);N.watchdog(owner,e,leg,now,true);return
    elseif not e.path and now<(e.clearRetryAt or 0) and (e.root.Position-e.clearPosition).Magnitude<.3 and (leg-e.clearGoal).Magnitude<1.5 then
        -- A stationary blocked actor need not repeat the same spatial work at
        -- every AI tick. Access/target movement cancels this short, bounded hold.
        e.movingTo=nil;e.hum:MoveTo(e.root.Position);N.watchdog(owner,e,leg,now);return
    elseif N.clearRoute(owner.ctx,e,leg) then
        if e.path or e.computing then N.invalidate(e,false,true) end
        destination=leg;e.navFailure=nil;e.blockedDoor=nil;e.model:SetAttribute("NavigationState","Direct")
    else
        if now>=(e.nextPath or 0) or (e.pathFailures or 0)==0 and e.pathGoal and flat(e.pathGoal-leg).Magnitude>6 then N.compute(owner,e,leg,now) end
        local point=e.path and e.path[e.index]
        while point and N.waypointReached(e,point.Position,e.index>1 and e.path[e.index-1].Position) do e.index+=1 point=e.path[e.index] end
        if point then
            local at=N.segmentTarget(owner.ctx,e,point.Position+UP*N.rootHeight(e))
            if N.clearRoute(owner.ctx,e,at) then destination=at;e.navFailure=nil;e.blockedDoor=nil
            else N.invalidate(e,false,true);N.failure(owner,e,"BlockedSegment",now) end
        elseif (e.pathFailures or 0)>=2 and not e.roomRoute then
            -- Legacy producers may still supply recovery hints. A planned room
            -- route must never rescan already-completed anchors behind the NPC.
            local route=Graph.route(owner.ctx.map,e.root.Position,target)
            for _,hint in ipairs(route or {}) do
                local ground=N.floor(owner.ctx.map,hint+UP*3) local p=ground and ground+UP*N.rootHeight(e) or hint
                if flat(p-e.root.Position).Magnitude>2 and N.clearRoute(owner.ctx,e,p) then destination=p break end
            end
        end
        -- A supported clear prefix bridges large room-local distances when
        -- the navmesh is temporarily unavailable. It never crosses a blocker.
        if not destination and e.roomRoute then
            local delta=leg-e.root.Position
            for _,distance in ipairs({12,6,3}) do
                local at=e.root.Position+delta*math.min(1,distance/math.max(.01,flat(delta).Magnitude))
                local floor=N.floor(owner.ctx.map,at+UP*2)
                if floor then at=Vector3.new(at.X,floor.Y+N.rootHeight(e),at.Z)
                    if N.clearRoute(owner.ctx,e,at) then destination=at;break end
                end
            end
        end
    end
    if destination then destination=N.steer(owner,e,destination) end
    if leg and not destination then e.clearGoal=leg;e.clearPosition=e.root.Position;e.clearRetryAt=now+.3+e.id%3*.025
    else e.clearRetryAt=nil end
    e.movingTo=destination e.hum:MoveTo(destination or e.root.Position)
    N.watchdog(owner,e,destination or leg,now)
end
return N
