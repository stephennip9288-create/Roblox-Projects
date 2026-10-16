local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util) local C=require(RS.DeadSignal.Config)
local Z={}
function Z.begin(map)
    if map.extractionVisual then map.extractionVisual.model:Destroy() end
    local model=U.make("Model",map.model,{Name="ActiveExtractionZone"}) local center=map.exfilCenter local radius=C.Extraction.radius*map.scale
    local function p(name,size,cf,color)
        return U.make("Part",model,{Name=name,Size=size,CFrame=cf,Color=color,Material=Enum.Material.Neon,
            Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false})
    end
    local amber=Color3.fromRGB(234,178,77) local ring={}
    for i=1,48 do local a=i*math.pi/24
        table.insert(ring,p("BoardingBoundary",Vector3.new(radius*math.pi/24+.03,.035,.13),CFrame.new(center+Vector3.new(math.cos(a)*radius,.075,math.sin(a)*radius))*CFrame.Angles(0,-a-math.pi/2,0),amber))
    end
    local beacon=p("RescueBeacon",Vector3.new(.18,12,.18),CFrame.new(center+Vector3.new(0,6,0)),amber) beacon.Transparency=.35
    U.make("PointLight",beacon,{Brightness=1,Range=16,Color=amber,Shadows=false})
    local marker=U.make("BillboardGui",beacon,{Name="BoardingMarker",Size=UDim2.fromOffset(245,64),StudsOffsetWorldSpace=Vector3.new(0,3,0),AlwaysOnTop=true,MaxDistance=1000})
    local label=U.make("TextLabel",marker,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(13,18,18),BackgroundTransparency=.15,
        Text="EXTRACT HERE\nELIMINATE THE WARDEN",TextColor3=amber,Font=Enum.Font.GothamBold,TextSize=14,TextWrapped=true})
    U.make("UICorner",label,{CornerRadius=UDim.new(0,3)})
    map.extractionVisual={model=model,label=label,ring=ring}
end
function Z.update(map,run)
    local v=map.extractionVisual if not v then return end
    local stats=run.exfilStats or {} local time=math.max(0,math.ceil(run.deadline-os.clock()))
    local color=run.exfilStage=="Board" and Color3.fromRGB(109,216,185) or stats.contested and Color3.fromRGB(226,94,64) or Color3.fromRGB(234,178,77)
    v.label.Text="EXTRACT HERE / "..string.format("%d:%02d",math.floor(time/60),time%60).."\n"..(run.exfilStage=="Warden" and "ELIMINATE THE WARDEN" or (stats.insideAlive or 0).." / "..(stats.alive or 0).." CREW  •  "..math.floor(run.exfilProgress or 0).."%")
    v.label.TextColor3=color for _,q in ipairs(v.ring) do q.Color=color end
end
return Z
