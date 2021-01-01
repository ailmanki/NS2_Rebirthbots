
if Server then

	local configFileName = "RebirthBots.json"

	local defaultConfig = {
		even_teams_with_bots = false
		}

	local config = LoadConfigFile(configFileName, defaultConfig, true)


	function Server.GetRebirthBotsConfig(name)

		if config then
			return config[name]
		end

	end


    local oldEndGame = NS2Gamerules.EndGame
    function NS2Gamerules:EndGame(winningTeam, autoConceded)
    
        if self:GetGameState() == kGameState.Started then

            --remove commander bots that where added via the comm bot vote
            if self.removeCommanderBots then
                self.botTeamController:RemoveCommanderBots()
                self.removeCommanderBots = false
            end
            
        end
        oldEndGame(self, winningTeam, autoConceded)
    end

    local oldOnCreate = NS2Gamerules.OnCreate
    function NS2Gamerules:OnCreate()
		oldOnCreate(self)
		self:SetEvenTeamsWithBots(Server.GetRebirthBotsConfig("even_teams_with_bots"))
	end
    
    
    function NS2Gamerules:GetCanJoinTeamNumber(player, teamNumber)
	
		-- Every check below is disabled with cheats enabled
		if Shared.GetCheatsEnabled() then
			return true
		end
		
        local forceEvenTeams = Server.GetConfigSetting("force_even_teams_on_join")
        if forceEvenTeams then
            
            local team1Players, _, team1Bots = self.team1:GetNumPlayers()
            local team2Players, _, team2Bots = self.team2:GetNumPlayers()
			
			local team1Number = self.team1:GetTeamNumber()
			local team2Number = self.team2:GetTeamNumber()
	
			
			
            --Log("player.is_a_robot: %s", player.is_a_robot)
            
			-- only subtract bots IF we want to even teams with bots
			if Server.GetRebirthBotsConfig("even_teams_with_bots") then
				if not player.is_a_robot then
				  team1Players = team1Players - team1Bots
				  team2Players = team2Players - team2Bots
				end
			end
            
            if (team1Players > team2Players) and (teamNumber == team1Number) then
                Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(0), true)
                return false
            elseif (team2Players > team1Players) and (teamNumber == team2Number) then
                Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(0), true)
                return false
            end

        end

        -- Scenario: Veteran tries to join a team at rookie only server
        if teamNumber ~= kSpectatorIndex then --allow to spectate
            local isRookieOnly = Server.IsDedicated() and not self.botTraining and self.gameInfo:GetRookieMode()

            if isRookieOnly and player:GetSkillTier() > kRookieMaxSkillTier then
                Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(2), true)
                return false
            end
        end
        
        return true
        
    end
	
	
    function NS2Gamerules:SetEvenTeamsWithBots(evenTeams)
        self.botTeamController:SetEvenTeamsWithBots(evenTeams)
        self.botTeamController:UpdateBots()
    end

    
    --TODO: Remove this hack
    local oldUpdate = NS2Gamerules.OnUpdate
    local lastBotUpdate = 0
    function NS2Gamerules:OnUpdate(timePassed)
        oldUpdate(self, timePassed)
        if lastBotUpdate + 10 < Shared.GetTime() then
            lastBotUpdate = Shared.GetTime()
            self:UpdateBots()
        end
    end
end