local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Tween=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.DeadSignal.Config)
local R=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local Presentation=require(RS.DeadSignal.Presentation)
local LoadingScreen=require(RS.DeadSignal.LoadingScreen)
local PC=require(RS.DeadSignal.PlaceConfig)
local WeaponModels=require(RS.DeadSignal.WeaponModels)
local UI={} UI.__index=UI
local colors={} for key,value in pairs(Presentation.colors) do colors[key]=U.color(value) end
local function text(parent,txt,size,pos,dims,color,font)
    return U.make("TextLabel",parent,{BackgroundTransparency=1,Text=txt,TextColor3=color or colors.text,
        Font=font or Enum.Font.Gotham,TextSize=size,TextXAlignment=Enum.TextXAlignment.Left,
        TextStrokeTransparency=.96,TextStrokeColor3=colors.bg,
        Position=pos or UDim2.new(),Size=dims or UDim2.fromScale(1,1)})
end
local function frame(parent,size,pos,color)
    local f=U.make("Frame",parent,{Size=size,Position=pos or UDim2.new(),BackgroundColor3=color or colors.panel,BorderSizePixel=0})
    U.make("UICorner",f,{CornerRadius=UDim.new(0,3)}) return f
end
local function button(parent,txt,size,pos,callback,color)
    local b=U.make("TextButton",parent,{Text=txt,Size=size,Position=pos or UDim2.new(),BackgroundColor3=color or colors.panel,
        BorderSizePixel=0,TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,AutoButtonColor=true,Selectable=true})
    U.make("UICorner",b,{CornerRadius=UDim.new(0,3)})
    U.make("UIStroke",b,{Color=colors.muted,Transparency=.82,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    U.make("UIPadding",b,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
    b.Activated:Connect(callback) return b
end
function UI.new(send,onMenu)
    local self=setmetatable({send=send,onMenu=onMenu,selectedMap="Station",selectedMode="Standard",boards={},boardKey="StandardSolo",touch=UIS.TouchEnabled},UI)
    local old=Players.LocalPlayer.PlayerGui:FindFirstChild("DeadSignalHUD") if old then old:Destroy() end
    for _,name in ipairs({"DeadSignalReticle","DeadSignalOptic"}) do local prior=Players.LocalPlayer.PlayerGui:FindFirstChild(name) if prior then prior:Destroy() end end
    local gui=U.make("ScreenGui",Players.LocalPlayer.PlayerGui,{Name="DeadSignalHUD",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=20,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}) self.gui=gui
    self.reticleGui=U.make("ScreenGui",Players.LocalPlayer.PlayerGui,{Name="DeadSignalReticle",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.None,
        IgnoreGuiInset=true,ClipToDeviceSafeArea=false,DisplayOrder=20,Enabled=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    self.hud=U.make("Frame",gui,{Name="CombatHUD",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
    self.roundLabel=text(self.hud,"ROUND",10,nil,nil,colors.muted)
    self.round=text(self.hud,"01",32,UDim2.fromOffset(20,12),UDim2.fromOffset(115,49),colors.text,Enum.Font.GothamBold)
    self.waveInfo=text(self.hud,"SURVIVAL",11,UDim2.fromOffset(22,62),UDim2.fromOffset(200,20),colors.muted)
    self.points=text(self.hud,"500",27,UDim2.new(1,-215,0,16),UDim2.fromOffset(190,38),colors.amber,Enum.Font.GothamBold) self.points.TextXAlignment=Enum.TextXAlignment.Right
    self.ammo=text(self.hud,"12 / 84",self.touch and 18 or 35,self.touch and UDim2.new(.5,-125,1,-66) or UDim2.new(1,-250,1,-67),UDim2.fromOffset(self.touch and 250 or 230,45),colors.text,Enum.Font.GothamBold) self.ammo.TextXAlignment=self.touch and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right
    self.weapon=text(self.hud,"KESTREL 9",12,self.touch and UDim2.new(1,-220,0,106) or UDim2.new(1,-285,1,-89),UDim2.fromOffset(self.touch and 200 or 265,22),colors.muted) self.weapon.TextXAlignment=Enum.TextXAlignment.Right
    self.weapon.Visible=not self.touch
    local healthPos=self.touch and UDim2.fromOffset(20,92) or UDim2.new(0,22,1,-60)
    self.healthBG=frame(self.hud,UDim2.fromOffset(self.touch and 160 or 215,7),healthPos,Color3.fromRGB(44,51,53))
    self.healthBar=frame(self.healthBG,UDim2.fromScale(1,1),nil,colors.cyan)
    self.healthText=text(self.hud,"100",11,self.touch and UDim2.fromOffset(20,105) or UDim2.new(0,22,1,-44),UDim2.fromOffset(250,18),colors.muted)
    self.staminaBG=frame(self.hud,UDim2.fromOffset(self.touch and 160 or 215,3),self.touch and UDim2.fromOffset(20,128) or UDim2.new(0,22,1,-22),Color3.fromRGB(44,51,53))
    self.staminaBar=frame(self.staminaBG,UDim2.fromScale(1,1),nil,colors.amber)
    self.perks=text(self.hud,"",10,self.touch and UDim2.fromOffset(20,139) or UDim2.new(0,22,1,-99),UDim2.fromOffset(self.touch and 210 or 390,32),colors.cyan) self.perks.TextWrapped=true
    self.objective=text(self.hud,"",11,UDim2.new(.5,-235,0,18),UDim2.fromOffset(470,38),colors.muted) self.objective.TextWrapped=true self.objective.TextXAlignment=Enum.TextXAlignment.Center
    self.objective.BackgroundColor3=colors.bg self.objective.BackgroundTransparency=.30
    U.make("UICorner",self.objective,{CornerRadius=UDim.new(0,3)})
    U.make("UIPadding",self.objective,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
    U.make("UIStroke",self.objective,{Color=colors.muted,Transparency=.86,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    U.make("Frame",self.objective,{Name="ObjectiveRule",Size=UDim2.new(0,2,1,-12),Position=UDim2.fromOffset(0,6),BackgroundColor3=colors.amber,BorderSizePixel=0})
    self.team=text(self.hud,"",11,UDim2.fromOffset(22,self.touch and 180 or 106),UDim2.fromOffset(220,90),colors.muted) self.team.TextYAlignment=Enum.TextYAlignment.Top
    self.effects=text(self.hud,"",11,UDim2.new(.5,-220,0,66),UDim2.fromOffset(440,24),colors.amber) self.effects.TextXAlignment=Enum.TextXAlignment.Center
    self.bossBG=frame(self.hud,UDim2.fromOffset(200,4),UDim2.new(.5,-100,0,104),Color3.fromRGB(43,50,53)) self.bossBG.Visible=false
    self.bossBar=frame(self.bossBG,UDim2.fromScale(1,1),nil,colors.red)
    self.bossName=text(self.hud,"WARDEN",10,UDim2.new(.5,-100,0,88),UDim2.fromOffset(200,15),colors.red,Enum.Font.GothamBold) self.bossName.TextXAlignment=Enum.TextXAlignment.Center self.bossName.Visible=false
    self.cross=U.make("Frame",self.reticleGui,{Size=UDim2.fromOffset(40,40),Position=UDim2.new(.5,-20,.5,-20),BackgroundTransparency=1})
    self.crossBars={}
    for _,d in ipairs({{18,6,2,7},{18,27,2,7},{6,18,7,2},{27,18,7,2}}) do self.crossBars[#self.crossBars+1]=frame(self.cross,UDim2.fromOffset(d[3],d[4]),UDim2.fromOffset(d[1],d[2]),colors.text) end
    self.marker=U.make("TextLabel",self.reticleGui,{Text="×",TextSize=36,Font=Enum.Font.Gotham,TextColor3=colors.text,TextTransparency=1,BackgroundTransparency=1,Size=UDim2.fromOffset(60,60),Position=UDim2.new(.5,-30,.5,-30)})
    self.hurt=U.make("Frame",gui,{Name="DamageFlash",Size=UDim2.fromScale(1,1),BackgroundColor3=colors.red,BackgroundTransparency=1,BorderSizePixel=0})
    self.spectate=frame(gui,UDim2.fromOffset(300,42),UDim2.new(.5,-150,1,-70)) self.spectate.Visible=false
    self.spectateText=text(self.spectate,"",12,UDim2.fromOffset(45,0),UDim2.fromOffset(210,42)) self.spectateText.TextXAlignment=Enum.TextXAlignment.Center
    button(self.spectate,"‹",UDim2.fromOffset(38,34),UDim2.fromOffset(4,4),function() if self.cycle then self.cycle(-1) end end)
    button(self.spectate,"›",UDim2.fromOffset(38,34),UDim2.fromOffset(258,4),function() if self.cycle then self.cycle(1) end end)
    self.lobby=U.make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    self.lobbyInfo=text(self.lobby,"WALK INTO A SOLO OR CREW BAY",12,UDim2.new(0,20,1,-105),UDim2.new(1,-40,0,26),colors.muted)
    local bar=U.make("ScrollingFrame",self.lobby,{Size=UDim2.new(1,-32,0,46),Position=UDim2.new(0,16,1,-65),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(540,0),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X})
    for i,item in ipairs({{"DISPATCH","Deploy"},{"ARMORY","Armory"},{"RECORDS","Records"},{"MANUAL","Manual"},{"SETTINGS","Settings"}}) do
        button(bar,item[1],UDim2.fromOffset(100,42),UDim2.fromOffset((i-1)*110,0),function() self:open(item[2]) end,i==1 and colors.red or colors.panel)
    end
    self.queue=text(gui,"",13,UDim2.new(.5,-235,0,15),UDim2.fromOffset(470,35),colors.amber) self.queue.TextXAlignment=Enum.TextXAlignment.Center self.queue.TextWrapped=true
    self.menuButton=button(gui,"≡",UDim2.fromOffset(36,30),UDim2.new(1,-48,0,self.touch and 144 or 70),function() self:toggle() end) self.menuButton.Visible=false
    self.shade=U.make("TextButton",gui,{Name="MenuShade",Size=UDim2.fromScale(1,1),Text="",BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.36,Visible=false,AutoButtonColor=false,BorderSizePixel=0})
    self.panel=frame(self.shade,UDim2.fromOffset(700,460),UDim2.new(.5,-350,.5,-230),colors.bg)
    U.make("UIStroke",self.panel,{Color=colors.muted,Transparency=.65,Thickness=1})
    frame(self.panel,UDim2.new(1,-44,0,2),UDim2.fromOffset(22,57),colors.cyan)
    self.title=text(self.panel,"OPERATOR TERMINAL",18,UDim2.fromOffset(22,15),UDim2.new(1,-94,0,36),colors.text,Enum.Font.GothamBold) self.title.TextWrapped=true
    button(self.panel,"×",UDim2.fromOffset(44,40),UDim2.new(1,-59,0,13),function() self:close() end)
    self.content=U.make("ScrollingFrame",self.panel,{Position=UDim2.fromOffset(20,66),Size=UDim2.new(1,-40,1,-86),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=colors.muted})
    self.bannerFrame=frame(gui,UDim2.fromOffset(560,68),UDim2.new(.5,-280,.2,0),colors.bg) self.bannerFrame.Visible=false
    self.bannerText=text(self.bannerFrame,"",20,UDim2.fromOffset(18,0),UDim2.new(1,-36,1,0),colors.red,Enum.Font.GothamBold) self.bannerText.TextWrapped=true self.bannerText.TextXAlignment=Enum.TextXAlignment.Center
    self.toastFrame=frame(gui,UDim2.fromOffset(420,48),UDim2.new(.5,-210,.75,0),colors.bg) self.toastFrame.Visible=false
    self.toastText=text(self.toastFrame,"",13,UDim2.fromOffset(12,0),UDim2.new(1,-24,1,0),colors.amber) self.toastText.TextWrapped=true self.toastText.TextXAlignment=Enum.TextXAlignment.Center
    self.loading=LoadingScreen.new(gui) self.travelLayer=self.loading.frame
    self.loading:set(PC.Role=="Match" and PC.Map or "Lobby","Establishing uplink",PC.Role=="Match")
    self.extractionBar=frame(self.objective,UDim2.fromScale(0,0),UDim2.new(0,0,1,-3),colors.cyan)
    local function resize()
        local v=self.hud.AbsoluteSize if not v or v.X<1 then v=workspace.CurrentCamera.ViewportSize end
        local layout=Presentation.layout(v.X,v.Y,self.touch) self.layout=layout
        local function fit(obj,r) obj.Size=UDim2.fromOffset(r.w,r.h) obj.Position=UDim2.fromOffset(r.x,r.y) end
        for key,obj in pairs({round=self.round,roundLabel=self.roundLabel,waveInfo=self.waveInfo,points=self.points,
            menu=self.menuButton,health=self.healthBG,healthText=self.healthText,stamina=self.staminaBG,perks=self.perks,
            objective=self.objective,team=self.team,effects=self.effects,ammo=self.ammo,weapon=self.weapon,
            boss=self.bossBG,bossName=self.bossName,panel=self.panel}) do fit(obj,layout[key]) end
        self.ammo.TextSize=layout.compact and 22 or 32 self.ammo.TextXAlignment=layout.compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right
        self.weapon.Visible=true self.weapon.TextSize=10 self.weapon.TextXAlignment=layout.compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right
        self.points.TextSize=20 self.objective.TextSize=12 self.weapon.TextSize=11
        self.team.TextSize=11 self.team.TextWrapped=layout.narrow or not layout.compact self.healthText.TextSize=11 self.perks.TextSize=10
        local bw=math.min(560,v.X-32) self.bannerFrame.Size=UDim2.fromOffset(bw,68) self.bannerFrame.Position=UDim2.new(.5,-bw/2,.2,0)
        local tw=math.min(420,v.X-32) self.toastFrame.Size=UDim2.fromOffset(tw,48) self.toastFrame.Position=UDim2.new(.5,-tw/2,.75,0)
        self.objective.Visible=true self.effects.Visible=true self.team.Visible=true
    end
    self.hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) resize()
    return self
end
function UI:clearContent()
    for _,obj in ipairs(self.content:GetChildren()) do obj:Destroy() end
    self.content.CanvasPosition=Vector2.new(0,0)
    U.make("UIListLayout",self.content,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
    self.order=0 self.firstButton=nil
end
function UI:row(height)
    self.order=self.order+1
    local r=frame(self.content,UDim2.new(1,-8,0,height),nil,colors.panel) r.LayoutOrder=self.order return r
end
function UI:paragraph(value,color)
    self.order=self.order+1
    local t=text(self.content,value,13,nil,UDim2.new(1,-8,0,0),color or colors.muted)
    t.AutomaticSize=Enum.AutomaticSize.Y t.TextWrapped=true t.LayoutOrder=self.order return t
end
function UI:choice(label,callback,color)
    local row=self:row(self.touch and 48 or 44)
    local b=button(row,label,UDim2.fromScale(1,1),nil,callback,color)
    if not self.firstButton then self.firstButton=b end return b
end
function UI:mapCard(id,selected,callback)
    local def=C.Maps[id] local row=self:row(104)
    local b=button(row,"",UDim2.fromScale(1,1),nil,callback,selected and Color3.fromRGB(42,49,49) or colors.panel)
    local asset=tostring(C.MapArtworkIds[id] or "")
    if asset~="" then
        local image=U.make("ImageLabel",b,{Name="MapKeyArt",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=asset:match("rbxassetid://") and asset or "rbxassetid://"..asset,ScaleType=Enum.ScaleType.Crop,ImageTransparency=.45})
        U.make("UIGradient",image,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.75),NumberSequenceKeypoint.new(1,0)})})
    end
    frame(b,UDim2.fromOffset(3,80),UDim2.fromOffset(0,12),selected and colors.amber or colors.muted)
    local heading=text(b,string.upper(def.name),18,UDim2.fromOffset(18,14),UDim2.new(1,-36,0,26),colors.text,Enum.Font.GothamBold) heading.ZIndex=2
    local copy=text(b,def.subtitle.."\n"..def.description,12,UDim2.fromOffset(18,43),UDim2.new(1,-36,0,51),colors.muted) copy.TextWrapped=true copy.ZIndex=2
    if not self.firstButton then self.firstButton=b end return b
end
function UI:arsenalPreview(id,skin)
    local def=C.Weapons[id] local row=self:row(self.touch and 182 or 210)
    local viewport=U.make("ViewportFrame",row,{Name="ArsenalModel",Size=UDim2.fromScale(.65,1),Position=UDim2.fromScale(.35,0),
        BackgroundTransparency=1,Ambient=Color3.fromRGB(130,137,143),LightColor=Color3.fromRGB(234,218,190),LightDirection=Vector3.new(-1,-.7,-.4)})
    local world=U.make("WorldModel",viewport,{Name="WeaponDisplay"}) local model=WeaponModels.build(id,skin or "Factory",0,world,false)
    model:PivotTo(CFrame.new())
    local camera=U.make("Camera",viewport,{FieldOfView=45,CFrame=CFrame.lookAt(Vector3.new(4,1.8,-4.4),Vector3.new(0,-.08,0))}) viewport.CurrentCamera=camera
    text(row,def.class:upper(),10,UDim2.fromOffset(16,16),UDim2.new(.42,0,0,20),colors.amber)
    local name=text(row,def.name:upper(),19,UDim2.fromOffset(16,43),UDim2.new(.46,0,0,58),colors.text,Enum.Font.GothamBold) name.TextWrapped=true name.TextYAlignment=Enum.TextYAlignment.Top
    text(row,def.mag.." ROUND MAGAZINE",10,UDim2.new(0,16,1,-55),UDim2.new(.45,0,0,20),colors.muted)
    text(row,def.upgraded,10,UDim2.new(0,16,1,-33),UDim2.new(.45,0,0,22),colors.amber)
end
function UI:close()
    self.shade.Visible=false self.tab=nil GuiService.SelectedObject=nil
    self.reticleGui.Enabled=self.hud.Visible
    if self.onMenu then self.onMenu(false) end
end
function UI:toggle() if self.shade.Visible then self:close() else self:open(self.state and self.state.participating and "Operation" or "Deploy") end end
function UI:ownBay()
    local dispatch=self.state and self.state.dispatch
    if not dispatch or not dispatch.own then return nil end
    for _,b in ipairs(dispatch.bays) do if b.id==dispatch.own then return b end end
end
function UI:bayKey(state)
    local d=state and state.dispatch if not d or not d.own then return "" end
    for _,b in ipairs(d.bays) do if b.id==d.own then
        local ids={} for _,m in ipairs(b.members) do table.insert(ids,m.id..":"..tostring(m.present)) end
        return b.id..":"..b.state..":"..b.map..":"..b.mode..":"..tostring(b.leader)..":"..tostring(b.friendsOnly)..":"..table.concat(ids,",")..":"..(b.error or "")
    end end return ""
end
function UI:bayContent()
    local b=self:ownBay()
    self.title.Text=b and b.name.." / "..#b.members.." OF "..b.max or "DISPATCH BAYS"
    if not b then self:paragraph("Walk into a glowing bay to board. The two cyan bays are solo. Amber crew bays need 2–4 operators. You can explore Dispatch before joining.") return end
    local leader=b.leader==Players.LocalPlayer.UserId
    local members={} for _,m in ipairs(b.members) do table.insert(members,(m.id==b.leader and "LEADER • " or "")..m.name..(m.present and "" or " / returning")) end
    self:paragraph(table.concat(members,"\n"),colors.text)
    self:paragraph(C.Maps[b.map].name.." / "..C.Modes[b.mode].name.." / "..(b.friendsOnly and "Friends only" or "Public"),colors.cyan)
    if b.state=="Countdown" then self:paragraph("Departure countdown is running. Leaving cancels the countdown.",colors.amber)
        if leader then self:choice("CANCEL COUNTDOWN",function() self.send("BayCancel",{}) end) end
    elseif b.state=="Departing" or b.state=="Away" then self:paragraph("Dispatch is preparing your operation.",colors.amber)
    else
        if b.state=="Held" then self:paragraph("Your crew is regrouping. The leader starts the next trip when everyone is ready. Returning does not start another operation automatically.",colors.amber) end
        if leader then
            for _,id in ipairs(C.MapOrder) do
                local def=C.Maps[id]
                self:mapCard(id,b.map==id,function() self.send("BaySetting",{map=id}) end)
            end
            self:choice("MODE: "..C.Modes[b.mode].name.." / CHANGE",function() self.send("BaySetting",{mode=b.mode=="Standard" and "Lockdown" or "Standard"}) end)
            if b.max>1 then self:choice("CREW: "..(b.friendsOnly and "FRIENDS ONLY" or "PUBLIC").." / CHANGE",function() self.send("BaySetting",{friendsOnly=not b.friendsOnly}) end) end
            self:choice("START OPERATION",function() self.send("BayStart",{}) self:close() end,colors.red)
            if b.state=="Held" then self:choice("RELEASE MISSING SEATS",function() self.send("BayRelease",{}) end) end
        else self:paragraph("The leader chooses the operation and starts the countdown.") end
    end
    if b.error then self:paragraph(b.error,colors.amber) end
    self:paragraph("Perks need restored power and later rounds. Each perk already held adds 250 points to your next purchase.")
    self:choice("LEAVE BAY",function() self.send("BayLeave",{}) self:close() end)
end
function UI:open(tab)
    self.tab=tab self.shade.Visible=true self:clearContent()
    self.reticleGui.Enabled=false
    if self.onMenu then self.onMenu(true) end
    local p=self.profile or {credits=0,rank=1,skins={Factory=true},skin="Factory",best={},daily={claimed={}},achievements={},settings=C.DefaultSettings}
    if tab=="Bay" or (tab=="Deploy" and self.state and self.state.role=="Lobby") then
        self:bayContent()
        if not self:ownBay() then self:choice("FIELD MANUAL",function() self:open("Manual") end) self:choice("CAREER TASKS",function() self:open("Tasks") end) end
    elseif tab=="Deploy" and self.state and self.state.role=="Match" then
        self.title.Text="SIGNAL SHELTER"
        self:paragraph(self.state.status=="Rejected" and "Board a dispatch bay to join a valid operation." or "Your crew is arriving. Eliminated operators rejoin after a cleared round.")
        self:choice("RETURN TO DISPATCH",function() self.send("Leave",{}) self:close() end,colors.red)
    elseif tab=="Deploy" then
        self.title.Text="CHOOSE YOUR OPERATION"
        self:paragraph("Solo or cooperative • Four operators maximum • Use match points for equipment. Field credits buy permanent cosmetic finishes.")
        for _,id in ipairs(C.MapOrder) do
            self:mapCard(id,self.selectedMap==id,function() self.selectedMap=id self:open("Deploy") end)
        end
        self:choice("MODE: "..C.Modes[self.selectedMode].name.."  /  change",function() self.selectedMode=self.selectedMode=="Standard" and "Lockdown" or "Standard" self:open("Deploy") end)
        self:paragraph(self.selectedMode=="Lockdown" and "Lockdown: tougher infected, stronger attacks, no solo automatic revives, increased XP." or "Survival: the classic experience. Solo Lifeline provides up to three automatic revives per run.")
        self:choice(self.state and self.state.ready and "CANCEL DEPLOYMENT" or "READY TO DEPLOY",function() self.send("Queue",{ready=not (self.state and self.state.ready),map=self.selectedMap,mode=self.selectedMode}) self:close() end,colors.red)
    elseif tab=="Operation" then
        self.title.Text="OPERATOR MENU"
        self:choice("RESUME",function() self:close() end,colors.red)
        self:paragraph(self.state and self.state.objective or "Survive and restore the signal.",colors.cyan)
        self:choice("SETTINGS",function() self:open("Settings") end)
        self:paragraph("The operation continues while this menu is open. Open doors to create training routes. Pick four perks. A teammate can revive you before your timer expires. Eliminated operators return after a cleared round.")
        self:paragraph("PC: mouse fire / right mouse aim • R reload • 1/2 or Q swap • V melee • G grenade • Shift sprint • E interact • M menu. Controller: RT fire • LT aim • Y reload • B swap • R3 melee • RB grenade • L3 sprint • X interact • Select menu.")
        self:choice("RETURN TO DISPATCH",function() self.send("Leave",{}) self:close() end)
    elseif tab=="Armory" then
        self.title.Text="ARMORY / "..p.credits.." FIELD CREDITS"
        self:arsenalPreview(self.selectedWeapon or "Carbine",p.skin)
        self:paragraph("Finishes apply to every weapon. Earn credits by playing, completing tasks, and extracting.")
        for _,skin in ipairs(C.Skins) do
            local row=self:row(64) frame(row,UDim2.fromOffset(36,36),UDim2.fromOffset(10,14),U.color(skin.color))
            text(row,skin.name,14,UDim2.fromOffset(56,10),UDim2.new(1,-195,0,24),colors.text,Enum.Font.GothamBold)
            text(row,p.skins[skin.id] and "OWNED" or skin.cost.." credits",11,UDim2.fromOffset(56,34),UDim2.new(1,-195,0,20),colors.muted)
            button(row,p.skin==skin.id and "EQUIPPED" or (p.skins[skin.id] and "EQUIP" or "UNLOCK"),UDim2.fromOffset(100,36),UDim2.new(1,-112,0,14),function() self.send(p.skins[skin.id] and "EquipSkin" or "BuySkin",{id=skin.id}) end)
        end
        self:choice("WEAPON CATALOG",function() self:open("Weapons") end)
    elseif tab=="Weapons" then
        self.title.Text="FIELD ARSENAL / 20 WEAPONS"
        self:arsenalPreview(self.selectedWeapon or "Carbine",p.skin)
        self:paragraph("Inspect your next weapon. Find wall weapons in each sector or try Unknown Supply. Resonance upgrades increase damage and ammunition.")
        local ordered={} for id in pairs(C.Weapons) do table.insert(ordered,id) end table.sort(ordered)
        for _,id in ipairs(ordered) do local w=C.Weapons[id]
            self:choice(w.name.."  /  "..w.class.."  /  "..w.mag.." RDS",function() self.selectedWeapon=id self:open("Weapons") end,self.selectedWeapon==id and Color3.fromRGB(50,46,36) or colors.panel)
        end
        self:choice("BACK TO ARMORY",function() self:open("Armory") end)
    elseif tab=="Manual" then
        self.title.Text="FIELD MANUAL / BREAK THE SIGNAL"
        self:paragraph("1. Start in a solo or crew bay. Your leader picks the map, difficulty, and departure.\n2. Survive the early rounds, buy a second weapon, and open routes.\n3. Restore power. Earn perks as their round requirements unlock.\n4. Collect three fuses, install them, match the frequency dials, and verify at the transmitter.\n5. Upgrade at the Resonance Forge. Reach round 15 to vote for extraction, or keep surviving.",colors.text)
        self:paragraph("PERK REQUIREMENTS / POWER MUST BE ON",colors.amber)
        self:paragraph("EXTRACTION / After the vote, eliminate the Warden, clear nearby threats, and bring every surviving operator to the tall rescue beacon. Hold the zone for 12 seconds. Boarding pauses while contested or while crew members are outside. Downed crew inside the beacon can board with a survivor. The HUD shows the exact remaining condition and countdown.",colors.text)
        for _,key in ipairs(C.PerkOrder) do local perk=C.Perks[key]
            self:paragraph(perk.name.." • Round "..perk.round.." • "..perk.price.." points"..(key=="Lifeline" and " / solo: round 2, 1000 points" or "").."\n"..perk.description)
        end
        self:paragraph("Match points: 60 per kill, 90 for a headshot. Damage earns 2 points with a 10-point cap per enemy. Repairs pay 5, capped at 30 per round. Keep an ammo reserve; the Kestrel refill costs 225.")
        self:paragraph("Four perk limit. Each perk already held adds 250 points to the next. Perks are lost when downed; teammates can still revive you without buying Lifeline.")
        self:paragraph("PC: mouse fire / right mouse aim • R reload • Q or 1/2 swap • V melee • G grenade • Shift sprint • E interact. Controller: RT / LT • Y reload • B swap • R3 melee • RB grenade • L3 sprint • X interact. M / Select opens the menu.")
        self:choice("CAREER TASKS",function() self:open("Tasks") end)
    elseif tab=="Records" then
        self.title.Text="OPERATOR RECORDS / RANK "..(p.rank or 1)
        self:paragraph((p.kills or 0).." lifetime kills • "..(p.headshots or 0).." headshots • "..(p.revives or 0).." revives • "..(p.extractions or 0).." extractions")
        self:paragraph("XP "..(p.xp or 0).." / "..R.rankFloor((p.rank or 1)+1).." for next rank. "..(p.status or ""))
        for _,key in ipairs({"StandardSolo","StandardSquad","LockdownSolo","LockdownSquad"}) do
            self:choice((key:gsub("Standard","Survival "):gsub("Lockdown","Lockdown ")).."  /  Personal: "..(p.best[key] or 0),function() self.boardKey=key self:open("Records") end,self.boardKey==key and Color3.fromRGB(42,63,65) or colors.panel)
        end
        self:paragraph("GLOBAL / "..self.boardKey,colors.cyan)
        local rows=self.boards[self.boardKey] or {}
        if #rows==0 then self:paragraph("No global results available yet. Your personal record updates after each operation.") end
        for i,row in ipairs(rows) do self:paragraph(i..". "..row.name.." — round "..row.round,colors.text) end
        if os.clock()-(self.lastBoards or -30)>10 then self.lastBoards=os.clock() self.send("Boards",{}) end
    elseif tab=="Tasks" then
        self.title.Text="FIELD TASKS"
        self:paragraph("Daily progress and rewards settle at the end of an operation. Daily tasks reset at midnight UTC.")
        for _,goal in ipairs(C.DailyGoals) do local d=p.daily or {} local done=d.claimed and d.claimed[goal.id]
            self:paragraph((done and "✓ " or "○ ")..goal.name.."  "..math.min(d[goal.id] or 0,goal.target).."/"..goal.target.."  • "..goal.credits.." credits",done and colors.cyan or colors.text)
        end
        self:paragraph("CAREER ACHIEVEMENTS",colors.amber)
        for _,key in ipairs({"FirstShift","LongNight","Deadeye","Guardian","Technician","Homebound","LoneWolf"}) do local a=C.Achievements[key]
            self:paragraph((p.achievements[key] and "✓ " or "○ ")..a.name.." • "..a.description.." • "..a.credits.." credits",p.achievements[key] and colors.cyan or colors.muted)
        end
    elseif tab=="Settings" then
        self.title.Text="FIELD SETTINGS"
        local settings=p.settings or C.DefaultSettings
        for _,item in ipairs({{"volume","Volume",.1,0,1},{"fov","Field of view",5,70,95},{"shake","Camera shake",.25,0,1}}) do
            local row=self:row(44) local key,label,step,min,max=table.unpack(item)
            text(row,label..": "..tostring(U.round(settings[key]*100)/100),13,UDim2.fromOffset(12,0),UDim2.new(1,-110,1,0))
            button(row,"−",UDim2.fromOffset(36,32),UDim2.new(1,-88,0,6),function() self.send("Setting",{key=key,value=math.max(min,settings[key]-step)}) end)
            button(row,"+",UDim2.fromOffset(36,32),UDim2.new(1,-44,0,6),function() self.send("Setting",{key=key,value=math.min(max,settings[key]+step)}) end)
        end
        for _,item in ipairs({{"aimAssist","Touch / controller aim assist"},{"hitmarkers","Hit markers"},{"lowEffects","Reduced effects"}}) do
            self:choice(item[2]..": "..(settings[item[1]] and "ON" or "OFF"),function() self.send("Setting",{key=item[1],value=not settings[item[1]]}) end)
        end
        self:paragraph("MOBILE FIRING · Tap is the initial trial layout. Compare on your phone and switch freely.",colors.cyan)
        for _,item in ipairs({{"Tap","Tap screen to shoot"},{"Left","Left fire zone"},{"Classic","Classic fire + drag"}}) do
            local key,label=table.unpack(item)
            self:choice((settings.fireLayout==key and "✓ " or "")..label,function() self.send("Setting",{key="fireLayout",value=key}) end)
        end
        self:paragraph("Tap: short right-side tap fires at that exact spot; swipe only looks. Automatic weapons can hold after a short delay. Left: hold the stick above its outer edge to arm fire, then keep moving; center or release to stop. Classic: hold Fire and drag that same thumb to aim.")
        self:paragraph("AIM ASSIST · Separate from firing layout",colors.cyan)
        for _,item in ipairs({{"Assisted","Assisted · stronger slowdown"},{"Manual","Manual · light assist"},{"Advanced","Advanced · no tracking assist"}}) do
            local key,label=table.unpack(item)
            self:choice((settings.assistPreset==key and "✓ " or "")..label,function() self.send("Setting",{key="assistPreset",value=key}) end)
        end
        self:choice("Optional auto-fire: "..(settings.autoFire and "ON" or "OFF"),function() self.send("Setting",{key="autoFire",value=not settings.autoFire}) end)
        self:paragraph("Auto-fire needs Assisted mode and a visible enemy under the center sight. Direct screen taps never snap to another target.")
        for _,item in ipairs({{"Outer","Outer stick · move + aim + fire"},{"Toggle","Left pad toggle · tap again to stop"},{"Pad","Left pad hold · separate from movement"}}) do
            local key,label=table.unpack(item)
            self:choice((settings.leftGesture==key and "✓ " or "")..label,function() self.send("Setting",{key="leftGesture",value=key}) end)
        end
        self:paragraph("A separate left pad cannot be held with the same thumb as the movement stick. Use Outer or Toggle for two-thumb play. Orange controls and the FIRING label show active fire.")
        for _,item in ipairs({{"lookSensitivity","Look sensitivity",.15,.25,2.5},{"verticalSensitivity","Vertical sensitivity",.15,.25,2.5},
            {"adsSensitivity","ADS sensitivity",.1,.2,1.5},{"scopeSensitivity","Scoped sensitivity",.1,.1,1.2},
            {"tapHoldTime","Auto hold delay",.05,.28,.65},{"tapSlop","Tap / swipe tolerance",2,6,24},
            {"gyroSensitivity","Gyro sensitivity",.1,.1,2}}) do
            local row=self:row(44) local key,label,step,min,max=table.unpack(item) local value=settings[key] or C.DefaultSettings[key]
            text(row,label..": "..tostring(U.round(value*100)/100),13,UDim2.fromOffset(12,0),UDim2.new(1,-110,1,0))
            button(row,"−",UDim2.fromOffset(36,32),UDim2.new(1,-88,0,6),function() self.send("Setting",{key=key,value=math.max(min,value-step)}) end)
            button(row,"+",UDim2.fromOffset(36,32),UDim2.new(1,-44,0,6),function() self.send("Setting",{key=key,value=math.min(max,value+step)}) end)
        end
        for _,item in ipairs({{"leftHanded","Mirror touch layout"},{"tapHold","Hold in Tap mode for automatic fire"},{"invertY","Invert vertical look"},{"gyroAim","Gyroscope fine aim (supported devices)"}}) do
            self:choice(item[2]..": "..(settings[item[1]] and "ON" or "OFF"),function() self.send("Setting",{key=item[1],value=not settings[item[1]]}) end)
        end
        if self.editTouch then self:choice("EDIT HUD · drag / resize / opacity / reset",function() self.editTouch() end) end
        if self.touchSummary then
            local summary=self.touchSummary()
            for _,key in ipairs({"Tap","Left","Classic"}) do local a=summary.samples[key]
                if a then self:paragraph(key..": "..math.floor(a.seconds).."s · "..a.accepted.." local shots · "..a.hits.." server hit confirmations") end
            end
            self:choice("RESET COMPARISON SAMPLE",function() if self.resetTouchSample then self.resetTouchSample() self:open("Settings") end end)
        end
        self:paragraph("Reloading, swapping, menus and downing cancel held or toggled fire. Re-engage the gesture to fire again. Reduced effects lowers decorative particles and camera shake.")
        self:choice("BACK",function() self:open(self.state and self.state.participating and "Operation" or "Deploy") end)
    end
    if UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 and self.firstButton then GuiService.SelectedObject=self.firstButton end
end
function UI:setProfile(profile)
    self.profile=profile
    if self.shade.Visible and self.tab~="Results" then self:open(self.tab) end
end
function UI:setState(state,displayMag)
    local previous=self.state self.state=state
    if previous and previous.status~=state.status and (state.status=="Lobby" or previous.status=="Lobby") then self:close() end
    self.hud.Visible=state.participating and state.status~="Results"
    self.reticleGui.Enabled=self.hud.Visible and not self.shade.Visible
    self.lobby.Visible=not state.participating self.menuButton.Visible=state.participating and state.status~="Results"
    self.queue.Visible=not state.participating
    local bay=self:ownBay()
    self.queue.Text=bay and (bay.name.." / "..(bay.state=="Countdown" and "DEPARTING IN "..bay.timer.."s" or bay.state:upper()).." • OPEN DISPATCH FOR CONTROLS") or (state.role=="Match" and not state.participating and "WAITING FOR YOUR CREW" or "")
    if self.tab=="Bay" or (self.tab=="Deploy" and state.role=="Lobby") then
        if self:bayKey(previous)~=self:bayKey(state) then self:open(self.tab) end
    end
    self.round.Text=string.format("%02d",state.round)
    self.waveInfo.Text=(state.phase=="Intermission" or state.phase=="Preparing") and "NEXT ROUND / "..state.timer.."s" or (state.phase=="Exfil" and "RESCUE / "..state.timer.."s" or state.left.." INFECTED REMAINING")
    self.points.Text=tostring(state.points).."  P"
    self.healthBar.Size=UDim2.fromScale(math.clamp(state.health/state.maxHealth,0,1),1)
    self.staminaBar.Size=UDim2.fromScale(math.clamp(state.stamina/state.maxStamina,0,1),1)
    self.healthText.Text=state.status=="Down" and ((state.autoRevive and "LIFELINE ACTIVATING" or "HOLD ON • REVIVE NEEDED").." / "..state.downLeft.."s") or state.health.." HP"
    self.healthBar.BackgroundColor3=state.health<45 and colors.red or colors.cyan
    local names={} for _,key in ipairs(C.PerkOrder) do if state.perks[key] then table.insert(names,C.Perks[key].name) end end self.perks.Text=table.concat(names,"  •  ")
    local x=state.extraction
    self.objective.Text=x and (x.title.." · "..math.floor(x.progress).."%\n"..x.inside.."/"..x.alive.." AT BEACON · "..math.floor(x.distance).." STUDS") or state.objective
    self.objective.TextColor3=x and (x.contested and colors.red or colors.amber) or colors.muted
    self.extractionBar.Size=UDim2.new(x and math.clamp(x.progress/100,0,1) or 0,0,0,3)
    self.bossBG.Visible=state.boss~=nil self.bossName.Visible=state.boss~=nil
    if state.boss then self.bossBar.Size=UDim2.fromScale(math.clamp(state.boss.hp/state.boss.max,0,1),1)
        self.bossName.Text="WARDEN / "..(state.boss.overload and "ARMOR OVERLOAD" or "PHASE "..(state.boss.phase or 1))
    end
    local ef={} for key,expiry in pairs(state.effects) do if expiry>state.serverTime then table.insert(ef,C.Powerups[key].name.." "..math.ceil(expiry-state.serverTime).."s") end end
    if x then table.insert(ef,x.stage=="Board" and "HOLD POSITION" or x.stage=="Warden" and "KILL THE WARDEN" or x.stage=="Clear" and "ZONE CONTESTED" or "FOLLOW THE RESCUE BEACON") end self.effects.Text=table.concat(ef,"   ")
    local rows={} local down=false for _,p in ipairs(state.team) do if p.id~=Players.LocalPlayer.UserId then
        down=down or p.status=="Down"
        table.insert(rows,p.name.."  /  "..(p.status=="Alive" and "ACTIVE" or p.status=="Down" and "REVIVE NEEDED" or p.status:upper()))
    end end self.team.Text=table.concat(rows,"\n") self.team.TextColor3=down and colors.amber or colors.muted
    if self.layout and self.layout.compact and not self.layout.narrow then
        local downNames={} local active=0
        for _,p in ipairs(state.team) do if p.id~=Players.LocalPlayer.UserId then
            if p.status=="Down" then table.insert(downNames,p.name) elseif p.status=="Alive" then active=active+1 end
        end end
        self.team.Text=#downNames>0 and "REVIVE: "..table.concat(downNames,", ") or "CREW / "..active.." ACTIVE"
    end
    self.cross.Visible=state.status=="Alive" and not self.shade.Visible
    self.spectate.Visible=state.status=="Eliminated" and not self.shade.Visible
    self.loading:update(state)
    local gun=state.guns[state.slot] if gun then
        local stat=R.weaponStats(C.Weapons[gun.id],gun.tier,state.perks)
        self.ammo.Text=gun.reloadUntil>state.serverTime and "RELOADING" or (displayMag or gun.mag).." / "..gun.reserve
        self.weapon.Text=string.upper(stat.name).."   /   "..state.grenades.." GRENADES"
    end
    local p=self.profile self.lobbyInfo.Text="DISPATCH"..(p and "  /  RANK "..p.rank.."  /  "..p.credits.." FIELD CREDITS" or "  /  PROFILE LOADING")..(bay and "" or "  /  WALK INTO A BAY")
end
function UI:travel(data)
    self.loading:set(data.map or "Lobby",data.message,data.active)
    if not data.active and self.state and self.state.role=="Match" then
        if self.state.phase=="Results" and self.lastResults then self:results(self.lastResults)
        else self:open("Deploy") end
    end
end
function UI:loadingGui(message,map)
    local gui=U.make("ScreenGui",nil,{Name="DeadSignalTravel",IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,ClipToDeviceSafeArea=false,DisplayOrder=1000,ResetOnSpawn=false})
    LoadingScreen.new(gui):set(map or "Lobby",message,true)
    return gui
end
function UI:toast(value,color)
    self.toastToken=(self.toastToken or 0)+1 local token=self.toastToken
    self.toastText.Text=value self.toastText.TextColor3=colors[color] or colors.amber self.toastFrame.Visible=true
    task.delay(3.3,function() if self.toastToken==token then self.toastFrame.Visible=false end end)
end
function UI:banner(value,color)
    self.bannerToken=(self.bannerToken or 0)+1 local token=self.bannerToken
    self.bannerText.Text=value self.bannerText.TextColor3=colors[color] or colors.red self.bannerFrame.Visible=true
    task.delay(3.5,function() if self.bannerToken==token then self.bannerFrame.Visible=false end end)
end
function UI:hit(kill,head)
    if self.profile and not self.profile.settings.hitmarkers then return end
    self.marker.TextColor3=kill and colors.red or (head and colors.cyan or colors.text) self.marker.TextTransparency=0
    Tween:Create(self.marker,TweenInfo.new(.22),{TextTransparency=1}):Play()
end
function UI:damage()
    self.hurt.BackgroundTransparency=.78 Tween:Create(self.hurt,TweenInfo.new(.5),{BackgroundTransparency=1}):Play()
end
function UI:results(payload)
    self.lastResults=payload
    self:open("Results") self.title.Text=payload.win and "CREW EXTRACTED" or payload.extraction and "EXTRACTION FAILED" or "OPERATION LOST"
    self:paragraph(payload.reason,payload.win and colors.cyan or colors.red)
    if payload.extraction then self:paragraph((payload.extraction.wardenDefeated and "Warden eliminated" or "Warden survived").." / Boarding "..math.floor(payload.extraction.progress or 0).."%",colors.amber) end
    self:paragraph("Round "..payload.round.." reached • "..payload.stats.rounds.." rounds cleared",colors.text)
    self:paragraph(payload.stats.kills.." kills • "..payload.stats.headshots.." headshots • "..payload.stats.revives.." revives",colors.text)
    self:paragraph("+"..payload.reward.xp.." XP   /   +"..payload.reward.credits.." FIELD CREDITS",colors.amber)
    for _,a in ipairs(payload.reward.achievements) do self:paragraph("UNLOCKED: "..a,colors.cyan) end
    self:paragraph("Returning to Dispatch in 14 seconds. Your earned progress is being saved. Your crew's bay will wait for an explicit restart.")
    local returnButton=self:choice("RETURN TO DISPATCH",function() self.send("Leave",{}) self:close() end,colors.red)
    if UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 then GuiService.SelectedObject=returnButton end
end
return UI
