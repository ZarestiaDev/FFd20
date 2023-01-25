-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function getSkillDescNode()
	local sStripName = StringManager.strip(window.label.getValue());
	if sStripName == "" then
		return nil;
	end
	
	local aMappings = LibraryData.getMappings("skill");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in ipairs(DB.getChildrenGlobal(vMapping)) do
			if StringManager.strip(DB.getValue(vNode, "name", "")) == sStripName then
				return vNode;
			end
		end
	end
	
	ChatManager.SystemMessage(Interface.getString("char_message_missingskilldesc"));
	return nil;
end

function onButtonPress()
	local v = getSkillDescNode();
	if v then
		Interface.openWindow("referenceskill", v);
	end
end

function onDragStart(draginfo)
	local v = getSkillDescNode();
	if v then
		draginfo.setType("shortcut");
		draginfo.setIcon("button_link");
		draginfo.setShortcutData("referenceskill", v);
		draginfo.setDescription(window.label.getValue());
		return true;
	end
	return false;
end
