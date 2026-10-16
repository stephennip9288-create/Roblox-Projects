local A={}
function A.admitted(state)
    return state.participating and (state.status=="Alive" or state.status=="Down" or state.status=="Eliminated")
end
function A.ready(state,root,world,mapReady,supported)
    if state.travelling then return false end
    if state.phase=="Results" or state.status=="Rejected" then return true end
    local dispatch=state.role~="Match" and not state.participating
    if not dispatch and not A.admitted(state) then return false end
    return root and world and (dispatch or mapReady) and (dispatch or state.status~="Alive" or supported) and true or false
end
return A
