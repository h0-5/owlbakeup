-- owlbakeup Fix #63 - Mechanic Panel SERVER, rebuilt from the client
-- contract ([jobs]/mechanical/mech_c_decompiled.lua + mech_shared, Fix #54
-- pattern):
--   mechanic:repairBody(vehicle)      -> body price math (mech_shared's
--     calculateRepairPrice verbatim), charges the panel opener, fixes
--     doors/panels/wheels.
--   mechanic:repairEngine(vehicle)    -> (1 - health/1000) * 2000 price,
--     charges + fixes.
--   mechanic:repairWheels(vehicle, w) -> wheel state * 50, charges + fixes.
--   mechanic:addUpgrade/removeUpgrade(vehicle, id, price) -> server-side
--     price validation from upgrades.xml (server copy of veh_upgrades),
--     charges + applies the upgrade.
--   mechanic:changeVehicleColor(vehicle, colors) $1000 ->
--     setVehicleColor RGB x4.
--   mechanic:changeLightsColor(vehicle, r, g, b) $1500 ->
--     setVehicleHeadLightColor.
-- The payer is the panel OPENER (the decompiled client gates on
-- getPlayerMoney(localPlayer) before removing the price row - verbatim).
-- No job gating / EXP / salary calls exist in the decompiles - this is a
-- vehicle service panel, not a gated job (documented).
-- [Fix #110] the "mechanic_panel" faction permission from the F3 Tools tab
-- (Mechanic type 7 / Traffic type 9, min rank 3 or faction leader) now gates
-- every mechanic:* event below. The "no job gating" note above still holds -
-- no job/EXP requirement was added - but the panel is a faction tool now.

-- [Fix #110] server gate for the panel: pcall + fail-open, the same shape as
-- the Fix #56 permission gates in spike-system / roadblock-system - if
-- faction-system is stopped the call fails and the panel keeps its old
-- (ungated) behaviour.
local function hasMechanicPanelPermission(player)
	local okPerm, hasPerm = pcall(function()
		return exports["faction-system"]:doesPlayerHaveFactionPermission(player, "mechanic_panel")
	end)
	return (not okPerm) or (hasPerm ~= false)
end

local veh_upgrades = {}

local function bodyRepairPrice(vehicle)
	local total = 0
	for door = 0, 5 do
		total = total + getVehicleDoorState(vehicle, door) * 100
	end
	for pane = 0, 6 do
		total = total + getVehiclePanelState(vehicle, pane) * 100
	end
	return math.floor(total)
end

local function charge(player, price, vehicle)
	local money = tonumber(getElementData(player, "money")) or 0
	if money < price then
		return false
	end
	if price > 0 then
		exports.global:takeMoney(player, price)
	end
	return true
end

local function isServiceVehicle(vehicle, player)
	if not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" or not isElement(player) then
		return false
	end
	local px, py, pz = getElementPosition(player)
	local vx, vy, vz = getElementPosition(vehicle)
	return getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz) <= 10
end

addEvent("mechanic:repairBody", true)
addEventHandler("mechanic:repairBody", root, function(vehicle)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) then
		return
	end
	local price = bodyRepairPrice(vehicle)
	if not charge(player, price, vehicle) then
		return
	end
	for door = 0, 5 do
		setVehicleDoorState(vehicle, door, 0)
	end
	for pane = 0, 6 do
		setVehiclePanelState(vehicle, pane, 0)
	end
	exports.notifications:outputToPlayer(player, "تم إصلاح هيكل المركبة", 4000, "success")
end)

addEvent("mechanic:repairEngine", true)
addEventHandler("mechanic:repairEngine", root, function(vehicle)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) then
		return
	end
	local price = math.floor((1 - getElementHealth(vehicle) / 1000) * 2000)
	if not charge(player, price, vehicle) then
		return
	end
	fixVehicle(vehicle)
	exports.notifications:outputToPlayer(player, "تم إصلاح محرك المركبة", 4000, "success")
end)

addEvent("mechanic:repairWheels", true)
addEventHandler("mechanic:repairWheels", root, function(vehicle, wheel)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) or not tonumber(wheel) then
		return
	end
	local price = getVehicleWheelState(vehicle, tonumber(wheel)) * 50
	if not charge(player, price, vehicle) then
		return
	end
	setVehicleWheelState(vehicle, tonumber(wheel), 0)
	exports.notifications:outputToPlayer(player, "تم إصلاح إطار المركبة", 4000, "success")
end)

addEvent("mechanic:addUpgrade", true)
addEventHandler("mechanic:addUpgrade", root, function(vehicle, upgradeID, price)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) or not tonumber(upgradeID) or not tonumber(price) then
		return
	end
	local info = veh_upgrades[tostring(tonumber(upgradeID))]
	if not info or info.price ~= tonumber(price) then
		return -- price must match the server catalog
	end
	if getVehicleUpgradeOnSlot(vehicle, getVehicleUpgradeSlotFromUpgrade(tonumber(upgradeID))) ~= 0 then
		return -- slot occupied; the client offers removal instead
	end
	if not charge(player, info.price, vehicle) then
		return
	end
	addVehicleUpgrade(vehicle, tonumber(upgradeID))
end)

addEvent("mechanic:removeUpgrade", true)
addEventHandler("mechanic:removeUpgrade", root, function(vehicle, upgradeID, price)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) or not tonumber(upgradeID) then
		return
	end
	removeVehicleUpgrade(vehicle, tonumber(upgradeID))
end)

addEvent("mechanic:changeVehicleColor", true)
addEventHandler("mechanic:changeVehicleColor", root, function(vehicle, colors)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) or type(colors) ~= "table" or #colors ~= 4 then
		return
	end
	local money = tonumber(getElementData(player, "money")) or 0
	if money < 1000 then
		return
	end
	exports.global:takeMoney(player, 1000)
	setVehicleColor(vehicle, colors[1][1], colors[1][2], colors[1][3], colors[2][1], colors[2][2], colors[2][3], colors[3][1], colors[3][2], colors[3][3], colors[4][1], colors[4][2], colors[4][3])
	exports.notifications:outputToPlayer(player, "تم تغيير ألوان المركبة", 4000, "success")
end)

addEvent("mechanic:changeLightsColor", true)
addEventHandler("mechanic:changeLightsColor", root, function(vehicle, r, g, b)
	local player = client
	-- [Fix #110] F3 Tools "Mechanic Panel" toggle (Faction permission, server
	-- authority) - denial uses this file's Arabic notification style.
	if not hasMechanicPanelPermission(player) then
		exports.notifications:outputToPlayer(player, "لا تملك صلاحية لوحة الميكانيكي.", 4000, "error")
		return
	end
	if not isServiceVehicle(vehicle, player) or not tonumber(r) or not tonumber(g) or not tonumber(b) then
		return
	end
	local money = tonumber(getElementData(player, "money")) or 0
	if money < 1500 then
		return
	end
	exports.global:takeMoney(player, 1500)
	setVehicleHeadLightColor(vehicle, tonumber(r), tonumber(g), tonumber(b))
	exports.notifications:outputToPlayer(player, "تم تغيير لون إضاءة المركبة", 4000, "success")
end)

addEventHandler("onResourceStart", resourceRoot, function()
	-- server copy of the client's veh_upgrades (price validation)
	local xml = xmlLoadFile("mechanical/upgrades.xml")
	if xml then
		for _, node in ipairs(xmlNodeGetChildren(xml)) do
			veh_upgrades[xmlNodeGetAttribute(node, "id")] = {
				name = xmlNodeGetAttribute(node, "name"),
				price = tonumber(xmlNodeGetAttribute(node, "price")) or 2000
			}
		end
		xmlUnloadFile(xml)
	end
end)
