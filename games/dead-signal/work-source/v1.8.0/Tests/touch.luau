local Settings=require('../Source/Runtime/shared/ControlSettings')
local Input=require('../Source/Runtime/shared/TouchInput')
local Layout=require('../Source/Runtime/shared/TouchLayout')
local count=0
local function check(ok,message) assert(ok,message) count+=1 end
local function fresh(extra) local s=Settings.resolve(extra) return Input.new(s),s end
local function shots(t) local n=0 for _,e in ipairs(t:drain()) do if e.kind=='shot' then n+=1 end end return n end
-- Exact off-center tap payload, including while the other thumb holds movement.
local t=fresh()
t:begin('left',100,260,0,'move',45,true) t:move('left',110,205,.05)
t:begin('right',568,122,.1,'look',45,true) t:finish('right',569,123,.20,false)
local e=t:drain() check(#e==1 and e[1].kind=='shot' and e[1].data.x==569 and e[1].data.y==123,'tap must preserve touched location')
check(t:step(.2,true).y<-.5,'tap must preserve left movement')
-- Tremor below threshold taps; a swipe is irrevocably a look gesture.
for _,drift in ipairs({0,2,6,11}) do local a=fresh();a:begin(1,500,150,0,'look',45,false);a:move(1,500+drift,151,.04);a:finish(1,500+drift,151,.12,false);check(shots(a)==1,'small tremor tap') end
for _,drift in ipairs({13,30,100}) do local a=fresh();a:begin(1,500,150,0,'look',45,true);a:move(1,500+drift,150,.05);check(a:step(.1,true).lookX>0,'swipe rotates');a:move(1,500,150,.12);a:finish(1,500,150,.18,false);check(shots(a)==0,'returning swipe never fires') end
local a=fresh();a:begin(1,500,150,0,'look',45,true);check(a:step(.33,true).held==nil,'hold waits threshold');check(a:step(.35,true).held.screen,'automatic hold ray');a:finish(1,500,150,.8,false);check(shots(a)==0 and not a:step(.9,true).held,'hold release no extra tap')
a=fresh();a:begin(1,500,150,0,'look',45,false);check(a:step(.7,false).held==nil,'semi never repeats on hold');a:finish(1,500,150,.8,false);check(shots(a)==0,'long semi press is not a tap')
-- Quick repeats use per-touch identity rather than the last global contact.
a=fresh();for i=1,12 do local now=i*.18;a:begin(i,530,170,now,'look',45,false);a:finish(i,530,170,now+.08,false) end check(shots(a)==12,'rapid distinct taps')
-- Left outer gesture: ordinary movement and sprint never silently fire.
a=fresh({fireLayout='Left'}) a:begin('move',100,260,0,'move',50,true)
a:move('move',100,207,.1);local out=a:step(.5,true);check(out.sprint and not out.held and shots(a)==0,'ordinary movement not fire')
a:begin('look',500,150,.5,'look',50,true);a:move('look',545,153,.6)
a:move('move',100,180,.6);check(a:step(.7,true).held==nil,'outer must dwell');out=a:step(.84,true)
check(out.held~=nil and out.y<-.9 and a.touches.look~=nil and shots(a)==1,'two contacts move look and fire')
a:move('move',145,260,.9);check(a:step(.95,true).held~=nil,'armed gesture preserves strafe')
a:move('move',100,260,1);check(a:step(1.1,true).held==nil,'center stops fire')
a:finish('move',100,260,1.2,false);check(a:step(1.3,true).x==0,'release stops movement')
-- Separate pad cannot steal a captured joystick; toggle survives starting movement.
a=fresh({fireLayout='Left',leftGesture='Pad'});a:begin('move',100,260,0,'move',50,true);a:move('move',100,210,.1);a:begin('pad',210,150,.2,'fire',50,true);check(a:step(.3,true).y<-.9 and a:step(.3,true).held~=nil,'independent pad preserves captured movement');a:finish('pad',210,150,.4,false);check(a.moveOwner=='move','pad release leaves joystick')
a=fresh({fireLayout='Left',leftGesture='Toggle'});a:begin(1,200,170,0,'fire',50,true);a:finish(1,200,170,.1,false);check(a:step(.2,true).held~=nil,'toggle stays on');a:begin(2,100,270,.3,'move',50,true);a:move(2,100,220,.4);check(a:step(.5,true).held~=nil,'toggle plus movement');a:cancel('reload');check(a:step(.6,true).held==nil and next(a.touches)==nil,'reload cancels toggle and captures')
-- Classic fire + drag uses the fire contact to turn while moving.
a=fresh({fireLayout='Classic'});a:begin('move',100,260,0,'move',50,true);a:move('move',95,210,.05);a:begin('fire',500,230,.1,'fire',50,true);a:move('fire',550,220,.2);out=a:step(.2,true);check(out.held and out.lookX==50 and out.y<-.9,'classic two-thumb fire and drag')
-- UI actions, reserved regions, cancellation and end from an old lifecycle cannot fire.
for _,reason in ipairs({'menu','focus','down','respawn','phase','travel','reload','swap'}) do local b=fresh();b:begin(1,500,150,0,'look',50,true);b:cancel(reason);b:finish(1,500,150,.1,false);check(shots(b)==0 and b:step(1,true).held==nil,'cancel '..reason) end
for _,role in ipairs({'RELOAD','SWAP','AIM','MELEE','G','reserved'}) do local b=fresh();b:begin(1,500,150,0,role,50,true);b:finish(1,500,150,.1,false);check(shots(b)==0,'UI action never fires '..role) end
a=fresh();a:begin(1,500,150,0,'look',50,true);a:finish(1,500,150,.1,true);check(shots(a)==0,'cancelled contact no tap')
-- Safe-area local geometry on phones, tall portrait screens and tablets.
for _,size in ipairs({{568,280},{640,320},{740,340},{800,360},{360,740},{1024,700},{1280,760}}) do for _,mode in ipairs({'Tap','Left','Classic'}) do for _,mirrored in ipairs({false,true}) do
 local s=Settings.resolve({fireLayout=mode,leftHanded=mirrored});local l=Layout.build(size[1],size[2],s)
 check(#Layout.overlaps(l,s)==0,'default control rectangles do not overlap '..size[1]..'x'..size[2]..' '..mode)
 local rects={l.move,l.fire};for _,r in pairs(l.buttons) do table.insert(rects,r) end
 for _,r in ipairs(rects) do check(r.x>=0 and r.y>=0 and r.x+r.w<=size[1] and r.y+r.h<=size[2],'safe rectangle') end
 local r=l.move;check(Layout.role(l,s,r.x+r.w/2,r.y+r.h/2)=='move','move hit testing')
 local x=mirrored and size[1]*.28 or size[1]*.58;check(Layout.role(l,s,x,size[2]*.25)=='look','broad look')
end end end
for k,v in pairs(Settings.defaults) do check(Settings.valid(k,v),'default settings '..k) end
check(not Settings.valid('fireLayout','AutoAimBot') and not Settings.valid('hudMoveX',0/0),'reject malformed preferences')
print('Touch behavior and safe-layout assertions passed:',count)
-- Reload/swap preserve movement and look, but require a fresh firing gesture.
local b=fresh({fireLayout='Left'});b:begin('move',100,260,0,'move',50,true);b:move('move',100,180,.1);b:step(.4,true);b:drain()
b:cancelFire('reload');check(b:step(.5,true).y<-.9 and b:step(.5,true).held==nil,'reload preserves movement, cancels fire')
b:move('move',100,175,.6);check(b:step(1,true).held==nil,'outer must recenter after reload')
b:move('move',100,260,1.1);b:move('move',100,180,1.2);check(b:step(1.5,true).held~=nil,'new outer gesture rearms')
b=fresh();b:begin(1,500,150,0,'look',50,true);b:step(.4,true);b:cancelFire('reload');b:move(1,520,150,.5);local o=b:step(.6,true);check(o.lookX>0 and o.held==nil,'reload permits look with same thumb');b:finish(1,520,150,.7,false);check(shots(b)==0,'old look contact cannot fire on release after reload')
print('Touch reload continuity total assertions:',count)
