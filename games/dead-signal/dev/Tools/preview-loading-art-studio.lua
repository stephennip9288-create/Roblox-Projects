-- Dead Signal: inspect the game's ACTUAL loading screen, held open in Studio.
-- Press Play, switch Command Bar to CLIENT, paste this entire file, then run.
-- Run from Dispatch before starting an operation; this does not pause a round.
-- Use the four buttons to inspect Dispatch and all three original map pictures.
-- CLOSE or Stop Play removes the preview; it also closes after two minutes.
-- Only a temporary local GUI is created. No source, assets, saves, or places change.
-- This verifies Studio rendering, not published-game asset access or teleports.
do
    local Run=game:GetService("RunService")
    assert(Run:IsStudio() and Run:IsRunning() and Run:IsClient(),
        "Press Play, switch Command Bar to Client, then run the preview.")
    local Players=game:GetService("Players")
    local RS=game:GetService("ReplicatedStorage")
    local Http=game:GetService("HttpService")
    local folder=RS:FindFirstChild("DeadSignal")
    local module=folder and folder:FindFirstChild("LoadingScreen")
    assert(module and module:IsA("ModuleScript"), "DeadSignal.LoadingScreen was not found.")
    local Loading=require(module)
    local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
    local old=playerGui:FindFirstChild("DeadSignalArtworkPreview")
    if old then old:Destroy() end
    local function make(class,parent,props)
        local object=Instance.new(class)
        for key,value in pairs(props) do object[key]=value end
        object.Parent=parent
        return object
    end
    local gui=make("ScreenGui",playerGui,{Name="DeadSignalArtworkPreview"})
    local screen=Loading.new(gui)
    gui.DisplayOrder=10000
    local controls=make("Frame",gui,{Name="PreviewControls",Position=UDim2.fromScale(.02,.015),
        Size=UDim2.new(.96,0,0,90),BackgroundTransparency=1,ZIndex=200})
    local note=make("TextLabel",controls,{Name="PreviewStatus",Position=UDim2.new(0,0,0,46),
        Size=UDim2.new(1,0,0,42),BackgroundColor3=Color3.fromRGB(15,21,28),BackgroundTransparency=.1,
        BorderSizePixel=0,Text="",TextSize=14,TextWrapped=true,Font=Enum.Font.Gotham,
        TextColor3=Color3.fromRGB(236,240,244),ZIndex=201})
    local generation=0
    local function show(map)
        generation+=1 local expected=generation
        -- No synthetic image probe: construct and select the same module used by UI.
        screen:set(map,"Studio preview / select a map above",true)
        note.Text=map.." / "..screen.image.Image.." / loading; see Output in 5 seconds"
        for _,seconds in ipairs({1,5}) do
            task.delay(seconds,function()
                if not gui.Parent or generation~=expected then return end
                local loaded=screen.image.IsLoaded
                note.Text=map.." / "..screen.image.Image.." / "..(loaded and "IMAGE LOADED" or "NOT LOADED YET").." / Studio preview only"
                print("[DeadSignal Loading Preview] "..Http:JSONEncode({
                    map=map,image=screen.image.Image,imageIsLoaded=loaded,
                    imageVisible=screen.image.Visible,screenVisible=screen.frame.Visible,
                    viewport={screen.image.AbsoluteSize.X,screen.image.AbsoluteSize.Y},
                    elapsedSeconds=seconds,placeId=game.PlaceId,universeId=game.GameId,
                    testedIn="Studio client / actual LoadingScreen module",publishedPermissionTest=false,
                }))
            end)
        end
    end
    local maps={{"Lobby","DISPATCH"},{"Station","BLACKWATER"},{"Foundry","CINDERWORKS"},{"Frost","WHITEOUT"}}
    for index,entry in ipairs(maps) do
        local button=make("TextButton",controls,{Name="Show"..entry[1],Text=entry[2],
            Position=UDim2.fromScale((index-1)*.2,0),Size=UDim2.new(.19,0,0,40),
            BackgroundColor3=Color3.fromRGB(39,58,69),BorderSizePixel=0,
            TextColor3=Color3.new(1,1,1),TextSize=12,TextWrapped=true,Font=Enum.Font.GothamBold,ZIndex=202})
        local map=entry[1]
        button.Activated:Connect(function() if gui.Parent then show(map) end end)
    end
    local close=make("TextButton",controls,{Name="ClosePreview",Text="CLOSE",
        Position=UDim2.fromScale(.8,0),Size=UDim2.new(.2,0,0,40),
        BackgroundColor3=Color3.fromRGB(92,43,40),BorderSizePixel=0,
        TextColor3=Color3.new(1,1,1),TextSize=14,Font=Enum.Font.GothamBold,ZIndex=202})
    close.Activated:Connect(function() gui:Destroy() end)
    task.delay(120,function() if gui.Parent then gui:Destroy() end end)
    show("Lobby")
end
