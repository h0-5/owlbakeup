-- ============================================================
-- Click handling - drives all faction actions
-- ============================================================
local selMsg = "\216\167\216\177\216\172\217\136\216\168 \216\167\216\174\216\174\216\177 \216\185\217\132\217\138\216\167 \216\185\216\182\217\136 \216\163\217\136\217\132\216\167"

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if button ~= "left" or state ~= "down" then return end
    if not F.visible then return end
    local px, py = absoluteX, absoluteY

    -- edit box focus selector (runs first, sets activeEdit)
    activeEdit = nil
    if F.section == "ranks" then
        if pointInBox(px, py, F._rankNameEdit) then activeEdit = "rankName" return
        elseif pointInBox(px, py, F._rankWageEdit) then activeEdit = "rankWage" return end
    elseif F.section == "management" then
        if pointInBox(px, py, F._motdEdit) then activeEdit = "motd" return end
    elseif F.section == "note" then
        if pointInBox(px, py, F._noteEdit) then activeEdit = "note" return end
    end
    if F.sub.addMember and pointInBox(px, py, F._addMemberEdit) then activeEdit = "addMember" return
    end

    -- close button
    if pointInBox(px, py, F._closeBtn) then
        triggerEvent("hideFactionMenu", localPlayer)
        return
    end
    -- more button (change faction)
    if pointInBox(px, py, F._moreBtn) then
        outputChatBox("\217\133\217\134\216\167\216\184\217\136\216\185 \216\167\217\132\216\165\216\175\216\167\216\177\216\169: \216\165\217\132\216\186\216\167\216\161 \216\167\217\132\217\129\216\167\216\170\217\138\217\134", 255, 194, 14)
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
                            triggerServerEvent("cguiPromotePlayer", localPlayer, sel.rawName, newRank,
                                tostring(ranksList[oldRank] or ""), tostring(ranksList[newRank] or ""))
                        else
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
                    triggerServerEvent("cguiInvitePlayer", localPlayer, found)
                    F.sub.addMember = false
                    F.sub.addMemberText = ""
                    F.sub.addMemberResult = ""
                    triggerEvent("hideFactionMenu", localPlayer)
                else
                    F.sub.addMemberResult = "\216\167\217\132\217\132\216\167\216\168\216\168 \216\186\217\138\216\177 \217\133\216\170\216\181\217\132"
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
            if item.id == "duty" or item.id == "dutylocations" or item.id == "dutyvehicles" then
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
                    F.sub.confirmText = "\217\132\216\167 \216\163\217\134\216\170 \217\133\216\170\216\163\217\131\216\175 \217\133\217\134 \216\183\216\177\216\175 " .. sel.name .. "\216\159"
                    F.sub.confirmAction = function()
                        triggerServerEvent("cguiKickPlayer", localPlayer, sel.rawName)
                        triggerEvent("hideFactionMenu", localPlayer)
                    end
                    F.sub.confirm = true
                elseif id == "promote" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.promote = true
                elseif id == "leader" then
                    if not sel then outputChatBox(selMsg, 255, 0, 0) return end
                    F.sub.confirmText = sel.leader and "\216\174\217\129\216\182 " .. sel.name .. " \217\133\217\134 \216\167\217\132\217\130\217\138\216\167\216\175\216\159" or "\216\170\216\177\217\130\217\138\216\169 " .. sel.name .. " \216\165\217\132\217\137 \217\130\216\167\216\166\216\175\216\159"
                    F.sub.confirmAction = function()
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
                    F.sub.dutyPerksSelected = {}
                    if sel.perks then
                        for k, v in pairs(sel.perks) do
                            if v then F.sub.dutyPerksSelected[tostring(k)] = true end
                        end
                    end
                    triggerServerEvent("Duty:GetPackages", resourceRoot, F.factionID)
                elseif id == "respawn" then
                    F.sub.confirmText = "\217\132\216\167 \216\163\217\134\216\170 \217\133\216\170\216\163\217\131\216\175 \217\133\217\134 \216\177\217\138\216\179\216\168\217\136\217\134 \216\172\217\133\217\138\216\185 \217\133\216\177\226\128\145\216\167\216\170\216\159"
                    F.sub.confirmAction = function()
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
                triggerServerEvent("cguiRespawnOneVehicle", localPlayer, tostring(F.data.vehicleIDs[F.vehiclesSelected]))
            else
                outputChatBox("\216\167\216\177\216\172\217\136\216\168 \216\167\216\174\216\174\216\177 \217\133\216\177\226\128\145\216\167\216\169 \217\133\217\134 \216\177\217\138\216\179\216\168\217\136\217\134", 255, 0, 0)
            end
            return
        end
        if pointInBox(px, py, F._vehRespawnAllBtn) then
            F.sub.confirmText = "\217\132\216\167 \216\163\217\134\216\170 \217\133\216\170\216\163\217\131\216\175 \217\133\217\134 \216\177\217\138\216\179\216\168\217\136\217\134 \216\172\217\133\217\138\216\185 \217\133\216\177\226\128\145\216\167\216\170\216\159"
            F.sub.confirmAction = function()
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

    -- management section
    if F.section == "management" and F.isLeader then
        if pointInBox(px, py, F._motdSaveBtn) then
            triggerServerEvent("cguiUpdateMOTD", localPlayer, F.motdBuffer)
            triggerEvent("hideFactionMenu", localPlayer)
            return
        end
        if pointInBox(px, py, F._quitBtn) then
            F.sub.confirmText = "\217\132\216\167 \216\163\217\134\216\170 \217\133\216\170\216\163\217\131\216\175 \217\133\217\134 \217\133\216\186\216\167\216\175\216\169 \217\129\216\167\216\170\217\138\217\134\216\159"
            F.sub.confirmAction = function()
                triggerServerEvent("cguiQuitFaction", localPlayer)
                triggerEvent("hideFactionMenu", localPlayer)
            end
            F.sub.confirm = true
            return
        end
    end

    -- note section
    if F.section == "note" and F.isLeader then
        if pointInBox(px, py, F._noteSaveBtn) then
            triggerServerEvent("faction:note", localPlayer, F.noteBuffer)
            triggerEvent("hideFactionMenu", localPlayer)
            return
        end
    end

    -- duty buttons
    if F.section == "duty" and F._dutyBtns then
        if pointInBox(px, py, F._dutyBtns[1]) then
            outputChatBox("\217\132\216\167\216\179\216\170\216\174\217\138\216\175 \216\165\216\182\216\167\217\129\216\169 \216\175\217\138\217\136\216\170\217\138 \217\133\217\134 \217\132\217\136\216\167\217\129\217\138\216\169 \217\131\216\167\216\170\217\137", 255, 194, 14)
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
        if F.section == "members" then F.membersScroll = math.max(0, F.membersScroll - step)
        elseif F.section == "ranks" then F.ranksScroll = math.max(0, F.ranksScroll - step)
        elseif F.section == "vehicles" then F.vehiclesScroll = math.max(0, F.vehiclesScroll - step)
        elseif F.section == "finance" then F.financeScroll = math.max(0, F.financeScroll - step)
        elseif F.section == "logs" then F.logsScroll = math.max(0, F.logsScroll - step)
        elseif F.section == "duty" then F.dutyScroll = math.max(0, F.dutyScroll - step)
        elseif F.section == "dutylocations" then F.dutyLocationsScroll = math.max(0, F.dutyLocationsScroll - step)
        elseif F.section == "dutyvehicles" then F.dutyVehiclesScroll = math.max(0, F.dutyVehiclesScroll - step)
        end
    elseif key == "mouse_wheel_down" then
        if F.section == "members" then F.membersScroll = F.membersScroll + step
        elseif F.section == "ranks" then F.ranksScroll = F.ranksScroll + step
        elseif F.section == "vehicles" then F.vehiclesScroll = F.vehiclesScroll + step
        elseif F.section == "finance" then F.financeScroll = F.financeScroll + step
        elseif F.section == "logs" then F.logsScroll = F.logsScroll + step
        elseif F.section == "duty" then F.dutyScroll = F.dutyScroll + step
        elseif F.section == "dutylocations" then F.dutyLocationsScroll = F.dutyLocationsScroll + step
        elseif F.section == "dutyvehicles" then F.dutyVehiclesScroll = F.dutyVehiclesScroll + step
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
    end
end)

-- ============================================================
-- Cleanup
-- ============================================================
addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
end)
