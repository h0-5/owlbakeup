-- ped-system - Owl old-client port (Fix #59)
-- Faithful reconstruction of arma-backupm/[rp]/ped-system/ped_c_decompiled.lua.
-- Decompiler artifacts repaired:
--   * var0/var1 collapsed globals split back into their real roles
--     (interact types / weapon ids / nearby peds / shoot counters / timers / font)
--   * lost multi-return unpacking restored (positions, rotations, camera matrix)
--   * lost accumulators restored (talk candidate list, combobox indices)
--   * broken shoot-timer check restored (shootTimers[ped], not the whole table)
--   * drawPedsName shadow + colorCoded text args restored (font via UIKit)

local PEDS_NEARBY_REFRESH = 1500
local NAME_DRAW_DISTANCE = 15
local TALK_DISTANCE = 3

GUIEditor = {
	scrollpane = {},
	edit = {},
	button = {},
	label = {},
	staticimage = {},
	combobox = {},
}

-- Interact types accepted in the editor combobox (values recovered from the
-- old-client system resources that route ped:interact).
local interactTypes = {
	"", "seller", "skins", "clothes.shop", "furniture.shop", "bank",
	"activities", "jobs", "job.gunsmith", "job.drug_dealer", "job.liquor_dealer",
	"traffic.tickets", "traffic.ownership_transfer", "traffic.impound",
	"offenses", "identity", "change_name", "electric", "key.duplicator",
	"sell.materials", "sell.crops", "airport.travel",
}

local weaponIDs = { 2, 3, 4, 5, 6, 7, 8, 9, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34 }

skins = {
	[0] = { 7, 14, 15, 17, 20, 21, 24, 25, 26, 29, 35, 36, 37, 44, 46, 57, 58, 59, 60, 68, 72, 98, 147, 185, 186, 187, 223, 227, 228, 234, 235, 240, 258, 259 },
	[1] = { 9, 11, 12, 40, 41, 55, 56, 69, 76, 88, 89, 91, 93, 129, 130, 141, 148, 150, 151, 190, 191, 192, 193, 194, 196, 211, 215, 216, 219, 224, 225, 226, 233, 263 },
}

local nearbyPeds = {}     -- refreshed by the 1500ms loop (camera range)
local shootCounts = {}    -- ped -> consecutive defence shots
local shootTimers = {}    -- ped -> defence timer
local talkHintShown = false
local dxFont = "default-bold"
local namesRenderAttached = false

addEventHandler("onClientResourceStart", resourceRoot, function()
	GUIEditor.staticimage[1] = guiCreateStaticImage(49, 148, 264, 422, ":interface/rectangle.png", false)
	guiSetProperty(GUIEditor.staticimage[1], "ImageColours", "tl:DD000000 tr:DD000000 bl:DD000000 br:DD000000")
	guiSetVisible(GUIEditor.staticimage[1], false)
	GUIEditor.staticimage[2] = guiCreateStaticImage(0, 0, 264, 31, ":interface/rectangle.png", false, GUIEditor.staticimage[1])
	guiSetProperty(GUIEditor.staticimage[2], "ImageColours", "tl:FE000000 tr:FE000000 bl:FE000000 br:FE000000")
	GUIEditor.label[1] = guiCreateLabel(0, 0, 264, 31, "SETTING", false, GUIEditor.staticimage[2])
	guiLabelSetHorizontalAlign(GUIEditor.label[1], "center", false)
	guiLabelSetVerticalAlign(GUIEditor.label[1], "center")
	GUIEditor.staticimage[3] = guiCreateStaticImage(0, 31, 264, 2, ":interface/rectangle.png", false, GUIEditor.staticimage[1])
	guiSetProperty(GUIEditor.staticimage[3], "ImageColours", "tl:FFAD0000 tr:FFAD0000 bl:FFAD0000 br:FFAD0000")
	GUIEditor.scrollpane[1] = guiCreateScrollPane(10, 43, 254, 343, false, GUIEditor.staticimage[1])
	GUIEditor.label[2] = guiCreateLabel(10, 0, 244, 15, "ID: 0000", false, GUIEditor.scrollpane[1])
	GUIEditor.label[3] = guiCreateLabel(10, 17, 69, 23, "Name:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[3], "center")
	GUIEditor.edit[1] = guiCreateEdit(79, 17, 160, 23, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[1], 0.8)
	GUIEditor.label[4] = guiCreateLabel(10, 44, 69, 21, "Interact:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[4], "center")
	GUIEditor.combobox[1] = guiCreateComboBox(79, 44, 160, 300, "", false, GUIEditor.scrollpane[1])
	for _, interactType in ipairs(interactTypes) do
		guiComboBoxAddItem(GUIEditor.combobox[1], interactType)
	end
	GUIEditor.label[5] = guiCreateLabel(10, 75, 69, 23, "Skin:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[5], "center")
	GUIEditor.label[6] = guiCreateLabel(10, 98, 244, 15, "Position:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[6], "center")
	GUIEditor.label[7] = guiCreateLabel(10, 119, 31, 20, "X:", false, GUIEditor.scrollpane[1])
	guiLabelSetHorizontalAlign(GUIEditor.label[7], "center", false)
	guiLabelSetVerticalAlign(GUIEditor.label[7], "center")
	GUIEditor.edit[2] = guiCreateEdit(51, 119, 188, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[2], 0.8)
	GUIEditor.label[8] = guiCreateLabel(10, 139, 31, 20, "Y:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[8], "center")
	GUIEditor.label[9] = guiCreateLabel(10, 159, 31, 20, "Z:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[9], "center")
	GUIEditor.edit[3] = guiCreateEdit(51, 139, 188, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[3], 0.8)
	GUIEditor.edit[4] = guiCreateEdit(51, 159, 188, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[4], 0.8)
	GUIEditor.combobox[2] = guiCreateComboBox(79, 75, 160, 200, "", false, GUIEditor.scrollpane[1])
	guiComboBoxAddItem(GUIEditor.combobox[2], "0")
	GUIEditor.label[10] = guiCreateLabel(10, 179, 51, 20, "Rotation:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[10], "center")
	GUIEditor.edit[5] = guiCreateEdit(81, 179, 158, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[5], 0.8)
	GUIEditor.label[11] = guiCreateLabel(10, 209, 61, 20, "Interior:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[11], "center")
	GUIEditor.edit[6] = guiCreateEdit(81, 209, 158, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[6], 0.8)
	GUIEditor.label[12] = guiCreateLabel(10, 229, 61, 20, "Dimension:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[12], "center")
	GUIEditor.edit[7] = guiCreateEdit(81, 229, 158, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[7], 0.8)
	GUIEditor.label[13] = guiCreateLabel(10, 264, 61, 20, "Frozen:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[13], "center")
	GUIEditor.combobox[3] = guiCreateComboBox(81, 264, 158, 69, "", false, GUIEditor.scrollpane[1])
	guiComboBoxAddItem(GUIEditor.combobox[3], "true")
	guiComboBoxAddItem(GUIEditor.combobox[3], "false")
	GUIEditor.label[14] = guiCreateLabel(10, 303, 229, 15, "Type:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[14], "center")
	GUIEditor.combobox[4] = guiCreateComboBox(10, 323, 229, 198, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.combobox[4], 0.8)
	guiComboBoxAddItem(GUIEditor.combobox[4], "immortal: (almost) never dies")
	guiComboBoxAddItem(GUIEditor.combobox[4], "scared: will put hands up or crouch down upon being attacked")
	guiComboBoxAddItem(GUIEditor.combobox[4], "defending: will try to shoot back upon being attacked (given it has a weapon, otherwise punch)")
	guiComboBoxAddItem(GUIEditor.combobox[4], "immortal: (almost) never dies (duplicate to 0)")
	guiComboBoxAddItem(GUIEditor.combobox[4], "pannicing: will run away in pannic upon being attacked")
	guiComboBoxAddItem(GUIEditor.combobox[4], "public transport user: will enter any operated trams")
	GUIEditor.label[15] = guiCreateLabel(10, 355, 229, 15, "Shop ID (for seller interact):", false, GUIEditor.scrollpane[1])
	GUIEditor.edit[8] = guiCreateEdit(10, 375, 229, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[8], 0.8)
	GUIEditor.label[16] = guiCreateLabel(10, 405, 229, 15, "Weapon:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[16], "center")
	GUIEditor.combobox[5] = guiCreateComboBox(10, 425, 229, 198, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.combobox[5], 0.8)
	for _, weaponID in ipairs(weaponIDs) do
		guiComboBoxAddItem(GUIEditor.combobox[5], getWeaponNameFromID(weaponID))
	end
	GUIEditor.label[17] = guiCreateLabel(10, 460, 229, 15, "Gates ID:", false, GUIEditor.scrollpane[1])
	GUIEditor.edit[9] = guiCreateEdit(10, 480, 229, 20, "", false, GUIEditor.scrollpane[1])
	guiSetAlpha(GUIEditor.edit[9], 0.8)
	GUIEditor.label[18] = guiCreateLabel(10, 520, 229, 15, "Animation:", false, GUIEditor.scrollpane[1])
	guiLabelSetVerticalAlign(GUIEditor.label[18], "center")
	GUIEditor.combobox[6] = guiCreateComboBox(10, 540, 229, 195, "", false, GUIEditor.scrollpane[1])
	GUIEditor.combobox[7] = guiCreateComboBox(10, 565, 229, 195, "", false, GUIEditor.scrollpane[1])
	GUIEditor.button[1] = guiCreateButton(6, 392, 82, 26, "CLOSE", false, GUIEditor.staticimage[1])
	GUIEditor.button[2] = guiCreateButton(177, 392, 82, 26, "SAVE", false, GUIEditor.staticimage[1])
	GUIEditor.button[3] = guiCreateButton(91, 392, 83, 26, "DELETE", false, GUIEditor.staticimage[1])
end)

addEventHandler("onClientGUIComboBoxAccepted", resourceRoot, function(comboBox)
	if comboBox == GUIEditor.combobox[6] then
		local groupText = tostring(guiComboBoxGetItemText(GUIEditor.combobox[6], guiComboBoxGetSelected(GUIEditor.combobox[6]) or -1) or "")
		if groupText ~= "" then
			guiComboBoxClear(GUIEditor.combobox[7])
			local animations = exports["anim-system"]:getAllAnimations().anims[groupText]
			for _, animName in ipairs(animations or {}) do
				guiComboBoxAddItem(GUIEditor.combobox[7], animName)
			end
		end
	end
end)

local function getEditorPedID()
	return tonumber((string.gsub(guiGetText(GUIEditor.label[2]), "ID: ", ""))) or false
end

addEventHandler("onClientGUIClick", root, function()
	if source == GUIEditor.button[1] then
		guiSetVisible(GUIEditor.staticimage[1], false)
		showCursor(false)
	elseif source == GUIEditor.button[2] then
		local pedID = getEditorPedID()
		local ped = pedID and getPedFromID(pedID) or false
		if not ped then
			return
		end
		if guiGetText(GUIEditor.edit[2]) == "" or guiGetText(GUIEditor.edit[3]) == "" or guiGetText(GUIEditor.edit[4]) == "" then
			return
		end
		local data = getElementData(ped, "ped:data") or {}
		data.GatesID = guiGetText(GUIEditor.edit[9])
		data.ShopID = guiGetText(GUIEditor.edit[8])
		data.Frozen = guiComboBoxGetSelected(GUIEditor.combobox[3]) == 0 and true or false
		data.anim = {
			guiComboBoxGetItemText(GUIEditor.combobox[6], guiComboBoxGetSelected(GUIEditor.combobox[6]) or -1) or "",
			guiComboBoxGetItemText(GUIEditor.combobox[7], guiComboBoxGetSelected(GUIEditor.combobox[7]) or -1) or "",
		}
		if guiComboBoxGetSelected(GUIEditor.combobox[5]) ~= -1 then
			data.Weapon = getWeaponIDFromName(guiComboBoxGetItemText(GUIEditor.combobox[5], guiComboBoxGetSelected(GUIEditor.combobox[5])))
		end
		setElementData(ped, "ped:data", data)
		triggerServerEvent("ped:updatePedInDataBase", localPlayer, pedID,
			guiGetText(GUIEditor.edit[1]) ~= "" and guiGetText(GUIEditor.edit[1]) or "Unnamed Ped",
			guiComboBoxGetItemText(GUIEditor.combobox[1], guiComboBoxGetSelected(GUIEditor.combobox[1]) or -1) or "",
			math.max(guiComboBoxGetSelected(GUIEditor.combobox[4]) or 0, 0),
			{
				tonumber(guiComboBoxGetItemText(GUIEditor.combobox[2], guiComboBoxGetSelected(GUIEditor.combobox[2]) or -1)) or 0,
				guiGetText(GUIEditor.edit[2]),
				guiGetText(GUIEditor.edit[3]),
				guiGetText(GUIEditor.edit[4]),
				guiGetText(GUIEditor.edit[5]),
				tonumber(guiGetText(GUIEditor.edit[6])) or false,
				tonumber(guiGetText(GUIEditor.edit[7])) or false,
			},
			data,
			getElementData(ped, "ped:owner"),
			guiComboBoxGetSelected(GUIEditor.combobox[5]))
	elseif source == GUIEditor.button[3] then
		local pedID = getEditorPedID()
		if pedID then
			triggerServerEvent("ped:deletePedFromDataBase", localPlayer, pedID)
		end
		guiSetVisible(GUIEditor.staticimage[1], false)
		showCursor(false)
	end
end)

function getPedFromID(pedID)
	return getElementByID("ped:" .. tostring(pedID)) or false
end

addEvent("onClientElementMenuShow", true)
addEventHandler("onClientElementMenuShow", root, function(element, distance, menuType)
	if menuType == "ped" and distance <= TALK_DISTANCE then
		if not isElement(element) then
			return
		end
		exports.interaction:addInteractOption(element, {
			text = "Talk",
			data = {
				interact = getElementData(element, "ped:interact"),
				data = getElementData(element, "ped:data"),
			},
		})
	end
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText, optionData)
	if getElementType(element) == "ped" and optionText == "Edit" then
		if not getElementData(localPlayer, "character:id") then
			return
		end
		local data = getElementData(element, "ped:data") or {}
		guiSetVisible(GUIEditor.staticimage[1], true)
		showCursor(true)
		guiSetText(GUIEditor.label[2], "ID: " .. tostring(optionData and optionData.ID or getElementData(element, "dbid") or 0))
		guiSetText(GUIEditor.edit[1], tostring(getElementData(element, "ped:name") or ""))
		local x, y, z = getElementPosition(element)
		guiSetText(GUIEditor.edit[2], tostring(x))
		guiSetText(GUIEditor.edit[3], tostring(y))
		guiSetText(GUIEditor.edit[4], tostring(z))
		local _, _, rz = getElementRotation(element)
		guiSetText(GUIEditor.edit[5], tostring(rz))
		guiSetText(GUIEditor.edit[6], tostring(getElementInterior(element)))
		guiSetText(GUIEditor.edit[7], tostring(getElementDimension(element)))
		guiComboBoxClear(GUIEditor.combobox[2])
		guiComboBoxAddItem(GUIEditor.combobox[2], tostring(getElementModel(element)))
		guiComboBoxSetSelected(GUIEditor.combobox[2], 0)
		for _, model in ipairs(getValidPedModels()) do
			if model ~= getElementModel(element) then
				guiComboBoxAddItem(GUIEditor.combobox[2], tostring(model))
			end
		end
		if data.Frozen then
			guiComboBoxSetSelected(GUIEditor.combobox[3], 0)
		else
			guiComboBoxSetSelected(GUIEditor.combobox[3], 1)
		end
		guiComboBoxSetSelected(GUIEditor.combobox[4], tonumber(getElementData(element, "ped:behaviour")) or 0)
		guiSetText(GUIEditor.edit[8], tostring(data.ShopID or ""))
		guiSetText(GUIEditor.edit[9], tostring(data.GatesID or ""))
		local interactIndex = 0
		for index, interactType in ipairs(interactTypes) do
			if interactType == getElementData(element, "ped:interact") then
				interactIndex = index - 1
				break
			end
		end
		guiComboBoxSetSelected(GUIEditor.combobox[1], interactIndex)
		guiComboBoxClear(GUIEditor.combobox[6])
		guiComboBoxClear(GUIEditor.combobox[7])
		local animations = exports["anim-system"]:getAllAnimations()
		local groupIndex = 0
		for _, group in ipairs(animations.groups) do
			guiComboBoxAddItem(GUIEditor.combobox[6], group)
			groupIndex = groupIndex + 1
			if data.anim and data.anim[1] == group then
				guiComboBoxSetSelected(GUIEditor.combobox[6], groupIndex - 1)
				local animIndex = 0
				for _, animName in ipairs(animations.anims[group] or {}) do
					guiComboBoxAddItem(GUIEditor.combobox[7], animName)
					animIndex = animIndex + 1
					if data.anim[2] == animName then
						guiComboBoxSetSelected(GUIEditor.combobox[7], animIndex - 1)
					end
				end
			end
		end
	end
end)

function UIKitReady()
	eui = exports.UIKit
	dxFont = eui:getUIFont("default-large")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

setTimer(function()
	local camX, camY, camZ = getCameraMatrix()
	local int, dim = getElementInterior(localPlayer), getElementDimension(localPlayer)
	nearbyPeds = getElementsWithinRange(camX, camY, camZ, 30, "ped", int, dim) or {}
	if not isPedInVehicle(localPlayer) then
		local px, py, pz = getElementPosition(localPlayer)
		local closePeds = getElementsWithinRange(px, py, pz, TALK_DISTANCE, "ped", int, dim) or {}
		if #closePeds > 0 then
			if not talkHintShown then
				exports.notifications:showKeyDescription("ped:talk", "E", "Talk")
				talkHintShown = true
			end
		elseif talkHintShown then
			exports.notifications:hideKeyDescription("ped:talk")
			talkHintShown = false
		end
	elseif talkHintShown then
		exports.notifications:hideKeyDescription("ped:talk")
		talkHintShown = false
	end
end, PEDS_NEARBY_REFRESH, 0)

function drawPedsName()
	if not getElementData(localPlayer, "character:id") then
		return
	end
	if isPlayerMapVisible() then
		return
	end
	local camX, camY, camZ = getCameraMatrix()
	local px, py, pz = getElementPosition(localPlayer)
	for index = 1, #nearbyPeds do
		local ped = nearbyPeds[index]
		if ped ~= localPlayer and isElement(ped) and isElementOnScreen(ped) and getElementData(ped, "ped:name") then
			local bx, by, bz = getPedBonePosition(ped, 8)
			if getDistanceBetween3DPoints(camX, camY, camZ, bx, by, bz) <= NAME_DRAW_DISTANCE then
				setPedLookAt(ped, px, py, pz)
				if isLineOfSightClear(camX, camY, camZ, bx, by, bz, true, false, false, true, true, false, false) then
					local sx, sy = getScreenFromWorldPosition(bx, by, bz)
					if sx and sy then
						dxDrawText(tostring(getElementData(ped, "ped:name")) .. " (NPC)", sx + 2, sy + 2, sx + 2, sy + 2, tocolor(0, 0, 0, 255), 1, dxFont, "center", "top", false, false, false, true)
						dxDrawText(tostring(getElementData(ped, "ped:name")) .. " #FF0000(NPC)", sx, sy, sx, sy, tocolor(255, 255, 255, 255), 1, dxFont, "center", "top", false, false, false, true)
					end
				end
			end
		end
	end
end

addEventHandler("onClientCharacterSpawn", localPlayer, function()
	if not namesRenderAttached then
		addEventHandler("onClientRender", root, drawPedsName, false)
		namesRenderAttached = true
	end
end)
addEventHandler("onClientResourceStart", resourceRoot, function()
	if getElementData(localPlayer, "character:id") and not namesRenderAttached then
		addEventHandler("onClientRender", root, drawPedsName, false)
		namesRenderAttached = true
	end
end)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	if namesRenderAttached then
		removeEventHandler("onClientRender", root, drawPedsName)
		namesRenderAttached = false
	end
end)

function getDistanceBetween3DPoints(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function doPedShootDefence(ped, attacker)
	if not isElement(ped) then
		return
	end
	setPedAimTarget(ped, getElementPosition(attacker))
	setPedControlState(ped, "aim_weapon", true)
	setPedControlState(ped, "fire", true)
	reloadWeaponForPed(ped)
	shootCounts[ped] = (shootCounts[ped] or 0) + 1
	if shootCounts[ped] >= 10 then
		pedStopShooting(ped)
		shootCounts[ped] = 0
	end
end

function pedStopShooting(ped)
	setPedControlState(ped, "aim_weapon", false)
	setPedControlState(ped, "fire", false)
	if shootTimers[ped] then
		if isTimer(shootTimers[ped]) then
			killTimer(shootTimers[ped])
		end
		shootTimers[ped] = nil
	end
end

function reloadWeaponForPed(ped)
end

function tryAttackPed(attacker, weapon, bodyPart, loss)
	local behaviour = tonumber(getElementData(source, "ped:behaviour"))
	if not behaviour then
		return
	end
	if behaviour == 0 or behaviour == 3 then
		setElementHealth(source, 100)
		cancelEvent()
	elseif behaviour == 1 then
		local panicAnim = math.random(2) == 1 and "handsup" or "WEAPON_crouch"
		if panicAnim == "handsup" then
			setPedAnimation(source, "ped", panicAnim, -1, false, false, true, true)
		else
			setPedAnimation(source, "ped", panicAnim)
		end
	elseif behaviour == 2 then
		doPedShootDefence(source, attacker)
		if not shootTimers[source] then
			shootTimers[source] = setTimer(doPedShootDefence, 1000, 10, source, attacker)
		end
	elseif behaviour == 4 then
		setPedAnimation(source, "ped", "sprint_panic")
	end
end
addEventHandler("onClientPedDamage", getRootElement(), tryAttackPed)

function pedTalk(ped, data)
	triggerServerEvent("ped:pedTalk", localPlayer, ped, data)
end

addEventHandler("onClientElementStreamIn", resourceRoot, function()
	local data = getElementData(source, "ped:data")
	if data and data.anim and data.anim[1] and data.anim[1] ~= "" and data.anim[2] and data.anim[2] ~= "" then
		setPedAnimation(source, data.anim[1], data.anim[2], -1, true, false, false, true)
	end
end)

function talk_key(key, keyState)
	if isPedDead(localPlayer) then
		return
	end
	if isPedInVehicle(localPlayer) then
		return
	end
	if isCursorShowing() then
		return
	end
	local px, py = getElementPosition(localPlayer)
	local candidates = {}
	for index = 1, #nearbyPeds do
		local ped = nearbyPeds[index]
		if isElement(ped) and getElementData(ped, "ped:name") then
			local ex, ey = getElementPosition(ped)
			local distance = getDistanceBetweenPoints2D(px, py, ex, ey)
			if distance < TALK_DISTANCE then
				table.insert(candidates, { ped, distance })
			end
		end
	end
	table.sort(candidates, function(a, b)
		return tonumber(a[2]) < tonumber(b[2])
	end)
	if #candidates > 0 then
		local ped = candidates[1][1]
		exports.interaction:executeInteractOption(ped, {
			text = "Talk",
			data = {
				interact = getElementData(ped, "ped:interact"),
				data = getElementData(ped, "ped:data"),
			},
		})
	end
end
bindKey("E", "down", talk_key)
