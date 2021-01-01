------------------------------------------
--  This is expensive.
--  It would be nice to piggy back off of LOSMixin, but that is delayed and also does not remember WHO can see what.
--  -- Fixed some bad logic.  Now, we simply look to see if the trace point is further away than the target, and if so,
--  It's a hit.  Previous logic seemed to assume that if the target itself wasn't hit (caused by the EngagementPoint not
--  being inside a collision solid -- the skulk for example moves around a lot) then it magically wasn't there anymore.
------------------------------------------
function GetBotCanSeeTarget(attacker, target)

    local p0 = attacker:GetEyePos()
    local p1 = target:GetEngagementPoint()
    local bias = 1.5 * 1.5 -- allow trace entity to be this far off and still say close enough

    local trace = Shared.TraceCapsule( p0, p1, 0.15, 0,
            CollisionRep.Damage, PhysicsMask.Bullets,
            EntityFilterTwo(attacker, attacker:GetActiveWeapon()) )
    --return trace.entity == target
    return trace.fraction == 1 or
        (trace.entity == target) or 
        ((trace.endPoint - p1):GetLengthSquared() <= bias) or
        (trace.entity and trace.entity.GetTeamNumber and target.GetTeamNumber and (trace.entity:GetTeamNumber() == target:GetTeamNumber()))

end

local kDistCheckTime = 3

-- this is also a VERY expensive function
local origGetMinPathDistToEntities = GetMinPathDistToEntities
function GetMinPathDistToEntities( fromEnt, toEnts )

    PROFILE("GetMinPathDistToEntities")

    local minDist
    local fromPos = fromEnt:GetOrigin()
    local fromEntId = fromEnt:GetId()
    local now = Shared.GetTime()
    
    if not fromEnt._pathDistances then
        fromEnt._pathDistances = {}
    end

    for i = 1, #toEnts do
        local toEnt = toEnts[i]
        local toEntId = toEnt:GetId()
        local dist = 0
        
        if not toEnt._pathDistances then
            toEnt._pathDistances = {}
        end
        
        if fromEnt._pathDistances[toEntId] and fromEnt._pathDistances[toEntId].validTill > now then
            --Log("Using cached fromEnt")
            dist = fromEnt._pathDistances[toEntId].dist
        elseif toEnt._pathDistances[fromEntId] and toEnt._pathDistances[fromEntId].validTill > now then
            --Log("Using cached toEnt")
            dist = toEnt._pathDistances[fromEntId].dist
        else
            --Log("Not using cache")
            -- Expensive !!!
            local path = PointArray()
            Pathing.GetPathPoints(fromPos, toEnt:GetOrigin(), path)
            dist = GetPointDistance(path)
            local distObj =  {
                dist = dist,
                validTill = now + kDistCheckTimeIntervall
            }
            fromEnt._pathDistances[toEntId] = distObj
            toEnt._pathDistances[fromEntId] = distObj
        end
        if not minDist or dist < minDist then
            minDist = dist
        end

    end

    return minDist


end
