-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	if node then
		DB.createChild(node, "level0");
		DB.createChild(node, "level1");
		DB.createChild(node, "level2");
		DB.createChild(node, "level3");
		DB.createChild(node, "level4");
		DB.createChild(node, "level5");
		DB.createChild(node, "level6");
		DB.createChild(node, "level7");
		DB.createChild(node, "level8");
		DB.createChild(node, "level9");
	end
end

function onFilter(w)
	return w.getFilter();
end

function addEntry()
	return createWindow();
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end
	
	local winLevel = getWindowAt(x, y);
	if not winLevel then
		return false;
	end

	-- Draggable spell name to move spells
	if draginfo.isType("spellmove") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeNew = SpellManager.addSpell(nodeSource, DB.getChild(node, "..."), DB.getValue(node, "level"));
			if nodeNew then
				DB.deleteNode(nodeSource);
				winLevel.spells.setVisible(true);
			end
		end
		
		return true;

	-- Spell link with level information (i.e. class spell list)
	elseif draginfo.isType("spelldescwithlevel") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeNew = SpellManager.addSpell(nodeSource, DB.getChild(node, "..."), DB.getValue(node, "level"));
			if nodeNew then
				winLevel.spells.setVisible(true);
			end
		end
		
		return true;
	
	-- Spell link with no level information
	elseif draginfo.isType("shortcut") then
		local sDropClass, sSource = draginfo.getShortcutData();

		if sDropClass == "spelldesc" then
			local node = winLevel.getDatabaseNode();
			if node then
				local nodeSource = DB.findNode(sSource);
				local nodeNew = SpellManager.addSpell(nodeSource, DB.getChild(node, "..."), DB.getValue(node, "level"));
				if nodeNew then
					winLevel.spells.setVisible(true);
				end
				
				return true;
			end
		end
	end
end
