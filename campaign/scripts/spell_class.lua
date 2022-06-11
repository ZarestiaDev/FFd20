-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local tClassSpellLvl = {
	["Third"] = {0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4},
	["Half"] = {1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,6,6},
	["Full"] = {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9,9}
}

local tClassMP = {
	["Third"] = {0,0,0,1,2,3,4,5,6,7,8,10,12,14,16,19,22,25,29,33},
	["Half"] = {1,2,3,4,6,8,10,14,17,20,25,29,33,40,46,50,59,66,74,79},
	["Full"] = {3,4,5,6,8,11,15,20,26,32,39,47,56,65,75,86,98,110,122,135}
}

local tAbilityBonusMP = {
	[0] = {0,0,0,0,0,0,0,0,0},
	[1] = {1,1,1,1,1,1,1,1,1},
	[2] = {1,3,3,3,3,3,3,3,3},
	[3] = {1,3,6,6,6,6,6,6,6},
	[4] = {1,3,6,10,10,10,10,10,10},
	[5] = {2,4,7,11,16,16,16,16,16},
	[6] = {2,6,9,13,18,24,24,24,24},
	[7] = {2,6,12,16,21,27,34,34,34},
	[8] = {2,6,12,20,25,31,38,46,46},
	[9] = {3,7,13,21,31,37,44,52,61},
	[10] = {3,9,15,23,33,45,52,60,69},
	[11] = {3,9,18,26,36,48,62,70,79},
	[12] = {3,9,18,30,40,52,66,82,91},
	[13] = {4,10,19,31,46,58,72,88,106},
	[14] = {4,12,21,33,48,66,80,96,114},
	[15] = {4,12,24,36,51,69,90,106,124},
	[16] = {4,12,24,40,55,73,94,118,136},
	[17] = {5,13,25,41,61,79,100,124,151}
}

local bInitialized = false;
local bShow = true;
	
function onInit()
	bInitialized = true;
	
	registerMenuItems();
	toggleDetail();
	onClassLevelChanged();
end

function update(bEditMode)
	idelete.setVisibility(bEditMode);
	for _,w in ipairs(levels.getWindows()) do
		w.update(bEditMode);
	end
end

function registerMenuItems()
	resetMenuItems();
	
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("menu_deletespellclass"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	end
end

function onStatUpdate()
	if dcstatmod then
		local nodeSpellClass = getDatabaseNode();
		local nodeCreature = nodeSpellClass.getChild("...");

		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

		local rActor = ActorManager.resolveActor(nodeCreature);
		local nValue = ActorManagerFFd20.getAbilityBonus(rActor, sAbility);
		
		dcstatmod.setValue(nValue);
		calcAbilityBonusMP(nodeSpellClass, nValue);
	end
	
	for _,vLevel in pairs(levels.getWindows()) do
		for _,vSpell in pairs(vLevel.spells.getWindows()) do
			for _,vAction in pairs(vSpell.actions.getWindows()) do
				vAction.updateViews();
			end
			for _,vAction in pairs(vSpell.header.subwindow.actionsmini.getWindows()) do
				vAction.updateViews();
			end
		end
	end
end

function calcAbilityBonusMP(node, nValue)
	if nValue < 0 or nValue > 17 then
		return;
	end

	local sType = DB.getValue(node, "type", "");
	local nLevel = DB.getValue(node, "classlevel", 0);

	if sType ~= "" then
		local nSpellLevel = tClassSpellLvl[sType][nLevel];

		DB.setValue(node, "mp.bonus", "number", tAbilityBonusMP[nValue][nSpellLevel]);
	end
end

function calcClassMP()
	local node = getDatabaseNode();
	local sType = DB.getValue(node, "type", "");
	local nLevel = DB.getValue(node, "classlevel", 0);
	if sType ~= "" then
		DB.setValue(node, "mp.class", "number", tClassMP[sType][nLevel]);
	end
end

function calcMP()
	local node = getDatabaseNode();
	local nBonus = DB.getValue(node, "mp.bonus", 0);
	local nClass = DB.getValue(node, "mp.class", 0);
	local nMisc = DB.getValue(node, "mp.misc", 0);
	
	local nCurrent = DB.getValue(node, "mp.current", 0);
	local nMax = nBonus + nClass + nMisc;
	local nOriginalMax = DB.getValue(node, "mp.max", 0);
	local nDelta = nOriginalMax - nMax;

	DB.setValue(node, "mp.max", "number", nMax);

	if nDelta ~= 0 then
		if nOriginalMax < nMax then
			nDelta = math.abs(nDelta);
		elseif nOriginalMax > nMax then
			nDelta = math.abs(nDelta)*-1;
		end
		nCurrent = nCurrent + nDelta;
		DB.setValue(node, "mp.current", "number", nCurrent);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end

function updateControl(sControl, bShow)
	local bLocalShow = bShow;
	
	if self[sControl] then
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	
	frame_stat.setVisible(status);
	ability_label.setVisible(status);
	updateControl("dcstat", status);
	
	frame_dc.setVisible(status);
	dc_label.setVisible(status);
	updateControl("dcstatmod", status);
	updateControl("dcmisc", status);
	updateControl("dctotal", status);
	
	frame_sp.setVisible(status);
	spmain_label.setVisible(status);
	updateControl("sp", status);
	
	frame_cc.setVisible(status);
	label_cc.setVisible(status);
	updateControl("ccmisc", status);

	frame_mp.setVisible(status);
	label_classlevel.setVisible(status);
	label_mpclass.setVisible(status);
	updateControl("mpbonus", status);
	updateControl("mpclass", status);
	updateControl("classlevel", status);
	updateControl("maxlevel", status);
	updateControl("mpmisc", status);
end

function setFilter(bFilter)
	bShow = bFilter;
end

function getFilter()
	return bShow;
end

function isInitialized()
	return bInitialized;
end

function updateSpellView()
	local nodeSpellClass = getDatabaseNode();
	local nAvailableLevel = DB.getValue(nodeSpellClass, "availablelevel", 0);
	local bShowLevel;

	for _,vLevel in pairs(levels.getWindows()) do
		local nLevel = DB.getValue(vLevel.getDatabaseNode(), "level", 0);
		if nAvailableLevel >= nLevel then
			bShowLevel = true;
		else
			bShowLevel = false;
		end
		vLevel.setFilter(bShowLevel);
	end
end

function performFilter()
	for _,vLevel in pairs(levels.getWindows()) do
		vLevel.spells.applyFilter();
	end
	levels.applyFilter();

	windowlist.applyFilter();
end

function onClassLevelChanged()
	updateSpellView();
	performFilter();
end

function showSpellsForLevel(nLevel)
	for _,vWin in pairs(levels.getWindows()) do
		if DB.getValue(vWin.getDatabaseNode(), "level") == nLevel then
			vWin.spells.setVisible(true);
			break;
		end
	end
end
