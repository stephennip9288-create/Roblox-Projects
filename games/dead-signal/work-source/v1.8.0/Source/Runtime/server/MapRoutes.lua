-- Traversable routes are authored in Architecture, including the two unique diagonal links.
local R={}
function R.apply(map,_P,_S)
    map.routeObstacles={} map.navigationRevision=8
end
return R
