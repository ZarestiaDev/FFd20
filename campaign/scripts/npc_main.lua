-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
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
		if WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);

	WindowManager.callSafeControlUpdate(self, "type", bReadOnly);

	WindowManager.callSafeControlUpdate(self, "alignment", bReadOnly, true);
	WindowManager.callSafeControlUpdate(self, "senses", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "aura", bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "ac", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "hd", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "absorb", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "dr", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "immune", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "resistance", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "weakness", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "strong", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sr", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "specialqualities", bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "speed", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "atk", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "fullatk", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "spacereach", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "specialattacks", bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "babcmb", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "feats", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "skills", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "languages", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "advancement", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "leveladjustment", bReadOnly);

	WindowManager.callSafeControlUpdate(self, "environment", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "organization", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "treasure", bReadOnly);
	
	-- Trap
	WindowManager.callSafeControlUpdate(self, "trigger", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "reset", bReadOnly);

	-- Vehicle
	WindowManager.callSafeControlUpdate(self, "size", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "cost", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "fuel", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "vac", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "cmd", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "cover", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "hardness", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "modifiers", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "passengers", bReadOnly);
end
