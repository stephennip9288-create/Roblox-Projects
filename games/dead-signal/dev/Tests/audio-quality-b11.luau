-- Batch 1.1 exact runtime, asynchronous loader and engine object doubles.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local candidate=fs.readFile('Source/Runtime/client/Effects.lua')
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
local function near(a,b,message) check(math.abs(a-b)<.00001,message) end
local function signal()
    local s={entries={}}
    function s:Connect(fn)
        local entry={fn=fn,active=true};self.entries[#self.entries+1]=entry
        return {Disconnect=function() entry.active=false end}
    end
    function s:Fire()
        for _,entry in ipairs(table.clone(self.entries)) do if entry.active then entry.fn() end end
    end
    return s
end
local function setup(low)
    local env={now=100,nodes={},loaded={},plays=0,fail=false,pending={},preloads=0,cancelled=0,rays=0}
    local function node(class,parent,props)
        local p={ClassName=class,Parent=parent,children={},Destroying=signal(),Ended=signal()}
        local obj={}
        local methods={}
        function methods:Destroy()
            if p.destroyed then return end
            p.Destroying:Fire();p.destroyed=true;p.Parent=nil
            for _,child in ipairs(p.children) do child:Destroy() end
        end
        function methods:Play() if env.fail then error('simulated denied playback') end;p.Playing=true;env.plays+=1 end
        function methods:Stop() p.Playing=false end
        function methods:GetChildren() return p.children end
        function methods:FindFirstChild(name) for _,child in ipairs(p.children) do if child.Name==name and child.Parent then return child end end end
        function methods:GetAttribute(name) return (p.attributes or {})[name] end
        function methods:SetAttribute(name,value) p.attributes=p.attributes or {};p.attributes[name]=value end
        setmetatable(obj,{__index=function(_,key) return methods[key] or p[key] end,__newindex=function(_,key,value)
            p[key]=value
            if key=='SoundId' then p.IsLoaded=value:sub(1,11)=='rbxasset://' or env.loaded[value]==true end
        end})
        for key,value in pairs(props or {}) do obj[key]=value end
        if parent and parent.children then parent.children[#parent.children+1]=obj end
        env.nodes[#env.nodes+1]=obj
        return obj
    end
    local settings={volume=.65,lowEffects=low==true}
    local config={DefaultSettings=settings,SoundIds={},Evolution={audio={}},Weapons={Kestrel={class='Pistol'},Trench={class='Shotgun'},Anchor={class='Heavy'}}}
    local util={copy=table.clone,make=node}
    local soundService=node('SoundService')
    local world={CurrentCamera={CFrame=r.CFrame.new(0,0,0)},FindFirstChild=function(_,name) return name=='DeadSignalMap' and env.map or nil end}
    local rs={DeadSignal={Config='Config',Util='Util',NPCPose='NPCPose'}}
    local content={}
    function content:PreloadAsync(items,callback)
        local probe=items[1];env.preloads+=1
        env.pending[probe.SoundId]={thread=coroutine.running(),probe=probe,callback=callback}
        local succeeded=coroutine.yield()
        callback(probe.SoundId,succeeded and r.Enum.AssetFetchStatus.Success or r.Enum.AssetFetchStatus.Failure)
    end
    local scheduler={spawn=function(fn) local thread=coroutine.create(fn);assert(coroutine.resume(thread));return thread end,
        cancel=function(thread) env.cancelled+=1;if coroutine.status(thread)~='dead' then coroutine.close(thread) end end}
    function world:Raycast(origin,delta) env.rays+=1;return env.blocked and {Position=origin+delta*.5} or nil end
    local services={ContentProvider=content,ReplicatedStorage=rs,SoundService=soundService,TweenService={},Debris={AddItem=function() end}}
    local clock=table.clone(os);clock.clock=function() return env.now end
    local FX=luau.load(candidate,{debugName='ProposedEffects',environment={
        game={GetService=function(_,name) return services[name] end},workspace=world,
        require=function(key) if key=='Config' then return config elseif key=='Util' then return util else return {} end end,
        Vector3=r.Vector3,Enum=r.Enum,os=clock,typeof=typeof,task=scheduler,RaycastParams={new=function() return {} end},
    },injectGlobals=true})()
    env.fx=FX.new();env.config=config;env.world=world;env.service=soundService;env.FX=FX;env.node=node
    function env:complete(id,success)
        id='rbxassetid://'..tostring(id);local job=assert(self.pending[id],id);self.pending[id]=nil
        if coroutine.status(job.thread)=='dead' then job.callback(id,r.Enum.AssetFetchStatus.Success);return end
        if success then
            self.loaded[id]=true
            for _,n in ipairs(self.nodes) do if n.SoundId==id then n.IsLoaded=true end end
        end
        assert(coroutine.resume(job.thread,success))
    end
    function env:activeSounds()
        local total=0;for _,n in ipairs(self.nodes) do if n.ClassName=='Sound' and n.Parent and not n.destroyed and n.Playing then total+=1 end end;return total
    end
    function env:advance(seconds)
        local steps=math.max(1,math.ceil(seconds/.1))
        for _=1,steps do self.now+=seconds/steps;self.fx:audioUpdate(seconds/steps) end
    end
    function env:approve(key,id)
        -- IDs here are arbitrary test fixtures; no network/Roblox asset lookup occurs.
        self.config.SoundIds[key]=tostring(id);self.loaded['rbxassetid://'..tostring(id)]=true
    end
    function env:live(class)
        local total=0
        for _,n in ipairs(self.nodes) do if n.Parent and not n.destroyed and (not class or n.ClassName==class) then total+=1 end end
        return total
    end
    function env:connections()
        local total=0
        for _,n in ipairs(self.nodes) do for _,entry in ipairs(n.Ended.entries) do if entry.active then total+=1 end end end
        return total
    end
    return env
end
local V=r.Vector3
-- A cold warning is immediate fallback, never a false permission failure.
do
    local e=setup();local fx=e.fx;e.config.SoundIds.Howl='9001'
    local first=fx:sound('Howl',V.new(12,0,0),{source='hound'})
    check(first and first.sound.SoundId=='rbxasset://sounds/uuhhh.mp3','cold warning retains functional fallback')
    check(not fx.audio.failed['rbxassetid://9001'],'cold cache is not denied permission')
    check(fx:audioDiagnostics().pending==1 and e.plays==1,'one silent warm request, no queued game cue')
    e:complete(9001,true);check(e.plays==1,'late load cannot replay the old warning')
    e:advance(.4)
    local second=fx:sound('Howl',V.new(12,0,0),{source='hound'})
    check(second.custom and second.sound.SoundId=='rbxassetid://9001' and second.sound.PlaybackSpeed==1,'next actual warning uses loaded authored recording')
    check(first.sound.SoundId~=second.sound.SoundId,'loaded asset never changes an already-started fallback mid-cue')
    fx:audioDestroy();check(e:live('Sound')==0 and e:connections()==0,'cache and voice teardown')
end
do
    local e=setup();local fx=e.fx;e.config.SoundIds['Zombie.Footstep']='9002'
    local result,reason=fx:sound('Zombie.Footstep',V.zero,{source='z'})
    check(not result and reason=='loading','cold optional foley has no stale playback')
    fx:audioUpdate(0);e:complete(9002,false)
    check(fx.audio.failed['rbxassetid://9002']>e.now and e.plays==0,'actual fetch failure gets bounded backoff')
    local requests=e.preloads;e:advance(20);check(e.preloads==requests,'denied asset does not churn retries every frame')
    e:advance(11);fx:sound('Zombie.Footstep',V.zero);fx:audioUpdate(0)
    check(e.preloads==requests+1,'later actual event can retry after backoff')
    local plays=e.plays;fx:audioReset('new-run');e:complete(9002,true)
    check(e.plays==plays and fx:audioDiagnostics().cached==0,'old epoch completion cannot attach a Sound')
end
-- Queue, cache and watchdog remain bounded even with oversized configuration.
for _,low in ipairs({false,true}) do
    local e=setup(low);local fx=e.fx;fx:audioInit()
    for n=1,300 do fx:audioRequest('rbxassetid://'..(10000+n)) end
    check(fx:audioDiagnostics().queued==32,'warm queue hard cap')
    fx:audioUpdate(0);check(fx:audioDiagnostics().pending==2,'two asynchronous decoders maximum')
    e:advance(8.1)
    check(e.cancelled>=2 and fx:audioDiagnostics().pending<=2,'watchdog cancels stuck jobs and respects concurrency')
    local peak=0
    for n=1,60 do
        local pending={};for id in pairs(fx.audio.loading) do pending[#pending+1]=id end
        for _,id in ipairs(pending) do e:complete(id:match('(%d+)$'),true) end
        fx:audioUpdate(0);local diag=fx:audioDiagnostics();peak=math.max(peak,diag.cached)
        check(diag.cached<=(low and 16 or 32) and diag.pending<=2 and diag.queued<=32,'bounded preload lifecycle '..n)
    end
    check(peak>0,'loader exercised successful cache admission')
    fx:audioDestroy();check(e:live('Sound')==0,'loader/cache owner teardown')
end
do
    local e=setup();local fx=e.fx;fx:audioInit()
    for n=1,32 do fx.audio.ready[tostring(n)]={sound=e.node('Sound',fx.audio.flat,{}),at=n} end
    fx.settings.lowEffects=true;fx:audioUpdate(0)
    check(fx:audioDiagnostics().cached==16,'live low quality change trims existing cache')
end
-- Variants change by family, independent of unrelated UI or other emitters.
do
    local e=setup();local fx=e.fx
    e.config.SoundIds.Rifle={near={'11001','11002','11003'},gain=.8}
    for _,id in ipairs({'11001','11002','11003'}) do e.loaded['rbxassetid://'..id]=true end
    local seen={};local previous
    for i=1,18 do
        local v=fx:sound('Weapon.Report',V.zero,{class='Rifle',sourceId='shooter-'..i})
        check(v and v.custom and v.sound.SoundId~=previous,'different recording, no immediate repeated rifle sample')
        check(v.sound.PlaybackSpeed==1,'no placeholder pitch substitution')
        near(v.gain,.38*.8,'recording calibration and bank mastering gain')
        previous=v.sound.SoundId;seen[previous]=true;v.sound.Ended:Fire();fx:sound('Click');e:advance(.15)
    end
    local total=0;for _ in pairs(seen) do total+=1 end;check(total==3,'all real sample variants used')
    for i=1,300 do fx:sound('Hit',nil,{class='unique-'..i,sourceId=i});e:advance(.11) end
    total=0;for _ in pairs(fx.audio.variation) do total+=1 end;check(total<=128,'variant history is bounded')
end
-- Close/far recordings crossfade continuously while both consume native slots.
do
    local e=setup();local fx=e.fx;e:approve('Rifle',12001);e:approve('Rifle.Far',12002)
    local v=fx:sound('Rifle',V.new(20,0,0),{source='remote'})
    check(v.cost==2 and v.farSound and fx:audioDiagnostics().voices==2,'report pair counted as two voices')
    check(v.sound.Volume>0 and v.farSound.Volume<.00001,'close report dominates nearby')
    e.world.CurrentCamera.CFrame=r.CFrame.new(-55,0,0);e:advance(.1)
    near(v.sound.Volume,v.farSound.Volume,'equal power midpoint at 75 studs')
    local logical=fx:audioGain(v)
    near(v.sound.Volume*v.sound.Volume+v.farSound.Volume*v.farSound.Volume,logical*logical,'constant energy through crossfade')
    e.world.CurrentCamera.CFrame=r.CFrame.new(-100,0,0);e:advance(.1)
    check(v.sound.Volume<.00001 and v.farSound.Volume>0,'distant physical report dominates without a restart')
    local plays=e.plays;e:advance(.1);check(e.plays==plays,'moving listener does not start duplicate reports')
    v.sound.Ended:Fire();check(not v.retired,'shorter layer cannot truncate remaining natural tail')
    v.farSound.Ended:Fire();check(v.retired and e:connections()==0,'last layer completion cleans pair and both connections')
end
do
    local e=setup(true);local fx=e.fx;e:approve('Rifle',12011);e:approve('Rifle.Far',12012)
    local close=fx:sound('Rifle',V.new(20,0,0),{source='near'})
    local far=fx:sound('Rifle',V.new(100,0,0),{source='far'})
    check(close.cost==1 and not close.farSound and close.sound.SoundId=='rbxassetid://12011','mobile selects one close recording')
    check(far.cost==1 and not far.farSound and far.sound.SoundId=='rbxassetid://12012','mobile selects one distant recording')
end
-- Acknowledged adjacent mechanical phases cannot swallow each other.
do
    local e=setup();local fx=e.fx;e:approve('Weapon.Magazine.Rifle.mag-out',13001);e:approve('Weapon.Magazine.Rifle.mag-in',13002)
    local out=fx:audioEvent('Weapon.Mechanism',{phase='mag-out',class='Rifle',token='reload',sourceId='operator'})
    e:advance(.04)
    local into=fx:audioEvent('Weapon.Mechanism',{phase='mag-in',class='Rifle',token='reload',sourceId='operator'})
    check(out and into and out.sound.SoundId~=into.sound.SoundId,'mag out/in have separate recordings and cooldown identity')
    check(not fx:audioEvent('Weapon.Mechanism',{phase='mag-in',class='Rifle',token='reload',sourceId='operator'}),'same phase replay remains deduplicated')
    fx:audioCancel('reload');check(out.retired and into.retired,'accepted action cancellation stops all mechanical layers')
    check(not fx:audioEvent('Weapon.Mechanism',{phase='mag-out',class='Rifle',token='reload'}),'cancel rejects late phase')
end
-- Metadata distinguishes enclosed halls, corridors and exterior acoustics.
do
    local e=setup();local fx=e.fx
    local map=e.node('Model',nil,{Name='DeadSignalMap'});e.map=map
    local semantics=e.node('Folder',map,{Name='MapSemantics'});local zones=e.node('Folder',semantics,{Name='Zones'})
    local function zone(id,x,width,length,purpose,indoors)
        local z=e.node('Folder',zones,{Name=id});z:SetAttribute('Position',V.new(x,0,0));z:SetAttribute('Indoors',indoors);z:SetAttribute('Purpose',purpose)
        local region=e.node('Folder',z,{});region:SetAttribute('PointCount',4)
        for i,p in ipairs({V.new(x-width/2,0,-length/2),V.new(x+width/2,0,-length/2),V.new(x+width/2,0,length/2),V.new(x-width/2,0,length/2)}) do region:SetAttribute('Point'..i,p) end
    end
    zone('hall',0,50,50,'Machine hall',true);zone('corridor',100,8,30,'Service corridor',true);zone('exterior',200,50,50,'Ice apron',false)
    fx:audioState({map='Foundry',runId=1,room='hall',indoors=true})
    check(fx:audioSpace(V.new(0,3,0))=='hall' and fx:audioSpace(V.new(100,3,0))=='corridor' and fx:audioSpace(V.new(200,3,0))=='outdoor','source footprints resolve acoustic profiles')
    e:approve('Rifle',14001);local v=fx:sound('Rifle',nil,{firstPerson=true});e:advance(.2)
    check(v.reverb and v.reverb.DecayTime==1.4 and v.reverb.WetLevel>-80,'first-person report gets actual hall character')
    fx:audioState({map='Foundry',runId=1,room='corridor',indoors=true});e:advance(.2)
    near(v.reverb.DecayTime,.8,'corridor has shorter decay')
    fx:audioState({map='Foundry',runId=1,room='exterior',indoors=false});local wet=v.reverb.WetLevel;e:advance(.2)
    check(v.reverb.WetLevel<wet,'outdoor transition smoothly removes wet return')
    local warning=fx:sound('Howl',V.new(2,3,0));check(not warning.reverb and not warning.equalizer,'critical warning remains dry/readable')
end
do
    local e=setup();local fx=e.fx;e.map=e.node('Model',nil,{Name='DeadSignalMap'});e.blocked=true
    for i=1,4 do e:approve('Rifle',15001);fx:sound('Rifle',V.new(15+i,0,0),{sourceId=i}) end
    e:advance(.8)
    check(e.rays<=10,'occlusion uses at most two map rays per 200 ms')
    local v=fx.audio.voices[1];check(v.equalizer and v.equalizer.HighGain<0,'real map obstruction attenuates high frequencies')
    e.blocked=false;e:advance(1.6)
    check(v.occlusionGain>.99,'unobstructed transition restores gain')
end
-- Dense waves exercise pair costs, warning reserves, cadence and mute.
for _,low in ipairs({false,true}) do
    local e=setup(low);local fx=e.fx;local max=low and 12 or 20;local reserve=low and 6 or 8
    e:approve('Rifle',16001);e:approve('Rifle.Far',16002);e:approve('Zombie.Groan',16003)
    for i=1,40 do fx:sound('Zombie.Groan',V.new(i,0,0),{sourceId='z'..i}) end
    local vocals=0;for _,v in ipairs(fx.audio.voices) do if v.key=='Zombie.Groan' then vocals+=1 end end
    check(vocals==1,'large group does not produce a synchronized groan choir')
    for i=1,40 do fx:sound('Rifle',V.new(i,0,0),{sourceId='p'..i}) end
    check(fx:audioDiagnostics().voices<=max-reserve,'report pairs respect routine reservation')
    for i=1,40 do fx:sound('Hound.Charge',V.new(40+i,0,0),{sourceId='h'..i}) end
    local close=fx:sound('Warden.Warning',V.new(2,0,0),{sourceId='warden'})
    check(close and close.sound.Playing,'critical nearby warning preempts dense mix')
    check(fx:audioDiagnostics().voices<=max and e:activeSounds()<=max,'native decoder hard limit at 40 enemies')
    fx.settings.volume=0;e:advance(.1)
    for _,v in ipairs(fx.audio.voices) do check(v.sound.Volume==0 and (not v.farSound or v.farSound.Volume==0),'mute reaches every report layer') end
    local plays=e.plays;check(not fx:sound('Rifle') and e.plays==plays,'mute queues no new gameplay sound')
    fx.settings.volume=.65
    for i=1,30 do fx:audioState({map=({'Station','Foundry','Frost'})[(i-1)%3+1],runId=i,token='scene-'..i});fx:sound('Rifle');e:advance(.1) end
    fx:audioDestroy();check(e:live('Sound')==0 and e:live('Part')==0 and e:connections()==0,'thirty travel/respawn sessions leave no voices/cache/anchors/connections')
end
print('Audio quality Batch 1.1 assertions passed:',count)
