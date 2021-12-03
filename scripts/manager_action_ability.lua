-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("ability", modRoll);
	ActionsManager.registerResultHandler("ability", onRoll);
end

function performPartySheetRoll(draginfo, rActor, sAbilityStat)
	local rRoll = getRoll(rActor, sAbilityStat);
	
	local nTargetDC = DB.getValue("partysheet.abilitydc", 0);
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

function performRoll(draginfo, rActor, sAbilityStat)
	local rRoll = getRoll(rActor, sAbilityStat);
	
	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sAbilityStat)
	local rRoll = {};
	rRoll.sType = "ability";
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManager35E.getAbilityBonus(rActor, sAbilityStat);
	
	rRoll.sDesc = "[ABILITY]";
	rRoll.sDesc = rRoll.sDesc .. " " .. StringManager.capitalize(sAbilityStat);
	rRoll.sDesc = rRoll.sDesc .. " check";

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		local sActionStat = nil;
		local sAbility = string.match(rRoll.sDesc, "%[ABILITY%] (%w+) check");
		if sAbility then
			sAbility = string.lower(sAbility);
		else
			if string.match(rRoll.sDesc, "%[STABILIZATION%]") then
				sAbility = "constitution";
			end
		end

		-- GET ACTION MODIFIERS
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager35E.getEffectsBonus(rSource, {"ABIL"}, false, {sAbility});
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- GET CONDITION MODIFIERS
		if EffectManager35E.hasEffectCondition(rSource, "Frightened") or 
				EffectManager35E.hasEffectCondition(rSource, "Panicked") or
				EffectManager35E.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if EffectManager35E.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end

		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager35E.getAbilityEffectsBonus(rSource, sAbility);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- HANDLE NEGATIVE LEVELS
		local nNegLevelMod, nNegLevelCount = EffectManager35E.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			nAddMod = nAddMod - nNegLevelMod;
			bEffects = true;
		end

		-- IF EFFECTS HAPPENED, THEN ADD NOTE
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
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

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
	
	Comm.deliverChatMessage(rMessage);
end

