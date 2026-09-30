-- ============================================================================
-- skin-system / c_skins.lua                      (Fix #65)
-- ----------------------------------------------------------------------------
-- Client half, restored 1:1 from the old Owl client:
--   /home/daytona/backupm/[rp]/skin-system/skin_c_decompiled.lua
--
-- Every window keeps the old client's exact numbers and UIKit calls:
--
--   window[1] "Fashion Dupont"   uiCreateWindow(false, false, 350, 400)
--             gridlist (5, 35, 340, 260) cols SkinID .15 / Description .65 / Price .2
--             checkbox (10, 307, 150, 15) "My private skins."
--             button Buy Skin (5, 332, 340, 30)   button Close (5, 365, 340, 30)
--   window.AddSkin  rectangle (false, false, 380, 220) bg (15, 15, 15, 240)
--             label "Clothing" (10, 10, 232, 20) default-large
--             edit SkinID (10, 45, 360, 20) / Description (10, 70) / URL (10, 95) / Price (10, 120)
--             checkbox "Private skin" (10, 155, 360, 20)
--             button Add (5, 185, 100, 30) / Close (110, 185, 100, 30) / Remove (215, 185, 100, 30)
--
-- The shop is opened by talking to a ped whose `ped:interact` is "skins"
-- (ped-system injects the "Talk" option), exactly like the old client.  Shop
-- owners additionally get the old client's "Add new skin" option.
--
-- Deviations (documented on purpose):
--  * the old client rendered the custom skin itself (png download + tea
--    decryption + dxt1 texture + ped shader).  A purchased skin is handed out
--    as item 16 ("Clothes", value "skin:clothing.id") instead, so the existing
--    mabako-clothingstore / item-texture pipeline streams and applies the very
--    same texture.  The window, its numbers and its flow are unchanged.
--  * texts are bilingual {en, ar} like the rest of the server.
-- ============================================================================

eui = exports.UIKit

local localPlayer = getLocalPlayer()
local root = getRootElement()

local UI = {
	window = {},
	label = {},
	edit = {},
	checkbox = {},
	button = {},
	gridlist = {},
}

local skins = {}            -- last skins:sendSkinsDatabaseToClient payload
local shopPed = false       -- the ped the shop window was opened from
local isAddForShop = false  -- old client's flag: shop owner adding for the shop
local editingSkin = false   -- database id of the row being edited

local function getMyCharacterID()
	return tonumber(getElementData(localPlayer, "dbid"))
		or tonumber(getElementData(localPlayer, "character:id"))
		or tonumber(getElementData(localPlayer, "account:character:id"))
		or -1
end

local function isShopOwner()
	local username = getElementData(localPlayer, "account:username")
	return username ~= nil and SKINS.shopOwners[tostring(username)] == true
end

-- ---------------------------------------------------------------------------
-- 1: the old client's two windows
-- ---------------------------------------------------------------------------
function UIKitReady()
	eui = exports.UIKit

	-- === window[1] : Fashion Dupont ========================================
	UI.window[1] = eui:uiCreateWindow(false, false, 350, 400, { en = "Fashion Dupont", ar = "فاشن دوبونت" })
	eui:uiWindowSetMovable(UI.window[1], false)
	eui:uiSetVisible(UI.window[1], false)

	UI.gridlist[1] = eui:uiCreateGridList(5, 35, 340, 260, tocolor(10, 10, 10), UI.window[1])
	eui:uiGridListAddColumn(UI.gridlist[1], { en = "SkinID", ar = "رقم السكن" }, 0.15)
	eui:uiGridListAddColumn(UI.gridlist[1], { en = "Description", ar = "الوصف" }, 0.65)
	eui:uiGridListAddColumn(UI.gridlist[1], { en = "Price", ar = "السعر" }, 0.2)
	eui:uiSetAlign(UI.gridlist[1], "left", "center")

	UI.checkbox[1] = eui:uiCreateCheckBox(10, 307, 150, 15, { en = "My private skins.", ar = "سكناتي الخاصة فقط." }, true, nil, UI.window[1])

	UI.button[1] = eui:uiCreateButton(5, 332, 340, 30, { en = "Buy Skin", ar = "شراء السكن" }, tocolor(0, 0, 0), UI.window[1])
	UI.button[2] = eui:uiCreateButton(5, 365, 340, 30, { en = "Close", ar = "إغلاق" }, tocolor(0, 0, 0), UI.window[1])

	-- === window.AddSkin : Clothing / Edit Skin =============================
	UI.window.AddSkin = eui:uiCreateRectangle(false, false, 380, 220, tocolor(15, 15, 15, 240), true, true, true, true)
	eui:uiSetVisible(UI.window.AddSkin, false)

	UI.label.Title = eui:uiCreateLabel(10, 10, 232, 20, { en = "Clothing", ar = "الملابس" }, tocolor(255, 255, 255, 255), "left", "top", UI.window.AddSkin)
	eui:uiSetFont(UI.label.Title, "default-large")

	UI.edit.SkinID = eui:uiCreateEdit(10, 45, 360, 20, "", { en = "Skin ID", ar = "رقم السكن" }, nil, UI.window.AddSkin)
	UI.edit.Description = eui:uiCreateEdit(10, 70, 360, 20, "", { en = "Description", ar = "الوصف" }, nil, UI.window.AddSkin)
	UI.edit.URL = eui:uiCreateEdit(10, 95, 360, 20, "", { en = "URL (.png)", ar = "رابط الصورة (.png)" }, nil, UI.window.AddSkin)
	UI.edit.Price = eui:uiCreateEdit(10, 120, 360, 20, "", { en = "Price", ar = "السعر" }, nil, UI.window.AddSkin)

	UI.checkbox.isPrivate = eui:uiCreateCheckBox(10, 155, 360, 20, { en = "Private skin", ar = "سكن خاص" }, true, nil, UI.window.AddSkin)

	UI.button.AddSkin = eui:uiCreateButton(5, 185, 100, 30, { en = "Add", ar = "إضافة" }, tocolor(0, 0, 0), UI.window.AddSkin)
	UI.button.CloseAddSkin = eui:uiCreateButton(110, 185, 100, 30, { en = "Close", ar = "إغلاق" }, tocolor(0, 0, 0), UI.window.AddSkin)
	UI.button.RemoveSkin = eui:uiCreateButton(215, 185, 100, 30, { en = "Remove", ar = "حذف" }, tocolor(0, 0, 0), UI.window.AddSkin)
	eui:uiSetVisible(UI.button.RemoveSkin, false)

	refreshList()
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

-- ---------------------------------------------------------------------------
-- 2: the gridlist, exactly like the old client
-- ---------------------------------------------------------------------------
local function addSkinRow(entry)
	local row = eui:uiGridListAddRow(UI.gridlist[1])
	eui:uiGridListSetItemText(UI.gridlist[1], row, 1, tostring(entry.SkinID))
	eui:uiGridListSetItemText(UI.gridlist[1], row, 2, tostring(entry.Description))
	eui:uiGridListSetItemText(UI.gridlist[1], row, 3, "$" .. tostring(entry.Price))
	eui:uiGridListSetItemData(UI.gridlist[1], row, 1, entry)
end

function refreshList()
	if not isElement(UI.gridlist[1]) then return end
	local onlyMine = eui:uiCheckBoxGetSelected(UI.checkbox[1]) == true
	local myID = getMyCharacterID()

	eui:uiGridListClear(UI.gridlist[1])
	for _, entry in ipairs(skins) do
		local mine = tonumber(entry.Owner) == myID
		if onlyMine then
			if entry.private == 1 and mine then addSkinRow(entry) end
		elseif entry.private == 0 or mine then
			addSkinRow(entry)
		end
	end
end

-- ---------------------------------------------------------------------------
-- 3: opening / closing, mirrors the old client's closeUIWindows()
-- ---------------------------------------------------------------------------
local function closeUIWindows()
	if not isElement(UI.window[1]) then return end
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window.AddSkin, false)
	editingSkin = false
	shopPed = false
	showCursor(false)
end

addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

local function openSkinWindow(ped)
	shopPed = ped
	eui:uiSetVisible(UI.window[1], true)
	eui:uiBringToFront(UI.window[1])
	showCursor(true)
	triggerServerEvent(SKINS.events.getDatabase, localPlayer)
end

local function openAddSkinWindow(forShop)
	isAddForShop = forShop == true
	editingSkin = false
	eui:uiSetVisible(UI.window.AddSkin, true)
	eui:uiBringToFront(UI.window.AddSkin)
	eui:uiSetText(UI.label.Title, { en = "Clothing", ar = "الملابس" })
	eui:uiSetText(UI.button.AddSkin, { en = "Add", ar = "إضافة" })
	eui:uiSetText(UI.edit.SkinID, "")
	eui:uiSetText(UI.edit.Description, "")
	eui:uiSetText(UI.edit.URL, "")
	eui:uiSetText(UI.edit.Price, "")
	eui:uiSetVisible(UI.button.RemoveSkin, false)
	eui:uiCheckBoxSetSelected(UI.checkbox.isPrivate, false)
	eui:uiSetProperty(UI.edit.URL, "Disabled", "False")
	eui:uiSetVisible(UI.checkbox.isPrivate, isAddForShop)
	showCursor(true)
end

-- ---------------------------------------------------------------------------
-- 4: clicks - mirrors the old client's onClientUIClick / onClientUIDoubleClick
-- ---------------------------------------------------------------------------
addEventHandler("onClientUIClick", root, function()
	if not isElement(UI.window[1]) then return end

	if source == UI.button[1] then
		-- Buy Skin
		local row = eui:uiGridListGetSelectedItem(UI.gridlist[1])
		if row == -1 then return end
		local entry = eui:uiGridListGetItemData(UI.gridlist[1], row, 1)
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
		if type(entry) == "table" then
			triggerServerEvent(SKINS.events.buy, localPlayer, entry.ID, shopPed)
		end
	elseif source == UI.button[2] then
		eui:uiSetVisible(UI.window[1], false)
		showCursor(false)
	elseif source == UI.button.CloseAddSkin then
		eui:uiSetVisible(UI.window.AddSkin, false)
		showCursor(false)
		if editingSkin then
			eui:uiSetVisible(UI.window[1], false)
			editingSkin = false
		end
	elseif source == UI.checkbox[1] then
		refreshList()
	elseif source == UI.button.AddSkin then
		local skinID = tonumber(eui:uiGetText(UI.edit.SkinID))
		local description = eui:uiGetText(UI.edit.Description) or ""
		local url = eui:uiGetText(UI.edit.URL) or ""
		local price = tonumber(eui:uiGetText(UI.edit.Price))

		if not (skinID and description ~= "" and url ~= "" and price) then return end

		-- the old client forced the URL to http and required a bare .png link
		local checked = string.gsub(url, "https", "http")
		if string.sub(checked, -4) ~= ".png" or string.find(checked, "?", 1, true) then
			outputChatBox("Error: invalid image URL", 230, 0, 0)
			return
		end
		if isAddForShop and price <= 0 then return end

		local private = eui:uiCheckBoxGetSelected(UI.checkbox.isPrivate) and 1 or 0
		if editingSkin then
			triggerServerEvent(SKINS.events.update, localPlayer, editingSkin, skinID, description, url, price, private)
		else
			triggerServerEvent(SKINS.events.add, localPlayer, skinID, description, url, price, private, isAddForShop)
		end

		eui:uiSetVisible(UI.window.AddSkin, false)
		if isAddForShop then
			eui:uiSetVisible(UI.window[1], true)
		end
		eui:uiSetText(UI.button.AddSkin, { en = "Add", ar = "إضافة" })
		editingSkin = false
	elseif source == UI.button.RemoveSkin then
		eui:uiSetVisible(UI.window.AddSkin, false)
		eui:uiSetVisible(UI.window[1], true)
		if editingSkin then
			triggerServerEvent(SKINS.events.remove, localPlayer, editingSkin)
			editingSkin = false
		end
	end
end)

addEventHandler("onClientUIDoubleClick", root, function()
	if source ~= UI.gridlist[1] or not isElement(UI.window[1]) then return end
	local row = eui:uiGridListGetSelectedItem(UI.gridlist[1])
	if row == -1 then return end
	local entry = eui:uiGridListGetItemData(UI.gridlist[1], row, 1)
	if type(entry) ~= "table" or tonumber(entry.Owner) ~= getMyCharacterID() then return end

	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetText(UI.label.Title, { en = "Edit Skin", ar = "تعديل السكن" })
	eui:uiSetVisible(UI.window.AddSkin, true)
	eui:uiBringToFront(UI.window.AddSkin)
	eui:uiSetText(UI.button.AddSkin, { en = "Save", ar = "حفظ" })
	eui:uiSetText(UI.edit.SkinID, tostring(entry.SkinID))
	eui:uiSetText(UI.edit.Description, tostring(entry.Description))
	eui:uiSetText(UI.edit.URL, tostring(entry.Skin_URL))
	eui:uiSetText(UI.edit.Price, tostring(entry.Price))
	eui:uiSetVisible(UI.button.RemoveSkin, true)
	eui:uiCheckBoxSetSelected(UI.checkbox.isPrivate, entry.private == 1)
	eui:uiSetProperty(UI.edit.URL, "Disabled", "True")
	eui:uiSetVisible(UI.checkbox.isPrivate, true)
	editingSkin = tonumber(entry.ID)
	showCursor(true)
end)

-- ---------------------------------------------------------------------------
-- 5: server <-> client plumbing
-- ---------------------------------------------------------------------------
addEventHandler(SKINS.events.sendDatabase, root, function(list)
	skins = type(list) == "table" and list or {}
	if not isElement(UI.gridlist[1]) then return end
	eui:uiCheckBoxSetSelected(UI.checkbox[1], false)
	refreshList()
end)

-- old client's event for players adding their own skin (isAddForShop = false)
addEventHandler(SKINS.events.showAddWindow, localPlayer, function(forShop)
	if not isElement(UI.window.AddSkin) then return end
	openAddSkinWindow(forShop == true)
end)

-- ---------------------------------------------------------------------------
-- 6: the ped ("Fashion Dupont") - Talk opens the shop, shop owners may add
-- ---------------------------------------------------------------------------
addEvent("onClientElementMenuShow", true)
addEventHandler("onClientElementMenuShow", root, function(element, distance, menuType)
	if menuType ~= "ped" or not isElement(element) then return end
	if getElementData(element, "ped:interact") ~= SKINS.pedInteract then return end
	if not isShopOwner() then return end
	exports.interaction:addInteractOption(element, { text = "Add new skin" })
end)

addEventHandler("onClientElementMenuClick", root, function(element, optionText, optionData)
	if not isElement(element) or getElementType(element) ~= "ped" then return end
	if getElementData(element, "ped:interact") ~= SKINS.pedInteract then return end

	if optionText == "Talk" then
		if optionData and optionData.interact and optionData.interact ~= SKINS.pedInteract then
			return
		end
		openSkinWindow(element)
	elseif optionText == "Add new skin" then
		openAddSkinWindow(true)
	end
end)
