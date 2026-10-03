-- [Fix #160] A7 - admin misc command handlers
-- Owned exclusively by the matching Fix #160 task agent.
--
-- [Fix #160] Rights wired here (gate table: staff_manager/gates_fix160_task7.lua)
--   gate-only, the handler already lives elsewhere:
--     accounts.changeid    -> /changeid       scoreboard/s_tab.lua:486
--     admin.revive         -> /revive         es-system/s_es_system.lua:1913
--     admin.isStaff        -> /staff :639, /admins :635  hud/s_overlay_show_admins.lua
--     applications.access  -> /apps, /applications        apps/app_manager_c.lua (client)
--     admin.setwave        -> /swh            weather-system/s_weather_system.lua:625
--     admin.badge          -> /issuebadge     item-system/s_commands.lua:169
--                             (already mapped in the base map, command_gates_s.lua)
--   new handlers implemented below:
--     admin.clearhistory             -> /clearhistory
--     admin.clearhistoryforallonline -> /clearhistoryforallonline
--     admin.removehistory            -> /removehistory
--     admin.restartallres / stopallres -> /restartallres /stopallres
--     admin.startallmaps / stopallmaps -> /startallmaps /stopallmaps
--     admin.pkickall                 -> /pkickall
--     admin.bc_chat                  -> /bc
--     admin.badge.developer/support  -> /togdevbadge /togsupportbadge
--     applications.edit              -> /appstate
--     special_membership.add/remove  -> /addspecial /removespecial
--     level.give_exp / level.boost   -> /giveexp /levelboost
--     feature.give                   -> /givefeature
--   REPURPOSED by the admin-logs task (owner request): /hiddenlogs is no
--   longer a hiddenlogs/*.log file viewer, it now toggles the GLOBAL hide of
--   this admin's OWN usage (right admin.hide_logs, checked inside the
--   handler). The local toggle /hidelogs (right hidden.logs) lives in the
--   admin-logs resource next to the log feed it controls.
--   NOT DONE (no command/system/consumer in this server, intentionally left
--   out of the gate table - the A7 report gives the reason per right):
--     admin.remove_gov, admin.voice_mute, admin.voice_unmute,
--     cinema, mechanic.panel, activity.create, activity.end
--
-- [Fix #160] They register through the WRAPPED addCommandHandler
-- (command_gates_s.lua is the first script of admin-system), so ranked staff
-- are already refused by the gate itself; the helper below is the legacy
-- ladder for players without a Vortex rank, which the gate deliberately lets
-- through (same rule as Fix #157 / A2's s_fix160_char.lua).

-- [Fix #160] meta.xml lists this stub three times (merge artifact of the
-- parallel task patches). Load once, otherwise every command below would
-- register three handler instances and fire three times.
if rawget(_G, "FIX160_MISC_LOADED") then return end
_G.FIX160_MISC_LOADED = true

local mysql = exports.mysql

local function fix160MiscTrim(s)
        s = tostring(s or "")
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fix160MiscSyntax(player, cmd, args)
        outputChatBox("SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), player, 255, 194, 14)
end

-- legacy ladder, identical to fix157HasRight (staff_manager_s.lua): rank
-- holders are decided by stored rights, everyone else by the old admin ladder
local function fix160MiscHasRight(player, right)
        if not isElement(player) then return false end
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right) and true or false
                end
                return false
        end
        local prefix = tostring(right):match("^([%w]+)%.") or ""
        if prefix == "owner" or prefix == "accounts" then
                return exports.integration:isPlayerLeadAdmin(player) and true or false
        end
        if prefix == "character" then
                return exports.integration:isPlayerTrialAdmin(player) and true or false
        end
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function fix160MiscCheck(player, right)
        if fix160MiscHasRight(player, right) then return true end
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return false
end

-- admin-command log (action 4 = "Admin command"); affected may be an element
-- or, for offline accounts, any string
local function fix160MiscLog(actor, data, affected)
        pcall(function()
                exports.logs:dbLog(actor, 4, affected or actor, data)
        end)
end

local function fix160MiscAdminAnnounce(text)
        pcall(function()
                exports.global:sendMessageToAdmins(text)
        end)
end

-- resolve an ONLINE target; findPlayerByPartialNick prints its own miss msg
local function fix160MiscTarget(player, query)
        local target, targetName = exports.global:findPlayerByPartialNick(player, fix160MiscTrim(query))
        if not isElement(target) then return nil, nil end
        if tonumber(getElementData(target, "loggedin") or 0) ~= 1 then
                outputChatBox("Player is not logged in.", player, 255, 0, 0)
                return nil, nil
        end
        return target, targetName
end

local function fix160MiscPlayerByAccountID(accountID)
        accountID = tonumber(accountID)
        if not accountID then return nil end
        for _, p in ipairs(getElementsByType("player")) do
                if tonumber(getElementData(p, "account:id")) == accountID then
                        return p
                end
        end
        return nil
end

-- resolve an account from: numeric id -> username -> character name ->
-- online player nick (quiet). Returns the accounts row + online player.
local FIX160_MISC_ACCOUNT_COLS = "id, username, appstate, warns"

local function fix160MiscAccount(query)
        local q = fix160MiscTrim(query)
        if q == "" then return nil, nil end
        local esc = mysql:escape_string(q)
        local row
        if q:match("^%d+$") then
                row = mysql:query_fetch_assoc("SELECT " .. FIX160_MISC_ACCOUNT_COLS
                        .. " FROM accounts WHERE id=" .. tonumber(q))
        end
        if not row then
                row = mysql:query_fetch_assoc("SELECT " .. FIX160_MISC_ACCOUNT_COLS
                        .. " FROM accounts WHERE LOWER(username)=LOWER('" .. esc .. "') LIMIT 1")
        end
        if not row then
                local cRow = mysql:query_fetch_assoc("SELECT account FROM characters"
                        .. " WHERE LOWER(charactername)=LOWER('" .. esc .. "') LIMIT 1")
                if cRow and tonumber(cRow.account) then
                        row = mysql:query_fetch_assoc("SELECT " .. FIX160_MISC_ACCOUNT_COLS
                                .. " FROM accounts WHERE id=" .. tonumber(cRow.account))
                end
        end
        if not row then
                local ok, target = pcall(function()
                        -- third arg = quiet: no "No such player found." spam
                        return exports.global:findPlayerByPartialNick(nil, q, true)
                end)
                if ok and isElement(target) and getElementType(target) == "player" then
                        local aid = tonumber(getElementData(target, "account:id"))
                        if aid then
                                row = mysql:query_fetch_assoc("SELECT " .. FIX160_MISC_ACCOUNT_COLS
                                        .. " FROM accounts WHERE id=" .. aid)
                        end
                end
        end
        if not row then return nil, nil end
        return row, fix160MiscPlayerByAccountID(tonumber(row.id))
end

-- ================================================ adminhistory family ====
-- mirrors removeAdminHistoryLine (s_check.lua): every history row with
-- action 4 is a warning, deleting it gives the warning back (floored at 0)

local function fix160MiscClearAccount(accID)
        accID = tonumber(accID)
        if not accID then return 0, 0 end
        local lines, warns = 0, 0
        local q = mysql:query("SELECT id, action FROM adminhistory WHERE user=" .. accID)
        if q then
                while true do
                        local r = mysql:fetch_assoc(q)
                        if not r then break end
                        lines = lines + 1
                        if tonumber(r.action) == 4 then warns = warns + 1 end
                end
                mysql:free_result(q)
        end
        if lines == 0 then return 0, 0 end
        if warns > 0 then
                mysql:query_free("UPDATE accounts SET warns=IF(warns>=" .. warns
                        .. ",warns-" .. warns .. ",0) WHERE id=" .. accID)
                local online = fix160MiscPlayerByAccountID(accID)
                if online then
                        local cur = tonumber(getElementData(online, "warns")) or 0
                        exports.anticheat:changeProtectedElementDataEx(online, "warns",
                                math.max(0, cur - warns), false)
                end
        end
        mysql:query_free("DELETE FROM adminhistory WHERE user=" .. accID)
        return lines, warns
end

addCommandHandler("clearhistory", function(player, cmd, ...)
        if not fix160MiscCheck(player, "admin.clearhistory") then return end
        if not select(1, ...) then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / AccountID / Character Name]")
                return
        end
        local full = table.concat({ ... }, "_")
        local row, online = fix160MiscAccount(full)
        if not row then
                outputChatBox("Account not found: " .. full, player, 255, 0, 0)
                return
        end
        local lines, warns = fix160MiscClearAccount(tonumber(row.id))
        if lines == 0 then
                outputChatBox(tostring(row.username) .. " has no admin history lines.", player, 255, 194, 14)
                return
        end
        outputChatBox("Removed " .. lines .. " admin history line(s) (" .. warns
                .. " warning(s)) from " .. tostring(row.username) .. " (account #"
                .. tonumber(row.id) .. ").", player, 0, 255, 0)
        fix160MiscLog(player, "CLEARHISTORY " .. tostring(row.username) .. " account #"
                .. tonumber(row.id) .. ": " .. lines .. " lines (" .. warns .. " warnings)",
                online or tostring(row.username))
end, false, false)

addCommandHandler("clearhistoryforallonline", function(player, cmd)
        if not fix160MiscCheck(player, "admin.clearhistoryforallonline") then return end
        local seen, accounts = {}, {}
        for _, p in ipairs(getElementsByType("player")) do
                if tonumber(getElementData(p, "loggedin") or 0) == 1 then
                        local aid = tonumber(getElementData(p, "account:id"))
                        if aid and not seen[aid] then
                                seen[aid] = true
                                accounts[#accounts + 1] = aid
                        end
                end
        end
        if #accounts == 0 then
                outputChatBox("No logged-in players online.", player, 255, 194, 14)
                return
        end
        local totalLines, totalWarns, touched = 0, 0, 0
        for _, aid in ipairs(accounts) do
                local lines, warns = fix160MiscClearAccount(aid)
                if lines > 0 then
                        touched = touched + 1
                        totalLines = totalLines + lines
                        totalWarns = totalWarns + warns
                end
        end
        outputChatBox("Cleared " .. totalLines .. " admin history line(s) (" .. totalWarns
                .. " warning(s)) across " .. touched .. " of " .. #accounts
                .. " online account(s).", player, 0, 255, 0)
        fix160MiscLog(player, "CLEARHISTORYFORALLONLINE " .. touched .. " accounts, "
                .. totalLines .. " lines, " .. totalWarns .. " warnings", player)
end, false, false)

addCommandHandler("removehistory", function(player, cmd, idArg)
        if not fix160MiscCheck(player, "admin.removehistory") then return end
        local id = tonumber(idArg)
        if not id or id < 1 or id % 1 ~= 0 then
                fix160MiscSyntax(player, cmd, "[adminhistory line ID]  (see /history)")
                return
        end
        id = math.floor(id)
        local row = mysql:query_fetch_assoc("SELECT id, user, action FROM adminhistory WHERE id=" .. id)
        if not row or not row.id then
                outputChatBox("No admin history line #" .. id .. " found.", player, 255, 0, 0)
                return
        end
        if tonumber(row.action) == 4 then
                local accID = tonumber(row.user)
                if accID then
                        mysql:query_free("UPDATE accounts SET warns=IF(warns>0,warns-1,0) WHERE id=" .. accID)
                        local online = fix160MiscPlayerByAccountID(accID)
                        if online then
                                local cur = tonumber(getElementData(online, "warns")) or 0
                                exports.anticheat:changeProtectedElementDataEx(online, "warns",
                                        math.max(0, cur - 1), false)
                        end
                end
        end
        mysql:query_free("DELETE FROM adminhistory WHERE id=" .. id)
        outputChatBox("Admin history entry #" .. id .. " removed.", player, 0, 255, 0)
        fix160MiscLog(player, "REMOVEHISTORY #" .. id .. " action=" .. tostring(row.action)
                .. " user=" .. tostring(row.user), player)
end, false, false)

-- ================================================== bulk resource tools ====
-- admin-system is always skipped: it hosts these handlers (restarting it
-- mid-loop would kill the rest of the command)

local function fix160MiscIsSelf(res)
        return res == getThisResource() or getResourceName(res) == "admin-system"
end

local function fix160MiscBulkConfirm(player, cmd, what)
        local now = tonumber(os.time()) or 0
        local last = tonumber(getElementData(player, "fix160:bulkconfirm")) or 0
        if now - last <= 10 then
                exports.anticheat:changeProtectedElementDataEx(player, "fix160:bulkconfirm", 0, false)
                return true
        end
        exports.anticheat:changeProtectedElementDataEx(player, "fix160:bulkconfirm", now, false)
        outputChatBox("WARNING: /" .. cmd .. " will " .. what .. ".", player, 255, 0, 0)
        outputChatBox("Type /" .. cmd .. " again within 10 seconds to confirm.", player, 255, 194, 14)
        return false
end

addCommandHandler("restartallres", function(player, cmd)
        if not fix160MiscCheck(player, "admin.restartallres") then return end
        local all = getResources()
        local count = 0
        for _, res in ipairs(all) do
                if not fix160MiscIsSelf(res) and getResourceState(res) == "running" then
                        count = count + 1
                end
        end
        if count == 0 then
                outputChatBox("No running resources to restart.", player, 255, 194, 14)
                return
        end
        if not fix160MiscBulkConfirm(player, cmd, "restart " .. count
                .. " running resource(s) (admin-system is always skipped)") then
                return
        end
        fix160MiscLog(player, "RESTARTALLRES (" .. count .. " resources)", player)
        fix160MiscAdminAnnounce("[RESTARTALLRES]: " .. getPlayerName(player):gsub("_", " ")
                .. " issued a restart of all running resources.")
        local done = 0
        for _, res in ipairs(all) do
                if not fix160MiscIsSelf(res) and getResourceState(res) == "running" then
                        if restartResource(res) then done = done + 1 end
                end
        end
        outputChatBox("Restart issued for " .. done .. " of " .. count
                .. " resource(s) (admin-system skipped).", player, 0, 255, 0)
end, false, false)

addCommandHandler("stopallres", function(player, cmd)
        if not fix160MiscCheck(player, "admin.stopallres") then return end
        local all = getResources()
        local count = 0
        for _, res in ipairs(all) do
                if not fix160MiscIsSelf(res) and getResourceState(res) == "running" then
                        count = count + 1
                end
        end
        if count == 0 then
                outputChatBox("No running resources to stop.", player, 255, 194, 14)
                return
        end
        if not fix160MiscBulkConfirm(player, cmd, "STOP " .. count
                .. " running resource(s) (admin-system is always skipped; bring one"
                .. " back with /startres <name>)") then
                return
        end
        fix160MiscLog(player, "STOPALLRES (" .. count .. " resources)", player)
        fix160MiscAdminAnnounce("[STOPALLRES]: " .. getPlayerName(player):gsub("_", " ")
                .. " issued a stop of all running resources.")
        local done = 0
        for _, res in ipairs(all) do
                if not fix160MiscIsSelf(res) and getResourceState(res) == "running" then
                        if stopResource(res) then done = done + 1 end
                end
        end
        outputChatBox("Stopped " .. done .. " of " .. count
                .. " resource(s) (admin-system skipped). /startres <name> brings one back.",
                player, 0, 255, 0)
end, false, false)

-- ======================================================= map tool pair =====
-- a "map" resource = meta <info type="map">, readable via getResourceInfo

local function fix160MiscIsMap(res)
        local ok, typ = pcall(getResourceInfo, res, "type")
        return ok and tostring(typ or ""):lower() == "map"
end

addCommandHandler("startallmaps", function(player, cmd)
        if not fix160MiscCheck(player, "admin.startallmaps") then return end
        local todo = 0
        for _, res in ipairs(getResources()) do
                if fix160MiscIsMap(res) and getResourceState(res) == "stopped" then
                        todo = todo + 1
                end
        end
        if todo == 0 then
                outputChatBox("No stopped map resources.", player, 255, 194, 14)
                return
        end
        fix160MiscLog(player, "STARTALLMAPS (" .. todo .. " maps)", player)
        local done = 0
        for _, res in ipairs(getResources()) do
                if fix160MiscIsMap(res) and getResourceState(res) == "stopped" then
                        if startResource(res, true) then done = done + 1 end
                end
        end
        outputChatBox("Started " .. done .. " of " .. todo .. " map resource(s).", player, 0, 255, 0)
end, false, false)

addCommandHandler("stopallmaps", function(player, cmd)
        if not fix160MiscCheck(player, "admin.stopallmaps") then return end
        local todo = 0
        for _, res in ipairs(getResources()) do
                if fix160MiscIsMap(res) and getResourceState(res) == "running" then
                        todo = todo + 1
                end
        end
        if todo == 0 then
                outputChatBox("No running map resources.", player, 255, 194, 14)
                return
        end
        fix160MiscLog(player, "STOPALLMAPS (" .. todo .. " maps)", player)
        local done = 0
        for _, res in ipairs(getResources()) do
                if fix160MiscIsMap(res) and getResourceState(res) == "running" then
                        if stopResource(res) then done = done + 1 end
                end
        end
        outputChatBox("Stopped " .. done .. " of " .. todo
                .. " map resource(s) (start them again with /startallmaps).", player, 0, 255, 0)
end, false, false)

-- ======================================================= mass pkick ========

local function fix160MiscIsStaffPlayer(p)
        if not isElement(p) then return false end
        if getElementData(p, "rank:index") ~= nil then return true end
        if (tonumber(getElementData(p, "admin_level")) or 0) > 0 then return true end
        if (tonumber(getElementData(p, "supporter_level")) or 0) > 0 then return true end
        if (tonumber(getElementData(p, "account:gmlevel")) or 0) > 0 then return true end
        return false
end

addCommandHandler("pkickall", function(player, cmd, ...)
        if not fix160MiscCheck(player, "admin.pkickall") then return end
        local reason = table.concat({ ... }, " ")
        if reason == "" then
                fix160MiscSyntax(player, cmd, "[Reason]")
                return
        end
        local hidden = tonumber(getElementData(player, "hiddenadmin")) or 0
        local kicked, staffSkipped, unlogged = 0, 0, 0
        for _, target in ipairs(getElementsByType("player")) do
                if target == player then
                        -- never boot the caster
                elseif fix160MiscIsStaffPlayer(target) then
                        staffSkipped = staffSkipped + 1
                elseif tonumber(getElementData(target, "loggedin") or 0) ~= 1 then
                        unlogged = unlogged + 1
                else
                        local targetName = getPlayerName(target)
                        if type(addAdminHistory) == "function" then
                                addAdminHistory(target, player, reason, 1, 0)
                        end
                        fix160MiscLog(player, "PKICKALL " .. reason, target)
                        if hidden == 0 then
                                kickPlayer(target, player, reason)
                        else
                                kickPlayer(target, "Console", reason)
                        end
                        kicked = kicked + 1
                        outputDebugString("[Fix #160] pkickall: " .. tostring(targetName) .. " - " .. reason)
                end
        end
        if kicked > 0 then
                if hidden == 0 then
                        fix160MiscAdminAnnounce("[PKICKALL]: " .. getPlayerName(player):gsub("_", " ")
                                .. " booted " .. kicked .. " player(s) out of game.")
                else
                        fix160MiscAdminAnnounce("[PKICKALL]: " .. kicked .. " player(s) booted out of game.")
                end
                fix160MiscAdminAnnounce("[PKICKALL]: Reason: " .. reason .. ".")
        end
        outputChatBox("Booted " .. kicked .. " player(s) | skipped " .. staffSkipped
                .. " staff and " .. unlogged .. " not-logged-in.", player,
                kicked > 0 and 0 or 255, kicked > 0 and 255 or 194, 14)
        fix160MiscLog(player, "PKICKALL RESULT " .. kicked .. " kicked, " .. staffSkipped
                .. " staff skipped, " .. unlogged .. " not logged in (" .. reason .. ")", player)
end, false, false)

-- ======================================================== broadcast ========

addCommandHandler("bc", function(player, cmd, ...)
        if not fix160MiscCheck(player, "admin.bc_chat") then return end
        local msg = table.concat({ ... }, " ")
        if msg == "" then
                fix160MiscSyntax(player, cmd, "[Message]")
                return
        end
        for _, p in ipairs(getElementsByType("player")) do
                if tonumber(getElementData(p, "loggedin") or 0) == 1 then
                        outputChatBox("[BROADCAST] " .. msg, p, 255, 214, 60)
                end
        end
        fix160MiscLog(player, "BC " .. msg, player)
        fix160MiscAdminAnnounce("[BC]: " .. getPlayerName(player):gsub("_", " ")
                .. " broadcasted: " .. msg)
end, false, false)

-- =========================================================== badges ========
-- consumer: hud/c_nametags.lua reads the hud:badges element data list and
-- draws icons/<name>.png above the head (textures shipped in hud/icons/)
-- [Fix #160 / U1] display rule: the three RANK badges (admin_badge /
--   developer_badge / support_badge) are drawn from the element data
--   fix160.badgerights (the rights the target's rank holds, pushed by
--   staff_manager_bridge_s.lua pushFix160BadgeRights), NOT from hud:badges -
--   a hud:badges entry with one of those three names is ignored by the
--   nametag while the right decides. The commands below are unchanged: same
--   right gate, same toggle, same chat + log output.

local function fix160MiscToggleBadge(player, cmd, right, badgeName, query)
        if not fix160MiscCheck(player, right) then return end
        if not query then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / ID]")
                return
        end
        local target, targetName = fix160MiscTarget(player, query)
        if not target then return end
        local list = getElementData(target, "hud:badges")
        if type(list) ~= "table" then list = {} end
        local found = false
        for i = #list, 1, -1 do
                if list[i] == badgeName then
                        table.remove(list, i)
                        found = true
                end
        end
        if not found then
                list[#list + 1] = badgeName
        end
        exports.anticheat:changeProtectedElementDataEx(target, "hud:badges", list, true)
        outputChatBox((found and "Removed" or "Granted") .. " the '" .. badgeName
                .. "' badge for " .. targetName .. ".", player, 0, 255, 0)
        outputChatBox(found and ("Your '" .. badgeName .. "' badge was removed.")
                or ("You were granted the '" .. badgeName .. "' badge."), target, 255, 194, 14)
        fix160MiscLog(player, (found and "BADGE- " or "BADGE+ ") .. badgeName .. " -> " .. targetName, player)
end

addCommandHandler("togdevbadge", function(player, cmd, query)
        fix160MiscToggleBadge(player, cmd, "admin.badge.developer", "developer_badge", query)
end, false, false)

addCommandHandler("togsupportbadge", function(player, cmd, query)
        fix160MiscToggleBadge(player, cmd, "admin.badge.support", "support_badge", query)
end, false, false)

-- =================================================== applications edit =====
-- consumer: account/login-panel/server.lua gates login on accounts.appstate
-- (appstate < 3 = not accepted yet); the apps review flow writes the same
-- column (apps/app_manager_s.lua updateAppState)

local FIX160_APPSTATES = {
        [0] = "blocked (cannot log in until lifted)",
        [1] = "application in progress",
        [2] = "application submitted (under review)",
        [3] = "accepted (normal login)",
}

addCommandHandler("appstate", function(player, cmd, query, stateArg, ...)
        if not fix160MiscCheck(player, "applications.edit") then return end
        local state = tonumber(stateArg)
        if not query or not state or state < 0 or state > 3 or state % 1 ~= 0 then
                fix160MiscSyntax(player, cmd, "[Player / AccountID] [0-3] [reason]")
                outputChatBox("  0 = blocked, 1 = in progress, 2 = submitted, 3 = accepted",
                        player, 170, 170, 170)
                return
        end
        local row, online = fix160MiscAccount(query)
        if not row then
                outputChatBox("Account not found: " .. tostring(query), player, 255, 0, 0)
                return
        end
        local reason = table.concat({ ... }, " ")
        if not mysql:query_free("UPDATE accounts SET appstate=" .. state .. " WHERE id="
                .. tonumber(row.id) .. " LIMIT 1") then
                outputChatBox("Database error - appstate was not changed.", player, 255, 0, 0)
                return
        end
        outputChatBox("Set " .. tostring(row.username) .. "'s application state to " .. state
                .. " (" .. FIX160_APPSTATES[state] .. ")."
                .. (online and " Player is online - the login flow re-reads it on next login." or ""),
                player, 0, 255, 0)
        fix160MiscLog(player, "APPSTATE " .. tostring(row.username) .. " -> " .. state
                .. (reason ~= "" and (" (" .. reason .. ")") or ""), online or tostring(row.username))
end, false, false)

-- =============================================== special membership ========
-- the id is the one settings/settings_c.lua checks (special_membership:Premium,
-- premium-theme cleanup) and it is a normal F4 strip row, format
-- {id, state, icon, tip1, tip2} like hud/s_hud.lua pushDefaultItems

local FIX160_SPECIAL_ID = "special_membership:Premium"

local function fix160MiscSpecial(player, cmd, right, add, query)
        if not fix160MiscCheck(player, right) then return end
        if not query then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / ID]")
                return
        end
        local target, targetName = fix160MiscTarget(player, query)
        if not target then return end
        local items = getElementData(target, "hud:items")
        if type(items) ~= "table" then items = {} end
        local at = nil
        for i, row in ipairs(items) do
                if type(row) == "table" and row[1] == FIX160_SPECIAL_ID then
                        at = i
                        break
                end
        end
        if add and at then
                outputChatBox(targetName .. " already has the special membership.", player, 255, 194, 14)
                return
        end
        if not add and not at then
                outputChatBox(targetName .. " does not have the special membership.", player, 255, 194, 14)
                return
        end
        if add then
                items[#items + 1] = { FIX160_SPECIAL_ID, "on", "diamond", "Special Membership", "Premium" }
        else
                table.remove(items, at)
        end
        exports.anticheat:changeProtectedElementDataEx(target, "hud:items", items, true)
        outputChatBox((add and "Added" or "Removed") .. " the special membership for "
                .. targetName .. ".", player, 0, 255, 0)
        fix160MiscLog(player, (add and "SPECIAL+ " or "SPECIAL- ") .. targetName, player)
end

addCommandHandler("addspecial", function(player, cmd, query)
        fix160MiscSpecial(player, cmd, "special_membership.add", true, query)
end, false, false)

addCommandHandler("removespecial", function(player, cmd, query)
        fix160MiscSpecial(player, cmd, "special_membership.remove", false, query)
end, false, false)

-- ============================================================ levels =======
-- consumer: exports "level-system"/addExp (s_level.lua, cap 5000 per call,
-- required exp = level^2 * 50 - the loop below chunks around the cap)

local function fix160MiscAddExp(target, amount, reason)
        local okCall, ok, lvl, exp = pcall(function()
                return exports["level-system"]:addExp(target, amount, reason)
        end)
        if not okCall or not ok then
                return nil, nil
        end
        return lvl, exp
end

addCommandHandler("giveexp", function(player, cmd, query, amountArg, ...)
        if not fix160MiscCheck(player, "level.give_exp") then return end
        local amount = tonumber(amountArg)
        if not query or not amount or amount < 1 or amount % 1 ~= 0 then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / ID] [amount] [reason]")
                return
        end
        amount = math.floor(amount)
        local target, targetName = fix160MiscTarget(player, query)
        if not target then return end
        if not tonumber(getElementData(target, "character:id")) then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end
        local reason = table.concat({ ... }, " ")
        if reason == "" then reason = "Staff grant" end
        local left, given, lvl, exp = amount, 0, nil, nil
        while left > 0 do
                local chunk = math.min(left, 5000)
                local l, e = fix160MiscAddExp(target, chunk, reason)
                if l == nil then
                        outputChatBox("level-system/addExp failed after " .. given
                                .. " exp (is level-system running?).", player, 255, 0, 0)
                        return
                end
                given = given + chunk
                left = left - chunk
                lvl, exp = l, e
        end
        outputChatBox("Gave " .. given .. " exp to " .. targetName .. " - now level "
                .. tostring(lvl) .. " (" .. tostring(exp) .. "/" .. ((tonumber(lvl) or 1) ^ 2 * 50)
                .. " toward next).", player, 0, 255, 0)
        fix160MiscLog(player, "GIVEEXP " .. targetName .. " +" .. given .. " (" .. reason
                .. ") -> level " .. tostring(lvl), player)
end, false, false)

addCommandHandler("levelboost", function(player, cmd, query, levelsArg)
        if not fix160MiscCheck(player, "level.boost") then return end
        local levels = tonumber(levelsArg)
        if not query or not levels or levels < 1 or levels > 10 or levels % 1 ~= 0 then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / ID] [levels 1-10]")
                return
        end
        local target, targetName = fix160MiscTarget(player, query)
        if not target then return end
        local cid = tonumber(getElementData(target, "character:id"))
        if not cid then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end
        for _ = 1, levels do
                local row = mysql:query_fetch_assoc("SELECT level, exp FROM level_system WHERE character_id=" .. cid)
                local lvl = row and tonumber(row.level) or 1
                local exp = row and tonumber(row.exp) or 0
                local need = (lvl * lvl * 50) - exp
                if need <= 0 then need = 1 end
                while need > 0 do
                        local chunk = math.min(need, 5000)
                        local l = fix160MiscAddExp(target, chunk, "levelboost")
                        if l == nil then
                                outputChatBox("level-system/addExp failed at level " .. lvl
                                        .. " (is level-system running?).", player, 255, 0, 0)
                                return
                        end
                        need = need - chunk
                end
        end
        local row = mysql:query_fetch_assoc("SELECT level, exp FROM level_system WHERE character_id=" .. cid)
        local lvl = row and tonumber(row.level) or "?"
        outputChatBox(targetName .. " boosted " .. levels .. " level(s) - now level "
                .. tostring(lvl) .. ".", player, 0, 255, 0)
        fix160MiscLog(player, "LEVELBOOST " .. targetName .. " +" .. levels .. " -> level "
                .. tostring(lvl), player)
end, false, false)

-- ======================================================== hidden logs ======
-- [REPURPOSED - admin-logs task, owner request] /hiddenlogs used to list and
-- tail the files of the logs resource (resources/logs/hiddenlogs/*.log) with
-- optional [file.log] [lines] arguments. That viewer (and both arguments) is
-- gone: the command is now a TOGGLE of the GLOBAL hide of this admin's OWN
-- usage. While it is ON every command he uses produces NO log line for
-- ANYONE - including himself - while he keeps seeing the other admins' lines
-- normally. Feedback is local (to him) only, and the command itself is never
-- logged (admin-logs keeps it in its never-logged list).
--
-- Right: admin.hide_logs, enforced right here. NOTE (reported, not edited
-- here): staff_manager/gates_fix160_task7.lua still gates the command to
-- hidden.logs, so a ranked staff member needs BOTH rights to reach this
-- handler - the gate table belongs to the staff_manager agent.
--
-- State key "adminlogs:hide_global" (server-only element data) is owned and
-- read by the admin-logs resource, which also wipes it when the player quits.
addCommandHandler("hiddenlogs", function(player, cmd)
        if not fix160MiscCheck(player, "admin.hide_logs") then return end
        local on = (tonumber(getElementData(player, "adminlogs:hide_global")) or 0) ~= 1
        -- synchronize = false: the flag never reaches a client, only the
        -- admin-logs feed reads it server-side
        setElementData(player, "adminlogs:hide_global", on and 1 or 0, false)
        outputChatBox(on and "hidden logs on" or "hidden logs off", player, 255, 194, 14)
end, false, false)

-- ========================================================== features =======
-- consumer: donators exports givePlayerPerk (new row, expirationDate =
-- NOW()+interval <days> day, 0 GC cost) / updatePerkValue (already owned)

addCommandHandler("givefeature", function(player, cmd, query, perkArg, valueArg, daysArg)
        if not fix160MiscCheck(player, "feature.give") then return end
        local perkID = tonumber(perkArg)
        local days = tonumber(daysArg)
        if not query or not perkID or perkID < 1 or perkID > 38 or perkID % 1 ~= 0
                or not days or days < 1 then
                fix160MiscSyntax(player, cmd, "[Player Partial Nick / ID] [perkID 1-38] [value] [days]")
                outputChatBox("  value defaults to 1; days = duration (use 3650 for a permanent grant)",
                        player, 170, 170, 170)
                return
        end
        local value = fix160MiscTrim(valueArg)
        if value == "" then value = "1" end
        local target, targetName = fix160MiscTarget(player, query)
        if not target then return end
        local owned = false
        pcall(function() owned = exports.donators:hasPlayerPerk(target, perkID) and true or false end)
        local okCall, ok, msg
        if owned then
                okCall, ok, msg = pcall(function()
                        return exports.donators:updatePerkValue(target, perkID, value)
                end)
        else
                okCall, ok, msg = pcall(function()
                        return exports.donators:givePlayerPerk(target, perkID, value, days, 0)
                end)
        end
        if not okCall or not ok then
                outputChatBox("Failed to give perk #" .. perkID .. ": "
                        .. tostring(msg or "denied by the perk flow"), player, 255, 0, 0)
                return
        end
        outputChatBox((owned and "Updated" or "Gave") .. " feature #" .. perkID .. " (value "
                .. value .. (owned and "" or (", " .. days .. " day(s)")) .. ") to " .. targetName
                .. (type(msg) == "string" and ("  - " .. msg) or "") .. ".", player, 0, 255, 0)
        fix160MiscLog(player, "GIVEFEATURE " .. targetName .. " perk#" .. perkID
                .. " value=" .. value .. (owned and " (updated)"
                or (" days=" .. days)), player)
end, false, false)
