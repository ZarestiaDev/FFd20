-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);
	
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
	status.setValue(sStatus);
	
	if not self.isPC() then
		idelete.setVisibility(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(DB.createChild(nodeChar, "name", "string"), true);
		senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);

		hp.setLink(DB.createChild(nodeChar, "hp.total", "number"));
		hptemp.setLink(DB.createChild(nodeChar, "hp.temporary", "number"));
		nonlethal.setLink(DB.createChild(nodeChar, "hp.nonlethal", "number"));
		wounds.setLink(DB.createChild(nodeChar, "hp.wounds", "number"));

		if DataCommon.isPFRPG() then
			type.addSource(DB.getPath(nodeChar, "alignment"), true);
		else
			alignment.setLink(DB.createChild(nodeChar, "alignment", "string"));
		end
		type.addSource(DB.getPath(nodeChar, "size"), true);
		type.addSource(DB.getPath(nodeChar, "race"));
		
		cmb.setLink(DB.createChild(nodeChar, "attackbonus.cmb.total", "number"), true);
		
		ac_final.setLink(DB.createChild(nodeChar, "ac.totals.general", "number"), true);
		ac_touch.setLink(DB.createChild(nodeChar, "ac.totals.touch", "number"), true);
		ac_flatfooted.setLink(DB.createChild(nodeChar, "ac.totals.flatfooted", "number"), true);
		cmd.setLink(DB.createChild(nodeChar, "ac.totals.cmd", "number"), true);
		
		fortitudesave.setLink(DB.createChild(nodeChar, "saves.fortitude.total", "number"), true);
		reflexsave.setLink(DB.createChild(nodeChar, "saves.reflex.total", "number"), true);
		willsave.setLink(DB.createChild(nodeChar, "saves.will.total", "number"), true);
		
		sr.setLink(DB.createChild(nodeChar, "defenses.sr.total", "number"), true);

		init.setLink(DB.createChild(nodeChar, "initiative.total", "number"), true);
	end
end
