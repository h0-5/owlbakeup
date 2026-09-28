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
                -- [Vortex fix] MTA's targeted form is (sendTo, eventName, source, ...);
                -- the old (eventName, thePlayer) order was read by MTA as the BROADCAST
                -- form (string first arg), so every online client received and rendered
                -- this player's vehicles/interiors/staff data.
                triggerClientEvent(thePlayer, eventName, thePlayer, ...)
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

        -- [Vortex fix] v.Hidden does not exist in this server's vehicles
        -- table, so the WHOLE query errored and the F1 list was always empty.
        -- Select only columns that really exist (verified against
        -- vehicle-system/s_vehicle_system.lua: id/model/plate/Impounded).
        local ok, rows = pcall(function()
                return mysql:query(
                        "SELECT v.id, v.model, v.plate, v.Impounded, " ..
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

        -- [Vortex fix] the interiors table has no `status`/`price` columns
        -- (verified against interior-system/s_interior_system.lua): the query
        -- always errored and the F1 list stayed empty. Real columns are
        -- locked/cost + deleted; status is derived from them.
        local ok, rows = pcall(function()
                return mysql:query(
                        "SELECT i.id, i.name, i.locked, i.cost " ..
                        "FROM `interiors` i " ..
                        "WHERE i.owner = " .. mysql:escape_string(characterId) .. " " ..
                        "AND (i.deleted = 0 OR i.deleted IS NULL) " ..
                        "ORDER BY i.id ASC"
                )
        end)
        if not ok or type(rows) ~= "table" then return {}, 0 end

        local list = {}
        for _, row in ipairs(rows) do
                local locked = (tonumber(row["locked"]) or 0) == 1
                list[#list + 1] = {
                        id     = tonumber(row["id"]) or 0,
                        name   = tostring(row["name"] or "Interior"),
                        status = locked and "locked" or "owned",
                        price  = tonumber(row["cost"]) or 0,
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
                -- [Vortex fix] rank-aware classification for the 21-rank ladder:
                -- admin_level>0  -> Admins Team (Trial Moderator and above)
                -- supporter_level>0 (without admin) -> Supports Team (Trial
                -- Support / Support) -- these were invisible before.
                -- [Vortex] rank:index (staff bridge) is THE source when it
                -- exists, so Owner/Founder/Tester etc. always land in the
                -- right team; legacy columns stay the fallback otherwise.
                local admin, support
                local ridx = tonumber(getElementData(player, "rank:index"))
                if ridx then
                        admin = (ridx >= 4) and ridx or 0                 -- Trial Moderator+
                        support = (ridx >= 1 and ridx <= 3) and ridx or 0 -- Trial Support..Support
                else
                        admin = tonumber(getElementData(player, "admin_level")) or 0
                        support = tonumber(getElementData(player, "supporter_level")) or 0
                        if admin == 0 and getResourceRunning("global") then
                                local ok, value = pcall(function()
                                        return exports.global:getPlayerAdminLevel(player)
                                end)
                                if ok and value then admin = tonumber(value) or admin end
                        end
                end
                if admin > 0 or support > 0 then
                        -- [Fix #14] unified rank title + color ship with the row
                        local rname = tostring(getElementData(player, "rank:name") or "")
                        local rcolor = getElementData(player, "rank:color")
                        list[#list + 1] = {
                                admin == 0 and support > 0,                -- [1] isSupport
                                getPlayerIDStrSafe(player),                -- [2] id
                                getPlayerName(player):gsub("_", " "),      -- [3] name
                                (getElementData(player, "hiddenadmin") or 0) == 1, -- [4] hidden
                                rname ~= "" and rname or nil,              -- [5] rank title
                                type(rcolor) == "table" and rcolor or nil, -- [6] rank color
                                tostring(getElementData(player, "account:username") or "-"), -- [7] account name (Fix #26)
                                tostring(getElementData(player, "account:id")
                                        or getElementData(player, "account:character:id") or "-"), -- [8] account id (Fix #26)
                                (tonumber(getElementData(player, "duty_admin")) == 1
                                        or tonumber(getElementData(player, "duty_supporter")) == 1), -- [9] on duty (Fix #26)
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

--[[ ==================== radio channels (Fix #26) ==================== ]]
addEvent("main-menu:radio:list", true)
addEventHandler("main-menu:radio:list", root, function()
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        local list = {}
        local q = exports.mysql:query("SELECT id, station_name, source FROM radio_stations WHERE enabled='1' ORDER BY id ASC")
        if q then
                while true do
                        local row = exports.mysql:fetch_assoc(q)
                        if not row then break end
                        list[#list + 1] = { tonumber(row.id), tostring(row.station_name), tostring(row.source) }
                end
                exports.mysql:free_result(q)
        end
        reply(thePlayer, "main-menu:radio:list:callback", list)
end)

addEvent("main-menu:radio:add", true)
addEventHandler("main-menu:radio:add", root, function(name, url)
        local thePlayer = client or source
        if not isElement(thePlayer) then return end
        -- BACKEND permission check: staff only
        if (tonumber(getElementData(thePlayer, "admin_level")) or 0) <= 0
                and (tonumber(getElementData(thePlayer, "account:gmlevel")) or 0) <= 0 then
                triggerClientEvent(thePlayer, "main-menu:radio:added", thePlayer,
                        false, "You don't have permission to use this command.")
                return
        end
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        url = tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if #name < 2 or #name > 50 then
                triggerClientEvent(thePlayer, "main-menu:radio:added", thePlayer,
                        false, "اسم القناة قصير أو طويل جداً (2-50 حرف).")
                return
        end
        if url == "" or (#url > 255) or not url:find("^https?://") then
                triggerClientEvent(thePlayer, "main-menu:radio:added", thePlayer,
                        false, "رابط البث غير صالح (يجب أن يبدأ http أو https).")
                return
        end
        local ok = exports.mysql:query_free("INSERT INTO radio_stations (station_name, source, enabled) VALUES ('"
                .. exports.mysql:escape_string(name) .. "', '"
                .. exports.mysql:escape_string(url) .. "', '1')")
        if ok then
                -- carradio re-syncs its stream table on its own refresh timer
                triggerClientEvent(thePlayer, "main-menu:radio:added", thePlayer,
                        true, "تمت إضافة قناة الراديو بنجاح ✔")
        else
                triggerClientEvent(thePlayer, "main-menu:radio:added", thePlayer,
                        false, "فشل حفظ القناة في قاعدة البيانات.")
        end
end)

--------------------------------------------------------------------------------
-- [Fix #35] F1 load sentinel (server half): a player who is logged in but
-- whose client never pinged mainmenu:clientLoaded has a dead main-menu
-- client script (load abort) - tell them instead of letting F1 be silent.
--------------------------------------------------------------------------------
addEvent("mainmenu:clientLoaded", true)
addEventHandler("mainmenu:clientLoaded", root, function()
        if client then setElementData(client, "mainmenu:loaded", true, false) end
end)

addEventHandler("onPlayerJoin", root, function()
        local pid = source
        setTimer(function()
                if isElement(pid) and tonumber(getElementData(pid, "loggedin")) == 1
                        and not getElementData(pid, "mainmenu:loaded") then
                        outputChatBox("[F1] main-menu client script failed to load - report this to Keeler.",
                                pid, 255, 120, 120, false)
                end
        end, 25000, 1, pid)
end)
