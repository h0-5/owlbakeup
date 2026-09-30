-- ============================================================================
-- vehicle-tuning / c_vehtuning.lua              (Fix #63)
-- ----------------------------------------------------------------------------
-- Client half, restored 1:1 from the old Owl client:
--   /home/daytona/backupm/[rp]/vehicle-tuning/client_decompiled.lua
--
-- Everything the old client drew is kept with the SAME numbers, the same UIKit
-- calls and the same order, so the panel is pixel identical:
--
--   window[1] "Vehicles Tuning"   window(20, _, 280, 450) + car.png icon
--             button[1] Purchase (primary)      button[2] Close
--             gridlist  (10, 50, 260, 295) cols "Option" .6 / "" .4, row 25
--             sections: Engines | Vehicle Tinting | Neon | Back-fire | Lock
--   window[2] right info rectangle (refSx-300, _, 280, 400) bg (15,15,15,240)
--             5 rows: Max Speed / Acceleration / Engine Inertia / Drive Type /
--             Engine Type, two of them with a 5px progress bar (0,150,255,240)
--   window[3] "Vehicles Handling" (20, _, 300, 700) with the 13 range sliders
--             of the old client's `handlings` table (same min/max/step).
--
-- Deviations (documented on purpose):
--  * window[3] is reachable by pressing H while the tuning panel is open and is
--    server-side restricted to staff - the decompiled client had lost the code
--    that showed it.
--  * neon tubes are drawn as MTA lights: the old client spawned object 1940
--    with a streamed DFF/TXD (the `mods` customModel pack) which is not part of
--    the backup.  Set TUNING.neonUseObjects + TUNING.neonObjectModel once that
--    pack is installed and the original art is used instead.
-- ============================================================================

local eui = exports.UIKit
local localPlayer = getLocalPlayer()
local root = getRootElement()

local UI = {
	window = {},
	label = {},
	button = {},
	gridlist = {},
	progressbar = {},
	labelValue = {},
	rangeslider = {},
}

local currentVehicle = false   -- the vehicle the panel is bound to
local currentSection = "sections"
local tuningData = {}          -- last vehtuning:sync payload
local handlingWindowOpen = false

local numberFormat = function(amount)
	local formatted = tostring(math.floor(tonumber(amount) or 0))
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- ---------------------------------------------------------------------------
-- 1: initialise the old client's interface
-- ---------------------------------------------------------------------------
local HANDLING_SLIDERS = {
	{ label = "Max Speed (km/h)",     property = "maxVelocity",              min = 80,      max = 380,     step = 20 },
	{ label = "Acceleration",         property = "engineAcceleration",       min = 1,       max = 50,      step = 1 },
	{ label = "Engine Inertia",       property = "engineInertia",            min = -1000,   max = 1000,    step = 10 },
	{ label = "Supension Height",     property = "suspensionLowerLimit",     min = -50,     max = 50,      step = 1 },
	{ label = "Supension Bias",       property = "suspensionFrontRearBias",  min = 0,       max = 1,       step = 0.01 },
	{ label = "Supension Force",      property = "suspensionForceLevel",     min = 0,       max = 100,     step = 1 },
	{ label = "Supension Damping",    property = "suspensionDamping",        min = 0,       max = 100,     step = 1 },
	{ label = "Steering Lock",        property = "steeringLock",             min = 0,       max = 360,     step = 1 },
	{ label = "Drag Coefficiency",    property = "dragCoeff",                min = -200,    max = 200,     step = 1 },
	{ label = "Braking Power",        property = "brakeDeceleration",        min = 1,       max = 100,     step = 1 },
	{ label = "Braking Bias",         property = "brakeBias",                min = 0,       max = 1,       step = 0.01 },
	{ label = "Traction Multiplier",  property = "tractionMultiplier",       min = -100000, max = 100000,  step = 10 },
	{ label = "Traction Bias",        property = "tractionBias",             min = 0,       max = 1,       step = 0.01 },
}

function UIKitReady()
	eui = exports.UIKit
	local refSx = eui:uiGetReferenceScreenSize()

	-- === window[1] : Vehicles Tuning =======================================
	UI.window[1] = eui:uiCreateWindow(20, false, 280, 450, {
		en = "Vehicles Tuning",
		ar = "ضبط المركبات",
	}, _, ":assets/icons/car.png")
	eui:uiSetVisible(UI.window[1], false)
	eui:uiWindowSetMovable(UI.window[1], false)

	UI.button[1] = eui:uiCreateButton(10, 365, 260, 35, { en = "Purchase", ar = "شراء" }, "primary", UI.window[1])
	UI.button[2] = eui:uiCreateButton(10, 405, 260, 35, { en = "Close", ar = "إغلاق" }, _, UI.window[1])
	eui:uiSetVisible(UI.button[1], false)
	eui:uiSetProperty(UI.button[2], "HoverTextColor", tocolor(255, 48, 48))

	UI.gridlist[1] = eui:uiCreateGridList(10, 50, 260, 295, tocolor(10, 10, 10, 0), UI.window[1])
	eui:uiGridListAddColumn(UI.gridlist[1], "Option", 0.6)
	eui:uiGridListAddColumn(UI.gridlist[1], "", 0.4)
	eui:uiSetAlign(UI.gridlist[1], "left", "center")
	eui:uiSetProperty(UI.gridlist[1], "row_height", 25)

	-- === window[2] : right hand vehicle statistics =========================
	UI.window[2] = eui:uiCreateRectangle(refSx - 280 - 20, false, 280, 400, tocolor(15, 15, 15, 240), true, true, true, true)
	eui:uiSetVisible(UI.window[2], false)

	local statRows = {
		{ en = "Max Speed",    ar = "السرعة القصوى", progress = true },
		{ en = "Acceleration", ar = "التسارع",       progress = true },
		{ en = "Engine Inertia", ar = "عزم المحرك" },
		{ en = "Drive Type",   ar = "نوع القيادة" },
		{ en = "Engine Type",  ar = "نوع المحرك" },
	}
	for i, row in ipairs(statRows) do
		eui:uiCreateLabel(20, 20 + 55 * (i - 1), 240, 20, row, tocolor(255, 255, 255, 255), "left", "top", UI.window[2])
		UI.labelValue[i] = eui:uiCreateLabel(20, 20 + 55 * (i - 1), 240, 20, "-", tocolor(255, 255, 255, 255), "right", "top", UI.window[2])
		if row.progress then
			UI.progressbar[i] = eui:uiCreateProgressBar(20, 20 + 55 * (i - 1) + 30, 240, 5, tocolor(0, 150, 255, 240), UI.window[2])
			eui:uiSetProperty(UI.progressbar[i], "background_color", tocolor(30, 30, 30, 255))
			eui:uiSetProperty(UI.progressbar[i], "show_progress", false)
		end
	end

	-- === window[3] : Vehicles Handling (old client's slider list) ==========
	UI.window[3] = eui:uiCreateWindow(20, false, 300, 700, "Vehicles Handling", _, ":assets/icons/car.png")
	eui:uiSetVisible(UI.window[3], false)
	for i, slider in ipairs(HANDLING_SLIDERS) do
		UI.rangeslider[slider.property] = eui:uiCreateRangeSlider(20, 30 + (i - 1) * 48, 260, 40, slider.label, "primary", tocolor(30, 30, 30), true, UI.window[3])
		eui:uiSetProperty(UI.rangeslider[slider.property], "min_value", slider.min)
		eui:uiSetProperty(UI.rangeslider[slider.property], "max_value", slider.max)
		eui:uiSetProperty(UI.rangeslider[slider.property], "step_size", slider.step)
	end

	showSections()
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

-- ---------------------------------------------------------------------------
-- 2: the gridlist content, exactly like the old client
-- ---------------------------------------------------------------------------
local function moneyColumn(list, row, text)
	eui:uiGridListSetItemText(list, row, 1, text)
	eui:uiGridListSetItemColor(list, row, 1, tocolor(255, 255, 255, 255))
end

local function priceColumn(list, row, price)
	eui:uiGridListSetItemText(list, row, 2, "$" .. numberFormat(price))
	eui:uiGridListSetItemColor(list, row, 2, tocolor(0, 220, 0, 255))
	eui:uiGridListSetItemData(list, row, 1, price)
end

function showSections()
	currentSection = "sections"
	eui:uiGridListClear(UI.gridlist[1])
	for _, name in ipairs(TUNING.sections) do
		local row = eui:uiGridListAddRow(UI.gridlist[1])
		moneyColumn(UI.gridlist[1], row, name)
	end
	eui:uiSetVisible(UI.button[1], false)
	eui:uiSetVisible(UI.window[2], false)
end

local function showSectionPrices(which, entries, dataKey)
	currentSection = which
	eui:uiGridListClear(UI.gridlist[1])
	local row = eui:uiGridListAddRow(UI.gridlist[1])
	moneyColumn(UI.gridlist[1], row, "...")
	for i, entry in ipairs(entries) do
		row = eui:uiGridListAddRow(UI.gridlist[1])
		moneyColumn(UI.gridlist[1], row, entry.name)
		priceColumn(UI.gridlist[1], row, entry.price)
		if dataKey then
			eui:uiGridListSetItemData(UI.gridlist[1], row, 1, i)
		end
	end
	eui:uiSetVisible(UI.button[1], true)
	eui:uiSetVisible(UI.window[2], which == "Engines")
end

function showEngines()
	currentSection = "Engines"
	eui:uiGridListClear(UI.gridlist[1])
	local row = eui:uiGridListAddRow(UI.gridlist[1])
	moneyColumn(UI.gridlist[1], row, "...")
	for i, engine in ipairs(TUNING.engines) do
		row = eui:uiGridListAddRow(UI.gridlist[1])
		moneyColumn(UI.gridlist[1], row, engine.name)
		priceColumn(UI.gridlist[1], row, engine.price)
		eui:uiGridListSetItemData(UI.gridlist[1], row, 1, i)
	end
	eui:uiSetVisible(UI.button[1], true)
	eui:uiSetVisible(UI.window[2], true)
end

function showTinting()
	showSectionPrices("Vehicle Tinting", { TUNING.tinting.add, TUNING.tinting.remove }, false)
end

function showNeon()
	showSectionPrices("Neon", TUNING.neon, false)
end

function showBackfire()
	showSectionPrices("Back-fire", { TUNING.backfire.add, TUNING.backfire.remove }, false)
end

function showLockReplacement()
	showSectionPrices("Lock Replacement", { TUNING.lock }, false)
end

-- ---------------------------------------------------------------------------
-- 3: window[2] statistics (fed by the server sync)
-- ---------------------------------------------------------------------------
local function refreshStats()
	local h = tuningData.handling or {}
	eui:uiSetText(UI.labelValue[1], tostring(h.maxVelocity or 0) .. "  km/h")
	eui:uiSetText(UI.labelValue[2], tostring(h.engineAcceleration or 0) .. "  m/s2")
	eui:uiSetText(UI.labelValue[3], tostring(h.engineInertia or 0) .. "  kg m2")
	eui:uiSetText(UI.labelValue[4], tostring(h.driveType or "-"))
	eui:uiSetText(UI.labelValue[5], tostring(h.engineType or "-"))
	if UI.progressbar[1] then
		eui:uiProgressBarSetProgress(UI.progressbar[1], math.min(100, (tonumber(h.maxVelocity) or 0) / 360 * 100))
	end
	if UI.progressbar[2] then
		eui:uiProgressBarSetProgress(UI.progressbar[2], math.min(100, (tonumber(h.engineAcceleration) or 0) / 100 * 100))
	end
end

local function refreshHandlingSliders(handling)
	if not handling then return end
	for _, slider in ipairs(HANDLING_SLIDERS) do
		local element = UI.rangeslider[slider.property]
		if isElement(element) and handling[slider.property] then
			eui:uiRangeSliderSetValue(element, handling[slider.property])
		end
	end
end

-- ---------------------------------------------------------------------------
-- 4: server <-> client plumbing
-- ---------------------------------------------------------------------------
addEvent(TUNING.EVENTS.sync, true)
addEventHandler(TUNING.EVENTS.sync, localPlayer, function(data)
	if type(data) ~= "table" then return end
	tuningData = data
	refreshStats()
end)

-- The server pushes the live handling table on request (opening window[3]).
addEvent("vehtuning:handling:values", true)
addEventHandler("vehtuning:handling:values", localPlayer, function(handling)
	refreshHandlingSliders(handling)
end)

local function closeUIWindows()
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window[2], false)
	eui:uiSetVisible(UI.window[3], false)
	handlingWindowOpen = false
	if currentVehicle then
		restoreNeon(currentVehicle)
		currentVehicle = false
	end
	showCursor(false)
end

addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

-- ---------------------------------------------------------------------------
-- 5: clicks - mirrors the old client's onClientUIClick / onClientUIDoubleClick
-- ---------------------------------------------------------------------------
local function selectedRow()
	return eui:uiGridListGetSelectedItem(UI.gridlist[1])
end

local function selectedText()
	local row = selectedRow()
	if row == -1 then return nil, nil end
	return eui:uiGridListGetItemText(UI.gridlist[1], row, 1), eui:uiGridListGetItemData(UI.gridlist[1], row, 1)
end

addEventHandler("onClientUIDoubleClick", root, function()
	if source ~= UI.gridlist[1] then return end
	local row = selectedRow()
	if row == -1 then return end
	if currentSection ~= "sections" then
		if row == 0 then showSections() end
		return
	end
	local name = eui:uiGridListGetItemText(UI.gridlist[1], row, 1)
	if name == "Engines" then
		showEngines()
	elseif name == "Vehicle Tinting" then
		showTinting()
	elseif name == "Neon" then
		showNeon()
	elseif name == "Back-fire" then
		showBackfire()
	elseif name == "Lock Replacement" then
		showLockReplacement()
	end
end)

addEventHandler("onClientUIClick", root, function()
	if source == UI.gridlist[1] then
		local row = selectedRow()
		if row == -1 or not currentVehicle then return end
		local text, data = selectedText()
		if currentSection == "Engines" and data then
			local engine = TUNING.engines[data]
			if engine then
				tuningData.handling = {
					maxVelocity = engine.maxVelocity,
					engineAcceleration = engine.engineAcceleration,
					engineInertia = engine.engineInertia,
					driveType = engine.driveType,
					engineType = engine.engineType,
				}
				refreshStats()
			end
		elseif currentSection == "Neon" then
			-- the old client previewed the colour on the vehicle immediately
			-- row 0 = the "..." placeholder, row 1 = "Remove Neon", row 2+ = a colour
			if isNeonModelSupported(getElementModel(currentVehicle)) then
				if row <= 1 then
					removeNeon(currentVehicle)
				else
					addNeon(currentVehicle, row - 1)
				end
			else
				exports.notifications:output({ en = "You cannot install neon lights on this vehicle", ar = "لا يمكنك تركيب ضوء نيون على هذه السيارة" }, 3000, "error")
			end
		end
	elseif source == UI.button[1] then
		if not currentVehicle then return end
		local row = selectedRow()
		if row == -1 then return end
		local text, data = selectedText()
		if currentSection == "Engines" and data then
			local vtype = getVehicleType(currentVehicle)
			if vtype ~= "Automobile" and vtype ~= "Monster Truck" then
				exports.notifications:output({ en = "You can't tune this vehicle", ar = "لا يمكنك تعديل هذه المركبة" }, 3000, "error")
			else
				triggerServerEvent(TUNING.EVENTS.purchaseEngine, localPlayer, data)
				eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
			end
		elseif currentSection == "Vehicle Tinting" then
			triggerServerEvent(TUNING.EVENTS.purchaseTint, localPlayer, row == 1 and "add" or "remove", data)
			eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
		elseif currentSection == "Neon" then
			triggerServerEvent(TUNING.EVENTS.purchaseNeon, localPlayer, row, data)
			eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
		elseif currentSection == "Back-fire" then
			triggerServerEvent(TUNING.EVENTS.purchaseBack, localPlayer, row == 1 and "add" or "remove", data)
			eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
		elseif currentSection == "Lock Replacement" then
			triggerServerEvent(TUNING.EVENTS.replaceLock, localPlayer)
			eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
		end
	elseif source == UI.button[2] then
		closeUIWindows()
	end
end)

-- Restore the stored neon when the panel closes (old client's
-- onClientUIVisibilityChange behaviour).
addEventHandler("onClientUIVisibilityChange", root, function(visible)
	if visible or source ~= UI.window[1] then return end
	if currentVehicle then
		restoreNeon(currentVehicle)
	end
end)

-- ---------------------------------------------------------------------------
-- 6: neon - client side objects/lights driven by the synced `neon` element data
-- ---------------------------------------------------------------------------
local neonElements = {}

local function neonColor(index)
	local entry = TUNING.neon[(tonumber(index) or 0) + 1]
	if entry and entry.rgb then return entry.rgb[1], entry.rgb[2], entry.rgb[3] end
	return 255, 255, 255
end

-- createLight(lightType, x, y, z, radius, r, g, b) - the radius is what makes
-- the glow visible, and MTA only lights up the ground under a vehicle when at
-- least two lights overlap it (a single light only reaches peds, players,
-- wheels and number plates).  The old client's two mirrored tubes do exactly
-- that, so the fallback keeps two lights as well.
local NEON_LIGHT_RADIUS = 1.8

local function worldFromOffset(element, offX, offY, offZ)
	local m = getElementMatrix(element)
	if not m then return nil end
	return offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1],
		offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2],
		offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
end

local function destroyNeon(veh)
	local entry = neonElements[veh]
	if not entry then return end
	for _, element in ipairs(entry.elements) do
		if isElement(element) then destroyElement(element) end
	end
	neonElements[veh] = nil
end

function removeNeon(veh)
	destroyNeon(veh)
end

function addNeon(veh, colorIndex)
	if not isElement(veh) then return end
	destroyNeon(veh)
	if not isNeonModelSupported(getElementModel(veh)) then return end

	local r, g, b = neonColor(colorIndex)
	local offset = TUNING.neonOffsets[getElementModel(veh)] or TUNING.neonDefaultOffset
	local elements, lights, offsets = {}, {}, {}

	for _, side in ipairs({ 1, -1 }) do
		local ox, oy, oz = side * offset[1], offset[2], offset[3]
		local element, isLight

		if TUNING.neonUseObjects then
			-- the original tube model (needs the `mods` customModel pack)
			element = createObject(TUNING.neonObjectModel, 0, 0, 0)
			if element then
				setObjectColor(element, r, g, b)
			end
		end

		if not element then
			-- fallback: a real light pool under the car, positioned every frame
			-- from the vehicle's matrix so it follows the car exactly
			element = createLight(0, 0, 0, 0, NEON_LIGHT_RADIUS, r, g, b)
			isLight = isElement(element)
		end

		if isElement(element) then
			setElementDimension(element, getElementDimension(veh))
			setElementInterior(element, getElementInterior(veh))
			if isLight then
				local x, y, z = worldFromOffset(veh, ox, oy, oz)
				if x then setElementPosition(element, x, y, z) end
				lights[#lights + 1] = element
				offsets[#offsets + 1] = { ox, oy, oz }
			else
				attachElements(element, veh, ox, oy, oz)
			end
			elements[#elements + 1] = element
		end
	end

	neonElements[veh] = #elements > 0 and { elements = elements, lights = lights, offsets = offsets } or nil
end

function restoreNeon(veh)
	local data = getElementData(veh, "neon")
	if type(data) == "table" and data[2] == 1 then
		addNeon(veh, data[1])
	else
		destroyNeon(veh)
	end
end

addEventHandler("onClientElementStreamIn", root, function()
	if getElementType(source) ~= "vehicle" then return end
	restoreNeon(source)
end)

addEventHandler("onClientElementStreamOut", root, function()
	if getElementType(source) ~= "vehicle" then return end
	destroyNeon(source)
end)

addEventHandler("onClientElementDataChange", root, function(dataName)
	if dataName ~= "neon" or getElementType(source) ~= "vehicle" then return end
	if not isElementStreamedIn(source) then return end
	restoreNeon(source)
end)

addEventHandler("onClientElementDimensionChange", root, function()
	local entry = neonElements[source]
	if not entry then return end
	for _, element in ipairs(entry.elements) do
		if isElement(element) then setElementDimension(element, getElementDimension(source)) end
	end
end)

addEventHandler("onClientElementInteriorChange", root, function()
	local entry = neonElements[source]
	if not entry then return end
	for _, element in ipairs(entry.elements) do
		if isElement(element) then setElementInterior(element, getElementInterior(source)) end
	end
end)

-- lights do not follow their vehicle on their own, so keep them glued to the
-- stored offsets (the same offsets the old client's tubes were attached with)
addEventHandler("onClientPreRender", root, function()
	for veh, entry in pairs(neonElements) do
		if #entry.lights > 0 and isElement(veh) and isElementStreamedIn(veh) then
			local dimension, interior = getElementDimension(veh), getElementInterior(veh)
			for i, light in ipairs(entry.lights) do
				if isElement(light) then
					local offset = entry.offsets[i]
					local x, y, z = worldFromOffset(veh, offset[1], offset[2], offset[3])
					if x then
						setElementPosition(light, x, y, z)
						setElementDimension(light, dimension)
						setElementInterior(light, interior)
					end
				end
			end
		end
	end
end)

addEventHandler("onClientElementDestroy", root, function()
	destroyNeon(source)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
	for veh in pairs(neonElements) do
		destroyNeon(veh)
	end
end)

-- ---------------------------------------------------------------------------
-- 7: back-fire - flames out of the exhaust when the throttle is released
-- ---------------------------------------------------------------------------
local function getPositionFromElementOffset(element, offX, offY, offZ)
	local m = getElementMatrix(element)
	if not m then return nil end
	return offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1],
		offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2],
		offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
end

local wasAccelerating = false

addEventHandler("onClientPreRender", root, function()
	local veh = getPedOccupiedVehicle(localPlayer)
	if not veh or getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
		wasAccelerating = false
		return
	end
	if getElementData(veh, "backfire") ~= true then
		wasAccelerating = false
		return
	end

	local accelerating = getControlState("accelerate") == true
	if wasAccelerating and not accelerating and getVehicleEngineState(veh) then
		local x, y, z = getPositionFromElementOffset(veh, -2.0, 0, 0.3)
		if x then
			fxAddGunshot(x, y, z, 0, 0, 0.15, true)
			fxAddGunshot(x, y, z, 0.6, 0, 0.1, true)
			fxAddGunshot(x, y, z, -0.6, 0, 0.1, true)
		end
	end
	wasAccelerating = accelerating
end)

-- ---------------------------------------------------------------------------
-- 8: the old client's garage markers + blips
--    ("كراج تعديل السيارات", createMarker + createBlip + blip:name)
-- ---------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
	for _, pos in ipairs(TUNING.locations) do
		local marker = createMarker(pos[1], pos[2], pos[3] - 1, "cylinder", 2.2, 0, 150, 255, 120)
		if marker then
			setElementData(marker, "vehtuning:marker", true)
		end
		local blip = createBlip(pos[1], pos[2], pos[3], 63)
		if blip then
			setElementData(blip, "blip:name", TUNING.blipName)
		end
	end
end)

addEventHandler("onClientMarkerHit", resourceRoot, function(hitElement, matchingDimension)
	if hitElement ~= localPlayer then return end
	if not getElementData(source, "vehtuning:marker") then return end
	if not matchingDimension then return end

	if isPedInVehicle(localPlayer) then
		if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then return end
		local veh = getPedOccupiedVehicle(localPlayer)
		if getVehicleType(veh) == "BMX" then
			exports.notifications:output({ en = "You can't tune this vehicle", ar = "لا يمكنك تعديل هذه المركبة" }, 3000, "error")
			return
		end
		currentVehicle = veh
		showSections()
		eui:uiSetVisible(UI.window[1], true)
		eui:uiSetVisible(UI.window[2], false)
		showCursor(true)
		exports.notifications:showKeyDescription("vehtuning:handling", "H", "Vehicle handling editor (staff)")
		triggerServerEvent("vehtuning:request", localPlayer)
		local x, y, z = getElementPosition(source)
		setElementVelocity(veh, 0, 0, 0)
		setElementPosition(veh, x, y, z)
		setElementAlpha(source, 0)
	else
		exports.notifications:output({ en = "You should be in a vehicle", ar = "يجب أن تكون في سيارة" }, 3000, "error")
	end
end)

addEventHandler("onClientMarkerLeave", resourceRoot, function(hitElement)
	if hitElement ~= localPlayer then return end
	if not getElementData(source, "vehtuning:marker") then return end
	closeUIWindows()
	setElementAlpha(source, 150)
	exports.notifications:hideKeyDescription("vehtuning:handling")
end)

-- H toggles window[3] (staff only - enforced server side), Enter applies it
bindKey("h", "down", function()
	if not eui or not isElement(UI.window[1]) then return end
	if not eui:uiGetVisible(UI.window[1]) then return end
	handlingWindowOpen = not handlingWindowOpen
	eui:uiSetVisible(UI.window[3], handlingWindowOpen)
	if handlingWindowOpen then
		triggerServerEvent("vehtuning:handling:requestValues", localPlayer)
	end
end)

bindKey("num_enter", "down", function()
	if not handlingWindowOpen then return end
	local values = {}
	for _, slider in ipairs(HANDLING_SLIDERS) do
		local element = UI.rangeslider[slider.property]
		if isElement(element) then
			values[slider.property] = eui:uiRangeSliderGetValue(element)
		end
	end
	triggerServerEvent("vehtuning:handling:apply", localPlayer, values)
end)
