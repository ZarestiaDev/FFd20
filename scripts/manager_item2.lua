-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function getItemType(vRecord, sClass)
	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	if not nodeItem then
		return "", "";
	end
	
	local sTypeLower = "";
	local sSubtypeLower = "";

	sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if StringManager.contains({"shield", "shields"}, sTypeLower) then
		sTypeLower = "armor";
		sSubtypeLower = "shield";
	elseif sSubtypeLower == "shields" then
		sSubtypeLower = "shield";
	end

	return sTypeLower, sSubtypeLower;
end

function isArmor(vRecord, sClass)
	local sTypeLower, sSubtypeLower = getItemType(vRecord, sClass);
	local bIsArmor = (sTypeLower == "armor");

	return bIsArmor, sTypeLower, sSubtypeLower;
end

function isWeapon(vRecord, sClass)
	local sTypeLower, sSubtypeLower = getItemType(vRecord, sClass);
	local bIsWeapon = ((sTypeLower == "weapon") and (sSubtypeLower ~= "ammunition")) or (sSubtypeLower == "weapon");

	return bIsWeapon, sTypeLower, sSubtypeLower;
end

function addItemToList2(sClass, nodeSource, nodeTarget)
	if LibraryData.isRecordDisplayClass("item", sClass) then
		DB.copyNode(nodeSource, nodeTarget);
		DB.setValue(nodeTarget, "isidentified", "number", 1);
		return true;
	end

	return false;
end
