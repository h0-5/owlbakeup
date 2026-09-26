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
        return UI.window.picker and isElement(UI.window.picker)
                and eui:uiGetVisible(UI.window.picker)
end

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
                eui:uiSetVisible(UI.window.picker, false)
                triggerEvent("onClientColorPickerConfirm", localPlayer,
                        cpColor.r, cpColor.g, cpColor.b, cpColor.a)
        elseif source == UI.button.cancel then
                eui:uiSetVisible(UI.window.picker, false)
        end
end)
