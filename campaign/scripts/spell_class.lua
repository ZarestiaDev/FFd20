-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local tClassSpellLvl = {
	["Partial"] = {0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4},
	["Semi"] = {1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,6,6},
	["Full"] = {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9,9}
}

local tClassMP = {
	["Partial"] = {0,0,0,1,2,3,4,5,6,7,8,10,12,14,16,19,22,25,29,33},
	["Semi"] = {1,2,3,4,6,8,10,14,17,20,25,29,33,40,46,50,59,66,74,79},
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
	
function onInit()
	self.setInitialized();

	self.toggleDetail();
end

local _bShow = true;
function setFilter(bValue)
	_bShow = bValue;
end
function getFilter()
	return _bShow;
end
local _bInitialized = false;
function isInitialized()
	return _bInitialized;
end
function setInitialized()
	_bInitialized = true;
end

function registerMenuItems()
	resetMenuItems();
	
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("menu_deletespellclass"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	end
end

local bStatUpdateLock = false;
function onStatUpdate()
	if bStatUpdateLock then
		return;
	end
	bStatUpdateLock = true;

	if dcstatmod then
		local nodeSpellClass = getDatabaseNode();
		local nodeCreature = DB.getChild(nodeSpellClass, "...");

		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

		local rActor = ActorManager.resolveActor(nodeCreature);
		local nAbilityMod = ActorManagerFFd20.getAbilityBonus(rActor, sAbility);
		
		dcstatmod.setValue(nAbilityMod);
		calcAbilityBonusMP(nodeSpellClass, nAbilityMod);
	end
	
	for _,vLevel in pairs(levels.getWindows()) do
		for _,v in pairs(vLevel.spells.getWindows()) do
			if v.header.subwindow and v.header.subwindow.actionsmini then
				for _,v2 in pairs(v.header.subwindow.actionsmini.getWindows()) do
					v2.onDataChanged();
				end
			end
			if v.actions then
				for _,v2 in pairs(v.actions.getWindows()) do
					v2.onDataChanged();
				end
			end
		end
	end
	bStatUpdateLock = false;
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

function calcAbilityBonusMP(node, nAbilityMod)
	if nAbilityMod < 0 or nAbilityMod > 17 then
		return;
	end

	local sType = DB.getValue(node, "type", "");
	local nLevel = DB.getValue(node, "classlevel", 0);

	if sType and sType ~= "" then
		local nSpellLevel = tClassSpellLvl[sType][nLevel];

		DB.setValue(node, "mp.bonus", "number", tAbilityBonusMP[nAbilityMod][nSpellLevel]);
	end
end

function calcClassMP()
	local node = getDatabaseNode();
	local sType = DB.getValue(node, "type", "");
	local nLevel = DB.getValue(node, "classlevel", 0);
	if sType and sType ~= "" then
		DB.setValue(node, "mp.class", "number", tClassMP[sType][nLevel]);
	end
end

function onTypeChanged()
	local nodeSpellClass = getDatabaseNode();
	local nodeCreature = DB.getChild(nodeSpellClass, "...");

	local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

	local rActor = ActorManager.resolveActor(nodeCreature);
	local nAbilityMod = ActorManagerFFd20.getAbilityBonus(rActor, sAbility);
	
	calcAbilityBonusMP(nodeSpellClass, nAbilityMod);

	local nLevel = DB.getValue(nodeSpellClass, "classlevel", 0);
	local sType = DB.getValue(nodeSpellClass, "type", "");
	if sType and sType ~= "" then
		DB.setValue(nodeSpellClass, "availablelevel", "number", tClassSpellLvl[sType][nLevel]);
	end

	calcClassMP();
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		UtilityManager.safeDeleteWindow(self);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	
	frame_stat.setVisible(status);
	ability_label.setVisible(status);
	WindowManager.setControlVisibleWithLabel(self, "dcstat", status);
	
	frame_dc.setVisible(status);
	dc_label.setVisible(status);
	WindowManager.setControlVisibleWithLabel(self, "dcstatmod", status);
	WindowManager.setControlVisibleWithLabel(self, "dcmisc", status);
	WindowManager.setControlVisibleWithLabel(self, "dctotal", status);
	
	frame_sp.setVisible(status);
	spmain_label.setVisible(status);
	WindowManager.setControlVisibleWithLabel(self, "sp", status);
	
	frame_cc.setVisible(status);
	label_cc.setVisible(status);
	WindowManager.setControlVisibleWithLabel(self, "ccmisc", status);

	frame_mp.setVisible(status);
	label_classlevel.setVisible(status);
	label_mpclass.setVisible(status);
	WindowManager.setControlVisibleWithLabel(self, "mpbonus", status);
	WindowManager.setControlVisibleWithLabel(self, "mpclass", status);
	WindowManager.setControlVisibleWithLabel(self, "classlevel", status);
	WindowManager.setControlVisibleWithLabel(self, "maxlevel", status);
	WindowManager.setControlVisibleWithLabel(self, "mpmisc", status);
	WindowManager.setControlVisibleWithLabel(self, "type", status);
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
