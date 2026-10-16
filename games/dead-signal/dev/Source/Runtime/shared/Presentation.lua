-- Shared layout contract for actual HUD widgets and touch controls.
local P={}
P.colors={bg={10,13,15},panel={23,27,28},text={235,232,222},muted={165,171,167},red={201,87,62},amber={217,168,88},cyan={149,177,170}}
function P.layout(width,height,touch)
    local compact=touch or width<1000 local narrow=width<600 local margin=18
    local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end
    local r={compact=compact,narrow=narrow}
    r.round=rect(margin,20,50,38) r.roundLabel=rect(margin,5,64,16)
    r.waveInfo=rect(78,26,math.max(90,math.min(220,width-270)),26)
    r.points=rect(width-176,13,108,30) r.menu=rect(width-56,12,40,40)
    r.health=rect(margin,compact and 68 or height-54,compact and 156 or 206,5)
    r.healthText=rect(margin,compact and 76 or height-45,compact and 280 or 330,20)
    r.stamina=rect(margin,compact and 99 or height-18,compact and 156 or 206,2)
    r.perks=rect(margin,compact and 211 or height-92,compact and math.min(240,width-36) or 360,28)
    r.objective=compact and rect(margin,108,math.min(420,narrow and width-36 or width-260),36) or rect(width/2-210,17,420,40)
    r.team=rect(margin,compact and 152 or 100,compact and math.min(240,width-36) or 240,50)
    r.effects=compact and rect(width/2-105,height-92,210,22) or rect(width/2-220,61,440,22)
    r.ammo=compact and rect(width/2-100,height-48,200,32) or rect(width-258,height-61,230,40)
    r.weapon=compact and rect(width/2-110,height-70,220,18) or rect(width-308,height-83,280,20)
    r.boss=rect(width/2-90,compact and 58 or 108,180,4)
    r.bossName=rect(width/2-90,compact and 43 or 91,180,16)
    if compact and not narrow then
        r.team=rect(204,54,math.min(400,width-222),20)
        r.perks=rect(190,96,width-280,12)
        r.boss.y=height-122 r.bossName.y=height-140
    end
    if narrow then r.boss.y=302 r.bossName.y=282 r.effects=rect(margin,248,width-36,22) end
    local w=math.min(720,width-28) local h=math.min(550,height-28)
    r.panel=rect((width-w)/2,(height-h)/2,w,h)
    r.touch={}
    if touch then
        local positions=narrow and {
            FIRE={82,206,64},AIM={76,270,48},RELOAD={82,130,48},SWAP={142,130,48},
            MELEE={142,206,48},G={142,270,48},SPRINT={202,270,48}
        } or {
            FIRE={82,154,64},AIM={76,228,48},RELOAD={146,88,48},SWAP={204,88,48},
            MELEE={146,146,48},G={204,146,48},SPRINT={204,204,48}
        }
        for name,v in pairs(positions) do r.touch[name]=rect(width-v[1],height-v[2],v[3],v[3]) end
    end
    return r
end
return P
