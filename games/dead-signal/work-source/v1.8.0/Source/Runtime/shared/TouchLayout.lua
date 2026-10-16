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
