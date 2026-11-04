-- R6 construction/authority/animation tests. Native visual acceptance is pending.
local H=require('./Support/InfectedHarness');local r=H.roblox;local V=r.Vector3
local h=H.new();local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local A=h.load(H.folders.server.RigAnatomy)
local function zones(model)
 local out={};for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p:GetAttribute('AuthoritativeHitbox') then out[p.Name]=p end end;return out
end
for _,map in ipairs({'Station','Foundry','Frost'}) do
 h.ctx.map.id=map;local roles={};local stages={}
 for id=1,18 do
  local m,root,hum=h.Rigs.build(nil,'Shambler',V.zero,id,map);local plain=h.Rigs.base(nil,'Shambler',V.zero,id)
  check(m:GetAttribute('PresentationRig')=='R6' and hum.RigType==r.Enum.HumanoidRigType.R6,'actual R6 Humanoid and body contract')
  local motors,bodies,proxies,parts,frames=0,0,0,0,0
  for _,p in ipairs(m:GetDescendants()) do
   check(not p:IsA('MeshPart') and not p:IsA('SurfaceAppearance'),'humanoids have no imported character mesh/texture dependency')
   if p:IsA('Motor6D') then motors+=1 end
   if p:IsA('BasePart') then
    parts+=1;if p:GetAttribute('R6Body') then bodies+=1 end;if p:GetAttribute('R6HitProxy') then proxies+=1 end
    if p:GetAttribute('MilitaryDetail') then check(not p.CanCollide and not p.CanQuery and p.Massless,'cosmetics never absorb hits or block navigation') end
   elseif p:IsA('Frame') then frames+=1 end
  end
  check(motors==6 and bodies==6 and proxies==8,'six driving joints and bodies retain eight rigid query proxies')
  check(parts<=52 and frames<=48,'bounded R6 geometry and printed detail')
  local baseline=zones(plain);local actual=zones(m);local total=0
  for name,p in pairs(baseline) do local q=actual[name];total+=1
   check(q and q.Size==p.Size and q.CFrame==p.CFrame and q.CanQuery and q:GetAttribute('HitZone')==p:GetAttribute('HitZone'),'wardrobe leaves R6 authoritative region untouched '..name)
  end
  check(total==14,'all fourteen existing hit-region names are retained')
  local face=m.Head:FindFirstChild('InfectedFace')
  check(face and face.Face==r.Enum.NormalId.Front and not face.AlwaysOnTop and face.MaxDistance<=70,'face is forward, occluded and distance bounded')
  check(face:FindFirstChild('LeftSocket') and face:FindFirstChild('DamagedMouth') and face:FindFirstChild('DryFissure1'),'original infected facial marks exist')
  check(m.Head.Material~=r.Enum.Material.SmoothPlastic and m.Head.Reflectance==0,'matte infected skin replaces plastic presentation')
  check(m:GetAttribute('VisualAcceptance')=='StudioGameplayPending','code never claims gameplay or visual approval')
  m:PivotTo(r.CFrame.new(3,6,9)*r.CFrame.Angles(0,1.1,0))
  check(root.CFrame.LookVector:Dot(m.Head.CFrame.LookVector)>.9999,'head and face follow the root forward direction')
  roles[m:GetAttribute('InfectedRole')]=true;stages[m:GetAttribute('InfectionStage')]=true
  m:Destroy();plain:Destroy()
 end
 local n=0;for _ in pairs(roles) do n+=1 end;check(n==6 and stages[1] and stages[2] and stages[3],'six themed personnel families and three infection wear stages per map')
end
for _,kind in ipairs({'Shambler','Runner','Crawler','Stalker','Warden'}) do
 local m,root,hum=h.Rigs.build(nil,kind,V.zero,3,'Station');local old=A.build(nil,kind,V.zero,3)
 check(m.BodyCollider.Size==old.BodyCollider.Size and m.BodyCollider.CFrame==old.BodyCollider.CFrame,'R6 retains exact live collider geometry '..kind)
 for _,key in ipairs({'NavigationRootHeight','NavigationRadius','NavigationHeight'}) do check(m:GetAttribute(key)==old:GetAttribute(key),'base navigation contract retained '..key) end
 for _,speed in ipairs({0,5,12}) do for phase=0,16 do
  local poses=h.Pose.transforms(kind,phase*math.pi/8,speed,.5,m:GetAttribute('PoseSeed'),true);local frames=h.Pose.frames(m,poses)
  for name,p in pairs(zones(m)) do check(frames[p]~=nil,'posed R6 hit proxy remains connected '..name) end
  for _,j in ipairs(m:GetDescendants()) do if j:IsA('Motor6D') then
   local a=frames[j.Part0]*(j:GetAttribute('RestC0') or j.C0)*(poses[j.Name] or r.CFrame.identity)
   check((a.Position-(frames[j.Part1]*j.C1).Position).Magnitude<.001,'R6 driving pivot remains coincident')
  end end
 end end
 old:Destroy();m:Destroy()
end
do
 local e=h:enemy('Runner',{Armored=true,Enraged=true,Volatile=true});local hp=e.hp;local head=e.model.Head
 check(e.armorParts.Head.CanQuery and e.reactorParts[1].CanQuery,'armor and reactor remain targetable server Parts')
 h.N.rigBounds(e,'Vault','Cross')
 h.Rigs.breakArmor(e,'Head');check(not e.armorParts.Head and e.weakParts.Head.CanQuery,'armor destruction exposes the existing R6 weak region')
 check(not e.entryGeometry and not e.entryBounds,'armor break invalidates cached entry geometry')
 check(e.weakParts.Head.Position.Z-e.weakParts.Head.Size.Z*.5<head.Position.Z-head.Size.Z*.5,'exposed R6 head weak point lies in front of the head query box')
 h.Rigs.breakArmor(e,'Body')
 check(e.weakParts.Body.Position.Z-e.weakParts.Body.Size.Z*.5<e.model.Torso.Position.Z-e.model.Torso.Size.Z*.5,'exposed R6 body weak point stays targetable outside torso')
 local killed=h.enemies:damage(e,10,nil,true,'r6-authority','Bullet',head)
 check(not killed and e.hp<hp,'R6 head retains server-authoritative nonlethal damage')
 h.enemies:kill(e,nil,false,false);local sockets=0
 for _,p in ipairs(e.model:GetDescendants()) do
  if p:IsA('BallSocketConstraint') then sockets+=1 end
  if p:IsA('BasePart') then check(not p.CanQuery and p.CollisionGroup=='DeadSignalCorpses','dead R6 parts leave hit and player collision groups') end
 end
 check(sockets==5 and e.model:GetAttribute('Ragdoll'),'all five R6 articulated joints enter the existing death path')
end
print('Batch 1 R6 assertions passed:',count)
