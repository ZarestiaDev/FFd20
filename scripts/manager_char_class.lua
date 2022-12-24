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

--

function addClass(nodeChar, sClass, sRecord)
	local nodeSource = CharManager.resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	local nodeList = nodeChar.createChild("classes");
	if not nodeList then
		return;
	end
	
	local sClassName = DB.getValue(nodeSource, "name", "");
	local sClassNameLower = StringManager.trim(sClassName):lower();
	
	local sFormat = Interface.getString("char_message_classadd");
	local sMsg = string.format(sFormat, sClassName, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	-- Try and match an existing class entry, or create a new one
	local nodeClass = nil;
	for _,v in pairs(nodeList.getChildren()) do
		local sExistingClassName = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if (sExistingClassName == sClassNameLower) and (sExistingClassName ~= "") then
			nodeClass = v;
			break;
		end
	end
	local nLevel = 1;
	local bExistingClass = false;
	if nodeClass then
		bExistingClass = true;
		nLevel = DB.getValue(nodeClass, "level", 1) + 1;
	else
		nodeClass = nodeList.createChild();
	end

	if not bExistingClass then
		DB.setValue(nodeClass, "name", "string", sClassName);
	end
	DB.setValue(nodeClass, "level", "number", nLevel);
	DB.setValue(nodeClass, "shortcut", "windowreference", sClass, sRecord);

	local nTotalLevel = 0;
	for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
		nTotalLevel = nTotalLevel + DB.getValue(vClass, "level", 0);
	end

	applyClassStats(nodeChar, nodeClass, nodeSource, nLevel, nTotalLevel);
	
	for _,v in pairs(DB.getChildren(nodeSource, "classfeatures")) do
		if DB.getValue(v, "level", 0) == nLevel then
			addClassFeature(nodeChar, "referenceclassability", v.getPath());
		end
	end

	addClassSpellLevel(nodeChar, sClassName);

	if nTotalLevel == 1 then
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
		if CharManager.hasTrait(nodeChar, TRAIT_MULTITALENTED) then
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
		local rFavoredClassSelect = { nodeChar = nodeChar, sCurrentClass = sClassName, aClassesOffered = aClasses };
		wSelect.requestSelection(sTitle, sMessage, aClasses, CharManager.onFavoredClassSelect, rFavoredClassSelect, nFavoredClass);
	else
		checkFavoredClassBonus(nodeChar, sClassName);
	end
end

function applyClassStats(nodeChar, nodeClass, nodeSource, nLevel, nTotalLevel)
	local sClassType = DB.getValue(nodeSource, "classtype");
	local sHD = StringManager.trim(DB.getValue(nodeSource, "hitdie", ""));
	local sSpellcastingType = DB.getValue(nodeSource, "spellcasting", "");
	local sSpellcastingStat = DB.getValue(nodeSource, "stat", "");
	local sBAB = StringManager.trim(DB.getValue(nodeSource, "bab", "")):lower();
	local sFort = StringManager.trim(DB.getValue(nodeSource, "fort", "")):lower();
	local sRef = StringManager.trim(DB.getValue(nodeSource, "ref", "")):lower();
	local sWill = StringManager.trim(DB.getValue(nodeSource, "will", "")):lower();
	local nSkillPoints = DB.getValue(nodeSource, "skillranks", 0);
	local sClassSkills = DB.getValue(nodeSource, "classskills", "");
	local bPrestige = (sClassType == "prestige");

	-- Spellcasting
	if sSpellcastingType ~= "" and sSpellcastingStat ~= "" then
		handleClassFeatureSpells(nodeChar, nodeClass, sSpellcastingStat, sSpellcastingType);
	end

	-- Hit points
	local sHDMult, sHDSides = sHD:match("^(%d?)d(%d+)");
	if sHDSides then
		local nHDMult = tonumber(sHDMult) or 1;
		local nHDSides = tonumber(sHDSides) or 8;

		local nHP = DB.getValue(nodeChar, "hp.total", 0);
		local nCHP = DB.getValue(nodeChar, "hp.class", 0);
		local nAHP = DB.getValue(nodeChar, "hp.ability", 0);
		local nConBonus = DB.getValue(nodeChar, "abilities.constitution.bonus", 0);
		if nTotalLevel == 1 then
			local nAddHP = (nHDMult * nHDSides);
			nCHP = nCHP + nAddHP;
			nAHP = nAHP + nConBonus;
			nHP = nCHP + nAHP;

			local sFormat = Interface.getString("char_message_classhpaddmax");
			local sMsg = string.format(sFormat, DB.getValue(nodeClass, "name", ""), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. "+" .. nConBonus .. ")";
			ChatManager.SystemMessage(sMsg);
		else
			local nAddHP = math.floor(((nHDMult * (nHDSides + 1)) / 2) + 0.5);
			nCHP = nCHP + nAddHP;
			nAHP = nAHP + nConBonus;
			nHP = nCHP + nAHP;

			local sFormat = Interface.getString("char_message_classhpaddavg");
			local sMsg = string.format(sFormat, DB.getValue(nodeClass, "name", ""), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. "+" .. nConBonus .. ")";
			ChatManager.SystemMessage(sMsg);
		end
		DB.setValue(nodeChar, "hp.class", "number", nCHP);
		DB.setValue(nodeChar, "hp.ability", "number", nAHP);
		DB.setValue(nodeChar, "hp.total", "number", nHP);
	end
	
	-- BAB
	if StringManager.contains({ CLASS_BAB_FAST, CLASS_BAB_MEDIUM, CLASS_BAB_SLOW }, sBAB) then
		local nAddBAB = 0;
		if sBAB == CLASS_BAB_FAST then
			nAddBAB = 1;
		elseif sBAB == CLASS_BAB_MEDIUM then
			if nLevel % 4 ~= 1 then
				nAddBAB = 1;
			end
		elseif sBAB == CLASS_BAB_SLOW then
			if nLevel % 2 == 0 then
				nAddBAB = 1;
			end
		end
		
		if nAddBAB > 0 then
			DB.setValue(nodeChar, "attackbonus.base", "number", DB.getValue(nodeChar, "attackbonus.base", 0) + nAddBAB);
			local sFormat = Interface.getString("char_message_classbabadd");
			local sMsg = string.format(sFormat, DB.getValue(nodeChar, "name", "")) .. " (+" .. nAddBAB .. ")";
		end
	end
	
	-- Saves
	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sFort) then
		local nAddSave = 0;
		if sFort == CLASS_SAVE_GOOD then
			if bPrestige then
				if nLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if nLevel == 1 then
					nAddSave = 2;
				elseif nLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sFort == CLASS_SAVE_BAD then
			if bPrestige then
				if nLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if nLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(nodeChar, "fortitude", "base", nAddSave);
		end
	end
	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sRef) then
		local nAddSave = 0;
		if sRef == CLASS_SAVE_GOOD then
			if bPrestige then
				if nLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if nLevel == 1 then
					nAddSave = 2;
				elseif nLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sRef == CLASS_SAVE_BAD then
			if bPrestige then
				if nLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if nLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(nodeChar, "reflex", "base", nAddSave);
		end
	end
	if StringManager.contains({ CLASS_SAVE_GOOD, CLASS_SAVE_BAD }, sWill) then
		local nAddSave = 0;
		if sWill == CLASS_SAVE_GOOD then
			if bPrestige then
				if nLevel % 2 == 1 then
					nAddSave = 1;
				end
			else
				if nLevel == 1 then
					nAddSave = 2;
				elseif nLevel % 2 == 0 then
					nAddSave = 1;
				end
			end
		elseif sWill == CLASS_SAVE_BAD then
			if bPrestige then
				if nLevel % 3 == 2 then
					nAddSave = 1;
				end
			else
				if nLevel % 3 == 0 then
					nAddSave = 1;
				end
			end
		end
		
		if nAddSave > 0 then
			CharManager.addSaveBonus(nodeChar, "will", "base", nAddSave);
		end
	end
	
	-- Skill Points
	if nSkillPoints > 0 then
		local nSkillAbilityScore = DB.getValue(nodeChar, "abilities.intelligence.score", 10);
		local nAbilitySkillPoints = math.floor((nSkillAbilityScore - 10) / 2);
		local nBonusSkillPoints = 0;
		if CharManager.hasTrait(nodeChar, "Skilled") then
			nBonusSkillPoints = nBonusSkillPoints + 1;
		end
		
		DB.setValue(nodeClass, "skillranks", "number", DB.getValue(nodeClass, "skillranks", 0) + nSkillPoints + nAbilitySkillPoints + nBonusSkillPoints);
		
		local sPoints = tostring(nSkillPoints) .. "+" .. tostring(nAbilitySkillPoints);
		if nBonusSkillPoints > 0 then
			sPoints = sPoints .. "+" .. nBonusSkillPoints;
		end
		local sFormat = Interface.getString("char_message_classskillranksadd");
		local sMsg = string.format(sFormat, DB.getValue(nodeClass, "name", ""), DB.getValue(nodeChar, "name", "")) .. " (" .. sPoints .. ")";
		ChatManager.SystemMessage(sMsg);
	end
	
	-- Class Skills
	if nLevel == 1 and sClassSkills ~= "" then
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
				if addClassSkill(nodeChar, sSkill, vSkill:match("%(([^)]+)%)")) then
					table.insert(aClassSkillsAdded, vSkill);
				end
			end
		end
		
		if #aClassSkillsAdded > 0 then
			local sFormat = Interface.getString("char_message_classskillsadd");
			local sMsg = string.format(sFormat, DB.getValue(nodeChar, "name", "")) .. " (" .. table.concat(aClassSkillsAdded, ", ") .. ")";
			ChatManager.SystemMessage(sMsg);
		end
	end
	
	return aClassStats;
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
				handleClassFeatureDomains(nodeChar, nodeSource);
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

function handleClassFeatureDomains(nodeChar, nodeFeature)
	local nodeSpellClassList = nodeChar.createChild("spellset");
	local nodeNewSpellClass = nodeSpellClassList.createChild();
	DB.setValue(nodeNewSpellClass, "label", "string", CLASS_FEATURE_DOMAIN_SPELLS);
	DB.setValue(nodeNewSpellClass, "dc.ability", "string", "wisdom");
	return true;
end

function handleClassFeatureSpells(nodeChar, nodeClass, sAbility, sType)
	local sClassName = DB.getValue(nodeClass, "name", "");
	local nodeSpellClassList = nodeChar.createChild("spellset");
	local nCount = nodeSpellClassList.getChildCount();

	if nCount == 0 then
		local nodeNewSpellClass = nodeSpellClassList.createChild();
		DB.setValue(nodeNewSpellClass, "label", "string", sClassName, "");
		DB.setValue(nodeNewSpellClass, "dc.ability", "string", sAbility);
		DB.setValue(nodeNewSpellClass, "type", "string", sType);
	else
		for _,v in pairs(nodeSpellClassList.getChildren()) do
			local sExistingClassName = DB.getValue(v, "label", "");
			if sClassName ~= sExistingClassName then
				local nodeNewSpellClass = nodeSpellClassList.createChild();
				DB.setValue(nodeNewSpellClass, "label", "string", sClassName, "");
				DB.setValue(nodeNewSpellClass, "dc.ability", "string", sAbility);
				DB.setValue(nodeNewSpellClass, "type", "string", sType);
			end
		end
	end
	return true;
end

function addClassSpellLevel(nodeChar, sClassName)
	for _,v in pairs(DB.getChildren(nodeChar, "spellset")) do
		if DB.getValue(v, "label", "") == sClassName then
			addClassSpellLevelHelper(v);
		end
	end
end

function addClassSpellLevelHelper(nodeSpellClass)
	local nCL = DB.getValue(nodeSpellClass, "cl", 0) + 1;
	local nClassLevel = DB.getValue(nodeSpellClass, "classlevel", 0) + 1;
	local sType = DB.getValue(nodeSpellClass, "type", "");
	local tClassSpellLvl = {
		["Partial"] = {0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4},
		["Semi"] = {1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,6,6},
		["Full"] = {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9,9}
	}
	-- Increment caster level
	DB.setValue(nodeSpellClass, "cl", "number", nCL);
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
	checkFavoredClassBonus(rFavoredClassSelect.nodeChar, rFavoredClassSelect.sCurrentClass);
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
		wSelect.requestSelection(sTitle, sMessage, aOptions, CharManager.onFavoredClassBonusSelect, rFavoredClassBonusSelect, 1);
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
		local nodeClass = getClassNode(rFavoredClassBonusSelect.nodeChar, rFavoredClassBonusSelect.sCurrentClass);
		if nodeClass then
			DB.setValue(nodeClass, "skillranks", "number", DB.getValue(nodeClass, "skillranks", 0) + 1);
		end
		
		local sMsg = string.format(Interface.getString("char_message_favoredclassskilladd"), DB.getValue(rFavoredClassBonusSelect.nodeChar, "name", ""));
		ChatManager.SystemMessage(sMsg);
	end
	DB.setValue(rFavoredClassBonusSelect.nodeChar, "hp.total", "number", DB.getValue(rFavoredClassBonusSelect.nodeChar, "hp.favored", 0) + DB.getValue(rFavoredClassBonusSelect.nodeChar, "hp.total", 0));
end
