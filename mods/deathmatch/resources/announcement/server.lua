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

			-- [Fix] one text feeds BOTH the scrolling banner and the client			-- notification toast further down, so the two can never disagree.			local annText, annR, annG, annB			if exports.integration:isPlayerTrialAdmin(thePlayer) then				annText, annR, annG, annB = "Admin Announcement: " .. message, 255, 194, 14			else				annText, annR, annG, annB = "SUP Announcement: " .. message, 255, 100, 150			end						-- [user] /ann also fires a CLIENT side toast through the notifications			-- resource; guarded + pcall so a stopped notifications resource can			-- never break the announcement itself.			local notiRes = getResourceFromName("notifications")			local notiReady = notiRes and getResourceState(notiRes) == "running"						for k, arrayPlayer in ipairs(players) do				triggerClientEvent(arrayPlayer, "announcement:post", arrayPlayer, annText, annR, annG, annB, 1)				if notiReady then					pcall(function()						exports.notifications:outputToPlayer(arrayPlayer, annText, 8000, "megaphone")					end)				end			end
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