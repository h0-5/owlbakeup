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

local NAMETAG_DISTANCE = 8

local playersHud = {}   -- [player] = { name, color, icons, hidden }
local typing = {}       -- [player] = true while chatting
local localTyping = false

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
        local black = tocolor(0, 0, 0, 255)
        dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY, false, false, true)
        dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY, false, false, true)
        dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY, false, false, true)
        dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY, false, false, true)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, true)
end

--------------------------------------------------------------------------------
-- cache rebuild (old client updatePlayersHud)
--------------------------------------------------------------------------------
local function buildPlayerEntry(player)
        local hidden = getElementData(player, "hiddenadmin") == 1
                or getElementData(player, "admin:hideadmin")

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
        if getElementData(player, "duty_admin") == 1
                and not getElementData(player, "admin:hideadmin") then
                table.insert(icons, "admin_badge")
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
        if typing[source] then typing[source] = nil end
        if playersHud[source] then playersHud[source] = nil end
end)
addEventHandler("onClientPlayerQuit", root, function()
        typing[source] = nil
        playersHud[source] = nil
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
-- draw (old client drawPlayersName)
--------------------------------------------------------------------------------
local WaitTyping = 0

addEventHandler("onClientRender", root, function()
        if isPlayerMapVisible() then return end
        if not isHudShowing or not isHudShowing() then return end
        if not getHudSetting or getHudSetting("tagmode") == false then return end
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "character:id") then return end

        local camX, camY, camZ = getCameraMatrix()
        local lX, lY, lZ = getElementPosition(localPlayer)

        for player, entry in pairs(playersHud) do
                if player ~= localPlayer and isElement(player) and entry and not entry.hidden then
                        local pX, pY, pZ = getElementPosition(player)
                        local distance = getDistanceBetweenPoints3D(lX, lY, lZ, pX, pY, pZ)
                        if distance <= NAMETAG_DISTANCE then
                                local hx, hy, hz = getPedBonePosition(player, 6)
                                if hx then
                                        local sX, sY = getScreenFromWorldPosition(hx, hy, hz + 0.42)
                                        if sX then
                                                -- line of sight (skip when blocked), recon ignores it
                                                local blocked = processLineOfSight(camX, camY, camZ, hx, hy, hz + 0.4,
                                                        true, true, false, true, false, false, false, false)
                                                local recon = getElementData(localPlayer, "reconx")
                                                if not blocked or recon then
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

                                                        -- the name
                                                        outlineText(entry.name, sX - 120, baseY - 22, 240, 18,
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
end, false, "high-2")

--------------------------------------------------------------------------------
-- startup
--------------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
        loadBadges()
        updatePlayersHud()
end)
