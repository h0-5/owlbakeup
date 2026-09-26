-- ============================================================
-- Management section
-- ============================================================
function drawManagement()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()

    dxDrawText("\216\165\216\175\216\167\216\177\216\169 \216\167\217\132\217\129\216\167\216\170\217\138\217\134", cx, cy, cx + cw, cy + 26 * scale,
        THEME.text, 1.1, "default-bold", "left", "center", true, false, true)
    local cogSize = 20 * scale
    drawIcon("cog", cx + cw - cogSize - 4 * scale, cy + 3 * scale, cogSize, tocolor(255, 255, 255, 130))

    -- MOTD editor
    local mY = cy + 36 * scale
    dxDrawText("\216\177\216\179\216\167\217\132\216\169 \216\167\217\132\217\138\217\136\217\133 (MOTD)", cx, mY, cx + 300 * scale, mY + 20 * scale,
        THEME.textDim, 1.0, "default", "left", "center", true, false, true)
    local mEditY = mY + 24 * scale
    local hover = isMouseIn(cx, mEditY, cw, 60 * scale)
    dxDrawRoundedRect(cx, mEditY, cw, 60 * scale, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawRectangle(cx, mEditY + 59 * scale, cw, 1, THEME.lineStrong, true)
    dxDrawText(F.motdBuffer ~= "" and F.motdBuffer or T.motdph,
        cx + 10 * scale, mEditY, cx + cw - 10 * scale, mEditY + 60 * scale,
        F.motdBuffer ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "top", true, false, true)
    F._motdEdit = { x = cx, y = mEditY, w = cw, h = 60 * scale }

    local sY = mEditY + 68 * scale
    local sW = 130 * scale
    hover = isMouseIn(cx, sY, sW, 32 * scale)
    dxDrawRoundedRect(cx, sY, sW, 32 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText(T.savemotd, cx, sY, cx + sW, sY + 32 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._motdSaveBtn = { x = cx, y = sY, w = sW, h = 32 * scale }

    -- quit button
    local qY = sY + 44 * scale
    hover = isMouseIn(cx, qY, sW, 32 * scale)
    dxDrawRoundedRect(cx, qY, sW, 32 * scale, hover and tocolor(180, 40, 40, 220) or tocolor(120, 30, 30, 160), 5, true)
    dxDrawText(T.quit, cx, qY, cx + sW, qY + 32 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._quitBtn = { x = cx, y = qY, w = sW, h = 32 * scale }
end

-- ============================================================
-- Finance section
-- ============================================================
local finCols = {
    { name = "ID",     frac = 0.10 },
    { name = "\216\167\217\132\217\136\217\130\216\170",  frac = 0.25 }, -- الوقت
    { name = "\216\167\217\132\217\134\217\136\216\185",  frac = 0.10 }, -- النوع
    { name = "\217\133\217\134",       frac = 0.18 }, -- من
    { name = "\216\165\217\132\217\137",       frac = 0.18 }, -- إلى
    { name = "\216\167\217\132\217\133\216\168\217\132\216\159",  frac = 0.19 }, -- المبلغ
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

    local bankIconSize = 20 * scale
    drawIcon("bank", cx + cw - bankIconSize - 4 * scale, cy + 3 * scale, bankIconSize, tocolor(255, 255, 255, 130))

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
    local listH = ch - 34 * scale - 10 * scale
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
end

-- ============================================================
-- Note section
-- ============================================================
function drawNote()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local isLeaderNote = F.isLeader and F.section == "note"

    dxDrawText(isLeaderNote and "\217\133\217\132\216\167\216\184\216\157\216\167\216\170 \216\167\217\132\217\130\216\167\216\166\216\175" or "\217\133\217\132\216\167\216\184\216\157\216\167\216\170 \216\167\217\132\217\129\216\167\216\170\217\138\217\134",
        cx, cy, cx + cw, cy + 26 * scale, THEME.text, 1.1, "default-bold", "left", "center", true, false, true)
    local noteIconSize = 20 * scale
    drawIcon("note", cx + cw - noteIconSize - 4 * scale, cy + 3 * scale, noteIconSize, tocolor(255, 255, 255, 130))

    local nY = cy + 36 * scale
    local nH = ch - 36 * scale - (isLeaderNote and 50 * scale or 10 * scale)
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
    end
end

-- ============================================================
-- Duty sections
-- ============================================================
-- ============================================================
-- Logs section (faction transaction log)
-- ============================================================
local logCols = {
    { name = "ID",     frac = 0.08 },
    { name = "\216\167\217\132\217\136\217\130\216\170",  frac = 0.24 }, -- الوقت
    { name = "\216\167\217\132\217\134\217\136\216\185",  frac = 0.10 }, -- النوع
    { name = "\217\133\217\134",       frac = 0.19 }, -- من
    { name = "\216\165\217\132\217\137",       frac = 0.19 }, -- إلى
    { name = "\216\167\217\132\217\133\216\168\217\132\216\159",  frac = 0.20 }, -- المبلغ
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

    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 10 * scale
    local colX = cx
    for _, col in ipairs(logCols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local txs = {}
    for _, t in ipairs(fin.thisWeek or {}) do table.insert(txs, t) end
    for _, t in ipairs(fin.prevWeek or {}) do table.insert(txs, t) end

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

function drawDuty()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local colX = cx
    dxDrawText("ID", colX + 8 * scale, cy, colX + cw * 0.15, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.15
    dxDrawText("\216\167\217\132\216\167\216\179\217\133", colX + 8 * scale, cy, colX + cw * 0.45, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.45
    dxDrawText("\216\167\217\132\217\133\217\136\216\167\216\185\216\167\216\170", colX + 8 * scale, cy, colX + cw * 0.40, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local duties = {}
    for k, v in pairs(customg or {}) do
        table.insert(duties, { id = v[1], name = v[2], locs = v[4] })
    end
    table.sort(duties, function(a, b) return tostring(a.id) < tostring(b.id) end)

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #duties - visibleRows) * rowH
    F.dutyScroll = math.min(F.dutyScroll, maxScroll)
    local startIdx = math.floor(F.dutyScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #duties) do
        local d = duties[i]
        if not d then break end
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        if hover then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
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

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dutyBtns = {}
    local labels = { "\216\165\216\182\216\167\217\129\216\169 \216\175\217\138\217\136\216\170\217\138", "\216\173\216\176\217\129 \216\175\217\138\217\136\216\170\217\138" }
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

function drawDutyLocations()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local cols = {
        { name = "ID",     frac = 0.10 },
        { name = "\216\167\217\132\216\167\216\179\217\133", frac = 0.25 },
        { name = "\216\167\217\132\217\132\216\183\216\167\217\130", frac = 0.10 },
        { name = "\216\167\217\132\216\175\216\167\216\174\217\132\217\137", frac = 0.10 },
        { name = "\216\167\217\132\216\168\216\185\216\175", frac = 0.10 },
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

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #locs - visibleRows) * rowH
    F.dutyLocationsScroll = math.min(F.dutyLocationsScroll, maxScroll)
    local startIdx = math.floor(F.dutyLocationsScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #locs) do
        local l = locs[i]
        if not l then break end
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        if hover then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end
        local vals = { tostring(l[1] or "-"), tostring(l[2] or "-"), tostring(l[6] or "-"),
                       tostring(l[8] or "-"), tostring(l[7] or "-") }
        local fracs = { 0.10, 0.25, 0.10, 0.10, 0.10 }
        local cX2 = cx
        for j = 1, 5 do
            dxDrawText(vals[j], cX2 + 8 * scale, rowY, cX2 + cw * fracs[j], rowY + rowH,
                THEME.textDim, 1.0, "default", "left", "center", true, false, true)
            cX2 = cX2 + cw * fracs[j]
        end
        dxDrawText(string.format("%s, %s, %s", tostring(l[3] or 0), tostring(l[4] or 0), tostring(l[5] or 0)),
            cX2 + 8 * scale, rowY, cx + cw, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyLocationsScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dlBtns = {}
    local labels = { "\216\165\216\182\216\167\217\129\216\169 \217\133\217\136\216\167\216\185", "\216\173\216\176\217\129 \217\133\217\136\216\167\216\185" }
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

function drawDutyVehicles()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local colX = cx
    dxDrawText("ID", colX + 8 * scale, cy, colX + cw * 0.2, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.2
    dxDrawText("\216\177\217\130\217\133 \217\133\216\177\226\128\145\216\167\216\169", colX + 8 * scale, cy, colX + cw * 0.4, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    colX = colX + cw * 0.4
    dxDrawText("\216\167\217\132\216\167\216\179\217\133", colX + 8 * scale, cy, colX + cw * 0.4, cy + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local vehs = {}
    for k, v in pairs(locationsg or {}) do
        if v[10] then table.insert(vehs, v) end
    end
    table.sort(vehs, function(a, b) return tostring(a[1]) < tostring(b[1]) end)

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #vehs - visibleRows) * rowH
    F.dutyVehiclesScroll = math.min(F.dutyVehiclesScroll, maxScroll)
    local startIdx = math.floor(F.dutyVehiclesScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #vehs) do
        local v = vehs[i]
        if not v then break end
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        if hover then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end
        dxDrawText(tostring(v[1] or "-"), cx + 8 * scale, rowY, cx + cw * 0.2, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawText(tostring(v[9] or "-"), cx + cw * 0.2 + 8 * scale, rowY, cx + cw * 0.6, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        local vehName = getVehicleNameFromModel(tonumber(v[10]) or 0) or tostring(v[10] or "-")
        dxDrawText(tostring(vehName), cx + cw * 0.6 + 8 * scale, rowY, cx + cw, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.dutyVehiclesScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 130 * scale, 30 * scale
    F._dvBtns = {}
    local labels = { "\216\165\216\182\216\167\217\129\216\169 \217\133\216\177\226\128\145\216\167\216\169", "\216\173\216\176\217\129 \217\133\216\177\226\128\145\216\167\216\169" }
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
