-- blips_s.lua
-- Server side of the house-blip system (counterpart of blips_c.lua).
-- Restored from an encrypted original. Provides:
--   * "createBlipsFromTable" push - bulk resync of a player's house blips
--     (the client handler lives in c_interior_system.lua and was never called)
--   * server event "refreshMyInteriorBlips" - manual refresh hook for other
--     resources / UCP
-- The row format matches c_interior_system.lua createBlipAtXY(inttype, x, y):
--   { inttype, x, y } with inttype normalized to 0/1 so the client picks
--   icon 31 (house) or 32 (business) exactly like blips_c.lua does.

local function getInteriorFromID(intID)
	for _, interior in ipairs(getElementsByType("interior")) do
		if isElement(interior) and getElementData(interior, "dbid") == tonumber(intID) then
			return interior
		end
	end
	return false
end

local function addRow(rows, status, entrance)
	-- blips_c.lua: icon 32 when status[1] == 1, otherwise 31
	local inttype = 0
	if tonumber(status[1]) == 1 then
		inttype = 1
	end
	table.insert(rows, { inttype, tonumber(entrance[1]), tonumber(entrance[2]) })
end

-- mirror of blips_c.lua locateMyParentInteriorInWorldMap(): walk up the
-- interior chain until a world entrance is found
local function locateWorldEntrance(interior, status, owner, rows, seen)
	if not isElement(interior) or seen[interior] then
		return
	end
	seen[interior] = true

	local entrance = getElementData(interior, "entrance")
	if type(entrance) ~= "table" then
		return
	end

	if tonumber(entrance[4]) ~= 0 and tonumber(entrance[5]) ~= 0 then
		local parent = getInteriorFromID(tonumber(entrance[5]))
		if parent then
			locateWorldEntrance(parent, status, owner, rows, seen)
		end
	else
		local parentStatus = getElementData(interior, "status")
		-- only draw the world entrance when it does not belong to us
		-- (our own ones are added by the main pass below)
		if type(parentStatus) == "table" and tonumber(parentStatus[4]) ~= owner then
			addRow(rows, status, entrance)
		end
	end
end

local function collectRows(player)
	local owner = tonumber(getElementData(player, "dbid"))
	local rows = {}

	for _, interior in ipairs(getElementsByType("interior")) do
		if isElement(interior) then
			local status = getElementData(interior, "status")
			local entrance = getElementData(interior, "entrance")
			if type(status) == "table" and type(entrance) == "table" and tonumber(status[4]) == owner then
				if tonumber(entrance[4]) == 0 and tonumber(entrance[5]) == 0 then
					-- our own world entrance
					addRow(rows, status, entrance)
				else
					locateWorldEntrance(interior, status, owner, rows, {})
				end
			end
		end
	end

	return rows
end

function sendInteriorBlips(player)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false
	end

	triggerClientEvent(player, "createBlipsFromTable", player, collectRows(player))
	return true
end

addEvent("refreshMyInteriorBlips", true)
addEventHandler("refreshMyInteriorBlips", root,
	function()
		if client then
			sendInteriorBlips(client)
		end
	end
)

-- initial sync shortly after login, once character/interior data is ready
addEventHandler("onPlayerJoin", root,
	function()
		setTimer(
			function(player)
				if isElement(player) then
					sendInteriorBlips(player)
				end
			end, 20000, 1, source
		)
	end
)
