-- Exercise the assembled map/weapon/enemy modules together. This is source/data
-- contract coverage, not an engine navmesh, collision or rendered sight test.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local V=r.Vector3 local count=0
local function check(ok,message) assert(ok,message);count+=1 end
for _,id in ipairs({'Station','Foundry','Frost'}) do
    local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'))
    local f=loader.install(dm) local load=loader.new(dm)
    local C=load(f.shared.Config) local M=load(f.server.MapBuilder) local Graph=load(f.shared.NavigationGraph)
    local map=M.build(id)
    check(C.ProfileStore=='DeadSignal_Profile_v1',id..' retains production profile contract')
    check(map.navigationRevision==9 and #map.floorParts>0,id..' remaster navigation/floor contract')
    -- Test gate state independently from room progression: no closed gate may
    -- become traversable merely because the rooms have been marked unlocked.
    for _,room in ipairs(map.rooms) do room.unlocked=true end
    for _,door in ipairs(map.doors) do door.open=false end
    check(Graph.route(map,map.rooms[1].center+V.new(0,3,0),map.rooms[6].center+V.new(0,3,0))==nil,id..' closed graph has no cross-sector bypass')
    for _,door in ipairs(map.doors) do
        door.open=true
        local route=Graph.route(map,map.rooms[door.a].center+V.new(2,3,1),map.rooms[door.b].center+V.new(0,3,0))
        check(route and #route>=2,id..' each isolated purchased gate creates its authored route')
        check((route[1]-map.rooms[door.a].center).Magnitude>3,id..' gate approach has no room-center detour')
        door.open=false
    end
    for _,door in ipairs(map.doors) do door.open=true end
    for roomId,room in ipairs(map.rooms) do if room.stairBase then
        local route=Graph.route(map,map.rooms[1].center+V.new(0,3,0),room.upperCenter+V.new(0,3,0))
        local base,top=false,false
        for _,point in ipairs(route or {}) do
            base=base or (point-room.stairBase).Magnitude<.01
            top=top or (point-room.stairTop).Magnitude<.01
        end
        check(base and top,id..' recovery route reaches gallery '..roomId..' through the ramp')
    end end
    -- Combined wall displays must use the new weapon builder while retaining
    -- the authored non-queryable/non-colliding presentation geometry.
    for _,buy in ipairs(map.wallBuys) do
        local gun=buy.part:FindFirstChild('Weapon_'..buy.id)
        if gun then
            check(gun:GetAttribute('WeaponArtRevision')==9,id..' wall display uses integrated weapon revision')
            check(gun.PrimaryPart and gun.PrimaryPart:FindFirstChild('SightAxis'),id..' display retains the sight contract')
        end
    end
    local groundY=0
    local world={GetServerTimeNow=function() return 100 end,Raycast=function(_,origin)
        return {Position=V.new(origin.X,groundY,origin.Z)}
    end}
    local navLoad=loader.new(dm,{globals={workspace=world,RaycastParams={new=function() return {} end}}})
    local N=navLoad(f.server.Navigation) local Rigs=navLoad(f.server.EnemyRigs)
    local parent=r.Instance.new('Folder')
    for index,spec in ipairs({{kind='Shambler'},{kind='Hound',mods={Alpha=true}},{kind='Crawler'},
        {kind='Stalker'},{kind='Warden'},{kind='Runner',mods={Armored=true,Enraged=true}}}) do
        local model,root,hum=Rigs.build(parent,spec.kind,map.spawnPoints[1],index)
        local e={id=index,kind=spec.kind,model=model,root=root,hum=hum,mods=spec.mods or {}}
        Rigs.evolve(e)
        local agent=N.agent(e)
        check(not agent.AgentCanJump and not agent.AgentCanClimb,id..' '..spec.kind..' retains grounded navigation')
        for _,door in ipairs(map.doors) do
            check(agent.AgentRadius*2+.5<door.part.Size.X,id..' '..spec.kind..' fits authored gate width')
            check(agent.AgentHeight+.5<door.part.Size.Y,id..' '..spec.kind..' fits authored gate height')
        end
        local target=map.rooms[6].center+V.new(3,4,2)
        groundY=0
        local goal=N.goal({map=map},e,target,100)
        check(goal.X==target.X and goal.Z==target.Z and math.abs(goal.Y-N.rootHeight(e))<.001,id..' live target coordinates survive map/rig scaling')
        for _,room in ipairs(map.rooms) do if room.stairTop then
            groundY=room.rise
            local upper=N.goal({map=map},e,room.upperCenter+V.new(1,3,1),100)
            check(math.abs(upper.Y-room.rise-N.rootHeight(e))<.001,id..' '..spec.kind..' preserves gallery floor height')
        end end
        model:Destroy()
    end
    parent:Destroy()
end
print('Combined integration contract assertions passed:',count)
