-- Fitted set dressing: detailed surfaces without adding navigation obstacles.
local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local F={}
function F.apply(map,def,layout)
    local folder=U.make("Model",map.model,{Name="CinematicDressing"}) local s=map.scale
    local dark=Color3.fromRGB(28,33,32) local steel=Color3.fromRGB(86,95,91) local rust=Color3.fromRGB(104,76,52)
    local function p(name,size,cf,col,mat,round)
        local q=U.make("Part",folder,{Name=name,Size=size,CFrame=cf,Color=col or steel,Material=mat or Enum.Material.Metal,
            Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=true})
        if round then U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) end return q
    end
    local function fitted(base,name,size,at,col,mat,round) return p(name,size*s,base.CFrame*CFrame.new(at*s),col,mat,round) end
    local source=map.model:GetDescendants()
    for _,base in ipairs(source) do if base:IsA("BasePart") then
        local size=base.Size/s
        if base.Name=="Locker" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do
                fitted(base,"LockerFoldedEdge",Vector3.new(.08,size.Y-.15,.09),Vector3.new(x,0,size.Z/2+.08),dark)
                for _,y in ipairs({-size.Y*.34,size.Y*.34}) do fitted(base,"DoorHinge",Vector3.new(.10,.35,.13),Vector3.new(x,y,size.Z/2+.12),steel) end
            end
            fitted(base,"LockerPlinth",Vector3.new(size.X+.08,.18,size.Z+.06),Vector3.new(0,-size.Y/2+.12,0),dark)
        elseif base.Name=="ShippingCrate" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do for _,z in ipairs({-size.Z/2-.02,size.Z/2+.02}) do
                fitted(base,"CrateCornerStrap",Vector3.new(.27,size.Y+.08,.08),Vector3.new(x,0,z),rust)
                for _,y in ipairs({-size.Y*.38,size.Y*.38}) do fitted(base,"CrateRivet",Vector3.new(.075,.075,.04),Vector3.new(x,y,z-.05),steel,nil,true) end
            end end
            fitted(base,"RecessedCarryGrip",Vector3.new(.75,.17,.08),Vector3.new(0,.35,-size.Z/2-.03),dark)
        elseif base.Name=="WornDeskTop" then
            for _,z in ipairs({-size.Z/2,size.Z/2}) do fitted(base,"DeskEdgeBand",Vector3.new(size.X,.12,.055),Vector3.new(0,0,z),Color3.fromRGB(64,54,41),Enum.Material.Wood) end
            fitted(base,"DeskDrawerCase",Vector3.new(2.1,1.3,2.8),Vector3.new(size.X/2-1.35,-.8,.15),Color3.fromRGB(67,72,64))
            for j=1,2 do
                fitted(base,"DeskDrawerFace",Vector3.new(1.94,.52,.08),Vector3.new(size.X/2-1.35,-.35-j*.54,-1.30),steel)
                fitted(base,"DeskDrawerPull",Vector3.new(.58,.07,.12),Vector3.new(size.X/2-1.35,-.35-j*.54,-1.39),dark)
            end
        elseif base.Name=="RadioCabinet" then
            for _,x in ipairs({-size.X/2+.12,size.X/2-.12}) do for _,y in ipairs({-size.Y/2+.12,size.Y/2-.12}) do
                fitted(base,"RadioCaseScrew",Vector3.new(.08,.08,.04),Vector3.new(x,y,size.Z/2+.04),steel,nil,true)
            end end
            for x=-1.3,1.3,.26 do fitted(base,"RadioTopVent",Vector3.new(.11,.018,.5),Vector3.new(x,size.Y/2+.012,0),dark) end
        elseif base.Name=="CanvasSandbag" then
            local mesh=base:FindFirstChildOfClass("SpecialMesh")
            if not mesh then U.make("SpecialMesh",base,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) end
        end
    end end
    for i,r in ipairs(layout) do
        local origin=CFrame.new(Vector3.new(r.x,0,r.z)*s)
        -- Truss and cable silhouettes create layered ceilings and directional light.
        for _,z in ipairs({-r.d*.24,r.d*.24}) do
            for _,y in ipairs({r.h-.75,r.h-2.0}) do p("RoofTrussChord",Vector3.new(r.w-2,.16,.16)*s,origin*CFrame.new(0,y*s,z*s),dark) end
            for x=-r.w/2+3,r.w/2-3,4 do
                p("RoofTrussDiagonal",Vector3.new(4.1,.09,.10)*s,origin*CFrame.new(x*s,(r.h-1.38)*s,z*s)*CFrame.Angles(0,0,x%8<4 and .31 or -.31),steel)
            end
        end
        local lamp=p("CagedWallLamp",Vector3.new(1.2,.43,.5)*s,origin*CFrame.new((r.w/2-1.2)*s,(r.h-4)*s,0),dark)
        p("FrostedLampLens",Vector3.new(1,.18,.32)*s,lamp.CFrame*CFrame.new(0,-.25*s,0),Color3.fromRGB(210,192,153),Enum.Material.Neon)
        for x=-.4,.4,.2 do p("LampGuardWire",Vector3.new(.035,.30,.47)*s,lamp.CFrame*CFrame.new(x*s,-.16*s,0),dark) end
        local light=U.make("SpotLight",lamp,{Face=Enum.NormalId.Bottom,Angle=75,Range=20*s,Brightness=.55,Color=def.theme=="Foundry" and Color3.fromRGB(234,167,91) or Color3.fromRGB(185,207,202),Shadows=i%2==0})
        light:SetAttribute("PoweredBrightness",1.9)
    end
    folder:SetAttribute("ArtRevision",5)
end
return F
