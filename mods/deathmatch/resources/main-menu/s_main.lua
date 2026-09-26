--[[
        Vortex Main Menu — server bridge (F1)

        Answers the original wnash client events with the same event names and
        the same payload field names the original client expects, using the
        resources that exist on this server. Missing systems (discord link bot,
        level system) reply with safe placeholders until their mods are restored:

          main-menu:characterInfo:getVehicles  -> :callback(list, slots)
                  list rows { ID, Name, plate, impounded, hidden }
          main-menu:characterInfo:getInteriors -> :callback(list, slots)
                  list rows { id, name, status, price }
          admin:showStaff (request)            -> admin:showStaff(list)
                  list rows { isSupport, id, name, hidden }
          leaderboard:get(kind)                -> leaderboard:get:response(kind, list)
                  list rows { name, level } | { name, points }
          main-menu:linkdiscord:generateCode   -> :callback(code)   (20 chars, 5 min)
          main-menu:linkdiscord:unlink         -> clears the stored account
]]

local function getCharacterId(thePlayer)
        return tonumber(getElementData(thePlayer, "account:character:id"))
                or tonumber(getElementData(thePlayer, "character:id"))
                or tonumber(getElementData(thePlayer, "dbid"))
                or -1
end

local function getResourceRunning(name)
        local res = getResourceFromName(name)
        if not res then return false end
        return getResourceState(res) == "running"
end

local function reply(thePlayer, eventName, ...)
        if isElement(thePlayer) then
                triggerClientEvent(eventName, thePlayer, ...)
        end
end

--[[ ==================== vehicles ==================== ]]

-- display name from vehicles_shop when joined, GTA model name otherwise
local function getVehicleDisplayName(row)
        local brand, model = row["vehbrand"], row["vehmodel"]
        if brand or model then
                return ("%s %s %s"):format(
                        tostring(row["vehyear"] or ""),
                        tostring(brand or ""),
                        tostring(model or "")
                ):match("^%s*(.-)%s*$")
        end
        return getVehicleNameFromModel(tonumber(row["model"]) or 411) or "Unknown"
end

local function buildVehiclesList(characterId)
        if characterId < 0 then return {}, 0 end
        if not getResourceRunning("mysql") then return {}, 0 end

        local ok, rows = pcall(function()
                return mysql:query(
                        "SELECT v.id, v.model, v.plate, v.Impounded, v.Hidden, " ..
                        "       s.vehbrand, s.vehmodel, s.vehyear " ..
                        "FROM `vehicles` v " ..
                        "LEFT JOIN `vehicles_shop` s ON v.vehicle_shop_id = s.id " ..
                        "WHERE v.owner = " .. mysql:escape_string(characterId) .. " " ..
                        "ORDER BY v.id ASC"
                )
        end)
        if not ok or type(rows) ~= "table" then return {}, 0 end

        local list = {}
        for _, row in ipairs(rows) do
                list[#list + 1] = {
                        ID        = tonumber(row["id"]) or 0,
                        Name      = getVehicleDisplayName(row),
                        plate     = tostring(row["plate"] or "--------"),
                        impounded = (tonumber(row["Impounded"]) or 0) == 1,
                        hidden    = tonumber(row["Hidden"]) or 0,
                }
        end
        return list, #list
end

addEvent("main-menu:characterInfo:getVehicles", true)
addEventHandler("main-menu:characterInfo:getVehicles", root, function()
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        local list, slots = buildVehiclesList(getCharacterId(thePlayer))
        reply(thePlayer, "main-menu:characterInfo:getVehicles:callback", list, slots)
end)

--[[ ==================== interiors ==================== ]]

local function buildInteriorsList(characterId)
        if characterId < 0 then return {}, 0 end
        if not getResourceRunning("mysql") then return {}, 0 end

        local ok, rows = pcall(function()
                return mysql:query(
                        "SELECT i.id, i.name, i.status, i.price, i.owner " ..
                        "FROM `interiors` i " ..
                        "WHERE i.owner = " .. mysql:escape_string(characterId) .. " " ..
                        "ORDER BY i.id ASC"
                )
        end)
        if not ok or type(rows) ~= "table" then return {}, 0 end

        local list = {}
        for _, row in ipairs(rows) do
                list[#list + 1] = {
                        id     = tonumber(row["id"]) or 0,
                        name   = tostring(row["name"] or "Interior"),
                        status = tostring(row["status"] or "-"),
                        price  = tonumber(row["price"]) or 0,
                }
        end
        return list, #list
end

addEvent("main-menu:characterInfo:getInteriors", true)
addEventHandler("main-menu:characterInfo:getInteriors", root, function()
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        local list, slots = buildInteriorsList(getCharacterId(thePlayer))
        reply(thePlayer, "main-menu:characterInfo:getInteriors:callback", list, slots)
end)

--[[ ==================== online staff ==================== ]]
-- payload per row: { isSupport, id, name, hidden } (client unpacks by index)

addEvent("admin:showStaff", true)
addEventHandler("admin:showStaff", root, function()
        local thePlayer = client or source
        if not isElement(thePlayer) then return end

        local list = {}
        for _, player in ipairs(getElementsByType("player")) do
                local level = false
                if getResourceRunning("global") then
                        local ok, value = pcall(function()
                                return exports.global:getPlayerAdminLevel(player)
                        end)
                        if ok then level = tonumber(value) or 0 end
                end
                if level and level > 0 then
                        list[#list + 1] = {
                                level == 1,                                -- [1] isSupport
                                getPlayerIDStrSafe(player),                -- [2] id
                                getPlayerName(player):gsub("_", " "),      -- [3] name
                                false,                                     -- [4] hidden
                        }
                end
        end
        reply(thePlayer, "admin:showStaff", list)
end)

function getPlayerIDStrSafe(player)
        return tostring(getElementData(player, "account:character:id")
                or getElementData(player, "character:id")
                or getElementData(player, "playerid")
                or "-")
end

--[[ ==================== leaderboard ==================== ]]
-- placeholder until the level-system mod is restored: replies with an
-- empty list so the client grid simply renders empty (same as PDZ bridge)

addEvent("leaderboard:get", true)
addEventHandler("leaderboard:get", root, function(kind)
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        if kind ~= "levels" and kind ~= "activities" then return end
        reply(thePlayer, "leaderboard:get:response", kind, {})
end)

--[[ ==================== discord link ==================== ]]

local CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local function generateCode()
        local code = {}
        for i = 1, 20 do
                local pos = math.random(1, #CODE_CHARS)
                code[i] = CODE_CHARS:sub(pos, pos)
                if i % 5 == 0 and i < 20 then code[#code + 1] = "-" end
        end
        return table.concat(code)
end

addEvent("main-menu:linkdiscord:generateCode", true)
addEventHandler("main-menu:linkdiscord:generateCode", root, function()
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        local code = generateCode()
        setElementData(thePlayer, "main-menu:discord:code", code)
        setElementData(thePlayer, "main-menu:discord:code:time", getRealTime().timestamp)
        reply(thePlayer, "main-menu:linkdiscord:generateCode:callback", code)
end)

addEvent("main-menu:linkdiscord:unlink", true)
addEventHandler("main-menu:linkdiscord:unlink", root, function(characterId)
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        removeElementData(thePlayer, "main-menu:discord:code")
        removeElementData(thePlayer, "main-menu:discord:account")
        -- the discord bot integration will clear the DB row once restored
        outputDebugString("[main-menu] unlink requested for character " .. tostring(characterId))
end)
