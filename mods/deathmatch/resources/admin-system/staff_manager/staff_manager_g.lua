--MAXIME / 2015.1.8function canPlayerAccessStaffManager(player)	-- [user rule #4] the PANEL right is the WHOLE gate, and it means exactly one	-- thing: may open /staffs. It used to be "has ANY of the 21 ranks", so a rank	-- with admin.manager.panel unticked still walked straight in - which made the	-- right meaningless, and let a viewer who cannot open the panel go on	-- RECEIVING the teams payload this helper also gates. The rank's OWN stored	-- rights decide now, backend-first, exactly like every other helper here.	--		-- The no-rank branch answers with the player's TEAMS first (see below),
	-- then keeps the OLD legacy ladder: before the bridge has resolved a
	-- rank, playerHasRight() has nothing to read, so an unranked legacy admin
	-- must not be locked out of his own panel - and a rank-less member of a
	-- staff TEAM must not be either.
		if getElementData(player, "rank:index") then
		if type(playerHasRight) == "function" then
			return playerHasRight(player, "admin.manager.panel") and true or false
		end
		return false
	end
	-- [Batch 173] the TEAM answers before the legacy ladder. /staffs is
	-- already ALLOWED for a rank-less member of the Full Access team by the
	-- gate in command_gates_s.lua ("staffs" = admin.manager.panel), but this
	-- helper - the server side of the client's rpadmin:requestPanel - only
	-- knew the legacy integration ladder (accounts columns), which reads 0/0/0
	-- for him, so the panel answered "You don't have permission" anyway. The
	-- team's stored payload is checked first here; it fails CLOSED for a
	-- player with no team, so every legacy admin keeps his old answer.
	if type(playerTeamsGrantRight) == "function" then
		local ok, res = pcall(playerTeamsGrantRight, player, "admin.manager.panel")
		if ok and res == true then return true end
	end
	return exports.integration:isPlayerTrialAdmin(player)		or exports.integration:isPlayerSupporter(player)		or exports.integration:isPlayerVCTMember(player)		or exports.integration:isPlayerLeadScripter(player)		or exports.integration:isPlayerMappingTeamLeader(player)end	