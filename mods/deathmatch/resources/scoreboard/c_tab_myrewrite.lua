--
-- score-board / c_tab.lua
-- OwlGaming style scoreboard.
--
-- Layout is computed from the screen size so the board stays proportional on
-- any resolution. All sizes live in the BOARD table (see computeBoard).
--
-- Original external dependencies and how they are satisfied here:
--   exports.UIKit                        -> replaced by local fonts/theme
--   exports.roleplay:getPlayerID         -> element data "playerid"
--   exports["play-time"]:getPlayerPlayTime -> element data "hoursplayed"
--   exports.hud:getHudSetting            -> always on
--   exports.public:setBlurShaderVisible  -> local BlurShader.fx
--

local sw, sh = guiGetScreenSize()

-- scale factor used everywhere by the original: screenWidth / 1080
-- capped so the board never grows beyond its 1080p design size on wider screens
local s = math.min(sw / 1080, sh / 1080, 1.25)

ScoreBoard = {
	state = false,
	columns = {
		{ "ID", 0.06, true },
		{ "", 0.05 },
		{ "Name", 0.42, true },
		{ "Rank", 0.20, true },
		{ "Playtime", 0.15 },
		{ "Ping", 0.08 }
	},
	isHoverScrolbar = false,
	isClickScrolbar = false,
	clickPositionRelatedToScroll = 0,
	scrollY = 0,
	pos = { 0, 0, 0, 0 },
	scroll = 0,
	scrollPos = {},
	drawScroll = false,
	friends = {},
	friendstate = false,
	players = {},
	filtered_players = false,
	cursorStatus = false
}

-- board geometry, recomputed from the screen size so everything stays proportional
local BOARD = {
	w = 0, h = 0, x = 0, y = 0,
	headerH = 0, colH = 0, rowH = 0,
	padX = 0, rowsTop = 0, rowsBottom = 0
}

local function computeBoard()
	BOARD.w = math.min(sw * 0.62, 1180 * s)
	BOARD.h = math.min(sh * 0.68, 620 * s)
	BOARD.x = (sw - BOARD.w) / 2
	BOARD.y = (sh - BOARD.h) / 2
	BOARD.padX = 18 * s
	BOARD.headerH = 58 * s
	BOARD.colH = 34 * s
	BOARD.rowH = 30 * s
	BOARD.rowsTop = BOARD.y + BOARD.headerH + BOARD.colH + 8 * s
	BOARD.rowsBottom = BOARD.y + BOARD.h - 14 * s
	ScoreBoard.pos = { BOARD.x, BOARD.y, BOARD.w, BOARD.h }
	-- content width available for the columns
	BOARD.contentW = BOARD.w - BOARD.padX * 2 - 10 * s
end
computeBoard()

--[[ ==================== theme / fonts ==================== ]]

-- theme accent colour (original: exports.UIKit:uiGetThemeColor("primary"))
local themeR, themeG, themeB = 0, 168, 255
local function themeColor(a) return tocolor(themeR, themeG, themeB, a or 255) end

local fontLarge, fontUI, fontSmall
local function loadFonts()
	-- font sizes are relative to the board height so they scale with the board
	local base = math.max(math.min(BOARD.h / 620, 1.6), 0.85)
	fontLarge = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", math.floor(17 * base)) or "default-bold"
	fontUI = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", math.floor(14 * base)) or "default"
	fontSmall = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", math.floor(12 * base)) or "default"
end
loadFonts()

-- highest player count (synced from the server)
local highestPlayerCount = 0

-- badges
local badgeStep = 20 * s
local badgeSize = 16 * s
local badgeTextures = {}
local groupTexture, logoCircle, logoText

local BADGE_FILES = { "premium", "booster", "classic", "gold_member", "verified", "youtuber" }

local function createBadges()
	for i = 1, #BADGE_FILES do
		badgeTextures[BADGE_FILES[i]] = dxCreateTexture("icons/" .. BADGE_FILES[i] .. ".png", "dxt5", true, "clamp")
	end
end

local function createTextures()
	groupTexture = dxCreateTexture("group.png", "argb", true, "clamp")
	logoCircle = dxCreateTexture("logo-circle.png", "argb", true, "clamp")
	logoText = dxCreateTexture("logo-text.png", "argb", true, "clamp")
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	createBadges()
	createTextures()
end)

-- blur, replaces exports.public:setBlurShaderVisible
local blurShader
local function createShader()
	blurShader = dxCreateShader("BlurShader.fx", "", 0, 0)
end
createShader()

--[[ ==================== search field (UIKit replacement) ]]--

-- filled in every frame by drawSearchField()
local SEARCH = { x = 0, y = 0, w = 0, h = 0 }
local searchTexture = dxCreateTexture("search.png", "argb", true, "clamp")
local searchActive, searchBuffer = false, ""

-- highest player count sync (original: scoreboard:highestPlayerCount:sync)
ScoreBoard.highestCount = 0
addEvent("scoreboard:highestPlayerCount:sync", true)
addEventHandler("scoreboard:highestPlayerCount:sync", root, function(value)
	highestPlayerCount = value or 0
	ScoreBoard.highestCount = highestPlayerCount
end)

addEvent("scoreboard:getFriendsList:callback", true)
addEventHandler("scoreboard:getFriendsList:callback", root, function(friends)
	ScoreBoard.friends = friends
end)

function filterPlayersList(text)
	text = string.lower(tostring(text or ""))
	if text == "" then
		ScoreBoard.filtered_players = false
	else
		ScoreBoard.filtered_players = {}
		for i = 1, #ScoreBoard.players do
			local matched = false
			for _, column in ipairs(ScoreBoard.columns) do
				if column[3] then
					local value = getColumnData(column[1], ScoreBoard.players[i])
					if value and string.find(string.lower(tostring(value)), text, 1, true) then
						matched = true
						break
					end
				end
			end
			if matched then
				ScoreBoard.filtered_players[i] = true
			end
		end
		ScoreBoard.scroll = 0
	end
end

--[[ ==================== helpers ==================== ]]

function isMouseInPosition(x, y, w, h)
	if not isCursorShowing() then
		return false
	end
	local cx, cy = getCursorPosition()
	return x <= cx * sw and y <= cy * sh and cx * sw <= x + w and cy * sh <= y + h
end

-- click hit-test that works whether the cursor is shown or not (MTA always
-- reports a cursor position while a scoreboard is open)
function clickInPosition(x, y, w, h)
	local cx, cy = getCursorPosition()
	if not cx then
		return false
	end
	return x <= cx * sw and y <= cy * sh and cx * sw <= x + w and cy * sh <= y + h
end

function convertTimeToString(seconds)
	seconds = tonumber(seconds) or 0
	if math.floor(seconds / (24 * 60 * 60)) == 0 then
		if math.floor(seconds % (24 * 60 * 60) / (60 * 60)) == 0 then
			return math.floor(seconds % (24 * 60 * 60) % (60 * 60) / 60) .. "m "
				.. math.floor(seconds % (24 * 60 * 60) % (60 * 60) % 60) .. "s"
		else
			return math.floor(seconds % (24 * 60 * 60) / (60 * 60)) .. "h "
				.. math.floor(seconds % (24 * 60 * 60) % (60 * 60) / 60) .. "m"
		end
	else
		return math.floor(seconds % (24 * 60 * 60) / (60 * 60)) + math.floor(seconds / (24 * 60 * 60)) * 24 .. "h "
			.. math.floor(seconds % (24 * 60 * 60) % (60 * 60) / 60) .. "m"
	end
end

--[[ ==================== data providers ==================== ]]

-- per-player cached colour + badges, the original stored these in var0[player]
local var0data = {}

local function getPlayerID(thePlayer)
	local id = tonumber(getElementData(thePlayer, "playerid"))
	if id then return id end
	return 0
end

local function getPlayerPlayTime(thePlayer)
	local hours = tonumber(getElementData(thePlayer, "hoursplayed"))
	if hours then return hours * 3600 end
	return 0
end

local function getTempRank(thePlayer)
	local title
	if getResourceState(getResourceFromName("global")) == "running" then
		local ok, res = pcall(function() return exports.global:getPlayerAdminTitle(thePlayer) end)
		if ok then title = res end
	end
	if title and title ~= "" and title ~= "Player" then return title end
	if getResourceState(getResourceFromName("integration")) == "running" then
		if exports.integration:isPlayerSupportManager(thePlayer) then return "Support Manager"
		elseif exports.integration:isPlayerSupporter(thePlayer) then return "Supporter"
		elseif exports.integration:isPlayerLeadScripter(thePlayer) then return "Lead Scripter"
		elseif exports.integration:isPlayerScripter(thePlayer) then return "Scripter"
		elseif exports.integration:isPlayerVCTMember(thePlayer) then return "VCT Member" end
	end
	return false
end

local function getNameColor(thePlayer)
	local data = var0data[thePlayer]
	return data and data.color or tocolor(255, 255, 255, 120)
end

local function getSpecialMembership(thePlayer)
	local icons = {}
	if getElementData(thePlayer, "hiddenadmin") == 1 then
		return icons
	end
	local level = tonumber(getElementData(thePlayer, "admin_level")) or 0
	if level >= 6 then
		table.insert(icons, "premium")
	elseif level >= 4 then
		table.insert(icons, "booster")
	elseif level >= 1 then
		table.insert(icons, "classic")
	end
	if getResourceState(getResourceFromName("integration")) == "running" then
		if exports.integration:isPlayerVCTMember(thePlayer) then
			table.insert(icons, "verified")
		end
		if exports.integration:isPlayerLeadScripter(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
			table.insert(icons, "gold_member")
		end
	end
	if getElementData(thePlayer, "donation:nametag") == true then
		table.insert(icons, "youtuber")
	end
	return icons
end

local function cachePlayerData(thePlayer)
	local level = tonumber(getElementData(thePlayer, "admin_level")) or 0
	local r, g, b = 255, 255, 255
	if tonumber(getElementData(thePlayer, "hiddenadmin")) ~= 1 then
		if level >= 6 then
			r, g, b = 255, 0, 0
		elseif level >= 4 then
			r, g, b = 255, 140, 0
		elseif level >= 1 then
			r, g, b = 0, 170, 255
		end
	end
	var0data[thePlayer] = {
		color = tocolor(r, g, b, 255),
		icon = getSpecialMembership(thePlayer)
	}
end

function getColumnData(column, thePlayer)
	if not isElement(thePlayer) then
		return "-", tocolor(255, 255, 255, 120)
	end
	if column == "ID" then
		return tostring(getPlayerID(thePlayer)), getNameColor(thePlayer)
	elseif column == "" then
		return "", getNameColor(thePlayer), (var0data[thePlayer] and var0data[thePlayer].icon) or false
	elseif column == "Name" then
		local username = getElementData(thePlayer, "account:username")
		if username and getElementData(thePlayer, "loggedin") == 1 then
			return tostring(getPlayerName(thePlayer):gsub("_", " ")) .. " (" .. tostring(username) .. ")", getNameColor(thePlayer)
		end
		return tostring(getPlayerName(thePlayer):gsub("_", " ")), getNameColor(thePlayer)
	elseif column == "Ping" then
		return getPlayerPing(thePlayer), getNameColor(thePlayer)
	elseif column == "Playtime" then
		return convertTimeToString(getPlayerPlayTime(thePlayer)), getNameColor(thePlayer)
	elseif column == "Rank" then
		if getElementData(thePlayer, "hiddenadmin") then
			return "-", getNameColor(thePlayer)
		elseif getTempRank(thePlayer) then
			return getTempRank(thePlayer), getNameColor(thePlayer)
		else
			return "-", getNameColor(thePlayer)
		end
	end
	return "-", getNameColor(thePlayer)
end

--[[ ==================== drawing ==================== ]]

local function drawColumnRow(rowY, thePlayer, hovered)
	local x = BOARD.x + BOARD.padX
	local w = BOARD.contentW
	dxDrawRectangle(x, rowY, w, BOARD.rowH, tocolor(0, 0, 0, hovered and 110 or 150), true)
	if hovered then
		dxDrawRectangle(x, rowY, 3 * s, BOARD.rowH, themeColor(200), true)
	end
	local cx = x + 8 * s
	for _, column in ipairs(ScoreBoard.columns) do
		local cw = column[2] * w
		local value, color, badges = getColumnData(column[1], thePlayer)
		if badges then
			for b = 1, #badges do
				dxDrawImage(cx + (badgeStep * (b - 1)), rowY + (BOARD.rowH - badgeSize) / 2,
					badgeSize, badgeSize, badgeTextures[badges[b]], 0, 0, 0, tocolor(255, 255, 255, 255), true)
			end
		elseif value ~= nil then
			dxDrawText(tostring(value), cx, rowY, cx + cw - 4 * s, rowY + BOARD.rowH,
				color, 1, fontUI, "left", "center", true, false, true)
		end
		cx = cx + cw
	end
end

local function drawColumnHeaders()
	local x = BOARD.x + BOARD.padX
	local w = BOARD.contentW
	dxDrawRectangle(x, BOARD.rowsTop - BOARD.colH - 6 * s, w, BOARD.colH + 6 * s, tocolor(0, 0, 0, 220), true)
	dxDrawRectangle(x, BOARD.rowsTop - BOARD.colH - 6 * s, 3 * s, BOARD.colH + 6 * s, themeColor(230), true)
	local cx = x + 8 * s
	for _, column in ipairs(ScoreBoard.columns) do
		local cw = column[2] * w
		if column[1] ~= "" then
			dxDrawText(column[1], cx, BOARD.rowsTop - BOARD.colH, cx + cw - 4 * s, BOARD.rowsTop,
				tocolor(255, 255, 255, 235), 1, fontLarge, "left", "center", true, false, true)
		end
		cx = cx + cw
	end
	dxDrawRectangle(x, BOARD.rowsTop - 1, w, 1, tocolor(255, 255, 255, 40), true)
end

local function drawHeader()
	local x = BOARD.x
	-- header background
	dxDrawRectangle(x, BOARD.y, BOARD.w, BOARD.headerH, tocolor(10, 14, 20, 250), true)
	-- accent line under the header
	dxDrawRectangle(x, BOARD.y + BOARD.headerH - 2 * s, BOARD.w, 2 * s, themeColor(220), true)
	-- logo circle
	local logoSize = BOARD.headerH - 24 * s
	if logoCircle then
		dxDrawImage(x + BOARD.padX, BOARD.y + (BOARD.headerH - logoSize) / 2,
			logoSize, logoSize, logoCircle, 0, 0, 0, tocolor(255, 255, 255, 255), true)
	end
	-- server name
	dxDrawText("Project Death Zone", x + BOARD.padX + logoSize + 12 * s, BOARD.y,
		x + BOARD.w * 0.55, BOARD.y + BOARD.headerH,
		tocolor(255, 255, 255, 240), 1, fontLarge, "left", "center", true, false, true)
	-- group icon + players online
	local text = ScoreBoard.players_count or "0 Players"
	local textW = dxGetTextWidth(text, 1, fontUI)
	local iconX = x + BOARD.w - BOARD.padX - textW - 24 * s
	local iconY = BOARD.y + (BOARD.headerH - 16 * s) / 2
	if groupTexture then
		dxDrawImage(iconX, iconY, 16 * s, 16 * s, groupTexture, 0, 0, 0, tocolor(255, 255, 255, 255), true)
	end
	dxDrawText(text .. "  ( " .. tostring(highestPlayerCount) .. " max )",
		x + BOARD.w - BOARD.padX - textW, BOARD.y,
		x + BOARD.w - BOARD.padX, BOARD.y + BOARD.headerH,
		tocolor(255, 255, 255, 200), 1, fontUI, "left", "center", true, false, true)
end

drawSearchField = function()
	local x = BOARD.x + BOARD.w - BOARD.padX - 260 * s
	local y = BOARD.y - 2 * s
	local w = 260 * s
	local h = 30 * s
	dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 190), true)
	if searchTexture then
		dxDrawImage(x + 8 * s, y + (h - 14 * s) / 2, 14 * s, 14 * s,
			searchTexture, 0, 0, 0, tocolor(255, 255, 255, searchActive and 255 or 130), true)
	end
	dxDrawRectangle(x, y + h - 1, w, 1, searchActive and themeColor(255) or tocolor(255, 255, 255, 30), true)
	local text = searchBuffer
	if text == "" then
		dxDrawText("Search...", x + 28 * s, y, x + w - 6 * s, y + h,
			tocolor(255, 255, 255, 110), 1, fontUI, "left", "center", true, false, true)
	else
		dxDrawText(text, x + 28 * s, y, x + w - 6 * s, y + h,
			tocolor(255, 255, 255, 255), 1, fontUI, "left", "center", true, false, true)
		if math.floor(getRealTime().timestamp / 0.5) % 2 == 0 then
			local tw = dxGetTextWidth(text, 1, fontUI)
			dxDrawRectangle(x + 28 * s + tw + 2 * s, y + 7 * s, 1, h - 14 * s, tocolor(255, 255, 255, 255), true)
		end
	end
	SEARCH.x, SEARCH.y, SEARCH.w, SEARCH.h = x, y, w, h
end

function drawScrollbar(x, y, w, h)
	ScoreBoard.scrollPos = { x, y, w, h }
	local thumbH = math.max(h / 5, 20 * s)
	dxDrawRectangle(x + 1, ScoreBoard.scrollY, w - 2, thumbH, themeColor(210), true)
	if isMouseInPosition(x + 1, ScoreBoard.scrollY, w - 2, thumbH) then
		ScoreBoard.isHoverScrolbar = true
	else
		ScoreBoard.isHoverScrolbar = false
	end
	if ScoreBoard.isClickScrolbar and isCursorShowing() then
		local _, cy = getCursorPosition()
		ScoreBoard.scrollY = cy * sh - ScoreBoard.clickPositionRelatedToScroll
		ScoreBoard.scrollY = math.min(math.max(y + 1, ScoreBoard.scrollY), y + h - thumbH - 1)
		ScoreBoard.scroll = math.floor((ScoreBoard.scrollY - y - 1) / (h - thumbH) * 100)
	end
end

function ScoreBoard.draw()
	-- recompute in case the resolution changed
	computeBoard()

	-- outer shadow + board background
	dxDrawRectangle(BOARD.x - 6 * s, BOARD.y - 6 * s, BOARD.w + 12 * s, BOARD.h + 12 * s, tocolor(3, 6, 11, 160), true)
	dxDrawRectangle(BOARD.x, BOARD.y, BOARD.w, BOARD.h, tocolor(8, 11, 16, 235), true)

	drawHeader()
	drawColumnHeaders()

	ScoreBoard.hovered = -1

	-- local player row is always pinned to the top
	local localRowY = BOARD.rowsTop
	if localRowY + BOARD.rowH <= BOARD.rowsBottom then
		local hover = clickInPosition(BOARD.x + BOARD.padX, localRowY, BOARD.contentW, BOARD.rowH)
		drawColumnRow(localRowY, localPlayer, hover)
		if hover then ScoreBoard.hovered = 0 end
		dxDrawRectangle(BOARD.x + BOARD.padX, localRowY + BOARD.rowH, BOARD.contentW, 1, tocolor(255, 255, 255, 25), true)
	end

	local visibleRows = math.floor((BOARD.rowsBottom - localRowY - BOARD.rowH - 6 * s) / BOARD.rowH)
	local total = #ScoreBoard.players
	local maxScroll = math.max(0, total - visibleRows)
	local firstRow = 1
	if maxScroll > 0 then
		firstRow = 1 + math.floor(ScoreBoard.scroll / 100 * maxScroll)
	end

	local drawn = 0
	for i = firstRow, total do
		if drawn >= visibleRows then break end
		if not ScoreBoard.filtered_players or ScoreBoard.filtered_players[i] then
			local rowY = localRowY + BOARD.rowH + 6 * s + BOARD.rowH * drawn
			if rowY + BOARD.rowH <= BOARD.rowsBottom then
				local hover = clickInPosition(BOARD.x + BOARD.padX, rowY, BOARD.contentW, BOARD.rowH)
				drawColumnRow(rowY, ScoreBoard.players[i], hover)
				if hover then ScoreBoard.hovered = i end
			end
			drawn = drawn + 1
		end
	end

	ScoreBoard.drawScroll = (total > visibleRows) and (not ScoreBoard.filtered_players or visibleRows < total)
	if ScoreBoard.drawScroll then
		local sx = BOARD.x + BOARD.w - BOARD.padX - 6 * s
		drawScrollbar(sx, localRowY + BOARD.rowH + 6 * s, 6 * s, BOARD.rowsBottom - (localRowY + BOARD.rowH + 6 * s))
	end

	drawSearchField()
end

--[[ ==================== input ==================== ]]

function CursorVisible()
	ScoreBoard.cursorStatus = not ScoreBoard.cursorStatus
	showCursor(ScoreBoard.cursorStatus)
	if not ScoreBoard.cursorStatus and not getKeyState("tab") then
		showScoreboard(false)
	end
end

function ScoreBoard.click(button, state)
	if button == "left" then
		if state == "down" then
			if clickInPosition(SEARCH.x - 34 * s, SEARCH.y, SEARCH.w + 34 * s, SEARCH.h) then
				searchActive = true
				ScoreBoard.cursorStatus = true
				showCursor(true)
			else
				searchActive = false
			end
			if ScoreBoard.isHoverScrolbar then
				local _, cy = getCursorPosition()
				ScoreBoard.clickPositionRelatedToScroll = cy * sh - ScoreBoard.scrollY
				ScoreBoard.isClickScrolbar = true
			end
		else
			ScoreBoard.isClickScrolbar = false
			if searchActive and not clickInPosition(SEARCH.x - 34 * s, SEARCH.y, SEARCH.w + 34 * s, SEARCH.h) then
				searchActive = false
			end
			if ScoreBoard.hovered ~= -1 and ScoreBoard.hovered == 0 then
				ScoreBoard.friendstate = not ScoreBoard.friendstate
			end
			ScoreBoard.hovered = -1
		end
	end
end

function ScoreBoard.key(key, press)
	if key == "mouse_wheel_up" or key == "mouse_wheel_down" then
		if ScoreBoard.state then
			MouseWheel(key, "both")
		end
		cancelEvent()
		return
	end
	if searchActive and press == "down" then
		if key == "back" then
			searchBuffer = searchBuffer:sub(1, -2)
			filterPlayersList(searchBuffer)
			return
		elseif key == "delete" then
			searchBuffer = ""
			filterPlayersList(searchBuffer)
			return
		elseif key == "escape" then
			searchActive = false
			showCursor(ScoreBoard.cursorStatus)
			return
		end
	-- printable single key (letters/digits/space) or a UTF-8 character that
	-- MTA reports as a multibyte key name (Arabic etc.)
	if type(key) == "string" and #key == 1 and key:match("[%w%s]") then
		searchBuffer = searchBuffer .. key
		filterPlayersList(searchBuffer)
	elseif type(key) == "string" and #key == 2 and key:byte(1) >= 194 and key:byte(1) <= 244 then
		searchBuffer = searchBuffer .. key
		filterPlayersList(searchBuffer)
	end
	end
end

function MouseWheel(key, state)
	if not ScoreBoard.drawScroll then
		return false
	end
	if key == "mouse_wheel_down" then
		ScoreBoard.scroll = math.min(ScoreBoard.scroll + 5, 100)
	elseif key == "mouse_wheel_up" then
		ScoreBoard.scroll = math.max(ScoreBoard.scroll - 5, 0)
	end
	-- scrollY is derived from the scroll percentage in drawScrollbar
	local sp = ScoreBoard.scrollPos
	if sp and sp[4] then
		local thumbH = math.max(sp[4] / 5, 20 * s)
		ScoreBoard.scrollY = sp[2] + 1 + (sp[4] - thumbH) * (ScoreBoard.scroll / 100)
	end
end

--[[ ==================== player list ==================== ]]

function updatePlayersList()
	if ScoreBoard.state then
		ScoreBoard.players = getElementsByType("player")
		table.remove(ScoreBoard.players, 1)
		table.sort(ScoreBoard.players, function(a, b)
			return (tonumber(getPlayerID(a)) or 9999999) < (tonumber(getPlayerID(b)) or 9999999)
		end)
		ScoreBoard.players_count = (#ScoreBoard.players + 1) .. " Player" .. (#ScoreBoard.players + 1 == 1 and "" or "s")
		ScoreBoard.highestCount = math.max(ScoreBoard.highestCount, #ScoreBoard.players + 1)
		for _, p in ipairs(ScoreBoard.players) do
			if isElement(p) and not var0data[p] then
				cachePlayerData(p)
			end
		end
	end
	var0data[source] = nil
end
addEventHandler("onClientPlayerJoin", root, updatePlayersList)
addEventHandler("onClientPlayerQuit", root, updatePlayersList)

-- refresh colours / badges every second
local syncTick = 0
addEventHandler("onClientPreRender", root, function()
	if ScoreBoard.state then
		syncTick = syncTick + 1
		if syncTick % 30 == 0 then
			for _, p in ipairs(ScoreBoard.players) do
				if isElement(p) then
					cachePlayerData(p)
				end
			end
		end
	end
end)

--[[ ==================== show / hide ==================== ]]

function showScoreboard(visible)
	if visible and not (tonumber(getElementData(localPlayer, "loggedin")) == 1) then
		return false
	end
	if ScoreBoard.state == visible then
		return
	end
	ScoreBoard.state = visible
	if visible then
		if blurShader then
			dxSetShaderValue(blurShader, "sScreenSource", 0)
		end
		ScoreBoard.cursorStatus = false
		searchActive, searchBuffer = false, ""
		filterPlayersList("")
		ScoreBoard.scroll = 0
		ScoreBoard.scrollY = 0
		computeBoard()
		addEventHandler("onClientPreRender", root, ScoreBoard.draw)
		addEventHandler("onClientClick", root, ScoreBoard.click)
		addEventHandler("onClientKey", root, ScoreBoard.key)
		bindKey("mouse2", "down", CursorVisible)
		ScoreBoard.hovered = -1
		ScoreBoard.players = getElementsByType("player")
		table.remove(ScoreBoard.players, 1)
		table.sort(ScoreBoard.players, function(a, b)
			return (tonumber(getPlayerID(a)) or 9999999) < (tonumber(getPlayerID(b)) or 9999999)
		end)
		ScoreBoard.players_count = (#ScoreBoard.players + 1) .. " Player" .. (#ScoreBoard.players + 1 == 1 and "" or "s")
		ScoreBoard.highestCount = math.max(ScoreBoard.highestCount, #ScoreBoard.players + 1)
		for _, p in ipairs(ScoreBoard.players) do
			cachePlayerData(p)
		end
		cachePlayerData(localPlayer)
	else
		showCursor(false)
		ScoreBoard.cursorStatus = false
		searchActive = false
		ScoreBoard.isClickScrolbar = false
		removeEventHandler("onClientPreRender", root, ScoreBoard.draw)
		removeEventHandler("onClientClick", root, ScoreBoard.click)
		removeEventHandler("onClientKey", root, ScoreBoard.key)
		unbindKey("mouse2", "down", CursorVisible)
		var0data = {}
	end
end

bindKey("tab", "both", function(_, state)
	if state == "down" and ScoreBoard.state and ScoreBoard.cursorStatus then
		showScoreboard(false)
		return
	end
	showScoreboard(state == "down" or ScoreBoard.cursorStatus)
end)

-- meta.xml export
function isVisible()
	return ScoreBoard.state
end

-- texture / font cleanup
addEventHandler("onClientResourceStop", getResourceRootElement(getThisResource()), function()
	for _, tex in pairs(badgeTextures) do
		if isElement(tex) then destroyElement(tex) end
	end
	for _, tex in ipairs({ groupTexture, logoCircle, logoText, searchTexture }) do
		if isElement(tex) then destroyElement(tex) end
	end
	if isElement(blurShader) then destroyElement(blurShader) end
	if isElement(fontLarge) then destroyElement(fontLarge) end
	if isElement(fontUI) then destroyElement(fontUI) end
	if isElement(fontSmall) then destroyElement(fontSmall) end
end)
