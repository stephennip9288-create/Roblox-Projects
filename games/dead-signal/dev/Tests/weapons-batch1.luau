-- Construction, timing, caps and cleanup of delivered source. No native art or
-- device-performance acceptance is inferred from these controlled tests.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
r.implementMethod('ParticleEmitter','Emit',function(p,n) p:SetAttribute('Emitted',(p:GetAttribute('Emitted') or 0)+n) end)
r.implementMethod('ParticleEmitter','Clear',function(p) p:SetAttribute('Cleared',(p:GetAttribute('Cleared') or 0)+1) end)
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm);local load=loader.new(dm)
local W=load(f.shared.WeaponModels);local B=load(f.shared.WeaponBlueprints);local C=load(f.shared.Config);local Rules=load(f.shared.Rules)
local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local maximum=0 local models=0 local effects=r.Instance.new('Folder')
for id,def in pairs(C.Weapons) do for tier=0,3 do for _,skin in ipairs({'Factory','Copper'}) do
 local model=W.build(id,skin,tier,nil,true);models+=1
 check(model:GetAttribute('WeaponId')==id and model:GetAttribute('FidelityRevision')==1,id..' fitted detail pass')
 check(model:GetAttribute('UpgradeHardwareTier')==tier,id..' upgrade hardware metadata')
 check(model.Root:FindFirstChild('EjectionAxis')~=nil,id..' authored action opening')
 local parts=0 local fitted=0 local fins=0
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  parts+=1;if p:GetAttribute('WeaponFidelity') then fitted+=1 end;if p.Name=='UpgradeHeatFin' then fins+=1 end
  check(not p.CanCollide and not p.CanQuery and not p.CanTouch,id..' presentation cannot change hits/movement')
 end end
 maximum=math.max(maximum,parts);check(parts<350,id..' bounded authored viewmodel parts '..parts)
 check(fitted>=8,id..' individually fitted receiver/action/material hardware')
 check(fins==(tier>0 and 2*(tier+1) or 0),id..' progressive geometry beyond recolor')
 if B[id].optic=='reflex' then check(model:FindFirstChild('ReflexSide')~=nil,id..' open reflex housing') end
 if id=='Cyclone' then for _,group in pairs(W.groups(model)) do check(group~='pump','auto shotgun has no moving pump') end end
  if id=='Breaker' then
   local barrels,shells=0,0
   for _,part in ipairs(model:GetChildren()) do
    if part.Name=='TwinBarrel' or part.Name=='UpgradeBarrel' then barrels+=1 end
    if part.Name=='BreechLoadShell' then shells+=1 end
   end
   local capacity=Rules.weaponStats(def,tier,{}).mag
   check(barrels==capacity and shells==capacity,'Breaker physical barrels and loading shells match authoritative capacity')
  end
 if id=='Kestrel' or id=='Longwatch' then
  local template=dm.ReplicatedStorage.DeadSignalArt:FindFirstChild('Weapon_'..id)
  for _,source in ipairs(template:GetChildren()) do if source:IsA('MeshPart') then
   local p=model:FindFirstChild('Imported'..source.Name)
   -- MeshContent supersedes MeshId in current native files; the source clone
   -- may omit the deprecated default. Compare the content-bearing property.
   local function mesh(part)
    local ok,value=pcall(function() return part.MeshContent end)
    if ok then return tostring(value) end
    return part.MeshId
   end
   check(p~=nil and p:IsA('MeshPart') and mesh(p)==mesh(source),id..' original native mesh retained')
  end end
 end
 local start=W.reloadFrame(id,0,6) local finish=W.reloadFrame(id,1,6)
 check(start.mag.Position.Magnitude<.001 and finish.mag.Position.Magnitude<.001,id..' reload begins/ends seated')
 check(start.left.Magnitude<.001 and finish.left.Magnitude<.001,id..' hands reset at both ends')
 local stages=W.reloadEvents(id,0,1,6);check(#stages>=3,id..' staged action timeline')
 for i=2,#stages do check(stages[i].at>=stages[i-1].at,id..' stage ordering') end
 if B[id].reloadStyle=='tube' then
  local shell=0 for _,event in ipairs(stages) do if event.phase=='shell-in' then shell+=1 end end
  check(shell==6,id..' shell presentation count uses missing-round context')
  local capacity=Rules.weaponStats(def,tier,{}).mag
  for _,missing in ipairs({1,capacity-1,capacity}) do
   local total=0 local sequence=W.reloadEvents(id,0,1,missing)
   for _,event in ipairs(sequence) do if event.phase=='shell-in' then total+=1 end end
   check(total==missing and #sequence<=16,id..' partial/full upgraded shell count '..missing)
  end
 end
 if B[id].action=='revolver' then
  local chambers,rounds=0,0
  for _,p in ipairs(model:GetChildren()) do
   if p.Name=='CylinderChamber' then chambers+=1 elseif p.Name=='SpeedLoadRound' then rounds+=1 end
  end
  local capacity=Rules.weaponStats(def,tier,{}).mag
  check(chambers==capacity and rounds==capacity,id..' cylinder/loader matches current upgrade capacity')
 end
 -- Actual poses move the entire front action/feeds together, then restore.
 local moving=model:FindFirstChild(id=='Breaker' and 'SightFront' or id=='Anchor' and 'FeedRound' or 'Magazine')
 local original=moving and moving.CFrame
 W.pose(model,.5,0,0,0,false,{now=10,missing=6})
 if id=='Breaker' or id=='Anchor' then check((moving.CFrame.Position-original.Position).Magnitude>.02,id..' front/feed follows hinge') end
 W.pose(model,0,0,0,0,false,{now=10,missing=6})
 if moving then check((moving.CFrame.Position-original.Position).Magnitude<.001,id..' pose resets after cancel') end
 W.bindEffects(model,effects)
 for _,low in ipairs({false,true}) do
  W.clearEffects(model)
  local t=20
  for n=1,80 do
   t+=.07;W.shot(model,t,low,.07);W.updateEffects(model,t+.04,low,0)
   W.pose(model,0,0,0,1,false,{now=t+.04})
   local stats=W.effectStats(model)
   check(stats.active<=(low and 2 or 8) and stats.pool<=8 and stats.queued<=8 and stats.events<=16,id..' firing effects bounded at high rate')
  end
  W.updateEffects(model,t+1,low,0)
  check(W.effectStats(model).active==0 and W.effectStats(model).queued==0,id..' casing TTL and queue expire')
  check(model.Muzzle.Flash.Brightness==0,id..' muzzle flash expires without delayed callbacks')
  local flash=model.Muzzle:FindFirstChild('WeaponFlash');check(flash and flash.Rate==0,id..' cached one-shot muzzle flash')
  if low then check((flash:GetAttribute('Emitted') or 0)>0,id..' reduced effects retains firing cue') end
  W.beginReload(model,6,true)
  for _,progress in ipairs({.05,.20,.30,.55,.75,.98}) do W.updateEffects(model,t+progress,low,progress) end
  local events=W.drainPresentationEvents(model);local phases={}
  for _,event in ipairs(events) do
   phases[event.phase]=(phases[event.phase] or 0)+1
   check(event.token~=nil,id..' semantic stages carry lifecycle token')
  end
  if B[id].action=='energy' then check(W.effectStats(model).active==0,id..' energy never ejects brass') end
  if B[id].action=='revolver' or B[id].action=='break' then check(phases.eject==1,id..' manual-action ejection occurs once during reload') end
  W.clearEffects(model)
  check(W.effectStats(model).active==0 and W.effectStats(model).queued==0 and #W.drainPresentationEvents(model)==0,id..' lifecycle cancellation clears effects/stages')
  W.updateEffects(model,t+4,low,.5);check(W.effectStats(model).active==0,id..' cancelled reload cannot emit stale ejections')
  W.shot(model,t+5,low,.2);W.updateEffects(model,t+5.4,low,0)
  check(model.Muzzle.WeaponFlash.Rate==0,id..' firing works after reset without duplicate emitters')
 end
 for _,p in ipairs(effects:GetDescendants()) do if p:IsA('BasePart') then check(not p.CanQuery and not p.CanCollide,id..' casings never join server geometry') end end
 W.clearEffects(model,true);model:Destroy()
 check(#effects:GetChildren()==0,id..' destroyed viewmodel removes cosmetic container')
end end end
-- The ceiling applies across simultaneous local sources, including replacement
-- overlap, rather than granting each viewmodel its own eight active casings.
local a=W.build('Vandal','Factory',0,nil,true) local b=W.build('Rook','Factory',0,nil,true)
W.bindEffects(a,effects);W.bindEffects(b,effects)
for _,low in ipairs({false,true}) do
 for n=1,20 do
  local t=60+n*.04;W.shot(a,t,low,.04);W.shot(b,t,low,.04)
  W.updateEffects(a,t+.02,low,0);W.updateEffects(b,t+.02,low,0)
  check(W.effectStats(a).active+W.effectStats(b).active<=(low and 2 or 8),'shared per-client casing cap')
 end
end
W.clearEffects(a,true);W.clearEffects(b,true);a:Destroy();b:Destroy()
check(#effects:GetChildren()==0,'all simultaneous cosmetic sources are removed')
-- The reflex sight has a zero at the same full-viewport center as the magnified
-- optic, and never enables its black masks or shifts for a phone safe inset.
local Scope=load(f.client.Scope);local parent=r.Instance.new('Folder');local gui=r.Instance.new('ScreenGui');gui.Parent=parent;gui.DisplayOrder=20
local optic=Scope.new(gui)
for _,size in ipairs({{320,568},{568,280},{844,390},{1024,768},{1920,1080},{3440,1440}}) do
 optic:update(false,r.Vector2.new(size[1],size[2]),true)
 check(optic.reflex.Visible and not optic.frame.Visible,'reflex does not mask the target')
 check(optic.reflex.Position==r.UDim2.new(.5,-10,.5,-10) and optic.reflex.ZeroPoint.Position==r.UDim2.fromOffset(9,9),'reflex zero remains at shot axis')
 optic:update(true,r.Vector2.new(size[1],size[2]),true);check(not optic.reflex.Visible and optic.frame.Visible,'magnified optic owns its aperture')
 optic:update(false,r.Vector2.new(size[1],size[2]),false);check(not optic.reflex.Visible and not optic.frame.Visible,'reload/down/hip exits optic')
end
print('Batch 1 weapon fidelity assertions passed:',count)
print('Native-preserving models:',models,'maximum authored viewmodel parts:',maximum)
