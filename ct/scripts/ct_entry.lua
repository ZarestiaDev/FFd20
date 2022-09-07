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
		name.setLink(nodeChar.createChild("name", "string"), true);
		senses.setLink(nodeChar.createChild("senses", "string"), true);

		hp.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		nonlethal.setLink(nodeChar.createChild("hp.nonlethal", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));

		type.addSource(DB.getPath(nodeChar, "alignment"), true);
		type.addSource(DB.getPath(nodeChar, "size"), true);
		type.addSource(DB.getPath(nodeChar, "race"));
		
		cmb.setLink(nodeChar.createChild("attackbonus.cmb.total", "number"), true);
		
		ac_final.setLink(nodeChar.createChild("ac.totals.general", "number"), true);
		ac_touch.setLink(nodeChar.createChild("ac.totals.touch", "number"), true);
		ac_flatfooted.setLink(nodeChar.createChild("ac.totals.flatfooted", "number"), true);
		cmd.setLink(nodeChar.createChild("ac.totals.cmd", "number"), true);
		
		fortitudesave.setLink(nodeChar.createChild("saves.fortitude.total", "number"), true);
		reflexsave.setLink(nodeChar.createChild("saves.reflex.total", "number"), true);
		willsave.setLink(nodeChar.createChild("saves.will.total", "number"), true);
		
		sr.setLink(nodeChar.createChild("defenses.sr.total", "number"), true);

		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
	end
end

function onSectionChanged(sKey)
	local sSectionName = "sub_" .. sKey;

	local cSection = self[sSectionName];
	if cSection then
		local bShow = self.getSectionToggle(sKey);

		if bShow then
			local sSectionClass = "ct_section_" .. sKey;
			if sKey == "active" then
				if self.isRecordType("npc") then
					sSectionClass = sSectionClass .. "_npc";
				end
			end
			cSection.setValue(sSectionClass, getDatabaseNode());
		else
			cSection.setValue("", "");
		end
		cSection.setVisible(bShow);
	end

	local sSummaryName = "summary_" .. sKey;
	local cSummary = self[sSummaryName];
	if cSummary then
		cSummary.onToggle();
	end
end
