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

-- [old client] /piss — empties the bladder (urine back to 0)
addCommandHandler("piss", function(player)
        local st = playerStatus[player]
        if st then
                st.urine = 0
                sendStatus(player)
                notify(player, "You feel relieved", "شعرت بارتياح", 3000)
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
        { "head_turning", "on", "head_turning", "Head Turning", "" },
        { "togpm",        "on", "togpm",        "Toggle Personal Messages", "" },
        { "reportpanel",  "on", "reportpanel",  "Report Center", "" },
        { "ads",          "on", "ads",          "Advertisements", "" },
}

local function pushDefaultItems(player)
        local items = getElementData(player, "hud:items")
        if type(items) == "table" and #items > 0 then return end -- resources may have added their own
        local list = {}
        for _, item in ipairs(DEFAULT_ITEMS) do
                table.insert(list, { item[1], item[2], item[3], item[4], item[5], nil })
        end
        setProtected(player, "hud:items", list)
end

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
        elseif item == "head_turning" then
                -- cycle 0 -> 1 -> 2 -> 0 (realism-system/c_ped_look_at reads this)
                local cur = tostring(getElementData(player, "head_turning") or "0")
                local next_ = (cur == "0" and "1") or (cur == "1" and "2") or "0"
                setProtected(player, "head_turning", next_)
        elseif item == "reportpanel" then
                -- handled client-side (opens report-system UI)
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
