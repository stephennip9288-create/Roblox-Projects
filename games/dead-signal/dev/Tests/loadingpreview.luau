-- Execute the Studio preview and actual LoadingScreen constructor/set against UI
-- and service doubles. Tests control flow/layout intent, not engine painting.
local fs=require('@lune/fs') local r=require('@lune/roblox') local luau=require('@lune/luau') local serde=require('@lune/serde')
local loader=require('./Support/RuntimeLoader') local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl')) local folders=loader.install(dm)
local timers={} local reports={} local studio,running,client=true,true,true local constructed=0
local function signal()
 local listeners={}
 return {Connect=function(_,fn) listeners[#listeners+1]=fn end,Fire=function() for _,fn in ipairs(listeners) do fn() end end}
end
local function make(class,parent,props)
 constructed+=1
 local object={ClassName=class,Parent=parent,Name=class,children={},AbsoluteSize=r.Vector2.new(1280,720),IsLoaded=false,Activated=signal()}
 function object:FindFirstChild(name) for _,child in ipairs(self.children) do if child.Parent==self and child.Name==name then return child end end end
 function object:GetPropertyChangedSignal() return signal() end
 function object:Destroy() self.Parent=nil end
 for key,value in pairs(props or {}) do object[key]=value end
 if parent then parent.children[#parent.children+1]=object end
 return object
end
local playerGui=make('PlayerGui') local run={IsStudio=function() return studio end,IsRunning=function() return running end,IsClient=function() return client end}
local service={RunService=run,Players={LocalPlayer={WaitForChild=function(_,name) check(name=='PlayerGui','preview uses local PlayerGui');return playerGui end}},
 ReplicatedStorage=dm.ReplicatedStorage,HttpService={JSONEncode=function(_,data) return serde.encode('json',data) end},
 ContentProvider={PreloadAsync=function(_,objects) objects[1].IsLoaded=true end}}
local load=loader.new(dm,{modules={Util={make=make}},services=service})
local Loading=load(folders.shared.LoadingScreen) local C=load(folders.shared.Config)
local originalNew=Loading.new local selected
Loading.new=function(parent) selected=originalNew(parent);return selected end
local env={game={PlaceId=0,GameId=0,GetService=function(_,name) assert(service[name],'unexpected service '..name);return service[name] end},
 Instance={new=function(class) return make(class) end},Enum=r.Enum,UDim2=r.UDim2,Color3=r.Color3,require=load,
 task={delay=function(seconds,fn) timers[#timers+1]={seconds=seconds,fn=fn} end},
 print=function(message) reports[#reports+1]=serde.decode('json',message:sub(#'[DeadSignal Loading Preview] '+1)) end}
-- Instance.new assigns Parent later in the preview; record those parent changes.
env.Instance.new=function(class)
 local object=make(class)
 return setmetatable(object,{__newindex=function(t,key,value)
  rawset(t,key,value)
  if key=='Parent' and value then value.children[#value.children+1]=t end
 end})
end
local source=fs.readFile('Tools/preview-loading-art-studio.lua')
local function preview() return luau.load(source,{environment=env,injectGlobals=true})() end
local function flushReports()
 local pending=timers;timers={}
 for _,timer in ipairs(pending) do if timer.seconds<120 then timer.fn() else timers[#timers+1]=timer end end
end
local function view() return playerGui:FindFirstChild('DeadSignalArtworkPreview') end
local function button(name) return view():FindFirstChild('PreviewControls'):FindFirstChild(name) end
for _,flags in ipairs({{false,true,true},{true,false,true},{true,true,false}}) do
 studio,running,client=table.unpack(flags)
 local before=constructed local ok=pcall(preview)
 check(not ok and constructed==before,'preview rejects non-Studio, editor-only and server contexts before creating UI')
end
studio,running,client=true,true,true
preview()
check(view()~=nil and view().DisplayOrder==10000,'preview stays above the normal loading HUD')
check(selected.frame.Visible and selected.image.Visible,'actual screen is displayed without an arrival update')
check(selected.frame.BackgroundTransparency==0 and selected.image.ZIndex>selected.backdrop.ZIndex,'actual opaque loading layer and artwork order retained')
check(#timers==3,'preview schedules bounded diagnostics and automatic cleanup')
for _,map in ipairs({'Lobby','Station','Foundry','Frost'}) do
 button('Show'..map).Activated:Fire()
 check(selected.map==map and selected.image.Image=='rbxassetid://'..C.MapArtworkIds[map],'button selects configured original artwork for '..map)
 check(selected.frame.Visible and selected.image.Visible,'selected map stays open for inspection')
 flushReports()
 local report=reports[#reports]
 check(report.map==map and report.imageIsLoaded and report.screenVisible and report.imageVisible,'reports actual module image flags')
 check(report.publishedPermissionTest==false and report.testedIn=='Studio client / actual LoadingScreen module','does not claim published permission verification')
 check(report.viewport[1]==1280 and report.viewport[2]==720,'reports actual image viewport')
end
local before=#reports
button('ShowStation').Activated:Fire();button('ShowFrost').Activated:Fire();flushReports()
check(#reports==before+2 and reports[#reports].map=='Frost','stale timers cannot report an old map')
button('ShowFoundry').Activated:Fire();selected.image.IsLoaded=false;flushReports()
check(not reports[#reports].imageIsLoaded and selected.frame.Visible,'failed/unready artwork stays inspectable and reports truthfully')
local old=view();preview()
check(old.Parent==nil and view()~=old,'repeated preview replaces its own GUI only')
button('ClosePreview').Activated:Fire();flushReports()
check(view()==nil,'close removes temporary preview without reopening it')
preview()
local pending=timers;timers={}
for _,timer in ipairs(pending) do if timer.seconds==120 then timer.fn() end end
check(view()==nil,'automatic timeout removes abandoned preview')
check(C.ProfileStore=='DeadSignal_Profile_v1','profile namespace retained')
print('Studio loading preview assertions passed:',count)
