-- Original mechanical detailing. No Toolbox, external mesh or texture dependencies.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.DeadSignal.Util)
local D={}
function D.build(model,bp,p,tube,ball,c,arms)
    local kind=bp.kind local pistol=kind=="Pistol" or kind=="Revolver" or kind=="MachinePistol"
    local wood=kind=="WoodCarbine" or kind=="WoodBolt" or kind=="Pump" or kind=="Double"
    local energy=kind=="Signal" or kind=="Arc" local muzzle=-.55-bp.barrel
    local function round(name,size,at,color,mat,group,rotation)
        local q=p(name,size,at,color,mat,group,rotation)
        U.make("SpecialMesh",q,{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)}) return q
    end
    local function screw(name,at,radius,group)
        local q=p(name,Vector3.new(.022,radius*2,radius*2),at,c.edge,nil,group) q.Shape=Enum.PartType.Cylinder
        p("ScrewRecess",Vector3.new(.026,radius*.22,radius*1.2),at,c.dark,nil,group)
    end
    -- Machining details have restrained finishes; bright edges remain small.
    local x=bp.bodyWidth/2+.012
    for _,side in ipairs({-1,1}) do
        if not energy then
            p("ReceiverInset",Vector3.new(.018,.13,pistol and .45 or .62),Vector3.new(side*x,-.04,-.02),c.metal)
            screw("CaptivePin",Vector3.new(side*(x+.018),-.08,.27),.032)
            screw("CaptivePin",Vector3.new(side*(x+.018),-.08,-.34),.032)
            p("SelectorBoss",Vector3.new(.04,.12,.12),Vector3.new(side*(x+.01),-.15,.16),c.dark)
            p("SafetyLever",Vector3.new(.045,.038,.19),Vector3.new(side*(x+.035),-.13,.21),c.metal,nil,nil,CFrame.Angles(.12,0,0))
            p("SelectorIndex",Vector3.new(.025,.025,.04),Vector3.new(side*(x+.035),-.05,.14),Color3.fromRGB(172,154,120))
        end
        if pistol then
            round("GripPalmSwell",Vector3.new(.055,.48,.28),Vector3.new(side*.16,-.44,.21),c.rubber,Enum.Material.SmoothPlastic)
            p("GripPanelBorder",Vector3.new(.025,.4,.027),Vector3.new(side*.19,-.43,.31),c.dark,Enum.Material.SmoothPlastic)
            p("FrameRailSeam",Vector3.new(.02,.025,.66),Vector3.new(side*.165,-.02,-.19),c.dark)
        else
            p("ReceiverJoint",Vector3.new(.018,.024,.89),Vector3.new(side*x,-.14,.0),c.dark)
            p("StockPanelSeam",Vector3.new(.018,.025,.64),Vector3.new(side*(wood and .181 or .188),-.18,1.09),c.dark)
            screw("StockFastener",Vector3.new(side*(wood and .185 or .191),-.28,1.2),.034)
            p("SlingEye",Vector3.new(.045,.13,.16),Vector3.new(side*.23,-.37,1.1),c.metal)
            p("SlingEyeRecess",Vector3.new(.05,.06,.08),Vector3.new(side*.23,-.37,1.1),c.dark)
        end
    end
    -- Separate breech, extractor, serrated controls and muzzle machining.
    tube("BarrelCollar",pistol and .092 or .115,.11,Vector3.new(0,pistol and .085 or .03,muzzle+.10),c.metal)
    tube("MuzzleRecess",pistol and .053 or .064,.012,Vector3.new(0,pistol and .085 or .03,muzzle-.145),c.dark)
    if pistol then
        if kind=="Revolver" then
            tube("EjectorRod",.036,.8,Vector3.new(.11,-.055,-1.03),c.edge)
            tube("Underlug",.066,.85,Vector3.new(0,-.09,-1.01),c.metal)
            p("CylinderLatch",Vector3.new(.05,.095,.16),Vector3.new(-.175,.06,.18),c.edge)
            round("SidePlate",Vector3.new(.035,.26,.45),Vector3.new(.15,-.055,.08),c.metal)
            p("HammerSpur",Vector3.new(.14,.035,.16),Vector3.new(0,.244,.29),c.dark,nil,"hammer")
            for j=1,3 do p("HammerKnurl",Vector3.new(.14,.02,.018),Vector3.new(0,.269,.22+j*.035),c.edge,nil,"hammer") end
        else
            p("BreechFace",Vector3.new(.026,.09,.21),Vector3.new(.188,.07,-.29),c.edge,nil,"slide")
            p("Extractor",Vector3.new(.025,.035,.22),Vector3.new(.195,.13,-.22),c.metal,nil,"slide")
            p("SlideEndPlate",Vector3.new(.22,.15,.025),Vector3.new(0,.075,.335),c.dark,nil,"slide")
            p("SlideCatch",Vector3.new(.065,.04,.24),Vector3.new(-.19,-.04,.07),c.edge)
            p("MagazineRelease",Vector3.new(.04,.08,.09),Vector3.new(-.185,-.22,.06),c.metal)
            p("Beavertail",Vector3.new(.25,.085,.21),Vector3.new(0,-.075,.36),c.metal)
            for side=-1,1,2 do for j=1,4 do
                p("ForwardSlideCut",Vector3.new(.018,.13,.025),Vector3.new(side*.17,.08,-.48-j*.058),c.dark,nil,"slide",CFrame.Angles(.18,0,0))
            end end
            tube("RecoilSpringPlug",.045,.05,Vector3.new(0,-.105,-.82),c.edge)
        end
        if kind~="Revolver" then
            p("MagazineFloorplate",Vector3.new(.29,.045,.31),Vector3.new(0,-.46-bp.mag/2,.15),c.dark,nil,"mag")
            for j=1,4 do p("MagazineWitnessHole",Vector3.new(.025,.026,.026),Vector3.new(.135,-.30-j*.065,.17),c.dark,nil,"mag") end
        end
    else
        p("BoltBody",Vector3.new(.024,.08,.24),Vector3.new(x+.018,.055,-.19),c.edge,nil,"bolt")
        p("BoltTrack",Vector3.new(.026,.025,.42),Vector3.new(x+.02,.135,-.1),c.dark)
        if not wood and not energy then
            p("MagazineWell",Vector3.new(.31,.16,.43),Vector3.new(0,-.32,kind=="Bullpup" and .45 or -.3),c.paint)
            p("MagazineCatch",Vector3.new(.04,.06,.17),Vector3.new(.20,-.28,-.16),c.edge)
            p("GripBackstrap",Vector3.new(.25,.47,.045),Vector3.new(0,-.50,.38),c.dark,Enum.Material.SmoothPlastic,nil,CFrame.Angles(-.2,0,0))
        end
        if wood then
            -- Fine longitudinal grain, fitted buttplate and steel barrel bands.
            for side=-1,1,2 do for j=1,5 do
                p("StockGrain",Vector3.new(.012,.012,.55+j*.06),Vector3.new(side*.181,-.05-j*.085,.95+j*.027),Color3.fromRGB(83+j*3,55+j*2,34),Enum.Material.Wood,nil,CFrame.Angles(.02*j,0,0))
            end end
            for _,z in ipairs({-1.09,-1.62}) do
                p("ForendBand",Vector3.new(.41,.035,.075),Vector3.new(0,-.23,z),c.metal)
                for side=-1,1,2 do p("ForendBandSide",Vector3.new(.027,.22,.075),Vector3.new(side*.206,-.10,z),c.metal) end
            end
            for j=1,5 do p("ButtpadGroove",Vector3.new(.32,.021,.02),Vector3.new(0,-.49+j*.09,1.748),c.edge) end
        elseif not energy then
            p("StockCheekRest",Vector3.new(.29,.065,.47),Vector3.new(0,.10,1.04),c.rubber,Enum.Material.SmoothPlastic)
            p("StockRelease",Vector3.new(.16,.06,.23),Vector3.new(0,-.46,1.0),c.dark)
            for j=1,4 do p("GripStipple",Vector3.new(.31,.025,.022),Vector3.new(0,-.29-j*.085,.39),c.metal,Enum.Material.SmoothPlastic) end
        end
        if kind=="AR" or kind=="DMR" or kind=="Precision" or kind=="DrumLMG" or kind=="Belt" then
            tube("GasTube",.036,bp.barrel*.65,Vector3.new(0,.17,-.9-bp.barrel*.325),c.metal)
            p("GasBlock",Vector3.new(.21,.19,.16),Vector3.new(0,.09,muzzle+.45),c.dark)
            for j=1,5 do for side=-1,1,2 do
                p("KeyslotRim",Vector3.new(.025,.086,.12),Vector3.new(side*.212,-.055,-.66-j*.15),c.edge)
                p("KeyslotRecess",Vector3.new(.028,.052,.09),Vector3.new(side*.228,-.055,-.66-j*.15),c.dark)
            end end
        elseif kind=="Bullpup" then
            for side=-1,1,2 do
                p("BullpupCheekPanel",Vector3.new(.027,.28,.51),Vector3.new(side*.246,.045,.68),c.metal)
                p("BullpupLatch",Vector3.new(.06,.08,.16),Vector3.new(side*.265,-.24,.72),c.edge)
            end
        elseif kind=="TopPDW" then
            p("TopMagazineLatch",Vector3.new(.38,.06,.12),Vector3.new(0,.26,.56),c.dark,nil,"mag")
            for side=-1,1,2 do p("PDWGripRecess",Vector3.new(.022,.24,.35),Vector3.new(side*.255,-.16,-.98),c.dark) end
        end
        if kind=="Pump" or kind=="TacticalShot" or kind=="AutoShot" then
            for j=1,4 do
                local z=.19-j*.16
                local shell=p("ShellCarrier",Vector3.new(.15,.29,.13),Vector3.new(-.25,-.03,z),Color3.fromRGB(112,48,37)) shell.Shape=Enum.PartType.Cylinder
                p("ShellBrass",Vector3.new(.16,.055,.14),Vector3.new(-.25,.11,z),Color3.fromRGB(153,131,77))
            end
            for side=-1,1,2 do p("PumpActionRail",Vector3.new(.035,.04,.9),Vector3.new(side*.19,-.18,-.72),c.edge,nil,"pump") end
        elseif kind=="Double" then
            p("BreakHinge",Vector3.new(.46,.12,.12),Vector3.new(0,-.13,-.55),c.edge,nil,"front")
            round("BreechSideplate",Vector3.new(.035,.24,.40),Vector3.new(.184,-.01,.03),c.edge)
        elseif kind=="Belt" then
            p("FeedCoverHinge",Vector3.new(.57,.08,.09),Vector3.new(0,.24,.38),c.edge)
            p("CarryHandleBase",Vector3.new(.08,.15,.29),Vector3.new(-.31,.16,-.24),c.metal)
            for j=1,6 do p("BeltLink",Vector3.new(.042,.115,.09),Vector3.new(.24+j*.075,-.04,-.29),c.metal) end
            p("AmmoBoxSeam",Vector3.new(.76,.025,.64),Vector3.new(.25,-.50,-.27),c.dark,nil,"mag")
        elseif kind=="DrumLMG" then
            p("DrumLatch",Vector3.new(.79,.14,.1),Vector3.new(0,-.64,-.75),c.dark,nil,"mag")
            for j=1,8 do local a=j*math.pi/4
                p("DrumRadialRib",Vector3.new(.785,.025,.24),Vector3.new(0,-.64+math.cos(a)*.22,-.31+math.sin(a)*.22),c.metal,nil,"mag",CFrame.Angles(a,0,0))
            end
        end
        if bp.scope then
            for j=1,6 do tube("ScopeFocusRing",.151,.018,Vector3.new(0,bp.sight,.18+j*.023),c.metal) end
            for side=-1,1,2 do
                local q=p("ScopeWindage",Vector3.new(.12,.13,.13),Vector3.new(side*.18,bp.sight,-.09),c.metal) q.Shape=Enum.PartType.Cylinder
                screw("OpticClampBolt",Vector3.new(side*.14,.32,.09),.035)
            end
            for j=1,4 do p("ElevationKnurl",Vector3.new(.025,.04,.15),Vector3.new(-.09+j*.035,bp.sight+.28,-.08),c.dark) end
        end
    end
    if energy then
        for side=-1,1,2 do
            p("CeramicInset",Vector3.new(.024,.24,.57),Vector3.new(side*.271,-.01,-.99),Color3.fromRGB(96,107,105))
            for j=1,4 do
                screw("InsulatorBolt",Vector3.new(side*.286,.11,-.64-j*.18),.028)
                p("CoolingFin",Vector3.new(.045,.25,.025),Vector3.new(side*.29,-.02,-.65-j*.17),c.metal)
            end
            p("BusInsulator",Vector3.new(.08,.08,.18),Vector3.new(side*.26,.22,-.59),c.dark)
        end
        tube("CellEndcap",.25,.09,Vector3.new(0,-.44,.20),c.edge,"mag")
        p("PowerMeter",Vector3.new(.025,.07,.2),Vector3.new(.277,-.11,-.21),c.paint,Enum.Material.Neon)
    end
    -- Thin, purposeful wear on contact edges instead of random oversized scratches.
    for side=-1,1,2 do for j=1,3 do
        p("ContactWear",Vector3.new(.012,.012,.04+j*.018),Vector3.new(side*x,-.09+j*.045,-.28+j*.17),c.edge,nil,nil,CFrame.Angles(.08*j,0,0))
    end end
    model:SetAttribute("ArtRevision",4)
    if arms then
        -- Rounded sleeve volumes and hand anatomy replace squared first-person arms.
        -- Base hand names remain available to the reload/equip animation system.
        model:SetAttribute("DetailedHands",true)
    end
end
-- A second pass fits to each weapon's actual construction. It is applied AFTER
-- optional imported art, so the native body/texture survives and the fittings
-- don't silently disappear when ArtAssets replaces the procedural body.
function D.fidelity(model,id,bp,p,tube,ball,c,tier)
    local imported=model:GetAttribute("ImportedArt")==true
    local pistol=bp.kind=="Pistol" or bp.kind=="MachinePistol" or bp.kind=="Revolver"
    local side=bp.bodyWidth/2+.012
    local function part(name,size,at,color,material,group,rotation)
        local q=p(name,size,at,color,material,group,rotation)
        q:SetAttribute("WeaponFidelity",true) return q
    end
    local steel=bp.finish=="blued" and Color3.fromRGB(39,46,53) or Color3.fromRGB(62,68,70)
    local polymer=Color3.fromRGB(42,48,46) local leather=Color3.fromRGB(78,60,43)
    local magZ=bp.reloadStyle=="bullpup" and .45 or pistol and .15 or -.3
    if bp.reloadStyle=="magazine" or bp.reloadStyle=="bullpup" or bp.reloadStyle=="bolt" then
        local width=pistol and .29 or .32 local y=pistol and -.33 or -.32
        for sign=-1,1,2 do
            part("FittedMagwellLip",Vector3.new(.025,.06,pistol and .28 or .44),Vector3.new(sign*width/2,y,magZ),steel,Enum.Material.Metal)
            part("MagazineGuide",Vector3.new(.014,bp.mag*.6,.025),Vector3.new(sign*.128,-.40-bp.mag*.5,magZ-.12),c.edge,Enum.Material.Metal,"mag")
        end
    end
    for sign=-1,1,2 do
        local x=sign*side
        part("ActionPinSeat",Vector3.new(.025,.065,.065),Vector3.new(x,.015,imported and -.12 or -.4),steel,Enum.Material.Metal)
        part("ReceiverMachining",Vector3.new(.012,.013,imported and .22 or .58),Vector3.new(x,bp.bodyHeight*.23,-.1),c.edge,Enum.Material.Metal)
        if bp.finish=="wood" and not pistol then
            part("LeatherSlingTab",Vector3.new(.025,.12,.19),Vector3.new(sign*.185,-.29,1.25),leather,Enum.Material.Fabric)
            part("SlingTabRivet",Vector3.new(.029,.035,.035),Vector3.new(sign*.202,-.29,1.29),c.edge,Enum.Material.Metal)
        elseif not pistol then
            part("StockLockTrack",Vector3.new(.022,.08,.43),Vector3.new(sign*.185,-.25,.99),polymer,Enum.Material.SmoothPlastic)
            part("StockIndexMark",Vector3.new(.024,.016,.07),Vector3.new(sign*.199,-.24,.86),c.edge,Enum.Material.Metal)
        end
        -- Wear follows two real contact edges and stays deterministic/bounded.
        for n=1,2 do
            part("FittedContactWear",Vector3.new(.008,.009,.035+n*.018),Vector3.new(x,.025+n*.035,-.23+n*.15),Color3.fromRGB(116,121,118),Enum.Material.Metal)
        end
    end
    if bp.reloadStyle=="top" then
        for sign=-1,1,2 do part("TopFeedGuide",Vector3.new(.025,.06,1.08),Vector3.new(sign*.185,.22,-.12),steel,Enum.Material.Metal) end
        part("TopFeedRelease",Vector3.new(.19,.05,.10),Vector3.new(0,.27,.60),polymer,Enum.Material.SmoothPlastic)
    elseif bp.reloadStyle=="cylinder" then
        part("CylinderCrane",Vector3.new(.08,.15,.18),Vector3.new(-.13,-.12,-.20),steel,Enum.Material.Metal,"cylinder")
        part("ExtractorStar",Vector3.new(.17,.17,.025),Vector3.new(0,.02,.09),c.edge,Enum.Material.Metal,"cylinder")
    elseif bp.reloadStyle=="belt" then
        part("FeedTrayRim",Vector3.new(.46,.035,.67),Vector3.new(0,.19,-.05),steel,Enum.Material.Metal)
        part("FeedCoverLatch",Vector3.new(.16,.075,.12),Vector3.new(0,.29,-.47),polymer,Enum.Material.SmoothPlastic,"feed")
    elseif bp.reloadStyle=="drum" then
        for sign=-1,1,2 do part("DrumWellGuide",Vector3.new(.035,.16,.28),Vector3.new(sign*.18,-.31,-.31),steel,Enum.Material.Metal) end
    elseif bp.reloadStyle=="cell" then
        for sign=-1,1,2 do
            part("CellLockJaw",Vector3.new(.08,.16,.25),Vector3.new(sign*.24,-.38,-.20),polymer,Enum.Material.SmoothPlastic)
            part("CeramicStandoff",Vector3.new(.05,.12,.10),Vector3.new(sign*.28,.10,-1.10),Color3.fromRGB(166,168,153),Enum.Material.SmoothPlastic):SetAttribute("SurfaceRole","Ceramic")
        end
    end
    -- Upgrades are original fitted hardware, not another painted receiver.
    if tier>0 then
        for sign=-1,1,2 do
            part("UpgradeCoupler",Vector3.new(.055,.12,.16),Vector3.new(sign*(side+.025),-.015,-.38),c.edge,Enum.Material.Metal)
            for n=1,tier+1 do
                part("UpgradeHeatFin",Vector3.new(.06,.17,.025),Vector3.new(sign*(side+.045),.015,-.55-n*.09),steel,Enum.Material.Metal)
            end
            if tier>=2 then part("UpgradeInsulatedLead",Vector3.new(.035,.035,.39),Vector3.new(sign*(side+.065),-.13,-.56),polymer,Enum.Material.Rubber) end
            if tier>=3 then part("UpgradeRegulator",Vector3.new(.09,.19,.24),Vector3.new(sign*(side+.055),-.03,.04),Color3.fromRGB(84,91,88),Enum.Material.Metal) end
        end
    end
    model:SetAttribute("FidelityRevision",1) model:SetAttribute("UpgradeHardwareTier",tier)
end
return D
