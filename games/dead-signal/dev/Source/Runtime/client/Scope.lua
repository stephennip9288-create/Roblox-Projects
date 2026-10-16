-- Wide circular aperture, drawn with GUI masks; no external image asset is required.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local S={} S.__index=S
function S.new(gui)
    local self=setmetatable({strips={},size=Vector2.new(0,0)},S)
    self.gui=U.make("ScreenGui",gui.Parent,{Name="DeadSignalOptic",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.None,IgnoreGuiInset=true,ClipToDeviceSafeArea=false,DisplayOrder=gui.DisplayOrder-1,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    self.frame=U.make("Frame",self.gui,{Name="OpticView",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ZIndex=2})
    local function mask() return U.make("Frame",self.frame,{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=2}) end
    self.top=mask() self.bottom=mask()
    for i=1,96 do self.strips[i]={mask(),mask()} end
    self.reticle={}
    for _,v in ipairs({{-1,-65,2,55},{-1,10,2,55},{-65,-1,55,2},{10,-1,55,2}}) do
        table.insert(self.reticle,U.make("Frame",self.frame,{Size=UDim2.fromOffset(v[3],v[4]),Position=UDim2.new(.5,v[1],.5,v[2]),
            BackgroundColor3=Color3.fromRGB(29,32,28),BorderSizePixel=0,ZIndex=3}))
    end
    U.make("Frame",self.frame,{Name="ZeroPoint",Size=UDim2.fromOffset(2,2),Position=UDim2.new(.5,-1,.5,-1),BackgroundColor3=Color3.fromRGB(201,74,48),BorderSizePixel=0,ZIndex=3})
    return self
end
function S:update(enabled,viewport)
    self.frame.Visible=enabled
    if not enabled or (self.size.X==viewport.X and self.size.Y==viewport.Y) then return end
    self.size=viewport local w,h=viewport.X,viewport.Y
    -- The aperture occupies 92% of the shorter screen dimension, including mobile.
    local radius=math.min(w,h)*.46 local y0=h/2-radius local rows=#self.strips local dy=radius*2/rows
    self.top.Position=UDim2.fromOffset(0,0) self.top.Size=UDim2.fromOffset(w,math.ceil(y0))
    self.bottom.Position=UDim2.fromOffset(0,math.floor(h/2+radius)) self.bottom.Size=UDim2.fromOffset(w,math.ceil(y0)+1)
    for i,pair in ipairs(self.strips) do
        local y=-radius+(i-.5)*dy local half=math.sqrt(math.max(0,radius*radius-y*y)) local edge=w/2-half
        pair[1].Position=UDim2.fromOffset(0,math.floor(y0+(i-1)*dy)) pair[1].Size=UDim2.fromOffset(math.ceil(edge),math.ceil(dy)+1)
        pair[2].Position=UDim2.fromOffset(math.floor(w-edge),math.floor(y0+(i-1)*dy)) pair[2].Size=UDim2.fromOffset(math.ceil(edge)+1,math.ceil(dy)+1)
    end
end
return S
