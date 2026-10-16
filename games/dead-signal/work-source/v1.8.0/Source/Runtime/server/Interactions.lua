local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local I={} I.__index=I
function I.new(ctx) return setmetatable({ctx=ctx,items={},holds={},nextId=0},I) end
function I:eligible(player,item)
    local state=self.ctx.players[player] local root=U.root(player)
    if not state or not root or not item.part.Parent or not item.prompt.Enabled then return false end
    if item.lobby then if state.status~="Lobby" then return false end
    elseif state.status~="Alive" or not state.participating then return false end
    if (root.Position-item.part.Position).Magnitude>item.prompt.MaxActivationDistance+2 then return false end
    if not item.lobby and self.ctx.map and not item.allowWall then
        local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={self.ctx.map.model}
        local hit=workspace:Raycast(root.Position,item.part.Position-root.Position,params)
        if hit and hit.Instance~=item.part and not hit.Instance:IsDescendantOf(item.part) and (hit.Position-item.part.Position).Magnitude>3 then return false end
    end
    return true
end
function I:bind(part,title,action,hold,callback,options)
    options=options or {} self.nextId=self.nextId+1
    local prompt=U.make("ProximityPrompt",part,{Name="Use",ObjectText=title,ActionText=action,HoldDuration=hold or 0,
        MaxActivationDistance=options.distance or 10,RequiresLineOfSight=false,
        KeyboardKeyCode=Enum.KeyCode.E,GamepadKeyCode=Enum.KeyCode.ButtonX,Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton})
    local item={part=part,prompt=prompt,callback=callback,hold=hold or 0,lobby=options.lobby,allowWall=options.allowWall,required=options.required}
    self.items[prompt]=item
    prompt.PromptButtonHoldBegan:Connect(function(player)
        if self:eligible(player,item) then self.holds[player]={item=item,start=os.clock(),position=U.root(player).Position} end
    end)
    prompt.PromptButtonHoldEnded:Connect(function(player)
        local old=self.holds[player]
        task.delay(.25,function() if self.holds[player]==old then self.holds[player]=nil end end)
    end)
    prompt.Triggered:Connect(function(player)
        if not self:eligible(player,item) then return end
        local required=item.required and item.required(player) or item.hold
        if required>0 then
            local h=self.holds[player]
            if not h or h.item~=item or os.clock()-h.start<required-.15 then return end
        end
        self.holds[player]=nil
        local state=self.ctx.players[player]
        if os.clock()<(state.nextInteract or 0) then return end
        state.nextInteract=os.clock()+.25
        callback(player,state,prompt)
    end)
    return prompt
end
function I:tick()
    for player,h in pairs(self.holds) do
        local root=U.root(player)
        if not root or not self:eligible(player,h.item) or (root.Position-h.position).Magnitude>3.5 then self.holds[player]=nil end
    end
end
function I:cancel(player) self.holds[player]=nil end
function I:clearMap()
    for prompt,item in pairs(self.items) do if not item.lobby then self.items[prompt]=nil end end
    self.holds={}
end
return I
