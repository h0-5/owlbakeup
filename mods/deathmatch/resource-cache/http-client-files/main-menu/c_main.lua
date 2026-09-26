--[[
	PDZ Main Menu (F1)
	Faithful port of the original client "main-menu" resource.

	Original layout (all values are uiGetReferenceScreenSize() * X):
	  window         1000 x 620                 (0.75*sw x 0.65*sh)
	  sidebar menu   (5, 15) 220 x (0.65*sh)     row_height 33
	  content panel  (250, 5) (0.75*sw-130-220-30) x (0.65*sh-10)
	  title label    (0, 10) 30 high, default-large font
	  corner marks   four 10x2 bars, tocolor(255,255,255,240)
	  colors         bg tocolor(3,6,11,240) / row tocolor(19,22,27,240)
	                  card tocolor(9,12,17,180) / hover tocolor(9,12,17,100)

	Sections (id -> tab panel) exactly as the original:
	  character_info -> [Info, Vehicles, Interiors]
	  onlinestaff    -> [Admins Team, Supports Team]
	  linkdiscord    -> [notlinked, linked]
	  leaderboard    -> [Levels, Activities]
	  about          -> [discord, factions, gangs, youtube, store]

	Exports that do not exist on this server are replaced:
	  exports.roleplay.getCharacter()  -> element data on localPlayer
	  exports.roleplay:isPlayerOnline -> scoreboard player list
	  exports.UIKit                    -> plain dx calls
]]

local sw, sh = guiGetScreenSize()
local sx, sy = sw / 1920, sh / 1080

--[[ ================= theme ================= ]]

local C = {
	winAlpha	= 240,
	bg			= tocolor(3, 6, 11, 240),		-- content panel
	card		= tocolor(9, 12, 17, 180),		-- inner cards
	row			= tocolor(19, 22, 27, 240),	-- about / link rows
	rowHover	= tocolor(9, 12, 17, 100),
	selected	= tocolor(3, 6, 11, 250),
	tabSel		= tocolor(9, 12, 17, 220),
	tabHover	= tocolor(9, 12, 17, 100),
	menuBg		= tocolor(19, 22, 27, 0),
	white		= tocolor(255, 255, 255, 255),
	white70		= tocolor(255, 255, 255, 180),
	white50		= tocolor(255, 255, 255, 120),
	cornerBar	= tocolor(255, 255, 255, 240),
	green		= tocolor(0, 255, 0, 255),
	primaryR, primaryG, primaryB = 0, 168, 255
}
local function primary(a) return tocolor(C.primaryR, C.primaryG, C.primaryB, a or 255) end

local fontLarge, fontUI, fontSmall
local function createFonts()
	fontLarge = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", 24) or "default-bold"
	fontUI = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", 19) or "default"
	fontSmall = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", 16) or "default"
end
createFonts()

local blurShader = dxCreateShader("shaders/BlurShader.fx", "", 0, 0)
local logoTex = dxCreateTexture("logo-circle.png", "argb", true, "clamp")


--[[ ================= layout ================= ]]

local REF = math.min(sw / 1.7778, sh)   -- FIX: was math.min(sw, sh * 1.78) => 1920 on 1920x1080, making WIN.h = math.min(1248px (taller than the 1080px screen), sh - 40)
local R = function(v) return v * REF end		-- 0.75 * refScreenSize

local WIN = {
	w = R(0.75),
	h = R(0.65),
	x = 0, y = 0
}
local MENU = {
	x = 5, y = 15, w = 220, h = R(0.65) - 30, rowH = 33
}
local PANEL = {
	x = 220 + 30, y = 5,
	w = R(0.75) - 130 - 220 - 30,
	h = R(0.65) - 10
}
local TITLE = { x = 0, y = 10, w = PANEL.w, h = 30 }
local TABBAR_Y = 110
local TAB_H = 60

--[[ ================= state
	Declared up here on purpose: the row builder below reads it, so it has to
	exist before any function that closes over it is defined. ]]
local state = {
	open = false,
	section = "character_info",
	tab = 1,
	alpha = 0,
	hoverMenu = -1,
	hoverTab = -1,
	hoverRow = -1,
	scroll = 0,
	scrollBar = false
}


--[[ ================= data providers
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
		ID			= tonumber(getElementData(p, "account:character:id")) or tonumber(getElementData(p, "dbid")) or 0,
		Name		= tostring(getPlayerName(p)):gsub("_", " "),
		Account		= tostring(getElementData(p, "account:username") or "N/A"),
		Gender		= GENDERS[gender] or GENDERS[gender % 2] or "Male",
		GenderIcon	= (gender == 1 or gender == 3) and "female" or "male",
		BirthDate	= string.format("%02d/%02d", day, month),
		Age			= age,
		Month		= month,
		Day			= day,
		FingerPrint	= getElementData(p, "fingerprint") or "0000000000",
		Height		= tonumber(getElementData(p, "height")) or 180,
		Weight		= tonumber(getElementData(p, "weight")) or 75,
		Country		= COUNTRIES[country] or "Unknown",
		Job			= getElementData(p, "job") or "Unemployed",
		Faction		= tonumber(getElementData(p, "faction")) or 0,
		FactionRank	= tonumber(getElementData(p, "factionrank")) or 0,
		Level		= tonumber(getElementData(p, "level")) or 1,
		Exp			= tonumber(getElementData(p, "exp")) or 0,
		ExpMax		= tonumber(getElementData(p, "expmax")) or 10000,
		Balance		= convertNumber(getElementData(p, "money") or 0),
		BankAccount	= convertNumber(getElementData(p, "bank") or 0),
		Bank		= tonumber(getElementData(p, "bank")) or 0,
		Health		= tonumber(getElementData(p, "health")) or 100,
		PlayTime	= tonumber(getElementData(p, "timeinserver")) or 0
	}
end

-- 00:00:00:00  (days:hours:minutes:seconds) - exactly as the original label
local function formatPlayTime(seconds)
	seconds = tonumber(seconds) or 0
	local d = math.floor(seconds / 86400)
	local h = math.floor(seconds % 86400 / 3600)
	local m = math.floor(seconds % 3600 / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d:%02d", d, h, m, s)
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
	client cannot match it locally:

		vehicles.owner  = characters.id      (an integer)
		interiors.owner = characters.id      (an integer)

	Comparing those against localPlayer (an element) never matches, which is
	why the tabs used to stay empty. Everything is now requested from
	s_main.lua, which joins on the real character id.

	The two placeholder systems (leaderboard / discord) get their empty tables
	from the server too, so the layout is identical and only the data is
	missing until the real systems are wired in. ]]

local cache = {
	vehicles   = {},
	interiors  = {},
	staff      = { admins = {}, supports = {} },
	leaderboard = { levels = {}, activities = {} },
	discord    = { linked = false, code = "", tag = "" }
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
	return cx * sw >= x and cx * sw <= x + w and cy * sh >= y and cy * sh <= y + h
end

local function text(str, x1, y1, x2, y2, color, scale, font, ax, ay, shadow)
	dxDrawText(tostring(str), x1, y1, x2, y2, color, scale or 1, font or fontUI,
		ax or "left", ay or "center", shadow ~= false, shadow == true, false)
end

-- four 10x2 corner bars
local function drawCorners(x, y, w, h)
	local L, T = 10, 2
	dxDrawRectangle(x, y, L, T, C.cornerBar, false)
	dxDrawRectangle(x + w - L, y, L, T, C.cornerBar, false)
	dxDrawRectangle(x, y + h - T, L, T, C.cornerBar, false)
	dxDrawRectangle(x + w - L, y + h - T, L, T, C.cornerBar, false)
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


--[[ ================= state ================= ]]

-- the original sidebar, exactly as eui:uiMenuAddButton order
local SECTIONS = {
	{ "character_info", "Personal Info" },
	{ "onlinestaff", "Online Staff" },
	{ "leaderboard", "Leaderboard" },
	{ "linkdiscord", "Link Discord" },
	{ "about", "About Server" }
}
local TABS = {
	character_info	= { "Info", "Vehicles", "Interiors" },
	onlinestaff		= { "Admins Team", "Supports Team" },
	linkdiscord		= { "notlinked", "linked" },
	leaderboard		= { "Levels", "Activities" },
	about			= { "discord", "factions", "gangs", "youtube", "store" }
}

local function getSectionTitle(id)
	for _, s in ipairs(SECTIONS) do
		if s[1] == id then return s[2] end
	end
	return ""
end

--[[ ================= rendering ================= ]]

local function drawMenu()
	local mx, my, mw, mh = MENU.x, MENU.y, MENU.w, MENU.h

	-- sidebar background
	dxDrawRectangle(mx, my, mw, mh, C.menuBg, true)

	-- sidebar rows
	for i, sec in ipairs(SECTIONS) do
		local y = my + i * MENU.rowH - MENU.rowH
		local selected = (state.section == sec[1])
		local hovered = (state.hoverMenu == i) and not selected

		if selected then
			dxDrawRectangle(mx + 1, y, 3, MENU.rowH, primary(), true)
		end
		if hovered then
			dxDrawRectangle(mx, y, mw, MENU.rowH, C.rowHover, true)
		end
		text(sec[2], mx + 20, y, mx + mw - 10, y + MENU.rowH,
			selected and primary() or C.white70, 1, selected and fontLarge or fontUI, "left", "center")
	end

	-- title
	text(getSectionTitle(state.section), PANEL.x + TITLE.x, PANEL.y, PANEL.x + TITLE.w,
		PANEL.y + TITLE.h, C.white, 1.1, fontLarge, "left", "center")

	-- tab bar
	local tabs = TABS[state.section] or {}
	local tabW = PANEL.w / math.max(#tabs, 1)
	for i = 1, #tabs do
		local x = PANEL.x + (i - 1) * tabW
		local selected = (state.tab == i)
		if selected then
			dxDrawRectangle(x, TABBAR_Y, tabW, TAB_H, C.tabSel, true)
			dxDrawRectangle(x, TABBAR_Y + TAB_H - 2, tabW, 2, primary(), true)
		elseif state.hoverTab == i then
			dxDrawRectangle(x, TABBAR_Y, tabW, TAB_H, C.tabHover, true)
		end
		text(tabs[i], x, TABBAR_Y, x + tabW, TABBAR_Y + TAB_H,
			selected and C.white or C.white50, 1, selected and fontUI or fontSmall, "center", "center")
	end

	-- rows
	local rows = buildRows()
	local listY = TABBAR_Y + TAB_H + 12
	local rowH = 30
	local listH = PANEL.y + PANEL.h - listY - 10
	local visible = math.floor(listH / rowH)
	local maxScroll = math.max(0, #rows - visible)
	if state.scroll > maxScroll then state.scroll = maxScroll end

	for i = state.scroll + 1, math.min(#rows, state.scroll + visible) do
		local row = rows[i]
		local y = listY + (i - state.scroll - 1) * rowH
		local hovered = (state.hoverRow == i)

		dxDrawRectangle(PANEL.x + 5, y + 1, PANEL.w - 10, rowH - 4, C.card, true)
		if hovered then
			dxDrawRectangle(PANEL.x + 5, y + 1, PANEL.w - 10, rowH - 4, C.rowHover, true)
		end
		dxDrawRectangle(PANEL.x + 5, y + 1, 2, rowH - 4,
			row[1] == "title" and primary() or tocolor(255, 255, 255, 40), true)

		if row[1] == "title" then
			-- single line (vehicles / staff / leaderboard / about)
			text(row[2], PANEL.x + 20, y + 1, PANEL.x + PANEL.w - 20, y + rowH - 3, row[3], 1, fontUI, "left", "center")
		else
			-- key on the right, value on the left
			text(row[1], PANEL.x + PANEL.w - 200, y + 1, PANEL.x + PANEL.w - 20, y + rowH - 3,
				C.white50, 1, fontUI, "right", "center")
			text(row[2], PANEL.x + 20, y + 1, PANEL.x + PANEL.w - 210, y + rowH - 3,
				row[3], 1, fontUI, "left", "center")
		end
	end

	-- scrollbar
	if #rows > visible then
		local barH = math.max(30, listH * (visible / #rows))
		local maxY = listY + listH - barH
		local barY = listY + (maxY - listY) * (maxScroll > 0 and (state.scroll / maxScroll) or 0)
		dxDrawRectangle(PANEL.x + PANEL.w - 6, listY, 3, listH, tocolor(255, 255, 255, 25), true)
		dxDrawRectangle(PANEL.x + PANEL.w - 6, barY, 3, barH, primary(210), true)
		state.scrollBar = { x = PANEL.x + PANEL.w - 10, y = listY, w = 10, h = listH, barY = barY, barH = barH }
	end

	drawCorners(PANEL.x, PANEL.y, PANEL.w, PANEL.h)
end

--[[ ================= draw ================= ]]

local updateHover	-- forward declaration (defined in the interaction block below)

local function onRender()
	if not state.open then return end

	-- the original ran the hover pass first, then painted
	updateHover()

	-- fade the game out a bit (original: var0.alpha animation 255 -> 0)
	local overlay = math.max(0, 255 - state.alpha)
	dxDrawRectangle(0, 0, sw, sh, tocolor(0, 0, 0, math.max(0, overlay - 80)), false)

	-- window
	WIN.x = (sw - WIN.w) / 2
	WIN.y = (sh - WIN.h) / 2
	dxDrawRectangle(WIN.x, WIN.y, WIN.w, WIN.h, C.bg, true)

	-- logo
	if logoTex then
		dxDrawImage(WIN.x + 14, WIN.y + 14, 34, 34, logoTex, 0, 0, 0, C.white, true)
	end

	drawMenu()

	-- corners of the whole window
	drawCorners(WIN.x, WIN.y, WIN.w, WIN.h)
end

--[[ ================= interaction ================= ]]

-- NOTE: assigned (not `local function`) on purpose. A `local function` here
-- would declare a second local that shadows the forward declaration above,
-- leaving onRender() calling nil and throwing on every frame.
updateHover = function()
	state.hoverMenu, state.hoverTab, state.hoverRow = -1, -1, -1
	if not isCursorShowing() then return end

	-- sidebar
	for i = 1, #SECTIONS do
		local y = MENU.y + (i - 1) * MENU.rowH
		if isMouseIn(MENU.x, y, MENU.w, MENU.rowH) then
			state.hoverMenu = i
			return
		end
	end

	-- tabs
	local tabs = TABS[state.section] or {}
	local tabW = PANEL.w / math.max(#tabs, 1)
	if isMouseIn(PANEL.x, TABBAR_Y, PANEL.w, TAB_H) then
		state.hoverTab = math.floor((getCursorPosition() * sw - PANEL.x) / tabW) + 1
		return
	end

	-- rows
	local rows = buildRows()
	local listY = TABBAR_Y + TAB_H + 12
	local rowH = 30
	local listH = PANEL.y + PANEL.h - listY - 10
	local visible = math.floor(listH / rowH)
	if isMouseIn(PANEL.x, listY, PANEL.w, listH) then
		local idx = state.scroll + math.floor((getCursorPosition() * sh - listY) / rowH) + 1
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
	local rows = buildRows()
	local listY = TABBAR_Y + TAB_H + 12
	local rowH = 30
	local listH = PANEL.y + PANEL.h - listY - 10
	local visible = math.max(1, math.floor(listH / rowH))
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
		-- full-screen render target for the blur: must be in PIXELS, not the
		-- sw/1920 ratio used by the layout code
		dxSetRenderTarget(blurShader, 0, 0, 0, sw, sh)
		dxSetBlurShaderEnabled(blurShader, true, 4)
		state.alpha = 255
		-- pull fresh data every time the menu opens, so a vehicle bought or an
		-- interior bought since the last open shows up immediately
		requestAll()
	else
		dxSetBlurShaderEnabled(blurShader, false)
	end
end

-- warm the cache on login so the first F1 press is not empty
addEvent("onClientResourceStart", resourceRoot, function()
	setTimer(function()
		if isElement(localPlayer) then requestAll() end
	end, 2000, 1)
end)

bindKey("F1", "down", function()
	setOpen(not state.open)
end)
bindKey("F1", "up", function() end)

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
	if blurShader then dxSetBlurShaderEnabled(blurShader, false); destroyShader(blurShader) end
	if logoTex then destroyTexture(logoTex) end
	destroyFont(fontLarge)
	destroyFont(fontUI)
	destroyFont(fontSmall)
end)

-- exports used by other resources
function isOpen() return state.open end
function toggleMenu() setOpen(not state.open) end

