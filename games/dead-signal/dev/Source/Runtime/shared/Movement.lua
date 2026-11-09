local M={}
-- Batch 2 tuning is shared by prediction and authority, not supplied by remotes.
M.tuning={walk=16,backward=9.5,strafe=10.5,sprint=24,marathonWalk=19,marathonSprint=28,
    ads=11,acceleration=40,forwardCone=math.cos(math.rad(30)),startStamina=12,
    drain=18,recover=24,inputLifetime=.6,burstAllowance=4}
function M.finite(v)
    return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z
        and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7
end
function M.flat(v) return M.finite(v) and Vector3.new(v.X,0,v.Z) or Vector3.zero end
function M.input(v)
    if not M.finite(v) or math.abs(v.Y)>.05 or v.Magnitude>1.05 then return nil end
    local flat=M.flat(v) return flat.Magnitude>1 and flat.Unit or flat
end
function M.facing(v,fallback)
    local flat=M.flat(v)
    if flat.Magnitude<.001 then flat=M.flat(fallback or Vector3.new(0,0,-1)) end
    return flat.Magnitude>.001 and flat.Unit or Vector3.new(0,0,-1)
end
function M.axes(move,facing)
    local flat=M.flat(move) local magnitude=math.min(1,flat.Magnitude)
    if magnitude<.05 then return 0,0,magnitude end
    local f=M.facing(facing) local right=Vector3.new(-f.Z,0,f.X) local unit=flat.Unit
    return unit:Dot(f),unit:Dot(right),magnitude
end
function M.policy(move,facing,state)
    state=state or {} local t=M.tuning
    if state.alive==false or state.blocked then return {speed=0,sprinting=false,reason="blocked"} end
    local forward,side,power=M.axes(move,facing)
    local base=state.aiming and t.ads or state.marathon and t.marathonWalk or t.walk
    -- Elliptical polar radius: no additive diagonal boost and no analog-speed
    -- multiplication here (Humanoid:Move already preserves stick magnitude).
    local factor=1
    if power>=.05 then
        local longitudinal=forward>=0 and 1 or t.backward/t.walk
        factor=1/math.sqrt((forward/longitudinal)^2+(side/(t.strafe/t.walk))^2)
    end
    local reason="ready"
    if state.aiming then reason="aiming"
    elseif state.reloading then reason="reload"
    elseif state.stale then reason="stale"
    elseif (state.wasSprinting and (state.stamina or 0)<=1) or (not state.wasSprinting and (state.stamina or 0)<t.startStamina) then reason="stamina"
    elseif power<.8 then reason="idle"
    elseif forward<=t.forwardCone then reason="direction" end
    local sprint=state.requested and reason=="ready" or false
    local speed=base*factor
    if state.stale then speed=math.min(speed,base*t.backward/t.walk) end
    if sprint then
        local x=math.clamp((forward-t.forwardCone)/(1-t.forwardCone),0,1)
        local blend=x*x*(3-2*x)
        speed=speed+((state.marathon and t.marathonSprint or t.sprint)-base)*factor*blend
    end
    return {speed=speed,sprinting=sprint,reason=reason,forward=forward,power=power}
end
function M.approach(previous,target,dt)
    if not previous then return target end
    -- Restrictions apply immediately; only acceleration may approach a cap.
    return math.min(target,previous+M.tuning.acceleration*math.clamp(dt,0,.1))
end
function M.stamina(value,maximum,sprinting,dt)
    return math.clamp(value+(sprinting and -M.tuning.drain or M.tuning.recover)*math.clamp(dt,0,1),0,maximum)
end
function M.audit(sample,position,now,speed)
    if not M.finite(position) then return false,sample.position end
    if not sample.position then sample.position=position sample.at=now sample.debt=0 return true,position end
    local dt=math.clamp(now-sample.at,0,1)
    local distance=M.flat(position-sample.position).Magnitude
    local debt=math.max(0,(sample.debt or 0)+distance-math.max(0,speed)*dt)
    sample.at=now
    local allowance=sample.allowance or M.tuning.burstAllowance
    if debt>allowance then
        -- Retain the debt on correction: resetting it would grant a renewable
        -- teleport/speed allowance every few packets.
        sample.debt=allowance sample.corrections=(sample.corrections or 0)+1
        return false,sample.position
    end
    sample.debt=debt sample.position=position return true,position
end
function M.camera(amount,now,shake,lowEffects,aiming)
    if lowEffects or aiming or type(shake)~="number" or shake~=shake then return Vector3.zero end
    local gain=math.clamp(shake,0,1)*math.clamp(amount,0,1)
    return Vector3.new(math.sin(now*10)*.008,math.sin(now*20)*.010,0)*gain
end
function M.noJump(humanoid,player)
    if player then player.AutoJumpEnabled=false end
    if not humanoid then return end
    humanoid.UseJumpPower=true humanoid.JumpPower=0 humanoid.JumpHeight=0 humanoid.AutoJumpEnabled=false humanoid.Jump=false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
    humanoid.MaxSlopeAngle=45
end
return M
