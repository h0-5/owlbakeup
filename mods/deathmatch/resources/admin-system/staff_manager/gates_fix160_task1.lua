-- [Fix #160] gate table for task1 - A1 blacklist.add/remove - owner: account/**, global/s_bannedPlayers.lua
-- Owned EXCLUSIVELY by agent A1 blacklist.add/remove - owner: account/**, global/s_bannedPlayers.lua[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
staffRegisterGates({
        -- [Fix #160] A1 - account/s_blacklist.lua registers both commands
        ["blacklistadd"] = "blacklist.add",
        ["blacklistremove"] = "blacklist.remove",
})

