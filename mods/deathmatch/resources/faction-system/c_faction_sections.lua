-- ============================================================
-- Members section
-- ============================================================
local memberCols = {
    { name = "الاسم",       frac = 0.30 },
    { name = "الرتبة",      frac = 0.22 },
    { name = "الحالة",      frac = 0.11 },
    { name = "آخر دخول",    frac = 0.15 },
    { name = "الراتب",      frac = 0.10 },
    { name = "الديوتي",     frac = 0.12 },
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
    F.membersScroll = math.max(0, F.membersScroll)
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

    -- action buttons
    if F.isLeader then
        local btnY = cy + ch - 40 * scale
        local btnH = 30 * scale
        local gap = 5 * scale
        local buttons = {
            { id = "kick",    label = T.kick,      w = 100, icon = "close" },
            { id = "promote", label = T.promote,   w = 120, icon = "star" },
            { id = "perks",   label = T.perks,     w = 120, icon = "box" },
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
        -- add member button
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
        -- online/offline legend
        local legendW = 200 * scale
        if bx + legendW <= cx + cw then
            dxDrawText("#00FF00• #FFFFFF" .. T.online .. "   #FF0000• #FFFFFF" .. T.offline,
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

    dxDrawText("الرتب (1 - 20)", cx + 8 * scale, cy, cx + listW, cy + headerH2,
        THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    dxDrawText("الراتب", cx + listW * 0.65, cy, cx + listW, cy + headerH2,
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
            dxDrawRectangle(cx, rowY, listW, rowH, THEME.rowSelected, true)
            dxDrawRectangle(cx, rowY, 3, rowH, THEME.primary, true)
        elseif hover then
            dxDrawRectangle(cx, rowY, listW, rowH, THEME.rowHover, true)
        end
        dxDrawText("#" .. i .. "  " .. tostring(rankName), cx + 10 * scale, rowY, cx + listW * 0.65, rowY + rowH,
            selected and THEME.text or THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawText("$" .. formatMoney(wage), cx + listW * 0.65, rowY, cx + listW, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)
        dxDrawRectangle(cx, rowY + rowH - 1, listW, 1, THEME.line, true)
        F._rankRows[i] = { x = cx, y = rowY, w = listW, h = rowH, idx = i }
    end

    if maxScroll > 0 then
        drawScrollbar(cx + listW - 12 * scale, listY, listH, F.ranksScroll, maxScroll)
    end

    -- editor (right side)
    if F.isLeader and F.ranksSelected > 0 then
        local eX = cx + listW + 15 * scale
        local eW = cw - listW - 15 * scale
        dxDrawText("تعديل الرتبة #" .. F.ranksSelected, eX, cy, eX + eW, cy + 24 * scale,
            THEME.text, 1.0, "default-bold", "left", "center", true, false, true)

        local nY = cy + 34 * scale
        dxDrawText("الاسم", eX, nY, eX + eW, nY + 18 * scale,
            THEME.textDim, 0.9, "default", "left", "center", true, false, true)
        local neY = nY + 22 * scale
        local nHover = isMouseIn(eX, neY, eW, 30 * scale)
        dxDrawRoundedRect(eX, neY, eW, 30 * scale, nHover and THEME.inputBgHov or THEME.inputBg, 5, true)
        dxDrawRectangle(eX, neY + 29 * scale, eW, 1, THEME.lineStrong, true)
        local curName = ranks[F.ranksSelected] or ""
        local dispName = F.rankNameBuffer ~= "" and F.rankNameBuffer or curName
        dxDrawText(dispName, eX + 10 * scale, neY, eX + eW - 10 * scale, neY + 30 * scale,
            F.rankNameBuffer ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
        F._rankNameEdit = { x = eX, y = neY, w = eW, h = 30 * scale }

        local wY = neY + 42 * scale
        dxDrawText("الراتب (الحد 2500)", eX, wY, eX + eW, wY + 18 * scale,
            THEME.textDim, 0.9, "default", "left", "center", true, false, true)
        local weY = wY + 22 * scale
        local wHover = isMouseIn(eX, weY, eW, 30 * scale)
        dxDrawRoundedRect(eX, weY, eW, 30 * scale, wHover and THEME.inputBgHov or THEME.inputBg, 5, true)
        dxDrawRectangle(eX, weY + 29 * scale, eW, 1, THEME.lineStrong, true)
        local curWage = wages[F.ranksSelected] or 0
        local dispWage = F.rankWageBuffer ~= "" and F.rankWageBuffer or tostring(curWage)
        dxDrawText(dispWage, eX + 10 * scale, weY, eX + eW - 10 * scale, weY + 30 * scale,
            F.rankWageBuffer ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
        F._rankWageEdit = { x = eX, y = weY, w = eW, h = 30 * scale }

        local sY = weY + 44 * scale
        local sW = 130 * scale
        local sHover = isMouseIn(eX, sY, sW, 32 * scale)
        dxDrawRoundedRect(eX, sY, sW, 32 * scale, sHover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
        dxDrawText(T.save, eX, sY, eX + sW, sY + 32 * scale,
            tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
        F._rankSaveBtn = { x = eX, y = sY, w = sW, h = 32 * scale }
    end
end

-- ============================================================
-- Vehicles section
-- ============================================================
local vehCols = {
    { name = "المركبة",  frac = 0.45 },
    { name = "اللوحة",   frac = 0.25 },
    { name = "الموقع",   frac = 0.30 },
}

function drawVehicles()
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    local btnSpace = F.isLeader and 46 * scale or 10 * scale
    local listY = cy + 34 * scale
    local listH = ch - 34 * scale - btnSpace

    local colX = cx
    for _, col in ipairs(vehCols) do
        local colW = cw * col.frac
        dxDrawText(col.name, colX + 8 * scale, cy, colX + colW, cy + 30 * scale,
            THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
        colX = colX + colW
    end
    dxDrawRectangle(cx, cy + 30 * scale, cw, 1, THEME.lineStrong, true)

    local vids = F.data.vehicleIDs or {}
    local vmodels = F.data.vehicleModels or {}
    local vplates = F.data.vehiclePlates or {}
    local vlocs = F.data.vehicleLocations or {}
    local count = #vids

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, count - visibleRows) * rowH
    F.vehiclesScroll = math.min(F.vehiclesScroll, maxScroll)
    F.vehiclesScroll = math.max(0, F.vehiclesScroll)
    local startIdx = math.floor(F.vehiclesScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, count) do
        local vid = vids[i]
        if not vid then break end
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

        local model = vmodels[i] or 0
        local vehName = getVehicleNameFromModel(tonumber(model) or 0) or tostring(model)
        local cX2, colW2 = cx, cw * vehCols[1].frac
        dxDrawText(tostring(vehName), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * vehCols[2].frac
        dxDrawText(tostring(vplates[i] or "-"), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)

        cX2 = cX2 + colW2; colW2 = cw * vehCols[3].frac
        dxDrawText(truncate(tostring(vlocs[i] or "-"), colW2 - 16 * scale, "default"), cX2 + 8 * scale, rowY, cX2 + colW2, rowY + rowH,
            THEME.textDim, 1.0, "default", "left", "center", true, false, true)

        dxDrawRectangle(cx, rowY + rowH - 1, cw - 14 * scale, 1, THEME.line, true)
    end

    if maxScroll > 0 then
        drawScrollbar(cx + cw - 12 * scale, listY, listH, F.vehiclesScroll, maxScroll)
    end

    if F.isLeader then
        local btnY = cy + ch - 40 * scale
        local btnW, btnH = 150 * scale, 30 * scale
        F._vehRespawnBtn = { x = cx, y = btnY, w = btnW, h = btnH }
        local hover = isMouseIn(cx, btnY, btnW, btnH)
        dxDrawRoundedRect(cx, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        local iconSize = 16 * scale
        drawIcon("car", cx + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
            hover and THEME.primary or tocolor(255, 255, 255, 130))
        dxDrawText("رسبنة سيارة", cx + 28 * scale, btnY, cx + btnW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)

        local allX = cx + btnW + 8 * scale
        F._vehRespawnAllBtn = { x = allX, y = btnY, w = btnW, h = btnH }
        hover = isMouseIn(allX, btnY, btnW, btnH)
        dxDrawRoundedRect(allX, btnY, btnW, btnH, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
        drawIcon("car", allX + 8 * scale, btnY + (btnH - iconSize) / 2, iconSize,
            hover and THEME.primary or tocolor(255, 255, 255, 130))
        dxDrawText("رسبنة الكل", allX + 28 * scale, btnY, allX + btnW, btnY + btnH,
            hover and THEME.primary or THEME.textDim, 1.0, "default-bold", "left", "center", true, false, true)
    end
end
