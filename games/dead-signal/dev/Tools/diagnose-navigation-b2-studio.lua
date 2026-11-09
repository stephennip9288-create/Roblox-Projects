-- SERVER Command Bar, running disposable Studio candidate only. No save/publish.
-- Remove Workspace.DeadSignalNavigationReview to stop and free the diagnostic ring.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and Run:IsRunning(),"Navigation overlay requires a running Studio server")
local D=require(game.ServerScriptService.DeadSignalServer.Diagnostics)
D.navigation(true)
local old=workspace:FindFirstChild("DeadSignalNavigationReview");if old then old:Destroy() end
local folder=Instance.new("Folder");folder.Name="DeadSignalNavigationReview";folder.Parent=workspace
folder:SetAttribute("InspectEnemyId",0)
local labels,dots,lines={},{},{}
local function marker(name)
 local p=Instance.new("Part");p.Name=name;p.Size=Vector3.new(.22,.22,.22);p.Anchored=true
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Material=Enum.Material.Neon;p.Parent=folder
 return p
end
for i=1,40 do
 local p=marker("Actor"..i);p.Transparency=1
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(245,75);gui.AlwaysOnTop=true;gui.MaxDistance=100;gui.Parent=p
 local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.Font=Enum.Font.Code;text.TextSize=12
 text.BackgroundColor3=Color3.fromRGB(13,20,18);text.BackgroundTransparency=.15;text.TextColor3=Color3.fromRGB(225,236,224);text.TextWrapped=true;text.Parent=gui
 labels[i]={part=p,gui=gui,text=text}
end
for i=1,24 do local p=marker("Waypoint"..i);p.Color=Color3.fromRGB(240,196,87);dots[i]=p end
for i=1,24 do local p=marker("Segment"..i);p.Color=Color3.fromRGB(90,196,180);lines[i]=p end
local function v(x) return x and Vector3.new(x[1],x[2],x[3]) end
local elapsed=0;local connection
connection=Run.Heartbeat:Connect(function(dt)
 if not folder.Parent then connection:Disconnect();D.navigation(false);return end
 elapsed+=dt;if elapsed<.5 then return end;elapsed=0
 local snapshot=D.navigation();if not snapshot.enabled then folder:Destroy();return end
 local selected
 for i=1,40 do
  local row=snapshot.actors[i];local label=labels[i];label.gui.Enabled=row~=nil
  if row then
   label.part.Position=v(row.position)+Vector3.new(0,4,0)
   label.text.Text=string.format("#%d %s | room %s -> %s\n%s | %s | door %s\nno progress %.1fs | paths %d | recovery %d",
    row.id,row.kind,tostring(row.room),tostring(row.targetRoom),row.state or "idle",row.failure or "clear",tostring(row.blockedDoor),
    row.secondsWithoutProgress,row.pathRequests,row.recoveries)
   if row.id==folder:GetAttribute("InspectEnemyId") or not selected then selected=row end
  end
 end
 local path=selected and (#selected.waypoints>0 and selected.waypoints or selected.route) or {}
 local previous=selected and v(selected.position)
 for i=1,24 do
  local point=v(path[i]);dots[i].Transparency=point and 0 or 1;lines[i].Transparency=point and previous and 0 or 1
  if point then
   point+=Vector3.new(0,.3,0);dots[i].Position=point
   local delta=point-previous
   if delta.Magnitude>.01 then lines[i].Size=Vector3.new(.06,.06,delta.Magnitude);lines[i].CFrame=CFrame.lookAt((point+previous)*.5,point) end
   previous=point
  end
 end
 folder:SetAttribute("Live",snapshot.live);folder:SetAttribute("Pending",snapshot.pending)
 folder:SetAttribute("ActivePaths",snapshot.activePaths);folder:SetAttribute("PathRequests",snapshot.counters["path-request"] or 0)
 folder:SetAttribute("RequestsPerSecond",(snapshot.counters["path-request"] or 0)/math.max(.001,snapshot.seconds))
end)
print("Studio navigation review enabled (40 labels / 24 segments / 2Hz). Set the folder's InspectEnemyId to select an actor. Diagnostics.navigation() returns capped waypoints, room route, blocked doors and the last128 trace events. Remove the folder to stop. No physics/navmesh/device result is inferred from this tool.")
