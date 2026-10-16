-- Validate actual client effect instances/cleanup under both quality settings.
-- Native rendering, audio playback quality and device frame times require staging.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl'));local f=loader.install(dm)
local camera=dm:FindFirstChild('Workspace').CurrentCamera
if camera then camera.CFrame=r.CFrame.new(0,4,0) end
r.implementMethod('ParticleEmitter','Emit',function(p,n) p:SetAttribute('TestEmission',n) end)
local debris={} local sounds={} local count=0
local function check(ok,msg) assert(ok,msg);count+=1 end
local load=loader.new(dm,{globals={TweenInfo={new=function(...) return {...} end}},services={Debris={AddItem=function(_,p,t) debris[#debris+1]={p=p,t=t} end},TweenService={Create=function() return {Play=function() end} end}}})
local FX=load(f.client.Effects);local V=r.Vector3
for _,low in ipairs({false,true}) do
 local fx=FX.new();fx.settings.lowEffects=low;fx.sound=function(_,key) sounds[#sounds+1]=key end
 fx:hazardWarning({id=1,position=V.zero,radius=7,duration=1.25,cue='Howl'})
 check(#fx.hazards[1].warnings==(low and 13 or 25),'warning retained at low quality')
 for _,p in ipairs(fx.hazards[1].warnings) do check(not p.CanCollide and not p.CanQuery,'warnings cannot affect shots or collision') end
 fx:hazardBlast({id=1,position=V.zero,radius=7,smoke=2.6,flames=2.2,opacity=.30})
 local h=fx.hazards[1];local smoke=h.smoke:FindFirstChildOfClass('ParticleEmitter');local fire=h.fire:FindFirstChildOfClass('ParticleEmitter')
 check(smoke.Rate==0 and smoke:GetAttribute('TestEmission')==(low and 2 or 5),'bounded one-shot smoke particles')
 check(smoke.Transparency.Keypoints[1].Value>=(low and .82 or .68)-.001,'smoke has configured transparency ceiling')
 check(fire.Rate<=(low and 4 or 10),'flame particle rate capped')
 fx:hazardCounter({id=1,kind='Vent'});check(h.fire.Parent~=nil,'vent never removes flames')
 h.smoke=nil;fx:hazardCounter({id=1,kind='Vent'});check(h.fire.Parent~=nil,'missing smoke cannot fall through to fire')
 fx:hazardCounter({id=1,kind='Sprinkler'});h.fire=nil
 fx:clearHazards();check(next(fx.hazards)==nil,'map reset clears hazard cache')
 fx:hazardBlast({id=2,position=V.zero,radius=7,smoke=0,flames=0,opacity=.3})
 check(not fx.hazards[2].smoke and not fx.hazards[2].fire,'suppressed hazards create no lingering obstruction')
 fx:clearHazards()
end
check(#sounds>0,'distinct audio cue hooks invoked')
print('Evolution presentation assertions passed:',count)
