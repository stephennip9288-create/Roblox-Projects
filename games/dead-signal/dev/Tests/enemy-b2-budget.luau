-- Measured policy CPU and API admission under controlled latency/NoPath responses.
-- Excludes Roblox engine ComputeAsync, physics, rendering and network costs.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader');local V=r.Vector3;local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
r.implementMethod('Humanoid','MoveTo',function(h,p) h:SetAttribute('TestMoveTo',p) end)
local report={engine=false,agents=40,round=40,virtualSeconds=60,runs={}}
for _,debugEnabled in ipairs({false,true}) do
 local now=0;local queue={};local calls=0;local peak=0;local served={}
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
 local world={GetServerTimeNow=function() return now end,Raycast=function(_,p) return {Position=V.new(p.X,0,p.Z)} end,
  Blockcast=function() return {} end,GetPartBoundsInBox=function() return {} end}
 local pf={CreatePath=function(_,agent)
  check(not agent.AgentCanJump and not agent.AgentCanClimb,'stress paths keep no-jump/no-climb policy')
  calls+=1;return {Status=r.Enum.PathStatus.NoPath,ComputeAsync=function() end}
 end}
 local clock=table.clone(os);clock.clock=function() return now end
 local load=loader.new(dm,{services={PathfindingService=pf},globals={workspace=world,os=clock,RaycastParams={new=function() return {} end},
  OverlapParams={new=function() return {} end},task={spawn=function(fn) queue[#queue+1]=fn end}}})
 local E,R,N=load(f.server.Enemies),load(f.server.EnemyRigs),load(f.server.Navigation)
 local map=loader.new(dm)(f.server.MapBuilder).build('Station')
 for _,room in ipairs(map.rooms) do room.unlocked=true end;for _,door in ipairs(map.doors) do door.open=true end
 local folder=r.Instance.new('Folder');local character=r.Instance.new('Model');local pr=r.Instance.new('Part');pr.Name='HumanoidRootPart';pr.Position=map.rooms[1].center+V.new(0,3,0);pr.Parent=character
 local player={Parent=true,UserId=1,Character=character}
 local ctx={map=map,
  players={[player]={participating=true,status='Alive'}},run={id=1,round=40,phase='Wave',mode='Standard'},
  combat={hurt=function() error('no attack may pass a solid wall') end},feed={FireAllClients=function() end}}
 local h=setmetatable({ctx=ctx,list={},pending={},hazards={},folder=folder,corpses=r.Instance.new('Folder'),targetLoads={},pathTokens=4,pathBudgetAt=0,recovered=0},E)
 h.clearSight=function() return false end;ctx.enemies=h
 if debugEnabled then h.navigationDebug={started=0,events={},count=0,cursor=0,counters={}} end
 local specs={{'Shambler',{}},{'Runner',{Armored=true,Enraged=true}},{'Crawler',{}},{'Hound',{}},{'Hound',{Alpha=true}},{'Stalker',{}},{'Warden',{}}}
 local creation=os.clock()
 for id=1,40 do
  local spec=specs[(id-1)%#specs+1];local spawn=map.rooms[2+(id-1)%5].center+V.new(id%3*2,4,id%2*2)
  local model,root,hum=R.build(folder,spec[1],spawn,id,'Station')
  local e={id=id,kind=spec[1],mods=spec[2],model=model,root=root,hum=hum,entered=true,hp=500,maxHP=500,damage=20,baseSpeed=12,
   lastPosition=root.Position,lastMoved=0,nextPath=0,index=1,targetAt=0,phase=1,attack=1000,shock=1000}
  R.evolve(e);h.list[id]=e;e.original=root.CFrame
 end
 local creationMs=(os.clock()-creation)*1000;local samples={};local maximum=0
 for tick=1,400 do
  now=tick*.15;local started=os.clock();h:tick(now);local ms=(os.clock()-started)*1000
  peak=math.max(peak,h.activePaths or 0);maximum=math.max(maximum,ms)
  if tick>14 then samples[#samples+1]=ms end
  check((h.activePaths or 0)<=3,'at most three outstanding native requests')
  check(calls<=4+math.floor(now*12+.001),'global admission stays within twelve requests/sec plus four-token burst')
  check((h.roomPlanBudget or 0)>=0,'at most four structural room-route builds per rotating tick')
  if tick%2==0 then local pending=queue;queue={};for _,fn in ipairs(pending) do fn() end end
  for id,e in pairs(h.list) do if (e.pathRequests or 0)>0 then served[id]=true end end
 end
 local total=0
 for id,e in pairs(h.list) do
  total+=1;check(served[id] and e.hp==500 and e.root.CFrame==e.original,'stationary failure retains identity/HP without teleportation for actor '..id)
 end
 check(total==40 and h:count()==40 and h.recovered==0,'no invisible retirement or exterior relocation of entered actors')
 table.sort(samples);local sum=0;for _,ms in ipairs(samples) do sum+=ms end
 local row={diagnostics=debugEnabled,requests=calls,peakOutstanding=peak,served=total,creationMs=creationMs,
  meanMs=sum/#samples,medianMs=samples[math.ceil(#samples*.5)],p95Ms=samples[math.ceil(#samples*.95)],maxMs=maximum}
 if debugEnabled then local snapshot=N.snapshot(h,now);check(#snapshot.actors==40 and #snapshot.events<=128,'QA snapshot remains capped under stress');row.traceEvents=#snapshot.events
 else check(not h.navigationDebug,'normal gameplay allocates no diagnostic ring') end
 report.runs[#report.runs+1]=row
 map.model:Destroy()
 print('40-enemy offline policy benchmark:',serde.encode('json',row))
end
fs.writeDir('Validation/EnemyB2');report.assertions=count;fs.writeFile('Validation/EnemyB2/Budget.json',serde.encode('json',report))
print('Batch 2 forty-enemy budget assertions passed:',count)
