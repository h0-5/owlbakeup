-- NOTE: every Owl job client lives inside the ONE job-system resource, so
-- the decompile global stopJob() is renamed dustmanStopJob() (same Fix #62
-- pattern as UIKitReady/UIKitReadyJob) - a generic global would be a
-- cross-job collision. Logic is untouched.
-- Decompiled by Owl Decompiler v1.0 ([jobs]/dustman-job/c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0 = TWO merged tables: the garbage-truck model SET (var0[getElementModel]
--     gate) and the trash spawn points map (var0["Las Venturas"]). The model
--     set is reconstructed as the Trashmaster (408) - the only garbage truck
--     in SA - and the point list is reconstructed LV coordinates (server data
--     was lost with the old dump; documented in s_dustman_owl.lua).
--   * the decompile re-evaluated var0["Las Venturas"][math.random(...)] in
--     EVERY statement - one random pick drifted apart from the next, so the
--     trash object, the ground-check, the arrow, the blip and the radar route
--     each pointed at DIFFERENT places. Restored as ONE `point` per placement.
--   * the ground repair z used
--     `math.abs(getElementBoundingBox(o) - getElementBoundingBox(o))` = 0
--     (same call twice - lost min/max pair). Repaired with the canonical
--     getGroundPosition + getDistanceFromGroundToCenterOfMass offset.
--   * the second branch's createMarker(unpack(point)) lost its marker args -
--     restored to the same green arrow the first branch used.
--   * WaitingGroundTimer ground-checked a DIFFERENT random point than the
--     one TrashObject was created at - restored to the same point.

local TRASH_MODELS = {
	1265,
	1440,
	1357,
	1441,
	1338,
	1230,
	1450,
	1438
}

-- garbage-truck models the job starts in (var0[getElementModel] gate)
local TRUCK_MODELS = {
	[408] = true -- Trashmaster
}

-- reconstructed spawn points around Las Venturas (the original table was
-- server/client data lost with the dump; z values sit at street level and
-- the ground-repair loop below still corrects any bad spot)
local TRASH_POINTS = {
	["Las Venturas"] = {
		{ 2294.5, 2451.5, 10.8 },
		{ 2442.9, 2373.8, 12.2 },
		{ 2068.6, 2243.4, 10.7 },
		{ 2470.9, 2036.2, 10.8 },
		{ 2115.2, 1958.5, 10.8 },
		{ 2260.4, 1670.5, 10.8 },
		{ 2459.9, 1329.9, 10.8 },
		{ 2325.9, 1287.9, 10.4 },
		{ 2087.7, 1304.4, 10.5 },
		{ 2497.4, 1019.5, 10.8 },
		{ 2283.5, 923.9, 10.8 },
		{ 2102.3, 1016.5, 10.8 },
		{ 2653.8, 1119.7, 10.8 },
		{ 2695.6, 1703.4, 10.8 }
	}
}

local TrashModels = TRASH_MODELS
local JobVehicle = false
local isShowMarker = false

addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
	if job ~= "Dustman" then
		return
	end
	if isElement(TrashObject) then
		outputChatBox("You already started the job.", 255, 0, 0)
		return
	end
	if isPedInVehicle(localPlayer) then
		VehicleAttachedMarker = createColCircle(0, 0, 1.5)
		attachElements(VehicleAttachedMarker, getPedOccupiedVehicle(localPlayer), 0, -5, -1.5)
		if TRUCK_MODELS[getElementModel(getPedOccupiedVehicle(localPlayer))] then
			createTrashOnPlace()
		end
	end
end)

function createTrashOnPlace()
	if isElement(TrashArrow) then
		destroyElement(TrashArrow)
	end
	if isElement(TrashObject) then
		destroyElement(TrashObject)
	end
	if isElement(TrashBlip) then
		destroyElement(TrashBlip)
	end
	TrashArrow = nil
	TrashObject = nil
	TrashBlip = nil
	if isTimer(WaitingGroundTimer) then
		killTimer(WaitingGroundTimer)
	end
	local point = TRASH_POINTS["Las Venturas"][math.random(#TRASH_POINTS["Las Venturas"])]
	TrashObject = createObject(TrashModels[math.random(#TrashModels)], unpack(point))
	if getGroundPosition(point[1], point[2], point[3]) == 0 then
		WaitingGroundTimer = setTimer(function(x, y, z)
			if getGroundPosition(x, y, z) ~= 0 then
				setElementPosition(TrashObject, x, y, getGroundPosition(x, y, z) + getElementDistanceFromGroundToCenterOfMass(TrashObject))
				TrashArrow = createMarker(x, y, getGroundPosition(x, y, z) + 2.5, "arrow", 0.6, 0, 200, 0, 150)
				killTimer(WaitingGroundTimer)
			end
		end, 1000, 0, point[1], point[2], point[3])
	else
		setElementPosition(TrashObject, unpack(point))
		TrashArrow = createMarker(point[1], point[2], point[3] + 2.5, "arrow", 0.6, 0, 200, 0, 150)
	end
	setElementFrozen(TrashObject, true)
	TrashBlip = createBlip(point[1], point[2], point[3])
	exports.radar:findBestWay(point[1], point[2], point[3])
	isShowMarker = true
end

addEventHandler("onClientObjectDamage", resourceRoot, function()
	if source == TrashObject then
		cancelEvent()
	end
end)

addEventHandler("onClientColShapeHit", resourceRoot, function(element)
	if source == VehicleAttachedMarker and element == TrashObject and getVehicleController(getElementAttachedTo(source)) == localPlayer then
		if isElement(TrashArrow) then
			destroyElement(TrashArrow)
		end
		if isElement(TrashObject) then
			destroyElement(TrashObject)
		end
		if isElement(TrashBlip) then
			destroyElement(TrashBlip)
		end
		TrashArrow = nil
		TrashObject = nil
		TrashBlip = nil
		if isTimer(WaitingGroundTimer) then
			killTimer(WaitingGroundTimer)
		end
		exports["job-system"]:givePlayerJobEXP("Dustman", 1)
		createTrashOnPlace()
	end
end)

addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
	if job == "Dustman" then
		dustmanStopJob()
	end
end)

function dustmanStopJob()
	if isElement(TrashArrow) then
		destroyElement(TrashArrow)
	end
	if isElement(TrashObject) then
		destroyElement(TrashObject)
	end
	if isElement(TrashBlip) then
		destroyElement(TrashBlip)
	end
	if isElement(VehicleAttachedMarker) then
		destroyElement(VehicleAttachedMarker)
	end
	TrashArrow = nil
	TrashObject = nil
	TrashBlip = nil
	VehicleAttachedMarker = nil
	if isTimer(WaitingGroundTimer) then
		killTimer(WaitingGroundTimer)
	end
	isShowMarker = false
end

addEventHandler("onClientPlayerSpawn", localPlayer, function()
	dustmanStopJob()
end)
