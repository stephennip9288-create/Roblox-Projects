-- Distinct proportions and construction, not a common receiver recolored twenty times.
local B={
    Kestrel={kind="Pistol",barrel=.82,mag=.5,sight=.29},
    Carbine={kind="WoodCarbine",barrel=1.85,mag=.42,sight=.29},
    Rook={kind="TubeSMG",barrel=1.15,mag=.85,sight=.31},
    Trench={kind="Pump",barrel=2.05,mag=.4,sight=.29,reloadStyle="tube"},
    Vandal={kind="AR",barrel=1.75,mag=.9,sight=.35},
    Harrier={kind="Bullpup",barrel=1.2,mag=.82,sight=.39},
    Anchor={kind="Belt",barrel=2.1,mag=.65,sight=.35,reloadStyle="belt"},
    Longwatch={kind="WoodBolt",barrel=2.55,mag=.42,sight=.52,scope=true,aimFov=34,reloadStyle="bolt"},
    Cyclone={kind="AutoShot",barrel=1.5,mag=.68,sight=.36},
    Mantis={kind="TopPDW",barrel=.95,mag=.45,sight=.39},
    Signal={kind="Signal",barrel=1.65,mag=.7,sight=.38,reloadStyle="cell"},
    Vigil={kind="Revolver",barrel=1.2,mag=.55,sight=.32,reloadStyle="cylinder"},
    Needle={kind="MachinePistol",barrel=.7,mag=.95,sight=.31},
    Breaker={kind="Double",barrel=2.25,mag=.25,sight=.29,reloadStyle="break"},
    Sable={kind="TacticalShot",barrel=1.85,mag=.45,sight=.34,reloadStyle="tube"},
    Meridian={kind="DMR",barrel=2.15,mag=.62,sight=.51,scope=true,aimFov=44},
    Wasp={kind="Compact",barrel=.9,mag=.84,sight=.34},
    Bulwark={kind="DrumLMG",barrel=2.25,mag=.85,sight=.37},
    Halcyon={kind="Precision",barrel=2.8,mag=.57,sight=.54,scope=true,aimFov=34,reloadStyle="bolt"},
    Arc={kind="Arc",barrel=1.75,mag=.72,sight=.44,reloadStyle="cell"},
}
-- Presentation units are studs. These are original construction/action profiles,
-- not combat tuning: damage, magazine size, RPM and timing remain in Config/Rules.
local profiles={
    Kestrel={.156,.23,1.10,"slide","magazine","iron","alloy",.10},
    Carbine={.31,.32,1.16,"carrier","magazine","iron","wood",.14},
    Rook={.36,.34,1.10,"carrier","magazine","iron","stamped",.10},
    Trench={.36,.36,1.22,"pump","tube","iron","wood",.24},
    Vandal={.35,.36,1.12,"carrier","magazine","reflex","polymer",.11},
    Harrier={.40,.40,1.50,"carrier","bullpup","reflex","polymer",.13},
    Anchor={.53,.44,1.28,"carrier","belt","iron","stamped",.16},
    Longwatch={.15,.34,1.10,"bolt","bolt","scope","wood",.28},
    Cyclone={.43,.40,1.20,"carrier","drum","iron","polymer",.13},
    Mantis={.42,.38,1.50,"carrier","top","reflex","polymer",.09},
    Signal={.52,.43,1.18,"energy","cell","reflex","ceramic",0},
    Vigil={.29,.34,1.08,"revolver","cylinder","iron","blued",0},
    Needle={.33,.29,1.08,"slide","magazine","iron","polymer",.08},
    Breaker={.38,.32,1.14,"break","break","iron","wood",0},
    Sable={.37,.36,1.22,"pump","tube","iron","polymer",.22},
    Meridian={.36,.37,1.18,"carrier","magazine","scope","alloy",.13},
    Wasp={.32,.31,1.08,"carrier","magazine","reflex","stamped",.08},
    Bulwark={.49,.43,1.26,"carrier","drum","iron","polymer",.15},
    Halcyon={.37,.39,1.24,"bolt","bolt","scope","alloy",.30},
    Arc={.54,.45,1.18,"energy","cell","reflex","ceramic",0},
}
for id,v in pairs(profiles) do
    local bp=B[id]
    bp.bodyWidth=v[1] bp.bodyHeight=v[2] bp.bodyLength=v[3]
    bp.action=v[4] bp.reloadStyle=v[5] bp.optic=v[6] bp.finish=v[7] bp.ejectDelay=v[8]
    bp.kick=bp.action=="energy" and .05 or bp.action=="pump" and .12 or bp.action=="bolt" and .10 or .07
end
B.Mantis.sight=.45
return B
