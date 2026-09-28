--[[ =========================================================================
        c_characters.lua — Vortex CHARACTER LOBBY (Fix #40, MOD 3 part 2)

        1:1 UIKit port of the OLD CLIENT character selection
        (backupm roleplay character_c_decompiled.lua):

          * midnight lobby scene on 4 random camera matrices (dim 65499,
            localPlayer hidden), dark bg_gradient + Vortex logo alpha 200
          * top tab row with animated circle indicator:
            CHARACTERS / CREATE CHARACTER / LATEST NEWS / HISTORY /
            RESET PASSWORD (hover = select.wav like the old client)
          * horizontal character name list under the tabs; the selected name
            is white with an animated underline; "N/max" top-right
          * the selected character stands in front of the camera with a random
            idle animation (dead characters get the graveyard loop)
          * right-side 250x500 info window (#ID / name + details) with
            "Remove Character" (dead characters only -> soft delete)
          * big PLAY button bottom-centre (HoverGlow -> primary text)
          * LATEST NEWS reads the account resourceRoot news:* element data
          * local toasts (notifications resource does not exist here)
          * account username drawn top-right

        SERVER CONTRACT UNCHANGED:
          reads   elementData "account:characters" (array v1..v15, s_characters)
          events  accounts:characters:spawn (existing flow, c_login triggers)
                  updateCharacters (refresh list)
          NEW (safe, opt-in): accounts:characters:remove -> soft delete
                  (only allowed for cked=1 characters, s_characters.lua)
========================================================================= ]]

local sx, sy = guiGetScreenSize()
local s = sy / 1080
local localPlayer = getLocalPlayer()
local eui = exports.UIKit

local REF_SX, REF_SY = (function()
        -- [Fix #52] top-level UIKit call died if UIKit had not started yet,
        -- killing this whole script (selection screen never registered).
        local ok, x, y = pcall(function() return eui:uiGetReferenceScreenSize() end)
        if ok and tonumber(x) then return tonumber(x), tonumber(y) end
        return 1728, 972
end)()

-- the four old-client lobby camera spots {x, y, z, rotation}
local CAM_SPOTS = {
        { 706.1298, -1690.823, 3.4375, 180 },
        { 1096.57, -2238.263, 49.3593, 226.21467590332 },
        { 1025.306, -2195.153, 39.1406, 112.47149658203 },
        { 2531.5, -1666.171, 15.1677, 117.15173339844 },
}
local CAMERA_DISTANCE = 4.4

lobby = {
        character = false,
        section = false,
        selection_status = false,
        selectedCharacter = 1,
        selectedID = false,
        maxCharacters = 3,
        account = "None",
        currentCharacters = {},
        showPed = false,
        tabs = {
                { id = 1, text = "CHARACTERS" },
                { id = 2, text = "CREATE CHARACTER" },
                { id = 3, text = "LATEST NEWS" },
                { id = 4, text = "HISTORY" },
                { id = 5, text = "RESET PASSWORD" },
        },
        tab_width = {},
        topBarHeight = 50,
        cam = { pos = false, target = false, from = false, to = false, count = 0 },
        selectAnim = { tick = 0, fromX = 0, fromW = 0 },
        hoverTab = false,
        nameRects = {},
        tabRects = {},
        profilePic = false,
}

for i, tab in ipairs(lobby.tabs) do
        lobby.tab_width[i] = dxGetTextWidth(tab.text, 1.2 * s, "default-bold") + 50 * s
end

local UI = { window = {}, label = {}, button = {}, memo = {} }
local built = false
local music = nil
local fadeTimer = nil
local toastData = { text = false, r = 255, g = 255, b = 255, tick = 0, life = 0 }
local directiveText = false
local BG_TEXTURE = ":assets/images/bg_gradient.png"

-- ===========================================================================
-- small local helpers
-- ===========================================================================

local function isMouseInPosition(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        if not cx then return false end
        cx, cy = cx * sx, cy * sy
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function anim(tick, duration, fromX, fromW, toX, toW)
        local elapsed = getTickCount() - tick
        if elapsed >= duration then return toX, toW end
        return interpolateBetween(fromX, fromW, 0, toX, toW, 0, elapsed / duration, "Linear")
end

function lobbyToast(text, kind)
        local r, g, b = 255, 255, 255
        if kind == "error" then
                r, g, b = 255, 82, 110
        elseif kind == "success" then
                r, g, b = 90, 220, 140
        elseif kind == "info" then
                r, g, b = 120, 190, 255
        end
        toastData = { text = tostring(text), r = r, g = g, b = b, tick = getTickCount(), life = 5000 }
end

function showDirective(text)
        directiveText = text
end

local function startLobbyMusic()
        if isElement(music) then return end
        music = playSound("menu.mp3", true)
        if isElement(music) then
                setSoundVolume(music, 0.45)
                setElementData(localPlayer, "bgMusic", music, false)
        end
end

function stopLobbyMusic()
        if isElement(music) then
                if isTimer(fadeTimer) then killTimer(fadeTimer) end
                local theMusic = music
                fadeTimer = setTimer(function()
                        if not isElement(theMusic) then return end
                        local v = getSoundVolume(theMusic)
                        setSoundVolume(theMusic, v - 0.1)
                        if v - 0.1 <= 0 then destroyElement(theMusic) end
                end, 400, 10)
        end
        if getElementData(localPlayer, "bgMusic") then
                setElementData(localPlayer, "bgMusic", nil, false)
        end
        music = nil
end

local function getCamPoint(spot)
        -- camera floats in FRONT of the ped so the face is visible (old client)
        local rad = math.rad(spot[4])
        local px = spot[1] + math.sin(rad) * CAMERA_DISTANCE
        local py = spot[2] + math.cos(rad) * CAMERA_DISTANCE
        return px, py, spot[3] + 0.6
end

-- ===========================================================================
-- UIKit build
-- ===========================================================================

local function buildUI()
        if built then return end
        -- [Fix #48] the flag moves to the END of the function: a mid-build
        -- error must leave built=false so Characters_showSelection can retry

        -- character info window (right side, 250x500)
        UI.window.CharacterInfo = eui:uiCreateRectangle(REF_SX - 300, false, 250, 500, "bg_default", true, true, true, true)
        eui:uiSetVisible(UI.window.CharacterInfo, false)
        eui:uiCreateRectangle(62.5, 0, 125, 5, "primary", false, false, false, false, UI.window.CharacterInfo)
        eui:uiCreateRectangle(62.5, 495, 125, 5, "primary", false, false, false, false, UI.window.CharacterInfo)
        UI.label.CharacterInfo_1 = eui:uiCreateLabel(10, 15, 230, 60, "", tocolor(255, 255, 255, 240), "left", "top", UI.window.CharacterInfo)
        eui:uiSetFont(UI.label.CharacterInfo_1, "default-large")
        UI.label.CharacterInfo_2 = eui:uiCreateLabel(10, 85, 230, 340, "", tocolor(255, 255, 255, 240), "left", "top", UI.window.CharacterInfo)
        eui:uiSetProperty(UI.label.CharacterInfo_2, "word_break", true)
        UI.button.RemoveCharacter = eui:uiCreateButton(10, 450, 230, 35, { en = "Remove Character", ar = "حذف الشخصية" }, _, UI.window.CharacterInfo)

        -- play button (bottom-centre)
        UI.button.Play = eui:uiCreateButton((REF_SX - 200) / 2, REF_SY - 60, 200, 50, "Play", "primary")
        eui:uiSetFont(UI.button.Play, "hud-large")
        eui:uiSetProperty(UI.button.Play, "HoverGlow", true)
        eui:uiSetProperty(UI.button.Play, "HoverTextColor", eui:uiGetThemeColor("primary"))
        eui:uiSetVisible(UI.button.Play, false)

        -- latest news window
        UI.window.News = eui:uiCreateRectangle((REF_SX - 500) / 2, (REF_SY - 360) / 2, 500, 360, tocolor(20, 20, 20, 230), true, true, true, true)
        eui:uiSetVisible(UI.window.News, false)
        UI.label.NewsTitle = eui:uiCreateLabel(15, 10, 470, 30, "Latest News", tocolor(255, 255, 255, 255), "left", "top", UI.window.News)
        eui:uiSetFont(UI.label.NewsTitle, "default-large")
        UI.label.NewsText = eui:uiCreateLabel(15, 50, 470, 250, "", tocolor(255, 255, 255, 220), "left", "top", UI.window.News)
        eui:uiSetProperty(UI.label.NewsText, "word_break", true)
        UI.label.NewsSub = eui:uiCreateLabel(15, 310, 470, 20, "", tocolor(255, 255, 255, 140), "left", "top", UI.window.News)
        UI.button.CloseNews = eui:uiCreateButton(15, 320, 470, 30, { en = "Hide", ar = "إخفاء" }, tocolor(0, 0, 0, 255), UI.window.News)

        -- history window
        UI.window.History = eui:uiCreateRectangle((REF_SX - 500) / 2, (REF_SY - 360) / 2, 500, 360, tocolor(20, 20, 20, 230), true, true, true, true)
        eui:uiSetVisible(UI.window.History, false)
        UI.label.HistoryTitle = eui:uiCreateLabel(15, 10, 470, 30, "History", tocolor(255, 255, 255, 255), "left", "top", UI.window.History)
        eui:uiSetFont(UI.label.HistoryTitle, "default-large")
        UI.label.HistoryText = eui:uiCreateLabel(15, 50, 470, 250, "", tocolor(255, 255, 255, 220), "left", "top", UI.window.History)
        eui:uiSetProperty(UI.label.HistoryText, "word_break", true)
        UI.button.CloseHistory = eui:uiCreateButton(15, 320, 470, 30, { en = "Hide", ar = "إخفاء" }, tocolor(0, 0, 0, 255), UI.window.History)
        -- [Fix #48] built flips true only AFTER the whole build succeeds, so a
        -- mid-build error (UIKit restart race) leaves it false and the retry
        -- in Characters_showSelection can actually rebuild
        built = true
end

-- ===========================================================================
-- info window content (old-client layout: bullets + primary color)
-- ===========================================================================

local PRIMARY_HEX = "#ff375f"

local function genderText(gender)
        return gender == 1 and "انثى" or "ذكر"
end

local function monthName(month)
        local names = { "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December" }
        return names[tonumber(month) or 1] or "January"
end

local function lastSeenText(days)
        days = tonumber(days) or 0
        if days <= 0 then return "اليوم" end
        return "قبل " .. days .. (days == 1 and " يوم" or " يوم")
end

local function refreshCharacterDetails()
        local char = lobby.currentCharacters[lobby.selectedCharacter]
        if not char then return end
        local info = "#" .. tostring(char[1]) .. "\n" .. tostring(char[2] or ""):gsub("_", " ")

        local status = (tonumber(char[3]) == 1) and "#FF0000ميت" or "#00FF00على قيد الحياة"
        local details = ""
                .. PRIMARY_HEX .. " • الجنس » #FFFFFF" .. genderText(char[6]) .. "\n"
                .. PRIMARY_HEX .. " • العمر » #FFFFFF" .. tostring(char[5] or "?") .. "\n"
                .. PRIMARY_HEX .. " • تاريخ الميلاد » #FFFFFF" .. monthName(char[13]) .. " " .. tostring(char[14] or "?") .. "\n"
                .. PRIMARY_HEX .. " • الوزن » #FFFFFF" .. tostring(char[11] or "?") .. " kg\n"
                .. PRIMARY_HEX .. " • الطول » #FFFFFF" .. tostring(char[12] or "?") .. " cm\n"
                .. "\n"
                .. PRIMARY_HEX .. " • الوظيفة » #FFFFFF" .. (char[7] and (tostring(char[8] or "") .. " - " .. tostring(char[7])) or "مواطن") .. "\n"
                .. "\n"
                .. PRIMARY_HEX .. " • الحالة » " .. status .. "\n"
                .. PRIMARY_HEX .. " • آخر ظهور » #FFFFFF" .. lastSeenText(char[10]) .. "\n"
                .. "     " .. tostring(char[4] or "?")

        eui:uiSetText(UI.label.CharacterInfo_1, info)
        eui:uiSetText(UI.label.CharacterInfo_2, details)
        eui:uiSetProperty(UI.label.CharacterInfo_2, "color_coded", true)
end

local function applyPedForCharacter()
        local char = lobby.currentCharacters[lobby.selectedCharacter]
        if not char then return end
        local model = tonumber(char[9]) or 0
        if not isElement(lobby.showPed) then
                local spot = CAM_SPOTS[lobby.cam.index]
                lobby.showPed = createPed(model, spot[1], spot[2], spot[3])
                setElementDimension(lobby.showPed, 65499)
                setElementInterior(lobby.showPed, 0)
                setPedRotation(lobby.showPed, spot[4])
        end
        if isElement(lobby.showPed) then
                setElementModel(lobby.showPed, model)
                local animType = (tonumber(char[3]) == 1) and 4 or (lobby.justSwitched and 1 or 2)
                local anim = getRandomAnim(animType or 2)
                if anim then
                        setPedAnimation(lobby.showPed, anim[1], anim[2], -1, true, false, false, false)
                end
        end
end

-- ===========================================================================
-- show / hide
-- ===========================================================================

function Characters_showSelection()
        -- [Fix #48] a failed buildUI (UIKit restart race) used to abort the
        -- whole transition and leave the camera wherever the login screen
        -- ended - frozen with no UI. Build is pcall'd with one retry; a total
        -- failure is reported in chat instead of dying silently.
        if not built then
                local okBuild, buildErr = pcall(buildUI)
                if not okBuild then
                        built = false
                        outputChatBox("[Characters] UI build failed: " .. tostring(buildErr), 255, 100, 100, false)
                        local okRetry, retryErr = pcall(buildUI)
                        if not okRetry then
                                built = false
                                outputChatBox("[Characters] UI build retry failed: " .. tostring(retryErr), 255, 100, 100, false)
                        end
                end
        end
        triggerEvent("onSapphireXMBShow", localPlayer)
        showPlayerHudComponent("radar", false)

        lobby.selection_status = true
        showCursor(true)
        showChat(false)
        guiSetInputEnabled(false)

        if isElement(lobby.showPed) then destroyElement(lobby.showPed) end
        lobby.showPed = false

        local characterList = getElementData(localPlayer, "account:characters") or {}
        lobby.currentCharacters = characterList
        if #characterList == 0 then
                lobby.selectedCharacter = 0
                lobby.selectedID = false
        else
                if not characterList[lobby.selectedCharacter] then lobby.selectedCharacter = 1 end
                lobby.selectedID = characterList[lobby.selectedCharacter][1]
        end

        lobby.account = getElementData(localPlayer, "account:username")
                or getElementData(localPlayer, "account")
                or "None"
        lobby.cam.index = math.random(1, #CAM_SPOTS)
        local spot = CAM_SPOTS[lobby.cam.index]
        lobby.cam.spot = spot
        local cx, cy, cz = getCamPoint(spot)
        lobby.cam.pos = { cx, cy, cz }
        lobby.cam.target = { spot[1], spot[2], spot[3] + 0.45 }

        setTime(0, 0)
        setElementInterior(localPlayer, 0)
        setCameraInterior(0)
        setElementDimension(localPlayer, 65499)
        setElementAlpha(localPlayer, 0)
        fadeCamera(true)
        setCameraMatrix(cx, cy, cz, spot[1], spot[2], spot[3] + 0.45)



        if #characterList == 0 then
                eui:uiSetVisible(UI.window.CharacterInfo, false)
                eui:uiSetVisible(UI.button.Play, false)
                selectTab(2)
        else
                applyPedForCharacter()
                refreshCharacterDetails()
                eui:uiSetVisible(UI.window.CharacterInfo, true)
                eui:uiSetVisible(UI.button.Play, true)
                lobby.section = 1
        end

        removeEventHandler("onClientRender", root, lobby.draw)
        addEventHandler("onClientRender", root, lobby.draw)
        removeEventHandler("onClientClick", root, lobby.click)
        addEventHandler("onClientClick", root, lobby.click)

        startLobbyMusic()
end

function lobbyHide()
        lobby.selection_status = false
        stopLobbyMusic()
        showCursor(false)
        showChat(true)
        showPlayerHudComponent("radar", true)
        setElementAlpha(localPlayer, 255)
        setCameraTarget(localPlayer)
        removeEventHandler("onClientRender", root, lobby.draw)
        removeEventHandler("onClientClick", root, lobby.click)
        if isElement(lobby.showPed) then destroyElement(lobby.showPed) end
        lobby.showPed = false
        if built then
                eui:uiSetVisible(UI.window.CharacterInfo, false)
                eui:uiSetVisible(UI.button.Play, false)
                eui:uiSetVisible(UI.window.News, false)
                eui:uiSetVisible(UI.window.History, false)
        end
        showDirective(false)
        lobby.section = false
end

function characters_destroyDetailScreen()
        -- legacy name kept: clears everything the lobby owns
        lobbyHide()
end

-- ===========================================================================
-- tab switching
-- ===========================================================================

function selectTab(id)
        if lobby.section then
                if lobby.section == 1 then
                        eui:uiSetVisible(UI.window.CharacterInfo, #lobby.currentCharacters > 0)
                        eui:uiSetVisible(UI.button.Play, #lobby.currentCharacters > 0)
                elseif lobby.section == 2 and type(lobbyCreation) == "function" then
                        lobbyCreation(false)
                elseif lobby.section == 3 then
                        eui:uiSetVisible(UI.window.News, false)
                elseif lobby.section == 4 then
                        eui:uiSetVisible(UI.window.History, false)
                end
        end

        lobby.section = id
        if not id then return end
        playSound(":UIKit/sounds/click2.wav")

        if id == 1 then
                if isElement(lobby.showPed) then
                        local char = lobby.currentCharacters[lobby.selectedCharacter]
                        if char then
                                local anim = getRandomAnim(tonumber(char[3]) == 1 and 4 or 2)
                                if anim then setPedAnimation(lobby.showPed, anim[1], anim[2], -1, true, false, false, false) end
                        end
                end
                refreshCharacterDetails()
                eui:uiSetVisible(UI.window.CharacterInfo, #lobby.currentCharacters > 0)
                eui:uiSetVisible(UI.button.Play, #lobby.currentCharacters > 0)
        elseif id == 2 then
                eui:uiSetVisible(UI.window.CharacterInfo, false)
                eui:uiSetVisible(UI.button.Play, false)
                if type(lobbyCreation) == "function" then lobbyCreation(true) end
        elseif id == 3 then
                local title = getElementData(resourceRoot, "news:title")
                local text = getElementData(resourceRoot, "news:text")
                local sub = getElementData(resourceRoot, "news:sub")
                eui:uiSetText(UI.label.NewsTitle, tostring(title or "Latest News"))
                eui:uiSetText(UI.label.NewsText, tostring(text or "لا يوجد خبر متاح حالياً."))
                eui:uiSetText(UI.label.NewsSub, tostring(sub or ""))
                eui:uiSetVisible(UI.window.News, true)
        elseif id == 4 then
                eui:uiSetText(UI.label.HistoryTitle, "History")
                eui:uiSetText(UI.label.HistoryText, "سجل الحساب غير متوفر حالياً.\n\nAccount history is not available yet.")
                eui:uiSetVisible(UI.window.History, true)
        elseif id == 5 then
                lobbyToast("لتغيير كلمة المرور تواصل مع الإدارة عبر الديسكورد مع اسم الحساب + الإيميل", "info")
                outputChatBox("Password reset: contact the staff on Discord with your account name + email.", 255, 194, 14)
                lobby.section = false
        end
end

-- ===========================================================================
-- draw loop
-- ===========================================================================

function lobby.draw()
        if not lobby.selection_status then return end

        dxDrawRectangle(0, 0, sx, sy, tocolor(0, 3, 8, 180), true)
        dxDrawImage(0, 0, sx, sy, BG_TEXTURE, 0, 0, 0, tocolor(0, 3, 8, 255), true)

        -- logo (left, vertically centered) + account name (top-right)
        local logoSize = 100 * s
        dxDrawImage(70 * s, (sy - logoSize) / 2, logoSize, logoSize, ":main-menu/images/logo.png", 0, 0, 0, tocolor(255, 255, 255, 200), true)
        dxDrawText(tostring(lobby.account), 0, 10 * s, sx - 80 * s, 60 * s, tocolor(255, 255, 255, 180), 1.1 * s, "default-bold", "right", "center")

        -- tab row (circle indicator + labels) ------------------------------------
        local tabH = 40 * s
        local tabY = 45 * s
        local radius = (lobby.section and 12 * s) or 6 * s
        dxDrawCircle(50 * s, tabY + tabH / 2, radius, 0, 360, 0, 0, tocolor(255, 55, 95, 255), nil, 3 * s)

        local cursorX = 100 * s
        lobby.tabRects = {}
        for i, tab in ipairs(lobby.tabs) do
                local w = lobby.tab_width[i]
                local hovered = isMouseInPosition(cursorX, tabY, w, tabH)
                if hovered and lobby.hoverTab ~= i then
                        lobby.hoverTab = i
                        playSound(":assets/sounds/select.wav")
                elseif not hovered and lobby.hoverTab == i then
                        lobby.hoverTab = false
                end
                local alpha = (lobby.section == i) and 255 or (hovered and 200 or 120)
                dxDrawText(tab.text, cursorX, tabY, cursorX + w, tabY + tabH, tocolor(255, 255, 255, alpha), 1.2 * s, "default-bold", "center", "center")
                lobby.tabRects[i] = { x = cursorX, y = tabY, w = w, h = tabH }
                cursorX = cursorX + w
        end

        -- characters name list -----------------------------------------------------
        local nameY = 120 * s
        local nameH = 30 * s
        lobby.nameRects = {}
        if lobby.section == 1 or lobby.section == 2 then
                local countLabel = tostring(#lobby.currentCharacters)
                if #lobby.currentCharacters <= lobby.maxCharacters then
                        countLabel = countLabel .. "/" .. tostring(lobby.maxCharacters)
                end
                dxDrawText(countLabel, 0, nameY, sx - 50 * s, nameY + nameH, tocolor(255, 255, 255, 255), 1.1 * s, "default-bold", "right", "center")
        end

        if lobby.section == 1 then
                local underX, underW
                for i, char in ipairs(lobby.currentCharacters) do
                        local charName = tostring(char[2] or ""):gsub("_", " ")
                        local w = dxGetTextWidth(charName, 1.1 * s, "default-bold")
                        local x = 100 * s
                        local hovered = isMouseInPosition(x, nameY, w, nameH)
                        local alpha = (lobby.selectedCharacter == i) and 255 or (hovered and 200 or 150)
                        dxDrawText(charName, x, nameY + (i - 1) * (nameH + 8 * s), x + w, nameY + (i - 1) * (nameH + 8 * s) + nameH,
                                tocolor(255, 255, 255, alpha), 1.1 * s, "default-bold", "left", "center")
                        lobby.nameRects[i] = { x = x, y = nameY + (i - 1) * (nameH + 8 * s), w = w, h = nameH }
                        if lobby.selectedCharacter == i then
                                underX, underW = anim(lobby.selectAnim.tick, 400, lobby.selectAnim.fromX, lobby.selectAnim.fromW, x, w)
                                dxDrawLine(underX, nameY + (i - 1) * (nameH + 8 * s) + nameH, underX + underW, nameY + (i - 1) * (nameH + 8 * s) + nameH, tocolor(255, 255, 255, 255), 2, true)
                        end
                end
        end

        -- toast -------------------------------------------------------------------
        if toastData.text and getTickCount() - toastData.tick < toastData.life then
                local ttw = math.min(dxGetTextWidth(toastData.text, 1 * s, "default-bold") + 40 * s, sx - 100 * s)
                local th = 44 * s
                local tx = (sx - ttw) / 2
                local ty = sy - 140 * s
                dxDrawRectangle(tx, ty, ttw, th, tocolor(10, 10, 12, 235), true)
                dxDrawRectangle(tx, ty, 4 * s, th, tocolor(toastData.r, toastData.g, toastData.b, 255), true)
                dxDrawText(toastData.text, tx + 15 * s, ty, tx + ttw - 15 * s, ty + th, tocolor(255, 255, 255, 255), 1 * s, "default-bold", "center", "center", false, true, true)
        end

        -- directive (skin switching) ----------------------------------------------
        if directiveText then
                local dtw = dxGetTextWidth(directiveText, 1 * s, "default-bold") + 40 * s
                local dth = 40 * s
                local dtx = (sx - dtw) / 2
                local dty = 90 * s
                dxDrawRectangle(dtx, dty, dtw, dth, tocolor(10, 10, 12, 220), true)
                dxDrawText(directiveText, dtx, dty, dtx + dtw, dty + dth, tocolor(255, 255, 255, 240), 1 * s, "default-bold", "center", "center")
        end
end

-- ===========================================================================
-- click layer (tabs + names, raw onClientClick like the old client)
-- ===========================================================================

function lobby.click(button, state, absX, absY)
        if button ~= "left" or state ~= "down" then return end
        if not lobby.selection_status then return end

        for i, rect in ipairs(lobby.tabRects or {}) do
                if absX >= rect.x and absX <= rect.x + rect.w and absY >= rect.y and absY <= rect.y + rect.h then
                        if lobby.section ~= i then
                                selectTab(i)
                        end
                        return
                end
        end

        if lobby.section == 1 then
                for i, rect in ipairs(lobby.nameRects or {}) do
                        if absX >= rect.x and absX <= rect.x + rect.w and absY >= rect.y and absY <= rect.y + rect.h then
                                if lobby.selectedCharacter ~= i then
                                        lobby.justSwitched = true
                                        lobby.selectedCharacter = i
                                        lobby.selectedID = lobby.currentCharacters[i][1]
                                        lobby.selectAnim = { tick = getTickCount(), fromX = rect.x, fromW = 0 }
                                        applyPedForCharacter()
                                        refreshCharacterDetails()
                                        setTimer(function() lobby.justSwitched = false end, 600, 1)
                                end
                                return
                        end
                end
        end
end

-- ===========================================================================
-- UIKit events
-- ===========================================================================

addEventHandler("onClientUIClick", root, function()
        if not lobby.selection_status then return end
        if source == UI.button.Play then
                local char = lobby.currentCharacters[lobby.selectedCharacter]
                if not char then return end
                if tonumber(char[3]) == 1 then
                        lobbyToast("هذه الشخصية ميتة، لا يمكن اللعب بها", "error")
                        return
                end
                eui:uiSetVisible(UI.button.Play, false)
                eui:uiSetVisible(UI.window.CharacterInfo, false)
                stopLobbyMusic()
                fadeCamera(false, 1, 0, 0, 0)
                lobby.spawnRequested = getTickCount()
                setTimer(function()
                        triggerServerEvent("accounts:characters:spawn", localPlayer, lobby.selectedID)
                end, 900, 1)
                -- [Fix #48] SPAWN WATCHDOG: if the server never answers (an
                -- error aborted the spawn chain), the screen used to stay
                -- black/frozen forever with zero feedback. After 15s restore
                -- the lobby so the player can retry instead of relogging.
                setTimer(function()
                        if not lobby.selection_status then return end
                        if not lobby.spawnRequested then return end
                        if getTickCount() - lobby.spawnRequested < 14000 then return end
                        lobby.spawnRequested = nil
                        fadeCamera(true, 1)
                        eui:uiSetVisible(UI.button.Play, true)
                        eui:uiSetVisible(UI.window.CharacterInfo, true)
                        lobbyToast("فشل ظهور الشخصية، حاول مجددا", "error")
                end, 15000, 1)
        elseif source == UI.button.RemoveCharacter then
                local char = lobby.currentCharacters[lobby.selectedCharacter]
                if not char then return end
                if tonumber(char[3]) ~= 1 then
                        lobbyToast("يمكنك حذف الشخصيات الميتة فقط", "error")
                        return
                end
                triggerServerEvent("accounts:characters:remove", localPlayer, tonumber(char[1]))
        elseif source == UI.button.CloseNews then
                eui:uiSetVisible(UI.window.News, false)
                selectTab(1)
        elseif source == UI.button.CloseHistory then
                eui:uiSetVisible(UI.window.History, false)
                selectTab(1)
        end
end)

-- removal response: refresh the list and re-render the lobby
addEvent("accounts:characters:remove:response", true)
addEventHandler("accounts:characters:remove:response", root, function(ok, reason)
        if ok then
                lobbyToast("تم حذف الشخصية", "success")
                triggerServerEvent("updateCharacters", localPlayer)
                setTimer(function()
                        local list = getElementData(localPlayer, "account:characters") or {}
                        lobby.currentCharacters = list
                        if not list[lobby.selectedCharacter] then lobby.selectedCharacter = 1 end
                        if not list[lobby.selectedCharacter] then
                                lobby.selectedID = false
                                eui:uiSetVisible(UI.window.CharacterInfo, false)
                                eui:uiSetVisible(UI.button.Play, false)
                                if isElement(lobby.showPed) then destroyElement(lobby.showPed) end
                                lobby.showPed = false
                                selectTab(2)
                        else
                                lobby.selectedID = list[lobby.selectedCharacter][1]
                                applyPedForCharacter()
                                refreshCharacterDetails()
                        end
                end, 500, 1)
        else
                lobbyToast(tostring(reason or "فشل حذف الشخصية"), "error")
        end
end)

-- spawned: the server owns the rest (s_characters accounts:characters:spawn)
addEventHandler("accounts:characters:spawn", root, function()
        lobby.spawnRequested = nil -- [Fix #48] answered -> disarm the watchdog
        lobbyHide()
        fadeCamera(true)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        if lobby.selection_status then
                setElementAlpha(localPlayer, 255)
                setCameraTarget(localPlayer)
                showChat(true)
        end
end)

-- legacy alias used by the old logout flow
Characters_deactivateGUI = lobbyHide
