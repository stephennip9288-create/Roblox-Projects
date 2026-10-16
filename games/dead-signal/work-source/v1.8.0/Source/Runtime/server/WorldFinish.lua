-- Architectural finish work is decorative and never changes traversable space.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local F={}
function F.lobby(parent,center)
    local steel=Color3.fromRGB(65,74,69) local dark=Color3.fromRGB(30,35,33)
    local function p(name,size,at,color,mat,rot)
        return U.make("Part",parent,{Name=name,Size=size,CFrame=CFrame.new(center+at)*(rot or CFrame.new()),
            Color=color or steel,Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false})
    end
    for x=-96,96,16 do p("HangarExpansionJoint",Vector3.new(.03,.014,138),Vector3.new(x,.013,0),dark,Enum.Material.Concrete) end
    for z=-56,56,14 do p("HangarExpansionJoint",Vector3.new(220,.014,.03),Vector3.new(0,.014,z),dark,Enum.Material.Concrete) end
    for x=-96,96,24 do
        for _,z in ipairs({-69.7,69.7}) do
            p("WallFrameColumn",Vector3.new(.45,26,.25),Vector3.new(x,14,z),steel)
            p("ColumnBasePlate",Vector3.new(1.2,.12,.8),Vector3.new(x,.1,z),steel)
        end
    end
    for _,z in ipairs({-24,24}) do
        p("CeilingDuct",Vector3.new(212,1.7,2.7),Vector3.new(0,27,z),steel)
        for x=-96,96,16 do p("DuctJoint",Vector3.new(.09,1.8,2.82),Vector3.new(x,27,z),dark) end
    end
    for j=1,8 do
        local x=-100+j*24 local z=-64.42
        p("RackFace",Vector3.new(8.7,5.1,.09),Vector3.new(x,3,z),dark)
        for row=1,6 do
            p("RackVent",Vector3.new(6.5,.065,.055),Vector3.new(x,1.2+row*.32,z+.08),steel)
            p("RackFastener",Vector3.new(.08,.08,.04),Vector3.new(x-3.9,1.1+row*.48,z+.11),Color3.fromRGB(130,137,122))
        end
        p("MeterPanel",Vector3.new(2.1,.72,.08),Vector3.new(x+2.3,4.1,z+.12),Color3.fromRGB(122,134,115),Enum.Material.Glass)
    end
end
function F.apply(map,def,layout)
    local metal=Color3.fromRGB(70,77,72) local shadow=Color3.fromRGB(43,47,42)
    local warm=Color3.fromRGB(207,191,150) local cool=Color3.fromRGB(166,189,186)
    for i,r in ipairs(layout) do
        for _,q in ipairs(map.rooms[i].model:GetChildren()) do
            if q:IsA("BasePart") and (q.Name=="WaterStain" or q.Name=="PeelingPlaster") then
                U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) q.CastShadow=false
            end
        end
        local folder=U.make("Model",map.rooms[i].model,{Name="FinishDetails"}) local s=map.scale
        local function p(name,size,at,color,mat,rot)
            local q=U.make("Part",folder,{Name=name,Size=size*s,CFrame=CFrame.new((Vector3.new(r.x,0,r.z)+at)*s)*(rot or CFrame.new()),
                Color=color or metal,Material=mat or Enum.Material.Metal,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=true})
            q:SetAttribute("DecorativeFinish",true) return q
        end
        local function pipe(name,len,dia,at,axis,col)
            local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.new()
            local q=p(name,Vector3.new(len,dia,dia),at,col,nil,rot) q.Shape=Enum.PartType.Cylinder return q
        end
        -- Sparse expansion joints establish a human scale without noisy floor grids.
        for x=-r.w/2+12,r.w/2-6,12 do p("FloorExpansionJoint",Vector3.new(.028,.012,r.d-2),Vector3.new(x,.013,0),shadow,Enum.Material.Concrete) end
        for z=-r.d/2+12,r.d/2-6,12 do p("FloorExpansionJoint",Vector3.new(r.w-2,.012,.028),Vector3.new(0,.014,z),shadow,Enum.Material.Concrete) end
        local wallZ=-r.d/2+1.05 local high=r.h-3
        pipe("ServiceConduit",r.w-7,.16,Vector3.new(0,high,wallZ),"X",metal)
        pipe("ServiceConduit",r.w-7,.11,Vector3.new(0,high-.38,wallZ),"X",shadow)
        for x=-r.w/2+5,r.w/2-4,9 do
            p("ConduitClip",Vector3.new(.13,.76,.18),Vector3.new(x,high-.17,wallZ),shadow)
            pipe("ConduitFastener",.05,.08,Vector3.new(x,high+.20,wallZ-.12),"Z",warm)
        end
        local x=-r.w/2+2.3
        pipe("VerticalServicePipe",high-2,.34,Vector3.new(x,(high+2)/2,wallZ-.18),"Y",def.theme=="Foundry" and Color3.fromRGB(120,86,54) or metal)
        for _,y in ipairs({3.5,high-1.7}) do
            pipe("PipeCoupling",.16,.46,Vector3.new(x,y,wallZ-.18),"Y",shadow)
            p("PipeBracket",Vector3.new(.64,.12,.4),Vector3.new(x,y,wallZ),metal)
        end
        -- Lamp housing, diffuser and two down-facing reflectors per sector.
        for _,xx in ipairs({-r.w*.24,r.w*.24}) do
            local at=Vector3.new(xx,r.h-2,0)
            p("CeilingFixture",Vector3.new(5.5,.35,1.25),at,shadow)
            local lens=p("FixtureDiffuser",Vector3.new(5.03,.09,.84),at-Vector3.new(0,.21,0),def.theme=="Foundry" and warm or cool,Enum.Material.Neon)
            for _,side in ipairs({-1,1}) do p("FixtureReflector",Vector3.new(5.3,.15,.1),at+Vector3.new(0,-.11,side*.56),metal) end
            local l=U.make("SurfaceLight",lens,{Face=Enum.NormalId.Bottom,Angle=110,Range=25*s,Brightness=.38,Color=def.theme=="Foundry" and warm or cool,Shadows=xx<0})
            l:SetAttribute("PoweredBrightness",1.15)
        end
        -- Material transitions: small repairs, kick plates and a fitted vent grille.
        local vx=r.w/2-5
        p("VentFrame",Vector3.new(4.3,2.2,.12),Vector3.new(vx,high-2.2,wallZ-.15),shadow)
        for j=1,7 do p("VentLouver",Vector3.new(4.05,.10,.14),Vector3.new(vx,high-3.16+j*.24,wallZ-.25),metal,nil,CFrame.Angles(.3,0,0)) end
        for j=1,3 do
            local patch=p("PlasterRepair",Vector3.new(1.5+j*.4,1.1+j*.3,.025),Vector3.new(-r.w*.28+j*1.1,4+j*.4,-r.d/2+.73),Color3.fromRGB(133+j*3,132+j*3,111+j*3),Enum.Material.Concrete)
            U.make("SpecialMesh",patch,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)})
        end
        if def.theme=="Foundry" then
            for j=1,3 do p("HotWorkWarningBand",Vector3.new(1.8,.018,.26),Vector3.new(vx-4+j*1.8,.03,wallZ+2),Color3.fromRGB(157,124,66),Enum.Material.SmoothPlastic,nil) end
        elseif def.theme=="Frost" then
            for j=1,4 do p("CondensationLine",Vector3.new(.035,2+j*.3,.025),Vector3.new(vx-1.4+j*.54,high-4.5,wallZ+.13),Color3.fromRGB(124,147,147),Enum.Material.Ice) end
        end
        folder:SetAttribute("ArtRevision",4)
    end
end
return F
