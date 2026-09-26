--MAXIME

apps = {

	"history",

	"contacts",

	"messages",

	"emails",

	"hotlines",

	"music",

	"weather",

	"bank",

	"appstore",

	"settings",

	"power_off",

}



guiApps = {}

local maxAppsPerRow = 3

local appsMaxRows = 4

local iconSize = 65

local iconSpacing = 5

local btnAlpha = 0.1

function drawOneApp(appPane, appId, appName, xoffset, yoffset)

	if appPane and isElement(appPane) then

		if not xoffset then xoffset = 0 end

		if not yoffset then yoffset = 0 end

		local posX = 30+xoffset

		local posY = 100+yoffset



		guiApps[appId] = {}

		guiApps[appId][1] = guiCreateStaticImage(posX,posY,iconSize,iconSize,"images/"..appName..".png",false,appPane)

		guiApps[appId][2] = guiCreateButton(posX,posY,iconSize,iconSize,"",false,appPane)

		guiSetAlpha(guiApps[appId][2], btnAlpha)

		posX = posX + iconSize+iconSpacing

		return true

	end

end



guiPaneApps = {}



function drawOnePaneOfApps(paneId, xoffset, yoffset)

	if isPhoneGUICreated() then

		if not xoffset then xoffset = 0 end

		if not yoffset then yoffset = 0 end

		local itemsPerRow = 0

		local rows = 0

		local original_xoffset = xoffset

		guiPaneApps[paneId] = guiCreateScrollPane(30+xoffset, 100+yoffset, 221, 300, false, wPhoneMenu)

		for i = 1, #apps do 

			if drawOneApp(guiPaneApps[paneId], i, apps[i],  xoffset, yoffset) then

				itemsPerRow = itemsPerRow + 1

				xoffset = xoffset + iconSpacing + iconSize

				if itemsPerRow >= maxAppsPerRow then

					itemsPerRow = 0

					rows = rows + 1

					yoffset = yoffset + iconSpacing + iconSize

					xoffset = original_xoffset

					if rows >= appsMaxRows then

						break

					end

				end

			end

		end

		return guiPaneApps[paneId]

	end

end



function drawAllPaneOfApps(xoffset, yoffset)

	if not xoffset then xoffset = 0 end

	if not yoffset then yoffset = 0 end

	if isPhoneGUICreated() and #apps > 0 then

		if #apps > 12 then

			maxAppsPerRow = 4

			appsMaxRows = 5

			iconSize = 48

		end

		local maxAppsPerPane = maxAppsPerRow*appsMaxRows

		local numberOfPanes = math.ceil(#apps/maxAppsPerPane)

		for i = 1, numberOfPanes do

			addEventHandler("onClientGUIClick", drawOnePaneOfApps(i, xoffset, yoffset), clientClickApp)

		end

		if numberOfPanes > 1 then

			--Draw switch arrows but will make later.

		end

	end

end



function togglePanesOfApps(state)

	local didIt = nil

	if guiPaneApps[1] and isElement(guiPaneApps[1]) then

		for i, pane in pairs(guiPaneApps) do

			didIt = guiSetVisible(pane, state)

		end

	end

	return didIt

end



function clientClickApp()

	if isPhoneGUICreated() then

		for i = 1, #apps do

			if source == guiApps[i][2] then

				local clickedAppName = apps[i]

				if clickedAppName == "history" then

					toggleOffEverything()

					toggleHistory(true)

				elseif clickedAppName == "bank" then 
					local width, height = 600, 400
					local scrWidth, scrHeight = guiGetScreenSize()
					local x = scrWidth/2 - (width/2)
					local y = scrHeight/2 - (height/2)
					local transactionColumns = {
						{ "ID", 0.09 },
						{ "From", 0.2 },
						{ "To", 0.2 },
						{ "Amount", 0.1 },
						{ "Date", 0.2 },
						{ "Reason", 0.5 }
					}
					guiSetInputMode("no_binds")
					wBank =guiCreateWindow(x, y, 600, 400, "Bank Phone - By:Direct-Hosting", false)
					tabPanel = guiCreateTabPanel(0.05, 0.05, 0.9, 0.85, true, wBank)
					tabPersonal = guiCreateTab("Personal Banking", tabPanel)
					local balance = getElementData(localPlayer, "bankmoney")
					lBalance = guiCreateLabel(0.1, 0.05, 0.9, 0.05, "الرصيد : $" .. exports.global:formatMoney(balance), true, tabPersonal)
					guiSetFont(lBalance, "default-bold-small")
					tabPersonalTransactions = guiCreateTab("العملات شخصية", tabPanel)
					
					addEventHandler( "onClientGUITabSwitched", tabPanel, updateTabStuff )
					gPersonalTransactions = guiCreateGridList(0.02, 0.02, 0.96, 0.96, true, tabPersonalTransactions)
					for key, value in ipairs( transactionColumns ) do
						guiGridListAddColumn( gPersonalTransactions, value[1], value[2] or 0.1 )
					end
					lTransferP = guiCreateLabel(0.1, 0.45, 0.2, 0.05, "تحويل:", true, tabPersonal)
			guiSetFont(lTransferP, "default-bold-small")
			tTransferP = guiCreateEdit(0.22, 0.43, 0.2, 0.075, "0", true, tabPersonal)
			guiSetFont(tTransferP, "default-bold-small")
			addEventHandler("onClientGUIClick", tTransferP, function()
				if guiGetText(tTransferP) == "0" then
					guiSetText(tTransferP, "")
				end
			end, false)
			eTransferP = guiCreateEdit(0.66, 0.43, 0.3, 0.075, "<Player/Faction Name>", true, tabPersonal)
			addEventHandler("onClientGUIClick", eTransferP, function()
				if guiGetText(eTransferP) == "<Player/Faction Name>" then
					guiSetText(eTransferP, "")
				end
			end, false)
			lTransferPReason = guiCreateLabel(0.1, 0.55, 0.2, 0.05, "السبب :", true, tabPersonal)
			guiSetFont(lTransferPReason, "default-bold-small")
			tTransferPReason = guiCreateEdit(0.22, 0.54, 0.74, 0.075, "<What is this transaction for?>", true, tabPersonal)
			addEventHandler("onClientGUIClick", tTransferPReason, function()
				if guiGetText(tTransferPReason) == "<What is this transaction for?>" then
					guiSetText(tTransferPReason, "")
				end
			end, false)
			function transferMoneyPersonal(button)
				if (button=="left") then
					local amount = tonumber(guiGetText(tTransferP))
					local money = getElementData(localPlayer, "bankmoney")
					local reason = guiGetText(tTransferPReason)
					local playername = guiGetText(eTransferP)
			
					if not amount or amount <= 0 or math.ceil( amount ) ~= amount then
						outputChatBox("[ Bank ] : من فضلك ادخل المبلغ المطلوب", 255, 0, 0)
					elseif (amount>money) then
						outputChatBox("[ Bank ] : انت لا تملك اموال كافية", 255, 0, 0)
					elseif reason == "" then
						outputChatBox("[ Bank ] : يجب ادخال سبب التحويل", 255, 0, 0)
					elseif playername == "" then
						outputChatBox("[ Bank ] : الرجاء ادخال اسم شخص لتتم العملية", 255, 0, 0)
					else
						triggerServerEvent("transferMoneyToPersonal", localPlayer, false, playername, amount, reason)
						guiSetText(tTransferP, "0")
						guiSetText(tTransferPReason, "")
						guiSetText(eTransferP, "")
					end
				end
			end
			bTransferP = guiCreateButton(0.44, 0.43, 0.2, 0.075, "تحويل", true, tabPersonal)
			addEventHandler("onClientGUIClick", bTransferP, transferMoneyPersonal, false)
			bClose = guiCreateButton(0.75, 0.91, 0.2, 0.1, "اغلاق", true, wBank)
			function hideBankUI()
				if isElement(wBank) then
					destroyElement(wBank)
					wBank = nil
			
					guiSetInputEnabled(false)
			
					cooldown = setTimer(function() cooldown = nil end, 1000, 1)
					setElementData(getLocalPlayer(), "exclusiveGUI", false, false)
				end
			end
			addEvent("hideBankUI", true)
			addEventHandler("hideBankUI", getRootElement(), hideBankUI)
			addEventHandler("onClientGUIClick", bClose, hideBankUI, false)
			addEventHandler ( "onSapphireXMBShow", getRootElement(), hideBankUI )
			addEventHandler("onClientChangeChar", getRootElement(), hideBankUI)
			


				elseif clickedAppName == "contacts" then

					guiSetEnabled(wPhoneMenu, false)

					if not contactList[phone] then

						triggerServerEvent("phone:requestContacts", localPlayer, phone)

					else

						openPhoneContacts(contactList[phone])

					end

				elseif clickedAppName == "power_off" then

					powerOffPhone()

				elseif clickedAppName == "settings" then

					toggleOffEverything()

					toggleSettingsGUI(true)

				elseif clickedAppName == "hotlines" then

					toggleOffEverything()

					toggleHotlines(true)

				elseif clickedAppName == "messages" then

					toggleOffEverything()

					--drawOneSMSThread()

					drawAllSMSThreads()

				end

				break

			end

		end

	end

end