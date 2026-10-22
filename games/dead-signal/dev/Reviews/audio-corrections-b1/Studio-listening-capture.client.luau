-- Paste into the CLIENT Command Bar during staging Studio Play.
-- Passive observer: never plays a cue, modifies Config, sends HTTP or publishes.
-- It records observations only. Subjective/native acceptance remains pending.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio(),'Studio Play only')
assert(game.GameId==10771141095,'Open a place in private staging universe 10771141095')
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local HttpService=game:GetService('HttpService')
local player=assert(Players.LocalPlayer,'Use CLIENT Command Bar during Play')
local name='DeadSignalAudioListeningCapture'
local old=player.PlayerGui:FindFirstChild(name);if old then old:Destroy() end
local gui=Instance.new('ScreenGui');gui.Name=name;gui.ResetOnSpawn=false;gui.Parent=player.PlayerGui
local stopButton=Instance.new('TextButton');stopButton.Size=UDim2.fromOffset(230,42);stopButton.Position=UDim2.new(0,12,0,12)
stopButton.Text='Stop audio capture / print report';stopButton.Parent=gui
local report={kind='observed-audio-only',stagingUniverse=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,
    sourceSHA='FILL_EXACT_REVIEWED_BUILD_SHA',startedServerTime=workspace:GetServerTimeNow(),
    nativeQualityAccepted=false,permissionEvidenceAccepted=false,mobileAccepted=false,
    maxOwnedPlaying=0,maxOtherPlaying=0,droppedEvents=0,unwatchedSounds=0,events={}}
local watchers,roots={},{};local running=true;local heartbeat;local alive=0
local banned={['rbxasset://sounds/impact_water.mp3']=true,['rbxasset://sounds/swordslash.wav']=true,
    ['rbxasset://sounds/swordlunge.wav']=true,['rbxasset://sounds/unsheath.wav']=true}
local function owned(sound)
    local p=sound.Parent
    while p do
        if p.Name=='DeadSignalLocalEffects' or p.Name=='DeadSignalAudio' then return true end
        p=p.Parent
    end
    return false
end
local function watch(sound)
    if not sound:IsA('Sound') or watchers[sound] then return end
    if alive>=256 then report.unwatchedSounds+=1;return end
    local links={};watchers[sound]=links;alive+=1
    local function playing()
        if not running or not sound.Playing then return end
        if #report.events>=200 then report.droppedEvents+=1;return end
        report.events[#report.events+1]={serverTime=workspace:GetServerTimeNow(),cue=sound.Name,id=sound.SoundId,
            owner=owned(sound) and 'Effects' or 'outside-Effects',parent=sound.Parent and sound.Parent:GetFullName() or '',
            loaded=sound.IsLoaded,volume=sound.Volume,speed=sound.PlaybackSpeed,loop=sound.Looped,
            prohibitedPhysicalStock=banned[sound.SoundId]==true}
    end
    links[1]=sound:GetPropertyChangedSignal('Playing'):Connect(playing)
    links[2]=sound.Destroying:Connect(function()
        for _,connection in ipairs(links) do connection:Disconnect() end
        if watchers[sound] then watchers[sound]=nil;alive-=1 end
    end)
    playing()
end
for _,root in ipairs({workspace,SoundService}) do
    roots[#roots+1]=root.DescendantAdded:Connect(watch)
    for _,descendant in ipairs(root:GetDescendants()) do watch(descendant) end
end
local elapsed=0
heartbeat=RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0
    local ours,other=0,0
    for sound in pairs(watchers) do if sound.Parent and sound.Playing then
        if owned(sound) then ours+=1 else other+=1 end
    end end
    report.maxOwnedPlaying=math.max(report.maxOwnedPlaying,ours)
    report.maxOtherPlaying=math.max(report.maxOtherPlaying,other)
end)
local function stop()
    if not running then return end;running=false
    heartbeat:Disconnect()
    for _,connection in ipairs(roots) do connection:Disconnect() end
    for _,links in pairs(watchers) do for _,connection in ipairs(links) do connection:Disconnect() end end
    table.clear(watchers);alive=0
    report.endedServerTime=workspace:GetServerTimeNow()
    print('DEAD_SIGNAL_AUDIO_OBSERVATIONS '..HttpService:JSONEncode(report))
    print('Capture stopped. Correlate this report with gameplay video and fill source/device/map/settings. It is not a quality or permission approval.')
    gui:Destroy()
end
stopButton.Activated:Connect(stop);gui.Destroying:Connect(stop)
print('Passive audio capture started: 200 event / 256 live-Sound bounds. Stop to print report. Measure FPS again without this diagnostic UI.')
