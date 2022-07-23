-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.isArmor = isArmor;
	ItemManager.isShield = isShield;
	ItemManager.isWeapon = isWeapon;
	
	ItemManager.registerCleanupTransferHandler(handleItemCleanupOnTransfer);
end

function isArmor(nodeItem)
	local bArmor = false;
	local sType = DB.getValue(nodeItem, "type", "");
	local sSubType = DB.getValue(nodeItem, "subtype", "");

	if sType == "Armor" or sSubType == "Magical Armor" then
		bArmor = true;
	else
		bArmor = false;
	end

	return bArmor;
end

function isShield(nodeItem)
	bShield = false;
	local sSubType = DB.getValue(nodeItem, "subtype", "");
	
	if sSubType == "Shield" then
		bShield = true;
	else
		bShield = false;
	end

	return bShield;
end

function isWeapon(nodeItem)
	bWeapon = false;
	local sType = DB.getValue(nodeItem, "type", "");
	local sSubType = DB.getValue(nodeItem, "subtype", "");

	if sType == "Weapon" or sSubType == "Magical Weapon" then
		if string.find(sSubType, "Ammunition") then
			bWeapon = false;
		end
		bWeapon = true;
	else
		bWeapon = false;
	end

	return bWeapon;
end

function handleItemCleanupOnTransfer(rSourceItem, rTempItem, rTargetItem)
	if rSourceItem.sClass ~= "item" then
		DB.setValue(rTempItem.node, "isidentified", "number", 1);
	end
end
