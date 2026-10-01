--------------------------------------------------------------------------------
-- Vortex speedometer — client ([Fix #161] rectangular panel redesign)
--
-- Single visible panel for cars / boats / monster trucks / quads / bikes.
-- The legacy backup gauge (realism-system/c_speedo.lua drawSpeedo/drawFuel) is
-- suppressed for those vehicle types, so nothing double-draws any more; it
-- keeps drawing street/district/speed-limit info and still handles aircraft.
--
-- Layout — one dark translucent panel, bottom-right, 12px inner padding, every
-- row aligned to the same inner edges (old glowing disc removed):
--   row 1  "FUEL nn%" (state colour)      gear pill (red HANDBRAKE while parked)
--   row 2  left arrow | big speed digits | right arrow   (500ms blink)
--   row 3  unit label: KM/H / MPH, or red ENGINE OFF while off
--   row 4  "RPM" micro bar (theme purple -> red past the 85% redline)
--   row 5  seatbelt banner (green = buckled, red pulsing = unbuckled);
--          omitted on bikes / BMX (no belt) and the panel shrinks to match
--   under  c_hud's engine/handbrake/seatbelt/lights/lock row (SPEEDO_* anchors)
--
-- EXPORTS — hud/c_hud.lua reads these in the SAME resource VM to anchor its
-- engine/handbrake/seatbelt/lights/lock row under the panel. DO NOT REMOVE:
--   SPEEDO_CX / SPEEDO_CY / SPEEDO_R / SPEEDO_DISC_R
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- panel geometry (bottom-right corner, free area - no radar in this build)
-- [Fix #34 - user] the engine/handbrake/seatbelt/lights/lock row (drawn by
-- c_hud.lua) sits UNDER the panel
-- [Fix #161] disc -> rectangular panel; bottom edge stays at sy-134 so the
-- icon row, the district chip and the street chip keep their old positions
local PANEL_W = 272
local PANEL_H = 194             -- with seatbelt banner
local PANEL_H_NOBELT = 156      -- bikes / BMX: no banner row
local PANEL_X = sx - PANEL_W - 16
local PANEL_BOTTOM = sy - 134
local PAD = 12

-- row metrics (all relative to the panel top, constant for both heights)
local ROW_HEADER_H = 26         -- fuel + gear pill
local DIGIT_ROW_H = 56          -- speed digits (+ arrows)
local UNIT_ROW_H = 24           -- unit / ENGINE OFF
local BAR_H = 6                 -- rpm micro bar
local BAND_H = 26               -- seatbelt banner
local ROW_GAP = 10              -- header -> digits, unit -> bar
local SIDE_RESERVE = 40         -- arrow lane reserved left / right of digits

-- [Fix #34] shared with c_hud.lua (same client VM): the vehicle items row
-- anchors to the panel. Written at file scope so load order never matters.
-- cy + disc = panel bottom, so c_hud's "cy + disc + 12" lands 12px under the
-- panel (identical to the old disc position).
SPEEDO_CX = PANEL_X + PANEL_W / 2
SPEEDO_CY = PANEL_BOTTOM - 40
SPEEDO_R = 40
SPEEDO_DISC_R = 40

local arrowTex, beltTex
local rpmSmooth = 0
local blinkLeft, blinkRight = false, false
local largeFont, smallFont

local themePrimary = { 149, 84, 252 }

local function UIKitReady()
        local ok, v = pcall(function()
                local c = exports.UIKit:uiGetThemeColor("primary")
                if type(c) == "number" then
                        return { bitExtract(c, 16, 8), bitExtract(c, 8, 8), bitExtract(c, 0, 8) }
                end
        end)
        if ok and type(v) == "table" then themePrimary = v end
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function fontLarge()
        if largeFont then return largeFont end
        local ok, f = pcall(function() return exports.UIKit:getUIFont("hud-large") end)
        if ok and f then largeFont = f end
        return largeFont or "default-bold"
end

local function fontSmall()
        if smallFont then return smallFont end
        local ok, f = pcall(function() return exports.UIKit:getUIFont("hud") end)
        if ok and f then smallFont = f end
        return smallFont or "default-bold"
end

-- old client speed formula: length(velocity) * 161
local function getVehicleSpeedKmh(veh)
        local vx, vy, vz = getElementVelocity(veh)
        return math.sqrt(vx * vx + vy * vy + vz * vz) * 161
end

-- old client allowed types (planes/helis/bmx/trains excluded)
local function vehicleAllowed(veh)
        local t = getVehicleType(veh)
        return t == "Automobile" or t == "Boat" or t == "Monster Truck"
                or t == "Quad" or t == "Bike"
end

-- fuel: the server writes element data "fuel" with sync = false and pushes the
-- live value through the "syncFuel" client event (source = vehicle), so the
-- event is the authoritative source and element data is the initial fallback.
local fuelCache = {}
addEvent("syncFuel", true)
addEventHandler("syncFuel", root, function(ifuel)
        if source and isElement(source) then
                fuelCache[source] = tonumber(ifuel) or 0
        end
end)
addEventHandler("onClientElementDestroy", root, function()
        if fuelCache[source] then fuelCache[source] = nil end
end)

local function fuelPercent(veh)
        local fuel = fuelCache[veh]
        if not fuel then
                -- element data is only synced when the vehicle loads
                fuel = tonumber(getElementData(veh, "fuel"))
        end
        if not fuel then
                -- fallback: vehicle health as a 0..100 gauge
                local h = getElementHealth(veh)
                if h > 100 then h = 100 end
                return math.max(0, math.min(100, h))
        end
        local mx = 100
        local ok, v = pcall(function() return exports["fuel-system"]:getMaxFuel(getElementModel(veh)) end)
        if ok and type(v) == "number" and v > 0 then mx = v end
        return math.max(0, math.min(100, fuel / mx * 100))
end

local function shadowText(str, left, top, right, bottom, color, scale, font, alignX)
        alignX = alignX or "center"
        dxDrawText(str, left + 1.5, top + 1.5, right + 1.5, bottom + 1.5,
                tocolor(0, 0, 0, 180), scale, font, alignX, "center", false, false, true)
        dxDrawText(str, left, top, right, bottom, color, scale, font, alignX, "center", false, false, true)
end

local function speedoDraw()
        if not isHudShowing or not isHudShowing() then return end
        -- old client gates: element data "speedo" = "0" hides it, and the gauge
        -- never draws over the full-screen map
        if getElementData(localPlayer, "speedo") == "0" then return end
        if isPlayerMapVisible() then return end
        local veh = getPedOccupiedVehicle(localPlayer)
        if not veh or not isElement(veh) or not vehicleAllowed(veh) then return end

        local now = getTickCount()

        -- indicators: temp:indicator 2 = left, 3 = right (old client data)
        local ind = tonumber(getElementData(veh, "temp:indicator"))
        local phase = math.floor(now / 500) % 2 == 0
        blinkRight = ind == 3 and phase
        blinkLeft = ind == 2 and (not phase)

        local engineOn = getVehicleEngineState(veh) and true or false
        local kmh = getVehicleSpeedKmh(veh)

        -- unit mode (old client data): "2" = mph, anything else = km/h
        local mphMode = (getElementData(localPlayer, "speedo") == "2")
        local unitLabel = mphMode and "MPH" or "KM/H"
        local dispSpeed = mphMode and (kmh * 0.621371) or kmh

        -- rpm model (old client: idle ~650, redline 9000, 0 with engine off)
        local target = 0
        if engineOn then
                target = 650 + math.min(kmh, 260) / 260 * 8350
        end
        rpmSmooth = rpmSmooth + (target - rpmSmooth) * 0.12
        local rpmProgress = math.max(0, math.min(1, rpmSmooth / 9000))

        local fuel = fuelPercent(veh)

        local hb = getElementData(veh, "handbrake")
        local handbrake = (hb == true or hb == 1)

        -- seatbelt: server truth is element data "seatbelt" on the local player
        -- (realism-system s_vehicle_crash.lua seatbelt(), /seatbelt /belt and the
        -- realism:seatbelt:toggle event; also mirrored by the hud seatbelt item).
        -- Bikes / BMX have no belt at all (the server refuses those), so they
        -- get no banner row.
        local vtype = getVehicleType(veh)
        local beltCapable = (vtype ~= "Bike" and vtype ~= "BMX")
        local beltOn = false
        if beltCapable then
                if getElementData(localPlayer, "seatbelt") == true then
                        beltOn = true
                elseif getHudSetting and getHudSetting("seatbelt") then
                        beltOn = true
                end
        end
        local pulse = math.floor(now / 350) % 2 == 0

        -- panel frame (dark translucent body, hairline theme accent border)
        local ph = beltCapable and PANEL_H or PANEL_H_NOBELT
        local px, py = PANEL_X, PANEL_BOTTOM - ph
        local ix0, ix1 = px + PAD, px + PANEL_W - PAD
        local pr, pg, pb = themePrimary[1], themePrimary[2], themePrimary[3]

        dxDrawRoundedRectangle(px, py, PANEL_W, ph, tocolor(pr, pg, pb, 95), 12, true)
        dxDrawRoundedRectangle(px + 1, py + 1, PANEL_W - 2, ph - 2,
                tocolor(12, 11, 20, 228), 11, true)

        -- row 1: fuel label (left; blinks red under 10% like the old warning)
        local fr, fg, fb = 80, 220, 90
        if fuel <= 15 then
                fr, fg, fb = 255, 60, 60
        elseif fuel <= 25 then
                fr, fg, fb = 255, 170, 40
        end
        local fuelAlpha = 245
        if fuel <= 10 then
                fuelAlpha = pulse and 255 or 130
                fr, fg, fb = 255, 60, 60
        end
        local headerY = py + PAD
        shadowText(string.format("FUEL %d%%", math.floor(fuel + 0.5)),
                ix0, headerY, ix0 + 130, headerY + ROW_HEADER_H,
                tocolor(fr, fg, fb, fuelAlpha), 0.85, fontSmall(), "left")

        -- row 1: gear pill (right; red HANDBRAKE while the handbrake is up)
        local gear = (getVehicleCurrentGear and getVehicleCurrentGear(veh)) or 0
        local gearText
        if handbrake then
                gearText = "HANDBRAKE"
        elseif gear == -1 then
                gearText = "GEAR R"
        elseif gear == 0 then
                gearText = "GEAR N"
        else
                gearText = "GEAR " .. tostring(gear)
        end
        local pillW = (dxGetTextWidth(gearText, 0.78, fontSmall()) or 60) + 22
        local pillX = ix1 - pillW
        local pillY = headerY + (ROW_HEADER_H - 24) / 2
        local pcR, pcG, pcB
        if handbrake then
                pcR, pcG, pcB = 200, 46, 46
        else
                pcR, pcG, pcB = pr, pg, pb
        end
        dxDrawRoundedRectangle(pillX - 1, pillY - 1, pillW + 2, 26,
                tocolor(pcR, pcG, pcB, 170), 9, true)
        dxDrawRoundedRectangle(pillX, pillY, pillW, 24,
                tocolor(pcR, pcG, pcB, handbrake and 70 or 55), 8, true)
        shadowText(gearText, pillX, pillY, pillX + pillW, pillY + 24,
                tocolor(255, 255, 255, 245), 0.78, fontSmall(), "center")

        -- row 2: speed digits between the two arrow lanes
        local speedY = headerY + ROW_HEADER_H + ROW_GAP
        local spdStr = tostring(math.floor(dispSpeed))
        local dScale = (#spdStr >= 4) and 1.55 or 2.0
        local digitColor = engineOn and tocolor(255, 255, 255, 255)
                or tocolor(255, 255, 255, 130)
        shadowText(spdStr, ix0 + SIDE_RESERVE, speedY, ix1 - SIDE_RESERVE,
                speedY + DIGIT_ROW_H, digitColor, dScale, fontLarge(), "center")

        -- row 2: turn-signal arrows (idle theme accent, green while blinking)
        if arrowTex then
                local asize = 34
                local ay = speedY + (DIGIT_ROW_H - asize) / 2
                local idle = tocolor(pr, pg, pb, 130)
                local colR = blinkRight and tocolor(0, 235, 90, 245) or idle
                local colL = blinkLeft and tocolor(0, 235, 90, 245) or idle
                dxDrawImage(ix1 - asize, ay, asize, asize, arrowTex, 0, 0, 0, colR, true)
                dxDrawImage(ix0, ay, asize, asize, arrowTex, 180, 0, 0, colL, true)
        end

        -- row 3: unit (or engine state)
        local unitY = speedY + DIGIT_ROW_H
        if engineOn then
                shadowText(unitLabel, ix0, unitY, ix1, unitY + UNIT_ROW_H,
                        tocolor(pr, pg, pb, 245), 1.0, fontSmall(), "center")
        else
                shadowText("ENGINE OFF", ix0, unitY, ix1, unitY + UNIT_ROW_H,
                        tocolor(255, 82, 82, 245), 1.0, fontSmall(), "center")
        end

        -- row 4: rpm micro bar (theme accent, red through the redline)
        local barY = unitY + UNIT_ROW_H + ROW_GAP
        local labelW = 32
        shadowText("RPM", ix0, barY - 5, ix0 + labelW, barY + BAR_H + 5,
                tocolor(255, 255, 255, 140), 0.7, fontSmall(), "left")
        local trackX = ix0 + labelW + 8
        local trackW = ix1 - trackX
        dxDrawRoundedRectangle(trackX, barY, trackW, BAR_H,
                tocolor(255, 255, 255, 26), BAR_H / 2, true)
        local rpR, rpG, rpB = pr, pg, pb
        if rpmProgress > 0.85 then
                local t = (rpmProgress - 0.85) / 0.15
                rpR = rpR + (255 - rpR) * t
                rpG = rpG + (60 - rpG) * t
                rpB = rpB + (60 - rpB) * t
        end
        if rpmProgress > 0.01 then
                dxDrawRoundedRectangle(trackX, barY, math.max(BAR_H, trackW * rpmProgress),
                        BAR_H, tocolor(rpR, rpG, rpB, 235), BAR_H / 2, true)
        end

        -- row 5: seatbelt banner (red pulsing = unbuckled, green = buckled)
        if beltCapable then
                local bandY = py + ph - PAD - BAND_H
                local bg = beltOn and tocolor(24, 132, 66, 245)
                        or tocolor(186, 28, 28, pulse and 250 or 180)
                dxDrawRoundedRectangle(ix0, bandY, ix1 - ix0, BAND_H, bg, 8, true)
                local tx0 = ix0 + 6
                if beltTex then
                        dxDrawImage(ix0 + 9, bandY + (BAND_H - 16) / 2, 16, 16, beltTex,
                                0, 0, 0, tocolor(255, 255, 255, 240), true)
                        tx0 = ix0 + 30
                end
                local label = beltOn and "SEATBELT ON" or "FASTEN SEATBELT"
                shadowText(label, tx0, bandY, ix1 - 6, bandY + BAND_H,
                        tocolor(255, 255, 255, 250), 0.85, fontSmall(), "center")
        end
end

-- indicator keys (old client: "." right, "," left; driver only)
local function bindBlocked()
        if isChatBoxInputActive and isChatBoxInputActive() then return true end
        if guiGetFocusedElement then
                local ok, focused = pcall(guiGetFocusedElement)
                if ok and focused then return true end
        end
        if getKeyState("lctrl") or getKeyState("rctrl") or getKeyState("lalt") or getKeyState("ralt") then
                return true
        end
        return false
end

local function setIndicator(which)
        if bindBlocked() then return end
        local veh = getPedOccupiedVehicle(localPlayer)
        if not veh or not isElement(veh) then return end
        if getVehicleController(veh) ~= localPlayer then return end
        local cur = tonumber(getElementData(veh, "temp:indicator"))
        local want = which == "right" and 3 or 2
        setElementData(veh, "temp:indicator", cur == want and nil or want)
end
bindKey(".", "down", function() setIndicator("right") end)
bindKey(",", "down", function() setIndicator("left") end)

addEventHandler("onClientResourceStart", resourceRoot, function()
        UIKitReady()
        if fileExists("images/arrow.png") then
                arrowTex = dxCreateTexture("images/arrow.png", "argb", true, "clamp")
        end
        if fileExists("icons/vehicle_seatbelt.png") then
                beltTex = dxCreateTexture("icons/vehicle_seatbelt.png", "argb", true, "clamp")
        end
        addEventHandler("onClientRender", root, speedoDraw, false, "high-2")
end)
