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
    ImportSpellManager.importHelperName();

	-- Assume School & Level on Line 2
	ImportSpellManager.importHelperSchoolLevel();

	-- Assume Casting on Line 3 and 4
	--ImportSpellManager.importHelperCasting();
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName()
	ImportSpellManager.nextImportLine();
	_tImportState.sSpellName = _tImportState.sActiveLine
	DB.setValue(_tImportState.node, "name", "string", _tImportState.sSpellName);
end

-- Assumes school and level is on next line
function importHelperSchoolLevel()
	ImportSpellManager.nextImportLine();
	local tSegments = StringManager.splitByPattern(_tImportState.sActiveLine, ";", true);

	local sSchool = tSegments[1] or "";
	local sLevel = tSegments[2] or "";

	sSchool = StringManager.trim(sSchool:gsub("School", ""));
	sLevel = StringManager.trim(sLevel:gsub("Level", ""));

	DB.setValue(_tImportState.node, "school", "string", StringManager.capitalizeAll(sSchool));
	DB.setValue(_tImportState.node, "level", "string", StringManager.capitalizeAll(sLevel));
end

--
--	Import state identification and tracking
--

function initImportState(sStatBlock)
	_tImportState = {};

	local sCleanStats = ImportUtilityManager.cleanUpText(sStatBlock);
	_tImportState.nLine = 0;
	_tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanStats);
	_tImportState.sActiveLine = "";

	_tImportState.tStatOutput = {};

	local sRootMapping = LibraryData.getRootMapping("spell");
	_tImportState.node = DB.createChild(sRootMapping);

    --Debug.chat(_tImportState.tLines)
end

function nextImportLine(nAdvance)
	_tImportState.nLine = _tImportState.nLine + (nAdvance or 1);
	_tImportState.sActiveLine = _tImportState.tLines[_tImportState.nLine];
end
