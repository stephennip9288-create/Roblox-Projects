-- Run the actual Controller with deterministic clock, signals and UI/services.
-- Input routing/state reconciliation only; not a Studio or physical-input test.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
r.implementMethod('ParticleEmitter','Emit',function() end)
r.implementMethod('ParticleEmitter','Clear',function() end)
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local base=loader.new(dm) local C=base(f.shared.Config) local W=base(f.shared.WeaponModels)
dm.Workspace.CurrentCamera.ViewportSize=r.Vector2.new(1280,720)
local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local function signal()
 local handlers={} return {Connect=function(_,fn) handlers[#handlers+1]=fn end,fire=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end}
end
local now=100 local requests={} local bindings={} local render local ui local mobile
local function folder(t) t.WaitForChild=function(self,name) return assert(self[name],name) end;return t end
local feed={OnClientEvent=signal()}
local remote=folder({Action={FireServer=function(_,op,args) requests[#requests+1]={op=op,args=args} end},Feed=feed})
local shared=folder({Remotes=remote}) for _,m in ipairs(f.shared:GetChildren()) do if m:IsA('ModuleScript') then shared[m.Name]=m end end
local RS=folder({DeadSignal=shared,FindFirstChild=function(_,name) return dm.ReplicatedStorage:FindFirstChild(name) end})
local player={UserId=1,PlayerGui=r.Instance.new('Folder'),PlayerScripts=folder({}),CharacterAdded=signal()}
local Players={LocalPlayer=player,GetPlayers=function() return {player} end}
local UIS={TouchEnabled=false,MouseEnabled=true,WindowFocusReleased=signal(),TextBoxFocused=signal(),focused=nil,
 GetFocusedTextBox=function(self) return self.focused end,GetLastInputType=function() return r.Enum.UserInputType.Keyboard end}
local GuiService={MenuIsOpen=false,MenuOpened=signal()}
local PPS={} for _,key in ipairs({'PromptShown','PromptHidden','PromptTriggered','PromptButtonHoldBegan','PromptButtonHoldEnded'}) do PPS[key]=signal() end
local fakeUI={new=function(_,onMenu)
 ui={gui={},loading={frame={Visible=false},set=function() end},cross={},ammo={},points={},spectateText={},
  setState=function(self,state) self.state=state end,setProfile=function() end,reticle=function() end,
  close=function() onMenu(false) end,toggle=function() end,toast=function() end,banner=function() end,
  hit=function() end,damage=function() end,travel=function() end}
 return ui
end}
local sounds={} local cancellations={}
local fx={settings=table.clone(C.DefaultSettings),shake=0,sound=function(_,key,position,context) sounds[#sounds+1]={key=key,context=context,position=position} end,muzzle=function() end,
 event=function() end,animate=function() end}
local fakeMobile={new=function(_,cb)
 mobile={enabled=false,settings=table.clone(C.DefaultSettings),cb=cb,
  cancel=function() cb.stop() end,cancelFire=function() cb.stop() end,update=function() end,
  setSettings=function() end,summary=function() return {} end,hit=function() end}
 return mobile
end}
local load=loader.new(dm,{services={Players=Players,UserInputService=UIS,GuiService=GuiService,ReplicatedStorage=RS,
 ContextActionService={BindActionAtPriority=function(_,name,fn) bindings[name]=fn end},ProximityPromptService=PPS,
 RunService={PreSimulation=signal(),BindToRenderStep=function(_,_,_,fn) render=fn end},
 TeleportService={GetArrivingTeleportGui=function() end},ReplicatedFirst={RemoveDefaultLoadingScreen=function() end}},
 modules={UI=fakeUI,Effects={new=function() return fx end},MobileControls=fakeMobile,WeaponModels=W,
  Movement={noJump=function() end},DownedPose={client=function() end},ThirdPerson={client=function() end},
  Scope={new=function() return {update=function() end} end}},
 globals={os={clock=function() return now end},task={spawn=function() end,delay=function() end}}})
load(f.client.Controller).start()
check(render~=nil and bindings.DeadSignal_NoJump~=nil,'controller starts and preserves no-jump binding')
local function press(name,state)
 return bindings['DeadSignal_'..name](name,state or r.Enum.UserInputState.Begin,{UserInputType=r.Enum.UserInputType.Keyboard,KeyCode=r.Enum.KeyCode.Q})
end
local function times(op) local n=0 for _,v in ipairs(requests) do if v.op==op then n+=1 end end return n end
local function last(op) for i=#requests,1,-1 do if requests[i].op==op then return requests[i].args end end end
local snapshot={status='Alive',participating=true,travelling=false,phase='Wave',guns={
 {id='Vandal',tier=0,mag=25,reserve=210,reloadUntil=0},{id='Trench',tier=0,mag=6,reserve=48,reloadUntil=0}},
 slot=1,perks={},serverTime=now,team={},stamina=100}
local function state() snapshot.serverTime=now;feed.OnClientEvent:fire('State',snapshot) end
local function tick(dt) now+=dt or .2;render(dt or .2) end
state()
press('Fire');tick();check(times('Fire')==1,'held automatic fire sends a request')
UIS.focused={};UIS.TextBoxFocused:fire();local fired=times('Fire');tick(1)
check(times('Fire')==fired and last('Aim').enabled==false,'text focus cancels held fire and aim')
UIS.focused=nil;tick();check(times('Fire')==fired,'text focus exit requires a new firing gesture')
press('Fire');tick();check(times('Fire')==fired+1,'new fire gesture works after typing')
GuiService.MenuIsOpen=true;GuiService.MenuOpened:fire();fired=times('Fire');tick(1)
check(times('Fire')==fired,'Roblox menu cancels held fire')
GuiService.MenuIsOpen=false;tick();check(times('Fire')==fired,'Roblox menu exit does not resume held fire')
press('Fire');tick();UIS.WindowFocusReleased:fire();fired=times('Fire');tick(1)
check(times('Fire')==fired,'window focus cancellation')
-- Revive/buy prompt holds own their input until end/hidden/triggered; an event
-- belonging to another operator must never cancel the local operator's hold.
local prompt=r.Instance.new('ProximityPrompt');prompt:SetAttribute('RevivePrompt',true)
PPS.PromptShown:fire(prompt);check(prompt.HoldDuration>0,'revive duration follows current perks')
press('Aim');check(last('Aim').enabled,'can aim before interaction')
PPS.PromptButtonHoldBegan:fire(prompt,player);check(not last('Aim').enabled,'revive hold cancels ADS')
fired=times('Fire');press('Fire');tick();check(times('Fire')==fired,'no shot while holding revive')
PPS.PromptButtonHoldEnded:fire(prompt,{UserId=2});press('Fire');tick();check(times('Fire')==fired,'another player cannot end local interaction')
PPS.PromptHidden:fire(prompt);press('Fire');tick();check(times('Fire')==fired+1,'hidden/destroyed prompt releases interaction lock')
PPS.PromptButtonHoldBegan:fire(prompt,player);PPS.PromptTriggered:fire(prompt,player)
press('Fire');tick();check(times('Fire')==fired+2,'completed hold releases interaction lock')
-- Reload and swap reconcile with the server rather than locally cancelling a
-- reload when the player presses the already-equipped slot or lacks a second gun.
press('Reload');check(times('Reload')==1,'reload requested for partial magazine')
press('Aim');check(last('Aim').enabled==false,'reload blocks ADS')
local swaps=times('Swap');press('Slot1');check(times('Swap')==swaps,'current slot is not a swap/reload cancel')
fired=times('Fire');press('Fire');tick(.3);check(times('Fire')==fired,'same-slot input cannot bypass reload lock')
press('Swap');check(times('Swap')==swaps+1 and last('Swap').slot==2,'swap requests explicit other slot')
press('Fire');tick(.3);check(times('Fire')==fired,'unacknowledged swap cannot clear server reload')
snapshot=table.clone(snapshot);snapshot.slot=2;state();tick(.3);press('Fire');tick()
check(times('Fire')==fired+1,'acknowledged swap equips gun and permits fire')
snapshot=table.clone(snapshot);snapshot.slot=1;snapshot.guns={snapshot.guns[1]};state()
swaps=times('Swap');press('Swap');check(times('Swap')==swaps,'no phantom swap with only one gun')
-- Actual server Reload event also drops any previously latched ADS/fire.
press('Aim');feed.OnClientEvent:fire('Reload',{weapon='Vandal',duration=2})
check(not last('Aim').enabled,'server reload cancels ADS')
fired=times('Fire');tick(2.2);check(times('Fire')==fired,'reload completion never resumes an old held gesture')
-- A settled sight remains centered across repeated render steps. Camera recoil
-- is separate from the model, and full ADS removes idle/walking lateral bob.
local walking={MoveDirection=r.Vector3.new(0,0,-1)}
player.Character={FindFirstChild=function() end,FindFirstChildOfClass=function(_,class) return class=='Humanoid' and walking or nil end}
press('Aim');for _=1,20 do tick(.05) end
local camera=dm.Workspace.CurrentCamera local model=camera:FindFirstChild('Weapon_Vandal')
check(model~=nil,'actual viewmodel constructed by controller')
local axis=camera.CFrame:PointToObjectSpace((model.Root.CFrame*model.Root.SightAxis.CFrame).Position)
check(math.abs(axis.X)<.001 and math.abs(axis.Y)<.001,'settled Controller ADS aligns authored sight axis')
press('Aim',r.Enum.UserInputState.End);for _=1,15 do tick(.05) end
axis=camera.CFrame:PointToObjectSpace((model.Root.CFrame*model.Root.SightAxis.CFrame).Position)
check(axis.X>.6,'ADS exit restores hip-side presentation')
-- Status transitions invalidate an interaction even if Roblox omits hold-ended.
PPS.PromptButtonHoldBegan:fire(prompt,player)
snapshot=table.clone(snapshot);snapshot.status='Down';state();snapshot=table.clone(snapshot);snapshot.status='Alive';state()
press('Fire');tick();check(times('Fire')==fired+1,'down/revive transition clears stale prompt lock')
-- A phase transition cancels local presentation, but cannot cancel the server's
-- still-active reload. Reconcile its remaining duration without replaying stages.
snapshot=table.clone(snapshot);snapshot.guns={{id='Vandal',tier=0,mag=20,reserve=210,reloadUntil=now+1.2}};snapshot.phase='Intermission';state()
fired=times('Fire');press('Fire');tick(.3)
check(times('Fire')==fired and ui.ammo.Text=='RELOADING','phase transition respects the authoritative reload deadline')
for _,sound in ipairs(sounds) do check(sound.key~='Weapon.Reload','legacy audio receives no opt-in mechanics') end
-- Optional Audio contract: one existing report, acknowledged stages, canonical
-- context and source cancellation. No dependency on an unmerged Audio module.
fx.audioCancel=function(_,token) cancellations[#cancellations+1]=token end
feed.OnClientEvent:fire('Reload',{weapon='Vandal',duration=2})
local before=#sounds;tick(.5)
check(#sounds==before+1 and sounds[#sounds].key=='Weapon.Reload' and sounds[#sounds].context.phase=='mag-out','acknowledged reload stage emitted once')
local oldToken=sounds[#sounds].context.token
check(sounds[#sounds].context.weaponId=='Vandal' and sounds[#sounds].context.firstPerson==true and type(oldToken)=='string','canonical audio context')
UIS.WindowFocusReleased:fire();check(cancellations[#cancellations]==oldToken,'focus reset cancels source audio token')
tick(.1);before=#sounds;tick(.8)
check(#sounds==before+1 and sounds[#sounds].context.phase=='mag-in' and sounds[#sounds].context.token~=oldToken,'resumed reload avoids replay and stale tokens')
feed.OnClientEvent:fire('Reload',{weapon='Trench',duration=10});tick(1)
check(ui.ammo.Text~='RELOADING','stale other-weapon reload cannot lock current weapon')
print('Combat controller input assertions passed:',count)
