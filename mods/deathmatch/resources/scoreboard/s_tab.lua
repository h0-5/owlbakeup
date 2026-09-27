--

-- vgScoreboard v1.0

-- Server-side script.

-- By Alberto "ryden" Alonso

--





local scoreboardDummy



--[[

* onResourceStart

Handles the resource start event to create a dummy entity with information about the server.

--]]

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()), function ()

        scoreboardDummy = createElement ( "scoreboard" )

        setElementData ( scoreboardDummy, "serverName", "Direct-Hosting" )

        setElementData ( scoreboardDummy, "maxPlayers", getMaxPlayers () )

        setElementData ( scoreboardDummy, "allow", true )

        

        --[[ Uncomment to test with dummies ]]--

        --[[

        for k=70,270 do

                local dummy = createElement ( "playerDummy" )

                setElementData ( dummy, "playerid", k )

                setElementData ( dummy, "name", "dummy" .. tostring(k), false )

                setElementData ( dummy, "ping", math.random ( 1, 300 ) )

                setElementData ( dummy, "color", { math.random(0,255), math.random(0,255), math.random(0,255) } )

        end

        --]]

end, false )



--[[

* onResourceStop

Delete the dummy created on resource start.

--]]

addEventHandler ( "onResourceStop", getResourceRootElement(getThisResource()), function ()

        if scoreboardDummy then

                destroyElement ( scoreboardDummy )

        end

end, false )


-- highest player count sync: tracks the peak online count and pushes it to
-- all clients every 30 seconds (replaces the original play-time/public based sync).

local highestPlayerCount = 0

setTimer ( function ()

        local current = getPlayerCount ()

        if current > highestPlayerCount then

                highestPlayerCount = current

        end

        triggerClientEvent ( root, "scoreboard:highestPlayerCount:sync", root, highestPlayerCount )

end, 30000, 0 )

-- ============================================================================
-- [Vortex] rank-data hardening
--
-- The client reads rank:name / rank:color elementData pushed by the staff
-- bridge (admin-system). If that ever misses (login-panel hook skipped,
-- resource restarted mid-session, stale migration) the board used to fall
-- back to the legacy "Admin <level>" text. This poll re-applies the ladder
-- through the exported bridge API for anyone whose data is missing, so the
-- real rank title + color always land.
-- ============================================================================

local function reapplyMissingRanks ( )
        local adminSys = getResourceFromName ( "admin-system" )
        if not adminSys or getResourceState ( adminSys ) ~= "running" then
                return
        end

        for _, player in ipairs ( getElementsByType ( "player" ) ) do
                -- only accounts that are logged in AND look like staff somehow
                if isElement ( player ) and tonumber ( getElementData ( player, "account:id" ) ) then
                        local hasName = getElementData ( player, "rank:name" )
                        local level   = tonumber ( getElementData ( player, "admin_level" ) ) or 0
                        local hasIdx  = tonumber ( getElementData ( player, "rank:index" ) )
                        if not hasName and ( level > 0 or hasIdx ) then
                                pcall ( function ( )
                                        exports [ "admin-system" ]:refreshPlayerRank ( player )
                                end )
                        end
                end
        end
end

setTimer ( reapplyMissingRanks, 60000, 0 )
setTimer ( reapplyMissingRanks, 10000, 1 ) -- shortly after resource start

--------------------------------------------------------------------------------
-- Fix #24 (user): FIXED MOD ID per account
--   * every account gets a permanent sequential id the first time it logs in
--   * the id survives reconnects (stored mod_ids.json inside this resource)
--   * the scoreboard ID column shows it instead of the session playerid
--   * /checkid [name|id]  (staff): look up who owns a mod id / name
--   * /setid <name|id> <newid>  (staff): reassign an account's mod id
--------------------------------------------------------------------------------
local modIds = {}          -- [username] = mod id
local nextModId = 1
local idsFile = "mod_ids.json"

local function loadModIds()
        if fileExists(idsFile) then
                local f = fileOpen(idsFile, true)
                if f then
                        local data = ""
                        while not fileIsEOF(f) do
                                data = data .. fileRead(f, 1024)
                        end
                        fileClose(f)
                        local t = fromJSON(data)
                        if type(t) == "table" then
                                modIds = t.ids or {}
                                nextModId = tonumber(t.next) or 1
                        end
                end
        end
end

local function saveModIds()
        local f = fileCreate(idsFile)
        if f then
                fileWrite(f, toJSON({ ids = modIds, next = nextModId }))
                fileClose(f)
        end
end

local function getOrCreateModId(accountName)
        if not accountName or accountName == "" then return nil end
        accountName = tostring(accountName)
        local id = modIds[accountName]
        if not id then
                id = nextModId
                nextModId = nextModId + 1
                modIds[accountName] = id
                saveModIds()
        end
        return id
end

local function isStaffPlayer(p)
        return (tonumber(getElementData(p, "admin_level")) or 0) > 0
                or (tonumber(getElementData(p, "account:gmlevel")) or 0) > 0
end

local function findPlayerByNamePart(part)
        part = string.lower(tostring(part or ""))
        for _, p in ipairs(getElementsByType("player")) do
                local user = tostring(getElementData(p, "account:username") or "")
                if user ~= "" and string.find(string.lower(user), part, 1, true) then
                        return p
                end
        end
        return nil
end

addEventHandler("onResourceStart", resourceRoot, function()
        loadModIds()
end)

addEventHandler("onPlayerLogin", root, function()
        local id = getOrCreateModId(getElementData(source, "account:username"))
        if id then
                setElementData(source, "mod:id", id)
        end
end)

-- staff: /checkid <part-of-name | mod id>  (no args = your own id)
addCommandHandler("checkid", function(player, cmd, query)
        if not isStaffPlayer(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 80, 80)
                return
        end
        if not query or query == "" then
                local myId = tonumber(getElementData(player, "mod:id")) or "-"
                outputChatBox("Your mod id: " .. tostring(myId)
                        .. " | account: " .. tostring(getElementData(player, "account:username") or "?"),
                        player, 120, 220, 120)
                return
        end
        local found = {}
        local q = string.lower(query)
        for user, id in pairs(modIds) do
                if string.find(string.lower(user), q, 1, true) or tostring(id) == q then
                        local online = findPlayerByNamePart(user)
                        found[#found + 1] = string.format("%s => mod id %d%s", user, id,
                                online and " (online)" or " (offline)")
                end
        end
        if #found == 0 then
                outputChatBox("No account matches '" .. query .. "'.", player, 255, 140, 60)
        else
                for _, line in ipairs(found) do
                        outputChatBox("[CHECKID] " .. line, player, 140, 200, 255)
                end
        end
end, false, false)

-- staff: /setid <part-of-name | old mod id> <new id>
addCommandHandler("setid", function(player, cmd, query, newId)
        if not isStaffPlayer(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 80, 80)
                return
        end
        newId = tonumber(newId)
        if not query or query == "" or not newId or newId < 1 then
                outputChatBox("USAGE: /setid <account | current mod id> <new id>", player, 255, 195, 14)
                return
        end
        local targetUser = nil
        local q = string.lower(query)
        for user, id in pairs(modIds) do
                if string.find(string.lower(user), q, 1, true) or tostring(id) == q then
                        targetUser = user
                        break
                end
        end
        if not targetUser then
                outputChatBox("No account matches '" .. query .. "'.", player, 255, 140, 60)
                return
        end
        for user, id in pairs(modIds) do
                if id == newId and user ~= targetUser then
                        outputChatBox("Mod id " .. newId .. " already belongs to " .. user .. ".", player, 255, 80, 80)
                        return
                end
        end
        modIds[targetUser] = newId
        if newId >= nextModId then
                nextModId = newId + 1
        end
        saveModIds()
        local online = findPlayerByNamePart(targetUser)
        if online then
                setElementData(online, "mod:id", newId)
        end
        outputChatBox("[SETID] " .. targetUser .. " now has mod id " .. newId .. ".", player, 120, 220, 120)
end, false, false)
