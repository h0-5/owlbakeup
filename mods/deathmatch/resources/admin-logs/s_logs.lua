-- ===========================================================================
-- admin-logs - TIERED CHAT LOG FEED (new resource, companion of Fix #160)
--
-- WHAT THIS RESOURCE IS
--   One place that prints rich, single-line log entries into the chat box of
--   every viewer who is entitled to see them. Three feeds feed it:
--     * fix160:cmdok       - fired by staff_manager's central command gate
--                            every time a GATED admin command is allowed
--                            (source may be any resourceRoot);
--     * fix160:rankchanged - fired at every staff_rank_changelogs INSERT
--                            (promotion / demotion / rank edit);
--     * adminlogs:report*  - fired by report-system/s_reports.lua where a
--                            report is opened / accepted (see that file).
--   Multi-kills are tracked locally (onPlayerWasted).
--   The listeners are implemented NOW even though the staff_manager side may
--   not fire the fix160:* events yet - they activate the moment it does.
--
-- LINE FORMAT (owner's screenshots - ONE shape for every feed)
--   [{Tag}] : {Character} ({account}) {detail}.
--   e.g.  [Admin] : Robson Walton (h05) revived Hamdi DJawfer.
--   Tag   = Admin (gated command usage), Staff (report opened / accepted,
--           promotions / demotions), Debug (internal warnings),
--           DEATHMATCH (kill alerts)
--   The THREE hide commands (/hidelogs, /hiddenlogs, /hideadmin) are NEVER
--   logged for anyone.
--
-- VISIBILITY TIERS (decided by the VIEWER, never by the actor)
--   4 debug           -> every line
--   3 admin.isAdmin   -> every line EXCEPT the ones built from commands that
--                        change serial / email / account id / role id
--                        (SENSITIVE_COMMANDS below - those are debug-only)
--   2 admin.isStaff   -> ONLY ownership / vehicle transfers, report opened,
--                        report accepted, promotions and demotions
--   1 nobody          -> nothing
--   On top of the tier: a viewer with the local hide toggle ON sees nothing
--   at all (KEY_HIDE_LOCAL), and an actor with the global hide toggle ON
--   produces no command line for ANYONE (KEY_HIDE_GLOBAL).
--
-- STATE (grepped before choosing the keys: nothing else reads them)
--   adminlogs:hide_local  - /hidelogs  (viewer-side, this admin sees nothing)
--   adminlogs:hide_global - /hiddenlogs (actor-side, his usage logs nowhere)
--   Both are server-only element data (synchronize = false) and are wiped
--   when the player quits.
-- ===========================================================================

-- =========================================================== tiers =========
-- entry/viewer tiers; an entry is shown when viewerTier >= entryTier
local TIER_NONE   = 1
local TIER_STAFF  = 2 -- admin.isStaff without admin.isAdmin
local TIER_ADMIN  = 3 -- admin.isAdmin
local TIER_DEBUG  = 4 -- debug

-- chat colours, identical to tocolor(255, 64, 64) / tocolor(255, 160, 0) /
-- tocolor(64, 220, 64). Passed as the r,g,b triple because that is the
-- documented server-side outputChatBox form everywhere in this server.
local COLOR_ADMIN      = { 255,  64,  64 } -- admin command lines (red)
local COLOR_DEATHMATCH = { 255,  64,  64 } -- kill alerts (red)
local COLOR_STAFF      = { 255, 160,   0 } -- rank changes (orange)
local COLOR_REPORT     = {  64, 220,  64 } -- report lines (green)

-- element data keys of this resource (server-only, see the header)
local KEY_HIDE_LOCAL  = "adminlogs:hide_local"
local KEY_HIDE_GLOBAL = "adminlogs:hide_global"

-- the three hide commands themselves are never logged, for anyone
local NEVER_LOGGED = {
        hideadmin  = true, -- keeps its hiddenadmin element data behaviour
        hidelogs   = true, -- new: local hide of this admin's own view
        hiddenlogs = true, -- repurposed: global hide of his own usage
}

-- Rights that change serial / email / account id / role id (and the close
-- cousins: account password / account name / account & character removal).
-- Derived from the command_gates_s.lua rights - a viewer below the debug
-- tier never sees the usage of these commands:
--   accounts.changepass / accounts.changeemail / accounts.changeserial /
--   accounts.changeid / accounts.changeaccountname / owner.setroleid /
--   owner.giverole / owner.takerole / owner.removeaccount /
--   owner.removecharacter
local SENSITIVE_COMMANDS = {
        -- accounts.* family (change serial / email / account id / name)
        changepass            = true,
        changeaccountpassword = true,
        setaccountpassword    = true,
        changeemail           = true,
        changeserial          = true,
        changeid              = true,
        changeaccountname     = true,
        -- owner.* family (role-id / role / whole account changes)
        giverole      = true,
        takerole      = true,
        setroleid     = true,
        giveziadadmin = true,
        resetaccount  = true,
        resetcharacter = true,
        rs            = true,
        unrecovery    = true,
}

-- Ownership / vehicle transfer lines: these are the extra lines the plain
-- admin.isStaff tier is allowed to see (the screenshot's "get vehicle ID
-- #69326 (From: ... | To: ...)" line belongs here too).
local STAFF_COMMANDS = {
        -- vehicle transfers
        getveh     = true,
        getcar     = true,
        giveveh    = true,
        setvehowner = true,
        sendcar    = true,
        sendvehto  = true,
        -- interior / property ownership transfers
        setintowner   = true,
        removeintowner = true,
        forcesell     = true,
        fsell         = true,
        tempsell      = true,
}

-- copy of the staff_manager rank seed order (staff_manager_s.lua RANK_SEED,
-- read-only reference) - only used to word a rank change as promoted /
-- demoted; an unknown rank name falls back to "changed the rank of"
local RANK_LADDER = {
        "Tester", "Trial Support", "Support", "Trial Moderator", "Moderator",
        "Senior Moderator", "Trial Administrator", "Administrator",
        "Senior Administrator", "Super Administrator", "Lead Administrator",
        "Administrative Director", "Junior Management", "Senior Management",
        "Server Management", "Head Management", "Chief Management",
        "Vice Founder", "Founder", "Diverloper", "Owner",
}

-- ============================================================ helpers =======

local function trim(s)
        return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- "Omar_O.Keeler" -> "Omar O.Keeler"
local function charName(p)
        if not isElement(p) then return "?" end
        local name = getPlayerName(p)
        if not name or name == "" then return "?" end
        return (name:gsub("_", " "))
end

local function accountName(p)
        if not isElement(p) then return "?" end
        local acct = getElementData(p, "account:username")
        if type(acct) == "string" and acct ~= "" then return acct end
        return "?"
end

-- "Omar O.Keeler (OmarLotfi)" - the actor prefix of every admin command line
local function who(p)
        return charName(p) .. " (" .. accountName(p) .. ")"
end

-- the id inside "(54088)" of the kill line: account id first (that is the
-- stable identity), character id and the session playerid as fallbacks
local function idOf(p)
        if not isElement(p) then return "?" end
        local id = tonumber(getElementData(p, "account:id"))
                or tonumber(getElementData(p, "character:id"))
                or tonumber(getElementData(p, "playerid"))
        return id and tostring(id) or "?"
end

-- quiet target resolution: findPlayerByPartialNick prints nothing when the
-- first argument is nil, so the log feed can never leak chat by itself
local function resolveName(query)
        query = trim(query)
        if query == "" then return "?" end
        local ok, target = pcall(function()
                return exports.global:findPlayerByPartialNick(nil, query)
        end)
        if ok and isElement(target) then
                return charName(target)
        end
        return query
end

-- "0, Rodeo, Los Santos" - dimension + colourful zone of any element
local function zoneLabel(el)
        if not isElement(el) then return "?" end
        local ok, zone = pcall(getElementZoneName, el, true)
        if not ok or type(zone) ~= "string" or zone == "" then
                zone = "unknown zone"
        end
        local dim = getElementDimension(el)
        return tostring(tonumber(dim) or 0) .. ", " .. zone
end

-- ==================================================== viewer rights =========
-- Primary source is the contract element data "rank:rights": a JSON string
-- (or an already-parsed table) pushed by staff_manager_bridge_s.lua. MTA
-- wraps associative tables as [{ ["right"] = true }], so both shapes are
-- unwrapped here; anything else is treated as "no live rights set".

local function rightsMap(player)
        local raw = getElementData(player, "rank:rights")
        local parsed = raw
        if type(raw) == "string" and raw ~= "" then
                local ok, decoded = pcall(fromJSON, raw)
                if not ok or type(decoded) ~= "table" then return nil end
                parsed = decoded
        end
        if type(parsed) ~= "table" then return nil end
        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                parsed = parsed[1]
        end
        if type(parsed) ~= "table" then return nil end
        return parsed
end

-- last resort when admin-system itself is not running: the old numeric
-- ladder, same thresholds the Fix #160 helpers use (lead = 4, senior = 3)
local function legacyHasRight(player, right)
        local lvl = tonumber(getElementData(player, "admin_level")) or 0
        if right == "debug" or right == "hidden.logs" then return lvl >= 4 end
        if right == "admin.isAdmin" or right == "admin.hide_logs" then
                return lvl >= 3
        end
        if right == "admin.isStaff" then return lvl >= 1 end
        return lvl >= 3
end

local function viewerHasRight(player, right)
        if not isElement(player) or getElementType(player) ~= "player" then
                return false
        end
        local map = rightsMap(player)
        if map and map[right] == true then return true end
        -- The live set may be complete but a TEAM grant (or the legacy
        -- ladder when no rank row exists) still decides: ask the staff
        -- bridge, the same API every gate in admin-system uses.
        local ok, res = pcall(function()
                return exports["admin-system"]:playerHasRight(player, right)
        end)
        if ok and res ~= nil then return res and true or false end
        if map then return false end -- live set exists and says no
        return legacyHasRight(player, right)
end

-- Fast path is the element data itself (no cross-resource call at all); the
-- bridge is asked only when the live set carries none of the three identity
-- rights, so a TEAM grant or a rank-less legacy admin is still classified
-- correctly.
local function tierFor(player)
        local map = rightsMap(player)
        if map then
                if map["debug"] then return TIER_DEBUG end
                if map["admin.isAdmin"] then return TIER_ADMIN end
                if map["admin.isStaff"] then return TIER_STAFF end
        end
        local ok, hasDebug, hasAdmin, hasStaff = pcall(function()
                local ex = exports["admin-system"]
                return ex:playerHasRight(player, "debug"),
                        ex:playerHasRight(player, "admin.isAdmin"),
                        ex:playerHasRight(player, "admin.isStaff")
        end)
        if ok then
                if hasDebug then return TIER_DEBUG end
                if hasAdmin then return TIER_ADMIN end
                if hasStaff then return TIER_STAFF end
                return TIER_NONE
        end
        if map then return TIER_NONE end
        -- admin-system is not running: legacy numeric ladder decides
        local lvl = tonumber(getElementData(player, "admin_level")) or 0
        if lvl >= 4 then return TIER_DEBUG end
        if lvl >= 3 then return TIER_ADMIN end
        if lvl >= 1 then return TIER_STAFF end
        return TIER_NONE
end

-- ============================================================ emit =========
-- the ONE line shape every feed prints (owner's screenshots):
--   "[Admin] : Robson Walton (h05) revived Hamdi DJawfer."
--   "{Tag} : {Character} ({account}) {detail}."  - actor ALWAYS carries the
--   account, detail never carries the trailing dot (logLine adds it).
local TAG_ADMIN      = "[Admin]"
local TAG_STAFF      = "[Staff]"
local TAG_DEBUG      = "[Debug]"
local TAG_DEATHMATCH = "[DEATHMATCH]"

local function logLine(tag, actor, detail)
        return tag .. " : " .. actor .. " " .. detail .. "."
end

-- one line -> every online, logged-in viewer whose tier covers it and whose
-- local hide toggle is OFF
local function emitLog(color, line, tier)
        for _, viewer in ipairs(getElementsByType("player")) do
                if isElement(viewer)
                        and tonumber(getElementData(viewer, "loggedin") or 0) == 1
                        and (tonumber(getElementData(viewer, KEY_HIDE_LOCAL)) or 0) ~= 1
                        and tierFor(viewer) >= tier then
                        outputChatBox(line, viewer, color[1], color[2], color[3])
                end
        end
end

-- ======================================================= formatters ========
-- Per-command detail builders: (actor, args) -> "detail" WITHOUT the trailing
-- period (logLine adds it). Returning nil falls back to the generic
-- "used /cmd <args>" line built from the cmdok args.

local function a(args, i)
        return trim(args and args[i])
end

-- everything from args[i] onwards, as typed
local function rest(args, i)
        if type(args) ~= "table" then return "" end
        local parts = {}
        for k = i or 1, #args do
                parts[#parts + 1] = tostring(args[k])
        end
        return trim(table.concat(parts, " "))
end

-- /ban <player> <hours> [reason] - shared by the whole ban family
local function fmtBan(actor, args)
        if a(args, 1) == "" then return nil end
        local who_ = a(args, 2) ~= "" and (a(args, 2) .. " hour(s) for ") or ""
        local reason = rest(args, 3)
        local line = "banned " .. who_ .. resolveName(a(args, 1))
        if reason ~= "" then line = line .. " (" .. reason .. ")" end
        return line
end

-- /jail <player> <minutes> [reason] - shared by jail / sjail / ojail / sojail
local function fmtJail(actor, args)
        if a(args, 1) == "" then return nil end
        local line = "jailed " .. resolveName(a(args, 1))
        if a(args, 2) ~= "" then line = line .. " for " .. a(args, 2) .. " minute(s)" end
        local reason = rest(args, 3)
        if reason ~= "" then line = line .. " (" .. reason .. ")" end
        return line
end

-- /kick <player> [reason]
local function fmtKick(actor, args)
        if a(args, 1) == "" then return nil end
        local line = "kicked " .. resolveName(a(args, 1))
        local reason = rest(args, 2)
        if reason ~= "" then line = line .. " (" .. reason .. ")" end
        return line
end

-- /sethp <player> <health> and friends: "set health of player Hade U.Keeler
-- to (100)" - the owner's screenshot wording (name unbracketed, value in
-- brackets)
local function fmtHealth(what, defValue)
        return function(actor, args)
                if a(args, 1) == "" then return nil end
                local value = a(args, 2)
                if value == "" then value = tostring(defValue or "?") end
                return "set " .. what .. " of player " .. resolveName(a(args, 1))
                        .. " to (" .. value .. ")"
        end
end

-- money commands: /setmoney <player> <amount>, /givemoney, /takemoney
local function fmtMoney(mode)
        return function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                local target = resolveName(a(args, 1))
                local amount = "$" .. a(args, 2):gsub("^%$", "")
                if mode == "set" then
                        return "set money of player (" .. target .. ") to (" .. amount .. ")"
                elseif mode == "give" then
                        return "gave " .. amount .. " to player (" .. target .. ")"
                end
                return "took " .. amount .. " from player (" .. target .. ")"
        end
end

-- /closereport <id> / /cr <id> / /endreport <id> / /er <id> - the screenshot
-- line: "finished report ID 1."
local function fmtReportFinish(actor, args)
        local id = tonumber(a(args, 1))
        if not id then return nil end
        return "finished report ID " .. id
end

local FORMATTERS = {
        ---------------------------------------------------------- teleports --
        -- the screenshot line: "teleported to Cosed Eli Madadiqa."
        ["goto"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "teleported to " .. resolveName(a(args, 1))
        end,
        ["atp"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "teleported to " .. resolveName(a(args, 1))
        end,
        ["dtp"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "teleported to " .. resolveName(a(args, 1))
        end,
        -- the screenshot line: "went to place 'agm'." -> teleports to a place
        ["gotoplace"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                local line = "teleported to place '" .. a(args, 1) .. "'"
                if a(args, 2) ~= "" then
                        line = line .. " for '" .. resolveName(a(args, 2)) .. "'"
                end
                return line
        end,
        ["gotofuel"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "teleported to place '" .. a(args, 1) .. "'"
        end,
        ["gotogate"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "teleported to place '" .. a(args, 1) .. "'"
        end,
        ["gethere"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "brought player '" .. resolveName(a(args, 1)) .. "' to his position"
        end,
        ["sendto"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                local line = "sent player '" .. resolveName(a(args, 1)) .. "'"
                if a(args, 2) ~= "" then line = line .. " to '" .. a(args, 2) .. "'" end
                return line
        end,
        ["gotoveh"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "went to vehicle #" .. a(args, 1)
        end,
        ["gotocar"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "went to vehicle #" .. a(args, 1)
        end,
        ----------------------------------------------------------- vehicles --
        -- the screenshot line: "get vehicle ID #69326 (From: 0, Rodeo, Los
        -- Santos | To: 0, Commerce, Los Santos)." The pair is read when the
        -- feed arrives: while the gate fires before the command runs, From is
        -- still the vehicle spot and To is the admin's spot (getveh moves the
        -- vehicle to the admin).
        ["getveh"] = function(actor, args)
                local id = tonumber(a(args, 1))
                if not id then return nil end
                local veh
                pcall(function() veh = exports.pool:getElement("vehicle", id) end)
                if not isElement(veh) then
                        return "get vehicle ID #" .. id
                end
                return "get vehicle ID #" .. id .. " (From: " .. zoneLabel(veh)
                        .. " | To: " .. zoneLabel(actor) .. ")"
        end,
        ["getcar"] = function(actor, args)
                local id = tonumber(a(args, 1))
                if not id then return nil end
                local veh
                pcall(function() veh = exports.pool:getElement("vehicle", id) end)
                if not isElement(veh) then
                        return "get vehicle ID #" .. id
                end
                return "get vehicle ID #" .. id .. " (From: " .. zoneLabel(veh)
                        .. " | To: " .. zoneLabel(actor) .. ")"
        end,
        ["giveveh"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "gave vehicle #" .. a(args, 1) .. " to player '"
                        .. resolveName(a(args, 2)) .. "'"
        end,
        ["setvehowner"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                local line = "transferred ownership of vehicle #" .. a(args, 1)
                if a(args, 2) ~= "" then
                        line = line .. " to '" .. resolveName(a(args, 2)) .. "'"
                end
                return line
        end,
        ------------------------------------------------------ player state ---
        -- the screenshot line: "set health of player Hade U.Keeler to (100)."
        ["sethp"] = fmtHealth("health", 100),
        ["setarmor"] = fmtHealth("armor", 100),
        -- the screenshot line: "revived <target player name>."
        ["revive"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "revived " .. resolveName(a(args, 1))
        end,
        ["aheal"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "healed player (" .. resolveName(a(args, 1)) .. ") to (100)"
        end,
        ["setskin"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "set skin of player (" .. resolveName(a(args, 1))
                        .. ") to (#" .. a(args, 2) .. ")"
        end,
        ["changename"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "renamed player (" .. resolveName(a(args, 1)) .. ") to ("
                        .. rest(args, 2) .. ")"
        end,
        ["disappear"] = function(actor, args)
                return "toggled vanish (disappear) mode"
        end,
        ------------------------------------------------------------ money ----
        ["setmoney"] = fmtMoney("set"),
        ["givemoney"] = fmtMoney("give"),
        ["takemoney"] = fmtMoney("take"),
        ["givegc"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "gave " .. a(args, 2) .. " game coin(s) to player ("
                        .. resolveName(a(args, 1)) .. ")"
        end,
        ["givegamecoins"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "gave " .. a(args, 2) .. " game coin(s) to player ("
                        .. resolveName(a(args, 1)) .. ")"
        end,
        ["givegamecoin"] = function(actor, args)
                if a(args, 1) == "" or a(args, 2) == "" then return nil end
                return "gave " .. a(args, 2) .. " game coin(s) to player ("
                        .. resolveName(a(args, 1)) .. ")"
        end,
        -------------------------------------------------------- moderation ---
        ["ban"] = fmtBan, ["pban"] = fmtBan, ["sban"] = fmtBan,
        ["oban"] = fmtBan, ["soban"] = fmtBan,
        ["kick"] = fmtKick, ["pkick"] = fmtKick, ["skick"] = fmtKick,
        ["jail"] = fmtJail, ["sjail"] = fmtJail,
        ["ojail"] = fmtJail, ["sojail"] = fmtJail,
        ["unjail"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                return "released " .. resolveName(a(args, 1)) .. " from jail"
        end,
        ["warn"] = function(actor, args)
                if a(args, 1) == "" then return nil end
                local line = "warned " .. resolveName(a(args, 1))
                local reason = rest(args, 2)
                if reason ~= "" then line = line .. " (" .. reason .. ")" end
                return line
        end,
        ------------------------------------------------------------ reports ---
        -- the screenshot line: "finished report ID 1."
        ["closereport"] = fmtReportFinish, ["cr"] = fmtReportFinish,
        ["endreport"] = fmtReportFinish, ["er"] = fmtReportFinish,
        ------------------------------------------------------- announcements -
        ["bc"] = function(actor, args)
                local msg = rest(args, 1)
                if msg == "" then return nil end
                return "broadcasted '" .. msg .. "'"
        end,
        ["ann"] = function(actor, args)
                local msg = rest(args, 1)
                if msg == "" then return nil end
                return "announced '" .. msg .. "'"
        end,
}

-- detail must stay one short line: collapse whitespace, drop a trailing dot
-- (logLine adds it) and cap the length so one command cannot flood the chat
local function sanitizeDetail(detail)
        detail = tostring(detail or ""):gsub("[\r\n]", " ")
        detail = detail:gsub("%s+", " ")
        detail = trim(detail):gsub("[%.%s]+$", "")
        if detail == "" then return nil end
        if #detail > 160 then detail = detail:sub(1, 157) .. "..." end
        return detail
end

-- ============================================== feed 1: gated commands =====

local function logCommandUsage(player, cmd, args)
        if not isElement(player) or getElementType(player) ~= "player" then
                return
        end
        cmd = tostring(cmd or ""):lower()
        if cmd == "" or NEVER_LOGGED[cmd] then return end
        -- /hiddenlogs (global hide): while ON this admin's usage produces no
        -- line for ANYONE, himself included - everyone else keeps seeing his
        -- other commands normally.
        if (tonumber(getElementData(player, KEY_HIDE_GLOBAL)) or 0) == 1 then
                return
        end
        if type(args) ~= "table" then args = {} end

        local detail
        local formatter = FORMATTERS[cmd]
        if formatter then
                local ok, built = pcall(formatter, player, args)
                if ok then detail = built end
        end
        if not detail then
                -- generic fallback built from the cmdok args: used /cmd a b c
                detail = "used /" .. cmd
                local tail = rest(args, 1)
                if tail ~= "" then detail = detail .. " " .. tail end
        end
        detail = sanitizeDetail(detail)
        if not detail then return end

        local line = logLine(TAG_ADMIN, who(player), detail)
        local tier = TIER_ADMIN
        if SENSITIVE_COMMANDS[cmd] then
                tier = TIER_DEBUG
        elseif STAFF_COMMANDS[cmd] then
                tier = TIER_STAFF
        end
        emitLog(COLOR_ADMIN, line, tier)
end

-- The staff_manager command gate fires this for EVERY allowed gated command.
-- addEvent is called here as well (allowRemoteTrigger = false): whichever
-- resource registers it first wins, and neither side wants a client to be
-- able to push fake lines - the handler below rejects remote triggers too.
addEvent("fix160:cmdok", false)
addEventHandler("fix160:cmdok", root, function(player, cmd, args)
        if client then
                outputDebugString(logLine(TAG_DEBUG, who(client),
                        "rejected a remote fix160:cmdok trigger"), 2)
                return
        end
        local ok, err = pcall(logCommandUsage, player, cmd, args)
        if not ok then
                outputDebugString(logLine(TAG_DEBUG, who(player),
                        "cmdok failed for /" .. tostring(cmd) .. ": "
                        .. tostring(err)), 2)
        end
end)

-- ============================================ feed 2: rank changes =========
-- fired by staff_manager at every staff_rank_changelogs INSERT with a single
-- table: { account=…, target=…, from=…, to=…, by=… }. Fields may be player
-- elements, account names or plain strings - resolveNameWho() handles all.

local function rankPos(name)
        if type(name) ~= "string" then return nil end
        local wanted = name:lower()
        for i, rname in ipairs(RANK_LADDER) do
                if rname:lower() == wanted then return i end
        end
        return nil
end

-- turn one payload field (element / table / string) into "char", "account"
local function resolveWho(value, extra)
        if isElement(value) and getElementType(value) == "player" then
                return charName(value), accountName(value)
        end
        if type(value) == "table" then
                local cname = value.char or value.name or value.character
                local acct = value.account or value.username or value.acct
                if isElement(cname) then cname = charName(cname) end
                if isElement(acct) then acct = accountName(acct) end
                return tostring(cname or extra or "?"), tostring(acct or "?")
        end
        if type(value) == "string" and value ~= "" then
                -- maybe an account name of an online player: then we know
                -- both halves of the pair, otherwise use it as the character
                for _, p in ipairs(getElementsByType("player")) do
                        if (getElementData(p, "account:username") or ""):lower()
                                == value:lower() then
                                return charName(p), accountName(p)
                        end
                end
                return value, tostring(extra or value)
        end
        if type(extra) == "string" and extra ~= "" then
                return extra, extra
        end
        return "?", "?"
end

local function logRankChange(payload, ...)
        -- tolerate a positional call (account, target, from, to, by) as well
        -- as the contracted single-table payload
        local account, target, from, to, by
        if type(payload) == "table" then
                account = payload.account
                target = payload.target
                from = payload.from
                to = payload.to
                by = payload.by
        else
                account, target, from, to, by = payload, ...
        end
        if target == nil and account ~= nil and type(account) ~= "table" then
                target = account
        end

        local byChar, byAcct = resolveWho(by, "?")
        local tgChar, tgAcct = resolveWho(target, account)

        from = (type(from) == "string" and from ~= "") and from or nil
        to = (type(to) == "string" and to ~= "") and to or nil

        local detail
        if from and to then
                local fromPos, toPos = rankPos(from), rankPos(to)
                local verb = "changed the rank of"
                if fromPos and toPos then
                        verb = toPos > fromPos and "promoted" or "demoted"
                end
                detail = verb .. " " .. tgChar .. " (" .. tgAcct .. ") from '"
                        .. from .. "' to '" .. to .. "'"
        elseif to then
                detail = "granted rank '" .. to .. "' to " .. tgChar .. " ("
                        .. tgAcct .. ")"
        elseif from then
                detail = "removed rank '" .. from .. "' from " .. tgChar .. " ("
                        .. tgAcct .. ")"
        else
                return -- nothing changed, no line
        end

        detail = sanitizeDetail(detail)
        if not detail then return end
        local line = logLine(TAG_STAFF, byChar .. " (" .. byAcct .. ")", detail)
        emitLog(COLOR_STAFF, line, TIER_STAFF)
end

addEvent("fix160:rankchanged", false)
addEventHandler("fix160:rankchanged", root, function(payload, ...)
        if client then
                outputDebugString(logLine(TAG_DEBUG, who(client),
                        "rejected a remote fix160:rankchanged trigger"), 2)
                return
        end
        local ok, err = pcall(logRankChange, payload, ...)
        if not ok then
                local byChar, byAcct = "?", "?"
                if type(payload) == "table" then
                        byChar, byAcct = resolveWho(payload.by, "?")
                end
                outputDebugString(logLine(TAG_DEBUG,
                        byChar .. " (" .. byAcct .. ")",
                        "rankchanged failed: " .. tostring(err)), 2)
        end
end)

-- ================================================ feed 3: reports ==========
-- report-system/s_reports.lua triggers these; both lines use the owner's
-- screenshot wording, the STAFF tag and the reporter as the actor, in report
-- green.

addEvent("adminlogs:reportopen", false)
addEventHandler("adminlogs:reportopen", root, function(reporter, id)
        if client then return end
        if not isElement(reporter) then return end
        local detail = sanitizeDetail("has submitted a report (Report ID: #"
                .. tostring(id or "?") .. ")")
        if not detail then return end
        emitLog(COLOR_REPORT, logLine(TAG_STAFF, who(reporter), detail),
                TIER_STAFF)
end)

addEvent("adminlogs:reportaccept", false)
addEventHandler("adminlogs:reportaccept", root, function(reporter, id, admin)
        if client then return end
        local actor = isElement(reporter) and who(reporter) or "? (?)"
        local adminWho = isElement(admin) and who(admin) or "? (?)"
        local detail = sanitizeDetail("has submitted a report (Report ID: #"
                .. tostring(id or "?") .. ") | accept by " .. adminWho)
        if not detail then return end
        emitLog(COLOR_REPORT, logLine(TAG_STAFF, actor, detail), TIER_STAFF)
end)

-- ============================================== feed 4: multi-kills ========
-- more than 2 kills inside 60 seconds -> one alert per window (a long spree
-- must not print the line again on every further kill)

local killWindows = {} -- [killer] = { { t = timestamp, victim = element }, ... }
local killAlerted = {} -- [killer] = true once the current window fired

addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart, stealth)
        if not isElement(killer) or getElementType(killer) ~= "player" then
                return
        end
        if killer == source then return end -- suicides are not a spree
        local now = tonumber(getRealTime().timestamp) or 0

        local kept, list = {}, killWindows[killer] or {}
        for _, entry in ipairs(list) do
                if now - (entry.t or 0) <= 60 then
                        kept[#kept + 1] = entry
                end
        end
        kept[#kept + 1] = { t = now, victim = source }
        killWindows[killer] = kept

        if #kept > 2 then
                if not killAlerted[killer] then
                        killAlerted[killer] = true
                        local line = logLine(TAG_DEATHMATCH, who(killer),
                                "killed " .. #kept
                                .. " players within 1 minute")
                        emitLog(COLOR_DEATHMATCH, line, TIER_ADMIN)
                end
        else
                -- window decayed: the next spree may alert again
                killAlerted[killer] = nil
        end
end)

-- ==================================================== /hidelogs ===========
-- NEW command, right hidden.logs. It is NOT in any Fix #160 gate table
-- (unmapped commands are unrestricted), so the right is enforced right here
-- and it is never logged - see NEVER_LOGGED.
addCommandHandler("hidelogs", function(player, cmd)
        if not isElement(player) or getElementType(player) ~= "player" then
                return
        end
        if not viewerHasRight(player, "hidden.logs") then
                outputChatBox("You don't have permission to use this command.",
                        player, 255, 0, 0)
                return
        end
        local on = (tonumber(getElementData(player, KEY_HIDE_LOCAL)) or 0) ~= 1
        -- server-only element data: nothing outside this resource reads it
        setElementData(player, KEY_HIDE_LOCAL, on and 1 or 0, false)
        outputChatBox(on and "hide logs on" or "hide logs off", player, 255, 194, 14)
end, false, false)

-- ====================================================== housekeeping =======

-- the toggles and the spree window are per-session: never survive a relog
addEventHandler("onPlayerQuit", root, function()
        setElementData(source, KEY_HIDE_LOCAL, nil, false)
        setElementData(source, KEY_HIDE_GLOBAL, nil, false)
        killWindows[source] = nil
        killAlerted[source] = nil
end)
