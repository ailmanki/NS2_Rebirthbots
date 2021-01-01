-- basically a copy of CombatUpgrade:GetIsHardCapped
-- but we start with numPlayersWithUpgrade = 1 instead of 0.
function CombatUpgrade:GetIsHardCappedForBots(player)
	
	-- Hard cap scale is expressed e.g. 1/5
	-- So if we have more than 1 player with this upgrade per 5 players we are hardcapped.
	-- Recalculate at the point someone tries to buy for accuracy.
	local hardCapScale = self:GetHardCapScale()
	if (hardCapScale > 0) then
		
		local id = self:GetId()
		local teamPlayers = GetEntitiesForTeam("Player", player:GetTeamNumber())
		local numInTeam = #teamPlayers
		local numPlayersWithUpgrade = 1
		
		for _, teamPlayer in ipairs(teamPlayers) do
			
			-- Skip dead players
			if (teamPlayer:GetIsAlive()) then
				
				if (teamPlayer:GetHasCombatUpgrade(id)) then
					numPlayersWithUpgrade = numPlayersWithUpgrade + 1
				end
			
			end
		
		end
		
		if numPlayersWithUpgrade >= math.ceil(hardCapScale * numInTeam) then
			return true
		else
			return false
		end
	
	else
		return false
	end

end