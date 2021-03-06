-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function recalculateHP()
	local nodeChar = getDatabaseNode();
	local nAbilityMod = DB.getValue(nodeChar, "abilities.constitution.bonus", 0);
	local nHD = DB.getValue(nodeChar, "level", 0);
	local nAHP = DB.getValue(nodeChar, "hp.ability", 0);
	local nCHP = DB.getValue(nodeChar, "hp.class", 0);
	local nFHP = DB.getValue(nodeChar, "hp.favored", 0);
	local nMHP = DB.getValue(nodeChar, "hp.misc", 0);
	nAHP = nAbilityMod * nHD;

	DB.setValue(nodeChar, "hp.ability", "number", nAHP);

	local nHP = nAHP + nCHP + nFHP + nMHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
end

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