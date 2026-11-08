-- Actual Config/Effects; production permission is externally verified, never inferred here.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local setup=require('./Fixtures/audio-corrections-env') local count=0
local old=fs.readFile('Reviews/production-batch1/STAGED-CONFIG.lua.txt') local current=require('./Fixtures/audio-b2-config').original(fs.readFile('Source/Runtime/shared/Config.lua'))
local function check(ok,message) assert(ok,message);count+=1 end
local function same(a,b)
 if type(a)~=type(b) then return false end;if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not same(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end;return true
end
local function config(source,id)
 local controls=luau.load(fs.readFile('Source/Runtime/shared/ControlSettings.lua'))()
 return luau.load(source,{environment={game={GameId=id},script={Parent={ControlSettings='c'}},require=function() return controls end},injectGlobals=true})()
end
for _,id in ipairs({10771141095,0,1,10770732079,10771141096}) do check(same(config(old,id),config(current,id)),'Exact unchanged Config in staging/other universe '..id) end
local stage=config(current,10771141095);local prod=config(current,10770732078);local before=config(old,10770732078)
check(same(prod.SoundIds,stage.SoundIds),'All production banks exactly match accepted staging')
for key,value in pairs(before) do if key~='SoundIds' then check(same(value,prod[key]),'Production non-audio Config retained '..key) end end
check(prod.SoundIds['Board.Stress']==nil and prod.SoundIds['Board.Debris']==nil,'Unbound components remain unbound')
check(prod.ProfileStore=='DeadSignal_Profile_v1' and prod.ProfileStore==before.ProfileStore,'No player-data namespace change')
local function ready(e,v)
 if type(v)=='string' and v:match('^rbxassetid://%d+$') then e.loaded[v]=true elseif type(v)=='table' then for _,x in pairs(v) do ready(e,x) end end
end
for _,id in ipairs({10771141095,10770732078}) do for _,low in ipairs({false,true}) do
 local e=setup(low,config(current,id));ready(e,e.config.SoundIds)
 local allowed={Board={['rbxassetid://121376790132442']=true,['rbxassetid://91133693743569']=true},['Enemy.Entry.Contact']={['rbxassetid://128395906553592']=true,['rbxassetid://126280091004313']=true}}
 for key,bank in pairs(allowed) do for n=1,8 do
  local v=e.fx:sound(key,r.Vector3.new(8,0,0),{token=key..n,sourceId='actor-'..n})
  check(v and bank[v.sound.SoundId] and v.custom,'Correct production/staging event bank '..key)
  check(v.sound.PlaybackSpeed==1 and not v.sound.Looped and v.anchor~=nil,'Spatial natural-speed one-shot retained')
  v.sound.Ended:Fire();e.fx:audioUpdate(0);e:advance(.7)
 end end
 local landing=e.fx:sound('Enemy.Entry.Land',r.Vector3.zero,{token='land',sourceId='entry'});check(landing and not allowed['Enemy.Entry.Contact'][landing.sound.SoundId],'Landing is separate')
 e.fx.settings.volume=0;check(not e.fx:sound('Board',r.Vector3.zero,{sourceId='mute'}),'Master mute')
 e.fx:audioDestroy();check(e:live('Sound')==0,'Repeat-session cleanup')
end end
local unknown=setup(false,config(current,123));check(not unknown.fx:sound('Board',r.Vector3.zero),'Unknown universe does not receive protected audio banks');unknown.fx:audioDestroy()
print('Production audio assertions passed:',count)
