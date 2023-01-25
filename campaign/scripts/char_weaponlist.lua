-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
end

function onListChanged()
	DB.removeHandler(getDatabaseNode(), "onChildAdded", onChildAdded);

	update();
end

function onChildAdded()
	update();
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
	if (w.carried.getValue() < 2) then
		return false;
	end
	
	return true;
end
