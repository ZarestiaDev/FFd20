-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);

	--[[
	for k,v in pairs(_tDataModuleSets) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end
	]]--
end

-- Shown in Modifiers window
-- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
_tModifierWindowPresets =
{
	{ 
		sCategory = "attack",
		tPresets = 
		{
			"ATT_TCH",
			"DEF_PCOVER",
			"ATT_FF",
			"DEF_COVER",
			"ATT_OPP",
			"DEF_SCOVER",
			"",
			"DEF_CONC",
			"",
			"DEF_TCONC",
		},
	},
	{ 
		sCategory = "damage",
		tPresets = { 
			"DMG_CRIT",
			"DMG_HALF",
		}
	},
};
_tModifierExclusionSets =
{
	{ "DEF_PCOVER", "DEF_COVER", "DEF_SCOVER" },
	{ "DEF_CONC", "DEF_TCONC" },
};

-- Shown in Campaign Setup window

--[[ Change later with names of the FFd20 modules
_tDataModuleSets = 
{
	["client"] =
	{
		{
			name = "3.5E - SRD",
			modules =
			{
				{ name = "3.5E Basic Rules" },
				{ name = "3.5E Spells" },
			},
		},
	},
	["host"] =
	{
		{
			name = "3.5E - SRD",
			modules =
			{
				{ name = "3.5E Basic Rules" },
				{ name = "3.5E Magic Items" },
				{ name = "3.5E Monsters" },
				{ name = "3.5E Spells" },
			},
		},
	},
};
]]--