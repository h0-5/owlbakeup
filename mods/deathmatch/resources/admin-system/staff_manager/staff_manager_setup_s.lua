--[[ ------------------------------------------------------------------------
        Vortex Staff — TEMPORARY database bootstrap & diagnostics (user request)

        Loads BEFORE staff_manager_s.lua (see meta.xml) and makes the staff
        system's database state visible + self-healing:

          1. creates the three staff tables if they are missing
             (staff_roles / staff_role_members / staff_rank_changelogs)
          2. makes sure accounts.adminreports exists (the panel reads it)
          3. makes sure the feedbacks table exists (temporary, the panel
             joins it for the Feedback columns)
          4. repairs rank rows whose Color JSON is broken (drawn black =
             "invisible rows" in the staffs grid)
          5. /staffdb (server command) prints the LIVE state of every table
             straight into the calling admin's chat — so a database problem
             can never masquerade as "the panel is just decorative" again

        This file is intentionally safe to delete later: staff_manager_s.lua
        re-creates its own tables and seeds the rank ladder on start.
-------------------------------------------------------------------------- ]]

local mysql = exports.mysql

local function dbg(msg)
        outputDebugString("[Vortex Staff DB] " .. tostring(msg), 3, 120, 200, 255)
end

local function esc(s)
        local ok, r = pcall(function() return mysql:escape_string(tostring(s)) end)
        if ok and r then return r end
        return tostring(s):gsub("'", "\\'")
end

-- free-form DDL/query with a readable failure report
local function ddl(sql, what)
        local ok, err = pcall(function() mysql:query_free(sql) end)
        if not ok then
                dbg("FAILED: " .. tostring(what) .. " (" .. tostring(err) .. ")")
                return false
        end
        return true
end

local function fetchOne(sql)
        local ok, res = pcall(function() return mysql:query_fetch_assoc(sql) end)
        if ok then return res end
        return nil, res
end

local SETUP_REPORT = {}

local function runSetup()
        SETUP_REPORT = { lines = {}, problems = 0 }

        -- 0) is the mysql resource even there and callable?
        if not getResourceFromName("mysql") then
                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                dbg("PROBLEM: the 'mysql' resource is NOT running — every staff query will silently fail!")
                table.insert(SETUP_REPORT.lines, "mysql resource: MISSING")
                return false
        end
        local okProbe, probe = fetchOne("SELECT 1 AS ok")
        if not okProbe then
                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                dbg("PROBLEM: exports.mysql answered with an error — check the mysql module/connection")
                table.insert(SETUP_REPORT.lines, "mysql connection: BROKEN")
                return false
        end
        table.insert(SETUP_REPORT.lines, "mysql connection: OK")

        -- 1) the three staff tables
        local created = 0
        if ddl([[CREATE TABLE IF NOT EXISTS staff_roles (
                ID INT NOT NULL AUTO_INCREMENT,
                LevelName VARCHAR(64) NOT NULL,
                Rights TEXT,
                Color TEXT,
                hidden TINYINT NOT NULL DEFAULT 0,
                PRIMARY KEY (ID))]], "CREATE staff_roles") then
                -- [Batch rule 2] hidden flag: CREATE ... IF NOT EXISTS does NOT
                -- add columns to an EXISTING table, so patch old schemas the
                -- same idempotent way accounts.adminreports is patched below.
                local hid = fetchOne([[
                        SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_SCHEMA = DATABASE()
                                AND TABLE_NAME = 'staff_roles' AND COLUMN_NAME = 'hidden']])
                if hid and tonumber(hid.n) == 0 then
                        if ddl("ALTER TABLE staff_roles ADD COLUMN hidden TINYINT NOT NULL DEFAULT 0",
                                "ALTER staff_roles ADD hidden") then
                                dbg("added missing staff_roles.hidden column")
                                table.insert(SETUP_REPORT.lines, "staff_roles.hidden: ADDED (was missing)")
                        else
                                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                                table.insert(SETUP_REPORT.lines, "staff_roles.hidden: ALTER FAILED")
                        end
                end
                local row = fetchOne("SELECT COUNT(*) AS n FROM staff_roles")
                local n = row and tonumber(row.n) or -1
                if n == 0 then
                        table.insert(SETUP_REPORT.lines, "staff_roles: empty (rank ladder will be seeded)")
                elseif n < 0 then
                        SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                        table.insert(SETUP_REPORT.lines, "staff_roles: UNREADABLE")
                else
                        table.insert(SETUP_REPORT.lines, "staff_roles: " .. n .. " rank(s)")
                end
        else
                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                table.insert(SETUP_REPORT.lines, "staff_roles: CREATE FAILED")
        end

        if ddl([[CREATE TABLE IF NOT EXISTS staff_role_members (
                RoleID INT NOT NULL,
                AccountID INT NOT NULL,
                UNIQUE KEY ra (RoleID, AccountID))]], "CREATE staff_role_members") then
                local row = fetchOne("SELECT COUNT(*) AS n FROM staff_role_members")
                local n = row and tonumber(row.n) or -1
                if n >= 0 then
                        table.insert(SETUP_REPORT.lines, "staff_role_members: " .. n .. " member(s)")
                else
                        SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                        table.insert(SETUP_REPORT.lines, "staff_role_members: UNREADABLE")
                end
        else
                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                table.insert(SETUP_REPORT.lines, "staff_role_members: CREATE FAILED")
        end

        if ddl([[CREATE TABLE IF NOT EXISTS staff_rank_changelogs (
                ID INT NOT NULL AUTO_INCREMENT,
                Date DATETIME,
                cType VARCHAR(32),
                Username VARCHAR(64),
                FromR VARCHAR(64),
                ToR VARCHAR(64),
                By_ VARCHAR(64),
                PRIMARY KEY (ID))]], "CREATE staff_rank_changelogs") then
                local row = fetchOne("SELECT COUNT(*) AS n FROM staff_rank_changelogs")
                local n = row and tonumber(row.n) or -1
                if n >= 0 then
                        table.insert(SETUP_REPORT.lines, "staff_rank_changelogs: " .. n .. " log(s)")
                else
                        SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                        table.insert(SETUP_REPORT.lines, "staff_rank_changelogs: UNREADABLE")
                end
        else
                SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                table.insert(SETUP_REPORT.lines, "staff_rank_changelogs: CREATE FAILED")
        end

        -- 2) accounts.adminreports column (panel: Reports #)
        local col = fetchOne([[
                SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                        AND TABLE_NAME = 'accounts' AND COLUMN_NAME = 'adminreports']])
        if col and tonumber(col.n) == 0 then
                if ddl("ALTER TABLE accounts ADD COLUMN adminreports INT NOT NULL DEFAULT 0",
                        "ALTER accounts ADD adminreports") then
                        dbg("added missing accounts.adminreports column")
                        table.insert(SETUP_REPORT.lines, "accounts.adminreports: ADDED (was missing)")
                else
                        SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                        table.insert(SETUP_REPORT.lines, "accounts.adminreports: ALTER FAILED")
                end
        elseif col then
                table.insert(SETUP_REPORT.lines, "accounts.adminreports: OK")
        else
                table.insert(SETUP_REPORT.lines, "accounts table: NOT FOUND (check your accounts resource)")
        end

        -- 3) feedbacks table (temporary — panel joins it for Feedback Rating/#)
        local fb = fetchOne([[
                SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feedbacks']])
        if fb and tonumber(fb.n) == 0 then
                if ddl([[CREATE TABLE IF NOT EXISTS feedbacks (
                        id INT NOT NULL AUTO_INCREMENT,
                        staff_id INT NOT NULL,
                        rating INT NOT NULL DEFAULT 0,
                        date DATETIME,
                        PRIMARY KEY (id))]], "CREATE feedbacks (temporary)") then
                        dbg("created missing feedbacks table (temporary)")
                        table.insert(SETUP_REPORT.lines, "feedbacks: CREATED (temporary)")
                else
                        SETUP_REPORT.problems = SETUP_REPORT.problems + 1
                        table.insert(SETUP_REPORT.lines, "feedbacks: CREATE FAILED")
                end
        elseif fb then
                table.insert(SETUP_REPORT.lines, "feedbacks: OK")
        else
                table.insert(SETUP_REPORT.lines, "feedbacks: CHECK SKIPPED")
        end

        -- 4) repair broken rank colors (invalid/zero JSON drew invisible rows)
        -- [Fix #86] the old check blanked EVERY row failing `LIKE '[[%'` to
        -- white. MTA's toJSON (non-compact) writes "[ [ 255, 255, 255, 255 ] ]"
        -- WITH spaces, so every SAVED color failed the LIKE test and was wiped
        -- to white on EVERY resource start -- saved colors never persisted.
        -- Parse each row instead: only truly invalid values (NULL / '' / '{}'
        -- / unparseable / missing channels) become white; valid spaced JSON
        -- (from toJSON) is kept.
        pcall(function()
                local q = mysql:query("SELECT ID, Color FROM staff_roles")
                if q then
                        local fixed = 0
                        while true do
                                local row = mysql:fetch_assoc(q)
                                if not row then break end
                                local raw = row.Color
                                local c = nil
                                if type(raw) == "string" and raw ~= "" then
                                        c = fromJSON(raw)
                                end
                                -- [Fix #153] fromJSON unpacks a JSON array into
                                -- its elements, so toJSON's "[ [ r, g, b, a ] ]"
                                -- normally comes back FLAT as { r, g, b, a }.
                                -- Some builds hand back the nested shape
                                -- { { r, g, b, a } } instead - unwrap one level
                                -- so a VALID color is never mistaken for a
                                -- broken one and wiped to white here.
                                if type(c) == "table" and type(c[1]) == "table" then
                                        c = c[1]
                                end
                                local ok = type(c) == "table"
                                        and tonumber(c[1]) and tonumber(c[2]) and tonumber(c[3])
                                if not ok then
                                        ddl("UPDATE staff_roles SET Color='[[255,255,255,255]]' WHERE ID=" .. tonumber(row.ID),
                                                "UPDATE staff color #" .. tostring(row.ID))
                                        fixed = fixed + 1
                                end
                        end
                        mysql:free_result(q)
                        if fixed > 0 then
                                dbg("repaired " .. fixed .. " invalid rank color(s) -> white")
                                table.insert(SETUP_REPORT.lines, "rank colors repaired: " .. fixed)
                        end
                end
        end)

        -- 4b) [Fix #101] the [Fix #14] "readability floor" that used to sit here
        -- REWROTE every dark rank color to a lighter shade on every start (log:
        -- "[Vortex Staff DB] brightened N dark rank color(s)"), so a color the
        -- owner picked dark never stayed dark - the next restart lightened it
        -- again and the stored value no longer matched what was saved. Stored
        -- colors are now left EXACTLY as saved (pass 4 above still repairs
        -- truly invalid values to white); the panel/TAB/nametags draw them
        -- as-is.

        -- 5) orphaned members (AccountID without an account row) clean-up
        ddl("DELETE m FROM staff_role_members m LEFT JOIN accounts a ON a.id = m.AccountID WHERE a.id IS NULL",
                "DELETE orphaned staff_role_members")

        -- 5b) [Fix #18] repair the legacy "[ { ... } ]" rights rows. MTA's
        -- toJSON wraps associative tables in an array, so every stored Rights
        -- looked like '[ { "a": true } ]' and fromJSON returned
        -- { [1] = {a=true} } -> rights[right] was always nil -> every gate
        -- silently failed ("permissions broken"). Rewrite each row as a plain
        -- JSON object. Idempotent: already-correct rows parse to the same set.
        pcall(function()
                local q = mysql:query("SELECT ID, Rights FROM staff_roles")
                if not q then return end
                local fixed, scanned = 0, 0
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then break end
                        scanned = scanned + 1
                        local raw = tostring(row.Rights or "")
                        if raw ~= "" then
                                local parsed = fromJSON(raw)
                                if type(parsed) == "table" then
                                        -- unwrap the MTA array wrapper
                                        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                                                parsed = parsed[1]
                                        end
                                        local keys = {}
                                        for k, v in pairs(parsed) do
                                                if v then keys[#keys + 1] = tostring(k) end
                                        end
                                        if #keys > 0 or raw:find("{") then
                                                table.sort(keys)
                                                local parts = {}
                                                for _, k in ipairs(keys) do
                                                        parts[#parts + 1] = '"' .. mysql:escape_string(k):gsub('\\', '\\\\'):gsub('"', '\\"') .. '":true'
                                                end
                                                local out = "{" .. table.concat(parts, ",") .. "}"
                                                -- only touch rows that actually differ
                                                if out ~= raw then
                                                        mysql:query_free("UPDATE staff_roles SET Rights='"
                                                                .. out .. "' WHERE ID=" .. tonumber(row.ID))
                                                        fixed = fixed + 1
                                                end
                                        end
                                end
                        end
                end
                mysql:free_result(q)
                if fixed > 0 then
                        dbg("repaired " .. fixed .. "/" .. scanned .. " rank rights rows (MTA toJSON wrapper)")
                        table.insert(SETUP_REPORT.lines, "rank rights repaired: " .. fixed .. "/" .. scanned)
                end
        end)

        return true
end

addEventHandler("onResourceStart", resourceRoot, function()
        if runSetup() then
                dbg("bootstrap done" .. (SETUP_REPORT.problems > 0
                        and (" with " .. SETUP_REPORT.problems .. " PROBLEM(S) — type /staffdb in-game for the live report")
                        or " — all tables OK"))
        else
                dbg("bootstrap aborted — fix the mysql resource, then type /staffdb to re-check")
        end
end)

-- live, in-chat database report for admins
addCommandHandler("staffdb", function(player)
        if player and not (exports.integration and exports.integration:isPlayerStaff(player)) then
                return
        end
        runSetup()
        outputChatBox("=== Vortex Staff — DB state ===", player, 120, 200, 255)
        for _, line in ipairs(SETUP_REPORT.lines) do
                local r, g, b = 160, 200, 255
                if line:find("FAILED") or line:find("MISSING") or line:find("BROKEN")
                        or line:find("UNREADABLE") or line:find("NOT FOUND") then
                        r, g, b = 255, 80, 80
                end
                outputChatBox("• " .. line, player, r, g, b)
        end
        if SETUP_REPORT.problems > 0 then
                outputChatBox("PROBLEMS: " .. SETUP_REPORT.problems .. " — check debugscript 3", player, 255, 120, 120)
        else
                outputChatBox("All tables OK. Panel buttons now work even if UIKit events die (V7 fallback).",
                        player, 120, 255, 120)
        end
end)
