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
    self.backdropMotif=U.make("TextLabel",self.backdrop,{Name="OperationWatermark",Size=UDim2.fromScale(.9,.35),Position=UDim2.fromScale(.28,.37),
        BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBlack,TextScaled=true,TextTransparency=.86,
        TextColor3=Color3.fromRGB(207,222,225),TextXAlignment=Enum.TextXAlignment.Center,Rotation=-12,ZIndex=90})
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
    U.make("UIGradient",shade,{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.55,.35),NumberSequenceKeypoint.new(1,.68)})})
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
    if active then self.generation+=1 self.waiting=false self.frame.Visible=true
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
        -- Two rendered frames complete the camera/character handoff before a single-frame removal.
        RunService.RenderStepped:Wait() RunService.RenderStepped:Wait()
        if generation==self.generation and not self.state.travelling then self.frame.Visible=false self.waiting=false end
    end)
end
return L
