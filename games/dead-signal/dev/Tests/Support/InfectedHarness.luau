-- Controlled services for actual Batch 1 modules. No native spatial/physics claim.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local folders=loader.install(dm)
r.implementMethod('Humanoid','MoveTo',function(hum,p) hum:SetAttribute('TestMoveTo',p) end)
local H={roblox=r,folders=folders}
function H.new()
 local V=r.Vector3;local h={time=100,events={},cues={},cueKeys={},hits={},connections={},blocked=false,overlap=false,noFloor=false,probes=0}
 local world={GetServerTimeNow=function() return h.time end,
  Raycast=function(_,pos) return not h.noFloor and {Position=V.new(pos.X,h.floorFunction and h.floorFunction(pos) or h.floorY or 0,pos.Z)} or nil end,
  Blockcast=function(_,_,_,delta)
   h.probes+=1;if h.blocked and (not h.blockForward or delta.Z>0) then return {} end
   return nil
  end,
  GetPartBoundsInBox=function() return h.overlap and {{CanCollide=true}} or {} end}
 local heartbeat={Connect=function(_,fn)
  local c={active=true,fn=fn};h.connections[#h.connections+1]=c
  return {Disconnect=function() c.active=false end}
 end}
 local testOs=table.clone(os);testOs.clock=function() return h.time end
 local load=loader.new(dm,{services={RunService={Heartbeat=heartbeat},Debris={AddItem=function(_,model,seconds) model:SetAttribute('TestDebrisSeconds',seconds) end}},
  globals={workspace=world,os=testOs,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}})
 h.load=load;h.E=load(folders.server.Enemies);h.N=load(folders.server.Navigation);h.Rigs=load(folders.server.EnemyRigs)
 h.C=load(folders.shared.Config);h.Pose=load(folders.shared.NPCPose)
 local parent=r.Instance.new('Folder');local corpses=r.Instance.new('Folder')
 h.ctx={players={},map={id='Station',scale=1,model=r.Instance.new('Model'),floorParts={},rooms={{unlocked=true}},navigationRevision=1},
  run={id=1,round=25,phase='Wave',mode='Standard'},
  feed={FireAllClients=function(_,kind,data) h.events[#h.events+1]={kind=kind,data=data,time=h.time} end},
  game={addPoints=function() end,drop=function() end},combat={hurt=function(_,player,damage) h.hits[#h.hits+1]={player=player,damage=damage} end}}
 h.enemies=setmetatable({ctx=h.ctx,list={},nextId=0,hazards={},hazardId=0,folder=parent,corpses=corpses,targetLoads={},pathTokens=4,pathBudgetAt=h.time,recovered=0},h.E)
 h.ctx.enemies=h.enemies
 function h:player(id,pos)
  local char=r.Instance.new('Model');local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.CFrame=r.CFrame.new(pos);root.Position=pos;root.Parent=char
  local p={Parent=true,UserId=id,Character=char};self.ctx.players[p]={participating=true,status='Alive',health=100,perks={},guns={},stats={kills=0,headshots=0}}
  return p,root
 end
 function h:window(x)
  x=x or 0;local part=r.Instance.new('Part');part.Position=V.new(x,6.3,0);part.CFrame=r.CFrame.new(part.Position);part.CollisionGroup='DeadSignalWindow';part.Parent=self.ctx.map.model
  return {room=1,part=part,outside=V.new(x,3.5,-6),inside=V.new(x,3.5,8),count=0,boards={},nextTear=0}
 end
 function h:enemy(kind,mods,window,entered)
  self.enemies.nextId+=1;local id=self.enemies.nextId;window=window or self:window()
  local pos=V.new(window.outside.X,kind=='Hound' and 1.66 or kind=='Crawler' and .72 or kind=='Warden' and 4.312 or 3.08,window.outside.Z-3)
  local model,root,hum=self.Rigs.build(parent,kind,pos,id,self.ctx.map.id)
  hum.MaxHealth=500;hum.Health=500;hum.PlatformStand=false
  local e={id=id,kind=kind,model=model,root=root,hum=hum,window=window,entered=entered==true,entryQueued=entered~=true,
   hp=500,maxHP=500,damage=25,baseSpeed=10,mods=mods or {},lastPosition=root.Position,lastMoved=self.time,runId=1,attack=0,phase=1,
   shock=self.time+100,nextPath=0,index=1,targetAt=0,damageWindow=self.time,windowDamage=0,attackDamage={},packRole='Charger'}
  e.armor=e.mods.Armored and {Head=160,Body=160} or nil;e.reactor=e.mods.Volatile and 110 or nil
  self.Rigs.evolve(e);root.Anchored=e.entryQueued;hum.AutoRotate=not e.entryQueued
  for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then p.AssemblyLinearVelocity=V.zero;p.AssemblyAngularVelocity=V.zero end end
  self.enemies.list[id]=e;return e
 end
 function h:step(dt)
  local function observe()
   for _,e in pairs(self.enemies.list) do if e.model.Parent then
    local cue=e.model:GetAttribute('EntryCue');local at=e.model:GetAttribute('EntryCueAt')
    local key=tostring(e.model:GetAttribute('EntrySourceId'))..tostring(cue)..tostring(at)
    if cue and not self.cueKeys[key] then
     self.cueKeys[key]=true;self.cues[#self.cues+1]={cue=cue,time=at,id=e.id,position=e.root.Position}
    end
   end end
  end
  observe()
  self.time+=dt or 1/30;local callbacks=table.clone(self.connections)
  for _,c in ipairs(callbacks) do if c.active then c.fn(dt or 1/30) end end
  observe()
 end
 function h:activeClocks() local n=0;for _,c in ipairs(self.connections) do if c.active then n+=1 end end;return n end
 return h
end
return H
