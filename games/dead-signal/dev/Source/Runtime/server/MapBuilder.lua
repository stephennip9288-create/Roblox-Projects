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
    local gui=U.make("SurfaceGui",p,{Face=Enum.NormalId.Front,PixelsPerStud=48,LightInfluence=0.35,MaxDistance=65,AlwaysOnTop=false})
    local label=U.make("TextLabel",gui,{Size=UDim2.fromScale(.92,.82),Position=UDim2.fromScale(.04,.09),BackgroundTransparency=1,Text=text,
        TextColor3=color or Color3.fromRGB(221,223,212),Font=Enum.Font.Gotham,TextScaled=true,TextWrapped=true})
    U.make("UITextSizeConstraint",label,{MinTextSize=8,MaxTextSize=30})
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
    local function fit(pos,margin)
        for _,r in ipairs(layout) do
            if math.abs(pos.X-r.x)<=r.w/2+.01 and math.abs(pos.Z-r.z)<=r.d/2+.01 then
                local x,z=Layouts.inset(r,pos.X,pos.Z,margin or 6) return Vector3.new(x,pos.Y,z)
            end
        end return pos
    end
    local function S(text,pos,size,angle,col)
        return sign(f,text,CFrame.new(pos*scale)*CFrame.Angles(0,angle or 0,0),size*scale,col or U.color(def.accent))
    end
    P("ExteriorGround",Vector3.new(680,3,620),Vector3.new(10,-2.5,42),def.theme=="Frost" and Color3.fromRGB(176,188,182) or Color3.fromRGB(54,61,42),def.theme=="Frost" and Enum.Material.Snow or Enum.Material.Ground,true)
    Architecture.build(map,layout,P,S,light,def)
    local perkRooms={1,3,4,2,5,6}
    for j,key in ipairs(C.PerkOrder) do
        local r=layout[perkRooms[j]] local pos=fit(Vector3.new(r.x+r.w/2-6,0,r.z-r.d/2+4),7)
        local body,model=Vending.build(f,key,CFrame.new(pos*scale)*CFrame.Angles(0,math.pi,0),scale)
        map.perks[key]={part=body,model=model,room=perkRooms[j]}
    end
    for i,weapon in ipairs(loadouts[id] or loadouts.Station) do
        local r=layout[i] local west=i==3
        local x=i==1 and r.x+r.w/2-19 or r.x-r.w/2+(i==6 and 6.5 or 9.5)
        local pos=west and Vector3.new(r.x-r.w/2+1.1,5,r.z-r.d/2+9) or Vector3.new(x,5,r.z-r.d/2+1.1)
        pos=fit(pos,7)
        local yaw=west and -math.pi/2 or math.pi local rot=CFrame.Angles(0,yaw,0)
        local facing=west and Vector3.new(1,0,0) or Vector3.new(0,0,1)
        local plaque=P("WallBuy_"..weapon,Vector3.new(11.5,3.6,.12),pos,Color3.fromRGB(46,47,39),Enum.Material.Slate,false,rot)
        for _,dy in ipairs({-1.7,1.7}) do P("ChalkFrame",Vector3.new(11.3,.045,.025),pos+Vector3.new(0,dy,0)+facing*.1,Color3.fromRGB(199,195,169),Enum.Material.SmoothPlastic,false,rot).Parent=plaque end
        local gun=W.build(weapon,"Factory",0,plaque,false) gun:PivotTo(plaque.CFrame*CFrame.Angles(0,math.pi/2,0))
        S(C.Weapons[weapon].name.." / "..C.Weapons[weapon].cost.." POINTS",pos+Vector3.new(0,-2.6,0)+facing*.15,Vector3.new(13,1.15,.12),yaw,Color3.fromRGB(211,205,176)).Parent=plaque
        map.wallBuys[i]={part=plaque,id=weapon,room=i}
        local boxPos=fit(Vector3.new(r.x-r.w/2+10,1.5/scale,r.z+r.d/2-10),7)
        table.insert(map.boxSpots,{room=i,cf=CFrame.new(boxPos*scale)})
    end
    local entry=layout[1]
    local ammoPos=fit(Vector3.new(entry.x+entry.w/2-9,1,entry.z+entry.d/2-6),7)
    local ammo=P("StarterAmmunition",Vector3.new(3.4,2,2.1),ammoPos,Color3.fromRGB(75,79,51),Enum.Material.CorrodedMetal,true)
    S("KESTREL AMMUNITION\n225 POINT REFILL",ammoPos+Vector3.new(0,2,0),Vector3.new(9,1.8,.12),0,Color3.fromRGB(197,183,139)).Parent=ammo
    table.insert(map.wallBuys,{part=ammo,id="Kestrel",room=1})
    local r=layout[3] local powerPos=fit(Vector3.new(r.x+r.w/2-8,2.5,r.z+r.d/2-8),9)
    map.power=P("PowerSwitch",Vector3.new(4,5,1.8),powerPos,Color3.fromRGB(49,58,49),Enum.Material.CorrodedMetal,true)
    S("MAIN BREAKER / OFF",powerPos+Vector3.new(0,3.7,-1.1),Vector3.new(10,1.6,.12),0,Color3.fromRGB(218,181,88)).Parent=map.power
    map.lever=P("BreakerLever",Vector3.new(.4,1.7,.4),powerPos+Vector3.new(0,.3,-1.2),Color3.fromRGB(171,56,39),Enum.Material.Metal,false) map.lever.Parent=map.power
    for j,roomId in ipairs({1,4,6}) do
        local room=layout[roomId] local pos=fit(Vector3.new(room.x-room.w/2+13,1.65,room.z-room.d/2+12),7)
        local fuse=P("Fuse_"..j,Vector3.new(.7,1.8,.7),pos,Color3.fromRGB(95,212,210),Enum.Material.Neon,false)
        U.make("PointLight",fuse,{Color=Color3.fromRGB(85,205,219),Brightness=.6,Range=11,Shadows=false})
        map.fuses[j]={part=fuse,room=roomId,collected=false}
    end
    r=layout[5] local relayPos=fit(Vector3.new(r.x,2.7,r.z-r.d/2+8),9)
    map.relay=P("Transmitter",Vector3.new(10,5.4,3),relayPos,Color3.fromRGB(47,56,47),Enum.Material.Metal,true)
    for n=1,5 do
        local screen=P("RelayInstrument",Vector3.new(1.4,1.3,.08),relayPos+Vector3.new(-4+n*1.4,1,-1.54),Color3.fromRGB(158,169,116),Enum.Material.Neon,false) screen.Parent=map.relay
        local dial=P("InstrumentDial",Vector3.new(.5,.5,.08),relayPos+Vector3.new(-4+n*1.4,-.4,-1.6),Color3.fromRGB(141,141,123),Enum.Material.Metal,false) dial.Shape=Enum.PartType.Cylinder dial.Parent=map.relay
    end
    S("TRANSMITTER / THREE FUSES REQUIRED",relayPos+Vector3.new(0,4,-1.6),Vector3.new(16,1.7,.12),0).Parent=map.relay
    for j,roomId in ipairs({2,4,6}) do
        r=layout[roomId] local pos=fit(Vector3.new(r.x-r.w/2+6,1.6,r.z),7)
        local panel=P("FrequencyPanel"..j,Vector3.new(3.5,3.2,1.4),pos,Color3.fromRGB(66,71,57),Enum.Material.CorrodedMetal,true)
        local screen=S("FREQUENCY "..j.."\n1",pos+Vector3.new(0,3,-.8),Vector3.new(5.8,2,.12),0,Color3.fromRGB(172,196,132))
        screen.Parent=panel map.panels[j]={part=panel,screen=screen,value=1,room=roomId}
    end
    r=layout[6] local forgePos=fit(Vector3.new(r.x,3.5,r.z-r.d/2+8),9)
    map.upgrade=P("UpgradeMachine",Vector3.new(9,7,6),forgePos,Color3.fromRGB(47,64,62),Enum.Material.Metal,true)
    for _,dx in ipairs({-3.1,3.1}) do
        local col=P("ForgeCondenser",Vector3.new(6.2,1.7,1.7),forgePos+Vector3.new(dx,.1,-3.5),Color3.fromRGB(104,127,123),Enum.Material.Metal,false,CFrame.Angles(0,0,math.pi/2)) col.Shape=Enum.PartType.Cylinder col.Parent=map.upgrade
        for n=1,7 do P("ForgeRing",Vector3.new(2,.13,2),forgePos+Vector3.new(dx,-2.7+n*.8,-3.5),Color3.fromRGB(80,191,201),Enum.Material.Neon,false).Parent=map.upgrade end
    end
    local glass=P("ForgeInspection",Vector3.new(4.8,3,.15),forgePos+Vector3.new(0,.4,-3.12),Color3.fromRGB(77,145,145),Enum.Material.Glass,false) glass.Transparency=.35 glass.Parent=map.upgrade
    S("RESONANCE FORGE\n5000 / 7500 POINTS",forgePos+Vector3.new(0,5,-3.6),Vector3.new(13,2.3,.12),0,Color3.fromRGB(113,217,217)).Parent=map.upgrade
    r=layout[2] local radioPos=fit(Vector3.new(r.x+r.w/2-13,1.65,r.z+r.d/2-10),9)
    map.radio=P("ExtractionRadio",Vector3.new(5,3.3,3),radioPos,Color3.fromRGB(66,74,54),Enum.Material.Metal,true)
    for n=1,4 do P("RadioGrille",Vector3.new(3.7,.06,.08),radioPos+Vector3.new(0,-.7+n*.3,-1.56),Color3.fromRGB(24,30,24),Enum.Material.Metal,false).Parent=map.radio end
    P("RadioAntenna",Vector3.new(.12,5,.12),radioPos+Vector3.new(1.6,3,0),Color3.fromRGB(155,158,143),Enum.Material.Metal,false).Parent=map.radio
    S("RESCUE CHANNEL\nSIGNAL + ROUND 15",radioPos+Vector3.new(0,3.5,-1.6),Vector3.new(12,2.5,.12),0).Parent=map.radio
    map.exfilCenter=Vector3.new(r.x,0,r.z)*scale
    for n=1,16 do local a=n*math.pi/8
        P("ExtractionMarker",Vector3.new(1.2,.04,.35),Vector3.new(r.x+math.cos(a)*15,.055,r.z+math.sin(a)*15),Color3.fromRGB(195,174,96),Enum.Material.Metal,false,CFrame.Angles(0,-a,0))
    end
    for _,roomId in ipairs({3,4}) do
        r=layout[roomId] local pos=fit(Vector3.new(r.x-r.w/2+6,1.5,r.z-r.d*.22),7)
        local controller=P("TrapControl",Vector3.new(2.3,3,1.3),pos,Color3.fromRGB(141,135,85),Enum.Material.CorrodedMetal,true)
        local center=Vector3.new(r.x,0,r.z)*scale
        for _,dx in ipairs({-9,9}) do P("TrapEmitter",Vector3.new(.8,7,.8),Vector3.new(r.x+dx,3.5,r.z),Color3.fromRGB(71,81,78),Enum.Material.Metal,true) end
        local beam=P("TrapField",Vector3.new(17,6,.3),Vector3.new(r.x,3,r.z),Color3.fromRGB(78,208,235),Enum.Material.Neon,false) beam.Transparency=1
        map.traps[#map.traps+1]={part=controller,center=center,beam=beam,activeUntil=0,cooldownUntil=0,room=roomId}
    end
    map.spawnPoints={}
    for _,v in ipairs({Vector3.new(-6,4,-3),Vector3.new(6,4,-3),Vector3.new(-6,4,7),Vector3.new(6,4,7)}) do
        table.insert(map.spawnPoints,(Vector3.new(entry.x,0,entry.z)+v)*scale)
    end
    NavGraph.build(map)
    -- Furniture is authored around objective volumes and their standing approaches.
    map.interactionZones={}
    local function reserve(pos,size,minY,maxY)
        table.insert(map.interactionZones,{minX=pos.X-size.X/2-3*scale,maxX=pos.X+size.X/2+3*scale,
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
    for _,room in ipairs(map.rooms) do if room.stairBase then
        reserve((room.stairBase+room.stairTop)*.5,Vector3.new(9,room.rise/scale+6,36)*scale,-1,room.rise+5*scale)
    end end
    -- Reserve counter panels before set dressing; candidates avoid every objective,
    -- portal, vault, spawn and stair approach. Panels have no movement collision.
    map.counters={}
    for _,spec in ipairs({{room=1,kind="Vent",name="VENTILATION / CLEAR SMOKE"},{room=4,kind="Sprinkler",name=def.theme=="Frost" and "DEICING MIST / SUPPRESS FIRE" or def.theme=="Foundry" and "QUENCH LINE / SUPPRESS FIRE" or "SPRINKLERS / SUPPRESS FIRE"}}) do
        local room=layout[spec.room] local chosen
        for n=1,128 do
            local radius=.43-math.floor((n-1)/32)*.09
            local a=n*math.pi/16 local x,z=Layouts.inset(room,room.x+math.cos(a)*room.w*radius,room.z+math.sin(a)*room.d*radius,5)
            local at=Vector3.new(x,3,z)*scale local free=true
            for _,zone in ipairs(map.interactionZones) do
                if at.X>zone.minX-3*scale and at.X<zone.maxX+3*scale and at.Z>zone.minZ-3*scale and at.Z<zone.maxZ+3*scale then free=false break end
            end
            if free then chosen=Vector3.new(x,3,z) break end
        end
        if chosen then
            local control=P("CounterControl_"..spec.kind,Vector3.new(2.3,2.8,.55),chosen,Color3.fromRGB(57,77,76),Enum.Material.Metal,false)
            P("CounterPedestal",Vector3.new(.34,1.8,.34),Vector3.new(chosen.X,.9,chosen.Z),Color3.fromRGB(66,74,72),Enum.Material.Metal,false).Parent=control
            P("CounterFoot",Vector3.new(1.8,.12,1.3),Vector3.new(chosen.X,.08,chosen.Z),Color3.fromRGB(49,57,55),Enum.Material.Metal,false).Parent=control
            local label=S(spec.name.."\nPOWER REQUIRED / 45s COOLDOWN",chosen+Vector3.new(0,2.5,-.2),Vector3.new(7,1.7,.1),0,Color3.fromRGB(151,209,204));label.Parent=control
            local fixture=P(spec.kind=="Vent" and "ExtractionFan" or "SuppressionNozzle",Vector3.new(3,.5,3),chosen+Vector3.new(0,5,0),Color3.fromRGB(91,104,97),Enum.Material.Metal,false)
            for k=-2,2 do P("CounterGrille",Vector3.new(2.6,.08,.12),chosen+Vector3.new(0,4.72,k*.36),Color3.fromRGB(30,38,36),Enum.Material.Metal,false).Parent=fixture end
            table.insert(map.counters,{part=control,room=spec.room,kind=spec.kind,cooldownUntil=0}) reserve(chosen*scale,Vector3.new(8,7,8)*scale)
        end
    end
    Routes.apply(map,P,S)
    Detail.apply(map,def,layout,P,S,light)
    VisualPass.apply(map,def,layout)
    WorldArt.apply(f,def.theme)
    WorldArt.setDressing(map,layout)
    map.model:SetAttribute("MapReady",true)
    map.model:SetAttribute("LayoutRevision",8)
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
    Lighting.ClockTime=id=="Lobby" and 5.7 or 3.4 Lighting.Brightness=id=="Lobby" and 2.1 or 1.85
    Lighting.Ambient=Color3.fromRGB(29,33,38) Lighting.OutdoorAmbient=Color3.fromRGB(81,91,103)
    Lighting.EnvironmentDiffuseScale=.85 Lighting.EnvironmentSpecularScale=1 Lighting.ShadowSoftness=.23
    -- Studio/Command Bar can set the protected style; runtime keeps the saved style.
    pcall(function() Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
    Lighting.FogColor=U.color(def.sky) Lighting.FogStart=120 Lighting.FogEnd=420
    Lighting.GlobalShadows=true Lighting.ExposureCompensation=.05
    for _,name in ipairs({"DeadSignalAtmosphere","DeadSignalGrade","DeadSignalBloom"}) do local old=Lighting:FindFirstChild(name) if old then old:Destroy() end end
    U.make("Atmosphere",Lighting,{Name="DeadSignalAtmosphere",Density=id=="Lobby" and .08 or def.theme=="Frost" and .25 or .18,Offset=.12,Color=U.color(def.sky),Decay=U.color(def.wall),Glare=.05,Haze=.85})
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
