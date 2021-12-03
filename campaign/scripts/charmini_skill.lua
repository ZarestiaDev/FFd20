-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	updateName();
end

function onStatUpdate()
	stat.update(statname.getValue());
end

function updateStatus()
	windowlist.applyFilter();
end

function updateName()
	if sublabel.getValue() ~= "" then
		name.setValue(label.getValue() .. " (" .. sublabel.getValue() .. ")");
	else
		name.setValue(label.getValue());
	end
end
