
local oldOnCreate = Hallucination.OnCreate
function Hallucination:OnCreate()
	oldOnCreate(self)
	-- fix vanilla issue
	
	self:OnUpdate(0)
	
end