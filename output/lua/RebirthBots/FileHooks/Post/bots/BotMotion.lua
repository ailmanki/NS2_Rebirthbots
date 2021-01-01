
local maxDistOffPath = 0.65
local minDistToUnstuck = 3.0
local timeToBeStuck = 60.0
local rotateSpeedRatio = 1.0

function BotMotion:OnGenerateMove(player)
    PROFILE("BotMotion:OnGenerateMove")

    local currentPos = player:GetOrigin()
    local onGround = player.GetIsOnGround and player:GetIsOnGround()
    local eyePos = player:GetEyePos()
    local isSneaking = (player.GetCrouching and player:GetCrouching() and player:isa("Marine")) or (player:isa("Skulk") and player.movementModiferState)
    local isGroundMover = player:isa("Marine") or player:isa("Exo") or player:isa("Onos")
    local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())
    local doJump = false
    local groundPoint = Pathing.GetClosestPoint(currentPos)
	local isStuck = false

    local delta = currentPos - self.lastMovedPos
    local distToTarget = 100
    local now = Shared.GetTime()
    ------------------------------------------
    --  Update ground motion
    ------------------------------------------

    local moveTargetPos = self:ComputeLongTermTarget(player)

    if moveTargetPos ~= nil and not player:isa("Embryo") then

        distToTarget = currentPos:GetDistance(moveTargetPos)

        if distToTarget <= 0.01 then

            -- Basically arrived, stay here
            self.currMoveDir = Vector(0,0,0)

        else

            local updateMoveDir = self.nextMoveUpdate <= now
            local unstuckDuration = 1.2
            isStuck = delta:GetLength() < 1e-2 or self.unstuckUntil > now
			
			if not isGroundMover and not isStuck and not isSneaking then
				if not self.lastFlyingPos then
					self.lastFlyingPos = currentPos
					self.lastFlyingTime = Shared.GetTime()
				else
					if self.lastFlyingTime + 3 < Shared.GetTime() then
						local flyingDelta = currentPos - self.lastFlyingPos
						if flyingDelta:GetLength() < 2.5 then
							isStuck = true
							self.unstuckUntil = now + unstuckDuration * math.random()
						else
							self.lastFlyingPos = currentPos
							self.lastFlyingTime = Shared.GetTime()
						end
					end
				end
			end
            
            if self.desiredMoveTarget and isGroundMover and not isStuck then
                local moveTargetDelta = self.desiredMoveTarget - player:GetOrigin()
                local vertDist = math.abs(moveTargetDelta.y)
                if vertDist > 3.5 and vertDist > moveTargetDelta:GetLengthXZ() then
                    isStuck = true
                    -- but not actually stuck! we just want the random movement/jumping
                    self.lastStuckPos = nil
                    self.lastStuckTime = nil
                    self.unstuckUntil = now + unstuckDuration * math.random()
                end
            end
			
			
            if updateMoveDir then

               self.nextMoveUpdate = now + kPlayerBrainTickFrametime
                -- If we have not actually moved much since last frame, then maybe pathing is failing us
                -- So for now, move in a random direction for a bit and jump
               if isStuck and not isSneaking then
               
                    if not self.lastStuckPos or (currentPos - self.lastStuckPos):GetLength() > minDistToUnstuck then
                        self.lastStuckPos = currentPos
                        self.lastStuckTime = now
                    end
                    
                    if self.unstuckUntil < now then
						-- Move randomly during Xs
						self.unstuckUntil = now + unstuckDuration * math.random()

						self.currMoveDir = GetRandomDirXZ()

						if isGroundMover then
							doJump = true
							self.lastJumpTime = Shared.GetTime()
							self:SetDesiredMoveDirection(self.currMoveDir)
						else
							self.currMoveDir.y = math.sin(Shared.GetTime() * 0.3) * 4 - 2
							self.desiredViewTarget = nil
							groundPoint = nil
						end

							 
                    end

                elseif distToTarget <= 1.0 then

                    -- Optimization: If we are close enough to target, just shoot straight for it.
                    -- We assume that things like lava pits will be reasonably large so this shortcut will
                    -- not cause bots to fall in
                    -- NOTE NOTE STEVETEMP TODO: We should add a visiblity check here. Otherwise, units will try to go through walls
                    self.currMoveDir = (moveTargetPos - currentPos):GetUnit()

                    if self.lastStuckPos then
                        self.lastStuckPos = nil
                        self.lastStuckTime = nil
                    end
                    
                else

                    -- We are pretty far - do the expensive pathing call
                    self:GetOptimalMoveDirection(currentPos, moveTargetPos)
                    
                    if self.lastStuckPos and (currentPos - self.lastStuckPos):GetLength() > minDistToUnstuck then
                        self.lastStuckPos = nil
                        self.lastStuckTime = nil
                    end
                    
                        
                    if isSneaking then
                        
                        local time = Shared.GetTime()
                        local strafeTarget = self.currMoveDir:CrossProduct(Vector(0,1,0))
                        strafeTarget:Normalize()
                        
                        -- numbers chosen arbitrarily to give some appearance of sneaking
                        strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 1.5 ) + math.sin(time * 0.2 ) > 0 , -1, 1)
                        strafeTarget = (strafeTarget + self.currMoveDir):GetUnit()
                        
                        if strafeTarget:GetLengthSquared() > 0 then
                            self.currMoveDir = strafeTarget
                        end
                    end
                    
                end

                self.currMoveTime = Shared.GetTime()

            end

            self.lastMovedPos = currentPos
        end


    else

        -- Did not want to move anywhere - stay still
        self.currMoveDir = Vector(0,0,0)

    end
    
    -- don't move there if it's off pathing
    if self.desiredMoveDirection and distToTarget <= 2.0  then
        local roughNextPoint = currentPos + self.currMoveDir * delta:GetLength()
        local closestPoint = Pathing.GetClosestPoint(roughNextPoint)
        if closestPoint and groundPoint and
            ((closestPoint - roughNextPoint):GetLengthXZ() > maxDistOffPath) and 
            ((groundPoint - currentPos):GetLengthXZ() > 0.1) then
            self.currMoveDir = (closestPoint - currentPos):GetUnit()
        end
    end

    ------------------------------------------
    --  View direction
    ------------------------------------------
    local desiredDir
    if self.desiredViewTarget ~= nil then

        -- Look at target
        desiredDir = (self.desiredViewTarget - eyePos):GetUnit()

    elseif self.currMoveDir:GetLength() > 1e-4 and not isStuck then

        -- Look in move dir
        if self:isa("Marine") or self:isa("Exo") then
            desiredDir = self:GetCurPathLook(eyePos) -- self.currMoveDir
        else
            desiredDir = self.currMoveDir
			if isGroundMover then
				desiredDir.y = 0.0  -- pathing points are slightly above ground, which leads to funny looking-up
			end
            desiredDir = desiredDir:GetUnit()
        end
        
        if player:isa("Exo") or player:isa("Marine") or player:isa("Fade") then
            if doJump or not onGround then
                desiredDir.y = 0.2
            else
                desiredDir.y = 0.0  -- pathing points are slightly above ground, which leads to funny looking-up
            end
        end
        
        if player:isa("Lerk") and isInCombat then
        
            -- this is expensive!!!
            local trace = Shared.TraceRay(eyePos, eyePos + desiredDir * 3, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterAll())
            
            if trace.fraction >= 1 then
                local time = Shared.GetTime()
                desiredDir.y =  (math.sin(time * 5.78 ) + math.cos(time * 8.35 )) * 0.9
            else
                desiredDir = self:GetCurPathLook(eyePos)
                desiredDir.y = desiredDir.y - 0.3
            end
        elseif (player:isa("Lerk") or player:isa("Fade") or player:isa("Skulk")) and groundPoint then
        
            if (currentPos - groundPoint).y > 1.5 then
                desiredDir.y = -0.2
            elseif(currentPos - groundPoint).y < 0.6 then
                desiredDir.y = 0.2
            else
                desiredDir.y = 0.0
            end
			
        end
        desiredDir = desiredDir:GetUnit()

    else
        -- leave it alone
    end
    
    if desiredDir then
        -- TODO: change the frametime to the actual time spent
        -- since we could be in combat doing 26fps or out of combat and doing 8fps
        local slerpSpeed = kPlayerBrainTickFrametime * rotateSpeedRatio
        
        local currentYaw = player:GetViewAngles().yaw
        local targetYaw = GetYawFromVector(desiredDir)
        
        local xzLen = desiredDir:GetLengthXZ()
        
        local newYaw = SlerpRadians(currentYaw, targetYaw, slerpSpeed)
        local inBetween = Vector(math.sin(newYaw) * xzLen, desiredDir.y, math.cos(newYaw) * xzLen)
        self.currViewDir = inBetween:GetUnit()
        
    end
    
    if player:isa("Exo") and (self.lastJumpTime and self.lastJumpTime > Shared.GetTime() - 2) then
        doJump = true
    end
    
    if self.lastStuckPos and self.lastStuckTime and 
        (currentPos - self.lastStuckPos):GetLength() < minDistToUnstuck and
        self.lastStuckTime + timeToBeStuck < now then
        
        -- we've been stuck for a very long time... we can't get out
        player:Kill(nil, nil, player:GetOrigin())
        self.lastStuckPos = nil
        self.lastStuckTime = nil
    end

    return self.currViewDir, self.currMoveDir, doJump

end


function BotMotion:GetCurPathLook(eyePos)
    local lookDir = self.currMoveDir
    local lookDistance = 4
    if self.desiredViewTarget then
        lookDir = (self.desiredViewTarget - eyePos):GetUnit()
    end
    if self.desiredViewTarget and (self.desiredViewTarget - eyePos):GetLength() < lookDistance then
        -- leave it
    elseif self.currPathPoints ~= nil then
        local iter = self.currPathPointsIt + 1
        while iter < #self.currPathPoints
                and self.currPathPoints[iter]:GetDistanceTo(eyePos) < lookDistance
        do
            iter = iter + 1
        end
        if iter < #self.currPathPoints then
            lookDir = (self.currPathPoints[iter] - eyePos):GetUnit()
        end
    end
    return lookDir
end


local function GetNearestPowerPoint(origin)

    local nearest
    local nearestDistance = 0

    for _, ent in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do

		local distance = (ent:GetOrigin() - origin):GetLength()
		if nearest == nil or distance < nearestDistance then

			nearest = ent
			nearestDistance = distance

		end
		
    end

    return nearest

end

------------------------------------------
--  Expensive pathing call
------------------------------------------
function BotMotion:GetOptimalMoveDirection(from, to)
    PROFILE("BotMotion:GetOptimalMoveDirection")

    local minDistOpti = 4 -- Distance below which the next point in the path is removed.
    local newMoveDir, reachable

    if self.currPathPoints == nil or self.forcePathRegen or from:GetDistanceTo(to) < minDistOpti then
        -- Generate a full path to follow (expansive)
        self.currPathPoints = PointArray()
        self.currPathPointsIt = 1
        self.forcePathRegen = nil
        reachable = Pathing.GetPathPoints(from, to, self.currPathPoints)
        if reachable and #self.currPathPoints > 0 then
            newMoveDir = (self.currPathPoints[1] - from):GetUnit()
        end
    else

        -- Follow the path we have generated earlier: It is much much faster to compute a
        -- direction using a small portion of the path, and reliable since it gaves us the
        -- real direction to use (regardless of any displacement, pos we could be in)
        if self.currPathPoints and #self.currPathPoints > 0 then
            -- Increase iterator forward for each points of the path below X meters
            local total = 0
            local last
            while self.currPathPointsIt < #self.currPathPoints
                    and self.currPathPoints[self.currPathPointsIt]:GetDistanceTo(from) + total < minDistOpti
            do
                if last then
                    total = total + last:GetDistanceTo(self.currPathPoints[self.currPathPointsIt])
                end
                last = self.currPathPoints[self.currPathPointsIt]
                self.currPathPointsIt = self.currPathPointsIt + 1
            end

            if self.currPathPointsIt == #self.currPathPoints then
                self.currPathPoints = nil
            else
                -- Compute reliable direction using previously generated path
                local pathPoints = PointArray()
                reachable = Pathing.GetPathPoints(from, self.currPathPoints[self.currPathPointsIt], pathPoints)
                if reachable and #pathPoints > 0 then
                    newMoveDir = (pathPoints[1] - from):GetUnit()
                end
            end
        end
    end

    if not newMoveDir and (to - from):GetLength() > 10.0 then -- first fallback
        
        --Log("We can't path, so we need a temp path")
                
        local pathPoints = PointArray()
        local nearestResNode = GetNearest(to, "ResourcePoint")
        if nearestResNode then
            reachable = Pathing.GetPathPoints(from, nearestResNode:GetOrigin(), pathPoints)
            if reachable and #pathPoints > 0 then
                newMoveDir = (pathPoints[1] - from):GetUnit()
            end
        end
        
    end

    if not newMoveDir and (to - from):GetLength() > 10.0 then -- second fallback
                
        local pathPoints = PointArray()
        local nearestPower = GetNearestPowerPoint(to)
        if nearestPower then
            reachable = Pathing.GetPathPoints(from, nearestPower:GetOrigin(), pathPoints)
            if reachable and #pathPoints > 0 then
                newMoveDir = (pathPoints[1] - from):GetUnit()
            end
        end
        
    end
    
    if not newMoveDir then -- third fallback
        newMoveDir = (to-from):GetUnit()
    end

    self.currMoveDir = newMoveDir
end
