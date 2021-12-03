-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType ~= "shortcut" then
		return false;
	end
	
	local sDropClass, sDropNodeName = draginfo.getShortcutData();
	if not StringManager.contains({"item", "referencearmor", "referenceweapon", "referenceequipment"}, sDropClass) then
		return true;
	end
	
	local nodeSource = draginfo.getDatabaseNode();
	local nodeTarget = window.getDatabaseNode();
		
	local sSourceType = DB.getValue(nodeSource, "type", "");
	local sTargetType = DB.getValue(nodeTarget, "type", "");
	
	local sSourceName = DB.getValue(nodeSource, "name", "");
	sSourceName = string.gsub(sSourceName, " %(" .. sSourceType .. "%)", "");
	local sTargetName = DB.getValue(nodeTarget, "name", "");
	sTargetName = string.gsub(sTargetName, " %(" .. sTargetType .. "%)", "");
	
	if sSourceType == "Shield" then
		sSourceType = "Armor";
	end
	if sTargetType == "Shield" then
		sTargetType = "Armor";
	end

	if sSourceType == sTargetType and StringManager.contains({ "Weapon", "Armor" }, sSourceType) then
		local sSourceAura = DB.getValue(nodeSource, "aura", "");
		local sTargetAura = DB.getValue(nodeTarget, "aura", "");
		
		if ((sSourceAura == "") and (sTargetAura ~= "")) then
			if sSourceName ~= "" then
				local sName = sSourceName .. " (" .. DB.getValue(nodeTarget, "name", "") .. ")";
				DB.setValue(nodeTarget, "name", "string", sName);
			end
			
			local sCost = StringManager.combine(" ", DB.getValue(nodeSource, "cost", ""), DB.getValue(nodeTarget, "cost", ""));
			DB.setValue(nodeTarget, "cost", "string", sCost);
			
			local nSourceBonus = DB.getValue(nodeSource, "bonus", 0);
			local nTargetBonus = DB.getValue(nodeTarget, "bonus", 0);
			DB.setValue(nodeTarget, "bonus", "number", nSourceBonus + nTargetBonus);
			
			if sSourceType == "Weapon" then
				DB.setValue(nodeTarget, "subtype", "string", DB.getValue(nodeSource, "subtype", ""));
				DB.setValue(nodeTarget, "weight", "number", DB.getValue(nodeSource, "weight", 0));
				DB.setValue(nodeTarget, "damage", "string", DB.getValue(nodeSource, "damage", ""));
				DB.setValue(nodeTarget, "damagetype", "string", DB.getValue(nodeSource, "damagetype", ""));
				DB.setValue(nodeTarget, "critical", "string", DB.getValue(nodeSource, "critical", ""));
				DB.setValue(nodeTarget, "range", "number", DB.getValue(nodeSource, "range", 0));
				DB.setValue(nodeTarget, "properties", "string", DB.getValue(nodeSource, "properties", ""));
			elseif sSourceType == "Armor" then
				DB.setValue(nodeTarget, "subtype", "string", DB.getValue(nodeSource, "subtype", ""));
				DB.setValue(nodeTarget, "weight", "number", DB.getValue(nodeSource, "weight", 0));
				DB.setValue(nodeTarget, "ac", "number", DB.getValue(nodeSource, "ac", 0));
				DB.setValue(nodeTarget, "maxstatbonus", "number", DB.getValue(nodeSource, "maxstatbonus", 0));
				DB.setValue(nodeTarget, "checkpenalty", "number", DB.getValue(nodeSource, "checkpenalty", 0));
				DB.setValue(nodeTarget, "spellfailure", "number", DB.getValue(nodeSource, "spellfailure", 0));
				DB.setValue(nodeTarget, "speed30", "number", DB.getValue(nodeSource, "speed30", 0));
				DB.setValue(nodeTarget, "speed20", "number", DB.getValue(nodeSource, "speed20", 0));
				DB.setValue(nodeTarget, "properties", "string", DB.getValue(nodeSource, "properties", ""));
			end
		elseif ((sSourceAura ~= "") and (sTargetAura == "")) then
			local sName = "";
			if sTargetName ~= "" then
				sName = sTargetName .. " (" .. sSourceName .. ")";
			else
				sName = sSourceName;
			end
			DB.setValue(nodeTarget, "name", "string", sName);
			
			local sCost = StringManager.combine(" ", DB.getValue(nodeTarget, "cost", ""), DB.getValue(nodeSource, "cost", ""));
			DB.setValue(nodeTarget, "cost", "string", sCost);

			local nSourceBonus = DB.getValue(nodeSource, "bonus", 0);
			local nTargetBonus = DB.getValue(nodeTarget, "bonus", 0);
			DB.setValue(nodeTarget, "bonus", "number", nSourceBonus + nTargetBonus);
			
			DB.setValue(nodeTarget, "aura", "string", DB.getValue(nodeSource, "aura", ""));
			DB.setValue(nodeTarget, "cl", "number", DB.getValue(nodeSource, "cl", 0));
			DB.setValue(nodeTarget, "prerequisites", "string", DB.getValue(nodeSource, "prerequisites", ""));
			
			if nodeSource and nodeTarget then
				local nodeSourceDesc = nodeSource.getChild("description");
				if nodeSourceDesc then
					local nodeTargetDesc = nodeTarget.createChild("description", "formattedtext");
					if nodeTargetDesc then
						DB.copyNode(nodeSourceDesc, nodeTargetDesc);
					end
				end
			end
		end
	end

	return true;
end
