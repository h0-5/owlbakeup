--------------------------------------------------------------------------------
-- VORTEX nametags — client (Fix #19)
-- Ported from the old client source (backupm hud drawPlayersName):
--   * Fix #19: NO rank title text above the head — rank is shown only by the
--     admin badge icon (user spec)
--   * name colored by rank, "Unknown Person" for masked players
--   * ((TYPING...)) animated indicator while a player is writing
--   * badge icons above heads (icons/): AFK, admin badge on duty, heart item
--   * 8-unit range + line of sight, tagmode setting respected
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- [Fix #33] 8u was follow-distance only - names were invisible in every
-- normal situation (the user read that as "the feature does not exist").
-- 20u matches how close you actually are when you expect to read a name.
local NAMETAG_DISTANCE = 20

-- [Fix #33] self-diagnostics: any error inside this handler used to kill the
-- draw silently EVERY FRAME (and eat FPS with error logging). Wrap it and
-- surface the first error in chat so it can never hide again.
local nametagErrorShown = false

local playersHud = {}   -- [player] = { name, color, icons, hidden }
local typing = {}       -- [player] = true while chatting
local localTyping = false
-- Fix #23 perf: throttled line-of-sight cache (declared early: cleanup
-- handlers below reference it)
local losCache = {}     -- [player] = { blocked = bool, t = tick }

-- badge textures (old client icons/ set)
local badgeTex = {}

local function loadBadges()
        badgeTex = {}
        local names = { "AFK", "admin_badge", "admin2", "support_badge",
                        "support_badge_2", "developer_badge", "developer_badge2",
                        "heart", "verified", "youtuber", "pro", "booster",
                        "police", "facbadge", "mask", "handcuffs" }
        for _, name in ipairs(names) do
                local path = "icons/" .. name .. ".png"
                if fileExists(path) then
                        badgeTex[name] = dxCreateTexture(path, "dxt5", true, "clamp")
                end
        end
end

-- UIKit fonts (same as old client), with stock fallbacks
local dxFontDefault, dxFontHud

local function UIKitReady()
        local ok, eui = pcall(function() return exports.UIKit end)
        if not ok or not eui then return end
        local function f(name)
                local ok2, v = pcall(function() return eui:getUIFont(name) end)
                return ok2 and v or nil
        end
        dxFontDefault = f("ui-default")
        dxFontHud = f("hud")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

local function fontDefault() return dxFontDefault or "default-bold" end
local function fontHud() return dxFontHud or "default" end

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY)
        -- [Fix #32] old client = 1 black offset shadow + 1 colored pass
        -- (was 5 passes per text per player per frame)
        local black = tocolor(0, 0, 0, 255)
        dxDrawText(text, x + 2, y + 2, x + w + 2, y + h + 2, black, scale, font, alignX, alignY, false, false, true)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, true)
end

--------------------------------------------------------------------------------
-- cache rebuild (old client updatePlayersHud)
--------------------------------------------------------------------------------
local function isOne(v)
        return v == true or v == "1" or tonumber(v) == 1
end

local function localIsStaff()
        local idx = tonumber(getElementData(localPlayer, "rank:index"))
        if idx then return true end
        return (tonumber(getElementData(localPlayer, "admin_level")) or 0) > 0
                or (tonumber(getElementData(localPlayer, "account:gmlevel")) or 0) > 0
end

local function buildPlayerEntry(player)
        -- [Fix #33] robust across every way the server stores these flags
        -- (number 1, DB string "1", boolean true)
        local hidden = isOne(getElementData(player, "hiddenadmin"))
                or getElementData(player, "admin:hideadmin") == true
                or getElementData(player, "admin:hideadmin") == "1"

        local masked = getElementData(player, "fakename")
        local name = masked and "Unknown Person"
                or getPlayerName(player):gsub("_", " ")

        -- staff rank color pushes the name color (Fix #19: no title text)
        local rgb = getElementData(player, "rank:color")
        if type(rgb) ~= "table" or #rgb < 3 then rgb = { 255, 255, 255 } end

        -- friends were colored white in the old client (friend-system guarded)
        local friend = player == localPlayer
        local friendSys = getResourceFromName("friend-system")
        if not friend and friendSys and getResourceState(friendSys) == "running" then
                local ok, isFriend = pcall(function() return exports["friend-system"]:isFriend(player) end)
                if ok then friend = isFriend and true or false end
        end

        -- badge icons above the head (old client icons row)
        local icons = {}
        if getElementData(player, "temp:AFK") then
                table.insert(icons, "AFK")
        end
        if isOne(getElementData(player, "duty_admin"))
                and not isOne(getElementData(player, "admin:hideadmin")) then
                table.insert(icons, "admin_badge")
        end
        -- [Fix #32] supporters get their badge above the head too (F4 supduty)
        if isOne(getElementData(player, "duty_supporter"))
                and not isOne(getElementData(player, "admin:hideadmin")) then
                table.insert(icons, "support_badge")
        end
        if getElementData(player, "temp:heart") then
                table.insert(icons, "heart")
        end
        -- external resources may push extra badges via hud:badges element data
        local extra = getElementData(player, "hud:badges")
        if type(extra) == "table" then
                for _, badgeName in ipairs(extra) do
                        if badgeTex[badgeName] then
                                table.insert(icons, badgeName)
                        end
                end
        end

        return {
                name = name,
                color = tocolor(rgb[1], rgb[2], rgb[3], 255),
                icons = icons,
                hidden = hidden and true or false,
                friend = friend,
        }
end

local function updatePlayersHud()
        playersHud = {}
        for _, player in ipairs(getElementsByType("player")) do
                if isElement(player) and isElementStreamedIn(player) then
                        playersHud[player] = buildPlayerEntry(player)
                end
        end
end

local CACHE_KEYS = {
        ["rank:color"] = true, ["fakename"] = true,
        ["temp:AFK"] = true, ["hiddenadmin"] = true, ["admin:hideadmin"] = true,
        ["character:name"] = true, ["duty_admin"] = true, ["temp:heart"] = true,
        ["hud:badges"] = true,
}
addEventHandler("onClientElementDataChange", root, function(key, _, _value)
        if CACHE_KEYS[key] and isElement(source) and getElementType(source) == "player" then
                if isElementStreamedIn(source) then
                        playersHud[source] = buildPlayerEntry(source)
                end
        end
end)
addEventHandler("onClientElementStreamIn", root, function()
        if getElementType(source) == "player" then
                playersHud[source] = buildPlayerEntry(source)
        end
end)
addEventHandler("onClientElementStreamOut", root, function()
        typing[source] = nil
        playersHud[source] = nil
        losCache[source] = nil
end)
addEventHandler("onClientPlayerQuit", root, function()
        typing[source] = nil
        playersHud[source] = nil
        losCache[source] = nil
end)

--------------------------------------------------------------------------------
-- typing sync (old client: latent server event, server relays to nearby)
--------------------------------------------------------------------------------
local function checkLocalTyping()
        local active = isChatBoxInputActive()
        if active and not localTyping then
                localTyping = true
                triggerLatentServerEvent("typing:sync", 20000, localPlayer, true)
        elseif not active and localTyping then
                localTyping = false
                triggerLatentServerEvent("typing:sync", 20000, localPlayer, false)
        end
end
setTimer(checkLocalTyping, 200, 0)

addEvent("typing:sync", true)
addEventHandler("typing:sync", root, function(state)
        typing[source] = state and true or nil
end)

--------------------------------------------------------------------------------
-- ALT = show IDs (old client: lalt hold / ralt toggle -> local element data
-- "describtion:show"; the name then draws with the player ID in parentheses)
--------------------------------------------------------------------------------
local altSticky = false
bindKey("lalt", "both", function(_, press)
        if not altSticky then
                setElementData(localPlayer, "describtion:show", press == "down", false)
        end
end)
bindKey("ralt", "down", function()
        altSticky = not getElementData(localPlayer, "describtion:show")
        setElementData(localPlayer, "describtion:show", altSticky, false)
end)
addEventHandler("onClientPlayerSpawn", localPlayer, function()
        altSticky = false
        setElementData(localPlayer, "describtion:show", false, false)
end)

--------------------------------------------------------------------------------
-- draw (old client drawPlayersName)
--------------------------------------------------------------------------------
local WaitTyping = 0

addEventHandler("onClientRender", root, function()
        if nametagErrorShown then return end
        local ok, err = pcall(drawNametags)
        if not ok and not nametagErrorShown then
                nametagErrorShown = true
                outputChatBox("[Nametags] " .. tostring(err), 255, 100, 100, false)
        end
end, false, "high-2")

local function isPlayerMapVisibleSafe()
        -- old-client global; guarded so a missing implementation can never
        -- abort the whole draw loop (nil-safe regardless of load order)
        if isPlayerMapVisible and isPlayerMapVisible() then return true end
        return false
end

function drawNametags()
        if isPlayerMapVisibleSafe() then return end
        if not isHudShowing or not isHudShowing() then return end
        if not getHudSetting or getHudSetting("tagmode") == false then return end
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "account:character:id") then return end

        local camX, camY, camZ = getCameraMatrix()
        local lX, lY, lZ = getElementPosition(localPlayer)
        local recon = getElementData(localPlayer, "reconx")  -- hoisted out of the loop
        local now = getTickCount()

        for player, entry in pairs(playersHud) do
                if player ~= localPlayer and isElement(player) and entry
                        and (not entry.hidden or localIsStaff()) then
                        local pX, pY, pZ = getElementPosition(player)
                        local distance = getDistanceBetweenPoints3D(lX, lY, lZ, pX, pY, pZ)
                        if distance <= NAMETAG_DISTANCE then
                                local hx, hy, hz = getPedBonePosition(player, 6)
                                if hx then
                                        local sX, sY = getScreenFromWorldPosition(hx, hy, hz + 0.42)
                                        if sX then
                                                -- line of sight (skip when blocked), recon ignores it
                                                -- Fix #23: throttled to once per 250ms per player
                                                local c = losCache[player]
                                                if not c or now - c.t > 250 then
                                                        c = { blocked = processLineOfSight(camX, camY, camZ,
                                                                        hx, hy, hz + 0.4,
                                                                        true, true, false, true, false, false, false, false),
                                                              t = now }
                                                        losCache[player] = c
                                                end
                                                if not c.blocked or recon then
                                                        local baseY = sY

                                                        -- ((TYPING...)) animated dots (above the title)
                                                        if typing[player] then
                                                                local now = getTickCount()
                                                                if now - WaitTyping > 4000 then
                                                                        WaitTyping = now
                                                                end
                                                                local dots = string.rep(".", math.floor((now - WaitTyping) / 1000) % 4)
                                                                outlineText("((TYPING" .. dots .. "))", sX - 120, baseY - 54, 240, 15,
                                                                        tocolor(255, 255, 255, 255), 0.8, fontHud(), "center", "top")
                                                        end

                                                        -- Fix #19: rank title text removed —
                                                        -- the admin badge below is the only rank marker

                                                        -- the name (Alt = ID in parentheses, old client describtion:show)
                                                        local nameText = entry.name
                                                        if getElementData(localPlayer, "describtion:show") then
                                                                local pid = getElementData(player, "playerid")
                                                                        or getElementData(player, "character:id")
                                                                        or getElementData(player, "account:character:id")
                                                                if pid then
                                                                        nameText = nameText .. " (" .. tostring(pid) .. ")"
                                                                end
                                                        end
                                                        -- [Fix #33] staff viewers keep seeing hidden admins
                                                        -- (with a suffix) exactly like the old client's
                                                        -- admintag view; regular players see nothing
                                                        if entry.hidden then
                                                                nameText = nameText .. " (Hidden)"
                                                        end
                                                        outlineText(nameText, sX - 120, baseY - 22, 240, 18,
                                                                entry.color, 1, fontDefault(), "center", "top")

                                                        -- badge icons under the name (old client icons row)
                                                        if #entry.icons > 0 then
                                                                local iconSize, iconGap = 18, 3
                                                                local rowW = #entry.icons * iconSize + (#entry.icons - 1) * iconGap
                                                                local iconX = sX - rowW / 2
                                                                local iconY = baseY + 4
                                                                for _, icon in ipairs(entry.icons) do
                                                                        local t = badgeTex[icon]
                                                                        if t then
                                                                                dxDrawImage(iconX, iconY, iconSize, iconSize, t, 0, 0, 0,
                                                                                        tocolor(255, 255, 255, 230), true)
                                                                                iconX = iconX + iconSize + iconGap
                                                                        end
                                                                end
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end
end
-- drawNametags ends here; the pcall'd onClientRender handler above is the
-- only registration (Fix #33: one-time error report instead of a silent
-- every-frame abort that also ate FPS)

--------------------------------------------------------------------------------
-- startup
--------------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
        loadBadges()
        updatePlayersHud()
        -- Fix #23: safety rebuild every 2s — entries built from data-change
        -- events alone could go stale (names/badges never showing after a
        -- restart or a missed stream event). Cheap: only streamed players.
        setTimer(updatePlayersHud, 2000, 0)
end)
