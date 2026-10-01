-- [Fix #160] A4 - missing vehicle staff command handlers
-- Owned exclusively by the matching Fix #160 task agent.
-- [Fix #160] commands here: /setvehjob, /respawnjobvehs, /setarmored, /setvehowner,
-- /unimpoundveh, /hideallnparkveh (gated in staff_manager/gates_fix160_task4.lua).
-- [Fix #160] /respawnveh stays in s_vehicle_commands.lua - it only gained plate lookup.

local mysql = exports.mysql

-- [Fix #160] job names shown by vehicle-system's /makeveh help
local jobNames = {
	[1] = "Delivery Driver",
	[2] = "Taxi Driver",
	[3] = "Bus Driver",
}

-- [Fix #160] shared "[Vehicle ID]" resolution + legacy admin gate, same style as setvehfaction
local function getVehicleFromCommand(thePlayer, theCommand, vehicleID)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return nil
	end
	local id = tonumber(vehicleID)
	if not id or id % 1 ~= 0 then
		outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID]", thePlayer, 255, 194, 14)
		return nil
	end
	local theVehicle = exports.pool:getElement("vehicle", id)
	if not theVehicle then
		outputChatBox("No vehicle with that ID found.", thePlayer, 255, 0, 0)
		return nil
	end
	return theVehicle, id
end

-- [Fix #160] /setvehjob [Vehicle ID] [Job ID] - right: setvehjob
-- [Fix #160] writes the vehicles.job column, then applies the same elementData + auto
-- respawn rules vehicle-system applies when it spawns a job vehicle.
function setVehJob(thePlayer, theCommand, vehicleID, jobID)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end
	if not vehicleID or not jobID then
		outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID] [Job ID] (-1 = none)", thePlayer, 255, 194, 14)
		outputChatBox("Job 1 = Delivery Driver, 2 = Taxi Driver, 3 = Bus Driver", thePlayer, 255, 194, 14)
		return
	end
	local theVehicle, vehID = getVehicleFromCommand(thePlayer, theCommand, vehicleID)
	if not theVehicle then
		return
	end
	local job = tonumber(jobID)
	if not job or job % 1 ~= 0 or job < -1 then
		outputChatBox("Invalid Job ID - use -1 for none or a positive job id.", thePlayer, 255, 0, 0)
		return
	end

	mysql:query_free("UPDATE `vehicles` SET `job`='" .. mysql:escape_string(job) .. "' WHERE `id`='" .. mysql:escape_string(vehID) .. "'")

	exports.anticheat:changeProtectedElementDataEx(theVehicle, "job", (job > 0) and job or 0, true)
	if job > 0 then
		toggleVehicleRespawn(theVehicle, true)
		setVehicleRespawnDelay(theVehicle, 60000)
		setVehicleIdleRespawnDelay(theVehicle, 15 * 60000)
	else
		toggleVehicleRespawn(theVehicle, false)
	end

	outputChatBox("Vehicle #" .. vehID .. " job set to " .. job .. (jobNames[job] and (" (" .. jobNames[job] .. ")") or "") .. ".", thePlayer, 255, 194, 14)
	addVehicleLogs(vehID, theCommand .. " " .. job, thePlayer)
	exports.logs:dbLog(thePlayer, 6, { theVehicle }, theCommand .. " " .. job)
end
addCommandHandler("setvehjob", setVehJob, false, false)

-- [Fix #160] /respawnjobvehs - right: vehicle.respawnalljobveh
-- [Fix #160] respawns every unoccupied vehicle with job > 0 (same unoccupied rules as /respawnciv)
function respawnJobVehicles(thePlayer, theCommand)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end

	local counter = 0
	for _, theVehicle in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
		local dbid = tonumber(getElementData(theVehicle, "dbid"))
		local job = tonumber(getElementData(theVehicle, "job")) or 0
		if dbid and dbid > 0 and job > 0 then
			if not getVehicleOccupant(theVehicle) and not getVehicleOccupant(theVehicle, 1)
					and not getVehicleOccupant(theVehicle, 2) and not getVehicleOccupant(theVehicle, 3)
					and not getVehicleTowingVehicle(theVehicle) and #getAttachedElements(theVehicle) == 0 then
				if isElementAttached(theVehicle) then
					detachElements(theVehicle)
					setElementCollisionsEnabled(theVehicle, true)
				end
				exports.anticheat:changeProtectedElementDataEx(theVehicle, 'i:left')
				exports.anticheat:changeProtectedElementDataEx(theVehicle, 'i:right')

				respawnTheVehicle(theVehicle)
				setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
				setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))
				counter = counter + 1
			end
		end
	end

	outputChatBox("Respawned " .. counter .. " job vehicle(s).", thePlayer, 255, 194, 14)
	exports.logs:dbLog(thePlayer, 6, { thePlayer }, theCommand .. " " .. counter)
end
addCommandHandler("respawnjobvehs", respawnJobVehicles, false, false)

-- [Fix #160] /setarmored [Vehicle ID] [0/1] - right: vehicle.setarmored
-- [Fix #160] toggles the vehicles.bulletproof column + damageproof state: the same
-- armour pattern /setbulletproof uses, but by vehicle id and without a target player.
function setVehArmored(thePlayer, theCommand, vehicleID, state)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end
	if not vehicleID then
		outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID] [0/1] (no state = toggle)", thePlayer, 255, 194, 14)
		return
	end
	local theVehicle, vehID = getVehicleFromCommand(thePlayer, theCommand, vehicleID)
	if not theVehicle then
		return
	end

	local newState
	if state == nil then
		newState = isVehicleDamageProof(theVehicle) and 0 or 1
	else
		newState = tonumber(state)
		if newState ~= 0 and newState ~= 1 then
			outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID] [0/1] (no state = toggle)", thePlayer, 255, 194, 14)
			return
		end
	end

	mysql:query_free("UPDATE `vehicles` SET `bulletproof`='" .. mysql:escape_string(newState) .. "' WHERE `id`='" .. mysql:escape_string(vehID) .. "'")

	local armored = (newState == 1) or (armoredCars[getElementModel(theVehicle)] == true)
	setVehicleDamageProof(theVehicle, armored)

	outputChatBox("Vehicle #" .. vehID .. (armored and " is now armored." or " is no longer armored."), thePlayer, 255, 194, 14)
	addVehicleLogs(vehID, theCommand .. " " .. newState, thePlayer)
	exports.logs:dbLog(thePlayer, 6, { theVehicle }, theCommand .. " " .. newState)
end
addCommandHandler("setarmored", setVehArmored, false, false)

-- [Fix #160] /setvehowner [Vehicle ID] [Character ID / Name] - right: setvehowner
-- [Fix #160] same flow as /setvehfaction: DB update -> F1 notify -> reloadVehicle -> restore pos.
function setVehOwner(thePlayer, theCommand, vehicleID, targetChar, ...)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end
	if not vehicleID or not targetChar then
		outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID] [Character ID / Name]", thePlayer, 255, 194, 14)
		return
	end
	local theVehicle, vehID = getVehicleFromCommand(thePlayer, theCommand, vehicleID)
	if not theVehicle then
		return
	end

	local charID, charName
	local asNumber = tonumber(targetChar)
	if asNumber and asNumber % 1 == 0 then
		local row = mysql:query_fetch_assoc("SELECT `id`, `charactername` FROM `characters` WHERE `id`='" .. mysql:escape_string(asNumber) .. "' LIMIT 1")
		if not row or not row.id then
			outputChatBox("No character with that ID found.", thePlayer, 255, 0, 0)
			return
		end
		charID = tonumber(row.id)
		charName = row.charactername
	else
		local name = targetChar
		if select("#", ...) > 0 then
			name = table.concat({ targetChar, ... }, "_")
		end
		name = tostring(name):gsub("%s+", "_")
		local row = mysql:query_fetch_assoc("SELECT `id`, `charactername` FROM `characters` WHERE `charactername`='" .. mysql:escape_string(name) .. "' LIMIT 1")
		if not row or not row.id then
			outputChatBox("No character with that name found.", thePlayer, 255, 0, 0)
			return
		end
		charID = tonumber(row.id)
		charName = row.charactername
	end

	local oldOwner = getElementData(theVehicle, "owner")
	local x, y, z = getElementPosition(theVehicle)
	local int = getElementInterior(theVehicle)
	local dim = getElementDimension(theVehicle)

	mysql:query_free("UPDATE `vehicles` SET `owner`='" .. mysql:escape_string(charID) .. "', `lastUsed`=NOW() WHERE `id`='" .. mysql:escape_string(vehID) .. "'")
	-- [Fix #152] the previous owner's open F1 drops the car row now
	notifyF1VehicleRemoved(oldOwner, vehID)
	exports.logs:dbLog(thePlayer, 6, { theVehicle }, theCommand .. " " .. charID)

	exports['vehicle-system']:reloadVehicle(vehID)
	local newVehicleElement = exports.pool:getElement("vehicle", vehID)
	if isElement(newVehicleElement) then
		setElementPosition(newVehicleElement, x, y, z)
		setElementInterior(newVehicleElement, int)
		setElementDimension(newVehicleElement, dim)
	end

	outputChatBox("Vehicle #" .. vehID .. " now belongs to " .. tostring(charName):gsub("_", " ") .. " (character ID " .. charID .. ").", thePlayer, 255, 194, 14)
	addVehicleLogs(vehID, theCommand .. " " .. charID, thePlayer)
end
addCommandHandler("setvehowner", setVehOwner, false, false)

-- [Fix #160] /unimpoundveh [Vehicle ID] - right: unimpoundveh
-- [Fix #160] releases an impounded vehicle (vehicles.Impounded column): clears the impound
-- flags and puts it back on its saved /park position the way tow-system's release does.
function unimpoundVehCommand(thePlayer, theCommand, vehicleID)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end
	if not vehicleID then
		outputChatBox("SYNTAX: /" .. theCommand .. " [Vehicle ID]", thePlayer, 255, 194, 14)
		return
	end
	local theVehicle, vehID = getVehicleFromCommand(thePlayer, theCommand, vehicleID)
	if not theVehicle then
		return
	end

	local impounded = tonumber(getElementData(theVehicle, "Impounded")) or 0
	if impounded == 0 then
		outputChatBox("Vehicle #" .. vehID .. " is not impounded.", thePlayer, 255, 0, 0)
		return
	end

	mysql:query_free("UPDATE `vehicles` SET `Impounded`='0' WHERE `id`='" .. mysql:escape_string(vehID) .. "'")
	exports.anticheat:changeProtectedElementDataEx(theVehicle, "Impounded", 0)
	exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, false)
	exports.anticheat:changeProtectedElementDataEx(theVehicle, "handbrake", 0, true)
	setElementFrozen(theVehicle, false)

	local keepArmor = isVehicleDamageProof(theVehicle) or (armoredCars[getElementModel(theVehicle)] == true)
	setVehicleDamageProof(theVehicle, keepArmor)

	if isElementAttached(theVehicle) then
		detachElements(theVehicle)
		setElementCollisionsEnabled(theVehicle, true)
	end

	respawnTheVehicle(theVehicle)
	setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
	setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

	outputChatBox("Vehicle #" .. vehID .. " was released from impound.", thePlayer, 0, 255, 0)
	addVehicleLogs(vehID, theCommand, thePlayer)
	exports.logs:dbLog(thePlayer, 6, { theVehicle }, theCommand)
end
addCommandHandler("unimpoundveh", unimpoundVehCommand, false, false)

-- [Fix #160] /hideallnparkveh - right: vehicle.hideallnparkveh
-- [Fix #160] a "public parking" vehicle = public stock (owner -2, no faction, no job,
-- not carshop stock) resting on its saved parking spot outdoors, unoccupied, not
-- impounded. Hide = vehicles.deleted='1' + world element removed (the pattern
-- /respawnall uses for carshop-parked cars); /restoreveh brings a hidden car back.
function hideAllNParkVehicles(thePlayer, theCommand)
	if not exports.integration:isPlayerTrialAdmin(thePlayer) then
		return
	end

	local hidden = 0
	for _, theVehicle in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
		local dbid = tonumber(getElementData(theVehicle, "dbid"))
		local owner = tonumber(getElementData(theVehicle, "owner"))
		local faction = tonumber(getElementData(theVehicle, "faction"))
		local job = tonumber(getElementData(theVehicle, "job")) or 0
		local impounded = tonumber(getElementData(theVehicle, "Impounded")) or 0
		local respawnposition = getElementData(theVehicle, "respawnposition")
		if dbid and dbid > 0 and owner == -2 and (tonumber(faction) or -1) <= 0
				and job == 0 and impounded == 0
				and getElementInterior(theVehicle) == 0 and getElementDimension(theVehicle) == 0
				and not getElementData(theVehicle, "carshop")
				and type(respawnposition) == "table"
				and not getVehicleOccupant(theVehicle) and not getVehicleOccupant(theVehicle, 1)
				and not getVehicleOccupant(theVehicle, 2) and not getVehicleOccupant(theVehicle, 3)
				and not getVehicleTowingVehicle(theVehicle) and not isElementAttached(theVehicle)
				and #getAttachedElements(theVehicle) == 0 then
			local x, y = getElementPosition(theVehicle)
			if math.abs(x - (tonumber(respawnposition[1]) or math.huge)) < 2
					and math.abs(y - (tonumber(respawnposition[2]) or math.huge)) < 2 then
				triggerEvent("onVehicleDelete", theVehicle)
				exports.logs:dbLog(thePlayer, 6, { theVehicle }, theCommand)
				mysql:query_free("UPDATE `vehicles` SET `deleted`='1' WHERE `id`='" .. mysql:escape_string(dbid) .. "'")
				destroyElement(theVehicle)
				hidden = hidden + 1
			end
		end
	end

	outputChatBox("Hidden " .. hidden .. " vehicle(s) parked in public parkings - /restoreveh [id] brings one back.", thePlayer, 255, 194, 14)
	exports.logs:dbLog(thePlayer, 6, { thePlayer }, theCommand .. " " .. hidden)
end
addCommandHandler("hideallnparkveh", hideAllNParkVehicles, false, false)
