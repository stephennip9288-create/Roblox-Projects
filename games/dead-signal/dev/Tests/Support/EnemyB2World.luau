-- Offline convex sweeps; no Roblox engine/navmesh claim. Existing B1 helper is unchanged.
-- B1 conservatively boxes ramps. B2 slope tests additionally use actual six-vertex
-- WedgePart hulls (face normals + edge cross axes), with a swept world-axis box.
local G=require('./EnemyB11Geometry');local r=require('@lune/roblox');local V=r.Vector3
local B={};local axes={V.xAxis,V.yAxis,V.zAxis};local filterSets=setmetatable({},{__mode='k'})
local function included(part,p)
 local cached=filterSets[p];local list=p.FilterDescendantsInstances
 if not cached or cached.list~=list then
  cached={list=list,roots={}};for _,x in ipairs(list or {}) do cached.roots[x]=true end;filterSets[p]=cached
 end
 local matched=false;local at=part
 while at do if cached.roots[at] then matched=true;break end;at=at.Parent end
 return p.FilterType==r.Enum.RaycastFilterType.Include and matched or p.FilterType~=r.Enum.RaycastFilterType.Include and not matched
end
local function wedge(shape)
 if shape.wedgeAxes then return shape.wedgeAxes end
 local part=shape.part;local h=part.Size*.5;local cf=part.CFrame
 local vertices={}
 for _,x in ipairs({-h.X,h.X}) do for _,yz in ipairs({{-h.Y,-h.Z},{-h.Y,h.Z},{h.Y,h.Z}}) do
  vertices[#vertices+1]=cf:VectorToWorldSpace(V.new(x,yz[1],yz[2]))
 end end
 local candidates={V.xAxis,V.yAxis,V.zAxis,cf.RightVector,cf.UpVector,-cf.LookVector,
  cf:VectorToWorldSpace(V.new(0,1/h.Y,-1/h.Z)).Unit}
 local edges={cf.RightVector,cf.UpVector,-cf.LookVector,cf:VectorToWorldSpace(V.new(0,h.Y,h.Z)).Unit}
 for _,a in ipairs(axes) do for _,edge in ipairs(edges) do local cross=a:Cross(edge)
  if cross.Magnitude>1e-6 then candidates[#candidates+1]=cross.Unit end
 end end
 local tests={}
 for _,a in ipairs(candidates) do
  local lo,hi=math.huge,-math.huge
  for _,v in ipairs(vertices) do local d=v:Dot(a);lo=math.min(lo,d);hi=math.max(hi,d) end
  tests[#tests+1]={axis=a,lo=lo,hi=hi}
 end
 shape.wedgeAxes=tests;return tests
end
local function cast(shape,center,half,delta)
 local tests=shape.part:IsA('WedgePart') and wedge(shape) or shape.axes
 local enter,leave=0,1
 for _,test in ipairs(tests) do
  local a=test.axis;local radius=math.abs(a.X)*half.X+math.abs(a.Y)*half.Y+math.abs(a.Z)*half.Z
  local lo=(test.lo or -test.radius)-radius+1e-5;local hi=(test.hi or test.radius)+radius-1e-5
  local distance=(center-shape.center):Dot(a);local speed=delta:Dot(a)
  if math.abs(speed)<1e-8 then if distance<=lo or distance>=hi then return nil end
  else
   local p,q=(lo-distance)/speed,(hi-distance)/speed;if p>q then p,q=q,p end
   enter=math.max(enter,p);leave=math.min(leave,q);if enter>leave then return nil end
  end
 end
 return enter
end
function B.world(map)
 local world=G.world(map);local shapeBuckets={};local cell=24
 for _,shape in ipairs(world.allShapes) do
  for x=math.floor(shape.xmin/cell),math.floor(shape.xmax/cell) do for z=math.floor(shape.zmin/cell),math.floor(shape.zmax/cell) do
   local key=x..':'..z;shapeBuckets[key]=shapeBuckets[key] or {};table.insert(shapeBuckets[key],shape)
  end end
 end
 -- Lune's Vector3/CFrame arithmetic is float32. Adjacent floor triangles can
 -- disagree at their shared edge by a few micrometres. Use a 0.0001-stud plane
 -- tolerance on real convex parts, never a logical polygon or filled hole.
 local floorBuckets={}
 for _,part in ipairs(map.floorParts) do
  local h=part.Size*.5;local cf=part.CFrame;local x,y,z=cf.RightVector,cf.UpVector,-cf.LookVector
  local ex=math.abs(x.X)*h.X+math.abs(y.X)*h.Y+math.abs(z.X)*h.Z+.001
  local ez=math.abs(x.Z)*h.X+math.abs(y.Z)*h.Y+math.abs(z.Z)*h.Z+.001
  for bx=math.floor((cf.X-ex)/cell),math.floor((cf.X+ex)/cell) do for bz=math.floor((cf.Z-ez)/cell),math.floor((cf.Z+ez)/cell) do
   local key=bx..':'..bz;floorBuckets[key]=floorBuckets[key] or {};table.insert(floorBuckets[key],part)
  end end
 end
 local function floorRay(part,origin,direction)
  local p=part.CFrame:PointToObjectSpace(origin);local v=part.CFrame:VectorToObjectSpace(direction);local h=part.Size*.5
  local planes={{V.xAxis,h.X},{-V.xAxis,h.X},{V.yAxis,h.Y},{-V.yAxis,h.Y},{V.zAxis,h.Z},{-V.zAxis,h.Z}}
  if part:IsA('WedgePart') then planes[#planes+1]={V.new(0,1/h.Y,-1/h.Z).Unit,0} end
  local enter,leave=0,1
  for _,plane in ipairs(planes) do
   local a=plane[1];local distance=p.X*a.X+p.Y*a.Y+p.Z*a.Z-plane[2];local speed=v.X*a.X+v.Y*a.Y+v.Z*a.Z
   if math.abs(speed)<1e-8 then if distance>.0001 then return nil end
   elseif speed<0 then enter=math.max(enter,-distance/speed)
   else leave=math.min(leave,-distance/speed) end
   if enter>leave+1e-7 then return nil end
  end
  return enter
 end
 function world:Blockcast(cf,size,delta,params)
  self.probes+=1
  local lo,hi=cf.Position-size*.5,cf.Position+size*.5
  local x0,x1=math.min(lo.X,lo.X+delta.X),math.max(hi.X,hi.X+delta.X)
  local y0,y1=math.min(lo.Y,lo.Y+delta.Y),math.max(hi.Y,hi.Y+delta.Y)
  local z0,z1=math.min(lo.Z,lo.Z+delta.Z),math.max(hi.Z,hi.Z+delta.Z)
  local nearest,part=math.huge,nil
  local seen={}
  for x=math.floor(x0/cell),math.floor(x1/cell) do for z=math.floor(z0/cell),math.floor(z1/cell) do
   for _,shape in ipairs(shapeBuckets[x..':'..z] or {}) do if not seen[shape] then
    seen[shape]=true
    if shape.enemyCollide and shape.part.CanCollide and x0<shape.xmax and x1>shape.xmin and y0<shape.ymax and y1>shape.ymin
     and z0<shape.zmax and z1>shape.zmin and included(shape.part,params) then
     local t=cast(shape,cf.Position,size*.5,delta)
     if t and t<nearest then nearest=t;part=shape.part end
    end
   end end
  end end
  self.lastBlock=part
  return part and {Instance=part,Position=cf.Position+delta*nearest} or nil
 end
 function world:Raycast(origin,direction,params)
  if math.abs(direction.X)+math.abs(direction.Z)>.0001 then
   return self:Blockcast(r.CFrame.new(origin),V.new(.02,.02,.02),direction,params)
  end
  local nearest,part=math.huge,nil
  for _,p in ipairs(floorBuckets[math.floor(origin.X/cell)..':'..math.floor(origin.Z/cell)] or {}) do if included(p,params) then
   local t=floorRay(p,origin,direction);if t and t<nearest then nearest=t;part=p end
  end end
  return part and {Instance=part,Position=origin+direction*nearest} or nil
 end
 return world
end
return B
