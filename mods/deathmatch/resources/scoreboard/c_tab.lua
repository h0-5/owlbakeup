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

-- Fix #29 (user): the board follows the Maqsad reference panel - periwinkle
-- accent (104,102,255) sampled from the reference shot, near-black indigo
-- body, blue column headers, whole-row coloring, collapse chevron and the
-- REAL server logo (vortex_logo.png) instead of the bare VV mark.
local ACCENT = { 104, 102, 255 }   -- the reference board's periwinkle
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
        logoTex = dxCreateTexture("vortex_logo.png", "argb", true, "clamp") -- the REAL server logo
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
-- [Fix #31 - user] the tab NO LONGER carries its own rank colors: every
-- color now comes from the STAFF SYSTEM (rank:color element data pushed by
-- staff_manager + the full staff_roles table pushed by s_tab.lua)
local rankColors = {}   -- [rankName] = {r,g,b} straight from staff_roles

addEvent("scoreboard:rankColors", true)
addEventHandler("scoreboard:rankColors", root, function(tbl)
        if type(tbl) == "table" then rankColors = tbl end
end)

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
local searchActive = false       -- a live UIKit search edit exists
local searchBuf = ""
local searchBox = { x = 0, y = 0, w = 0, h = 0 }
-- Fix #29: collapse chevron state (reference header button)
local collapsed = false
local chevronBox = { x = 0, y = 0, w = 0, h = 0 }

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
        -- [Fix #30] robust across type flips (DB string "1", number 1, boolean)
        local v = getElementData(p, "hiddenadmin")
        return v == true or v == "1" or tonumber(v) == 1
end

-- [Vortex duty/permission fixes] duty_admin / duty_supporter are server-set
-- elementData (login panel + /adminduty), rank:index is the 21-rank ladder
-- pushed by the staff bridge — these are the real authority, not cosmetic.

local PLAIN_COLOR = tocolor(235, 240, 246, 255) -- off-duty / hidden rows

local function isStaff(p)
        return tonumber(getElementData(p, "rank:index")) ~= nil
end

local function isOnDuty(p)
        -- [Fix #31 - user] the BADGE (شارة) state must survive every way the
        -- server stores it: number 1, DB string "1" or boolean true
        for _, key in ipairs({ "duty_admin", "duty_supporter" }) do
                local v = getElementData(p, key)
                if v == true or v == "1" or tonumber(v) == 1 then return true end
        end
        return false
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
        -- [Fix #32 - user] "خلي اسم شخصية لا تيغير": a hidden admin keeps
        -- showing their REAL character name (they read as a normal player) -
        -- the old "Hidden" placeholder is gone. Mask/fakename rules below
        -- still apply on top.
        -- Fix #24 (user): before a character is picked the board shows the
        -- ACCOUNT NAME (it is known at login), not a useless row number
        if tonumber(getElementData(p, "loggedin")) ~= 1 then
                local user = getElementData(p, "account:username")
                if user and user ~= "" then
                        return "Joining: " .. tostring(user)
                end
                return "Selecting character ..."
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
        -- Fix #29 (reference): donors read PURPLE, VCT/gold read CYAN-GREEN -
        -- whole-row colors like the Maqsad board's VIP rows
        if getElementData(p, "donation:nametag") == true then return tocolor(216, 112, 227, 255) end
        local integ0 = getResourceFromName("integration")
        if integ0 and getResourceState(integ0) == "running" then
                local okG, isG = pcall(function() return exports.integration:isPlayerVCTMember(p) end)
                if okG and isG then return tocolor(0, 243, 215, 255) end
        end
        -- [Fix #32 - user] "ما ابي لون رتبة يسوي مستطيل ... تطلع بلون مثل صورة":
        -- the RANK color must NOT flood the whole row (a colored band of text
        -- reads like a rectangle). The row stays plain; the rank color lives
        -- on the NAME and the RANK cell only (see cellData).
        return PLAIN_COLOR
end

-- Fix #29: the RANK COLUMN keeps the rank's own color even when the player
-- is off duty / plain (reference: the dimmed row still shows its orange
-- rank text). No donor/VIP override here.
function getRankColorRaw(p, rankName)
        -- [Fix #33 - user] "فعلت الهدن وضل لون اسم شخصية ذي ماهو": a HIDDEN
        -- admin must read as a plain player in the name + rank cells too -
        -- their rank:color was still leaking onto the name and giving them
        -- away. Plain white for hidden, exactly like off-duty staff.
        if isHidden(p) then return PLAIN_COLOR end
        -- [Fix #31 - user] color source = the STAFF SYSTEM only:
        --   1) the live per-member rank:color pushed by staff_manager
        --   2) the full staff_roles color table pushed by s_tab.lua
        -- The tab itself carries NO colors anymore.
        local rc = getElementData(p, "rank:color")
        if type(rc) == "table" and rc[1] then
                local r, g, b = clampSB(rc)
                return tocolor(r, g, b, 255)
        end
        local sc = rankColors[rankName]
        if type(sc) == "table" and sc[1] then
                local r, g, b = clampSB(sc)
                return tocolor(r, g, b, 255)
        end
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

-- playtime "Xh Ym": hoursplayed bumps once per payday hour and
-- timeinserver counts the minutes of the CURRENT pay hour (0..59).
-- Fix #24: the old code used the WALL-CLOCK minute, which resets every
-- hour and never matched real played time.
local function getPlaytime(p)
        if tonumber(getElementData(p, "loggedin")) ~= 1 then return "0m 0s" end
        local hours = tonumber(getElementData(p, "hoursplayed")) or 0
        local tis = tonumber(getElementData(p, "timeinserver")) or 0
        local totalMin = hours * 60 + math.min(tis, 59)
        return string.format("%dh %02dm", math.floor(totalMin / 60), totalMin % 60)
end

local function refreshPlayer(p)
        if not isElement(p) then return end
        local rank = getRank(p)
        cache[p] = {
                rank = rank,
                color = getRankColor(p, rank),
                rankColor = getRankColorRaw(p, rank),
                badges = getBadges(p),
                dim = (tonumber(getElementData(p, "loggedin")) ~= 1) and 0.42
                        or (getElementData(p, "afk") == true and 0.62
                        or (isStaffOffDuty(p) and 0.55 or 1)),
        }
end

--[[ ==================== player list ==================== ]]

local function updatePlayers()
        local all = getElementsByType("player")
        local list = {}
        for _, p in ipairs(all) do
                if isElement(p) then
                        -- Fix #24: prefer the account's FIXED mod id (assigned
                        -- at first creation, survives reconnects) over the
                        -- session playerid
                        local pid = tonumber(getElementData(p, "mod:id"))
                                or tonumber(getElementData(p, "playerid")) or 999999
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

-- [Fix #31 - user] badge on/off and rank/color edits apply INSTANTLY:
-- refresh the row cache the moment any watched value flips, so enabling
-- the badge colors the whole row on the same frame (not 2s later)
local WATCHED_KEYS = {
        ["duty_admin"] = true, ["duty_supporter"] = true,
        ["rank:color"] = true, ["rank:name"] = true, ["rank:index"] = true,
        ["loggedin"] = true, ["hiddenadmin"] = true,
        ["donation:nametag"] = true, ["account:username"] = true,
        ["fakename"] = true, ["afk"] = true, ["mod:id"] = true,
}
addEventHandler("onClientElementDataChange", root, function(key)
        if WATCHED_KEYS[key] and cache[source] then
                refreshPlayer(source)
        end
end)

--[[ ==================== search ==================== ]]

local function filteredList()
        if searchBuf == "" then
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
        -- Fix #29: collapse/expand chevron (reference header button)
        if clickInRect(chevronBox.x, chevronBox.y, chevronBox.w, chevronBox.h) then
                collapsed = not collapsed
                return
        end
        if clickInRect(searchBox.x, searchBox.y, searchBox.w, searchBox.h) then
                if not searchActive then createSearchEdit() end
                if not cursorOn then
                        cursorOn = true
                        showCursor(true)
                end
        end
end)

--[[ [Fix #31 - user] THE SEARCH = the old client's search, 1:1.

backupm score-board used a UIKit edit:
    search_edit = eui:uiCreateEdit(..., "", {en="Search...", ar="بحث..."}, ...)
    onClientUIChanged -> filterPlayersList(uiGetText(source))

Our previous build mirrored a hidden GUI-edit into dxDrawText: Arabic came
out mangled and backspace felt dead (user: "كاتبة البحث مليان اخطاء لا تقدر
تحذف"). The UIKit edit gives native typing, backspace, delete, caret and
the proper {en/ar} placeholder - same widget, same events as the old client.
]]
local eui            -- UIKit exports bridge
local searchUI       -- the ui-edit element (alive while the board is open)

local function ensureUIKit()
        if eui then return true end
        local u = getResourceFromName("UIKit")
        if not u or getResourceState(u) ~= "running" then return false end
        eui = exports.UIKit
        return true
end

function destroySearchEdit()
        if searchUI and isElement(searchUI) then
                destroyElement(searchUI)
        end
        searchUI = nil
        searchActive = false
        searchBuf = ""
        -- [Fix #35] the search edit may die while it holds keyboard focus -
        -- UIKit's blur never fires on destroy, so the MTA chat input would
        -- stay disarmed ("can't type in chat after using the tab search")
        toggleControl("chatbox", true)
end

function createSearchEdit()
        if not ensureUIKit() then return end
        destroySearchEdit()
        -- UIKit expects coordinates in its 1728x972 reference space
        local rx, ry = 1728 / sx, 972 / sy
        searchUI = eui:uiCreateEdit(
                (searchBox.x + 30 * s) * rx,
                (searchBox.y + 3 * s) * ry,
                (searchBox.w - 44 * s) * rx,
                (searchBox.h - 6 * s) * ry,
                "", { en = "Search...", ar = "بحث..." },
                tocolor(104, 102, 255), nil)
        eui:uiSetProperty(searchUI, "UnderLineVisible", "False")
        eui:uiSetFocusedElement(searchUI)
        searchActive = true
end

-- live filter (old client: onClientUIChanged -> filterPlayersList)
addEventHandler("onClientUIChanged", root, function()
        if searchUI and source == searchUI and eui then
                searchBuf = tostring(eui:uiGetText(searchUI) or "")
                scroll = 0
        end
end)

-- wheel + escape. [Fix #31] `press` is a BOOLEAN here - the old check
-- `press ~= "down"` was ALWAYS true, so wheel scrolling and the escape
-- cancel never ran at all (part of the reported "مشاكل")
addEventHandler("onClientKey", root, function(key, press)
        if not state or not press then return end
        if key == "mouse_wheel_up" or key == "mouse_wheel_down" then
                onWheel(key)
                return
        end
        if key == "escape" and searchActive then
                destroySearchEdit()
                cancelEvent()
        end
end)

--[[ ==================== cell data ==================== ]]

local function cellData(colName, p, c, id)
        if colName == "ID" then
                return tostring(id), c.color
        elseif colName == "" then
                return nil, c.color, c.badges
        elseif colName == "Name" then
                -- [Fix #32 - user] badge on = the NAME + the RANK cell carry the
                -- rank color; the rest of the row stays plain information
                return getDisplayName(p, id), c.rankColor or c.color
        elseif colName == "Rank" then
                -- Fix #29: rank column = the rank's OWN color (no whitening on
                -- hover, stays colored when off duty) like the reference
                return c.rank, c.rankColor or c.color, nil, true
        elseif colName == "Playtime" then
                -- Fix #29: playtime + ping follow the ROW color like the ref
                return getPlaytime(p), c.color
        elseif colName == "Ping" then
                return tostring(getPlayerPing(p) or 0), c.color
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
        drawRoundRect(searchBox.x - 1, searchBox.y - 1, searchBox.w + 2, searchBox.h + 2,
                tocolor(104, 102, 255, 70), true, (searchBox.h + 2) / 2)
        drawRoundRect(searchBox.x, searchBox.y, searchBox.w, searchBox.h, tocolor(30, 23, 43, 255), true, searchBox.h / 2)
        if searchTex then
                dxDrawImage(searchBox.x + 12 * s, searchBox.y + (searchBox.h - 14 * s) / 2, 14 * s, 14 * s,
                        searchTex, 0, 0, 0, tocolor(255, 255, 255, searchActive and 255 or 150), true)
        end
        -- [Fix #31] the text inside the pill is drawn by the UIKit edit
        -- itself (proper Arabic, native caret) - nothing to draw here

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

        -- Fix #29: collapse chevron (reference) - click to fold the rows away
        -- [Fix #32 - user] "سهم مفروض يكون عمودي جنب اعلى تواجد بس هو صاير تحت":
        -- the chevron sits BESIDE the "أعلى تواجد" line, not under it
        chevronBox.w = 22 * s
        chevronBox.h = 16 * s
        local peakText = "أعلى تواجد: " .. tostring(maxOnline)
        local peakW = (dxGetTextWidth(peakText, 1, fontAR) or 0)
        chevronBox.x = rightEdge - 12 * s - peakW - 10 * s - chevronBox.w
        chevronBox.y = BOARD.y + 41 * s
        local x0, y0 = chevronBox.x, chevronBox.y
        local cw2, ch2 = chevronBox.w, chevronBox.h
        local apexY = (not collapsed) and (y0 + 3 * s) or (y0 + ch2 - 3 * s)
        local baseY = (not collapsed) and (y0 + ch2 - 3 * s) or (y0 + 3 * s)
        dxDrawLine(x0, baseY, x0 + cw2 / 2, apexY, tocolor(191, 189, 195, 240), 1.6, true)
        dxDrawLine(x0 + cw2 / 2, apexY, x0 + cw2, baseY, tocolor(191, 189, 195, 240), 1.6, true)
end

local function drawBoard()
        local list = filteredList()

        -- board body: dark rounded fill with a hairline outer border
        -- Fix #29: near-black indigo fill + subtle navy border (reference)
        local bodyH = collapsed and (HEADER_H + 12 * s) or BOARD.h
        local bw = 1 * s
        drawRoundRect(BOARD.x - bw, BOARD.y - bw, BOARD.w + 2 * bw, bodyH + 2 * bw, tocolor(150, 150, 200, 26), true)
        drawRoundRect(BOARD.x, BOARD.y, BOARD.w, bodyH, tocolor(5, 3, 9, 247), true)

        drawHeader()

        -- Fix #29: collapsed mode = header only (chevron clicked)
        if not collapsed then
        -- column header row
        local colY = BOARD.y + HEADER_H
        local cx = BOARD.x + PAD_X
        for _, col in ipairs(COLUMNS) do
                local cw = col.frac * CONTENT_W
                if col.name ~= "" then
                        dxDrawText(col.name, cx, colY, cx + cw - 4 * s, colY + COL_H,
                                tocolor(98, 96, 241, 235), 1, fontCol, "left", "center", true, false, true)
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

                        -- row background: Fix #29 reference styling - clear zebra
                        -- rows, the local row keeps a soft light plate and the
                        -- hovered row goes DARKER with the accent bar
                        local bgA = isLocal and 12 or 0
                        if i % 2 == 0 then bgA = bgA + 9 end
                        if bgA > 0.5 then
                                drawRoundRect(rowX, rowY, rowW, ROW_H - 2, tocolor(255, 255, 255, bgA), true, 6 * s)
                        end
                        if rowHover > 0.01 then
                                drawRoundRect(rowX, rowY, rowW, ROW_H - 2, tocolor(0, 0, 0, 110 * rowHover), true, 6 * s)
                        end

                        -- left accent bar: permanent on my row, slides in on hover
                        local barAlpha = 230 * (isLocal and 1 or rowHover)
                        if barAlpha > 4 then
                                drawRoundRect(rowX - 6 * s, rowY + 3 * s, 3 * s, ROW_H - 8 * s,
                                        accent(barAlpha), true, 1.5 * s)
                        end

                        local c = cache[p] or { color = tocolor(235, 240, 246, 255), rankColor = tocolor(235, 240, 246, 255), badges = {}, rank = "-", dim = 1 }
                        local textShift = rowHover * 4 * s
                        local cellX = BOARD.x + PAD_X
                        for _, col in ipairs(COLUMNS) do
                                local cw = col.frac * CONTENT_W
                                -- [Fix #35 - user] "مستطيلات لحول اسم الرمادية ذي حول كل
                                -- معلومات مب بس اسم": the gray cell plate goes around
                                -- EVERY column now (ID / badges / Name / Rank /
                                -- Playtime / Ping), not just the name
                                drawRoundRect(cellX + 2 * s, rowY + 2 * s,
                                        cw - 5 * s, ROW_H - 7 * s,
                                        tocolor(150, 156, 170, 26), true, 4 * s)
                                local value, color, badges, noWhiten = cellData(col.name, p, c, pData.id)
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
                                        -- Fix #29: hover whitens normal cells; the rank
                                        -- column keeps its own color (noWhiten)
                                        local hc
                                        if noWhiten then
                                                hc = tocolor(r2, g2, b3, a3)
                                        else
                                                hc = tocolor(
                                                        math.floor(r2 + (255 - r2) * rowHover),
                                                        math.floor(g2 + (255 - g2) * rowHover),
                                                        math.floor(b3 + (255 - b3) * rowHover),
                                                        a3
                                                )
                                        end
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
        end -- not collapsed
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

-- mouse wheel scrolling is handled by the search/key handler above: it
-- fires even while the cursor is visible, unlike bindKey which the GUI
-- can swallow

local function toggle(show)
        if show == state then return end
        state = show
        if show then
                updatePlayers()
                scroll = 0
                cursorOn = true
                showCursor(true)
                searchActive = false
                searchBuf = ""
                hoverRow = -1
                hoverAnim = 0
                lastTick = getTickCount()
                drawErrorShown = false
                -- [Fix #31] the board renders in onClientPreRender (exactly
                -- like the old client) so the UIKit search edit - drawn in
                -- UIKit's onClientRender pass - lands ON TOP of the board
                addEventHandler("onClientPreRender", root, render)
                bindKey("mouse2", "down", toggleCursor)
        else
                removeEventHandler("onClientPreRender", root, render)
                unbindKey("mouse2", "down", toggleCursor)
                destroySearchEdit()
                if cursorOn then showCursor(false) end
                cursorOn = false
                searchActive = false
        end
end

-- Fix #24 (user): the board shows while TAB is HELD and disappears the
-- moment the finger lifts. It stays open only when the search box is
-- active (so searching still works); pressing TAB again or ESC closes it.
bindKey("tab", "both", function(_, keyState)
        if keyState == "down" then
                if state and searchActive then return end
                toggle(true)
        elseif state and not searchActive then
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
                isHidden = isHidden,
                isStaff = isStaff,
                isOnDuty = isOnDuty,
                isStaffOffDuty = isStaffOffDuty,
                canSeeAccounts = canSeeAccounts,
                getRankColorRaw = getRankColorRaw,
                LADDER = LADDER,
        }
end


