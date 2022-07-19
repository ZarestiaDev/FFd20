-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function getItemType(vRecord, sClass)
	ItemManager.isArmor = isArmor;
	ItemManager.isShield = isShield;
	ItemManager.isWeapon = isWeapon;
	
	ItemManager.registerCleanupTransferHandler(handleItemCleanupOnTransfer);
end

function isArmor(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	return StringManager.contains({"armor", "shield", "shields"}, sTypeLower);
end

function isShield(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	local bIsShield = false;

	if StringManager.contains({"shield", "shields"}, sTypeLower) then
		bIsShield = true;
	elseif sSubtypeLower == "shields" then
		bIsShield = true;
	end
	return bIsShield;
end

function isWeapon(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
	local bIsWeapon = ((sTypeLower == "weapon") and (sSubtypeLower ~= "ammunition")) or (sSubtypeLower == "weapon");

	return bIsWeapon;
end

function handleItemCleanupOnTransfer(rSourceItem, rTempItem, rTargetItem)
	if rSourceItem.sClass ~= "item" then
		DB.setValue(rTempItem.node, "isidentified", "number", 1);
	end
end
