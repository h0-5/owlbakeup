-- [Fix #160] A5 - /checkc client character-info panel (age/job)
-- Owned exclusively by the matching Fix #160 task agent.
--
-- Raw MTA GUI in the same shape as admin-system/c_check.lua ("Player Check"):
-- one small window, one label grid, one Close button. The command itself is
-- SERVER-side (Player/s_checkc.lua, right admin.checkc); this file only
-- renders the table the server sends on "checkc:show".
--
-- Skin: image-4 style flat dark panel. MTA can not recolour the default
-- window chrome, so the whole panel (near-black bg, red left accent bar,
-- centred white title, bullet rows, dark Close button) is drawn with dx AFTER
-- the GUI (postGUI = true) while the window is open. The gui labels below are
-- kept as the data store - the skin reads them back with guiGetText(), so
-- every setText() in the "checkc:show" handler keeps working untouched.

local checkcWindow = nil
local checkcClose = nil
local checkcLabels = {}
local checkcCursorOwned = false

local function buildCheckcWindow()
        if checkcWindow and isElement(checkcWindow) then return end
        local width, height = guiGetScreenSize()
        checkcWindow = guiCreateWindow(width - 440, 0, 430, 420, "Character Info", false)
        guiWindowSetSizable(checkcWindow, false)

        checkcLabels = {
                name     = guiCreateLabel(15, 45, 400, 22, "Name: N/A", false, checkcWindow),
                account  = guiCreateLabel(15, 71, 400, 22, "Account: N/A", false, checkcWindow),
                status   = guiCreateLabel(15, 97, 400, 22, "Status: N/A", false, checkcWindow),
                age      = guiCreateLabel(15, 123, 205, 22, "Age: N/A", false, checkcWindow),
                birthday = guiCreateLabel(225, 123, 205, 22, "Birthday: N/A", false, checkcWindow),
                gender   = guiCreateLabel(15, 149, 205, 22, "Gender: N/A", false, checkcWindow),
                body     = guiCreateLabel(225, 149, 205, 22, "Height/Weight: N/A", false, checkcWindow),
                job      = guiCreateLabel(15, 175, 400, 22, "Job: N/A", false, checkcWindow),
                faction  = guiCreateLabel(15, 201, 400, 22, "Faction: N/A", false, checkcWindow),
                hours    = guiCreateLabel(15, 227, 205, 22, "Hours played: N/A", false, checkcWindow),
                deaths   = guiCreateLabel(225, 227, 205, 22, "Deaths: N/A", false, checkcWindow),
                money    = guiCreateLabel(15, 253, 205, 22, "Cash: N/A", false, checkcWindow),
                bank     = guiCreateLabel(225, 253, 205, 22, "Bank: N/A", false, checkcWindow),
                area     = guiCreateLabel(15, 279, 400, 44, "Area: N/A", false, checkcWindow),
        }

        checkcClose = guiCreateButton(155, 376, 120, 30, "Close", false, checkcWindow)
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
-- image-4 style dark skin (dx drawn AFTER the gui, so it covers the default
-- window chrome, the default labels and the default button look)
-- ---------------------------------------------------------------------------
local checkcSkin = {
        bg       = tocolor(14, 14, 16, 255),
        line     = tocolor(38, 38, 44, 255),
        red      = tocolor(226, 59, 59, 255),
        title    = tocolor(255, 255, 255, 255),
        key      = tocolor(255, 255, 255, 255),
        value    = tocolor(200, 200, 206, 255),
        accent   = tocolor(255, 92, 92, 255),
        btn      = tocolor(24, 24, 28, 255),
        btnHover = tocolor(48, 48, 56, 255),
        dim      = tocolor(120, 120, 126, 255),
}

-- two column row grid (y positions inside the 430x420 window)
local checkcRows = {
        { y = 50,  left = "name" },
        { y = 80,  left = "account" },
        { y = 110, left = "status" },
        { y = 144, left = "age",    right = "birthday" },
        { y = 174, left = "gender", right = "body" },
        { y = 204, left = "job" },
        { y = 234, left = "faction" },
        { y = 264, left = "hours",  right = "deaths" },
        { y = 294, left = "money",  right = "bank" },
        { y = 324, left = "area" },
}
local checkcAccent = { money = true, bank = true, hours = true, deaths = true }

local COL_LX, COL_LW = 28, 196      -- left column text
local COL_RX, COL_RW = 244, 170     -- right column text
local COL_FULLX, COL_FULLW = 28, 386
local BULLET_L, BULLET_R = 18, 234

local function checkcMouseOver(x, y, w, h)
        local cx, cy = getCursorPosition()
        if not cx then return false end
        local sx, sy = guiGetScreenSize()
        cx, cy = cx * sx, cy * sy
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function drawCheckcRow(ox, oy, bx, tx, tw, y, key)
        local element = checkcLabels[key]
        if not isElement(element) then return end
        local text = guiGetText(element)
        if not text or text == "" then return end

        dxDrawRectangle(ox + bx, oy + y + 5, 6, 2, checkcSkin.red, true)

        local label, value = string.match(text, "^(.-):%s*(.*)$")
        if not label or label == "" then
                dxDrawText(text, ox + tx, oy + y, ox + tx + tw, oy + y + 15,
                        checkcSkin.key, 0.9, "default", "left", "top", true, false, true)
                return
        end

        dxDrawText(label .. ":", ox + tx, oy + y, ox + tx + tw, oy + y + 15,
                checkcSkin.key, 0.9, "default-bold", "left", "top", true, false, true)
        if value ~= "" then
                local colour = checkcAccent[key] and checkcSkin.accent or checkcSkin.value
                local kw = dxGetTextWidth(label .. ": ", 0.9, "default-bold")
                dxDrawText(value, ox + tx + kw, oy + y, ox + tx + tw, oy + y + 15,
                        colour, 0.9, "default", "left", "top", true, false, true)
        end
end

local function drawCheckcButton(ox, oy, element)
        if not isElement(element) then return end
        local bx, by = guiGetPosition(element, false)
        local bw, bh = guiGetSize(element, false)
        bx, by = ox + bx, oy + by

        local enabled = guiGetEnabled(element)
        local hover = enabled and checkcMouseOver(bx, by, bw, bh)
        local bg = checkcSkin.btn
        if hover then bg = checkcSkin.btnHover end
        dxDrawRectangle(bx, by, bw, bh, bg, true)
        if hover then
                dxDrawRectangle(bx, by, 2, bh, checkcSkin.red, true)
        end
        local colour = enabled and checkcSkin.title or checkcSkin.dim
        dxDrawText(guiGetText(element), bx + 4, by, bx + bw - 2, by + bh,
                colour, 0.9, "default-bold", "center", "center", true, false, true)
end

addEventHandler("onClientRender", root, function()
        if not (isElement(checkcWindow) and guiGetVisible(checkcWindow)) then return end

        -- the panel is open: the cursor must stay on (nametags rely on it)
        if not isCursorShowing() then
                showCursor(true)
                checkcCursorOwned = true
        end

        local ox, oy = guiGetPosition(checkcWindow, false)
        local ow, oh = guiGetSize(checkcWindow, false)

        -- flat near-black panel
        dxDrawRectangle(ox, oy, ow, oh, checkcSkin.bg, true)
        -- red accent bar along the far left edge + centred white title
        dxDrawRectangle(ox, oy, 4, oh, checkcSkin.red, true)
        dxDrawText("Character Info", ox + 4, oy + 6, ox + ow, oy + 32,
                checkcSkin.title, 1, "default-bold", "center", "center", false, false, true)
        dxDrawRectangle(ox + 16, oy + 36, ow - 32, 1, checkcSkin.line, true)

        for i = 1, #checkcRows do
                local row = checkcRows[i]
                if row.right then
                        drawCheckcRow(ox, oy, BULLET_L, COL_LX, COL_LW, row.y, row.left)
                        drawCheckcRow(ox, oy, BULLET_R, COL_RX, COL_RW, row.y, row.right)
                else
                        drawCheckcRow(ox, oy, BULLET_L, COL_FULLX, COL_FULLW, row.y, row.left)
                end
        end

        drawCheckcButton(ox, oy, checkcClose)
end)
