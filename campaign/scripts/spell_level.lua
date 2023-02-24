-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local nLevel = tonumber(string.sub(DB.getName(node), 6)) or 0;
	DB.setValue(node, "level", "number", nLevel);

	self.updateLabel();
	
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("menu_addspell"), "insert", 5);
	end
end

local _bShow = true;
function getFilter()
	return _bShow;
end
function setFilter(bValue)
	_bShow = bValue;
end

function updateLabel()
	local sLabel = "Level " .. DB.getValue(getDatabaseNode(), "level", 0);
	
	label.setValue(sLabel);
end

function onMenuSelection(selection, subselection)
	if selection == 5 then
		spells.addEntry(true);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if DB.getChildCount(spells.getDatabaseNode(), "") == 0 then
		spells.addEntry(true);
		return true;
	end

	spells.setVisible(not spells.isVisible());
	return true;
end
