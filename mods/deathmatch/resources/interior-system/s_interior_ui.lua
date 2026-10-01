-- ============================================================================
-- interior-system / s_interior_ui.lua                        (Fix #66)
-- ----------------------------------------------------------------------------
-- Server half of the old client's property panels, restored from
-- /home/daytona/backupm/[rp]/interior-system/int_c_decompiled.lua:
--
--   interior:onClientMarkerHit   (id, action, showPanel, name)  in-world hint
--   interior:onClientMarkerLeave ()
--   interior:openPurchaseWindow  (interior, marker, data)       "Purchase Property"
--   interior:openRentWindow      (interior, marker, data)       "Rent Property"
--   interior:openPanel           (interior, marker, owner, data, sellFactor)
--   interiors:checkint           (id, logs)                     "Check Interior"
--
-- and the client -> server side of the very same client:
--
--   interior:markerHit / interior:markerLeave   player reached an interior door
--   interior:panelRequest                       the old client's H key
--   interior:buyInterior / interior:rentInterior
--   interior:sellInterior                       "Sell property" on the panel
--   interior:previewInterior                    "Preview Interior"
--   /checkint <id>                              staff command of the old client
--
-- Systems completed here (the backup only kept the client, so these were
-- missing on this server):
--   * purchase price / purchase date / previous owner are stored
--     (interiors.purchaseprice / purchasedate / originalowner - Fix #66)
--   * enter / exit / lock / unlock are written to `interior_logs` with the
--     action tokens ENTER / EXIT / LOCK / UNLOCK, which is what the old
--     client's "Check Interior" window lists
--   * selling straight from the panel mirrors /sellproperty (same refund)
-- ============================================================================

local mysql = exports.mysql

local SELL_FACTOR = 2 / 3        -- /sellproperty refunds 2/3 of the price
local PANEL_RANGE = 12           -- how close to the door a player may use a panel
local CHECK_TYPES = { ENTER = true, EXIT = true, LOCK = true, UNLOCK = true }

local purchaseColumnsMissing = false

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function notify(player, en, ar, ntype)
	if isElement(player) then
		exports.notifications:outputToPlayer(player, { en = en, ar = ar }, 5000, ntype or "info")
	end
end

local function getInteriorByID(id)
	id = tonumber(id)
	if not id then return false end
	for _, interior in ipairs(getElementsByType("interior")) do
		if isElement(interior) and tonumber(getElementData(interior, "dbid")) == id then
			return interior
		end
	end
	return false
end

local function getAccountName(accountID)
	accountID = tonumber(accountID)
	if not accountID then return "-" end
	local name = exports.cache:getUsernameFromId(accountID)
	if type(name) == "string" and name ~= "" then return name end
	return "#" .. tostring(accountID)
end

local function getInteriorType(interior)
	local status = getElementData(interior, "status")
	if type(status) ~= "table" then return 2 end
	return tonumber(status[INTERIOR_TYPE]) or 2
end

-- players may open a panel while standing at the door or while inside
local function isNearInterior(player, interior)
	if not isElement(player) or not isElement(interior) then return false end
	local dbid = tonumber(getElementData(interior, "dbid")) or -1
	if getElementDimension(player) == dbid then return true end

	local px, py, pz = getElementPosition(player)
	for _, point in ipairs({ getElementData(interior, "entrance"), getElementData(interior, "exit") }) do
		if type(point) == "table" then
			if getDistanceBetweenPoints3D(px, py, pz, point[1], point[2], point[3]) <= PANEL_RANGE then
				return true
			end
		end
	end
	return false
end

-- the old client's address line: distance from the map origin + zone name
-- (global: s_interior_system.lua sends it with the Purchase/Rent window)
function interiorUiAddress(interior)
	local x, y, z = getElementPosition(interior)
	local number = math.floor(math.sqrt((x or 0) ^ 2 + (y or 0) ^ 2))
	return tostring(number) .. " " .. tostring(getZoneName(x or 0, y or 0, z or 0))
end

-- payload of the old client's "Purchase Property" / "Rent Property" window
function interiorUiWindowData(interior)
	local status = getElementData(interior, "status") or {}
	return {
		Name = tostring(getElementData(interior, "name") or "Interior"),
		Address = interiorUiAddress(interior),
		Price = tonumber(status[INTERIOR_COST]) or 0,
	}
end

local function interiorOwnerName(interior)
	local status = getElementData(interior, "status")
	if type(status) ~= "table" then return "-" end

	local owner = tonumber(status[INTERIOR_OWNER]) or 0
	if owner > 0 then
		local name = exports.cache:getCharacterNameFromID(owner)
		if type(name) == "string" and name ~= "" then return name end
		return "Character #" .. tostring(owner)
	end

	local faction = tonumber(status[INTERIOR_FACTION]) or 0
	if faction > 0 then
		local name = exports.cache:getFactionNameFromId(faction)
		if type(name) == "string" and name ~= "" then return name .. " (faction)" end
		return "Faction #" .. tostring(faction)
	end
	return "-"
end

local function canPlayerSeeInteriorID(player)
	return exports.integration:isPlayerTrialAdmin(player) and getElementData(player, "duty_admin") == 1
end

-- the old client showed the H hint for owned / for-sale properties only
local function canPlayerUsePanel(player, interior)
	if not isElement(interior) or getElementType(interior) ~= "interior" then return false end
	if getInteriorType(interior) ~= 2 then return true end
	return canPlayerSeeInteriorID(player) == true
end

local function interiorActionText(player, interior)
	if isInteriorForSale(interior) then
		if getInteriorType(interior) == 3 then
			return { en = "rent this property", ar = "استئجار هذا العقار" }
		end
		return { en = "purchase this property", ar = "شراء هذا العقار" }
	end
	return { en = "enter", ar = "الدخول" }
end

-- ---------------------------------------------------------------------------
-- interior_logs : ENTER / EXIT / LOCK / UNLOCK  (the Check Interior window)
-- ---------------------------------------------------------------------------
local function logInteriorAction(dbid, action, actor)
	dbid = tonumber(dbid)
	if not dbid or not action then return false end

	local accountID = isElement(actor) and getElementData(actor, "account:id") or nil
	local actorValue = accountID and ("'" .. mysql:escape_string(accountID) .. "'") or "NULL"
	return mysql:query_free("INSERT INTO `interior_logs` (`intID`, `action`, `actor`, `date`) VALUES ('" ..
		mysql:escape_string(dbid) .. "', '" .. mysql:escape_string(action) .. "', " .. actorValue .. ", NOW())")
end

local function collectCheckInteriorLogs(dbid)
	local logs = {}
	local rows = mysql:query_rows_assoc("SELECT `action`, `date`, `actor` FROM `interior_logs` WHERE `intID` = '" ..
		mysql:escape_string(tonumber(dbid) or 0) .. "' ORDER BY `log_id` DESC LIMIT 60")
	if type(rows) ~= "table" then return logs end

	for _, row in ipairs(rows) do
		local action = tostring(row.action or "")
		if CHECK_TYPES[action] and not logs[action] then
			logs[action] = { value = getAccountName(row.actor), time = tostring(row.date or "-") }
		end
	end
	return logs
end

-- ---------------------------------------------------------------------------
-- purchase data (Fix #66 columns) - degrades gracefully when not imported yet
-- ---------------------------------------------------------------------------
local function readPurchaseInfo(dbid)
	local row = mysql:query_fetch_assoc("SELECT `purchaseprice`, `purchasedate`, `originalowner` FROM `interiors` WHERE `id` = '" ..
		mysql:escape_string(tonumber(dbid) or 0) .. "' LIMIT 1")

	if type(row) ~= "table" then
		if not purchaseColumnsMissing then
			purchaseColumnsMissing = true
			outputDebugString("interior-system: interiors.purchaseprice / purchasedate / originalowner are missing - import mods/deathmatch/pdz_missing_tables.sql (Fix #66). The panel falls back to the listing price.", 2)
		end
		local fallback = mysql:query_fetch_assoc("SELECT `cost` FROM `interiors` WHERE `id` = '" .. mysql:escape_string(tonumber(dbid) or 0) .. "' LIMIT 1")
		local price = type(fallback) == "table" and tonumber(fallback.cost) or 0
		return { PurchasePrice = price or 0, PurchaseDate = false, OriginalOwner = false }
	end

	return {
		PurchasePrice = tonumber(row.purchaseprice) or 0,
		PurchaseDate = tonumber(row.purchasedate) or row.purchasedate or false,
		OriginalOwner = tonumber(row.originalowner) or row.originalowner or false,
	}
end

local function savePurchaseInfo(dbid, price, previousOwner)
	if purchaseColumnsMissing then return false end
	local ok = mysql:query_free("UPDATE `interiors` SET `purchaseprice` = '" .. (tonumber(price) or 0) ..
		"', `purchasedate` = NOW(), `originalowner` = '" .. (tonumber(previousOwner) or -1) ..
		"' WHERE `id` = '" .. mysql:escape_string(tonumber(dbid) or 0) .. "'")
	if not ok then
		purchaseColumnsMissing = true
		outputDebugString("interior-system: could not store the purchase price of interior #" .. tostring(dbid) .. " - import mods/deathmatch/pdz_missing_tables.sql (Fix #66).", 2)
	end
	return ok and true or false
end

local function previousOwnerName(charID)
	charID = tonumber(charID)
	if not charID or charID <= 0 then return false end
	local name = exports.cache:getCharacterNameFromID(charID)
	if type(name) == "string" and name ~= "" then return name end
	return "Character #" .. tostring(charID)
end

-- ---------------------------------------------------------------------------
-- interior:markerHit / markerLeave  ->  the old client's in-world hint
-- ---------------------------------------------------------------------------
addEvent("interior:markerHit", true)
addEventHandler("interior:markerHit", root, function(interior)
	if not isElement(client) or client ~= source then return end
	if not isElement(interior) or getElementType(interior) ~= "interior" then return end
	if not isNearInterior(client, interior) then return end

	local dbid = tonumber(getElementData(interior, "dbid"))
	triggerClientEvent(client, "interior:onClientMarkerHit", resourceRoot, dbid,
		interiorActionText(client, interior), canPlayerUsePanel(client, interior),
		tostring(getElementData(interior, "name") or "Interior"))
end)

addEvent("interior:markerLeave", true)
addEventHandler("interior:markerLeave", root, function(interior)
	if not isElement(client) or client ~= source then return end
	triggerClientEvent(client, "interior:onClientMarkerLeave", resourceRoot)
end)

-- ---------------------------------------------------------------------------
-- interior:panelRequest  (the old client's H key -> "Property Panel")
-- ---------------------------------------------------------------------------
addEvent("interior:panelRequest", true)
addEventHandler("interior:panelRequest", root, function(interior)
	if not isElement(client) or client ~= source then return end
	if not isElement(interior) or getElementType(interior) ~= "interior" then return end
	if not isNearInterior(client, interior) then
		notify(client, "You are too far away from this property.", "أنت بعيد جداً عن هذا العقار.", "error")
		return
	end
	if not canPlayerUsePanel(client, interior) then
		notify(client, "This is a government property.", "هذا العقار حكومي.", "error")
		return
	end

	local dbid = tonumber(getElementData(interior, "dbid"))
	local status = getElementData(interior, "status") or {}
	local purchase = readPurchaseInfo(dbid)
	local type_ = tonumber(status[INTERIOR_TYPE]) or 2
	local owner = tonumber(status[INTERIOR_OWNER]) or 0
	local cost = tonumber(status[INTERIOR_COST]) or 0

	local data = {
		OriginalPrice = cost,
		PurchasePrice = purchase.PurchasePrice,
		PurchaseDate = purchase.PurchaseDate,
		OriginalOwner = purchase.OriginalOwner and previousOwnerName(purchase.OriginalOwner) or false,
		Address = interiorUiAddress(interior),
		Owner = interiorOwnerName(interior),
		Renter = (type_ == 3 and owner > 0) and interiorOwnerName(interior) or false,
		-- what /sellproperty will really pay (the old client multiplied the
		-- purchase price by the factor the server sent)
		SellPrice = math.ceil(cost * SELL_FACTOR),
		CanSell = (owner > 0 and owner == tonumber(getElementData(client, "dbid")))
			or (tonumber(status[INTERIOR_FACTION]) > 0 and tonumber(status[INTERIOR_FACTION]) == tonumber(getElementData(client, "faction"))
				and tonumber(getElementData(client, "factionleader")) > 0) or false,
	}

	triggerClientEvent(client, "interior:openPanel", resourceRoot, interior, false, interiorOwnerName(interior), data, SELL_FACTOR)
end)

-- ---------------------------------------------------------------------------
-- interior:buyInterior / interior:rentInterior
--   the old client had a single "Purchase" button (no payment picker), so a
--   purchase first tries the player's pocket and then his bank account which
--   is exactly what the two classic flows (buypropertywithcash / withbank) do.
--   Faction leaders keep the old payment picker so faction purchases stay
--   possible.
-- ---------------------------------------------------------------------------
local function startPurchase(player, interior, isRentable)
	local dbid = tonumber(getElementData(interior, "dbid"))
	local status = getElementData(interior, "status") or {}
	local cost = tonumber(status[INTERIOR_COST]) or 0
	local type_ = tonumber(status[INTERIOR_TYPE]) or 2
	local isHouse = (type_ == 0 or type_ == 3)
	local previousOwner = tonumber(status[INTERIOR_OWNER]) or -1
	local myChar = tonumber(getElementData(player, "dbid"))

	if tonumber(getElementData(player, "factionleader")) > 0 and tonumber(getElementData(player, "faction")) > 0 then
		-- keep the classic cash / bank / faction choice for faction leaders
		triggerClientEvent(player, "openPropertyGUI", player, interior, cost, isHouse, isRentable, interiorUiAddress(interior))
		return
	end

	if exports.global:getMoney(player) >= cost then
		buyInteriorCash(player, interior, cost, isHouse, isRentable)
	else
		buyInteriorBank(player, interior, cost, isHouse, isRentable)
	end

	-- the classic handlers call realReloadInterior(), which destroys and
	-- recreates the interior element - so confirm the purchase in the database
	local row = mysql:query_fetch_assoc("SELECT `owner` FROM `interiors` WHERE `id` = '" .. mysql:escape_string(dbid) .. "' LIMIT 1")
	if type(row) == "table" and tonumber(row.owner) == myChar then
		savePurchaseInfo(dbid, cost, previousOwner)
		triggerClientEvent(player, "interior:closeWindows", resourceRoot)
	end
end

addEvent("interior:buyInterior", true)
addEventHandler("interior:buyInterior", root, function(id)
	if not isElement(client) or client ~= source then return end
	local interior = getInteriorByID(id)
	if not interior or not isNearInterior(client, interior) then return end
	if not isInteriorForSale(interior) then
		notify(client, "This property is not for sale.", "هذا العقار ليس للبيع.", "error")
		return
	end
	startPurchase(client, interior, false)
end)

addEvent("interior:rentInterior", true)
addEventHandler("interior:rentInterior", root, function(id)
	if not isElement(client) or client ~= source then return end
	local interior = getInteriorByID(id)
	if not interior or not isNearInterior(client, interior) then return end
	if not isInteriorForSale(interior) then
		notify(client, "This property is not for rent.", "هذا العقار ليس للإيجار.", "error")
		return
	end
	startPurchase(client, interior, true)
end)

-- ---------------------------------------------------------------------------
-- interior:sellInterior  ("Sell property" on the Property Panel)
--   mirrors /sellproperty: same ownership check, same 2/3 refund.
-- ---------------------------------------------------------------------------
addEvent("interior:sellInterior", true)
addEventHandler("interior:sellInterior", root, function(id)
	if not isElement(client) or client ~= source then return end
	local interior = getInteriorByID(id)
	if not interior then return end
	if not isNearInterior(client, interior) then return end

	local status = getElementData(interior, "status") or {}
	local owner = tonumber(status[INTERIOR_OWNER]) or 0
	local faction = tonumber(status[INTERIOR_FACTION]) or 0
	local myChar, myFaction = tonumber(getElementData(client, "dbid")), tonumber(getElementData(client, "faction")) or -1

	local isOwner = owner > 0 and owner == myChar
	local isFactionOwner = faction > 0 and faction == myFaction and tonumber(getElementData(client, "factionleader")) > 0
	if not (isOwner or isFactionOwner) then
		notify(client, "You do not own this property.", "أنت لا تملك هذا العقار.", "error")
		return
	end

	local dbid = tonumber(getElementData(interior, "dbid"))
	publicSellProperty(client, dbid, true, true, false)
	cleanupProperty(dbid, true)
	exports.logs:dbLog(client, 37, { "in" .. tostring(dbid) }, "SELLPROPERTY " .. tostring(dbid))
	logInteriorAction(dbid, "SELL", client)
	triggerClientEvent(client, "interior:closeWindows", resourceRoot)
end)

-- ---------------------------------------------------------------------------
-- interior:previewInterior  ("Preview Interior")
--   the classic 60 second timed viewing already existed server side.
-- ---------------------------------------------------------------------------
addEvent("interior:previewInterior", true)
addEventHandler("interior:previewInterior", root, function(id)
	if not isElement(client) or client ~= source then return end
	local dbid = tonumber(id)
	if not dbid then return end
	timedInteriorView(client, dbid)
end)

-- ---------------------------------------------------------------------------
-- /checkint <id>  -  the old client's "Check Interior" window
-- ---------------------------------------------------------------------------
addCommandHandler("checkint", function(player, command, id)
	if not exports.integration:isPlayerTrialAdmin(player) then
		outputChatBox("You are not allowed to check interiors.", player, 255, 0, 0)
		return
	end

	id = tonumber(id)
	if not id then
		local dbid = findProperty(player)
		id = tonumber(dbid)
	end
	if not id or id <= 0 then
		outputChatBox("Usage: /checkint <interior id>", player, 255, 0, 0)
		return
	end

	triggerClientEvent(player, "interiors:checkint", resourceRoot, id, collectCheckInteriorLogs(id))
end)

-- ---------------------------------------------------------------------------
-- the missing log writes: ENTER / EXIT (interior:enter) and LOCK / UNLOCK
-- ---------------------------------------------------------------------------
addEventHandler("interior:enter", root, function()
	if not isElement(client) or client ~= source then return end
	local interior = source
	if getElementType(interior) ~= "interior" then return end

	local dbid = tonumber(getElementData(interior, "dbid"))
	local entrance, exit = getElementData(interior, "entrance"), getElementData(interior, "exit")
	if not dbid or type(entrance) ~= "table" or type(exit) ~= "table" then return end

	-- same decision the teleport makes: standing on the outside door means the
	-- player is going in, standing inside means he is leaving
	local goingIn = tonumber(entrance[INTERIOR_DIM]) == getElementDimension(client)
	local expected = tonumber(goingIn and exit[INTERIOR_DIM] or entrance[INTERIOR_DIM])
	local action = goingIn and "ENTER" or "EXIT"

	setTimer(function(targetPlayer, interiorID, expectedDim, actionName)
		if isElement(targetPlayer) and getElementDimension(targetPlayer) == expectedDim then
			logInteriorAction(interiorID, actionName, targetPlayer)
		end
	end, 2000, 1, client, dbid, expected, action)
end)

-- the door the player locked must be the closest one (the classic key flow
-- finds it the same way: a point of an interior within 5m in his dimension)
local function nearestDoorInterior(player)
	local dimension = getElementDimension(player)
	local px, py, pz = getElementPosition(player)
	local best, bestDistance = false, 5

	for _, interior in ipairs(getElementsByType("interior")) do
		if isElement(interior) then
			for _, point in ipairs({ getElementData(interior, "entrance"), getElementData(interior, "exit") }) do
				if type(point) == "table" and tonumber(point[INTERIOR_DIM]) == dimension then
					local distance = getDistanceBetweenPoints3D(px, py, pz, point[1], point[2], point[3]) or 20
					if distance < bestDistance then
						best, bestDistance = interior, distance
					end
				end
			end
		end
	end
	return best
end

local function logLockState(player, interior)
	if not isElement(player) or not isElement(interior) then return end
	local dbid = tonumber(getElementData(interior, "dbid"))
	if not dbid then return end

	setTimer(function(targetPlayer, interiorID)
		local row = mysql:query_fetch_assoc("SELECT `locked` FROM `interiors` WHERE `id` = '" .. mysql:escape_string(interiorID) .. "' LIMIT 1")
		if type(row) == "table" then
			logInteriorAction(interiorID, tonumber(row.locked) == 1 and "LOCK" or "UNLOCK", targetPlayer)
		end
	end, 700, 1, player, dbid)
end

addEventHandler("lockUnlockHouseID", root, function(id)
	if isElement(source) then
		logLockState(source, getInteriorByID(id))
	end
end)

addEventHandler("lockUnlockHouse", root, function(player)
	local opener = isElement(player) and player or (isElement(source) and source)
	if not isElement(opener) then return end
	local interior = nearestDoorInterior(opener)
	if interior then
		logLockState(opener, interior)
	end
end)
