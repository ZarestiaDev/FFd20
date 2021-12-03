-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDisplayChanged()
	for _,v in pairs(actions.subwindow.spellclasslist.getWindows()) do
		v.onDisplayChanged();
	end
end

function onModeChanged()
	actions.subwindow.weaponlist.onModeChanged();
	
	updateSpellCounters();
end

function updateSpellCounters()
	for _,v in pairs(actions.subwindow.spellclasslist.getWindows()) do
			v.onSpellCounterUpdate();
	end
end

