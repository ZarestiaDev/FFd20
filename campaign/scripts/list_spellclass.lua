-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local bInit = false;
function onInit()
	bInit = true;
end

function onListChanged()
	update();
end

function update()
	if bInit then
		local bEditMode = window.getEditMode();
		for _,w in ipairs(getWindows()) do
			w.update(bEditMode);
		end
	end
end

function onFilter(w)
	return w.getFilter();
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end

	if draginfo.isType("spellmove") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				local nTargetLevel = draginfo.getNumberData();

				local nSourceLevel = nil;
				if nodeSource then
					nSourceLevel = nodeSource.getChild("...level");
				end

				if nSourceLevel and nSourceLevel ~= nTargetLevel then
					local nodeNew = SpellManager.addSpell(nodeSource, nodeWin, nTargetLevel);
					if nodeNew then
						nodeSource.delete();
						winClass.showSpellsForLevel(nTargetLevel);
					end
				end
			end

			return true;
		end

	-- Spell link with level information (i.e. class spell list)
	elseif draginfo.isType("spelldescwithlevel") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				local nSourceLevel = draginfo.getNumberData();

				local nodeNew = SpellManager.addSpell(nodeSource, nodeWin, nSourceLevel);
				if nodeNew then
					winClass.showSpellsForLevel(nSourceLevel);
				end
			end
			
			return true;
		end
	end
end

function onSpellAddToLevel(aSelection, vCustom)
	local nTargetLevel = tonumber(aSelection[1]) or nil;
	local nodeNew = SpellManager.addSpell(vCustom.nodeSource, vCustom.nodeClass, nTargetLevel);
	if nodeNew then
		for _,winClass in ipairs(getWindows()) do
			if winClass.getDatabaseNode() == vCustom.nodeClass then
				winClass.showSpellsForLevel(nTargetLevel);
				break;
			end
		end
	end
end
