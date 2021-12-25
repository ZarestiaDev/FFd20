-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onHealthChanged()
	local sColor = ActorManagerFFd20.getPCSheetWoundColor(getDatabaseNode());
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
end