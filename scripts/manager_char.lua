-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemDelete);

	initWeaponIDTracking();

	if Session.IsHost then
		CharInventoryManager.enableInventoryUpdates();
		CharInventoryManager.enableSimpleLocationHandling();

		CharInventoryManager.registerFieldUpdateCallback("carried", CharManager.onCharInventoryArmorCalc);

		CharInventoryManager.registerFieldUpdateCallback("isidentified", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("bonus", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("ac", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("maxstatbonus", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("checkpenalty", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("spellfailure", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("speed20", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("speed30", CharManager.onCharInventoryArmorCalcIfCarried);
	end
end

function onCharInventoryArmorCalcIfCarried(nodeItem, sField)
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		CharManager.onCharInventoryArmorCalc(nodeItem, sField);
	end
end
function onCharInventoryArmorCalc(nodeItem, sField)
	if ItemManager.isArmor(nodeItem) then
		local nodeChar = DB.getChild(nodeItem, "...");
		CharManager.calcItemArmorClass(nodeChar);
	end
end

function outputUserMessage(sResource, ...)
	local sFormat = Interface.getString(sResource);
	local sMsg = string.format(sFormat, ...);
	ChatManager.SystemMessage(sMsg);
end

--
-- ITEM/FOCUS MANAGEMENT
--

function onCharItemAdd(nodeItem)
	DB.setValue(nodeItem, "carried", "number", 1);
	
	addToArmorDB(nodeItem);
	addToWeaponDB(nodeItem);
end

function onCharItemDelete(nodeItem)
	removeFromArmorDB(nodeItem);
	removeFromWeaponDB(nodeItem);
end

--
-- ARMOR MANAGEMENT
-- 

function removeFromArmorDB(nodeItem)
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return;
	end
	
	-- If this armor was worn, recalculate AC
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		DB.setValue(nodeItem, "carried", "number", 1);
	end
end

function addToArmorDB(nodeItem)
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return;
	end
	local bIsShield = ItemManager.isShield(nodeItem);
	
	-- Determine whether to auto-equip armor
	local bArmorAllowed = true;
	local bShieldAllowed = true;
	local nodeChar = DB.getChild(nodeItem, "...");
	if (bArmorAllowed and not bIsShield) or (bShieldAllowed and bIsShield) then
		local bArmorEquipped = false;
		local bShieldEquipped = false;
		for _,v in ipairs(DB.getChildList(nodeItem, "..")) do
			if DB.getValue(v, "carried", 0) == 2 then
				if ItemManager.isArmor(v) then
					if ItemManager.isShield(v) then
						bShieldEquipped = true;
					else
						bArmorEquipped = true;
					end
				end
			end
		end
		if bShieldAllowed and bIsShield and not bShieldEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		elseif bArmorAllowed and not bIsShield and not bArmorEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		end
	end
end

function calcItemArmorClass(nodeChar)
	local nMainArmorTotal = 0;
	local nMainShieldTotal = 0;
	local nMainMaxStatBonus = 0;
	local nMainCheckPenalty = 0;
	local nMainSpellFailure = 0;
	local nMainSpeed30 = 0;
	local nMainSpeed20 = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local bID = LibraryData.getIDState("item", vNode, true);
				
				if ItemManager.isShield(vNode) then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0);
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0);
					end
				else
					if bID then
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0);
					else
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, "ac", 0);
					end
					
					local nItemSpeed30 = DB.getValue(vNode, "speed30", 0);
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30);
						else
							nMainSpeed30 = nItemSpeed30;
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, "speed20", 0);
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20);
						else
							nMainSpeed20 = nItemSpeed20;
						end
					end
				end
					
				local nMaxStatBonus = DB.getValue(vNode, "maxstatbonus", 0);
				if nMaxStatBonus > 0 then
					if nMainMaxStatBonus > 0 then nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus); 
					else nMainMaxStatBonus = nMaxStatBonus;
					end
				end
				
				local nCheckPenalty = DB.getValue(vNode, "checkpenalty", 0);
				if nCheckPenalty < 0 then
					nMainCheckPenalty = nMainCheckPenalty + nCheckPenalty;
				end
				
				local nSpellFailure = DB.getValue(vNode, "spellfailure", 0);
				if nSpellFailure > 0 then
					nMainSpellFailure = nMainSpellFailure + nSpellFailure;
				end
			end
		end
	end
	
	DB.setValue(nodeChar, "ac.sources.armor", "number", nMainArmorTotal);
	DB.setValue(nodeChar, "ac.sources.shield", "number", nMainShieldTotal);
	if nMainMaxStatBonus > 0 then
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 1);
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonus", "number", nMainMaxStatBonus);
	else
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 0);
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonus", "number", 0);
	end
	DB.setValue(nodeChar, "encumbrance.armorcheckpenalty", "number", nMainCheckPenalty);
	DB.setValue(nodeChar, "encumbrance.spellfailure", "number", nMainSpellFailure);
	
	local bApplySpeedPenalty = true;
	if hasTrait(nodeChar, "Slow and Steady") then
		bApplySpeedPenalty = false;
	end

	local nSpeedBase = DB.getValue(nodeChar, "speed.base", 0);
	local nSpeedArmor = 0;
	if bApplySpeedPenalty then
		if (nSpeedBase >= 30) and (nMainSpeed30 > 0) then
			nSpeedArmor = nMainSpeed30 - 30;
		elseif (nSpeedBase < 30) and (nMainSpeed20 > 0) then
			nSpeedArmor = nMainSpeed20 - 20;
		end
	end
	DB.setValue(nodeChar, "speed.armor", "number", nSpeedArmor);
	local nSpeedTotal = nSpeedBase + nSpeedArmor + DB.getValue(nodeChar, "speed.misc", 0) + DB.getValue(nodeChar, "speed.temporary", 0);
	DB.setValue(nodeChar, "speed.final", "number", nSpeedTotal);
end

function getSpellFailure(nodeChar)
	local nArmorPenalty = DB.getValue(nodeChar, "encumbrance.armormaxstatbonusactive", 0);
	if nArmorPenalty == 1 then
		local nSpellFailure = DB.getValue(nodeChar, "encumbrance.spellfailure", 0);
		return nSpellFailure;
	end
	return 0;
end
--
-- WEAPON MANAGEMENT
--

function removeFromWeaponDB(nodeItem)
	if not nodeItem then
		return false;
	end
	
	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local sItemNode = DB.getPath(nodeItem);
	local sItemNode2 = "....inventorylist." .. DB.getName(nodeItem);
	local bFound = false;
	for _,v in ipairs(DB.getChildList(nodeItem, "...weaponlist")) do
		local sClass, sRecord = DB.getValue(v, "shortcut", "", "");
		if sRecord == sItemNode or sRecord == sItemNode2 then
			DB.deleteNode(v);
			bFound = true;
		end
	end

	return bFound;
end

function addToWeaponDB(nodeItem)
	-- Parameter validation
	if DB.getValue(nodeItem, "type", "") ~= "Weapon" then
		return;
	end
	
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(nodeItem, "...");
	local nodeWeapons = DB.createChild(nodeChar, "weaponlist");
	if not nodeWeapons then
		return nil;
	end
	
	-- Set new weapons as equipped
	DB.setValue(nodeItem, "carried", "number", 2);

	-- Determine identification
	local nItemID = 0;
	if LibraryData.getIDState("item", nodeItem, true) then
		nItemID = 1;
	end
	
	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end
	local nBonus = 0;
	if nItemID == 1 then
		nBonus = DB.getValue(nodeItem, "bonus", 0);
	end

	local nRange = DB.getValue(nodeItem, "range", 0);
	local nRadius = tonumber(string.match(DB.getValue(nodeItem, "burstradius", ""), "(%d+)") or 0);
	local nReflex = DB.getValue(nodeItem, "reflexdc", 0);
	local nAtkBonus = nBonus;

	local sType = string.lower(DB.getValue(nodeItem, "subtype", ""));
	local bMelee = true;
	local bRanged = false;
	local bGunArms = false;
	local bExplosives = false;
	if string.find(sType, "melee") then
		bMelee = true;
		if nRange > 0 then
			bRanged = true;
		end
	elseif string.find(sType, "ranged") then
		bMelee = false;
		bRanged = true;
	elseif sType == "explosives" then
		bMelee = false;
		bRanged = true;
		bExplosives = true;
	end
	if sType == "gun arms" then
		bGunArms = true;
	end
	
	local bDouble = false;
	local sProps = DB.getValue(nodeItem, "properties", "");
	local sPropsLower = sProps:lower();
	if sPropsLower:match("double") then
		bDouble = true;
	end
	if nAtkBonus == 0 and (sPropsLower:match("masterwork") or sPropsLower:match("adamantine")) then
		nAtkBonus = 1;
	end
	local bTwoWeaponFight = false;
	if hasFeat(nodeChar, "Two-Weapon Fighting") then
		bTwoWeaponFight = true;
	end
	
	local aDamage = {};
	local sDamage = DB.getValue(nodeItem, "damage", "") .. ";" .. DB.getValue(nodeItem, "gdamage", "");
	local aDamageSplit = StringManager.split(sDamage, "/;");

	for _,vDamage in ipairs(aDamageSplit) do
		local diceDamage, nDamage = StringManager.convertStringToDice(vDamage);
		table.insert(aDamage, { dice = diceDamage, mod = nDamage });
	end
	
	local sDamageType = DB.getValue(nodeItem, "damagetype", "") .. ";" .. DB.getValue(nodeItem, "gdamagetype", "");
	local aDamageTypeSplit = StringManager.split(sDamageType:lower(), "/;");
	
	local aCritThreshold = { 20 };
	local aCritMult = { 2 };
	local sCritical = DB.getValue(nodeItem, "critical", "") .. ";" .. DB.getValue(nodeItem, "gcritical", "");

	-- Handle potential empty critical range
	if bGunArms then
		if string.match(sCritical, ";x") then
			sCritical = sCritical:gsub(";x", ";20-20/x");
		end
		if string.match(sCritical, "^x") then
			sCritical = "20-20/" .. sCritical;
		end
	end

	local aCrit = StringManager.split(sCritical, "/;");
	local nThresholdIndex = 1;
	local nMultIndex = 1;
	for _,sCrit in ipairs(aCrit) do
		local sCritThreshold = string.match(sCrit, "(%d+)[%-*]20");
		if sCritThreshold then
			aCritThreshold[nThresholdIndex] = tonumber(sCritThreshold) or 20;
			nThresholdIndex = nThresholdIndex + 1;
		end

		local sCritMult = string.match(sCrit, "x(%d)");
		if sCritMult then
			aCritMult[nMultIndex] = tonumber(sCritMult) or 2;
			nMultIndex = nMultIndex + 1;
		end
	end

	-- Get some character data to pre-fill weapon info
	local nBAB = DB.getValue(nodeChar, "attackbonus.base", 0);
	local nAttacks = math.floor((nBAB - 1) / 5) + 1;
	if nAttacks < 1 then
		nAttacks = 1;
	end
	local sMeleeAttackStat = DB.getValue(nodeChar, "attackbonus.melee.ability", "");
	local sRangedAttackStat = DB.getValue(nodeChar, "attackbonus.ranged.ability", "");

	-- Fill the weapon loop
	local aWeaponNumber = {};
	if bMelee or bRanged then
		table.insert(aWeaponNumber, 1);
		if bDouble and not bGunArms then
			table.insert(aWeaponNumber, 2);
		elseif bGunArms and not bDouble then
			table.insert(aWeaponNumber, 2);
		elseif bDouble and bGunArms then
			table.insert(aWeaponNumber, 2)
			table.insert(aWeaponNumber, 3);
		end
	end

	for _,v in pairs(aWeaponNumber) do
		local nodeWeapon = DB.createChild(nodeWeapons);
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. DB.getName(nodeItem));

			if bMelee then
				DB.setValue(nodeWeapon, "type", "number", 0);
				DB.setValue(nodeWeapon, "attackstat", "string", sMeleeAttackStat);
			elseif bRanged then
				DB.setValue(nodeWeapon, "type", "number", 1);
				DB.setValue(nodeWeapon, "attackstat", "string", sRangedAttackStat);
				DB.setValue(nodeWeapon, "rangeincrement", "number", nRange);
			end
			if bExplosives then
				DB.setValue(nodeWeapon, "subtype", "string", "explosive");
				DB.setValue(nodeWeapon, "radius", "number", nRadius);
				DB.setValue(nodeWeapon, "reflexdc", "number", nReflex);
			end
			DB.setValue(nodeWeapon, "properties", "string", sProps);
			
			DB.setValue(nodeWeapon, "attacks", "number", nAttacks);
			DB.setValue(nodeWeapon, "bonus", "number", nAtkBonus);

			DB.setValue(nodeWeapon, "critatkrange", "number", aCritThreshold[v]);

			if v == 1 then
				if bDouble then
					DB.setValue(nodeWeapon, "name", "string", sName .. " (D1)");
					if bTwoWeaponFight then
						DB.setValue(nodeWeapon, "bonus", "number", nAtkBonus - 2);
					else
						DB.setValue(nodeWeapon, "bonus", "number", nAtkBonus - 4);
					end
				else
					DB.setValue(nodeWeapon, "name", "string", sName .. "");
				end
			elseif v == 2 then
				if bDouble then
					DB.setValue(nodeWeapon, "name", "string", sName .. " (D2)");
					DB.setValue(nodeWeapon, "critatkrange", "number", aCritThreshold[v-1]);

					if bTwoWeaponFight then
						DB.setValue(nodeWeapon, "bonus", "number", nAtkBonus - 2);
					else
						DB.setValue(nodeWeapon, "bonus", "number", nAtkBonus - 8);
					end
				elseif bGunArms and not bDouble then
					DB.setValue(nodeWeapon, "name", "string", sName .. " (Firearm)");
					DB.setValue(nodeWeapon, "type", "number", 1);
					DB.setValue(nodeWeapon, "attackstat", "string", sRangedAttackStat);
					DB.setValue(nodeWeapon, "rangeincrement", "number", nRange);
				end
			elseif v == 3 then
				DB.setValue(nodeWeapon, "critatkrange", "number", aCritThreshold[v-1]);
				DB.setValue(nodeWeapon, "name", "string", sName .. " (Firearm)");
				DB.setValue(nodeWeapon, "type", "number", 1);
				DB.setValue(nodeWeapon, "attackstat", "string", sRangedAttackStat);
				DB.setValue(nodeWeapon, "rangeincrement", "number", nRange);
			end

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				local nodeDmg = DB.createChild(nodeDmgList);
				if nodeDmg then
					if aDamage[v] then
						DB.setValue(nodeDmg, "dice", "dice", aDamage[v].dice);
						DB.setValue(nodeDmg, "bonus", "number", nBonus + aDamage[v].mod);
					else
						DB.setValue(nodeDmg, "bonus", "number", nBonus);
					end

					if bMelee then
						DB.setValue(nodeDmg, "stat", "string", "strength");
						if string.find(sType, "two%-handed") then
							DB.setValue(nodeDmg, "statmult", "number", 1.5);
						end
					elseif bRanged then
						if sName == "Sling" then
							DB.setValue(nodeDmg, "stat", "string", "strength");
						elseif sName == "Shortbow" or sName == "Longbow" or sName == "Shortbow, composite" or sName == "Longbow, composite" then
							DB.setValue(nodeDmg, "stat", "string", "");
						elseif string.find(string.lower(sName), "crossbow") or sName == "Net" or sName == "Blowgun" then
							DB.setValue(nodeDmg, "stat", "string", "");
						else
							DB.setValue(nodeDmg, "stat", "string", "strength");
						end
					end

					DB.setValue(nodeDmg, "critmult", "number", aCritMult[v]);
					DB.setValue(nodeDmg, "type", "string", aDamageTypeSplit[v]);

					if v == 2 then
						if bDouble then
							DB.setValue(nodeDmg, "type", "string", aDamageTypeSplit[v-1]);
							DB.setValue(nodeDmg, "critmult", "number", aCritMult[v-1]);
						elseif bGunArms and not bDouble then
							DB.setValue(nodeDmg, "stat", "string", "");
						end
					elseif v == 3 then
						DB.setValue(nodeDmg, "stat", "string", "");
						DB.setValue(nodeDmg, "critmult", "number", aCritMult[v-1]);
						DB.setValue(nodeDmg, "type", "string", aDamageTypeSplit[v-1]);
					end
				end
			end
		end
	end
end

function initWeaponIDTracking()
	DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemIDChanged);
end

function onItemIDChanged(nodeItemID)
	local nodeItem = DB.getChild(nodeItemID, "..");
	local nodeChar = DB.getChild(nodeItemID, "....");

	local sPath = DB.getPath(nodeItem);
	for _,vWeapon in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
		local _,sRecord = DB.getValue(vWeapon, "shortcut", "", "");
		if sRecord == sPath then
			checkWeaponIDChange(vWeapon);
		end
	end
end

function checkWeaponIDChange(nodeWeapon)
	local _,sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	if sRecord == "" then
		return;
	end
	local nodeItem = DB.findNode(sRecord);
	if not nodeItem then
		return;
	end
	
	local bItemID = LibraryData.getIDState("item", DB.findNode(sRecord), true);
	local bWeaponID = (DB.getValue(nodeWeapon, "isidentified", 1) == 1);
	if bItemID == bWeaponID then
		return;
	end
	
	local sOldName = DB.getValue(nodeWeapon, "name", "");
	local aOldParens = {};
	for w in sOldName:gmatch("%([^%)]+%)") do
		table.insert(aOldParens, w);
	end
	local sOldSuffix = nil;
	if #aOldParens > 0 then
		sOldSuffix = aOldParens[#aOldParens];
	end
	
	local sName;
	if bItemID then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end
	if sOldSuffix then
		sName = sName .. " " .. sOldSuffix;
	end
	DB.setValue(nodeWeapon, "name", "string", sName);
	
	local nBonus = 0;
	if bItemID then
		DB.setValue(nodeWeapon, "bonus", "number", DB.getValue(nodeWeapon, "bonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		end
	else
		DB.setValue(nodeWeapon, "bonus", "number", DB.getValue(nodeWeapon, "bonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		end
	end
	
	if bItemID then
		DB.setValue(nodeWeapon, "isidentified", "number", 1);
	else
		DB.setValue(nodeWeapon, "isidentified", "number", 0);
	end
end

function getWeaponAttackRollStructures(nodeWeapon, nAttack)
	if not nodeWeapon then
		return;
	end
	
	local nodeChar = DB.getChild(nodeWeapon, "...");
	local rActor = ActorManager.resolveActor(nodeChar);

	local rAttack = {};
	rAttack.type = "attack";
	rAttack.label = DB.getValue(nodeWeapon, "name", "");
	local nType = DB.getValue(nodeWeapon, "type", 0);
	if nType == 2 then
		rAttack.range = "M";
		rAttack.cm = true;
	elseif nType == 1 then
		rAttack.range = "R";
	else
		rAttack.range = "M";
	end
	rAttack.crit = DB.getValue(nodeWeapon, "critatkrange", 20);
	rAttack.stat = DB.getValue(nodeWeapon, "attackstat", "");
	if rAttack.stat == "" then
		if rAttack.range == "M" then
			if rAttack.cm then
				rAttack.stat = DB.getValue(nodeChar, "attackbonus.cmb.ability", "");
				if rAttack.stat == "" then
					rAttack.stat = "strength";
				end
			else
				rAttack.stat = DB.getValue(nodeChar, "attackbonus.melee.ability", "");
				if rAttack.stat == "" then
					rAttack.stat = "strength";
				end
			end
		else
			rAttack.stat = DB.getValue(nodeChar, "attackbonus.ranged.ability", "");
			if rAttack.stat == "" then
				rAttack.stat = "dexterity";
			end
		end
	end
	
	local sProp = DB.getValue(nodeWeapon, "properties", ""):lower();
	if sProp:match("touch") then
		rAttack.touch = true;
	end
	
	return rActor, rAttack;
end

function getWeaponDamageRollStructures(nodeWeapon)
	local nodeChar = DB.getChild(nodeWeapon, "...");
	local rActor = ActorManager.resolveActor(nodeChar);

	local bRanged = (DB.getValue(nodeWeapon, "type", 0) == 1);

	local rDamage = {};
	rDamage.type = "damage";
	rDamage.label = DB.getValue(nodeWeapon, "name", "");
	if bRanged then
		rDamage.range = "R";
	else
		rDamage.range = "M";
	end
	
	rDamage.clauses = {};
	local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
	for _,v in ipairs(aDamageNodes) do
		local sDmgType = DB.getValue(v, "type", "");
		local aDmgDice = DB.getValue(v, "dice", {});
		local nDmgMod = DB.getValue(v, "bonus", 0);
		local nDmgMult = DB.getValue(v, "critmult", 2);

		local nMult = 1;
		local nMax = 0;
		local sDmgAbility = DB.getValue(v, "stat", "");
		if sDmgAbility ~= "" then
			nMult = DB.getValue(v, "statmult", 1);
			nMax = DB.getValue(v, "statmax", 0);
			local nAbilityBonus = ActorManagerFFd20.getAbilityBonus(rActor, sDmgAbility);
			if nMax > 0 then
				nAbilityBonus = math.min(nAbilityBonus, nMax);
			end
			if nAbilityBonus > 0 and nMult ~= 1 then
				nAbilityBonus = math.floor(nMult * nAbilityBonus);
			end
			nDmgMod = nDmgMod + nAbilityBonus;
		end
		
		table.insert(rDamage.clauses, 
				{ 
					dice = aDmgDice, 
					modifier = nDmgMod, 
					mult = nDmgMult,
					stat = sDmgAbility, 
					statmax = nMax,
					statmult = nMult,
					dmgtype = sDmgType, 
				});
	end
	
	return rActor, rDamage;
end

function onActionDrop(draginfo, nodeChar)
	if draginfo.isType("spellmove") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("spelldescwithlevel") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "spelldesc" then
			ChatManager.Message(Interface.getString("spell_error_dropclasslevelmissing"));
			return true;
		elseif LibraryData.isRecordDisplayClass("item", sClass) and ItemManager.isWeapon(nodeSource) then
			return ItemManager.handleAnyDrop(nodeChar, draginfo);
		end
	end
end

--
-- ACTIONS
--

function rest(nodeChar)
	resetHealth(nodeChar);
	SpellManager.resetMP(nodeChar);
end

function resetHealth(nodeChar)
	-- Clear temporary hit points
	DB.setValue(nodeChar, "hp.temporary", "number", 0);
	
	-- Heal hit points equal to character level
	local nLevel = DB.getValue(nodeChar, "level", 0);
	
	local nWounds = DB.getValue(nodeChar, "hp.wounds", 0);
	nWounds = nWounds - nLevel;
	if nWounds < 0 then
		nWounds = 0;
	end
	DB.setValue(nodeChar, "hp.wounds", "number", nWounds);
	
	local nNonlethal = DB.getValue(nodeChar, "hp.nonlethal", 0);
	nNonlethal = nNonlethal - (nLevel * 8);
	if nNonlethal < 0 then
		nNonlethal = 0;
	end
	DB.setValue(nodeChar, "hp.nonlethal", "number", nNonlethal);
	
	-- Heal ability damage
	local nAbilityDamage;
	for _,vAbility in pairs(DataCommon.abilities) do
		nAbilityDamage = DB.getValue(nodeChar, "abilities." .. vAbility .. ".damage", 0);
		if nAbilityDamage > 0 then
			DB.setValue(nodeChar, "abilities." .. vAbility .. ".damage", "number", nAbilityDamage - 1);
		end
	end
	
	-- Remove Stable effect if not dead/dying
	local rActor = ActorManager.resolveActor(nodeChar);
	if not ActorHealthManager.isDyingOrDead(rActor) then
		EffectManager.removeCondition(rActor, "Stable");
	end
end

--
-- DATA ACCESS
--

function getSkillValue(rActor, sSkill, sSubSkill)
	local nValue = 0;
	local bUntrained = false;

	local rSkill = DataCommon.skilldata[sSkill];
	local bTrainedOnly = (rSkill and rSkill.trainedonly);
	
	local nodeChar = ActorManager.getCreatureNode(rActor);
	if nodeChar then
		local sSkillLower = sSkill:lower();
		local sSubLower = nil;
		if sSubSkill then
			sSubLower = sSubSkill:lower();
		end
		
		local nodeSkill = nil;
		for _,vNode in ipairs(DB.getChildList(nodeChar, "skilllist")) do
			local sNameLower = DB.getValue(vNode, "label", ""):lower();

			-- Capture exact matches
			if sNameLower == sSkillLower then
				if sSubLower then
					local sSubName = DB.getValue(vNode, "sublabel", ""):lower();
					if (sSubName == sSubLower) or (sSubLower == "planes" and sSubName == "the planes") then
						nodeSkill = vNode;
						break;
					end
				else
					nodeSkill = vNode;
					break;
				end
			
			-- And partial matches
			elseif sNameLower:sub(1, #sSkillLower) == sSkillLower then
				if sSubLower then
					local sSubName = sNameLower:sub(#sSkillLower + 1):match("%w[%w%s]*%w");
					if sSubName and ((sSubName == sSubLower) or (sSubLower == "planes" and sSubName == "the planes")) then
						nodeSkill = vNode;
						break;
					end
				end
			end
		end
		
		if nodeSkill then
			local nRanks = DB.getValue(nodeSkill, "ranks", 0);
			local nAbility = DB.getValue(nodeSkill, "stat", 0);
			local nMisc = DB.getValue(nodeSkill, "misc", 0);
			
			nValue = math.floor(nRanks) + nAbility + nMisc;

			if (nRanks > 0) then
				local nState = DB.getValue(nodeSkill, "state", 0);
				if nState == 1 then
					nValue = nValue + 3;
				end
			end
			
			local nACMult = DB.getValue(nodeSkill, "armorcheckmultiplier", 0);
			if nACMult ~= 0 then
				local bApplyArmorMod = DB.getValue(nodeSkill, "...encumbrance.armormaxstatbonusactive", 0);
				if (bApplyArmorMod ~= 0) then
					local nACPenalty = DB.getValue(nodeSkill, "...encumbrance.armorcheckpenalty", 0);
					nValue = nValue + (nACMult * nACPenalty);
				end
			end

			if bTrainedOnly then
				if nRanks == 0 then
					bUntrained = true;
				end
			end
		else
			if rSkill then
				if rSkill.stat then
					nValue = nValue + ActorManagerFFd20.getAbilityBonus(rActor, rSkill.stat);
				end
				
				if rSkill.armorcheckmultiplier then
					local bApplyArmorMod = DB.getValue(nodeChar, "encumbrance.armormaxstatbonusactive", 0);
					if (bApplyArmorMod ~= 0) then
						local nArmorCheckPenalty = DB.getValue(nodeChar, "encumbrance.armorcheckpenalty", 0);
						nValue = nValue + (nArmorCheckPenalty * (tonumber(rSkill.armorcheckmultiplier) or 0));
					end
				end
			end
			bUntrained = bTrainedOnly;
		end
	else
		bUntrained = bTrainedOnly;
	end
	
	return nValue, bUntrained;
end

function getBaseAttackRollStructures(sAttack, nodeChar)
	local rCreature = ActorManager.resolveActor(nodeChar);

	local rAttack = {};
	rAttack.type = "attack";
	rAttack.label = sAttack;

	if string.match(string.lower(sAttack), "melee") then
		rAttack.range = "M";
		rAttack.modifier = DB.getValue(nodeChar, "attackbonus.melee.total", 0);
		rAttack.stat = DB.getValue(nodeChar, "attackbonus.melee.ability", "");
		if rAttack.stat == "" then
			rAttack.stat = "strength";
		end
	else
		rAttack.range = "R";
		rAttack.modifier = DB.getValue(nodeChar, "attackbonus.ranged.total", 0);
		rAttack.stat = DB.getValue(nodeChar, "attackbonus.ranged.ability", "");
		if rAttack.stat == "" then
			rAttack.stat = "dexterity";
		end
	end
	
	return rCreature, rAttack;
end

function getCMBRollStructures(rActor, sAttack)
	local rAttack = {};
	rAttack.type = "attack";
	rAttack.label = sAttack;
	rAttack.range = "M";
	
	local nodeChar = ActorManager.getCreatureNode(rActor);
	if nodeChar then
		rAttack.modifier = DB.getValue(nodeChar, "attackbonus.cmb.total", 0);
		rAttack.stat = DB.getValue(nodeChar, "attackbonus.cmb.ability", "");
	end
	if rAttack.stat == "" then
		rAttack.stat = "strength";
	end

	return rAttack;
end

function updateSkillPoints(nodeChar)
	local nSpentTotal = 0;
	
	local nSpent;
	for _,vNode in ipairs(DB.getChildList(nodeChar, "skilllist")) do
		nSpent = DB.getValue(vNode, "ranks", 0);
		if nSpent > 0 then			
			nSpentTotal = nSpentTotal + nSpent;
		end
	end

	DB.setValue(nodeChar, "skillpoints.spent", "number", nSpentTotal);
end

function hasFeat(nodeChar, sFeat)
	if not sFeat then
		return false;
	end
	local sLowerFeat = StringManager.trim(sFeat:lower());
	for _,vNode in ipairs(DB.getChildList(nodeChar, "fttlist")) do
		if StringManager.trim(DB.getValue(vNode, "name", ""):lower()) == sLowerFeat then
			return true;
		end
	end
	return false;
end

function hasTrait(nodeChar, sTrait)
	if not sTrait then
		return false;
	end
	local sLowerTrait = StringManager.trim(string.lower(sTrait));
	
	for _,vNode in ipairs(DB.getChildList(nodeChar, "traitlist")) do
		if StringManager.trim(DB.getValue(vNode, "name", ""):lower()) == sLowerTrait then
			return true;
		end
	end
	return false;
end

--
-- CHARACTER SHEET DROPS
--

function addInfoDB(nodeChar, sClass, sRecord, nodeTargetList)
	if not nodeChar then
		return false;
	end
	
	if sClass == "referencerace" or sClass == "referenceheritage" then
		CharRaceManager.addRace(nodeChar, sClass, sRecord);
	elseif sClass == "referenceracialtrait" or sClass == "referenceheritagetrait" or sClass == "referencealternate" then
		CharRaceManager.addRacialTrait(nodeChar, sClass, sRecord);
	elseif sClass == "referenceclass" then
		CharClassManager.addClass(nodeChar, sClass, sRecord);
	elseif sClass == "referenceclassability" then
		CharClassManager.addClassFeature(nodeChar, sClass, sRecord, nodeTargetList);
	elseif sClass == "referencefeat" or sClass == "referencetrait" or sClass == "referencetalent" then
		addFeat(nodeChar, sRecord, nodeTargetList);
	elseif sClass == "referencedeity" then
		addDeity(nodeChar, sClass, sRecord);
	elseif sClass == "spelldesc" then
		addSpell(nodeChar, sClass, sRecord, nodeTargetList);
	else
		return false;
	end
	
	return true;
end

function resolveRefNode(sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		local sRecordSansModule = StringManager.split(sRecord, "@")[1];
		nodeSource = DB.findNode(sRecordSansModule .. "@*");
		if not nodeSource then
			ChatManager.SystemMessage(Interface.getString("char_error_missingrecord"));
		end
	end
	return nodeSource;
end

function getSkillNode(nodeChar, sSkill, sSpecialty)
	if not sSkill then
		return nil;
	end

	local nodeSkill = nil;
	for _,vSkill in ipairs(DB.getChildList(nodeChar, "skilllist")) do
		if DB.getValue(vSkill, "label", "") == sSkill then
			if sSpecialty then
				if DB.getValue(vSkill, "sublabel", "") == sSpecialty then
					nodeSkill = vSkill;
				end
			else
				nodeSkill = vSkill;
			end
		end
	end
	if not nodeSkill then
		local t = DataCommon.skilldata[sSkill];
		if t then
			local nodeSkillList = DB.createChild(nodeChar, "skilllist");
			nodeSkill = DB.createChild(nodeSkillList);
			
			DB.setValue(nodeSkill, "label", "string", sSkill);
			DB.setValue(nodeSkill, "statname", "string", t.stat or "");
			
			if t.sublabeling and sSpecialty then
				DB.setValue(nodeSkill, "sublabel", "string", sSpecialty);
			end
		end
	end
	return nodeSkill;
end

function getClassNode(nodeChar, sClassName)
	if not sClassName then
		return nil;
	end

	local nodeClass = nil;
	for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		if DB.getValue(vClass, "name", "") == sClassName then
			return vClass;
		end
	end
	return nil;
end

function addSpell(nodeChar, sClass, sRecord, nodeTargetList)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return false;
	end

	if not nodeTargetList then
		nodeTargetList = nodeChar.createChild("blulist");
		if not nodeTargetList then
			return false;
		end
	end
	local nodeEntry = DB.createChild(nodeTargetList);
	DB.copyNode(nodeSource, nodeEntry);
	DB.setValue(nodeEntry, "source", "string", DB.getValue(nodeSource, "...name", ""));
	DB.setValue(nodeEntry, "locked", "number", 1);
	return true;
end

function addDeity(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	local sDeity = DB.getValue(nodeSource, "name", "");

	DB.setValue(nodeChar, "deity", "string", sDeity);
	DB.setValue(nodeChar, "deitylink", "windowreference", sClass, nodeSource.getPath());
end

function helperBuildAddStructure(nodeChar, sClass, sRecord)
	if not nodeChar or ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local rAdd = { };
	rAdd.nodeSource = DB.findNode(sRecord);
	if not rAdd.nodeSource then
		return nil;
	end

	rAdd.sSourceClass = sClass;
	rAdd.sSourceName = StringManager.trim(DB.getValue(rAdd.nodeSource, "name", ""));
	rAdd.nodeChar = nodeChar;
	rAdd.sCharName = StringManager.trim(DB.getValue(nodeChar, "name", ""));

	rAdd.sSourceType = StringManager.simplify(rAdd.sSourceName);
	if rAdd.sSourceType == "" then
		rAdd.sSourceType = rAdd.nodeSource.getName();
	end

	return rAdd;
end

function addLanguage(nodeChar, sLanguage)
	local nodeList = DB.createChild(nodeChar, "languagelist");
	if not nodeList then
		return false;
	end
	
	if sLanguage ~= "Choice" then
		for _,v in ipairs(DB.getChildList(nodeList)) do
			if DB.getValue(v, "name", "") == sLanguage then
				return false;
			end
		end
	end

	local vNew = DB.createChild(nodeList);
	DB.setValue(vNew, "name", "string", sLanguage);

	local sFormat = Interface.getString("char_message_languageadd");
	local sMsg = string.format(sFormat, DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	return true;
end

function addSkillBonus(nodeChar, sSkill, nBonus, sSpecialty)
	local nodeSkill = getSkillNode(nodeChar, sSkill, sSpecialty);
	if nodeSkill then
		DB.setValue(nodeSkill, "misc", "number", DB.getValue(nodeSkill, "misc", 0) + nBonus);
		
		if sSpecialty then
			sSkill = sSkill .. " (" .. sSpecialty .. ")";
		end
		local sFormat = Interface.getString("char_message_skillbonusadd");
		local sMsg = string.format(sFormat, nBonus, sSkill, DB.getValue(nodeChar, "name", ""));
		ChatManager.SystemMessage(sMsg);
	end
end

function addSaveBonus(nodeChar, sSave, sBonusType, nBonus)
	if not DataCommon.save_ltos[sSave] or nBonus <= 0 or not StringManager.contains({ "base", "misc" }, sBonusType) then
		return;
	end
	
	DB.setValue(nodeChar, "saves." .. sSave .. "." .. sBonusType, "number", DB.getValue(nodeChar, "saves." .. sSave .. "." .. sBonusType, 0) + nBonus);
	
	local sFormat = Interface.getString("char_message_savebonusadd");
	local sMsg = string.format(sFormat, nBonus, StringManager.capitalize(sSave), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
end

function parseFeatureName(s)
	local nMult = 1;
	local sMult = s:match("%s+%((%d+)x%)$");
	if sMult then
		s = s:gsub("%s+%(%d+x%)$", "");
		nMult = tonumber(sMult) or 1;
	end
	
	local sSuffix = s:match("%s+%(?%+?%d+%)?$"); -- (+#) or +# or #
	if sSuffix then
		s = s:gsub("%s+%(?%+?%d+%)?$", "");
	else
		sSuffix = s:match("%s+%(?%d+/%-%)?$"); -- #/- or (#/-)
		if sSuffix then
			s = s:gsub("%s+%(?%d+/%-%)?$", "");
		else
			sSuffix = s:match("%s+%(?%+?%d+d6%)?$"); -- +#d6 or #d6
			if sSuffix then
				s = s:gsub("%s+%(?%+?%d+d6%)?$", "");
			else
				sSuffix = s:match("%s+%(?%d+/day%)?$"); -- #/day
				if sSuffix then
					s = s:gsub("%s+%(?%d+/day%)?$", "");
				else
					sSuffix = s:match("%s+%(?%d+ ft%.?%)?$"); -- # ft. or # ft
					if sSuffix then
						s = s:gsub("%s+%(?%d+ ft%.?%)?$", "");
					end
				end
			end
		end
	end
	
	return s:lower(), nMult, sSuffix;
end

function handleDuplicateFeatures(nodeChar, nodeFeature, sFeatureType, nodeTargetList)
	local sClassName = StringManager.strip(DB.getValue(nodeFeature, "...name", ""));
	local sFeatureStrip = StringManager.strip(DB.getValue(nodeFeature, "name", ""));
	
	local sFeatureStripLower, nFeatureMult, sFeatureSuffix = parseFeatureName(sFeatureStrip);
	local nFeatureSuffix = 1;
	if sFeatureSuffix then
		nFeatureSuffix = tonumber(sFeatureSuffix:match("%d+")) or 1;
	end

	if not nodeTargetList then
		nodeTargetList = DB.createChild(nodeChar, "specialabilitylist");
		if not nodeTargetList then
			return false;
		end
	end
	
	for _,v in ipairs(DB.getChildList(nodeTargetList)) do
		local sStrip = StringManager.strip(DB.getValue(v, "name", ""));
		local sLower, nMult, sSuffix = parseFeatureName(sStrip);
		
		if sLower == sFeatureStripLower then
			local sSource = StringManager.strip(DB.getValue(v, "source", ""));
			if sSource ~= sClassName and sSource ~= "" then
				return false;
			end
			if (sSuffix and not sFeatureSuffix) or (not sSuffix and sFeatureSuffix) then
				return false;
			end
				
			local sNewFeature = StringManager.capitalize(sFeatureStripLower);
			sNewFeature = sNewFeature:gsub("^Ac ", "AC ");
			if sSuffix then
				local nSuffix = 1;
				if sSuffix then
					nSuffix = tonumber(sSuffix:match("%d+")) or 1;
				end
				
				if nFeatureSuffix > nSuffix then
					nSuffix = nFeatureSuffix;
				else
					nSuffix = nSuffix + nFeatureSuffix;
				end
				
				local i,j = sSuffix:find("%d+");
				local sReplace = sSuffix:sub(1,i-1) .. nSuffix .. sSuffix:sub(j+1);
				DB.setValue(v, "name", "string", sNewFeature .. sReplace);
			else
				DB.setValue(v, "name", "string", sNewFeature .. " (" .. (nMult + nFeatureMult) .. "x)");
			end
			return true;
		end
	end
	return false;
end

function handleProficiencies(nodeChar, nodeFeature)
	local aWeapons = {};
	local aArmor = {};
	
	local bIgnore = false;
	local sText = DB.getText(nodeFeature, "text", "");
	local aSentences = StringManager.split(sText, ".", true);
	for _,sSentence in ipairs(aSentences) do
		local aProfWords = StringManager.parseWords(sSentence);
		for i = 1,#aProfWords do
			if StringManager.isPhrase(aProfWords, i, { "gain", "no", "proficiency" }) then
				bIgnore = true;
				break;
			end
			if StringManager.isPhrase(aProfWords, i, { { "proficient", "skilled" }, "with" }) or 
					StringManager.isPhrase(aProfWords, i, { "proficient", "in", "the", "use", "of" }) then
				if not StringManager.isWord(aProfWords[i-1], "not") then
					local j = i + 2;
					while aProfWords[j] do
						if StringManager.isWord(aProfWords[j], "but") or StringManager.isPhrase(aProfWords, j, { "and", "treat", "any", "weapon" }) then
							break;
						elseif StringManager.isWord(aProfWords[j], "weapons") then
							if StringManager.isPhrase(aProfWords, j-3, { "simple", "and", "martial" }) then
								table.insert(aWeapons, "simple");
								table.insert(aWeapons, "martial");
							elseif StringManager.isWord(aProfWords[j-1], "simple") then
								table.insert(aWeapons, "simple");
							elseif StringManager.isWord(aProfWords[j-1], "martial") then
								table.insert(aWeapons, "martial");
							end
						elseif StringManager.isWord(aProfWords[j], "armor") then
							if StringManager.isPhrase(aProfWords, j-3, { "light", "and", "medium" }) then
								table.insert(aArmor, "light");
								table.insert(aArmor, "medium");
							elseif StringManager.isWord(aProfWords[j-1], "light") then
								table.insert(aArmor, "light");
							elseif StringManager.isWord(aProfWords[j-1], "medium") then
								table.insert(aArmor, "medium");
							elseif StringManager.isWord(aProfWords[j-1], "all") then
								table.insert(aArmor, "all");
							elseif StringManager.isPhrase(aProfWords, j-3, { "all", "types", "of" }) then
								table.insert(aArmor, "all");
							end
						elseif StringManager.isWord(aProfWords[j], "shields") then
							if StringManager.isPhrase(aProfWords, j+1, { "except", "tower", "shields" }) then
								table.insert(aArmor, "shields (except tower shields)");
								j = j + 3;
							elseif StringManager.isPhrase(aProfWords, j+1, { "including", "tower", "shields" }) then
								table.insert(aArmor, "shields (including tower shields)");
								j = j + 3;
							else
								table.insert(aArmor, "shields");
							end
						-- Class
						elseif StringManager.isPhrase(aProfWords, j, { { "hand", "light", "heavy" }, "crossbow" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+1));
							j = j + 1;
						elseif StringManager.isPhrase(aProfWords, j, { "crossbow", "light", "or", "heavy" } ) then
							table.insert(aWeapons, aProfWords[j] .. " (" .. table.concat(aProfWords, " ", j+1, j+3) .. ")");
							j = j + 3;
						elseif StringManager.isPhrase(aProfWords, j, { "brass", "knuckles" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+1));
							j = j + 1;
						elseif StringManager.isPhrase(aProfWords, j, { { "short", "long" }, "spear" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+1));
							j = j + 1;
						elseif StringManager.isPhrase(aProfWords, j, { { "short", "long", "temple" }, "sword" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+1));
							j = j + 1;
						elseif StringManager.isPhrase(aProfWords, j, { "one", "simple", "weapon" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+2));
							j = j + 1;
						-- Prestige
						elseif StringManager.isPhrase(aProfWords, j, { "crossbow", "hand", "light", "or", "heavy" } ) then
							table.insert(aWeapons, aProfWords[j] .. " (" .. table.concat(aProfWords, ", ", j+1, j+2) .. " " .. table.concat(aProfWords, " ", j+3, j+4) .. ")");
							j = j + 4;
						elseif StringManager.isPhrase(aProfWords, j, { { "longbow", "shortbow" }, "normal", "and", "composite" } ) then
							table.insert(aWeapons, aProfWords[j] .. " (" .. table.concat(aProfWords, " ", j+1, j+3) .. ")");
							j = j + 3;
						-- Racial
						elseif StringManager.isWord(aProfWords[j], { "battleaxes", "blowguns", "falchions", "greataxes", "longswords", "nets", "rapiers", "slings", "warhammers" } ) then
							table.insert(aWeapons, aProfWords[j]);
						elseif StringManager.isPhrase(aProfWords, j, { "heavy", "picks" } ) then
							table.insert(aWeapons, table.concat(aProfWords, " ", j, j+1));
							j = j + 1;
						elseif StringManager.isPhrase(aProfWords, j, { { "longbows", "shortbows" }, "including", "composite", { "longbows", "shortbows" } } ) then
							table.insert(aWeapons, aProfWords[j] .. " (" .. table.concat(aProfWords, " ", j+1, j+3) .. ")");
							j = j + 3;
						-- Specific
						elseif StringManager.isWord(aProfWords[j], { "cestus", "club", "dagger", "dart", "handaxe", "javelin", "kama", "kukri", "longsword", "nunchaku", "quarterstaff", "rapier", "sai", "sap", "scimitar", "scythe", "shortbow", "shortspear", "shortsword", "shuriken", "siangham", "sickle", "sling", "spear", "whip" } ) then
							table.insert(aWeapons, aProfWords[j]);
						end
						j = j + 1;
					end
				end
			end
		end
	end
	
	local nodeProfList = DB.createChild(nodeChar, "proficiencylist");
	if #aWeapons > 0 then
		local nodeWeaponProf = DB.createChild(nodeProfList);
		DB.setValue(nodeWeaponProf, "name", "string", "Weapon: " .. table.concat(aWeapons, ", "));
	end
	if #aArmor > 0 then
		local nodeWeaponProf = DB.createChild(nodeProfList);
		DB.setValue(nodeWeaponProf, "name", "string", "Armor: " .. table.concat(aArmor, ", "));
	end
	
	if bIgnore then
		return true;
	end
	return (#aWeapons > 0) or (#aArmor > 0);
end

function addFeat(nodeChar, sRecord, nodeTargetList)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	if not nodeTargetList then
		nodeTargetList = DB.createChild(nodeChar, "fttlist");
		if not nodeTargetList then
			return;
		end
	end

	local sRecordType;
	if string.find(sRecord, "feat") then
		sRecordType = "feat";
	elseif string.find(sRecord, "trait") then
		sRecordType = "trait";
	elseif string.find(sRecord, "talent") then
		sRecordType = "talent";
	end
	
	local nodeEntry = DB.createChild(nodeTargetList);
	DB.setValue(nodeEntry, "recordtype", "string", sRecordType)
	DB.copyNode(nodeSource, nodeEntry);
	DB.setValue(nodeEntry, "locked", "number", 1);
end
