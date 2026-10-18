-- Structural animation/art checks. Native rendering/asset quality is unverified.
local harness=require('./Support/InfectedHarness');local r=harness.roblox;local V=r.Vector3
local h=harness.new();local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local Anatomy=h.load(harness.folders.server.RigAnatomy)
local function zones(model)
 local out={};for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p:GetAttribute('AuthoritativeHitbox') then
  out[p.Name]={cf=p.CFrame,size=p.Size,query=p.CanQuery,zone=p:GetAttribute('HitZone')}
 end end;return out
end
for _,map in ipairs({'Station','Foundry','Frost'}) do
 h.ctx.map.id=map
 for id=1,18 do
  local e=h:enemy('Shambler');local before=Anatomy.build(h.enemies.folder,'Shambler',e.root.Position,e.id)
  for name,p in pairs(zones(before)) do local q=e.model:FindFirstChild(name)
   check(q and (q.CFrame.Position-p.cf.Position).Magnitude<.0001 and q.CFrame.LookVector:Dot(p.cf.LookVector)>.99999 and q.Size==p.size and q.CanQuery==p.query and q:GetAttribute('HitZone')==p.zone,'art never changes authoritative '..name)
  end
  check(e.model:GetAttribute('MilitaryDetailCount')<=66,'bounded generated detail')
  check(e.model:GetAttribute('VisualAcceptance')=='StudioAndAuthoredArtPending','source does not assert visual acceptance')
  local native=0;for _,p in ipairs(e.model:GetDescendants()) do if p:IsA('MeshPart') then
   native+=1;local ok,content=pcall(function() return tostring(p.MeshContent) end)
   check(ok and content:find('rbxassetid://')~=nil,'retained native mesh content is present')
  end end
  check(native>0,'native art is retained instead of replaced by primitive anatomy')
  if e.model:GetAttribute('OutfitName')=='Infantry' then
   check(not e.model:FindFirstChild('DamagedHelmet') and e.model:FindFirstChild('BrokenFieldHeadset'),'communications personnel expose the face')
  end
  before:Destroy();e.model:Destroy();h.enemies.list[e.id]=nil
 end
end
for _,kind in ipairs({'Shambler','Runner','Crawler','Hound','Stalker','Warden'}) do
 local e=h:enemy(kind)
 for _,speed in ipairs({0,5,12}) do for n=0,16 do
  local poses=h.Pose.transforms(kind,n*math.pi/8,speed,.5,e.model:GetAttribute('PoseSeed'))
  local frames=h.Pose.frames(e.model,poses)
  for _,j in ipairs(e.model:GetDescendants()) do if j:IsA('Motor6D') then
   check(frames[j.Part1]~=nil,'every articulated bone is connected')
   local a=frames[j.Part0]*(j:GetAttribute('RestC0') or j.C0)*(poses[j.Name] or r.CFrame.identity)
   local b=frames[j.Part1]*j.C1
   check((a.Position-b.Position).Magnitude<.001,'pose keeps elbow/knee/wrist/ankle attachment continuity')
  end end
 end end
 if kind=='Shambler' or kind=='Runner' or kind=='Warden' then
  local poses=h.Pose.transforms(kind,0,0,0,1.37)
  check(poses['Right Shoulder']~=poses['Left Shoulder'] and poses['Right Elbow']~=poses['Left Elbow'],'asymmetric reanimated idle carriage')
 end
 local collider=e.model.BodyCollider;check(collider:FindFirstChildOfClass('WeldConstraint').Part0==e.root,'visual lean cannot animate the physical collider')
end
-- Reverse animation phase uses the same named stage, decreasing continuously.
for _,kind in ipairs({'Shambler','Runner','Stalker','Warden'}) do
 local e=h:enemy(kind)
 local frames=h.Pose.frames(e.model,h.Pose.traversal(kind,'Vault','Cross',.5))
 for _,side in ipairs({'Left','Right'}) do
  local hand=frames[e.model:FindFirstChild(side..' Hand')].Position
  local torso=frames[e.model.Torso].Position
  check(hand.Y>torso.Y+.5 and hand.Z<torso.Z-1,'vaulting hands brace ahead of chest instead of hanging below the waist')
 end
end
do
 local e=h:enemy('Shambler');e.model:SetAttribute('TraversalStage','Cross');e.model:SetAttribute('TraversalStyle','Vault')
 e.model:SetAttribute('TraversalDirection',-1);e.model:SetAttribute('TraversalStageAt',101);e.model:SetAttribute('TraversalStageDuration',1)
 local a=h.Pose.sample(e.model,e.root,100.3);local b=h.Pose.sample(e.model,e.root,100.6)
 check(a['Right Hip']~=b['Right Hip'],'reverse traversal has changing joint motion')
end
print('Batch 1.1 enemy appearance assertions passed:',count)
