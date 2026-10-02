function enterCommand(commandName, ...)
	triggerServerEvent("checkCommandEntered", getLocalPlayer(), getLocalPlayer(), commandName, ...)
end
addCommandHandler("check", enterCommand, false, false)

-- true while the cursor is on because THIS panel turned it on (refcount-safe
-- close: we never hide a cursor that another panel is using)
local checkCursorOwned = false

function CreateCheckWindow()
	local width, height = guiGetScreenSize()	
	Button = {}
	Window = guiCreateWindow(width-400,0,400,385,"Player Check",false)
	guiWindowSetSizable(Window, false)
	Button[3] = guiCreateButton(338,336,52,35,"Close",false,Window)
	addEventHandler( "onClientGUIClick", Button[3], CloseCheck )
	Label = {
		guiCreateLabel(0.03,0.06,0.95,0.0887,"Name: N/A",true,Window),
		guiCreateLabel(0.03,0.10,0.66,0.0887,"IP: N/A",true,Window),
		guiCreateLabel(0.03,0.26,0.66,0.0887,"Money: N/A",true,Window),
		guiCreateLabel(0.03,0.30,0.17,0.0806,"Health: N/A",true,Window),
		guiCreateLabel(0.27,0.34,0.30,0.0806,"Armor: N/A",true,Window),
		guiCreateLabel(0.03,0.34,0.17,0.0806,"Skin: N/A",true,Window),
		guiCreateLabel(0.27,0.30,0.30,0.0806,"Weapon: N/A",true,Window),
		guiCreateLabel(0.03,0.38,0.66,0.0806,"Faction: N/A",true,Window),
		guiCreateLabel(0.03,0.18,0.66,0.0806,"Ping: N/A",true,Window),
		guiCreateLabel(0.03,0.42,0.66,0.0806,"Vehicle: N/A",true,Window),
		guiCreateLabel(0.03,0.46,0.66,0.0806,"Warns: N/A",true,Window),
		guiCreateLabel(0.03,0.50,0.97,0.0766,"Location: N/A",true,Window),
		guiCreateLabel(0.7,0.06,0.4031,0.0766,"X:",true,Window),
		guiCreateLabel(0.7,0.10,0.4031,0.0766,"Y: N/A",true,Window),
		guiCreateLabel(0.7,0.14,0.4031,0.0766,"Z: N/A",true,Window),
		guiCreateLabel(0.7,0.18,0.2907,0.0806,"Interior: N/A",true,Window),
		guiCreateLabel(0.7,0.22,0.2907,0.0806,"Dimension: N/A",true,Window),
		guiCreateLabel(0.03,0.14,0.66,0.0887,"Admin Level: N/A", true,Window),
		guiCreateLabel(0.7,0.26,0.4093,0.0806,"Hours on Character: N/A\n~ Total: N/A",true,Window),
		guiCreateLabel(0.03,0.22,0.66,0.0887,"GameCoins: N/A", true,Window),
		guiCreateLabel(0.03,0.50,0.66,0.0806,"",true,Window),
	}
	
	-- player notes
	memo = guiCreateMemo(16, 240, 314, 131, "", false, Window)
	addEventHandler( "onClientGUIClick", Window,
		function( button, state )
			if button == "left" and state == "up" then
				if source == memo then
					guiSetInputEnabled( true )
				else
					guiSetInputEnabled( false )
				end
			end
		end
	)
	Button[4] = guiCreateButton(338,240,52,52,"Save\nNote",false,Window)
	
	addEventHandler( "onClientGUIClick", Button[4], SaveNote, false )
	
	Button[5] = guiCreateButton(16,206,314,30,"History: N/A",false,Window)
	addEventHandler( "onClientGUIClick", Button[5], ShowHistory, false )
	
	Button[6] = guiCreateButton(338,296,52,36,"Inv.",false,Window)
	addEventHandler( "onClientGUIClick", Button[6], showInventory, false )

	guiSetVisible(Window, false)
end

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()),
	function ()
		CreateCheckWindow()
	end
)

function OpenCheck( ip, adminreports, donPoints, note, history, warns, transfers, bankmoney, money, adminlevel, hoursPlayed, accountname, hoursAcc )
	player = source

	-- accountname
	guiSetText ( Label[1], "Name: " .. getPlayerName(player):gsub("_", " ") .. " ("..accountname..")")
	if adminreports == nil then
		adminreports = "-1"
	end
	
	
	if donPoints == nil then
		donPoints = "Unknown"
	end
	
	if transfers == nil then
		transfers = "N/A"
	end
	
	if warns == nil then
		warns = "N/A"
	end
	
	if history == nil then
		history = "N/A"
	else
		local total = 0
		local str = {}
		for key, value in ipairs(history) do
			total = total + value[2]
			table.insert(str, value[2] .. " " .. getHistoryAction(value[1]))
			if key % 2 == 0 and key < #history then
				table.insert( str, "\n" )
			end
		end
		history = table.concat(str, " ")
	end
	
	if bankmoney == nil then
		bankmoney = "-1"
	end
	
	guiSetText ( Label[2], "IP: " .. ip )
	guiSetText ( Label[18], "Admin Level: " ..adminlevel.. " (" .. adminreports .. " Reports)" )
	guiSetText ( Label[11], "Warns: " .. warns )
	if not exports.integration:isPlayerTrialAdmin(getLocalPlayer()) then
		guiSetText ( Label[3], "Money: N/A (Bank: N/A)")
	else	
		guiSetText ( Label[3], "Money: $" .. exports.global:formatMoney(money) .. " (Bank: $" .. exports.global:formatMoney(bankmoney) .. ")")
	end
	guiSetText ( Button[5], history )
	guiSetText ( Label[20], "GameCoins: " .. exports.global:formatMoney(donPoints) )
	guiSetText ( Label[19], "Hours Char: " .. ( hoursPlayed or "N/A" ) .. "\n~ Total: " .. ( hoursAcc or "N/A" ) )
	
	if (player == getLocalPlayer()) and not exports.integration:isPlayerAdmin(getLocalPlayer()) then
		guiSetText ( memo, "-You can not view your own note-")
		guiMemoSetReadOnly(memo, true)
		guiSetEnabled(Button[4], false)
	elseif not exports.integration:isPlayerTrialAdmin(getLocalPlayer()) then
		guiSetText ( memo, "-You do not have access to admin note-")
		guiMemoSetReadOnly(memo, true)
		guiSetEnabled(Button[4], false)
	else
		guiSetText ( memo, note or "ERROR: COULD NOT FETCH NOTE")
		guiSetEnabled(Button[4], true)
		guiMemoSetReadOnly(memo, false)
	end

	if not guiGetVisible( Window ) then
		if not isCursorShowing() then
			showCursor( true )
			checkCursorOwned = true
		end

		guiSetVisible(Window, true)
	end
end

addEvent( "onCheck", true )
addEventHandler( "onCheck", getRootElement(), OpenCheck )


addEventHandler( "onClientRender", getRootElement(),
	function()
		if guiGetVisible(Window) and isElement( player ) then
			local x, y, z = 0, 0, 0
			if not exports.integration:isPlayerSupporter(getLocalPlayer()) and getElementAlpha(player) ~= 0 or exports.integration:isPlayerSeniorAdmin(getLocalPlayer()) then 
				x, y, z = getElementPosition(player)
				guiSetText ( Label[13], "X: " .. string.format("%.5f", x) )
				guiSetText ( Label[14], "Y: " .. string.format("%.5f", y) )
				guiSetText ( Label[15], "Z: " .. string.format("%.5f", z) )
			
			else
				guiSetText ( Label[13], "X: N/A" )
				guiSetText ( Label[14], "Y: N/A" )
				guiSetText ( Label[15], "Z: N/A" )
			end
			
			guiSetText ( Label[4], "Health: " .. math.floor( getElementHealth( player ) ) )
			guiSetText ( Label[5], "Armour: " .. math.floor( getPedArmor( player ) ) )
			guiSetText ( Label[6], "Skin: " .. getElementModel( player ) )
			
			local weapon = getPedWeapon( player )
			if weapon then
				weapon = getWeaponNameFromID( weapon )
			else
				weapon = "N/A"
			end
			guiSetText ( Label[7], "Weapon: " .. weapon )

			local team = getPlayerTeam(player)
			if team then --and exports.integration:isPlayerAdmin(getLocalPlayer()) then -- Maxime | Faction info is visible for Lead+ only
				guiSetText ( Label[8], "Faction: " .. getTeamName(team) )
			else
				guiSetText ( Label[8], "Faction: N/A")
			end
			guiSetText ( Label[9], "Ping: " .. getPlayerPing( player ) )
			
			local vehicle = getPedOccupiedVehicle( player )
			if vehicle and not exports.integration:isPlayerSupporter(getLocalPlayer()) then
				guiSetText ( Label[10], "Vehicle: " .. exports.global:getVehicleName( vehicle ) .. " (" ..getVehicleName( vehicle ).." - "..getElementData( vehicle, "dbid" ) .. ")" )
			else
				guiSetText ( Label[10], "Vehicle: N/A")
			end
			if not exports.integration:isPlayerSupporter(getLocalPlayer()) then
				guiSetText ( Label[12], "Location: " .. getZoneName( x, y, z ) )
				guiSetText ( Label[16], "Interior: " .. getElementInterior( player ) )
				guiSetText ( Label[17], "Dimension: " .. getElementDimension( player ) )
			else
				guiSetText ( Label[12], "Location: N/A" )
				guiSetText ( Label[16], "Interior: N/A" )
				guiSetText ( Label[17], "Dimension: N/A" )
			end
		end
	end
)

function CloseCheck( button, state )
	if source == Button[3] and button == "left" and state == "up" then
		if checkCursorOwned then
			triggerEvent("cursorHide", getLocalPlayer())
			checkCursorOwned = false
		end
		guiSetVisible( Window, false )
		guiSetInputEnabled( false )
		player = nil
	end
end

function SaveNote( button, state )
	if source == Button[4] and button == "left" and state == "up" then
		local text = guiGetText(memo)
		if text then
			triggerServerEvent("savePlayerNote", getLocalPlayer(), player, text)
		end
	end
end

function ShowHistory( button, state )
	if source == Button[5] and button == "left" and state == "up" then
		triggerServerEvent( "showAdminHistory", getLocalPlayer(), player )
	end
end

function showInventory( button, state )
	if source == Button[6] and button == "left" and state == "up" then
		if not exports.integration:isPlayerSupporter(getLocalPlayer()) then
			triggerServerEvent( "admin:showInventory", player )
		end
	end
end

local wHist, gHist, bClose, lastElement

-- window


-- image-4 style dark skin for the Player Check window.
-- MTA can not recolour the default window chrome, so the whole panel (flat
-- near-black bg, red left accent bar, centred white title, bullet rows and
-- dark buttons) is drawn with dx AFTER the GUI (postGUI = true) while the
-- window is open. The note memo keeps a hole in the skin so it stays native
-- and editable (caret, selection, scroll). Every row reads guiGetText() of the
-- existing labels, so all the setters above keep working untouched.
local checkSkin = {

	bg = tocolor(14, 14, 16, 255),

	line = tocolor(38, 38, 44, 255),

	red = tocolor(226, 59, 59, 255),

	title = tocolor(255, 255, 255, 255),

	key = tocolor(255, 255, 255, 255),

	value = tocolor(200, 200, 206, 255),

	accent = tocolor(255, 92, 92, 255),

	btn = tocolor(24, 24, 28, 255),

	btnHover = tocolor(48, 48, 56, 255),

	btnOff = tocolor(17, 17, 20, 255),

	dim = tocolor(120, 120, 126, 255),

}


-- two column row grid (y positions inside the 400x385 window)
-- left: Name, IP, Admin Level, Weapon, Money, Warns, Faction, Hours, Vehicle, Location
-- right: X, Y, Z, Interior, Dimension, Health, Armour, Skin, GameCoins, Ping
local checkRows = { 36, 53, 70, 87, 104, 121, 138, 155, 172, 189 }

local checkLeft = { 1, 2, 18, 7, 3, 11, 8, 19, 10, 12 }

local checkRight = { 13, 14, 15, 16, 17, 4, 5, 6, 20, 9 }

local checkAccent = { [3] = true, [4] = true, [5] = true, [11] = true, [20] = true }



local function checkMouseOver(x, y, w, h)

	local cx, cy = getCursorPosition()

	if not cx then

		return false

	end

	local sx, sy = guiGetScreenSize()

	cx, cy = cx * sx, cy * sy

	return cx >= x and cx <= x + w and cy >= y and cy <= y + h

end



local function drawCheckRow(ox, oy, bx, tx, tw, y, index)

	local element = Label and Label[index]

	if not isElement(element) then

		return

	end

	local text = guiGetText(element)

	if not text or text == "" then

		return

	end

	dxDrawRectangle(ox + bx, oy + y + 5, 6, 2, checkSkin.red, true)

	local key, value = string.match(text, "^(.-):%s*(.*)$")

	if not key or key == "" then

		dxDrawText(text, ox + tx, oy + y, ox + tx + tw, oy + y + 15, checkSkin.key, 0.9, "default", "left", "top", true, false, true)

		return

	end

	dxDrawText(key .. ":", ox + tx, oy + y, ox + tx + tw, oy + y + 15, checkSkin.key, 0.9, "default-bold", "left", "top", true, false, true)

	if value ~= "" then

		value = string.gsub(value, "\n", " | ")

		local colour = checkAccent[index] and checkSkin.accent or checkSkin.value

		local kw = dxGetTextWidth(key .. ": ", 0.9, "default-bold")

		dxDrawText(value, ox + tx + kw, oy + y, ox + tx + tw, oy + y + 15, colour, 0.9, "default", "left", "top", true, false, true)

	end

end



local function drawCheckButton(ox, oy, element)

	if not isElement(element) then

		return

	end

	local bx, by = guiGetPosition(element, false)

	local bw, bh = guiGetSize(element, false)

	bx, by = ox + bx, oy + by

	local enabled = guiGetEnabled(element)

	local hover = enabled and checkMouseOver(bx, by, bw, bh)

	local bg = checkSkin.btn

	if not enabled then

		bg = checkSkin.btnOff

	elseif hover then

		bg = checkSkin.btnHover

	end

	dxDrawRectangle(bx, by, bw, bh, bg, true)

	if hover then

		dxDrawRectangle(bx, by, 2, bh, checkSkin.red, true)

	end

	local colour = enabled and checkSkin.title or checkSkin.dim

	dxDrawText(guiGetText(element), bx + 4, by, bx + bw - 2, by + bh, colour, 0.9, "default-bold", "center", "center", true, false, true)

end



addEventHandler("onClientRender", getRootElement(),

	function()

		if not (isElement(Window) and guiGetVisible(Window)) then

			return

		end

		-- the panel is open: the cursor must stay on (other panels / nametags rely on it)

		if not isCursorShowing() then

			showCursor(true)

			checkCursorOwned = true

		end

		local ox, oy = guiGetPosition(Window, false)

		local ow, oh = guiGetSize(Window, false)

		if isElement(memo) then

			local mx, my = guiGetPosition(memo, false)

			local mw, mh = guiGetSize(memo, false)

			-- flat near-black panel, drawn around the native note memo

			dxDrawRectangle(ox, oy, ow, my, checkSkin.bg, true)

			dxDrawRectangle(ox, oy + my, mx, mh, checkSkin.bg, true)

			dxDrawRectangle(ox + mx + mw, oy + my, ow - mx - mw, mh, checkSkin.bg, true)

			dxDrawRectangle(ox, oy + my + mh, ow, oh - my - mh, checkSkin.bg, true)

			dxDrawRectangle(ox + mx - 1, oy + my - 1, mw + 2, 1, checkSkin.line, true)

			dxDrawRectangle(ox + mx - 1, oy + my + mh, mw + 2, 1, checkSkin.line, true)

			dxDrawRectangle(ox + mx - 1, oy + my, 1, mh, checkSkin.line, true)

			dxDrawRectangle(ox + mx + mw, oy + my, 1, mh, checkSkin.line, true)

		else

			dxDrawRectangle(ox, oy, ow, oh, checkSkin.bg, true)

		end

		-- red accent bar along the far left edge + centred white title

		dxDrawRectangle(ox, oy, 4, oh, checkSkin.red, true)

		dxDrawText("Player Check", ox + 4, oy + 4, ox + ow, oy + 28, checkSkin.title, 1, "default-bold", "center", "center", false, false, true)

		dxDrawRectangle(ox + 16, oy + 31, ow - 32, 1, checkSkin.line, true)

		for i = 1, #checkRows do

			drawCheckRow(ox, oy, 16, 26, 232, checkRows[i], checkLeft[i])

			drawCheckRow(ox, oy, 262, 272, 118, checkRows[i], checkRight[i])

		end

		drawCheckButton(ox, oy, Button and Button[5])

		drawCheckButton(ox, oy, Button and Button[4])

		drawCheckButton(ox, oy, Button and Button[6])

		drawCheckButton(ox, oy, Button and Button[3])

	end

)



addEvent( "cshowAdminHistory", true )
addEventHandler( "cshowAdminHistory", getRootElement(),
	function( info, targetID )
		if wHist then
			destroyElement( wHist )
			wHist = nil
			
			showCursor( false )
		else
			local sx, sy = guiGetScreenSize()
			
			local name
			if targetID == nil then
				name = getPlayerName( source )
			else
				name = "Account " .. tostring(targetID)
			end
			
			wHist = guiCreateWindow( sx / 2 - 350, sy / 2 - 250, 800, 600, "Admin History: ".. name, false )
			
			-- date, action, reason, duration, a.username, c.charactername, id
			
			gHist = guiCreateGridList( 0, 0.04, 1, 0.88, true, wHist )
			local colID = guiGridListAddColumn( gHist, "ID", 0.05 )
			local colAction = guiGridListAddColumn( gHist, "Action", 0.07 )
			local colChar = guiGridListAddColumn( gHist, "Character", 0.2 )
			local colReason = guiGridListAddColumn( gHist, "Reason", 0.25 )
			local colDuration = guiGridListAddColumn( gHist, "Time", 0.07 )
			local colAdmin = guiGridListAddColumn( gHist, "Admin", 0.15 )
			local colDate = guiGridListAddColumn( gHist, "Date", 0.15 )
			
			
			for _, res in pairs( info ) do
				local row = guiGridListAddRow( gHist )
				guiGridListSetItemText( gHist, row, colID,   res[7]  or "?", false, true )
				guiGridListSetItemText( gHist, row, colAction, getHistoryAction(res[2]), false, false )
				guiGridListSetItemText( gHist, row, colChar, res[6], false, false )
				guiGridListSetItemText( gHist, row, colReason, res[3], false, false )
				guiGridListSetItemText( gHist, row, colDuration, historyDuration( res[4], tonumber( res[2] ) ), false, false )
				guiGridListSetItemText( gHist, row, colAdmin, res[5], false, false )
				guiGridListSetItemText( gHist, row, colDate, res[1], false, false )
			end
		
			
			local bremove = guiCreateButton( 0, 0.93, 0.5, 0.07, "Remove", true, wHist )
			addEventHandler( "onClientGUIClick", bremove,
				function( button, state )
					if exports.integration:isPlayerTrialAdmin(localPlayer) or exports.integration:isPlayerSupporter(localPlayer) then
						local row, col = guiGridListGetSelectedItem( gHist )
						if row ~= -1 and col ~= -1 then
							local gridID = guiGridListGetItemText( gHist , row, col )
							local record = getHistoryRecordFromId(info, gridID)
							if tonumber(record[2]) == 6 then
								return outputChatBox( "This record is not removable.", 255, 0, 0 )
							end
							if not exports.integration:isPlayerSeniorAdmin(localPlayer) and tonumber(record[8]) ~= getElementData(localPlayer, "account:id") then
								return outputChatBox( "You can only remove admin history that you're the creator. Otherwise, it requires a Senior Admin or higher up.", 255, 0, 0 )
							end
							triggerServerEvent("admin:removehistory", getLocalPlayer(), gridID)
							destroyElement( wHist )
							wHist = nil
							showCursor( false )
						else
							outputChatBox( "You need to pick a record.", 255, 0, 0 )
						end
					else
						outputChatBox( "Please submit a ticket on Support Center to appeal and get this admin history record removed.", 255, 0, 0 )
					end
				end, false
			)
		
			
			bClose = guiCreateButton( 0.52, 0.93, 0.47, 0.07, "Close", true, wHist )
			addEventHandler( "onClientGUIClick", bClose,
				function( button, state )
					if button == "left" and state == "up" then
						destroyElement( wHist )
						wHist = nil
						
						showCursor( false )
					end
				end, false
			)
			
			showCursor( true )
		end
	end
)
 