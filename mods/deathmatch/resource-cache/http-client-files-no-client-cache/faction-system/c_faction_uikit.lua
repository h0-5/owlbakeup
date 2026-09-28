--[[ =========================================================================
        c_faction_uikit.lua — Vortex FACTION PANEL (Fix #42, MOD 4/4)

        1:1 UIKit port of the OLD CLIENT faction panel
        (backupm faction-system faction_c_decompiled.lua):

          * 955x625 dark window (6,9,14,235), LEFT SIDEBAR MENU (150 wide,
            row_height 30, selection color = faction color) with level
            filtered sections: Members / Ranks / Notes / Settings / Properties
            / Duty / Logs  (sections without a backend on this server -
            recruitment, tasks, top-members, invoices - stay hidden instead
            of being dead buttons)
          * header: faction logo 100x100, "#ID Name" title, info block
            (type / members online / RGB color + hotline / radio / MOTD),
            member-count box top-right + "more" icon -> SelectFaction window
          * MEMBERS: Name/Rank/LastLogin/Wage/Phone/Duty gridlist, online =
            green / offline = red (old-client rule), leader action row
            (Dismissal / Promote-Demote / DutyPerks / Set Leader / + add)
          * RANKS: ranks gridlist + name/wage edits + Save Changes
          * NOTES: note memo + MOTD memo with their own save buttons
          * SETTINGS: bank/balance info (factionmenu:fillFinance) + quit
          * PROPERTIES: faction vehicles ID/Name/Plate/Location + limit,
            Respawn All, double-click = respawn one
          * DUTY: tab panel (packages / locations / vehicle locations) with
            add/remove per tab
          * LOGS: session action log
          * sub windows: Promote/Demote rank picker (double click),
            Add Member with live character search, Duty Perks checklist

        SERVER CONTRACT UNCHANGED (s_faction_system.lua / s_faction_admin.lua):
          receives showFactionMenu(22 args) / hideFactionMenu /
                   factionmenu:fillFinance / importDutyData / Duty:GotPackages /
                   gotAllow
          sends    cguiPromotePlayer, cguiDemotePlayer, cguiInvitePlayer,
                   faction:perks:edit, cguiKickPlayer, cguiToggleLeader,
                   cguiUpdateRanks, cguiRespawnVehicles, cguiRespawnOneVehicle,
                   cguiUpdateMOTD, faction:note, cguiQuitFaction,
                   factionmenu:hide, factionmenu:getFinance, fetchDutyInfo,
                   Duty:GetPackages, Duty:AddDuty, Duty:RemoveDuty,
                   Duty:AddLocation, Duty:RemoveLocation, Duty:AddVehicle
========================================================================= ]]

local localPlayer = getLocalPlayer()
local eui = exports.UIKit

local REF_SX, REF_SY = (function()
        -- [Fix #52] top-level UIKit call died if UIKit had not started yet,
        -- killing this whole script (F3 handler never registered).
        local ok, x, y = pcall(function() return eui:uiGetReferenceScreenSize() end)
        if ok and tonumber(x) then return tonumber(x), tonumber(y) end
        return 1728, 972
end)()

local WIN_W, WIN_H = 955, 625
local PANEL_X, PANEL_W = 150 + 10, 955 - 150 - 15 -- 160 / 790
local PANEL_Y, PANEL_H = 130, 625 - 130 - 5       -- 130 / 490
local BTN_ROW = PANEL_H - 35

local UI = { window = {}, label = {}, button = {}, edit = {}, gridlist = {},
        menu = {}, container = {}, memo = {}, image = {}, checkbox = {}, progress = {}, checklist = {},
        tabpanel = {}, tab = {} }
local isLabelButton = {}
local built = false

F = {
        visible = false,
        data = nil,
        section = "members",
        members = {},
        onlineCount = 0,
        isLeader = false,
        factionID = -1,
        factionType = 0,
        team = nil,
        noteBuffer = "",
        motdBuffer = "",
        finance = nil,
        financeLoaded = false,
        dutyPackages = {},
        dutyLocations = {},
        dutyAllow = {},
        actionLog = {},
        selectedMember = 0,
        currentRank = 0,
}

local SECTIONS = {
        { id = "members",    title = { en = "Members",    ar = "الأعضاء" },    level = "Member", icon = ":assets/icons/group.png" },
        { id = "ranks",      title = { en = "Ranks",      ar = "الرتب" },      level = "Leader", icon = ":assets/icons/settings.png" },
        { id = "notes",      title = { en = "Notes",      ar = "الملاحظات" },  level = "Leader", icon = ":assets/icons/note.png" },
        { id = "management", title = { en = "Settings",   ar = "الإعدادات" },  level = "Leader", icon = ":assets/icons/dollar.png" },
        { id = "properties", title = { en = "Properties", ar = "الخصائص" },    level = "Leader", icon = ":assets/icons/car.png" },
        { id = "duty",       title = { en = "Duty",       ar = "الخدمة" },     level = "Leader", icon = ":assets/icons/flag.png" },
        { id = "logs",       title = { en = "Logs",       ar = "السجل" },      level = "Leader", icon = ":assets/icons/history.png" },
}

FACTION_TYPES = { { en = "Gang", ar = "عصابة" }, { en = "Mafia", ar = "مافيا" },
        { en = "Law", ar = "قانوني" }, { en = "Government", ar = "حكومي" }, { en = "Medical", ar = "صحي" },
        { en = "Other", ar = "أخر" }, { en = "News", ar = "إعلام" }, { en = "Mechanic", ar = "ميكانيكي" },
        { en = "Electric", ar = "كهرباء" }, { en = "Traffic", ar = "مرور" }, { en = "Business", ar = "أعمال" },
        { en = "Family", ar = "عائلة" } }

local function logAction(text)
        table.insert(F.actionLog, 1, { text = tostring(text), at = os.date("%d/%m %H:%M") })
        if #F.actionLog > 60 then table.remove(F.actionLog) end
end

local function factionColor()
        local c = F.team and getElementData(F.team, "color") or nil
        if type(c) == "table" and tonumber(c[1]) then
                return tonumber(c[1]), tonumber(c[2]), tonumber(c[3])
        end
        return 255, 55, 95
end

local function typeAr(t)
        return (FACTION_TYPES[(tonumber(t) or 5) + 1] or FACTION_TYPES[6]).ar
end

-- ===========================================================================
-- build
-- ===========================================================================

local function buildUI()
        if built then return end
        built = true

        UI.window.FactionWindow = eui:uiCreateRectangle(false, false, WIN_W, WIN_H, tocolor(6, 9, 14, 235), true, true, true, true)
        eui:uiSetVisible(UI.window.FactionWindow, false)

        UI.menu.main = eui:uiCreateMenu(5, 150, 150, 400, tocolor(19, 22, 27, 0), UI.window.FactionWindow)
        eui:uiSetProperty(UI.menu.main, "hovered_row_color", tocolor(9, 12, 17, 200))
        eui:uiSetProperty(UI.menu.main, "selected_row_color", tocolor(3, 6, 11, 255))
        eui:uiSetProperty(UI.menu.main, "row_height", 30)

        for _, sec in ipairs(SECTIONS) do
                UI.container[sec.id] = eui:uiCreateContainer(0, 0, PANEL_W, PANEL_H,
                        eui:uiCreateRectangle(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, tocolor(11, 14, 19, 230), true, true, true, true, UI.window.FactionWindow))
                eui:uiSetVisible(UI.container[sec.id], false)
        end

        -- header ---------------------------------------------------------------
        UI.window.FactionMain = eui:uiCreateRectangle(5, 5, 700, 125, tocolor(20, 20, 20, 0), true, true, true, true, UI.window.FactionWindow)
        UI.image.FactionLogo = eui:uiCreateImage(25, 15, 100, 100, ":assets/images/logo.png", UI.window.FactionMain)
        UI.label.FactionTitle = eui:uiCreateLabel(160, 10, 232, 30, "", tocolor(255, 255, 255, 255), "left", "top", UI.window.FactionMain)
        eui:uiSetFont(UI.label.FactionTitle, "default-large")
        UI.label.FactionInfo = eui:uiCreateLabel(160, 50, 250, 70, "", tocolor(255, 255, 255, 255), "left", "top", UI.window.FactionMain)
        eui:uiSetProperty(UI.label.FactionInfo, "color_coded", true)
        UI.label.FactionInfo2 = eui:uiCreateLabel(420, 50, 260, 70, "", tocolor(255, 255, 255, 255), "left", "top", UI.window.FactionMain)
        eui:uiSetProperty(UI.label.FactionInfo2, "color_coded", true)

        -- member count box + more icon ------------------------------------------
        UI.container.level = eui:uiCreateRectangle(WIN_W - 155, 50, 140, 60, tocolor(20, 20, 20, 240), true, true, true, true, UI.window.FactionWindow)
        UI.label.level = eui:uiCreateLabel(10, 5, 140, 20, "", tocolor(255, 255, 255, 255), "left", "top", UI.container.level)
        eui:uiSetFont(UI.label.level, "default-large")
        UI.label.level_points = eui:uiCreateLabel(10, 32, 140, 20, "", tocolor(255, 255, 255, 220), "left", "top", UI.container.level)
        UI.label.ChangeFaction = eui:uiCreateImage(WIN_W - 60, 10, 40, 40, ":assets/icons/more.png", UI.window.FactionWindow)
        eui:uiSetProperty(UI.label.ChangeFaction, "HoverOpacityEffect", true)
        isLabelButton[UI.label.ChangeFaction] = "ChangeFaction"

        -- ================= MEMBERS =================
        UI.gridlist.Members = eui:uiCreateGridList(0, 0, PANEL_W, PANEL_H - 45, tocolor(20, 20, 20, 0), UI.container.members)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "Name", ar = "الاسم" }, 0.28)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "Rank", ar = "الرتبة" }, 0.22)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "LastLogin", ar = "آخر ظهور" }, 0.13)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "Wage", ar = "الراتب" }, 0.1)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "Phone", ar = "الهاتف" }, 0.12)
        eui:uiGridListAddColumn(UI.gridlist.Members, { en = "Duty", ar = "الخدمة" }, 0.15)
        eui:uiSetAlign(UI.gridlist.Members, "left", "center")

        UI.button["Member.Dismissal"] = eui:uiCreateButton(5, BTN_ROW, 100, 30, { en = "Dismissal", ar = "طرد" }, _, UI.container.members)
        UI.button["Member.Promote/Demote"] = eui:uiCreateButton(110, BTN_ROW, 120, 30, { en = "Promote/Demote", ar = "ترقية/خفض" }, _, UI.container.members)
        UI.button["Member.DutyPerks"] = eui:uiCreateButton(235, BTN_ROW, 120, 30, { en = "Duty Perks", ar = "امتيازات الديوتي" }, _, UI.container.members)
        UI.button["Member.SetLevel"] = eui:uiCreateButton(360, BTN_ROW, 100, 30, { en = "Set Leader", ar = "تعيين قائد" }, _, UI.container.members)
        UI.button["Member.AddMember"] = eui:uiCreateButton(465, BTN_ROW, 30, 30, "+", _, UI.container.members)
        eui:uiSetProperty(UI.button["Member.Dismissal"], "HoverTextColor", tocolor(255, 48, 48))
        eui:uiSetProperty(UI.button["Member.Promote/Demote"], "HoverTextColor", eui:uiGetThemeColor("primary"))
        eui:uiSetProperty(UI.button["Member.DutyPerks"], "HoverTextColor", eui:uiGetThemeColor("primary"))
        eui:uiSetProperty(UI.button["Member.SetLevel"], "HoverTextColor", eui:uiGetThemeColor("primary"))
        eui:uiSetProperty(UI.button["Member.AddMember"], "HoverTextColor", eui:uiGetThemeColor("primary"))
        eui:uiCreateLabel(PANEL_W - 215, BTN_ROW, 200, 30, "#00FF00 • #FFFFFFمتصل   #FF0000 • #FFFFFFغير متصل", tocolor(255, 255, 255, 255), "left", "center", UI.container.members)

        -- ================= RANKS =================
        UI.gridlist.FactionRanks = eui:uiCreateGridList(5, 5, PANEL_W / 2 - 10, PANEL_H - 10, tocolor(6, 9, 14, 235), UI.container.ranks)
        eui:uiGridListAddColumn(UI.gridlist.FactionRanks, { en = "Ranks", ar = "الرتب" }, 0.8)
        eui:uiGridListAddColumn(UI.gridlist.FactionRanks, "", 0.2)
        UI.edit.RankName = eui:uiCreateEdit(PANEL_W / 2 + 5, 10, PANEL_W / 2 - 10, 25, "", { en = "Rank Name", ar = "اسم الرتبة" }, _, UI.container.ranks)
        UI.edit.RankWage = eui:uiCreateEdit(PANEL_W / 2 + 5, 40, PANEL_W / 2 - 10, 25, "", { en = "Rank Wage", ar = "راتب الرتبة" }, _, UI.container.ranks)
        UI.label.RanksHint = eui:uiCreateLabel(PANEL_W / 2 + 5, 75, PANEL_W / 2 - 10, 40,
                "اختر رتبة من القائمة ثم عدّل الاسم والراتب.\nالترتيب من الأعلى (قائد) إلى الأسفل.", tocolor(255, 255, 255, 150), "left", "top", UI.container.ranks)
        UI.button["Ranks.Save"] = eui:uiCreateButton(PANEL_W - 145, BTN_ROW, 140, 30, { en = "Save Changes", ar = "حفظ التغييرات" }, _, UI.container.ranks)

        -- ================= NOTES =================
        eui:uiCreateLabel(5, 5, 300, 20, { en = "Notes (leader only)", ar = "الملاحظات (للقائد)" }, tocolor(255, 255, 255, 160), "left", "top", UI.container.notes)
        UI.memo.Notes = eui:uiCreateMemo(5, 30, PANEL_W / 2 - 10, PANEL_H - 80, "", tocolor(5, 5, 5, 240), UI.container.notes)
        eui:uiSetProperty(UI.memo.Notes, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiCreateLabel(PANEL_W / 2 + 5, 5, 300, 20, { en = "MOTD", ar = "رسالة اليوم" }, tocolor(255, 255, 255, 160), "left", "top", UI.container.notes)
        UI.memo.MOTD = eui:uiCreateMemo(PANEL_W / 2 + 5, 30, PANEL_W / 2 - 10, PANEL_H - 80, "", tocolor(5, 5, 5, 240), UI.container.notes)
        eui:uiSetProperty(UI.memo.MOTD, "TextColor", tocolor(255, 255, 255, 255))
        UI.button["Notes.Save"] = eui:uiCreateButton(5, PANEL_H - 40, 140, 35, { en = "Save Notes", ar = "حفظ الملاحظات" }, _, UI.container.notes)
        UI.button["MOTD.Save"] = eui:uiCreateButton(PANEL_W / 2 + 5, PANEL_H - 40, 140, 35, { en = "Save MOTD", ar = "حفظ الرسالة" }, _, UI.container.notes)

        -- ================= MANAGEMENT =================
        UI.label.FactionBank = eui:uiCreateLabel(10, 15, PANEL_W - 20, 120, "", tocolor(255, 255, 255, 255), "left", "top", UI.container.management)
        eui:uiSetFont(UI.label.FactionBank, "default-large")
        UI.button["Management.Refresh"] = eui:uiCreateButton(10, 150, 200, 30, { en = "Refresh Bank", ar = "تحديث البنك" }, _, UI.container.management)
        UI.button["Management.Quit"] = eui:uiCreateButton(10, PANEL_H - 40, 200, 30, { en = "Quit Faction", ar = "مغادرة الفاكشن" }, _, UI.container.management)
        eui:uiSetProperty(UI.button["Management.Quit"], "HoverTextColor", tocolor(255, 48, 48))

        -- ================= PROPERTIES (vehicles) =================
        UI.gridlist.Vehicles = eui:uiCreateGridList(0, 0, PANEL_W, PANEL_H - 45, tocolor(20, 20, 20, 0), UI.container.properties)
        eui:uiGridListAddColumn(UI.gridlist.Vehicles, { en = "ID", ar = "ID" }, 0.1)
        eui:uiGridListAddColumn(UI.gridlist.Vehicles, { en = "Name", ar = "الاسم" }, 0.4)
        eui:uiGridListAddColumn(UI.gridlist.Vehicles, { en = "Plate", ar = "اللوحة" }, 0.15)
        eui:uiGridListAddColumn(UI.gridlist.Vehicles, { en = "Location", ar = "الموقع" }, 0.35)
        eui:uiSetAlign(UI.gridlist.Vehicles, "left", "center")
        UI.button["Vehicles.RespawnAll"] = eui:uiCreateButton(PANEL_W - 160, BTN_ROW, 155, 30, { en = "Respawn All Vehicles", ar = "رسبنة جميع المركبات" }, _, UI.container.properties)
        UI.label["Vehicles.Limit"] = eui:uiCreateLabel(0, BTN_ROW, 400, 30, "", tocolor(255, 255, 255, 150), "left", "center", UI.container.properties)
        eui:uiSetFont(UI.label["Vehicles.Limit"], "default-large")

        -- ================= DUTY (tab panel) =================
        UI.tabpanel.Duty = eui:uiCreateTabPanel(0, 0, PANEL_W, PANEL_H, "", tocolor(30, 30, 30, 0), UI.container.duty)
        eui:uiSetProperty(UI.tabpanel.Duty, "title_shown", false)
        UI.tab.DutyPerksPkg = eui:uiCreateTab({ en = "Duty Perks", ar = "المناوبات" }, "Duty Perks", UI.tabpanel.Duty)
        UI.gridlist.DutyPerks = eui:uiCreateGridList(0, 10, PANEL_W - 10, PANEL_H - 90, tocolor(20, 20, 20, 0), UI.tab.DutyPerksPkg)
        eui:uiGridListAddColumn(UI.gridlist.DutyPerks, { en = "ID", ar = "ID" }, 0.15)
        eui:uiGridListAddColumn(UI.gridlist.DutyPerks, { en = "Name", ar = "الاسم" }, 0.85)
        UI.button["DP:Add"] = eui:uiCreateButton(0, PANEL_H - 70, 150, 30, { en = "Add New Duty", ar = "إضافة مناوبة" }, _, UI.tab.DutyPerksPkg)
        UI.button["DP:Remove"] = eui:uiCreateButton(155, PANEL_H - 70, 150, 30, { en = "Remove Duty", ar = "حذف مناوبة" }, _, UI.tab.DutyPerksPkg)

        UI.tab.DutyLocations = eui:uiCreateTab({ en = "Duty Locations", ar = "مواقع الخدمة" }, "Duty Locations", UI.tabpanel.Duty)
        UI.gridlist.DutyLocations = eui:uiCreateGridList(0, 10, PANEL_W - 10, PANEL_H - 90, tocolor(20, 20, 20, 0), UI.tab.DutyLocations)
        eui:uiGridListAddColumn(UI.gridlist.DutyLocations, { en = "ID", ar = "ID" }, 0.1)
        eui:uiGridListAddColumn(UI.gridlist.DutyLocations, { en = "Name", ar = "الاسم" }, 0.3)
        eui:uiGridListAddColumn(UI.gridlist.DutyLocations, { en = "Interior", ar = "ال Inside" }, 0.12)
        eui:uiGridListAddColumn(UI.gridlist.DutyLocations, { en = "Dimension", ar = "العالم" }, 0.12)
        eui:uiGridListAddColumn(UI.gridlist.DutyLocations, { en = "X, Y, Z", ar = "X, Y, Z" }, 0.36)
        UI.button["DL:Add"] = eui:uiCreateButton(0, PANEL_H - 70, 150, 30, { en = "Add Location", ar = "إضافة موقع" }, _, UI.tab.DutyLocations)
        UI.button["DL:Remove"] = eui:uiCreateButton(155, PANEL_H - 70, 150, 30, { en = "Remove Location", ar = "حذف الموقع" }, _, UI.tab.DutyLocations)

        UI.tab.DutyVehicles = eui:uiCreateTab({ en = "Duty Vehicles", ar = "مركبات الخدمة" }, "Duty Vehicles", UI.tabpanel.Duty)
        UI.gridlist.DutyVehicles = eui:uiCreateGridList(0, 10, PANEL_W - 10, PANEL_H - 90, tocolor(20, 20, 20, 0), UI.tab.DutyVehicles)
        eui:uiGridListAddColumn(UI.gridlist.DutyVehicles, { en = "ID", ar = "ID" }, 0.2)
        eui:uiGridListAddColumn(UI.gridlist.DutyVehicles, { en = "Vehicle ID", ar = "رقم المركبة" }, 0.4)
        eui:uiGridListAddColumn(UI.gridlist.DutyVehicles, { en = "Name", ar = "الاسم" }, 0.4)
        UI.button["DVL:Add"] = eui:uiCreateButton(0, PANEL_H - 70, 150, 30, { en = "Add Vehicle Location", ar = "إضافة مركبة" }, _, UI.tab.DutyVehicles)
        UI.button["DVL:Remove"] = eui:uiCreateButton(155, PANEL_H - 70, 170, 30, { en = "Remove Vehicle Location", ar = "حذف مركبة" }, _, UI.tab.DutyVehicles)

        -- ================= LOGS =================
        UI.gridlist.Logs = eui:uiCreateGridList(5, 5, PANEL_W - 10, PANEL_H - 10, tocolor(20, 20, 20, 0), UI.container.logs)
        eui:uiGridListAddColumn(UI.gridlist.Logs, { en = "Log", ar = "الحدث" }, 0.82)
        eui:uiGridListAddColumn(UI.gridlist.Logs, { en = "Date", ar = "التاريخ" }, 0.18)
        eui:uiSetAlign(UI.gridlist.Logs, "left", "center")

        -- ============ sub windows ============
        UI.window["Promote/Demote"] = eui:uiCreateWindow(false, false, 400, 380, { en = "Promote/Demote Member", ar = "ترقية/خفض العضو" })
        eui:uiWindowSetMovable(UI.window["Promote/Demote"], false)
        eui:uiSetVisible(UI.window["Promote/Demote"], false)
        UI.gridlist["Promote/Demote"] = eui:uiCreateGridList(0, 50, 400, 300, tocolor(10, 10, 10, 0), UI.window["Promote/Demote"])
        eui:uiGridListAddColumn(UI.gridlist["Promote/Demote"], { en = "Double Click To Select", ar = "ضغط مزدوج للاختيار" }, 0.7)
        eui:uiGridListAddColumn(UI.gridlist["Promote/Demote"], "", 0.3)
        eui:uiSetAlign(UI.gridlist["Promote/Demote"], "left", "center")
        UI.button["CancelPromote/Demote"] = eui:uiCreateButton(5, 355, 390, 25, { en = "Cancel", ar = "إلغاء" }, _, UI.window["Promote/Demote"])

        UI.window.DutyPerks = eui:uiCreateWindow(false, false, 400, 350, { en = "Duty Perks For Member", ar = "امتيازات الديوتي للعضو" })
        eui:uiWindowSetMovable(UI.window.DutyPerks, false)
        eui:uiSetVisible(UI.window.DutyPerks, false)
        UI.checklist.DutyPerks = eui:uiCreateCheckList(0, 50, 400, 265, tocolor(10, 10, 10, 0), UI.window.DutyPerks)
        UI.button["Member.DutyPerks.Save"] = eui:uiCreateButton(5, 320, 390, 30, { en = "Save Changes", ar = "حفظ التغييرات" }, _, UI.window.DutyPerks)

        UI.window.AddMember = eui:uiCreateWindow(false, false, 250, 150, { en = "Add Member", ar = "إضافة عضو" })
        eui:uiWindowSetMovable(UI.window.AddMember, false)
        eui:uiSetVisible(UI.window.AddMember, false)
        UI.edit.AddMember = eui:uiCreateEdit(10, 50, 230, 30, "", { en = "Character Name", ar = "اسم الشخصية" }, _, UI.window.AddMember)
        UI.label.SearchPlayer = eui:uiCreateLabel(5, 85, 240, 15, "...", tocolor(255, 255, 255, 240), "left", "top", UI.window.AddMember)
        eui:uiSetAlign(UI.label.SearchPlayer, "center", "center")
        UI.button.AddMember = eui:uiCreateButton(5, 115, 119, 30, { en = "Add", ar = "إضافة" }, _, UI.window.AddMember)
        UI.button.CloseAddMember = eui:uiCreateButton(126, 115, 119, 30, { en = "Close", ar = "إغلاق" }, _, UI.window.AddMember)

        -- SelectFaction
        UI.window.SelectFaction = eui:uiCreateWindow(false, false, 400, 250, { en = "Select Faction", ar = "اختر الفاكشن" })
        eui:uiWindowSetMovable(UI.window.SelectFaction, false)
        eui:uiSetVisible(UI.window.SelectFaction, false)
        eui:uiSetProperty(UI.window.SelectFaction, "close_button", true)
        UI.gridlist.SelectFaction = eui:uiCreateGridList(0, 40, 400, 210, tocolor(0, 0, 0, 0), UI.window.SelectFaction)
        eui:uiGridListAddColumn(UI.gridlist.SelectFaction, { en = "Faction name", ar = "اسم الفاكشن" }, 1)
        eui:uiSetAlign(UI.gridlist.SelectFaction, "left", "center")
        eui:uiSetProperty(UI.gridlist.SelectFaction, "row_height", 28)
end

-- ===========================================================================
-- menu + sections
-- ===========================================================================

local function reloadMenu()
        local r, g, b = factionColor()
        eui:uiMenuClear(UI.menu.main)
        for _, sec in ipairs(SECTIONS) do
                if sec.level == "Member" or F.isLeader then
                        eui:uiMenuAddRow(UI.menu.main, sec.title, tocolor(r, g, b, 255), sec.icon, UI.container[sec.id], sec.id)
                end
        end
        eui:uiMenuSetSelectedRow(UI.menu.main, 1)
end

local function showSection(id)
        for _, sec in ipairs(SECTIONS) do
                eui:uiSetVisible(UI.container[sec.id], sec.id == id)
        end
end

local function refreshMembersGrid()
        eui:uiGridListClear(UI.gridlist.Members)
        for _, m in ipairs(F.members) do
                local row = eui:uiGridListAddRow(UI.gridlist.Members)
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 1, tostring(m.name))
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 2, "#" .. tostring(m.rank) .. " " .. tostring(m.rankName))
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 3, tostring(m.login))
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 4, m.wage and ("$" .. tostring(m.wage)) or "-")
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 5, tostring(m.phone ~= "" and m.phone or "-"))
                eui:uiGridListSetItemText(UI.gridlist.Members, row, 6, m.duty and "في الخدمة" or "-")
                local c = m.online and tocolor(0, 255, 0, 255) or tocolor(255, 0, 0, 255)
                for col = 1, 6 do
                        eui:uiGridListSetItemColor(UI.gridlist.Members, row, col, c)
                end
        end
end

local function refreshRanksGrid()
        eui:uiGridListClear(UI.gridlist.FactionRanks)
        local ranks = F.data and F.data.factionRanks or {}
        local wages = F.data and F.data.factionWages or {}
        for i, name in ipairs(ranks) do
                local row = eui:uiGridListAddRow(UI.gridlist.FactionRanks)
                eui:uiGridListSetItemText(UI.gridlist.FactionRanks, row, 1, "#" .. i .. " " .. tostring(name))
                eui:uiGridListSetItemText(UI.gridlist.FactionRanks, row, 2, "$" .. tostring(wages[i] or 0))
                eui:uiGridListSetItemData(UI.gridlist.FactionRanks, row, 1, { id = i, name = tostring(name), wage = tonumber(wages[i]) or 0 })
        end
end

local function refreshVehiclesGrid()
        eui:uiGridListClear(UI.gridlist.Vehicles)
        local d = F.data
        if not d then return end
        for i = 1, #(d.vehicleIDs or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.Vehicles)
                eui:uiGridListSetItemText(UI.gridlist.Vehicles, row, 1, tostring(d.vehicleIDs[i]))
                eui:uiGridListSetItemText(UI.gridlist.Vehicles, row, 2, getVehicleNameFromModel(tonumber(d.vehicleModels[i]) or 0) or tostring(d.vehicleModels[i] or "?"))
                eui:uiGridListSetItemText(UI.gridlist.Vehicles, row, 3, tostring(d.vehiclePlates[i] or "-"))
                eui:uiGridListSetItemText(UI.gridlist.Vehicles, row, 4, tostring(d.vehicleLocations[i] or "-"))
        end
        local vehLimit = F.data.vehLimit
        if vehLimit then
                eui:uiSetText(UI.label["Vehicles.Limit"], tostring(#(d.vehicleIDs or {})) .. " / " .. tostring(vehLimit))
        else
                eui:uiSetText(UI.label["Vehicles.Limit"], tostring(#(d.vehicleIDs or {})))
        end
end

local function refreshDutyGrids()
        eui:uiGridListClear(UI.gridlist.DutyPerks)
        for _, p in ipairs(F.dutyPackages or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.DutyPerks)
                eui:uiGridListSetItemText(UI.gridlist.DutyPerks, row, 1, tostring(p.id or "-"))
                eui:uiGridListSetItemText(UI.gridlist.DutyPerks, row, 2, tostring(p.name or "-"))
        end
        eui:uiGridListClear(UI.gridlist.DutyLocations)
        eui:uiGridListClear(UI.gridlist.DutyVehicles)
        for _, l in ipairs(F.dutyLocations or {}) do
                local row = eui:uiGridListAddRow(UI.gridlist.DutyLocations)
                eui:uiGridListSetItemText(UI.gridlist.DutyLocations, row, 1, tostring(l[1] or "-"))
                eui:uiGridListSetItemText(UI.gridlist.DutyLocations, row, 2, tostring(l[2] or "-"))
                eui:uiGridListSetItemText(UI.gridlist.DutyLocations, row, 3, tostring(l[6] or "-"))
                eui:uiGridListSetItemText(UI.gridlist.DutyLocations, row, 4, tostring(l[7] or "-"))
                eui:uiGridListSetItemText(UI.gridlist.DutyLocations, row, 5, string.format("%s, %s, %s", tostring(l[3] or 0), tostring(l[4] or 0), tostring(l[5] or 0)))
                if l[10] then
                        local vrow = eui:uiGridListAddRow(UI.gridlist.DutyVehicles)
                        eui:uiGridListSetItemText(UI.gridlist.DutyVehicles, vrow, 1, tostring(l[1] or "-"))
                        eui:uiGridListSetItemText(UI.gridlist.DutyVehicles, vrow, 2, tostring(l[10]))
                        eui:uiGridListSetItemText(UI.gridlist.DutyVehicles, vrow, 3, getVehicleNameFromModel(tonumber(l[10]) or 0) or tostring(l[10]))
                end
        end
end

local function refreshLogsGrid()
        eui:uiGridListClear(UI.gridlist.Logs)
        for _, l in ipairs(F.actionLog) do
                local row = eui:uiGridListAddRow(UI.gridlist.Logs)
                eui:uiGridListSetItemText(UI.gridlist.Logs, row, 1, tostring(l.text))
                eui:uiGridListSetItemText(UI.gridlist.Logs, row, 2, tostring(l.at))
        end
end

local function refreshHeader()
        local r, g, b = factionColor()
        local hex = string.format("#%.2X%.2X%.2X", r, g, b)
        local d = F.data
        eui:uiSetText(UI.label.FactionTitle, hex .. " #" .. tostring(F.factionID) .. "  " .. tostring(F.team and getTeamName(F.team) or "?"))
        local online = F.onlineCount or 0
        eui:uiSetText(UI.label.FactionInfo,
                hex .. "• النوع » #FFFFFF" .. typeAr(F.factionType) .. "\n" ..
                hex .. "• الأعضاء » #FFFFFF" .. tostring(#F.members) .. " / 20" .. "\n" ..
                hex .. "• متصل الآن » #00FF00" .. tostring(online))
        eui:uiSetText(UI.label.FactionInfo2,
                hex .. "• الخط الساخن » #FFFFFF" .. tostring((d and d.phone) or "-") .. "\n" ..
                hex .. "• رسالة اليوم » #FFFFFF" .. tostring((d and d.motd) or "-"))
        eui:uiSetText(UI.label.level, "الأعضاء")
        eui:uiSetText(UI.label.level_points, tostring(online) .. " متصل من " .. tostring(#F.members) .. " / 20")
end

local function applyLeaderRights()
        local leader = F.isLeader
        for _, btn in ipairs({ "Member.Dismissal", "Member.Promote/Demote", "Member.DutyPerks", "Member.SetLevel", "Member.AddMember" }) do
                eui:uiSetVisible(UI.button[btn], leader)
        end
        eui:uiSetVisible(UI.button["Ranks.Save"], leader)
        eui:uiSetVisible(UI.button["Notes.Save"], leader)
        eui:uiSetVisible(UI.button["MOTD.Save"], leader)
        eui:uiSetVisible(UI.button["Vehicles.RespawnAll"], leader)
        eui:uiMemoSetReadOnly(UI.memo.Notes, not leader)
        eui:uiMemoSetReadOnly(UI.memo.MOTD, not leader)
end

-- ===========================================================================
-- show / hide
-- ===========================================================================

local function closeAllWindows()
        eui:uiSetVisible(UI.window.FactionWindow, false)
        eui:uiSetVisible(UI.window.SelectFaction, false)
        eui:uiSetVisible(UI.window["Promote/Demote"], false)
        eui:uiSetVisible(UI.window.DutyPerks, false)
        eui:uiSetVisible(UI.window.AddMember, false)
end

function factionUIHide()
        F.visible = false
        closeAllWindows()
        showCursor(false)
end

addEvent("factionmenu:hide", true)
addEventHandler("factionmenu:hide", root, function()
        factionUIHide()
end)

addEventHandler("onClientPlayerWasted", localPlayer, function()
        if F.visible then factionUIHide() end
end)

addEventHandler("onClientKey", root, function(button, press)
        if button == "escape" and press and F.visible then
                local cancel = false
                if eui:uiGetVisible(UI.window["Promote/Demote"]) or eui:uiGetVisible(UI.window.DutyPerks) or eui:uiGetVisible(UI.window.AddMember) then
                        eui:uiSetVisible(UI.window["Promote/Demote"], false)
                        eui:uiSetVisible(UI.window.DutyPerks, false)
                        eui:uiSetVisible(UI.window.AddMember, false)
                        cancel = true
                end
                if not cancel then
                        factionUIHide()
                        triggerServerEvent("factionmenu:hide", localPlayer)
                end
                cancelEvent()
        end
end)

-- ===========================================================================
-- data flow (server contract unchanged)
-- ===========================================================================

addEventHandler("showFactionMenu", root, function(motd, memberUsernames, memberRanks, memberPerks, memberLeaders,
        memberOnline, memberLastLogin, factionRanks, factionWages, theTeam, note, fnote, vehicleIDs, vehicleModels,
        vehiclePlates, vehicleLocations, memberOnDuty, towstats, phone, membersPhone, fromShowF, factionID)
        if not theTeam then return end

        buildUI()
        F.data = {
                motd = motd, memberUsernames = memberUsernames, memberRanks = memberRanks, memberPerks = memberPerks,
                memberLeaders = memberLeaders, memberOnline = memberOnline, memberLastLogin = memberLastLogin,
                factionRanks = factionRanks, factionWages = factionWages, team = theTeam, note = note, fnote = fnote,
                vehicleIDs = vehicleIDs, vehicleModels = vehicleModels, vehiclePlates = vehiclePlates,
                vehicleLocations = vehicleLocations, memberOnDuty = memberOnDuty, towstats = towstats,
                phone = phone, membersPhone = membersPhone,
        }
        F.team = theTeam
        F.factionID = factionID or getElementData(localPlayer, "faction") or -1
        F.factionType = tonumber(getElementData(theTeam, "type")) or 0
        F.noteBuffer = note or ""
        F.motdBuffer = motd or ""
        F.isLeader = fromShowF or false

        if not F.isLeader then
                local myName = getPlayerName(localPlayer)
                for k, v in ipairs(memberUsernames or {}) do
                        if v == myName and memberLeaders and memberLeaders[k] then F.isLeader = true end
                end
        end

        F.members = {}
        F.onlineCount = 0
        for k, name in ipairs(memberUsernames or {}) do
                local rank = tonumber(memberRanks[k]) or 1
                local lastLogin = tonumber(memberLastLogin[k])
                local loginText = "أبداً"
                if lastLogin == 0 then loginText = "اليوم"
                elseif lastLogin == 1 then loginText = "أمس"
                elseif lastLogin and lastLogin > 1 then loginText = lastLogin .. " يوم" end
                local isOnline = memberOnline and memberOnline[k] == true
                if isOnline then F.onlineCount = F.onlineCount + 1 end
                local phoneTxt = ""
                if phone and membersPhone and membersPhone[k] then
                        phoneTxt = tostring(phone) .. "-" .. tostring(membersPhone[k])
                end
                table.insert(F.members, {
                        name = tostring(name):gsub("_", " "), rawName = name, rank = rank,
                        rankName = (factionRanks and factionRanks[rank]) or ("رتبة " .. rank),
                        login = loginText, online = isOnline,
                        duty = memberOnDuty and memberOnDuty[k] == true,
                        leader = (memberLeaders and memberLeaders[k]) or false,
                        wage = factionWages and tonumber(factionWages[rank]) or nil,
                        phone = phoneTxt,
                        perks = (memberPerks and type(memberPerks[k]) == "table" and memberPerks[k]) or {},
                })
        end

        eui:uiSetText(UI.memo.Notes, F.noteBuffer)
        eui:uiSetText(UI.memo.MOTD, F.motdBuffer)
        refreshHeader()
        refreshMembersGrid()
        refreshRanksGrid()
        refreshVehiclesGrid()
        refreshDutyGrids()
        refreshLogsGrid()
        applyLeaderRights()
        reloadMenu()
        showSection("members")
        F.section = "members"

        F.visible = true
        eui:uiSetVisible(UI.window.FactionWindow, true)
        showCursor(true)
end)

addEventHandler("onClientUIMenuSelectChange", root, function(row)
        if source ~= UI.menu.main then return end
        local id = eui:uiMenuGetItemID(source, row)
        if not id then return end
        F.section = id
        showSection(id)
        if id == "duty" then
                triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
        elseif id == "management" and not F.financeLoaded then
                triggerServerEvent("factionmenu:getFinance", getResourceRootElement())
        elseif id == "logs" then
                refreshLogsGrid()
        end
end)

addEvent("factionmenu:fillFinance", true)
addEventHandler("factionmenu:fillFinance", root, function(factionID, bankThisWeek, bankPrevWeek, bankmoney, vehiclesvalue, propertiesvalue)
        F.finance = {
                bankmoney = bankmoney or 0, vehiclesvalue = vehiclesvalue or 0,
                propertiesvalue = propertiesvalue or 0,
        }
        F.financeLoaded = true
        local fmt = function(n)
                local s = tostring(math.floor(tonumber(n) or 0))
                local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
                return out:gsub("^,", "")
        end
        eui:uiSetText(UI.label.FactionBank,
                "حساب الفاكشن:\n#00FF00$" .. fmt(F.finance.bankmoney) .. "\n\n" ..
                "قيمة المركبات: #FFFFFF$" .. fmt(F.finance.vehiclesvalue) .. "\n" ..
                "قيمة العقارات: #FFFFFF$" .. fmt(F.finance.propertiesvalue))
        eui:uiSetProperty(UI.label.FactionBank, "color_coded", true)
end)

addEvent("importDutyData", true)
addEventHandler("importDutyData", resourceRoot, function(custom, locations, factionID, message)
        if message then outputChatBox(message, 255, 194, 14) end
        F.dutyLocations = locations or {}
        refreshDutyGrids()
end)

addEvent("Duty:GotPackages", true)
addEventHandler("Duty:GotPackages", resourceRoot, function(packages)
        F.dutyPackages = packages or {}
        refreshDutyGrids()
end)

addEvent("gotAllow", true)
addEventHandler("gotAllow", resourceRoot, function(allowList)
        F.dutyAllow = allowList or {}
end)

-- ===========================================================================
-- clicks
-- ===========================================================================

local selectedMemberRow = function()
        local sel = eui:uiGridListGetSelectedItem(UI.gridlist.Members)
        if sel == -1 then return nil end
        return F.members[sel + 1]
end

addEventHandler("onClientUIClick", root, function()
        if not F.visible then return end

        if isLabelButton[source] == "ChangeFaction" then
                eui:uiSetVisible(UI.window.SelectFaction, true)
                eui:uiGridListClear(UI.gridlist.SelectFaction)
                local row = eui:uiGridListAddRow(UI.gridlist.SelectFaction)
                eui:uiGridListSetItemText(UI.gridlist.SelectFaction, row, 1, F.team and getTeamName(F.team) or "?")
                eui:uiGridListSetItemData(UI.gridlist.SelectFaction, row, 1, F.factionID)
                eui:uiGridListSetItemColor(UI.gridlist.SelectFaction, row, 1, eui:uiGetThemeColor("primary"))
                return
        end

        if source == UI.gridlist.Members then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.Members)
                F.selectedMember = (sel ~= -1) and (sel + 1) or 0
                local m = selectedMemberRow()
                if m then
                        eui:uiSetText(UI.button["Member.SetLevel"], m.leader and { en = "Set Member", ar = "تعيين عضو" } or { en = "Set Leader", ar = "تعيين قائد" })
                end
                return
        end

        if source == UI.button["Member.Dismissal"] then
                local m = selectedMemberRow()
                if m then
                        logAction("طرد " .. m.name)
                        triggerServerEvent("cguiKickPlayer", localPlayer, m.rawName)
                        factionUIHide()
                        triggerServerEvent("factionmenu:hide", localPlayer)
                end
        elseif source == UI.button["Member.Promote/Demote"] then
                local m = selectedMemberRow()
                if m then
                        F.currentRank = m.rank
                        eui:uiGridListClear(UI.gridlist["Promote/Demote"])
                        local ranks = F.data.factionRanks or {}
                        local wages = F.data.factionWages or {}
                        for i, rname in ipairs(ranks) do
                                local row = eui:uiGridListAddRow(UI.gridlist["Promote/Demote"])
                                eui:uiGridListSetItemText(UI.gridlist["Promote/Demote"], row, 1, "#" .. i .. " " .. tostring(rname))
                                eui:uiGridListSetItemText(UI.gridlist["Promote/Demote"], row, 2, "$" .. tostring(wages[i] or 0))
                                eui:uiGridListSetItemColor(UI.gridlist["Promote/Demote"], row, 1, i == m.rank and tocolor(0, 255, 0, 255) or tocolor(255, 255, 255, 255))
                        end
                        eui:uiSetVisible(UI.window["Promote/Demote"], true)
                        eui:uiBringToFront(UI.window["Promote/Demote"])
                end
        elseif source == UI.button["CancelPromote/Demote"] then
                eui:uiSetVisible(UI.window["Promote/Demote"], false)
        elseif source == UI.button["Member.DutyPerks"] then
                local m = selectedMemberRow()
                if m then
                        F.perksMember = m
                        eui:uiCheckListClear(UI.checklist.DutyPerks)
                        for _, perk in ipairs(F.dutyAllow or {}) do
                                eui:uiCheckListAddRow(UI.checklist.DutyPerks, tostring(perk), eui:uiGetThemeColor("primary"), m.perks[perk] == true)
                        end
                        eui:uiSetVisible(UI.window.DutyPerks, true)
                        eui:uiBringToFront(UI.window.DutyPerks)
                end
        elseif source == UI.button["Member.DutyPerks.Save"] then
                local m = F.perksMember
                if m then
                        local perkTable = {}
                        for _, idx in ipairs(eui:uiCheckListGetSelectedItems(UI.checklist.DutyPerks) or {}) do
                                perkTable[eui:uiCheckListGetItemText(UI.checklist.DutyPerks, idx)] = true
                        end
                        logAction("تعديل امتيازات " .. m.name)
                        triggerServerEvent("faction:perks:edit", localPlayer, perkTable, m.rawName)
                end
                eui:uiSetVisible(UI.window.DutyPerks, false)
                factionUIHide()
                triggerServerEvent("factionmenu:hide", localPlayer)
        elseif source == UI.button["Member.SetLevel"] then
                local m = selectedMemberRow()
                if m then
                        logAction((m.leader and "إقالة قائد " or "تعيين قائد ") .. m.name)
                        triggerServerEvent("cguiToggleLeader", localPlayer, m.rawName, not m.leader)
                        factionUIHide()
                        triggerServerEvent("factionmenu:hide", localPlayer)
                end
        elseif source == UI.button["Member.AddMember"] then
                eui:uiSetText(UI.edit.AddMember, "")
                eui:uiSetText(UI.label.SearchPlayer, "...")
                eui:uiSetVisible(UI.window.AddMember, true)
                eui:uiBringToFront(UI.window.AddMember)
        elseif source == UI.button.AddMember then
                local text = eui:uiGetText(UI.edit.AddMember):gsub(" ", "_")
                if text ~= "" then
                        -- prefer the live-search result so a partial name works
                        local found = F.searchResult or getPlayerFromName(text)
                        F.searchResult = nil
                        if found then
                                logAction("إضافة العضو " .. text)
                                triggerServerEvent("cguiInvitePlayer", localPlayer, found)
                                eui:uiSetVisible(UI.window.AddMember, false)
                                factionUIHide()
                                triggerServerEvent("factionmenu:hide", localPlayer)
                        else
                                eui:uiSetText(UI.label.SearchPlayer, "اللاعب غير متصل")
                        end
                end
        elseif source == UI.button.CloseAddMember then
                eui:uiSetVisible(UI.window.AddMember, false)
        elseif source == UI.button["Ranks.Save"] then
                local count = eui:uiGridListGetRowCount(UI.gridlist.FactionRanks)
                if count > 0 then
                        local ranks, wages = {}, {}
                        for i = 0, count - 1 do
                                local d = eui:uiGridListGetItemData(UI.gridlist.FactionRanks, i, 1)
                                ranks[#ranks + 1] = tostring(d and d.name or "")
                                wages[#wages + 1] = tonumber(d and d.wage or 0) or 0
                        end
                        logAction("حفظ الرتب")
                        triggerServerEvent("cguiUpdateRanks", localPlayer, ranks, wages)
                        outputChatBox("تم حفظ الرتب", 80, 255, 120)
                end
        elseif source == UI.button["Notes.Save"] then
                F.noteBuffer = eui:uiGetText(UI.memo.Notes)
                logAction("حفظ الملاحظات")
                triggerServerEvent("faction:note", localPlayer, F.noteBuffer)
        elseif source == UI.button["MOTD.Save"] then
                F.motdBuffer = eui:uiGetText(UI.memo.MOTD)
                logAction("حفظ رسالة اليوم")
                triggerServerEvent("cguiUpdateMOTD", localPlayer, F.motdBuffer)
        elseif source == UI.button["Management.Refresh"] then
                F.financeLoaded = false
                triggerServerEvent("factionmenu:getFinance", getResourceRootElement())
        elseif source == UI.button["Management.Quit"] then
                logAction("مغادرة الفاكشن")
                triggerServerEvent("cguiQuitFaction", localPlayer)
                factionUIHide()
        elseif source == UI.button["Vehicles.RespawnAll"] then
                logAction("رسبنة جميع المركبات")
                triggerServerEvent("cguiRespawnVehicles", localPlayer)
        elseif source == UI.button["DP:Add"] then
                triggerServerEvent("Duty:AddDuty", resourceRoot, {}, {}, {}, "Duty " .. tostring((#F.dutyPackages or 0) + 1), F.factionID, 0)
                logAction("إضافة مناوبة")
                triggerServerEvent("Duty:GetPackages", resourceRoot, F.factionID)
        elseif source == UI.button["DP:Remove"] then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.DutyPerks)
                if sel ~= -1 then
                        local p = F.dutyPackages[sel + 1]
                        triggerServerEvent("Duty:RemoveDuty", resourceRoot, tonumber(p and p.id) or p, F.factionID)
                        logAction("حذف مناوبة")
                        triggerServerEvent("Duty:GetPackages", resourceRoot, F.factionID)
                end
        elseif source == UI.button["DL:Add"] then
                local x, y, z = getElementPosition(localPlayer)
                triggerServerEvent("Duty:AddLocation", resourceRoot, x, y, z, 3, getElementInterior(localPlayer), getElementDimension(localPlayer), "موقع خدمة", F.factionID, nil)
                logAction("إضافة موقع خدمة")
                triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
        elseif source == UI.button["DL:Remove"] then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.DutyLocations)
                if sel ~= -1 then
                        local l = F.dutyLocations[sel + 1]
                        triggerServerEvent("Duty:RemoveLocation", resourceRoot, tonumber(l and l[1]) or l, F.factionID)
                        logAction("حذف موقع خدمة")
                        triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
                end
        elseif source == UI.button["DVL:Add"] then
                local veh = getPedOccupiedVehicle(localPlayer)
                if veh then
                        triggerServerEvent("Duty:AddVehicle", resourceRoot, getElementModel(veh), F.factionID)
                        logAction("إضافة مركبة خدمة")
                        triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
                else
                        outputChatBox("يجب أن تكون داخل مركبة", 255, 82, 110)
                end
        elseif source == UI.button["DVL:Remove"] then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.DutyVehicles)
                if sel ~= -1 then
                        local vehs = {}
                        for _, l in ipairs(F.dutyLocations or {}) do
                                if l[10] then table.insert(vehs, l) end
                        end
                        local l = vehs[sel + 1]
                        if l then
                                triggerServerEvent("Duty:RemoveLocation", resourceRoot, tonumber(l[1]) or l[1], F.factionID)
                                logAction("حذف مركبة خدمة")
                                triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
                        end
                end
        end
end)

-- double clicks -------------------------------------------------------------
addEventHandler("onClientUIDoubleClick", root, function()
        if not F.visible then return end
        if source == UI.gridlist["Promote/Demote"] then
                local m = F.members[F.selectedMember]
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist["Promote/Demote"])
                if m and sel ~= -1 then
                        local newRank = sel + 1
                        local ranks = F.data.factionRanks or {}
                        if newRank > m.rank then
                                logAction("ترقية " .. m.name .. " إلى #" .. newRank)
                                triggerServerEvent("cguiPromotePlayer", localPlayer, m.rawName, newRank,
                                        tostring(ranks[m.rank] or ""), tostring(ranks[newRank] or ""))
                        elseif newRank < m.rank then
                                logAction("خفض " .. m.name .. " إلى #" .. newRank)
                                triggerServerEvent("cguiDemotePlayer", localPlayer, m.rawName, newRank,
                                        tostring(ranks[m.rank] or ""), tostring(ranks[newRank] or ""))
                        end
                        eui:uiSetVisible(UI.window["Promote/Demote"], false)
                        factionUIHide()
                        triggerServerEvent("factionmenu:hide", localPlayer)
                end
        elseif source == UI.gridlist.SelectFaction then
                eui:uiSetVisible(UI.window.SelectFaction, false)
        elseif source == UI.gridlist.Vehicles then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.Vehicles)
                if sel ~= -1 then
                        local vid = F.data.vehicleIDs and F.data.vehicleIDs[sel + 1]
                        if vid then
                                logAction("رسبنة مركبة #" .. tostring(vid))
                                triggerServerEvent("cguiRespawnOneVehicle", localPlayer, tostring(vid))
                        end
                end
        end
end)

-- live search in the add-member window + rank edits ------------------------
addEventHandler("onClientUITextChange", root, function()
        if source == UI.edit.AddMember then
                local text = eui:uiGetText(source):lower()
                eui:uiSetText(UI.label.SearchPlayer, "...")
                if text ~= "" then
                        for _, p in ipairs(getElementsByType("player")) do
                                local cname = getElementData(p, "character:name")
                                if cname and string.find(tostring(cname):lower(), text, 1, true) then
                                        F.searchResult = p
                                        eui:uiSetText(UI.label.SearchPlayer, tostring(cname:gsub("_", " ")) .. " | " .. tostring(getElementData(p, "character:id") or "?"))
                                        break
                                end
                        end
                end
        elseif source == UI.edit.RankName or source == UI.edit.RankWage then
                local sel = eui:uiGridListGetSelectedItem(UI.gridlist.FactionRanks)
                if sel == -1 then return end
                local d = eui:uiGridListGetItemData(UI.gridlist.FactionRanks, sel, 1) or {}
                if source == UI.edit.RankName then
                        d.name = eui:uiGetText(source)
                elseif tonumber(eui:uiGetText(source)) then
                        d.wage = tonumber(eui:uiGetText(source))
                end
                eui:uiGridListSetItemText(UI.gridlist.FactionRanks, sel, 1, "#" .. tostring(d.id) .. " " .. tostring(d.name))
                eui:uiGridListSetItemText(UI.gridlist.FactionRanks, sel, 2, "$" .. tostring(d.wage or 0))
                eui:uiGridListSetItemData(UI.gridlist.FactionRanks, sel, 1, d)
        end
end)

-- introspection (tests / debugging): read access to the built UI tables
function factionUIGet(key) return UI[key] end
