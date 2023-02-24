-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManagerFFd20.getPowerActorNode,
		fnUsePower = PowerManagerFFd20.usePower,
		fnParse = PowerManagerFFd20.parsePower,
		fnUpdateDisplay = PowerManagerFFd20.updatePowerDisplay,
	};
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);

	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManagerFFd20.getActionButtonIcons,
		fnGetText = PowerManagerFFd20.getActionText,
		fnGetTooltip = PowerManagerFFd20.getActionTooltip,
		fnPerform = PowerManagerFFd20.performAction,
	};
	PowerActionManagerCore.registerActionType("", tPowerActionHandlers);
	PowerActionManagerCore.registerActionType("cast", {});
	PowerActionManagerCore.registerActionType("damage", {});
	PowerActionManagerCore.registerActionType("heal", {});
	PowerActionManagerCore.registerActionType("effect", {});
end

function getPowerActorNode(node)
	return DB.getChild(node, ".......");
end
function usePower(node)
	local nodeSpellClass = DB.getChild(node, ".....");
	if not nodeSpellClass then
		return;
	end

	local nodeChar = PowerManagerFFd20.getPowerActorNode(node);
	local rActor = ActorManager.resolveActor(nodeChar);

	local nMPCurrent = DB.getValue(nodeSpellClass, "mp.current", 0);
	local nCost = DB.getValue(node, "...level", 0);
	
	local sMessage;
	if nCost > nMPCurrent then
		sMessage = string.format("%s\r[%d MP] [NOT ENOUGH MP AVAILABLE]", PowerManagerCore.getPowerName(node), nCost);
	else
		DB.setValue(nodeSpellClass, "mp.current", "number", nMPCurrent - nCost);
		sMessage = string.format("%s\r[%d MP]", PowerManagerCore.getPowerOutput(node), nCost);
		PowerManagerCore.performDefaultPowerUse(node);
	end

	ChatManager.Message(sMessage, ActorManager.isPC(rActor), rActor);
end
function parsePower(node)
	SpellManager.parseSpell(node);
end
function updatePowerDisplay(w)
	if not w.header or not w.header.subwindow then
		return;
	end
	if not w.header.subwindow.actionsmini then
		return;
	end

	w.header.subwindow.actionsmini.setVisible(true);
end

function getActionButtonIcons(node, tData)
	if tData.sType == "cast" then
		if tData.sSubRoll == "atk" then
			return "button_action_attack", "button_action_attack_down";
		elseif tData.sSubRoll == "clc" then
			return "button_roll", "button_roll_down";
		elseif tData.sSubRoll == "save" then
			return "button_roll", "button_roll_down";
		end
		return "button_roll", "button_roll_down";
	elseif tData.sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif tData.sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif tData.sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(node, tData)
	if tData.sType == "cast" then
		if tData.sSubRoll == "atk" then
			return SpellManager.getActionAttackText(node);
		elseif tData.sSubRoll == "clc" then
			return SpellManager.getActionCLText(node);
		elseif tData.sSubRoll == "save" then
			return SpellManager.getActionSaveText(node);
		end
		return "";
	elseif tData.sType == "damage" then
		return SpellManager.getActionDamageText(node);
	elseif tData.sType == "heal" then
		return SpellManager.getActionHealText(node);
	elseif tData.sType == "effect" then
		if tData.sSubRoll == "duration" then
			return SpellManager.getActionEffectDurationText(node);
		else
			return PowerActionManagerCore.getActionEffectText(node, tData);
		end
	end
	return "";
end
function getActionTooltip(node, tData)
	if tData.sType == "cast" then
		if tData.sSubRoll == "atk" then
			return string.format("%s: %s", Interface.getString("power_tooltip_attack"), PowerActionManagerCore.getActionText(node, tData));
		elseif tData.sSubRoll == "clc" then
			return string.format("%s: %s", Interface.getString("power_tooltip_cl"), PowerActionManagerCore.getActionText(node, tData));
		elseif tData.sSubRoll == "save" then
			return string.format("%s: %s", Interface.getString("power_tooltip_save"), PowerActionManagerCore.getActionText(node, tData));
		end
		local tTooltip = {};
		table.insert(tTooltip, Interface.getString("power_tooltip_cast"));
		local sCL = SpellManager.getActionCLText(node)
		if sCL ~= "" then
			table.insert(tTooltip, string.format("%s: %s", Interface.getString("power_tooltip_cl"), sCL));
		end
		local sAttack = SpellManager.getActionAttackText(node);
		if sAttack ~= "" then
			table.insert(tTooltip, string.format("%s: %s", Interface.getString("power_tooltip_attack"), sAttack));
		end
		local sSave = SpellManager.getActionSaveText(node);
		if sSave ~= "" then
			table.insert(tTooltip, string.format("%s: %s", Interface.getString("power_tooltip_save"), sSave));
		end
		return table.concat(tTooltip, "\r");
	elseif tData.sType == "damage" then
		return string.format("%s: %s", Interface.getString("power_tooltip_damage"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "heal" then
		return string.format("%s: %s", Interface.getString("power_tooltip_heal"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectTooltip(node, tData);
	end
	return "";
end
function performAction(node, tData)
	SpellManager.onSpellAction(tData.draginfo, node, tData and tData.sSubRoll);
end
