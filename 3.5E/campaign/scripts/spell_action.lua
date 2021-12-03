-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_sType = nil;

function onInit()
	registerMenuItem(Interface.getString("menu_deletespellaction"), "deletepointer", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "deletepointer", 4, 3);

	local sNode = getDatabaseNode().getPath();
	DB.addHandler(sNode, "onChildAdded", onDataChanged);
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getPath();
	DB.removeHandler(sNode, "onChildAdded", onDataChanged);
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

local bDataChangedLock = false;
function onDataChanged()
	if bDataChangedLock then
		return;
	end
	bDataChangedLock = true;
	if not m_sType then
		local sType = DB.getValue(getDatabaseNode(), "type");
		if (sType or "") ~= "" then
			createDisplay(sType);
			m_sType = sType;
		end
	end
	if m_sType then
		updateViews();
	end
	bDataChangedLock = false;
end

function highlight(bState)
	if bState then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function createDisplay(sType)
	if sType == "cast" then
		createControl("spell_action_castbutton", "castbutton");
		createControl("spell_action_castlabel", "castlabel");
		createControl("spell_action_attackbutton", "attackbutton");
		createControl("spell_action_attackviewlabel", "attackviewlabel");
		createControl("spell_action_attackview", "attackview");
		createControl("spell_action_levelcheckbutton", "levelcheckbutton");
		createControl("spell_action_levelcheckviewlabel", "levelcheckviewlabel");
		createControl("spell_action_levelcheckview", "levelcheckview");
		createControl("spell_action_savebutton", "savebutton");
		createControl("spell_action_saveviewlabel", "saveviewlabel");
		createControl("spell_action_saveview", "saveview");
		createControl("spell_action_castdetailbutton", "castdetail");
	elseif sType == "damage" then
		createControl("spell_action_damagebutton", "damagebutton");
		createControl("spell_action_damagelabel", "damagelabel");
		createControl("spell_action_damageview", "damageview");
		createControl("spell_action_damagedetailbutton", "damagedetail");
	elseif sType == "heal" then
		createControl("spell_action_healbutton", "healbutton");
		createControl("spell_action_heallabel", "heallabel");
		createControl("spell_action_healview", "healview");
		createControl("spell_action_healtypelabel", "healtypelabel");
		createControl("spell_action_healtype", "healtype");
		createControl("spell_action_healdetailbutton", "healdetail");
	elseif sType == "effect" then
		createControl("spell_action_effectbutton", "effectbutton");
		createControl("spell_action_effecttargeting", "targeting");
		createControl("spell_action_effectapply", "apply");
		createControl("spell_action_effectlabel", "label");
		createControl("spell_action_effectdurationview", "durationview");
		createControl("spell_action_effectdetailbutton", "effectdetail");
	end
end

function updateViews()
	if m_sType == "cast" then
		onCastChanged();
	elseif m_sType == "damage" then
		onDamageChanged();
	elseif m_sType == "heal" then
		onHealChanged();
	elseif m_sType == "effect" then
		onEffectChanged();
	end
end

function onCastChanged()
	local node = getDatabaseNode();

	local sAttack = SpellManager.getActionAttackText(node);
	attackview.setValue(sAttack);

	local nCL = SpellManager.getActionCLC(node);
	levelcheckview.setValue("" .. nCL);
	
	local sSave = SpellManager.getActionSaveText(node);
	saveview.setValue(sSave);
end

function onDamageChanged()
	local sDamage = SpellManager.getActionDamageText(getDatabaseNode());
	damageview.setValue(sDamage);
end

function onHealChanged()
	local sHeal = SpellManager.getActionHealText(getDatabaseNode());
	healview.setValue(sHeal);
end

function onEffectChanged()
	local sDuration = SpellManager.getActionEffectDurationText(getDatabaseNode());
	durationview.setValue(sDuration);
end
