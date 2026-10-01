-- ============================================================================
-- vehicle-tuning / s_vehtuning.lua              (Fix #63)
-- ----------------------------------------------------------------------------
-- Server half of the Vehicles Tuning system restored from the old Owl client
-- (backupm/[rp]/vehicle-tuning/client_decompiled.lua).  The backup only kept
-- the client; the handlers below reproduce the exact event surface that client
-- talks to:
--
--   vehtuning:engine:purchase  (index)
--   vehtuning:tint:purchase    ("add"|"remove", price)
--   vehtuning:neon:purchase    (rowIndex, price)
--   vehtuning:backfire:purchase("add"|"remove", price)
--   vehtuning:replace_lock     ()
--
-- Every purchase re-validates, server-side: the player must be sitting in the
-- vehicle, own it (or be staff / a faction member for a faction car), be close
-- to one of TUNING.locations and have the money.
-- ============================================================================

local mysql = exports.mysql

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function notify(player, en, ar, ntype)
	if isElement(player) then
		exports.notifications:outputToPlayer(player, { en = en, ar = ar }, 4000, ntype or "info")
	end
end

local function getPlayerCharID(player)
	return tonumber(getElementData(player, "dbid")) or -1
end

function isNearTuningGarage(player, range)
	if not isElement(player) then return false end
	local px, py, pz = getElementPosition(player)
	range = range or 25
	for _, pos in ipairs(TUNING.locations) do
		if getDistanceBetweenPoints3D(px, py, pz, pos[1], pos[2], pos[3]) <= range then
			return true
		end
	end
	return false
end

function canPlayerTuneVehicle(player, veh)
	if not isElement(player) or not isElement(veh) then return false, "Invalid vehicle." end
	if exports.integration:isPlayerTrialAdmin(player) then return true end

	local owner = tonumber(getElementData(veh, "owner")) or -1
	if owner > 0 and owner == getPlayerCharID(player) then return true end

	local vehFaction = tonumber(getElementData(veh, "faction")) or -1
	local plFaction = tonumber(getElementData(player, "faction")) or -1
	if vehFaction > 0 and vehFaction == plFaction then return true end

	return false, "This is not your vehicle."
end

-- Rate limit: one purchase per 700ms per player (double-clicks on the gridlist
-- used to fire twice and charge twice).
local lastPurchase = {}
local function throttle(player)
	local now = getTickCount()
	if lastPurchase[player] and now - lastPurchase[player] < 700 then
		return false
	end
	lastPurchase[player] = now
	return true
end
addEventHandler("onPlayerQuit", root, function() lastPurchase[source] = nil end)

-- ---------------------------------------------------------------------------
-- persistence
--   vehicles_custom.handling -> the 33 value JSON the vehicle-manager loader reads
--   vehicles_custom.tuning   -> { engine = tier, neon = colour, neonOn = bool, backfire = bool }
-- ---------------------------------------------------------------------------
local function readTuningRow(vehID)
	local row = mysql:query_fetch_assoc("SELECT `handling`, `tuning` FROM `vehicles_custom` WHERE `id` = '" .. mysql:escape_string(vehID) .. "' LIMIT 1")
	return row or {}
end

local function writeTuningRow(vehID, handlingJSON, tuningTable)
	local sets = {}
	if handlingJSON then
		sets[#sets + 1] = "`handling`='" .. mysql:escape_string(handlingJSON) .. "'"
	end
	if tuningTable then
		sets[#sets + 1] = "`tuning`='" .. mysql:escape_string(toJSON(tuningTable)) .. "'"
	end
	if #sets == 0 then return false end
	return mysql:query_free("INSERT INTO `vehicles_custom` SET `id`='" .. tostring(tonumber(vehID)) .. "', " .. table.concat(sets, ", ")
		.. " ON DUPLICATE KEY UPDATE " .. table.concat(sets, ", ") .. ", `updatedate`=NOW()")
end

local function loadTuningData(vehID)
	local row = readTuningRow(vehID)
	local tuning = {}
	if row.tuning then
		local ok, decoded = pcall(fromJSON, row.tuning)
		if ok and type(decoded) == "table" then
			tuning = decoded
		end
	end
	if not tuning.engine then tuning.engine = 1 end
	if not tuning.neon then tuning.neon = 0 end
	if tuning.neonOn == nil then tuning.neonOn = false end
	if tuning.backfire == nil then tuning.backfire = false end
	return tuning
end

local function pushTuningData(veh, tuning)
	if not isElement(veh) then return end
	exports.anticheat:changeProtectedElementDataEx(veh, "neon", { tuning.neon, tuning.neonOn and 1 or 0 }, true)
	exports.anticheat:changeProtectedElementDataEx(veh, "backfire", tuning.backfire and true or false, true)
	exports.anticheat:changeProtectedElementDataEx(veh, "engine_tier", tuning.engine, false)
end

-- Serialize the live handling table in the exact order the vehicle-manager
-- loader (`loadHandlingToVeh`) expects.
local function serializeHandling(veh)
	local h = getVehicleHandling(veh)
	if not h then return nil end
	local out = {}
	for i, prop in ipairs(TUNING.handlingOrder) do
		out[i] = h[prop]
	end
	return toJSON(out)
end

-- ---------------------------------------------------------------------------
-- sync (client opened the panel / streamed the vehicle in)
-- ---------------------------------------------------------------------------
local function sendSync(player, veh)
	local dbid = tonumber(getElementData(veh, "dbid"))
	if not dbid then return end
	local tuning = loadTuningData(dbid)
	local h = getVehicleHandling(veh) or {}
	triggerClientEvent(player, TUNING.EVENTS.sync, player, {
		dbid      = dbid,
		engine    = tuning.engine,
		neon      = tuning.neon,
		neonOn    = tuning.neonOn and true or false,
		backfire  = tuning.backfire and true or false,
		tint      = getElementData(veh, "tinted") == true,
		handling  = {
			maxVelocity        = tonumber(h.maxVelocity) or 0,
			engineAcceleration = tonumber(h.engineAcceleration) or 0,
			engineInertia      = tonumber(h.engineInertia) or 0,
			driveType          = tostring(h.driveType or "-"),
			engineType         = tostring(h.engineType or "-"),
		},
	})
end

addEvent("vehtuning:request", true)
addEventHandler("vehtuning:request", root, function()
	local player = client
	local veh = getPedOccupiedVehicle(player)
	if veh and canPlayerTuneVehicle(player, veh) then
		sendSync(player, veh)
	end
end)

-- ---------------------------------------------------------------------------
-- Engines
-- ---------------------------------------------------------------------------
addEvent(TUNING.EVENTS.purchaseEngine, true)
addEventHandler(TUNING.EVENTS.purchaseEngine, root, function(index)
	local player = client
	local veh = getPedOccupiedVehicle(player)
	local tier = TUNING.engines[tonumber(index) or -1]
	if not veh or not tier then return end
	if not throttle(player) then return end

	local allowed, reason = canPlayerTuneVehicle(player, veh)
	if not allowed then notify(player, reason, "ليست سيارتك.", "error") return end
	if not isNearTuningGarage(player) then notify(player, "You are not at a tuning garage.", "أنت لست في كراج تعديل.", "error") return end

	local vtype = getVehicleType(veh)
	if vtype ~= "Automobile" and vtype ~= "Monster Truck" then
		notify(player, "You can't tune this vehicle", "لا يمكنك تعديل هذه المركبة", "error")
		return
	end

	if tier.price > 0 then
		local ok, paid = exports.global:takeMoney(player, tier.price)
		if not ok then
			notify(player, "You do not have enough money ($" .. exports.global:formatMoney(tier.price) .. ")",
				"ليس لديك مال كافٍ ($" .. exports.global:formatMoney(tier.price) .. ")", "error")
			return
		end
	end

	setVehicleHandling(veh, "maxVelocity", tier.maxVelocity)
	setVehicleHandling(veh, "engineAcceleration", tier.engineAcceleration)
	setVehicleHandling(veh, "engineInertia", tier.engineInertia)
	setVehicleHandling(veh, "driveType", tier.driveType)
	setVehicleHandling(veh, "engineType", tier.engineType)
	if type(tier.mass) == "number" then
		setVehicleHandling(veh, "mass", tier.mass)
	end

	local dbid = tonumber(getElementData(veh, "dbid"))
	local tuning = loadTuningData(dbid)
	tuning.engine = tonumber(index)
	writeTuningRow(dbid, serializeHandling(veh), tuning)
	pushTuningData(veh, tuning)

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning engine: " .. tier.name)
	end
	if exports["vehicle-manager"] then
		pcall(function() exports["vehicle-manager"]:addVehicleLogs(dbid, "vehtuning engine " .. tier.name, player) end)
	end

	notify(player, "Engine installed: " .. tier.name, "تم تركيب المحرك: " .. tier.name, "success")
	sendSync(player, veh)
end)

-- ---------------------------------------------------------------------------
-- Tinting  (delegates to the same storage the admin /setvehtint command uses)
-- ---------------------------------------------------------------------------
addEvent(TUNING.EVENTS.purchaseTint, true)
addEventHandler(TUNING.EVENTS.purchaseTint, root, function(mode, price)
	local player = client
	local veh = getPedOccupiedVehicle(player)
	if not veh then return end
	if not throttle(player) then return end

	local entry = TUNING.tinting[mode == "remove" and "remove" or "add"]
	local allowed, reason = canPlayerTuneVehicle(player, veh)
	if not allowed then notify(player, reason, "ليست سيارتك.", "error") return end
	if not isNearTuningGarage(player) then notify(player, "You are not at a tuning garage.", "أنت لست في كراج تعديل.", "error") return end

	local hasTint = getElementData(veh, "tinted") == true
	if entry == TUNING.tinting.add and hasTint then
		notify(player, "This vehicle is already tinted.", "هذه المركبة مظللة مسبقاً.", "warning")
		return
	end
	if entry == TUNING.tinting.remove and not hasTint then
		notify(player, "This vehicle has no tint.", "هذه المركبة غير مظللة.", "warning")
		return
	end

	local ok = exports.global:takeMoney(player, entry.price)
	if not ok then
		notify(player, "You do not have enough money ($" .. exports.global:formatMoney(entry.price) .. ")",
			"ليس لديك مال كافٍ ($" .. exports.global:formatMoney(entry.price) .. ")", "error")
		return
	end

	local dbid = tonumber(getElementData(veh, "dbid"))
	local add = (entry == TUNING.tinting.add)
	mysql:query_free("UPDATE vehicles SET tintedwindows = '" .. (add and "1" or "0") .. "' WHERE id='" .. mysql:escape_string(dbid) .. "'")
	exports.anticheat:changeProtectedElementDataEx(veh, "tinted", add, true)
	triggerClientEvent("tintWindows", veh)

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning tint " .. (add and "add" or "remove"))
	end
	notify(player, add and "Window tint added" or "Window tint removed",
		add and "تم تظليل النوافذ" or "تم إزالة تظليل النوافذ", "success")
	sendSync(player, veh)
end)

-- ---------------------------------------------------------------------------
-- Neon
-- ---------------------------------------------------------------------------
addEvent(TUNING.EVENTS.purchaseNeon, true)
addEventHandler(TUNING.EVENTS.purchaseNeon, root, function(rowIndex, price)
	local player = client
	local veh = getPedOccupiedVehicle(player)
	rowIndex = tonumber(rowIndex)
	if not veh or not rowIndex then return end
	if not throttle(player) then return end

	local entry = TUNING.neon[rowIndex]
	if not entry then return end
	local allowed, reason = canPlayerTuneVehicle(player, veh)
	if not allowed then notify(player, reason, "ليست سيارتك.", "error") return end
	if not isNearTuningGarage(player) then notify(player, "You are not at a tuning garage.", "أنت لست في كراج تعديل.", "error") return end

	if not isNeonModelSupported(getElementModel(veh)) then
		notify(player, "You cannot install neon lights on this vehicle", "لا يمكنك تركيب ضوء نيون على هذه السيارة", "error")
		return
	end

	local ok = exports.global:takeMoney(player, entry.price)
	if not ok then
		notify(player, "You do not have enough money ($" .. exports.global:formatMoney(entry.price) .. ")",
			"ليس لديك مال كافٍ ($" .. exports.global:formatMoney(entry.price) .. ")", "error")
		return
	end

	local dbid = tonumber(getElementData(veh, "dbid"))
	local tuning = loadTuningData(dbid)
	if rowIndex == 1 then
		tuning.neon = 0
		tuning.neonOn = false
	else
		tuning.neon = rowIndex - 1
		tuning.neonOn = true
	end
	writeTuningRow(dbid, nil, tuning)
	pushTuningData(veh, tuning)

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning neon: " .. entry.name)
	end
	notify(player, "Neon: " .. entry.name, "النيون: " .. entry.name, "success")
end)

-- ---------------------------------------------------------------------------
-- Back-fire
-- ---------------------------------------------------------------------------
addEvent(TUNING.EVENTS.purchaseBack, true)
addEventHandler(TUNING.EVENTS.purchaseBack, root, function(mode, price)
	local player = client
	local veh = getPedOccupiedVehicle(player)
	if not veh then return end
	if not throttle(player) then return end

	local add = (mode == "add")
	local entry = add and TUNING.backfire.add or TUNING.backfire.remove
	local allowed, reason = canPlayerTuneVehicle(player, veh)
	if not allowed then notify(player, reason, "ليست سيارتك.", "error") return end
	if not isNearTuningGarage(player) then notify(player, "You are not at a tuning garage.", "أنت لست في كراج تعديل.", "error") return end

	local has = getElementData(veh, "backfire") == true
	if add and has then
		notify(player, "This vehicle already has a back-fire.", "هذه المركبة تحتوي على باك فاير.", "warning") return
	end
	if (not add) and (not has) then
		notify(player, "This vehicle has no back-fire.", "هذه المركبة لا تحتوي على باك فاير.", "warning") return
	end

	local ok = exports.global:takeMoney(player, entry.price)
	if not ok then
		notify(player, "You do not have enough money ($" .. exports.global:formatMoney(entry.price) .. ")",
			"ليس لديك مال كافٍ ($" .. exports.global:formatMoney(entry.price) .. ")", "error")
		return
	end

	local dbid = tonumber(getElementData(veh, "dbid"))
	local tuning = loadTuningData(dbid)
	tuning.backfire = add
	writeTuningRow(dbid, nil, tuning)
	pushTuningData(veh, tuning)

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning backfire " .. (add and "add" or "remove"))
	end
	notify(player, add and "Back-fire installed" or "Back-fire removed",
		add and "تم تركيب الباك فاير" or "تم إزالة الباك فاير", "success")
end)

-- ---------------------------------------------------------------------------
-- Lock Replacement
--   Destroys every existing car key for this vehicle (all online players) and
--   hands a fresh key to the buyer - i.e. copies that leaked stop working.
-- ---------------------------------------------------------------------------
local KEY_ITEM = 3 -- item-system: car key (value = vehicle dbid)

local function takeAllKeysOf(vehID)
	local removed = 0
	for _, other in ipairs(getElementsByType("player")) do
		local guard = 0
		while exports.global:hasItem(other, KEY_ITEM, vehID) and guard < 20 do
			exports.global:takeItem(other, KEY_ITEM, vehID)
			removed = removed + 1
			guard = guard + 1
		end
	end
	return removed
end

addEvent(TUNING.EVENTS.replaceLock, true)
addEventHandler(TUNING.EVENTS.replaceLock, root, function()
	local player = client
	local veh = getPedOccupiedVehicle(player)
	if not veh then return end
	if not throttle(player) then return end

	local allowed, reason = canPlayerTuneVehicle(player, veh)
	if not allowed then notify(player, reason, "ليست سيارتك.", "error") return end
	if not isNearTuningGarage(player) then notify(player, "You are not at a tuning garage.", "أنت لست في كراج تعديل.", "error") return end

	local dbid = tonumber(getElementData(veh, "dbid"))
	if not dbid then return end

	local ok = exports.global:takeMoney(player, TUNING.lock.price)
	if not ok then
		notify(player, "You do not have enough money ($" .. exports.global:formatMoney(TUNING.lock.price) .. ")",
			"ليس لديك مال كافٍ ($" .. exports.global:formatMoney(TUNING.lock.price) .. ")", "error")
		return
	end

	takeAllKeysOf(dbid)
	exports.global:giveItem(player, KEY_ITEM, dbid)

	local owner = tonumber(getElementData(veh, "owner")) or -1
	if owner > 0 then
		local ownerPlayer = exports.global:getPlayerFromCharacterID(owner)
		if ownerPlayer and ownerPlayer ~= player then
			exports.global:giveItem(ownerPlayer, KEY_ITEM, dbid)
			notify(ownerPlayer, "The locks of your vehicle were changed - your new key is in your inventory.",
				"تم تغيير أقفال مركبتك - المفتاح الجديد في حقيبتك.", "info")
		end
	end

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning replace lock")
	end
	notify(player, "The lock has been replaced and old keys no longer work", "تم استبدال القفل والمفاتيح القديمة لم تعد تعمل", "success")
end)

-- ---------------------------------------------------------------------------
-- When a vehicle loads, push its stored tuning data onto the element so every
-- client can render neon / back-fire without an extra round trip.
-- ---------------------------------------------------------------------------
local function applyTuningTo(veh)
	if not isElement(veh) or getElementType(veh) ~= "vehicle" then return end
	local dbid = tonumber(getElementData(veh, "dbid"))
	if not dbid then return end
	pushTuningData(veh, loadTuningData(dbid))
end

local function applyTuningToAll()
	for _, veh in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
		applyTuningTo(veh)
	end
end

-- Vehicles are loaded asynchronously by vehicle-system, so give it a moment.
addEventHandler("onResourceStart", resourceRoot, function()
	setTimer(applyTuningToAll, 8000, 1)
end)

addEventHandler("onVehicleRespawn", root, function() applyTuningTo(source) end)
addEventHandler("onPlayerVehicleEnter", root, function(veh) applyTuningTo(veh) end)

-- ---------------------------------------------------------------------------
-- Staff handling editor (window[3] of the old client's panel)
--   H opens it, Enter applies it.  Restricted to staff and persisted in the
--   same vehicles_custom.handling column the engine presets use.
-- ---------------------------------------------------------------------------
local HANDLING_PROPS = {
	"maxVelocity", "engineAcceleration", "engineInertia", "suspensionLowerLimit",
	"suspensionFrontRearBias", "suspensionForceLevel", "suspensionDamping", "steeringLock",
	"dragCoeff", "brakeDeceleration", "brakeBias", "tractionMultiplier", "tractionBias",
}

addEvent("vehtuning:handling:requestValues", true)
addEventHandler("vehtuning:handling:requestValues", root, function()
	local player = client
	if not exports.integration:isPlayerTrialAdmin(player) then return end
	local veh = getPedOccupiedVehicle(player)
	if not veh then return end
	local h = getVehicleHandling(veh) or {}
	local out = {}
	for _, prop in ipairs(HANDLING_PROPS) do
		out[prop] = tonumber(h[prop]) or 0
	end
	triggerClientEvent(player, "vehtuning:handling:values", player, out)
end)

addEvent("vehtuning:handling:apply", true)
addEventHandler("vehtuning:handling:apply", root, function(values)
	local player = client
	if not exports.integration:isPlayerTrialAdmin(player) then return end
	local veh = getPedOccupiedVehicle(player)
	if not veh or type(values) ~= "table" then return end
	for _, prop in ipairs(HANDLING_PROPS) do
		local v = tonumber(values[prop])
		if v then setVehicleHandling(veh, prop, v) end
	end
	local dbid = tonumber(getElementData(veh, "dbid"))
	if dbid then
		writeTuningRow(dbid, serializeHandling(veh), nil)
	end
	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehtuning staff handling edit")
	end
	notify(player, "Vehicle handling updated", "تم تحديث معالجة المركبة", "success")
	sendSync(player, veh)
end)

-- Fallback: protect the keys from being tampered with client side
addEvent("vehtuning:clientSync", true)
addEventHandler("vehtuning:clientSync", root, function()
	local player = client
	local veh = getPedOccupiedVehicle(player)
	if veh then sendSync(player, veh) end
end)
