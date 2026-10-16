local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local PPS=game:GetService("ProximityPromptService")
local C=require(RS:WaitForChild("DeadSignal"):WaitForChild("Config"))
local R=require(RS.DeadSignal.Rules)
local U=require(RS.DeadSignal.Util)
local W=require(RS.DeadSignal.WeaponModels)
local Movement=require(RS.DeadSignal.Movement)
local Downed=require(RS.DeadSignal.DownedPose)
local ThirdPerson=require(RS.DeadSignal.ThirdPerson)
local Scope=require(script.Parent.Scope)
local UI=require(script.Parent.UI)
local FX=require(script.Parent.Effects)
local MobileControls=require(script.Parent.MobileControls)
local AimAssist=require(script.Parent.AimAssist)
local Controller={}
function Controller.start()
    local player=Players.LocalPlayer
    if player.PlayerGui:FindFirstChild("DeadSignalHUD") then return end
    local remotes=RS.DeadSignal:WaitForChild("Remotes") local action=remotes:WaitForChild("Action") local feed=remotes:WaitForChild("Feed")
    local s={state=nil,profile=nil,fire=false,aim=false,sprint=false,menu=false,nextShot=0,seq=0,pending={},slot=1,guns={},recoil=0,vm=nil,vmKey="",spectateIndex=1,semi=false,reloading=0,meleeAt=0,reloadStarted=0,reloadDuration=1,equipAt=0}
    local fx=FX.new() local ui local aimAlpha=0
    local function send(op,args) action:FireServer(op,args or {}) end
    local controls local mobile
    task.spawn(function() local pm=player.PlayerScripts:WaitForChild("PlayerModule",10) if pm then local ok,result=pcall(function() return require(pm):GetControls() end) if ok then controls=result end end end)
    local function resetInput()
        if mobile then mobile:cancel("input reset") end
        s.fire=false s.aim=false s.sprint=false s.semi=false
        send("Aim",{enabled=false}) send("Sprint",{enabled=false})
    end
    ui=UI.new(send,function(open)
        s.menu=open resetInput()
        if controls then if open then controls:Disable() else controls:Enable() end end
    end)
    pcall(function()
        local arriving=game:GetService("TeleportService"):GetArrivingTeleportGui()
        if arriving then ui.loading:set(ui.loading.map,"Completing arrival",true) arriving:Destroy() end
        game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
    end)
    local optic=Scope.new(ui.gui)
    CAS:BindActionAtPriority("DeadSignal_NoJump",function() return Enum.ContextActionResult.Sink end,false,3000,Enum.PlayerActions.CharacterJump)
    local function noJump(char)
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then Movement.noJump(hum,player) end
        local touch=player.PlayerGui:FindFirstChild("TouchGui")
        if touch then for _,obj in ipairs(touch:GetDescendants()) do if obj.Name=="JumpButton" and obj:IsA("GuiObject") then obj.Visible=false end end end
    end
    if player.Character then noJump(player.Character) end
    RunService.PreSimulation:Connect(function()
        for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then ThirdPerson.client(plr.Character) Downed.client(plr.Character,plr==player) end end
    end)
    local function living() return s.state and s.state.status=="Alive" and s.state.participating and not s.menu and not s.state.travelling and not s.travelLock and not ui.loading.frame.Visible and (s.state.phase=="Wave" or s.state.phase=="Preparing" or s.state.phase=="Intermission" or s.state.phase=="Exfil") end
    local function gun() return s.guns[s.slot] end
    local function displayMag()
        local g=gun() if not g then return 0 end local pending=0
        for _,v in pairs(s.pending) do if v.slot==s.slot and v.id==g.id then pending=pending+1 end end
        return math.max(0,g.mag-pending)
    end
    local function ammo(data)
        local oldSlot=s.slot local oldGun=s.guns[s.slot]
        s.guns=data.guns or s.guns s.slot=data.slot or s.slot
        local newGun=s.guns[s.slot]
        if mobile and (oldSlot~=s.slot or (oldGun and newGun and oldGun.id~=newGun.id)) then mobile:cancelFire("weapon changed") end
        if oldSlot~=s.slot or (oldGun and newGun and oldGun.id~=newGun.id) then s.reloading=0 s.reloadStarted=0 s.equipAt=os.clock() s.pending={} end
        local ack=data.accepted or 0
        for seq in pairs(s.pending) do if seq<=ack then s.pending[seq]=nil end end
    end
    local function rebuild()
        local g=gun() local key=g and g.id..":"..g.tier..":"..(s.profile and s.profile.skin or "Factory") or ""
        if key==s.vmKey then return end
        s.vmKey=key if s.vm then s.vm:Destroy() s.vm=nil end
        if g then s.vm=W.build(g.id,s.profile and s.profile.skin or "Factory",g.tier,workspace.CurrentCamera,true) s.equipAt=os.clock() fx:sound("Equip") end
    end
    local function spectate(delta)
        if not s.state then return end local targets={}
        for _,p in ipairs(s.state.team) do if p.status=="Alive" and p.id~=player.UserId then table.insert(targets,p) end end
        if #targets==0 then return end
        s.spectateIndex=(s.spectateIndex-1+(delta or 0))%#targets+1
        local target=Players:GetPlayerByUserId(targets[s.spectateIndex].id)
        local hum=target and U.humanoid(target)
        if hum then workspace.CurrentCamera.CameraSubject=hum ui.spectateText.Text=targets[s.spectateIndex].name end
    end
    ui.cycle=spectate
    local function aim(enabled)
        s.aim=enabled and living() or false s.sprint=false
        send("Aim",{enabled=s.aim}) send("Sprint",{enabled=false})
    end
    local function sprint(enabled)
        local value=enabled and living() or false
        if value==s.sprint then return end
        s.sprint=value if value then s.aim=false send("Aim",{enabled=false}) end
        send("Sprint",{enabled=value})
    end
    local function reload()
        local g=gun() if not living() or not g or os.clock()<s.reloading then return end
        local stat=R.weaponStats(C.Weapons[g.id],g.tier,s.state.perks)
        if displayMag()>=stat.mag or g.reserve<=0 then return end
        if mobile then mobile:cancelFire("reload") end
        aim(false)
        s.reloadStarted=os.clock() s.reloadDuration=stat.reload s.reloading=s.reloadStarted+stat.reload s.sprint=false send("Sprint",{enabled=false}) send("Reload",{})
    end
    local function direction(point)
        local camera=workspace.CurrentCamera
        if point then
            -- InputObject.Position uses CoreUISafeInsets, like GUI AbsolutePosition.
            -- ScreenPointToRay adds the top-bar/device inset exactly once. No sensitivity,
            -- normalized layout coordinate or aim snapping changes a tapped ray.
            return camera:ScreenPointToRay(point.X,point.Y,0).Direction.Unit
        end
        local dir=camera.CFrame.LookVector
        local settings=mobile and mobile.settings
        local preset=settings and settings.assistPreset or "Manual"
        local supported=UIS.TouchEnabled or UIS:GetLastInputType()==Enum.UserInputType.Gamepad1
        if fx.settings.aimAssist and supported and preset~="Advanced" then
            local g=gun() local def=g and C.Weapons[g.id]
            local target=AimAssist.target(camera,preset,def and def.range)
            if target then dir=dir:Lerp((target.Position-camera.CFrame.Position).Unit,preset=="Assisted" and .22 or .12).Unit end
        end
        return dir
    end
    local function shoot(point,pulse)
        local g=gun() if not living() or not g or os.clock()<s.nextShot or os.clock()<s.reloading then return end
        local def=C.Weapons[g.id] if pulse then s.semi=false end
        if not def.auto and s.semi then return false end
        if s.sprint then sprint(false) end
        if displayMag()<=0 then if g.reserve>0 then reload() elseif os.clock()>s.nextShot then fx:sound("Empty") s.nextShot=os.clock()+.4 end return end
        local stats=R.weaponStats(def,g.tier,s.state.perks)
        s.nextShot=os.clock()+stats.interval s.semi=true s.seq=s.seq+1
        s.pending[s.seq]={slot=s.slot,id=g.id,time=os.clock()}
        local request={direction=direction(point),seq=s.seq}
        if point then request.viewOrigin=workspace.CurrentCamera.CFrame.Position end
        send("Fire",request)
        s.recoil=math.min(5,s.recoil+((def.class=="Shotgun" or def.class=="Sniper") and 1.7 or .7))
        fx:sound(def.class)
        if s.vm then
            local muzzle=s.vm:FindFirstChild("Muzzle")
            if muzzle then fx:muzzle(muzzle) end
            if muzzle and muzzle:FindFirstChild("Flash") then muzzle.Flash.Brightness=3 task.delay(.05,function() if muzzle.Parent then muzzle.Flash.Brightness=0 end end) end
        end
        return true
    end
    local function melee()
        if living() and os.clock()-s.meleeAt>.85 then s.meleeAt=os.clock() send("Melee",{}) end
    end
    local function grenade()
        if living() then send("Grenade",{direction=direction()}) elseif s.state and s.state.status=="Eliminated" then spectate(1) end
    end
    local function bind(name,keys,fn)
        CAS:BindActionAtPriority("DeadSignal_"..name,function(_,state,input)
            if name=="Fire" and input.UserInputType==Enum.UserInputType.MouseButton1 and UIS.TouchEnabled
                and (not UIS.MouseEnabled or (mobile and mobile.activeTouch)) then return Enum.ContextActionResult.Sink end
            if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            if name~="Menu" and s.menu then return Enum.ContextActionResult.Pass end
            if name~="Menu" and not (s.state and s.state.participating) then return Enum.ContextActionResult.Pass end
            fn(state,input) return Enum.ContextActionResult.Sink
        end,false,2100,table.unpack(keys))
    end
    bind("Fire",{Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2},function(state) if state==Enum.UserInputState.Begin then s.fire=living() s.semi=false elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then s.fire=false s.semi=false end end)
    bind("Aim",{Enum.UserInputType.MouseButton2,Enum.KeyCode.ButtonL2},function(state) if state==Enum.UserInputState.Begin then aim(true) elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then aim(false) end end)
    bind("Reload",{Enum.KeyCode.R,Enum.KeyCode.ButtonY},function(state) if state==Enum.UserInputState.Begin then reload() end end)
    bind("Swap",{Enum.KeyCode.Q,Enum.KeyCode.ButtonB},function(state) if state==Enum.UserInputState.Begin and living() then send("Swap",{}) s.reloading=0 s.nextShot=os.clock()+.28 end end)
    bind("Slot1",{Enum.KeyCode.One},function(state) if state==Enum.UserInputState.Begin and living() then send("Swap",{slot=1}) s.reloading=0 end end)
    bind("Slot2",{Enum.KeyCode.Two},function(state) if state==Enum.UserInputState.Begin and living() then send("Swap",{slot=2}) s.reloading=0 end end)
    bind("Melee",{Enum.KeyCode.V,Enum.KeyCode.ButtonR3},function(state) if state==Enum.UserInputState.Begin then melee() end end)
    bind("Grenade",{Enum.KeyCode.G,Enum.KeyCode.ButtonR1},function(state) if state==Enum.UserInputState.Begin then grenade() end end)
    bind("SpectatePrevious",{Enum.KeyCode.LeftBracket,Enum.KeyCode.ButtonL1},function(state) if state==Enum.UserInputState.Begin and s.state and s.state.status=="Eliminated" then spectate(-1) end end)
    bind("Sprint",{Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3},function(state,input)
        if state==Enum.UserInputState.Begin then if input.KeyCode==Enum.KeyCode.ButtonL3 then sprint(not s.sprint) else sprint(true) end
        elseif state==Enum.UserInputState.End and input.KeyCode==Enum.KeyCode.LeftShift then sprint(false) end
    end)
    bind("Menu",{Enum.KeyCode.M,Enum.KeyCode.ButtonSelect},function(state) if state==Enum.UserInputState.Begin then ui:toggle() end end)
    UIS.WindowFocusReleased:Connect(resetInput)
    mobile=MobileControls.new(ui,{
        weapon=function() local g=gun() return g and C.Weapons[g.id] end,
        fire=shoot,
        stop=function() s.fire=false s.semi=false if s.sprint then sprint(false) end end,
        sprint=sprint,
        native=function(owned)
            if s.nativeOwned~=owned or s.nativeControls~=controls then
                s.nativeOwned=owned s.nativeControls=controls
                if controls then if owned or s.menu then controls:Disable() else controls:Enable() end end
                local hum=U.humanoid(player) if hum then hum.AutoRotate=not owned end
                if not owned and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then
                    workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
                    local char=player.Character
                    if char then for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("BasePart") then obj.LocalTransparencyModifier=0 end end end
                end
            end
        end,
        action=function(name)
            if name=="AIM" then aim(not s.aim)
            elseif name=="RELOAD" then reload()
            elseif name=="SWAP" and living() then mobile:cancelFire("swap") send("Swap",{}) s.reloading=0 s.nextShot=os.clock()+.28
            elseif name=="MELEE" then melee()
            elseif name=="G" then grenade() end
        end,
        save=function(settings) send("ControlSettings",{settings=settings}) end,
        slowdown=function()
            if not fx.settings.aimAssist or not mobile then return 1 end
            local target=AimAssist.target(workspace.CurrentCamera,mobile.settings.assistPreset,100)
            return target and (mobile.settings.assistPreset=="Assisted" and .65 or .82) or 1
        end,
        autoEligible=function()
            local g=gun() return living() and g~=nil and os.clock()>=s.reloading and AimAssist.autoEligible(workspace.CurrentCamera,C.Weapons[g.id].range)
        end,
    })
    ui.editTouch=function() ui:close() mobile:openEditor() end
    ui.touchSummary=function() return mobile:summary() end
    ui.resetTouchSample=function() mobile.samples={} mobile:cancel("comparison reset") end
    PPS.PromptShown:Connect(function(prompt)
        if prompt:GetAttribute("RevivePrompt") then prompt.HoldDuration=R.reviveTime(s.state and s.state.perks or {}) end
    end)
    feed.OnClientEvent:Connect(function(kind,data)
        if kind=="State" then
            local old=s.state s.state=data ammo(data)
            local held=gun()
            if held and held.reloadUntil<=data.serverTime and os.clock()-s.reloadStarted>.7 then s.reloading=0 end
            if old and (old.status~=data.status or old.phase~=data.phase or old.travelling~=data.travelling) then resetInput() s.reloading=0 s.pending={} end
            if data.status=="Eliminated" then spectate(0) end
            if data.status=="Alive" then rebuild() end
            ui:setState(data,displayMag())
            fx:event(data.special)
        elseif kind=="Profile" then s.profile=data fx.settings=data.settings mobile:setSettings(data.settings) ui:setProfile(data) s.vmKey="" rebuild()
        elseif kind=="Ammo" then ammo(data) if living() then rebuild() end
        elseif kind=="Deploy" then ui:close() resetInput() s.pending={} s.reloading=0
        elseif kind=="OpenLobby" then if not (s.state and s.state.participating) then ui:open("Deploy") end
        elseif kind=="OpenBay" then if not (s.state and s.state.participating) then ui:open("Bay") end
        elseif kind=="CloseBay" then ui:close()
        elseif kind=="OpenTerminal" then ui:open(data.tab)
        elseif kind=="Travel" then
            s.travelLock=data.active==true resetInput() ui:close() ui:travel(data)
            if data.active then
                pcall(function() game:GetService("TeleportService"):SetTeleportGui(ui:loadingGui(data.message,data.map)) end)
                if data.token then send("TravelReady",{token=data.token}) end
            end
        elseif kind=="Banner" then ui:banner(data.text,data.color)
        elseif kind=="Toast" then ui:toast(data.text,data.color)
        elseif kind=="Hit" then mobile:hit(data.kill) ui:hit(data.kill,data.head) fx:sound(data.kill and "Kill" or "Hit")
        elseif kind=="Hurt" then ui:damage() fx.shake=math.max(fx.shake,1)
        elseif kind=="Reload" then mobile:cancelFire("server reload") s.reloadStarted=os.clock() s.reloadDuration=data.duration s.reloading=s.reloadStarted+data.duration fx:sound("Reload")
        elseif kind=="Cue" then fx:sound(data.name)
        elseif kind=="Points" then if s.state then s.state.points=data.total ui.points.Text=data.total.."  P" end
        elseif kind=="Boards" then ui.boards=data if ui.tab=="Records" then ui:open("Records") end
        elseif kind=="Results" then resetInput() ui:results(data)
        elseif kind=="Shot" then
            local own=data.player==player.UserId local origin=data.origin
            if own and s.vm and s.vm:FindFirstChild("Muzzle") then origin=s.vm.Muzzle.Position end
            local energy=C.Weapons[data.weapon].class=="Energy"
            for _,point in ipairs(data.ends) do fx:tracer(origin,point,energy) end
            if not own then fx:sound(C.Weapons[data.weapon].class,data.origin) end
        elseif kind=="Explosion" then fx:burst(data.position,data.radius,Color3.fromRGB(255,179,74)) fx:sound("Grenade",data.position) local root=U.root(player) if root and (root.Position-data.position).Magnitude<35 then fx.shake=1.5 end
        elseif kind=="Shock" then fx:burst(data.position,data.radius,Color3.fromRGB(85,205,233)) local root=U.root(player) if root and (root.Position-data.position).Magnitude<35 then fx.shake=1 end
        elseif kind=="ShockWarning" then fx:warning(data) fx:sound("ShockCharge",data.position)
        elseif kind=="SpecialWave" then
            fx:event(data.active==false and nil or data)
            if data.active~=false then ui:banner(data.name.." / "..data.preparation.."s PREPARE","amber");ui:toast(data.hint,"amber") end
        elseif kind=="EnemyTelegraph" then fx:telegraph(data)
        elseif kind=="HazardWarning" then fx:hazardWarning(data)
        elseif kind=="HazardBlast" then fx:hazardBlast(data)
        elseif kind=="HazardCounter" then fx:hazardCounter(data)
        elseif kind=="HazardClear" then fx:clearHazards()
        elseif kind=="ArmorBreak" then fx:particles(data.position,fx.settings.lowEffects and 3 or 9,.5,.16,Color3.fromRGB(172,171,151),true);fx:sound("ArmorBreak",data.position)
        elseif kind=="EliteHit" then
            if os.clock()>=(s.eliteFeedbackAt or 0) or data.kind=="ArmorBreak" then
                s.eliteFeedbackAt=os.clock()+1.2
                ui:toast(data.kind=="Armor" and "ARMOR HIT" or data.kind=="ArmorBreak" and "PLATE BROKEN" or data.kind=="Reactor" and "PRESSURE RISING" or "WEAK POINT","amber")
            end
        elseif kind=="CounterActive" then fx:sound("Vent",data.position);fx:particles(data.position,fx.settings.lowEffects and 3 or 8,.9,.6,Color3.fromRGB(159,201,207),false)
        elseif kind=="EnemyAttack" then fx:sound(data.kind=="Hound" and "Howl" or data.kind=="Stalker" and "Stalker" or data.enraged and "Redline" or "Attack",data.position)
        elseif kind=="ArcLink" then fx:tracer(data.origin,data.finish,true)
        elseif kind=="EnemyDeath" then fx:enemyDeath(data)
        elseif kind=="Melee" then if data.player==player.UserId then fx:sound("Click") end
        elseif kind=="Board" then fx:sound("Board",data.position)
        end
    end)
    local cameraMode="" local anim=0 local ambientAt=os.clock()+15
    RunService:BindToRenderStep("DeadSignalPresentation",Enum.RenderPriority.Camera.Value+1,function(dt)
        local inputBlocked=s.menu or ui.loading.frame.Visible
        if controls and s.controlBlocked~=inputBlocked then
            s.controlBlocked=inputBlocked if inputBlocked then controls:Disable() else controls:Enable() end
        end
        local camera=workspace.CurrentCamera local state=s.state local now=os.clock()
        for seq,p in pairs(s.pending) do if now-p.time>1.5 then s.pending[seq]=nil end end
        local mode=state and state.status or "Lobby"
        local wanted=s.menu and "Menu" or mode
        if wanted~=cameraMode then
            cameraMode=wanted camera.CameraType=Enum.CameraType.Custom
            if wanted=="Alive" or wanted=="Down" then player.CameraMode=Enum.CameraMode.LockFirstPerson player.CameraMinZoomDistance=.5 player.CameraMaxZoomDistance=.5
            else player.CameraMode=Enum.CameraMode.Classic player.CameraMinZoomDistance=6 player.CameraMaxZoomDistance=18 end
            if wanted~="Eliminated" then local hum=U.humanoid(player) if hum then camera.CameraSubject=hum end end
        end
        UIS.MouseIconEnabled=s.menu or not (mode=="Alive" or mode=="Down")
        if s.menu then UIS.MouseBehavior=Enum.MouseBehavior.Default end
        local hum=U.humanoid(player) if hum then hum.CameraOffset=mode=="Down" and Vector3.new(0,.35,-.25) or Vector3.new(0,0,0) end
        noJump(player.Character)
        if state and s.sprint and state.stamina<2 then sprint(false) end
        mobile:update(dt,state,s.menu or s.travelLock,s.aim,gun() and W.scoped(gun().id) and s.aim)
        if s.fire then shoot() end
        local held=gun() local isAiming=s.aim and living() and now>=s.reloading
        if living() and now>(s.lookSentAt or 0) then
            s.lookSentAt=now+.1 local root=U.root(player)
            if root then local look=root.CFrame:VectorToObjectSpace(camera.CFrame.LookVector)
                send("Look",{pitch=math.asin(math.clamp(look.Y,-1,1)),yaw=math.atan2(-look.X,-look.Z)})
            end
        end
        local aimedFov=held and W.aimFov(held.id) or 57
        aimAlpha=aimAlpha+((isAiming and 1 or 0)-aimAlpha)*math.min(1,dt*18)
        local scoped=held and W.scoped(held.id) and isAiming and aimAlpha>.93
        optic:update(scoped==true,camera.ViewportSize)
        ui.cross.Visible=living() and aimAlpha<.5 and not (mobile.enabled and mobile.settings.fireLayout=="Tap")
        camera.FieldOfView=camera.FieldOfView+((s.aim and living() and aimedFov or fx.settings.fov)-camera.FieldOfView)*math.min(1,dt*14)
        s.recoil=s.recoil*math.exp(-dt*15) fx.shake=fx.shake*math.exp(-dt*7)
        local shake=fx.settings.lowEffects and 0 or fx.settings.shake*fx.shake
        if living() then camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(s.recoil),math.sin(now*57)*shake*.005,0) end
        if s.vm then
            if living() then
                local moving=hum and hum.MoveDirection.Magnitude or 0
                local hip=mobile.enabled and mobile.settings.fireLayout=="Tap" and Vector3.new(.78,-.94,-1.2) or Vector3.new(.64,-.67,-1.1)
                local offset=hip:Lerp(Vector3.new(0,-W.aimHeight(gun().id),-1.15),aimAlpha)
                local bob=Vector3.new(math.sin(now*9)*.022*moving,math.abs(math.cos(now*9))*.025*moving,0)*(1-aimAlpha*.92)
                local progress=now<s.reloading and math.clamp((now-s.reloadStarted)/s.reloadDuration,0,1) or 0
                local reloadRoll=progress>0 and math.sin(progress*math.pi)*.48 or 0
                local meleeProgress=now-s.meleeAt<.38 and (now-s.meleeAt)/.38 or 0
                local meleeRoll=meleeProgress>0 and -math.sin(meleeProgress*math.pi)*.95 or 0
                local equip=math.max(0,1-(now-s.equipAt)/.3)
                local sway=Vector3.new(math.sin(now*1.6)*.003,math.cos(now*1.8)*.004,0)*(1-aimAlpha)
                s.vm:PivotTo(camera.CFrame*CFrame.new(offset+bob+sway+Vector3.new(0,-equip*.65,s.recoil*.035-math.sin(meleeProgress*math.pi)*.25))*CFrame.Angles(s.recoil*.012-equip*.3,0,reloadRoll+meleeRoll+(s.sprint and -.35 or 0)))
                W.pose(s.vm,progress,meleeProgress,equip,s.recoil)
                W.aim(s.vm,aimAlpha>.8 and W.scoped(gun().id))
            else s.vm:PivotTo(CFrame.new(0,-1000,0)) end
        end
        local char=player.Character local carried=char and char:FindFirstChild("CarriedWeapon")
        if carried then for _,p in ipairs(carried:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier=(mode=="Alive" or mode=="Down") and 1 or 0 end end end
        if state and gun() then ui.ammo.Text=now<s.reloading and "RELOADING" or displayMag().." / "..gun().reserve end
        anim=anim+dt if anim>.033 then fx:animate(anim) anim=0 end
        if now>ambientAt then
            ambientAt=now+20 fx:sound("Ambient")
            if state and state.participating then fx:sound(state.map=="Frost" and "Wind" or state.map=="Foundry" and "Machinery" or "Radio")
            else fx:sound("Dispatch") end
        end
    end)
    player.CharacterAdded:Connect(function(char) resetInput() cameraMode="" s.vmKey="" task.delay(.6,function() noJump(char) if s.state and s.state.status=="Alive" then rebuild() end end) end)
    task.spawn(function() while not s.profile do send("Ready",{}) task.wait(2) end end)
    send("Ready",{})
end
return Controller
