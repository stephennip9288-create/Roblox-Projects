-- Export exact policy/unchanged pursuit tuning. No place serialization, remote,
-- gameplay acceleration or native-performance claim.
local fs=require('@lune/fs') local r=require('@lune/roblox') local serde=require('@lune/serde')
local loader=require('../Tests/Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm);local load=loader.new(dm)
local M=load(f.shared.Movement) local R=load(f.shared.Rules)
local function speed(degrees,flags)
 local angle=math.rad(degrees) local state={alive=true,stamina=100,requested=false}
 for key,value in pairs(flags or {}) do state[key]=value end
 return M.policy(r.Vector3.new(math.sin(angle),0,-math.cos(angle)),r.Vector3.new(0,0,-1),state).speed
end
local report={sourceBaseline='7aaf323de6153134df2154c7ae3b1613a596495b',tuning=M.tuning,
    enginePlaytest=false,balanceStatus='Recommended initial values; native gameplay approval pending',speeds={},angles={},pursuit={}}
for name,flags in pairs({normal={},Marathon={marathon=true},ADS={aiming=true}}) do
 report.speeds[name]={forward=speed(0,flags),backward=speed(180,flags),strafe=speed(90,flags),diagonal=speed(45,flags)}
 if name~='ADS' then flags.requested=true report.speeds[name].sprint=speed(0,flags) end
end
for degrees=0,180,5 do
 report.angles[#report.angles+1]={degrees=degrees,walk=speed(degrees),sprintRequest=speed(degrees,{requested=true}),
    Marathon=speed(degrees,{marathon=true}),ADS=speed(degrees,{aiming=true})}
end
for _,round in ipairs({1,5,8,10,15,20,30,40}) do
 report.pursuit[#report.pursuit+1]={round=round,shambler=R.enemySpeed(round,'Shambler'),runner=R.enemySpeed(round,'Runner'),hound=R.enemySpeed(round,'Hound')}
end
fs.writeFile('Reviews/movement-batch2/Balance-Report.json',serde.encode('json',report,true))
print('Exported directional speeds and unchanged round pursuit curves; native tuning remains pending.')
