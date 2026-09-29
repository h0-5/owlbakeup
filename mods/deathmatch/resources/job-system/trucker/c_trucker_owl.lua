-- Decompiled by Owl Decompiler v1.0 ([jobs]/trucker/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * the decompile merged SIX state identities into var0..var5. Restored:
--       JOB_NAME            - the job name string ("Trucker")
--       CONFIG              - { trailer_markers, locations } (see the shared
--                             config file; the original data was lost)
--       trailerMarkers      - [marker] = index (var2 in createTrailerMarkers)
--       trailerMarkersCreated - 0/1 flag (var0 in create/destroy)
--       parkedTrailers      - [marker] = trailer element synced by the server
--       attachedTrailer     - the trailer element being hauled
--       trailerAttached     - boolean
--       deliveryActive      - a trailer was taken, heading to the stop point
--       stopPointIndex      - chosen location index (var0 in showStopPoint)
--   * getNextPoint was BROKEN by the decompile: table.insert({}, ...) made a
--     new table per iteration (lost accumulator) and `({})[math.random(1, #{})]`
--     indexed the empty lost table; getDistanceBetweenPoints3D lost its second
--     getElementPosition. Restored: collect indices > 2000m away, pick one.
--     Safety repair: when no location is far enough, any location is picked
--     (the original would have indexed nil and crashed showStopPoint).
--   * the state table declared below keeps the same global names the
--     decompile used at runtime (StopPointMarker / StopPointBlip).

addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
	if job ~= JOB_NAME then
		return
	end
	if isElement(StopPointMarker) then
		outputChatBox("You already started the job.", 255, 0, 0)
		return
	end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
	createTrailerMarkers()
end)

function createTrailerMarkers()
	if trailerMarkersCreated ~= 0 then
		return
	end
	for index, point in ipairs(CONFIG.trailer_markers) do
		trailerMarkers[createMarker(unpack(point))] = index
	end
	trailerMarkersCreated = 1
end

function destroyTrailerMarkers()
	if trailerMarkersCreated ~= 1 then
		return
	end
	for marker in pairs(trailerMarkers) do
		if isElement(marker) then
			destroyElement(marker)
		end
	end
	trailerMarkers = nil
	trailerMarkersCreated = 0
end

function getNextPoint()
	local px, py, pz = getElementPosition(localPlayer)
	local far = {}
	for index, location in ipairs(CONFIG.locations) do
		local x, y, z = unpack(location.position)
		if getDistanceBetweenPoints3D(px, py, pz, x, y, z) > 2000 then
			table.insert(far, index)
		end
	end
	if #far == 0 then
		return math.random(1, #CONFIG.locations)
	end
	return far[math.random(1, #far)]
end

addEvent("trucker:trailer:attach:callback", true)
addEventHandler("trucker:trailer:attach:callback", localPlayer, function(trailer)
	deliveryActive = true
	onAttachTrailer(trailer)
	showStopPoint()
	fadeCamera(true, 1)
	exports.public:loading("trucker:trailer:attach", false)
end)

function onAttachTrailer(trailer)
	attachedTrailer = trailer
	addEventHandler("onClientTrailerAttach", trailer, onAttach)
	addEventHandler("onClientTrailerDetach", trailer, onDetach)
	addEventHandler("onClientElementDestroy", trailer, onDestroyTrailer)
	trailerAttached = true
end

function onDestroyTrailer()
	removeEventHandler("onClientTrailerAttach", source, onAttach)
	removeEventHandler("onClientTrailerDetach", source, onDetach)
	attachedTrailer = nil
	trailerAttached = false
end

function onAttach()
	trailerAttached = true
end

function onDetach()
	trailerAttached = false
end

addEvent("trucker:trailer:delivered:callback", true)
addEventHandler("trucker:trailer:delivered:callback", localPlayer, function(success)
	if success then
		destroyElement(StopPointMarker)
		StopPointMarker = nil
	end
	fadeCamera(true, 1)
	exports.public:loading("trucker:trailer:delivered", false)
end)

addEventHandler("onClientPlayerVehicleEnter", localPlayer, enterVehicleEvent)

function enterVehicleEvent(vehicle)
	if not TRUCKER_TRUCK_MODELS[getElementModel(vehicle)] then
		return
	end
	if getElementData(localPlayer, "job") ~= JOB_NAME then
		return
	end
	if not getVehicleTowedByVehicle(vehicle) then
		exports.notifications:output({
			en = "No trailer attached",
			ar = "لاتوجد مقطورة متصلة"
		}, 3500, "info")
		return
	end
end

function shuffle(table)
	for i = #table, 2, -1 do
		table[i], table[math.random(1, i)] = table[math.random(1, i)], table[i]
	end
	return table
end

function showStopPoint()
	if isElement(StopPointMarker) then
		return
	end
	stopPointIndex = getNextPoint()
	StopPointMarker = createColPolygon(unpack(CONFIG.locations[stopPointIndex].col_points))
	exports.public:addColshapeChecker(StopPointMarker, unpack(CONFIG.locations[stopPointIndex].position))
	StopPointBlip = createBlip(unpack(CONFIG.locations[stopPointIndex].position))
	setElementParent(StopPointBlip, StopPointMarker)
	exports.radar:findBestWay(unpack(CONFIG.locations[stopPointIndex].position))
	exports.notifications:output({
		en = "Go to the yellow marker shown on the map",
		ar = "اذهب للعلامة الصفراء على الخريطة"
	}, 10000, "info")
end

addEventHandler("onClientColshapeCheckerHit", resourceRoot, function()
	if source == StopPointMarker then
		if not trailerAttached or not attachedTrailer then
			exports.notifications:output({
				en = "No trailer attached",
				ar = "لاتوجد مقطورة متصلة"
			}, 3500, "info")
			return
		end
		if isElementWithinColShape(attachedTrailer, source) then
			setPedControlState(localPlayer, "handbrake", true)
			fadeCamera(false, 2, 0, 0, 0)
			exports.public:loading("trucker:trailer:delivered", true)
			setTimer(triggerServerEvent, 3000, 1, "trucker:trailer:delivered", localPlayer, getPedOccupiedVehicle(localPlayer), attachedTrailer)
		end
	end
end)

function attachTrailer(key, keyState, marker)
	if isElementWithinMarker(localPlayer, marker) and getPedOccupiedVehicle(localPlayer) then
		trailerAttached = false
		fadeCamera(false, 1, 0, 0, 0)
		exports.public:loading("trucker:trailer:attach", true)
		setTimer(triggerServerEvent, 1000, 1, "trucker:trailer:attach", localPlayer, getPedOccupiedVehicle(localPlayer))
	end
	unbindKey(key, keyState, attachTrailer)
	exports.notifications:hideKeyDescription("trucker:attach_trailer")
end

addEventHandler("onClientMarkerHit", resourceRoot, function(player, matchingDimension)
	if player ~= localPlayer then
		return
	end
	if getElementData(localPlayer, "job") ~= JOB_NAME then
		return
	end
	if trailerMarkers[source] then
		if not parkedTrailers[source] then
			return
		end
		if deliveryActive then
			return
		end
		if trailerAttached then
			return
		end
		if not isPedInVehicle(player) then
			exports.notifications:output({
				en = "You have to bring a truck for the job",
				ar = "عليك إحضار شاحنة خاصة بالوظيفة"
			}, 3500, "warning")
			return
		end
		if getVehicleTowedByVehicle(getPedOccupiedVehicle(player)) then
			return
		end
		if getVehicleController(getPedOccupiedVehicle(player)) ~= player then
			return
		end
		if not TRUCKER_TRUCK_MODELS[getElementModel(getPedOccupiedVehicle(player))] then
			exports.notifications:output({
				en = "You need a special truck for the job",
				ar = "تحتاج إلى شاحنة خاصة بالوظيفة"
			}, 3500, "warning")
			return
		end
		bindKey("lshift", "down", attachTrailer, source)
		exports.notifications:showKeyDescription("trucker:attach_trailer", "Left Shift", "Take Trailer")
	end
end)

addEventHandler("onClientMarkerLeave", resourceRoot, function(player, matchingDimension)
	if player ~= localPlayer then
		return
	end
	if getElementType(player) ~= "player" then
		return
	end
	if not isPedInVehicle(player) then
		return
	end
	if trailerMarkers[source] then
		unbindKey("lshift", "down", attachTrailer, source)
		exports.notifications:hideKeyDescription("trucker:attach_trailer")
	end
end)

addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
	if job == JOB_NAME then
		truckerStopJob()
	end
end)

-- NOTE: decompile global stopJob() renamed truckerStopJob() - every Owl job
-- client lives inside the ONE job-system resource (same Fix #62 pattern)
function truckerStopJob()
	if isElement(StopPointBlip) then
		destroyElement(StopPointBlip)
		destroyElement(StopPointMarker)
		StopPointBlip = nil
		StopPointMarker = nil
	end
	deliveryActive = false
	trailerAttached = false
end

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	truckerStopJob()
end)

-- restored state (globals the decompile's vars resolved to at runtime)
trailerMarkers = {}
parkedTrailers = {}
trailerMarkersCreated = 0
attachedTrailer = nil
trailerAttached = false
deliveryActive = false
stopPointIndex = nil
