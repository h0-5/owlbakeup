--[[ //Chaos
~=~=~=~=~=~= ORGANIZED REPORTS FOR OWL INFO =~=~=~=~=~=~
Name: The name to show once the report is submitted and in the F2 menu
Staff to send to: The Usergroup ID on the forums that you are sending the report to
Abbreviation: Used in the report identifier for the staff
r, g, b: The color for the report

I used the strings as the values instead of the keys, this way its easier for us to organize. 
{NAME, { Staff to send to }, Abbreviation, r, g, b} ]]

reportTypes = {
 	{"Issue with another player", {18, 17, 64, 15, 14}, "PLY", 214, 6, 6, "Use this type if you are reporting a player about a issue that has occured." },
	{"Interior Issue", {18, 17, 64, 15, 14}, "INT", 255, 126, 0, "Use this type if you are having a issue with a interior." },
	{"Item Issue", {18, 17, 64, 15, 14}, "ITM", 255, 126, 0, "Use this type if you need items spawned or anything related to your item invetory." },
	{"General Question", {30, 18, 17, 64, 15, 14}, "SUP", 70, 200, 30, "Use this type if you have any questions." },
	{"Vehicle Related Issues", {30, 18, 17, 64, 15, 14}, "VEH", 255, 126, 0, "Use this type if you have a issue with a vehicle." },
	{"Vehicle Build/Import Requests", {39, 43}, "VCT", 176, 7, 237, "Use this type to contact the VCT." },
	--{"Mapping Issue", {44, 28}, "MAP", 0, 0, 0 }, MAXIME IF YOU EVER WANT TO BRING THIS BACK, UNCOMMENT
	{"Scripting Question", {32}, "ScrT", 148, 126, 12, "Use this type if you with to contact the Scripting Team." },
}

adminTeams = exports.integration:getAdminStaffNumbers()
auxiliaryTeams = exports.integration:getAuxiliaryStaffNumbers()
SUPPORTER = exports.integration:getSupporterNumber()

function getReportInfo(row, element)
	if not isElement(element) then
		element = nil
	end

	local staff = reportTypes[row][2]
	local players = getElementsByType("player")
	local vcount = 0
	local scount = 0


	for k,v in ipairs(staff) do
		if v == 39 or v == 43 then

			for key, player in ipairs(players) do
				if exports.integration:isPlayerVCTMember(player) or exports.integration:isPlayerVehicleConsultant(player) then
					vcount = vcount + 1
					save = player
				end
			end

			if vcount==0 then
				return false, "There is currently no VCT Members online. Contact them here: http://forums.owlgaming.net/forms.php?do=form&fid=42"
			elseif vcount==1 and save == element then -- Callback for checking if a aux staff logs out
				return false, "There is currently no VCT Members online. Contact them here: http://forums.owlgaming.net/forms.php?do=form&fid=42"
			end
		elseif v == 32 then

			for key, player in ipairs(players) do
				if exports.integration:isPlayerScripter(player) then
					scount = scount + 1
					save = player
				end
			end

			if scount==0 then
				return false, "There is currently no members of the Scripting team online. Use Support Center at www.owlgaming.net/support.php"
			elseif scount==1 and save == element then -- Callback for checking if a aux staff logs out
				return false, "There is currently no members of the Scripting team online. Use Support Center at www.owlgaming.net/support.php"
			end
		end
	end

	local name = reportTypes[row][1]
	local abrv = reportTypes[row][3]
	local red = reportTypes[row][4]
	local green = reportTypes[row][5]
	local blue = reportTypes[row][6]

	return staff, false, name, abrv, red, green, blue
end

function isSupporterReport(row)
	local staff = reportTypes[row][2]

	for k, v in ipairs(staff) do
		if v == SUPPORTER then
			return true
		end
	end
	return false
end

function isAdminReport(row)
	local staff = reportTypes[row][2]

	for k, v in ipairs(staff) do
		if string.find(adminTeams, v) then
			return true
		end
	end
	return false
end

function isAuxiliaryReport(row)
	local staff = reportTypes[row][2]

	for k, v in ipairs(staff) do
		if string.find(auxiliaryTeams, v) then
			return true
		end
	end
	return false
end

function showExternalReportBox(thePlayer)
	if not thePlayer then return false end
	return (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) and (getElementData(thePlayer, "report_panel_mod") == "2" or getElementData(thePlayer, "report_panel_mod") == "3")
end

function showTopRightReportBox(thePlayer)
	if not thePlayer then return false end
	return (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) and (getElementData(thePlayer, "report_panel_mod") == "1" or getElementData(thePlayer, "report_panel_mod") == "3")
end

-- [Fix #167 - user] may THIS player use the LIVE REPORTS LIST behind the F4
-- "Report Center" item? The entitlement is the access.reports right
-- (staff_manager_rights.lua:134 - the very right /reports + acceptreport are
-- already gated on in admin-system/command_gates_s.lua:770-779 - this closes
-- every OTHER way into that panel; the command gates stay untouched).
-- Lives here because meta.xml:17 loads this file as type="shared": ONE
-- definition for the server handlers and for c_report_panel.lua, same shape
-- as integration/g_staff.lua rankHoldsRight (lines 38-53):
--   * server - the real union (rank + TEAM) through the admin-system
--     playerHasRight export, pcall'd so admin-system being stopped answers
--     "no right",
--   * client - that export is server-only, so pcall fails and we fall back
--     to the rank:rights element data, then to the hud:reportsright mirror
--     that hud/s_hud.lua pushes from that very export.
-- Every path fails CLOSED: no answer, no panel.
function hasReportsPanelAccess(player)
	if not player or not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	local ok, res = pcall(function()
		return exports["admin-system"]:playerHasRight(player, "access.reports")
	end)
	if ok and res ~= nil then
		return res and true or false
	end
	local raw = getElementData(player, "rank:rights")
	if type(raw) == "string" and raw ~= "" then
		local okJSON, parsed = pcall(fromJSON, raw)
		if okJSON and type(parsed) == "table" then
			if type(parsed[1]) == "table" and next(parsed, 1) == nil then
				parsed = parsed[1]
			end
			if type(parsed) == "table" and parsed["access.reports"] then
				return true
			end
		end
	end
	return tonumber(getElementData(player, "hud:reportsright")) == 1
end
