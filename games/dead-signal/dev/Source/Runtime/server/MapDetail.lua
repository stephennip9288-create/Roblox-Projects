-- Original, authored room furnishings. All dimensions are in unscaled layout studs.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Layouts=require(RS.DeadSignal.MapLayouts)
local Detail={}
function Detail.apply(map,def,layout,P,S,light)
    local steel=Color3.fromRGB(59,66,62) local dark=Color3.fromRGB(31,35,32)
    local cream=Color3.fromRGB(188,178,143) local wood=Color3.fromRGB(103,77,48)
    local accent=U.color(def.accent) local rust=Color3.fromRGB(110,69,44)
    local function free(i,x,z,w,d,y,h)
        local r=layout[i] local s=map.scale
        local minX=(r.x+x-w/2)*s local maxX=(r.x+x+w/2)*s local minZ=(r.z+z-d/2)*s local maxZ=(r.z+z+d/2)*s
        for _,dx in ipairs({-w/2,w/2}) do for _,dz in ipairs({-d/2,d/2}) do
            if not Layouts.contains(r,r.x+x+dx,r.z+z+dz,1.6) then return false end
        end end
        for _,zones in ipairs({map.interactionZones or {},map.detailZones or {}}) do for _,zone in ipairs(zones) do
            if (y or 0)*s<zone.maxY and ((y or 0)+(h or 8))*s>zone.minY and minX<zone.maxX and maxX>zone.minX and minZ<zone.maxZ and maxZ>zone.minZ then return false end
        end end return true
    end
    local function part(i,name,size,at,col,mat,solid,rot)
        local r=layout[i] local p=P(name,size,Vector3.new(r.x,0,r.z)+at,col or steel,mat or Enum.Material.Metal,solid==true,rot)
        if not Layouts.contains(r,r.x+at.X,r.z+at.Z,1) or solid and not free(i,at.X,at.Z,size.X,size.Z,at.Y-size.Y/2,size.Y) then p.Parent=nil return p end
        p:SetAttribute("DeadSignalFurnishing",true)
        p.Parent=map.rooms[i].model if not solid then p.CanQuery=false end return p
    end
    local function label(i,text,at,size,yaw,col)
        local r=layout[i] local p=S(text,Vector3.new(r.x,0,r.z)+at,size,yaw or 0,col or cream) p.Parent=map.rooms[i].model return p
    end
    local function cylinder(i,name,length,diameter,at,col,axis,solid)
        local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.new()
        local p=part(i,name,Vector3.new(length,diameter,diameter),at,col,nil,solid,rot) p.Shape=Enum.PartType.Cylinder return p
    end
    local function crate(i,x,z,y)
        y=y or 0
        if not free(i,x,z,4.9,4.2,y,3.5) then return end
        part(i,"ShippingCrate",Vector3.new(4.5,3.2,3.8),Vector3.new(x,y+1.6,z),wood,Enum.Material.WoodPlanks,true)
        for _,dx in ipairs({-1.6,1.6}) do
            for _,dz in ipairs({-1.95,1.95}) do part(i,"CrateBatten",Vector3.new(.36,3.4,.16),Vector3.new(x+dx,y+1.6,z+dz),cream,Enum.Material.Wood,false) end
            part(i,"CrateTopBatten",Vector3.new(.36,.16,4),Vector3.new(x+dx,y+3.3,z),cream,Enum.Material.Wood,false)
        end
        label(i,"D.S. / FIELD SUPPLY",Vector3.new(x,y+1.9,z-1.99),Vector3.new(3.5,.8,.03),math.pi,cream)
    end
    local function tableTop(i,x,z,y,w)
        y=y or 0 w=w or 10
        if not free(i,x,z,w+1,4.5,y,5) then return end
        part(i,"WornDeskTop",Vector3.new(w,.35,4.1),Vector3.new(x,y+3,z),wood,Enum.Material.WoodPlanks,true)
        for _,dx in ipairs({-w/2+.5,w/2-.5}) do for _,dz in ipairs({-1.5,1.5}) do part(i,"DeskLeg",Vector3.new(.25,2.8,.25),Vector3.new(x+dx,y+1.4,z+dz),steel,nil,true) end end
        part(i,"DeskBrace",Vector3.new(w-1,.2,.2),Vector3.new(x,y+.7,z+1.5),steel)
        for n=1,3 do part(i,"PaperRecord",Vector3.new(1.6,.025,1.1),Vector3.new(x-2+n*.7,y+3.2,z-.2+n*.28),cream,Enum.Material.SmoothPlastic,false,CFrame.Angles(0,n*.23,0)) end
        cylinder(i,"EnamelMug",.48,.38,Vector3.new(x+w/2-1,y+3.45,z-.5),cream,"Y",false)
    end
    local function radio(i,x,z,y)
        if not free(i,x,z,4,2.5,math.max(0,y-3.2),6) then return end
        if y>0 then
            -- A wide desk may be omitted by an objective reservation. Its radio
            -- must be omitted with it rather than floating in the approach.
            local r=layout[i] local s=map.scale local at=Vector3.new(r.x+x,y,r.z+z)*s local supported=false
            for _,q in ipairs(map.rooms[i].model:GetChildren()) do if q:IsA("BasePart") and q.Name=="WornDeskTop" then
                local localAt=q.CFrame:PointToObjectSpace(at)
                if math.abs(localAt.X)<q.Size.X/2 and math.abs(localAt.Z)<q.Size.Z/2 and math.abs(localAt.Y-q.Size.Y/2)<.2*s then supported=true break end
            end end
            if not supported then return end
        end
        part(i,"RadioCabinet",Vector3.new(3.6,2.3,1.8),Vector3.new(x,y+1.15,z),Color3.fromRGB(64,79,61),nil,true)
        part(i,"FrequencyGlass",Vector3.new(2.4,.55,.06),Vector3.new(x,y+1.65,z+.94),cream,Enum.Material.Glass)
        for n=1,12 do part(i,"DialTick",Vector3.new(.035,.12,.025),Vector3.new(x-1.14+n*.18,y+1.72,z+.98),dark) end
        for _,dx in ipairs({-.9,.9}) do cylinder(i,"TuningDial",.17,.42,Vector3.new(x+dx,y+.55,z+1),dark,"Z",false) end
        for n=1,7 do part(i,"SpeakerSlot",Vector3.new(.035,.6,.025),Vector3.new(x-1.6+n*.13,y+.65,z+.95),dark) end
        label(i,"EMERGENCY BAND",Vector3.new(x,y+2.08,z+.96),Vector3.new(2.2,.28,.025),math.pi,cream)
    end
    local function sandbags(i,x,z,y)
        y=y or 0
        if not free(i,x,z,12.5,3,y,3) then return end
        for row=0,2 do for n=-2,2 do
            local at=Vector3.new(x+n*2.25+(row%2)*.65,y+.45+row*.7,z+(row%2)*.2)
            local bag=part(i,"CanvasSandbag",Vector3.new(2.3,.8,1.8),at,Color3.fromRGB(137+row*5,129+row*4,94),Enum.Material.Fabric,true,CFrame.Angles(0,.04*n,0))
            part(i,"SandbagSeam",Vector3.new(2.1,.035,.06),at+Vector3.new(0,.39,0),wood,Enum.Material.Fabric)
        end end
    end
    local function lockers(i,x,z,y,count)
        y=y or 0 count=count or 3
        if not free(i,x,z,count*2.5,2.5,y,6.5) then return end
        for n=1,count do local xx=x+(n-(count+1)/2)*2.5
            part(i,"Locker",Vector3.new(2.35,6.3,2),Vector3.new(xx,y+3.15,z),Color3.fromRGB(69+n*3,76+n*2,63),nil,true)
            part(i,"LockerDoor",Vector3.new(2.14,6,.07),Vector3.new(xx,y+3.16,z+1.05),steel)
            for k=1,4 do part(i,"LockerVent",Vector3.new(1.25,.06,.025),Vector3.new(xx,y+5.15+k*.17,z+1.1),dark) end
            part(i,"LockerHandle",Vector3.new(.1,.48,.1),Vector3.new(xx+.75,y+3,z+1.12),cream)
            label(i,string.format("%02d",n+i*3),Vector3.new(xx,y+4.1,z+1.11),Vector3.new(.6,.4,.03),math.pi,cream)
        end
    end
    local function bench(i,x,z,y)
        y=y or 0
        if not free(i,x,z,10.5,3,y,4) then return end
        for n=1,4 do part(i,"BenchSlat",Vector3.new(10,.22,.48),Vector3.new(x,y+1.9,z-1.1+n*.5),wood,Enum.Material.WoodPlanks,true) end
        for n=1,3 do part(i,"BenchBackSlat",Vector3.new(10,.42,.22),Vector3.new(x,y+2.25+n*.48,z+1),wood,Enum.Material.WoodPlanks,true) end
        for _,dx in ipairs({-4,4}) do part(i,"BenchFrame",Vector3.new(.3,1.8,2.4),Vector3.new(x+dx,y+.9,z),steel,nil,true) end
    end
    local function rack(i,x,z,y)
        y=y or 0
        if not free(i,x,z,10,3.5,y,8) then return end
        for _,dx in ipairs({-4.5,4.5}) do part(i,"RackUpright",Vector3.new(.25,7,.25),Vector3.new(x+dx,y+3.5,z),steel,nil,true) end
        for level=1,3 do
            part(i,"RackShelf",Vector3.new(9.3,.2,3),Vector3.new(x,y+level*2,z),steel,nil,true)
            for n=-1,1 do part(i,"SupplyTin",Vector3.new(2.2,1.5,2.2),Vector3.new(x+n*2.8,y+level*2+.85,z),Color3.fromRGB(113,119,94),nil,true)
                part(i,"TinStrap",Vector3.new(.16,1.6,2.25),Vector3.new(x+n*2.8,y+level*2+.85,z),dark) end
        end
    end
    local function console(i,x,z,y,text)
        if not free(i,x,z,12,5,y,7) then return end
        tableTop(i,x,z,y,11)
        local facing=z<0 and -1 or 1
        for dx=-3.5,3.5,3.5 do
            part(i,"InstrumentHousing",Vector3.new(2.5,2,1.5),Vector3.new(x+dx,y+4.1,z+facing*.6),steel,nil,true)
            part(i,"InstrumentScreen",Vector3.new(2.1,1.35,.08),Vector3.new(x+dx,y+4.25,z-facing*.19),Color3.fromRGB(69,104,75),Enum.Material.Neon).Transparency=.35
            for n=1,3 do part(i,"ScopeTrace",Vector3.new(.55,.03,.02),Vector3.new(x+dx-.8+n*.42,y+4.15+math.sin(n)*.3,z-facing*.24),Color3.fromRGB(153,175,102),Enum.Material.Neon) end
            cylinder(i,"ControlKnob",.14,.18,Vector3.new(x+dx+.8,y+3.45,z-facing*.3),dark,"Z",false)
        end
        label(i,text,Vector3.new(x,y+6,z+.7),Vector3.new(10,1,.06),0,cream)
    end
    local function tank(i,x,z,col)
        if not free(i,x,z,6.5,6,0,10) then return end
        cylinder(i,"PressureVessel",9,5.4,Vector3.new(x,5.2,z),col or rust,"Y",true)
        for _,y in ipairs({1.1,4.8,8.5}) do cylinder(i,"TankBand",.22,5.6,Vector3.new(x,y,z),steel,"Y",false) end
        for _,dx in ipairs({-1.9,1.9}) do part(i,"TankFoot",Vector3.new(.6,1.6,2),Vector3.new(x+dx,.8,z),steel,nil,true) end
        cylinder(i,"PressureGauge",.18,1.15,Vector3.new(x,6,z-2.8),cream,"Z",false)
        part(i,"GaugeNeedle",Vector3.new(.04,.4,.03),Vector3.new(x+.07,6.12,z-2.92),dark,nil,false,CFrame.Angles(0,0,-.6))
        cylinder(i,"TankOutlet",6,.65,Vector3.new(x,9.6,z+1),steel,"X",false)
        cylinder(i,"RedValve",.18,1.1,Vector3.new(x+3,9.6,z+1),rust,"X",false)
    end
    -- Small-scale wear is distributed deterministically, never as player collision.
    for i,r in ipairs(layout) do
        local z=r.d/2-1.05
        part(i,"UtilityConduit",Vector3.new(r.w-4,.22,.22),Vector3.new(0,r.h-5,z),dark)
        for _,x in ipairs({-r.w/2+2,r.w/2-2}) do
            part(i,"ConduitRiser",Vector3.new(.22,r.h-6,.22),Vector3.new(x,(r.h-6)/2,z),dark)
            for y=3,r.h-4,5 do part(i,"PipeClamp",Vector3.new(.45,.12,.4),Vector3.new(x,y,z),steel) end
        end
        for n=1,14 do
            local x=-r.w/2+3+(n*13.17)%(r.w-6) local zz=-r.d/2+3+(n*17.23)%(r.d-6)
            part(i,"FloorCrack",Vector3.new(.045,.015,1.5+n%4),Vector3.new(x,.017,zz),dark,Enum.Material.Slate,false,CFrame.Angles(0,n*.87,0))
            if n%3==0 then part(i,"PlasterChip",Vector3.new(.5+n%2,.06,.55),Vector3.new(x+1,.04,zz),cream,Enum.Material.Concrete,false,CFrame.Angles(0,n,0)) end
        end
        for n=1,4 do
            part(i,"WaterStain",Vector3.new(1.4+n*.3,2.7+n*.7,.018),Vector3.new(-r.w/2+2+n*1.4,6+n*.4,-r.d/2+.73),Color3.fromRGB(79,83,64),Enum.Material.Concrete)
        end
        local gx=r.w/2-5 local gz=-r.d/2+14
        part(i,"DrainBed",Vector3.new(2,.04,4),Vector3.new(gx,.025,gz),dark)
        for n=1,9 do part(i,"DrainGrille",Vector3.new(1.8,.04,.08),Vector3.new(gx,.05,gz-1.9+n*.38),steel) end
        if r.upper then
            local y=map.rooms[i].rise/map.scale
            tableTop(i,2,r.d/2-5,y,9) radio(i,1,r.d/2-5,y+3.2)
            crate(i,r.w/2-5,r.d/2-6,y) bench(i,14,r.d/2-7,y)
        end
    end
    if def.theme=="Station" then
        -- A ruined concrete shelter: field radio, sandbag position and dusty living quarters.
        tableTop(1,0,-layout[1].d/2+10,0,12) radio(1,-2,-layout[1].d/2+10,3.2)
        sandbags(1,14,layout[1].d/2-7)
        for _,i in ipairs({3,4,5,6}) do local r=layout[i]
            lockers(i,r.w/2-7,-r.d/2+14,0,3)
            if i==3 then tank(i,-r.w/2+6,r.d/2-14) else rack(i,r.w/2-8,r.d/2-15,0) end
        end
        console(4,0,-layout[4].d/2+12,0,"WORKSHOP / FAULT 0317")
        console(5,0,layout[5].d/2-7,0,"CARRIER ARRAY / NO RESPONSE")
        tableTop(6,0,layout[6].d/2-12,0,10)
        part(6,"SpecimenTray",Vector3.new(6,.3,2),Vector3.new(0,3.35,layout[6].d/2-12),cream,nil,true)
        for n=1,5 do cylinder(6,"SpecimenVial",.6,.35,Vector3.new(-2+n*.7,3.8,layout[6].d/2-12),accent,"Y",false) end
        local r=layout[2]
        for _,x in ipairs({-r.w/2+8,r.w/2-8}) do
            part(2,"AerialFoundation",Vector3.new(5,1,5),Vector3.new(x,.5,-r.d/2+15),cream,Enum.Material.Concrete,true)
            part(2,"LatticeMast",Vector3.new(.5,22,.5),Vector3.new(x,12,-r.d/2+15),steel,nil,true)
            for y=4,20,4 do part(2,"AerialCrossbar",Vector3.new(4,.18,.18),Vector3.new(x,y,-r.d/2+15),steel) end
            light(map.rooms[2].model,CFrame.new((Vector3.new(r.x+x,22,r.z-r.d/2+15))*map.scale),accent,false)
        end
    elseif def.theme=="Foundry" then
        tableTop(1,0,-layout[1].d/2+12,0,12) radio(1,0,-layout[1].d/2+12,3.2) lockers(1,layout[1].w/2-6,layout[1].d/2-9,0,3)
        for _,i in ipairs({3,4,6}) do local r=layout[i]
            tank(i,-r.w/2+7,r.d/2-17,rust) tank(i,r.w/2-7,-r.d/2+17,rust)
            local x=r.w/2-8 local z=r.d/2-17
            part(i,"LatheBase",Vector3.new(10,2,5),Vector3.new(x-2,1,z),steel,nil,true)
            part(i,"LatheBed",Vector3.new(10,.45,3),Vector3.new(x-2,3,z),Color3.fromRGB(74,98,75),nil,true)
            cylinder(i,"LatheChuck",1.4,2,Vector3.new(x-6,4.1,z),cream,"X",false)
            cylinder(i,"WorkStock",6,.6,Vector3.new(x-2,4.1,z),steel,"X",false)
            part(i,"Carriage",Vector3.new(2.4,.6,3.2),Vector3.new(x,3.5,z),rust,nil,true)
        end
        local r=layout[2]
        for _,x in ipairs({-r.w/2+10,r.w/2-10}) do
            cylinder(2,"CastingLadle",6,8,Vector3.new(x,4,-r.d/2+18),steel,"Y",true)
            cylinder(2,"LadleRim",.4,8.5,Vector3.new(x,7,-r.d/2+18),dark,"Y",false)
            cylinder(2,"CoolingSlag",.1,6.7,Vector3.new(x,7.1,-r.d/2+18),accent,"Y",false).Material=Enum.Material.Neon
        end
        part(2,"GantryBeam",Vector3.new(r.w-8,1.8,1.4),Vector3.new(0,23,-r.d/2+18),rust,nil,true)
        for _,x in ipairs({-r.w/2+5,r.w/2-5}) do part(2,"CraneColumn",Vector3.new(1.4,23,1.4),Vector3.new(x,11.5,-r.d/2+18),steel,nil,true) end
        part(2,"HoistBlock",Vector3.new(4,2.8,3),Vector3.new(5,20,-r.d/2+18),rust,nil,true)
        cylinder(2,"HoistCable",8,.15,Vector3.new(5,15,-r.d/2+18),dark,"Y",false)
        console(5,0,layout[5].d/2-8,0,"FURNACE MONITOR / INTERLOCK OFFLINE")
        for _,i in ipairs({4,5,6}) do local q=layout[i] crate(i,q.w/2-7,q.d/2-27) rack(i,-q.w/2+7,-q.d/2+17,0) end
    else
        tableTop(1,0,-layout[1].d/2+12,0,12) radio(1,0,-layout[1].d/2+12,3.2)
        for _,x in ipairs({-layout[1].w/2+7,layout[1].w/2-7}) do
            for _,y in ipairs({1.7,5.2}) do
                part(1,"BunkBed",Vector3.new(5,.4,10),Vector3.new(x,y,layout[1].d/2-10),steel,nil,true)
                part(1,"BunkMattress",Vector3.new(4.7,.55,9.6),Vector3.new(x,y+.5,layout[1].d/2-10),cream,Enum.Material.Fabric,true)
                part(1,"FoldedThermalBlanket",Vector3.new(4.8,.2,5),Vector3.new(x,y+.85,layout[1].d/2-8),Color3.fromRGB(100,118,108),Enum.Material.Fabric)
            end
            for _,dx in ipairs({-2.5,2.5}) do for _,dz in ipairs({-5,5}) do part(1,"BunkPost",Vector3.new(.18,6,.18),Vector3.new(x+dx,3,layout[1].d/2-10+dz),steel,nil,true) end end
        end
        for _,i in ipairs({3,4,5,6}) do local r=layout[i] rack(i,r.w/2-7,r.d/2-17,0) tank(i,-r.w/2+7,-r.d/2+17,Color3.fromRGB(90,123,130)) end
        console(5,0,layout[5].d/2-8,0,"WHITEOUT / ECHO TRACKING")
        local r=layout[2]
        for _,x in ipairs({-r.w/2+10,r.w/2-10}) do
            part(2,"DishPedestal",Vector3.new(4,7,4),Vector3.new(x,3.5,-r.d/2+17),steel,nil,true)
            for n=-3,3 do part(2,"DishPetal",Vector3.new(2.2,7,.5),Vector3.new(x+n*1.8,11+math.abs(n)*.35,-r.d/2+17),cream,nil,false,CFrame.Angles(.2,0,n*.12)) end
            cylinder(2,"DishFeed",6,.35,Vector3.new(x,11,-r.d/2+13),steel,"Z",false)
        end
        for i,q in ipairs(layout) do
            for n=1,7 do part(i,"WindblownSnow",Vector3.new(2+n*.6,.08,1.7),Vector3.new(-q.w/2+4+n*2,.06,-q.d/2+5),Color3.fromRGB(191,205,204),Enum.Material.Snow,false,CFrame.Angles(0,n*.2,0)) end
            for n=1,8 do cylinder(i,"IceDrip",.6+n%3*.4,.12,Vector3.new(-q.w/2+3+n*1.1,q.h-1.5,-q.d/2+.9),Color3.fromRGB(172,204,216),"Y",false).Material=Enum.Material.Ice end
        end
    end
    -- Small cover islands give the expanded interiors readable training routes.
    -- Door approaches stay on the central fourteen-stud axes; yard defence stays clear.
    if def.theme=="Foundry" then
        for _,i in ipairs({3,4,5,6}) do local r=layout[i] local z=-r.d*.18
            tableTop(i,0,z,0,16)
            part(i,"WorkIslandCabinet",Vector3.new(6,2.6,3.2),Vector3.new(-4,1.3,z),Color3.fromRGB(75,91,72),nil,true)
            for n=1,3 do
                part(i,"ToolDrawer",Vector3.new(5.7,.67,.08),Vector3.new(-4,.45+n*.62,z-1.66),steel)
                part(i,"DrawerPull",Vector3.new(1.1,.08,.12),Vector3.new(-4,.45+n*.62,z-1.77),cream)
                cylinder(i,"RolledSteel",5,.45,Vector3.new(3,3.5,z-.9+n*.55),steel,"X",false)
            end
            part(i,"BenchVise",Vector3.new(1.3,.8,1.3),Vector3.new(6,3.5,z-.5),rust,nil,true)
            cylinder(i,"ViseHandle",1.9,.1,Vector3.new(6,3.4,z-1.3),cream,"X",false)
            for _,x in ipairs({-6,6}) do for n=1,4 do part(i,"FadedSafetyStripe",Vector3.new(2,.025,.35),Vector3.new(x,.04,z+3+n*.65),cream,nil,false,CFrame.Angles(0,.65,0)) end end
        end
    elseif def.theme=="Frost" then
        for _,i in ipairs({4,5,6}) do local r=layout[i] local z=-r.d*.18
            for _,x in ipairs({-r.w*.2,r.w*.2}) do
                part(i,"SupplyPallet",Vector3.new(5.5,.32,5.2),Vector3.new(x,.16,z),wood,Enum.Material.WoodPlanks,true)
                crate(i,x,z,.4) crate(i,x,z,3.65)
                part(i,"LooseThermalCanvas",Vector3.new(5.2,.14,4.8),Vector3.new(x,7,z),Color3.fromRGB(102,129,128),Enum.Material.Fabric)
            end
        end
    else
        local r=layout[1] lockers(1,-r.w/2+5,-r.d/2+13,0,3)
        for _,i in ipairs({3,4,5,6}) do local q=layout[i] local x=q.w/2-8 local z=-q.d*.15
            part(i,"FieldFootlocker",Vector3.new(6,2.5,3),Vector3.new(x,1.25,z),Color3.fromRGB(91,102,73),nil,true)
            for _,dx in ipairs({-2,2}) do part(i,"FootlockerStrap",Vector3.new(.18,2.6,3.08),Vector3.new(x+dx,1.25,z),steel) end
            part(i,"CanvasBedroll",Vector3.new(4.5,.75,2.7),Vector3.new(x,2.9,z),Color3.fromRGB(132,126,89),Enum.Material.Fabric,true)
        end
    end
    -- Each sector gets one functional, wall-backed outbreak trace, not a random center prop.
    map.facilityDisplays={}
    local traces={Station={"TRIAGE / UNCLAIMED","03:17 / CARRIER LOST","DIESEL / HOLD LOAD","REPAIR / SHIFT ABANDONED","WATCH / NO REPLY","SIGNAL / QUARANTINE"},
        Foundry={"SHIFT 09 / NO RETURN","FREIGHT / EVACUATED","PRESSURE / ISOLATED","TOOLS / DO NOT RESTART","HEAT / INTERLOCK LOST","SAMPLE / CONTAMINATED"},
        Frost={"ARRIVALS / DEICE FIRST","RESCUE / MISSED CHECK-IN","THERMAL / HOLD OUTPUT","RATIONS / LAST INVENTORY","ECHO / REPLY BELOW ICE","CRYO / DO NOT THAW"}}
    for i,r in ipairs(layout) do
        local chosen
        for _,face in ipairs(map.rooms[i].wallFaces) do
            local limit=face.length/2-5.5
            for offset=-limit,limit,4 do
                local center=face.center+face.tangent*offset-face.normal*1.9 local valid=true
                for _,x in ipairs({-4.2,4.2}) do for _,z in ipairs({-1,1}) do
                    local q=center+face.tangent*x+face.normal*z
                    if not Layouts.contains(r,q.X,q.Z,.75) then valid=false end
                end end
                local ex=math.abs(face.tangent.X)*4.2+math.abs(face.normal.X)
                local ez=math.abs(face.tangent.Z)*4.2+math.abs(face.normal.Z)
                local loX,hiX=(center.X-ex)*map.scale,(center.X+ex)*map.scale
                local loZ,hiZ=(center.Z-ez)*map.scale,(center.Z+ez)*map.scale
                for _,zone in ipairs(map.interactionZones) do
                    if zone.minY<8*map.scale and zone.maxY>0 and loX<zone.maxX and hiX>zone.minX and loZ<zone.maxZ and hiZ>zone.minZ then valid=false break end
                end
                if valid then chosen={at=center,face=face} break end
            end
            if chosen then break end
        end
        if chosen then
            local face=chosen.face local cf=CFrame.fromMatrix(chosen.at,face.tangent,Vector3.yAxis,face.normal)
            local paint=def.theme=="Station" and Color3.fromRGB(92,112,82) or def.theme=="Foundry" and Color3.fromRGB(118,91,59) or Color3.fromRGB(130,157,164)
            local function q(name,size,offset,col,mat,solid,rot)
                local at=cf*CFrame.new(offset) local obj=P(name,size,at.Position,col or paint,mat or Enum.Material.Metal,solid==true,(at-at.Position)*(rot or CFrame.identity))
                obj.Parent=map.rooms[i].model obj:SetAttribute("FacilityDetail",true) return obj
            end
            local body=q("FacilityInstrumentCabinet",Vector3.new(8.2,6,1.9),Vector3.new(0,3,0),paint,nil,true)
            body:SetAttribute("FacilityFunction",r.purpose) body:SetAttribute("LoreTrace",traces[map.id][i])
            for row=1,3 do
                q("FacilityDrawer",Vector3.new(7.4,.9,.12),Vector3.new(0,.6+row*1.1,-1.03),steel)
                q("RecessedDrawerPull",Vector3.new(1.1,.12,.14),Vector3.new(1.8,.6+row*1.1,-1.15),dark)
            end
            for _,x in ipairs({-2.7,0,2.7}) do
                if def.theme=="Foundry" then
                    local gauge=q("PressureGauge",Vector3.new(.18,1.2,1.2),Vector3.new(x,4.6,-1.07),cream,nil,false,CFrame.Angles(0,math.pi/2,0));gauge.Shape=Enum.PartType.Cylinder
                    q("PressureNeedle",Vector3.new(.06,.43,.06),Vector3.new(x+.09,4.6,-1.23),dark,nil,false,CFrame.Angles(0,0,-.45+x*.06))
                elseif def.theme=="Frost" then
                    q("SealedPolarSample",Vector3.new(1.5,1.2,.12),Vector3.new(x,4.6,-1.08),Color3.fromRGB(118,183,198),Enum.Material.Glass)
                    q("SampleSeal",Vector3.new(1.1,.13,.14),Vector3.new(x,4.95,-1.17),cream)
                else
                    q("FieldEquipmentCase",Vector3.new(1.5,1.2,.18),Vector3.new(x,4.6,-1.08),cream)
                    q("FieldCaseLatch",Vector3.new(.2,.3,.12),Vector3.new(x+.5,4.6,-1.23),dark)
                end
            end
            q("RecoveredFieldOrders",Vector3.new(2,.95,.08),Vector3.new(-2.2,2.3,-1.2),cream,Enum.Material.SmoothPlastic,false,CFrame.Angles(0,0,.08))
            for row=1,3 do q("OrderTextTrace",Vector3.new(1.5,.035,.025),Vector3.new(-2.2,2.65-row*.18,-1.26),dark,Enum.Material.SmoothPlastic) end
            local labelCF=cf*CFrame.new(0,6.9/map.scale,-1.2)
            local yaw=math.atan2(-labelCF.LookVector.X,-labelCF.LookVector.Z)
            local caption=S(traces[map.id][i],labelCF.Position,Vector3.new(8.4,1.15,.1),yaw,cream);caption.Parent=body
            table.insert(map.facilityDisplays,{id=map.id.."_facility_"..i,room=i,purpose=r.purpose,trace=traces[map.id][i],part=body})
        end
    end
    -- Exterior silhouettes are scenery only. Players remain inside the authored rooms.
    local b=map.bounds
    for n=1,10 do
        local x=b.minX+4+(b.maxX-b.minX-8)*(n-1)/9 local z=b.minZ-22-(n%3)*7
        P("RuinedExteriorPillar",Vector3.new(2.3,6+n%5*2,2.4),Vector3.new(x,3+n%5,z),rust,Enum.Material.Brick,true,CFrame.Angles(0,n*.6,0))
        P("RuinedExteriorSlab",Vector3.new(9,.8,4),Vector3.new(x+4,1,z),cream,Enum.Material.Concrete,true,CFrame.Angles(.1,n*.4,.12))
    end
end
return Detail
