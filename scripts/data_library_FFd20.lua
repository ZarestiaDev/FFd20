-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function getItemIsIdentified(vRecord, vDefault)
	return LibraryData.getIDState("item", vRecord, true);
end

function getCRGroupedList(v)
	local nOutput = v or 0;
	if nOutput > 0 then
		if nOutput < 0.14 then
			nOutput = "1/8";
		elseif nOutput < 0.2 then
			nOutput = "1/6";
		elseif nOutput < 0.3 then
			nOutput = "1/4";
		elseif nOutput < 0.4 then
			nOutput = "1/3";
		elseif nOutput < 1 then
			nOutput = "1/2";
		end
	end
	return tostring(nOutput);
end

function getCRGroup(v)
	local nOutput = v or 0;
	if nOutput > 0 then
		if nOutput < 0.14 then
			nOutput = 0.125;
		elseif nOutput < 0.2 then
			nOutput = 0.166;
		elseif nOutput < 0.3 then
			nOutput = 0.25;
		elseif nOutput < 0.4 then
			nOutput = 0.33;
		elseif nOutput < 1 then
			nOutput = 0.5;
		end
	end
	return tostring(nOutput);
end

function getNPCCRValue(vNode)
	return getCRGroup(DB.getValue(vNode, "cr", 0));
end

function getTypeGroup(v)
	local sOutput = "";
	if v then
		local sCreatureType = StringManager.trim(v):lower();
		for _,sListCreatureType in ipairs(DataCommon.creaturetype) do
			if sCreatureType:match(sListCreatureType) then
				sOutput = StringManager.capitalize(sListCreatureType);
				break;
			end
		end
	end
	return sOutput;
end

function getNPCTypeValue(vNode)
	return getTypeGroup(DB.getValue(vNode, "type", ""));
end

function getItemRecordDisplayClass(vNode)
	local sRecordDisplayClass = "item";
	if vNode then
		local sBasePath, sSecondPath = UtilityManager.getDataBaseNodePathSplit(vNode);
		if sBasePath == "reference" then
			if sSecondPath == "weapon" then
				sRecordDisplayClass = "referenceweapon";
			elseif sSecondPath == "armor" then
				sRecordDisplayClass = "referencearmor";
			elseif sSecondPath == "equipment" then
				sRecordDisplayClass = "referenceequipment";
			else
				sRecordDisplayClass = "item";
			end
		end
	end
	return sRecordDisplayClass;
end

function isItemIdentifiable(vNode)
	return (getItemRecordDisplayClass(vNode) == "item");
end

function getSpellSchoolValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "school", ""));
	local sType = v:match("^%w+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end

function getSpellSourceValue(vNode)
	return StringManager.split(DB.getValue(vNode, "level", ""), ",", true);
end

function getClassTypeValue(vNode)
	local sClassType = DB.getValue(vNode, "classtype", "");
	if sClassType == "prestige" then
		return Interface.getString("class_label_classtype_prestige");
	elseif sClassType == "npc" then
		return Interface.getString("class_label_classtype_npc");
	end
	return Interface.getString("class_label_classtype_base");
end

aRecordOverrides = {
	-- CoreRPG overrides
	["image"] = { 
		aDataMap = { "image", "reference.imagedata" }, 
	},
	["npc"] = { 
		aDataMap = { "npc", "reference.npcdata" }, 
		aGMListButtons = { "button_npc_letter", "button_npc_cr", "button_npc_type" },
		aCustomFilters = {
			["CR"] = { sField = "cr", sType = "number", fGetValue = getNPCCRValue },
			["Type"] = { sField = "type", fGetValue = getNPCTypeValue },
		},
	},
	["item"] = { 
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", "reference.equipment", "reference.weapon", "reference.armor", "reference.magicitems" }, 
		fRecordDisplayClass = getItemRecordDisplayClass,
		aRecordDisplayClasses = { "item", "referencearmor", "referenceweapon", "referenceequipment" },
		aGMListButtons = { "button_item_armor", "button_item_weapons" },
		aPlayerListButtons = { "button_item_armor", "button_item_weapons" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
			["Subtype"] = {sField = "subtype" },
		},
	},

	-- New record types
	["class"] = {
		bExport = true,
		aDataMap = { "class", "reference.classes" }, 
		sRecordDisplayClass = "referenceclass", 
		aCustomFilters = {
			["Type"] = { sField = "classtype", fGetValue = getClassTypeValue },
		},
	},
	["feat"] = {
		bExport = true,
		aDataMap = { "feat", "reference.feats" }, 
		sRecordDisplayClass = "referencefeat", 
		aGMListButtons = { "button_feat_type" },
		aPlayerListButtons = { "button_feat_type" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},
	["race"] = {
		bExport = true,
		aDataMap = { "race", "reference.races" }, 
		sRecordDisplayClass = "referencerace", 
	},
	["skill"] = {
		bExport = true,
		aDataMap = { "skill", "reference.skills" }, 
		sRecordDisplayClass = "referenceskill", 
		aCustomFilters = {
			["Ability"] = { sField = "ability" },
		},
	},
	["spell"] = {
		bExport = true,
		aDataMap = { "spell", "reference.spells", "spelldesc" }, 
		sRecordDisplayClass = "spelldesc", 
		aCustomFilters = {
			["School"] = { sField = "school", fGetValue = getSpellSchoolValue },
			["Source"] = { sField = "level", fGetValue = getSpellSourceValue },
		},
	},
	["specialability"] = {
		bExport = true,
		aDataMap = { "specialability", "reference.specialabilities" }, 
		sRecordDisplayClass = "referenceclassability", 
		aGMListButtons = { "button_specialability_type" },
		aPlayerListButtons = { "button_specialability_type" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},
};

aListViews = {
	["npc"] = {
		["byletter"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=250 },
				{ sName = "cr", sType = "number", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["bycr"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=250 },
				{ sName = "cr", sType = "number", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "cr", sPrefix = "CR", sCustom="npc_cr" } },
			aGroupValueOrder = { "CR", "CR 0", "CR 1/8", "CR 1/4", "CR 1/2", 
								"CR 1", "CR 2", "CR 3", "CR 4", "CR 5", "CR 6", "CR 7", "CR 8", "CR 9" },
		},
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=250 },
				{ sName = "cr", sType = "number", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "type", sCustom="npc_type" } },
			aGroupValueOrder = { },
		},
	},
	["item"] = {
		["armor"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "ac", sType = "number", sHeadingRes = "item_grouped_label_ac", sTooltipRes = "item_grouped_tooltip_ac", nWidth=40, bCentered=true, nSortOrder=1 },
				{ sName = "maxstatbonus", sType = "number", sHeadingRes = "item_grouped_label_maxstatbonus", sTooltipRes = "item_grouped_tooltip_maxstatbonus", bCentered=true },
				{ sName = "checkpenalty", sType = "number", sHeadingRes = "item_grouped_label_checkpenalty", sTooltipRes = "item_grouped_tooltip_checkpenalty", bCentered=true },
				{ sName = "spellfailure", sType = "number", sHeadingRes = "item_grouped_label_spellfailure", sTooltipRes = "item_grouped_tooltip_spellfailure", bCentered=true },
				{ sName = "speed30", sType = "number", sHeadingRes = "item_grouped_label_speed30", sTooltipRes = "item_grouped_tooltip_speed30", bCentered=true },
				{ sName = "speed20", sType = "number", sHeadingRes = "item_grouped_label_speed20", sTooltipRes = "item_grouped_tooltip_speed20", bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Armor" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Light", "Medium", "Heavy", "Shield", "Extras" },
		},
		["weapon"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "damage", sType = "string", sHeadingRes = "item_grouped_label_damage", nWidth=60, bCentered=true },
				{ sName = "critical", sType = "string", sHeadingRes = "item_grouped_label_critical", bCentered=true },
				{ sName = "range", sType = "number", sHeadingRes = "item_grouped_label_range", sTooltipRes = "item_grouped_tooltip_range", nWidth=30, bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true },
				{ sName = "properties", sType = "string", sHeadingRes = "item_grouped_label_properties", nWidth=120 },
				{ sName = "damagetype", sType = "string", sHeadingRes = "item_grouped_label_damagetype", nWidth=150 }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Weapon" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Simple Unarmed Melee", "Simple Light Melee", "Simple One-Handed Melee", "Simple Two-Handed Melee", "Simple Ranged", "Martial Light Melee", "Martial One-Handed Melee", "Martial Two-Handed Melee", "Martial Ranged", "Exotic Light Melee", "Exotic One-Handed Melee", "Exotic Two-Handed Melee", "Exotic Ranged" },
		},
		["equipment"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true },
			},
			aFilters = { 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Ammunition", "Adventuring Gear", "Special Substances And Items", "Tools And Skill Kits", "Clothing", "Food, Drink, And Lodging", "Mounts And Related Gear", "Transport", "Spellcasting And Services" },
		},
	},
	["specialability"] = {
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=250 },
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { },
		},
	},
	["feat"] = {
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "name", nWidth=170 },
				{ sName = "prerequisites", sType = "string", sHeadingRes = "feat_grouped_label_prereq", nWidth=240, bWrapped = true },
				{ sName = "summary", sType = "string", sHeadingRes = "feat_grouped_label_benefit", nWidth=280, bWrapped = true },
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { },
		},
	},
};

function onInit()
	LibraryData.setCustomFilterHandler("item_isidentified", getItemIsIdentified);
	LibraryData.setCustomGroupOutputHandler("npc_cr", getCRGroupedList);
	LibraryData.setCustomGroupOutputHandler("npc_type", getTypeGroup);

	LibraryData.overrideRecordTypes(aRecordOverrides);
	LibraryData.setRecordViews(aListViews);
	LibraryData.setRecordTypeInfo("vehicle", nil);
end
