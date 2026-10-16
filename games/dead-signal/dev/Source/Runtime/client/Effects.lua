local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local C=require(RS.DeadSignal.Config)
local U=require(RS.DeadSignal.Util)
local NPCPose=require(RS.DeadSignal.NPCPose)
local FX={} FX.__index=FX
local stock={Click="unsheath.wav",Equip="unsheath.wav",Board="impact_water.mp3",Attack="uuhhh.mp3",ShockCharge="unsheath.wav",Reload="unsheath.wav",Empty="unsheath.wav",Hit="impact_water.mp3",Kill="uuhhh.mp3",Down="uuhhh.mp3",Revive="action_get_up.mp3",Grenade="impact_water.mp3",Round="action_get_up.mp3",Power="unsheath.wav",Box="unsheath.wav",Perk="action_get_up.mp3",Victory="action_get_up.mp3",Enemy="uuhhh.mp3",Pistol="swordslash.wav",Rifle="swordslash.wav",SMG="swordslash.wav",Shotgun="swordlunge.wav",Heavy="swordlunge.wav",Sniper="swordlunge.wav",Energy="swordlunge.wav"}
function FX.new()
    local self=setmetatable({settings=U.copy(C.DefaultSettings),rigs=setmetatable({},{__mode="k"}),animTime=0,shake=0},FX)
    self.folder=U.make("Folder",workspace,{Name="DeadSignalLocalEffects"}) return self
end
function FX:sound(key,position)
    local id=C.SoundIds[key] local custom=id and tostring(id)~=""
    if not custom and not stock[key] then return end
    local parent=SoundService local anchor
    if position then anchor=U.make("Part",self.folder,{Size=Vector3.new(.1,.1,.1),Position=position,Transparency=1,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false}) parent=anchor Debris:AddItem(anchor,4) end
    local sound=U.make("Sound",parent,{SoundId=custom and "rbxassetid://"..tostring(id) or "rbxasset://sounds/"..stock[key],
        Volume=self.settings.volume*(custom and .6 or .17),PlaybackSpeed=custom and 1 or ((key=="Pistol" or key=="SMG" or key=="Rifle") and 1.8 or 1),
        RollOffMinDistance=8,RollOffMaxDistance=115})
    sound:Play() Debris:AddItem(sound,key=="Ambient" and 45 or 4)
    if not custom and (key=="Pistol" or key=="Rifle" or key=="SMG" or key=="Heavy") then task.delay(.1,function() if sound.Parent then sound:Stop() end end) end
end
function FX:part(size,cf,color,shape)
    return U.make("Part",self.folder,{Size=size,CFrame=cf,Color=color,Shape=shape or Enum.PartType.Block,
        Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
end
function FX:tracer(a,b,energy)
    local dist=(b-a).Magnitude if dist<.05 then return end
    local p=self:part(Vector3.new(energy and .18 or .055,energy and .18 or .055,dist),CFrame.lookAt((a+b)*.5,b),energy and Color3.fromRGB(71,216,232) or Color3.fromRGB(255,210,127))
    Debris:AddItem(p,self.settings.lowEffects and .035 or .075)
    if not self.settings.lowEffects then
        self:particles(b,3,.38,.24,Color3.fromRGB(137,126,107),false)
    end
end
function FX:particles(position,count,lifetime,size,color,hot)
    local anchor=U.make("Part",self.folder,{Name=hot and "HotDebris" or "ImpactDust",Size=Vector3.new(.05,.05,.05),CFrame=CFrame.new(position),
        Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
    local emitter=U.make("ParticleEmitter",anchor,{Name="TransientParticles",Texture=hot and "rbxasset://textures/particles/fire_main.dds" or "rbxasset://textures/particles/smoke_main.dds",
        Rate=0,Lifetime=NumberRange.new(lifetime*.65,lifetime),Speed=NumberRange.new(hot and 7 or .7,hot and 15 or 2.5),
        SpreadAngle=Vector2.new(65,65),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-35,35),
        Acceleration=Vector3.new(0,hot and -12 or .8,0),Drag=hot and 4 or 1.5,LightEmission=hot and .7 or 0,LightInfluence=hot and .1 or .9,
        Color=ColorSequence.new(color),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.25),NumberSequenceKeypoint.new(.25,size),NumberSequenceKeypoint.new(1,hot and 0 or size*1.6)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,hot and .05 or .55),NumberSequenceKeypoint.new(.2,hot and .15 or .65),NumberSequenceKeypoint.new(1,1)})})
    emitter:Emit(count) Debris:AddItem(anchor,lifetime+.15) return anchor
end
function FX:muzzle(muzzle)
    if self.settings.lowEffects then return end
    local emitter=muzzle:FindFirstChild("MuzzleSmoke")
    if not emitter then emitter=U.make("ParticleEmitter",muzzle,{Name="MuzzleSmoke",Texture="rbxasset://textures/particles/smoke_main.dds",Rate=0,
        Lifetime=NumberRange.new(.12,.26),Speed=NumberRange.new(1,2.5),EmissionDirection=Enum.NormalId.Front,SpreadAngle=Vector2.new(12,12),
        Drag=2,Color=ColorSequence.new(Color3.fromRGB(142,140,130)),LightInfluence=1,
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.07),NumberSequenceKeypoint.new(1,.3)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.72),NumberSequenceKeypoint.new(1,1)})}) end
    emitter:Emit(2)
end
function FX:burst(position,radius,color)
    local anchor=self:particles(position,self.settings.lowEffects and 3 or 14,.8,math.min(radius*.4,3),Color3.fromRGB(88,84,76),false)
    local light=U.make("PointLight",anchor,{Color=color,Brightness=4,Range=math.min(radius*2,30),Shadows=false})
    Tween:Create(light,TweenInfo.new(.18),{Brightness=0}):Play()
    if not self.settings.lowEffects then self:particles(position,10,.5,.4,Color3.fromRGB(241,175,87),true) end
end
function FX:enemyDeath(data)
    if self.settings.lowEffects then return end
    -- The server retains the actual ragdoll for 30 seconds. Only dust is local.
    self:particles(data.position,5,.65,.45,Color3.fromRGB(112,106,92),false)
end
function FX:warning(data)
    local duration=data.duration or 1.8
    for i=1,(self.settings.lowEffects and 12 or 24) do
        local a=i*math.pi*2/(self.settings.lowEffects and 12 or 24)
        local p=self:part(Vector3.new(2.1,.06,.5),CFrame.new(data.position.X+math.cos(a)*data.radius,.08,data.position.Z+math.sin(a)*data.radius)*CFrame.Angles(0,-a,0),Color3.fromRGB(234,144,61))
        p.Transparency=.25 Tween:Create(p,TweenInfo.new(duration),{Color=Color3.fromRGB(244,70,57)}):Play() Debris:AddItem(p,duration)
    end
end
function FX:animate(dt)
    self.animTime=self.animTime+dt local time=self.animTime
    local folder=workspace:FindFirstChild("DeadSignalEnemies") if not folder then return end
    local camera=workspace.CurrentCamera
    for _,model in ipairs(folder:GetChildren()) do
        local root=model:FindFirstChild("HumanoidRootPart") local torso=model:FindFirstChild("Torso")
        if root and torso and (root.Position-camera.CFrame.Position).Magnitude<180 then
            local cache=self.rigs[model]
            if not cache then
                cache={} for _,j in ipairs(model:GetDescendants()) do if j:IsA("Motor6D") then cache[#cache+1]=j end end
                self.rigs[model]=cache
            end
            if not model:GetAttribute("Dead") then
                local poses=NPCPose.sample(model,root,workspace:GetServerTimeNow())
                for _,j in ipairs(cache) do if j.Enabled then j.Transform=poses[j.Name] or CFrame.identity end end
            end
        end
    end
    for model,cache in pairs(self.rigs) do
        if model:GetAttribute("Dead") then
            for _,joint in ipairs(cache) do if joint.Parent then joint.Transform=CFrame.identity end end
            self.rigs[model]=nil
        elseif not model.Parent then self.rigs[model]=nil end
    end
    local map=workspace:FindFirstChild("DeadSignalMap")
    if map then
        if self.map~=map then
            if self.mapConnection then self.mapConnection:Disconnect() end
            self.map=map self.pickups={}
            local function added(p) if p:IsA("BasePart") and p.Name:sub(1,5)=="Drop_" then self.pickups[p]=true end end
            for _,p in ipairs(map:GetChildren()) do added(p) end
            self.mapConnection=map.ChildAdded:Connect(added)
        end
        local rescue=map:FindFirstChild("Rescue")
        if rescue and rescue:FindFirstChild("Rotor") then rescue.Rotor.CFrame=rescue.PrimaryPart.CFrame*CFrame.new(0,4,0)*CFrame.Angles(0,time*30,0) end
        -- Only a handful of drops are animated; no map-wide per-frame traversal.
        for p in pairs(self.pickups) do if not p.Parent then self.pickups[p]=nil else p.CFrame=CFrame.new(p.Position)*CFrame.Angles(time*.9,time*1.5,0) end end
    end
end
return FX
