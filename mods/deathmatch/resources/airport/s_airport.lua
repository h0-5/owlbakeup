-- owlbakeup Fix #63 - airport SERVER, rebuilt from the client contract
-- ([rp]/airport/client_decompiled.lua, Fix #54 phone pattern):
--   airport:get_travel_tickets        -> ticket list {code, from, to, price}
--   airport:select_ticket(code)       -> pay + move to the plane gate + start
--                                        the flight: the pilot:flight timer
--                                        (pilot resource) counts it down and
--                                        the passenger lands at destination.
-- The ticket table/prices and the gate coordinates are RECONSTRUCTED (the
-- old server was lost); the ticket schema {code, from, to} is verbatim from
-- the client gridlist contract. The mobile-app booking mentioned in the
-- intro text has no client decompile - deferred.

local TICKETS = {
	{ code = "LS-SF", from = "Los Santos", to = "San Fierro", price = 500 },
	{ code = "LS-LV", from = "Los Santos", to = "Las Venturas", price = 500 },
	{ code = "SF-LV", from = "San Fierro", to = "Las Venturas", price = 500 },
	{ code = "SF-LS", from = "San Fierro", to = "Los Santos", price = 500 },
	{ code = "LV-LS", from = "Las Venturas", to = "Los Santos", price = 500 },
	{ code = "LV-SF", from = "Las Venturas", to = "San Fierro", price = 500 }
}

-- gate position per city + a short flight time (reconstructed coordinates)
local CITY_GATES = {
	["Los Santos"] = { 1686.4, -2334.4, 13.5 },
	["San Fierro"] = { 1319.1, -1416.5, 13.4 },
	["Las Venturas"] = { 1600.8, 1810.2, 13.5 }
}
local FLIGHT_TIME_MS = 30000

local flights = {} -- [player] = { ticket, timer }

addEvent("airport:get_travel_tickets", true)
addEventHandler("airport:get_travel_tickets", root, function()
	local player = client
	if not player then
		return
	end
	triggerClientEvent(player, "airport:get_travel_tickets:callback", player, TICKETS)
end)

addEvent("airport:select_ticket", true)
addEventHandler("airport:select_ticket", root, function(code)
	local player = client
	if not player or type(code) ~= "string" or flights[player] then
		return
	end
	if getElementData(player, "loggedin") ~= 1 then
		return
	end
	local ticket
	for _, t in ipairs(TICKETS) do
		if t.code == code then
			ticket = t
			break
		end
	end
	if not ticket then
		return
	end
	local money = tonumber(getElementData(player, "money")) or 0
	if money < ticket.price then
		exports.notifications:outputToPlayer(player, "لاتملك ما يكفي لسعر التذكرة $" .. ticket.price, 5000, "error")
		return
	end
	exports.global:takeMoney(player, ticket.price)
	local fromGate = CITY_GATES[ticket.from]
	local toGate = CITY_GATES[ticket.to]
	if not fromGate or not toGate then
		return
	end
	setElementPosition(player, fromGate[1] + 2, fromGate[2] + 2, fromGate[3])
	setElementInterior(player, 0)
	setElementDimension(player, 0)
	exports.notifications:outputToPlayer(player, "توجهت لبوابة الطائرة - الرحلة تنطلق الآن", 5000, "info")
	triggerClientEvent(player, "pilot:start_flight", player, FLIGHT_TIME_MS / 1000)
	fadeCamera(player, false, 1)
	setTimer(function(player, ticket, toGate)
		if not isElement(player) then
			return
		end
		flights[player] = nil
		setElementPosition(player, toGate[1], toGate[2], toGate[3] + 1)
		setElementInterior(player, 0)
		setElementDimension(player, 0)
		fadeCamera(player, true, 1)
		triggerClientEvent(player, "pilot:end_flight", player)
		exports.notifications:outputToPlayer(player, "وصلت إلى " .. ticket.to .. " - رحلة سعيدة", 6000, "success")
	end, FLIGHT_TIME_MS, 1, player, ticket, toGate)
	flights[player] = { ticket = ticket }
end)

addEventHandler("onPlayerQuit", root, function()
	flights[source] = nil
end)
