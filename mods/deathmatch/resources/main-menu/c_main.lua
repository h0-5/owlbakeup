--[[ ------------------------------------------------------------------------
        Vortex Main Menu (F1) — faithful 1:1 port of the original client resource.

        The UI is built with UIKit exactly like the original decompiled code
        (client_decompiled.lua from the lost client pack):

          window          uiCreateRectangle(false, false, refSx*0.75-130, refSy*0.65)
                          -> centered, rounded corners (true,true,true,true)
          sidebar menu    uiCreateMenu(5, 15, 220, refSy*0.65)
          content panel   uiCreateRectangle(250, 5, W-250, H-10, tocolor(3,6,11,240))
          corner ticks    four 10x2 white bars on the content panel corners
          sections        character_info / onlinestaff / leaderboard / linkdiscord / about

        Vortex deltas (user decisions):
          - UIKit theme_1.lua supplies the Vortex blue/purple (#5E4CFC / #9032FA)
          - sidebar rows use emoji icons (UIKit uiMenuAddRow emoji param)
          - sidebar rows are distributed across the FULL menu height (row 33 -> full)
          - "Wnash Time Roleplay" -> "Vortex", Vortex logo, links kept as data

        Server bridge notes:
          - exports that do not exist on this server yet (roleplay, level-system,
            play-time, notifications, public) are called through safeExport() and
            fall back to element data / plain values until those mods are restored.
-------------------------------------------------------------------------- ]]

local sx, sy = guiGetScreenSize()

--[[ reference screen — mirrors UIKit core/c_main.lua exactly ]]
local refSx, refSy = 1728, 972
if sx == 800 and sy == 600 then
        refSx, refSy = 1024, 768
end
local SCALE_X, SCALE_Y = sx / refSx, sy / refSy
if sx == 800 and sy == 600 then
        SCALE_X, SCALE_Y = SCALE_X * 0.7, SCALE_Y * 0.85
        refSx, refSy = sx / SCALE_X, sy / SCALE_Y
end
if sx == 1024 and sy == 768 then
        SCALE_X, SCALE_Y = SCALE_X * 1.05, SCALE_Y * 0.9
        refSx, refSy = sx / SCALE_X, sy / SCALE_Y
end

local eui = exports.UIKit

--[[ ============================== branding ============================== ]]

local LINKS = {
        discord      = "https://discord.gg/wnashtime",
        factions     = "https://discord.gg/TJPjhE8XMf",
        gangs        = "https://discord.gg/rQRMUkx7Pz",
        youtube      = "https://www.youtube.com/channel/UCAPHuNaKb1dF1zcYMH7HdCw",
        store        = "https://store.wnashtime.net",
        linkdiscord  = "https://wnashtime.net/linkdiscord",
}

local VERSION_LINE = "Version 2.1.0  -  Vortex Roleplay  -  Season 3"
local BRAND_TEXT   = "VORTEX ROLEPLAY"

--[[ ============================== sections ==============================
        id must match UI.container[id]. The original client referenced this
        table from a lost config file; the ids below are the ones the original
        code creates content for. Titles/emoji restore the sidebar. ]]

local SECTIONS = {
        -- icons use the ORIGINAL rows[].icon mechanism (arg3 of uiMenuAddRow);
        -- UIKit tints them with the menu "icons_color" (Vortex blue)
        { id = "character_info", en = "Personal Info",  ar = "المعلومات الشخصية",  icon = "icons/menu_person.png" },
        { id = "onlinestaff",    en = "Online Staff",   ar = "الإدارة المتصلة",    icon = "icons/menu_shield.png" },
        { id = "leaderboard",    en = "Leaderboard",    ar = "المتصدرين",          icon = "icons/menu_trophy.png" },
        -- [Mod 2] F2 sections: reports + rules + help, ABOVE link discord
        { id = "reports",        en = "Reports",        ar = "البلاغات",           icon = "icons/reportpanel.png" },
        { id = "rules",          en = "Server Rules",   ar = "القوانين",           icon = "icons/verified.png" },
        { id = "help",           en = "Help Center",    ar = "طلب المساعدة",       icon = "icons/heart.png" },
        { id = "linkdiscord",    en = "Link Discord",   ar = "ربط الديسكورد",      icon = "icons/menu_chat.png" },
        { id = "about",          en = "About Server",   ar = "عن السيرفر",         icon = "icons/menu_globe.png" },
}

local GENDERS = { "Male", "Female" }
local COUNTRIES = {}

--[[ ============================== state ============================== ]]

local UI = {
        tab = {}, progressbar = {}, edit = {}, window = {}, label = {}, checkbox = {},
        switch = {}, button = {}, tabpanel = {}, radiobutton = {}, gridlist = {},
        memo = {}, scrollbar = {}, combobox = {}, container = {}, image = {}, rectangle = {},
}

local menu = false            -- ui-menu element
local currentLinkCode = false -- discord link code
local pendingCode = false     -- generate-code request in flight

local state = {
        state = false,  -- sidebar open?
        alpha = 0,      -- current overlay alpha
        sideX = -260,   -- current branding strip width (slides)
        anim = false,
        vehicles = 0,   -- fetch throttles (tick stamps)
        interiors = 0,
        ["leaderboard:levels"] = 0,
        ["leaderboard:activities"] = 0,
}

--[[ ============================== helpers ============================== ]]

local resCache = {}
local function resRunning(name)
        if resCache[name] ~= nil then return resCache[name] end
        local res = getResourceFromName(name)
        local ok, running = false, false
        if res then
                ok, running = pcall(getResourceState, res)
        end
        resCache[name] = ok and running == "running"
        return resCache[name]
end

-- call a client export of another resource safely (nil when unavailable)
local function safeExport(resName, fnName, ...)
        if not resRunning(resName) then return nil end
        local res = getResourceFromName(resName)
        if not res then return nil end
        local ok, result = pcall(call, res, fnName, ...)
        if ok then return result end
        return nil
end

-- notifications with a chat fallback until the notifications mod is restored
local function notify(text, duration, kind)
        if type(text) ~= "table" then text = { en = tostring(text), ar = tostring(text) } end
        if resRunning("notifications") then
                local ok = pcall(function()
                        exports.notifications:output(text, duration or 3000, kind or "success")
                end)
                if ok then return end
        end
        outputChatBox(text.ar or text.en or "")
end

-- character data: exports.roleplay:getCharacter() when the mod is restored,
-- element-data fallback meanwhile
local function getCharacter()
        local c = safeExport("roleplay", "getCharacter")
        if type(c) == "table" then return c end
        local id = getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "account:character:id")
        return {
                ID = id or "-",
                Name = getPlayerName(localPlayer),
                Info = {},
                country = false,
        }
end

local function getPlayerIDStr(player)
        local id = safeExport("roleplay", "getPlayerID", player)
        if id then return tostring(id) end
        return tostring(getElementData(player, "character:id")
                or getElementData(player, "account:character:id") or "-")
end

-- number formatting with thousand separators (fixed the decompiled
-- infinite-loop version of this function)
function convertNumber(amount)
        amount = tostring(amount)
        local formatted = amount
        while true do
                local k
                formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
                if k == 0 then break end
        end
        return formatted
end

function convertTimeToString(seconds)
        seconds = tonumber(seconds) or 0
        return math.floor(seconds / (24 * (60 * 60))) .. "d "
                .. math.floor(seconds % (24 * (60 * 60)) / (60 * 60)) .. "h "
                .. math.floor(seconds % (24 * (60 * 60)) % (60 * 60) / 60) .. "m"
end

-- linear/out-quad interpolation for the sidebar slide + overlay fade
-- anim = { start, fromAlpha, fromSideX, toAlpha, toSideX, duration, easeOut }
function animation(anim)
        local elapsed = getTickCount() - anim[1]
        local progress = math.min(elapsed / anim[6], 1)
        if anim[7] then
                progress = 1 - (1 - progress) * (1 - progress)
        end
        return anim[2] + (anim[4] - anim[2]) * progress,
                anim[3] + (anim[5] - anim[3]) * progress
end

--[[ ============================== drawing ============================== ]]

local logoTex = dxCreateTexture("logo-circle.png", "argb", true, "clamp")
local logoTextTex = dxCreateTexture("images/logo_text.png", "argb", true, "clamp")
local bgGradient = false
if fileExists(":UIKit/images/gradient_x.png") then
        bgGradient = dxCreateTexture(":UIKit/images/gradient_x.png", "argb", true, "clamp")
end

-- [Mod 2] bigger centered logo + vertical cursive wordmark
local LOGO_SIZE = 110 * SCALE_Y

function main_menu_draw()
        state.alpha, state.sideX = animation(state.anim)
        -- dark veil over the game
        dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, math.max(0, state.alpha - 80)), true)
        -- branding strip sliding in from the left
        dxDrawRectangle(0, 0, state.sideX, sy, tocolor(0, 3, 8, state.alpha), true)
        if bgGradient then
                dxDrawImage(state.sideX, 0, sx, sy, bgGradient, 0, 0, 0, tocolor(0, 3, 8, state.alpha), true)
        end
        -- divider line
        if state.sideX > 0 then
                dxDrawRectangle(state.sideX + 2 * SCALE_X, 0, SCALE_X, sy, tocolor(255, 255, 255, 10), true)
        end
        -- [Mod 2] branding strip: big centered logo, then "Vortex" written
        -- vertically (cursive pricedown, rotated 90 = reads top->bottom)
        if logoTex and state.sideX > 60 then
                local bigX = (state.sideX - LOGO_SIZE) / 2
                local bigY = 26 * SCALE_Y
                dxDrawImage(bigX, bigY, LOGO_SIZE, LOGO_SIZE, logoTex, 0, 0, 0, tocolor(255, 255, 255, 215), true)
                local wordScale = 1.35 * SCALE_Y
                local wordW = 64 * SCALE_Y
                local wordH = 250 * SCALE_Y
                local wordX = (state.sideX - wordW) / 2
                local wordY = bigY + LOGO_SIZE + 40 * SCALE_Y
                local wordColor = tocolor(255, 255, 255, 235)
                local shadowColor = tocolor(94, 76, 252, 120)
                dxDrawText("Vortex", wordX + 2, wordY + 2, wordX + wordW + 2, wordY + wordH + 2,
                        shadowColor, wordScale, "pricedown", "center", "center", false, false, true, false, false, 90)
                dxDrawText("Vortex", wordX, wordY, wordX + wordW, wordY + wordH,
                        wordColor, wordScale, "pricedown", "center", "center", false, false, true, false, false, 90)
        end
end

--[[ F1 / ESC-binds cancel while quitting the character ]]
function cancelBindsEvent(key, press)
        if press and (key == "F1" or key == "F2" or key == "F3" or key == "F4"
                or key == "F11" or key == "F7") then
                cancelEvent()
        end
end

function MainMenuKey()
        -- original gate is character:id (wnash RP core, not restored yet);
        -- this server's account system sets SYNCED loggedin=1 on character
        -- selection and 0 on quit — accept either so F1 works on both stacks
        if getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "loggedin") == 1 then
                showSideBar(not state.state)
        end
end
bindKey("F1", "down", MainMenuKey)
addCommandHandler("menu", MainMenuKey, false, false)

-- [Mod 2] F2 = reports hub (opens the same Vortex menu directly on the
-- reports section; rules + help live right below it)
function ReportsMenuKey()
        if getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "loggedin") == 1 then
                local wasOpen = state.state
                showSideBar(not wasOpen, "reports")
        end
end
bindKey("F2", "down", ReportsMenuKey)
-- /report stays owned by report-system (classic admin window)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
        showSideBar(false)
end)

function showEscapeView(show)
        showSideBar(show)
end

function isOpen()
        return state.state
end

function getMenuElement()
        return menu
end

function showSideBar(show, openSection)
        state.state = show
        showCursor(show)
        if show then
                state.anim = { getTickCount(), state.alpha, state.sideX, 250, 250, 350, true }
                addEventHandler("onClientRender", root, main_menu_draw, false, "high-2")
                eui:uiSetVisible(UI.window.MainMenu, true)
                -- [Mod 2] optional section to land on (F2 -> reports)
                local target = 1
                if openSection then
                        for i, section in ipairs(SECTIONS) do
                                if section.id == openSection then target = i end
                        end
                end
                eui:uiMenuSetSelectedRow(menu, target)
        else
                removeEventHandler("onClientRender", root, main_menu_draw)
                state.anim = { getTickCount(), state.alpha, state.sideX, 0, -260, 250, false }
                eui:uiSetVisible(UI.window.MainMenu, false)
        end
end

--[[ ===================== UIKit construction (1:1) ===================== ]]

local uiBuilt = false -- rebuild guard (see UIKitReady)

function UIKitReady()
        -- only one live panel per UIKit lifetime: both onClientUIReady and
        -- onClientUIKitReady fire on some start orders (and UIKit may restart
        -- while main-menu is up). A COMPLETED build is kept, an ABORTED one
        -- (UIKit not running yet) is discarded and rebuilt on the next event.
        if UI.window.MainMenu and isElement(UI.window.MainMenu) then
                if uiBuilt then return end
                destroyElement(UI.window.MainMenu)
        end
        eui = exports.UIKit

        UI.window.MainMenu = eui:uiCreateRectangle(false, false,
                refSx * 0.75 - 130, refSy * 0.65, tocolor(19, 22, 27, 0), true, true, true, true)
        eui:uiSetVisible(UI.window.MainMenu, false)
        eui:uiBringToFront(UI.window.MainMenu)

        local winW, winH = refSx * 0.75 - 130, refSy * 0.65
        local contentW, contentH = winW - 220 - 30, winH - 10

        -- sidebar menu — rows distributed across the FULL height (user fix #3),
        -- emoji icons instead of images (user fix #2), rounded rows via UIKit (fix #1)
        menu = eui:uiCreateMenu(5, 15, 220, winH, tocolor(19, 22, 27, 0), UI.window.MainMenu)
        eui:uiSetProperty(menu, "hovered_row_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(menu, "selected_row_color", tocolor(3, 6, 11, 250))
        -- fill the menu height: padding 5+5 and 4px gaps between rows, small safety
        local rowHeight = (winH - (10 + (#SECTIONS - 1) * 4 + 8) / SCALE_Y) / #SECTIONS
        eui:uiSetProperty(menu, "row_height", rowHeight)
        eui:uiSetProperty(menu, "row_font_scale", 1.2)
        eui:uiSetProperty(menu, "icons_color", eui:uiGetThemeColor("primary"))
        eui:uiSetProperty(menu, "selection_color", tocolor(255, 255, 255))
        setElementID(menu, "main-menu")

        for _, section in ipairs(SECTIONS) do
                -- rounded content panel (true,true,true,true = rounded corners, radius 7)
                local panel = eui:uiCreateRectangle(220 + 30, 5, contentW, contentH,
                        tocolor(3, 6, 11, 240), true, true, true, true, UI.window.MainMenu)
                UI.container[section.id] = eui:uiCreateContainer(0, 0, contentW, contentH, panel)
                eui:uiSetVisible(UI.container[section.id], false)

                UI.label.title = eui:uiCreateLabel(0, 10, contentW, 30,
                        { en = section.en, ar = section.ar }, tocolor(255, 255, 255, 255),
                        "center", "center", UI.container[section.id])
                eui:uiSetFont(UI.label.title, "default-large")

                -- the four white corner ticks of the content panel (sharp, like original)
                eui:uiCreateRectangle(30, 0, 10, 2, tocolor(255, 255, 255, 240),
                        false, false, false, false, panel)
                eui:uiCreateRectangle(contentW - 40, contentH - 2, 10, 2, tocolor(255, 255, 255, 240),
                        false, false, false, false, panel)
                eui:uiCreateRectangle(contentW - 40, 0, 10, 2, tocolor(255, 255, 255, 240),
                        false, false, false, false, panel)
                eui:uiCreateRectangle(30, contentH - 2, 10, 2, tocolor(255, 255, 255, 240),
                        false, false, false, false, panel)

                eui:uiMenuAddRow(menu, { en = section.en, ar = section.ar },
                        tocolor(29, 32, 37, 0), section.icon, UI.container[section.id], section.id)
        end

        --[[ ------------------ reports (F2) ------------------ ]]

        -- [Mod 2] dedicated reports design. Mirrors the report-system flow:
        -- triggerServerEvent("clientSendReport", localPlayer, target, text, type)
        -- with the SAME 7 categories (report-system/g_reports.lua order) so the
        -- admin side keeps working untouched.
        local REPORT_TYPES = {
                { "Issue with another player",     "Use this type if you are reporting a player about a issue that has occured." },
                { "Interior Issue",                "Use this type if you are having a issue with a interior." },
                { "Item Issue",                    "Use this type if you need items spawned or anything related to your item inventory." },
                { "General Question",              "Use this type if you have any questions." },
                { "Vehicle Related Issues",        "Use this type if you have a issue with a vehicle." },
                { "Vehicle Build/Import Requests", "Use this type to contact the VCT." },
                { "Scripting Question",            "Use this type if you wish to contact the Scripting Team." },
        }

        local function resolveReportTarget(text)
                -- same resolution the old F2 window used: full/partial name or player id
                if type(text) ~= "string" or text == "" then return false end
                local found = false
                if tonumber(text) then
                        for _, value in ipairs(getElementsByType("player")) do
                                if tonumber(getElementData(value, "playerid")) == tonumber(text) then
                                        found = value
                                        break
                                end
                        end
                else
                        for _, value in ipairs(getElementsByType("player")) do
                                if string.find(string.lower(getPlayerName(value)), string.lower(text), 1, true) then
                                        found = value
                                        break
                                end
                        end
                end
                return found
        end

        eui:uiCreateLabel(30, 52, (contentW - 60) * 0.45, 22, { en = "Report type", ar = "نوع البلاغ" },
                tocolor(255, 255, 255, 160), "left", "center", UI.container.reports)
        UI.combobox.report_type = eui:uiCreateComboBox(30, 78, (contentW - 60) * 0.45, 32,
                "اختر النوع...", tocolor(9, 12, 17, 235), UI.container.reports)
        eui:uiSetProperty(UI.combobox.report_type, "text_color", tocolor(255, 255, 255, 255))
        for _, rtype in ipairs(REPORT_TYPES) do
                eui:uiComboBoxAddItem(UI.combobox.report_type, rtype[1])
        end
        eui:uiComboBoxSetSelected(UI.combobox.report_type, 0)
        UI.label.report_type_desc = eui:uiCreateLabel(30, 116, (contentW - 60) * 0.45, 44,
                REPORT_TYPES[1][2], tocolor(255, 255, 255, 120), "left", "top", UI.container.reports)

        eui:uiCreateLabel(30 + (contentW - 60) * 0.5, 52, (contentW - 60) * 0.5, 22,
                { en = "Player you report (optional)", ar = "اللاعب المراد الإبلاغ عنه (اختياري)" },
                tocolor(255, 255, 255, 160), "left", "center", UI.container.reports)
        UI.edit.report_target = eui:uiCreateEdit(30 + (contentW - 60) * 0.5, 78, (contentW - 60) * 0.5, 32,
                "", "اسم اللاعب / رقمه", tocolor(9, 12, 17, 235), UI.container.reports)
        eui:uiSetProperty(UI.edit.report_target, "UnderLineVisible", "False")

        UI.memo.report_text = eui:uiCreateMemo(30, 170, contentW - 60, contentH - 170 - 92,
                "", tocolor(255, 255, 255, 255), UI.container.reports)
        UI.label.report_counter = eui:uiCreateLabel(30, contentH - 84, 220, 24, "0 / 150",
                tocolor(46, 213, 115, 255), "left", "center", UI.container.reports)
        UI.button.report_submit = eui:uiCreateButton(contentW - 30 - 190, contentH - 84, 190, 42,
                { en = "Send Report", ar = "إرسال البلاغ" }, "primary", UI.container.reports)
        eui:uiSetProperty(UI.button.report_submit, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.report_submit, "HoverTextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.report_submit, "HoverGlow", true)

        if not UI._mod2WiredText then
        UI._mod2WiredText = true
addEventHandler("onClientUITextChange", root, function()
                if source == UI.memo.report_text and isElement(UI.label.report_counter) then
                        local len = #tostring(eui:uiGetText(UI.memo.report_text) or "")
                        eui:uiSetText(UI.label.report_counter, len .. " / 150")
                end
        end)
        end

        if not UI._mod2WiredReport then
        UI._mod2WiredReport = true
addEventHandler("onClientUIClick", root, function()
                if source ~= UI.button.report_submit then return end
                local text = tostring(eui:uiGetText(UI.memo.report_text) or "")
                local typeIdx = (tonumber(eui:uiComboBoxGetSelected(UI.combobox.report_type)) or 0) + 1
                if text:len() < 10 then
                        notify({ en = "Report is too short (min 10 chars)", ar = "البلاغ قصير جداً (10 أحرف على الأقل)" }, 3000, "error")
                        eui:uiLabelApplyShakeAnimation(UI.label.report_counter, tocolor(255, 65, 65, 255))
                        return
                end
                if text:len() > 150 then
                        notify({ en = "Report is too long (max 150 chars)", ar = "البلاغ طويل جداً (150 حرفاً كحد أقصى)" }, 3000, "error")
                        eui:uiLabelApplyShakeAnimation(UI.label.report_counter, tocolor(255, 65, 65, 255))
                        return
                end
                local target = resolveReportTarget(tostring(eui:uiGetText(UI.edit.report_target) or ""))
                triggerServerEvent("clientSendReport", localPlayer, target or localPlayer, text, typeIdx)
                eui:uiSetText(UI.memo.report_text, "")
                eui:uiSetText(UI.label.report_counter, "0 / 150")
                notify({ en = "Report sent to the staff team", ar = "تم إرسال البلاغ إلى الإدارة" }, 4000, "success")
        end)
        end

        --[[ ------------------ rules ------------------ ]]

        -- [Mod 2] dedicated rules design: the full server rules rendered in the
        -- Vortex panel (same text the old login flow used, now always reachable)
        local rulesText = ""
        local rulesXml = xmlLoadFile("rules.xml")
        if rulesXml then
                rulesText = tostring(xmlNodeGetValue(rulesXml) or "")
                xmlUnloadFile(rulesXml)
        end
        eui:uiCreateLabel(30, 50, contentW - 60, 24,
                { en = "Read the rules carefully - breaking them is punishable", ar = "اقرأ القوانين بعناية - مخالفتها عرضة للعقوبة" },
                tocolor(255, 255, 255, 150), "center", "center", UI.container.rules)
        UI.memo.rules = eui:uiCreateMemo(30, 82, contentW - 60, contentH - 100,
                rulesText, tocolor(255, 255, 255, 255), UI.container.rules)

        --[[ ------------------ help ------------------ ]]

        -- [Mod 2] dedicated help center: what is roleplay + quick actions
        local rpText = ""
        local rpXml = xmlLoadFile("whatisroleplaying.xml")
        if rpXml then
                rpText = tostring(xmlNodeGetValue(rpXml) or "")
                xmlUnloadFile(rpXml)
        end
        local helpCardW = (contentW - 40) * 0.55
        eui:uiCreateLabel(30, 50, helpCardW, 24, { en = "What is roleplay?", ar = "ما هو الرول بلاي؟" },
                tocolor(255, 255, 255, 160), "left", "center", UI.container.help)
        UI.memo.help_rp = eui:uiCreateMemo(30, 82, helpCardW, contentH - 100,
                rpText, tocolor(255, 255, 255, 255), UI.container.help)

        local helpX = 30 + helpCardW + 10
        local helpW = contentW - 30 - helpX
        local helpCardH = (contentH - 100 - 20) / 3
        local helpCards = {
                { key = "report",  icon = "icons/reportpanel.png",     en = "Ask the staff for help",   ar = "اطلب المساعدة من الإدارة" },
                { key = "staff",   icon = "icons/menu_shield.png",     en = "See the online staff",     ar = "الإدارة المتصلة الآن" },
                { key = "discord", icon = "icons/discord.png",         en = "Join our Discord",         ar = "الديسكورد الرسمي" },
        }
        for i, card in ipairs(helpCards) do
                local cardY = 82 + (i - 1) * (helpCardH + 10)
                local rect = eui:uiCreateRectangle(helpX, cardY, helpW, helpCardH,
                        tocolor(9, 12, 17, 200), true, true, true, true, UI.container.help)
                eui:uiCreateImage(14, helpCardH / 2 - 17, 34, 34, card.icon, rect)
                eui:uiCreateLabel(60, 0, helpW - 70, helpCardH, { en = card.en, ar = card.ar },
                        tocolor(255, 255, 255, 255), "left", "center", rect)
                UI.rectangle["help_" .. card.key] = rect
        end

        if not UI._mod2WiredHelp then
        UI._mod2WiredHelp = true
addEventHandler("onClientUIClick", root, function()
                if source == UI.rectangle.help_report then
                        for i, section in ipairs(SECTIONS) do
                                if section.id == "reports" then eui:uiMenuSetSelectedRow(menu, i) end
                        end
                elseif source == UI.rectangle.help_staff then
                        for i, section in ipairs(SECTIONS) do
                                if section.id == "onlinestaff" then eui:uiMenuSetSelectedRow(menu, i) end
                        end
                elseif source == UI.rectangle.help_discord then
                        setClipboard(LINKS.discord)
                        notify({ en = "Discord link copied", ar = "تم نسخ رابط الديسكورد" }, 3000, "success")
                end
        end)
        end

        --[[ ------------------ character_info ------------------ ]]

        UI.tabpanel[1] = eui:uiCreateTabPanel(10, 110, contentW - 20, 320, "",
                tocolor(0, 0, 0, 0), UI.container.character_info)
        eui:uiSetProperty(UI.tabpanel[1], "tabs_bar_color", tocolor(29, 32, 37, 0))
        eui:uiSetProperty(UI.tabpanel[1], "tab_selected_color", tocolor(9, 12, 17, 220))
        eui:uiSetProperty(UI.tabpanel[1], "tab_height", 60)
        eui:uiSetProperty(UI.tabpanel[1], "tab_hovered_color", tocolor(9, 12, 17, 100))

        UI.tab[1] = eui:uiCreateTab({ en = "Info", ar = "المعلومات" }, "", UI.tabpanel[1])
        local infoW = (contentW - 40) * 0.7
        local infoH = winH - 10 - 210
        local cardColor = tocolor(9, 12, 17, 180)
        local rectInfoLeft = eui:uiCreateRectangle(5, 25, infoW, infoH, cardColor,
                true, true, true, true, UI.tab[1])
        UI.label[1] = eui:uiCreateLabel(15, 25, (infoW - 20) / 2, 300, "",
                tocolor(255, 255, 255, 255), "left", "top", rectInfoLeft)
        eui:uiSetProperty(UI.label[1], "line_spacing", 35)
        UI.label[4] = eui:uiCreateLabel(15 + (infoW - 20) / 2, 25, (infoW - 20) / 2, 300, "",
                tocolor(255, 255, 255, 255), "left", "top", rectInfoLeft)
        eui:uiSetProperty(UI.label[4], "line_spacing", 35)

        local sideW = (contentW - 40) * 0.3
        local sideH = (infoH - 10) * 0.5
        local rectInfoRight = eui:uiCreateRectangle(5 + infoW + 10, 25, sideW, sideH, cardColor,
                true, true, true, true, UI.tab[1])
        UI.label.level = eui:uiCreateLabel(0, 30, sideW, 30, "Level ${color.primary}1",
                tocolor(255, 255, 255, 255), "center", "top", rectInfoRight)
        UI.label.level_exp = eui:uiCreateLabel(0, 60, sideW, 30, "10000 / 10000",
                tocolor(255, 255, 255, 255), "center", "top", rectInfoRight)
        eui:uiSetFont(UI.label.level, "default-large")
        UI.progressbar[1] = eui:uiCreateProgressBar(20, 100, sideW - 40, 6, _, rectInfoRight)
        eui:uiSetProperty(UI.progressbar[1], "background_color", tocolor(20, 20, 20, 240))
        eui:uiSetProperty(UI.progressbar[1], "show_progress", false)
        eui:uiSetProperty(UI.progressbar[1], "progress_animation", true)
        UI.button.goto_level_awards = eui:uiCreateButton(15, sideH - 50, sideW - 30, 35,
                { en = "Level Awards", ar = "جوائز المستوى" }, _, rectInfoRight)

        local rectPlayTime = eui:uiCreateRectangle(5 + infoW + 10, 25 + sideH + 10,
                sideW, sideH, cardColor, true, true, true, true, UI.tab[1])
        UI.label.play_time = eui:uiCreateLabel(0, 0, sideW, sideH,
                "\nPlay Time\n\n00:00:00:00", tocolor(255, 255, 255, 255),
                "center", "center", rectPlayTime)
        eui:uiSetFont(UI.label.play_time, "default-large")

        UI.tab[2] = eui:uiCreateTab({ en = "Vehicles", ar = "المركبات" }, "", UI.tabpanel[1])
        UI.label.vehicles = eui:uiCreateLabel(10, 10, 340, 20, "",
                tocolor(255, 255, 255, 255), "left", "top", UI.tab[2])
        UI.gridlist.vehicles = eui:uiCreateGridList(0, 40, contentW - 20, winH - 10 - 220,
                tocolor(10, 10, 10, 0), UI.tab[2])
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "Name", 0.65)
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "Plate", 0.15)
        eui:uiSetAlign(UI.gridlist.vehicles, "left", "center")
        eui:uiSetProperty(UI.gridlist.vehicles, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.vehicles, "row_height", 30)

        UI.tab[3] = eui:uiCreateTab({ en = "Interiors", ar = "البيوت والمحلات" }, "", UI.tabpanel[1])
        UI.label.interiors = eui:uiCreateLabel(10, 10, 340, 20, "",
                tocolor(255, 255, 255, 255), "left", "top", UI.tab[3])
        UI.gridlist.interiors = eui:uiCreateGridList(0, 40, contentW - 20, winH - 10 - 220,
                tocolor(10, 10, 10, 0), UI.tab[3])
        eui:uiGridListAddColumn(UI.gridlist.interiors, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.interiors, "Name", 0.6)
        eui:uiGridListAddColumn(UI.gridlist.interiors, "Status", 0.2)
        eui:uiSetAlign(UI.gridlist.interiors, "left", "center")
        eui:uiSetProperty(UI.gridlist.interiors, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.interiors, "row_height", 30)

        -- footer: separator + username + quit button
        eui:uiCreateRectangle(5, contentH - 60, contentW - 10, 1, tocolor(255, 255, 255, 10),
                false, false, false, false, UI.container.character_info)
        UI.label.username = eui:uiCreateLabel(20, contentH - 50, 200, 35, "",
                tocolor(255, 255, 255, 50), "left", "center", UI.container.character_info)
        UI.button["character:quit"] = eui:uiCreateButton(contentW - 200 - 15, contentH - 50,
                200, 35, { en = "Quit Character", ar = "خروج من الشخصية" },
                "primary", UI.container.character_info)
        eui:uiSetProperty(UI.button["character:quit"], "HoverGlow", true)

        --[[ ------------------ about ------------------ ]]

        eui:uiCreateLabel(0, contentH - 40, contentW, 30, VERSION_LINE,
                tocolor(255, 255, 255, 50), "center", "center", UI.container.about)

        local linkRows = {
                { key = "discord",  y = 100, icon = "icons/discord.png", ar = "الديسكورد الرسمي" },
                { key = "factions", y = 160, icon = "icons/discord.png", ar = "ديسكورد الفاشنات" },
                { key = "gangs",    y = 220, icon = "icons/discord.png", ar = "ديسكورد العصابات" },
                { key = "youtube",  y = 280, icon = "icons/youtube.png", ar = "Vortex RolePlay" },
                { key = "store",    y = 340, icon = "logo-circle.png",    ar = "المتجر الرسمي" },
        }
        for _, row in ipairs(linkRows) do
                local rect = eui:uiCreateRectangle(10, row.y, contentW - 20, 50,
                        tocolor(19, 22, 27, 240), true, true, true, true, UI.container.about)
                UI.rectangle[row.key] = rect
                eui:uiCreateImage(10, 5, 40, 40, row.icon, rect)
                eui:uiCreateLabel(60, 0, 200, 50, row.ar, tocolor(255, 255, 255, 255),
                        "left", "center", rect)
                UI.button["copy_" .. row.key] = eui:uiCreateButton(contentW - 20 - 100, 10,
                        90, 30, { en = "Copy Link", ar = "انسخ الرابط" },
                        tocolor(9, 12, 17, 220), rect)
                eui:uiSetClickAction(UI.button["copy_" .. row.key], LINKS[row.key])
        end

        --[[ ------------------ online staff ------------------ ]]

        UI.gridlist.staff = eui:uiCreateGridList(10, 50, contentW - 20, (contentH - 50) / 2,
                tocolor(0, 0, 0, 0), UI.container.onlinestaff)
        eui:uiGridListAddColumn(UI.gridlist.staff, "Admins Team", 0.5)
        eui:uiGridListAddColumn(UI.gridlist.staff, "", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.staff, "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.staff, "", 0.15)
        eui:uiSetAlign(UI.gridlist.staff, "left", "center")
        eui:uiSetProperty(UI.gridlist.staff, "color_coded", true)

        UI.gridlist.staff2 = eui:uiCreateGridList(10, 50 + (contentH - 50) / 2 + 10,
                contentW - 20, (contentH - 100) / 2, tocolor(0, 0, 0, 0), UI.container.onlinestaff)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "Supports Team", 0.5)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "", 0.15)
        eui:uiSetAlign(UI.gridlist.staff2, "left", "center")
        eui:uiSetProperty(UI.gridlist.staff2, "color_coded", true)

        --[[ ------------------ link discord ------------------ ]]

        UI.container.notlinked = eui:uiCreateContainer(0, 0, contentW, contentH, UI.container.linkdiscord)
        UI.container.linked = eui:uiCreateContainer(0, 0, contentW, contentH, UI.container.linkdiscord)
        eui:uiSetVisible(UI.container.notlinked, true)
        eui:uiSetVisible(UI.container.linked, false)

        UI.image.WT = eui:uiCreateImage(contentW / 2 - 80 - 40, 70, 80, 80, "logo-circle.png", UI.container.linkdiscord)
        UI.image.Discord = eui:uiCreateImage(contentW / 2 + 40, 70, 80, 80, "icons/discord.png", UI.container.linkdiscord)
        UI.image.Link = eui:uiCreateImage(contentW / 2 - 15, 100, 30, 30, "icons/link.png", UI.container.linkdiscord)

        eui:uiCreateLabel(15, 180, contentW - 30, 80,
                "\t\tالآن يمكنك ربط حسابك بحساب الديسكورد الخاص بك\n"
                .. "\t\tالربط سيساعدك على تأمين حسابك بشكل أفضل والحصول على ميزات عديدة\n\n"
                .. "\t\tلربط حسابك قم بإنشاء رمز جديد عن طريق الضغط على زر 'إنشاء رمز' بالأسفل\n"
                .. "\t\tثم توجه إلى الصفحة التالية\n"
                .. "${color.primary}" .. LINKS.linkdiscord .. "\n",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.notlinked)
        UI.button.copy_link_url = eui:uiCreateButton((contentW - 120) / 2, 300, 120, 30,
                { en = "Copy Link", ar = "انسخ الرابط" }, tocolor(0, 0, 0, 240), UI.container.notlinked)
        UI.rectangle.code = eui:uiCreateRectangle((contentW - 350) / 2, 370, 350, 40,
                tocolor(19, 22, 27, 240), true, true, true, true, UI.container.notlinked)
        UI.label.code = eui:uiCreateLabel(0, 0, 350, 40, "* * * * * * * * * * * * * * * * * * * * * * *",
                tocolor(255, 255, 255, 255), "center", "center", UI.rectangle.code)
        eui:uiSetFont(UI.label.code, "default-large")
        UI.button.generate_code = eui:uiCreateButton((contentW - 170) / 2, 420, 170, 35,
                { en = "Generate Code", ar = "إنشاء رمز" }, "primary", UI.container.notlinked)
        eui:uiCreateLabel(15, 480, contentW - 30, 30,
                "\t\tبعد إنشاء الرمز سيكون صالح للاستخدام خلال 5 دقائق\n"
                .. "\t\tيمكن نسخ الرمز عن طريق الضغط عليه\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.notlinked)

        eui:uiCreateLabel(15, 180, contentW - 30, 20,
                "\t\tحسابك مربوط بحساب الديسكورد التالي\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.linked)
        UI.label.discord_tag = eui:uiCreateLabel(15, 210, contentW - 30, 30, "-",
                "primary", "center", "top", UI.container.linked)
        eui:uiSetFont(UI.label.discord_tag, "default-large")
        UI.label.discord_id = eui:uiCreateLabel(15, 240, contentW - 30, 20,
                "\n                ID: XXXXXXXXXXXXXXXXXXXX\n        ",
                tocolor(255, 255, 255, 150), "center", "top", UI.container.linked)
        eui:uiCreateLabel(15, 410, contentW - 30, 40,
                "\t\tفي حال رغبتك بتغيير حساب الديسكورد المربوط بحسابك\n"
                .. "\t\tيمكنك إلغاء الربط وإعادة ربط حسابك مع الحساب الجديد\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.linked)
        UI.button.unlinkdiscord = eui:uiCreateButton((contentW - 170) / 2, 470, 170, 35,
                { en = "Unlink the Discord", ar = "إلغاء ربط الديسكورد" }, "primary", UI.container.linked)
        UI.image.avatar = eui:uiCreateBrowser((contentW - 100) / 2, 280, 100, 100, false, true, UI.container.linked)
        addEventHandler("onClientBrowserCreated", eui:uiGetBrowser(UI.image.avatar), function()
                loadBrowserURL(source, "https://i.postimg.cc/fRxyqZQ6/logo.png")
        end)

        --[[ ------------------ leaderboard ------------------ ]]

        UI.tabpanel.leaderboard = eui:uiCreateTabPanel(10, 110, contentW - 20, 320, "",
                tocolor(0, 0, 0, 0), UI.container.leaderboard)
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tabs_bar_color", tocolor(29, 32, 37, 0))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_selected_color", tocolor(9, 12, 17, 220))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_height", 50)
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_hovered_color", tocolor(9, 12, 17, 100))

        UI.tab["leaderboard:levels"] = eui:uiCreateTab(
                { en = "Levels", ar = "المستويات" }, "", UI.tabpanel.leaderboard)
        UI.tab["leaderboard:activities"] = eui:uiCreateTab(
                { en = "Activities", ar = "الأنشطة" }, "", UI.tabpanel.leaderboard)

        UI.gridlist["leaderboard:levels"] = eui:uiCreateGridList(0, 30, contentW - 20,
                contentH - 150, tocolor(10, 10, 10, 0), UI.tab["leaderboard:levels"])
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "Name", 0.5)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "Level", 0.3)
        eui:uiSetAlign(UI.gridlist["leaderboard:levels"], "left", "center")
        eui:uiSetProperty(UI.gridlist["leaderboard:levels"], "color_coded", true)
        eui:uiSetProperty(UI.gridlist["leaderboard:levels"], "row_height", 40)

        UI.gridlist["leaderboard:activities"] = eui:uiCreateGridList(0, 30, contentW - 20,
                contentH - 150, tocolor(10, 10, 10, 0), UI.tab["leaderboard:activities"])
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "Name", 0.5)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "Points", 0.3)
        eui:uiSetAlign(UI.gridlist["leaderboard:activities"], "left", "center")
        eui:uiSetProperty(UI.gridlist["leaderboard:activities"], "color_coded", true)
        eui:uiSetProperty(UI.gridlist["leaderboard:activities"], "row_height", 40)

        --[[ ------------------ handlers ------------------ ]]

        addEventHandler("onClientUIClick", root, function()
                if source == UI.button["character:quit"] then
                        -- [Mod 2 fix] F1 change-character now runs the EXACT old F10
                        -- flow. The old backup (account + hud c_options.lua) listens
                        -- to the client event "accounts:logout" with options_logOut:
                        --   updateCharacters -> accounts:characters:change ->
                        --   onClientChangeChar -> options_disable ->
                        --   Characters_showSelection() -> clearChat()
                        -- The previous code only fired the server event, so the
                        -- server cleaned up while the 3D character-selection screen
                        -- never appeared (player stuck in an empty dimension).
                        addEventHandler("onClientKey", root, cancelBindsEvent)
                        showSideBar(false)
                        if resRunning("roleplay") then
                                pcall(function() exports.roleplay:switchOutPlayer() end)
                        else
                                triggerEvent("accounts:logout", localPlayer)
                        end
                        setTimer(function()
                                removeEventHandler("onClientKey", root, cancelBindsEvent)
                        end, 3000, 1)
                elseif source == UI.button.copy_discord then
                        setClipboard(LINKS.discord)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.button.copy_youtube then
                        setClipboard(LINKS.youtube)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.button.copy_store then
                        setClipboard(LINKS.store)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.button["copy_discord.factions"] then
                        setClipboard(LINKS.factions)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.button["copy_discord.gangs"] then
                        setClipboard(LINKS.gangs)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.button.copy_link_url then
                        setClipboard(LINKS.linkdiscord)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.label.code then
                        if currentLinkCode then
                                setClipboard(currentLinkCode)
                                notify({ en = "Code copied", ar = "تم نسخ الرمز" }, 3000, "success")
                                eui:uiLabelApplyShakeAnimation(UI.label.code, tocolor(0, 255, 0, 255))
                        else
                                notify({ en = "Generate code first", ar = "قم بإنشاء رمز أولاً" }, 3000, "error")
                                eui:uiLabelApplyShakeAnimation(UI.label.code, tocolor(255, 0, 0, 255))
                        end
                elseif source == UI.button.generate_code then
                        if pendingCode then
                                notify({ en = "Please wait...", ar = "انتظر من فضلك..." }, 3000, "warning")
                                return
                        end
                        pendingCode = true
                        triggerServerEvent("main-menu:linkdiscord:generateCode", localPlayer)
                elseif source == UI.button.unlinkdiscord then
                        eui:uiSetVisible(UI.container.linked, false)
                        eui:uiSetVisible(UI.container.notlinked, true)
                        local charId = getElementData(localPlayer, "character:id")
                                or getElementData(localPlayer, "account:character:id")
                        triggerServerEvent("main-menu:linkdiscord:unlink", localPlayer, charId)
                        currentLinkCode = false
                elseif source == UI.button.goto_level_awards then
                        -- original jumped to the awards section row; our leaderboard row index:
                        local target = 1
                        for i, section in ipairs(SECTIONS) do
                                if section.id == "leaderboard" then target = i end
                        end
                        eui:uiMenuSetSelectedRow(menu, target)
                end
        end)

        addEvent("main-menu:linkdiscord:generateCode:callback", true)
        addEventHandler("main-menu:linkdiscord:generateCode:callback", localPlayer, function(code)
                pendingCode = false
                if code then
                        eui:uiSetText(UI.label.code, code)
                        currentLinkCode = code
                        setClipboard(code)
                end
                eui:uiLabelApplyShakeAnimation(UI.label.code, code and tocolor(0, 255, 0, 255) or tocolor(255, 55, 95, 255))
                notify({ en = "Code generated and copied", ar = "تم إنشاء ونسخ الرمز" }, 6000, "success")
        end)

        addEvent("main-menu:linkdiscord:sync", true)
        addEventHandler("main-menu:linkdiscord:sync", localPlayer, function(data)
                pendingCode = false
                eui:uiSetVisible(UI.container.notlinked, false)
                eui:uiSetVisible(UI.container.linked, true)
                eui:uiSetText(UI.label.discord_tag, data.username or "-")
                eui:uiSetText(UI.label.discord_id, "ID: " .. tostring(data.id))
                if data.avatar and data.avatar ~= "" then
                        loadBrowserURL(eui:uiGetBrowser(UI.image.avatar), data.avatar)
                end
        end)

        requestBrowserDomains({ "cdn.discordapp.com", "wnashtime.net" })

        addEventHandler("onClientUIMenuSelectChange", root, function(_, container)
                if source == menu then
                        if container == UI.container.onlinestaff then
                                triggerServerEvent("admin:showStaff", localPlayer)
                        elseif container == UI.container.leaderboard then
                                if eui:uiGetSelectedTab(UI.tabpanel.leaderboard) == UI.tab["leaderboard:levels"] then
                                        updateLeaderboard("levels")
                                elseif eui:uiGetSelectedTab(UI.tabpanel.leaderboard) == UI.tab["leaderboard:activities"] then
                                        updateLeaderboard("activities")
                                end
                        end
                end
        end)

        addEvent("admin:showStaff", true)
        addEventHandler("admin:showStaff", root, function(list)
                eui:uiGridListClear(UI.gridlist.staff)
                eui:uiGridListClear(UI.gridlist.staff2)
                if type(list) ~= "table" then return end
                local adminCount, supportCount = 0, 0
                for _, entry in ipairs(list) do
                        local isSupport = entry[1] == true
                        local hidden = entry[4] == true
                        local pid = tostring(entry[2] or "-")
                        local name = tostring(entry[3] or "-")
                        local grid = isSupport and UI.gridlist.staff2 or UI.gridlist.staff
                        local row = eui:uiGridListAddRow(grid)
                        eui:uiGridListSetItemText(grid, row, 1, "•    [" .. pid .. "]  " .. name .. "  (#ff375f" .. pid .. "#FFFFFF)")
                        eui:uiGridListSetItemText(grid, row, 2, "ID: #ff375f" .. pid)
                        eui:uiGridListSetItemText(grid, row, 3, hidden and "Hidden Admin" or "")
                        eui:uiGridListSetItemText(grid, row, 4, hidden and "#00FF00On-Duty" or "#FF0000Off-Duty")
                        if isSupport then supportCount = supportCount + 1 else adminCount = adminCount + 1 end
                end
                eui:uiGridListSetColumnText(UI.gridlist.staff2, 1, "Supports Team  (" .. supportCount .. ")")
                eui:uiGridListSetColumnText(UI.gridlist.staff, 1, "Admins Team  (" .. adminCount .. ")")
        end)

        addEventHandler("onClientUIVisibilityChange", root, function(visible)
                if visible and source == UI.window.MainMenu then
                        -- [Mod 2 fix] REAL character data from this server's account
                        -- system. The old filler read char.Info from the not-restored
                        -- roleplay exports + license keys that do not exist here
                        -- (license.Vehicles/Boats/Aircraft/Pilots), so every field
                        -- showed "-" / red "No". All keys below are verified against
                        -- account/s_characters.lua spawnCharacter (dbid, age, gender,
                        -- race, height, weight, fingerprint, hoursplayed, bankmoney,
                        -- license.car/bike/boat/pilot/gun, job, factionrank).
                        local bullet = "${color.primary}• "

                        local charId = tonumber(getElementData(localPlayer, "dbid"))
                                or tonumber(getElementData(localPlayer, "account:character:id")) or "-"
                        local charName = tostring(getPlayerName(localPlayer)):gsub("_", " ")
                        local genderVal = tonumber(getElementData(localPlayer, "gender")) or 0
                        local gender = (genderVal == 1) and { "Female", "أنثى" } or { "Male", "ذكر" }
                        local raceVal = tonumber(getElementData(localPlayer, "race"))
                        local races = { [0] = { "Black", "أسود" }, [1] = { "White", "أبيض" }, [2] = { "Asian", "آسيوي" }, [3] = { "Latino", "لاتيني" } }
                        local race = races[raceVal] or { "-", "-" }
                        local age = tonumber(getElementData(localPlayer, "age")) or "-"
                        local height = tonumber(getElementData(localPlayer, "height")) or "-"
                        local weight = tonumber(getElementData(localPlayer, "weight")) or "-"
                        local fingerprint = tostring(getElementData(localPlayer, "fingerprint") or "-")
                        if fingerprint == "" then fingerprint = "-" end
                        local job = tostring(getElementData(localPlayer, "job") or "")
                        if job == "" then job = nil end
                        local factionRank = tostring(getElementData(localPlayer, "factionrank") or "")
                        if factionRank == "" then factionRank = nil end
                        local desc = tostring(getElementData(localPlayer, "description") or "")
                        if desc == "" then desc = nil end
                        if desc and #desc > 64 then desc = desc:sub(1, 61) .. "..." end

                        eui:uiSetText(UI.label[1], {
                                en = bullet .. "Character ID »  #FFFFFF" .. tostring(charId) .. "\n"
                                        .. bullet .. "Name »  #FFFFFF" .. tostring(charName) .. "\n"
                                        .. bullet .. "Gender »  #FFFFFF" .. gender[1] .. "\n"
                                        .. bullet .. "Age »  #FFFFFF" .. tostring(age) .. " years old\n"
                                        .. bullet .. "Height »  #FFFFFF" .. tostring(height) .. " cm\n"
                                        .. bullet .. "Weight »  #FFFFFF" .. tostring(weight) .. " kg\n"
                                        .. bullet .. "Ethnicity »  #FFFFFF" .. race[1] .. "\n"
                                        .. bullet .. "Fingerprint »  #FFFFFF" .. fingerprint .. "\n"
                                        .. bullet .. "Description »  #FFFFFF" .. tostring(desc or "-"),
                                ar = bullet .. "رقم الشخصية »  #FFFFFF" .. tostring(charId) .. "\n"
                                        .. bullet .. "الاسم »  #FFFFFF" .. tostring(charName) .. "\n"
                                        .. bullet .. "الجنس »  #FFFFFF" .. gender[2] .. "\n"
                                        .. bullet .. "العمر »  #FFFFFF" .. tostring(age) .. " سنة\n"
                                        .. bullet .. "الطول »  #FFFFFF" .. tostring(height) .. " سم\n"
                                        .. bullet .. "الوزن »  #FFFFFF" .. tostring(weight) .. " كجم\n"
                                        .. bullet .. "العِرق »  #FFFFFF" .. race[2] .. "\n"
                                        .. bullet .. "بصمة الأصابع »  #FFFFFF" .. fingerprint .. "\n"
                                        .. bullet .. "الوصف »  #FFFFFF" .. tostring(desc or "-"),
                        })
                        -- [Mod 2 fix] money cards show the REAL cash + bank balance
                        local money = getPlayerMoney() or 0
                        local bank = tonumber(getElementData(localPlayer, "bankmoney")) or 0
                        eui:uiSetText(UI.label.level, {
                                en = "Cash ${color.primary}$" .. convertNumber(money),
                                ar = "المال ${color.primary}$" .. convertNumber(money),
                        })
                        eui:uiSetText(UI.label.level_exp, {
                                en = "Bank ${color.primary}$" .. convertNumber(bank),
                                ar = "البنك ${color.primary}$" .. convertNumber(bank),
                        })
                        local share = 0
                        if (money + bank) > 0 then share = math.floor(money / (money + bank) * 100) end
                        eui:uiProgressBarSetProgress(UI.progressbar[1], share)
                        local hours = tonumber(getElementData(localPlayer, "hoursplayed")) or 0
                        local minutes = math.floor((tonumber(getElementData(localPlayer, "timeinserver")) or 0))
                        eui:uiSetText(UI.label.play_time, {
                                en = "\nPlay Time\n\n" .. tostring(math.floor(hours)) .. "h " .. (minutes % 60) .. "m",
                                ar = "وقت اللعب\n\n" .. tostring(math.floor(hours)) .. " ساعة " .. (minutes % 60) .. " دقيقة",
                        })

                        -- [Mod 2 fix] licenses use the REAL keys (license.car/bike/boat/
                        -- pilot/gun) + faction rank; the old block read keys that never
                        -- existed on this server so everything showed red "No"
                        local function hasLicense(key)
                                return (tonumber(getElementData(localPlayer, key)) or 0) >= 1
                        end
                        eui:uiSetText(UI.label[4], {
                                en = bullet .. "Career »  #FFFFFF" .. tostring(job or "Unemployed") .. "\n"
                                        .. bullet .. "Faction Rank »  #FFFFFF" .. tostring(factionRank or "None") .. "\n"
                                        .. bullet .. "Car License:  #FFFFFF" .. (hasLicense("license.car") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Bike License:  #FFFFFF" .. (hasLicense("license.bike") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Boats License:  #FFFFFF" .. (hasLicense("license.boat") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Pilots License:  #FFFFFF" .. (hasLicense("license.pilot") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Gun License:  #FFFFFF" .. (hasLicense("license.gun") and "Yes" or "#FF0000No"),
                                ar = bullet .. "المهنة »  #FFFFFF" .. tostring(job or "عاطل") .. "\n"
                                        .. bullet .. "رتبة الفاشن »  #FFFFFF" .. tostring(factionRank or "لا يوجد") .. "\n"
                                        .. bullet .. "رخصة السيارة:  #FFFFFF" .. (hasLicense("license.car") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة الدراجة:  #FFFFFF" .. (hasLicense("license.bike") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة القوارب:  #FFFFFF" .. (hasLicense("license.boat") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة الطيار:  #FFFFFF" .. (hasLicense("license.pilot") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة السلاح:  #FFFFFF" .. (hasLicense("license.gun") and "نعم" or "#FF0000لا"),
                        })
                        local accName = getElementData(localPlayer, "account:username")
                        if type(accName) ~= "string" or accName == "" then accName = getPlayerName(localPlayer) end
                        eui:uiSetText(UI.label.username, accName)
                end
        end)

        addEventHandler("onClientUITabSwitched", root, function(_, tab)
                if tab == UI.tab[2] then
                        if getTickCount() - state.vehicles < 10000 then return end
                        state.vehicles = getTickCount()
                        triggerServerEvent("main-menu:characterInfo:getVehicles", localPlayer)
                elseif tab == UI.tab[3] then
                        if getTickCount() - state.interiors < 10000 then return end
                        state.interiors = getTickCount()
                        triggerServerEvent("main-menu:characterInfo:getInteriors", localPlayer)
                elseif tab == UI.tab["leaderboard:levels"] then
                        updateLeaderboard("levels")
                elseif tab == UI.tab["leaderboard:activities"] then
                        updateLeaderboard("activities")
                end
        end)

        addEvent("main-menu:characterInfo:getVehicles:callback", true)
        addEventHandler("main-menu:characterInfo:getVehicles:callback", localPlayer, function(list, slots)
                eui:uiSetText(UI.label.vehicles, "Vehicles  #FFFFFF( ${color.primary}" .. tostring(#list) .. "#ffffff / " .. tostring(slots or #list) .. " )")
                eui:uiGridListClear(UI.gridlist.vehicles)
                for _, car in ipairs(list) do
                        local row = eui:uiGridListAddRow(UI.gridlist.vehicles)
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 1, tostring(car.ID))
                        eui:uiGridListSetItemColor(UI.gridlist.vehicles, row, 1, eui:uiGetThemeColor("primary"))
                        local name = tostring(car.Name or "?")
                        if car.impounded then
                                name = name .. "  |  #FF0000(Impounded)#FFFFFF"
                        elseif car.hidden == 1 then
                                eui:uiGridListSetItemColor(UI.gridlist.vehicles, row, 2, tocolor(180, 180, 180, 255))
                                name = name .. "  |  (Hidden)"
                        end
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 2, name)
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 3, car.plate or "")
                end
        end)

        addEvent("main-menu:characterInfo:getInteriors:callback", true)
        addEventHandler("main-menu:characterInfo:getInteriors:callback", localPlayer, function(list, slots)
                eui:uiSetText(UI.label.interiors, "Interiors  #FFFFFF( ${color.primary}" .. tostring(#list) .. "#ffffff / " .. tostring(slots or #list) .. " )")
                eui:uiGridListClear(UI.gridlist.interiors)
                for _, interior in ipairs(list) do
                        local row = eui:uiGridListAddRow(UI.gridlist.interiors)
                        eui:uiGridListSetItemText(UI.gridlist.interiors, row, 1, tostring(interior.id))
                        eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 1, eui:uiGetThemeColor("primary"))
                        eui:uiGridListSetItemText(UI.gridlist.interiors, row, 2, tostring(interior.name))
                        local status = tostring(interior.status or "-")
                        if status == "rented" then
                                eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 3, tocolor(255, 255, 0))
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status .. " ($" .. tostring(interior.price or 0) .. ")")
                        elseif status == "owned" then
                                eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 3, tocolor(168, 255, 168))
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status)
                        else
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status)
                        end
                end
        end)

        addEvent("leaderboard:get:response", true)
        addEventHandler("leaderboard:get:response", localPlayer, function(kind, list)
                local grid = UI.gridlist["leaderboard:" .. tostring(kind)]
                if not grid then return end
                eui:uiGridListClear(grid)
                if type(list) ~= "table" then return end
                for rank, entry in ipairs(list) do
                        local row = eui:uiGridListAddRow(grid)
                        eui:uiGridListSetItemText(grid, row, 1, tostring(rank) .. ".")
                        eui:uiGridListSetItemText(grid, row, 2, tostring(entry.name))
                        eui:uiGridListSetItemText(grid, row, 3, tostring(kind == "levels" and entry.level or entry.points))
                end
        end)

        uiBuilt = true
end

function updateLeaderboard(kind)
        if getTickCount() - state["leaderboard:" .. kind] < 10000 then return end
        state["leaderboard:" .. kind] = getTickCount()
        triggerServerEvent("leaderboard:get", localPlayer, kind)
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)
