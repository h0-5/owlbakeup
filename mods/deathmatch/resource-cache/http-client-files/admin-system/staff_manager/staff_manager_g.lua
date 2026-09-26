--MAXIME / 2015.1.8

function canPlayerAccessStaffManager(player)
	-- Vortex ladder: any of the 21 ranks (Tester included) opens the panel
	if getElementData(player, "rank:index") then
		return true
	end
	return exports.integration:isPlayerTrialAdmin(player) or exports.integration:isPlayerSupporter(player) or exports.integration:isPlayerVCTMember(player) or exports.integration:isPlayerLeadScripter(player) or exports.integration:isPlayerMappingTeamLeader(player)
end
	