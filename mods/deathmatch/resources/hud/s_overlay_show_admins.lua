-- Misc
local function sortTable( a, b )
	if b[2] < a[2] then
		return true
	end

	if b[2] == a[2] and b[4] > a[4] then
		return true
	end

	return false
end

local function getPlayerScripterRank( player )
	if exports.integration:isPlayerLeadScripter( player ) then
		return "Lead Developer"
	elseif exports.integration:isPlayerScripter( player ) then
		return "Senior Scripter"
	elseif exports.integration:isPlayerTester( player ) then
		return "Scripter"
	else
		return ""
	end
end

local function getPlayerSupportRank( player )
	-- [Fix #163] a Vortex rank holder is titled by HIS RANK title
	-- the old Supporter / Support Manager ladder is only the fallback for
	-- players without a rank (and for a rank whose name never reached the
	-- client).
	local rname = getElementData(player, "rank:name")
	if type(rname) == "string" and rname ~= "" then
		return tostring(rname)
	end
	if exports.integration:isPlayerSupportManager( player ) then
		return "Support Manager"
	elseif exports.integration:isPlayerSupporter( player ) then
		return "Supporter"
	else
		return ""
	end
end

-- [Fix #163] RIGHTS gate for the two staff lists below.
-- admin.isAdmin / admin.isStaff are what makes a Vortex RANK show up as an
-- admin / as support; a rank without the right never reaches either list.
-- Server side the live rights API answers (rank + TEAM union), client side
-- the synced rank:rights element data decides (playerHasRight is exported
-- for the server only). nil/false-safe: an unreachable API simply denies.
local function rankRight( player, right )
	local ok, res = pcall(function()
		return exports["admin-system"]:playerHasRight( player, right )
	end)
	if ok and res ~= nil then
		return res and true or false
	end
	local raw = getElementData(player, "rank:rights")
	if type(raw) ~= "string" or raw == "" then return false end
	local okJSON, parsed = pcall(fromJSON, raw)
	if not okJSON or type(parsed) ~= "table" then return false end
	if type(parsed[1]) == "table" and next(parsed, 1) == nil then
		parsed = parsed[1]
	end
	return type(parsed) == "table" and parsed[right] == true or false
end

function showStaff( thePlayer, commandName )
	local logged = getElementData(thePlayer, "loggedin")
	local info = {}
	local isOverlayDisabled = getElementData(thePlayer, "hud:isOverlayDisabled")

	-- ADMINS --
	if(logged==1) then
		-- [Fix #163] every online player is considered: exports.global:getAdmins()
		-- pre-filtered rank holders through isPlayerTrialAdmin (ladder index), so
		-- a rank holding admin.isAdmin below the Trial Moderator index never
		-- reached this list.
		local players = exports.pool:getPoolElementsByType("player")
		local counter = 0

		admins = {}

		if isOverlayDisabled then
			outputChatBox("ADMINISTRATORS:", thePlayer, 255, 194, 14)
		else
			table.insert(info, {"Administration Team:", 255, 194, 14, 255, 1, "title"})
			table.insert(info, {""})
		end

		for k, arrayPlayer in ipairs(players) do
			local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
			local logged = getElementData(arrayPlayer, "loggedin")

			if logged == 1 then
				-- [Fix #163] RIGHTS decide the Administration Team membership of a
				-- RANK holder: admin.isAdmin, at any ladder index. The old
				-- admin_level < 10 + isPlayerTrialAdmin pair stays for players without
				-- a Vortex rank (legacy ladder, byte-identical behaviour).
				local ridx = tonumber(getElementData(arrayPlayer, "rank:index"))
				local listed
				if ridx then
					listed = rankRight(arrayPlayer, "admin.isAdmin")
				else
					local lvl = tonumber(getElementData( arrayPlayer, "admin_level" )) or 0
					listed = lvl < 10 and exports.integration:isPlayerTrialAdmin(arrayPlayer)
				end
				if listed and ( hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) and not exports.integration:isPlayerIA( arrayPlayer ) then
					admins[ #admins + 1 ] = { arrayPlayer, tonumber(getElementData( arrayPlayer, "admin_level" )) or 0, getElementData( arrayPlayer, "duty_admin" ), exports.global:getPlayerName( arrayPlayer ) }
				end
			end
		end

		table.sort( admins, sortTable )

		for k, v in ipairs(admins) do
			arrayPlayer = v[1]
			local adminTitle = exports.global:getPlayerAdminTitle(arrayPlayer)
			local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
			if hiddenAdmin == 0 or exports.integration:isPlayerTrialAdmin(thePlayer) then
				v[4] = v[4] .. " (" .. tostring(getElementData(arrayPlayer, "account:username")) .. ")"

				if(v[3]==1)then
					if isOverlayDisabled then
						outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty", thePlayer, 0, 200, 10)
					else
						table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty", 0, 255, 0, 255, 1, "default"})
					end
				else
					if isOverlayDisabled then
						outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty", thePlayer, 100, 100, 100)
					else
						table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty", 200, 200, 200, 255, 1, "default"})
					end
				end
			end
		end

		if #admins == 0 then
			if isOverlayDisabled then
				outputChatBox("-    Currently no administrators online.", thePlayer)
			else
				table.insert(info, {"-    Currently no administrators online.", 255, 255, 255, 255, 1, "default"})
			end
		end
		--outputChatBox("Use /gms to see a list of gamemasters.", thePlayer)
	end

	if not isOverlayDisabled then
		table.insert(info, {" ", 100, 100, 100, 255, 1, "default"})
	end

	--GMS--
	if(logged==1) then
		-- [Fix #163] every online player is considered: exports.global:
		-- getGameMasters() pre-filtered rank holders through isPlayerSupporter,
		-- which is ladder-index driven (a rank below index 2 that DOES hold
		-- admin.isStaff never showed up here).
		local players = exports.pool:getPoolElementsByType("player")
		local counter = 0

		admins = {}
		if isOverlayDisabled then
			outputChatBox("SUPPORTERS:", thePlayer, 255, 194, 14)
		else
			table.insert(info, {"Support Team:", 255, 194, 14, 255, 1, "title"})
			table.insert(info, {""})
		end
		for k, arrayPlayer in ipairs(players) do
			local logged = getElementData(arrayPlayer, "loggedin")
			if logged == 1 then
				-- [Fix #163] RIGHTS decide the Support Team membership of a RANK
				-- holder: admin.isStaff puts him here, admin.isAdmin keeps him OUT (an
				-- admin is never double-listed as support). Players without a rank keep
				-- the legacy isPlayerSupporter ladder untouched.
				local ridx = tonumber(getElementData(arrayPlayer, "rank:index"))
				local listed
				if ridx then
					listed = rankRight(arrayPlayer, "admin.isStaff")
						and not rankRight(arrayPlayer, "admin.isAdmin")
				else
					listed = exports.integration:isPlayerSupporter(arrayPlayer)
				end
				if listed then
					admins[ #admins + 1 ] = { arrayPlayer, getElementData( arrayPlayer, "account:gmlevel" ), getElementData( arrayPlayer, "duty_supporter" ), exports.global:getPlayerName( arrayPlayer ) }
				end
			end
		end

		for k, v in ipairs(admins) do
			arrayPlayer = v[1]
			local adminTitle = getPlayerSupportRank(arrayPlayer)

			--if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
				v[4] = v[4] .. " (" .. tostring(getElementData(arrayPlayer, "account:username")) .. ")"
			--end

			if(v[3] == 1)then
				if isOverlayDisabled then
					outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty", thePlayer, 0, 200, 10)
				else
					table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty", 0, 255, 0, 255, 1, "default"})
				end
			else
				if isOverlayDisabled then
					outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty", thePlayer, 100, 100, 100)
				else
					table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty", 200, 200, 200, 255, 1, "default"})
				end
			end
		end

		if #admins == 0 then
			if isOverlayDisabled then
				outputChatBox("-    Currently no supporter online.", thePlayer)
			else
				table.insert(info, {"-    Currently no supporter online.", 255, 255, 255, 255, 1, "default"})
			end
		end

	end

	if not isOverlayDisabled then
		table.insert(info, {" ", 100, 100, 100, 255, 1, "default"})
	end

	--VCTs--
	if(logged==1) then
		local players = exports.pool:getPoolElementsByType("player")
		local counter = 0

		--[[if isOverlayDisabled then
			outputChatBox("VEHICLE CONSULTATION TEAM:", thePlayer, 255, 194, 14)
		else
			table.insert(info, {"Vehicle Consultation Team:", 255, 194, 14, 255, 1, "title"})
			table.insert(info, {""})
		end

		for k, arrayPlayer in ipairs(players) do
			local logged = getElementData(arrayPlayer, "loggedin")
			if logged == 1 then
				if exports.integration:isPlayerVCTMember(arrayPlayer) then
					local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
					local stuffToPrint
					if (hiddenAdmin == 1) then
						stuffToPrint = "-    "..(exports.integration:isPlayerVehicleConsultant(arrayPlayer) and "Leader" or "Member").." (Hidden) "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					else
						stuffToPrint = "-    "..(exports.integration:isPlayerVehicleConsultant(arrayPlayer) and "Leader" or "Member").." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					end
					if (hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) then
						local r, g, b = 0, 255, 0 --hud colour
						local cR, cG, cB = 0, 200, 10 --chatbox colour
						if(hiddenAdmin == 1) then
							r, g, b = 200, 200, 200
							cR, cG, cB = 100, 100, 100
						end
						if isOverlayDisabled then
							outputChatBox(stuffToPrint, thePlayer, cR, cG, cB)
						else
							table.insert(info, {stuffToPrint, r, g, b, 255, 1, "default"})
						end
						counter = counter + 1
					end
				end
			end
		end

		if counter == 0 then
			if isOverlayDisabled then
				outputChatBox("-    Currently no members online.", thePlayer)
			else
				table.insert(info, {"-    Currently no members online.", 255, 255, 255, 255, 1, "default"})
			end
		end

		if not isOverlayDisabled then
			table.insert(info, {" ", 100, 100, 100, 255, 1, "default"})
		end--]]


		-- MAPPING TEAM --
		--[[if isOverlayDisabled then
			outputChatBox("MAPPING TEAM:", thePlayer, 255, 194, 14)
		else
			table.insert(info, {"Mapping Team:", 255, 194, 14, 255, 1, "title"})
			table.insert(info, {""})
		end

		for k, arrayPlayer in ipairs(players) do
			local logged = getElementData(arrayPlayer, "loggedin")
			if logged == 1 then
				if exports.integration:isPlayerMappingTeamMember(arrayPlayer) then
					local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
					local stuffToPrint
					if (hiddenAdmin == 1) then
						stuffToPrint = "-    "..(exports.integration:isPlayerMappingTeamLeader(arrayPlayer) and "Leader" or "Member").." (Hidden) "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					else
						stuffToPrint = "-    "..(exports.integration:isPlayerMappingTeamLeader(arrayPlayer) and "Leader" or "Member").." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					end
					if (hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) then
						local r, g, b = 0, 255, 0 --hud colour
						local cR, cG, cB = 0, 200, 10 --chatbox colour
						if(hiddenAdmin == 1) then
							r, g, b = 200, 200, 200
							cR, cG, cB = 100, 100, 100
						end
						if isOverlayDisabled then
							outputChatBox(stuffToPrint, thePlayer, cR, cG, cB)
						else
							table.insert(info, {stuffToPrint, r, g, b, 255, 1, "default"})
						end
						counter = counter + 1
					end
				end
			end
		end

		if counter == 0 then
			if isOverlayDisabled then
				outputChatBox("-    Currently no members online.", thePlayer)
			else
				table.insert(info, {"-    Currently no members online.", 255, 255, 255, 255, 1, "default"})
			end
		end]]

		-- SCRIPTERS --
		if isOverlayDisabled then
			outputChatBox("DEVELOPMENT TEAM:", thePlayer, 255, 194, 14)
		else
			table.insert(info, {"Development Team:", 255, 194, 14, 255, 1, "title"})
			table.insert(info, {""})
		end

		for k, arrayPlayer in ipairs(players) do
			local logged = getElementData(arrayPlayer, "loggedin")
			if logged == 1 then
				if exports.integration:isPlayerTester(arrayPlayer) then
					local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
					local adminTitle = getPlayerScripterRank( arrayPlayer )
					local stuffToPrint
					if (hiddenAdmin == 1) then
						stuffToPrint = "-    (Hidden) "..tostring(adminTitle).." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					else
						stuffToPrint = "-    "..tostring(adminTitle).." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
					end
					if (hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) then
						local r, g, b = 0, 255, 0 --hud colour
						local cR, cG, cB = 0, 200, 10 --chatbox colour
						if(hiddenAdmin == 1) then
							r, g, b = 200, 200, 200
							cR, cG, cB = 100, 100, 100
						end
						if isOverlayDisabled then
							outputChatBox(stuffToPrint, thePlayer, cR, cG, cB)
						else
							table.insert(info, {stuffToPrint, r, g, b, 255, 1, "default"})
						end
						counter = counter + 1
					end
				end
			end
		end

		if counter == 0 then
			if isOverlayDisabled then
				outputChatBox("-    Currently no scripters online.", thePlayer)
			else
				table.insert(info, {"-    Currently no scripters online.", 255, 255, 255, 255, 1, "default"})
			end
		end

	end

	if logged == 1 then
		if not isOverlayDisabled then
			exports.hud:sendTopRightNotification(thePlayer, info, 350)
		end
	end
end
addCommandHandler("admins", showStaff, false, false)
addCommandHandler("gms", showStaff, false, false)
addCommandHandler("staff", showStaff, false, false)

function toggleOverlay(thePlayer, commandName)
	if getElementData(thePlayer, "hud:isOverlayDisabled") then
		setElementData(thePlayer, "hud:isOverlayDisabled", false)
		outputChatBox("You enabled overlay menus.",thePlayer)
	else
		setElementData(thePlayer, "hud:isOverlayDisabled", true)
		outputChatBox("You disabled overlay menus.", thePlayer)
	end
end
addCommandHandler("toggleOverlay", toggleOverlay, false, false)
addCommandHandler("togOverlay", toggleOverlay, false, false)
