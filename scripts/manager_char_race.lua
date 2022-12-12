-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function addRace(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end
	
	local sRace = DB.getValue(rAdd.nodeSource, "name", "");
	
	local sFormat = Interface.getString("char_message_raceadd");
	local sMsg = string.format(sFormat, sRace, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	DB.setValue(nodeChar, "race", "string", sRace);
	DB.setValue(nodeChar, "racelink", "windowreference", sClass, rAdd.nodeSource.getPath());
	
	if DB.getChildCount(rAdd.nodeSource, "heritages") > 0 then
		handleRacialHeritage(rAdd);
	else
		for _,v in pairs(DB.getChildren(rAdd.nodeSource, "racialtraits")) do
			addRacialTrait(nodeChar, "referenceracialtrait", v.getPath());
		end
	end
end

function handleRacialHeritage(rAdd)
	local aHeritages = { "None" };
	local tHeritages = DB.getChildren(rAdd.nodeSource, "heritages");

	for _,v in pairs(tHeritages) do
		table.insert(aHeritages, DB.getValue(v, "name", ""));
	end

	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_title_selectheritage");
	local sMessage = Interface.getString("char_message_selectheritage");
	local rHeritageSelect = { nodeChar = rAdd.nodeChar, tHeritages = tHeritages, nodeSource = rAdd.nodeSource };
	wSelect.requestSelection(sTitle, sMessage, aHeritages, CharRaceManager.onRaceHeritageSelect, rHeritageSelect, 1);
end

function onRaceHeritageSelect(aSelection, rHeritageSelect)
	local tHeritageTraits = {};
	local sSelection = aSelection[1];
	if sSelection ~= "None" then
		for _,v in pairs(rHeritageSelect.tHeritages) do
			local sHeritage = DB.getValue(v, "name", "");
			if sHeritage == sSelection then
				tHeritageTraits = v.getChild("heritagetraits").getChildren();
	
				local sFormat = Interface.getString("char_message_heritageadd");
				local sMsg = string.format(sFormat, sHeritage, DB.getValue(rHeritageSelect.nodeChar, "name", ""));
				ChatManager.SystemMessage(sMsg);
				
				DB.setValue(rHeritageSelect.nodeChar, "race", "string", DB.getValue(rHeritageSelect.nodeChar, "race", "") .. " (" .. sHeritage .. ")");
			end
		end
	
		for _,heritageTrait in pairs(tHeritageTraits) do
			addRacialTrait(rHeritageSelect.nodeChar, "referenceracialtrait", heritageTrait.getPath());
		end
	end
	
	for _,v in pairs(DB.getChildren(rHeritageSelect.nodeSource, "racialtraits")) do
		addRacialTrait(rHeritageSelect.nodeChar, "referenceracialtrait", v.getPath());
	end
end

function addRacialTrait(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	CharRaceManager.helperAddRaceTraitMain(rAdd);
end

function helperAddRaceTraitMain(rAdd)
	for _,v in pairs(DB.getChildren(rAdd.nodeChar, "traitlist")) do
		local sExistingTrait = DB.getValue(v, "name", "");
		if sExistingTrait == rAdd.sSourceName then
			return;
		end
	end
	
	handleRacialBasicTrait(rAdd);
	if rAdd.sSourceType == "abilityscoreracialtraits" then
		handleRacialAbilities(rAdd);

	elseif rAdd.sSourceType == "languages" then
		handleRacialLanguages(rAdd);

	elseif rAdd.sSourceType == "size" then
		handleRacialSize(rAdd);
	
	elseif rAdd.sSourceType == "basespeed" then
		handleRacialSpeed(rAdd);
	
	elseif rAdd.sSourceType == "darkvision" or rAdd.sSourceType == "superiordarkvision" or rAdd.sSourceType == "lowlightvision" then
		handleRacialVision(rAdd);
		
	elseif rAdd.sSourceType == "weaponfamiliarity" then
		CharManager.handleProficiencies(rAdd.nodeChar, rAdd.nodeSource);
	else
		if not checkForRacialAbilityInName(rAdd) then
			checkForRacialSkillBonus(rAdd);
			checkForRacialSaveBonus(rAdd);
		end
	end

	CharManager.outputUserMessage("char_message_racialtraitadd", rAdd.sSourceName, rAdd.sCharName);
	return true;
end

function handleRacialBasicTrait(rAdd)
	local nodeTraitList = DB.createChild(rAdd.nodeChar, "traitlist");
	if not nodeTraitList then
		return nil;
	end

	local nodeNewTrait = DB.createChild(nodeTraitList);
	if not nodeNewTrait then
		return nil;
	end

	DB.copyNode(rAdd.nodeSource, nodeNewTrait);
	DB.setValue(nodeNewTrait, "locked", "number", 1);

	if rAdd.sSourceClass == "referenceracialtrait" then
		DB.setValue(nodeNewTrait, "type", "string", "racial");
	elseif rAdd.sSourceClass == "referenceheritagetrait" then
		DB.setValue(nodeNewTrait, "type", "string", "heritage");
	end

	return nodeNewTrait;
end

function handleRacialAbilities(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", ""):lower();
	local aWords = StringManager.parseWords(sText);
	
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

function handleRacialLanguages(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text");
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
	
	for _,v in ipairs(aLanguages) do
		CharManager.addLanguage(rAdd.nodeChar, v);
	end
	return true;
end

function handleRacialSize(rAdd)
	local sSize = "";
	local sText = DB.getText(rAdd.nodeSource, "text"):lower();
	if sText:match("medium") then
		sSize = "medium";
	elseif sText:match("small") then
		sSize = "small";
	end
	
	if sSize == "" then
		return false;
	end
	
	DB.setValue(rAdd.nodeChar, "size", "string", StringManager.capitalize(sSize));
	if sSize == "small" then
		DB.setValue(rAdd.nodeChar, "ac.sources.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.melee.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.ranged.size", "number", 1);
		DB.setValue(rAdd.nodeChar, "attackbonus.cmb.size", "number", -1);
		CharManager.addSkillBonus(rAdd.nodeChar, "Stealth", 4);
	elseif sSize == "medium" then
		DB.setValue(rAdd.nodeChar, "ac.sources.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.melee.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.ranged.size", "number", 0);
		DB.setValue(rAdd.nodeChar, "attackbonus.cmb.size", "number", 0);
	end
	return true;
end

function handleRacialSpeed(rAdd)
	local nBaseSpeed = 0;
	local sSpeed = DB.getText(rAdd.nodeSource, "text");
	local sBaseSpeed = sSpeed:match("base speed of (%d+) feet");
	if sBaseSpeed then
		nBaseSpeed = sBaseSpeed;
	end
	
	if nBaseSpeed ~= 0 then
		DB.setValue(rAdd.nodeChar, "speed.base", "number", nBaseSpeed);
	else
		return false;
	end

	return true;
end

function handleRacialVision(rAdd)
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

function onRaceAbilitySelect(aSelection, nodeChar)
	for _,sAbility in ipairs(aSelection) do
		local k = sAbility:lower();
		if StringManager.contains(DataCommon.abilities, k) then
			local sPath = "abilities." .. k .. ".score";
			DB.setValue(nodeChar, sPath, "number", DB.getValue(nodeChar, sPath, 10) + 2);
		end
	end
end

function checkForRacialAbilityInName(rAdd)
	local bHandled = false;
	local aWords = StringManager.parseWords(rAdd.sSourceType);
	if #aWords > 0 then
		local bRaceAttInName = true;
		local i = 1;
		while aWords[i] do
			if not StringManager.isNumberString(aWords[i]) and not StringManager.contains(DataCommon.abilities, aWords[i]) then
				bRaceAttInName = false;
				break;
			end
			i = i + 1;
		end
		if bRaceAttInName then
			bHandled = handleRacialAbilities(rAdd);
		end
	end
	return bHandled;
end

function checkForRacialSkillBonus(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	sText = sText:gsub(" due to their fearsome nature%.", "."); -- Half-orc Intimidating
	for sMod, sSkills in sText:gmatch("%+(%d) racial bonus on ([^.]+) checks[.;,]") do
		local nMod = tonumber(sMod) or 0;
		if sSkills and nMod ~= 0 then
			local aSkills = {};
			sSkills = sSkills:gsub(",? and ", ",");
			aSkills = StringManager.split(sSkills, ",", true);
			for _,vSkill in ipairs(aSkills) do
				vSkill = vSkill:gsub(" checks$", "");
				vSkill = vSkill:gsub(" skill$", "");
				local sSpecialty = vSkill:match("%(%w+%)");
				if sSpecialty then
					vSkill = StringManager.trim(vSkill:match("[^(]*"));
				end
				CharManager.addSkillBonus(rAdd.nodeChar, vSkill, nMod, sSpecialty);
			end
		end
	end
end

function checkForRacialSaveBonus(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	local sMod = sText:match("%+(%d) racial bonus on all saving throws%.");
	local nMod = tonumber(sMod) or 0;
	if nMod ~= 0 then
		CharManager.addSaveBonus(rAdd.nodeChar, "fortitude", "misc", nMod);
		CharManager.addSaveBonus(rAdd.nodeChar, "reflex", "misc", nMod);
		CharManager.addSaveBonus(rAdd.nodeChar, "will", "misc", nMod);
	end
end
