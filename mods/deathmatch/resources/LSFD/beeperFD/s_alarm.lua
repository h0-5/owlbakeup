
--server
local x1, y1, z1 = 1721.361328125, -1120.359375, 24.085935592651 
function triggerTheAlarm(thePlayer)
	if getPlayerTeam(thePlayer) ~= getTeamFromName("Los Santos Fire Department") then
		return false
	end

	local x, y, z = getElementPosition(thePlayer)
	local distance = getDistanceBetweenPoints3D(x1, y1, z1, x, y, z)
	if (distance > 5) then
		return false
	end
	
	--Makes /me emote for each fd members.
	local fireTeam = getTeamFromName("Los Santos Fire Department")
    if (fireTeam) then
		local playersOnFireTeam = getPlayersInTeam ( fireTeam ) 
        for k, v in ipairs (playersOnFireTeam) do
			exports.global:sendLocalDoAction(v, "The sound of a beeper going off can be heard off " .. exports.global:getPlayerName(v) .."'s person.")
		end
	end
	local players = getElementsByType("player")
	for i, player in ipairs (players) do
		--Start playing alarm sound to all players around the spot.
		x, y, z = getElementPosition(player)
		if getDistanceBetweenPoints3D(x1, y1, z1, x, y, z) <= 5 then
			triggerClientEvent(player,"playAlarmAroundTheArea", thePlayer)
		end
		--Start playing pager sound to everyone that is around the player that had been received the pager.
		local theTeam = getPlayerTeam(player)
		if theTeam and getTeamName(theTeam) == "Los Santos Fire Department" then
			triggerClientEvent(player,"notifyAnFdMember", thePlayer) --Start sending pager to FD members.
			for k, p in ipairs(players) do
				local x2, y2, z2 = getElementPosition(p)
				if getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) <= 5 then
					triggerClientEvent(p,"playPagerSfxAround", player)
				end
			end
		end
	end 
end
addCommandHandler("alarm", triggerTheAlarm)
-- it's done I think, let's test. Wanna come on dev server? or I ask someone? ya i will -- password: yesyesyes k
-- its thePlayer because its 'k got it. haha
-- This all works perfectly. It triggers the client event (line 12), tell me when you are here.

-- This 