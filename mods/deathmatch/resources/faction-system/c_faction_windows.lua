-- ============================================================
-- Sub-windows
-- ============================================================
function drawPromoteWindow()
    if not F.sub.promote then return end
    local w, h = 400 * scale, 380 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRoundedRect(x, y, w, h, THEME.overlay, 8, true)
    dxDrawText("ترقية / خفض العضو", x, y + 12 * scale, x + w, y + 42 * scale,
        THEME.text, 1.1, "default-bold", "center", "center", true, false, true)

    local sel = F.members[F.membersSelected]
    if not sel then F.sub.promote = false return end
    dxDrawText("العضو: #E24848" .. sel.name, x, y + 44 * scale, x + w, y + 66 * scale,
        tocolor(255, 255, 255, 220), 1.0, "default", "center", "center", true, false, true)

    local listY = y + 70 * scale
    local listH = h - 70 * scale - 50 * scale
    local ranks = F.data.factionRanks or {}
    F._promoteRows = {}
    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #ranks - visibleRows) * rowH
    F.promoteScroll = math.min(F.promoteScroll, maxScroll)
    F.promoteScroll = math.max(0, F.promoteScroll)
    local startIdx = math.floor(F.promoteScroll / rowH) + 1
    -- ensure the member's current rank is visible
    if sel.rank then
        local curIdx = math.max(1, math.min(#ranks, sel.rank))
        if curIdx < startIdx then F.promoteScroll = (curIdx - 1) * rowH
        elseif curIdx > startIdx + visibleRows - 1 then F.promoteScroll = (curIdx - visibleRows) * rowH
        end
        startIdx = math.floor(F.promoteScroll / rowH) + 1
    end
    for i = startIdx, math.min(startIdx + visibleRows, #ranks) do
        local rowY = listY + (i - startIdx) * rowH
        local hover = isMouseIn(x + 10 * scale, rowY, w - 20 * scale, rowH)
        local isCurrent = sel.rank == i
        if isCurrent then
            dxDrawRectangle(x + 10 * scale, rowY, w - 20 * scale, rowH, THEME.primarySoft, true)
        elseif hover then
            dxDrawRectangle(x + 10 * scale, rowY, w - 20 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end
        dxDrawText("#" .. i .. "  " .. tostring(ranks[i] or ("Rank " .. i)), x + 20 * scale, rowY, x + w - 20 * scale, rowY + rowH,
            isCurrent and THEME.primary or THEME.text, 1.0, "default", "left", "center", true, false, true)
        F._promoteRows[i] = { x = x + 10 * scale, y = rowY, w = w - 20 * scale, h = rowH, rank = i }
    end

    if maxScroll > 0 then
        drawScrollbar(x + w - 14 * scale, listY, listH, F.promoteScroll, maxScroll)
    end

    local cY = y + h - 36 * scale
    local hover = isMouseIn(x + 10 * scale, cY, w - 20 * scale, 30 * scale)
    dxDrawRoundedRect(x + 10 * scale, cY, w - 20 * scale, 30 * scale, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
    dxDrawText("إغلاق", x + 10 * scale, cY, x + w - 10 * scale, cY + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
    F._promoteCancel = { x = x + 10 * scale, y = cY, w = w - 20 * scale, h = 30 * scale }
end

function drawAddMemberWindow()
    if not F.sub.addMember then return end
    local w, h = 300 * scale, 170 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRoundedRect(x, y, w, h, THEME.overlay, 8, true)
    dxDrawText("إضافة عضو", x, y + 12 * scale, x + w, y + 38 * scale,
        THEME.text, 1.1, "default-bold", "center", "center", true, false, true)

    local eY = y + 46 * scale
    local hover = isMouseIn(x + 15 * scale, eY, w - 30 * scale, 32 * scale)
    dxDrawRoundedRect(x + 15 * scale, eY, w - 30 * scale, 32 * scale, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawText(F.sub.addMemberText ~= "" and F.sub.addMemberText or T.nameph,
        x + 25 * scale, eY, x + w - 25 * scale, eY + 32 * scale,
        F.sub.addMemberText ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
    F._addMemberEdit = { x = x + 15 * scale, y = eY, w = w - 30 * scale, h = 32 * scale }

    dxDrawText(F.sub.addMemberResult, x + 15 * scale, eY + 36 * scale, x + w - 15 * scale, eY + 54 * scale,
        THEME.textDim, 0.9, "default", "center", "center", true, false, true)

    local bY = y + h - 42 * scale
    local bW = (w - 40 * scale) / 2
    hover = isMouseIn(x + 15 * scale, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + 15 * scale, bY, bW, 30 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText(T.add, x + 15 * scale, bY, x + 15 * scale + bW, bY + 30 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._addMemberOk = { x = x + 15 * scale, y = bY, w = bW, h = 30 * scale }

    hover = isMouseIn(x + 25 * scale + bW, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + 25 * scale + bW, bY, bW, 30 * scale, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
    dxDrawText(T.cancel, x + 25 * scale + bW, bY, x + w - 15 * scale, bY + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
    F._addMemberCancel = { x = x + 25 * scale + bW, y = bY, w = bW, h = 30 * scale }
end

function drawConfirmWindow()
    if not F.sub.confirm then return end
    local w, h = 360 * scale, 160 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRoundedRect(x, y, w, h, THEME.overlay, 8, true)
    dxDrawText(F.sub.confirmText, x + 15 * scale, y + 15 * scale, x + w - 15 * scale, y + h - 55 * scale,
        THEME.text, 1.0, "default", "center", "center", true, true, true)

    local bY = y + h - 42 * scale
    local bW = (w - 45 * scale) / 2
    local hover = isMouseIn(x + 15 * scale, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + 15 * scale, bY, bW, 30 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText("نعم", x + 15 * scale, bY, x + 15 * scale + bW, bY + 30 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._confirmYes = { x = x + 15 * scale, y = bY, w = bW, h = 30 * scale }

    hover = isMouseIn(x + 30 * scale + bW, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + 30 * scale + bW, bY, bW, 30 * scale, hover and THEME.btnBgHover or THEME.btnBg, 5, true)
    dxDrawText("لا", x + 30 * scale + bW, bY, x + w - 15 * scale, bY + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
    F._confirmNo = { x = x + 30 * scale + bW, y = bY, w = bW, h = 30 * scale }
end

function drawTextInputWindow()
    if not F.sub.textInput then return end
    local w, h = 400 * scale, 160 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRoundedRect(x, y, w, h, THEME.overlay, 8, true)

    dxDrawText(F.sub.textInputLabel, x, y + 12 * scale, x + w, y + 40 * scale,
        THEME.text, 1.1, "default-bold", "center", "center", true, false, true)

    local eY = y + 48 * scale
    local eH = 40 * scale
    local hover = isMouseIn(x + 20 * scale, eY, w - 40 * scale, eH)
    dxDrawRoundedRect(x + 20 * scale, eY, w - 40 * scale, eH, hover and THEME.inputBgHov or THEME.inputBg, 5, true)
    dxDrawRectangle(x + 20 * scale, eY + eH - 1, w - 40 * scale, 1, THEME.lineStrong, true)
    dxDrawText(F.sub.textInputText ~= "" and F.sub.textInputText or T.nameph,
        x + 30 * scale, eY, x + w - 30 * scale, eY + eH,
        F.sub.textInputText ~= "" and THEME.text or THEME.textFaint, 1.0, "default", "left", "center", true, false, true)
    F._textInputEdit = { x = x + 20 * scale, y = eY, w = w - 40 * scale, h = eH }

    local bW = 100 * scale
    local bY = y + h - 42 * scale
    local okHover = isMouseIn(x + 20 * scale, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + 20 * scale, bY, bW, 30 * scale, okHover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText(T.add, x + 20 * scale, bY, x + 20 * scale + bW, bY + 30 * scale,
        THEME.text, 1.0, "default-bold", "center", "center", true, false, true)
    F._textInputOk = { x = x + 20 * scale, y = bY, w = bW, h = 30 * scale }

    local cancelHover = isMouseIn(x + w - 20 * scale - bW, bY, bW, 30 * scale)
    dxDrawRoundedRect(x + w - 20 * scale - bW, bY, bW, 30 * scale, cancelHover and THEME.btnBgHover or THEME.btnBg, 5, true)
    dxDrawText(T.cancel, x + w - 20 * scale - bW, bY, x + w - 20 * scale, bY + 30 * scale,
        THEME.textDim, 1.0, "default-bold", "center", "center", true, false, true)
    F._textInputCancel = { x = x + w - 20 * scale - bW, y = bY, w = bW, h = 30 * scale }
end

function drawDutyPerksWindow()
    if not F.sub.dutyPerks then return end
    local w, h = 400 * scale, 350 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRoundedRect(x, y, w, h, THEME.overlay, 8, true)
    dxDrawText("حصص الديوتي للعضو", x, y + 12 * scale, x + w, y + 40 * scale,
        THEME.text, 1.1, "default-bold", "center", "center", true, false, true)

    local sel = F.members[F.membersSelected]
    if not sel then F.sub.dutyPerks = false return end

    local listY = y + 50 * scale
    local listH = h - 50 * scale - 50 * scale
    F._perkRows = {}
    local packages = F.dutyPackages or {}
    local ordered = {}
    for k, v in pairs(packages) do
        local name = (type(v) == "table" and (v[2] or v.name)) or tostring(v)
        local id = (type(v) == "table" and (v[1] or v.id)) or k
        table.insert(ordered, { name = name, id = tostring(id) })
    end
    table.sort(ordered, function(a, b) return a.name < b.name end)

    local visibleRows = math.floor(listH / rowH)
    local maxScroll = math.max(0, #ordered - visibleRows) * rowH
    F.perksScroll = math.min(F.perksScroll or 0, maxScroll)
    F.perksScroll = math.max(0, F.perksScroll)
    local startIdx = math.floor(F.perksScroll / rowH) + 1

    for i = startIdx, math.min(startIdx + visibleRows, #ordered) do
        local p = ordered[i]
        if not p then break end
        local rowY = listY + (i - startIdx) * rowH
        local checked = F.sub.dutyPerksSelected[p.id] == true
        local hover = isMouseIn(x + 10 * scale, rowY, w - 20 * scale, rowH)
        if checked then
            dxDrawRectangle(x + 10 * scale, rowY, w - 20 * scale, rowH, THEME.primarySoft, true)
        elseif hover then
            dxDrawRectangle(x + 10 * scale, rowY, w - 20 * scale, rowH, tocolor(255, 255, 255, 12), true)
        end
        -- checkbox box
        local cbSize = 16 * scale
        local cbX, cbY = x + 18 * scale, rowY + (rowH - cbSize) / 2
        dxDrawRoundedRect(cbX, cbY, cbSize, cbSize, checked and THEME.primary or tocolor(40, 44, 52, 255), 3, true)
        if checked then
            drawIcon("check", cbX + 2 * scale, cbY + 2 * scale, cbSize - 4 * scale, tocolor(255, 255, 255, 255))
        end
        dxDrawText(tostring(p.name), x + 42 * scale, rowY, x + w - 20 * scale, rowY + rowH,
            THEME.text, 1.0, "default", "left", "center", true, false, true)
        F._perkRows[i] = { x = x + 10 * scale, y = rowY, w = w - 20 * scale, h = rowH, id = p.id }
    end

    if maxScroll > 0 then
        drawScrollbar(x + w - 14 * scale, listY, listH, F.perksScroll, maxScroll)
    end

    local bY = y + h - 38 * scale
    local hover = isMouseIn(x + 10 * scale, bY, w - 20 * scale, 30 * scale)
    dxDrawRoundedRect(x + 10 * scale, bY, w - 20 * scale, 30 * scale, hover and tocolor(226, 72, 72, 220) or tocolor(226, 72, 72, 160), 5, true)
    dxDrawText("حفظ", x + 10 * scale, bY, x + w - 10 * scale, bY + 30 * scale,
        tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center", true, false, true)
    F._perkSave = { x = x + 10 * scale, y = bY, w = w - 20 * scale, h = 30 * scale }
end

-- ============================================================
-- Main render
-- ============================================================
function render()
    if not F.visible or not F.data then return end

    updateCursorCache()

    local x, y = winPos()

    -- main window background
    dxDrawRoundedRect(x, y, winW, winH, THEME.bg, 10, true)
    dxDrawRectangle(x, y + headerH, menuW, winH - headerH, THEME.sidebar, true)

    drawHeader()
    drawSidebar()

    -- content background
    local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
    dxDrawRoundedRect(cx - 5 * scale, cy - 5 * scale, cw + 10 * scale, ch + 10 * scale, THEME.bgSoft, 8, true)

    if F.section == "members" then drawMembers()
    elseif F.section == "ranks" then drawRanks()
    elseif F.section == "vehicles" then drawVehicles()
    elseif F.section == "finance" then drawFinance()
    elseif F.section == "logs" then drawLogs()
    elseif F.section == "note" then drawNote()
    elseif F.section == "duty" then drawDuty()
    end

    drawPromoteWindow()
    drawAddMemberWindow()
    drawDutyPerksWindow()
    drawConfirmWindow()
    drawTextInputWindow()
end
addEventHandler("onClientRender", root, render)
