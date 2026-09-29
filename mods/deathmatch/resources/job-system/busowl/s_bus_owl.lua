-- owlbakeup Fix #63 - Bus Driver SERVER, rebuilt from the client contract
-- ([jobs]/bus-driver/bus_c_decompiled.lua, Fix #54 pattern):
--   /startjob (jobs:start_job) re-fires onClientPlayerStartJob - the only
--     route-start trigger the decompiled client exposes (pizza flow).
--   Two parked buses (431) at the first bus stop's depot area (1823, -1853,
--     LS bus stop) - reconstructed spawns ("Take a bus").
-- The decompile has NO giveJobSalary call - the job pays EXP only.

local BUS_SPAWNS = {
	{ 1817.9, -1858.4, 13.4, 90 },
	{ 1817.9, -1866.2, 13.4, 90 }
}

addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
	local player = client
	if not player or getElementData(player, "job") ~= "Bus Driver" then
		return
	end
	triggerClientEvent(player, "onClientPlayerStartJob", player, "Bus Driver")
end)

addEventHandler("onResourceStart", resourceRoot, function()
	for _, spot in ipairs(BUS_SPAWNS) do
		local bus = createVehicle(431, spot[1], spot[2], spot[3], 0, 0, spot[4])
		if bus then
			setElementData(bus, "vehicle:owner.name", "job:Bus Driver")
		end
	end
end)
