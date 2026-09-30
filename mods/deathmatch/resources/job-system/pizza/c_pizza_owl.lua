-- Decompiled by Owl Decompiler v1.0 ([jobs]/pizza-delivery/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0 = the pizza vehicle model SET (the [448] Pizzaboy gate).
--   * the decompile global stopJob() is renamed pizzaStopJob() - every Owl
--     job client lives inside the ONE job-system resource (Fix #62 pattern).
--   * the StopPoints table (21 real delivery points: {vehicle stop, door})
--     is copied VERBATIM from the decompile.
-- Server contract: pizza_delivery:attachPizzaBox(bool) - the pizza box on
-- the deliverer's back (reconstructed transform, model 2880) - plus the
-- duty-start re-fire of onClientPlayerStartJob that makes /startjob begin
-- the route once the deliverer sits on a Pizzaboy.

local PIZZA_VEHICLES = {
	[448] = true -- Pizzaboy
}

addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
	if job ~= "Pizza Deliverer" then
		return
	end
	if isElement(StopPointMarker) then
		outputChatBox("You already started the job.", 255, 0, 0)
		return
	end
	if isPedInVehicle(localPlayer) and PIZZA_VEHICLES[getElementModel(getPedOccupiedVehicle(localPlayer))] then
		StopPoints = shuffle(StopPoints)
		showStopPoint()
		outputChatBox("Go to the yellow marker shown on the map.", 255, 255, 0)
		return
	end
	outputChatBox("Enter Pizzaboy vehicle first.", 252, 132, 3)
	outputChatBox("You can find the vehicles next to the pizza stack shop.", 252, 132, 3)
end)
addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
	if job ~= "Pizza Deliverer" then
		return
	end
	outputChatBox("Follow These steps:", 255, 255, 0)
	outputChatBox("   1- Take a pizzaboy vehicle from Pizza Stack.", 255, 255, 0)
	outputChatBox("   2- Open your GPS.", 255, 255, 0)
	outputChatBox("   3- Type /startjob.", 255, 255, 0)
	outputChatBox("   4- Go to the yellow marker shown on the map.", 255, 255, 0)
	outputChatBox("   5- Get out of the vehicle and deliver the pizza to the door of the house.", 255, 255, 0)
end)
addEvent("onClientPlayerTakeJob", true)
addEventHandler("onClientPlayerTakeJob", localPlayer, function(job)
	if job ~= "Pizza Deliverer" then
		return
	end
	outputChatBox("Type  /jobhelp  to view job instructions", 252, 132, 3)
	outputChatBox("\217\132\216\185\216\177\216\182 \216\170\216\185\217\132\217\138\217\133\216\167\216\170 \216\167\217\132\216\185\217\133\217\132  /jobhelp  \216\167\217\131\216\170\216\168", 252, 132, 3)
end)

PointID = 1
StopPoints = {
	{ { 2095.19, -1293.239, 23.9733 }, { 2091.421, -1279.869, 26.0139 } },
	{ { 2148.242, -1228.255, 23.9765 }, { 2153.747, -1241.078, 25.128 } },
	{ { 2078.513, -1186.544, 23.8188 }, { 2090.962, -1185.489, 27.057 } },
	{ { 2000.499, -1128.455, 25.4927 }, { 2000.267, -1115.945, 27.0621 } },
	{ { 1911.648, -1127.795, 24.772 }, { 1905.761, -1113.968, 26.664 } },
	{ { 2020.951, -1060.04, 24.6649 }, { 2023.793, -1054.031, 25.5961 } },
	{ { 2244.688, -1051.66, 53.0229 }, { 2249.552, -1059.363, 55.9687 } },
	{ { 2455.379, -1094.02, 42.8995 }, { 2456.937, -1100.256, 43.7022 } },
	{ { 2377.92, -1292.647, 24 }, { 2388.801, -1297.816, 25.3322 } },
	{ { 2205.195, -1469.315, 23.9843 }, { 2192.6, -1470.451, 25.7625 } },
	{ { 2237.126, -1645.238, 15.486 }, { 2243.88, -1639.244, 15.9074 } },
	{ { 2364.673, -1666.873, 13.5468 }, { 2368.343, -1674.495, 13.9062 } },
	{ { 2494.707, -1683.579, 13.3385 }, { 2495.285, -1689.977, 14.7656 } },
	{ { 2507.153, -2015.581, 13.5468 }, { 2507.84, -2019.51, 13.5468 } },
	{ { 1994.765, -1710.228, 13.5468 }, { 1981.743, -1719.019, 17.0304 } },
	{ { 2862.873, -1365.146, 11.0206 }, { 2854.317, -1366.166, 14.164 } },
	{ { 2816.182, -1935.598, 11.1093 }, { 2805.341, -1936.5, 13.5468 } },
	{ { 2160.217, -1790.765, 13.5202 }, { 2153.152, -1789.171, 13.5123 } },
	{ { 1949.489, -1710.532, 13.5468 }, { 1969.116, -1708.073, 15.9687 } },
	{ { 1910.69, -1605.422, 13.5468 }, { 1910.024, -1599.691, 13.9473 } },
	{ { 2078.861, -1122.541, 24.0825 }, { 2093.178, -1123.777, 27.6898 } },
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
	DeliverPizzaMarker = createMarker(unpack(StopPoints[PointID][2]))
	setElementAlpha(DeliverPizzaMarker, 0)
	exports.radar:findBestWay(unpack(StopPoints[PointID][1]))
end
addEventHandler("onClientPlayerVehicleEnter", localPlayer, function()
	if isElement(StopPointMarker) and getElementAlpha(StopPointMarker) == 0 then
		setElementAlpha(StopPointMarker, 100)
		setElementAlpha(DeliverPizzaMarker, 0)
		triggerServerEvent("pizza_delivery:attachPizzaBox", localPlayer, false)
	end
end)
addEventHandler("onClientMarkerHit", resourceRoot, function(player)
	if player ~= localPlayer then
		return
	end
	if getElementType(player) ~= "player" then
		return
	end
	if source == StopPointMarker then
		if not isPedInVehicle(player) then
			return
		end
		if getVehicleController(getPedOccupiedVehicle(player)) ~= player then
			return
		end
		if PIZZA_VEHICLES[getElementModel(getPedOccupiedVehicle(player))] then
			if getElementAlpha(source) == 0 then
				return
			end
			setPedControlState(localPlayer, "handbrake", true)
			setElementFrozen(getPedOccupiedVehicle(player), true)
			setTimer(setElementFrozen, 500, 1, getPedOccupiedVehicle(player), false)
			setPedExitVehicle(localPlayer)
			setElementAlpha(source, 0)
			setElementAlpha(DeliverPizzaMarker, 100)
			setTimer(triggerServerEvent, 1000, 1, "pizza_delivery:attachPizzaBox", localPlayer, true)
		end
	elseif source == DeliverPizzaMarker then
		if getElementAlpha(source) == 0 then
			return
		end
		triggerServerEvent("pizza_delivery:attachPizzaBox", localPlayer, false)
		exports["job-system"]:givePlayerJobEXP("Pizza Deliverer", 1)
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
end)
addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
	if job == "Pizza Deliverer" then
		pizzaStopJob()
	end
end)
function pizzaStopJob()
	if isElement(StopPointBlip) then
		destroyElement(StopPointBlip)
		destroyElement(StopPointMarker)
		StopPointBlip = nil
		StopPointMarker = nil
		if isElement(DeliverPizzaMarker) then
			if getElementAlpha(DeliverPizzaMarker) ~= 0 then
				triggerServerEvent("pizza_delivery:attachPizzaBox", localPlayer, false)
			end
			destroyElement(DeliverPizzaMarker)
			DeliverPizzaMarker = nil
		end
	end
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
	pizzaStopJob()
end)
