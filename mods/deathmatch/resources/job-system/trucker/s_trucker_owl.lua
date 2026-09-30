-- owlbakeup Fix #63 - Trucker job SERVER, rebuilt from the client contract
-- ([jobs]/trucker/client_decompiled.lua, Fix #54 phone pattern):
--   trucker:trailer:attach(truck)   -> hook the parked trailer to the truck
--                                      + attach:callback(trailer)
--   trucker:trailer:delivered(truck, trailer) -> validate + pay + destroy
--                                      trailer + delivered:callback(true)
-- The parked trailers (one per trailer marker, from the shared config) and
-- the flat delivery pay are documented reconstructions - the old server was
-- lost. No givePlayerJobEXP/giveJobSalary call exists in the decompile, so
-- the pay goes straight to the wallet + a delivery log row.

local mysql = exports.mysql

local markerTrailers = {} -- [marker element] = trailer vehicle
local busyTrailers = {} -- [trailer] = player currently hauling it

local TRAILER_MODELS = { 435, 450, 591 }

local function spawnTrailers()
        for index, point in ipairs(TRUCKER_CONFIG.trailer_markers) do
                local trailer = createVehicle(TRAILER_MODELS[(index - 1) % #TRAILER_MODELS + 1], point[1], point[2], point[3] + 1, 0, 0, math.random(0, 359))
                if trailer then
                        setVehicleEngineState(trailer, false)
                        markerTrailers[index] = trailer
                end
        end
end

local function nearestTrailerMarker(x, y, z)
        local best, bestDist = nil, 12
        for index, point in ipairs(TRUCKER_CONFIG.trailer_markers) do
                local dist = getDistanceBetweenPoints3D(x, y, z, point[1], point[2], point[3])
                if dist < bestDist then
                        best = index
                        bestDist = dist
                end
        end
        return best
end

addEvent("trucker:trailer:attach", true)
addEventHandler("trucker:trailer:attach", root, function(truck)
        local player = client
        if not player or not isElement(truck) then
                return
        end
        if getElementData(player, "job") ~= "Trucker" then
                return
        end
        if getElementType(truck) ~= "vehicle" or not TRUCKER_TRUCK_MODELS[getElementModel(truck)] then
                -- release the client's loading screen (its attach flow opened one)
                triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
                return
        end
        local tx, ty, tz = getElementPosition(truck)
        local index = nearestTrailerMarker(tx, ty, tz)
        local trailer = index and markerTrailers[index]
        if not trailer or busyTrailers[trailer] then
                triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
                return
        end
        busyTrailers[trailer] = player
        markerTrailers[index] = nil
        if not attachTrailerToVehicle(truck, trailer) then
                markerTrailers[index] = trailer
                busyTrailers[trailer] = nil
                triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
                return
        end
        triggerClientEvent(player, "trucker:trailer:attach:callback", player, trailer)
end)

addEvent("trucker:trailer:delivered", true)
addEventHandler("trucker:trailer:delivered", root, function(truck, trailer)
        local player = client
        if not player or not isElement(truck) or not isElement(trailer) then
                return
        end
        if getElementData(player, "job") ~= "Trucker" then
                return
        end
        if busyTrailers[trailer] ~= player then
                triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
                return
        end
        if getVehicleTowedByVehicle(truck) ~= trailer then
                triggerClientEvent(player, "trucker:trailer:delivered:callback", player, false)
                return
        end
        busyTrailers[trailer] = nil
        destroyElement(trailer)
        exports.global:giveMoney(player, TRUCKER_DELIVERY_PAY)
        local characterID = tonumber(getElementData(player, "character:id"))
        if characterID then
                mysql:query_free("INSERT INTO trucker_deliveries (character_id, paid, delivered_at) VALUES (" .. characterID .. ", " .. TRUCKER_DELIVERY_PAY .. ", '" .. os.date("%Y-%m-%d %H:%M:%S") .. "')")
        end
        exports.notifications:outputToPlayer(player, "تم توصيل المقطورة - أجرتك $" .. TRUCKER_DELIVERY_PAY, 5000, "success")
        triggerClientEvent(player, "trucker:trailer:delivered:callback", player, true)
        -- a new trailer rolls into the vacated marker after a while
        for index, point in ipairs(TRUCKER_CONFIG.trailer_markers) do
                if not markerTrailers[index] then
                        setTimer(function(index)
                                if not markerTrailers[index] then
                                        local point = TRUCKER_CONFIG.trailer_markers[index]
                                        local trailer = createVehicle(TRAILER_MODELS[(index - 1) % #TRAILER_MODELS + 1], point[1], point[2], point[3] + 1, 0, 0, math.random(0, 359))
                                        if trailer then
                                                setVehicleEngineState(trailer, false)
                                                markerTrailers[index] = trailer
                                        end
                                end
                        end, 60000, 1, index)
                        break
                end
        end
end)

addEventHandler("onPlayerQuit", root, function()
        for trailer, player in pairs(busyTrailers) do
                if player == source then
                        busyTrailers[trailer] = nil
                end
        end
end)

addEventHandler("onResourceStart", resourceRoot, function()
        mysql:query_free([[
                CREATE TABLE IF NOT EXISTS trucker_deliveries (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        character_id INT NOT NULL,
                        paid INT NOT NULL DEFAULT 0,
                        delivered_at VARCHAR(32) NOT NULL DEFAULT ''
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        spawnTrailers()
end)

addEventHandler("onResourceStop", resourceRoot, function()
        for _, trailer in pairs(markerTrailers) do
                if isElement(trailer) then
                        destroyElement(trailer)
                end
        end
end)
