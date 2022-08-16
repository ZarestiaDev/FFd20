-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function getRaceHeritageOptions(sRaceName)
	local tOptions = {};
	RecordManager.callForEachRecordByStringI("race_heritage", "race", sRaceName, CharRaceManager.helperGetRaceExternalHeritageOption, tOptions);
	RecordManager.callForEachRecordByStringI("race", "name", sRaceName, CharRaceManager.helperGetRaceEmbeddedHeritageOption, tOptions);
	table.sort(tOptions, function(a,b) return a.text < b.text; end);
	return tOptions;
end
function helperGetRaceExternalHeritageOption(nodeHeritage, tOptions)
	local sHeritageName = StringManager.trim(DB.getValue(nodeHeritage, "name", ""));
	if sHeritageName ~= "" then
		table.insert(tOptions, { text = sHeritageName, linkclass = "referenceheritage", linkrecord = nodeHeritage.getPath() });
	end
end
function helperGetRaceEmbeddedHeritageOption(nodeRace, tOptions)
	for _,nodeHeritage in pairs(DB.getChildren(nodeRace, "heritages")) do
		local sHeritageName = StringManager.trim(DB.getValue(nodeHeritage, "name", ""));
		if sHeritageName ~= "" then
			table.insert(tOptions, { text = sHeritageName, linkclass = "referenceheritage", linkrecord = nodeHeritage.getPath() });
		end
	end
end

function getRaceFromHeritage(sHeritageName)
	local nodeExternalHeritage = RecordManager.findRecordByStringI("race_heritage", "name", sHeritageName);
	if nodeExternalHeritage then
		local sRaceName = StringManager.trim(DB.getValue(nodeExternalHeritage, "race", ""));
		local nodeRace = RecordManager.findRecordByStringI("race", "name", sRaceName);
		return sRaceName, nodeRace;
	end

	local sHeritageNameLower = StringManager.trim(sHeritageName):lower();
	local tMappings = LibraryData.getMappings("race");
	for _,sMapping in ipairs(tMappings) do
		for _,vRace in pairs(DB.getChildrenGlobal(sMapping)) do
			for _,vHeritage in pairs(DB.getChildren(vRace, "heritages")) do
				local sMatch = StringManager.trim(DB.getValue(vHeritage, "name", "")):lower();
				if sMatch == sHeritageNameLower then
					local sRaceName = StringManager.trim(DB.getValue(vRace, "name", ""));
					return sRaceName, vRace;
				end
			end
		end
	end

	return "", nil;
end

function addRaceDrop(nodeChar, sClass, sRecord)
	if sClass == "reference_race" then
		local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
		if not rAdd then
			return;
		end

		CharRaceManager.helperAddRaceMain(rAdd);
		CharRaceManager.helperAddRaceHeritageChoice(rAdd);

	elseif sClass == "reference_heritage" then
		local nodeSource = DB.findNode(sRecord);
		if not nodeSource then
			return;
		end

		local sHeritageName = StringManager.trim(DB.getValue(nodeSource, "name", ""));
		local sRaceName, nodeRace = CharRaceManager.getRaceFromHeritage(sHeritageName);
		if not nodeRace or ((sRaceName or "") == "") then
			CharManager.outputUserMessage("char_error_missingracefromheritage");
			return;
		end


		local rAdd = {
			nodeSource = nodeRace,
			sSourceClass = "reference_race",
			sSourceName = sRaceName,
			nodeChar = nodeChar,
			sCharName = StringManager.trim(DB.getValue(nodeChar, "name", "")),
			sHeritageChoice = sHeritageName,
		};
		CharRaceManager.helperAddRaceMain(rAdd);
		CharRaceManager.helperAddRaceHeritage(rAdd);
	end
end
function helperAddRaceMain(rAdd)
	-- Notification
	CharManager.outputUserMessage("char_abilities_message_raceadd", rAdd.sSourceName, rAdd.sCharName);

	-- Set name and link
	DB.setValue(rAdd.nodeChar, "race", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "racelink", "windowreference", "reference_race", rAdd.nodeSource.getPath());
	DB.setValue(rAdd.nodeChar, "heritagelink", "windowreference", "", "");

	-- Add racial traits
	for _,v in pairs(DB.getChildren(rAdd.nodeSource, "traits")) do
		CharRaceManager.addRaceTrait(rAdd.nodeChar, "reference_racialtrait", v.getPath());
	end
end

function helperAddRaceHeritageChoice(rAdd)
	local tRaceHeritageOptions = CharRaceManager.getRaceHeritageOptions(rAdd.sSourceName);
	if #tRaceHeritageOptions == 0 then
		return;
	end

	if #tRaceHeritageOptions == 1 then
		-- Automatically select only heritage
		rAdd.sHeritageChoice = tRaceHeritageOptions[1].text;
		CharRaceManager.helperAddRaceHeritage(rAdd);
	else
		-- Display dialog to choose heritage
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_build_title_selectheritage");
		local sMessage = Interface.getString("char_build_message_selectheritage");
		wSelect.requestSelection(sTitle, sMessage, tRaceHeritageOptions, CharRaceManager.callbackAddRaceHeritageChoice, rAdd);
	end
end
function callbackAddRaceHeritageChoice(tSelection, rAdd)
	if not tSelection or (#tSelection ~= 1) then
		CharManager.outputUserMessage("char_error_addheritage");
		return;
	end

	rAdd.sHeritageChoice = tSelection[1];
	CharRaceManager.helperAddRaceHeritage(rAdd);
end
function helperAddRaceHeritage(rAdd)
	if ((rAdd.sHeritageChoice or "") == "") then
		return;
	end

	-- Get heritage data path from name
	local sHeritagePath = nil;
	local tRaceHeritageOptions = CharRaceManager.getRaceHeritageOptions(rAdd.sSourceName);
	for _,v in ipairs(tRaceHeritageOptions) do
		if v.text == rAdd.sHeritageChoice then
			sHeritagePath = v.linkrecord;
			break;
		end
	end
	if ((sHeritagePath or "") == "") then
		CharManager.outputUserMessage("char_error_missingheritage");
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_abilities_message_heritageadd", rAdd.sHeritageChoice, rAdd.sCharName);

	-- Update race name and heritage link
	if rAdd.sHeritageChoice:match(rAdd.sSourceName) then
		DB.setValue(rAdd.nodeChar, "race", "string", rAdd.sHeritageChoice);
	else
		DB.setValue(rAdd.nodeChar, "race", "string", string.format("%s (%s)", rAdd.sSourceName, rAdd.sHeritageChoice));
	end
	DB.setValue(rAdd.nodeChar, "heritagelink", "windowreference", "reference_heritage", sHeritagePath);

	-- Add racial traits
	for _,v in pairs(DB.getChildren(DB.getPath(sHeritagePath, "traits"))) do
		CharRaceManager.addRaceTrait(rAdd.nodeChar, "reference_subracialtrait", v.getPath());
	end
end

function addRaceTrait(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	CharRaceManager.helperAddRaceTraitMainDrop(rAdd);
end
function helperAddRaceTraitMainDrop(rAdd)
	if rAdd.sSourceType == "ability score racial traits" then
		CharRaceManager.helperAddRaceTraitAbilityIncreaseDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "size" then
		CharRaceManager.helperAddRaceTraitSizeDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "base speed" then
		CharRaceManager.helperAddRaceTraitSpeedDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "darkvision" then
		CharRaceManager.helperAddRaceTraitDarkvisionDrop(rAdd);
		return;
		
	elseif rAdd.sSourceType == "superiordarkvision" then
		CharRaceManager.helperAddRaceTraitSuperiorDarkvisionDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "languages" then
		CharRaceManager.helperAddRaceTraitLanguagesDrop(rAdd);
		return;
		
	else
		local sText = DB.getText(rAdd.nodeSource, "text", "");
		CharManager.checkSkillProficiencies(rAdd.nodeChar, sText);
		
		-- Create standard trait entry
		local nodeNewTrait = CharRaceManager.helperAddRaceTraitStandard(rAdd);
		if not nodeNewTrait then
			return;
		end
		
		-- Special handling
		local sNameLower = rAdd.sSourceName:lower();
		if sNameLower == CharManager.TRAIT_NATURAL_ARMOR then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end

		-- Standard action addition handling
		CharManager.helperCheckActionsAdd(rAdd.nodeChar, rAdd.nodeSource, rAdd.sSourceType, "Race Actions/Effects");
	end
end

function helperAddRaceTraitStandard(rAdd)
	local nodeTraitList = DB.createChild(rAdd.nodeChar, "traitlist");
	if not nodeTraitList then
		return nil;
	end

	local nodeNewTrait = DB.createChild(nodeTraitList);
	if not nodeNewTrait then
		return nil;
	end

	CharManager.outputUserMessage("char_abilities_message_traitadd", rAdd.sSourceName, rAdd.sCharName);

	DB.copyNode(rAdd.nodeSource, nodeNewTrait);
	DB.setValue(nodeNewTrait, "locked", "number", 1);

	if rAdd.sSourceClass == "reference_racialtrait" then
		DB.setValue(nodeNewTrait, "type", "string", "racial");
	elseif rAdd.sSourceClass == "reference_subracialtrait" then
		DB.setValue(nodeNewTrait, "type", "string", "subracial");
	end

	return nodeNewTrait;
end
function helperAddRaceTraitAbilityIncreaseDrop(rAdd)
	local sAdjust = DB.getText(rAdd.nodeSource, "text", ""):lower();
    local aWords = StringManager.parseWords(sAdjust:lower());
	
	local aIncreases = {};
	local bChoice = false;
	local i = 1;
	while aWords[i] do
		if StringManager.isNumberString(aWords[i]) then
			local nMod = tonumber(aWords[i]) or 0;
			if nMod ~= 0 then
				if StringManager.contains(DataCommon.abilities, aWords[i+1]) then
					aIncreases[aWords[i+1]] = nMod;
				elseif StringManager.contains(DataCommon.abilities, aWords[i-1]) then
					aIncreases[aWords[i-1]] = nMod;
				else
					local j = i + 1;
					if StringManager.isWord(aWords[j], "bonus") then
						j = j + 1;
					end
					if StringManager.isPhrase(aWords, j, { "to", "one", "ability", "score" }) then
						bChoice = true;
					end
				end
			end
		end
		i = i + 1;
	end
	
	local bApplied = false;
	for k,v in pairs(aIncreases) do
		if StringManager.contains(DataCommon.abilities, k) then
			local sPath = "abilities." .. k .. ".score";
			DB.setValue(rAdd.nodeChar, sPath, "number", DB.getValue(rAdd.nodeChar, sPath, 10) + v);
			bApplied = true;
		end
	end
	
	if bChoice then
		local aAbilities = {};
		for _,v in ipairs(DataCommon.abilities) do
			table.insert(aAbilities, StringManager.capitalize(v));
		end
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_title_selectabilityincrease");
		local sMessage = Interface.getString("char_message_selectabilityincrease");
		wSelect.requestSelection(sTitle, sMessage, aAbilities, CharManager.onRaceAbilitySelect, rAdd.nodeChar, 1);
		bApplied = true;
	end
	
	return bApplied;
end
function helperAddRaceTraitSizeDrop(rAdd)
	local sSize = DB.getText(rAdd.nodeSource, "text", ""):lower();
	sSize = sSize:match("are (%w+) creatures");
	if not sSize then
		sSize = "medium";
	end

	if sSize == "small" then
		DB.setValue(rAdd.nodeChar, "ac.sources.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.melee.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.ranged.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.cmb.size", "number", -1);
		addSkillBonus(rAdd.nodeChar, "Stealth", 4);
	elseif sSize == "medium" then
		DB.setValue(rAdd.nodeChar, "ac.sources.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.melee.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.ranged.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.cmb.size", "number", 0);
	end
	DB.setValue(rAdd.nodeChar, "size", "string", StringManager.capitalize(sSize));
end
function helperAddRaceTraitSpeedDrop(rAdd)
	local s = DB.getText(rAdd.nodeSource, "text", "");

	local nSpeed, tSpecial = CharRaceManager.parseRaceSpeed(s);
	
	DB.setValue(rAdd.nodeChar, "speed.base", "number", nSpeed);
	CharManager.outputUserMessage("char_abilities_message_basespeedset", nSpeed, DB.getValue(rAdd.nodeChar, "name", ""));

	local sExistingSpecial = StringManager.trim(DB.getValue(rAdd.nodeChar, "speed.special", ""));
	local tExistingSpecial = StringManager.split(sExistingSpecial, ",", true);

	local tFinalSpecial = {};
	local tMatchCheck = {};
	for _,sSpecial in ipairs(tSpecial) do
		if not tMatchCheck[sSpecial] then
			table.insert(tFinalSpecial, sSpecial);
		end
	end
	for _,sSpecial in ipairs(tExistingSpecial) do
		if not tMatchCheck[sSpecial] then
			table.insert(tFinalSpecial, sSpecial);
		end
	end
	DB.setValue(rAdd.nodeChar, "speed.special", "string", table.concat(tFinalSpecial, ", "));
end
function helperAddRaceTraitDarkvisionDrop(rAdd)
	local tSenses = {};
	local sSenses = DB.getValue(rAdd.nodeChar, "senses", "");
	if sSenses ~= "" then
		table.insert(tSenses, sSenses);
	end
	
	local sNewSense;
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	if sText then
		local sDist = sText:match("%d+");
		if sDist then
			sNewSense = string.format("%s %s", rAdd.sSourceName, sDist);
		end
	end
	if not sNewSense then
		sNewSense = rAdd.sSourceName;
	end
	table.insert(tSenses, sNewSense);
	
	DB.setValue(rAdd.nodeChar, "senses", "string", table.concat(tSenses, ", "));
end
function helperAddRaceTraitLanguagesDrop(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", "");
    local aWords = StringManager.parseWords(sText);
	
	local aLanguages = {};
	local i = 1;
	while aWords[i] do
		if StringManager.isPhrase(aWords, i, { "begin", "play", "speaking" }) then
			local j = i + 3;
			while aWords[j] do
				if GameSystem.languages[aWords[j]] then
					table.insert(aLanguages, aWords[j]);
				elseif not StringManager.isWord(aWords[j], "and") then
					break;
				end
				j = j + 1;
			end
			break;
		end
		i = i + 1;
	end

	if #aLanguages == 0 then
		return false;
	end
	
	for s in ipairs(aLanguages) do
		CharManager.addLanguage(rAdd.nodeChar, s);
	end
end

function parseRaceSpeed(s)
	if (s or "") == "" then
		return 30, {};
	end

	local sSpeed = s:lower();
	local nSpeed = 30;
	local tSpecial = {};

	local sBaseSpeed = sSpeed:match("base speed of (%d+) feet");
	if sBaseSpeed then
		nSpeed = tonumber(sBaseSpeed) or 30;
	end
	
	local sSwimSpeed = sSpeed:match("swim speed of (%d+) feet");
	if sSwimSpeed then
		table.insert(tSpecial, "Swim " .. sSwimSpeed .. " ft.");
	end

	local sFlySpeed = sSpeed:match("fly speed of (%d+) feet");
	if sFlySpeed then
		table.insert(tSpecial, "Fly " .. sFlySpeed .. " ft.");
	end

	local sClimbSpeed = sSpeed:match("climb speed of (%d+) feet");
	if sClimbSpeed then
		table.insert(tSpecial, "Climb " .. sClimbSpeed .. " ft.");
	end
	
	local sBurrowSpeed = sSpeed:match("burrow speed of (%d+) feet");
	if sBurrowSpeed then
		table.insert(tSpecial, "Burrow " .. sBurrowSpeed .. " ft.");
	end

	return nSpeed, tSpecial;
end
