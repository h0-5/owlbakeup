-- owlbakeup Fix #61 - taxi job SERVER, rebuilt from the client contract
-- (Fix #54 phone pattern). The Owl server was never in the dump, so every
-- event name comes from c_taxi_owl.lua:
--   taxi:setLight(vehicle)   -> toggle the taxi roof light (meter button)
--   taxi:send_request        -> passenger requests a taxi (phone app)
--   taxi:accept_request(el)  -> driver accepts a pending request
--   taxi:request_sync        -> driver reopened the app, re-sync list
--   taxi:requests:sync       -> server pushes the pending list to drivers
--   taxi:on_accept_request   -> requester is told which driver accepted
-- Plus two server-side duties the client data implies:
--   * vehicle:total.distance bridge (the meter reads it every frame; the
--     repo odometer lives in vehicle-system) for occupied job taxies
--   * passenger payment on exit while the meter is running, straight from
--     the vehicle's taxi.meter = {startDistance, startTick, state, fare}

local taxiRequests = {} -- [requester] = {status = "pending", tick = n}

local function isTaxiDriver(player)
	return isElement(player) and getElementType(player) == "player" and getElementData(player, "job") == "Taxi Driver"
end

local function syncToDrivers(target)
	local payload = {}
	local now = getTickCount()
	for requester, request in pairs(taxiRequests) do
		if isElement(requester) and now - request.tick <= 300000 then
			payload[requester] = request
		else
			taxiRequests[requester] = nil
		end
	end
	if target then
		if isTaxiDriver(target) then
			triggerClientEvent(target, "taxi:requests:sync", target, payload)
		end
		return
	end
	for _, player in ipairs(getElementsByType("player")) do
		if isTaxiDriver(player) then
			triggerClientEvent(player, "taxi:requests:sync", player, payload)
		end
	end
end

addEvent("taxi:setLight", true)
addEventHandler("taxi:setLight", root, function(vehicle)
	local player = client
	if not player or not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" then
		return
	end
	if not isTaxiDriver(player) or getPedOccupiedVehicle(player) ~= vehicle then
		return
	end
	if getElementModel(vehicle) ~= 420 then
		return
	end
	setVehicleOverrideLights(vehicle, getVehicleOverrideLights(vehicle) == 2 and 1 or 2)
end)

addEvent("taxi:send_request", true)
addEventHandler("taxi:send_request", root, function()
	local player = client
	if not player or isTaxiDriver(player) or taxiRequests[player] then
		return
	end
	local characterID = tonumber(getElementData(player, "character:id"))
	if not characterID then
		return
	end
	taxiRequests[player] = { status = "pending", tick = getTickCount() }
	syncToDrivers()
end)

addEvent("taxi:accept_request", true)
addEventHandler("taxi:accept_request", root, function(requester)
	local driver = client
	if not driver or not isTaxiDriver(driver) or not isElement(requester) or not taxiRequests[requester] then
		return
	end
	taxiRequests[requester] = nil
	triggerClientEvent(requester, "taxi:on_accept_request", requester, driver)
	syncToDrivers()
end)

addEvent("taxi:request_sync", true)
addEventHandler("taxi:request_sync", root, function()
	syncToDrivers(client)
end)

addEventHandler("onPlayerQuit", root, function()
	taxiRequests[source] = nil
end)

-- passenger payment on exit while the meter is running
addEventHandler("onVehicleExit", root, function(player, seat)
	if seat == 0 or getElementType(source) ~= "vehicle" or getElementModel(source) ~= 420 then
		return
	end
	local meter = getElementData(source, "taxi.meter")
	if not meter or type(meter) ~= "table" or meter[3] ~= "started" then
		return
	end
	local driver = getVehicleOccupant(source, 0)
	if not isTaxiDriver(driver) then
		return
	end
	local distance = math.max((getElementData(source, "vehicle:total.distance") or 0) - (tonumber(meter[1]) or 0), 0)
	local cost = math.floor(distance * (tonumber(meter[4]) or 10))
	-- meter resets to the current odometer + stopped state
	setElementData(source, "taxi.meter", {
		getElementData(source, "vehicle:total.distance") or 0,
		getTickCount(),
		"stopped",
		tonumber(meter[4]) or 10
	})
	if cost <= 0 then
		return
	end
	local money = exports.global:getMoney(player)
	local paid = math.min(cost, tonumber(money) or 0)
	if paid <= 0 then
		exports.notifications:outputToPlayer(driver, "الراكب لم يستطع دفع الأجرة", 5000, "error")
		return
	end
	exports.global:takeMoney(player, paid, false)
	exports.global:giveMoney(driver, paid)
	exports.notifications:outputToPlayer(player, "تم دفع " .. paid .. "$ أجرة التاكسي", 5000, "info")
	exports.notifications:outputToPlayer(driver, "تلقت " .. paid .. "$ من الراكب", 5000, "info")
end)

-- vehicle:total.distance bridge for occupied job taxies (meter reads it)
setTimer(function()
	for _, player in ipairs(getElementsByType("player")) do
		if isTaxiDriver(player) then
			local vehicle = getPedOccupiedVehicle(player)
			if vehicle and getElementModel(vehicle) == 420 then
				local odometer = getElementData(vehicle, "odometer") or 0
				if getElementData(vehicle, "vehicle:total.distance") ~= odometer then
					setElementData(vehicle, "vehicle:total.distance", odometer)
				end
			end
		end
	end
end, 1000, 0)
