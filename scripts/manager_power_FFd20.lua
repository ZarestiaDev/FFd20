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

	PowerActionManagerCore.registerActionTypes({ "cast", "damage", "heal", "effect" });
	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManagerFFd20.getActionButtonIcons,
		fnGetText = PowerManagerFFd20.getActionText,
		fnGetTooltip = PowerManagerFFd20.getActionTooltip,
		fnPerform = PowerManagerFFd20.performAction,
	};
	PowerActionManagerCore.registerActionHandlers(tPowerActionHandlers);
end

function getPowerActorNode(node)
	return DB.getChild(node, ".......");
end
function usePower(node)
	local nodeSpellClass = DB.getChild(node, ".....");
	if not nodeSpellClass then
		return;
	end

	if DB.getValue(nodeSpellClass, "castertype", "") ~= "points" then
		PowerManagerCore.performDefaultPowerUse(node);
		return;
	end

	local nodeChar = PowerManagerFFd20.getPowerActor(node);
	local rActor = ActorManager.resolveActor(nodeChar);

	local nPP = DB.getValue(nodeSpellClass, "points", 0);
	local nPPUsed = DB.getValue(nodeSpellClass, "pointsused", 0);
	local nCost = DB.getValue(node, "cost", 0);
	
	local sMessage;
	if (nPP - nPPUsed) < nCost then
		sMessage = string.format("%s\r[%d PP] [INSUFFICIENT PP AVAILABLE]", PowerManagerCore.getPowerName(node), nCost);
	else
		DB.setValue(nodeSpellClass, "pointsused", "number", nPPUsed + nCost);
		sMessage = string.format("%s\r[%d PP]", PowerManagerCore.getPowerOutput(node), nCost);
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
	if not w.header.subwindow.shortdescription or not w.header.subwindow.actionsmini then
		return;
	end

	local nodeActor = PowerManagerCore.getPowerActorNode(w.getDatabaseNode());
	if ActorManager.isPC(nodeActor) then
		sDisplayMode = DB.getValue(nodeActor, "spelldisplaymode", "");
	else
		sDisplayMode = "action";
	end

	if sDisplayMode == "action" then
		w.header.subwindow.shortdescription.setVisible(false);
		w.header.subwindow.actionsmini.setVisible(true);
	else
		w.header.subwindow.shortdescription.setVisible(true);
		w.header.subwindow.actionsmini.setVisible(false);
	end
end

function getActionButtonIcons(node, tData)
	local sType = DB.getValue(node, "type", "");
	if sType == "cast" then
		if tData and tData.sSubRoll == "atk" then
			return "button_action_attack", "button_action_attack_down";
		elseif tData and tData.sSubRoll == "clc" then
			return "button_roll", "button_roll_down";
		elseif tData and tData.sSubRoll == "save" then
			return "button_roll", "button_roll_down";
		end
		return "button_roll", "button_roll_down";
	elseif sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(node, tData)
	local sType = DB.getValue(node, "type", "");
	if sType == "cast" then
		if tData and tData.sSubRoll == "atk" then
			return SpellManager.getActionAttackText(node);
		elseif tData and tData.sSubRoll == "clc" then
			return SpellManager.getActionCLText(node);
		elseif tData and tData.sSubRoll == "save" then
			return SpellManager.getActionSaveText(node);
		end
		return "";
	elseif sType == "damage" then
		return SpellManager.getActionDamageText(node);
	elseif sType == "heal" then
		return SpellManager.getActionHealText(node);
	elseif sType == "effect" then
		if tData and tData.sSubRoll == "duration" then
			return SpellManager.getActionEffectDurationText(node);
		else
			return PowerActionManagerCore.getActionEffectText(node, tData);
		end
	end
	return "";
end
function getActionTooltip(node, tData)
	local sType = DB.getValue(node, "type", "");
	if sType == "cast" then
		if tData and tData.sSubRoll == "atk" then
			return string.format("%s: %s", Interface.getString("power_tooltip_attack"), PowerActionManagerCore.getActionText(node, tData));
		elseif tData and tData.sSubRoll == "clc" then
			return string.format("%s: %s", Interface.getString("power_tooltip_cl"), PowerActionManagerCore.getActionText(node, tData));
		elseif tData and tData.sSubRoll == "save" then
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
	elseif sType == "damage" then
		return string.format("%s: %s", Interface.getString("power_tooltip_damage"), PowerActionManagerCore.getActionText(node, tData));
	elseif sType == "heal" then
		return string.format("%s: %s", Interface.getString("power_tooltip_heal"), PowerActionManagerCore.getActionText(node, tData));
	elseif sType == "effect" then
		return PowerActionManagerCore.getActionEffectTooltip(node, tData);
	end
	return "";
end
function performAction(draginfo, node, tData)
	local sType = DB.getValue(node, "type", "");
	if sType ~= "" then
		local sSubRoll;
		if tData and tData.sSubRoll then
			sSubRoll = tData.sSubRoll;
		end
		SpellManager.onSpellAction(draginfo, node, sSubRoll);
	end
end
