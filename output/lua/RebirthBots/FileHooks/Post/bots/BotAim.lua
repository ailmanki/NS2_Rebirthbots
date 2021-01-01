
local aimRandomness = 0.001

BotAim.viewAngle = math.rad(27)
BotAim.reactionTime = 0.50 -- was 0.30
BotAim.panicDistSquared = 2.0 * 2.0

local oldBotAim_UpdateAim = BotAim_UpdateAim
function BotAim_UpdateAim(self, target, targetAimPoint)
    local player = self.owner:GetPlayer()
	if player then
		local dist = player:GetEyePos():GetDistance(targetAimPoint)
		local d = dist * aimRandomness
		local t = Shared.GetTime()
		local randPoint = Vector(math.sin(t) * d - d*0.5,math.cos(t*1.08423) *  d - d*0.5,math.sin(t*1.024584) *  d - d*0.5)
		targetAimPoint = targetAimPoint + randPoint
	end
	return oldBotAim_UpdateAim(self, target, targetAimPoint)
end

function BotAim:UpdateAim(target, targetAimPoint)
    PROFILE("BotAim:UpdateAim")
    local player = self.owner:GetPlayer()
    local playerEyePos = player and player:GetEyePos()
    if playerEyePos and (playerEyePos:GetDistanceSquared(targetAimPoint) <= BotAim.panicDistSquared or
            IsPointInCone(targetAimPoint, playerEyePos, player:GetCoords().zAxis, BotAim.viewAngle)) then
        return BotAim_UpdateAim(self, target, targetAimPoint)
    else
        -- try to view the target anyways, even though we can't directly see it
        self.owner:GetMotion():SetDesiredViewTarget( targetAimPoint )
        return false
    end
end

function BotAim:GetReactionTime()
    local reducedReaction = self.owner.aimAbility * 0.1
    local gameInfoEnt = GetGameInfoEntity()
    local serverSkill = gameInfoEnt and gameInfoEnt:GetAveragePlayerSkill() -- Todo: Use enemy's team skill instead
	if serverSkill then
		reducedReaction = reducedReaction * Clamp((serverSkill-500)/4000, -1, 1)
	end
    return BotAim.reactionTime - reducedReaction
end

function BotAim_GetAimPoint(self, now, aimPoint)
    if gBotDebug:Get("aim") and gBotDebug:Get("spam") then
        Log("%s: getting aim point", self.owner)
    end

    local reactionTime = self:GetReactionTime()
    while #self.targetTrack > 1 do
        -- search for a pair of tracks where the oldest is old enough for us to shoot from
        local targetData1 = self.targetTrack[1]
        local targetData2 = self.targetTrack[2]
        local p1, t1, target1 = targetData1[1], targetData1[2], targetData1[3]
        local p2, t2, target2 = targetData2[1], targetData2[2], targetData2[3]
               
        if target1 ~= target2 or now - t1 > reactionTime + 0.5 or now - t2 > reactionTime then
            -- t1 can't be used to shot on t2 due to different target
            -- OR t1 is uselessly old 
            -- OR we can use 2 because t2 is > reaction time
            table.remove(self.targetTrack, 1)
        else
            -- .. ending up here with [ (reactionTime + 0.1) > t1 > reactionTime > t2 ]
            local dt = now - t1
            if dt > reactionTime then

                local mt = t2 - t1
                if mt > 0 then
                    local movementVector = (p2 - p1) / mt
                    local speed = movementVector:GetLength()
                    local result = p1 + movementVector * (dt)
                    if gBotDebug:Get("aim") then
						local delta = result - aimPoint
                        Log("%s: Aiming at %s, off by %s, speed %s (%s tracks)", self.owner, target1, delta:GetLength(), speed, #self.targetTrack)
                    end
                    return result
                end
            end
            if gBotDebug:Get("aim") and gBotDebug:Get("spam") then
                Log("%s: waiting for reaction time", self.owner)
            end
            return nil
        end
    end
    if gBotDebug:Get("aim") and gBotDebug:Get("spam") then
        Log("%s: no target", self.owner)
    end
    return nil
end