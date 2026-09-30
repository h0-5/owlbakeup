-- Decompiled by Owl Decompiler v1.0 ([jobs]/farmer/farmer_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1/var2 = the drug-dealer family merge (insidePlantMarker /
--     plantMarkers map / harvestBusy / harvestTargetMarker) - split exactly
--     like the drug port.
--   * the plant-overlap 2D distance lost its second position - restored.
--   * the sell window lost the count + price accumulators ("You have: N
--     fish" - the original says FISH, a fishing copy-paste; byte-exact).
--   * the crops scan adapted to the repo item-system (crop items 235/236
--     via FACTORY-style FACTORY_ITEM_IDS map: CROP_ITEM_IDS).
--   * drawPlantsLabels: the decompiler destroyed the draw math into
--     nonsense (table.sort on a split result). Restored to the evident
--     intent: a "<plant type> Plant\n\n** Ready to Harvest **" label above
--     each grown plant (plant IDs are "plant:<uid>:<type>" so split(":")[3]
--     is the type - the harvest ID is split(":")[2], consistent).
--   * the plant trigger: farmer:startFarming has no visible trigger in the
--     decompile (the Owl seeds-shop flow is lost) - reconstructed with a
--     right-click field marker at the farm, same as the drug/liquor ports.
--   * takeJob/harvest events identical to the drug family (uid = part 2).

local CROP_ITEM_IDS = {
	Carrot = 235,
	Corn = 236
}
local CROP_PRICES = {
	Carrot = 55,
	Corn = 35
}

local plantMarkers = {}
local insidePlantMarker = false
local harvestBusy = false
local harvestMarker = false
local harvestTargetMarker = false

addEvent("farmer:startFarming", true)
addEventHandler("farmer:startFarming", root, function(seedType)
	if not getElementData(localPlayer, "character:id") then
		return
	end
	if isPedDead(localPlayer) then
		return
	end
	if isPedInVehicle(localPlayer) then
		return
	end
	if isPedOnGround(localPlayer) then
		if getElementData(localPlayer, "job") == "Farmer" then
			if insidePlantMarker and isElement(insidePlantMarker) and isElementWithinMarker(localPlayer, insidePlantMarker) then
				outputChatBox("You cannot plant over another plant.", 255, 60, 0)
				return
			end
			local px, py = getElementPosition(localPlayer)
			for _, obj in ipairs(getElementsByType("object", resourceRoot)) do
				if getElementInterior(obj) == getElementInterior(localPlayer) and getElementDimension(obj) == getElementDimension(localPlayer) then
					local ox, oy = getElementPosition(obj)
					if getDistanceBetweenPoints2D(px, py, ox, oy) <= 1 and getElementID(obj) and string.find(getElementID(obj), "plant:", 1, true) then
						outputChatBox("You cannot plant over another plant.", 255, 60, 0)
						return
					end
				end
			end
			triggerServerEvent("farmer:plant", localPlayer, plant_types[seedType].name, plant_types[seedType].model, getElementPosition(localPlayer))
			destroyElement(createObject(plant_types[seedType].model, getElementPosition(localPlayer)))
		else
			outputChatBox("You must be a farmer to be able to plant this seeds.", 255, 68, 0)
		end
	end
end)

addEvent("farmer:createPlantMarker", true)
addEventHandler("farmer:createPlantMarker", root, function(x, y, z, plantObject)
	local marker = createMarker(x, y, z - 0.7, "cylinder", 1, 7, 181, 54, 100)
	if isElementWithinMarker(localPlayer, marker) then
		insidePlantMarker = marker
	end
	plantMarkers[marker] = plantObject
end)

addEvent("farmer:syncPlantsMarkers", true)
addEventHandler("farmer:syncPlantsMarkers", root, function(plants)
	for _, plant in ipairs(plants) do
		local marker = createMarker(unpack(plant[2]))
		if isElementWithinMarker(localPlayer, marker) then
			insidePlantMarker = marker
		end
		plantMarkers[marker] = plant[1]
	end
end)

addEventHandler("onClientMarkerHit", resourceRoot, function(player, matchingDimension)
	if not matchingDimension then
		return
	end
	if player ~= localPlayer then
		return
	end
	if plantMarkers[source] and isElement(plantMarkers[source]) then
		harvestMarker = source
		if isPedOnGround(localPlayer) and not isObjectMoving(plantMarkers[source]) then
			if isPedInVehicle(localPlayer) then
				return
			end
			bindKey("H", "down", harvestKey, source)
			exports.notifications:showKeyDescription("farmer:harvest", "H", "Harvest")
		end
	end
end)

addEventHandler("onClientMarkerLeave", resourceRoot, function(player, matchingDimension)
	if player ~= localPlayer then
		return
	end
	if plantMarkers[source] then
		harvestMarker = false
		if isElement(plantMarkers[source]) and isObjectMoving(plantMarkers[source]) then
		else
			unbindKey("H", "down", harvestKey, source)
			exports.notifications:hideKeyDescription("farmer:harvest")
		end
	end
end)

function harvestKey(key, keyState, marker)
	if isElement(marker) then
		if harvestBusy then
			return
		end
		if isPedDead(localPlayer) then
			return
		end
		if isPedInVehicle(localPlayer) then
			return
		end
		if not isPedOnGround(localPlayer) then
			return
		end
		if plantMarkers[marker] and getElementID(plantMarkers[marker]) then
			harvestBusy = true
			harvestTargetMarker = marker
			triggerServerEvent("farmer:harvest", localPlayer, split(getElementID(plantMarkers[marker]), ":")[2])
			unbindKey("H", "down", harvestKey, source)
			exports.notifications:hideKeyDescription("farmer:harvest")
		end
	end
end

addEvent("farmer:harvest:callback", true)
addEventHandler("farmer:harvest:callback", localPlayer, function(success)
	if success and isElement(harvestTargetMarker) then
		destroyElement(harvestTargetMarker)
		plantMarkers[harvestTargetMarker] = nil
	end
	harvestBusy = false
	harvestTargetMarker = false
end)

addEventHandler("onClientElementDestroy", resourceRoot, function()
	if getElementType(source) == "object" then
		for marker, plantObject in pairs(plantMarkers) do
			if plantObject == source then
				if marker ~= harvestTargetMarker and isElement(marker) then
					plantMarkers[marker] = nil
					destroyElement(marker)
				end
				break
			end
		end
	end
end)

function drawPlantsLabels()
	if isPlayerMapVisible() then
		return
	end
	local cx, cy, cz, ctx, cty, ctz = getCameraMatrix()
	for _, plant in ipairs(getElementsWithinRange(cx, cy, cz, 30, "object", getElementInterior(localPlayer), getElementDimension(localPlayer))) do
		local id = getElementID(plant)
		if id and string.find(id, "plant:", 1, true) then
			local x, y, z = getElementPosition(plant)
			local sxp, syp = getScreenFromWorldPosition(x, y, z + 1.5)
			if sxp and isLineOfSightClear(cx, cy, cz, x, y, z, true, false, false, true) then
				local parts = split(id, ":")
				local text = tostring(parts[3]) .. " Plant\n\n** Ready to Harvest **"
				local width = math.max(dxGetTextWidth(text, 1, "default-bold"), 100) + 15
				local height = 15 * #split(text, "\n") + 9
				dxDrawRectangle(sxp - width / 2, syp - height / 2, width, height, tocolor(0, 0, 0, 120))
				dxDrawText(text, sxp + 2, syp + 2, sxp, syp, tocolor(0, 0, 0, 255), 1, "default-bold", "center", "center")
				dxDrawText(text, sxp, syp, sxp, syp, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center")
			end
		end
	end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	if getElementData(localPlayer, "describtion:show") then
		addEventHandler("onClientRender", root, drawPlantsLabels)
	end
end)
addEventHandler("onClientElementDataChange", localPlayer, function(key, newValue)
	if key == "describtion:show" then
		if getElementData(localPlayer, "describtion:show") then
			removeEventHandler("onClientRender", root, drawPlantsLabels)
			addEventHandler("onClientRender", root, drawPlantsLabels)
		else
			removeEventHandler("onClientRender", root, drawPlantsLabels)
		end
	end
end)

local UI = {
	window = {},
	label = {},
	button = {}
}
local crops = {}
local busy = false

function UIKitReady()
	eui = exports.UIKit
	UI.window[1] = eui:uiCreateWindow(false, false, 420, 220, {
		en = "Selling Agricultural Crops",
		ar = "بيع المحاصيل الزراعية"
	})
	eui:uiSetVisible(UI.window[1], false)
	UI.label.Info = eui:uiCreateLabel(20, 60, 222, 20, "", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
	UI.button.sell = eui:uiCreateButton(5, 180, 150, 35, { en = "Sell", ar = "بيع" }, "primary", UI.window[1])
	UI.button.cancel = eui:uiCreateButton(160, 180, 150, 35, { en = "Cancel", ar = "إلغاء" }, _, UI.window[1])
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

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText)
	if not isElement(element) then
		return
	end
	if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "sell.crops" and optionText == "Talk" then
		if not getElementData(localPlayer, "character:id") then
			return
		end
		crops = {}
		local items = exports["item-system"]:getItems(localPlayer) or {}
		for _, value in ipairs(items) do
			for cropName, itemID in pairs(CROP_ITEM_IDS) do
				if value[1] == itemID and plant_info[cropName] then
					table.insert(crops, { name = cropName, count = 1 })
				end
			end
		end
		-- collapse per-crop counts
		local counts = {}
		local total = 0
		for _, crop in ipairs(crops) do
			counts[crop.name] = (counts[crop.name] or 0) + 1
			total = total + plant_info[crop.name].sell_price
		end
		local count = #crops
		eui:uiSetText(UI.label.Info, {
			en = "You have: " .. tostring(count) .. [[ fish
Total price: #00FF00$]] .. tostring(total) .. [[


#FFFFFFPress 'Sell' button if you want to sell all your crops.]],
			ar = "أنت لديك: " .. tostring(count) .. " محصول\nالسعر الإجمالي: #00FF00$" .. tostring(total) .. "\n\n#FFFFFFاضغط 'بيع' اذا كنت تريد بيع جميع المحاصيل لديك."
		})
		eui:uiSetVisible(UI.window[1], true)
		showCursor(true)
	end
end)

addEventHandler("onClientUIClick", root, function()
	if source == UI.button.sell then
		if busy then
			exports.notifications:output({
				en = "Wait please",
				ar = "انتظر من فضلك"
			}, 3000, "warning")
			return
		end
		if #crops > 0 then
			if not getElementData(localPlayer, "character:id") then
				return
			end
			busy = true
			triggerServerEvent("farmer:sell", localPlayer)
			eui:uiSetVisible(UI.window[1], false)
			showCursor(false)
			crops = {}
		else
			outputChatBox("You don't have any crops to sell.", 255, 0, 0)
		end
	elseif source == UI.button.cancel then
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	end
end)
addEvent("farmer:sell:callback", true)
addEventHandler("farmer:sell:callback", localPlayer, function()
	busy = false
end)
addEvent("onClientPlayerTakeJob", true)
addEventHandler("onClientPlayerTakeJob", localPlayer, function(job)
	if job ~= "Farmer" then
		return
	end
	outputChatBox("اتبع الخطوات التالية:", 255, 200, 0)
	outputChatBox("   1- اذهب إلى المزرعة، المنطقة الصفراء على الخريطة.", 255, 200, 0)
	outputChatBox("   2- قم بشراء البذور من البائع الموجود في المزرعة.", 255, 200, 0)
	outputChatBox("   3- اذهب إلى منطقة الزراعة واستخدم البذور من الحقيبة لبدأ الزراعة.", 255, 200, 0)
	outputChatBox("   4- انتظر حتى نمو الزرع بشكل كامل.", 255, 200, 0)
	outputChatBox("   5- احصد المزروع عن طريق الوقوف بجانب الزرعة والضغط على زر H.", 255, 200, 0)
	outputChatBox("   6- تستطيع بيع المحصول مباشرة أو عرضه في المحلات أو اكله والاستفادة منه.", 255, 200, 0)
end)
addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
	if job ~= "Farmer" then
		return
	end
	outputChatBox("اتبع الخطوات التالية:", 255, 200, 0)
	outputChatBox("   1- اذهب إلى المزرعة، المنطقة الصفراء على الخريطة.", 255, 200, 0)
	outputChatBox("   2- قم بشراء البذور من البائع الموجود في المزرعة.", 255, 200, 0)
	outputChatBox("   3- اذهب إلى منطقة الزراعة واستخدم البذور من الحقيبة لبدأ الزراعة.", 255, 200, 0)
	outputChatBox("   4- انتظر حتى نمو الزرع بشكل كامل.", 255, 200, 0)
	outputChatBox("   5- احصد المزروع عن طريق الوقوف بجانب الزرعة والضغط على زر H.", 255, 200, 0)
	outputChatBox("   6- تستطيع بيع المحصول مباشرة أو عرضه في المحلات أو اكله والاستفادة منه.", 255, 200, 0)
end)
