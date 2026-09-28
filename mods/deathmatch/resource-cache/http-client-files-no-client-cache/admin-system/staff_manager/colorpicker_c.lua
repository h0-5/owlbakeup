--[[ ------------------------------------------------------------------------
        Vortex Staff Panel — UIKit color picker.

        The original rp-admin used the packed colorpicker resource that did
        not survive the backup (binary blob). This module restores the SAME
        interface the decompiled client calls:

            colorPicker.openSelect()      -- opens the picker (uses the
                                          -- caller's currentColorLabel state)
            colorPicker.RGBToHex(r,g,b,a) -- "#RRGGBBAA" helper

        and confirms through the onClientColorPickerConfirm event carrying
        (r, g, b, a), which the staff panel listens to.

        Built on UIKit so it matches the panel look (rounded, dark, Vortex
        buttons). Palette = web colors + the 21 Vortex rank colors.
-------------------------------------------------------------------------- ]]

local eui = nil

local UI = { window = {}, rectangle = {}, button = {}, label = {}, edit = {} }
local cpBuilt = false
local cpColor = { r = 255, g = 255, b = 255, a = 255 }

-- [Fix #50 - user] HEX COLOR CONFIG: accept #efc180 / #efc180c / efc180 /
-- short 3-4 digit forms; returns r, g, b, a or nil when not a color code
local function parseHexColor(text)
        if type(text) ~= "string" then return nil end
        local s = text:gsub("[%s#]", "")
        if s == "" then return nil end
        if not s:find("^%x+$") then return nil end
        if #s >= 8 then s = s:sub(1, 8)
        elseif #s == 7 then s = s:sub(1, 6)
        elseif #s == 5 then s = s:sub(1, 4)
        end
        local r, g, b, a
        if #s == 6 or #s == 8 then
                r = tonumber(s:sub(1, 2), 16)
                g = tonumber(s:sub(3, 4), 16)
                b = tonumber(s:sub(5, 6), 16)
                a = (#s == 8) and tonumber(s:sub(7, 8), 16) or 255
        elseif #s == 3 or #s == 4 then
                r = tonumber(s:sub(1, 1):rep(2), 16)
                g = tonumber(s:sub(2, 2):rep(2), 16)
                b = tonumber(s:sub(3, 3):rep(2), 16)
                a = (#s == 4) and tonumber(s:sub(4, 4):rep(2), 16) or 255
        else
                return nil
        end
        if not (r and g and b and a) then return nil end
        return r, g, b, a
end

-- commit whatever is currently typed in the hex edit (called by BOTH confirm
-- paths so an unparsed string can never be silently dropped)
local function commitHexFromEdit()
        if not (UI.edit.hex and isElement(UI.edit.hex)) then return false end
        local okText, text = pcall(function() return eui:uiGetText(UI.edit.hex) end)
        if not okText or not text or text == "" then return false end
        local r, g, b, a = parseHexColor(text)
        if r then
                cpColor.r, cpColor.g, cpColor.b, cpColor.a = r, g, b, a
                return true
        end
        return false
end


local PALETTE = {
        -- Vortex rank colors (the ones the server seeds)
        {255,140,0}, {204,85,0}, {102,178,255}, {52,152,219}, {32,112,178},
        {16,72,130}, {144,50,250}, {94,76,252}, {255,215,0}, {160,101,54},
        {255,105,180}, {199,84,124}, {128,0,32}, {120,0,10}, {170,0,0},
        {220,0,0}, {0,120,255}, {255,0,0},
        -- web colors
        {255,255,255},{220,220,220},{192,192,192},{128,128,128},{64,64,64},{0,0,0},
        {255,0,255},{255,0,127},{176,48,96},{240,128,128},{250,128,114},{233,150,122},
        {255,127,80},{255,160,122},{255,165,0},{255,190,0},{255,206,0},{218,165,32},
        {184,134,11},{188,143,143},{222,196,144},{245,222,179},{255,228,196},{255,235,205},
        {120,219,226},{0,255,255},{64,224,208},{0,206,209},{32,178,170},{95,158,160},
        {0,128,128},{0,255,127},{124,252,0},{127,255,0},{50,205,50},{34,139,34},
        {0,100,0},{144,238,144},{152,251,152},{143,188,143},{60,179,113},{46,139,87},
        {135,206,235},{135,206,250},{176,224,230},{173,216,230},{100,149,237},{30,144,255},
        {0,0,255},{65,105,225},{0,0,205},{25,25,112},{138,43,226},{147,112,219},
        {216,191,216},{221,160,221},{238,130,238},{255,0,255},{186,85,211},{153,50,204},
}

local SW_COLS, SW_ROWS = 15, 5
local SW_SIZE, SW_GAP = 26, 4

-- global API table (same name the original decompiled client calls)
colorPicker = colorPicker or {}

local function buildPicker()
        if cpBuilt and UI.window.picker and isElement(UI.window.picker) then return end
        if UI.window.picker and isElement(UI.window.picker) then
                destroyElement(UI.window.picker)
        end
        eui = exports.UIKit

        UI.window.picker = eui:uiCreateWindow(false, false, 560, 360,
                "Color Picker / اختر لوناً")
        eui:uiWindowSetMovable(UI.window.picker, false)
        eui:uiSetVisible(UI.window.picker, false)

        UI.rectangle.preview = eui:uiCreateRectangle(10, 35, 540, 40,
                tocolor(255, 255, 255, 255), true, true, true, true, UI.window.picker)
        UI.label.preview = eui:uiCreateLabel(0, 0, 540, 40, "#FFFFFF",
                tocolor(0, 0, 0, 220), "center", "center", UI.rectangle.preview)

        -- swatch grid
        local x0, y0 = 10, 85
        for i, rgb in ipairs(PALETTE) do
                local col = (i - 1) % SW_COLS
                local row = math.floor((i - 1) / SW_COLS)
                local sw = eui:uiCreateRectangle(x0 + col * (SW_SIZE + SW_GAP),
                        y0 + row * (SW_SIZE + SW_GAP), SW_SIZE, SW_SIZE,
                        tocolor(rgb[1], rgb[2], rgb[3], 255), true, true, true, true,
                        UI.window.picker)
                UI.rectangle["swatch_" .. i] = sw
                UI.rectangle["swatchrgb_" .. i] = rgb
        end

        -- [Fix #50 - user] hex color config input
        UI.edit.hex = eui:uiCreateEdit(10, 270, 380, 32, "", "#efc180 - hex color code",
                tocolor(255, 255, 255, 255), UI.window.picker)
        eui:uiSetProperty(UI.edit.hex, "UnderLineVisible", "False")
        eui:uiSetFont(UI.edit.hex, "default-large")
        UI.label.hex_hint = eui:uiCreateLabel(400, 270, 150, 32, { en = "live preview", ar = "معاينة مباشرة" },
                tocolor(160, 160, 170, 220), "left", "center", UI.window.picker)

        UI.button.ok = eui:uiCreateButton(10, 315, 265, 35,
                { en = "Confirm", ar = "تأكيد" }, "primary", UI.window.picker)
        UI.button.cancel = eui:uiCreateButton(285, 315, 265, 35,
                { en = "Cancel", ar = "إلغاء" }, tocolor(9, 12, 17, 220), UI.window.picker)

        cpBuilt = true
end

function colorPicker.openSelect(r, g, b, a)
        buildPicker()
        if not cpBuilt then return false end
        if r then
                cpColor.r, cpColor.g, cpColor.b, cpColor.a = tonumber(r) or 255,
                        tonumber(g) or 255, tonumber(b) or 255, tonumber(a) or 255
        end
        eui:uiSetColor(UI.rectangle.preview, cpColor.r, cpColor.g, cpColor.b, 255)
        eui:uiSetText(UI.label.preview, ("#%02X%02X%02X"):format(cpColor.r, cpColor.g, cpColor.b))
        eui:uiSetVisible(UI.window.picker, true)
        eui:uiBringToFront(UI.window.picker)
        showCursor(true)
        return true
end

function colorPicker.closeSelect()
        if UI.window.picker and isElement(UI.window.picker) then
                eui:uiSetVisible(UI.window.picker, false)
        end
end

function colorPicker.RGBToHex(red, green, blue, alpha)
        return string.format("#%02X%02X%02X%02X", tonumber(red) or 255,
                tonumber(green) or 255, tonumber(blue) or 255, tonumber(alpha) or 255)
end

function colorPicker.isPickerVisible()
        if not (UI.window.picker and isElement(UI.window.picker)) then return false end
        -- [Fix #34] pcall: a UIKit restart between the isElement check and the
        -- export call used to hard-error the whole client VM from inside the
        -- raw click handler
        local ok, v = pcall(function() return eui:uiGetVisible(UI.window.picker) end)
        return (ok and v == true) or false
end

-- [Fix #50] live hex parse while typing
addEventHandler("onClientUIChanged", root, function()
        if source ~= UI.edit.hex then return end
        if not commitHexFromEdit() then return end
        if UI.rectangle.preview and isElement(UI.rectangle.preview) then
                pcall(function()
                        eui:uiSetColor(UI.rectangle.preview, cpColor.r, cpColor.g, cpColor.b, 255)
                        eui:uiSetText(UI.label.preview, ("#%02X%02X%02X"):format(cpColor.r, cpColor.g, cpColor.b))
                end)
        end
end)

addEventHandler("onClientUIClick", root, function()
        if not (UI.window.picker and isElement(UI.window.picker)) then return end
        -- swatch hit?
        for i = 1, #PALETTE do
                if source == UI.rectangle["swatch_" .. i] then
                        local rgb = UI.rectangle["swatchrgb_" .. i]
                        cpColor.r, cpColor.g, cpColor.b = rgb[1], rgb[2], rgb[3]
                        eui:uiSetColor(UI.rectangle.preview, cpColor.r, cpColor.g, cpColor.b, 255)
                        eui:uiSetText(UI.label.preview,
                                ("#%02X%02X%02X"):format(cpColor.r, cpColor.g, cpColor.b))
                        return
                end
        end
        if source == UI.button.ok then
                commitHexFromEdit() -- [Fix #50] never drop a typed code
                eui:uiSetVisible(UI.window.picker, false)
                triggerEvent("onClientColorPickerConfirm", localPlayer,
                        cpColor.r, cpColor.g, cpColor.b, cpColor.a)
        elseif source == UI.button.cancel then
                eui:uiSetVisible(UI.window.picker, false)
        end
end)

--[[ [Fix #17] RAW-INPUT FALLBACK ============================================
        The UIKit event pipeline (onClientClick -> UI.click -> onClientUIClick)
        is not reliably alive on this server, so the picker's UIKit-only
        handler above never fired: clicking a swatch or Confirm did nothing
        ("can't change the rank color"). The staff panel already routes its
        own clicks through a raw hit-test; the picker builds the SAME kind of
        absolute-rect registry and answers MTA's raw onClientClick itself.
        A per-element latch stops the two paths from double-firing.
========================================================================== ]]

local CP_HIT = {}          -- [element] = { x, y, w, h, kind, payload }
local cpDispatchTick = {}  -- per-element latch (300ms)

-- [Fix #32 - user] "لو ضغط على لون ياخذ كبسة على لوحة لتحتها": the hit rects
-- were re-derived by hand from the reference-space math and DRIFTED from what
-- UIKit actually paints (window centering + title bar), so a click on one
-- swatch registered on the row below. The registry now reads each element's
-- ABSOLUTE rendered rect straight from UIKit (uiGetAbsoluteBounds) - the same
-- geometry the drawing loop and hover use - so click == visual, always.
local function rebuildPickerHits()
        CP_HIT = {}
        if not (UI.window.picker and isElement(UI.window.picker)) then return end
        local function reg(el, kind, payload)
                if not el or not isElement(el) then return end
                local ok, x, y, w, h = pcall(eui.uiGetAbsoluteBounds, eui, el)
                if not ok or not x then return end
                CP_HIT[el] = { x = x, y = y, w = w or 0, h = h or 0,
                        kind = kind, payload = payload }
        end
        reg(UI.window.picker, "window")
        reg(UI.rectangle.preview, "preview")
        for i, rgb in ipairs(PALETTE) do
                reg(UI.rectangle["swatch_" .. i], "swatch", rgb)
        end
        reg(UI.edit.hex, "edit")
        reg(UI.button.ok, "ok")
        reg(UI.button.cancel, "cancel")
end

local function applyPick(kind, payload)
        if kind == "edit" then
                -- [Fix #50] the modal swallows raw clicks; route the edit click
                -- into a programmatic focus so typing works
                pcall(eui.uiSetFocusedElement, eui, UI.edit.hex)
                return
        end
        if kind == "swatch" and payload then
                cpColor.r, cpColor.g, cpColor.b = payload[1], payload[2], payload[3]
                eui:uiSetColor(UI.rectangle.preview, cpColor.r, cpColor.g, cpColor.b, 255)
                eui:uiSetText(UI.label.preview,
                        ("#%02X%02X%02X"):format(cpColor.r, cpColor.g, cpColor.b))
        elseif kind == "ok" then
                commitHexFromEdit() -- [Fix #50] never drop a typed code
                eui:uiSetVisible(UI.window.picker, false)
                pcall(eui.uiFlashPress, eui, UI.button.ok)
                triggerEvent("onClientColorPickerConfirm", localPlayer,
                        cpColor.r, cpColor.g, cpColor.b, cpColor.a)
        elseif kind == "cancel" then
                eui:uiSetVisible(UI.window.picker, false)
        end
end

--[[ [Fix #34 - user] "تقدر تضغط على القائمة لتحتها مع انك تكون جالس تختار لون
        فبسبب الخطا ذا يختار رتبة ثانية ويصير لون لها": the picker sat ON TOP of
        the staff panel, but a click on a swatch ALSO travelled underneath -
        the panel's raw hit-test matched the rank row behind it, selected
        another rank, and the confirm then recolored THAT rank. The picker is
        now a TRUE MODAL: while it is visible EVERY raw click is swallowed
        (cancelEvent on down AND up, inside or outside the picker window), the
        staff panel additionally refuses all input (see staff_manager_c.lua)
        and Escape closes it. There is no legal click target behind the picker
        while it is open, so nothing can ever be selected through it again.
========================================================================== ]]

local function pickerSwallowClick(button, state, ax, ay)
        if not colorPicker.isPickerVisible() then return end
        -- one click = down + up: kill BOTH halves so no element underneath
        -- (UIKit pipeline, panel raw hit-test, other resources) ever sees it
        cancelEvent(true)
        if button ~= "left" then return end
        if not CP_HIT[UI.window.picker] then rebuildPickerHits() end
        -- only "up" acts (same as before) - "down" is merely swallowed
        if state ~= "up" then return end
        -- topmost hit wins: iterate swatches last so they outrank the window
        local hitEl, hitInfo
        for el, info in pairs(CP_HIT) do
                if info.kind ~= "window" and ax >= info.x and ax <= info.x + (info.w or 0)
                        and ay >= info.y and ay <= info.y + (info.h or 0) then
                        hitEl, hitInfo = el, info
                end
        end
        if not hitEl then return end
        local nowTick = getTickCount()
        if cpDispatchTick[hitEl] and nowTick - cpDispatchTick[hitEl] < 300 then return end
        cpDispatchTick[hitEl] = nowTick
        pcall(eui.uiFlashPress, eui, hitEl)
        applyPick(hitInfo.kind, hitInfo.payload)
end

addEventHandler("onClientClick", root, function(button, state, ax, ay)
        pickerSwallowClick(button, state, ax, ay)
end)

-- [Fix #34] Escape closes the picker (and keeps the MTA main menu shut
-- while the modal is up); keypad_enter confirms the current swatch
addEventHandler("onClientKey", root, function(key, press)
        if not colorPicker.isPickerVisible() then return end
        if press ~= "down" then return end
        if key == "escape" then
                cancelEvent(true)
                colorPicker.closeSelect()
        elseif key == "enter" or key == "kp_enter" or key == "num_enter" then
                applyPick("ok")
        end
end)

-- rebuild the registry whenever the picker is opened (UIKit may have
-- re-created the elements after a restart, invalidating the old rects)
local raw_openSelect = colorPicker.openSelect
function colorPicker.openSelect(r, g, b, a)
        local res = raw_openSelect(r, g, b, a)
        setTimer(rebuildPickerHits, 50, 1)
        return res
end
