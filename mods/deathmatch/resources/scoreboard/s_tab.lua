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

-- ============================================================================
-- [Fix #31 - user] RANK COLORS = STAFF SYSTEM ONLY
--
-- "ياخذ لون الرتبة من نظام الرتب ستاف سستم مب من تاب لحاله"
-- The client no longer hardcodes any rank colors: s_tab pulls the whole
-- staff_roles color table from the staff bridge (admin-system) and pushes
-- it to every client. Re-synced on start, on a timer (covers late admin-system
-- starts), and by the bridge itself whenever a rank is saved.
-- ============================================================================

local function syncRankColors ( )
        local adminSys = getResourceFromName ( "admin-system" )
        if not adminSys or getResourceState ( adminSys ) ~= "running" then
                return
        end
        local ok, tbl = pcall ( function ( )
                return exports [ "admin-system" ]:getAllRankColors ( )
        end )
        if ok and type ( tbl ) == "table" and next ( tbl ) then
                triggerClientEvent ( "scoreboard:rankColors", root, tbl )
        end
end

addEventHandler ( "onResourceStart", resourceRoot, function ( )
        setTimer ( syncRankColors, 5000, 1 )  -- let admin-system finish booting
end )
setTimer ( syncRankColors, 30000, 0 )         -- keep mirroring staff_roles

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
        -- [Fix #30] the 21-rank ladder is the real authority (Trial Moderator+);
        -- the legacy columns stay as fallback
        local idx = tonumber(getElementData(p, "rank:index"))
        if idx then return idx >= 4 end
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

-- [Fix #30] THIS server's account stack never fires onPlayerLogin (no
-- triggerEvent("onPlayerLogin") exists anywhere), so mod ids were never
-- assigned ("Your mod id: -" in the owner's screenshots) and /checkid,
-- /setid could never find anybody. Hook what the stack ACTUALLY fires:
-- the account:username data flip and accounts:character:select.
local function assignModId(player)
        local user = tostring(getElementData(player, "account:username") or "")
        if user == "" then return end
        local id = getOrCreateModId(user)
        if id and getElementData(player, "mod:id") ~= id then
                setElementData(player, "mod:id", id)
        end
end

addEventHandler("onElementDataChange", root, function(key)
        if key == "account:username" and isElement(source)
                and getElementType(source) == "player" then
                assignModId(source)
        end
end)

addEvent("accounts:character:select", true)
addEventHandler("accounts:character:select", root, function()
        assignModId(source)
end)

-- legacy MTA login event kept for compatibility
addEventHandler("onPlayerLogin", root, function()
        assignModId(source)
end)

-- ---------------------------------------------------------------------------
-- [Fix #30] /checkid — the full ACCOUNT INSPECTOR.
--   /checkid            -> opens the input dialog (ask for an id)
--   /checkid <query>    -> straight lookup
--   query = mod id | account id | session id | account name | character name
-- The result panel lists: mod id, account id, username, email, serial, ip,
-- register date, last login, rank, warns, EVERY character (id/hours/ck) and
-- the live session. OFFLINE accounts work too (pure DB read).
-- ---------------------------------------------------------------------------
local mysql = exports.mysql

local function resolveAccountQuery(query)
        local q = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" then return nil end

        -- 1) mod id (exact)
        local asNum = tonumber(q)
        if asNum then
                for user, id in pairs(modIds) do
                        if id == asNum then
                                local row = mysql:query_fetch_assoc(
                                        "SELECT id, username FROM accounts WHERE username='"
                                        .. mysql:escape_string(user) .. "' LIMIT 1")
                                if row then return tonumber(row.id), tonumber(row.id) end
                        end
                end
        end

        -- 2) session id -> online player
        if asNum then
                for _, pl in ipairs(getElementsByType("player")) do
                        if tonumber(getElementData(pl, "playerid")) == asNum
                                or tonumber(getElementData(pl, "account:id")) == asNum then
                                return tonumber(getElementData(pl, "account:id")), pl
                        end
                end
        end

        -- 3) exact username
        local row = mysql:query_fetch_assoc("SELECT id FROM accounts WHERE username='"
                .. mysql:escape_string(q) .. "' LIMIT 1")
        if row then return tonumber(row.id) end

        -- 4) exact character name (with underscores or spaces)
        local charName = q:gsub(" ", "_")
        row = mysql:query_fetch_assoc("SELECT account FROM characters WHERE charactername='"
                .. mysql:escape_string(charName) .. "' LIMIT 1")
        if row then return tonumber(row.account) end

        -- 5) partial username (first match wins)
        local like = "%" .. mysql:escape_string(q) .. "%"
        row = mysql:query_fetch_assoc("SELECT id FROM accounts WHERE username LIKE '"
                .. like .. "' ORDER BY id ASC LIMIT 1")
        if row then return tonumber(row.id) end

        return nil
end

local function buildCheckidRows(accountID)
        local acc = mysql:query_fetch_assoc(
                "SELECT id, username, email, registerdate, mtaserial, ip, hiddenadmin, admin, supporter, scripter, warns, credits, adminnote, lastlogin"
                .. " FROM accounts WHERE id=" .. tonumber(accountID) .. " LIMIT 1")
        if not acc then return nil end

        local rows = {}
        local function add(label, value) rows[#rows + 1] = { label, value } end

        local username = tostring(acc.username or "-")
        local online = findPlayerByNamePart(username)

        -- rank through the staff bridge (nil-safe: account may hold no rank)
        local rankText = "-"
        local rankRecord = false
        pcall(function()
                local sys = getResourceFromName("admin-system")
                if sys and getResourceState(sys) == "running" then
                        rankRecord = exports["admin-system"]:getPlayerRankRecordByAccountID(accountID)
                end
        end)
        if type(rankRecord) == "table" and rankRecord.name then
                rankText = tostring(rankRecord.name)
        else
                local legacyAdmin = tonumber(acc.admin) or 0
                local legacySup = tonumber(acc.supporter) or 0
                if legacyAdmin > 0 or legacySup > 0 then
                        rankText = "admin=" .. legacyAdmin .. " supporter=" .. legacySup
                end
        end

        add("Mod ID", tostring(modIds[username] or "-"))
        add("Account ID", tostring(acc.id or "-"))
        add("Account Name", username)
        add("Email", tostring(acc.email or "-"))
        add("Serial", tostring(acc.mtaserial or "-"))
        add("IP", tostring(acc.ip or "-"))
        add("Rank", rankText)
        add("Register Date", tostring(acc.registerdate or "-"))
        add("Last Login", tostring(acc.lastlogin or "-"))
        add("Status", online and "#00ff00Online (session id "
                .. tostring(getElementData(online, "playerid") or "?") .. ")" or "#ff3c3cOffline")
        add("Hidden Admin", (tonumber(acc.hiddenadmin) or 0) == 1 and "YES" or "No")
        add("Warns", tostring(acc.warns or "0"))
        add("Admin Note", tostring(acc.adminnote or "-"))

        -- every character of the account (id / hours / cked)
        local chars = mysql:query(
                "SELECT id, charactername, cked, hoursPlayed FROM characters WHERE account="
                .. tonumber(accountID) .. " ORDER BY lastlogin DESC")
        if chars then
                local list = {}
                while true do
                        local c = mysql:fetch_assoc(chars)
                        if not c then break end
                        list[#list + 1] = string.format("%s (#%d, %sh%s)",
                                tostring(c.charactername or "?"):gsub("_", " "),
                                tonumber(c.id) or 0,
                                tostring(tonumber(c.hoursPlayed) or 0),
                                (tonumber(c.cked) == 1) and ", CKed" or "")
                end
                mysql:free_result(chars)
                add("Characters (" .. #list .. ")", #list > 0 and table.concat(list, " | ") or "-")
        else
                add("Characters", "-")
        end

        return rows
end

local lastLookup = setmetatable({}, { __mode = "k" })
local function lookupRateLimited(player)
        local now = getTickCount()
        local last = lastLookup[player] or 0
        if now - last < 500 then return false end
        lastLookup[player] = now
        return true
end

addEvent("checkid:lookup", true)
addEventHandler("checkid:lookup", root, function(query)
        local player = client
        if not player or client ~= source then return end
        if not isStaffPlayer(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 80, 80)
                return
        end
        if not lookupRateLimited(player) then return end
        local accountID = resolveAccountQuery(query)
        if not accountID then
                triggerClientEvent(player, "checkid:result", player, {
                        error = "No account matches '" .. tostring(query) .. "'.",
                })
                return
        end
        local rows = buildCheckidRows(accountID)
        if not rows then
                triggerClientEvent(player, "checkid:result", player, {
                        error = "Account data not found (id " .. tostring(accountID) .. ").",
                })
                return
        end
        triggerClientEvent(player, "checkid:result", player, rows)
end)

-- the command: no args = open the input dialog, args = straight lookup
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
                triggerClientEvent(player, "checkid:openInput", player)
                return
        end
        triggerClientEvent(player, "checkid:openInput", player, query)
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
