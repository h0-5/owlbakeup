--[[ =========================================================================
        s_turf.lua — Vortex TURF SYSTEM server (Fix #57)

        The old client shipped ONLY the 84-line ring client; the server
        behind its events (OS:AREA.*) is rebuilt here on the Owl data,
        classic arma/OS turf-war rules:

          * turfs are radar-area rectangles + colshapes carrying the EXACT
            old client data key: elementData "OS:AREA.DB" =
            { ID, Turf, MaxTurf, Group, TurfGroup, OldTurf }
              - Group      = owning faction name (string, shown in the UI)
              - TurfGroup  = the faction currently capturing (string)
              - Turf/MaxTurf = capture progress
              - OldTurf    = previous owner (retake bookkeeping)
          * tick (5s): alive logged-in players inside are counted per team
              - attackers present, no defender  -> Turf += ATTACK_RATE
              - both sides present              -> contested (paused,
                                                   radar area flashing)
              - defender alone with progress    -> Turf decays (recovery)
              - capture complete                -> owner flips, radar recolors,
                                                  OldTurf = previous owner,
                                                  announce to both factions
          * players inside an ACTIVE turf get the old ring UI through
            OS:AREA.ShowProgress / UpdateAreaDB / HideProgress
          * persistence: turf_system table (CREATE TABLE IF NOT EXISTS =
            zero manual SQL), rows written on ownership change + stop

        NOTE: Group is the faction NAME (the old client showed a string;
        getTeamFromName resolves it back to the team element).
========================================================================= ]]

local mysql = exports.mysql

local TICK = 5000
local ATTACK_RATE = 4 -- progress per tick while capping (MaxTurf 50 -> ~63s)
local DEFEND_RECOVER = 2
local IDLE_DECAY = 1

local turfs = {} -- { {id, area, col, db={ID,Turf,MaxTurf,Group,TurfGroup,OldTurf}} }

-- capture zones (LS first like the old server): x, y, w, h radar rects
local TURF_CONFIG = {
        { x = 1970, y = -1450, w = 250, h = 250 }, -- East Beach industrial
        { x = 2180, y = -1830, w = 260, h = 220 }, -- East LS docks
        { x = 1930, y = -2050, w = 230, h = 200 }, -- El Corona
        { x = 1720, y = -1870, w = 220, h = 200 }, -- Little Mexico
        { x = 1450, y = -2050, w = 250, h = 220 }, -- Idlewood
        { x = 1290, y = -1650, w = 240, h = 240 }, -- Glen Park
        { x = 2000, y = -1100, w = 260, h = 240 }, -- Jefferson
        { x = 2350, y = -1050, w = 240, h = 220 }, -- East LS north
        { x = 830,  y = -1720, w = 260, h = 260 }, -- Verona Beach
        { x = 480,  y = -1350, w = 260, h = 260 }, -- Rodeo
        { x = 1310, y = -880,  w = 260, h = 240 }, -- Las Colinas
        { x = 2470, y = -670,  w = 260, h = 240 }, -- reflected heights
}

-- ---------------------------------------------------------------------------
-- persistence
-- ---------------------------------------------------------------------------
local function ensureTable()
        pcall(function()
                mysql:query_free([[CREATE TABLE IF NOT EXISTS turf_system (
                        id INT NOT NULL PRIMARY KEY,
                        turf INT NOT NULL DEFAULT 0,
                        maxturf INT NOT NULL DEFAULT 50,
                        groupName VARCHAR(64) NOT NULL DEFAULT '',
                        turf_group VARCHAR(64) NOT NULL DEFAULT '',
                        old_turf VARCHAR(64) NOT NULL DEFAULT ''
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        end)
end

local function saveTurfRow(db)
        pcall(function()
                mysql:query_free(string.format(
                        "UPDATE turf_system SET turf=%d, maxturf=%d, groupName='%s', turf_group='%s', old_turf='%s' WHERE id=%d",
                        tonumber(db.Turf) or 0, tonumber(db.MaxTurf) or 50,
                        mysql:escape_string(tostring(db.Group or "")),
                        mysql:escape_string(tostring(db.TurfGroup or "")),
                        mysql:escape_string(tostring(db.OldTurf or "")),
                        tonumber(db.ID) or 0))
        end)
end

local function loadTurfs()
        ensureTable()
        local rows = {}
        local ok, result = pcall(function() return mysql:query("SELECT * FROM turf_system ORDER BY id ASC") end)
        if ok and result then
                while true do
                        local row = mysql:fetch_assoc(result)
                        if not row then break end
                        rows[tonumber(row.id)] = row
                end
        end

        for i, cfg in ipairs(TURF_CONFIG) do
                local row = rows[i]
                local db = {
                        ID = i,
                        Turf = row and (tonumber(row.turf) or 0) or 0,
                        MaxTurf = row and (tonumber(row.maxturf) or 50) or 50,
                        Group = row and tostring(row.groupName or "") or "",
                        TurfGroup = row and tostring(row.turf_group or "") or "",
                        OldTurf = row and tostring(row.old_turf or "") or "",
                }
                if not row then
                        pcall(function()
                                mysql:query_free(string.format(
                                        "INSERT INTO turf_system (id, turf, maxturf, groupName, turf_group, old_turf) VALUES (%d, 0, %d, '', '', '')",
                                        i, db.MaxTurf))
                        end)
                end

                local area = createRadarArea(cfg.x, cfg.y, cfg.w, cfg.h, 0, 0, 0, 90)
                local col = createColRectangle(cfg.x, cfg.y, cfg.w, cfg.h)
                setElementParent(col, resourceRoot)
                setElementData(col, "OS:AREA.DB", db, true)
                if db.Group ~= "" then
                        local team = getTeamFromName(db.Group)
                        if isElement(team) then
                                local r, g, b = getTeamColor(team)
                                setRadarAreaColor(area, r, g, b, 90)
                        end
                end
                turfs[i] = { id = i, area = area, col = col, db = db, flashing = false, ringPlayers = {} }
        end
        outputDebugString("[turf-system] loaded " .. #turfs .. " turfs")
end

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function playersInCol(col)
        local inside = {}
        for _, p in ipairs(getElementsWithinColShape(col, "player")) do
                if isElement(p) and not isPedDead(p) and getElementData(p, "loggedin") == 1 then
                        table.insert(inside, p)
                end
        end
        return inside
end

local function turfTeamCounts(col)
        local counts = {}
        for _, p in ipairs(playersInCol(col)) do
                local team = getPlayerTeam(p)
                if isElement(team) then
                        local name = getTeamName(team)
                        counts[name] = (counts[name] or 0) + 1
                end
        end
        return counts
end

local function broadcastTurf(t, db)
        setElementData(t.col, "OS:AREA.DB", db, true)
end

local function ringShow(t, db)
        for _, p in ipairs(playersInCol(t.col)) do
                triggerClientEvent(p, "OS:AREA.ShowProgress", p, db)
                t.ringPlayers[p] = true
        end
end

local function ringUpdate(t, db)
        for _, p in ipairs(playersInCol(t.col)) do
                triggerClientEvent(p, "OS:AREA.UpdateAreaDB", p,
                        db.Turf, db.MaxTurf, db.Group, db.TurfGroup, db.OldTurf, db.ID)
                t.ringPlayers[p] = true
        end
        -- hide for players who left
        for p in pairs(t.ringPlayers) do
                if not isElement(p) or not isElementWithinColShape(p, t.col) then
                        if isElement(p) then
                                triggerClientEvent(p, "OS:AREA.HideProgress", p)
                        end
                        t.ringPlayers[p] = nil
                end
        end
end

local function ringHide(t)
        for p in pairs(t.ringPlayers) do
                if isElement(p) then
                        triggerClientEvent(p, "OS:AREA.HideProgress", p)
                end
        end
        t.ringPlayers = {}
end

local function announceFaction(teamName, msg)
        local team = getTeamFromName(teamName)
        if isElement(team) then
                for _, p in ipairs(getPlayersInTeam(team)) do
                        outputChatBox(msg, p, 255, 120, 120, true)
                end
        end
end

-- ---------------------------------------------------------------------------
-- capture tick
-- ---------------------------------------------------------------------------
local function tick()
        for _, t in ipairs(turfs) do
                local db = t.db
                local counts = turfTeamCounts(t.col)
                local ownerCount = db.Group ~= "" and (counts[db.Group] or 0) or 0

                -- strongest attacking faction inside (not the owner)
                local attackerName, attackerCount = nil, 0
                for name, cnt in pairs(counts) do
                        if name ~= db.Group and cnt > attackerCount then
                                attackerName, attackerCount = name, cnt
                        end
                end

                local active = false
                if attackerName and attackerCount > 0 then
                        if ownerCount > 0 then
                                -- contested: flash the radar area, no progress
                                if not t.flashing then
                                        setRadarAreaFlashing(t.area, true)
                                        t.flashing = true
                                end
                                active = true
                        else
                                -- free capture
                                if t.flashing then
                                        setRadarAreaFlashing(t.area, false)
                                        t.flashing = false
                                end
                                db.TurfGroup = attackerName
                                db.Turf = (tonumber(db.Turf) or 0) + ATTACK_RATE
                                if db.Turf >= db.MaxTurf then
                                        -- ownership flip (old bookkeeping)
                                        db.OldTurf = db.Group
                                        db.Group = attackerName
                                        db.Turf = 0
                                        db.TurfGroup = ""
                                        local team = getTeamFromName(attackerName)
                                        if isElement(team) then
                                                local r, g, b = getTeamColor(team)
                                                setRadarAreaColor(t.area, r, g, b, 90)
                                        end
                                        announceFaction(attackerName, "#00FF00تم احتلال منطقة #" .. db.ID .. " باسم فاكشنكم!")
                                        if db.OldTurf ~= "" then
                                                announceFaction(db.OldTurf, "#FF3030فقدتم منطقة #" .. db.ID .. " لصالح " .. attackerName)
                                        end
                                        saveTurfRow(db)
                                end
                                active = true
                        end
                else
                        if t.flashing then
                                setRadarAreaFlashing(t.area, false)
                                t.flashing = false
                        end
                        -- recovery / idle decay
                        if (tonumber(db.Turf) or 0) > 0 then
                                if ownerCount > 0 then
                                        db.Turf = math.max(0, db.Turf - DEFEND_RECOVER)
                                else
                                        db.Turf = math.max(0, db.Turf - IDLE_DECAY)
                                end
                                if db.Turf == 0 then
                                        db.TurfGroup = ""
                                        saveTurfRow(db)
                                end
                        end
                end

                broadcastTurf(t, db)
                if active then
                        ringUpdate(t, db)
                else
                        ringHide(t)
                end
        end
end

-- players entering an already-active turf get the ring instantly
addEventHandler("onColShapeHit", resourceRoot, function(elm, dim)
        if getElementType(elm) ~= "player" or not dim then return end
        for _, t in ipairs(turfs) do
                if t.col == source then
                        local db = t.db
                        if (tonumber(db.Turf) or 0) > 0 then
                                triggerClientEvent(elm, "OS:AREA.ShowProgress", elm, db)
                                t.ringPlayers[elm] = true
                        end
                        return
                end
        end
end)

addEventHandler("onColShapeLeave", resourceRoot, function(elm, dim)
        if getElementType(elm) ~= "player" then return end
        for _, t in ipairs(turfs) do
                if t.col == source and t.ringPlayers[elm] then
                        triggerClientEvent(elm, "OS:AREA.HideProgress", elm)
                        t.ringPlayers[elm] = nil
                        return
                end
        end
end)

addEventHandler("onResourceStart", resourceRoot, function()
        loadTurfs()
        setTimer(tick, TICK, 0)
end)

addEventHandler("onResourceStop", resourceRoot, function()
        for _, t in ipairs(turfs) do
                saveTurfRow(t.db)
        end
end)

-- ---------------------------------------------------------------------------
-- exports
-- ---------------------------------------------------------------------------
function getTurfList()
        return turfs
end

function getTurfByID(id)
        return turfs[tonumber(id)]
end
