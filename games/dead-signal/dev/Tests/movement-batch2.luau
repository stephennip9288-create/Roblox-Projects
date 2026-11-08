-- Real shared policy + Game authority + Network adapter. Controlled physics,
-- clocks and datatypes; native replication/device/balance acceptance is separate.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local now=100 local load=loader.new(dm,{modules={ThirdPerson={update=function() end}},globals={os={clock=function() return now end}}})
local M=load(f.shared.Movement) local C=load(f.shared.Config) local Game=load(f.server.Game) local Network=load(f.server.Network)
local V,CF=r.Vector3,r.CFrame local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local function near(a,b,msg) check(math.abs(a-b)<.0001,msg..' '..a..' / '..b) end
local ahead=V.new(0,0,-1)
local function policy(move,extra)
 local state={alive=true,stamina=100,requested=true}
 for k,v in pairs(extra or {}) do state[k]=v end return M.policy(move,ahead,state)
end
near(policy(ahead,{requested=false}).speed,16,'normal forward')
near(policy(-ahead).speed,9.5,'backpedal') near(policy(V.xAxis).speed,10.5,'strafe')
near(policy(ahead).speed,24,'forward sprint') near(policy(ahead,{marathon=true}).speed,28,'Marathon sprint')
near(policy(ahead,{requested=false,marathon=true}).speed,19,'Marathon walk')
near(policy(ahead,{aiming=true}).speed,11,'ADS forward')
near(policy(V.xAxis,{aiming=true}).speed,11*10.5/16,'ADS directional ratio')
near(policy(-ahead,{marathon=true}).speed,19*9.5/16,'Marathon reverse ratio')
for _,forward in ipairs({ahead,V.new(1,0,-1).Unit,V.new(-1,0,-1).Unit}) do
 local p=policy(forward);check(p.sprinting==(forward==ahead),'45 degree diagonal cannot sprint')
 check(p.speed<=24,'no diagonal boost')
end
for _,scale in ipairs({.1,.5,.79,1}) do
 local p=policy(ahead*scale);near(p.speed,scale<.8 and 16 or 24,'stick magnitude is not applied twice')
 check(p.sprinting==(scale>=.8),'analog sprint threshold')
end
local previous
for degrees=-180,180 do
 local angle=math.rad(degrees) local move=V.new(math.sin(angle),0,-math.cos(angle))
 for _,flags in ipairs({{}, {marathon=true},{aiming=true},{reloading=true}}) do
  local p=policy(move,flags)
  check(not p.sprinting or math.abs(degrees)<30,'narrow forward sprint cone')
  check(p.speed<=28 and p.speed>0,'finite bounded angular speed')
  if degrees>=90 or degrees<=-90 then check(not p.sprinting,'no side/reverse sprint') end
 end
 local p=policy(move)
 if previous then check(math.abs(p.speed-previous)<.9,'continuous angular blend') end previous=p.speed
 for yaw=0,330,30 do
  local rotation=CF.Angles(0,math.rad(yaw),0)
  near(M.policy(rotation:VectorToWorldSpace(move),rotation.LookVector,{alive=true,requested=true,stamina=100}).speed,p.speed,'rotation-independent basis')
 end
end
for key,value in pairs({alive=false,blocked=true,aiming=true,reloading=true,stale=true,stamina=0}) do
 check(not policy(ahead,{[key]=value}).sprinting,'immediate gate '..key)
end
check(not policy(ahead,{stamina=11}).sprinting and policy(ahead,{stamina=12}).sprinting,'ready threshold avoids exhaustion chatter')
check(policy(ahead,{wasSprinting=true,stamina=2}).sprinting and not policy(ahead,{wasSprinting=true,stamina=1}).sprinting,'ongoing sprint drain cutoff')
near(M.approach(24,9.5,.016),9.5,'speed reductions cannot retain sprint speed')
near(M.approach(16,24,.1),20,'bounded acceleration')
near(M.stamina(100,100,true,1),82,'existing stamina drain') near(M.stamina(50,100,false,1),74,'existing stamina recovery')
for _,bad in ipairs({V.new(0/0,0,0),V.new(math.huge,0,0),V.new(2,0,0),V.new(0,1,0),'forward',false}) do check(M.input(bad)==nil,'reject malformed/unbounded intent') end
check(M.input(V.new(.4,0,-.4))~=nil,'valid analog intent')
for _,off in ipairs({{0,false,false},{1,true,false},{1,false,true}}) do
 check(M.camera(1,1,off[1],off[2],off[3])==V.zero,'accessibility disables camera translation')
end
check(M.camera(1,1,1,false,false).Magnitude<.014,'camera has tiny bounded translation, no FOV/roll')
-- A sustained per-packet boost cannot repeatedly renew the four-stud slack.
for _,hz in ipairs({10,30,60}) do for _,cheatSpeed in ipairs({16,24,28,100}) do
 local sample={position=V.zero,at=0,debt=0} local pos=V.zero local corrected=0
 for tick=1,hz*10 do
  local wanted=pos+ahead*(cheatSpeed/hz)
  local ok,accepted=M.audit(sample,wanted,tick/hz,9.5)
  pos=ok and wanted or accepted;if not ok then corrected+=1 end
 end
 check(corrected>0 and pos.Magnitude<=9.5*10+M.tuning.burstAllowance+.001,'sustained speed exploit bound '..hz..'/'..cheatSpeed)
end end
-- Batched replication, slopes and a 300ms stall don't accumulate false debt.
local sample={position=V.zero,at=0,debt=0} local pos=V.zero
for tick=1,600 do
 if tick%6==0 then pos+=ahead*1.6 end
 local ok=M.audit(sample,pos+V.new(0,tick*.1,0),tick/60,16);check(ok,'jitter/vertical traversal tolerance')
end
local ok=M.audit(sample,pos+ahead*4.8,10.3,16);check(ok,'300ms server/replication step')
local prior=sample.position;check(not M.audit(sample,V.new(0/0,0,0),11,16),'nonfinite position rejected');check(sample.position==prior,'invalid position cannot poison sample')
-- Unlike a server stall, delayed replication batches arrive while the server
-- keeps ticking. Only server-measured ping may enlarge the bounded slack.
for _,ping in ipairs({.05,.15,.3}) do
 local batch=math.floor(ping*60+.5) local sample={position=V.zero,at=0,debt=0,allowance=4+28*ping} local pos=V.zero
 for tick=1,600 do
  if tick%batch==0 then pos+=ahead*(28*batch/60) end
  check(M.audit(sample,pos,tick/60,28),'server-measured latency tolerates packet batches '..ping)
 end
end
-- Execute the real Game and rate-limited Network dispatch against two players.
local char=r.Instance.new('Model');local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.CFrame=CF.identity;root.Position=V.zero;root.Parent=char
local hum=r.Instance.new('Humanoid');hum.Parent=char
local player={UserId=1,Character=char,Parent=true}
local p={status='Alive',participating=true,perks={},stamina=100,guns={{reloadUntil=0}},slot=1}
local ctx={players={[player]=p},run={phase='Wave'},action={OnServerEvent={Connect=function() end}},combat={gun=function(_,state) return state.guns[state.slot] end}}
local game=setmetatable({ctx=ctx},Game);ctx.game=game;local network=Network.new(ctx)
local function input(move,requested)
 network:dispatch(player,'Look',{pitch=0,yaw=0,move=move,blocked=false})
 if requested~=nil then network:dispatch(player,'Sprint',{enabled=requested,move=move}) end
end
local function step(move,dt)
 now+=dt or .1;root.Position+=move;root.CFrame=CF.new(root.Position)
 game:movePlayer(player,p,hum,root,now,dt or .1);root.Position=root.CFrame.Position
end
input(ahead,true)
for _=1,8 do input(ahead);step(V.zero) end
check(p.sprinting and hum.WalkSpeed==24 and p.stamina<100,'server grants valid sprint without replicated Humanoid.MoveDirection')
input(V.xAxis);step(V.zero);check(not p.sprinting and hum.WalkSpeed<=10.5,'server rejects sideways sprint')
input(-ahead,true);step(V.zero);check(not p.sprinting and hum.WalkSpeed<=9.5,'server rejects reverse sprint')
input(ahead,true);p.aiming=true;step(V.zero);check(not p.sprinting and hum.WalkSpeed<=11 and not p.sprintRequested,'ADS cancels authority request')
p.aiming=false;p.guns[1].reloadUntil=now+1;input(ahead,true);step(V.zero)
check(not p.sprinting and not p.sprintRequested,'reload cancels authority request')
p.guns[1].reloadUntil=0;p.stamina=100;input(ahead,true);step(V.zero,.7)
check(not p.sprinting and hum.WalkSpeed<=9.5,'stale intent cannot sprint or keep forward cap')
input(ahead,true);step(V.zero);local at=p.moveAt
network:dispatch(player,'Look',{pitch=0,yaw=0,move=V.new(100,0,0),speed=1000,stamina=999})
check(p.moveAt==at and p.stamina<=100,'untrusted speed/stamina/bad intent ignored')
network:dispatch(player,'Sprint',{enabled=false,move=V.zero,blocked=true});step(V.zero)
check(hum.WalkSpeed==0 and not p.sprinting,'blocked input cancels authority immediately')
input(ahead,true)
for _=1,10 do input(ahead);step(-ahead*2.4) end
check(not p.sprinting and (p.motion.corrections or 0)>0,'observed reverse motion defeats spoofed forward intent')
check(network:allow(player,'Look',now),'Look adapter keeps existing limiter')
local passed=0 for _=1,40 do if network:allow(player,'Look',now) then passed+=1 end end;check(passed<=16,'movement cannot bypass Look bucket')
local second={UserId=2};local p2={status='Down',participating=true,perks={},stamina=100};ctx.players[second]=p2
network:dispatch(second,'Sprint',{enabled=true,move=ahead});check(not p2.sprintRequested and p.moveIntent==ahead,'player state and player-local intent isolation')
local char2=r.Instance.new('Model');local root2=r.Instance.new('Part');root2.Name='HumanoidRootPart';root2.CFrame=CF.identity;root2.Position=V.zero;root2.Parent=char2
local hum2=r.Instance.new('Humanoid');hum2.Parent=char2;second.Character=char2
second.GetNetworkPing=function() return .3 end
p2.status='Alive';p2.perks={Marathon=true};p2.guns={{reloadUntil=0}};p2.slot=1;p2.stamina=200
local firstStamina=p.stamina
network:dispatch(second,'Look',{pitch=0,yaw=0,move=V.xAxis,blocked=false})
network:dispatch(second,'Sprint',{enabled=true,move=V.xAxis})
for _=1,5 do now+=.1;network:dispatch(second,'Look',{pitch=0,yaw=0,move=V.xAxis,blocked=false});game:movePlayer(second,p2,hum2,root2,now,.1) end
near(hum2.WalkSpeed,19*10.5/16,'second Marathon player has independent sideways cap')
check(not p2.sprinting and p.stamina==firstStamina and p.motion~=p2.motion,'player-local sprint, stamina and debt isolation')
near(p2.motion.allowance,12.4,'only server-observed bounded ping enlarges tolerance')
-- An attacker cannot reset the burst allowance by repeatedly triggering the
-- existing boundary rescue. Execute the real Game tick around a rescued player.
local rescueLoad=loader.new(dm,{modules={ThirdPerson={update=function() end},BoundaryGuard={enforce=function(_,who,state)
 if who~=player then return false end
 root.Position=V.zero;root.CFrame=CF.identity;state.lastPosition=V.zero;state.lastSample=now;state.safePosition=V.zero;return true
end}},globals={os={clock=function() return now end}}})
local RescueGame=rescueLoad(f.server.Game)
ctx.run={phase='Preparing',deadline=now+100,effects={}};ctx.map={traps={}}
p.health=100;p.lastHurt=now;p2.health=100;p2.lastHurt=now;p.motion.debt=4
now+=.1;local rescue=setmetatable({ctx=ctx,drops={}},RescueGame);rescue:tick(now,.1)
check(p.motion.debt>0 and p.motion.debt<=4,'boundary rescue rebases without renewing movement credit')
-- Actual UI method: readable words in the existing vitals row, no new widget.
local UI=load(f.client.UI);local view=setmetatable({state={status='Alive',participating=true,health=100},healthText=r.Instance.new('TextLabel'),staminaBar=r.Instance.new('Frame')},UI)
view:movement(true,50,100,'ready');check(view.healthText.Text=='100 HP · RUN 50%','textual sprint/stamina feedback')
view:movement(false,5,100,'stamina');check(view.healthText.Text=='100 HP · REST 5%','immediate ended/exhausted feedback')
view:movement(false,100,100,'ready');check(view.healthText.Text=='100 HP · READY 100%','stamina-ready cue')
view.state.status='Down';view.healthText.Text='REVIVE NEEDED';view:movement(false,50,100,'blocked');check(view.healthText.Text=='REVIVE NEEDED','movement feedback preserves down/revive text')
print('Batch 2 movement assertions passed:',count)
