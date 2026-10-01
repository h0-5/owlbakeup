--------------------------------------------------------------------------------
-- VORTEX nametags — client (Fix #19)
-- Ported from the old client source (backupm hud drawPlayersName):
--   * Fix #19: NO rank title text above the head — rank is shown only by the
--     admin badge icon (user spec)
--   * name colored by rank, "Unknown Person" for masked players
--   * U1 reviewed by the user: the name is back to the ORIGINAL plain outlined
--     text over the head (NO filled chip / rectangle behind it) and the badge
--     row is back BELOW the name (original 26px icons at baseY+4),
--     admin/developer/support still come from the element data
--     fix160.badgerights (AFK / heart / hud:badges extras unchanged).
--     Name color rule: rank color ONLY for a visible ON-DUTY staff member,
--     white otherwise - and the name NEVER disappears (a hidden admin draws
--     his plain white name like any player; only the badges stay hidden).
--     "TYPING" replaces the old ((TYPING...)) text and chat-system's green
--     logo, and nothing at all is drawn while a menu/window is open
--     (ui:f1open / scoreboard / staff panel / right-click menu / cursor) -
--     but NOT while the cursor is the bare M cursor (Fix #161)
--   * 20-unit range + line of sight, tagmode setting respected
--   * Fix #154: drawn in onClientPreRender so F1 / F3 / /staffs / TAB always
--     cover the tags, and non-friends read the account "mod:id" instead of
--     the name (friends keep the name - see buildPlayerEntry)
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
-- [Fix #47] the old one-time kill-switch was the real "names never show"
-- bug: ONE transient error (e.g. a UIKit restart destroying the font element
-- mid-frame) permanently disabled every player name for the whole session
-- while NPC names (separate file) kept working - exactly the user's report.
-- Errors are now reported at most once per 30s and the draw AUTOMATICALLY
-- recovers on the next frame with fonts revalidated.
local nametagErrorShown = false
local nametagLastError = 0
local nametagErrorCount = 0

local playersHud = {}   -- [player] = { name, color, icons, hidden }
local typing = {}       -- [player] = true while chatting
local localTyping = false
-- Fix #23 perf: throttled line-of-sight cache (declared early: cleanup
-- handlers below reference it)
local losCache = {}     -- [player] = { blocked = bool, t = tick }

-- [Fix #154] the local account's friend ids. nil until the first list
-- arrives, then { [accountId] = true }. buildPlayerEntry reads it, so it is
-- declared up here while the event plumbing lives further down (it has to,
-- since it calls updatePlayersHud).
local friendIds = nil
local friendRowsRequestedAt = 0

-- [Fix #154] self-heal request: only ever fired while friendIds is still nil
-- (hud restarted after login, so the push below was missed) and only once per
-- 5s. It reuses main-menu's read-only Fix #159 list - no change there - and
-- stops the moment an answer lands.
local function requestFriendIds()
        if friendIds then return end
        local now = getTickCount()
        if now - friendRowsRequestedAt < 5000 then return end
        friendRowsRequestedAt = now
        triggerServerEvent("main-menu:friends:list", localPlayer)
end

-- badge textures (old client icons/ set)
local badgeTex = {}

-- [Fix #160 / U1] the three RIGHT-GATED rank badges: their icon names are
-- owned by fix160.badgerights (server pushes the rights, buildPlayerEntry
-- maps them), so a hud:badges entry with one of these names is skipped.
local RANK_BADGE_ICONS = {
        ["admin_badge"] = true,
        ["developer_badge"] = true,
        ["support_badge"] = true,
}

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

local function fontDefault()
        -- [Fix #47] UIKit restarts destroy the exported font elements; drawing
        -- with a dead font element is a per-frame error. Revalidate on use.
        if dxFontDefault and not isElement(dxFontDefault) then dxFontDefault = nil end
        return dxFontDefault or "default-bold"
end
local function fontHud()
        if dxFontHud and not isElement(dxFontHud) then dxFontHud = nil end
        return dxFontHud or "default"
end

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

-- [Fix #47] the Nametag gate accepts every loggedin shape the stack produces
-- (number 1, string "1", boolean true) and BOTH character id keys, matching
-- the ped-system gate so players and NPCs can never disagree again.
local function localIsLoggedIn()
        return isOne(getElementData(localPlayer, "loggedin"))
                or getElementData(localPlayer, "account:character:id") ~= nil
                or getElementData(localPlayer, "character:id") ~= nil
end

local function localIsStaff()
        local idx = tonumber(getElementData(localPlayer, "rank:index"))
        if idx then return true end
        return (tonumber(getElementData(localPlayer, "admin_level")) or 0) > 0
                or (tonumber(getElementData(localPlayer, "account:gmlevel")) or 0) > 0
end

-- [Fix #98] staff/off-duty detection for OTHER players - mirrors the
-- scoreboard trio (c_tab.lua isStaff / isOnDuty / isStaffOffDuty):
-- staff = the 21-rank ladder (rank:index) or an admin/supporter level;
-- on duty = the server-set duty_admin / duty_supporter flags in any shape
-- (number 1, DB string "1", boolean true - same as isOne above).
local function isPlayerStaff(p)
        if tonumber(getElementData(p, "rank:index")) then return true end
        if (tonumber(getElementData(p, "admin_level")) or 0) > 0 then return true end
        if (tonumber(getElementData(p, "supporter_level")) or 0) > 0 then return true end
        return false
end

local function isPlayerOnDuty(p)
        return isOne(getElementData(p, "duty_admin"))
                or isOne(getElementData(p, "duty_supporter"))
end

local function buildPlayerEntry(player)
        -- [Fix #154] if the friend list never arrived (hud restarted after
        -- login), ask main-menu for it before deciding name-vs-id
        if friendIds == nil and localIsLoggedIn() then requestFriendIds() end
        -- [Fix #33] robust across every way the server stores these flags
        -- (number 1, DB string "1", boolean true)
        local hidden = isOne(getElementData(player, "hiddenadmin"))
                or getElementData(player, "admin:hideadmin") == true
                or getElementData(player, "admin:hideadmin") == "1"

        -- [Fix #89 - user] "الاسم المخفي يطلع بكلمة / يظهر رغم الإخفاء":
        -- the ENGINE nametag is drawn by the game itself and never reaches
        -- this file's gate, so it can put a hidden admin's real name over
        -- their head for every viewer (including regular players). MTA's own
        -- stock race/nametags.lua forces it off from the client every frame
        -- for exactly this reason. One call per build is enough; the server
        -- also disables it at spawn (s_characters.lua:491), this client-side
        -- pass makes it impossible for the engine renderer to leak it.
        if hidden and setPlayerNametagShowing then
                setPlayerNametagShowing(player, false)
        end

        local masked = getElementData(player, "fakename")
        local name = masked and "Unknown Person"
                or getPlayerName(player):gsub("_", " ")

        -- [point 2 - user, EXACT name color rules]: WHITE for a normal
        -- player; WHITE when an admin is OFF duty; WHITE while hide-admin is
        -- enabled for him; the RANK COLOR only when the admin is ON duty and
        -- not hidden (Fix #75 / Fix #98 kept - hidden AND off-duty staff read
        -- as plain players above the head; un-hiding / going on duty restores
        -- rank:color, re-read on every build).
        local nameRgb = { 255, 255, 255 }
        if not hidden and isPlayerStaff(player) and isPlayerOnDuty(player) then
                local rgb = getElementData(player, "rank:color")
                if type(rgb) == "table" and #rgb >= 3 then
                        nameRgb = { rgb[1], rgb[2], rgb[3] }
                end
        end

        -- [Fix #154] friends keep the real name, everyone else is read as
        -- their account-bound "mod:id" (the very id /checkid, /changeid and
        -- the TAB board use). Rules kept from the old client: self stays a
        -- friend, a masked player is NEVER swapped (the mask has to keep
        -- hiding them) and a missing id falls back to the name, so no tag can
        -- ever go blank. The old friend-system lookup is gone with this - that
        -- resource does not exist in this server, so it always read false.
        local accountId = tonumber(getElementData(player, "account:id"))
        local friend = player == localPlayer
                or (accountId ~= nil and friendIds ~= nil and friendIds[accountId] == true)
        if not friend and not masked then
                local modId = tonumber(getElementData(player, "mod:id"))
                if modId then name = tostring(modId) end
        end

        -- badge icons above the head (old client icons row)
        -- [Fix #54 - user] "الشارة تختفي لو طفي الدوتي أو hideadmin": the
        -- badge follows duty_admin/duty_supporter AND the REAL hide key the
        -- server uses ("hiddenadmin" 0/1) - the old "admin:hideadmin" check
        -- never matched anything server-side, so hidden admins kept their
        -- badge.
        -- [Fix #160 / U1 task 2] THREE RIGHT-GATED BADGES.
        -- The server (staff_manager_bridge_s.lua pushFix160BadgeRights) pushes
        -- the element data "fix160.badgerights": a comma-separated string of
        -- the badge rights the player's RANK currently holds, e.g.
        -- "admin.badge,admin.badge.developer" (set on login/ready and re-set
        -- after every rank change; "" = a rank that holds none).
        -- RULE (agreed choice, right beats the manual toggle BOTH ways):
        --   * rank holds admin.badge            -> admin_badge
        --   * rank holds admin.badge.developer  -> developer_badge
        --   * rank holds admin.badge.support    -> support_badge
        --   * rank holds none of them           -> no rank badge at all, and
        --     a hud:badges entry pushed by /togdevbadge /togsupportbadge for
        --     those three names is IGNORED (the right decides, never the
        --     toggle; the commands still run, sync and log server-side).
        --   * AFK / heart / every OTHER hud:badges entry is untouched.
        -- Keep-working rules kept from Fix #54 / Fix #98: hidden admins and
        -- off-duty staff draw NO badge (they read as plain players, which is
        -- also what the scoreboard column does).
        -- Legacy fallback: while the key is still missing (admin-system not
        -- reloaded yet) the old duty + hud:badges behaviour is kept 1:1 so a
        -- live server never loses its badges.
        local badgeRights = nil
        local rawRights = getElementData(player, "fix160.badgerights")
        if rawRights ~= nil then
                badgeRights = {}
                if type(rawRights) == "table" then
                        for _, token in ipairs(rawRights) do
                                badgeRights[tostring(token):match("^%s*(.-)%s*$")] = true
                        end
                elseif type(rawRights) == "string" then
                        for token in string.gmatch(rawRights, "[^,]+") do
                                badgeRights[token:match("^%s*(.-)%s*$")] = true
                        end
                end
        end

        local icons = {}
        if getElementData(player, "temp:AFK") then
                table.insert(icons, "AFK")
        end
        if not hidden and isPlayerOnDuty(player) then
                if badgeRights == nil then
                        -- legacy path (server has not pushed the key yet)
                        if isOne(getElementData(player, "duty_admin")) then
                                table.insert(icons, "admin_badge")
                        end
                        -- [Fix #32] supporters get their badge above the head too (F4 supduty)
                        if isOne(getElementData(player, "duty_supporter")) then
                                table.insert(icons, "support_badge")
                        end
                else
                        -- AllRights order: admin, developer, support
                        if badgeRights["admin.badge"] then
                                table.insert(icons, "admin_badge")
                        end
                        if badgeRights["admin.badge.developer"] then
                                table.insert(icons, "developer_badge")
                        end
                        if badgeRights["admin.badge.support"] then
                                table.insert(icons, "support_badge")
                        end
                end
        end
        if getElementData(player, "temp:heart") then
                table.insert(icons, "heart")
        end
        -- external resources may push extra badges via hud:badges element data
        local extra = getElementData(player, "hud:badges")
        if type(extra) == "table" then
                for _, badgeName in ipairs(extra) do
                        -- [Fix #160 / U1] once the server pushes the rights the
                        -- three RANK badge names no longer come from hud:badges
                        -- (the right alone decides); every other badge does.
                        if badgeTex[badgeName]
                                and (badgeRights == nil or not RANK_BADGE_ICONS[badgeName]) then
                                table.insert(icons, badgeName)
                        end
                end
        end

        return {
                name = name,
                -- [point 2] nameColor = the RANK color only for a visible
                -- on-duty staff member, else plain white {255,255,255};
                -- `color` is the same value packed for the outlineText call
                nameColor = nameRgb,
                color = tocolor(nameRgb[1], nameRgb[2], nameRgb[3], 255),
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
        ["character:name"] = true, ["duty_admin"] = true, ["duty_supporter"] = true,
        ["temp:heart"] = true, ["hud:badges"] = true,
        -- [Fix #160 / U1] the rank's badge rights: an edit / rank change must
        -- rebuild the entry on the same frame (not 2s later)
        ["fix160.badgerights"] = true,
        -- [Fix #98] staff detection reads these too (rank ladder / levels) -
        -- a rank push must re-evaluate the off-duty plain-white color now
        ["rank:index"] = true, ["admin_level"] = true, ["supporter_level"] = true,
        -- [Fix #154] the tag text itself: a /setid or a login-time account
        -- assignment has to rebuild the entry (name vs mod:id), and the
        -- friend match keys on account:id
        ["mod:id"] = true, ["account:id"] = true,
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
-- [Fix #154] friend list -> who still reads as a NAME above their head
--------------------------------------------------------------------------------
local function setFriendIds(list, idIndex)
        local set = {}
        if type(list) == "table" then
                for _, row in ipairs(list) do
                        -- rows arrive with mixed shapes/types (social-system
                        -- pushes raw DB values), so always compare as numbers
                        local id = tonumber(type(row) == "table" and row[idIndex] or nil)
                        if id then set[id] = true end
                end
        end
        friendIds = set
        updatePlayersHud()
end

-- social-system sends the whole list to this client at login and again on
-- every friend add/accept (s_friends.lua: sendFriends -> "social:friends",
-- source = the player).
-- [Fix #154] both events are declared by OTHER resources, and MTA refuses
-- addEventHandler() until that declaration exists: it checks CEvents::Exists
-- first and just RETURNS FALSE (CStaticFunctionDefinitions::AddEventHandler),
-- no error, no handler. hud starts before social-system and main-menu (it is
-- far earlier in mtaserver.conf), so the attach is retried until it sticks -
-- the login push and every friends fetch arrive well after that, so nothing
-- is ever missed.
local socialFriendsAttached = false
local friendCallbackAttached = false

local function attachFriendHandlers()
        if not socialFriendsAttached then
                -- rows: { accountID, username, message, player-or-lastOnline }
                socialFriendsAttached = addEventHandler("social:friends", localPlayer, function(friendsList)
                        setFriendIds(friendsList, 1)
                end) == true
        end
        if not friendCallbackAttached then
                -- main-menu's Fix #159 list, rows are { id = accountId, ... }:
                -- requestFriendIds above asks for it while friendIds is nil,
                -- and it also sees F1's own refreshes, which keeps the set
                -- honest after an unfriend.
                friendCallbackAttached = addEventHandler("main-menu:friends:list:callback", localPlayer, function(rows)
                        setFriendIds(rows, "id")
                end) == true
        end
        return socialFriendsAttached and friendCallbackAttached
end

if not attachFriendHandlers() then
        local attachTries = 0
        local attachTimer
        attachTimer = setTimer(function()
                attachTries = attachTries + 1
                if attachFriendHandlers() or attachTries >= 120 then
                        if isTimer(attachTimer) then killTimer(attachTimer) end
                end
        end, 1000, 0)
end

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

-- [Fix #47] instant self-heal: if the entry cache is empty while other
-- players ARE streamed in, rebuild it right now instead of waiting for the
-- 2s timer (missed stream events used to leave names blank for seconds)
local function cacheLooksBroken()
        if next(playersHud) ~= nil then return false end
        for _, p in ipairs(getElementsByType("player", root, true)) do
                if p ~= localPlayer then return true end
        end
        return false
end

-- [Fix #154] Drawn from onClientPreRender, NOT onClientRender, keeping the
-- "high-2" band. MTA walks its handler list from HIGH to LOW
-- (CMapEventManager::AddInternal inserts the higher priority first and Call()
-- iterates that order), and dx is only ORDERED by WHEN it is issued - so the
-- pass that issues a draw first is the pass that ends up at the BOTTOM:
--   * F1 (chrome veil "high-2" + its UIKit window), F3 and /staffs (UIKit
--     windows at "normal") all draw in onClientRender: every one of them now
--     issues AFTER this pass and therefore covers the tags. Before, this
--     handler TIED with F1's chrome at "high-2" and only stayed underneath
--     while hud happened to be the older of the two registrations - a hud
--     restart with F1 open flipped the stacking.
--   * the TAB board draws in THIS very event at "normal" (scoreboard
--     c_tab.lua, Fix #31), so "high-2" keeps the tags first inside the pass
--     and under the board - that was the one menu nametags provably covered.
-- postGUI=true is untouched: the tags still land over the 3D world, the
-- radar, the chatbox and every pre-GUI layer, and Fix #100 / #151, the radar
-- band and the HUD bands are NOT touched - only menu stacking changes.
addEventHandler("onClientPreRender", root, function()
        local ok, err = pcall(drawNametags)
        if not ok then
                -- [Fix #47] report once per 30s, keep drawing (auto-recover)
                local now = getTickCount()
                nametagErrorCount = nametagErrorCount + 1
                if now - nametagLastError > 30000 then
                        nametagLastError = now
                        outputChatBox("[Nametags] " .. tostring(err)
                                .. " (recovered, errors so far: " .. nametagErrorCount .. ")", 255, 100, 100, false)
                end
        end
end, false, "high-2")

local function isPlayerMapVisibleSafe()
        -- old-client global; guarded so a missing implementation can never
        -- abort the whole draw loop (nil-safe regardless of load order)
        if isPlayerMapVisible and isPlayerMapVisible() then return true end
        return false
end

-- [Fix #35] one-time-per-session gate reports: "names never appear" was
-- un-diagnosable because every gate was a silent return. Now the FIRST time
-- a gate blocks, the player is told exactly why (once, no spam).
local gateReported = {}
local function gateReport(reason)
        if gateReported[reason] then return end
        gateReported[reason] = true
        outputChatBox("[Nametags] names are hidden because: " .. reason, 255, 220, 120, false)
end

-- [U1 task 4] while ANY menu/window is open the world under it must be
-- clean - names + badges + the TYPING word all stop drawing.
-- Signals that exist today (read-only, nothing owned by other agents is
-- touched):
--   1. ui:f1open on localPlayer  - the F1 menu contract pushed by agent U6
--      (accepted shapes: true / "true" / 1 / "1")
--   2. exports.scoreboard:isVisible()  - the TAB board (scoreboard/c_tab.lua)
--   3. exports["main-menu"]:isOpen()   - the F1/F2 sidebar (main-menu/c_main.lua,
--      same menu the key above reports, kept for older/newer U6 builds)
--   4. staffPanelOpen - the staff panel (/staffs, /managepanel), mirrored
--      from its single open/close funnel rpadmin:showPanel below
--   5. exports.interaction:isInteractionOptionsShowing() - the right-click
--      interaction menu, and ONLY while it actually has rows to draw (the
--      menu self-destructs in menuRender whenever the cursor drops, so it
--      can never exist outside the cursor case anyway)
--   6. isCursorShowing() (but NOT while the chatbox is focused, and NOT
--      while it is the bare M cursor - Fix #161) - the generic local
--      fallback for the windows nobody publishes state for: the item-system
--      book windows and every UIKit dialog all call showCursor(true) while
--      open and showCursor(false) when they close, and normal gameplay (chat
--      input, driving, aiming) never holds the cursor.
-- NOT DETECTABLE from here (reported, not implemented): a UIKit window that
-- opens without showCursor - UIKit exports no "any window visible" query and
-- its UI table is private to that resource.
-- (plain functions, not inline closures: this runs every frame)

-- [Fix #161] "اظهار لموشر ماوس بـ m" hid every name + badge: M only shows
-- the BARE cursor (interaction/c_interaction.lua:52 showCursor toggle and
-- social-system/c_old_friends.lua:47 /togglecursor - NEITHER opens a window),
-- but gate 6 above read any isCursorShowing() as "a menu is open", so the
-- tags vanished with the cursor. The cursor that appears within 500ms of an
-- M press is now tracked as the BARE cursor and skips gate 6; every cursor a
-- window shows on its own has no M press behind it, so F1, TAB, the staff
-- panel, the main-menu sidebar and every dialog still hide exactly as before.
local mKeyTick = 0          -- tick of the last M /togglecursor press
local bareCursor = false    -- true while the cursor M showed is still up
local cursorWasShowing = false
-- staff panel mirror: staff_manager_c.lua:799-800 toggles the window AND
-- showCursor together from the one rpadmin:showPanel funnel (and every close
-- path - the event itself or the Close button - drops the cursor), so the
-- flag is cleared the moment the cursor goes down and cannot stick.
local staffPanelOpen = false

local function noteBareCursorKey()
        mKeyTick = getTickCount()
end
bindKey("m", "down", noteBareCursorKey)
addCommandHandler("togglecursor", noteBareCursorKey)

setTimer(function()
        local showing = isCursorShowing()
        if not showing then
                -- cursor down = no window gate left standing (the staff
                -- panel always holds the cursor while it is open)
                staffPanelOpen = false
                bareCursor = false
                cursorWasShowing = false
                return
        end
        if not cursorWasShowing then
                cursorWasShowing = true
                -- a SHOW only counts as the bare M cursor when an M press
                -- caused it; a window showing its own cursor -> menu
                bareCursor = mKeyTick > 0
                        and getTickCount() - mKeyTick <= 500
        end
end, 100, 0)

-- rpadmin:showPanel is DECLARED by admin-system, which starts AFTER hud in
-- mtaserver.conf, so addEventHandler returns false until that declaration
-- exists (same CEvents::Exists rule the friend handlers above retry against).
local staffPanelAttached = false
local function attachStaffPanelHandler()
        if staffPanelAttached then return true end
        staffPanelAttached = addEventHandler("rpadmin:showPanel", root, function()
                staffPanelOpen = not staffPanelOpen
        end) == true
        return staffPanelAttached
end
if not attachStaffPanelHandler() then
        local staffAttachTries = 0
        local staffAttachTimer
        staffAttachTimer = setTimer(function()
                staffAttachTries = staffAttachTries + 1
                if attachStaffPanelHandler() or staffAttachTries >= 120 then
                        if isTimer(staffAttachTimer) then killTimer(staffAttachTimer) end
                end
        end, 1000, 0)
end

local function scoreboardVisible()
        return exports.scoreboard:isVisible()
end
local function mainMenuOpen()
        return exports["main-menu"]:isOpen()
end
local function interactionMenuRows()
        return exports.interaction:isInteractionOptionsShowing()
end

local function menuCoversWorld()
        local f1 = getElementData(localPlayer, "ui:f1open")
        if f1 == true or f1 == "true" or isOne(f1) then return true end

        local ok, vis = pcall(scoreboardVisible)
        if ok and vis then return true end

        local ok2, open = pcall(mainMenuOpen)
        if ok2 and open then return true end

        -- [Fix #161] gates 4 + 5: the staff panel and the right-click menu
        -- cause no cursor transition of their own while the bare M cursor is
        -- already up, so they carry their own state here
        if staffPanelOpen then return true end

        local ok3, rows = pcall(interactionMenuRows)
        if ok3 and type(rows) == "table" and #rows > 0 then return true end

        -- [Fix #161] gate 6: the cursor covers the world UNLESS it is the
        -- bare M cursor with no window behind it
        if isCursorShowing() and not bareCursor and not isChatBoxInputActive() then return true end

        return false
end

function drawNametags()
        if isPlayerMapVisibleSafe() then return end
        if not isHudShowing or not isHudShowing() then
                gateReport("the HUD is hidden (F4 > showhud is off)")
                return
        end
        if not getHudSetting or getHudSetting("tagmode") == false then
                gateReport("tagmode is off")
                return
        end
        -- [Fix #47] robust gate (1 / "1" / true, both id keys) - was
        -- `loggedin ~= 1 and not account:character:id` which dead-ended on
        -- every non-number loggedin shape and never accepted character:id
        if not localIsLoggedIn() then
                gateReport("waiting for character select (loggedin="
                        .. tostring(getElementData(localPlayer, "loggedin")) .. ")")
                return
        end
        -- [U1 task 4] a menu/window is open -> draw nothing at all (the old
        -- stacking only buried the tags UNDER the window, they still showed
        -- around its edges and through the transparent parts)
        if menuCoversWorld() then
                gateReport("a menu / window is open (F1, TAB, staff panel, ...)")
                return
        end

        local camX, camY, camZ = getCameraMatrix()
        local lX, lY, lZ = getElementPosition(localPlayer)
        local recon = getElementData(localPlayer, "reconx")  -- hoisted out of the loop
        local now = getTickCount()

        -- [Fix #47] self-heal: empty cache while other players are streamed in
        if cacheLooksBroken() then updatePlayersHud() end

        for player, entry in pairs(playersHud) do
                -- [Fix #71] the old client draws EVERY streamed player INCLUDING
                -- localPlayer (its loop tests `== localPlayer` for the heart
                -- cooldown). The `player ~= localPlayer` skip meant a session
                -- with a single client (the only case ever connected here) drew
                -- ZERO names — exactly the user's "nametags don't show" report.
                -- [point 3 - user] THE NAME NEVER DISAPPEARS: the old
                -- `entry.hidden` half of this gate is gone - a hidden admin now
                -- draws his plain WHITE name like a normal player (for others
                -- AND for himself); only the BADGES stay off for hidden /
                -- off-duty staff, that gate lives in buildPlayerEntry. The
                -- ENGINE nametag is still force-disabled above (Fix #89), so
                -- MTA's own renderer can never leak the real name either.
                if isElement(player) and entry then
                        local pX, pY, pZ = getElementPosition(player)
                        local distance = getDistanceBetweenPoints3D(lX, lY, lZ, pX, pY, pZ)
                        if distance <= NAMETAG_DISTANCE then
                                -- [Fix #71] bone 8 (head) — matches the old client
                                -- (var8(player, 8)) and the WORKING NPC renderer
                                -- (c_ped_names.lua:120). Bone 6 is the neck and sat
                                -- too low, so the +0.42 lift floated the tag oddly.
                                local hx, hy, hz = getPedBonePosition(player, 8)
                                if hx then
                                        -- [Fix #75 - user] "كبر اسم الشخصية فوق اللاعب اكثر":
                                        -- anchor slightly higher to fit the bigger text+badge
                                        local sX, sY = getScreenFromWorldPosition(hx, hy, hz + 0.30)
                                        if sX then
                                                -- line of sight (skip when blocked), recon ignores it
                                                -- Fix #23: throttled to once per 250ms per player
                                                local c = losCache[player]
                                                if not c or now - c.t > 250 then
                                                        -- [Fix #71] vehicles=false — a passing/car target used to
                                                        -- hide the name (false blocked). The WORKING NPC renderer
                                                        -- (c_ped_names.lua:131) clears LOS with vehicles=false too.
                                                        c = { blocked = processLineOfSight(camX, camY, camZ,
                                                                        hx, hy, hz + 0.30,
                                                                        true, false, false, true, false, false, false, false),
                                                              t = now }
                                                        losCache[player] = c
                                                end
                                                if not c.blocked or recon then
                                                        local baseY = sY

                                                        -- Fix #19: rank title text removed -
                                                        -- [point 1 - user] the name is the ORIGINAL plain
                                                        -- outlined text again (the filled rank-color chip
                                                        -- is gone), the badge row is back BELOW the name
                                                        -- (point 4) and the typing indicator stays ABOVE
                                                        -- the name (U1 task 3: the word TYPING replaced
                                                        -- the old ((TYPING...)) text and the green
                                                        -- chat.png logo of chat-system)

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
                                                        -- [Fix #98 - user] "ما ينكتب بكلمة Hidden جنب الاسم": the
                                                        -- " (Hidden)" suffix is removed for EVERYONE - a hidden admin
                                                        -- now draws as a completely plain player (plain white name,
                                                        -- no marker, and the name itself is always drawn - point 3).
                                                        -- [Fix #33] before this, hidden admins were only drawn for
                                                        -- staff viewers and always carried the suffix.
                                                        -- [Fix #75 - user] "كبر اسم الشخصية اكثر وكبر الشارة اكثر"
                                                        -- name: scale 1 -> 1.3 (wider centered box for long names)
                                                        -- [U1 task 1 - kept] distance scaling: the text and the
                                                        -- badge icons keep their full size up close and shrink
                                                        -- gently as the target walks away, so they stay readable
                                                        -- out to the NAMETAG_DISTANCE cut-off; the layout itself
                                                        -- is the original plain one.
                                                        local rowScale = 1
                                                        if distance > 8 then
                                                                rowScale = math.max(0.75,
                                                                        1 - (distance - 8) / (NAMETAG_DISTANCE - 8) * 0.25)
                                                        end

                                                        local font = fontDefault()

                                                        -- [point 1] the name: plain outlined text at the ORIGINAL
                                                        -- spot - a 300x28 box centred on the head with its top
                                                        -- edge at baseY-34, NO rectangle behind it. entry.color
                                                        -- carries the point-2 rule (rank color only for a visible
                                                        -- ON-DUTY staff member, white for everyone else).
                                                        outlineText(nameText, sX - 150, baseY - 34, 300, 28,
                                                                entry.color, 1.3 * rowScale, font, "center", "top")

                                                        -- only icons whose texture actually loaded
                                                        local drawable = {}
                                                        for _, icon in ipairs(entry.icons) do
                                                                if badgeTex[icon] then
                                                                        drawable[#drawable + 1] = icon
                                                                end
                                                        end

                                                        -- [point 4] the badge row is back BELOW the name / above
                                                        -- the head: original 26px icons in a horizontally centred
                                                        -- row at baseY+4 (admin/developer/support come from
                                                        -- fix160.badgerights; AFK / heart / hud:badges unchanged)
                                                        if #drawable > 0 then
                                                                local iconSize = 26 * rowScale
                                                                local gap = 4 * rowScale
                                                                local rowW = #drawable * iconSize
                                                                        + (#drawable - 1) * gap
                                                                local iconX = sX - rowW / 2
                                                                local iconY = baseY + 4
                                                                for _, icon in ipairs(drawable) do
                                                                        dxDrawImage(iconX, iconY, iconSize, iconSize,
                                                                                badgeTex[icon], 0, 0, 0,
                                                                                tocolor(255, 255, 255, 240), true)
                                                                        iconX = iconX + iconSize + gap
                                                                end
                                                        end

                                                        -- [U1 task 3 - kept] typing indicator: the word TYPING
                                                        -- right above the restored name box (chat-system's green
                                                        -- logo no longer draws; its chat1/chat0 state sync still runs)
                                                        if typing[player] then
                                                                local tnow = getTickCount()
                                                                if tnow - WaitTyping > 4000 then
                                                                        WaitTyping = tnow
                                                                end
                                                                local dots = string.rep(".",
                                                                        math.floor((tnow - WaitTyping) / 1000) % 4)
                                                                outlineText("TYPING" .. dots, sX - 120,
                                                                        baseY - 34 - 18, 240, 16,
                                                                        tocolor(255, 255, 255, 255), 0.9 * rowScale,
                                                                        fontHud(), "center", "bottom")
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end
end
-- drawNametags ends here; the pcall'd onClientPreRender handler above is the
-- only registration (Fix #33: one-time error report instead of a silent
-- every-frame abort that also ate FPS; Fix #154 moved it out of
-- onClientRender so the menus always cover the tags)

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
