-- Modern Scoreboard for Owl Gaming / PDZ Roleplay
-- Adapted from decompiled modern tab (score_c_decompiled.lua)
-- Compatible with local server exports (global, integration, playerid)

local sw, sh = guiGetScreenSize()
local sx, sy = sw / 1920, sh / 1080

local ScoreBoard = {
	state = false,
	cursorStatus = false,
	scroll = 0,
	players = {},
	players_count = "0 Players",
	columns = {
		{ name = "ID",       width = math.floor(70 * sx),  align = "center" },
		{ name = "Name",     width = math.floor(380 * sx), align = "left" },
		{ name = "Rank",     width = math.floor(220 * sx), align = "left" },
		{ name = "Playtime", width = math.floor(160 * sx), align = "center" },
		{ name = "Ping",     width = math.floor(90 * sx),  align = "center" }
	}
}

-- UI Dimensions
local boardWidth = math.floor(960 * sx)
local boardHeight = math.floor(620 * sy)
local boardX = math.floor((sw - boardWidth) / 2)
local boardY = math.floor((sh - boardHeight) / 2)

local headerHeight = math.floor(65 * sy)
local rowHeight = math.floor(32 * sy)
local maxVisibleRows = math.floor((boardHeight - headerHeight - 40 * sy) / rowHeight)

-- Colors
local COLOR_BG = tocolor(15, 20, 30, 240)
local COLOR_HEADER = tocolor(22, 30, 45, 255)
local COLOR_ROW_EVEN = tocolor(20, 26, 38, 180)
local COLOR_ROW_ODD = tocolor(15, 20, 30, 180)
local COLOR_ROW_HOVER = tocolor(45, 85, 155, 120)
local COLOR_LOCAL_PLAYER = tocolor(40, 100, 180, 70)
local COLOR_ACCENT = tocolor(52, 152, 219, 255)
local COLOR_TEXT_DIM = tocolor(180, 190, 205, 200)
local COLOR_TEXT_BRIGHT = tocolor(255, 255, 255, 255)

-- Convert hours played into human-readable string
local function formatPlayTime(hours)
	hours = tonumber(hours) or 0
	if hours <= 0 then
		return "0h"
	elseif hours < 24 then
		return string.format("%dh", hours)
	else
		local days = math.floor(hours / 24)
		local remHours = hours % 24
		return string.format("%dd %dh", days, remHours)
	end
end

-- Get rank title and color
local function getPlayerRank(player)
	local hidden = getElementData(player, "hiddenadmin")
	if hidden == 1 then
		return "Player", tocolor(200, 200, 200, 220)
	end

	local adminLevel = tonumber(getElementData(player, "admin_level")) or 0
	if exports.global and exports.global.getPlayerAdminTitle then
		local title = exports.global:getPlayerAdminTitle(player)
		if title and title ~= "" and title ~= "Player" then
			return title, tocolor(231, 76, 60, 255)
		end
	end

	if adminLevel > 0 then
		local titles = {
			[1] = "Trial Admin",
			[2] = "Admin",
			[3] = "Senior Admin",
			[4] = "Lead Admin",
			[5] = "Head Admin",
			[6] = "Owner"
		}
		return titles[adminLevel] or ("Admin (" .. adminLevel .. ")"), tocolor(231, 76, 60, 255)
	end

	local supporter = tonumber(getElementData(player, "supporter_level")) or 0
	if supporter > 0 then
		return "Supporter", tocolor(46, 204, 113, 255)
	end

	local vct = tonumber(getElementData(player, "vct_level")) or 0
	if vct > 0 then
		return "VCT Member", tocolor(241, 196, 15, 255)
	end

	local scripter = tonumber(getElementData(player, "scripter_level")) or 0
	if scripter > 0 then
		return "Scripter", tocolor(155, 89, 182, 255)
	end

	return "Player", tocolor(180, 190, 205, 200)
end

-- Update players list & sort by ID
local function updatePlayersList()
	local all = getElementsByType("player")
	local list = {}

	for _, p in ipairs(all) do
		local pid = tonumber(getElementData(p, "playerid")) or 9999
		table.insert(list, {
			element = p,
			id = pid,
			name = getPlayerName(p):gsub("_", " "),
			username = getElementData(p, "account:username") or "",
			hours = tonumber(getElementData(p, "hoursplayed")) or 0,
			ping = getPlayerPing(p)
		})
	end

	table.sort(list, function(a, b)
		return a.id < b.id
	end)

	ScoreBoard.players = list
	ScoreBoard.players_count = #list .. " Player" .. (#list == 1 and "" or "s")
end

-- Mouse check helper
local function isMouseInArea(x, y, w, h)
	if not isCursorShowing() then return false end
	local cx, cy = getCursorPosition()
	cx, cy = cx * sw, cy * sh
	return (cx >= x and cx <= x + w and cy >= y and cy <= y + h)
end

-- Main Draw function
function ScoreBoard.draw()
	-- Main container background
	dxDrawRectangle(boardX, boardY, boardWidth, boardHeight, COLOR_BG, true)

	-- Top decorative line (accent)
	dxDrawRectangle(boardX, boardY, boardWidth, 3, COLOR_ACCENT, true)

	-- Top Header bar
	dxDrawRectangle(boardX, boardY + 3, boardWidth, headerHeight - 3, COLOR_HEADER, true)

	-- Server info / Logo text
	local serverName = "Direct Backup Roleplay"
	dxDrawText(serverName, boardX + 20 * sx, boardY, boardX + 300 * sx, boardY + headerHeight, COLOR_TEXT_BRIGHT, 1.2, "default-bold", "left", "center", true, false, true)

	-- Player count & hint
	local countText = ScoreBoard.players_count .. " Online  |  RMB: Cursor"
	dxDrawText(countText, boardX + boardWidth - 420 * sx, boardY, boardX + boardWidth - 20 * sx, boardY + headerHeight, COLOR_TEXT_DIM, 1.0, "default", "right", "center", true, false, true)

	-- Column headers background
	local colHeaderY = boardY + headerHeight
	local colHeaderH = math.floor(28 * sy)
	dxDrawRectangle(boardX, colHeaderY, boardWidth, colHeaderH, tocolor(25, 35, 52, 230), true)

	-- Column Titles
	local curX = boardX + 15 * sx
	for _, col in ipairs(ScoreBoard.columns) do
		dxDrawText(col.name, curX, colHeaderY, curX + col.width, colHeaderY + colHeaderH, COLOR_ACCENT, 1.0, "default-bold", col.align, "center", true, false, true)
		curX = curX + col.width + 10 * sx
	end

	-- Player Rows
	local totalPlayers = #ScoreBoard.players
	local startIndex = math.max(1, math.min(ScoreBoard.scroll + 1, math.max(1, totalPlayers - maxVisibleRows + 1)))
	local endIndex = math.min(totalPlayers, startIndex + maxVisibleRows - 1)

	local startRowY = colHeaderY + colHeaderH + 4 * sy

	for i = startIndex, endIndex do
		local pData = ScoreBoard.players[i]
		if pData and isElement(pData.element) then
			local rowY = startRowY + (i - startIndex) * rowHeight
			local isLocal = (pData.element == localPlayer)
			local isHover = isMouseInArea(boardX + 5 * sx, rowY, boardWidth - 10 * sx, rowHeight)

			-- Row background
			if isHover then
				dxDrawRectangle(boardX + 5 * sx, rowY, boardWidth - 10 * sx, rowHeight - 2, COLOR_ROW_HOVER, true)
			elseif isLocal then
				dxDrawRectangle(boardX + 5 * sx, rowY, boardWidth - 10 * sx, rowHeight - 2, COLOR_LOCAL_PLAYER, true)
			elseif i % 2 == 0 then
				dxDrawRectangle(boardX + 5 * sx, rowY, boardWidth - 10 * sx, rowHeight - 2, COLOR_ROW_EVEN, true)
			else
				dxDrawRectangle(boardX + 5 * sx, rowY, boardWidth - 10 * sx, rowHeight - 2, COLOR_ROW_ODD, true)
			end

			-- Render Columns
			local rowX = boardX + 15 * sx
			local rankTitle, rankColor = getPlayerRank(pData.element)

			-- ID
			dxDrawText(tostring(pData.id), rowX, rowY, rowX + ScoreBoard.columns[1].width, rowY + rowHeight, COLOR_TEXT_BRIGHT, 1.0, "default-bold", "center", "center", true, false, true)
			rowX = rowX + ScoreBoard.columns[1].width + 10 * sx

			-- Name + Username
			local displayName = pData.name
			if pData.username ~= "" then
				displayName = displayName .. " (" .. pData.username .. ")"
			end
			dxDrawText(displayName, rowX, rowY, rowX + ScoreBoard.columns[2].width, rowY + rowHeight, COLOR_TEXT_BRIGHT, 1.0, "default", "left", "center", true, false, true)
			rowX = rowX + ScoreBoard.columns[2].width + 10 * sx

			-- Rank
			dxDrawText(rankTitle, rowX, rowY, rowX + ScoreBoard.columns[3].width, rowY + rowHeight, rankColor, 1.0, "default-bold", "left", "center", true, false, true)
			rowX = rowX + ScoreBoard.columns[3].width + 10 * sx

			-- Playtime
			local pTime = formatPlayTime(pData.hours)
			dxDrawText(pTime, rowX, rowY, rowX + ScoreBoard.columns[4].width, rowY + rowHeight, COLOR_TEXT_DIM, 1.0, "default", "center", "center", true, false, true)
			rowX = rowX + ScoreBoard.columns[4].width + 10 * sx

			-- Ping
			local ping = pData.ping
			local pingColor = tocolor(46, 204, 113, 255)
			if ping > 150 then
				pingColor = tocolor(231, 76, 60, 255)
			elseif ping > 80 then
				pingColor = tocolor(241, 196, 15, 255)
			end
			dxDrawText(tostring(ping), rowX, rowY, rowX + ScoreBoard.columns[5].width, rowY + rowHeight, pingColor, 1.0, "default", "center", "center", true, false, true)
		end
	end

	-- Scrollbar (if needed)
	if totalPlayers > maxVisibleRows then
		local scrollTrackH = maxVisibleRows * rowHeight
		local scrollTrackX = boardX + boardWidth - 12 * sx
		local scrollTrackY = startRowY

		-- Track
		dxDrawRectangle(scrollTrackX, scrollTrackY, 6 * sx, scrollTrackH, tocolor(10, 15, 20, 150), true)

		-- Thumb
		local thumbRatio = maxVisibleRows / totalPlayers
		local thumbH = math.max(20, scrollTrackH * thumbRatio)
		local maxScroll = totalPlayers - maxVisibleRows
		local currentScroll = math.min(ScoreBoard.scroll, maxScroll)
		local thumbY = scrollTrackY + (currentScroll / maxScroll) * (scrollTrackH - thumbH)

		dxDrawRectangle(scrollTrackX, thumbY, 6 * sx, thumbH, COLOR_ACCENT, true)
	end
end

-- Toggle Cursor with Right Mouse Button
local function toggleCursor(key, state)
	if not ScoreBoard.state then return end
	if state == "down" then
		ScoreBoard.cursorStatus = not ScoreBoard.cursorStatus
		showCursor(ScoreBoard.cursorStatus)
	end
end

-- Mouse Wheel Scroll
local function handleWheel(key)
	if not ScoreBoard.state then return end
	local total = #ScoreBoard.players
	local maxScroll = math.max(0, total - maxVisibleRows)

	if key == "mouse_wheel_up" then
		ScoreBoard.scroll = math.max(0, ScoreBoard.scroll - 1)
	elseif key == "mouse_wheel_down" then
		ScoreBoard.scroll = math.min(maxScroll, ScoreBoard.scroll + 1)
	end
end

-- Toggle Scoreboard
local function toggleScoreboard(show)
	if show == ScoreBoard.state then return end

	ScoreBoard.state = show
	if show then
		updatePlayersList()
		ScoreBoard.scroll = 0
		ScoreBoard.cursorStatus = false
		addEventHandler("onClientRender", root, ScoreBoard.draw)
		bindKey("mouse2", "down", toggleCursor)
		bindKey("mouse_wheel_up", "down", handleWheel)
		bindKey("mouse_wheel_down", "down", handleWheel)
	else
		removeEventHandler("onClientRender", root, ScoreBoard.draw)
		unbindKey("mouse2", "down", toggleCursor)
		unbindKey("mouse_wheel_up", "down", handleWheel)
		unbindKey("mouse_wheel_down", "down", handleWheel)
		if ScoreBoard.cursorStatus then
			showCursor(false)
			ScoreBoard.cursorStatus = false
		end
	end
end

-- Export for compatibility with other resources
function isVisible()
	return ScoreBoard.state
end

-- TAB Key Handler
bindKey("tab", "both", function(key, state)
	if state == "down" then
		toggleScoreboard(true)
	else
		if not ScoreBoard.cursorStatus then
			toggleScoreboard(false)
		end
	end
end)

-- Auto refresh on player join/quit
addEventHandler("onClientPlayerJoin", root, function()
	if ScoreBoard.state then updatePlayersList() end
end)

addEventHandler("onClientPlayerQuit", root, function()
	if ScoreBoard.state then updatePlayersList() end
end)

