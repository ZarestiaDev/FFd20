-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.updateMenu();

	self.onCheckPenaltyChange();
	self.onStatUpdate();

	self.onEditModeChanged();
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(windowlist, "skills_iedit");

	local bAllowDelete = self.isCustom();
	if not bAllowDelete then
		local sLabel = label.getValue();
		local rSkill = DataCommon.skilldata[sLabel];
		if rSkill and rSkill.sublabeling then
			bAllowDelete = true;
		end
	end

	if bAllowDelete then
		idelete_spacer.setVisible(false);
		idelete.setVisibility(bEditMode);
	else
		idelete_spacer.setVisible(bEditMode);
		idelete.setVisibility(false);
	end
end

function updateWindow()
	local sLabel = label.getValue();
	local t = DataCommon.skilldata[sLabel];
	if t then
		self.setCustom(false);
		
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
		self.setCustom(true);
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
local _bCustom = true;
function setCustom(state)
	_bCustom = state;
	
	if _bCustom then
		label.setEnabled(true);
		label.setLine(true);
	else
		label.setEnabled(false);
		label.setLine(false);
	end
	
	self.updateMenu();
end

function isCustom()
	return _bCustom;
end

function updateMenu()
	resetMenuItems();
	
	if self.isCustom() then
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
