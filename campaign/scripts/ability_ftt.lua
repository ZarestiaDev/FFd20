-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bReadOnly, bShow)
	if not self[sControl] then
		return false;
	end
	
	if not bShow then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
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
			type_biglabel.setValue("[" .. type.getValue() .. "]");
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
			class_biglabel.setValue("[" .. class.getValue() .. "]");
			class_biglabel.setVisible(true);
			type_biglabel.setVisible(false);
			type.update(bReadOnly);
			
			class.update(bReadOnly, true);
		else
			class_biglabel.setVisible(false);
			class.update(bReadOnly);
		end
	end
	
	updateControl("advance", bReadOnly, bTalent);
	updateControl("flavor", bReadOnly, bFeat or bTrait);
	updateControl("prerequisites", bReadOnly, bFeat or bTrait or bTalent);
	updateControl("summary", bReadOnly, bFeat);
	updateControl("benefit", bReadOnly, bFeat or bTrait or bTalent);
	updateControl("normal", bReadOnly, bFeat);
	updateControl("special", bReadOnly, bFeat);
end