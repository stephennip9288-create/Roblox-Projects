local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local W=require(RS.DeadSignal.WeaponModels)
local D=require(RS.DeadSignal.DeploymentRules)
local Detail=require(script.Parent.MapDetail)
local Architecture=require(script.Parent.Architecture)
local Layouts=require(RS.DeadSignal.MapLayouts)
local Vending=require(script.Parent.PerkMachines)
local NavGraph=require(RS.DeadSignal.NavigationGraph)
local Vehicles=require(script.Parent.Vehicles)
local Finish=require(script.Parent.WorldFinish)
local Cinematic=require(script.Parent.CinematicWorld)
local WorldArt=require(script.Parent.WorldArt)
local Routes=require(script.Parent.MapRoutes)
local VisualPass=require(script.Parent.VisualPass)
local M={}
local function part(parent,name,size,cf,color,material,collision,class)
    return U.make(class or "Part",parent,{Name=name,Size=size,CFrame=cf,Color=color,
        Material=material or Enum.Material.Concrete,Anchored=true,CanCollide=collision~=false,
        CanTouch=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth})
end
local function sign(parent,text,cf,size,color)
    local p=part(parent,"Sign",size or Vector3.new(12,3,.2),cf,Color3.fromRGB(24,28,30),Enum.Material.Metal,false)
    p.CanQuery=false
    local gui=U.make("SurfaceGui",p,{Face=Enum.NormalId.Front,PixelsPerStud=64,LightInfluence=0,MaxDistance=65,AlwaysOnTop=false})
    local label=U.make("TextLabel",gui,{Size=UDim2.fromScale(.92,.82),Position=UDim2.fromScale(.04,.09),BackgroundTransparency=1,Text=text,
        TextColor3=color or Color3.fromRGB(221,223,212),Font=Enum.Font.GothamBold,TextScaled=true,TextWrapped=true})
    U.make("UITextSizeConstraint",label,{MinTextSize=12,MaxTextSize=64})
    U.make("Frame",gui,{Name="HeaderRule",Size=UDim2.new(.92,0,0,2),Position=UDim2.fromScale(.04,.03),BorderSizePixel=0,
        BackgroundColor3=color or Color3.fromRGB(155,170,154),BackgroundTransparency=.35})
    for _,x in ipairs({-.47,.47}) do for _,y in ipairs({-.41,.41}) do
        local pin=part(p,"SignFastener",Vector3.new(.07,.07,.035),cf*CFrame.new(size and size.X*x or 12*x,size and size.Y*y or 3*y,-.12),Color3.fromRGB(97,108,99),Enum.Material.Metal,false)
        pin.CanQuery=false
    end end
    return p
end
M.sign=sign M.part=part
local function light(parent,cf,color,on)
    local p=part(parent,"EmergencyLight",Vector3.new(2,.35,1),cf,color,Enum.Material.Neon,false)
    local housing=part(p,"FixtureHousing",Vector3.new(2.3,.32,1.25),cf*CFrame.new(0,.22,0),Color3.fromRGB(46,52,47),Enum.Material.Metal,false) housing.CanQuery=false
    U.make("PointLight",p,{Brightness=on and 1.4 or .25,Range=26,Color=color,Shadows=false})
    p:SetAttribute("PowerLight",true)
    return p
end
function M.holding()
    local old=workspace:FindFirstChild("DeadSignalHolding") if old then old:Destroy() end
    local f=U.make("Model",workspace,{Name="DeadSignalHolding"}) local c=Vector3.new(0,0,-690)
    local col=Color3.fromRGB(34,44,49)
    part(f,"Floor",Vector3.new(44,2,34),CFrame.new(c-Vector3.new(0,1,0)),col)
    for _,x in ipairs({-22,22}) do part(f,"Wall",Vector3.new(2,18,34),CFrame.new(c+Vector3.new(x,9,0)),col) end
    for _,z in ipairs({-17,17}) do part(f,"Wall",Vector3.new(44,18,2),CFrame.new(c+Vector3.new(0,9,z)),col) end
    part(f,"Roof",Vector3.new(44,2,34),CFrame.new(c+Vector3.new(0,18,0)),col)
    light(f,CFrame.new(c+Vector3.new(0,15,0)),Color3.fromRGB(116,211,225),true)
    sign(f,"SIGNAL SHELTER\nELIMINATED OPERATORS REJOIN AT THE NEXT ROUND",CFrame.new(c+Vector3.new(0,8,15)),Vector3.new(32,5,.2))
    return {model=f,position=c+Vector3.new(0,4,0)}
end
function M.lobby()
    local old=workspace:FindFirstChild("DeadSignalLobby") if old then old:Destroy() end
    local f=U.make("Model",workspace,{Name="DeadSignalLobby"})
    local center=Vector3.new(0,0,-448)
    local dark=Color3.fromRGB(36,41,44) local amber=Color3.fromRGB(242,159,70)
    part(f,"HangarFloor",Vector3.new(224,2,142),CFrame.new(center-Vector3.new(0,1,0)),dark,Enum.Material.Concrete)
    for _,x in ipairs({-112,112}) do part(f,"HangarWall",Vector3.new(2,30,142),CFrame.new(center+Vector3.new(x,15,0)),dark,Enum.Material.Brick) end
    for _,z in ipairs({-71,71}) do part(f,"HangarWall",Vector3.new(224,30,2),CFrame.new(center+Vector3.new(0,15,z)),dark,Enum.Material.Brick) end
    part(f,"Roof",Vector3.new(226,1,144),CFrame.new(center+Vector3.new(0,30,0)),dark,Enum.Material.Metal)
    for x=-96,96,32 do
        part(f,"SteelTruss",Vector3.new(1,1,144),CFrame.new(center+Vector3.new(x,28,0)),Color3.fromRGB(64,76,79),Enum.Material.Metal,false)
        for _,z in ipairs({-14,14}) do light(f,CFrame.new(center+Vector3.new(x,27,z)),Color3.fromRGB(197,216,213),true) end
    end
    for _,z in ipairs({-9,9}) do part(f,"ConcourseEdge",Vector3.new(211,.035,.25),CFrame.new(center+Vector3.new(0,.03,z)),amber,Enum.Material.SmoothPlastic,false) end
    for x=-96,96,12 do part(f,"PathMarker",Vector3.new(4,.025,1),CFrame.new(center+Vector3.new(x,.04,0)),Color3.fromRGB(106,163,169),Enum.Material.Metal,false) end
    sign(f,"DEAD SIGNAL / DISPATCH",CFrame.new(center+Vector3.new(-108,19,0))*CFrame.Angles(0,-math.pi/2,0),Vector3.new(46,5,.2),Color3.fromRGB(213,127,99))
    sign(f,"WALK INTO A BAY • CHOOSE A MAP • LEADER STARTS\nSOLO: 1 OPERATOR     CREW: 2–4 OPERATORS",CFrame.new(center+Vector3.new(108,18,0))*CFrame.Angles(0,math.pi/2,0),Vector3.new(43,6,.2),amber)
    local kiosk=part(f,"DispatchTerminal",Vector3.new(8,4,3),CFrame.new(center+Vector3.new(-95,2,0)),Color3.fromRGB(53,62,62),Enum.Material.Metal)
    local bays={}
    for _,def in ipairs(D.Bays) do
        local bay=U.make("Model",f,{Name="DepartureBay_"..def.id}) local c=Vector3.new(def.x,0,def.z)
        local north=def.z<center.Z local facing=north and 1 or -1 local yaw=north and math.pi or 0
        local color=def.max==1 and Color3.fromRGB(91,201,219) or amber
        part(bay,"BoardingDeck",Vector3.new(36,.3,34),CFrame.new(c+Vector3.new(0,.15,0)),Color3.fromRGB(46,54,58),Enum.Material.Metal)
        local entry=c+Vector3.new(0,.4,facing*15)
        local pad=part(bay,"WalkInPad",Vector3.new(20,.05,10),CFrame.new(entry),color,Enum.Material.Neon,false) pad.Transparency=.55
        for _,x in ipairs({-18,18}) do
            part(bay,"BayPost",Vector3.new(.7,12,.7),CFrame.new(c+Vector3.new(x,6,14*facing)),color,Enum.Material.Metal)
            for z=-12,12,8 do part(bay,"SafetyBollard",Vector3.new(.6,3,.6),CFrame.new(c+Vector3.new(x,1.5,z)),color,Enum.Material.Metal) end
        end
        local label=sign(bay,def.name.."\nWALK IN TO BOARD",CFrame.new(c+Vector3.new(0,12,14*facing))*CFrame.Angles(0,yaw,0),Vector3.new(30,5,.2),color)
        local console=part(bay,"CrewTerminal",Vector3.new(4,4,2),CFrame.new(c+Vector3.new(-13,2,10*facing)),dark,Enum.Material.Metal)
        sign(console,"CREW CONTROL",console.CFrame*CFrame.new(0,3,0)*CFrame.Angles(0,yaw,0),Vector3.new(7,1.3,.2),color)
        Vehicles.build(bay,CFrame.new(c)*CFrame.Angles(0,facing==1 and 0 or math.pi,0),color,def.id)
        local spots={}
        for i=1,def.max do
            local x=def.max==1 and 0 or (i%2==0 and 4 or -4)
            local z=facing*(i<=2 and 7 or 12)
            local spot=c+Vector3.new(x,4,z) table.insert(spots,spot)
            part(bay,"OperatorSlot_"..i,Vector3.new(5,.06,4),CFrame.new(c+Vector3.new(x,.38,z)),color,Enum.Material.Neon,false).Transparency=.5
        end
        bays[def.id]={entry=entry,console=console,label=label,spots=spots}
    end
    for _,x in ipairs({-90,90}) do
        part(f,"WorkBench",Vector3.new(18,3,6),CFrame.new(center+Vector3.new(x,1.5,56)),dark,Enum.Material.Metal)
        for i=1,3 do
            local gun=W.build(C.BoxPool[i+(x>0 and 3 or 0)],"Factory",0,f,false)
            gun:PivotTo(CFrame.new(center+Vector3.new(x-6+i*3,3.6,56))*CFrame.Angles(0,math.pi/2,0))
        end
    end
    local manual=sign(f,"FIELD MANUAL\nSURVIVE • RESTORE POWER • UPGRADE\nDECODE THE SIGNAL • EXTRACT",CFrame.new(center+Vector3.new(-38,8,66)),Vector3.new(26,8,.2),amber)
    local record=sign(f,"OPERATOR RECORDS\nSOLO / CREW • SURVIVAL / LOCKDOWN",CFrame.new(center+Vector3.new(38,8,66)),Vector3.new(26,8,.2))
    local armory=sign(f,"ARMORY\n20 WEAPONS • EARN YOUR FINISH",CFrame.new(center+Vector3.new(88,9,65)),Vector3.new(27,6,.2),Color3.fromRGB(116,209,218))
    for j=1,8 do
        local c=center+Vector3.new(-100+j*24,3,-66)
        part(f,"DispatchEquipment",Vector3.new(10,6,3),CFrame.new(c),dark,Enum.Material.Metal)
        sign(f,"CHANNEL "..j.."\n09.6 / STANDBY",CFrame.new(c+Vector3.new(0,0,1.6))*CFrame.Angles(0,math.pi,0),Vector3.new(7,3,.15),Color3.fromRGB(86,177,183))
    end
    local spawn=U.make("SpawnLocation",f,{Name="DispatchSpawn",Size=Vector3.new(8,1,8),CFrame=CFrame.new(center+Vector3.new(0,.5,0)),Anchored=true,Neutral=true,Duration=0,Transparency=1,CanCollide=false})
    Finish.lobby(f,center)
    WorldArt.apply(f,"Lobby")
    WorldArt.lobby(f,center)
    return {model=f,spawn=spawn,kiosk=kiosk,armory=armory,manual=manual,record=record,bays=bays,position=center+Vector3.new(0,4,0)}
end
local loadouts={Station={"Carbine","Rook","Trench","Vandal","Anchor","Meridian"},Foundry={"Carbine","Breaker","Wasp","Sable","Bulwark","Vigil"},Frost={"Carbine","Needle","Trench","Harrier","Mantis","Halcyon"}}
function M.build(id)
    local physics=game:GetService("PhysicsService")
    for _,group in ipairs({"DeadSignalPlayers","DeadSignalEnemies","DeadSignalWindow","DeadSignalShots","DeadSignalBounds"}) do pcall(function() physics:RegisterCollisionGroup(group) end) end
    for _,group in ipairs({"Default","DeadSignalEnemies","DeadSignalShots"}) do physics:CollisionGroupSetCollidable("DeadSignalBounds",group,false) end
    physics:CollisionGroupSetCollidable("DeadSignalBounds","DeadSignalPlayers",true)
    physics:CollisionGroupSetCollidable("DeadSignalWindow","DeadSignalShots",false)
    local def=C.Maps[id] or C.Maps.Station local layout=Layouts[id] or Layouts.Station
    local old=workspace:FindFirstChild("DeadSignalMap") if old then old:Destroy() end
    local f=U.make("Model",workspace,{Name="DeadSignalMap"}) local scale=def.scale
    local map={id=id,model=f,scale=scale,rooms={},doors={},windows={},perks={},wallBuys={},boxSpots={},fuses={},panels={},traps={}}
    local function P(name,size,pos,col,mat,solid,rot,class)
        local p=part(f,name,size*scale,CFrame.new(pos*scale)*(rot or CFrame.new()),col or U.color(def.wall),mat,solid,class)
        if solid==false then p.CanQuery=false end return p
    end
    local function S(text,pos,size,angle,col)
        return sign(f,text,CFrame.new(pos*scale)*CFrame.Angles(0,angle or 0,0),size*scale,col or U.color(def.accent))
    end
    P("ExteriorGround",Vector3.new(680,3,620),Vector3.new(10,-2.5,42),def.theme=="Frost" and Color3.fromRGB(176,188,182) or Color3.fromRGB(54,61,42),def.theme=="Frost" and Enum.Material.Snow or Enum.Material.Ground,true)
    Architecture.build(map,layout,P,S,light,def)
    -- Allocate against actual solid wall spans. Never pull a wall display toward a room center.
    -- The same bays own their clear standing/revive approaches and prompt separation.
    map.mounts={}
    local occupied={}
    for _,w in ipairs(map.windows) do table.insert(occupied,{position=w.part.Position,room=w.room}) end
    for _,d in ipairs(map.doors) do
        table.insert(occupied,{position=d.part.Position,room=d.a})
        table.insert(occupied,{position=d.part.Position,room=d.b})
    end
    local requests={}
    local function request(room,key,width,depth,height)
        table.insert(requests,{room=room,key=key,width=width,depth=depth,height=height})
    end
    request(3,"Power",6,2.2,2.5) request(5,"Transmitter",17,3.4,2.7)
    request(6,"Forge",14,8,3.5) request(2,"Rescue",12,3.4,1.65)
    local perkRooms={1,3,4,2,5,6}
    for j,key in ipairs(C.PerkOrder) do request(perkRooms[j],"Perk_"..key,6,4,0) end
    for i,weapon in ipairs(loadouts[id] or loadouts.Station) do
        request(i,"WallBuy_"..weapon,14,.5,4.7/scale) request(i,"SupplyBox",9/scale,4/scale,1.5/scale)
    end
    request(1,"StarterAmmo",8,.5,3.8/scale)
    for j,room in ipairs({1,4,6}) do request(room,"Fuse_"..j,3,.6,3.2/scale) end
    for j,room in ipairs({2,4,6}) do request(room,"Frequency_"..j,6,1.6,1.6) end
    for _,room in ipairs({3,4}) do request(room,"Trap",4,1.5,1.5) end
    request(1,"Counter_Vent",9,1,3/scale) request(4,"Counter_Sprinkler",9,1,3/scale)
    local planned={}
    for room,r in ipairs(layout) do
        local choices={}
        for _,spec in ipairs(requests) do if spec.room==room then
            local candidates={}
            for _,face in ipairs(map.rooms[room].wallFaces) do
                local limit=face.length/2-spec.width/2-1.5
                for offset=-limit,limit,2.5/scale do
                    local at=face.center+face.tangent*offset-face.normal*(.82+spec.depth/2)+Vector3.new(0,spec.height,0)
                    local approach=at-face.normal*(spec.depth/2+4/scale)
                    local clear=Layouts.contains(r,approach.X,approach.Z,3/scale)
                    for _,dx in ipairs({-spec.width/2,spec.width/2}) do for _,dz in ipairs({-spec.depth/2,spec.depth/2}) do
                        local corner=at+face.tangent*dx+face.normal*dz
                        if not Layouts.contains(r,corner.X,corner.Z,.7) then clear=false end
                    end end
                    for _,item in ipairs(occupied) do if item.room==room then
                        local d=at*scale-item.position
                        if Vector3.new(d.X,0,d.Z).Magnitude<20.5 then clear=false break end
                    end end
                    local sector=map.rooms[room]
                    for _,stair in ipairs(sector.stairs or {}) do
                        local a,b=stair.base/scale,stair.top/scale
                        local t=math.clamp((at-a):Dot(b-a)/(b-a):Dot(b-a),0,1)
                        local d=at-(a+(b-a)*t)
                        if Vector3.new(d.X,0,d.Z).Magnitude<spec.depth/2+8 then clear=false end
                    end
                    if clear then table.insert(candidates,{cf=Layouts.wallFrame(at,face.normal),
                        room=room,key=spec.key,width=spec.width,depth=spec.depth,
                        wall=(face.center+face.tangent*offset)*scale,approach=approach*scale}) end
                end
            end
            table.insert(choices,{spec=spec,candidates=candidates})
        end end
        -- Most constrained bays first. Bounded backtracking avoids order-dependent placement
        -- failures when a small panel consumes the only span wide enough for a cabinet.
        table.sort(choices,function(a,b) if #a.candidates==#b.candidates then return a.spec.key<b.spec.key end return #a.candidates<#b.candidates end)
        local selected={} local attempts=0
        local function solve(index)
            if index>#choices then return true end
            for _,candidate in ipairs(choices[index].candidates) do
                attempts+=1 if attempts>80000 then return false end
                local clear=true
                for _,old in ipairs(selected) do
                    local d=(candidate.cf.Position-old.cf.Position)*scale
                    if Vector3.new(d.X,0,d.Z).Magnitude<20.5 then clear=false break end
                end
                if clear then
                    selected[index]=candidate
                    if solve(index+1) then return true end
                    selected[index]=nil
                end
            end return false
        end
        assert(solve(1),"No separated wall-bay plan for "..id.." / sector "..room)
        for _,bay in ipairs(selected) do planned[room..":"..bay.key]=bay end
    end
    local function mount(room,key)
        local bay=assert(planned[room..":"..key],"Unplanned wall bay: "..key)
        table.insert(map.mounts,bay) return bay.cf
    end
    local function at(name,size,cf,col,mat,solid)
        return P(name,size,cf.Position,col,mat,solid,cf-cf.Position)
    end
    local function frontLabel(parent,text,cf,depth,width,height,col)
        local face=cf*CFrame.new(0,5.4/scale-cf.Position.Y,-depth/2-.14)
        local p=sign(parent,text,CFrame.new(face.Position*scale)*(face-face.Position),Vector3.new(width,height,.10)*scale,col or Color3.fromRGB(235,238,224))
        p:SetAttribute("InteractionSign",true) return p
    end
    -- Large cabinets reserve their bays before narrow displays and pickups.
    local powerCF=mount(3,"Power")
    map.power=at("PowerSwitch",Vector3.new(4,5,1.8),powerCF,Color3.fromRGB(49,58,49),Enum.Material.CorrodedMetal,true)
    frontLabel(map.power,"MAIN BREAKER / OFF",powerCF,2.2,8,1.5,Color3.fromRGB(245,219,159))
    map.lever=at("BreakerLever",Vector3.new(.4,1.7,.4),powerCF*CFrame.new(0,.3,-1.25),Color3.fromRGB(171,56,39),Enum.Material.Metal,false) map.lever.Parent=map.power
    local relayCF=mount(5,"Transmitter")
    map.relay=at("Transmitter",Vector3.new(10,5.4,3),relayCF,Color3.fromRGB(47,56,47),Enum.Material.Metal,true)
    for n=1,5 do
        at("RelayInstrument",Vector3.new(1.4,1.3,.08),relayCF*CFrame.new(-4+n*1.4,.4,-1.54),Color3.fromRGB(158,169,116),Enum.Material.Neon,false).Parent=map.relay
        local dial=at("InstrumentDial",Vector3.new(.5,.5,.08),relayCF*CFrame.new(-4+n*1.4,-.9,-1.6),Color3.fromRGB(141,141,123),Enum.Material.Metal,false) dial.Parent=map.relay
    end
    frontLabel(map.relay,"TRANSMITTER / THREE FUSES",relayCF,3.4,16,1.6)
    local forgeCF=mount(6,"Forge")
    map.upgrade=at("UpgradeMachine",Vector3.new(9,7,6),forgeCF,Color3.fromRGB(47,64,62),Enum.Material.Metal,true)
    for _,dx in ipairs({-3.1,3.1}) do
        local col=at("ForgeCondenser",Vector3.new(6.2,1.7,1.7),forgeCF*CFrame.new(dx,.1,-3.5)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(104,127,123),Enum.Material.Metal,false) col.Shape=Enum.PartType.Cylinder col.Parent=map.upgrade
        for n=1,7 do at("ForgeRing",Vector3.new(2,.13,2),forgeCF*CFrame.new(dx,-2.7+n*.8,-3.5),Color3.fromRGB(80,191,201),Enum.Material.Neon,false).Parent=map.upgrade end
    end
    local glass=at("ForgeInspection",Vector3.new(4.8,3,.15),forgeCF*CFrame.new(0,.4,-3.12),Color3.fromRGB(77,145,145),Enum.Material.Glass,false) glass.Transparency=.35 glass.Parent=map.upgrade
    frontLabel(map.upgrade,"RESONANCE FORGE\n5000 / 7500 POINTS",forgeCF,8,13,2.2,Color3.fromRGB(177,238,235))
    local radioCF=mount(2,"Rescue")
    map.radio=at("ExtractionRadio",Vector3.new(5,3.3,3),radioCF,Color3.fromRGB(66,74,54),Enum.Material.Metal,true)
    for n=1,4 do at("RadioGrille",Vector3.new(3.7,.06,.08),radioCF*CFrame.new(0,-.7+n*.3,-1.56),Color3.fromRGB(24,30,24),Enum.Material.Metal,false).Parent=map.radio end
    at("RadioAntenna",Vector3.new(.12,5,.12),radioCF*CFrame.new(1.6,3,0),Color3.fromRGB(155,158,143),Enum.Material.Metal,false).Parent=map.radio
    frontLabel(map.radio,"RESCUE CHANNEL\nSIGNAL + ROUND 15",radioCF,3.4,12,2.2)
    for j,key in ipairs(C.PerkOrder) do
        local room=perkRooms[j] local cf=mount(room,"Perk_"..key)
        local body,model=Vending.build(f,key,CFrame.new(cf.Position*scale)*(cf-cf.Position),scale)
        map.perks[key]={part=body,model=model,room=room}
    end
    for i,weapon in ipairs(loadouts[id] or loadouts.Station) do
        local cf=mount(i,"WallBuy_"..weapon)
        local plaque=at("WallBuy_"..weapon,Vector3.new(12,3.1,.16),cf,Color3.fromRGB(29,37,37),Enum.Material.Metal,false)
        -- Recenter the actual display bounds; weapon blueprints/ADS remain owned by combat.
        local gun=W.build(weapon,"Factory",0,plaque,false)
        local side=CFrame.Angles(0,math.pi/2,0) local lo,hi=math.huge,-math.huge
        local thickness=0
        for _,p in ipairs(gun:GetDescendants()) do if p:IsA("BasePart") then
            local c=side*p.CFrame local sz=p.Size*.5
            local x=math.abs(c.RightVector.X)*sz.X+math.abs(c.UpVector.X)*sz.Y+math.abs(c.LookVector.X)*sz.Z
            local z=math.abs(c.RightVector.Z)*sz.X+math.abs(c.UpVector.Z)*sz.Y+math.abs(c.LookVector.Z)*sz.Z
            lo=math.min(lo,c.Position.X-x) hi=math.max(hi,c.Position.X+x) thickness=math.max(thickness,c.Position.Z+z)
        end end
        gun:PivotTo(plaque.CFrame*CFrame.new(-(lo+hi)/2,0,-.12-thickness)*side)
        local labelCF=cf*CFrame.new(0,-2.1/scale,-.4)
        sign(plaque,C.Weapons[weapon].name.." / "..C.Weapons[weapon].cost,
            CFrame.new(labelCF.Position*scale)*(labelCF-labelCF.Position),Vector3.new(13,1.3,.1)*scale,Color3.fromRGB(235,224,188))
        map.wallBuys[i]={part=plaque,id=weapon,room=i}
        local boxCF=mount(i,"SupplyBox")
        table.insert(map.boxSpots,{room=i,cf=CFrame.new(boxCF.Position*scale)*(boxCF-boxCF.Position)})
    end
    local ammoCF=mount(1,"StarterAmmo")
    local ammo=at("StarterAmmunition",Vector3.new(5,2.2,.25),ammoCF,Color3.fromRGB(75,79,51),Enum.Material.Metal,false)
    frontLabel(ammo,"KESTREL REFILL / 225",ammoCF,.5,8,1.4,Color3.fromRGB(235,224,188))
    table.insert(map.wallBuys,{part=ammo,id="Kestrel",room=1})
    for j,room in ipairs({1,4,6}) do
        local cf=mount(room,"Fuse_"..j)
        local bracket=at("FuseCradle",Vector3.new(2,2.5,.3),cf,Color3.fromRGB(35,46,46),Enum.Material.Metal,false)
        local fuse=at("Fuse_"..j,Vector3.new(.7,1.8,.7),cf*CFrame.new(0,0,-.55),Color3.fromRGB(95,212,210),Enum.Material.Neon,false)
        U.make("PointLight",fuse,{Color=Color3.fromRGB(85,205,219),Brightness=.6,Range=11,Shadows=false})
        frontLabel(bracket,"SIGNAL FUSE "..j,cf,.6,5,1.2)
        map.fuses[j]={part=fuse,room=room,collected=false}
    end
    for j,room in ipairs({2,4,6}) do
        local cf=mount(room,"Frequency_"..j)
        local panel=at("FrequencyPanel"..j,Vector3.new(3.5,3.2,1.4),cf,Color3.fromRGB(66,71,57),Enum.Material.Metal,true)
        local screen=frontLabel(panel,"FREQUENCY "..j.."\n1",cf,1.6,5.8,2,Color3.fromRGB(218,235,180))
        map.panels[j]={part=panel,screen=screen,value=1,room=room}
    end
    local yard=layout[2] map.exfilCenter=Vector3.new(yard.x,0,yard.z)*scale
    for n=1,16 do local a=n*math.pi/8
        P("ExtractionMarker",Vector3.new(1.2,.04,.35),Vector3.new(yard.x+math.cos(a)*15,.055,yard.z+math.sin(a)*15),Color3.fromRGB(195,174,96),Enum.Material.Metal,false,CFrame.Angles(0,-a,0))
    end
    for _,room in ipairs({3,4}) do
        local cf=mount(room,"Trap")
        local controller=at("TrapControl",Vector3.new(2.3,3,1.3),cf,Color3.fromRGB(141,135,85),Enum.Material.Metal,true)
        frontLabel(controller,"ARC FENCE / 1000",cf,1.5,7,1.4,Color3.fromRGB(245,219,159))
        local r=layout[room] local center=Vector3.new(r.x,0,r.z)*scale
        -- Recessed floor emitters have no posts to snag a revive or a large enemy.
        for _,dx in ipairs({-9,9}) do P("TrapEmitter",Vector3.new(.8,.08,2),Vector3.new(r.x+dx,.06,r.z),Color3.fromRGB(71,81,78),Enum.Material.Metal,false) end
        local beam=P("TrapField",Vector3.new(17,6,.3),Vector3.new(r.x,3,r.z),Color3.fromRGB(78,208,235),Enum.Material.Neon,false) beam.Transparency=1
        map.traps[#map.traps+1]={part=controller,center=center,beam=beam,activeUntil=0,cooldownUntil=0,room=room}
    end
    local entry=layout[1] map.spawnPoints={}
    for _,v in ipairs({Vector3.new(-6,4,-3),Vector3.new(6,4,-3),Vector3.new(-6,4,7),Vector3.new(6,4,7)}) do
        table.insert(map.spawnPoints,(Vector3.new(entry.x,0,entry.z)+v)*scale)
    end
    NavGraph.build(map)
    -- Furniture is authored around objective volumes and their standing approaches.
    map.interactionZones={} map.detailZones={}
    local function reserve(pos,size,minY,maxY,zones)
        table.insert(zones or map.interactionZones,{minX=pos.X-size.X/2-3*scale,maxX=pos.X+size.X/2+3*scale,
            minZ=pos.Z-size.Z/2-3*scale,maxZ=pos.Z+size.Z/2+3*scale,minY=minY or -1,maxY=maxY or 8*scale})
    end
    local function reservePart(p)
        local a,b,c=p.CFrame.RightVector,p.CFrame.UpVector,p.CFrame.LookVector local sz=p.Size
        reserve(p.Position,Vector3.new(math.abs(a.X)*sz.X+math.abs(b.X)*sz.Y+math.abs(c.X)*sz.Z,
            math.abs(a.Y)*sz.X+math.abs(b.Y)*sz.Y+math.abs(c.Y)*sz.Z,math.abs(a.Z)*sz.X+math.abs(b.Z)*sz.Y+math.abs(c.Z)*sz.Z))
    end
    for _,p in ipairs({map.power,map.relay,map.upgrade,map.radio}) do reservePart(p) end
    for _,group in ipairs({map.perks,map.panels,map.fuses,map.traps,map.wallBuys}) do
        for _,v in pairs(group) do reservePart(v.part) end
    end
    for _,v in ipairs(map.boxSpots) do reserve(v.cf.Position,Vector3.new(7,3,3)) end
    for _,v in ipairs(map.spawnPoints) do reserve(v,Vector3.new(3,6,3)) end
    for _,window in ipairs(map.windows) do reserve(window.inside,Vector3.new(11,8,12)*scale,-1,9*scale) end
    for id,node in pairs(map.navigation.nodes) do
        if id:sub(1,4)=="door" then reserve(node.position,Vector3.new(12,7,12)*scale,-1,8*scale) end
    end
    for _,room in ipairs(map.rooms) do for _,stair in ipairs(room.stairs or {}) do
        reserve((stair.base+stair.top)*.5,Vector3.new(stair.width/scale+2,stair.rise/scale+6,36)*scale,-1,stair.rise+5*scale)
    end end
    -- Keep the elevated service circuit clear of colliding dressing at actor height.
    for _,room in ipairs(map.rooms) do if room.upperRing then
        for i,a in ipairs(room.upperRing) do local b=room.upperRing[i%#room.upperRing+1]
            reserve((a+b)*.5,Vector3.new(math.abs(a.X-b.X)+8*scale,8*scale,math.abs(a.Z-b.Z)+8*scale),room.rise-.6*scale,room.rise+9*scale,map.detailZones)
        end
    end end
    -- Reserve counter panels before set dressing; candidates avoid every objective,
    -- portal, vault, spawn and stair approach. Panels have no movement collision.
    map.counters={}
    for _,spec in ipairs({{room=1,kind="Vent",name="VENTILATION / CLEAR SMOKE"},{room=4,kind="Sprinkler",name=def.theme=="Frost" and "DEICING MIST / SUPPRESS FIRE" or def.theme=="Foundry" and "QUENCH LINE / SUPPRESS FIRE" or "SPRINKLERS / SUPPRESS FIRE"}}) do
        local cf=mount(spec.room,"Counter_"..spec.kind)
        local control=at("CounterControl_"..spec.kind,Vector3.new(2.3,2.8,.55),cf,Color3.fromRGB(57,77,76),Enum.Material.Metal,false)
        frontLabel(control,spec.name.."\nPOWER / 45s COOLDOWN",cf,1,9,1.8,Color3.fromRGB(186,234,225))
        local fixture=at(spec.kind=="Vent" and "ExtractionFan" or "SuppressionNozzle",Vector3.new(3,.5,1.2),cf*CFrame.new(0,5,0),Color3.fromRGB(91,104,97),Enum.Material.Metal,false)
        for k=-2,2 do at("CounterGrille",Vector3.new(2.6,.08,.12),cf*CFrame.new(0,4.72,-.5+k*.2),Color3.fromRGB(30,38,36),Enum.Material.Metal,false).Parent=fixture end
        table.insert(map.counters,{part=control,room=spec.room,kind=spec.kind,cooldownUntil=0})
    end
    -- Reserve the complete bay, display and its standing space, not only its prompt part.
    for _,bay in ipairs(map.mounts) do
        local center=bay.cf.Position*scale local inward=bay.cf.LookVector
        local extra=(bay.approach-center).Magnitude+3
        local depth=bay.depth*scale+extra local width=bay.width*scale
        local right=bay.cf.RightVector
        reserve(center+inward*(extra/2),Vector3.new(math.abs(right.X)*width+math.abs(inward.X)*depth,8*scale,
            math.abs(right.Z)*width+math.abs(inward.Z)*depth),-1,9*scale)
    end
    Routes.apply(map,P,S)
    Detail.apply(map,def,layout,P,S,light)
    VisualPass.apply(map,def,layout)
    WorldArt.apply(f,def.theme)
    WorldArt.setDressing(map,layout)
    Cinematic.exterior(map,def,layout)
    Cinematic.publishSemantics(map)
    map.model:SetAttribute("Batch1MapRevision",1)
    local started=os.clock()
    local function updateWorld()
        if Cinematic.worldStep(map,os.clock()-started) then task.delay(1,updateWorld) end
    end
    -- Only scenery changes; this loop owns no combat/round state and ends with its map.
    task.delay(1,updateWorld)
    map.model:SetAttribute("MapReady",true)
    map.model:SetAttribute("LayoutRevision",9)
    return map
end
function M.power(map)
    for _,p in ipairs(map.model:GetDescendants()) do
        if p:IsA("PointLight") or p:IsA("SurfaceLight") or p:IsA("SpotLight") then p.Brightness=p:GetAttribute("PoweredBrightness") or 1.6 end
    end
    map.lever.CFrame=map.lever.CFrame*CFrame.Angles(.7,0,0)
    local gui=map.power:FindFirstChild("Sign")
    if gui then gui.SurfaceGui.TextLabel.Text="MAIN POWER / ONLINE" end
end
function M.environment(id)
    local def=C.Maps[id] or C.Maps.Station
    local presets={
        Station={clock=3.4,brightness=2.0,ambient={42,48,45},outside={86,99,102},start=135,finish=600,density=.14},
        Foundry={clock=4.1,brightness=2.1,ambient={54,44,36},outside={118,104,87},start=170,finish=650,density=.13},
        Frost={clock=6.2,brightness=2.2,ambient={53,65,78},outside={143,162,174},start=120,finish=560,density=.17},
    }
    local look=presets[id] or (id~="Lobby" and presets.Station or nil)
    Lighting.ClockTime=id=="Lobby" and 5.7 or look.clock Lighting.Brightness=id=="Lobby" and 2.1 or look.brightness
    Lighting.Ambient=id=="Lobby" and Color3.fromRGB(29,33,38) or U.color(look.ambient)
    Lighting.OutdoorAmbient=id=="Lobby" and Color3.fromRGB(81,91,103) or U.color(look.outside)
    Lighting.EnvironmentDiffuseScale=.85 Lighting.EnvironmentSpecularScale=1 Lighting.ShadowSoftness=.28
    pcall(function() Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
    Lighting.FogColor=U.color(def.sky) Lighting.FogStart=look and look.start or 120 Lighting.FogEnd=look and look.finish or 420
    Lighting.GlobalShadows=true Lighting.ExposureCompensation=.05
    for _,name in ipairs({"DeadSignalAtmosphere","DeadSignalGrade","DeadSignalBloom"}) do local old=Lighting:FindFirstChild(name) if old then old:Destroy() end end
    U.make("Atmosphere",Lighting,{Name="DeadSignalAtmosphere",Density=id=="Lobby" and .08 or look.density,Offset=.12,Color=U.color(def.sky),Decay=U.color(def.wall),Glare=.05,Haze=.65})
    U.make("ColorCorrectionEffect",Lighting,{Name="DeadSignalGrade",Brightness=.015,Contrast=.12,Saturation=-.10,TintColor=def.theme=="Foundry" and Color3.fromRGB(255,242,222) or Color3.fromRGB(239,245,251)})
    U.make("BloomEffect",Lighting,{Name="DeadSignalBloom",Intensity=.065,Size=16,Threshold=2.2})
end
function M.helicopter(map)
    local m=U.make("Model",map.model,{Name="Rescue"})
    local cf=CFrame.new(map.exfilCenter+Vector3.new(0,28,0))
    local body=part(m,"Fuselage",Vector3.new(7,6,16),cf,Color3.fromRGB(44,55,48),Enum.Material.Metal,false)
    U.make("SpecialMesh",body,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)})
    m.PrimaryPart=body
    local glass=part(m,"Cockpit",Vector3.new(6,3.8,6),cf*CFrame.new(0,.6,-5.2),Color3.fromRGB(77,100,104),Enum.Material.Glass,false)
    U.make("SpecialMesh",glass,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) glass.Transparency=.18
    local tail=part(m,"Tail",Vector3.new(2,2,16),cf*CFrame.new(0,1,11),body.Color,Enum.Material.Metal,false)
    U.make("SpecialMesh",tail,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)})
    part(m,"TailFin",Vector3.new(.3,5,3.1),cf*CFrame.new(0,3.4,17.6),body.Color,Enum.Material.Metal,false,"WedgePart")
    part(m,"TailPlane",Vector3.new(8,.16,1.3),cf*CFrame.new(0,1.4,16.3),body.Color,Enum.Material.Metal,false)
    local mast=part(m,"RotorMast",Vector3.new(2.7,.48,.48),cf*CFrame.new(0,3.6,0)*CFrame.Angles(0,0,math.pi/2),body.Color,Enum.Material.Metal,false) mast.Shape=Enum.PartType.Cylinder
    for j=0,3 do
        part(m,"Rotor",Vector3.new(16.2,.12,1.1),cf*CFrame.new(0,4.8,0)*CFrame.Angles(0,j*math.pi/2,0)*CFrame.new(8.4,0,0),Color3.fromRGB(27,32,28),Enum.Material.Metal,false)
    end
    local tailRotor=part(m,"TailRotor",Vector3.new(.12,5.3,.25),cf*CFrame.new(1.25,2.6,17.2),body.Color,Enum.Material.Metal,false)
    part(m,"TailRotor",Vector3.new(.12,.25,5.3),tailRotor.CFrame,body.Color,Enum.Material.Metal,false)
    for _,x in ipairs({-3.25,3.25}) do
        part(m,"SlidingDoor",Vector3.new(.12,3.2,5),cf*CFrame.new(x,-.1,.3),body.Color,Enum.Material.Metal,false)
        local window=part(m,"CabinWindow",Vector3.new(.14,1.25,2.3),cf*CFrame.new(x,.8,.2),Color3.fromRGB(70,95,99),Enum.Material.Glass,false) window.Transparency=.15
        part(m,"DoorHandle",Vector3.new(.2,.12,.7),cf*CFrame.new(x,-.5,-1.1),Color3.fromRGB(115,126,114),Enum.Material.Metal,false)
        for _,z in ipairs({-3,3.5}) do part(m,"SkidBrace",Vector3.new(.20,2.1,.2),cf*CFrame.new(x,-3.2,z)*CFrame.Angles(0,0,x>0 and -.3 or .3),body.Color,Enum.Material.Metal,false) end
    end
    for _,x in ipairs({-4,4}) do part(m,"Skid",Vector3.new(.4,.4,15),cf*CFrame.new(x,-4,0),body.Color,Enum.Material.Metal,false) end
    return m
end
function M.preview(id)
    M.lobby() M.environment(id or "Station") return M.build(id or "Station").model
end
return M
