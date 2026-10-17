-- All rectangles are in the safe-area frame's local pixels. Shots use the original
-- InputObject screen position, never a normalized or sensitivity-adjusted coordinate.
local L={}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function L.build(w,h,s)
    local unit=clamp(h/420,.78,1.3)
    local layout={w=w,h=h,unit=unit,buttons={}}
    local function rect(key,base,minimum)
        local size=math.min(math.max(base*unit,minimum or 0)*s["hud"..key.."Size"],h*.46,w*.28)
        local x=s["hud"..key.."X"]*w if s.leftHanded then x=w-x end
        local y=s["hud"..key.."Y"]*h
        return {x=clamp(x,size/2+8,w-size/2-8)-size/2,
            y=clamp(y,size/2+8,h-size/2-8)-size/2,w=size,h=size,key=key}
    end
    layout.move=rect("Move",110)
    layout.fire=rect(s.fireLayout=="Classic" and "Classic" or "Fire",s.fireLayout=="Classic" and 82 or 100)
    for _,item in ipairs({{"AIM","Aim",46},{"RELOAD","Reload",52},{"SWAP","Swap",44},
        {"MELEE","Melee",42},{"G","Grenade",42}}) do layout.buttons[item[1]]=rect(item[2],item[3],item[1]=="RELOAD" and 48 or item[1]=="AIM" and 44 or 40) end
    return layout
end
function L.overlaps(layout,settings)
    local rects={{name="Move",r=layout.move}}
    if settings.fireLayout~="Tap" then table.insert(rects,{name="Fire",r=layout.fire}) end
    for name,r in pairs(layout.buttons) do table.insert(rects,{name=name,r=r}) end
    local out={}
    for i=1,#rects do for j=i+1,#rects do
        local a,b=rects[i].r,rects[j].r
        if a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y then
            table.insert(out,rects[i].name.."/"..rects[j].name)
        end
    end end
    return out
end
function L.contains(r,x,y) return x>=r.x and y>=r.y and x<=r.x+r.w and y<=r.y+r.h end
function L.intersects(a,b,gap)
    gap=gap or 0
    return a.x<b.x+b.w+gap and a.x+a.w+gap>b.x and a.y<b.y+b.h+gap and a.y+a.h+gap>b.y
end
-- Place information around the *saved* controls. Never move or persist a control
-- to make room for a notice. This runs on resize/visibility changes, not per frame.
function L.combatHUD(layout,s,flags)
    flags=flags or {} local w,h=layout.w,layout.h local occupied={}
    local short=w<600 and h<320
    local function reserve(r) occupied[#occupied+1]=r end
    local move=layout.move
    reserve({x=move.x-move.w*.25,y=move.y-move.h*.15,w=move.w*1.5,h=h-move.y+move.h*.15})
    if s.fireLayout~="Tap" then reserve(layout.fire) end
    for _,r in pairs(layout.buttons) do reserve(r) end
    -- Leave the target and the scope's center clear of persistent HUD panels.
    reserve({x=w*.45,y=h*.42,w=w*.1,h=h*.16})
    local result={hidden={},crowded=false}
    local function place(key,width,height,x,y,optional)
        local best local score=math.huge
        local widths={width}
        if width>160 then widths[#widths+1]=math.max(120,width*.75) end
        local minimum=key=="account" and 154 or key=="heading" and math.min(170,w-184) or key=="crew" and 96 or 120
        if width>minimum then widths[#widths+1]=minimum end
        for _,rw in ipairs(widths) do
            local rh=(key=="toast" or key=="banner") and rw<180 and 44 or height
            local xs={clamp(x,8,w-rw-8),8,w-rw-8}
            local ys={clamp(y,6,h-rh-6),6,h-rh-6}
            for _,r in ipairs(occupied) do
                xs[#xs+1]=clamp(r.x+r.w+6,8,w-rw-8) xs[#xs+1]=clamp(r.x-rw-6,8,w-rw-8)
                ys[#ys+1]=clamp(r.y+r.h+6,6,h-rh-6) ys[#ys+1]=clamp(r.y-rh-6,6,h-rh-6)
            end
            for _,px in ipairs(xs) do for _,py in ipairs(ys) do
                local candidate={x=px,y=py,w=rw,h=rh} local free=true
                for _,r in ipairs(occupied) do if L.intersects(candidate,r,4) then free=false break end end
                local cost=(px-x)^2+(py-y)^2+(width-rw)^2
                if free and cost<score then best=candidate score=cost end
            end end
        end
        if not best then
            if optional then result.hidden[key]=true return end
            -- Fully overlapping custom controls can consume all usable space.
            -- Keep essential information on-screen; the editor still owns layout.
            best={x=clamp(x,8,w-width-8),y=clamp(y,6,h-height-6),w=width,h=height} result.crowded=true
        end
        result[key]=best reserve(best)
    end
    place("heading",math.min(short and 228 or 270,w-184),34,12,6)
    place("account",154,34,w-166,6)
    place("objective",math.min(420,w-24),30,12,46)
    place("ammo",math.min(200,w*.42),44,w/2-math.min(200,w*.42)/2,h-62)
    place("vitals",w<640 and h<400 and 116 or 156,32,12,86)
    if flags.crew then place("crew",short and 96 or math.min(220,w*.4),26,12,126,not flags.down) end
    local noticeWidth=math.min(300,math.max(160,w*.35))
    if flags.banner then place("banner",noticeWidth,32,w/2-noticeWidth/2,84) end
    if flags.boss then place("boss",short and 120 or math.min(180,w*.3),24,w/2-90,84) end
    if flags.toast then place("toast",noticeWidth,40,w/2-noticeWidth/2,h-112) end
    if flags.effects then place("effects",math.min(240,w*.4),26,w/2-100,h-96) end
    if flags.perks then place("perks",math.min(240,w*.4),18,12,160,true) end
    return result
end
function L.role(layout,s,x,y)
    for action,r in pairs(layout.buttons) do if L.contains(r,x,y) then return action end end
    if s.fireLayout~="Tap" and L.contains(layout.fire,x,y) then return "fire" end
    local r=layout.move
    if x>=r.x-r.w*.25 and x<=r.x+r.w*1.25 and y>=r.y-r.h*.15 and y<=layout.h then return "move" end
    local onLook=s.leftHanded and x<layout.w*.57 or not s.leftHanded and x>layout.w*.43
    if onLook then return "look" end
    return "reserved"
end
return L
