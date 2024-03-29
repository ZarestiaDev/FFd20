-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	initActorHealth();
end

--
--	HEALTH
-- 

function initActorHealth()
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_UNCONSCIOUS, ColorManager.COLOR_HEALTH_UNCONSCIOUS);
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_DISABLED, ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED);
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_STAGGERED, ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED);

	ActorHealthManager.getWoundPercent = getWoundPercent;
end

-- NOTE: Always default to using CT node as primary to make sure 
--		that all bars and statuses are synchronized in combat tracker
--		(Cross-link network updates between PC and CT fields can occur in either order, 
--		depending on where the scripts or end user updates.)
-- NOTE 2: We can not use default effect checking in this function; 
-- 		as it will cause endless loop with conditionals that check health
function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	local nHP = 0;
	local nTemp = 0;
	local nWounds = 0;
	local nNonlethal = 0;

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		nHP = math.max(DB.getValue(nodeCT, "hp", 0), 0);
		nTemp = math.max(DB.getValue(nodeCT, "hptemp", 0), 0);
		nWounds = math.max(DB.getValue(nodeCT, "wounds", 0), 0);
		nNonlethal = math.max(DB.getValue(nodeCT, "nonlethal", 0), 0);
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0);
			nTemp = math.max(DB.getValue(nodePC, "hp.temporary", 0), 0);
			nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0);
			nNonlethal = math.max(DB.getValue(nodePC, "hp.nonlethal", 0), 0);
		end
	end
	
	local nPercentLethal = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentLethal = nWounds / nHP;
		nPercentNonlethal = (nWounds + nNonlethal) / (nHP + nTemp);
	end

	local sStatus;
	local bDiesAtZero = false;
	if ActorCommonManager.isCreatureTypeDnD(rActor, "construct,undead,swarm") then
		bDiesAtZero = true;
	end
	if bDiesAtZero and nPercentLethal >= 1 then
		sStatus = ActorHealthManager.STATUS_DEAD;
	elseif nPercentLethal > 1 then
		local nDying = GameSystem.getDeathThreshold(rActor);
		
		if (nWounds - nHP) < nDying then
			sStatus = ActorHealthManager.STATUS_DYING;
		else
			sStatus = ActorHealthManager.STATUS_DEAD;
		end
	elseif nPercentNonlethal > 1 then
		sStatus = ActorHealthManager.STATUS_UNCONSCIOUS;
	elseif nPercentLethal == 1 then
		sStatus = ActorHealthManager.STATUS_DISABLED;
	elseif nPercentNonlethal == 1 then
		sStatus = ActorHealthManager.STATUS_STAGGERED;
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentNonlethal);
	end
	
	return nPercentNonlethal, sStatus, nPercentLethal;
end

function getPCSheetWoundColor(nodePC)
	local nHP = 0;
	local nTemp = 0;
	local nWounds = 0;
	local nNonlethal = 0;
	if nodePC then
		nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0);
		nTemp = math.max(DB.getValue(nodePC, "hp.temporary", 0), 0);
		nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0);
		nNonlethal = math.max(DB.getValue(nodePC, "hp.nonlethal", 0), 0);
	end

	local nPercentLethal = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentLethal = nWounds / nHP;
		nPercentNonlethal = (nWounds + nNonlethal) / (nHP + nTemp);
	end
	
	if nPercentLethal > 1 then
		return ColorManager.COLOR_HEALTH_DYING_OR_DEAD;
	elseif nPercentNonlethal > 1 then
		return ColorManager.COLOR_HEALTH_UNCONSCIOUS;
	elseif nPercentLethal == 1 then
		return ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED;
	elseif nPercentNonlethal == 1 then
		return ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED;
	end

	local sColor = ColorManager.getHealthColor(nPercentNonlethal, false);
	return sColor;
end

--
--	ABILITY SCORES
--

function getAbilityEffectsBonus(rActor, sAbility, tags)
	if not rActor or not sAbility then
		return 0, 0;
	end
	
	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	if not sAbilityEffect then
		return 0, 0;
	end
	
	local nEffectMod, nAbilityEffects = EffectManagerFFd20.getEffectsBonus(rActor, sAbilityEffect, true, nil, nil, false, tags);
	
	if sAbility == "dexterity" then
		if EffectManagerFFd20.hasEffectCondition(rActor, "Entangled", tags) then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
		if EffectManagerFFd20.hasEffectCondition(rActor, "Grappled", tags) then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	if sAbility == "dexterity" or sAbility == "strength" then
		if EffectManagerFFd20.hasEffectCondition(rActor, "Exhausted", tags) then
			nEffectMod = nEffectMod - 6;
			nAbilityEffects = nAbilityEffects + 1;
		elseif EffectManagerFFd20.hasEffectCondition(rActor, "Fatigued", tags) then
			nEffectMod = nEffectMod - 2;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	
	local nEffectBonusMod = 0;
	if nEffectMod > 0 then
		nEffectBonusMod = math.floor(nEffectMod / 2);
	else
		nEffectBonusMod = math.ceil(nEffectMod / 2);
	end

	local nAbilityMod = 0;
	nAbilityMod = nEffectBonusMod;

	return nAbilityMod, nAbilityEffects;
end

function getAbilityDamage(rActor, sAbility)
	if not sAbility then
		return 0;
	end
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end
	
	local nStatDamage = 0;

	if sNodeType == "pc" then
		local sShort = string.sub(string.lower(sAbility), 1, 3);
		if sShort == "lev" then
			nStatDamage = 0;
		elseif sShort == "bab" then
			nStatDamage = 0;
		elseif sShort == "str" then
			nStatDamage = DB.getValue(nodeActor, "abilities.strength.damage", 0);
		elseif sShort == "dex" then
			nStatDamage = DB.getValue(nodeActor, "abilities.dexterity.damage", 0);
		elseif sShort == "con" then
			nStatDamage = DB.getValue(nodeActor, "abilities.constitution.damage", 0);
		elseif sShort == "int" then
			nStatDamage = DB.getValue(nodeActor, "abilities.intelligence.damage", 0);
		elseif sShort == "wis" then
			nStatDamage = DB.getValue(nodeActor, "abilities.wisdom.damage", 0);
		elseif sShort == "cha" then
			nStatDamage = DB.getValue(nodeActor, "abilities.charisma.damage", 0);
		end
	end
	
	return nStatDamage;
end

function getAbilityScore(rActor, sAbility)
	if not sAbility then
		return -1;
	end
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end
	
	local nStatScore = -1;
	
	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if sNodeType == "pc" then
		if sShort == "lev" then
			nStatScore = DB.getValue(nodeActor, "level", 0);
		elseif sShort == "bab" then
			nStatScore = DB.getValue(nodeActor, "attackbonus.base", 0);
		elseif sShort == "cmb" then
			nStatScore = DB.getValue(nodeActor, "attackbonus.base", 0);
		elseif sShort == "str" then
			nStatScore = DB.getValue(nodeActor, "abilities.strength.score", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(nodeActor, "abilities.dexterity.score", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(nodeActor, "abilities.constitution.score", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(nodeActor, "abilities.intelligence.score", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(nodeActor, "abilities.wisdom.score", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(nodeActor, "abilities.charisma.score", 0);
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		if sShort == "lev" then
			nStatScore = tonumber(string.match(DB.getValue(nodeActor, "hd", ""), "^(%d+)")) or 0;
		elseif sShort == "bab" then
			nStatScore = 0;

			local sBABCMB = DB.getValue(nodeActor, "babcmb", "");
			local sBAB = sBABCMB:match("[+-]?%d+");
			if sBAB then
				nStatScore = tonumber(sBAB) or 0;
			end
		elseif sShort == "cmb" then
			nStatScore = 0;

			local sBABCMB = DB.getValue(nodeActor, "babcmb", "");
			local sBAB = sBABCMB:match("CMB ([+-]?%d+)");
			if not sBAB then
				sBAB = sBABCMB:match("[+-]?%d+");
			end
			if sBAB then
				nStatScore = tonumber(sBAB) or 0;
			end
		elseif sShort == "str" then
			nStatScore = DB.getValue(nodeActor, "strength", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(nodeActor, "dexterity", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(nodeActor, "constitution", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(nodeActor, "intelligence", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(nodeActor, "wisdom", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(nodeActor, "charisma", 0);
		end
	end
	
	return nStatScore;
end

function getAbilityBonus(rActor, sAbility)
	if not sAbility then
		return 0;
	end
	if not rActor then
		return 0;
	end
	
	-- SETUP
	local sStat = sAbility;
	local bHalf = false;
	local bDouble = false;
	local nStatVal = 0;
	
	-- HANDLE HALF/DOUBLE MODIFIERS
	if string.match(sStat, "^half") then
		bHalf = true;
		sStat = string.sub(sStat, 5);
	end
	if string.match(sStat, "^double") then
		bDouble = true;
		sStat = string.sub(sStat, 7);
	end

	-- GET ABILITY VALUE
	local nStatScore = getAbilityScore(rActor, sStat);
	if nStatScore < 0 then
		return 0;
	end
	
	if StringManager.contains(DataCommon.abilities, sStat) then
		local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
		if nodeActor and (sNodeType == "pc") then
			nStatVal = nStatVal + DB.getValue(nodeActor, "abilities." .. sStat .. ".bonusmodifier", 0);
			
			local nAbilityDamage = DB.getValue(nodeActor, "abilities." .. sStat .. ".damage", 0);
			if nAbilityDamage >= 0 then
				nAbilityDamage = math.floor(nAbilityDamage / 2) * 2;
			else
				nAbilityDamage = math.ceil(nAbilityDamage / 2) * 2;
			end
			
			nStatScore = nStatScore - nAbilityDamage;
		end
		nStatVal = nStatVal + math.floor((nStatScore - 10) / 2);
	else
		nStatVal = nStatScore;
	end
	
	-- APPLY HALF/DOUBLE MODIFIERS
	if bDouble then
		nStatVal = nStatVal * 2;
	end
	if bHalf then
		nStatVal = math.floor(nStatVal / 2);
	end

	-- RESULTS
	return nStatVal;
end

--
--	DEFENSES
--

function getSpellDefense(rActor)
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nSR = 0;
	if sNodeType == "pc" then
		nSR = DB.getValue(nodeActor, "defenses.sr.total", 0);
	elseif sNodeType == "ct" then
		nSR = DB.getValue(nodeActor, "sr", 0);
	elseif sNodeType == "npc" then
		local sSpecialQualities = string.lower(DB.getValue(nodeActor, "specialqualities", ""));
		local sSpellResist = string.match(sSpecialQualities, "spell resistance (%d+)");
		if not sSpellResist then
			sSpellResist = string.match(sSpecialQualities, "sr (%d+)");
		end
		if sSpellResist then
			nSR = tonumber(sSpellResist) or 0;
		end
	end
	
	return nSR;
end

function getArmorComps(rActor)
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return {};
	end

	local aComps = {};
	
	if sNodeType == "pc" then
		local nACBonusComp = DB.getValue(nodeActor, "ac.sources.armor", 0);
		if nACBonusComp ~= 0 then
			aComps["armor"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.shield", 0);
		if nACBonusComp ~= 0 then
			aComps["shield"] = nACBonusComp;
		end
		local sAbility = DB.getValue(nodeActor, "ac.sources.ability", "");
		if DataCommon.ability_ltos[sAbility] then
			aComps[DataCommon.ability_ltos[sAbility]] = getAbilityBonus(rActor, sAbility);
		end
		local sAbility2 = DB.getValue(nodeActor, "ac.sources.ability2", "");
		if DataCommon.ability_ltos[sAbility2] then
			aComps[DataCommon.ability_ltos[sAbility2]] = getAbilityBonus(rActor, sAbility2);
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.size", 0);
		if nACBonusComp ~= 0 then
			aComps["size"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.naturalarmor", 0);
		if nACBonusComp ~= 0 then
			aComps["natural"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.deflection", 0);
		if nACBonusComp ~= 0 then
			aComps["deflection"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.dodge", 0);
		if nACBonusComp ~= 0 then
			aComps["dodge"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.misc", 0);
		if nACBonusComp ~= 0 then
			aComps["misc"] = nACBonusComp;
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		local sAC = DB.getValue(nodeActor, "ac", ""):lower();
		local nAC = tonumber(sAC:match("^(%d+)")) or 10;
		local sACComps = sAC:match("%(([^)]+)%)");
		local nCompTotal = 10;
		if sACComps then
			local aACSplit = StringManager.split(sACComps, ",", true);
			for _,vACComp in ipairs(aACSplit) do
				local sACCompBonus, sACCompType = vACComp:match("^([+-]%d+)%s+(.*)$");
				if not sACCompType then
					sACCompType, sACCompBonus = vACComp:match("^(.*)%s+([+-]%d+)$");
				end
				local nACCompBonus = tonumber(sACCompBonus) or 0;
				if sACCompType and nACCompBonus ~= 0 then
					sACCompType = sACCompType:gsub("[+-]%d+", "");
					sACCompType = StringManager.trim(sACCompType);
					
					if DataCommon.actypes[sACCompType] then
						aComps[DataCommon.actypes[sACCompType]] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acarmormatch, sACCompType) then
						aComps["armor"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acshieldmatch, sACCompType) then
						aComps["shield"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acdeflectionmatch, sACCompType) then
						aComps["deflection"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					end
				end
			end
		end
		if nCompTotal ~= nAC then
			aComps["misc"] = nAC - nCompTotal;
		end
	end

	return aComps;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	-- VALIDATE
	if not rDefender or not rRoll then
		return nil, 0, 0, 0;
	end
	
	local sAttack = rRoll.sDesc;
	
	-- DETERMINE ATTACK TYPE AND DEFENSE
	local sAttackType = "M";
	if rRoll.sType == "attack" then
		sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
	end
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
	local bTouch = true;
	if rRoll.sType == "attack" then
		bTouch = string.match(sAttack, "%[TOUCH%]");
	end
	local bFlatFooted = string.match(sAttack, "%[FF%]");
	local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0;
	local bConceal = string.match(sAttack, "%[CONCEAL%]");
	local bTotalConceal = string.match(sAttack, "%[TOTAL CONC%]");
	local bAttackerBlinded = string.match(sAttack, "%[BLINDED%]");

	-- Determine the defense database node name
	local nDefense = 10;
	local nFlatFootedMod = 0;
	local nTouchMod = 0;
	local sDefenseStat = "dexterity";
	local sDefenseStat2 = "";
	local sDefenseStat3 = "";
	if rRoll.sType == "cmb" then
		sDefenseStat3 = "strength";
	end

	local sDefenderNodeType, nodeDefender = ActorManager.getTypeAndNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, 0;
	end

	if sDefenderNodeType == "pc" then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(nodeDefender, "ac.totals.general", 10);
			nFlatFootedMod = nDefense - DB.getValue(nodeDefender, "ac.totals.flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(nodeDefender, "ac.totals.touch", 10);
		else
			nDefense = DB.getValue(nodeDefender, "ac.totals.cmd", 10);
			nFlatFootedMod = DB.getValue(nodeDefender, "ac.totals.general", 10) - DB.getValue(nodeDefender, "ac.totals.flatfooted", 10);
		end
		sDefenseStat = DB.getValue(nodeDefender, "ac.sources.ability", "");
		if sDefenseStat == "" then
			sDefenseStat = "dexterity";
		end
		sDefenseStat2 = DB.getValue(nodeDefender, "ac.sources.ability2", "");
		if rRoll.sType == "cmb" then
			sDefenseStat3 = DB.getValue(nodeDefender, "ac.sources.cmdability", "");
			if sDefenseStat3 == "" then
				sDefenseStat3 = "strength";
			end
		end
	elseif sDefenderNodeType == "ct" then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(nodeDefender, "ac_final", 10);
			nFlatFootedMod = nDefense - DB.getValue(nodeDefender, "ac_flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(nodeDefender, "ac_touch", 10);
		else
			nDefense = DB.getValue(nodeDefender, "cmd", 10);
			nFlatFootedMod = DB.getValue(nodeDefender, "ac_final", 10) - DB.getValue(nodeDefender, "ac_flatfooted", 10);
		end
	elseif sDefenderNodeType == "npc" then
		if rRoll.sType == "attack" then
			local sAC = DB.getValue(nodeDefender, "ac", "");
			nDefense = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nDefense - tonumber(sFlatFootedAC);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
			
			local sTouchAC = string.match(sAC, "touch (%d+)");
			if sTouchAC then
				nTouchMod = nDefense - tonumber(sTouchAC);
			end
		else
			local sBABCMB = DB.getValue(nodeDefender, "babcmb", "");
			local sMatch = string.match(sBABCMB, "CMD ([+-]?[0-9]+)");
			if sMatch then
				nDefense = tonumber(sMatch) or 10;
			else
				nDefense = 10;
			end
			
			local sAC = DB.getValue(nodeDefender, "ac", "");
			local nAC = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nAC - (tonumber(sFlatFootedAC) or 10);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
		end
	end

	nDefenseStatMod = getAbilityBonus(rDefender, sDefenseStat) + getAbilityBonus(rDefender, sDefenseStat2);
	
	-- MAKE SURE FLAT-FOOTED AND TOUCH ADJUSTMENTS ARE POSITIVE
	if nTouchMod < 0 then
		nTouchMod = 0;
	end
	if nFlatFootedMod < 0 then
		nFlatFootedMod = 0;
	end
	
	-- APPLY FLAT-FOOTED AND TOUCH ADJUSTMENTS
	if bTouch then
		nDefense = nDefense - nTouchMod;
	end
	if bFlatFooted then
		nDefense = nDefense - nFlatFootedMod;
	end
	
	-- EFFECT MODIFIERS
	local nDefenseEffectMod = 0;
	local nMissChance = 0;
	if ActorManager.hasCT(rDefender) then
		-- SETUP
		local bCombatAdvantage = false;
		local bZeroAbility = false;
		local nBonusAC = 0;
		local nBonusStat = 0;
		local nBonusSituational = 0;
		
		-- BUILD ATTACK FILTER 
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end

		-- CHECK IF COMBAT ADVANTAGE ALREADY SET BY ATTACKER EFFECT
		if sAttack:match("%[CA%]") then
			bCombatAdvantage = true;
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - GENERAL
		if EffectManagerFFd20.hasEffect(rAttacker, "CA", rDefender, true) then
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rAttacker, "Invisible", rDefender, true) then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "GRANTCA", rAttacker) then
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Blinded") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Cowering") or
				EffectManagerFFd20.hasEffect(rDefender, "Rebuked") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Slowed") then
			nBonusSituational = nBonusSituational - 1;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Flat-footed") or 
				EffectManagerFFd20.hasEffect(rDefender, "Flatfooted") or 
				EffectManagerFFd20.hasEffect(rDefender, "Climbing") or 
				EffectManagerFFd20.hasEffect(rDefender, "Running") then
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Pinned") then
			bCombatAdvantage = true;
			nBonusSituational = nBonusSituational - 4;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Helpless") or 
				EffectManagerFFd20.hasEffect(rDefender, "Paralyzed") or 
				EffectManagerFFd20.hasEffect(rDefender, "Petrified") or
				EffectManagerFFd20.hasEffect(rDefender, "Unconscious") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			end
			bZeroAbility = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Kneeling") or 
				EffectManagerFFd20.hasEffect(rDefender, "Sitting") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 2;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 2;
			end
		elseif EffectManager.hasCondition(rDefender, "Prone") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 4;
			end
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Squeezing") then
			nBonusSituational = nBonusSituational - 4;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Stunned") then
			nBonusSituational = nBonusSituational - 2;
			if rRoll.sType == "cmb" then
				nBonusSituational = nBonusSituational - 4;
			end
			bCombatAdvantage = true;
		end
		if EffectManagerFFd20.hasEffect(rDefender, "Invisible", rAttacker) then
			bTotalConceal = true;
		end
		
		-- DETERMINE EXISTING AC MODIFIER TYPES
		local aExistingBonusByType = getArmorComps (rDefender);
		
		-- GET DEFENDER ALL DEFENSE MODIFIERS
		local aIgnoreEffects = {};
		if bTouch then
			table.insert(aIgnoreEffects, "armor");
			table.insert(aIgnoreEffects, "shield");
			table.insert(aIgnoreEffects, "natural");
		end
		if bFlatFooted or bCombatAdvantage then
			table.insert(aIgnoreEffects, "dodge");
		end
		if rRoll.sType == "cmb" then
			table.insert(aIgnoreEffects, "size");
		end
		local aACEffects = EffectManagerFFd20.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
		for k,v in pairs(aACEffects) do
			if not StringManager.contains(aIgnoreEffects, k) then
				local sBonusType = DataCommon.actypes[k];
				if sBonusType then
					-- Dodge bonuses stack (by rules)
					if sBonusType == "dodge" then
						nBonusAC = nBonusAC + v.mod;
					-- Size bonuses stack (by usage expectation)
					elseif sBonusType == "size" then
						nBonusAC = nBonusAC + v.mod;
					elseif aExistingBonusByType[sBonusType] then
						if v.mod < 0 then
							nBonusAC = nBonusAC + v.mod;
						elseif v.mod > aExistingBonusByType[sBonusType] then
							nBonusAC = nBonusAC + v.mod - aExistingBonusByType[sBonusType];
						end
					else
						nBonusAC = nBonusAC + v.mod;
					end
				else
					nBonusAC = nBonusAC + v.mod;
				end
			end
		end
		if rRoll.sType == "cmb" then
			local nPFMod, nPFCount = EffectManagerFFd20.getEffectsBonus(rDefender, {"CMD"}, true, aAttackFilter, rAttacker);
			if nPFCount > 0 then
				nBonusAC = nBonusAC + nPFMod;
			end
		end
		
		-- GET DEFENDER DEFENSE STAT MODIFIERS
		local nBonusStat = 0;
		local nBonusStat1 = getAbilityEffectsBonus(rDefender, sDefenseStat);
		if (sDefenderNodeType == "pc") and (nBonusStat1 > 0) then
			if DB.getValue(nodeDefender, "encumbrance.armormaxstatbonusactive", 0) == 1 then
				local nCurrentStatBonus = getAbilityBonus(rDefender, sDefenseStat);
				local nMaxStatBonus = math.max(DB.getValue(nodeDefender, "encumbrance.armormaxstatbonus", 0), 0);
				local nMaxEffectStatModBonus = math.max(nMaxStatBonus - nCurrentStatBonus, 0);
				if nBonusStat1 > nMaxEffectStatModBonus then 
					nBonusStat1 = nMaxEffectStatModBonus; 
				end
			end
		end
		if not bFlatFooted and not bCombatAdvantage and sDefenseStat == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat1;
		end
		nBonusStat = nBonusStat + nBonusStat1;
		local nBonusStat2 = getAbilityEffectsBonus(rDefender, sDefenseStat2);
		if not bFlatFooted and not bCombatAdvantage and sDefenseStat2 == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat2;
		end
		nBonusStat = nBonusStat + nBonusStat2;
		local nBonusStat3 = getAbilityEffectsBonus(rDefender, sDefenseStat3);
		if not bFlatFooted and not bCombatAdvantage and sDefenseStat3 == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat3;
		end
		nBonusStat = nBonusStat + nBonusStat3;
		if bFlatFooted or bCombatAdvantage then
			-- IF NEGATIVE AND AC STAT BONUSES, THEN ONLY APPLY THE AMOUNT THAT EXCEEDS AC STAT BONUSES
			if nBonusStat < 0 then
				if nDefenseStatMod > 0 then
					nBonusStat = math.min(nDefenseStatMod + nBonusStat, 0);
				end
				
			-- IF POSITIVE AND AC STAT PENALTIES, THEN ONLY APPLY UP TO AC STAT PENALTIES
			else
				if nDefenseStatMod < 0 then
					nBonusStat = math.min(nBonusStat, -nDefenseStatMod);
				else
					nBonusStat = 0;
				end
			end
		end
		
		-- HANDLE NEGATIVE LEVELS
		if rRoll.sType == "cmb" then
			local nNegLevelMod, nNegLevelCount = EffectManagerFFd20.getEffectsBonus(rDefender, {"NLVL"}, true);
			if nNegLevelCount > 0 then
				nBonusSituational = nBonusSituational - nNegLevelMod;
			end
		end
		
		-- HANDLE DEXTERITY MODIFIER REMOVAL
		if bZeroAbility then
			if bFlatFooted then
				nBonusSituational = nBonusSituational - 5;
			else
				nBonusSituational = nBonusSituational - nFlatFootedMod - 5;
			end
		elseif bCombatAdvantage and not bFlatFooted then
			nBonusSituational = nBonusSituational - nFlatFootedMod;
		end

		-- GET DEFENDER SITUATIONAL MODIFIERS - COVER
		if nCover < 8 then
			local aCover = EffectManagerFFd20.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
			if #aCover > 0 or EffectManagerFFd20.hasEffect(rDefender, "SCOVER", rAttacker) then
				nBonusSituational = nBonusSituational + 8 - nCover;
			elseif nCover < 4 then
				aCover = EffectManagerFFd20.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
				if #aCover > 0 or EffectManagerFFd20.hasEffect(rDefender, "COVER", rAttacker) then
					nBonusSituational = nBonusSituational + 4 - nCover;
				elseif nCover < 2 then
					aCover = EffectManagerFFd20.getEffectsByType(rDefender, "PCOVER", aAttackFilter, rAttacker);
					if #aCover > 0 or EffectManagerFFd20.hasEffect(rDefender, "PCOVER", rAttacker) then
						nBonusSituational = nBonusSituational + 2 - nCover;
					end
				end
			end
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - CONCEALMENT
		local aConceal = EffectManagerFFd20.getEffectsByType(rDefender, "TCONC", aAttackFilter, rAttacker);
		if #aConceal > 0 or EffectManagerFFd20.hasEffect(rDefender, "TCONC", rAttacker) or bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		else
			aConceal = EffectManagerFFd20.getEffectsByType(rDefender, "CONC", aAttackFilter, rAttacker);
			if #aConceal > 0 or EffectManagerFFd20.hasEffect(rDefender, "CONC", rAttacker) or bConceal then
				nMissChance = 20;
			end
		end

		nAttackMiss = EffectManagerFFd20.getEffectsBonus(rAttacker, "MISS", true);
		if nAttackMiss > 0 then
			nMissChance = nAttackMiss;
		end
		
		-- ADD IN EFFECT MODIFIERS
		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
	
	-- NO DEFENDER SPECIFIED, SO JUST LOOK AT THE ATTACK ROLL MODIFIERS
	else
		if bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		elseif bConceal then
			nMissChance = 20;
		end
	end
	
	-- Return the final defense value
	return nDefense, 0, nDefenseEffectMod, nMissChance;
end
