-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onResolve);
end

function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end

function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;
	
	msgOOB.nTotal = nTotal;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[INIT]";
	
	rRoll.bSecret = bSecretRoll;

	-- Determine the modifier and ability to use for this roll
	local sAbility = nil;
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sNodeType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);
			sAbility = DB.getValue(nodeActor, "initiative.ability", "");
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
	if sAbility and sAbility ~= "" and sAbility ~= "dexterity" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end

	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = getRoll(rActor, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			sActionStat = "dexterity";
		end
		
		local bEffects, aEffectDice, nEffectMod, bADV, bDIS = getEffectAdjustments(rSource, sActionStat);
		if bEffects then
			for _,vDie in ipairs(aEffectDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nEffectMod;

			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(sMod));
		end
		ActionAdvantage.encodeAdvantage(rRoll, bADV, bDIS);
	end
end

-- Returns effect existence, effect dice, effect mod
function getEffectAdjustments(rActor, sActionStat)
	if rActor == nil then
		return false, {}, 0;
	end
	
	-- Determine initiative ability used
	if not sActionStat then
		local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
		if nodeActor and (sNodeType == "pc") then
			sActionStat = DB.getValue(nodeActor, "initiative.ability", "");
		end
		if (sActionStat or "") == "" then
			sActionStat = "dexterity";
		end
	end
	
	-- Set up
	local bEffects = false;
	local aEffectDice = {};
	local nEffectMod = 0;
	local bADV = false;
	local bDIS = false;
	
	-- Determine general effect modifiers
	local aCheckFilter = { sActionStat };
	local aInitDice, nInitMod, nInitCount = EffectManagerFFd20.getEffectsBonus(rActor, {"INIT"});
	if nInitCount > 0 then
		bEffects = true;
		for _,vDie in ipairs(aInitDice) do
			table.insert(aEffectDice, vDie);
		end
		nEffectMod = nEffectMod + nInitMod;
	end
	
	-- Get ability effect modifiers
	local nAbilityMod, nAbilityEffects = ActorManagerFFd20.getAbilityEffectsBonus(rActor, sActionStat);
	if nAbilityEffects > 0 then
		bEffects = true;
		nEffectMod = nEffectMod + nAbilityMod;
	end

	-- Get condition modifiers
	if EffectManagerFFd20.hasEffectCondition(rActor, "ADVINIT") then
		bEffects = true;
		bADV = true;
	end
	if EffectManagerFFd20.hasEffectCondition(rActor, "DISINIT") then
		bEffects = true;
		bDIS = true;
	end

	-- Dexterity check conditions
	if EffectManagerFFd20.hasEffectCondition(rActor, "ADVABIL") then
		bEffects = true;
		bADV = true;
	elseif #(EffectManagerFFd20.getEffectsByType(rActor, "ADVABIL", aCheckFilter)) > 0 then
		bEffects = true;
		bADV = true;
	end
	if EffectManagerFFd20.hasEffectCondition(rActor, "DISABIL") then
		bEffects = true;
		bDIS = true;
	elseif #(EffectManagerFFd20.getEffectsByType(rActor, "DISABIL", aCheckFilter)) > 0 then
		bEffects = true;
		bDIS = true;
	end
	
	-- Check special conditions
	if EffectManagerFFd20.hasEffectCondition(rActor, "Deafened") then
		bEffects = true;
		nEffectMod = nEffectMod - 4;
	end

	return bEffects, aEffectDice, nEffectMod, bADV, bDIS;
end

function onResolve(rSource, rTarget, rRoll)
	ActionAdvantage.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
	
	local nTotal = ActionsManager.total(rRoll);
	notifyApplyInit(rSource, nTotal);
end
