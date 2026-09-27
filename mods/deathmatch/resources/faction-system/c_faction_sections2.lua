-- ============================================================
-- Finance section
-- ============================================================
local finCols = {
    { name = "ID",     frac = 0.10 },
    { name = "الوقت",  frac = 0.25 },
    { name = "النوع",  frac = 0.10 },
    { name = "من",     frac = 0.18 },
    { name = "إلى",    frac = 0.18 },
    { name = "المبلغ", frac = 0.19 },
}

function drawFinance()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()

    if not F.financeLoaded then
        loadFinance()
        dxDrawText(T.loading, cx, cy, cx + cw, cy + 60 * scale,
            THEME.textDim, 1.0, "default", "center", "center", true, false, true)
        return
    end

    local fin = F.finance
    if not fin then return end

    -- assets panel (right)
    local aW = cw * 0.32
    local aX = cx + cw - aW
    dxDrawRoundedRect(aX, cy, aW, 110 * scale, tocolor(15, 18, 24, 255), 6, true)
    dxDrawText(T.assets, aX + 10 * scale, cy + 8 * scale, aX + aW, cy + 30 * scale,
        THEME.text, 1.0, "default-bold", "left", "top")
    local totalVal = (tonumber(fin.bankmoney) or 0) + (tonumber(fin.vehiclesvalue) or 0) + (tonumber(fin.propertiesvalue) or 0)
    local rows = {
        { T.bank,  "$" .. formatMoney(fin.bankmoney) },
        { T.vehs,  "$" .. formatMoney(fin.vehiclesvalue) },
        { T.props, "$" .. formatMoney(fin.propertiesvalue) },
    }
    local aY = cy + 34 * scale
    for _, r in ipairs(rows) do
        dxDrawText(r[1], aX + 10 * scale, aY, aX + aW * 0.6, aY + 20 * scale,
            THEME.textDim, 0.95, "default", "left", "center")
        dxDrawText(r[2], aX + aW * 0.5, aY, aX + aW - 10 * scale, aY + 20 * scale,
            THEME.online, 0.95, "default", "right", "center")
        aY = aY + 22 * scale
    end
    dxDrawRectangle(aX + 10 * scale, aY, aW - 20 * scale, 1, THEME.lineStrong, true)
    dxDrawText(T.total, aX + 10 * scale, aY + 4 * scale, aX + aW * 0.6, aY + 26 * scale,
        THEME.text, 0.95, "default-bold", "left", "center")
    dxDrawText("$" .. formatMoney(totalVal),
        aX + aW * 0.5, aY + 4 * scale, aX + aW - 10 * scale, aY + 26 * scale,
        THEME.online, 0.95, "default-bold", "right", "center")

    -- transactions (left)
    local tW = cw - aW - 15 * scale
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 44 * scale
    local colX = cx
    for _, col in ipairs(finCols) do
        local colW = tW * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, tW, 1, THEME.lineStrong, true)

    local txs = {}
    for _, t in ipairs(fin.thisWeek or {}) do table.insert(txs, t) end
    for _, t in ipairs(fin.prevWeek or {}) do table.insert(txs, t) end

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #txs - visibleRows) * rowH
    F.financeScroll = math.min(F.financeScroll, maxScroll)
    F.financeScroll = math.max(0, F.financeScroll)
    local startIdx = math.floor(F.financeScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #txs) do
        local t = txs[i]
        if not t then break end
        local rowY = listY + (i - startIdx) * rowH
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, tW, rowH, tocolor(255, 255, 255, 5), true)
        end
        local cX2 = cx
        dxDrawText(tostring(t.id or "-"), cX2 + 8 * scale, rowY, cX2 + tW * 0.10, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + tW * 0.10
        dxDrawText(truncate(tostring(t.time or "-"), tW * 0.25 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + tW * 0.25, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + tW * 0.25
        dxDrawText(tostring(t.type or "-"), cX2 + 8 * scale, rowY, cX2 + tW * 0.10, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + tW * 0.10
        dxDrawText(truncate(tostring(t.from or "-"), tW * 0.18 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + tW * 0.18, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + tW * 0.18
        dxDrawText(truncate(tostring(t.to or "-"), tW * 0.18 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + tW * 0.18, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + tW * 0.18
        local amount = tonumber(t.amount) or 0
        dxDrawText((amount >= 0 and "+" or "") .. "$" .. formatMoney(amount), cX2 + 8 * scale, rowY, cX2 + tW * 0.19, rowY + rowH,
            amount >= 0 and THEME.online or THEME.offline, 0.95, "default", "left", "center", true, false, true)

        dxDrawRectangle(cx, rowY + rowH - 1, tW, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + tW - 12 * scale, listY, listH, F.financeScroll, maxScroll)
    end

    -- refresh button (bottom)
    local rW = 110 * scale
    local btnY = cy + ch - 34 * scale
    local rHover = isMouseIn(cx, btnY, rW, 28 * scale)
    dxDrawRoundedRect(cx, btnY, rW, 28 * scale, rHover and THEME.btnBgHover or THEME.btnBg, 5, true)
    dxDrawText(T.refresh, cx, btnY, cx + rW, btnY + 28 * scale,
        rHover and THEME.primary or THEME.textDim, 0.9, "default-bold", "center", "center", true, false, true)
    F._finRefreshBtn = { x = cx, y = btnY, w = rW, h = 28 * scale }
end

-- ============================================================
-- Note section
-- ============================================================
function drawNote()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local isLeaderNote = F.isLeader and F.section == "note"

    dxDrawText(isLeaderNote and "ملاحظات القادة" or "ملاحظات الفاكشن",
        cx, cy, cx + cw, cy + 26 * scale, THEME.text, 1.1, "default-bold", "left", "center", true, false, true)
    local noteIconSize = 20 * scale
    drawIcon("note", cx + cw - noteIconSize - 4 * scale, cy + 3 * scale, noteIconSize, tocolor(255, 255, 255, 130))

    -- MOTD editor (leaders)
    local mY = cy + 30 * scale
    if isLeaderNote then
        dxDrawText("رسالة اليوم (MOTD)", cx, mY, cx + 300 * scale, mY + 18 * scale,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        local mEditY = mY + 22 * scale
        local mH = 46 * scale
        local mHover = isMouseIn(cx, mEditY, cw, mH)
        dxDrawRoundedRect(cx, mEditY, cw, mH, mHover and THEME.inputBgHov or THEME.inputBg, 5, true)
        dxDrawRectangle(cx, mEditY + mH - 1, cw, 1, THEME.lineStrong, true)
        dxDrawText(F.motdBuffer ~= "" and F.motdBuffer or T.motdph,
            cx + 10 * scale, mEditY, cx + cw - 10 * scale, mEditY + mH,
            F.motdBuffer ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "top", true, false, true)
        F._motdEdit = { x = cx, y = mEditY, w = cw, h = mH }

        local mSY = mEditY + mH + 8 * scale
        local mSW = 130 * scale
        local msHover = isMouseIn(cx, mSY, mSW, 30 * scale)
        dxDrawRoundedRect(cx, mSY, mSW, 30 * scale, msHover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
        dxDrawText(T.savemotd, cx, mSY, cx + mSW, mSY + 30 * scale,
            tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
        F._motdSaveBtn = { x = cx, y = mSY, w = mSW, h = 30 * scale }
        mY = mSY + 38 * scale
    end

    -- faction note
    if isLeaderNote then
        dxDrawText("الملاحظات", cx, mY, cx + cw, mY + 18 * scale,
            THEME.text, 0.95, "default", "left", "center", true, false, true)
    end
    local nY = mY + 22 * scale
    local nH = ch - (nY - cy) - (isLeaderNote and 50 * scale or 10 * scale)
    nH = math.max(nH, 40 * scale)
    local hover = isMouseIn(cx, nY, cw, nH)
    dxDrawRoundedRect(cx, nY, cw, nH, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawRectangle(cx, nY + nH - 1, cw, 1, THEME.lineStrong, true)

    local txt = isLeaderNote and F.noteBuffer or (F.data.fnote or "")
    dxDrawText(txt ~= "" and txt or T.noteph,
        cx + 10 * scale, nY, cx + cw - 10 * scale, nY + nH,
        txt ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "top", true, false, true)
    F._noteEdit = { x = cx, y = nY, w = cw, h = nH }

    if isLeaderNote then
        local sY = nY + nH + 10 * scale
        local sW = 130 * scale
        hover = isMouseIn(cx, sY, sW, 32 * scale)
        dxDrawRoundedRect(cx, sY, sW, 32 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
        dxDrawText(T.savenote, cx, sY, cx + sW, sY + 32 * scale,
            tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
        F._noteSaveBtn = { x = cx, y = sY, w = sW, h = 32 * scale }

        -- quit faction button
        local qX = cx + sW + 10 * scale
        hover = isMouseIn(qX, sY, sW, 32 * scale)
        dxDrawRoundedRect(qX, sY, sW, 32 * scale, hover and tocolor(180, 40, 40, 220) or tocolor(120, 30, 30, 160), 5, true)
        dxDrawText(T.quit, qX, sY, qX + sW, sY + 32 * scale,
            tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
        F._quitBtn = { x = qX, y = sY, w = sW, h = 32 * scale }
    end
end

-- ============================================================
-- Logs section
-- ============================================================
local logCols = {
    { name = "ID",     frac = 0.08 },
    { name = "الوقت",  frac = 0.24 },
    { name = "النوع",  frac = 0.10 },
    { name = "من",     frac = 0.19 },
    { name = "إلى",    frac = 0.19 },
    { name = "المبلغ", frac = 0.20 },
}

function drawLogs()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()

    if not F.financeLoaded then
        loadFinance()
        dxDrawText(T.loading, cx, cy, cx + cw, cy + 60 * scale,
            THEME.textDim, 1.0, "default", "center", "center", true, false, true)
        return
    end

    local fin = F.finance
    if not fin then return end

    local logIconSize = 20 * scale
    drawIcon("log", cx + cw - logIconSize - 4 * scale, cy + 3 * scale, logIconSize, tocolor(255, 255, 255, 130))

    -- local action log (top band)
    local actionLog = F.actionLog or {}
    local headerY = cy
    if #actionLog > 0 then
        local aH = math.min(74 * scale, 8 + #actionLog * 18 * scale)
        dxDrawRoundedRect(cx, cy, cw, aH, tocolor(15, 18, 24, 255), 5, true)
        dxDrawText("آخر الإجراءات", cx + 10 * scale, cy + 6 * scale, cx + cw, cy + 24 * scale,
            THEME.text, 0.9, "default-bold", "left", "center", true, false, true)
        local aY = cy + 26 * scale
        local maxShow = math.floor((aH - 28 * scale) / (18 * scale))
        for i = 1, math.min(maxShow, #actionLog) do
            local entry = actionLog[i]
            dxDrawText("• " .. tostring(entry.text), cx + 14 * scale, aY, cx + cw - 14 * scale, aY + 18 * scale,
                THEME.textDim, 0.9, "default", "left", "center", true, false, true)
            aY = aY + 18 * scale
        end
        dxDrawRectangle(cx, cy + aH, cw, 1, THEME.lineStrong, true)
        headerY = cy + aH + 8 * scale
    end

    local listY = headerY + 30 * scale
    local listH = ch - (listY - cy) - 10 * scale
    local colX = cx
    for _, col in ipairs(logCols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, headerY, colX + colW, headerY + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, headerY + 30 * scale, cw, 1, THEME.lineStrong, true)

    local txs = {}
    for _, t in ipairs(fin.thisWeek or {}) do table.insert(txs, t) end
    for _, t in ipairs(fin.prevWeek or {}) do table.insert(txs, t) end

    if #txs == 0 and #actionLog == 0 then
        dxDrawText(T.nologs, cx, listY, cx + cw - 14 * scale, listY + 60 * scale,
            THEME.textFaint, 1.0, "default", "center", "center", true, false, true)
    end

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #txs - visibleRows) * rowH
    F.logsScroll = math.min(F.logsScroll, maxScroll)
    F.logsScroll = math.max(0, F.logsScroll)
    local startIdx = math.floor(F.logsScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #txs) do
        local t = txs[i]
        if not t then break end
        local rowY = listY + (i - startIdx) * rowH
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        local cX2 = cx
        dxDrawText(tostring(t.id or "-"), cX2 + 8 * scale, rowY, cX2 + cw * 0.08, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.08
        dxDrawText(truncate(tostring(t.time or "-"), cw * 0.24 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + cw * 0.24, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.24
        dxDrawText(tostring(t.type or "-"), cX2 + 8 * scale, rowY, cX2 + cw * 0.10, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.10
        dxDrawText(truncate(tostring(t.from or "-"), cw * 0.19 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + cw * 0.19, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.19
        dxDrawText(truncate(tostring(t.to or "-"), cw * 0.19 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + cw * 0.19, rowY + rowH,
            THEME.textDim, 0.95, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.19
        local amount = tonumber(t.amount) or 0
        dxDrawText((amount >= 0 and "+" or "") .. "$" .. formatMoney(amount), cX2 + 8 * scale, rowY, cX2 + cw * 0.20, rowY + rowH,
            amount >= 0 and THEME.online or THEME.offline, 0.95, "default", "left", "center", true, false, true)

        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.logsScroll, maxScroll)
    end
end

-- ============================================================
-- Duty section (packages + locations + vehicles in one panel)
-- ============================================================
local dutyTabs = {
    { id = "packages",  label = "الحصص" },
    { id = "locations", label = "المواقع" },
    { id = "vehicles",  label = "المركبات" },
}

dutyRows = {}

function drawDuty()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()

    -- sub-tab bar
    local tabW = 110 * scale
    local tabH = 28 * scale
    F._dutyTabs = {}
    for i, t in ipairs(dutyTabs) do
        local tx = cx + (i - 1) * (tabW + 6 * scale)
        local selected = F.dutyTab == t.id
        local hover = isMouseIn(tx, cy, tabW, tabH)
        dxDrawRoundedRect(tx, cy, tabW, tabH, selected and tocolor(226, 72, 72, 40) or (hover and tocolor(255, 255, 255, 12) or tocolor(20, 24, 30, 255)), 5, true)
        if selected then
            dxDrawRectangle(tx, cy, 3, tabH, THEME.primary, true)
        end
        dxDrawText(t.label, tx + 8 * scale, cy, tx + tabW, cy + tabH,
            selected and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        F._dutyTabs[i] = { id = t.id, x = tx, y = cy, w = tabW, h = tabH }
    end

    local bodyY = cy + tabH + 8 * scale
    local bodyH = ch - tabH - 8 * scale

    if F.dutyTab == "packages" then
        drawDutyPackages(cx, bodyY, cw, bodyH)
    elseif F.dutyTab == "locations" then
        drawDutyLocations(cx, bodyY, cw, bodyH)
    else
        drawDutyVehicles(cx, bodyY, cw, bodyH)
    end
end

function drawDutyPackages(cx, cy, cw, ch)
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local colX = cx
    dxDrawText("ID", colX + 8 * scale, cy, colX + cw * 0.15, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.15
    dxDrawText("الاسم", colX + 8 * scale, cy, colX + cw * 0.45, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.45
    dxDrawText("المواقع", colX + 8 * scale, cy, colX + cw * 0.40, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local duties = {}
    for k, v in pairs(customg or {}) do
        table.insert(duties, { id = v[1], name = v[2], locs = v[4] })
    end
    table.sort(duties, function(a, b) return tostring(a.id) < tostring(b.id) end)
    dutyRows.packages = duties

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #duties - visibleRows) * rowH
    F.dutyScroll = math.min(F.dutyScroll, maxScroll)
    F.dutyScroll = math.max(0, F.dutyScroll)
    local startIdx = math.floor(F.dutyScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #duties) do
        local d = duties[i]
        if not d then break end
        local rowY = listY + (i - startIdx) * rowH
        local selected = F.dutySelPkg == d.id
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if selected then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, THEME.rowSelected, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        else
            if i % 2 == 0 then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
            end
            if hover then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
            end
        end
        dxDrawText(tostring(d.id), cx + 8 * scale, rowY, cx + cw * 0.15, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawText(tostring(d.name), cx + cw * 0.15 + 8 * scale, rowY, cx + cw * 0.60, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        local locStr = ""
        if type(d.locs) == "table" then
            local names = {}
            for _, l in pairs(d.locs) do
                if type(l) == "table" and l[2] then table.insert(names, tostring(l[2]))
                elseif type(l) ~= "table" then table.insert(names, tostring(l)) end
            end
            locStr = table.concat(names, ", ")
        end
        dxDrawText(truncate(locStr, cw * 0.40 - 16 * scale, "default"), cx + cw * 0.60 + 8 * scale, rowY, cx + cw, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if #duties == 0 then
        dxDrawText(T.noduty, cx, listY, cx + cw - 14 * scale, listY + 60 * scale,
            THEME.textFaint, 1.0, "default", "center", "center", true, false, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dutyBtns = {}
    local labels = { T.addduty, T.delduty }
    local bx = cx
    for i = 1, 2 do
        local hover = isMouseIn(bx, btnY, btnW, btnH)
        dxDrawRoundedRect(bx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        dxDrawText(labels[i], bx, btnY, bx + btnW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
        F._dutyBtns[i] = { x = bx, y = btnY, w = btnW, h = btnH }
        bx = bx + btnW + 8 * scale
    end
end

function drawDutyLocations(cx, cy, cw, ch)
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local cols = {
        { name = "ID",      frac = 0.10 },
        { name = "الاسم",   frac = 0.25 },
        { name = "النطاق",  frac = 0.10 },
        { name = "الداخل",  frac = 0.10 },
        { name = "البعد",   frac = 0.10 },
        { name = "X, Y, Z", frac = 0.35 },
    }
    local colX = cx
    for _, col in ipairs(cols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local locs = {}
    for k, v in pairs(locationsg or {}) do
        if not v[10] then table.insert(locs, v) end
    end
    table.sort(locs, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
    dutyRows.locations = locs

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #locs - visibleRows) * rowH
    F.dutyLocationsScroll = math.min(F.dutyLocationsScroll, maxScroll)
    F.dutyLocationsScroll = math.max(0, F.dutyLocationsScroll)
    local startIdx = math.floor(F.dutyLocationsScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #locs) do
        local l = locs[i]
        if not l then break end
        local rowY = listY + (i - startIdx) * rowH
        local selected = F.dutySelLoc == l[1]
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if selected then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, THEME.rowSelected, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        else
            if i % 2 == 0 then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
            end
            if hover then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
            end
        end
        local vals = { tostring(l[1] or "-"), tostring(l[2] or "-"), tostring(l[6] or "-"),
                       tostring(l[8] or "-"), tostring(l[7] or "-") }
        local fracs = { 0.10, 0.25, 0.10, 0.10, 0.10 }
        local cX2 = cx
        for j = 1, 5 do
            dxDrawText(vals[j], cX2 + 8 * scale, rowY, cX2 + cw * fracs[j], rowY + rowH,
                selected and THEME.text or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
            cX2 = cX2 + cw * fracs[j]
        end
        dxDrawText(string.format("%s, %s, %s", tostring(l[3] or 0), tostring(l[4] or 0), tostring(l[5] or 0)),
            cX2 + 8 * scale, rowY, cx + cw, rowY + rowH,
            selected and THEME.text or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if #locs == 0 then
        dxDrawText(T.noproplist, cx, listY, cx + cw - 14 * scale, listY + 60 * scale,
            THEME.textFaint, 1.0, "default", "center", "center", true, false, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyLocationsScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dlBtns = {}
    local labels = { T.addloc, T.delloc }
    local bx = cx
    for i = 1, 2 do
        local hover = isMouseIn(bx, btnY, btnW, btnH)
        dxDrawRoundedRect(bx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        dxDrawText(labels[i], bx, btnY, bx + btnW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
        F._dlBtns[i] = { x = bx, y = btnY, w = btnW, h = btnH }
        bx = bx + btnW + 8 * scale
    end
end

function drawDutyVehicles(cx, cy, cw, ch)
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local colX = cx
    dxDrawText("ID", colX + 8 * scale, cy, colX + cw * 0.2, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.2
    dxDrawText("رقم المركبة", colX + 8 * scale, cy, colX + cw * 0.4, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.4
    dxDrawText("الاسم", colX + 8 * scale, cy, colX + cw * 0.4, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local vehs = {}
    for k, v in pairs(locationsg or {}) do
        if v[10] then table.insert(vehs, v) end
    end
    table.sort(vehs, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
    dutyRows.vehicles = vehs

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #vehs - visibleRows) * rowH
    F.dutyVehiclesScroll = math.min(F.dutyVehiclesScroll, maxScroll)
    F.dutyVehiclesScroll = math.max(0, F.dutyVehiclesScroll)
    local startIdx = math.floor(F.dutyVehiclesScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #vehs) do
        local v = vehs[i]
        if not v then break end
        local rowY = listY + (i - startIdx) * rowH
        local selected = F.dutySelLoc == v[1]
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if selected then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, THEME.rowSelected, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        else
            if i % 2 == 0 then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
            end
            if hover then
                dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
            end
        end
        dxDrawText(tostring(v[1] or "-"), cx + 8 * scale, rowY, cx + cw * 0.2, rowY + rowH,
            selected and THEME.text or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawText(tostring(v[9] or "-"), cx + cw * 0.2 + 8 * scale, rowY, cx + cw * 0.6, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        local vehName = getVehicleNameFromModel(tonumber(v[10]) or 0) or tostring(v[10] or "-")
        dxDrawText(tostring(vehName), cx + cw * 0.6 + 8 * scale, rowY, cx + cw, rowY + rowH,
            selected and THEME.text or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if #vehs == 0 then
        dxDrawText(T.noproplist, cx, listY, cx + cw - 14 * scale, listY + 60 * scale,
            THEME.textFaint, 1.0, "default", "center", "center", true, false, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyVehiclesScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dvBtns = {}
    local labels = { T.addveh, T.delveh }
    local bx = cx
    for i = 1, 2 do
        local hover = isMouseIn(bx, btnY, btnW, btnH)
        dxDrawRoundedRect(bx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        dxDrawText(labels[i], bx, btnY, bx + btnW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
        F._dvBtns[i] = { x = bx, y = btnY, w = btnW, h = btnH }
        bx = bx + btnW + 8 * scale
    end
end
