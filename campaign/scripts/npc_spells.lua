-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
	updateAbility();

	local node = getDatabaseNode();
	for _,v in pairs(DataCommon.abilities) do
		DB.addHandler(DB.getPath(node, v), "onUpdate", updateAbility);
	end

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "spellset"), "onChildUpdate", updateAbility);
end

function onClose()
	local node = getDatabaseNode();
	for _,v in pairs(DataCommon.abilities) do
		DB.removeHandler(DB.getPath(node, v), "onUpdate", updateAbility);
	end

	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "spellset"), "onChildUpdate", updateAbility);
end

function onModeChanged()
	for _,vClass in pairs(spellclasslist.getWindows()) do
		vClass.onSpellCounterUpdate();
	end
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	spellclasslist_iedit.setValue(0);
	spellclasslist_iedit.setVisible(not bReadOnly);
	spellclasslist_iadd.setVisible(not bReadOnly);
	
	spellclasslist_mini.setVisible(bReadOnly);
	expand_mini.setVisible(bReadOnly);
	collapse_mini.setVisible(bReadOnly);
	
	spellclasslist.setVisible(not bReadOnly);
	expand_full.setVisible(not bReadOnly);
	collapse_full.setVisible(not bReadOnly);
	label_mode.setVisible(not bReadOnly);
	spellmode.setVisible(not bReadOnly);
end

function updateAbility()
	for _,v in pairs(spellclasslist.getWindows()) do
		v.onStatUpdate();
	end
end

function addSpellClass()
	local w = spellclasslist.createWindow();
	if w then
		w.activatedetail.setValue(1);
		w.label.setFocus();
		DB.setValue(getDatabaseNode(), "spellmode", "string", "standard");
	end
end

function onSpellDrop(x, y, draginfo)
	if draginfo.isType("spellmove") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("spelldescwithlevel") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		
		if sClass == "spelldesc" or sClass == "spelldesc2" then
			ChatManager.Message(Interface.getString("spell_error_dropclasslevelmissing"));
			return true;
		end
	end
end

function getEditMode()
	return (spellclasslist_iedit.getValue() == 1);
end
