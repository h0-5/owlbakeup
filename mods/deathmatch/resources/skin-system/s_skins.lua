-- ============================================================================
-- skin-system / s_skins.lua                      (Fix #65)
-- ----------------------------------------------------------------------------
-- Server half of the old Owl client's player-skin shop ("Fashion Dupont").
-- The backup only kept the client (backupm/[rp]/skin-system/skin_c_decompiled.lua),
-- so the handlers below reproduce the exact event surface that client talks to:
--
--   skins:getSkinsDatabase           ()                                  -> sendDatabase
--   skins:buySkin                    (id, shopPed)
--   skins:addNewSkin                 (skinID, description, url, price, private, isAddForShop)
--   skins:updateSkin                 (id, skinID, description, url, price, private)
--   skins:removeSkin                 (id)
--
-- The catalogue is the `clothing` table (clothing shop + item/texture pipeline
-- already read it).  Fix #65 adds the old client's two extra fields:
-- `private` (0/1) and `owner` (character id).  A purchase is handed out as
-- item 16 ("Clothes", value "skin:clothing.id") so wearing it goes through the
-- existing pipeline: setElementModel + `clothing:id` + the replacement shader.
-- ============================================================================

local mysql = exports.mysql

local CLOTHES_ITEM = 16
local MAX_DESCRIPTION = 96
local MAX_URL = 255

local catalogue = {}         -- [id] = { ID, SkinID, Description, Skin_URL, Price, private, Owner }
local hasPrivateColumns = false

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function notify(player, en, ar, ntype)
	if isElement(player) then
		exports.notifications:outputToPlayer(player, { en = en, ar = ar }, 4000, ntype or "info")
	end
end

local function getCharID(player)
	return tonumber(getElementData(player, "dbid"))
		or tonumber(getElementData(player, "character:id"))
		or tonumber(getElementData(player, "account:character:id"))
		or -1
end

function canManageSkins(player)
	if not isElement(player) then return false end
	if exports.integration:isPlayerScripter(player) then return true end
	local username = getElementData(player, "account:username")
	return username ~= nil and SKINS.shopOwners[tostring(username)] == true
end

-- the old client only accepted http(s) links ending in .png without a query
local function isValidSkinURL(url)
	if type(url) ~= "string" or #url < 8 or #url > MAX_URL then return false end
	local plain = string.gsub(url, "https", "http")
	return string.sub(plain, 1, 7) == "http://"
		and string.lower(string.sub(plain, -4)) == ".png"
		and not string.find(plain, "?", 1, true)
end

-- one purchase per 700ms per player (a double click used to charge twice)
local lastPurchase = {}
local function throttle(player)
	local now = getTickCount()
	if lastPurchase[player] and now - lastPurchase[player] < 700 then return false end
	lastPurchase[player] = now
	return true
end
addEventHandler("onPlayerQuit", root, function() lastPurchase[source] = nil end)

-- the player must still be standing next to the shop ped the window came from
local function isNearShopPed(player, ped)
	if not isElement(ped) or getElementType(ped) ~= "ped" then return true end
	if getElementData(ped, "ped:interact") ~= SKINS.pedInteract then return false end
	return getDistanceBetweenPoints3D(getElementPosition(player), getElementPosition(ped)) <= (SKINS.talkDistance + 2)
end

-- ---------------------------------------------------------------------------
-- catalogue
-- ---------------------------------------------------------------------------
function loadSkinCatalogue()
	catalogue = {}
	local rows = mysql:query_rows_assoc("SELECT `id`, `skin`, `url`, `description`, `price`, `private`, `owner` FROM `" .. SKINS.table .. "`")
	hasPrivateColumns = type(rows) == "table"
	if not hasPrivateColumns then
		outputDebugString("skin-system: clothing.private / clothing.owner are missing - import mods/deathmatch/pdz_missing_tables.sql (Fix #65)", 2)
		rows = mysql:query_rows_assoc("SELECT `id`, `skin`, `url`, `description`, `price` FROM `" .. SKINS.table .. "`") or {}
	end

	local count = 0
	for _, row in ipairs(rows) do
		local id = tonumber(row.id)
		if id then
			catalogue[id] = {
				ID = id,
				SkinID = tonumber(row.skin) or 0,
				Description = tostring(row.description or ""),
				Skin_URL = tostring(row.url or ""),
				Price = tonumber(row.price) or 0,
				private = tonumber(row.private) or 0,
				Owner = tonumber(row.owner) or 0,
			}
			count = count + 1
		end
	end
	return count
end

function getSkinCatalogue()
	local list = {}
	for _, entry in pairs(catalogue) do
		list[#list + 1] = entry
	end
	table.sort(list, function(a, b) return a.ID < b.ID end)
	return list
end

function getSkin(id)
	return catalogue[tonumber(id) or -1]
end

addEventHandler("onResourceStart", resourceRoot, function()
	local count = loadSkinCatalogue()
	outputDebugString("skin-system: loaded " .. tostring(count) .. " skins")
end)

-- ---------------------------------------------------------------------------
-- skins:getSkinsDatabase -> skins:sendSkinsDatabaseToClient
-- ---------------------------------------------------------------------------
addEvent(SKINS.events.getDatabase, true)
addEventHandler(SKINS.events.getDatabase, root, function()
	if not isElement(client) or client ~= source then return end
	triggerClientEvent(client, SKINS.events.sendDatabase, resourceRoot, getSkinCatalogue())
end)

-- ---------------------------------------------------------------------------
-- skins:addNewSkin / skins:updateSkin / skins:removeSkin
-- ---------------------------------------------------------------------------
addEvent(SKINS.events.add, true)
addEventHandler(SKINS.events.add, root, function(skinID, description, url, price, private, isAddForShop)
	if not isElement(client) or client ~= source then return end

	skinID = tonumber(skinID)
	price = tonumber(price)
	description = tostring(description or "")
	url = tostring(url or "")
	private = private and 1 or 0

	if isAddForShop and not canManageSkins(client) then
		notify(client, "You are not allowed to add skins to the shop.", "لا يمكنك إضافة سكنات للمتجر.", "error")
		return
	end
	if not skinID or skinID <= 0 then
		notify(client, "Invalid skin id.", "رقم السكن غير صحيح.", "error")
		return
	end
	if price == nil or price < 0 or (isAddForShop and price <= 0) then
		notify(client, "Invalid price.", "السعر غير صحيح.", "error")
		return
	end
	if #description == 0 or #description > MAX_DESCRIPTION then
		notify(client, "Invalid description.", "الوصف غير صحيح.", "error")
		return
	end
	if not isValidSkinURL(url) then
		notify(client, "Error: invalid image URL (must be a .png link).", "خطأ: رابط الصورة غير صحيح (يجب أن يكون رابط .png).", "error")
		return
	end

	-- the `clothing` table of this schema has no AUTO_INCREMENT, so the next id
	-- is picked explicitly (also safe when it does have one)
	local nextRow = mysql:query_fetch_assoc("SELECT IFNULL(MAX(`id`), 0) + 1 AS `next` FROM `" .. SKINS.table .. "`") or {}
	local id = tonumber(nextRow.next)
	if not id then
		notify(client, "Unable to add the skin.", "تعذر إضافة السكن.", "error")
		return
	end

	local columns, values = "`id`, `skin`, `url`, `description`, `price`",
		id .. ", " .. skinID .. ", '" .. mysql:escape_string(url) .. "', '" .. mysql:escape_string(description) .. "', " .. price
	if hasPrivateColumns then
		columns = columns .. ", `private`, `owner`"
		values = values .. ", " .. private .. ", " .. getCharID(client)
	end

	if not mysql:query_free("INSERT INTO `" .. SKINS.table .. "` (" .. columns .. ") VALUES (" .. values .. ")") then
		notify(client, "Unable to add the skin.", "تعذر إضافة السكن.", "error")
		return
	end

	catalogue[id] = {
		ID = id,
		SkinID = skinID,
		Description = description,
		Skin_URL = url,
		Price = price,
		private = private,
		Owner = getCharID(client),
	}

	outputChatBox("Skin added with id " .. tostring(id) .. ".", client, 0, 255, 0)
	exports.logs:dbLog(client, 4, { client }, "SKINS ADD " .. tostring(id) .. " MODEL " .. tostring(skinID) .. " PRICE " .. tostring(price) .. " PRIVATE " .. tostring(private))
	triggerClientEvent(client, SKINS.events.sendDatabase, resourceRoot, getSkinCatalogue())
end)

addEvent(SKINS.events.update, true)
addEventHandler(SKINS.events.update, root, function(id, skinID, description, url, price, private)
	if not isElement(client) or client ~= source then return end

	id = tonumber(id)
	local existing = id and catalogue[id]
	if not existing then
		notify(client, "Unable to find that skin.", "لم يتم العثور على هذا السكن.", "error")
		return
	end
	if existing.Owner ~= getCharID(client) and not canManageSkins(client) then
		notify(client, "That is not your skin.", "هذا السكن ليس لك.", "error")
		return
	end

	skinID = tonumber(skinID) or existing.SkinID
	price = tonumber(price)
	description = tostring(description or "")
	private = private and 1 or 0

	if price == nil or price < 0 then
		notify(client, "Invalid price.", "السعر غير صحيح.", "error")
		return
	end
	if #description == 0 or #description > MAX_DESCRIPTION then
		notify(client, "Invalid description.", "الوصف غير صحيح.", "error")
		return
	end

	local sets = {
		"`skin` = " .. skinID,
		"`description` = '" .. mysql:escape_string(description) .. "'",
		"`price` = " .. price,
	}
	if hasPrivateColumns then
		sets[#sets + 1] = "`private` = " .. private
	end

	if not mysql:query_free("UPDATE `" .. SKINS.table .. "` SET " .. table.concat(sets, ", ") .. " WHERE `id` = " .. id) then
		notify(client, "The skin could not be saved.", "تعذر حفظ السكن.", "error")
		return
	end

	existing.SkinID = skinID
	existing.Description = description
	existing.Price = price
	existing.private = private

	outputChatBox("Saved skin #" .. tostring(id) .. ".", client, 0, 255, 0)
	exports.logs:dbLog(client, 4, { client }, "SKINS SAVE " .. tostring(id))
	triggerClientEvent(client, SKINS.events.sendDatabase, resourceRoot, getSkinCatalogue())
end)

addEvent(SKINS.events.remove, true)
addEventHandler(SKINS.events.remove, root, function(id)
	if not isElement(client) or client ~= source then return end

	id = tonumber(id)
	local existing = id and catalogue[id]
	if not existing then return end
	if existing.Owner ~= getCharID(client) and not canManageSkins(client) then
		notify(client, "That is not your skin.", "هذا السكن ليس لك.", "error")
		return
	end

	if not mysql:query_free("DELETE FROM `" .. SKINS.table .. "` WHERE `id` = " .. id) then
		notify(client, "Unable to remove the skin.", "تعذر حذف السكن.", "error")
		return
	end

	catalogue[id] = nil
	outputChatBox("Skin #" .. tostring(id) .. " removed.", client, 0, 255, 0)
	exports.logs:dbLog(client, 4, { client }, "SKINS REMOVE " .. tostring(id))
	triggerClientEvent(client, SKINS.events.sendDatabase, resourceRoot, getSkinCatalogue())
end)

-- ---------------------------------------------------------------------------
-- skins:buySkin
-- ---------------------------------------------------------------------------
addEvent(SKINS.events.buy, true)
addEventHandler(SKINS.events.buy, root, function(id, shopPed)
	if not isElement(client) or client ~= source then return end

	id = tonumber(id)
	local entry = id and catalogue[id]
	if not entry then return end

	if entry.private == 1 and entry.Owner ~= getCharID(client) and not canManageSkins(client) then
		notify(client, "This skin is private.", "هذا السكن خاص.", "error")
		return
	end
	if not isNearShopPed(client, shopPed) then
		notify(client, "You moved away from the shop.", "لقد ابتعدت عن المتجر.", "error")
		return
	end
	if not throttle(client) then return end

	if not exports.global:hasMoney(client, entry.Price) then
		notify(client, "You do not have the required $" .. exports.global:formatMoney(entry.Price) .. ".",
			"لا تملك المبلغ المطلوب $" .. exports.global:formatMoney(entry.Price) .. ".", "error")
		return
	end
	-- hand out the clothes first: a full inventory must not be charged
	if not exports.global:giveItem(client, CLOTHES_ITEM, entry.SkinID .. ":" .. entry.ID) then
		notify(client, "You do not have enough space in your inventory.", "لا يوجد مساحة كافية في حقيبتك.", "error")
		return
	end

	exports.global:takeMoney(client, entry.Price)
	notify(client, "You purchased some clothing for $" .. exports.global:formatMoney(entry.Price) .. ".",
		"لقد اشتريت سكناً بمبلغ $" .. exports.global:formatMoney(entry.Price) .. ".")
	exports.logs:dbLog(client, 4, { client }, "SKINS BUY " .. tostring(entry.ID) .. " FOR $" .. tostring(entry.Price))
end)

-- ---------------------------------------------------------------------------
-- old client's `skins:showAddSkinWindow` (players adding their own skin)
-- ---------------------------------------------------------------------------
function openSkinAddWindow(player, forShop)
	if isElement(player) then
		triggerClientEvent(player, SKINS.events.showAddWindow, resourceRoot, forShop and true or false)
	end
end
