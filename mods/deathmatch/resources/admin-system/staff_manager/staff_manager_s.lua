--[[ ------------------------------------------------------------------------
        Vortex Staff System — server (restores the lost rp-admin server side).

        The original server script did not survive the backup; every event
        the decompiled client triggers is rebuilt here against the SAME
        schema the client expects:

          staff_roles            ID / LevelName / Rights(JSON) / Color(JSON)
          staff_role_members     RoleID / AccountID
          staff_rank_changelogs  Date / cType / Username / FromR / ToR / By_

        Seeded ranks (user spec, in order) with the exact colors:

          Tester / Trial Support / Support ............... orange
          Trial Moderator / Moderator / Senior Moderator .. dark orange
          Trial Administrator .. Super Administrator ...... blue shades
          Lead Administrator ............................. Vortex purple
          Administrative Director ........................ yellow
          Junior Management .............................. wood
          Senior Management .............................. pink
          Server Management .............................. pink-burgundy
          Head Management ................................ burgundy
          Chief Management ............................... darkest red
          Vice Founder / Founder ........................ reds
          Diverloper ..................................... blue
          Owner .......................................... bright red

        Permissions: every rank inherits everything from the ranks above it
        plus its own extras (a sensible admin ladder from view-only checks
        up to full ownership). All names come from the original AllRights
        list (staff_manager_rights.lua).

        Gates:
          open panel      canPlayerAccessStaffManager (shared helper)
          edit members    integration:isPlayerSeniorAdmin  (admin >= 3)
          edit ranks      integration:isPlayerLeadAdmin    (admin >= 4)

        NOTE: this system manages its own role database + changelogs. It
        does NOT rewrite the legacy accounts.admin ladder that powers the
        integration exports, so existing in-game powers stay untouched.
-------------------------------------------------------------------------- ]]

local mysql = exports.mysql

-- ============================================================================
-- Rank seed — { name, color, extras } — rights accumulate top to bottom
-- ============================================================================

local RANK_SEED = {
        { name = "Tester",                  color = { 255, 140,   0, 255}, extras = {
                "admin.check", "admin.checkveh", "admin.checkint", "admin.checkc",
                "admin.history", "admin.show_jails", "admin.showbans", "admin.resstate",
                "items.list", "shops.list", "admin.showalts",
        }},
        { name = "Trial Support",           color = { 255, 140,   0, 255}, extras = {
                "support.chat /g", "admin.chat /a", "access.reports", "admin.warn",
                "admin.mute", "admin.unmute", "admin.voice_mute", "admin.voice_unmute",
                "admin.freeze", "admin.unfreeze", "admin.jail", "admin.unjail",
                "admin.goto", "admin.gethere", "admin.sendto", "admin.revive",
                "admin.flip", "admin.unflip", "admin.fixveh", "admin.fuelveh",
        }},
        { name = "Support",                 color = { 255, 140,   0, 255}, extras = {
                "admin.pkick", "admin.eject", "admin.disappear", "admin.recon",
                "admin.uncuffs", "disarm", "admin.ooc",
        }},
        { name = "Trial Moderator",         color = { 204,  85,   0, 255}, extras = {
                "admin.ban", "admin.showban", "admin.unban", "admin.clearchatforall",
                "admin.bc_chat",
        }},
        { name = "Moderator",               color = { 204,  85,   0, 255}, extras = {
                "admin.banip", "admin.banserial", "admin.banaccount", "admin.sendtoplace",
                "admin.gotoplace", "admin.gotoint", "admin.gotoped", "admin.gotoveh",
                "admin.setplayerdim", "admin.setplayerint", "admin.xyz", "admin.pos",
                "admin.destroyveh", "admin.enterveh", "admin.sendtoveh", "admin.sendvehto",
        }},
        { name = "Senior Moderator",        color = { 204,  85,   0, 255}, extras = {
                "admin.getveh", "admin.giveveh", "admin.setweather", "admin.settime",
                "admin.setfpslimit", "admin.setgametype", "admin.ann",
                "admin.highchat /h", "admin.staffchat /st",
        }},
        { name = "Trial Administrator",     color = { 102, 178, 255, 255}, extras = {
                "admin.setplayermoney", "admin.giveplayermoney", "admin.takeplayermoney",
                "admin.sethp", "admin.skin", "admin.forcepayday", "giveitem", "givekey",
                "givelicense", "admin.isStaff",
        }},
        { name = "Administrator",           color = {  52, 152, 219, 255}, extras = {
                "admin.giveallmoney", "admin.superman", "admin.freecam",
                "admin.restartres", "admin.stopres", "admin.startres", "admin.changename",
                "vehicle.fixallveh", "vehicle.respawnallveh", "vehicle.setcolor",
                "vehicle.park", "admin.isAdmin",
        }},
        { name = "Senior Administrator",    color = {  32, 112, 178, 255}, extras = {
                "admin.pkickall", "admin.setserverpassword", "admin.forceapp",
                "admin.unforceapp", "admin.makefire", "admin.removefire",
                "admin.cleanstreets", "admin.setrain", "admin.setwave",
                "admin.hide_admin", "admin.hide_logs",
        }},
        { name = "Super Administrator",     color = {  16,  72, 130, 255}, extras = {
                "accounts.changepass", "accounts.changeemail", "accounts.changeserial",
                "accounts.changeid", "accounts.changeaccountname", "owner.checkid",
                "owner.checkaccount", "owner.checkserial", "owner.checkemail",
                "admin.check", "admin.clearhistory", "admin.removehistory",
                "admin.remove_gov", "admin.badge",
        }},
        { name = "Lead Administrator",      color = { 144,  50, 250, 255}, extras = {
                "admin.manager.panel", "admin.manager.editmembers", "admin.manager.editranks",
                "admin.manager.resources", "admin.restartallres", "admin.stopallres",
                "admin.startallmaps", "admin.stopallmaps", "duty.adminduty",
                "duty.showallonduty", "admin.showsettings", "admin.setsettings",
                "admin.getsettings", "hidden.logs", "debug", "dev.fullstatus",
                "admin.badge.developer",
        }},
        { name = "Administrative Director", color = { 255, 215,   0, 255}, extras = {
                "admin.playas", "admin.fakeme", "owner.changemode", "owner.setactivestatus",
                "admin.clearhistoryforallonline", "admin.staffchat /st",
        }},
        { name = "Junior Management",       color = { 160, 101,  54, 255}, extras = {
                "makefaction", "removefaction", "setfaction", "setfactionleader",
                "setfactioncolor", "setfactionname", "setfactiontype", "makeveh",
                "delveh", "editvehicle", "setvehowner", "setvehfaction", "setvehjob",
                "property.make", "property.delete", "property.setowner", "makeatm",
                "makeshop", "makeped", "delped", "editped", "makegeneric", "makegate",
                "makephone", "addint", "deleteint", "setintid", "setintowner",
                "setintprice", "setintforsale", "setintenterance", "setintname",
                "whitelist.add", "whitelist.remove", "blacklist.add", "blacklist.remove",
        }},
        { name = "Senior Management",       color = { 255, 105, 180, 255}, extras = {
                "web.reports", "web.blacklist", "web.whitelist", "web.controlpanel",
                "web.support.tickets", "web.docs.edit", "web.staff.members",
                "web.staff.changelog", "web.staff.reports", "web.factions", "web.users",
                "web.characters", "web.bans", "web.history", "web.rules_categories",
                "web.rules", "web.applications", "applications.edit", "applications.access",
                "special_membership.add", "special_membership.remove", "level.give_exp",
                "level.boost", "feature.give",
        }},
        { name = "Server Management",       color = { 199,  84, 124, 255}, extras = {
                "owner.giverole", "owner.takerole", "places.access", "places.add",
                "places.remove", "radiostations.manager", "editor.editObjects",
                "editor.removeObjects", "editor.savemap", "duplicate.keys", "keys.delete",
                "editObjectProperties",
        }},
        { name = "Head Management",         color = { 128,   0,  32, 255}, extras = {
                "owner.removeaccount", "owner.removecharacter", "factions.clearlogs",
                "faction.clearinvoices", "interior.lock", "interior.deleteitems",
                "intlib.add", "intlib.remove", "vehicle.restore_destroyed", "vehicle.hide",
                "vehicle.unhide", "vehicle.hideallnparkveh", "vehicle.setarmored",
                "setvehtint",
        }},
        { name = "Chief Management",        color = { 120,   0,  10, 255}, extras = {
                "ownership", -- + everything remaining (filled below)
        }},
        { name = "Vice Founder",            color = { 170,   0,   0, 255}, extras = {} },
        { name = "Founder",                 color = { 220,   0,   0, 255}, extras = {} },
        { name = "Diverloper",              color = {   0, 120, 255, 255}, extras = {} },
        { name = "Owner",                   color = { 255,   0,   0, 255}, extras = {} },
}

-- Chief Management and above get the full rights list
local FULL_RIGHTS_FROM = "Chief Management"

-- ============================================================================
-- tables + seed
-- ============================================================================

local function ensureTables()
        mysql:query_free([[CREATE TABLE IF NOT EXISTS staff_roles (
                ID INT NOT NULL AUTO_INCREMENT,
                LevelName VARCHAR(64) NOT NULL,
                Rights TEXT,
                Color TEXT,
                PRIMARY KEY (ID))]])
        mysql:query_free([[CREATE TABLE IF NOT EXISTS staff_role_members (
                RoleID INT NOT NULL,
                AccountID INT NOT NULL,
                UNIQUE KEY ra (RoleID, AccountID))]])
        mysql:query_free([[CREATE TABLE IF NOT EXISTS staff_rank_changelogs (
                ID INT NOT NULL AUTO_INCREMENT,
                Date DATETIME,
                cType VARCHAR(32),
                Username VARCHAR(64),
                FromR VARCHAR(64),
                ToR VARCHAR(64),
                By_ VARCHAR(64),
                PRIMARY KEY (ID))]])
end

local function seedRanks()
        local row = mysql:query_fetch_assoc("SELECT COUNT(*) AS n FROM staff_roles")
        if not row or tonumber(row.n) > 0 then return end
        outputDebugString("[Vortex Staff] seeding the default rank ladder...")

        -- cumulative union of rights
        local granted = {}
        local allGranted = false
        for _, rank in ipairs(RANK_SEED) do
                if rank.name == FULL_RIGHTS_FROM then
                        allGranted = true
                end
                if not allGranted then
                        for _, right in ipairs(rank.extras) do
                                granted[right] = true
                        end
                else
                        for _, right in ipairs(AllRights) do
                                granted[right] = true
                        end
                end
                local rights = {}
                for right in pairs(granted) do
                        rights[#rights + 1] = right
                end
                table.sort(rights)
                local rightsMap = {}
                for _, right in ipairs(rights) do
                        rightsMap[right] = true
                end
                mysql:query_free("INSERT INTO staff_roles (LevelName, Rights, Color) VALUES ('"
                        .. mysql:escape_string(rank.name) .. "', '"
                        .. mysql:escape_string(toJSON(rightsMap)) .. "', '"
                        .. mysql:escape_string(toJSON(rank.color)) .. "')")
        end
        outputDebugString("[Vortex Staff] seeded " .. #RANK_SEED .. " ranks.")
end

addEventHandler("onResourceStart", resourceRoot, function()
        ensureTables()
        seedRanks()
end)

-- ============================================================================
-- permission gates
-- ============================================================================

local function hasEditMembers(player)
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function hasEditRanks(player)
        return exports.integration:isPlayerLeadAdmin(player) and true or false
end

-- ============================================================================
-- data assembly
-- ============================================================================

local function fetchLevels()
        local levels = {}
        local q = mysql:query("SELECT ID, LevelName, Rights, Color FROM staff_roles ORDER BY ID ASC")
        if not q then
                -- [V7] loud failure: a dead query used to silently empty the panel
                outputDebugString("[Vortex Staff] DB query FAILED: staff_roles SELECT - run /staffdb", 1)
                return levels
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                levels[#levels + 1] = {
                        ID = tonumber(row.ID),
                        LevelName = row.LevelName,
                        Rights = row.Rights or "{}",
                        Color = row.Color or "[[255,255,255,255]]",
                }
        end
        mysql:free_result(q)
        return levels
end

local function fetchStaffReport()
        local out = {}
        local q = mysql:query([[
                SELECT a.id, a.username, m.RoleID
                FROM staff_role_members m
                JOIN accounts a ON a.id = m.AccountID
                GROUP BY a.id ORDER BY a.username ASC]])
        if not q then
                -- [V7] loud failure
                outputDebugString("[Vortex Staff] DB query FAILED: staff report JOIN - run /staffdb", 1)
                return out
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                local report = {
                        username = row.username,
                        login_time = false,
                        logout_time = false,
                        total_attendance_time = 0,
                        jails = 0,
                        bans = 0,
                        reports = 0,
                }
                -- best-effort activity numbers from the shared log table; every query
                -- is guarded because owl_logs may not exist on fresh installs
                pcall(function()
                        local logs = getResourceFromName("logs")
                        if not logs then return end
                        local accID = tonumber(row.AccountID)
                        local stats = mysql:query_fetch_assoc([[
                                SELECT
                                        SUM(CASE WHEN data LIKE '%JAIL%' THEN 1 ELSE 0 END) AS jails,
                                        SUM(CASE WHEN (data LIKE '%BAN%' AND data NOT LIKE '%UNBAN%') THEN 1 ELSE 0 END) AS bans,
                                        SUM(CASE WHEN action = '38' THEN 1 ELSE 0 END) AS reports
                                FROM owl_logs
                                WHERE source = 'ac]] .. accID .. [[' AND action = '4'
                                        AND DATE(time) = CURDATE()]])
                        if stats then
                                report.jails = tonumber(stats.jails) or 0
                                report.bans = tonumber(stats.bans) or 0
                                report.reports = tonumber(stats.reports) or 0
                        end
                end)
                out[#out + 1] = report
        end
        mysql:free_result(q)
        return out
end

local function sendFullData(player)
        local levels = fetchLevels()
        -- staff members with feedback + report counts (same sources the old
        -- staff manager used: accounts.adminreports + feedbacks.rating)
        local admins = {}
        local roleMembers = {}
        local q = mysql:query([[
                SELECT a.id, a.username, a.adminreports, m.RoleID,
                        COALESCE(ROUND(AVG(f.rating), 3), 0) AS FeedbackRating,
                        COUNT(f.id) AS FeedbackCount
                FROM staff_role_members m
                JOIN accounts a ON a.id = m.AccountID
                LEFT JOIN feedbacks f ON f.staff_id = a.id
                GROUP BY a.id ORDER BY m.RoleID ASC, a.username ASC]])
        if not q then
                -- [V7] loud failure
                outputDebugString("[Vortex Staff] DB query FAILED: admins JOIN - run /staffdb", 1)
                if isElement(player) then
                        outputChatBox("Staff system: database error loading staff list (/staffdb).", player, 255, 80, 80)
                end
                triggerClientEvent(player, "rpadmin:sendSQLInformations", player,
                        levels, {}, {}, {}, {}, {})
                return levels, admins
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                admins[#admins + 1] = {
                        AdminID = tonumber(row.RoleID),
                        Account = row.username,
                        ReportsCount = tonumber(row.adminreports) or 0,
                        FeedbackRating = tonumber(row.FeedbackRating) or 0,
                        FeedbackCount = tonumber(row.FeedbackCount) or 0,
                }
                roleMembers[#roleMembers + 1] = {
                        RoleID = tonumber(row.RoleID),
                        Account = row.username,
                }
        end
        mysql:free_result(q)

        local changelogs = {}
        local cq = mysql:query([[
                SELECT DATE_FORMAT(Date, '%Y-%m-%d %H:%i:%s') AS Date,
                        cType, Username, FromR, ToR, By_
                FROM staff_rank_changelogs ORDER BY ID DESC LIMIT 200]])
        if not cq then
                -- [V7] loud failure (changelogs are non-fatal: still push the rest)
                outputDebugString("[Vortex Staff] DB query FAILED: changelogs SELECT - run /staffdb", 1)
        end
        while cq do
                local row = cq and mysql:fetch_assoc(cq) or nil
                if not row then break end
                changelogs[#changelogs + 1] = row
        end
        if cq then mysql:free_result(cq) end

        triggerClientEvent(player, "rpadmin:sendSQLInformations", player,
                levels, admins, changelogs, {}, roleMembers, fetchStaffReport())
        return levels, admins
end

-- ============================================================================
-- panel open
-- ============================================================================

local function sendPanel(player)
        if not canPlayerAccessStaffManager(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                return false
        end
        local editMembers = hasEditMembers(player)
        local editRanks = hasEditRanks(player)
        local levels = fetchLevels()
        -- reuse the same query used by sendFullData for the first paint
        local admins, roleMembers = {}, {}
        local q = mysql:query([[
                SELECT a.id, a.username, a.adminreports, m.RoleID,
                        COALESCE(ROUND(AVG(f.rating), 3), 0) as FeedbackRating,
                        COUNT(f.id) AS FeedbackCount
                FROM staff_role_members m
                JOIN accounts a ON a.id = m.AccountID
                LEFT JOIN feedbacks f ON f.staff_id = a.id
                GROUP BY a.id ORDER BY m.RoleID ASC, a.username ASC]])
        if not q then
                -- [V7] loud failure: panel still opens, but with a clear message
                outputDebugString("[Vortex Staff] DB query FAILED: panel admins JOIN - run /staffdb", 1)
                outputChatBox("Staff system: database error - run /staffdb to diagnose.", player, 255, 80, 80)
                triggerClientEvent(player, "rpadmin:showPanel", player,
                        editMembers, editRanks, editRanks,
                        { levels = levels, admins = {}, changelogs = {},
                          role_members = {}, staff_report = {} })
                return false
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                admins[#admins + 1] = {
                        AdminID = tonumber(row.RoleID),
                        Account = row.username,
                        ReportsCount = tonumber(row.adminreports) or 0,
                        FeedbackRating = tonumber(row.FeedbackRating) or 0,
                        FeedbackCount = tonumber(row.FeedbackCount) or 0,
                }
                roleMembers[#roleMembers + 1] = {
                        RoleID = tonumber(row.RoleID),
                        Account = row.username,
                }
        end
        mysql:free_result(q)

        local changelogs = {}
        local cq = mysql:query([[
                SELECT DATE_FORMAT(Date, '%Y-%m-%d %H:%i:%s') AS Date,
                        cType, Username, FromR, ToR, By_
                FROM staff_rank_changelogs ORDER BY ID DESC LIMIT 200]])
        while true do
                local row = mysql:fetch_assoc(cq)
                if not row then break end
                changelogs[#changelogs + 1] = row
        end
        mysql:free_result(cq)

        triggerClientEvent(player, "rpadmin:showPanel", player,
                editMembers, editRanks, editRanks,
                { levels = levels, admins = admins, changelogs = changelogs,
                  role_members = roleMembers, staff_report = fetchStaffReport() })
        return true
end

addEvent("rpadmin:requestPanel", true)
addEventHandler("rpadmin:requestPanel", root, function()
        sendPanel(source)
end)

-- [Vortex fix] /staffs is handled CLIENT-side (staff_manager_c.lua) which
-- asks the server through rpadmin:requestPanel. Registering it HERE as well
-- made one typed /staffs fire BOTH paths -> two rpadmin:showPanel events ->
-- the client TOGGLE showed the panel then instantly hid it (the "<1 second
-- and it disappears" bug). One command, one toggle.

-- ============================================================================
-- mutations
-- ============================================================================

local function addChangelog(cType, username, fromRank, toRank)
        local by = "System"
        if isElement(client) and getElementType(client) == "player" then
                by = getElementData(client, "account:username")
                        or getPlayerName(client) or "Unknown"
        end
        mysql:query_free(string.format(
                "INSERT INTO staff_rank_changelogs (Date, cType, Username, FromR, ToR, By_) VALUES (NOW(), '%s', '%s', '%s', '%s', '%s')",
                mysql:escape_string(tostring(cType)),
                mysql:escape_string(tostring(username)),
                mysql:escape_string(tostring(fromRank or "-")),
                mysql:escape_string(tostring(toRank or "-")),
                mysql:escape_string(tostring(by))))
end

local function refresh(player)
        if isElement(player) then
                sendFullData(player)
        end
end

-- add a staff member to a rank
addEvent("rpadmin:addNewAdmin", true)
addEventHandler("rpadmin:addNewAdmin", root, function(account, levelID, levelName)
        if not hasEditMembers(client) then return end
        if not account or not tonumber(levelID) then return end
        local user = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE username='"
                .. mysql:escape_string(tostring(account)) .. "'")
        if not user then
                outputChatBox("Account not found: " .. tostring(account), client, 255, 0, 0)
                return
        end
        levelID = tonumber(levelID)
        local oldName = "-"
        local old = mysql:query_fetch_assoc([[
                SELECT m.RoleID FROM staff_role_members m
                WHERE m.AccountID = ]] .. tonumber(user.id) .. [[ LIMIT 1]])
        if old then
                local levels = fetchLevels()
                for _, level in ipairs(levels) do
                        if tonumber(level.ID) == tonumber(old.RoleID) then
                                oldName = level.LevelName
                        end
                end
                mysql:query_free("UPDATE staff_role_members SET RoleID=" .. levelID
                        .. " WHERE AccountID=" .. tonumber(user.id))
        else
                mysql:query_free("INSERT INTO staff_role_members (RoleID, AccountID) VALUES ("
                        .. levelID .. ", " .. tonumber(user.id) .. ")")
        end
        addChangelog("Promotion", user.username, oldName, tostring(levelName or "-"))
        outputChatBox("Staff added: " .. user.username .. " -> " .. tostring(levelName), client, 0, 255, 0)
        refresh(client)
        -- Vortex bridge: push the new rank onto the target immediately if online
        if type(refreshPlayerRank) == "function" then
                for _, p in ipairs(getElementsByType("player")) do
                        if tonumber(getElementData(p, "account:id")) == tonumber(user.id) then
                                refreshPlayerRank(p)
                                break
                        end
                end
        end
end)

-- remove a staff member (by username)
addEvent("rpadmin:removeAdmin", true)
addEventHandler("rpadmin:removeAdmin", root, function(account)
        if not hasEditMembers(client) then return end
        if not account then return end
        local user = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE username='"
                .. mysql:escape_string(tostring(account)) .. "'")
        if not user then
                outputChatBox("Account not found: " .. tostring(account), client, 255, 0, 0)
                return
        end
        local oldName = "-"
        local old = mysql:query_fetch_assoc([[
                SELECT m.RoleID FROM staff_role_members m
                WHERE m.AccountID = ]] .. tonumber(user.id) .. [[ LIMIT 1]])
        if old then
                local levels = fetchLevels()
                for _, level in ipairs(levels) do
                        if tonumber(level.ID) == tonumber(old.RoleID) then
                                oldName = level.LevelName
                        end
                end
        end
        mysql:query_free("DELETE FROM staff_role_members WHERE AccountID=" .. tonumber(user.id))
        addChangelog("Demotion", user.username, oldName, "Player")
        outputChatBox("Staff removed: " .. user.username, client, 0, 255, 0)
        refresh(client)
        -- Vortex bridge: drop the target's live rank data if online
        if type(refreshPlayerRank) == "function" then
                for _, p in ipairs(getElementsByType("player")) do
                        if tonumber(getElementData(p, "account:id")) == tonumber(user.id) then
                                refreshPlayerRank(p)
                                break
                        end
                end
        end
end)

-- create a rank
addEvent("rpadmin:addAdminLevel", true)
addEventHandler("rpadmin:addAdminLevel", root, function(rankName)
        if not hasEditRanks(client) then return end
        if not rankName or rankName == "" then return end
        local exists = mysql:query_fetch_assoc("SELECT ID FROM staff_roles WHERE LevelName='"
                .. mysql:escape_string(tostring(rankName)) .. "'")
        if exists then
                outputChatBox("A rank with this name already exists.", client, 255, 0, 0)
                return
        end
        mysql:query_free("INSERT INTO staff_roles (LevelName, Rights, Color) VALUES ('"
                .. mysql:escape_string(tostring(rankName)) .. "', '{}', '"
                .. mysql:escape_string(toJSON({ 255, 255, 255, 255 })) .. "')")
        addChangelog("Rank Added", tostring(rankName), "-", "-")
        refresh(client)
end)

-- delete a rank
addEvent("rpadmin:removeAdminLevel", true)
addEventHandler("rpadmin:removeAdminLevel", root, function(levelID)
        if not hasEditRanks(client) then return end
        if not tonumber(levelID) then return end
        levelID = tonumber(levelID)
        local row = mysql:query_fetch_assoc("SELECT LevelName FROM staff_roles WHERE ID=" .. levelID)
        if not row then return end
        mysql:query_free("DELETE FROM staff_roles WHERE ID=" .. levelID)
        mysql:query_free("DELETE FROM staff_role_members WHERE RoleID=" .. levelID)
        addChangelog("Rank Deleted", row.LevelName, "-", "-")
        refresh(client)
        -- Vortex bridge: former members lost their rank
        if type(refreshAllPlayerRanks) == "function" then
                refreshAllPlayerRanks()
        end
end)

-- rename a rank
addEvent("rpadmin:changeAdminLevelName", true)
addEventHandler("rpadmin:changeAdminLevelName", root, function(levelID, newName)
        if not hasEditRanks(client) then return end
        if not tonumber(levelID) or not newName or newName == "" then return end
        local row = mysql:query_fetch_assoc("SELECT LevelName FROM staff_roles WHERE ID="
                .. tonumber(levelID))
        if not row then return end
        mysql:query_free("UPDATE staff_roles SET LevelName='"
                .. mysql:escape_string(tostring(newName)) .. "' WHERE ID=" .. tonumber(levelID))
        addChangelog("Rank Renamed", row.LevelName, row.LevelName, tostring(newName))
        refresh(client)
end)

-- save rights + color (the UIKit panel path) + legacy alias. The panel
-- sends the CHECKED rights set and the original replaced the stored set
-- with exactly that, so both paths share one implementation.
local function updateRoleImpl(sender, levelID, rights, color)
        if not hasEditRanks(sender) then return end
        if not tonumber(levelID) then return end
        levelID = tonumber(levelID)
        local row = mysql:query_fetch_assoc("SELECT LevelName FROM staff_roles WHERE ID=" .. levelID)
        if not row then return end

        if type(rights) ~= "table" then
                rights = {}
        end
        if type(color) ~= "table" or #color < 3 then
                color = { 255, 255, 255, 255 }
        end

        mysql:query_free("UPDATE staff_roles SET Rights='"
                .. mysql:escape_string(toJSON(rights)) .. "', Color='"
                .. mysql:escape_string(toJSON(color)) .. "' WHERE ID=" .. levelID)
        addChangelog("Rank Edited", row.LevelName, "-",
                ("#%02X%02X%02X"):format(color[1], color[2], color[3]))
        outputChatBox("Rank saved: " .. row.LevelName, sender, 0, 255, 0)
        refresh(sender)
        -- Vortex bridge: live-update colors/rights for every online member
        if type(refreshRankMembers) == "function" then
                refreshRankMembers(levelID)
        end
end

addEvent("rpadmin:updateRole", true)
addEventHandler("rpadmin:updateRole", root, function(levelID, _, rights, color)
        updateRoleImpl(client, levelID, rights, color)
end)

addEvent("rpadmin:saveLevelRights", true)
addEventHandler("rpadmin:saveLevelRights", root, function(levelID, rights, color)
        updateRoleImpl(source, levelID, rights, color)
end)
