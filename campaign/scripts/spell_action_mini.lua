-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sNode = getDatabaseNode().getPath();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getPath();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onDataChanged()
	updateDisplay();
	updateViews();
end

function updateDisplay()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		button.setIcons("button_roll", "button_roll_down");
	elseif sType == "damage" then
		button.setIcons("button_action_damage", "button_action_damage_down");
	elseif sType == "heal" then
		button.setIcons("button_action_heal", "button_action_heal_down");
	elseif sType == "effect" then
		button.setIcons("button_action_effect", "button_action_effect_down");
	end
end

function updateViews()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		onCastChanged();
	elseif sType == "damage" then
		onDamageChanged();
	elseif sType == "heal" then
		onHealChanged();
	elseif sType == "effect" then
		onEffectChanged();
	end
end

function onCastChanged()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local sCL = string.format("%s: %d", Interface.getString("power_tooltip_cast"), SpellManager.getActionCLC(node));
	
	local sAttack = SpellManager.getActionAttackText(node);
	if sAttack ~= "" then
		sAttack = string.format("%s: %s", Interface.getString("power_tooltip_attack"), sAttack);
	end

	local sSave = SpellManager.getActionSaveText(node);
	if sSave ~= "" then
		sSave = string.format("%s: %s", Interface.getString("power_tooltip_save"), sSave);
	end
	
	local sTooltip = sCL;
	if sAttack ~= "" then
		sTooltip = sTooltip .. "\r" .. sAttack;
	end
	if sSave ~= "" then
		sTooltip = sTooltip .. "\r" .. sSave;
	end

	button.setTooltipText(sTooltip);
end

function onDamageChanged()
	local sDamage = SpellManager.getActionDamageText(getDatabaseNode());
	button.setTooltipText(string.format("%s: %s", Interface.getString("power_tooltip_damage"), sDamage));
end

function onHealChanged()
	local sHeal = SpellManager.getActionHealText(getDatabaseNode());
	button.setTooltipText(string.format("%s: %s", Interface.getString("power_tooltip_heal"), sHeal));
end

function onEffectChanged()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local sTooltip = DB.getValue(node, "label", "");

	local sApply = DB.getValue(node, "apply", "");
	if sApply == "action" then
		sTooltip = "[1 ACTN]; " .. sTooltip;
	elseif sApply == "roll" then
		sTooltip = "[1 ROLL]; " .. sTooltip;
	elseif sApply == "single" then
		sTooltip = "[SNGL]; " .. sTooltip;
	end
	
	local sTargeting = DB.getValue(node, "targeting", "");
	if sTargeting == "self" then
		sTooltip = "[SELF]; " .. sTooltip;
	end
	
	sTooltip = string.format("%s: %s", Interface.getString("power_tooltip_effect"), sTooltip);
	
	button.setTooltipText(sTooltip);
end
