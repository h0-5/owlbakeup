--[[ ------------------------------------------------------------------------
        /showalts + /findalts character list panel (dark UIKit window).

        Server side: Player/s_search.lua resolves the SEARCHED CHARACTER to
        the account that owns it and pushes every character of that account
        on the "showalts:show" event. This file renders those rows the way a
        command output is meant to look on this server - the dark window the
        /checkc panel and the F1 main menu belong to: red accent bullet
        header, red column headers, one clean row per character, a Close
        button, and the gridlist scrollbar whenever the account holds more
        characters than the window can show (no extra scroll code - the
        UIKit gridlist already wheels + drags).

        UIKit is resolved lazily. While it is not running the rows fall back
        to the old chat list, so the command can never go silent again.
-------------------------------------------------------------------------- ]]

local eui
local sx, sy = guiGetScreenSize()

local WIN_W, WIN_H = 700, 470          -- content box (UIKit adds its title bar)
local ACCENT_HEX = "#FF4141"           -- red accent, color-coded text form
local GREEN_HEX = "#2ED573"            -- theme success, used for "(online)"
local ACCENT = tocolor(255, 65, 65)    -- red accent, element form (theme danger)
local GREY = tocolor(180, 180, 180, 255)

local win, grid, closeBtn
local watchRender                       -- forward declared: closePanel uses it
local watching = false
local cursorUp = false                  -- only give the cursor back if we took it

-- UIKit export calls go through pcall (a destroyed window makes its assert
-- throw); the closures are built once, not per frame / per click
local getVisible = function(element) return eui:uiGetVisible(element) end
local getBounds = function(element) return eui:uiGetAbsoluteBounds(element) end

local function ensureEui()
        if eui then return true end
        local ok, res = pcall(getResourceFromName, "UIKit")
        if not ok or not res or getResourceState(res) ~= "running" then return false end
        eui = exports.UIKit
        -- the panel accent follows the theme's danger colour when it exists
        local okColor, color = pcall(function() return eui:uiGetThemeColor("danger") end)
        if okColor and color then ACCENT = color end
        return true
end

local function stopWatch()
        if not watching then return end
        removeEventHandler("onClientRender", root, watchRender)
        watching = false
end

-- Close = destroy the window, stop the watch, hand the cursor back.
local function closePanel()
        stopWatch()
        if win and isElement(win) then destroyElement(win) end
        win, grid, closeBtn = nil, nil, nil
        if cursorUp then
                showCursor(false)
                cursorUp = false
        end
end

-- The window paints its own X and that X only HIDES the window (UIKit), so
-- watch it: a hidden window with the cursor still up would leave the player
-- unable to play. pcall keeps a dead UI.DB out of the render loop.
watchRender = function()
        if not (win and isElement(win)) or not eui then
                closePanel()
                return
        end
        local ok, visible = pcall(getVisible, win)
        if not ok or not visible then closePanel() end
end

-- The optional columns take a fixed slice of the row, the Character column
-- takes what is left, so the row always fills the window exactly (sum = 1).
local function buildColumns(data)
        local cols = {
                { key = "id",        en = "ID",         ar = "الرقم",    w = 0.07 },
                { key = "hours",     en = "Hours",      ar = "الساعات",  w = 0.09 },
                { key = "status",    en = "Status",     ar = "الحالة",   w = 0.14 },
        }
        if data.showFaction then
                cols[#cols + 1] = { key = "faction", en = "Faction", ar = "الفصيل", w = 0.16 }
        end
        cols[#cols + 1] = { key = "lastlogin", en = "Last login", ar = "آخر دخول",
                w = data.showFaction and 0.17 or 0.20 }
        if data.creation then
                cols[#cols + 1] = { key = "created", en = "Created", ar = "تاريخ الإنشاء", w = 0.12 }
        end

        local used = 0
        for _, col in ipairs(cols) do
                used = used + col.w
        end
        table.insert(cols, 1, { key = "name", en = "Character", ar = "الشخصية", w = 1 - used })
        return cols
end

-- one row per character; the column order must match buildColumns()
local function fillRows(data)
        local rows = type(data.rows) == "table" and data.rows or {}
        for _, r in ipairs(rows) do
                local row = eui:uiGridListAddRow(grid)
                local col = 1

                local name = tostring(r.name or "?")
                if r.online then
                        name = name .. "   " .. GREEN_HEX .. "• online"
                end
                eui:uiGridListSetItemText(grid, row, col, name)
                col = col + 1

                -- no "#" here: a 6 digit id would be eaten as a colour code
                eui:uiGridListSetItemText(grid, row, col, tostring(r.id or "?"))
                eui:uiGridListSetItemColor(grid, row, col, ACCENT)
                col = col + 1

                eui:uiGridListSetItemText(grid, row, col, tostring(r.hours or 0))
                col = col + 1

                local status = tostring(r.status or "-")
                eui:uiGridListSetItemText(grid, row, col, status)
                if status ~= "Alive" then
                        eui:uiGridListSetItemColor(grid, row, col, ACCENT)
                end
                col = col + 1

                if data.showFaction then
                        local faction = r.faction
                        eui:uiGridListSetItemText(grid, row, col,
                                (faction and faction ~= "") and faction or "-")
                        col = col + 1
                end

                eui:uiGridListSetItemText(grid, row, col, tostring(r.lastlogin or "-"))
                eui:uiGridListSetItemColor(grid, row, col, GREY)
                col = col + 1

                if data.creation then
                        eui:uiGridListSetItemText(grid, row, col, tostring(r.created or "-"))
                        eui:uiGridListSetItemColor(grid, row, col, GREY)
                end
        end
        return #rows
end

-- the red bullet header, the F1 main-menu line style ("bullet » value")
local function buildHeader(data, count)
        local account = tostring(data.account or "?")
        local en = ACCENT_HEX .. "•  Account »  #FFFFFF" .. account
                .. "  #FFFFFF(id: " .. tostring(data.accountID or "?") .. ")"
                .. "      " .. ACCENT_HEX .. "Characters »  #FFFFFF" .. tostring(count)
        local ar = ACCENT_HEX .. "•  الحساب »  #FFFFFF" .. account
                .. "  #FFFFFF(id: " .. tostring(data.accountID or "?") .. ")"
                .. "      " .. ACCENT_HEX .. "عدد الشخصيات »  #FFFFFF" .. tostring(count)
        if tonumber(data.appstate) and tonumber(data.appstate) < 3 then
                en = en .. "      " .. ACCENT_HEX .. "(application not passed)"
                ar = ar .. "      " .. ACCENT_HEX .. "(لم يجتز الحساب التقديم)"
        end
        return { en = en, ar = ar }
end

local function buildPanel(data)
        closePanel() -- one panel at a time
        if not ensureEui() then return false end

        win = eui:uiCreateWindow((sx - WIN_W) / 2, (sy - WIN_H) / 2, WIN_W, WIN_H,
                { en = "Account Characters", ar = "شخصيات الحساب" })
        eui:uiBringToFront(win)
        -- the accent bar of the title strip follows the panel accent
        eui:uiSetProperty(win, "topline_color", ACCENT)

        local rows = type(data.rows) == "table" and data.rows or {}
        eui:uiCreateLabel(16, 46, WIN_W - 32, 24, buildHeader(data, #rows),
                ACCENT, "left", "center", win)

        grid = eui:uiCreateGridList(12, 78, WIN_W - 24, WIN_H - 134,
                tocolor(0, 0, 0, 0), win)
        eui:uiSetProperty(grid, "row_height", 26)
        eui:uiSetProperty(grid, "color_coded", true)

        for _, col in ipairs(buildColumns(data)) do
                local index = eui:uiGridListAddColumn(grid, { en = col.en, ar = col.ar }, col.w)
                eui:uiGridListSetColumnColor(grid, index, ACCENT)
        end
        fillRows(data)

        closeBtn = eui:uiCreateButton(WIN_W - 130, WIN_H - 46, 115, 30,
                { en = "Close", ar = "إغلاق" }, tocolor(10, 10, 10, 240), win)
        -- UIKit's default button TextColor is theme black (invisible on the
        -- dark button), same fix the staff panel needs
        eui:uiSetProperty(closeBtn, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(closeBtn, "HoverTextColor", tocolor(255, 80, 80))

        showCursor(true)
        cursorUp = true
        if not watching then
                addEventHandler("onClientRender", root, watchRender)
                watching = true
        end
        return true
end

-- no UIKit -> the old chat list, so the command still answers
local function chatFallback(data)
        outputChatBox("WHOIS " .. tostring(data.account or "?") .. " (#"
                .. tostring(data.accountID or "?") .. "):", localPlayer, 255, 194, 14)
        local rows = type(data.rows) == "table" and data.rows or {}
        for index, r in ipairs(rows) do
                local text = "#" .. index .. ": " .. tostring(r.name or "?")
                        .. " (char #" .. tostring(r.id or "?") .. ")"
                if r.hours then text = text .. " - " .. tostring(r.hours) .. " hours" end
                if r.status then text = text .. " - " .. tostring(r.status) end
                if r.lastlogin then text = text .. " - " .. tostring(r.lastlogin) end
                -- the old colour rule: online = green, offline = yellow
                outputChatBox(text, localPlayer, r.online and 0 or 255, 255, 0)
        end
end

-- raw hit-test on top of onClientUIClick: the UIKit click pipeline is not
-- reliably alive on every client (the same workaround the scoreboard's
-- /checkid panel needed), so Close must work either way
addEventHandler("onClientClick", root, function(button, state, ax, ay)
        if button ~= "left" or state ~= "up" then return end
        if not (win and isElement(win) and closeBtn and isElement(closeBtn)) then return end
        local ok, x, y, w, h = pcall(getBounds, closeBtn)
        if not ok or not x then return end
        if ax >= x and ax <= x + (w or 0) and ay >= y and ay <= y + (h or 0) then
                closePanel()
        end
end)

-- the same button through the UIKit click event, when that pipeline runs
addEventHandler("onClientUIClick", root, function()
        if closeBtn and source == closeBtn then closePanel() end
end)

addEvent("showalts:show", true)
addEventHandler("showalts:show", root, function(data)
        if type(data) ~= "table" then return end
        if not ensureEui() then
                chatFallback(data)
                return
        end
        buildPanel(data)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        closePanel()
end)
