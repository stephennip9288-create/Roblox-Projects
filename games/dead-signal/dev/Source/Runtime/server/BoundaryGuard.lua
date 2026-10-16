local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local B={}
local function polygonContains(p,x,z)
    if not p then return true end
    local inside=false local j=#p
    for i,a in ipairs(p) do local b=p[j]
        if (a[2]>z)~=(b[2]>z) and x<(b[1]-a[1])*(z-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
        j=i
    end return inside
end
function B.contains(map,pos)
    if not U.finiteVector(pos) then return false end
    for _,area in ipairs(map.areas or {}) do
        local enabled=area.room and map.rooms[area.room].unlocked or area.door and (map.rooms[area.door.a].unlocked or map.rooms[area.door.b].unlocked)
        if enabled and pos.X>=area.minX and pos.X<=area.maxX and pos.Z>=area.minZ and pos.Z<=area.maxZ
            and pos.Y>=area.minY and pos.Y<=area.maxY and polygonContains(area.polygon,pos.X,pos.Z) then return true end
    end return false
end
function B.enforce(ctx,player,state)
    local map=ctx.map local root=U.root(player)
    if not map or not root or not state.participating or (state.status~="Alive" and state.status~="Down") then return false end
    if B.contains(map,root.Position) then
        -- Remember only supported positions on authored floors, decks and stairs.
        local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances=map.floorParts or {}
        local floor=workspace:Raycast(root.Position,Vector3.new(0,-35,0),params)
        local hum=U.humanoid(player) local leg=player.Character:FindFirstChild("Left Leg")
        local clearance=state.status=="Down" and 1.8 or math.max(3.8,root.Size.Y*.5+(hum and hum.HipHeight or 0)+(leg and leg.Size.Y or 0)+.9)
        if floor and root.Position.Y-floor.Position.Y<=clearance then
            state.safePosition=root.Position state.unsupportedSince=nil return false
        end
        -- A prop or railing is not a playable floor. Allow brief falls/steps, then correct.
        state.unsupportedSince=state.unsupportedSince or os.clock()
        if os.clock()-state.unsupportedSince<1.1 then return false end
    end
    local safe=state.safePosition
    if not safe or not B.contains(map,safe) then safe=map.spawnPoints[1] end
    root.CFrame=CFrame.new(safe) root.AssemblyLinearVelocity=Vector3.new(0,0,0) root.AssemblyAngularVelocity=Vector3.new(0,0,0)
    state.lastPosition=safe state.lastSample=os.clock() state.safePosition=safe
    state.escapeCorrections=(state.escapeCorrections or 0)+1
    state.unsupportedSince=nil
    return true
end
return B
