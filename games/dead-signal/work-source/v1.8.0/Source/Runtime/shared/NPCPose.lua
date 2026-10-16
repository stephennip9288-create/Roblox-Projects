-- Negative Z is forward for every species. Shared by client motion and death-pose capture.
local P={}
function P.transforms(kind,phase,speed,attack)
    local out={} local move=math.clamp(speed/5,0,1) local s=math.sin(phase)*move local c=math.cos(phase)*move
    local hound=kind=="Hound" local crawler=kind=="Crawler"
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
            out[name.." Shoulder"]=CFrame.Angles(.60-step*.25+attack*.80,0,side*.08)
            out[name.." Elbow"]=CFrame.Angles(.35+math.max(0,-step)*.30+attack*.35,0,0)
            out[name.." Wrist"]=CFrame.Angles(-.08,0,side*.04)
            out[name.." Hip"]=CFrame.Angles(step*.48,0,side*.025)
            out[name.." Knee"]=CFrame.Angles(-math.max(0,-step)*.66-.03,0,0)
            out[name.." Ankle"]=CFrame.Angles(-step*.15,0,0)
        end
    end
    out.Neck=CFrame.Angles(hound and -.02+attack*.10 or crawler and -.08 or -.06+attack*.12,math.sin(phase*.23)*.055,0)
    out.RootJoint=CFrame.new(0,math.abs(c)*(hound and .06 or crawler and .025 or .055),-attack*.10)*CFrame.Angles(hound and c*.035 or crawler and 0 or .075,0,c*.015)
    for n=1,3 do out["Tail"..n.."Joint"]=CFrame.Angles(0,math.sin(phase*.5-n*.3)*.10,0) end
    return out
end
function P.sample(model,root,time)
    local v=root.AssemblyLinearVelocity local speed=Vector3.new(v.X,0,v.Z).Magnitude
    local kind=model:GetAttribute("EnemyType") local seed=model:GetAttribute("PoseSeed") or 0
    local phase=time*(kind=="Hound" and 10.5 or kind=="Crawler" and 4.8 or 6.5)+seed
    local attack=math.max(0,1-(time-(model:GetAttribute("AttackAt") or -100))/.65)
    return P.transforms(kind,phase,speed,attack)
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
