-- Negative Z is forward for every species. Shared by client motion and death-pose capture.
local P={}
function P.transforms(kind,phase,speed,attack,seed)
    local out={} local move=math.clamp(speed/5,0,1) local s=math.sin(phase)*move local c=math.cos(phase)*move
    local hound=kind=="Hound" local crawler=kind=="Crawler"
    local asym=math.sin((seed or 0)*1.37)
    local dragging=kind=="Shambler" or kind=="Warden"
    for _,side in ipairs({-1,1}) do
        local name=side==1 and "Right" or "Left" local step=s*side
        if hound then
            out[name.." Shoulder"]=CFrame.Angles(step*.28-attack*.15,0,0)
            out[name.." Elbow"]=CFrame.Angles(-math.max(0,-step)*.85-.12,0,0)
            out[name.." Wrist"]=CFrame.Angles(math.max(0,-step)*.3,0,0)
            out[name.." Hip"]=CFrame.Angles(-step*.24,0,0)
            out[name.." Knee"]=CFrame.Angles(math.max(0,step)*.80,0,0)
            out[name.." Ankle"]=CFrame.Angles(-math.max(0,step)*.35,0,0)
        elseif crawler then
            out[name.." Shoulder"]=CFrame.Angles(step*.10-attack*.20,step*.15,side*(.10+step*.14))
            out[name.." Elbow"]=CFrame.Angles(-.20-math.max(0,step)*.35,0,side*math.max(0,-step)*.12)
            out[name.." Wrist"]=CFrame.Angles(.13,0,0)
            out[name.." Hip"]=CFrame.Angles(0,step*.10,side*.09)
            out[name.." Knee"]=CFrame.Angles(0,step*.06,0)
        else
            local lag=math.sin(phase+(side==1 and .28+asym*.12 or 0))*move*side
            out[name.." Shoulder"]=CFrame.Angles(.22+side*asym*.12-lag*(dragging and .11 or .32)+attack*1.05,side*.025,side*.055)
            out[name.." Elbow"]=CFrame.Angles(.20+(side==1 and .24 or .05)+math.max(0,-lag)*.18-attack*.12,0,side*.04)
            out[name.." Wrist"]=CFrame.Angles(-.18-side*asym*.10-attack*.08,0,side*.10)
            out[name.." Hip"]=CFrame.Angles(lag*(dragging and .31 or .52)*(side==1 and .82 or 1),0,side*.018)
            out[name.." Knee"]=CFrame.Angles(-math.max(0,-lag)*(dragging and .42 or .76)-.025,0,0)
            out[name.." Ankle"]=CFrame.Angles(-lag*.14,0,0)
        end
    end
    out.Neck=CFrame.Angles(hound and -.02+attack*.10 or crawler and -.08 or -.13-attack*.10,math.sin(phase*.23)*.055,not hound and not crawler and asym*.055 or 0)
    out.RootJoint=CFrame.new(0,math.abs(c)*(hound and .06 or crawler and .025 or .055),-attack*.10)*CFrame.Angles(hound and c*.035 or crawler and 0 or -.12-attack*.13,0,c*.015+(not hound and not crawler and asym*.022 or 0))
    for n=1,3 do out["Tail"..n.."Joint"]=CFrame.Angles(0,math.sin(phase*.5-n*.3)*.10,0) end
    if hound then
        out.Jaw=CFrame.Angles(.08+attack*.36,0,0)
        out["Right Ear"]=CFrame.Angles(-attack*.4,0,-.05)
        out["Left Ear"]=CFrame.Angles(-attack*.35,0,.05)
    end
    return out
end
function P.traversal(kind,style,stage,phase)
    local out={} local wave=math.sin(math.clamp(phase,0,1)*math.pi)
    if stage=="Approach" or stage=="Waiting" or stage=="Pursuit" then return out end
    local cross=stage=="Cross" local contact=stage=="Contact" local landing=stage=="Land" or stage=="Settle"
    if style=="Walk" then return out end
    if kind=="Hound" then
        out.RootJoint=CFrame.new(0,landing and -.12*(1-phase) or contact and -.11*wave or 0,0)*CFrame.Angles(cross and -.16 or contact and .12 or .06,0,0)
        for _,side in ipairs({"Left","Right"}) do
            out[side.." Shoulder"]=CFrame.Angles(cross and .65-wave*.6 or contact and -.35 or -.20*(1-phase),0,0)
            out[side.." Elbow"]=CFrame.Angles(cross and -.65*wave or -.25,0,0)
            out[side.." Hip"]=CFrame.Angles(cross and -.5+phase*.9 or contact and .4 or .2*(1-phase),0,0)
            out[side.." Knee"]=CFrame.Angles(cross and .65*wave or contact and .5 or .1,0,0)
            out[side.." Ear"]=CFrame.Angles(-.35,0,side=="Left" and .1 or -.1)
        end
        out.Neck=CFrame.Angles(cross and .12 or -.08,0,0);out.Jaw=CFrame.Angles(.08,0,0)
    elseif style=="Crawl" then
        out.RootJoint=CFrame.new(0,-.06*wave,-.10*wave)
        for _,side in ipairs({-1,1}) do local name=side==1 and "Right" or "Left"
            out[name.." Shoulder"]=CFrame.Angles(.15-wave*.12,side*wave*.18,side*.18)
            out[name.." Elbow"]=CFrame.Angles(-.4-wave*.3,0,0)
            out[name.." Hip"]=CFrame.Angles(-.08,side*.05,side*.10)
        end
    else
        out.RootJoint=CFrame.new(0,cross and -.18*wave or landing and -.12*(1-phase) or 0,cross and -.10 or 0)*CFrame.Angles(cross and -.45 or contact and -.20 or -.08,0,0)
        for _,side in ipairs({-1,1}) do local name=side==1 and "Right" or "Left"
            out[name.." Shoulder"]=CFrame.Angles(contact and (side==1 and .95 or 1.10) or cross and (side==1 and 1.12 or .97)-phase*.52 or .32,0,side*.12)
            out[name.." Elbow"]=CFrame.Angles(cross and -.55 or -.20,0,0)
            out[name.." Hip"]=CFrame.Angles(cross and (side==1 and .6 or .25)*wave or -.1,0,0)
            out[name.." Knee"]=CFrame.Angles(cross and -1.1*wave or -.15,0,0)
        end
        out.Neck=CFrame.Angles(-.10,0,0)
    end
    return out
end
function P.sample(model,root,time)
    local v=root.AssemblyLinearVelocity local speed=Vector3.new(v.X,0,v.Z).Magnitude
    local kind=model:GetAttribute("EnemyType") local seed=model:GetAttribute("PoseSeed") or 0
    local charging=time<(model:GetAttribute("ChargeUntil") or 0)
    local stage=model:GetAttribute("TraversalStage") local traversal=stage and stage~="Pursuit" and stage~="Waiting"
    if stage=="Approach" or stage=="Retreat" or traversal and model:GetAttribute("TraversalStyle")=="Walk" then speed=model:GetAttribute("TraversalSpeed") or 8 end
    local phase=time*(kind=="Hound" and (charging and 14 or 10.5) or kind=="Crawler" and 4.8 or kind=="Stalker" and 7.8 or kind=="Runner" and 9.1 or 5.4)*(model:GetAttribute("Enraged") and 1.25 or 1)+seed
    local age=time-(model:GetAttribute("AttackAt") or -100)
    local windup=kind=="Hound" and .32 or kind=="Stalker" and .6 or kind=="Warden" and .65 or .45
    local attack=age<0 and 0 or age<windup and (age/windup)^2*.55 or age<windup+.10 and .55+(age-windup)/.10*.45
        or math.max(0,1-(age-windup-.10)/.28)
    if traversal then attack=0 end
    local out=P.transforms(kind,phase,speed,attack*(model:GetAttribute("Enraged") and 1.25 or 1),seed)
    if traversal then
        local u=model:GetAttribute("TraversalHeld") and (model:GetAttribute("TraversalHoldPhase") or 0)
            or math.clamp((time-(model:GetAttribute("TraversalStageAt") or time))*(model:GetAttribute("TraversalDirection") or 1)/math.max(.01,model:GetAttribute("TraversalStageDuration") or 1),0,1)
        for key,pose in pairs(P.traversal(kind,model:GetAttribute("TraversalStyle"),stage,u)) do out[key]=pose end
    end
    if kind=="Stalker" and not traversal then out.RootJoint=out.RootJoint*CFrame.Angles(.2,0,0);out.Neck=CFrame.Angles(-.18,0,math.sin(time*2)*.06) end
    if charging then out.RootJoint=out.RootJoint*CFrame.Angles(-.08,0,0) end
    local hitAge=time-(model:GetAttribute("HitAt") or -100)
    local force=model:GetAttribute("HitVector")
    if not traversal and hitAge>=0 and hitAge<.30 and typeof(force)=="Vector3" then
        local direction=root.CFrame:VectorToObjectSpace(force)
        local strength=math.clamp(model:GetAttribute("HitStrength") or .2,0,.75)*math.sin(hitAge/.30*math.pi)
        out.RootJoint=out.RootJoint*CFrame.Angles(-direction.Z*.22*strength,0,-direction.X*.22*strength)
        if model:GetAttribute("HitHead") then out.Neck=out.Neck*CFrame.Angles(-direction.Z*.24*strength,direction.X*.20*strength,0) end
    end
    if not traversal and time<(model:GetAttribute("StunnedUntil") or 0) then
        out.RootJoint=CFrame.Angles(.18,0,.08);out.Neck=CFrame.Angles(-.2,0,0)
    end
    return out
end
-- Pure root-local skeleton evaluation for geometry audits and server sweeps.
-- No live joints, hitboxes or meshes are moved by this function.
function P.frames(model,poses)
    local root=model:FindFirstChild("HumanoidRootPart")
    local frames={[root]=CFrame.identity} local pending={}
    for _,j in ipairs(model:GetDescendants()) do
        if j:IsA("Motor6D") and j.Part0 and j.Part1 then pending[#pending+1]=j end
    end
    for _=1,#pending do
        local progress=false
        for _,j in ipairs(pending) do if not frames[j.Part1] and frames[j.Part0] then
            frames[j.Part1]=frames[j.Part0]*(j:GetAttribute("RestC0") or j.C0)*(poses[j.Name] or CFrame.identity)*j.C1:Inverse()
            progress=true
        end end
        if not progress then break end
    end
    return frames
end
function P.capture(model,time)
    local root=model:FindFirstChild("HumanoidRootPart") if not root then return end
    local poses=P.sample(model,root,time) local pending={}
    for _,j in ipairs(model:GetDescendants()) do if j:IsA("Motor6D") and j.Part0 and j.Part1 then pending[#pending+1]=j end end
    local ready={[root]=true}
    for _=1,#pending do
        for _,j in ipairs(pending) do if not ready[j.Part1] and ready[j.Part0] then
            local rest=j:GetAttribute("RestC0") or j.C0
            j.C0=rest*(poses[j.Name] or CFrame.identity) j.Transform=CFrame.identity
            j.Part1.CFrame=j.Part0.CFrame*j.C0*j.C1:Inverse() ready[j.Part1]=true
        end end
    end
    -- Welded art follows the new skeleton in the engine; the Motor joint frames are now exact.
end
return P
