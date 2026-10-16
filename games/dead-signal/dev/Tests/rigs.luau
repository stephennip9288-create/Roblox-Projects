local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl')) local f=loader.install(dm)
local cleanup={} local delays={} local clock=100
local load=loader.new(dm,{services={Debris={AddItem=function(_,model,seconds) cleanup[#cleanup+1]={model=model,seconds=seconds} end}},globals={workspace={GetServerTimeNow=function() return clock end},
 task={delay=function(t,fn) delays[#delays+1]={time=t,fn=fn} end}}})
local R=load(f.server.EnemyRigs) local N=load(f.server.Navigation) local P=load(f.shared.NPCPose)
local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local physics={groups={},pairs={},RegisterCollisionGroup=function(self,name) self.groups[name]=true end,
 CollisionGroupSetCollidable=function(self,a,b,value)
  check(a=='Default' or self.groups[a],'collision group registered before use') check(b=='Default' or self.groups[b],'collision group registered before use')
  self.pairs[a..':'..b]=value;self.pairs[b..':'..a]=value
 end}
load(f.server.CollisionPolicy).setup(physics)
check(physics.pairs['DeadSignalPlayers:DeadSignalEnemies'],'living enemies collide with players')
check(physics.pairs['DeadSignalEnemies:DeadSignalEnemies'],'living enemies collide with each other')
check(physics.pairs['DeadSignalCorpses:Default'],'corpses collide with the world')
check(not physics.pairs['DeadSignalCorpses:DeadSignalPlayers'],'corpses cannot pin survivors')
local parent=r.Instance.new('Folder');local corpses=r.Instance.new('Folder')
for _,kind in ipairs({'Shambler','Runner','Hound','Crawler','Warden'}) do
 local m,root,hum=R.build(parent,kind,r.Vector3.new(0,8,0),5)
 root.AssemblyLinearVelocity=r.Vector3.zero
 local e={model=m,root=root,hum=hum,kind=kind}
 check(m:GetAttribute('ArticulatedRig') and m:GetAttribute('ForwardAxis')=='-Z',kind..' unified forward convention')
 check(math.abs(N.rootHeight(e)-(root.Size.Y*.5+m:FindFirstChild('Left Leg').Size.Y+hum.HipHeight))<.0001,kind..' actual humanoid floor clearance')
 local collider=m:FindFirstChild('BodyCollider')
 check(collider.CanCollide,kind..' physical shell')
 local floor=root.Position.Y-N.rootHeight(e)
 check(collider.Position.Y-collider.Size.Y*.5-floor<.3,kind..' collision shell reaches the floor so crawlers cannot pass under it')
 check(N.agent(e).AgentRadius>=math.max(collider.Size.X,collider.Size.Z)*.5+.1,kind..' path agent covers the body turning radius')
 check(not root.CanCollide and not m.Head.CanCollide,kind..' no competing live limb collision')
 local joints=0
 for _,j in ipairs(m:GetDescendants()) do if j:IsA('Motor6D') then
  joints+=1;local a=j.Part0.CFrame*j.C0 local b=j.Part1.CFrame*j.C1
  check((a.Position-b.Position).Magnitude<.001,kind..' coincident rest joint frames '..j.Name)
 end end
 check(joints>=14,kind..' elbows knees wrists and ankles exist')
 local serialized=r.serializeModel({m});local reopened=r.deserializeModel(serialized)[1]
 check(reopened:FindFirstChild('BodyCollider').CanCollide and reopened:GetAttribute('ArtRevision')==8,kind..' native rig survives serialization')
 R.corpse(m,corpses)
 check(m.Parent==corpses and m:GetAttribute('Ragdoll'),kind..' every elimination enters shared ragdoll')
 check(not m.BodyCollider.CanCollide and hum.PlatformStand and not hum.AutoRotate,kind..' living locomotion disabled')
 local sockets=0
 for _,j in ipairs(m:GetDescendants()) do
  if j:IsA('Motor6D') and j.Name~='RootJoint' then check(not j.Enabled,kind..' death motor disabled')
  elseif j:IsA('BallSocketConstraint') then
   sockets+=1 local a=j.Attachment0.Parent.CFrame*j.Attachment0.CFrame local b=j.Attachment1.Parent.CFrame*j.Attachment1.CFrame
   check((a.Position-b.Position).Magnitude<.001,kind..' death joints capture current pose without separation')
  end
 end
 check(sockets==joints-1,kind..' all articulated joints ragdoll')
 check(cleanup[#cleanup].seconds==30,kind..' bounded corpse lifetime')
 local before=#cleanup;R.corpse(m,corpses);check(#cleanup==before,kind..' duplicate death ignored')
end
local poses=P.transforms('Shambler',0,0,1)
local arm=poses['Right Shoulder']*r.Vector3.new(0,-1,0)
check(arm.Z<0,'zombie attack reaches toward negative Z, not behind its back')
print('Rig and collision assertions passed:',count)
