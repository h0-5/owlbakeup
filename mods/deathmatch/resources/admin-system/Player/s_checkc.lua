-- [Fix #160] A5 - /checkc server data provider
-- Owned exclusively by the matching Fix #160 task agent.
--
-- /checkc <player> -> right admin.checkc (staff_manager/gates_fix160_task5.lua,
-- enforced by the command-gates wrapper + onPlayerCommand).
-- Resolves the target's CHARACTER row - online player first, then a raw
-- character id / an exact character name - and pushes the cheap fields the
-- client panel (Player/c_checkc.lua) renders. Offline characters work too.

local mysql = exports.mysql

-- gender: 0 = Male, 1 = Female (account/s_create_character.lua:167)
local function checkcGender(v)
        return tonumber(v) == 1 and "Female" or "Male"
end

-- cked: 0 = alive, 1 = CK requested, 2 = CK'd (admin-system/Player/s_ck.lua)
local function checkcStatus(v)
        local n = tonumber(v) or 0
        if n == 2 then return "CK'd" end
        if n == 1 then return "CK pending" end
        return "Alive"
end

local function checkcJobLabel(jobID, online)
        -- the live element data carries the job NAME once the job system
        -- restored it; the DB column only holds the numeric job id
        if online then
                local live = getElementData(online, "job")
                if type(live) == "string" and live ~= "" then return live end
        end
        local id = tonumber(jobID) or 0
        if id <= 0 then return "Unemployed" end
        local ok, title = pcall(function()
                return exports["job-system"]:getJobTitleFromID(id)
        end)
        if ok and type(title) == "string" and title ~= "" then return title end
        return "Job ID " .. id
end

-- 1) online player (partial nick / name / id)  2) raw character id
-- 3) exact character name (underscores or spaces)
local function checkcResolve(query)
        query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if query == "" then return nil end

        local ok, target = pcall(function()
                -- third arg = quiet: no "No such player found." spam
                return exports.global:findPlayerByPartialNick(nil, query, true)
        end)
        if ok and isElement(target) and getElementType(target) == "player" then
                local dbid = tonumber(getElementData(target, "dbid"))
                if dbid then return dbid, target end
        end

        if query:match("^%d+$") then
                local row = mysql:query_fetch_assoc("SELECT id FROM characters WHERE id="
                        .. tonumber(query) .. " LIMIT 1")
                if row then return tonumber(row.id) end
        end

        local esc = mysql:escape_string(query:gsub(" ", "_"))
        local row = mysql:query_fetch_assoc("SELECT id FROM characters WHERE LOWER(charactername)=LOWER('"
                .. esc .. "') LIMIT 1")
        if not row then
                row = mysql:query_fetch_assoc("SELECT id FROM characters WHERE LOWER(charactername)=LOWER('"
                        .. mysql:escape_string(query) .. "') LIMIT 1")
        end
        if row then return tonumber(row.id) end
        return nil
end

local function checkcFaction(charRow)
        local factionID = tonumber(charRow.faction_id) or -1
        if factionID <= 0 then return "None", "-" end
        local rank = math.min(15, math.max(1, tonumber(charRow.faction_rank) or 1))
        local frow = mysql:query_fetch_assoc("SELECT `rank_" .. rank .. "` AS rname FROM factions WHERE id="
                .. factionID .. " LIMIT 1")
        local rankName = (frow and frow.rname) and tostring(frow.rname) or ("Rank " .. rank)
        return tostring(charRow.factionname or ("Faction #" .. factionID)), rankName
end

addCommandHandler("checkc", function(player, cmd, targetQuery)
        if not targetQuery or tostring(targetQuery) == "" then
                outputChatBox("SYNTAX: /" .. tostring(cmd) .. " [Player / Character Name / Character ID]",
                        player, 255, 194, 14)
                return
        end
        local charID, online = checkcResolve(targetQuery)
        if not charID then
                outputChatBox("Character not found: " .. tostring(targetQuery), player, 255, 0, 0)
                return
        end
        local row = mysql:query_fetch_assoc([[
                SELECT c.id, c.charactername, c.account, c.age, c.gender, c.weight, c.height,
                        c.job, c.faction_id, c.faction_rank, c.hoursplayed, c.money, c.bankmoney,
                        c.day, c.month, c.cked, c.deaths, c.lastarea, c.active,
                        a.username AS accountname, f.name AS factionname
                FROM characters c
                LEFT JOIN accounts a ON a.id = c.account
                LEFT JOIN factions f ON f.id = c.faction_id
                WHERE c.id = ]] .. charID)
        if not row then
                outputChatBox("Character record not found (id " .. charID .. ").", player, 255, 0, 0)
                return
        end
        local factionName, factionRank = checkcFaction(row)
        local data = {
                name = tostring(row.charactername or "?"):gsub("_", " "),
                account = tostring(row.accountname or "?"),
                accountID = tonumber(row.account),
                id = tonumber(row.id),
                age = tonumber(row.age),
                gender = checkcGender(row.gender),
                height = tonumber(row.height),
                weight = tonumber(row.weight),
                birthday = tostring(tonumber(row.day) or 1) .. "/" .. tostring(tonumber(row.month) or 1),
                job = checkcJobLabel(row.job, online),
                faction = factionName,
                factionRank = factionRank,
                hours = tonumber(row.hoursplayed),
                money = tonumber(row.money),
                bank = tonumber(row.bankmoney),
                area = tostring(row.lastarea or "-"),
                deaths = tonumber(row.deaths),
                status = checkcStatus(row.cked),
                online = online ~= nil,
        }
        triggerClientEvent(player, "checkc:show", player, data)
        outputChatBox("Character info opened for " .. data.name .. " (#" .. tostring(data.id) .. ").",
                player, 0, 255, 0)
end, false, false)
