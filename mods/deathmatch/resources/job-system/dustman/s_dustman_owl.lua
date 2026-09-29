-- owlbakeup Fix #63 - Dustman job SERVER, rebuilt from the client contract
-- ([jobs]/dustman-job/c_decompiled.lua, Fix #54 phone pattern):
--   * the client starts its trash loop the moment the job is taken while
--     sitting in a garbage truck (TRUCK_MODELS gate -> Trashmaster 408)
--   * every delivered trash = givePlayerJobEXP("Dustman", 1) via the job core
--     (client-initiated; the server re-validates the job name there)
--   * no giveJobSalary call exists in the decompile - the dustman earns EXP
--     only (salary stays 0; documented reconstruction)
-- The old server data (truck spawn points / trash positions) was lost with
-- the dump, so /startjob spawns a Trashmaster next to the player instead -
-- the client contract only needs the player IN a 408 for the loop to start.
-- Trash spawn points are reconstructed in c_dustman_owl.lua.

local jobTrucks = {} -- [player] = truck

local function destroyTruck(player)
        local truck = jobTrucks[player]
        if truck then
                jobTrucks[player] = nil
                if isElement(truck) then
                        destroyElement(truck)
                end
        end
end

-- fires IN ADDITION to the job core's own handler (both are root handlers)
addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
        local player = client
        if not player or getElementData(player, "job") ~= "Dustman" then
                return
        end
        local vehicle = getPedOccupiedVehicle(player)
        if vehicle and getElementModel(vehicle) == 408 then
                return -- already in a garbage truck, nothing to spawn
        end
        destroyTruck(player)
        local x, y, z = getElementPosition(player)
        local truck = createVehicle(408, x + 3, y, z + 1)
        if not truck then
                return
        end
        setElementData(truck, "vehicle:owner.name", "job:Dustman")
        setTimer(function(player, truck)
                if isElement(player) and isElement(truck) and getElementData(player, "job") == "Dustman" then
                        warpPedIntoVehicle(player, truck)
                end
        end, 200, 1, player, truck)
        jobTrucks[player] = truck
end)

addEvent("jobs:quit_job", true)
addEventHandler("jobs:quit_job", root, function()
        local player = client
        if player then
                destroyTruck(player)
        end
end)

addEventHandler("onPlayerQuit", root, function()
        destroyTruck(source)
end)
