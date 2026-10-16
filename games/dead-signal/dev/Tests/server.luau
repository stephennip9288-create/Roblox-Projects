-- Run with Lune from the kit root: lune run Tests/server.luau
-- Uses real runtime modules, Roblox datatypes and controlled service doubles.
local fs=require('@lune/fs')
local r=require('@lune/roblox')
local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'))
local folders=loader.install(dm)
local now=0 local rayBlocked=false local events={}
local world={GetServerTimeNow=function() return now end,Raycast=function(_,origin,delta,params)
 if rayBlocked then return {Position=origin+delta*.3,Instance={}} end
 return nil
end}
local testOs=table.clone(os);testOs.clock=function() return now end
local load=loader.new(dm,{globals={workspace=world,os=testOs,RaycastParams={new=function() return {} end}}})
local R=load(folders.shared.Rules)
local C=load(folders.shared.Config)
local Director=load(folders.server.WaveDirector)
local Combat=load(folders.server.Combat)
local Enemies=load(folders.server.Enemies)
local count=0
local function check(ok,msg) assert(ok,msg) count+=1 end
local V=r.Vector3
local function player(id,pos)
 local char=r.Instance.new('Model') local root=r.Instance.new('Part');root.Name='HumanoidRootPart';root.CFrame=r.CFrame.new(pos);root.Position=pos;root.Size=V.new(2,2,1);root.Parent=char
 local head=r.Instance.new('Part');head.Name='Head';head.CFrame=r.CFrame.new(pos+V.new(0,1.5,0));head.Position=head.CFrame.Position;head.Parent=char
 local carried=r.Instance.new('Model');carried.Name='CarriedWeapon';carried.Parent=char
 local muzzle=r.Instance.new('Part');muzzle.Name='Muzzle';muzzle.CFrame=r.CFrame.new(head.Position+V.new(.6,-.25,-2));muzzle.Position=muzzle.CFrame.Position;muzzle.Parent=carried
 return {Parent=true,UserId=id,Character=char},root
end
local p1,root1=player(1,V.new(0,3,0))
local p2,root2=player(2,V.new(80,3,0))
local function state() return {participating=true,status='Alive',health=100,perks={},guns={{id='Kestrel',tier=0,mag=12,reserve=84,reloadUntil=0}},slot=1} end
local ctx={players={[p1]=state(),[p2]=state()},run={id=1,phase='Wave',round=1,mode='Standard',effects={}},
 map={model=r.Instance.new('Model'),windows={},rooms={{unlocked=true}}},
 feed={FireAllClients=function(_,kind,data) table.insert(events,{kind=kind,data=data}) end,FireClient=function() end},
 game={isCombat=function() return true end,addPoints=function() end},enemies={list={},clearSight=function() return false end}}
local d=Director.new(ctx);ctx.director=d;d:begin(now)
local cap=d:budget(now);check(ctx.run.spawnRemaining==14 and cap==9,'duo quota and cap')
for i=1,5 do d:spawnedOne() end
d:budget(1);check(ctx.run.spawnRemaining==9,'spent quota accounted')
ctx.players[p2].status='Down';local capDown=d:budget(2)
check(ctx.run.spawnRemaining==9 and capDown<cap,'down immediately reduces pressure, not committed quota')
d:budget(7.9);check(ctx.run.spawnRemaining==9,'quota settle delay')
d:budget(8.1);check(ctx.run.spawnRemaining==3,'six-second reduction affects unspawned quota only')
ctx.players[p2].status='Alive';d:budget(9);check(ctx.run.spawnRemaining==9,'revive reconciles rather than adds an entire wave')
p2.Parent=false;d:budget(10);d:budget(16.1);check(ctx.run.spawnRemaining==3,'disconnect reconciliation')
ctx.players[p2].participating=false;p2.Parent=true
local spectator=player(3,V.new(0,3,0));ctx.players[spectator]=state();ctx.players[spectator].participating=false
check(d:crew()==1,'spectator and lobby exclusion')
local soloStats=d:stats('Shambler');check(soloStats.hp==65 and soloStats.damage==16,'solo baseline new spawn stats')
ctx.players[p2].participating=true;local duoStats=d:stats('Shambler');check(duoStats.hp>soloStats.hp and duoStats.damage>soloStats.damage and duoStats.speed>soloStats.speed,'crew threat scales all dimensions')
ctx.map.windows={{room=1,inside=V.new(0,3,-8)},{room=1,inside=V.new(40,3,-40)}}
check(d:window(18)==ctx.map.windows[2],'unfair near spawn avoided')
ctx.map.windows={ctx.map.windows[1]};check(d:window(19)==nil,'defer all unsafe windows')
-- Cached selection has no activation radius and immediately rejects downed targets.
local e=setmetatable({ctx=ctx,list={},targetLoads={}},Enemies)
local enemy={id=2,root={Position=V.new(0,3,1500)},targetAt=0}
local target,dist=e:target(enemy,now);check(target~=nil and dist>1000,'distant enemy continuously selects a player')
ctx.players[target].status='Down';local other=e:target(enemy,.01);check(other~=target and other~=nil,'cached downed target invalidated immediately')
ctx.players[p1].status='Alive';ctx.players[p2].status='Alive'
local same=V.new(0,3,0);root1.Position=same;root2.Position=same
e.targetLoads={[p1]=10,[p2]=0};enemy={id=3,root={Position=V.new(0,3,30)}}
check(e:target(enemy,2)==p2,'crowding-aware targeting spreads equal targets')
-- Actual combat method validates cadence, sequence, ammo and nearby camera origin.
local b=Combat.new(ctx);ctx.combat=b
local targetModel=r.Instance.new('Model');targetModel:SetAttribute('EnemyId',1)
local targetHead=r.Instance.new('Part');targetHead.Name='Head';targetHead.Parent=targetModel
local hit={Instance=targetHead,Position=V.new(8,4.5,-30)}
local victim={id=1,model=targetModel,hp=10000,maxHP=10000,kind='Shambler'};ctx.enemies.list[1]=victim
local damage=0
ctx.enemies.damage=function(_,who,amount) damage+=amount;who.hp-=amount;return false end
local rays={}
b.ray=function(_,origin,dir,range,ignore) table.insert(rays,{origin=origin,dir=dir,range=range});return hit end
local p=ctx.players[p1];p.nextShot=0
local eye=p1.Character.Head.Position local direction=(hit.Position-eye).Unit
now=20;b:fire(p1,{seq=1,direction=direction,viewOrigin=eye})
check(p.guns[1].mag==11 and damage>0,'valid tap uses existing server damage pipeline')
check(#rays==2 and (rays[2].origin-p1.Character.CarriedWeapon.Muzzle.Position).Magnitude<.001,'bullet originates at authored muzzle')
check(rays[2].dir:Dot((hit.Position-rays[2].origin).Unit)>.999,'camera point reconstructed then muzzle parallax applied')
local mag=p.guns[1].mag;now=20.02;b:fire(p1,{seq=2,direction=direction,viewOrigin=eye});check(p.guns[1].mag==mag,'reject cadence')
now=21;b:fire(p1,{seq=2,direction=direction});check(p.guns[1].mag==mag,'reject replayed sequence')
b:fire(p1,{seq=3,direction=direction,viewOrigin=eye+V.new(20,0,0)});check(p.guns[1].mag==mag,'reject remote camera origin')
b:fire(p1,{seq=3,direction=direction*30});check(p.guns[1].mag==mag,'reject non-unit direction')
p.guns[1].reloadUntil=22;b:fire(p1,{seq=3,direction=direction});check(p.guns[1].mag==mag,'reject reload shot');p.guns[1].reloadUntil=0
p.sprinting=true;b:fire(p1,{seq=4,direction=direction});check(p.guns[1].mag==mag,'reject sprint shot');p.sprinting=false
rayBlocked=true;local before=damage;now=23;b:fire(p1,{seq=5,direction=direction,viewOrigin=eye})
check(p.guns[1].mag==mag-1 and damage==before,'muzzle blocked by near wall consumes round without through-wall damage')
rayBlocked=false;p.guns[1].mag=0;now=24;b:fire(p1,{seq=6,direction=direction});check(damage==before,'empty magazine no hit')
p.guns[1].mag=10;p.status='Down';now=25;b:fire(p1,{seq=7,direction=direction});check(p.guns[1].mag==10,'downed shot rejected')
-- Existing Warden phase caps still apply across an entire trigger pull.
p.status='Alive';local boss={id=99,kind='Warden',hp=60000,maxHP=60000,phase=1,damageWindow=25,windowDamage=0,attackDamage={},model=r.Instance.new('Model'),root={Position=V.zero},hum={Health=60000},shock=50}
e.list={[99]=boss};e.spawn=function() end;e.kill=function(_,who) who.dead=true;e.list[who.id]=nil end;ctx.enemies=e
now=26
for _=1,10 do e:damage(boss,1000000,p1,true,'one-trigger','Bullet') end
check(boss.hp>=60000*(1-C.Warden.attackCap)-.01,'one trigger damage cap survived new scaling')
for second=27,55 do now=second for shot=1,4 do e:damage(boss,1000000,p1,true,tostring(second)..':'..shot,'Bullet') end end
check(boss.phase==3 and boss.hp<21001,'Warden reaches phase three without skipping gates')
-- Profile migration and atomic preference updates retain the existing identity.
local Persist=load(folders.server.Persistence)
local old=Persist.sanitize({xp=640,credits=75,skin='Factory',settings={volume=.25,aimAssist=false}})
check(old.xp==640 and old.credits==75 and old.settings.aimAssist==false,'prior progression preserved')
check(old.settings.fireLayout=='Tap' and old.settings.assistPreset=='Manual','new defaults merged into old profiles')
local dirty=Persist.sanitize({settings={fireLayout='Left',hudMoveX=.2,gyroSensitivity=0/0,autoFire='yes'}})
check(dirty.settings.fireLayout=='Left' and dirty.settings.hudMoveX==.2 and dirty.settings.autoFire==false,'settings migration validates individual fields')
ctx.players[p1].travelling=false;ctx.action={OnServerEvent={Connect=function() end}}
ctx.data={profiles={[p1]={loaded=true,data={settings=old.settings}}},send=function() end}
local Network=load(folders.server.Network);local network=Network.new(ctx)
network:dispatch(p1,'ControlSettings',{settings={fireLayout='Left',hudMoveX=.21}})
check(ctx.data.profiles[p1].data.settings.fireLayout=='Left','atomic HUD preference update')
network:dispatch(p1,'ControlSettings',{settings={fireLayout='Classic',badField=true}})
check(ctx.data.profiles[p1].data.settings.fireLayout=='Left','malformed batch rejected without partial mutation')
check(network:allow(p1,'ControlSettings',100) and network:allow(p1,'ControlSettings',100) and network:allow(p1,'ControlSettings',100) and not network:allow(p1,'ControlSettings',100),'preference rate limit')
print('Server integration assertions passed:',count)
