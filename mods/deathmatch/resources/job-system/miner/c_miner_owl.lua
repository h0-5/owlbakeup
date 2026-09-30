-- Decompiled by Owl Decompiler v1.0 ([jobs]/miner/miner_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1/var2 were MERGED into two identities: the UI table, the
--     busy flag and the materials list all shared one var in the decompile
--     (var0.progressbar vs var0 = {} vs var1 = true vs #var2). Restored as
--     UI / busy / materials.
--   * the info label was built AFTER the items loop from the LAST forvar12
--     only - `tostring(0 + 1)` (lost `#materials`) and
--     `0 + forvar12.Properties.org_price` (lost the sum accumulator).
--     Restored with the loop accumulating the total.
--   * Owl's inventory API (getInventoryItems("character:"..id) +
--     Type/Properties.org_price) does not exist in this repo - adapted to
--     the UG item-system that ships here (getItems/countItems + item #215
--     "Materials", price constant mirrored in s_miner_owl.lua).
--   * the mining loop UI is verbatim: Miner:ProgressState ("Show"/"Hide")
--     reading the "Miner:Progress" elementData on the rock, refreshed
--     every 2000ms (the old server drove those - s_miner_owl rebuilds it).

local MATERIAL_ITEM_ID = 215 -- g_items.lua "Materials" (Fix #63)
local MATERIAL_PRICE = 25 -- mirrors s_miner_owl.lua

local sx, sy = guiGetScreenSize()
local SCALE = sy / 1080

UI = {
        progressbar = {},
        window = {},
        label = {},
        button = {}
}

local busy = false
local materials = {}

function UIKitReady()
        eui = exports.UIKit
        UI.progressbar[1] = eui:uiCreateProgressBar((sx - 200 * SCALE) / 2, sy - 100 * SCALE, 200 * SCALE, 10 * SCALE, tocolor(153, 73, 0, 255))
        eui:uiSetVisible(UI.progressbar[1], false)
        eui:uiSetProperty(UI.progressbar[1], "background_color", tocolor(0, 0, 0, 240))
        eui:uiSetProperty(UI.progressbar[1], "progress_animation", true)
        eui:uiSetProperty(UI.progressbar[1], "show_progress", false)
        UI.window[1] = eui:uiCreateWindow(false, false, 420, 220, {
                en = "Sell Your Materials",
                ar = "بيع المعادن"
        })
        eui:uiSetVisible(UI.window[1], false)
        UI.label.Info = eui:uiCreateLabel(20, 60, 222, 20, "", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
        UI.button.sell = eui:uiCreateButton(5, 180, 150, 35, { en = "Sell", ar = "بيع" }, "primary", UI.window[1])
        UI.button.cancel = eui:uiCreateButton(160, 180, 150, 35, { en = "Cancel", ar = "إلغاء" }, _, UI.window[1])
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

function closeUIWindows()
        eui:uiSetVisible(UI.progressbar[1], false)
        eui:uiSetVisible(UI.window[1], false)
        showCursor(false)
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

addEvent("Miner:ProgressState", true)
addEventHandler("Miner:ProgressState", root, function(state, rock)
        if isTimer(ProgressTimer) then
                killTimer(ProgressTimer)
        end
        if state == "Show" then
                eui:uiSetVisible(UI.progressbar[1], true)
                eui:uiProgressBarSetProgress(UI.progressbar[1], getElementData(rock, "Miner:Progress") or 0)
                ProgressTimer = setTimer(function(rock)
                        eui:uiProgressBarSetProgress(UI.progressbar[1], getElementData(rock, "Miner:Progress") or 0)
                end, 2000, 0, rock)
        elseif state == "Hide" then
                eui:uiSetVisible(UI.progressbar[1], false)
        end
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText, data)
        if not isElement(element) then
                return
        end
        if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "sell.materials" and optionText == "Talk" then
                if not getElementData(localPlayer, "character:id") then
                        return
                end
                materials = {}
                local items = exports["item-system"]:getItems(localPlayer) or {}
                for _, value in ipairs(items) do
                        if value[1] == MATERIAL_ITEM_ID then
                                table.insert(materials, value)
                        end
                end
                local total = 0
                for i = 1, #materials do
                        total = total + MATERIAL_PRICE
                end
                -- byte-exact strings from the decompile (verify script:
                -- scripts/fix63_verify_miner_arabic.py) - en has NO space/newline
                -- between the count and "materials" in the original, ar has " معدن"
                eui:uiSetText(UI.label.Info, {
                        en = "You have: " .. tostring(#materials) .. "materials\nTotal price: #00FF00$" .. tostring(total) .. "\n\n\n#FFFFFFPress 'Sell' button if you want to sell all your materials.",
                        ar = "أنت لديك: " .. tostring(#materials) .. " معدن\nالسعر الإجمالي: #00FF00$" .. tostring(total) .. "\n\n#FFFFFFاضغط 'بيع' اذا كنت تريد بيع جميع المعادن لديك."
                })
                eui:uiSetVisible(UI.window[1], true)
                showCursor(true)
        end
end)

addEventHandler("onClientUIClick", root, function()
        if source == UI.button.sell then
                if busy then
                        exports.notifications:output({
                                en = "Wait please",
                                ar = "انتظر من فضلك"
                        }, 3000, "warning")
                        return
                end
                if #materials > 0 then
                        if not getElementData(localPlayer, "character:id") then
                                return
                        end
                        busy = true
                        triggerServerEvent("miner:sell", localPlayer)
                        eui:uiSetVisible(UI.window[1], false)
                        showCursor(false)
                        materials = {}
                else
                        exports.notifications:output({
                                en = "You don't have any materials to sell",
                                ar = "ليس لديك أي مواد لبيعها"
                        }, 3500, "error")
                end
        elseif source == UI.button.cancel then
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
        end
end)

addEvent("miner:sell:callback", true)
addEventHandler("miner:sell:callback", localPlayer, function()
        busy = false
end)
