-- Studio server Command Bar during Play; read-only evidence, no game-state changes.
do
    local Run=game:GetService("RunService")
    assert(Run:IsStudio() and Run:IsRunning() and Run:IsServer(),"Run in Studio Server Command Bar during Play.")
    local Http=game:GetService("HttpService")
    local function vec(v) return {v.X,v.Y,v.Z} end
    local function facts(object,keys)
        local out={}
        for _,key in ipairs(keys) do
            local value=object:GetAttribute(key)
            if typeof(value)=="Vector3" then value=vec(value)
            elseif typeof(value)=="CFrame" then value={position=vec(value.Position),forward=vec(value.LookVector)} end
            if type(value)=="table" or type(value)=="number" or type(value)=="boolean" or type(value)=="string" then out[key]=value end
        end
        return out
    end
    task.spawn(function()
        local report={placeId=game.PlaceId,placeVersion=game.PlaceVersion,universeId=game.GameId,
            testedIn="Studio server only",windows={},samples={}}
        for _,p in ipairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and p.Name=="WindowBarrier" and p:GetAttribute("EntryId") then
                report.windows[#report.windows+1]={path=p:GetFullName(),position=vec(p.Position),size=vec(p.Size),
                    collisionGroup=p.CollisionGroup,canCollide=p.CanCollide,
                    entry=facts(p,{"EntryId","EntryRoom","EntryKind","EntrySchema","Approach","Breach","Landing","Inward","AllowedKinds","ClearRadius","ClearWidth","ClearHeight","SillHeight"})}
            end
        end
        for pass=1,3 do
            local rows={}
            for _,m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m:GetAttribute("EnemyId") and #rows<40 then
                    local p=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    local body=m:FindFirstChild("BodyCollider",true)
                    rows[#rows+1]={path=m:GetFullName(),position=p and vec(p.Position),
                        bodyCollides=body and body:IsA("BasePart") and body.CanCollide,
                        facts=facts(m,{"EnemyId","EnemyRunId","EnemyTitle","HP","TraversalStage","TraversalStyle","TraversalHeld","TraversalStageAt","EntrySourceId","EntryCue","EntryCueAt"})}
                end
            end
            report.samples[pass]={serverTime=workspace:GetServerTimeNow(),enemies=rows}
            if pass<3 then task.wait(2.5) end
        end
        print("[DeadSignal Batch1.1 Entry] "..Http:JSONEncode(report))
    end)
end
