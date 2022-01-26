-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local tLanguages = DataCommon.languages;
	local nodeChar = getDatabaseNode();

	-- construct languages
	for _,v in ipairs(tLanguages) do
		local w = list.createWindow();
		w.text.setValue(v);
	end

	-- read languages from DB and mark them selected
	local tLanguageList = DB.getChildren(nodeChar.getChild("languagelist"));

	for _,v in pairs(tLanguageList) do
		local sCharLanguage = DB.getValue(v, "name");

		for _,w in pairs(list.getWindows()) do
			local sLanguage = w.text.getValue();
			if sLanguage == sCharLanguage then
				w.selected.setValue(1);
			end
		end
	end
end

local function removeLanguage(nodeChar, sLanguage)
	local nodeList = nodeChar.getChild("languagelist");
	if not nodeList then
		return false;
	end

	for _,v in pairs(nodeList.getChildren()) do
		if DB.getValue(v, "name", "") == sLanguage then
			v.delete();
			return true;
		end
	end
end

function processOK()
	local nodeChar = getDatabaseNode();

	for _,w in pairs(list.getWindows()) do
		if w.selected.getValue() == 1 then
			local sLanguage = w.text.getValue();
			CharManager.addLanguage(nodeChar, sLanguage);
		elseif w.selected.getValue() == 0 then
			local sLanguage = w.text.getValue();
			removeLanguage(nodeChar, sLanguage);
		end
	end

	close();
end

function processCancel()
	close();
end