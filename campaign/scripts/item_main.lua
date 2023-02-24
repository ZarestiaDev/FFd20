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
	"Tier 1 Alchemical Items",
	"Tier 2 Alchemical Items",
	"Tier 3 Alchemical Items",
	"Tier 4 Alchemical Items",
	"Tier 5 Alchemical Items",
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
	"Scroll",
	"Staff",
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
	"Simple Firearms",
	"Advanced Firearms",
	"Artillery Firearms",
	"Explosives",
	"Gun Arms",
	"Royal Arms",
	"Other"
}

local materia = {
	["Common"] = {
		[0] = 0,0,500,1000,2000
	},
	["Uncommon"] = {
		[0] = 0,500,1000,2000,4000
	},
	["Rare"] = {
		[0] = 0,750,1500,3000,6000
	},
	["Legendary"] = {
		[0] = 0,1000,2000,4000,8000
	}
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

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);

	local nCostVisibility = cost_visibility.getValue();
	local nCharges = charges.getValue();
	local sType = type.getValue();
	local sSubType = subtype.getValue();
	local sMateriaRarity = materia_rarity.getValue();

	local bAlchemical = (sSubType == "Tier 1 Alchemical Items" or sSubType == "Tier 2 Alchemical Items" or sSubType == "Tier 3 Alchemical Items" or sSubType == "Tier 4 Alchemical Items" or sSubType == "Tier 5 Alchemical Items")
	local bArmor = (sType == "Armor");
	local bChocoboFood = (sSubType == "Chocobo Food");
	local bCybertech = (sType == "Cybertech");
	local bExplosives = (sSubType == "Explosives");
	local bFirearms = (sSubType == "Simple Firearms" or sSubType == "Advanced Firearms" or sSubType == "Artillery Firearms");
	local bGoodsAndService = (sType == "Goods and Service");
	local bGunArms = (sSubType == "Gun Arms");
	local bMagicItem = (sType == "Magic Item");
	local bMagicalArmor = (sSubType == "Magical Armor");
	local bMagicalWeapon = (sSubType == "Magical Weapon");
	local bMateria = (sSubType == "Materia");
	local bMateriaRarity = (sMateriaRarity == "Common" or sMateriaRarity == "Unommon" or sMateriaRarity == "Rare" or sMateriaRarity == "Legendary" );
	local bRoyalArms = (sSubType == "Royal Arms");
	local bStaff = (sSubType == "Staff");
	local bWand = (sSubType == "Wand");
	local bWeapon = (sType == "Weapon");
	local bTechnologicalGear = (sSubType == "Technological Gear")

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

	-- Set comboboxes readonly if locked
	if bReadOnly == true then
		type.setComboBoxReadOnly(true);
		subtype.setComboBoxReadOnly(true);
	else
		type.setComboBoxReadOnly(false);
		subtype.setComboBoxReadOnly(false);
	end
	
	local bSection1 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self,"nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self,"nonid_name", bReadOnly, false);
	end
	if (Session.IsHost or not bID) then
		if WindowManager.callSafeControlUpdate(self,"nonidentified", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self,"nonidentified", bReadOnly, false);
	end

	local bSection2 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self,"cost", bReadOnly, not bID and not bMateria) then bSection2 = true; end
	else
		if WindowManager.callSafeControlUpdate(self,"cost", bReadOnly, not bID and (nCostVisibility == 0) and not bMateria) then bSection2 = true; end
	end
	if WindowManager.callSafeControlUpdate(self,"weight", bReadOnly, not bID and not bMateria) then bSection2 = true; end

	-- Wand & Staff workaround for visible labeltop if no wand or staff. Hide Charges_Max dependant on number of charges left.
	if WindowManager.callSafeControlUpdate(self,"charges", bReadOnly, not bID and (bStaff or bWand)) then
		charges_labeltop.setVisible(true);
	else
		charges_labeltop.setVisible(false);
	end
	if bReadOnly then
		WindowManager.callSafeControlUpdate(self,"charges_max", bReadOnly, not bID and (bStaff or bWand) and nCharges > 0);
	else
		WindowManager.callSafeControlUpdate(self,"charges_max", bReadOnly, not bID and (bStaff or bWand));
	end
	
	-- Weapon
	WindowManager.callSafeControlUpdate(self,"damage", bReadOnly, not bID and (bWeapon or bMagicalWeapon));
	WindowManager.callSafeControlUpdate(self,"damagetype", bReadOnly, not bID and (bWeapon or bMagicalWeapon));
	WindowManager.callSafeControlUpdate(self,"critical", bReadOnly, not bID and (bWeapon or bMagicalWeapon));
	WindowManager.callSafeControlUpdate(self,"range", bReadOnly, not bID and (bWeapon or bMagicalWeapon));
	
	-- Armor
	WindowManager.callSafeControlUpdate(self,"ac", bReadOnly, not bID and (bArmor or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"maxstatbonus", bReadOnly, not bID and (bArmor or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"checkpenalty", bReadOnly, not bID and (bArmor or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"spellfailure", bReadOnly, not bID and (bArmor or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"speed30", bReadOnly, not bID and (bArmor or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"speed20", bReadOnly, not bID and (bArmor or bMagicalArmor));

	WindowManager.callSafeControlUpdate(self,"properties", bReadOnly, not bID and (bWeapon or bArmor));
	
	-- Magic Item
	WindowManager.callSafeControlUpdate(self,"bonus", bReadOnly, not bID and (bMagicalWeapon or bMagicalArmor));
	WindowManager.callSafeControlUpdate(self,"aura", bReadOnly, not bID and bMagicItem);
	WindowManager.callSafeControlUpdate(self,"cl", bReadOnly, not bID and bMagicItem);
	WindowManager.callSafeControlUpdate(self,"prerequisites", bReadOnly, not bID and bMagicItem and not bMateria);
	WindowManager.callSafeControlUpdate(self,"activation", bReadOnly, not bID and (bMagicItem or bRoyalArms));
	WindowManager.callSafeControlUpdate(self,"slot", bReadOnly, not bID and bMagicItem);

	-- Materia
	WindowManager.callSafeControlUpdate(self,"materia_type", bReadOnly, not bID and bMateria);
	WindowManager.callSafeControlUpdate(self,"materia_rarity", bReadOnly, not bID and bMateria);
	WindowManager.callSafeControlUpdate(self,"materia_cost_lvl1", bReadOnly, not bID and bMateria);
	WindowManager.callSafeControlUpdate(self,"materia_cost_lvl2", bReadOnly, not bID and bMateria);
	WindowManager.callSafeControlUpdate(self,"materia_cost_lvl3", bReadOnly, not bID and bMateria);
	WindowManager.callSafeControlUpdate(self,"materia_level", bReadOnly, not bID and (bMateriaRarity and bMateria));
	WindowManager.callSafeControlUpdate(self,"mxp", bReadOnly, not bID and (bMateriaRarity and bMateria));
	WindowManager.callSafeControlUpdate(self,"mxp_nlvl", bReadOnly, not bID and (bMateriaRarity and bMateria));

	-- Chocobo Food
	WindowManager.callSafeControlUpdate(self,"apply", bReadOnly, not bID and bChocoboFood);

	-- Cybertech
	WindowManager.callSafeControlUpdate(self,"craftinstall", bReadOnly, not bID and bCybertech);
	WindowManager.callSafeControlUpdate(self,"implantation", bReadOnly, not bID and bCybertech);

	-- Firearms
	WindowManager.callSafeControlUpdate(self,"ammo", bReadOnly, not bID and bFirearms);
	WindowManager.callSafeControlUpdate(self,"rof", bReadOnly, not bID and bFirearms);
	WindowManager.callSafeControlUpdate(self,"capacity", bReadOnly, not bID and (bFirearms or bGunArms));
	WindowManager.callSafeControlUpdate(self,"size", bReadOnly, not bID and (bFirearms or bExplosives or bTechnologicalGear));

	-- Explosives
	WindowManager.callSafeControlUpdate(self,"burstradius", bReadOnly, not bID and bExplosives);
	WindowManager.callSafeControlUpdate(self,"reflexdc", bReadOnly, not bID and bExplosives);
	WindowManager.callSafeControlUpdate(self,"craftdc", bReadOnly, not bID and bExplosives);

	-- Gun Arms
	WindowManager.callSafeControlUpdate(self,"gdamage", bReadOnly, not bID and bGunArms);
	WindowManager.callSafeControlUpdate(self,"gdamagetype", bReadOnly, not bID and bGunArms);
	WindowManager.callSafeControlUpdate(self,"gcritical", bReadOnly, not bID and bGunArms);

	-- Alchemical
	WindowManager.callSafeControlUpdate(self,"usage", bReadOnly, not bID and bAlchemical);

	-- Royal Arms
	WindowManager.callSafeControlUpdate(self,"royalarms_type", bReadOnly, not bID and bRoyalArms);

	description.setVisible(bID);
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection1 and bSection2);
end

function calcMateria()
	local nodeRecord = getDatabaseNode();
	local sMateriaRarity = DB.getValue(nodeRecord, "materia_rarity", "");
	local nMateriaLevel = DB.getValue(nodeRecord, "materia_level", 0);
	local bMateriaRarity = (sMateriaRarity == "Common" or sMateriaRarity == "Unommon" or sMateriaRarity == "Rare" or sMateriaRarity == "Legendary" );

	if bMateriaRarity then
		local nCalcMXPnLVL = materia[sMateriaRarity][nMateriaLevel];
		DB.setValue(nodeRecord, "mxp_nlvl", "number", nCalcMXPnLVL);
	end
end
