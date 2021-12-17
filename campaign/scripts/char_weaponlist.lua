-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);

	onModeChanged();
end

function onListChanged()
	DB.removeHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);

	update();
end

function onChildAdded()
	onModeChanged();
	update();
end

function onModeChanged()
	local bPrepMode = (DB.getValue(window.getDatabaseNode(), "spellmode", "") == "preparation");
	for _,w in ipairs(getWindows()) do
		w.carried.setVisible(bPrepMode);
	end
	
	applyFilter();
end

function update()
	local bEditMode = window.getEditMode();
	for _,w in pairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus and w then
		w.name.setFocus();
	end
	return w;
end

function onDrop(x, y, draginfo)
	return CharManager.onActionDrop(draginfo, window.getDatabaseNode());
end

function onFilter(w)
	if (DB.getValue(window.getDatabaseNode(), "spellmode", "") == "combat") and (w.carried.getValue() < 2) then
		return false;
	end
	
	return true;
end
