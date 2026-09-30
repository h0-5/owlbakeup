-- ============================================================================
-- vehicle-parking / s_vehicleparking.lua        (Fix #64)
-- ----------------------------------------------------------------------------
-- Server half of the old client's "Parking Area" panel.  Storage lives in the
-- new `vehicle_parking` table (see mods/deathmatch/pdz_missing_tables.sql):
--
--   vehicleID  PK   -> vehicles.id
--   lot        INT  -> 1-based index into PARKING.lots
--   slot       INT  -> 1-based index into that lot's slots
--   parked     DATETIME
--
-- A parked car is frozen and moved into PARKING.hiddenDimensionBase + lot, so
-- it is out of the world (safe from theft/damage) until it is taken out again.
-- The vehicles row is updated too, so a server restart reloads it in the same
-- state.
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

local function charID(player)
	return tonumber(getElementData(player, "dbid")) or -1
end

local function vehicleModelName(model)
	local name = getVehicleNameFromModel(tonumber(model) or 0)
	return name or ("Vehicle " .. tostring(model))
end

function isVehicleParked(vehID)
	vehID = tonumber(vehID)
	if not vehID then return false end
	local row = mysql:query_fetch_assoc("SELECT `lot` FROM `vehicle_parking` WHERE `vehicleID` = '" .. mysql:escape_string(vehID) .. "' LIMIT 1")
	return row and tonumber(row.lot) or false
end

function getParkedLotOf(vehID)
	return isVehicleParked(vehID)
end

-- Row of parked cars of a player inside one lot.
local function getPlayerParkedRows(player, lotID)
	local rows = mysql:query_rows_assoc("SELECT v.`id` AS `id`, v.`model` AS `model`, v.`plate` AS `plate`"
		.. " FROM `vehicle_parking` p"
		.. " LEFT JOIN `vehicles` v ON v.`id` = p.`vehicleID`"
		.. " WHERE p.`lot` = '" .. mysql:escape_string(lotID) .. "'"
		.. " AND v.`owner` = '" .. mysql:escape_string(charID(player)) .. "'"
		.. " AND v.`deleted` = 0"
		.. " ORDER BY p.`parked` ASC") or {}

	local out = {}
	for _, row in ipairs(rows) do
		out[#out + 1] = { ID = tonumber(row.id), Name = vehicleModelName(row.model) }
	end
	return out
end

local function freeSlot(lotID)
	local data = mysql:query_rows_assoc("SELECT `slot` FROM `vehicle_parking` WHERE `lot` = '" .. mysql:escape_string(lotID) .. "'") or {}
	local used = {}
	for _, row in ipairs(data) do
		used[tonumber(row.slot)] = true
	end
	local lot = getParkingLot(lotID)
	if not lot then return false end
	for i = 1, #lot.slots do
		if not used[i] then return i end
	end
	return false
end

local function persistRow(veh, x, y, z, rotz, dimension)
	local dbid = tonumber(getElementData(veh, "dbid"))
	if not dbid then return end
	mysql:query_free("UPDATE `vehicles` SET `x`='" .. mysql:escape_string(x) .. "', `y`='" .. mysql:escape_string(y)
		.. "', `z`='" .. mysql:escape_string(z) .. "', `rotz`='" .. mysql:escape_string(rotz)
		.. "', `dimension`='" .. mysql:escape_string(dimension) .. "', `currdimension`='" .. mysql:escape_string(dimension)
		.. "', `currx`='" .. mysql:escape_string(x) .. "', `curry`='" .. mysql:escape_string(y)
		.. "', `currz`='" .. mysql:escape_string(z) .. "', `currrz`='" .. mysql:escape_string(rotz)
		.. "' WHERE `id` = '" .. mysql:escape_string(dbid) .. "'")
end

-- ---------------------------------------------------------------------------
-- markers
-- ---------------------------------------------------------------------------
local function createLotMarkers()
	for index, lot in ipairs(PARKING.lots) do
		local marker = createMarker(lot.pos[1], lot.pos[2], lot.pos[3] - 1, "cylinder", PARKING.markerRadius, 41, 71, 204, 150)
		if marker then
			setElementDimension(marker, lot.dimension or 0)
			setElementData(marker, "vehparking:lot", index)
		end
		local blip = createBlip(lot.pos[1], lot.pos[2], lot.pos[3], PARKING.blip.icon)
		if blip then
			setElementData(blip, "blip:name", PARKING.blip.name)
		end
	end
end
addEventHandler("onResourceStart", resourceRoot, createLotMarkers)

-- ---------------------------------------------------------------------------
-- parking / taking out
-- ---------------------------------------------------------------------------
local function parkVehicle(player, veh, lotID)
	local lot = getParkingLot(lotID)
	if not lot then return end
	local dbid = tonumber(getElementData(veh, "dbid"))
	if not dbid then return end

	local slot = freeSlot(lotID)
	if not slot then
		notify(player, "This parking lot is full", "هذا الموقف ممتلئ", "error")
		return
	end

	local owner = tonumber(getElementData(veh, "owner")) or -1
	if owner ~= charID(player) and not exports.integration:isPlayerTrialAdmin(player) then
		notify(player, "This is not your vehicle", "هذه ليست مركبتك", "error")
		return
	end

	if tonumber(getElementData(veh, "Impounded")) == 1 then
		notify(player, "This vehicle is impounded", "هذه المركبة محتجزة", "error")
		return
	end

	if isVehicleParked(dbid) then
		notify(player, "This vehicle is already parked", "هذه المركبة موقوفة مسبقاً", "warning")
		return
	end

	mysql:query_free("INSERT INTO `vehicle_parking` SET `vehicleID`='" .. mysql:escape_string(dbid)
		.. "', `lot`='" .. mysql:escape_string(lotID) .. "', `slot`='" .. mysql:escape_string(slot)
		.. "', `parked`=NOW()")

	local spot = lot.slots[slot]
	exports.anticheat:changeProtectedElementDataEx(veh, "parked", tonumber(lotID), true)
	setElementFrozen(veh, true)
	setVehicleEngineState(veh, false)
	setVehicleLocked(veh, true)
	for _, other in ipairs(getElementsByType("player")) do
		if isPedInVehicle(other) and getPedOccupiedVehicle(other) == veh then
			removePedFromVehicle(other)
		end
	end
	setElementDimension(veh, getHiddenDimension(lotID))
	setElementInterior(veh, 0)
	setElementPosition(veh, spot[1], spot[2], spot[3])
	setElementRotation(veh, 0, 0, spot[4] or 0)
	persistRow(veh, spot[1], spot[2], spot[3], spot[4] or 0, getHiddenDimension(lotID))

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehparking park lot " .. tostring(lotID))
	end
	notify(player, "Your vehicle is now parked and safe from theft and damage",
		"سيارتك الآن موقوفة وآمنة من السرقة والتلف", "success")
end

local function takeVehicleOut(player, lotID, vehID)
	local lot = getParkingLot(lotID)
	vehID = tonumber(vehID)
	if not lot or not vehID then return end

	local row = mysql:query_fetch_assoc("SELECT p.`lot`, v.`owner` FROM `vehicle_parking` p"
		.. " LEFT JOIN `vehicles` v ON v.`id` = p.`vehicleID`"
		.. " WHERE p.`vehicleID` = '" .. mysql:escape_string(vehID) .. "' LIMIT 1")
	if not row or tonumber(row.lot) ~= tonumber(lotID) then
		notify(player, "That vehicle is not parked in this lot", "هذه المركبة ليست موقوفة في هذا الموقف", "error")
		return
	end
	if tonumber(row.owner) ~= charID(player) and not exports.integration:isPlayerTrialAdmin(player) then
		notify(player, "This is not your vehicle", "هذه ليست مركبتك", "error")
		return
	end

	mysql:query_free("DELETE FROM `vehicle_parking` WHERE `vehicleID` = '" .. mysql:escape_string(vehID) .. "'")

	local veh = exports.pool:getElement("vehicle", vehID)
	if not veh or not isElement(veh) then
		-- not loaded right now: it will spawn at the lot exit on its next load
		mysql:query_free("UPDATE `vehicles` SET `dimension`='" .. mysql:escape_string(lot.dimension or 0)
			.. "', `currdimension`='" .. mysql:escape_string(lot.dimension or 0)
			.. "', `x`='" .. mysql:escape_string(lot.spawn[1]) .. "', `y`='" .. mysql:escape_string(lot.spawn[2])
			.. "', `z`='" .. mysql:escape_string(lot.spawn[3]) .. "', `rotz`='" .. mysql:escape_string(lot.spawn[4] or 0)
			.. "' WHERE `id` = '" .. mysql:escape_string(vehID) .. "'")
		notify(player, "Your vehicle will be ready at the parking exit", "ستكون سيارتك جاهزة عند مخرج الموقف", "info")
		return
	end

	exports.anticheat:changeProtectedElementDataEx(veh, "parked", 0, true)
	setElementDimension(veh, lot.dimension or 0)
	setElementInterior(veh, 0)
	setElementPosition(veh, lot.spawn[1], lot.spawn[2], lot.spawn[3])
	setElementRotation(veh, 0, 0, lot.spawn[4] or 0)
	setElementFrozen(veh, false)
	setVehicleEngineState(veh, false)
	setVehicleLocked(veh, false)
	persistRow(veh, lot.spawn[1], lot.spawn[2], lot.spawn[3], lot.spawn[4] or 0, lot.dimension or 0)

	if exports.logs then
		exports.logs:dbLog(player, 6, { veh, player }, "vehparking get out lot " .. tostring(lotID))
	end
	notify(player, "Your vehicle is ready at the parking exit", "سيارتك جاهزة عند مخرج الموقف", "success")
end

-- ---------------------------------------------------------------------------
-- marker interaction (mirrors the old client's onClientMarkerHit branches)
-- ---------------------------------------------------------------------------
addEventHandler("onMarkerHit", resourceRoot, function(hitElement, matchingDimension)
	if getElementType(hitElement) ~= "player" then return end
	local lotID = getElementData(source, "vehparking:lot")
	if not lotID then return end
	if not matchingDimension then return end

	if isPedInVehicle(hitElement) then
		if getPedOccupiedVehicleSeat(hitElement) ~= 0 then return end
		local veh = getPedOccupiedVehicle(hitElement)
		if getPedOccupiedVehicle(hitElement) ~= veh then return end
		local owner = tonumber(getElementData(veh, "owner")) or -1
		if owner ~= charID(hitElement) and not exports.integration:isPlayerTrialAdmin(hitElement) then
			return
		end
		triggerClientEvent(hitElement, PARKING.EVENTS.showParking, hitElement, tonumber(lotID))
	else
		if not isPedOnGround(hitElement) then return end
		triggerClientEvent(hitElement, PARKING.EVENTS.showList, hitElement, getPlayerParkedRows(hitElement, tonumber(lotID)), tonumber(lotID))
	end
end)

addEvent(PARKING.EVENTS.park, true)
addEventHandler(PARKING.EVENTS.park, root, function(lotID)
	local player = client
	local lot = getParkingLot(lotID)
	if not lot then return end
	local veh = getPedOccupiedVehicle(player)
	if not veh then return end
	local x, y, z = getElementPosition(veh)
	if getDistanceBetweenPoints3D(x, y, z, lot.pos[1], lot.pos[2], lot.pos[3]) > 40 then
		notify(player, "You must be at the parking lot", "يجب أن تكون في الموقف", "error")
		return
	end
	parkVehicle(player, veh, tonumber(lotID))
end)

addEvent(PARKING.EVENTS.getOut, true)
addEventHandler(PARKING.EVENTS.getOut, root, function(vehicleID)
	local player = client
	-- the client sends only the vehicle id; the lot is whichever lot the player stands in
	local lotID = nil
	local markers = getElementsByType("marker", resourceRoot)
	local px, py, pz = getElementPosition(player)
	for _, marker in ipairs(markers) do
		local mx, my, mz = getElementPosition(marker)
		if getDistanceBetweenPoints3D(px, py, pz, mx, my, mz) <= PARKING.markerRadius * 2 then
			lotID = getElementData(marker, "vehparking:lot")
			break
		end
	end
	if not lotID then
		notify(player, "You are not at a parking lot", "أنت لست في موقف سيارات", "error")
		return
	end
	takeVehicleOut(player, tonumber(lotID), vehicleID)
end)

-- ---------------------------------------------------------------------------
-- keep parked vehicles parked (respawn/explode must not wake them up)
-- ---------------------------------------------------------------------------
addEventHandler("onVehicleRespawn", root, function()
	local veh = source
	local parkedLot = getElementData(veh, "parked")
	if not parkedLot or tonumber(parkedLot) == 0 then return end
	local lotID = tonumber(parkedLot)
	local lot = getParkingLot(lotID)
	if not lot then return end
	local row = mysql:query_fetch_assoc("SELECT `slot` FROM `vehicle_parking` WHERE `vehicleID` = '"
		.. mysql:escape_string(tonumber(getElementData(veh, "dbid")) or 0) .. "' LIMIT 1")
	local slot = row and tonumber(row.slot) or 1
	local spot = lot.slots[slot] or lot.slots[1]
	if not spot then return end
	setElementDimension(veh, getHiddenDimension(lotID))
	setElementPosition(veh, spot[1], spot[2], spot[3])
	setElementRotation(veh, 0, 0, spot[4] or 0)
	setElementFrozen(veh, true)
	setVehicleEngineState(veh, false)
end)

-- ---------------------------------------------------------------------------
-- restore on start: hide every parked vehicle straight away
-- ---------------------------------------------------------------------------
local function restoreParkedVehicles()
	local rows = mysql:query_rows_assoc("SELECT `vehicleID`, `lot`, `slot` FROM `vehicle_parking`") or {}
	for _, row in ipairs(rows) do
		local lotID = tonumber(row.lot)
		local lot = getParkingLot(lotID)
		if not lot then
			mysql:query_free("DELETE FROM `vehicle_parking` WHERE `vehicleID` = '" .. mysql:escape_string(row.vehicleID) .. "'")
		else
			local veh = exports.pool:getElement("vehicle", tonumber(row.vehicleID))
			if veh and isElement(veh) then
				local spot = lot.slots[tonumber(row.slot)] or lot.slots[1]
				exports.anticheat:changeProtectedElementDataEx(veh, "parked", lotID, true)
				setElementFrozen(veh, true)
				setVehicleEngineState(veh, false)
				setElementDimension(veh, getHiddenDimension(lotID))
				setElementPosition(veh, spot[1], spot[2], spot[3])
				setElementRotation(veh, 0, 0, spot[4] or 0)
			end
		end
	end
end
addEventHandler("onResourceStart", resourceRoot, function()
	setTimer(restoreParkedVehicles, 5000, 1)
end)

-- admin helper: /parkedlists
addCommandHandler("parkedlists", function(player)
	if not exports.integration:isPlayerTrialAdmin(player) then return end
	local rows = mysql:query_rows_assoc("SELECT * FROM `vehicle_parking` ORDER BY `lot`") or {}
	outputChatBox("[PARKING] " .. #rows .. " vehicle(s) stored:", player, 41, 71, 204)
	for _, row in ipairs(rows) do
		outputChatBox("  lot #" .. tostring(row.lot) .. " slot " .. tostring(row.slot) .. " -> vehicle #" .. tostring(row.vehicleID), player, 255, 255, 255)
	end
end)
