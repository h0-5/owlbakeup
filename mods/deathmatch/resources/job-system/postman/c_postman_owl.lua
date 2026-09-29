-- Decompiled by Owl Decompiler v1.0 ([jobs]/postman/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1/var2 merged SIX identities - restored:
--       CONFIG (locations: 3 mail stops with box positions, VERBATIM),
--       truckMarkers ([marker] = stop index), boxMap ([box] = true),
--       carrying (the box on the postman's back), TRUCK_MODELS (the Burrito
--       482 gate - reconstructed), SCALE (screen scale for the box HUD).
--   * the 2m pick-up distance compared ONE position (the player) - the box
--     position was lost; restored with explicit locals.
--   * "Change Colors"-style row leaks don't apply here; the gridlist fills
--     are simple, kept verbatim.
--   * drawJobInfo: generated box.png placeholder (asset not in the dump);
--     the lost color arg restored to white; _ = SCALE unpack repairs.
--   * stopJob() renamed postmanStopJob() (single-resource collision rule).
-- Server contract: postman:attachBox(bool, model) / putBoxInsideVehicle /
-- openVehicleTrunk + the "temp:boxes" elementData (server-authoritative).

local SCALE -- screen scale

local CONFIG = {
	locations = {
		{
			marker_pos = { 
        1771.87,
        -2049.135,
        11.5
       },
			boxes_pos = {
				
			}
		},
		{
			marker_pos = { 
        1771.87,
        -2031.82,
        11.5
       },
			boxes_pos = {
				
			}
		},
		{
			marker_pos = { 
        1751.726,
        -2061.259,
        11.5
       },
			boxes_pos = {
				
			}
		}
	}
}

local JOB_NAME = "Postman"
local TRUCK_MODELS = {
	[482] = true -- Burrito (reconstructed truck gate)
}

local truckMarkers = {}
local boxMap = {}
local carrying = false

local sx, sy = guiGetScreenSize()
SCALE = sy / 1080

for index, stop in ipairs(CONFIG.locations) do
	truckMarkers[createMarker(unpack(stop.marker_pos))] = index
end

function createBoxes(stopIndex)
	for box in pairs(boxMap) do
		if isElement(box) then
			return
		end
	end
	for _, pos in ipairs(CONFIG.locations[stopIndex].boxes_pos) do
		boxMap[createObject(unpack(pos))] = true
	end
end
addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
	if job ~= "Postman" then
		return
	end
end)
addEvent("onClientPlayerTakeJob", true)
addEventHandler("onClientPlayerTakeJob", localPlayer, function(job)
	if job ~= "Postman" then
		return
	end
	outputChatBox("Type  /jobhelp  to view job instructions", 252, 132, 3)
	outputChatBox("لعرض تعليمات العمل  /jobhelp  اكتب", 252, 132, 3)
end)
function enterVehicleEvent(vehicle)
	if not TRUCK_MODELS[getElementModel(vehicle)] then
		return
	end
	if getElementData(localPlayer, "job") ~= JOB_NAME then
		return
	end
	if getElementData(vehicle, "temp:boxes") then
		if getElementData(vehicle, "temp:boxes") > 0 then
			showStopPoint()
		else
			exports.notifications:output({
				en = "There are no boxes in the truck",
				ar = "لاتوجد صناديق في الشاحنة"
			}, 3500, "info")
		end
		addEventHandler("onClientRender", root, drawJobInfo)
	else
		exports.notifications:output({
			en = "There are no boxes in the truck",
			ar = "لاتوجد صناديق في الشاحنة"
		}, 3500, "info")
	end
end
addEventHandler("onClientPlayerVehicleEnter", localPlayer, enterVehicleEvent)
function exitVehicleEvent(vehicle)
	if not TRUCK_MODELS[getElementModel(vehicle)] then
		return
	end
	removeEventHandler("onClientRender", root, drawJobInfo)
end
addEventHandler("onClientPlayerVehicleExit", localPlayer, exitVehicleEvent)
function drawJobInfo()
	if getPedOccupiedVehicle(localPlayer) then
		dxDrawImage(25 * SCALE, 650 * SCALE, 32 * SCALE, 32 * SCALE, "box.png", 0, 0, 0)
		dxDrawText(tostring(getElementData(getPedOccupiedVehicle(localPlayer), "temp:boxes") or 0), 70 * SCALE, 650 * SCALE, 150 * SCALE, 682 * SCALE, tocolor(255, 255, 255, 255), 2 * SCALE, "default-bold", "left", "center")
	else
		removeEventHandler("onClientRender", root, drawJobInfo)
	end
end
PointID = 1
StopPoints = {
	{ { 2085.237, -1926.778, 13.2781 }, { 2090.37, -1927.53, 13.5401 } },
	{ { 1159.517, -1855.902, 13.3974 }, { 1159.447, -1861.544, 13.7729 } },
	{ { 910.832, -1446.12, 13.5469 }, { 903.0292, -1447.176, 13.5585 } },
	{ { 1030.139, -1153.116, 23.6562 }, { 1034.745, -1157.359, 23.8281 } },
	{ { 1158.948, -1101.795, 24.9123 }, { 1145.332, -1100.969, 25.8175 } },
	{ { 1721.356, -1260.562, 13.5468 }, { 1730.084, -1263.328, 13.5468 } },
	{ { 2078.216, -1632.082, 13.3828 }, { 2069.613, -1630.564, 13.8761 } },
	{ { 2479.95, -1740.201, 13.5468 }, { 2476.569, -1748.949, 13.5468 } },
	{ { 2763.381, -1940.473, 13.5393 }, { 2754.291, -1938.664, 13.5453 } },
	{ { 2871.383, -1438.062, 10.789 }, { 2864.254, -1436.875, 10.9752 } },
	{ { 2828.332, -1182.926, 24.9442 }, { 2809.889, -1178.439, 25.3308 } },
	{ { 2447.025, -1303.126, 23.8248 }, { 2436.777, -1304.776, 24.6745 } },
	{ { 2135.304, -1085.638, 24.1814 }, { 2138.292, -1082.719, 24.3837 } },
	{ { 1669.454, -1291.884, 14.3263 }, { 1667.953, -1278.643, 14.7775 } },
	{ { 1428.946, -1551.972, 13.3647 }, { 1421.571, -1552.025, 13.5421 } },
	{ { 1958.132, -1989.625, 13.3905 }, { 1951.274, -1987.719, 13.5468 } },
	{ { 1709.717, -2109.31, 13.3828 }, { 1710.383, -2104.042, 13.5468 } }
}
function shuffle(tbl)
	for i = #tbl, 2, -1 do
		tbl[i], tbl[math.random(1, i)] = tbl[math.random(1, i)], tbl[i]
	end
	return tbl
end
function showStopPoint()
	if isElement(StopPointMarker) then
		return
	end
	StopPointMarker = createMarker(unpack(StopPoints[PointID][1]))
	StopPointBlip = createBlip(unpack(StopPoints[PointID][1]))
	setElementParent(StopPointBlip, StopPointMarker)
	DeliverBoxMarker = createMarker(unpack(StopPoints[PointID][2]))
	setElementAlpha(DeliverBoxMarker, 0)
	exports.radar:findBestWay(unpack(StopPoints[PointID][1]))
	exports.notifications:output({
		en = "Go to the yellow marker shown on the map",
		ar = "اذهب للعلامة الصفراء على الخريطة"
	}, 10000, "info")
end
addEventHandler("onClientClick", root, function(button, state, absX, absY, wx, wy, wz, clickedElement)
	if clickedElement and state == "down" then
		if boxMap[clickedElement] then
			if carrying then
				return
			end
			if getElementData(localPlayer, "job") ~= JOB_NAME then
				return
			end
			-- repair: the decompile compared ONE position (the player) -
			-- the box position was lost to the unpack collapse
			local px, py, pz = getElementPosition(localPlayer)
			local bx, by, bz = getElementPosition(clickedElement)
			if getDistanceBetweenPoints3D(px, py, pz, bx, by, bz) > 2 then
				return
			end
			boxMap[clickedElement] = nil
			destroyElement(clickedElement)
			carrying = true
			triggerServerEvent("postman:attachBox", localPlayer, true, getElementModel(clickedElement))
		elseif getElementType(clickedElement) == "vehicle" then
			if not carrying then
				return
			end
			if getElementData(localPlayer, "job") ~= JOB_NAME then
				return
			end
			if not TRUCK_MODELS[getElementModel(clickedElement)] then
				return
			end
			local px, py, pz = getElementPosition(localPlayer)
			local vx, vy, vz = getElementPosition(clickedElement)
			if getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz) > 5 then
				return
			end
			carrying = false
			triggerServerEvent("postman:putBoxInsideVehicle", localPlayer, clickedElement)
		end
	end
end, true, "high-1")
addEventHandler("onClientMarkerHit", resourceRoot, function(player)
	if player ~= localPlayer then
		return
	end
	if getElementData(localPlayer, "job") ~= JOB_NAME then
		return
	end
	if truckMarkers[source] then
		if getElementAlpha(source) == 0 then
			return
		end
		if not isPedInVehicle(player) then
			exports.notifications:output({
				en = "You have to bring a truck for the job",
				ar = "عليك إحضار شاحنة خاصة بالوظيفة"
			}, 3500, "warning")
			return
		end
		if getVehicleController(getPedOccupiedVehicle(player)) ~= player then
			return
		end
		if TRUCK_MODELS[getElementModel(getPedOccupiedVehicle(player))] then
			if getElementData(getPedOccupiedVehicle(player), "temp:boxes") and getElementData(getPedOccupiedVehicle(player), "temp:boxes") >= 10 then
				showStopPoint()
				exports.notifications:output({
					en = "The truck is loaded with boxes, take them to the required place",
					ar = "الشاحنة محملة بالصناديق، قم بتوصيلهم للمكان المطلوب"
				}, 3500, "warning")
				return
			end
			setPedControlState(localPlayer, "handbrake", true)
			setElementFrozen(getPedOccupiedVehicle(player), true)
			setTimer(setElementFrozen, 500, 1, getPedOccupiedVehicle(player), false)
			setPedExitVehicle(localPlayer)
			setElementAlpha(source, 0)
			triggerServerEvent("postman:openVehicleTrunk", localPlayer, getPedOccupiedVehicle(player))
			createBoxes(truckMarkers[source])
			exports.notifications:output({
				en = "Put the boxes in the truck",
				ar = "قم بوضع الصناديق في الشاحنة"
			}, 8000, "info")
		else
			exports.notifications:output({
				en = "You need a special truck for the job",
				ar = "تحتاج إلى شاحنة خاصة بالوظيفة"
			}, 3500, "warning")
		end
	elseif source == StopPointMarker then
		if not isPedInVehicle(player) then
			return
		end
		if getVehicleController(getPedOccupiedVehicle(player)) ~= player then
			return
		end
		if TRUCK_MODELS[getElementModel(getPedOccupiedVehicle(player))] then
			if getElementAlpha(source) == 0 then
				return
			end
			setPedControlState(localPlayer, "handbrake", true)
			setElementFrozen(getPedOccupiedVehicle(player), true)
			setTimer(setElementFrozen, 500, 1, getPedOccupiedVehicle(player), false)
			setPedExitVehicle(localPlayer)
			setElementAlpha(source, 0)
			setElementAlpha(DeliverBoxMarker, 100)
			exports.notifications:output({
				en = "Take a box from the truck",
				ar = "خذ صندوق من الشاحنة"
			}, 3500, "info")
		end
	elseif source == DeliverBoxMarker then
		if getElementAlpha(source) == 0 then
			return
		end
		if not carrying then
			exports.notifications:output({
				en = "Take a box from the truck",
				ar = "خذ صندوق من الشاحنة"
			}, 3500, "info")
			return
		end
		carrying = false
		triggerServerEvent("postman:attachBox", localPlayer, false)
		exports["job-system"]:givePlayerJobEXP("Postman", 1)
		destroyElement(StopPointMarker)
		StopPointMarker = nil
		destroyElement(source)
		PointID = PointID + 1
		if PointID > #StopPoints then
			StopPoints = shuffle(StopPoints)
			PointID = 1
		end
		showStopPoint()
	end
end)
addEventHandler("onClientMarkerLeave", resourceRoot, function(player)
	if player ~= localPlayer then
		return
	end
	if getElementType(player) ~= "player" then
		return
	end
	if not isPedInVehicle(player) then
		return
	end
	if truckMarkers[source] then
		if getElementAlpha(source) ~= 0 then
			return
		end
		setElementAlpha(source, 150)
	end
end)
addEvent("onClientElementMenuShow", true)
addEventHandler("onClientElementMenuShow", localPlayer, function(element, distance, elementType)
	if distance <= 5 and elementType == "vehicle" and isElement(element) then
		if carrying then
			return
		end
		if isPedInVehicle(localPlayer) then
			return
		end
		if getElementData(element, "temp:boxes") and getElementData(element, "temp:boxes") > 0 then
			exports.interaction:addInteractOption(element, { text = "Take box" })
		end
	end
end)
addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", localPlayer, function(element, optionText)
	if optionText == "Take box" and isElement(element) and getElementType(element) == "vehicle" then
		if isPedInVehicle(localPlayer) then
			return
		end
		if getElementData(element, "temp:boxes") and getElementData(element, "temp:boxes") > 0 then
			setElementData(element, "temp:boxes", getElementData(element, "temp:boxes") - 1)
			carrying = true
			triggerServerEvent("postman:attachBox", localPlayer, true, 2912)
		end
	end
end)
addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
	if job ~= "Postman" then
		return
	end
	if isElement(StopPointMarker) then
		outputChatBox("You already started the job.", 255, 0, 0)
		return
	end
end)
addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
	if job == "Postman" then
		postmanStopJob()
	end
end)
function postmanStopJob()
	if isElement(StopPointBlip) then
		destroyElement(StopPointBlip)
		destroyElement(StopPointMarker)
		if isElement(DeliverBoxMarker) then
			destroyElement(DeliverBoxMarker)
		end
		StopPointBlip = nil
		StopPointMarker = nil
		DeliverBoxMarker = nil
	end
	if carrying then
		carrying = false
		triggerServerEvent("postman:attachBox", localPlayer, false)
	end
	for box in pairs(boxMap) do
		if isElement(box) then
			destroyElement(box)
		end
	end
	boxMap = {}
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	postmanStopJob()
end)
