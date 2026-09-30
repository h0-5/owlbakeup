-- ============================================================================
-- vehicle-tuning / g_vehtuning.lua              (Fix #63)
-- ----------------------------------------------------------------------------
-- Shared configuration for the Vehicles Tuning system.
--
-- Restored 1:1 from the old Owl client backup:
--   /home/daytona/backupm/[rp]/vehicle-tuning/client_decompiled.lua
--
-- The old client only shipped the CLIENT half; every table below that it read
-- as a global (`Engines`, `neon_vehicles`, the tuning-marker list) came from the
-- server.  Those tables were re-authored here with the same shape the client
-- expects, and every number the client hard-codes (prices, gridlist layout,
-- handling scale of the progress bars) is kept identical.
-- ============================================================================

TUNING = {}

-- Titles of the left gridlist, in the old client's exact order.
TUNING.sections = { "Engines", "Vehicle Tinting", "Neon", "Back-fire", "Lock Replacement" }

-- ---------------------------------------------------------------------------
-- Engines
-- ---------------------------------------------------------------------------
-- The old client rendered:
--   col 1 = name            col 2 = "$" .. price (green)
--   Max Speed  progress bar = maxVelocity       / 360 * 100
--   Accel      progress bar = engineAcceleration / 100 * 100
-- and offered the row only on "Automobile" / "Monster Truck" vehicles.
-- Tiers are absolute handling presets (the panel prints the numbers directly).
TUNING.engines = {
	{ name = "Stock Engine",     price = 0,       maxVelocity = 160, engineAcceleration = 8.0,  engineInertia = 20, driveType = "R", engineType = "P" },
	{ name = "Street Engine",    price = 45000,   maxVelocity = 190, engineAcceleration = 11.0, engineInertia = 15, driveType = "R", engineType = "P" },
	{ name = "Sport Engine",     price = 140000,  maxVelocity = 225, engineAcceleration = 15.0, engineInertia = 11, driveType = "R", engineType = "P" },
	{ name = "Turbo Engine",     price = 320000,  maxVelocity = 260, engineAcceleration = 21.0, engineInertia = 8,  driveType = "R", engineType = "P" },
	{ name = "Supercharged",     price = 650000,  maxVelocity = 300, engineAcceleration = 30.0, engineInertia = 6,  driveType = "R", engineType = "P" },
	{ name = "Race Spec",        price = 1200000, maxVelocity = 340, engineAcceleration = 42.0, engineInertia = 4,  driveType = "4", engineType = "P" },
}

-- ---------------------------------------------------------------------------
-- Vehicle Tinting  (old client: add 20000 / remove 5000, green price column)
-- ---------------------------------------------------------------------------
TUNING.tinting = {
	add    = { name = "Add vehicle tinting",    price = 20000 },
	remove = { name = "Remove vehicle tinting", price = 5000 },
}

-- ---------------------------------------------------------------------------
-- Neon  (old client: Remove 1000 + 6 colours @ 50000)
-- Only these SA models may receive neon (the old client's `neon_vehicles`).
-- ---------------------------------------------------------------------------
TUNING.neon = {
	{ name = "Remove Neon", price = 1000 },
	{ name = "Red Neon",    price = 50000, rgb = { 255, 0, 0 } },
	{ name = "Blue Neon",   price = 50000, rgb = { 0, 0, 255 } },
	{ name = "Green Neon",  price = 50000, rgb = { 0, 255, 0 } },
	{ name = "Yellow Neon", price = 50000, rgb = { 255, 255, 0 } },
	{ name = "Pink Neon",   price = 50000, rgb = { 255, 0, 255 } },
	{ name = "White Neon",  price = 50000, rgb = { 255, 255, 255 } },
}

TUNING.neonModels = {
	[400] = true, [401] = true, [402] = true, [403] = true, [404] = true, [405] = true, [409] = true, [410] = true, [415] = true,
	[411] = true, [412] = true, [413] = true, [416] = true, [418] = true, [419] = true, [420] = true, [421] = true, [422] = true,
	[423] = true, [426] = true, [428] = true, [429] = true, [431] = true, [434] = true, [436] = true, [437] = true, [438] = true,
	[439] = true, [440] = true, [442] = true, [445] = true, [446] = true, [451] = true, [458] = true, [459] = true, [466] = true,
	[467] = true, [470] = true, [474] = true, [475] = true, [477] = true, [479] = true, [480] = true, [482] = true, [483] = true,
	[489] = true, [490] = true, [491] = true, [492] = true, [494] = true, [495] = true, [496] = true, [498] = true, [499] = true,
	[500] = true, [502] = true, [503] = true, [504] = true, [505] = true, [506] = true, [507] = true, [508] = true, [516] = true,
	[517] = true, [518] = true, [525] = true, [526] = true, [527] = true, [528] = true, [529] = true, [533] = true, [534] = true,
	[535] = true, [536] = true, [540] = true, [541] = true, [542] = true, [543] = true, [545] = true, [546] = true, [547] = true,
	[549] = true, [550] = true, [551] = true, [552] = true, [554] = true, [555] = true, [558] = true, [559] = true, [560] = true,
	[561] = true, [562] = true, [565] = true, [566] = true, [567] = true, [575] = true, [576] = true, [579] = true, [580] = true,
	[582] = true, [585] = true, [587] = true, [588] = true, [589] = true, [596] = true, [597] = true, [598] = true, [599] = true,
	[600] = true, [602] = true, [603] = true, [604] = true, [605] = true, [609] = true,
}

-- Bespoke attachment offsets, copied verbatim from the old client's addNeon()
-- (two tubes per car, mirrored on X).  Models without an entry fall back to
-- TUNING.neonDefaultOffset.
TUNING.neonOffsets = {
	[401] = { 0.9, 0, -0.55 }, [402] = { 1, 0, -0.63 }, [411] = { 0.95, 0, -0.63 }, [412] = { 0.95, 0, -0.64 },
	[415] = { 0.9, 0, -0.57 }, [416] = { 0.9, 0, -0.7 }, [419] = { 0.97, 0.1, -0.61 }, [421] = { 0.95, 0.1, -0.66 },
	[422] = { 0.85, 0, -0.66 }, [429] = { 0.9, 0, -0.51 }, [431] = { 1.3, 1.8, -0.77 }, [434] = { 0.9, 0, -0.6 },
	[437] = { 1.3, 1.8, -0.77 }, [438] = { 0.95, 0, -0.72 }, [445] = { 0.95, 0, -0.55 }, [459] = { 0.8, 0, -0.78 },
	[466] = { 0.9, 0, -0.57 }, [477] = { 0.99, 0, -0.57 }, [480] = { 0.72, 0, -0.53 }, [482] = { 0.95, 0.05, -0.82 },
	[483] = { 0.85, 0.3, -0.8 }, [490] = { 0.9, 0.1, -0.66 }, [491] = { 0.9, 0, -0.61 }, [492] = { 0.93, 0, -0.5 },
	[496] = { 0.85, 0, -0.5 }, [498] = { 1.1, 0, -0.7 }, [499] = { 0.8, 0, -0.6 }, [504] = { 0.95, 0, -0.55 },
	[507] = { 1.1, 0, -0.65 }, [518] = { 0.95, 0.15, -0.5 }, [526] = { 0.93, 0, -0.61 }, [527] = { 0.92, 0.15, -0.47 },
	[528] = { 0.9, 0.15, -0.59 }, [529] = { 1, -0.05, -0.46 }, [533] = { 0.93, 0, -0.51 }, [535] = { 0.95, 0, -0.6 },
	[536] = { 0.95, 0, -0.6 }, [541] = { 0.9, 0, -0.45 }, [542] = { 0.9, 0, -0.57 }, [554] = { 0.9, 0, -0.6 },
	[555] = { 0.8, 0, -0.5 }, [562] = { 0.95, 0.15, -0.48 }, [565] = { 0.83, 0, -0.47 }, [575] = { 0.9, 0, -0.38 },
	[585] = { 1.05, 0, -0.42 }, [587] = { 1.05, -0.05, -0.61 }, [588] = { 1.4, 0, -0.71 }, [589] = { 0.92, 0.1, -0.43 },
	[602] = { 0.95, 0, -0.6 }, [604] = { 0.9, 0, -0.57 }, [609] = { 1.1, 0, -0.7 },
}
TUNING.neonDefaultOffset = { 0.9, 0, -0.6 }

-- Object model the old client spawned for a neon tube.  Its DFF/TXD used to be
-- streamed by the `mods` resource under this key ("customModel"), so when the
-- model pack is installed the tube is the original art.  Without it we fall
-- back to a coloured light (see c_vehtuning.lua).
TUNING.neonObjectModel = 1940

-- The DFF/TXD pack itself is not part of the backup, so the tubes are drawn
-- as lights (c_vehtuning.lua).  Flip this to true once the customModel pack
-- ships with the server and the original tube art is streamed again.
TUNING.neonUseObjects = false

-- ---------------------------------------------------------------------------
-- Back-fire  (old client: add 500000 / remove 5000)
-- ---------------------------------------------------------------------------
TUNING.backfire = {
	add    = { name = "Add Back-fire",    price = 500000 },
	remove = { name = "Remove Back-fire", price = 5000 },
}

-- ---------------------------------------------------------------------------
-- Lock Replacement  (old client: 10000, single row)
-- ---------------------------------------------------------------------------
TUNING.lock = { name = "Replace the lock", price = 10000 }

-- ---------------------------------------------------------------------------
-- Tuning garages (markers + blips).  The old client received this list from the
-- server and created createMarker(unpack(pos)) + a blip named
-- "كراج تعديل السيارات" for each entry.  Coordinates are the SA mod garages.
-- ---------------------------------------------------------------------------
TUNING.locations = {
	{ 1041.3, -1025.4, 31.1 },   -- Transfender, Temple (LS)
	{ -1934.4, 239.5, 34.6 },    -- Loco Low Co, Willowfield (LS)
	{ -2714.4, 218.2, 4.0 },     -- Wheel Arch Angels, Ocean Flats (SF)
	{ -1906.9, 287.2, 41.3 },    -- Transfender, Doherty (SF)
	{ 2644.7, 1064.4, 10.6 },    -- Transfender, Redsands East (LV)
	{ 615.6, -1254.4, 15.2 },    -- Transfender, Idlewood (LS)
}

TUNING.blipName = { en = "Vehicle Tuning Garage", ar = "كراج تعديل السيارات" }

-- ---------------------------------------------------------------------------
-- Handling JSON layout used by vehicle-manager (`vehicles_custom.handling`).
-- Copied from vehicle-manager/vehicle-handling-editor/g_handling_values.lua so
-- a tuned engine is stored in the format the loader already understands.
-- ---------------------------------------------------------------------------
TUNING.handlingOrder = {
	"mass", "turnMass", "dragCoeff", "centerOfMass", "percentSubmerged", "tractionMultiplier", "tractionLoss",
	"tractionBias", "numberOfGears", "maxVelocity", "engineAcceleration", "engineInertia", "driveType", "engineType",
	"brakeDeceleration", "brakeBias", "ABS", "steeringLock", "suspensionForceLevel", "suspensionDamping",
	"suspensionHighSpeedDamping", "suspensionUpperLimit", "suspensionLowerLimit", "suspensionFrontRearBias",
	"suspensionAntiDiveMultiplier", "seatOffsetDistance", "collisionDamageMultiplier", "monetary", "modelFlags",
	"handlingFlags", "headLight", "tailLight", "animGroup",
}

-- Event names (single source of truth, both sides)
TUNING.EVENTS = {
	purchaseEngine = "vehtuning:engine:purchase",
	purchaseTint   = "vehtuning:tint:purchase",
	purchaseNeon   = "vehtuning:neon:purchase",
	purchaseBack   = "vehtuning:backfire:purchase",
	replaceLock    = "vehtuning:replace_lock",
	sync           = "vehtuning:sync",
	notify         = "vehtuning:notify",
}

function isEngineTierValid(index)
	return type(index) == "number" and TUNING.engines[index] ~= nil
end

function isNeonModelSupported(model)
	return TUNING.neonModels[tonumber(model) or -1] == true
end

function getVehicleTuning()
	return TUNING
end
