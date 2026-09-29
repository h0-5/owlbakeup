-- owlbakeup Fix #61 - job-system SERVER (Owl core), rebuilt from the client
-- contract (Fix #54 phone pattern). The Owl server was never in the dump,
-- so every event name comes from c_job_owl.lua:
--   jobs:get(hash)                       -> jobs:get:response(list, data | true)
--   jobs:take_job(name)                  -> elementData "job" + DB
--   jobs:start_job (+ /startjob)         -> elementData "job:on_duty" + onClientPrepareJob
--   jobs:quit_job  (+ /quitjob)          -> onClientPlayerQuitJob
--   jobs:get_character_data              -> jobs:get_character_data:response(records)
--   jobs:giveJobSalary(player, amt, why) -> money + total_salary bookkeeping
--   jobs:givePlayerJobEXP(amt, why)      -> level-system addExp
-- On login the current job is restored from character_jobs.
--
-- JOBS_DATA is reconstructed content (the old server data was lost): only
-- PORTED jobs are listed so a player can never take a job whose resource
-- does not exist yet - extend as each job gets ported.

local mysql = exports.mysql

local JOBS_DATA = {
        taxi = {
                code = "taxi",
                name = "Taxi Driver",
                label = "Taxi Driver",
                jobs_center = true,
                requirements = {
                        min_level = 2
                        -- driving_license left OFF until the old driving-license school
                        -- system is ported (the client check activates via this flag)
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 100 },
                        { name = "Driver", required_exp = 50, salary = 150 },
                        { name = "Skilled Driver", required_exp = 150, salary = 225 },
                        { name = "Veteran Driver", required_exp = 400, salary = 320 },
                        { name = "Taxi Master", required_exp = 900, salary = 450 }
                }
        }
}

local JOBS_LIST = { "taxi" }

local function ensureTable()
        mysql:query_free([[
                CREATE TABLE IF NOT EXISTS character_jobs (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        character_id INT NOT NULL,
                        job_code VARCHAR(32) NOT NULL,
                        exp INT NOT NULL DEFAULT 0,
                        first_work VARCHAR(32) NOT NULL DEFAULT '',
                        last_work VARCHAR(32) NOT NULL DEFAULT '',
                        total_salary INT NOT NULL DEFAULT 0,
                        is_current INT NOT NULL DEFAULT 0,
                        UNIQUE KEY ck_unique (character_id, job_code)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
end

local function getJobByName(name)
        for code, data in pairs(JOBS_DATA) do
                if data.name == name then
                        return code, data
                end
        end
        return nil
end

local function getCurrentRecord(characterID)
        return mysql:query_fetch_assoc("SELECT job_code, exp, first_work, last_work, total_salary FROM character_jobs WHERE character_id = " .. tonumber(characterID) .. " AND is_current = 1 LIMIT 1")
end

local function buildJobDataElementData(player, characterID, jobCode)
        local record = mysql:query_fetch_assoc("SELECT first_work, total_salary FROM character_jobs WHERE character_id = " .. tonumber(characterID) .. " AND job_code = '" .. mysql:escape_string(jobCode) .. "' LIMIT 1")
        local jobData = getElementData(player, "job:data") or {}
        jobData[JOBS_DATA[jobCode].name] = {
                tDate = record and record.first_work or "",
                total_salary = record and (tonumber(record.total_salary) or 0) or 0
        }
        return jobData
end

addEvent("jobs:get", true)
addEventHandler("jobs:get", root, function(hash)
        if hash == md5(toJSON(JOBS_LIST)) then
                triggerClientEvent(client, "jobs:get:response", client, true)
        else
                triggerClientEvent(client, "jobs:get:response", client, JOBS_LIST, JOBS_DATA)
        end
end)

addEvent("jobs:take_job", true)
addEventHandler("jobs:take_job", root, function(name)
        local player = client
        if not player or type(name) ~= "string" then
                return
        end
        local characterID = tonumber(getElementData(player, "character:id"))
        if not characterID or getElementData(player, "loggedin") ~= 1 then
                return
        end
        if getElementData(player, "job") then
                exports.notifications:outputToPlayer(player, "يجب عليك ترك وظيفتك أولا", 5000, "error")
                return
        end
        local code, data = getJobByName(name)
        if not code then
                return
        end
        local level = tonumber(getElementData(player, "level")) or 1
        if data.requirements.min_level and level < data.requirements.min_level then
                exports.notifications:outputToPlayer(player, "مستواك يجب أن يكون " .. data.requirements.min_level .. " أو أعلى", 5000, "error")
                return
        end
        -- driving_license requirement: skipped until the driving-license school
        -- system is ported (no job currently sets the flag)
        local today = os.date("%Y-%m-%d %H:%M:%S")
        mysql:query_free("UPDATE character_jobs SET is_current = 0 WHERE character_id = " .. characterID)
        local existing = mysql:query_fetch_assoc("SELECT id FROM character_jobs WHERE character_id = " .. characterID .. " AND job_code = '" .. code .. "' LIMIT 1")
        if existing then
                mysql:query_free("UPDATE character_jobs SET is_current = 1 WHERE id = " .. tonumber(existing.id))
        else
                mysql:query_free("INSERT INTO character_jobs (character_id, job_code, exp, first_work, last_work, total_salary, is_current) VALUES (" .. characterID .. ", '" .. code .. "', 0, '" .. today .. "', '" .. today .. "', 0, 1)")
        end
        exports.anticheat:changeProtectedElementDataEx(player, "job", name, true)
        exports.anticheat:changeProtectedElementDataEx(player, "job:data", buildJobDataElementData(player, characterID, code), true)
        triggerClientEvent(player, "onClientPlayerStartJob", player, name)
        exports.notifications:outputToPlayer(player, "تم تعيينك في وظيفة " .. name .. " - استخدم /startjob لبدء العمل", 5000, "info")
end)

local function startJob(player)
        local characterID = tonumber(getElementData(player, "character:id"))
        local jobName = getElementData(player, "job")
        if not characterID or not jobName then
                return
        end
        local code = getJobByName(jobName)
        if not code then
                return
        end
        mysql:query_free("UPDATE character_jobs SET last_work = '" .. os.date("%Y-%m-%d %H:%M:%S") .. "' WHERE character_id = " .. characterID .. " AND job_code = '" .. code .. "'")
        exports.anticheat:changeProtectedElementDataEx(player, "job:on_duty", true, true)
        triggerClientEvent(player, "onClientPrepareJob", player, jobName)
        exports.notifications:outputToPlayer(player, "بدأت العمل - وظيفة " .. jobName, 5000, "info")
end
addEvent("jobs:start_job", true)
addEventHandler("jobs:start_job", root, function()
        startJob(client)
end)
addCommandHandler("startjob", function(player)
        startJob(player)
end)

local function quitJob(player)
        local characterID = tonumber(getElementData(player, "character:id"))
        local jobName = getElementData(player, "job")
        if not characterID or not jobName then
                return
        end
        local code = getJobByName(jobName)
        if code then
                mysql:query_free("UPDATE character_jobs SET is_current = 0 WHERE character_id = " .. characterID .. " AND job_code = '" .. code .. "'")
        end
        removeElementData(player, "job")
        removeElementData(player, "job:on_duty")
        triggerClientEvent(player, "onClientPlayerQuitJob", player, jobName)
        exports.notifications:outputToPlayer(player, "استقلت من وظيفة " .. jobName, 5000, "info")
end
addEvent("jobs:quit_job", true)
addEventHandler("jobs:quit_job", root, function()
        quitJob(client)
end)
addCommandHandler("quitjob", function(player)
        quitJob(player)
end)

addEvent("jobs:get_character_data", true)
addEventHandler("jobs:get_character_data", root, function()
        local player = client
        local characterID = tonumber(getElementData(player, "character:id"))
        if not characterID then
                return
        end
        local records = {}
        local q = mysql:query("SELECT job_code, exp, first_work, last_work FROM character_jobs WHERE character_id = " .. characterID)
        if q then
                while true do
                        local row = mysql:fetch_assoc(q)
                        if not row then
                                break
                        end
                        table.insert(records, {
                                job_code = row.job_code,
                                exp = tonumber(row.exp) or 0,
                                first_work = row.first_work,
                                last_work = row.last_work
                        })
                end
                mysql:free_result(q)
        end
        triggerClientEvent(player, "jobs:get_character_data:response", player, records)
end)

-- giveJobSalary(amount, reason) arrives through the security shim as
-- (player, amount, reason) with client == player (self-payment only)
addEvent("jobs:giveJobSalary", true)
addEventHandler("jobs:giveJobSalary", root, function(player, amount, reason)
        local worker = client
        if not worker or player ~= worker or not tonumber(amount) or type(reason) ~= "string" or reason == "" then
                return
        end
        amount = math.floor(tonumber(amount))
        if amount <= 0 or amount > 2000 then
                return -- anti-exploit cap (server-side trust boundary)
        end
        local characterID = tonumber(getElementData(worker, "character:id"))
        local jobName = getElementData(worker, "job")
        if not characterID or not jobName then
                return
        end
        exports.global:giveMoney(worker, amount)
        local code = getJobByName(jobName)
        if code then
                mysql:query_free("UPDATE character_jobs SET total_salary = total_salary + " .. amount .. " WHERE character_id = " .. characterID .. " AND job_code = '" .. code .. "'")
                exports.anticheat:changeProtectedElementDataEx(worker, "job:data", buildJobDataElementData(worker, characterID, code), true)
        end
end)

-- givePlayerJobEXP(amount, reason) -> level-system
addEvent("jobs:givePlayerJobEXP", true)
addEventHandler("jobs:givePlayerJobEXP", root, function(amount, reason)
        local player = client
        if not player or not tonumber(amount) or type(reason) ~= "string" or reason == "" then
                return
        end
        amount = math.floor(tonumber(amount))
        if amount <= 0 or amount > 500 then
                return -- anti-exploit cap
        end
        if not getElementData(player, "job") then
                return
        end
        exports["level-system"]:addExp(player, amount, reason)
end)

-- login sync: restore the current job from character_jobs
addEventHandler("onElementDataChange", root, function(key)
        if key ~= "loggedin" or getElementType(source) ~= "player" then
                return
        end
        if getElementData(source, "loggedin") == 1 then
                setTimer(function(player)
                        if not isElement(player) or getElementData(player, "loggedin") ~= 1 then
                                return
                        end
                        local characterID = tonumber(getElementData(player, "character:id"))
                        if not characterID then
                                return
                        end
                        local record = getCurrentRecord(characterID)
                        if record and JOBS_DATA[record.job_code] then
                                exports.anticheat:changeProtectedElementDataEx(player, "job", JOBS_DATA[record.job_code].name, true)
                                exports.anticheat:changeProtectedElementDataEx(player, "job:data", buildJobDataElementData(player, characterID, record.job_code), true)
                        end
                end, 1500, 1, source)
        end
end)

addEventHandler("onResourceStart", resourceRoot, function()
        ensureTable()
end)
