-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action()	
	local aParty = {};
	for _,v in pairs(window.list.getWindows()) do
		local rActor = ActorManager.resolveActor(v.link.getTargetDatabaseNode());
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sSkill = DB.getValue("partysheet.selectedskill", "");
	if sSkill == "" then
		return true;
	end
	local sSubSkill = nil;
	if sSkill:match("^Knowledge") then
		sSubSkill = sSkill:sub(12, -2);
		sSkillLookup = "Knowledge";
	else
		sSkillLookup = sSkill;
	end
						
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		local nValue = CharManager.getSkillValue(v, sSkillLookup, sSubSkill);
		ActionSkill.performPartySheetRoll(nil, v, sSkill, nValue);
	end
	ModifierStack.unlock(true);
	
	return true;
end

function onButtonPress()
	return action();
end			
