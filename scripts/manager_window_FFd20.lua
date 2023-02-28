-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Rewrite CoreRPG function because otherwise spells records don't work for players

local setInitialOrderOriginal;

function onInit()
    setInitialOrderOriginal = WindowManager.setInitialOrder;
    WindowManager.setInitialOrder = setInitialOrder;
end

function setInitialOrder(w)
	if not w or not w.windowlist then
		return;
	end

	local node = w.getDatabaseNode();
	if not node or (DB.getValue(node, "order", 0) ~= 0) or not DB.isOwner(node) then
		return;
	end

	local tOrder = {};
	for _,v in ipairs(DB.getChildList(w.windowlist.getDatabaseNode(), "")) do
		tOrder[DB.getValue(v, "order", 0)] = true;
	end
	local i = 1;
	while tOrder[i] do
		i = i + 1;
	end

	DB.setValue(node, "order", "number", i);
end