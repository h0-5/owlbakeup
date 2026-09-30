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
        return mysql:query_fetch_assoc("SELECT ID, LevelName, Rights, Color FROM staff_roles WHERE ID="
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

function getAllRankColors()
        local out = {}
        local q = mysql:query("SELECT LevelName, Color FROM staff_roles")
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        out[tostring(row.LevelName)] = decodeColor(row.Color)
                end
                mysql:free_result(q)
        end
        return out
end

-- push the table to every client (called on staff_manager start and after
-- every rank save, so the tab always mirrors the live staff_roles colors)
function pushRankColorsToAll()
        triggerClientEvent("scoreboard:rankColors", root, getAllRankColors())
end

-- resolve the rank record (index included) for an account id; nil = no rank
function getPlayerRankRecordByAccountID(accountID)
        local member = fetchMemberRow(accountID)
        if not member then return nil end
        local role = fetchRankByID(member.RoleID)
        if not role then return nil end

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
        }
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

        local compat = RANK_COMPAT[record.index]
        if compat then
                setIfChanged(player, "admin_level", compat.admin)
                setIfChanged(player, "supporter_level", compat.supporter)
                setIfChanged(player, "scripter_level", compat.scripter)
        end
        return true
end

-- clear rank elementData (called on logout/demotion while online) and
-- restore the legacy column values that were snapshotted on apply
function clearPlayerRank(player)
        if not isElement(player) then return end
        local legacy = getElementData(player, "rank:legacy")
        if type(legacy) == "table" then
                setIfChanged(player, "admin_level", legacy.admin or 0)
                setIfChanged(player, "supporter_level", legacy.supporter or 0)
                setIfChanged(player, "scripter_level", legacy.scripter or 0)
        end
        for _, key in ipairs({ "rank:index", "rank:name", "rank:color", "rank:rights", "rank:legacy" }) do
                if getElementData(player, key) ~= nil then
                    setElementData(player, key, nil, true)
                end
        end
end

-- exported entry point (login hook + panel mutations)
function refreshPlayerRank(player)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        if not tonumber(getElementData(player, "account:id")) then return false end
        local record = getPlayerRankRecord(player)
        if record then
                return applyPlayerRank(player, record)
        end
        -- no Vortex rank assigned -> fall back to the legacy columns; drop any
        -- stale rank data so integration gates use the old path
        clearPlayerRank(player)
        return false
end

-- push a rank change to every online member of a role (rank edited/deleted)
function refreshRankMembers(roleID)
        if not tonumber(roleID) then return end
        for _, player in ipairs(getElementsByType("player")) do
                local accountID = tonumber(getElementData(player, "account:id"))
                if accountID then
                        local member = fetchMemberRow(accountID)
                        if member and tonumber(member.RoleID) == tonumber(roleID) then
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
                                return parsed[right] == true
                        end
                end
        end
        -- no live set (never pushed / unparseable): one fresh DB read decides
        local record = getPlayerRankRecord(player)
        if not record then
                -- legacy fallback: only the old top ladder gets the flat grant
                local level = tonumber(getElementData(player, "admin_level")) or 0
                return level >= 4
        end
        if record.rights[right] == true then return true end
        if record.rights[right] == nil and not isKnownRight(right)
                and (tonumber(record.index) or 0) >= 11 then
                return true
        end
        return false
end

-- at-rank-or-above check (the gate the integration file uses)
function playerRankAtLeast(player, index)
        local idx = tonumber(getElementData(player, "rank:index"))
        if not idx then return nil end -- no rank assigned -> caller falls back
        return idx >= index
end

-- legacy column -> closest new rank (highest wins).
-- [Vortex fix] the OLD ladder only ever held admin 1..4 (plus 10 = scripter);
-- anything from 5 to 21 was someone writing the NEW 21-rank index straight
-- into the old column (admin=21 = Owner). migrateLegacyStaff honors those
-- values 1:1 through RANK_LADDER before these thresholds apply.
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
addEventHandler("onElementDataChange", root, function(key)
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
