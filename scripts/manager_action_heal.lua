-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("heal", modHeal);
	ActionsManager.registerResultHandler("heal", onHeal);
end

function getRoll(rActor, rAction, tag)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	rRoll.tags = tag;
	
	rRoll.sDesc = "[HEAL";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;

	-- Save the heal clauses in the roll structure
	rRoll.clauses = rAction.clauses;

	-- Add heal type to roll data
	if rAction.subtype == "temp" then
		rRoll.healtype = "temp";
	else
		rRoll.healtype = "health";
	end
	
	-- Add the dice and modifiers
	for _,vClause in pairs(rRoll.clauses) do
		DiceRollManager.addHealDice(rRoll.aDice, vClause.dice, { healtype = rRoll.healtype });
		rRoll.nMod = rRoll.nMod + vClause.modifier;
	end

	-- Encode the damage types
	ActionHeal.encodeHealClauses(rRoll);

	-- Handle temporary hit points
	if rAction.subtype == "temp" then
		rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
	end

	-- Encode meta tags
	if rAction.meta then
		if rAction.meta == "empower" then
			rRoll.sDesc = rRoll.sDesc .. " [EMPOWER]";
		elseif rAction.meta == "maximize" then
			rRoll.sDesc = rRoll.sDesc .. " [MAXIMIZE]";
		end
	end

	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end

	return rRoll;
end

function modHeal(rSource, rTarget, rRoll)
	ActionHeal.decodeHealClauses(rRoll);
	CombatManager2.addRightClickDiceToClauses(rRoll);

	-- Set up
	local aAddDesc = {};
	
	-- If source actor, then get modifiers
	if rSource then
		local bEffects = false;
		local aEffectDice = {};
		local nEffectMod = 0;

		-- Apply ability modifiers
		for kClause,vClause in ipairs(rRoll.clauses) do
			-- Get original stat modifier
			local nStatMod = ActorManagerFFd20.getAbilityBonus(rSource, vClause.stat);
			
			-- Get any stat effects bonus
			local nBonusStat, nBonusEffects = ActorManagerFFd20.getAbilityEffectsBonus(rSource, vClause.stat);
			if nBonusEffects > 0 then
				bEffects = true;
				
				-- Calc total stat mod
				local nTotalStatMod = nStatMod + nBonusStat;
				
				-- Handle maximum stat mod setting
				local nStatModMax = vClause.statmax or 0;
				if nStatModMax > 0 then
					nStatMod = math.max(math.min(nStatMod, nStatModMax), 0);
					nTotalStatMod = math.max(math.min(nTotalStatMod, nStatModMax), 0);
				end

				-- Calculate bonus difference (and handle decimal multiples)
				local nMult = math.max(vClause.statmult or 1, 1);
				local nMultOrigStatMod = math.floor(nStatMod * nMult);
				local nMultNewStatMod = math.floor(nTotalStatMod * nMult);
				local nMultDiffStatMod = nMultNewStatMod - nMultOrigStatMod;
				
				-- Apply bonus difference
				nEffectMod = nEffectMod + nMultDiffStatMod;
				vClause.modifier = vClause.modifier + nMultDiffStatMod;
				rRoll.nMod = rRoll.nMod + nMultDiffStatMod;
			end
		end
		
		-- Apply general heal modifiers
		local nEffectCount;
		local aAddDice, nAddMod, nEffectCount = EffectManagerFFd20.getEffectsBonus(rSource, {"HEAL"});
		if (nEffectCount > 0) then
			bEffects = true;
			
			DiceRollManager.addHealDice(rRoll.aDice, aAddDice, { iconcolor = "FF00FF", healtype = rRoll.healtype });
			nEffectMod = nEffectMod + nAddMod;
			rRoll.nMod = rRoll.nMod + nAddMod;
		end
		
		-- Add note about effects
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	-- Add notes to roll description
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
end

function onHeal(rSource, rTarget, rRoll)
	-- Meta spell processing
	local bMaximize = rRoll.sDesc:match(" %[MAXIMIZE%]");
	local bEmpower = rRoll.sDesc:match(" %[EMPOWER%]");
	if bMaximize then
		for _, v in ipairs(rRoll.aDice) do
			local nDieSides = tonumber(v.type:match("d(%d+)")) or 0;
			if nDieSides > 0 then
				v.result = nDieSides;
				v.value = v.result;
			end
		end
	end
	if bEmpower then
		local nEmpowerTotal = ActionsManager.total(rRoll);
		local nEmpowerMod = math.floor(nEmpowerTotal / 2);
		
		local sReplace = string.format(" [EMPOWER %+d]", nEmpowerMod);
		rRoll.sDesc = rRoll.sDesc:gsub(" %[EMPOWER%]", sReplace);
		rRoll.nMod = rRoll.nMod + nEmpowerMod;
	end
	
	-- Deliver chat message
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end
	
	-- Apply heal to target
	local nTotal = ActionsManager.total(rRoll);
	ActionDamage.notifyApplyDamage(rSource, rTarget, rMessage.secret, rRoll.sType, rMessage.text, nTotal);
end

--
-- UTILITY FUNCTIONS
--

function encodeHealClauses(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		rRoll.sDesc = rRoll.sDesc .. string.format(" [CLAUSE: (%s) (%s) (%s) (%s)]", sDice, vClause.stat or "", vClause.statmax or 0, vClause.statmult or 1);
	end
end

function decodeHealClauses(rRoll)
	-- Process each type clause in the damage description
	rRoll.clauses = {};
	for sDice, sStat, sStatMax, sStatMult in rRoll.sDesc:gmatch("%[CLAUSE: %(([^)]*)%) %(([^)]*)%) %(([^)]*)%) %(([^)]*)%)]") do
		local rClause = {};
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDice);
		rClause.stat = sStat;
		rClause.statmax = tonumber(sStatMax) or 0;
		rClause.statmult = tonumber(sStatMult) or 1;
		
		table.insert(rRoll.clauses, rClause);
	end
	
	-- Remove heal clause information from roll description
	rRoll.sDesc = rRoll.sDesc:gsub(" %[CLAUSE:[^]]*%]", "");
end

