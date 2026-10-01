--------------------------------------------------------------------------------
-- VORTEX HUD — server (Fix #19)
-- Old client event names preserved exactly (backupm hud + life-system flow):
--   * typing:sync                 relay ((TYPING...)) to nearby players
--   * hud:onHudItemClick          strip item router (old names -> this server)
--   * hud:engine / hud:handbrake / hud:lockvehicle / hud:vehiclelights
--   * hud:remove_heart            life boost cleanup (guarded)
--   * character_status:*          the old life-system status protocol
--     (sendToClient / update / request_sync) with the exact old decay rates:
--     thirsty -1/min, hungry -0.5/min, urine +0.2/min, cleanness -0.05/min,
--     sleepy +0.15/min, warnings + health penalties at the limits.
--   * consume actions (Fix #19): /drink /eat /shower /sleep refill the needs
--     and heal, /piss empties the bladder — server counts every value
--   * Fix #21: /piss is the FULL sequence — it plays the old PAULNMAC pee
--     animation, the animation STOPS BY ITSELF when it finishes, and only
--     then the bladder empties (client shows the urine ring FULL again and
--     it depletes gradually while the bladder refills)
--   * Fix #21: life:setAnimation server bridge (old life-system event the
--     client triggers for the forced tired animation — nothing handled it
--     before, so the tired animation never played and never stopped)
--   * hud:items default strip pushed on login (walkingstyle/head_turning/
--     togpm/reportpanel/ads)
--------------------------------------------------------------------------------

-- [old client] typing relay ----------------------------------------------------
addEvent("typing:sync", true)
addEventHandler("typing:sync", root, function(state)
        if client ~= source or not isElement(source) then return end
        local sX, sY, sZ = getElementPosition(source)
        for _, player in ipairs(getElementsByType("player")) do
                if player ~= source and isElement(player) then
                        local pX, pY, pZ = getElementPosition(player)
                        if getDistanceBetweenPoints3D(sX, sY, sZ, pX, pY, pZ) <= 60 then
                                triggerClientEvent(player, "typing:sync", source, state)
                        end
                end
        end
end)

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function notify(player, textEN, textAR, ms)
        if getResourceFromName("notifications")
                and getResourceState(getResourceFromName("notifications")) == "running" then
                pcall(function()
                        exports.notifications:output({ en = textEN, ar = textAR }, ms or 8000, "warning", "right")
                end)
        else
                outputChatBox(textEN .. " | " .. textAR, player, 255, 176, 32, true)
        end
end

local function setProtected(player, key, value)
        local ac = getResourceFromName("anticheat")
        if ac and getResourceState(ac) == "running" and isElement(player) then
                pcall(function()
                        exports.anticheat:changeProtectedElementDataEx(player, key, value, true)
                end)
        else
                if isElement(player) then setElementData(player, key, value, true) end
        end
end

--------------------------------------------------------------------------------
-- CHARACTER STATUS ENGINE (old life-system rates, server authoritative)
--------------------------------------------------------------------------------
local STATUS_DEFAULTS = { thirsty = 100, hungry = 100, urine = 0, sleepy = 0, cleanness = 100 }
local playerStatus = {}   -- [player] = {thirsty=.., hungry=.., ...}

local function sendStatus(player)
        if not isElement(player) or not playerStatus[player] then return end
        triggerClientEvent(player, "character_status:sendToClient", player, playerStatus[player])
end

local function loadStatus(player)
        local st = {}
        for k, v in pairs(STATUS_DEFAULTS) do st[k] = v end
        -- restore from the account when possible
        local account = getPlayerAccount(player)
        if account and not isGuestAccount(account) then
                local ok, raw = pcall(getAccountData, account, "character:status")
                if ok and raw then
                        local saved = fromJSON(raw)
                        if type(saved) == "table" then
                                for k in pairs(STATUS_DEFAULTS) do
                                        if type(saved[k]) == "number" then st[k] = saved[k] end
                                end
                        end
                end
        end
        playerStatus[player] = st
        sendStatus(player)
end

local function saveStatus(player)
        local st = playerStatus[player]
        if not st then return end
        local account = getPlayerAccount(player)
        if account and not isGuestAccount(account) then
                pcall(setAccountData, account, "character:status", toJSON(st))
        end
end

local function clamp(v)
        if v < 0 then v = 0 elseif v > 100 then v = 100 end
        return v
end

--------------------------------------------------------------------------------
-- [old client] /piss — Fix #21: the FULL pee sequence.
--   1. plays the old PAULNMAC pee animation, BOUNDED (the old animation-system
--      used -1 = looped forever and never stopped — fixed)
--   2. when it finishes the animation STOPS BY ITSELF (global:removeAnimation
--      also restores the controls that applyAnimation locked)
--   3. only then the bladder empties -> client urine ring goes FULL and starts
--      depleting gradually while the bladder refills (+0.2/min, old rate)
--------------------------------------------------------------------------------
local PISS_ANIM_MS = 7000       -- how long the pee animation lasts
local peeing = {}               -- [player] = true while the sequence runs

local function forceStopAnimation(player)
        local g = getResourceFromName("global")
        if g and getResourceState(g) == "running" then
                pcall(function() exports.global:removeAnimation(player) end)
        else
                setPedAnimation(player, false)
                toggleAllControls(player, true, true, false)
        end
end

addCommandHandler("piss", function(player)
        local st = playerStatus[player]
        if not st or isPedDead(player) or peeing[player] then return end
        if isPedInVehicle(player) then
                notify(player, "You can't pee inside a vehicle", "لا يمكنك قضاء الحاجة داخل السيارة", 3000)
                return
        end
        peeing[player] = true
        -- bounded animation: global's applyAnimation removes it automatically
        -- after the duration and restores the controls (stop by itself)
        local applied = nil
        local g = getResourceFromName("global")
        if g and getResourceState(g) == "running" then
                local ok, res = pcall(function()
                        return exports.global:applyAnimation(player, "PAULNMAC", "Piss_loop",
                                PISS_ANIM_MS, true, false, false)
                end)
                if ok then applied = res end
        end
        if applied == false then                 -- frozen / tazed / injured
                peeing[player] = nil
                return
        end
        if applied == nil then                   -- global not running: raw fallback
                setPedAnimation(player, "PAULNMAC", "Piss_loop", PISS_ANIM_MS, true, false, false)
        end
        -- finished: the animation stopped by itself -> bladder empty now
        setTimer(function()
                peeing[player] = nil
                if not isElement(player) then return end
                forceStopAnimation(player)
                local st2 = playerStatus[player]
                if st2 and not isPedDead(player) then
                        st2.urine = 0
                        sendStatus(player)
                        notify(player, "You feel relieved", "شعرت بارتياح", 3000)
                end
        end, PISS_ANIM_MS + 200, 1)
end)

--------------------------------------------------------------------------------
-- OLD LIFE-SYSTEM BRIDGE (Fix #21): the hud client triggers life:setAnimation
-- for the forced tired animation (fatigue 95%) but nothing handled it, so the
-- animation never played and never stopped. Old event shape kept exactly:
--   life:setAnimation(block, name, animtime, loop, updatePosition, forced)
--   life:setAnimation()                                  -> stop the animation
--------------------------------------------------------------------------------
addEvent("life:setAnimation", true)
addEventHandler("life:setAnimation", root, function(block, name, animtime, loop, updatePosition, forced)
        local player = client
        if not player or client ~= source then return end
        if not isElement(player) or isPedDead(player) then return end
        if not block or not name then
                forceStopAnimation(player)
                return
        end
        local g = getResourceFromName("global")
        if g and getResourceState(g) == "running" then
                pcall(function()
                        exports.global:applyAnimation(player, block, name,
                                animtime or -1, loop ~= false, updatePosition ~= false, forced ~= false)
                end)
        else
                setPedAnimation(player, block, name, animtime or -1, loop ~= false)
        end
end)

--------------------------------------------------------------------------------
-- CONSUME ACTIONS (Fix #19 — full needs loop, server authoritative):
-- the server owns every value; the rings mirror it 1:1 on the client
-- (full state = full circle, depleting gradually until the line disappears).
-- Consuming refills a need AND improves health (e.g. drinking heals).
--   /drink   thirsty +40, urine +10 (what goes in must come out), health +5
--   /eat     hungry +40, health +5
--   /shower  cleanness back to 100
--   /sleep   sleepy back to 0 (rested)
--   /piss    urine back to 0 (old client)
--------------------------------------------------------------------------------
local CONSUME_COOLDOWN = 30000  -- ms between two uses of the same action
local lastConsume = {}

local function maxHealthOf(player)
        return 0.232018558500192 * getPedStat(player, 24) - 32.018558511152
end

local function heal(player, amount)
        if isPedDead(player) then return end
        local maxhp = maxHealthOf(player)
        local cur = getElementHealth(player)
        if cur < maxhp then
                setElementHealth(player, math.min(maxhp, cur + amount))
        end
end

local function canConsume(player, action)
        local now = getTickCount()
        local last = lastConsume[player] and lastConsume[player][action]
        if last and now - last < CONSUME_COOLDOWN then
                local left = math.ceil((CONSUME_COOLDOWN - (now - last)) / 1000)
                notify(player, "Wait " .. left .. " seconds before doing that again",
                        "انتظر " .. left .. " ثانية قبل تكرارها", 3000)
                return false
        end
        lastConsume[player] = lastConsume[player] or {}
        lastConsume[player][action] = now
        return true
end

addCommandHandler("drink", function(player)
        local st = playerStatus[player]
        if not st or isPedDead(player) or not canConsume(player, "drink") then return end
        st.thirsty = clamp((st.thirsty or 0) + 40)
        st.urine = clamp((st.urine or 0) + 10)
        sendStatus(player)
        heal(player, 5)
        notify(player, "You drank some water and feel refreshed", "شربت ماء وشعرت بتحسن", 3000)
end)

addCommandHandler("eat", function(player)
        local st = playerStatus[player]
        if not st or isPedDead(player) or not canConsume(player, "eat") then return end
        st.hungry = clamp((st.hungry or 0) + 40)
        sendStatus(player)
        heal(player, 5)
        notify(player, "You ate some food and feel better", "أكلت شيئاً وشعرت بتحسن", 3000)
end)

addCommandHandler("shower", function(player)
        local st = playerStatus[player]
        if not st or isPedDead(player) or not canConsume(player, "shower") then return end
        st.cleanness = 100
        sendStatus(player)
        notify(player, "You took a shower, you are clean again", "استحممت وأصبحت نظيفاً", 3000)
end)

addCommandHandler("sleep", function(player)
        local st = playerStatus[player]
        if not st or isPedDead(player) or not canConsume(player, "sleep") then return end
        st.sleepy = 0
        sendStatus(player)
        notify(player, "You slept and feel rested", "نمت وشعرت بالنشاط", 3000)
end)

-- one global 60s tick, exact old-client decay table
setTimer(function()
        for _, player in ipairs(getElementsByType("player")) do
                local st = playerStatus[player]
                if st and isElement(player)
                        and (getElementData(player, "loggedin") == 1 or getElementData(player, "character:id"))
                        and not isPedDead(player)
                        and not getElementData(player, "prisoner") then

                        -- thirsty: -1/min, hits 0 -> warning + health -2 (old)
                        if (st.thirsty or 0) <= 0 then
                                notify(player, "Your character is thirsty", "شخصيتك تشعر بالعطش", 8000)
                                setElementHealth(player, getElementHealth(player) - 2)
                        else
                                st.thirsty = clamp((st.thirsty or 0) - 1)
                        end

                        -- hungry: -0.5/min, hits 0 -> warning + health -2 (old)
                        if (st.hungry or 0) <= 0 then
                                notify(player, "Your character is hungry", "شخصيتك تشعر بالجوع", 8000)
                                setElementHealth(player, getElementHealth(player) - 2)
                        else
                                st.hungry = clamp((st.hungry or 0) - 0.5)
                        end

                        -- urine: +0.2/min, hits 100 -> warning + health -2 (old)
                        if (st.urine or 0) >= 100 then
                                notify(player, "Your character needs to pee, type /piss to pee",
                                        "شخصيتك بحاجة لقضاء الحاجة، اكتب /piss", 8000)
                                setElementHealth(player, getElementHealth(player) - 2)
                        else
                                st.urine = clamp((st.urine or 0) + 0.2)
                        end

                        -- cleanness: -0.05/min, hits 0 -> warning (old)
                        if (st.cleanness or 0) <= 0 then
                                notify(player, "Your character smells bad, you have to take a shower",
                                        "شخصيتك تنبعث منها رائحة كريهة، عليك بالاستحمام", 8000)
                        else
                                st.cleanness = clamp((st.cleanness or 0) - 0.05)
                        end

                        -- sleepy: +0.15/min, hits 100 -> warning + health -1 (old)
                        if (st.sleepy or 0) >= 100 then
                                notify(player, "Your character needs sleep", "شخصيتك بحاجة للنوم", 8000)
                                setElementHealth(player, getElementHealth(player) - 1)
                        else
                                st.sleepy = clamp((st.sleepy or 0) + 0.15)
                        end

                        sendStatus(player)
                end
        end
end, 60000, 0)

-- periodic save (every 10 minutes)
setTimer(function()
        for player in pairs(playerStatus) do
                saveStatus(player)
        end
end, 600000, 0)

-- old protocol: client asks, server answers
addEvent("character_status:request_sync", true)
addEventHandler("character_status:request_sync", root, function()
        local player = client
        if not player or client ~= source then return end
        if not getElementData(player, "character:id") and getElementData(player, "loggedin") ~= 1 then return end
        if not playerStatus[player] then loadStatus(player) return end
        sendStatus(player)
end)

-- old protocol: external pushes (setCharacterStatus clients used this)
addEvent("character_status:update", true)
addEventHandler("character_status:update", root, function(key, value)
        local player = client
        if not player or client ~= source then return end
        local st = playerStatus[player]
        if st and type(key) == "string" and type(value) == "number" and st[key] ~= nil then
                st[key] = clamp(value)
                sendStatus(player)
        end
end)

-- respawn refill (old client: thirsty/hungry back to 20 when they hit 0)
addEventHandler("onPlayerSpawn", root, function()
        local st = playerStatus[source]
        if st then
                if (st.thirsty or 0) <= 0 then st.thirsty = 20 end
                if (st.hungry or 0) <= 0 then st.hungry = 20 end
                sendStatus(source)
        end
end)

addEventHandler("onPlayerLogin", root, function()
        loadStatus(source)
end)

addEventHandler("onPlayerResourceStart", root, function(res)
        if res == getThisResource() and getElementData(source, "loggedin") == 1 then
                loadStatus(source)
        end
end)

addEventHandler("onPlayerQuit", root, function()
        saveStatus(source)
        playerStatus[source] = nil
        lastConsume[source] = nil
        peeing[source] = nil
end)

-- exported for other resources (old life-system server API shape)
function getCharacterStatus(player, key)
        local st = playerStatus[player]
        if not st then return false end
        if key then return st[key] end
        return st
end

function setCharacterStatusValue(player, key, value)
        local st = playerStatus[player]
        if st and type(key) == "string" and type(value) == "number" and st[key] ~= nil then
                st[key] = clamp(value)
                sendStatus(player)
                return true
        end
        return false
end

--------------------------------------------------------------------------------
-- DEFAULT STRIP ITEMS (pushed on login — old hud:items element data format:
-- {id, state, icon, tip1, tip2, category})
--------------------------------------------------------------------------------
local DEFAULT_ITEMS = {
        { "walkingstyle", "on", "walkingstyle", "Next Walking Style", "" },
        -- [Fix #32 - user] "شيل head turing و فتح وقفل سيارة": the head-turning
        -- and Lock/Unlock-Vehicle strip items are REMOVED (the in-vehicle quick
        -- row still has its own engine/lock/lights buttons like the old client)
        { "togpm",        "on", "togpm",        "Toggle Personal Messages", "" },
        { "reportpanel",  "on", "reportpanel",  "Report Center", "" },
        { "admintag",     "on", "admin_badge",  "Toggle Admin Tag", "" },
        -- ("ads" dropped: icons/ads.png does not exist, the item rendered nothing)
}

local function isStaffForStrip(player)
        -- rank ladder first (staff bridge), legacy columns as fallback
        local idx = tonumber(getElementData(player, "rank:index"))
        if idx then return idx >= 4 end -- Trial Moderator+
        return (tonumber(getElementData(player, "admin_level")) or 0) > 0
                or (tonumber(getElementData(player, "account:gmlevel")) or 0) > 0
end

-- [Fix #30] UPSERT, not "only when empty". The old early-return meant any
-- player whose hud:items had been set once (stale list from an earlier
-- login, another resource, an older build) NEVER received the new items -
-- the owner reported "F4 has no duty toggle and no PM lock". Every login
-- the defaults are merged in (missing rows added, duplicates skipped) and
-- the duty row is re-synced to the live duty state.
local function pushDefaultItems(player)
        if not isElement(player) then return end
        local items = getElementData(player, "hud:items")
        if type(items) ~= "table" then items = {} end

        local function upsert(id, state, icon, tip1, tip2)
                for _, row in ipairs(items) do
                        if type(row) == "table" and row[1] == id then
                                return
                        end
                end
                items[#items + 1] = { id, state, icon, tip1, tip2, nil }
        end

        for _, item in ipairs(DEFAULT_ITEMS) do
                upsert(item[1], item[2], item[3], item[4], item[5])
        end
        -- [Fix #32 - user] rows removed from the strip must be actively
        -- PRUNED (the upsert above would keep stale head_turning/lockvehicle
        -- rows on every account that received them before)
        for i = #items, 1, -1 do
                local row = items[i]
                if type(row) == "table" and (row[1] == "head_turning" or row[1] == "lockvehicle") then
                        table.remove(items, i)
                end
        end
        -- staff-only duty toggle (on/off duty = badge above the head while on
        -- duty). Trial Moderator+ gets the ADMIN badge (/adminduty); pure
        -- supporters get the SUPPORT badge (/sduty). Both routed through the
        -- REAL commands so every check/announcement applies.
        local ridx = tonumber(getElementData(player, "rank:index"))
        local adminLevel = tonumber(getElementData(player, "admin_level")) or 0
        local supporterLevel = tonumber(getElementData(player, "supporter_level")) or 0
        local isAdminDuty = (ridx and ridx >= 4) or adminLevel > 0
        local isSupportDuty = not isAdminDuty
                and ((ridx and ridx >= 1 and ridx <= 3) or supporterLevel > 0
                        or (tonumber(getElementData(player, "account:gmlevel")) or 0) > 0)
        if isAdminDuty or isSupportDuty then
                local duty = (isAdminDuty and tonumber(getElementData(player, "duty_admin")) == 1)
                        or (isSupportDuty and tonumber(getElementData(player, "duty_supporter")) == 1)
                local id = isAdminDuty and "adminduty" or "supduty"
                upsert(id, duty and "on" or "off", isAdminDuty and "admin_badge" or "support_badge",
                        isAdminDuty and "Admin Duty (Badge)" or "Support Duty (Badge)", "")
                for _, row in ipairs(items) do
                        if type(row) == "table" and row[1] == id then
                                row[2] = duty and "on" or "off"
                        end
                end
        end
        setProtected(player, "hud:items", items)
end

-- [Fix #30] the duty state lives in elementData, so keep the strip icon
-- truthful whenever it flips (via /adminduty, /gm duty, the panel, ...)
local function refreshStripDutyState(player)
        if not isElement(player) then return end
        local items = getElementData(player, "hud:items")
        if type(items) ~= "table" then return end
        local changed = false
        for _, row in ipairs(items) do
                if type(row) == "table" and row[1] == "adminduty" then
                        local want = (tonumber(getElementData(player, "duty_admin")) == 1) and "on" or "off"
                        if row[2] ~= want then row[2] = want; changed = true end
                elseif type(row) == "table" and row[1] == "supduty" then
                        local want = (tonumber(getElementData(player, "duty_supporter")) == 1) and "on" or "off"
                        if row[2] ~= want then row[2] = want; changed = true end
                end
        end
        if changed then setProtected(player, "hud:items", items) end
end

-- [Fix #30] THIS server's account stack never fires onPlayerLogin (verified:
-- not a single triggerEvent("onPlayerLogin") exists in the repo) - the old
-- hook silently never ran, so the strip stayed empty. Hook the events the
-- stack ACTUALLY fires: accounts:character:select + the loggedin data flip.
addEvent("accounts:character:select", true)
addEventHandler("accounts:character:select", root, function()
        pushDefaultItems(source)
end)

addEventHandler("onElementDataChange", root, function(key, _, newValue)
        if key == "loggedin" and tonumber(newValue) == 1 then
                pushDefaultItems(source)
        elseif key == "duty_admin" or key == "duty_supporter" then
                refreshStripDutyState(source)
        end
end)

-- legacy MTA login event kept for compatibility
addEventHandler("onPlayerLogin", root, function()
        pushDefaultItems(source)
end)

addEventHandler("onPlayerResourceStart", root, function(res)
        if res == getThisResource() and getElementData(source, "loggedin") == 1 then
                pushDefaultItems(source)
        end
end)

--------------------------------------------------------------------------------
-- STRIP ITEM ROUTER (old client event name, this server's systems)
--------------------------------------------------------------------------------
addEvent("hud:onHudItemClick", true)
addEventHandler("hud:onHudItemClick", root, function(item)
        local player = client
        if not player or client ~= source then return end
        if item == "walkingstyle" then
                triggerEvent("realism:switchWalkingStyle", player, player)
        elseif item == "togpm" then
                triggerEvent("chat:togpm", player, player)
        elseif item == "ads" then
                triggerEvent("advertisements:open_ads", player)
        elseif item == "seatbelt" then
                triggerEvent("realism:seatbelt:toggle", player, player)
        -- [Fix #32 - user] head_turning + lockvehicle strip rows removed
        elseif item == "reportpanel" then
                -- handled client-side (opens the reports panel)
        elseif item == "admintag" then
                local admintagItems = getElementData(player, "hud:items") or {}
                for _, row in ipairs(admintagItems) do
                        if type(row) == "table" and row[1] == "admintag" then
                                row[2] = (row[2] == "on") and "off" or "on"
                                setProtected(player, "hud:items", admintagItems)
                                break
                        end
                end
        elseif item == "adminduty" then
                -- Fix #23: badge toggle runs the REAL /adminduty command (checks,
                -- announcements, element data) instead of a client-side fake
                executeCommandHandler("adminduty", player)
        elseif item == "supduty" then
                -- Fix #30: supporter duty through the REAL /sduty command
                executeCommandHandler("sduty", player)
        end
end)

--------------------------------------------------------------------------------
-- VEHICLE QUICK ACTIONS (old client events -> this server's vehicle systems)
--------------------------------------------------------------------------------
addEvent("hud:engine", true)
addEventHandler("hud:engine", root, function()
        local player = client
        if player and client == source then
                triggerEvent("toggleEngine", player, player)
        end
end)

addEvent("hud:handbrake", true)
addEventHandler("hud:handbrake", root, function()
        local player = client
        if player and client == source then
                triggerEvent("vehicle:handbrake", player, false, "hud")
        end
end)

addEvent("hud:lockvehicle", true)
addEventHandler("hud:lockvehicle", root, function()
        local player = client
        if player and client == source then
                triggerEvent("togLockVehicle", player, player)
        end
end)

addEvent("hud:vehiclelights", true)
addEventHandler("hud:vehiclelights", root, function()
        local player = client
        if player and client == source then
                triggerEvent("togLightsVehicle", player)
        end
end)

--------------------------------------------------------------------------------
-- HEART CLEANUP (old life-system boost hook — safe no-op until restored)
--------------------------------------------------------------------------------
addEvent("hud:remove_heart", true)
addEventHandler("hud:remove_heart", root, function()
        local player = client
        if not player or client ~= source then return end
        if getElementHealth(player) > 40 then
                local items = getElementData(player, "hud:items") or {}
                for i, item in ipairs(items) do
                        if item[1] == "heart" then
                                table.remove(items, i)
                                setProtected(player, "hud:items", items)
                                break
                        end
                end
        end
end)

--------------------------------------------------------------------------------
-- [Fix #35] /fpsdiag server driver — stops each suspect resource one at a
-- time, lets the client sample FPS, restarts it, and finally prints the
-- ranked verdict to the tester. Gated to ranks holding the "debug" right
-- (see command_gates_s.lua). Explicit step state machine:
--   step 1            = baseline sample
--   step 2..N+1       = one suspect resource stopped per step
--   step N+2          = everything restored, final sample, verdict
--------------------------------------------------------------------------------
local FPSDIAG_CANDIDATES = { "ped-system", "scoreboard", "map-system", "report-system", "main-menu" }
local fpsdiagResults, fpsdiagBusy, fpsdiagStep, fpsdiagTester = {}, false, 0, nil

local function fpsdiagPhaseCount()
        return #FPSDIAG_CANDIDATES + 2 -- baseline + candidates + restored
end

addEvent("fpsdiag:phase", true)
addEvent("fpsdiag:result", true)

local function fpsdiagVerdict()
        local tester = fpsdiagTester
        fpsdiagBusy = false
        if not tester then return end
        outputChatBox("========= [fpsdiag] VERDICT =========", tester, 255, 220, 120, false)
        local base
        for _, row in ipairs(fpsdiagResults) do
                if row[1] == "baseline" then base = row[2] end
        end
        local ranked = {}
        for _, row in ipairs(fpsdiagResults) do ranked[#ranked + 1] = row end
        table.sort(ranked, function(a, b)
                if a[1] == "baseline" then return false end
                if b[1] == "baseline" then return true end
                return (tonumber(a[2]) or 0) > (tonumber(b[2]) or 0)
        end)
        for _, row in ipairs(ranked) do
                local name, fps = tostring(row[1]), tonumber(row[2]) or 0
                local delta = base and (fps - base) or 0
                local mark = (delta > 6) and "   <<< THE CULPRIT" or ""
                outputChatBox(("%-14s %3d FPS  (%+d vs baseline)%s")
                        :format(name, fps, delta, mark), tester,
                        delta > 6 and 0 or 180, delta > 6 and 255 or 220, delta > 6 and 120 or 255, false)
        end
        for _, row in ipairs(fpsdiagResults) do
                if type(row[3]) == "table" and row[3].card then
                        local s = row[3]
                        outputChatBox(("GPU: %s | free VRAM: %s MB | RT: %s MB | textures: %s MB | players: %s")
                                :format(s.card, tostring(s.freeVRAM), tostring(s.rtMB),
                                        tostring(s.texMB), tostring(s.players)),
                                tester, 200, 200, 200, false)
                        break
                end
        end
        outputChatBox("Send Keeler a screenshot of this list.", tester, 255, 220, 120, false)
        fpsdiagResults = {}
        fpsdiagStep = 0
        fpsdiagTester = nil
end

addEventHandler("fpsdiag:result", root, function(phaseName, fps, stats)
        if not fpsdiagBusy or client ~= fpsdiagTester then return end
        fpsdiagResults[#fpsdiagResults + 1] = { tostring(phaseName), tonumber(fps) or 0, stats }
        outputChatBox(("[fpsdiag] %-12s %d FPS"):format(tostring(phaseName), tonumber(fps) or 0),
                fpsdiagTester, 180, 220, 255, false)
        if phaseName == "restored" then
                -- make sure the LAST candidate is running again before the verdict
                local last = FPSDIAG_CANDIDATES[#FPSDIAG_CANDIDATES]
                if last then
                        local r = getResourceFromName(last)
                        if r and getResourceState(r) ~= "running" then
                                startResource(r)
                                outputChatBox("[fpsdiag] restarted " .. last, fpsdiagTester, 150, 255, 150, false)
                        end
                end
                setTimer(fpsdiagVerdict, 150, 1)
                return
        end
        setTimer(fpsdiagAdvance, 600, 1)
end)

function fpsdiagAdvance()
        local tester = fpsdiagTester
        if not tester then return end
        -- restart the resource stopped in the PREVIOUS candidate step
        if fpsdiagStep >= 3 then
                local prev = FPSDIAG_CANDIDATES[fpsdiagStep - 2]
                if prev then
                        local r = getResourceFromName(prev)
                        if r and getResourceState(r) ~= "running" then
                                startResource(r)
                                outputChatBox("[fpsdiag] restarted " .. prev, tester, 150, 255, 150, false)
                        end
                end
        end
        fpsdiagStep = fpsdiagStep + 1
        if fpsdiagStep > fpsdiagPhaseCount() then
                fpsdiagVerdict()
                return
        end
        local name
        if fpsdiagStep == 1 then
                name = "baseline"
        elseif fpsdiagStep <= #FPSDIAG_CANDIDATES + 1 then
                name = FPSDIAG_CANDIDATES[fpsdiagStep - 1]
                local r = getResourceFromName(name)
                if r and getResourceState(r) == "running" then
                        stopResource(r)
                        outputChatBox("[fpsdiag] stopped " .. name .. " ...", tester, 255, 200, 120, false)
                else
                        outputChatBox("[fpsdiag] " .. name .. " not running (measured anyway)", tester, 255, 200, 120, false)
                end
        else
                name = "restored"
        end
        setTimer(function()
                triggerClientEvent(tester, "fpsdiag:phase", tester, name, 2500)
        end, 800, 1)
end

addEvent("fpsdiag:start", true)
addEventHandler("fpsdiag:start", root, function()
        if fpsdiagBusy then
                outputChatBox("[fpsdiag] already running - wait for the verdict.", client, 255, 120, 120, false)
                return
        end
        fpsdiagBusy = true
        fpsdiagResults = {}
        fpsdiagStep = 1
        fpsdiagTester = client
        setTimer(function()
                triggerClientEvent(fpsdiagTester, "fpsdiag:phase", fpsdiagTester, "baseline", 2500)
        end, 500, 1)
end)
