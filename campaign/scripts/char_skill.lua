-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
sets = {};

function onInit()
	updateMenu();
	
	onCheckPenaltyChange();
	onStatUpdate();
end

function updateWindow()
	local sLabel = label.getValue();
	local t = DataCommon.skilldata[sLabel];
	if t then
		setCustom(false);
		
		if t.sublabeling then
			sublabel.setVisible(true);
		end

		if t.armorcheckmultiplier then
			armorcheckmultiplier.setValue(t.armorcheckmultiplier);
		else
			armorcheckmultiplier.setValue(0);
		end

		if t.trainedonly then
			trainedonly.setVisible(true);
		else
			trainedonly.setVisible(false);
		end
	else
		setCustom(true);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		UtilityManager.safeDeleteWindow(self);
	end
end

function onCheckPenaltyChange()
	if armorcheckmultiplier.getValue() ~= 0 then
		armorwidget.setIcon("char_armorcheck");
	else
		armorwidget.setIcon(nil);
	end
end

function onStatUpdate()
	stat.update(statname.getStringValue());
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
	else
		label.setEnabled(false);
		label.setLine(false);
	end
	
	updateMenu();
end

function isCustom()
	return iscustom;
end

function updateMenu()
	resetMenuItems();
	
	if iscustom then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	else
		local sLabel = label.getValue();
		local rSkill = DataCommon.skilldata[sLabel];
		if rSkill and rSkill.sublabeling then
			registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
			registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
		end
	end
end
