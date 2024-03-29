-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncDnD);

	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);
	CombatManager.setCustomCombatReset(resetInit);

	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", ActorCommonManager.getSpaceReachDnD3Legacy);
	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
end

--
-- TURN FUNCTIONS
--

function onRoundStart(nCurrent)
	if OptionsManager.isOption("HRIR", "on") then
		rollInit();
	end
end

function onTurnEnd(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "immediate", "number", 0);
	
	-- Check for stabilization (based on option)
	local sOptionHRST = OptionsManager.getOption("HRST");
	if sOptionHRST ~= "off" then
		if (sOptionHRST == "all") or (DB.getValue(nodeEntry, "friendfoe", "") == "friend") then
			local rActor = ActorManager.resolveActor(nodeEntry);
			local sStatus = ActorHealthManager.getHealthStatus(rActor);
			if sStatus == ActorHealthManager.STATUS_DYING then
				if not EffectManager.hasCondition(rActor, "Stable") then
					ActionDamage.performStabilizationRoll(rActor);
				end
			end
		end
	end
end

--
-- ADD FUNCTIONS
--

function onNPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Setup
	local nodeNPC = tCustom.nodeRecord;

	-- HP
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sOptHRNH == "max" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true, true);
	elseif sOptHRNH == "random" and sHD ~= "" then
		nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
	end
	DB.setValue(tCustom.nodeCT, "hp", "number", nHP);

	-- Defensive properties
	local sAC = DB.getValue(nodeNPC, "ac", "10");
	DB.setValue(tCustom.nodeCT, "ac_final", "number", tonumber(string.match(sAC, "^(%d+)")) or 10);
	DB.setValue(tCustom.nodeCT, "ac_touch", "number", tonumber(string.match(sAC, "touch (%d+)")) or 10);
	local sFlatFooted = string.match(sAC, "flat[%-�]footed (%d+)");
	if not sFlatFooted then
		sFlatFooted = string.match(sAC, "flatfooted (%d+)");
	end
	DB.setValue(tCustom.nodeCT, "ac_flatfooted", "number", tonumber(sFlatFooted) or 10);
	
	-- Handle BAB / cmb / CM Field
	local sBABCMB = DB.getValue(nodeNPC, "babcmb", "");
	local aSplitBABCMB = StringManager.split(sBABCMB, "/", true);
	
	local sMatch = string.match(sBABCMB, "CMB ([+-]%d+)");
	if sMatch then
		DB.setValue(tCustom.nodeCT, "cmb", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABCMB[2] then
			DB.setValue(tCustom.nodeCT, "cmb", "number", tonumber(aSplitBABCMB[2]) or 0);
		end
	end

	sMatch = string.match(sBABCMB, "CMD ([+-]?%d+)");
	if sMatch then
		DB.setValue(tCustom.nodeCT, "cmd", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABCMB[3] then
			DB.setValue(tCustom.nodeCT, "cmd", "number", tonumber(aSplitBABCMB[3]) or 0);
		end
	end

	-- Offensive properties
	local nodeAttacks = DB.createChild(tCustom.nodeCT, "attacks");
	if nodeAttacks then
		DB.deleteChildren(nodeAttacks);
		
		local nAttacks = 0;
		
		local sAttack = DB.getValue(nodeNPC, "atk", "");
		if sAttack ~= "" then
			local nodeValue = DB.createChild(nodeAttacks);
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		local sFullAttack = DB.getValue(nodeNPC, "fullatk", "");
		if sFullAttack ~= "" then
			nodeValue = DB.createChild(nodeAttacks);
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sFullAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		if nAttacks == 0 then
			DB.createChild(nodeAttacks);
		end
	end

	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	local aAddDamageTypes = {};
	
	-- Decode monster type qualities
	local sType = string.lower(DB.getValue(nodeNPC, "type", ""));
	local sCreatureType, sSubTypes = string.match(sType, "([^(]+) %(([^)]+)%)");
	if not sCreatureType then
		sCreatureType = sType;
	end
	local aSubTypes = {};
	if sSubTypes then
		aSubTypes = StringManager.split(sSubTypes, ",", true);
	end

	if StringManager.contains(aSubTypes, "lawful") then
		table.insert(aAddDamageTypes, "lawful");
	end
	if StringManager.contains(aSubTypes, "chaotic") then
		table.insert(aAddDamageTypes, "chaotic");
	end
	if StringManager.contains(aSubTypes, "good") then
		table.insert(aAddDamageTypes, "good");
	end
	if StringManager.contains(aSubTypes, "evil") then
		table.insert(aAddDamageTypes, "evil");
	end

	-- DECODE SPECIAL QUALITIES
	local sSpecialQualities = string.lower(DB.getValue(nodeNPC, "specialqualities", ""));
	
	local aSQWords = StringManager.parseWords(sSpecialQualities);
	local i = 1;
	while aSQWords[i] do
		-- HARDNESS
		if StringManager.isWord(aSQWords[i], "hardness") and StringManager.isNumberString(aSQWords[i+1]) then
			i = i + 1;
			local sHardnessAmount = aSQWords[i];
			if (tonumber(aSQWords[i+1]) or 0) <= 20 then
				table.insert(aEffects, "DR: " .. sHardnessAmount .. " adamantine; RESIST: " .. sHardnessAmount .. " " .. table.concat(DataCommon.energytypes, "; RESIST: " .. sHardnessAmount .. " "));
			else
				table.insert(aEffects, "DR: " .. sHardnessAmount .. " all; RESIST: " .. sHardnessAmount .. " " .. table.concat(DataCommon.energytypes, "; RESIST: " .. sHardnessAmount .. " "));
			end
		
		-- FAST HEALING
		elseif StringManager.isWord(aSQWords[i], "fast") and StringManager.isWord(aSQWords[i+1], { "healing", "heal" }) then
			i = i + 1;
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				table.insert(aEffects, "FHEAL: " .. aSQWords[i]);
			end
		
		-- REGENERATION
		elseif StringManager.isWord(aSQWords[i], "regeneration") then
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				local sRegenAmount = aSQWords[i];
				local aRegenTypes = {};
				
				while aSQWords[i+1] do
					if StringManager.isWord(aSQWords[i+1], { "and", "or" }) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], "cold") and StringManager.isWord(aSQWords[i+2], "iron") then
						table.insert(aRegenTypes, "cold iron");
						i = i + 1;
					elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
				i = i - 1;
				
				local sRegenEffect = "REGEN: " .. sRegenAmount;
				if #aRegenTypes > 0 then
					sRegenEffect = sRegenEffect .. " " .. table.concat(aRegenTypes, " ");
					EffectManager.addEffect("", "", tCustom.nodeCT, { sName = sRegenEffect, nDuration = 0, nGMOnly = 1 }, false);
				else
					table.insert(aEffects, sRegenEffect);
				end
			end
			
		-- SPECIAL DEFENSES
		elseif StringManager.isWord(aSQWords[i], "uncanny") and StringManager.isWord(aSQWords[i+1], "dodge") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Uncanny Dodge");
			else
				table.insert(aEffects, "Uncanny Dodge");
			end
			i = i + 1;
		
		elseif StringManager.isWord(aSQWords[i], "evasion") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Evasion");
			else
				table.insert(aEffects, "Evasion");
			end
		
		-- TRAITS
		elseif StringManager.isWord(aSQWords[i], "incorporeal") then
			table.insert(aEffects, "Incorporeal");
		elseif StringManager.isWord(aSQWords[i], "blur") then
			table.insert(aEffects, "CONC");
		elseif StringManager.isWord(aSQWords[i], "natural") and StringManager.isWord(aSQWords[i+1], "invisibility") then
			table.insert(aEffects, "Invisible");
		end
	
		-- ITERATE SPECIAL QUALITIES DECODE
		i = i + 1;
	end

	-- DECODE ABSORB
	local sAbsorb = string.lower(DB.getValue(nodeNPC, "absorb", ""));
	local aAbsorbWords = StringManager.parseWords(sAbsorb);
	local j = 1;
	while aAbsorbWords[j] do
		if StringManager.isWord(aAbsorbWords[j], DataCommon.energytypes) then
			table.insert(aEffects, "ABSORB: " .. aAbsorbWords[j]);
		else
			break;
		end

		j = j + 1;
	end

	-- DECODE DR
	local sDR = string.lower(DB.getValue(nodeNPC, "dr", ""));
	local aDRWords = StringManager.parseWords(sDR);
	local k = 1;
	while aDRWords[k] do
		if StringManager.isNumberString(aDRWords[k]) then
			local sDRAmount = aDRWords[k];
			local aDRTypes = {};

 			while aDRWords[k+1] do
				if StringManager.isWord(aDRWords[k+1], { "and", "or" }) then
					table.insert(aDRTypes, aDRWords[k+1]);
				elseif StringManager.isWord(aDRWords[k+1], { "epic", "magic" }) then
					table.insert(aDRTypes, aDRWords[k+1]);
					table.insert(aAddDamageTypes, aDRWords[k+1]);
				elseif StringManager.isWord(aDRWords[k+1], "cold") and StringManager.isWord(aDRWords[k+2], "iron") then
					table.insert(aDRTypes, "cold iron");
					k = k + 1;
				elseif StringManager.isWord(aDRWords[k+1], DataCommon.dmgtypes) then
					table.insert(aDRTypes, aDRWords[k+1]);
				else
					break;
				end

				k = k + 1;
			end
			
			local sDREffect = "DR: " .. sDRAmount;
			if #aDRTypes > 0 then
				sDREffect = sDREffect .. " " .. table.concat(aDRTypes, " ");
			end
			table.insert(aEffects, sDREffect);
			k = k + 1;
		else
			k = k + 1;
		end
	end

	-- DECODE IMMUNE
	local sImmune = string.lower(DB.getValue(nodeNPC, "immune", ""));
	local aImmuneWords = StringManager.splitByPattern(sImmune, ",");
	local l = 1;
	while aImmuneWords[l] do
		if StringManager.isWord(aImmuneWords[l], "magic") then
			table.insert(aEffects, "IMMUNE: spell");
		elseif StringManager.isWord(aImmuneWords[l], DataCommon.immunetypes) then
			table.insert(aEffects, "IMMUNE: " .. aImmuneWords[l]);
		elseif StringManager.isWord(aImmuneWords[l], DataCommon.dmgtypes) and not StringManager.isWord(aImmuneWords[l], DataCommon.specialdmgtypes) then
			table.insert(aEffects, "IMMUNE: " .. aImmuneWords[l]);		
		else
			table.insert(aEffects, "IMMUNE: " .. aImmuneWords[l]);
		end

		l = l + 1;
	end

	-- DECODE RESISTANCE
	local sResistance = string.lower(DB.getValue(nodeNPC, "resistance", ""));
	local aResistanceWords = StringManager.parseWords(sResistance);
	local m = 1;
	while aResistanceWords[m] do
		if StringManager.isWord(aResistanceWords[m], DataCommon.energytypes) and StringManager.isNumberString(aResistanceWords[m+1]) then
			table.insert(aEffects, "RESIST: " .. aResistanceWords[m+1] .. " " .. aResistanceWords[m]);
			m = m + 1;
		else
			break;
		end

		m = m + 1;
	end

	-- DECODE WEAKNESS
	local sWeakness = string.lower(DB.getValue(nodeNPC, "weakness", ""));
	local aWeaknessWords = StringManager.parseWords(sWeakness);
	local n = 1;
	while aWeaknessWords[n] do
		if StringManager.isWord(aWeaknessWords[n], DataCommon.energytypes) then
			table.insert(aEffects, "WEAK: " .. aWeaknessWords[n]);
		else
			break;
		end

		n = n + 1;
	end

	-- DECODE STRONG
	local sStrong = string.lower(DB.getValue(nodeNPC, "strong", ""));
	local aStrongWords = StringManager.parseWords(sStrong);
	local o = 1;
	while aStrongWords[o] do
		if StringManager.isWord(aStrongWords[o], DataCommon.energytypes) then
			table.insert(aEffects, "STRONG: " .. aStrongWords[o]);
		else
			break;
		end

		o = o + 1;
	end

	-- DECODE SR
	local nSR = DB.getValue(nodeNPC, "sr", 0);
	if nSR > 0 then
		local sSR = tostring(nSR);
		table.insert(aEffects, "SR: " .. sSR);
	end

	-- FINISH ADDING EXTRA DAMAGE TYPES
	if #aAddDamageTypes > 0 then
		table.insert(aEffects, "DMGTYPE: " .. table.concat(aAddDamageTypes, ","));
	end

	-- VEHICLE
	local sNPCType = DB.getValue(nodeNPC, "npctype", "");
	if sNPCType == "Vehicle" then
		local nAC = DB.getValue(nodeNPC, "vac", 0);
		local nHardness = DB.getValue(nodeNPC, "hardness", 0);

		DB.setValue(tCustom.nodeCT, "ac_final", "number", nAC);
		if nHardness > 0 then
			local sHardness = tostring(nHardness);
			table.insert(aEffects, "HARDNESS: " .. sHardness);
		end
	end
	
	-- ADD DECODED EFFECTS
	if #aEffects > 0 then
		EffectManager.addEffect("", "", tCustom.nodeCT, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	CombatRecordManager.handleCombatAddInitDnD(tCustom);
end

--
-- RESET FUNCTIONS
--

function resetInit()
	function resetCombatantInit(nodeCT)
		DB.setValue(nodeCT, "initresult", "number", 0);
		DB.setValue(nodeCT, "immediate", "number", 0);
	end
	CombatManager.callForEachCombatant(resetCombatantInit);
end

function clearExpiringEffects(bShort)
	function checkEffectExpire(nodeEffect, bShort)
		local sLabel = DB.getValue(nodeEffect, "label", "");
		local nDuration = DB.getValue(nodeEffect, "duration", 0);
		local sApply = DB.getValue(nodeEffect, "apply", "");
		
		if nDuration ~= 0 or sApply ~= "" or sLabel == "" then
			if bShort and (nDuration > 50) then
				DB.setValue(nodeEffect, "duration", "number", nDuration - 50);
			else
				DB.deleteNode(nodeEffect);
			end
		end
	end
	CombatManager.callForEachCombatantEffect(checkEffectExpire, bShort);
end

function rest(bShort)
	CombatManager.resetInit();
	clearExpiringEffects(bShort);
	
	if not bShort then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, sRecord = DB.getValue(v, "link", "", "");
			if sClass == "charsheet" and sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					CharManager.rest(nodePC);
				end
			end
		end
	end
end

function rollInit(sType)
	CombatManager.rollTypeInit(sType, CombatManager2.rollEntryInit);
end
function rollEntryInit(nodeEntry)
	CombatManager.rollStandardEntryInit(CombatManager2.getEntryInitRecord(nodeEntry));
end
function getEntryInitRecord(nodeEntry)
	if not nodeEntry then
		return nil;
	end

	local tInit = { nodeEntry = nodeEntry };

	-- Start with the base initiative bonus
	tInit.nMod = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);
	local bEffects, aEffectDice, nEffectMod = ActionInit.getEffectAdjustments(rActor);
	if bEffects then
		tInit.nMod = tInit.nMod + StringManager.evalDice(aEffectDice, nEffectMod);
	end
	return tInit;
end

--
-- PARSE CT ATTACK LINE
--

function parseAttackLine(rActor, sLine)
	-- SETUP
	local rAttackRolls = {};
	local rDamageRolls = {};
	local rAttackCombos = {};

	-- Check the anonymous NPC attacks option
	local sOptANPC = OptionsManager.getOption("ANPC");

	-- PARSE 'OR'/'AND' PHRASES
	sLine = sLine:gsub("�", "-");
	local aPhrasesOR, aSkipOR = ActionDamage.decodeAndOrClauses(sLine);

	-- PARSE EACH ATTACK
	local nAttackIndex = 1;
	local nLineIndex = 1;
	local aCurrentCombo = {};
	local nStarts, nEnds, sAll, sAttackCount, sAttackLabel, sAttackModifier, sAttackType, nDamageStart, sDamage, nDamageEnd;
	for kOR, vOR in ipairs(aPhrasesOR) do
			
		for kAND, sAND in ipairs(vOR) do

			-- Look for the right patterns
			nStarts, nEnds, sAll, sAttackCount, sAttackLabel, sAttackModifier, sAttackType, nDamageStart, sDamage, nDamageEnd 
					= string.find(sAND, '((%+?%d*) ?([%w%s,%[%]%(%)%+%-]*) ([%+%-%d][%+%-%d/]+)([^%(]*)%(()([^%)]*)()%))');
			if not nStarts then
				nStarts, nEnds, sAll, sAttackLabel, nDamageStart, sDamage, nDamageEnd 
						= sAND:find('(([%w%s,%[%]%(%)%+%-]*)%(()([^%)]*)()%))');
				if nStarts then
					sAttackCount = "";
					sAttackModifier = "+0";
					sAttackType = "";
				end
			end
			
			-- Make sure we got a match
			if nStarts then
				local rAttack = {};
				rAttack.startpos = nLineIndex + nStarts - 1;
				rAttack.endpos = nLineIndex + nEnds;
				
				local rDamage = {};
				rDamage.startpos = nLineIndex + nDamageStart - 2;
				rDamage.endpos = nLineIndex + nDamageEnd;
				
				-- Check for implicit damage types
				local aImplicitDamageType = {};
				local aLabelWords = StringManager.parseWords(sAttackLabel:lower());
				local i = 1;
				while aLabelWords[i] do
					if aLabelWords[i] == "touch" then
						rAttack.touch = true;
					elseif aLabelWords[i] == "sonic" or aLabelWords[i] == "electricity" then
						table.insert(aImplicitDamageType, aLabelWords[i]);
						break;
					elseif aLabelWords[i] == "adamantine" or aLabelWords[i] == "silver" then
						table.insert(aImplicitDamageType, aLabelWords[i]);
					elseif aLabelWords[i] == "cold" and aLabelWords[i+1] and aLabelWords[i+1] == "iron" then
						table.insert(aImplicitDamageType, "cold iron");
						i = i + 1;
					elseif aLabelWords[i] == "holy" then
						table.insert(aImplicitDamageType, "good");
					elseif aLabelWords[i] == "unholy" then
						table.insert(aImplicitDamageType, "evil");
					elseif aLabelWords[i] == "anarchic" then
						table.insert(aImplicitDamageType, "chaotic");
					elseif aLabelWords[i] == "axiomatic" then
						table.insert(aImplicitDamageType, "lawful");
					else
						if aLabelWords[i]:sub(-1) == "s" then
							aLabelWords[i] = aLabelWords[i]:sub(1, -2);
						end
						if DataCommon.naturaldmgtypes[aLabelWords[i]] then
							table.insert(aImplicitDamageType, DataCommon.naturaldmgtypes[aLabelWords[i]]);
						elseif DataCommon.weapondmgtypes[aLabelWords[i]] then
							if type(DataCommon.weapondmgtypes[aLabelWords[i]]) == "table" then
								if aLabelWords[i-1] and DataCommon.weapondmgtypes[aLabelWords[i]][aLabelWords[i-1]] then
									table.insert(aImplicitDamageType, DataCommon.weapondmgtypes[aLabelWords[i]][aLabelWords[i-1]]);
								elseif DataCommon.weapondmgtypes[aLabelWords[i]]["*"] then
									table.insert(aImplicitDamageType, DataCommon.weapondmgtypes[aLabelWords[i]]["*"]);
								end
							else
								table.insert(aImplicitDamageType, DataCommon.weapondmgtypes[aLabelWords[i]]);
							end
						end
					end
					
					i = i + 1;
				end
				
				-- Clean up the attack count field (i.e. magical weapon bonuses up front, no attack count)
				local bMagicAttack = false;
				local bEpicAttack = false;
				local nAttackCount = 1;
				if string.sub(sAttackCount, 1, 1) == "+" then
					bMagicAttack = true;
					if sOptANPC ~= "on" then
						sAttackLabel = sAttackCount .. " " .. sAttackLabel;
					end
					local nAttackPlus = tonumber(sAttackCount) or 1;
					if nAttackPlus > 5 then
						bEpicAttack = true;
					end
				elseif #sAttackCount then
					nAttackCount = tonumber(sAttackCount) or 1;
					if nAttackCount < 1 then
						nAttackCount = 1;
					end
				end

				-- Capitalize first letter of label
				sAttackLabel = StringManager.capitalize(sAttackLabel);
				
				-- If the anonymize option is on, then remove any label text within parentheses or brackets
				if sOptANPC == "on" then
					-- Strip out label information enclosed in ()
					sAttackLabel = string.gsub(sAttackLabel, "%s?%b()", "");

					-- Strip out label information enclosed in []
					sAttackLabel = string.gsub(sAttackLabel, "%s?%b[]", "");
				end

				rAttack.label = sAttackLabel;
				rAttack.count = nAttackCount;
				rAttack.modifier = sAttackModifier or 0;
				
				rDamage.label = sAttackLabel;
				
				local bRanged = false;
				local aTypeWords = StringManager.parseWords(string.lower(sAttackType));
				for kWord, vWord in pairs(aTypeWords) do
					if vWord == "ranged" then
						bRanged = true;
					elseif vWord == "touch" then
						rAttack.touch = true;
					end
				end
				
				-- Determine attack type
				if bRanged then
					rAttack.range = "R";
					rDamage.range = "R";
					rAttack.stat = "dexterity";
				else
					rAttack.range = "M";
					rDamage.range = "M";
					rAttack.stat = "strength";
				end

				-- Determine critical information
				rAttack.crit = 20;
				nCritStart, nCritEnd, sCritThreshold = string.find(sDamage, "/(%d+)%-20");
				if sCritThreshold then
					rAttack.crit = tonumber(sCritThreshold) or 20;
					if rAttack.crit < 2 or rAttack.crit > 20 then
						rAttack.crit = 20;
					end
				end
				
				-- Determine damage clauses
				rDamage.clauses = {};

				local aClausesDamage = {};
				local nIndexDamage = 1;
				local nStartDamage, nEndDamage;
				while nIndexDamage < #sDamage do
					nStartDamage, nEndDamage = string.find(sDamage, ' plus ', nIndexDamage);
					if nStartDamage then
						table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage, nStartDamage - 1));
						nIndexDamage = nEndDamage;
					else
						table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage));
						nIndexDamage = #sDamage;
					end
				end

				for kClause, sClause in pairs(aClausesDamage) do
					local aDamageAttrib = StringManager.split(sClause, "/", true);
					
					local aWordType = {};
					local sDamageRoll, sDamageTypes = string.match(aDamageAttrib[1], "^([d%d%+%-%s]+)([%w%s,]*)");
					if sDamageRoll then
						if sDamageTypes then
							if string.match(sDamageTypes, " and ") then
								sDamageTypes = string.gsub(sDamageTypes, " and .*$", "");
							end
							table.insert(aWordType, sDamageTypes);
						end
						
						local sCrit;
						for nAttrib = 2, #aDamageAttrib do
							sCrit, sDamageTypes = string.match(aDamageAttrib[nAttrib], "^x(%d)([%w%s,]*)");
							if not sCrit then
								sDamageTypes = string.match(aDamageAttrib[nAttrib], "^%d+%-20%s?([%w%s,]*)");
							end
							
							if sDamageTypes then
								table.insert(aWordType, sDamageTypes);
							end
						end
						
						local aWordDice, nWordMod = StringManager.convertStringToDice(sDamageRoll);
						if #aWordDice > 0 or nWordMod ~= 0 then
							local rDamageClause = { dice = {} };
							for kDie, vDie in ipairs(aWordDice) do
								table.insert(rDamageClause.dice, vDie);
							end
							rDamageClause.modifier = nWordMod;

							if kClause == 1 then
								rDamageClause.mult = 2;
							else
								rDamageClause.mult = 1;
							end
							rDamageClause.mult = tonumber(sCrit) or rDamageClause.mult;
							
							if not bRanged then
								rDamageClause.stat = "strength";
							end

							local aDamageType = ActionDamage.getDamageTypesFromString(table.concat(aWordType, ","));
							if #aDamageType == 0 then
								for kType, sType in ipairs(aImplicitDamageType) do
									table.insert(aDamageType, sType);
								end
							end
							if bMagicAttack then
								table.insert(aDamageType, "magic");
							end
							if bEpicAttack then
								table.insert(aDamageType, "epic");
							end
							rDamageClause.dmgtype = table.concat(aDamageType, ",");
							
							table.insert(rDamage.clauses, rDamageClause);
						end
					end
				end
				
				if #(rDamage.clauses) > 0 then
					if bRanged then
						local nDmgBonus = rDamage.clauses[1].modifier;
						if nDmgBonus > 0 then
							local nStatBonus = ActorManagerFFd20.getAbilityBonus(rActor, "strength");
							if (nDmgBonus >= nStatBonus) then
								rDamage.statmult = 1;
							end
						end
					else
						local nDmgBonus = rDamage.clauses[1].modifier;
						local nStatBonus = ActorManagerFFd20.getAbilityBonus(rActor, "strength");
						
						if (nStatBonus > 0) and (nDmgBonus > 0) then
							if nDmgBonus >= math.floor(nStatBonus * 1.5) then
								rDamage.statmult = 1.5;
							elseif nDmgBonus >= nStatBonus then
								rDamage.statmult = 1;
							else
								rDamage.statmult = 0.5;
							end
						elseif (nStatBonus == 1) and (nDmgBonus == 0) then
							rDamage.statmult = 0.5;
						end
					end
				end

				-- Add to roll list
				table.insert(rAttackRolls, rAttack);
				table.insert(rDamageRolls, rDamage);

				-- Add to combo
				table.insert(aCurrentCombo, nAttackIndex);
				nAttackIndex = nAttackIndex + 1;
			end

			nLineIndex = nLineIndex + #sAND;
			nLineIndex = nLineIndex + aSkipOR[kOR][kAND];
		end

		-- Finish combination
		if #aCurrentCombo > 0 then
			table.insert(rAttackCombos, aCurrentCombo);
			aCurrentCombo = {};
		end
	end
	
	return rAttackRolls, rDamageRolls, rAttackCombos;
end

--
--	XP FUNCTIONS
--

function getCRFromXP(nXP)
	local nCR = 0;
	if nXP > 0 then
		if nXP <= 50 then
			nCR = 0.125;
		elseif nXP <= 65 then
			nCR = 0.166;
		elseif nXP <= 100 then
			nCR = 0.25;
		elseif nXP <= 135 then
			nCR = 0.333;
		elseif nXP <= 200 then
			nCR = 0.5;
		elseif nXP <= 400 then
			nCR = 1;
		elseif nXP <= 600 then
			nCR = 2;
		elseif nXP <= 800 then
			nCR = 3;
		elseif nXP <= 1200 then
			nCR = 4;
		elseif nXP <= 1600 then
			nCR = 5;
		elseif nXP <= 2400 then
			nCR = 6;
		elseif nXP <= 3200 then
			nCR = 7;
		elseif nXP <= 4800 then
			nCR = 8;
		elseif nXP <= 6400 then
			nCR = 9;
		elseif nXP <= 9600 then
			nCR = 10;
		elseif nXP <= 12800 then
			nCR = 11;
		elseif nXP <= 19200 then
			nCR = 12;
		elseif nXP <= 25600 then
			nCR = 13;
		elseif nXP <= 38400 then
			nCR = 14;
		elseif nXP <= 51200 then
			nCR = 15;
		elseif nXP <= 76800 then
			nCR = 16;
		elseif nXP <= 102400 then
			nCR = 17;
		elseif nXP <= 153600 then
			nCR = 18;
		elseif nXP <= 204800 then
			nCR = 19;
		elseif nXP <= 307200 then
			nCR = 20;
		elseif nXP <= 409600 then
			nCR = 21;
		elseif nXP <= 614400 then
			nCR = 22;
		elseif nXP <= 819200 then
			nCR = 23;
		elseif nXP <= 1228800 then
			nCR = 24;
		elseif nXP <= 1638400 then
			nCR = 25;
		elseif nXP <= 2457600 then
			nCR = 26;
		elseif nXP <= 3276800 then
			nCR = 27;
		elseif nXP <= 4915200 then
			nCR = 28;
		elseif nXP <= 6553600 then
			nCR = 29;
		elseif nXP <= 9830400 then
			nCR = 30;
		else
			nCR = 35;
		end
	end
	return nCR;
end

function getXPFromCR(nCR)
	local nXP = 0;
	if nCR > 0 then
		if nCR <= 0.125 then
			nXP = 50;
		elseif nCR <= 0.167 then
			nXP = 65;
		elseif nCR <= 0.25 then
			nXP = 100;
		elseif nCR <= 0.334 then
			nXP = 135;
		elseif nCR <= 0.5 then
			nXP = 200;
		elseif nCR <= 1 then
			nXP = 400;
		elseif nCR <= 2 then
			nXP = 600;
		elseif nCR <= 3 then
			nXP = 800;
		elseif nCR <= 4 then
			nXP = 1200;
		elseif nCR <= 5 then
			nXP = 1600;
		elseif nCR <= 6 then
			nXP = 2400;
		elseif nCR <= 7 then
			nXP = 3200;
		elseif nCR <= 8 then
			nXP = 4800;
		elseif nCR <= 9 then
			nXP = 6400;
		elseif nCR <= 10 then
			nXP = 9600;
		elseif nCR <= 11 then
			nXP = 12800;
		elseif nCR <= 12 then
			nXP = 19200;
		elseif nCR <= 13 then
			nXP = 25600;
		elseif nCR <= 14 then
			nXP = 38400;
		elseif nCR <= 15 then
			nXP = 51200;
		elseif nCR <= 16 then
			nXP = 76800;
		elseif nCR <= 17 then
			nXP = 102400;
		elseif nCR <= 18 then
			nXP = 153600;
		elseif nCR <= 19 then
			nXP = 204800;
		elseif nCR <= 20 then
			nXP = 307200;
		elseif nCR <= 21 then
			nXP = 409600;
		elseif nCR <= 22 then
			nXP = 614400;
		elseif nCR <= 23 then
			nXP = 819200;
		elseif nCR <= 24 then
			nXP = 1228800;
		elseif nCR <= 25 then
			nXP = 1638400;
		elseif nCR <= 26 then
			nXP = 2457600;
		elseif nCR <= 27 then
			nXP = 3276800;
		elseif nCR <= 28 then
			nXP = 4915200;
		elseif nCR <= 29 then
			nXP = 6553600;
		elseif nCR <= 30 then
			nXP = 9830400;
		else
			nXP = 52480000;
		end
	end
	return nXP;
end

function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	local nXP = 0;
	for _, vNPCItem in ipairs(DB.getChildList(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				local nXPNPC = getXPFromCR(DB.getValue(nodeNPC, "cr", 0));
				if nXPNPC >= 0 then
					nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * nXPNPC);
				else
					local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpcxp"), DB.getValue(vNPCItem, "name", ""));
					ChatManager.SystemMessage(sMsg);
				end
			else
				local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end
	end
		
	DB.setValue(nodeBattle, "exp", "number", nXP);
end
	
function calcBattleCR(nodeBattle)
	calcBattleXP(nodeBattle);

	local nXP = DB.getValue(nodeBattle, "exp", 0);
	local nCR = getCRFromXP(nXP);
	DB.setValue(nodeBattle, "level", "number", nCR);
end

--
--	COMBAT ACTION FUNCTIONS
--

function addRightClickDiceToClauses(rRoll)
	if #rRoll.clauses > 0 then
		local nOrigDamageDice = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nOrigDamageDice = nOrigDamageDice + #vClause.dice;
		end
		if #rRoll.aDice > nOrigDamageDice then
			local v = rRoll.clauses[#rRoll.clauses].dice;
			for i = nOrigDamageDice + 1,#rRoll.aDice do
				if type(rRoll.aDice[i]) == "table" then
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i].type);
				else
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i]);
				end
			end
		end
	end
end
