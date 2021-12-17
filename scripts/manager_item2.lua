-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function isArmor(vRecord)
	local bIsArmor = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	if not nodeItem then
		return false, "", "";
	end
	
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if (sTypeLower == "armor") then
		bIsArmor = true;
	elseif StringManager.contains({"shield", "shields"}, sTypeLower) then
		bIsArmor = true;
		sTypeLower = "armor";
		sSubtypeLower = "shield";
	end
	if sSubtypeLower == "shields" then
		sSubtypeLower = "shield";
	end
	
	return bIsArmor, sTypeLower, sSubtypeLower;
end

function isWeapon(vRecord)
	local bIsWeapon = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	if not nodeItem then
		return false, "", "";
	end
	
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if sClass == "item" then
		if ((sTypeLower == "weapon") and (sSubtypeLower ~= "ammunition")) or (sSubtypeLower == "weapon") then
			bIsWeapon = true;
		end
	end
	
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
