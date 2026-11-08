local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local CAS=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
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
-- Integration-owned adapters for acknowledged state and replicated map/NPC facts.
-- One bounded 10 Hz pass; no new remote, required ModuleScript or gameplay authority.
function Controller.audioBindings(fx,player)
    if not fx.audioState or not fx.audioEvent or not fx.audioCancel or not fx.audioReset then return nil end
    local binding={fx=fx,player=player,actors={},zones={},events={},anchors={},stockSounds={},epoch=0,nextTick=0,nextMetadata=0,nextStock=0}
    local function inside(points,p)
        local hit=false local previous=points[#points]
        for _,point in ipairs(points) do
            if previous and (point.Z>p.Z)~=(previous.Z>p.Z)
                and p.X<(previous.X-point.X)*(p.Z-point.Z)/(previous.Z-point.Z)+point.X then hit=not hit end
            previous=point
        end
        return hit
    end
    function binding:clearActors()
        for _,actor in pairs(self.actors) do if actor.token then fx:audioCancel(actor.token) end if actor.life then fx:audioCancel(actor.life) end end
        self.actors={}
    end
    function binding:stockMix(now)
        if now>=self.nextStock then
            self.nextStock=now+1
            local ok,players=pcall(function() return Players:GetPlayers() end)
            for _,who in ipairs(ok and players or {player}) do
                local root=U.root(who)
                for _,sound in ipairs(root and root:GetChildren() or {}) do if sound:IsA("Sound") and not self.stockSounds[sound] then
                    if not self.stockGroup then self.stockGroup=U.make("SoundGroup",SoundService,{Name="DeadSignalCharacterMix"}) end
                    self.stockSounds[sound]={group=sound.SoundGroup}
                    sound.SoundGroup=self.stockGroup
                end end
            end
            for sound in pairs(self.stockSounds) do if not sound.Parent then self.stockSounds[sound]=nil end end
        end
        if self.stockGroup then self.stockGroup.Volume=R.finite(fx.settings.volume) and math.clamp(fx.settings.volume,0,1) or .65 end
    end
    function binding:metadata(map,now)
        if now<self.nextMetadata then return end self.nextMetadata=now+1
        local semantics=map and map:FindFirstChild("MapSemantics")
        self.zones={} self.anchors={} self.worldEvents={} self.atmosphereAnchors={}
        if not semantics or semantics:GetAttribute("SchemaVersion")~=1 then return end
        local zones=semantics:FindFirstChild("Zones")
        for index,item in ipairs(zones and zones:GetChildren() or {}) do
            if index>32 then break end
            local position=item:GetAttribute("Position")
            if not U.finiteVector(position) then continue end
            local zone={id=item.Name,room=item:GetAttribute("Room"),position=position,indoors=item:GetAttribute("Indoors")==true,
                level=item:GetAttribute("Level") or 0,priority=item:GetAttribute("Priority") or 0,purpose=item:GetAttribute("Purpose") or "",regions={}}
            for regionIndex,region in ipairs(item:GetChildren()) do
                if regionIndex>32 then break end
                local points={} local n=region:GetAttribute("PointCount")
                if type(n)=="number" and n>=3 and n<=16 then
                    for i=1,n do local point=region:GetAttribute("Point"..i) if U.finiteVector(point) then points[#points+1]=point end end
                    if #points==n then zone.regions[#zone.regions+1]=points end
                end
            end
            self.zones[#self.zones+1]=zone
        end
        table.sort(self.zones,function(a,b) return a.priority==b.priority and a.id<b.id or a.priority>b.priority end)
        local function room(pattern)
            for _,zone in ipairs(self.zones) do if string.find(string.lower(zone.purpose),pattern,1,true) then return zone.position end end
        end
        local landmarks=semantics:FindFirstChild("Landmarks") local points={}
        for index,item in ipairs(landmarks and landmarks:GetChildren() or {}) do
            if index>48 then break end
            local position=item:GetAttribute("Position")
            if U.finiteVector(position) then
                points[item:GetAttribute("Kind") or item.Name]=position
                if #self.atmosphereAnchors<16 then self.atmosphereAnchors[#self.atmosphereAnchors+1]=position end
            end
        end
        self.anchors={
            ["World.Station.radio"]=points.AntennaField,["World.Station.power"]=room("generation"),["World.Station.wind"]=room("antenna"),
            ["World.Foundry.machinery"]=room("machine hall") or points.GantryCrane,["World.Foundry.furnace"]=room("furnace") or points.Smokestack,
            ["World.Foundry.vent"]=room("boiler"),["World.Frost.wind"]=room("ice apron"),["World.Frost.relay"]=room("listening"),
            ["World.Frost.structure"]=points.RemotePolarFacility,
        }
        local events=semantics:FindFirstChild("VisualEvents")
        for index,item in ipairs(events and events:GetChildren() or {}) do if index>12 then break end self.worldEvents[#self.worldEvents+1]=item end
    end
    function binding:context(extra)
        local context={runId=self.runId,token=self.token,map=self.mapId}
        for key,value in pairs(extra or {}) do context[key]=value end return context
    end
    function binding:tick(now,force)
        if self.destroyed or not self.state or not force and now<self.nextTick then return end self.nextTick=now+.1
        self:stockMix(now)
        local state=self.state local map=workspace:FindFirstChild("DeadSignalMap")
        local character=player.Character local root=U.root(player)
        local mapId=state.participating and state.map or "Lobby"
        local runId=tostring(state.runId or 0)
        if map~=self.map or character~=self.character or runId~=self.runId or mapId~=self.mapId then
            self:clearActors() self.map=map self.character=character self.runId=runId self.mapId=mapId
            self.epoch+=1 self.token="scene:"..player.UserId..":"..self.epoch self.nextMetadata=0 self.events={}
        end
        local active=not self.blocked and not state.travelling
        if not active then
            if self.active~=false then self:clearActors();fx:audioState({active=false,token=self.token}) end
            self.active=false return
        end
        self.active=true self:metadata(map,now)
        local room,indoors
        if root then for _,zone in ipairs(self.zones) do
            local floor=zone.level==1 and zone.position.Y or 0
            if root.Position.Y>=floor-.8 and root.Position.Y<=floor+9 then
                for _,region in ipairs(zone.regions) do if inside(region,root.Position) then room=zone.id;indoors=zone.indoors;break end end
                if room then break end
            end
        end end
        fx:audioState({map=mapId,runId=runId,token=self.token,active=true,room=room,indoors=indoors==true,
            intensity=math.clamp((state.round or 0)/30+(state.phase=="Wave" and .15 or 0),0,1),anchors=self.anchors,
            phase=state.phase,status=state.status,boss=type(state.boss)=="table",special=state.special~=nil and state.special~=false,
            atmosphereAnchors=self.atmosphereAnchors})
        if state.phase=="Results" or state.status=="Eliminated" then self:clearActors();return end
        -- World activity follows actual visual-event edges. Omit auto-activity
        -- anchors so the mixer cannot also create an unrelated distant cue.
        for _,event in ipairs(self.worldEvents or {}) do
            local activeEvent=event:GetAttribute("Active")==true local old=self.events[event.Name]
            if old==false and activeEvent then
                local position=event:GetAttribute("Position")
                if U.finiteVector(position) then fx:audioEvent("World.Landmark",self:context({map=mapId,position=position,sourceId=event.Name,eventId=event.Name})) end
            end
            self.events[event.Name]=activeEvent
        end
        local folder=workspace:FindFirstChild("DeadSignalEnemies") local seen={} local routine=0
        local models=folder and folder:GetChildren() or {} local entryVoices=0 local footsteps=0
        table.sort(models,function(a,b)
            local ar=a:FindFirstChild("HumanoidRootPart") local br=b:FindFirstChild("HumanoidRootPart")
            local da=root and ar and (ar.Position-root.Position).Magnitude or math.huge
            local db=root and br and (br.Position-root.Position).Magnitude or math.huge
            if da==db then return (a:GetAttribute("EnemyId") or 0)<(b:GetAttribute("EnemyId") or 0) end
            return da<db
        end)
        local serverNow=workspace:GetServerTimeNow()
        for index,model in ipairs(models) do
            if index>40 then break end
            local actorRoot=model:FindFirstChild("HumanoidRootPart")
            if not actorRoot or model:GetAttribute("Dead") then continue end
            local actorRun=model:GetAttribute("EnemyRunId")
            if actorRun~=nil and tostring(actorRun)~=runId then continue end
            seen[model]=true local record=self.actors[model]
            if not record then record={nextRoutine=now+2+(index%5),position=actorRoot.Position,life="actor:"..self.epoch..":"..tostring(model:GetAttribute("EnemyId") or index)};self.actors[model]=record end
            local source=model:GetAttribute("EntrySourceId") local at=model:GetAttribute("EntryCueAt")
            if source and source~=record.token then if record.token then fx:audioCancel(record.token) end record.token=source;record.cueAt=nil end
            local sourceRun=type(source)=="string" and source:match("^enemy:([^:]+):")
            if source and sourceRun==runId and type(at)=="number" and at~=record.cueAt then
                record.cueAt=at local cue=model:GetAttribute("EntryCue")
                if cue=="Enemy.Entry.Cancel" then fx:audioCancel(source)
                elseif (cue=="Enemy.Entry.Approach" or cue=="Enemy.Entry.Contact" or cue=="Enemy.Entry.Land") and math.abs(serverNow-at)<1.5 and entryVoices<4 then
                    entryVoices+=1 fx:audioEvent(cue,self:context({position=actorRoot.Position,sourceId=source,token=source}))
                end
            end
            local distance=root and (actorRoot.Position-root.Position).Magnitude or math.huge
            local enemyId=model:GetAttribute("EnemyId") or index local sourceId="npc:"..runId..":"..enemyId
            local kind=model:GetAttribute("EnemyType")
            if model:GetAttribute("Alpha") and not record.alpha and distance<85 then
                record.alpha=true fx:audioEvent("Enemy.Alpha",self:context({position=actorRoot.Position,sourceId=sourceId,token=record.life}))
            end
            local awareness=model:GetAttribute("AwarenessAt")
            if type(awareness)=="number" and awareness==awareness and awareness~=record.awarenessAt then
                record.awarenessAt=awareness -- Consume even if stale/budgeted: never replay later.
                if tostring(model:GetAttribute("AwarenessRunId"))==runId
                    and model:GetAttribute("AwarenessTargetUserId")==player.UserId
                    and math.abs(serverNow-awareness)<=1.5 and distance<65
                    and now>=(record.nextAwareness or 0) and now>=(self.nextAwareness or 0) then
                    record.nextAwareness=now+8;self.nextAwareness=now+2.5
                    fx:audioEvent(kind=="Hound" and "Hound.Snarl" or "Enemy.Awareness",self:context({position=actorRoot.Position,sourceId=sourceId,
                        token=record.life,phase=tostring(awareness)}))
                end
            end
            if now>=record.nextRoutine and distance<70 and routine<2 then
                routine+=1;record.routineSeed=((record.routineSeed or enemyId+1)*48271)%2147483647
                record.nextRoutine=now+5+record.routineSeed/2147483647*8
                local cue=kind=="Hound" and "Hound.Snarl" or "Zombie.Groan"
                if kind~="Hound" and distance<22 and fx.audioAvailable and fx:audioAvailable("Zombie.Breath")
                    and record.routineSeed%3==0 then cue="Zombie.Breath" end
                fx:audioEvent(cue,self:context({position=actorRoot.Position,sourceId=sourceId,token=record.life,kind=kind,routine=true}))
            end
            -- NPCs do not receive Roblox's default player-footstep script.
            -- Material slots remain silent until an approved recording is set.
            local hum=model:FindFirstChildOfClass("Humanoid")
            local material=hum and hum.FloorMaterial
            local moved=(actorRoot.Position-record.position).Magnitude
            if moved>.03 and moved<10 then record.travel=(record.travel or 0)+moved
            elseif moved>=10 then record.travel=0 end
            if distance<38 and moved>.03 and (record.travel or 0)>=2 and now>=(record.stepAt or 0)
                and material and material~=Enum.Material.Air and footsteps<2 then
                footsteps+=1 record.stepAt=now+(kind=="Hound" and .35 or .55);record.travel=0
                local context=self:context({position=actorRoot.Position,sourceId=sourceId,token=record.life,material=material.Name,kind=kind})
                fx:audioEvent(kind=="Crawler" and "Zombie.Drag" or "Zombie.Footstep",context)
                if kind~="Hound" and now>=(record.gearAt or 0) then
                    record.gearAt=now+1.5+(enemyId%3)*.3;fx:audioEvent("Zombie.Gear",context)
                end
            end
            record.position=actorRoot.Position
        end
        for model,record in pairs(self.actors) do if not seen[model] then if record.token then fx:audioCancel(record.token) end if record.life then fx:audioCancel(record.life) end self.actors[model]=nil end end
    end
    function binding:set(state,blocked)
        self.state=state self.blocked=blocked==true self:tick(os.clock(),true)
        if not state or not self.active then return end
        local oldPhase=self.phase local oldRound=self.round
        if oldPhase and (state.phase~=oldPhase or state.round~=oldRound) then
            local key=state.phase=="Wave" and "Wave.Start" or state.phase=="Preparing" and not state.special and "Wave.Prepare"
                or state.phase=="Intermission" and oldPhase=="Wave" and "Wave.Complete" or state.phase=="Exfil" and "Extraction.Warn"
            if key then fx:audioEvent(key,self:context({sourceId="phase:"..state.phase..":"..(state.round or 0)})) end
        end
        if self.signal==false and state.signal then fx:audioEvent("Objective.Signal",self:context({sourceId="signal"})) end
        if state.boss and self.bossPhase and state.boss.phase~=self.bossPhase then
            fx:audioEvent("Warden.Phase",self:context({sourceId="warden:"..state.boss.phase}))
        end
        self.phase=state.phase self.round=state.round self.signal=state.signal==true self.bossPhase=state.boss and state.boss.phase
    end
    function binding:results(state)
        local result=table.clone(state or {});result.phase="Results";result.travelling=false
        self:set(result,false)
    end
    function binding:destroy()
        if self.destroyed then return end self:clearActors() fx:audioReset(self.token)
        for sound,row in pairs(self.stockSounds) do if sound.Parent then sound.SoundGroup=row.group end end
        self.stockSounds={} if self.stockGroup then self.stockGroup:Destroy() self.stockGroup=nil end self.destroyed=true
    end
    return binding
end

function Controller.start()
    local player=Players.LocalPlayer
    if player.PlayerGui:FindFirstChild("DeadSignalHUD") then return end
    local remotes=RS.DeadSignal:WaitForChild("Remotes") local action=remotes:WaitForChild("Action") local feed=remotes:WaitForChild("Feed")
    local s={state=nil,profile=nil,fire=false,aim=false,sprint=false,menu=false,nextShot=0,seq=0,pending={},slot=1,guns={},recoil=0,vm=nil,vmKey="",spectateIndex=1,semi=false,reloading=0,meleeAt=0,reloadStarted=0,reloadDuration=1,equipAt=0}
    local fx=FX.new() local ui local aimAlpha=0
    local audioBindings=Controller.audioBindings(fx,player)
    local audioSerial=0 local shotReports={} local shotOrder={}
    local function cancelPresentation()
        if s.weaponToken and fx.audioCancel then fx:audioCancel(s.weaponToken) end
        s.weaponToken=nil s.reloadPresentation=false
        if s.vm then W.clearEffects(s.vm) end
    end
    local function weaponSound(key,phase,actionKind,position,held,remote)
        held=held or s.guns[s.slot] if not held then return end
        if not remote and not s.weaponToken then audioSerial+=1 s.weaponToken="weapon:"..player.UserId..":"..audioSerial end
        fx:sound(key,position,{weaponId=held.id,action=actionKind,phase=phase,token=not remote and s.weaponToken or nil,
            position=position,runId=s.state and s.state.runId,firstPerson=not remote,tier=held.tier,sourceId=remote and tostring(remote) or tostring(player.UserId)})
    end
    local function warningSound(data,key)
        if not audioBindings then return data end
        local visual=table.clone(data) visual.cue=nil
        fx:audioEvent(key,audioBindings:context({position=data.position,sourceId=data.id,duration=data.duration}))
        return visual
    end
    local function send(op,args) action:FireServer(op,args or {}) end
    local controls local mobile
    task.spawn(function() local pm=player.PlayerScripts:WaitForChild("PlayerModule",10) if pm then local ok,result=pcall(function() return require(pm):GetControls() end) if ok then controls=result end end end)
    local function resetInput()
        if mobile then mobile:cancel("input reset") end
        cancelPresentation()
        s.fire=false s.aim=false s.sprint=false s.sprintWanted=false s.semi=false s.moveSpeed=0 s.sprintMotion=0
        send("Aim",{enabled=false}) send("Sprint",{enabled=false,move=Vector3.zero,blocked=true})
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
    local function living() return s.state and s.state.status=="Alive" and s.state.participating and not s.menu and not s.interacting and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox() and not s.state.travelling and not s.travelLock and not ui.loading.frame.Visible and (s.state.phase=="Wave" or s.state.phase=="Preparing" or s.state.phase=="Intermission" or s.state.phase=="Exfil") end
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
        if oldSlot~=s.slot or (oldGun and newGun and oldGun.id~=newGun.id) then
            cancelPresentation()
            s.reloading=0 s.reloadStarted=0 s.equipAt=os.clock() s.pending={}
            s.fire=false s.aim=false s.semi=false s.recoil=0 aimAlpha=0 send("Aim",{enabled=false})
        end
        local ack=data.accepted or 0
        for seq in pairs(s.pending) do if seq<=ack then s.pending[seq]=nil end end
    end
    local function rebuild()
        local g=gun() local key=g and g.id..":"..g.tier..":"..(s.profile and s.profile.skin or "Factory") or ""
        if key==s.vmKey then return end
        cancelPresentation()
        s.vmKey=key if s.vm then W.clearEffects(s.vm,true) s.vm:Destroy() s.vm=nil end
        if g then s.vm=W.build(g.id,s.profile and s.profile.skin or "Factory",g.tier,workspace.CurrentCamera,true) W.bindEffects(s.vm,fx.folder) s.equipAt=os.clock() weaponSound("Equip","equip","equip") end
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
        s.aim=enabled and living() and os.clock()>=s.reloading or false s.sprint=false s.sprintWanted=false
        send("Aim",{enabled=s.aim}) send("Sprint",{enabled=false})
    end
    local function sprint(enabled,source)
        s.sprintWanted=enabled and living() or false s.sprintSource=source or "analog"
        if not s.sprintWanted and s.sprint then s.sprint=false send("Sprint",{enabled=false,move=Vector3.zero}) end
    end
    local function reload()
        local g=gun() if not living() or not g or os.clock()<s.reloading then return end
        local stat=R.weaponStats(C.Weapons[g.id],g.tier,s.state.perks)
        if displayMag()>=stat.mag or g.reserve<=0 then return end
        if mobile then mobile:cancelFire("reload") end
        aim(false)
        cancelPresentation()
        s.reloadMissing=math.max(1,stat.mag-displayMag())
        s.reloadAcknowledged=false s.reloadPresentation=true
        if s.vm then W.beginReload(s.vm,s.reloadMissing,false) end
        s.reloadStarted=os.clock() s.reloadDuration=stat.reload s.reloading=s.reloadStarted+stat.reload s.sprint=false s.sprintWanted=false send("Sprint",{enabled=false}) send("Reload",{})
    end
    local function swap(slot)
        local index=(slot==1 or slot==2) and slot or (s.slot==1 and 2 or 1)
        if not living() or index==s.slot or not s.guns[index] then return end
        if mobile then mobile:cancelFire("swap") end
        s.fire=false s.semi=false aim(false)
        send("Swap",{slot=index}) s.nextShot=os.clock()+.28
        -- Reload animation/ammo are reconciled only when the server confirms
        -- the new slot. A rejected swap cannot locally cancel a real reload.
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
        if displayMag()<=0 then if g.reserve>0 then reload() elseif os.clock()>s.nextShot then weaponSound("Empty","empty","fire") s.nextShot=os.clock()+.4 end return end
        local stats=R.weaponStats(def,g.tier,s.state.perks)
        s.nextShot=os.clock()+stats.interval s.semi=true s.seq=s.seq+1
        s.pending[s.seq]={slot=s.slot,id=g.id,time=os.clock()}
        local request={direction=direction(point),seq=s.seq}
        if point then request.viewOrigin=workspace.CurrentCamera.CFrame.Position end
        send("Fire",request)
        s.recoil=math.min(5,s.recoil+((def.class=="Shotgun" or def.class=="Sniper") and 1.7 or .7))
        -- Report audio follows the server Shot acknowledgment; recoil stays responsive.
        if s.vm then W.shot(s.vm,os.clock(),fx.settings.lowEffects,stats.interval) end
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
    bind("Swap",{Enum.KeyCode.Q,Enum.KeyCode.ButtonB},function(state) if state==Enum.UserInputState.Begin then swap() end end)
    bind("Slot1",{Enum.KeyCode.One},function(state) if state==Enum.UserInputState.Begin then swap(1) end end)
    bind("Slot2",{Enum.KeyCode.Two},function(state) if state==Enum.UserInputState.Begin then swap(2) end end)
    bind("Melee",{Enum.KeyCode.V,Enum.KeyCode.ButtonR3},function(state) if state==Enum.UserInputState.Begin then melee() end end)
    bind("Grenade",{Enum.KeyCode.G,Enum.KeyCode.ButtonR1},function(state) if state==Enum.UserInputState.Begin then grenade() end end)
    bind("SpectatePrevious",{Enum.KeyCode.LeftBracket,Enum.KeyCode.ButtonL1},function(state) if state==Enum.UserInputState.Begin and s.state and s.state.status=="Eliminated" then spectate(-1) end end)
    bind("Sprint",{Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3},function(state,input)
        if state==Enum.UserInputState.Begin then if input.KeyCode==Enum.KeyCode.ButtonL3 then sprint(not s.sprintWanted,"toggle") else sprint(true,"hold") end
        elseif (state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel) and input.KeyCode==Enum.KeyCode.LeftShift then sprint(false,"hold") end
    end)
    bind("Menu",{Enum.KeyCode.M,Enum.KeyCode.ButtonSelect},function(state) if state==Enum.UserInputState.Begin then ui:toggle() end end)
    UIS.WindowFocusReleased:Connect(resetInput)
    UIS.TextBoxFocused:Connect(resetInput)
    GuiService.MenuOpened:Connect(resetInput)
    mobile=MobileControls.new(ui,{
        weapon=function() local g=gun() return g and C.Weapons[g.id] end,
        fire=shoot,
        stop=function() s.fire=false s.semi=false sprint(false) end,
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
            elseif name=="SWAP" then swap()
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
    PPS.PromptButtonHoldBegan:Connect(function(prompt,who)
        if not who or who==player then s.interacting=prompt resetInput() end
    end)
    local function endInteraction(prompt,who)
        if s.interacting==prompt and (not who or who==player) then s.interacting=nil resetInput() end
    end
    PPS.PromptButtonHoldEnded:Connect(endInteraction)
    PPS.PromptTriggered:Connect(endInteraction)
    PPS.PromptHidden:Connect(endInteraction)
    feed.OnClientEvent:Connect(function(kind,data)
        if kind~="State" and type(data)=="table" and data.runId~=nil and s.state and s.state.runId~=nil and data.runId~=s.state.runId then return end
        if kind=="State" then
            local old=s.state s.state=data s.moveStamina=data.stamina ammo(data)
            local authority=data.movement
            if authority and not authority.sprinting and (authority.reason=="stamina" or authority.reason=="reload" or authority.reason=="aiming" or authority.reason=="blocked") then
                s.sprint=false
                if s.sprintSource=="toggle" or authority.reason~="stamina" then s.sprintWanted=false end
            end
            if audioBindings then audioBindings:set(data,s.travelLock or ui.loading.frame.Visible) end
            local held=gun()
            if held and held.reloadUntil<=data.serverTime and os.clock()-s.reloadStarted>.7 then s.reloading=0 end
            if old and (old.status~=data.status or old.phase~=data.phase or old.travelling~=data.travelling) then s.interacting=nil resetInput() s.reloading=0 s.pending={} end
            if data.status=="Eliminated" then spectate(0) end
            if data.status=="Alive" then
                rebuild()
                -- A phase/input lifecycle reset is not a server reload cancel.
                -- Resume from its remaining duration without replaying old cues.
                local remaining=held and held.reloadUntil-data.serverTime or 0
                if remaining>0 and s.reloading<=os.clock() then
                    local stats=R.weaponStats(C.Weapons[held.id],held.tier,data.perks)
                    s.reloadDuration=stats.reload s.reloading=os.clock()+remaining s.reloadStarted=s.reloading-stats.reload
                    s.reloadMissing=math.max(1,stats.mag-displayMag())
                    s.reloadAcknowledged=true s.reloadPresentation=true
                    if s.vm then W.beginReload(s.vm,s.reloadMissing,true,math.clamp(1-remaining/stats.reload,0,1)) end
                end
            end
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
            s.travelLock=data.active==true s.interacting=nil resetInput() ui:close() ui:travel(data)
            if audioBindings then audioBindings:set(s.state,s.travelLock or ui.loading.frame.Visible) end
            if data.active then
                pcall(function() game:GetService("TeleportService"):SetTeleportGui(ui:loadingGui(data.message,data.map)) end)
                if data.token then send("TravelReady",{token=data.token}) end
            end
        elseif kind=="Banner" then ui:banner(data.text,data.color)
        elseif kind=="Toast" then ui:toast(data.text,data.color)
        elseif kind=="Hit" then mobile:hit(data.kill) ui:hit(data.kill,data.head) fx:sound(data.kill and "Kill" or "Hit")
        elseif kind=="Hurt" then ui:damage() fx.shake=math.max(fx.shake,1)
        elseif kind=="Reload" then
            local held=gun()
            if held and (not data.weapon or held.id==data.weapon) then
                mobile:cancelFire("server reload") s.fire=false aim(false)
                cancelPresentation()
                local stats=R.weaponStats(C.Weapons[held.id],held.tier,s.state and s.state.perks or {})
                s.reloadMissing=math.max(1,stats.mag-displayMag())
                s.reloadAcknowledged=true s.reloadPresentation=true
                if s.vm then W.beginReload(s.vm,s.reloadMissing,true) end
                s.reloadStarted=os.clock() s.reloadDuration=data.duration s.reloading=s.reloadStarted+data.duration weaponSound("Reload","begin","reload")
            end
        elseif kind=="Cue" then if not audioBindings or data.name~="Round" then fx:sound(data.name) end
        elseif kind=="Points" then if s.state then s.state.points=data.total ui.points.Text=data.total.."  P" end
        elseif kind=="Boards" then ui.boards=data if ui.tab=="Records" then ui:open("Records") end
        elseif kind=="Results" then resetInput() ui:results(data) if audioBindings then audioBindings:results(s.state) end
        elseif kind=="Shot" then
            if data.runId~=nil and s.state and data.runId~=s.state.runId then return end
            local own=data.player==player.UserId local origin=data.origin
            if own and data.seq~=nil then
                local key=tostring(data.runId)..":"..tostring(data.seq)
                if shotReports[key] then return end
                shotReports[key]=true shotOrder[#shotOrder+1]=key
                if #shotOrder>128 then shotReports[table.remove(shotOrder,1)]=nil end
            end
            if own and s.vm and s.vm:FindFirstChild("Muzzle") then origin=s.vm.Muzzle.Position end
            local energy=C.Weapons[data.weapon].class=="Energy"
            for _,point in ipairs(data.ends) do fx:tracer(origin,point,energy) end
            if not s.travelLock and not ui.loading.frame.Visible then
                weaponSound(C.Weapons[data.weapon].class,"fire","fire",not own and data.origin or nil,{id=data.weapon,tier=data.tier},not own and data.player or nil)
            end
        elseif kind=="Explosion" then fx:burst(data.position,data.radius,Color3.fromRGB(255,179,74)) fx:sound("Grenade",data.position) local root=U.root(player) if root and (root.Position-data.position).Magnitude<35 then fx.shake=1.5 end
        elseif kind=="Shock" then fx:burst(data.position,data.radius,Color3.fromRGB(85,205,233)) local root=U.root(player) if root and (root.Position-data.position).Magnitude<35 then fx.shake=1 end
        elseif kind=="ShockWarning" then fx:warning(data) fx:sound("Warden.Warn",data.position,audioBindings and audioBindings:context())
        elseif kind=="SpecialWave" then
            fx:event(data.active==false and nil or data)
            if data.active~=false then ui:banner(data.name.." / "..data.preparation.."s PREPARE","amber");ui:toast(data.hint,"amber") end
        elseif kind=="EnemyTelegraph" then fx:telegraph(warningSound(data,data.finish and "Enemy.Charge.Warn" or "Enemy.Ambush.Warn"))
        elseif kind=="HazardWarning" then fx:hazardWarning(warningSound(data,"Enemy.Blast.Warn"))
        elseif kind=="HazardBlast" then fx:hazardBlast(data)
        elseif kind=="HazardCounter" then fx:hazardCounter(data)
        elseif kind=="HazardClear" then fx:clearHazards()
        elseif kind=="ArmorBreak" then fx:particles(data.position,fx.settings.lowEffects and 3 or 9,.5,.16,Color3.fromRGB(172,171,151),true);fx:sound("Enemy.Armor.Break",data.position,audioBindings and audioBindings:context({sourceId=data.id}))
        elseif kind=="EliteHit" then
            if os.clock()>=(s.eliteFeedbackAt or 0) or data.kind=="ArmorBreak" then
                s.eliteFeedbackAt=os.clock()+1.2
                ui:toast(data.kind=="Armor" and "ARMOR HIT" or data.kind=="ArmorBreak" and "PLATE BROKEN" or data.kind=="Reactor" and "PRESSURE RISING" or "WEAK POINT","amber")
            end
        elseif kind=="CounterActive" then fx:sound("Vent",data.position);fx:particles(data.position,fx.settings.lowEffects and 3 or 8,.9,.6,Color3.fromRGB(159,201,207),false)
        elseif kind=="EnemyAttack" then fx:sound(data.kind=="Hound" and "Hound.Attack" or "Zombie.Attack",data.position,audioBindings and audioBindings:context({sourceId=data.id,kind=data.kind}))
        elseif kind=="ArcLink" then fx:tracer(data.origin,data.finish,true)
        elseif kind=="EnemyDeath" then fx:enemyDeath(data) if audioBindings then fx:audioEvent("Enemy.Death",audioBindings:context({position=data.position,sourceId=data.id,token="death:"..audioBindings.runId..":"..data.id,kind=data.kind})) end
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
        if audioBindings then
            audioBindings.blocked=s.travelLock or ui.loading.frame.Visible
            audioBindings:tick(now)
        end
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
        mobile:update(dt,state,s.menu or s.travelLock,s.aim,gun() and W.scoped(gun().id) and s.aim)
        local root=U.root(player) local move=hum and Movement.flat(hum.MoveDirection) or Vector3.zero
        local facing=Movement.facing(camera.CFrame.LookVector,root and root.CFrame.LookVector)
        local allowed=living()
        if allowed and hum and root then
            -- All input devices use the same horizontal camera/root basis.
            hum.AutoRotate=false root.CFrame=CFrame.lookAt(root.Position,root.Position+facing)
        elseif hum and not mobile.enabled and mode~="Down" then hum.AutoRotate=true end
        if state and state.status=="Alive" and state.participating then
            local maximum=state.maxStamina or R.stamina(state.perks)
            s.moveStamina=s.moveStamina or state.stamina
            local movement=Movement.policy(move,facing,{alive=true,blocked=not allowed,aiming=s.aim,reloading=now<s.reloading,
                stamina=s.moveStamina,marathon=state.perks.Marathon,requested=s.sprintWanted,wasSprinting=s.sprint})
            if not movement.sprinting and (s.sprintSource=="toggle" or movement.reason=="blocked" or movement.reason=="aiming" or movement.reason=="reload") then s.sprintWanted=false end
            if movement.sprinting~=s.sprint then
                s.sprint=movement.sprinting send("Sprint",{enabled=s.sprint,move=move,blocked=not allowed})
            end
            s.moveStamina=Movement.stamina(s.moveStamina,maximum,s.sprint,dt)
            s.moveSpeed=Movement.approach(s.moveSpeed or 0,movement.speed,dt)
            if hum then hum.WalkSpeed=s.moveSpeed end
            if ui.movement then ui:movement(s.sprint,s.moveStamina,maximum,movement.reason) end
        else s.sprint=false s.sprintWanted=false s.moveSpeed=0 end
        s.sprintMotion=(s.sprintMotion or 0)+((s.sprint and 1 or 0)-(s.sprintMotion or 0))*(1-math.exp(-dt*14))
        if s.fire then shoot() end
        local held=gun() local isAiming=s.aim and living() and now>=s.reloading
        if living() and now>(s.lookSentAt or 0) then
            s.lookSentAt=now+.1 local root=U.root(player)
            if root then local look=root.CFrame:VectorToObjectSpace(camera.CFrame.LookVector)
                send("Look",{pitch=math.asin(math.clamp(look.Y,-1,1)),yaw=math.atan2(-look.X,-look.Z),move=move,blocked=false})
            end
        end
        local aimedFov=held and W.aimFov(held.id) or 57
        aimAlpha=aimAlpha+((isAiming and 1 or 0)-aimAlpha)*math.min(1,dt*18)
        local scoped=held and W.scoped(held.id) and isAiming and aimAlpha>.93
        optic:update(scoped==true,camera.ViewportSize,held and isAiming and aimAlpha>.93 and W.optic(held.id)=="reflex")
        ui.cross.Visible=living() and aimAlpha<.5 and not (mobile.enabled and mobile.settings.fireLayout=="Tap")
        camera.FieldOfView=camera.FieldOfView+((isAiming and aimedFov or fx.settings.fov)-camera.FieldOfView)*math.min(1,dt*14)
        ui:reticle(held and C.Weapons[held.id],camera.FieldOfView,camera.ViewportSize,s.recoil)
        s.recoil=s.recoil*math.exp(-dt*15) fx.shake=fx.shake*math.exp(-dt*7)
        local shake=fx.settings.lowEffects and 0 or fx.settings.shake*fx.shake
        if living() then camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(s.recoil),math.sin(now*57)*shake*.005,0) end
        camera.CFrame=camera.CFrame*CFrame.new(Movement.camera(s.sprint and s.sprintMotion or 0,now,fx.settings.shake,fx.settings.lowEffects,isAiming))
        if s.vm then
            if living() then
                local moving=hum and hum.MoveDirection.Magnitude or 0
                local hip=mobile.enabled and mobile.settings.fireLayout=="Tap" and Vector3.new(.78,-.94,-1.2) or Vector3.new(.64,-.67,-1.1)
                local offset=W.viewOffset(held.id,hip,aimAlpha,camera.FieldOfView,camera.ViewportSize)
                local bob=Vector3.new(math.sin(now*9)*.022*moving,math.abs(math.cos(now*9))*.025*moving,0)*(1-aimAlpha)
                local progress=now<s.reloading and math.clamp((now-s.reloadStarted)/s.reloadDuration,0,1) or 0
                if progress>0 and not s.reloadPresentation then
                    W.beginReload(s.vm,s.reloadMissing,s.reloadAcknowledged,progress) s.reloadPresentation=true
                elseif progress==0 then s.reloadPresentation=false end
                local reloadRoll=progress>0 and math.sin(progress*math.pi)*.48 or 0
                local meleeProgress=now-s.meleeAt<.38 and (now-s.meleeAt)/.38 or 0
                local meleeRoll=meleeProgress>0 and -math.sin(meleeProgress*math.pi)*.95 or 0
                local equip=math.max(0,1-(now-s.equipAt)/.3)
                local sway=Vector3.new(math.sin(now*1.6)*.003,math.cos(now*1.8)*.004,0)*(1-aimAlpha)
                local kick=s.recoil*(1-aimAlpha*.95)
                local physicalKick=W.kickOffset(s.vm,now)*(1-aimAlpha*.8)
                s.vm:PivotTo(camera.CFrame*CFrame.new(offset+bob+sway+Vector3.new(0,-equip*.65,kick*.035+physicalKick-math.sin(meleeProgress*math.pi)*.25))*CFrame.Angles(kick*.012-equip*.3,0,reloadRoll+meleeRoll+(s.sprint and -.35 or 0)))
                W.pose(s.vm,progress,meleeProgress,equip,s.recoil,displayMag()==0,{now=now,missing=s.reloadMissing})
                W.aim(s.vm,scoped==true,W.scoped(held.id) and aimAlpha or 0)
                W.updateEffects(s.vm,now,fx.settings.lowEffects,progress)
                for _,event in ipairs(W.drainPresentationEvents(s.vm)) do
                    -- Legacy Effects remains the fallback. No additional report
                    -- or predicted hit is emitted; acknowledged reload phases
                    -- opt in only when the approved Audio lifecycle API exists.
                    if fx.audioCancel and event.acknowledged and event.phase~="eject" then
                        weaponSound("Weapon.Reload",event.phase,"reload")
                    end
                end
            else cancelPresentation() s.vm:PivotTo(CFrame.new(0,-1000,0)) end
        end
        local char=player.Character local carried=char and char:FindFirstChild("CarriedWeapon")
        if carried then for _,p in ipairs(carried:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier=(mode=="Alive" or mode=="Down") and 1 or 0 end end end
        if state and gun() then ui.ammo.Text=now<s.reloading and "RELOADING" or displayMag().." / "..gun().reserve end
        anim=anim+dt if anim>.033 then fx:animate(anim) anim=0 end
        if not audioBindings and now>ambientAt then
            ambientAt=now+20 fx:sound("Ambient")
            if state and state.participating then fx:sound(state.map=="Frost" and "Wind" or state.map=="Foundry" and "Machinery" or "Radio")
            else fx:sound("Dispatch") end
        end
    end)
    player.CharacterAdded:Connect(function(char) if audioBindings then audioBindings:set(s.state,s.travelLock or ui.loading.frame.Visible) end s.interacting=nil resetInput() cameraMode="" s.vmKey="" task.delay(.6,function() noJump(char) if s.state and s.state.status=="Alive" then rebuild() end end) end)
    pcall(function() script.Destroying:Connect(function()
        if audioBindings then audioBindings:destroy() end
        if fx.audioDestroy then fx:audioDestroy() end
        RunService:UnbindFromRenderStep("DeadSignalPresentation")
    end) end)
    task.spawn(function() while not s.profile do send("Ready",{}) task.wait(2) end end)
    send("Ready",{})
end
return Controller
