--------------------------------------------------------------------------------
-- Vortex speedometer — client (Fix #32)
-- Ported from the OLD CLIENT [rp]/speedo/speedo_c_decompiled.lua (backupm):
--   * shown only in Automobile / Boat / Monster Truck / Quad / Bike
--   * big "%03d" speed + "KM/H" + "GEAR n" + RPM progress + fuel arc
--   * left/right indicator arrows on keys "," / "." (500ms green blink,
--     driven by the vehicle's temp:indicator data like the old client)
-- The old gauge art (SVG dial + arrow.png) shipped ENCRYPTED in the backup,
-- so the exact layout is rebuilt with the hud's analytic ring/disc shaders.
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- gauge geometry (bottom-right corner, free area - no radar in this build)
local G_R = 62                      -- gauge radius
local G_CX, G_CY = sx - 104, sy - 122

local arrowTex
local rpmSmooth = 0
local lastBlink = { left = 0, right = 0 }
local blinkLeft, blinkRight = false, false

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
        local ok, f = pcall(function() return exports.UIKit:getUIFont("hud-large") end)
        return (ok and f) or "default-bold"
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

local function fuelPercent(veh)
        -- new stack keeps fuel in element data "fuel" (fuel-system), max per model
        local fuel = tonumber(getElementData(veh, "fuel"))
        if not fuel then
                -- fallback: vehicle health as a 0..100 gauge
                local h = getElementHealth(veh)
                if h > 1000 then h = 100 end
                return math.max(0, math.min(100, h))
        end
        local mx = 100
        local ok, v = pcall(function() return exports["fuel-system"]:getMaxFuel(getElementModel(veh)) end)
        if ok and type(v) == "number" and v > 0 then mx = v end
        return math.max(0, math.min(100, fuel / mx * 100))
end

local function drawRingArc(cx, cy, size, radius, stroke, r, g, b, a, progress)
        if progress <= 0.003 then return end
        drawSmoothRingG(cx, cy, size, radius, stroke, r, g, b, a, math.min(progress, 1), true)
end

local function speedoDraw()
        if not isHudShowing or not isHudShowing() then return end
        local veh = getPedOccupiedVehicle(localPlayer)
        if not veh or not isElement(veh) or not vehicleAllowed(veh) then return end

        local now = getTickCount()

        -- indicators: temp:indicator 2 = left, 3 = right (old client data)
        local ind = tonumber(getElementData(veh, "temp:indicator"))
        local phase = math.floor(now / 500) % 2 == 0
        blinkRight = ind == 3 and phase
        blinkLeft = ind == 2 and (not phase)

        -- RPM model (old client: idle ~650, redline 9000, 0 with engine off)
        local kmh = getVehicleSpeedKmh(veh)
        local target = 0
        if getVehicleEngineState(veh) then
                target = 650 + math.min(kmh, 260) / 260 * 8350
        end
        rpmSmooth = rpmSmooth + (target - rpmSmooth) * 0.12
        local rpmProgress = math.max(0, math.min(1, rpmSmooth / 9000))

        local fuel = fuelPercent(veh)

        -- dial: dark disc + thin rim
        drawSmoothDiscG(G_CX, G_CY, G_R + 4, 8, 5, 16, 150, true)
        drawSmoothRingG(G_CX, G_CY, (G_R + 4) * 2, G_R + 3, 1.5, 255, 255, 255, 26, 1, true)

        -- RPM progress ring (theme primary, old SVG stroke behaviour)
        drawRingArc(G_CX, G_CY, (G_R + 4) * 2, G_R - 3, 4,
                themePrimary[1], themePrimary[2], themePrimary[3], 235, rpmProgress)

        -- fuel arc (thin, inside): green / orange / red
        local fr, fg, fb = 80, 220, 90
        if fuel <= 15 then
                fr, fg, fb = 255, 60, 60
        elseif fuel <= 25 then
                fr, fg, fb = 255, 170, 40
        end
        drawRingArc(G_CX, G_CY, (G_R - 8) * 2, G_R - 10, 2.5, fr, fg, fb, 220, fuel / 100)

        -- speed digits (old: %03d, hud-large, centered) + KM/H + GEAR
        local font = fontLarge()
        dxDrawText(string.format("%03d", math.floor(kmh)), G_CX - G_R, G_CY - 26,
                G_CX + G_R, G_CY + 26, tocolor(255, 255, 255, 255), 0.9, font,
                "center", "center", false, false, true)
        dxDrawText("KM/H", G_CX - G_R, G_CY + 26, G_CX + G_R, G_CY + 48,
                tocolor(255, 255, 255, 150), 0.55, font, "center", "center", false, false, true)
        local gear = getVehicleCurrentGear and getVehicleCurrentGear(veh) or 0
        dxDrawText("GEAR " .. tostring(gear), G_CX - G_R, G_CY - 52, G_CX + G_R, G_CY - 30,
                tocolor(255, 255, 255, 150), 0.55, font, "center", "center", false, false, true)

        -- indicator arrows (old: arrow.png right rot 0 / left rot 180,
        -- green while blinking, white 220 otherwise)
        if arrowTex then
                local asize = 26
                local axR, ayR = G_CX + G_R + 18, G_CY - asize / 2
                local axL, ayL = G_CX - G_R - 18 - asize, G_CY - asize / 2
                local colR = blinkRight and tocolor(0, 255, 0, 235) or tocolor(255, 255, 255, 150)
                local colL = blinkLeft and tocolor(0, 255, 0, 235) or tocolor(255, 255, 255, 150)
                dxDrawImage(axR, ayR, asize, asize, arrowTex, 0, 0, 0, colR, true)
                dxDrawImage(axL, ayL, asize, asize, arrowTex, 180, 0, 0, colL, true)
        end
end

-- indicator keys (old client: "." right, "," left; driver only)
local function setIndicator(which)
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
        if fileExists("images/arrow.png") then
                arrowTex = dxCreateTexture("images/arrow.png", "argb", true, "clamp")
        end
        addEventHandler("onClientRender", root, speedoDraw, false, "high-2")
end)
