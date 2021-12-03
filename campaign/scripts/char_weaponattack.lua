-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSourceUpdate()
	local nodeWin = window.getDatabaseNode();
	local nType = DB.getValue(nodeWin, "type", 0);
	local sAttackStat = DB.getValue(nodeWin, "attackstat", "");
	
	local nValue = calculateSources() + (modifier[1] or 0);

	nValue = nValue + DB.getValue(nodeWin, "...attackbonus.base", 0);

	if sAttackStat == "" then
		if nType == 2 then
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.grapple.ability", "");
		elseif nType == 1 then
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.ranged.ability", "");
		else
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.melee.ability", "");
		end
	end
	if sAttackStat == "" then
		if nType == 2 then
			sAttackStat = "strength";
		elseif nType == 1 then
			sAttackStat = "dexterity";
		else
			sAttackStat = "strength";
		end
	end
	nValue = nValue + DB.getValue(nodeWin, "...abilities." .. sAttackStat .. ".bonus", 0);
	
	if nType == 2 then
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.grapple.misc", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.grapple.size", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.grapple.temporary", 0);
	elseif nType == 1 then
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.ranged.misc", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.ranged.size", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.ranged.temporary", 0);
	else
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.melee.misc", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.melee.size", 0);
		nValue = nValue + DB.getValue(nodeWin, "...attackbonus.melee.temporary", 0);
	end

	setValue(nValue);
end

function action(draginfo)
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(window.getDatabaseNode());
	rAttack.modifier = getValue();
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1;
	
	ActionAttack.performRoll(draginfo, rActor, rAttack);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end			
