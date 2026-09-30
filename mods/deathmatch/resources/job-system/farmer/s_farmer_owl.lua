-- owlbakeup Fix #63 - Farmer SERVER, rebuilt from the client contract
-- ([jobs]/farmer/farmer_c_decompiled.lua + config, drug-dealer family):
--   farmer:plant(name, model, x, y, z)   -> plant:<uid>:<type> object (the
--     client label reads split(":")[3] as the type, harvest sends
--     split(":")[2] as the uid), grow_duration from the verbatim config.
--   farmer:harvest(uid)                  -> owner + distance gates, crops
--     into the inventory (Carrot #235 / Corn #236), callback.
--   farmer:sell                          -> crops counted + paid by the
--     verbatim plant_info sell prices, sold_at log, callback.
--   farm site RECONSTRUCTED at Blueberry Acres (the verbatim farms list is
--     empty) - a field marker with right-click Plant options triggers
--     farmer:startFarming (the Owl seeds-shop flow is lost with the dump).
-- The decompile has no givePlayerJobEXP call - the job earns by selling.

local mysql = exports.mysql

local plants = {} -- [uid] = { object, type, x, y, z, owner, growTimer, markerTimer, ready }
local plantUID = 0

local FARM_FIELD = { -378.5, -1051.9, 59.3 } -- reconstructed (Blueberry Acres)

local function buildSyncList()
	local list = {}
	for uid, plant in pairs(plants) do
		if plant.ready then
			table.insert(list, { plant.object, { plant.x, plant.y, plant.z } })
		end
	end
	return list
end

local function makePlantReady(uid)
	local plant = plants[uid]
	if not plant or plant.ready then
		return
	end
	plant.ready = true
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "loggedin") == 1 then
			triggerClientEvent(player, "farmer:createPlantMarker", player, plant.x, plant.y, plant.z, plant.object)
		end
	end
end

addEvent("farmer:plant", true)
addEventHandler("farmer:plant", root, function(name, model, x, y, z)
	local player = client
	if not player or getElementData(player, "loggedin") ~= 1 then
		return
	end
	if getElementData(player, "job") ~= "Farmer" then
		return
	end
	if not (tonumber(x) and tonumber(y) and tonumber(z)) then
		return
	end
	local config = plant_types[name]
	if not config or config.model ~= tonumber(model) then
		return
	end
	for uid, plant in pairs(plants) do
		if plant.owner == player then
			return
		end
	end
	plantUID = plantUID + 1
	local uid = plantUID
	local obj = createObject(config.model, x, y, z)
	if not obj then
		return
	end
	setElementID(obj, "plant:" .. uid .. ":" .. name)
	setElementFrozen(obj, true)
	plants[uid] = {
		object = obj,
		type = name,
		x = x,
		y = y,
		z = z,
		owner = player,
		ready = false
	}
	plants[uid].growTimer = setTimer(makePlantReady, (grow_duration[name] or 240) * 1000, 1, uid)
	exports.notifications:outputToPlayer(player, "تم زرع البذور - انتظر حتى ينمو ثم اضغط H", 5000, "info")
end)

addEvent("farmer:harvest", true)
addEventHandler("farmer:harvest", root, function(uid)
	local player = client
	if not player or not tonumber(uid) then
		return
	end
	local plant = plants[tonumber(uid)]
	if not plant or not plant.ready or plant.owner ~= player then
		triggerClientEvent(player, "farmer:harvest:callback", player, false)
		return
	end
	local px, py, pz = getElementPosition(player)
	local ox, oy, oz = getElementPosition(plant.object)
	if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) > 5 then
		triggerClientEvent(player, "farmer:harvest:callback", player, false)
		return
	end
	exports["item-system"]:giveItem(player, CROP_ITEM_IDS[plant.type], 1)
	exports.notifications:outputToPlayer(player, "حصدت محصولك", 5000, "success")
	if isTimer(plant.growTimer) then
		killTimer(plant.growTimer)
	end
	destroyElement(plant.object)
	plants[tonumber(uid)] = nil
	triggerClientEvent(player, "farmer:harvest:callback", player, true)
end)

addEvent("farmer:sell", true)
addEventHandler("farmer:sell", root, function()
	local player = client
	if not player or getElementData(player, "loggedin") ~= 1 then
		return
	end
	local characterID = tonumber(getElementData(player, "character:id"))
	if not characterID then
		return
	end
	local items = exports["item-system"]:getItems(player)
	if type(items) ~= "table" then
		triggerClientEvent(player, "farmer:sell:callback", player)
		return
	end
	local total = 0
	for cropName, itemID in pairs(CROP_ITEM_IDS) do
		local count = 0
		for _, value in ipairs(items) do
			if tonumber(value[1]) == itemID then
				count = count + 1
			end
		end
		for _ = 1, count do
			if exports["item-system"]:takeItem(player, itemID) then
				total = total + (plant_info[cropName].sell_price or 0)
			end
		end
	end
	if total > 0 then
		exports.global:giveMoney(player, total)
		mysql:query_free("INSERT INTO farmer_sales (character_id, paid, sold_at) VALUES (" .. characterID .. ", " .. total .. ", '" .. os.date("%Y-%m-%d %H:%M:%S") .. "')")
		exports.notifications:outputToPlayer(player, "بعت محاصيلك بمبلغ $" .. total, 5000, "success")
	end
	triggerClientEvent(player, "farmer:sell:callback", player)
end)

-- login sync for grown plants
addEventHandler("onElementDataChange", root, function(key)
	if key ~= "loggedin" or getElementType(source) ~= "player" then
		return
	end
	if getElementData(source, "loggedin") == 1 then
		setTimer(function(player)
			if isElement(player) and getElementData(player, "loggedin") == 1 then
				triggerClientEvent(player, "farmer:syncPlantsMarkers", player, buildSyncList())
			end
		end, 2500, 1, source)
	end
end)

addEventHandler("onPlayerQuit", root, function()
	for uid, plant in pairs(plants) do
		if plant.owner == source then
			if isTimer(plant.growTimer) then
				killTimer(plant.growTimer)
			end
			if isElement(plant.object) then
				destroyElement(plant.object)
			end
			plants[uid] = nil
		end
	end
end)

-- field marker right-click -> the client's farmer:startFarming gates
addEventHandler("onClientElementMenuClick:Server", root, function(element, optionText)
	local player = client
	if not player or not isElement(element) then
		return
	end
	if getElementData(element, "farmer:field") then
		for cropName, _ in pairs(plant_types) do
			if optionText == "Plant " .. cropName then
				triggerClientEvent(player, "farmer:startFarming", player, cropName)
			end
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	mysql:query_free([[
		CREATE TABLE IF NOT EXISTS farmer_sales (
			id INT AUTO_INCREMENT PRIMARY KEY,
			character_id INT NOT NULL,
			paid INT NOT NULL DEFAULT 0,
			sold_at VARCHAR(32) NOT NULL DEFAULT ''
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]])
	-- reconstructed field marker at the farm site
	local marker = createMarker(FARM_FIELD[1], FARM_FIELD[2], FARM_FIELD[3] - 0.7, "cylinder", 2.5, 7, 181, 54, 100)
	if marker then
		setElementData(marker, "farmer:field", true)
		setElementData(marker, "rightclick:title", "Farm field")
		local options = {}
		for cropName, _ in pairs(plant_types) do
			table.insert(options, { Text = "Plant " .. cropName })
		end
		setElementData(marker, "rightclick:menu", options)
	end
end)
