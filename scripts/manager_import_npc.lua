-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local _tImportState = {};

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	local sLabel = Interface.getString("import_mode_2022");
	ImportUtilityManager.registerImportMode("npc", "2022", sLabel, ImportNPCManager.import2022);
end

function performImport(w)
	local sMode = w.mode.getSelectedValue();
	local tImportMode = ImportUtilityManager.getImportMode("npc", sMode);
	if tImportMode then
		local sStats = w.statblock.getValue();
		local sDesc = w.description.getValue();
		tImportMode.fn(sStats, sDesc);
	end
end

--
--	Built-in supported import modes
--

function import2022(sStats, sDesc)
    -- Track state information
	ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name/cr on Line 1
	ImportNPCManager.importHelperNameCR();

    -- Assume XP on Line 2
    ImportNPCManager.importHelperXP();

    -- Assume alignment/size/type on Line 3
    ImportNPCManager.importHelperAlignmentSizeType();

    -- Assume initiative/senses on Line 4
    ImportNPCManager.importHelperInitiativeSenses();

    -- Assume defense on Line 5-8, maybe more
    ImportNPCManager.importHelperDefense();

    -- Assume optional tactics
    ImportNPCManager.importHelperOptionalTactics();

    -- Assume offense next
    ImportNPCManager.importHelperOffense();

    -- Assume optional spells next
    ImportNPCManager.importHelperSpells();

    -- Assume Statistics next
    ImportNPCManager.importHelperStatistics();

    -- Assume special abilities next
    ImportNPCManager.importHelperSpecialAbilities();

    -- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", _tImportState.node);
end
