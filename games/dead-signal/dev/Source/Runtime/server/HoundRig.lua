-- K9 presentation on the retained canine skeleton; no replacement damage volumes.
local RS=game:GetService("ReplicatedStorage") local U=require(RS.DeadSignal.Util)
local Anatomy=require(script.Parent.RigAnatomy)
local H={maxParts=34}
function H.build(parent,position,id,mapId)
    local model,root,hum=Anatomy.build(parent,"Hound",position,id)
    local head=model.Head local torso=model.Torso local n=0
    local coats={{72,66,51},{92,82,62},{52,56,51}}
    local coat=mapId=="Frost" and Color3.fromRGB(148,155,147) or U.color(coats[(id-1)%3+1])
    local dark=Color3.fromRGB(31,33,29) local canvas=mapId=="Frost" and Color3.fromRGB(113,132,131) or Color3.fromRGB(85,97,68)
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and p.MaterialVariant=="DS_Canine" then p.Color=coat end end
    local function part(b,name,size,at,color,material,shape,rot)
        if n>=H.maxParts then return end n+=1
        local p=U.make("Part",model,{Name=name,Size=size,CFrame=b.CFrame*CFrame.new(at)*(rot or CFrame.identity),
            Color=color or coat,Material=material or Enum.Material.Fabric,Shape=shape or Enum.PartType.Ball,
            Anchored=false,Massless=true,CanCollide=false,CanQuery=false,CanTouch=false,CollisionGroup="DeadSignalEnemies"})
        p.MaterialVariant=p.Material==Enum.Material.Fabric and "DS_Canine" or "";p:SetAttribute("K9Detail",true)
        U.make("WeldConstraint",p,{Part0=b,Part1=p});return p
    end
    -- Forechest, tapering muzzle, hocks and movable ears make the canine silhouette explicit.
    part(torso,"K9Sternum",Vector3.new(.69,.95,.69),Vector3.new(0,-.03,-1.00))
    part(head,"NasalBridge",Vector3.new(.43,.34,.73),Vector3.new(0,-.01,-.61))
    part(head,"K9Nose",Vector3.new(.38,.24,.16),Vector3.new(0,-.04,-.99),dark,Enum.Material.Rubber)
    local jaw=part(head,"K9Mandible",Vector3.new(.48,.18,.70),Vector3.new(0,-.36,-.53),coat)
    jaw:FindFirstChildOfClass("WeldConstraint"):Destroy()
    local world=head.CFrame*CFrame.new(0,-.23,-.17)
    local j=U.make("Motor6D",head,{Name="Jaw",Part0=head,Part1=jaw,C0=head.CFrame:ToObjectSpace(world),C1=jaw.CFrame:ToObjectSpace(world)})
    j:SetAttribute("RestC0",j.C0);j:SetAttribute("RagdollAngle",18)
    for _,side in ipairs({-1,1}) do
        local ear=part(head,"K9Ear",Vector3.new(.28,.62,.21),Vector3.new(side*.36,.57,.02),coat,nil,Enum.PartType.Block,CFrame.Angles(0,0,-side*.17))
        ear:FindFirstChildOfClass("WeldConstraint"):Destroy()
        local at=head.CFrame*CFrame.new(side*.35,.30,.02)
        local joint=U.make("Motor6D",head,{Name=(side==1 and "Right" or "Left").." Ear",Part0=head,Part1=ear,C0=head.CFrame:ToObjectSpace(at),C1=ear.CFrame:ToObjectSpace(at)})
        joint:SetAttribute("RestC0",joint.C0);joint:SetAttribute("RagdollAngle",25)
        part(head,"K9CheekTendon",Vector3.new(.14,.36,.24),Vector3.new(side*.37,-.12,-.38),Color3.fromRGB(112,115,91),Enum.Material.SmoothPlastic)
        part(head,"MuzzleWhiskerPad",Vector3.new(.20,.19,.34),Vector3.new(side*.18,-.16,-.72))
        part(jaw,"LowerCanine",Vector3.new(.065,.18,.065),Vector3.new(side*.17,.13,-.16),Color3.fromRGB(170,166,137),Enum.Material.Slate)
        part(torso,"K9HarnessPanel",Vector3.new(.10,.63,1.05),Vector3.new(side*.60,.15,-.15),canvas,Enum.Material.Fabric,Enum.PartType.Block)
        part(torso,"K9UnitBars",Vector3.new(.025,.08,.56),Vector3.new(side*.66,.21,-.15),Color3.fromRGB(166,171,142),Enum.Material.Fabric,Enum.PartType.Block)
        local shin=model:FindFirstChild(side==1 and "Right Shin" or "Left Shin")
        part(shin,"DefinedHock",Vector3.new(.31,.37,.33),Vector3.new(0,-.27,.09))
    end
    part(torso,"HarnessDorsalHandle",Vector3.new(.19,.17,.66),Vector3.new(0,.77,-.13),dark,Enum.Material.Rubber,Enum.PartType.Block)
    part(torso,"HarnessReceiver",Vector3.new(.29,.16,.42),Vector3.new(.25,.73,.18),canvas,Enum.Material.Metal,Enum.PartType.Block)
    part(head,"TornK9EarEdge",Vector3.new(.11,.17,.07),Vector3.new(id%2==0 and .40 or -.40,.73,-.04),Color3.fromRGB(93,100,79),Enum.Material.SmoothPlastic)
    part(torso,"K9InfectionScar",Vector3.new(.055,.38,.38),Vector3.new(.65,.03,.73),Color3.fromRGB(97,111,81),Enum.Material.SmoothPlastic)
    model:SetAttribute("K9Revision",1);model:SetAttribute("K9DetailCount",n)
    model:SetAttribute("MilitaryOrigin",mapId=="Frost" and "Whiteout Search K9" or mapId=="Foundry" and "Containment K9" or "Blackwater Patrol K9")
    return model,root,hum
end
return H
