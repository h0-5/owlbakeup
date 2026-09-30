-- Decompiled by Owl Decompiler v1.0 ([jobs]/forklift-operator/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * the decompile merged SIX state identities into var0/var1/var2/var3:
--       JOB_NAME        - "Forklift Operator" (the start/help/quit compares)
--       FORKLIFT_MODELS - the vehicle model SET ([530] Forklift gate)
--       BOX_POSITIONS   - the spawn-point list (shuffled on start)
--       boxes           - map [box object] = its blip
--       lastNotifyTick  - the 2s throttle on the "Deliver the box" hint
--       started         - var3 (duty flag)
--   * createBox created the box object TWICE (lost local: one createObject
--     fed the map key, a second fed createBlipAttachedTo) - one box now.
--   * getNextPoint: table.insert({}, ...) lost the accumulator and
--     `({})[math.random(1, #{})]` indexed the empty lost table;
--     getDistanceBetweenPoints3D lost its second getElementPosition.
--     Restored (30m rule) + all-near safety pick.
--   * stopJob() renamed forkliftStopJob() (single-resource collision rule).
--   * BOX_POSITIONS are RECONSTRUCTED around the SF-dock job site (the lift
--     marker's hardcoded coordinates -1471.5, 277.97 place the site); the
--     original point list was lost with the dump.

local JOB_NAME = "Forklift Operator"
local FORKLIFT_MODELS = {
	[530] = true -- Forklift
}

-- reconstructed box spawn points (SF docks around the lift marker site)
local BOX_POSITIONS = {
	{ -1471.5, 277.97, 7.19 },
	{ -1455.8, 292.4, 7.19 },
	{ -1487.2, 305.1, 7.19 },
	{ -1440.3, 268.9, 7.19 },
	{ -1502.6, 281.7, 7.19 },
	{ -1462.9, 318.5, 7.19 },
	{ -1433.8, 300.2, 7.19 },
	{ -1510.4, 264.3, 7.19 }
}

local boxes = {}
local lastNotifyTick = 0
local started = false

function getNextPoint()
	local px, py, pz = getElementPosition(localPlayer)
	local far = {}
	for index, point in ipairs(BOX_POSITIONS) do
		if getDistanceBetweenPoints3D(px, py, pz, point[1], point[2], point[3]) > 30 then
			table.insert(far, index)
		end
	end
	if #far == 0 then
		return math.random(1, #BOX_POSITIONS)
	end
	return far[math.random(1, #far)]
end

function createBox()
	local box = createObject(2900, unpack(BOX_POSITIONS[getNextPoint()]))
	boxes[box] = createBlipAttachedTo(box, 0, 1, 255, 100, 0)
end

function attachLiftMarker(vehicle)
	if isElement(lift_marker) then
		return
	end
	lift_marker = createMarker(-1471.5, 277.97167, 7.1875, "cylinder", 1.9, 255, 255, 255, 0)
	current_lift_colshape = getElementColShape(lift_marker)
	addEventHandler("onClientColShapeHit", current_lift_colshape, hitLiftColshape)
	addEventHandler("onClientColShapeLeave", current_lift_colshape, leaveLiftColshape)
	attachElements(lift_marker, vehicle, 0, 1.3, -0.5)
	addEventHandler("onClientVehicleExit", vehicle, exitCurrentVehicle)
	addEventHandler("onClientElementDestroy", vehicle, destroyCurrentVehicle)
	current_vehicle = vehicle
end

function detachLiftMarker()
	if not isElement(lift_marker) then
		return
	end
	if isElement(current_lift_colshape) then
		removeEventHandler("onClientColShapeHit", current_lift_colshape, hitLiftColshape)
		removeEventHandler("onClientColShapeLeave", current_lift_colshape, leaveLiftColshape)
	end
	destroyElement(lift_marker)
	lift_marker = nil
	current_lift_colshape = nil
	removeEventHandler("onClientVehicleExit", current_vehicle, exitCurrentVehicle)
	removeEventHandler("onClientElementDestroy", current_vehicle, destroyCurrentVehicle)
	current_vehicle = nil
end

function exitCurrentVehicle(player, seat)
	if player ~= localPlayer then
		return
	end
	detachLiftMarker()
end

function enterVehicleEvent(player, seat)
	if player ~= localPlayer then
		return
	end
	if not BOX_POSITIONS then
		return
	end
	if FORKLIFT_MODELS[getElementModel(source)] then
		attachLiftMarker(source)
	end
end

function destroyCurrentVehicle()
	detachLiftMarker()
end

function createDestination()
	if isElement(current_destination_marker) then
		return
	end
	current_destination_marker = createMarker(unpack(BOX_POSITIONS[getNextPoint()]))
	current_destination_blip = createBlipAttachedTo(current_destination_marker, 0, 1, 255, 255, 0)
	addEventHandler("onClientColShapeHit", getElementColShape(current_destination_marker), hitDestination)
end

function destroyDestination()
	if not isElement(current_destination_marker) then
		return
	end
	removeEventHandler("onClientColShapeHit", getElementColShape(current_destination_marker), hitDestination)
	destroyElement(current_destination_blip)
	destroyElement(current_destination_marker)
	current_destination_blip = nil
	current_destination_marker = nil
end

function forkliftStopJob()
	detachLiftMarker()
	destroyDestination()
	for box, blip in pairs(boxes) do
		if isElement(box) then
			destroyElement(box)
		end
		if isElement(blip) then
			destroyElement(blip)
		end
	end
	boxes = {}
	current_box = false
	started = false
	removeEventHandler("onClientVehicleEnter", root, enterVehicleEvent)
end

function hitDestination(player, matchingDimension)
	if boxes[player] then
		if not isElementAttached(player) then
			return
		end
		destroyDestination()
		destroyElement(boxes[player])
		destroyElement(player)
		boxes[player] = nil
		current_box = false
		exports["job-system"]:givePlayerJobEXP(JOB_NAME, 1)
		createBox()
	end
end

function leaveLiftColshape(element, matchingDimension)
	if boxes[element] then
		if not isElementAttached(element) then
			return
		end
		detachElements(element)
		current_box = false
	end
end

function hitLiftColshape(element, matchingDimension)
	if boxes[element] then
		if isElementAttached(element) then
			return
		end
		if not isPedInVehicle(localPlayer) then
			return
		end
		if current_box then
			return
		end
		if tostring(getVehicleComponentPosition(getPedOccupiedVehicle(localPlayer), "misc_a")) == "-0.38061952590942" then
			attachElements(element, getPedOccupiedVehicle(localPlayer), 0, 0.55, -0.05)
			current_box = element
			if getTickCount() - lastNotifyTick > 2000 then
				exports.notifications:output({
					en = "Deliver the box to the specified location",
					ar = "قم بتوصيل الصندوق إلى الموقع المحدد"
				}, 4000, "info")
				lastNotifyTick = getTickCount()
			end
			createDestination()
		else
			exports.notifications:output({
				en = "The lift should be at the bottom",
				ar = "الرافعة يجب أن تكون في الأسفل"
			}, 3000, "warning")
		end
	end
end

addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
	if job ~= JOB_NAME then
		return
	end
	if isElement(lift_marker) then
		exports.notifications:output({
			en = "You already started the job",
			ar = "لقد بدأت العمل بالفعل"
		}, 3000, "warning")
		return
	end
	if isPedInVehicle(localPlayer) and FORKLIFT_MODELS[getElementModel(getPedOccupiedVehicle(localPlayer))] then
		BOX_POSITIONS = shuffle(BOX_POSITIONS)
		started = true
		attachLiftMarker(getPedOccupiedVehicle(localPlayer))
		createBox()
		addEventHandler("onClientVehicleEnter", root, enterVehicleEvent)
		exports.notifications:output({
			en = "Go to the box location to take it",
			ar = "اذهب إلى موقع الصندوق لأخذه"
		}, 10000, "info")
		return
	end
	exports.notifications:output({
		en = "You should enter the job vehicle first",
		ar = "يجب عليك دخول مركبة العمل أولاً"
	}, 4000, "warning")
end)

addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
	if job ~= JOB_NAME then
		return
	end
	outputChatBox("Follow These steps:", 255, 255, 0)
	outputChatBox("   1- اذهب للميناء", 255, 255, 0)
	outputChatBox("   2- اركب احدى المركبات المخصصة للوظيفة", 255, 255, 0)
	outputChatBox("   3- اكتب /startjob", 255, 255, 0)
	outputChatBox("   4- اذهب للموقع المحدد لك على الخريطة", 255, 255, 0)
	outputChatBox("   5- احمل الصندوق على رافعة المركبة", 255, 255, 0)
	outputChatBox("   6- قم بتوصيل الصندوق للموقع المطلوب", 255, 255, 0)
end)

addEvent("onClientPlayerTakeJob", true)
addEventHandler("onClientPlayerTakeJob", localPlayer, function(job)
	if job ~= JOB_NAME then
		return
	end
	outputChatBox("Type  /jobhelp  to view job instructions", 252, 132, 3)
	outputChatBox("لعرض تعليمات العمل  /jobhelp  اكتب", 252, 132, 3)
end)

addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
	if job == JOB_NAME then
		forkliftStopJob()
	end
end)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	forkliftStopJob()
end)

function shuffle(tbl)
	for i = #tbl, 2, -1 do
		tbl[i], tbl[math.random(1, i)] = tbl[math.random(1, i)], tbl[i]
	end
	return tbl
end
