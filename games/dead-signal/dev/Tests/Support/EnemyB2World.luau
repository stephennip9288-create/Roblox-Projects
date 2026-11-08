-- Offline convex sweeps; no Roblox engine/navmesh claim. Existing B1 helper is unchanged.
-- B1 conservatively boxes ramps. B2 slope tests additionally use actual six-vertex
-- WedgePart hulls (face normals + edge cross axes), with a swept world-axis box.
local G=require('./EnemyB11Geometry');local r=require('@lune/roblox');local V=r.Vector3
local B={};local axes={V.xAxis,V.yAxis,V.zAxis}
local function included(part,p)
 local matched=false
 for _,x in ipairs(p.FilterDescendantsInstances or {}) do if part==x or part:IsDescendantOf(x) then matched=true;break end end
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
 local world=G.world(map);local original=world.Blockcast
 function world:Blockcast(cf,size,delta,params)
  local hit=original(self,cf,size,delta,params)
  if not hit or not hit.Instance:IsA('WedgePart') then return hit end
  local nearest,part=math.huge,nil
  for _,shape in ipairs(self.shapes) do if shape.enemyCollide and shape.part.CanCollide and included(shape.part,params) then
   local t=cast(shape,cf.Position,size*.5,delta)
   if t and t<nearest then nearest=t;part=shape.part end
  end end
  self.lastBlock=part
  return part and {Instance=part,Position=cf.Position+delta*nearest} or nil
 end
 local ray=world.Raycast
 function world:Raycast(origin,direction,params)
  if math.abs(direction.X)+math.abs(direction.Z)>.0001 then
   return self:Blockcast(r.CFrame.new(origin),V.new(.02,.02,.02),direction,params)
  end
  return ray(self,origin,direction,params)
 end
 return world
end
return B
