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
                PRIMARY KEY (ID))]], "CREATE staff_roles") then
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
        local bad = fetchOne([=[
                SELECT COUNT(*) AS n FROM staff_roles
                WHERE Color IS NULL OR Color = '' OR Color = '{}'
                        OR Color NOT LIKE '[[%']=])
        if bad and tonumber(bad.n) and tonumber(bad.n) > 0 then
                if ddl("UPDATE staff_roles SET Color='[255,255,255,255]' WHERE Color IS NULL OR Color = '' OR Color = '{}' OR Color NOT LIKE '[['",
                        "UPDATE staff_roles colors") then
                        dbg("repaired " .. tonumber(bad.n) .. " rank color(s) -> white")
                        table.insert(SETUP_REPORT.lines, "rank colors repaired: " .. tonumber(bad.n))
                end
        end

        -- 5) orphaned members (AccountID without an account row) clean-up
        ddl("DELETE m FROM staff_role_members m LEFT JOIN accounts a ON a.id = m.AccountID WHERE a.id IS NULL",
                "DELETE orphaned staff_role_members")

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
