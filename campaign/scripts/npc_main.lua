-- 
-- Please see the license.html file included with this distribution for 
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
