-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function handleDrop(sTarget, draginfo)
	if sTarget == "spell" then
		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sRootMapping = LibraryData.getRootMapping(sTarget);
			local sClass, sRecord = draginfo.getShortcutData();
			if ((sClass == "spelldesc") or (sClass == "spelldesc2")) and ((sRootMapping or "") ~= "") then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				DB.setValue(nodeTarget, "locked", "number", 1);
				SpellManager.convertSpellDescToFormattedText(nodeTarget);
				return true;
			end
		end
	end
end

function onEncounterGenerated(nodeEncounter)
	CombatManager2.calcBattleCR(nodeEncounter);
end
