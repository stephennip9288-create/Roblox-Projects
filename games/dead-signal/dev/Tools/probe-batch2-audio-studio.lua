-- Open PRIVATE STAGING Dispatch in Studio, press Play, use CLIENT Command Bar.
-- Paste this entire file, then click CHECK ALL 16. No install/save/publish needed.
-- One temporary local Sound at a time; no Config, DataStore, HTTP or place writes.
-- Native evidence only: moderation and existing owner quality approval are separate.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and Run:IsRunning() and Run:IsClient(),'Use the CLIENT Command Bar during Studio Play')
assert(game.GameId==10771141095,'Open PRIVATE STAGING universe 10771141095, not production or a local unsaved place')
local places={[117710269155815]=true,[102403661108879]=true,[125712056058975]=true,[122269451559483]=true}
assert(places[game.PlaceId],'This is not one of the four recorded private-staging places')
local Players=game:GetService('Players')
local Content=game:GetService('ContentProvider')
local SoundService=game:GetService('SoundService')
local Http=game:GetService('HttpService')
local Input=game:GetService('UserInputService')
local player=assert(Players.LocalPlayer,'Client player is not ready')
local playerGui=player:WaitForChild('PlayerGui')
local name='DeadSignalBatch2NativeAudioProbe'
local previous=playerGui:FindFirstChild(name);if previous then previous:Destroy() end
local previousSounds=SoundService:FindFirstChild(name);if previousSounds then previousSounds:Destroy() end
local function make(class,parent,props)
    local object=Instance.new(class)
    for key,value in pairs(props or {}) do object[key]=value end
    object.Parent=parent
    return object
end
local gui=make('ScreenGui',playerGui,{Name=name,ResetOnSpawn=false,DisplayOrder=10000})
local root=make('Frame',gui,{Position=UDim2.fromScale(.06,.08),Size=UDim2.fromScale(.88,.82),
    BackgroundColor3=Color3.fromRGB(16,23,29),BorderSizePixel=0})
local function label(text,y,height)
    return make('TextLabel',root,{Text=text,TextWrapped=true,TextSize=14,Font=Enum.Font.Gotham,
        TextColor3=Color3.fromRGB(230,238,240),BackgroundTransparency=1,
        Position=UDim2.new(0,12,0,y),Size=UDim2.new(1,-24,0,height)})
end
label('BATCH 2 / PRIVATE STAGING / NATIVE AUDIO CHECK',8,26)
label('Existing listening approval is retained. This checks engine loading/playback and intended clip identity. About 45 seconds if all files load. Use headphones at a comfortable volume.',36,48)
local status=label('Ready. Click CHECK ALL 16. Close or Stop Play removes every probe object.',86,42)
local textBox=make('TextBox',root,{Name='Report',Text='',MultiLine=true,ClearTextOnFocus=false,
    TextEditable=false,TextSize=11,Font=Enum.Font.Code,TextColor3=Color3.fromRGB(217,232,232),
    BackgroundColor3=Color3.fromRGB(10,15,19),TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,Position=UDim2.new(0,12,0,218),Size=UDim2.new(1,-24,1,-230)})
local buttons={}
local function button(key,text,x,y)
    local object=make('TextButton',root,{Name=key,Text=text,TextSize=12,TextWrapped=true,Font=Enum.Font.GothamBold,
        TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(39,62,69),BorderSizePixel=0,
        Position=UDim2.new(x,8,0,y),Size=UDim2.new(.32,-10,0,34)})
    buttons[key]=object;return object
end
button('All','CHECK ALL 16',.01,136);button('Next','NEXT CLIP',.34,136);button('Replay','CHECK / REPLAY SELECTED',.67,136)
button('Confirm','CONFIRM INTENDED CLIPS',.01,176);button('Export','EXPORT REPORT',.34,176);button('Close','CLOSE / CLEAN UP',.67,176)
local slots={
    {'Music.Station.Calm','138465772345022',32},{'Music.Station.Pressure','130706797589872',32},
    {'Music.Foundry.Calm','127835878664881',32},{'Music.Foundry.Pressure','136397741479585',32},
    {'Music.Frost.Calm','76339621502898',32},{'Music.Frost.Pressure','76092484114227',32},
    {'Music.Lobby.Calm','78163810591784',32},{'Music.Warden','125448982783761',32},
    {'Music.Extraction','99490559372066',32},{'Atmosphere.Stinger','79202413557343',3},
    {'Atmosphere.Station.Creak','128855928185941',3.312},{'Atmosphere.Foundry.Steam','101059835221623',3.816},
    {'Atmosphere.Foundry.Impact','123384623508546',1.071020408},{'Atmosphere.Cry','124107740668584',4.5},
    {'Zombie.Breath','122477333598212',2.497958333},{'Zombie.Drag','92629845353488',1.999433107},
}
local report={schema=1,kind='dead-signal-b2-native-audio-probe',probeVersion='1',
    studio=true,client=true,universeId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,
    startedAtUTC=os.date('!%Y-%m-%dT%H:%M:%SZ'),
    touchEnabled=Input.TouchEnabled,keyboardEnabled=Input.KeyboardEnabled,gamepadEnabled=Input.GamepadEnabled,
    gameSourceSHA='not attested; this probe runs independently of installed game banks',
    existingSourceListeningApprovalRetained=true,ownerNativeIntendedClipsConfirmed=false,
    moderationVerifiedByThisProbe=false,gameplayQualityAccepted=false,productionAuthorized=false,records={}}
local function empty(slot)
    return {event=slot[1],assetId=slot[2],expectedSeconds=slot[3],tested=false,callbackStatuses={},
        fetchStatus='NotTested',preloadCompleted=false,isLoaded=false,timeLengthSeconds=0,
        durationWithinTolerance=false,nativeLoadEligible=false,playCallSucceeded=false,playbackAdvanced=false}
end
for index,slot in ipairs(slots) do report.records[index]=empty(slot) end
local folder=make('Folder',SoundService,{Name=name})
local active=true;local busy=false;local selected=1;local worker;local preloader;local sound
local function finite(number) return type(number)=='number' and number==number and math.abs(number)<math.huge end
local function stopSound()
    if sound then pcall(function() sound:Stop() end);sound:Destroy();sound=nil end
end
local function summarize()
    local tested,loaded,played=0,0,0
    for _,row in ipairs(report.records) do
        if row.tested then tested+=1 end;if row.nativeLoadEligible then loaded+=1 end;if row.playbackAdvanced then played+=1 end
    end
    report.testedCount=tested;report.nativeLoadEligibleCount=loaded;report.playbackAdvancedCount=played
    report.allSixteenNativeEligible=tested==16 and loaded==16 and played==16
end
local function export()
    summarize();report.probeRunning=busy;report.capturedAtUTC=os.date('!%Y-%m-%dT%H:%M:%SZ')
    local encoded=Http:JSONEncode(report);textBox.Text=encoded
    print('DEAD_SIGNAL_B2_AUDIO_PROBE '..encoded)
    return report
end
local function probe(index)
    selected=index;stopSound()
    local slot=slots[index];local row=empty(slot);report.records[index]=row;row.tested=true
    status.Text=string.format('%d / 16 — %s — preloading (20 second limit)',index,slot[1])
    sound=make('Sound',folder,{Name='Probe',SoundId='rbxassetid://'..slot[2],Volume=0,Looped=false,PlaybackSpeed=1})
    local object=sound;local complete=false;local succeeded=false;local callbacksOpen=true
    preloader=task.spawn(function()
        local ok,err=pcall(function() Content:PreloadAsync({object},function(contentId,fetchStatus)
            if not active or not callbacksOpen then return end
            local state=fetchStatus and fetchStatus.Name or 'Unknown'
            if #row.callbackStatuses<8 then row.callbackStatuses[#row.callbackStatuses+1]={contentId=tostring(contentId),status=state} end
            row.fetchStatus=state;succeeded=fetchStatus==Enum.AssetFetchStatus.Success
        end) end)
        row.preloadCompleted=ok;complete=true
        if not ok then row.preloadError=tostring(err) end
    end)
    local deadline=os.clock()+20
    while active and not complete and os.clock()<deadline do task.wait(.1) end
    callbacksOpen=false
    if not active then return end
    if not complete then
        row.fetchStatus='ProbeTimedOut';pcall(task.cancel,preloader)
    end
    preloader=nil;row.isLoaded=object.IsLoaded==true
    local seconds=object.TimeLength;row.timeLengthSeconds=finite(seconds) and seconds or 0
    row.durationWithinTolerance=finite(seconds) and seconds>0 and math.abs(seconds-slot[3])<=math.max(.1,slot[3]*.03)
    row.nativeLoadEligible=complete and row.preloadCompleted and succeeded and row.isLoaded and row.durationWithinTolerance
    if row.nativeLoadEligible then
        object.Volume=.35;object.TimePosition=0
        local ok,err=pcall(function() object:Play() end);row.playCallSucceeded=ok
        if not ok then row.playError=tostring(err) end
        status.Text=string.format('%d / 16 — %s — native playback',index,slot[1])
        if ok then
            task.wait(math.min(2.5,math.max(.5,seconds*.75)))
            if not active then return end
            local at=object.TimePosition;row.observedTimePosition=finite(at) and at or 0
            row.playbackAdvanced=finite(at) and at>.05
        end
    end
    stopSound();summarize()
end
local function start(all)
    if not active or busy then return end
    busy=true;report.ownerNativeIntendedClipsConfirmed=false;report.probeError=nil
    worker=task.spawn(function()
        local ok,err=pcall(function()
            if all then for index=1,#slots do if not active then break end;probe(index) end else probe(selected) end
        end)
        stopSound();busy=false
        if not active then return end
        summarize()
        status.Text=ok and string.format('Finished: %d/16 loaded; %d/16 playback advanced. Confirm intended clips only if heard; EXPORT REPORT.',report.nativeLoadEligibleCount,report.playbackAdvancedCount) or 'Probe error: '..tostring(err)
        if not ok then report.probeError=tostring(err) end
        export()
    end)
end
local function cleanup()
    if not active then return end;active=false
    if preloader then pcall(task.cancel,preloader);preloader=nil end
    if worker then pcall(task.cancel,worker);worker=nil end
    stopSound();folder:Destroy()
end
local function close() if not active then return end;export();cleanup();gui:Destroy() end
gui.Destroying:Connect(cleanup)
buttons.All.Activated:Connect(function() start(true) end)
buttons.Replay.Activated:Connect(function() start(false) end)
buttons.Next.Activated:Connect(function() if not busy then selected=selected%#slots+1;status.Text=slots[selected][1]..' / '..slots[selected][2] end end)
buttons.Confirm.Activated:Connect(function()
    summarize()
    if busy or not report.allSixteenNativeEligible then status.Text='All sixteen native checks must pass before intended-clip confirmation.';return end
    report.ownerNativeIntendedClipsConfirmed=true;status.Text='Owner confirms native playback matched the intended clips. Latest report exported; game/native quality QA remains separate.';export()
end)
buttons.Export.Activated:Connect(export);buttons.Close.Activated:Connect(close)
task.delay(600,close)
return {report=report,startAll=function() start(true) end,startSelected=function() start(false) end,
    export=export,close=close,buttons=buttons}
