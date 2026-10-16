local P={}
function P.setup(physics)
    local groups={"DeadSignalPlayers","DeadSignalEnemies","DeadSignalCorpses","DeadSignalWindow","DeadSignalShots","DeadSignalBounds"}
    for _,group in ipairs(groups) do pcall(function() physics:RegisterCollisionGroup(group) end) end
    physics:CollisionGroupSetCollidable("DeadSignalPlayers","DeadSignalPlayers",false)
    physics:CollisionGroupSetCollidable("DeadSignalPlayers","DeadSignalEnemies",true)
    physics:CollisionGroupSetCollidable("DeadSignalEnemies","DeadSignalEnemies",true)
    for _,group in ipairs(groups) do physics:CollisionGroupSetCollidable("DeadSignalCorpses",group,false) end
    physics:CollisionGroupSetCollidable("DeadSignalCorpses","Default",true)
    physics:CollisionGroupSetCollidable("DeadSignalShots","DeadSignalWindow",false)
    for _,group in ipairs({"Default","DeadSignalEnemies","DeadSignalShots"}) do physics:CollisionGroupSetCollidable("DeadSignalBounds",group,false) end
    physics:CollisionGroupSetCollidable("DeadSignalBounds","DeadSignalPlayers",true)
end
return P
