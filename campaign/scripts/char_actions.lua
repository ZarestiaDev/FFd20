-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(self, "actions_iedit");
	
	label_mode.setVisible(not bEditMode);
	spellmode.setVisible(not bEditMode);
end
