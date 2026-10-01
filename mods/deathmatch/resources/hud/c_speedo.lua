--------------------------------------------------------------------------------
-- Vortex speedometer — client (full redesign, U7 UI batch)
--
-- Single visible gauge for cars / boats / monster trucks / quads / bikes.
-- The legacy backup gauge (realism-system/c_speedo.lua drawSpeedo/drawFuel) is
-- suppressed for those vehicle types, so nothing double-draws any more; it
-- keeps drawing street/district/speed-limit info and still handles aircraft.
--
-- Layout, inside the 112px disc centred on G_CX / G_CY:
--   * rim     seatbelt band (green = buckled, red pulsing = unbuckled)
--   * outer   rpm ring    (theme purple -> red past the 85% redline)
--   * middle  speed ring  (white -> orange @140 -> red @190 km/h)
--   * inner   fuel ring   (green / orange <=25% / red <=15%)
--   * top     "FUEL nn%" label + gear pill (red "HANDBRAKE" while parked)
--   * centre  big speed digits + KM/H or MPH (or ENGINE OFF while off)
--   * bottom  seatbelt band banner, right above c_hud's vehicle icon row
--   * sides   turn-signal arrows ("," left / "." right, 500ms blink)
--
-- EXPORTS — hud/c_hud.lua reads these in the SAME resource VM to anchor its
-- engine/handbrake/seatbelt/lights/lock row under the dial. DO NOT REMOVE:
--   SPEEDO_CX / SPEEDO_CY / SPEEDO_R / SPEEDO_DISC_R
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- gauge geometry (bottom-right corner, free area - no radar in this build)
-- [Fix #34 - user] dial raised a little so the engine/handbrake/seatbelt/
-- lights/lock row (drawn by c_hud.lua) fits UNDER the gauge
-- [Fix #47 - user] dial radius 84 -> 108
-- The redesign keeps the same screen area so the c_hud under-dial row and the
-- SPEEDO_* globals stay compatible.
local G_R = 108                     -- gauge radius
local G_CX, G_CY = sx - 180, sy - 246

-- [Fix #34] shared with c_hud.lua (same client VM): the vehicle items row
-- anchors to the gauge. Written at file scope so load order never matters.
SPEEDO_CX = G_CX
SPEEDO_CY = G_CY
SPEEDO_R = G_R
SPEEDO_DISC_R = G_R + 4

-- ring geometry (inside the 112px disc)
local R_BELT, T_BELT = 110, 4       -- rim band: seatbelt state
local R_RPM, T_RPM = 103, 9         -- outer ring: rpm
local R_SPD, T_SPD = 90, 6          -- middle ring: speed
local R_FUEL, T_FUEL = 78, 5        -- inner ring: fuel
local SPEED_MAX = 240               -- km/h = full speed ring

-- seatbelt band banner (bottom of the dial; sits in the 12px gap that c_hud
-- leaves above its vehicle icon row: disc bottom = CY+112, row top = CY+124)
local BAND_W, BAND_H = 148, 24
local BAND_X = G_CX - BAND_W / 2
local BAND_Y = G_CY + 96

local arrowTex, beltTex
local rpmSmooth = 0
local blinkLeft, blinkRight = false, false
local largeFont, smallFont

local themePrimary = { 149, 84, 255 }

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

local function ringTrack(radius, thickness, r, g, b, a)
        local size = (radius + thickness + 2) * 2
        drawSmoothRingG(G_CX, G_CY, size, radius, thickness, r, g, b, a, 1, true)
end

local function ringValue(radius, thickness, r, g, b, a, progress)
        if not progress or progress <= 0.004 then return end
        if progress > 1 then progress = 1 end
        local size = (radius + thickness + 2) * 2
        drawSmoothRingG(G_CX, G_CY, size, radius, thickness, r, g, b, a, progress, true)
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
        local speedMax = mphMode and 150 or SPEED_MAX
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
        -- get no band.
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

        -- base disc + thin rim
        drawSmoothDiscG(G_CX, G_CY, SPEEDO_DISC_R, 12, 10, 24, 235, true)
        ringTrack(SPEEDO_DISC_R - 1, 1.5, 255, 255, 255, 30)

        -- rpm ring (theme primary, turns red through the redline)
        ringTrack(R_RPM, T_RPM, 255, 255, 255, 16)
        local rpR, rpG, rpB = themePrimary[1], themePrimary[2], themePrimary[3]
        if rpmProgress > 0.85 then
                local t = (rpmProgress - 0.85) / 0.15
                rpR = rpR + (255 - rpR) * t
                rpG = rpG + (60 - rpG) * t
                rpB = rpB + (60 - rpB) * t
        end
        ringValue(R_RPM, T_RPM, rpR, rpG, rpB, 240, rpmProgress)

        -- speed ring (white -> orange -> red)
        ringTrack(R_SPD, T_SPD, 255, 255, 255, 16)
        local spdR, spdG, spdB = 255, 255, 255
        if kmh >= 190 then
                spdR, spdG, spdB = 255, 70, 70
        elseif kmh >= 140 then
                spdR, spdG, spdB = 255, 170, 40
        end
        ringValue(R_SPD, T_SPD, spdR, spdG, spdB, 235, dispSpeed / speedMax)

        -- fuel arc: green / orange / red
        local fr, fg, fb = 80, 220, 90
        if fuel <= 15 then
                fr, fg, fb = 255, 60, 60
        elseif fuel <= 25 then
                fr, fg, fb = 255, 170, 40
        end
        ringTrack(R_FUEL, T_FUEL, 255, 255, 255, 14)
        ringValue(R_FUEL, T_FUEL, fr, fg, fb, 235, fuel / 100)

        -- seatbelt band around the rim
        if beltCapable then
                if beltOn then
                        ringTrack(R_BELT, T_BELT, 60, 225, 110, 225)
                else
                        ringTrack(R_BELT, T_BELT, 255, 62, 62, pulse and 240 or 130)
                end
        end

        -- fuel label (top); blinks red under 10% like the old fuel warning icon
        local fuelAlpha = 245
        if fuel <= 10 then
                fuelAlpha = pulse and 255 or 120
                fr, fg, fb = 255, 60, 60
        end
        shadowText(string.format("FUEL %d%%", math.floor(fuel + 0.5)),
                G_CX - 62, G_CY - 72, G_CX + 62, G_CY - 56,
                tocolor(fr, fg, fb, fuelAlpha), 0.62, fontSmall(), "center")

        -- gear pill (red HANDBRAKE while the handbrake is up)
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
        local pillW = handbrake and 96 or 84
        local pillH = 22
        local pillX, pillY = G_CX - pillW / 2, G_CY - 52
        local pcR, pcG, pcB
        if handbrake then
                pcR, pcG, pcB = 200, 46, 46
        else
                pcR, pcG, pcB = themePrimary[1], themePrimary[2], themePrimary[3]
        end
        dxDrawRoundedRectangle(pillX - 1, pillY - 1, pillW + 2, pillH + 2,
                tocolor(pcR, pcG, pcB, 170), 9, true)
        dxDrawRoundedRectangle(pillX, pillY, pillW, pillH,
                tocolor(pcR, pcG, pcB, handbrake and 70 or 55), 8, true)
        shadowText(gearText, pillX, pillY, pillX + pillW, pillY + pillH,
                tocolor(255, 255, 255, 245), 0.78, fontSmall(), "center")

        -- speed digits
        local spdStr = tostring(math.floor(dispSpeed))
        local dScale = (#spdStr >= 4) and 1.55 or 2.0
        local digitColor = engineOn and tocolor(255, 255, 255, 255) or tocolor(255, 255, 255, 130)
        shadowText(spdStr, G_CX - G_R, G_CY - 24, G_CX + G_R, G_CY + 20,
                digitColor, dScale, fontLarge(), "center")

        -- unit (or engine state)
        if engineOn then
                shadowText(unitLabel, G_CX - G_R, G_CY + 26, G_CX + G_R, G_CY + 42,
                        tocolor(themePrimary[1], themePrimary[2], themePrimary[3], 245),
                        1.0, fontSmall(), "center")
        else
                shadowText("ENGINE OFF", G_CX - G_R, G_CY + 26, G_CX + G_R, G_CY + 42,
                        tocolor(255, 82, 82, 245), 1.0, fontSmall(), "center")
        end

        -- seatbelt band banner (red pulsing = unbuckled, green = buckled)
        if beltCapable then
                local bg = beltOn and tocolor(24, 132, 66, 245)
                        or tocolor(186, 28, 28, pulse and 250 or 180)
                dxDrawRoundedRectangle(BAND_X, BAND_Y, BAND_W, BAND_H, bg, 10, true)
                local tx0 = BAND_X + 6
                if beltTex then
                        dxDrawImage(BAND_X + 9, BAND_Y + 4, 16, 16, beltTex,
                                0, 0, 0, tocolor(255, 255, 255, 240), true)
                        tx0 = BAND_X + 30
                end
                local label = beltOn and "SEATBELT ON" or "FASTEN SEATBELT"
                shadowText(label, tx0, BAND_Y, BAND_X + BAND_W - 6, BAND_Y + BAND_H,
                        tocolor(255, 255, 255, 250), 0.85, fontSmall(), "center")
        end

        -- indicator arrows (old: arrow.png right rot 0 / left rot 180,
        -- green while blinking, theme primary while idle)
        if arrowTex then
                local asize = 40
                local ay = G_CY - asize / 2
                local idle = tocolor(themePrimary[1], themePrimary[2], themePrimary[3], 130)
                local colR = blinkRight and tocolor(0, 235, 90, 245) or idle
                local colL = blinkLeft and tocolor(0, 235, 90, 245) or idle
                dxDrawImage(G_CX + G_R + 22, ay, asize, asize, arrowTex, 0, 0, 0, colR, true)
                dxDrawImage(G_CX - G_R - 22 - asize, ay, asize, asize, arrowTex, 180, 0, 0, colL, true)
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
