local fs=require('@lune/fs')
local luau=require('@lune/luau')
local r=require('@lune/roblox')
local L={}
-- Lune serializes instances, but does not run Roblox spatial methods/physics.
-- These authoring shims transform exact CFrames for offline map construction.
r.implementMethod('Model','PivotTo',function(model,cf)
 local root=model.PrimaryPart local before=root and root.CFrame or r.CFrame.identity
 local transform=cf*before:Inverse()
 for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.CFrame=transform*part.CFrame;part.Position=part.CFrame.Position end end
end)
r.implementMethod('Model','GetPivot',function(model) local p=model.PrimaryPart return p and p.CFrame or r.CFrame.identity end)
function L.new(dm,overrides)
 local cache={} local services={}
 local physics={RegisterCollisionGroup=function() end,CollisionGroupSetCollidable=function() end}
 local workspace=dm:FindFirstChild('Workspace')
 local game={GetService=function(_,name)
  if name=='PhysicsService' then return physics end
  if overrides and overrides.services and overrides.services[name] then return overrides.services[name] end
  local service=dm:FindFirstChild(name)
  if not service then service=r.Instance.new(name);service.Parent=dm end
  return service
 end}
 local function loadModule(script)
  if overrides and overrides.modules and overrides.modules[script.Name] then return overrides.modules[script.Name] end
  if cache[script] then return cache[script] end
  local globals={game=game,workspace=workspace,script=script,Instance=r.Instance,Enum=r.Enum,
   Vector2=r.Vector2,Vector3=r.Vector3,CFrame=r.CFrame,Color3=r.Color3,UDim=r.UDim,UDim2=r.UDim2,
   NumberSequence=r.NumberSequence,NumberSequenceKeypoint=r.NumberSequenceKeypoint,
   ColorSequence=r.ColorSequence,ColorSequenceKeypoint=r.ColorSequenceKeypoint,NumberRange=r.NumberRange,
   Rect=r.Rect,Font=r.Font,PhysicalProperties=r.PhysicalProperties,
   require=loadModule,task={spawn=function(f,...) return f(...) end,delay=function() end,wait=function() end},
   typeof=typeof,print=print,warn=warn}
  if overrides and overrides.globals then for key,value in pairs(overrides.globals) do globals[key]=value end end
  local f=luau.load(script.Source,{debugName=script:GetFullName(),environment=globals,injectGlobals=true})
  local result=f()
  if script.Name=='Util' then
   local original=result.make
   result.make=function(class,parent,props)
    local obj=original(class,parent,props)
    if obj:IsA('BasePart') then
     if props and props.CFrame then obj.Position=obj.CFrame.Position
     elseif props and props.Position then obj.CFrame=r.CFrame.new(props.Position) else obj.Position=obj.CFrame.Position end
    end
    if obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox') then
     obj.FontFace=r.Font.new('rbxasset://fonts/families/GothamSSm.json',props and props.Font==r.Enum.Font.GothamBold and r.Enum.FontWeight.Bold or r.Enum.FontWeight.Regular,r.Enum.FontStyle.Normal)
    end
    return obj
   end
  end
  cache[script]=result return result
 end
 return loadModule,workspace
end
function L.install(dm)
 local root='Source/Runtime/'
 local folders={shared=dm:FindFirstChild('ReplicatedStorage').DeadSignal,
  server=dm:FindFirstChild('ServerScriptService').DeadSignalServer,
  client=dm:FindFirstChild('StarterPlayer').StarterPlayerScripts.DeadSignalClient}
 for group,folder in pairs(folders) do
  for _,file in ipairs(fs.readDir(root..group)) do
   if file:sub(-4)=='.lua' then
    local name=file:gsub('%.server%.lua$',''):gsub('%.client%.lua$',''):gsub('%.lua$','')
    -- PlaceConfig differs per place and must never be replaced by Lobby's source.
    if name~='PlaceConfig' then
     local script=folder:FindFirstChild(name)
     if not script then script=r.Instance.new(file:find('Bootstrap') and (group=='server' and 'Script' or 'LocalScript') or 'ModuleScript');script.Name=name;script.Parent=folder end
     script.Source=fs.readFile(root..group..'/'..file)
    end
   end
  end
 end
 return folders
end
return L
