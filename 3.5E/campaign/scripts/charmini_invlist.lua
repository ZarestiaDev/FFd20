-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	local sName1 = ItemManager.getSortName(w1.getDatabaseNode());
	local sName2 = ItemManager.getSortName(w2.getDatabaseNode());
	
	if sName1 == "" then
		if sName2 == "" then
			return nil;
		end
		return true;
	elseif sName2 == "" then
		return false;
	end
	
	if sName1 ~= sName2 then
		return sName1 > sName2;
	end
end

function onFilter(w)
	return (w.showonminisheet.getValue() ~= 0);
end

function addEntry(bFocus)
	return createWindow();
end
