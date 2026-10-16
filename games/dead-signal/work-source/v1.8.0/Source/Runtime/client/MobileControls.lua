local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local PPS=game:GetService("ProximityPromptService")
local RS=game:GetService("ReplicatedStorage")
local Settings=require(RS.DeadSignal.ControlSettings)
local Layout=require(RS.DeadSignal.TouchLayout)
local Input=require(RS.DeadSignal.TouchInput)
local U=require(RS.DeadSignal.Util)
local M={} M.__index=M
local labels={AIM="ADS",RELOAD="RELOAD",SWAP="SWAP",MELEE="MELEE",G="FRAG"}
local editorKeys={"Move","Fire","Classic","Aim","Reload","Swap","Melee","Grenade"}
local function copy(t) return table.clone(t) end
function M.new(ui,callbacks)
    local self=setmetatable({ui=ui,cb=callbacks,settings=Settings.resolve(),enabled=false,
        yaw=0,pitch=0,editor=false,editorKey=1,widgets={},samples={},prompts={},activeTouch=UIS.TouchEnabled},M)
    self.router=Input.new(self.settings)
    self.gui=U.make("ScreenGui",Players.LocalPlayer.PlayerGui,{Name="DeadSignalTouch",ResetOnSpawn=false,
        ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=21,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    self.frame=U.make("Frame",self.gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
    local function widget(name,label)
        local f=U.make("Frame",self.frame,{Name=name,BackgroundColor3=Color3.fromRGB(24,34,39),
            BackgroundTransparency=.65,BorderSizePixel=0,Active=false})
        U.make("UICorner",f,{CornerRadius=UDim.new(1,0)})
        local stroke=U.make("UIStroke",f,{Color=Color3.fromRGB(165,191,185),Transparency=.55})
        local text=U.make("TextLabel",f,{Size=UDim2.fromScale(1,1),Text=label,BackgroundTransparency=1,
            TextColor3=Color3.fromRGB(223,235,224),Font=Enum.Font.GothamBold,TextSize=12})
        self.widgets[name]={frame=f,text=text,stroke=stroke} return f
    end
    widget("Move","MOVE") self.knob=U.make("Frame",self.widgets.Move.frame,{AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.32,.32),BackgroundColor3=Color3.fromRGB(190,213,204),BackgroundTransparency=.45,BorderSizePixel=0})
    U.make("UICorner",self.knob,{CornerRadius=UDim.new(1,0)})
    widget("Fire","FIRE")
    for action,label in pairs(labels) do widget(action,label) end
    self.hint=U.make("TextLabel",self.frame,{Size=UDim2.new(.5,0,0,14),Position=UDim2.new(.25,0,1,-16),
        BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(177,210,203),Font=Enum.Font.Gotham,TextSize=10})
    self.indicator=U.make("Frame",self.frame,{Size=UDim2.fromOffset(18,18),AnchorPoint=Vector2.new(.5,.5),Visible=false,BackgroundTransparency=1})
    U.make("UICorner",self.indicator,{CornerRadius=UDim.new(1,0)})
    self.indicatorStroke=U.make("UIStroke",self.indicator,{Color=Color3.fromRGB(111,231,204),Thickness=2})
    self:buildEditor()
    local summary=U.make("BindableFunction",self.gui,{Name="Summary"})
    summary.OnInvoke=function() local data=self:summary() print(game:GetService("HttpService"):JSONEncode(data)) return data end
    self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:resize() self:cancel("viewport resized") end)
    UIS.LastInputTypeChanged:Connect(function(kind)
        if kind==Enum.UserInputType.Touch then self.activeTouch=true
        elseif kind==Enum.UserInputType.Gamepad1 or kind==Enum.UserInputType.Keyboard or kind==Enum.UserInputType.MouseButton1 then
            self.activeTouch=false self:cancel("input device changed")
        end
    end)
    local function point(input) local p=input.Position local offset=self.frame.AbsolutePosition return p.X-offset.X,p.Y-offset.Y end
    UIS.TouchStarted:Connect(function(input,processed)
        if self.editor then self:editorBegin(input,processed) return end
        self.activeTouch=true
        if not self.enabled and self.allowed and not processed then
            self:cancel("input device changed") self.enabled=true
            local look=workspace.CurrentCamera.CFrame.LookVector
            self.yaw=math.atan2(-look.X,-look.Z) self.pitch=math.asin(math.clamp(look.Y,-1,1))
            self.cb.native(true)
        end
        if not self.enabled or not self.layout or self:blocked(input,processed) then return end
        local x,y=point(input) local role=Layout.role(self.layout,self.settings,x,y)
        local g=self.cb.weapon()
        self.router:begin(input,x,y,os.clock(),role,self.layout.move.w/2,g and g.auto)
        if role=="move" and self.router.moveOwner==input then
            self.moveAnchor=Vector2.new(x,y)
        end
        self:events()
    end)
    UIS.TouchMoved:Connect(function(input)
        if self.editor then self:editorMove(input) return end
        if not self.enabled then return end
        local x,y=point(input) self.router:move(input,x,y,os.clock())
    end)
    UIS.TouchEnded:Connect(function(input)
        if self.editor then if self.editFinger==input then self.editFinger=nil end return end
        local x,y=point(input)
        self.router:finish(input,x,y,os.clock(),input.UserInputState==Enum.UserInputState.Cancel)
        self:events()
    end)
    UIS.WindowFocusReleased:Connect(function() self:cancel("window focus") end)
    UIS.TextBoxFocused:Connect(function() self:cancel("text focus") end)
    GuiService.MenuOpened:Connect(function() self:cancel("Roblox menu") end)
    PPS.PromptShown:Connect(function(prompt) self.prompts[prompt]=true end)
    PPS.PromptHidden:Connect(function(prompt) self.prompts[prompt]=nil end)
    PPS.PromptButtonHoldBegan:Connect(function(_,player)
        if not player or player==Players.LocalPlayer then self:cancel("interaction") end
    end)
    UIS.DeviceRotationChanged:Connect(function(_,cf)
        if self.enabled and self.settings.gyroAim and UIS.GyroscopeEnabled and self.lastGyro then
            local delta=self.lastGyro:ToObjectSpace(cf) local x,y=delta:ToEulerAnglesYXZ()
            self.yaw=self.yaw-math.clamp(y,-.07,.07)*self.settings.gyroSensitivity
            self.pitch=math.clamp(self.pitch+math.clamp(x,-.07,.07)*self.settings.gyroSensitivity,-1.42,1.42)
        end
        self.lastGyro=cf
    end)
    self:resize() return self
end
function M:resize()
    local size=self.frame.AbsoluteSize if size.X<1 or size.Y<1 then return end
    self.layout=Layout.build(size.X,size.Y,self.settings)
    local function fit(widget,r)
        widget.frame.Position=UDim2.fromOffset(r.x,r.y) widget.frame.Size=UDim2.fromOffset(r.w,r.h)
        widget.frame.BackgroundTransparency=1-self.settings.hudOpacity
        widget.text.TextTransparency=math.max(0,.45-self.settings.hudOpacity)
    end
    fit(self.widgets.Move,self.layout.move) fit(self.widgets.Fire,self.layout.fire)
    for name,r in pairs(self.layout.buttons) do fit(self.widgets[name],r) end
    self.widgets.Fire.frame.Visible=self.editor or self.settings.fireLayout~="Tap"
    self.widgets.Fire.text.Text=self.settings.leftGesture=="Toggle" and "FIRE\nTOGGLE" or "FIRE"
    self.widgets.Move.text.Text=self.settings.fireLayout=="Left" and self.settings.leftGesture=="Outer" and "↑ FIRE EDGE" or "MOVE"
    self.widgets.Move.text.Position=UDim2.fromScale(0,.07) self.widgets.Move.text.Size=UDim2.fromScale(1,.2) self.widgets.Move.text.TextSize=10
    if self.editor then self:editorLabel() end
end
function M:setSettings(settings)
    local value=Settings.resolve(settings) local changed=false
    for key,v in pairs(value) do if self.settings[key]~=v then changed=true break end end
    if changed then self:cancel("settings changed") self.settings=value self.router.settings=value self:resize() end
end
function M:blocked(input,processed)
    if processed or UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then return true end
    for _,obj in ipairs(Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(input.Position.X,input.Position.Y)) do
        if not obj:IsDescendantOf(self.gui) and (obj:IsA("GuiButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") or obj.Active) then return true end
    end
    -- Built-in prompt GUI can live in CoreGui; reserve its visible click target too.
    local camera=workspace.CurrentCamera local offset=self.frame.AbsolutePosition
    for prompt in pairs(self.prompts) do
        local parent=prompt.Parent
        local pos=parent and (parent:IsA("Attachment") and parent.WorldPosition or parent:IsA("BasePart") and parent.Position)
        if pos and prompt.Enabled then local p,visible=camera:WorldToScreenPoint(pos)
            if visible and (Vector2.new(input.Position.X,input.Position.Y)-Vector2.new(p.X,p.Y)).Magnitude<52 then return true end
        end
    end
    return false
end
function M:events()
    for _,event in ipairs(self.router:drain()) do
        if event.kind=="shot" and self.enabled then
            local point=event.data.screen and Vector2.new(event.data.x,event.data.y)+self.frame.AbsolutePosition or nil
            self:request(point,true)
        elseif event.kind=="action" and self.enabled then self.cb.action(event.data) end
    end
end
function M:request(point,pulse)
    local key=self.settings.fireLayout local sample=self.samples[key] or {requests=0,accepted=0,hits=0,kills=0,seconds=0}
    self.samples[key]=sample sample.requests=sample.requests+1
    if self.cb.fire(point,pulse) then
        self.lastAcceptedShot=os.clock()
        sample.accepted=sample.accepted+1
        if point then self.indicator.Position=UDim2.fromOffset(point.X-self.frame.AbsolutePosition.X,point.Y-self.frame.AbsolutePosition.Y) self.indicator.Visible=true self.indicatorUntil=os.clock()+.13 end
    end
end
function M:hit(kill)
    local sample=self.samples[self.settings.fireLayout]
    if sample then sample.hits=sample.hits+1 if kill then sample.kills=sample.kills+1 end end
end
function M:summary()
    return {samples=self.samples,gestures=copy(self.router.metrics),layout=self.settings.fireLayout,
        note="Local shot requests and server hit confirmations; comfort and accidental fire require player observation."}
end
function M:cancel(reason)
    local char=Players.LocalPlayer.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:Move(Vector3.new(),false) end
    self.router:cancel(reason) self.moveAnchor=nil self.lastGyro=nil self.editFinger=nil
    if reason=="input reset" or reason=="Roblox menu" or reason=="window focus" or reason=="text focus" then
        self.editor=false if self.editorPanel then self.editorPanel.Visible=false end
    end
    if self.cb.stop then self.cb.stop() end
end
function M:cancelFire(reason)
    self.router:cancelFire(reason)
    if self.cb.stop then self.cb.stop() end
end
function M:update(dt,state,menu,aiming,scoped)
    self.allowed=UIS.TouchEnabled and state and state.participating
        and (state.status=="Alive" or state.status=="Down") and not menu and not state.travelling and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
    local shouldOwn=self.allowed and self.activeTouch
    if not not shouldOwn~=self.enabled then
        self:cancel("game state") self.enabled=not not shouldOwn
        if self.enabled then local look=workspace.CurrentCamera.CFrame.LookVector self.yaw=math.atan2(-look.X,-look.Z) self.pitch=math.asin(math.clamp(look.Y,-1,1)) end
    end
    self.frame.Visible=self.enabled or self.editor
    self.cb.native(self.enabled or self.editor)
    if self.editor then workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable return end
    if not self.enabled or not self.layout then return end
    local def=self.cb.weapon()
    local out=self.router:step(os.clock(),def and def.auto) self:events()
    local sensitivity=(scoped and self.settings.scopeSensitivity or aiming and self.settings.adsSensitivity or 1)
    local slow=self.cb.slowdown and self.cb.slowdown() or 1
    self.yaw=self.yaw-out.lookX*.0038*self.settings.lookSensitivity*sensitivity*slow
    self.pitch=math.clamp(self.pitch-out.lookY*.0038*self.settings.verticalSensitivity*sensitivity*(self.settings.invertY and -1 or 1)*slow,-1.42,1.42)
    local char=Players.LocalPlayer.Character local root=char and char:FindFirstChild("HumanoidRootPart") local hum=char and char:FindFirstChildOfClass("Humanoid")
    local head=char and char:FindFirstChild("Head") local camera=workspace.CurrentCamera
    if root and hum and head then
        camera.CameraType=Enum.CameraType.Scriptable
        local yaw=CFrame.Angles(0,self.yaw,0)
        local desired=head.Position local base=root.Position+Vector3.new(0,state.status=="Down" and .2 or 1.2,0)
        local map=workspace:FindFirstChild("DeadSignalMap")
        if map and (desired-base).Magnitude>.02 then
            local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map} params.CollisionGroup="DeadSignalShots"
            local hit=workspace:Raycast(base,desired-base,params) if hit then desired=hit.Position+hit.Normal*.25 end
        end
        camera.CFrame=CFrame.new(desired)*yaw*CFrame.Angles(self.pitch,0,0) camera.Focus=CFrame.new(desired+camera.CFrame.LookVector*12)
        hum.AutoRotate=false
        if state.status=="Alive" then root.CFrame=CFrame.new(root.Position)*yaw end
        hum:Move(yaw:VectorToWorldSpace(Vector3.new(out.x,0,out.y)),false)
        for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("BasePart") then obj.LocalTransparencyModifier=1 end end
    end
    self.cb.sprint(out.sprint and not aiming and state.status=="Alive" and os.clock()-(self.lastAcceptedShot or -100)>.4)
    local fire=out.held
    if fire then
        local point=fire.screen and Vector2.new(fire.x,fire.y)+self.frame.AbsolutePosition or nil
        self:request(point,false)
    elseif self.settings.autoFire and self.settings.assistPreset=="Assisted" and not self.router.fire then
        local look=self.router.lookOwner and self.router.touches[self.router.lookOwner]
        if (not look or look.swipe) and self.cb.autoEligible() then self:request(nil,not (def and def.auto)) end
    end
    local move=self.layout.move local pos=self.moveAnchor
    self.widgets.Move.frame.Position=pos and UDim2.fromOffset(pos.X-move.w/2,pos.Y-move.h/2) or UDim2.fromOffset(move.x,move.y)
    self.knob.Position=UDim2.fromScale(.5+out.x*.34,.5+out.y*.34)
    self.widgets.Fire.stroke.Color=self.router.fire and Color3.fromRGB(255,112,65) or Color3.fromRGB(165,191,185)
    self.widgets.Move.stroke.Color=self.router.fire and Color3.fromRGB(255,112,65) or Color3.fromRGB(165,191,185)
    local stopHint=self.settings.fireLayout=="Left" and (self.settings.leftGesture=="Toggle" and "TAP FIRE TO STOP" or self.settings.leftGesture=="Outer" and "CENTER STICK / RELEASE TO STOP") or "RELEASE TO STOP"
    self.hint.Text=self.router.fire and "FIRING · "..stopHint or self.settings.fireLayout=="Tap" and "TAP TO SHOOT · SWIPE TO LOOK · HOLD FOR AUTO" or ""
    if self.indicator.Visible and os.clock()>(self.indicatorUntil or 0) then self.indicator.Visible=false end
    local sample=self.samples[self.settings.fireLayout] if sample then sample.seconds=sample.seconds+dt end
end
function M:buildEditor()
    self.editorPanel=U.make("Frame",self.gui,{Size=UDim2.new(1,-20,0,82),Position=UDim2.fromOffset(10,8),
        BackgroundColor3=Color3.fromRGB(17,29,33),BorderSizePixel=0,Visible=false,Active=true,ZIndex=4})
    self.editorTitle=U.make("TextLabel",self.editorPanel,{Size=UDim2.new(1,-16,0,28),Position=UDim2.fromOffset(8,0),
        BackgroundTransparency=1,Text="Drag a zone. Select a control to resize.",TextColor3=Color3.fromRGB(226,239,228),TextSize=12,Font=Enum.Font.Gotham})
    local function button(label,order,fn)
        local b=U.make("TextButton",self.editorPanel,{Size=UDim2.new(1/7,-6,0,38),Position=UDim2.new((order-1)/7,3,0,34),
            Text=label,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(223,239,228),BackgroundColor3=Color3.fromRGB(39,57,61),BorderSizePixel=0})
        b.Activated:Connect(fn)
    end
    button("SELECT",1,function() self.editorKey=self.editorKey%#editorKeys+1 self:editorLabel() end)
    button("SMALLER",2,function() self:editValue("Size",-.1) end)
    button("LARGER",3,function() self:editValue("Size",.1) end)
    button("FADE",4,function() self.settings.hudOpacity=self.settings.hudOpacity>=.8 and .15 or math.min(.85,self.settings.hudOpacity+.15) self:resize() end)
    button("MIRROR",5,function() self.settings.leftHanded=not self.settings.leftHanded self:resize() end)
    button("RESET",6,function() self.settings=Settings.resolve() self.router.settings=self.settings self:resize() self:editorLabel() end)
    button("SAVE",7,function()
        self.editor=false self.editorPanel.Visible=false self.cb.save(copy(self.settings)) self:cancel("editor closed") self:resize()
    end)
end
function M:editorLabel()
    local overlaps=self.layout and Layout.overlaps(self.layout,self.settings) or {}
    self.editorTitle.Text="HUD EDITOR · "..editorKeys[self.editorKey]..(#overlaps>0 and " · Overlap: "..table.concat(overlaps,", ") or " · Drag zones; SELECT resizes.")
end
function M:editValue(suffix,amount)
    local key="hud"..editorKeys[self.editorKey]..suffix
    self.settings[key]=math.clamp(self.settings[key]+amount,.65,1.5) self:resize()
end
function M:openEditor()
    self:cancel("HUD editor") self.editor=true self.editorPanel.Visible=true self.frame.Visible=true self:resize() self:editorLabel()
end
function M:editorBegin(input,processed)
    if processed then return end
    local p=Vector2.new(input.Position.X,input.Position.Y)-self.frame.AbsolutePosition
    if p.Y<100 then return end
    local chosen
    if Layout.contains(self.layout.move,p.X,p.Y) then chosen="Move"
    elseif Layout.contains(self.layout.fire,p.X,p.Y) then chosen=self.settings.fireLayout=="Classic" and "Classic" or "Fire"
    else for _,r in pairs(self.layout.buttons) do if Layout.contains(r,p.X,p.Y) then chosen=r.key break end end end
    if not chosen then return end
    for i,key in ipairs(editorKeys) do if key==chosen then self.editorKey=i break end end
    self.editFinger=input self:editorLabel()
end
function M:editorMove(input)
    if self.editFinger~=input then return end
    local p=Vector2.new(input.Position.X,input.Position.Y)-self.frame.AbsolutePosition
    local key="hud"..editorKeys[self.editorKey]
    local x=math.clamp(p.X/self.layout.w,.04,.96)
    self.settings[key.."X"]=self.settings.leftHanded and 1-x or x
    self.settings[key.."Y"]=math.clamp(p.Y/self.layout.h,.04,.96) self:resize()
end
return M
