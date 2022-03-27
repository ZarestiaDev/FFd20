-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local armor_subtypes = {
	"Light",
	"Medium",
	"Heavy",
	"Shield",
	"Extras"
}

local cybertech_subtpyes = {
	"Arm Slot",
	"Body Slot",
	"Brain Slot",
	"Ears Slot",
	"Eyes Slot",
	"Head Slot",
	"Legs Slot",
	"Slotless"
}

local goods_and_servives_subtypes = {
	"Adventuring Gear",
	"Alchemical Gear",
	"Animals & Animal Gear",
	"Books, Paper, & Writing Supplies",
	"Chocobo Food",
	"Clothing & Containers",
	"Furniture, Trade Goods & Vehicles",
	"Hirelings, Servants & Services",
	"Locks, Keys, Tools & Kits",
	"Religious Items, Toys & Games",
	"Technological Gear"
}

local magic_item_subtypes = {
	"Alchemical Items",
	"Artifact",
	"Cursed Item",
	"Intelligent Item",
	"Magical Armor",
	"Magical Weapon",
	"Magitek",
	"Materia",
	"Miscellaneous Item",
	"Potion",
	"Ring",
	"Relic",
	"Rod",
	"Royal Arms",
	"Scroll",
	"Stave",
	"Wand",
	"Wondrous Item"
}

local weapon_subtypes = {
	"Simple Unarmed",
	"Simple Light",
	"Simple One-Handed",
	"Simple Two-Handed",
	"Simple Ranged",
	"Simple Ammunition",
	"Martial Light",
	"Martial One-Handed",
	"Martial Two-Handed",
	"Martial Ranged",
	"Martial Ammunition",
	"Exotic Light",
	"Exoitc One-Handed",
	"Exotic Two-Handed",
	"Exotic Ranged",
	"Exotic Ammunition",
	"Firearms",
	"Gun Arms",
	"Other"
}

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end

	if not bID then
		return self[sControl].update(bReadOnly, true);
	end

	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);
	local nCostVisibility = cost_visibility.getValue();

	local sType = type.getValue();
	local sSubType = subtype.getValue();
	local bArmor = (sType == "Armor");
	local bCybertech = (sType == "Cybertech");
	local bGoodsAndService = (sType == "Goods and Service");
	local bMagicItem = (sType == "Magic Item");
	local bWeapon = (sType == "Weapon");
	local bMagicalArmor = (sSubType == "Magical Armor");
	local bMagicalWeapon = (sSubType == "Magical Weapon");
	local bStave = (sSubType == "Stave");
	local bWand = (sSubType == "Wand");

	if bArmor then
		subtype.clear();
		subtype.addItems(armor_subtypes);
	elseif bCybertech then
		subtype.clear();
		subtype.addItems(cybertech_subtpyes);
	elseif bGoodsAndService then
		subtype.clear();
		subtype.addItems(goods_and_servives_subtypes);
	elseif bMagicItem then
		subtype.clear();
		subtype.addItems(magic_item_subtypes);
	elseif bWeapon then
		subtype.clear();
		subtype.addItems(weapon_subtypes);
	end

	-- Hide comboboxes if locked
	if bReadOnly == true then
		type_label.setVisible(false);
		type.setComboBoxVisible(false);
		subtype_label.setVisible(false);
		subtype.setComboBoxVisible(false);
	else
		type_label.setVisible(true);
		type.setComboBoxVisible(true);
		subtype_label.setVisible(true);
		subtype.setComboBoxVisible(true);
	end
	
	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonid_name", false);
	end
	if (Session.IsHost or not bID) then
		if updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonidentified", false);
	end

	local bSection2 = false;
	if Session.IsHost then
		if updateControl("cost", bReadOnly, bID) then bSection2 = true; end
	else
		if updateControl("cost", bReadOnly, bID and (nCostVisibility == 0)) then bSection2 = true; end
	end
	if updateControl("weight", bReadOnly, bID) then bSection2 = true; end

	-- Wand & Stave
	if updateControl("charges", bReadOnly, bID and (bStave or bWand)) then
		charges_labeltop.setVisible(true);
	else
		charges_labeltop.setVisible(false);
	end
	updateControl("charges_max", bReadOnly, bID and (bStave or bWand));
	
	-- Weapon
	updateControl("damage", bReadOnly, bID and (bWeapon or bMagicalWeapon));
	updateControl("damagetype", bReadOnly, bID and (bWeapon or bMagicalWeapon));
	updateControl("critical", bReadOnly, bID and (bWeapon or bMagicalWeapon));
	updateControl("range", bReadOnly, bID and (bWeapon or bMagicalWeapon));
	
	-- Armor
	updateControl("ac", bReadOnly, bID and (bArmor or bMagicalArmor));
	updateControl("maxstatbonus", bReadOnly, bID and (bArmor or bMagicalArmor));
	updateControl("checkpenalty", bReadOnly, bID and (bArmor or bMagicalArmor));
	updateControl("spellfailure", bReadOnly, bID and (bArmor or bMagicalArmor));
	updateControl("speed30", bReadOnly, bID and (bArmor or bMagicalArmor));
	updateControl("speed20", bReadOnly, bID and (bArmor or bMagicalArmor));

	updateControl("properties", bReadOnly, bID and (bWeapon or bArmor));
	
	-- Magic Item
	updateControl("bonus", bReadOnly, bID and (bMagicalWeapon or bMagicalArmor));
	updateControl("aura", bReadOnly, bID and bMagicItem);
	updateControl("cl", bReadOnly, bID and bMagicItem);
	updateControl("prerequisites", bReadOnly, bID and bMagicItem);
	
	description.setVisible(bID);
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection1 and bSection2);
end
