-- Spatially sample the receiver cross-sections that previously had invisible bevel gaps.
local fs=require('@lune/fs') local r=require('@lune/roblox') local loader=require('./Support/RuntimeLoader')
local dm=r.deserializePlace(fs.readFile('Places/DeadSignal-v1.8.0-Lobby.rbxl')) local f=loader.install(dm) local load=loader.new(dm)
local W=load(f.shared.WeaponModels) local C=load(f.shared.Config) local count=0 local function check(ok,msg) assert(ok,msg);count+=1 end
local parent=r.Instance.new('Folder')
local function inside(p,point)
 local v=p.CFrame:PointToObjectSpace(point) local h=p.Size*.5
 if p.Shape==r.Enum.PartType.Cylinder then return math.abs(v.X)<=h.X+.001 and (v.Y/h.Y)^2+(v.Z/h.Z)^2<=1.001 end
 return math.abs(v.X)<=h.X+.001 and math.abs(v.Y)<=h.Y+.001 and math.abs(v.Z)<=h.Z+.001
end
local samples=0
for _,id in ipairs({'Vandal','Harrier','Rook','Carbine','Trench','Halcyon'}) do
 local model=W.build(id,'Factory',0,parent,false) local receiver=model:FindFirstChild('Receiver') local pieces={}
 for _,p in ipairs(model:GetChildren()) do if p:IsA('Part') and (p.Name=='Receiver' or p.Name=='ReceiverWeb' or p.Name=='ReceiverRadius') then pieces[#pieces+1]=p end end
 check(#pieces==6,id..' continuous receiver sections')
 local web=model:FindFirstChild('ReceiverWeb') local width=web.Size.X local height=receiver.Size.Y local bevel=math.min(width,height)*.16
 for _,z in ipairs({-.52,-.10,.35}) do
  for ix=-8,8 do for iy=-8,8 do
   local x=ix/8*(width/2-.003) local y=iy/8*(height/2-.003)
   local qx=math.abs(x)-(width/2-bevel) local qy=math.abs(y)-(height/2-bevel)
   local distance=math.sqrt(math.max(qx,0)^2+math.max(qy,0)^2)+math.min(math.max(qx,qy),0)-bevel
   if distance<-.001 then
    local covered=false for _,p in ipairs(pieces) do if inside(p,r.Vector3.new(x,y,z)) then covered=true break end end
    check(covered,id..' solid receiver section');samples+=1
   end
  end end
 end
 model:Destroy()
end
for id in pairs(C.Weapons) do
 local model=W.build(id,'Factory',0,parent,false)
 check(model:GetAttribute('WeaponArtRevision')==10 and model.PrimaryPart~=nil,id..' revised weapon builds')
 check(model:FindFirstChild('Muzzle')~=nil,id..' retains authored combat muzzle')
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then check(not p.CanCollide and not p.CanQuery,id..' presentation never blocks shots or movement') end end
 local bytes=r.serializeModel({model});check(#bytes>1000,id..' serialized native model') model:Destroy()
end
print('Weapon geometry assertions passed:',count)
print('Receiver cross-section samples:',samples)
