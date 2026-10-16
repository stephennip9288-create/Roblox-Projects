local R=require('../Source/Runtime/shared/Rules')
local D=require('../Source/Runtime/shared/DirectorRules')
local count=0
local function check(ok,msg) assert(ok,msg) count+=1 end
local standard={health=1,enemies=1,damage=1}
local prev=0
for round=1,30 do
 local before=0
 for crew=1,4 do
  local quota=R.waveCount(round,crew,standard)
  check(quota>=before and (quota>before or before==320) and quota<=320,'crew quotas monotonic');before=quota
  local cap=R.activeLimit(round,crew,40)
  check(cap<=40 and cap>=5,'concurrency bound')
  local threat=D.threat(crew,0,round);check(threat.health>=1 and threat.health<=1.43,'crew health cap')
 end
 check(R.waveCount(round,1,standard)>prev,'round quota monotonic');prev=R.waveCount(round,1,standard)
 check(R.enemySpeed(round,'Shambler')<=16,'base speed cap')
end
check(R.waveCount(1,1,standard)==8 and R.waveCount(1,4,standard)==24,'opening quota')
check(R.enemyHealth(1,'Shambler',standard,1)==65,'solo opening health')
check(D.threat(1,2,1).health==1 and D.threat(1,2,10).health==1.24,'upgrades only affect later waves')
check(D.quota(40,15)==25 and D.quota(10,15)==0,'reconcile pending only')
local name,gap,cap,trigger=D.pacing(10,.3,1,-100,10,'Wave')
check(name=='Recover' and trigger and gap>1 and cap<1,'distress recovery')
name=D.pacing(10,1,0,0,10,'Wave');check(name=='Pressure','ordinary pressure')
name=D.pacing(24,1,0,0,24,'Wave');check(name=='Breathe','planned breath')
name,gap,cap,trigger=D.pacing(24,.1,2,-100,24,'Exfil');check(name=='Finale' and gap==1 and cap==1 and not trigger,'finale pacing invariant')
check(D.spawnScore(10,false,15,0)==nil,'near spawn rejected')
check(D.spawnScore(50,false,15,0)>D.spawnScore(50,true,15,0),'offscreen spawn favored')
check(D.spawnScore(50,false,15,0)>D.spawnScore(50,false,1,2),'repeat crowded region avoided')
print('Difficulty/director policy assertions passed:',count)
