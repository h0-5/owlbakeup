-- Decompiled by Owl Decompiler v1.0 ([jobs]/bus-driver/bus_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0 = the bus model SET (reconstructed: 431 Bus + 437 Coach).
--   * the decompile global stopJob() is renamed busStopJob() (single
--     resource collision rule, Fix #62 pattern).
--   * showStopPoint's createMarker(unpack(StopPoints[PointID])) would pass
--     the 4th element (the passenger-spot table) into createMarker's type
--     arg - the marker takes the first three coordinates explicitly. The
--     passenger spots stay in the data for the server (reconstructed use:
--     none in the client).
--   * PressALT's `getElementVelocity(v) ~= 0` compared only the FIRST
--     velocity component (a bus sliding on Y read as "stopped") - repaired
--     to check all three components.
-- The 14 stops (x, y, z + passenger spots) are VERBATIM from the decompile.

local BUS_MODELS = {
        [431] = true, -- Bus
        [437] = true -- Coach
}

PointID = 1
StopPoints = {
{1823.71, -1853.14, 12.5, {{1828.9608154297, -1852.88671875, 13.578125}, {1828.7816162109, -1850.4633789063, 13.578125}, {1828.9012451172, -1856.626953125, 13.578125}}},
{2087.92, -1776.44, 12.5, {{2092.583984375, -1777.8129882813, 13.546875}, {2092.7624511719, -1775.8077392578, 13.546875}, {2091.9462890625, -1779.8798828125, 13.546875}}},
{2259.52, -1661.46, 14.5, {{2259.4309082031, -1665.3950195313, 15.444325447083}, {2261.5402832031, -1665.6363525391, 15.428695678711}}},
{2513.87, -1289.8, 33.5, {{2518.3562011719, -1289.9761962891, 34.8515625}, {2518.0520019531, -1288.4815673828, 34.8515625}}},
{1970.84, -1458.92, 12.5, {{1970.6401367188, -1454.0592041016, 13.552314758301}, {1972.1387939453, -1454.2248535156, 13.55365562439}}},
{1527.46, -1676.12, 12.5, {{1523.1110839844, -1677.4431152344, 13.546875}, {1522.6812744141, -1679.2592773438, 13.546875}}},
{1315.28, -1702.4, 13, {{1318.8361816406, -1702.1793212891, 13.546875}, {1319.0723876953, -1700.4946289063, 13.546875}}},
{1427.85, -1031.87, 22.5, {{1427.5700683594, -1027.5958251953, 23.828125}, {1426.1805419922, -1026.5930175781, 23.828125}}},
{1020.08, -1037.43, 30.5, {{1020.2698364258, -1033.0958251953, 31.791244506836}, {1018.6152954102, -1032.8804931641, 31.800228118896}}},
{1207.28, -1328.65, 12.5, {{1212.1417236328, -1328.4129638672, 13.560200691223}, {1212.0718994141, -1330.205078125, 13.560638427734}}},
{541.62, -1256.58, 15.5, {{544.54144287109, -1259.5384521484, 16.760377883911}, {546.16186523438, -1258.8076171875, 16.802213668823}}},
{518.29, -1731.46, 10.8, {{517.91125488281, -1735.6462402344, 11.946187973022}, {519.88879394531, -1735.8493652344, 11.989227294922}}},
{1032.79, -2071.82, 12.2, {{1028.3774414063, -2070.2666015625, 13.132044792175}, {1027.7727050781, -2072.4108886719, 13.124306678772}}},
{1974.36, -2169.26, 12.5, {{1974.7344970703, -2172.5432128906, 13.540592193604}, {1976.0931396484, -2172.787109375, 13.540592193604}, {1973.7144775391, -2172.2092285156, 13.540592193604}}},}
function showStopPoint()
        if isElement(StopPointMarker) then
                return
        end
        local stop = StopPoints[PointID]
        StopPointMarker = createMarker(stop[1], stop[2], stop[3])
        StopPointBlip = createBlip(stop[1], stop[2], stop[3])
        setElementParent(StopPointBlip, StopPointMarker)
        exports.radar:findBestWay(stop[1], stop[2], stop[3])
end
addEventHandler("onClientMarkerHit", resourceRoot, function(player)
        if player ~= localPlayer then
                return
        end
        if getElementType(player) ~= "player" then
                return
        end
        if not isPedInVehicle(player) then
                return
        end
        if getVehicleController(getPedOccupiedVehicle(player)) ~= player then
                return
        end
        if BUS_MODELS[getElementModel(getPedOccupiedVehicle(player))] then
                setPedControlState(player, "handbrake", true)
                bindKey("space", "down", PressALT, source)
                exports.notifications:output({
                        en = "Press 'Space'",
                        ar = "'اضغط 'مسافة"
                }, 3000, "info")
        end
end)
addEventHandler("onClientMarkerLeave", resourceRoot, function(player)
        if player ~= localPlayer then
                return
        end
        if getElementType(player) ~= "player" then
                return
        end
        if not isPedInVehicle(player) then
                return
        end
        unbindKey("space", "down", PressALT, source)
end)
function PressALT(key, keyState, marker)
        if isPedInVehicle(localPlayer) then
                if getVehicleController(getPedOccupiedVehicle(localPlayer)) ~= localPlayer then
                        return
                end
                if BUS_MODELS[getElementModel(getPedOccupiedVehicle(localPlayer))] then
                        -- repair: all three velocity components (the decompile compared
                        -- only the first - a Y-moving bus read as stopped)
                        local vx, vy, vz = getElementVelocity(getPedOccupiedVehicle(localPlayer))
                        if vx ~= 0 or vy ~= 0 or vz ~= 0 then
                                return exports.notifications:output({
                                        en = "Stop the Bus first",
                                        ar = "أوقف الحافلة أولاً"
                                }, 4000, "warning")
                        end
                        if getElementHealth(getPedOccupiedVehicle(localPlayer)) < 500 then
                                return exports.notifications:output({
                                        en = "Your Bus is very damaged, repair it to complete work",
                                        ar = "حافلتك متضررة جداً، أصلحها لتكمل العمل"
                                }, 5000, "warning")
                        end
                        unbindKey("space", "down", PressALT, marker)
                        exports["job-system"]:givePlayerJobEXP("Bus Driver", 1)
                        destroyElement(getElementChild(marker, 0))
                        destroyElement(marker)
                        PointID = PointID + 1
                        if PointID > #StopPoints then
                                PointID = 1
                        end
                        showStopPoint()
                end
        end
end
addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
        if job ~= "Bus Driver" then
                return
        end
        if isElement(StopPointMarker) then
                outputChatBox("You already started the job.", 255, 0, 0)
                return
        end
        if isPedInVehicle(localPlayer) and BUS_MODELS[getElementModel(getPedOccupiedVehicle(localPlayer))] then
                StopPoints = shuffle(StopPoints)
                showStopPoint()
                outputChatBox("Go to the marker shown on the map.", 255, 255, 0)
        end
end)
addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
        if job ~= "Bus Driver" then
                return
        end
        outputChatBox("Follow These steps:", 255, 255, 0)
        outputChatBox("   1- Take a bus.", 255, 255, 0)
        outputChatBox("   2- Open your GPS.", 255, 255, 0)
        outputChatBox("   3- Type /startjob.", 255, 255, 0)
        outputChatBox("   4- Go to the marker shown on the map.", 255, 255, 0)
        outputChatBox("   5- Stop on the marker and press 'space'.", 255, 255, 0)
end)
addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
        if job == "Bus Driver" then
                busStopJob()
        end
end)
function busStopJob()
        unbindKey("space", "down", PressALT)
        if isElement(StopPointBlip) then
                destroyElement(StopPointBlip)
                destroyElement(StopPointMarker)
                StopPointBlip = nil
                StopPointMarker = nil
        end
end
addEventHandler("onClientPlayerSpawn", localPlayer, function()
        busStopJob()
end)
function shuffle(tbl)
        for i = #tbl, 2, -1 do
                tbl[i], tbl[math.random(1, i)] = tbl[math.random(1, i)], tbl[i]
        end
        return tbl
end
