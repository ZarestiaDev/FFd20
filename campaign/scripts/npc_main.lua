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
			local aSplit = StringManager.split(value, " ", true);
			local aSourceSplit = StringManager.split(sExistingValue, " ", true);

			for _,v in pairs(aSplit) do
				if not string.find(table.concat(aSourceSplit), v) then
					table.insert(aValues, v);
				end;
			end

			local sNewValues = table.concat(aValues);
			if sNewValues ~= "" then
				sNewValues = ", " .. string.gsub(sNewValues, ",", ", ");
				DB.setValue(nodeRecord, category, "string", sExistingValue .. sNewValues);
			end
		end
	end
end

function parseTypeAndSubtype()
	local nodeRecord = getDatabaseNode();
	local sRecord = DB.getValue(nodeRecord, "type", "");
	local sCreatureType, sSubTypes = string.match(sRecord, "([^(]+) %(([^)]+)%)");
	local aAllTypes = StringManager.split(sCreatureType, " ", true);
	local sType = aAllTypes[#aAllTypes]:lower();
	local aCreatureType = DataCommon.creaturetype[sType];

	insertTables(aCreatureType, nodeRecord);

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

	-- Update labels based on NPC type
	local sType = DB.getValue(nodeRecord, "npctype", "");
	if babgrp_label then
		if sType == "Vehicle" then
			babgrp_label.setValue(Interface.getString("npc_label_cm"));
			updateControl("babgrp", bReadOnly);
		else
			babgrp_label.setValue(Interface.getString("npc_label_babcm"));
		end
	end

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
	
	updateControl("babgrp", bReadOnly);
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
	updateControl("squares", bReadOnly);
	updateControl("basesave", bReadOnly);
	
	updateControl("prop", bReadOnly);
	updateControl("drive", bReadOnly);
	updateControl("ff", bReadOnly);
	updateControl("drived", bReadOnly);
	updateControl("drives", bReadOnly);
	updateControl("crew", bReadOnly);
	updateControl("decks", bReadOnly);
	updateControl("weapons", bReadOnly);
end
