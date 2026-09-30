-- Decompiled by Owl Decompiler v1.0 ([jobs]/taxi-driver/taxi_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with decompiler artifacts repaired:
--   * var0/var1 = the lost screen width/height pair used by
--     isMouseInPosition/dxDrawInfo - restored as SX/SY.
--   * var3 = the meter button table (labels + enabled flags), var2 = the
--     hovered button index - restored as BUTTONS / hoverBtn.
--   * the meter cost + distance texts were collapsed to literal `0` by the
--     decompiler - restored from the taxi.meter contract
--     {startDistance, startTick, state, farePerKm}:
--         distance = vehicle:total.distance - startDistance
--         cost     = distance * farePerKm
--   * `unpack(getElementData(...))` in the Reset/Start-Pause/Save flows lost
--     its position index (4 = the fare) - restored as unpack(meter, 4) and
--     {unpack(meter, 1, 3), FARES[selected]}.
--   * msToTimeStr: restored the lost zero-padding branches (MM:SS).
--   * taxi:requests:sync: getDistanceBetweenPoints3D lost the second
--     getElementPosition (the requester) - restored; lost `local row`.
--   * the meter background color was lost - reconstructed as a dark
--     tocolor(0,0,0,180) pill matching the white 180-alpha line/text styling.

local SX, SY = guiGetScreenSize()

local BUTTONS = {
        { "Reset", true },
        { "Start/Pause", true },
        { "Light", true },
        { "Set Fare", true }
}
local FARES = { 10, 15, 30, 35 }
local hoverBtn = 0

function dxDrawEmptyLine(x, y, w, h, color, postGUI, width)
        dxDrawLine(x, y, x + w, y, color, width, postGUI)
        dxDrawLine(x, y, x, y + h, color, width, postGUI)
        dxDrawLine(x, y + h, x + w, y + h, color, width, postGUI)
        dxDrawLine(x + w, y, x + w, y + h, color, width, postGUI)
end

function isMouseInPosition(x, y, w, h)
        if isCursorShowing() and x <= getCursorPosition() * SX and y <= getCursorPosition() * SY and getCursorPosition() * SX <= x + w and getCursorPosition() * SY <= y + h then
                return true
        end
end

function dxDrawInfo(text, x, y, w, h)
        if isMouseInPosition(x, y, w, h) then
                dxDrawRectangle(math.min(getCursorPosition() * SX, SX - (dxGetTextWidth(text, 1, "default") + 10)), getCursorPosition() * SY - (dxGetFontHeight(1, "default") * #split(text, "\n") + 10), dxGetTextWidth(text, 1, "default") + 10, dxGetFontHeight(1, "default") * #split(text, "\n") + 10, tocolor(0, 0, 0, 255), true)
                dxDrawLine(math.min(getCursorPosition() * SX, SX - (dxGetTextWidth(text, 1, "default") + 10)), getCursorPosition() * SY, math.min(getCursorPosition() * SX, SX - (dxGetTextWidth(text, 1, "default") + 10)) + (dxGetTextWidth(text, 1, "default") + 10), getCursorPosition() * SY, tocolor(255, 55, 95, 255), 2, true)
                dxDrawText(text, math.min(getCursorPosition() * SX, SX - (dxGetTextWidth(text, 1, "default") + 10)), getCursorPosition() * SY - (dxGetFontHeight(1, "default") * #split(text, "\n") + 10), math.min(getCursorPosition() * SX, SX - (dxGetTextWidth(text, 1, "default") + 10)) + (dxGetTextWidth(text, 1, "default") + 10), getCursorPosition() * SY, tocolor(255, 255, 255, 255), 1, "default", "center", "center", false, false, true, false, false)
        end
end

local function meterRect()
        return (SX - 300) / 2, SY - 130 - 10, 300, 130
end

local function getMeter()
        return getElementData(getPedOccupiedVehicle(localPlayer), "taxi.meter") or {
                0,
                getTickCount(),
                "stopped",
                10
        }
end

function drawTaxiMeter()
        if not isPedInVehicle(localPlayer) then
                removeEventHandler("onClientPreRender", root, drawTaxiMeter)
                removeEventHandler("onClientClick", root, clickMeterBtn)
                return
        end
        local mx, my, mw, mh = meterRect()
        dxDrawRectangle(mx, my, mw, mh, tocolor(0, 0, 0, 180))
        dxDrawEmptyLine(mx, my, mw, mh, tocolor(255, 255, 255, 180), false, 2)
        -- inner accent line (the decompile drew a second border inset by 5)
        dxDrawEmptyLine(mx + 5, my + 5, mw - 10, mh - 10, tocolor(255, 255, 255, 180), false, 2)
        local meter = getMeter()
        local distance = math.max((getElementData(getPedOccupiedVehicle(localPlayer), "vehicle:total.distance") or 0) - (tonumber(meter[1]) or 0), 0)
        local cost = math.floor(distance * (tonumber(meter[4]) or 10))
        -- big cost readout
        dxDrawText("$" .. tostring(cost), mx + 5, my + 5, mx + mw - 10, my + mh - 45 - 10, tocolor(255, 255, 255, 180), 3, "default", "center", "center", false, false, false, false, false)
        -- fare per km
        dxDrawText(tostring(meter[4] or 10) .. "$/km", mx + 5, my + mh - 45 - 20, mx + mw - 10, my + mh - 45, tocolor(255, 255, 255, 230), 1, "default-bold", "center", "center", false, false, false, false, false)
        hoverBtn = 0
        for i = 1, 4 do
                local bx, by = mx + mw - 30 * i, my + mh - 30
                dxDrawRectangle(bx, by, 25, 25, tocolor(150, 150, 150, 240), false)
                dxDrawEmptyLine(bx, by, 25, 25, tocolor(150, 150, 150, 240), false, 2)
                dxDrawText(BUTTONS[i][1], bx, by, bx + 25, by + 25, tocolor(15, 15, 15, 255), 1, "default-bold", "center", "center", false, false, false, false, false)
                dxDrawInfo(BUTTONS[i][1], bx, by, 25, 25)
                if isMouseInPosition(bx, by, 25, 25) then
                        hoverBtn = i
                end
        end
        if meter[3] == "started" then
        end
        -- bottom strip: distance (left) + elapsed time (right)
        dxDrawText("Distance (km/h)\n" .. tostring(tostring(distance):sub(1, 9) or "000000"), mx + 5, my + mh - 40, mx + 90, my + mh - 8, tocolor(255, 255, 255, 230), 1, "default-bold", "center", "center", false, false, false, false, false)
        dxDrawText("Time\n" .. msToTimeStr((getTickCount() - (tonumber(meter[2]) or getTickCount())) / 1000), mx + 90, my + mh - 40, mx + 175, my + mh - 8, tocolor(255, 255, 255, 230), 1, "default-bold", "center", "center", false, false, false, false, false)
end

function msToTimeStr(seconds)
        seconds = tonumber(seconds)
        seconds = math.floor(seconds)
        if not seconds then
                return ""
        end
        if seconds < 0 then
                return "00:00"
        end
        local s = math.fmod(seconds, 60)
        local m = math.floor(seconds / 60)
        if #tostring(s) == 1 then
                s = "0" .. s
        end
        if #tostring(m) == 1 then
                m = "0" .. m
        end
        return m .. ":" .. s
end

addEventHandler("onClientVehicleStartEnter", root, function(player, seat)
        if player ~= localPlayer then
                return
        end
        if getElementModel(source) == 420 and seat == 0 and getElementData(localPlayer, "job") ~= "Taxi Driver" then
                cancelEvent()
        end
end)

addEventHandler("onClientVehicleEnter", root, function(player, seat)
        if player == localPlayer and getElementModel(source) == 420 then
                if not getElementData(source, "taxi.meter") then
                        setElementData(source, "taxi.meter", {
                                getElementData(source, "vehicle:total.distance") or 0,
                                getTickCount(),
                                "stopped",
                                10
                        })
                end
                removeEventHandler("onClientPreRender", root, drawTaxiMeter)
                addEventHandler("onClientPreRender", root, drawTaxiMeter)
                addEventHandler("onClientClick", root, clickMeterBtn)
        end
end)

addEventHandler("onClientVehicleStartExit", root, function(player, seat)
        if player == localPlayer and getElementModel(source) == 420 then
                removeEventHandler("onClientPreRender", root, drawTaxiMeter)
                removeEventHandler("onClientClick", root, clickMeterBtn)
        end
end)

function clickMeterBtn(button, state, absoluteX, absoluteY, worldX, worldY, clickedElement, clickedGUI)
        if button == "left" and state == "up" and hoverBtn ~= 0 then
                if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
                        return
                end
                if getElementData(localPlayer, "job") ~= "Taxi Driver" then
                        return
                end
                local vehicle = getPedOccupiedVehicle(localPlayer)
                if BUTTONS[hoverBtn][1] == "Reset" then
                        setElementData(vehicle, "taxi.meter", {
                                getElementData(vehicle, "vehicle:total.distance") or 0,
                                getTickCount(),
                                "stopped",
                                unpack(getElementData(vehicle, "taxi.meter"), 4)
                        })
                elseif BUTTONS[hoverBtn][1] == "Start/Pause" then
                        setElementData(vehicle, "taxi.meter", {
                                getElementData(vehicle, "vehicle:total.distance") or 0,
                                getTickCount(),
                                "started",
                                unpack(getElementData(vehicle, "taxi.meter"), 4)
                        })
                elseif BUTTONS[hoverBtn][1] == "Light" then
                        triggerServerEvent("taxi:setLight", localPlayer, (vehicle))
                elseif BUTTONS[hoverBtn][1] == "Set Fare" then
                        guiSetVisible(GUIEditor.window[1], true)
                        currentVehicle = vehicle
                end
        end
end

GUIEditor = {
        button = {},
        window = {},
        radiobutton = {}
}

addEventHandler("onClientResourceStart", resourceRoot, function()
        GUIEditor.window[1] = guiCreateWindow((SX - 219) / 2, (SY - 167) / 2, 219, 167, "Set fare", false)
        guiWindowSetSizable(GUIEditor.window[1], false)
        guiSetVisible(GUIEditor.window[1], false)
        GUIEditor.radiobutton[1] = guiCreateRadioButton(10, 30, 117, 15, "10$ /km", false, GUIEditor.window[1])
        GUIEditor.radiobutton[2] = guiCreateRadioButton(10, 50, 117, 15, "15$ /km", false, GUIEditor.window[1])
        GUIEditor.radiobutton[3] = guiCreateRadioButton(10, 70, 117, 15, "30$ /km", false, GUIEditor.window[1])
        GUIEditor.radiobutton[4] = guiCreateRadioButton(10, 90, 117, 15, "35$ /km", false, GUIEditor.window[1])
        GUIEditor.button[1] = guiCreateButton(62, 127, 95, 30, "Save", false, GUIEditor.window[1])
end)

addEventHandler("onClientGUIClick", resourceRoot, function()
        if source == GUIEditor.button[1] then
                for i, radioButton in ipairs(GUIEditor.radiobutton) do
                        if guiRadioButtonGetSelected(radioButton) then
                                -- decompiler collapsed meter[1..3] into unpack(); a table
                                -- constructor would truncate a non-final call to one value,
                                -- so the fare write must index explicitly
                                local meter = getElementData(currentVehicle, "taxi.meter")
                                setElementData(currentVehicle, "taxi.meter", {
                                        meter[1],
                                        meter[2],
                                        meter[3],
                                        FARES[i]
                                })
                                break
                        end
                end
                guiSetVisible(GUIEditor.window[1], false)
        end
end)

-- ============================== PHONE APP ==============================
-- taxi screens are injected into the phone through phone:app:request
-- (name, parent, x, y, w, h) - the phone-system stub container is the parent

local UI = {
        screen = {},
        label = {},
        button = {},
        gridlist = {}
}
local reset_timer

addEvent("phone:app:request", true)
addEventHandler("phone:app:request", localPlayer, function(appName, parent, x, y, w, h)
        if appName == "taxi" then
                if not isElement(UI.screen["taxi:main"]) then
                        eui = exports.UIKit
                        UI.screen["taxi:main"] = eui:uiCreateContainer(x, y, w, h, parent)
                        UI.label.Title = eui:uiCreateLabel(15, 40, 200, 20, {en = "TAXI", ar = "TAXI"}, tocolor(255, 220, 0, 255), "left", "top", UI.screen["taxi:main"])
                        eui:uiSetFont(UI.label.Title, "default-large")
                        eui:uiCreateRectangle(0, 80, w, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.screen["taxi:main"])
                        eui:uiCreateImage((w - w / 2) / 2, 120, w / 2, w / 2, "images/pin.png", UI.screen["taxi:main"])
                        UI.label["taxi:note"] = eui:uiCreateLabel(15, 300, w - 30, 100, "", tocolor(255, 220, 0, 255), "center", "top", UI.screen["taxi:main"])
                        UI.button["taxi:request"] = eui:uiCreateButton(10, h - 70, w - 20, 35, {
                                en = "Request Taxi",
                                ar = "طلب تاكسي"
                        }, tocolor(255, 220, 0, 255), UI.screen["taxi:main"])
                        eui:uiSetProperty(UI.button["taxi:request"], "TextColor", tocolor(0, 0, 0))
                        UI.screen["taxi:driver"] = eui:uiCreateContainer(x, y, w, h, parent)
                        eui:uiSetVisible(UI.screen["taxi:driver"], false)
                        UI.label.Title = eui:uiCreateLabel(30, 40, 200, 20, {
                                en = "TAXI | Driver",
                                ar = "TAXI | السائق"
                        }, tocolor(255, 220, 0, 255), "left", "top", UI.screen["taxi:driver"])
                        eui:uiSetFont(UI.label.Title, "default-large")
                        eui:uiCreateRectangle(0, 80, w, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.screen["taxi:driver"])
                        UI.gridlist.taxi_requests = eui:uiCreateGridList(15, 130, w - 30, h - 250, tocolor(0, 0, 0, 0), UI.screen["taxi:driver"])
                        eui:uiGridListAddColumn(UI.gridlist.taxi_requests, "", 1)
                        eui:uiSetAlign(UI.gridlist.taxi_requests, "left", "center")
                        eui:uiSetProperty(UI.gridlist.taxi_requests, "row_height", 30)
                        eui:uiSetProperty(UI.gridlist.taxi_requests, "columns_names_visible", "False")
                        eui:uiSetProperty(UI.gridlist.taxi_requests, "column_height", 0)
                        UI.button["taxi:accept_request"] = eui:uiCreateButton(10, h - 70, w - 20, 35, {
                                en = "Accept Request",
                                ar = "قبول الطلب"
                        }, tocolor(255, 220, 0, 255), UI.screen["taxi:driver"])
                        eui:uiSetProperty(UI.button["taxi:accept_request"], "TextColor", tocolor(0, 0, 0))
                end
                if getElementData(localPlayer, "job") == "Taxi Driver" then
                        eui:uiSetVisible(UI.screen["taxi:main"], false)
                        eui:uiSetVisible(UI.screen["taxi:driver"], true)
                        triggerServerEvent("taxi:request_sync", localPlayer)
                else
                        eui:uiSetVisible(UI.screen["taxi:driver"], false)
                        eui:uiSetVisible(UI.screen["taxi:main"], true)
                end
        end
end)

addEventHandler("onClientUIClick", root, function()
        if source == UI.button["taxi:request"] then
                triggerServerEvent("taxi:send_request", localPlayer)
        elseif source == UI.button["taxi:accept_request"] and eui:uiGridListGetSelectedItem(UI.gridlist.taxi_requests) ~= -1 then
                triggerServerEvent("taxi:accept_request", localPlayer, (eui:uiGridListGetItemData(UI.gridlist.taxi_requests, eui:uiGridListGetSelectedItem(UI.gridlist.taxi_requests), 1)))
        end
end)

addEvent("taxi:requests:sync", true)
addEventHandler("taxi:requests:sync", root, function(requests)
        eui:uiGridListClear(UI.gridlist.taxi_requests)
        local px, py, pz = getElementPosition(localPlayer)
        for requester in pairs(requests) do
                if requests[requester].status ~= "accepted" then
                        -- decompiler lost the second getElementPosition; a nested call
                        -- would truncate to one value, so both positions are read out
                        local qx, qy, qz = getElementPosition(requester)
                        local row = eui:uiGridListAddRow(UI.gridlist.taxi_requests)
                        local metres = math.floor(getDistanceBetweenPoints3D(px, py, pz, qx, qy, qz))
                        eui:uiGridListSetItemText(UI.gridlist.taxi_requests, row, 1, tostring((getElementData(requester, "character:name"))) .. "   (" .. tostring(metres) .. " m away)")
                        eui:uiGridListSetItemData(UI.gridlist.taxi_requests, row, 1, requester)
                end
        end
end)

addEvent("taxi:on_accept_request", true)
addEventHandler("taxi:on_accept_request", localPlayer, function(driver)
        eui:uiSetVisible(UI.button["taxi:request"], false)
        eui:uiSetText(UI.label["taxi:note"], {
                en = "",
                ar = "تم قبول الطلب من قبل السائق" .. "\n" .. getElementData(driver, "character:name") .. "\n\nالرجاء لاتقم بتغيير موقعك" .. "\nحتى يستطيع السائق الوصول لك"
        })
        if reset_timer and isTimer(reset_timer) then
                killTimer(reset_timer)
        end
        reset_timer = setTimer(function()
                eui:uiSetVisible(UI.button["taxi:request"], true)
                eui:uiSetText(UI.label["taxi:note"], "")
        end, 300000, 1)
end)
