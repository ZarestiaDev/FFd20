-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(bFocus)
	local w = createWindow();
	if w and bFocus then
		w.name.setFocus();
	end
	return w;
end

function deleteAll()
	DB.deleteChildren(getDatabaseNode());
end
