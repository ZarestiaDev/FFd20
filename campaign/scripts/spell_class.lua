-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local tBonusMP = {
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
	
	toggleDetail();

	local nDCStatValue = dcstatmod.getValue();
	local nBonusMP = tBonusMP[nDCStatValue][9];
	Debug.console("bonusMP:", nBonusMP)
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
	end
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		for kSpell, vSpell in pairs(vLevel.spells.getWindows()) do
			for kAction, vAction in pairs(vSpell.actions.getWindows()) do
				vAction.updateViews();
			end
			for kAction, vAction in pairs(vSpell.header.subwindow.actionsmini.getWindows()) do
				vAction.updateViews();
			end
		end
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

	local bClassShow = false;

	local bLevelShow, nodeLevel, nAvailable, nTotalCast, nSpells;
	local bSpellShow, nodeSpell;
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		bLevelShow = false;

		nAvailable = 0;
		nodeLevel = vLevel.getDatabaseNode();
		if nodeLevel then
			nAvailable = DB.getValue(nodeSpellClass, "available" .. nodeLevel.getName(), 0);
		end
		
		nSpells = 0;
		nTotalCast = DB.getValue(nodeLevel, "totalcast", 0);

		if nodeLevel and nodeLevel.getName() == "level0" then
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				bSpellShow = true;
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);
				
				vSpell.header.subwindow.usepower.setVisible(false);
			end
			
			bLevelShow = bLevelShow and (nAvailable > 0) and (nSpells > 0);
		else
			-- Update spell counter objects and spell visibility
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				nCast = DB.getValue(nodeSpell, "cast", 0);
				
				bSpellShow = true;
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);

				vSpell.header.subwindow.usepower.setVisible(false);
			end
			
			bLevelShow = bLevelShow and (nTotalCast < nAvailable) and (nAvailable > 0) and (nSpells > 0);
		end
		bClassShow = bClassShow or bLevelShow;
		vLevel.setFilter(bLevelShow);
	end
	
	setFilter(bClassShow);
end

function performFilter()
	for _,vLevel in pairs(levels.getWindows()) do
		vLevel.spells.applyFilter();
	end
	levels.applyFilter();

	windowlist.applyFilter();
end

function showSpellsForLevel(nLevel)
	for _,vWin in pairs(levels.getWindows()) do
		if DB.getValue(vWin.getDatabaseNode(), "level") == nLevel then
			vWin.spells.setVisible(true);
			break;
		end
	end
end
