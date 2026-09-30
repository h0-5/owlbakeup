--------------------------------------------------------------------------------
-- VORTEX nametags — client (Fix #19)
-- Ported from the old client source (backupm hud drawPlayersName):
--   * Fix #19: NO rank title text above the head — rank is shown only by the
--     admin badge icon (user spec)
--   * name colored by rank, "Unknown Person" for masked players
--   * ((TYPING...)) animated indicator while a player is writing
--   * badge icons above heads (icons/): AFK, admin badge on duty, heart item
--   * 8-unit range + line of sight, tagmode setting respected
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

-- a staff member currently OFF duty reads as a plain player (regular
-- players are never "off duty" - they simply hold no rank)
local function isPlayerOffDutyStaff(p)
        return isPlayerStaff(p) and not isPlayerOnDuty(p)
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

        -- staff rank color pushes the name color (Fix #19: no title text)
        local rgb = getElementData(player, "rank:color")
        if type(rgb) ~= "table" or #rgb < 3 then rgb = { 255, 255, 255 } end
        -- [Fix #75 - user] hidden admins show as PLAIN players above the head:
        -- "لو سويت hide admin ما يرجع لون فوق الشخصية كلاير - يبقى لون الرتبة".
        -- Un-hiding restores the rank color (rgb is re-read every build).
        -- [Fix #98 - user] "لما اسوي hide admin او اطفي الدوتي الاسم يظل بلون
        -- الرتبة": hidden AND off-duty staff both drop to the plain default
        -- player color (white). Only VISIBLE ON-DUTY staff keep rank:color;
        -- plain players were already white (rgb fallback above).
        if hidden or isPlayerOffDutyStaff(player) then rgb = { 255, 255, 255 } end

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
        local icons = {}
        if getElementData(player, "temp:AFK") then
                table.insert(icons, "AFK")
        end
        if isOne(getElementData(player, "duty_admin")) and not hidden then
                table.insert(icons, "admin_badge")
        end
        -- [Fix #32] supporters get their badge above the head too (F4 supduty)
        if isOne(getElementData(player, "duty_supporter")) and not hidden then
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
        ["character:name"] = true, ["duty_admin"] = true, ["duty_supporter"] = true,
        ["temp:heart"] = true, ["hud:badges"] = true,
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
                -- [Fix #89 - user] "الاسم المخفي يطلع بكلمة / يظهر رغم
                -- الإخفاء": the staff half of this gate also matched the
                -- LOCAL player, so after /hideadmin a hidden admin kept
                -- seeing their OWN name above their own head - and that is
                -- the only nametag a single client session can ever show
                -- (the suffix that used to ride along is gone, Fix #98).
                -- Self view is now skipped when the local player is hidden;
                -- staff still see OTHER hidden admins (plain, no marker)
                -- and regular players still see nothing (both unchanged).
                if isElement(player) and entry
                        and (not entry.hidden
                                or (localIsStaff() and player ~= localPlayer)) then
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
                                                        -- [Fix #98 - user] "ما ينكتب بكلمة Hidden جنب الاسم": the
                                                        -- " (Hidden)" suffix is removed for EVERYONE - a hidden admin
                                                        -- now draws as a completely plain player (plain white name,
                                                        -- no marker). The visibility gate above is untouched:
                                                        -- staff still SEE other hidden admins, self view stays skipped.
                                                        -- [Fix #33] before this, hidden admins were only drawn for
                                                        -- staff viewers and always carried the suffix.
                                                        -- [Fix #75 - user] "كبر اسم الشخصية اكثر وكبر الشارة اكثر"
                                                        -- name: scale 1 -> 1.3 (wider centered box for long names)
                                                        outlineText(nameText, sX - 150, baseY - 34, 300, 28,
                                                                entry.color, 1.3, fontDefault(), "center", "top")

                                                        -- badge icons under the name (old client icons row)
                                                        -- [Fix #75] 18px -> 26px (user: "كبر الشارة اكثر")
                                                        if #entry.icons > 0 then
                                                                local iconSize, iconGap = 26, 4
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
