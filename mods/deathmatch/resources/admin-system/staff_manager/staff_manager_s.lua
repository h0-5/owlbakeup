--[[ ------------------------------------------------------------------------
        Vortex Staff System — server (restores the lost rp-admin server side).

        The original server script did not survive the backup; every event
        the decompiled client triggers is rebuilt here against the SAME
        schema the client expects:

          staff_roles            ID / LevelName / Rights(JSON) / Color(JSON)
          staff_role_members     RoleID / AccountID
          staff_rank_changelogs  Date / cType / Username / FromR / ToR / By_
          [TEAMS] staff_teams         id / name / rights(CSV) / createdby / created
          [TEAMS] staff_team_members  id / teamid / account_id / addedby / date

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
                "admin.highstaffchat", "admin.staffchat /st",
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
                "property.delete", "property.setowner", "makeatm",
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

-- [Fix #18] MTA's toJSON({["a"]=true}) emits '[ { "a": true } ]' (array
-- wrapper), so fromJSON gives { [1] = {a=true} } and every rights lookup
-- silently fails. Emit a plain JSON object instead.
local function rightsToJSON(rightsMap)
        local keys = {}
        for k, v in pairs(rightsMap) do
                if v then keys[#keys + 1] = tostring(k) end
        end
        table.sort(keys)
        local out = {}
        for _, k in ipairs(keys) do
                out[#out + 1] = '"' .. mysql:escape_string(k):gsub('\\', '\\\\'):gsub('"', '\\"') .. '":true'
        end
        return "{" .. table.concat(out, ",") .. "}"
end

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
                        .. rightsToJSON(rightsMap) .. "', '"
                        .. mysql:escape_string(toJSON(rank.color)) .. "')")
        end
        outputDebugString("[Vortex Staff] seeded " .. #RANK_SEED .. " ranks.")
end

-- [Fix #160] one-time migration: existing ranks were seeded before the new
-- rights existed (seedRanks only runs on an EMPTY table), so grant
-- admin.highstaffchat to every rank that already holds the old
-- admin.highchat /h right, and drop the cancelled property.make right.
local function migrateRightsFix160()
        local q = mysql:query("SELECT ID, Rights FROM staff_roles")
        if not q then return end
        local pending = {}
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                local parsed = fromJSON(row.Rights or "")
                if type(parsed) == "table" then
                        -- MTA wraps objects as [ { k = true } ]; unwrap like the bridge does
                        local rights = parsed
                        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                                rights = parsed[1]
                        end
                        local changed = false
                        if rights["admin.highchat /h"] then
                                -- [Fix #160] the old dead right is superseded by admin.highstaffchat
                                rights["admin.highchat /h"] = nil
                                rights["admin.highstaffchat"] = true
                                changed = true
                        end
                        if rights["property.make"] then
                                rights["property.make"] = nil
                                changed = true
                        end
                        if changed then
                                pending[#pending + 1] = { id = tonumber(row.ID), rights = rights }
                        end
                end
        end
        mysql:free_result(q)
        for _, p in ipairs(pending) do
                mysql:query_free("UPDATE staff_roles SET Rights='" .. rightsToJSON(p.rights)
                        .. "' WHERE ID=" .. p.id)
        end
        if #pending > 0 then
                outputDebugString("[Vortex Staff] Fix #160: migrated rights on " .. #pending .. " rank(s).")
        end
end

addEventHandler("onResourceStart", resourceRoot, function()
        ensureTables()
        seedRanks()
        migrateRightsFix160()
end)

-- ============================================================================
-- permission gates
-- ============================================================================

-- [Fix #14] gates rebuilt: the rank's own stored Rights decide FIRST (the
-- panel writes them per rank), the numeric ladder stays the fallback. This
-- fixes owners with custom ranks whose row-order index lands below the old
-- threshold and silently blocked every member/rank edit.

-- [Fix #51] defensive: a client may send the staffs-grid username CELL text,
-- which carries the online status prefix ("#00FF00● name" / "#808080○ name").
-- Strip color codes, the status dot and surrounding whitespace BEFORE any
-- account lookup, or the removal dies with 'Account not found'.
local function stripStatusPrefix(raw)
        local s = tostring(raw or "")
        s = s:gsub("^#[0-9A-Fa-f]+%s*", "")
        s = s:gsub("^●%s*", ""):gsub("^○%s*", "")
        s = s:gsub("^%s+", "")
        return s
end

local function hasEditMembers(player)        -- Fix #25: same backend-first rule as hasEditRanks
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, "admin.manager.editmembers") and true or false
                end
                return false
        end
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function hasEditRanks(player)
        -- Fix #25 (user): the rank's stored rights are the ONLY truth for
        -- ranked staff — the old ladder fallback let high ranks edit ranks
        -- even with the right unticked (sections were cosmetic)
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, "admin.manager.editranks") and true or false
                end
                return false
        end
        return exports.integration:isPlayerLeadAdmin(player) and true or false
end

-- [Fix #160] A5: the Resources/Mods SECTION is one more backend-first
-- permission (admin.manager.resources) - same rule as the two helpers above,
-- Lead Admin+ decides for staff without a Vortex rank. Every resource action
-- additionally needs its own admin.startres/stopres/restartres right.
local function hasManageResources(player)
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, "admin.manager.resources") and true or false
                end
                return false
        end
        return exports.integration:isPlayerLeadAdmin(player) and true or false
end

-- [Fix #160] A5: every right the client mirrors (hide/disable buttons).
-- The server re-checks each one inside the event handlers - this table only
-- saves the client from showing controls it can never use.
local function panelRights(player)
        local function has(right)
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right) and true or false
                end
                return false
        end
        return {
                editmembers = hasEditMembers(player),
                editranks = hasEditRanks(player),
                resources = hasManageResources(player),
                startres = has("admin.startres"),
                stopres = has("admin.stopres"),
                restartres = has("admin.restartres"),
        }
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
        -- [Mod 2 fix] alias a.id AS AccountID: the daily-report stats below
        -- read row.AccountID, which never existed (a.id) so the owl_logs
        -- activity numbers silently errored out (pcall) and stayed 0
        local q = mysql:query([[
                SELECT a.id AS AccountID, a.username, m.RoleID
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
        -- [Mod 2 fix] map online players by ACCOUNT id once; every staff row
        -- carries the live rank (rank:name / rank:color element data pushed by
        -- the Vortex bridge) so the panel ALWAYS agrees with the scoreboard,
        -- even when the DB role changed while the staff member was offline
        local onlineByAccount = {}
        for _, p in ipairs(getElementsByType("player")) do
                local acc = tonumber(getElementData(p, "account:id"))
                if acc then onlineByAccount[acc] = p end
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                local onlinePlayer = onlineByAccount[tonumber(row.id)]
                admins[#admins + 1] = {
                        AdminID = tonumber(row.RoleID),
                        Account = row.username,
                        AccountID = tonumber(row.id),
                        Online = onlinePlayer ~= nil,
                        LiveRank = onlinePlayer and getElementData(onlinePlayer, "rank:name") or nil,
                        LiveColor = onlinePlayer and getElementData(onlinePlayer, "rank:color") or nil,
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

-- [TEAMS] the Teams block of the panel payload. staff_manager_teams_s.lua
-- loads AFTER this file (see meta.xml), so the hook is resolved at call time
-- and guarded: a missing/disabled teams script must never stop the panel.
local function teamsPayload()
        if type(fetchStaffTeamsPayload) == "function" then
                local ok, payload = pcall(fetchStaffTeamsPayload)
                if ok and type(payload) == "table" then return payload end
        end
        return nil
end

local function sendPanel(player)
        if not canPlayerAccessStaffManager(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                return false
        end
        local editMembers = hasEditMembers(player)
        local editRanks = hasEditRanks(player)
        -- [Fix #160] A5: Resources/Mods section flag (was a copy of editRanks)
        local manageResources = hasManageResources(player)
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
                        editMembers, editRanks, hasManageResources(player),
                        { levels = levels, admins = {}, changelogs = {},
                          role_members = {}, staff_report = {},
                          teams = teamsPayload() },
                        panelRights(player))
                return false
        end
        -- [Mod 2 fix] map online players by ACCOUNT id once; every staff row
        -- carries the live rank (rank:name / rank:color element data pushed by
        -- the Vortex bridge) so the panel ALWAYS agrees with the scoreboard,
        -- even when the DB role changed while the staff member was offline
        local onlineByAccount = {}
        for _, p in ipairs(getElementsByType("player")) do
                local acc = tonumber(getElementData(p, "account:id"))
                if acc then onlineByAccount[acc] = p end
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                local onlinePlayer = onlineByAccount[tonumber(row.id)]
                admins[#admins + 1] = {
                        AdminID = tonumber(row.RoleID),
                        Account = row.username,
                        AccountID = tonumber(row.id),
                        Online = onlinePlayer ~= nil,
                        LiveRank = onlinePlayer and getElementData(onlinePlayer, "rank:name") or nil,
                        LiveColor = onlinePlayer and getElementData(onlinePlayer, "rank:color") or nil,
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
                editMembers, editRanks, manageResources,
                { levels = levels, admins = admins, changelogs = changelogs,
                  role_members = roleMembers, staff_report = fetchStaffReport(),
                  teams = teamsPayload() },
                panelRights(player))
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

-- [Fix #160] A5: /managepanel opens the SAME panel as /staffs but is gated to
-- admin.manager.panel (gate: staff_manager/gates_fix160_task5.lua + the
-- explicit right check below, so the button/section right is enforced even
-- when the command is fired without the gate layer).
addCommandHandler("managepanel", function(player, cmd)
        if not (isElement(player) and getElementType(player) == "player") then return end
        if getElementData(player, "rank:index") then
                if type(playerHasRight) ~= "function"
                        or not playerHasRight(player, "admin.manager.panel") then
                        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                        return
                end
        elseif not exports.integration:isPlayerLeadAdmin(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                return
        end
        sendPanel(player)
end, false, false)

-- ============================================================================
-- mutations
-- ============================================================================

local function addChangelog(cType, username, fromRank, toRank, actor)
        -- [Fix #157] optional actor: command handlers have no event `client`,
        -- so /giverole and friends pass themselves; event callers stay as-is
        local src = actor
        if not (isElement(src) and getElementType(src) == "player")
                and isElement(client) and getElementType(client) == "player" then
                src = client
        end
        local by = "System"
        if isElement(src) and getElementType(src) == "player" then
                by = getElementData(src, "account:username")
                        or getPlayerName(src) or "Unknown"
        end
        mysql:query_free(string.format(
                "INSERT INTO staff_rank_changelogs (Date, cType, Username, FromR, ToR, By_) VALUES (NOW(), '%s', '%s', '%s', '%s', '%s')",
                mysql:escape_string(tostring(cType)),
                mysql:escape_string(tostring(username)),
                mysql:escape_string(tostring(fromRank or "-")),
                mysql:escape_string(tostring(toRank or "-")),
                mysql:escape_string(tostring(by))))
end

-- [Fix #50 - user] MICRO-STUTTER KILL: every mutation used to fire
-- sendFullData immediately - a blocking MySQL JOIN + 200 changelog rows +
-- staff report on the SERVER thread, often several in a burst (updateRole,
-- bridge rank refresh, changelog write...). The per-player 250ms debounce
-- coalesces each burst into ONE push; the last action always wins.
local refreshTimers = {}
local function refresh(player)
        if not isElement(player) then return end
        local t = refreshTimers[player]
        if t and isTimer(t) then killTimer(t) end
        refreshTimers[player] = setTimer(function(pid)
                refreshTimers[pid] = nil
                if isElement(pid) then
                        sendFullData(pid)
                end
        end, 250, 1, player)
end

-- [Fix #15] rank changes are PUBLIC chat logs. Format follows the classic
-- admin-bot line: "[STAFF]: Hade promoted 'BO5' to Head Management."
-- green = promotion, red = demotion/removal, visible to everyone.
local function actorName(actor)
        -- [Fix #157] optional actor (command handlers, no event `client`)
        local src = actor
        if not (isElement(src) and getElementType(src) == "player")
                and isElement(client) and getElementType(client) == "player" then
                src = client
        end
        if isElement(src) and getElementType(src) == "player" then
                return getElementData(src, "account:username") or getPlayerName(src) or "?"
        end
        return "System"
end

local function broadcastRankChange(action, target, toRank, isNegative, actor)
        -- Fix #25 (user, image 3): colored staff log — purple [STAFF] tag,
        -- colored actor, rank name in its panel color when known
        local rankColor = ""
        if toRank and mysql then
                local q = mysql:query("SELECT Color FROM staff_roles WHERE LevelName = '"
                        .. mysql:escape_string(tostring(toRank)) .. "' LIMIT 1")
                if q then
                        local row = mysql:fetch_assoc(q)
                        if row and row.Color and tostring(row.Color) ~= "" then
                                local c = fromJSON(tostring(row.Color)) or {}
                                if type(c[1]) == "table" then
                                        c = c[1]
                                end
                                local cr, cg, cb = tonumber(c[1]), tonumber(c[2]), tonumber(c[3])
                                if cr and cg and cb then
                                        rankColor = ("#%02X%02X%02X"):format(cr, cg, cb)
                                end
                        end
                        mysql:free_result(q)
                end
        end
        local line = "#a855f7[STAFF]#ffffff " .. actorName(actor) .. " "
                .. (isNegative and "#ff5a5a" or "#46c85a") .. action .. "#ffffff '"
                .. tostring(target) .. "'"
                .. (toRank and (" to " .. rankColor .. tostring(toRank)) or "") .. "."
        outputChatBox(line, root, 255, 255, 255, true)
end

-- add a staff member to a rank
addEvent("rpadmin:addNewAdmin", true)
addEventHandler("rpadmin:addNewAdmin", root, function(account, levelID, levelName)
        if not hasEditMembers(client) then
                outputChatBox("You don't have permission to edit staff members.", client, 255, 80, 80)
                return
        end
        if not account or not tonumber(levelID) then return end
        -- [Fix #14] case-insensitive: typing "hade" finds "Hade"
        local user = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE LOWER(username)=LOWER('"
                .. mysql:escape_string(tostring(account)) .. "') LIMIT 1")
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
        -- [Fix #14] the log tells the truth: compare the old vs new ladder
        -- position, so a downgrade is recorded (and colored) as a Demotion
        local changeType = "Promotion"
        if old and type(getRankTitleIndex) == "function" then
                local oldIdx = getRankTitleIndex(oldName)
                local newIdx = getRankTitleIndex(tostring(levelName or "-"))
                if oldIdx and newIdx and newIdx < oldIdx then
                        changeType = "Demotion"
                end
        end
        addChangelog(changeType, user.username, oldName, tostring(levelName or "-"))
        outputChatBox("Staff updated: " .. user.username .. " -> " .. tostring(levelName)
                .. " (" .. changeType .. ")", client, 0, 255, 0)
        -- [Fix #15] public chat log of the rank change
        broadcastRankChange(changeType == "Demotion" and "demoted" or "promoted",
                user.username, tostring(levelName or "-"), changeType == "Demotion")
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
        if not hasEditMembers(client) then
                outputChatBox("You don't have permission to edit staff members.", client, 255, 80, 80)
                return
        end
        -- [Fix #51] never let the decorated grid text reach the account lookup
        account = stripStatusPrefix(account)
        if account == "" then return end
        local user = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE LOWER(username)=LOWER('"
                .. mysql:escape_string(tostring(account)) .. "') LIMIT 1")
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
        -- [Fix #15] public chat log of the removal
        broadcastRankChange("removed", user.username, false, true)
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
        if not hasEditRanks(client) then
                outputChatBox("You don't have permission to edit ranks.", client, 255, 80, 80)
                return
        end
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
        if not hasEditRanks(client) then
                outputChatBox("You don't have permission to edit ranks.", client, 255, 80, 80)
                return
        end
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
        if not hasEditRanks(client) then
                outputChatBox("You don't have permission to edit ranks.", client, 255, 80, 80)
                return
        end
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
        if not hasEditRanks(sender) then
                outputChatBox("You don't have permission to edit ranks.", sender, 255, 80, 80)
                return
        end
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

        local rightsCount = 0
        for _ in pairs(rights) do rightsCount = rightsCount + 1 end
        -- [Fix #34 - user] the Color column was saved as
        --   toJSON(color[1]) .. "," .. toJSON(color[2]) ...
        -- and MTA's toJSON wraps EVERY plain value in an array:
        -- toJSON(220) == "[220]" -> the column got "[220],[0],[0]", which is
        -- NOT valid JSON, fromJSON returned nil and the rank silently fell
        -- back to WHITE on the next read (tab/chat/nametag colors died after
        -- every panel save). Encode the whole {r,g,b,a} table in ONE call.
        -- [Fix #86] one toJSON call for the whole {r,g,b,a} table (see Fix
        -- #34 above). NOTE: MTA has no "compact" mode — toJSON always emits
        -- the spaced "[ [ r, g, b, a ] ]" form; that is FINE now because the
        -- setup pass parses Color with fromJSON instead of the old
        -- `LIKE '[[%'` string test that wiped every saved color to white.
        -- [Fix #153] alpha is ALWAYS 255 here: every in-game renderer draws a
        -- rank color opaque, and the panel's picker preview does too - saving
        -- a < 255 (an 8-digit hex pick) made the panel blend the row with its
        -- background while the game showed the pure RGB.
        local colorJSON = toJSON({ tonumber(color[1]) or 255, tonumber(color[2]) or 255,
                tonumber(color[3]) or 255, 255 })
        mysql:query_free("UPDATE staff_roles SET Rights='"
                .. rightsToJSON(rights) .. "', Color='"
                .. mysql:escape_string(colorJSON) .. "' WHERE ID=" .. levelID)
        addChangelog("Rank Edited", row.LevelName, "-",
                ("#%02X%02X%02X"):format(color[1], color[2], color[3]))
        -- [Fix #30] LOUD proof the backend fired: what was saved + that
        -- every online member of the rank got it LIVE (data re-pushed)
        outputChatBox("Rank saved: " .. row.LevelName
                .. " | rights: " .. rightsCount
                .. " | color: " .. ("#%02X%02X%02X"):format(color[1], color[2], color[3])
                .. " | applied live to online members", sender, 0, 255, 0)
        refresh(sender)
        -- Vortex bridge: live-update colors/rights for every online member
        if type(refreshRankMembers) == "function" then
                refreshRankMembers(levelID)
        end
end

addEvent("rpadmin:updateRole", true)
addEventHandler("rpadmin:updateRole", root, function(levelID, name, rights, color)
        updateRoleImpl(client, levelID, rights, color)
        -- [Fix #53] persist a non-empty rank name from the SAME Save press
        -- (the client used to send nil here, so typed names never saved).
        if type(name) == "string" and name ~= "" and tonumber(levelID) and hasEditRanks(client) then
                local row = mysql:query_fetch_assoc("SELECT LevelName FROM staff_roles WHERE ID="
                        .. tonumber(levelID))
                if row then
                        mysql:query_free("UPDATE staff_roles SET LevelName='"
                                .. mysql:escape_string(name) .. "' WHERE ID=" .. tonumber(levelID))
                        addChangelog("Rank Renamed", row.LevelName, row.LevelName, name)
                        outputChatBox("Rank renamed: " .. tostring(row.LevelName) .. " -> " .. name,
                                client, 0, 255, 0)
                        refresh(client)
                end
        end
end)

addEvent("rpadmin:saveLevelRights", true)
addEventHandler("rpadmin:saveLevelRights", root, function(levelID, rights, color)
        updateRoleImpl(source, levelID, rights, color)
end)

-- ===========================================================================
-- [Fix #157] COMMAND AUDIT — the /staffs rank editor lists command-looking
-- rights that had NO working command behind them, so ticking or unticking
-- them changed nothing. Every one of them now has a real handler below:
--
--   accounts family : /changepass /changeemail /changeserial
--                     /changeaccountname
--   owner family    : /checkserial /checkaccount /checkemail
--                     /setactivestatus /changemode
--                     /giverole /takerole /setroleid
--   mapped, no code : /setfpslimit /setgametype /clearchatforall /gotoped
--                     /setweight /unmute  (gate keys already existed)
--   read-only help  : /showbans /showsettings /getaccount
--
-- They register through the WRAPPED addCommandHandler (command_gates_s.lua is
-- the FIRST script of admin-system), so for ranked staff the gate map already
-- enforces them; the helper below is the legacy ladder for players without a
-- Vortex rank, which the gate deliberately lets through.
-- ===========================================================================

-- right check: rank rights are the ONLY truth for ranked staff, the legacy
-- integration ladder decides for everyone else (same rule as hasEditRanks)
local function fix157HasRight(player, right)
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

local function fix157Check(player, right)
        if fix157HasRight(player, right) then return true end
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return false
end

local function fix157Trim(s)
        s = tostring(s or "")
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fix157Syntax(player, cmd, args)
        outputChatBox("SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), player, 255, 194, 14)
end

-- every DB read below goes through this column list (+ salt, used by
-- /changepass to re-hash with the LIVE login scheme)
local FIX157_ACCOUNT_COLS = "id, username, salt, email, mtaserial, ip, "
        .. "activated, appstate, registerdate, lastlogin, admin, supporter, muted, warns"

local function fix157PlayerByAccountID(accountID)
        accountID = tonumber(accountID)
        if not accountID then return nil end
        for _, p in ipairs(getElementsByType("player")) do
                if tonumber(getElementData(p, "account:id")) == accountID then
                        return p
                end
        end
        return nil
end

-- resolve an account from: numeric id -> exact username -> online player nick
local function fix157Account(query)
        local q = fix157Trim(query)
        if q == "" then return nil, nil end
        local esc = mysql:escape_string(q)
        local row
        if q:match("^%d+$") then
                row = mysql:query_fetch_assoc("SELECT " .. FIX157_ACCOUNT_COLS
                        .. " FROM accounts WHERE id=" .. tonumber(q))
        end
        if not row then
                row = mysql:query_fetch_assoc("SELECT " .. FIX157_ACCOUNT_COLS
                        .. " FROM accounts WHERE LOWER(username)=LOWER('" .. esc .. "') LIMIT 1")
        end
        if not row then
                -- partial nick / scoreboard id of an ONLINE player
                local ok, target = pcall(function()
                        -- third arg = quiet: no "No such player found." spam
                        return exports.global:findPlayerByPartialNick(nil, q, true)
                end)
                if ok and isElement(target) and getElementType(target) == "player" then
                        local aid = tonumber(getElementData(target, "account:id"))
                        if aid then
                                row = mysql:query_fetch_assoc("SELECT " .. FIX157_ACCOUNT_COLS
                                        .. " FROM accounts WHERE id=" .. aid)
                        end
                end
        end
        if not row then return nil, nil end
        return row, fix157PlayerByAccountID(row.id)
end

-- [Fix #157] EXACTLY the live login scheme (login-panel/server.lua:60):
-- lower(md5(lower(md5(password)) .. salt)); the old md5("wedorp"..pw) path
-- sits inside the commented block in account/s_main.lua, never use it.
local function fix157HashPassword(password, salt)
        return string.lower(md5(string.lower(md5(tostring(password))) .. tostring(salt or "")))
end

local function fix157StaffRankName(accountID)
        local row = mysql:query_fetch_assoc("SELECT r.LevelName, r.ID FROM staff_role_members m"
                .. " JOIN staff_roles r ON r.ID = m.RoleID WHERE m.AccountID="
                .. tonumber(accountID) .. " LIMIT 1")
        if row and row.LevelName then
                return tostring(row.LevelName) .. " (#" .. tostring(row.ID) .. ")"
        end
        return "-"
end

local function fix157PrintAccount(actor, row)
        local online = fix157PlayerByAccountID(row.id)
        outputChatBox("Account: " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")"
                .. (online and "  [ONLINE]" or "  [offline]"), actor, 220, 220, 220)
        outputChatBox("  Email: " .. ((row.email and row.email ~= "") and row.email or "-")
                .. "  |  IP: " .. ((row.ip and row.ip ~= "") and row.ip or "-"), actor, 200, 200, 200)
        outputChatBox("  Serial: " .. ((row.mtaserial and row.mtaserial ~= "") and row.mtaserial or "-"),
                actor, 200, 200, 200)
        outputChatBox("  activated=" .. tostring(row.activated) .. "  appstate=" .. tostring(row.appstate)
                .. "  muted=" .. tostring(row.muted) .. "  warns=" .. tostring(row.warns),
                actor, 200, 200, 200)
        outputChatBox("  Registered: " .. tostring(row.registerdate or "-")
                .. "  |  last login: " .. tostring(row.lastlogin or "-"), actor, 200, 200, 200)
        outputChatBox("  Legacy admin=" .. tostring(row.admin) .. "  supporter=" .. tostring(row.supporter)
                .. "  |  staff rank: " .. fix157StaffRankName(row.id), actor, 120, 200, 255)
end

-- admin-command log (action 4 = "Admin command"); affected may be an element
-- or, for offline accounts, any string
local function fix157Log(actor, data, affected)
        pcall(function()
                exports.logs:dbLog(actor, 4, affected or actor, data)
        end)
end

local function fix157ListAccounts(actor, header, q)
        local n = 0
        if not q then
                outputChatBox("Account query failed - run /staffdb", actor, 255, 0, 0)
                return 0
        end
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                n = n + 1
                outputChatBox("  (#" .. tostring(row.id) .. ") " .. tostring(row.username),
                        actor, 220, 220, 220)
        end
        mysql:free_result(q)
        if n == 0 then
                outputChatBox(header .. ": no account found.", actor, 255, 194, 14)
        end
        return n
end

-- ================================================================ accounts --

-- [Fix #157] accounts.changepass — /setaccountpassword + /changeaccountpassword
-- are commented out in account/s_main.lua, so the right was display-only.
addCommandHandler("changepass", function(player, cmd, account, newPass, confirmPass)
        if not fix157Check(player, "accounts.changepass") then return end
        if not account or not newPass or not confirmPass then
                fix157Syntax(player, cmd, "[Account Username] [New Password] [Confirm Password]")
                return
        end
        local row, online = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        if #newPass < 6 or #newPass >= 30 then
                outputChatBox("Password must be 6-29 characters long.", player, 255, 0, 0)
                return
        end
        if newPass:find("[;'@,%s]") then
                outputChatBox("Password cannot contain ; ' @ , or a space.", player, 255, 0, 0)
                return
        end
        if newPass ~= confirmPass then
                outputChatBox("Passwords do not match.", player, 255, 0, 0)
                return
        end
        local hash = fix157HashPassword(newPass, row.salt)
        mysql:query_free("UPDATE accounts SET password='" .. mysql:escape_string(hash)
                .. "' WHERE id=" .. tonumber(row.id))
        outputChatBox("Password changed for '" .. tostring(row.username) .. "' (#"
                .. tostring(row.id) .. ") - the new password is never shown.", player, 0, 255, 0)
        if online and online ~= player then
                outputChatBox("Staff changed your account password - use it on your next login.",
                        online, 255, 194, 14)
        end
        fix157Log(player, "CHANGEPASS " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")",
                "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] accounts.changeemail
addCommandHandler("changeemail", function(player, cmd, account, email)
        if not fix157Check(player, "accounts.changeemail") then return end
        if not account or not email then
                fix157Syntax(player, cmd, "[Account Username] [New Email]")
                return
        end
        if #email > 100 or not email:match("^[%w%._%-]+@[%w%._%-]+%.[%w]+$") then
                outputChatBox("Invalid email address (max 100 characters).", player, 255, 0, 0)
                return
        end
        local row, online = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        local before = tostring(row.email or "-")
        mysql:query_free("UPDATE accounts SET email='" .. mysql:escape_string(email)
                .. "' WHERE id=" .. tonumber(row.id))
        outputChatBox("Email changed: " .. tostring(row.username) .. " (#" .. tostring(row.id)
                .. ") '" .. before .. "' -> '" .. email .. "'", player, 0, 255, 0)
        if online and online ~= player then
                outputChatBox("Staff set your account email to " .. email .. ".", online, 255, 194, 14)
        end
        fix157Log(player, "CHANGEEMAIL " .. tostring(row.username) .. " (#" .. tostring(row.id)
                .. ") -> " .. email, "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] accounts.changeserial
addCommandHandler("changeserial", function(player, cmd, account, newSerial)
        if not fix157Check(player, "accounts.changeserial") then return end
        if not account or not newSerial then
                fix157Syntax(player, cmd, "[Account Username / Player] [32-char Serial]")
                return
        end
        -- canonical serial format is what getPlayerSerial returns: 32 A-Z0-9
        newSerial = fix157Trim(newSerial):upper()
        if #newSerial ~= 32 or not newSerial:match("^%w+$") then
                outputChatBox("REJECTED: a serial is exactly 32 letters/digits (0-9 A-Z).",
                        player, 255, 80, 80)
                return
        end
        local row, online = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        local esc = mysql:escape_string(newSerial)
        local dup = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE mtaserial='"
                .. esc .. "' AND id<>" .. tonumber(row.id) .. " LIMIT 1")
        mysql:query_free("UPDATE accounts SET mtaserial='" .. esc .. "' WHERE id="
                .. tonumber(row.id))
        outputChatBox("Serial changed: " .. tostring(row.username) .. " (#" .. tostring(row.id)
                .. ") -> " .. newSerial, player, 0, 255, 0)
        if dup and dup.username then
                outputChatBox("NOTE: this serial is already used by '" .. tostring(dup.username)
                        .. "' (#" .. tostring(dup.id) .. ").", player, 255, 194, 14)
        end
        if online then
                outputChatBox("MTA binds the serial at login, so the change applies from their NEXT login.",
                        player, 255, 194, 14)
                if online ~= player then
                        outputChatBox("Staff changed your account serial - it applies on your next login.",
                                online, 255, 194, 14)
                end
        end
        fix157Log(player, "CHANGESERIAL " .. tostring(row.username) .. " (#" .. tostring(row.id)
                .. ") -> " .. newSerial, "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] accounts.changeaccountname
addCommandHandler("changeaccountname", function(player, cmd, oldName, newName)
        if not fix157Check(player, "accounts.changeaccountname") then return end
        if not oldName or not newName then
                fix157Syntax(player, cmd, "[Current Account] [New Account]")
                return
        end
        if #newName < 3 or #newName > 32 then
                outputChatBox("The new account name must be 3-32 characters long.", player, 255, 0, 0)
                return
        end
        if newName:find("[;'@,%s]") then
                outputChatBox("An account name cannot contain ; ' @ , or a space.", player, 255, 0, 0)
                return
        end
        local row, online = fix157Account(oldName)
        if not row then
                outputChatBox("Account not found: " .. tostring(oldName), player, 255, 0, 0)
                return
        end
        if tostring(row.username):lower() == newName:lower() then
                outputChatBox("The account already uses that name.", player, 255, 194, 14)
                return
        end
        local taken = mysql:query_fetch_assoc("SELECT id FROM accounts WHERE LOWER(username)=LOWER('"
                .. mysql:escape_string(newName) .. "') LIMIT 1")
        if taken then
                outputChatBox("Name already taken: " .. newName, player, 255, 0, 0)
                return
        end
        local before = tostring(row.username)
        mysql:query_free("UPDATE accounts SET username='" .. mysql:escape_string(newName)
                .. "' WHERE id=" .. tonumber(row.id))
        if online then
                -- same call the donator username-change perk uses
                exports.anticheat:changeProtectedElementDataEx(online, "account:username", newName, true)
        end
        outputChatBox("Account renamed: '" .. before .. "' -> '" .. newName .. "' (#"
                .. tostring(row.id) .. ")", player, 0, 255, 0)
        if online and online ~= player then
                outputChatBox("Staff renamed your account to '" .. newName .. "'.", online, 255, 194, 14)
        end
        fix157Log(player, "CHANGEACCOUNTNAME '" .. before .. "' -> '" .. newName .. "' (#"
                .. tostring(row.id) .. ")", "account#" .. tostring(row.id))
end, false, false)

-- ================================================================== owner --

-- [Fix #157] owner.checkserial — /findserial + /findip cover the ONLINE case,
-- this one also answers for offline accounts and for a bare 32-char serial.
addCommandHandler("checkserial", function(player, cmd, query)
        if not fix157Check(player, "owner.checkserial") then return end
        query = fix157Trim(query)
        if query == "" then
                fix157Syntax(player, cmd, "[Account Username / Player / 32-char Serial]")
                return
        end
        if #query == 32 and query:match("^%w+$") then
                local q = mysql:query("SELECT id, username FROM accounts WHERE LOWER(mtaserial)=LOWER('"
                        .. mysql:escape_string(query) .. "') ORDER BY id ASC LIMIT 10")
                if not q then
                        outputChatBox("Serial query failed - run /staffdb", player, 255, 0, 0)
                        return
                end
                local n = fix157ListAccounts(player, "serial " .. query, q)
                if n > 0 then
                        outputChatBox("serial " .. query .. " is used by the account(s) above.",
                                player, 120, 200, 255)
                end
                return
        end
        local row = fix157Account(query)
        if not row then
                outputChatBox("Account not found: " .. query, player, 255, 0, 0)
                return
        end
        outputChatBox("Serial for '" .. tostring(row.username) .. "' (#" .. tostring(row.id) .. "): "
                .. ((row.mtaserial and row.mtaserial ~= "") and row.mtaserial or "-"),
                player, 120, 200, 255)
        fix157Log(player, "CHECKSERIAL " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")",
                "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] owner.checkaccount — full account card + characters
addCommandHandler("checkaccount", function(player, cmd, account)
        if not fix157Check(player, "owner.checkaccount") then return end
        account = fix157Trim(account)
        if account == "" then
                fix157Syntax(player, cmd, "[Account Username / Player / Account ID]")
                return
        end
        local row = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. account, player, 255, 0, 0)
                return
        end
        fix157PrintAccount(player, row)
        local q = mysql:query("SELECT charactername, hoursplayed, active FROM characters WHERE account="
                .. tonumber(row.id) .. " ORDER BY lastlogin DESC LIMIT 6")
        if q then
                local n = 0
                while true do
                        local c = mysql:fetch_assoc(q)
                        if not c then break end
                        n = n + 1
                        outputChatBox("  char: " .. tostring(c.charactername) .. " ("
                                .. tostring(tonumber(c.hoursplayed) or 0) .. "h)"
                                .. (tostring(c.active) == "0" and " [inactive]" or ""),
                                player, 190, 190, 190)
                end
                mysql:free_result(q)
                if n == 0 then
                        outputChatBox("  no characters on this account.", player, 190, 190, 190)
                end
        end
        fix157Log(player, "CHECKACCOUNT " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")",
                "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] owner.checkemail — by email address (who owns it) or by account
addCommandHandler("checkemail", function(player, cmd, query)
        if not fix157Check(player, "owner.checkemail") then return end
        query = fix157Trim(query)
        if query == "" then
                fix157Syntax(player, cmd, "[Email Address / Account Username / Player]")
                return
        end
        if query:find("@", 1, true) then
                local q = mysql:query("SELECT id, username FROM accounts WHERE LOWER(email)=LOWER('"
                        .. mysql:escape_string(query) .. "') ORDER BY id ASC LIMIT 10")
                local n = fix157ListAccounts(player, "email " .. query, q)
                if n > 0 then
                        outputChatBox("email " .. query .. " belongs to the account(s) above.",
                                player, 120, 200, 255)
                end
                return
        end
        local row = fix157Account(query)
        if not row then
                outputChatBox("Account not found: " .. query, player, 255, 0, 0)
                return
        end
        outputChatBox("Email for '" .. tostring(row.username) .. "' (#" .. tostring(row.id) .. "): "
                .. ((row.email and row.email ~= "") and row.email or "-"), player, 120, 200, 255)
        fix157Log(player, "CHECKEMAIL " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")",
                "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] owner.setactivestatus — accounts.activated = "0" is exactly what
-- the login panel checks (login-panel/server.lua:72) to refuse a login.
addCommandHandler("setactivestatus", function(player, cmd, account, state)
        if not fix157Check(player, "owner.setactivestatus") then return end
        if not account or not state then
                fix157Syntax(player, cmd, "[Account Username / Player] [0 = locked, 1 = activated]")
                return
        end
        local n = tonumber(state)
        if n ~= 0 and n ~= 1 then
                outputChatBox("State must be 0 (login blocked) or 1 (login allowed).", player, 255, 0, 0)
                return
        end
        local row, online = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        local before = tostring(row.activated)
        if before == tostring(n) then
                outputChatBox("Account '" .. tostring(row.username) .. "' is already activated="
                        .. before .. ".", player, 255, 194, 14)
                return
        end
        mysql:query_free("UPDATE accounts SET activated=" .. n .. " WHERE id=" .. tonumber(row.id))
        outputChatBox("Account '" .. tostring(row.username) .. "' (#" .. tostring(row.id)
                .. "): activated " .. before .. " -> " .. n
                .. (n == 0 and " (login blocked)" or " (login allowed)"), player, 0, 255, 0)
        if online and online ~= player then
                if n == 0 then
                        outputChatBox("Staff deactivated your account - you may finish this session "
                                .. "but cannot log in again until it is reactivated.", online, 255, 100, 100)
                else
                        outputChatBox("Staff reactivated your account - you can log in again.",
                                online, 0, 255, 0)
                end
        end
        fix157Log(player, "SETACTIVESTATUS " .. tostring(row.username) .. " (#" .. tostring(row.id)
                .. ") activated " .. before .. " -> " .. n, "account#" .. tostring(row.id))
end, false, false)

-- [Fix #157] owner.changemode — this server has NO /changemode: mapmanager
-- (the only resource that ships it) is not installed, so the handler works
-- through its exports when present and says so plainly when not.
addCommandHandler("changemode", function(player, cmd, ...)
        if not fix157Check(player, "owner.changemode") then return end
        local modeName = fix157Trim(table.concat({...}, " "))
        local mapRes = getResourceFromName("mapmanager")
        if not mapRes or getResourceState(mapRes) ~= "running" then
                outputChatBox("Cannot switch gamemode: the 'mapmanager' resource is not "
                        .. "installed on this server.", player, 255, 0, 0)
                outputChatBox("Current gamemode: '" .. tostring(getGameType())
                        .. "' - owner.changemode needs mapmanager.", player, 255, 194, 14)
                return
        end
        if modeName == "" then
                fix157Syntax(player, cmd, "[Gamemode Resource Name]")
                local ok, modes = pcall(function() return exports.mapmanager:getGamemodes() end)
                if ok and type(modes) == "table" and #modes > 0 then
                        local names = {}
                        for _, res in ipairs(modes) do
                                names[#names + 1] = getResourceName(res)
                        end
                        outputChatBox("Available gamemodes: " .. table.concat(names, ", "),
                                player, 200, 200, 200)
                end
                return
        end
        local ok, result = pcall(function()
                return exports.mapmanager:changeGamemodeByName(modeName)
        end)
        if not ok then
                outputChatBox("mapmanager refused the gamemode: " .. tostring(result), player, 255, 0, 0)
                return
        end
        if result == false then
                outputChatBox("Unknown gamemode resource: " .. modeName
                        .. " (check /gamemodes).", player, 255, 0, 0)
                return
        end
        outputChatBox("Switching gamemode to '" .. modeName .. "' via mapmanager ...",
                player, 0, 255, 0)
        fix157Log(player, "CHANGEMODE " .. modeName, "server")
end, false, false)

-- ================================================================== roles --
-- The panel (rpadmin:addNewAdmin / rpadmin:removeAdmin) already assigns
-- staff_role_members, but only through the GUI. /giverole /takerole /
-- /setroleid are the chat commands the owner.* rights promised.

local function fix157FindRoleByArg(arg)
        local q = fix157Trim(arg)
        if q == "" then return nil, nil end
        local row
        if q:match("^%d+$") then
                row = mysql:query_fetch_assoc("SELECT ID, LevelName FROM staff_roles WHERE ID="
                        .. tonumber(q))
        else
                row = mysql:query_fetch_assoc("SELECT ID, LevelName FROM staff_roles"
                        .. " WHERE LOWER(LevelName)=LOWER('" .. mysql:escape_string(q)
                        .. "') ORDER BY ID ASC LIMIT 1")
        end
        if row and row.ID then return tonumber(row.ID), tostring(row.LevelName) end
        return nil, nil
end

local function fix157CurrentRoleName(accountID)
        local old = mysql:query_fetch_assoc("SELECT m.RoleID FROM staff_role_members m WHERE m.AccountID="
                .. tonumber(accountID) .. " LIMIT 1")
        if not old then return nil, nil end
        local oldName = "-"
        for _, level in ipairs(fetchLevels()) do
                if tonumber(level.ID) == tonumber(old.RoleID) then
                        oldName = level.LevelName
                end
        end
        return tonumber(old.RoleID), oldName
end

local function fix157AssignRole(actor, row, levelID, levelName)
        local oldRoleID, oldName = fix157CurrentRoleName(row.id)
        if oldRoleID then
                mysql:query_free("UPDATE staff_role_members SET RoleID=" .. levelID
                        .. " WHERE AccountID=" .. tonumber(row.id))
        else
                mysql:query_free("INSERT INTO staff_role_members (RoleID, AccountID) VALUES ("
                        .. levelID .. ", " .. tonumber(row.id) .. ")")
        end
        -- [Fix #14] log tells the truth: compare ladder position old vs new
        local changeType = "Promotion"
        if oldRoleID and type(getRankTitleIndex) == "function" then
                local oldIdx = getRankTitleIndex(oldName)
                local newIdx = getRankTitleIndex(tostring(levelName or "-"))
                if oldIdx and newIdx and newIdx < oldIdx then
                        changeType = "Demotion"
                end
        end
        addChangelog(changeType, row.username, oldName or "-", tostring(levelName or "-"), actor)
        outputChatBox("Staff updated: " .. tostring(row.username) .. " -> "
                .. tostring(levelName) .. " (" .. changeType .. ")", actor, 0, 255, 0)
        broadcastRankChange(changeType == "Demotion" and "demoted" or "promoted",
                row.username, tostring(levelName or "-"), changeType == "Demotion", actor)
        refresh(actor)
        local online = fix157PlayerByAccountID(row.id)
        if online and type(refreshPlayerRank) == "function" then
                refreshPlayerRank(online)
        end
        fix157Log(actor, "GIVEROLE " .. tostring(row.username) .. " -> " .. tostring(levelName)
                .. " (" .. changeType .. ")", "account#" .. tostring(row.id))
end

local function fix157ClearRole(actor, row)
        local oldRoleID, oldName = fix157CurrentRoleName(row.id)
        mysql:query_free("DELETE FROM staff_role_members WHERE AccountID=" .. tonumber(row.id))
        addChangelog("Demotion", row.username, oldName or "-", "Player", actor)
        outputChatBox("Staff removed: " .. tostring(row.username)
                .. (oldRoleID and (" (was: " .. oldName .. ")") or ""), actor, 0, 255, 0)
        broadcastRankChange("removed", row.username, false, true, actor)
        refresh(actor)
        local online = fix157PlayerByAccountID(row.id)
        if online and type(refreshPlayerRank) == "function" then
                refreshPlayerRank(online)
        end
        fix157Log(actor, "TAKEROLE " .. tostring(row.username)
                .. (oldRoleID and (" (was: " .. oldName .. ")") or ""), "account#" .. tostring(row.id))
end

-- [Fix #157] owner.giverole — by rank ID or rank name
addCommandHandler("giverole", function(player, cmd, account, roleArg)
        if not fix157Check(player, "owner.giverole") then return end
        if not account or not roleArg then
                fix157Syntax(player, cmd, "[Account Username / Player] [Rank ID or Rank Name]")
                return
        end
        local row = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        local levelID, levelName = fix157FindRoleByArg(roleArg)
        if not levelID then
                outputChatBox("Rank not found: " .. tostring(roleArg)
                        .. "  (use a rank ID or an exact rank name)", player, 255, 0, 0)
                return
        end
        fix157AssignRole(player, row, levelID, levelName)
end, false, false)

-- [Fix #157] owner.setroleid — same, but the argument must be a rank ID
addCommandHandler("setroleid", function(player, cmd, account, roleID)
        if not fix157Check(player, "owner.setroleid") then return end
        if not account or not roleID then
                fix157Syntax(player, cmd, "[Account Username / Player] [Rank ID]")
                return
        end
        roleID = fix157Trim(roleID)
        if not roleID:match("^%d+$") then
                outputChatBox("Rank ID must be a number (see the ID column in the panel).",
                        player, 255, 0, 0)
                return
        end
        local row = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. tostring(account), player, 255, 0, 0)
                return
        end
        local levelID, levelName = fix157FindRoleByArg(roleID)
        if not levelID then
                outputChatBox("Rank not found: ID " .. roleID, player, 255, 0, 0)
                return
        end
        fix157AssignRole(player, row, levelID, levelName)
end, false, false)

-- [Fix #157] owner.takerole — drop the staff role (same as the panel button)
addCommandHandler("takerole", function(player, cmd, account)
        if not fix157Check(player, "owner.takerole") then return end
        account = fix157Trim(account)
        if account == "" then
                fix157Syntax(player, cmd, "[Account Username / Player]")
                return
        end
        local row = fix157Account(account)
        if not row then
                outputChatBox("Account not found: " .. account, player, 255, 0, 0)
                return
        end
        local oldRoleID = fix157CurrentRoleName(row.id)
        if not oldRoleID then
                outputChatBox("Account has no staff role: " .. tostring(row.username),
                        player, 255, 194, 14)
                return
        end
        fix157ClearRole(player, row)
end, false, false)

-- ======================================================== generic admin tools --

-- [Fix #157] admin.setfpslimit — gate key existed, no handler anywhere
addCommandHandler("setfpslimit", function(player, cmd, limit)
        if not fix157Check(player, "admin.setfpslimit") then return end
        local n = tonumber(limit)
        if not n or n < 10 or n > 100 or n % 1 ~= 0 then
                fix157Syntax(player, cmd, "[FPS Limit: 10-100]")
                return
        end
        local old = (type(getFPSLimit) == "function") and getFPSLimit() or "?"
        setFPSLimit(n)
        outputChatBox("FPS limit changed: " .. tostring(old) .. " -> " .. n, player, 0, 255, 0)
        fix157Log(player, "SETFPSLIMIT " .. tostring(old) .. " -> " .. n, "server")
end, false, false)

-- [Fix #157] admin.setgametype
addCommandHandler("setgametype", function(player, cmd, ...)
        if not fix157Check(player, "admin.setgametype") then return end
        local text = fix157Trim(table.concat({...}, " "))
        if text == "" then
                fix157Syntax(player, cmd, "[Game Type Text]")
                return
        end
        local old = tostring(getGameType())
        setGameType(text)
        outputChatBox("Game type changed: '" .. old .. "' -> '" .. text .. "'", player, 0, 255, 0)
        fix157Log(player, "SETGAMETYPE '" .. old .. "' -> '" .. text .. "'", "server")
end, false, false)

-- [Fix #157] admin.clearchatforall — blank-lines every client's chat buffer
addCommandHandler("clearchatforall", function(player, cmd)
        if not fix157Check(player, "admin.clearchatforall") then return end
        for i = 1, 30 do
                outputChatBox(" ", root, 0, 0, 0)
        end
        outputChatBox("Chat cleared by staff.", player, 194, 194, 194)
        fix157Log(player, "CLEARCHATFORALL", "server")
end, false, false)

-- [Fix #157] admin.gotoped — nearest ped in the same interior/dimension
addCommandHandler("gotoped", function(player, cmd)
        if not fix157Check(player, "admin.gotoped") then return end
        local x, y, z = getElementPosition(player)
        local best, bestDist
        for _, ped in ipairs(getElementsByType("ped")) do
                if isElement(ped)
                        and getElementDimension(ped) == getElementDimension(player)
                        and getElementInterior(ped) == getElementInterior(player) then
                        local px, py, pz = getElementPosition(ped)
                        local dist = getDistanceBetweenPoints3D(x, y, z, px, py, pz)
                        if not bestDist or dist < bestDist then
                                best, bestDist = ped, dist
                        end
                end
        end
        if not isElement(best) then
                outputChatBox("No pedestrians found in your interior/dimension.", player, 255, 0, 0)
                return
        end
        local px, py, pz = getElementPosition(best)
        setElementPosition(player, px, py, pz + 1)
        outputChatBox("Teleported to the nearest ped (model " .. getElementModel(best)
                .. ", " .. math.floor(bestDist) .. " m).", player, 0, 255, 0)
        fix157Log(player, "GOTOPED model " .. getElementModel(best), player)
end, false, false)

-- [Fix #157] character.setweight — mirror of /setheight; 40-140 is the range
-- the game's own weight editor accepts (social-system/g_look.lua)
addCommandHandler("setweight", function(player, cmd, targetQuery, weight)
        if not fix157Check(player, "character.setweight") then return end
        if not targetQuery or not weight then
                fix157Syntax(player, cmd, "[Player Partial Nick / ID] [Weight in kg: 40-140]")
                return
        end
        local kg = tonumber(weight)
        if not kg or kg < 40 or kg > 140 or kg % 1 ~= 0 then
                outputChatBox("Weight must be a whole number between 40 and 140 kg.",
                        player, 255, 0, 0)
                return
        end
        local target, targetName = exports.global:findPlayerByPartialNick(player, targetQuery)
        if not isElement(target) then return end
        local dbid = tonumber(getElementData(target, "dbid"))
        if not dbid then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end
        mysql:query_free("UPDATE characters SET weight='" .. mysql:escape_string(tostring(kg))
                .. "' WHERE id=" .. dbid)
        exports.anticheat:changeProtectedElementDataEx(target, "weight", kg, true)
        outputChatBox("You changed " .. targetName .. "'s weight to " .. kg .. " kg.",
                player, 0, 255, 0)
        if target ~= player then
                outputChatBox("Your weight was set to " .. kg .. " kg.", target, 0, 255, 0)
        end
        fix157Log(player, "SETWEIGHT " .. targetName .. " " .. kg .. "kg", target)
end, false, false)

-- [Fix #157] admin.unmute — /pmute already toggles both elementData + the
-- accounts column; this is the one-way version the panel right promised
addCommandHandler("unmute", function(player, cmd, targetQuery)
        if not fix157Check(player, "admin.unmute") then return end
        if not targetQuery then
                fix157Syntax(player, cmd, "[Player Partial Nick / ID]")
                return
        end
        local target, targetName = exports.global:findPlayerByPartialNick(player, targetQuery)
        if not isElement(target) then return end
        if tonumber(getElementData(target, "loggedin") or 0) ~= 1 then
                outputChatBox("Player is not logged in.", player, 255, 0, 0)
                return
        end
        local hiddenAdmin = getElementData(player, "hiddenadmin")
        exports.anticheat:changeProtectedElementDataEx(target, "muted", 0, false)
        mysql:query_free("UPDATE accounts SET muted=" .. mysql:escape_string(
                tostring(getElementData(target, "muted") or 0))
                .. " WHERE id = " .. mysql:escape_string(
                tostring(getElementData(target, "account:id") or 0)))
        outputChatBox(targetName .. " is now unmuted from OOC.", player, 0, 255, 0)
        if target ~= player then
                if hiddenAdmin == 0 then
                        outputChatBox("You were unmuted by '" .. getPlayerName(player) .. "'.",
                                target, 0, 255, 0)
                else
                        outputChatBox("You were unmuted by a Hidden Admin.", target, 0, 255, 0)
                end
        end
        exports.logs:dbLog(player, 4, target, "UNMUTE")
end, false, false)

-- =============================================================== read-only --

-- [Fix #157] admin.showbans — /showban reads ONE ban record; this lists them
addCommandHandler("showbans", function(player, cmd, count)
        if not fix157Check(player, "admin.showbans") then return end
        local n = tonumber(count) or 10
        n = math.floor(n)
        if n < 1 or n > 20 then n = 10 end
        local totalRow = mysql:query_fetch_assoc("SELECT COUNT(*) AS c FROM bans")
        local total = (totalRow and tonumber(totalRow.c)) or 0
        outputChatBox("========== LAST " .. n .. " BANS (of " .. total .. " total) ==========",
                player, 60, 200, 120)
        if total == 0 then
                outputChatBox("No bans on record.", player, 255, 194, 14)
                return
        end
        local q = mysql:query("SELECT b.id, b.date, b.serial, b.ip, b.reason,"
                .. " au.username AS banned, ad.username AS byName FROM bans b"
                .. " LEFT JOIN accounts au ON au.id = b.account"
                .. " LEFT JOIN accounts ad ON ad.id = b.admin"
                .. " ORDER BY b.id DESC LIMIT " .. n)
        if not q then
                outputChatBox("Ban query failed - run /staffdb", player, 255, 0, 0)
                return
        end
        local shown = 0
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                shown = shown + 1
                local reason = tostring(row.reason or "-")
                if #reason > 60 then reason = reason:sub(1, 57) .. "..." end
                local who = tostring(row.banned or ("serial " .. tostring(row.serial or "-")))
                if row.ip and tostring(row.ip) ~= "" then
                        who = who .. " / " .. tostring(row.ip)
                end
                outputChatBox("#" .. tostring(row.id) .. "  " .. tostring(row.date or "?")
                        .. "  |  " .. who .. "  |  by "
                        .. tostring(row.byName or "unknown"), player, 220, 220, 220)
                outputChatBox("      reason: " .. reason, player, 190, 190, 190)
        end
        mysql:free_result(q)
        if shown == 0 then
                outputChatBox("No bans on record.", player, 255, 194, 14)
        end
end, false, false)

-- [Fix #157] admin.showsettings — read-only snapshot of the server settings
local function fix157Safe(fnName, ...)
        local fn = _G[fnName]
        if type(fn) ~= "function" then return "?" end
        local ok, v = pcall(fn, ...)
        if not ok then return "?" end
        return v
end

addCommandHandler("showsettings", function(player, cmd)
        if not fix157Check(player, "admin.showsettings") then return end
        local hour, minute = fix157Safe("getHour"), fix157Safe("getMinute")
        local timeStr = (type(hour) == "number" and type(minute) == "number")
                and (tostring(hour) .. ":" .. ("%02d"):format(minute)) or "?"
        outputChatBox("========== SERVER SETTINGS ==========", player, 60, 200, 120)
        outputChatBox("name: " .. tostring(fix157Safe("getServerName")), player, 220, 220, 220)
        outputChatBox("gametype: " .. tostring(fix157Safe("getGameType"))
                .. "  |  map: " .. tostring(fix157Safe("getMapName")), player, 220, 220, 220)
        outputChatBox("max players: " .. tostring(fix157Safe("getMaxPlayers"))
                .. "  |  fps limit: " .. tostring(fix157Safe("getFPSLimit")),
                player, 220, 220, 220)
        outputChatBox("weather: " .. tostring(fix157Safe("getWeather"))
                .. "  |  time: " .. timeStr
                .. "  |  minute duration: " .. tostring(fix157Safe("getMinuteDuration")) .. " ms",
                player, 220, 220, 220)
        local running = (type(getRunningResources) == "function")
                and #getRunningResources() or "?"
        outputChatBox("resources: " .. tostring(fix157Safe("getTotalResources"))
                .. "  |  running: " .. tostring(running), player, 220, 220, 220)
        fix157Log(player, "SHOWSETTINGS", player)
end, false, false)

-- [Fix #157] admin.getaccount — quick account card for an ONLINE player
addCommandHandler("getaccount", function(player, cmd, targetQuery)
        if not fix157Check(player, "admin.getaccount") then return end
        if not targetQuery then
                fix157Syntax(player, cmd, "[Online Player Partial Nick / ID]")
                return
        end
        local target = exports.global:findPlayerByPartialNick(player, targetQuery)
        if not isElement(target) then return end
        local aid = tonumber(getElementData(target, "account:id"))
        if not aid then
                outputChatBox("That player has no account data loaded.", player, 255, 0, 0)
                return
        end
        local row = mysql:query_fetch_assoc("SELECT " .. FIX157_ACCOUNT_COLS
                .. " FROM accounts WHERE id=" .. aid)
        if not row then
                outputChatBox("Account not found for that player.", player, 255, 0, 0)
                return
        end
        fix157PrintAccount(player, row)
        fix157Log(player, "GETACCOUNT " .. tostring(row.username) .. " (#" .. tostring(row.id) .. ")",
                target)
end, false, false)

-- ===========================================================================
-- [Fix #160] A5: RESOURCES/MODS section of the staff panel
--   list     rpadmin:requestResources -> admin.manager.resources
--   action   rpadmin:resourceAction    -> admin.manager.resources
--                                      + admin.startres / admin.stopres /
--                                        admin.restartres (per action)
-- Both are BUTTON rights, not commands: /startres /stopres /restartres keep
-- their own gates in command_gates_s.lua untouched.
-- ===========================================================================

local function resourceListPayload()
        local out = {}
        for _, res in ipairs(getResources()) do
                out[#out + 1] = {
                        name = getResourceName(res),
                        state = getResourceState(res),
                }
        end
        table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
        return out
end

local RESOURCE_ACTION_RIGHTS = {
        start = "admin.startres",
        stop = "admin.stopres",
        restart = "admin.restartres",
}

-- same backend-first ladder as hasManageResources, per right
local function resourceRightHas(player, right)
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right) and true or false
                end
                return false
        end
        return exports.integration:isPlayerLeadAdmin(player) and true or false
end

local function checkResourceAction(player, action)
        if not hasManageResources(player) then
                outputChatBox("You don't have permission to manage resources.", player, 255, 80, 80)
                return false
        end
        local right = RESOURCE_ACTION_RIGHTS[action]
        if not right then
                outputChatBox("Unknown resource action: " .. tostring(action), player, 255, 80, 80)
                return false
        end
        if not resourceRightHas(player, right) then
                outputChatBox("You don't have permission to " .. action .. " resources (" .. right .. ").",
                        player, 255, 80, 80)
                return false
        end
        return true
end

addEvent("rpadmin:requestResources", true)
addEventHandler("rpadmin:requestResources", root, function()
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not hasManageResources(player) then
                outputChatBox("You don't have permission to manage resources.", player, 255, 80, 80)
                return
        end
        triggerClientEvent(player, "rpadmin:sendResources", player, resourceListPayload())
end)

addEvent("rpadmin:resourceAction", true)
addEventHandler("rpadmin:resourceAction", root, function(action, resourceName)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        action = tostring(action or ""):lower()
        resourceName = tostring(resourceName or "")
        if not checkResourceAction(player, action) then return end

        local theResource = getResourceFromName(resourceName)
        if not theResource then
                outputChatBox("Resource not found: " .. resourceName, player, 255, 0, 0)
                return
        end
        -- [Fix #160] this panel lives in admin-system: never let a click from
        -- inside it tear the panel (and every gate above) down
        if resourceName == "admin-system" and action ~= "start" then
                outputChatBox("The admin-system resource is protected.", player, 255, 0, 0)
                return
        end

        local state = getResourceState(theResource)
        local ok = false
        if action == "start" then
                if state == "running" then
                        outputChatBox(resourceName .. " is already running.", player, 255, 194, 14)
                        triggerClientEvent(player, "rpadmin:sendResources", player, resourceListPayload())
                        return
                end
                ok = startResource(theResource)
        elseif action == "stop" then
                if state ~= "running" then
                        outputChatBox(resourceName .. " is not running (" .. tostring(state) .. ").",
                                player, 255, 194, 14)
                        triggerClientEvent(player, "rpadmin:sendResources", player, resourceListPayload())
                        return
                end
                ok = stopResource(theResource)
        else -- restart
                if state == "running" then
                        ok = restartResource(theResource)
                else
                        ok = startResource(theResource)
                end
        end

        if ok then
                outputChatBox("Resource " .. resourceName .. ": " .. action .. " requested.", player, 0, 255, 0)
                fix157Log(player, ("RESOURCE %s %s (was: %s)"):format(action:upper(), resourceName,
                        tostring(state)), player)
        else
                outputChatBox("Could not " .. action .. " " .. resourceName .. " (" .. tostring(state) .. ").",
                        player, 255, 0, 0)
        end
        triggerClientEvent(player, "rpadmin:sendResources", player, resourceListPayload())
end)

