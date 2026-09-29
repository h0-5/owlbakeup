-- Decompiled by Owl Decompiler v1.0 ([jobs]/farmer/config_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63). farms = {} is verbatim (the old
-- server shipped an empty farm list - the farm site is reconstructed in
-- s_farmer_owl.lua). The crops map to item IDs 235/236 (g_items.lua
-- [Fix #63] - the Owl inventory stored them by name with Properties).

farms = {}

plant_info = {
	Carrot = {
		sell_price = 55,
		item_props = { value = 6 }
	},
	Corn = {
		sell_price = 35,
		item_props = { value = 4 }
	}
}

plant_types = {
	Carrot = { name = "Carrot", model = 679 },
	Corn = { name = "Corn", model = 862 }
}

grow_duration = { Carrot = 300, Corn = 180 }

CROP_ITEM_IDS = {
	Carrot = 235,
	Corn = 236
}
