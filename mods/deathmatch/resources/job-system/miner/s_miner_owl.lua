-- owlbakeup Fix #63 - Miner job SERVER, rebuilt from the client contract
-- ([jobs]/miner/miner_c_decompiled.lua, Fix #54 phone pattern):
--   miner:sell           -> sell every "Materials" item (#215) at the fixed
--                           org price (the Owl inventory stored per-item
--                           org_price; this repo's item-system has no price
--                           field, so a per-unit constant mirrors it -
--                           MATERIAL_PRICE must stay in sync with the client)
--   miner:sell:callback  -> release the client's busy flag
--   Miner:ProgressState ("Show"/"Hide") + "Miner:Progress" elementData are
--   driven by the mining loop below - RECONSTRUCTED server data (the old
--   server was lost): rocks carry a right-click "Mine" option (the Fix #60
--   interaction menu shows rightclick:menu objects), mining runs an 8s
--   progress mirrored onto the rock's "Miner:Progress" elementData exactly
--   the way the decompiled progress bar reads it, then grants one Material.
--   The decompiled miner has NO job gating and NO givePlayerJobEXP call -
--   anyone may mine, money comes from selling - so there is no jobs_data
--   entry for it.

local mysql = exports.mysql

local MATERIAL_ITEM_ID = 215 -- g_items.lua "Materials"
local MATERIAL_PRICE = 25 -- must mirror c_miner_owl.lua
local MINE_TIME_MS = 8000
local ROCK_RESPAWN_MS = 15000

-- reconstructed mining site: rocks scattered around the LV quarry
local ROCK_SPOTS = {
	{ 2313.5, 868.2, 0, 3930 },
	{ 2338.1, 842.7, 0, 3930 },
	{ 2351.9, 885.4, 0, 3930 },
	{ 2296.7, 830.5, 0, 3930 },
	{ 2367.3, 820.9, 0, 3930 },
	{ 2284.2, 902.8, 0, 3930 }
}

local rocks = {} -- [rock] = { worker = player, timer = timerHandle }

local function spawnRocks()
	for _, spot in ipairs(ROCK_SPOTS) do
		local x, y, model = spot[1], spot[2], spot[4]
		local z = getGroundPosition(x, y, spot[3] == 0 and 30 or spot[3])
		if not z or z == 0 then
			z = spot[3] == 0 and 12 or spot[3]
		end
		local rock = createObject(model, x, y, z - 0.5)
		if rock then
			setElementData(rock, "rightclick:title", "Rock")
			setElementData(rock, "rightclick:menu", { { Text = "Mine" } })
			setElementData(rock, "Miner:Progress", 0)
			table.insert(rocks, { element = rock })
		end
	end
end

local function findRockEntry(rock)
	for _, entry in ipairs(rocks) do
		if entry.element == rock then
			return entry
		end
	end
end

local function stopMining(entry)
	if entry.timer and isTimer(entry.timer) then
		killTimer(entry.timer)
	end
	entry.timer = nil
	entry.worker = nil
	setElementData(entry.element, "Miner:Progress", 0)
end

addEventHandler("onClientElementMenuClick:Server", root, function(element, optionText)
	local player = client
	if not player or optionText ~= "Mine" then
		return
	end
	local entry = findRockEntry(element)
	if not entry or entry.worker then
		return -- already being mined
	end
	local px, py, pz = getElementPosition(player)
	local rx, ry, rz = getElementPosition(element)
	if getDistanceBetweenPoints3D(px, py, pz, rx, ry, rz) > 5 then
		return
	end
	entry.worker = player
	setElementData(element, "Miner:Progress", 0)
	triggerClientEvent(player, "Miner:ProgressState", player, "Show", element)
	local progress = 0
	entry.timer = setTimer(function(entry)
		if not isElement(entry.element) or not isElement(entry.worker) then
			triggerClientEvent(entry.worker, "Miner:ProgressState", entry.worker, "Hide", entry.element)
			stopMining(entry)
			return
		end
		progress = progress + math.ceil(100 / (MINE_TIME_MS / 100))
		if progress >= 100 then
			setElementData(entry.element, "Miner:Progress", 100)
			triggerClientEvent(entry.worker, "Miner:ProgressState", entry.worker, "Hide", entry.element)
			local worker = entry.worker
			stopMining(entry)
			-- short respawn cooldown: nobody can mine this rock right away
			setElementData(entry.element, "rightclick:menu", {})
			setTimer(function(entry)
				if isElement(entry.element) then
					setElementData(entry.element, "rightclick:menu", { { Text = "Mine" } })
				end
			end, ROCK_RESPAWN_MS, 1, entry)
			exports["item-system"]:giveItem(worker, MATERIAL_ITEM_ID, 1)
			exports.notifications:outputToPlayer(worker, "حصلت على مادة خام - بعتها عند تاجر المواد", 5000, "info")
			return
		end
		setElementData(entry.element, "Miner:Progress", progress)
	end, 100, MINE_TIME_MS / 100, entry)
end)

addEvent("miner:sell", true)
addEventHandler("miner:sell", root, function()
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
		triggerClientEvent(player, "miner:sell:callback", player)
		return
	end
	local count = 0
	for _, value in ipairs(items) do
		if tonumber(value[1]) == MATERIAL_ITEM_ID then
			count = count + 1
		end
	end
	local total = count * MATERIAL_PRICE
	if count <= 0 then
		triggerClientEvent(player, "miner:sell:callback", player)
		return
	end
	local removed = 0
	for _ = 1, count do
		if exports["item-system"]:takeItem(player, MATERIAL_ITEM_ID) then
			removed = removed + 1
		else
			break
		end
	end
	if removed > 0 then
		local pay = removed * MATERIAL_PRICE
		exports.global:giveMoney(player, pay)
		mysql:query_free("INSERT INTO miner_sales (character_id, materials, paid, sold_at) VALUES (" .. characterID .. ", " .. removed .. ", " .. pay .. ", '" .. os.date("%Y-%m-%d %H:%M:%S") .. "')")
		exports.notifications:outputToPlayer(player, "بعت " .. removed .. " مواد بمبلغ $" .. pay, 5000, "success")
	end
	triggerClientEvent(player, "miner:sell:callback", player)
end)

addEventHandler("onPlayerQuit", root, function()
	for _, entry in ipairs(rocks) do
		if entry.worker == source then
			triggerClientEvent(entry.worker, "Miner:ProgressState", entry.worker, "Hide", entry.element)
			stopMining(entry)
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	mysql:query_free([[
		CREATE TABLE IF NOT EXISTS miner_sales (
			id INT AUTO_INCREMENT PRIMARY KEY,
			character_id INT NOT NULL,
			materials INT NOT NULL DEFAULT 0,
			paid INT NOT NULL DEFAULT 0,
			sold_at VARCHAR(32) NOT NULL DEFAULT ''
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]])
	spawnRocks()
end)

addEventHandler("onResourceStop", resourceRoot, function()
	for _, entry in ipairs(rocks) do
		if isElement(entry.element) then
			destroyElement(entry.element)
		end
	end
end)
