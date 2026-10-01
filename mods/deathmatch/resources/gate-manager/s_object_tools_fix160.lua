-- [Fix #160] OBJECT & GATE system (replaces the cancelled property.make): object
-- placement (/makeobj), right-click menu, gate edit panel, gate locking, map/creator
-- tools and the keys commands. The command->right map lives in
-- admin-system/staff_manager/gates_fix160_task6.lua - the global onPlayerCommand
-- gate enforces it for typed commands, the checks below enforce the same rights on
-- the client events of this file.

local mysql = exports.mysql

-- [Fix #160] one right check, also used by s_gate_action.lua (locked gates). A
-- Vortex rank is decided solely by its stored rights; a player without a Vortex
-- rank falls back to the legacy ladder (the same rule as hasCommandRight).
function hasGateToolRight(thePlayer, right)
	if not isElement(thePlayer) or getElementType(thePlayer) ~= "player" then return false end
	if getElementData(thePlayer, "rank:index") then
		local ok, res = pcall(function()
			return exports['admin-system']:playerHasRight(thePlayer, right)
		end)
		return ok and res and true or false
	end
	return exports.integration:isPlayerAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)
end

-- [Fix #160] ANY of the listed rights grants access (union semantics of the gate map)
function hasAnyGateToolRight(thePlayer, ...)
	for i = 1, select("#", ...) do
		local right = select(i, ...)
		if right and hasGateToolRight(thePlayer, right) then
			return true
		end
	end
	return false
end

-- [Fix #160] shared denial message (also used by s_gate_manager.lua / s_gates.lua)
function denyToolRight(thePlayer, message)
	if not (thePlayer and isElement(thePlayer)) then return end
	outputChatBox(message or "You don't have permission to use this command.", thePlayer, 255, 0, 0)
end

-- [Fix #160] only objects owned by this resource with gate data can be edited here
local function isManagedGate(theGate)
	if not theGate or not isElement(theGate) or getElementType(theGate) ~= "object" then return false end
	if getElementParent(theGate) ~= getResourceRootElement(getThisResource()) then return false end
	return getElementData(theGate, "gate") and true or false
end

-- [Fix #160] dimension/interior aware reach check for the edit tools
local function canReachGate(thePlayer, theGate, radius)
	if getElementDimension(thePlayer) ~= getElementDimension(theGate) then return false end
	if getElementInterior(thePlayer) ~= getElementInterior(theGate) then return false end
	local px, py, pz = getElementPosition(thePlayer)
	local gx, gy, gz = getElementPosition(theGate)
	return getDistanceBetweenPoints3D(px, py, pz, gx, gy, gz) <= (radius or 10)
end

-- [Fix #160] a door is an object whose move-to target differs from its start
local function isDoorObject(theGate)
	local params = getElementData(theGate, "gate:parameters")
	if type(params) ~= "table" then return false end
	local s, e = params["startPosition"], params["endPosition"]
	if type(s) ~= "table" or type(e) ~= "table" then return false end
	for i = 1, 6 do
		if tonumber(s[i]) ~= tonumber(e[i]) then return true end
	end
	return false
end

-- [Fix #160] resolve an id argument, or the nearest object within the radius
local function findNearestGate(thePlayer, gateID, radius)
	if tonumber(gateID) then
		local theGate = getGateElementFromID(tonumber(gateID))
		if not theGate then
			outputChatBox("[GATEMANAGER] Gate/object #" .. tonumber(gateID) .. " does not exist.", thePlayer, 255, 0, 0)
			return nil
		end
		return theGate
	end
	radius = radius or 10
	local px, py, pz = getElementPosition(thePlayer)
	local dim = getElementDimension(thePlayer)
	local found, foundDist = nil, radius
	for _, theGate in ipairs(getElementsByType("object", getResourceRootElement(getThisResource()))) do
		if getElementData(theGate, "gate") and getElementDimension(theGate) == dim then
			local gx, gy, gz = getElementPosition(theGate)
			local dist = getDistanceBetweenPoints3D(px, py, pz, gx, gy, gz)
			if dist <= foundDist then
				found, foundDist = theGate, dist
			end
		end
	end
	if not found then
		outputChatBox("[GATEMANAGER] No gate/object within " .. radius .. "m of you.", thePlayer, 255, 194, 14)
	end
	return found
end

-- [Fix #160] numeric column pack shared by /makeobj, the edit panel and /savemap
local function gateValues(model, s, e, int, dim)
	local vals = {
		tonumber(model),
		tonumber(s[1]), tonumber(s[2]), tonumber(s[3]), tonumber(s[4]), tonumber(s[5]), tonumber(s[6]),
		tonumber(e[1]), tonumber(e[2]), tonumber(e[3]), tonumber(e[4]), tonumber(e[5]), tonumber(e[6]),
		tonumber(int), tonumber(dim),
	}
	for i = 1, #vals do
		if not vals[i] then return nil end
	end
	return vals
end

-- [Fix #160] val layout: 1 = model, 2..7 = start, 8..13 = move-to, 14 = interior, 15 = dimension
local function insertGateSQL(gateID, vals, creator, note)
	return "INSERT INTO `gates` (`id`, `objectID`, `startX`, `startY`, `startZ`, `startRX`, `startRY`, `startRZ`,"
		.. " `endX`, `endY`, `endZ`, `endRX`, `endRY`, `endRZ`, `gateType`, `gateSecurityParameters`,"
		.. " `autocloseTime`, `movementTime`, `objectInterior`, `objectDimension`, `creator`, `adminNote`,"
		.. " `triggerDistance`, `triggerDistanceVehicle`)"
		.. " VALUES ('" .. gateID .. "', '" .. vals[1] .. "', '" .. vals[2] .. "', '" .. vals[3] .. "', '" .. vals[4] .. "', '"
		.. vals[5] .. "', '" .. vals[6] .. "', '" .. vals[7] .. "', '" .. vals[8] .. "', '" .. vals[9] .. "', '" .. vals[10] .. "', '"
		.. vals[11] .. "', '" .. vals[12] .. "', '" .. vals[13] .. "', '1', '', '0', '30', '" .. vals[14] .. "', '" .. vals[15] .. "', '"
		.. mysql:escape_string(tostring(creator or "unknown")) .. "', '" .. mysql:escape_string(tostring(note or "")) .. "', '10', '10')"
end

local function updateGateSQL(gateID, vals)
	return "UPDATE `gates` SET `objectID` = '" .. vals[1] .. "',"
		.. " `startX` = '" .. vals[2] .. "', `startY` = '" .. vals[3] .. "', `startZ` = '" .. vals[4] .. "',"
		.. " `startRX` = '" .. vals[5] .. "', `startRY` = '" .. vals[6] .. "', `startRZ` = '" .. vals[7] .. "',"
		.. " `endX` = '" .. vals[8] .. "', `endY` = '" .. vals[9] .. "', `endZ` = '" .. vals[10] .. "',"
		.. " `endRX` = '" .. vals[11] .. "', `endRY` = '" .. vals[12] .. "', `endRZ` = '" .. vals[13] .. "',"
		.. " `objectInterior` = '" .. vals[14] .. "', `objectDimension` = '" .. vals[15] .. "'"
		.. " WHERE `id` = '" .. mysql:escape_string(tostring(gateID)) .. "'"
end

-- [Fix #160] createObject returns false for a bad model id, so test-drive it first
local function isValidObjectModel(model)
	model = tonumber(model)
	if not model or model < 321 or model > 19999 or model ~= math.floor(model) then return false end
	local test = createObject(model, 0, 0, -100)
	if not test then return false end
	destroyElement(test)
	return true
end

-- [Fix #160] payload for the client edit panel (c_object_panel_fix160.lua)
local function getGatePayload(theGate)
	local params = getElementData(theGate, "gate:parameters")
	local s = (type(params) == "table" and params["startPosition"]) or nil
	local e = (type(params) == "table" and params["endPosition"]) or nil
	local x, y, z = getElementPosition(theGate)
	local rx, ry, rz = getElementRotation(theGate)
	s = s or { x, y, z, rx, ry, rz }
	e = e or { x, y, z, rx, ry, rz }
	return {
		id = tonumber(getElementData(theGate, "gate:id")) or -1,
		model = getElementModel(theGate),
		sx = s[1], sy = s[2], sz = s[3], srx = s[4], sry = s[5], srz = s[6],
		ex = e[1], ey = e[2], ez = e[3], erx = e[4], ery = e[5], erz = e[6],
		int = getElementInterior(theGate),
		dim = getElementDimension(theGate),
		door = isDoorObject(theGate),
	}
end

-- [Fix #160] delete an object/gate from the map (shared by /delobj and the panel)
local function removeGateFromMap(thePlayer, theGate)
	local gateID = tonumber(getElementData(theGate, "gate:id"))
	if gateID and gateID > 0 then
		if mysql:query_free("DELETE FROM `gates` WHERE `id` = '" .. mysql:escape_string(tostring(gateID)) .. "'") then
			removeGate(theGate)
			outputChatBox("[GATEMANAGER] Removed gate/object #" .. gateID .. " from the map.", thePlayer, 0, 255, 0)
			return true
		end
		outputChatBox("[GATEMANAGER] Failed to remove gate/object #" .. gateID .. ".", thePlayer, 255, 0, 0)
		return false
	end
	removeGate(theGate)
	outputChatBox("[GATEMANAGER] Removed the temporary object.", thePlayer, 0, 255, 0)
	return true
end

-- ===========================================================================
-- commands
-- ===========================================================================

-- [Fix #160] /makeobj <objectID> [door] - place a persistent object (editor.editObjects)
local function makeObject(thePlayer, commandName, objectID, mode)
	if not hasGateToolRight(thePlayer, "editor.editObjects") then
		denyToolRight(thePlayer)
		return
	end
	objectID = tonumber(objectID)
	if not objectID then
		outputChatBox("SYNTAX: /" .. commandName .. " <objectID> [door]", thePlayer, 255, 194, 14)
		outputChatBox("Pick the object ID from the MTA object ID list - add 'door' to make it openable.", thePlayer, 255, 194, 14)
		return
	end
	if not isValidObjectModel(objectID) then
		outputChatBox("[GATEMANAGER] " .. tostring(objectID) .. " is not a valid object ID.", thePlayer, 255, 0, 0)
		return
	end

	local x, y, z = getElementPosition(thePlayer)
	local rx, ry, rz = 0, 0, getElementRotation(thePlayer)
	local ex, ey, ez, erx, ery, erz = x, y, z, rx, ry, rz
	local isDoor = mode and string.lower(tostring(mode)) == "door"
	if isDoor then
		erz = rz + 90
	end

	local vals = gateValues(objectID, { x, y, z, rx, ry, rz }, { ex, ey, ez, erx, ery, erz },
		getElementInterior(thePlayer), getElementDimension(thePlayer))
	if not vals then
		outputChatBox("[GATEMANAGER] Failed to read your position.", thePlayer, 255, 0, 0)
		return
	end

	local gateID = SmallestID()
	if not gateID then
		outputChatBox("[GATEMANAGER] Failed to allocate a new gate ID.", thePlayer, 255, 0, 0)
		return
	end

	local creator = getElementData(thePlayer, "account:username") or "unknown"
	if mysql:query_free(insertGateSQL(gateID, vals, creator, "placed with /makeobj")) then
		loadOneGate(gateID)
		outputChatBox("[GATEMANAGER] Placed object #" .. gateID .. " (model " .. objectID .. ")"
			.. (isDoor and " as a door." or "."), thePlayer, 0, 255, 0)
		outputChatBox("[GATEMANAGER] Right-click it -> 'Gate edit' to move it or set a move-to target.", thePlayer, 255, 194, 14)
		exports.logs:dbLog(thePlayer, 4, thePlayer, "Makeobj - gate #" .. gateID .. " model " .. objectID .. " at " .. x .. ", " .. y .. ", " .. z)
	else
		outputChatBox("[GATEMANAGER] Failed to place the object.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("makeobj", makeObject, false, false)

-- [Fix #160] /editobj [id] - open the gate edit panel (editObjectProperties)
local function editObjectCommand(thePlayer, commandName, gateID)
	if not hasGateToolRight(thePlayer, "editObjectProperties") then
		denyToolRight(thePlayer)
		return
	end
	local theGate = findNearestGate(thePlayer, gateID, 10)
	if not theGate then return end
	triggerClientEvent(thePlayer, "objedit:openPanel", thePlayer, theGate, getGatePayload(theGate))
end
addCommandHandler("editobj", editObjectCommand, false, false)

-- [Fix #160] /delobj [id] - remove a placed object/gate (editor.removeObjects)
local function deleteObjectCommand(thePlayer, commandName, gateID)
	if not hasGateToolRight(thePlayer, "editor.removeObjects") then
		denyToolRight(thePlayer)
		return
	end
	local theGate = findNearestGate(thePlayer, gateID, 10)
	if not theGate then return end
	removeGateFromMap(thePlayer, theGate)
end
addCommandHandler("delobj", deleteObjectCommand, false, false)

-- [Fix #160] /lockgate [id] and /unlockgate [id] - lockgate right. A locked gate
-- only answers to lockgate holders (enforced in s_gate_action.lua).
local function setGateLock(thePlayer, commandName, gateID)
	if not hasGateToolRight(thePlayer, "lockgate") then
		denyToolRight(thePlayer)
		return
	end
	local theGate = findNearestGate(thePlayer, gateID, 10)
	if not theGate then return end

	local wantLock = (string.lower(tostring(commandName)) == "lockgate")
	local isLocked = getElementData(theGate, "gate:locked") and true or false
	if wantLock == isLocked then
		outputChatBox("[GATEMANAGER] Gate #" .. (tonumber(getElementData(theGate, "gate:id")) or -1)
			.. " is already " .. (wantLock and "locked." or "unlocked."), thePlayer, 255, 194, 14)
		return
	end

	exports.anticheat:changeProtectedElementDataEx(theGate, "gate:locked", wantLock, true)
	local rowID = tonumber(getElementData(theGate, "gate:id")) or -1
	outputChatBox("[GATEMANAGER] Gate #" .. rowID
		.. (wantLock and " LOCKED - only lockgate holders can operate it." or " UNLOCKED."),
		thePlayer, wantLock and 255 or 0, wantLock and 126 or 255, 0)
	exports.logs:dbLog(thePlayer, 4, thePlayer,
		wantLock and ("Lockgate - gate #" .. rowID .. " LOCK") or ("Lockgate - gate #" .. rowID .. " UNLOCK"))
end
addCommandHandler("lockgate", setGateLock, false, false)
addCommandHandler("unlockgate", setGateLock, false, false)

-- [Fix #160] /savemap - flush every loaded object/gate back to the DB (editor.savemap)
local function saveMap(thePlayer, commandName)
	if not hasGateToolRight(thePlayer, "editor.savemap") then
		denyToolRight(thePlayer)
		return
	end
	local saved, skipped = 0, 0
	for _, theGate in ipairs(getElementsByType("object", getResourceRootElement(getThisResource()))) do
		local gateID = tonumber(getElementData(theGate, "gate:id"))
		local params = getElementData(theGate, "gate:parameters")
		if gateID and gateID > 0 and type(params) == "table" and params["startPosition"] and params["endPosition"] then
			-- [Fix #160] positions come from gate:parameters, never from a live
			-- (possibly mid-animation) element, so an open gate cannot be saved open
			local vals = gateValues(getElementModel(theGate), params["startPosition"], params["endPosition"],
				getElementInterior(theGate), getElementDimension(theGate))
			if vals and mysql:query_free(updateGateSQL(gateID, vals)) then
				saved = saved + 1
			else
				skipped = skipped + 1
			end
		end
	end
	outputChatBox("[GATEMANAGER] Map saved - " .. saved .. " object(s)/gate(s) persisted"
		.. (skipped > 0 and (" (" .. skipped .. " skipped).") or "."), thePlayer, 0, 255, 0)
	exports.logs:dbLog(thePlayer, 4, thePlayer, "Savemap - " .. saved .. " rows persisted")
end
addCommandHandler("savemap", saveMap, false, false)

-- [Fix #160] /checkcreator [id] - who placed this gate/object (editor.checkcreator)
local function checkCreator(thePlayer, commandName, gateID)
	if not hasGateToolRight(thePlayer, "editor.checkcreator") then
		denyToolRight(thePlayer)
		return
	end
	local theGate = findNearestGate(thePlayer, gateID, 10)
	if not theGate then return end
	local rowID = tonumber(getElementData(theGate, "gate:id"))
	if not rowID or rowID < 1 then
		outputChatBox("[GATEMANAGER] This object is not saved yet (no creator on record).", thePlayer, 255, 194, 14)
		return
	end
	local row = mysql:query_fetch_assoc("SELECT `objectID`, `creator`, `createdDate` FROM `gates` WHERE `id` = '"
		.. mysql:escape_string(tostring(rowID)) .. "'")
	if not row then
		outputChatBox("[GATEMANAGER] Gate/object #" .. rowID .. " does not exist.", thePlayer, 255, 0, 0)
		return
	end
	local creator = row["creator"]
	if not creator or creator == "" then creator = "unknown" end
	outputChatBox("[GATEMANAGER] #" .. rowID .. " (model " .. tostring(row["objectID"]) .. ") created by "
		.. creator .. " on " .. tostring(row["createdDate"]) .. ".", thePlayer, 255, 194, 14)
end
addCommandHandler("checkcreator", checkCreator, false, false)

-- [Fix #160] /delkey <player> <keyType> <keyID> - revoke a key item (keys.delete).
-- The key type map is the same one /copykey uses (1=House, 2=Business, 3=Vehicle).
local KEY_ITEM_IDS = { [1] = 4, [2] = 5, [3] = 3 }

local function deleteKey(thePlayer, commandName, targetNick, keyType, keyID)
	if not hasGateToolRight(thePlayer, "keys.delete") then
		denyToolRight(thePlayer)
		return
	end
	keyType, keyID = tonumber(keyType), tonumber(keyID)
	if not targetNick or not keyType or not keyID or not KEY_ITEM_IDS[keyType] then
		outputChatBox("SYNTAX: /" .. commandName .. " [Player] [Key Type: 1=House 2=Business 3=Vehicle] [Key ID]",
			thePlayer, 255, 194, 14)
		return
	end
	local target, targetName = exports.global:findPlayerByPartialNick(thePlayer, targetNick)
	if not target then return end

	local itemID = KEY_ITEM_IDS[keyType]
	if not exports.global:hasItem(target, itemID, keyID) then
		outputChatBox(targetName .. " does not have that key.", thePlayer, 255, 0, 0)
		return
	end
	if exports.global:takeItem(target, itemID, keyID) then
		outputChatBox("[GATEMANAGER] Removed key type " .. keyType .. " #" .. keyID .. " from " .. targetName .. ".", thePlayer, 0, 255, 0)
		outputChatBox("Your key type " .. keyType .. " #" .. keyID .. " was revoked by staff.", target, 255, 194, 14)
		exports.logs:dbLog(thePlayer, 4, { target }, "Delkey - type " .. keyType .. " #" .. keyID .. " removed")
	else
		outputChatBox("[GATEMANAGER] Failed to remove that key.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("delkey", deleteKey, false, false)

-- ===========================================================================
-- right-click menu + gate edit panel (client: c_object_panel_fix160.lua)
-- ===========================================================================

-- [Fix #160] right-click on a gate/object -> the options the client may show
addEvent("objedit:requestMenu", true)
addEventHandler("objedit:requestMenu", root, function(theGate)
	if not client or not isManagedGate(theGate) then return end
	if not canReachGate(client, theGate, 10) then return end
	local isDoor = isDoorObject(theGate)
	local canEdit = hasGateToolRight(client, "editObjectProperties")
	if not isDoor and not canEdit then return end
	triggerClientEvent(client, "objedit:showMenu", client, theGate, isDoor, canEdit)
end)

-- [Fix #160] "Gate edit" row of that menu and /editobj both land here
addEvent("objedit:requestPanel", true)
addEventHandler("objedit:requestPanel", root, function(theGate)
	if not client or not isManagedGate(theGate) then return end
	if not hasGateToolRight(client, "editObjectProperties") then
		denyToolRight(client, "You don't have permission to edit objects.")
		return
	end
	if not canReachGate(client, theGate, 10) then
		outputChatBox("[GATEMANAGER] You are too far away to edit this object.", client, 255, 194, 14)
		return
	end
	triggerClientEvent(client, "objedit:openPanel", client, theGate, getGatePayload(theGate))
end)

-- [Fix #160] panel Save: model, position, move-to target, interior/dimension (editObjectProperties)
addEvent("objedit:save", true)
addEventHandler("objedit:save", root, function(theGate, model, sx, sy, sz, srx, sry, srz, ex, ey, ez, erx, ery, erz, int, dim)
	if not client or not isManagedGate(theGate) then return end
	if not hasGateToolRight(client, "editObjectProperties") then
		denyToolRight(client, "You don't have permission to edit objects.")
		return
	end
	if not canReachGate(client, theGate, 15) then
		outputChatBox("[GATEMANAGER] You are too far away to edit this object.", client, 255, 194, 14)
		return
	end

	local vals = gateValues(model, { sx, sy, sz, srx, sry, srz }, { ex, ey, ez, erx, ery, erz },
		math.floor(tonumber(int) or 0), math.floor(tonumber(dim) or 0))
	if not vals then
		outputChatBox("[GATEMANAGER] Every field must be a number.", client, 255, 0, 0)
		return
	end
	if not isValidObjectModel(vals[1]) then
		outputChatBox("[GATEMANAGER] " .. tostring(vals[1]) .. " is not a valid object ID.", client, 255, 0, 0)
		return
	end
	vals[14] = math.floor(vals[14])
	vals[15] = math.floor(vals[15])

	local gateID = tonumber(getElementData(theGate, "gate:id"))
	local creator = getElementData(client, "account:username") or "unknown"

	if gateID and gateID > 0 then
		if mysql:query_free(updateGateSQL(gateID, vals)) then
			removeGate(theGate)
			loadOneGate(gateID)
			outputChatBox("[GATEMANAGER] Saved gate/object #" .. gateID .. ".", client, 0, 255, 0)
			exports.logs:dbLog(client, 4, client, "Editobj - gate #" .. gateID .. " saved model " .. vals[1])
		else
			outputChatBox("[GATEMANAGER] Failed to save gate/object #" .. gateID .. ".", client, 255, 0, 0)
		end
		return
	end

	-- [Fix #160] a fresh temp object (from /newgate) - persist it as a new row
	local newID = SmallestID()
	if not newID then
		outputChatBox("[GATEMANAGER] Failed to allocate a new gate ID.", client, 255, 0, 0)
		return
	end
	if mysql:query_free(insertGateSQL(newID, vals, creator, "created with /newgate")) then
		removeGate(theGate)
		loadOneGate(newID)
		outputChatBox("[GATEMANAGER] Created gate/object #" .. newID .. ".", client, 0, 255, 0)
		exports.logs:dbLog(client, 4, client, "Newgate - gate #" .. newID .. " model " .. vals[1])
	else
		outputChatBox("[GATEMANAGER] Failed to create the gate.", client, 255, 0, 0)
	end
end)

-- [Fix #160] panel Delete button (editor.removeObjects)
addEvent("objedit:delete", true)
addEventHandler("objedit:delete", root, function(theGate)
	if not client or not isManagedGate(theGate) then return end
	if not hasGateToolRight(client, "editor.removeObjects") then
		denyToolRight(client, "You don't have permission to remove objects.")
		return
	end
	if not canReachGate(client, theGate, 15) then
		outputChatBox("[GATEMANAGER] You are too far away to edit this object.", client, 255, 194, 14)
		return
	end
	removeGateFromMap(client, theGate)
end)

-- [Fix #160] /newgate flow: drop the temporary object once its row was saved
addEvent("objedit:destroyTemp", true)
addEventHandler("objedit:destroyTemp", root, function(theObject)
	if not client or not isElement(theObject) then return end
	if getElementType(theObject) ~= "object" then return end
	if getElementParent(theObject) ~= getResourceRootElement(getThisResource()) then return end
	if tonumber(getElementData(theObject, "gate:id")) ~= -1 then return end
	removeGate(theObject)
end)
