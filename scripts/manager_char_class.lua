TRAIT_MULTITALENTED = "multitalented";

CLASS_BAB_FAST = "fast";
CLASS_BAB_MEDIUM = "medium";
CLASS_BAB_SLOW = "slow";
CLASS_SAVE_GOOD = "good";
CLASS_SAVE_BAD = "bad";

CLASS_FEATURE_PROFICIENCY = "^weapon and armor proficiency$";
CLASS_FEATURE_DOMAINS = "^domains$";
CLASS_FEATURE_DOMAIN_SPELLS = "Domain Spells";

--
-- CLASS MANAGEMENT
--

function calcLevel(nodeChar)
	local nLevel = 0;
	
	for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
		nLevel = nLevel + DB.getValue(nodeChild, "level", 0);
	end
	
	DB.setValue(nodeChar, "level", "number", nLevel);
end

function sortClasses(a,b)
	return a.getName() < b.getName();
end

function getClassLevelSummary(nodeChar, bLong)
	if not nodeChar then
		return "";
	end
	
	local aClasses = {};

	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, sortClasses);
			
	local bLongClassNames = bLong and #aSorted <= 3;
	for _,nodeChild in pairs(aSorted) do
		local sClass = DB.getValue(nodeChild, "name", "");
		local nLevel = DB.getValue(nodeChild, "level", 0);
		if nLevel > 0 then
			nLevel = math.floor(nLevel*100)*0.01;
			if bLongClassNames then
				table.insert(aClasses, sClass .. " " .. nLevel);
			else
				table.insert(aClasses, string.sub(sClass, 1, 3) .. " " .. nLevel);
			end
		end
	end

	local sSummary = table.concat(aClasses, " / ");
	return sSummary;
end

function getCharLevel(nodeChar)
	local nTotal = 0;
	for _,v in pairs(DB.getChildren(nodeChar, "classes")) do
		local nClassLevel = DB.getValue(v, "level", 0);
		if nClassLevel > 0 then
			nTotal = nTotal + nClassLevel;
		end
	end
	return nTotal;
end
function getCharClassRecord(nodeChar, sClassName)
	if (sClassName or "") == "" then
		return nil;
	end
	local sClassNameLower = StringManager.trim(sClassName):lower();

	for _,v in pairs(DB.getChildren(nodeChar, "classes")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sClassNameLower then
			return v;
		end
	end
	return nil;
end

function helperAddClassArchetypeChoice(rAdd)
	local aArchetypes = { "Base Class" };
	rAdd.tArchetypes = DB.getChildren(rAdd.nodeSource, "archetypes");

	for _,vArchetype in pairs(rAdd.tArchetypes) do
		table.insert(aArchetypes, DB.getValue(vArchetype, "name", ""));
	end

	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_title_selectarchetype");
	local sMessage = Interface.getString("char_message_selectarchetype");
	wSelect.requestSelection(sTitle, sMessage, aArchetypes, CharClassManager.onClassArchetypeSelect, rAdd, 1);
end
function onClassArchetypeSelect(aSelection, rAdd)
	local sSelection = aSelection[1];
	if sSelection == "Base Class" then
		CharClassManager.helperAddClassMain(rAdd);
		return;
	end
	
	for _,vArchetype in pairs(rAdd.tArchetypes) do
		local sArchetype = DB.getValue(vArchetype, "name", "");
		if sArchetype == sSelection then
			local sFormat = Interface.getString("char_message_archetypeadd");
			local sMsg = string.format(sFormat, sArchetype, DB.getValue(rAdd.nodeChar, "name", ""));
			ChatManager.SystemMessage(sMsg);
			
			DB.setValue(rAdd.nodeCharClass, "archetype", "string", sArchetype);
		end
	end

	for _,vNodeArchetype in pairs(DB.getChildren(DB.getChild(rAdd.nodeSource, "archetypes"))) do
		if DB.getValue(rAdd.nodeCharClass, "archetype", "") == DB.getValue(vNodeArchetype, "name", "") then
			rAdd.nodeArchetype = vNodeArchetype;
			DB.setValue(rAdd.nodeCharClass, "shortcutarchetype", "windowreference", "referencearchetype", DB.getPath(rAdd.nodeArchetype));
			break;
		end
	end

	CharClassManager.helperAddClassMain(rAdd);
end

function helperAddClassFavoredChoice(rAdd)
	if rAdd.nCharLevel ~= 1 then
		CharClassManager.checkFavoredClassBonus(rAdd.nodeChar, rAdd.sSourceName);
		return;
	end
	local aClasses = {};
	
	local sRootMapping = LibraryData.getRootMapping("class");
	local wIndex, bWasIndexOpen = RecordManager.openRecordIndex(sRootMapping);
	
	if wIndex then
		local aMappings = LibraryData.getMappings("class");
		for _,vMapping in ipairs(aMappings) do
			for _,vClass in pairs(DB.getChildrenGlobal(vMapping)) do
				local sClassType = DB.getValue(vClass, "classtype");
				if (sClassType or "") ~= "prestige" then
					table.insert(aClasses, { text = DB.getValue(vClass, "name", ""), linkclass = "referenceclass", linkrecord = vClass.getPath() });
				end
			end
		end
		
		if not bWasIndexOpen then
			wIndex.close();
		end
	end
	
	table.sort(aClasses, function(a,b) return a.text < b.text end);
	
	local nFavoredClass = 1;
	if CharManager.hasTrait(rAdd.nodeChar, TRAIT_MULTITALENTED) then
		nFavoredClass = nFavoredClass + 1;
	end
	
	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_title_selectfavoredclass");
	local sMessage;
	if nFavoredClass > 1 then
		sMessage = string.format(Interface.getString("char_message_selectfavoredclasses"), nFavoredClass);
	else
		sMessage = Interface.getString("char_message_selectfavoredclass");
	end
	local rFavoredClassSelect = { nodeChar = rAdd.nodeChar, sCurrentClass = rAdd.sSourceName, aClassesOffered = aClasses };
	wSelect.requestSelection(sTitle, sMessage, aClasses, CharClassManager.onFavoredClassSelect, rFavoredClassSelect, nFavoredClass);
end

--

function addClass(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_message_classadd", rAdd.sSourceName, rAdd.sCharName);

	CharClassManager.helperAddClassLevel(rAdd);
	CharClassManager.helperAddClassFavoredChoice(rAdd);

	-- We have to intercept because we might want to change skills and features based on archetype
	if DB.getChildCount(rAdd.nodeSource, "archetypes") > 0 and rAdd.nCharClassLevel == 1 then
		CharClassManager.helperAddClassArchetypeChoice(rAdd);
	else
		CharClassManager.helperAddClassMain(rAdd);
	end
end

function helperAddClassMain(rAdd)
	CharClassManager.helperAddClassHP(rAdd);
	CharClassManager.helperAddClassBAB(rAdd);
	CharClassManager.helperAddClassSaves(rAdd);
	CharClassManager.helperAddClassSkills(rAdd);
	CharClassManager.helperAddClassFeatures(rAdd);
	CharClassManager.helperAddClassSpellcasting(rAdd);
end
	
function helperAddClassLevel(rAdd)
	-- Check to see if the character already has this class; or create a new class entry
	rAdd.nodeCharClass = CharClassManager.getCharClassRecord(rAdd.nodeChar, rAdd.sSourceName);
	if not rAdd.nodeCharClass then
		local nodeClassList = DB.createChild(rAdd.nodeChar, "classes");
		if not nodeClassList then
			return;
		end
		rAdd.nodeCharClass = DB.createChild(nodeClassList);
		rAdd.bNewCharClass = true;
	end

	-- Add basic class information
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "name", "string", rAdd.sSourceName);
		rAdd.nCharClassLevel = 1;
	else
		rAdd.nCharClassLevel = DB.getValue(rAdd.nodeCharClass, "level", 0) + 1;
	end
	DB.setValue(rAdd.nodeCharClass, "level", "number", rAdd.nCharClassLevel);
	DB.setValue(rAdd.nodeCharClass, "shortcut", "windowreference", "referenceclass", DB.getPath(rAdd.nodeSource));
	
	-- Calculate total level
	rAdd.nCharLevel = CharClassManager.getCharLevel(rAdd.nodeChar);

	-- Get existing archetype on level-up
	if DB.getValue(rAdd.nodeCharClass, "archetype", "") == "" then
		return;
	end
	for _,vNodeArchetype in pairs(DB.getChildren(DB.getChild(rAdd.nodeSource, "archetypes"))) do
		if DB.getValue(rAdd.nodeCharClass, "archetype", "") == DB.getValue(vNodeArchetype, "name", "") then
			rAdd.nodeArchetype = vNodeArchetype;
			break;
		end
	end
end

function helperAddClassHP(rAdd)
	-- Translate Hit Die
	local bHDFound = false;
	local nHDMult, nHDSides;
	local sHD = DB.getText(rAdd.nodeSource, "hitdie");
	if sHD then
		local sMult, sSides = sHD:match("(%d?)d(%d+)");
		nHDMult = tonumber(sMult) or 1;
		nHDSides = tonumber(sSides) or 8;
		bHDFound = true;
	end
	if not bHDFound then
		CharManager.outputUserMessage("char_error_addclasshd");
	end

	-- Add hit points based on level added
	local nHP = DB.getValue(rAdd.nodeChar, "hp.total", 0);
	local nCHP = DB.getValue(rAdd.nodeChar, "hp.class", 0);
	local nAHP = DB.getValue(rAdd.nodeChar, "hp.ability", 0);
	local nConBonus = DB.getValue(rAdd.nodeChar, "abilities.constitution.bonus", 0);
	local nAddHP;

	if rAdd.nCharLevel == 1 then
		nAddHP = (nHDMult * nHDSides);
		CharManager.outputUserMessage("char_message_classhpaddmax", rAdd.sSourceName, rAdd.sCharName, nAddHP);
	else
		nAddHP = math.floor(((nHDMult * (nHDSides + 1)) / 2) + 0.5);
		CharManager.outputUserMessage("char_message_classhpaddavg", rAdd.sSourceName, rAdd.sCharName, nAddHP);
	end

	nCHP = nCHP + nAddHP;
	nAHP = nAHP + nConBonus;
	nHP = nCHP + nAHP;

	DB.setValue(rAdd.nodeChar, "hp.class", "number", nCHP);
	DB.setValue(rAdd.nodeChar, "hp.ability", "number", nAHP);
	DB.setValue(rAdd.nodeChar, "hp.total", "number", nHP);
end

function helperAddClassBAB(rAdd)
	local sBAB = StringManager.trim(DB.getValue(rAdd.nodeSource, "bab", "")):lower();
	if StringManager.contains({ CLASS_BAB_FAST, CLASS_BAB_MEDIUM, CLASS_BAB_SLOW }, sBAB) then
		local nAddBAB = 0;
		if sBAB == CLASS_BAB_FAST then
			nAddBAB = 1;
		elseif sBAB == CLASS_BAB_MEDIUM then
			if rAdd.nCharClassLevel % 4 ~= 1 then
				nAddBAB = 1;
			end
		elseif sBAB == CLASS_BAB_SLOW then
			if rAdd.nCharClassLevel % 2 == 0 then
				nAddBAB = 1;
			end
		end
		
		if nAddBAB > 0 then
			DB.setValue(rAdd.nodeChar, "attackbonus.base", "number", DB.getValue(rAdd.nodeChar, "attackbonus.base", 0) + nAddBAB);
		end
	end
end

function helperAddClassSaves(rAdd)
	local sClassType = DB.getValue(rAdd.nodeSource, "classtype");
	local sFort = StringManager.trim(DB.getValue(rAdd.nodeSource, "fort", "")):lower();
	local sRef = StringManager.trim(DB.getValue(rAdd.nodeSource, "ref", "")):lower();
	local sWill = StringManager.trim(DB.getValue(rAdd.nodeSource, "will", "")):lower();
	local bPrestige = (sClassType == "prestige");

	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sFort) then
		local nAddSave = 0;
		if sFort == CLASS_SAVE_GOOD then
			if bPrestige then
				if rAdd.nCharClassLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel == 1 then
					nAddSave = 2;
				elseif rAdd.nCharClassLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sFort == CLASS_SAVE_BAD then
			if bPrestige then
				if rAdd.nCharClassLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(rAdd.nodeChar, "fortitude", "base", nAddSave);
		end
	end
	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sRef) then
		local nAddSave = 0;
		if sRef == CLASS_SAVE_GOOD then
			if bPrestige then
				if rAdd.nCharClassLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel == 1 then
					nAddSave = 2;
				elseif rAdd.nCharClassLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sRef == CLASS_SAVE_BAD then
			if bPrestige then
				if rAdd.nCharClassLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(rAdd.nodeChar, "reflex", "base", nAddSave);
		end
	end
	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sWill) then
		local nAddSave = 0;
		if sWill == CLASS_SAVE_GOOD then
			if bPrestige then
				if rAdd.nCharClassLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel == 1 then
					nAddSave = 2;
				elseif rAdd.nCharClassLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sWill == CLASS_SAVE_BAD then
			if bPrestige then
				if rAdd.nCharClassLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if rAdd.nCharClassLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(rAdd.nodeChar, "will", "base", nAddSave);
		end
	end
end

function helperAddClassSkills(rAdd)
	-- Potential Archetype skills
	local sArchetypeSkillReplace, sArchetypeSkillWith = "", "";

	if rAdd.nodeArchetype then
		sArchetypeSkillReplace = DB.getValue(rAdd.nodeArchetype, "skill.replace", "");
		sArchetypeSkillWith = DB.getValue(rAdd.nodeArchetype, "skill.with", "");
	end

	local nSkillPoints = DB.getValue(rAdd.nodeSource, "skillranks", 0);
	local sClassSkills = DB.getValue(rAdd.nodeSource, "classskills", "");

	if sArchetypeSkillReplace ~= "" then
		sArchetypeSkillReplace = sArchetypeSkillReplace:gsub("%s?and", ",");
	end
	if sArchetypeSkillReplace:match(",") then
		for _,vSkillReplace in ipairs(StringManager.split(sArchetypeSkillReplace, ",", true)) do
			vSkillReplace = vSkillReplace:gsub("%(", "%%(");
			vSkillReplace = vSkillReplace:gsub("%)", "%%)");
			sClassSkills = sClassSkills:gsub(vSkillReplace, "");
		end
	end
	if sArchetypeSkillWith ~= "" then
		sArchetypeSkillWith = sArchetypeSkillWith:gsub("%s?and", ",");
		sClassSkills = sClassSkills .. ", " .. sArchetypeSkillWith;
	end
	
	-- Skill Points
	if nSkillPoints > 0 then
		local nSkillAbilityScore = DB.getValue(rAdd.nodeChar, "abilities.intelligence.score", 10);
		local nAbilitySkillPoints = math.floor((nSkillAbilityScore - 10) / 2);
		local nBonusSkillPoints = 0;
		if CharManager.hasTrait(rAdd.nodeChar, "Skilled") then
			nBonusSkillPoints = nBonusSkillPoints + 1;
		end
		
		DB.setValue(rAdd.nodeCharClass, "skillranks", "number", DB.getValue(rAdd.nodeCharClass, "skillranks", 0) + nSkillPoints + nAbilitySkillPoints + nBonusSkillPoints);
		
		local sPoints = tostring(nSkillPoints) .. "+" .. tostring(nAbilitySkillPoints);
		if nBonusSkillPoints > 0 then
			sPoints = sPoints .. "+" .. nBonusSkillPoints;
		end
	end
	
	-- Class Skills
	if rAdd.nCharClassLevel == 1 and sClassSkills ~= "" then
		local aClassSkillsAdded = {};
		
		sClassSkills = sClassSkills:gsub(" and ", "");
		local aClassSkills = StringManager.split(sClassSkills, ",", true);
		for _,vSkill in ipairs(aClassSkills) do
			local sSkillAbility = vSkill:match("%((%w+)%)$");
			if sSkillAbility and (DataCommon.ability_ltos[sSkillAbility:lower()] or DataCommon.ability_stol[sSkillAbility:upper()]) then
				sSkillAbility = sSkillAbility:gsub("%s*%(%w+%)$", "");
				vSkill = vSkill:gsub("%s*%((%w+)%)$", "");
			end
			local sSkill = vSkill:match("[^(]+%w");
			if sSkill then
				if CharClassManager.addClassSkill(rAdd.nodeChar, sSkill, vSkill:match("%(([^)]+)%)")) then
					table.insert(aClassSkillsAdded, vSkill);
				end
			end
		end
	end
end

function helperAddClassSpellcasting(rAdd)
	rAdd.sSpellcastingType = DB.getValue(rAdd.nodeSource, "spellcasting", "");
	rAdd.sSpellcastingStat = DB.getValue(rAdd.nodeSource, "stat", "");

	-- Spellcasting
	if rAdd.sSpellcastingType ~= "" and rAdd.sSpellcastingStat ~= "" then
		CharClassManager.handleClassFeatureSpells(rAdd);
		CharClassManager.addClassSpellLevel(rAdd);
	end
end

function helperAddClassFeatures(rAdd)
	for _,vFeature in pairs(DB.getChildren(rAdd.nodeSource, "classfeatures")) do
		if DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel then
			local bReplaced = false;
			for _,vArchetypeFeature in pairs(DB.getChildren(rAdd.nodeArchetype, "archetypefeatures")) do
				if DB.getValue(vArchetypeFeature, "level", 0) == rAdd.nCharClassLevel then
					local sClassFeatureName = DB.getValue(vFeature, "name", "");
					local sArchetypeFeatureReplace = DB.getValue(vArchetypeFeature, "replace", "");
					if sArchetypeFeatureReplace == sClassFeatureName then
						CharClassManager.addClassFeature(rAdd.nodeChar, "referenceclassability", vArchetypeFeature.getPath());
						bReplaced = true;
						break;
					end
				end
			end
			if not bReplaced then
				CharClassManager.addClassFeature(rAdd.nodeChar, "referenceclassability", vFeature.getPath());
			end
		end
	end
end

function addClassFeature(nodeChar, sClass, sRecord, nodeTargetList)
	local nodeSource = CharManager.resolveRefNode(sRecord);
	if not nodeSource then
		return false;
	end
	
	local sClassName = StringManager.strip(DB.getValue(nodeSource, "...name", ""));
	local sFeatureName = DB.getValue(nodeSource, "name", "");
	local sFeatureType = StringManager.strip(sFeatureName):lower();

	local bCreateFeatureEntry = false;
	if not nodeTargetList and sFeatureType:match(CLASS_FEATURE_PROFICIENCY) then
		CharManager.handleProficiencies(nodeChar, nodeSource);
	else
		if not CharManager.handleDuplicateFeatures(nodeChar, nodeSource, sFeatureType, nodeTargetList) then
			bCreateFeatureEntry = true;
			if sFeatureType:match(CLASS_FEATURE_DOMAINS) then
				CharClassManager.handleClassFeatureDomains(nodeChar);
			end
		end
	end
	if bCreateFeatureEntry then
		if not nodeTargetList then
			nodeTargetList = nodeChar.createChild("specialabilitylist");
			if not nodeTargetList then
				return false;
			end
		end
		local vNew = nodeTargetList.createChild();
		DB.copyNode(nodeSource, vNew);
		DB.setValue(vNew, "name", "string", sFeatureName);
		DB.setValue(vNew, "source", "string", sClassName);
		DB.setValue(vNew, "locked", "number", 1);
	end

	local sFormat = Interface.getString("char_message_classfeatureadd");
	local sMsg = string.format(sFormat, sFeatureName, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	return true;
end

function addClassSkill(nodeChar, sSkill, sParens)
	if not sSkill then
		return false;
	end
	sSkill = StringManager.capitalizeAll(sSkill);
	sSkill = sSkill:gsub("Of", "of");
	local t = DataCommon.skilldata[sSkill];
	if not t then
		return false;
	end
	
	if t.sublabeling then
		if sParens then
			sParens = sParens:gsub(" and ", ",");
			sParens = sParens:gsub("all skills,? taken individually", "");
			sParens = sParens:gsub("all", "");
		end
		local aSpecialties = StringManager.split(sParens, ",", true);
		if #aSpecialties == 0 then
			local nodeSkill = CharManager.getSkillNode(nodeChar, sSkill);
			if not nodeSkill then
				return false;
			end
			DB.setValue(nodeSkill, "state", "number", 1);
		else
			for _, sSpecialty in ipairs(aSpecialties) do
				local nodeSkill = CharManager.getSkillNode(nodeChar, sSkill, StringManager.capitalize(sSpecialty));
				if nodeSkill then
					DB.setValue(nodeSkill, "state", "number", 1);
				end
			end
		end
	else
		local nodeSkill = CharManager.getSkillNode(nodeChar, sSkill);
		if not nodeSkill then
			return false;
		end
		
		DB.setValue(nodeSkill, "state", "number", 1);
	end
end

function handleClassFeatureDomains(nodeChar)
	local nodeSpellClassList = nodeChar.createChild("spellset");
	local nodeNewSpellClass = nodeSpellClassList.createChild();
	DB.setValue(nodeNewSpellClass, "label", "string", CLASS_FEATURE_DOMAIN_SPELLS);
	DB.setValue(nodeNewSpellClass, "dc.ability", "string", "wisdom");
	return true;
end

function handleClassFeatureSpells(rAdd)
	local sClassName = DB.getValue(rAdd.nodeCharClass, "name", "");
	local nodeSpellClassList = rAdd.nodeChar.createChild("spellset");
	local nCount = nodeSpellClassList.getChildCount();

	if nCount == 0 then
		local nodeNewSpellClass = nodeSpellClassList.createChild();
		DB.setValue(nodeNewSpellClass, "label", "string", sClassName, "");
		DB.setValue(nodeNewSpellClass, "dc.ability", "string", rAdd.sSpellcastingStat);
		DB.setValue(nodeNewSpellClass, "type", "string", rAdd.sSpellcastingType);
	else
		for _,v in pairs(nodeSpellClassList.getChildren()) do
			local sExistingClassName = DB.getValue(v, "label", "");
			if sClassName ~= sExistingClassName then
				local nodeNewSpellClass = nodeSpellClassList.createChild();
				DB.setValue(nodeNewSpellClass, "label", "string", sClassName, "");
				DB.setValue(nodeNewSpellClass, "dc.ability", "string", rAdd.sSpellcastingStat);
				DB.setValue(nodeNewSpellClass, "type", "string", rAdd.sSpellcastingType);
			end
		end
	end
end

function addClassSpellLevel(rAdd)
	for _,v in pairs(DB.getChildren(rAdd.nodeChar, "spellset")) do
		if DB.getValue(v, "label", "") == rAdd.sSourceName then
			CharClassManager.addClassSpellLevelHelper(v);
		end
	end
end

function addClassSpellLevelHelper(nodeSpellClass)
	local nClassLevel = DB.getValue(nodeSpellClass, "classlevel", 0) + 1;
	local sType = DB.getValue(nodeSpellClass, "type", "");
	local tClassSpellLvl = {
		["Partial"] = {0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4},
		["Semi"] = {1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,6,6},
		["Full"] = {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9,9}
	}
	-- Increment caster level
	DB.setValue(nodeSpellClass, "cl", "number", DB.getValue(nodeSpellClass, "cl", 0) + 1);
	DB.setValue(nodeSpellClass, "classlevel", "number", nClassLevel);

	-- Set available spell level
	local nSpellLevel = tClassSpellLvl[sType][nClassLevel];
	DB.setValue(nodeSpellClass, "availablelevel", "number", nSpellLevel);
end

function onFavoredClassSelect(aSelection, rFavoredClassSelect)
	local aClassToAdd = {};
	for _,vClassSelect in ipairs(aSelection) do
		local bHandled = false;
		for _,vClass in pairs(DB.getChildren(rFavoredClassSelect.nodeChar, "classes")) do
			if DB.getValue(vClass, "name", "") == vClassSelect then
				DB.setValue(vClass, "favored", "number", 1);
				bHandled = true;
				break;
			end
		end
		if not bHandled then
			table.insert(aClassToAdd, vClassSelect);
		end
	end
	CharClassManager.checkFavoredClassBonus(rFavoredClassSelect.nodeChar, rFavoredClassSelect.sCurrentClass);
	for _,vClassToAdd in ipairs(aClassToAdd) do
		local nodeList = rFavoredClassSelect.nodeChar.createChild("classes");
		if nodeList then
			local nodeClass = nodeList.createChild();
			DB.setValue(nodeClass, "name", "string", vClassToAdd);
			DB.setValue(nodeClass, "favored", "number", 1);
			for _,vClassOffered in ipairs(rFavoredClassSelect.aClassesOffered) do
				if vClassOffered.text == vClassToAdd then
					DB.setValue(nodeClass, "shortcut", "windowreference", vClassOffered.linkclass, vClassOffered.linkrecord);
					break;
				end
			end
		end
	end
end

function checkFavoredClassBonus(nodeChar, sClassName)
	local bApply = false;
	for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(vClass, "name", "") == sClassName and DB.getValue(vClass, "favored", 0) == 1 then
			bApply = true;
			break;
		end
	end
	if bApply then
		local aOptions = {};
		table.insert(aOptions, Interface.getString("char_value_favoredclasshpbonus"));
		table.insert(aOptions, Interface.getString("char_value_favoredclassskillbonus"));
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_title_selectfavoredclassbonus");
		local sMessage = Interface.getString("char_message_selectfavoredclassbonus");
		local rFavoredClassBonusSelect = { nodeChar = nodeChar, sCurrentClass = sClassName };
		wSelect.requestSelection(sTitle, sMessage, aOptions, CharClassManager.onFavoredClassBonusSelect, rFavoredClassBonusSelect, 1);
		bApplied = true;
	end
end

function onFavoredClassBonusSelect(aSelection, rFavoredClassBonusSelect)
	if #aSelection == 0 then
		return;
	end
	if aSelection[1] == Interface.getString("char_value_favoredclasshpbonus") then
		DB.setValue(rFavoredClassBonusSelect.nodeChar, "hp.favored", "number", DB.getValue(rFavoredClassBonusSelect.nodeChar, "hp.favored", 0) + 1);
		
		local sMsg = string.format(Interface.getString("char_message_favoredclasshpadd"), DB.getValue(rFavoredClassBonusSelect.nodeChar, "name", ""));
		ChatManager.SystemMessage(sMsg);
	elseif aSelection[1] == Interface.getString("char_value_favoredclassskillbonus") then
		local nodeClass = CharManager.getClassNode(rFavoredClassBonusSelect.nodeChar, rFavoredClassBonusSelect.sCurrentClass);
		if nodeClass then
			DB.setValue(nodeClass, "skillranks", "number", DB.getValue(nodeClass, "skillranks", 0) + 1);
		end
		
		local sMsg = string.format(Interface.getString("char_message_favoredclassskilladd"), DB.getValue(rFavoredClassBonusSelect.nodeChar, "name", ""));
		ChatManager.SystemMessage(sMsg);
	end
	DB.setValue(rFavoredClassBonusSelect.nodeChar, "hp.total", "number", DB.getValue(rFavoredClassBonusSelect.nodeChar, "hp.favored", 0) + DB.getValue(rFavoredClassBonusSelect.nodeChar, "hp.total", 0));
end
