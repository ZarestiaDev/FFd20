-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 7);
		registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 7, 8);
		registerMenuItem(Interface.getString("menu_restovernight"), "pointer_circle", 7, 6);
	end
	updateAdd();
	onLevelChanged();
	DB.addHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);
end

function onLevelChanged()
	CharManager.calcLevel(getDatabaseNode());
end

function onMenuSelection(selection, subselection)
	if selection == 7 then
		if subselection == 8 then
			local nodeChar = getDatabaseNode();
			ChatManager.Message(Interface.getString("message_restshort"), true, ActorManager.resolveActor(nodeChar));
		elseif subselection == 6 then
			local nodeChar = getDatabaseNode();
			ChatManager.Message(Interface.getString("message_restovernight"), true, ActorManager.resolveActor(nodeChar));
			CharManager.rest(nodeChar);
		end
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		if StringManager.contains({"referenceclass", "referencerace", "referencedeity"}, sClass) then
			CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
			updateAdd();
			return true;
		end
	end
end

function updateAdd()
	local nodeChar = getDatabaseNode();
	if DB.getValue(nodeChar, "racelink", "") == "referencerace" then
		race_add.setVisible(false);
	end
	if DB.getValue(nodeChar, "deitylink", "") == "referencedeity" then
		deity_add.setVisible(false);
	end
end