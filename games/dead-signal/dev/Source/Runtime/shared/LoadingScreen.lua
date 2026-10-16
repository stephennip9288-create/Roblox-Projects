-- One opaque, full-viewport layer. No animated world camera or translucent exit tween.
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Content=game:GetService("ContentProvider")
local Arrival=require(RS.DeadSignal.ArrivalRules)
local L={} L.__index=L
function L.new(parent)
    local self=setmetatable({generation=0},L)
    local gui=parent
    if parent.Name=="DeadSignalHUD" and parent.Parent then
        local old=parent.Parent:FindFirstChild("DeadSignalLoading") if old then old:Destroy() end
        gui=U.make("ScreenGui",parent.Parent,{Name="DeadSignalLoading"})
    end
    gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.ScreenInsets=Enum.ScreenInsets.None gui.ClipToDeviceSafeArea=false
    gui.DisplayOrder=1000 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling self.gui=gui
    self.frame=U.make("Frame",gui,{Name="TravelScreen",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(10,15,18),BackgroundTransparency=0,BorderSizePixel=0,Visible=false,Active=true,ZIndex=90})
    -- Keep an authored, map-specific background even if artwork assets are private,
    -- deleted, moderated, still streaming, or unavailable to a particular client.
    -- This fallback is drawn from ordinary GUI primitives and needs no external assets.
    self.backdrop=U.make("Frame",self.frame,{Name="BuiltInMapBackdrop",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(21,32,38),BorderSizePixel=0,ZIndex=90})
    self.backdropGradient=U.make("UIGradient",self.backdrop,{Rotation=28})
    self.backdropMotif=U.make("TextLabel",self.backdrop,{Name="OperationWatermark",Size=UDim2.fromScale(.82,.3),Position=UDim2.fromScale(.34,.33),
        BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBlack,TextScaled=true,TextTransparency=.76,
        TextColor3=Color3.fromRGB(207,222,225),TextXAlignment=Enum.TextXAlignment.Center,Rotation=-10,ZIndex=90})

    -- Asset-independent scenic art. Every map has an immediately visible backdrop
    -- even on a first join, slow network, private image assets or failed preloading.
    -- Only lightweight static Roblox UI primitives; no external image IDs.
    self.scenes={}
    local function shape(parent,name,x,y,w,h,color,transparency,rotation)
        return U.make("Frame",parent,{
            Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),
            BackgroundColor3=color,BackgroundTransparency=transparency or 0,
            BorderSizePixel=0,Rotation=rotation or 0,ZIndex=90})
    end
    local function scene(map)
        local root=U.make("Frame",self.backdrop,{
            Name=map.."Scenery",Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,Visible=false,ZIndex=90})
        self.scenes[map]=root
        return root
    end
    local function glow(parent,x,y,r,color)
        local orb=shape(parent,"AtmosphericGlow",x,y,r,r,color,.48)
        U.make("UICorner",orb,{CornerRadius=UDim.new(1,0)})
        U.make("UIAspectRatioConstraint",orb,{AspectRatio=1})
    end
    local function buildings(parent,items,color)
        for i,v in ipairs(items) do
            local x,w,h=v[1],v[2],v[3]
            shape(parent,"Structure"..i,x,.79-h,w,h,color,.10)
            for j=1,3 do
                shape(parent,"LitWindow"..i.."_"..j,x+.012,.79-h+j*h/4,w*.35,.007,Color3.fromRGB(214,192,125),.35)
            end
        end
    end
    do
        local root=scene("Lobby")
        glow(root,.76,.13,.14,Color3.fromRGB(103,188,212))
        shape(root,"Horizon",0,.79,1,.21,Color3.fromRGB(5,19,30),.06)
        buildings(root,{{.41,.10,.19},{.53,.11,.26},{.65,.08,.15},{.79,.10,.22},{.91,.08,.16}},Color3.fromRGB(11,30,42))
        shape(root,"DispatchTower",.74,.29,.019,.5,Color3.fromRGB(14,28,38))
        shape(root,"DispatchMast",.744,.16,.009,.18,Color3.fromRGB(110,196,213),.04)
        shape(root,"Beacon",.733,.16,.033,.014,Color3.fromRGB(238,188,103))
        shape(root,"GroundLine",0,.79,1,.007,Color3.fromRGB(78,167,187),.25)
    end
    do
        local root=scene("Station")
        glow(root,.79,.11,.12,Color3.fromRGB(210,114,73))
        shape(root,"DarkGround",0,.82,1,.18,Color3.fromRGB(18,22,19))
        buildings(root,{{.42,.11,.21},{.54,.13,.32},{.69,.10,.2},{.82,.13,.31},{.96,.07,.16}},Color3.fromRGB(28,33,29))
        shape(root,"DamagedAntenna",.75,.26,.011,.56,Color3.fromRGB(57,69,58),.06,-6)
        shape(root,"Crossarm",.69,.35,.13,.009,Color3.fromRGB(101,116,97),.1,-6)
        shape(root,"HazardBand",0,.8,1,.009,Color3.fromRGB(209,105,66),.17)
    end
    do
        local root=scene("Foundry")
        glow(root,.74,.24,.23,Color3.fromRGB(246,133,54))
        shape(root,"FoundryFloor",0,.78,1,.22,Color3.fromRGB(36,21,16))
        buildings(root,{{.43,.15,.27},{.60,.17,.37},{.79,.14,.24},{.95,.09,.18}},Color3.fromRGB(48,33,27))
        shape(root,"StackOne",.64,.16,.039,.42,Color3.fromRGB(39,36,35))
        shape(root,"StackTwo",.84,.28,.035,.29,Color3.fromRGB(41,36,34))
        shape(root,"FurnaceLight",.56,.68,.13,.036,Color3.fromRGB(250,155,58),.12)
        shape(root,"FurnaceLight2",.80,.72,.10,.026,Color3.fromRGB(250,155,58),.16)
        shape(root,"HotHorizon",0,.79,1,.012,Color3.fromRGB(234,115,44),.1)
    end
    do
        local root=scene("Frost")
        glow(root,.75,.09,.15,Color3.fromRGB(175,220,242))
        shape(root,"FrozenHorizon",0,.80,1,.20,Color3.fromRGB(10,28,43))
        shape(root,"MountainFarOne",.60,.57,.40,.42,Color3.fromRGB(58,111,141),.20,45)
        shape(root,"MountainFarTwo",.83,.62,.29,.29,Color3.fromRGB(80,151,176),.16,45)
        shape(root,"IceShelf",0,.88,1,.12,Color3.fromRGB(25,64,91),.10)
        shape(root,"RelaySpire",.76,.24,.014,.52,Color3.fromRGB(108,165,181))
        shape(root,"RelayArm",.70,.41,.14,.011,Color3.fromRGB(127,200,217),.05)
        shape(root,"FrozenRidge",0,.82,1,.009,Color3.fromRGB(178,221,237),.28)
    end
    for n=0,12 do
        U.make("Frame",self.backdrop,{Name="SignalGrid"..n,Position=UDim2.fromScale(n/10-.1,0),
            Size=UDim2.new(0,1,1,0),BackgroundColor3=Color3.fromRGB(205,217,221),
            BackgroundTransparency=.89,BorderSizePixel=0,ZIndex=90})
    end
    self.image=U.make("ImageLabel",self.frame,{Name="MapArtwork",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Crop,Visible=false,ZIndex=91})
    self.image:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        if self.image.Parent then self.image.Visible=self.image.Image~="" and self.image.IsLoaded end
    end)
    local shade=U.make("Frame",self.frame,{Name="EditorialShade",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=92})
    -- Previously .08 transparency meant 92% *opaque* black on the left,
    -- swallowing the map art. Preserve readability without blacking it out.
    U.make("UIGradient",shade,{Rotation=0,Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,.60),NumberSequenceKeypoint.new(.55,.75),NumberSequenceKeypoint.new(1,.92)})})
    local function label(name,text,y,h,size,color)
        return U.make("TextLabel",self.frame,{Name=name,Text=text,Position=UDim2.fromScale(.07,y),Size=UDim2.fromScale(.80,h),BackgroundTransparency=1,
            TextColor3=color or Color3.fromRGB(233,231,218),TextSize=size,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,ZIndex=94})
    end
    self.kicker=label("Chapter","OPERATIONS DIVISION / SIGNAL ARCHIVE",.13,.05,12,Color3.fromRGB(200,166,106))
    self.brand=label("GameTitle","DEAD SIGNAL",.23,.13,48)
    self.name=label("MapTitle","",.42,.13,27)
    self.lore=label("MapLore","",.59,.18,15,Color3.fromRGB(192,201,199)) self.lore.Font=Enum.Font.Gotham
    self.status=label("ConnectionStatus","CONNECTING",.83,.06,12,Color3.fromRGB(208,172,111))
    self.tip=label("ExtractionTip","Restore the signal. Defeat the Warden. Rally at the rescue beacon.",.93,.045,11,Color3.fromRGB(153,173,177))
    U.make("Frame",self.frame,{Position=UDim2.fromScale(.07,.565),Size=UDim2.new(.06,0,0,2),BackgroundColor3=Color3.fromRGB(205,166,102),BorderSizePixel=0,ZIndex=94})
    local function resize()
        local v=self.frame.AbsoluteSize if v.X<1 then return end
        self.brand.TextSize=math.clamp(v.Y*.09,25,48) self.name.TextSize=v.X<600 and 21 or 27
        self.lore.TextSize=v.Y<450 and 12 or 15
        self.tip.Visible=v.Y>=360
    end
    self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize) resize()
    return self
end
function L:set(map,message,active)
    map=C.Maps[map] and map or map=="Lobby" and map or "Station"
    if self.map~=map then
        self.map=map local def=C.Maps[map]
        self.name.Text=def and string.upper(def.name) or "DISPATCH / SAFE HAVEN"
        self.lore.Text=def and def.lore or "Regroup at Dispatch. Rearm, choose a destination, and follow the next signal."
        local themes={
            Lobby={top=Color3.fromRGB(30,45,55),bottom=Color3.fromRGB(9,14,21),accent=Color3.fromRGB(89,170,193),label="DISPATCH"},
            Station={top=Color3.fromRGB(55,63,57),bottom=Color3.fromRGB(12,17,17),accent=Color3.fromRGB(181,83,60),label="BLACKWATER"},
            Foundry={top=Color3.fromRGB(82,45,29),bottom=Color3.fromRGB(21,14,13),accent=Color3.fromRGB(238,140,52),label="CINDERWORKS"},
            Frost={top=Color3.fromRGB(35,75,99),bottom=Color3.fromRGB(10,23,38),accent=Color3.fromRGB(111,202,227),label="WHITEOUT"},
        }
        local theme=themes[map]
        for name,root in pairs(self.scenes) do root.Visible=name==map end
        self.backdrop.BackgroundColor3=theme.bottom
        self.backdropGradient.Color=ColorSequence.new(theme.top,theme.bottom)
        self.backdropMotif.Text=theme.label
        self.backdropMotif.TextColor3=theme.accent
        self.status.TextColor3=theme.accent
        local id=tostring(C.MapArtworkIds[map] or "")
        local validId=id:match("^rbxassetid://%d+$") and id or (tonumber(id) and tonumber(id)>0 and "rbxassetid://"..id or "")
        self.image.Visible=false
        self.image.Image=validId
        local expected=map
        if validId~="" then
            task.spawn(function()
                pcall(function() Content:PreloadAsync({self.image}) end)
                if self.map==expected and self.image.Parent and self.image.Image==validId then
                    self.image.Visible=self.image.IsLoaded
                end
            end)
        end
    end
    self.status.Text=string.upper(message or "CONNECTING")
    if active then
        if not self.frame.Visible then self.shownAt=os.clock() end
        self.generation+=1 self.waiting=false self.frame.Visible=true
    else self.generation+=1 self.waiting=false self.frame.Visible=false end
end
function L:update(state)
    self.state=state
    if state.travelling then return end
    local admitted=Arrival.admitted(state)
    local dispatch=state.role~="Match" and not state.participating
    if state.role=="Match" and not admitted and state.phase~="Results" and state.status~="Rejected" then
        self:set(state.map,"Waiting for deployment authorization",true) return
    end
    if not self.frame.Visible or self.waiting then return end
    self.waiting=true self.generation+=1 local generation=self.generation
    task.spawn(function()
        local started=os.clock() local ready=false
        repeat
            if generation~=self.generation then return end
            local current=self.state local player=Players.LocalPlayer local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart")
            local model=workspace:FindFirstChild(dispatch and "DeadSignalLobby" or "DeadSignalMap")
            local supported=false
            if root and model and not dispatch then
                local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={model}
                supported=workspace:Raycast(root.Position,Vector3.new(0,-12,0),p)~=nil
            end
            ready=current and Arrival.ready(current,root~=nil,model~=nil,model and model:GetAttribute("MapReady"),supported)
            if not ready then task.wait(.08) end
        until ready or os.clock()-started>8
        if generation~=self.generation then return end
        -- Keep the actual background on-screen long enough to register visually
        -- on fast clients, without blocking gameplay beyond a short handoff.
        task.wait(math.max(0,1.0-(os.clock()-(self.shownAt or os.clock()))))
        if generation~=self.generation then return end
        RunService.RenderStepped:Wait() RunService.RenderStepped:Wait()
        if generation==self.generation and not self.state.travelling then self.frame.Visible=false self.waiting=false end
    end)
end
return L
