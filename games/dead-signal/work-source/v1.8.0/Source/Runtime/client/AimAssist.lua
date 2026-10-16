local Players=game:GetService("Players")
local A={}
function A.visible(camera,head,model)
    local folder=workspace:FindFirstChild("DeadSignalEnemies") local map=workspace:FindFirstChild("DeadSignalMap")
    if not folder or not map then return false end
    local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={folder,map} p.CollisionGroup="DeadSignalShots"
    local hit=workspace:Raycast(camera.CFrame.Position,head.Position-camera.CFrame.Position,p)
    return hit~=nil and hit.Instance:IsDescendantOf(model)
end
function A.target(camera,preset,range)
    if preset=="Advanced" then return nil end
    local folder=workspace:FindFirstChild("DeadSignalEnemies") if not folder then return nil end
    local best,dot=nil,math.cos(math.rad(preset=="Assisted" and 3.5 or 2))
    for _,model in ipairs(folder:GetChildren()) do
        local head=model:FindFirstChild("Head")
        if head and (model:GetAttribute("HP") or 0)>0 then
            local delta=head.Position-camera.CFrame.Position
            if delta.Magnitude>.1 and delta.Magnitude<math.min(range or 110,110) then
                local score=camera.CFrame.LookVector:Dot(delta.Unit)
                if score>dot and A.visible(camera,head,model) then best=head dot=score end
            end
        end
    end
    return best
end
function A.autoEligible(camera,range)
    local folder=workspace:FindFirstChild("DeadSignalEnemies") local map=workspace:FindFirstChild("DeadSignalMap")
    if not folder or not map then return false end
    local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={folder,map} p.CollisionGroup="DeadSignalShots"
    local hit=workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector*math.min(range or 100,110),p)
    local model=hit and hit.Instance:FindFirstAncestorOfClass("Model")
    return model~=nil and model.Parent==folder and (model:GetAttribute("HP") or 0)>0
end
return A
