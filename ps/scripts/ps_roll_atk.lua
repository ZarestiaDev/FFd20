-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
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
	
	local rAction = {};
	rAction.label = Interface.getString("ps_label_groupatk");
	rAction.modifier = window.bonus.getValue();
	rAction.crit = 20;

	ModifierStack.lock();
	for _,v in pairs(aParty) do
		ActionAttack.performPartySheetVsRoll(nil, v, rAction);
	end
	ModifierStack.unlock(true);
	
	return true;
end

function onButtonPress()
	return action();
end			

