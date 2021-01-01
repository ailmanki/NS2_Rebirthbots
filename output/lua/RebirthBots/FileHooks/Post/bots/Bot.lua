
function Bot:UpdateTeam()
    PROFILE("Bot:UpdateTeam")

    local player = self:GetPlayer()

    -- Join random team (could force join if needed but will enter respawn queue if game already started)
    if player and player:GetTeamNumber() == 0 then
    
        if not self.team then
            self.team = math.random(1, 2)
        end

        local gamerules = GetGamerules()
        if gamerules and gamerules:GetCanJoinTeamNumber(player, self.team) or Shared.GetCheatsEnabled() then
            gamerules:JoinTeam(player, self.team, true)
        end
        
    end

end