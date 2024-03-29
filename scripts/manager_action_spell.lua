-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVEVS = "applysavevs";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVEVS, handleApplySave);

	ActionsManager.registerTargetingHandler("cast", onSpellTargeting);
	ActionsManager.registerTargetingHandler("clc", onSpellTargeting);
	ActionsManager.registerTargetingHandler("spellsave", onSpellTargeting);

	ActionsManager.registerModHandler("castsave", modCastSave);
	ActionsManager.registerModHandler("spellsave", modCastSave);
	ActionsManager.registerModHandler("clc", modCLC);
	ActionsManager.registerModHandler("concentration", modConcentration);
	
	ActionsManager.registerResultHandler("cast", onSpellCast);
	ActionsManager.registerResultHandler("castclc", onCastCLC);
	ActionsManager.registerResultHandler("castsave", onCastSave);
	ActionsManager.registerResultHandler("clc", onCLC);
	ActionsManager.registerResultHandler("spellsave", onSpellSave);
	ActionsManager.registerResultHandler("spellfailure", onSpellFailure);
end

function handleApplySave(msgOOB)
	-- GET THE TARGET ACTOR
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.save_stol[sSaveShort];
		if sSave then
			ActionSave.performVsRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, msgOOB.bRemoveOnMiss, msgOOB.sDesc, msgOOB.tags);
		end
	end
end

function notifyApplySave(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss, tags)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVEVS;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;
	msgOOB.tags = tags;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	if bRemoveOnMiss then
		msgOOB.bRemoveOnMiss = 1;
	end

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if nodeTarget and (sTargetNodeType == "pc") then
		if Session.IsHost then
			local sOwner = DB.getOwner(nodeTarget);
			if (sOwner or "") ~= "" then
				for _,vUser in ipairs(User.getActiveUsers()) do
					if vUser == sOwner then
						for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
							if DB.getName(nodeTarget) == vIdentity then
								Comm.deliverOOBMessage(msgOOB, sOwner);
								return;
							end
						end
					end
				end
			end
		else
			if DB.isOwner(nodeTarget) then
				handleApplySave(msgOOB);
				return;
			end
		end
	end
	Comm.deliverOOBMessage(msgOOB, "");
end

function onSpellTargeting(rSource, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		bRemoveOnMiss = (#aTargets > 1);
	end
	
	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = "true";
		end
	end

	return aTargeting;
end

function getSpellCastRoll(rActor, rAction, tag)
	local rRoll = {};
	rRoll.sType = "cast";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	rRoll.tags = tag;
	
	rRoll.sDesc = "[CAST";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;

	if rRoll.tags then
		rRoll.sDesc = rRoll.sDesc .. " [TAGS: " .. rRoll.tags .. "]";
	end
	
	return rRoll;
end

function getCLCRoll(rActor, rAction, tag)
	local rRoll = {};
	rRoll.sType = "clc";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.clc or 0;
	rRoll.tags = tag;
	
	rRoll.sDesc = "[CL CHECK";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if rAction.sr == "no" then
		rRoll.sDesc = rRoll.sDesc .. " [SR NOT ALLOWED]";
	end
	
	return rRoll;
end

function getSaveVsRoll(rActor, rAction, tag)
	local rRoll = {};
	rRoll.sType = "spellsave";
	rRoll.aDice = {};
	rRoll.tags = tag;

	local nDCMod = EffectManagerFFd20.getEffectsBonus(rActor, {"DC"}, true, nil, nil, false, rRoll.tags);
	rAction.savemod = rAction.savemod + nDCMod;
	rRoll.nMod = rAction.savemod or 0;
	
	rRoll.sDesc = "[SAVE VS";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if rAction.save == "fortitude" then
		rRoll.sDesc = rRoll.sDesc .. " [FORT DC " .. rAction.savemod .. "]";
	elseif rAction.save == "reflex" then
		rRoll.sDesc = rRoll.sDesc .. " [REF DC " .. rAction.savemod .. "]";
	elseif rAction.save == "will" then
		rRoll.sDesc = rRoll.sDesc .. " [WILL DC " .. rAction.savemod .. "]";
	end

	if rAction.dcstat then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.dcstat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	if rAction.onmissdamage == "half" then
		rRoll.sDesc = rRoll.sDesc .. " [HALF ON SAVE]";
	end

	return rRoll;
end

function modCastSave(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if sActionStat then
			local nBonusStat, nBonusEffects = ActorManagerFFd20.getAbilityEffectsBonus(rSource, sActionStat, rRoll.tags);
			if nBonusEffects > 0 then
				rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(nBonusStat));
				rRoll.nMod = rRoll.nMod + nBonusStat;
			end
		end
	end
end

function modCLC(rSource, rTarget, rRoll)
	if rSource then
		local aAddDice = {};
		local nAddMod = 0;
		
		-- Get CLC modifier effects
		local nCLCMod, nCLCCount = EffectManagerFFd20.getEffectsBonus(rSource, {"CLC"}, true, nil, rTarget, false, rRoll.tags);
		if nCLCCount > 0 then
			bEffects = true;
			nAddMod = nAddMod + nCLCMod;
		end
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManagerFFd20.getEffectsBonus(rSource, {"NLVL"}, true, nil, nil, false, rRoll.tags);
		if nNegLevelCount > 0 then
			bEffects = true;
			nAddMod = nAddMod - nNegLevelMod;
		end

		if bEffects then
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(sMod));
			for _,vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
		end
	end
end

function modConcentration(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end

		local nBonusStat, nBonusEffects = ActorManagerFFd20.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(nBonusStat));
			rRoll.nMod = rRoll.nMod + nBonusStat;
		end
	end
end

function onSpellCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "power_use";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
		
		local spellImmunity = EffectManagerFFd20.hasEffect(rTarget, "IMMUNE", rSource, false, false, rRoll.tags);
		if spellImmunity then
			rMessage.text = rMessage.text .. " [IMMUNE]";
			rMessage.icon = "spell_cast_fail";
		end

		local nSpellFailure = CharManager.getSpellFailure(ActorManager.getCreatureNode(rSource));
		local nSFEffect = EffectManagerFFd20.getEffectsBonus(rSource, "SF", true);
		if nSpellFailure > 0 or nSFEffect ~= 0 then
			local rSpellFailureRoll = { sType = "spellfailure", sDesc = "[SPELL FAILURE " .. nSpellFailure + nSFEffect .. "%]", aDice = { "d100" }, nMod = 0 };
			ActionsManager.roll(rSource, rTarget, rSpellFailureRoll);
		end
	Comm.deliverChatMessage(rMessage);
	end
end

function onSpellFailure(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	local nSpellFailure = tonumber(string.match(rRoll.sDesc, "%[SPELL FAILURE (%d+)%%%]")) or 0;

	if nTotal <= nSpellFailure then
		rMessage.text = rMessage.text .. " [FAILURE]";
		rMessage.icon = "spell_cast_fail";
	else
		rMessage.text = rMessage.text .. " [SUCCESS]";
		rMessage.icon = "power_use";
	end

	Comm.deliverChatMessage(rMessage);
end

function onCastCLC(rSource, rTarget, rRoll)
	if rTarget then
		local nSRMod = EffectManagerFFd20.getEffectsBonus(rTarget, {"SR"}, true, nil, rSource, false);

		local nSR = math.max(ActorManagerFFd20.getSpellDefense(rTarget), nSRMod);
		if nSR > 0 then
			if not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]") then
				local bWeakness = EffectManagerFFd20.hasEffect(rTarget, "WEAK", rSource, false, false, rRoll.tags);
				if bWeakness then
					rRoll.nMod = rRoll.nMod + 2;
					rRoll.sDesc = "[WEAK]" .. rRoll.sDesc;
				end
				local rRoll = { sType = "clc", sDesc = rRoll.sDesc, aDice = {"d20"}, nMod = rRoll.nMod, bRemoveOnMiss = rRoll.bRemoveOnMiss };
				ActionsManager.actionDirect(rSource, "clc", { rRoll }, { { rTarget } });
				return true;
			end
		end
	end
end

function onCastSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort, sSaveDC = string.match(rRoll.sDesc, "%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.save_stol[sSaveShort];
			if sSave then		
				notifyApplySave(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.bRemoveOnMiss, rRoll.tags);
				return true;
			end
		end
	end

	return false;
end

function onCLC(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	local bSRAllowed = not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]");
	
	if rTarget then
		local nSRMod = EffectManagerFFd20.getEffectsBonus(rTarget, {"SR"}, true, nil, rSource, false);
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
		
		if bSRAllowed then
			local nSR = math.max(ActorManagerFFd20.getSpellDefense(rTarget), nSRMod);
			if nSR > 0 then
				if nTotal >= nSR then
					rMessage.text = rMessage.text .. " [SUCCESS]";
				else
					rMessage.text = rMessage.text .. " [FAILURE]";
					if rSource then
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
			else
				rMessage.text = rMessage.text .. " [TARGET HAS NO SR]";
			end
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onSpellSave(rSource, rTarget, rRoll)
	if onCastSave(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
