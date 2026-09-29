-- Decompiled by Owl Decompiler v1.0 ([jobs]/gunsmith/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with decompiler artifacts repaired:
--   * var0/var1/var2/var3 merged identities restored:
--       dragMap    - [drag image] = part code (var0 in StartClick/DragEnd)
--       dropTarget - [drag point rect] = the gun-part image it reveals
--                    (var1 in DragEnd + showAssembling)
--       partW/partH- the lost parts-list cell size (var2/var3) - the parts
--                    list is 146px wide inside the 900px window, so 70x70
--                    cells are the reconstructed fit (documented).
--   * the gridlist fill inlined uiGridListAddRow into every Set* call
--     (2 rows per entry) - restored with `local row`.
--   * showAssembling's three part loops shared forvar leaks - restored.
--   * exports["inventory-system"]:playerHasItem(name) does not exist here -
--     adapted to exports["item-system"]:hasItem with FACTORY_ITEM_IDS
--     (the config's REPO ADAPTATION map).
--   * exports["inventory-system"]:hideCrafting() - lost Owl resource -
--     pcall-guarded DEFER (elementData contract kept verbatim).
--   * images: the original factory artwork was not in the dump - generated
--     placeholders ship in gunsmith/images/ (the decompile's paths
--     prefixed with the subfolder - this port lives inside job-system).

local UI = {
        window = {},
        label = {},
        button = {},
        gridlist = {},
        box = {},
        drag_point = {},
        gun_structure = {},
        gun_part = {},
        gun_part_drag = {},
        container = {},
        rectangle = {},
        image = {}
}

local current_assembling_details = false
local current_assembling_details_index = false
local waiting_assembling_callback = false
local dragMap = {}
local dropTarget = {}
local partW, partH = 70, 70

function UIKitReady()
        eui = exports.UIKit
        UI.window[1] = eui:uiCreateWindow(false, false, 350, 450, {
                en = "Factory",
                ar = "المصنع"
        })
        eui:uiSetVisible(UI.window[1], false)
        eui:uiWindowSetMovable(UI.window[1], false)
        UI.button[1] = eui:uiCreateButton(5, 410, 340, 35, { en = "Cancel", ar = "إلغاء" }, _, UI.window[1])
        eui:uiSetProperty(UI.button[1], "HoverTextColor", tocolor(255, 48, 48))
        UI.gridlist[1] = eui:uiCreateGridList(5, 50, 340, 300, tocolor(10, 10, 10, 0), UI.window[1])
        eui:uiGridListAddColumn(UI.gridlist[1], "", 1)
        eui:uiSetAlign(UI.gridlist[1], "left", "center")
        eui:uiSetProperty(UI.gridlist[1], "row_height", 30)
        UI.window[2] = eui:uiCreateWindow(false, false, 900, 500, "Gun Factory / Assembling")
        eui:uiSetVisible(UI.window[2], false)
        eui:uiWindowSetMovable(UI.window[2], false)
        UI.button.cancel_craft = eui:uiCreateButton(480, 450, 200, 40, { en = "Cancel", ar = "إلغاء" }, _, UI.window[2])
        eui:uiSetClickAction(UI.button.cancel_craft, "hide_ui", UI.window[2])
        UI.button.craft = eui:uiCreateButton(690, 450, 200, 40, { en = "Craft", ar = "صنع" }, "primary", UI.window[2])
        eui:uiSetProperty(UI.button.craft, "HoverGlow", true)
        UI.container.gun = eui:uiCreateContainer(156 + 30, 50, 704, 353, UI.window[2])
        UI.image.gun_structure = eui:uiCreateImage(0, 0, 704, 353, "gunsmith/images/ak-47.png", UI.container.gun)
        UI.rectangle.gun_parts_list = eui:uiCreateRectangle(10, 40, 156 + 10, 450, tocolor(0, 0, 0, 200), true, true, true, true, UI.window[2])
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

addEventHandler("onClientUIVisibilityChange", root, function(visible)
        if source == UI.window[2] and not visible then
                showCursor(false)
        end
end)

addEventHandler("onClientUIClick", root, function()
        if source == UI.button[1] then
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
        elseif source == UI.button.craft and current_assembling_details_index then
                if waiting_assembling_callback then
                        return
                end
                for _, partImage in pairs(UI.gun_part) do
                        if not eui:uiGetVisible(partImage) then
                                exports.notifications:output({
                                        en = "Weapon assembly is incomplete",
                                        ar = "تجميع السلاح غير مكتمل"
                                }, 5000, "error")
                                return
                        end
                end
                waiting_assembling_callback = true
                exports.public:loading("factory:assembling", true)
                triggerServerEvent("factory:assembling", localPlayer, current_assembling_details_index)
        end
end)

addEvent("factory:assembling:callback", true)
addEventHandler("factory:assembling:callback", localPlayer, function(success)
        if success then
                eui:uiSetVisible(UI.window[2], false)
                showCursor(false)
        end
        exports.public:loading("factory:assembling", false)
        waiting_assembling_callback = nil
end)

addEventHandler("onClientUIStartClick", root, function()
        if dragMap[source] then
                eui:uiDragElement(source)
        end
end)

addEventHandler("onClientUIDragEnd", root, function(droppedOn)
        if dragMap[source] and dropTarget[droppedOn] and dropTarget[droppedOn] == UI.gun_part[dragMap[source]] then
                eui:uiSetVisible(source, false)
                eui:uiSetVisible(UI.gun_part[dragMap[source]], true)
        end
end)

addEventHandler("onClientUIDoubleClick", root, function()
        if source == UI.gridlist[1] and eui:uiGridListGetSelectedItem(UI.gridlist[1]) ~= -1 then
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
                if eui:uiGridListGetItemData(UI.gridlist[1], eui:uiGridListGetSelectedItem(UI.gridlist[1]), 1) == "crafting" then
                        triggerServerEvent("factory:crafting", localPlayer, eui:uiGridListGetSelectedItem(UI.gridlist[1]) + 1, factory.currentMarker)
                else
                        showAssembling(factory.assembly_items[eui:uiGridListGetSelectedItem(UI.gridlist[1]) + 1], eui:uiGridListGetSelectedItem(UI.gridlist[1]) + 1)
                end
                eui:uiGridListSetSelectedItem(UI.gridlist[1], -1)
        end
end)

function showAssembling(details, detailsIndex)
        current_assembling_details = details
        current_assembling_details_index = detailsIndex
        eui:uiSetText(UI.window[2], "Gun Factory / Assembling / " .. tostring(details.title))
        eui:uiStaticImageLoadImage(UI.image.gun_structure, "gunsmith/images/" .. details.item.Name .. "/" .. details.item.Name .. ".png")
        for _, partImage in pairs(UI.gun_part) do
                destroyElement(partImage)
        end
        for _, child in ipairs(getElementChildren(UI.rectangle.gun_parts_list)) do
                destroyElement(child)
        end
        for _, pointRect in pairs(UI.drag_point) do
                destroyElement(pointRect)
        end
        UI.gun_part = {}
        UI.gun_part_drag = {}
        dragMap = {}
        UI.drag_point = {}
        dropTarget = {}
        for _, part in ipairs(details.parts) do
                UI.gun_part[part.code] = eui:uiCreateImage(0, 0, 704, 353, "gunsmith/images/" .. details.item.Name .. "/" .. part.code .. ".png", UI.container.gun)
                eui:uiSetVisible(UI.gun_part[part.code], false)
        end
        for _, part in ipairs(details.parts) do
                eui:uiCreateRectangle(5, 5, partW, partH, "bg_default", true, true, true, true, UI.rectangle.gun_parts_list)
                UI.gun_part_drag[part.code] = eui:uiCreateImage(5, 5, partW, partH, "gunsmith/images/" .. details.item.Name .. "/" .. part.code .. ".png", UI.rectangle.gun_parts_list)
                if exports["item-system"]:hasItem(localPlayer, FACTORY_ITEM_IDS[part.item_name]) then
                        eui:uiSetProperty(UI.gun_part_drag[part.code], "draggable", true)
                        dragMap[UI.gun_part_drag[part.code]] = part.code
                else
                        eui:uiSetColor(UI.gun_part_drag[part.code], 255, 0, 0, 180)
                end
        end
        for _, part in ipairs(details.parts) do
                UI.drag_point[part.code] = eui:uiCreateRectangle(part.offset[1], part.offset[2], 120, 60)
                dropTarget[UI.drag_point[part.code]] = UI.gun_part[part.code]
        end
        eui:uiSetVisible(UI.window[2], true)
        showCursor(true)
end

addEventHandler("onClientMarkerLeave", resourceRoot, function(player, matchingDimension)
        if player ~= localPlayer then
                return
        end
        if getElementData(source, "factory:crafting") then
                pcall(function()
                        exports["inventory-system"]:hideCrafting()
                end)
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
                factory.currentMarker = nil
        end
end)

addEvent("factory:showSelection", true)
addEventHandler("factory:showSelection", root, function(marker, kind)
        eui:uiSetVisible(UI.window[1], true)
        showCursor(true)
        factory.currentMarker = marker
        eui:uiGridListClear(UI.gridlist[1])
        if kind == "crafting" then
                for _, craftItem in ipairs(factory.craft_items) do
                        local row = eui:uiGridListAddRow(UI.gridlist[1])
                        eui:uiGridListSetItemText(UI.gridlist[1], row, 1, craftItem.title)
                        eui:uiGridListSetItemData(UI.gridlist[1], row, 1, kind)
                end
        elseif kind == "assembling" then
                for _, assemblyItem in ipairs(factory.assembly_items) do
                        local row = eui:uiGridListAddRow(UI.gridlist[1])
                        eui:uiGridListSetItemText(UI.gridlist[1], row, 1, assemblyItem.title)
                        eui:uiGridListSetItemData(UI.gridlist[1], row, 1, kind)
                end
        end
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText, data)
        if not isElement(element) then
                return
        end
        if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "job.gunsmith" and optionText == "Talk" then
                exports["job-system"]:showTakeJob("Gunsmith", {
                        en = "Gunsmith",
                        ar = "صانع أسلحة"
                }, {
                        en = [[
You can not take this job if you are on duty

You will be able to craft guns and bombs inside the factory]],
                        ar = "\nلاتستطيع أخذ الوظيفة إذا كنت داخل الخدمة\n\nسوف تتمكن من صنع الأسلحة والمتفجرات بداخل المصنع"
                })
        end
end)

addEvent("onClientRequestTakeJob", true)
addEventHandler("onClientRequestTakeJob", localPlayer, function(job)
        if job == "Gunsmith" then
                if getElementData(localPlayer, "duty:data") and getElementData(localPlayer, "duty:data").Status then
                        outputChatBox("(( You must be off duty to take this job. ))", 255, 46, 46)
                        return
                end
                exports["job-system"]:takeJob(job)
        end
end)
