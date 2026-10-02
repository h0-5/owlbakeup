--[[ ------------------------------------------------------------------------
        Vortex Staff System — TEAMS (تيمات) — server.

        A TEAM is a stored permission BUNDLE layered on top of the 21-rank
        ladder. A player's effective rights are the UNION (OR) of:

              his RANK rights   ∪   the rights of every team he is a member of

        Resolution lives in playerHasRight (staff_manager_bridge_s.lua);
        this file owns storage, the panel API and every mutation.

        Tables (created idempotently on resource start AND shipped as
        database/12_fix160_teams.sql — both are import-safe):

              staff_teams         id / name / rights (CSV) / createdby / created
              staff_team_members  id / teamid / account_id / addedby / date
                                  UNIQUE (teamid, account_id)
        The member key is the ACCOUNT id — exactly how staff_role_members
        stores rank membership (RoleID / AccountID), so a team membership
        follows the account across characters.

        PREDEFINED BUNDLE TEMPLATES — built from AllRights
        (staff_manager_rights.lua) through prefix/exact rules, so only rights
        that really exist in that list are ever stored:

          هاوس     house     : property.* interior.* intlib.* elevator.*
                               places.* editor.* + interiors (setint*/addint/
                               deleteint/...), gates (lockgate/makegate), peds
                               (makeped/delped/editped), makegeneric/makephone,
                               keys (givekey/duplicate.keys/keys.delete),
                               mapping helpers (editObjectProperties/Textures)
                               + shops (makeshop/showshops/shops.*)
          سيارات   vehicles  : vehicle.* (incl. vehicles.*) setveh* makeveh
                               delveh editvehicle respawn_vehicle unimpoundveh
                               restartcarshops + the admin vehicle commands
                               (admin.fixveh/fuelveh/getveh/giveveh/gotoveh/
                               destroyveh/enterveh/eject/sendtoveh/sendvehto/
                               flip/unflip/checkveh)
          بانل     panel     : admin.* support.* access.* duty.*
                               applications.* blacklist.* whitelist.*
                               + moderation/items/licenses/blips/briefcase/
                               misc tools (giveitem items.* inventory.open
                               givelicense givegunlicense cancelgunlicense
                               weapons.* disarm blip.* skins.makeskin
                               radiostations.manager bc.* activity.* cinema
                               mechanic.panel special_membership.* hidden.logs
                               debug dev.fullstatus)
          فاشنات   factions  : faction.* factions.* + makefaction removefaction
                               setfaction setfactionleader setfactioncolor
                               setfactionhotline setfactionradio
                               setfactionvehlimit setfactionname
                               setfactiontype setvehfaction jobs.setjob
          البنك    bank      : bank.* + makeatm + the admin money commands
                               (admin.setplayermoney/giveplayermoney/
                               takeplayermoney/giveallmoney)
          أكاونت   account   : accounts.* character.* level.* + account
                               lookups/management (admin.getaccount/ck/unck/
                               changename/showalts, owner.checkid/checkaccount/
                               checkserial/checkemail, owner.removeaccount/
                               removecharacter/setactivestatus, feature.give)
          ويب      web       : web.* (the whole web control panel)
          owner.*  owner     : EVERY right in AllRights (full access)
          فارغ     custom    : no rights at all — a blank team an admin can
                               fill later with the panel's Rights button

        GATES: every mutation (create / rename / delete / set rights / add
        member / remove member) is checked SERVER-SIDE with the right
        admin.manager.editmembers (backend-first rule, same ladder as
        hasEditMembers in staff_manager_s.lua). Viewing (requestTeams) stays
        open to whoever can open the panel (canPlayerAccessStaffManager).
        Every mutation invalidates the bridge's team-rights cache and
        re-pushes the Fix #160 badge rights to the affected players.
-------------------------------------------------------------------------- ]]

local mysql = exports.mysql

-- [Batch rule 1] staffTeamIsFullAccess / staffNormalizedTeamName are
-- GLOBALS owned by the bridge (staff_manager_bridge_s.lua) - it loads before
-- this file in meta.xml, so the seed below and the payload filter can call
-- them directly at runtime.

-- ============================================================================
-- templates + bundle rules
-- ============================================================================

-- id = stable key sent to the panel; name = the Arabic label the admin picks
local TEAM_TEMPLATES = {
        { id = "house",    name = "هاوس" },
        { id = "vehicles", name = "سيارات" },
        { id = "panel",    name = "بانل" },
        { id = "factions", name = "فاشنات" },
        { id = "bank",     name = "البنك" },
        { id = "account",  name = "أكاونت" },
        { id = "web",      name = "ويب" },
        { id = "owner",    name = "owner.*" },
        { id = "custom",   name = "فارغ (مخصص)" },
}

-- prefix = right starts with it; exact = right equals it; all = every right
local TEMPLATE_RULES = {
        house = {
                prefixes = { "property.", "interior.", "intlib.", "elevator.",
                        "places.", "editor." },
                exact = {
                        "addint", "deleteint", "setintid", "setintowner",
                        "removeintowner", "setintprice", "setintforsale",
                        "cancelintsale", "setintenterance", "setintname",
                        "lockgate", "makegate", "makeped", "delped", "editped",
                        "makegeneric", "makephone", "editObjectProperties",
                        "duplicate.keys", "keys.delete", "givekey", "Textures",
                        "makeshop", "showshops", "additemsinshop",
                        "additeminshop", "shops.items", "shops.manager",
                        "shops.changeQuantity", "shops.list", "shops.setowner",
                        "shops.getowner", "shops.setname",
                },
        },
        vehicles = {
                prefixes = { "vehicle.", "setveh" },
                exact = {
                        "makeveh", "delveh", "editvehicle", "respawn_vehicle",
                        "unimpoundveh", "vehicles.library", "restartcarshops",
                        "setvehtint",
                        "admin.fixveh", "admin.fuelveh", "admin.getveh",
                        "admin.giveveh", "admin.gotoveh", "admin.destroyveh",
                        "admin.enterveh", "admin.eject", "admin.sendtoveh",
                        "admin.sendvehto", "admin.flip", "admin.unflip",
                        "admin.checkveh",
                },
        },
        panel = {
                prefixes = { "admin.", "support.", "access.", "duty.",
                        "applications.", "blacklist.", "whitelist." },
                exact = {
                        "hidden.logs", "debug", "dev.fullstatus",
                        "giveitem", "items.list", "items.list.add",
                        "items.list.edit", "items.list.remove", "inventory.open",
                        "givelicense", "givegunlicense", "cancelgunlicense",
                        "weapons.search", "weapons.goto", "disarm",
                        "blip.make", "blip.remove", "skins.makeskin",
                        "radiostations.manager", "bc.givebc", "bc.takebc",
                        "bc.checkbc", "bc.giveallbc", "activity.create",
                        "activity.end", "cinema", "mechanic.panel",
                        "special_membership.add", "special_membership.remove",
                },
        },
        factions = {
                prefixes = { "faction.", "factions." },
                exact = {
                        "makefaction", "removefaction", "setfaction",
                        "setfactionleader", "setfactioncolor",
                        "setfactionhotline", "setfactionradio",
                        "setfactionvehlimit", "setfactionname",
                        "setfactiontype", "setvehfaction", "jobs.setjob",
                },
        },
        bank = {
                prefixes = { "bank." },
                exact = {
                        "makeatm", "admin.setplayermoney",
                        "admin.giveplayermoney", "admin.takeplayermoney",
                        "admin.giveallmoney",
                },
        },
        account = {
                prefixes = { "accounts.", "character.", "level." },
                exact = {
                        "admin.getaccount", "admin.ck", "admin.unck",
                        "admin.changename", "admin.showalts", "owner.checkid",
                        "owner.checkaccount", "owner.checkserial",
                        "owner.checkemail", "owner.setactivestatus",
                        "owner.removeaccount", "owner.removecharacter",
                        "feature.give",
                },
        },
        web = { prefixes = { "web." } },
        owner = { all = true },
        custom = {},
}

-- filter a rule against AllRights -> the sorted list a template stores
local function templateRights(templateID)
        local rules = TEMPLATE_RULES[tostring(templateID or "")]
        if not rules then return nil end
        if type(AllRights) ~= "table" then return {} end
        local out = {}
        if rules.all then
                for _, r in ipairs(AllRights) do out[#out + 1] = tostring(r) end
                return out
        end
        for _, r in ipairs(AllRights) do
                local s = tostring(r)
                local hit = false
                for _, p in ipairs(rules.prefixes or {}) do
                        if s:sub(1, #p) == p then hit = true break end
                end
                if not hit then
                        for _, e in ipairs(rules.exact or {}) do
                                if s == e then hit = true break end
                        end
                end
                if hit then out[#out + 1] = s end
        end
        return out
end

local function findTemplate(templateID)
        for _, t in ipairs(TEAM_TEMPLATES) do
                if t.id == tostring(templateID or "") then return t end
        end
        return nil
end

-- ============================================================================
-- tables (idempotent, on resource start)
-- ============================================================================

local function ensureTeamTables()
        mysql:query_free([[CREATE TABLE IF NOT EXISTS staff_teams (
                id INT NOT NULL AUTO_INCREMENT,
                name VARCHAR(64) NOT NULL,
                rights TEXT,
                createdby VARCHAR(64),
                created DATETIME,
                hidden TINYINT NOT NULL DEFAULT 0,
                PRIMARY KEY (id))]])
        mysql:query_free([[CREATE TABLE IF NOT EXISTS staff_team_members (
                id INT NOT NULL AUTO_INCREMENT,
                teamid INT NOT NULL,
                account_id INT NOT NULL,
                addedby VARCHAR(64),
                date DATETIME,
                PRIMARY KEY (id),
                UNIQUE KEY stm_team_account (teamid, account_id),
                KEY stm_account (account_id))]])
        -- [Batch rule 2] hidden flag: CREATE ... IF NOT EXISTS does NOT add
        -- columns to an EXISTING table, so patch an old schema idempotently
        -- (same INFORMATION_SCHEMA pattern staff_manager_setup_s.lua uses).
        pcall(function()
                local col = mysql:query_fetch_assoc([[
                        SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_SCHEMA = DATABASE()
                                AND TABLE_NAME = 'staff_teams' AND COLUMN_NAME = 'hidden']])
                if col and tonumber(col.n) == 0 then
                        mysql:query_free("ALTER TABLE staff_teams ADD COLUMN hidden TINYINT NOT NULL DEFAULT 0")
                        outputDebugString("[Vortex Staff] added missing staff_teams.hidden column")
                end
        end)
end

addEventHandler("onResourceStart", resourceRoot, function()
        ensureTeamTables()
        -- runtime documentation: how many AllRights entries each bundle holds
        local parts = {}
        for _, t in ipairs(TEAM_TEMPLATES) do
                local r = templateRights(t.id)
                parts[#parts + 1] = t.name .. "=" .. tostring(r and #r or "?")
        end
        outputDebugString("[Vortex Staff] teams ready - bundle sizes ("
                .. (type(AllRights) == "table" and #AllRights or 0)
                .. " AllRights): " .. table.concat(parts, ", "))
end)

-- ============================================================================
-- helpers
-- ============================================================================

local function trim(s)
        s = tostring(s or "")
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- [Fix #51 mirror] the panel grid may hand over "#00FF00● name" cell text
local function stripStatusPrefix(raw)
        local s = tostring(raw or "")
        s = s:gsub("^#[0-9A-Fa-f]+%s*", "")
        s = s:gsub("^●%s*", ""):gsub("^○%s*", "")
        s = s:gsub("^%s+", "")
        return s
end

local function splitRightsCSV(raw)
        local out = {}
        for token in tostring(raw or ""):gmatch("[^,]+") do
                local right = trim(token)
                if right ~= "" then out[#out + 1] = right end
        end
        return out
end

local function joinRightsCSV(list)
        local keys = {}
        local seen = {}
        for _, r in ipairs(list or {}) do
                local s = tostring(r)
                if s ~= "" and not seen[s] then
                        seen[s] = true
                        keys[#keys + 1] = s
                end
        end
        table.sort(keys)
        return table.concat(keys, ",")
end

-- known-right set (AllRights is THE source of truth, same rule as the bridge)
local knownRightsSet
local function isKnownRight(right)
        if type(AllRights) ~= "table" then return false end
        if not knownRightsSet then
                knownRightsSet = {}
                for _, r in ipairs(AllRights) do knownRightsSet[tostring(r)] = true end
        end
        return knownRightsSet[tostring(right)] == true
end

-- [Batch rule 1] STARTUP SEED: a team row with a normalized name of
-- "fullaccess" (or the legacy typo "fullacsess") MUST exist, carrying EVERY
-- right in AllRights - Full Access is what grants full command permission to
-- a member with no admin rank at all (hasCommandRight). Idempotent: it only
-- inserts when no matching row is there, never touches an existing one.
-- Registered as its OWN onResourceStart handler because the CSV helper above
-- is a local declared after the first start handler (lexical scope).
local function ensureFullAccessTeam()
        if type(AllRights) ~= "table" or #AllRights == 0 then return end
        local found = false
        local q = mysql:query("SELECT id, name FROM staff_teams")
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        if staffTeamIsFullAccess(row.name) then
                                found = true
                                break
                        end
                end
                mysql:free_result(q)
        end
        if found then return end
        mysql:query_free("INSERT INTO staff_teams (name, rights, createdby, created) VALUES ('"
                .. mysql:escape_string("Full Access") .. "', '"
                .. mysql:escape_string(joinRightsCSV(AllRights)) .. "', 'system', NOW())")
        outputDebugString("[Vortex Staff] seeded the Full Access team (" .. #AllRights
                .. " rights) - granted to members even without any admin rank")
        if type(staffTeamsInvalidateRights) == "function" then
                staffTeamsInvalidateRights()
        end
end

addEventHandler("onResourceStart", resourceRoot, function()
        ensureFullAccessTeam()
end)

local function fetchTeamByID(teamID)
        teamID = tonumber(teamID)
        if not teamID then return nil end
        return mysql:query_fetch_assoc("SELECT id, name, rights FROM staff_teams WHERE id="
                .. teamID .. " LIMIT 1")
end

local function isTeamMember(teamID, accountID)
        return mysql:query_fetch_assoc("SELECT id FROM staff_team_members WHERE teamid="
                .. tonumber(teamID) .. " AND account_id=" .. tonumber(accountID) .. " LIMIT 1")
end

local function actorName(player)
        if isElement(player) and getElementType(player) == "player" then
                return getElementData(player, "account:username") or getPlayerName(player) or "Unknown"
        end
        return "System"
end

-- account lookup: numeric id -> exact username -> online partial nick ->
-- unique offline username prefix. Returns row { id, username } or nil, reason
local function resolveAccount(query)
        local q = trim(stripStatusPrefix(query))
        if q == "" then return nil, "empty" end
        local esc = mysql:escape_string(q)
        local row
        if q:match("^%d+$") then
                row = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE id="
                        .. tonumber(q) .. " LIMIT 1")
        end
        if not row then
                row = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE LOWER(username)=LOWER('"
                        .. esc .. "') LIMIT 1")
        end
        if not row then
                -- partial nick / scoreboard id of an ONLINE player (quiet mode)
                local ok, target = pcall(function()
                        return exports.global:findPlayerByPartialNick(nil, q, true)
                end)
                if ok and isElement(target) and getElementType(target) == "player" then
                        local aid = tonumber(getElementData(target, "account:id"))
                        if aid then
                                row = mysql:query_fetch_assoc("SELECT id, username FROM accounts WHERE id="
                                        .. aid .. " LIMIT 1")
                        end
                end
        end
        if not row then
                -- offline partial: only when the prefix matches EXACTLY one
                -- account, otherwise the target would be a guess
                local pattern = (q:gsub("[%%_]", function(c) return "\\" .. c end))
                local qq = mysql:query("SELECT id, username FROM accounts WHERE LOWER(username) LIKE LOWER('"
                        .. mysql:escape_string(pattern)
                        .. "%') ORDER BY username ASC LIMIT 2")
                local first, count = nil, 0
                if qq then
                        while true do
                                local r = mysql:fetch_assoc(qq)
                                if not r then break end
                                count = count + 1
                                if count == 1 then first = r end
                        end
                        mysql:free_result(qq)
                end
                if count == 1 then
                        row = first
                elseif count > 1 then
                        return nil, "ambiguous"
                end
        end
        if not row then return nil, "notfound" end
        return { id = tonumber(row.id), username = tostring(row.username) }
end

-- backend-first gate: the right admin.manager.editmembers (mirror of
-- hasEditMembers in staff_manager_s.lua, Fix #25 - the rank's stored rights
-- decide for ranked staff; the legacy ladder + the TEAM union decide for
-- everyone else)
local function canEditTeams(player)
        if not (isElement(player) and getElementType(player) == "player") then
                return false
        end
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, "admin.manager.editmembers") and true or false
                end
                return false
        end
        -- no Vortex rank: playerHasRight still answers through the TEAM union
        -- (and the legacy admin>=4 fallback), then the panel's own ladder
        if type(playerHasRight) == "function"
                and playerHasRight(player, "admin.manager.editmembers") then
                return true
        end
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function denyEdit(player)
        outputChatBox("You don't have permission to edit staff teams.", player, 255, 80, 80)
end

-- ============================================================================
-- panel payload
-- ============================================================================

-- [Batch rule 2] the payload is built PER VIEWER: a hidden team (hidden=1)
-- is dropped entirely for everyone except rank 20/21 and dev-team members;
-- those entitled viewers receive the row with hidden=true so the panel can
-- tag it "(hidden)". viewer == nil (internal callers that never render the
-- list) is treated as NOT entitled - hidden rows never leak by accident.
local function fetchTeamsPayload(viewer)
        local payload = { teams = {}, templates = {} }
        for _, t in ipairs(TEAM_TEMPLATES) do
                payload.templates[#payload.templates + 1] = { id = t.id, name = t.name }
        end
        local canSee = false
        if viewer ~= nil and type(staffCanSeeHiddenStaff) == "function" then
                local ok, res = pcall(staffCanSeeHiddenStaff, viewer)
                canSee = ok and res or false
        end
        local q = mysql:query("SELECT id, name, rights, hidden FROM staff_teams ORDER BY name ASC")
        if not q then return payload end
        local teamsByID = {}
        while true do
                local row = mysql:fetch_assoc(q)
                if not row then break end
                local hidden = tonumber(row.hidden) == 1
                if not hidden or canSee then
                        local rights = splitRightsCSV(row.rights)
                        local team = {
                                id = tonumber(row.id),
                                name = tostring(row.name or ""),
                                rights = rights,
                                rightsCount = #rights,
                                members = {},
                                memberCount = 0,
                                hidden = hidden,
                        }
                        teamsByID[team.id] = team
                        payload.teams[#payload.teams + 1] = team
                end
        end
        mysql:free_result(q)

        local online = {}
        for _, p in ipairs(getElementsByType("player")) do
                local acc = tonumber(getElementData(p, "account:id"))
                if acc then online[acc] = true end
        end
        local mq = mysql:query("SELECT m.teamid, m.account_id, a.username"
                .. " FROM staff_team_members m"
                .. " LEFT JOIN accounts a ON a.id = m.account_id"
                .. " ORDER BY a.username ASC")
        if mq then
                while true do
                        local row = mysql:fetch_assoc(mq)
                        if not row then break end
                        local team = teamsByID[tonumber(row.teamid)]
                        if team then
                                local acc = tonumber(row.account_id) or 0
                                local m = team.members
                                m[#m + 1] = {
                                        AccountID = acc,
                                        Account = tostring(row.username or ("#" .. acc)),
                                        Online = online[acc] == true,
                                }
                                team.memberCount = #m
                        end
                end
                mysql:free_result(mq)
        end
        return payload
end

-- global hook: staff_manager_s.lua sendPanel() pulls the teams block from
-- here (the viewing player travels with it so hidden rows can be filtered)
function fetchStaffTeamsPayload(viewer)
        return fetchTeamsPayload(viewer)
end

local function pushTeamsToViewers()
        for _, p in ipairs(getElementsByType("player")) do
                if type(canPlayerAccessStaffManager) ~= "function"
                        or canPlayerAccessStaffManager(p) then
                        -- [Batch rule 2] per-viewer payload: a hidden team is
                        -- invisible to every non-entitled viewer
                        triggerClientEvent(p, "rpadmin:sendTeams", p, fetchTeamsPayload(p))
                end
        end
end

-- after ANY mutation: drop the bridge's team-rights cache (it is keyed per
-- account and every bundle/membership change can move it), re-push the
-- Fix #160 badge rights (they are computed THROUGH playerHasRight, so teams
-- can grant badges too) and re-send the team list to every panel viewer.
local function afterTeamMutation()
        if type(staffTeamsInvalidateRights) == "function" then
                staffTeamsInvalidateRights()
        end
        -- [Batch rules 1+2] a membership/hidden change moves two flags the
        -- OTHER resources read off element data (F1 list, TAB scoreboard):
        --   staff:hasTeam    - the player belongs to some team (rank-less team
        --                      members are invisible as staff),
        --   staff:seehhidden  - the viewer may see hidden ranks/teams (rank
        --                      20/21 or a "dev" team member).
        -- Re-push them for EVERYONE - the hidden flag of a team can flip for
        -- all viewers at once.
        if type(staffPushStaffMeta) == "function" then
                for _, p in ipairs(getElementsByType("player")) do
                        staffPushStaffMeta(p)
                end
        end
        -- [Fix #U3] a team can grant (or lose) duty.adminduty, and a team
        -- membership change can also drop the union below what an on-duty
        -- player needs -> re-check everybody's duty flag right here.
        if type(enforceStaffDutyRights) == "function" then
                for _, p in ipairs(getElementsByType("player")) do
                        enforceStaffDutyRights(p)
                end
        end
        -- [Fix #U6] team rights feed panelRights too -> refresh the mirrored
        -- flags of every panel viewer (no open/close, no toggle).
        if type(refreshStaffPanelRightsAll) == "function" then
                pcall(refreshStaffPanelRightsAll)
        end
        if type(pushFix160BadgeRights) == "function"
                or type(teamBadgeRightsValue) == "function" then
                for _, p in ipairs(getElementsByType("player")) do
                        if getElementData(p, "rank:index") then
                                -- ranked: the full union (rank + teams)
                                if type(pushFix160BadgeRights) == "function" then
                                        pushFix160BadgeRights(p)
                                end
                        elseif type(teamBadgeRightsValue) == "function" then
                                -- no Vortex rank: teams only (keeps the Fix #160
                                -- "no rank -> no badge from the legacy ladder"
                                -- behaviour byte-identical for teamless players)
                                local value = teamBadgeRightsValue(p) or ""
                                if getElementData(p, "fix160.badgerights") ~= value then
                                        setElementData(p, "fix160.badgerights", value, true)
                                end
                        end
                end
        end
        pushTeamsToViewers()
end

-- ============================================================================
-- events (every one of them gated server-side with admin.manager.editmembers)
-- ============================================================================

-- viewing: open to whoever can open the panel (admin.manager.panel ladder)
addEvent("rpadmin:requestTeams", true)
addEventHandler("rpadmin:requestTeams", root, function()
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if type(canPlayerAccessStaffManager) == "function"
                and not canPlayerAccessStaffManager(player) then
                outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                return
        end
        triggerClientEvent(player, "rpadmin:sendTeams", player, fetchTeamsPayload(player))
end)

-- create a team from a template (name + template, the minimum-viable create)
addEvent("rpadmin:teamCreate", true)
addEventHandler("rpadmin:teamCreate", root, function(name, templateID, hidden)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        name = trim(name)
        if name == "" then
                outputChatBox("Type a team name first.", player, 255, 80, 80)
                return
        end
        if #name > 64 then
                outputChatBox("Team names are at most 64 characters long.", player, 255, 80, 80)
                return
        end
        local template = findTemplate(templateID)
        if not template then
                outputChatBox("Unknown team template: " .. tostring(templateID), player, 255, 80, 80)
                return
        end
        local exists = mysql:query_fetch_assoc("SELECT id FROM staff_teams WHERE LOWER(name)=LOWER('"
                .. mysql:escape_string(name) .. "') LIMIT 1")
        if exists then
                outputChatBox("A team with this name already exists.", player, 255, 0, 0)
                return
        end
        local rights = templateRights(template.id) or {}
        -- [Batch rule 2] optional hidden flag straight from the editor checkbox
        local hiddenFlag = (hidden == true or tonumber(hidden) == 1) and 1 or 0
        mysql:query_free("INSERT INTO staff_teams (name, rights, createdby, created, hidden) VALUES ('"
                .. mysql:escape_string(name) .. "', '"
                .. mysql:escape_string(joinRightsCSV(rights)) .. "', '"
                .. mysql:escape_string(actorName(player)) .. "', NOW(), " .. hiddenFlag .. ")")
        outputChatBox("Team created: " .. name .. "  |  template: " .. template.name
                .. "  |  rights: " .. #rights, player, 0, 255, 0)
        afterTeamMutation()
end)

-- rename a team
addEvent("rpadmin:teamRename", true)
addEventHandler("rpadmin:teamRename", root, function(teamID, newName)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        newName = trim(newName)
        if newName == "" then
                outputChatBox("Type the new team name first.", player, 255, 80, 80)
                return
        end
        if #newName > 64 then
                outputChatBox("Team names are at most 64 characters long.", player, 255, 80, 80)
                return
        end
        local dup = mysql:query_fetch_assoc("SELECT id FROM staff_teams WHERE LOWER(name)=LOWER('"
                .. mysql:escape_string(newName) .. "') AND id<>" .. tonumber(team.id) .. " LIMIT 1")
        if dup then
                outputChatBox("A team with this name already exists.", player, 255, 0, 0)
                return
        end
        local before = tostring(team.name)
        mysql:query_free("UPDATE staff_teams SET name='" .. mysql:escape_string(newName)
                .. "' WHERE id=" .. tonumber(team.id))
        outputChatBox("Team renamed: " .. before .. " -> " .. newName, player, 0, 255, 0)
        afterTeamMutation()
end)

-- delete a team (its memberships go with it)
addEvent("rpadmin:teamDelete", true)
addEventHandler("rpadmin:teamDelete", root, function(teamID)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        local members = mysql:query_fetch_assoc("SELECT COUNT(*) AS n FROM staff_team_members WHERE teamid="
                .. tonumber(team.id))
        local memberCount = members and tonumber(members.n) or 0
        mysql:query_free("DELETE FROM staff_team_members WHERE teamid=" .. tonumber(team.id))
        mysql:query_free("DELETE FROM staff_teams WHERE id=" .. tonumber(team.id))
        outputChatBox("Team deleted: " .. tostring(team.name) .. " (" .. memberCount
                .. " member(s) removed)", player, 0, 255, 0)
        afterTeamMutation()
end)

-- replace a team's rights set (the panel's Rights editor - custom teams)
addEvent("rpadmin:teamSetRights", true)
addEventHandler("rpadmin:teamSetRights", root, function(teamID, rights)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        if type(rights) ~= "table" then rights = {} end
        local clean, dropped = {}, 0
        for _, r in ipairs(rights) do
                if isKnownRight(r) then
                        clean[#clean + 1] = tostring(r)
                else
                        dropped = dropped + 1
                end
        end
        local csv = joinRightsCSV(clean)
        mysql:query_free("UPDATE staff_teams SET rights='" .. mysql:escape_string(csv)
                .. "' WHERE id=" .. tonumber(team.id))
        local line = "Team rights saved: " .. tostring(team.name) .. "  |  rights: " .. #clean
        if dropped > 0 then
                line = line .. "  (" .. dropped .. " unknown right(s) ignored)"
        end
        outputChatBox(line, player, 0, 255, 0)
        afterTeamMutation()
end)

-- [Batch rule 2] toggle a team's hidden flag (the team editor checkbox).
-- Hidden teams are invisible to every panel viewer except rank 20/21 and
-- "dev" team members - see fetchTeamsPayload above.
addEvent("rpadmin:teamSetHidden", true)
addEventHandler("rpadmin:teamSetHidden", root, function(teamID, hidden)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        local flag = (hidden == true or tonumber(hidden) == 1) and 1 or 0
        mysql:query_free("UPDATE staff_teams SET hidden=" .. flag
                .. " WHERE id=" .. tonumber(team.id))
        outputChatBox("Team " .. (flag == 1 and "hidden" or "unhidden") .. ": "
                .. tostring(team.name), player, 0, 255, 0)
        afterTeamMutation()
end)

-- add a member (by account name / account id / online partial nick / ID)
addEvent("rpadmin:teamAddMember", true)
addEventHandler("rpadmin:teamAddMember", root, function(teamID, query)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        local account, reason = resolveAccount(query)
        if not account then
                if reason == "ambiguous" then
                        outputChatBox("More than one account matches '" .. trim(query)
                                .. "' - be more specific (full account name).", player, 255, 80, 80)
                elseif reason == "empty" then
                        outputChatBox("Type an account name / player nick first.", player, 255, 80, 80)
                else
                        outputChatBox("Account not found: " .. trim(query), player, 255, 0, 0)
                end
                return
        end
        if isTeamMember(team.id, account.id) then
                outputChatBox(account.username .. " is already a member of '" .. team.name .. "'.",
                        player, 255, 194, 14)
                return
        end
        mysql:query_free("INSERT INTO staff_team_members (teamid, account_id, addedby, date) VALUES ("
                .. tonumber(team.id) .. ", " .. account.id .. ", '"
                .. mysql:escape_string(actorName(player)) .. "', NOW())")
        outputChatBox("Team member added: " .. account.username .. " -> " .. tostring(team.name),
                player, 0, 255, 0)
        afterTeamMutation()
end)

-- remove a member (same account lookup the rank-member removal uses)
addEvent("rpadmin:teamRemoveMember", true)
addEventHandler("rpadmin:teamRemoveMember", root, function(teamID, query)
        local player = client
        if not (isElement(player) and getElementType(player) == "player") then return end
        if not canEditTeams(player) then denyEdit(player) return end

        local team = fetchTeamByID(teamID)
        if not team then
                outputChatBox("Team not found.", player, 255, 80, 80)
                return
        end
        local account, reason = resolveAccount(query)
        if not account then
                if reason == "ambiguous" then
                        outputChatBox("More than one account matches '" .. trim(query)
                                .. "' - select the member from the list.", player, 255, 80, 80)
                elseif reason == "empty" then
                        outputChatBox("Select a member from the team members list first.",
                                player, 255, 80, 80)
                else
                        outputChatBox("Account not found: " .. trim(query), player, 255, 0, 0)
                end
                return
        end
        if not isTeamMember(team.id, account.id) then
                outputChatBox(account.username .. " is not a member of '" .. team.name .. "'.",
                        player, 255, 194, 14)
                return
        end
        mysql:query_free("DELETE FROM staff_team_members WHERE teamid=" .. tonumber(team.id)
                .. " AND account_id=" .. account.id)
        outputChatBox("Team member removed: " .. account.username .. " from " .. tostring(team.name),
                player, 0, 255, 0)
        afterTeamMutation()
end)
