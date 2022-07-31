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
	ImportNPCManager.importHelperOffense();

	-- Assume Statistics next
	ImportNPCManager.importHelperStatistics();

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

	-- Create Spellclass and save nMP for later here
	if nMP and nMP > 0 then
		importHelperSpellClass(nMP);
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

function importHelperOffense()
	ImportNPCManager.nextImportLine();

	-- Speed
	local sSpeed = _tImportState.sActiveLine:gsub("Speed%s?", "");
	ImportNPCManager.nextImportLine();

	-- Melee
	local sAttack = _tImportState.sActiveLine:gsub("Melee%s?", "");
	ImportNPCManager.nextImportLine();

	-- Optional Space/Reach
	local sSpaceReach = "5 ft./5 ft.";
	if _tImportState.sActiveLine:match("Space") then
		local sSpace, sReach = _tImportState.sActiveLine:match("(%d+).-(%d+)");
		sSpaceReach = sSpace .. " ft./" .. sReach .. " ft.";
		ImportNPCManager.nextImportLine();
	end

	-- Optional Special Attack
	local sSpecialAttack = "";
	if _tImportState.sActiveLine:match("Special") then
		sSpecialAttack = _tImportState.sActiveLine:gsub("Special%sAttacks%s?", "");
		ImportNPCManager.nextImportLine();
	end

	-- Optional Spells
	if _tImportState.sActiveLine:match("Spells") then
		ImportNPCManager.importHelperSpellcasting();
	end

	DB.setValue(_tImportState.node, "speed", "string", sSpeed);
	DB.setValue(_tImportState.node, "fullatk", "string", sAttack);
	DB.setValue(_tImportState.node, "spacereach", "string", sSpaceReach);
	DB.setValue(_tImportState.node, "specialattacks", "string", sSpecialAttack);
end

function importHelperStatistics()
	ImportNPCManager.nextImportLine();

	local nStr, nDex, nCon, nInt, nWis, nCha = _tImportState.sActiveLine:match("(%d+).-(%d+).-(%d+).-(%d+).-(%d+).-(%d+)");
	-- BAB/CMB/CMD

	DB.setValue(_tImportState.node, "strength", "number", nStr);
	DB.setValue(_tImportState.node, "dexterity", "number", nDex);
	DB.setValue(_tImportState.node, "constitution", "number", nCon);
	DB.setValue(_tImportState.node, "intelligence", "number", nInt);
	DB.setValue(_tImportState.node, "wisdom", "number", nWis);
	DB.setValue(_tImportState.node, "charisma", "number", nCha);
end

function importHelperSpellcasting()
	local nodeSpellset = _tImportState.node.getChild("spellset");
	if not nodeSpellset then
		return;
	end

	local sType;
	if _tImportState.sActiveLine:match("FC") then
		sType = "Full";
	elseif _tImportState.sActiveLine:match("SC") then
		sType = "Semi";
	elseif _tImportState.sActiveLine:match("PC") then
		sType = "Partial";
	end
	local nCL = tonumber(_tImportState.sActiveLine:match("CL%s(%d+)"));
	local tSpells = DB.findNode("spell").getChildren();

	-- Only one spellset child is possible
	local nodeSpellClass = nodeSpellset.getChild("id-00001");
	DB.setValue(nodeSpellClass, "type", "string", sType);
	DB.setValue(nodeSpellClass, "cl", "number", nCL);
	
	while not _tImportState.sActiveLine:match("STATISTICS") do
		ImportNPCManager.nextImportLine();
		local sLine = _tImportState.sActiveLine;
		if not sLine or sLine == "" or sLine:match("STATISTICS") then
			break;
		end

		local nSpellLevel = tonumber(sLine:match("%d+"));
		if sLine:match("At%swill") then
			nSpellLevel = 0;
		end

		local sSpells = sLine:match("%).-(%w+.*)");
		local tSegments = StringManager.splitByPattern(sSpells, ",");
		for _,sSpellName in ipairs(tSegments) do
			ImportNPCManager.importHelperSearchSpell(nodeSpellClass, tSpells, nSpellLevel, sSpellName);
		end
	end
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

function importHelperSpellClass(nMP)
	local nodeNPC = _tImportState.node;
	local nodeNewSpellClass = nodeNPC.createChild("spellset").createChild();

	if nodeNewSpellClass then
		DB.setValue(nodeNewSpellClass, "label", "string", "Spellcasting");
		DB.setValue(nodeNewSpellClass, "mp.misc", "number", nMP);
		-- change later
		DB.setValue(nodeNewSpellClass, "availablelevel", "number", 9);
	end
end

function importHelperSearchSpell(nodeSpellClass, tSpells, nSpellLevel, sSpellName)
	for _,nodeSource in pairs(tSpells) do
		local sExistingSpellName = DB.getValue(nodeSource, "name", ""):lower();
		if sSpellName == sExistingSpellName then
			ImportNPCManager.importHelperAddSpell(nodeSource, nodeSpellClass, nSpellLevel)
		end
	end
end

function importHelperAddSpell(nodeSource, nodeSpellClass, nSpellLevel)
	local nodeTargetLevelSpells = nodeSpellClass.createChild("levels.level" .. nSpellLevel .. ".spells");
	local nodeNewSpell = nodeTargetLevelSpells.createChild();

	DB.copyNode(nodeSource, nodeNewSpell);
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
