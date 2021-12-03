-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	cmdlabel.setVisible(DataCommon.isPFRPG());

	OptionsManager.registerCallback("REVL", update);
	
	if not Session.IsHost then
		list.setAnchor("bottom", "", "bottom", "absolute", -25);
	end
end

function onClose()
	OptionsManager.unregisterCallback("REVL", update);
end

function update()
	hiderollresults.setVisible(OptionsManager.isOption("REVL", "on"));
end
