-- FIND IP --
local function showIPAlts(thePlayer, ip)
	result = mysql:query("SELECT `username`, `lastlogin` ,`appstate` FROM `accounts` WHERE `ip` = '" .. mysql:escape_string(ip) .. "' ORDER BY `id` ASC" )
	if result then
		local count = 0
		
		outputChatBox( " IP Address: " .. ip, thePlayer)
		while true do
			local row = mysql:fetch_assoc(result)
			if not row then break end
			
			if row["lastlogin"] == nil then
				row["lastlogin"] = "Never"
			end
			
			local text = " #" .. count .. ": " .. tostring(row["username"])
			
			if tonumber( row["appstate"] ) < 3 then
				text = text .. " (Awaiting App)"
			end
			
			outputChatBox( text, thePlayer)
			
			count = count + 1
		end
		mysql:free_result( result )
	else
		outputChatBox( "Error #9101 - Report on Forums", thePlayer, 255, 0, 0)
	end
end

function findAltAccIP(thePlayer, commandName, ...)
	if exports.integration:isPlayerTrialAdmin( thePlayer ) then
		if not (...) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick]", thePlayer, 255, 194, 14)
		else
			local targetPlayerName = table.concat({...}, "_")
			local targetPlayer = exports.global:findPlayerByPartialNick(nil, targetPlayerName)
			
			if not targetPlayer or getElementData( targetPlayer, "loggedin" ) ~= 1 then
				-- select by charactername
				local result = mysql:query("SELECT a.`ip` FROM `characters` c LEFT JOIN `accounts` a on c.`account`=a.`id` WHERE c.`charactername` = '" .. mysql:escape_string(targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) == 1 then
						local row = mysql:fetch_assoc(result)
						local ip = row["ip"] or '0.0.0.0'
						mysql:free_result( result )
						showIPAlts( thePlayer, ip )
						return
					end
					mysql:free_result( result )
				end
				
				targetPlayerName = table.concat({...}, " ")
				
				-- select by accountname
				local result = mysql:query("SELECT ip FROM accounts WHERE username = '" .. mysql:escape_string(targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) == 1 then
						local row = mysql:fetch_assoc(result)
						local ip = row["ip"] or '0.0.0.0'
						mysql:free_result( result )
						showIPAlts( thePlayer, ip )
						return
					end
					mysql:free_result( result )
				end

				-- select by ip
				local result = mysql:query("SELECT ip FROM accounts WHERE ip = '" .. mysql:escape_string( targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) >= 1 then
						local row = mysql:fetch_assoc(result2)
						local ip = tonumber( row["ip"] ) or '0.0.0.0'
						mysql:free_result( result )
						showIPAlts( thePlayer, ip )
						return
					end
					mysql:free_result( result )
				end

				outputChatBox("Player not found or multiple were found.", thePlayer, 255, 0, 0)
			else -- select by online player
				showIPAlts( thePlayer, getPlayerIP(targetPlayer) )
			end
		end
	end
end
addCommandHandler( "findip", findAltAccIP )
-- END FIND IP --

-- START FINDALTS --
-- /showalts + /findalts (+ /findalts2 with the creation dates): the argument
-- is a CHARACTER (name or id), the output is the whole character list of the
-- account that character belongs to. The rows go to the dark list panel
-- (admin-system/c_showalts.lua, event "showalts:show") instead of the old
-- one-chat-line-per-character wall.

-- Right: admin.showalts. staff_manager/command_gates_s.lua maps /findalts and
-- /findalts2 to it, but /showalts is NOT in that map (an unmapped command is
-- always let through by the gate), so this file checks the right itself:
-- the executor's own rank:rights element data decides.
local function showaltsHasRight( thePlayer )
	if not isElement( thePlayer ) then
		return false
	end

	-- the live set staff_manager pushes (JSON string or already a table)
	local live
	local raw = getElementData( thePlayer, "rank:rights" )
	if type( raw ) == "table" then
		live = raw
	elseif type( raw ) == "string" and raw ~= "" then
		local ok, parsed = pcall( fromJSON, raw )
		if ok and type( parsed ) == "table" then
			-- MTA stores a single JSON object as { [ 1 ] = { ... } }
			if type( parsed[1] ) == "table" and next( parsed, 1 ) == nil then
				parsed = parsed[1]
			end
			live = parsed
		end
	end

	if live then
		-- the stored set is the whole truth: an unticked right must deny
		if live["admin.showalts"] == true then
			return true
		end
		-- the rank missed it - a staff team may still grant it (the same
		-- union playerHasRight already applies for every other command)
		if type( playerHasRight ) == "function" then
			return playerHasRight( thePlayer, "admin.showalts" ) and true or false
		end
		return false
	end

	-- no live rights set (no Vortex rank pushed yet): the legacy ladder
	-- decides, exactly like the gate does for the mapped /findalts
	return exports.integration:isPlayerTrialAdmin( thePlayer )
		or exports.integration:isPlayerSupporter( thePlayer )
end

-- Resolve the SEARCHED CHARACTER to the id of the account that owns it.
-- A number is always a raw character id (findPlayerByPartialNick would read
-- it as a session/mod id and hit the WRONG account), anything else is tried
-- as an exact character name, then as an online (partial) nick, then - as a
-- legacy convenience - as an exact account username.
local function showaltsResolve( query )
	query = tostring( query or "" ):gsub( "^%s+", "" ):gsub( "%s+$", "" )
	if query == "" then
		return nil
	end

	if query:match( "^%d+$" ) then
		local row = mysql:query_fetch_assoc( "SELECT `account` FROM `characters` WHERE `id` = '"
			.. mysql:escape_string( query ) .. "' LIMIT 1" )
		if row and tonumber( row["account"] ) then
			return tonumber( row["account"] )
		end
		return nil -- a number that is not a character id resolves to nothing
	end

	-- character names are stored with underscores
	local row = mysql:query_fetch_assoc( "SELECT `account` FROM `characters` WHERE LOWER(`charactername`) = LOWER('"
		.. mysql:escape_string( query:gsub( " ", "_" ) ) .. "') LIMIT 1" )
	if row and tonumber( row["account"] ) then
		return tonumber( row["account"] )
	end

	-- online character by (partial) nick; the third argument keeps the helper
	-- quiet, this command prints its own not found message
	-- spaces are never part of a stored nickname, but a "John Doe" argument
	-- must still hit the online "John_Doe"
	local nickQuery = query:gsub( " ", "_" )
	local ok, target = pcall( function()
		return exports.global:findPlayerByPartialNick( nil, nickQuery, true )
	end )
	if ok and isElement( target ) and getElementType( target ) == "player" then
		local account = tonumber( getElementData( target, "account:id" ) )
		if account then
			return account
		end
	end

	-- legacy: the command also took an account name
	row = mysql:query_fetch_assoc( "SELECT `id` FROM `accounts` WHERE LOWER(`username`) = LOWER('"
		.. mysql:escape_string( query ) .. "') LIMIT 1" )
	if row and tonumber( row["id"] ) then
		return tonumber( row["id"] )
	end

	return nil
end

-- Collect every character of the account and hand the rows to the panel
local function showAlts( thePlayer, id, creation )
	local account = mysql:query_fetch_assoc( "SELECT `username`, `appstate` FROM `accounts` WHERE `id` = '"
		.. mysql:escape_string( id ) .. "' LIMIT 1" )
	if not account then
		outputChatBox( "Game Account is unknown.", thePlayer, 255, 0, 0 )
		return
	end

	local result = mysql:query( "SELECT `charactername`, `id`, `cked`, `faction_id`, `lastlogin`, `creationdate`, `hoursplayed`, `active` FROM `characters` WHERE `account` = '"
		.. mysql:escape_string( id ) .. "' ORDER BY `charactername` ASC" )
	if not result then
		outputChatBox( "Error #9102 - Report on Forums", thePlayer, 255, 0, 0 )
		return
	end

	-- the faction column stays admin only, like the old chat output
	local showFaction = exports.integration:isPlayerAdmin( thePlayer )
	local rows = { }
	while true do
		local row = mysql:fetch_assoc( result )
		if not row then
			break
		end

		-- the same three states the old list showed
		local status = "Alive"
		if tonumber( row["cked"] ) == 1 then
			status = "Missing"
		elseif tonumber( row["cked"] ) == 2 then
			status = "Buried"
		end
		if tonumber( row["active"] ) == 0 then
			status = status .. ", inactive"
		end

		local faction = ""
		if showFaction and ( tonumber( row["faction_id"] ) or 0 ) > 0 then
			local theTeam = exports.pool:getElement( "team", tonumber( row["faction_id"] ) )
			if theTeam then
				faction = getTeamName( theTeam )
			end
		end

		local charName = tostring( row["charactername"] or "?" )
		charName = charName:gsub( "_", " " )

		rows[ #rows + 1 ] = {
			id = tonumber( row["id"] ),
			name = charName,
			online = getPlayerFromName( tostring( row["charactername"] or "" ) ) and true or false,
			hours = tonumber( row["hoursplayed"] ) or 0,
			status = status,
			faction = faction,
			lastlogin = tostring( row["lastlogin"] or "-" ),
			created = tostring( row["creationdate"] or "-" ),
		}
	end
	mysql:free_result( result )

	triggerClientEvent( thePlayer, "showalts:show", thePlayer, {
		account = tostring( account["username"] or "?" ),
		accountID = tonumber( id ),
		appstate = tonumber( account["appstate"] ),
		creation = creation and true or false,
		showFaction = showFaction,
		rows = rows,
	} )
	outputChatBox( "Showing " .. #rows .. " character(s) of account "
		.. tostring( account["username"] ) .. ".", thePlayer, 0, 255, 0 )
end

-- shared by /showalts, /findalts and /findalts2
function findAltChars( thePlayer, commandName, ... )
	if not showaltsHasRight( thePlayer ) then
		outputChatBox( "You don't have permission to use this command.", thePlayer, 255, 0, 0 )
		return
	end

	if not ( ... ) then
		outputChatBox( "SYNTAX: /" .. tostring( commandName ) .. " [character name or id]", thePlayer, 255, 194, 14 )
		return
	end

	local query = table.concat( { ... }, " " )
	local id
	if query == "*" then
		-- legacy: "*" = your own account
		id = tonumber( getElementData( thePlayer, "account:id" ) )
	else
		id = showaltsResolve( query )
	end

	if not id then
		outputChatBox( "Character not found: " .. query, thePlayer, 255, 0, 0 )
		return
	end

	showAlts( thePlayer, id, commandName == "findalts2" )
end

addCommandHandler( "showalts", findAltChars )
addCommandHandler( "findalts", findAltChars )
addCommandHandler( "findalts2", findAltChars )
-- END FINDALTS --

-- START FINDSERIAL --
local function showSerialAlts(thePlayer, serial)
	result = mysql:query("SELECT `username`, `lastlogin`, `appstate` FROM `accounts` WHERE mtaserial = '" .. mysql:escape_string(serial) .. "'" )
	if result then
		local count = 0
		local continue = true
		while continue do
			local row = mysql:fetch_assoc(result)
			if not row then break end
			count = count + 1
			if (count == 1) then
				outputChatBox( " Serial: " .. serial, thePlayer)
			end
			
			local text = "#" .. count .. ": " .. row["username"]
			
			if tonumber( row["appstate"] ) < 3 then
				text = text .. " (Application not passed)"
			end

			outputChatBox( text, thePlayer)
		end
		mysql:free_result( result )
	else
		outputChatBox( "Error #9101 - Report on Forums", thePlayer, 255, 0, 0)
	end
end

function findAltAccSerial(thePlayer, commandName, ...)
	if exports.integration:isPlayerTrialAdmin( thePlayer ) then
		if not (...) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Player Nick/Serial]", thePlayer, 255, 194, 14)
		else
			local targetPlayerName = table.concat({...}, "_")
			local targetPlayer = exports.global:findPlayerByPartialNick(nil, targetPlayerName)
			
			if not targetPlayer then --or getElementData( targetPlayer, "loggedin" ) ~= 1 then
				
				
				-- select by charactername
				local result = mysql:query("SELECT a.`mtaserial` FROM `characters` c LEFT JOIN `accounts` a on c.`account`=a.`id` WHERE c.`charactername` = '" .. mysql:escape_string(targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) == 1 then
						local row = mysql:fetch_assoc(result)
						local serial = row["mtaserial"] or 'UnknownSerial'
						mysql:free_result( result )
						showSerialAlts( thePlayer, serial )
						return
					end
					mysql:free_result( result )
				end
				
				targetPlayerName = table.concat({...}, " ")
				
				-- select by accountname
				local result = mysql:query("SELECT `mtaserial` FROM `accounts` WHERE `username` = '" .. mysql:escape_string(targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) == 1 then
						local row = mysql:fetch_assoc(result)
						local serial = row["mtaserial"] or 'UnknownSerial'
						mysql:free_result( result )
						showSerialAlts( thePlayer, serial)
						return
					end
					mysql:free_result( result )
				end
				
				-- select by ip
				local result = mysql:query("SELECT `mtaserial` FROM `accounts` WHERE `ip` = '" .. mysql:escape_string( targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) >= 1 then
						local row = mysql:fetch_assoc(result)
						local serial = row["mtaserial"] or 'UnknownSerial'
						mysql:free_result( result )
						showSerialAlts( thePlayer, serial )
						return
					end
					mysql:free_result( result )
				end
				
				-- select by serial
				local result = mysql:query("SELECT `mtaserial` FROM `accounts` WHERE `mtaserial` = '" .. mysql:escape_string( targetPlayerName ) .. "'" )
				if result then
					if mysql:num_rows( result ) >= 1 then
						local row = mysql:fetch_assoc(result)
						local serial = row["mtaserial"] or 'UnknownSerial'
						mysql:free_result( result )
						showSerialAlts( thePlayer, serial )
						return
					end
					mysql:free_result( result )
				end
				
				outputChatBox("Player not found or multiple were found.", thePlayer, 255, 0, 0)
			else -- select by online player
				showSerialAlts( thePlayer, getPlayerSerial(targetPlayer) )
			end
		end
	end
end
addCommandHandler( "findserial", findAltAccSerial )
-- END FINDSERIAL --