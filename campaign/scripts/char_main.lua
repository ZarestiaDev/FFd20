-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onConChanged()
	local nodeChar = getDatabaseNode();
	local nAbilityMod = DB.getValue(nodeChar, "abilities.constitution.bonus", 0);
	local nHD = DB.getValue(nodeChar, "level", 0);
	local nAHP = DB.getValue(nodeChar, "hp.ability", 0);
	local nCHP = DB.getValue(nodeChar, "hp.class", 0);
	nAHP = nAbilityMod * nHD;

	DB.setValue(nodeChar, "hp.ability", "number", nAHP);

	local nHP = nAHP + nCHP;
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