local D={}
D.Bays={
    {id=1,name="SOLO 01",min=1,max=1,x=-64,z=-486},
    {id=2,name="SOLO 02",min=1,max=1,x=0,z=-486},
    {id=3,name="CREW 01",min=2,max=4,x=64,z=-486},
    {id=4,name="CREW 02",min=2,max=4,x=-64,z=-410},
    {id=5,name="CREW 03",min=2,max=4,x=0,z=-410},
    {id=6,name="CREW 04",min=2,max=4,x=64,z=-410},
}
function D.has(roster,userId) for _,id in ipairs(roster or {}) do if id==userId then return true end end return false end
function D.validRoster(roster,max)
    if type(roster)~="table" or #roster<1 or #roster>(max or 4) then return false end
    local seen={} for _,id in ipairs(roster) do
        if type(id)~="number" or id%1~=0 or id==0 or seen[id] then return false end seen[id]=true
    end return true
end
function D.canStart(bay,userId,count)
    if bay.leader~=userId then return false,"Only the crew leader can start." end
    if bay.state~="Forming" and bay.state~="Held" then return false,"This bay is already departing." end
    if count<bay.min then return false,"This crew bay needs at least two operators. Use a solo bay to play alone." end
    return true
end
function D.ticketValid(ticket,userId,placeId,map,now)
    return type(ticket)=="table" and type(ticket.expires)=="number" and ticket.expires>now
        and ticket.placeId==placeId and ticket.map==map and D.validRoster(ticket.roster)
        and D.has(ticket.roster,userId) and ticket.cancelled~=true
end
function D.regroupValid(ticket,userId,lobbyId,sourceId,now)
    return type(ticket)=="table" and type(ticket.expires)=="number" and ticket.expires>now and ticket.lobbyPlaceId==lobbyId
        and ticket.placeId==sourceId and D.has(ticket.roster,userId)
        and type(ticket.returnAllowed)=="table" and ticket.returnAllowed[tostring(userId)]==true
end
return D
