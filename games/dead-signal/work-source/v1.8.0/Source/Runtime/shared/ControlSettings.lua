-- Touch preferences are independent of aim assistance. Only these keys may persist.
local S={}
S.defaults={fireLayout="Tap",assistPreset="Manual",autoFire=false,tapHold=true,
    tapHoldTime=.34,tapTime=.25,tapSlop=12,leftGesture="Outer",leftHanded=false,
    lookSensitivity=1,verticalSensitivity=1,adsSensitivity=.65,scopeSensitivity=.4,
    invertY=false,gyroAim=false,gyroSensitivity=.7,hudOpacity=.38,
    hudMoveX=.16,hudMoveY=.76,hudMoveSize=1,
    hudFireX=.31,hudFireY=.43,hudFireSize=1,
    hudClassicX=.77,hudClassicY=.67,hudClassicSize=1,
    hudAimX=.92,hudAimY=.53,hudAimSize=1,
    hudReloadX=.93,hudReloadY=.82,hudReloadSize=1,
    hudSwapX=.78,hudSwapY=.91,hudSwapSize=1,
    hudMeleeX=.65,hudMeleeY=.78,hudMeleeSize=1,
    hudGrenadeX=.81,hudGrenadeY=.43,hudGrenadeSize=1}
local enums={fireLayout={Tap=true,Left=true,Classic=true},assistPreset={Assisted=true,Manual=true,Advanced=true},
    leftGesture={Outer=true,Toggle=true,Pad=true}}
local ranges={tapHoldTime={.28,.65},tapTime={.15,.28},tapSlop={6,24},
    lookSensitivity={.25,2.5},verticalSensitivity={.25,2.5},adsSensitivity={.2,1.5},
    scopeSensitivity={.1,1.2},gyroSensitivity={.1,2},hudOpacity={.1,.85}}
function S.valid(key,value)
    if type(key)~="string" or S.defaults[key]==nil then return false end
    if enums[key] then return type(value)=="string" and enums[key][value]==true end
    if type(S.defaults[key])=="boolean" then return type(value)=="boolean" end
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return false end
    local range=ranges[key]
    if range then return value>=range[1] and value<=range[2] end
    if key:sub(-4)=="Size" then return value>=.65 and value<=1.5 end
    return value>=.04 and value<=.96
end
function S.resolve(settings)
    local out=table.clone(S.defaults)
    for key,value in pairs(settings or {}) do if S.valid(key,value) then out[key]=value end end
    return out
end
return S
