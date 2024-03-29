-- Function call and handler check whether skill ranks get adjusted
function onInit()
	calculateSkills();
	DB.addHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", calculateSkills);
end

-- Closing handler check whether skill ranks get adjusted
function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", calculateSkills);
end

-- Add all class skills together
function calculateSkills()
	local nodeChar = getDatabaseNode();
	local nTotalSkillRanks = 0;
	
	for _,nodeClass in pairs(DB.getChildList(DB.getChild(nodeChar, "classes"))) do
		local nSkillRanks = DB.getValue(nodeClass, "skillranks", 0);
		nTotalSkillRanks = nTotalSkillRanks + nSkillRanks;
	end
	
	DB.setValue(nodeChar, "skillpoints.total", "number", nTotalSkillRanks);
end