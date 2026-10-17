-- Actual viewmodel geometry and UI methods; no native rendering/device claim.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local Settings=require('../Source/Runtime/shared/ControlSettings')
local Layout=require('../Source/Runtime/shared/TouchLayout')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'))
local f=loader.install(dm) local tweens={}
local load=loader.new(dm,{globals={TweenInfo={new=function() return {} end}},services={Players={LocalPlayer={UserId=1}},TweenService={Create=function(_,obj,_,props)
 local t={object=obj,props=props,Play=function() end,Cancel=function(self) self.cancelled=true end}
 tweens[#tweens+1]=t return t
end}}})
local W=load(f.shared.WeaponModels) local C=load(f.shared.Config) local UI=load(f.client.UI)
local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local V,CF=r.Vector3,r.CFrame
local sizes={{568,280},{640,320},{740,340},{800,360},{360,740},{1024,700},{1280,760},{1920,1080},{2560,1080}}
-- A conservative oriented-box ray test: even mesh bounds must leave the shot
-- axis clear. This is intentionally stricter than inspecting mesh triangles.
local function blocks(part)
 if part.Transparency>.95 or part.LocalTransparencyModifier>.95 then return false end
 local origin=part.CFrame:PointToObjectSpace(V.zero) local dir=part.CFrame:VectorToObjectSpace(V.new(0,0,-1))
 local half=part.Size*.5 local near,far=0,100
 for _,axis in ipairs({'X','Y','Z'}) do
  if math.abs(dir[axis])<.00001 then if math.abs(origin[axis])>half[axis] then return false end
  else local a=(-half[axis]-origin[axis])/dir[axis] local b=(half[axis]-origin[axis])/dir[axis]
   near=math.max(near,math.min(a,b)) far=math.min(far,math.max(a,b)) if near>far then return false end
  end
 end
 return far>0 and near<=far
end
local models=0
for id in pairs(C.Weapons) do for tier=0,3 do
 local model=W.build(id,'Factory',tier,nil,true) models+=1
 check(model:GetAttribute('WeaponArtRevision')==9,id..' art revision')
 check(model.Root:FindFirstChild('SightAxis')~=nil,id..' sight authoring reference')
 check(model:FindFirstChild('RearSightIndex')~=nil,id..' readable rear sight, including imported art')
 for _,size in ipairs(sizes) do for _,fov in ipairs({34,44,57,80,100}) do
  local viewport=r.Vector2.new(size[1],size[2])
  local offset=W.viewOffset(id,V.new(.64,-.67,-1.1),1,fov,viewport)
  model:PivotTo(CF.new(offset));W.pose(model,0,0,0,0);W.aim(model,W.scoped(id),1)
  local axis=model.Root.CFrame*model.Root.SightAxis.CFrame
  check(math.abs(axis.X)<.00001 and math.abs(axis.Y)<.00001 and axis.Z<-.25,id..' sight projects to exact screen center')
  for _,p in ipairs(model:GetChildren()) do if p:IsA('BasePart') then check(not blocks(p),id..' clear aimed ray: '..p.Name) end end
 end end
 W.aim(model,false,0)
 for _,p in ipairs(model:GetChildren()) do if p:IsA('BasePart') then check(p.LocalTransparencyModifier==0,id..' hip visibility restored') end end
 local hip=V.new(.78,-.94,-1.2)
 check((W.viewOffset(id,hip,0,80,r.Vector2.new(568,280))-hip).Magnitude<.00001,id..' original hip position preserved')
 -- Reload/melee/equip poses are reversible and never make geometry queryable.
 for _,progress in ipairs({.2,.5,.85}) do W.pose(model,progress,progress,progress,3) end
 W.pose(model,0,0,0,0)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  check(not p.CanCollide and not p.CanQuery and not p.CanTouch,id..' presentation remains outside hit validation')
 end end
 if id=='Kestrel' or id=='Needle' then
  local slide
  for _,p in ipairs(model:GetChildren()) do if W.groups(model)[p.Name]=='slide' then slide=p break end end
  check(slide~=nil,id..' animated slide present')
  local before=slide.CFrame;W.pose(model,0,0,0,0,true)
  check((slide.CFrame.Position-before.Position).Magnitude>.13,id..' empty slide locks back')
  W.pose(model,.4,0,0,0,true);check((slide.CFrame.Position-before.Position).Magnitude<.001,id..' reload releases slide lock')
 end
 model:Destroy()
end end
-- Exercise every visibility combination, mirror and existing firing layout.
-- Both an extraction/Warden panel and special warnings may be received close
-- together during state transitions, so test the worst combined presentation.
local cases=0
for _,size in ipairs(sizes) do for _,mode in ipairs({'Tap','Left','Classic'}) do for _,mirror in ipairs({false,true}) do
 local settings=Settings.resolve({fireLayout=mode,leftHanded=mirror}) local before=table.clone(settings)
 local layout=Layout.build(size[1],size[2],settings)
 for _,flags in ipairs({{}, {crew=true,down=true}, {banner=true,toast=true,effects=true},
  {boss=true,crew=true,down=true,effects=true}, {banner=true,toast=true,boss=true,crew=true,down=true,effects=true,perks=true}}) do
  local hud=Layout.combatHUD(layout,settings,flags) cases+=1
  check(not hud.crowded,'HUD fits '..size[1]..'x'..size[2]..' '..mode..' mirrored '..tostring(mirror))
  local controls={layout.move} if mode~='Tap' then controls[#controls+1]=layout.fire end
  for _,rect in pairs(layout.buttons) do controls[#controls+1]=rect end
  local rects={}
  for key,rect in pairs(hud) do if type(rect)=='table' and rect.x then
   check(rect.x>=0 and rect.y>=0 and rect.x+rect.w<=size[1]+.001 and rect.y+rect.h<=size[2]+.001,'on-screen '..key)
   for _,control in ipairs(controls) do check(not Layout.intersects(rect,control,3.9),'HUD avoids touch control: '..key) end
   for _,other in ipairs(rects) do check(not Layout.intersects(rect,other,3.9),'HUD widgets do not overlap: '..key) end
   rects[#rects+1]=rect
  end end
  if flags.down then check(hud.crew~=nil,'revive status never discarded for cosmetic perks') end
  if flags.boss then check(hud.boss~=nil,'Warden status retained') end
  if flags.banner then check(hud.banner~=nil,'event warning retained') end
  if flags.effects then check(hud.effects~=nil,'active status durations retained') end
 end
 for key,value in pairs(before) do check(settings[key]==value,'HUD must not change saved control settings') end
end end end
-- The actual scope GUI keeps its full circular aperture and zero at each ratio.
local Scope=load(f.client.Scope) local parent=r.Instance.new('Folder')
local gui=r.Instance.new('ScreenGui');gui.Parent=parent;gui.DisplayOrder=20
local optic=Scope.new(gui)
for _,size in ipairs(sizes) do
 optic:update(true,r.Vector2.new(size[1],size[2]))
 check(optic.frame.Visible and #optic.strips==96,'scope visible with bounded mask count')
 check(optic.frame.ZeroPoint.Position==r.UDim2.new(.5,-1,.5,-1),'scope zero centered without safe-area shift')
end
optic:update(false,r.Vector2.new(568,280));check(not optic.frame.Visible,'scope leaves on aim/reload exit')
-- Actual crosshair and hit methods: broad shotgun spread differs from a rifle,
-- and newer hits cancel older fades. Text makes head/kill feedback non-color-only.
local ui=setmetatable({crossBars={},marker=r.Instance.new('TextLabel'),hitCaption=r.Instance.new('TextLabel')},UI)
for i=1,4 do ui.crossBars[i]=r.Instance.new('Frame') end
ui:reticle(C.Weapons.Vandal,80,r.Vector2.new(1280,720),0);local rifle=ui.reticleGap
ui:reticle(C.Weapons.Trench,80,r.Vector2.new(1280,720),0);check(ui.reticleGap>rifle,'crosshair reflects angular weapon spread')
ui:reticle(C.Weapons.Trench,80,r.Vector2.new(1280,720),3);check(ui.reticleGap>rifle,'recoil feedback bounded')
ui:hit(false,true);check(ui.hitCaption.Text=='HEAD','headshot has a word cue')
local old=ui.hitTween;ui:hit(true,false);check(old.cancelled and ui.hitCaption.Text=='KILL','rapid hits replace their fade; kill has a word cue')
ui.profile={settings={hitmarkers=false}};local n=#tweens;ui:hit(true,true);check(#tweens==n,'saved hitmarker preference respected')
-- Run actual MobileControls:blocked; world-prompt fallback must not disable
-- saved controls, while processed UI and actual buttons always keep priority.
local objects={} local userInput={GetFocusedTextBox=function() end} local guiService={MenuIsOpen=false}
local touchLoad=loader.new(dm,{services={UserInputService=userInput,GuiService=guiService,
 Players={LocalPlayer={PlayerGui={GetGuiObjectsAtPosition=function() return objects end}}}},
 globals={workspace={CurrentCamera={WorldToScreenPoint=function(_,pos) return pos,true end}}}})
local Mobile=touchLoad(f.client.MobileControls)
local settings=Settings.resolve({fireLayout='Classic'}) local layout=Layout.build(640,320,settings)
local target=r.Instance.new('Part');target.Position=V.new(layout.fire.x+layout.fire.w/2,layout.fire.y+layout.fire.h/2,0)
local prompt=r.Instance.new('ProximityPrompt');prompt.Parent=target
local mobile=setmetatable({frame={AbsolutePosition=r.Vector2.zero},settings=settings,layout=layout,prompts={[prompt]=true}},Mobile)
local input={Position=target.Position}
check(not mobile:blocked(input,false),'world prompt fallback cannot swallow a fire pad')
check(mobile:blocked(input,true),'actual processed prompt/UI consumes touch')
objects={{IsDescendantOf=function() return false end,IsA=function(_,kind) return kind=='GuiButton' end}}
check(mobile:blocked(input,false),'actual interactive GUI wins over the fire pad')
objects={};target.Position=V.new(340,80,0);input.Position=target.Position
check(mobile:blocked(input,false),'tap on a visible world prompt cannot become a shot')
guiService.MenuIsOpen=true;input.Position=V.new(600,250,0)
check(mobile:blocked(input,false),'Roblox menu consumes all touch input')
-- Actual state presentation keeps inventory and revive counts legible even
-- when a long weapon/crew name has to be truncated by the compact rectangle.
local stateUI=setmetatable({layout={compact=true},loading={update=function() end},resize=function() end},UI)
for _,name in ipairs({'round','waveInfo','points','healthText','perks','objective','bossName','effects','team','ammo','weapon','grenades','lobbyInfo','queue'}) do stateUI[name]=r.Instance.new('TextLabel') end
for _,name in ipairs({'hud','shade','lobby','menuButton','healthBar','staminaBar','extractionBar','bossBG','bossBar','cross','spectate'}) do stateUI[name]=r.Instance.new('Frame') end
stateUI.shade.Visible=false;stateUI.reticleGui=r.Instance.new('ScreenGui')
local state={status='Alive',participating=true,role='Match',phase='Exfil',round=20,points=500,
 timer=30,left=10,health=100,maxHealth=100,stamina=80,maxStamina=100,perks={},serverTime=100,
 effects={Double=120,Instant=115,Sale=110},team={{id=1,name='Me',status='Alive'},{id=2,name='LongCrewDisplayName',status='Down'}},
 guns={{id='Vandal',tier=3,mag=30,reserve=210,reloadUntil=0}},slot=1,grenades=3,
 extraction={title='ELIMINATE THE WARDEN',stage='Warden',progress=20,inside=1,alive=2,distance=50},
 boss={hp=80,max=100,phase=2}}
stateUI:setState(state,28)
check(stateUI.team.Text:find('REVIVE 1:',1,true)~=nil,'compact crew includes explicit down count')
check(stateUI.grenades.Text=='G 3' and not stateUI.weapon.Text:find('GRENADES',1,true),'grenades have their own compact label')
check(stateUI.objective.Text:find('ELIMINATE THE WARDEN',1,true)~=nil and stateUI.bossName.Visible,'extraction and Warden instructions retained')
check(stateUI.effects.Text:find('2x POINTS',1,true)~=nil and stateUI.effects.Text:find('LETHAL',1,true)~=nil,'all active compact power-up durations retained')
state.status='Down';state.downLeft=18;stateUI:setState(state,28)
check(stateUI.healthText.Text:find('18s',1,true)~=nil,'down countdown remains in the compact vital label')
print('Combat/UI geometry and layout assertions passed:',count)
print('Weapon/tier models:',models,'HUD scenarios:',cases)
