-- [Fix #160] client side of the OBJECT & GATE system: right-click menu on gate
-- objects (open/close + gate edit) and the numeric gate edit panel. Server side:
-- s_object_tools_fix160.lua, command->right map: staff_manager/gates_fix160_task6.lua.

local panelWindow = false
local panelEdits = nil
local panelGate = false
local deleteArmed = false
local menuGate = false

-- ===========================================================================
-- right-click menu
-- ===========================================================================

-- [Fix #160] right click on a gate/object -> ask the server what this player may do
local function onGateRightClick(button, state, absX, absY, wx, wy, wz, element)
	if button ~= "right" or state ~= "down" then return end
	if getElementData(localPlayer, "exclusiveGUI") then return end
	if not element or getElementType(element) ~= "object" then return end
	if not getElementData(element, "gate") then return end
	if isPedDead(localPlayer) then return end

	triggerServerEvent("objedit:requestMenu", localPlayer, element)
end
addEventHandler("onClientClick", root, onGateRightClick, true)

-- [Fix #160] the server answers with what this player is allowed to do with it
addEvent("objedit:showMenu", true)
addEventHandler("objedit:showMenu", root, function(theGate, isDoor, canEdit)
	if not isElement(theGate) then return end
	menuGate = theGate

	showCursor(true)
	local rcMenu = exports.rightclick:create("Gate/Object #" .. (tonumber(getElementData(theGate, "gate:id")) or -1))

	if isDoor then
		local row = exports.rightclick:addRow("Open / Close")
		addEventHandler("onClientGUIClick", row, function()
			if isElement(menuGate) then
				triggerServerEvent("gate:trigger", menuGate)
			end
		end, true)
	end

	if canEdit then
		local row = exports.rightclick:addRow("Gate edit")
		addEventHandler("onClientGUIClick", row, function()
			if isElement(menuGate) then
				triggerServerEvent("objedit:requestPanel", localPlayer, menuGate)
			end
		end, true)
	end

	local row = exports.rightclick:addRow("Cancel")
	addEventHandler("onClientGUIClick", row, function() end, true)
end)

-- ===========================================================================
-- gate edit panel
-- ===========================================================================

local FIELD_LABELS = { "X", "Y", "Z", "RX", "RY", "RZ" }
local FIELD_WIDTH = 80
local FIELD_GAP = 4

local function closePanel()
	if panelWindow and isElement(panelWindow) then
		destroyElement(panelWindow)
	end
	panelWindow = false
	panelEdits = false
	panelGate = false
	deleteArmed = false
	guiSetInputEnabled(false)
	showCursor(false)
	setElementData(localPlayer, "exclusiveGUI", false, false)
end

local function getFieldRow(parent, labels, y)
	local row = {}
	for i = 1, 6 do
		local x = 10 + (i - 1) * (FIELD_WIDTH + FIELD_GAP)
		local lbl = guiCreateLabel(x, y, FIELD_WIDTH, 14, labels[i], false, parent)
		guiSetFont(lbl, "default-small")
		row[i] = guiCreateEdit(x, y + 15, FIELD_WIDTH, 22, "0", false, parent)
	end
	return row
end

local function fillFieldRow(row, values)
	for i = 1, 6 do
		if isElement(row[i]) then
			guiSetText(row[i], tostring(values[i] or 0))
		end
	end
end

-- [Fix #160] open (or re-open) the numeric editor for one gate/object
local function openPanel(theGate, payload)
	if not isElement(theGate) or type(payload) ~= "table" then return end
	if panelWindow and isElement(panelWindow) then
		destroyElement(panelWindow)
	end
	panelGate = theGate
	deleteArmed = false

	local sw, sh = guiGetScreenSize()
	local w, h = 520, 268
	local left, top = (sw - w) / 2, (sh - h) / 2

	panelWindow = guiCreateWindow(left, top, w, h,
		"Gate/Object editor #" .. tostring(payload.id or -1) .. "  (model " .. tostring(payload.model or "?") .. ")", false)
	guiWindowSetSizable(panelWindow, false)
	setElementData(localPlayer, "exclusiveGUI", true, false)

	-- [Fix #160] object + placement row
	local lbl = guiCreateLabel(10, 30, 46, 22, "Model", false, panelWindow)
	guiLabelSetVerticalAlign(lbl, "center")
	local model = guiCreateEdit(54, 30, 70, 22, tostring(payload.model or ""), false, panelWindow)

	lbl = guiCreateLabel(140, 30, 55, 22, "Interior", false, panelWindow)
	guiLabelSetVerticalAlign(lbl, "center")
	local interior = guiCreateEdit(195, 30, 55, 22, tostring(payload.int or 0), false, panelWindow)

	lbl = guiCreateLabel(260, 30, 65, 22, "Dimension", false, panelWindow)
	guiLabelSetVerticalAlign(lbl, "center")
	local dimension = guiCreateEdit(325, 30, 70, 22, tostring(payload.dim or 0), false, panelWindow)

	lbl = guiCreateLabel(410, 30, 100, 22, payload.door and "Type: DOOR" or "Type: STATIC", false, panelWindow)
	guiLabelSetVerticalAlign(lbl, "center")
	guiLabelSetColor(lbl, payload.door and 0 or 255, payload.door and 255 or 194, payload.door and 0 or 14)

	-- [Fix #160] start (closed) row and move-to (open) row
	lbl = guiCreateLabel(10, 58, 500, 15, "Start position (closed) = DB startX..startRZ", false, panelWindow)
	guiLabelSetColor(lbl, 255, 194, 14)

	local startPos = { payload.sx, payload.sy, payload.sz, payload.srx, payload.sry, payload.srz }
	local endPos = { payload.ex, payload.ey, payload.ez, payload.erx, payload.ery, payload.erz }

	local startEdits = getFieldRow(panelWindow, FIELD_LABELS, 76)

	lbl = guiCreateLabel(10, 120, 500, 15, "Move to position (open) = DB endX..endRZ", false, panelWindow)
	guiLabelSetColor(lbl, 255, 194, 14)

	local endEdits = getFieldRow(panelWindow, FIELD_LABELS, 138)

	fillFieldRow(startEdits, startPos)
	fillFieldRow(endEdits, endPos)

	panelEdits = {
		model = model,
		int = interior,
		dim = dimension,
		start = startEdits,
		["end"] = endEdits,
	}

	local btnSave = guiCreateButton(10, 200, 90, 26, "Save", false, panelWindow)
	local btnDelete = guiCreateButton(108, 200, 90, 26, "Delete", false, panelWindow)
	local btnCancel = guiCreateButton(206, 200, 90, 26, "Cancel", false, panelWindow)

	local hint = guiCreateLabel(10, 232, 500, 28,
		"Save writes all fields to the DB. Delete removes the object from the map. The right-click menu stays available after saving.",
		false, panelWindow)
	guiLabelSetWordWrap(hint, true)

	showCursor(true)
	guiSetInputEnabled(true)
	-- [Fix #160] the rightclick menu hides the cursor ~250ms after the click that
	-- opened this panel, so re-show it once that has happened
	setTimer(function()
		if panelWindow and isElement(panelWindow) then
			showCursor(true)
		end
	end, 400, 1)

	addEventHandler("onClientGUIClick", btnSave, function()
		if not (panelGate and isElement(panelGate)) then
			outputChatBox("[GATEMANAGER] That object no longer exists.", 255, 0, 0)
			closePanel()
			return
		end
		if not panelEdits then return end

		local values = {
			tonumber(guiGetText(panelEdits.model)),
			tonumber(guiGetText(panelEdits.int)),
			tonumber(guiGetText(panelEdits.dim)),
		}
		for i = 1, 6 do
			values[3 + i] = tonumber(guiGetText(panelEdits.start[i]))
			values[9 + i] = tonumber(guiGetText(panelEdits["end"][i]))
		end
		for i = 1, 15 do
			if values[i] == nil then
				outputChatBox("[GATEMANAGER] Every field must be a number.", 255, 0, 0)
				return
			end
		end

		triggerServerEvent("objedit:save", localPlayer, panelGate,
			values[1], values[4], values[5], values[6], values[7], values[8], values[9],
			values[10], values[11], values[12], values[13], values[14], values[15],
			values[2], values[3])
		closePanel()
	end, false)

	addEventHandler("onClientGUIClick", btnDelete, function()
		if not (panelGate and isElement(panelGate)) then
			outputChatBox("[GATEMANAGER] That object no longer exists.", 255, 0, 0)
			closePanel()
			return
		end
		if not deleteArmed then
			deleteArmed = true
			guiSetText(btnDelete, "Really delete?")
			return
		end
		triggerServerEvent("objedit:delete", localPlayer, panelGate)
		closePanel()
	end, false)

	addEventHandler("onClientGUIClick", btnCancel, function()
		closePanel()
	end, false)
end

addEvent("objedit:openPanel", true)
addEventHandler("objedit:openPanel", root, openPanel)

-- [Fix #160] ESC closes the panel instead of the pause menu
addEventHandler("onClientKey", root, function(key, pressed)
	if not pressed then return end
	if not (panelWindow and isElement(panelWindow)) then return end
	if key == "escape" then
		cancelEvent()
		closePanel()
	end
end)

-- [Fix #160] never leave the cursor/input enabled behind
addEventHandler("onClientResourceStop", resourceRoot, function()
	if panelWindow and isElement(panelWindow) then
		destroyElement(panelWindow)
	end
	guiSetInputEnabled(false)
	showCursor(false)
end)
