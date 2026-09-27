--------------------------------------------------------------------------------
-- VORTEX HUD — server
-- Old client event names preserved exactly (backupm hud resource) so restored
-- resources (life-system, bios-coins, ...) can talk to the hud again.
--------------------------------------------------------------------------------

-- [old client] typing relay: client sends latent "typing:sync", we relay to
-- nearby players so their nametags can draw ((TYPING...))
addEvent("typing:sync", true)
addEventHandler("typing:sync", root, function(state)
	if client ~= source or not isElement(source) then return end
	local sX, sY, sZ = getElementPosition(source)
	for _, player in ipairs(getElementsByType("player")) do
		if player ~= source and isElement(player) then
			local pX, pY, pZ = getElementPosition(player)
			if getDistanceBetweenPoints3D(sX, sY, sZ, pX, pY, pZ) <= 60 then
				triggerClientEvent(player, "typing:sync", source, state)
			end
		end
	end
end)

-- [old client] strip item clicks (single router, routes onto this server's
-- existing systems instead of the ones that are not restored yet)
addEvent("hud:onHudItemClick", true)
addEventHandler("hud:onHudItemClick", root, function(item)
	local player = client
	if not player or client ~= source then return end
	if item == "walkingstyle" then
		triggerEvent("realism:switchWalkingStyle", player)
	elseif item == "togpm" then
		triggerEvent("chat:togpm", player, player)
	elseif item == "ads" then
		triggerEvent("advertisements:open_ads", player)
	elseif item == "seatbelt" then
		triggerEvent("realism:seatbelt:toggle", player, player)
	elseif item == "reportpanel" then
		-- classic report window stays owned by report-system (/report)
	end
end)

-- [old client] vehicle quick actions
addEvent("hud:engine", true)
addEventHandler("hud:engine", root, function()
	local player = client
	if player and client == source then
		triggerEvent("toggleEngine", player, player)
	end
end)

addEvent("hud:handbrake", true)
addEventHandler("hud:handbrake", root, function()
	local player = client
	if player and client == source then
		triggerEvent("vehicle:handbrake", player, false, "hud")
	end
end)

addEvent("hud:lockvehicle", true)
addEventHandler("hud:lockvehicle", root, function()
	local player = client
	if player and client == source then
		triggerEvent("togLockVehicle", player, player)
	end
end)

addEvent("hud:vehiclelights", true)
addEventHandler("hud:vehiclelights", root, function()
	local player = client
	if player and client == source then
		triggerEvent("togLightsVehicle", player)
	end
end)

-- [old client] heart cleanup hook (life-system boost item) — guarded so it is
-- a no-op until the life-system is restored
addEvent("hud:remove_heart", true)
addEventHandler("hud:remove_heart", root, function()
	local player = client
	if not player or client ~= source then return end
	if getElementHealth(player) > 40 then
		local items = getElementData(player, "hud:items") or {}
		for i, item in ipairs(items) do
			if item[1] == "heart" then
				table.remove(items, i)
				setElementData(player, "hud:items", items)
				break
			end
		end
	end
end)
