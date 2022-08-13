-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end

	return self[sControl].update(bReadOnly, bForceHide);
end

function insertTables(aTypeSubtype, nodeRecord)
	for category,value in pairs(aTypeSubtype) do
		local sExistingValue = DB.getValue(nodeRecord, category, "");

		if sExistingValue == "" then
			DB.setValue(nodeRecord, category, "string", value);
		else
			local aValues = {}
			local aSplit = StringManager.split(value, ",", true);
			local aSourceSplit = StringManager.split(sExistingValue, ",", true);

			for _,v in pairs(aSplit) do
				if not string.find(table.concat(aSourceSplit), v) then
					table.insert(aValues, v);
				end;
			end

			if next(aValues) ~= nil then
				local sNewValues = table.concat(aValues, ", ");
				DB.setValue(nodeRecord, category, "string", sExistingValue .. ", " .. sNewValues);
			end
		end
	end
end

function parseTypeAndSubtype()
	local nodeRecord = getDatabaseNode();
	local sRecord = DB.getValue(nodeRecord, "type", "");
	local sCreatureType, sSubTypes;
	if string.match(sRecord, "%(") then
		sCreatureType, sSubTypes = string.match(sRecord, "([^(]+) %(([^)]+)%)");
	else
		sCreatureType = sRecord;
	end

	-- Cleanup DB nodes
	DB.setValue(nodeRecord, "absorb", "string", "");
	DB.setValue(nodeRecord, "dr", "string", "");
	DB.setValue(nodeRecord, "immune", "string", "");
	DB.setValue(nodeRecord, "resistance", "string", "");
	DB.setValue(nodeRecord, "weakness", "string", "");
	DB.setValue(nodeRecord, "strong", "string", "");
	
	if sCreatureType ~= "" then
		local aAllTypes = StringManager.split(sCreatureType, " ", true);
		local sType = aAllTypes[#aAllTypes]:lower();
		local aCreatureType = DataCommon.creaturetype[sType];
	
		if aCreatureType then
			insertTables(aCreatureType, nodeRecord);
		end
	end

	local aSubTypes = {};
	if sSubTypes then
		aSubTypes = StringManager.split(sSubTypes, ",", true);
		for _,v in pairs(aSubTypes) do
			local sSubType = v:lower();
			local aCreatureSubType = DataCommon.creaturesubtype[sSubType];

			if aCreatureSubType then
				insertTables(aCreatureSubType, nodeRecord);
			end
		end
	end
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);

	updateControl("type", bReadOnly);

	updateControl("alignment", bReadOnly, true);
	updateControl("senses", bReadOnly);
	updateControl("aura", bReadOnly);
	
	updateControl("ac", bReadOnly);
	updateControl("hd", bReadOnly);
	updateControl("absorb", bReadOnly);
	updateControl("dr", bReadOnly);
	updateControl("immune", bReadOnly);
	updateControl("resistance", bReadOnly);
	updateControl("weakness", bReadOnly);
	updateControl("strong", bReadOnly);
	updateControl("sr", bReadOnly);
	updateControl("specialqualities", bReadOnly);
	
	updateControl("speed", bReadOnly);
	updateControl("atk", bReadOnly);
	updateControl("fullatk", bReadOnly);
	updateControl("spacereach", bReadOnly);
	updateControl("specialattacks", bReadOnly);
	
	updateControl("babcmb", bReadOnly);
	updateControl("feats", bReadOnly);
	updateControl("skills", bReadOnly);
	updateControl("languages", bReadOnly);
	updateControl("advancement", bReadOnly);
	updateControl("leveladjustment", bReadOnly);

	updateControl("environment", bReadOnly);
	updateControl("organization", bReadOnly);
	updateControl("treasure", bReadOnly);
	
	-- Trap
	updateControl("trigger", bReadOnly);
	updateControl("reset", bReadOnly);

	-- Vehicle
	updateControl("size", bReadOnly);
	updateControl("cost", bReadOnly);
	updateControl("fuel", bReadOnly);
	updateControl("vac", bReadOnly);
	updateControl("cmd", bReadOnly);
	updateControl("cover", bReadOnly);
	updateControl("hardness", bReadOnly);
	updateControl("modifiers", bReadOnly);
	updateControl("passengers", bReadOnly);
end
