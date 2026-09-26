--[[ ------------------------------------------------------------------------
        Vortex Staff Panel (/staffs) — faithful 1:1 port of the original
        rp-admin client (admin_c_decompiled.lua, UIKit build).

        Layout is the ORIGINAL, element for element:
          window 905x575 (rounded, dark) with a 150px sidebar menu and a
          content panel per section:
            staffs             grid: Rank / Username / Reports # / Feedback
            roles_members      grid: Role / Username
            changelogs         search + grid: Date/Time/Action/Username/From/To/By
            ranks              ranks grid + permissions grid + color + save
            daily_staff_report grid: Username/Login/Logout/Attendance/Jails/Bans/Reports
          plus: add-staff window, delete-staff dialog, delete-rank dialog.

        Server bridge (rpadmin:* events) is restored in staff_manager_s.lua.

        Vortex deltas (same decisions as the F1 main-menu port):
          - UIKit theme_1.lua supplies the Vortex blue/purple (replaces the
            original's red accents everywhere except functional green/red
            permission colors and the destructive button text)
          - sidebar rows distributed across the FULL menu height (fix #3)
          - sidebar rows use PNG icons tinted Vortex blue (fix #2 — emoji
            glyphs tofu out in MTA, so the icon mechanism is used)
          - rounded corners everywhere (fix #1)
          - the legacy gui* "Staff Manager" and "Places" windows from the
            decompiled file are NOT ported: the UIKit build replaced them.
            The PlacesList window had no trigger source left on this server.

        Rebuild guard: onClientUIReady + onClientUIKitReady both can fire
        (and UIKit may restart while the panel is open) — a COMPLETED build
        is kept, an ABORTED one is discarded and rebuilt.
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

--[[ ============================== state ============================== ]]

local UI = {
        tab = {}, progressbar = {}, edit = {}, window = {}, label = {}, checkbox = {},
        switch = {}, button = {}, tabpanel = {}, radiobutton = {}, gridlist = {},
        memo = {}, scrollbar = {}, combobox = {}, container = {}, image = {},
        rectangle = {}, dialog = {},
}

local eui = exports.UIKit
local menu = false
local uiBuilt = false

local rank_to_delete = nil      -- role id pending delete-confirmation
local currentColorLabel = nil   -- which element the color picker writes to
local RankColor = { 255, 255, 255, 255 }

local LevelNames = {}           -- [roleID] = name
local LevelRights = {}          -- [roleID] = { right = true }
local LevelColor = {}           -- [roleID] = {r,g,b,a}
local getLevelByName = {}       -- [name] = roleID

local panelData = { changelogs = {} }

--[[ sidebar sections — reconstructed menu table (the decompiler collapsed
     the original config into `var0`; ids are the ones the code builds
     content for, permissions from reloadAdminPanelMenu/showPanel logic) ]]
local SECTIONS = {
        { id = "staffs",             en = "Staffs",        ar = "الهيئة",           icon = "icons/menu_shield.png", permission = false },
        { id = "roles_members",      en = "Role Members",  ar = "أعضاء الرتب",      icon = "icons/menu_person.png", permission = "editmembers" },
        { id = "changelogs",         en = "Changelogs",    ar = "سجل التغييرات",    icon = "icons/menu_chat.png",   permission = false },
        { id = "ranks",              en = "Ranks",         ar = "الرتب",            icon = "icons/menu_trophy.png", permission = "editranks" },
        { id = "daily_staff_report", en = "Daily Report",  ar = "تقرير اليوم",      icon = "icons/menu_globe.png",  permission = false },
}

--[[ layout constants — straight from the decompiled code ]]
local PANEL_W, PANEL_H = 905, 575
local MENU_W = 150
local CONTENT_X = MENU_W + 10             -- 160
local CONTENT_W = PANEL_W - MENU_W - 15   -- 740
local CONTENT_H = PANEL_H - 10            -- 565

local function themeColor(name)
        local ok, c = pcall(eui.uiGetThemeColor, eui, name)
        if ok and c then return c end
        return tocolor(94, 76, 252) -- Vortex blue fallback
end

--[[ ===================== UIKit construction (1:1) ===================== ]]

function UIKitReady()
        if UI.window.admin_panel and isElement(UI.window.admin_panel) then
                if uiBuilt then return end
                destroyElement(UI.window.admin_panel)
        end
        eui = exports.UIKit

        UI.window.admin_panel = eui:uiCreateRectangle(false, false, PANEL_W, PANEL_H,
                tocolor(6, 9, 14, 235), true, true, true, true)
        eui:uiSetVisible(UI.window.admin_panel, false)
        eui:uiBringToFront(UI.window.admin_panel)

        UI.image.title_logo = eui:uiCreateImage(15, 12, 32, 32, "icons/menu_shield.png", UI.window.admin_panel)
        UI.label.MainMenuTitle = eui:uiCreateLabel(55, 10, 200, 45, "Admin Panel",
                tocolor(255, 255, 255), "left", "center", UI.window.admin_panel)
        eui:uiSetFont(UI.label.MainMenuTitle, "default-large")

        UI.button.close_panel = eui:uiCreateButton(5, PANEL_H - 45, 150, 40,
                { en = "Close", ar = "إغلاق" }, tocolor(6, 9, 14, 255), UI.window.admin_panel)
        eui:uiSetProperty(UI.button.close_panel, "HoverTextColor", tocolor(255, 0, 0))

        -- one rounded content panel + container per section
        for _, section in ipairs(SECTIONS) do
                local panel = eui:uiCreateRectangle(CONTENT_X, 5, CONTENT_W, CONTENT_H,
                        tocolor(11, 14, 19, 230), true, true, true, true, UI.window.admin_panel)
                UI.container[section.id] = eui:uiCreateContainer(0, 0, CONTENT_W, CONTENT_H, panel)
                eui:uiSetVisible(UI.container[section.id], false)
                UI.label.title = eui:uiCreateLabel(15, 10, 200, 30,
                        { en = section.en, ar = section.ar }, themeColor("primary"),
                        "left", "center", UI.container[section.id])
                eui:uiSetFont(UI.label.title, "default-large")
        end

        --[[ ----------------------- staffs section ----------------------- ]]
        UI.gridlist.staffs = eui:uiCreateGridList(10, 60, CONTENT_W - 20, PANEL_H - 10 - 120,
                tocolor(10, 10, 10, 0), UI.container.staffs)
        eui:uiGridListAddColumn(UI.gridlist.staffs, "Rank", 0.27)
        eui:uiGridListAddColumn(UI.gridlist.staffs, "Username", 0.28)
        eui:uiGridListAddColumn(UI.gridlist.staffs, "Reports #", 0.13)
        eui:uiGridListAddColumn(UI.gridlist.staffs, "Feedback Rating", 0.18)
        eui:uiGridListAddColumn(UI.gridlist.staffs, "Feedback #", 0.14)
        eui:uiSetAlign(UI.gridlist.staffs, "left", "center")
        eui:uiSetProperty(UI.gridlist.staffs, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.staffs, "column_font_scale", 0.8)
        eui:uiSetProperty(UI.gridlist.staffs, "row_height", 30)

        UI.button.delete_admin = eui:uiCreateButton(10, PANEL_H - 10 - 45, 150, 35,
                { en = "Remove", ar = "إزالة" }, tocolor(6, 9, 14, 255), UI.container.staffs)
        eui:uiSetProperty(UI.button.delete_admin, "TextColor", tocolor(255, 0, 0))
        UI.button.add_admin = eui:uiCreateButton(170, PANEL_H - 10 - 45, 150, 35,
                { en = "Add", ar = "إضافة" }, tocolor(6, 9, 14, 255), UI.container.staffs)

        --[[ ----------------------- add staff window ----------------------- ]]
        UI.window.add_staff = eui:uiCreateRectangle(false, false, 400, 390,
                tocolor(6, 9, 14, 235), true, true, true, true)
        eui:uiSetVisible(UI.window.add_staff, false)
        UI.label.add_staff = eui:uiCreateLabel(10, 15, 232, 20,
                { en = "Add Staff", ar = "إضافة للهيئة" }, tocolor(255, 255, 255, 255),
                "left", "top", UI.window.add_staff)
        eui:uiSetFont(UI.label.add_staff, "default-large")
        UI.edit.add_staff_account = eui:uiCreateEdit(10, 50, 380, 25, "", "Username",
                tocolor(255, 0, 0, 255), UI.window.add_staff)
        UI.gridlist.add_staff_ranks = eui:uiCreateGridList(10, 90, 380, 250,
                tocolor(6, 9, 14, 255), UI.window.add_staff)
        eui:uiGridListAddColumn(UI.gridlist.add_staff_ranks, "Rank Name", 1)
        eui:uiSetAlign(UI.gridlist.add_staff_ranks, "left", "center")
        eui:uiSetProperty(UI.gridlist.add_staff_ranks, "row_height", 25)
        UI.button.cancel_add_staff = eui:uiCreateButton(10, 345, 185, 35,
                { en = "Cancel", ar = "إلغاء" }, tocolor(3, 6, 11), UI.window.add_staff)
        UI.button.add_staff = eui:uiCreateButton(200, 345, 190, 35,
                { en = "Add", ar = "إضافة" }, tocolor(3, 6, 11), UI.window.add_staff)

        --[[ ----------------------- delete staff dialog ----------------------- ]]
        UI.dialog.delete_staff = eui:uiCreateDialog(false, false, 300, 160, "Confirm")
        eui:uiSetVisible(UI.dialog.delete_staff, false)
        UI.label.delete_staff = eui:uiCreateLabel(10, 50, 280, 30,
                { en = "Are you sure you want to delete this staff?",
                  ar = "هل أنت متأكد من حذف هذا الإداري؟" },
                tocolor(255, 255, 255, 230), "center", "center", UI.dialog.delete_staff)
        UI.label.delete_staff_username = eui:uiCreateLabel(10, 80, 280, 30, "Username",
                tocolor(255, 255, 255, 255), "center", "center", UI.dialog.delete_staff)
        eui:uiSetFont(UI.label.delete_staff_username, "default-large")
        eui:uiDialogSetLeftButtonText(UI.dialog.delete_staff, "Yes")
        eui:uiDialogSetRightButtonText(UI.dialog.delete_staff, "No")

        --[[ ----------------------- role members section ----------------------- ]]
        UI.gridlist.roles_members = eui:uiCreateGridList(10, 60, CONTENT_W - 20, PANEL_H - 10 - 120,
                tocolor(10, 10, 10, 0), UI.container.roles_members)
        eui:uiGridListAddColumn(UI.gridlist.roles_members, "Role", 0.4)
        eui:uiGridListAddColumn(UI.gridlist.roles_members, "Username", 0.6)
        eui:uiSetAlign(UI.gridlist.roles_members, "left", "center")
        eui:uiSetProperty(UI.gridlist.roles_members, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.roles_members, "column_font_scale", 0.8)
        eui:uiSetProperty(UI.gridlist.roles_members, "row_height", 30)

        --[[ ----------------------- changelogs section ----------------------- ]]
        UI.edit.changelogs_search = eui:uiCreateEdit(CONTENT_W - 310, 15, 300, 25, "",
                { en = "Search...", ar = "بحث..." }, tocolor(255, 0, 0, 255), UI.container.changelogs)
        UI.gridlist.changelogs = eui:uiCreateGridList(10, 60, CONTENT_W - 20, PANEL_H - 10 - 60 - 10,
                tocolor(10, 10, 10, 0), UI.container.changelogs)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "Date", 0.1)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "Time", 0.1)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "Action", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "Username", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "From", 0.125)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "To", 0.125)
        eui:uiGridListAddColumn(UI.gridlist.changelogs, "By", 0.2)
        eui:uiSetAlign(UI.gridlist.changelogs, "left", "center")
        eui:uiSetProperty(UI.gridlist.changelogs, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.changelogs, "column_font_scale", 0.8)
        eui:uiSetProperty(UI.gridlist.changelogs, "row_height", 30)

        --[[ ----------------------- ranks section ----------------------- ]]
        local ranksW = (CONTENT_W - 20) * 0.3
        local permsX = 10 + ranksW + 5
        local permsW = (CONTENT_W - 20) * 0.7 - 5

        UI.gridlist.ranks = eui:uiCreateGridList(10, 60, ranksW, PANEL_H - 10 - 120,
                tocolor(6, 9, 14, 235), UI.container.ranks)
        eui:uiGridListAddColumn(UI.gridlist.ranks, "Ranks", 1)
        eui:uiSetAlign(UI.gridlist.ranks, "left", "center")
        eui:uiSetProperty(UI.gridlist.ranks, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.ranks, "row_height", 25)
        eui:uiSetProperty(UI.gridlist.ranks, "column_height", 35)
        eui:uiSetProperty(UI.gridlist.ranks, "column_font_scale", 0.8)

        UI.gridlist.permissions = eui:uiCreateGridList(permsX, 100, permsW,
                PANEL_H - 10 - 60 - 100 - 30, tocolor(6, 9, 14, 235), UI.container.ranks)
        eui:uiGridListAddColumn(UI.gridlist.permissions, "Permissions", 1)
        eui:uiSetAlign(UI.gridlist.permissions, "left", "center")
        eui:uiSetProperty(UI.gridlist.permissions, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.permissions, "column_font_scale", 0.8)
        eui:uiSetProperty(UI.gridlist.permissions, "row_height", 25)

        UI.checkbox.permissions_select_all = eui:uiCreateCheckBox(permsX,
                PANEL_H - 10 - 60 - 20, 150, 25, "Select All", false,
                themeColor("primary"), UI.container.ranks)
        eui:uiSetFontSize(UI.checkbox.permissions_select_all, 0.8)

        for _, right in ipairs(AllRights) do
                eui:uiGridListSetItemText(UI.gridlist.permissions,
                        eui:uiGridListAddRow(UI.gridlist.permissions), 1, tostring(right))
        end

        UI.label.rank_id = eui:uiCreateLabel(permsX + 10, 65, 50, 24, "#0",
                themeColor("primary"), "left", "center", UI.container.ranks)
        eui:uiSetFont(UI.label.rank_id, "default-large")
        UI.edit.rank_name = eui:uiCreateEdit(permsX + 55, 65, 300, 25, "", "Rank Name",
                tocolor(255, 0, 0, 255), UI.container.ranks)
        eui:uiSetProperty(UI.edit.rank_name, "UnderLineVisible", "False")
        eui:uiSetFont(UI.edit.rank_name, "default-large")
        UI.rectangle.rank_color = eui:uiCreateRectangle(PANEL_W - MENU_W - 15 - 60, 65, 50, 25,
                tocolor(255, 255, 255, 255), false, false, false, false, UI.container.ranks)

        UI.button.delete_rank = eui:uiCreateButton(10, PANEL_H - 10 - 45, 150, 35,
                { en = "Delete Rank", ar = "حذف الرتبة" }, tocolor(6, 9, 14, 255), UI.container.ranks)
        eui:uiSetProperty(UI.button.delete_rank, "TextColor", tocolor(255, 0, 0))
        UI.button.add_rank = eui:uiCreateButton(170, PANEL_H - 10 - 45, 150, 35,
                { en = "Add Rank", ar = "إضافة رتبة" }, tocolor(6, 9, 14, 255), UI.container.ranks)
        UI.button.save_rank_changes = eui:uiCreateButton(PANEL_W - MENU_W - 15 - 160,
                PANEL_H - 10 - 45, 150, 35, { en = "Save Changes", ar = "حفظ التغييرات" },
                tocolor(6, 9, 14, 255), UI.container.ranks)

        UI.dialog.delete_rank = eui:uiCreateDialog(false, false, 300, 160, "Confirm")
        eui:uiSetVisible(UI.dialog.delete_rank, false)
        UI.label.delete_rank = eui:uiCreateLabel(10, 50, 280, 30,
                { en = "Are you sure you want to delete this rank?",
                  ar = "هل أنت متأكد من حذف هذه الرتبة؟" },
                tocolor(255, 255, 255, 230), "center", "center", UI.dialog.delete_rank)
        UI.label.delete_rank_name = eui:uiCreateLabel(10, 80, 280, 30, "Rank Name",
                tocolor(255, 255, 255, 255), "center", "center", UI.dialog.delete_rank)
        eui:uiSetFont(UI.label.delete_rank_name, "default-large")
        eui:uiDialogSetLeftButtonText(UI.dialog.delete_rank, "Yes")
        eui:uiDialogSetRightButtonText(UI.dialog.delete_rank, "No")

        --[[ ----------------------- daily report section ----------------------- ]]
        UI.gridlist.daily_staff_report = eui:uiCreateGridList(10, 60, CONTENT_W - 20,
                PANEL_H - 10 - 120, tocolor(10, 10, 10, 0), UI.container.daily_staff_report)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Username", 0.25)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Login", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Logout", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Attendance", 0.15)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Jails", 0.1)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Bans", 0.1)
        eui:uiGridListAddColumn(UI.gridlist.daily_staff_report, "Reports", 0.1)
        eui:uiSetAlign(UI.gridlist.daily_staff_report, "left", "center")
        eui:uiSetProperty(UI.gridlist.daily_staff_report, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.daily_staff_report, "column_font_scale", 0.8)
        eui:uiSetProperty(UI.gridlist.daily_staff_report, "row_height", 30)

        --[[ ----------------------- sidebar menu -----------------------
             Vortex lab-style sidebar: compact top-aligned rows on a soft
             card, Vortex-blue accent bar on the selected row (fixes the
             solid black box look) ]]
        local MENU_H = 300
        menu = eui:uiCreateMenu(5, 65, MENU_W, MENU_H, tocolor(19, 22, 27, 120),
                UI.window.admin_panel)
        eui:uiSetProperty(menu, "hovered_row_color", tocolor(9, 12, 17, 110))
        eui:uiSetProperty(menu, "selected_row_color", tocolor(13, 16, 22, 235))
        -- rows are stored pre-scaled by SCALE_Y and drawn with a SECOND
        -- SCALE_Y factor + 4px gap, so divide the per-row budget by SCALE_Y^2
        -- to actually fill MENU_H without overflowing it
        local rowHeight = ((MENU_H - 10) / #SECTIONS - 4) / (SCALE_Y * SCALE_Y)
        eui:uiSetProperty(menu, "row_height", rowHeight)
        eui:uiSetProperty(menu, "row_font_scale", 1.2)
        eui:uiSetProperty(menu, "icons_color", themeColor("primary"))
        eui:uiSetProperty(menu, "selection_color", themeColor("primary"))
        setElementID(menu, "staff-panel-menu")

        uiBuilt = true
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

--[[ ===================== sidebar menu (1:1) ===================== ]]

function reloadAdminPanelMenu(hasEditMembers, hasEditRanks)
        eui:uiMenuClear(menu)
        for _, section in ipairs(SECTIONS) do
                local allowed = not section.permission
                        or (section.permission == "editmembers" and hasEditMembers)
                        or (section.permission == "editranks" and hasEditRanks)
                if allowed then
                        eui:uiMenuAddRow(menu, { en = section.en, ar = section.ar },
                                tocolor(29, 32, 37, 0), section.icon, UI.container[section.id], section.id)
                end
        end
        eui:uiMenuSetSelectedRow(menu, 1)
end

--[[ ===================== events + handlers (1:1) ===================== ]]

addEvent("rpadmin:showPanel", true)
addEventHandler("rpadmin:showPanel", root, function(hasEditMembers, hasEditRanks, hasResources, data)
        if not (UI.window.admin_panel and isElement(UI.window.admin_panel)) then
                UIKitReady() -- UIKit restarted while we were closed: rebuild
        end
        eui:uiSetVisible(UI.window.admin_panel, not eui:uiGetVisible(UI.window.admin_panel))
        showCursor(eui:uiGetVisible(UI.window.admin_panel))
        eui:uiSetVisible(UI.button.delete_admin, hasEditMembers and true or false)
        eui:uiSetVisible(UI.button.add_admin, hasEditMembers and true or false)
        reloadAdminPanelMenu(hasEditMembers, hasEditRanks)
        if eui:uiGetVisible(UI.window.admin_panel) and type(data) == "table" then
                refreshPanel(data.levels, data.admins, data.changelogs, {},
                        data.role_members, data.staff_report)
        end
end)

addEventHandler("onClientUIChanged", root, function()
        if source == UI.edit.changelogs_search and panelData.changelogs then
                local text = eui:uiGetText(source)
                eui:uiGridListClear(UI.gridlist.changelogs)
                if text ~= "" then
                        for _, c in ipairs(panelData.changelogs) do
                                if string.find(c.cType or "", text, 1, true)
                                        or string.find(c.Username or "", text, 1, true)
                                        or string.find(c.FromR or "", text, 1, true)
                                        or string.find(c.ToR or "", text, 1, true)
                                        or string.find(c.By_ or "", text, 1, true)
                                        or string.find(c.Date or "", text, 1, true) then
                                        insertChangelogRow(c)
                                end
                        end
                else
                        for _, c in ipairs(panelData.changelogs) do
                                insertChangelogRow(c)
                        end
                end
        end
end)

addEventHandler("onClientUIDialogButtonClick", root, function(button)
        if source == UI.dialog.delete_staff then
                if button == "left" then
                        triggerServerEvent("rpadmin:removeAdmin", localPlayer,
                                eui:uiGetText(UI.label.delete_staff_username))
                end
        elseif source == UI.dialog.delete_rank then
                if button == "left" and rank_to_delete then
                        triggerServerEvent("rpadmin:removeAdminLevel", localPlayer, rank_to_delete)
                end
                rank_to_delete = nil
        end
end)

addEventHandler("onClientUIClick", root, function()
        if not (UI.window.admin_panel and isElement(UI.window.admin_panel)) then return end

        -- ranks grid: select a rank -> load its rights + color
        if source == UI.gridlist.ranks then
                local sel = eui:uiGridListGetSelectedItem(source)
                if sel ~= -1 then
                        local roleID = eui:uiGridListGetItemData(source, sel, 1)
                        eui:uiSetText(UI.edit.rank_name, eui:uiGridListGetItemText(source, sel, 1))
                        eui:uiSetText(UI.label.rank_id, "#" .. tostring(roleID))
                        for i, right in ipairs(AllRights) do
                                local enabled = false
                                local rights = LevelRights[tostring(roleID)]
                                if rights and type(rights) == "table" then
                                        enabled = rights[tostring(right)] and true or false
                                end
                                eui:uiGridListSetItemData(UI.gridlist.permissions, i - 1, 1, enabled)
                                if enabled then
                                        eui:uiGridListSetItemColor(UI.gridlist.permissions, i - 1, 1, tocolor(0, 255, 0))
                                else
                                        eui:uiGridListSetItemColor(UI.gridlist.permissions, i - 1, 1, tocolor(255, 0, 0))
                                end
                        end
                        currentColorLabel = UI.rectangle.rank_color
                        local color = LevelColor[tostring(roleID)]
                        RankColor = color and { unpack(color) } or { 255, 255, 255, 255 }
                        eui:uiSetColor(UI.rectangle.rank_color, unpack(color or { 255, 255, 255, 255 }))
                end

        elseif source == UI.rectangle.rank_color then
                currentColorLabel = UI.rectangle.rank_color
                colorPicker.openSelect(unpack(RankColor))

        elseif source == UI.checkbox.permissions_select_all then
                local selected = eui:uiCheckBoxGetSelected(source)
                for row = 0, eui:uiGridListGetRowCount(UI.gridlist.permissions) - 1 do
                        eui:uiGridListSetItemData(UI.gridlist.permissions, row, 1, selected and true or false)
                        if selected then
                                eui:uiGridListSetItemColor(UI.gridlist.permissions, row, 1, tocolor(0, 255, 0))
                        else
                                eui:uiGridListSetItemColor(UI.gridlist.permissions, row, 1, tocolor(255, 0, 0))
                        end
                end

        elseif source == UI.button.delete_rank then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.ranks)
                if sel ~= -1 then
                        eui:uiSetVisible(UI.dialog.delete_rank, true)
                        eui:uiSetText(UI.label.delete_rank_name,
                                eui:uiGridListGetItemText(UI.gridlist.ranks, sel, 1))
                        rank_to_delete = eui:uiGridListGetItemData(UI.gridlist.ranks, sel, 1)
                end

        elseif source == UI.button.add_rank then
                if eui:uiGetText(UI.edit.rank_name) ~= "" then
                        triggerServerEvent("rpadmin:addAdminLevel", localPlayer,
                                eui:uiGetText(UI.edit.rank_name))
                        eui:uiSetText(UI.edit.rank_name, "")
                end

        elseif source == UI.button.save_rank_changes then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.ranks)
                if sel ~= -1 then
                        -- accumulate the CHECKED rights only (the decompiler lost this
                        -- accumulator into `({})[key] = value` — rebuilt here)
                        local rights = {}
                        for row = 0, eui:uiGridListGetRowCount(UI.gridlist.permissions) - 1 do
                                if eui:uiGridListGetItemData(UI.gridlist.permissions, row, 1) then
                                        rights[eui:uiGridListGetItemText(UI.gridlist.permissions, row, 1)] = true
                                end
                        end
                        triggerServerEvent("rpadmin:updateRole", localPlayer,
                                eui:uiGridListGetItemData(UI.gridlist.ranks, sel, 1), nil, rights,
                                { unpack(RankColor or { 255, 255, 255, 255 }) })
                end

        elseif source == UI.button.delete_admin then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.staffs)
                if sel ~= -1 then
                        eui:uiSetVisible(UI.dialog.delete_staff, true)
                        eui:uiSetText(UI.label.delete_staff_username,
                                eui:uiGridListGetItemText(UI.gridlist.staffs, sel, 2))
                end

        elseif source == UI.button.add_admin then
                eui:uiSetVisible(UI.window.add_staff, true)
                eui:uiBringToFront(UI.window.add_staff)

        elseif source == UI.button.add_staff then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.add_staff_ranks)
                if #eui:uiGetText(UI.edit.add_staff_account) ~= 0 and sel ~= -1 then
                        triggerServerEvent("rpadmin:addNewAdmin", localPlayer,
                                eui:uiGetText(UI.edit.add_staff_account),
                                eui:uiGridListGetItemData(UI.gridlist.add_staff_ranks, sel, 1),
                                eui:uiGridListGetItemText(UI.gridlist.add_staff_ranks, sel, 1))
                        eui:uiSetVisible(UI.window.add_staff, false)
                        eui:uiSetText(UI.edit.add_staff_account, "")
                end

        elseif source == UI.button.cancel_add_staff then
                eui:uiSetVisible(UI.window.add_staff, false)

        elseif source == UI.button.close_panel then
                eui:uiSetVisible(UI.window.admin_panel, false)
                eui:uiSetVisible(UI.window.add_staff, false)
                showCursor(false)
        end
end)

addEventHandler("onClientUIDoubleClick", root, function()
        if source == UI.gridlist.permissions
                and eui:uiGridListGetSelectedItem(source) ~= -1 then
                local sel = eui:uiGridListGetSelectedItem(source)
                local state = not eui:uiGridListGetItemData(source, sel, 1)
                eui:uiGridListSetItemData(source, sel, 1, state)
                if state then
                        eui:uiGridListSetItemColor(source, sel, 1, tocolor(0, 255, 0))
                else
                        eui:uiGridListSetItemColor(source, sel, 1, tocolor(255, 0, 0))
                end
        end
end)

-- color picker confirmations
addEvent("onClientColorPickerConfirm", true)
addEventHandler("onClientColorPickerConfirm", root, function(r, g, b, a)
        if not currentColorLabel then return end
        if isElement(currentColorLabel) then
                eui:uiSetColor(currentColorLabel, r, g, b, a or 255)
        end
        if currentColorLabel == UI.rectangle.rank_color then
                RankColor = { r, g, b, a or 255 }
        end
        currentColorLabel = nil
end)

--[[ ===================== data refresh (1:1, row-safe) ===================== ]]

function msToTimeStr(seconds)
        seconds = tonumber(seconds)
        if not seconds then return "" end
        seconds = math.floor(seconds)
        if seconds < 0 then return "00:00:00" end
        return ("%.2d:%.2d:%.2d"):format(math.floor(seconds / 3600),
                math.floor(seconds / 60) % 60, seconds % 60)
end

function insertChangelogRow(c)
        local row = eui:uiGridListAddRow(UI.gridlist.changelogs)
        local datePart = tostring(split(tostring(c.Date or ""), " ")[1] or "")
        local timePart = tostring(split(tostring(c.Date or ""), " ")[2] or "")
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 1, datePart)
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 2, timePart)
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 3, tostring(c.cType or ""))
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 4, tostring(c.Username or ""))
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 5, tostring(c.FromR or ""))
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 6, tostring(c.ToR or ""))
        eui:uiGridListSetItemText(UI.gridlist.changelogs, row, 7, tostring(c.By_ or ""))
        local color = false
        if c.cType == "Promotion" then
                color = tocolor(0, 255, 0)
        elseif c.cType == "Demotion" then
                color = tocolor(255, 0, 0)
        end
        if color then
                for col = 1, 7 do
                        eui:uiGridListSetItemColor(UI.gridlist.changelogs, row, col, color)
                end
        end
end

-- the decompiled loop called uiGridListAddRow inside EVERY SetItemText /
-- SetItemColor call (a lost local row variable) which duplicated rows; a
-- single row index is captured here instead, exactly like the original.
function refreshPanel(levels, admins, changelogs, resources, roleMembers, staffReport)
        panelData.changelogs = changelogs or {}

        --[[ daily staff report ]]
        if staffReport then
                eui:uiGridListClear(UI.gridlist.daily_staff_report)
                for _, r in ipairs(staffReport) do
                        local row = eui:uiGridListAddRow(UI.gridlist.daily_staff_report)
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 1,
                                tostring(r.username))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 2,
                                tostring(r.login_time and split(r.login_time, " ")[2] or "-"))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 3,
                                tostring(r.logout_time and split(r.logout_time, " ")[2] or "-"))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 4,
                                tostring(msToTimeStr(r.total_attendance_time)))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 5, tostring(r.jails))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 6, tostring(r.bans))
                        eui:uiGridListSetItemText(UI.gridlist.daily_staff_report, row, 7, tostring(r.reports))
                        if tonumber(r.jails) and tonumber(r.jails) > 0 then
                                eui:uiGridListSetItemColor(UI.gridlist.daily_staff_report, row, 5, tocolor(0, 255, 0))
                        end
                        if tonumber(r.bans) and tonumber(r.bans) > 0 then
                                eui:uiGridListSetItemColor(UI.gridlist.daily_staff_report, row, 6, tocolor(0, 255, 0))
                        end
                        if tonumber(r.reports) and tonumber(r.reports) > 0 then
                                eui:uiGridListSetItemColor(UI.gridlist.daily_staff_report, row, 7, tocolor(0, 255, 0))
                        end
                end
        end

        --[[ role tables ]]
        LevelNames = {}
        LevelRights = {}
        LevelColor = {}
        getLevelByName = {}
        for _, level in ipairs(levels or {}) do
                LevelNames[tostring(level.ID)] = tostring(level.LevelName)
                local rights = fromJSON(level.Rights or "{}")
                LevelRights[tostring(level.ID)] = type(rights) == "table" and rights or {}
                local color = fromJSON(level.Color or "[[255,255,255,255]]")
                LevelColor[tostring(level.ID)] = type(color) == "table" and color or { 255, 255, 255, 255 }
                getLevelByName[tostring(level.LevelName)] = tostring(level.ID)
        end

        --[[ staffs list ]]
        eui:uiGridListClear(UI.gridlist.staffs)
        table.sort(admins or {}, function(a, b)
                local ida, idb = tonumber(a.AdminID) or 0, tonumber(b.AdminID) or 0
                if ida == idb then
                        local ra = tonumber(a.FeedbackRating) / math.max(tonumber(a.FeedbackCount), 1)
                        local rb = tonumber(b.FeedbackRating) / math.max(tonumber(b.FeedbackCount), 1)
                        return ra > rb
                end
                return ida < idb
        end)
        for _, staff in ipairs(admins or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.staffs)
                local color = LevelColor[tostring(staff.AdminID)] or { 255, 255, 255 }
                local rating = 0
                if tonumber(staff.FeedbackCount) and tonumber(staff.FeedbackCount) > 0 then
                        rating = tonumber(staff.FeedbackRating) / tonumber(staff.FeedbackCount)
                end
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 1,
                        tostring(LevelNames[tostring(staff.AdminID)] or "N/A"))
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 2, tostring(staff.Account))
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 3,
                        tostring(staff.ReportsCount or 0))
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 4,
                        string.format("%0.3f", rating))
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 5,
                        tostring(staff.FeedbackCount or 0))
                -- design (preview 01): ONLY the rank column carries the rank
                -- color; username/reports/rating/feedback stay white
                eui:uiGridListSetItemColor(UI.gridlist.staffs, row, 1,
                        tocolor(color[1] or 255, color[2] or 255, color[3] or 255, color[4] or 255))
        end

        --[[ role members ]]
        eui:uiGridListClear(UI.gridlist.roles_members)
        for _, member in ipairs(roleMembers or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.roles_members)
                eui:uiGridListSetItemText(UI.gridlist.roles_members, row, 1,
                        tostring(LevelNames[tostring(member.RoleID)] or "N/A") .. " (#" .. tostring(member.RoleID) .. ")")
                eui:uiGridListSetItemText(UI.gridlist.roles_members, row, 2,
                        tostring(member.Account))
                local color = LevelColor[tostring(member.RoleID)]
                if color then
                        eui:uiGridListSetItemColor(UI.gridlist.roles_members, row, 1, tocolor(unpack(color)))
                end
        end

        --[[ changelogs ]]
        eui:uiGridListClear(UI.gridlist.changelogs)
        for _, c in ipairs(panelData.changelogs) do
                insertChangelogRow(c)
        end

        --[[ ranks + add-staff rank lists ]]
        eui:uiGridListClear(UI.gridlist.ranks)
        eui:uiGridListClear(UI.gridlist.add_staff_ranks)
        for _, level in ipairs(levels or {}) do
                local color = fromJSON(level.Color or "[[255,255,255,255]]")
                if type(color) ~= "table" then color = { 255, 255, 255, 255 } end
                local row = eui:uiGridListAddRow(UI.gridlist.ranks)
                eui:uiGridListSetItemText(UI.gridlist.ranks, row, 1, tostring(level.LevelName))
                eui:uiGridListSetItemData(UI.gridlist.ranks, row, 1, level.ID)
                eui:uiGridListSetItemColor(UI.gridlist.ranks, row, 1,
                        tocolor(color[1] or 255, color[2] or 255, color[3] or 255))
                local arow = eui:uiGridListAddRow(UI.gridlist.add_staff_ranks)
                eui:uiGridListSetItemText(UI.gridlist.add_staff_ranks, arow, 1,
                        tostring(level.LevelName))
                eui:uiGridListSetItemData(UI.gridlist.add_staff_ranks, arow, 1, level.ID)
                eui:uiGridListSetItemColor(UI.gridlist.add_staff_ranks, arow, 1,
                        tocolor(color[1] or 255, color[2] or 255, color[3] or 255))
        end

        eui:uiCheckBoxSetSelected(UI.checkbox.permissions_select_all, false)
end

addEvent("rpadmin:sendSQLInformations", true)
addEventHandler("rpadmin:sendSQLInformations", root, refreshPanel)

-- /staffs (kept on the client as a request; the server decides access)
addCommandHandler("staffs", function()
        triggerServerEvent("rpadmin:requestPanel", localPlayer)
end, false, false)

--[[ test hook — harmless in production, lets the automated harness reach the
     otherwise file-local element tables ]]
function getStaffPanelTestTable()
        return {
                window = UI.window, gridlist = UI.gridlist, button = UI.button,
                label = UI.label, edit = UI.edit, dialog = UI.dialog,
                rectangle = UI.rectangle, checkbox = UI.checkbox, container = UI.container,
                image = UI.image,
                menu = menu,
                getRankColor = function() return RankColor end,
        }
end
