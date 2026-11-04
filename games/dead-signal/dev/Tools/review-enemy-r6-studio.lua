-- Paste in the SERVER Command Bar of a disposable Studio candidate only.
-- Uses the candidate's installed source. Never saves or publishes a place.
local Run=game:GetService("RunService")
assert(Run:IsStudio(),"R6 review gallery is Studio-only")
local R=require(game.ServerScriptService.DeadSignalServer.EnemyRigs)
local P=require(game.ReplicatedStorage.DeadSignal.NPCPose)
local previous=workspace:FindFirstChild("DeadSignalR6Review")
if previous then previous:Destroy() end
local folder=Instance.new("Folder");folder.Name="DeadSignalR6Review";folder.Parent=workspace
folder:SetAttribute("SourceReviewOnly",true)
local player=game:GetService("Players"):GetPlayers()[1]
local character=player and player.Character;local playerRoot=character and character:FindFirstChild("HumanoidRootPart")
local origin=(playerRoot and playerRoot.Position or Vector3.new(0,20,0))+Vector3.new(0,3,-30)
local rows={}
local function add(map,kind,id,x,z,action,mods)
 local m,root,hum=R.build(folder,kind,origin+Vector3.new(x,0,z),id,map)
 R.evolve({id=id,kind=kind,model=m,root=root,hum=hum,mods=mods or {}})
 assert(m:GetAttribute("PresentationRig")=="R6","Candidate has not installed R6 source")
 root.Anchored=true;hum.AutoRotate=false;hum.PlatformStand=true
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(210,46);gui.StudsOffset=Vector3.new(0,3.9,0);gui.MaxDistance=100;gui.Parent=m.Head
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.25;label.BackgroundColor3=Color3.fromRGB(19,27,23)
 label.TextColor3=Color3.fromRGB(224,229,215);label.TextSize=12;label.TextWrapped=true;label.Text=map.." / "..kind.." / "..(m:GetAttribute("InfectedRole") or "").."\n"..action;label.Parent=gui
 rows[#rows+1]={model=m,root=root,action=action}
end
for mi,map in ipairs({"Station","Foundry","Frost"}) do for id=1,6 do
 add(map,"Shambler",id,(id-1)*7,(mi-1)*11,"shamble")
end end
for i,spec in ipairs({{"Runner","run",{}},{"Crawler","crawl",{}},{"Stalker","attack",{}},{"Warden","vault",{}},
 {"Runner","hit",{Enraged=true}},{"Shambler","shamble",{Armored=true}},{"Shambler","attack",{Volatile=true}},
 {"Runner","vault",{Armored=true,Enraged=true}}}) do
 add("Station",spec[1],7+i,(i-1)*7,38,spec[2],spec[3])
end
local function pose(time)
 for _,row in ipairs(rows) do
  local m=row.model;local a=row.action;local age=time%1.8
  m:SetAttribute("AttackAt",a=="attack" and time-age or nil)
  m:SetAttribute("HitAt",a=="hit" and time-age or nil)
  m:SetAttribute("HitVector",Vector3.new(1,0,-1).Unit);m:SetAttribute("HitStrength",.65);m:SetAttribute("HitHead",true)
  m:SetAttribute("TraversalStage",a=="vault" and "Cross" or nil)
  m:SetAttribute("TraversalStyle",a=="vault" and "Vault" or nil)
  m:SetAttribute("TraversalStageAt",time-age);m:SetAttribute("TraversalStageDuration",1.8)
  row.root.AssemblyLinearVelocity=Vector3.new(0,0,a=="run" and -12 or -4)
  local transforms=P.sample(m,row.root,time)
  for _,j in ipairs(m:GetDescendants()) do if j:IsA("Motor6D") then
   j.C0=(j:GetAttribute("RestC0") or j.C0)*(transforms[j.Name] or CFrame.identity);j.Transform=CFrame.identity
  end end
 end
end
pose(workspace:GetServerTimeNow())
if Run:IsRunning() then
 local connection
 connection=Run.Heartbeat:Connect(function()
  if not folder.Parent then connection:Disconnect();return end
  pose(workspace:GetServerTimeNow())
 end)
end
print("Studio R6 gallery ready. Delete Workspace.DeadSignalR6Review to remove it. This gallery has no gameplay AI, collision, damage or traversal simulation; test those in real waves separately.")
