-- ============================================================
-- Faction System - Client UI (OWL Design)
-- All rendering and layout. Texts are stored as UTF-8 escaped
-- byte sequences to survive any file encoding issues.
-- ============================================================

sx, sy = guiGetScreenSize()
scale = math.min(sx / 1728, sy / 972)
scale = math.max(scale, 0.55)

-- Arabic strings (real UTF-8)
T = {
    members   = "الأعضاء",
    ranks     = "الرتب",
    vehicles  = "المركبات",
    duty      = "الديوتي",
    dutyloc   = "مواقع الديوتي",
    dutyveh   = "سيارات الديوتي",
    mgmt      = "الإدارة",
    finance   = "المالية",
    logs      = "السجل",
    note      = "الملاحظات",
    online    = "متصل",
    offline   = "غير متصل",
    today     = "اليوم",
    yesterday = "أمس",
    never     = "أبداً",
    days      = "يوم",
    onduty    = "في الخدمة",
    offduty   = "خارج",
    leader    = "زعيم",
    member    = "عضو",
    kick      = "طرد",
    promote   = "ترقية/خفض",
    setleader = "تعيين قائد",
    addmem    = "إضافة",
    perks     = "صلاحيات",
    respawn   = "رسبنة السيارات",
    save      = "حفظ التغييرات",
    close     = "إغلاق",
    yes       = "نعم",
    no        = "لا",
    quit      = "مغادرة الفاكشن",
    savemotd  = "حفظ الرسالة",
    savenote  = "حفظ الملاحظات",
    add       = "إضافة",
    cancel    = "إلغاء",
    nameph    = "اسم الشخصية",
    rankph    = "اسم الرتبة",
    wageph    = "الراتب",
    motdph    = "اكتب رسالة اليوم",
    noteph    = "لا توجد ملاحظات",
    selectmem = "ارجوك اختر عضوا اولا",
    title     = "الأعضاء",
    connected = "المتصلون",
    assets    = "الأصول",
    bank      = "حساب البنك",
    vehs      = "المركبات",
    props     = "الخصائص",
    total     = "المجموع",
    loading   = "جاري تحميل البيانات...",
    notfound  = "اللاعب غير متصل",
}

THEME = {
    bg          = tocolor(6, 9, 14, 245),
    bgSoft      = tocolor(11, 14, 19, 235),
    sidebar     = tocolor(19, 22, 27, 255),
    rowHover    = tocolor(9, 12, 17, 200),
    rowSelected = tocolor(3, 6, 11, 255),
    line        = tocolor(255, 255, 255, 18),
    lineStrong  = tocolor(255, 255, 255, 35),
    text        = tocolor(255, 255, 255, 255),
    textDim     = tocolor(255, 255, 255, 170),
    textFaint   = tocolor(255, 255, 255, 110),
    primary     = tocolor(226, 72, 72, 255),
    primarySoft = tocolor(226, 72, 72, 60),
    online      = tocolor(0, 255, 0, 255),
    offline     = tocolor(255, 0, 0, 255),
    overlay     = tocolor(0, 0, 0, 200),
    btnBg       = tocolor(20, 24, 30, 255),
    btnBgHover  = tocolor(30, 34, 42, 255),
    inputBg     = tocolor(15, 18, 24, 255),
    inputBgHov  = tocolor(25, 28, 35, 255),
}

factionTypes = {
    [1] = "GANG", [2] = "MAFIA", [3] = "LAW", [4] = "GOV", [5] = "MED",
    [6] = "OTHER", [7] = "NEWS", [8] = "MECHANIC", [9] = "ELECTRIC",
    [10] = "TRAFFIC", [11] = "BUSINESS", [12] = "FAMILY",
}

rowH = 30 * scale
menuW = 150 * scale
winW, winH = 955 * scale, 625 * scale
headerH = 125 * scale

function winPos()
    return (sx - winW) / 2, (sy - winH) / 2
end

function contentX()
    local x = winPos()
    return x + menuW + 10 * scale
end
function contentY()
    local _, y = winPos()
    return y + headerH + 5 * scale
end
function contentW()
    return winW - menuW - 15 * scale
end
function contentH()
    return winH - headerH - 15 * scale
end

-- ============================================================
-- Utilities
-- ============================================================
function isMouseIn(x, y, w, h)
    if not F.cursorValid then return false end
    local cx, cy = F.cursorX, F.cursorY
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function pointInBox(px, py, box)
    return box and px >= box.x and px <= box.x + box.w and py >= box.y and py <= box.y + box.h
end

function dxDrawRoundedRect(x, y, w, h, color, radius, postGUI)
    radius = radius or 6
    if postGUI == nil then postGUI = true end
    dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI)
    dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI)
    dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI)
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 10, 1, postGUI)
    dxDrawCircle(x + w - radius, y + radius, radius, 270, 360, color, color, 10, 1, postGUI)
    dxDrawCircle(x + radius, y + h - radius, radius, 90, 180, color, color, 10, 1, postGUI)
    dxDrawCircle(x + w - radius, y + h - radius, radius, 0, 90, color, color, 10, 1, postGUI)
end

function formatMoney(amount)
    amount = tonumber(amount) or 0
    local formatted = tostring(math.floor(amount))
    while true do
        local k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == formatted then break end
        formatted = k
    end
    return formatted
end

function truncate(text, maxW, font)
    if not text or text == "" then return "" end
    if dxGetTextWidth(text, 1, font) <= maxW then return text end
    while #text > 0 and dxGetTextWidth(text .. "...", 1, font) > maxW do
        text = string.sub(text, 1, -2)
    end
    return text .. "..."
end

function updateCursorCache()
    if isCursorShowing() then
        local cx, cy = getCursorPosition()
        F.cursorX, F.cursorY = cx * sx, cy * sy
        F.cursorValid = true
    else
        F.cursorValid = false
    end
end

function drawScrollbar(x, y, h, scroll, maxScroll)
    if maxScroll <= 0 then return end
    local thumbH = math.max(h * (h / (h + maxScroll)), 20)
    local thumbY = y + (scroll / maxScroll) * (h - thumbH)
    dxDrawRectangle(x, y, 4, h, tocolor(255, 255, 255, 15), true)
    dxDrawRectangle(x, thumbY, 4, thumbH, THEME.primary, true)
end

-- ============================================================
-- Menu definition
-- ============================================================
function buildMenu()
    F.menu = {
        { id = "members", title = T.members, icon = "group" },
    }
    if F.isLeader then
        table.insert(F.menu, { id = "ranks", title = T.ranks, icon = "star" })
        table.insert(F.menu, { id = "vehicles", title = T.vehicles, icon = "car" })
        if F.factionType and F.factionType >= 2 then
            table.insert(F.menu, { id = "duty", title = T.duty, icon = "box" })
            table.insert(F.menu, { id = "dutylocations", title = T.dutyloc, icon = "pin" })
            table.insert(F.menu, { id = "dutyvehicles", title = T.dutyveh, icon = "truck" })
        end
        table.insert(F.menu, { id = "management", title = T.mgmt, icon = "cog" })
        table.insert(F.menu, { id = "finance", title = T.finance, icon = "bank" })
        table.insert(F.menu, { id = "logs", title = T.logs, icon = "log" })
    end
    table.insert(F.menu, { id = "note", title = T.note, icon = "note" })
end

-- ============================================================
-- Header
-- ============================================================
function drawHeader()
    local x, y = winPos()

    -- logo circle with initials
    local logoSize = 100 * scale
    local logoX = x + (menuW - logoSize) / 2
    local logoY = y + 15 * scale
    dxDrawCircle(logoX + logoSize / 2, logoY + logoSize / 2, logoSize / 2, 0, 360, tocolor(20, 24, 30, 255), tocolor(20, 24, 30, 255), 30, 1, true)
    dxDrawCircle(logoX + logoSize / 2, logoY + logoSize / 2, logoSize / 2 - 3 * scale, 0, 360, THEME.primary, THEME.primary, 30, 1, true)
    local fname = (F.team and getTeamName(F.team)) or "F"
    local initials = string.upper(string.sub(fname, 1, 2))
    dxDrawText(initials, logoX, logoY, logoX + logoSize, logoY + logoSize, tocolor(255, 255, 255, 255), 1.6 * scale, "default-bold", "center", "center", true, false, true)

    -- title
    local fType = factionTypes[F.factionType] or "OTHER"
    local fID = tonumber(F.factionID) or -1
    local fTitle = ((F.team and getTeamName(F.team)) or "Faction")
    local title = "#E24848# " .. fID .. " #FFFFFF" .. fTitle .. "  #7F7F7F(" .. fType .. ")"
    dxDrawText(title, contentX(), y + 12 * scale, contentX() + 500 * scale, y + 45 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "left", "center", true, false, true)

    -- info
    local infoY = y + 48 * scale
    dxDrawText("#00FF00\226\128\162 #FFFFFF" .. F.onlineCount .. " " .. T.online .. "  #FF0000\226\128\162 #FFFFFF" .. (F.maxMembers - F.onlineCount) .. " " .. T.offline,
        contentX(), infoY, contentX() + 500 * scale, infoY + 22 * scale, tocolor(255, 255, 255, 255), 1.0, "default", "left", "center", true, false, true)

    if F.phone then
        dxDrawText("#E24848\226\128\162 #FFFFFF" .. "\216\167\217\132\216\174\216\183 \216\167\217\132\216\179\216\167\216\174\217\134: " .. tostring(F.phone),
            contentX(), infoY + 22 * scale, contentX() + 500 * scale, infoY + 44 * scale,
            tocolor(255, 255, 255, 255), 1.0, "default", "left", "center", true, false, true)
    end

    -- level/online box (matching reference level panel)
    local boxW, boxH = 150 * scale, 60 * scale
    local boxX = x + winW - boxW - 15 * scale
    local boxY = y + 50 * scale
    dxDrawRoundedRect(boxX, boxY, boxW, boxH, tocolor(20, 20, 20, 240), 6, true)
    dxDrawText(T.connected, boxX + 10 * scale, boxY + 6 * scale, boxX + boxW, boxY + 26 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "left", "top")
    local pct = F.slotLimit > 0 and (F.onlineCount / F.slotLimit) or 0
    dxDrawText(F.onlineCount .. " / " .. F.slotLimit, boxX + 10 * scale, boxY + 30 * scale, boxX + boxW, boxY + 50 * scale,
        THEME.primary, 1.0, "default-bold", "left", "top")
    local barW = boxW - 20 * scale
    dxDrawRectangle(boxX + 10 * scale, boxY + boxH - 8 * scale, barW, 4, tocolor(30, 30, 30, 255), true)
    dxDrawRectangle(boxX + 10 * scale, boxY + boxH - 8 * scale, barW * pct, 4, THEME.primary, true)

    -- close button
    local closeSize = 30 * scale
    local closeX = x + winW - closeSize - 12 * scale
    local closeY = y + 12 * scale
    local hover = isMouseIn(closeX, closeY, closeSize, closeSize)
    dxDrawRoundedRect(closeX, closeY, closeSize, closeSize, hover and tocolor(226, 72, 72, 200) or tocolor(20, 20, 20, 240), 6, true)
    drawIcon("close", closeX + 5 * scale, closeY + 5 * scale, closeSize - 10 * scale, tocolor(255, 255, 255, 220))
    F._closeBtn = { x = closeX, y = closeY, w = closeSize, h = closeSize }

    -- more button (change faction, matching reference more.png)
    local moreSize = 34 * scale
    local moreX = closeX - moreSize - 6 * scale
    hover = isMouseIn(moreX, closeY, moreSize, moreSize)
    dxDrawRoundedRect(moreX, closeY, moreSize, moreSize, hover and tocolor(30, 34, 42, 255) or tocolor(20, 20, 20, 240), 6, true)
    drawIcon("more", moreX + 6 * scale, closeY + 6 * scale, moreSize - 12 * scale, tocolor(255, 255, 255, 200))
    F._moreBtn = { x = moreX, y = closeY, w = moreSize, h = moreSize }

    -- separator
    dxDrawRectangle(x + 10 * scale, y + headerH, winW - 20 * scale, 1, THEME.lineStrong, true)
end

-- ============================================================
-- Sidebar
-- ============================================================
function drawSidebar()
    local x, y = winPos()
    local itemH = 34 * scale
    local startY = y + headerH + 15 * scale

    for i, item in ipairs(F.menu) do
        local itemY = startY + (i - 1) * itemH
        local selected = F.section == item.id
        local hover = isMouseIn(x + 10 * scale, itemY, menuW - 10 * scale, itemH)

        if selected then
            dxDrawRoundedRect(x + 10 * scale, itemY, menuW - 10 * scale, itemH, THEME.rowSelected, 6, true)
            dxDrawRectangle(x + 10 * scale, itemY, 3, itemH, THEME.primary, true)
        elseif hover then
            dxDrawRoundedRect(x + 10 * scale, itemY, menuW - 10 * scale, itemH, THEME.rowHover, 6, true)
        end

        dxDrawText(item.title, x + 50 * scale, itemY, x + menuW, itemY + itemH,
            selected and THEME.primary or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        local iconSize = 18 * scale
        drawIcon(item.icon, x + 20 * scale, itemY + (itemH - iconSize) / 2, iconSize,
            selected and THEME.primary or tocolor(255, 255, 255, 130))
    end
end
