-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);
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