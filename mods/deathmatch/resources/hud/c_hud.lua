--------------------------------------------------------------------------------
-- VORTEX HUD — client
-- Ported 1:1 from the old client source (github.com/h0-5/backupm, hud resource)
-- visual fidelity: same layout, colors, sizes, fonts, animations, event names.
-- Data sources adapted to this server's stack, every foreign export guarded.
--
-- blocks (old client):
--   * statusHud      top-right: SVG progress rings (health/shield/fatigue/...),
--                    clock + date, money pill  (+coins pill when the coins
--                    system is ever restored), soft hud_bg panels
--   * zone label     bottom-left above radar: City | Zone + SAFE/DANGER zone
--   * drawHUD        F4 slide-down icon strip (hold or toggle) + in-vehicle
--                    engine/handbrake/seatbelt/lights/lock row + tooltips
--   * nametags       see c_nametags.lua (rank title + colored name + icons)
--   * fatigue        sprint drains, rest recovers, 95% = forced tired
--   * fps            bottom-left "N FPS" + /fps
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- [old client] UIKit fonts ----------------------------------------------------
local dxFontDefault, dxFontLarge, dxFontHudLarge, dxFontHud

local function UIKitReady()
        local ok, eui = pcall(function() return exports.UIKit end)
        if not ok or not eui then return end
        dxFontDefault = eui:getUIFont("ui-default")
        dxFontLarge   = eui:getUIFont("default-large")
        dxFontHudLarge= eui:getUIFont("hud-large")
        dxFontHud     = eui:getUIFont("hud")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function fontDefault() return dxFontDefault or "default-bold" end
local function fontHud()     return dxFontHud or "default" end
local function fontLarge()   return dxFontLarge or "default-bold" end

-- [old client] textures -------------------------------------------------------
-- the backup ships no images (they were file-protected), so every icon resolves
-- to an existing asset of this server; anything missing simply never renders.
local tex = {}
local ICON_DIR = "images/hud/"
local ICON_FILES = {
        showhud        = "hide_username.png",
        tagmode        = "tagmode.png",
        walkingstyle   = "walkingstyle.png",
        head_turning   = "head_turning.png",
        togpm          = "togpm.png",
        reportpanel    = "reportpanel_on.png",
        ads            = "ads.png",
        admin_badge    = "admin.png",
        adminduty      = "admin.png",
        engine         = "engine.png",
        vehicle_engine = "engine.png",
        handbrake      = "handbrake.png",
        vehicle_handbrake = "handbrake.png",
        seatbelt       = "seatbelt.png",
        vehicle_seatbelt  = "seatbelt.png",
        car_lights     = "headlights.png",
        vehicle_lights    = "headlights.png",
        car_lock       = "carlock.png",
        vehicle_lock      = "carlock.png",
        mask           = "mask.png",
        gasmask        = "gasmask.png",
        blindfold      = "bandana.png",
        medical_mask   = "mask.png",
        handcuffs      = "handcuffs.png",
        phone          = "phone.png",
        heart          = "health.png",
        health         = "health.png",
        shield         = "armour.png",
        police         = "badge1.png",
        facbadge       = "badge2.png",
        AFK            = "afk.png",
        fatigue        = "walkingstyle.png",
}

local function resolveIcon(name)
        local file = ICON_FILES[name]
        if not file then return nil end
        if fileExists(ICON_DIR .. file) then return ICON_DIR .. file end
        return nil
end

local function loadTextures()
        tex.bg = fileExists("hud_bg.png") and dxCreateTexture("hud_bg.png", "argb", true, "clamp") or nil
        for name in pairs(ICON_FILES) do
                local path = resolveIcon(name)
                if path then tex[name] = path end
        end
end

-- [old client] config (exports.settings was the old source; guarded) ----------
local CONFIG = {
        hold    = false,  -- F4 held down opens the strip, released closes it
        right   = false,  -- strip hugs the right edge instead of centered
        hideClock = false,
        safeZones = {     -- zone names (getZoneName) counted as SAFE ZONE
                ["East Beach"] = true,
                ["Commerce"]   = true,
        },
}

local function refreshConfig()
        if getResourceFromName("settings") and getResourceState(getResourceFromName("settings")) == "running" then
                local ok, val
                ok, val = pcall(function() return exports.settings:getSetting("Hud:hold") end)
                if ok and val ~= nil then CONFIG.hold = val end
                ok, val = pcall(function() return exports.settings:getSetting("Hud:right") end)
                if ok and val ~= nil then CONFIG.right = val end
                ok, val = pcall(function() return exports.settings:getSetting("Hud:hideClock") end)
                if ok and val ~= nil then CONFIG.hideClock = val end
        end
end

-- [old client] helpers --------------------------------------------------------
function isMouseInPosition(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        cx, cy = cx * sx, cy * sy
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function dxDrawRoundedRectangle(x, y, w, h, color, radius, postGUI)
        radius = radius or 8
        if w < radius * 2 or h < radius * 2 then
                dxDrawRectangle(x, y, w, h, color, postGUI)
                return
        end
        dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI)
        dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI)
        dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI)
        dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 7, postGUI)
        dxDrawCircle(x + w - radius, y + radius, radius, 270, 360, color, color, 7, postGUI)
        dxDrawCircle(x + w - radius, y + h - radius, radius, 0, 90, color, color, 7, postGUI)
        dxDrawCircle(x + radius, y + h - radius, radius, 90, 180, color, color, 7, postGUI)
end

-- soft dark panel exactly like the old client: hud_bg stretched, tinted
local PANEL_TINT = tocolor(0, 8, 20, 180)
local function drawPanel(x, y, w, h, postGUI)
        if tex.bg then
                dxDrawImage(x, y, w, h, tex.bg, 0, 0, 0, PANEL_TINT, postGUI)
        else
                dxDrawRoundedRectangle(x, y, w, h, PANEL_TINT, 8, postGUI)
        end
end

local function anim(startTick, duration, fromValue, toValue)
        local t = 0
        if duration > 0 then
                t = (getTickCount() - startTick) / duration
        end
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        return fromValue + (toValue - fromValue) * t
end

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY, postGUI)
        -- old client 4-pass black outline + white fill
        local black = tocolor(0, 0, 0, 255)
        dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, postGUI)
end

-- [old client] hud settings API (kept for cross-resource compatibility) -------
local hudSettings = { showhud = true, tagmode = true, seatbelt = false }
local hudItems = {}          -- element data mirror (old {id, state, icon, tip1, tip2, category})
local hudState = false       -- strip open?
local visibleItems = {}      -- resolved strip list (rebuilt when data changes)

function isHudShowing() return hudSettings.showhud end
function getHudSetting(key) return hudSettings[key] or false end

function setHudSetting(key, value)
        for _, item in ipairs(visibleItems) do
                if item.id == key then
                        item.state = value and "on" or "off"
                        break
                end
        end
        hudSettings[key] = value and true or false
end

local function rebuildVisibleItems()
        visibleItems = {}
        -- the old client listed "showhud" first, then whatever resources pushed in
        table.insert(visibleItems, {
                id = "showhud", state = hudSettings.showhud and "on" or "off",
                icon = tex.showhud, tip1 = "Show/Hide Hud", category = "local",
        })
        if #hudItems > 0 then
                for _, item in ipairs(hudItems) do
                        table.insert(visibleItems, {
                                id = item[1], state = item[2],
                                icon = resolveIcon(item[3]) or resolveIcon(item[1]),
                                tip1 = item[4], tip2 = item[5], category = item[6],
                        })
                end
        else
                -- this server's defaults, mapped onto systems that actually exist here
                local defaults = {
                        { "tagmode",      "on", "tagmode",      "Show/Hide Names" },
                        { "walkingstyle", "on", "walkingstyle", "Next Walking Style" },
                        { "head_turning", "on", "head_turning", "Head Turning" },
                        { "togpm",        "on", "togpm",        "Toggle Personal Messages" },
                        { "reportpanel",  "on", "reportpanel",  "Report Center" },
                        { "ads",          "on", "ads",          "Advertisements" },
                }
                for _, d in ipairs(defaults) do
                        table.insert(visibleItems, {
                                id = d[1], state = d[2], icon = tex[d[3]], tip1 = d[4], category = nil,
                        })
                end
        end
        local integrationOK = getResourceFromName("integration")
                and getResourceState(getResourceFromName("integration")) == "running"
        if integrationOK and isElement(localPlayer)
                and exports.integration:isPlayerTrialAdmin(localPlayer) then
                table.insert(visibleItems, {
                        id = "adminduty", state = (getElementData(localPlayer, "duty_admin") == 1) and "on" or "off",
                        icon = tex.adminduty, tip1 = "Admin Duty", category = "client",
                })
        end
end

function updateHudItemsList(items)
        items = items or getElementData(localPlayer, "hud:items") or {}
        hudItems = items
        rebuildVisibleItems()
end

function addHudItem(id, state, tip1, tip2, iconName, category)
        local list = getElementData(localPlayer, "hud:items") or {}
        table.insert(list, { id, state, iconName or id, tip1, tip2, category })
        setElementData(localPlayer, "hud:items", list)
end

function removeHudItem(id)
        local list = getElementData(localPlayer, "hud:items") or {}
        for i, item in ipairs(list) do
                if item[1] == id then
                        table.remove(list, i)
                        triggerEvent("hud:onClientPlayerHudItemRemove", localPlayer, id)
                        break
                end
        end
        setElementData(localPlayer, "hud:items", list)
end

function isHudItemExists(id)
        for _, item in ipairs(getElementData(localPlayer, "hud:items") or {}) do
                if item[1] == id then return true end
        end
        return false
end

function getHudItemData(id)
        for _, item in ipairs(getElementData(localPlayer, "hud:items") or {}) do
                if item[1] == id then return item[5] end
        end
        return false
end

function getBGTexture() return tex.bg end

addEventHandler("onClientElementDataChange", localPlayer, function(key, _, newValue)
        if key == "hud:items" then
                updateHudItemsList(newValue)
        end
end)

--------------------------------------------------------------------------------
-- STATUS HUD — top-right rings (old client colors, exact)
--------------------------------------------------------------------------------
local RING_SIZE, RING_GAP = 26, 8
local PANEL_TOPY, PANEL_H = 6, RING_SIZE + 14
local RIGHT_MARGIN = 14

local RING_DEFS = {
        -- id          svg color     icon tint (old client exact)      icon file
        { id = "health",    color = "#00ff85", tint = {0, 255, 132},   icon = "health"  },
        { id = "sleepy",    color = "#7dffea", tint = {255, 255, 255}, icon = nil       },
        { id = "thirsty",   color = "#4de4ff", tint = {77, 228, 255},  icon = nil       },
        { id = "hungry",    color = "#caff00", tint = {202, 255, 0},   icon = nil       },
        { id = "urine",     color = "#f3ffb5", tint = {255, 255, 255}, icon = nil       },
        { id = "fatigue",   color = "#71ffdd", tint = {113, 255, 221}, icon = "fatigue" },
        { id = "cleanness", color = "#ffffff", tint = {255, 255, 255}, icon = nil       },
        { id = "shield",    color = "#ffffff", tint = {255, 255, 255}, icon = "shield"  },
}
local rings = {}          -- [id] = {value, svg, xml, progressNode, visible}
local ringOrder = {}      -- visible ids in draw order (rebuilt on change)

local function clampPercent(v)
        if v < 0 then v = 0 elseif v > 100 then v = 100 end
        return v
end

local RING_XML = [[<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
<circle cx="50" cy="50" r="50" fill="none" stroke="%s" stroke-width="9"
 stroke-linecap="round" stroke-dasharray="315" stroke-dashoffset="315"
 transform="rotate(-90 50 50)"/>
</svg>]]

local svgSupported = type(svgCreate) == "function"

local function createRing(id, colorHex)
        local ring = { value = 0, visible = false }
        if svgSupported then
                local xml = string.format(RING_XML, colorHex)
                ring.template = xml
                ring.svg = svgCreate(100, 100, xml)
        end
        rings[id] = ring
        return ring
end

function setProgress(id, value)
        local ring = rings[id]
        if not ring then return end
        value = clampPercent(tonumber(value) or 0)
        ring.value = value
        if ring.svg and svgSetDocumentXML and ring.template then
                -- old client: stroke-dashoffset = 315 - value / 100 * 315
                local offset = string.format("%.1f", 315 - value / 100 * 315)
                local updated = ring.template:gsub('stroke%-dashoffset="[%d%.]+"',
                        'stroke-dashoffset="' .. offset .. '"')
                pcall(svgSetDocumentXML, ring.svg, updated)
        end
end

local function rebuildRingOrder()
        ringOrder = {}
        for _, def in ipairs(RING_DEFS) do
                local ring = rings[def.id]
                if ring and ring.visible then
                        table.insert(ringOrder, def)
                end
        end
end

local function setRingVisible(id, visible)
        local ring = rings[id]
        if not ring or ring.visible == visible then return end
        ring.visible = visible
        rebuildRingOrder()
end

local function drawRing(def, x, y, size)
        local ring = rings[def.id]
        if not ring then return end
        local t = getTickCount()
        -- old client pulse: sin(tick / 300) * 230 drives the blink of critical stats
        local pulse = math.abs(math.sin(t / 300)) * 230
        if ring.svg then
                dxDrawImage(x, y, size, size, ring.svg, 0, 0, 0, tocolor(255, 255, 255, 255), true)
        else
                -- fallback ring via dxDrawCircle arc (starts at top, sweeps clockwise)
                local radius = size / 2 - 2
                local cx, cy = x + size / 2, y + size / 2
                local sweep = 360 * (ring.value / 100)
                if sweep > 0.5 then
                        dxDrawCircle(cx, cy, radius, 270, 270 + sweep, tocolor(def.tint[1], def.tint[2], def.tint[3], 255), def.tint, 4, true)
                end
        end
        if def.icon and tex[def.icon] then
                local iconAlpha
                if def.id == "health" then
                        iconAlpha = ring.value > 10 and 220 or pulse
                elseif def.id == "fatigue" then
                        iconAlpha = ring.value < 90 and 220 or pulse
                else
                        iconAlpha = 220
                end
                local pad = size * 0.22
                dxDrawImage(x + pad, y + pad, size - pad * 2, size - pad * 2, tex[def.icon],
                        0, 0, 0, tocolor(def.tint[1], def.tint[2], def.tint[3], iconAlpha), true)
        end
end

-- max health exactly like the old client formula
local function healthPercent()
        local maxHealth = 0.232018558500192 * getPedStat(localPlayer, 24) - 32.018558511152
        if maxHealth <= 0 then return 0 end
        local pct = getElementHealth(localPlayer) / maxHealth
        if pct < 0 then pct = 0 end
        return clampPercent(pct * 100)
end

--------------------------------------------------------------------------------
-- statusHud draw handler
--------------------------------------------------------------------------------
local statusHud = { visible = false }
local statusHudDraw -- forward declaration (assigned below)

function showStatusHud(state)
        if state == statusHud.visible then return end
        if state then
                addEventHandler("onClientRender", root, statusHudDraw, false, "high-5")
                local life = getResourceFromName("life-system")
                if life and getResourceState(life) == "running" then
                        -- restored old hooks: thirsty/hungry/urine/sleepy/cleanness
                        local ok, st = pcall(function() return exports["life-system"]:getCharacterStatus("thirsty") end)
                        if ok and st then setProgress("thirsty", st) end
                        local ok2, st2 = pcall(function() return exports["life-system"]:getCharacterStatus("hungry") end)
                        if ok2 and st2 then setProgress("hungry", st2) end
                        setRingVisible("thirsty", ok2 or ok)
                        setRingVisible("hungry", ok2 or ok)
                end
                setRingVisible("health", true)
        else
                removeEventHandler("onClientRender", root, statusHudDraw)
        end
        statusHud.visible = state
end

-- one-second sync (old client): clock, zone safety, armor, health, fatigue
local zoneText = ""
local zoneLabel, zoneLabelColor = "", tocolor(255, 255, 255, 255)
local wasDanger = false
local fatigue = 0
local fatigueTired = false
local lastHealth, lastArmor = -1, -1

local function getCurrentTime()
        local t = getRealTime()
        local h = t.hour % 12
        if h == 0 then h = 12 end
        local suffix = t.hour < 12 and "AM" or "PM"
        return string.format("%d:%02d %s", h, t.minute, suffix)
end

local function getCurrentDate()
        local t = getRealTime()
        return string.format("%02d-%02d-%04d", t.monthday, t.month + 1, t.year + 1900)
end

setTimer(function()
        if not statusHud.visible then return end

        -- health / armor
        local hp = healthPercent()
        if hp ~= lastHealth then
                lastHealth = hp
                setProgress("health", hp)
        end
        local armor = tonumber(getElementData(localPlayer, "temp:armor")) or getPedArmor(localPlayer)
        if armor ~= lastArmor then
                lastArmor = armor
                setProgress("shield", armor)
                setRingVisible("shield", armor > 0)
        end

        -- zone + safety (old client)
        local x, y, z = getElementPosition(localPlayer)
        local city = getZoneName(x, y, z, true)
        local zone = getZoneName(x, y, z, false)
        zoneText = "#bfbfbf" .. city .. " #ffffff| " .. zone
        if getElementInterior(localPlayer) == 0 then
                if CONFIG.safeZones[zone] or CONFIG.safeZones[city] then
                        zoneLabel = "SAFE ZONE"
                        zoneLabelColor = tocolor(153, 255, 0, 255)
                        wasDanger = false
                else
                        if zoneLabel ~= "DANGER ZONE" and not wasDanger then
                                wasDanger = true
                                local notified = false
                                if getResourceFromName("notifications")
                                        and getResourceState(getResourceFromName("notifications")) == "running" then
                                        pcall(function()
                                                exports.notifications:output({
                                                        en = "#ff3030You are now in an unsafe area, you must be careful",
                                                        ar = "#ff3030انت الان في منطقة غير أمنة، يجب عليك الانذار",
                                                }, 6000, "danger")
                                        end)
                                        notified = true
                                end
                                if not notified then
                                        outputChatBox("#ff3030You are now in an unsafe area, you must be careful | انت الان في منطقة غير أمنة، يجب عليك الانذار", 255, 48, 48)
                                end
                        end
                        zoneLabel = "DANGER ZONE"
                        zoneLabelColor = tocolor(255, 0, 0, 255)
                end
        else
                zoneLabel = "NORMAL ZONE"
                zoneLabelColor = tocolor(255, 255, 255, 255)
                wasDanger = false
        end

        -- fatigue (old client drain/recover table, exact deltas)
        local k = ((tonumber(getElementData(localPlayer, "temp:drugEffect")) or 1) + 10)
                * ((1 - getPedStat(localPlayer, 22) / 1000) * 0.8)
        local before = fatigue
        if isElementInWater(localPlayer) and not isPedInVehicle(localPlayer) then
                if getPedControlState(localPlayer, "sprint") then
                        fatigue = fatigue + (3 + k)
                elseif getPedControlState(localPlayer, "forwards") then
                        fatigue = fatigue + (2 + k)
                else
                        fatigue = fatigue + (1 + k)
                end
        elseif not getPedMoveState(localPlayer) or getPedMoveState(localPlayer) == "stand" then
                fatigue = fatigue - 4
        elseif getPedMoveState(localPlayer) == "walk" then
                fatigue = fatigue - 2
        elseif getPedMoveState(localPlayer) == "powerwalk" then
                fatigue = fatigue + (3 + k)
        elseif getPedMoveState(localPlayer) == "jog" then
                fatigue = fatigue + (2 + k)
        elseif getPedMoveState(localPlayer) == "sprint" then
                fatigue = fatigue + (getPedWalkingStyle(localPlayer) == 54 and (3 + k) or (2 + k))
        elseif getPedMoveState(localPlayer) == "jump" then
                fatigue = fatigue + (4 + k)
        elseif getPedMoveState(localPlayer) == "climb" then
                fatigue = fatigue + (5 + k)
        end
        fatigue = math.max(0, math.min(100, fatigue))
        if fatigue ~= before then
                setProgress("fatigue", fatigue)
                setRingVisible("fatigue", fatigue > 5)
        end

        -- forced tired at 95% (old client), recovered at 50%
        if fatigue >= 95 and not fatigueTired then
                setElementData(localPlayer, "temp:block.anims", true)
                if isElementInWater(localPlayer) then
                        fadeCamera(false, 0.5, 255, 0, 0)
                        setTimer(fadeCamera, 200, 1, true, 0.3, 255, 0, 0)
                        setElementHealth(localPlayer, getElementHealth(localPlayer) - 1)
                else
                        fatigueTired = true
                        setPedControlState(localPlayer, "forwards", false)
                        setPedControlState(localPlayer, "jump", false)
                        setPedControlState(localPlayer, "sprint", false)
                        setPedControlState(localPlayer, "walk", false)
                        local life = getResourceFromName("life-system")
                        if life and getResourceState(life) == "running" then
                                pcall(function()
                                        triggerServerEvent("life:setAnimation", localPlayer, "FAT", "idle_tired", -1, true, false, false, false)
                                end)
                        end
                end
        elseif fatigue <= 50 and fatigueTired then
                fatigueTired = false
                local life = getResourceFromName("life-system")
                if life and getResourceState(life) == "running" then
                        pcall(function() triggerServerEvent("life:setAnimation", localPlayer) end)
                end
                setElementData(localPlayer, "temp:block.anims", nil)
        end
end, 1000, 0)

-- life-system restored later: its status change event lights the rings up
addEvent("onClientCharacterStatusChange", true)
addEventHandler("onClientCharacterStatusChange", localPlayer, function(status)
        if type(status) ~= "table" then return end
        setProgress("thirsty", status.thirsty or 0)
        setProgress("hungry", status.hungry or 0)
        setProgress("urine", status.urine or 0)
        setProgress("sleepy", status.sleepy or 0)
        setProgress("cleanness", status.cleanness or 0)
        setRingVisible("thirsty", true)
        setRingVisible("hungry", true)
        setRingVisible("urine", true)
        setRingVisible("sleepy", true)
        setRingVisible("cleanness", true)
end)

local function statusHudDrawImpl()
        if not statusHud.visible or not isHudShowing() then return end
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "character:id") then return end

        -- rings row, right aligned (old client: panel + row of 26px rings)
        local count = #ringOrder
        local rowW = count > 0 and (count * RING_SIZE + (count - 1) * RING_GAP) or 0
        local panelX = sx - rowW - RIGHT_MARGIN - 10
        local panelW = rowW + 20
        drawPanel(panelX, PANEL_TOPY, panelW, PANEL_H, true)
        dxDrawRectangle(panelX, PANEL_TOPY, panelW, 1, tocolor(255, 255, 255, 150), true)
        dxDrawRectangle(panelX, PANEL_TOPY + PANEL_H, panelW, 1, tocolor(255, 255, 255, 150), true)

        local x = sx - RIGHT_MARGIN - RING_SIZE
        for i = count, 1, -1 do
                local def = ringOrder[i]
                drawRing(def, x, PANEL_TOPY + 7, RING_SIZE)
                x = x - RING_SIZE - RING_GAP
        end

        -- clock + date (old client formats)
        local textY = PANEL_TOPY + PANEL_H + 6
        if not CONFIG.hideClock then
                outlineText(getCurrentTime(), sx - RIGHT_MARGIN - 120, textY, 120, 22,
                        tocolor(255, 255, 255, 255), 1, fontDefault(), "right", "top", true)
                outlineText(getCurrentDate(), sx - RIGHT_MARGIN - 120, textY + 20, 120, 16,
                        tocolor(255, 255, 255, 200), 0.8, fontHud(), "right", "top", true)
                textY = textY + 44
        end

        -- money pill (old client: soft panel + green $ + amount), coins only when
        -- the coins system exists again — coins sit nearest the screen edge
        local money = getPlayerMoney()
        local pillW, pillH = 152, 28
        local coins = tonumber(getElementData(localPlayer, "bios:coins"))
        local moneyX = sx - RIGHT_MARGIN - pillW
        if coins then
                local pillW2, pillH2 = 110, 28
                local pill2X = sx - RIGHT_MARGIN - pillW2
                drawPanel(pill2X, textY, pillW2, pillH2, true)
                dxDrawCircle(pill2X + 14, textY + pillH2 / 2, 8.5, 0, 360,
                        tocolor(255, 45, 45, 255), tocolor(255, 45, 45, 255), 12, true)
                dxDrawText(tostring(coins), pill2X + 30, textY, pill2X + pillW2 - 6, textY + pillH2,
                        tocolor(255, 255, 255, 255), 0.8, fontHud(), "right", "center", false, false, true)
                moneyX = pill2X - 8 - pillW
        end
        drawPanel(moneyX, textY, pillW, pillH, true)
        dxDrawCircle(moneyX + 14, textY + pillH / 2, 8.5, 0, 360,
                tocolor(0, 255, 133, 255), tocolor(0, 255, 133, 255), 12, true)
        dxDrawText("$", moneyX + 5, textY + pillH / 2 - 8, moneyX + 23,
                textY + pillH / 2 + 8, tocolor(10, 30, 20, 255), 0.7, fontDefault(), "center", "center", false, false, true)
        dxDrawText(tostring(money), moneyX + 30, textY, moneyX + pillW - 6,
                textY + pillH, tocolor(255, 255, 255, 255), 0.8, fontHud(), "right", "center", false, false, true)

        -- zone label, bottom-left above the radar (old client look)
        outlineText(zoneText:gsub("#%x%x%x%x%x%x", ""), 18, sy - 206, 320, 16,
                tocolor(255, 255, 255, 255), 0.85, fontHud(), "left", "top", true)
        outlineText(zoneLabel, 18, sy - 188, 320, 16, zoneLabelColor, 0.85, fontHud(), "left", "top", true)
end
statusHudDraw = statusHudDrawImpl

--------------------------------------------------------------------------------
-- F4 STRIP — slide-down icon strip (old client: 32px icons, 37px pitch,
-- rounded (15,15,15,250) panel, hover tooltip below, click debounced 1s)
--------------------------------------------------------------------------------
local STRIP_ICON, STRIP_PITCH, STRIP_PAD = 32, 32, 15
local STRIP_H = 37
local stripAnim = { count = 0, time = 250, from = -STRIP_H - 2, to = -STRIP_H - 2, current = -STRIP_H - 2 }
local hoveredItem = 0
local hoveredVehItem = 0
local lastItemClick = 0

local VEH_ITEMS = {
        { key = "vehicle_engine",    icon = "engine" },
        { key = "vehicle_handbrake", icon = "handbrake" },
        { key = "vehicle_seatbelt",  icon = "seatbelt" },
        { key = "vehicle_lights",    icon = "car_lights" },
        { key = "vehicle_lock",      icon = "car_lock" },
}

local function playSelectSound()
        if fileExists(":assets/sounds/select.wav") then
                playSound(":assets/sounds/select.wav", false)
        end
end

local function stripGeometry(itemCount)
        local w = STRIP_PITCH * itemCount + STRIP_PAD
        local x = CONFIG.right and (sx - w - 5) or (sx - w) / 2
        return x, stripAnim.current, w, STRIP_H
end

local function drawHUD()
        stripAnim.current = anim(stripAnim.count, stripAnim.time, stripAnim.from, stripAnim.to)
        hoveredItem = 0
        hoveredVehItem = 0

        -- strip draws even when the HUD stats are hidden; F4 opens it
        if stripAnim.current > -STRIP_H / 2 - 2 then
                local items = visibleItems
                local count = #items
                if count > 0 then
                        local px, py, pw, ph = stripGeometry(count)
                        dxDrawRoundedRectangle(px, py, pw, ph, tocolor(15, 15, 15, 250), 8, true)
                        local iconX = px + STRIP_PAD / 2
                        for i, item in ipairs(items) do
                                if item.icon then
                                        local active = item.state == "on"
                                        dxDrawImage(iconX, py + 2.5, STRIP_ICON, STRIP_ICON, item.icon, 0, 0, 0,
                                                tocolor(255, 255, 255, active and 255 or 130), true)
                                end
                                if isMouseInPosition(iconX - 1, py, STRIP_PITCH + 2, ph) then
                                        hoveredItem = i
                                end
                                iconX = iconX + STRIP_PITCH
                        end
                        -- tooltip below the strip (old client position + outline)
                        local tip = items[hoveredItem]
                        if tip and tip.tip1 and tip.tip1 ~= "" then
                                local tipY = py + ph + 5
                                outlineText(tip.tip1, 10, tipY, sx - 20, 40,
                                        tocolor(255, 255, 255, 230), 1, "default-bold", CONFIG.right and "right" or "center", "top", true)
                        end
                end
        end

        -- in-vehicle row (driver only): engine/handbrake/seatbelt/lights/lock
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleController(veh) == localPlayer then
                local size = 24
                local gap = 5
                local rowW = #VEH_ITEMS * size + (#VEH_ITEMS - 1) * gap
                local vx = sx - rowW - RIGHT_MARGIN
                -- pinned under the rings panel (old client kept it near the strip)
                local vy = PANEL_TOPY + PANEL_H + 8
                local seatbeltOn = getHudSetting("seatbelt")
                for i, item in ipairs(VEH_ITEMS) do
                        local active = false
                        if item.key == "vehicle_engine" then
                                active = getVehicleEngineState(veh)
                        elseif item.key == "vehicle_handbrake" then
                                active = tonumber(getElementData(veh, "handbrake") or 0) == 1
                                        or getElementData(veh, "handbrake") == true
                        elseif item.key == "vehicle_seatbelt" then
                                active = seatbeltOn or getElementData(localPlayer, "seatbelt") == true
                        elseif item.key == "vehicle_lights" then
                                active = getVehicleOverrideLights(veh) ~= 1
                        elseif item.key == "vehicle_lock" then
                                active = isVehicleLocked(veh)
                        end
                        if tex[item.icon] then
                                dxDrawImage(vx, vy, size, size, tex[item.icon], 0, 0, 0,
                                        tocolor(255, 255, 255, active and 255 or 110), true)
                        end
                        if isMouseInPosition(vx - 2, vy - 2, size + 4, size + 4) then
                                hoveredVehItem = i
                        end
                        vx = vx + size + gap
                end
                local hovered = VEH_ITEMS[hoveredVehItem]
                if hovered then
                        local labels = {
                                vehicle_engine = "Engine", vehicle_handbrake = "Handbrake",
                                vehicle_seatbelt = "Seatbelt", vehicle_lights = "Lights",
                                vehicle_lock = "Lock",
                        }
                        outlineText(labels[hovered.key] or "", 10, PANEL_TOPY + PANEL_H + 34, sx - 20, 30,
                                tocolor(255, 255, 255, 230), 1, "default-bold", "right", "top", true)
                end
        end
end
addEventHandler("onClientRender", root, drawHUD, false, "low-5")

-- [old client] F4 both-direction binding: hold mode or toggle mode
bindKey("F4", "both", function(_, press)
        refreshConfig()
        if CONFIG.hold then
                if press == "down" then
                        stripAnim.count = getTickCount()
                        stripAnim.from = stripAnim.current
                        stripAnim.to = 2
                        showCursor(true)
                        hudState = true
                else
                        stripAnim.count = getTickCount()
                        stripAnim.from = stripAnim.current
                        stripAnim.to = -STRIP_H / 2 - 2
                        showCursor(false, false)
                        hudState = false
                end
        elseif press == "down" then
                if hudState then
                        stripAnim.count = getTickCount()
                        stripAnim.from = stripAnim.current
                        stripAnim.to = -STRIP_H / 2 - 2
                        hudState = false
                else
                        stripAnim.count = getTickCount()
                        stripAnim.from = stripAnim.current
                        stripAnim.to = 2
                        hudState = true
                end
        end
end)

addEvent("onClientSettingChange", true)
addEventHandler("onClientSettingChange", localPlayer, function(key, _, value)
        if key == "Hud:hideClock" then
                CONFIG.hideClock = value
        elseif key == "Hud:right" then
                CONFIG.right = value
        end
end)

-- [old client] click dispatch (1s debounce) -----------------------------------
addEventHandler("onClientClick", root, function(button, state)
        if not isCursorShowing() or state ~= "down" then return end

        if hoveredItem ~= 0 then
                local now = getTickCount()
                if now - lastItemClick < 1000 then return end
                lastItemClick = now
                playSelectSound()
                local item = visibleItems[hoveredItem]
                if not item then return end

                if item.id == "showhud" then
                        setHudSetting("showhud", not hudSettings.showhud)
                        triggerEvent("onClientHudVisibilityChange", localPlayer, hudSettings.showhud)
                elseif item.id == "tagmode" then
                        setHudSetting("tagmode", not hudSettings.tagmode)
                elseif item.id == "head_turning" then
                        local current = getElementData(localPlayer, "head_turning") or "0"
                        local next_ = current == "1" and "2" or (current == "2" and "0" or "1")
                        triggerEvent("accounts:settings:updateCharacterSettings", localPlayer, "head_turning", next_)
                elseif item.id == "adminduty" then
                        local newDuty = getElementData(localPlayer, "duty_admin") == 1 and 0 or 1
                        if newDuty == 0 then
                                triggerEvent("accounts:settings:updateAccountSettings", localPlayer, "duty_admin", 0)
                        else
                                triggerEvent("accounts:settings:updateAccountSettings", localPlayer, "duty_admin", 1)
                        end
                        rebuildVisibleItems()
                elseif item.category ~= "disable-click" then
                        -- everything else routes through the old server event
                        triggerServerEvent("hud:onHudItemClick", localPlayer, item.id)
                end
        end

        if hoveredVehItem ~= 0 then
                local veh = getPedOccupiedVehicle(localPlayer)
                if not isElement(veh) or getVehicleController(veh) ~= localPlayer then return end
                playSelectSound()
                local key = VEH_ITEMS[hoveredVehItem].key
                if key == "vehicle_engine" then
                        triggerServerEvent("hud:engine", localPlayer)
                elseif key == "vehicle_handbrake" then
                        triggerServerEvent("hud:handbrake", localPlayer)
                elseif key == "vehicle_seatbelt" then
                        triggerServerEvent("hud:onHudItemClick", localPlayer, "seatbelt")
                elseif key == "vehicle_lock" then
                        triggerServerEvent("hud:lockvehicle", localPlayer)
                elseif key == "vehicle_lights" then
                        triggerServerEvent("hud:vehiclelights", localPlayer)
                end
        end
end)

addEvent("onClientHudVisibilityChange", false)

--------------------------------------------------------------------------------
-- FPS (old client counter + /fps)
--------------------------------------------------------------------------------
local fpsFrames, fpsTime, fpsValue = 0, 0, 0

function fpscheck()
        fpsFrames = fpsFrames + 1
        local now = getTickCount()
        if now - 1000 > fpsTime then
                fpsValue = math.floor(fpsFrames / ((now - fpsTime) / 1000))
                fpsTime = now
                fpsFrames = 0
        end
        return fpsValue
end

addCommandHandler("fps", function()
        outputChatBox(fpscheck() .. " FPS", 255, 55, 95)
end)

addEventHandler("onClientRender", root, function()
        if not statusHud.visible then return end
        dxDrawText(fpscheck() .. " FPS", 5, sy - 15, 105, sy, tocolor(255, 255, 255, 100), 1, "default-bold")
end, false, "low-10")

--------------------------------------------------------------------------------
-- STARTUP — load textures, seed rings, activate with the character
--------------------------------------------------------------------------------
local function activateHud()
        refreshConfig()
        loadTextures()
        rebuildVisibleItems()
        updateHudItemsList()
        for _, def in ipairs(RING_DEFS) do
                createRing(def.id, def.color)
        end
        setRingVisible("health", true)
        showStatusHud(true)
        setElementData(localPlayer, "hud:whereToDisplay", 200)
        setElementData(localPlayer, "hud:whereToDisplayY", 0)
end

local function deactivateHud()
        showStatusHud(false)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        -- if the character is already in (client restart mid-session) activate now
        if getElementData(localPlayer, "loggedin") == 1 or getElementData(localPlayer, "character:id") then
                activateHud()
        end
end)

-- account system sets loggedin=1 on character selection, 0 on quit
addEventHandler("onClientElementDataChange", localPlayer, function(key, _, newValue)
        if key == "loggedin" then
                if newValue == 1 then
                        activateHud()
                elseif newValue == 0 then
                        deactivateHud()
                end
        elseif key == "duty_admin" or key == "admin_level" then
                rebuildVisibleItems()
        end
end)
