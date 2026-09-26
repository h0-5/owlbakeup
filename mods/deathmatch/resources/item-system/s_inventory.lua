-- s_inventory.lua
-- Restored from an encrypted original. Implements the contracts declared by
-- item-system/meta.xml and consumed by c_item_system.lua:
--   * server event "toggleGhettoblaster"  (right-click menu on a placed ghettoblaster)
--   * export      "updateSafeItems"       (refresh safe inventories after external/DB changes)

local GHETTOBLASTER_ITEMS = { [54] = true, [176] = true }

-- same write path as ghettoblaster/s_ghettoblaster.lua updateWorldItemValue()
local function applyWorldItemValue(item, newValue)
	exports.anticheat:changeProtectedElementDataEx(item, "itemValue", newValue)

	local id = tonumber(getElementData(item, "id"))
	if id then
		mysql:query_free("UPDATE worlditems SET itemvalue='" .. newValue .. "' WHERE id=" .. id)
	end

	triggerClientEvent("toggleSound", item)
end

addEvent("toggleGhettoblaster", true)
addEventHandler("toggleGhettoblaster", root,
	function(item)
		local player = client
		if not player then
			return
		end
		if not isElement(item) then
			return
		end

		local itemID = tonumber(getElementData(item, "itemID"))
		if not itemID or not GHETTOBLASTER_ITEMS[itemID] then
			return
		end

		-- the client menu only opens within 3 units; re-check server side
		local px, py, pz = getElementPosition(player)
		local ix, iy, iz = getElementPosition(item)
		if getDistanceBetweenPoints3D(px, py, pz, ix, iy, iz) > 5 then
			return
		end

		local value = split(tostring(getElementData(item, "itemValue") or ""), ':')
		local station = tonumber(value[1]) or 0
		local volume = tonumber(value[2])

		-- toggle: off -> first station, playing -> off
		local newStation = 0
		if station == 0 then
			newStation = 1
		end

		local newValue = tostring(newStation)
		if volume and volume ~= 100 then
			newValue = newValue .. ":" .. volume
		end

		applyWorldItemValue(item, newValue)
	end
)

-- export (item-system/meta.xml): force-reloads safe inventories from the database
-- and pushes the fresh item lists to every player currently viewing them (loadItems
-- with force=true notifies all subscribers).
--   updateSafeItems()                -> all safes (objects, model 2332)
--   updateSafeItems(dimension)        -> safes located in that interior/dimension
--   updateSafeItems(element)          -> any inventory element (safe/vehicle/player/...)
-- returns: success, numberOfUpdatedInventories
function updateSafeItems(target)
	local targets = {}

	if isElement(target) then
		table.insert(targets, target)
	else
		local dimension = tonumber(target)
		for _, object in ipairs(getElementsByType("object")) do
			if getElementModel(object) == 2332 and (not dimension or getElementDimension(object) == dimension) then
				table.insert(targets, object)
			end
		end
	end

	local updated = 0
	for _, element in ipairs(targets) do
		if loadItems(element, true) then
			updated = updated + 1
		end
	end

	return updated > 0, updated
end
