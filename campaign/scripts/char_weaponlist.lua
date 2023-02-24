-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

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
	local bEquipped = (w.carried.getValue() >= 2);
	
	return (bEquipped or (DB.getValue(window.getDatabaseNode(), "spellmode", "") ~= "combat"));
end
