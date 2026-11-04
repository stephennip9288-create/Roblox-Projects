-- Actual map Parts and retained rigs; controlled services are not Roblox physics.
local fs=require('@lune/fs');local r=require('@lune/roblox');local serde=require('@lune/serde');local process=require('@lune/process')
local loader=require('./Support/RuntimeLoader');local G=require('./Support/EnemyB11Geometry');local V=r.Vector3
local before=process.args[1]=='before';local count=0;local function check(ok,msg) assert(ok,msg);count+=1 end
local function install(dm)
 local f=loader.install(dm)
 if before then for _,spec in ipairs({{'server','Enemies'},{'server','EnemyRigs'},{'server','InfectedWardrobe'},{'server','Navigation'},{'shared','NPCPose'}}) do
  f[spec[1]][spec[2]].Source=fs.readFile('Validation/EnemyB1Followup/BeforeSource/'..spec[1]..'/'..spec[2]..'.lua')
 end end
 return f
end
local report={engine=false,before=before,maps={},lower_slots={},admitted=0,deferred=0}
for _,id in ipairs({'Station','Foundry','Frost'}) do
 local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-'..id..'.rbxl'));local f=install(dm)
 local map=loader.new(dm)(f.server.MapBuilder).build(id);local strict=table.clone(map);strict.floorRegions={}
 strict.floorParts=table.clone(map.floorParts);local exterior=map.model:FindFirstChild('ExteriorGround');if exterior then strict.floorParts[#strict.floorParts+1]=exterior end
 local world=G.world(strict);local load=loader.new(dm,{globals={workspace=world,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}})
 local N=load(f.server.Navigation);local R=load(f.server.EnemyRigs);local folder=r.Instance.new('Folder');local owner={ctx={map=map,players={}},list={},folder=folder}
 local row={map=id,windows=0,admitted=0,deferred=0}
 for wi,w in ipairs(map.windows) do
  w.count=0;owner.list={};local models={};local descriptor=N.entryDescriptor(map,w);check(descriptor~=nil,'real map descriptor remains supported')
  for n=1,3 do
   local model,root,hum=R.build(folder,'Shambler',w.outside,n,id);local e={id=n,kind='Shambler',model=model,root=root,hum=hum,mods={},window=w,entered=false};R.evolve(e)
   local p=N.queuePosition(owner,e,w)
   if p then
    local feet=p.Y-N.rootHeight(e);row.admitted+=1;report.admitted+=1
    if math.abs(feet-descriptor.approach.Y)>.25 then report.lower_slots[#report.lower_slots+1]={map=id,window=wi,feetY=feet,approachY=descriptor.approach.Y} end
    if not before then
     check(math.abs(feet-descriptor.approach.Y)<=.25,'admission cannot strand a no-jump actor below the apron')
     check(N.queueRoute(owner,e,p,descriptor,w,N.rigBounds(e,'Walk','Approach')),'queue has a continuous same-level route to approach')
    end
    model:PivotTo(r.CFrame.lookAt(p,p+w.entry.approach.LookVector));owner.list[n]=e
   else row.deferred+=1;report.deferred+=1 end
   models[#models+1]=model
  end
  row.windows+=1;for _,m in ipairs(models) do m:Destroy() end
 end
 report.maps[#report.maps+1]=row;check(row.windows==10 and row.admitted>=10,'all windows admit at least one supported unit')
 folder:Destroy();map.model:Destroy()
end
fs.writeDir('Validation/EnemyB1Followup');fs.writeFile('Validation/EnemyB1Followup/'..(before and 'Queues-Before' or 'Queues')..'.json',serde.encode('json',report))
if before then
 assert(#report.lower_slots>0,'negative control must reproduce low exterior admissions')
 print('Before correction: lower queue admissions:',#report.lower_slots,'of',report.admitted);return
end
check(#report.lower_slots==0,'all actual-map admissions stay on reachable apron support')
local H=require('./Support/InfectedHarness')
do
 local h=H.new();local e=h:enemy('Shambler');e.window.activeEntry=98765
 check(h.N.queueHead(h.enemies,e,e.window) and not e.window.activeEntry,'a removed reservation owner cannot lock a window')
 e.window.activeEntry=e.id;e.entered=true
 check(not h.N.queueHead(h.enemies,e,e.window) and not e.window.activeEntry,'an entered non-traversing actor cannot keep ownership')
end
do
 local h=H.new();h:player(1,V.new(25,3,35));local e=h:enemy('Shambler');h.ctx.map.windows={e.window}
 h.blocked=true;e.entryFailure='Geometry';h.enemies:recover(e)
 local expires=e.failedEntryUntil[e.window];check(expires>h.time and e.failedEntries[e.window]==1,'real hard failure gets a bounded exclusion')
 h.time+=5;h.enemies:recover(e);check(e.failedEntryUntil[e.window]==expires,'recover calls cannot extend a cached failure indefinitely')
 h.blocked=false;h.time=expires+.01
 check(h.N.entryPlan(h.enemies,e,e.window)~=nil and not e.failedEntries[e.window],'cleared transient obstruction is actually reprobed after backoff')
 check(h.enemies:count()==1 and e.hp==500 and not e.dead,'reprobe retains quota and health')
end
do
 local h=H.new();h:player(1,V.new(25,3,35));local e=h:enemy('Shambler');e.hum.PlatformStand=true
 local plan=h.N.entryPlan(h.enemies,e,e.window);check(h.enemies:startTraversal(e,plan,h.time),'physical-state recovery fixture starts')
 for _=1,400 do h:step(1/30);if not e.traversal then break end end
 check(e.entered and not e.hum.PlatformStand and e.hum.AutoRotate and not e.root.Anchored,'successful entry always restores live Humanoid chasing state')
end
print('Batch 1 entry follow-up assertions passed:',count)
