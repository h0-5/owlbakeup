--------------------------------------------------------------------------------
-- VORTEX nametags — client
-- Ported from the old client source (backupm hud drawPlayersName):
--   * rank title above the name (rank:name / rank:color pushed by staff_manager)
--   * name colored by staff rank, "Unknown Person" for masked players
--   * ((TYPING...)) animated indicator while a player is writing
--   * AFK badge, admin visibility hiding, 8-unit range + line of sight
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

local NAMETAG_DISTANCE = 8

local playersHud = {}   -- [player] = { name, title, titleColor, icons, hidden }
local typing = {}       -- [player] = true while chatting
local localTyping = false

-- UIKit fonts (same as old client), with stock fallbacks
local dxFontDefault, dxFontHud

local function UIKitReady()
	local ok, eui = pcall(function() return exports.UIKit end)
	if not ok or not eui then return end
	dxFontDefault = eui:getUIFont("ui-default")
	dxFontHud = eui:getUIFont("hud")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function fontDefault() return dxFontDefault or "default-bold" end
local function fontHud() return dxFontHud or "default" end

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY)
	local black = tocolor(0, 0, 0, 255)
	dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY, false, false, true)
	dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY, false, false, true)
	dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY, false, false, true)
	dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY, false, false, true)
	dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, true)
end

--------------------------------------------------------------------------------
-- cache rebuild (old client updatePlayersHud)
--------------------------------------------------------------------------------
local function buildPlayerEntry(player)
	local hidden = getElementData(player, "hiddenadmin") == 1
		or getElementData(player, "admin:hideadmin")

	local masked = getElementData(player, "fakename")
	local name = masked and "Unknown Person"
		or getPlayerName(player):gsub("_", " ")

	-- staff rank pushed by admin-system/staff_manager
	local title = getElementData(player, "rank:name")
	local rgb = getElementData(player, "rank:color")
	if type(rgb) ~= "table" or #rgb < 3 then rgb = { 255, 255, 255 } end

	-- friends were colored white in the old client (friend-system guarded)
	local friend = player == localPlayer
	local friendSys = getResourceFromName("friend-system")
	if not friend and friendSys and getResourceState(friendSys) == "running" then
		local ok, isFriend = pcall(function() return exports["friend-system"]:isFriend(player) end)
		if ok then friend = isFriend and true or false end
	end

	local icons = {}
	if getElementData(player, "temp:AFK") then
		table.insert(icons, "AFK")
	end

	return {
		name = name,
		title = (type(title) == "string" and title ~= "") and title or nil,
		titleColor = tocolor(rgb[1], rgb[2], rgb[3], 255),
		color = tocolor(rgb[1], rgb[2], rgb[3], 255),
		icons = icons,
		hidden = hidden and true or false,
		friend = friend,
	}
end

local function updatePlayersHud()
	playersHud = {}
	for _, player in ipairs(getElementsByType("player")) do
		if isElement(player) and isElementStreamedIn(player) then
			playersHud[player] = buildPlayerEntry(player)
		end
	end
end

local CACHE_KEYS = {
	["rank:name"] = true, ["rank:color"] = true, ["fakename"] = true,
	["temp:AFK"] = true, ["hiddenadmin"] = true, ["admin:hideadmin"] = true,
	["character:name"] = true,
}
addEventHandler("onClientElementDataChange", root, function(key, _, _value)
	if CACHE_KEYS[key] and isElement(source) and getElementType(source) == "player" then
		if isElementStreamedIn(source) then
			playersHud[source] = buildPlayerEntry(source)
		end
	end
end)
addEventHandler("onClientElementStreamIn", root, function()
	if getElementType(source) == "player" then
		playersHud[source] = buildPlayerEntry(source)
	end
end)
addEventHandler("onClientElementStreamOut", root, function()
	if typing[source] then typing[source] = nil end
	if playersHud[source] then playersHud[source] = nil end
end)
addEventHandler("onClientPlayerQuit", root, function()
	typing[source] = nil
	playersHud[source] = nil
end)

--------------------------------------------------------------------------------
-- typing sync (old client: latent server event, server relays to nearby)
--------------------------------------------------------------------------------
local function checkLocalTyping()
	local active = isChatBoxInputActive()
	if active and not localTyping then
		localTyping = true
		triggerLatentServerEvent("typing:sync", 20000, localPlayer, true)
	elseif not active and localTyping then
		localTyping = false
		triggerLatentServerEvent("typing:sync", 20000, localPlayer, false)
	end
end
setTimer(checkLocalTyping, 200, 0)

addEvent("typing:sync", true)
addEventHandler("typing:sync", root, function(state)
	typing[source] = state and true or nil
end)

--------------------------------------------------------------------------------
-- draw (old client drawPlayersName)
--------------------------------------------------------------------------------
local WaitTyping = 0

addEventHandler("onClientRender", root, function()
	if isPlayerMapVisible() then return end
	if not isHudShowing or not isHudShowing() then return end
	if not getHudSetting or getHudSetting("tagmode") == false then return end
	if getElementData(localPlayer, "loggedin") ~= 1
		and not getElementData(localPlayer, "character:id") then return end

	local camX, camY, camZ = getCameraMatrix()
	local lX, lY, lZ = getElementPosition(localPlayer)

	for player, entry in pairs(playersHud) do
		if player ~= localPlayer and isElement(player) and entry and not entry.hidden then
			local pX, pY, pZ = getElementPosition(player)
			local distance = getDistanceBetweenPoints3D(lX, lY, lZ, pX, pY, pZ)
			if distance <= NAMETAG_DISTANCE then
				local hx, hy, hz = getPedBonePosition(player, 6)
				if hx then
					local sX, sY = getScreenFromWorldPosition(hx, hy, hz + 0.42)
					if sX then
						-- line of sight (skip when blocked), recon ignores it
						local blocked = processLineOfSight(camX, camY, camZ, hx, hy, hz + 0.4,
							true, true, false, true, false, false, false, false)
						local recon = getElementData(localPlayer, "reconx")
						if not blocked or recon then
							local baseY = sY

							-- rank title above the name (old client badge text)
							if entry.title then
								outlineText(entry.title, sX - 120, baseY - 34, 240, 15,
									entry.titleColor, 0.8, fontHud(), "center", "top")
								baseY = baseY + 2
							end

							-- ((TYPING...)) animated dots
							if typing[player] then
								local now = getTickCount()
								if now - WaitTyping > 4000 then
									WaitTyping = now
								end
								local dots = string.rep(".", math.floor((now - WaitTyping) / 1000) % 4)
								outlineText("((TYPING" .. dots .. "))", sX - 120, baseY - 52, 240, 15,
									tocolor(255, 255, 255, 255), 0.8, fontHud(), "center", "top")
							end

							-- the name
							outlineText(entry.name, sX - 120, baseY - 22, 240, 18,
								entry.color, 1, fontDefault(), "center", "top")

							-- AFK badge under the name
							if #entry.icons > 0 then
								local iconY = baseY + 2
								for _, icon in ipairs(entry.icons) do
									local path = icon == "AFK" and "images/hud/afk.png" or nil
									if path and fileExists(path) then
										dxDrawImage(sX - 10, iconY, 20, 20, path, 0, 0, 0,
											tocolor(255, 255, 255, 230), true)
										iconY = iconY + 22
									end
								end
							end
						end
					end
				end
			end
		end
	end
end, false, "high-2")

updatePlayersHud()
