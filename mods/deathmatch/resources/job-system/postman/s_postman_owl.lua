-- owlbakeup Fix #63 - Postman SERVER, rebuilt from the client contract
-- ([jobs]/postman/client_decompiled.lua, Fix #54 pattern):
--   postman:attachBox(bool, model)   -> the mail box on the postman's back
--     (attach transform reconstructed; model 2912 verbatim)
--   postman:putBoxInsideVehicle(veh) -> validate carrying distance + truck
--     gate, temp:boxes +1 (server-authoritative elementData)
--   postman:openVehicleTrunk(veh)    -> opens the van's rear door
--   Two parked Burritos (482, reconstructed gate) at the first mail stop.
-- No giveJobSalary call in the decompile - EXP-only per delivered box.

local boxOnBack = {} -- [player] = box object

local MAIL_TRUCKS = {
	{ 1777.9, -2055.4, 13.4, 270 },
	{ 1777.9, -2061.2, 13.4, 270 }
}

local function removeBox(player)
	local box = boxOnBack[player]
	if box then
		boxOnBack[player] = nil
		if isElement(box) then
			destroyElement(box)
		end
	end
end

addEvent("postman:attachBox", true)
addEventHandler("postman:attachBox", root, function(attach, model)
	local player = client
	if not player or getElementData(player, "job") ~= "Postman" then
		return
	end
	if attach then
		if boxOnBack[player] or isPedInVehicle(player) then
			return
		end
		local box = createObject(tonumber(model) or 2912, 0, 0, 0)
		if box then
			attachElements(box, player, 0, 0.3, 0.6, 0, 90, 0)
			boxOnBack[player] = box
		end
	else
		removeBox(player)
	end
end)

addEvent("postman:putBoxInsideVehicle", true)
addEventHandler("postman:putBoxInsideVehicle", root, function(vehicle)
	local player = client
	if not player or not boxOnBack[player] then
		return
	end
	if getElementType(vehicle) ~= "vehicle" or getElementModel(vehicle) ~= 482 then
		return
	end
	local px, py, pz = getElementPosition(player)
	local vx, vy, vz = getElementPosition(vehicle)
	if getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz) > 5 then
		return
	end
	removeBox(player)
	setVehicleDoorOpenRatio(vehicle, 1, 1, 200)
	setTimer(setVehicleDoorOpenRatio, 3000, 1, vehicle, 1, 0, 300)
	local boxes = tonumber(getElementData(vehicle, "temp:boxes")) or 0
	exports.anticheat:changeProtectedElementDataEx(vehicle, "temp:boxes", boxes + 1, true)
end)

addEvent("postman:openVehicleTrunk", true)
addEventHandler("postman:openVehicleTrunk", root, function(vehicle)
	local player = client
	if not player or getElementType(vehicle) ~= "vehicle" then
		return
	end
	setVehicleDoorOpenRatio(vehicle, 1, 1, 200)
end)

addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
	local player = client
	if not player or getElementData(player, "job") ~= "Postman" then
		return
	end
	triggerClientEvent(player, "onClientPlayerStartJob", player, "Postman")
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

addEventHandler("onResourceStart", resourceRoot, function()
	for _, spot in ipairs(MAIL_TRUCKS) do
		local van = createVehicle(482, spot[1], spot[2], spot[3], 0, 0, spot[4])
		if van then
			setElementData(van, "vehicle:owner.name", "job:Postman")
		end
	end
end)
