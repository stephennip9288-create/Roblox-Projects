local X=require('../Source/Runtime/shared/Extraction')
local count=0
local function check(v,m) assert(v,m);count+=1 end
local c={seconds=180,afterBossGrace=75,holdSeconds=12}
for _,crew in ipairs({1,2,4}) do
 local run={phase='Exfil',bossSpawned=true,bossAlive=true,deadline=180,exfilProgress=0,spawnRemaining=5}
 local stats={alive=crew,insideAlive=crew,downOutside=0,contested=false}
 check(X.step(run,stats,c,100,1)==nil and run.exfilStage=='Warden','boss required')
 run.bossAlive=false
 X.step(run,stats,c,178,1)
 check(run.deadline==253 and run.spawnRemaining==0 and run.exfilStage=='Board','boss defeat extends boarding grace')
 stats.contested=true;local progress=run.exfilProgress;X.step(run,stats,c,179,1)
 check(run.exfilProgress==progress and run.exfilStage=='Clear','contest pauses')
 stats.contested=false;stats.insideAlive=crew-1;X.step(run,stats,c,180,1)
 check(run.exfilStage=='Rally' and run.exfilProgress==progress,'whole living crew must rally')
 stats.insideAlive=crew;stats.downOutside=1;X.step(run,stats,c,181,1)
 check(run.exfilStage=='Rally' and run.exfilProgress==progress,'stranded downed crew blocks boarding')
 stats.downOutside=0
 local result
 for second=182,194 do result=X.step(run,stats,c,second,1) if result then break end end
 check(result==true and run.exfilProgress==100,'mission completes without normal wave transition')
end
local run={phase='Exfil',bossSpawned=true,bossAlive=true,deadline=10,exfilProgress=0}
local result,reason=X.step(run,{alive=1,insideAlive=1,downOutside=0,contested=false},c,11,1)
check(result==false and reason:find('WARDEN'),'specific boss timeout')
run={phase='Exfil',bossSpawned=true,bossAlive=false,bossDefeatedAt=1,deadline=10,exfilProgress=0}
result,reason=X.step(run,{alive=1,insideAlive=1,downOutside=0,contested=true},c,11,1)
check(result==false and reason:find('OVERRUN'),'specific contest timeout')
print('Extraction regression assertions passed:',count)
