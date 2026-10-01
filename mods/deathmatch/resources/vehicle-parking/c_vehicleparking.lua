-- ============================================================================
-- vehicle-parking / c_vehicleparking.lua        (Fix #64)
-- ----------------------------------------------------------------------------
-- Client half, restored 1:1 from the old Owl client:
--   /home/daytona/backupm/[rp]/vehicle-parking/client_decompiled.lua
--
--   window[1]  rectangle(_, _, 400, 500) bg (15,15,15,240), all corners rounded
--              parking-area.png (10,10,64,64)
--              title "Parking Area" @ (90,10,100,20) font default-large
--              two description labels (90,35,300,20) colour (255,255,255,150),
--                  one color_coded=false and one word_break=true
--              blue bar (1,85,396,10) and (1,475,396,10) = (41,71,204,240)
--              gridlist (10,105,380,280) cols ID .15 / Vehicle Name .65, row 25
--              button "Get the car out of the parking lot" (10,390,380,35)
--              button "Cancel"                            (10,430,380,35)
--   window[2]  rectangle(_, _, 400, 185) - the "park here" confirmation
--              button "Park the car in this parking"      (10,100,380,35)
--              button "Cancel"                            (10,140,380,35)
--
-- Deviation: the old client also drew a dxDrawMaterialLine3D over every marker
-- in a render loop that the decompiler left with undefined globals (var0/var1 =
-- offset + texture, both lost).  The lots already have real cylinder markers
-- created by the server, so that broken loop is not reproduced.
-- ============================================================================

local eui = exports.UIKit
local localPlayer = getLocalPlayer()
local root = getRootElement()

local UI = {
	window = {},
	label = {},
	button = {},
	gridlist = {},
	image = {},
}

local currentLot = false

local DESCRIPTION = {
	en = "Park your car in the parking lot to be safe from theft and damage",
	ar = "أوقف سيارتك في الموقف لتكون في أمان من السرقة والتلف",
}

function UIKitReady()
	eui = exports.UIKit

	-- === window[1] : the list of your parked cars in this lot ==============
	UI.window[1] = eui:uiCreateRectangle(false, false, 400, 500, tocolor(15, 15, 15, 240), true, true, true, true)
	eui:uiSetVisible(UI.window[1], false)
	eui:uiCreateImage(10, 10, 64, 64, "parking-area.png", UI.window[1])

	UI.label.Title = eui:uiCreateLabel(90, 10, 100, 20, { en = "Parking Area", ar = "موقف سيارات" }, tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
	eui:uiSetFont(UI.label.Title, "default-large")

	local descA = eui:uiCreateLabel(90, 35, 300, 20, DESCRIPTION, tocolor(255, 255, 255, 150), "left", "top", UI.window[1])
	eui:uiSetProperty(descA, "color_coded", false)
	local descB = eui:uiCreateLabel(90, 35, 300, 20, DESCRIPTION, tocolor(255, 255, 255, 150), "left", "top", UI.window[1])
	eui:uiSetProperty(descB, "word_break", true)

	eui:uiCreateRectangle(1, 85, 396, 10, tocolor(41, 71, 204, 240), false, false, false, false, UI.window[1])
	eui:uiCreateRectangle(1, 475, 396, 10, tocolor(41, 71, 204, 240), false, false, false, false, UI.window[1])

	UI.gridlist[1] = eui:uiCreateGridList(10, 105, 380, 280, tocolor(10, 10, 10, 0), UI.window[1])
	eui:uiGridListAddColumn(UI.gridlist[1], "ID", 0.15)
	eui:uiGridListAddColumn(UI.gridlist[1], "Vehicle Name", 0.65)
	eui:uiSetAlign(UI.gridlist[1], "left", "center")
	eui:uiSetProperty(UI.gridlist[1], "row_height", 25)

	UI.button[1] = eui:uiCreateButton(10, 390, 380, 35, {
		en = "Get the car out of the parking lot",
		ar = "إخراج السيارة من الموقف",
	}, tocolor(24, 47, 150, 255), UI.window[1])
	UI.button[2] = eui:uiCreateButton(10, 430, 380, 35, { en = "Cancel", ar = "إلغاء" }, tocolor(10, 10, 10, 255), UI.window[1])

	-- === window[2] : the "park here" confirmation =========================
	UI.window[2] = eui:uiCreateRectangle(false, false, 400, 185, tocolor(15, 15, 15, 240), true, true, true, true)
	eui:uiSetVisible(UI.window[2], false)
	eui:uiCreateImage(10, 10, 64, 64, "parking-area.png", UI.window[2])

	UI.label.Title2 = eui:uiCreateLabel(90, 10, 100, 20, { en = "Parking Area", ar = "موقف سيارات" }, tocolor(255, 255, 255, 255), "left", "top", UI.window[2])
	eui:uiSetFont(UI.label.Title2, "default-large")

	local descC = eui:uiCreateLabel(90, 35, 300, 20, DESCRIPTION, tocolor(255, 255, 255, 150), "left", "top", UI.window[2])
	eui:uiSetProperty(descC, "color_coded", false)
	local descD = eui:uiCreateLabel(90, 35, 300, 20, DESCRIPTION, tocolor(255, 255, 255, 150), "left", "top", UI.window[2])
	eui:uiSetProperty(descD, "word_break", true)

	UI.button[3] = eui:uiCreateButton(10, 100, 380, 35, {
		en = "Park the car in this parking",
		ar = "إيقاف السيارة في هذا الموقف",
	}, tocolor(24, 47, 150, 255), UI.window[2])
	UI.button[4] = eui:uiCreateButton(10, 140, 380, 35, { en = "Cancel", ar = "إلغاء" }, tocolor(10, 10, 10, 255), UI.window[2])
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

-- ---------------------------------------------------------------------------
function closeUIWindows()
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window[2], false)
	showCursor(false)
end

addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

-- ---------------------------------------------------------------------------
-- clicks (old client's onClientUIClick)
-- ---------------------------------------------------------------------------
addEventHandler("onClientUIClick", root, function()
	if source == UI.button[1] then
		local row = eui:uiGridListGetSelectedItem(UI.gridlist[1])
		if row ~= -1 then
			eui:uiSetVisible(UI.window[1], false)
			showCursor(false)
			triggerServerEvent(PARKING.EVENTS.getOut, localPlayer, tonumber(eui:uiGridListGetItemText(UI.gridlist[1], row, 1)))
		end
	elseif source == UI.button[2] then
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	elseif source == UI.button[3] then
		eui:uiSetVisible(UI.window[2], false)
		showCursor(false)
		if currentLot then
			triggerServerEvent(PARKING.EVENTS.park, localPlayer, currentLot)
		end
	elseif source == UI.button[4] then
		eui:uiSetVisible(UI.window[2], false)
		showCursor(false)
	end
end)

-- ---------------------------------------------------------------------------
-- server -> client
-- ---------------------------------------------------------------------------
addEvent(PARKING.EVENTS.showParking, true)
addEventHandler(PARKING.EVENTS.showParking, localPlayer, function(lotID)
	currentLot = lotID
	eui:uiSetVisible(UI.window[2], true)
	showCursor(true)
end)

addEvent(PARKING.EVENTS.showList, true)
addEventHandler(PARKING.EVENTS.showList, localPlayer, function(rows, lotID)
	currentLot = lotID
	eui:uiSetVisible(UI.window[1], true)
	showCursor(true)
	eui:uiGridListClear(UI.gridlist[1])
	for _, vehicle in ipairs(rows or {}) do
		local row = eui:uiGridListAddRow(UI.gridlist[1])
		eui:uiGridListSetItemText(UI.gridlist[1], row, 1, tostring(vehicle.ID))
		eui:uiGridListSetItemText(UI.gridlist[1], row, 2, tostring(vehicle.Name))
		eui:uiGridListSetItemColor(UI.gridlist[1], row, 1, tocolor(255, 234, 176, 255))
		eui:uiGridListSetItemColor(UI.gridlist[1], row, 2, tocolor(255, 234, 176, 255))
	end
end)
