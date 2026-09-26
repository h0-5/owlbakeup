--
-- vgScoreboard v1.0
-- Server-side script.
-- By Alberto "ryden" Alonso
--


local scoreboardDummy

--[[
* onResourceStart
Handles the resource start event to create a dummy entity with information about the server.
--]]
addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()), function ()
	scoreboardDummy = createElement ( "scoreboard" )
	setElementData ( scoreboardDummy, "serverName", "Direct-Hosting" )
	setElementData ( scoreboardDummy, "maxPlayers", getMaxPlayers () )
	setElementData ( scoreboardDummy, "allow", true )
	
	--[[ Uncomment to test with dummies ]]--
	--[[
	for k=70,270 do
		local dummy = createElement ( "playerDummy" )
		setElementData ( dummy, "playerid", k )
		setElementData ( dummy, "name", "dummy" .. tostring(k), false )
		setElementData ( dummy, "ping", math.random ( 1, 300 ) )
		setElementData ( dummy, "color", { math.random(0,255), math.random(0,255), math.random(0,255) } )
	end
	--]]
end, false )

--[[
* onResourceStop
Delete the dummy created on resource start.
--]]
addEventHandler ( "onResourceStop", getResourceRootElement(getThisResource()), function ()
	if scoreboardDummy then
		destroyElement ( scoreboardDummy )
	end
end, false )

-- highest player count sync: tracks the peak online count and pushes it to
-- all clients every 30 seconds (replaces the original play-time/public based sync).

local highestPlayerCount = 0

setTimer ( function ()

	local current = getPlayerCount ()

	if current > highestPlayerCount then

		highestPlayerCount = current

	end

	triggerClientEvent ( root, "scoreboard:highestPlayerCount:sync", root, highestPlayerCount )

end, 30000, 0 )
