-- Engine doubles only; no asset approval, native playback or device claim.
local fs=require('@lune/fs') local luau=require('@lune/luau') local r=require('@lune/roblox')
local candidate=fs.readFile('Source/Runtime/client/Effects.lua')
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
local function setup(low,override,candidateOverride)
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
    local config=override or {DefaultSettings=settings,SoundIds={},Evolution={audio={}},Weapons={Kestrel={class='Pistol'},Trench={class='Shotgun'},Anchor={class='Heavy'}}}
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
    local FX=luau.load(candidateOverride or candidate,{debugName='AudioRuntimeUnderTest',environment={
        game={GetService=function(_,name) return services[name] end},workspace=world,
        require=function(key) if key=='Config' then return config elseif key=='Util' then return util else return {} end end,
        Vector3=r.Vector3,Enum=r.Enum,os=clock,typeof=typeof,task=scheduler,RaycastParams={new=function() return {} end},
    },injectGlobals=true})()
    env.fx=FX.new();env.fx.settings.lowEffects=low==true;env.config=config;env.world=world;env.service=soundService;env.FX=FX;env.node=node
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
return setup
