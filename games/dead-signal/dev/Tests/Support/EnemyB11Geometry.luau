-- Broadphase only. The existing SAT/ray implementation still decides collisions.
local G=require('./SourceGeometry')
local r=require('@lune/roblox');local V=r.Vector3;local M={}
function M.world(map)
 local spatial=table.clone(map);spatial.floorParts=table.clone(map.floorParts)
 local world=G.world(spatial);local all=table.clone(world.shapes);local buckets={};local cell=24
 for _,shape in ipairs(all) do
  for x=math.floor(shape.xmin/cell),math.floor(shape.xmax/cell) do for z=math.floor(shape.zmin/cell),math.floor(shape.zmax/cell) do
   local key=x..':'..z;buckets[key]=buckets[key] or {};buckets[key][#buckets[key]+1]=shape
  end end
 end
 local function select(cf,size,delta)
  local half=size*.5;local a=cf.Position-half;local b=cf.Position+half
  local xmin=math.floor(math.min(a.X,a.X+delta.X)/cell);local xmax=math.floor(math.max(b.X,b.X+delta.X)/cell)
  local zmin=math.floor(math.min(a.Z,a.Z+delta.Z)/cell);local zmax=math.floor(math.max(b.Z,b.Z+delta.Z)/cell)
  table.clear(world.shapes);local seen={}
  for x=xmin,xmax do for z=zmin,zmax do for _,shape in ipairs(buckets[x..':'..z] or {}) do
   if not seen[shape] then seen[shape]=true;world.shapes[#world.shapes+1]=shape end
  end end end
 end
 local cast,overlap=world.Blockcast,world.GetPartBoundsInBox
 function world:Blockcast(cf,size,delta,params)
  select(cf,size,delta);local hit=cast(self,cf,size,delta,params)
  if hit then self.lastFailure={kind='cast',center={cf.Position.X,cf.Position.Y,cf.Position.Z},size={size.X,size.Y,size.Z},delta={delta.X,delta.Y,delta.Z}} end
  return hit
 end
 function world:GetPartBoundsInBox(cf,size,params)
  select(cf,size,V.zero);local hits=overlap(self,cf,size,params)
  if #hits>0 then self.lastBlock=hits[1];self.lastFailure={kind='overlap',center={cf.Position.X,cf.Position.Y,cf.Position.Z},size={size.X,size.Y,size.Z}} end
  return hits
 end
 -- Vertical support rays use the same exact convex ray solver, with a
 -- conservative XZ broadphase. Never mutate the producer's floor inventory.
 local floors=table.clone(map.floorParts);local floorBuckets={}
 for _,part in ipairs(floors) do
  local cf=part.CFrame;local half=part.Size*.5
  local right,up,back=cf.RightVector,cf.UpVector,-cf.LookVector
  local ex=math.abs(right.X)*half.X+math.abs(up.X)*half.Y+math.abs(back.X)*half.Z+.002
  local ez=math.abs(right.Z)*half.X+math.abs(up.Z)*half.Y+math.abs(back.Z)*half.Z+.002
  for x=math.floor((cf.Position.X-ex)/cell),math.floor((cf.Position.X+ex)/cell) do
   for z=math.floor((cf.Position.Z-ez)/cell),math.floor((cf.Position.Z+ez)/cell) do
    local key=x..':'..z;floorBuckets[key]=floorBuckets[key] or {};table.insert(floorBuckets[key],part)
   end
  end
 end
 local ray=world.Raycast
 function world:Raycast(origin,direction,params)
  if math.abs(direction.X)<1e-8 and math.abs(direction.Z)<1e-8 and not next(map.floorRegions or {}) then
   spatial.floorParts=floorBuckets[math.floor(origin.X/cell)..':'..math.floor(origin.Z/cell)] or {}
  end
  local hit=ray(self,origin,direction,params);spatial.floorParts=floors
  return hit
 end
 world.allShapes=all
 return world
end
return M
