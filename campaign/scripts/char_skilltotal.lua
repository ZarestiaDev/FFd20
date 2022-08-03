-- Function call and handler check whether skill ranks get adjusted
function onInit()
	CalculateSkills()
	DB.addHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", CalculateSkills)
end

-- Closing handler check whether skill ranks get adjusted
function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", CalculateSkills)
end

-- Add all class skills together
function CalculateSkills()
	local nodeChar = getDatabaseNode()
	local tClasses = DB.getChildren(nodeChar.getChild("classes"))
	local nTotalSkillRanks = 0
	
	for _,v in pairs(tClasses) do
		local nSkillRanks = DB.getValue(v, "skillranks", 0)
		nTotalSkillRanks = nTotalSkillRanks + nSkillRanks
	end
	
	DB.setValue(nodeChar, "skillpoints.total", "number", nTotalSkillRanks)
end