--------------------------------------------------------------------------------
-- phone-system / phone_c.lua  (client)
--
-- [Fix #54] The NEW Owl iPhone - faithful client port of the old-client
-- phone-system v1.0 (decompiled reference: backupm/[rp]/phone-system/
-- phone_c_decompiled.lua). Same geometry (240*1.3 x 500*1.3 device), same
-- 14 apps, same SIM window, same call screens, same {en/ar} texts.
-- owlbakeup adaptations (each documented at its site):
--   * item 2 "Cellphone" = the phone; the SERVER sends the descriptor
--     (owlbakeup items are {itemID, itemValue}, no client item objects)
--   * onClientUseItem -> phone:itemUse fired by the item-system use branch
--   * exports.notifications -> exports.hud / chat
--   * exports.roleplay:getCharacterStat -> native getPedStat (same stat ids)
--   * exports.radar:findBestWay -> local blip fallback
--   * F3 bind removed (F3 = faction menu here); /phone + item click kept
--   * UIKit resolved LAZILY (Fix #52 class: no load-time UIKit calls)
--------------------------------------------------------------------------------

local REF_W, REF_H = 1728, 972 -- UIKit reference space fallback

local eui = nil                 -- UIKit exports bridge
local built = false
local UI = {
    window = {}, label = {}, edit = {}, button = {}, gridlist = {},
    memo = {}, app = {}, appIcon = {}, browser = {}, container = {},
    progressbar = {}, switch = {}, image = {}, rectangle = {},
}

-- the phone session (decompile: currentApp / data / item / call)
local app = {
    currentApp = false,
    item = false,          -- server descriptor {id, serial, phone_number, voucher}
    data = false,          -- {id, notes, contacts, sms, recents}
    currentID = false,     -- = item.phone_number (the identity in owlbakeup)
    currentWalletAccount = nil,
    current_whatsapp_phone_number = nil,
}
local default_contacts = { { "Emergency", 911 } }

local smsList = {}         -- {id, from, text, time}
local whatsappCache = {}   -- [phoneId] -> [peerNumber] -> {list = {{text,type,color,data}}}
local recents = {}         -- {outgoing, number, duration, end_at}
local sms_notifications = false
local contacts = {}        -- {{name, number}}
local myCall = { state = false, number = nil, callData = nil, startTick = nil }

local update_clock_timer, callTimer
local lastCallAttempt = 0
local ringtone_sound, callBusy

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------
local function ensureUIKit()
    if eui then return true end
    local u = getResourceFromName("UIKit")
    if not u or getResourceState(u) ~= "running" then return false end
    eui = exports.UIKit
    return true
end

local function lang()
    local ok, v = pcall(function() return exports.settings:getSetting("language") end)
    if ok and v then return "ar" end
    return "ar" -- Owl AR audience first; UIKit itself defaults to "ar" too
end

local function L(tbl)
    if type(tbl) == "table" then return tbl[lang()] or tbl.ar or tbl.en or "" end
    return tostring(tbl or "")
end

local function notify(textTbl, timeMs, r, g, b)
    outputChatBox(L(textTbl), 255, (r or 200), (g or 200), (b or 200))
end

local function playResSound(name)
    if fileExists(":" .. getResourceName(getThisResource()) .. "/" .. name) or fileExists(name) then
        playSound(name)
    end
end

local function formatNumber(n)
    n = tonumber(n) or 0
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    out = out:gsub("^,", "")
    return out
end

local function escHTML(s)
    s = tostring(s or "")
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
    s = s:gsub("\r", ""):gsub("\n", "<br>")
    return s
end

local function escJS(s)
    return escHTML(s):gsub("\\", "\\\\")
end

local function checkContactNumber(number)
    number = tostring(number)
    for _, c in ipairs(contacts) do
        if tostring(c[2]) == number then return tostring(c[1]) end
    end
    return number
end

local function hasActiveSIM()
    return app.item and app.item.phone_number and app.item.phone_number ~= false
end

local function getCurrentGameTime()
    local h, m = getTime()
    local suffix = h < 12 and "AM" or "PM"
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d %s", h12, m, suffix)
end

--------------------------------------------------------------------------------
-- UI BUILD (UIKitReady) - exact decompiled geometry
--------------------------------------------------------------------------------
local function UIKitReady()
    if built or not ensureUIKit() then return end
    local ok, err = pcall(function()
        local rw, rh = REF_W, REF_H
        pcall(function()
            local a, b = eui:uiGetReferenceScreenSize()
            if a and b then rw, rh = a, b end
        end)
        local DW, DH = 240 * 1.3, 500 * 1.3 -- 312 x 650

        -- ============================ SIM CARDS WINDOW ====================
        UI.window.SIM = eui:uiCreateWindow(false, false, 420, 325, "SIM Cards")
        eui:uiSetVisible(UI.window.SIM, false)
        eui:uiWindowSetMovable(UI.window.SIM, false)
        UI.label["SIM:Info"] = eui:uiCreateLabel(0, 50, 420, 20, {
            en = "Phone numbers registered in your name",
            ar = "أرقام الهواتف المسجلة باسمك",
        }, "primary", "center", "top", UI.window.SIM)
        UI.gridlist["SIM:OwnedNumbers"] = eui:uiCreateGridList(10, 75, 400, 120, _, UI.window.SIM)
        eui:uiGridListAddColumn(UI.gridlist["SIM:OwnedNumbers"], "Phone Number", 1)
        eui:uiCreateLabel(0, 205, 420, 20, {
            en = "You can buy a new phone number for $500",
            ar = "يمكنك شراء رقم هاتف جديد بـ$500",
        }, "primary", "center", "top", UI.window.SIM)
        UI.button["SIM:Buy"] = eui:uiCreateButton(10, 235, 195, 35, {
            en = "Buy a new number", ar = "شراء رقم جديد",
        }, _, UI.window.SIM)
        UI.button["SIM:GetCard"] = eui:uiCreateButton(215, 235, 195, 35, {
            en = "Get SIM card ($100)", ar = "($100) إخذ الشريحة",
        }, _, UI.window.SIM)
        UI.button["SIM:Close"] = eui:uiCreateButton(10, 280, 400, 35, {
            en = "Close", ar = "إغلاق",
        }, _, UI.window.SIM)

        -- ============================ DEVICE ==============================
        UI.image.screen = eui:uiCreateImage(rw - DW - 40 * 1.3, rh - DH - 40 * 1.3, DW, DH,
            ":phone-system/IMG/white_screen.png")
        eui:uiSetVisible(UI.image.screen, false)
        eui:uiSetProperty(UI.image.screen, "DisableFocus", "True")
        eui:uiSetColor(UI.image.screen, 10, 10, 10, 255)
        UI.image.wallpaper = eui:uiCreateImage(0, 0, DW, DH, ":phone-system/IMG/wallpaper3.png", UI.image.screen)
        eui:uiSetProperty(UI.image.wallpaper, "Disabled", "True")
        UI.image.device = eui:uiCreateImage(0, 0, DW, DH,
            dxCreateTexture(":phone-system/IMG/iPhone2.png", "argb", true, "clamp"), UI.image.screen)

        UI.label.carrier = eui:uiCreateLabel(40, 20 * 1.3, 60, 15 * 1.3, "••••• WT", tocolor(255, 255, 255), "left", "top", UI.image.device)
        eui:uiSetFontSize(UI.label.carrier, 0.8)
        UI.label.clock = eui:uiCreateLabel(DW - 80, 20 * 1.3, 60, 15 * 1.3, "9:41 AM", tocolor(255, 255, 255), "left", "top", UI.image.device)
        eui:uiSetFontSize(UI.label.clock, 0.8)

        -- home screen + dock
        UI.label.home_screen = eui:uiCreateLabel(0, 0, DW, DH, "", tocolor(255, 255, 255), "left", "top", UI.image.device)
        eui:uiSetProperty(eui:uiCreateRectangle((DW - 50 * 1.3 * 4) / 2, DH - 75 * 1.3, 50 * 1.3 * 4, 55 * 1.3,
            tocolor(0, 0, 0, 100), true, true, true, true, UI.label.home_screen), "border_radius", 16)

        local dockX = (DW - (45 * 1.3 + 1 * 1.3) * 4) / 2
        local dockY = DH - 70 * 1.3
        local dockIcons = { "Phone", "Contacts", "Messages", "Settings" }
        for i, name in ipairs(dockIcons) do
            UI.appIcon[i] = eui:uiCreateImage(dockX + (45 * 1.3 + 1 * 1.3) * (i - 1), dockY, 45 * 1.3, 45 * 1.3,
                ":phone-system/IMG/" .. name .. ".png", UI.label.home_screen)
        end
        local gridNames = { "Wallet", "Notes", "taxi", "Safari", "WhatsApp", "Flights",
            "electricity", "health", "traffic_tickets", "activities" }
        for i, name in ipairs(gridNames) do
            local row, col = math.floor((i - 1) / 4), (i - 1) % 4
            local gx = (DW - 50 * 1.3 * 4) / 2 + 50 * 1.3 * col
            local gy = 60 + 70 * row
            UI.appIcon[4 + i] = eui:uiCreateImage(gx, gy, 50 * 1.3, 50 * 1.3,
                ":phone-system/IMG/" .. name .. ".png", UI.label.home_screen)
        end
        for i = 1, 14 do
            eui:uiSetProperty(UI.appIcon[i], "HoverOpacityEffect", true)
        end
        -- icon -> app name (decompile var0 map)
        -- [Fix #72] position 5 was "bank": the Wallet.png icon opened the
        -- EMPTY bank stub while the fully built UI.app.wallet (with server
        -- data request) was unreachable - remapped so the Wallet icon works
        local iconApps = { "phone", "contacts", "messages", "settings", "wallet", "notes",
            "taxi", "safari", "whatsapp", "airport", "electricity", "health", "traffic", "activities" }
        UI.iconApp = {}
        for i, name in ipairs(iconApps) do UI.iconApp[UI.appIcon[i]] = name end

        -- ============================ SETTINGS APP ========================
        UI.app.settings = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.settings, false)
        UI.label.Title = eui:uiCreateLabel(30, 50, DW - 10 - 40, 20, {
            en = "Settings", ar = "الإعدادات",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.app.settings)
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.app.settings)
        UI.label.device_info = eui:uiCreateLabel(30, 120, 180, 100, "", tocolor(255, 255, 255, 255), "left", "top", UI.app.settings)
        UI.button.remove_SIM = eui:uiCreateButton(20, 230, DW - 10 - 40, 30, {
            en = "Remove SIM", ar = "إخراج الشريحة",
        }, tocolor(255, 69, 58, 255), UI.app.settings)
        UI.button.open_SIM = eui:uiCreateButton(20, 268, DW - 10 - 40, 30, {
            en = "My Numbers / SIM", ar = "أرقامي / الشرائح",
        }, tocolor(0, 122, 255, 255), UI.app.settings)
        sms_notifications = false
        pcall(function() sms_notifications = exports.settings:getSetting("sms_notifications") and true or false end)
        UI.switch.toggle_sms_notifications = eui:uiCreateSwitch(25, 310, DW - 10 - 40, 20, {
            en = "Enable SMS notifications", ar = "تفعيل إشعارات الرسائل",
        }, sms_notifications, _, UI.app.settings)

        -- ============================ PHONE APP ===========================
        UI.app.phone = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.phone, false)
        UI.label["contacts:screen:keypad"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.phone)
        UI.label.Title = eui:uiCreateLabel(30, 50, DW - 10 - 40, 20, {
            en = "Calls", ar = "الاتصالات",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.label["contacts:screen:keypad"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.label["contacts:screen:keypad"])
        UI.edit.phone_number = eui:uiCreateEdit(30, 120, DW - 10 - 60, 30, "", "Phone number", _, UI.label["contacts:screen:keypad"])
        eui:uiSetFont(UI.edit.phone_number, "default-large")
        UI.button.call = eui:uiCreateImage((DW - 10 - 60) / 2, 170, 60, 60,
            ":phone-system/IMG/icons/accept_call.png", UI.label["contacts:screen:keypad"])
        eui:uiSetProperty(UI.button.call, "HoverOpacityEffect", true)
        UI.gridlist.recent_calls = eui:uiCreateGridList(20, 250, DW - 10 - 40, DH - 300, tocolor(0, 0, 0, 0), UI.label["contacts:screen:keypad"])
        eui:uiGridListAddColumn(UI.gridlist.recent_calls, "Recents", 0.8)
        eui:uiGridListAddColumn(UI.gridlist.recent_calls, "", 0.2)
        eui:uiSetAlign(UI.gridlist.recent_calls, "left", "center")
        eui:uiSetProperty(UI.gridlist.recent_calls, "color_coded", true)

        UI.label["contacts:screen:call"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.phone)
        eui:uiSetVisible(UI.label["contacts:screen:call"], false)
        UI.button["call:cancel"] = eui:uiCreateImage((DW - 10 - 60) / 2, 370, 60, 60,
            ":phone-system/IMG/icons/decline_call.png", UI.label["contacts:screen:call"])
        eui:uiSetProperty(UI.button["call:cancel"], "HoverOpacityEffect", true)
        UI.button["call:end"] = eui:uiCreateImage((DW - 10 - 60) / 2, 370, 60, 60,
            ":phone-system/IMG/icons/decline_call.png", UI.label["contacts:screen:call"])
        eui:uiSetProperty(UI.button["call:end"], "HoverOpacityEffect", true)
        UI.button["call:decline"] = eui:uiCreateImage((DW - 10) / 2 - 80, 370, 50, 50,
            ":phone-system/IMG/icons/decline_call.png", UI.label["contacts:screen:call"])
        eui:uiSetProperty(UI.button["call:decline"], "HoverOpacityEffect", true)
        UI.button["call:accept"] = eui:uiCreateImage((DW - 10) / 2 + 30, 370, 50, 50,
            ":phone-system/IMG/icons/accept_call.png", UI.label["contacts:screen:call"])
        eui:uiSetProperty(UI.button["call:accept"], "HoverOpacityEffect", true)
        UI.label["call:number"] = eui:uiCreateLabel(20, 100, DW - 10 - 40, 30, "00000000", tocolor(255, 255, 255, 255), "center", "center", UI.label["contacts:screen:call"])
        eui:uiSetFont(UI.label["call:number"], "default-large")
        UI.label["call:text"] = eui:uiCreateLabel(20, 130, DW - 10 - 40, 20, "", tocolor(255, 255, 255, 200), "center", "center", UI.label["contacts:screen:call"])
        eui:uiSetVisible(UI.button["call:cancel"], false)
        eui:uiSetVisible(UI.button["call:end"], false)
        eui:uiSetVisible(UI.button["call:decline"], false)
        eui:uiSetVisible(UI.button["call:accept"], false)

        -- ============================ CONTACTS APP ========================
        UI.app.contacts = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.contacts, false)
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.app.contacts)
        UI.label["contacts:screen:1"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.contacts)
        UI.label.Title = eui:uiCreateLabel(30, 50, 200, 20, {
            en = "Contacts", ar = "جهات الاتصال",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.label["contacts:screen:1"])
        eui:uiSetFont(UI.label.Title, "default-large")
        UI.gridlist.contacts = eui:uiCreateGridList(15, 90, DW - 10 - 30, DH - 250, tocolor(0, 0, 0, 0), UI.label["contacts:screen:1"])
        eui:uiGridListAddColumn(UI.gridlist.contacts, "", 1)
        eui:uiSetAlign(UI.gridlist.contacts, "left", "center")
        eui:uiSetProperty(UI.gridlist.contacts, "row_height", 30)
        eui:uiSetProperty(UI.gridlist.contacts, "columns_names_visible", "False")
        eui:uiSetProperty(UI.gridlist.contacts, "column_height", 0)
        UI.button.chat_with_contact = eui:uiCreateButton(20, DH - 70 - 70, DW - 10 - 40, 30, {
            en = "Chat via WhatsApp", ar = "محادثة عبر الواتساب",
        }, tocolor(43, 183, 65, 255), UI.label["contacts:screen:1"])
        UI.button.remove_contact = eui:uiCreateButton(20, DH - 70 - 35, DW - 10 - 40, 30, {
            en = "Remove Contact", ar = "حذف جهة الاتصال",
        }, tocolor(255, 69, 58, 255), UI.label["contacts:screen:1"])
        UI.button.add_contact = eui:uiCreateButton(20, DH - 70, DW - 10 - 40, 30, {
            en = "Add Contact", ar = "إضافة جهة اتصال",
        }, tocolor(0, 122, 255, 255), UI.label["contacts:screen:1"])
        UI.label["contacts:screen:2"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.contacts)
        eui:uiSetVisible(UI.label["contacts:screen:2"], false)
        UI.label["contacts:screen:2:topbar"] = eui:uiCreateLabel(0, 50, DW - 10, 30, {
            en = "Add Contact", ar = "إضافة جهة اتصال",
        }, tocolor(255, 255, 255, 255), "center", "center", UI.label["contacts:screen:2"])
        UI.button["add_contact:return"] = eui:uiCreateImage(25, 8, 16, 16, ":phone-system/IMG/icons/left-arrow.png", UI.label["contacts:screen:2:topbar"])
        eui:uiSetProperty(UI.button["add_contact:return"], "HoverOpacityEffect", true)
        UI.edit["add_contact:name"] = eui:uiCreateEdit(25, 120, 190, 30, "", "Name", _, UI.label["contacts:screen:2"])
        UI.edit["add_contact:phone"] = eui:uiCreateEdit(25, 160, 190, 30, "", "Phone number", _, UI.label["contacts:screen:2"])
        UI.button["add_contact:add"] = eui:uiCreateButton(25, DW - 10 - 30, DW - 10 - 50, 30, {
            en = "Add", ar = "إضافة",
        }, tocolor(0, 122, 255, 240), UI.label["contacts:screen:2"])
    end)
    if not ok then
        outputDebugString("[phone-system] build error: " .. tostring(err), 1, 255, 100, 100)
        return
    end
    built = true -- Fix #52 class: flip ONLY after the whole build succeeded
end

--------------------------------------------------------------------------------
-- UI BUILD part 2: messages / wallet / notes / safari / whatsapp / airport /
-- health + home button
--------------------------------------------------------------------------------
local function UIKitReadyPart2()
    if not built then return end
    local ok, err = pcall(function()
        local DW, DH = 240 * 1.3, 500 * 1.3

        -- ============================ MESSAGES APP =======================
        UI.app.messages = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.messages, false)
        UI.label["messages:screen1"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.messages)
        UI.label.Title = eui:uiCreateLabel(30, 50, 200, 20, {
            en = "Messages", ar = "الرسائل",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.label["messages:screen1"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.label["messages:screen1"])
        UI.gridlist.messages = eui:uiCreateGridList(15, 90, DW - 10 - 30, DH - 90 - 20, tocolor(10, 10, 10, 0), UI.label["messages:screen1"])
        eui:uiGridListAddColumn(UI.gridlist.messages, "", 1)
        eui:uiSetAlign(UI.gridlist.messages, "left", "center")
        eui:uiSetProperty(UI.gridlist.messages, "row_height", 50)
        eui:uiSetProperty(UI.gridlist.messages, "columns_names_visible", "False")
        eui:uiSetProperty(UI.gridlist.messages, "column_height", 0)
        eui:uiSetProperty(UI.gridlist.messages, "color_coded", true)
        UI.label["messages:chatScreen"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.messages)
        eui:uiSetVisible(UI.label["messages:chatScreen"], false)
        UI.label["messages:chatScreen:topbar"] = eui:uiCreateLabel(0, 50, DW - 10, 30, { en = "", ar = "" }, tocolor(255, 255, 255, 255), "center", "center", UI.label["messages:chatScreen"])
        UI.button["messages:chat:return"] = eui:uiCreateImage(25, 8, 16, 16, ":phone-system/IMG/icons/left-arrow.png", UI.label["messages:chatScreen:topbar"])
        eui:uiSetProperty(UI.button["messages:chat:return"], "HoverOpacityEffect", true)
        UI.label["messages:chat:message"] = eui:uiCreateLabel(25, 100, 190, 300, "", tocolor(255, 255, 255), "left", "top", UI.label["messages:chatScreen"])
        eui:uiSetProperty(UI.label["messages:chat:message"], "color_coded", false)
        eui:uiSetProperty(UI.label["messages:chat:message"], "word_break", true)

        -- ============================ WALLET APP =========================
        UI.app.wallet = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.wallet, false)
        UI.label["wallet:screen:main"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.wallet)
        UI.label.Title = eui:uiCreateLabel(30, 50, 200, 20, { en = "Wallet", ar = "المحفظة" }, tocolor(255, 255, 255, 255), "left", "top", UI.label["wallet:screen:main"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.label["wallet:screen:main"])
        eui:uiCreateLabel(30, 100, DW - 10 - 60, 20, {
            en = "Your Bank Accounts", ar = "حساباتك البنكية",
        }, tocolor(255, 255, 255, 255), "center", "top", UI.label["wallet:screen:main"])
        UI.gridlist.bank_accounts = eui:uiCreateGridList(15, 130, DW - 10 - 30, 300, tocolor(10, 10, 10, 0), UI.label["wallet:screen:main"])
        eui:uiGridListAddColumn(UI.gridlist.bank_accounts, "", 1)
        eui:uiSetAlign(UI.gridlist.bank_accounts, "left", "center")
        eui:uiSetProperty(UI.gridlist.bank_accounts, "row_height", 30)
        eui:uiSetProperty(UI.gridlist.bank_accounts, "columns_names_visible", "False")
        eui:uiSetProperty(UI.gridlist.bank_accounts, "column_height", 0)
        UI.button.copy_bankaccount_id = eui:uiCreateButton(20, DH - 70, DW - 10 - 40, 30, {
            en = "Copy Account ID", ar = "نسخ معرف الحساب",
        }, tocolor(0, 122, 255, 255), UI.label["wallet:screen:main"])
        UI.label["wallet:screen:account"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.wallet)
        eui:uiSetVisible(UI.label["wallet:screen:account"], false)
        UI.button["wallet:account:return"] = eui:uiCreateImage(25, 58, 16, 16, "IMG/icons/left-arrow.png", UI.label["wallet:screen:account"])
        eui:uiSetProperty(UI.button["wallet:account:return"], "HoverOpacityEffect", true)
        eui:uiCreateLabel(30, 100, 180, 20, {
            en = "Account Balance", ar = "رصيد الحساب",
        }, tocolor(255, 255, 255, 255), "center", "top", UI.label["wallet:screen:account"])
        UI.label["wallet:balance"] = eui:uiCreateLabel(30, 130, 180, 30, "$0", tocolor(0, 255, 0, 255), "center", "center", UI.label["wallet:screen:account"])
        eui:uiSetFont(UI.label["wallet:balance"], "default-large")
        eui:uiCreateLabel(30, 200, 180, 20, {
            en = "Transfer Amount", ar = "تحويل مبلغ",
        }, tocolor(255, 255, 255, 255), "center", "top", UI.label["wallet:screen:account"])
        UI.edit["wallet:transfer:account"] = eui:uiCreateEdit(25, 230, 190, 30, "", {
            en = "Account ID", ar = "معرف الحساب",
        }, _, UI.label["wallet:screen:account"])
        UI.edit["wallet:transfer:amount"] = eui:uiCreateEdit(25, 270, 190, 30, "", {
            en = "Amount", ar = "المبلغ",
        }, _, UI.label["wallet:screen:account"])
        eui:uiCreateLabel(30, 300, 180, 100, {
            en = "You can transfer limited amounts.\nTo transfer larger amounts you must go to the bank.",
            ar = "تستطيع تحويل مبلغ محدود\nلتحويل مبلغ أكبر يجب عليك\nالذهاب للبنك",
        }, tocolor(255, 255, 255, 255), "center", "center", UI.label["wallet:screen:account"])
        UI.button["wallet:tranfser"] = eui:uiCreateButton(25, 400, DW - 10 - 50, 30, {
            en = "Transfer", ar = "تحويل",
        }, tocolor(0, 122, 255, 240), UI.label["wallet:screen:account"])

        -- ============================ NOTES APP ==========================
        UI.app.notes = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.notes, false)
        UI.label["notes:screen1"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.notes)
        UI.label.Title = eui:uiCreateLabel(30, 50, 200, 20, {
            en = "Notes", ar = "الملاحظات",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.label["notes:screen1"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.label["notes:screen1"])
        UI.memo.notes = eui:uiCreateMemo(15, 95, DW - 10 - 30, DH - 95 - 60, "", tocolor(255, 255, 255, 200), UI.label["notes:screen1"])
        UI.button["notes:save"] = eui:uiCreateButton(20, DH - 55, DW - 10 - 40, 25, {
            en = "Save Notes", ar = "حفظ الملاحظات",
        }, tocolor(0, 122, 255, 255), UI.label["notes:screen1"])

        -- ============================ SAFARI APP =========================
        UI.app.safari = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.safari, false)
        UI.browser.safari = eui:uiCreateBrowser(15, 60, DW - 10 - 30, DH - 120, false, false, UI.app.safari)
        local safariBrowser = eui:uiGetBrowser(UI.browser.safari)
        setBrowserProperty(safariBrowser, "mobile", "1")
        addEventHandler("onClientBrowserCreated", safariBrowser, function()
            loadBrowserURL(source, "https://www.google.com/")
        end)

        -- ============================ WHATSAPP APP =======================
        UI.app.whatsapp = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.whatsapp, false)
        UI.container["whatsapp:screen:main"] = eui:uiCreateContainer(0, 0, DW - 10, DH, UI.app.whatsapp)
        UI.label.Title = eui:uiCreateLabel(30, 60, 200, 20, { en = "WhatsApp", ar = "WhatsApp" }, tocolor(255, 255, 255, 255), "left", "top", UI.container["whatsapp:screen:main"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.container["whatsapp:screen:main"])
        UI.button["whatsapp:start_new_chat"] = eui:uiCreateImage(DW - 10 - 50, 65, 15, 15, ":phone-system/IMG/icons/plus.png", UI.container["whatsapp:screen:main"])
        eui:uiSetProperty(UI.button["whatsapp:start_new_chat"], "HoverOpacityEffect", true)
        UI.gridlist.whatsapp = eui:uiCreateGridList(15, 90, DW - 10 - 30, DH - 150, tocolor(10, 10, 10, 0), UI.container["whatsapp:screen:main"])
        eui:uiGridListAddColumn(UI.gridlist.whatsapp, "", 1)
        eui:uiSetAlign(UI.gridlist.whatsapp, "left", "center")
        eui:uiSetProperty(UI.gridlist.whatsapp, "row_height", 30)
        eui:uiSetProperty(UI.gridlist.whatsapp, "columns_names_visible", "False")
        eui:uiSetProperty(UI.gridlist.whatsapp, "column_height", 0)
        UI.container["whatsapp:screen:startchat"] = eui:uiCreateContainer(0, 0, DW - 10, DH, UI.app.whatsapp)
        eui:uiSetVisible(UI.container["whatsapp:screen:startchat"], false)
        UI.label["whatsapp:screen:startchat:topbar"] = eui:uiCreateLabel(0, 50, DW - 10, 30, { en = "", ar = "" }, tocolor(255, 255, 255, 255), "center", "center", UI.container["whatsapp:screen:startchat"])
        UI.button["whatsapp:screen:startchat:return"] = eui:uiCreateImage(25, 8, 16, 16, ":phone-system/IMG/icons/left-arrow.png", UI.label["whatsapp:screen:startchat:topbar"])
        eui:uiSetProperty(UI.button["whatsapp:screen:startchat:return"], "HoverOpacityEffect", true)
        UI.edit["whatsapp:screen:startchat:phone"] = eui:uiCreateEdit(25, 150, DW - 10 - 50, 35, "", {
            en = "Phone Number", ar = "رقم الهاتف",
        }, _, UI.container["whatsapp:screen:startchat"])
        UI.button["whatsapp:screen:startchat:start"] = eui:uiCreateButton(25, 210, DW - 10 - 50, 35, {
            en = "Start Chat", ar = "بدء محادثة",
        }, tocolor(0, 122, 255, 240), UI.container["whatsapp:screen:startchat"])
        UI.container["whatsapp:screen:chat"] = eui:uiCreateContainer(0, 0, DW - 10, DH, UI.app.whatsapp)
        eui:uiSetVisible(UI.container["whatsapp:screen:chat"], false)
        UI.label["whatsapp:screen:chat:topbar"] = eui:uiCreateLabel(0, 50, DW - 10, 30, { en = "", ar = "" }, tocolor(255, 255, 255, 255), "center", "center", UI.container["whatsapp:screen:chat"])
        UI.button["whatsapp:screen:chat:return"] = eui:uiCreateImage(25, 8, 16, 16, ":phone-system/IMG/icons/left-arrow.png", UI.label["whatsapp:screen:chat:topbar"])
        eui:uiSetProperty(UI.button["whatsapp:screen:chat:return"], "HoverOpacityEffect", true)
        eui:uiCreateImage(15, 90, DW - 10 - 30, DH - 180, ":phone-system/IMG/whatsapp_wallpaper.png", UI.container["whatsapp:screen:chat"])
        UI.browser.whatsapp = eui:uiCreateBrowser(15, 90, DW - 10 - 30, DH - 180, true, true, UI.container["whatsapp:screen:chat"])
        local whatsappBrowser = eui:uiGetBrowser(UI.browser.whatsapp)
        setBrowserProperty(whatsappBrowser, "mobile", "1")
        addEventHandler("onClientBrowserCreated", whatsappBrowser, function()
            loadBrowserURL(source, "http://mta/phone-system/html/whatsapp.html")
        end)
        UI.edit["whatsapp:input"] = eui:uiCreateEdit(20, DH - 80, DW - 10 - 40, 30, "", {
            en = "Text", ar = "النص",
        }, _, UI.container["whatsapp:screen:chat"])
        UI.button["whatsapp:send_location"] = eui:uiCreateImage(DW - 10 - 66, DH - 37, 16, 16, "IMG/icons/location.png", UI.container["whatsapp:screen:chat"])
        eui:uiSetProperty(UI.button["whatsapp:send_location"], "HoverOpacityEffect", true)

        -- ============================ AIRPORT APP ========================
        UI.app.airport = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.airport, false)
        UI.label["airport:screen:main"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.airport)
        UI.label.Title = eui:uiCreateLabel(30, 50, 200, 20, {
            en = "Travel Tickets", ar = "تذاكر السفر",
        }, tocolor(255, 255, 255, 255), "left", "top", UI.label["airport:screen:main"])
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.label["airport:screen:main"])
        eui:uiCreateLabel(30, 100, DW - 10 - 60, 20, {
            en = "Your Tickets", ar = "تذاكرك",
        }, tocolor(255, 255, 255, 255), "center", "top", UI.label["airport:screen:main"])
        UI.gridlist.travel_tickets = eui:uiCreateGridList(15, 130, DW - 10 - 30, 400, tocolor(10, 10, 10, 0), UI.label["airport:screen:main"])
        eui:uiGridListAddColumn(UI.gridlist.travel_tickets, "", 1)
        eui:uiSetAlign(UI.gridlist.travel_tickets, "left", "center")
        eui:uiSetProperty(UI.gridlist.travel_tickets, "row_height", 30)
        eui:uiSetProperty(UI.gridlist.travel_tickets, "columns_names_visible", "False")
        eui:uiSetProperty(UI.gridlist.travel_tickets, "column_height", 0)
        UI.label.travel_ticket_details = eui:uiCreateLabel(25, 440, DW - 10 - 50, 50, "", tocolor(255, 255, 255), "left", "top", UI.label["airport:screen:main"])
        UI.button.buy_travel_ticket = eui:uiCreateButton(20, DH - 75, DW - 10 - 40, 35, {
            en = "Buy Travel Ticket", ar = "شراء تذكرة سفر",
        }, tocolor(0, 122, 255, 255), UI.label["airport:screen:main"])
        UI.label["airport:screen:buy_ticket"] = eui:uiCreateLabel(0, 0, DW - 10, DH, "", tocolor(255, 255, 255), "left", "top", UI.app.airport)
        eui:uiSetVisible(UI.label["airport:screen:buy_ticket"], false)
        UI.label["airport:buy_ticket:title"] = eui:uiCreateLabel(0, 50, DW - 10, 30, {
            en = "Buy Ticket", ar = "شراء تذكرة",
        }, tocolor(255, 255, 255, 255), "center", "center", UI.label["airport:screen:buy_ticket"])
        UI.button["airport:buy_ticket:return"] = eui:uiCreateImage(25, 58, 16, 16, "IMG/icons/left-arrow.png", UI.label["airport:screen:buy_ticket"])
        eui:uiSetProperty(UI.button["airport:buy_ticket:return"], "HoverOpacityEffect", true)
        UI.gridlist["airport:buy_ticket:from"] = eui:uiCreateGridList(25, 100, DW - 10 - 50, 150, tocolor(0, 0, 0, 0), UI.label["airport:screen:buy_ticket"])
        eui:uiGridListAddColumn(UI.gridlist["airport:buy_ticket:from"], "From", 1)
        UI.gridlist["airport:buy_ticket:to"] = eui:uiCreateGridList(25, 260, DW - 10 - 50, 150, tocolor(0, 0, 0, 0), UI.label["airport:screen:buy_ticket"])
        eui:uiGridListAddColumn(UI.gridlist["airport:buy_ticket:to"], "To", 1)
        UI.label["airport:buy_ticket:price"] = eui:uiCreateLabel(25, DH - 110, DW - 10 - 50, 20, "$0", tocolor(0, 255, 0, 255), "center", "top", UI.label["airport:screen:buy_ticket"])
        UI.button["airport:buy_ticket"] = eui:uiCreateButton(25, DH - 80, DW - 10 - 50, 35, {
            en = "Buy", ar = "شراء",
        }, tocolor(0, 122, 255, 240), UI.label["airport:screen:buy_ticket"])
        for _, city in ipairs({ "Los Santos", "San Fierro", "Las Venturas", "Cayo Perico" }) do
            eui:uiGridListSetItemText(UI.gridlist["airport:buy_ticket:from"], eui:uiGridListAddRow(UI.gridlist["airport:buy_ticket:from"]), 1, city)
            eui:uiGridListSetItemText(UI.gridlist["airport:buy_ticket:to"], eui:uiGridListAddRow(UI.gridlist["airport:buy_ticket:to"]), 1, city)
        end

        -- ====================== STUB APPS (v1.0 faithful) =================
        -- electricity / traffic / bank / activities shipped EMPTY in the
        -- original v1.0 client - kept as dark containers with a title only
        -- [Fix #72] taxi is the iconApps name too (gridNames "taxi" -> openApp
        -- "taxi"); without a container uiSetVisible(nil) errored on every tap
        for _, name in ipairs({ "electricity", "traffic", "bank", "activities", "taxi" }) do
            UI.app[name] = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
            eui:uiSetVisible(UI.app[name], false)
        end

        -- ============================ HEALTH APP ==========================
        UI.app.health = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app.health, false)
        UI.label.Title = eui:uiCreateLabel(30, 50, DW - 10 - 40, 20, { en = "Health", ar = "الصحة" }, tocolor(255, 74, 74, 255), "left", "top", UI.app.health)
        eui:uiSetFont(UI.label.Title, "default-large")
        eui:uiCreateRectangle(15, 90, DW - 10 - 30, 1, tocolor(255, 255, 255, 25), false, false, false, false, UI.app.health)
        -- NOTE: the decompile drew all 3 rows at y=150 (overlapping) - rows
        -- are spread here, the only layout fix vs the original
        local stats = {
            { title = { en = "Fat", ar = "السمنة" }, stat = "fat", id = 21 },
            { title = { en = "Stamina", ar = "قوة التحمل" }, stat = "stamina", id = 22 },
            { title = { en = "Muscle", ar = "العضلات" }, stat = "muscle", id = 23 },
        }
        for i, st in ipairs(stats) do
            local y = 150 + (i - 1) * 50
            eui:uiCreateLabel(30, y, DW - 10 - 60, 20, st.title, tocolor(255, 74, 74, 255), "left", "top", UI.app.health)
            UI.label["health:" .. st.stat] = eui:uiCreateLabel(30, y, DW - 10 - 60, 20, "0 / 0", tocolor(255, 255, 255, 255), "right", "top", UI.app.health)
            UI.progressbar["health:" .. st.stat] = eui:uiCreateProgressBar(30, y + 25, DW - 10 - 60, 5, tocolor(255, 255, 255, 240), UI.app.health)
            eui:uiSetProperty(UI.progressbar["health:" .. st.stat], "show_progress", false)
        end

        -- ============================ HOME BUTTON =========================
        UI.rectangle.HOME_BUTTON = eui:uiCreateRectangle((DW - 10 - 100 * 1.3) / 2, DH - 20 * 1.3, 100 * 1.3, 5,
            tocolor(255, 255, 255, 200), false, false, false, false, UI.image.device)
        eui:uiSetProperty(UI.rectangle.HOME_BUTTON, "HoverOpacityEffect", true)
    end)
    if not ok then
        outputDebugString("[phone-system] build2 error: " .. tostring(err), 1, 255, 100, 100)
    end
end

--------------------------------------------------------------------------------
-- session state helpers + fillers
--------------------------------------------------------------------------------
local cursorStatus = false

local function cursor_visible()
    cursorStatus = not cursorStatus
    showCursor(cursorStatus)
end

local function screenVisible()
    if not built then return false end
    local ok, v = pcall(function() return eui:uiGetVisible(UI.image.screen) end)
    return ok and v and true or false
end

local function hideCallScreen()
    eui:uiSetVisible(UI.label["contacts:screen:call"], false)
    eui:uiSetVisible(UI.label["contacts:screen:keypad"], true)
end

local function reloadSMS()
    -- NOTE: the decompile called uiGridListAddRow TWICE per entry (decompiler
    -- artifact that duplicated every row) - one row per entry here
    eui:uiGridListClear(UI.gridlist.messages)
    for i = 1, #smsList do
        local s = smsList[#smsList - i + 1]
        if s then
            local row = eui:uiGridListAddRow(UI.gridlist.messages)
            eui:uiGridListSetItemText(UI.gridlist.messages, row, 1, s.title or "")
            eui:uiGridListSetItemData(UI.gridlist.messages, row, 1, s.message or "")
        end
    end
end

local function reloadRecents()
    eui:uiGridListClear(UI.gridlist.recent_calls)
    for i = 1, math.min(#recents, 20) do
        local r = recents[#recents - i + 1]
        if r then
            local dur = tonumber(r.duration) or 0
            local durStr = string.format("%d:%02d", math.floor(dur / 60), dur % 60)
            local ago = getRealTime().timestamp - (tonumber(r.end_at) or 0)
            local agoStr = (ago < 60) and (ago .. "s ago") or (math.floor(ago / 60) .. "m ago")
            local row = eui:uiGridListAddRow(UI.gridlist.recent_calls)
            eui:uiGridListSetItemText(UI.gridlist.recent_calls, row, 1,
                checkContactNumber(tostring(r.number)) .. " #a3a3a3- " .. durStr)
            eui:uiGridListSetItemText(UI.gridlist.recent_calls, row, 2, "#a3a3a3" .. agoStr)
            eui:uiGridListSetItemData(UI.gridlist.recent_calls, row, 1, tostring(r.number))
        end
    end
end

local function fillContacts()
    eui:uiGridListClear(UI.gridlist.contacts)
    for _, c in ipairs(contacts) do
        local row = eui:uiGridListAddRow(UI.gridlist.contacts)
        eui:uiGridListSetItemText(UI.gridlist.contacts, row, 1, tostring(c[1]) .. "  (" .. tostring(c[2]) .. ")")
        eui:uiGridListSetItemData(UI.gridlist.contacts, row, 1, tostring(c[2]))
    end
end

local function applyData(item, data)
    app.item = item
    app.data = data
    app.currentID = item.phone_number or item.id
    contacts = {}
    for _, c in ipairs(default_contacts) do contacts[#contacts + 1] = { c[1], tostring(c[2]) } end
    for _, c in ipairs(data.contacts or {}) do contacts[#contacts + 1] = { tostring(c[1]), tostring(c[2]) } end
    smsList = {}
    for _, s in ipairs(data.sms or {}) do
        local preview = tostring(s.text or ""):gsub("\n", "")
        preview = preview:sub(1, 35)
        smsList[#smsList + 1] = {
            id = s.id,
            title = tostring(s.from or "?") .. "\n#a3a3a3" .. preview .. "...",
            message = ((s.time and s.time.str) and (s.time.str .. "\n\n") or "") .. tostring(s.text or ""),
        }
    end
    recents = data.recents or {}
    if screenVisible() then
        eui:uiSetText(UI.label.device_info, "Serial Number: " .. tostring(item.serial or "N/A") ..
            "\nPhone Number: " .. tostring(item.phone_number or "N/A") ..
            "\nVoucher: " .. tostring(item.voucher or 0))
        eui:uiSetText(UI.memo.notes, data.notes or "")
        fillContacts()
        reloadSMS()
        reloadRecents()
    end
end

--------------------------------------------------------------------------------
-- open / close / openApp (decompile: app.open / app.close / openApp)
--------------------------------------------------------------------------------
local function openApp(name)
    -- [Fix #72] guard: an icon whose app name has no container (e.g. taxi
    -- before the stub was added) must not error inside onClientUIClick
    if not (name and UI.app and UI.app[name]) then
        outputDebugString("[phone-system] openApp: no container for app '"
            .. tostring(name) .. "'", 2)
        return
    end
    if app.currentApp then
        eui:uiSetVisible(UI.app[app.currentApp], false)
    else
        eui:uiSetVisible(UI.image.wallpaper, false)
        eui:uiSetVisible(UI.label.home_screen, false)
    end
    -- Fix #61: external app modules (e.g. taxi) build into a stub via
    -- phone:app:request(name, parent, x, y, w, h)
    if not UI.app[name] then
        UI.app[name] = eui:uiCreateContainer(5, 0, DW - 10, DH, UI.image.device)
        eui:uiSetVisible(UI.app[name], false)
        triggerEvent("phone:app:request", localPlayer, name, UI.app[name], 0, 0, DW - 10, DH)
    end
    app.currentApp = name
    eui:uiSetVisible(UI.app[name], true)
    if name == "phone" then
        reloadRecents()
    elseif name == "wallet" then
        triggerServerEvent("phone:requestBankAccounts", localPlayer)
    elseif name == "whatsapp" then
        triggerServerEvent("phone:whatsapp:history", localPlayer, app.currentID)
    elseif name == "airport" then
        triggerServerEvent("airport:get_travel_tickets", localPlayer)
    elseif name == "health" then
        for key, id in pairs({ fat = 21, stamina = 22, muscle = 23 }) do
            local stat = getPedStat(localPlayer, id) or 0
            eui:uiSetText(UI.label["health:" .. key], tostring(stat) .. " / 1000")
            eui:uiProgressBarSetProgress(UI.progressbar["health:" .. key], stat / 1000 * 100)
        end
    end
end

local function closePhone()
    if not screenVisible() then return end
    if app.currentApp then
        eui:uiSetVisible(UI.app[app.currentApp], false)
        app.currentApp = false
    end
    eui:uiSetVisible(UI.image.wallpaper, true)
    eui:uiSetVisible(UI.label.home_screen, true)
    hideCallScreen()
    eui:uiSetVisible(UI.image.screen, false)
    triggerServerEvent("phone:onClose", localPlayer)
    showCursor(false)
    cursorStatus = false
    unbindKey("mouse2", "down", cursor_visible)
    if isTimer(update_clock_timer) then killTimer(update_clock_timer) end
    app.currentWalletAccount = nil
    app.current_whatsapp_phone_number = nil
end

-- the decompile opened the phone with the item object and requested data only
-- when the serial was uncached; in owlbakeup the server sends BOTH together
addEvent("phone:data:request:callback", true)
addEventHandler("phone:data:request:callback", localPlayer, function(item, data)
    applyData(item, data)
    if not screenVisible() then
        app.currentApp = false
        eui:uiSetVisible(UI.image.wallpaper, true)
        eui:uiSetVisible(UI.label.home_screen, true)
        eui:uiSetVisible(UI.image.screen, true)
        bindKey("mouse2", "down", cursor_visible)
        -- [Fix #72] the screen opened with NO cursor - onClientUIClick only
        -- fires on cursor clicks, so every tap did nothing ("phone broken,
        -- nothing works"). Open with the cursor on (right-click still toggles
        -- it off/on via cursor_visible); closePhone/showCursor(false) resets.
        cursorStatus = true
        showCursor(true)
        eui:uiSetText(UI.label.device_info, "Serial Number: " .. tostring(item.serial or "N/A") ..
            "\nPhone Number: " .. tostring(item.phone_number or "N/A") ..
            "\nVoucher: " .. tostring(item.voucher or 0))
        eui:uiSetText(UI.label.clock, getCurrentGameTime())
        eui:uiSetText(UI.memo.notes, data.notes or "")
        fillContacts()
        reloadSMS()
        reloadRecents()
        if not isTimer(update_clock_timer) then
            update_clock_timer = setTimer(function()
                if built then eui:uiSetText(UI.label.clock, getCurrentGameTime()) end
            end, 2000, 0)
        end
    end
end)

addEvent("phone:itemUse", true)
addEventHandler("phone:itemUse", root, function()
    if screenVisible() then
        closePhone()
    else
        triggerServerEvent("phone:requestOpen", localPlayer)
    end
end)

addCommandHandler("phone", function()
    if not (getElementData(localPlayer, "account:character:id")
        or getElementData(localPlayer, "dbid")
        or getElementData(localPlayer, "character:id")) then return end
    if isPedDead(localPlayer) then return end
    if screenVisible() then
        closePhone()
    else
        triggerServerEvent("phone:requestOpen", localPlayer)
    end
end, false, false)

-- NOTE: the original bound F3 to /phone - F3 is the faction menu on this
-- server, so the bind is intentionally dropped (use /phone or the item)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
    if screenVisible() then closePhone() end
end)
addEventHandler("onClientPlayerWasted", localPlayer, function()
    if screenVisible() then closePhone() end
end)

--------------------------------------------------------------------------------
-- SIM cards window
--------------------------------------------------------------------------------
addEvent("telecom:showPhoneNumbers", true)
addEventHandler("telecom:showPhoneNumbers", root, function(list)
    eui:uiSetVisible(UI.window.SIM, true)
    showCursor(true)
    eui:uiGridListClear(UI.gridlist["SIM:OwnedNumbers"])
    for _, n in ipairs(list or {}) do
        local row = eui:uiGridListAddRow(UI.gridlist["SIM:OwnedNumbers"])
        eui:uiGridListSetItemText(UI.gridlist["SIM:OwnedNumbers"], row, 1, tostring(n.phone_number))
    end
end)

--------------------------------------------------------------------------------
-- calls (decompile: call / showXCallScreen / onClientReceiveCall / ...)
--------------------------------------------------------------------------------
local currentCaller = nil

local function msToTimeStr(sec)
    sec = math.floor(tonumber(sec) or 0)
    if sec < 0 then sec = 0 end
    return string.format("%02d:%02d", math.floor(sec / 60) % 60, sec % 60)
end

local function callNumberText(number)
    if app.data and app.data.contacts then
        for _, c in ipairs(contacts) do
            if tostring(c[2]) == tostring(number) then
                eui:uiSetText(UI.label["call:number"], tostring(c[1]))
                return
            end
        end
    end
    eui:uiSetText(UI.label["call:number"], tostring(number))
end

local function showOutgoingCallScreen(number)
    openApp("phone")
    eui:uiSetVisible(UI.label["contacts:screen:keypad"], false)
    eui:uiSetVisible(UI.label["contacts:screen:call"], true)
    eui:uiSetVisible(UI.button["call:cancel"], true)
    eui:uiSetVisible(UI.button["call:end"], false)
    eui:uiSetVisible(UI.button["call:decline"], false)
    eui:uiSetVisible(UI.button["call:accept"], false)
    eui:uiSetText(UI.label["call:text"], "Calling...")
    callNumberText(number)
end

local function showIncomingCallScreen(number)
    openApp("phone")
    eui:uiSetVisible(UI.label["contacts:screen:keypad"], false)
    eui:uiSetVisible(UI.label["contacts:screen:call"], true)
    eui:uiSetVisible(UI.button["call:cancel"], false)
    eui:uiSetVisible(UI.button["call:end"], false)
    eui:uiSetVisible(UI.button["call:decline"], true)
    eui:uiSetVisible(UI.button["call:accept"], true)
    eui:uiSetText(UI.label["call:text"], "iPhone")
    callNumberText(number)
end

local function showOngoingCallScreen(number)
    openApp("phone")
    eui:uiSetVisible(UI.label["contacts:screen:keypad"], false)
    eui:uiSetVisible(UI.label["contacts:screen:call"], true)
    eui:uiSetVisible(UI.button["call:cancel"], false)
    eui:uiSetVisible(UI.button["call:end"], true)
    eui:uiSetVisible(UI.button["call:decline"], false)
    eui:uiSetVisible(UI.button["call:accept"], false)
    eui:uiSetText(UI.label["call:text"], "00:00")
    callNumberText(number)
end

local function call(number)
    if not tonumber(number) then return end
    if not hasActiveSIM() and tostring(number) ~= "911" then
        notify({ en = "The phone does not have a SIM card", ar = "الهاتف لا يحتوي على شريحة اتصال" }, 3000, 255, 120, 120)
        return
    end
    if getTickCount() - lastCallAttempt < 2000 then return end
    lastCallAttempt = getTickCount()
    showOutgoingCallScreen(number)
    myCall = { state = "outgoing", number = tostring(number),
        callData = { localPlayer, nil, number, app.item.phone_number } }
    triggerServerEvent("phone:phoneCall", localPlayer, number, app.item.phone_number)
end

addEvent("onClientReceiveCall", true)
addEventHandler("onClientReceiveCall", root, function(caller, number, callData, callType)
    if callType == "hotline" then
        currentCaller = caller
        myCall = { state = "hotline", number = tostring(number), callData = callData }
        triggerServerEvent("onPlayerAcceptCall", localPlayer, currentCaller, callData, "hotline")
        return
    end
    showIncomingCallScreen(number)
    currentCaller = caller
    myCall = { state = "incoming", number = tostring(number), callData = callData }
    notify({ en = checkContactNumber(tostring(number)) .. " is calling you ..",
        ar = checkContactNumber(tostring(number)) .. " يتصل بك .." }, 8000)
    if isElement(ringtone_sound) then destroyElement(ringtone_sound) end
    ringtone_sound = playSound("sounds/iphone_ringtone.mp3")
end)

addEvent("onClientPlayerStartCall", true)
addEventHandler("onClientPlayerStartCall", root, function(callData, otherNumber)
    showOngoingCallScreen(otherNumber)
    myCall.state = "ongoing"
    myCall.number = tostring(otherNumber)
    myCall.callData = callData or myCall.callData
    myCall.startTick = getTickCount()
    if isTimer(callTimer) then killTimer(callTimer) end
    callTimer = setTimer(function()
        if myCall.state == "ongoing" and myCall.startTick then
            eui:uiSetText(UI.label["call:text"], msToTimeStr((getTickCount() - myCall.startTick) / 1000))
        end
    end, 1000, 0)
    if isElement(ringtone_sound) then
        destroyElement(ringtone_sound)
        ringtone_sound = nil
    end
end)

addEvent("onClientPlayerEndCall", true)
addEventHandler("onClientPlayerEndCall", root, function()
    if myCall.state == "ongoing" and myCall.startTick then
        table.insert(recents, 1, {
            outgoing = true,
            number = myCall.number,
            duration = math.floor((getTickCount() - myCall.startTick) / 1000),
            end_at = getRealTime().timestamp,
        })
    end
    hideCallScreen()
    if isTimer(callTimer) then killTimer(callTimer) end
    myCall = { state = false, number = nil, callData = nil, startTick = nil }
    if isElement(ringtone_sound) then
        destroyElement(ringtone_sound)
        ringtone_sound = nil
    end
    if isElement(callBusy) then
        destroyElement(callBusy)
        callBusy = nil
    end
    if screenVisible() then reloadRecents() end
end)

addEvent("onClientNotFoundPhoneNumber", true)
addEventHandler("onClientNotFoundPhoneNumber", localPlayer, function()
    if isElement(ringtone_sound) then
        destroyElement(ringtone_sound)
        ringtone_sound = nil
    end
    playResSound("sounds/notification.mp3")
    outputChatBox("This number is not available right now, please try again later", 180, 180, 180)
    if myCall.state == "outgoing" then
        hideCallScreen()
        myCall = { state = false, number = nil, callData = nil, startTick = nil }
    end
end)

--------------------------------------------------------------------------------
-- whatsapp (decompile: whatsappChatList / openWhatsappChat / insertWhatsapp*)
--------------------------------------------------------------------------------
local function whatsappChatList()
    local cache = whatsappCache[tostring(app.currentID)]
    eui:uiGridListClear(UI.gridlist.whatsapp)
    if not cache then return end
    for peer, _ in pairs(cache) do
        local row = eui:uiGridListAddRow(UI.gridlist.whatsapp)
        eui:uiGridListSetItemText(UI.gridlist.whatsapp, row, 1, checkContactNumber(tostring(peer)))
        eui:uiGridListSetItemData(UI.gridlist.whatsapp, row, 1, tostring(peer))
    end
end

local function insertWhatsappMessageBox(idx, text, kind, color, data)
    local wh = eui:uiGetBrowser(UI.browser.whatsapp)
    if not wh or not isElement(wh) then return end
    local safe = escHTML(text)
    local extra = ""
    if data and data.message_type == "location" then
        extra = ' location" onclick="mta.triggerEvent(\'phone:whatsapp:on_location_click\', \'msg-' .. idx .. '\')" data-x="'
    end
    local js = "document.body.innerHTML += '<div id=\"msg-" .. idx .. "\" class=\"message-row " ..
        tostring(kind) .. "\"><div class=\"message" .. (color and " red" or "") .. extra .. '">' ..
        safe .. "</div></div>';" ..
        "window.scrollTo(0, document.body.scrollHeight);"
    executeBrowserJavascript(wh, js)
end

local function rerenderChat(peer)
    local cache = whatsappCache[tostring(app.currentID)]
    local entry = cache and cache[tostring(peer)]
    local wh = eui:uiGetBrowser(UI.browser.whatsapp)
    if wh and isElement(wh) then
        executeBrowserJavascript(wh, "document.body.innerHTML = '';")
    end
    if entry then
        for i, m in ipairs(entry.list or {}) do
            insertWhatsappMessageBox(i, m.text, m.type, m.color, m.data)
        end
    end
end

local function openWhatsappChat(peer)
    eui:uiSetVisible(UI.container["whatsapp:screen:main"], false)
    eui:uiSetVisible(UI.container["whatsapp:screen:chat"], true)
    local pid = tostring(app.currentID)
    whatsappCache[pid] = whatsappCache[pid] or {}
    whatsappCache[pid][tostring(peer)] = whatsappCache[pid][tostring(peer)] or { list = {} }
    rerenderChat(peer)
    app.current_whatsapp_phone_number = tostring(peer)
    eui:uiSetText(UI.label["whatsapp:screen:chat:topbar"], checkContactNumber(peer))
    triggerServerEvent("phone:whatsapp:history", localPlayer, app.currentID)
end

local function insertWhatsappMessage(phoneId, peer, text, kind, color, data)
    local pid = tostring(phoneId)
    whatsappCache[pid] = whatsappCache[pid] or {}
    whatsappCache[pid][tostring(peer)] = whatsappCache[pid][tostring(peer)] or { list = {} }
    local list = whatsappCache[pid][tostring(peer)].list
    list[#list + 1] = { text = text, type = kind, color = color, data = data }
    if tostring(app.current_whatsapp_phone_number) == tostring(peer) and screenVisible() then
        insertWhatsappMessageBox(#list, text, kind, color, data)
    end
end

addEvent("phone:whatsapp:history:callback", true)
addEventHandler("phone:whatsapp:history:callback", localPlayer, function(number, msgs)
    if tostring(number) ~= tostring(app.currentID) then return end
    local pid = tostring(number)
    whatsappCache[pid] = {}
    for _, m in ipairs(msgs or {}) do
        local peer = (m.from == number) and m.to or m.from
        local kind = (m.from == number) and "sent" or "received"
        local data = nil
        if m.type == "location" then
            data = { message_type = "location", location = m.loc }
        end
        local list = whatsappCache[pid]
        list[peer] = list[peer] or { list = {} }
        table.insert(list[peer].list, { text = m.text, type = kind, color = nil, data = data })
    end
    whatsappChatList()
    if app.current_whatsapp_phone_number then
        rerenderChat(app.current_whatsapp_phone_number)
    end
end)

addEvent("phone:whatsapp:receive", true)
addEventHandler("phone:whatsapp:receive", localPlayer, function(phoneId, from, text, data)
    insertWhatsappMessage(phoneId, from, text, "received", nil, data)
    playResSound("sounds/notification.mp3")
    if not screenVisible() then
        outputChatBox("WhatsApp: (" .. checkContactNumber(tostring(from)) .. ") رسالة جديدة", 120, 220, 120)
    end
end)

addEvent("phone:whatsapp:noInternet", true)
addEventHandler("phone:whatsapp:noInternet", localPlayer, function()
    insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
        "Error. No Internet!", "received", "red", nil)
end)

addEvent("phone:whatsapp:on_location_click", true)
addEventHandler("phone:whatsapp:on_location_click", root, function(msgKey)
    local idx = tonumber(tostring(msgKey):match("msg%-(%d+)"))
    if not idx or not app.currentID or not app.current_whatsapp_phone_number then return end
    local cache = whatsappCache[tostring(app.currentID)]
    local entry = cache and cache[tostring(app.current_whatsapp_phone_number)]
    local msg = entry and entry.list and entry.list[idx]
    if msg and msg.data and msg.data.location then
        local x, y, z = unpack(msg.data.location)
        -- decompile used exports.radar:findBestWay (not on this server):
        -- temporary map blip fallback
        local blip = createBlip(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0, 0, 3, 255, 60, 60, 255, 0, 30000)
        if isElement(blip) then setTimer(destroyElement, 60000, 1, blip) end
        outputChatBox("تم تحديد الموقع على الخريطة / The location is marked on the map", 180, 220, 255)
    end
end)

--------------------------------------------------------------------------------
-- SMS receive + tickets + wallet + contacts callbacks
--------------------------------------------------------------------------------
addEvent("phone:receiveSMS", true)
addEventHandler("phone:receiveSMS", root, function(from, text, time, id)
    if not built then return end
    local preview = tostring(text or ""):gsub("\n", "")
    preview = preview:sub(1, 35)
    smsList[#smsList + 1] = {
        id = id,
        title = tostring(from or "?") .. "\n#a3a3a3" .. preview .. "...",
        message = ((time and (tostring(time.hour or 0) .. ":" .. tostring(time.minute or 0) .. ":" .. tostring(time.second or 0)) or "") .. "\n\n") .. tostring(text or ""),
    }
    reloadSMS()
    if sms_notifications then
        outputChatBox("(" .. tostring(from) .. ") رسالة نصية جديدة / New SMS", 120, 220, 120)
        playResSound("sounds/notification.mp3")
    end
end)

addEvent("airport:get_travel_tickets:callback", true)
addEventHandler("airport:get_travel_tickets:callback", localPlayer, function(list)
    eui:uiGridListClear(UI.gridlist.travel_tickets)
    for _, t in ipairs(list or {}) do
        local row = eui:uiGridListAddRow(UI.gridlist.travel_tickets)
        eui:uiGridListSetItemText(UI.gridlist.travel_tickets, row, 1,
            tostring(t.code) .. "  (To: " .. tostring(t.to) .. ")")
        eui:uiGridListSetItemData(UI.gridlist.travel_tickets, row, 1, t)
    end
end)

addEvent("phone:requestBankAccounts:callback", true)
addEventHandler("phone:requestBankAccounts:callback", localPlayer, function(list)
    eui:uiGridListClear(UI.gridlist.bank_accounts)
    for _, acc in ipairs(list or {}) do
        local row = eui:uiGridListAddRow(UI.gridlist.bank_accounts)
        eui:uiGridListSetItemText(UI.gridlist.bank_accounts, row, 1, tostring(acc.code))
        eui:uiGridListSetItemData(UI.gridlist.bank_accounts, row, 1, tonumber(acc.amount) or 0)
    end
end)

addEvent("phone:contacts:add:callback", true)
addEventHandler("phone:contacts:add:callback", root, function(name, phone)
    contacts[#contacts + 1] = { tostring(name), tostring(phone) }
    local row = eui:uiGridListAddRow(UI.gridlist.contacts)
    eui:uiGridListSetItemText(UI.gridlist.contacts, row, 1, tostring(name) .. "  (" .. tostring(phone) .. ")")
    eui:uiGridListSetItemData(UI.gridlist.contacts, row, 1, tostring(phone))
end)

--------------------------------------------------------------------------------
-- CLICK DISPATCH (decompile onClientUIClick, same source-by-source shape)
--------------------------------------------------------------------------------
local TRAVEL_PRICES = {
    ["Los Santos|San Fierro"] = 2000,  ["San Fierro|Los Santos"] = 2000,
    ["Los Santos|Las Venturas"] = 2500, ["Las Venturas|Los Santos"] = 2500,
    ["Los Santos|Cayo Perico"] = 8000,  ["Cayo Perico|Los Santos"] = 8000,
    ["San Fierro|Las Venturas"] = 2200, ["Las Venturas|San Fierro"] = 2200,
    ["San Fierro|Cayo Perico"] = 8000,  ["Cayo Perico|San Fierro"] = 8000,
    ["Las Venturas|Cayo Perico"] = 8500, ["Cayo Perico|Las Venturas"] = 8500,
}

local function calculateTravelTicketPrice()
    local sel = eui:uiGridListGetSelectedItem(UI.gridlist["airport:buy_ticket:from"])
    local sel2 = eui:uiGridListGetSelectedItem(UI.gridlist["airport:buy_ticket:to"])
    if sel == -1 or sel2 == -1 then
        eui:uiSetText(UI.label["airport:buy_ticket:price"], "$0")
        return
    end
    local from = eui:uiGridListGetItemText(UI.gridlist["airport:buy_ticket:from"], sel, 1)
    local to = eui:uiGridListGetItemText(UI.gridlist["airport:buy_ticket:to"], sel2, 1)
    local price = TRAVEL_PRICES[from .. "|" .. to]
    eui:uiSetText(UI.label["airport:buy_ticket:price"], price and ("$" .. price) or "$0")
end

addEventHandler("onClientUIClick", root, function()
    if not built then return end
    if source == UI.button["SIM:Close"] then
        eui:uiSetVisible(UI.window.SIM, false)
        showCursor(false)
    elseif source == UI.button["SIM:Buy"] then
        triggerServerEvent("telecom:buyPhoneNumber", localPlayer)
        eui:uiSetVisible(UI.window.SIM, false)
        showCursor(false)
    elseif source == UI.button["SIM:GetCard"] then
        if eui:uiGridListGetSelectedItem(UI.gridlist["SIM:OwnedNumbers"]) ~= -1 then
            local num = eui:uiGridListGetItemText(UI.gridlist["SIM:OwnedNumbers"],
                eui:uiGridListGetSelectedItem(UI.gridlist["SIM:OwnedNumbers"]), 1)
            eui:uiGridListSetSelectedItem(UI.gridlist["SIM:OwnedNumbers"], -1)
            triggerServerEvent("telecom:requestSIMCard", localPlayer, num)
        end
    elseif source == UI.rectangle.HOME_BUTTON then
        if app.currentApp then
            eui:uiSetVisible(UI.app[app.currentApp], false)
            eui:uiSetVisible(UI.image.wallpaper, true)
            eui:uiSetVisible(UI.label.home_screen, true)
            app.currentApp = false
            focusBrowser()
        else
            closePhone()
        end
    elseif UI.iconApp[source] then
        openApp(UI.iconApp[source])
    elseif source == UI.button.open_SIM then
        triggerServerEvent("telecom:requestNumbers", localPlayer)
    elseif source == UI.button.remove_SIM then
        triggerServerEvent("phone:SIM:remove", localPlayer, app.item)
    elseif source == UI.button["notes:save"] then
        local text = eui:uiGetText(UI.memo.notes)
        if app.data and text ~= app.data.notes then
            triggerServerEvent("phone:notes:save", localPlayer, app.currentID, text)
            app.data.notes = text
        end
    elseif source == UI.button.add_contact then
        eui:uiSetVisible(UI.label["contacts:screen:1"], false)
        eui:uiSetVisible(UI.label["contacts:screen:2"], true)
        eui:uiSetText(UI.edit["add_contact:name"], "")
        eui:uiSetText(UI.edit["add_contact:phone"], "")
    elseif source == UI.button.remove_contact then
        local sel = eui:uiGridListGetSelectedItem(UI.gridlist.contacts)
        if sel ~= -1 then
            local num = eui:uiGridListGetItemData(UI.gridlist.contacts, sel, 1)
            eui:uiGridListSetSelectedItem(UI.gridlist.contacts, -1)
            eui:uiGridListRemoveRow(UI.gridlist.contacts, sel)
            triggerServerEvent("phone:contacts:remove", localPlayer, app.currentID, num)
        end
    elseif source == UI.button.chat_with_contact then
        local sel = eui:uiGridListGetSelectedItem(UI.gridlist.contacts)
        if sel ~= -1 then
            openApp("whatsapp")
            openWhatsappChat(eui:uiGridListGetItemData(UI.gridlist.contacts, sel, 1))
        end
    elseif source == UI.button["add_contact:return"] then
        eui:uiSetVisible(UI.label["contacts:screen:2"], false)
        eui:uiSetVisible(UI.label["contacts:screen:1"], true)
    elseif source == UI.button["add_contact:add"] then
        if app.currentID then
            local name = eui:uiGetText(UI.edit["add_contact:name"])
            local phone = eui:uiGetText(UI.edit["add_contact:phone"])
            if utf8.len(name) < 2 then
                notify({ en = "The name is too short", ar = "الاسم قصير جداً" }, 3000, 255, 120, 120)
                return
            end
            if utf8.len(name) > 25 then
                notify({ en = "The name is too long", ar = "الاسم طويل جداً" }, 3000, 255, 120, 120)
                return
            end
            if not tonumber(phone) or utf8.len(phone) <= 0 or utf8.len(phone) >= 10 then
                notify({ en = "Invalid phone number", ar = "رقم الهاتف غير صحيح" }, 3000, 255, 120, 120)
                return
            end
            triggerServerEvent("phone:contacts:add", localPlayer, app.currentID, name, phone)
            eui:uiSetVisible(UI.label["contacts:screen:2"], false)
            eui:uiSetVisible(UI.label["contacts:screen:1"], true)
        end
    elseif source == UI.button.call then
        local number = eui:uiGetText(UI.edit.phone_number)
        if tonumber(number) then
            call(number)
        end
    elseif source == UI.button["call:cancel"] then
        hideCallScreen()
        triggerServerEvent("onPlayerEndCall", localPlayer, myCall.callData)
    elseif source == UI.button["call:accept"] then
        triggerServerEvent("onPlayerAcceptCall", localPlayer, currentCaller, myCall.callData)
    elseif source == UI.button["call:decline"] then
        hideCallScreen()
        triggerServerEvent("onPlayerEndCall", localPlayer, myCall.callData)
    elseif source == UI.button["call:end"] then
        hideCallScreen()
        triggerServerEvent("onPlayerEndCall", localPlayer, myCall.callData)
    elseif source == UI.button["messages:chat:return"] then
        eui:uiSetVisible(UI.label["messages:chatScreen"], false)
        eui:uiSetVisible(UI.label["messages:screen1"], true)
    elseif source == UI.button["wallet:account:return"] then
        eui:uiSetVisible(UI.label["wallet:screen:account"], false)
        eui:uiSetVisible(UI.label["wallet:screen:main"], true)
        app.currentWalletAccount = nil
    elseif source == UI.button.copy_bankaccount_id then
        local sel = eui:uiGridListGetSelectedItem(UI.gridlist.bank_accounts)
        if sel ~= -1 then
            setClipboard(eui:uiGridListGetItemText(UI.gridlist.bank_accounts, sel, 1))
            notify({ en = "ID copied", ar = "تم نسخ المعرّف" }, 3000, 120, 220, 120)
        end
    elseif source == UI.button["wallet:tranfser"] then
        if not app.currentWalletAccount then return end
        local toAcc = eui:uiGetText(UI.edit["wallet:transfer:account"])
        local amount = tonumber(eui:uiGetText(UI.edit["wallet:transfer:amount"]))
        if toAcc ~= "" and amount and amount > 0 then
            if amount > 20000 then
                notify({ en = "You can't transfer that much amount",
                    ar = "لايمكنك تحويل هذا المبلغ الكبير" }, 3500, 255, 120, 120)
                return
            end
            if app.currentWalletAccount == toAcc then return end
            eui:uiSetText(UI.edit["wallet:transfer:amount"], "")
            triggerServerEvent("phone:wallet:transfer", localPlayer, app.currentWalletAccount, toAcc, amount)
        end
    elseif source == UI.button["whatsapp:screen:chat:return"] then
        eui:uiSetVisible(UI.container["whatsapp:screen:chat"], false)
        eui:uiSetVisible(UI.container["whatsapp:screen:main"], true)
        app.current_whatsapp_phone_number = nil
        whatsappChatList()
    elseif source == UI.button["whatsapp:screen:startchat:return"] then
        eui:uiSetVisible(UI.container["whatsapp:screen:startchat"], false)
        eui:uiSetVisible(UI.container["whatsapp:screen:main"], true)
    elseif source == UI.button["whatsapp:start_new_chat"] then
        eui:uiSetVisible(UI.container["whatsapp:screen:main"], false)
        eui:uiSetVisible(UI.container["whatsapp:screen:startchat"], true)
    elseif source == UI.button["whatsapp:screen:startchat:start"] then
        local num = eui:uiGetText(UI.edit["whatsapp:screen:startchat:phone"])
        if num ~= "" and tonumber(num) then
            eui:uiSetVisible(UI.container["whatsapp:screen:startchat"], false)
            openWhatsappChat(num)
        end
    elseif source == UI.button.buy_travel_ticket then
        eui:uiSetVisible(UI.label["airport:screen:main"], false)
        eui:uiSetVisible(UI.label["airport:screen:buy_ticket"], true)
    elseif source == UI.button["airport:buy_ticket:return"] then
        eui:uiSetVisible(UI.label["airport:screen:buy_ticket"], false)
        eui:uiSetVisible(UI.label["airport:screen:main"], true)
    elseif source == UI.gridlist["airport:buy_ticket:from"] or source == UI.gridlist["airport:buy_ticket:to"] then
        calculateTravelTicketPrice()
    elseif source == UI.button["airport:buy_ticket"] then
        local selF = eui:uiGridListGetSelectedItem(UI.gridlist["airport:buy_ticket:from"])
        local selT = eui:uiGridListGetSelectedItem(UI.gridlist["airport:buy_ticket:to"])
        if selF == -1 or selT == -1 then return end
        local from = eui:uiGridListGetItemText(UI.gridlist["airport:buy_ticket:from"], selF, 1)
        local to = eui:uiGridListGetItemText(UI.gridlist["airport:buy_ticket:to"], selT, 1)
        if from == to then return end
        eui:uiGridListSetSelectedItem(UI.gridlist["airport:buy_ticket:from"], -1)
        eui:uiGridListSetSelectedItem(UI.gridlist["airport:buy_ticket:to"], -1)
        triggerServerEvent("airport:buy_ticket", localPlayer, from, to)
    elseif source == UI.gridlist.travel_tickets then
        local sel = eui:uiGridListGetSelectedItem(UI.gridlist.travel_tickets)
        if sel ~= -1 then
            local t = eui:uiGridListGetItemData(UI.gridlist.travel_tickets, sel, 1)
            if type(t) == "table" then
                eui:uiSetText(UI.label.travel_ticket_details,
                    "Code: " .. tostring(t.code) .. "\nFrom: " .. tostring(t.from) ..
                    "\nTo: " .. tostring(t.to) .. "\nPurchase Date: " .. tostring(t.createdAt))
            end
        else
            eui:uiSetText(UI.label.travel_ticket_details, "")
        end
    elseif source == UI.button["whatsapp:send_location"] then
        if not app.current_whatsapp_phone_number then return end
        if getElementInterior(localPlayer) ~= 0 or getElementDimension(localPlayer) ~= 0 then
            insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
                "Your location could not be determined", "received", "red", nil)
            return
        end
        local x, y, z = getElementPosition(localPlayer)
        local zone = getZoneName(x, y, z, false)
        insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
            "Location (" .. zone .. "), click to see on map", "sent", nil,
            { message_type = "location", location = { x, y, z } })
        if not hasActiveSIM() then
            insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
                "Error. No SIM card!", "received", "red", nil)
            return
        end
        if (tonumber(app.item.voucher) or 0) <= 0 then
            insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
                "Error. No Internet!", "received", "red", nil)
            return
        end
        playResSound("sounds/send.mp3")
        triggerServerEvent("phone:whatsapp:send", localPlayer, app.item.phone_number,
            app.current_whatsapp_phone_number, "Location (" .. zone .. "), click to see on map",
            { message_type = "location", location = { x, y, z } })
        app.item.voucher = (tonumber(app.item.voucher) or 0) - 1
    elseif source == UI.switch.toggle_sms_notifications then
        local on = eui:uiSwitchGetSelected(source) and true or false
        pcall(function()
            exports.settings:setSetting("sms_notifications", on and "true" or "false")
        end)
        sms_notifications = on
    end
end)

-- send a whatsapp text when the input edit is accepted (Enter)
addEventHandler("onClientUIAccepted", root, function()
    if not built then return end
    if source == UI.edit["whatsapp:input"] then
        local text = eui:uiGetText(source)
        if text == "" or not app.current_whatsapp_phone_number then return end
        if utf8.len(text) > 100 then
            notify({ en = "The message is very long", ar = "الرسالة طويلة جداً" }, 3500, 255, 120, 120)
            return
        end
        eui:uiSetText(source, "")
        insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number, text, "sent", nil, nil)
        if not hasActiveSIM() then
            insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
                "Error. No SIM card!", "received", "red", nil)
            return
        end
        if (tonumber(app.item.voucher) or 0) <= 0 then
            insertWhatsappMessage(app.currentID, app.current_whatsapp_phone_number,
                "Error. No Internet!", "received", "red", nil)
            return
        end
        playResSound("sounds/send.mp3")
        triggerServerEvent("phone:whatsapp:send", localPlayer, app.item.phone_number,
            app.current_whatsapp_phone_number, text)
        app.item.voucher = (tonumber(app.item.voucher) or 0) - 1
    end
end)

-- double clicks: contacts -> dial, messages -> read, accounts -> transfer,
-- whatsapp list -> chat, recents -> call
-- (checked BEFORE any uiGridListGetSelectedItem call: that API asserts on
-- non-gridlist elements and this handler fires for EVERY UIKit element)
addEventHandler("onClientUIDoubleClick", root, function()
    if not built then return end
    local isGrid = (source == UI.gridlist.contacts) or (source == UI.gridlist.messages)
        or (source == UI.gridlist.bank_accounts) or (source == UI.gridlist.whatsapp)
        or (source == UI.gridlist.recent_calls)
    if not isGrid then return end
    local sel = eui:uiGridListGetSelectedItem(source)
    if sel == -1 or sel == nil then return end
    if source == UI.gridlist.contacts then
        if sel ~= -1 then
            openApp("phone")
            eui:uiSetText(UI.edit.phone_number,
                tostring(eui:uiGridListGetItemData(source, sel, 1)))
        end
    elseif source == UI.gridlist.messages then
        if sel ~= -1 then
            eui:uiSetVisible(UI.label["messages:screen1"], false)
            eui:uiSetVisible(UI.label["messages:chatScreen"], true)
            eui:uiSetText(UI.label["messages:chat:message"],
                tostring(eui:uiGridListGetItemData(source, sel, 1)))
        end
    elseif source == UI.gridlist.bank_accounts then
        if sel ~= -1 then
            eui:uiSetVisible(UI.label["wallet:screen:main"], false)
            eui:uiSetVisible(UI.label["wallet:screen:account"], true)
            eui:uiSetText(UI.label["wallet:balance"],
                "$" .. formatNumber(eui:uiGridListGetItemData(source, sel, 1)))
            app.currentWalletAccount = eui:uiGridListGetItemText(source, sel, 1)
        end
    elseif source == UI.gridlist.whatsapp then
        if sel ~= -1 then
            openWhatsappChat(eui:uiGridListGetItemData(source, sel, 1))
        end
    elseif source == UI.gridlist.recent_calls then
        if sel ~= -1 then
            call(eui:uiGridListGetItemData(source, sel, 1))
        end
    end
end)

--------------------------------------------------------------------------------
-- BOOT: lazy UIKit resolution with retries (Fix #45/#52 pattern)
--------------------------------------------------------------------------------
local function tryBuild()
    if built then return true end
    UIKitReady()
    if built then UIKitReadyPart2() end
    return built
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    pcall(function() sms_notifications = exports.settings:getSetting("sms_notifications") and true or false end)
    if not tryBuild() then
        local attempts = 0
        setTimer(function()
            attempts = attempts + 1
            if tryBuild() then
                killTimer(source)
            elseif attempts >= 15 then
                killTimer(source)
                outputDebugString("[phone-system] UIKit never became ready - phone UI unavailable", 2, 255, 170, 90)
            end
        end, 1000, 15)
    end
end)

addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, function() tryBuild() end)
