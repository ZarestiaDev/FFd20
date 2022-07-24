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
	ImportSpellManager.importHelperCasting();

	-- Assume the following optional fields in the following order:
	-- Range
	-- Area
	-- Target(s)
	-- Effect
	-- Duration
	-- Saving Throw
	-- Spell Resistance
	ImportSpellManager.importHelperOptionalFields();

	-- Assume Description on last Lines
	ImportSpellManager.importHelperDescription();

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("spell", _tImportState.node);

	-- Parse the spell info for effects
	SpellManager.parseSpell(_tImportState.node);
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName()
	ImportSpellManager.nextImportLine();
	local sName = _tImportState.sActiveLine;
	DB.setValue(_tImportState.node, "name", "string", sName);
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

-- Assumes casting is on next next line, some spells do not have a casting parameter
function importHelperCasting()
	local sHeading = "CASTING";
	if not correctHeading(sHeading) then
		return;
	end

	local sCasting = _tImportState.sActiveLine;
	sCasting = StringManager.trim(sCasting:gsub("Casting Time", ""));

	DB.setValue(_tImportState.node, "castingtime", "string", sCasting);
end

-- Assume the following optional fields in the following order:
-- Range
-- Area
-- Target(s)
-- Effect
-- Duration
-- Saving Throw
-- Spell Resistance
function importHelperOptionalFields()
	local sHeading = "EFFECT";
	if not correctHeading(sHeading) then
		return;
	end

	local sLine = _tImportState.sActiveLine;

	if sLine and sLine:match("^Range") then
		local sRange = _tImportState.sActiveLine;
		sRange = StringManager.trim(sRange:gsub("Range", ""));

		DB.setValue(_tImportState.node, "range", "string", StringManager.capitalize(sRange));
		
		ImportSpellManager.nextImportLine();
		sLine = _tImportState.sActiveLine;
	end

	if sLine and (sLine:match("^Area") or sLine:match("^Target") or sLine:match("^Effect")) then
		local sEffect = _tImportState.sActiveLine;
		sEffect = StringManager.trim(sEffect:gsub("Effect", ""));
		sEffect = StringManager.trim(sEffect:gsub("Area", ""));
		sEffect = StringManager.trim(sEffect:gsub("Targets", ""));
		sEffect = StringManager.trim(sEffect:gsub("Target", ""));

		DB.setValue(_tImportState.node, "effect", "string", StringManager.capitalize(sEffect));
		
		ImportSpellManager.nextImportLine();
		sLine = _tImportState.sActiveLine;
	end

	if sLine and sLine:match("^Duration") then
		local sDuration = _tImportState.sActiveLine;
		sDuration = StringManager.trim(sDuration:gsub("Duration", ""));

		DB.setValue(_tImportState.node, "duration", "string", StringManager.capitalize(sDuration));
		
		ImportSpellManager.nextImportLine();
		sLine = _tImportState.sActiveLine;
	end

	if sLine and sLine:match("^Saving Throw") then
		local tSegments = StringManager.splitByPattern(_tImportState.sActiveLine, ";", true);

		local sSavingThrow = tSegments[1] or "";
		local sSpellResistance = tSegments[2] or "";

		sSavingThrow = StringManager.trim(sSavingThrow:gsub("Saving Throw", ""));
		sSpellResistance = StringManager.trim(sSpellResistance:gsub("Spell Resistance", ""));

		DB.setValue(_tImportState.node, "save", "string", StringManager.capitalize(sSavingThrow));
		DB.setValue(_tImportState.node, "sr", "string", StringManager.capitalize(sSpellResistance));
	end
end

-- Assume description is on the next line
function importHelperDescription()
	local sHeading = "DESCRIPTION";
	if not correctHeading(sHeading) then
		return;
	end

	local sDescription = _tImportState.sActiveLine;
	while _tImportState.sActiveLine ~= "" do
		ImportSpellManager.nextImportLine();
		sDescription = sDescription .. "<p />" .. _tImportState.sActiveLine;
	end
	DB.setValue(_tImportState.node, "description", "formattedtext", sDescription);
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

	local sRootMapping = LibraryData.getRootMapping("spell");
	_tImportState.node = DB.createChild(sRootMapping);
end

function nextImportLine(nAdvance)
	_tImportState.nLine = _tImportState.nLine + (nAdvance or 1);
	_tImportState.sActiveLine = _tImportState.tLines[_tImportState.nLine];
end

function previousImportLine()
	_tImportState.nLine = _tImportState.nLine - 1;
	_tImportState.sActiveLine = _tImportState.tLines[_tImportState.nLine];
end

function correctHeading(sHeading)
	local bHeading = true;
	if _tImportState.sActiveLine == sHeading then
		ImportSpellManager.nextImportLine();
		return bHeading;
	end

	ImportSpellManager.nextImportLine();
	if _tImportState.sActiveLine ~= sHeading then
		ImportSpellManager.previousImportLine();
		bHeading = false;
	else
		ImportSpellManager.nextImportLine();
	end

	return bHeading;
end
