-- 
-- Please see the license.html file included with this distribution for 
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
	
	onDisplayChanged();
end

function update(bEditMode)
	if minisheet then
		return;
	end
	
	idelete.setVisibility(bEditMode);
end

function onDisplayChanged()
	if minisheet then
		return;
	end
	
	sDisplayMode = DB.getValue(getDatabaseNode(), ".......spelldisplaymode", "");

	if sDisplayMode == "action" then
		header.subwindow.shortdescription.setVisible(false);
		header.subwindow.actionsmini.setVisible(true);
	else
		header.subwindow.shortdescription.setVisible(true);
		header.subwindow.actionsmini.setVisible(false);
	end
end

function onHover(bOver)
	if minisheet then
		if bOver then
			setFrame("rowshade");
		else
			setFrame(nil);
		end
	end
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

function getDescription()
	local nodeSpell = getDatabaseNode();
	
	local s = DB.getValue(nodeSpell, "name", "");
	
	local sShort = DB.getValue(nodeSpell, "shortdescription", "");
	if sShort ~= "" then
		s = s .. " - " .. sShort;
	end

	return s;
end

function activatePower()
	local nodeSpell = getDatabaseNode();
	if nodeSpell then
		local rActor = ActorManager.resolveActor(nodeSpell.getChild("......."));
		ChatManager.Message(getDescription(), true, rActor);
	end
end

function usePower()
	local nodeSpell = getDatabaseNode();
	local nodeSpellClass = nodeSpell.getChild(".....");
	local rActor = ActorManager.resolveActor(nodeSpell.getChild("......."));

	local sMessage;
	if DB.getValue(nodeSpellClass, "castertype", "") == "points" then
		local nPP = DB.getValue(nodeSpell, ".....points", 0);
		local nPPUsed = DB.getValue(nodeSpell, ".....pointsused", 0);
		local nCost = DB.getValue(nodeSpell, "cost", 0);
		
		sMessage = DB.getValue(nodeSpell, "name", "") .. " [" .. nCost .. " PP]";
		if (nPP - nPPUsed) < nCost then
			sMessage = sMessage .. " [INSUFFICIENT PP AVAILABLE]";
		else
			nPPUsed = nPPUsed + nCost;
			DB.setValue(nodeSpell, ".....pointsused", "number", nPPUsed);
		end
	else
		sMessage = DB.getValue(nodeSpell, "name", "");
	end

	ChatManager.Message(sMessage, ActorManager.isPC(rActor), rActor);
end
