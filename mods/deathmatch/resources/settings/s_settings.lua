--------------------------------------------------------------------------------
-- VORTEX settings — server (Fix #18)
-- Minimal server side of the old settings resource: stores per-user settings
-- pushed by trusted clients and syncs them back on request.
--------------------------------------------------------------------------------

local userSettings = {}  -- [player] = { [index] = value }

addEvent("settings:setSetting", true)
addEventHandler("settings:setSetting", root, function(key, value)
        local player = client
        if not player or client ~= source then return end
        if type(key) ~= "string" or #key > 64 then return end
        if not userSettings[player] then userSettings[player] = {} end
        userSettings[player][key] = value
        triggerClientEvent(player, "settings:user:sync", player, userSettings[player])
end)

addEventHandler("onPlayerLogin", root, function()
        local list = userSettings[source]
        if list then
                triggerClientEvent(source, "settings:user:sync", source, list)
        end
end)

addEventHandler("onPlayerQuit", root, function()
        userSettings[source] = nil
end)
