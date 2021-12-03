-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeChar = window.getDatabaseNode();
	if nodeChar then
		local nodeClass = nodeChar.createChild("classes");
		if nodeClass then
			nodeClass.onChildUpdate = updateValue;
		end
	end

	updateValue();
end

function updateValue()
	setValue(CharManager.getClassLevelSummary(window.getDatabaseNode()));
end
