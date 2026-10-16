local U = {}
function U.color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
function U.copy(t)
    local out = {}
    for k,v in pairs(t) do out[k] = type(v) == "table" and U.copy(v) or v end
    return out
end
function U.root(player) return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
function U.humanoid(player) return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
function U.finiteVector(v)
    return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 100000 and math.abs(v.Y) < 100000 and math.abs(v.Z) < 100000
end
function U.make(class, parent, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
function U.count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
function U.round(n) return math.floor(n + 0.5) end
return U
