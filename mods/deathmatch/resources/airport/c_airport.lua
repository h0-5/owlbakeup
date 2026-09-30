-- Decompiled by Owl Decompiler v1.0 ([rp]/airport/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with one decompiler artifact repaired:
--   * the gridlist fill inlined uiGridListAddRow into every Set* call
--     (4 rows per ticket, the same Fix #62 repair pattern) - restored with a
--     `local row`.

local UI = {
	window = {},
	label = {},
	button = {},
	gridlist = {}
}

function UIKitReady()
	eui = exports.UIKit
	UI.window[1] = eui:uiCreateWindow(false, false, 500, 420, {
		en = "Air Travel",
		ar = "السفر عبر الطائرة"
	}, _, ":assets/icons/plane.png")
	eui:uiSetVisible(UI.window[1], false)
	eui:uiWindowSetMovable(UI.window[1], false)
	eui:uiSetProperty(eui:uiCreateLabel(0, 40, 490, 50, {
		en = [[
Please select the ticket you wish to use for travel
Then go directly to the gate of the plane and wait for the next flight time

If you do not have travel tickets, you can book through the mobile application
	]],
		ar = "الرجاء اختيار التذكرة التي ترغب باستخدامها للسفر\nثم التوجه مباشرة إلى بوابة الطائرة وانتظار وقت الرحلة القادمة\n\nإذا كنت لاتملك تذاكر سفر يمكنك الحجز عن طريق تطبيق الجوال\n\t"
	}, tocolor(255, 255, 255, 230), "center", "top", UI.window[1]), "color_coded", false)
	eui:uiSetProperty(eui:uiCreateLabel(0, 40, 490, 50, {
		en = [[
Please select the ticket you wish to use for travel
Then go directly to the gate of the plane and wait for the next flight time

If you do not have travel tickets, you can book through the mobile application
	]],
		ar = "الرجاء اختيار التذكرة التي ترغب باستخدامها للسفر\nثم التوجه مباشرة إلى بوابة الطائرة وانتظار وقت الرحلة القادمة\n\nإذا كنت لاتملك تذاكر سفر يمكنك الحجز عن طريق تطبيق الجوال\n\t"
	}, tocolor(255, 255, 255, 230), "center", "top", UI.window[1]), "word_break", true)
	UI.gridlist[1] = eui:uiCreateGridList(5, 150, 490, 170, tocolor(0, 0, 0, 0), UI.window[1])
	eui:uiGridListAddColumn(UI.gridlist[1], "#", 0.4)
	eui:uiGridListAddColumn(UI.gridlist[1], "From", 0.3)
	eui:uiGridListAddColumn(UI.gridlist[1], "To", 0.3)
	eui:uiSetProperty(UI.gridlist[1], "row_height", 30)
	UI.button[1] = eui:uiCreateButton(5, 340, 490, 35, {
		en = "Travel now",
		ar = "السفر الآن"
	}, "primary", UI.window[1])
	UI.button[2] = eui:uiCreateButton(5, 380, 490, 35, {
		en = "I don't want to travel",
		ar = "لا أريد السفر"
	}, _, UI.window[1])
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

function closeUIWindows()
	eui:uiSetVisible(UI.window[1], false)
	showCursor(false)
end
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

addEventHandler("onClientUIClick", root, function()
	if source == UI.button[1] then
		if eui:uiGridListGetSelectedItem(UI.gridlist[1]) ~= -1 then
			eui:uiSetVisible(UI.window[1], false)
			showCursor(false)
			triggerServerEvent("airport:select_ticket", localPlayer, eui:uiGridListGetItemData(UI.gridlist[1], eui:uiGridListGetSelectedItem(UI.gridlist[1]), 1).code)
		end
	elseif source == UI.button[2] then
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	end
end)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, optionText, data)
	if not isElement(element) then
		return
	end
	if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "airport.travel" and optionText == "Talk" then
		eui:uiGridListClear(UI.gridlist[1])
		eui:uiSetVisible(UI.window[1], true)
		showCursor(true)
		exports.public:loading("airport.get_travel_tickets", true)
		triggerServerEvent("airport:get_travel_tickets", localPlayer)
	end
end)

addEvent("airport:get_travel_tickets:callback", true)
addEventHandler("airport:get_travel_tickets:callback", localPlayer, function(tickets)
	exports.public:loading("airport.get_travel_tickets", false)
	eui:uiGridListClear(UI.gridlist[1])
	for _, ticket in pairs(tickets) do
		local row = eui:uiGridListAddRow(UI.gridlist[1])
		eui:uiGridListSetItemData(UI.gridlist[1], row, 1, ticket)
		eui:uiGridListSetItemText(UI.gridlist[1], row, 1, ticket.code)
		eui:uiGridListSetItemText(UI.gridlist[1], row, 2, ticket.from)
		eui:uiGridListSetItemText(UI.gridlist[1], row, 3, ticket.to)
	end
end)
