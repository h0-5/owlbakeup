-- notifications - server relay (Fix #59)
-- The Owl server for the F6 notification-center did not survive the backup;
-- this server exposes the same event surface other Owl resources trigger.

local function sendNotification(title, text, time, horizontalAlign, verticalAlign, id)
	triggerClientEvent(client, "notifications:sendNotification", client, title, text, time, horizontalAlign, verticalAlign, id)
end
addEvent("notifications:sendNotification", true)
addEventHandler("notifications:sendNotification", root, sendNotification)

local function output(text, duration, ntype, align)
	triggerClientEvent(client, "notifications:output", client, text, duration, ntype, align)
end
addEvent("notifications:output", true)
addEventHandler("notifications:output", root, output)

local function showDirective(text, color, timeout)
	triggerClientEvent(client, "notifications:showDirective", client, text, color, timeout)
end
addEvent("notifications:showDirective", true)
addEventHandler("notifications:showDirective", root, showDirective)

local function hideDirective()
	triggerClientEvent(client, "notifications:hideDirective", client)
end
addEvent("notifications:hideDirective", true)
addEventHandler("notifications:hideDirective", root, hideDirective)

local function showKeyDescription(code, keyText, text, color)
	triggerClientEvent(client, "notifications:showKeyDescription", client, code, keyText, text, color)
end
addEvent("notifications:showKeyDescription", true)
addEventHandler("notifications:showKeyDescription", root, showKeyDescription)

local function hideKeyDescription(code)
	triggerClientEvent(client, "notifications:hideKeyDescription", client, code)
end
addEvent("notifications:hideKeyDescription", true)
addEventHandler("notifications:hideKeyDescription", root, hideKeyDescription)

-- server-authoritative helpers for other Owl resources
function outputToPlayer(player, text, duration, ntype, align)
	if isElement(player) then
		triggerClientEvent(player, "notifications:output", player, text, duration, ntype, align)
	end
end
