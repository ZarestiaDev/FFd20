-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_ltos = {
	["strength"] = "STR",
	["dexterity"] = "DEX",
	["constitution"] = "CON",
	["intelligence"] = "INT",
	["wisdom"] = "WIS",
	["charisma"] = "CHA"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};

-- Saves
save_ltos = {
	["fortitude"] = "FORT",
	["reflex"] = "REF",
	["will"] = "WILL"
};

save_stol = {
	["FORT"] = "fortitude",
	["REF"] = "reflex",
	["WILL"] = "will"
};

-- Values for wound comparison
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for alignment comparison
alignment_lawchaos = {
	["lawful"] = 1,
	["chaotic"] = 3,
	["lg"] = 1,
	["ln"] = 1,
	["le"] = 1,
	["cg"] = 3,
	["cn"] = 3,
	["ce"] = 3,
};
alignment_goodevil = {
	["good"] = 1,
	["evil"] = 3,
	["lg"] = 1,
	["le"] = 3,
	["ng"] = 1,
	["ne"] = 3,
	["cg"] = 1,
	["ce"] = 3,
};
alignment_neutral = "n";

-- Values for size comparison
creaturesize = {
	["fine"] = -4,
	["diminutive"] = -3,
	["tiny"] = -2,
	["small"] = -1,
	["medium"] = 0,
	["large"] = 1,
	["huge"] = 2,
	["gargantuan"] = 3,
	["colossal"] = 4,
	["f"] = -4,
	["d"] = -3,
	["t"] = -2,
	["s"] = -1,
	["m"] = 0,
	["l"] = 1,
	["h"] = 2,
	["g"] = 3,
	["c"] = 4,
};

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
creaturetype = {
	["aberration"]  = {},
	["animal"]  = {},
	["construct"] = {
		immune = "bleed, blind, disease, death, doom, exhausted, fatigued, mindaffecting, necromancy, nonlethal, paralysis, poison, sleep, stunning"
	},
	["dragon"] = {
		immune = "paralysis, sleep"
	},
	["fey"] = {},
	["humanoid"] = {},
	["magical beast"] = {},
	["monstrous humanoid"] = {},
	["multiple"] = {},
	["ooze"] = {
		immune = "critical, flanking, gaze, illusion, mindaffecting, poison, sleep, paralysis, precision, polymorph, stunning",
		strong = "physical"
	},
	["outsider"] = {},
	["plant"] = {
		immune = "mindaffecting, paralysis, poison, polymorph, sleep, stunning"
	},
	["undead"] = {
		absorb = "shadow",
		immune = "bleed, death, disabled, disease, doom, exhausted, fatigued, mindaffecting, nonlethal, paralysis, poison, sleep, stunning, zombie",
		weakness = "holy"
	},
	["vermin"] = {
		immune = "mindaffecting"
	},
};
creaturesubtype = {
	["adlet"] = {},
	["aeon"] = {
		immune = "ice, poison, critical",
		resistance = "lightning 10, fire 10"
	},
	["agathion"] = {
		immune = "lightning, petrify",
		resistance = "ice 10"
	},
	["air"] = {},
	["amalj'aa"] = {},
	["angel"] = {
		immune = "earth, ice, petrify",
		resistance = "lightning 10, fire 10"
	},
	["aquatic"] = {},
	["archfiend"] = {},
	["archon"] = {
		immune = "lightning, petrify"
	},
	["asura"] = {
		immune = "curse, disease, poison",
		resistance = "earth 10, lightning 10"
	},
	["augmented"] = {},
	["automaton"] = {
		immune = "lightning",
		resistance = "ice 10"
	},
	["avian"] = {
		immune = "earth",
		weakness = "wind"
	},
	["azata"] = {
		immune = "lightning, petrify",
		resistance = "ice 10, fire 10"
	},
	["behemoth"] = {
		immune = "bleed, disease, fire, mindaffecting, paralysis, petrify, poison, polymorph",
		dr = "15 epic"
	},
	["bomb"] = {
		immune = "bleed, paralysis, poison, sleep"
	},
	["boss"] = {
		immune = "banish, daze, gravity, frog, mini, disabled, death, doom, paralysis, sleep, stop, stunning, petrify"
	},
	["catfolk"] = {},
	["centaur"] = {},
	["chaotic"] = {},
	["cie'th"] = {
		immune = "mindaffecting"
	},
	["clockwork"] = {
		weakness = "lightning"
	},
	["cold"] = {
		immune = "ice",
		weakness = "fire"
	},
	["colossus"] = {},
	["daemon"] = {
		immune = "earth, death, doom, disease, poison",
		resistance = "earth 10, ice 10, fire 10"
	},
	["dark folk"] = {},
	["deep one"] = {},
	["demodand"] = {
		immune = "earth, poison",
		resistance = "fire 10, ice 10"
	},
	["demon"] = {
		immune = "lightning, poison",
		resistance = "earth 10, ice 10, fire 10"
	},
	["devil"] = {
		immune = "fire, poison",
		resistance = "earth 10, ice 10"
	},
	["div"] = {
		immune = "fire, poison",
		resistance = "earth 10, lightning 10"
	},
	["dwarf"] = {},
	["earth"] = {
		immune = "earth",
		strong = "lightning",
		weakness = "wind"
	},
	["element"] = {},
	["elemental"] = {
		immune = "bleed, paralysis, poison, sleep, stunning, critical, flanking, precision"
	},
	["elf"] = {},
	["elvaan"] = {},
	["evil"] = {},
	["extraplanar"] = {},
	["familiar"] = {},
	["fire"] = {
		immune = "fire",
		strong = "ice",
		weakness = "water"
	},
	["giant"] = {},
	["gnoll"] = {},
	["gnome"] = {},
	["goblinoid"] = {},
	["godspawn"] = {},
	["good"] = {},
	["great old one"] = {},
	["halfling"] = {},
	["herald"] = {},
	["hive"] = {
		immune = "earth"
	},
	["holy"] = {
		immune = "holy",
		weakness = "shadow"
	},
	["human"] = {},
	["hume"] = {},
	["ice"] = {
		immune = "ice",
		strong = "wind",
		weakness = "fire"
	},
	["incorporeal"] = {},
	["inevitable"] = {},
	["kaiju"] = {
		immune = "death, doom, disease, fear",
		dr = "20 epic"
	},
	["kami"] = {
		immune = "bleed, mindaffecting, petrify, polymorph",
		resistance = "earth 10, lightning 10, fire 10"
	},
	["kasatha"] = {},
	["kitsune"] = {},
	["kobold"] = {},
	["kojin"] = {},
	["kyton"] = {
		immune = "ice"
	},
	["lawful"]  = {},
	["leshy"] = {
		immune = "lightning"
	},
	["living construct"] = {},
	["lightning"] = {
		immune = "lightning",
		strong = "water",
		weakness = "earth"
	},
	["machina"] = {
		weakness = "lightning"
	},
	["merfolk"] = {},
	["mini-boss"] = {},
	["moogle"] = {},
	["mortic"] = {},
	["mythic"] = {},
	["native"] = {},
	["nightshade"] = {},
	["non-elemental"] = {},
	["oni"] = {},
	["orc"] = {},
	["protean"] = {
		immune = "earth",
		resistance = "lightning 10"
	},
	["primal"] = {},
	["psychopomp"] = {
		immune = "death, doom, disease, poison",
		resistance = "ice 10, lightning 10"
	},
	["qlippoth"] = {
		immune = "ice, mindaffecting, poison",
		resistance = "earth 10, lightning 10, fire 10"
	},
	["quadav"] = {},
	["rakshasa"] = {},
	["ratfolk"] = {},
	["reptilian"] = {
		immune = "water",
		weakness = "ice"
	},
	["robot"] = {
		weakness = "lightning"
	},
	["samsaran"] = {},
	["sasquatch"] = {},
	["shapechanger"] = {},
	["sin eater"] = {
		immune = "death, doom, holy, mindaffecting, petrify",
		resistance = "lightning 10, fire 10",
		dr = "5 evil"
	},
	["super boss"] = {
		immune = "banish, gravity, frog, mini, disabled, death, doom, paralysis, sleep, stop, petrify"
	},
	["swarm"] = {},
	["shadow"] = {
		immune = "shadow",
		weakness = "holy"
	},
	["troop"] = {},
	["udaeus"] = {},
	["unbreathing"] = {},
	["vanara"] = {},
	["vanu vanu"] = {},
	["vishkanya"] = {},
	["water"] = {
		immune = "water",
		strong = "fire",
		weakness = "lightning"
	},
	["wayang"] = {},
	["wild hunt"] = {
		immune = "ice",
		resistance = "lightning 10, fire 10"
	},
	["wind"] = {
		immune = "wind",
		strong = "earth",
		weakness = "ice"
	}
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
-- NOTE: From rules, missing dying, staggered and disabled
conditions = {
	"antagonized",
	"banished",
	"blinded",
	"charmed",
	"climbing",
	"confused",
	"cowering",
	"cursed",
	"dazed",
	"dazzled",
	"deafened",
	"disabled",
	"diseased",
	"entangled",
	"exhausted",
	"fascinated",
	"fatigued",
	"flat-footed",
	"float",
	"frightened",
	"frozen",
	"grappled",
	"helpless",
	"immobilized",
	"imperil",
	"incorporeal",
	"invisible",
	"kneeling",
	"nauseated",
	"panicked",
	"paralyzed",
	"petrified",
	"pinned",
	"prone",
	"rebuked",
	"reflect",
	"reraise",
	"running",
	"shaken",
	"sickened",
	"silenced",
	"sitting",
	"sleep",
	"squeezing",
	"stable",
	"staggered",
	"static",
	"stunned",
	"turned",
	"unconscious",
	"weighted",
	"zombie"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"ABIL",
	"AC",
	"ATK",
	"CMB",
	"CMD",
	"DMG",
	"DMGS",
	"HEAL",
	"SAVE",
	"SKILL",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA",
	"FORT",
	"REF",
	"WILL"
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["confused"] = "cond_confused",
	["cowering"] = "cond_frightened",
	["dazed"] = "cond_dazed",
	["dazzled"] = "cond_dazed",
	["deafened"] = "cond_deafened",
	["entangled"] = "cond_restrained",
	["exhausted"] = "cond_weakened",
	["fascinated"] = "cond_charmed",
	["fatigued"] = "cond_weakened",
	["flat-footed"] = "cond_surprised",
	["flatfooted"] = "cond_surprised",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["helpless"] = "cond_helpless",
	["incorporeal"] = "cond_incorporeal",
	["invisible"] = "cond_invisible",
	["nauseated"] = "cond_sickened",
	["panicked"] = "cond_frightened",
	["paralyzed"] = "cond_paralyzed",
	["petrified"] = "cond_paralyzed",
	["pinned"] = "cond_pinned",
	["prone"] = "cond_prone",
	["rebuked"] = "cond_turned",
	["shaken"] = "cond_frightened",
	["sickened"] = "cond_sickened",
	["slowed"] = "cond_slowed",
	["stunned"] = "cond_stunned",
	["turned"] = "cond_turned",
	["unconscious"] = "cond_unconscious",
	-- Similar to conditions
	["ca"] = "cond_advantage",
	["grantca"] = "cond_disadvantage",
	["conc"] = "cond_conceal",
	["tconc"] = "cond_conceal",
	["cover"] = "cond_cover",
	["scover"] = "cond_cover",
};

-- Other visible effect types for token widgets
othercomps = {
	["CONC"] = "cond_conceal",
	["TCONC"] = "cond_conceal",
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["NLVL"] = "cond_penalty",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resistance",
	["WEAK"] = "cond_weakness",
	["STRONG"] = "cond_strong",
	["REGEN"] = "cond_regeneration",
	["FHEAL"] = "cond_regeneration",
	["DMGO"] = "cond_bleed",
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"CONC",
	"TCONC",
	"COVER",
	"SCOVER",
	"AC",
	"CMD",
	"SAVE",
	"ATK",
	"CMB",
	"DMG",
	"DMGS",
	"IMMUNE",
	"WEAKNESS",
	"STRONG",
	"RESIST",
	"SR",
	"SIMMUNE"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
energytypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"earth",
	"electricity",
	"fire",
	"holy",
	"ice",
	"lightning",
	"shadow",
	"sonic",
	"water",
	"wind",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative",
	"bleed",		-- SPECIAL DAMAGE TYPES
	"non-elemental"
};

immunetypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"earth",
	"electricity",
	"fire",
	"holy",
	"ice",
	"lightning",
	"shadow",
	"sonic",
	"water",
	"wind",
	"nonlethal",	-- SPECIAL DAMAGE TYPES
	"critical",
	"poison",		-- OTHER IMMUNITY TYPES
	"sleep",
	"paralysis",
	"petrify",
	"charm",
	"sleep",
	"fear",
	"disease",
	"mindaffecting",
	"bleed",
	"death",		-- SPECIAL DAMAGE TYPES
	"non-elemental"
};

dmgtypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"earth",
	"electricity",
	"fire",
	"holy",
	"ice",
	"lightning",
	"shadow",
	"sonic",
	"water",
	"wind",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold iron",
	"epic",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"chaotic",		-- ALIGNMENT DAMAGE TYPES
	"evil",
	"good",
	"lawful",
	"nonlethal",	-- MISC DAMAGE TYPE
	"spell",
	"critical",
	"precision",
	"bleed",		-- SPECIAL DAMAGE TYPES
	"immunebypass",
	"vorpal",
	"resistbypass",
	"resisthalved",
	"drbypass",
	"bypass",
	"non-elemental"
};

basicdmgtypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"earth",
	"electricity",
	"fire",
	"holy",
	"ice",
	"lightning",
	"shadow",
	"sonic",
	"water",
	"wind",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative",
	"bludgeoning", 	-- WEAPON PROPERTY DAMAGE TYPES
	"piercing",
	"slashing",
	"non-elemental"
};

specialdmgtypes = {
	"nonlethal",
	"spell",
	"critical",
	"precision",
	"bleed",		-- SPECIAL DAMAGE TYPES
	"immunebypass",
	"vorpal",
	"resistbypass",
	"resisthalved",
	"drbypass",
	"bypass"
};

-- Bonus types supported in power descriptions
bonustypes = {
	"alchemical",
	"armor",
	"circumstance",
	"competence",
	"deflection",
	"dodge",
	"enhancement",
	"equipment",
	"insight",
	"luck",
	"morale",
	"natural",
	"profane",
	"racial",
	"resistance",
	"sacred",
	"shield",
	"size",
	"trait",
};

stackablebonustypes = {
	"circumstance",
	"dodge"
};

-- Armor class bonus types
-- (Map text types to internal types)
actypes = {
	["dex"] = "dex",
	["armor"] = "armor",
	["shield"] = "shield",
	["natural"] = "natural",
	["dodge"] = "dodge",
	["deflection"] = "deflection",
	["size"] = "size",
};
acarmormatch = {
	"padded",
	"padded armor",
	"padded barding",
	"leather",
	"leather armor",
	"leather barding",
	"studded leather",
	"studded leather armor",
	"studded leather barding",
	"chain shirt",
	"chain shirt barding",
	"hide",
	"hide armor",
	"hide barding",
	"scale mail",
	"scale mail barding",
	"chainmail",
	"chainmail barding",
	"breastplate",
	"breastplate barding",
	"splint mail",
	"splint mail barding",
	"banded mail",
	"banded mail barding",
	"half-plate",
	"half-plate armor",
	"half-plate barding",
	"full plate",
	"full plate armor",
	"full plate barding",
	"plate barding",
	"bracers of armor",
	"mithral chain shirt",
};
acshieldmatch = {
	"buckler",
	"light shield",
	"light wooden shield",
	"light steel shield",
	"heavy shield",
	"heavy wooden shield",
	"heavy steel shield",
	"tower shield",
};
acdeflectionmatch = {
	"ring of protection"
};

-- Spell effects supported in spell descriptions
spelleffects = {
	"blinded",
	"confused",
	"cowering",
	"dazed",
	"dazzled",
	"deafened",
	"entangled",
	"exhausted",
	"fascinated",
	"frightened",
	"helpless",
	"invisible",
	"panicked",
	"paralyzed",
	"shaken",
	"sickened",
	"slowed",
	"stunned",
	"unconscious"
};

-- NPC damage properties
weapondmgtypes = {
	["axe"] = "slashing",
	["battleaxe"] = "slashing",
	["bolas"] = "bludgeoning,nonlethal",
	["chain"] = "piercing",
	["club"] = "bludgeoning",
	["crossbow"] = "piercing",
	["cutlass"] = "slashing",
	["dagger"] = "piercing,slashing",
	["dart"] = "piercing",
	["falchion"] = "slashing",
	["flail"] = "bludgeoning",
	["glaive"] = "slashing",
	["greataxe"] = "slashing",
	["greatclub"] = "bludgeoning",
	["greatsword"] = "slashing",
	["guisarme"] = "slashing",
	["halberd"] = "piercing,slashing",
	["hammer"] = "bludgeoning",
	["handaxe"] = "slashing",
	["javelin"] = "piercing",
	["kama"] = "slashing",
	["kukri"] = "slashing",
	["lance"] = "piercing",
	["longbow"] = "piercing",
	["longspear"] = "piercing",
	["longsword"] = "slashing",
	["mace"] = "bludgeoning",
	["morningstar"] = "bludgeoning,piercing",
	["nunchaku"] = "bludgeoning",
	["pick"] = "piercing",
	["quarterstaff"] = "bludgeoning",
	["ranseur"] = "piercing",
	["rapier"] = "piercing",
	["sai"] = "bludgeoning",
	["sap"] = "bludgeoning,nonlethal",
	["scimitar"] = "slashing",
	["scythe"] = "piercing,slashing",
	["shortbow"] = "piercing",
	["shortspear"] = "piercing",
	["shuriken"] = "piercing",
	["siangham"] = "piercing",
	["sickle"] = "slashing",
	["sling"] = "bludgeoning",
	["spear"] = "piercing",
	["sword"] = {["short"] = "piercing", ["*"] = "slashing"},
	["trident"] = "piercing",
	["urgrosh"] = "piercing,slashing",
	["waraxe"] = "slashing",
	["warhammer"] = "bludgeoning",
	["whip"] = "slashing"
}

naturaldmgtypes = {
	["arm"] = "bludgeoning",
	["bite"] = "piercing,slashing,bludgeoning",
	["butt"] = "bludgeoning",
	["claw"] =  "bludgeoning,slashing",
	["foreclaw"] =  "bludgeoning,slashing",
	["gore"] = "piercing",
	["hoof"] = "bludgeoning",
	["hoove"] = "bludgeoning",
	["horn"] = "piercing",
	["pincer"] = "bludgeoning",
	["quill"] = "piercing",
	["ram"] = "bludgeoning",
	["rock"] = "bludgeoning",
	["slam"] = "bludgeoning",
	["snake"] = "piercing,slashing,bludgeoning",
	["spike"] = "piercing",
	["stamp"] = "bludgeoning",
	["sting"] = "piercing",
	["swarm"] = "piercing,slashing,bludgeoning",
	["tail"] = "bludgeoning",
	["talon"] =  "slashing",
	["tendril"] = "bludgeoning",
	["tentacle"] = "bludgeoning",
	["wing"] = "bludgeoning",
}

-- Skill properties
sensesdata = {
	["Perception"] = {
			stat = "wisdom"
		},	
}

skilldata = {
	["Acrobatics"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Appraise"] = {
			stat = "intelligence"
		},
	["Bluff"] = {
			stat = "charisma"
		},
	["Craft"] = {
			sublabeling = true,
			stat = "intelligence"
		},
	["Diplomacy"] = {
			stat = "charisma"
		},
	["Disable Device"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1,
			trainedonly = 1
		},
	["Disguise"] = {
			stat = "charisma"
		},
	["Drive"] = {
			stat = "dexterity",
			trainedonly = 1
		},
	["Escape Artist"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Fly"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Handle Animal"] = {
			stat = "charisma",
			trainedonly = 1
		},
	["Heal"] = {
			stat = "wisdom"
		},
	["Intimidate"] = {
			stat = "charisma"
		},
	["Knowledge"] = {
			sublabeling = true,
			stat = "intelligence",
			trainedonly = 1
		},
	["Linguistics"] = {
			stat = "intelligence",
			trainedonly = 1
		},
	["Navigate"] = {
			stat = "intelligence"
		},
	["Perception"] = {
			stat = "wisdom"
		},
	["Perform"] = {
			sublabeling = true,
			stat = "charisma",
			trainedonly = 1
		},
	["Pilot"] = {
			stat = "dexterity",
			trainedonly = 1
		},
	["Profession"] = {
			sublabeling = true,
			stat = "wisdom",
			trainedonly = 1
		},
	["Repair"] = {
			stat = "intelligence"
		},
	["Ride"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Sense Motive"] = {
			stat = "wisdom"
		},
	["Sleight of Hand"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Spellcraft"] = {
			stat = "intelligence",
			trainedonly = 1
		},
	["Stealth"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Survival"] = {
			stat = "wisdom"
		},
	["Swim"] = {
			stat = "strength",
			armorcheckmultiplier = 1
		},
	["Use Magic Device"] = {
			stat = "charisma",
			trainedonly = 1
		}
}

-- Coin labels
currency = { "Cactuar", "Goldie", "Silvie", "Single" };

-- Party sheet drop down list data
psabilitydata = {
	"Strength",
	"Dexterity",
	"Constitution",
	"Intelligence",
	"Wisdom",
	"Charisma"
};

pssavedata = {
	"Fortitude",
	"Reflex",
	"Will"
};

psskilldata = {
	"Acrobatics",
	"Appraise",
	"Bluff",
	"Diplomacy",
	"Disable Device",
	"Disguise",
	"Drive",
	"Escape Artist",
	"Fly",
	"Handle Animal",
	"Heal",
	"Intimidate",
	"Knowledge (Arcana)",
	"Knowledge (Dungeoneering)",
	"Knowledge (Engineering)",
	"Knowledge (Geography)",
	"Knowledge (History)",
	"Knowledge (Local)",
	"Knowledge (Nature)",
	"Knowledge (Nobility)",
	"Knowledge (Planes)",
	"Knowledge (Religion)",
	"Knowledge (Technology)",
	"Linguistics",
	"Navigate",
	"Perception",
	"Pilot",
	"Repair",
	"Ride",
	"Sense Motive",
	"Sleight of Hand",
	"Spellcraft",
	"Stealth",
	"Survival",
	"Swim",
	"Use Magic Device"
};

-- PC/NPC Class properties

class_stol = {
	["brb"] = "barbarian",
	["brd"] = "bard",
	["clr"] = "cleric",
	["drd"] = "druid",
	["ftr"] = "fighter",
	["mnk"] = "monk",
	["pal"] = "paladin",
	["rgr"] = "ranger",
	["rog"] = "rogue",
	["sor"] = "sorcerer",
	["wiz"] = "wizard",
};

languages = {
	"Aegyllan",
	"Albhedian",
	"Antican",
	"Aquan",
	"Auran",
	"Auroran",
	"Banganese",
	"Burmecian",
	"Draconic",
	"Dwarven",
	"Elvaan",
	"Enochian",
	"Galkan",
	"Garif",
	"Goblin",
	"Ignan",
	"Kojin",
	"Lalafellan",
	"Lupin",
	"Mandragoran",
	"Mithran",
	"Moogle",
	"Numish",
	"Orcish",
	"Runic",
	"Qiqirn",
	"Quadav",
	"Queran",
	"Roegadyn",
	"Ronsaur",
	"Sahagin",
	"Seeq",
	"Sylvan",
	"Terran",
	"Thorian",
	"Tonberry",
	"Umbran",
	"Vanu",
	"Vieran",
	"Yagudo"
}