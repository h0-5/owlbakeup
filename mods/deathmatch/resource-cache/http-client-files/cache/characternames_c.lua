--MAXIME
local characterNameCache = {}
local searched = {}
local refreshCacheRate = 10 --Minutes
function getCharacterNameFromID( id )
	if not id or not tonumber(id) then
		outputDebugString("Client cache: id is empty.")
		return false
	else
		id = tonumber(id)
	end
	
	if characterNameCache[id] then
		outputDebugString("Client cache: characterName found in cache - "..characterNameCache[id]) 
		return characterNameCache[id]
	end
	
	outputDebugString("Client cache: characterName not found in cache. Searching in all current online players.")
	for i, player in pairs(getElementsByType("player")) do
		if id == getElementData(player, "dbid") then
			characterNameCache[id] = exports.global:getPlayerName(player)
			outputDebugString("Client cache: characterName found in current online players. - "..characterNameCache[id]) 
			return characterNameCache[id]
		end
	end
	
	if searched[id] then
		outputDebugString("Client cache: Previously requested for server's cache but not found. Searching cancelled.")
		return false
	end
	searched[id] = true
	
	outputDebugString("Client cache: Username not found in all current online players. Requesting for server's cache.")
	triggerServerEvent("requestCharacterNameCacheFromServer", localPlayer, id)
	
	setTimer(function()
		local index = id
		searched[index] = nil
	end, refreshCacheRate*1000*60, 1)

	return "Loading.."
end

function retrieveCharacterNameCacheFromServer(characterName, id)
	outputDebugString("Client cache: Retrieving data from server and adding to client's cache.")
	if characterName and id then
		characterNameCache[id] = characterName
	end
end
addEvent("retrieveCharacterNameCacheFromServer", true)
addEventHandler("retrieveCharacterNameCacheFromServer", root, retrieveCharacterNameCacheFromServer)