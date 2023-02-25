-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	local sRecordType = DB.getValue(nodeRecord, "recordtype", "");
	
	local bFeat = (sRecordType == "feat");
	local bTrait = (sRecordType == "trait");
	local bTalent = (sRecordType == "talent");
	
	if bFeat or bTrait then
		if bReadOnly then
			type_biglabel.setValue(string.format("[%s]", type.getValue()));
			type_biglabel.setVisible(true);
			class_biglabel.setVisible(false);
			class.update(bReadOnly);
			
			type.update(bReadOnly, true);
		else
			type_biglabel.setVisible(false);
			type.update(bReadOnly);
		end
	elseif bTalent then
		if bReadOnly then
			class_biglabel.setValue(string.format("[%s]", class.getValue()));
			class_biglabel.setVisible(true);
			type_biglabel.setVisible(false);
			type.update(bReadOnly);
			
			class.update(bReadOnly, true);
		else
			class_biglabel.setVisible(false);
			class.update(bReadOnly);
		end
	end
	
	WindowManager.callSafeControlUpdate(self, "advance", bReadOnly, not bTalent);
	WindowManager.callSafeControlUpdate(self, "flavor", bReadOnly, not (bFeat or bTrait));
	WindowManager.callSafeControlUpdate(self, "prerequisites", bReadOnly, not (bFeat or bTrait or bTalent));
	WindowManager.callSafeControlUpdate(self, "summary", bReadOnly, not bFeat);
	WindowManager.callSafeControlUpdate(self, "benefit", bReadOnly, not (bFeat or bTrait or bTalent));
	WindowManager.callSafeControlUpdate(self, "normal", bReadOnly, not bFeat);
	WindowManager.callSafeControlUpdate(self, "special", bReadOnly, not bFeat);
end