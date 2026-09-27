--------------------------------------------------------------------------------
-- VORTEX HUD — client (Fix #18)
-- 1:1 port of the old client hud resource (github.com/h0-5/backupm [rp]/hud).
-- Layout, colors, sizes, animations and event names follow the decompiled
-- source exactly; data sources are adapted to this server's stack.
--
-- blocks (old client):
--   * statusHud      top-right: hud_bg panel + 7 SVG progress rings
--                    (health/sleepy/thirsty/hungry/toilet/fatigue/shower),
--                    shield ring drops below the row while armor > 0,
--                    clock + date, money pill (+ coins row when bios coins
--                    data exists) — exact old colors:
--                    health #00ff85  sleepy #7dffea  thirsty #4de4ff
--                    hungry #caff00   urine #f3ffb5  fatigue #71ffdd
--                    cleanness/shield #ffffff
--   * zone           bottom-left above radar: City | Zone + SAFE/DANGER ZONE
--   * drawHUD        F4 slide-down icon strip (hold or toggle) + in-vehicle
--                    engine/handbrake/seatbelt/lights/lock row, old events
--   * fatigue        sprint drains, rest recovers, 95% = forced tired anim
--   * fps            bottom-left "N FPS" + /fps
--   * nametags       see c_nametags.lua
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()
local SCALE = sy / 1080

-- [old client] UIKit fonts ----------------------------------------------------
local dxFontDefault, dxFontHud, dxFontHudLarge

local function UIKitReady()
        local ok, eui = pcall(function() return exports.UIKit end)
        if not ok or not eui then return end
        local function f(name)
                local ok2, v = pcall(function() return eui:getUIFont(name) end)
                return ok2 and v or nil
        end
        dxFontDefault  = f("ui-default")
        dxFontHud      = f("hud")
        dxFontHudLarge = f("hud-large")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function fontDefault()   return dxFontDefault   or "default-bold" end
local function fontHud()       return dxFontHud       or "default"      end
local function fontHudLarge()  return dxFontHudLarge  or "default-bold" end

--------------------------------------------------------------------------------
-- TEXTURES — icons/ + status_icons/ (new old-client style set) + hud_bg
--------------------------------------------------------------------------------
local tex = {}          -- [name] = texture element (dxCreateTexture)
local missing = {}      -- names that fell back (logged once)

local ICON_NAMES = {
        "seatbelt", "police", "walkingstyle", "handcuffs", "admin_badge",
        "head_turning", "mask", "tagmode", "facbadge", "togpm", "reportpanel",
        "engine", "handbrake", "car_lights", "car_lock", "blindfold",
        "gasmask", "heart", "gloves", "phone", "diamond", "medical_mask",
        "support_badge", "support_badge_2", "developer_badge",
        "developer_badge2", "booster", "pro", "AFK", "admin2", "verified",
        "rope", "classic", "youtuber", "vehicle_engine", "vehicle_handbrake",
        "vehicle_lights", "vehicle_lock", "vehicle_seatbelt",
}
local STATUS_ICON_NAMES = {
        "fatigue", "health", "hungry", "sleep", "thirsty", "toilet",
        "shower", "shield",
}

local function loadTextures()
        tex = {}
        tex.bg = fileExists("hud_bg.png") and dxCreateTexture("hud_bg.png", "argb", true, "clamp") or nil
        for _, name in ipairs(ICON_NAMES) do
                local path = "icons/" .. name .. ".png"
                if fileExists(path) then
                        tex[name] = dxCreateTexture(path, "dxt5", true, "clamp")
                else
                        missing[name] = true
                end
        end
        for _, name in ipairs(STATUS_ICON_NAMES) do
                local path = "status_icons/" .. name .. ".png"
                if fileExists(path) then
                        tex[name] = dxCreateTexture(path, "dxt3", true, "clamp")
                else
                        missing[name] = true
                end
        end
end

function getBGTexture() return tex.bg end

--------------------------------------------------------------------------------
-- CONFIG — old client read these from exports.settings (settings resource
-- restored alongside this fix). Guarded so hud still boots if settings is off.
--------------------------------------------------------------------------------
local CONFIG = {
        hold      = false, -- F4 held = open, released = close
        right     = false, -- strip hugs the right edge
        hideClock = false,
        safeZones = {
                ["East Beach"] = true, ["Commerce"] = true,
        },
}

local function refreshConfig()
        if getResourceFromName("settings") and getResourceState(getResourceFromName("settings")) == "running" then
                local ok, v
                ok, v = pcall(function() return exports.settings:getSetting("Hud:hideClock") end)
                if ok and v ~= nil then CONFIG.hideClock = v end
                ok, v = pcall(function() return exports.settings:getSetting("Hud:right") end)
                if ok and v ~= nil then CONFIG.right = v end
                ok, v = pcall(function() return exports.settings:getSetting("Hud:hold") end)
                if ok and v ~= nil then CONFIG.hold = v end
        end
end

--------------------------------------------------------------------------------
-- HELPERS (old client exact)
--------------------------------------------------------------------------------
function isMouseInPosition(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        if not cx then return false end
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

local function anim(startTick, duration, fromValue, toValue)
        local t = 0
        if duration and duration > 0 then
                t = (getTickCount() - startTick) / duration
        end
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        return fromValue + (toValue - fromValue) * t
end

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY, postGUI, colorCoded)
        local black = tocolor(0, 0, 0, 255)
        dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
        dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
        dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
        dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
end

--------------------------------------------------------------------------------
-- HUD SETTINGS + ITEMS API (old client names, used by other resources)
--------------------------------------------------------------------------------
local hudSettings = { showhud = true, tagmode = true, seatbelt = false }
local hudItems = {}            -- element data mirror {id, state, icon, tip1, tip2, category}
local visibleItems = {}        -- resolved strip list

function isHudShowing() return hudSettings.showhud end
function getHudSetting(key) return hudSettings[key] or false end

function setHudSetting(key, value)
        for _, item in ipairs(hudItems) do
                if item[1] == key then
                        item[2] = value and "on" or "off"
                        break
                end
        end
        hudSettings[key] = value and true or false
end

local function itemIcon(name)
        if not name or name == "" then return nil end
        return tex[name]
end

local function rebuildVisibleItems()
        visibleItems = {}
        -- old client always prepends showhud (icon: tagmode)
        table.insert(visibleItems, {
                id = "showhud", state = hudSettings.showhud and "on" or "off",
                icon = tex.tagmode, tip1 = "Show/Hide Hud", category = "local",
        })
        for _, item in ipairs(hudItems) do
                table.insert(visibleItems, {
                        id = item[1], state = item[2] or "on",
                        icon = itemIcon(item[3]),
                        tip1 = item[4], tip2 = item[5], category = item[6],
                })
        end
end

function updateHudItemsList(items)
        items = items or getElementData(localPlayer, "hud:items") or {}
        hudItems = items
        hudSettings = { showhud = hudSettings.showhud, tagmode = hudSettings.tagmode, seatbelt = hudSettings.seatbelt }
        for _, item in ipairs(hudItems) do
                if type(item[1]) == "string" then
                        hudSettings[item[1]] = item[2] == "on"
                end
        end
        rebuildVisibleItems()
end

function addHudItem(id, state, tip1, tip2, iconName, category)
        local list = getElementData(localPlayer, "hud:items") or {}
        for _, item in ipairs(list) do
                if item[1] == id then return end
        end
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

function isHudItemOfCategoryExists(cat)
        for _, item in ipairs(getElementData(localPlayer, "hud:items") or {}) do
                if item[6] == cat then return true end
        end
        return false
end

function getHudItemsByCategory(cat)
        local out = {}
        for _, item in ipairs(getElementData(localPlayer, "hud:items") or {}) do
                if item[6] == cat then table.insert(out, item) end
        end
        return out
end

function isPlayerHudItemExists(player, id)
        for _, item in ipairs(getElementData(player, "hud:items") or {}) do
                if item[1] == id then return true end
        end
        return false
end

function isPlayerHudItemOfCategoryExists(player, cat)
        for _, item in ipairs(getElementData(player, "hud:items") or {}) do
                if item[6] == cat then return true end
        end
        return false
end

function getPlayerHudItemsByCategory(player, cat)
        local out = {}
        for _, item in ipairs(getElementData(player, "hud:items") or {}) do
                if item[6] == cat then table.insert(out, item) end
        end
        return out
end

function getPlayerHudSetting(player, id)
        for _, item in ipairs(getElementData(player, "hud:items") or {}) do
                if item[1] == id then return item[2] == "on" end
        end
        return false
end

function getHudItemData(id)
        for _, item in ipairs(getElementData(localPlayer, "hud:items") or {}) do
                if item[1] == id then return item[5] end
        end
        return false
end

function getPlayerHudItemData(player, id)
        for _, item in ipairs(getElementData(player, "hud:items") or {}) do
                if item[1] == id then return item[5] end
        end
        return false
end

addEventHandler("onClientElementDataChange", localPlayer, function(key, _, newValue)
        if key == "hud:items" then
                updateHudItemsList(newValue)
        end
end)

addEvent("onClientHudVisibilityChange", false)

--------------------------------------------------------------------------------
-- STATUS RINGS — SVG progress circles, exact old-client geometry:
-- circle r=50, stroke-width 9, dasharray 315, dashoffset = 315 - value/100*315
--------------------------------------------------------------------------------
local RING_SIZE, RING_GAP = 26, 8
local RING_DEFS = {
        -- id        svg color    icon tint (exact old)   icon file
        { id = "health",    color = "#00ff85", tint = {0, 255, 132},   icon = "health"  },
        { id = "sleepy",    color = "#7dffea", tint = {255, 255, 255}, icon = "sleep"   },
        { id = "thirsty",   color = "#4de4ff", tint = {77, 228, 255},  icon = "thirsty" },
        { id = "hungry",    color = "#caff00", tint = {202, 255, 0},   icon = "hungry"  },
        { id = "urine",     color = "#f3ffb5", tint = {255, 255, 255}, icon = "toilet"  },
        { id = "fatigue",   color = "#71ffdd", tint = {113, 255, 221}, icon = "fatigue" },
        { id = "cleanness", color = "#ffffff", tint = {255, 255, 255}, icon = "shower"  },
        { id = "shield",    color = "#ffffff", tint = {255, 255, 255}, icon = "shield"  },
}

local rings = {}       -- [id] = {value=0..100, template=xml, svg=element}
local statusValues = {} -- [id] = number (what the old client kept in statusHud vars)

local RING_XML = [[<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
<circle cx="50" cy="50" r="50" fill="none" stroke="%s" stroke-width="9"
 stroke-linecap="round" stroke-dasharray="315" stroke-dashoffset="315"
 transform="rotate(-90 50 50)"/>
</svg>]]

local svgSupported = type(svgCreate) == "function"

local function createRing(id, colorHex)
        local ring = { value = 0 }
        if svgSupported then
                ring.template = string.format(RING_XML, colorHex)
                ring.svg = svgCreate(100, 100, ring.template)
        end
        rings[id] = ring
        return ring
end

local function clampPercent(v)
        v = tonumber(v) or 0
        if v < 0 then v = 0 elseif v > 100 then v = 100 end
        return v
end

function setProgress(id, value)
        local ring = rings[id]
        if not ring then return end
        value = clampPercent(value)
        ring.value = value
        statusValues[id] = value
        if ring.svg and ring.template then
                -- old client: stroke-dashoffset = 315 - value / 100 * 315
                local offset = string.format("%.1f", 315 - value / 100 * 315)
                local updated = ring.template:gsub('stroke%-dashoffset="[%-%d%.]+"',
                        'stroke-dashoffset="' .. offset .. '"')
                pcall(svgSetDocumentXML, ring.svg, updated)
        end
end

local function getRingValue(id)
        local ring = rings[id]
        return ring and ring.value or 0
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
-- STATUS HUD GEOMETRY (old client exact)
--   ring_x(i) = sx - (S+G)*7 - G*2 + (S+G)*i     (i = 0..6, health first)
--   ring_y    = panelY + 8.5*scale
--   shield    = same column as cleanness, 150*scale below the ring row
--------------------------------------------------------------------------------
local PANEL_PAD_L = 16
local ROW_W = 7 * RING_SIZE + 6 * RING_GAP          -- 230 @ 1080p
local PANEL_W = ROW_W + PANEL_PAD_L + 2 * RING_GAP  -- 270
local PANEL_H = 42
local PANEL_X = sx - PANEL_W
local STRIP_H = 37

local statusHud = { visible = false, anims = { count = 0, time = 250, from = -80, to = 25, current = -80 } }
local statusHudDraw -- forward declaration
local moneyBlockBottom = false   -- bottom Y of the money block (used by vehicle row)
local zoneText, zoneLabel = "", ""
local zoneLabelColor = tocolor(255, 255, 255, 255)

function showStatusHud(state)
        if state == statusHud.visible then return end
        if state then
                statusHud.anims.count = getTickCount()
                statusHud.anims.from = statusHud.anims.current
                statusHud.anims.to = 25
                addEventHandler("onClientRender", root, statusHudDraw, false, "high-5")
                -- seed from life-system if the real one is running (old client)
                local life = getResourceFromName("life-system")
                if life and getResourceState(life) == "running" then
                        local ok, v
                        for _, pair in ipairs({ { "thirsty", "thirsty" }, { "hungry", "hungry" },
                                                { "urine", "urine" }, { "sleepy", "sleepy" }, { "cleanness", "cleanness" } }) do
                                ok, v = pcall(function() return exports["life-system"]:getCharacterStatus(pair[2]) end)
                                if ok and type(v) == "number" then setProgress(pair[1], v) end
                        end
                end
                setProgress("health", healthPercent())
                setProgress("shield", tonumber(getElementData(localPlayer, "temp:armor")) or getPedArmor(localPlayer))
        else
                removeEventHandler("onClientRender", root, statusHudDraw)
        end
        statusHud.visible = state
end

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

local function drawMoneyBlock(x, y, w, postGUI)
        local money = getPlayerMoney(localPlayer) or 0
        local coins = tonumber(getElementData(localPlayer, "bios:coins"))
        local rows = coins and 2 or 1
        local h = 30 * rows + 6
        if tex.bg then
                dxDrawImage(x, y, w, h, tex.bg, 180, 0, 0, tocolor(0, 8, 20, 180), postGUI)
        else
                dxDrawRoundedRectangle(x, y, w, h, tocolor(0, 8, 20, 180), 8, postGUI)
        end
        -- row 1: money (green dot, old client colors)
        local r1y = y + 4
        dxDrawCircle(x + 15, r1y + 11, 7.5, 0, 360, tocolor(0, 255, 133, 255), tocolor(0, 255, 133, 255), 12, postGUI)
        dxDrawText("$", x + 8, r1y + 3, x + 22, r1y + 19, tocolor(8, 40, 26, 255), 0.7, fontDefault(), "center", "center", false, false, postGUI)
        dxDrawText(string.format("%s", money and tostring(money) or "0"), x + 28, r1y, x + w - 8, r1y + 22,
                tocolor(255, 255, 255, 255), 1, fontDefault(), "right", "center", false, false, postGUI)
        -- row 2: coins (red dot) — only while the coins system exists
        if coins then
                local r2y = y + 32
                dxDrawCircle(x + 15, r2y + 11, 7.5, 0, 360, tocolor(255, 45, 45, 255), tocolor(255, 45, 45, 255), 12, postGUI)
                dxDrawText(tostring(coins), x + 28, r2y, x + w - 8, r2y + 22,
                        tocolor(255, 255, 255, 200), 0.8, fontHud(), "right", "center", false, false, postGUI)
        end
        return h
end

local function statusHudDrawImpl()
        if not statusHud.visible or not isHudShowing() then return end
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "character:id") then return end

        local postGUI = true
        local animY = anim(statusHud.anims.count, statusHud.anims.time, statusHud.anims.from, statusHud.anims.to)
        local panelY = animY + 25 - 20 * SCALE
        if panelY < -PANEL_H then return end

        -- main panel + old 1px highlight lines
        if tex.bg then
                dxDrawImage(PANEL_X, panelY, PANEL_W, PANEL_H, tex.bg, 0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
                dxDrawImage(PANEL_X, panelY, PANEL_W, 1, tex.bg, 0, 0, 0, tocolor(255, 255, 255, 150), postGUI)
                dxDrawImage(sx - PANEL_W / 1.5, panelY + PANEL_H, PANEL_W / 1.5, 1, tex.bg, 0, 0, 0,
                        tocolor(255, 255, 255, 150), postGUI)
        else
                dxDrawRoundedRectangle(PANEL_X, panelY, PANEL_W, PANEL_H, tocolor(0, 8, 20, 200), 8, postGUI)
        end

        -- pulse (old client): math.abs(sin(tick/300)) * 230 drives critical blink
        local pulse = math.abs(math.sin(getTickCount() / 300)) * 230

        -- ring row (7 rings, health leftmost — exact old order)
        local ringY = panelY + 8.5 * SCALE
        local S, G = RING_SIZE, RING_GAP
        for i = 0, 6 do
                local def = RING_DEFS[i + 1]
                local ring = rings[def.id]
                local x = sx - (S + G) * 7 - G * 2 + (S + G) * i
                if ring and ring.svg then
                        dxDrawImage(x, ringY, S, S, ring.svg, 0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
                elseif ring then
                        -- fallback arc (only when svgCreate unavailable)
                        local sweep = 360 * (ring.value / 100)
                        if sweep > 0.5 then
                                dxDrawCircle(x + S / 2, ringY + S / 2, S / 2 - 2, 270, 270 + sweep,
                                        tocolor(def.tint[1], def.tint[2], def.tint[3], 255), def.tint, 4, postGUI)
                        end
                end
                local icon = tex[def.icon]
                if icon then
                        -- old blink rules: value-driven alpha (220 steady / pulse critical)
                        local a = 220
                        if def.id == "health" then
                                a = getRingValue("health") > 10 and 220 or pulse
                        elseif def.id == "sleep" or def.id == "sleepy" then
                                a = getRingValue("sleepy") < 90 and 220 or pulse
                        elseif def.id == "thirsty" then
                                a = getRingValue("thirsty") > 5 and 220 or pulse
                        elseif def.id == "hungry" then
                                a = getRingValue("hungry") > 5 and 220 or pulse
                        elseif def.id == "toilet" then
                                a = getRingValue("urine") < 90 and 220 or pulse
                        elseif def.id == "fatigue" then
                                a = getRingValue("fatigue") < 90 and 220 or pulse
                        elseif def.id == "shower" then
                                a = getRingValue("cleanness") > 5 and 220 or pulse
                        end
                        local pad = S * 0.22
                        dxDrawImage(x + pad, ringY + pad, S - pad * 2, S - pad * 2, icon, 0, 0, 0,
                                tocolor(def.tint[1], def.tint[2], def.tint[3], a), postGUI)
                end
        end

        -- shield ring: old client draws it under the last column while > 0
        if getRingValue("shield") > 0 then
                local def = RING_DEFS[8]
                local ring = rings["shield"]
                local x = sx - (S + G) * 7 - G * 2 + (S + G) * 6
                local y = ringY + 150 * SCALE
                if ring and ring.svg then
                        dxDrawImage(x, y, S, S, ring.svg, 0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
                end
                if tex.shield then
                        local a = getRingValue("shield") > 5 and 220 or pulse
                        local pad = S * 0.22
                        dxDrawImage(x + pad, y + pad, S - pad * 2, S - pad * 2, tex.shield, 0, 0, 0,
                                tocolor(255, 255, 255, a), postGUI)
                end
        end

        -- clock + date (old formats, right aligned under the panel)
        if not CONFIG.hideClock then
                local textY = panelY + PANEL_H + 6
                outlineText(getCurrentTime(), sx - 140, textY, 128, 24,
                        tocolor(255, 255, 255, 255), 0.38, fontHudLarge(), "right", "top", postGUI)
                outlineText(getCurrentDate(), sx - 140, textY + 16, 128, 16,
                        tocolor(255, 255, 255, 200), 0.3, fontHudLarge(), "right", "top", postGUI)
                -- money block
                local mh = drawMoneyBlock(sx - 160, textY + 38, 160, postGUI)
                moneyBlockBottom = textY + 38 + mh
        else
                local mh = drawMoneyBlock(sx - 160, panelY + PANEL_H + 6, 160, postGUI)
                moneyBlockBottom = panelY + PANEL_H + 6 + mh
        end

        -- zone label, bottom-left above the radar (old client)
        outlineText(zoneText:gsub("#%x%x%x%x%x%x", ""), 18, sy - 206, 340, 16,
                tocolor(255, 255, 255, 255), 0.85, fontHud(), "left", "top", postGUI)
        outlineText(zoneLabel, 18, sy - 188, 340, 16, zoneLabelColor, 0.85, fontHud(), "left", "top", postGUI)
end
statusHudDraw = statusHudDrawImpl

--------------------------------------------------------------------------------
-- ONE-SECOND SYNC (old client): health, armor, zone safety, fatigue
--------------------------------------------------------------------------------
local wasDanger = false
local fatigue = 0
local fatigueTired = false
local lastHealth, lastArmor = -1, -1

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
                        if not wasDanger then
                                wasDanger = true
                                local notified = false
                                if getResourceFromName("notifications")
                                        and getResourceState(getResourceFromName("notifications")) == "running" then
                                        pcall(function()
                                                exports.notifications:output({
                                                        en = "#ff3030You are now in an unsafe area, you must be careful",
                                                        ar = "#ff3030انت الان في منطقة غير أمنة، يجب عليك الانتباه",
                                                }, 6000, "danger")
                                        end)
                                        notified = true
                                end
                                if not notified then
                                        outputChatBox("#ff3030You are now in an unsafe area, you must be careful | انت الان في منطقة غير أمنة، يجب عليك الانتباه", 255, 48, 48, true)
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

--------------------------------------------------------------------------------
-- SERVER-DRIVEN CHARACTER STATUS (old life-system flow):
-- character_status:sendToClient -> onClientCharacterStatusChange -> rings
--------------------------------------------------------------------------------
addEvent("character_status:sendToClient", true)
addEventHandler("character_status:sendToClient", localPlayer, function(status)
        if type(status) ~= "table" then return end
        setProgress("thirsty", status.thirsty or 0)
        setProgress("hungry", status.hungry or 0)
        setProgress("urine", status.urine or 0)
        setProgress("sleepy", status.sleepy or 0)
        setProgress("cleanness", status.cleanness or 0)
end)

addEvent("onClientCharacterStatusChange", true)
addEventHandler("onClientCharacterStatusChange", localPlayer, function(status)
        if type(status) ~= "table" then return end
        if status.thirsty then setProgress("thirsty", status.thirsty) end
        if status.hungry then setProgress("hungry", status.hungry) end
        if status.urine then setProgress("urine", status.urine) end
        if status.sleepy then setProgress("sleepy", status.sleepy) end
        if status.cleanness then setProgress("cleanness", status.cleanness) end
end)

addEvent("character_status:update", true)
addEventHandler("character_status:update", localPlayer, function(key, value)
        if type(key) == "string" and type(value) == "number" then
                setProgress(key, value)
        end
end)

addEvent("onClientCharacterRespawn", true)
addEventHandler("onClientCharacterRespawn", localPlayer, function()
        -- old client: refill to 20 when the status hit 0 (server also enforces)
        if getRingValue("thirsty") <= 0 then setProgress("thirsty", 20) end
        if getRingValue("hungry") <= 0 then setProgress("hungry", 20) end
end)

--------------------------------------------------------------------------------
-- F4 STRIP — slide-down icon strip (old client exact):
-- 32px icons, pitch 37, panel w = 32*count + 15, h = 37, rounded 8,
-- color (15,15,15,250), icons at y+2.5, tooltip below, 1s click debounce,
-- hover select sound :assets/sounds/select.wav
--------------------------------------------------------------------------------
local STRIP_ICON, STRIP_PITCH = 32, 37
local stripAnim = { count = 0, time = 250, from = -STRIP_H - 2, to = -STRIP_H - 2, current = -STRIP_H - 2 }
local hoveredItem = 0
local hoveredVehItem = 0
local lastItemClick = 0
local hudState = false

-- in-vehicle quick actions (old client vehicle_* icon set)
local VEH_ITEMS = {
        { key = "engine",    icon = "vehicle_engine",    label = "Engine" },
        { key = "handbrake", icon = "vehicle_handbrake", label = "Handbrake" },
        { key = "seatbelt",  icon = "vehicle_seatbelt",  label = "Seatbelt" },
        { key = "lights",    icon = "vehicle_lights",    label = "Lights" },
        { key = "lock",      icon = "vehicle_lock",      label = "Lock" },
}

local function playSelectSound()
        if fileExists(":assets/sounds/select.wav") then
                playSound(":assets/sounds/select.wav", false)
        end
end

local function drawHUD()
        hoveredItem = 0
        hoveredVehItem = 0

        stripAnim.current = anim(stripAnim.count, stripAnim.time, stripAnim.from, stripAnim.to)

        if stripAnim.current > -STRIP_H / 2 - 2 then
                local count = #visibleItems
                if count > 0 then
                        local w = (STRIP_PITCH - 5) * count + 15
                        local px = CONFIG.right and (sx - w - 5) or (sx - w) / 2
                        local py = stripAnim.current
                        dxDrawRoundedRectangle(px, py, w, STRIP_H, tocolor(15, 15, 15, 250), 8, true)

                        local iconX = px + 7.5
                        for i, item in ipairs(visibleItems) do
                                if item.icon then
                                        local active = item.state == "on"
                                        dxDrawImage(iconX, py + 2.5, STRIP_ICON, STRIP_ICON, item.icon, 0, 0, 0,
                                                tocolor(255, 255, 255, active and 255 or 130), true)
                                end
                                if isMouseInPosition(iconX - 2.5, py, STRIP_PITCH, STRIP_H) then
                                        if hoveredItem ~= i then
                                                playSelectSound()
                                        end
                                        hoveredItem = i
                                end
                                iconX = iconX + (STRIP_PITCH - 5)
                        end

                        -- tooltip (old client: 4-pass outline below the strip)
                        local tip = visibleItems[hoveredItem]
                        if tip and tip.tip1 and tip.tip1 ~= "" then
                                local tipY = py + STRIP_H + 5
                                outlineText(tip.tip1, 10, tipY, sx - 20, 40,
                                        tocolor(255, 255, 255, 230), 1, "default-bold",
                                        CONFIG.right and "right" or "center", "top", true)
                        end
                end
        end

        -- in-vehicle row (driver only, old client states)
        -- pinned below the money block on the right (never overlaps the rings)
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleController(veh) == localPlayer then
                local size, gap = 24, 5
                local rowW = #VEH_ITEMS * size + (#VEH_ITEMS - 1) * gap
                local vx = sx - rowW - 14
                local vy = (statusHud.visible and moneyBlockBottom) and (moneyBlockBottom + 8) or 14
                for i, item in ipairs(VEH_ITEMS) do
                        local state = "off"
                        if item.key == "engine" then
                                state = getVehicleEngineState(veh) and "on" or "off"
                        elseif item.key == "handbrake" then
                                local hb = getElementData(veh, "handbrake")
                                state = (hb == true or hb == 1) and "on" or "off"
                        elseif item.key == "seatbelt" then
                                state = (getElementData(localPlayer, "seatbelt") == true
                                        or getHudSetting("seatbelt")) and "on" or "off"
                        elseif item.key == "lights" then
                                state = getVehicleOverrideLights(veh) ~= 1 and "on" or "off"
                        elseif item.key == "lock" then
                                state = isVehicleLocked(veh) and "on" or "off"
                        end
                        if tex[item.icon] then
                                dxDrawImage(vx, vy, size, size, tex[item.icon], 0, 0, 0,
                                        tocolor(255, 255, 255, state == "on" and 255 or 110), true)
                        end
                        if isMouseInPosition(vx - 2, vy - 2, size + 4, size + 4) then
                                hoveredVehItem = i
                        end
                        vx = vx + size + gap
                end
                local hovered = VEH_ITEMS[hoveredVehItem]
                if hovered then
                        outlineText(hovered.label, 10, vy + size + 6, sx - 20, 30,
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
                CONFIG.hideClock = value and true or false
        elseif key == "Hud:right" then
                CONFIG.right = value and true or false
        elseif key == "Hud:hold" then
                CONFIG.hold = value and true or false
        end
end)

--------------------------------------------------------------------------------
-- CLICK DISPATCH (old client exact: 1s debounce, both events fired)
--------------------------------------------------------------------------------
addEventHandler("onClientClick", root, function(button, state)
        if not isCursorShowing() or state ~= "down" then return end

        if hoveredItem ~= 0 then
                local now = getTickCount()
                if now - lastItemClick < 1000 then return end
                lastItemClick = now
                local item = visibleItems[hoveredItem]
                if not item then return end

                if item.id == "showhud" then
                        setHudSetting("showhud", not hudSettings.showhud)
                        rebuildVisibleItems()
                        triggerEvent("onClientHudVisibilityChange", localPlayer, hudSettings.showhud)
                elseif item.category ~= "disable-click" then
                        -- old client: server event + local event, both
                        triggerServerEvent("hud:onHudItemClick", localPlayer, item.id)
                        triggerEvent("hud:onClientHudItemClick", localPlayer, item.id, getHudSetting(item.id))
                end
        end

        if hoveredVehItem ~= 0 then
                local veh = getPedOccupiedVehicle(localPlayer)
                if not isElement(veh) or getVehicleController(veh) ~= localPlayer then return end
                local key = VEH_ITEMS[hoveredVehItem].key
                if key == "engine" then
                        triggerServerEvent("hud:engine", localPlayer)
                elseif key == "handbrake" then
                        triggerServerEvent("hud:handbrake", localPlayer)
                elseif key == "seatbelt" then
                        triggerServerEvent("hud:onHudItemClick", localPlayer, "seatbelt")
                        triggerEvent("hud:onClientHudItemClick", localPlayer, "seatbelt", getHudSetting("seatbelt"))
                elseif key == "lock" then
                        triggerServerEvent("hud:lockvehicle", localPlayer)
                elseif key == "lights" then
                        triggerServerEvent("hud:vehiclelights", localPlayer)
                end
        end
end)

-- local-side click effects (old client equivalents)
addEvent("hud:onClientHudItemClick", false)
addEventHandler("hud:onClientHudItemClick", localPlayer, function(id)
        if id == "reportpanel" then
                -- Report Center is owned by report-system (/report)
                if getResourceFromName("report-system")
                        and getResourceState(getResourceFromName("report-system")) == "running" then
                        executeCommandHandler("report", localPlayer)
                end
        elseif id == "tagmode" then
                setHudSetting("tagmode", not getHudSetting("tagmode"))
                rebuildVisibleItems()
        end
end)

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
-- AFK AUTO-DETECT (old client: temp:AFK + any key clears it)
--------------------------------------------------------------------------------
local function checkAFK()
        setElementData(localPlayer, "temp:AFK", nil)
        removeEventHandler("onClientKey", root, checkAFK)
end
addEventHandler("onClientElementDataChange", localPlayer, function(key, _, newValue)
        if key == "temp:AFK" and newValue == true then
                addEventHandler("onClientKey", root, checkAFK)
        end
end)
if getElementData(localPlayer, "temp:AFK") then
        addEventHandler("onClientKey", root, checkAFK)
end

--------------------------------------------------------------------------------
-- ACTIVATION — old client events + this server's loggedin flag
--------------------------------------------------------------------------------
local function activateHud()
        refreshConfig()
        loadTextures()
        updateHudItemsList()
        for _, def in ipairs(RING_DEFS) do
                createRing(def.id, def.color)
        end
        setProgress("health", healthPercent())
        setProgress("shield", tonumber(getElementData(localPlayer, "temp:armor")) or getPedArmor(localPlayer))
        showStatusHud(true)
        setElementData(localPlayer, "hud:whereToDisplay", 200)
        setElementData(localPlayer, "hud:whereToDisplayY", 0)
        -- ask the server for the current character status (old request_sync)
        triggerServerEvent("character_status:request_sync", localPlayer)
end

local function deactivateHud()
        showStatusHud(false)
        for i = 1, #RING_DEFS do
                local def = RING_DEFS[i]
                if rings[def.id] then
                        if isElement(rings[def.id].svg) then destroyElement(rings[def.id].svg) end
                        rings[def.id] = nil
                end
        end
        for _, t in pairs(tex) do
                if isElement(t) then destroyElement(t) end
        end
        tex = {}
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        -- mid-session client restart: activate right away
        if getElementData(localPlayer, "loggedin") == 1 or getElementData(localPlayer, "character:id") then
                activateHud()
        end
end)

-- old client activation events (fired by the account system)
addEvent("onClientCharacterSpawn", true)
addEventHandler("onClientCharacterSpawn", localPlayer, function()
        if not statusHud.visible then activateHud() end
end)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
        deactivateHud()
end)

-- this server's account system toggles loggedin on character select/quit
addEventHandler("onClientElementDataChange", localPlayer, function(key, _, newValue)
        if key == "loggedin" then
                if newValue == 1 then
                        activateHud()
                elseif newValue == 0 then
                        deactivateHud()
                end
        end
end)
