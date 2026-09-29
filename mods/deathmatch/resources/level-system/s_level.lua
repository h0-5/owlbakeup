-- owlbakeup Fix #61 - level-system SERVER, rebuilt from the client contract
-- (Fix #54 phone pattern). The Owl server was never in the old-client dump,
-- so every event/elementData name here comes from c_level.lua:
--   level:syncLocalLevel(level, exp, awards)  -> sent on login
--   level:onExpUp(level, lastExp, exp, boost) -> on EXP gain
--   level:onLevelUp(level, lastExp, exp)      -> on level-up
--   level:takeAward(awardId)                  -> F1 awards tab button
-- getRequiredExp mirrors the client formula: level^2 * 50.

local mysql = exports.mysql

local function getRequiredExp(level)
        return level ^ 2 * 50
end

local function ensureTables()
        mysql:query_free([[
                CREATE TABLE IF NOT EXISTS level_system (
                        character_id INT NOT NULL PRIMARY KEY,
                        level INT NOT NULL DEFAULT 1,
                        exp INT NOT NULL DEFAULT 0
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        mysql:query_free([[
                CREATE TABLE IF NOT EXISTS level_awards (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        character_id INT NOT NULL,
                        award VARCHAR(64) NOT NULL DEFAULT '',
                        description VARCHAR(255) NOT NULL DEFAULT '',
                        reason VARCHAR(255) NOT NULL DEFAULT '',
                        level INT NOT NULL DEFAULT 1,
                        created_at VARCHAR(64) NOT NULL DEFAULT '',
                        expiry_date VARCHAR(64) NOT NULL DEFAULT '',
                        taken INT NOT NULL DEFAULT 0
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
end

local function loadAwards(characterID)
        local awards = {}
        local q = mysql:query("SELECT id, award, description, reason, level, created_at, expiry_date FROM level_awards WHERE character_id = " .. tonumber(characterID) .. " AND taken = 0")
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then
                                break
                        end
                        table.insert(awards, {
                                id = tonumber(row.id),
                                award = row.award,
                                description = row.description,
                                reason = row.reason,
                                level = tonumber(row.level),
                                createdAt = row.created_at,
                                expiry_date = row.expiry_date
                        })
                end
                mysql:free_result(q)
        end
        return awards
end

local function syncPlayer(player)
        local characterID = tonumber(getElementData(player, "character:id"))
        if not characterID then
                return
        end
        local row = mysql:query_fetch_assoc("SELECT level, exp FROM level_system WHERE character_id = " .. characterID)
        local level, exp
        if row then
                level = tonumber(row.level) or 1
                exp = tonumber(row.exp) or 0
        else
                level, exp = 1, 0
                mysql:query_free("INSERT INTO level_system (character_id, level, exp) VALUES (" .. characterID .. ", 1, 0)")
        end
        exports.anticheat:changeProtectedElementDataEx(player, "level", level, true)
        triggerClientEvent(player, "level:syncLocalLevel", player, level, exp, loadAwards(characterID))
end

addEventHandler("onElementDataChange", root, function(key)
        if key ~= "loggedin" or getElementType(source) ~= "player" then
                return
        end
        if getElementData(source, "loggedin") == 1 then
                setTimer(syncPlayer, 1000, 1, source)
        end
end)

addEventHandler("onResourceStart", resourceRoot, function()
        ensureTables()
        for _, player in ipairs(getElementsByType("player")) do
                if getElementData(player, "loggedin") == 1 then
                        syncPlayer(player)
                end
        end
end)

addEventHandler("onPlayerQuit", root, function()
        removeElementData(source, "level")
end)

-- server-side EXP API (job salary/EXP flows call this)
function addExp(player, amount, reason)
        if not isElement(player) or not tonumber(amount) or tonumber(amount) <= 0 then
                return false
        end
        local characterID = tonumber(getElementData(player, "character:id"))
        if not characterID then
                return false
        end
        amount = math.floor(tonumber(amount))
        if amount > 5000 then
                amount = 5000 -- anti-exploit cap (server-side trust boundary)
        end
        local row = mysql:query_fetch_assoc("SELECT level, exp FROM level_system WHERE character_id = " .. characterID)
        local level = row and (tonumber(row.level) or 1) or 1
        local exp = row and (tonumber(row.exp) or 0) or 0
        local lastExp = exp
        exp = exp + amount
        local leveledUp = false
        while exp >= getRequiredExp(level) do
                exp = exp - getRequiredExp(level)
                level = level + 1
                leveledUp = true
        end
        if row then
                mysql:query_free("UPDATE level_system SET level = " .. level .. ", exp = " .. exp .. " WHERE character_id = " .. characterID)
        else
                mysql:query_free("INSERT INTO level_system (character_id, level, exp) VALUES (" .. characterID .. ", " .. level .. ", " .. exp .. ")")
        end
        exports.anticheat:changeProtectedElementDataEx(player, "level", level, true)
        if leveledUp then
                triggerClientEvent(player, "level:onLevelUp", player, level, lastExp, exp)
        else
                triggerClientEvent(player, "level:onExpUp", player, level, lastExp, exp, 0)
        end
        return true, level, exp
end

addEvent("level:takeAward", true)
addEventHandler("level:takeAward", root, function(awardId)
        local player = client
        if not player or not tonumber(awardId) then
                return
        end
        local characterID = tonumber(getElementData(player, "character:id"))
        if not characterID then
                return
        end
        local row = mysql:query_fetch_assoc("SELECT id, taken FROM level_awards WHERE id = " .. tonumber(awardId) .. " AND character_id = " .. characterID)
        if not row or tonumber(row.taken) == 1 then
                return
        end
        mysql:query_free("UPDATE level_awards SET taken = 1 WHERE id = " .. tonumber(awardId))
        triggerClientEvent(player, "level:syncLocalAwards", player, loadAwards(characterID))
        exports.notifications:outputToPlayer(player, "تم استلام الجائزة بنجاح", 5000, "info")
end)
