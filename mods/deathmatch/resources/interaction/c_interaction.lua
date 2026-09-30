-- interaction - Owl old-client port (Fix #59)
-- Reconstructed from arma-backupm/[rp]/interaction/client_decompiled.lua.
-- Right-click interaction menu shared by every Owl system (ped Talk/Edit,
-- bank, fuel, jobs, ...). Systems hook in through:
--   * onClientElementMenuShow(element, distance, elementType)
--   * onClientElementMenuClick(element, text, data)
--   * exports.interaction:addInteractOption(element, {text, data})
--   * exports.interaction:executeInteractOption(element, {text, data})
--
-- NOT ported: vehicle-door click toggling (server vehicles:doorsControl did
-- not survive the backup) and the decorative cursor ring.

local function isServerElement(element)
	-- isElementLocal exists on MTA 1.6+; on 1.5.9 treat every element as server-synced
	if isElementLocal and isElementLocal(element) then
		return false
	end
	return true
end

local menu = {
	status = false,
	currentElement = false,
	currentOptions = {},
	title = "",
	hovered = 0,
	pos = { 0, 0 },
	renderAttached = false,
}
local lastGUIClickTick = 0

local screenW, screenH = guiGetScreenSize()

-- Owl's decompile exposes menu state through isInteractionOptionsShowing()
local function dxDrawRoundedRectangle(x, y, w, h, color, radius, postGUI)
	radius = radius or 6
	local rx, ry = math.floor(x + radius), math.floor(y + radius)
	local rw, rh = math.floor(w - radius * 2), math.floor(h - radius * 2)
	if rw < 1 or rh < 1 then
		dxDrawRectangle(x, y, w, h, color, postGUI)
		return
	end
	dxDrawRectangle(rx - radius, ry, rw + radius * 2, rh, color, postGUI)
	dxDrawRectangle(rx, ry - radius, rw, radius, color, postGUI)
	dxDrawRectangle(rx, ry + rh, rw, radius, color, postGUI)
	dxDrawCircle(rx, ry, radius, 180, 270, color, color, 7, _, postGUI)
	dxDrawCircle(rx + rw, ry, radius, 270, 360, color, color, 7, _, postGUI)
	dxDrawCircle(rx, ry + rh, radius, 90, 180, color, color, 7, _, postGUI)
	dxDrawCircle(rx + rw, ry + rh, radius, 0, 90, color, color, 7, _, postGUI)
end

bindKey("m", "down", function(key, keyState)
	if not getElementData(localPlayer, "character:id") then
		return
	end
	showCursor(not isCursorShowing())
end)

addEventHandler("onClientGUIClick", root, function()
	lastGUIClickTick = getTickCount()
end)
addEventHandler("onClientGUIDoubleClick", root, function()
	lastGUIClickTick = getTickCount()
end)

local function findElementUnderPosition(wx, wy, wz)
	local int, dim = getElementInterior(localPlayer), getElementDimension(localPlayer)
	-- players first (dead players excluded)
	for _, element in ipairs(getElementsWithinRange(wx, wy, wz, 20, "player", int, dim)) do
		if not isPedDead(element) then
			return element
		end
	end
	-- items / objects carrying interaction data
	for _, element in ipairs(getElementsWithinRange(wx, wy, wz, 20, "object", int, dim)) do
		if getElementData(element, "item:data") or getElementData(element, "rightclick:menu") then
			return element
		end
	end
	-- [Fix #63] vehicles (the mechanic panel injects its option on
	-- onClientElementMenuShow - the encrypted Owl interaction client
	-- supported vehicle right-clicks the same way)
	for _, element in ipairs(getElementsWithinRange(wx, wy, wz, 20, "vehicle", int, dim)) do
		if getElementData(element, "rightclick:menu") then
			return element
		end
	end
	for _, element in ipairs(getElementsWithinRange(wx, wy, wz, 20, "pickup", int, dim)) do
		return element
	end
	for _, element in ipairs(getElementsWithinRange(wx, wy, wz, 20, "marker", int, dim)) do
		return element
	end
	return false
end

local function findViableElement(losElement, wx, wy, wz)
	if isElement(losElement) and getElementType(losElement) == "ped" then
		return losElement
	end
	local found = findElementUnderPosition(wx, wy, wz)
	if found then
		return found
	end
	return false
end

function showInteract(element, absoluteX, absoluteY)
	if getTickCount() - lastGUIClickTick <= 300 then
		return
	end
	if menu.currentElement == element then
		menu.pos = { absoluteX, absoluteY }
		return
	end
	menu.status = true
	menu.currentElement = element
	menu.currentOptions = getElementData(element, "rightclick:menu") or {}
	menu.title = getElementData(element, "rightclick:title") or ""
	menu.hovered = 0
	menu.pos = { absoluteX, absoluteY }
	if not menu.renderAttached then
		addEventHandler("onClientRender", root, menuRender)
		menu.renderAttached = true
	end
	local px, py, pz = getElementPosition(localPlayer)
	local ex, ey, ez = getElementPosition(element)
	triggerEvent("onClientElementMenuShow", localPlayer, element, getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez), getElementType(element))
	if isServerElement(element) then
		triggerServerEvent("onClientElementMenuShow:Server", localPlayer, element, getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez))
	end
end

function hideInteract()
	if menu.status then
		if menu.renderAttached then
			removeEventHandler("onClientRender", root, menuRender)
			menu.renderAttached = false
		end
		menu.status = false
		menu.hovered = 0
		menu.currentElement = false
		menu.currentOptions = false
		menu.title = ""
	end
end

function closeInteraction()
	hideInteract()
end

function isInteractionOptionsShowing()
	return menu.currentOptions
end

function menuRender()
	if not isCursorShowing() then
		hideInteract()
		return
	end
	if not isElement(menu.currentElement) then
		hideInteract()
		return
	end
	local baseX, baseY = menu.pos[1], menu.pos[2]
	local options = menu.currentOptions or {}
	local rows = math.max(#options, 1)
	local width = 180
	local height = 25 + rows * 28
	dxDrawText(tostring(menu.title), baseX, baseY, baseX + width, baseY + 20, tocolor(255, 255, 255, 255), 1, "default-bold", "left", "top", true, false, true, true, false)
	menu.hovered = 0
	local cx, cy = getCursorPosition()
	if cx then
		cx, cy = cx * screenW, cy * screenH
		for index = 1, #options do
			local rowY = baseY + 25 + (index - 1) * 28
			if cx >= baseX and cx <= baseX + width and cy >= rowY and cy <= rowY + 28 then
				menu.hovered = index
			end
		end
	end
	dxDrawRoundedRectangle(baseX, baseY + 25, width, height - 25, tocolor(6, 9, 14, 235), 6, true)
	for index = 1, #options do
		local rowY = baseY + 25 + (index - 1) * 28
		local option = options[index]
		local label = tostring(option.Data and option.Data.label or option.Text)
		local isAdmin = string.find(tostring(option.Text), "Admin", 1, true) and true or false
		if index == menu.hovered then
			dxDrawRectangle(baseX + 2, rowY, width - 4, 28, tocolor(255, 255, 255, 25), true)
			dxDrawText(label, baseX + 25, rowY, baseX + width, rowY + 28, isAdmin and tocolor(255, 0, 0, 255) or tocolor(255, 255, 255, 255), 1, "default-bold", "left", "center", true, false, true, true, false)
		else
			dxDrawText(label, baseX + 10, rowY, baseX + width, rowY + 28, isAdmin and tocolor(255, 0, 0, 150) or tocolor(255, 255, 255, 150), 1, "default-bold", "left", "center", true, false, true, true, false)
		end
	end
end

local function onCursorClick(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
	if isPedDead(localPlayer) then
		return
	end
	if button == "right" and state == "up" then
		local target = false
		if isElement(clickedElement) and getElementType(clickedElement) == "ped" then
			target = clickedElement
		end
		if not target then
			local los = false
			local cx, cy, cz, ctx, cty, ctz = getCameraMatrix()
			local hit, hitX, hitY, hitZ, hitElement = processLineOfSight(cx, cy, cz, ctx, cty, ctz)
			if hit then
				los = hitElement
				if isElement(los) and getElementType(los) == "ped" then
					target = los
				end
			end
			if not target then
				target = findViableElement(los, hitX or worldX or cx, hitY or worldY or cy, hitZ or worldZ or cz)
			end
		end
		if target then
			showInteract(target, absoluteX, absoluteY)
		else
			hideInteract()
		end
	elseif button == "left" and state == "down" then
		if menu.status then
			if menu.hovered ~= 0 and menu.currentOptions and isElement(menu.currentElement) then
				local option = menu.currentOptions[menu.hovered]
				triggerEvent("onClientElementMenuClick", localPlayer, menu.currentElement, option.Text, option.Data)
				if isServerElement(menu.currentElement) then
					triggerServerEvent("onClientElementMenuClick:Server", localPlayer, menu.currentElement, option.Text, option.Data)
				end
			end
			hideInteract()
		elseif not isElement(clickedElement) then
			hideInteract()
		end
	end
end
addEventHandler("onClientClick", root, onCursorClick)

addEvent("onClientElementMenuClick", false)
addEvent("onClientElementMenuShow", false)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeInteraction)
addEventHandler("onClientPlayerWasted", localPlayer, closeInteraction)

-------------------------------------------------------------------------------
-- Option injection API
-------------------------------------------------------------------------------
function addInteractOption(element, option)
	if menu.currentElement ~= element then
		return false
	end
	if type(option) ~= "table" or not option.text then
		return false
	end
	if string.find(option.text, "Admin", 1, true) and exports.hud and not exports.hud:getHudSetting("admintag") then
		return false
	end
	menu.currentOptions = menu.currentOptions or {}
	for _, existing in ipairs(menu.currentOptions) do
		if existing.Text == option.text then
			return false
		end
	end
	table.insert(menu.currentOptions, { Text = option.text, Data = option.data })
	return true
end

function executeInteractOption(element, option)
	if type(option) ~= "table" or not option.text then
		return false
	end
	triggerEvent("onClientElementMenuClick", localPlayer, element, option.text, option.data)
	if isServerElement(element) then
		triggerServerEvent("onClientElementMenuClick:Server", localPlayer, element, option.text, option.data)
	end
	return true
end

addEvent("interaction:addInteractOption", true)
addEventHandler("interaction:addInteractOption", root, function(element, option)
	addInteractOption(element, option)
end)
addEvent("interaction:addInteractOptions", true)
addEventHandler("interaction:addInteractOptions", root, function(element, options)
	for index = 1, #options do
		addInteractOption(element, options[index])
	end
end)

-------------------------------------------------------------------------------
-- /nearbyitems - debug listing of nearby M.E.O item objects
-------------------------------------------------------------------------------
addCommandHandler("nearbyitems", function()
	if not getElementData(localPlayer, "character:id") then
		return
	end
	local px, py, pz = getElementPosition(localPlayer)
	local int, dim = getElementInterior(localPlayer), getElementDimension(localPlayer)
	local found = {}
	for _, element in ipairs(getElementsWithinRange(px, py, pz, 5, "object", int, dim)) do
		if getElementData(element, "item:data") and tonumber(getElementPosition(element)) then
			table.insert(found, element)
		end
	end
	outputChatBox("Nearby Items:", 255, 55, 95)
	for _, element in ipairs(found) do
		local elementID = getElementID(element)
		if elementID and string.find(elementID, "M.E.O:", 1, true) then
			local data = getElementData(element, "item:data") or {}
			outputChatBox("  Item ID: " .. tostring(elementID) .. " | Item name: " .. tostring(data.Name or "N/A"), 255, 55, 95)
		end
	end
end, false, false)
