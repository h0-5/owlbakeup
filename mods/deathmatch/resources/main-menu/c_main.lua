--[[
        Vortex Main Menu (F1) — mod #1 of the Vortex restore
        Logic port: 1:1 from the original client "main-menu" resource.
        Design: Vortex theme (blue/purple from the logo), rounded corners,
                emoji sidebar icons, sidebar menu spanning the full panel height.

        Original layout (all values are uiGetReferenceScreenSize() * X):
          window         0.75 x 0.65 ref, centered
          sidebar menu   full inner height, rows distributed evenly
          content panel  right of the sidebar
          sections (id -> tab panel) exactly as the original:
            character_info -> [Info, Vehicles, Interiors]
            onlinestaff    -> [Admins Team, Supports Team]
            linkdiscord    -> [notlinked, linked]
            leaderboard    -> [Levels, Activities]
            about          -> [discord, factions, gangs, youtube, store]

        Exports that do not exist on this server are replaced:
          exports.roleplay.getCharacter()  -> element data on localPlayer
          exports.roleplay:isPlayerOnline  -> scoreboard player list
          exports.UIKit                    -> plain dx calls
]]

local sw, sh = guiGetScreenSize()

--[[ ================= theme ================= ]]

local C = {
        bg       = tocolor(3, 6, 11, 242),      -- window
        sidebar  = tocolor(19, 22, 27, 215),    -- sidebar panel
        card     = tocolor(9, 12, 17, 195),     -- content panel
        rowBg    = tocolor(19, 22, 27, 150),    -- content rows
        hover    = tocolor(255, 255, 255, 14),  -- generic hover
        white    = tocolor(255, 255, 255, 255),
        white70  = tocolor(255, 255, 255, 190),
        white50  = tocolor(255, 255, 255, 130),
        white30  = tocolor(255, 255, 255, 80),
        veil     = tocolor(0, 0, 0, 150),       -- dark veil over the game
        green    = tocolor(46, 213, 115)
}
local function primary(a)   return tocolor(94, 76, 252, a or 255) end    -- #5E4CFC
local function secondary(a) return tocolor(144, 50, 250, a or 255) end  -- #9032FA

local fontLarge, fontUI, fontSmall, fontEmoji
fontLarge = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", 24) or "default-bold"
fontUI    = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", 19) or "default"
fontSmall = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", 16) or "default"
-- colored emoji glyphs (Segoe UI Emoji ships with every Windows 8+ client)
fontEmoji = dxCreateFont("C:/Windows/Fonts/seguiemj.ttf", 20) or false

local logoTex = dxCreateTexture("logo-circle.png", "argb", true, "clamp")

--[[ ================= rounded corners =================
        White rounded textures tinted at draw time by the dxDrawImage color
        argument; 9-slice so the corner radius stays constant at any size. ]]

local texLg = dxCreateTexture("images/rounded_lg.png", "argb", true, "clamp")
local texSm = dxCreateTexture("images/rounded_sm.png", "argb", true, "clamp")

local function drawRounded(x, y, w, h, color, tex, src, slice)
        if not tex or w <= 0 or h <= 0 then return end
        if w < slice * 2 or h < slice * 2 then
                -- element too small for 9 slices: stretch the whole texture instead
                dxDrawImage(x, y, w, h, tex, 0, 0, 0, color, true)
                return
        end
        local mid = src - slice * 2
        -- corners
        dxDrawImageSection(x, y, slice, slice, 0, 0, slice, slice, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x + w - slice, y, slice, slice, src - slice, 0, slice, slice, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x, y + h - slice, slice, slice, 0, src - slice, slice, slice, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x + w - slice, y + h - slice, slice, slice, src - slice, src - slice, slice, slice, tex, 0, 0, 0, color, true)
        -- edges
        dxDrawImageSection(x + slice, y, w - slice * 2, slice, slice, 0, mid, slice, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x + slice, y + h - slice, w - slice * 2, slice, slice, src - slice, mid, slice, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x, y + slice, slice, h - slice * 2, 0, slice, slice, mid, tex, 0, 0, 0, color, true)
        dxDrawImageSection(x + w - slice, y + slice, slice, h - slice * 2, src - slice, slice, slice, mid, tex, 0, 0, 0, color, true)
        -- center
        dxDrawImageSection(x + slice, y + slice, w - slice * 2, h - slice * 2, slice, slice, mid, mid, tex, 0, 0, 0, color, true)
end

local function roundLg(x, y, w, h, color) drawRounded(x, y, w, h, color, texLg, 256, 48) end
local function roundSm(x, y, w, h, color) drawRounded(x, y, w, h, color, texSm, 96, 16) end

--[[ ================= layout constants ================= ]]

local REF = math.min(sw / 1.7778, sh)
local R = function(v) return v * REF end

local WIN = { w = R(0.75), h = R(0.65) }
local PAD = 14
local MENU_W = 230
local HEADER_H = 78
local TAB_H = 44

--[[ ================= state ================= ]]

local state = {
        open = false,
        section = "character_info",
        tab = 1,
        hoverMenu = -1,
        hoverTab = -1,
        hoverRow = -1,
        scroll = 0
}

--[[ ================= data providers =================
        exports.roleplay.getCharacter() does not exist here, so the same values are
        read from the element data that account/s_characters.lua sets. ]]

local COUNTRIES = { [1] = "USA", [2] = "Saudi Arabia", [3] = "Egypt", [4] = "UAE", [5] = "Kuwait" }
local GENDERS = { [0] = "Male", [1] = "Female", [2] = "Male", [3] = "Female" }

-- 1234567 -> "1,234,567"
local function convertNumber(value)
        local n = tonumber(value) or 0
        local formatted = tostring(math.floor(n))
        local out = formatted
        while true do
                local newOut, replaced = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
                out = newOut
                if replaced == 0 then break end
        end
        return out
end

local function getCharData()
        local p = localPlayer
        local gender = tonumber(getElementData(p, "gender")) or 0
        local country = tonumber(getElementData(p, "country")) or 0
        local month = tonumber(getElementData(p, "month")) or 1
        local day = tonumber(getElementData(p, "day")) or 1
        local age = tonumber(getElementData(p, "age")) or 18
        return {
                ID          = tonumber(getElementData(p, "account:character:id")) or tonumber(getElementData(p, "dbid")) or 0,
                Name        = tostring(getPlayerName(p)):gsub("_", " "),
                Account     = tostring(getElementData(p, "account:username") or "N/A"),
                Gender      = GENDERS[gender] or GENDERS[gender % 2] or "Male",
                BirthDate   = string.format("%02d/%02d", day, month),
                Age         = age,
                Month       = month,
                Day         = day,
                FingerPrint = getElementData(p, "fingerprint") or "0000000000",
                Height      = tonumber(getElementData(p, "height")) or 180,
                Weight      = tonumber(getElementData(p, "weight")) or 75,
                Country     = COUNTRIES[country] or "Unknown",
                Job         = getElementData(p, "job") or "Unemployed",
                Faction     = tonumber(getElementData(p, "faction")) or 0,
                FactionRank = tonumber(getElementData(p, "factionrank")) or 0,
                Level       = tonumber(getElementData(p, "level")) or 1,
                Exp         = tonumber(getElementData(p, "exp")) or 0,
                ExpMax      = tonumber(getElementData(p, "expmax")) or 10000,
                Balance     = convertNumber(getElementData(p, "money") or 0),
                BankAccount = convertNumber(getElementData(p, "bank") or 0),
                Bank        = tonumber(getElementData(p, "bank")) or 0,
                Health      = tonumber(getElementData(p, "health")) or 100,
                PlayTime    = tonumber(getElementData(p, "timeinserver")) or 0
        }
end

-- short form used by the leaderboard (the scoreboard style: 3h 12m)
local function convertTimeToString(seconds)
        seconds = tonumber(seconds) or 0
        if math.floor(seconds / 86400) == 0 then
                if math.floor(seconds % 86400 / 3600) == 0 then
                        return math.floor(seconds % 86400 % 3600 / 60) .. "m " .. math.floor(seconds % 60) .. "s"
                end
                return math.floor(seconds % 86400 / 3600) .. "h " .. math.floor(seconds % 86400 % 3600 / 60) .. "m"
        end
        return math.floor(seconds % 86400 / 3600) + math.floor(seconds / 86400) * 24 .. "h "
                .. math.floor(seconds % 86400 % 3600 / 60) .. "m"
end

--[[ ================= server data cache =================
        Ownership in the database is a character id, not a player element, so the
        client cannot match it locally. Everything is requested from s_main.lua,
        which joins on the real character id. ]]

local cache = {
        vehicles    = {},
        interiors   = {},
        staff       = { admins = {}, supports = {} },
        leaderboard = { levels = {}, activities = {} },
        discord     = { linked = false, code = "", tag = "" }
}

local function requestAll()
        triggerServerEvent("main-menu:requestVehicles", localPlayer)
        triggerServerEvent("main-menu:requestInteriors", localPlayer)
        triggerServerEvent("main-menu:requestStaff", localPlayer)
        triggerServerEvent("main-menu:requestLeaderboard", localPlayer)
        triggerServerEvent("main-menu:requestDiscord", localPlayer)
end

addEvent("main-menu:vehicles:callback", true)
addEventHandler("main-menu:vehicles:callback", root, function(list)
        cache.vehicles = type(list) == "table" and list or {}
        state.scroll = 0
end)

addEvent("main-menu:interiors:callback", true)
addEventHandler("main-menu:interiors:callback", root, function(list)
        cache.interiors = type(list) == "table" and list or {}
        state.scroll = 0
end)

addEvent("main-menu:staff:callback", true)
addEventHandler("main-menu:staff:callback", root, function(payload)
        if type(payload) == "table" then
                cache.staff = {
                        admins   = payload.admins or {},
                        supports = payload.supports or {}
                }
        end
end)

addEvent("main-menu:leaderboard:callback", true)
addEventHandler("main-menu:leaderboard:callback", root, function(payload)
        if type(payload) == "table" then
                cache.leaderboard = {
                        levels     = payload.levels or {},
                        activities = payload.activities or {}
                }
        end
end)

addEvent("main-menu:discord:callback", true)
addEventHandler("main-menu:discord:callback", root, function(payload)
        if type(payload) == "table" then
                cache.discord = {
                        linked = payload.linked and true or false,
                        code   = tostring(payload.code or ""),
                        tag    = tostring(payload.tag or "")
                }
        end
end)

--[[ ================= draw helpers ================= ]]

local function isMouseIn(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        if not cx then return false end
        return cx * sw >= x and cx * sw <= x + w and cy * sh >= y and cy * sh <= y + h
end

local function text(str, x1, y1, x2, y2, color, scale, font, ax, ay)
        dxDrawText(tostring(str), x1, y1, x2, y2, color, scale or 1, font or fontUI,
                ax or "left", ay or "center", false, false, true)
end

--[[ ================= section content ================= ]]

-- returns a list of rows, each row = { title, value, color }
local function buildRows()
        local d = getCharData()
        local admins, supports = cache.staff.admins, cache.staff.supports

        if state.section == "character_info" then
                if state.tab == 1 then
                        return {
                                { "Personal ID", tostring(d.ID), C.white },
                                { "Name", d.Name, C.white },
                                { "Gender", d.Gender or "-", C.white },
                                { "Date of Birth", d.BirthDate, C.white },
                                { "Age", d.Age .. " years old", C.white },
                                { "Fingerprints", d.FingerPrint, C.white },
                                { "Country", d.Country, C.white },
                                { "Career", d.Job, C.white },
                                { "Balance", "$" .. d.Balance, C.green },
                                { "Bank Account", d.BankAccount, C.white }
                        }
                elseif state.tab == 2 then
                        local rows, vehicles = {}, cache.vehicles
                        if #vehicles == 0 then
                                table.insert(rows, { "title", "You do not own any vehicle", C.white50 })
                        end
                        for _, v in ipairs(vehicles) do
                                table.insert(rows, { "title", ("%s  |  %s  |  Fuel: %d%%  |  Odo: %d km%s"):format(
                                        v.name, v.plate, v.fuel, v.odo, v.impounded and "  |  Impounded" or ""), C.white })
                        end
                        return rows
                elseif state.tab == 3 then
                        local rows, interiors = {}, cache.interiors
                        if #interiors == 0 then
                                table.insert(rows, { "title", "You do not own any interior", C.white50 })
                        end
                        for _, i in ipairs(interiors) do
                                table.insert(rows, { "title", ("%s  |  %s"):format(i.name, i.status), C.white })
                        end
                        return rows
                end

        elseif state.section == "onlinestaff" then
                local src = (state.tab == 1) and admins or supports
                if #src == 0 then
                        return { { "title", "Nobody online", C.white50 } }
                end
                local rows = {}
                for _, p in ipairs(src) do
                        table.insert(rows, { "title", ("%s  —  %s  (%d ms)"):format(p.name, p.title, p.ping), C.white })
                end
                return rows

        elseif state.section == "linkdiscord" then
                if state.tab == 1 then
                        return { { "title", "Your Discord is not linked", C.white50 } }
                end
                return { { "title", "Your Discord is linked", C.green } }

        elseif state.section == "leaderboard" then
                local list = state.tab == 1 and cache.leaderboard.levels or cache.leaderboard.activities
                if #list == 0 then
                        return { { "title", "No data yet", C.white50 } }
                end
                local rows = {}
                for _, e in ipairs(list) do
                        table.insert(rows, {
                                "title",
                                ("#%d  %s  —  %s"):format(e.id, e.name,
                                        state.tab == 1 and (e.value .. " lvl") or convertTimeToString(e.value)),
                                C.white
                        })
                end
                return rows

        elseif state.section == "about" then
                local names = { "discord", "factions", "gangs", "youtube", "store" }
                local urls = {
                        "discord.gg/pdz",
                        "Type /factions in chat",
                        "Type /gangs in chat",
                        "Type /youtube in chat",
                        "Type /store in chat"
                }
                local rows = {}
                for i = 1, #names do
                        table.insert(rows, { "title", ("%s  —  %s"):format(names[i]:upper(), urls[i]), C.white })
                end
                return rows
        end
        return {}
end

--[[ ================= sections ================= ]]

-- the original sidebar order, with Vortex emoji icons
local SECTIONS = {
        { "character_info", "Personal Info", "👤" },
        { "onlinestaff",    "Online Staff",  "🛡" },
        { "leaderboard",    "Leaderboard",   "🏆" },
        { "linkdiscord",    "Link Discord",  "💬" },
        { "about",          "About Server",  "🌐" }
}

local TABS = {
        character_info = { "Info", "Vehicles", "Interiors" },
        onlinestaff    = { "Admins Team", "Supports Team" },
        linkdiscord    = { "notlinked", "linked" },
        leaderboard    = { "Levels", "Activities" },
        about          = { "discord", "factions", "gangs", "youtube", "store" }
}

-- every coordinate is relative to the centered window, computed in one place
-- so the draw pass and the hover pass can never drift apart
local function layout()
        local wx, wy = (sw - WIN.w) / 2, (sh - WIN.h) / 2
        local mx, my, mw, mh = wx + PAD, wy + PAD, MENU_W, WIN.h - PAD * 2
        local px = mx + mw + 18
        local pw = wx + WIN.w - PAD - px
        local py, ph = wy + PAD, WIN.h - PAD * 2
        local tabs = TABS[state.section] or {}
        local tabW = (pw - 48 - 8 * (math.max(#tabs, 1) - 1)) / math.max(#tabs, 1)
        local listY = py + 62 + TAB_H + 14
        return {
                wx = wx, wy = wy, ww = WIN.w, wh = WIN.h,
                mx = mx, my = my, mw = mw, mh = mh,
                px = px, py = py, pw = pw, ph = ph,
                tabY = py + 62, tabH = TAB_H, tabW = tabW,
                listY = listY, rowH = 34, listH = py + ph - listY - 16,
                menuListY = my + HEADER_H, menuRowH = (mh - HEADER_H) / 5
        }
end

local function getSectionTitle(id)
        for _, s in ipairs(SECTIONS) do
                if s[1] == id then return s[2] end
        end
        return ""
end

--[[ ================= rendering ================= ]]

local updateHover   -- forward declaration (assigned in the interaction block)

local function drawMenu(L)
        -- sidebar: full inner height of the window
        roundLg(L.mx, L.my, L.mw, L.mh, C.sidebar)

        -- header: vortex logo + name
        if logoTex then
                local s = 40
                dxDrawImage(L.mx + (L.mw - s) / 2, L.my + 12, s, s, logoTex, 0, 0, 0, C.white, true)
        end
        text("VORTEX", L.mx, L.my + 54, L.mx + L.mw, L.my + HEADER_H - 2, C.white, 1.0, fontLarge, "center", "center")

        -- menu rows distributed over the full remaining height
        for i, sec in ipairs(SECTIONS) do
                local y = L.menuListY + (i - 1) * L.menuRowH
                local inset, vpad = 10, 11
                local ry, rh = y + vpad / 2, L.menuRowH - vpad
                local selected = (state.section == sec[1])
                local hovered = (state.hoverMenu == i) and not selected

                if selected then
                        roundSm(L.mx + inset, ry, L.mw - inset * 2, rh, primary(235))
                elseif hovered then
                        roundSm(L.mx + inset, ry, L.mw - inset * 2, rh, C.hover)
                end

                local tx = L.mx + inset + 18
                if fontEmoji then
                        text(sec[3], tx, ry, tx + 40, ry + rh,
                                selected and C.white or C.white50, 1.0, fontEmoji, "left", "center")
                        tx = tx + 44
                end
                text(sec[2], tx, ry, L.mx + L.mw - inset - 8, ry + rh,
                        selected and C.white or (hovered and C.white or C.white70),
                        1.0, selected and fontLarge or fontUI, "left", "center")
        end
end

local function drawPanel(L)
        roundLg(L.px, L.py, L.pw, L.ph, C.card)

        -- section title
        text(getSectionTitle(state.section), L.px + 24, L.py + 8, L.px + L.pw - 24, L.py + 54,
                C.white, 1.1, fontLarge, "left", "center")

        -- tab pills
        local tabs = TABS[state.section] or {}
        for i = 1, #tabs do
                local x = L.px + 24 + (i - 1) * (L.tabW + 8)
                local selected = (state.tab == i)
                local hovered = (state.hoverTab == i) and not selected
                if selected then
                        roundSm(x, L.tabY, L.tabW, L.tabH, primary(225))
                elseif hovered then
                        roundSm(x, L.tabY, L.tabW, L.tabH, C.hover)
                end
                text(tabs[i], x, L.tabY, x + L.tabW, L.tabY + L.tabH,
                        selected and C.white or C.white50, 1.0, selected and fontUI or fontSmall, "center", "center")
        end

        -- content rows
        local rows = buildRows()
        local visible = math.floor(L.listH / L.rowH)
        local maxScroll = math.max(0, #rows - visible)
        if state.scroll > maxScroll then state.scroll = maxScroll end

        for i = state.scroll + 1, math.min(#rows, state.scroll + visible) do
                local row = rows[i]
                local y = L.listY + (i - state.scroll - 1) * L.rowH
                local hovered = (state.hoverRow == i)
                local rw = L.pw - 24
                local rh = L.rowH - 6

                roundSm(L.px + 12, y + 1, rw, rh, hovered and C.hover or C.rowBg)
                -- accent pill on the left edge
                roundSm(L.px + 16, y + 7, 4, rh - 12, row[1] == "title" and primary() or C.white30)

                if row[1] == "title" then
                        text(row[2], L.px + 30, y + 1, L.px + L.pw - 24, y + L.rowH - 5, row[3], 1, fontUI, "left", "center")
                else
                        -- key on the right, value on the left
                        text(row[1], L.px + L.pw - 214, y + 1, L.px + L.pw - 34, y + L.rowH - 5,
                                C.white50, 1, fontUI, "right", "center")
                        text(row[2], L.px + 30, y + 1, L.px + L.pw - 224, y + L.rowH - 5,
                                row[3], 1, fontUI, "left", "center")
                end
        end

        -- scrollbar
        if #rows > visible then
                local barH = math.max(30, L.listH * (visible / #rows))
                local maxY = L.listY + L.listH - barH
                local barY = L.listY + (maxY - L.listY) * (maxScroll > 0 and (state.scroll / maxScroll) or 0)
                roundSm(L.px + L.pw - 10, L.listY, 4, L.listH, C.white30)
                roundSm(L.px + L.pw - 10, barY, 4, barH, primary(215))
                state.scrollBar = { x = L.px + L.pw - 14, y = L.listY, w = 12, h = L.listH, barY = barY, barH = barH }
        end
end

local function onRender()
        if not state.open then return end

        -- the original ran the hover pass first, then painted
        updateHover()

        -- dark veil over the game
        dxDrawRectangle(0, 0, sw, sh, C.veil, false)

        local L = layout()
        roundLg(L.wx, L.wy, L.ww, L.wh, C.bg)

        drawMenu(L)
        drawPanel(L)
end

--[[ ================= interaction ================= ]]

-- NOTE: assigned (not `local function`) on purpose. A `local function` here
-- would declare a second local that shadows the forward declaration above,
-- leaving onRender() calling nil and throwing on every frame.
updateHover = function()
        state.hoverMenu, state.hoverTab, state.hoverRow = -1, -1, -1
        if not isCursorShowing() then return end
        local cx, cy = getCursorPosition()
        if not cx then return end
        cx, cy = cx * sw, cy * sh
        local L = layout()

        -- sidebar
        if cx >= L.mx and cx <= L.mx + L.mw and cy >= L.menuListY and cy <= L.my + L.mh then
                state.hoverMenu = math.min(5, math.floor((cy - L.menuListY) / L.menuRowH) + 1)
                return
        end

        -- tabs
        local tabs = TABS[state.section] or {}
        if cx >= L.px + 24 and cx <= L.px + L.pw - 24 and cy >= L.tabY and cy <= L.tabY + L.tabH and #tabs > 0 then
                state.hoverTab = math.min(#tabs, math.floor((cx - (L.px + 24)) / (L.tabW + 8)) + 1)
                return
        end

        -- rows
        local rows = buildRows()
        local visible = math.floor(L.listH / L.rowH)
        if cx >= L.px + 12 and cx <= L.px + L.pw - 12 and cy >= L.listY and cy <= L.listY + L.listH then
                local idx = state.scroll + math.floor((cy - L.listY) / L.rowH) + 1
                if idx >= 1 and idx <= #rows and idx <= state.scroll + visible then
                        state.hoverRow = idx
                end
        end
end

local function onClick(button, press)
        if not state.open or press ~= "down" then return end
        updateHover()

        -- sidebar
        if state.hoverMenu ~= -1 then
                state.section = SECTIONS[state.hoverMenu][1]
                state.tab = 1
                state.scroll = 0
                return
        end

        -- tabs
        if state.hoverTab ~= -1 then
                state.tab = state.hoverTab
                state.scroll = 0
                return
        end

        -- about section: clicking a row opens the link
        if state.section == "about" and state.hoverRow ~= -1 and button == "left" then
                local targets = {
                        "https://discord.gg/pdz", "chat", "chat", "chat", "chat"
                }
                local t = targets[state.hoverRow]
                if t and t ~= "chat" then
                        triggerEvent("onClientVisitWebsite", root, t)
                end
        end
end

local function onWheel(pressed)
        if not state.open then return end
        local L = layout()
        local rows = buildRows()
        local visible = math.max(1, math.floor(L.listH / L.rowH))
        local maxScroll = math.max(0, #rows - visible)
        state.scroll = math.max(0, math.min(maxScroll, state.scroll + (pressed == "down" and 1 or -1)))
end

--[[ ================= open / close ================= ]]

local function setOpen(open)
        if state.open == open then return end
        state.open = open
        state.scroll = 0
        state.hoverRow = -1

        showCursor(open)
        if open then
                -- pull fresh data every time the menu opens, so a vehicle bought or an
                -- interior bought since the last open shows up immediately
                requestAll()
        end
end

-- warm the cache on login so the first F1 press is not empty
addEventHandler("onClientResourceStart", resourceRoot, function()
        setTimer(function()
                if isElement(localPlayer) then requestAll() end
        end, 2000, 1)
end)

bindKey("F1", "down", function()
        setOpen(not state.open)
end)

addEventHandler("onClientRender", root, onRender)
addEventHandler("onClientClick", root, onClick)
addEventHandler("onClientKey", root, function(key, press)
        if not state.open then return end
        if press == "down" and (key == "mouse_wheel_up" or key == "mouse_wheel_down") then
                onWheel(key == "mouse_wheel_down" and "down" or "up")
                cancelEvent()
        end
        if press == "down" and key == "escape" then
                setOpen(false)
                cancelEvent()
        end
end)

addEventHandler("onClientResourceStop", getResourceRootElement(getThisResource()), function()
        showCursor(false)
        for _, e in ipairs({ fontLarge, fontUI, fontSmall, fontEmoji, logoTex, texLg, texSm }) do
                if e and type(e) ~= "string" and isElement(e) then
                        destroyElement(e)
                end
        end
end)

-- exports used by other resources
function isOpen() return state.open end
function toggleMenu() setOpen(not state.open) end
