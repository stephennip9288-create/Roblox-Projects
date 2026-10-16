-- Round orchestration, reward idempotence and extraction isolation use the actual Game methods.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local now=100 local V=r.Vector3 local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local p1={Parent=true,UserId=1};local p2={Parent=true,UserId=2};local players={p1,p2}
local testOs=table.clone(os);testOs.clock=function() return now end
local load=loader.new(dm,{globals={os=testOs},services={Players={GetPlayers=function() return players end}}})
local G=load(f.server.Game) local C=load(f.shared.Config) local D=load(f.shared.DirectorRules) local R=load(f.shared.Rules)
local function state() return {participating=true,status='Alive',grenades=0,health=100,perks={},points=0,
 stats={bestRound=0,rounds=0},guns={{id='Kestrel',tier=0,mag=3,reserve=0,reloadUntil=0}}} end
local broadcasts={} local spawned={} local ammo=0 local cleared=0
local map={model=r.Instance.new('Model'),windows={},exfilCenter=V.zero,scale=1}
local ctx={players={[p1]=state(),[p2]=state()},map=map,run={id=1,round=4,phase='Intermission',mode='Standard',effects={}},
 feed={FireAllClients=function(_,kind,data) broadcasts[#broadcasts+1]={kind=kind,data=data} end,FireClient=function() end},
 combat={ammo=function() ammo+=1 end},
 enemies={count=function() return 0 end,pendingBlasts=function() return 0 end,clear=function() cleared+=1 end,
 spawn=function(_,kind,window,pos,mods) spawned[#spawned+1]={kind=kind,mods=mods} end},
 director={spawned=0,begin=function(self) self.spawned=0 end,budget=function() return 40,1 end,
 window=function() return {} end,spawnedOne=function(self) self.spawned+=1 end}}
local g=setmetatable({ctx=ctx,drops={}},G);ctx.game=g
g:wave();check(ctx.run.round==5 and ctx.run.event.id=='Hunt','round five schedules Hunt')
check(ctx.run.spawnRemaining==D.specialQuota(R.waveCount(5,2,C.Modes.Standard),ctx.run.event),'crew quota uses event budget')
check(ctx.run.nextSpawn==now+C.Evolution.preparation,'real prep blocks spawning')
g:spawnEnemy(now+6);check(#spawned==0,'no early event spawn')
g:spawnEnemy(now+7);check(#spawned==1 and spawned[1].kind=='Hound' and spawned[1].mods.Alpha,'Hunt starts with a recognizable Alpha')
check(ctx.run.evolutionCounts.alphas==1 and ctx.director.spawned==1,'rare count and shared quota charged once')
ctx.run.spawnRemaining=0;ctx.run.effects.Double=now+100;ctx.players[p2].participating=false
check(g:rewardSpecial(),'completed event grants reward')
check(ctx.players[p1].points==150 and ctx.players[p2].points==0,'special points bypass Double and exclude spectators')
check(ctx.players[p1].guns[1].reserve==21 and ctx.players[p1].guns[1].mag==3,'partial reserve reward preserves magazine')
check(ammo==1 and not g:rewardSpecial() and ctx.players[p1].points==150,'repeat completion cannot pay twice')
ctx.run.eventRewarded=false;ctx.players[p1].guns[1].reserve=83;g:rewardSpecial();check(ctx.players[p1].guns[1].reserve==84,'reserve reward capped')
ctx.players[p2].participating=true;ctx.run.round=19;g:wave();spawned={};g:spawnEnemy(now+3)
check(ctx.run.round==20 and ctx.run.event==nil and spawned[1].kind=='Warden','Warden takes precedence at overlapping cadence')
check(ctx.run.bossAlive and ctx.run.bossSpawned,'existing boss lifecycle retained')
ctx.run.event=C.Evolution.events[1];ctx.run.special=true;g:exfil()
check(ctx.run.phase=='Exfil' and not ctx.run.event and not ctx.run.special and cleared==1,'exfil clears event and pending enemies')
check(ctx.run.spawnRemaining==C.Extraction.escorts+C.Extraction.escortsPerPlayer*2,'extraction escort budget unchanged')
spawned={};g:spawnEnemy(now+1);check(spawned[1].kind=='Warden' and not next(spawned[1].mods),'extraction Warden receives no modifiers')
check(not g:rewardSpecial(),'exfil never grants an event reward')
-- Existing production profile identity remains unchanged.
check(C.ProfileStore=='DeadSignal_Profile_v1' and C.Version=='1.9.0','v1.9 preserves DataStore namespace')
print('Special wave orchestration assertions passed:',count)
