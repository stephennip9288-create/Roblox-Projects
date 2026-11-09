local M={}
function M.noJump(humanoid,player)
    if player then player.AutoJumpEnabled=false end
    if not humanoid then return end
    humanoid.UseJumpPower=true humanoid.JumpPower=0 humanoid.JumpHeight=0 humanoid.AutoJumpEnabled=false humanoid.Jump=false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
    humanoid.MaxSlopeAngle=45
end
return M
