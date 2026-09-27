-- ============================================================
-- Click handling - drives all faction actions
-- ============================================================
local selMsg = "ارجوك اختر عضوا اولا"

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if button ~= "left" or state ~= "down" then return end
    if not F.visible then return end
    local px, py = absoluteX, absoluteY

    -- edit box focus selector (runs first, sets activeEdit)
    activeEdit = nil
    if F.section == "ranks" then
        if pointInBox(px, py, F._rankNameEdit) then activeEdit = "rankName" return
        elseif pointInBox(px, py, F._rankWageEdit) then activeEdit = "rankWage" return end
    elseif F.section == "note" then
        if pointInBox(px, py, F._motdEdit) then activeEdit = "motd" return
        elseif pointInBox(px, py, F._noteEdit) then activeEdit = "note" return end
    end
    if F.sub.addMember and pointInBox(px, py, F._addMemberEdit) then activeEdit = "addMember" return
    end
    if F.sub.textInput and pointInBox(px, py, F._textInputEdit) then activeEdit = "textInput" return
    end

    -- close button
    if pointInBox(px, py, F._closeBtn) then
        triggerEvent("hideFactionMenu", localPlayer)
        return
    end
    -- more button (change faction)
    if pointInBox(px, py, F._moreBtn) then
        outputChatBox("منطقة الإدارة: إغلاق الفاكشن", 255, 194, 14)
        return
    end

    -- text input window
    if F.sub.textInput then
        if pointInBox(px, py, F._textInputCancel) then
            closeTextInput()
            return
        end
        if pointInBox(px, py, F._textInputOk) then
            local text = F.sub.textInputText
            local cb = F.sub.textInputCallback
            if text ~= "" and cb then
                closeTextInput()
                cb(text)
            end
            return
        end
        return
    end

    -- confirm dialog has priority
    if F.sub.confirm then
        if pointInBox(px, py, F._confirmYes) then
            local action = F.sub.confirmAction
            F.sub.confirm = false
            F.sub.confirmAction = nil
            if action then action() end
            return
        elseif pointInBox(px, py, F._confirmNo) then
            F.sub.confirm = false
            F.sub.confirmAction = nil
            return
        end
        return
    end

    -- promote window
    if F.sub.promote then
        if pointInBox(px, py, F._promoteCancel) then
            F.sub.promote = false
            return
        end
        if F._promoteRows then
            for _, r in pairs(F._promoteRows) do
                if pointInBox(px, py, r) then
                    local sel = F.members[F.membersSelected]
                    if sel then
                        local oldRank, newRank = sel.rank, r.rank
                        local ranksList = F.data.factionRanks or {}
                        if newRank > oldRank then
                            logAction("ترقية " .. sel.name .. " إلى #" .. newRank)
                            triggerServerEvent("cguiPromotePlayer", localPlayer, sel.rawName, newRank,
                                tostring(ranksList[oldRank] or ""), tostring(ranksList[newRank] or ""))
                        else
                            logAction("خفض " .. sel.name .. " إلى #" .. newRank)
                            triggerServerEvent("cguiDemotePlayer", localPlayer, sel.rawName, newRank,
                                tostring(ranksList[oldRank] or ""), tostring(ranksList[newRank] or ""))
                        end
                        F.sub.promote = false
                        triggerEvent("hideFactionMenu", localPlayer)
                    end
                    return
                end
            end
        end
        return
    end

    -- add member window
    if F.sub.addMember then
        if pointInBox(px, py, F._addMemberCancel) then
            F.sub.addMember = false
            F.sub.addMemberText = ""
            F.sub.addMemberResult = ""
            return
        end
        if pointInBox(px, py, F._addMemberOk) then
            local text = F.sub.addMemberText:gsub(" ", "_")
            if text ~= "" then
                local found = getPlayerFromName(text)
                if found then
                    logAction("إضافة العضو " .. F.sub.addMemberText)
                    triggerServerEvent("cguiInvitePlayer", localPlayer, found)
                    F.sub.addMember = false
                    F.sub.addMemberText = ""
                    F.sub.addMemberResult = ""
                    triggerEvent("hideFactionMenu", localPlayer)
                else
                    F.sub.addMemberResult = "اللاعب غير متصل"
                end
            end
            return
        end
        return
    end

    -- duty perks window
    if F.sub.dutyPerks then
        if pointInBox(px, py, F._perkSave) then
            local sel = F.members[F.membersSelected]
            if sel then
                local perkTable = {}
                for id, v in pairs(F.sub.dutyPerksSelected) do
                    if v then perkTable[id] = true end
                end
                triggerServerEvent("faction:perks:edit", localPlayer, perkTable, sel.rawName)
                logAction("تعديل صلاحيات ديوتي " .. sel.name)
            end
            F.sub.dutyPerks = false
            F.sub.dutyPerksSelected = {}
            triggerEvent("hideFactionMenu", localPlayer)
            return
        end
        if F._perkRows then
            for _, r in pairs(F._perkRows) do
                if pointInBox(px, py, r) then
                    F.sub.dutyPerksSelected[r.id] = not F.sub.dutyPerksSelected[r.id]
                    return
                end
            end
        end
        return
    end

    -- sidebar menu
    local x, y = winPos()
    local itemH = 34 * scale
    local startY = y + headerH + 15 * scale
    for i, item in ipairs(F.menu) do
        local itemY = startY + (i - 1) * itemH
        if px >= x + 10 * scale and px <= x + menuW and py >= itemY and py <= itemY + itemH then
            F.section = item.id
            if item.id == "duty" then
                if not customg or not next(customg or {}) then
                    fetchDutyInfo()
                end
            elseif item.id == "finance" then
                loadFinance()
            elseif item.id == "logs" then
                loadFinance()
            end
            return
        end
    end

    -- member list row selection
    if F.section == "members" then
        local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
        local btnSpace = F.isLeader and 46 * scale or 10 * scale
        local listY = cy + 34 * scale
        local listH = ch - 34 * scale - btnSpace
        if py >= listY and py <= listY + listH and px >= cx and px <= cx + cw - 14 * scale then
            local startIdx = math.floor(F.membersScroll / rowH) + 1
            local idx = startIdx + math.floor((py - listY) / rowH)
            if idx >= 1 and idx <= #F.members then
                F.membersSelected = idx
            end
            return
        end
    end

    -- member action buttons
    if F.section == "members" and F.isLeader and F._actionButtons then
        local sel = F.members[F.membersSelected]
        for id, box in pairs(F._actionButtons) do
            if pointInBox(px, py, box) then
                if id == "kick" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.confirmText = "هل متأكد من طرد " .. sel.name .. "؟"
                    F.sub.confirmAction = function()
                        logAction("طرد العضو " .. sel.name)
                        triggerServerEvent("cguiKickPlayer", localPlayer, sel.rawName)
                        triggerEvent("hideFactionMenu", localPlayer)
                    end
                    F.sub.confirm = true
                elseif id == "promote" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.promote = true
                    F.promoteScroll = 0
                elseif id == "leader" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.confirmText = sel.leader and "خفض " .. sel.name .. " من القادة" or "ترقية " .. sel.name .. " إلى قائد؟"
                    F.sub.confirmAction = function()
                        logAction(sel.leader and ("خفض " .. sel.name .. " من القادة") or ("تعيين " .. sel.name .. " قائداً"))
                        triggerServerEvent("cguiToggleLeader", localPlayer, sel.rawName, not sel.leader)
                        triggerEvent("hideFactionMenu", localPlayer)
                    end
                    F.sub.confirm = true
                elseif id == "add" then
                    F.sub.addMember = true
                    F.sub.addMemberText = ""
                    F.sub.addMemberResult = ""
                    activeEdit = "addMember"
                elseif id == "perks" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.dutyPerks = true
                    F.perksScroll = 0
                    F.sub.dutyPerksSelected = {}
                    if sel.perks then
                        for k, v in pairs(sel.perks) do
                            if v then F.sub.dutyPerksSelected[tostring(k)] = true end
                        end
                    end
                    triggerServerEvent("Duty:GetPackages", resourceRoot, F.factionID)
                elseif id == "respawn" then
                    F.sub.confirmText = "هل متأكد من رسبنة مجموعة سيارات؟"
                    F.sub.confirmAction = function()
                        logAction("رسبنة جميع مركبات الفاكشن")
                        triggerServerEvent("cguiRespawnVehicles", localPlayer)
                        triggerEvent("hideFactionMenu", localPlayer)
                    end
                    F.sub.confirm = true
                end
                return
            end
        end
    end

    -- ranks section
    if F.section == "ranks" and F.isLeader then
        local cx, cy, cw = contentX(), contentY(), contentW()
        local listW = cw * 0.5 - 5 * scale
        local headerH2 = 30 * scale
        local listY = cy + headerH2 + 5 * scale
        if F._rankRows then
            for _, r in pairs(F._rankRows) do
                if pointInBox(px, py, r) then
                    F.ranksSelected = r.idx
                    F.rankNameBuffer = ""
                    F.rankWageBuffer = ""
                    activeEdit = nil
                    return
                end
            end
        end
        if pointInBox(px, py, F._rankSaveBtn) then
            local ranks = F.data.factionRanks or {}
            local wages = F.data.factionWages or {}
            if F.ranksSelected > 0 then
                if F.rankNameBuffer ~= "" then
                    ranks[F.ranksSelected] = F.rankNameBuffer
                end
                local w = tonumber(F.rankWageBuffer)
                if w then
                    wages[F.ranksSelected] = math.min(2500, math.max(0, w))
                end
                triggerServerEvent("cguiUpdateRanks", localPlayer, ranks, wages)
                logAction("تعديل الرتبة #" .. F.ranksSelected)
                F.rankNameBuffer = ""
                F.rankWageBuffer = ""
                activeEdit = nil
                triggerEvent("hideFactionMenu", localPlayer)
            end
            return
        end
    end

    -- vehicles section
    if F.section == "vehicles" and F.isLeader then
        if pointInBox(px, py, F._vehRespawnBtn) then
            if F.vehiclesSelected > 0 and F.data.vehicleIDs and F.data.vehicleIDs[F.vehiclesSelected] then
                logAction("رسبنة مركبة #" .. tostring(F.data.vehicleIDs[F.vehiclesSelected]))
                triggerServerEvent("cguiRespawnOneVehicle", localPlayer, tostring(F.data.vehicleIDs[F.vehiclesSelected]))
            else
                outputChatBox("ارجوك اختر سيارة من رسبنة سيارات", 255, 0, 0)
            end
            return
        end
        if pointInBox(px, py, F._vehRespawnAllBtn) then
            F.sub.confirmText = "هل متأكد من رسبنة جميع السيارات؟"
            F.sub.confirmAction = function()
                logAction("رسبنة جميع مركبات الفاكشن")
                triggerServerEvent("cguiRespawnVehicles", localPlayer)
                triggerEvent("hideFactionMenu", localPlayer)
            end
            F.sub.confirm = true
            return
        end
        local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
        local listY = cy + 34 * scale
        local listH = ch - 34 * scale - 46 * scale
        if py >= listY and py <= listY + listH and px >= cx and px <= cx + cw - 14 * scale then
            local startIdx = math.floor(F.vehiclesScroll / rowH) + 1
            local idx = startIdx + math.floor((py - listY) / rowH)
            if idx >= 1 and idx <= #(F.data.vehicleIDs or {}) then
                F.vehiclesSelected = idx
            end
        end
    end

    -- finance section
    if F.section == "finance" and F._finRefreshBtn then
        if pointInBox(px, py, F._finRefreshBtn) then
            F.financeLoaded = false
            F.finance = nil
            loadFinance()
            return
        end
    end

    -- note section
    if F.section == "note" and F.isLeader then
        if pointInBox(px, py, F._motdSaveBtn) then
            triggerServerEvent("cguiUpdateMOTD", localPlayer, F.motdBuffer)
            triggerEvent("hideFactionMenu", localPlayer)
            return
        end
        if pointInBox(px, py, F._noteSaveBtn) then
            triggerServerEvent("faction:note", localPlayer, F.noteBuffer)
            triggerEvent("hideFactionMenu", localPlayer)
            return
        end
        if pointInBox(px, py, F._quitBtn) then
            F.sub.confirmText = "هل متأكد من مغادرة الفاكشن؟"
            F.sub.confirmAction = function()
                triggerServerEvent("cguiQuitFaction", localPlayer)
                triggerEvent("hideFactionMenu", localPlayer)
            end
            F.sub.confirm = true
            return
        end
    end

    -- duty section
    if F.section == "duty" and F.isLeader then
        -- sub-tabs
        if F._dutyTabs then
            for _, t in ipairs(F._dutyTabs) do
                if pointInBox(px, py, t) then
                    F.dutyTab = t.id
                    F.dutySelPkg = nil
                    F.dutySelLoc = nil
                    return
                end
            end
        end

        -- package buttons
        if F.dutyTab == "packages" and F._dutyBtns then
            if pointInBox(px, py, F._dutyBtns[1]) then
                openTextInput("اسم الديوتي الجديد", function(name)
                    logAction("إضافة ديوتي: " .. name)
                    triggerServerEvent("Duty:AddDuty", resourceRoot, {}, {}, {}, name, F.factionID, 0)
                end)
                return
            end
            if pointInBox(px, py, F._dutyBtns[2]) then
                if F.dutySelPkg then
                    logAction("حذف ديوتي #" .. tostring(F.dutySelPkg))
                    triggerServerEvent("Duty:RemoveDuty", resourceRoot, tonumber(F.dutySelPkg) or F.dutySelPkg, F.factionID)
                    F.dutySelPkg = nil
                else
                    outputChatBox(T.selduty, 255, 194, 14)
                end
                return
            end
        end

        -- location buttons
        if F.dutyTab == "locations" and F._dlBtns then
            if pointInBox(px, py, F._dlBtns[1]) then
                openTextInput("اسم الموقع الجديد", function(name)
                    local x, y, z = getElementPosition(localPlayer)
                    local r = 10
                    local i = getElementInterior(localPlayer)
                    local d = getElementDimension(localPlayer)
                    logAction("إضافة موقع ديوتي: " .. name)
                    triggerServerEvent("Duty:AddLocation", resourceRoot, x, y, z, r, i, d, name, F.factionID, nil)
                end)
                return
            end
            if pointInBox(px, py, F._dlBtns[2]) then
                if F.dutySelLoc then
                    logAction("حذف موقع ديوتي #" .. tostring(F.dutySelLoc))
                    triggerServerEvent("Duty:RemoveLocation", resourceRoot, tonumber(F.dutySelLoc) or F.dutySelLoc, F.factionID)
                    F.dutySelLoc = nil
                else
                    outputChatBox(T.selduty, 255, 194, 14)
                end
                return
            end
        end

        -- vehicle buttons
        if F.dutyTab == "vehicles" and F._dvBtns then
            if pointInBox(px, py, F._dvBtns[1]) then
                openTextInput("رقم المركبة (ID)", function(text)
                    local vid = tonumber(text)
                    if vid then
                        logAction("إضافة مركبة ديوتي #" .. vid)
                        triggerServerEvent("Duty:AddVehicle", resourceRoot, vid, F.factionID)
                    else
                        outputChatBox(T.selduty, 255, 0, 0)
                    end
                end)
                return
            end
            if pointInBox(px, py, F._dvBtns[2]) then
                if F.dutySelLoc then
                    logAction("حذف مركبة ديوتي #" .. tostring(F.dutySelLoc))
                    triggerServerEvent("Duty:RemoveLocation", resourceRoot, tonumber(F.dutySelLoc) or F.dutySelLoc, F.factionID)
                    F.dutySelLoc = nil
                else
                    outputChatBox(T.selduty, 255, 194, 14)
                end
                return
            end
        end

        -- row selection
        local cx, cy, cw, ch = contentX(), contentY(), contentW(), contentH()
        local tabH = 28 * scale
        local bodyY = cy + tabH + 8 * scale
        local bodyH = ch - tabH - 8 * scale
        local listY = bodyY + 34 * scale
        local listH = bodyH - 34 * scale - 46 * scale
        if py >= listY and py <= listY + listH and px >= cx and px <= cx + cw - 14 * scale then
            local scroll = F.dutyTab == "packages" and F.dutyScroll or (F.dutyTab == "locations" and F.dutyLocationsScroll or F.dutyVehiclesScroll)
            local startIdx = math.floor(scroll / rowH) + 1
            local idx = startIdx + math.floor((py - listY) / rowH)
            local rows = F.dutyTab == "packages" and dutyRows.packages or (F.dutyTab == "locations" and dutyRows.locations or dutyRows.vehicles)
            if rows and rows[idx] then
                if F.dutyTab == "packages" then
                    F.dutySelPkg = rows[idx].id
                else
                    F.dutySelLoc = rows[idx][1]
                end
            end
            return
        end
    end
end)

-- ============================================================
-- Scroll wheel
-- ============================================================
local function handleScrollwheel(key)
    if not F.visible or not F.data then return end
    local step = rowH
    if key == "mouse_wheel_up" then
        if F.sub.promote then F.promoteScroll = math.max(0, F.promoteScroll - step)
        elseif F.sub.dutyPerks then F.perksScroll = math.max(0, (F.perksScroll or 0) - step)
        elseif F.section == "members" then F.membersScroll = math.max(0, F.membersScroll - step)
        elseif F.section == "ranks" then F.ranksScroll = math.max(0, F.ranksScroll - step)
        elseif F.section == "vehicles" then F.vehiclesScroll = math.max(0, F.vehiclesScroll - step)
        elseif F.section == "finance" then F.financeScroll = math.max(0, F.financeScroll - step)
        elseif F.section == "logs" then F.logsScroll = math.max(0, F.logsScroll - step)
        elseif F.section == "duty" then
            if F.dutyTab == "packages" then F.dutyScroll = math.max(0, F.dutyScroll - step)
            elseif F.dutyTab == "locations" then F.dutyLocationsScroll = math.max(0, F.dutyLocationsScroll - step)
            elseif F.dutyTab == "vehicles" then F.dutyVehiclesScroll = math.max(0, F.dutyVehiclesScroll - step)
            end
        end
    elseif key == "mouse_wheel_down" then
        if F.sub.promote then F.promoteScroll = F.promoteScroll + step
        elseif F.sub.dutyPerks then F.perksScroll = (F.perksScroll or 0) + step
        elseif F.section == "members" then F.membersScroll = F.membersScroll + step
        elseif F.section == "ranks" then F.ranksScroll = F.ranksScroll + step
        elseif F.section == "vehicles" then F.vehiclesScroll = F.vehiclesScroll + step
        elseif F.section == "finance" then F.financeScroll = F.financeScroll + step
        elseif F.section == "logs" then F.logsScroll = F.logsScroll + step
        elseif F.section == "duty" then
            if F.dutyTab == "packages" then F.dutyScroll = F.dutyScroll + step
            elseif F.dutyTab == "locations" then F.dutyLocationsScroll = F.dutyLocationsScroll + step
            elseif F.dutyTab == "vehicles" then F.dutyVehiclesScroll = F.dutyVehiclesScroll + step
            end
        end
    end
end
bindKey("mouse_wheel_up", "both", function() handleScrollwheel("mouse_wheel_up") end)
bindKey("mouse_wheel_down", "both", function() handleScrollwheel("mouse_wheel_down") end)

-- ============================================================
-- Text input
-- ============================================================
activeEdit = nil

addEventHandler("onClientKey", root, function(button, press)
    if not press then return end
    if not F.visible then return end
    if not activeEdit then return end

    if button == "backspace" then
        cancelEvent()
        if activeEdit == "rankName" then F.rankNameBuffer = string.sub(F.rankNameBuffer, 1, -2)
        elseif activeEdit == "rankWage" then F.rankWageBuffer = string.sub(F.rankWageBuffer, 1, -2)
        elseif activeEdit == "motd" then F.motdBuffer = string.sub(F.motdBuffer, 1, -2)
        elseif activeEdit == "note" then F.noteBuffer = string.sub(F.noteBuffer, 1, -2)
        elseif activeEdit == "addMember" then F.sub.addMemberText = string.sub(F.sub.addMemberText, 1, -2)
        elseif activeEdit == "textInput" then F.sub.textInputText = string.sub(F.sub.textInputText, 1, -2)
        end
    elseif button == "escape" then
        cancelEvent()
        activeEdit = nil
    end
end)

addEventHandler("onClientCharacter", root, function(char)
    if not F.visible or not activeEdit then return end
    if #char == 0 then return end
    local c = char:byte(1)
    if c < 32 then return end
    cancelEvent()
    if activeEdit == "rankName" then F.rankNameBuffer = F.rankNameBuffer .. char
    elseif activeEdit == "rankWage" then
        if tonumber(char) then F.rankWageBuffer = F.rankWageBuffer .. char end
    elseif activeEdit == "motd" then F.motdBuffer = F.motdBuffer .. char
    elseif activeEdit == "note" then F.noteBuffer = F.noteBuffer .. char
    elseif activeEdit == "addMember" then
        F.sub.addMemberText = F.sub.addMemberText .. char
        F.sub.addMemberResult = ""
    elseif activeEdit == "textInput" then
        F.sub.textInputText = F.sub.textInputText .. char
    end
end)

-- ============================================================
-- Cleanup
-- ============================================================
addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
end)
