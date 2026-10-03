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
-- [Fix batch 171] /ann is gated by the admin.ann RIGHT (command_gates_s.lua
-- maps "ann" -> "admin.ann"), but this handler only asked the LEGACY identity
-- checks below (isPlayerTrialAdmin / isPlayerSupporter read admin.isAdmin /
-- admin.isStaff off the player's rank). A rank that holds admin.ann without
-- those two identity rights (the owner's current rank: staff_role_members
-- RoleID 22 = staff_roles 'hidden', rights 7379 chars, admin.ann=true,
-- admin.isAdmin/admin.isStaff ABSENT) passed the gate and then fell through
-- this condition SILENTLY -> no banner, no card, no toast, no dbLog row
-- (owl_logs ANN rows: 2026-09-29 03:41, 2026-10-03 02:32, 02:33, 16:52 -
-- nothing after the 17:50 restart). The right is now the primary check, the
-- legacy identity checks stay as the fallback for rank-less / legacy staff.
-- Fail-closed on a dead admin-system, same idiom as chat-system hasOocRight.
function hasAnnRight(thePlayer)
	if not isElement(thePlayer) or getElementType(thePlayer) ~= "player" then
		return false
	end
	local ok, res = pcall(function()
		return exports["admin-system"]:playerHasRight(thePlayer, "admin.ann")
	end)
	return ok and res and true or false
end

function adminAnnouncement(thePlayer, commandName, ...)
	local logged = getElementData(thePlayer, "loggedin")
	
	if(logged==1) and ( hasAnnRight(thePlayer) or exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) ) then
		if not (...) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Message]", thePlayer, 255, 194, 14)
		else
			local message = table.concat({...}, " ")
			local players = exports.pool:getPoolElementsByType("player")
			local username = getPlayerName(thePlayer)

			-- [Fix batch 172] no word on the card: the raw message goes out as-is.
			-- The owner does not want "Admin: " / "SUP: " prepended; the gate above
			-- (admin.ann + legacy identity fallback) is untouched, and every other
			-- announcement:post producer (this file's sendTopNotification export and
			-- mysql/s_server_global_maintenance) already passes its own string, so
			-- nothing relied on the prefix.
			local annText, annR, annG, annB = message, 255, 194, 14
						-- [Fix batch 171] the notifications pill is NOT sent anymore: the
			-- card is the ONE visible surface. The pill would stack a second
			-- copy at y 60-100 (its stackTop lives in his dirty
			-- notifications/c_notifications.lua, so it can never be moved to
			-- the reference slot from here without editing his file).						for k, arrayPlayer in ipairs(players) do				triggerClientEvent(arrayPlayer, "announcement:post", arrayPlayer, annText, annR, annG, annB, 1)
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