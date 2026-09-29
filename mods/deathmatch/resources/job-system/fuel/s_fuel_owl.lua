-- owlbakeup Fix #63 - Fuel Delivery SERVER, rebuilt from the client contract
-- ([jobs]/fuel-delivery/client_decompiled.lua, trucker pattern):
--   fuel-delivery:trailer:attach(truck) -> hook the parked tanker (584, the
--     trailer_model from the verbatim config) to the truck + attach:callback.
--     The tanker carries the "oil" elementData the client's fill/delivery
--     flow writes (30000 L fill, 5000 L/drop).
--   Truck gate: 514 Tank Truck (client), reconstructed spawn at the trailer
--   marker. No giveJobSalary in the decompile - EXP only.

local markerTrailer = nil -- the tanker at the (single) trailer marker

addEvent("fuel-delivery:trailer:attach", true)
addEventHandler("fuel-delivery:trailer:attach", root, function(truck)
	local player = client
	if not player or not isElement(truck) then
		return
	end
	if getElementData(player, "job") ~= "Fuel Deliverer" then
		return
	end
	if getElementType(truck) ~= "vehicle" or getElementModel(truck) ~= 514 then
		triggerClientEvent(player, "fuel-delivery:trailer:attach:callback", player, false)
		return
	end
	local tx, ty, tz = getElementPosition(truck)
	-- near the trailer marker (272.249, 1354.1943, 9 - verbatim config)
	if getDistanceBetweenPoints3D(tx, ty, tz, 272.249, 1354.1943, 9) > 15 then
		triggerClientEvent(player, "fuel-delivery:trailer:attach:callback", player, false)
		return
	end
	if not isElement(markerTrailer) then
		triggerClientEvent(player, "fuel-delivery:trailer:attach:callback", player, false)
		return
	end
	local trailer = markerTrailer
	markerTrailer = nil
	if not attachTrailerToVehicle(truck, trailer) then
		markerTrailer = trailer
		triggerClientEvent(player, "fuel-delivery:trailer:attach:callback", player, false)
		return
	end
	triggerClientEvent(player, "fuel-delivery:trailer:attach:callback", player, trailer)
end)

-- when the tanker is dropped anywhere, it returns to the marker after a while
addEventHandler("onTrailerDetach", root, function(towedBy, trailer)
	if trailer == markerTrailer then
		return
	end
	setTimer(function(trailer)
		if isElement(trailer) then
			-- reclaim as the marker tanker
			markerTrailer = trailer
		end
	end, 30000, 1, trailer)
end)

addEventHandler("onPlayerQuit", root, function()
	for _, vehicle in ipairs(getElementsByType("vehicle")) do
		local trailer = getVehicleTowedByVehicle(vehicle)
		if trailer and getElementData(trailer, "vehicle:owner.name") == "job:Fuel Deliverer" then
			local controller = getVehicleController(vehicle)
			if not isElement(controller) then
				destroyElement(trailer)
			end
		end
	end
	-- always keep one tanker available at the marker
	if not isElement(markerTrailer) then
		markerTrailer = createVehicle(584, 272.249, 1354.1943, 9 + 1, 0, 0, 180)
		if markerTrailer then
			setElementData(markerTrailer, "vehicle:owner.name", "job:Fuel Deliverer")
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	-- petrol tanker parked at the trailer marker (verbatim position) +
	-- a tank truck spawn next to it (reconstructed)
	markerTrailer = createVehicle(584, 272.249, 1354.1943, 9 + 1, 0, 0, 180)
	if markerTrailer then
		setElementData(markerTrailer, "vehicle:owner.name", "job:Fuel Deliverer")
	end
	local truck = createVehicle(514, 266.0, 1348.6, 10.5, 0, 0, 180)
	if truck then
		setElementData(truck, "vehicle:owner.name", "job:Fuel Deliverer")
	end
end)

addEventHandler("onResourceStop", resourceRoot, function()
	if isElement(markerTrailer) then
		destroyElement(markerTrailer)
	end
end)
