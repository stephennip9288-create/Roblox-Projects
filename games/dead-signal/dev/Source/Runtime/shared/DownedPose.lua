-- Replicated C0 poses support both R6 and R15 without uploaded animation IDs.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local Movement=require(RS.DeadSignal.Movement)
local D={}
local function rotate(base,rotation,position)
    return CFrame.new(position or base.Position)*rotation*(base-base.Position)
end
function D.rotation(name,phase)
    local side=name:find("Right") and 1 or -1
    if name=="RootJoint" or name=="Root" then return CFrame.Angles(-math.pi/2,0,0)
    elseif name=="Waist" then return CFrame.Angles(.08,0,math.sin(phase)*.025)
    elseif name:find("Shoulder") then
        -- Positive shoulder pitch brings the hands forward AND down after prone rotation.
        local pitch=name:find(" ") and 2.75 or 2.5
        return CFrame.Angles(pitch+math.sin(phase+side*math.pi/2)*.12,side*.08,side*.10)
    elseif name:find("Elbow") then return CFrame.Angles(.55,0,0)
    elseif name:find("Wrist") then return CFrame.Angles(.12,0,0)
    elseif name:find("Hip") then return CFrame.Angles(math.sin(phase+side*math.pi/2)*.10,side*.025,side*.035)
    elseif name:find("Knee") then return CFrame.Angles(.16,0,0)
    elseif name:find("Ankle") then return CFrame.Angles(-.12,0,0)
    elseif name=="Neck" then return CFrame.Angles(1.12,0,0) end
    return CFrame.new()
end
function D.clear(state)
    local pose=state.downedPose if not pose then return end state.downedPose=nil
    for _,j in ipairs(pose.joints) do if j.motor.Parent then j.motor.C0=j.c0 j.motor.C1=j.c1 j.motor.Transform=CFrame.new() end end
    for _,v in ipairs(pose.parts) do if v.part.Parent then v.part.CanCollide=v.collide v.part.Size=v.size end end
    if pose.hum.Parent then pose.hum.HipHeight=pose.hip pose.hum.AutoRotate=pose.auto Movement.noJump(pose.hum) end
    if pose.animate and pose.animate.Parent then pose.animate.Disabled=pose.disabled end
    if pose.char.Parent then pose.char:SetAttribute("DeadSignalCrawling",false) end
    for _,obj in ipairs(pose.markers) do obj:Destroy() end
end
function D.begin(player,state)
    D.clear(state)
    local char=player.Character local root=U.root(player) local hum=U.humanoid(player)
    if not char or not root or not hum then return end
    local pose={char=char,root=root,hum=hum,hip=hum.HipHeight,auto=hum.AutoRotate,joints={},parts={},markers={}}
    pose.animate=char:FindFirstChild("Animate")
    if pose.animate then pose.disabled=pose.animate.Disabled pose.animate.Disabled=true end
    pcall(function() for _,track in ipairs(hum:GetPlayingAnimationTracks()) do track:Stop(.08) end end)
    for _,obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Motor6D") and obj.Part0 and obj.Part1 then table.insert(pose.joints,{motor=obj,c0=obj.C0,c1=obj.C1})
        elseif obj:IsA("BasePart") then table.insert(pose.parts,{part=obj,collide=obj.CanCollide,size=obj.Size}) obj.CanCollide=obj==root end
    end
    local scale=math.clamp(root.Size.Y/2,.65,1.6)
    root.Size=Vector3.new(root.Size.X,1.2*scale,root.Size.Z)
    hum.HipHeight=char:FindFirstChild("Torso") and -(char:FindFirstChild("Left Leg") and char["Left Leg"].Size.Y or 2)+.18*scale or .18*scale
    hum.AutoRotate=true hum.WalkSpeed=3 Movement.noJump(hum,player)
    char:SetAttribute("DeadSignalCrawling",true)
    local highlight=U.make("Highlight",char,{Name="DownedOutline",Adornee=char,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor=Color3.fromRGB(243,175,68),FillTransparency=.88,OutlineColor=Color3.fromRGB(255,198,91),OutlineTransparency=.12})
    local marker=U.make("BillboardGui",root,{Name="ReviveMarker",Adornee=root,Size=UDim2.fromOffset(150,40),
        StudsOffsetWorldSpace=Vector3.new(0,2.4,0),MaxDistance=220,AlwaysOnTop=true})
    U.make("TextLabel",marker,{Name="NameLabel",Size=UDim2.new(1,0,0,17),BackgroundTransparency=1,Text=player.DisplayName,
        TextColor3=Color3.fromRGB(239,235,220),Font=Enum.Font.GothamBold,TextSize=12,TextTruncate=Enum.TextTruncate.AtEnd})
    pose.label=U.make("TextLabel",marker,{Name="Countdown",Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,18),
        BackgroundColor3=Color3.fromRGB(26,28,26),BackgroundTransparency=.12,BorderSizePixel=0,
        Text="REVIVE",TextColor3=Color3.fromRGB(255,198,91),Font=Enum.Font.GothamBold,TextSize=12})
    U.make("UICorner",pose.label,{CornerRadius=UDim.new(0,4)})
    pose.markers={highlight,marker} state.downedPose=pose D.step(state,os.clock())
end
function D.step(state,now)
    local pose=state.downedPose if not pose or not pose.char.Parent then return end
    local moving=pose.hum.MoveDirection.Magnitude>.05
    local phase=moving and now*5.5 or 0
    for _,j in ipairs(pose.joints) do if j.motor.Parent then
        local pos=(j.motor.Name=="RootJoint" or j.motor.Name=="Root") and Vector3.new(0,.12,0) or nil
        j.motor.C0=rotate(j.c0,D.rotation(j.motor.Name,phase),pos) j.motor.Transform=CFrame.new()
    end end
    for _,v in ipairs(pose.parts) do if v.part.Parent then v.part.CanCollide=v.part==pose.root end end
    pose.hum.WalkSpeed=3 Movement.noJump(pose.hum)
    pose.label.Text=(state.selfAt and "SELF REVIVE" or "REVIVE").."  /  "..math.max(0,math.ceil(state.downUntil-now)).."s"
end
function D.client(char,own)
    local crawling=char:GetAttribute("DeadSignalCrawling")==true
    local root=char:FindFirstChild("HumanoidRootPart")
    local marker=root and root:FindFirstChild("ReviveMarker") if marker then marker.Enabled=not own end
    local highlight=char:FindFirstChild("DownedOutline") if highlight then highlight.Enabled=not own end
    if crawling then for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") then obj.Transform=CFrame.new() end end end
end
return D
