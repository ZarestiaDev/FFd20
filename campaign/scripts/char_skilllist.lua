-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	
	constructDefaultSkills();
	CharManager.updateSkillPoints(window.getDatabaseNode());

	local nodeChar = getDatabaseNode().getParent();
	DB.addHandler(DB.getPath(nodeChar, "abilities"), "onChildUpdate", onStatUpdate);
	
	DB.addHandler(DB.getPath(nodeChar, "skilllist"), "onChildAdded", onSkillDataUpdate);
	DB.addHandler(DB.getPath(nodeChar, "skilllist"), "onChildDeleted", onSkillDataUpdate);
end

function onClose()
	local nodeChar = getDatabaseNode().getParent();
	DB.removeHandler(DB.getPath(nodeChar, "abilities"), "onChildUpdate", onStatUpdate);
	
	DB.removeHandler(DB.getPath(nodeChar, "skilllist"), "onChildAdded", onSkillDataUpdate);
	DB.removeHandler(DB.getPath(nodeChar, "skilllist"), "onChildDeleted", onSkillDataUpdate);
end

function onSkillDataUpdate()
	CharManager.updateSkillPoints(window.getDatabaseNode());
end

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.skills_iedit.getValue() == 1);
	window.idelete_header.setVisible(bEditMode);
	for _,w in ipairs(getWindows()) do
		local bAllowDelete = w.isCustom();
		if not bAllowDelete then
			local sLabel = w.label.getValue();
			local rSkill = DataCommon.skilldata[sLabel];
			if rSkill and rSkill.sublabeling then
				bAllowDelete = true;
			end
		end
		
		if bAllowDelete then
			w.idelete_spacer.setVisible(false);
			w.idelete.setVisibility(bEditMode);
		else
			w.idelete_spacer.setVisible(bEditMode);
			w.idelete.setVisibility(false);
		end
	end
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function addEntry(bFocus)
	local w = createWindow();
	w.setCustom(true);
	if bFocus and w then
		w.label.setFocus();
	end
	return w;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

-- Create default skill selection
function constructDefaultSkills()
	local aSystemSkills = DataCommon.skilldata;
	
	-- Create missing entries for all known skills
	local entrymap = {};
	for _,w in pairs(getWindows()) do
		local sLabel = w.label.getValue();
	
		local t = aSystemSkills[sLabel];
		if t and not t.sublabeling then
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				table.insert(entrymap[sLabel], w);
			end
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		if not t.sublabeling then
			local matches = entrymap[k];
			
			if not matches then
				local w = createWindow();
				if w then
					w.label.setValue(k);
					if t.stat then
						w.statname.setStringValue(t.stat);
					else
						w.statname.setStringValue("");
					end
					if t.trainedonly then
						w.showonminisheet.setValue(0);
					end
					matches = { w };
				end
			end
		end
	end

	-- Set properties for all skills
	for _,w in pairs(getWindows()) do
		w.updateWindow();
	end
end

function addNewInstance(sLabel)
	local rSkill = DataCommon.skilldata[sLabel];
	if rSkill and rSkill.sublabeling then
		local w = createWindow();
		w.label.setValue(sLabel);
		w.statname.setStringValue(rSkill.stat);
		w.updateWindow();
		w.sublabel.setFocus();
		onListChanged();
	end
end
