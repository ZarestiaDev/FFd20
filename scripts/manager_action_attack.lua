-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerTargetingHandler("attack", onTargeting);

	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerModHandler("grapple", modAttack);
	
	ActionsManager.registerResultHandler("attack", onAttack);
	ActionsManager.registerResultHandler("critconfirm", onAttack);
	ActionsManager.registerResultHandler("misschance", onMissChance);
	ActionsManager.registerResultHandler("grapple", onGrapple);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	ActionAttack.applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function notifyApplyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYATK;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sAttackType = sAttackType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
	if OptionsManager.isOption("RMMT", "multi") then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		if #aTargets > 1 then
			for _,vRoll in ipairs(rRolls) do
				if not string.match(vRoll.sDesc, "%[FULL%]") then
					vRoll.bRemoveOnMiss = "true";
				end
			end
		end
	end
	return aTargeting;
end

function performPartySheetVsRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
	
	ActionsManager.actionDirect(nil, "attack", { rRoll }, { { rActor } });
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction, tag)
	local rRoll = {};
	if rAction.cm then
		rRoll.sType = "grapple";
	else
		rRoll.sType = "attack";
	end
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier or 0;
	
	if rAction.cm then
		rRoll.sDesc = "[CMB";
		if rAction.order and rAction.order > 1 then
			rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
		end
		rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	else
		rRoll.sDesc = "[ATTACK";
		if rAction.order and rAction.order > 1 then
			rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
		end
		if rAction.range then
			rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
		end
		rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	end
	
	-- Add ability modifiers
	if rAction.stat then
		if (rAction.range == "M" and rAction.stat ~= "strength") or (rAction.range == "R" and rAction.stat ~= "dexterity") then
			local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	
	-- Add other modifiers
	rRoll.tags = tag;
	rRoll.crit = rAction.crit;

	if rAction.crit and rAction.crit < 20 then
		rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.crit .. "]";
	end
	if rAction.touch then
		rRoll.sDesc = rRoll.sDesc .. " [TOUCH]";
	end
	
	return rRoll;
end

function performGrappleRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getGrappleRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getGrappleRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "grapple";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier or 0;
	rRoll.sDesc = "[CMB]";

	if rAction.label and rAction.label ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. rAction.label;
	end
	
	-- Add ability modifiers
	if rAction.stat then
		if rAction.stat ~= "strength" then
			local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	
	return rRoll;
end

function modAttack(rSource, rTarget, rRoll)
	ActionAttack.clearCritState(rSource);
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	-- Check for opportunity attack
	local bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();

	-- Check defense modifiers
	local bTouch = ModifierManager.getKey("ATT_TCH");
	local bFlatFooted = ModifierManager.getKey("ATT_FF");
	local bCover = ModifierManager.getKey("DEF_COVER");
	local bPartialCover = ModifierManager.getKey("DEF_PCOVER");
	local bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");
	local bConceal = ModifierManager.getKey("DEF_CONC");
	local bTotalConceal = ModifierManager.getKey("DEF_TCONC");
	
	if bOpportunity then
		table.insert(aAddDesc, "[OPPORTUNITY]");
	end
	if bTouch then
		if not string.match(rRoll.sDesc, "%[TOUCH%]") then
			table.insert(aAddDesc, "[TOUCH]");
		end
	end
	if bFlatFooted then
		table.insert(aAddDesc, "[FF]");
	end
	if bSuperiorCover then
		table.insert(aAddDesc, "[COVER -8]");
	elseif bCover then
		table.insert(aAddDesc, "[COVER -4]");
	elseif bPartialCover then
		table.insert(aAddDesc, "[COVER -2]");
	end
	if bConceal then
		table.insert(aAddDesc, "[CONCEAL]");
	end
	if bTotalConceal then
		table.insert(aAddDesc, "[TOTAL CONC]");
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
		-- Determine attack type
		local sAttackType = nil;
		if rRoll.sType == "attack" then
			sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
			if not sAttackType then
				sAttackType = "M";
			end
		elseif rRoll.sType == "grapple" then
			sAttackType = "M";
		end

		-- Determine ability used
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			if sAttackType == "M" then
				sActionStat = "strength";
			elseif sAttackType == "R" then
				sActionStat = "dexterity";
			end
		end

		-- Build attack filter
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end
		
		-- Get attack effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManagerFFd20.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter, rTarget);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		if rRoll.sType == "grapple" then
			local aPFDice, nPFMod, nPFCount = EffectManagerFFd20.getEffectsBonus(rSource, {"CMB"}, false, aAttackFilter, rTarget);
			if nPFCount > 0 then
				bEffects = true;
				for k, v in ipairs(aPFDice) do
					table.insert(aAddDice, v);
				end
				nAddMod = nAddMod + nPFMod;
			end
		end

		-- Get advantage effects
		if EffectManagerFFd20.hasEffect(rSource, "ADVATK", rTarget) then
			bEffects = true;
			bADV = true;
		elseif #(EffectManagerFFd20.getEffectsByType(rSource, "ADVATK", aAttackFilter, rTarget)) > 0 then
			bEffects = true;
			bADV = true;
		end
		if EffectManagerFFd20.hasEffect(rSource, "DISATK", rTarget) then
			bEffects = true;
			bDIS = true;
		elseif #(EffectManagerFFd20.getEffectsByType(rSource, "DISATK", aAttackFilter, rTarget)) > 0 then
			bEffects = true;
			bDIS = true;
		end
		

		-- Get condition modifiers
		if EffectManagerFFd20.hasEffect(rSource, "Invisible") then
			bEffects = true;
			nAddMod = nAddMod + 2;
			table.insert(aAddDesc, "[CA]");
		elseif EffectManagerFFd20.hasEffect(rSource, "CA") then
			bEffects = true;
			table.insert(aAddDesc, "[CA]");
		end
		if EffectManagerFFd20.hasEffect(rSource, "Blinded") then
			bEffects = true;
			table.insert(aAddDesc, "[BLINDED]");
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Dazzled") then
			bEffects = true;
			nAddMod = nAddMod - 1;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Slowed") then
			bEffects = true;
			nAddMod = nAddMod - 1;
		end
		if EffectManagerFFd20.hasEffectCondition(rSource, "Entangled") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if rRoll.sType == "attack" and 
				(EffectManagerFFd20.hasEffectCondition(rSource, "Pinned") or
				EffectManagerFFd20.hasEffectCondition(rSource, "Grappled")) then
			bEffects = true;
			nAddMod = nAddMod - 2;
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

		-- Get other effect modifiers
		if EffectManagerFFd20.hasEffectCondition(rSource, "Squeezing") then
			bEffects = true;
			nAddMod = nAddMod - 4;
		end
		if EffectManager.hasCondition(rSource, "Prone") then
			if sAttackType == "M" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		end
		
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
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if bSuperiorCover then
		nAddMod = nAddMod - 8;
	elseif bCover then
		nAddMod = nAddMod - 4;
	elseif bPartialCover then
		nAddMod = nAddMod - 2;
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;

	ActionAdvantage.encodeAdvantage(rRoll, bADV, bDIS);
end

function onAttack(rSource, rTarget, rRoll)
	ActionAdvantage.decodeAdvantage(rRoll);
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bIsSourcePC = ActorManager.isPC(rSource);
	local bAllowCC = OptionsManager.isOption("HRCC", "on") or (not bIsSourcePC and OptionsManager.isOption("HRCC", "npc"));
	
	if rRoll.sDesc:match("%[CMB") then
		rRoll.sType = "grapple";
	end
	
	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};
	
	-- If we have a target, then calculate the defense we need to exceed
	if rRoll.sType == "critconfirm" then
		local sDefenseVal = rRoll.sDesc:match(" %[AC (%d+)%]");
		if sDefenseVal then
			rRoll.nDefenseVal = tonumber(sDefenseVal);
		end
		rRoll.nMissChance = tonumber(rRoll.sDesc:match("%[MISS CHANCE (%d+)%%%]")) or 0;
		rMessage.text = rMessage.text:gsub(" %[AC %d+%]", "");
		rMessage.text = rMessage.text:gsub(" %[MISS CHANCE %d+%%%]", "");
	else
		rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus, rRoll.nMissChance = ActorManagerFFd20.getDefenseValue(rSource, rTarget, rRoll);
		if rRoll.nAtkEffectsBonus ~= 0 then
			rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
			local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
			table.insert(rRoll.aMessages, string.format(sFormat, rRoll.nAtkEffectsBonus));
		end
		if rRoll.nDefEffectsBonus ~= 0 then
			rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
			local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]";
			table.insert(rRoll.aMessages, string.format(sFormat, rRoll.nDefEffectsBonus));
		end
	end

	-- Get the crit threshold
	rRoll.nCrit = 20;
	local sAltCritRange = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	if sAltCritRange then
		rRoll.nCrit = tonumber(sAltCritRange) or 20;
		if (rRoll.nCrit <= 1) or (rRoll.nCrit > 20) then
			rRoll.nCrit = 20;
		end
	end
	
	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	rRoll.bCritThreat = false;
	if rRoll.nFirstDie >= 20 then
		rRoll.bSpecial = true;
		if rRoll.sType == "critconfirm" then
			rRoll.sResult = "crit";
			table.insert(rRoll.aMessages, "[CRITICAL HIT]");
		elseif rRoll.sType == "attack" then
			if bAllowCC then
				rRoll.sResult = "hit";
				rRoll.bCritThreat = true;
				table.insert(rRoll.aMessages, "[AUTOMATIC HIT]");
			else
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			end
		else
			rRoll.sResult = "hit";
			table.insert(rRoll.aMessages, "[AUTOMATIC HIT]");
		end
	elseif rRoll.nFirstDie == 1 then
		if rRoll.sType == "critconfirm" then
			table.insert(rRoll.aMessages, "[CRIT NOT CONFIRMED]");
			rRoll.sResult = "miss";
		else
			table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
			rRoll.sResult = "fumble";
		end
	elseif rRoll.nDefenseVal then
		if rRoll.nTotal >= rRoll.nDefenseVal then
			if rRoll.sType == "critconfirm" then
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			elseif rRoll.sType == "attack" and rRoll.nFirstDie >= rRoll.nCrit then
				if bAllowCC then
					rRoll.sResult = "hit";
					rRoll.bCritThreat = true;
					table.insert(rRoll.aMessages, "[CRITICAL THREAT]");
				else
					rRoll.sResult = "crit";
					table.insert(rRoll.aMessages, "[CRITICAL HIT]");
				end
			else
				rRoll.sResult = "hit";
				table.insert(rRoll.aMessages, "[HIT]");
			end
		else
			rRoll.sResult = "miss";
			if rRoll.sType == "critconfirm" then
				table.insert(rRoll.aMessages, "[CRIT NOT CONFIRMED]");
			else
				table.insert(rRoll.aMessages, "[MISS]");
			end
		end
	elseif rRoll.sType == "critconfirm" then
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CHECK FOR CRITICAL]");
	elseif rRoll.sType == "attack" and rRoll.nFirstDie >= rRoll.nCrit then
		if bAllowCC then
			rRoll.sResult = "hit";
			rRoll.bCritThreat = true;
		else
			rRoll.sResult = "crit";
		end
		table.insert(rRoll.aMessages, "[CHECK FOR CRITICAL]");
	end
	
	if ((rRoll.sType == "critconfirm") or not rRoll.bCritThreat) and (rRoll.nMissChance > 0) then
		table.insert(rRoll.aMessages, "[MISS CHANCE " .. rRoll.nMissChance .. "%]");
	end

	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
end

function onPreAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- Do nothing; location to override
end

function onAttackResolve(rSource, rTarget, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);

	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end
	
	local bRollMissChance = false;
	if rRoll.sType == "critconfirm" then
		bRollMissChance = true;
	else
		if rRoll.bCritThreat then
			local rCritConfirmRoll = { sType = "critconfirm", aDice = {"d20"}, bTower = rRoll.bTower, bSecret = rRoll.bSecret };
				
			local nCCMod = EffectManagerFFd20.getEffectsBonus(rSource, {"CC"}, true, nil, rTarget);
			if nCCMod ~= 0 then
				rCritConfirmRoll.sDesc = string.format("%s [CONFIRM %+d]", rRoll.sDesc, nCCMod);
			else
				rCritConfirmRoll.sDesc = rRoll.sDesc .. " [CONFIRM]";
			end
			if rRoll.nMissChance > 0 then
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " [MISS CHANCE " .. rRoll.nMissChance .. "%]";
			end
			rCritConfirmRoll.nMod = rRoll.nMod + nCCMod;
			
			if rRoll.nDefenseVal then
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " [AC " .. rRoll.nDefenseVal .. "]";
			end

			if (rRoll.nAtkEffectsBonus or 0) ~= 0 then
				local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " " .. string.format(sFormat, rRoll.nAtkEffectsBonus);
			end
			
			ActionsManager.roll(rSource, { rTarget }, rCritConfirmRoll, true);
		elseif (rRoll.sResult ~= "miss") and (rRoll.sResult ~= "fumble") then
			bRollMissChance = true;
		end
	end
	if bRollMissChance and (rRoll.nMissChance > 0) then
		local aMissChanceDice = { "d100" };
		local sMissChanceText = rMessage.text:gsub(" %[CRIT %d+%]", ""):gsub(" %[CONFIRM%]", "");
		local rMissChanceRoll = { sType = "misschance", sDesc = sMissChanceText .. " [MISS CHANCE " .. rRoll.nMissChance .. "%]", aDice = aMissChanceDice, nMod = 0 };
		ActionsManager.roll(rSource, rTarget, rMissChanceRoll);
	end

	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rRoll.nTotal, table.concat(rRoll.aMessages, " "));
		
		-- REMOVE TARGET ON MISS OPTION
		if (rRoll.sResult == "miss" or rRoll.sResult == "fumble") and rRoll.sType ~= "critconfirm" and not string.match(rRoll.sDesc, "%[FULL%]") then
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif rRoll.bRemoveOnMiss then
				bRemoveTarget = true;
			end
			
			if bRemoveTarget then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end
end

function onPostAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rRoll.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		ActionAttack.notifyApplyHRFC("Fumble");
	end
	if rRoll.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		ActionAttack.notifyApplyHRFC("Critical Hit");
	end
end

function onGrapple(rSource, rTarget, rRoll)
	ActionAttack.onAttack(rSource, rTarget, rRoll);
end

function onMissChance(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	local nMissChance = tonumber(string.match(rMessage.text, "%[MISS CHANCE (%d+)%%%]")) or 0;
	if nTotal <= nMissChance then
		rMessage.text = rMessage.text .. " [MISS]";
		if rTarget then
			rMessage.icon = "roll_attack_miss";
			ActionAttack.clearCritState(rSource, rTarget);
		else
			rMessage.icon = "roll_attack";
		end
	else
		rMessage.text = rMessage.text .. " [HIT]";
		if rTarget then
			rMessage.icon = "roll_attack_hit";
		else
			rMessage.icon = "roll_attack";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

function applyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	if sAttackType == "grapple" then
		msgShort.text = "Combat Man. ->";
		msgLong.text = "Combat Man. [" .. nTotal .. "] ->";
	else
		msgShort.text = "Attack ->";
		msgLong.text = "Attack [" .. nTotal .. "] ->";
	end
	if rTarget then
		local sName = ActorManager.getDisplayName(rTarget);
		msgShort.text = msgShort.text .. " [at " .. sName .. "]";
		msgLong.text = msgLong.text .. " [at " .. sName .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "roll_attack";
	if string.match(sResults, "%[CRITICAL HIT%]") then
		msgLong.icon = "roll_attack_crit";
	elseif string.match(sResults, "HIT%]") then
		msgLong.icon = "roll_attack_hit";
	elseif string.match(sResults, "MISS%]") then
		msgLong.icon = "roll_attack_miss";
	elseif string.match(sResults, "CRITICAL THREAT%]") then
		msgLong.icon = "roll_attack_hit";
	else
		msgLong.icon = "roll_attack";
	end
		
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};

function setCritState(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end
	
	if not aCritState[sSourceCT] then
		aCritState[sSourceCT] = {};
	end
	table.insert(aCritState[sSourceCT], sTargetCT);
end

function clearCritState(rSource, rTarget)
	if rTarget then
		ActionAttack.isCrit(rSource, rTarget);
		return;
	end
	
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
	end
end

function isCrit(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end

	if not aCritState[sSourceCT] then
		return false;
	end
	
	for k,v in ipairs(aCritState[sSourceCT]) do
		if v == sTargetCT then
			table.remove(aCritState[sSourceCT], k);
			return true;
		end
	end
	
	return false;
end
