-- Decompiled by Owl Decompiler v1.0 ([jobs]/drug-dealer/config_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) - VERBATIM, no repairs needed.
-- Shared client+server: the server builds the crafting markers and validates
-- plant events; the client reads plant_types in drug_dealer:startFarming.

plant_types = {
	Cannabis = { name = "Cannabis", model = 810 },
	Papaver = {
		name = "Papaver",
		model = 809,
		scale = 0.3
	}
}

crafting_markers = {
	{ -1119.29, -1623.405, 75, "Cannabis", 7, 181, 54 },
	{ -1119.29, -1621.461, 75, "Cannabis", 7, 181, 54 },
	{ -1119.29, -1619.577, 75, "Cannabis", 7, 181, 54 },
	{ -1116.65, -1616.4, 75, "Papaver", 180, 0, 0 },
	{ -1114.84, -1616.4, 75, "Papaver", 180, 0, 0 }
}
