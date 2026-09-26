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

local LOGO_SIZE = 56 * SCALE_Y
local LOGO_X, LOGO_Y = 14 * SCALE_X, 10 * SCALE_Y

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
        -- Vortex logo on the strip
        if logoTex and state.sideX > LOGO_SIZE then
                dxDrawImage(LOGO_X, LOGO_Y, LOGO_SIZE, LOGO_SIZE, logoTex, 0, 0, 0, tocolor(255, 255, 255, 200), true)
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

function showSideBar(show)
        state.state = show
        showCursor(show)
        if show then
                state.anim = { getTickCount(), state.alpha, state.sideX, 250, 250, 350, true }
                addEventHandler("onClientRender", root, main_menu_draw, false, "high-2")
                eui:uiSetVisible(UI.window.MainMenu, true)
                eui:uiMenuSetSelectedRow(menu, 1)
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
                        -- [Vortex fix] the change-character request used to sit in
                        -- a 6s timer (leftover of the original loading-screen flow);
                        -- with no `public` loading screen on this server the player
                        -- just saw "nothing happen". Fire it IMMEDIATELY, exactly
                        -- like the proven F10 options flow.
                        addEventHandler("onClientKey", root, cancelBindsEvent)
                        showSideBar(false)
                        if resRunning("public") then
                                pcall(function() exports.public:loading("character:quit", true) end)
                        end
                        if resRunning("roleplay") then
                                pcall(function() exports.roleplay:switchOutPlayer() end)
                        else
                                -- this server's account system: real change-character flow
                                triggerServerEvent("accounts:characters:change", localPlayer, "Change Character")
                        end
                        setTimer(function()
                                if resRunning("roleplay") then
                                        triggerServerEvent("character:quit", localPlayer)
                                end
                                removeEventHandler("onClientKey", root, cancelBindsEvent)
                                if resRunning("public") then
                                        pcall(function() exports.public:loading("character:quit", false) end)
                                end
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
                        local char = getCharacter()
                        local info = char.Info or {}
                        local gender = GENDERS[tonumber(info.Gender) or -1] or "-"
                        local birth = "-"
                        if type(info.BirthDate) == "table" and info.BirthDate[1] then
                                birth = tostring(info.BirthDate[1]) .. "/" .. tostring(info.BirthDate[2]) .. "/" .. tostring(info.BirthDate[3])
                        end
                        local money = convertNumber(getPlayerMoney())
                        local level = safeExport("level-system", "getPlayerLevel") or 1
                        local levelExp = safeExport("level-system", "getPlayerExp")
                                or safeExport("level-system", "getPlayerLevel") or 0
                        local playTime = safeExport("play-time", "getCurrentPlayTime") or 0
                        local bullet = "${color.primary}• "

                        eui:uiSetText(UI.label[1], {
                                en = bullet .. "Personal ID »  #FFFFFF" .. tostring(char.ID) .. "\n"
                                        .. bullet .. "Name »  #FFFFFF" .. tostring(char.Name or "-") .. "\n"
                                        .. bullet .. "Gender »  #FFFFFF" .. gender .. "\n"
                                        .. bullet .. "Date of birth »  #FFFFFF" .. birth .. "\n"
                                        .. bullet .. "Age »  #FFFFFF" .. tostring(info.Age or "-") .. " years old\n"
                                        .. bullet .. "Fingerprints »  #FFFFFF" .. tostring(info.FingerPrint or "-") .. "\n"
                                        .. bullet .. "Country »  #FFFFFF" .. tostring(char.country and COUNTRIES[char.country] or "Unknown") .. "\n"
                                        .. bullet .. "Career »  #FFFFFF" .. (getElementData(localPlayer, "job") or "Unemployed") .. "\n\n"
                                        .. bullet .. "Money »  #00FF00$" .. money .. "\n"
                                        .. bullet .. "Main Bank Account »  #FFFFFF" .. tostring(info.BankAccount or "Not Found"),
                                ar = bullet .. "رقم الشخصية »  #FFFFFF" .. tostring(char.ID) .. "\n"
                                        .. bullet .. "الاسم »  #FFFFFF" .. tostring(char.Name or "-") .. "\n"
                                        .. bullet .. "الجنس »  #FFFFFF" .. gender .. "\n"
                                        .. bullet .. "تاريخ الميلاد »  #FFFFFF" .. birth .. "\n"
                                        .. bullet .. "العمر »  #FFFFFF" .. tostring(info.Age or "-") .. " سنة\n"
                                        .. bullet .. "بصمة الأصابع »  #FFFFFF" .. tostring(info.FingerPrint or "-") .. "\n"
                                        .. bullet .. "الجنسية »  #FFFFFF" .. tostring(char.country and COUNTRIES[char.country] or "Unknown") .. "\n"
                                        .. bullet .. "المهنة »  #FFFFFF" .. (getElementData(localPlayer, "job") or "Unemployed") .. "\n"
                                        .. bullet .. "المال »  #00FF00$" .. money .. "\n"
                                        .. bullet .. "الحساب البنكي الرئيسي »  #FFFFFF" .. tostring(info.BankAccount or "لا يوجد"),
                        })
                        eui:uiSetText(UI.label.level, "Level ${color.primary} " .. tostring(level))
                        eui:uiSetText(UI.label.level_exp, tostring(levelExp) .. " / " .. tostring(level))
                        eui:uiSetText(UI.label.play_time, {
                                en = "\nPlay Time\n\n" .. convertTimeToString(playTime),
                                ar = "وقت اللعب\n\n" .. convertTimeToString(playTime),
                        })
                        eui:uiProgressBarSetProgress(UI.progressbar[1], tonumber(level) or 1)

                        local marital = info.marital_status or "Single"
                        local languages = ""
                        for _, lang in ipairs(info.Languages or { "English" }) do
                                languages = languages .. "${color.primary}  » #FFFFFF" .. tostring(lang) .. " (100%)\n"
                        end
                        eui:uiSetText(UI.label[4], {
                                en = bullet .. "Marital Status »  #FFFFFF" .. tostring(marital) .. "\n\n\n"
                                        .. bullet .. "Languages: #FFFFFF\n" .. languages .. "\n"
                                        .. bullet .. "Cars Driving License:  #FFFFFF" .. (getElementData(localPlayer, "license.Vehicles") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Boats Driving License:  #FFFFFF" .. (getElementData(localPlayer, "license.Boats") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Aircraft Driving License:  #FFFFFF" .. (getElementData(localPlayer, "license.Aircraft") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Pilots License:  #FFFFFF" .. (getElementData(localPlayer, "license.Pilots") and "Yes" or "#FF0000No"),
                                ar = bullet .. "الحالة الاجتماعية »  #FFFFFF" .. tostring(marital == "Married" and "متزوج" or "أعزب") .. "\n\n\n"
                                        .. bullet .. "اللغات: #FFFFFF\n" .. languages .. "\n"
                                        .. bullet .. "رخصة قيادة السيارات:  #FFFFFF" .. (getElementData(localPlayer, "license.Vehicles") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة قيادة القوارب:  #FFFFFF" .. (getElementData(localPlayer, "license.Boats") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة قيادة الطائرات:  #FFFFFF" .. (getElementData(localPlayer, "license.Aircraft") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة الطيار:  #FFFFFF" .. (getElementData(localPlayer, "license.Pilots") and "نعم" or "#FF0000لا"),
                        })
                        local accName = getElementData(localPlayer, "character:account")
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
