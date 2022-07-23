-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local _tImportState = {};

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	local sLabel = Interface.getString("import_spell_mode_2022");
	ImportUtilityManager.registerImportMode("spell", "2022", sLabel, ImportSpellManager.import2022);
end

function performImport(w)
	local sMode = w.mode.getSelectedValue();
	local tImportMode = ImportUtilityManager.getImportMode("spell", sMode);
	if tImportMode then
		local sDesc = w.description.getValue();
		tImportMode.fn(sDesc);
	end
end

--
--	Built-in supported import modes
--

function import2022(sStats)
    -- Track state information
    ImportSpellManager.initImportState(sStats);

    -- Assume Name on Line 1
    
end

function initImportState(sStatBlock)
	_tImportState = {};

	local sCleanStats = ImportUtilityManager.cleanUpText(sStatBlock);
	_tImportState.nLine = 0;
	_tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanStats);
	_tImportState.sActiveLine = "";

	_tImportState.tStatOutput = {};

	local sRootMapping = LibraryData.getRootMapping("spell");
	_tImportState.node = DB.createChild(sRootMapping);

    Debug.chat(_tImportState.tLines)
end
