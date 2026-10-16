local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl')) local f=loader.install(dm) local load=loader.new(dm)
local A=load(f.shared.ArrivalRules) local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
for _,phase in ipairs({'Preparing','Wave','Intermission','Exfil'}) do
 local s={role='Match',participating=true,status='Alive',phase=phase}
 check(A.ready(s,true,true,true,true),'ready gameplay releases the opaque screen, including preparing')
 for missing=1,4 do
  local flags={true,true,true,true};flags[missing]=false
  check(not A.ready(s,table.unpack(flags)),'loading gate waits for character, world, ready flag and floor')
 end
 s.travelling=true;check(not A.ready(s,true,true,true,true),'outgoing travel cannot be dismissed by ready geometry')
end
local s={role='Match',participating=false,status='Arriving',phase='Preparing'}
check(not A.ready(s,true,true,true,true),'arrival authorization required')
s.status='Rejected';check(A.ready(s,false,false,false,false),'rejected arrival does not retain an infinite loading screen')
s={role='Lobby',participating=false,status='Lobby'};check(A.ready(s,true,true,false,false),'Dispatch arrival completes without a match floor')
check(not A.ready(s,false,true,false,false),'Dispatch waits for character')
print('Arrival handoff assertions passed:',count)
