-- Decompiled by Owl Decompiler v1.0 ([jobs]/gunsmith/config_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) - the factory data is VERBATIM.
-- REPO ADAPTATION (documented): the Owl inventory stored items by NAME with
-- Type/Properties; this repo's item-system uses numeric IDs (g_items.lua),
-- so FACTORY_ITEM_IDS maps every Name the config references to the new IDs
-- [Fix #63] (218-234). Weapons assemble into item 115 "Weapon"
-- ("weaponID:ammo", WeapModel from the config's Properties).

factory = {
	int = 2,
	dim = 756,
	crafting_markers = {
		{ 2543.201, -1295.981, 1043 },
		{ 2556.221, -1295.85, 1043 },
		{ 2543.185, -1290.918, 1043 },
		{ 2556.137, -1291.004, 1043 }
	},
	assembling_markers = {
		{ 2544.048, -1302.652, 1043 },
		{ 2560.163, -1302.573, 1043 },
		{ 2558.138, -1284.732, 1043 },
		{ 2550.13, -1284.746, 1043 }
	},
	machine_cooldown = 2400,
	craft_items = {
		{
			title = "c4 صنعاة قابلة",
			item = { Name = "c4", Type = "", Properties = { Model = 1654 } },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Wire", Type = "", Quantity = 1 },
				{ Name = "Electronic Chip", Type = "", Quantity = 1 },
				{ Name = "Explosive Powder", Type = "", Quantity = 1 }
			},
			cost = 2000,
			duration = 10,
			required_level = 2
		},
		{
			title = "Deagle Barrel صنعاة قطعة",
			item = { Name = "Deagle Barrel", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 2 },
				{ Name = "Copper", Type = "Material", Quantity = 1 },
				{ Name = "Lead", Type = "Material", Quantity = 1 },
				{ Name = "Aluminium", Type = "Material", Quantity = 1 }
			},
			cost = 3000,
			duration = 10,
			required_level = 4
		},
		{
			title = "Deagle Receiver صنعاة قطعة",
			item = { Name = "Deagle Receiver", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 2 },
				{ Name = "Copper", Type = "Material", Quantity = 1 },
				{ Name = "Lead", Type = "Material", Quantity = 1 },
				{ Name = "Aluminium", Type = "Material", Quantity = 1 }
			},
			cost = 5000,
			duration = 10,
			required_level = 5
		},
		{
			title = "AK-47 Magazine صنعاة قطعة",
			item = { Name = "AK-47 Magazine", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 4 },
				{ Name = "Aluminium", Type = "Material", Quantity = 1 }
			},
			cost = 5000,
			duration = 10,
			required_level = 8
		},
		{
			title = "AK-47 Receiver صنعاة قطعة",
			item = { Name = "AK-47 Receiver", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 4 },
				{ Name = "Copper", Type = "Material", Quantity = 1 },
				{ Name = "Lead", Type = "Material", Quantity = 1 },
				{ Name = "Aluminium", Type = "Material", Quantity = 1 },
				{ Name = "Wood", Type = "Material", Quantity = 1 }
			},
			cost = 5000,
			duration = 10,
			required_level = 8
		},
		{
			title = "AK-47 Stock صنعاة قطعة",
			item = { Name = "AK-47 Stock", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 3 },
				{ Name = "Wood", Type = "Material", Quantity = 2 }
			},
			cost = 5000,
			duration = 10,
			required_level = 8
		},
		{
			title = "AK-47 Wooden Shield صنعاة قطعة",
			item = { Name = "AK-47 Wooden Shield", Type = "WeaponPart", Properties = {}, SpecialProperties = {} },
			requirements = {
				{ Name = "Screwdriver", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Hammer", Type = "", Quantity = 1, TempUse = true },
				{ Name = "Iron", Type = "Material", Quantity = 1 },
				{ Name = "Wood", Type = "Material", Quantity = 4 }
			},
			cost = 2000,
			duration = 10,
			required_level = 8
		}
	},
	assembly_items = {
		{
			title = "AK-47 تجميع سلاح",
			item = {
				Name = "AK-47",
				Type = "Weapon",
				Properties = { Model = 355, WeapModel = 30, AmmoType = "762mm" },
				SpecialProperties = { Ammo = 1 }
			},
			parts = {
				{ code = "magazine", offset = { 345, 190 }, item_name = "AK-47 Magazine" },
				{ code = "receiver", offset = { 250, 110 }, item_name = "AK-47 Receiver" },
				{ code = "stock", offset = { 100, 135 }, item_name = "AK-47 Stock" },
				{ code = "wooden_shield", offset = { 480, 100 }, item_name = "AK-47 Wooden Shield" }
			},
			cost = 0,
			duration = 10,
			required_level = 25
		},
		{
			title = "Deagle تجميع سلاح",
			item = {
				Name = "Deagle",
				Type = "Weapon",
				Properties = { Model = 348, WeapModel = 24, AmmoType = "9mm" },
				SpecialProperties = { Ammo = 1 }
			},
			parts = {
				{ code = "barrel", offset = { 450, 55 }, item_name = "Deagle Barrel" },
				{ code = "receiver", offset = { 240, 110 }, item_name = "Deagle Receiver" }
			},
			cost = 0,
			duration = 5,
			required_level = 15
		}
	}
}

FACTORY_ITEM_IDS = {
	["Screwdriver"] = 218,
	["Hammer"] = 219,
	["Wire"] = 220,
	["Electronic Chip"] = 221,
	["Explosive Powder"] = 222,
	["Iron"] = 223,
	["Copper"] = 224,
	["Lead"] = 225,
	["Aluminium"] = 226,
	["Wood"] = 227,
	["Deagle Barrel"] = 228,
	["Deagle Receiver"] = 229,
	["AK-47 Magazine"] = 230,
	["AK-47 Receiver"] = 231,
	["AK-47 Stock"] = 232,
	["AK-47 Wooden Shield"] = 233,
	["c4"] = 234
}
