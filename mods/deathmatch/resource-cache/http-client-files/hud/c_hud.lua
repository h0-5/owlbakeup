--------------------------------------------------------------------------------
-- VORTEX HUD — client (Fix #19)
-- 1:1 port of the old client hud resource (github.com/h0-5/backupm [rp]/hud).
-- Layout, colors, sizes, animations and event names follow the decompiled
-- source exactly; data sources are adapted to this server's stack.
--
-- Fix #19 refinements (user spec):
--   * rings are pure dxDrawCircle arcs (NO SVG): the icon is now mathematically
--     centered inside its circle — exact center, never outside
--   * the black panel behind the rings is replaced by a light purple FRAME
--     (thin purple border + barely-visible fill) so it never hides the states
--   * the Vortex server logo sits inside the frame, left of all the states
--   * money block: black pill removed completely, green $ dot hugs the amount,
--     the slot is FLEXIBLE (smoothly expands as money grows, shrinks when it
--     drops) and amounts use thousand separators like the old client
--
-- Fix #20 refinements (user feedback):
--   * breathing room restored between the states frame, the clock and the
--     money row (they were squeezed together)
--   * status icons keep their TRUE aspect ratio and land EXACTLY on the ring
--     center (fractional centering + uncompressed ARGB textures — no more
--     distortion and no optical off-center)
--   * rings / dots / rounded frames are drawn with analytic HLSL shaders
--     (fx/ring.fx, fx/rounded.fx): perfectly smooth anti-aliased circle
--     lines, the pixelated dxDrawCircle edges are gone (fallback kept)
--
-- Fix #21 refinements (user feedback):
--   * EVERYTHING got bigger: status rings 26 -> 36 px (stroke 4), bigger
--     frame + logo, clock, date, money and the zone label are now easily
--     readable (they were far too small)
--   * zone rule: ALL of Los Santos = SAFE ZONE, every other city / area =
--     DANGER ZONE
--   * the urine ring shows RELIEF: full right after /piss finishes, then it
--     depletes gradually while the bladder refills server-side (empty = you
--     need to pee again)
--
-- blocks (old client):
--   * statusHud      top-right: 7 progress rings
--                    (health/sleepy/thirsty/hungry/toilet/fatigue/shower),
--                    shield ring drops below the row while armor > 0,
--                    clock + date, flexible money row (+ coins when bios
--                    coins data exists) — exact old colors:
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
        tex.logo = fileExists("images/vortex_logo.png")
                and dxCreateTexture("images/vortex_logo.png", "dxt5", true, "clamp") or nil
        for _, name in ipairs(ICON_NAMES) do
                local path = "icons/" .. name .. ".png"
                if fileExists(path) then
                        -- Fix #20: uncompressed ARGB — DXT compression shifted the
                        -- perceived glyph mass inside tiny icons
                        tex[name] = dxCreateTexture(path, "argb", true, "clamp")
                else
                        missing[name] = true
                end
        end
        for _, name in ipairs(STATUS_ICON_NAMES) do
                local path = "status_icons/" .. name .. ".png"
                if fileExists(path) then
                        tex[name] = dxCreateTexture(path, "argb", true, "clamp")
                else
                        missing[name] = true
                end
        end
end

function getBGTexture() return tex.bg end

--------------------------------------------------------------------------------
-- Fix #20 — smooth GPU drawing + exact icon geometry
--   * ring / disc / rounded-rect shapes go through tiny HLSL shaders
--     (fx/ring.fx, fx/rounded.fx) with per-pixel anti-aliasing: no more
--     pixelated dxDrawCircle edges
--   * status icons keep their true aspect ratio and are placed with
--     fractional coordinates so the glyph lands EXACTLY on the ring center
--   * every shader path falls back to the old dxDraw calls automatically
--------------------------------------------------------------------------------
local ICON_GLYPH = {   -- visible glyph size (px) inside each 128px canvas
        health = { 78, 94 },  sleep = { 86, 94 },   thirsty = { 74, 104 },
        hungry = { 88, 96 },  toilet = { 70, 92 },  fatigue = { 74, 114 },
        shower = { 66, 84 },  shield = { 90, 110 },
}

local function iconDrawSize(name, target)
        local glyph = ICON_GLYPH[name]
        if glyph then
                local k = target / math.max(glyph[1], glyph[2])
                return glyph[1] * k, glyph[2] * k
        end
        return target, target
end

local ringShader, discShader, roundedShader
local shadersOK = false

local function initShaders()
        if ringShader or not fileExists("fx/ring.fx") or not fileExists("fx/rounded.fx") then return end
        ringShader    = dxCreateShader("fx/ring.fx", 0, 0, false, "all")
        discShader    = dxCreateShader("fx/ring.fx", 0, 0, false, "all")
        roundedShader = dxCreateShader("fx/rounded.fx", 0, 0, false, "all")
        if ringShader and discShader and roundedShader then
                -- disc (filled dot): slightly softer edge than the ring band
                dxSetShaderValue(discShader, "gRingAA", 0.05)
                shadersOK = true
        else
                ringShader, discShader, roundedShader = nil, nil, nil
        end
end

local function unpackColor(color)
        local b = color % 256
        local g = math.floor(color / 256) % 256
        local r = math.floor(color / 65536) % 256
        local a = math.floor(color / 16777216) % 256
        return r, g, b, a
end

-- smooth progress ring: starts 12 o'clock, sweeps clockwise (old client)
local function drawSmoothRing(cx, cy, size, radius, thickness, r, g, b, a, progress, postGUI)
        progress = math.max(0, math.min(1, progress or 0))
        if ringShader then
                dxSetShaderValue(ringShader, "gProgress", progress)
                dxSetShaderValue(ringShader, "gColor", r / 255, g / 255, b / 255, a / 255)
                dxSetShaderValue(ringShader, "gBand",
                        (radius - thickness / 2) / size, (radius + thickness / 2) / size)
                dxDrawImage(cx - size / 2, cy - size / 2, size, size, ringShader,
                        0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
        else
                local sweep = math.min(360 * progress, 359.5)
                dxDrawCircle(cx, cy, radius, 270, 270 + sweep, tocolor(r, g, b, a), tocolor(r, g, b, a),
                        math.max(10, math.ceil(sweep / 12)), thickness, postGUI)
        end
end

-- smooth filled dot (money / coins)
local function drawSmoothDisc(cx, cy, rad, r, g, b, a, postGUI)
        if discShader then
                local img = rad * 2 + 4
                dxSetShaderValue(discShader, "gProgress", 1)
                dxSetShaderValue(discShader, "gColor", r / 255, g / 255, b / 255, a / 255)
                dxSetShaderValue(discShader, "gBand", 0, rad / img)
                dxDrawImage(cx - img / 2, cy - img / 2, img, img, discShader,
                        0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
        else
                dxDrawCircle(cx, cy, rad, 0, 360, tocolor(r, g, b, a), tocolor(r, g, b, a), 12, postGUI)
        end
end

-- [Fix #32] shared with c_speedo.lua (same resource, separate file)
function drawSmoothRingG(cx, cy, size, radius, thickness, r, g, b, a, progress, postGUI)
        return drawSmoothRing(cx, cy, size, radius, thickness, r, g, b, a, progress, postGUI)
end
function drawSmoothDiscG(cx, cy, rad, r, g, b, a, postGUI)
        return drawSmoothDisc(cx, cy, rad, r, g, b, a, postGUI)
end

--------------------------------------------------------------------------------
-- CONFIG — old client read these from exports.settings (settings resource
-- restored alongside this fix). Guarded so hud still boots if settings is off.
--------------------------------------------------------------------------------
local CONFIG = {
        hold      = false, -- F4 held = open, released = close
        right     = false, -- strip hugs the right edge
        hideClock = false,
        -- Fix #21 (user rule): ALL of Los Santos is a safe zone, every other
        -- city / countryside area is a danger zone
        safeZones = {
                ["Los Santos"] = true,
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
        if w < 2 or h < 2 or w < radius * 2 or h < radius * 2 then
                dxDrawRectangle(x, y, w, h, color, postGUI)
                return
        end
        -- Fix #20: analytic SDF corners — smooth at any radius
        if roundedShader then
                local r, g, b, a = unpackColor(color)
                dxSetShaderValue(roundedShader, "gSize", w, h)
                dxSetShaderValue(roundedShader, "gRadius", math.min(radius, w / 2, h / 2))
                dxSetShaderValue(roundedShader, "gColor", r / 255, g / 255, b / 255, a / 255)
                dxDrawImage(x, y, w, h, roundedShader, 0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
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
        -- [Fix #32 - PERF + old client] the old client drew every hud text as
        -- ONE black offset shadow + ONE colored pass (var16 pattern). The
        -- 5-pass outline tripled the dxDrawText cost for clock/date/zone and
        -- tooltips EVERY frame. 2 passes, same old-client look.
        local black = tocolor(0, 0, 0, 255)
        dxDrawText(text, x + 2, y + 2, x + w + 2, y + h + 2, black, scale, font, alignX, alignY, false, false, postGUI, colorCoded)
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

-- [Fix #52] meta.xml exported isActive but no function ever existed, so every
-- caller (chat icon, notifications, admin overlay, report box) raised
-- "failed to call 'hud:isActive'" every frame.
function isActive() return hudSettings.showhud end

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
-- STATUS RINGS — pure dxDrawCircle progress arcs (old-client colors/order).
-- Fix #19: SVG rendering proved unreliable in MTA (rings drew oversized and
-- off-center from their icons), so the arcs are now drawn directly:
-- perfectly centered on the icon at every ring size. Full state = full circle,
-- depleting gradually until the line disappears (old client behaviour).
--------------------------------------------------------------------------------
local RING_SIZE, RING_GAP = 36, 11
local RING_STROKE = 4            -- arc thickness (Fix #21: bigger + bolder)
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

local rings = {}       -- [id] = {value=0..100}
local statusValues = {} -- [id] = number (what the old client kept in statusHud vars)
-- [Fix #30] render-target cache state (declared EARLY: setProgress flips the
-- dirty flag, so it must be an upvalue of setProgress, not a later local)
local panelRT, panelRTDirty = false, true

local function createRing(id, colorHex)
        local ring = { value = 0 }
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
        if ring.value ~= value then
                ring.value = value
                statusValues[id] = value
                panelRTDirty = true   -- [Fix #30] repaint the cached panel
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
-- STATUS HUD GEOMETRY (old client row + Fix #19 frame/logo/money spec)
--   ring_x(i) = PANEL_X + PAD_L + LOGO_SIZE + LOGO_GAP + (S+G)*i
--   ring_y    = vertically centred in the frame
-- [Fix #35 - user] "رجعه وافضل مستطيلين عن بعض": the LOGO IS BACK inside the
--   status rectangle (Fix #33 removed it by misreading "clock rect without
--   logo" as "remove the logo from the status rect") and the panel is back
--   to a single ring row (PANEL_H 56). The clock + date live in their OWN
--   slightly-black rectangle right below the panel, close together, date
--   bigger than before and in the SAME font colour as the clock.
--------------------------------------------------------------------------------
local PANEL_PAD_L = 12
local LOGO_SIZE  = 40
local LOGO_GAP   = 14
local ROW_W = 7 * RING_SIZE + 6 * RING_GAP          -- 318
local PANEL_W = PANEL_PAD_L + LOGO_SIZE + LOGO_GAP + ROW_W + 16
-- clock/date rectangle (its own panel, no logo inside it)
local CLOCK_SCALE = 1.3
local DATE_SCALE   = 1.05
local CLOCK_LINE_H = 36
local DATE_LINE_H  = 27
-- [Fix #47 - user] strict rectangle per the reference shot: a little wider
-- so the right-aligned text floats over the fade zone like Image 1
local CLOCK_RECT_W = 172
local CLOCK_RECT_H = 8 + CLOCK_LINE_H + 2 + DATE_LINE_H + 8
local PANEL_H = 56
-- [Fix #32 - user] rest at the top with real margins - not glued to the edges
local PANEL_MARGIN_X = 14
local PANEL_X = sx - PANEL_W - PANEL_MARGIN_X
local CLOCK_RECT_X = sx - PANEL_MARGIN_X - CLOCK_RECT_W
local STRIP_H = 37

-- Fix #19: light purple frame — thin Vortex-purple border + a fill behind
-- the states. [Fix #32 - user] "تغمق لون كمان شوي": darker fill than #30/#31
local FRAME_BORDER = tocolor(149, 84, 255, 115)
local FRAME_FILL   = tocolor(8, 5, 16, 120)

local function drawStatusFrame(x, y, w, h, postGUI)
        dxDrawRoundedRectangle(x, y, w, h, FRAME_BORDER, 12, postGUI)
        dxDrawRoundedRectangle(x + 2, y + 2, w - 4, h - 4, FRAME_FILL, 10, postGUI)
end

local statusHud = { visible = false, anims = { count = 0, time = 250, from = -80, to = 2, current = -80 } }
local statusHudDraw -- forward declaration
local moneyBlockBottom = false   -- bottom Y of the money block (publishes hud:topRightBottom for the reports dock)
local zoneText, zoneLabel = "", ""
local zoneLabelColor = tocolor(255, 255, 255, 255)

--------------------------------------------------------------------------------
-- [Fix #30 - FPS] RENDER-TARGET CACHE for the status panel.
-- The frame + logo + 7 rings + icons used to be re-drawn EVERY frame
-- (~25 shader/image draws). They only change when a VALUE changes or the
-- panel slides in / a critical icon blinks - so they are painted into a
-- small render target and each frame now costs ONE dxDrawImage.
--------------------------------------------------------------------------------
local lastPulsePaint = 0
local PANEL_RT_PAD = 2
local lastClockText = ""   -- [Fix #33] repaint the RT once per minute

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

local function statusTexts()
        return getCurrentTime(), getCurrentDate()
end

local function destroyPanelRT()
        if isElement(panelRT) then destroyElement(panelRT) end
        panelRT = false
end

local function ensurePanelRT()
        if not isElement(panelRT) then
                panelRT = dxCreateRenderTarget(PANEL_W + PANEL_RT_PAD * 2,
                        PANEL_H + PANEL_RT_PAD * 2, true)
                panelRTDirty = true
        end
        return isElement(panelRT)
end

local function pulseForPaint()
        return math.abs(math.sin(getTickCount() / 300)) * 230
end

-- [Fix #47 - user] CLOCK = STRICT RECTANGLE (Image 1): sharp corners, NO
-- purple border, background is a right->left dark fade (solid at the right
-- screen edge, dissolving to nothing on the left) exactly like the shot.
-- The fade is painted ONCE into a 128x1 render target; each frame costs one
-- dxDrawImage (fallback: flat rectangle when RT creation fails).
local clockGradTex = false
local function ensureClockGradient()
        if isElement(clockGradTex) then return true end
        local ok, rt = pcall(dxCreateRenderTarget, 128, 1, true)
        if not ok or not rt then return false end
        local painted = pcall(function()
                dxSetRenderTarget(rt, true)
                for x = 0, 127 do
                        local t = x / 127
                        local a = math.floor(205 * (t * t)) -- solid hugs the right edge
                        dxDrawRectangle(x, 0, 1, 1, tocolor(12, 10, 14, a))
                end
                dxSetRenderTarget()
        end)
        if not painted then return false end
        clockGradTex = rt
        return true
end

local function drawStatusClock(panelY, postGUI)
        local clockText, dateText = statusTexts()
        local x, y = CLOCK_RECT_X, panelY + PANEL_H + 6
        if ensureClockGradient() then
                dxDrawImage(x, y, CLOCK_RECT_W, CLOCK_RECT_H, clockGradTex, 0, 0, 0,
                        tocolor(255, 255, 255, 255), postGUI)
        else
                dxDrawRectangle(x, y, CLOCK_RECT_W, CLOCK_RECT_H,
                        tocolor(12, 10, 14, 190), postGUI)
        end
        -- clock (bigger) on top, date below - both white, right-aligned
        outlineText(clockText, x + 12, y + 6, CLOCK_RECT_W - 22, CLOCK_LINE_H,
                tocolor(255, 255, 255, 255), CLOCK_SCALE, fontHudLarge(), "right", "top", postGUI)
        outlineText(dateText, x + 12, y + 6 + CLOCK_LINE_H + 2, CLOCK_RECT_W - 22, DATE_LINE_H,
                tocolor(255, 255, 255, 255), DATE_SCALE, fontHudLarge(), "right", "top", postGUI)
        return CLOCK_RECT_H + 6
end

local function repaintPanelRT()
        if not ensurePanelRT() then return false end
        dxSetRenderTarget(panelRT, true)
        local ox, oy = PANEL_RT_PAD, PANEL_RT_PAD -- draw offset inside the RT
        drawStatusFrame(ox, oy, PANEL_W, PANEL_H, false)
        if tex.logo then
                dxDrawImage(ox + PANEL_PAD_L, oy + (PANEL_H - LOGO_SIZE) / 2,
                        LOGO_SIZE, LOGO_SIZE, tex.logo, 0, 0, 0, tocolor(255, 255, 255, 235))
        end
        local ringY = oy + (PANEL_H - RING_SIZE) / 2
        local S, G = RING_SIZE, RING_GAP
        local firstX = ox + PANEL_PAD_L + LOGO_SIZE + LOGO_GAP
        for i = 0, 6 do
                local def = RING_DEFS[i + 1]
                local ring = rings[def.id]
                local x = firstX + (S + G) * i
                local cx, cy = x + S / 2, ringY + S / 2
                local value = ring and ring.value or 0
                local shown = def.id == "urine" and (100 - value) or value
                drawSmoothDisc(cx, cy, S / 2 - RING_STROKE + 0.5, 10, 6, 20, 165, false)
                if shown > 0.25 then
                        drawSmoothRing(cx, cy, S, S / 2 - RING_STROKE / 2 - 0.5, RING_STROKE,
                                def.tint[1], def.tint[2], def.tint[3], 255, shown / 100, false)
                end
                local icon = tex[def.icon]
                if icon then
                        local a = 255
                        if def.id == "health" then
                                a = getRingValue("health") > 10 and 255 or pulseForPaint()
                        elseif def.id == "sleep" or def.id == "sleepy" then
                                a = getRingValue("sleepy") < 90 and 255 or pulseForPaint()
                        elseif def.id == "thirsty" then
                                a = getRingValue("thirsty") > 5 and 255 or pulseForPaint()
                        elseif def.id == "hungry" then
                                a = getRingValue("hungry") > 5 and 255 or pulseForPaint()
                        elseif def.id == "toilet" then
                                a = getRingValue("urine") < 90 and 255 or pulseForPaint()
                        elseif def.id == "fatigue" then
                                a = getRingValue("fatigue") < 90 and 255 or pulseForPaint()
                        elseif def.id == "shower" then
                                a = getRingValue("cleanness") > 5 and 255 or pulseForPaint()
                        end
                        local dw, dh = iconDrawSize(def.icon, S * 0.66)
                        local ix = x + S / 2 - dw / 2
                        local iy = ringY + S / 2 - dh / 2
                        dxDrawImage(ix, iy, dw, dh, icon, 0, 0, 0,
                                tocolor(def.tint[1], def.tint[2], def.tint[3], a))
                end
        end
        -- [Fix #35] the clock/date rect is NOT part of the RT anymore - it is
        -- drawn live below the panel by statusHudDrawImpl (2 outline texts)
        dxSetRenderTarget()
        panelRTDirty = false
        return true
end

function showStatusHud(state)
        if state == statusHud.visible then return end
        if state then
                statusHud.anims.count = getTickCount()
                statusHud.anims.from = statusHud.anims.current
                -- [Fix #31 -> #32 - user] rest at the top of the screen but
                -- NOT glued to the edges: ~17px top rest, 14px right margin
                statusHud.anims.to = 12
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

--------------------------------------------------------------------------------
-- MONEY (Fix #19): no background rectangle at all. The green $ dot hugs the
-- amount and the whole slot is FLEXIBLE — it smoothly widens as the money
-- grows and tightens when it drops. Amounts carry thousand separators.
--------------------------------------------------------------------------------
local function formatMoney(n)
        local s = tostring(math.floor(tonumber(n) or 0))
        local k
        repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
        return s
end

local moneyFlex = nil   -- smoothed text width driving the icon position
local lastTopRightBottom = nil   -- [Fix #33] published for the reports list

local MONEY_SCALE = 1.45   -- [Fix #33 - user] "الفلوس كبرها"
local MONEY_ROW_H = 34

local function drawMoneyBlock(rightX, y, postGUI)
        -- Fix #23: this server keeps money in elementData "money" (custom economy),
        -- the MTA builtin stays 0 — read the real value, fall back to the builtin.
        local money = tonumber(getElementData(localPlayer, "money"))
                or getPlayerMoney(localPlayer) or 0
        local coins = tonumber(getElementData(localPlayer, "bios:coins"))
        local rowH = MONEY_ROW_H

        -- row 1: money (green dot, old client colors, no background)
        -- Fix #21: amount big enough to read at a glance / Fix #33: bigger
        local text = formatMoney(money)
        local tw = dxGetTextWidth(text, MONEY_SCALE, fontDefault()) or 0
        if not moneyFlex then moneyFlex = tw end
        moneyFlex = moneyFlex + (tw - moneyFlex) * 0.12   -- flexible slot
        local cy = y + rowH / 2
        local iconCX = rightX - moneyFlex - 12 - 11
        drawSmoothDisc(iconCX, cy, 11, 0, 255, 133, 255, postGUI)
        dxDrawText("$", iconCX - 11, cy - 12, iconCX + 11, cy + 12,
                tocolor(8, 40, 26, 255), 1.0, fontDefault(), "center", "center", false, false, postGUI)
        dxDrawText(text, iconCX + 13, y, rightX, y + rowH,
                tocolor(255, 255, 255, 255), MONEY_SCALE, fontDefault(), "right", "center", false, false, postGUI)
        local bottom = y + rowH

        -- row 2: coins (red dot) — only while the coins system exists
        if coins then
                local r2y = y + rowH + 10
                drawSmoothDisc(iconCX, r2y + rowH / 2, 11, 255, 45, 45, 255, postGUI)
                dxDrawText(tostring(coins), iconCX + 13, r2y, rightX, r2y + rowH,
                        tocolor(255, 255, 255, 210), 1.1, fontHud(), "right", "center", false, false, postGUI)
                bottom = r2y + rowH
        end
        return bottom - y
end

local function statusHudDrawImpl()
        if not statusHud.visible or not isHudShowing() then return end
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "character:id") then return end

        local postGUI = true
        local nowTick = getTickCount()
        local animY = anim(statusHud.anims.count, statusHud.anims.time, statusHud.anims.from, statusHud.anims.to)
        local panelY = animY + 25 - 20 * SCALE
        if panelY < -PANEL_H then return end
        local animating = (nowTick - statusHud.anims.count) < (statusHud.anims.time + 60)

        -- pulse (old client): math.abs(sin(tick/300)) * 230 drives critical blink
        local pulse = math.abs(math.sin(nowTick / 300)) * 230
        local anyCritical =
                (getRingValue("health") <= 10) or (getRingValue("sleepy") >= 90)
                or (getRingValue("thirsty") <= 5) or (getRingValue("hungry") <= 5)
                or (getRingValue("urine") >= 90) or (getRingValue("fatigue") >= 90)
                or (getRingValue("cleanness") <= 5)

        -- [Fix #30 - FPS] the frame + logo + rings + icons live in a render
        -- target repainted ONLY on value changes / slide-in / blink steps.
        -- One dxDrawImage per frame instead of ~30 draws.
        -- [Fix #35] the clock flipped to its own rect below the panel, so the
        -- minute flip no longer needs an RT repaint.
        local rtPainted = false
        if (panelRTDirty or animating or (anyCritical and nowTick - lastPulsePaint > 120)) then
                lastPulsePaint = nowTick
                rtPainted = repaintPanelRT()
        end
        if isElement(panelRT) and rtPainted ~= nil then
                dxDrawImage(PANEL_X - PANEL_RT_PAD, panelY - PANEL_RT_PAD,
                        PANEL_W + PANEL_RT_PAD * 2, PANEL_H + PANEL_RT_PAD * 2,
                        panelRT, 0, 0, 0, tocolor(255, 255, 255, 255), postGUI)
        else
                -- no render target (creation failed): direct draw fallback
                drawStatusFrame(PANEL_X, panelY, PANEL_W, PANEL_H, postGUI)
                if tex.logo then
                        dxDrawImage(PANEL_X + PANEL_PAD_L,
                                panelY + (PANEL_H - LOGO_SIZE) / 2,
                                LOGO_SIZE, LOGO_SIZE, tex.logo, 0, 0, 0,
                                tocolor(255, 255, 255, 235), postGUI)
                end
                local ringY = panelY + (PANEL_H - RING_SIZE) / 2
                local S, G = RING_SIZE, RING_GAP
                local firstX = PANEL_X + PANEL_PAD_L + LOGO_SIZE + LOGO_GAP
                for i = 0, 6 do
                        local def = RING_DEFS[i + 1]
                        local ring = rings[def.id]
                        local x = firstX + (S + G) * i
                        local cx, cy = x + S / 2, ringY + S / 2
                        local value = ring and ring.value or 0
                        local shown = def.id == "urine" and (100 - value) or value
                        drawSmoothDisc(cx, cy, S / 2 - RING_STROKE + 0.5, 10, 6, 20, 165, postGUI)
                        if shown > 0.25 then
                                drawSmoothRing(cx, cy, S, S / 2 - RING_STROKE / 2 - 0.5, RING_STROKE,
                                        def.tint[1], def.tint[2], def.tint[3], 255, shown / 100, postGUI)
                        end
                        local icon = tex[def.icon]
                        if icon then
                                local a = 255
                                if def.id == "health" then
                                        a = getRingValue("health") > 10 and 255 or pulse
                                elseif def.id == "sleep" or def.id == "sleepy" then
                                        a = getRingValue("sleepy") < 90 and 255 or pulse
                                elseif def.id == "thirsty" then
                                        a = getRingValue("thirsty") > 5 and 255 or pulse
                                elseif def.id == "hungry" then
                                        a = getRingValue("hungry") > 5 and 255 or pulse
                                elseif def.id == "toilet" then
                                        a = getRingValue("urine") < 90 and 255 or pulse
                                elseif def.id == "fatigue" then
                                        a = getRingValue("fatigue") < 90 and 255 or pulse
                                elseif def.id == "shower" then
                                        a = getRingValue("cleanness") > 5 and 255 or pulse
                                end
                                local dw, dh = iconDrawSize(def.icon, S * 0.66)
                                local ix = x + S / 2 - dw / 2
                                local iy = ringY + S / 2 - dh / 2
                                dxDrawImage(ix, iy, dw, dh, icon, 0, 0, 0,
                                        tocolor(def.tint[1], def.tint[2], def.tint[3], a), postGUI)
                        end
                end
        end
        -- [Fix #35] the clock + date in their own black rect right below the
        -- panel; the money block docks under THAT rect (bottom published for
        -- the reports list so it never overlaps the stack)
        local clockRectH = drawStatusClock(panelY, postGUI)
        -- shield ring: old client draws it under the last column while > 0
        if getRingValue("shield") > 0 then
                local S, G = RING_SIZE, RING_GAP
                local x = PANEL_X + PANEL_PAD_L + LOGO_SIZE + LOGO_GAP + (S + G) * 6
                local y = panelY + PANEL_H + 150 * SCALE
                local cx, cy = x + S / 2, y + S / 2
                drawSmoothDisc(cx, cy, S / 2 - RING_STROKE + 0.5, 10, 6, 20, 130, postGUI)
                if getRingValue("shield") > 0.25 then
                        drawSmoothRing(cx, cy, S, S / 2 - RING_STROKE / 2 - 0.5, RING_STROKE,
                                255, 255, 255, 255, getRingValue("shield") / 100, postGUI)
                end
                if tex.shield then
                        local a = getRingValue("shield") > 5 and 220 or pulse
                        local dw, dh = iconDrawSize("shield", S * 0.62)
                        local ix = x + S / 2 - dw / 2
                        local iy = y + S / 2 - dh / 2
                        dxDrawImage(ix, iy, dw, dh, tex.shield, 0, 0, 0,
                                tocolor(255, 255, 255, a), postGUI)
                end
        end

        -- [Fix #33] money sits right under the clock/date rectangle; its
        -- bottom is published for the reports list so the panel can dock
        -- UNDER the money instead of overlapping the stack
        local mh = drawMoneyBlock(sx - 14, panelY + PANEL_H + clockRectH + 4, postGUI)
        moneyBlockBottom = panelY + PANEL_H + clockRectH + 4 + mh
        if math.abs((tonumber(lastTopRightBottom) or 0) - moneyBlockBottom) >= 1 then
                lastTopRightBottom = moneyBlockBottom
                setElementData(localPlayer, "hud:topRightBottom", moneyBlockBottom, false)
        end

        -- zone label, bottom-left above the radar (old client)
        outlineText(zoneText:gsub("#%x%x%x%x%x%x", ""), 18, sy - 226, 460, 22,
                tocolor(255, 255, 255, 255), 1, fontHud(), "left", "top", postGUI)
        outlineText(zoneLabel, 18, sy - 202, 460, 22, zoneLabelColor, 1, fontHud(), "left", "top", postGUI)
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
                if CONFIG.safeZones[city] then
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
local lastHoveredItem = 0
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
                                        -- [Fix #32 - LAG] hoveredItem resets to 0 at the top of
                                        -- every frame, so "hoveredItem ~= i" was ALWAYS true and
                                        -- playSound fired EVERY FRAME while the cursor rested on
                                        -- an item (dozens of sound elements per second = the lag
                                        -- storm). Track the real previous index.
                                        if lastHoveredItem ~= i then
                                                playSelectSound()
                                        end
                                        lastHoveredItem = i
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
        -- [Fix #34 - user] "نزل امور مثل حزام وغيره فرامل يد وذول لتحت عداد
        -- السرعة وكبرهم": the engine/handbrake/seatbelt/lights/lock row moved
        -- from the top-right money stack to UNDER the speedometer dial,
        -- icons 24 -> 30, centred on the gauge (SPEEDO_* globals from
        -- c_speedo.lua - same client VM, set at file scope)
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleController(veh) == localPlayer then
                -- [Fix #35] icons scaled up with the bigger dial
                -- [Fix #47] dial is 108 now - row icons 34 -> 38 to keep pace
                local size, gap = 38, 9
                local rowW = #VEH_ITEMS * size + (#VEH_ITEMS - 1) * gap
                local scx = tonumber(SPEEDO_CX) or (sx - 104)
                local scy = tonumber(SPEEDO_CY) or (sy - 138)
                local sdisc = tonumber(SPEEDO_DISC_R) or 66
                local vx = scx - rowW / 2
                local vy = math.min(scy + sdisc + 12, sy - size - 28)
                local rowX = vx
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
                        -- label sits BELOW the row (old client strip behaviour;
                        -- above is the dial rim, below is the screen edge)
                        outlineText(hovered.label, rowX, vy + size + 6, rowW, 20,
                                tocolor(255, 255, 255, 230), 1, "default-bold",
                                "center", "top", true)
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
                -- [Fix #32 - user] "قائمة الريبورتات ماتظهر ريبورتات موجودة":
                -- the old client opens the LIVE REPORTS LIST through the
                -- reports:showUnansweredReportsPanel protocol (report-system
                -- c_report_panel.lua), not the /report submit window
                if getElementData(localPlayer, "report_panel_state") then
                        setElementData(localPlayer, "report_panel_state", false, false)
                        triggerServerEvent("reports:onHideUnansweredReportsPanel", localPlayer)
                        triggerEvent("reports:togglePanel", localPlayer, false)
                else
                        setElementData(localPlayer, "report_panel_state", true, false)
                        triggerServerEvent("reports:showUnansweredReportsPanel", localPlayer)
                        triggerEvent("reports:togglePanel", localPlayer, true)
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

-- [Fix #30] the strip used to be built ONCE at activation: any server-side
-- hud:items update (duty item added, duty state flipped, new items) never
-- reached the open strip until re-login. Live-refresh on data change.
addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "hud:items" then
                updateHudItemsList()
        end
end)

--------------------------------------------------------------------------------
-- ACTIVATION — old client events + this server's loggedin flag
--------------------------------------------------------------------------------
local function activateHud()
        refreshConfig()
        loadTextures()
        initShaders()
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
        destroyPanelRT()   -- [Fix #30] free the render target with the textures
        for _, t in pairs(tex) do
                if isElement(t) then destroyElement(t) end
        end
        tex = {}
        moneyFlex = nil
end

-- [Fix #30] render-target content is lost on device restore (alt-tab,
-- resolution change) - force one repaint afterwards
addEventHandler("onClientRestore", root, function()
        panelRTDirty = true
        if isElement(clockGradTex) then destroyElement(clockGradTex) end
        clockGradTex = false -- [Fix #47] the 1D clock gradient is an RT too
end)

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

--------------------------------------------------------------------------------
-- [Fix #35] /fpsdiag — FIND THE LAG ON THE ACTUAL MACHINE. The user reports
-- constant low FPS even with the HUD hidden; the code audit of every
-- per-frame handler found them all gated, so measure it live instead of
-- guessing: the client samples FPS while the SERVER temporarily stops each
-- suspect resource one at a time and restarts it. The resource whose absence
-- RAISES the FPS is the culprit. Owner/debug tool.
--------------------------------------------------------------------------------
addEvent("fpsdiag:phase", true)
addEventHandler("fpsdiag:phase", localPlayer, function(phaseName, sampleMs)
        local frames = 0
        local t0 = getTickCount()
        local function counter() frames = frames + 1 end
        addEventHandler("onClientRender", root, counter, false, "high+100")
        setTimer(function()
                removeEventHandler("onClientRender", root, counter)
                local dt = math.max(getTickCount() - t0, 1)
                local fps = math.floor(frames / dt * 1000 + 0.5)
                local st = {}
                if dxGetStatus then
                        local ok, s = pcall(dxGetStatus)
                        if ok and type(s) == "table" then st = s end
                end
                triggerServerEvent("fpsdiag:result", localPlayer, phaseName, fps, {
                        card = tostring(st.VideoCardName or "?"),
                        freeVRAM = tonumber(st.VideoMemoryFreeForMTA) or -1,
                        rtMB = tonumber(st.VideoMemoryUsedByRenderTargets) or -1,
                        texMB = tonumber(st.VideoMemoryUsedByTextures) or -1,
                        players = #getElementsByType("player"),
                })
        end, sampleMs, 1)
end)

addCommandHandler("fpsdiag", function()
        triggerServerEvent("fpsdiag:start", localPlayer)
        outputChatBox("[fpsdiag] measuring - stand still for ~25 seconds...", 255, 220, 120, false)
end)
