-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;
local bShow = true;
	
function onInit()
	bInitialized = true;
	
	onCasterTypeChanged();
	toggleDetail();
	onDisplayChanged();
end

function update(bEditMode)
	if minisheet then
		return;
	end
	
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
	
	if DB.getValue(getDatabaseNode(), "castertype", "") == "" then
		registerMenuItem(Interface.getString("menu_resetspells"), "pointer_circle", 3);
	end
end

function onStatUpdate()
	if dcstatmod then
		local nodeSpellClass = getDatabaseNode();
		local nodeCreature = nodeSpellClass.getChild("...");

		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

		local rActor = ActorManager.resolveActor(nodeCreature);
		local nValue = ActorManager35E.getAbilityBonus(rActor, sAbility);
		
		dcstatmod.setValue(nValue);
	end
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		for kSpell, vSpell in pairs(vLevel.spells.getWindows()) do
			if vSpell.minisheet then
				for kAction, vAction in pairs(vSpell.header.subwindow.actions.getWindows()) do
					vAction.updateViews();
				end
			else
				for kAction, vAction in pairs(vSpell.actions.getWindows()) do
					vAction.updateViews();
				end
				for kAction, vAction in pairs(vSpell.header.subwindow.actionsmini.getWindows()) do
					vAction.updateViews();
				end
			end
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		local nodeCaster = getDatabaseNode().getChild("...");
		SpellManager.resetPrepared(nodeCaster);
	elseif selection == 6 and subselection == 7 then
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
	if minisheet then
		return;
	end
	
	local status = (activatedetail.getValue() == 1);

	frame_levels.setVisible(status);
	updateControl("availablelevel", status);
	updateControl("availablelevel0", status);
	updateControl("availablelevel1", status);
	updateControl("availablelevel2", status);
	updateControl("availablelevel3", status);
	updateControl("availablelevel4", status);
	updateControl("availablelevel5", status);
	updateControl("availablelevel6", status);
	updateControl("availablelevel7", status);
	updateControl("availablelevel8", status);
	updateControl("availablelevel9", status);
	
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

function getSheetMode()
	if minisheet then
		return "combat";
	end
	
	return DB.getValue(getDatabaseNode(), "...spellmode", "standard");
end

function onCasterTypeChanged()
	local bShowPP = (DB.getValue(getDatabaseNode(), "castertype", "") == "points");
	pointsused.setVisible(bShowPP);
	label_pointsused.setVisible(bShowPP);
	points.setVisible(bShowPP);
	label_points.setVisible(bShowPP);
	
	onSpellCounterUpdate();
	
	registerMenuItems();
end

function onDisplayChanged()
	if minisheet then
		return;
	end
	
	for _,vLevel in pairs(levels.getWindows()) do
		for _,vSpell in pairs(vLevel.spells.getWindows()) do
			vSpell.onDisplayChanged();
		end
	end
end

function onSpellCounterUpdate()
	if not isInitialized() then
		return;
	end
	
	SpellManager.updateSpellClassCounts(getDatabaseNode());

	updateSpellView();
	
	performFilter();
end

function updateSpellView()
	local nodeSpellClass = getDatabaseNode();

	local bClassShow = false;
	local sSheetMode = getSheetMode();
	local sCasterType = DB.getValue(nodeSpellClass, "castertype", "");

	local bLevelShow, nodeLevel, nAvailable, nTotalCast, nTotalPrepared, nMaxPrepared, nSpells;
	local bSpellShow, nodeSpell, nCast, nPrepared, nPointCost;

	local nPP = DB.getValue(nodeSpellClass, "points", 0);
	local nPPUsed = DB.getValue(nodeSpellClass, "pointsused", 0);
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		bLevelShow = false;

		nAvailable = 0;
		nodeLevel = vLevel.getDatabaseNode();
		if nodeLevel then
			nAvailable = DB.getValue(nodeSpellClass, "available" .. nodeLevel.getName(), 0);
		end
		
		nSpells = 0;
		nTotalCast = DB.getValue(nodeLevel, "totalcast", 0);
		nTotalPrepared = DB.getValue(nodeLevel, "totalprepared", 0);
		nMaxPrepared = DB.getValue(nodeLevel, "maxprepared", 0);

		if nodeLevel and nodeLevel.getName() == "level0" then
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				bSpellShow = true;
				nPrepared = DB.getValue(nodeSpell, "prepared", 0);
				
				if sCasterType == "" and sSheetMode == "combat" then
					if nPrepared == 0 then
						bSpellShow = false;
					end
				end
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);
				
				if sCasterType == "" then
					if sSheetMode == "preparation" then
						vSpell.header.subwindow.usepower.setVisible(false);
						vSpell.header.subwindow.counter.setVisible(true);
						vSpell.header.subwindow.counter.update(sSheetMode, (sCasterType == "spontaneous"), nAvailable, 0, nTotalPrepared, nMaxPrepared);
						vSpell.header.subwindow.usespacer.setVisible(nAvailable == 0);
					else
						if (nPrepared > 0) then
							vSpell.header.subwindow.usepower.setVisible(true);
							vSpell.header.subwindow.usepower.setTooltipText(Interface.getString("spell_tooltip_castspell"));
							vSpell.header.subwindow.usespacer.setVisible(false);
						else
							vSpell.header.subwindow.usepower.setVisible(false);
							vSpell.header.subwindow.usespacer.setVisible(true);
						end
						vSpell.header.subwindow.counter.setVisible(false);
					end
				elseif sCasterType == "points" then
					vSpell.header.subwindow.usepower.setVisible(true);
					vSpell.header.subwindow.usepower.setTooltipText(Interface.getString("spell_tooltip_usepower"));
					vSpell.header.subwindow.counter.setVisible(false);
					vSpell.header.subwindow.usespacer.setVisible(false);
				else
					vSpell.header.subwindow.usepower.setVisible(true);
					vSpell.header.subwindow.usepower.setTooltipText(Interface.getString("spell_tooltip_castspell"));
					vSpell.header.subwindow.counter.setVisible(false);
					vSpell.header.subwindow.usespacer.setVisible(false);
				end
				vSpell.header.subwindow.cost.setVisible(false);
				vSpell.header.subwindow.cost_spacer.setVisible(false);
			end
			
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
			
		elseif sCasterType == "points" then
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				nPointCost = DB.getValue(nodeSpell, "cost", 0);
				
				if sSheetMode ~= "combat" then
					bSpellShow = true;
				else
					bSpellShow = (nPointCost <= (nPP - nPPUsed));
				end
				vSpell.setFilter(bSpellShow);
				bLevelShow = bLevelShow or bSpellShow;

				vSpell.header.subwindow.usepower.setVisible(true);
				vSpell.header.subwindow.cost.setVisible(true);
				vSpell.header.subwindow.cost_spacer.setVisible(true);
				vSpell.header.subwindow.counter.setVisible(false);
				vSpell.header.subwindow.usespacer.setVisible(false);
			end
		
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
		else
			-- Update spell counter objects and spell visibility
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				nCast = DB.getValue(nodeSpell, "cast", 0);
				nPrepared = DB.getValue(nodeSpell, "prepared", 0);
				
				if sCasterType == "spontaneous" or sSheetMode ~= "combat" then
					bSpellShow = true;
				else
					bSpellShow = (nCast < nPrepared);
				end
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);

				vSpell.header.subwindow.usepower.setVisible(false);
				vSpell.header.subwindow.cost.setVisible(false);
				vSpell.header.subwindow.cost_spacer.setVisible(false);
				vSpell.header.subwindow.counter.setVisible(true);
				vSpell.header.subwindow.counter.update(sSheetMode, (sCasterType == "spontaneous"), nAvailable, nTotalCast, nTotalPrepared, nMaxPrepared);
				if (sSheetMode == "preparation" or sCasterType == "spontaneous") then
					vSpell.header.subwindow.usespacer.setVisible(nAvailable == 0);
				else
					vSpell.header.subwindow.usespacer.setVisible(nPrepared == 0);
				end
			end
			
			-- Determine level visibility
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nTotalCast < nAvailable) and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
		end
		bClassShow = bClassShow or bLevelShow;
		vLevel.setFilter(bLevelShow);

		if not minisheet then
			-- Set level statistics label
			local sStats = "";
			if nodeLevel and nodeLevel.getName() == "level0" then
				if sCasterType == "" then
					sStats = "Prepared:  " .. nTotalPrepared .. " / " .. nAvailable;
				end
			elseif (sCasterType ~= "points") and (nAvailable > 0) and (nSpells > 0) then
				if (sCasterType == "spontaneous") then
					sStats = "Cast:  " .. nTotalCast .. " / " .. nAvailable;
				else
					sStats = "Cast:  " .. nTotalCast .. " / " .. nTotalPrepared;
					if nTotalPrepared < nAvailable then
						sStats = sStats .. "    Prepared:  " .. nTotalPrepared .. " / " .. nAvailable;
					end
				end
			end
			vLevel.stats.setValue(sStats);
		end
	end
	
	if sSheetMode == "combat" then
		setFilter(bClassShow);
	else
		setFilter(true);
	end
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
