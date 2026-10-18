-- Actual Enemies/Game/Director methods; controlled physics and Humanoid signals.
local H=require('./Support/InfectedHarness');local r=H.roblox;local V=r.Vector3
local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local function setup()
 local h=H.new();h:player(1,V.new(25,3,35));h.ctx.map.windows={h:window()};h.ctx.run.effects={}
 h.ctx.run.round=30;h.ctx.run.spawnRemaining=2;h.ctx.run.nextSpawn=0;h.ctx.run.bossSpawned=false;h.ctx.run.bossAlive=false
 local G=h.load(H.folders.server.Game);local D=h.load(H.folders.server.WaveDirector)
 h.ctx.game=setmetatable({ctx=h.ctx},G);h.ctx.director=D.new(h.ctx)
 h.ctx.director:begin(h.time);h.ctx.director.budget=function() return 40,.5 end
 local original=h.Rigs.build
 h.Rigs.build=function(...)
  local model,root,hum=original(...);hum.PlatformStand=false
  root.AssemblyLinearVelocity=V.zero;root.AssemblyAngularVelocity=V.zero
  local proxy=setmetatable({},{__index=function(_,key)
   if key=='Died' then return {Connect=function() return {} end} end
   if key=='SetStateEnabled' then return function() end end
   if key=='MoveTo' then return function(_,pos) hum:SetAttribute('TestMoveTo',pos) end end
   return hum[key]
  end,__newindex=function(_,key,value) hum[key]=value end})
  return model,root,proxy
 end
 return h
end
do
 local h=setup();h.noFloor=true
 h.ctx.game:spawnEnemy(h.time)
 local ticket=h.enemies.pending and h.enemies.pending[1]
 check(ticket and ticket.kind=='Warden' and h.ctx.run.bossSpawned and h.ctx.run.bossAlive,'Warden precedence includes pending admission')
 check(h.ctx.run.spawnRemaining==1 and h.ctx.director.spawned==1 and h.enemies:count()==1,'Game unconditional accounting retains exactly one ticket')
 check(not next(h.enemies.list) and #h.enemies.folder:GetChildren()==0,'live-only loops never see an unadmitted boss')
 h.ctx.run.nextSpawn=h.time+100;h.noFloor=false;h.time+=1;h.enemies:tick(h.time)
 local boss=h.enemies.list[ticket.id]
 check(boss and boss.kind=='Warden' and #h.enemies.pending==0 and h.enemies:count()==1,'pending Warden becomes exactly one live boss')
 check(h.ctx.run.spawnRemaining==1 and h.ctx.director.spawned==1,'admission cannot consume a second quota or director spawn')
 h.enemies:kill(boss,nil,false,false)
 check(not h.ctx.run.bossAlive and h.enemies:count()==0,'defeated admitted Warden clears the normal boss gate')
end
do
 local h=setup();h.noFloor=true;h.ctx.run.round=1
 for _=1,40 do h.enemies:spawn('Shambler',h.ctx.map.windows[1]) end
 local remaining=h.ctx.run.spawnRemaining;local serial=h.enemies.nextId
 h.ctx.game:spawnEnemy(h.time)
 check(h.enemies:count()==40 and h.enemies.nextId==serial and h.ctx.run.spawnRemaining==remaining,'pending quota enforces cap40 before another Game spawn')
 check(not next(h.enemies.list) and #h.enemies.pending==40,'pending tickets remain separate from live-only lists')
 h.noFloor=false;h.time+=1;h.enemies:tick(h.time)
 check(h.enemies:count()==40 and #h.enemies.pending==39,'admission preserves total count at cap40')
 h.enemies:clear();check(h.enemies:count()==0 and #h.enemies.pending==0,'reset/failure clears all pending and active units')
end
do
 local h=setup();h.noFloor=true
 for _=1,3 do h.enemies:spawn('Runner',h.ctx.map.windows[1]) end
 local original=h.N.queuePosition
 h.N.queuePosition=function(owner,e,w) if e.id==1 then return nil end return original(owner,e,w) end
 h.noFloor=false
 for _=1,3 do h.time+=1;h.enemies:tick(h.time) end
 check(h.enemies.list[2] and h.enemies.list[3] and #h.enemies.pending==1 and h.enemies.pending[1].id==1,'one blocked request cannot starve later requests')
 check(h.enemies:count()==3,'fair retries neither lose nor duplicate quota')
 local serial=h.enemies.nextId
 for _=1,4 do h.time+=1;h.enemies:tick(h.time) end
 check(h.enemies.nextId==serial and h.enemies:count()==3,'repeated retries preserve stable ticket identities')
 h.ctx.run.id+=1;h.time+=1;h.enemies:tick(h.time)
 check(#h.enemies.pending==0,'stale pending requests cannot enter a new run')
end
do
 local h=setup();local e=h.enemies:spawn('Runner',h.ctx.map.windows[1],nil,{Armored=true,Enraged=true})
 e.hp=73;e.hum.Health=73;e.armor.Head=0;e.armor.Body=17;e.reactor=9;e.hitRewards={kept=true};e.nextCharge=120;e.nextAmbush=130
 local id=e.id;h.noFloor=true;e.root:Destroy()
 check(h.enemies:recover(e) and not h.enemies.list[id] and #h.enemies.pending==1,'destroyed root becomes a retained admission unit')
 check(h.enemies:count()==1 and not next(h.enemies.list),'lost geometry never leaves a nil-root live record')
 h.noFloor=false;h.time+=1;h.enemies:tick(h.time)
 local restored=h.enemies.list[id]
 check(restored and restored.hp==73 and restored.maxHP==e.maxHP and restored.hum.Health==73,'restored unit preserves exact health and maximum')
 check(restored.armor.Head==0 and restored.armor.Body==17 and not restored.armorParts.Head,'restored unit preserves damaged and broken armor')
 check(restored.reactor==9 and restored.hitRewards.kept and restored.nextCharge==120 and restored.nextAmbush==130,'reactor/rewards and special cooldowns survive root loss')
 check(h.enemies:count()==1 and #h.enemies.pending==0,'root restoration cannot duplicate the wave unit')
end
do
 local h=setup();h.noFloor=true;h.enemies:spawn('Hound',h.ctx.map.windows[1]);h.enemies:spawn('Runner',h.ctx.map.windows[1],nil,{Volatile=true})
 h.ctx.game.addPoints=function() end;h.ctx.game.broadcast=function() end
 h.ctx.game:powerup('Nuke')
 check(h.enemies:count()==2 and not next(h.enemies.list) and #h.enemies.hazards==0,'nuke/live-only loops do not dereference or detonate pending tickets')
 h.time+=3;h.enemies:tickHazards(h.time)
 check(#h.hits==0 and h.enemies:pendingBlasts()==0,'pending admission cannot inflict invisible hazard damage')
 h.enemies:clear();check(h.enemies:count()==0 and h:activeClocks()==0,'cleanup leaves no pending hazard or animation clock')
end
print('Batch 1.1 admission/accounting assertions passed:',count)
