-- [Fix #160] A5 - /checkc client character-info panel (age/job)
-- Owned exclusively by the matching Fix #160 task agent.
--
-- Raw MTA GUI in the same shape as admin-system/c_check.lua ("Player Check"):
-- one window, one label grid, one Close button. The command itself is
-- SERVER-side (Player/s_checkc.lua, right admin.checkc); this file only
-- renders the table the server sends on "checkc:show".
--
-- Skin: reference "Character Info" panel - centered near-black rectangle
-- (10,10,12,245), red accent bar on the far left edge, (20,20,28) header strip
-- with the centred white title, a single active "Info" tab with the red
-- underline, two columns of "▸" bullet rows and a wide dark Close button. MTA
-- can not recolour the default window chrome, so the whole panel is drawn with
-- dx AFTER the GUI (postGUI = true) while the window is open. The gui labels
-- below are kept as the data store - the skin reads them back with
-- guiGetText(), so every setText() in the "checkc:show" handler keeps working
-- untouched.

local checkcWindow = nil
local checkcClose = nil
local checkcLabels = {}
local checkcCursorOwned = false

-- reference panel size at 1920x1080; every inner offset below is in these
-- base units and gets multiplied by checkcScale (smaller screens scale down)
local CHECKC_BASE_W, CHECKC_BASE_H = 660, 470
local checkcScale = 1

local checkcLabelDefs = {
        { "name",     "Name: N/A" },
        { "account",  "Account: N/A" },
        { "status",   "Status: N/A" },
        { "age",      "Age: N/A" },
        { "birthday", "Birthday: N/A" },
        { "gender",   "Gender: N/A" },
        { "body",     "Height/Weight: N/A" },
        { "job",      "Job: N/A" },
        { "faction",  "Faction: N/A" },
        { "hours",    "Hours played: N/A" },
        { "deaths",   "Deaths: N/A" },
        { "money",    "Cash: N/A" },
        { "bank",     "Bank: N/A" },
        { "area",     "Area: N/A" },
}

local function buildCheckcWindow()
        if checkcWindow and isElement(checkcWindow) then return end
        local sx, sy = guiGetScreenSize()
        local sc = math.min(sx / 1920, sy / 1080)
        if sc < 0.7 then sc = 0.7 end
        checkcScale = sc

        local width, height = CHECKC_BASE_W * sc, CHECKC_BASE_H * sc
        checkcWindow = guiCreateWindow((sx - width) / 2, (sy - height) / 2, width, height, "Character Info", false)
        guiWindowSetSizable(checkcWindow, false)

        checkcLabels = {}
        for i = 1, #checkcLabelDefs do
                local def = checkcLabelDefs[i]
                local label = guiCreateLabel(14 * sc, (66 + (i - 1) * 24) * sc,
                        (CHECKC_BASE_W - 30) * sc, 22 * sc, def[2], false, checkcWindow)
                -- invisible data store: the dx panel only covers it with alpha
                -- 245, so the native label bleeds through as misaligned ghost
                -- text (native rows sit at 66+24*i, the dx rows at 72+30*i).
                -- Hide it outright - guiGetText still reads it.
                guiLabelSetColor(label, 10, 10, 12)
                guiSetVisible(label, false)
                checkcLabels[def[1]] = label
        end

        checkcClose = guiCreateButton((CHECKC_BASE_W - 200) / 2 * sc, 404 * sc,
                200 * sc, 34 * sc, "Close", false, checkcWindow)
        addEventHandler("onClientGUIClick", checkcClose, function(button, state)
                if button ~= "left" or state ~= "up" then return end
                guiSetVisible(checkcWindow, false)
                -- refcount-safe: only drop the cursor we turned on ourselves
                if checkcCursorOwned then
                        showCursor(false)
                        checkcCursorOwned = false
                end
        end, false)

        guiSetVisible(checkcWindow, false)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        buildCheckcWindow()
end)

local function setText(key, text)
        local el = checkcLabels[key]
        if el and isElement(el) then
                guiSetText(el, tostring(text))
        end
end

addEvent("checkc:show", true)
addEventHandler("checkc:show", root, function(data)
        if type(data) ~= "table" then return end
        buildCheckcWindow()
        if not (checkcWindow and isElement(checkcWindow)) then return end

        local online = data.online and "Online" or "Offline"
        setText("name", "Name: " .. tostring(data.name or "N/A"))
        setText("account", "Account: " .. tostring(data.account or "N/A")
                .. (data.id and (" (character #" .. tostring(data.id) .. ")") or ""))
        setText("status", "Status: " .. tostring(data.status or "N/A") .. "  |  " .. online)
        setText("age", "Age: " .. tostring(data.age or "N/A"))
        setText("birthday", "Birthday: " .. tostring(data.birthday or "N/A"))
        setText("gender", "Gender: " .. tostring(data.gender or "N/A"))
        setText("body", "Height/Weight: " .. tostring(data.height or "?") .. " cm / "
                .. tostring(data.weight or "?") .. " kg")
        setText("job", "Job: " .. tostring(data.job or "N/A"))
        setText("faction", "Faction: " .. tostring(data.faction or "N/A")
                .. (data.factionRank and data.factionRank ~= "-" and (" - " .. tostring(data.factionRank)) or ""))
        setText("hours", "Hours played: " .. tostring(data.hours or "N/A"))
        setText("deaths", "Deaths: " .. tostring(data.deaths or "N/A"))
        setText("money", "Cash: $" .. tostring(data.money or "N/A"))
        setText("bank", "Bank: $" .. tostring(data.bank or "N/A"))
        setText("area", "Area: " .. tostring(data.area or "N/A"))

        guiSetVisible(checkcWindow, true)
        guiBringToFront(checkcWindow)
        -- the panel is open: make sure the cursor is on (and remember that we
        -- own it, so closing the panel never hides another panel's cursor)
        if not isCursorShowing() then
                showCursor(true)
                checkcCursorOwned = true
        end
end)

-- ---------------------------------------------------------------------------
-- reference "Character Info" skin (dx drawn AFTER the gui, so it covers the
-- default window chrome, the default labels and the default button look)
-- ---------------------------------------------------------------------------
local checkcSkin = {
        bg        = tocolor(10, 10, 12, 245),
        header    = tocolor(20, 20, 28, 255),
        red       = tocolor(226, 59, 59, 255),
        title     = tocolor(255, 255, 255, 255),
        key       = tocolor(255, 255, 255, 255),
        value     = tocolor(216, 216, 220, 255),
        money     = tocolor(255, 92, 92, 255),
        online    = tocolor(76, 175, 80, 255),
        offline   = tocolor(154, 154, 160, 255),
        btn       = tocolor(22, 22, 28, 255),
        btnHover  = tocolor(48, 48, 56, 255),
        btnBorder = tocolor(42, 42, 50, 255),
        dim       = tocolor(120, 120, 126, 255),
}

local CHECKC_HEADER_H = 34     -- header strip
local CHECKC_TAB_H = 26        -- tab row under the header

-- two column row grid (base y inside the 660x470 panel, 30px row spacing)
local checkcRows = {
        { y = 72,  left = "name" },
        { y = 102, left = "account" },
        { y = 132, left = "status" },
        { y = 162, left = "age",    right = "birthday" },
        { y = 192, left = "gender", right = "body" },
        { y = 222, left = "job" },
        { y = 252, left = "faction" },
        { y = 282, left = "hours",  right = "deaths" },
        { y = 312, left = "money",  right = "bank" },
        { y = 342, left = "area" },
}

local BULLET_L = 28             -- left column chevron
local COL_LX, COL_LW = 44, 287  -- left column text
local BULLET_R = 343            -- right column chevron (52% of the panel)
local COL_RX, COL_RW = 359, 281 -- right column text
local COL_FULLW = 596           -- full width rows

local function checkcMouseOver(x, y, w, h)
        local cx, cy = getCursorPosition()
        if not cx then return false end
        local sx, sy = guiGetScreenSize()
        cx, cy = cx * sx, cy * sy
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

-- "▸" (U+25B8) is in no font dxDrawText can resolve here - Arial, Arial Bold,
-- Tahoma, Verdana, Microsoft Sans Serif and MTA's own cgui/sans.ttf all lack
-- it, so the character drew as nothing and the panel lost its bullet column.
-- The chevron is drawn as geometry instead: a small filled right triangle.
local function drawCheckcBullet(bx, top, sc)
        local w, h = 6 * sc, 10 * sc
        local y0 = top + 3 * sc
        local steps = 11
        local rowH = h / steps
        for i = 0, steps - 1 do
                local t = (i + 0.5) / steps
                local segW = (1 - math.abs(t - 0.5) * 2) * w
                if segW > 0 then
                        dxDrawRectangle(bx, y0 + i * rowH, segW, rowH + 1,
                                checkcSkin.red, true)
                end
        end
end

-- "Label: value" -> red chevron bullet + white bold label + coloured value
local function drawCheckcRow(ox, oy, sc, bulletX, tx, tw, y, key)
        local element = checkcLabels[key]
        if not isElement(element) then return end
        local text = guiGetText(element)
        if not text or text == "" then return end

        local top = oy + y * sc
        local bottom = top + 17 * sc
        local x = ox + tx * sc
        local right = ox + (tx + tw) * sc

        drawCheckcBullet(ox + bulletX * sc + sc, top, sc)

        local label, value = string.match(text, "^(.-):%s*(.*)$")
        if not label or label == "" then
                dxDrawText(text, x, top, right, bottom,
                        checkcSkin.value, 0.9 * sc, "default", "left", "top", true, false, true)
                return
        end

        dxDrawText(label .. ":", x, top, right, bottom,
                checkcSkin.key, 0.9 * sc, "default-bold", "left", "top", true, false, true)
        if value == "" then return end

        local vx = x + dxGetTextWidth(label .. ": ", 0.9 * sc, "default-bold")
        if key == "status" then
                -- "Status: <state>  |  Online/Offline"
                local main, flag = string.match(value, "^(.-)%s*|%s*(.*)$")
                if main then
                        local prefix = main .. "  |  "
                        dxDrawText(prefix, vx, top, right, bottom,
                                checkcSkin.value, 0.9 * sc, "default", "left", "top", true, false, true)
                        local fx = vx + dxGetTextWidth(prefix, 0.9 * sc, "default")
                        local colour = (flag == "Online") and checkcSkin.online or checkcSkin.offline
                        dxDrawText(flag, fx, top, right, bottom,
                                colour, 0.9 * sc, "default", "left", "top", true, false, true)
                        return
                end
        elseif key == "money" or key == "bank" then
                dxDrawText(value, vx, top, right, bottom,
                        checkcSkin.money, 0.9 * sc, "default", "left", "top", true, false, true)
                return
        end

        dxDrawText(value, vx, top, right, bottom,
                checkcSkin.value, 0.9 * sc, "default", "left", "top", true, false, true)
end

local function drawCheckcButton(ox, oy, sc, element)
        if not isElement(element) then return end
        local bx, by = guiGetPosition(element, false)
        local bw, bh = guiGetSize(element, false)
        bx, by = ox + bx, oy + by

        local enabled = guiGetEnabled(element)
        local hover = enabled and checkcMouseOver(bx, by, bw, bh)
        local bg = checkcSkin.btn
        if hover then bg = checkcSkin.btnHover end
        dxDrawRectangle(bx, by, bw, bh, bg, true)
        -- 1px border (4 thin rectangles)
        dxDrawRectangle(bx, by, bw, sc, checkcSkin.btnBorder, true)
        dxDrawRectangle(bx, by + bh - sc, bw, sc, checkcSkin.btnBorder, true)
        dxDrawRectangle(bx, by, sc, bh, checkcSkin.btnBorder, true)
        dxDrawRectangle(bx + bw - sc, by, sc, bh, checkcSkin.btnBorder, true)
        if hover then
                dxDrawRectangle(bx, by, 3 * sc, bh, checkcSkin.red, true)
        end
        local colour = enabled and checkcSkin.title or checkcSkin.dim
        dxDrawText(guiGetText(element), bx + 4, by, bx + bw - 2, by + bh,
                colour, 0.9 * sc, "default-bold", "center", "center", true, false, true)
end

addEventHandler("onClientRender", root, function()
        if not (isElement(checkcWindow) and guiGetVisible(checkcWindow)) then return end

        -- [user] The cursor is turned ONCE when the panel opens (the checkc:show
-- handler) and is NOT re-asserted here any more: forcing it back on every
-- frame meant M / /togglecursor did nothing - the panel re-showed it 60x a
-- second. It now hides on M like every other window, and the Close button
-- still only drops the cursor it turned on itself.

        local ox, oy = guiGetPosition(checkcWindow, false)
        local ow, oh = guiGetSize(checkcWindow, false)
        local sc = checkcScale

        -- flat near-black panel
        dxDrawRectangle(ox, oy, ow, oh, checkcSkin.bg, true)

        -- header strip with the centred white title
        local headerH = CHECKC_HEADER_H * sc
        dxDrawRectangle(ox, oy, ow, headerH, checkcSkin.header, true)
        dxDrawText("Character Info", ox, oy, ox + ow, oy + headerH,
                checkcSkin.title, sc, "default-bold", "center", "center", true, false, true)

        -- tab row: only the single page we have ("Info"), active = white bold
        -- + red underline
        local tabY = oy + headerH
        local tabH = CHECKC_TAB_H * sc
        dxDrawText("Info", ox, tabY, ox + ow, tabY + tabH,
                checkcSkin.title, 0.95 * sc, "default-bold", "center", "center", false, false, true)
        local tabW = dxGetTextWidth("Info", 0.95 * sc, "default-bold")
        if tabW < 8 * sc then tabW = 8 * sc end
        dxDrawRectangle(ox + (ow - tabW) / 2, tabY + tabH - 3 * sc, tabW, 3 * sc, checkcSkin.red, true)

        -- red accent bar along the far left edge (over the header + tab row)
        dxDrawRectangle(ox, oy, 5 * sc, oh, checkcSkin.red, true)

        for i = 1, #checkcRows do
                local row = checkcRows[i]
                if row.right then
                        drawCheckcRow(ox, oy, sc, BULLET_R, COL_RX, COL_RW, row.y, row.right)
                        drawCheckcRow(ox, oy, sc, BULLET_L, COL_LX, COL_LW, row.y, row.left)
                else
                        drawCheckcRow(ox, oy, sc, BULLET_L, COL_LX, COL_FULLW, row.y, row.left)
                end
        end

        drawCheckcButton(ox, oy, sc, checkcClose)
end)
