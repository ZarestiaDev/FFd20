-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onHealthChanged()
	local nodeChar = getDatabaseNode();
	local sColor = ActorManagerFFd20.getPCSheetWoundColor(nodeChar);
	
	local nHPMax = DB.getValue(nodeChar, "hp.total", 0);
	local nHPWounds = DB.getValue(nodeChar, "hp.wounds", 0);
	local nHPCurrent = nHPMax - nHPWounds;
	DB.setValue(nodeChar, "hp.current", "number", nHPCurrent);

	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
end