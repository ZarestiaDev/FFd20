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

	-- Assume defensive values
	ImportNPCManager.importHelperDefense();

	-- Assume optional tactics
	--ImportNPCManager.importHelperTacticsOptional();

	-- Assume offense next
	--ImportNPCManager.importHelperOffense();

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
	ImportNPCManager.nextImportLine();
	local sDiffDefOff;
	-- Get all data between DEFENSE and OFFENSE
	sDiffDefOff = ImportNPCManager.importHelperDiff("DEFENSE", "OFFENSE");
	-- Assume every NPC has AC/HP/Saves and save the data without them in "sDiffDefOff"
	sDiffDefOff = ImportNPCManager.importHelperDefStats(sDiffDefOff);
	-- Assume optional values in the order:
	-- MP
	-- Defensive Abilities
	-- DR
	-- Immune
	-- Resist
	-- SR
	-- Strong
	-- Weakness
	ImportNPCManager.importHelperDefStatsOptional(sDiffDefOff);
end

function importHelperDefStats(sLines)
	local sAC, sHPLine, sHD, nHP, sSaveLine, nFort, nRef, nWill, sRemainder;
	-- Extract AC
	sAC, sRemainder = StringManager.extractPattern(sLines:lower(), "^ac.-%)");
	sAC = StringManager.trim(sAC:gsub("ac", "")) or "";
	-- Extract HP
	sHPLine, sRemainder = StringManager.extractPattern(sRemainder, "^%s?hp.-%)");
	nHP = sHPLine:match("%d+") or 0;
	sHD = sHPLine:match("%((.-)%)") or "";
	-- Extract Fort
	sSaveLine, sRemainder = StringManager.extractPattern(sRemainder, "fort%s.?%d+,%sref%s.?%d+,%swill%s.?%d+%s?");
	nFort = tonumber(sSaveLine:match("fort%s(.?%d+)")) or 0;
	nRef = tonumber(sSaveLine:match("ref%s(.?%d+)")) or 0;
	nWill = tonumber(sSaveLine:match("will%s(.?%d+)")) or 0;

	DB.setValue(_tImportState.node, "ac", "string", sAC);
	DB.setValue(_tImportState.node, "hp", "number", nHP);
	DB.setValue(_tImportState.node, "hd", "string", sHD);
	DB.setValue(_tImportState.node, "fortitudesave", "number", nFort);
	DB.setValue(_tImportState.node, "reflexsave", "number", nRef);
	DB.setValue(_tImportState.node, "willsave", "number", nWill);

	return sRemainder;
end

function importHelperDefStatsOptional(sLines)
	if not sLines or sLines == "" then
		return;
	end

	local nMP, sDA, sAbsorb, sDR, sImmune, sResist, nSR, sStrong, sWeakness;

	sLines = sLines:gsub(";?%s?defensive%sabilities", ";defensive abilities");
	sLines = sLines:gsub(";?%s?absorb", ";absorb");
	sLines = sLines:gsub(";?%s?dr", ";dr");
	sLines = sLines:gsub(";?%s?immune", ";immune");
	sLines = sLines:gsub(";?%s?resist", ";resist");
	sLines = sLines:gsub(";?%s?sr", ";sr");
	sLines = sLines:gsub(";?%s?strong", ";strong");
	sLines = sLines:gsub(";?%s?weakness", ";weakness");

	local tDefOptional = StringManager.splitByPattern(sLines, ";");

	for _,sDefOption in ipairs(tDefOptional) do
		if sDefOption:match("mp") then
			nMP = tonumber(sDefOption:match("%d+"));
		elseif sDefOption:match("defensive abilities") then
			sDA = sDefOption:gsub("defensive abilities%s?", "");
		elseif sDefOption:match("absorb") then
			sAbsorb = sDefOption:gsub("absorb%s?", "");
		elseif sDefOption:match("dr") then
			sDR = sDefOption:gsub("dr%s?", "");
		elseif sDefOption:match("immune") then
			sImmune = sDefOption:gsub("immune%s?", "");
		elseif sDefOption:match("resist") then
			sResist = sDefOption:gsub("resist%s?", "");
		elseif sDefOption:match("sr") then
			nSR = tonumber(sDefOption:match("%d+"));
		elseif sDefOption:match("strong") then
			sWeakness = sDefOption:gsub("strong%s?", "");
		elseif sDefOption:match("weakness") then
			sWeakness = sDefOption:gsub("weakness%s?", "");
		end
	end

	DB.setValue(_tImportState.node, "specialqualities", "string", sDA);
	DB.setValue(_tImportState.node, "absorb", "string", sAbsorb);
	DB.setValue(_tImportState.node, "dr", "string", sDR);
	DB.setValue(_tImportState.node, "immune", "string", sImmune);
	DB.setValue(_tImportState.node, "resistance", "string", sResist);
	DB.setValue(_tImportState.node, "sr", "number", nSR);
	DB.setValue(_tImportState.node, "strong", "string", sStrong);
	DB.setValue(_tImportState.node, "weakness", "string", sWeakness);
end

--
--	General helper
--

function importHelperDiff(sHeadingStart, sHeadingEnd)
	local tDefense = {};

	if _tImportState.sActiveLine:match(sHeadingStart) then
		while not _tImportState.sActiveLine:match(sHeadingEnd) do
			ImportNPCManager.nextImportLine();
			local sLine = _tImportState.sActiveLine;

			if not sLine or sLine == "" or sLine:match(sHeadingEnd) or sLine:match("TACTICS") then
				break;
			end

			table.insert(tDefense, sLine);
		end

		return table.concat(tDefense);
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
