-- Decompiled by Owl Decompiler v1.0 ([jobs]/drug-dealer/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1/var2 merged THREE+ identities. Restored as:
--       insidePlantMarker  - the plant marker the local player is inside
--                            (plant-over gate + harvest key target)
--       plantMarkers       - [marker] = plant object element
--       harvestBusy        - a harvest request is in flight (var0 = true/false)
--       harvestTargetMarker- the marker whose plant is being harvested (var2)
--   * drug_dealer:createPlantMarker / syncPlantsMarkers called createMarker
--     THREE times (once inside the isElementWithinMarker test, once in the
--     assignment, once as the plantMarkers key) - three separate markers,
--     two orphaned. Restored to ONE marker + test + map insert.
--   * syncPlantsMarkers entry = {plant element, {x, y, z, ...}} (unpack into
--     createMarker) - restored the unpack lost to forvar renaming.
--   * the plant-overlap loop called getDistanceBetweenPoints2D with ONE
--     position (the player) - the second getElementPosition (the plant
--     object) was lost. Restored with explicit locals.
--   * exports["inventory-system"]:hideCrafting() - the Owl craft UI resource
--     does not exist in this repo (server lost) - pcall-guarded DEFER, the
--     elementData contract (marker "drug:crafting") is kept verbatim.
--   * startFarming's createObject+destroyElement preview pair is kept
--     verbatim (harmless client-side flicker in the original too).

addEventHandler("onClientMarkerLeave", resourceRoot, function(player, matchingDimension)
	if player ~= localPlayer then
		return
	end
	if getElementData(source, "drug:crafting") then
		pcall(function()
			exports["inventory-system"]:hideCrafting()
		end)
	end
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText, data)
	if not isElement(element) then
		return
	end
	if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "job.drug_dealer" and optionText == "Talk" then
		exports["job-system"]:showTakeJob("Drug Dealer", {
			en = "Drug Dealer Job",
			ar = "وظيفة تاجر ممنوعات"
		}, {
			en = [[
You can not take this job if you are on duty

You will be able to grow cannabis and pack it in bags to be ready for use or sale]],
			ar = "\nلاتستطيع أخذ الوظيفة إذا كنت داخل الخدمة\n\nسوف تتمكن من زراعة الحشيش وتغليفه\nليكون جاهز للاستخدام أو البيع"
		})
	end
end)

addEvent("onClientRequestTakeJob", true)
addEventHandler("onClientRequestTakeJob", localPlayer, function(job)
	if job == "Drug Dealer" then
		if getElementData(localPlayer, "duty:data") and getElementData(localPlayer, "duty:data").Status then
			outputChatBox("(( You must be off duty to take this job. ))", 255, 46, 46)
			return
		end
		triggerServerEvent("drug_dealer:takeJob", localPlayer)
	end
end)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	for marker in pairs(plantMarkers) do
		if isElement(marker) then
			destroyElement(marker)
		end
	end
	plantMarkers = {}
end)

addEvent("drug_dealer:startFarming", true)
addEventHandler("drug_dealer:startFarming", root, function(seedType)
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
		if getElementData(localPlayer, "job") == "Drug Dealer" then
			if insidePlantMarker and isElement(insidePlantMarker) and isElementWithinMarker(localPlayer, insidePlantMarker) then
				outputChatBox("You cannot plant over another plant.", 255, 60, 0)
				return
			end
			local px, py, pz = getElementPosition(localPlayer)
			for _, obj in ipairs(getElementsByType("object", resourceRoot)) do
				if getElementInterior(obj) == getElementInterior(localPlayer) and getElementDimension(obj) == getElementDimension(localPlayer) then
					local ox, oy, oz = getElementPosition(obj)
					if getDistanceBetweenPoints2D(px, py, ox, oy) <= 1 and getElementID(obj) and string.find(getElementID(obj), "plant:", 1, true) then
						outputChatBox("You cannot plant over another plant.", 255, 60, 0)
						return
					end
				end
			end
			triggerServerEvent("drug_dealer:plant", localPlayer, plant_types[seedType].name, plant_types[seedType].model, getElementPosition(localPlayer))
			destroyElement(createObject(plant_types[seedType].model, getElementPosition(localPlayer)))
		else
			outputChatBox("You must be a drug dealer to be able to plant this seeds.", 255, 68, 0)
		end
	end
end)

addEvent("drug_dealer:createPlantMarker", true)
addEventHandler("drug_dealer:createPlantMarker", root, function(x, y, z, plantObject)
	local marker = createMarker(x, y, z - 0.7, "cylinder", 1, 7, 181, 54, 100)
	if isElementWithinMarker(localPlayer, marker) then
		insidePlantMarker = marker
	end
	plantMarkers[marker] = plantObject
end)

addEvent("drug_dealer:syncPlantsMarkers", true)
addEventHandler("drug_dealer:syncPlantsMarkers", root, function(plants)
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
			exports.notifications:showKeyDescription("drug:harvest", "H", "Harvest")
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
			exports.notifications:hideKeyDescription("drug:harvest")
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
			triggerServerEvent("drug_dealer:harvest", localPlayer, split(getElementID(plantMarkers[marker]), ":")[2])
			unbindKey("H", "down", harvestKey, source)
			exports.notifications:hideKeyDescription("drug:harvest")
		end
	end
end

addEvent("drug_dealer:harvest:callback", true)
addEventHandler("drug_dealer:harvest:callback", localPlayer, function(success)
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

-- restored state tables (declared last so the handlers above reference the
-- same globals the decompile's vars resolved to at runtime)
plantMarkers = {}
insidePlantMarker = false
harvestBusy = false
harvestMarker = false
harvestTargetMarker = false
