-- Broadphase only. The existing SAT/ray implementation still decides collisions.
local G=require('./SourceGeometry')
local r=require('@lune/roblox');local V=r.Vector3;local M={}
function M.world(map)
 local world=G.world(map);local all=table.clone(world.shapes);local buckets={};local cell=24
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
 world.allShapes=all
 return world
end
return M
