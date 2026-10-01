mysql = exports.mysql



-- EVENTS

addEvent("onPlayerJoinFaction", false)

addEventHandler("onPlayerJoinFaction", getRootElement(),

        function(theTeam)

                return

        end

)



locations = { }

custom = { }

-- [Fix #137] vehicle shop price cache, keyed by vehicle_shop_id, so repeated
-- finance renders do not re-query vehicles_shop for the same shop id.

local vehPrice = {}



-- [Fix #146] permanent faction audit trail (factionlogs table). Best effort
-- only: the INSERT runs inside pcall so a failed log can never abort the
-- mutation it records. Shared with s_faction_admin.lua.

function logFactionAction(factionID, actorName, text)

        local ok, err = pcall(function()

                mysql:query_free("INSERT INTO factionlogs (factionID, charactername, log) VALUES ('" .. mysql:escape_string(tonumber(factionID) or 0) .. "', '" .. mysql:escape_string(tostring(actorName or "Unknown")) .. "', '" .. mysql:escape_string(tostring(text or "")) .. "')")

        end)

        if not ok then

                outputDebugString("faction-system: logFactionAction failed: " .. tostring(err), 2)

        end

end



-- [Fix #146] F3 Logs tab history pull. Server-side membership check (the
-- client may only read its OWN faction's log), last 100 rows returned as a
-- plain toJSON-able array { {date=..., who=..., what=...}, ... }.

addEvent("faction:logs:request", true)

addEventHandler("faction:logs:request", resourceRoot, function()

        if not client or getElementType(client) ~= "player" then

                return

        end

        local theTeam = getPlayerTeam(client)

        local factionID = theTeam and tonumber(getElementData(theTeam, "id")) or nil

        if not factionID or factionID < 1 then

                return

        end

        local rows = { }

        local result = mysql:query("SELECT date, charactername, log FROM factionlogs WHERE factionID='" .. mysql:escape_string(factionID) .. "' ORDER BY date DESC, id DESC LIMIT 100")

        if result then

                while true do

                        local row = mysql:fetch_assoc(result)

                        if not row then break end

                        rows[#rows + 1] = { date = tostring(row.date or ""), who = tostring(row.charactername or ""), what = tostring(row.log or "") }

                end

                mysql:free_result(result)

        end

        triggerClientEvent(client, "faction:logs:receive", client, rows)

end)



function loadAllFactions(res)

        local counter = 0

        setElementData(resourceRoot, "DutyGUI", {})



        local result = mysql:query("SELECT * FROM factions ORDER BY id ASC")

        if not result then return end



        while result do

                local row = mysql:fetch_assoc(result)

                if not row then break end

                

                local id = tonumber(row.id)

                local name = row.name

                local money = tonumber(row.bankbalance)

                local factionType = tonumber(row.type)

                

                local theTeam = createTeam(tostring(name))

                exports.pool:allocateElement(theTeam, id)

                setFactionProtectedData(theTeam, "type", factionType, true)

                setFactionProtectedData(theTeam, "money", money, true)

                setFactionProtectedData(theTeam, "id", id, true)

                

                local factionRanks = {}

                local factionWages = {}

                for i = 1, 20 do

                        factionRanks[i] = row['rank_'..i]

                        factionWages[i] = tonumber(row['wage_'..i])

                end

                local motd = row.motd

                setFactionProtectedData(theTeam, "ranks", factionRanks, true)

                setFactionProtectedData(theTeam, "wages", factionWages, false)

                setFactionProtectedData(theTeam, "motd", motd, false)

                setFactionProtectedData(theTeam, "note", row.note == nil and "" or row.note, false)

                setFactionProtectedData(theTeam, "fnote", row.fnote == nil and "" or row.fnote, false)

                setFactionProtectedData(theTeam, "phone", row.phone ~= nil and row.phone or nil, false)

                -- [Fix #147] header live data (SELECT * already returns the new
                -- color/hotline/radio columns). Synchronized = true, unlike the
                -- server-only keys above, because the F3 header reads them from
                -- the client with getElementData(team, ...).

                setFactionProtectedData(theTeam, "color", row.color ~= nil and tostring(row.color) or "#FFFFFF", true)

                setFactionProtectedData(theTeam, "hotline", row.hotline ~= nil and tostring(row.hotline) or "", true)

                setFactionProtectedData(theTeam, "radio", row.radio ~= nil and tostring(row.radio) or "", true)

                setFactionProtectedData(theTeam, "max_interiors", tonumber(row.max_interiors), false, true) --Don't sync at all / Maxime



                custom[id] = { }

                local customQ = mysql:query("SELECT * FROM duty_custom WHERE factionid = ".. id .." ORDER BY id ASC")

                while customQ do

                        local row = mysql:fetch_assoc(customQ)

                        if not row then break end

                

                        local skins = fromJSON(tostring(row.skins)) or {}

                        local locations = fromJSON(tostring(row.locations)) or {}

                        local items = fromJSON(tostring(row.items)) or {}

                        custom[id][tonumber(row.id)] = { row.id, row.name, skins, locations, items }

                        --table.insert( custom, id[tonumber(row.id)], { row.id, row.name, skins, locations, items } )

                end

                mysql:free_result(customQ)



                locations[id] = { }

                local locationQ = mysql:query("SELECT * FROM duty_locations WHERE factionid = ".. id .." ORDER BY id ASC")

                while locationQ do

                        local row = mysql:fetch_assoc(locationQ)

                        if not row then break end

                        locations[id][tonumber(row.id)] = { row.id, row.name, row.x, row.y, row.z, row.radius, row.dimension, row.interior, row.vehicleid, row.model }

                        if not tonumber(row.model) then -- If it's not a vehicle it must be a location. Right?

                                exports.duty:createDutyColShape(row.x, row.y, row.z, row.radius, row.interior, row.dimension, id, row.id)

                        end

                end

                mysql:free_result(locationQ)

                counter = counter + 1

        end

        -- [Fix #139] removed triggerEvent("Duty:updateDuty", root, custom): it had
        -- no listener anywhere in the codebase. The duty resource already gets the
        -- data through the elementData writes below (and refreshClient()).

        mysql:free_result(result)



        maxIndex = 0

        local maxl = mysql:query_fetch_assoc("SELECT id FROM duty_locations ORDER BY id DESC LIMIT 0, 1") -- Cache Last Insert IDs

        if maxl and maxl.id ~= nil and tonumber(maxl.id) then

                maxIndex = tonumber(maxl.id)

        end

        setElementData(resourceRoot, "maxlindex", maxIndex)



        maxIndex = 0

        local maxc = mysql:query_fetch_assoc("SELECT id FROM duty_custom ORDER BY id DESC LIMIT 0, 1")

        if maxc and maxc.id ~= nil and tonumber(maxc.id) then

                maxIndex = tonumber(maxc.id)

        end

        setElementData(resourceRoot, "maxcindex", maxIndex)



        local citteam = createTeam("Citizen", 255, 255, 255)

        exports.pool:allocateElement(citteam, -1)

        

        -- set all players into their appropriate faction

        local players = exports.pool:getPoolElementsByType("player")

        for k, thePlayer in ipairs(players) do

                local username = getPlayerName(thePlayer)

                local safeusername = mysql:escape_string(username)

                

                local result = mysql:query_fetch_assoc("SELECT faction_id, faction_rank, faction_leader, faction_perks, faction_phone FROM characters WHERE charactername='" .. safeusername .. "' LIMIT 1")

                if result then

                        setFactionProtectedData(thePlayer, "factionMenu", 0, false)

                        setFactionProtectedData(thePlayer, "faction", tonumber(result.faction_id), false)

                        setFactionProtectedData(thePlayer, "factionrank", tonumber(result.faction_rank), false)

                        setFactionProtectedData(thePlayer, "factionphone", tonumber(result.faction_phone), false)

                        setFactionProtectedData(thePlayer, "factionleader", tonumber(result.faction_leader), false)

                        setFactionProtectedData(thePlayer, "factionPackages", type(result.faction_perks) == "string" and fromJSON(result.faction_perks) or { }, true)

                        

                        setPlayerTeam(thePlayer, exports.pool:getElement("team", result.faction_id) or citteam)

                end

        end



        setElementData(getResourceRootElement(getResourceFromName("duty")), "factionDuty", custom)

        setElementData(getResourceRootElement(getResourceFromName("duty")), "factionLocations", locations)

        

end



addEventHandler("onResourceStart", resourceRoot, loadAllFactions)



function hasPlayerAccessOverFaction(theElement, factionID)

        if (isElement(theElement)) then -- Is the player online?

                local realFactionID = getElementData(theElement, "faction") or -1

                local factionLeaderStatus = getElementData(theElement, "factionleader") or 0

                if tonumber(realFactionID) == tonumber(factionID) then -- Is the player in the specific faction

                        if tonumber(factionLeaderStatus) == 1 then -- Is the player a faction leader?

                                return true

                        end

                end

        end

        return false

end



-- [Fix #103] [Fix #104] Client supplied factionIDs are never trusted.
--      requireLeader = true  -> write gate (Duty:Add*/Duty:Remove*): the
--              requested faction must be the caller's OWN faction and the
--              caller must pass hasPlayerAccessOverFaction().
--      requireLeader = false -> read gate (fetchDutyInfo / Duty:Grab /
--              Duty:GetPackages): the caller must simply belong to the
--              requested faction.
-- Returns the verified factionID, or nil when the caller must be rejected.

function fsVerifyCallerFaction(requestedFactionID, requireLeader)

        if not client or getElementType(client) ~= "player" then return nil end

        local team = getPlayerTeam(client)

        if not isElement(team) then return nil end

        local myFactionID = tonumber(getElementData(team, "id"))

        if not myFactionID or myFactionID < 1 then return nil end

        if requestedFactionID ~= nil and tonumber(requestedFactionID) ~= myFactionID then

                return nil -- mismatched client argument -> rejected

        end

        if requireLeader and not hasPlayerAccessOverFaction(client, myFactionID) then

                return nil

        end

        return myFactionID

end



-- returns stateid, factionid, factionrank, factionleader, table with factionperks, element of player if applicable

-- stateid 0: Online, stateid 1: Offline, stateid 2: Not found

function getPlayerFaction(playerName)

        local thePlayerElement = getPlayerFromName(playerName)

        local override = false

        if (thePlayerElement) then -- Player is online

                if (getElementData(thePlayerElement, "loggedin") ~= 1) then

                        override = true

                else

                        local playerFaction = getElementData(thePlayerElement, "faction")

                        local playerFactionRank = getElementData(thePlayerElement, "factionrank")

                        local playerFactionLeader = getElementData(thePlayerElement, "factionleader")

                        local playerFactionPerks = getElementData(thePlayerElement, "factionPackages")

                        

                        return 0, playerFaction, playerFactionRank, playerFactionLeader, playerFactionPerks, thePlayerElement

                end

        end

        

        if (not thePlayerElement or override) then  -- Player is offline

                local row = mysql:query_fetch_assoc("SELECT faction_id, faction_rank, faction_perks, faction_leader FROM characters WHERE charactername='" .. mysql:escape_string(playerName) .. "'")

                if row then

                        return 1, tonumber(row["faction_id"]), tonumber(row["faction_rank"]), tonumber(row["faction_leader"]), (fromJSON(row["faction_perks"]) or { }), nil

                end

        end

        

        return 2, -1, 20, 0, { }, nil -- Player was not found

end




-- [Fix #47] resilient protected-data write: a stopped/restarting anticheat
-- resource used to raise "Call to non-running server resource" and kill the
-- whole calling function (F3 chain: faction/factionMenu never set -> menu
-- could never open). Falls back to a plain synced setElementData.
function setFactionProtectedData(element, key, value, synchronize, noSyncAtAll)
        if element == nil or key == nil then return false end
        local ac = getResourceFromName("anticheat")
        if ac and getResourceState(ac) == "running" then
                local ok = pcall(function()
                        -- [Fix #120] this used to call setFactionProtectedData
                        -- itself (infinite self-recursion blew the stack inside
                        -- the pcall and every write silently fell back to a plain
                        -- setElementData). Delegate to the anticheat export.
                        exports.anticheat:changeProtectedElementDataEx(element, key, value, synchronize, noSyncAtAll)
                end)
                if ok then return true end
        end
        setElementData(element, key, value, synchronize == true)
        return true
end

-- Bind Keys required

function bindKeys()

        local players = exports.pool:getPoolElementsByType("player")

        for k, arrayPlayer in ipairs(players) do

                if not(isKeyBound(arrayPlayer, "F3", "down", showFactionMenu)) then

                        bindKey(arrayPlayer, "F3", "down", showFactionMenu)

                end

        end

end



function bindKeysOnJoin()

        -- [Fix #150] same isKeyBound(..., showFactionMenu) double-bind guard as
        -- bindKeys() above, so a re-join/restart path can never stack F3 handlers

        if not isKeyBound(source, "F3", "down", showFactionMenu) then

                bindKey(source, "F3", "down", showFactionMenu)

        end

end

addEventHandler("onResourceStart", getResourceRootElement(), bindKeys)

addEventHandler("onPlayerJoin", getRootElement(), bindKeysOnJoin)



function showFactionMenu(source)

        showFactionMenuEx(source)

end



function showFactionMenuEx(source, factionID, fromShowF)

        local logged = getElementData(source, "loggedin")

        

        if (logged==1) then

                local menuVisible = getElementData(source, "factionMenu")

                

                -- [Fix #47] ~= 1 (not ==0): data that was never initialized (nil)
                -- used to block F3 forever with no feedback
                if (menuVisible~=1) then

                        local factionID = factionID or getElementData(source, "faction")

                        

                        if (factionID~=-1) then

                                local theTeam = exports.pool:getElement("team", factionID)

                                local query = mysql:query("SELECT charactername,  faction_rank, faction_perks, faction_leader, faction_phone, DATEDIFF(NOW(), lastlogin) AS lastlogin FROM characters WHERE faction_ID='" .. factionID .. "' ORDER BY faction_rank DESC, charactername ASC")

                                if query then

                                        

                                        local memberUsernames = {}

                                        local memberRanks = {}

                                        local memberLeaders = {}

                                        local memberOnline = {}

                                        local memberLastLogin = {}

                                        --[[local memberLocation = {}]]

                                        local memberPerks = {}

                                        local factionRanks = getElementData(theTeam, "ranks")

                                        local factionWages = getElementData(theTeam, "wages")

                                        local motd = getElementData(theTeam, "motd")

                                        local note = hasPlayerAccessOverFaction(source, factionID) and getElementData(theTeam, "note")

                                        local fnote = getElementData(theTeam, "fnote")

                                        local vehicleIDs = {}

                                        local vehicleModels = {}

                                        local vehiclePlates = {}

                                        local vehicleLocations = {}

                                        local memberOnDuty = {}

                                        local phone = getElementData(theTeam, "phone")

                                        local memberPhones = phone and {} or nil



                                        if (motd == "") then motd = nil end

                                        

                                        local i = 1

                                        while query do

                                                local row = mysql:fetch_assoc(query)

                                                if not row then break end

                                                

                                                local playerName = row.charactername

                                                memberUsernames[i] = playerName

                                                memberRanks[i] = row.faction_rank

                                                memberPerks[i] = type(row.faction_perks) == "string" and fromJSON(row.faction_perks) or { }

                                                if phone and row.faction_phone ~= nil and tonumber(row.faction_phone) then

                                                        memberPhones[i] = ("%02d"):format(tonumber(row.faction_phone))

                                                end



                                                if (tonumber(row.faction_leader)==1) then

                                                        memberLeaders[i] = true

                                                else

                                                        memberLeaders[i] = false

                                                end

                                                

                                                local login = ""

                                                

                                                memberLastLogin[i] = tonumber(row.lastlogin)

                                                if getPlayerFromName(playerName) then

                                                        local testingPlayer = getPlayerFromName(playerName)

                                                        local onlineState = getElementData(testingPlayer, "loggedin")

                                                        if (onlineState == 1) then

                                                                --[[if getElementDimension(testingPlayer) == 0 and getElementInterior(testingPlayer) == 0 then

                                                                        memberLocation[i] = tostring(exports.global:getElementZoneName(testingPlayer, false))

                                                                else

                                                                        memberLocation[i] = "Unknown"

                                                                end]]

                                                                memberOnline[i] = true

                                                                

                                                                local dutydata = getElementData(testingPlayer, "duty")

                                                                if dutydata then

                                                                        if(tonumber(dutydata) > 0) then

                                                                                memberOnDuty[i] = true

                                                                        else

                                                                                memberOnDuty[i] = false 

                                                                        end

                                                                end                                                             

                                                        end

                                                else

                                                        memberOnline[i] = false

                                                        memberOnDuty[i] = false

                                                        --[[memberLocation[i] = "Unknown"]]

                                                end

                                                i = i + 1

                                        end

                                        mysql:free_result( query )



                                        -- [Fix #141] the towstats query result was shipped to the
                                        -- client but never rendered anywhere: keep the argument
                                        -- slot (so no showFactionMenu position shifts) and send an
                                        -- empty table instead of running the dead query.
                                        local towstats = {}

                                        if hasPlayerAccessOverFaction(source, factionID) then

                                                local result = mysql:query("SELECT id, model, currx, curry, currz, plate FROM vehicles WHERE faction=" .. factionID .. " AND deleted=0")

                                                if result then

                                                        local j = 1

                                                        while result do

                                                                local row = mysql:fetch_assoc(result)

                                                                if not row then break end

                                                                vehicleIDs[j] = row.id

                                                                vehiclePlates[j] = row.plate

                                                                local veh = exports.pool:getElement("vehicle", row.id)

                                                                vehicleModels[j] = exports.global:getVehicleName(veh)

                                                                if true then -- this is totally non-sense / maxime / exports.global:hasItem(veh, 139) and getElementDimension(veh) == 0 and getElementInterior(veh) == 0 then

                                                                        vehicleLocations[j] = exports.global:getElementZoneName(veh) 

                                                                else

                                                                        vehicleLocations[j] = "Unknown"

                                                                end

                                                                j = j + 1

                                                        end

                                                        mysql:free_result(result)

                                                end



                                        end

                                        local theTeam = exports.pool:getElement("team", factionID)

                                        -- [Fix #136] NEW LAST (23rd) argument of showFactionMenu:
                                        -- vehLimit (client reads F.data.vehLimit). The factions table
                                        -- has no vehicle limit column (live schema verified: id, name,
                                        -- bankbalance, type, rank_1..20, wage_1..20, motd, note, fnote,
                                        -- phone, max_interiors) and no resource enforces a faction
                                        -- vehicle cap, so the slot carries the faction's current active
                                        -- fleet size (i.e. no cap is enforced today).
                                        local vehLimit = #vehicleIDs

                                        -- [Fix #149] the F3 gate blocks `~= 1`: if this build threw,
                                        -- factionMenu stayed 1 and F3 was dead until relog. Build and
                                        -- send inside a pcall and roll the flag back + hide the menu
                                        -- when the build fails.
                                        local buildOk = theTeam and pcall(function()

                                                setFactionProtectedData(source, "factionMenu", 1, false)

                                                -- [Fix #56] push the type+rank permission list for the Tools tab
                                                pcall(syncFactionPermissions, source)

                                                triggerClientEvent(source, "showFactionMenu", source, motd, memberUsernames, memberRanks, hasPlayerAccessOverFaction(source, factionID) and memberPerks or {}, memberLeaders, memberOnline, memberLastLogin, --[[memberLocation,]] factionRanks,  factionWages, theTeam, note, fnote, vehicleIDs, vehicleModels, vehiclePlates, vehicleLocations, memberOnDuty, towstats, phone, memberPhones, fromShowF, factionID, vehLimit)

                                        end)

                                        if not buildOk then

                                                setFactionProtectedData(source, "factionMenu", 0, false)

                                                triggerClientEvent(source, "hideFactionMenu", source)

                                                outputDebugString("faction-system: showFactionMenuEx failed to build the F3 menu for " .. tostring(getPlayerName(source)), 2)

                                        end

                                end

                        else

                                outputChatBox("انت لست في وظيفة.", source)

                        end

                else

                        triggerClientEvent(source, "hideFactionMenu", source)

                end

        end

end



-- // CALL BACKS FROM CLIENT GUI

function callbackUpdateRanks(ranks, wages)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("غير مسموح ، آسف.", client)

                return

        end

        

        for key, value in ipairs(ranks) do

                ranks[key] = mysql:escape_string(ranks[key])

        end

        

        if (wages) then

                for i = 1, 20 do

                        wages[i] = math.min(2500, math.max(0, tonumber(wages[i]) or 0))

                end

                

                mysql:query_free("UPDATE factions SET wage_1='" .. wages[1] .. "', wage_2='" .. wages[2] .. "', wage_3='" .. wages[3] .. "', wage_4='" .. wages[4] .. "', wage_5='" .. wages[5] .. "', wage_6='" .. wages[6] .. "', wage_7='" .. wages[7] .. "', wage_8='" .. wages[8] .. "', wage_9='" .. wages[9] .. "', wage_10='" .. wages[10] .. "', wage_11='" .. wages[11] .. "', wage_12='" .. wages[12] .. "', wage_13='" .. wages[13] .. "', wage_14='" .. wages[14] .. "', wage_15='" .. wages[15] .. "', wage_16='" .. wages[16] .. "', wage_17='" .. wages[17] .. "', wage_18='" .. wages[18] .. "', wage_19='" .. wages[19] .. "', wage_20='" .. wages[20] .. "' WHERE id='" .. factionID .. "'")

                setFactionProtectedData(theTeam, "wages", wages, false)

        end

        

        mysql:query_free("UPDATE factions SET rank_1='" .. ranks[1] .. "', rank_2='" .. ranks[2] .. "', rank_3='" .. ranks[3] .. "', rank_4='" .. ranks[4] .. "', rank_5='" .. ranks[5] .. "', rank_6='" .. ranks[6] .. "', rank_7='" .. ranks[7] .. "', rank_8='" .. ranks[8] .. "', rank_9='" .. ranks[9] .. "', rank_10='" .. ranks[10] .. "', rank_11='" .. ranks[11] .. "', rank_12='" .. ranks[12] .. "', rank_13='" .. ranks[13] .. "', rank_14='" .. ranks[14] .. "', rank_15='" .. ranks[15] .. "', rank_16='" .. ranks[16] .. "', rank_17='" .. ranks[17] .. "', rank_18='" .. ranks[18] .. "', rank_19='" .. ranks[19] .. "', rank_20='" .. ranks[20] .. "' WHERE id='" .. factionID .. "'")

        setFactionProtectedData(theTeam, "ranks", ranks, false)

        

        -- [Fix #146] rank & wage table edit

        logFactionAction(factionID, getPlayerName(client), "edited the rank & wage tables")

        -- [Fix #111] re-sync the permission list outside of the F3 open path

        pcall(syncFactionPermissions, client)

        -- [Fix #134] `source` is not guaranteed to be the player here

        outputChatBox("تم تحديث معلومات الفصيل بنجاح.", client, 0, 255, 0)

        showFactionMenu(client)

end

addEvent("cguiUpdateRanks", true )

addEventHandler("cguiUpdateRanks", getRootElement(), callbackUpdateRanks)





function callbackRespawnVehicles()

        -- [Fix #134] `client`, not `source`: the cooldown must be read from the
        -- caller's own team (the team is re-read from `client` right below anyway)

        local theTeam = getPlayerTeam(client)

        

        local factionCooldown = getElementData(theTeam, "cooldown")

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("غير مسموح ، آسف.", client)

                return

        end

                

        if not (factionCooldown) then

                for key, value in ipairs(exports.pool:getPoolElementsByType("vehicle")) do

                        local faction = getElementData(value, "faction")

                        if (faction == factionID and not getVehicleOccupant(value, 0) and not getVehicleOccupant(value, 1) and not getVehicleOccupant(value, 2) and not getVehicleOccupant(value, 3) and not getVehicleTowingVehicle(value)) then

                                respawnVehicle(value)

                                setElementInterior(value, getElementData(value, "interior"))

                                setElementDimension(value, getElementData(value, "dimension"))

                                setVehicleLocked(value, true)

                        end

                end

                

                -- Send message to everyone in the faction

                local teamPlayers = getPlayersInTeam(theTeam)

                -- [Fix #134] `client`, not `source`

                local username = getPlayerName(client)

                for k, v in ipairs(teamPlayers) do

                        outputChatBox(username:gsub("_"," ") .. " قام برسبنة السيارات.", v, 255, 194, 14)

                end



                setTimer(resetFactionCooldown, 60000, 1, theTeam)

                setFactionProtectedData(theTeam, "cooldown", true, false)

        else

                -- [Fix #134] `client`, not `source`

                outputChatBox("انتظر دقائق لكي تتمكن من الرسبنة مرة اخرى.", client, 255, 0, 0)

        end

end

addEvent("cguiRespawnVehicles", true )

addEventHandler("cguiRespawnVehicles", getRootElement(), callbackRespawnVehicles)



function resetFactionCooldown(theTeam)

        setFactionProtectedData(theTeam, "cooldown")

end



function callbackRespawnOneVehicle(vehicleID)

        local theTeam = getPlayerTeam(source)

        local theTeamID = getElementData(theTeam, "id")

        local theVehicle = exports.pool:getElement("vehicle", tonumber(vehicleID))

        if not hasPlayerAccessOverFaction(source, theTeamID) then

                outputChatBox("غير مسموح اسف", source, 255, 0, 0)

                return

        end

        if theVehicle then

                local theVehicleID = getElementData(theVehicle, "faction")

                if (theTeamID == theVehicleID and not getVehicleOccupant(theVehicle, 0) and not getVehicleOccupant(theVehicle, 1) and not getVehicleOccupant(theVehicle, 2) and not getVehicleOccupant(theVehicle, 3) and not getVehicleTowingVehicle(theVehicle)) then

                        if isElementAttached(theVehicle) then

                                detachElements(theVehicle)

                        end

                        setFactionProtectedData(theVehicle, 'i:left')

                        setFactionProtectedData(theVehicle, 'i:right')

                        exports.logs:dbLog(source, 6, theVehicle, "FACTIONRESPAWN")

                        respawnVehicle(theVehicle)

                        setElementInterior(theVehicle, getElementData(theVehicle, "interior"))

                        setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

                        setVehicleLocked(theVehicle, true)

                        outputChatBox("Vehicle Respawned.", source, 0, 255, 0)

                        local teamPlayers = getPlayersInTeam(theTeam)

                        local playerName = getPlayerName(source)

                        for k, v in ipairs(teamPlayers) do

                                outputChatBox(playerName:gsub("_"," ") .. " قام بعمل رسبنة للسيارات " .. vehicleID ..".", v, 255, 194, 14)

                        end

                else

                        outputChatBox("هذه السيارة مرسبنة.", source, 255, 0, 0)

                end

        else

                outputChatBox("يرجى تحديد السيارة التي سيتم رسبنتها.", source, 255, 0, 0)

        end

end

addEvent("cguiRespawnOneVehicle", true)

addEventHandler("cguiRespawnOneVehicle", getRootElement(), callbackRespawnOneVehicle)



function callbackUpdateMOTD(motd)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end



        local theTeam = getPlayerTeam(client)

        if (factionID~=-1) then

                if mysql:query_free("UPDATE factions SET motd='" .. tostring(mysql:escape_string(motd)) .. "' WHERE id='" .. factionID .. "'") then

                        outputChatBox(" لقد قمت بتغيير الرسالة بنجاح الى'" .. motd .. "'", client, 0, 255, 0)

                        setFactionProtectedData(theTeam, "motd", motd, false)

                        logFactionAction(factionID, getPlayerName(client), "changed the MOTD") -- [Fix #146]

                else

                        outputChatBox("خطأ.", client, 255, 0, 0)

                end

        end

end

addEvent("cguiUpdateMOTD", true )

addEventHandler("cguiUpdateMOTD", getRootElement(), callbackUpdateMOTD)



function callbackUpdateNote(note)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) or not note then

                outputChatBox("Not allowed, sorry.", client)

                return

        end



        local theTeam = getPlayerTeam(client)

        if (factionID~=-1) then

                if mysql:query_free("UPDATE factions SET note='" .. tostring(mysql:escape_string(note)) .. "' WHERE id='" .. factionID .. "'") then

                        outputChatBox("لقد غيرت ملاحظة قائد فصيلك بنجاح.", client, 0, 255, 0)

                        setFactionProtectedData(theTeam, "note", note, false)

                        logFactionAction(factionID, getPlayerName(client), "changed the leader note") -- [Fix #146]

                else

                        outputChatBox("خطا.", client, 255, 0, 0)

                end

        end

end

addEvent("faction:note", true )

addEventHandler("faction:note", getRootElement(), callbackUpdateNote)



-- [Fix #133] removed the orphan "faction:fnote" event + callbackUpdateFNote:
-- nothing in the codebase ever triggered it (zero senders).



function callbackRemovePlayer(removedPlayerName)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end



        local targetFactionInfo = {getPlayerFaction(removedPlayerName)}

        if targetFactionInfo[2] ~= factionID then

                outputChatBox("لن يحدث , اسف", client)

                return

        end

        

        if mysql:query_free("UPDATE characters SET faction_id='-1', faction_leader='0', faction_rank='1', duty = 0 WHERE charactername='" .. mysql:escape_string(removedPlayerName) .. "'") then

                logFactionAction(factionID, getPlayerName(client), "kicked " .. removedPlayerName) -- [Fix #146]

                local theTeam = getPlayerTeam(client)

                local theTeamName = "None"

                if (theTeam) then

                        theTeamName = getTeamName(theTeam)

                end

                

                local username = getPlayerName(client)

                



                local removedPlayer = getPlayerFromName(removedPlayerName)

                if (removedPlayer) then -- Player is online

                        if (getElementData(client, "factionMenu")==1) then

                                triggerClientEvent(removedPlayer, "hideFactionMenu", getRootElement())

                        end

                        outputChatBox(username:gsub("_"," ").. " قام بطردك من الوظيفة '" .. tostring(theTeamName) .. "'", removedPlayer, 255, 0, 0)

                        setPlayerTeam(removedPlayer, getTeamFromName("Citizen"))

                        setFactionProtectedData(removedPlayer, "faction", -1, false)

                        setFactionProtectedData(removedPlayer, "factionleader", 0, false)

                        -- [Fix #121] this line used to write to undefined `targetPlayer`

                        setFactionProtectedData(removedPlayer, "factionleader", 0, false)

                        triggerEvent("duty:offduty", removedPlayer)

                        --triggerClientEvent(removedPlayer, "updateFactionInfo", removedPlayer, -1, 1)

                end

                

                -- Send message to everyone in the faction

                local teamPlayers = getPlayersInTeam(theTeam)

                for k, v in ipairs(teamPlayers) do

                        if (v ~= removedPlayer) then

                                outputChatBox(username:gsub("_"," ") .. " قام بطرد " .. removedPlayerName:gsub("_", " ") .. " من الوضيفة '" .. tostring(theTeamName) .. "'.", v, 255, 194, 14)

                        end

                end



        else

                outputChatBox("حدث مشكلة في ازالة الاعب " .. removedPlayerName:gsub("_", " ") .. " من الوضيفة يرجى التكلم مع الادارة.", source, 255, 0, 0)

        end

end

addEvent("cguiKickPlayer", true )

addEventHandler("cguiKickPlayer", getRootElement(), callbackRemovePlayer)



function callbackPerkEdit( perkIDTable, playerName)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end

        

        local targetFactionInfo = {getPlayerFaction(playerName)}

        if targetFactionInfo[2] ~= factionID then

                outputChatBox("خطأ.", client)

                return

        end

        

        local jsonPerkIDTable = toJSON( perkIDTable )

        if mysql:query_free("UPDATE `characters` SET `faction_perks`='" .. mysql:escape_string(jsonPerkIDTable) .. "' WHERE `charactername`='" .. mysql:escape_string(playerName) .. "'") then

                outputChatBox(" تم عمل ديوتي لـ "..playerName:gsub("_", " ")..".", client, 255, 0, 0)
                logFactionAction(factionID, getPlayerName(client), "edited the duty perks of " .. playerName) -- [Fix #146]

                local targetPlayer = getPlayerFromName(playerName)

                if targetPlayer then

                        setElementData(targetPlayer, "factionPackages", perkIDTable)

                        outputChatBox(" تم تفعيل خاصية الديوتي لديك من قبل : "..getPlayerName(client):gsub("_", " ") .. ".", targetPlayer, 255, 0, 0)

                end

        end

end

addEvent("faction:perks:edit", true)

addEventHandler("faction:perks:edit", getRootElement(), callbackPerkEdit)





function callbackToggleLeader(playerName, isLeader)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("غير مسموح.", client)

                return

        end

        

        local targetFactionInfo = {getPlayerFaction(playerName)}

        if targetFactionInfo[2] ~= factionID then

                outputChatBox("خطأ.", client)

                return

        end

        

        if (isLeader) then -- Make player a leader

                local username = getPlayerName(client)

                if mysql:query_free("UPDATE characters SET faction_leader='1' WHERE charactername='" .. mysql:escape_string(playerName) .. "'") then



                        -- Send message to everyone in the faction

                        exports.factions:sendNotiToAllFactionMembers(factionID, username:gsub("_", " ") .. " promoted " .. playerName:gsub("_", " ") .. " to leader of your faction '"..getTeamName(theTeam).."'.")

                        logFactionAction(factionID, username, "made " .. playerName .. " leader") -- [Fix #146]

                        

                        local thePlayer = getPlayerFromName(playerName)

                        if(thePlayer) then -- Player is online, tell them

                                setFactionProtectedData(thePlayer, "factionleader", 1, true)

                        end

                else

                        -- [Fix #122] removedPlayerName is undefined here -> playerName
                        outputChatBox("Failed to promote " .. playerName:gsub("_", " ") .. " to faction leader, Contact an admin.", client, 255, 0, 0)

                end

        else

                local username = getPlayerName(client)

                if mysql:query_free("UPDATE characters SET faction_leader='0' WHERE charactername='" .. mysql:escape_string(playerName) .. "'") then

                        

                        local thePlayer = getPlayerFromName(playerName)

                        if(thePlayer) then -- Player is online, tell them

                                if (getElementData(client, "factionMenu")==1) then

                                        triggerClientEvent(thePlayer, "hideFactionMenu", getRootElement())

                                end

                                setFactionProtectedData(thePlayer, "factionleader", 0, true)

                        end

                        

                        -- Send message to everyone in the faction

                        exports.factions:sendNotiToAllFactionMembers(factionID, username:gsub("_", " ") .. " demoted " .. playerName:gsub("_", " ") .. " from leader to member of your faction '"..getTeamName(theTeam).."'.")

                        logFactionAction(factionID, username, "removed the leader flag from " .. playerName) -- [Fix #146]

                else

                        -- [Fix #122] removedPlayerName is undefined here -> playerName

                        outputChatBox("Failed to demote " .. playerName:gsub("_", " ") .. " from faction leader, Contact an admin.", client, 255, 0, 0)

                end

        end

        -- [Fix #111] re-sync the permission list outside of the F3 open path

        pcall(syncFactionPermissions, client)

end

addEvent("cguiToggleLeader", true )

addEventHandler("cguiToggleLeader", getRootElement(), callbackToggleLeader)



function callbackPromotePlayer(playerName, rankNum, oldRank, newRank)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end

        

        local targetFactionInfo = {getPlayerFaction(playerName)}

        if targetFactionInfo[2] ~= factionID then

                outputChatBox("Newp, not going to happen, sorry.", client)

                return

        end

        

        local username = getPlayerName(client)

        if mysql:query_free("UPDATE characters SET faction_rank='" .. rankNum .. "' WHERE charactername='" .. mysql:escape_string(playerName) .. "'") then

                local thePlayer = getPlayerFromName(playerName)

                if(thePlayer) then -- Player is online, set his rank

                        setFactionProtectedData(thePlayer, "factionrank", rankNum, false)

                end

                

                -- Send message to everyone in the faction

                exports.factions:sendNotiToAllFactionMembers(factionID, playerName:gsub("_", " ") .. " was promoted from '" .. oldRank .. "' to '" .. newRank .. "' by "..username:gsub("_", " ").." of '"..getTeamName(theTeam).."'")

                logFactionAction(factionID, username, "promoted " .. playerName .. " to rank " .. tostring(rankNum)) -- [Fix #146]

        else

                -- [Fix #122] removedPlayerName is undefined here -> playerName

                outputChatBox("Failed to promote " .. playerName:gsub("_", " ") .. " in the faction, Contact an admin.", client, 255, 0, 0)

        end

        -- [Fix #111] re-sync the permission list outside of the F3 open path

        pcall(syncFactionPermissions, client)

end

addEvent("cguiPromotePlayer", true )

addEventHandler("cguiPromotePlayer", getRootElement(), callbackPromotePlayer)



function callbackDemotePlayer(playerName, rankNum, oldRank, newRank)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end

        

        local targetFactionInfo = {getPlayerFaction(playerName)}

        if targetFactionInfo[2] ~= factionID then

                outputChatBox("Newp, not going to happen, sorry.", client)

                return

        end

        

        local username = getPlayerName(client)

        local safename = mysql:escape_string(playerName)

        

        if mysql:query_free("UPDATE characters SET faction_rank='" .. rankNum .. "' WHERE charactername='" .. safename .. "'") then

                local thePlayer = getPlayerFromName(playerName)

                if(thePlayer) then -- Player is online, tell them

                        setFactionProtectedData(thePlayer, "factionrank", rankNum, false)

                end

                

                -- Send message to everyone in the faction

                exports.factions:sendNotiToAllFactionMembers(factionID, playerName:gsub("_", " ") .. " was demoted from '" .. oldRank .. "' to '" .. newRank .. "' by "..username:gsub("_", " ").." of '"..getTeamName(theTeam).."'")

                logFactionAction(factionID, username, "demoted " .. playerName .. " to rank " .. tostring(rankNum)) -- [Fix #146]

        else

                -- [Fix #122] removedPlayerName is undefined here -> playerName

                outputChatBox("Failed to demote " .. playerName .. " in the faction, Contact an admin.", client, 255, 0, 0)

        end

        -- [Fix #111] re-sync the permission list outside of the F3 open path

        pcall(syncFactionPermissions, client)

end

addEvent("cguiDemotePlayer", true )

addEventHandler("cguiDemotePlayer", getRootElement(), callbackDemotePlayer)



function callbackQuitFaction()

        local username = getPlayerName(client)

        local safename = mysql:escape_string(username)

        local theTeam = getPlayerTeam(client)

        local theTeamName = getTeamName(theTeam)



        if theTeamName == "Los Santos Bus & Cab" then

                executeCommandHandler("quitjob", client)        

        elseif mysql:query_free("UPDATE characters SET faction_id='-1', faction_leader='0', duty = 0, faction_perks='{}' WHERE charactername='" .. safename .. "'") then

                outputChatBox("You quit the faction '" .. theTeamName .. "'.", client)

                

                local newTeam = getTeamFromName("Citizen")

                setPlayerTeam(client, newTeam)

                setFactionProtectedData(client, "faction", -1, false)

                setFactionProtectedData(client, "factionrank", 1, false)

                setFactionProtectedData(client, "factionleader", 0, false)

                setFactionProtectedData(client, "factionphone", nil, false)

                setFactionProtectedData(client, "factionPackages", {}, false)

                --triggerClientEvent(client, "updateFactionInfo", client, -1, 1)

                triggerEvent("duty:offduty", client)

                

                -- Send message to everyone in the faction

                local factionID = getElementData(theTeam, "id")

                exports.factions:sendNotiToAllFactionMembers(factionID, username:gsub("_", " ") .. " left your faction '" .. theTeamName .. "'.")
                logFactionAction(factionID, username, "quit the faction '" .. theTeamName .. "'") -- [Fix #146]

        else

                outputChatBox("Failed to quit the faction, Contact an admin.", client, 255, 0, 0)

        end

end

addEvent("cguiQuitFaction", true )

addEventHandler("cguiQuitFaction", getRootElement(), callbackQuitFaction)



function callbackInvitePlayer(invitedPlayer)

        local theTeam = getPlayerTeam(client)

        local factionID = getElementData(theTeam, "id")

        if not hasPlayerAccessOverFaction(client, factionID) then

                outputChatBox("Not allowed, sorry.", client)

                return

        end

        

        

        -- [Fix #160] faction blacklist: the server accept point refuses a blocked
        -- character even when a leader is the one adding him (task A3).
        local blRow = getFactionBlacklistHitForPlayer(factionID, invitedPlayer)
        if blRow then
                outputChatBox("تم رفض اضافة هذا اللاعب لوجوده في القائمة السوداء للفاكشن. السبب: " .. tostring(blRow.reason), client, 255, 0, 0)
                outputChatBox("لا يمكنك الانضمام الى هذا الفاكشن لوجودك في القائمة السوداء. السبب: " .. tostring(blRow.reason), invitedPlayer, 255, 0, 0)
                logFactionAction(factionID, getPlayerName(client), "tried to invite blacklisted " .. getPlayerName(invitedPlayer) .. " (blocked: " .. tostring(blRow.reason) .. ")") -- [Fix #146]
                return
        end

        local invitedPlayerNick = getPlayerName(invitedPlayer)

        local safename = mysql:escape_string(invitedPlayerNick)

        

        local targetTeam = getPlayerTeam(invitedPlayer)

        if (targetTeam~=nil) and (getTeamName(targetTeam)~="Citizen") then

                outputChatBox("الاعب موجود بالفاكشن بالفعل.", client, 255, 0, 0)

                return

        end

        

        if mysql:query_free("UPDATE characters SET faction_leader = 0, faction_id = " .. factionID .. ", faction_rank = 1 WHERE charactername='" .. safename .. "'") then

                local theTeam = getPlayerTeam(client)

                local theTeamName = getTeamName(theTeam)

                

                local targetTeam = getPlayerTeam(invitedPlayer)

                if (targetTeam~=nil) and (getTeamName(targetTeam)~="Citizen") then

                        outputChatBox("Player is already in a faction.", client, 255, 0, 0)

                else

                        setPlayerTeam(invitedPlayer, theTeam)

                        setFactionProtectedData(invitedPlayer, "faction", factionID, false)

                        outputChatBox("Player " .. invitedPlayerNick:gsub("_", " ") .. " الان عضو بالفاكشن '" .. tostring(theTeamName) .. "'.", client, 0, 255, 0)
                        logFactionAction(factionID, getPlayerName(client), "invited " .. invitedPlayerNick) -- [Fix #146]

                        exports.factions:sendNotiToAllFactionMembers(factionID, invitedPlayerNick:gsub("_", " ") .. " انضم كعضو جديد في فصيلك '" .. tostring(theTeamName) .. "'.")                              

                        if      (invitedPlayer) then

                                triggerEvent("onPlayerJoinFaction", invitedPlayer, theTeam)

                                setFactionProtectedData(invitedPlayer, "factionrank", 1, false)

                                -- [Fix #123] this used to wipe the INVITER's phone

                                setFactionProtectedData(invitedPlayer, "factionphone", nil, false)

                                outputChatBox("تم تعيينك على فصيل '" .. tostring(theTeamName) .. "'.", invitedPlayer, 255, 194, 14)

                        end

                end

        else

                outputChatBox("اللاعب موجود بالفعل في فصيل.", client, 255, 0, 0)

        end

end

addEvent("cguiInvitePlayer", true )

addEventHandler("cguiInvitePlayer", getRootElement(), callbackInvitePlayer)



-- [Fix #149] this is what releases the F3 lock (showFactionMenuEx sets
-- factionMenu=1 only on a successful build, and the `~= 1` gate blocks every
-- later open): the client must be able to clear it whenever it hides the menu.

function hideFactionMenu()

        setFactionProtectedData(client, "factionMenu", 0, false)

end

addEvent("factionmenu:hide", true)

addEventHandler("factionmenu:hide", getRootElement(), hideFactionMenu)



function getFactionFinance(factionID)

        if not factionID then factionID = getElementData(client, "faction") end



        if hasPlayerAccessOverFaction(client, factionID) then

                local bankThisWeek = {}

                local bankPrevWeek = {}

                local transactions = {}



                -- [Fix #138] YEARWEEK instead of WEEKOFYEAR: WEEKOFYEAR restarts at 1
                -- every January, so week 1 of the new year collided with week 1 of the
                -- old one. YEARWEEK buckets a whole year+week, and prevWeek uses the
                -- exact same -1 hour shift, 7 days back, so the historical rows and the
                -- current/previous week always land in the same buckets.
                local query = mysql:query("SELECT w.*, a.charactername as characterfrom, b.charactername as characterto,w.`time` - INTERVAL 1 hour as 'newtime', YEARWEEK(w.`time` - INTERVAL 1 hour) as 'week', YEARWEEK(CURDATE() - INTERVAL 1 hour) as 'currentWeek', YEARWEEK(CURDATE() - INTERVAL 7 DAY - INTERVAL 1 hour) as 'prevWeek' FROM wiretransfers w LEFT JOIN characters a ON a.id = `from` LEFT JOIN characters b ON b.id = `to` WHERE ( `from` = '" .. mysql:escape_string(tostring(-factionID)) .. "' OR `to` = '" .. mysql:escape_string(tostring(-factionID)) .. "' ) ORDER BY id DESC")

                

                --outputConsole("SELECT w.*, a.charactername as characterfrom, b.charactername as characterto,w.`time` - INTERVAL 1 hour as 'newtime', WEEKOFYEAR(w.`time` - INTERVAL 1 hour) as 'week', WEEKOFYEAR(CURDATE() - INTERVAL 1 hour) as 'currentWeek' FROM wiretransfers w LEFT JOIN characters a ON a.id = `from` LEFT JOIN characters b ON b.id = `to` WHERE ( `from` = " .. -factionID .. " OR `to` = " .. -factionID .. " ) ORDER BY id DESC")



                local mostRecentWeek = 0

                local currentWeek = 0

                -- [Fix #138] YEARWEEK bucket of "last week", filled from the query
                local prevWeek = 0

                if query then

                        while true do

                                row = mysql:fetch_assoc(query)

                                if not row then break end

                                

                                local id = tonumber(row["id"])

                                local amount = tonumber(row["amount"])

                                local time = row["newtime"]

                                local week = tonumber(row["week"])

                                currentWeek = tonumber(row["currentWeek"])

                                -- [Fix #138] taken from the query so the bucket stays
                                -- correct over the year boundary
                                prevWeek = tonumber(row["prevWeek"]) or 0

                                if week > mostRecentWeek then mostRecentWeek = week end

                                if not transactions[week] then transactions[week] = {} end

                                local txType = tonumber(row["type"])

                                local reason = row["reason"]

                                if reason == nil then

                                        reason = ""

                                end

                                

                                local from, to = "-", "-"

                                if type(row["characterfrom"]) == "string" then
                                        from = row["characterfrom"]:gsub("_", " ")
                                elseif tonumber(row["from"]) then
                                        num = tonumber(row["from"]) 

                                        if num < 0 then

                                                from = getTeamName(exports.pool:getElement("team", -num)) or "-"

                                        elseif num == 0 and ( txType == 6 or txType == 7 ) then

                                                from = "Government"

                                        end

                                end

                                if type(row["characterto"]) == "string" then
                                        to = row["characterto"]:gsub("_", " ")
                                elseif tonumber(row["to"]) and tonumber(row["to"]) < 0 then
                                        to = getTeamName(exports.pool:getElement("team", -tonumber(row["to"])))

                                end

                                

                                if tostring(row["from"]) == tostring(-factionID) and amount > 0 then

                                        amount = amount - amount - amount

                                end



                                table.insert(transactions[week], { id = id, amount = amount, time = time, type = txType, from = from, to = to, reason = reason, week = week })

                                --outputDebugString("transactions["..tostring(week).."]="..tostring(#transactions[week]))

                        end

                        mysql:free_result(query)



                        --outputDebugString("mostRecentWeek="..tostring(mostRecentWeek))

                        bankThisWeek = transactions[currentWeek] or {}

                        -- [Fix #138] the previous YEARWEEK bucket (currentWeek-1 would
                        -- produce 202600 instead of the previous year's 202552/202553)
                        bankPrevWeek = transactions[prevWeek] or {}



                        --outputDebugString("server: bankThisWeek="..tostring(#bankThisWeek).." bankPrevWeek="..tostring(#bankPrevWeek))



                        local faction = getPlayerTeam(client)

                        local bankmoney = exports.global:getMoney(faction)



                        local vehicles = {}

                        local result = mysql:query("SELECT vehicle_shop_id FROM vehicles WHERE faction='" .. mysql:escape_string(tostring(factionID)) .. "' AND deleted=0 AND chopped=0")

                        if result then

                                while true do

                                        local row = mysql:fetch_assoc(result)

                                        if not row then break end

                                        local vehicleShopID = tonumber(row["vehicle_shop_id"])

                                        -- [Fix #137] vehicle_shop_id can be NULL: tonumber(nil) is nil
                                        -- and `nil > 0` raises "attempt to compare nil with number"
                                        if vehicleShopID and vehicleShopID > 0 then

                                                table.insert(vehicles, vehicleShopID)

                                        end

                                end

                                mysql:free_result(result)

                        end



                        local vehiclesvalue = 0

                        if not vehPrice then vehPrice = {} end

                        for k,v in ipairs(vehicles) do

                                if vehPrice[v] then

                                        local price = tonumber(vehPrice[v]) or 0

                                        vehiclesvalue = vehiclesvalue + price

                                else

                                        local result2 = mysql:query("SELECT vehprice FROM vehicles_shop WHERE id='"..mysql:escape_string(tostring(v)).."'")

                                        if result2 then

                                                while true do

                                                        local row = mysql:fetch_assoc(result2)

                                                        if not row then break end

                                                        local price = tonumber(row["vehprice"]) or 0

                                                        vehPrice[v] = price

                                                        vehiclesvalue = vehiclesvalue + price

                                                end

                                                mysql:free_result(result2)

                                                -- [Fix #137] cache misses too (price 0), otherwise a
                                                -- shop id with no vehicles_shop row is re-queried on
                                                -- every finance render
                                                if vehPrice[v] == nil then vehPrice[v] = 0 end

                                        end

                                end

                        end



                        -- [Fix #135] 6th fillFinance argument: the faction's total
                        -- property value. Faction interiors are interiors rows with
                        -- faction=<id> (owner is reset to -1 when a faction takes a
                        -- property) and deleted='0'; their value is SUM(cost).
                        local propertiesvalue = 0

                        local propResult = mysql:query("SELECT COALESCE(SUM(cost),0) AS total FROM interiors WHERE faction='" .. mysql:escape_string(tostring(factionID)) .. "' AND deleted='0'")

                        if propResult then

                                local propRow = mysql:fetch_assoc(propResult)

                                if propRow then

                                        propertiesvalue = tonumber(propRow.total) or 0

                                end

                                mysql:free_result(propResult)

                        end

                        triggerClientEvent(client, "factionmenu:fillFinance", getResourceRootElement(), factionID, bankThisWeek, bankPrevWeek, bankmoney, vehiclesvalue, propertiesvalue)

                else

                        outputDebugString("Mysql error @ tellTransfers", 2)

                end

        end

end

addEvent("factionmenu:getFinance", true)

addEventHandler("factionmenu:getFinance", getResourceRootElement(), getFactionFinance)





-- [Fix #133] removed the orphan "factionmenu:setphone" event + handler: nothing
-- in the codebase ever triggered it (zero senders).





function isLeapYear(year)

        return year%4==0 and (year%100~=0 or year%400==0)

end

local lastDayOfMonth = {31,28,31,30,31,30,31,31,30,31,30,31}

function fromDatetime(string)

        local split1 = exports.global:split(string, " ")

        local date = split1[1]

        local time = split1[2]



        local datesplit = exports.global:split(date, "-")

        local year = tonumber(datesplit[1])

        local month = tonumber(datesplit[2])

        local day = tonumber(datesplit[3])



        local timesplit = exports.global:split(date, ":")

        local hour = tonumber(timesplit[1])

        local minute = tonumber(timesplit[2])

        local second = tonumber(timesplit[3])



        --calculate yearday

        local prevdays = 0

        local addmonth = 1

        while true do

                if addmonth >= month then break end

                if addmonth == 2 and isLeapYear(year) then

                        prevdays = prevdays + lastDayOfMonth[addmonth] + 1

                else

                        prevdays = prevdays + lastDayOfMonth[addmonth]

                end

                addmonth = addmonth + 1

        end

        local yearday = prevdays + day



        local time = { year = year, month = month, day = day, hour = hour, minute = minute, second = second, yearday = yearday }

        return time

end

function getWeekNumFromYearDay(yearday)

        local weekNum = math.floor(yearday / 7)

        return weekNum

end



-- Chaos's Custom Duty Stuff for OwlGaming > Script Stealers go away



addEvent("fetchDutyInfo", true)

addEventHandler("fetchDutyInfo", resourceRoot, function(factionID)

        if not factionID then factionID = getElementData(client, "faction") end

        -- [Fix #104] only store DutyGUI[client] and push duty data when the
        -- client belongs to the requested faction, otherwise refreshClient()
        -- keeps streaming another faction's duty data to him.
        local verifiedFactionID = fsVerifyCallerFaction(factionID, false)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID



        local elementInfo = getElementData(resourceRoot, "DutyGUI")

        elementInfo[client] = factionID

        setElementData(resourceRoot, "DutyGUI", elementInfo)



        triggerClientEvent(client, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID)

end)



addEvent("Duty:Grab", true)

addEventHandler("Duty:Grab", resourceRoot, function(factionID)

        if not factionID then factionID = getElementData(client, "faction") end

        -- [Fix #104] same membership gate as fetchDutyInfo
        local verifiedFactionID = fsVerifyCallerFaction(factionID, false)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID



        local t = getAllowList(factionID)



        triggerClientEvent(client, "gotAllow", resourceRoot, t)

end)



addEvent("Duty:GetPackages", true)

addEventHandler("Duty:GetPackages", resourceRoot, function(factionID)

        factionID = tonumber(factionID)

        -- [Fix #104] same membership gate as fetchDutyInfo
        local verifiedFactionID = fsVerifyCallerFaction(factionID, false)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID



        triggerClientEvent(client, "Duty:GotPackages", resourceRoot, custom[factionID])



        end)



-- [Fix #140] targetPlayer is now an explicit parameter: the acting player is
-- passed in by every Duty write handler instead of relying on the implicit
-- `client` of whatever event handler happened to call this.

function refreshClient(targetPlayer, message, factionID, dontSendToClient)

        if not isElement(targetPlayer) or getElementType(targetPlayer) ~= "player" then return end

        factionID = tonumber(factionID)

        if not factionID then return end

        for k,v in pairs(getElementData(resourceRoot, "DutyGUI") or {}) do

                if dontSendToClient then

                        if v == factionID and k~=dontSendToClient then

                                triggerClientEvent(k, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID, message)

                        end

                else

                        if v == factionID then

                                triggerClientEvent(k, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID, message)

                        end

                end

        end

        local resource = getResourceRootElement(getResourceFromName("duty"))

        if resource then

                setElementData(resource, "factionDuty", custom)

                setElementData(resource, "factionLocations", locations)

        end

end



function disconnectThem()

        local t = getElementData(resourceRoot, "DutyGUI") 

        t[source] = nil

        setElementData(resourceRoot, "DutyGUI", t)

end

addEventHandler("onPlayerQuit", getRootElement(), disconnectThem)



function addDuty(dutyItems, finalLocations, dutyNewSkins, name, factionID, dutyID)

        local dutyItems = dutyItems or {}

        local finalLocations = finalLocations or {}

        local dutyNewSkins = dutyNewSkins or {}

        -- [Fix #103] the client supplied factionID is never trusted: write to the
        -- caller's OWN faction only, and only with hasPlayerAccessOverFaction().
        local verifiedFactionID = fsVerifyCallerFaction(factionID, true)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID

        -- [Fix #140] nil guard: a faction without loaded duty rows has no table
        if not custom[tonumber(factionID)] then custom[tonumber(factionID)] = {} end

        if dutyID == 0 then

                local index = getElementData(resourceRoot, "maxcindex")+1

                mysql:query_free("INSERT INTO duty_custom SET id="..index..", factionID="..mysql:escape_string(factionID)..", name='"..mysql:escape_string(name).."', skins='"..mysql:escape_string(toJSON(dutyNewSkins)).."', locations='"..mysql:escape_string(toJSON(finalLocations)).."', items='"..mysql:escape_string(toJSON(dutyItems)).."'")

                setElementData(resourceRoot, "maxcindex", index)

                custom[tonumber(factionID)][index] = { index, name, dutyNewSkins, finalLocations, dutyItems }

                refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": Added duty '"..name.."'.", factionID, false)

                exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Added duty "..name.." Database ID #"..index)

        else

                mysql:query_free("UPDATE duty_custom SET name='"..mysql:escape_string(name).."', skins='"..mysql:escape_string(toJSON(dutyNewSkins)).."', locations='"..mysql:escape_string(toJSON(finalLocations)).."', items='"..mysql:escape_string(toJSON(dutyItems)).."' WHERE id="..dutyID)

                table.remove(custom[tonumber(factionID)], dutyID)

                custom[tonumber(factionID)][dutyID] = { dutyID, name, dutyNewSkins, finalLocations, dutyItems }

                refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": Revised duty ID #"..dutyID..".", factionID, false)

                exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Revised duty "..name.." Database ID #"..dutyID)

        end

end

addEvent("Duty:AddDuty", true)

addEventHandler("Duty:AddDuty", resourceRoot, addDuty)



function addLocation(x, y, z, r, i, d, name, factionID, index)

        -- [Fix #103] the client supplied factionID is never trusted: write to the
        -- caller's OWN faction only, and only with hasPlayerAccessOverFaction().
        local verifiedFactionID = fsVerifyCallerFaction(factionID, true)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID

        -- [Fix #140] nil guard: a faction without loaded duty locations has no table
        if not locations[tonumber(factionID)] then locations[tonumber(factionID)] = {} end

        local interiorElement = exports.pool:getElement("interior", d) or d == 0

        if interiorElement then

                local interiorF = 0

                if isElement(interiorElement) then

                        interiorStatus = getElementData(interiorElement, "status")

                        interiorF = interiorStatus[7]

                end



                if tonumber(interiorF) == tonumber(factionID) or d == 0 then

                        if not index then -- Index is used if the event is from a edit

                                local newIndex = getElementData(resourceRoot, "maxlindex")+1

                                mysql:query_free("INSERT INTO duty_locations SET id="..newIndex..", factionID="..mysql:escape_string(factionID)..", name='".. mysql:escape_string(name) .."', x="..mysql:escape_string(x)..", y="..mysql:escape_string(y)..", z="..mysql:escape_string(z)..", radius="..mysql:escape_string(r)..", dimension="..mysql:escape_string(d)..", interior="..mysql:escape_string(i))

                                setElementData(resourceRoot, "maxlindex", newIndex)

                                exports.duty:createDutyColShape(x, y, z, r, i, d, factionID, newIndex)

                                locations[tonumber(factionID)][newIndex] = { newIndex, name, x, y, z, r, d, i, nil, nil }

                                refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": Added location '"..name.."'.", factionID, false)

                                exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Added location, Name:"..name.." Database ID:"..newIndex.." x:"..x.." y:"..y.." z:"..z.." radius:"..r.." interior:"..i.." dimension:"..d)

                        else

                                mysql:query_free("UPDATE duty_locations SET name='".. mysql:escape_string(name) .."', x="..mysql:escape_string(x)..", y="..mysql:escape_string(y)..", z="..mysql:escape_string(z)..", radius="..mysql:escape_string(r)..", dimension="..mysql:escape_string(d)..", interior="..mysql:escape_string(i).." WHERE id="..index)

                                table.remove(locations[factionID], index)

                                exports.duty:destroyDutyColShape(factionID, index)

                                exports.duty:createDutyColShape(x, y, z, r, i, d, factionID, index)

                                locations[tonumber(factionID)][index] = { index, name, x, y, z, r, d, i, nil, nil }

                                refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": Revised location ID #"..index..".", factionID, false)

                                exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Revised location ID #"..index.." x:"..x.." y:"..y.." z:"..z.." radius:"..r.." interior:"..i.." dimension:"..d)

                        end

                else

                        outputChatBox("The interior you entered must be owned by the faction to be added as a duty location.", client, 255, 0, 0)

                end

        else

                outputChatBox("Server could not find the interior you entered!", client, 255, 0, 0)

        end

end

addEvent("Duty:AddLocation", true)

addEventHandler("Duty:AddLocation", resourceRoot, addLocation)



function addVehicle(vehicleID, factionID)

        -- [Fix #103] the client supplied factionID is never trusted: write to the
        -- caller's OWN faction only, and only with hasPlayerAccessOverFaction().
        local verifiedFactionID = fsVerifyCallerFaction(factionID, true)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID

        -- [Fix #140] nil guard: a faction without loaded duty locations has no table
        if not locations[tonumber(factionID)] then locations[tonumber(factionID)] = {} end

        local element = exports.pool:getElement("vehicle", vehicleID)

        if element then

                -- [Fix #103] numeric compare: factionID is the verified own faction
                if tonumber(getElementData(element, "faction")) == tonumber(factionID) then

                    local newIndex = getElementData(resourceRoot, "maxlindex")+1

                        mysql:query_free("INSERT INTO duty_locations SET id="..newIndex..", factionID="..mysql:escape_string(factionID)..", name='VEHICLE', vehicleid="..mysql:escape_string(vehicleID)..", model="..getElementModel(element))

                        setElementData(resourceRoot, "maxlindex", newIndex)

                        locations[tonumber(factionID)][newIndex] = { newIndex, "VEHICLE", nil, nil, nil, nil, nil, nil, tonumber(vehicleID), getElementModel(element) }

                        refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": Added vehicle #"..vehicleID..".", factionID, false)

                        exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Added Vehicle #"..vehicleID.." Database ID:"..newIndex)

                        --outputChatBox("Added vehicle "..vehicleID.." successfully.", client, 0, 255, 0)

                else

                        outputChatBox("You can only add faction vehicles as duty locations.", client, 255, 0, 0)

                end

        else

                outputChatBox("Error finding your vehicle, did you type the ID in right?", client, 255, 0, 0)

        end

end

addEvent("Duty:AddVehicle", true)

addEventHandler("Duty:AddVehicle", resourceRoot, addVehicle)



function removeLocation(removeID, factionID)

        -- [Fix #103] the client supplied factionID is never trusted: write to the
        -- caller's OWN faction only, and only with hasPlayerAccessOverFaction().
        local verifiedFactionID = fsVerifyCallerFaction(factionID, true)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID

        -- [Fix #140] nil guard: a faction without loaded duty locations has no table
        if not locations[tonumber(factionID)] then locations[tonumber(factionID)] = {} end

        locations[tonumber(factionID)][tonumber(removeID)] = nil

        exports.duty:destroyDutyColShape(factionID, removeID)

        mysql:query_free("DELETE FROM duty_locations WHERE id="..removeID)

        exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Removed Location #"..removeID)

        --outputChatBox("Duty Location removed!", client, 0, 255, 0)



        refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": removed location "..removeID..".", factionID, client)

end

addEvent("Duty:RemoveLocation", true)

addEventHandler("Duty:RemoveLocation", resourceRoot, removeLocation)



function removeDuty(removeID, factionID)

        -- [Fix #103] the client supplied factionID is never trusted: write to the
        -- caller's OWN faction only, and only with hasPlayerAccessOverFaction().
        local verifiedFactionID = fsVerifyCallerFaction(factionID, true)

        if not verifiedFactionID then return end

        factionID = verifiedFactionID

        -- [Fix #140] nil guard: a faction without loaded duty rows has no table
        if not custom[tonumber(factionID)] then custom[tonumber(factionID)] = {} end

        custom[tonumber(factionID)][tonumber(removeID)] = nil

        mysql:query_free("DELETE FROM duty_custom WHERE id="..removeID)

        exports.logs:dbLog(client, 35, "fa"..tostring(factionID), "Removed duty #"..removeID)

        --outputChatBox("Custom Duty Loadout removed!", client, 0, 255, 0)



        refreshClient(client, "> "..getPlayerName(client):gsub("_", " ")..": removed duty "..removeID..".", factionID, client)

end

addEvent("Duty:RemoveDuty", true)

addEventHandler("Duty:RemoveDuty", resourceRoot, removeDuty)

-- [Fix #102] Removed both "sacksupporter" command backdoors (shared global
-- sackSupporter handler that ran "UPDATE accounts SET Admin=4" for hardcoded
-- usernames with no permission check whatsoever).



