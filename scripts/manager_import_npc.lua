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

	-- Assume alignment/size/type on Line 3
	ImportNPCManager.importHelperAlignmentSizeType();

	-- Assume initiative/senses on Line 4
	ImportNPCManager.importHelperInitiativeSenses();

	-- Assume optional aura on Line 5
	ImportNPCManager.importHelperAura();

	-- Assume defense on Line 5-8, maybe more
	ImportNPCManager.importHelperDefense();

	-- Assume optional tactics
	--ImportNPCManager.importHelperOptionalTactics();

	-- Assume offense next
	--ImportNPCManager.importHelperOffense();

	-- Assume optional spells next
	--ImportNPCManager.importHelperSpells();

	-- Assume Statistics next
	--ImportNPCManager.importHelperStatistics();

	-- Assume special abilities next
	--ImportNPCManager.importHelperSpecialAbilities();

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", _tImportState.node);
end

--
--	Import section helper functions
--

function importHelperNameCR()
	ImportNPCManager.nextImportLine();
	local sLine = _tImportState.sActiveLine;
	local sName = sLine:gsub(" %(CR.+", "");
	local nCR = tonumber(sLine:match("CR%s(%d+)"));

	DB.setValue(_tImportState.node, "name", "string", sName);
	DB.setValue(_tImportState.node, "cr", "number", nCR);
end

function importHelperAlignmentSizeType()
	-- skip xp line
	ImportNPCManager.nextImportLine(2);
	DB.setValue(_tImportState.node, "type", "string", _tImportState.sActiveLine);
end

function importHelperInitiativeSenses()
	ImportNPCManager.nextImportLine();
	local sLine = _tImportState.sActiveLine;
	local nInit = tonumber(sLine:match("Init%s(.?%d+)"));
	local sSenses = sLine:match("Senses (.*)");

	DB.setValue(_tImportState.node, "init", "number", nInit);
	DB.setValue(_tImportState.node, "senses", "string", sSenses);
end

function importHelperAura()
	ImportNPCManager.nextImportLine();

	if _tImportState.sActiveLine:match("^Aura") then
		local sAura = _tImportState.sActiveLine:gsub("Aura ", "");
		DB.setValue(_tImportState.node, "aura", "string", sAura);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperDefense()
	-- skip DEFENSE
	ImportNPCManager.nextImportLine(2);
	-- AC / HP / MP
	local sLine = _tImportState.sActiveLine;
	if sLine:match("^AC") then
		local tSegments = StringManager.splitByPattern(sLine, "hp");
		local sAC = StringManager.trim(tSegments[1]:gsub("AC", ""));
		local sHPLine = tSegments[2];

		-- handle MP
		if sHPLine:match("mp") then
			local tMPSegments = StringManager.splitByPattern(sHPLine, "mp");
			-- Handle MP and Spellclass creation here
		end

		-- handle things like fast healing
		if sHPLine:match(";") then
			local tSQSegments = StringManager.splitByPattern(sHPLine, ";");
		end

		sHD = sHPLine:match("%((.-)%)");
		sHP = tonumber(sHPLine:match("%d+"));

		DB.setValue(_tImportState.node, "hd", "string", sHD);
		DB.setValue(_tImportState.node, "hp", "number", sHP);
		DB.setValue(_tImportState.node, "ac", "string", sAC);
	end
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

	local sRootMapping = LibraryData.getRootMapping("npc");
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
