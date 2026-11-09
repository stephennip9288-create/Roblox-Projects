-- Service doubles test the Studio tool's gates, failures and cleanup.
-- These observations are synthetic; they are never native eligibility evidence.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local source=fs.readFile('Tools/probe-batch2-audio-studio.lua')
return function()
    local assertions=0
    local function check(ok,message) assert(ok,message);assertions+=1 end
    local function environment(options)
        options=options or {}
        local env={now=0,nodes={},calls=0,plays=0,queue={},created=0,maxSounds=0,cancelled=0}
        local lengths={['79202413557343']=3,['128855928185941']=3.312,['101059835221623']=3.816,
            ['123384623508546']=1.071020408,['124107740668584']=4.5,['122477333598212']=2.497958333,['92629845353488']=1.999433107}
        local function signal()
            local callbacks={}
            return {Connect=function(_,fn) callbacks[#callbacks+1]=fn;return {Disconnect=function() end} end,
                    Fire=function() for _,fn in ipairs(callbacks) do fn() end end}
        end
        local function resume(thread)
            local ok,delay=coroutine.resume(thread);assert(ok,delay)
            if coroutine.status(thread)~='dead' and type(delay)=='number' then env.queue[#env.queue+1]={at=env.now+delay,thread=thread} end
        end
        local taskApi={spawn=function(fn) local t=coroutine.create(fn);resume(t);return t end,
            wait=function(delay) return coroutine.yield(delay or .1) end,
            delay=function(delay,fn) local t=coroutine.create(fn);env.queue[#env.queue+1]={at=env.now+delay,thread=t};return t end,
            cancel=function(thread) if coroutine.status(thread)~='dead' then env.cancelled+=1;coroutine.close(thread) end end}
        local function instance(class)
            env.created+=1
            local props={ClassName=class,children={},Destroying=signal(),Activated=signal(),IsLoaded=false,TimeLength=0,TimePosition=0}
            local methods={}
            function methods:FindFirstChild(name) for _,child in ipairs(props.children) do if child.Parent==self and child.Name==name then return child end end end
            function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
            function methods:Play() props.Playing=true;env.plays+=1 end
            function methods:Stop() props.Playing=false end
            function methods:Destroy()
                if props.destroyed then return end;props.destroyed=true;props.Destroying:Fire();props.Parent=nil
                for _,child in ipairs(props.children) do child:Destroy() end
            end
            local object
            object=setmetatable({}, {__index=function(_,key) if methods[key] then return methods[key] end;return props[key] end,
                __newindex=function(_,key,value)
                    props[key]=value
                    if key=='Parent' and value then value.children[#value.children+1]=object end
                    if key=='SoundId' then props.TimeLength=lengths[value:match('(%d+)$')] or 32 end
                end})
            env.nodes[#env.nodes+1]=object
            return object
        end
        local playerGui=instance('PlayerGui');local soundService=instance('SoundService')
        env.created=0
        local services={RunService={IsStudio=function() return options.studio~=false end,
                IsRunning=function() return options.running~=false end,IsClient=function() return options.client~=false end},
            Players={LocalPlayer={WaitForChild=function(_,key) assert(key=='PlayerGui');return playerGui end}},
            SoundService=soundService,UserInputService={TouchEnabled=false,KeyboardEnabled=true,GamepadEnabled=false},
            HttpService={JSONEncode=function() return 'synthetic diagnostic report' end},
            ContentProvider={PreloadAsync=function(_,objects,callback)
                env.calls+=1
                if options.mode=='hang' then coroutine.yield();return end
                local sound=objects[1]
                sound.IsLoaded=options.mode~='not-loaded'
                if options.mode=='bad-duration' then sound.TimeLength=math.huge end
                callback(sound.SoundId,options.mode=='denied' and r.Enum.AssetFetchStatus.Failure or r.Enum.AssetFetchStatus.Success)
            end}}
        local clock=table.clone(os);clock.clock=function() return env.now end
        env.load=luau.load(source,{environment={game={GameId=options.universe or 10771141095,PlaceId=options.place or 117710269155815,
            PlaceVersion=20,GetService=function(_,name) return assert(services[name],name) end},
            Instance={new=instance},Enum=r.Enum,UDim2=r.UDim2,Color3=r.Color3,task=taskApi,os=clock,print=function() end},injectGlobals=true})
        function env:drain(limit)
            local deadline=self.now+(limit or 100)
            while #self.queue>0 do
                table.sort(self.queue,function(a,b) return a.at<b.at end)
                if self.queue[1].at>deadline then break end
                local job=table.remove(self.queue,1)
                if coroutine.status(job.thread)=='dead' then continue end
                local delta=job.at-self.now;self.now=job.at
                local sounds=0
                for _,node in ipairs(self.nodes) do if node.ClassName=='Sound' and node.Parent then
                    sounds+=1
                    if node.Playing and options.mode~='stuck' then node.TimePosition=math.min(node.TimeLength,node.TimePosition+delta) end
                end end
                self.maxSounds=math.max(self.maxSounds,sounds);resume(job.thread)
            end
        end
        function env:live(class)
            local count=0;for _,node in ipairs(self.nodes) do if node.ClassName==class and node.Parent then count+=1 end end;return count
        end
        return env
    end
    for _,options in ipairs({{studio=false},{running=false},{client=false},{universe=10770732078},{place=0}}) do
        local e=environment(options);local ok=pcall(e.load)
        check(not ok and e.created==0 and e.calls==0,'Probe rejects unsafe context before UI or asset requests')
    end
    local e=environment();local api=e.load()
    check(e.calls==0 and e.plays==0,'Owner must initiate the temporary probe')
    api.buttons.Confirm.Activated:Fire()
    check(not api.report.ownerNativeIntendedClipsConfirmed,'Untested clips cannot be confirmed')
    api.startAll();e:drain()
    check(api.report.testedCount==16 and api.report.nativeLoadEligibleCount==16 and api.report.playbackAdvancedCount==16,'All exact slots report successful synthetic loading and progress')
    check(e.calls==16 and e.plays==16 and e.maxSounds==1 and e:live('Sound')==0,'Only one temporary Sound plays at a time; completed sounds are removed')
    check(not api.report.ownerNativeIntendedClipsConfirmed and not api.report.moderationVerifiedByThisProbe and not api.report.gameplayQualityAccepted,'Engine flags do not invent owner/moderation/gameplay acceptance')
    api.buttons.Confirm.Activated:Fire();check(api.report.ownerNativeIntendedClipsConfirmed,'Owner action separately records intended-clip confirmation')
    api.close();check(e:live('Sound')==0 and e:live('ScreenGui')==0 and e:live('Folder')==0,'Close removes only the temporary probe objects')
    for _,mode in ipairs({'denied','not-loaded','bad-duration','stuck','hang'}) do
        local failed=environment({mode=mode});local tool=failed.load();tool.startAll();failed:drain(400)
        check(not tool.report.allSixteenNativeEligible and not tool.report.ownerNativeIntendedClipsConfirmed,'Failure does not turn into native approval: '..mode)
        tool.buttons.Confirm.Activated:Fire();check(not tool.report.ownerNativeIntendedClipsConfirmed,'Cannot confirm incomplete native results: '..mode)
        if mode=='hang' then check(failed.cancelled==16 and failed.plays==0,'Every timed-out preload is cancelled and never played') end
        tool.close();check(failed:live('Sound')==0,'Failed probe cleans its sound: '..mode)
    end
    local cancelled=environment({mode='hang'});local tool=cancelled.load();tool.startAll();tool.close();cancelled:drain(40)
    check(cancelled:live('Sound')==0 and cancelled:live('Folder')==0 and cancelled.plays==0,'Closing during a pending request cancels work and suppresses late playback')
    return assertions
end
