-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("skill", modSkill);
	ActionsManager.registerResultHandler("skill", onRoll);
end

function performPartySheetRoll(draginfo, rActor, sSkillName, nSkillMod)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod);
					
	local nTargetDC = DB.getValue("partysheet.skilldc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performPCRoll(draginfo, rActor, nodeSkill)
	local sSkillName = DB.getValue(nodeSkill, "label", "");
	local sSubskillName = DB.getValue(nodeSkill, "sublabel", "");
	if sSubskillName ~= "" then
		sSkillName = sSkillName .. " (" .. sSubskillName .. ")";
	end

	local nSkillMod = DB.getValue(nodeSkill, "total", 0);
	local sSkillStat = DB.getValue(nodeSkill, "statname", "");
	
	performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat);
end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, sExtra)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod, sSkillStat, sExtra);
	
	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sSkillName, nSkillMod, sSkillStat, sExtra)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = { "d20" };
	rRoll.nMod = nSkillMod or 0;
	rRoll.sDesc = "[SKILL] " .. sSkillName;
	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end
	
	local sAbilityEffect = DataCommon.ability_ltos[sSkillStat];
	if sAbilityEffect then
		rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
	end
	
	if ActorManager.isPC(rActor) then
		local sSkillLookup;
		local sSubSkill = nil;
		if sSkillName:match("^Knowledge") then
			sSubSkill = sSkillName:sub(12, -2);
			sSkillLookup = "Knowledge";
		else
			sSkillLookup = sSkillName;
		end
		_,bUntrained = CharManager.getSkillValue(rActor, sSkillLookup, sSubSkill);
		if bUntrained then
			rRoll.sDesc = rRoll.sDesc .. " [UNTRAINED]";
		end
	end
	
	return rRoll;
end

function modSkill(rSource, rTarget, rRoll)
	local bAssist = Input.isShiftPressed();
	if bAssist then
		rRoll.sDesc = rRoll.sDesc .. " [ASSIST]";
	end

	local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	if rSource then
		local bEffects = false;

		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)");
		if sSkill then
			sSkillLower = string.lower(StringManager.trim(sSkill));
		end

		-- Determine ability used with this skill
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		else
			for k, v in pairs(DataCommon.skilldata) do
				if string.lower(k) == sSkillLower then
					sActionStat = v.stat;
				end
			end
		end

		-- Build effect filter for this skill
		local aSkillFilter = {};
		if sActionStat then
			table.insert(aSkillFilter, sActionStat);
		end
		local aSkillNameFilter = {};
		local aSkillWordsLower = StringManager.parseWords(sSkillLower);
		if #aSkillWordsLower > 0 then
			if #aSkillWordsLower == 1 then
				table.insert(aSkillFilter, aSkillWordsLower[1]);
			else
				table.insert(aSkillFilter, table.concat(aSkillWordsLower, " "));
				if aSkillWordsLower[1] == "knowledge" or aSkillWordsLower[1] == "perform" or aSkillWordsLower[1] == "craft" then
					table.insert(aSkillFilter, aSkillWordsLower[1]);
				end
			end
		end
		
		-- Get effects
		local aAddDice, nAddMod, nEffectCount = EffectManagerFFd20.getEffectsBonus(rSource, {"SKILL"}, false, aSkillFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Handle effects for fly
		for _,name in pairs(aSkillWordsLower) do
			if name == "fly" then
				local rActor = ActorManager.getCreatureNode(rSource)
				local nCreatureSize = ActorCommonManager.getCreatureSizeDnD3(rActor);
				if nCreatureSize ~= 0 then
					nAddMod = nAddMod + (nCreatureSize*-2);
					bEffects = true;
				end
				local aSpecialSpeed = StringManager.parseWords(DB.getValue(rActor, "speed.special", ""));
				for k,v in pairs(aSpecialSpeed) do
					if v:lower() == "fly" then
						local sManeuverability = aSpecialSpeed[k+2]:lower();
						if sManeuverability == "clumsy" then
							nAddMod = nAddMod - 8;
							bEffects = true;
						elseif sManeuverability == "poor" then
							nAddMod = nAddMod - 4;
							bEffects = true;
						elseif sManeuverability == "good" then
							nAddMod = nAddMod + 4;
							bEffects = true;
						elseif sManeuverability == "perfect" then
							nAddMod = nAddMod + 8;
							bEffects = true;
						end
					end
				end
			end
		end
		
		-- Get condition modifiers
		if EffectManagerFFd20.hasEffectCondition(rSource, "ADVSKILL") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManagerFFd20.getEffectsByType(rSource, "ADVSKILL", aSkillFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "DISSKILL") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManagerFFd20.getEffectsByType(rSource, "DISSKILL", aSkillFilter)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Frightened") or 
				EffectManagerFFd20.hasEffectCondition(rSource, "Panicked") or
				EffectManagerFFd20.hasEffectCondition(rSource, "Shaken") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Sickened") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Blinded") then
			if sActionStat == "strength" or sActionStat == "dexterity" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			elseif sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		elseif EffectManagerFFd20.hasEffectCondition(rSource, "Dazzled") then
			if sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 1;
			end
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Fascinated") then
			if sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		end
		-- Exhausted and Fatigued are handled by the effect checks for general ability modifiers

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManagerFFd20.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManagerFFd20.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			bEffects = true;
			nAddMod = nAddMod - nNegLevelMod;
		end

		-- If effects, then add them
		if bEffects then
			for _,vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;

			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
		ActionAdvantage.encodeAdvantage(rRoll, bADV, bDIS);
	end
end

function onRoll(rSource, rTarget, rRoll)
	ActionAdvantage.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);
end
