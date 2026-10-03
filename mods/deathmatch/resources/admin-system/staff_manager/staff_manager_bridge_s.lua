--[[ ------------------------------------------------------------------------
        Vortex Staff System — rank bridge (server).

        Makes the 21-rank Vortex ladder THE staff system of the server,
        replacing the old numeric ladder (admin/supporter/scripter columns)
        everywhere, while keeping every legacy check working:

          1. On login (and after every panel mutation) the player's rank is
             resolved from staff_role_members and pushed as elementData:
               rank:index   1..21  (ladder position, the universal measure)
               rank:name    exact rank title
               rank:color   {r,g,b,a}
               rank:rights  JSON map of the rank's granted rights
             plus the LEGACY compat numbers derived from the same rank:
               admin_level / supporter_level / scripter_level
             so every resource that reads them keeps behaving correctly.

        2. integration/g_staff.lua now consults rank:index FIRST and only
           falls back to the old elementData when no Vortex rank is assigned.

        3. hasRight(player, right) export gives the server a real
           permission API driven by the per-rank Rights JSON stored by the
           panel's rank editor.

        Ladder (index -> rank):
          1  Tester                     12 Administrative Director
          2  Trial Support              13 Junior Management
          3  Support                    14 Senior Management
          4  Trial Moderator            15 Server Management
          5  Moderator                  16 Head Management
          6  Senior Moderator           17 Chief Management
          7  Trial Administrator        18 Vice Founder
          8  Administrator              19 Founder
          9  Senior Administrator       20 Diverloper
          10 Super Administrator        21 Owner
          11 Lead Administrator

        IMPORTANT: this file must load AFTER staff_manager_s.lua in meta.xml
        (same Lua state — its globals are visible to the mutations in
        staff_manager_s.lua at runtime).
-------------------------------------------------------------------------- ]]

local mysql = exports.mysql

-- ============================================================================
-- Ladder constants — MUST mirror RANK_SEED order in staff_manager_s.lua
-- ============================================================================

RANK_LADDER = {
        [1]  = "Tester",
        [2]  = "Trial Support",
        [3]  = "Support",
        [4]  = "Trial Moderator",
        [5]  = "Moderator",
        [6]  = "Senior Moderator",
        [7]  = "Trial Administrator",
        [8]  = "Administrator",
        [9]  = "Senior Administrator",
        [10] = "Super Administrator",
        [11] = "Lead Administrator",
        [12] = "Administrative Director",
        [13] = "Junior Management",
        [14] = "Senior Management",
        [15] = "Server Management",
        [16] = "Head Management",
        [17] = "Chief Management",
        [18] = "Vice Founder",
        [19] = "Founder",
        [20] = "Diverloper",
        [21] = "Owner",
}

-- Legacy compat numbers derived from each rank.  These keep every old
-- threshold (isPlayerTrialAdmin >=1, Admin >=2, Senior >=3, Lead >=4,
-- supporter 1-2, scripter 1-3) meaningful under the new ladder.
RANK_COMPAT = {
        [1]  = { admin = 0, supporter = 0, scripter = 1 }, -- Tester
        [2]  = { admin = 0, supporter = 1, scripter = 0 }, -- Trial Support
        [3]  = { admin = 0, supporter = 2, scripter = 0 }, -- Support
        [4]  = { admin = 1, supporter = 1, scripter = 0 }, -- Trial Moderator
        [5]  = { admin = 2, supporter = 1, scripter = 0 }, -- Moderator
        [6]  = { admin = 2, supporter = 1, scripter = 0 }, -- Senior Moderator
        [7]  = { admin = 2, supporter = 1, scripter = 0 }, -- Trial Administrator
        [8]  = { admin = 2, supporter = 1, scripter = 0 }, -- Administrator
        [9]  = { admin = 3, supporter = 1, scripter = 0 }, -- Senior Administrator
        [10] = { admin = 3, supporter = 1, scripter = 0 }, -- Super Administrator
        [11] = { admin = 4, supporter = 1, scripter = 0 }, -- Lead Administrator
        [12] = { admin = 4, supporter = 2, scripter = 0 }, -- Administrative Director
        [13] = { admin = 4, supporter = 2, scripter = 0 }, -- Junior Management
        [14] = { admin = 4, supporter = 2, scripter = 0 }, -- Senior Management
        [15] = { admin = 4, supporter = 2, scripter = 0 }, -- Server Management
        [16] = { admin = 4, supporter = 2, scripter = 0 }, -- Head Management
        [17] = { admin = 4, supporter = 2, scripter = 0 }, -- Chief Management
        [18] = { admin = 4, supporter = 2, scripter = 0 }, -- Vice Founder
        [19] = { admin = 4, supporter = 2, scripter = 3 }, -- Founder
        [20] = { admin = 4, supporter = 2, scripter = 2 }, -- Diverloper
        [21] = { admin = 4, supporter = 2, scripter = 3 }, -- Owner
}

-- index thresholds used by the rewritten integration gates
RANK_GATE = {
        trial_admin   = 4,  -- Trial Moderator+
        admin         = 5,  -- Moderator+
        senior_admin  = 9,  -- Senior Administrator+
        lead_admin    = 11, -- Lead Administrator+
        supporter     = 2,  -- Trial Support+
        support_mgr   = 3,  -- Support+
        scripter      = 20, -- Diverloper+
        lead_scripter = 19, -- Founder+
}

-- Legacy column -> closest new rank (highest wins).
-- [Vortex fix] the OLD ladder only ever held admin 1..4 (plus 10 = scripter);
-- anything from 5 to 21 was someone writing the NEW 21-rank index straight
-- into the old column (admin=21 = Owner). migrateLegacyStaff honors those
-- values 1:1 through RANK_LADDER before these thresholds apply.
-- [Fix #U1] this table is the SINGLE mapping used by BOTH the write path
-- (migrateLegacyStaff - runs on resource start) and the read path
-- (deriveLegacyRankRecord - runs live, so the two can never disagree).
local LEGACY_MIGRATION = {
        { column = "admin",     min = 4, rank = "Lead Administrator"  },
        { column = "admin",     min = 3, rank = "Senior Administrator" },
        { column = "admin",     min = 2, rank = "Moderator"           },
        { column = "admin",     min = 1, rank = "Trial Moderator"     },
        { column = "scripter",  min = 3, rank = "Diverloper"          },
        { column = "scripter",  min = 2, rank = "Diverloper"          },
        { column = "scripter",  min = 1, rank = "Tester"              },
        { column = "supporter", min = 2, rank = "Support"             },
        { column = "supporter", min = 1, rank = "Trial Support"       },
}

local function safeToJSON(t)
        local ok, res = pcall(toJSON, t)
        if ok then return res end
        return "{}"
end

-- ============================================================================
-- rank resolution
-- ============================================================================

-- [Fix #18] MTA's toJSON wraps an associative table inside an array:
-- toJSON({["a"]=true}) == '[ { "a": true } ]', so fromJSON gives back
-- { [1] = { a = true } } and rights[right] is ALWAYS nil. That made every
-- hasRight() check silently false -- "permissions are broken / the toggles
-- do nothing". This unwraps both shapes on read.
local function unwrapRights(t)
        if type(t) ~= "table" then return {} end
        if type(t[1]) == "table" and next(t, 1) == nil then
                return t[1]
        end
        return t
end

local function fetchRankByID(roleID)
        if not tonumber(roleID) then return nil end
        return mysql:query_fetch_assoc("SELECT ID, LevelName, Rights, Color, hidden FROM staff_roles WHERE ID="
                .. tonumber(roleID) .. " LIMIT 1")
end

local function fetchMemberRow(accountID)
        if not tonumber(accountID) then return nil end
        return mysql:query_fetch_assoc("SELECT RoleID FROM staff_role_members WHERE AccountID="
                .. tonumber(accountID) .. " LIMIT 1")
end

-- [Fix #31 - user] the FULL rank color table straight from staff_roles.
-- UI consumers (the scoreboard tab) must take rank colors from the STAFF
-- SYSTEM ("ياخذ لون الرتبة من نظام الرتب ستاف سستم") - never from their own
-- hardcoded ladders. Returns { [LevelName] = {r, g, b} }.
local function decodeColor(raw)
        local c = fromJSON(raw or "") or { 255, 255, 255, 255 }
        if type(c) ~= "table" then
                return { 255, 255, 255 }
        end
        -- toJSON({r,g,b,a}) produces a nested array "[ [ r, g, b, a ] ]";
        -- unwrap one level so the numbers are where the callers expect them.
        if type(c[1]) == "table" then
                c = c[1]
        end
        return {
                tonumber(c[1]) or 255,
                tonumber(c[2]) or 255,
                tonumber(c[3]) or 255,
        }
end

-- [Batch rule 2] the color map is pushed to EVERY client as name -> color,
-- so a hidden rank's NAME would leak through the keys. Hidden rows are
-- dropped here; entitled viewers still get the color of a hidden rank
-- through the per-member rank:color element data (applyPlayerRank).
function getAllRankColors()
        local out = {}
        local q = mysql:query("SELECT LevelName, Color, hidden FROM staff_roles")
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        if tonumber(row.hidden) ~= 1 then
                                out[tostring(row.LevelName)] = decodeColor(row.Color)
                        end
                end
                mysql:free_result(q)
        end
        return out
end

-- push the table to every client (called on staff_manager start and after
-- every rank save, so the tab always mirrors the live staff_roles colors)
function pushRankColorsToAll()
        triggerClientEvent(root, "scoreboard:rankColors", resourceRoot, getAllRankColors())
end

-- shape every consumer expects, built from a staff_roles row
local function buildRankRecord(role)
        -- ladder index: prefer the name map (survives rank re-ordering/renames
        -- in the panel); fall back to row order for custom ranks
        local index = 0
        for idx, name in pairs(RANK_LADDER) do
                if name == role.LevelName then
                        index = idx
                        break
                end
        end
        if index == 0 then
                local q = mysql:query("SELECT ID FROM staff_roles ORDER BY ID ASC")
                if q then
                        local rowID = 0
                        while true do
                                local row = mysql:fetch_assoc(q)
                                if not row then break end
                                rowID = rowID + 1
                                if tonumber(row.ID) == tonumber(role.ID) then
                                        index = math.min(rowID, 21)
                                end
                        end
                        mysql:free_result(q)
                end
        end

        local color = fromJSON(role.Color or "") or { 255, 255, 255, 255 }
        return {
                ID = tonumber(role.ID),
                index = index,
                name = role.LevelName,
                rights = unwrapRights(fromJSON(role.Rights or "")),
                color = color,
                -- [Batch rule 2] the hidden flag rides along so applyPlayerRank
                -- can push it as element data for the F1/TAB readers
                hidden = tonumber(role.hidden) == 1,
        }
end

-- [Fix #U1] LIVE legacy derivation.
-- A staff_role_members row is the normal (panel written) path.  When there is
-- NONE, the accounts columns still say this account is staff (admin=21, ...),
-- and migrateLegacyStaff would INSERT exactly that row on the NEXT resource
-- start.  Deriving it live, without writing anything, makes a live session and
-- a restart agree: the player gets ONE coherent rank (index/name/color/rights)
-- instead of the old "no rank at all -> every gate falls back to the legacy
-- ladder" state, which is what let a revoked permission keep working.
local function fetchLegacyRankTitle(accountID)
        if not tonumber(accountID) then return nil end
        local acc = mysql:query_fetch_assoc("SELECT admin, supporter, scripter FROM accounts WHERE id="
                .. tonumber(accountID) .. " LIMIT 1")
        if not acc then return nil end
        -- direct NEW-ladder index stored in the old column (5..21, excluding 10
        -- which the old ladder used for Scripter) - same rule as the write path
        local adminVal = tonumber(acc.admin) or 0
        if adminVal >= 5 and adminVal <= 21 and adminVal ~= 10 then
                return RANK_LADDER[adminVal]
        end
        for _, rule in ipairs(LEGACY_MIGRATION) do
                if tonumber(acc[rule.column] or 0) >= rule.min then
                        return rule.rank
                end
        end
        return nil
end

local function deriveLegacyRankRecord(accountID)
        local title = fetchLegacyRankTitle(accountID)
        if not title then return nil end
        local role = mysql:query_fetch_assoc(
                "SELECT ID, LevelName, Rights, Color, hidden FROM staff_roles WHERE LevelName='"
                .. mysql:escape_string(title) .. "' LIMIT 1")
        if not role then return nil end -- ladder title renamed/removed: no guess
        local record = buildRankRecord(role)
        record.derived = true
        return record
end

-- resolve the rank record (index included) for an account id; nil = no rank
function getPlayerRankRecordByAccountID(accountID)
        if not tonumber(accountID) then return nil end
        local member = fetchMemberRow(accountID)
        if member then
                -- explicit panel assignment always wins; if its rank row is
                -- gone the account has no rank (unchanged behaviour)
                local role = fetchRankByID(member.RoleID)
                if not role then return nil end
                return buildRankRecord(role)
        end
        return deriveLegacyRankRecord(accountID)
end

function getPlayerRankRecord(player)
        if not isElement(player) or getElementType(player) ~= "player" then return nil end
        local accountID = tonumber(getElementData(player, "account:id"))
        if not accountID then return nil end
        return getPlayerRankRecordByAccountID(accountID)
end

-- ============================================================================
-- applying a rank to a player (elementData + legacy compat)
-- ============================================================================

local function setIfChanged(player, key, value)
        if getElementData(player, key) ~= value then
                setElementData(player, key, value, true)
        end
end

-- ============================================================================
-- [Fix #160 / U1] badge rights -> the clients
-- ============================================================================
-- ONE synced string on the player, comma separated, holding the badge rights
-- the player's RANK currently holds:
--      "admin.badge,admin.badge.developer"  /  ""  = no badge right at all
-- Consumers (both read ONLY this key):
--      hud/c_nametags.lua       -> the three 36px badges next to the name chip
--      scoreboard/c_tab.lua     -> the badge column of the TAB board
-- Pushed from applyPlayerRank (login/ready, every rank edit, the 3s refresh
-- after a resource start) and cleared from clearPlayerRank (logout, rank
-- deleted, no rank assigned). Set with sync=true so every client sees it.
local FIX160_BADGE_RIGHTS = {
        "admin.badge",
        "admin.badge.developer",
        "admin.badge.support",
}

function pushFix160BadgeRights(player)
        if not isElement(player) or getElementType(player) ~= "player" then
                return false
        end
        local value = ""
        if type(playerHasRight) == "function" then
                -- playerHasRight reads the live rank:rights element data that
                -- applyPlayerRank has just written, so no DB round-trip here
                local held = {}
                for _, right in ipairs(FIX160_BADGE_RIGHTS) do
                        if playerHasRight(player, right) then
                                held[#held + 1] = right
                        end
                end
                value = table.concat(held, ",")
        end
        if getElementData(player, "fix160.badgerights") ~= value then
                setElementData(player, "fix160.badgerights", value, true)
        end
        return true
end

function applyPlayerRank(player, record)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        if not record then
                record = getPlayerRankRecord(player)
        end
        if not record then return false end

        -- snapshot the legacy numbers the FIRST time a rank is applied, so a
        -- later demotion can restore exactly what the accounts columns held
        if getElementData(player, "rank:legacy") == nil then
                setElementData(player, "rank:legacy", {
                        admin = tonumber(getElementData(player, "admin_level")) or 0,
                        supporter = tonumber(getElementData(player, "supporter_level")) or 0,
                        scripter = tonumber(getElementData(player, "scripter_level")) or 0,
                }, true)
        end

        setIfChanged(player, "rank:index", record.index)
        setIfChanged(player, "rank:name", record.name)
        -- [Fix #101] the live color is the STORED rank color, unchanged: no
        -- luminance floor, so rank:color matches staff_roles (and the panel /
        -- TAB / nametag all show the same shade)
        setIfChanged(player, "rank:color", clampRankColor(record.color))
        setIfChanged(player, "rank:rights", safeToJSON(record.rights))
        -- [Batch rule 2] the rank's hidden flag as synced element data (1/0):
        -- the F1 list, the TAB scoreboard and /checkid are OTHER resources and
        -- can only reach it through element data - they suppress the rank
        -- title for every viewer that does not hold staff:seehhidden.
        setIfChanged(player, "rank:hidden", record.hidden and 1 or 0)

		-- [Fix #163] RIGHTS govern the LEGACY identity numbers as well:
		-- admin_level / supporter_level are what the nametags, the scoreboard
		-- fallback, the duty strip, chat colours and every other legacy reader
		-- look at, so a RANK that does not hold admin.isAdmin must not be read
		-- as an admin there (and one without admin.isStaff not as support).
		-- playerHasRight is used instead of record.rights so a TEAM grant of
		-- the right keeps the identity too (same API the F1 list, the /staff
		-- overlay and the integration gates use). scripter_level stays as it
		-- is - no right exists for it.
		local looksAdmin, looksStaff
		if type(playerHasRight) == "function" then
			looksAdmin = playerHasRight(player, "admin.isAdmin") and true or false
			looksStaff = playerHasRight(player, "admin.isStaff") and true or false
		else
			looksAdmin = record.rights["admin.isAdmin"] == true
			looksStaff = record.rights["admin.isStaff"] == true
		end

		-- [Fix #U1] a DERIVED rank (legacy column -> ladder, no
		-- staff_role_members row) must NOT rewrite the legacy numbers: they are
		-- exactly what the accounts columns hold and what old resources still
		-- read (resource-keeper admin_level >= 5, interior-manager < 6,
		-- c_overlay <= 7, the /checkid rank text ... ). Only a real panel
		-- assignment runs RANK_COMPAT, byte-identical to the old behaviour.
		-- For the old 1..4 columns RANK_COMPAT maps back to the same number
		-- anyway, so this only changes the "new index written into the old
		-- column" case (admin=21 -> stays 21) - i.e. nothing regresses.
		if not record.derived then
			local compat = RANK_COMPAT[record.index]
			if compat then
				setIfChanged(player, "admin_level", looksAdmin and compat.admin or 0)
				setIfChanged(player, "supporter_level", looksStaff and compat.supporter or 0)
				setIfChanged(player, "scripter_level", compat.scripter)
			end
		else
			-- [Fix #163] a DERIVED rank keeps its accounts-column numbers, but
			-- the column is zeroed when the derived rank does not hold the
			-- matching right - otherwise a derived rank without admin.isAdmin
			-- would still LOOK like an admin to every legacy reader.
			if not looksAdmin then setIfChanged(player, "admin_level", 0) end
			if not looksStaff then setIfChanged(player, "supporter_level", 0) end
		end
        -- [Fix #160 / U1] every rank apply also re-pushes the badge rights
        -- (login / ready, rank edited in the panel, refreshRankMembers, the
        -- 3s refreshAllPlayerRanks after a resource start)
        pushFix160BadgeRights(player)
        -- [Batch rules 1+2] membership/entitlement flags travel with every
        -- rank (re)application - see staffPushStaffMeta below
        if type(staffPushStaffMeta) == "function" then
                staffPushStaffMeta(player)
        end
        return true
end

-- clear rank elementData (called on logout/demotion while online) and
-- restore the legacy column values that were snapshotted on apply
function clearPlayerRank(player)
        if not isElement(player) then return end
        -- [Fix #U1] the ACCOUNTS columns are the truth for the legacy numbers.
        -- Re-read them instead of blindly restoring the snapshot taken when the
        -- rank was applied: a demotion that also zeroed accounts.admin must NOT
        -- resurrect admin_level from the snapshot (that is exactly how a
        -- removal stayed a no-op for legacy staff accounts). The snapshot stays
        -- as the fallback when the account row is gone / unreadable.
        local accountID = tonumber(getElementData(player, "account:id"))
        local fresh = accountID and mysql:query_fetch_assoc(
                "SELECT admin, supporter, scripter FROM accounts WHERE id="
                .. accountID .. " LIMIT 1") or nil
        if fresh then
                setIfChanged(player, "admin_level", tonumber(fresh.admin) or 0)
                setIfChanged(player, "supporter_level", tonumber(fresh.supporter) or 0)
                setIfChanged(player, "scripter_level", tonumber(fresh.scripter) or 0)
        else
                local legacy = getElementData(player, "rank:legacy")
                if type(legacy) == "table" then
                        setIfChanged(player, "admin_level", legacy.admin or 0)
                        setIfChanged(player, "supporter_level", legacy.supporter or 0)
                        setIfChanged(player, "scripter_level", legacy.scripter or 0)
                end
        end
        for _, key in ipairs({ "rank:index", "rank:name", "rank:color", "rank:rights",
                "rank:legacy", "rank:hidden" }) do
                if getElementData(player, key) ~= nil then
                    setElementData(player, key, nil, true)
                end
        end
        -- [Fix #160 / U1] no rank in hand -> badge rights come from the TEAMS
        -- union only (staff_manager_teams_s.lua), which is usually none: that
        -- writes the exact "" this always wrote (not nil, so the clients know
        -- "pushed, no rights" and the old duty badge behaviour on a live,
        -- not-yet-reloaded server stays untouched). Covers logout, a deleted
        -- rank and a player with no rank. Teamless players see no change.
        local badge = ""
        if type(teamBadgeRightsValue) == "function" then
                badge = teamBadgeRightsValue(player) or ""
        end
        if getElementData(player, "fix160.badgerights") ~= badge then
                setElementData(player, "fix160.badgerights", badge, true)
        end
        -- [Batch rules 1+2] no rank, but the TEAMS (and the seehidden
        -- entitlement) may still apply - re-push the member flags
        if type(staffPushStaffMeta) == "function" then
                staffPushStaffMeta(player)
        end
end

-- exported entry point (login hook + panel mutations)
function refreshPlayerRank(player)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        if not tonumber(getElementData(player, "account:id")) then return false end
        local record = getPlayerRankRecord(player)
        local applied = false
        if record then
                applied = applyPlayerRank(player, record)
        else
                -- no Vortex rank assigned -> fall back to the legacy columns; drop any
                -- stale rank data so integration gates use the old path
                clearPlayerRank(player)
        end
        -- [Fix #U3] every rank (re)application re-checks the duty flag against
        -- the duty.adminduty right, so a revocation takes the player off duty
        -- the moment his rank is refreshed.
        enforceStaffDutyRights(player)
        -- [Fix #U6] the panel's mirrored flags are only re-sent when the panel
        -- opens; re-send them after every rank change too (server re-checks
        -- anyway - this only keeps an OPEN panel honest).
        if type(refreshStaffPanelRights) == "function" then
                pcall(refreshStaffPanelRights, player)
        end
        return applied
end

-- push a rank change to every online member of a role (rank edited/deleted)
function refreshRankMembers(roleID)
        if not tonumber(roleID) then return end
        for _, player in ipairs(getElementsByType("player")) do
                local accountID = tonumber(getElementData(player, "account:id"))
                if accountID then
                        local member = fetchMemberRow(accountID)
                        local match = false
                        if member then
                                match = tonumber(member.RoleID) == tonumber(roleID)
                        else
                                -- [Fix #U1] derived members (no staff_role_members
                                -- row, legacy column -> this very rank) must be
                                -- refreshed too, otherwise their rank:rights set
                                -- goes stale and the revocation never bites.
                                local rec = getPlayerRankRecord(player)
                                match = rec ~= nil and rec.derived
                                        and tonumber(rec.ID) == tonumber(roleID)
                        end
                        if match then
                                refreshPlayerRank(player)
                        end
                end
        end
        -- [Fix #31] role colors may have changed - re-push to the UIs
        pushRankColorsToAll()
end

-- refresh every online player (resource start / rank table rebuild)
function refreshAllPlayerRanks()
        for _, player in ipairs(getElementsByType("player")) do
                refreshPlayerRank(player)
        end
        -- [Fix #31] publish the staff-system rank colors to every client
        pushRankColorsToAll()
end

-- ============================================================================
-- [Fix #U3] duty enforcement — duty_admin is a RIGHT, not a stored flag
-- ============================================================================
-- The duty flag is written by three different paths (/adminduty, the MDC,
-- and the login restore of account_settings.duty_admin) and none of them
-- re-checks the right after a revocation - a demoted player stayed "on duty"
-- (duty badge, on-duty list, admin duty commands) forever. This is the one
-- place that turns it OFF again; it mirrors the /adminduty off-duty branch
-- (s_player_commands.lua adminDuty) so the client persists the change too.
function enforceStaffDutyRights(player)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        if tonumber(getElementData(player, "duty_admin")) ~= 1 then return false end
        if type(playerHasRight) ~= "function" then return false end
        if playerHasRight(player, "duty.adminduty") then return false end

        -- server value first (the F1 list / scoreboard read this), then the
        -- client event so account_settings.duty_admin is written as 0 as well
        setElementData(player, "duty_admin", 0, true)
        triggerClientEvent(player, "accounts:settings:updateAccountSettings", player, "duty_admin", 0)
        outputChatBox("You don't hold the duty.adminduty right anymore - you were taken off admin duty.",
                player, 255, 80, 80)
        local name = getPlayerName(player)
        pcall(function()
                -- [round-2 T2] RESTORED: this notification was commented out in
                -- the owner's uncommitted edit and the forced off-duty then told
                -- nobody - the admin team has to know a player was pulled off
                -- duty automatically. Ask me to re-silence it if admin-logs
                -- really does cover duty.
                exports.global:sendMessageToAdmins("AdmDuty: "
                        .. tostring(name) .. " went off duty.")
        end)
        outputDebugString("[Vortex Staff] duty_admin forced OFF for " .. tostring(name)
                .. " (rank no longer holds duty.adminduty)")
        return true
end

-- ============================================================================
-- permission API
-- ============================================================================

-- [Fix #34 - user] "لما اقفل أمر على رتبة ... ما أحد معه هي رتبة يقدر يستخدمه":
-- the stored Rights set is THE WHOLE TRUTH. The panel always sends the
-- COMPLETE checked set on save, so a right that is ABSENT from it was
-- deliberately unticked and must DENY - for every rank, management included.
-- The old "unknown right defaults to ALLOWED for index >= 11" fallback made
-- every untick on ranks 11..21 (Lead Administrator..Owner) a silent no-op.
-- The ONLY carve-out that survives: a right that does not exist in AllRights
-- at all (added to the code after this rank's last save) stays allowed for
-- management+ so a restart can never lock them out of a brand-new feature.
local knownRightsSet
local function isKnownRight(right)
        if type(AllRights) ~= "table" then return true end -- rights file missing: do not lock out
        if not knownRightsSet then
                knownRightsSet = {}
                for _, r in ipairs(AllRights) do knownRightsSet[tostring(r)] = true end
        end
        return knownRightsSet[right] == true
end

-- ============================================================================
-- [TEAMS] team-granted rights (permission bundles on top of ranks)
-- ============================================================================
-- A player's TEAM rights are the union of the rights of every row in
-- staff_teams he has a staff_team_members row for (member key = account id,
-- the same key staff_role_members uses). Cached per account and invalidated:
--   * by staffTeamsInvalidateRights() after EVERY team mutation
--     (staff_manager_teams_s.lua: create / rename / delete / set rights /
--      add member / remove member / hidden toggle),
--   * on account:id changes (login/logout - the account the cache is keyed
--     by is going away or just arrived),
--   * implicitly on resource start (the table starts empty).
--
-- [Batch rule 1] the cached value is now a BUNDLE, not a bare rights set:
--      rights        { [right] = true }   union of every held team
--      names         { "team name", ... } raw names (dev-team matching)
--      fullAccess    member of the Full Access team (exempt from everything)
--      hasTeam       member of ANY team (rank-less team members are
--                    invisible as staff - see staffPushStaffMeta)
--      hasNormalTeam member of a NON-Full-Access team (such a player may
--                    only use THAT team's commands)
--
-- [Batch rule 1] name normalization lives here because this file loads
-- before the team seed and the payload filter (staff_manager_teams_s.lua)
-- and after the gate (command_gates_s.lua) - all three call these GLOBALS.
-- The owner's DB may carry the Full Access team under a legacy spelling, so
-- matching strips ALL whitespace + lowercases and accepts both "fullaccess"
-- and the legacy typo "fullacsess".
function staffNormalizedTeamName(name)
        return tostring(name or ""):gsub("%s+", ""):lower()
end

function staffTeamIsFullAccess(name)
        local n = staffNormalizedTeamName(name)
        return n == "fullaccess" or n == "fullacsess"
end

local teamBundleByAccount = {}    -- [accountID] = bundle (see above)
local teamScopedRightsCache       -- { [right] = true } or nil (not built yet)
-- [2f] normalized names of the teams flagged staff_teams.hidden = 1 - the
-- membership side of "hidden-team holder may see hidden". Cached together
-- with the team bundle and dropped by staffTeamsInvalidateRights, so a
-- teamCreate/teamSetHidden/teamRename is reflected on the next read.
local hiddenTeamNameSet           -- { [normalized name] = true } or nil

local function loadTeamBundle(accountID)
        local bundle = { rights = {}, names = {}, fullAccess = false,
                hasTeam = false, hasNormalTeam = false }
        local q = mysql:query("SELECT t.name, t.rights FROM staff_teams t"
                .. " JOIN staff_team_members m ON m.teamid = t.id"
                .. " WHERE m.account_id = " .. tonumber(accountID))
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        bundle.hasTeam = true
                        local name = tostring(row.name or "")
                        bundle.names[#bundle.names + 1] = name
                        if staffTeamIsFullAccess(name) then
                                bundle.fullAccess = true
                        else
                                bundle.hasNormalTeam = true
                        end
                        -- Full Access rights join the union too: a member of
                        -- Full Access holds every right through playerHasRight
                        -- (that is what "full access" means for rights checks)
                        for token in tostring(row.rights or ""):gmatch("[^,]+") do
                                local right = token:match("^%s*(.-)%s*$")
                                if right ~= "" then bundle.rights[right] = true end
                        end
                end
                mysql:free_result(q)
        end
        return bundle
end

local function playerTeamBundle(player)
        if not isElement(player) or getElementType(player) ~= "player" then return nil end
        local accountID = tonumber(getElementData(player, "account:id"))
        if not accountID then return nil end
        local bundle = teamBundleByAccount[accountID]
        if bundle == nil then
                bundle = loadTeamBundle(accountID)
                teamBundleByAccount[accountID] = bundle
        end
        return bundle
end

local function playerTeamRightsSet(player)
        local bundle = playerTeamBundle(player)
        return bundle and bundle.rights or nil
end

local function playerTeamGrantsRight(player, right)
        local set = playerTeamRightsSet(player)
        return set ~= nil and set[right] == true
end

-- [Batch rule 1] the rights SOME non-Full-Access team grants. A right in
-- this set is "team scoped": ranks other than the top four may only use a
-- command gated by it while holding a team that grants it (hasCommandRight).
-- Full Access is excluded on purpose - it grants EVERY right, and counting
-- it would make every single command team scoped and lock out every
-- rank-without-team (including the top four bypass's spirit).
local function teamScopedRightsSet()
        if teamScopedRightsCache ~= nil then return teamScopedRightsCache end
        local set = {}
        local q = mysql:query("SELECT name, rights FROM staff_teams")
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        if not staffTeamIsFullAccess(row.name) then
                                for token in tostring(row.rights or ""):gmatch("[^,]+") do
                                        local right = token:match("^%s*(.-)%s*$")
                                        if right ~= "" then set[right] = true end
                                end
                        end
                end
                mysql:free_result(q)
        end
        teamScopedRightsCache = set
        return set
end

-- does THIS command's right carry a team requirement? a gate may list
-- SEVERAL rights (shared commands): ANY of them being team scoped triggers
-- the requirement (the same ANY-of rule gateAllows uses for permissions)
function commandNeedsTeam(right)
        local scoped = teamScopedRightsSet()
        if type(right) == "table" then
                for _, r in ipairs(right) do
                        if scoped[tostring(r)] then return true end
                end
                return false
        end
        return scoped[tostring(right)] == true
end

-- [Batch rule 1] RANK-ONLY permission check: the rank's OWN stored rights
-- decide (live rank:rights element data, else a fresh staff_roles read) -
-- NO team union, NO legacy flat grant. This is the "rank restrictions
-- always win" half of the model; the team half lives in hasCommandRight.
function staffRankPermits(player, right)
        if type(right) == "table" then
                for _, r in ipairs(right) do
                        if staffRankPermits(player, r) then return true end
                end
                return false
        end
        local idx = tonumber(getElementData(player, "rank:index"))
        -- no rank at all: there is no rank restriction to apply - the caller
        -- (hasCommandRight) runs its own rank-less branch for that case
        if not idx then return true end
        local raw = getElementData(player, "rank:rights")
        if type(raw) == "string" and raw ~= "" then
                local parsed = fromJSON(raw)
                if type(parsed) == "table" then
                        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                                parsed = parsed[1]
                        end
                        if type(parsed) == "table" then
                                if parsed[right] == true then return true end
                                -- a live set is the COMPLETE saved set: an
                                -- absent right denies (Fix #34 rule), the
                                -- unknown-right carve-out only exists on the
                                -- DB path below - mirrored exactly
                                return false
                        end
                end
        end
        local record = getPlayerRankRecord(player)
        if not record then return true end -- nothing to restrict against
        if record.rights[right] == true then return true end
        if record.rights[right] == nil and not isKnownRight(right)
                and (tonumber(record.index) or 0) >= 11 then
                return true
        end
        return false
end

-- [Batch rule 1] membership queries used by hasCommandRight
function playerTeamInFullAccess(player)
        local bundle = playerTeamBundle(player)
        return bundle ~= nil and bundle.fullAccess == true
end

function playerTeamHoldsNormalTeam(player)
        local bundle = playerTeamBundle(player)
        return bundle ~= nil and bundle.hasNormalTeam == true
end

function playerTeamsGrantRight(player, right)
        local bundle = playerTeamBundle(player)
        if not bundle then return false end
        if type(right) == "table" then
                for _, r in ipairs(right) do
                        if bundle.rights[tostring(r)] then return true end
                end
                return false
        end
        return bundle.rights[tostring(right)] == true
end

-- global hook: staff_manager_teams_s.lua calls this after every team
-- mutation (no argument = drop every cached account + the scoped set; a
-- number = only that account, when the change is known to be scoped to one
-- member)
function staffTeamsInvalidateRights(accountID)
        if accountID == nil then
                teamBundleByAccount = {}
                teamScopedRightsCache = nil
                hiddenTeamNameSet = nil
        else
                teamBundleByAccount[tonumber(accountID)] = nil
        end
end

-- team-only badge rights string (Fix #160 badges WITHOUT the rank path).
-- [Batch rule 1] a player with NO Vortex rank is invisible as staff (no
-- badge, no title anywhere), so this now returns "" for him even when his
-- team grants a badge right - teams only decorate RANKED staff. Ranked
-- players keep the full union through pushFix160BadgeRights.
function teamBadgeRightsValue(player)
        if not tonumber(getElementData(player, "rank:index")) then return "" end
        local held = {}
        for _, right in ipairs(FIX160_BADGE_RIGHTS) do
                if playerTeamGrantsRight(player, right) then
                        held[#held + 1] = right
                end
        end
        return table.concat(held, ",")
end

-- [2f] the set of hidden team names, read once and cached until a team
-- mutation invalidates it. pcall-guarded: staff_manager_teams_s.lua only
-- adds the staff_teams.hidden column at ITS onResourceStart (which runs
-- after this resource's own), so a read that races that must degrade to
-- "no hidden team entitlement" instead of erroring the whole query chain.
local function hiddenTeamNames()
        if hiddenTeamNameSet == nil then
                hiddenTeamNameSet = {}
                local ok, rows = pcall(function()
                        return mysql:query("SELECT name, hidden FROM staff_teams")
                end)
                if ok and rows then
                        while true do
                                local row = mysql:fetch_assoc(rows)
                                if not row then break end
                                if tonumber(row.hidden) == 1 then
                                        hiddenTeamNameSet[staffNormalizedTeamName(row.name)] = true
                                end
                        end
                        mysql:free_result(rows)
                end
        end
        return hiddenTeamNameSet
end

-- [Batch rule 2 / 2f] WHO may see hidden ranks/teams: rank 21 (Owner),
-- rank 20 (Dev), a member of a team whose normalized name CONTAINS "dev"
-- (the owner's own rule - kept), the holder of a hidden rank (staff_roles
-- hidden = 1, synced as rank:hidden) and the holder of a hidden team
-- (staff_teams hidden = 1). Uniform everywhere (panel payload filter, F1
-- list, TAB, /checkid). Everyone else is refused - see memberRankMasked,
-- fetchTeamsPayload and hiddenRankContext for the refusal side.
function staffCanSeeHiddenStaff(player)
        if not isElement(player) or getElementType(player) ~= "player" then
                return false
        end
        local idx = tonumber(getElementData(player, "rank:index"))
        if idx == 20 or idx == 21 then return true end
        -- [2f] holders of a hidden rank see the hidden set
        if tonumber(getElementData(player, "rank:hidden")) == 1 then return true end
        local bundle = playerTeamBundle(player)
        if bundle then
                local hidden = hiddenTeamNames()
                for _, name in ipairs(bundle.names) do
                        local n = staffNormalizedTeamName(name)
                        -- [2f] holders of a hidden team see the hidden set
                        if hidden[n] then return true end
                        -- the owner's dev-team rule (kept as-is)
                        if n:find("dev", 1, true) then return true end
                end
        end
        return false
end

-- [Batch rules 1+2] two synced flags OTHER resources read off element data
-- (main-menu F1 list, scoreboard TAB):
--      staff:hasTeam    1/0 - the player belongs to some team; a rank-less
--                        team member must be invisible as staff everywhere
--                        (F1 skips his row entirely),
--      staff:seehhidden  1/0 - THIS player may see hidden ranks/teams (the
--                        viewer's entitlement, recomputed for everyone on
--                        every rank/team change).
function staffPushStaffMeta(player)
        if not isElement(player) or getElementType(player) ~= "player" then
                return false
        end
        local bundle = playerTeamBundle(player)
        local hasTeam = (bundle ~= nil and bundle.hasTeam == true)
        setIfChanged(player, "staff:hasTeam", hasTeam and 1 or 0)
        setIfChanged(player, "staff:seehhidden", staffCanSeeHiddenStaff(player) and 1 or 0)
        return true
end

-- exact right check against the rank's stored Rights JSON
function playerHasRight(player, right)
        if not right then return false end
        -- [Fix #18] live rights are pushed as element data by applyPlayerRank
        -- (rank:rights is the raw JSON string). Unwrap the MTA array wrapper
        -- so rights["admin.goto"] resolves instead of always nil.
        -- [Fix #34] when a live set EXISTS at all it is the complete saved
        -- set -> an absent right denies WITHOUT a DB round-trip (the old code
        -- fell through to a fresh MySQL read on every absent key, which made
        -- every chat command from ranked staff hit the DB twice).
        local raw = getElementData(player, "rank:rights")
        if type(raw) == "string" and raw ~= "" then
                local parsed = fromJSON(raw)
                if type(parsed) == "table" then
                        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                                parsed = parsed[1]
                        end
                        if type(parsed) == "table" then
                                if parsed[right] == true then return true end
                                -- [TEAMS] the RANK missed it -> try the teams
                                -- (a player has a right if his rank OR any of
                                -- his teams grants it - union / OR)
                                return playerTeamGrantsRight(player, right)
                        end
                end
        end
        -- no live set (never pushed / unparseable): one fresh DB read decides
        local record = getPlayerRankRecord(player)
        if not record then
                -- legacy fallback: only the old top ladder gets the flat grant
                local level = tonumber(getElementData(player, "admin_level")) or 0
                if level >= 4 then return true end
                return playerTeamGrantsRight(player, right)
        end
        if record.rights[right] == true then return true end
        if record.rights[right] == nil and not isKnownRight(right)
                and (tonumber(record.index) or 0) >= 11 then
                return true
        end
        -- [TEAMS] the stored rank set missed it -> the teams decide (union)
        return playerTeamGrantsRight(player, right)
end

-- at-rank-or-above check (the gate the integration file uses)
function playerRankAtLeast(player, index)
        local idx = tonumber(getElementData(player, "rank:index"))
        if not idx then return nil end -- no rank assigned -> caller falls back
        return idx >= index
end

-- legacy column -> closest new rank: the table itself lives with the ladder
-- constants at the top of this file (shared with migrateLegacyStaff).

-- [Fix #14] ladder position of a rank TITLE (nil when unknown/custom)
function getRankTitleIndex(name)
        if not name then return nil end
        for idx, rname in pairs(RANK_LADDER) do
                if rname == tostring(name) then
                        return idx
                end
        end
        return nil
end

-- [Fix #101] rank:color is pushed EXACTLY as stored in staff_roles - dark
-- stays dark, so the nametag, the scoreboard TAB and the staff panel's live
-- rows all show the shade the owner picked. The old [Fix #14] "readability
-- floor" blended every dark color toward white (luminance >= 0.45), which is
-- what made a dark red paint as a light red. All that is left here is the
-- MTA nested-array unwrap ("[ [ r, g, b, a ] ]" -> { r, g, b, a }) plus a
-- 0..255 clamp of the stored channels.
function clampRankColor(c)
        if type(c) ~= "table" then return c end
        if type(c[1]) == "table" then c = c[1] end
        local r = math.min(255, math.max(0, tonumber(c[1]) or 255))
        local g = math.min(255, math.max(0, tonumber(c[2]) or 255))
        local b = math.min(255, math.max(0, tonumber(c[3]) or 255))
        local a = math.min(255, math.max(0, tonumber(c[4]) or 255))
        return { r, g, b, a }
end

local function rankIDByName(name)
        local row = mysql:query_fetch_assoc("SELECT ID FROM staff_roles WHERE LevelName='"
                .. mysql:escape_string(name) .. "' LIMIT 1")
        return row and tonumber(row.ID) or nil
end

-- [Vortex fix] runs on EVERY resource start but is PER-ACCOUNT idempotent:
-- only accounts with NO staff_role_members row are considered, so deleting
-- someone's rank in the panel never gets re-created here. This also catches
-- accounts whose old column was edited AFTER the first migration (e.g. the
-- owner setting admin=21 to grab the Owner rank).
function migrateLegacyStaff()
        local rows = mysql:query(
                "SELECT id, username, admin, supporter, scripter FROM accounts " ..
                "WHERE IFNULL(admin,0) > 0 OR IFNULL(supporter,0) > 0 OR IFNULL(scripter,0) > 0")
        if not rows then return 0 end
        local migrated = 0
        while true do
                local acc = mysql:fetch_assoc(rows)
                if not acc then break end
                local accountID = tonumber(acc.id)
                if accountID and not mysql:query_fetch_assoc(
                                "SELECT AccountID FROM staff_role_members WHERE AccountID="
                                .. accountID .. " LIMIT 1") then
                        local assigned = nil
                        -- direct NEW-ladder index stored in the old column (5..21,
                        -- excluding 10 which the old ladder used for Scripter)
                        local adminVal = tonumber(acc.admin) or 0
                        if adminVal >= 5 and adminVal <= 21 and adminVal ~= 10 then
                                assigned = RANK_LADDER[adminVal]
                        end
                        if not assigned then
                                for _, rule in ipairs(LEGACY_MIGRATION) do
                                        if not assigned and tonumber(acc[rule.column] or 0) >= rule.min then
                                                assigned = rule.rank
                                        end
                                end
                        end
                        if assigned then
                                local roleID = rankIDByName(assigned)
                                if roleID then
                                        mysql:query_free("INSERT INTO staff_role_members (RoleID, AccountID) VALUES ("
                                                .. roleID .. ", " .. accountID .. ")")
                                        migrated = migrated + 1
                                end
                        end
                end
        end
        mysql:free_result(rows)
        if migrated > 0 then
                outputDebugString("[Vortex Staff] migrated " .. migrated
                        .. " legacy staff accounts onto the 21-rank ladder")
        end
        return migrated
end

-- ============================================================================
-- lifecycle
-- ============================================================================

addEventHandler("onResourceStart", resourceRoot, function()
        -- per-account migration (idempotent — see migrateLegacyStaff)
        migrateLegacyStaff()
        -- push the ladder onto everyone already online (resource restarts)
        setTimer(function()
                refreshAllPlayerRanks()
        end, 3000, 1)
end)


-- logout wipes rank data (login re-applies it)
addEventHandler("onPlayerLogout", root, function()
        clearPlayerRank(source)
end)

-- [Mod 2 fix] apply the rank the INSTANT the account is known. The login
-- panel calls refreshPlayerRank itself, but every other login path (seamless
-- revalidation, /loginto, future systems) only sets account:id - without this
-- hook those players kept stale/missing rank element data (the "new rank
-- system is still not active" symptom). Keyed by ACCOUNT id only: character
-- ids never enter the rank lookup.
local pendingRankTimers = {}
addEventHandler("onElementDataChange", root, function(key, oldValue)
        -- [TEAMS] the team-rights cache is keyed by ACCOUNT id: drop the
        -- account that is being left (logout) before anything else, so a
        -- later login of the same account can never read a stale bundle
        if key == "account:id" then
                local oldAccount = tonumber(oldValue)
                if oldAccount and type(staffTeamsInvalidateRights) == "function" then
                        staffTeamsInvalidateRights(oldAccount)
                end
        end
        -- [Fix #U3] duty_admin flipping ON (login restore of account_settings,
        -- /adminduty, the MDC, any setter) re-checks the duty.adminduty right
        -- immediately: whoever lost it can never stay on duty. The force-off
        -- inside writes 0, which lands here again and returns right away, so
        -- there is no loop.
        if key == "duty_admin" then
                if isElement(source) and getElementType(source) == "player"
                        and tonumber(getElementData(source, "duty_admin")) == 1 then
                        enforceStaffDutyRights(source)
                end
                return
        end
        if key ~= "account:id" then return end
        if not isElement(source) or getElementType(source) ~= "player" then return end
        local acc = tonumber(getElementData(source, "account:id"))
        if isTimer(pendingRankTimers[source]) then killTimer(pendingRankTimers[source]) end
        if acc then
                pendingRankTimers[source] = setTimer(function(p)
                        if isElement(p) then
                                refreshPlayerRank(p)
                                pendingRankTimers[p] = nil
                        end
                end, 500, 1, source)
        else
                clearPlayerRank(source)
        end
end)

-- ============================================================================
-- exports
-- ============================================================================

function export_refreshPlayerRank(player) return refreshPlayerRank(player) end
function export_getPlayerRankName(player)
        local r = getPlayerRankRecord(player)
        return r and r.name or false
end
function export_getPlayerRankIndex(player)
        local r = getPlayerRankRecord(player)
        return r and r.index or 0
end
function export_getPlayerRankColor(player)
        local r = getPlayerRankRecord(player)
        return r and r.color or false
end
function export_hasRight(player, right) return playerHasRight(player, right) end