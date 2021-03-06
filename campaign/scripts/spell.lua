-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local bShow = true;

function setFilter(bFilter)
	bShow = bFilter;
end

function getFilter()
	return bShow;
end

function onInit()
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("menu_deletespell"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

		registerMenuItem(Interface.getString("menu_addspellaction"), "pointer", 3);
		registerMenuItem(Interface.getString("menu_addspellcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("menu_addspelldamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("menu_addspellheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("menu_addspelleffect"), "radial_effect", 3, 5);
		
		registerMenuItem(Interface.getString("menu_reparsespell"), "textlist", 4);
	end

	-- Check to see if we should automatically parse spell description
	local nodeSpell = getDatabaseNode();
	local nParse = DB.getValue(nodeSpell, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodeSpell, "parse", "number", 0);
		SpellManager.parseSpell(nodeSpell);
	end
end

function update(bEditMode)
	idelete.setVisibility(bEditMode);
end

function createAction(sType)
	local nodeSpell = getDatabaseNode();
	if nodeSpell then
		local nodeActions = nodeSpell.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.createChild();
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
			end
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
	elseif selection == 4 then
		SpellManager.parseSpell(getDatabaseNode());
		activatedetail.setValue(1);
	elseif selection == 3 then
		if subselection == 2 then
			createAction("cast");
			activatedetail.setValue(1);
		elseif subselection == 3 then
			createAction("damage");
			activatedetail.setValue(1);
		elseif subselection == 4 then
			createAction("heal");
			activatedetail.setValue(1);
		elseif subselection == 5 then
			createAction("effect");
			activatedetail.setValue(1);
		end
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	
	actions.setVisible(status);
end

function usePower()
	local nodeSpell = getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeSpell.getChild("......."));
	
	local nMPCurrent = DB.getValue(nodeSpell, ".....mp.current", 0);
	local nCost = DB.getValue(nodeSpell, "...level", 0);

	local sMessage = DB.getValue(nodeSpell, "name", "") .. " [" .. nCost .. " MP]";
	if nCost > nMPCurrent then
		sMessage = sMessage .. " [NOT ENOUGH MP AVAILABLE]";
	else
		nMPCurrent = nMPCurrent - nCost;
		DB.setValue(nodeSpell, ".....mp.current", "number", nMPCurrent);
	end
	
	ChatManager.Message(sMessage, ActorManager.isPC(rActor), rActor);
end
