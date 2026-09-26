--MAXIME
mysql = exports.mysql

function setServerIP(thePlayer, commandName, ...)
	if (exports.integration:isPlayerSeniorAdmin(thePlayer)) then
		if not (...) then
			outputChatBox("SYNTAX: " .. commandName .. " [message]", thePlayer, 255, 194, 14)
		else
			local message = table.concat({...}, " ")
			local query = mysql:query_free("UPDATE `settings` SET `value`='" .. mysql:escape_string(message) .. "' WHERE `name`='serverip'")
			if (query) then
				outputChatBox("Server IP is set to '" .. message .. "'.", thePlayer, 0, 255, 0)
				exports.logs:dbLog(thePlayer, 4, thePlayer, "SETSERVERIP "..message)
				exports.anticheat:changeProtectedElementDataEx(getRootElement(), "serverip", message, false )
			else
				outputChatBox("Failed to set server IP.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setserverip", setServerIP, false, false)

-- Admin announcement
function adminAnnouncement(thePlayer, commandName, ...)
	local logged = getElementData(thePlayer, "loggedin")
	
	if(logged==1) and (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer))  then
		if not (...) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Message]", thePlayer, 255, 194, 14)
		else
			local message = table.concat({...}, " ")
			local players = exports.pool:getPoolElementsByType("player")
			local username = getPlayerName(thePlayer)

			for k, arrayPlayer in ipairs(players) do
				local logged = getElementData(arrayPlayer, "loggedin")
				
				if exports.integration:isPlayerTrialAdmin(thePlayer) then
					triggerClientEvent(arrayPlayer,"announcement:post", arrayPlayer, "Admin Announcement: " .. message, 255, 194, 14, 1)
				elseif exports.integration:isPlayerSupporter(thePlayer) then
					triggerClientEvent(arrayPlayer,"announcement:post", arrayPlayer, "SUP Announcement: " .. message, 255, 100, 150, 1)
				end
			end
			exports.global:sendMessageToAdmins("Adm/SUPCmd: "..username.." made an announcement")
			exports.logs:dbLog(thePlayer, 4, thePlayer, "ANN "..message)
			--exports.text2speech:convertTextToSpeech(root, message, "en", nil, 1, 50, 1) 
		end
	end
end
addCommandHandler("ann", adminAnnouncement, false, false)

function sendTopNotification(sendTo, msg, r, b, g, playsound)
	triggerClientEvent(sendTo,"announcement:post", sendTo, msg, r, b, g, playsound)
end