wReportMain, bClose, lStatus, lVehTheft, lPropBreak, lPapForgery, lVehTheftStatus, lPropBreakStatus, lPapForgeryStatus, bVehTheft, bPropBreak, bPapForgery, bHelp, lPlayerName, tPlayerName, lNameCheck, lReport, tReport, lLengthCheck, bSubmitReport = nil

function resourceStop()
	guiSetInputEnabled(false)
	showCursor(false)
end
addEventHandler("onClientResourceStop", getResourceRootElement(), resourceStop)

function resourceStart()
	-- [Mod 2] F2 opens the new Vortex menu reports section (main-menu);
	-- the classic window stays reachable through /report
end
addEventHandler("onClientResourceStart", getResourceRootElement(), resourceStart)

function toggleReport()
	executeCommandHandler("report")
	if wHelp then
		guiSetInputEnabled(false)
		showCursor(false)
		destroyElement(wHelp)
		wHelp = nil
	end
end

function checkBinds()
	if ( exports.integration:isPlayerTrialAdmin(getLocalPlayer()) or getElementData( getLocalPlayer(), "account:gmlevel" )  ) then
		if getBoundKeys("ar") or getBoundKeys("acceptreport") then
			--outputChatBox("You had keys bound to accept reports. Please delete these binds.", 255, 0, 0)
			triggerServerEvent("arBind", getLocalPlayer())
		end
	end
end
setTimer(checkBinds, 60000, 0)

local function scale(w)
	local width, height = guiGetSize(w, false)
	local screenx, screeny = guiGetScreenSize()
	local minwidth = math.min(700, screenx)
	if width < minwidth then
		guiSetSize(w, minwidth, height / width * minwidth, false)
		local width, height = guiGetSize(w, false)
		guiSetPosition(w, (screenx - width) / 2, (screeny - height) / 2, false)
	end
end

function toggleVehTheft()
	if exports.integration:isPlayerTrialAdmin(getLocalPlayer()) then
		local status = getElementData(resourceRoot, "vehtheft")
		local pdTeam = exports.factions:getTeamFromFactionID(1) --PD
		local hpTeam = exports.factions:getTeamFromFactionID(59) --HP
		local numPdMembers = (pdTeam and #getPlayersInTeam(pdTeam) or 0) + (hpTeam and #getPlayersInTeam(hpTeam) or 0)
		if numPdMembers < 3 then return outputChatBox("You can not not toggle this when there's less than 3 PD or HP members online.") end -- Automaticly to 'on hold' is less than 3 pd members
		if status == "Opened" then
			guiSetText(lVehTheftStatus, "On hold")
			guiLabelSetColor(lVehTheftStatus, 255, 0, 0)
			setElementData(resourceRoot, "vehtheft", "On hold")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Vehicle Theft", tostring(status))
		elseif status == "On hold" then
			guiSetText(lVehTheftStatus, "Opened")
			guiLabelSetColor(lVehTheftStatus, 0, 255, 0)
			setElementData(resourceRoot, "vehtheft", "Opened")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Vehicle Theft", tostring(status))
		end
	end
end

function togglePropBreak()
	if exports.integration:isPlayerTrialAdmin(getLocalPlayer()) then
		local status = getElementData(resourceRoot, "propbreak")
		local pdTeam = exports.factions:getTeamFromFactionID(1) --PD
		local hpTeam = exports.factions:getTeamFromFactionID(59) --HP
		local numPdMembers = (pdTeam and #getPlayersInTeam(pdTeam) or 0) + (hpTeam and #getPlayersInTeam(hpTeam) or 0)
		if numPdMembers < 3 then return outputChatBox("You can not not toggle this when there's less than 3 PD or HP members online.") end -- Automaticly to 'on hold' is less than 3 pd members
		if status == "Opened" then
			guiSetText(lPropBreakStatus, "On hold")
			guiLabelSetColor(lPropBreakStatus, 255, 0, 0)
			setElementData(resourceRoot, "propbreak", "On hold")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Property Break-in", tostring(status))
		elseif status == "On hold" then
			guiSetText(lPropBreakStatus, "Opened")
			guiLabelSetColor(lPropBreakStatus, 0, 255, 0)
			setElementData(resourceRoot, "propbreak", "Opened")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Property Break-in", tostring(status))
		end
	end
end

function togglePaperForg()
	if exports.integration:isPlayerTrialAdmin(getLocalPlayer()) then
		local status = getElementData(resourceRoot, "papforg")
		local pdTeam = exports.factions:getTeamFromFactionID(1) --PD
		local hpTeam = exports.factions:getTeamFromFactionID(59) --HP
		local numPdMembers = (pdTeam and #getPlayersInTeam(pdTeam) or 0) + (hpTeam and #getPlayersInTeam(hpTeam) or 0)
		if numPdMembers < 3 then return outputChatBox("You can not not toggle this when there's less than 3 PD or HP members online.") end -- Automaticly to 'on hold' is less than 3 pd members
		if status == "Opened" then
			guiSetText(lPapForgeryStatus, "On hold")
			guiLabelSetColor(lPapForgeryStatus, 255, 0, 0)
			setElementData(resourceRoot, "papforg", "On hold")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Paper Forgery", tostring(status))
		elseif status == "On hold" then
			guiSetText(lPapForgeryStatus, "Opened")
			guiLabelSetColor(lPapForgeryStatus, 0, 255, 0)
			setElementData(resourceRoot, "papforg", "Opened")
			triggerServerEvent("toggleStatus", localPlayer, localPlayer, "Paper Forgery", tostring(status))
		end
	end
end

-- //Chaos
function showReportMainUI()
	local logged = getElementData(getLocalPlayer(), "loggedin")
	--outputDebugString(logged)
	if (logged==1) then
		if (wReportMain==nil)  then
			reportedPlayer = nil
			wReportMain = guiCreateWindow(0.2, 0.2, 0.2, 0.25, "Direct-Hosting - F2 - شكاوي", true)
			scale(wReportMain)

			-- Controls within the window
			bClose = guiCreateButton(0.85, 0.9, 0.2, 0.1, "غلق", true, wReportMain)
			addEventHandler("onClientGUIClick", bClose, clickCloseButton)

			-- Status
			lStatus = guiCreateLabel(0.48, 0.05, 1.0, 0.5, "الحاله", true, wReportMain)
			guiSetFont(lStatus, "default-bold-small")

			lVehTheft = guiCreateLabel(0.125, 0.1, 1.0, 0.5, "سرقة سيارة", true, wReportMain)
			lPropBreak = guiCreateLabel(0.44, 0.1, 1.0, 0.5, "كسر في الممتلكات", true, wReportMain)
			lPapForgery = guiCreateLabel(0.75, 0.1, 1.0, 0.5, "تزوير ورقة", true, wReportMain)

			local vehTheftStatus = getElementData(resourceRoot, "vehtheft")
			local propBreakStatus = getElementData(resourceRoot, "propbreak")
			local papForgeStatus = getElementData(resourceRoot, "papforg")

			lVehTheftStatus = guiCreateLabel(0.145, 0.15, 1.0, 0.5, vehTheftStatus, true, wReportMain)
			lPropBreakStatus = guiCreateLabel(0.47, 0.15, 1.0, 0.5, propBreakStatus, true, wReportMain)
			lPapForgeryStatus = guiCreateLabel(0.77, 0.15, 1.0, 0.5, papForgeStatus, true, wReportMain)

			if vehTheftStatus == "Opened" then guiLabelSetColor(lVehTheftStatus, 0, 255, 0) end
			if vehTheftStatus == "On hold" then guiLabelSetColor(lVehTheftStatus, 255, 0, 0) end

			if propBreakStatus == "Opened" then guiLabelSetColor(lPropBreakStatus, 0, 255, 0) end
			if propBreakStatus == "On hold" then guiLabelSetColor(lPropBreakStatus, 255, 0, 0) end

			if papForgeStatus == "Opened" then guiLabelSetColor(lPapForgeryStatus, 0, 255, 0) end
			if papForgeStatus == "On hold" then guiLabelSetColor(lPapForgeryStatus, 255, 0, 0) end

			local canEditStatus = exports.integration:isPlayerTrialAdmin(getLocalPlayer())

			if canEditStatus then
				bVehTheft = guiCreateButton(0.130, 0.2, 0.10, 0.05, "تبديل", true, wReportMain)
				bPropBreak = guiCreateButton(0.45, 0.2, 0.10, 0.05, "تبديل", true, wReportMain)
				bPapForgery = guiCreateButton(0.75, 0.2, 0.10, 0.05, "تبديل", true, wReportMain)

				addEventHandler("onClientGUIClick", bVehTheft, toggleVehTheft, false)
				addEventHandler("onClientGUIClick", bPropBreak, togglePropBreak, false)
				addEventHandler("onClientGUIClick", bPapForgery, togglePaperForg, false)
			end

			guiSetInputEnabled(true)

			bHelp = guiCreateButton(0.025, 0.9, 0.2, 0.1, "عرض مساعدة / أوامر", true, wReportMain)
			guiSetEnabled(bHelp, true)
			addEventHandler("onClientGUIClick", bHelp, clickCloseButton)

			lPlayerName = guiCreateLabel(0.025, 0.28, 1.0, 0.3, "لاعب كنت ترغب في تقرير (اختياري ) :", true, wReportMain)
			guiSetFont(lPlayerName, "default-bold-small")

			tPlayerName = guiCreateEdit(0.025, 0.32, 0.25, 0.08, "لاعب الجزئي اسم / ID", true, wReportMain)
			addEventHandler("onClientGUIClick", tPlayerName, function()
				guiSetText(tPlayerName,"")
			end, false)

			lNameCheck = guiCreateLabel(0.025, 0.4, 1.0, 0.3, "كنت التقارير نفسك .", true, wReportMain)
			guiSetFont(lNameCheck, "default-bold-small")
			guiLabelSetColor(lNameCheck, 0, 255, 0)
			addEventHandler("onClientGUIChanged", tPlayerName, checkNameExists)

			lReportType = guiCreateLabel(0.4, 0.28, 0.23, 0.3, "حدد الخيار الذي أفضل\nيناسب التقرير الخاص بك.\nهذا يرسل التقرير الخاص بك للموظف المناسب.", true, wReportMain)

			cReportType = guiCreateComboBox(0.65, 0.32, 0.3, 0.34, "نوع التقرير", true, wReportMain)
			for key, value in ipairs(reportTypes) do
				guiComboBoxAddItem(cReportType, value[1])
			end
			addEventHandler("onClientGUIComboBoxAccepted", cReportType, canISubmit)
			addEventHandler("onClientGUIComboBoxAccepted", cReportType, function()
				local selected = guiComboBoxGetSelected(cReportType)+1
				guiLabelSetHorizontalAlign( lReportType, "center", true)
				guiSetText(lReportType, reportTypes[selected][7])
				end)

			lReport = guiCreateLabel(0, 0.46, 1.0, 0.3, "~ == تقرير معلومات == ~", true, wReportMain)
			guiLabelSetHorizontalAlign(lReport, "center")
			guiSetFont(lReport, "default-bold-small")
			guiSetFont(lPlayerName, "default-bold-small")

			tReport = guiCreateMemo(0.025, 0.49, 6, 0.3, "", true, wReportMain)
			addEventHandler("onClientGUIChanged", tReport, canISubmit)

			lLengthCheck = guiCreateLabel(0.4, 0.81, 0.4, 0.3, "Length: " .. string.len(tostring(guiGetText(tReport)))-1 .. "/ 150 حرفا", true, wReportMain)
			guiLabelSetColor(lLengthCheck, 0, 255, 0)
			guiSetFont(lLengthCheck, "default-bold-small")

			bSubmitReport = guiCreateButton(0.4, 0.875, 0.2, 0.1, "إرسال تقرير", true, wReportMain)
			addEventHandler("onClientGUIClick", bSubmitReport, submitReport)
			guiSetEnabled(bSubmitReport, false)

			guiWindowSetSizable(wReportMain, false)
			showCursor(true)

		elseif (wReportMain~=nil) then
			guiSetVisible(wReportMain, false)
			destroyElement(wReportMain)

			wReportMain, bClose, lStatus, lVehTheft, lPropBreak, lPapForgery, lVehTheftStatus, lPropBreakStatus, lPapForgeryStatus, bVehTheft, bPropBreak, bPapForgery, bHelp, lPlayerName, tPlayerName, lNameCheck, lReport, tReport, lLengthCheck, bSubmitReport = nil
			guiSetInputEnabled(false)
			showCursor(false)
		end
	end
end
addCommandHandler("report", showReportMainUI)

function submitReport(button, state)
	if (source==bSubmitReport) and (button=="left") and (state=="up") then
		triggerServerEvent("clientSendReport", getLocalPlayer(), reportedPlayer or getLocalPlayer(), tostring(guiGetText(tReport)), (guiComboBoxGetSelected(cReportType)+1))

		if (wReportMain~=nil) then
			destroyElement(wReportMain)
		end

		if (wHelp) then
			destroyElement(wHelp)
		end

		wReportMain, bClose, lStatus, lVehTheft, lPropBreak, lPapForgery, lVehTheftStatus, lPropBreakStatus, lPapForgeryStatus, bVehTheft, bPropBreak, bPapForgery, bHelp, lPlayerName, tPlayerName, lNameCheck, lReport, tReport, lLengthCheck, bSubmitReport = nil
		guiSetInputEnabled(false)
		showCursor(false)
	end
end

function checkReportLength(theEditBox)
	guiSetText(lLengthCheck, "Length: " .. string.len(tostring(guiGetText(tReport)))-1 .. "/ 150 حرفا.")

	if (tonumber(string.len(tostring(guiGetText(tReport))))-1>150) then
		guiLabelSetColor(lLengthCheck, 255, 0, 0)
		return false
	elseif (tonumber(string.len(tostring(guiGetText(tReport))))-1<3) then
		guiLabelSetColor(lLengthCheck, 255, 0, 0)
		return false
	elseif (tonumber(string.len(tostring(guiGetText(tReport))))-1>130) then
		guiLabelSetColor(lLengthCheck, 255, 255, 0)
		return true
	else
		guiLabelSetColor(lLengthCheck,0, 255, 0)
		return true
	end
end

function checkType(theGUI)
	local selected = guiComboBoxGetSelected(cReportType)+1 -- +1 to relate to the table for later

	if not selected or selected == 0 then
		return false
	else
		return true
	end
end

function canISubmit()
	local rType = checkType()
	local rReportLength = checkReportLength()
	--[[local adminreport = getElementData(getLocalPlayer(), "adminreport")
	local gmreport = getElementData(getLocalPlayer(), "gmreport")]]
	local reportnum = getElementData(getLocalPlayer(), "reportNum")
	if rType and rReportLength then
		if reportnum then
			guiSetText(wReportMain, "معرف التقرير الخاص بك #" .. (reportnum).. " لا تزال معلقة. /er يرجى الانتظار أو قبل تقديم آخر .")
		else
			guiSetEnabled(bSubmitReport, true)
		end
	else
		guiSetEnabled(bSubmitReport, false)
	end
end

function checkNameExists(theEditBox)
	local found = nil
	local count = 0


	local text = guiGetText(theEditBox)
	if text and #text > 0 then
		local players = getElementsByType("player")
		if tonumber(text) then
			local id = tonumber(text)
			for key, value in ipairs(players) do
				if getElementData(value, "playerid") == id then
					found = value
					count = 1
					break
				end
			end
		else
			for key, value in ipairs(players) do
				local username = string.lower(tostring(getPlayerName(value)))
				if string.find(username, string.lower(text)) then
					count = count + 1
					found = value
					break
				end
			end
		end
	end

	if (count>1) then
		guiSetText(lNameCheck, "متعددة وجدت - سوف تتخذ لنفسك أن تقدم .")
		guiLabelSetColor(lNameCheck, 255, 255, 0)
	elseif (count==1) then
		guiSetText(lNameCheck, "لاعب وجدت: " .. getPlayerName(found) .. " (ID #" .. getElementData(found, "playerid") .. ")")
		guiLabelSetColor(lNameCheck, 0, 255, 0)
		reportedPlayer = found
	elseif (count==0) then
		guiSetText(lNameCheck, "لاعب لم يتم العثور - هل تأخذ نفسك على تقديم.")
		guiLabelSetColor(lNameCheck, 255, 0, 0)
	end
end

-- Close button
function clickCloseButton(button, state)
	if (source==bClose) and (button=="left") and (state=="up") then
		if (wReportMain~=nil) then
			destroyElement(wReportMain)
		end

		if (wHelp) then
			destroyElement(wHelp)
		end

		wReportMain, bClose, lStatus, lVehTheft, lPropBreak, lPapForgery, lVehTheftStatus, lPropBreakStatus, lPapForgeryStatus, bVehTheft, bPropBreak, bPapForgery, bHelp, lPlayerName, tPlayerName, lNameCheck, lReport, tReport, lLengthCheck, bSubmitReport = nil
		guiSetInputEnabled(false)
		showCursor(false)
	elseif (source==bHelp) and (button=="left") and (state=="up") then
		if (wReportMain~=nil) then
			destroyElement(wReportMain)
		end

		wReportMain, bClose, lStatus, lVehTheft, lPropBreak, lPapForgery, lVehTheftStatus, lPropBreakStatus, lPapForgeryStatus, bVehTheft, bPropBreak, bPapForgery, bHelp, lPlayerName, tPlayerName, lNameCheck, lReport, tReport, lLengthCheck, bSubmitReport = nil
		guiSetInputEnabled(false)
		showCursor(false)

		triggerEvent("viewF1Help", getLocalPlayer())
	end
end

function onOpenCheck(playerID)
	executeCommandHandler ( "check", tostring(playerID) )
end
addEvent("report:onOpenCheck", true)
addEventHandler("report:onOpenCheck", getRootElement(), onOpenCheck)
