-- [Fix #160] gate table for task4 - A4 vehicle commands - owner: vehicle-manager/**, Vehicle/**
-- Owned EXCLUSIVELY by agent A4 vehicle commands - owner: vehicle-manager/**, Vehicle/**[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
staffRegisterGates({
        -- [Fix #160] A4 - handlers live in vehicle-manager/s_vehfix160.lua
        -- (plus the existing /respawnveh handler in vehicle-manager/s_vehicle_commands.lua)
        ["setvehjob"] = "setvehjob",
        -- /respawnveh is already mapped to vehicle.respawnallveh in the base map;
        -- TABLE = union-merge so BOTH rights stay live (any one of them grants it).
        ["respawnveh"] = { "vehicle.respawnallveh", "respawn_vehicle" },
        ["respawnjobvehs"] = "vehicle.respawnalljobveh",
        ["setarmored"] = "vehicle.setarmored",
        ["setvehowner"] = "setvehowner",
        ["unimpoundveh"] = "unimpoundveh",
        ["hideallnparkveh"] = "vehicle.hideallnparkveh",
})
