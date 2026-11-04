-- Offline continuous AABB/OBB SAT against generated colliders. Wedges use a
-- conservative box for sweeps and their exact convex shape for support rays.
-- This is source-geometry evidence, not Roblox physics/navmesh evidence.
local r=require('@lune/roblox') local V=r.Vector3
local G={} local axes={V.xAxis,V.yAxis,V.zAxis}
local function extent(axis,basis,half)
 return math.abs(axis:Dot(basis[1]))*half.X+math.abs(axis:Dot(basis[2]))*half.Y+math.abs(axis:Dot(basis[3]))*half.Z
end
local function box(part)
 local basis={part.CFrame.RightVector,part.CFrame.UpVector,-part.CFrame.LookVector}
 local out={part=part,center=part.CFrame.Position,half=part.Size*.5,basis=basis,axes={}}
 out.enemyCollide=part.CollisionGroup~='DeadSignalBounds' and part.CollisionGroup~='DeadSignalCorpses'
 out.extent=V.new(extent(axes[1],basis,out.half),extent(axes[2],basis,out.half),extent(axes[3],basis,out.half))
 local lo,hi=out.center-out.extent,out.center+out.extent
 out.xmin=lo.X;out.xmax=hi.X;out.ymin=lo.Y;out.ymax=hi.Y;out.zmin=lo.Z;out.zmax=hi.Z
 local function add(axis)
  if axis.Magnitude<1e-6 then return end
  axis=axis.Unit;out.axes[#out.axes+1]={axis=axis,radius=extent(axis,basis,out.half)}
 end
 for _,axis in ipairs(axes) do add(axis) end
 for _,axis in ipairs(basis) do add(axis) end
 for _,a in ipairs(axes) do for _,b in ipairs(basis) do add(a:Cross(b)) end end
 return out
end
local function bounds(center,half,delta)
 local start,finish=center-half,center+half
 local low=V.new(math.min(start.X,start.X+delta.X),math.min(start.Y,start.Y+delta.Y),math.min(start.Z,start.Z+delta.Z))
 local high=V.new(math.max(finish.X,finish.X+delta.X),math.max(finish.Y,finish.Y+delta.Y),math.max(finish.Z,finish.Z+delta.Z))
 return low.X,high.X,low.Y,high.Y,low.Z,high.Z
end
local function sweep(shape,center,half,delta)
 local enter,leave=0,1
 for _,test in ipairs(shape.axes) do
  local a=test.axis;local radius=test.radius+math.abs(a.X)*half.X+math.abs(a.Y)*half.Y+math.abs(a.Z)*half.Z-1e-5
  local distance=(center-shape.center):Dot(a);local speed=delta:Dot(a)
  if math.abs(speed)<1e-8 then if math.abs(distance)>=radius then return nil end
  else
   local p,q=(-radius-distance)/speed,(radius-distance)/speed;if p>q then p,q=q,p end
   enter=math.max(enter,p);leave=math.min(leave,q);if enter>leave then return nil end
  end
 end
 return enter
end
local function included(part,params)
 local matched=false
 for _,p in ipairs(params.FilterDescendantsInstances or {}) do if part==p or part:IsDescendantOf(p) then matched=true;break end end
 return params.FilterType==r.Enum.RaycastFilterType.Include and matched or params.FilterType~=r.Enum.RaycastFilterType.Include and not matched
end
local function ray(part,origin,direction)
 local p=part.CFrame:PointToObjectSpace(origin);local v=part.CFrame:VectorToObjectSpace(direction);local h=part.Size*.5
 local planes={{V.xAxis,h.X},{-V.xAxis,h.X},{V.yAxis,h.Y},{-V.yAxis,h.Y},{V.zAxis,h.Z},{-V.zAxis,h.Z}}
 if part:IsA('WedgePart') then planes[#planes+1]={V.new(0,1/h.Y,-1/h.Z),0} end
 local enter,leave=0,1
 for _,plane in ipairs(planes) do
  local distance=p:Dot(plane[1])-plane[2];local speed=v:Dot(plane[1])
  if math.abs(speed)<1e-8 then if distance>1e-6 then return nil end
  elseif speed<0 then enter=math.max(enter,-distance/speed)
  else leave=math.min(leave,-distance/speed) end
  if enter>leave then return nil end
 end
 return enter
end
function G.world(map)
 local shapes={} local g={probes=0,lastBlock=nil}
 for _,p in ipairs(map.model:GetDescendants()) do if p:IsA('BasePart') and p.CanCollide then shapes[#shapes+1]=box(p) end end
 g.shapes=shapes
 local function eligible(p,params)
  -- Exact Enemy/Bounds and Enemy/Corpses policies in CollisionPolicy.lua.
  return p.CanCollide and included(p,params)
 end
 function g:Blockcast(cf,size,delta,params)
  self.probes+=1
  local center,half=cf.Position,size*.5
  local x0,x1,y0,y1,z0,z1=bounds(center,half,delta)
  for _,shape in ipairs(shapes) do if shape.enemyCollide and x0<shape.xmax and x1>shape.xmin and y0<shape.ymax and y1>shape.ymin and z0<shape.zmax and z1>shape.zmin and eligible(shape.part,params) then
   local t=sweep(shape,center,half,delta)
   if t then self.lastBlock=shape.part;return {Instance=shape.part,Position=cf.Position+delta*t} end
  end end
 end
 function g:GetPartBoundsInBox(cf,size,params)
  local hits={}
  local center,half=cf.Position,size*.5
  local x0,x1,y0,y1,z0,z1=bounds(center,half,V.zero)
  for _,shape in ipairs(shapes) do if shape.enemyCollide and x0<shape.xmax and x1>shape.xmin and y0<shape.ymax and y1>shape.ymin and z0<shape.zmax and z1>shape.zmin and eligible(shape.part,params) and sweep(shape,center,half,V.zero) then hits[#hits+1]=shape.part end end
  return hits
 end
 function g:Raycast(origin,direction,params)
  local nearest,part=math.huge,nil
  for _,p in ipairs(map.floorParts) do if included(p,params) then
   local t=ray(p,origin,direction);if t and t<nearest then nearest=t;part=p end
  end end
  -- Architecture's exact convex ground regions avoid floating-point seams
  -- between its paired WedgePart triangles. Upper floors still use real rays.
  if direction.Y<0 and origin.Y>=0 and origin.Y+direction.Y<=0 and map.floorParts[1] and included(map.floorParts[1],params) then
   local t=-origin.Y/direction.Y;local point=origin+direction*t
   for _,poly in ipairs(map.floorRegions or {}) do
    local positive,negative=false,false
    for i,a in ipairs(poly) do
     local b=poly[i%#poly+1]
     local cross=(b[1]-a[1])*(point.Z-a[2])-(b[2]-a[2])*(point.X-a[1])
     positive=positive or cross>.001;negative=negative or cross<-.001
    end
    if not (positive and negative) and t<nearest then nearest=t;part=map.floorParts[1] end
   end
  end
  if part then return {Instance=part,Position=origin+direction*nearest} end
 end
 function g:GetServerTimeNow() return 100 end
 return g
end
return G
