-- owlbakeup Fix #63 - Gunsmith SERVER, rebuilt from the client contract
-- ([jobs]/gunsmith/client_decompiled.lua + config, Fix #54 pattern):
--   factory markers (crafting_markers / assembling_markers, interior 2
--     dimension 756 from the config) carry the "factory:crafting" elementData
--     the client's marker-leave contract reads; on player marker hit the
--     server sends factory:showSelection(marker, "crafting"/"assembling").
--   factory:crafting(index, marker)  -> machine_cooldown gate + level + cost
--     + requirements (TempUse tools checked only, materials consumed) ->
--     duration timer -> the crafted item (FACTORY_ITEM_IDS -> item-system).
--   factory:assembling(index)       -> level + every part consumed ->
--     the weapon as item 115 "Weapon" ("WeapModel:Ammo") -> callback(true).
--   onClientRequestTakeJob -> exports["job-system"]:takeJob (core client
--     export) - the Gunsmith is a normal core job.
-- The Owl machine "level" gate reads the level-system elementData ("level").

local mysql = exports.mysql

local cooldowns = {} -- [player] = tick of last machine use

local function countItem(player, itemID)
	local items = exports["item-system"]:getItems(player)
	if type(items) ~= "table" then
		return 0
	end
	local count = 0
	for _, value in ipairs(items) do
		if tonumber(value[1]) == itemID then
			count = count + 1
		end
	end
	return count
end

local function takeItems(player, itemID, quantity)
	for _ = 1, quantity do
		if not exports["item-system"]:takeItem(player, itemID) then
			return false
		end
	end
	return true
end

local function addFactoryMarkers(markerList, kind)
	for _, pos in ipairs(markerList) do
		local marker = createMarker(pos[1], pos[2], pos[3], "cylinder", 1.5, 255, 140, 0, 120)
		if marker then
			setElementInterior(marker, factory.int)
			setElementDimension(marker, factory.dim)
			setElementData(marker, "factory:crafting", kind)
			setElementData(marker, "factory:kind", kind)
		end
	end
end

addEventHandler("onPlayerMarkerHit", root, function(marker, matchingDimension)
	if getElementType(source) ~= "player" then
		return
	end
	local kind = getElementData(marker, "factory:kind")
	if not kind or getElementDimension(source) ~= factory.dim or getElementInterior(source) ~= factory.int then
		return
	end
	triggerClientEvent(source, "factory:showSelection", source, marker, kind)
end)

addEvent("factory:crafting", true)
addEventHandler("factory:crafting", root, function(index, marker)
	local player = client
	if not player or not tonumber(index) or not isElement(marker) then
		return
	end
	if getElementData(player, "job") ~= "Gunsmith" then
		return
	end
	local craftItem = factory.craft_items[tonumber(index)]
	if not craftItem then
		return
	end
	local now = getTickCount()
	if cooldowns[player] and now - cooldowns[player] < factory.machine_cooldown then
		return
	end
	cooldowns[player] = now
	local level = tonumber(getElementData(player, "level")) or 1
	if level < craftItem.required_level then
		exports.notifications:outputToPlayer(player, "تحتاج مستوى " .. craftItem.required_level .. " لصنع هذا", 5000, "error")
		return
	end
	local money = tonumber(getElementData(player, "money")) or 0
	if money < craftItem.cost then
		exports.notifications:outputToPlayer(player, "لاتملك ما يكفي ($" .. craftItem.cost .. ")", 5000, "error")
		return
	end
	-- requirements: TempUse tools are only checked, materials are consumed
	for _, req in ipairs(craftItem.requirements) do
		local itemID = FACTORY_ITEM_IDS[req.Name]
		if not itemID then
			return
		end
		if countItem(player, itemID) < req.Quantity then
			exports.notifications:outputToPlayer(player, "تحتاج " .. req.Name .. " x" .. req.Quantity, 5000, "error")
			return
		end
	end
	-- consume + pay only after every requirement is present
	for _, req in ipairs(craftItem.requirements) do
		if not req.TempUse then
			takeItems(player, FACTORY_ITEM_IDS[req.Name], req.Quantity)
		end
	end
	if craftItem.cost > 0 then
		exports.global:takeMoney(player, craftItem.cost)
	end
	local characterID = tonumber(getElementData(player, "character:id"))
	setTimer(function(player, craftItem, characterID)
		if not isElement(player) or getElementData(player, "loggedin") ~= 1 then
			return
		end
		exports["item-system"]:giveItem(player, FACTORY_ITEM_IDS[craftItem.item.Name], 1)
		if characterID then
			mysql:query_free("INSERT INTO factory_crafts (character_id, item_name, cost) VALUES (" .. characterID .. ", '" .. mysql:escape_string(craftItem.item.Name) .. "', " .. craftItem.cost .. ")")
		end
		exports.notifications:outputToPlayer(player, "تم صنع " .. craftItem.item.Name, 5000, "success")
	end, craftItem.duration * 1000, 1, player, craftItem, characterID)
end)

addEvent("factory:assembling", true)
addEventHandler("factory:assembling", root, function(index)
	local player = client
	if not player or not tonumber(index) then
		return
	end
	if getElementData(player, "job") ~= "Gunsmith" then
		triggerClientEvent(player, "factory:assembling:callback", player, false)
		return
	end
	local assemblyItem = factory.assembly_items[tonumber(index)]
	if not assemblyItem then
		triggerClientEvent(player, "factory:assembling:callback", player, false)
		return
	end
	local level = tonumber(getElementData(player, "level")) or 1
	if level < assemblyItem.required_level then
		exports.notifications:outputToPlayer(player, "تحتاج مستوى " .. assemblyItem.required_level .. " للتجميع", 5000, "error")
		triggerClientEvent(player, "factory:assembling:callback", player, false)
		return
	end
	for _, part in ipairs(assemblyItem.parts) do
		if countItem(player, FACTORY_ITEM_IDS[part.item_name]) < 1 then
			exports.notifications:outputToPlayer(player, "لاتمتلك كل القطع المطلوبة", 5000, "error")
			triggerClientEvent(player, "factory:assembling:callback", player, false)
			return
		end
	end
	for _, part in ipairs(assemblyItem.parts) do
		takeItems(player, FACTORY_ITEM_IDS[part.item_name], 1)
	end
	local weaponID = tonumber(assemblyItem.item.Properties.WeapModel)
	local ammo = tonumber(assemblyItem.item.SpecialProperties.Ammo) or 1
	setTimer(function(player, assemblyItem, weaponID, ammo)
		if not isElement(player) or getElementData(player, "loggedin") ~= 1 then
			return
		end
		exports["item-system"]:giveItem(player, 115, weaponID .. ":" .. ammo)
		triggerClientEvent(player, "factory:assembling:callback", player, true)
		exports.notifications:outputToPlayer(player, "تم تجميع " .. assemblyItem.item.Name, 5000, "success")
	end, assemblyItem.duration * 1000, 1, player, assemblyItem, weaponID, ammo)
end)

addEventHandler("onPlayerQuit", root, function()
	cooldowns[source] = nil
end)

addEventHandler("onResourceStart", resourceRoot, function()
	mysql:query_free([[
		CREATE TABLE IF NOT EXISTS factory_crafts (
			id INT AUTO_INCREMENT PRIMARY KEY,
			character_id INT NOT NULL,
			item_name VARCHAR(64) NOT NULL DEFAULT '',
			cost INT NOT NULL DEFAULT 0
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]])
	addFactoryMarkers(factory.crafting_markers, "crafting")
	addFactoryMarkers(factory.assembling_markers, "assembling")
end)
