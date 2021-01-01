
-- this is a hack to prevent drifter hallucinations because they cause WEIRD bugs for some reason....
--[[
if Server then

	local oldPerform = HallucinationCloud.Perform
    function HallucinationCloud:Perform()
	
        local drifter = GetEntitiesForTeamWithinRange("Drifter", self:GetTeamNumber(), self:GetOrigin(), HallucinationCloud.kRadius)[1]
        if drifter then
			drifter.timeLastHallucinated = Shared.GetTime()
		end
		
		oldPerform(self)
		
	end
	
end
]]--