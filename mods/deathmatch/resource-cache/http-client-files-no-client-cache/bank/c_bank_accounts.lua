--[[ =========================================================================
	c_bank_accounts.lua — Vortex BANK ACCOUNTS client (Fix #38)

	1:1 UIKit port of the OLD CLIENT (backupm bank-system): select-account
	window (code + PIN + your accounts combobox), main bank panel 450x300
	(15,15,15,240) with owner/balance info, big amount label, 4x3 keypad,
	Deposit / Withdraw / Transfer, create-account + change-PIN windows.
	Plus: Personal Savings / Faction Funds buttons that open the existing
	classic bank gui so the paycheck bankmoney + faction tabs keep working.
========================================================================= ]]

local localPlayer = getLocalPlayer()
local eui = exports.UIKit

local UI = {
	window = {}, label = {}, button = {}, edit = {}, combobox = {}, isKey = {}
}
local amountStr = "0"
local currentAccount = nil
local currentOwner = nil
local myAccounts = {}

local function convertNumber(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local k
	repeat
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return s
end

function bankUIKitReady()
	UI.window[1] = eui:uiCreateWindow(false, false, 261, 380, "Select your account")
	eui:uiSetVisible(UI.window[1], false)
	eui:uiWindowSetMovable(UI.window[1], false)
	eui:uiCreateLabel(15, 40, 231, 15, "Account ID:", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
	UI.edit[1] = eui:uiCreateEdit(15, 60, 231, 25, "", "", _, UI.window[1])
	eui:uiCreateLabel(15, 100, 231, 15, "PIN:", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
	UI.edit[2] = eui:uiCreateEdit(15, 120, 231, 25, "", "", _, UI.window[1])
	eui:uiEditSetMasked(UI.edit[2], true)
	eui:uiCreateLabel(15, 160, 231, 15, "Your accounts", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
	UI.combobox[1] = eui:uiCreateComboBox(15, 180, 231, 20, "", tocolor(255, 255, 255, 255), UI.window[1])
	UI.button[1] = eui:uiCreateButton(15, 236, 231, 33, "Open Account", _, UI.window[1])
	UI.button.Create = eui:uiCreateButton(15, 275, 231, 33, "Create Bank Account", _, UI.window[1])
	UI.button.ChangePIN = eui:uiCreateButton(15, 314, 112, 33, "Change PIN", _, UI.window[1])
	UI.button.Classic = eui:uiCreateButton(134, 314, 112, 33, "Savings / Faction", _, UI.window[1])
	UI.button[2] = eui:uiCreateButton(15, 353, 231, 20, "Cancel", _, UI.window[1])

	UI.window.Bank = eui:uiCreateRectangle(false, false, 450, 300, tocolor(15, 15, 15, 240), true, true, true, true)
	eui:uiSetVisible(UI.window.Bank, false)
	UI.label.Title = eui:uiCreateLabel(10, 10, 232, 20, "Bank", tocolor(255, 255, 255, 255), "left", "top", UI.window.Bank)
	eui:uiSetFont(UI.label.Title, "default-large")
	UI.label.Close = eui:uiCreateLabel(415, 10, 20, 20, "X", tocolor(255, 255, 255, 255), "right", "top", UI.window.Bank)
	eui:uiSetFont(UI.label.Close, "default-large")
	UI.label.Info = eui:uiCreateLabel(10, 40, 350, 40, "", tocolor(255, 255, 255, 255), "left", "top", UI.window.Bank)
	UI.label.AccountID = eui:uiCreateLabel(0, 10, 430, 20, "-", tocolor(255, 255, 255, 150), "right", "top", UI.window.Bank)
	eui:uiSetFont(UI.label.AccountID, "default-large")
	UI.label.Amount = eui:uiCreateLabel(20, 90, 166, 20, "$0", tocolor(255, 255, 255, 255), "center", "center", UI.window.Bank)
	eui:uiSetFont(UI.label.Amount, "default-large")

	local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "«", "0", "C" }
	for i, key in ipairs(keys) do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		local btn = eui:uiCreateButton(20 + 42 * col, 120 + 42 * row, 40, 40, key, tocolor(10, 10, 10, 255), UI.window.Bank)
		-- [Fix #52] btn is nil when UIKit has not finished starting; indexing
		-- nil killed the rest of the keypad build.
		if btn then
			UI.isKey[btn] = true
		end
	end

	UI.button.Deposit = eui:uiCreateButton(170, 120, 260, 30, "Deposit", tocolor(10, 10, 10, 240), UI.window.Bank)
	UI.button.Withdraw = eui:uiCreateButton(170, 155, 260, 30, "Withdraw", tocolor(10, 10, 10, 240), UI.window.Bank)
	UI.edit.TransferAccount = eui:uiCreateEdit(170, 195, 260, 25, "", "To Account", _, UI.window.Bank)
	UI.button.Transfer = eui:uiCreateButton(170, 225, 260, 30, "Transfer", tocolor(10, 10, 10, 240), UI.window.Bank)

	UI.window.CreateAccount = eui:uiCreateWindow(false, false, 420, 290, "Create Bank Account")
	eui:uiSetVisible(UI.window.CreateAccount, false)
	eui:uiWindowSetMovable(UI.window.CreateAccount, false)
	eui:uiCreateLabel(15, 50, 280, 15, "Enter your name:", tocolor(255, 255, 255, 255), "left", "top", UI.window.CreateAccount)
	UI.edit["CA:Name"] = eui:uiCreateEdit(15, 70, 280, 25, "", "your character name", _, UI.window.CreateAccount)
	eui:uiCreateLabel(15, 105, 280, 15, "Enter your personal ID number:", tocolor(255, 255, 255, 255), "left", "top", UI.window.CreateAccount)
	UI.edit["CA:CID"] = eui:uiCreateEdit(15, 125, 280, 25, "", "your character personal ID (/myid)", _, UI.window.CreateAccount)
	eui:uiCreateLabel(15, 160, 280, 15, "PIN (4 digits):", tocolor(255, 255, 255, 255), "left", "top", UI.window.CreateAccount)
	UI.edit["CA:Pin"] = eui:uiCreateEdit(15, 180, 100, 25, "", "PIN", _, UI.window.CreateAccount)
	eui:uiCreateLabel(15, 220, 390, 15, "Note: You must deposit $1000 to set up the account.",
		tocolor(255, 255, 255, 220), "left", "top", UI.window.CreateAccount)
	UI.button.CreateAccount = eui:uiCreateButton(15, 250, 150, 30, "Create Account", _, UI.window.CreateAccount)
	UI.button.CancelCreateAccount = eui:uiCreateButton(170, 250, 100, 30, "Cancel", _, UI.window.CreateAccount)

	UI.window.ChangePIN = eui:uiCreateWindow(false, false, 261, 324, "Change Account PIN")
	eui:uiSetVisible(UI.window.ChangePIN, false)
	eui:uiWindowSetMovable(UI.window.ChangePIN, false)
	eui:uiCreateLabel(15, 40, 231, 15, "Your Account", tocolor(255, 255, 255, 255), "left", "top", UI.window.ChangePIN)
	UI.combobox.AccountToChangePIN = eui:uiCreateComboBox(15, 60, 231, 20, "", tocolor(255, 255, 255, 255), UI.window.ChangePIN)
	eui:uiCreateLabel(15, 110, 231, 15, "PIN:", tocolor(255, 255, 255, 255), "left", "top", UI.window.ChangePIN)
	UI.edit.NewPIN = eui:uiCreateEdit(15, 130, 231, 20, "", "", _, UI.window.ChangePIN)
	eui:uiEditSetMasked(UI.edit.NewPIN, true)
	eui:uiCreateLabel(15, 160, 231, 15, "Confirm PIN:", tocolor(255, 255, 255, 255), "left", "top", UI.window.ChangePIN)
	UI.edit.NewPIN_Confirm = eui:uiCreateEdit(15, 180, 231, 20, "", "", _, UI.window.ChangePIN)
	eui:uiEditSetMasked(UI.edit.NewPIN_Confirm, true)
	UI.button.ChangePINNow = eui:uiCreateButton(15, 236, 231, 33, "Change Now", _, UI.window.ChangePIN)
	UI.button.CancelChangePIN = eui:uiCreateButton(15, 275, 231, 33, "Cancel", _, UI.window.ChangePIN)
end
addEventHandler("onClientUIReady", resourceRoot, function() bankUIKitReady() end)
addEventHandler("onClientUIKitReady", root, function() bankUIKitReady() end)

local function refreshAccountsCombo()
	eui:uiComboBoxClear(UI.combobox[1])
	eui:uiComboBoxClear(UI.combobox.AccountToChangePIN)
	for _, code in ipairs(myAccounts) do
		eui:uiComboBoxAddItem(UI.combobox[1], tostring(code))
		eui:uiComboBoxAddItem(UI.combobox.AccountToChangePIN, tostring(code))
	end
end

local function closeAll()
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window.Bank, false)
	eui:uiSetVisible(UI.window.CreateAccount, false)
	eui:uiSetVisible(UI.window.ChangePIN, false)
	showCursor(false)
end

-- entry point: the ATM / bank ped open path (s_bank_system sends this now)
addEvent("bank:openAccountsUI", true)
addEventHandler("bank:openAccountsUI", localPlayer, function()
	if getElementData(localPlayer, "exclusiveGUI") then return end
	closeAll()
	triggerServerEvent("bank:get_accounts", localPlayer)
	eui:uiSetVisible(UI.window[1], true)
	showCursor(true)
end)

addEvent("bank:get_accounts:callback", true)
addEventHandler("bank:get_accounts:callback", root, function(list)
	myAccounts = list or {}
	refreshAccountsCombo()
end)

addEvent("bank:accountsRefresh", true)
addEventHandler("bank:accountsRefresh", localPlayer, function()
	triggerServerEvent("bank:get_accounts", localPlayer)
end)

-- login success -> main panel
addEvent("ATM:openAccount", true)
addEventHandler("ATM:openAccount", localPlayer, function(code, owner, balance)
	currentAccount = tostring(code)
	currentOwner = tostring(owner)
	amountStr = "0"
	eui:uiSetText(UI.label.Amount, "$0")
	eui:uiSetText(UI.label.AccountID, tostring(code))
	eui:uiSetText(UI.label.Info, "Account Owner:  " .. currentOwner .. "\nBalance:  #00FF00$" .. convertNumber(balance))
	eui:uiSetVisible(UI.window[1], false)
	eui:uiSetVisible(UI.window.Bank, true)
end)

addEvent("ATM:updateBalance", true)
addEventHandler("ATM:updateBalance", localPlayer, function(balance, owner)
	eui:uiSetProperty(UI.button.Deposit, "Disabled", "False")
	eui:uiSetProperty(UI.button.Withdraw, "Disabled", "False")
	eui:uiSetProperty(UI.button.Transfer, "Disabled", "False")
	amountStr = "0"
	eui:uiSetText(UI.label.Amount, "$0")
	if balance then
		eui:uiSetText(UI.label.Info, "Account Owner:  " .. tostring(owner or currentOwner or "") .. "\nBalance:  #00FF00$" .. convertNumber(balance))
	end
end)

addEventHandler("onClientUIClick", root, function()
	if UI.isKey[source] then
		if amountStr == "0" then amountStr = "" end
		local key = eui:uiGetText(source)
		if key == "«" then
			amountStr = amountStr:sub(1, math.max(#amountStr - 1, 0))
			if amountStr == "" then amountStr = "0" end
			eui:uiSetText(UI.label.Amount, "$" .. convertNumber(amountStr))
		elseif key == "C" then
			amountStr = "0"
			eui:uiSetText(UI.label.Amount, "$0")
		elseif #amountStr < 7 then
			amountStr = amountStr .. key
			eui:uiSetText(UI.label.Amount, "$" .. convertNumber(amountStr))
		end
	elseif source == UI.button.Deposit then
		local amount = tonumber(amountStr)
		if amount and amount > 0 and currentAccount then
			eui:uiSetProperty(source, "Disabled", "True")
			triggerServerEvent("ATM:depositAmount", localPlayer, currentAccount, amount)
		end
	elseif source == UI.button.Withdraw then
		local amount = tonumber(amountStr)
		if amount and amount > 0 and currentAccount then
			eui:uiSetProperty(source, "Disabled", "True")
			triggerServerEvent("ATM:withdrawAmount", localPlayer, currentAccount, amount, "bank")
		end
	elseif source == UI.button.Transfer then
		local amount = tonumber(amountStr)
		local target = eui:uiGetText(UI.edit.TransferAccount)
		if amount and amount > 0 and currentAccount and target and #target > 2 then
			eui:uiSetProperty(source, "Disabled", "True")
			triggerServerEvent("ATM:transferAmount", localPlayer, currentAccount, target, amount)
		end
	elseif source == UI.label.Close then
		closeAll()
	elseif source == UI.button[2] then
		closeAll()
	elseif source == UI.button[1] then
		local code = eui:uiGetText(UI.edit[1])
		local pin = eui:uiGetText(UI.edit[2])
		if code and #code > 0 and pin and #pin > 0 then
			eui:uiSetText(UI.edit[2], "")
			triggerServerEvent("ATM:checkPassword", localPlayer, code, pin, "bank")
		end
	elseif source == UI.button.Create then
		eui:uiSetVisible(UI.window[1], false)
		eui:uiSetVisible(UI.window.CreateAccount, true)
	elseif source == UI.button.ChangePIN then
		eui:uiSetVisible(UI.window[1], false)
		eui:uiSetVisible(UI.window.ChangePIN, true)
	elseif source == UI.button.Classic then
		-- keep the existing personal savings / faction funds gui reachable
		closeAll()
		triggerServerEvent("bank:openClassicBank", localPlayer)
	elseif source == UI.button.CancelCreateAccount then
		eui:uiSetVisible(UI.window.CreateAccount, false)
		eui:uiSetVisible(UI.window[1], true)
	elseif source == UI.button.CreateAccount then
		local name = eui:uiGetText(UI.edit["CA:Name"])
		local cid = eui:uiGetText(UI.edit["CA:CID"])
		local pin = eui:uiGetText(UI.edit["CA:Pin"])
		local charName = tostring(getElementData(localPlayer, "character:name") or ""):gsub("_", " ")
		local charID = tostring(getElementData(localPlayer, "character:id") or getElementData(localPlayer, "dbid") or "")
		if name:lower() == charName:lower() then
			if cid == charID then
				if tonumber(pin) and tonumber(pin) > 0 and #pin == 4 then
					triggerServerEvent("ATM:createAccount", localPlayer, pin)
					eui:uiSetVisible(UI.window.CreateAccount, false)
					eui:uiSetVisible(UI.window[1], true)
				else
					outputChatBox("Error: check your PIN and try again (must be 4 digits only).", 255, 0, 0)
				end
			else
				outputChatBox("Error: Your personal ID is incorrect.", 255, 0, 0)
			end
		else
			outputChatBox("Error: Your name is incorrect.", 255, 0, 0)
		end
	elseif source == UI.button.CancelChangePIN then
		eui:uiSetVisible(UI.window.ChangePIN, false)
		eui:uiSetVisible(UI.window[1], true)
	elseif source == UI.button.ChangePINNow then
		local sel = eui:uiComboBoxGetSelected(UI.combobox.AccountToChangePIN)
		if sel == -1 then
			outputChatBox("ERROR: Select your account.", 255, 0, 0)
			return
		end
		local newPin = eui:uiGetText(UI.edit.NewPIN)
		if tonumber(newPin) and #tostring(newPin) == 4 then
			if newPin == eui:uiGetText(UI.edit.NewPIN_Confirm) then
				triggerServerEvent("bank:changePIN", localPlayer,
					eui:uiComboBoxGetItemText(UI.combobox.AccountToChangePIN, sel), newPin)
				eui:uiSetText(UI.edit.NewPIN, "")
				eui:uiSetText(UI.edit.NewPIN_Confirm, "")
			else
				outputChatBox("ERROR: The PIN does not match.", 255, 0, 0)
			end
		else
			outputChatBox("ERROR: The PIN must consist of 4 digits only.", 255, 0, 0)
		end
	end
end)

addEventHandler("onClientUIComboBoxAccepted", root, function()
	if source == UI.combobox[1] then
		local sel = eui:uiComboBoxGetSelected(source)
		if sel ~= -1 then
			eui:uiSetText(UI.edit[1], tostring(eui:uiComboBoxGetItemText(source, sel)))
		end
	end
end)

addEventHandler("onClientPlayerWasted", localPlayer, closeAll)
