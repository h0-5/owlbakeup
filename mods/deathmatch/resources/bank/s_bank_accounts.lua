--[[ =========================================================================
	s_bank_accounts.lua — Vortex BANK ACCOUNTS (Fix #38, MOD 2 part 2)

	1:1 port of the OLD CLIENT bank protocol (backupm bank-system):
	  ATM:checkPassword (code, pin)          -> login, answers ATM:openAccount
	  ATM:createAccount (pin)                -> $1000 setup fee, unique code
	  ATM:depositAmount (code, amount)       -> cash -> account
	  ATM:withdrawAmount (code, amount)      -> account -> cash
	  ATM:transferAmount (code, toCode, amt) -> account -> account
	  bank:changePIN (code, newPin)
	  bank:get_accounts                      -> your codes (+ faction accounts
	                                            for faction leaders, so the
	                                            factions/characters both bank)

	SECURITY: every op re-validates server side (PIN hash, ownership, leader
	rights, integer amounts > 0, balance checks). PINs stored as md5. Every
	action writes wiretransfers (compat with the existing transactions tab)
	AND exports.logs:dbLog.
========================================================================= ]]

local mysql = exports.mysql

local ACCOUNT_SETUP_FEE = 1000
local MIN_TRANSFER = 1

function ensureBankAccountTables()
	mysql:query_free([[CREATE TABLE IF NOT EXISTS bank_accounts (
		id INT NOT NULL AUTO_INCREMENT,
		code VARCHAR(16) NOT NULL UNIQUE,
		ownerType VARCHAR(8) NOT NULL DEFAULT 'char',
		ownerID INT NOT NULL,
		ownerName VARCHAR(64) NOT NULL DEFAULT '',
		pin VARCHAR(64) NOT NULL DEFAULT '',
		balance BIGINT NOT NULL DEFAULT 0,
		created DATETIME DEFAULT NOW(),
		PRIMARY KEY (id))]])
end

addEventHandler("onResourceStart", getResourceRootElement(), ensureBankAccountTables)

local function generateCode()
	-- 7-digit unique code, retried until free
	for _ = 1, 20 do
		local code = tostring(math.random(1000000, 9999999))
		local row = mysql:query_fetch_assoc("SELECT id FROM bank_accounts WHERE code='" .. code .. "' LIMIT 1")
		if not row then return code end
	end
	return nil
end

local function fetchAccount(code)
	if not code then return nil end
	return mysql:query_fetch_assoc("SELECT * FROM bank_accounts WHERE code='"
		.. mysql:escape_string(tostring(code)) .. "' LIMIT 1")
end

local function accountOwnerName(acc)
	if acc.ownerType == "faction" then
		local team = getPlayerTeam(client)
		if team and tonumber(getElementData(team, "id")) == tonumber(acc.ownerID) then
			return getTeamName(team)
		end
		local row = mysql:query_fetch_assoc("SELECT name FROM factions WHERE id=" .. tonumber(acc.ownerID) .. " LIMIT 1")
		return row and row.name or "Faction #" .. tostring(acc.ownerID)
	end
	return acc.ownerName ~= "" and acc.ownerName or ("Character #" .. tostring(acc.ownerID))
end

local function canOperate(acc)
	-- ownership re-check on EVERY operation (client is never trusted)
	if acc.ownerType == "char" then
		return tonumber(acc.ownerID) == tonumber(getElementData(client, "character:id")
			or getElementData(client, "dbid") or -1)
	elseif acc.ownerType == "faction" then
		return tonumber(getElementData(client, "factionleader")) == 1
			and tonumber(getElementData(client, "faction")) == tonumber(acc.ownerID)
	end
	return false
end

local function normalizeAmount(amount)
	amount = tonumber(amount)
	if not amount or math.floor(amount) ~= amount or amount < 1 then return nil end
	return amount
end

local function logTransfer(fromChar, toChar, amount, tType, reason)
	mysql:query_free("INSERT INTO wiretransfers (`from`, `to`, `amount`, `reason`, `type`) VALUES ("
		.. tonumber(fromChar or 0) .. ", " .. tonumber(toChar or 0) .. ", "
		.. tonumber(amount or 0) .. ", '" .. mysql:escape_string(tostring(reason or "")) .. "', "
		.. tonumber(tType or 0) .. ")")
end

-- ---------------------------------------------------------------- login ----
addEvent("ATM:checkPassword", true)
addEventHandler("ATM:checkPassword", root, function(code, pin)
	if not client or client ~= source then return end
	local acc = fetchAccount(code)
	if not acc then
		outputChatBox("Error: account not found.", client, 255, 0, 0)
		return
	end
	if acc.pin ~= md5(tostring(pin)) then
		outputChatBox("Error: wrong PIN.", client, 255, 0, 0)
		return
	end
	if not canOperate(acc) then
		outputChatBox("Error: this account is not yours.", client, 255, 0, 0)
		return
	end
	triggerClientEvent(client, "ATM:openAccount", client, tostring(acc.code), accountOwnerName(acc), tonumber(acc.balance) or 0)
	exports.logs:dbLog(client, 25, client, "BANK LOGIN " .. tostring(acc.code))
end)

-- -------------------------------------------------------------- create ----
addEvent("ATM:createAccount", true)
addEventHandler("ATM:createAccount", root, function(pin)
	if not client or client ~= source then return end
	if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
	pin = tostring(pin or "")
	if not pin:match("^%d%d%d%d$") then
		outputChatBox("Error: PIN must be exactly 4 digits.", client, 255, 0, 0)
		return
	end
	local charID = tonumber(getElementData(client, "character:id") or getElementData(client, "dbid"))
	if not charID then return end
	-- one personal account per character (old client behaviour)
	local row = mysql:query_fetch_assoc("SELECT id FROM bank_accounts WHERE ownerType='char' AND ownerID="
		.. charID .. " LIMIT 1")
	if row then
		outputChatBox("Error: you already own a bank account.", client, 255, 0, 0)
		return
	end
	if not exports.global:takeMoney(client, ACCOUNT_SETUP_FEE) then
		outputChatBox("Error: you need $" .. ACCOUNT_SETUP_FEE .. " to set up the account.", client, 255, 0, 0)
		return
	end
	local code = generateCode()
	if not code then
		exports.global:giveMoney(client, ACCOUNT_SETUP_FEE)
		outputChatBox("Error: could not allocate an account code, try again.", client, 255, 0, 0)
		return
	end
	local name = tostring(getElementData(client, "character:name") or ""):gsub("_", " ")
	mysql:query_free("INSERT INTO bank_accounts (code, ownerType, ownerID, ownerName, pin, balance) VALUES ('"
		.. code .. "', 'char', " .. charID .. ", '" .. mysql:escape_string(name) .. "', '"
		.. md5(pin) .. "', 0)")
	outputChatBox("Bank account created! Your account code is " .. code .. " - write it down.", client, 0, 255, 120)
	exports.logs:dbLog(client, 25, client, "BANK CREATE " .. code .. " fee $" .. ACCOUNT_SETUP_FEE)
	logTransfer(charID, 0, ACCOUNT_SETUP_FEE, 0, "Account setup fee " .. code)
	triggerClientEvent(client, "bank:accountsRefresh", client)
end)

-- ------------------------------------------------------------- deposit ----
addEvent("ATM:depositAmount", true)
addEventHandler("ATM:depositAmount", root, function(code, amount)
	if not client or client ~= source then return end
	amount = normalizeAmount(amount)
	if not amount then return end
	local acc = fetchAccount(code)
	if not acc or not canOperate(acc) then
		outputChatBox("Error: this account is not yours.", client, 255, 0, 0)
		return
	end
	if not exports.global:takeMoney(client, amount) then
		outputChatBox("Error: you don't have that much cash.", client, 255, 0, 0)
		return
	end
	local newBalance = (tonumber(acc.balance) or 0) + amount
	mysql:query_free("UPDATE bank_accounts SET balance=" .. newBalance .. " WHERE id=" .. tonumber(acc.id))
	logTransfer(tonumber(getElementData(client, "character:id") or getElementData(client, "dbid")), 0, amount, 0, "Deposit " .. tostring(acc.code))
	exports.logs:dbLog(client, 25, client, "BANK DEPOSIT " .. tostring(acc.code) .. " $" .. amount)
	triggerClientEvent(client, "ATM:updateBalance", client, newBalance, accountOwnerName(acc))
	outputChatBox("Deposited $" .. exports.global:formatMoney(amount) .. ".", client, 0, 255, 120)
end)

-- ------------------------------------------------------------ withdraw ----
addEvent("ATM:withdrawAmount", true)
addEventHandler("ATM:withdrawAmount", root, function(code, amount)
	if not client or client ~= source then return end
	amount = normalizeAmount(amount)
	if not amount then return end
	local acc = fetchAccount(code)
	if not acc or not canOperate(acc) then
		outputChatBox("Error: this account is not yours.", client, 255, 0, 0)
		return
	end
	local newBalance = (tonumber(acc.balance) or 0) - amount
	if newBalance < 0 then
		outputChatBox("Error: insufficient balance.", client, 255, 0, 0)
		return
	end
	mysql:query_free("UPDATE bank_accounts SET balance=" .. newBalance .. " WHERE id=" .. tonumber(acc.id))
	exports.global:giveMoney(client, amount)
	logTransfer(0, tonumber(getElementData(client, "character:id") or getElementData(client, "dbid")), amount, 0, "Withdraw " .. tostring(acc.code))
	exports.logs:dbLog(client, 25, client, "BANK WITHDRAW " .. tostring(acc.code) .. " $" .. amount)
	triggerClientEvent(client, "ATM:updateBalance", client, newBalance, accountOwnerName(acc))
	outputChatBox("Withdrew $" .. exports.global:formatMoney(amount) .. ".", client, 0, 255, 120)
end)

-- ------------------------------------------------------------- transfer ----
addEvent("ATM:transferAmount", true)
addEventHandler("ATM:transferAmount", root, function(code, toCode, amount)
	if not client or client ~= source then return end
	amount = normalizeAmount(amount)
	if not amount then return end
	local acc = fetchAccount(code)
	if not acc or not canOperate(acc) then
		outputChatBox("Error: this account is not yours.", client, 255, 0, 0)
		return
	end
	local target = fetchAccount(toCode)
	if not target then
		outputChatBox("Error: target account not found.", client, 255, 0, 0)
		return
	end
	if tostring(target.code) == tostring(acc.code) then
		outputChatBox("Error: you can't transfer to the same account.", client, 255, 0, 0)
		return
	end
	local newBalance = (tonumber(acc.balance) or 0) - amount
	if newBalance < 0 then
		outputChatBox("Error: insufficient balance.", client, 255, 0, 0)
		return
	end
	local targetBalance = (tonumber(target.balance) or 0) + amount
	mysql:query_free("UPDATE bank_accounts SET balance=" .. newBalance .. " WHERE id=" .. tonumber(acc.id))
	mysql:query_free("UPDATE bank_accounts SET balance=" .. targetBalance .. " WHERE id=" .. tonumber(target.id))
	local fromID = tonumber(getElementData(client, "character:id") or getElementData(client, "dbid")) or 0
	logTransfer(fromID, tonumber(target.ownerID), amount, 0, "Transfer " .. tostring(acc.code) .. " -> " .. tostring(target.code))
	exports.logs:dbLog(client, 25, client, "BANK TRANSFER " .. tostring(acc.code) .. " -> " .. tostring(target.code) .. " $" .. amount)
	triggerClientEvent(client, "ATM:updateBalance", client, newBalance, accountOwnerName(acc))
	outputChatBox("Transferred $" .. exports.global:formatMoney(amount) .. " to account " .. tostring(target.code) .. ".", client, 0, 255, 120)
end)

-- ----------------------------------------------------------------- pin ----
addEvent("bank:changePIN", true)
addEventHandler("bank:changePIN", root, function(code, newPin)
	if not client or client ~= source then return end
	newPin = tostring(newPin or "")
	if not newPin:match("^%d%d%d%d$") then
		outputChatBox("ERROR: The PIN must consist of 4 digits only.", client, 255, 0, 0)
		return
	end
	local acc = fetchAccount(code)
	if not acc or not canOperate(acc) then
		outputChatBox("Error: this account is not yours.", client, 255, 0, 0)
		return
	end
	mysql:query_free("UPDATE bank_accounts SET pin='" .. md5(newPin) .. "' WHERE id=" .. tonumber(acc.id))
	outputChatBox("PIN changed for account " .. tostring(acc.code) .. ".", client, 0, 255, 120)
	exports.logs:dbLog(client, 25, client, "BANK PIN CHANGE " .. tostring(acc.code))
end)

-- ------------------------------------------------------------- listing ----
-- codes for the "Your accounts" combobox: personal + faction (leaders only)
addEvent("bank:get_accounts", true)
addEventHandler("bank:get_accounts", root, function()
	if not client or client ~= source then return end
	local out = {}
	local charID = tonumber(getElementData(client, "character:id") or getElementData(client, "dbid"))
	if charID then
		local q = mysql:query("SELECT code FROM bank_accounts WHERE ownerType='char' AND ownerID=" .. charID)
		if q then
			while true do
				local row = mysql:fetch_assoc(q)
				if not row then break end
				out[#out + 1] = tostring(row.code)
			end
			mysql:free_result(q)
		end
	end
	if tonumber(getElementData(client, "factionleader")) == 1 and tonumber(getElementData(client, "faction") or 0) > 0 then
		local q = mysql:query("SELECT code FROM bank_accounts WHERE ownerType='faction' AND ownerID="
			.. tonumber(getElementData(client, "faction")))
		if q then
			while true do
				local row = mysql:fetch_assoc(q)
				if not row then break end
				out[#out + 1] = tostring(row.code)
			end
			mysql:free_result(q)
		end
	end
	triggerClientEvent(client, "bank:get_accounts:callback", client, out)
end)

-- faction account bootstrap: every faction gets one on demand (leaders only)
addEvent("bank:createFactionAccount", true)
addEventHandler("bank:createFactionAccount", root, function()
	if not client or client ~= source then return end
	if tonumber(getElementData(client, "factionleader")) ~= 1 then
		outputChatBox("Error: only the faction leader can create the faction account.", client, 255, 0, 0)
		return
	end
	local factionID = tonumber(getElementData(client, "faction"))
	if not factionID or factionID <= 0 then return end
	local row = mysql:query_fetch_assoc("SELECT id FROM bank_accounts WHERE ownerType='faction' AND ownerID="
		.. factionID .. " LIMIT 1")
	if row then
		outputChatBox("Your faction already has a bank account.", client, 255, 0, 0)
		return
	end
	local code = generateCode()
	if not code then return end
	local team = getPlayerTeam(client)
	local fname = team and getTeamName(team) or ("Faction #" .. factionID)
	mysql:query_free("INSERT INTO bank_accounts (code, ownerType, ownerID, ownerName, pin, balance) VALUES ('"
		.. code .. "', 'faction', " .. factionID .. ", '" .. mysql:escape_string(fname) .. "', '', 0)")
	outputChatBox("Faction bank account created! Code: " .. code .. " (operated by leaders, no PIN).", client, 0, 255, 120)
	exports.logs:dbLog(client, 25, client, "BANK FACTION CREATE " .. code)
	triggerClientEvent(client, "bank:accountsRefresh", client)
end)
