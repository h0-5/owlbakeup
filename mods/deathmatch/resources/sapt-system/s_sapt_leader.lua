--[[ SAPT Leader commands.
Add, edit or remove routes, lines or destinations ]]--

currentRoutes = { }
currentLines = { }
currentDestinations = { }

function showIBISAdmin(thePlayer, commandName)
	if (getElementData(thePlayer, "faction") == 64) then
		if (getElementData(thePlayer, "factionleader") == 1) then
			triggerClientEvent(thePlayer, "sapt:client_showIBISAdmin", thePlayer, currentRoutes, currentLines, currentDestinations)
		end
	end
end
addCommandHandler("ibisadmin", showIBISAdmin, false, false)
