-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local sCharPath;

local aAbility = {};
local aDefault = {};

function onInit()
	sCharPath = "";
	if charpath then
		sCharPath = charpath[1];
	end
	
	if ability then
		for _,v in ipairs(ability) do
			if v.source then
				local sDefault = "";
				if v.default then
					sDefault = v.default[1];
				end
				addAbilitySource(v.source[1], sDefault);
			end
		end
	end
	
	local nodeChar = window.getDatabaseNode();
	DB.addHandler(DB.getPath(nodeChar, "abilities"), "onChildUpdate", sourceupdate);
	DB.addHandler(DB.getPath(nodeChar, "level"), "onUpdate", sourceupdate);
	DB.addHandler(DB.getPath(nodeChar, "attackbonus.base"), "onUpdate", sourceupdate);
	
	super.onInit();
end

function onClose()
	local nodeChar = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(nodeChar, "abilities"), "onChildUpdate", sourceupdate);
	DB.removeHandler(DB.getPath(nodeChar, "level"), "onUpdate", sourceupdate);
	DB.removeHandler(DB.getPath(nodeChar, "attackbonus.base"), "onUpdate", sourceupdate);
end

function sourceupdate()
	if self.onSourceUpdate() then
		self.onSourceUpdate();
	end
end

function onSourceUpdate()
	local nAbility = getAbilityBonus();

	setValue(calculateSources() + nAbility);
end

function getAbilityBonus(nMaxMod)
	local nBonus = 0;
	
	local rActor = ActorManager.resolveActor(DB.getChild(window.getDatabaseNode(), sCharPath));
	
	for k, v in ipairs(aAbility) do
		local nAbilityBonus = ActorManagerFFd20.getAbilityBonus(rActor, getAbility(k));
		if k == 1 and nMaxMod and nMaxMod >= 0 then
			if nAbilityBonus > nMaxMod then
				nAbilityBonus = nMaxMod;
			end
		end
		nBonus = nBonus + nAbilityBonus;
	end
	
	return nBonus;
end

function getAbility(kAbility)
	local sAbility = "";
	if aAbility[kAbility] then
		sAbility = DB.getValue(window.getDatabaseNode(), sCharPath .. aAbility[kAbility], "");
	end
	if sAbility == "" and aDefault[kAbility] then
		sAbility = aDefault[kAbility];
	end
	
	return sAbility;
end

function addAbilitySource(sSource, sDefault)
	table.insert(aAbility, sSource);
	table.insert(aDefault, sDefault);
	
	addSource(sSource, "string");
end
