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
-- [Fix #15] backend-first permissions: the raw click layer + dispatcher use
-- these so a hidden control is truly UNREACHABLE, not just invisible
-- (a Trial clicking where the promote/kick buttons used to be executed the
-- action because only uiSetVisible(false) was applied).
local canEditMembers = false
local canEditRanks = false

-- [Fix #14] readability floor for every rank color the panel draws
local function clampRankColorC(c)
        if type(c) ~= "table" then return c end
        local r = tonumber(c[1]) or 255
        local g = tonumber(c[2]) or 255
        local b = tonumber(c[3]) or 255
        local a = tonumber(c[4]) or 255
        local lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        if lum < 0.45 then
                local t = (0.45 - lum) / math.max(1 - lum, 0.001)
                r = math.floor(r + (255 - r) * t + 0.5)
                g = math.floor(g + (255 - g) * t + 0.5)
                b = math.floor(b + (255 - b) * t + 0.5)
        end
        return { r, g, b, a }
end
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
        { id = "staffs",             en = "Staffs",        ar = "الهيئة",           icon = "staff_manager/icons/menu_shield.png", permission = false },
        { id = "roles_members",      en = "Role Members",  ar = "أعضاء الرتب",      icon = "staff_manager/icons/menu_person.png", permission = "editmembers" },
        { id = "changelogs",         en = "Logs",          ar = "السجلات",  icon = "staff_manager/icons/menu_chat.png",   permission = false },
        { id = "ranks",              en = "Ranks",         ar = "الرتب",            icon = "staff_manager/icons/menu_trophy.png", permission = "editranks" },
        { id = "daily_staff_report", en = "Daily Report",  ar = "تقرير اليوم",      icon = "staff_manager/icons/menu_globe.png",  permission = false },
}

--[[ layout constants — straight from the decompiled code ]]
local PANEL_W, PANEL_H = 905, 575
local MENU_W = 150
local CONTENT_X = MENU_W + 10             -- 160
local CONTENT_W = PANEL_W - MENU_W - 15   -- 740
local CONTENT_H = PANEL_H - 10            -- 565

--[[ [V7] SELF-CONTAINED CLICK LAYER ========================================

        The panel no longer DEPENDS on UIKit's event pipeline. UIKit's own
        path (onClientClick -> UI.click -> onClientUIClick) stays active,
        but a raw MTA onClientClick handler + this panel's own hit registry
        (absolute rects captured at build time, mirroring UIKit's geometry)
        drive the SAME dispatcher. A stale, broken or event-starved UIKit
        build can therefore never make the panel decorative again: if its
        events die, the raw path still lands. dispatchPanelAction latches
        each element for 300ms so both paths can never double-fire. ]]
local PANEL_HIT = {}          -- [element] = { x,y,w,h, kind, section, order }
local HIT_MENU_ROWS = {}      -- [1-based menu row] = section id (rebuilt on menu reload)
local panelDispatchTick = {}  -- per-element dispatch latch
local permToggleTick = {}     -- per-row permission toggle latch (double-click)
local regSeq = 0              -- registration order = painter order
local winX, winY              -- absolute top-left of admin_panel (set in UIKitReady)

local function regHit(el, kind, x, y, w, h, section, baseX, baseY)
        if not el or not isElement(el) then return end
        -- every section container sits at (CONTENT_X, 5) inside admin_panel;
        -- coordinates given relative to a container are lifted to panel space
        if baseX == nil and section ~= nil and section ~= false then
                x, y = x + CONTENT_X, y + 5
        end
        regSeq = regSeq + 1
        PANEL_HIT[el] = {
                x = (baseX or winX) + x * SCALE_Y, y = (baseY or winY) + y * SCALE_Y,
                w = w * SCALE_Y, h = h * SCALE_Y,
                kind = kind, section = section, order = regSeq,
        }
end

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


        -- [V7] absolute root geometry (mirrors UIKit addUIElement root branch)
        local refX, refY = (refSx - PANEL_W) / 2, (refSy - PANEL_H) / 2
        winX = refX * SCALE_X + (PANEL_W * SCALE_X - PANEL_W * SCALE_Y) / 2
        winY = refY * SCALE_Y
        UI.window.admin_panel = eui:uiCreateRectangle(false, false, PANEL_W, PANEL_H,
                tocolor(6, 9, 14, 235), true, true, true, true)
        eui:uiSetVisible(UI.window.admin_panel, false)
        eui:uiBringToFront(UI.window.admin_panel)

        -- [Fix #16] old-client header: text only, at (15, 10) - no logo image
        UI.label.MainMenuTitle = eui:uiCreateLabel(15, 10, 200, 45, "Admin Panel",
                tocolor(255, 255, 255), "left", "center", UI.window.admin_panel)
        eui:uiSetFont(UI.label.MainMenuTitle, "default-large")

        UI.button.close_panel = eui:uiCreateButton(5, PANEL_H - 45, 150, 40,
                { en = "Close", ar = "إغلاق" }, tocolor(6, 9, 14, 255), UI.window.admin_panel)
        eui:uiSetProperty(UI.button.close_panel, "HoverTextColor", tocolor(255, 0, 0))
        -- UIKit's default button TextColor is theme black (invisible on the
        -- dark buttons) — every button below sets an explicit text color
        eui:uiSetProperty(UI.button.close_panel, "TextColor", tocolor(255, 255, 255, 255))

        -- one rounded content panel + container per section
        for _, section in ipairs(SECTIONS) do
                local panel = eui:uiCreateRectangle(CONTENT_X, 5, CONTENT_W, CONTENT_H,
                        tocolor(11, 14, 19, 230), true, true, true, true, UI.window.admin_panel)
                UI.container[section.id] = eui:uiCreateContainer(0, 0, CONTENT_W, CONTENT_H, panel)
                eui:uiSetVisible(UI.container[section.id], false)
                -- [Fix #16] old client paints section titles RED
                UI.label.title = eui:uiCreateLabel(15, 10, 200, 30,
                        { en = section.en, ar = section.ar }, tocolor(255, 0, 0, 255),
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
        eui:uiSetProperty(UI.button.add_admin, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.add_admin, "HoverGlow", true)

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
        eui:uiSetProperty(UI.button.cancel_add_staff, "TextColor", tocolor(255, 255, 255, 255))
        UI.button.add_staff = eui:uiCreateButton(200, 345, 190, 35,
                { en = "Add", ar = "إضافة" }, tocolor(3, 6, 11), UI.window.add_staff)
        eui:uiSetProperty(UI.button.add_staff, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.add_staff, "HoverGlow", true)

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
                tocolor(255, 0, 0), UI.container.ranks)
        eui:uiSetFontSize(UI.checkbox.permissions_select_all, 0.8)

        for _, right in ipairs(AllRights) do
                eui:uiGridListSetItemText(UI.gridlist.permissions,
                        eui:uiGridListAddRow(UI.gridlist.permissions), 1, tostring(right))
        end

        UI.label.rank_id = eui:uiCreateLabel(permsX + 10, 65, 50, 24, "#0",
                tocolor(255, 0, 0, 255), "left", "center", UI.container.ranks)
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
        eui:uiSetProperty(UI.button.add_rank, "TextColor", tocolor(255, 255, 255, 255))

        eui:uiSetProperty(UI.button.add_rank, "HoverGlow", true)
        -- [Fix #20] the original client has a dedicated "Change Rank Name"
        -- button (the decompiled GUIEditor.button.ChangeRankName). Without it
        -- there is no way to rename a rank at all: the rank_name edit box is
        -- the ONLY input and it was wired to Add Rank only.
        UI.button.rename_rank = eui:uiCreateButton(330, PANEL_H - 10 - 45, 150, 35,
                { en = "Rename Rank", ar = "إعادة تسمية" }, tocolor(6, 9, 14, 255), UI.container.ranks)
        eui:uiSetProperty(UI.button.rename_rank, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.rename_rank, "HoverGlow", true)
        UI.button.save_rank_changes = eui:uiCreateButton(PANEL_W - MENU_W - 15 - 160,
                PANEL_H - 10 - 45, 150, 35, { en = "Save Changes", ar = "حفظ التغييرات" },
                tocolor(6, 9, 14, 255), UI.container.ranks)
        eui:uiSetProperty(UI.button.save_rank_changes, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiSetProperty(UI.button.save_rank_changes, "HoverGlow", true)

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

        -- [Fix #16] version badge removed - the old client has none

        --[[ ----------------------- sidebar menu -----------------------
             EXACT old client: 150x450 menu at (5, 65), row_height 35,
             RED selection bar + red selection text accent, compact rows ]]
        local MENU_H = 450
        menu = eui:uiCreateMenu(5, 65, MENU_W, MENU_H, tocolor(19, 22, 27, 0),
                UI.window.admin_panel)
        eui:uiSetProperty(menu, "hovered_row_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(menu, "selected_row_color", tocolor(3, 6, 11, 255))
        eui:uiSetProperty(menu, "row_height", 35)
        eui:uiSetProperty(menu, "icons_color", tocolor(255, 0, 0))
        eui:uiSetProperty(menu, "selection_color", tocolor(255, 0, 0))
        setElementID(menu, "staff-panel-menu")
        local rowHeight = 35

        -- [V7] hit registry: every interactive element with its absolute rect.
        -- Registration order = creation order = painter order (topmost wins).
        PANEL_HIT, regSeq = {}, 0
        PANEL_HIT[menu] = { x = winX + 5 * SCALE_Y, y = winY + 65 * SCALE_Y,
                w = MENU_W * SCALE_Y, h = MENU_H * SCALE_Y, kind = "menu",
                section = false, rowH = rowHeight, order = 0 }
        regHit(UI.button.close_panel, "button", 5, PANEL_H - 45, 150, 40, false)
        regHit(UI.gridlist.staffs, "grid", 10, 60, CONTENT_W - 20, PANEL_H - 10 - 120, UI.container.staffs)
        regHit(UI.button.delete_admin, "button", 10, PANEL_H - 10 - 45, 150, 35, UI.container.staffs)
        regHit(UI.button.add_admin, "button", 170, PANEL_H - 10 - 45, 150, 35, UI.container.staffs)
        regHit(UI.gridlist.roles_members, "grid", 10, 60, CONTENT_W - 20, PANEL_H - 10 - 120, UI.container.roles_members)
        regHit(UI.edit.changelogs_search, "edit", CONTENT_W - 310, 15, 300, 25, UI.container.changelogs)
        regHit(UI.gridlist.changelogs, "grid", 10, 60, CONTENT_W - 20, PANEL_H - 10 - 60 - 10, UI.container.changelogs)
        regHit(UI.gridlist.ranks, "grid", 10, 60, ranksW, PANEL_H - 10 - 120, UI.container.ranks)
        regHit(UI.gridlist.permissions, "grid", permsX, 100, permsW, PANEL_H - 10 - 60 - 100 - 30, UI.container.ranks)
        regHit(UI.checkbox.permissions_select_all, "checkbox", permsX, PANEL_H - 10 - 60 - 20, 150, 25, UI.container.ranks)
        regHit(UI.edit.rank_name, "edit", permsX + 55, 65, 300, 25, UI.container.ranks)
        regHit(UI.rectangle.rank_color, "colorrect", PANEL_W - MENU_W - 15 - 60, 65, 50, 25, UI.container.ranks)
        regHit(UI.button.delete_rank, "button", 10, PANEL_H - 10 - 45, 150, 35, UI.container.ranks)
        regHit(UI.button.add_rank, "button", 170, PANEL_H - 10 - 45, 150, 35, UI.container.ranks)
        regHit(UI.button.rename_rank, "button", 330, PANEL_H - 10 - 45, 150, 35, UI.container.ranks)
        regHit(UI.button.save_rank_changes, "button", PANEL_W - MENU_W - 15 - 160, PANEL_H - 10 - 45, 150, 35, UI.container.ranks)
        regHit(UI.gridlist.daily_staff_report, "grid", 10, 60, CONTENT_W - 20, PANEL_H - 10 - 120, UI.container.daily_staff_report)
        -- floating add-staff window (root element -> own base origin)
        local awX = ((refSx - 400) / 2) * SCALE_X + (400 * SCALE_X - 400 * SCALE_Y) / 2
        local awY = ((refSy - 390) / 2) * SCALE_Y
        PANEL_HIT[UI.window.add_staff] = { x = awX, y = awY, w = 400 * SCALE_Y,
                h = 390 * SCALE_Y, kind = "window", section = false, order = 0 }
        regHit(UI.edit.add_staff_account, "edit", 10, 50, 380, 25, UI.window.add_staff, awX, awY)
        regHit(UI.gridlist.add_staff_ranks, "grid", 10, 90, 380, 250, UI.window.add_staff, awX, awY)
        regHit(UI.button.cancel_add_staff, "button", 10, 345, 185, 35, UI.window.add_staff, awX, awY)
        regHit(UI.button.add_staff, "button", 200, 345, 190, 35, UI.window.add_staff, awX, awY)
        -- confirm dialogs float above everything; their buttons handle
        -- themselves inside the dialog draw (independent click detection)
        local dlgX = ((refSx - 300) / 2) * SCALE_X + (300 * SCALE_X - 300 * SCALE_Y) / 2
        local dlgY = ((refSy - 160) / 2) * SCALE_Y
        PANEL_HIT[UI.dialog.delete_staff] = { x = dlgX, y = dlgY, w = 300 * SCALE_Y,
                h = 160 * SCALE_Y, kind = "window", section = false, order = 0 }
        PANEL_HIT[UI.dialog.delete_rank] = { x = dlgX, y = dlgY, w = 300 * SCALE_Y,
                h = 160 * SCALE_Y, kind = "window", section = false, order = 0 }

        uiBuilt = true
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

--[[ ===================== sidebar menu (1:1) ===================== ]]

function reloadAdminPanelMenu(hasEditMembers, hasEditRanks)
        eui:uiMenuClear(menu)
        HIT_MENU_ROWS = {}
        for _, section in ipairs(SECTIONS) do
                local allowed = not section.permission
                        or (section.permission == "editmembers" and hasEditMembers)
                        or (section.permission == "editranks" and hasEditRanks)
                if allowed then
                        HIT_MENU_ROWS[#HIT_MENU_ROWS + 1] = section.id
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
        -- [Fix #15] remember the server-issued flags for the raw click layer
        canEditMembers = hasEditMembers and true or false
        canEditRanks = hasEditRanks and true or false
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
                        -- [Fix #15] client-side gate (the server rejects anyway)
                        if not canEditMembers then
                                outputChatBox("You don't have permission to edit staff members.", 255, 80, 80)
                                return
                        end
                        triggerServerEvent("rpadmin:removeAdmin", localPlayer,
                                eui:uiGetText(UI.label.delete_staff_username))
                end
        elseif source == UI.dialog.delete_rank then
                if button == "left" and rank_to_delete then
                        if not canEditRanks then
                                outputChatBox("You don't have permission to edit ranks.", 255, 80, 80)
                                return
                        end
                        triggerServerEvent("rpadmin:removeAdminLevel", localPlayer, rank_to_delete)
                end
                rank_to_delete = nil
        end
end)

local function dispatchPanelAction(el)
        if not (UI.window.admin_panel and isElement(UI.window.admin_panel)) then return end
        if not el or not isElement(el) then return end
        -- [V7] per-element latch: the UIKit path and the raw-input fallback
        -- can both land here for the same click; only the first counts
        local nowTick = getTickCount()
        if panelDispatchTick[el] and nowTick - panelDispatchTick[el] < 300 then return end
        panelDispatchTick[el] = nowTick

        -- [Fix #15] backend-first permission gates (the server re-checks every
        -- mutation; this makes the CLIENT refuse too so nothing "appears")
        if not canEditMembers and (el == UI.button.delete_admin or el == UI.button.add_admin) then
                outputChatBox("You don't have permission to edit staff members.", 255, 80, 80)
                return
        end
        if not canEditRanks and (el == UI.button.delete_rank or el == UI.button.add_rank
                or el == UI.button.rename_rank or el == UI.button.save_rank_changes
                or el == UI.checkbox.permissions_select_all) then
                outputChatBox("You don't have permission to edit ranks.", 255, 80, 80)
                return
        end

        -- ranks grid: select a rank -> load its rights + color
        if el == UI.gridlist.ranks then
                local sel = eui:uiGridListGetSelectedItem(el)
                if sel ~= -1 then
                        local roleID = eui:uiGridListGetItemData(el, sel, 1)
                        eui:uiSetText(UI.edit.rank_name, eui:uiGridListGetItemText(el, sel, 1))
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

        elseif el == UI.rectangle.rank_color then
                -- [Fix #19] backend-first: a rank without editranks must not be
                -- able to open the color picker at all (the server re-checks
                -- on save, but the picker should never even appear)
                if not canEditRanks then
                        outputChatBox("You don't have permission to edit ranks.", 255, 80, 80)
                        return
                end
                currentColorLabel = UI.rectangle.rank_color
                colorPicker.openSelect(unpack(RankColor))

        elseif el == UI.checkbox.permissions_select_all then
                local selected = eui:uiCheckBoxGetSelected(el)
                for row = 0, eui:uiGridListGetRowCount(UI.gridlist.permissions) - 1 do
                        eui:uiGridListSetItemData(UI.gridlist.permissions, row, 1, selected and true or false)
                        if selected then
                                eui:uiGridListSetItemColor(UI.gridlist.permissions, row, 1, tocolor(0, 255, 0))
                        else
                                eui:uiGridListSetItemColor(UI.gridlist.permissions, row, 1, tocolor(255, 0, 0))
                        end
                end

        elseif el == UI.button.delete_rank then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.ranks)
                if sel ~= -1 then
                        eui:uiSetVisible(UI.dialog.delete_rank, true)
                        eui:uiSetText(UI.label.delete_rank_name,
                                eui:uiGridListGetItemText(UI.gridlist.ranks, sel, 1))
                        rank_to_delete = eui:uiGridListGetItemData(UI.gridlist.ranks, sel, 1)
                end

        elseif el == UI.button.add_rank then
                if eui:uiGetText(UI.edit.rank_name) ~= "" then
                        triggerServerEvent("rpadmin:addAdminLevel", localPlayer,
                                eui:uiGetText(UI.edit.rank_name))
                        eui:uiSetText(UI.edit.rank_name, "")
                end

        elseif el == UI.button.rename_rank then
                -- [Fix #20] rename the SELECTED rank to the text in the edit
                -- box. Requires both a selection and a non-empty new name.
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.ranks)
                if sel == -1 then
                        outputChatBox("Select a rank from the list first.", 255, 80, 80)
                        return
                end
                local newName = eui:uiGetText(UI.edit.rank_name)
                if not newName or newName == "" then
                        outputChatBox("Type the new rank name first.", 255, 80, 80)
                        return
                end
                triggerServerEvent("rpadmin:changeAdminLevelName", localPlayer,
                        eui:uiGridListGetItemData(UI.gridlist.ranks, sel, 1), newName)
                eui:uiSetText(UI.edit.rank_name, "")

        elseif el == UI.button.save_rank_changes then
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

        elseif el == UI.button.delete_admin then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.staffs)
                if sel ~= -1 then
                        eui:uiSetVisible(UI.dialog.delete_staff, true)
                        eui:uiSetText(UI.label.delete_staff_username,
                                eui:uiGridListGetItemText(UI.gridlist.staffs, sel, 2))
                end

        elseif el == UI.button.add_admin then
                eui:uiSetVisible(UI.window.add_staff, true)
                eui:uiBringToFront(UI.window.add_staff)

        elseif el == UI.button.add_staff then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.add_staff_ranks)
                -- [Fix #14] LOUD validation: a silent return read exactly like
                -- "the promotion system is broken"
                if #eui:uiGetText(UI.edit.add_staff_account) == 0 then
                        outputChatBox("Promotion failed: type the ACCOUNT name first.", 255, 80, 80)
                        eui:uiLabelApplyShakeAnimation(UI.label.delete_staff_username, tocolor(255, 0, 0, 255))
                        return
                end
                if sel == -1 then
                        outputChatBox("Promotion failed: select a RANK from the list first.", 255, 80, 80)
                        return
                end
                if #eui:uiGetText(UI.edit.add_staff_account) ~= 0 and sel ~= -1 then
                        triggerServerEvent("rpadmin:addNewAdmin", localPlayer,
                                eui:uiGetText(UI.edit.add_staff_account),
                                eui:uiGridListGetItemData(UI.gridlist.add_staff_ranks, sel, 1),
                                eui:uiGridListGetItemText(UI.gridlist.add_staff_ranks, sel, 1))
                        eui:uiSetVisible(UI.window.add_staff, false)
                        eui:uiSetText(UI.edit.add_staff_account, "")
                end

        elseif el == UI.button.cancel_add_staff then
                eui:uiSetVisible(UI.window.add_staff, false)

        elseif el == UI.button.close_panel then
                eui:uiSetVisible(UI.window.admin_panel, false)
                eui:uiSetVisible(UI.window.add_staff, false)
                showCursor(false)
        end
end

addEventHandler("onClientUIClick", root, function()
        dispatchPanelAction(source)
end)

local function togglePermissionRow(sel)
        if not (UI.gridlist.permissions and isElement(UI.gridlist.permissions)) then return end
        if not sel or sel < 0 then return end
        -- [Fix #15] ranks editing is a permission, not a UI state
        if not canEditRanks then
                outputChatBox("You don't have permission to edit ranks.", 255, 80, 80)
                return
        end
        -- [V7] shared by the UIKit double-click path AND the raw fallback;
        -- the latch keeps a double-click from toggling twice
        local nowTick = getTickCount()
        if permToggleTick[sel] and nowTick - permToggleTick[sel] < 250 then return end
        permToggleTick[sel] = nowTick
        local state = not eui:uiGridListGetItemData(UI.gridlist.permissions, sel, 1)
        eui:uiGridListSetItemData(UI.gridlist.permissions, sel, 1, state)
        if state then
                eui:uiGridListSetItemColor(UI.gridlist.permissions, sel, 1, tocolor(0, 255, 0))
        else
                eui:uiGridListSetItemColor(UI.gridlist.permissions, sel, 1, tocolor(255, 0, 0))
        end
end

addEventHandler("onClientUIDoubleClick", root, function()
        if source == UI.gridlist.permissions
                and eui:uiGridListGetSelectedItem(source) ~= -1 then
                togglePermissionRow(eui:uiGridListGetSelectedItem(source))
        end
end)

--[[ [V7] raw-input click path - the panel's own hit registry + MTA's raw
        onClientClick/onClientDoubleClick. Keeps every button, row, checkbox,
        edit and menu row working even if UIKit's own event pipeline is dead,
        stale, or eaten by another resource. ]]

-- [Fix #17] SCROLL-AWARE row hit test. The old math divided the click Y by
-- the row height from the TOP OF THE LIST, ignoring the scroll offset
-- (data.row_i). After scrolling the ranks list down and clicking "Owner"
-- the computed index landed on a row near the TOP (e.g. Junior Management),
-- so the panel loaded the wrong rank's name/rights/color — the "I click
-- Owner and it shows Junior Management" bug. UIKit already knows the exact
-- visible window + per-row heights, so ask it directly instead of redoing
-- the math (this mirrors UI.refreshGridlistHoverRow in c_process.lua).
local function panelGridRowAt(info, gl, ay)
        if not (gl and isElement(gl)) then return nil end
        local okF, firstVisible, lastVisible = pcall(eui.uiGridListGetVisibleRows, eui, gl)
        if not okF or not firstVisible then
                -- UIKit predates the helper: fall back to the whole list
                firstVisible, lastVisible = 1, 1
                local okC, count = pcall(eui.uiGridListGetRowCount, eui, gl)
                if okC and count then lastVisible = math.max(count, 1) end
        end
        local okH, hitRow = pcall(eui.uiGridListGetRowAtPoint, eui, gl, ay)
        if okH and hitRow ~= nil and hitRow >= 0 then return hitRow end
        -- legacy fallback (kept for a UIKit without the two exports above)
        local ok, colH = pcall(eui.uiGetProperty, eui, gl, "column_height")
        local col = (ok and tonumber(colH)) or 25
        local ok2, rowHraw = pcall(eui.uiGetProperty, eui, gl, "row_height")
        local rowH = math.max((ok2 and tonumber(rowHraw) or 20) * SCALE_Y, 4)
        local relY = ay - (info.y + 2 + col)
        if relY < 0 then return nil end
        local ok3, count = pcall(eui.uiGridListGetRowCount, eui, gl)
        if not ok3 or not count or count <= 0 then return nil end
        local idx = math.floor(relY / rowH) + (firstVisible - 1)
        if idx >= 0 and idx < count then return idx end
        return nil
end

local function panelDispatch(hitEl, info, ax, ay)
        if not hitEl or not info then return end
        if info.kind == "button" or info.kind == "colorrect" then
                -- [Fix #14] the UIKit pipeline is dead on this server, so its
                -- pressed state never fired: flash through the new export
                pcall(eui.uiFlashPress, eui, hitEl)
                pcall(function() playSound(":UIKit/sounds/click.wav") end)
                dispatchPanelAction(hitEl)
        elseif info.kind == "checkbox" then
                local ok, cur = pcall(eui.uiCheckBoxGetSelected, eui, hitEl)
                if pcall(eui.uiCheckBoxSetSelected, eui, hitEl, not (ok and cur)) then
                        dispatchPanelAction(hitEl)
                end
        elseif info.kind == "grid" then
                local idx = panelGridRowAt(info, hitEl, ay)
                if idx and pcall(eui.uiGridListSetSelectedItem, eui, hitEl, idx) then
                        if hitEl == UI.gridlist.permissions then
                                togglePermissionRow(idx)
                        else
                                dispatchPanelAction(hitEl)
                        end
                end
        elseif info.kind == "edit" then
                -- focus (uiSetFocusedElement is a V7 UIKit export; if the
                -- installed UIKit predates it the pcall simply no-ops)
                pcall(eui.uiSetFocusedElement, eui, hitEl)
                local okT, txt = pcall(eui.uiGetText, eui, hitEl)
                local caret = 1
                if okT and type(txt) == "string" and #txt > 0 then
                        local n = (utf8 and utf8.len and utf8.len(txt)) or #txt
                        caret = (tonumber(n) or #txt) + 1
                end
                pcall(eui.uiEditSetCaretIndex, eui, hitEl, caret)
        elseif info.kind == "menu" then
                local step = (info.rowH or 40) * SCALE_Y + 4
                local idx = math.floor((ay - (info.y + 5 * SCALE_Y)) / step) + 1
                if HIT_MENU_ROWS[idx] then
                        pcall(eui.uiMenuSetSelectedRow, eui, menu, idx)
                end
        end
        -- kind "window": swallowed on purpose (floating windows/dialogs
        -- run their own click handling)
end

local function panelHitTest(ax, ay)
        -- 1) confirm dialogs float above everything
        for _, dlg in ipairs({ UI.dialog.delete_staff, UI.dialog.delete_rank }) do
                if dlg and isElement(dlg) then
                        local okV, dv = pcall(eui.uiGetVisible, eui, dlg)
                        if okV and dv then
                                local dr = PANEL_HIT[dlg]
                                if dr and ax >= dr.x and ax <= dr.x + dr.w and ay >= dr.y and ay <= dr.y + dr.h then
                                        return dlg, dr
                                end
                        end
                end
        end
        -- 2) the floating add-staff window
        local aw = UI.window.add_staff
        if aw and isElement(aw) then
                local okV, wv = pcall(eui.uiGetVisible, eui, aw)
                if okV and wv then
                        local wr = PANEL_HIT[aw]
                        if wr and ax >= wr.x and ax <= wr.x + wr.w and ay >= wr.y and ay <= wr.y + wr.h then
                                local bEl, bInfo, bOrder
                                for el, info in pairs(PANEL_HIT) do
                                        if info.section == aw and ax >= info.x and ax <= info.x + info.w
                                                and ay >= info.y and ay <= info.y + info.h then
                                                if not bOrder or info.order > bOrder then
                                                        bEl, bInfo, bOrder = el, info, info.order
                                                end
                                        end
                                end
                                return bEl or aw, bInfo or wr
                        end
                end
        end
        -- 3) the main panel surface
        local ap = UI.window.admin_panel
        if not (ap and isElement(ap)) then return nil end
        local okV, pv = pcall(eui.uiGetVisible, eui, ap)
        if not (okV and pv) then return nil end
        local bEl, bInfo, bOrder
        for el, info in pairs(PANEL_HIT) do
                if info.kind ~= "window" and info.section ~= aw then
                        local secOK = (info.section == nil or info.section == false)
                        if not secOK and isElement(info.section) then
                                local ok2, sv = pcall(eui.uiGetVisible, eui, info.section)
                                secOK = (ok2 and sv == true) or false
                        end
                        -- [Fix #15] THE fix for "the button is hidden but clicking
                        -- where it was still fires": the raw layer must respect the
                        -- element's OWN visibility, not only its section's.
                        local elOK = (info.kind == "menu")
                        if not elOK then
                                local ok3, ev = pcall(eui.uiGetVisible, eui, el)
                                elOK = (ok3 and ev == true) or false
                        end
                        if elOK and secOK and ax >= info.x and ax <= info.x + info.w
                                and ay >= info.y and ay <= info.y + info.h then
                                if not bOrder or info.order > bOrder then
                                        bEl, bInfo, bOrder = el, info, info.order
                                end
                        end
                end
        end
        return bEl, bInfo
end

addEventHandler("onClientClick", root, function(button, state, ax, ay)
        if button ~= "left" or state ~= "up" or not uiBuilt then return end
        local hitEl, info = panelHitTest(ax, ay)
        if hitEl and info then
                panelDispatch(hitEl, info, ax, ay)
        end
end)

addEventHandler("onClientDoubleClick", root, function(button, ax, ay)
        if button ~= "left" or not uiBuilt then return end
        local hitEl, info = panelHitTest(ax, ay)
        if hitEl and info and info.kind == "grid" and hitEl == UI.gridlist.permissions then
                local idx = panelGridRowAt(info, hitEl, ay)
                if idx then
                        pcall(eui.uiGridListSetSelectedItem, eui, hitEl, idx)
                        togglePermissionRow(idx)
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
-- [Fix #18] MTA's toJSON wraps associative tables: '[ { "a": true } ]'.
-- fromJSON then yields { [1] = {a=true} }, so LevelRights[id]["admin.goto"]
-- was always nil and every rank loaded with an EMPTY permission list in the
-- panel ("all checkboxes off, saving changes nothing"). Unwrap on read.
local function unwrapRightsC(t)
        if type(t) ~= "table" then return {} end
        if type(t[1]) == "table" and next(t, 1) == nil then
                return t[1]
        end
        return t
end

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
                local rights = unwrapRightsC(fromJSON(level.Rights or "{}"))
                LevelRights[tostring(level.ID)] = rights
                local color = fromJSON(level.Color or "[[255,255,255,255]]")
                LevelColor[tostring(level.ID)] = type(color) == "table" and color or { 255, 255, 255, 255 }
                getLevelByName[tostring(level.LevelName)] = tostring(level.ID)
        end

        --[[ staffs list ]]
        eui:uiGridListClear(UI.gridlist.staffs)
        table.sort(admins or {}, function(a, b)
                local ida, idb = tonumber(a.AdminID) or 0, tonumber(b.AdminID) or 0
                if ida == idb then
                        -- [V7] nil-proof: one bad row must never kill the sort
                        -- (a thrown sort leaves the whole panel half-filled)
                        local ra = (tonumber(a.FeedbackRating) or 0) / math.max(tonumber(a.FeedbackCount) or 0, 1)
                        local rb = (tonumber(b.FeedbackRating) or 0) / math.max(tonumber(b.FeedbackCount) or 0, 1)
                        return ra > rb
                end
                return ida < idb
        end)
        for _, staff in ipairs(admins or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.staffs)
                -- [Mod 2 fix] LIVE rank for ONLINE staff (bridge element data,
                -- matched by ACCOUNT id) wins over the stored DB role; offline
                -- staff keep the DB rank. Panel now always agrees with the tab.
                local color = (staff.Online and type(staff.LiveColor) == "table") and staff.LiveColor
                        or LevelColor[tostring(staff.AdminID)] or { 255, 255, 255 }
                color = clampRankColorC(color)
                local rankName = (staff.Online and staff.LiveRank and staff.LiveRank ~= "")
                        and tostring(staff.LiveRank)
                        or tostring(LevelNames[tostring(staff.AdminID)] or "N/A")
                local rating = 0
                if tonumber(staff.FeedbackCount) and tonumber(staff.FeedbackCount) > 0 then
                        rating = (tonumber(staff.FeedbackRating) or 0) / tonumber(staff.FeedbackCount)
                end
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 1, rankName)
                eui:uiGridListSetItemText(UI.gridlist.staffs, row, 2,
                        (staff.Online and "#00FF00● " or "#808080○ ") .. tostring(staff.Account))
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
