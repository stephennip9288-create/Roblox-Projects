-- Executes the real LoadingScreen:set with textures deliberately never render-ready.
-- This verifies load ordering, fallback and late preloads; it is not an engine render test.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'))
local folders=loader.install(dm) local queued={} local calls=0 local fail=false local checks=0
local function check(ok,message) assert(ok,message);checks+=1 end
local load=loader.new(dm,{modules={Util={},ArrivalRules={}},
 services={ContentProvider={PreloadAsync=function(_,instances)
  calls+=1 check(#instances==1 and instances[1].Parent,'preload receives the actual image instance')
  if fail then error('simulated unavailable texture') end
 end}},globals={task={spawn=function(fn) queued[#queued+1]=fn end}}})
local Loading=load(folders.shared.LoadingScreen) local C=load(folders.shared.Config)
local originals=table.clone(C.MapArtworkIds)
local function drain()
 local pending=queued;queued={}
 for _,fn in ipairs(pending) do fn() end
end
local function screen()
 local s={generation=0,map=nil,frame={Visible=false},
  image={Parent=true,Image='',Visible=false,IsLoaded=false},
  backdrop={Visible=true},backdropGradient={},backdropMotif={},
  name={},lore={},status={},scenes={Lobby={},Station={},Foundry={},Frost={}}}
 return setmetatable(s,Loading)
end
for _,map in ipairs({'Lobby','Station','Foundry','Frost'}) do
 local s=screen();s:set(map,'connecting',true)
 check(s.image.Visible and s.frame.Visible and not s.image.IsLoaded,map..' can render before IsLoaded')
 check(s.image.Image=='rbxassetid://'..originals[map],map..' retains original asset ID')
 check(s.backdrop.Visible,map..' retains opaque fallback during download')
 for name,root in pairs(s.scenes) do check(root.Visible==(name==map),'only selected fallback is visible') end
 drain();check(s.image.Visible and not s.image.IsLoaded,'successful preload does not re-hide pending texture')
 s:set(map,'complete',false);check(not s.frame.Visible,'arrival still hides the entire loading layer')
 s:set(map,'travel again',true);check(s.frame.Visible and s.image.Visible,'reactivation can reload a discarded texture')
end
local s=screen();s:set('Station','first',true);s:set('Foundry','second',true);drain()
check(s.image.Image=='rbxassetid://'..originals.Foundry and s.image.Visible,'late preload cannot override a new map')
fail=true;s=screen();s:set('Frost','unavailable',true);drain();fail=false
check(s.image.Visible and s.backdrop.Visible and s.frame.Visible,'download error retains original slot and local fallback')
for _,id in ipairs({'','0','-42','invalid'}) do
 C.MapArtworkIds.Lobby=id;s=screen();s:set('Lobby','no artwork',true)
 check(not s.image.Visible and s.image.Image=='' and s.backdrop.Visible and s.frame.Visible,'invalid/missing ID keeps fallback')
 check(#queued==0,'invalid ID does not start a fetch')
end
C.MapArtworkIds.Lobby=originals.Lobby
s=screen();s:set('Station','first',true);C.MapArtworkIds.Lobby='';s:set('Lobby','no art',true);drain()
check(not s.image.Visible and s.image.Image=='','stale preload cannot reveal a cleared image')
C.MapArtworkIds.Lobby=originals.Lobby
C.MapArtworkIds.Station='rbxassetid://'..originals.Station
s=screen();s:set('Station','URI ID',true);drain()
check(s.image.Image==C.MapArtworkIds.Station and s.image.Visible,'asset URI input remains supported')
C.MapArtworkIds.Station=originals.Station
check(C.ProfileStore=='DeadSignal_Profile_v1','profile namespace is unchanged')
check(calls==9,'expected fetches only; no unbounded retry loop')
print('Loading artwork assertions passed:',checks)
