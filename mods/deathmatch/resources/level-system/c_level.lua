-- Decompiled by Owl Decompiler v1.0 (level-system/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with decompiler artifacts repaired:
--   * the decompile emitted the state table twice as anonymous
--     `;({...}).render/.show` chains and referenced it as var0, with var1 =
--     the lost resolution scale - restored as the LEVEL table + SCALE.
--   * lost multi-return picks in the F1 awards tab (getPlayerLevel()
--     returns level, exp, required - the decompile reused the first value
--     everywhere, making the progress bar level/level) - restored with
--     explicit locals.
--   * anim() early return `arg5, arg6, arg7, t4` - t4 was the lost 4th
--     dummy (interpolateBetween returns 3 values) - dropped.
--   * getPlayerLevelAwards() returned `var0.awards, var1` (var1 = lost
--     second table) - returns the awards array.
--   * `tostring(getPlayerLevelAwards()[forvar13.award])` indexed the
--     awards ARRAY with an award id (the lost AWARD_TYPES map) - falls
--     back to tostring(award).
--   * boost defaulted to 0 in the state init (math.ceil(nil*100) crash
--     when no EXP event had arrived yet).

local sx, sy = guiGetScreenSize()
local SCALE = sy / 1080

local LEVEL = {
        count = getTickCount(),
        x = (sx - 400 * SCALE) / 2,
        y = 100,
        w = 400 * SCALE,
        h = 10 * SCALE,
        rec_w = 400 * SCALE / 10,
        level = 0,
        last_exp = 0,
        exp = 0,
        max_exp = 0,
        color = tocolor(255, 55, 95, 255),
        img_color = tocolor(255, 55, 95, 200),
        postGUI = true,
        image = false,
        awards = {},
        boost = 0
}

function LEVEL.render()
        for i = 1, 10 do
                dxDrawRectangle(LEVEL.x + LEVEL.rec_w * (i - 1), LEVEL.y, LEVEL.rec_w - 4, LEVEL.h, tocolor(20, 20, 30, 250), LEVEL.postGUI)
                local fill = LEVEL.x + anim(LEVEL.count, 1500, LEVEL.last_exp, 0, 0, LEVEL.exp, 0, 0, "Linear") * (LEVEL.w / LEVEL.max_exp) - (LEVEL.x + LEVEL.rec_w * (i - 1))
                if not (LEVEL.x + anim(LEVEL.count, 1500, LEVEL.last_exp, 0, 0, LEVEL.exp, 0, 0, "Linear") * (LEVEL.w / LEVEL.max_exp) > LEVEL.x + LEVEL.rec_w * (i - 1) + LEVEL.rec_w) and 0 < fill then
                        dxDrawRectangle(LEVEL.x + LEVEL.rec_w * (i - 1), LEVEL.y, fill - 3, LEVEL.h, LEVEL.color, LEVEL.postGUI)
                end
        end
        local text = tostring(math.floor(anim(LEVEL.count, 1500, LEVEL.last_exp, 0, 0, LEVEL.exp, 0, 0, "Linear"))) .. " / " .. tostring(LEVEL.max_exp) .. "\n\n+" .. (LEVEL.exp - LEVEL.last_exp) .. "" .. "   (+" .. math.ceil(LEVEL.boost * 100) .. "%)"
        dxDrawText(text, LEVEL.x - 2, LEVEL.y + LEVEL.h + 10, LEVEL.x + LEVEL.w, LEVEL.y + LEVEL.h + 60, tocolor(0, 0, 0, 255), 1.25, "default-bold", "center", "top", true, false, LEVEL.postGUI)
        dxDrawText(text, LEVEL.x, LEVEL.y + LEVEL.h + 10 - 2, LEVEL.x + LEVEL.w, LEVEL.y + LEVEL.h + 60, tocolor(0, 0, 0, 255), 1.25, "default-bold", "center", "top", true, false, LEVEL.postGUI)
        dxDrawText(text, LEVEL.x + 2, LEVEL.y + LEVEL.h + 10, LEVEL.x + LEVEL.w, LEVEL.y + LEVEL.h + 60, tocolor(0, 0, 0, 255), 1.25, "default-bold", "center", "top", true, false, LEVEL.postGUI)
        dxDrawText(text, LEVEL.x, LEVEL.y + LEVEL.h + 10 + 2, LEVEL.x + LEVEL.w, LEVEL.y + LEVEL.h + 60, tocolor(0, 0, 0, 255), 1.25, "default-bold", "center", "top", true, false, LEVEL.postGUI)
        dxDrawText(text, LEVEL.x, LEVEL.y + LEVEL.h + 10, LEVEL.x + LEVEL.w, LEVEL.y + LEVEL.h + 60, tocolor(255, 255, 255, 255), 1.25, "default-bold", "center", "top", true, false, LEVEL.postGUI)
        if LEVEL.image then
                dxDrawImage(LEVEL.x - 70 * SCALE, LEVEL.y - 25 * SCALE, 60 * SCALE, 60 * SCALE, LEVEL.image, 0, 0, 0, LEVEL.img_color, LEVEL.postGUI)
                dxDrawImage(LEVEL.x + LEVEL.w + 10 * SCALE, LEVEL.y - 25 * SCALE, 60 * SCALE, 60 * SCALE, LEVEL.image, 0, 0, 0, LEVEL.img_color, LEVEL.postGUI)
        end
        dxDrawText(tostring(LEVEL.level), LEVEL.x - 80 * SCALE, LEVEL.y - 10 * SCALE, LEVEL.x, LEVEL.y + 20 * SCALE, tocolor(255, 255, 255, 255), 3 * SCALE, "default-bold", "center", "center", false, false, LEVEL.postGUI)
        dxDrawText(tostring(LEVEL.level + 1), LEVEL.x + LEVEL.w, LEVEL.y - 10 * SCALE, LEVEL.x + LEVEL.w + 80 * SCALE, LEVEL.y + 20 * SCALE, tocolor(255, 255, 255, 255), 3 * SCALE, "default-bold", "center", "center", false, false, LEVEL.postGUI)
end

function anim(startTick, duration, from1, from2, from3, to1, to2, to3, easing)
        if duration < getTickCount() - startTick then
                return to1, to2, to3
        end
        return interpolateBetween(from1, from2, from3, to1, to2, to3, (getTickCount() - startTick) / duration, easing)
end

function LEVEL.show(duration)
        if isTimer(LEVEL.timer) then
                killTimer(LEVEL.timer)
        else
                addEventHandler("onClientRender", root, LEVEL.render)
        end
        LEVEL.timer = setTimer(function()
                removeEventHandler("onClientRender", root, LEVEL.render)
        end, duration or 8000, 1)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        downloadFile("rank.png")
end)
addEventHandler("onClientFileDownloadComplete", resourceRoot, function(fileName, cache)
        if fileName == "rank.png" then
                LEVEL.image = dxCreateTexture(fileName)
                fileDelete(fileName)
        end
end)

addEvent("level:show", true)
addEventHandler("level:show", localPlayer, function(level, exp)
        LEVEL.level = level
        LEVEL.exp = exp
        LEVEL.last_exp = exp
        LEVEL.max_exp = getRequiredExp(level)
        LEVEL.show(5000)
end)

addEvent("level:onLevelUp", true)
addEventHandler("level:onLevelUp", localPlayer, function(level, lastExp, exp)
        LEVEL.show()
        LEVEL.last_exp = lastExp
        LEVEL.exp = exp
        LEVEL.level = level
        LEVEL.max_exp = getRequiredExp(level)
        LEVEL.count = getTickCount()
end)

addEvent("level:onExpUp", true)
addEventHandler("level:onExpUp", localPlayer, function(level, lastExp, exp, boost)
        if isTimer(LEVEL.timer) then
                killTimer(LEVEL.timer)
        else
                addEventHandler("onClientRender", root, LEVEL.render)
        end
        LEVEL.timer = setTimer(function()
                removeEventHandler("onClientRender", root, LEVEL.render)
        end, 8000, 1)
        LEVEL.last_exp = lastExp
        LEVEL.exp = exp
        LEVEL.level = level
        LEVEL.max_exp = getRequiredExp(level)
        LEVEL.count = getTickCount()
        LEVEL.boost = boost
end)

addEvent("level:syncLocalLevel", true)
addEventHandler("level:syncLocalLevel", localPlayer, function(level, exp, awards)
        LEVEL.exp = exp
        LEVEL.level = level
        LEVEL.awards = awards
end)

addEvent("level:syncLocalAwards", true)
addEventHandler("level:syncLocalAwards", localPlayer, function(awards)
        LEVEL.awards = awards
end)

function getPlayerLevel()
        return LEVEL.level, LEVEL.exp, getRequiredExp(LEVEL.level)
end

function getPlayerLevelAwards()
        return LEVEL.awards
end

function getRequiredExp(level)
        return level ^ 2 * 50
end

addCommandHandler("level", function()
        if not getElementData(localPlayer, "character:id") then
                return
        end
        if getPlayerLevel() then
                triggerEvent("level:show", localPlayer, getPlayerLevel())
        end
end, false, false)

UI = {
        progressbar = {},
        edit = {},
        label = {},
        button = {},
        gridlist = {},
        container = {},
        image = {}
}

addEventHandler("onClientUIMenuSelectChange", root, function(row, toggleElement)
        if toggleElement and getElementID(source) == "main-menu" then
                eui = exports.UIKit
                if eui:uiMenuGetItemID(source, row) == "awards" then
                        if not isElement(UI.label.current_level) then
                                eui:uiSetColor(eui:uiCreateImage(25, 60, 50, 50, LEVEL.image, toggleElement), 255, 255, 255, 20)
                                eui:uiSetColor(eui:uiCreateImage(eui:uiGetSize(toggleElement) - 75, 60, 50, 50, LEVEL.image, toggleElement), 255, 255, 255, 20)
                                UI.label.current_level = eui:uiCreateLabel(25, 60, 50, 50, "1", "primary", "center", "center", toggleElement)
                                UI.label.next_level = eui:uiCreateLabel(eui:uiGetSize(toggleElement) - 75, 60, 50, 50, "2", "primary", "center", "center", toggleElement)
                                eui:uiSetFont(UI.label.current_level, "default-large")
                                eui:uiSetFont(UI.label.next_level, "default-large")
                                UI.label.exp = eui:uiCreateLabel(0, 95, eui:uiGetSize(toggleElement))
                                UI.progressbar.exp = eui:uiCreateProgressBar(100, 80, eui:uiGetSize(toggleElement) - 200, 10, _, toggleElement)
                                eui:uiSetProperty(UI.progressbar.exp, "background_color", tocolor(20, 20, 20, 240))
                                eui:uiSetProperty(UI.progressbar.exp, "show_progress", false)
                                eui:uiSetProperty(UI.progressbar.exp, "progress_animation", true)
                                eui:uiCreateLabel(15, 150, eui:uiGetSize(toggleElement) - 30, 80, "ستحصل على جوائز مختلفة عند وصولك إلى مستويات معينة أو عند التواجد بشكل مستمر\nيمكنك زيادة مستواك عن طريق الوظائف والمهمات والتواجد داخل السيرفر\n\nالقائمة التالية توضح جوائزك الحالية التي لم يتم استلامها بعد\n                    ", tocolor(255, 255, 255, 255), "center", "top", toggleElement)
                                UI.gridlist.awards = eui:uiCreateGridList(15, 250, eui:uiGetSize(toggleElement) - 30, 250, tocolor(10, 10, 10, 0), toggleElement)
                                eui:uiGridListAddColumn(UI.gridlist.awards, "Award", 0.4)
                                eui:uiGridListAddColumn(UI.gridlist.awards, "Reason", 0.25)
                                eui:uiGridListAddColumn(UI.gridlist.awards, "Received Date", 0.2)
                                eui:uiGridListAddColumn(UI.gridlist.awards, "Expiry", 0.15)
                                eui:uiSetAlign(UI.gridlist.awards, "left", "center")
                                eui:uiSetProperty(UI.gridlist.awards, "color_coded", true)
                                eui:uiSetProperty(UI.gridlist.awards, "row_height", 30)
                                UI.button.take_award = eui:uiCreateButton((eui:uiGetSize(toggleElement) - 250) / 2, eui:uiGetSize(toggleElement) - 45, 250, 35, {
                                        en = "Take Award",
                                        ar = "استلام الجائزة"
                                }, "primary", toggleElement)
                        end
                        local level, exp, required = getPlayerLevel()
                        eui:uiSetText(UI.label.current_level, tostring(level))
                        eui:uiSetText(UI.label.next_level, tostring(level + 1))
                        eui:uiSetText(UI.label.exp, "" .. tostring(exp) .. " / " .. tostring(required) .. "")
                        eui:uiProgressBarSetProgress(UI.progressbar.exp, exp / required * 100)
                        if getPlayerLevelAwards() then
                                eui:uiGridListClear(UI.gridlist.awards)
                                for _, award in ipairs(getPlayerLevelAwards()) do
                                        -- decompiler lost the `local row` and inlined uiGridListAddRow
                                        -- into every Set* call (4 rows per award) - restored
                                        local row = eui:uiGridListAddRow(UI.gridlist.awards)
                                        eui:uiGridListSetItemData(UI.gridlist.awards, row, 1, award.id)
                                        eui:uiGridListSetItemText(UI.gridlist.awards, row, 1, award.description or tostring(award.award))
                                        eui:uiGridListSetItemText(UI.gridlist.awards, row, 2, award.reason or "Reached Level " .. tostring(award.level))
                                        eui:uiGridListSetItemText(UI.gridlist.awards, row, 3, tostring(award.createdAt))
                                        eui:uiGridListSetItemText(UI.gridlist.awards, row, 4, award.expiry_date or "-")
                                        eui:uiGridListSetItemColor(UI.gridlist.awards, row, 1, tocolor(0, 255, 0, 255))
                                        eui:uiGridListSetItemColor(UI.gridlist.awards, row, 2, tocolor(0, 255, 0, 255))
                                        eui:uiGridListSetItemColor(UI.gridlist.awards, row, 3, tocolor(0, 255, 0, 255))
                                end
                        end
                end
        end
end)

addEventHandler("onClientUIClick", root, function()
        if source == UI.button.take_award and eui:uiGridListGetSelectedItem(UI.gridlist.awards) ~= -1 then
                eui:uiGridListSetSelectedItem(UI.gridlist.awards, -1)
                triggerServerEvent("level:takeAward", localPlayer, (eui:uiGridListGetItemData(UI.gridlist.awards, eui:uiGridListGetSelectedItem(UI.gridlist.awards), 1)))
        end
end)
