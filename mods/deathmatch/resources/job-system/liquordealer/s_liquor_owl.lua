-- owlbakeup Fix #63 - Drug Dealer job SERVER, rebuilt from the client
-- contract ([jobs]/liquor-dealer/client_decompiled.lua + config, Fix #54
-- phone pattern):
--   liquor_dealer:takeJob                      -> take the job at the ped
--   liquor_dealer:plant(name, model, x, y, z)  -> create plant:<id> object +
--                                               grow timer; when grown every
--                                               client gets createPlantMarker
--   liquor_dealer:harvest(plantID)             -> validate + give Marijuana
--                                               (item #38, 1 gram) + destroy
--                                               + harvest:callback
--   liquor_dealer:syncPlantsMarkers(plants)    -> login sync of grown plants
--   crafting_markers (config) -> server-side cylinder markers carrying the
--   "liquor:crafting" elementData the client's marker-leave contract reads;
--   right-click on them offers "Plant <type>" (the Owl craft UI resource was
--   lost with the dump - the interaction menu is the reconstructed trigger
--   for liquor_dealer:startFarming, no new UI invented).
-- The decompile has no givePlayerJobEXP/giveJobSalary call for this job.

local mysql = exports.mysql

local GROW_TIME_MS = 10 * 60000 -- 10 minutes to full growth
local PLANT_LIFETIME_MS = 30 * 60000 -- wilt + despawn 30 min after growth

local function harvestItemID(plantType)
	if plantType == "Blueberry" then
		return 217
	end
	return 216 -- Grapes
end

local plants = {} -- [uid] = { object, type, x, y, z, owner, growTimer, markerTimer, ready }
local plantUID = 0

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
			triggerClientEvent(player, "liquor_dealer:createPlantMarker", player, plant.x, plant.y, plant.z, plant.object)
		end
	end
	plant.markerTimer = setTimer(function()
		local plant = plants[uid]
		if not plant then
			return
		end
		if isElement(plant.object) then
			destroyElement(plant.object)
		end
		plants[uid] = nil
	end, PLANT_LIFETIME_MS, 1)
end

addEvent("liquor_dealer:takeJob", true)
addEventHandler("liquor_dealer:takeJob", root, function()
	local player = client
	if not player or getElementData(player, "loggedin") ~= 1 then
		return
	end
	local characterID = tonumber(getElementData(player, "character:id"))
	if not characterID or getElementData(player, "job") then
		return
	end
	local today = os.date("%Y-%m-%d %H:%M:%S")
	mysql:query_free("UPDATE character_jobs SET is_current = 0 WHERE character_id = " .. characterID)
	local existing = mysql:query_fetch_assoc("SELECT id FROM character_jobs WHERE character_id = " .. characterID .. " AND job_code = 'liquor_dealer' LIMIT 1")
	if existing then
		mysql:query_free("UPDATE character_jobs SET is_current = 1 WHERE id = " .. tonumber(existing.id))
	else
		mysql:query_free("INSERT INTO character_jobs (character_id, job_code, exp, first_work, last_work, total_salary, is_current) VALUES (" .. characterID .. ", 'liquor_dealer', 0, '" .. today .. "', '" .. today .. "', 0, 1)")
	end
	exports.anticheat:changeProtectedElementDataEx(player, "job", "Liquor Dealer", true)
	triggerClientEvent(player, "onClientPlayerStartJob", player, "Liquor Dealer")
	exports.notifications:outputToPlayer(player, "تم تعيينك في وظيفة تاجر الخمور - زرع في كروم الجبل", 5000, "info")
end)

addEvent("liquor_dealer:plant", true)
addEventHandler("liquor_dealer:plant", root, function(name, model, x, y, z)
	local player = client
	if not player or getElementData(player, "loggedin") ~= 1 then
		return
	end
	if getElementData(player, "job") ~= "Liquor Dealer" then
		return
	end
	if not (tonumber(x) and tonumber(y) and tonumber(z)) then
		return
	end
	-- validate against the config the decompile shipped
	local config = plant_types[name]
	if not config or config.model ~= tonumber(model) then
		return
	end
	-- one living plant per player
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
	if config.scale then
		setObjectScale(obj, config.scale)
	end
	setElementID(obj, "plant:" .. uid)
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
	plants[uid].growTimer = setTimer(makePlantReady, GROW_TIME_MS, 1, uid)
	exports.notifications:outputToPlayer(player, "تم زرع البذور - انتظر حتى تنمو ثم اضغط H", 5000, "info")
end)

addEvent("liquor_dealer:harvest", true)
addEventHandler("liquor_dealer:harvest", root, function(plantID)
	local player = client
	if not player or not tonumber(plantID) then
		return
	end
	local plant = plants[tonumber(plantID)]
	if not plant or not plant.ready then
		triggerClientEvent(player, "liquor_dealer:harvest:callback", player, false)
		return
	end
	if plant.owner ~= player then
		triggerClientEvent(player, "liquor_dealer:harvest:callback", player, false)
		return
	end
	local px, py, pz = getElementPosition(player)
	local ox, oy, oz = getElementPosition(plant.object)
	if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) > 5 then
		triggerClientEvent(player, "liquor_dealer:harvest:callback", player, false)
		return
	end
	exports["item-system"]:giveItem(player, harvestItemID(plant.type), "1") -- Grapes/Blueberries, 1 unit
	exports.notifications:outputToPlayer(player, "حصدت محصولك", 5000, "success")
	if isTimer(plant.growTimer) then
		killTimer(plant.growTimer)
	end
	if isTimer(plant.markerTimer) then
		killTimer(plant.markerTimer)
	end
	destroyElement(plant.object)
	plants[tonumber(plantID)] = nil
	triggerClientEvent(player, "liquor_dealer:harvest:callback", player, true)
end)

-- login sync: grown plants get their harvest markers back after a relog
addEventHandler("onElementDataChange", root, function(key)
	if key ~= "loggedin" or getElementType(source) ~= "player" then
		return
	end
	if getElementData(source, "loggedin") == 1 then
		setTimer(function(player)
			if isElement(player) and getElementData(player, "loggedin") == 1 then
				triggerClientEvent(player, "liquor_dealer:syncPlantsMarkers", player, buildSyncList())
			end
		end, 2000, 1, source)
	end
end)

addEventHandler("onPlayerQuit", root, function()
	for uid, plant in pairs(plants) do
		if plant.owner == source then
			if isTimer(plant.growTimer) then
				killTimer(plant.growTimer)
			end
			if isTimer(plant.markerTimer) then
				killTimer(plant.markerTimer)
			end
			if isElement(plant.object) then
				destroyElement(plant.object)
			end
			plants[uid] = nil
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	-- crafting_markers from the decompiled config: green/red cylinders with
	-- the liquor:crafting elementData + a right-click plant trigger
	for _, marker in ipairs(crafting_markers) do
		local m = createMarker(marker[1], marker[2], marker[3] - 0.7, "cylinder", 1, marker[5], marker[6], marker[7], 100)
		if m then
			setElementData(m, "liquor:crafting", marker[4])
			setElementData(m, "rightclick:title", marker[4] .. " field")
			setElementData(m, "rightclick:menu", { { Text = "Plant " .. marker[4] } })
		end
	end
end)

-- right-click "Plant <type>" on a crafting marker -> the client's
-- liquor_dealer:startFarming (same gates the decompile applies client-side)
addEventHandler("onClientElementMenuClick:Server", root, function(element, optionText)
	local player = client
	if not player or not isElement(element) then
		return
	end
	local fieldType = getElementData(element, "liquor:crafting")
	if not fieldType or optionText ~= "Plant " .. fieldType then
		return
	end
	if plant_types[fieldType] then
		triggerClientEvent(player, "liquor_dealer:startFarming", player, fieldType)
	end
end)
