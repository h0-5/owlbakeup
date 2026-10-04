--MAXIME + Vortex rank bridge (21-rank ladder replaces the old numeric one)
--
-- Gate order in every check below:
--   1. Vortex rank (elementData "rank:index", pushed by
--      admin-system/staff_manager/staff_manager_bridge_s.lua at login and
--      kept fresh after every /staffs mutation).  rank:index 1..21 mirrors
--      the staff_roles ladder, so these thresholds are the replacement for
--      the old admin_level 1-4 numbers.
--   2. [Fix #163] the IDENTITY rights on top of the index, for rank holders
--      only: admin.isAdmin decides every admin tier, admin.isStaff decides
--      the supporter tiers.  A rank without the right fails the gate (its
--      holders lose those permissions - that is what an untick in the panel
--      means); a rank with the right behaves exactly as in step 1 alone.
--   3. Legacy elementData fallback (accounts.admin/supporter/scripter
--      columns) for accounts that have no Vortex rank assigned yet - this
--      path is untouched by Fix #163.
--   4. [Batch 173] only when there is no rank AND no legacy column at all:
--      the player's TEAMS (staff_teams rights) supply admin.isAdmin /
--      admin.isStaff, so a rank-less member of the Full Access team is not
--      read as "not staff" by the legacy gates (/makeped, the F1 /staff
--      overlay, ...). Never fires for an account that still has a column.

local function isPlayerElement(player)
	return player and isElement(player) and getElementType(player) == "player"
end

-- nil = no Vortex rank on this player -> caller falls back to legacy data
local function getRankIndex(player)
	if not isPlayerElement(player) then return nil end
	return tonumber(getElementData(player, "rank:index"))
end

-- [Fix #163] admin.isAdmin / admin.isStaff are the RIGHTS that decide whether
-- a Vortex RANK reads as an admin / as support. The ladder index still sets
-- the TIER (Moderator+, Lead Administrator+, ...), the right sets the
-- IDENTITY: a rank that does not hold the right can never pass an admin /
-- support gate below - its holders lose exactly the legacy-tier permissions
-- the panel untick removed, while a rank that holds the right behaves
-- byte-identically to before (index check unchanged).
-- Shared script: the server answers through the rights API (rank + TEAM
-- union), the client - where playerHasRight is not exported - through the
-- synced rank:rights element data.
local function rankHoldsRight(player, right)
	local ok, res = pcall(function()
		return exports["admin-system"]:playerHasRight(player, right)
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

-- [Batch 173] TEAM-only identity for the LEGACY ladder (step 3 above).
-- Everything above still answers for a player WITH a Vortex rank or WITH a
-- legacy accounts column, so this helper deliberately fires for neither: it
-- only lifts the ONE player shape the owner reported - no rank, and all three
-- legacy columns 0 (staff:hasTeam = 1, accounts.admin/supporter/scripter = 0).
-- For him the rights API has no rank record and no column to derive one from,
-- so the answer can only come from his TEAMS - ask it: a team granting
-- admin.isAdmin makes him an admin, one granting admin.isStaff makes him
-- support. Anyone with a rank or a legacy column is left to the byte-identical
-- number test below, so no existing account changes rank tier.
-- This is why /makeped (ped-system, read-only here) printed NOTHING for him:
-- its handler gates on isPlayerTrialAdmin with no else branch, and a player
-- with no rank and admin_level 0 read as "not staff".
local function teamOnlyHolds(player, right)
	if not isPlayerElement(player) then return false end
	if getRankIndex(player) then return false end
	if (tonumber(getElementData(player, "admin_level")) or 0) > 0 then return false end
	if (tonumber(getElementData(player, "supporter_level")) or 0) > 0 then return false end
	if (tonumber(getElementData(player, "scripter_level")) or 0) > 0 then return false end
	return rankHoldsRight(player, right)
end

function isPlayerLeadAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 11 and rankHoldsRight(player, "admin.isAdmin") -- Lead Administrator+
	end
	if teamOnlyHolds(player, "admin.isAdmin") then return true end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 4)
end

function isPlayerSeniorAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 9 and rankHoldsRight(player, "admin.isAdmin") -- Senior Administrator+
	end
	if teamOnlyHolds(player, "admin.isAdmin") then return true end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 3)
end

function isPlayerAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 5 and rankHoldsRight(player, "admin.isAdmin") -- Moderator+
	end
	if teamOnlyHolds(player, "admin.isAdmin") then return true end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 2)
end

function isPlayerTrialAdmin(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 4 and rankHoldsRight(player, "admin.isAdmin") -- Trial Moderator+
	end
	if teamOnlyHolds(player, "admin.isAdmin") then return true end
	local adminLevel = getElementData(player, "admin_level") or 0
	return (adminLevel >= 1)
end

function isPlayerSupporter(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 2 and rankHoldsRight(player, "admin.isStaff") -- Trial Support+
	end
	if teamOnlyHolds(player, "admin.isStaff") then return true end
	local supporter_level = getElementData(player, "supporter_level") or 0
	return (supporter_level >= 1)
end

function isPlayerSupportManager(player)
	if not isPlayerElement(player) then
		return false
	end
	local idx = getRankIndex(player)
	if idx then
		return idx >= 3 and rankHoldsRight(player, "admin.isStaff") -- Support+
	end
	if teamOnlyHolds(player, "admin.isStaff") then return true end
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