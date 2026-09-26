-- Made by anumaz

 local callsigns = {
 "Alpha 1 - Executive Staff",
 "Alpha 2 - Command Staff",
 "Alpha 3 - Supervisory Staff",
 "Charlie 1",
 "Charlie 2",
 "Charlie 3",
 "Charlie 4",
 "Charlie 5",
 "Charlie 6",
 "Charlie 7",
 "Charlie 8",
 "Charlie 9",
 "Charlie 10",
 "Delta 1",
 "Delta 2",
 "Echo 1",
 "Echo 2",
 "Echo 3",
 "Hotel 1",
 "Kilo 1",
 "Kilo 2",
 "Mike 1 2",
 "Mike 1 3",
 "Oscar 1",
 "Oscar 2",
 "Papa 1 (Parole Services)",
 "Papa 2 (San Andreas Detention Center)",
 "Sierra 1"
}

local isNewTable = { }

local GUIEditor = {
    combobox = {},
    label = {},
    button = {},
    window = {},
    scrollbar = {},
    memo = {}
}

function buildDispatchGUI()
	if isElement(GUIEditor.window[1]) then destroyElement(GUIEditor.window[1]) end -- To avoid having two windows

	local name = getPlayerName(localPlayer)
	local processedName = string.gsub(name, "_", " ")

	local status = getElementData(localPlayer, "dispatch:status") or "Off duty"
	local callsign
	local availability

	if status ~= "Off duty" then
		callsign = getElementData(localPlayer, "dispatch:callsign") or "Not set"
		availability = getElementData(localPlayer, "dispatch:availability") or "Not set"
	else
		callsign = "Off duty"
		availability = "Off duty"
	end

	local screenX, screenY = guiGetScreenSize()
	local width = 600
	local height = 400
	local x = ( screenX - width ) / 2
	local y = ( screenY - height ) / 2
	GUIEditor.window[1] = guiCreateWindow(x, y, width, height, "Remote Dispatch Device - Powered by Tree Technology", false)
	guiWindowSetSizable(GUIEditor.window[1], false)

	-- Header Information
	GUIEditor.label[1] = guiCreateLabel(0.03, 0.07, 0.2, 0.07, "You are logged in as:", true, GUIEditor.window[1])
	GUIEditor.label[7] = guiCreateLabel(0.24, 0.07, 0.20, 0.07, processedName, true, GUIEditor.window[1])

	GUIEditor.label[2] = guiCreateLabel(0.03, 0.14, 0.19, 0.07, "Time:", true, GUIEditor.window[1])
	GUIEditor.label[8] = guiCreateLabel(0.24, 0.14, 0.20, 0.07, getDateTime(), true, GUIEditor.window[1])
	GUIEditor.label[3] = guiCreateLabel(0.02, 0.2, 0.52, 0.04, "______________________________________________________", true, GUIEditor.window[1])


	-- Update user information
	GUIEditor.label[4] = guiCreateLabel(0.02, 0.33, 0.13, 0.07, "Status:", true, GUIEditor.window[1])
	GUIEditor.label[5] = guiCreateLabel(0.02, 0.41, 0.13, 0.07, "Callsign:", true, GUIEditor.window[1])
	GUIEditor.label[6] = guiCreateLabel(0.02, 0.5, 0.13, 0.07, "Availability:", true, GUIEditor.window[1])
	GUIEditor.combobox[1] = guiCreateComboBox(0.15, 0.32, 0.35, 0.19, status, true, GUIEditor.window[1])
	guiComboBoxAddItem(GUIEditor.combobox[1], "Off duty")
	guiComboBoxAddItem(GUIEditor.combobox[1], "On duty")
	GUIEditor.combobox[2] = guiCreateComboBox(0.15, 0.405, 0.35, 0.4, callsign, true, GUIEditor.window[1])

	--To load the callsigns in the combobox
	for _, v in pairs(callsigns) do
		guiComboBoxAddItem(GUIEditor.combobox[2], v)
	end

	GUIEditor.combobox[3] = guiCreateComboBox(0.15, 0.49, 0.35, 0.34, availability, true, GUIEditor.window[1])
	guiComboBoxAddItem(GUIEditor.combobox[3], "Patroling")
	guiComboBoxAddItem(GUIEditor.combobox[3], "In roll call")
	guiComboBoxAddItem(GUIEditor.combobox[3], "Unavailable")
	guiComboBoxAddItem(GUIEditor.combobox[3], "In training")
	guiComboBoxAddItem(GUIEditor.combobox[3], "Traffic stop")
	guiComboBoxAddItem(GUIEditor.combobox[3], "In pursuit")
	guiComboBoxAddItem(GUIEditor.combobox[3], "In operation")
	--[[GUIEditor.label[9] = guiCreateLabel(0.15, 0.33, 0.17, 0.07, status, true, GUIEditor.window[1])
	GUIEditor.label[10] = guiCreateLabel(0.15, 0.41, 0.28, 0.07, callsign, true, GUIEditor.window[1])
	GUIEditor.label[11] = guiCreateLabel(0.15, 0.48, 0.17, 0.07, availability, true, GUIEditor.window[1])]]
	GUIEditor.memo[1] = guiCreateMemo(0.55, 0.06, 0.54, 0.8, getData(), true, GUIEditor.window[1])
	guiMemoSetReadOnly(GUIEditor.memo[1], true)

	GUIEditor.button[4] = guiCreateButton(0.01, 0.89, 0.98, 0.1, "Close", true, GUIEditor.window[1])

	addEventHandler("onClientGUIClick", GUIEditor.button[4], function () -- Close button
		if isElement(GUIEditor.window[1]) then destroyElement(GUIEditor.window[1]) end
	end, false)

	addEventHandler("onClientGUIComboBoxAccepted", GUIEditor.combobox[1], function () -- Change status button
		local newstatus = guiGetText( GUIEditor.combobox[1] )
		if newstatus == nil or string.len(newstatus) < 2 then newstatus = "Off duty" end
		setElementData(localPlayer, "dispatch:status", newstatus)
		reloadWindow()
	end, false)

	addEventHandler("onClientGUIComboBoxAccepted", GUIEditor.combobox[2], function () -- Change callsign
		local newcallsign = guiGetText(GUIEditor.combobox[2])
		if newcallsign == nil or string.len(newcallsign) < 2 then newcallsign = "Not set" end
		setElementData(localPlayer, "dispatch:callsign", newcallsign)
		reloadWindow()
	end, false)

	addEventHandler("onClientGUIComboBoxAccepted", GUIEditor.combobox[3], function () -- Change availability
		local newavailability = guiGetText(GUIEditor.combobox[3])
		if newavailability == nil or string.len(newavailability) < 2 then newavailability = "Not set" end
		setElementData(localPlayer, "dispatch:availability", newavailability)
		reloadWindow()
	end, false)
end

function canUseDispatch()
    if exports.global:hasItem(localPlayer, 177) and getPlayerTeam(localPlayer) == getTeamFromName( "San Andreas Highway Patrol" ) then
		buildDispatchGUI()
	else
		outputChatBox("Dispatching through thin air does not seem to work well...", 255, 0, 0)
	end
end
addCommandHandler("dispatch", canUseDispatch)

addEventHandler ( "onClientElementDataChange", root,
function ( dataName )
	if isElement(GUIEditor.window[1]) and (dataName == "dispatch:status" or "dispatch:callsign" or "dispatch:availability") then
		guiSetText(GUIEditor.memo[1], getData())
	end
end )

function getData() -- This function gets the data to display in 'memo' (display all on duty people, with their info)
	local peopleOnDispatch = { }
	for key, value in ipairs(callsigns) do
		for k, v in ipairs(getPlayersInTeam(getTeamFromName("San Andreas Highway Patrol"))) do
			local officerCallsign = getElementData(v, "dispatch:callsign") or "Not set"
			local officerStatus = getElementData(v, "dispatch:status")
			if officerCallsign == value and officerStatus ~= nil and officerStatus ~= "Off duty" then
				local streetlocation = getElementData(v, "dispatch:street") or false
				local officerAvailability = getElementData(v, "dispatch:availability") or "Not set"
				if streetlocation then
					peopleOnDispatch[string.gsub(getPlayerName(v), "_", " ")] = {" - "..officerAvailability.." at "..streetlocation, value}
				else
					peopleOnDispatch[string.gsub(getPlayerName(v), "_", " ")] = {" - "..officerAvailability, value}
				end
			end
		end
	end

	local content = ""
	local first = "true"
	for key, value in pairs(peopleOnDispatch) do
		if isNew(value[2]) then
			content = content .. (first=="true" and " >"..value[2] or "\n\n" .. " >"..value[2])
			first = "false"
		end
		content = content .."\n".. tostring(key) .. value[1]..""
	end
	isNew("clear")
	return content
end

function isNew(value)
	if value=="clear" then
		isNewTable = { }
		return
	end

	if isNewTable[value] then
		return
	else
		isNewTable[value] = true
		return true
	end
end

function reloadWindow()
	destroyElement(GUIEditor.window[1])
	buildDispatchGUI()
end

function getDateTime()
    local time = getRealTime()
    local hour = time.hour
    local minutes = time.minute
    local date = time.monthday
    local month = time.month+1
    local year = time.year+1900
    local content = hour..":"..minutes.." - "..date.."/"..month.."/"..year
    return tostring(content)
end
