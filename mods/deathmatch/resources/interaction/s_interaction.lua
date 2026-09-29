-- interaction - server (Fix #59)
-- Registers the server-side menu events and re-adds the admin "Edit" option
-- for NPC peds exactly like the old server did (the ped editor lives in the
-- ped-system client and listens for onClientElementMenuClick(ped, "Edit", data)).

addEvent("onClientElementMenuShow:Server", true)
addEvent("onClientElementMenuClick:Server", true)

addEventHandler("onClientElementMenuShow:Server", root, function(element, distance)
	if client ~= source then
		return
	end
	if not isElement(element) or getElementType(element) ~= "ped" then
		return
	end
	if distance and distance > 3 then
		return
	end
	if not exports.integration:isPlayerTrialAdmin(client) then
		return
	end
	local pedID = tonumber(getElementData(element, "dbid")) or tonumber(getElementData(element, "rpp.npc.dbid"))
	if not pedID or pedID <= 0 then
		return
	end
	triggerClientEvent(client, "interaction:addInteractOption", client, element, {
		text = "Edit",
		data = { ID = pedID },
	})
end)
