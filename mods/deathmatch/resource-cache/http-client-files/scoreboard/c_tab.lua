--
-- scoreboard / c_tab.lua
-- Modern scoreboard, ported from the OwlGaming "score-board" design.
--
-- Layout is computed from the screen size so it stays proportional on any
-- resolution. All sizes live in the BOARD table (see computeBoard).
--

local sw, sh = guiGetScreenSize()

-- design scale: the layout is authored for 1080p width, capped so it never
-- gets absurdly large on wider screens
local s = math.min(sw / 1080, 1.3)

--[[ ==================== board geometry ==================== ]]

local BOARD = { x = 0, y = 0, w = 0, h = 0 }
local HEADER_H, COL_H, ROW_H, PAD_X, ROWS_TOP, ROWS_BOTTOM, CONTENT_W
local CORNER

local function computeBoard()
        BOARD.w = 880 * s
        BOARD.h = math.min(math.max(sh - 240 * s, 400 * s), 560 * s)
        BOARD.x = (sw - BOARD.w) / 2
        BOARD.y = (sh - BOARD.h) / 2
        HEADER_H = 56 * s
        COL_H = 28 * s
        ROW_H = 26 * s
        PAD_X = 14 * s
	CORNER = 10 * s
        ROWS_TOP = BOARD.y + HEADER_H + COL_H + 4 * s
        ROWS_BOTTOM = BOARD.y + BOARD.h - 10 * s
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
        { name = "",         frac = 0.060 },
        { name = "Name",     frac = 0.420 },
        { name = "Rank",     frac = 0.200 },
        { name = "Playtime", frac = 0.150 },
        { name = "Ping",     frac = 0.095 },
}

--[[ ==================== theme / fonts / textures ==================== ]]

local function accent(a) return tocolor(0, 168, 255, a or 255) end

local fontTitle, fontCol, fontRow
local badgeTex = {}
local groupTex, logoTex, searchTex

local BADGE_NAMES = { "premium", "booster", "classic", "gold_member", "verified", "youtuber" }

local function loadAssets()
        local base = math.min(BOARD.h / 560, 1.15)
        fontTitle = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", math.floor(20 * base)) or "default-bold"
        fontCol = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", math.floor(13 * base)) or "default-bold"
        fontRow = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", math.floor(13 * base)) or "default"
        for _, name in ipairs(BADGE_NAMES) do
                badgeTex[name] = dxCreateTexture("icons/" .. name .. ".png", "dxt5", true, "clamp")
        end
        groupTex = dxCreateTexture("group.png", "argb", true, "clamp")
        logoTex = dxCreateTexture("logo-circle.png", "argb", true, "clamp")
        searchTex = dxCreateTexture("search.png", "argb", true, "clamp")
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        loadAssets()
        outputChatBox("[SB] scoreboard client loaded", 0, 255, 0)
end)

--[[ ==================== state ==================== ]]

local state = false
local cursorOn = false
local scroll = 0
local players = {}       -- sorted list of { element, id, name }
local countText = "0 Players"
local maxOnline = 0

-- search
local searchOn = false
local searchBuf = ""
local searchBox = { x = 0, y = 0, w = 0, h = 0 }
local searchEdit -- real CEGUI edit, invisible, used only to capture input

-- per-player cached data (colour, badges, rank)
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

local function formatTime(hours)
        hours = tonumber(hours) or 0
        if hours <= 0 then return "0h" end
        if hours < 24 then return string.format("%dh", math.floor(hours)) end
        local d = math.floor(hours / 24)
        local h = math.floor(hours % 24)
        return string.format("%dd %dh", d, h)
end

local function pingColor(ping)
        ping = tonumber(ping) or 0
        if ping > 150 then return tocolor(235, 80, 80, 255) end
        if ping > 80 then return tocolor(240, 190, 60, 255) end
        return tocolor(70, 200, 120, 255)
end

local RANK_TITLES = {
        [1] = "Trial Admin", [2] = "Admin", [3] = "Senior Admin",
        [4] = "Lead Admin", [5] = "Head Admin", [6] = "Owner",
        [10] = "Scripter",
}

local function adminColor(p)
        if getElementData(p, "hiddenadmin") == 1 then
                return tocolor(220, 226, 234, 255)
        end
        -- [Vortex] the rank's own panel color wins over the legacy ladder tint
        local rc = getElementData(p, "rank:color")
        if type(rc) == "table" and rc[1] then
                return tocolor(rc[1], rc[2], rc[3], 255)
        end
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level >= 6 then return tocolor(255, 80, 80, 255) end
        if level >= 4 then return tocolor(255, 150, 40, 255) end
        if level >= 1 then return tocolor(80, 180, 255, 255) end
        return tocolor(235, 240, 246, 255)
end

local function getBadges(p)
        local icons = {}
        if getElementData(p, "hiddenadmin") == 1 then return icons end
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level >= 6 then
                table.insert(icons, "premium")
        elseif level >= 4 then
                table.insert(icons, "booster")
        elseif level >= 1 then
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

local function getRank(p)
        if getElementData(p, "hiddenadmin") == 1 then return "Player" end
        -- [Vortex] the 21-rank ladder is THE source: rank:name is pushed by the
        -- staff bridge at login and kept fresh by /staffs. This must come before
        -- everything else -- the legacy admin_level fallback used to win whenever
        -- the "global" export hiccupped and rendered Owner accounts as
        -- "Admin <stale number>".
        local rn = getElementData(p, "rank:name")
        if rn and rn ~= "" then return tostring(rn) end
        local g = getResourceFromName("global")
        if g and getResourceState(g) == "running" then
                local ok, res = pcall(function() return exports.global:getPlayerAdminTitle(p) end)
                if ok and type(res) == "string" and res ~= "" and res ~= "Player" then
                        return res
                end
        end
        local level = tonumber(getElementData(p, "admin_level")) or 0
        if level > 0 then
                return RANK_TITLES[level] or ("Admin " .. level)
        end
        local integ = getResourceFromName("integration")
        if integ and getResourceState(integ) == "running" then
                local okSup, isSup = pcall(function() return exports.integration:isPlayerSupporter(p) end)
                if okSup and isSup then return "Supporter" end
                local okSm, isSm = pcall(function() return exports.integration:isPlayerSupportManager(p) end)
                if okSm and isSm then return "Support Manager" end
                local okVct, isVct = pcall(function() return exports.integration:isPlayerVCTMember(p) end)
                if okVct and isVct then return "VCT Member" end
                local okSc, isSc = pcall(function() return exports.integration:isPlayerScripter(p) end)
                if okSc and isSc then return "Scripter" end
        end
        return "Player"
end

local function refreshPlayer(p)
        if not isElement(p) then return end
        cache[p] = {
                color = adminColor(p),
                badges = getBadges(p),
                rank = getRank(p),
        }
end

--[[ ==================== player list ==================== ]]

local function updatePlayers()
        local all = getElementsByType("player")
        local list = {}
        for _, p in ipairs(all) do
                if isElement(p) then
                        local pid = tonumber(getElementData(p, "playerid")) or 999999
                        table.insert(list, {
                                element = p,
                                id = pid,
                                name = (getPlayerName(p) or "?"):gsub("_", " "),
                        })
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

-- refresh cached colours/ranks every 2 seconds while open
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
                local hay = string.lower(p.name .. " " .. tostring(p.id) .. " " .. (c and c.rank or ""))
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

local function cellData(colName, p, c)
        if colName == "ID" then
                return tostring(getElementData(p, "playerid") or "-"), c.color
        elseif colName == "" then
                return nil, c.color, c.badges
        elseif colName == "Name" then
                return (getPlayerName(p) or "?"):gsub("_", " "), c.color
        elseif colName == "Rank" then
                return c.rank, c.color
        elseif colName == "Playtime" then
                return formatTime(getElementData(p, "hoursplayed")), tocolor(175, 185, 200, 230)
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
        dxDrawRectangle(trackX, ROWS_TOP, 4 * s, trackH, tocolor(255, 255, 255, 18), true)
        dxDrawRectangle(trackX, thumbY, 4 * s, thumbH, accent(220), true)
end

-- hover animation: text whitens and shifts forward on the hovered row
local hoverRow = -1
local hoverAnim = 0
local lastTick = getTickCount()

local function drawBoard()
        local list = filteredList()

	-- smooth rounded border + fill: outer accent rect, inner black rect
	-- (concentric rounding keeps the border thickness even everywhere)
	local bw = 2 * s
	local inner = math.max(0, CORNER - bw)
	drawRoundRect(BOARD.x, BOARD.y, BOARD.w, BOARD.h, accent(120), true)
	drawRoundRect(BOARD.x + bw, BOARD.y + bw, BOARD.w - 2 * bw, BOARD.h - 2 * bw,
		tocolor(6, 8, 12, 255), true, inner)

	-- header separator, kept inside the straight part of the rounded sides
	dxDrawRectangle(BOARD.x + CORNER, BOARD.y + HEADER_H, BOARD.w - CORNER * 2, 1,
		tocolor(255, 255, 255, 20), true)
        local logoSize = HEADER_H - 22 * s
        if logoTex then
                dxDrawImage(BOARD.x + PAD_X, BOARD.y + (HEADER_H - logoSize) / 2,
                        logoSize, logoSize, logoTex, 0, 0, 0, tocolor(255, 255, 255, 255), true)
        end
        dxDrawText("Project Death Zone",
                BOARD.x + PAD_X + logoSize + 10 * s, BOARD.y,
                BOARD.x + BOARD.w * 0.5, BOARD.y + HEADER_H,
                tocolor(255, 255, 255, 240), 1, fontTitle, "left", "center", true, false, true)

        -- search field (top right of the header)
        searchBox.w = 220 * s
        searchBox.h = 30 * s
        searchBox.x = BOARD.x + BOARD.w - PAD_X - searchBox.w
	searchBox.y = BOARD.y + (HEADER_H - searchBox.h) / 2
	if searchEdit then
		guiSetPosition(searchEdit, searchBox.x + 28 * s, searchBox.y, false)
		guiSetSize(searchEdit, searchBox.w - 36 * s, searchBox.h, false)
	end
	drawRoundRect(searchBox.x, searchBox.y, searchBox.w, searchBox.h, tocolor(3, 5, 8, 255), true)
        dxDrawRectangle(searchBox.x + CORNER / 2, searchBox.y + searchBox.h - 1, searchBox.w - CORNER, 1,
                searchOn and accent(255) or tocolor(70, 85, 110, 200), true)
        if searchTex then
                dxDrawImage(searchBox.x + 8 * s, searchBox.y + (searchBox.h - 14 * s) / 2, 14 * s, 14 * s,
                        searchTex, 0, 0, 0, tocolor(255, 255, 255, searchOn and 255 or 140), true)
        end
        local sLabel = searchBuf ~= "" and searchBuf or "Search..."
        local sColor = searchBuf ~= "" and tocolor(255, 255, 255, 255) or tocolor(150, 160, 175, 255)
        dxDrawText(sLabel, searchBox.x + 28 * s, searchBox.y,
                searchBox.x + searchBox.w - 8 * s, searchBox.y + searchBox.h,
                sColor, 1, fontRow, "left", "center", true, false, true)
        if searchOn and math.floor(getRealTime().timestamp / 0.5) % 2 == 0 then
                local tw = dxGetTextWidth(searchBuf, 1, fontRow)
                dxDrawRectangle(searchBox.x + 28 * s + tw + 2, searchBox.y + 8 * s, 1, searchBox.h - 16 * s,
                        tocolor(255, 255, 255, 255), true)
        end

        -- player count (right aligned, clear of the search field)
        if groupTex then
                local giY = BOARD.y + (HEADER_H - 14 * s) / 2
                dxDrawImage(searchBox.x - 24 * s, giY, 14 * s, 14 * s,
                        groupTex, 0, 0, 0, tocolor(255, 255, 255, 230), true)
        end
        dxDrawText(countText .. "  ( " .. tostring(maxOnline) .. " max )",
                BOARD.x + BOARD.w * 0.5, BOARD.y, searchBox.x - 34 * s, BOARD.y + HEADER_H,
                tocolor(190, 200, 215, 230), 1, fontRow, "right", "center", true, false, true)

        -- column header row
        local colY = BOARD.y + HEADER_H
        dxDrawRectangle(BOARD.x, colY, BOARD.w, COL_H, tocolor(14, 18, 26, 255), true)
        local cx = BOARD.x + PAD_X
        for _, col in ipairs(COLUMNS) do
                local cw = col.frac * CONTENT_W
                if col.name ~= "" then
                        dxDrawText(col.name, cx, colY, cx + cw - 4 * s, colY + COL_H,
                                tocolor(170, 185, 205, 235), 1, fontCol, "left", "center", true, false, true)
                end
                cx = cx + cw
        end
        dxDrawRectangle(BOARD.x, colY + COL_H, BOARD.w, 1, tocolor(255, 255, 255, 25), true)

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
		if not isElement(p) then
			-- entry is stale; refresh on the next updatePlayers pass
		else
		local rowY = ROWS_TOP + (i - 1) * ROW_H
		local isLocal = (p == localPlayer)
		local rowBg
		if isLocal then
			rowBg = nil -- no blue highlight on the local player
		elseif i % 2 == 0 then
			rowBg = tocolor(255, 255, 255, 8)
		end
		if rowBg then
			drawRoundRect(BOARD.x + PAD_X / 2, rowY, BOARD.w - PAD_X, ROW_H - 2, rowBg, true, 6 * s)
		end

		-- hover: track which row the mouse is over (not my own row)
		local rowX = BOARD.x + PAD_X / 2
		local rowW = BOARD.w - PAD_X
		if clickInRect(rowX, rowY, rowW, ROW_H - 2) and not isLocal then
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

		-- text whitens and shifts forward slightly on the hovered row
		local rowHover = (i == hoverRow) and hoverAnim or 0
		local textShift = rowHover * 4 * s

		local c = cache[p] or { color = tocolor(235, 240, 246, 255), badges = {}, rank = "Player" }
		local cellX = BOARD.x + PAD_X
		for _, col in ipairs(COLUMNS) do
			local cw = col.frac * CONTENT_W
			local value, color, badges = cellData(col.name, p, c)
			if badges then
				for b = 1, #badges do
					local tex = badgeTex[badges[b]]
					if tex then
						dxDrawImage(cellX + (b - 1) * 20 * s + textShift, rowY + (ROW_H - 16 * s) / 2,
							16 * s, 16 * s, tex, 0, 0, 0, tocolor(255, 255, 255, 255), true)
					end
				end
			elseif value ~= nil then
				local r2 = bitExtract(color, 16, 8)
				local g2 = bitExtract(color, 8, 8)
				local b3 = bitExtract(color, 0, 8)
				local a3 = bitExtract(color, 24, 8)
				local hc = tocolor(
					math.floor(r2 + (255 - r2) * rowHover),
					math.floor(g2 + (255 - g2) * rowHover),
					math.floor(b3 + (255 - b3) * rowHover),
					a3
				)
				dxDrawText(tostring(value), cellX + textShift, rowY, cellX + cw - 4 * s + textShift, rowY + ROW_H,
					hc, 1, fontRow, "left", "center", true, false, true)
			end
			cellX = cellX + cw
		end

		-- permanent blue accent bar on MY row (the logged-in player)
		if isLocal then
			dxDrawRectangle(BOARD.x + PAD_X / 2 - 4 * s, rowY + 3 * s, 3 * s, ROW_H - 8 * s,
				accent(230), true)
		end

		-- faint grey separator between rows
                if rowY + ROW_H - 1 < ROWS_BOTTOM - 2 then
                        dxDrawRectangle(BOARD.x + PAD_X, rowY + ROW_H - 1, BOARD.w - PAD_X * 2, 1,
                                tocolor(120, 125, 135, 38), true)
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

--[[ test hook — harmless in production, lets the automated mock harness
     reach the otherwise file-local rank/color helpers ]]
function getScoreboardTestTable()
        return { getRank = getRank, adminColor = adminColor, getBadges = getBadges }
end
