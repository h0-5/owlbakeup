--
-- scoreboard / c_tab.lua  (V8 - Vortex)
-- Redesigned to match the reference shot: centered search pill, top accent
-- strip, V logo, "N Players / أعلى تواجد" right block, charname (username)
-- names, live 21-rank ladder colors, "Xh Ym" playtime, dimmed rows.
--

local sw, sh = guiGetScreenSize()

-- design scale: the layout is authored for 1080p width, capped so it never
-- gets absurdly large on wider screens
local s = math.min(sw / 1080, 1.3)

--[[ ==================== board geometry ==================== ]]

local BOARD = { x = 0, y = 0, w = 0, h = 0 }
local HEADER_H, COL_H, ROW_H, PAD_X, ROWS_TOP, ROWS_BOTTOM, CONTENT_W
local CORNER, STRIP_H

local function computeBoard()
        BOARD.w = 920 * s
        BOARD.h = math.min(math.max(sh - 230 * s, 420 * s), 600 * s)
        BOARD.x = (sw - BOARD.w) / 2
        BOARD.y = (sh - BOARD.h) / 2
        HEADER_H = 78 * s
        COL_H = 30 * s
        ROW_H = 28 * s
        PAD_X = 18 * s
        CORNER = 12 * s
        STRIP_H = math.max(3, math.floor(3 * s))
        ROWS_TOP = BOARD.y + HEADER_H + COL_H + 4 * s
        ROWS_BOTTOM = BOARD.y + BOARD.h - 12 * s
        CONTENT_W = BOARD.w - PAD_X * 2
end

computeBoard()

addEventHandler("onClientDisplayResolutionChange", root, computeBoard)

-- rounded rectangle built from thin horizontal slices whose width follows
-- the circle equation. Uses dxDrawRectangle only, so the corners connect
-- smoothly with no gaps, regardless of MTA's circle implementation.
local function drawRoundRect(x, y, w, h, color, postGUI, radius)
        if not x or not y or not w or not h then return end
        local r = math.min(radius or CORNER, h / 2, w / 2)
        if r < 2 then
                dxDrawRectangle(x, y, w, h, color, postGUI)
                return
        end
        local sqrt = math.sqrt
        -- straight middle band
        dxDrawRectangle(x, y + r, w, h - 2 * r, color, postGUI)
        -- slices across the two rounded ends
        local step = math.max(1, r / 24)
        for i = 0, r - 1, step do
                local dxh = sqrt(r * r - (r - i) * (r - i)) -- half-width allowed at this row
                local sw = w - 2 * (r - dxh)
                local th = step + 0.75 -- slight overlap to avoid hairline gaps
                local sx = x + r - dxh
                dxDrawRectangle(sx, y + i, sw, th, color, postGUI)
                dxDrawRectangle(sx, y + h - i - th, sw, th, color, postGUI)
        end
end

--[[ ==================== columns (fractions of CONTENT_W) ==================== ]]

local COLUMNS = {
        { name = "ID",       frac = 0.075 },
        { name = "",         frac = 0.070 }, -- badge icons
        { name = "Name",     frac = 0.395 },
        { name = "Rank",     frac = 0.210 },
        { name = "Playtime", frac = 0.160 },
        { name = "Ping",     frac = 0.090 },
}

--[[ ==================== theme / fonts / textures ==================== ]]

local ACCENT = { 56, 116, 255 }   -- the reference board's blue
local function accent(a) return tocolor(ACCENT[1], ACCENT[2], ACCENT[3], a or 255) end

local fontTitle, fontCol, fontRow
local fontAR, fontARB -- built-ins: they carry Arabic glyphs (PFDin does not)
local badgeTex = {}
local groupTex, logoTex, searchTex

local BADGE_NAMES = { "premium", "booster", "classic", "gold_member", "verified", "youtuber" }

local function loadAssets()
        local base = math.min(BOARD.h / 600, 1.15)
        fontTitle = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", math.floor(20 * base)) or "default-bold"
        fontCol = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", math.floor(12 * base)) or "default-bold"
        fontRow = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", math.floor(13 * base)) or "default"
        fontAR = "default"
        fontARB = "default-bold"
        for _, name in ipairs(BADGE_NAMES) do
                badgeTex[name] = dxCreateTexture("icons/" .. name .. ".png", "dxt5", true, "clamp")
        end
        groupTex = dxCreateTexture("group.png", "argb", true, "clamp")
        logoTex = dxCreateTexture("logo.png", "argb", true, "clamp") -- the white VV mark
        searchTex = dxCreateTexture("search.png", "argb", true, "clamp")
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        loadAssets()
end)

--[[ ==================== 21-rank Vortex ladder ==================== ]]

local LADDER = {
        [1]  = "Tester",                [12] = "Administrative Director",
        [2]  = "Trial Support",         [13] = "Junior Management",
        [3]  = "Support",               [14] = "Senior Management",
        [4]  = "Trial Moderator",       [15] = "Server Management",
        [5]  = "Moderator",             [16] = "Head Management",
        [6]  = "Senior Moderator",      [17] = "Chief Management",
        [7]  = "Trial Administrator",   [18] = "Vice Founder",
        [8]  = "Administrator",         [19] = "Founder",
        [9]  = "Senior Administrator",  [20] = "Diverloper",
        [10] = "Super Administrator",   [21] = "Owner",
        [11] = "Lead Administrator",
}

-- mirrors the colors seeded into staff_roles by staff_manager_s.lua, used
-- only when the live rank:color elementData has not arrived yet
local LADDER_COLOR = {
        ["Tester"]                  = { 255, 140,   0 },
        ["Trial Support"]           = { 255, 140,   0 },
        ["Support"]                 = { 255, 140,   0 },
        ["Trial Moderator"]         = { 204,  85,   0 },
        ["Moderator"]               = { 204,  85,   0 },
        ["Senior Moderator"]        = { 204,  85,   0 },
        ["Trial Administrator"]     = { 102, 178, 255 },
        ["Administrator"]           = {  52, 152, 219 },
        ["Senior Administrator"]    = {  32, 112, 178 },
        ["Super Administrator"]     = {  16,  72, 130 },
        ["Lead Administrator"]      = { 144,  50, 250 },
        ["Administrative Director"] = { 255, 215,   0 },
        ["Junior Management"]       = { 160, 101,  54 },
        ["Senior Management"]       = { 255, 105, 180 },
        ["Server Management"]       = { 199,  84, 124 },
        ["Head Management"]         = { 128,   0,  32 },
        ["Chief Management"]        = { 120,   0,  10 },
        ["Vice Founder"]            = { 170,   0,   0 },
        ["Founder"]                 = { 220,   0,   0 },
        ["Diverloper"]              = {   0, 120, 255 },
        ["Owner"]                   = { 255,   0,   0 },
}

local RANK_TITLES = { -- legacy numeric ladder (old column, 1..6)
        [1] = "Trial Admin", [2] = "Admin", [3] = "Senior Admin",
        [4] = "Lead Admin", [5] = "Head Admin", [6] = "Owner",
}

--[[ ==================== state ==================== ]]

local state = false
local cursorOn = false
local scroll = 0
local players = {}       -- sorted list of { element, id }
local countText = "0 Players"
local maxOnline = 0

-- search
local searchOn = false
local searchBuf = ""
local searchBox = { x = 0, y = 0, w = 0, h = 0 }
local searchEdit -- real CEGUI edit, invisible, used only to capture input

-- per-player cached data (color, badges, rank, name, dim)
local cache = {}

addEvent("scoreboard:highestPlayerCount:sync", true)
addEventHandler("scoreboard:highestPlayerCount:sync", root, function(value)
        maxOnline = tonumber(value) or 0
end)

--[[ ==================== helpers ==================== ]]

local function clickInRect(x, y, w, h)
        local cx, cy = getCursorPosition()
        if not cx then return false end
        cx, cy = cx * sw, cy * sh
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function pingColor(ping)
        ping = tonumber(ping) or 0
        if ping > 150 then return tocolor(235, 80, 80, 255) end
        if ping > 80 then return tocolor(240, 190, 60, 255) end
        return tocolor(120, 205, 130, 255)
end

local function isHidden(p)
        return tonumber(getElementData(p, "hiddenadmin")) == 1
end

-- [Vortex duty/permission fixes] duty_admin / duty_supporter are server-set
-- elementData (login panel + /adminduty), rank:index is the 21-rank ladder
-- pushed by the staff bridge — these are the real authority, not cosmetic.

local PLAIN_COLOR = tocolor(235, 240, 246, 255) -- off-duty / hidden rows

local function isStaff(p)
        return tonumber(getElementData(p, "rank:index")) ~= nil
end

local function isOnDuty(p)
        return tonumber(getElementData(p, "duty_admin")) == 1
           or tonumber(getElementData(p, "duty_supporter")) == 1
end

-- a staff member currently off duty (regular players are never "off duty",
-- they simply hold no rank)
local function isStaffOffDuty(p)
        if not isStaff(p) then return false end
        return not isOnDuty(p)
end

-- real permission gate: only Trial Administrator+ (rank:index >= 7) may see
-- account names next to character names on the board
local function canSeeAccounts()
        local idx = tonumber(getElementData(localPlayer, "rank:index"))
        return idx ~= nil and idx >= 7
end

-- the display name: "Charname (Username)" exactly like the reference shot;
-- players still at the login/character screen read "Selecting character ..."
-- [Vortex] the account part is a real permission: only Trial Administrator+
-- viewers may see it, and off-duty staff read as plain players (no account)
local function getDisplayName(p, id)
        if isHidden(p) then return "Hidden" end
        if tonumber(getElementData(p, "loggedin")) ~= 1 then
                return "Selecting character ... (" .. tostring(id) .. ")"
        end
        local name = getElementData(p, "fakename")
        if not name or name == "" or name == false then
                name = getPlayerName(p)
        end
        name = tostring(name):gsub("_", " ")
        if canSeeAccounts() and not isStaffOffDuty(p) then
                local user = getElementData(p, "account:username")
                if user and user ~= "" then
                        return name .. " (" .. tostring(user) .. ")"
                end
        end
        return name
end

local function getRank(p)
        -- [Vortex] hidden admins read as regular players: no rank at all
        if isHidden(p) then return "-" end
        -- [Vortex] off-duty staff keep their title, only the color drops to
        -- plain white (handled in getRankColor)
        -- the 21-rank ladder is THE source: rank:name is pushed by the
        -- staff bridge at login and re-applied by the scoreboard server poll.
        local rn = getElementData(p, "rank:name")
        if type(rn) == "string" and rn ~= "" then return rn end
        -- rank:index without a name -> resolve through the local ladder copy
        local idx = tonumber(getElementData(p, "rank:index"))
        if idx and LADDER[idx] then return LADDER[idx] end
        -- the old numeric column sometimes holds the NEW ladder index straight
        -- (that is where the infamous "Admin 21" came from) - show the real title
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level >= 5 and level <= 21 and level ~= 10 then
                return LADDER[level] or ("Admin " .. level)
        end
        if level > 0 then
                return RANK_TITLES[level] or ("Admin " .. level)
        end
        local g = getResourceFromName("global")
        if g and getResourceState(g) == "running" then
                local ok, res = pcall(function() return exports.global:getPlayerAdminTitle(p) end)
                if ok and type(res) == "string" and res ~= "" and res ~= "Player" then
                        return res
                end
        end
        local integ = getResourceFromName("integration")
        if integ and getResourceState(integ) == "running" then
                local okSup, isSup = pcall(function() return exports.integration:isPlayerSupporter(p) end)
                if okSup and isSup then return "Support" end
                local okSm, isSm = pcall(function() return exports.integration:isPlayerSupportManager(p) end)
                if okSm and isSm then return "Support Manager" end
                local okVct, isVct = pcall(function() return exports.integration:isPlayerVCTMember(p) end)
                if okVct and isVct then return "VCT Member" end
                local okSc, isSc = pcall(function() return exports.integration:isPlayerScripter(p) end)
                if okSc and isSc then return "Scripter" end
        end
        return "-" -- regular players show a dash, like the reference
end

-- [Fix #14] readability floor: dark rank colors (navy/maroon) vanished on
-- the dark board - the user read this as "the name disappears"
local function clampSB(c)
        local r = tonumber(c[1]) or 255
        local g = tonumber(c[2]) or 255
        local b = tonumber(c[3]) or 255
        local lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        if lum < 0.45 then
                local t = (0.45 - lum) / math.max(1 - lum, 0.001)
                r = math.floor(r + (255 - r) * t + 0.5)
                g = math.floor(g + (255 - g) * t + 0.5)
                b = math.floor(b + (255 - b) * t + 0.5)
        end
        return r, g, b
end

local function getRankColor(p, rankName)
        -- [Vortex] hidden AND off-duty staff read as plain players: the whole
        -- row goes white. Hidden also drops the rank title (see getRank).
        if isHidden(p) or isStaffOffDuty(p) then return PLAIN_COLOR end
        -- the rank's own panel color wins over everything
        local rc = getElementData(p, "rank:color")
        if type(rc) == "table" and rc[1] then
                local r, g, b = clampSB(rc)
                return tocolor(r, g, b, 255)
        end
        -- fall back to the seeded ladder palette for the resolved title
        local lc = LADDER_COLOR[rankName]
        if lc then
                local r, g, b = clampSB(lc)
                return tocolor(r, g, b, 255)
        end
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level >= 21 then return tocolor(255, 0, 0, 255) end
        if level >= 19 then return tocolor(220, 0, 0, 255) end
        if level >= 17 then return tocolor(120, 0, 10, 255) end
        if level >= 11 then return tocolor(144, 50, 250, 255) end
        if level >= 7 then return tocolor(102, 178, 255, 255) end
        if level >= 4 then return tocolor(204, 85, 0, 255) end
        if level >= 2 then return tocolor(255, 140, 0, 255) end
        return tocolor(235, 240, 246, 255)
end

local function getBadges(p)
        local icons = {}
        -- [Vortex] hidden / off-duty staff show no badges - they read as plain
        if isHidden(p) or isStaffOffDuty(p) then return icons end
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level >= 21 then
                table.insert(icons, "premium")
        elseif level >= 11 then
                table.insert(icons, "booster")
        elseif level >= 4 then
                table.insert(icons, "classic")
        end
        local integ = getResourceFromName("integration")
        if integ and getResourceState(integ) == "running" then
                local okScripter, isScripter = pcall(function() return exports.integration:isPlayerScripter(p) end)
                if okScripter and isScripter then
                        table.insert(icons, "verified")
                end
                local okVct, isVct = pcall(function() return exports.integration:isPlayerVCTMember(p) end)
                if okVct and isVct then
                        table.insert(icons, "gold_member")
                end
        end
        if getElementData(p, "donation:nametag") == true then
                table.insert(icons, "youtuber")
        end
        return icons
end

-- playtime "Xh Ym": hoursplayed bumps once an hour on the wall-clock payday,
-- so the live minute hand is simply the current minute of the hour
local function getPlaytime(p)
        if tonumber(getElementData(p, "loggedin")) ~= 1 then return "0h 00m" end
        local hours = tonumber(getElementData(p, "hoursplayed")) or 0
        local totalMin = hours * 60 + getRealTime().minute
        return string.format("%dh %02dm", math.floor(totalMin / 60), totalMin % 60)
end

local function refreshPlayer(p)
        if not isElement(p) then return end
        local rank = getRank(p)
        cache[p] = {
                rank = rank,
                color = getRankColor(p, rank),
                badges = getBadges(p),
                dim = (tonumber(getElementData(p, "loggedin")) ~= 1) and 0.42
                        or (getElementData(p, "afk") == true and 0.62 or 1),
        }
end

--[[ ==================== player list ==================== ]]

local function updatePlayers()
        local all = getElementsByType("player")
        local list = {}
        for _, p in ipairs(all) do
                if isElement(p) then
                        local pid = tonumber(getElementData(p, "playerid")) or 999999
                        table.insert(list, { element = p, id = pid })
                end
        end
        table.sort(list, function(a, b) return a.id < b.id end)
        players = list
        local n = #list
        countText = n .. " Player" .. (n == 1 and "" or "s")
        if n > maxOnline then maxOnline = n end
        for _, entry in ipairs(list) do
                refreshPlayer(entry.element)
        end
end

addEventHandler("onClientPlayerJoin", root, function()
        if state then updatePlayers() end
end)

addEventHandler("onClientPlayerQuit", root, function()
        cache[source] = nil
        if state then updatePlayers() end
end)

-- refresh cached colors/ranks every 2 seconds while open
setTimer(function()
        if not state then return end
        for _, entry in ipairs(players) do
                refreshPlayer(entry.element)
        end
end, 2000, 0)

--[[ ==================== search ==================== ]]

local function filteredList()
        if not searchOn or searchBuf == "" then
                return players
        end
        local out = {}
        local needle = string.lower(searchBuf)
        for _, p in ipairs(players) do
                local c = cache[p.element]
                local name = getDisplayName(p.element, p.id)
                local hay = string.lower(name .. " " .. tostring(p.id) .. " " .. (c and c.rank or ""))
                if string.find(hay, needle, 1, true) then
                        table.insert(out, p)
                end
        end
        return out
end

addEventHandler("onClientClick", root, function(button, buttonState)
        if not state or button ~= "left" or buttonState ~= "down" then return end
        if clickInRect(searchBox.x, searchBox.y, searchBox.w, searchBox.h) then
                searchOn = true
                if searchEdit then
                        guiSetVisible(searchEdit, true)
                        guiBringToFront(searchEdit)
                        guiSetFocused(searchEdit, true)
                end
                if not cursorOn then
                        cursorOn = true
                        showCursor(true)
                end
        elseif searchOn then
                searchOn = false
                if searchEdit then guiSetVisible(searchEdit, false) end
        end
end)

-- real input handling lives inside the invisible CEGUI edit;
-- we just mirror its text so our custom drawing stays in sync
addEventHandler("onClientGUIChanged", root, function()
        if not searchOn or source ~= searchEdit then return end
        searchBuf = guiGetText(searchEdit) or ""
        scroll = 0
end)

--[[ ==================== cell data ==================== ]]

local function cellData(colName, p, c, id)
        if colName == "ID" then
                return tostring(id), c.color
        elseif colName == "" then
                return nil, c.color, c.badges
        elseif colName == "Name" then
                return getDisplayName(p, id), c.color
        elseif colName == "Rank" then
                return c.rank, c.color
        elseif colName == "Playtime" then
                return getPlaytime(p), tocolor(178, 187, 205, 235)
        elseif colName == "Ping" then
                return tostring(getPlayerPing(p) or 0), pingColor(getPlayerPing(p))
        end
        return "-", c.color
end

--[[ ==================== drawing ==================== ]]

local function drawScrollbar()
        local visibleRows = math.floor((ROWS_BOTTOM - ROWS_TOP) / ROW_H)
        local total = #filteredList()
        if total <= visibleRows then return end
        local trackH = ROWS_BOTTOM - ROWS_TOP
        local trackX = BOARD.x + BOARD.w - PAD_X / 2 - 3 * s
        local thumbH = math.max(trackH * visibleRows / total, 24 * s)
        local maxScroll = total - visibleRows
        local thumbY = ROWS_TOP + (scroll / maxScroll) * (trackH - thumbH)
        dxDrawRectangle(trackX, ROWS_TOP, 4 * s, trackH, tocolor(255, 255, 255, 16), true)
        drawRoundRect(trackX, thumbY, 4 * s, thumbH, accent(230), true, 2 * s)
end

-- hover animation: text whitens and shifts forward on the hovered row
local hoverRow = -1
local hoverAnim = 0
local lastTick = getTickCount()

local function drawHeader()
        -- top accent strip, spanning the full board width like the reference
        drawRoundRect(BOARD.x, BOARD.y, BOARD.w, STRIP_H + 4 * s, accent(255), true, STRIP_H)

        -- VV logo, top left
        local logoSize = 40 * s
        if logoTex then
                dxDrawImage(BOARD.x + PAD_X, BOARD.y + (HEADER_H - logoSize) / 2 + 2 * s,
                        logoSize, logoSize, logoTex, 0, 0, 0, tocolor(255, 255, 255, 255), true)
        end

        -- centered search pill ("بحث...")
        searchBox.w = 320 * s
        searchBox.h = 32 * s
        searchBox.x = BOARD.x + (BOARD.w - searchBox.w) / 2
        searchBox.y = BOARD.y + (HEADER_H - searchBox.h) / 2 + 2 * s
        if searchEdit then
                guiSetPosition(searchEdit, searchBox.x + 30 * s, searchBox.y, false)
                guiSetSize(searchEdit, searchBox.w - 40 * s, searchBox.h, false)
        end
        drawRoundRect(searchBox.x, searchBox.y, searchBox.w, searchBox.h, tocolor(21, 25, 36, 255), true, searchBox.h / 2)
        if searchTex then
                dxDrawImage(searchBox.x + 12 * s, searchBox.y + (searchBox.h - 14 * s) / 2, 14 * s, 14 * s,
                        searchTex, 0, 0, 0, tocolor(255, 255, 255, searchOn and 255 or 150), true)
        end
        local sLabel = searchBuf ~= "" and searchBuf or "بحث..."
        local sColor = searchBuf ~= "" and tocolor(255, 255, 255, 255) or tocolor(140, 148, 168, 255)
        dxDrawText(sLabel, searchBox.x + 32 * s, searchBox.y,
                searchBox.x + searchBox.w - 14 * s, searchBox.y + searchBox.h,
                sColor, 1, fontAR, "left", "center", true, false, true)
        if searchOn and math.floor(getRealTime().timestamp / 0.5) % 2 == 0 then
                local tw = dxGetTextWidth(searchBuf, 1, fontAR)
                dxDrawRectangle(searchBox.x + 32 * s + tw + 2, searchBox.y + 8 * s, 1, searchBox.h - 16 * s,
                        tocolor(255, 255, 255, 255), true)
        end

        -- right block: "N Players" + icon, then the peak line "أعلى تواجد: N"
        local rightEdge = BOARD.x + BOARD.w - PAD_X
        dxDrawText(countText, BOARD.x + BOARD.w * 0.55, BOARD.y + 8 * s,
                rightEdge - 24 * s, BOARD.y + 34 * s,
                tocolor(235, 240, 248, 245), 1, fontCol, "right", "center", true, false, true)
        if groupTex then
                dxDrawImage(rightEdge - 18 * s, BOARD.y + 13 * s, 15 * s, 15 * s,
                        groupTex, 0, 0, 0, tocolor(255, 255, 255, 230), true)
        end
        dxDrawText("أعلى تواجد: " .. tostring(maxOnline), BOARD.x + BOARD.w * 0.55, BOARD.y + 36 * s,
                rightEdge - 12 * s, BOARD.y + 62 * s,
                tocolor(158, 167, 188, 240), 1, fontAR, "right", "center", true, false, true)
end

local function drawBoard()
        local list = filteredList()

        -- board body: dark rounded fill with a hairline outer border
        local bw = 1 * s
        drawRoundRect(BOARD.x - bw, BOARD.y - bw, BOARD.w + 2 * bw, BOARD.h + 2 * bw, tocolor(255, 255, 255, 14), true)
        drawRoundRect(BOARD.x, BOARD.y, BOARD.w, BOARD.h, tocolor(9, 11, 17, 246), true)

        drawHeader()

        -- column header row
        local colY = BOARD.y + HEADER_H
        local cx = BOARD.x + PAD_X
        for _, col in ipairs(COLUMNS) do
                local cw = col.frac * CONTENT_W
                if col.name ~= "" then
                        dxDrawText(col.name, cx, colY, cx + cw - 4 * s, colY + COL_H,
                                tocolor(128, 138, 162, 235), 1, fontCol, "left", "center", true, false, true)
                end
                cx = cx + cw
        end
        dxDrawRectangle(BOARD.x + PAD_X, colY + COL_H, BOARD.w - PAD_X * 2, 1, tocolor(255, 255, 255, 22), true)

        -- player rows
        local visibleRows = math.floor((ROWS_BOTTOM - ROWS_TOP) / ROW_H)
        local maxScroll = math.max(0, #list - visibleRows)
        if scroll > maxScroll then scroll = maxScroll end
        if scroll < 0 then scroll = 0 end

        hoverRow = -1
        for i = 1, visibleRows do
                local idx = scroll + i
                local pData = list[idx]
                if not pData then break end
                local p = pData.element
                if isElement(p) then
                        local rowY = ROWS_TOP + (i - 1) * ROW_H
                        local isLocal = (p == localPlayer)
                        local rowX = BOARD.x + PAD_X / 2
                        local rowW = BOARD.w - PAD_X

                        -- hover tracking
                        if clickInRect(rowX, rowY, rowW, ROW_H - 2) then
                                hoverRow = i
                        end

                        -- animation timer: advance the hover effect for this frame
                        local now = getTickCount()
                        local dt = (now - lastTick) / 1000
                        lastTick = now
                        if i == hoverRow then
                                hoverAnim = math.min(1, hoverAnim + dt * 8)
                        elseif hoverRow == -1 then
                                hoverAnim = math.max(0, hoverAnim - dt * 8)
                        end
                        local rowHover = (i == hoverRow) and hoverAnim or 0

                        -- row background: local player and hovered rows get the
                        -- lighter plate from the reference, plus a soft zebra
                        local bgAlpha = rowHover * 22
                        if isLocal then bgAlpha = math.max(bgAlpha, 12) end
                        if i % 2 == 0 then bgAlpha = bgAlpha + 5 end
                        if bgAlpha > 0.5 then
                                drawRoundRect(rowX, rowY, rowW, ROW_H - 2, tocolor(255, 255, 255, bgAlpha), true, 6 * s)
                        end

                        -- left accent bar: permanent on my row, slides in on hover
                        local barAlpha = 230 * (isLocal and 1 or rowHover)
                        if barAlpha > 4 then
                                drawRoundRect(rowX - 6 * s, rowY + 3 * s, 3 * s, ROW_H - 8 * s,
                                        accent(barAlpha), true, 1.5 * s)
                        end

                        local c = cache[p] or { color = tocolor(235, 240, 246, 255), badges = {}, rank = "-", dim = 1 }
                        local textShift = rowHover * 4 * s
                        local cellX = BOARD.x + PAD_X
                        for _, col in ipairs(COLUMNS) do
                                local cw = col.frac * CONTENT_W
                                local value, color, badges = cellData(col.name, p, c, pData.id)
                                if badges then
                                        for b = 1, #badges do
                                                local tex = badgeTex[badges[b]]
                                                if tex then
                                                        dxDrawImage(cellX + (b - 1) * 20 * s + textShift,
                                                                rowY + (ROW_H - 16 * s) / 2,
                                                                16 * s, 16 * s, tex, 0, 0, 0,
                                                                tocolor(255, 255, 255, 255 * (c.dim or 1)), true)
                                                end
                                        end
                                elseif value ~= nil then
                                        local r2 = bitExtract(color, 16, 8)
                                        local g2 = bitExtract(color, 8, 8)
                                        local b3 = bitExtract(color, 0, 8)
                                        local a3 = bitExtract(color, 24, 8) * (c.dim or 1)
                                        -- hover whitens the text, dimming fades the whole row
                                        local hc = tocolor(
                                                math.floor(r2 + (255 - r2) * rowHover),
                                                math.floor(g2 + (255 - g2) * rowHover),
                                                math.floor(b3 + (255 - b3) * rowHover),
                                                a3
                                        )
                                        dxDrawText(tostring(value), cellX + textShift, rowY,
                                                cellX + cw - 4 * s + textShift, rowY + ROW_H,
                                                hc, 1, fontRow, "left", "center", true, false, true)
                                end
                                cellX = cellX + cw
                        end

                        -- faint separator between rows
                        if rowY + ROW_H - 1 < ROWS_BOTTOM - 2 then
                                dxDrawRectangle(BOARD.x + PAD_X, rowY + ROW_H - 1, BOARD.w - PAD_X * 2, 1,
                                        tocolor(255, 255, 255, 12), true)
                        end
                end
        end

        drawScrollbar()
end

-- error-protected render entry point: reports the first draw error to chat
local drawErrorShown = false
local function render()
        local ok, err = pcall(drawBoard)
        if not ok and not drawErrorShown then
                drawErrorShown = true
                outputChatBox("[SB] draw error: " .. tostring(err), 255, 100, 100)
        end
end

--[[ ==================== show / hide ==================== ]]

local function toggleCursor()
        cursorOn = not cursorOn
        showCursor(cursorOn)
end

function onWheel(key)
        if not state then return end
        local visibleRows = math.floor((ROWS_BOTTOM - ROWS_TOP) / ROW_H)
        local maxScroll = math.max(0, #filteredList() - visibleRows)
        if key == "mouse_wheel_up" then
                scroll = math.max(0, scroll - 1)
        else
                scroll = math.min(maxScroll, scroll + 1)
        end
end

-- mouse wheel scrolling via onClientKey: this fires even while the cursor is
-- visible, unlike bindKey which the GUI can swallow
addEventHandler("onClientKey", root, function(key, press)
        if not state or press ~= "down" then return end
        if key == "mouse_wheel_up" or key == "mouse_wheel_down" then
                onWheel(key)
        end
end)

local function toggle(show)
        if show == state then return end
        state = show
        if show then
                updatePlayers()
                scroll = 0
                cursorOn = true
                showCursor(true)
                searchOn = false
                searchBuf = ""
                hoverRow = -1
                hoverAnim = 0
                lastTick = getTickCount()
                drawErrorShown = false
                -- transparent edit that captures keyboard input for the search box;
                -- no_binds_when_editing stops MTA binds (chat/movement) from firing
                -- while the player is typing a name
                if not searchEdit then
                        searchEdit = guiCreateEdit(0, 0, 1, 1, "", false)
                        if searchEdit then
                                guiSetAlpha(searchEdit, 0)
                                guiSetInputMode("no_binds_when_editing")
                        end
                else
                        guiSetText(searchEdit, "")
                end
                addEventHandler("onClientRender", root, render)
                bindKey("mouse2", "down", toggleCursor)
        else
                removeEventHandler("onClientRender", root, render)
                unbindKey("mouse2", "down", toggleCursor)
                if searchEdit then guiSetVisible(searchEdit, false) end
                if cursorOn then showCursor(false) end
                cursorOn = false
                searchOn = false
        end
end

bindKey("tab", "both", function(_, keyState)
        if keyState == "down" then
                toggle(true)
        elseif not cursorOn then
                toggle(false)
        end
end)

-- alternative trigger so the board can be opened even if TAB is hijacked
addCommandHandler("sb", function()
        toggle(not state)
end)

function isVisible()
        return state
end

--[[ test hook â€” harmless in production, lets the automated mock harness
     reach the otherwise file-local rank/color helpers ]]
function getScoreboardTestTable()
        return {
                getRank = getRank,
                getRankColor = getRankColor,
                getBadges = getBadges,
                getDisplayName = getDisplayName,
                getPlaytime = getPlaytime,
                LADDER = LADDER,
                LADDER_COLOR = LADDER_COLOR,
        }
end


