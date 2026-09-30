-- ============================================================================
-- interior-system / c_interior_ui.lua                        (Fix #66)
-- ----------------------------------------------------------------------------
-- Client half, restored 1:1 from the old Owl client:
--   /home/daytona/backupm/[rp]/interior-system/int_c_decompiled.lua
--
-- Every panel keeps the old client's exact numbers and UIKit calls:
--
--   window[1] "Purchase Property" / "Rent Property"  uiCreateWindow(false,false,439,187)
--             label info (10, 40, 420, 15)
--             label Interior Name (10, 70)  label Address (10, 90)  label Pricing (10,125, centered)
--             button Purchase/Rent (5, 152, 120, 30)  Preview Interior (130, 152, 130, 30)
--             button Cancel (314, 152, 120, 30)
--   window[2] "Property Panel"  uiCreateWindow(false,false,439,237)
--             label text (10, 40, 420, 130)
--             button Sell property (5, 202, 120, 30)  button Cancel (314, 202, 120, 30)
--   window.CheckInt "Check Interior"  uiCreateWindow(false,false,400,350)
--             label Logs (10, 50, 380, 150)  button Close (0, 320, 400, 30)
--
-- Plus the old client's in-world layer: the "Interior ID#x / Press F ... OR
-- Press H to show property panel" directive, the F/H key descriptions and the
-- interior name drawn at the bottom of the screen.
--
-- The H key (property panel) and the marker hit/leave detection are fed by
-- s_interior_ui.lua, which validates everything server side.
--
-- Deviations (documented on purpose):
--  * this file is registered before c_pickups.lua so its colshape handler runs
--    first (c_pickups cancels the event), and c_pickups' own bottom-screen HUD
--    was switched off in favour of the old client's directive + name draw.
--  * the old client's setPlayerInsideInterior relay already lives in
--    c_interior_system.lua, so it is not duplicated here.
-- ============================================================================

eui = exports.UIKit

local localPlayer = getLocalPlayer()
local root = getRootElement()

local UI = {
	window = {},
	label = {},
	button = {},
}

-- The old client also drew a full in-world directive ("Interior ID#x / Press F
-- ... / OR Press H ...") and its own name draw.  c_pickups.lua already draws
-- that bottom-screen HUD (name, owner, price, "Press F to ...") on this server,
-- so only the H hint is added here.  Flip this to true for the old client's
-- directive; then also switch off renderInteriorName in c_pickups.lua.
local SHOW_DIRECTIVE = false

local currentIntID = false          -- interior id of the open Property Panel
local currentIntToBuy = false       -- interior id of the open Purchase/Rent window
local currentIsRent = false
local currentInterior = false       -- the interior element the player is standing at
local interiorName = ""             -- drawn at the bottom of the screen
local drawingName = false
local scrWidth, scrHeight = guiGetScreenSize()

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function L(text)
	if type(text) == "table" then
		local pick = language and text[language] or nil
		return tostring(pick or text.en or text.ar or "")
	end
	return tostring(text or "")
end

local function money(amount)
	local formatted = tostring(math.floor(tonumber(amount) or 0))
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- ---------------------------------------------------------------------------
-- 1: the old client's three panels
-- ---------------------------------------------------------------------------
function UIKitReady()
	eui = exports.UIKit

	-- === window[1] : Purchase Property / Rent Property =====================
	UI.window[1] = eui:uiCreateWindow(false, false, 439, 187, { en = "Purchase Property", ar = "شراء عقار" })
	eui:uiWindowSetMovable(UI.window[1], false)
	eui:uiSetVisible(UI.window[1], false)
	eui:uiCreateLabel(10, 40, 420, 15, { en = "Please confirm the following information about this property.", ar = "من فضلك أكد المعلومات التالية عن هذا العقار." }, tocolor(255, 255, 255, 240), "left", "top", UI.window[1])
	UI.label[1] = eui:uiCreateLabel(10, 70, 420, 15, "", "primary", "left", "top", UI.window[1])
	UI.label[2] = eui:uiCreateLabel(10, 90, 420, 15, "", "primary", "left", "top", UI.window[1])
	UI.label[3] = eui:uiCreateLabel(10, 125, 420, 15, "", tocolor(255, 255, 255, 230), "left", "top", UI.window[1])
	eui:uiSetAlign(UI.label[3], "center", "center")
	UI.button[1] = eui:uiCreateButton(5, 152, 120, 30, { en = "Purchase", ar = "شراء" }, nil, UI.window[1])
	UI.button[2] = eui:uiCreateButton(314, 152, 120, 30, { en = "Cancel", ar = "إلغاء" }, nil, UI.window[1])
	UI.button[3] = eui:uiCreateButton(130, 152, 130, 30, { en = "Preview Interior", ar = "معاينة من الداخل" }, nil, UI.window[1])

	-- === window[2] : Property Panel =======================================
	UI.window[2] = eui:uiCreateWindow(false, false, 439, 237, { en = "Property Panel", ar = "لوحة العقار" })
	eui:uiWindowSetMovable(UI.window[2], false)
	eui:uiSetVisible(UI.window[2], false)
	UI.label[4] = eui:uiCreateLabel(10, 40, 420, 130, "", "primary", "left", "top", UI.window[2])
	eui:uiSetProperty(UI.label[4], "word_break", true)
	UI.button[5] = eui:uiCreateButton(5, 202, 120, 30, { en = "Sell property", ar = "بيع" }, nil, UI.window[2])
	UI.button[4] = eui:uiCreateButton(314, 202, 120, 30, { en = "Cancel", ar = "إلغاء" }, nil, UI.window[2])

	-- === window.CheckInt : Check Interior =================================
	UI.window.CheckInt = eui:uiCreateWindow(false, false, 400, 350, { en = "Check Interior", ar = "فحص العقار" })
	eui:uiWindowSetMovable(UI.window.CheckInt, false)
	eui:uiSetVisible(UI.window.CheckInt, false)
	UI.label.Logs = eui:uiCreateLabel(10, 50, 380, 150, "", tocolor(255, 255, 255, 255), "left", "top", UI.window.CheckInt)
	eui:uiSetProperty(UI.label.Logs, "word_break", true)
	UI.button.CloseCheckInt = eui:uiCreateButton(0, 320, 400, 30, { en = "Close", ar = "إغلاق" }, nil, UI.window.CheckInt)
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function closeUIWindows()
	if not isElement(UI.window[1]) then return end
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window[2], false)
	eui:uiSetVisible(UI.window.CheckInt, false)
	currentIntID = false
	currentIntToBuy = false
	showCursor(false)
end

addEvent("interior:closeWindows", true)
addEventHandler("interior:closeWindows", root, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

-- ---------------------------------------------------------------------------
-- 2: marker hints - the old client's directive, F/H key descriptions and the
--    interior name at the bottom of the screen
-- ---------------------------------------------------------------------------
local function drawInteriorName()
	if interiorName == "" then
		if drawingName then
			removeEventHandler("onClientRender", root, drawInteriorName)
			drawingName = false
		end
		return
	end
	dxDrawText(interiorName, 0, scrHeight - 60, scrWidth, scrHeight, tocolor(0, 0, 0, 220), 2, "arial", "center", "center", false, false, false, false, false)
	dxDrawText(interiorName, 0, scrHeight - 60, scrWidth, scrHeight, tocolor(255, 255, 255, 220), 2, "arial", "center", "center", false, false, false, false, false)
end

addEvent("interior:onClientMarkerHit", true)
addEventHandler("interior:onClientMarkerHit", root, function(id, actionText, showPanel, name)
	currentIntID = tonumber(id)
	interiorName = tostring(name or "")
	local action = L(actionText)

	if showPanel then
		exports.notifications:showKeyDescription("interior:panel", "H", { en = "Show property panel", ar = "عرض لوحة العقار" })
	end

	if not SHOW_DIRECTIVE then return end

	if not drawingName then
		addEventHandler("onClientRender", root, drawInteriorName)
		drawingName = true
	end

	if showPanel then
		exports.notifications:showDirective({
			en = "Interior ID#" .. tostring(id) .. "\n\nPress #ff375f'F'#FFFFFF to " .. action .. "\n\n#a9a9a9OR\n\n#FFFFFFPress #ff375f'H'#FFFFFF to show property panel",
			ar = "رقم العقار #" .. tostring(id) .. "\n\nاضغط #ff375f'F'#FFFFFF لـ" .. action .. "\n\n#a9a9a9أو\n\n#FFFFFFاضغط #ff375f'H'#FFFFFF لعرض لوحة العقار",
		}, tocolor(255, 255, 255, 255))
		exports.notifications:showKeyDescription("interior:enter", "F", actionText)
	else
		exports.notifications:showKeyDescription("interior:enter", "F", actionText)
		exports.notifications:showDirective({
			en = "Interior ID#" .. tostring(id) .. "\n\nPress #ff375f'F'#FFFFFF to " .. action,
			ar = "رقم العقار #" .. tostring(id) .. "\n\nاضغط #ff375f'F'#FFFFFF لـ" .. action,
		}, tocolor(255, 255, 255, 255))
	end
end)

addEvent("interior:onClientMarkerLeave", true)
addEventHandler("interior:onClientMarkerLeave", root, function()
	interiorName = ""
	currentInterior = false
	removeEventHandler("onClientRender", root, drawInteriorName)
	drawingName = false
	exports.notifications:hideDirective()
	exports.notifications:hideKeyDescription("interior:enter")
	exports.notifications:hideKeyDescription("interior:panel")
end)

-- the old client got this from the server; here the client reports the door it
-- reached and s_interior_ui.lua answers with the directive payload
local function reportMarkerHit(colshape)
	local interior = getElementParent(getElementParent(colshape))
	local kind = getElementType(interior)
	if kind ~= "interior" and kind ~= "elevator" then return end

	currentInterior = interior
	triggerServerEvent("interior:markerHit", localPlayer, interior)
end

-- NOTE: registered before c_pickups.lua (meta order), which cancels the event
addEventHandler("onClientColShapeHit", root, function(element, matchingDimension)
	if element ~= localPlayer or not matchingDimension then return end
	reportMarkerHit(source)
end)

addEventHandler("onClientColShapeLeave", root, function(element)
	if element ~= localPlayer then return end
	local interior = getElementParent(getElementParent(source))
	local kind = getElementType(interior)
	if kind ~= "interior" and kind ~= "elevator" then return end
	if interior ~= currentInterior then return end
	currentInterior = false
	triggerServerEvent("interior:markerLeave", localPlayer, interior)
end)

-- the old client's H key: show the property panel of the door in front of you
bindKey("h", "down", function()
	if isElement(currentInterior) and currentInterior then
		triggerServerEvent("interior:panelRequest", localPlayer, currentInterior)
	end
end)

-- the old client's interior sounds event
addEvent("interior:playSound", true)
addEventHandler("interior:playSound", root, function(file, x, y, z, interior, dimension)
	local sound = playSound3D(file, x, y, z, false)
	if sound then
		setElementInterior(sound, interior)
		setElementDimension(sound, dimension)
	end
end)

-- ---------------------------------------------------------------------------
-- 3: Property Panel
-- ---------------------------------------------------------------------------
local function panelText(interior, id, name, address, data, sellFactor)
	local status = getElementData(interior, "status")
	local type_ = type(status) == "table" and tonumber(status[INTERIOR_TYPE]) or 2
	local ownerName = data.Owner or "-"
	local renterName = data.Renter or "-"
	if type_ == 3 then
		ownerName = data.OriginalOwner or "-"
	end

	local lines = {
		"${color.primary}• Interior ID  »  #FFFFFF" .. tostring(id),
		"${color.primary}• Interior Name  »  #FFFFFF" .. tostring(name),
		"${color.primary}• Address  »  #FFFFFF" .. tostring(address),
		"${color.primary}• Original Price  »  #00FF00$" .. money(data.OriginalPrice or 0),
		"${color.primary}• Purchase Price  »  #00FF00$" .. money(data.PurchasePrice or 0),
		"${color.primary}• The date of purchase  »  #FFFFFF" .. tostring(data.PurchaseDate or "-"),
		"${color.primary}• Owner  »  #FFFFFF" .. ownerName,
		"${color.primary}• Renter  »  #FFFFFF" .. renterName,
		"You can sell this property for #00FF00$" .. money(data.SellPrice or math.ceil((tonumber(data.PurchasePrice) or 0) * (sellFactor or 0))),
	}
	return table.concat(lines, "\n")
end

addEvent("interior:openPanel", true)
addEventHandler("interior:openPanel", root, function(interior, marker, ownerName, data, sellFactor)
	if not isElement(interior) then return end
	data = type(data) == "table" and data or {}

	currentIntID = tonumber(getElementData(interior, "dbid"))
	eui:uiSetVisible(UI.window[2], true)
	eui:uiBringToFront(UI.window[2])
	showCursor(true)
	eui:uiSetText(UI.label[4], panelText(interior, currentIntID, getElementData(interior, "name"), data.Address, data, sellFactor))
end)

-- ---------------------------------------------------------------------------
-- 4: Purchase / Rent window
-- ---------------------------------------------------------------------------
local function openPurchaseWindow(interior, data, isRent)
	if not isElement(interior) then return end

	-- same guard the classic window had: while previewing a property the door
	-- sends you back out first (see purchasePropertyGUI)
	if getElementData(localPlayer, "viewingInterior") == 1 then
		triggerServerEvent("endViewPropertyInterior", localPlayer, localPlayer, tonumber(getElementData(interior, "dbid")))
		return
	end

	data = type(data) == "table" and data or {}

	local price = tonumber(data.Price) or tonumber(data.OriginalPrice) or tonumber(getElementData(interior, "interior:price")) or 0
	local tax = math.floor(price * 0.0025)
	currentIntToBuy = tonumber(getElementData(interior, "dbid"))
	currentIsRent = isRent == true

	eui:uiSetVisible(UI.window[1], true)
	eui:uiBringToFront(UI.window[1])
	showCursor(true)
	eui:uiSetText(UI.window[1], isRent and { en = "Rent Property", ar = "استئجار عقار" } or { en = "Purchase Property", ar = "شراء عقار" })
	eui:uiSetText(UI.button[1], isRent and { en = "Rent", ar = "استئجار" } or { en = "Purchase", ar = "شراء" })
	eui:uiSetText(UI.label[1], "• Interior Name  »  #FFFFFF" .. tostring(data.Name or getElementData(interior, "name")))
	eui:uiSetText(UI.label[2], "• Address  »  #FFFFFF" .. tostring(data.Address or "-"))
	eui:uiSetText(UI.label[3], {
		en = "Pricing: #00FF00$" .. money(price) .. " #FFFFFFwith tax ($" .. money(tax) .. ")",
		ar = "السعر: #00FF00$" .. money(price) .. " #FFFFFFمع ضريبة ($" .. money(tax) .. ")",
	})
end

addEvent("interior:openPurchaseWindow", true)
addEventHandler("interior:openPurchaseWindow", root, function(interior, marker, data)
	openPurchaseWindow(interior, data, false)
end)

addEvent("interior:openRentWindow", true)
addEventHandler("interior:openRentWindow", root, function(interior, marker, data)
	openPurchaseWindow(interior, data, true)
end)

-- ---------------------------------------------------------------------------
-- 5: Check Interior
-- ---------------------------------------------------------------------------
local LOG_LABELS = {
	{ key = "ENTER", en = "Last Enter", ar = "آخر دخول" },
	{ key = "EXIT", en = "Last Exit", ar = "آخر خروج" },
	{ key = "LOCK", en = "Last Lock", ar = "آخر قفل" },
	{ key = "UNLOCK", en = "Last Unlock", ar = "آخر فتح" },
}

addEvent("interiors:checkint", true)
addEventHandler("interiors:checkint", root, function(id, logs)
	logs = type(logs) == "table" and logs or {}
	local buffer = {}
	for _, entry in ipairs(LOG_LABELS) do
		local record = logs[entry.key]
		local value, time = "-", "-"
		if type(record) == "table" then
			value = tostring(record.value or "-")
			time = tostring(record.time or "-")
		end
		buffer[#buffer + 1] = "${color.primary}• " .. L(entry) .. "  »\n    #FFFFFF" .. value .. "  (" .. time .. ")\n"
	end

	eui:uiSetVisible(UI.window.CheckInt, true)
	eui:uiBringToFront(UI.window.CheckInt)
	showCursor(true)
	eui:uiSetText(UI.label.Logs, table.concat(buffer))
	eui:uiSetText(UI.window.CheckInt, { en = "Check Interior ID #" .. tostring(id), ar = "فحص العقار رقم #" .. tostring(id) })
end)

-- ---------------------------------------------------------------------------
-- 6: clicks - mirrors the old client's onClientUIClick
-- ---------------------------------------------------------------------------
addEventHandler("onClientUIClick", root, function()
	if not isElement(UI.window[1]) then return end

	if source == UI.button[1] then
		if currentIntToBuy then
			triggerServerEvent(currentIsRent and "interior:rentInterior" or "interior:buyInterior", localPlayer, currentIntToBuy)
		end
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	elseif source == UI.button[3] then
		if currentIntToBuy then
			triggerServerEvent("interior:previewInterior", localPlayer, currentIntToBuy)
		end
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	elseif source == UI.button[2] then
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	elseif source == UI.button[4] then
		eui:uiSetVisible(UI.window[2], false)
		showCursor(false)
	elseif source == UI.button[5] then
		if currentIntID then
			triggerServerEvent("interior:sellInterior", localPlayer, currentIntID)
		end
		eui:uiSetVisible(UI.window[2], false)
		showCursor(false)
	elseif source == UI.button.CloseCheckInt then
		eui:uiSetVisible(UI.window.CheckInt, false)
		showCursor(false)
	end
end)
