--[[
	PDZ Main Menu - server side (F1)

	The client cannot know any of this on its own, because ownership in the
	database is a character ID, not a player element:

	  main-menu:requestVehicles     -> SQL on `vehicles`   (owner = character id)
	  main-menu:requestInteriors    -> SQL on `interiors`  (owner = character id)
	  main-menu:requestStaff        -> admins / supporters online
	  main-menu:requestLeaderboard  -> { levels = {}, activities = {} }  (placeholder)
	  main-menu:requestDiscord      -> { linked = false }                (placeholder)

	The two placeholder systems return empty tables on purpose. The client
	already renders their layout, so enabling them later only means filling
	in the matching function below - no client change needed.
]]

--[[ character id, the same value vehicle-manager / interior-manager join on ]]
local function getCharacterId(thePlayer)
	return tonumber(getElementData(thePlayer, "dbid"))
		or tonumber(getElementData(thePlayer, "account:character:id"))
		or -1
end

local function getResourceRunning(name)
	return getResourceState(getResourceFromName(name)) == "running"
end

-- calls an export safely: returns nil when the resource is not running
local function safeExport(resourceName, exportName, ...)
	if not getResourceRunning(resourceName) then return nil end
	local args = { ... }
	local ok, result = pcall(function()
		return call(getResourceFromName(resourceName), exportName, unpack(args))
	end)
	if ok then return result end
	return nil
end

local function reply(thePlayer, eventName, payload)
	if isElement(thePlayer) then
		triggerClientEvent(eventName, thePlayer, payload)
	end
end

local function isRequesterValid(thePlayer)
	return isElement(thePlayer) and getElementType(thePlayer) == "player"
end

--[[ ==================== vehicles ==================== ]]

-- name comes from vehicles_shop, falls back to the GTA model name
local function getVehicleDisplayName(row)
	local brand, model = row["vehbrand"], row["vehmodel"]
	if brand or model then
		return ("%s %s %s"):format(
			tostring(row["vehyear"] or ""),
			tostring(brand or ""),
			tostring(model or "")
		):match("^%s*(.-)%s*$")
	end
	return getVehicleNameFromModel(tonumber(row["model"]) or 411) or "Unknown"
end

local function buildVehiclesList(characterId)
	if characterId < 0 then return {} end

	local rows = mysql:query(
		"SELECT v.id, v.model, v.plate, v.fuel, v.odometer, v.Impounded, v.locked, " ..
		"       v.hp, v.vehicle_shop_id, s.vehbrand, s.vehmodel, s.vehyear " ..
		"FROM `vehicles` v " ..
		"LEFT JOIN `vehicles_shop` s ON v.vehicle_shop_id = s.id " ..
		"WHERE v.owner = " .. mysql:escape_string(characterId) .. " " ..
		"ORDER BY v.id ASC"
	) or false

	if rows == false then return {} end

	local list = {}
	for _, row in ipairs(rows) do
		list[#list + 1] = {
			id        = tonumber(row["id"]) or 0,
			name      = getVehicleDisplayName(row),
			model     = tonumber(row["model"]) or 0,
			plate     = tostring(row["plate"] or "--------"),
			fuel      = tonumber(row["fuel"]) or 0,
			odo       = tonumber(row["odometer"]) or 0,
			engine    = (tonumber(row["engine"]) or 0) == 1,
			impounded = (tonumber(row["Impounded"]) or 0) == 1,
			locked    = (tonumber(row["locked"]) or 0) == 1
		}
	end
	return list
end

addEvent("main-menu:requestVehicles", true)
addEventHandler("main-menu:requestVehicles", root, function()
	local thePlayer = client or source
	if not isRequesterValid(thePlayer) then return end
	reply(thePlayer, "main-menu:vehicles:callback", buildVehiclesList(getCharacterId(thePlayer)))
end)

--[[ ==================== interiors ==================== ]]

local function buildInteriorsList(characterId)
	if characterId < 0 then return {} end

	local rows = mysql:query(
		"SELECT id, name, type, locked, disabled " ..
		"FROM `interiors` " ..
		"WHERE owner = " .. mysql:escape_string(characterId) .. " " ..
		"ORDER BY id ASC"
	) or false

	if rows == false then return {} end

	local list = {}
	for _, row in ipairs(rows) do
		local disabled = (tonumber(row["disabled"]) or 0) == 1
		local locked   = (tonumber(row["locked"]) or 0) == 1
		list[#list + 1] = {
			id       = tonumber(row["id"]) or 0,
			name     = tostring(row["name"] or "Unknown"),
			type     = tonumber(row["type"]) or 0,
			locked   = locked,
			disabled = disabled,
			status   = disabled and "Disabled" or (locked and "Locked" or "Unlocked")
		}
	end
	return list
end

addEvent("main-menu:requestInteriors", true)
addEventHandler("main-menu:requestInteriors", root, function()
	local thePlayer = client or source
	if not isRequesterValid(thePlayer) then return end
	reply(thePlayer, "main-menu:interiors:callback", buildInteriorsList(getCharacterId(thePlayer)))
end)

--[[ ==================== online staff ==================== ]]

-- integration holds the real authority on who is staff
local function isAdmin(thePlayer)
	return safeExport("integration", "isPlayerAdmin", thePlayer) == true
end

local function isSupporter(thePlayer)
	return safeExport("integration", "isPlayerSupporter", thePlayer) == true
end

local function buildStaffList()
	local admins, supports = {}, {}

	for _, p in ipairs(getElementsByType("player")) do
		if getElementData(p, "account:character:id") then
			local entry = {
				name  = tostring(getPlayerName(p):gsub("_", " ")),
				ping  = math.floor(getPlayerPing(p)),
				level = 0,
				title = "Player"
			}

			if isAdmin(p) then
				entry.level = tonumber(safeExport("integration", "getAdminLevel", p)) or 0
				entry.title = safeExport("integration", "getAdminTitle", p) or ("Admin " .. entry.level)
				admins[#admins + 1] = entry
			elseif isSupporter(p) then
				entry.title = "Supporter"
				supports[#supports + 1] = entry
			end
		end
	end

	table.sort(admins, function(a, b) return (a.level or 0) > (b.level or 0) end)
	table.sort(supports, function(a, b) return a.name < b.name end)

	return admins, supports
end

addEvent("main-menu:requestStaff", true)
addEventHandler("main-menu:requestStaff", root, function()
	local thePlayer = client or source
	if not isRequesterValid(thePlayer) then return end
	local admins, supports = buildStaffList()
	reply(thePlayer, "main-menu:staff:callback", { admins = admins, supports = supports })
end)

--[[ ==================== leaderboard (placeholder) ====================
	The level system does not exist on this server yet. The payload keeps
	the exact shape the client renders, so turning the system on later is
	only a matter of filling the two arrays from the real tables. ]]

addEvent("main-menu:requestLeaderboard", true)
addEventHandler("main-menu:requestLeaderboard", root, function()
	local thePlayer = client or source
	if not isRequesterValid(thePlayer) then return end
	reply(thePlayer, "main-menu:leaderboard:callback", { levels = {}, activities = {} })
end)

--[[ ==================== discord link (placeholder) ====================
	No discord system is running. The client renders the tab and shows the
	unlinked state until a real resource is wired in here. ]]

addEvent("main-menu:requestDiscord", true)
addEventHandler("main-menu:requestDiscord", root, function()
	local thePlayer = client or source
	if not isRequesterValid(thePlayer) then return end
	reply(thePlayer, "main-menu:discord:callback", { linked = false, code = "", tag = "" })
end)

