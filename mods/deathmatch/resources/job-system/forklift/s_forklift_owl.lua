-- owlbakeup Fix #63 - Forklift Operator SERVER, rebuilt from the client
-- contract ([jobs]/forklift-operator/client_decompiled.lua, Fix #54 pattern):
--   /startjob (jobs:start_job) re-fires onClientPlayerStartJob - the only
--     route-start trigger the decompiled client exposes (same flow as pizza:
--     take job at the ped, sit in a forklift, start duty).
--   Two parked Forklifts (530) at the SF-dock site (the lift marker's
--     hardcoded site -1471.5, 277.97 places the job) - reconstructed spawns.
-- The decompile has NO giveJobSalary call - the job pays EXP only.

local FORKLIFT_SPAWNS = {
	{ -1477.9, 271.4, 7.2, 90 },
	{ -1477.9, 284.6, 7.2, 90 }
}

addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
	local player = client
	if not player or getElementData(player, "job") ~= "Forklift Operator" then
		return
	end
	triggerClientEvent(player, "onClientPlayerStartJob", player, "Forklift Operator")
end)

addEventHandler("onResourceStart", resourceRoot, function()
	for _, spot in ipairs(FORKLIFT_SPAWNS) do
		local forklift = createVehicle(530, spot[1], spot[2], spot[3], 0, 0, spot[4])
		if forklift then
			setElementData(forklift, "vehicle:owner.name", "job:Forklift Operator")
		end
	end
end)
