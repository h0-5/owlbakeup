local ids = { }

function playerJoin()
	local slot = nil
	
	for i = 1, 5000 do
		if (ids[i]==nil) then
			slot = i
			break
		end
	end
	
	ids[slot] = source
	exports.anticheat:changeProtectedElementDataEx(source, "playerid", slot)
	exports.pool:allocateElement(source, slot)
end
addEventHandler("onPlayerJoin", getRootElement(), playerJoin)

function playerQuit()
	local slot = getElementData(source, "playerid")
	
	if (slot) then
		ids[slot] = nil
	end
end
addEventHandler("onPlayerQuit", getRootElement(), playerQuit)

function resourceStart()
	local players = exports.pool:getPoolElementsByType("player")
	
	for key, value in ipairs(players) do
		ids[key] = value
		exports.anticheat:changeProtectedElementDataEx(value, "playerid", key)
		exports.pool:allocateElement(value, key)
	end
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), resourceStart)


function fakeMyID()
	local slot = nil
	for i = 1, 5000 do
		if (ids[i]==nil) then
			slot = i
			break
		end
	end
	
	local slotOld = getElementData(source, "playerid")
	
	if (slotOld) then
		ids[slotOld] = nil
	end
	
	ids[slot] = source
	exports.anticheat:changeProtectedElementDataEx(source, "playerid", slot)
	exports.pool:allocateElement(source, slot)
end
addEvent("fakemyid", true)
addEventHandler("fakemyid", getRootElement(), fakeMyID)

-- [Fix #90] explicit session-id swap (used by /changeid for the FULL id
-- replacement: mod:id + playerid + pool slot together). Unlike fakeMyID
-- this takes an EXACT slot and refuses it when another player holds it.
function setPlayerSlot(player, slot)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false, "invalid player"
	end
	slot = tonumber(slot)
	if not slot or slot < 1 then
		return false, "invalid id"
	end
	local occupant = ids[slot]
	if occupant and occupant ~= player then
		return false, "id " .. slot .. " is already used by another online player"
	end
	local old = getElementData(player, "playerid")
	if old == slot then
		return true
	end
	if old and ids[old] == player then
		ids[old] = nil
	end
	ids[slot] = player
	exports.anticheat:changeProtectedElementDataEx(player, "playerid", slot)
	exports.pool:allocateElement(player, slot)
	return true
end