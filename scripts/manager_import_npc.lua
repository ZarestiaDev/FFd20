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

	-- GENERAL
	-- Assume Name/CR next
	ImportNPCManager.importHelperNameCr();

	-- Assume Alignment/Size/Type next
	ImportNPCManager.importHelperAlignmentSizeType();

	-- Assume Initiative/Senses next
	ImportNPCManager.importHelperInitiativeSenses();

	-- Assume aura next (optional)
	ImportNPCManager.importHelperAura();

	-- Assume Defense next
	ImportNPCManager.importHelperDefense();

	-- Assume Tactics next (optional)
	ImportNPCManager.importHelperTactics();

	-- Assume Speed next
	ImportNPCManager.importHelperSpeed();

	-- Assume Attacks next
	ImportNPCManager.importHelperAttack();

	-- Assume Space/Reach next
	ImportNPCManager.importHelperSpaceReach();

	-- Assume Special Abilities/Special Attack next (optional)
	ImportNPCManager.importHelperSpecialAbilAtt();

	-- Assume Spells next (optional)
	ImportNPCManager.importHelperSpells();

	-- Assume Ability Scores next
	ImportNPCManager.importHelperAbilityScores();

	-- Assume BAB/CMB/CMD next
	ImportNPCManager.importHelperBabCmbCmd();

	-- Assume Feats next (optional)
	ImportNPCManager.importHelperFeats();

	-- Assume Skills next (optional)
	ImportNPCManager.importHelperSkills();

	-- Assume Languages next (optional)
	ImportNPCManager.importHelperLanguage();

	-- Assume SQ next (optional)
	ImportNPCManager.importHelperSQ();

	-- Assume special abilities next
	ImportNPCManager.importHelperSpecialAbilities();

	-- Update Spellclass information
	ImportNPCManager.finalizeSpellclass();

	-- Update Description by adding the statblock text as well
	ImportNPCManager.finalizeDescription();

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", _tImportState.node);
end

--
--	Import section helper functions
--

function importHelperNameCr()
	ImportNPCManager.nextImportLine();

	local sLine = _tImportState.sActiveLine;
	local sName = sLine:gsub("%s%(CR.+", "");
	local nCR = tonumber(sLine:match("CR%s(%d+)"));
	if sLine:match("1/8") then
		nCR = 0.125;
	elseif sLine:match("1/6") then
		nCR = 0.166;
	elseif sLine:match("1/4") then
		nCR = 0.25;
	elseif sLine:match("1/3") then
		nCR = 0.333;
	elseif sLine:match("1/2") then
		nCR = 0.5;
	end

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
	local sSenses = sLine:match("Senses%s(.*)");

	DB.setValue(_tImportState.node, "init", "number", nInit);
	DB.setValue(_tImportState.node, "senses", "string", sSenses);
end

function importHelperAura()
	ImportNPCManager.nextImportLine();

	local sLine = _tImportState.sActiveLine;
	if sLine:match("Aura") then
		local sAura = sLine:gsub("Aura%s", "");
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

function importHelperDiff(sHeadingStart, sHeadingEnd)
	local tDefense = {};

	if _tImportState.sActiveLine:match(sHeadingStart) then
		while not _tImportState.sActiveLine:match(sHeadingEnd) do
			ImportNPCManager.nextImportLine();

			local sLine = _tImportState.sActiveLine;
			if not sLine or sLine == "" or sLine:match(sHeadingEnd) or sLine:upper():match("TACTICS") then
				ImportNPCManager.previousImportLine();
				break;
			end

			table.insert(tDefense, sLine);
		end

		return table.concat(tDefense);
	end
end

function importHelperDefStats(sLines)
	local sACLine, sHPLine, sSaveLine, sRemainder;
	-- Extract AC
	sACLine, sRemainder = StringManager.extractPattern(sLines:lower(), "^ac.-%)");
	local sAC = StringManager.trim(sACLine:gsub("ac", "")) or "";
	-- Extract HP
	sHPLine, sRemainder = StringManager.extractPattern(sRemainder, "^%s?hp.-%)");
	local nHP = sHPLine:match("%d+") or 0;
	local sHD = sHPLine:match("%((.-)%)") or "";
	-- Extract Fort
	sSaveLine, sRemainder = StringManager.extractPattern(sRemainder, "fort%s.?%d+,%sref%s.?%d+,%swill%s.?%d+%s?");
	local nFort = tonumber(sSaveLine:match("fort%s(.?%d+)")) or 0;
	local nRef = tonumber(sSaveLine:match("ref%s(.?%d+)")) or 0;
	local nWill = tonumber(sSaveLine:match("will%s(.?%d+)")) or 0;
	
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

	sLines = sLines:gsub(";?%s?defensive%sabilities%s", ";defensive abilities ");
	sLines = sLines:gsub(";?%s?absorb%s", ";absorb ");
	sLines = sLines:gsub(";?%s?dr%s", ";dr ");
	sLines = sLines:gsub(";?%s?immune%s", ";immune ");
	sLines = sLines:gsub(";?%s?resist%s", ";resist ");
	sLines = sLines:gsub(";?%s?sr%s", ";sr ");
	sLines = sLines:gsub(";?%s?strong%s", ";strong ");
	sLines = sLines:gsub(";?%s?weakness%s", ";weakness ");

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
			sStrong = sDefOption:gsub("strong%s?", "");
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

function importHelperTactics()
	ImportNPCManager.nextImportLine();

	if _tImportState.sActiveLine:upper():match("TACTICS") then
		ImportNPCManager.nextImportLine();
		
		local sTactics = _tImportState.sActiveLine:gsub("During%sCombat%s", "");
		ImportNPCManager.addStatOutput("<h>Tactics</h>")
		ImportNPCManager.addStatOutput(string.format("<p>%s</p>", sTactics));
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSpeed()
	-- skip Offense
	ImportNPCManager.nextImportLine(2);

	local sSpeed = _tImportState.sActiveLine:gsub("Speed%s?", "");

	DB.setValue(_tImportState.node, "speed", "string", sSpeed);
end

function importHelperAttack()
	ImportNPCManager.nextImportLine();

	local sAttacks = _tImportState.sActiveLine:gsub("Melee%s?", "");
	if sAttacks:match(",") then
		local tAttacks = StringManager.splitByPattern(sAttacks, ",");
		local sSingleAttack = tAttacks[1];
		sSingleAttack = sSingleAttack:gsub("^%d+%s", "");
		sSingleAttack = sSingleAttack:gsub("s%s%+", " +");
		local sFullAttack = sAttacks:gsub(",", " and");

		DB.setValue(_tImportState.node, "atk", "string", sSingleAttack);
		DB.setValue(_tImportState.node, "fullatk", "string", sFullAttack);
	else
		DB.setValue(_tImportState.node, "atk", "string", sAttacks);
	end
end

function importHelperSpaceReach()
	ImportNPCManager.nextImportLine();

	local sSpaceReach = "5 ft./5 ft.";
	local sLine = _tImportState.sActiveLine;
	if sLine:match("Space") and sLine:match(";") then
		local tSegments = StringManager.splitByPattern(sLine, ";");

		local sSpace = tSegments[1]:match("%d+.*");
		local sReach = tSegments[2]:match("%d+.*");
		sSpaceReach = sSpace .. "/" .. sReach;
	elseif not sLine:match("Space") then
		ImportNPCManager.previousImportLine();
	end

	DB.setValue(_tImportState.node, "spacereach", "string", sSpaceReach);
end

function importHelperSpecialAbilAtt()
	ImportNPCManager.nextImportLine();

	local sLine1 = _tImportState.sActiveLine;
	if sLine1:match("Special") then
		local sSpecialAttack = "";
		local sSpecialAttack2 = "";
		sSpecialAttack = sLine1;

		ImportNPCManager.nextImportLine();

		local sLine2 = _tImportState.sActiveLine;
		if sLine2:match("Special") then
			sSpecialAttack2 = sLine2;
			sSpecialAttack = sSpecialAttack .. ", " .. sSpecialAttack2;
		else
			ImportNPCManager.previousImportLine();
		end

		sSpecialAttack = sSpecialAttack:gsub("Special%sAbilities%s", "");
		sSpecialAttack = sSpecialAttack:gsub("Special%sAttacks%s", "");
		DB.setValue(_tImportState.node, "specialattacks", "string", sSpecialAttack);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSpells()
	ImportNPCManager.nextImportLine();

	local sLine = _tImportState.sActiveLine;
	if sLine:match("Spells") then
		ImportNPCManager.importHelperSpellcasting();
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSpellClass(nMP)
	local nodeNPC = _tImportState.node;
	local nodeNewSpellClass = nodeNPC.createChild("spellset").createChild();

	if nodeNewSpellClass then
		DB.setValue(nodeNewSpellClass, "label", "string", "Spellcasting");
		DB.setValue(nodeNewSpellClass, "mp.misc", "number", nMP);
	end
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
			ImportNPCManager.previousImportLine();
			break;
		end

		local nSpellLevel = tonumber(sLine:match("%d+"));
		if sLine:match("At%swill") then
			nSpellLevel = 0;
		end
		DB.setValue(nodeSpellClass, "availablelevel", "number", nSpellLevel);

		local sSpells = sLine:match("%).-(%w+.*)");
		local tSegments = StringManager.splitByPattern(sSpells, ",");
		for _,sSpellName in ipairs(tSegments) do
			ImportNPCManager.importHelperSearchSpell(nodeSpellClass, tSpells, nSpellLevel, sSpellName);
		end
	end
end

function importHelperSearchSpell(nodeSpellClass, tSpells, nSpellLevel, sSpellName)
	for _,nodeSource in pairs(tSpells) do
		local sExistingSpellName = DB.getValue(nodeSource, "name", ""):lower();
		if sSpellName == sExistingSpellName then
			ImportNPCManager.importHelperAddSpell(nodeSource, nodeSpellClass, nSpellLevel);
			break;
		end
	end
end

function importHelperAddSpell(nodeSource, nodeSpellClass, nSpellLevel)
	local nodeTargetLevelSpells = nodeSpellClass.createChild("levels.level" .. nSpellLevel .. ".spells");
	local nodeNewSpell = nodeTargetLevelSpells.createChild();

	DB.copyNode(nodeSource, nodeNewSpell);
end

function importHelperAbilityScores()
	-- skip Statistics
	ImportNPCManager.nextImportLine(2);

	local sLine = _tImportState.sActiveLine:gsub("-", "0");
	sLine = sLine:gsub("—", "0");
	local nStr, nDex, nCon, nInt, nWis, nCha = sLine:match("(%d+).-(%d+).-(%d+).-(%d+).-(%d+).-(%d+)");

	DB.setValue(_tImportState.node, "strength", "number", nStr);
	DB.setValue(_tImportState.node, "dexterity", "number", nDex);
	DB.setValue(_tImportState.node, "constitution", "number", nCon);
	DB.setValue(_tImportState.node, "intelligence", "number", nInt);
	DB.setValue(_tImportState.node, "wisdom", "number", nWis);
	DB.setValue(_tImportState.node, "charisma", "number", nCha);
end

function importHelperBabCmbCmd()
	ImportNPCManager.nextImportLine();

	local sBabCmbCmd = _tImportState.sActiveLine:gsub("Base%sAtk%s", "");
	sBabCmbCmd = sBabCmbCmd:gsub("%sCMB%s", "");
	sBabCmbCmd = sBabCmbCmd:gsub("%sCMD%s", "");
	sBabCmbCmd = sBabCmbCmd:gsub(";", "/");

	DB.setValue(_tImportState.node, "babgrp", "string", sBabCmbCmd);
end

function importHelperFeats()
	ImportNPCManager.nextImportLine();

	local sLine = _tImportState.sActiveLine;
	if sLine:match("Feats?%s") then
		local sFeats = sLine:gsub("Feats?%s", "");
		DB.setValue(_tImportState.node, "feats", "string", sFeats);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSkills()
	ImportNPCManager.nextImportLine();

	local sLine = _tImportState.sActiveLine;
	if sLine:match("Skills?%s") then
		local sSkills = sLine:gsub("Skills?%s", "");
		sSkills = sSkills:gsub(";.*", "");

		DB.setValue(_tImportState.node, "skills", "string", sSkills);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperLanguage()
	ImportNPCManager.nextImportLine();
	if _tImportState.sActiveLine:match("Language") then
		local sLanguages = _tImportState.sActiveLine:gsub("Languages?%s", "");
		DB.setValue(_tImportState.node, "languages", "string", sLanguages);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSQ()
	ImportNPCManager.nextImportLine();
	if _tImportState.sActiveLine:match("SQ") then
		local sSQ = _tImportState.sActiveLine:gsub("SQ%s", "");
		local sExistingSQ = DB.getValue(_tImportState.node, "specialqualities", "");
		if sExistingSQ ~= "" then
			sSQ = sExistingSQ .. ", " .. sSQ;
		end

		DB.setValue(_tImportState.node, "specialqualities", "string", sSQ);
	else
		ImportNPCManager.previousImportLine();
	end
end

function importHelperSpecialAbilities()
	ImportNPCManager.nextImportLine();

	if not _tImportState.sActiveLine or _tImportState.sActiveLine == "" then
		return;
	end

	ImportNPCManager.addStatOutput("<h>Special Abilities</h>")

	while _tImportState.sActiveLine:match("%w") do
		ImportNPCManager.nextImportLine();

		local sLine = _tImportState.sActiveLine;

		if not sLine or sLine == "" then
			break;
		end

		if sLine:match("Ex") or sLine:match("Su") then
			sLine = sLine:gsub("Copy link to clipboard%s?", "")
			ImportNPCManager.addStatOutput(string.format("<p><b>%s</b></p>", sLine));
		else
			ImportNPCManager.addStatOutput(string.format("<p>%s</p>" ,sLine));
		end
	end
end

--
--	Import state identification and tracking
--

function initImportState(sStatBlock, sDesc)
	_tImportState = {};

	local sCleanStats = ImportUtilityManager.cleanUpText(sStatBlock);
	_tImportState.nLine = 0;
	_tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanStats);
	_tImportState.sActiveLine = "";

	_tImportState.sDescription = ImportUtilityManager.cleanUpText(sDesc);
	_tImportState.tStatOutput = {};

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

function addStatOutput(s)
	table.insert(_tImportState.tStatOutput, s);
end

function finalizeSpellclass()
	local nodeSpellset = _tImportState.node.getChild("spellset");
	
	if not nodeSpellset then
		return;
	end

	local nInt = DB.getValue(_tImportState.node, "intelligence", 0);
	local nWis = DB.getValue(_tImportState.node, "wisdom", 0);
	local nCha = DB.getValue(_tImportState.node, "charisma", 0);

	local nHighest = math.max(nInt, nWis, nCha);

	local nodeSpellClass = nodeSpellset.getChild("id-00001");

	if nHighest == nWis then
		DB.setValue(nodeSpellClass, "dc.ability", "string", "wisdom");
	end
	if nHighest == nCha then
		DB.setValue(nodeSpellClass, "dc.ability", "string", "charisma");
	end
	if nHighest == nInt then
		DB.setValue(nodeSpellClass, "dc.ability", "string", "intelligence");
	end
end

function finalizeDescription()
	DB.setValue(_tImportState.node, "text", "formattedtext", _tImportState.sDescription .. table.concat(_tImportState.tStatOutput));
end
