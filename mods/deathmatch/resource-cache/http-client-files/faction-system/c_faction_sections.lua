-- ============================================================
-- Members section
-- ============================================================
local memberCols = {
    { name = "\216\167\217\132\216\167\216\179\217\133",       frac = 0.30 }, -- الاسم
    { name = "\216\167\217\132\216\177\216\170\216\168\216\169", frac = 0.22 }, -- الرتبة
    { name = "\216\167\217\132\216\173\216\167\217\132\216\169", frac = 0.11 }, -- الحالة
    { name = "\216\162\216\174\216\177 \216\175\216\174\217\136\217\132", frac = 0.15 }, -- آخر دخول
    { name = "\216\167\217\132\216\177\216\167\216\170\216\168", frac = 0.10 }, -- الراتب
    { name = "\216\167\217\132\216\175\217\138\217\136\216\170\217\138", frac = 0.12 }, -- الديوتي
}

function drawMembers()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local btnSpace = F.isLeader and 46 * scale or 10 * scale
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - btnSpace

    -- headers
    local colX = cx
    for _, col in ipairs(memberCols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local rows = F.members
    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #rows - visibleRows) * rowH
    F.membersScroll = math.min(F.membersScroll, maxScroll)
    local startIdx = math.floor(F.membersScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #rows) do
        local row = rows[i]
        if not row then break end
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        local selected = F.membersSelected == i

        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        if selected then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, THEME.primarySoft, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        elseif hover then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end

        local cX2, colW2 = cx, cw * memberCols[1].frac
        dxDrawText(truncate(row.name, colW2 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            row.online and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * memberCols[2].frac
        dxDrawText(truncate(row.rankName, colW2 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * memberCols[3].frac
        dxDrawText(row.online and T.online or T.offline, cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            row.online and THEME.online or THEME.offline, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * memberCols[4].frac
        dxDrawText(row.login, cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * memberCols[5].frac
        if F.factionType and F.factionType >= 2 then
            dxDrawText("$" .. formatMoney(row.wage), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
                THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        end

        cX2 = cX2 + colW2; colW2 = cw * memberCols[6].frac
        if F.factionType and F.factionType >= 2 then
            dxDrawText(row.duty and T.onduty or T.offduty, cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
                row.duty and THEME.online or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
        end

        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.membersScroll, maxScroll)
    end

    -- action buttons (matching reference layout & widths)
    if F.isLeader then
        local btnY = cy + ch - 40 * scale
        local btnH = 30 * scale
        local gap = 5 * scale
        -- reference: Dismissal 100, Promote/Demote 120, DutyPerks 120, SetLevel 100, AddMember 30
        local buttons = {
            { id = "kick",    label = T.kick,    w = 100, icon = "close" },
            { id = "promote", label = T.promote, w = 120, icon = "star" },
            { id = "perks",   label = T.perks,   w = 120, icon = "box" },
            { id = "leader",  label = T.setleader, w = 100, icon = "shield" },
        }
        local bx = cx
        F._actionButtons = {}
        for _, b in ipairs(buttons) do
            local btnW = b.w * scale
            local hover = isMouseIn(bx, btnY, btnW, btnH)
            dxDrawRoundedRect(bx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
            dxDrawRectangle(bx, btnY, btnW, 2, hover and THEME.primary or tocolor(255, 255, 255, 20), true)
            local iconSize = 16 * scale
            drawIcon(b.icon, bx + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
                hover and THEME.primary or tocolor(255, 255, 255, 130))
            dxDrawText(b.label, bx + 28 * scale, btnY, bx + btnW, btnY + btnH,
                hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
            F._actionButtons[b.id] = { x = bx, y = btnY, w = btnW, h = btnH }
            bx = bx + btnW + gap
        end
        -- add member button (small + button)
        local addW = 30 * scale
        local hover = isMouseIn(bx, btnY, addW, btnH)
        dxDrawRoundedRect(bx, btnY, addW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        drawIcon("plus", bx + 6 * scale, btnY + 6 * scale, addW - 12 * scale,
            hover and THEME.primary or tocolor(255, 255, 255, 200))
        F._actionButtons["add"] = { x = bx, y = btnY, w = addW, h = btnH }
        bx = bx + addW + gap
        -- respawn all vehicles
        local rvW = 150 * scale
        hover = isMouseIn(bx, btnY, rvW, btnH)
        dxDrawRoundedRect(bx, btnY, rvW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        local iconSize = 16 * scale
        drawIcon("car", bx + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
            hover and THEME.primary or tocolor(255, 255, 255, 130))
        dxDrawText(T.respawn, bx + 28 * scale, btnY, bx + rvW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        F._actionButtons["respawn"] = { x = bx, y = btnY, w = rvW, h = btnH }
        bx = bx + rvW + gap
        -- online/offline legend (matching reference)
        local legendW = 200 * scale
        if bx + legendW <= cx + cw then
            dxDrawText("#00FF00\226\128\162 #FFFFFF" .. T.online .. "   #FF0000\226\128\162 #FFFFFF" .. T.offline,
                bx, btnY, bx + legendW, btnY + btnH,
                tocolor(255, 255, 255, 150), 0.9, "default", "left", "center", true, false, true)
        end
    end
end

-- ============================================================
-- Ranks section
-- ============================================================
function drawRanks()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local ranks = F.data.factionRanks or {}
    local wages = F.data.factionWages or {}

    local listW = cw * 0.5 - 5 * scale
    local headerH2 = 30 * scale
    local listY = cy + headerH2 + 5 * scale
    local listH = ch - headerH2 - 15 * scale
    local btnH = F.isLeader and 40 * scale or 10 * scale
    listH = listH - btnH

    dxDrawText("\216\167\217\132\216\177\216\170\216\168 (1 - 20)", cx + 8 * scale, cy, cx + listW, cy + headerH2,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawText("\216\167\217\132\216\177\216\167\216\170\216\168", cx + listW * 0.65, cy, cx + listW, cy + headerH2,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawRectangle(cx, cy + headerH2, listW, 1, THEME.lineStrong, true)

    F.ranksSelected = math.max(0, math.min(F.ranksSelected, 20))

    local visibleRows = math.floor(listH / rowH)
    local totalRows = 20
    local maxScroll = math.max(0, totalRows - visibleRows) * rowH
    F.ranksScroll = math.min(F.ranksScroll, maxScroll)
    F.ranksScroll = math.max(0, F.ranksScroll)
    local startIdx = math.floor(F.ranksScroll / rowH) + 1

    F._rankRows = {}
    for i = startIdx, math.min(startIdx + visibleRows, totalRows) do
        local rankName = ranks[i] or ("Rank " .. i)
        local wage = wages[i] or 0
        local rowY = listY + (i - startIdx) * rowH
        if rowY + rowH > listY + listH then break end
        local hover = isMouseIn(cx, rowY, listW, rowH)
        local selected = F.ranksSelected == i
        if selected then
            dxDrawRectangle(cx, rowY, listW, rowH, THEME.primarySoft, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        elseif hover then
            dxDrawRectangle(cx, rowY, listW, rowH, tocolor(255, 255, 255, 10), true)
        end
        dxDrawText("#" .. i, cx + 8 * scale, rowY, cx + listW * 0.1, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawText(tostring(rankName), cx + listW * 0.12, rowY, cx + listW * 0.65, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        dxDrawText("$" .. formatMoney(wage), cx + listW * 0.65, rowY, cx + listW, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, listW, 1, THEME.line, true)
        F._rankRows[i] = { x = cx, y = rowY, w = listW, h = rowH, idx = i }
    end

    if maxScroll > 0 then
        drawScrollbar(cx + listW - 12 * scale, listY, listH, F.ranksScroll, maxScroll)
    end

    -- editor
    local edX = cx + cw * 0.5 + 5 * scale
    local edW = cw * 0.5 - 5 * scale
    dxDrawText("\216\170\216\185\216\175\217\138\217\132 \216\167\217\132\216\177\216\170\216\168\216\169 #" .. (F.ranksSelected > 0 and F.ranksSelected or "-"),
        edX, cy, edX + edW, cy + 24 * scale, THEME.text, 1.0, "default-bold", "left", "center", true, false, true)
    local starSize = 18 * scale
    drawIcon("star", edX + edW - starSize - 4 * scale, cy + 3 * scale, starSize, tocolor(255, 255, 255, 130))

    local nameY = cy + 30 * scale
    local hover = isMouseIn(edX, nameY, edW, 30 * scale)
    dxDrawRoundedRect(edX, nameY, edW, 30 * scale, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawRectangle(edX, nameY + 29 * scale, edW, 1, THEME.lineStrong, true)
    local curName = F.rankNameBuffer
    if curName == "" and F.ranksSelected > 0 then curName = ranks[F.ranksSelected] or "" end
    dxDrawText(curName ~= "" and curName or T.rankph, edX + 10 * scale, nameY, edX + edW, nameY + 30 * scale,
        curName ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
    F._rankNameEdit = { x = edX, y = nameY, w = edW, h = 30 * scale }

    local wageY = nameY + 38 * scale
    hover = isMouseIn(edX, wageY, edW, 30 * scale)
    dxDrawRoundedRect(edX, wageY, edW, 30 * scale, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawRectangle(edX, wageY + 29 * scale, edW, 1, THEME.lineStrong, true)
    local curWage = F.rankWageBuffer
    if curWage == "" and F.ranksSelected > 0 then curWage = tostring(wages[F.ranksSelected] or 0) end
    dxDrawText(curWage ~= "" and curWage or T.wageph, edX + 10 * scale, wageY, edX + edW, wageY + 30 * scale,
        curWage ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
    F._rankWageEdit = { x = edX, y = wageY, w = edW, h = 30 * scale }

    local saveY = wageY + 40 * scale
    local saveW = 130 * scale
    hover = isMouseIn(edX, saveY, saveW, 32 * scale)
    dxDrawRoundedRect(edX, saveY, saveW, 32 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText(T.save, edX, saveY, edX + saveW, saveY + 32 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._rankSaveBtn = { x = edX, y = saveY, w = saveW, h = 32 * scale }
end

-- ============================================================
-- Vehicles section
-- ============================================================
local vehCols = {
    { name = "ID",      frac = 0.12 },
    { name = "\216\167\217\132\217\133\216\177\226\128\145\216\167\216\170", frac = 0.42 }, -- المركبة
    { name = "\216\167\217\132\217\132\217\136\216\173\216\169",  frac = 0.16 }, -- اللوحة
    { name = "\216\167\217\132\217\133\217\136\216\167\216\185",  frac = 0.30 }, -- الموقع
}

function drawVehicles()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local ids = F.data.vehicleIDs or {}
    local models = F.data.vehicleModels or {}
    local plates = F.data.vehiclePlates or {}
    local locs = F.data.vehicleLocations or {}

    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - 46 * scale

    local colX = cx
    for _, col in ipairs(vehCols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #ids - visibleRows) * rowH
    F.vehiclesScroll = math.min(F.vehiclesScroll, maxScroll)
    local startIdx = math.floor(F.vehiclesScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #ids) do
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(cx, rowY, cw - 14 * scale, rowH)
        local selected = F.vehiclesSelected == i
        if i % 2 == 0 then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 5), true)
        end
        if selected then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, THEME.primarySoft, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        elseif hover then
            dxDrawRectangle(cx, rowY, cw - 14 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end

        local cX2 = cx
        dxDrawText(tostring(ids[i]), cX2 + 8 * scale, rowY, cX2 + cw * 0.12, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.12
        local modelName = tostring(models[i] or "-")
        dxDrawText(truncate(modelName, cw * 0.42 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + cw * 0.42, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.42
        dxDrawText(tostring(plates[i] or "-"), cX2 + 8 * scale, rowY, cX2 + cw * 0.16, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        cX2 = cX2 + cw * 0.16
        dxDrawText(truncate(tostring(locs[i] or "-"), cw * 0.30 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + cw * 0.30, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)

        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.vehiclesScroll, maxScroll)
    end

    local btnY = cy + ch - 40 * scale
    local btnW, btnH = 140 * scale, 30 * scale
    local hover = isMouseIn(cx, btnY, btnW, btnH)
    dxDrawRoundedRect(cx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
    local iconSize = 16 * scale
    drawIcon("car", cx + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
        hover and THEME.primary or tocolor(255, 255, 255, 130))
    dxDrawText("\216\177\217\138\216\179\216\168\217\136\217\134 \217\133\216\177\226\128\145\216\167\216\169", cx + 28 * scale, btnY, cx + btnW, btnY + btnH,
        hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    F._vehRespawnBtn = { x = cx, y = btnY, w = btnW, h = btnH }

    local btn2X = cx + btnW + 8 * scale
    hover = isMouseIn(btn2X, btnY, btnW, btnH)
    dxDrawRoundedRect(btn2X, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
    drawIcon("car", btn2X + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
        hover and THEME.primary or tocolor(255, 255, 255, 130))
    dxDrawText("\216\177\217\138\216\179\216\168\217\136\217\134 \216\167\217\132\217\131\217\132", btn2X + 28 * scale, btnY, btn2X + btnW, btnY + btnH,
        hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    F._vehRespawnAllBtn = { x = btn2X, y = btnY, w = btnW, h = btnH }
end
