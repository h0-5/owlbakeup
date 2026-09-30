-- owlbakeup Fix #63 - Pizza Deliverer SERVER, rebuilt from the client
-- contract ([jobs]/pizza-delivery/client_decompiled.lua, Fix #54 pattern):
--   pizza_delivery:attachPizzaBox(bool) -> attach/remove the pizza box on
--     the deliverer's back (the walk-to-the-door phase of the decompiled
--     flow). The box model + bone transform are RECONSTRUCTED (server lost;
--     2880 is the pizza-box object, back-bone mount).
--   /startjob (jobs:start_job) re-fires onClientPlayerStartJob - the only
--     route-start trigger the decompiled client exposes; the flow works
--     because the deliverer takes the job first and sits on a Pizzaboy
--     before starting duty ("Type /jobhelp" hints confirm the order).
--   Two parked Pizzaboys (448) at Pizza Stack - reconstructed spawns ("You
--     can find the vehicles next to the pizza stack shop").
-- The decompile has NO giveJobSalary call - the job pays EXP only.

local jobBoxes = {} -- [player] = pizza box object

local PIZZA_STACK_BIKES = {
	{ 2105.6, -1806.8, 13.5, 318 },
	{ 2102.8, -1810.2, 13.5, 270 }
}

local function removeBox(player)
	local box = jobBoxes[player]
	if box then
		jobBoxes[player] = nil
		if isElement(box) then
			destroyElement(box)
		end
	end
end

addEvent("pizza_delivery:attachPizzaBox", true)
addEventHandler("pizza_delivery:attachPizzaBox", root, function(attach)
	local player = client
	if not player or getElementData(player, "job") ~= "Pizza Deliverer" then
		return
	end
	if attach then
		if jobBoxes[player] or not isElement(player) then
			return
		end
		if isPedInVehicle(player) then
			return
		end
		local box = createObject(2880, 0, 0, 0)
		if box then
			setObjectScale(box, 0.9)
			attachElements(box, player, 0, 0.25, 0.55, 0, 90, 0)
			jobBoxes[player] = box
		end
	else
		removeBox(player)
	end
end)

-- duty start: re-fire the take-job client event so the route begins when
-- the deliverer is sitting on the Pizzaboy
addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
	local player = client
	if not player or getElementData(player, "job") ~= "Pizza Deliverer" then
		return
	end
	triggerClientEvent(player, "onClientPlayerStartJob", player, "Pizza Deliverer")
end)

addEvent("jobs:quit_job", true)
addEventHandler("jobs:quit_job", root, function()
	local player = client
	if player then
		removeBox(player)
	end
end)

addEventHandler("onPlayerQuit", root, function()
	removeBox(source)
end)

addEventHandler("onVehicleExit", root, function(player)
	if jobBoxes[player] then
		removeBox(player) -- walked away from the bike mid-delivery
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	for _, spot in ipairs(PIZZA_STACK_BIKES) do
		local bike = createVehicle(448, spot[1], spot[2], spot[3], 0, 0, spot[4])
		if bike then
			setElementData(bike, "vehicle:owner.name", "job:Pizza Deliverer")
		end
	end
end)
