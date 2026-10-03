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
        },
        -- [Fix #63] name MUST stay exactly "Dustman" - the decompiled client
        -- compares getElementData(job) == "Dustman" (c_decompiled.lua:7/96)
        dustman = {
                code = "dustman",
                name = "Dustman",
                label = "Dustman",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Collector", required_exp = 50, salary = 0 },
                        { name = "Sanitation Expert", required_exp = 150, salary = 0 }
                }
                -- EXP-only job in the decompile (no giveJobSalary call) so
                -- salaries are 0; EXP +1 per delivered trash (client-driven)
        },
        -- [Fix #63] name MUST stay exactly "Drug Dealer" - the decompiled
        -- client compares it verbatim and takes it via drug_dealer:takeJob
        drug_dealer = {
                code = "drug_dealer",
                name = "Drug Dealer",
                label = "Drug Dealer",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Grower", required_exp = 50, salary = 0 },
                        { name = "Supplier", required_exp = 150, salary = 0 }
                }
                -- harvested plants sell as items (no salary/EXP calls exist
                -- in the decompile)
        },
        -- [Fix #63] name MUST stay exactly "Liquor Dealer" (same decompile
        -- family as the drug dealer; taken via liquor_dealer:takeJob)
        liquor_dealer = {
                code = "liquor_dealer",
                name = "Liquor Dealer",
                label = "Liquor Dealer",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Brewer", required_exp = 50, salary = 0 },
                        { name = "Supplier", required_exp = 150, salary = 0 }
                }
        },
        -- [Fix #63] name MUST stay exactly "Trucker" (client compares it)
        trucker = {
                code = "trucker",
                name = "Trucker",
                label = "Trucker",
                jobs_center = true,
                requirements = {
                        min_level = 3
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Hauler", required_exp = 50, salary = 0 },
                        { name = "Long Hauler", required_exp = 150, salary = 0 },
                        { name = "Road Master", required_exp = 400, salary = 0 }
                }
                -- paid per delivery straight to the wallet (no giveJobSalary
                -- call exists in the decompile)
        },
        -- [Fix #63] name MUST stay exactly "Pizza Deliverer" (client compares)
        pizza = {
                code = "pizza",
                name = "Pizza Deliverer",
                label = "Pizza Deliverer",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Deliverer", required_exp = 50, salary = 0 },
                        { name = "Route Master", required_exp = 150, salary = 0 }
                }
                -- EXP-only in the decompile (no giveJobSalary call)
        },
        -- [Fix #63] name MUST stay exactly "Forklift Operator" (client compares)
        forklift = {
                code = "forklift",
                name = "Forklift Operator",
                label = "Forklift Operator",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Operator", required_exp = 50, salary = 0 },
                        { name = "Dock Master", required_exp = 150, salary = 0 }
                }
                -- EXP-only in the decompile (no giveJobSalary call)
        },
        -- [Fix #63] name MUST stay exactly "Bus Driver" (client compares it)
        bus = {
                code = "bus",
                name = "Bus Driver",
                label = "Bus Driver",
                jobs_center = true,
                requirements = {
                        min_level = 2
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Driver", required_exp = 50, salary = 0 },
                        { name = "Line Veteran", required_exp = 150, salary = 0 }
                }
                -- EXP-only in the decompile (no giveJobSalary call)
        },
        -- [Fix #63] name MUST stay exactly "Gunsmith" (client compares it)
        gunsmith = {
                code = "gunsmith",
                name = "Gunsmith",
                label = "Gunsmith",
                jobs_center = true,
                requirements = {
                        min_level = 2
                },
                ranks = {
                        { name = "Apprentice", required_exp = 0, salary = 0 },
                        { name = "Craftsman", required_exp = 50, salary = 0 },
                        { name = "Master Gunsmith", required_exp = 200, salary = 0 }
                }
                -- earns by crafting/assembling in the factory (sold to
                -- players); no giveJobSalary call in the decompile
        },
        -- [Fix #63] name MUST stay exactly "Fuel Deliverer" (client compares)
        fuel = {
                code = "fuel",
                name = "Fuel Deliverer",
                label = "Fuel Deliverer",
                jobs_center = true,
                requirements = {
                        min_level = 3
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Tanker Driver", required_exp = 50, salary = 0 },
                        { name = "Route Veteran", required_exp = 150, salary = 0 }
                }
                -- EXP +1 per 5000L drop (client-driven, decompile-verbatim)
        },
        -- [Fix #63] name MUST stay exactly "Postman" (client compares it)
        postman = {
                code = "postman",
                name = "Postman",
                label = "Postman",
                jobs_center = true,
                requirements = {
                        min_level = 2
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Courier", required_exp = 50, salary = 0 },
                        { name = "Route Master", required_exp = 150, salary = 0 }
                }
                -- EXP +1 per delivered box (client-driven, decompile-verbatim)
        },
        -- [Fix #63] name MUST stay exactly "Farmer" (client compares it)
        farmer = {
                code = "farmer",
                name = "Farmer",
                label = "Farmer",
                jobs_center = true,
                requirements = {
                        min_level = 1
                },
                ranks = {
                        { name = "Rookie", required_exp = 0, salary = 0 },
                        { name = "Grower", required_exp = 50, salary = 0 },
                        { name = "Harvest Master", required_exp = 150, salary = 0 }
                }
                -- earns by selling crops (no giveJobSalary in the decompile)
        }
}

local JOBS_LIST = { "taxi", "dustman", "drug_dealer", "liquor_dealer", "trucker", "pizza", "forklift", "bus", "gunsmith", "fuel", "postman", "farmer" }

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

-- givePlayerJobEXP(jobName, amount) -> level-system
-- [Fix #63] REAL Owl contract (see c_job_owl): the job clients call
-- givePlayerJobEXP("Postman", 1) etc - (jobName, amount), not (amount, reason).
-- The old server presumably gated the name against the player's job - kept.
addEvent("jobs:givePlayerJobEXP", true)
addEventHandler("jobs:givePlayerJobEXP", root, function(jobName, amount)
        local player = client
        if not player or type(jobName) ~= "string" or not tonumber(amount) then
                return
        end
        amount = math.floor(tonumber(amount))
        if amount <= 0 or amount > 500 then
                return -- anti-exploit cap
        end
        if getElementData(player, "job") ~= jobName then
                return -- can only earn EXP for the job you hold
        end
        -- job-rank EXP (character_jobs.exp drives getJobRankByEXP / salaries)
        local characterID = tonumber(getElementData(player, "character:id"))
        local code = getJobByName(jobName)
        if characterID and code then
                mysql:query_free("UPDATE character_jobs SET exp = exp + " .. amount .. " WHERE character_id = " .. characterID .. " AND job_code = '" .. code .. "'")
        end
        exports["level-system"]:addExp(player, amount, jobName)
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

-- ===========================================================================
-- Legacy /setjob contract - MISSING EXPORTS
--
-- job-system used to export only the four CLIENT functions in meta.xml.
-- Three SERVER callers still call into this resource and every one of them
-- died with `call: failed to call 'job-system:getJobTitleFromID'`:
--   * admin-system/Player/s_checkc.lua:35      (/checkc job line)
--   * hud/s_overlay_basic_info.lua:401         (Career line of /stats overlay,
--                                               called WITHOUT pcall -> live error)
--   * job-system-trucker/s_trucker_job_admin_cmds.lua:9  (/setjob, /setjoblevel)
-- and a fourth one calls the sibling below:
--   * job-system-trucker/s_trucker_job_admin_cmds.lua:141/501 (/setjob, /deljob)
-- ===========================================================================

-- The authoritative legacy job ids are the ones printSetJobSyntax() in
-- job-system-trucker/s_trucker_job_admin_cmds.lua prints (ID#1 .. ID#7), which
-- is also the table /setjob writes into characters.job.
local LEGACY_JOB_TITLES = {
        [0] = "Unemployed",
        [1] = "Delivery Driver",
        [2] = "Taxi Driver",
        [3] = "Bus Driver",
        [4] = "City Maintenance",
        [5] = "Mechanic",
        [6] = "Locksmith",
        [7] = "Long Haul Truck Driver",
}

-- jobID may be: a legacy numeric id (characters.job), the numeric id as a
-- string, or a plain job NAME - the ported job system stores the NAME in the
-- "job" element data, so the HUD overlay hands a string here once a player
-- took a ported job. Anything unrecognised degrades to a readable label
-- instead of throwing.
function getJobTitleFromID(jobID)
        if type(jobID) == "string" then
                local s = jobID:gsub("^%s+", ""):gsub("%s+$", "")
                if s == "" or s == "0" then return "Unemployed" end
                local numeric = tonumber(s)
                if numeric then
                        if numeric % 1 ~= 0 then numeric = math.floor(numeric) end
                        return LEGACY_JOB_TITLES[numeric] or ("Job ID " .. numeric)
                end
                return s
        end

        local id = tonumber(jobID)
        if not id or id <= 0 then return "Unemployed" end
        if id % 1 ~= 0 then id = math.floor(id) end
        return LEGACY_JOB_TITLES[id] or ("Job ID " .. id)
end

-- Re-publish the job element data from the LEGACY characters.job column.
-- This is exactly what /setjob and /deljob expect: they UPDATE characters.job
-- and then call this so the target's "job" element data (and therefore the
-- HUD Career line, F1 and /checkc) reflects the new value immediately.
-- The ported character_jobs system keeps its own login restore above; this
-- function only answers the legacy contract its two callers ask for.
function fetchJobInfoForOnePlayer(player)
        if not (isElement(player) and getElementType(player) == "player") then
                return nil
        end
        local dbid = tonumber(getElementData(player, "dbid"))
        if not dbid then return nil end

        local row = mysql:query_fetch_assoc("SELECT `job` FROM characters WHERE id = " .. dbid)
        local title = getJobTitleFromID(row and row["job"])

        if title == "Unemployed" then
                -- same removal style the ported quitJob path uses
                removeElementData(player, "job")
                return nil
        end

        exports.anticheat:changeProtectedElementDataEx(player, "job", title, true)
        return title
end
