function marry(thePlayer, commandName, player1, player2)
	-- [Fix #110] F3 Tools "marry" toggle (Government type 3, min rank 6 /	-- faction leader). The legacy admin check is kept as an explicit bypass,	-- so admins retain exactly today's access; every other player needs the	-- faction permission. pcall + fail-open mirrors the Fix #56 gates in	-- spike-system / roadblock-system: if faction-system is stopped the pcall	-- fails and the admin-only rule below stays authoritative (Fix #46 class).	local adminBypass = exports.integration:isPlayerAdmin(thePlayer)	local okPerm, hasPerm = pcall(function()		return exports["faction-system"]:doesPlayerHaveFactionPermission(thePlayer, "marry")	end)		if not adminBypass and (not okPerm or hasPerm == false) then		outputChatBox( "You do not have permission to use this command.", thePlayer, 255, 0, 0 )	else
		if not player1 or not player2 then
			outputChatBox( "SYNTAX: /" .. commandName .. " [player] [player]", thePlayer, 255, 194, 14 )
		else
			local player1, player1name = exports.global:findPlayerByPartialNick( thePlayer, player1 )
			if player1 then
				local player2, player2name = exports.global:findPlayerByPartialNick( thePlayer, player2 )
				if player2 then
					-- check if one of the players is already married
					local p1r = mysql:query_fetch_assoc("SELECT COUNT(*) as numbr FROM characters WHERE marriedto = " .. mysql:escape_string(getElementData( player1, "dbid" )) )
					if p1r then
						if tonumber( p1r["numbr"] ) == 0 then
							local p2r = mysql:query_fetch_assoc("SELECT COUNT(*) as numbr FROM characters WHERE marriedto = " .. mysql:escape_string(getElementData( player2, "dbid" )) )
							if p2r then
								if tonumber( p2r["numbr"] ) == 0 then
									mysql:query_free("UPDATE characters SET marriedto = " .. mysql:escape_string(getElementData( player1, "dbid" )) .. " WHERE id = " .. mysql:escape_string(getElementData( player2, "dbid" )) )
									mysql:query_free("UPDATE characters SET marriedto = " .. mysql:escape_string(getElementData( player2, "dbid" )) .. " WHERE id = " .. mysql:escape_string(getElementData( player1, "dbid" )) ) 
									
									outputChatBox( "You are now married to " .. player2name .. ".", player1, 0, 255, 0 )
									outputChatBox( "You are now married to " .. player1name .. ".", player2, 0, 255, 0 )
									
									exports['cache']:clearCharacterName( getElementData( player1, "dbid" ) )
									exports['cache']:clearCharacterName( getElementData( player2, "dbid" ) )
									
									outputChatBox( player1name .. " and " .. player2name .. " are now married.", thePlayer, 255, 194, 14 )
								else
									outputChatBox( player2name .. " is already married.", thePlayer, 255, 0, 0 )
								end
							end
						else
							outputChatBox( player1name .. " is already married.", thePlayer, 255, 0, 0 )
						end
					end
				end
			end
		end
	end
end
addCommandHandler("marry", marry)

function divorce(thePlayer, commandName, targetPlayer)
	-- [Fix #110] F3 Tools "divorce" toggle (Government type 3, min rank 6 /	-- faction leader); admin bypass + pcall fail-open, see marry above.	local adminBypass = exports.integration:isPlayerAdmin(thePlayer)	local okPerm, hasPerm = pcall(function()		return exports["faction-system"]:doesPlayerHaveFactionPermission(thePlayer, "divorce")	end)		if not adminBypass and (not okPerm or hasPerm == false) then		outputChatBox( "You do not have permission to use this command.", thePlayer, 255, 0, 0 )	else
		if not targetPlayer then
			outputChatBox( "SYNTAX: /" .. commandName .. " [player]", thePlayer, 255, 194, 14 )
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick( thePlayer, targetPlayer )
			if targetPlayer then
				local marriedto = mysql:query_fetch_assoc("SELECT marriedto FROM characters WHERE id = " .. mysql:escape_string(getElementData( targetPlayer, "dbid" )) )
				if marriedto then
					local to = tonumber( marriedto["marriedto"] )
					if to > 0 then
						mysql:query_free("UPDATE characters SET marriedto = 0 WHERE id = " .. mysql:escape_string(getElementData( targetPlayer, "dbid" )) )
						mysql:query_free("UPDATE characters SET marriedto = 0 WHERE marriedto = " .. mysql:escape_string(getElementData( targetPlayer, "dbid" )) )
						
						exports['cache']:clearCharacterName( getElementData( targetPlayer, "dbid" ) )
						exports['cache']:clearCharacterName( to )
						
						outputChatBox( targetPlayerName .. " is now divorced.", thePlayer, 0, 255, 0 )
					else
						outputChatBox( targetPlayerName .. " is not married to anyone.", thePlayer, 255, 194, 14 )
					end
				end
			end
		end
	end
end
addCommandHandler("divorce", divorce)