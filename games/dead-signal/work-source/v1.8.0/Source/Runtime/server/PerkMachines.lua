-- Original cabinet designs, labels and emblems; no external assets required.
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local V={}
function V.build(parent,key,cf,scale)
    local perk=C.Perks[key] local color=U.color(perk.color)
    local m=U.make("Model",parent,{Name="SodaMachine_"..key})
    local steel=Color3.fromRGB(103,112,112) local black=Color3.fromRGB(22,27,27)
    local cream=Color3.fromRGB(216,208,181)
    local function p(name,size,pos,col,mat,solid,rot,class)
        local obj=U.make(class or "Part",m,{Name=name,Size=size*scale,CFrame=cf*CFrame.new(pos*scale)*(rot or CFrame.new()),
            Color=col or color,Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=solid==true,CanTouch=false,CanQuery=solid==true})
        return obj
    end
    local body=p("Perk_"..key,Vector3.new(4.9,7.6,3.2),Vector3.new(0,3.8,0),color,Enum.Material.Metal,true)
    m.PrimaryPart=body
    p("Plinth",Vector3.new(5.2,.45,3.5),Vector3.new(0,.22,0),black)
    p("CreamDoor",Vector3.new(4.3,6.15,.14),Vector3.new(0,3.8,-1.68),cream)
    for _,x in ipairs({-2.25,2.25}) do p("ChromeEdge",Vector3.new(.15,7.4,.14),Vector3.new(x,3.95,-1.8),steel) end
    p("ChromeCrown",Vector3.new(4.6,.22,.2),Vector3.new(0,7.5,-1.8),steel)
    p("RoundedCrownLeft",Vector3.new(.6,.65,3.1),Vector3.new(-2.15,7.35,0),color,nil,false,CFrame.Angles(0,0,math.pi/2),"WedgePart")
    p("RoundedCrownRight",Vector3.new(.6,.65,3.1),Vector3.new(2.15,7.35,0),color,nil,false,CFrame.Angles(0,math.pi,math.pi/2),"WedgePart")
    local header=p("IlluminatedHeader",Vector3.new(3.95,1.6,.18),Vector3.new(0,6.35,-1.85),color,Enum.Material.Neon)
    U.make("PointLight",header,{Color=color,Brightness=.45,Range=9,Shadows=false})
    local function label(part,value,size,textColor)
        local g=U.make("SurfaceGui",part,{Face=Enum.NormalId.Front,PixelsPerStud=70,MaxDistance=65,LightInfluence=.2})
        U.make("TextLabel",g,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=value,TextColor3=textColor or cream,
            Font=Enum.Font.GothamBold,TextScaled=true,TextWrapped=true}) return g
    end
    label(header,perk.name:upper().."\nFIELD TONIC / 09.6",30)
    p("DisplayRecess",Vector3.new(2.65,3.4,.22),Vector3.new(-.5,3.75,-1.8),black)
    local glass=p("DisplayGlass",Vector3.new(2.5,3.2,.06),Vector3.new(-.5,3.75,-1.98),Color3.fromRGB(95,131,133),Enum.Material.Glass)
    glass.Transparency=.6
    for row=1,3 do
        p("BottleRack",Vector3.new(2.5,.12,.55),Vector3.new(-.5,1.92+row*.8,-1.93),steel)
        for j=1,4 do
            local x=-1.65+j*.45 local y=2.30+row*.8
            local bottle=p("TonicBottle",Vector3.new(.27,.67,.27),Vector3.new(x,y,-1.87),color,Enum.Material.Glass)
            bottle.Shape=Enum.PartType.Cylinder bottle.CFrame=bottle.CFrame*CFrame.Angles(0,0,math.pi/2) bottle.Size=Vector3.new(.67,.27,.27)*scale
            p("BottleNeck",Vector3.new(.13,.22,.13),Vector3.new(x,y+.43,-1.87),Color3.fromRGB(116,150,124),Enum.Material.Glass)
            p("BottleCap",Vector3.new(.18,.06,.18),Vector3.new(x,y+.57,-1.87),steel)
            p("BottleLabel",Vector3.new(.23,.21,.02),Vector3.new(x,y,-2.02),cream)
        end
    end
    p("CoinPanel",Vector3.new(.9,2.5,.18),Vector3.new(1.5,3.95,-1.83),steel)
    p("CoinSlot",Vector3.new(.09,.45,.04),Vector3.new(1.5,4.6,-1.95),black)
    local button=p("DispenseButton",Vector3.new(.13,.38,.38),Vector3.new(1.5,3.9,-1.95),color,Enum.Material.Neon)
    button.Shape=Enum.PartType.Cylinder button.CFrame=button.CFrame*CFrame.Angles(0,math.pi/2,0)
    p("CoinReturn",Vector3.new(.5,.22,.08),Vector3.new(1.5,3.1,-1.94),black)
    p("BottleDelivery",Vector3.new(2.9,.7,.2),Vector3.new(-.45,1.2,-1.88),black)
    p("DeliveryFlap",Vector3.new(2.65,.35,.05),Vector3.new(-.45,1.34,-2),steel)
    for j=1,6 do p("CoolingVent",Vector3.new(3.2,.035,.05),Vector3.new(0,.43+j*.09,-1.87),black) end
    local price=p("PricePlate",Vector3.new(3.5,.56,.05),Vector3.new(0,1.93,-2),cream)
    label(price,(key=="Lifeline" and "SOLO 1000 / CREW 2000" or perk.price.." POINTS").."\n"..(key=="Lifeline" and "POWER / R2 SOLO / R3 CREW" or "POWER / ROUND "..perk.round),16,black)
    local legend=p("SideEmblem",Vector3.new(.08,4,2.5),Vector3.new(2.5,4,.1),color)
    local g=U.make("SurfaceGui",legend,{Face=Enum.NormalId.Right,PixelsPerStud=60,MaxDistance=50})
    U.make("TextLabel",g,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=perk.name:upper().."\n09.6",TextColor3=cream,Font=Enum.Font.GothamBlack,TextScaled=true})
    -- Aged enamel, chipped corners and small screws give the cabinet depth.
    for j=1,7 do p("EnamelWear",Vector3.new(.15+j%3*.1,.09,.025),Vector3.new(-2+j*.55,.8+j%3*.2,-1.89),Color3.fromRGB(81,78,64)) end
    for _,x in ipairs({-2,2}) do for _,y in ipairs({.7,7}) do
        local screw=p("PanelScrew",Vector3.new(.085,.085,.035),Vector3.new(x,y,-1.88),steel) screw.Shape=Enum.PartType.Cylinder
    end end
    return body,m
end
return V
