-- Decompiled by Owl Decompiler v1.0 ([jobs]/fuel-delivery/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * the decompile inlined the config TABLE TWICE (once per creation loop)
--     - restored as the single CONFIG table (all 16 gas-station locations,
--       the trailer + filling markers and trailer_model 584 are VERBATIM).
--   * var0..var5 merged identities restored:
--       JOB_NAME ("Fuel Deliverer"), TRUCK_MODELS (514 Tank Truck gate),
--       trailerMarkers / fillingMarkers maps, stopIndex (var5), SCALE.
--   * the event/key prefixes were literal "fuel-delivery" (proven by the
--     addEvent("fuel-delivery" .. ":trailer:attach:callback") concat).
--   * marker creation inlined ({})[createMarker(...)] lost the local map -
--     restored.
--   * oil-barrel.png: asset not in the dump - generated placeholder ships.

local SCALE -- screen scale (drawJobInfo)

local CONFIG = {
        trailer_markers = {
                { 272.249, 1354.1943, 9 }
        },
        filling_markers = {
                { 260.5302, 1384.0273, 9 }
        },
        locations = {
                { position = { -1454.29, 1865.1289, 31.1328 } },
                { position = { -1307.59, 2705.9423, 48.5625 } },
                { position = { 2126.692, 2747.7753, 9.3203 } },
                { position = { 2202.407, 2487.3017, 9.3203 } },
                { position = { 1594.982, 2211.9384, 9.3203 } },
                { position = { 2129.343, 920.24707, 9.3203 } },
                { position = { 1395.3, 454.27832, 18.5443 } },
                { position = { 650.2373, -564.6337, 14.789 } },
                { position = { 989.874, -926.1289, 40.6796 } },
                { position = { 1941.671, -1787.006, 11.8828 } },
                { position = { -98.4365, -1186.132, 0.55274 } },
                { position = { -1540, -2747.023, 47.0351 } },
                { position = { -2252.22, -2556.828, 30.3851 } },
                { position = { -2037.38, 174.66406, 26.4208 } },
                { position = { -1703.15, 392.40527, 5.67968 } },
                { position = { -2424.37, 983.48535, 43.8 } }
        },
        trailer_model = 584
}

local JOB_NAME = "Fuel Deliverer"
local TRUCK_MODELS = {
        [514] = true -- Tank Truck
}

local trailerMarkers = {}
local fillingMarkers = {}
local stopIndex = 1

local sx, sy = guiGetScreenSize()
local SCALE = sy / 1080

for index, markerPos in ipairs(CONFIG.trailer_markers) do
        trailerMarkers[createMarker(unpack(markerPos))] = index
end
for index, markerPos in ipairs(CONFIG.filling_markers) do
        fillingMarkers[createMarker(unpack(markerPos))] = index
end

function showStopPoint()
        if isElement(StopPointMarker) then
                return
        end
        StopPointMarker = createMarker(unpack(CONFIG.locations[stopIndex].position))
        StopPointBlip = createBlip(unpack(CONFIG.locations[stopIndex].position))
        setElementParent(StopPointBlip, StopPointMarker)
        exports.radar:findBestWay(unpack(CONFIG.locations[stopIndex].position))
        exports.notifications:output({
                en = "Go to the yellow marker shown on the map",
                ar = "اذهب للعلامة الصفراء على الخريطة"
        }, 10000, "info")
end

addEventHandler("onClientMarkerHit", resourceRoot, function(player)
        if player ~= localPlayer then
                return
        end
        if getElementData(localPlayer, "job") ~= JOB_NAME then
                return
        end
        if trailerMarkers[source] then
                if not isPedInVehicle(player) then
                        exports.notifications:output({
                                en = "You have to bring a truck for the job",
                                ar = "عليك إحضار شاحنة خاصة بالوظيفة"
                        }, 3500, "warning")
                        return
                end
                if getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)) then
                        return
                end
                bindKey("lshift", "down", attachTrailer, source)
                exports.notifications:showKeyDescription("fuel-delivery:attach_trailer", "Left Shift", "Take Trailer")
        elseif fillingMarkers[source] then
                if not isPedInVehicle(player) then
                        exports.notifications:output({
                                en = "You have to bring a truck for the job",
                                ar = "عليك إحضار شاحنة خاصة بالوظيفة"
                        }, 3500, "warning")
                        return
                end
                if not getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)) or getElementModel(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer))) ~= CONFIG.trailer_model then
                        exports.notifications:output({
                                en = "No trailer attached",
                                ar = "لاتوجد مقطورة متصلة"
                        }, 3500, "warning")
                        return
                end
                bindKey("lshift", "down", fillTank, source, getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)))
                exports.notifications:showKeyDescription("fuel-delivery:fill_tank", "Left Shift", "Fill the tank")
        elseif StopPointMarker then
                if not isPedInVehicle(player) then
                        return
                end
                if not getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)) or getElementModel(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer))) ~= CONFIG.trailer_model then
                        exports.notifications:output({
                                en = "No trailer attached",
                                ar = "لاتوجد مقطورة متصلة"
                        }, 3500, "warning")
                        return
                end
                if not getElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil") or getElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil") < 5000 then
                        exports.notifications:output({
                                en = "There is not enough petrol in the tank (5000 Liters)",
                                ar = "(5000 Liters) لا يوجد وقود كافي في الخزان"
                        }, 3500, "warning")
                        return
                end
                setElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil", getElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil") - 5000)
                exports["job-system"]:givePlayerJobEXP(JOB_NAME, 1)
                destroyElement(StopPointMarker)
                StopPointMarker = nil
                stopIndex = stopIndex + 1
                if stopIndex > #CONFIG.locations then
                        CONFIG.locations = shuffle(CONFIG.locations)
                        stopIndex = 1
                end
                showStopPoint()
                if getElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil") == 5000 then
                        exports.notifications:output({
                                en = "The tank is out of petrol, you have to fill it up",
                                ar = "نفذ الوقود من الخزان، عليك تعبئته"
                        }, 5000, "warning")
                end
        end
end)

addEventHandler("onClientMarkerLeave", resourceRoot, function(player)
        if player ~= localPlayer then
                return
        end
        if trailerMarkers[source] then
                unbindKey("lshift", "down", attachTrailer)
                exports.notifications:hideKeyDescription("fuel-delivery:attach_trailer")
        elseif fillingMarkers[source] then
                unbindKey("lshift", "down", fillTank)
                exports.notifications:hideKeyDescription("fuel-delivery:fill_tank")
        end
end)

function attachTrailer(key, keyState, marker)
        if isElementWithinMarker(localPlayer, marker) and getPedOccupiedVehicle(localPlayer) then
                trailerAttached = false
                fadeCamera(false, 1, 0, 0, 0)
                exports.public:loading("fuel-delivery:trailer:attach", true)
                setTimer(triggerServerEvent, 1000, 1, "fuel-delivery:trailer:attach", localPlayer, getPedOccupiedVehicle(localPlayer))
        end
        unbindKey(key, keyState, attachTrailer)
        exports.notifications:hideKeyDescription("fuel-delivery:attach_trailer")
end

addEvent("fuel-delivery" .. ":trailer:attach:callback", true)
addEventHandler("fuel-delivery" .. ":trailer:attach:callback", localPlayer, function(trailer)
        showStopPoint()
        fadeCamera(true, 1)
        exports.public:loading("fuel-delivery:trailer:attach", false)
end)

function fillTank(key, keyState, marker, trailer)
        if isElementWithinMarker(localPlayer, marker) and getPedOccupiedVehicle(localPlayer) then
                startFillingTank(trailer)
        end
        unbindKey(key, keyState, fillTank)
        exports.notifications:hideKeyDescription("fuel-delivery:fill_tank")
end

function startFillingTank(trailer)
        toggleAllControls(false, true, false)
        exports.public:loading("fuel-delivery:tank:fill", true)
        exports.notifications:output({
                en = "The tank is being filled with petrol",
                ar = "جاري تعبئة الخزان بالبنزين"
        }, 5000, "info")
        setTimer(function(trailer)
                toggleAllControls(true, true, false)
                setElementData(trailer, "oil", 30000)
                exports.public:loading("fuel-delivery:tank:fill", false)
                exports.notifications:output({
                        en = "The tank was filled with petrol",
                        ar = "تم تعبئة الخزان بالبنزين"
                }, 3500, "info")
        end, 5000, 1, trailer)
end

function shuffle(tbl)
        for i = #tbl, 2, -1 do
                tbl[i], tbl[math.random(1, i)] = tbl[math.random(1, i)], tbl[i]
        end
        return tbl
end

function enterVehicleEvent(vehicle)
        if not TRUCK_MODELS[getElementModel(vehicle)] then
                return
        end
        if getElementData(localPlayer, "job") ~= JOB_NAME then
                return
        end
        if getVehicleTowedByVehicle(vehicle) then
                if getElementData(getVehicleTowedByVehicle(vehicle), "oil") then
                        if getElementData(getVehicleTowedByVehicle(vehicle), "oil") > 0 then
                                showStopPoint()
                        else
                                exports.notifications:output({
                                        en = "There is no fuel in the tank",
                                        ar = "لايوجد وقود في الخزان"
                                }, 3500, "info")
                        end
                else
                        exports.notifications:output({
                                en = "There is no fuel in the tank",
                                ar = "لايوجد وقود في الخزان"
                        }, 3500, "info")
                end
        end
        addEventHandler("onClientRender", root, drawJobInfo)
end
addEventHandler("onClientPlayerVehicleEnter", localPlayer, enterVehicleEvent)

function exitVehicleEvent(vehicle)
        if not TRUCK_MODELS[getElementModel(vehicle)] then
                return
        end
        removeEventHandler("onClientRender", root, drawJobInfo)
end
addEventHandler("onClientPlayerVehicleExit", localPlayer, exitVehicleEvent)

function drawJobInfo()
        if getPedOccupiedVehicle(localPlayer) then
                if getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)) then
                        dxDrawImage(25 * SCALE, 800 * SCALE, 32 * SCALE, 32 * SCALE, "oil-barrel.png", 0, 0, 0)
                        dxDrawText(tostring(getElementData(getVehicleTowedByVehicle(getPedOccupiedVehicle(localPlayer)), "oil") or 0) .. " Liter", 70 * SCALE, 800 * SCALE, 150 * SCALE, 832 * SCALE, tocolor(255, 255, 255, 255), 2 * SCALE, "default-bold", "left", "center")
                end
        else
                removeEventHandler("onClientRender", root, drawJobInfo)
        end
end

local trailerAttached = false
