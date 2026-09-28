--MAXIME + Vortex rank bridge (21-rank ladder replaces the old numeric one)
--
-- Gate order in every check below:
--   1. Vortex rank (elementData "rank:index", pushed by
--      admin-system/staff_manager/staff_manager_bridge_s.lua at login and
--      kept fresh after every /staffs mutation).  rank:index 1..21 mirrors
--      the staff_roles ladder, so these thresholds are the replacement for
--      the old admin_level 1-4 numbers.
--   2. Legacy elementData fallback (accounts.admin/supporter/scripter
--      columns) for accounts that have no Vortex rank assigned yet.

local function isPlayerElement(player)
	return player and isElement(player) and getElementType(player) == "player"
end

-- nil = no Vortex rank on this player -> caller falls back to legacy data
local function getRankIndex(player)
	if not isPlayerElement(player) then return nil end
	return tonumber(getElementData(player, "rank:index"))
end

function isPlayerLeadAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 11 -- Lead Administrator+
	end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 4)
end

function isPlayerSeniorAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 9 -- Senior Administrator+
	end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 3)
end

function isPlayerAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 5 -- Moderator+
	end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 2)
end

function isPlayerTrialAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 4 -- Trial Moderator+
	end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 1)
end

function isPlayerSupporter(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 2 -- Trial Support+
	end
	local supporter_level = getElementData(player, "supporter_level") or 0
	return (supporter_level >= 1)
end

function isPlayerSupportManager(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 3 -- Support+
	end
	local supporter_level = getElementData(player, "supporter_level") or 0
	return (supporter_level >= 2)
end

function isPlayerTester(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx == 1 or idx >= 19 -- Tester rank, or Founder/Developer/Owner
	end
	local scripter_level = getElementData(player, "scripter_level") or 0
	return (scripter_level >= 1)
end

function isPlayerScripter(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 20 -- Diverloper+
	end
	local scripter_level = getElementData(player, "scripter_level") or 0
	return (scripter_level >= 2)
end

function isPlayerLeadScripter(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 19 -- Founder+
	end
	local scripter_level = getElementData(player, "scripter_level") or 0
	return (scripter_level >= 3)
end

--LEADER
function isPlayerVehicleConsultant(player)
	if not isPlayerElement(player) then
		return false
	end
	local vct_level = getElementData(player, "vct_level") or 0
	return (vct_level >= 2)
end

--MEMBERS
function isPlayerVCTMember(player)
	if not isPlayerElement(player) then
		return false
	end
	local vct_level = getElementData(player, "vct_level") or 0
	return (vct_level >= 1)
end

--LEADER
function isPlayerMappingTeamLeader(player)
	if not isPlayerElement(player) then
		return false
	end
	local mapper_level = getElementData(player, "mapper_level") or 0
	return (mapper_level >= 2)
end

--MEMBERS
function isPlayerMappingTeamMember(player)
	if not isPlayerElement(player) then
		return false
	end
	local mapper_level = getElementData(player, "mapper_level") or 0
	return (mapper_level >= 1)
end

function isPlayerStaff(player)
	if not isPlayerElement(player) then
		return false
	end
	if getRankIndex(player) then
		return true -- any of the 21 Vortex ranks
	end
	return 	isPlayerTrialAdmin(player)
	or		isPlayerSupporter(player)
	or 		isPlayerScripter(player)
	or 		isPlayerVCTMember(player)
	or 		isPlayerMappingTeamMember(player)
end

function getAdminGroups() -- this is used in c_adminstats to correspond levels to forum usergroups
	return { SUPPORTER, TRIALADMIN, ADMIN, SENIORADMIN, LEADADMIN }
end

-- internal affairs
function isPlayerIA( player )
	if not isPlayerElement(player) then
		return false
	end
	return tonumber( getElementData( player, "account:id" ) ) == 211
end

-- Vortex ladder: exact rank title for chat/name tags.  Falls back to the
-- old numeric titles for accounts without a Vortex rank.
function getPlayerRankTitle(player)
	if not isPlayerElement(player) then
		return nil
	end
	local name = getElementData(player, "rank:name")
	if name and name ~= "" then
		return tostring(name)
	end
	return nil
end

adminTitles = {
	[1] = "Trial Admin",
	[2] = "Admin",
	[3] = "Senior Admin",
	[4] = "Lead Admin",
	[10] = "Scripter",
}

function getAdminTitles()
	return adminTitles
end

function getSupporterNumber()
	return SUPPORTER
end

function getAuxiliaryStaffNumbers()
	return table.concat(AUXILIARY_GROUPS, ",")
end

function getAdminStaffNumbers()
	return table.concat(ADMIN_GROUPS, ",")
end


-- [Fix #52] isPlayerFMT was referenced by g_admin_globals / g_chat_globals /
-- chat-system title chains but never existed anywhere, so the call raised and
-- aborted the whole title lookup. No FMT element-data exists on this server,
-- so answer false gracefully (title chain falls through).
function isPlayerFMT(player)
	if not isPlayerElement(player) then
		return false
	end
	local fmt_level = getElementData(player, "fmt_level") or 0
	return (fmt_level >= 1)
end