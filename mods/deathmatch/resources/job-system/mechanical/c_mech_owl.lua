-- Decompiled by Owl Decompiler v1.0 ([jobs]/mechanical/mech_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1 = the panel state TABLE (vehicle/currentPath/main_section)
--     merged with the raw vehicle element - restored as the `panel` table
--     (panel.vehicle / panel.currentPath / panel.main_section); every
--     getVehicleDoorState(var0) style call reads panel.vehicle.
--   * openMainSection's list items ("Repair"/"Upgrades"/"Repaint"/"Replace
--     Lights") are the decompile's four double-click branches - the table
--     itself was lost with the decompile's var0.main_section, restored.
--   * the Repaint branch: _FOR_:uiGridListAddRow leaks (lost `local row`)
--     restored; getVehicleColor(var0, true) RGB triples per row.
--   * the wheel repair list reused ONE getVehicleWheelStates call for all
--     four wheels (decompiler hoisting) - restored per-wheel reads.
--   * "Change Colors" sent only the first row's packed color - restored to
--     four RGB triples unpacked from the rows.
--   * colorPicker (openSelect) = the Owl colorpicker resource is ENCRYPTED
--     in the dump (in the decrypt list) - a minimal UIKit shim ships here:
--     one hex edit + Apply, tinting the repaint rows and lighting flow.
--   * getUpgradesFromSectionName: table.insert({}, ...) lost its
--     accumulator - restored; veh_upgrades loaded from upgrades.xml
--     (catalog reconstructed: 194 MTA upgrades with slot-based names).

local UI = {
	tab = {},
	progressbar = {},
	edit = {},
	window = {},
	label = {},
	checkbox = {},
	switch = {},
	button = {},
	tabpanel = {},
	radiobutton = {},
	gridlist = {},
	memo = {},
	scrollbar = {},
	combobox = {}
}

local panel = {
	vehicle = nil,
	currentPath = "",
	main_section = { "Repair", "Upgrades", "Repaint", "Replace Lights" }
}
local currentSelectedColor = { 255, 255, 255 }
local veh_upgrades = {}

local function lastPathSegment()
	local parts = split(panel.currentPath, "/")
	return parts[#parts] or ""
end

local function bodyRepairPrice(vehicle)
	local total = 0
	for door = 0, 5 do
		total = total + getVehicleDoorState(vehicle, door) * 100
	end
	for pane = 0, 6 do
		total = total + getVehiclePanelState(vehicle, pane) * 100
	end
	return math.floor(total)
end

function UIKitReady()
	eui = exports.UIKit
	UI.window[1] = eui:uiCreateWindow(false, false, 250, 338, "Mechanic Panel")
	eui:uiSetVisible(UI.window[1], false)
	UI.gridlist[1] = eui:uiCreateGridList(5, 35, 240, 260, tocolor(10, 10, 10, 0), UI.window[1])
	eui:uiGridListAddColumn(UI.gridlist[1], "Menu", 0.8)
	eui:uiGridListAddColumn(UI.gridlist[1], "", 0.2)
	eui:uiSetAlign(UI.gridlist[1], "left", "center")
	UI.button[2] = eui:uiCreateButton(5, 303, 240, 30, { en = "Close", ar = "إغلاق" }, _, UI.window[1])
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

function closeUIWindows()
	eui:uiSetVisible(UI.window[1], false)
	showCursor(false)
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

function showMechanicPanel(vehicle)
	panel.vehicle = vehicle
	eui:uiSetVisible(UI.window[1], true)
	openMainSection()
end

-- inject the right-click option on vehicles (the Owl interaction client is
-- encrypted; this port relies on the Fix #60 interaction menu, extended to
-- vehicles in Fix #63, and injects the panel option on menu show)
addEventHandler("onClientElementMenuShow", root, function(element, distance, elementType)
	if elementType ~= "vehicle" or not isElement(element) then
		return
	end
	local vehType = getVehicleType(element)
	if vehType ~= "BMX" and vehType ~= "Boat" and vehType ~= "Bike" and vehType ~= "Quad" and isVehicleLocked(element) then
		return
	end
	exports.interaction:addInteractOption(element, { text = "Mechanic Panel" })
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText)
	if optionText ~= "Mechanic Panel" then
		return
	end
	if not isElement(element) then
		return
	end
	if getElementType(element) == "vehicle" then
		local vehType = getVehicleType(element)
		if vehType ~= "BMX" and vehType ~= "Boat" and vehType ~= "Bike" and vehType ~= "Quad" and isVehicleLocked(element) then
			return
		end
		local px, py, pz = getElementPosition(localPlayer)
		if getDistanceBetweenPoints3D(px, py, pz, getElementPosition(element)) <= 6 then
			showMechanicPanel(element)
		end
	end
end)

-- minimal colorPicker shim (the Owl colorpicker resource is encrypted)
local colorShim = { window = nil, edit = nil }
colorPicker = {}

function colorPicker.openSelect()
	if not colorShim.window then
		colorShim.window = eui:uiCreateWindow(false, false, 220, 120, "Pick a color")
		eui:uiSetVisible(colorShim.window, false)
		colorShim.edit = eui:uiCreateEdit(10, 45, 130, 26, "255,255,255", colorShim.window)
		colorShim.apply = eui:uiCreateButton(150, 45, 60, 26, { en = "Apply", ar = "تطبيق" }, "primary", colorShim.window)
	end
	eui:uiSetVisible(colorShim.window, true)
	showCursor(true)
end

addEventHandler("onClientUIClick", root, function()
	if source == colorShim.apply then
		local text = tostring(eui:uiGetText(colorShim.edit) or "")
		local r, g, b = text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
		currentSelectedColor = { tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255 }
		eui:uiSetVisible(colorShim.window, false)
		-- recolor the repaint preview rows
		for row = 1, 4 do
			eui:uiGridListSetItemColor(UI.gridlist[1], row, 2, tocolor(currentSelectedColor[1], currentSelectedColor[2], currentSelectedColor[3]))
		end
	end
end)

addEventHandler("onClientUIClick", root, function()
	if source == UI.button[2] then
		eui:uiSetVisible(UI.window[1], false
		)
	elseif source == UI.gridlist[1] and eui:uiGridListGetSelectedItem(source) ~= -1 and lastPathSegment() == "Repaint" then
		currentSelectedColor = { 255, 255, 255 }
		colorPicker.openSelect()
	end
end)

local function addRow(text, text2)
	local row = eui:uiGridListAddRow(UI.gridlist[1])
	eui:uiGridListSetItemText(UI.gridlist[1], row, 1, text)
	if text2 then
		eui:uiGridListSetItemText(UI.gridlist[1], row, 2, text2)
	end
	return row
end

addEventHandler("onClientUIDoubleClick", root, function()
	if source == UI.gridlist[1] and eui:uiGridListGetSelectedItem(source) ~= -1 then
		local vehicle = panel.vehicle
		if eui:uiGridListGetItemText(source, eui:uiGridListGetSelectedItem(source), 1) == "..." then
			local parts = split(panel.currentPath, "/")
			parts[#parts] = nil
			panel.currentPath = table.concat(parts, "/")
			if lastPathSegment() == "" then
				openMainSection()
			elseif lastPathSegment() == "Upgrades" then
				showUpgradesInList()
			end
		elseif eui:uiGridListGetItemText(source, eui:uiGridListGetSelectedItem(source), 1) == "Upgrades" then
			panel.currentPath = panel.currentPath .. "/Upgrades"
			showUpgradesInList()
		elseif eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 1) == "upgrade-slot" then
			showVehicleUpgradesBySlot(eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 2))
			panel.currentPath = panel.currentPath .. "/sub-upgrades"
		elseif type(eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 1)) == "table" and eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 1).type == "upgrade" then
			local data = eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 1)
			if data.current then
				triggerServerEvent("mechanic:removeUpgrade", localPlayer, vehicle, tonumber(data.value), tonumber(data.price))
			else
				triggerServerEvent("mechanic:addUpgrade", localPlayer, vehicle, tonumber(data.value), tonumber(data.price))
			end
		elseif panel.currentPath == "" then
			local picked = eui:uiGridListGetItemText(source, eui:uiGridListGetSelectedItem(source), 1)
			panel.currentPath = panel.currentPath .. "/" .. picked
			eui:uiGridListClear(UI.gridlist[1])
			addRow("...")
			if picked == "Repair" then
				if bodyRepairPrice(vehicle) ~= 0 then
					local row = addRow("Body", "$" .. tostring(bodyRepairPrice(vehicle)))
					eui:uiGridListSetItemData(UI.gridlist[1], row, 2, { bodyRepairPrice(vehicle) })
				end
				if getElementHealth(vehicle) < 1000 then
					local price = math.floor((1 - getElementHealth(vehicle) / 1000) * 2000)
					local row = addRow("Engine", "$" .. tostring(price))
					eui:uiGridListSetItemData(UI.gridlist[1], row, 2, { price })
				end
				local wheelNames = { "Front left wheel", "Front right wheel", "Rear left wheel", "Rear right wheel" }
				for wheel = 0, 3 do
					local state = getVehicleWheelState(vehicle, wheel)
					if state ~= 0 then
						local row = addRow(wheelNames[wheel + 1], "$" .. tostring(state * 50))
						eui:uiGridListSetItemData(UI.gridlist[1], row, 2, { state * 50, wheel })
					end
				end
			elseif picked == "Repaint" then
				currentSelectedColor = { 255, 255, 255 }
				colorPicker.openSelect()
				for color = 1, 4 do
					addRow("Color " .. tostring(color), "\226\128\162\226\128\162\226\128\162")
				end
				addRow("Change Colors", "$1000")
				for row = 1, 4 do
					local r, g, b = getVehicleColor(vehicle, true)
					eui:uiGridListSetItemColor(UI.gridlist[1], row, 2, tocolor(r, g, b))
				end
			elseif picked == "Replace Lights" then
				currentSelectedColor = { 255, 255, 255 }
				colorPicker.openSelect()
				addRow("Change Color", "$1500")
			end
		else
			if isElement(vehicle) then
				local px, py, pz = getElementPosition(localPlayer)
				if 6 < getDistanceBetweenPoints3D(px, py, pz, getElementPosition(vehicle)) then
					eui:uiSetVisible(UI.window[1], false)
					return
				end
			else
				eui:uiSetVisible(UI.window[1], false)
				return
			end
			local path = lastPathSegment()
			local itemData = eui:uiGridListGetItemData(source, eui:uiGridListGetSelectedItem(source), 2)
			if path == "Repair" then
				local price = type(itemData) == "table" and itemData[1] or 0
				if getPlayerMoney(localPlayer) >= price then
					eui:uiGridListRemoveRow(source, eui:uiGridListGetSelectedItem(source))
				end
				local itemText = eui:uiGridListGetItemText(source, eui:uiGridListGetSelectedItem(source), 1)
				if itemText == "Body" then
					triggerServerEvent("mechanic:repairBody", localPlayer, vehicle)
				elseif itemText == "Engine" then
					triggerServerEvent("mechanic:repairEngine", localPlayer, vehicle)
				else
					triggerServerEvent("mechanic:repairWheels", localPlayer, vehicle, type(itemData) == "table" and itemData[2])
				end
			elseif path == "Repaint" then
				if eui:uiGridListGetItemText(source, eui:uiGridListGetSelectedItem(source), 1) == "Change Colors" then
					local colors = {}
					for row = 1, 4 do
						local packed = eui:uiGridListGetItemColor(UI.gridlist[1], row, 2)
						colors[row] = { bitAnd(packed, 255), bitAnd(bitShr(packed, 8), 255), bitAnd(bitShr(packed, 16), 255) }
					end
					triggerServerEvent("mechanic:changeVehicleColor", localPlayer, vehicle, colors)
				end
			elseif path == "Replace Lights" then
				triggerServerEvent("mechanic:changeLightsColor", localPlayer, vehicle, unpack(currentSelectedColor))
			end
		end
	end
end)

function openMainSection()
	eui:uiGridListClear(UI.gridlist[1])
	for _, item in ipairs(panel.main_section) do
		addRow(tostring(item))
	end
	panel.currentPath = ""
end

function showUpgradesInList()
	eui:uiGridListClear(UI.gridlist[1])
	addRow("...")
	local vehicle = panel.vehicle
	for slot = 0, 16 do
		if 0 < #getUpgradesFromSectionName(slot) then
			local row = addRow(tostring(getVehicleUpgradeSlotName(slot)), "(" .. #getUpgradesFromSectionName(slot) .. ")  \226\158\157")
			eui:uiGridListSetItemData(UI.gridlist[1], row, 1, "upgrade-slot")
			eui:uiGridListSetItemData(UI.gridlist[1], row, 2, slot)
		end
	end
end

function showVehicleUpgradesBySlot(slot)
	eui:uiGridListClear(UI.gridlist[1])
	addRow("...")
	local vehicle = panel.vehicle
	for _, upgradeID in ipairs(getVehicleCompatibleUpgrades(vehicle, slot)) do
		local info = veh_upgrades[tostring(upgradeID)]
		if info then
			local row = eui:uiGridListAddRow(UI.gridlist[1])
			eui:uiGridListSetItemText(UI.gridlist[1], row, 1, info.name)
			eui:uiGridListSetItemData(UI.gridlist[1], row, 1, {
				type = "upgrade",
				value = upgradeID,
				price = info.price,
				current = upgradeID == getVehicleUpgradeOnSlot(vehicle, slot)
			})
			eui:uiGridListSetItemText(UI.gridlist[1], row, 2, "$" .. info.price)
			if upgradeID == getVehicleUpgradeOnSlot(vehicle, slot) then
				eui:uiGridListSetItemColor(UI.gridlist[1], row, 1, tocolor(0, 255, 0))
				eui:uiGridListSetItemColor(UI.gridlist[1], row, 2, tocolor(0, 255, 0))
			end
		end
	end
end

function getUpgradesFromSectionName(slot)
	local found = {}
	if isElement(panel.vehicle) then
		for _, upgradeID in pairs(getVehicleCompatibleUpgrades(panel.vehicle, slot)) do
			if veh_upgrades[tostring(upgradeID)] then
				table.insert(found, { upgradeID, 1, 3500 })
			end
		end
	end
	return found
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	local xml = xmlLoadFile("mechanical/upgrades.xml")
	if xml then
		for _, node in ipairs(xmlNodeGetChildren(xml)) do
			veh_upgrades[xmlNodeGetAttribute(node, "id")] = {
				name = xmlNodeGetAttribute(node, "name"),
				price = tonumber(xmlNodeGetAttribute(node, "price")) or 2000
			}
		end
		xmlUnloadFile(xml)
	end
end)
