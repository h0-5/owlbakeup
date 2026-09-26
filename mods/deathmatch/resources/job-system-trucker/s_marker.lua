-- s_marker.lua
-- Restored from an encrypted original. Implements the trailer delivery events
-- fired by the trucker client (see the decompiled trucker client):
--   triggerServerEvent("trucker:trailer:attach", player, truck)
--   triggerServerEvent("trucker:trailer:delivered", player, truck, trailer)
-- and answers with the callbacks the client listens for:
--   "trucker:trailer:attach:callback"    (trailer element)
--   "trucker:trailer:delivered:callback" (success flag, used to unfade the camera)

local TRAILER_SEARCH_RADIUS = 40
local DELIVERY_MAX_DISTANCE = 25

local function isValidTruckerSetup(player, truck)
	if not player or not isElement(player) or not isElement(truck) or getElementType(truck) ~= "vehicle" then
		return false
	end
	if getElementData(player, "job") ~= 1 then
		return false
	end
	if getPedOccupiedVehicle(player) ~= truck or getVehicleController(truck) ~= player then
		return false
	end
	-- trucker trucks are tracked in s_trucker_job.lua (same resource environment)
	if not truckerJobVehicleInfo or not truckerJobVehicleInfo[getElementModel(truck)] then
		return false
	end
	return true
end

-- collects trailers that are not currently attached to another vehicle
local function findFreeTrailer(tx, ty, tz)
	local attached = {}
	for _, vehicle in ipairs(getElementsByType("vehicle")) do
		local towed = getVehicleTowedByVehicle(vehicle)
		if towed then
			attached[towed] = true
		end
	end

	local best, bestDist = nil, TRAILER_SEARCH_RADIUS
	for _, vehicle in ipairs(getElementsByType("vehicle")) do
		if getVehicleType(vehicle) == "Trailer" and not attached[vehicle] then
			local vx, vy, vz = getElementPosition(vehicle)
			local dist = getDistanceBetweenPoints3D(tx, ty, tz, vx, vy, vz)
			if dist <= bestDist then
				best, bestDist = vehicle, dist
			end
		end
	end

	return best
end

addEvent("trucker:trailer:attach", true)
addEventHandler("trucker:trailer:attach", root,
	function(truck)
		local player = client
		if not isValidTruckerSetup(player, truck) then
			return
		end

		-- already towing something: confirm with the current trailer
		local existing = getVehicleTowedByVehicle(truck)
		if existing then
			triggerClientEvent(player, "trucker:trailer:attach:callback", player, existing)
			return
		end

		local tx, ty, tz = getElementPosition(truck)
		local trailer = findFreeTrailer(tx, ty, tz)
		if not trailer then
			outputChatBox("No trailer available next to you.", player, 255, 0, 0)
			-- the client is fading its camera while waiting; always unfade it
			triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
			return
		end

		if not attachVehicle(trailer, truck) then
			outputChatBox("Could not attach the trailer.", player, 255, 0, 0)
			triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
			return
		end

		triggerClientEvent(player, "trucker:trailer:attach:callback", player, trailer)
	end
)

addEvent("trucker:trailer:delivered", true)
addEventHandler("trucker:trailer:delivered", root,
	function(truck, trailer)
		local player = client
		if not isValidTruckerSetup(player, truck) then
			return
		end

		-- the trailer must be attached to the truck or at least right next to it
		local delivered = false
		if isElement(trailer) then
			if getVehicleTowedByVehicle(truck) == trailer then
				delivered = true
			else
				local tx, ty, tz = getElementPosition(truck)
				local rx, ry, rz = getElementPosition(trailer)
				delivered = getDistanceBetweenPoints3D(tx, ty, tz, rx, ry, rz) <= DELIVERY_MAX_DISTANCE
			end
		end

		triggerClientEvent(player, "trucker:trailer:delivered:callback", player, delivered)
	end
)
