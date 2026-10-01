--[[ =========================================================================
	s_bank_admin.lua - staff bank inspection commands (Fix #160, agent A2)

		bank.showlog      -> /showbanklog    [account/character] [count]
		bank.showbalance  -> /showbankbalance [account/character]
		bank.showaccounts -> /nearbyatms      (already mapped in command_gates_s.lua)

	READ-ONLY: nothing here moves money, changes a balance or writes a row.
	It only reads
	  wiretransfers   - the transaction history (from/to/amount/reason/time/
	                    type/from_card/to_card/details),
	  bank_accounts   - the per-character (and per-faction) accounts the bank
	                    system is moving to - a character may end up with 2,
	  characters.bankmoney - the legacy per-character bank balance.

	The optional argument resolves in this order:
	  1. bank account code (the 7 digit code on the card)
	  2. numeric -> character id, then bank account row id
	  3. partial character name
	Bare /showbanklog lists the newest transfers server-wide; bare
	/showbankbalance shows your own character.
========================================================================= ]]

local mysql = exports.mysql

local function fix160BankTrim(s)
	s = tostring(s or "")
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fix160BankSyntax(player, cmd, args)
	outputChatBox("SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), player, 255, 194, 14)
end

-- Rank rights are the ONLY truth for ranked staff; the legacy integration
-- ladder decides for everyone else (the gate lets rank-less players through
-- on purpose, same rule as Fix #157). Uses the exported admin-system check.
local function fix160BankCheck(player, right)
	if not isElement(player) then return false end
	if getElementData(player, "rank:index") then
		local ok, has = pcall(function()
			return exports["admin-system"]:playerHasRight(player, right)
		end)
		if ok then
			if has then return true end
			outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
			return false
		end
		-- admin-system export unavailable -> fall through to the legacy ladder
	end
	if exports.integration:isPlayerTrialAdmin(player) then return true end
	outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
	return false
end

local function fix160BankLog(actor, data, affected)
	pcall(function()
		exports.logs:dbLog(actor, 4, affected or actor, data)
	end)
end

local function fix160Money(n)
	return exports.global:formatMoney(tonumber(n) or 0)
end

local FIX160_TX_TYPES = {
	[0] = "Withdraw (personal)",
	[1] = "Deposit (personal)",
	[2] = "Transfer P -> P/B",
	[3] = "Transfer B -> P/B",
	[4] = "Withdraw (business)",
	[5] = "Deposit (business)",
	[6] = "Wage / State benefits",
	[7] = "Payday",
	[8] = "Faction budget",
	[9] = "Fuel",
	[10] = "Repair",
}

local fix160FactionNames = {}

-- who is `from` / `to` on a wiretransfers row: a character (joined), a
-- faction (negative id) or the system (0)
local function fix160BankParty(row, side)
	local raw = tonumber(row[side])
	local charName = row[side == "from" and "characterfrom" or "characterto"]
	if charName and tostring(charName) ~= "" then
		local out = tostring(charName):gsub("_", " ")
		local card = row[side == "from" and "from_card" or "to_card"]
		if card and tostring(card) ~= "" then
			out = out .. " [" .. tostring(card) .. "]"
		end
		return out
	end
	if not raw or raw == 0 then return "System" end
	if raw < 0 then
		local fid = -raw
		local cached = fix160FactionNames[fid]
		if not cached then
			local f = mysql:query_fetch_assoc("SELECT name FROM factions WHERE id=" .. fid .. " LIMIT 1")
			cached = (f and f.name) or ("Faction #" .. fid)
			fix160FactionNames[fid] = cached
		end
		return tostring(cached)
	end
	return "Char #" .. raw
end

-- arg -> charID (number|nil), account row (table|nil), human label
local function fix160BankResolve(player, arg)
	arg = fix160BankTrim(arg)
	if arg == "" then
		local dbid = tonumber(getElementData(player, "character:id")
			or getElementData(player, "dbid"))
		if dbid then
			local row = mysql:query_fetch_assoc("SELECT id, charactername FROM characters WHERE id=" .. dbid)
			if row then
				return tonumber(row.id), nil,
					tostring(row.charactername):gsub("_", " ") .. " (#" .. tostring(row.id) .. ")"
			end
		end
		return nil, nil, nil
	end
	local esc = mysql:escape_string(arg)
	-- 1) bank account code
	local acc = mysql:query_fetch_assoc("SELECT * FROM bank_accounts WHERE LOWER(code)=LOWER('"
		.. esc .. "') LIMIT 1")
	-- 2) numeric: character id first, then bank account row id
	if not acc and arg:match("^%d+$") then
		local ch = mysql:query_fetch_assoc("SELECT id, charactername FROM characters WHERE id="
			.. tonumber(arg) .. " LIMIT 1")
		if ch then
			return tonumber(ch.id), nil,
				tostring(ch.charactername):gsub("_", " ") .. " (#" .. tostring(ch.id) .. ")"
		end
		acc = mysql:query_fetch_assoc("SELECT * FROM bank_accounts WHERE id="
			.. tonumber(arg) .. " LIMIT 1")
	end
	if acc then
		local ownerChar = (acc.ownerType == "char") and tonumber(acc.ownerID) or nil
		local who
		if acc.ownerType == "faction" then
			local fid = tonumber(acc.ownerID)
			who = fid and fix160BankParty({ from = -fid }, "from") or "Faction (unknown id)"
		else
			who = tostring(acc.ownerName or ""):gsub("_", " ")
			if who == "" then who = "Character #" .. tostring(acc.ownerID) end
		end
		return ownerChar, acc, "account " .. tostring(acc.code) .. " [" .. tostring(acc.ownerType)
			.. "] of " .. who
	end
	-- 3) partial character name
	local ch = mysql:query_fetch_assoc("SELECT id, charactername FROM characters"
		.. " WHERE LOWER(charactername) LIKE LOWER('%" .. esc .. "%') ORDER BY id ASC LIMIT 1")
	if ch then
		return tonumber(ch.id), nil,
			tostring(ch.charactername):gsub("_", " ") .. " (#" .. tostring(ch.id) .. ")"
	end
	return nil, nil, nil
end

-- ================================================================ showbanklog
addCommandHandler("showbanklog", function(player, cmd, target, countArg)
	if not fix160BankCheck(player, "bank.showlog") then return end

	local charID, acc, label
	local count = 10
	if target and fix160BankTrim(target) ~= "" then
		charID, acc, label = fix160BankResolve(player, target)
		if not charID and not acc then
			-- a lone number that matches nothing is a row count, not a target
			if not countArg and tonumber(target) then
				count = tonumber(target)
			else
				outputChatBox("No bank account or character matched '" .. fix160BankTrim(target)
					.. "'.", player, 255, 0, 0)
				outputChatBox("Give a bank account code, a character id or a partial name.",
					player, 170, 170, 170)
				return
			end
		end
	end
	if countArg then
		count = tonumber(countArg) or count
	end
	count = math.floor(count or 10)
	if count < 1 then count = 1 end
	if count > 50 then count = 50 end

	local where
	if acc and acc.ownerType == "char" and tonumber(acc.ownerID) then
		where = "(`from` = " .. tonumber(acc.ownerID) .. " OR `to` = " .. tonumber(acc.ownerID)
			.. " OR from_card = '" .. mysql:escape_string(tostring(acc.code))
			.. "' OR to_card = '" .. mysql:escape_string(tostring(acc.code)) .. "')"
	elseif acc and acc.ownerType == "faction" and tonumber(acc.ownerID) then
		local fid = -tonumber(acc.ownerID)
		where = "(`from` = " .. fid .. " OR `to` = " .. fid
			.. " OR from_card = '" .. mysql:escape_string(tostring(acc.code))
			.. "' OR to_card = '" .. mysql:escape_string(tostring(acc.code)) .. "')"
	elseif charID then
		where = "(`from` = " .. charID .. " OR `to` = " .. charID .. ")"
	end

	-- the same "-1 hour" correction the in-game transactions tab uses
	local sql = "SELECT w.id, w.`from`, w.`to`, w.amount, w.reason, w.time, w.type,"
		.. " w.from_card, w.to_card, w.details,"
		.. " w.`time` - INTERVAL 1 hour AS newtime,"
		.. " c.charactername AS characterfrom, c2.charactername AS characterto"
		.. " FROM wiretransfers w"
		.. " LEFT JOIN characters c ON c.id = w.`from`"
		.. " LEFT JOIN characters c2 ON c2.id = w.`to`"
		.. (where and (" WHERE " .. where) or "")
		.. " ORDER BY w.id DESC LIMIT " .. count

	local q = mysql:query(sql)
	if not q then
		outputChatBox("Transaction query failed.", player, 255, 0, 0)
		return
	end

	outputChatBox("========== BANK LOG: " .. (label or "ALL ACCOUNTS (server-wide)")
		.. " - last " .. count .. " ==========", player, 60, 200, 120)
	if acc then
		outputChatBox("  account " .. tostring(acc.code) .. "  balance $"
			.. fix160Money(acc.balance) .. "  owner: " .. tostring(acc.ownerType) .. " #"
			.. tostring(acc.ownerID), player, 190, 190, 190)
	end
	local shown = 0
	while true do
		local row = mysql:fetch_assoc(q)
		if not row then break end
		shown = shown + 1
		local ttype = tonumber(row.type) or 0
		local reason = tostring(row.reason or "")
		if reason == "" then reason = "-" end
		if #reason > 48 then reason = reason:sub(1, 45) .. "..." end
		outputChatBox("#" .. tostring(row.id) .. "  " .. tostring(row.newtime or row.time or "?")
			.. "  " .. fix160BankParty(row, "from") .. " -> " .. fix160BankParty(row, "to")
			.. "  $" .. fix160Money(row.amount), player, 220, 220, 220)
		outputChatBox("      " .. (FIX160_TX_TYPES[ttype] or ("type " .. ttype))
			.. "  |  " .. reason
			.. ((row.details and tostring(row.details) ~= "")
				and ("  |  " .. tostring(row.details):sub(1, 40)) or ""),
			player, 190, 190, 190)
	end
	mysql:free_result(q)
	if shown == 0 then
		outputChatBox("  no transactions on record for that scope.", player, 255, 194, 14)
	end
	fix160BankLog(player, "SHOWBANKLOG " .. (label or "server-wide") .. " rows " .. shown, player)
end, false, false)

-- ============================================================ showbankbalance
addCommandHandler("showbankbalance", function(player, cmd, target)
	if not fix160BankCheck(player, "bank.showbalance") then return end

	local charID, acc, label
	if target and fix160BankTrim(target) ~= "" then
		charID, acc, label = fix160BankResolve(player, target)
		if not charID and not acc then
			outputChatBox("No bank account or character matched '" .. fix160BankTrim(target)
				.. "'.", player, 255, 0, 0)
			return
		end
	else
		charID, acc, label = fix160BankResolve(player, "")
		if not charID and not acc then
			fix160BankSyntax(player, cmd, "[Bank Account Code / Character ID / Partial Name]")
			return
		end
	end

	outputChatBox("========== BANK BALANCE: " .. tostring(label) .. " ==========",
		player, 60, 200, 120)

	if charID then
		local row = mysql:query_fetch_assoc("SELECT charactername, bankmoney FROM characters WHERE id="
			.. charID .. " LIMIT 1")
		if row then
			outputChatBox("  characters.bankmoney (#" .. charID .. ", "
				.. tostring(row.charactername):gsub("_", " ") .. "): $"
				.. fix160Money(row.bankmoney), player, 220, 220, 220)
		end
	end

	local q = mysql:query("SELECT id, code, ownerType, ownerID, ownerName, balance, created"
		.. " FROM bank_accounts"
		.. (charID and (" WHERE ownerType='char' AND ownerID=" .. charID) or " WHERE 1=0")
		.. " ORDER BY id ASC")
	local shown = 0
	if q then
		while true do
			local a = mysql:fetch_assoc(q)
			if not a then break end
			shown = shown + 1
			outputChatBox("  account " .. tostring(a.code) .. " (#" .. tostring(a.id) .. ") ["
				.. tostring(a.ownerType) .. "]  balance: $" .. fix160Money(a.balance)
				.. "  created " .. tostring(a.created or "-"), player, 220, 220, 220)
		end
		mysql:free_result(q)
	end
	-- the argument may be an account whose owner is not a character
	if acc and acc.ownerType ~= "char" then
		shown = shown + 1
		outputChatBox("  account " .. tostring(acc.code) .. " (#" .. tostring(acc.id) .. ") ["
			.. tostring(acc.ownerType) .. " #" .. tostring(acc.ownerID) .. "]  balance: $"
			.. fix160Money(acc.balance) .. "  created " .. tostring(acc.created or "-"),
			player, 220, 220, 220)
	end
	if shown == 0 then
		outputChatBox("  no bank_accounts row yet (the character still banks through "
			.. "characters.bankmoney only).", player, 255, 194, 14)
	else
		outputChatBox("  " .. shown .. " account(s) on bank_accounts.", player, 170, 170, 170)
	end
	fix160BankLog(player, "SHOWBANKBALANCE " .. tostring(label), player)
end, false, false)
