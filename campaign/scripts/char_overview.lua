-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	updateAdd();
	onLevelChanged();
	DB.addHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);
end

function onLevelChanged()
	CharManager.calcLevel(getDatabaseNode());
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		if StringManager.contains({"referenceclass", "referencerace", "referencedeity"}, sClass) then
			CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
			updateAdd();
			return true;
		end
	end
end

function updateAdd()
	local nodeChar = getDatabaseNode();
	if DB.getValue(nodeChar, "racelink", "") == "referencerace" then
		race_add.setVisible(false);
	end
	if DB.getValue(nodeChar, "deitylink", "") == "referencedeity" then
		deity_add.setVisible(false);
	end
end
