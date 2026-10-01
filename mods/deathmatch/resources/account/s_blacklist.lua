-- [Fix #160] server-wide blacklist: account + serial + IP + email + device.
-- Enforcement points (all inside this resource):
--   s_login.lua            clientReady()   -> join gate (10 sec kick)
--   login-panel/server.lua playerLogin()   -> login gate (warning box)
--   login-panel/server.lua playerRegister() -> registration gate (warning box)
-- Commands (rights blacklist.add / blacklist.remove, gated by
-- admin-system/staff_manager/gates_fix160_task1.lua):
--   /blacklistadd <account> [reason]
--   /blacklistremove <account>
local mysql = exports.mysql

local BL_COLUMNS = "id, account, account_id, serial, ip, iprange, email, device, reason, addedby, date"

-- [Fix #160] the DDL - CREATE TABLE IF NOT EXISTS, so it is idempotent
local BL_CREATE_SQL = [[
CREATE TABLE IF NOT EXISTS `blacklist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` varchar(64) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  `serial` varchar(32) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `iprange` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `device` varchar(64) DEFAULT NULL,
  `reason` text,
  `addedby` varchar(64) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `bl_account` (`account`),
  KEY `bl_serial` (`serial`),
  KEY `bl_ip` (`ip`),
  KEY `bl_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
]]

local BL_FIELD_LABELS = {
	account = "الحساب",
	email = "البريد الإلكتروني",
	serial = "السيريال",
	device = "الجهاز",
	ip = "الآي بي",
	iprange = "نطاق الآي بي",
}

local tableOk = false
local cache = nil

local function trim(s)
	s = tostring(s or "")
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function esc(s)
	return mysql:escape_string(s)
end

-- [Fix #160] "1.2.3.4" -> "1.2.3" (the /24 the evader keeps getting a new
-- IP from); IPv6 has no range check, the exact IP still applies.
local function ipRange(ip)
	local a, b, c = trim(ip):match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
	if not a then return nil end
	return a .. "." .. b .. "." .. c
end

local function out(player, text, r, g, b)
	if isElement(player) then
		outputChatBox(text, player, r or 255, g or 255, b or 255)
	end
end

local function blLog(actor, data, affected)
	pcall(function()
		exports.logs:dbLog(actor, 4, affected or actor, data)
	end)
end

-- [Fix #160] CREATE TABLE IF NOT EXISTS, run lazily + once on resource start
local function ensureTable()
	if tableOk then return true end
	local ok, res = pcall(function()
		return mysql:query_free(BL_CREATE_SQL)
	end)
	tableOk = (ok and res) and true or false
	if not tableOk then
		outputDebugString("[blacklist] could not create the blacklist table: " .. tostring(res), 2)
	end
	return tableOk
end

-- [Fix #160] cache: blacklist + the legacy bannedips/bannedserials mirrors in
-- ONE list, so a legacy serial ban also stops a brand new registration.
function blacklistReload()
	local loaded = nil
	local ok, err = pcall(function()
		ensureTable()
		local rows = {}
		local q = mysql:query("SELECT " .. BL_COLUMNS .. " FROM blacklist")
		if q then
			while true do
				local row = mysql:fetch_assoc(q)
				if not row then break end
				row.source = "blacklist"
				rows[#rows + 1] = row
			end
			mysql:free_result(q)
		end
		local qi = mysql:query("SELECT ip, reason, account FROM bannedips")
		if qi then
			while true do
				local row = mysql:fetch_assoc(qi)
				if not row then break end
				rows[#rows + 1] = {
					source = "bannedips",
					ip = tostring(row.ip or ""),
					reason = tostring(row.reason or ""),
					account_id = row.account,
				}
			end
			mysql:free_result(qi)
		end
		local qs = mysql:query("SELECT serial, reason, account FROM bannedserials")
		if qs then
			while true do
				local row = mysql:fetch_assoc(qs)
				if not row then break end
				rows[#rows + 1] = {
					source = "bannedserials",
					serial = tostring(row.serial or ""),
					reason = tostring(row.reason or ""),
					account_id = row.account,
				}
			end
			mysql:free_result(qs)
		end
		loaded = rows
	end)
	if not ok then
		outputDebugString("[blacklist] reload failed (fail-open): " .. tostring(err), 2)
		cache = nil
		return false
	end
	cache = loaded or {}
	return true
end

-- [Fix #160] returns the first blacklist row that matches ANY identity
function blacklistFind(username, email, serial, ip)
	if not cache then blacklistReload() end
	local rows = cache or {}
	local u = trim(username):lower()
	local e = trim(email):lower()
	local s = trim(serial):upper()
	local i = trim(ip)
	local r = ipRange(i)
	for _, row in ipairs(rows) do
		if u ~= "" and trim(row.account):lower() == u then
			return row, "account"
		end
		if e ~= "" and trim(row.email):lower() == e then
			return row, "email"
		end
		if s ~= "" then
			if trim(row.serial):upper() == s then return row, "serial" end
			if trim(row.device):upper() == s then return row, "device" end
		end
		if i ~= "" then
			if trim(row.ip) == i then return row, "ip" end
			if trim(row.device) == i then return row, "device" end
		end
		if r ~= nil and trim(row.iprange) ~= "" and trim(row.iprange) == r then
			return row, "iprange"
		end
	end
	return nil
end

-- [Fix #160] join gate: only the serial + IP are known before the login panel
function blacklistCheckJoin(thePlayer)
	if not isElement(thePlayer) then return nil end
	return blacklistFind(nil, nil, getPlayerSerial(thePlayer), getPlayerIP(thePlayer))
end

-- [Fix #160] login gate: the account row brings its stored email into the match
function blacklistCheckLogin(thePlayer, username)
	if not isElement(thePlayer) then return nil end
	local email = ""
	local row = mysql:query_fetch_assoc("SELECT email FROM accounts WHERE LOWER(username)=LOWER('"
		.. mysql:escape_string(trim(username)) .. "') LIMIT 1")
	if row and row.email then email = tostring(row.email) end
	return blacklistFind(username, email, getPlayerSerial(thePlayer), getPlayerIP(thePlayer))
end

-- [Fix #160] registration gate: blocks the "new account" evasion path
function blacklistCheckRegister(thePlayer, username, email)
	if not isElement(thePlayer) then return nil end
	return blacklistFind(username, email, getPlayerSerial(thePlayer), getPlayerIP(thePlayer))
end

-- [Fix #160] Arabic kick/warning line naming the reason + the matched field
function blacklistMessage(row, field, stage)
	if not row then return "" end
	local reason = trim(row.reason)
	if reason == "" then reason = "غير محددة" end
	local label = BL_FIELD_LABELS[field] or tostring(field or "")
	local value = trim(row[field])
	if value == "" then value = "-" end
	return "لا يمكن " .. tostring(stage) .. " - السبب: " .. reason .. " (" .. label .. ": " .. value .. ")"
end

-- [Fix #160] right checks - the gate in command_gates_s.lua does the main
-- enforcement; this is the defensive layer (same ladder as the Fix #157
-- handlers).
local function blAllowed(player, command, right)
	if not isElement(player) or getElementType(player) ~= "player" then return false end
	local ranked = getElementData(player, "rank:index") and true or false
	local ok, allowed = pcall(function()
		return exports["admin-system"]:hasCommandRight(player, command)
	end)
	if ok and ranked then return allowed and true or false end
	-- [Fix #160] no Vortex rank (or the gate export is down): legacy ladder,
	-- and the blacklist tools sit at the lead-admin tier.
	local ok2, lead = pcall(function()
		return exports.integration:isPlayerLeadAdmin(player)
	end)
	return (ok2 and lead) and true or false
end

local function blCheck(player, command, right)
	if blAllowed(player, command, right) then return true end
	out(player, "You don't have permission to use this command.", 255, 0, 0)
	return false
end

local function blSyntax(player, cmd, args)
	out(player, "SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), 255, 194, 14)
end

-- [Fix #160] resolve an account from: numeric id -> username -> online nick
local function blResolveAccount(query)
	local q = trim(query)
	if q == "" then return nil, nil end
	local cols = "id, username, email, ip, mtaserial"
	local escQ = mysql:escape_string(q)
	local row
	if q:match("^%d+$") then
		row = mysql:query_fetch_assoc("SELECT " .. cols .. " FROM accounts WHERE id=" .. tonumber(q) .. " LIMIT 1")
	end
	if not row then
		row = mysql:query_fetch_assoc("SELECT " .. cols .. " FROM accounts WHERE LOWER(username)=LOWER('"
			.. escQ .. "') LIMIT 1")
	end
	if not row then
		local ok, target = pcall(function()
			-- [Fix #160] third arg = quiet: no "No such player found." spam
			return exports.global:findPlayerByPartialNick(nil, q, true)
		end)
		if ok and isElement(target) and getElementType(target) == "player" then
			local aid = tonumber(getElementData(target, "account:id"))
			if aid then
				row = mysql:query_fetch_assoc("SELECT " .. cols .. " FROM accounts WHERE id=" .. aid .. " LIMIT 1")
			end
		end
	end
	if not row then return nil, nil end
	local online = nil
	for _, p in ipairs(getElementsByType("player")) do
		if tonumber(getElementData(p, "account:id")) == tonumber(row.id) then
			online = p
			break
		end
	end
	return row, online
end

-- [Fix #160] /blacklistadd <account> [reason] -> right blacklist.add
addCommandHandler("blacklistadd", function(player, cmd, target, ...)
	if not blCheck(player, "blacklistadd", "blacklist.add") then return end
	target = trim(target)
	if target == "" then
		blSyntax(player, cmd, "[Account Username / ID / Player] [Reason]")
		return
	end
	local reason = trim(table.concat({ ... }, " "))
	if reason == "" then reason = "No reason given" end
	if #reason > 200 then reason = reason:sub(1, 200) end
	local acc, online = blResolveAccount(target)
	if not acc then
		out(player, "Account not found: " .. target, 255, 0, 0)
		return
	end
	ensureTable()
	local existing = mysql:query_fetch_assoc("SELECT id FROM blacklist WHERE LOWER(account)=LOWER('"
		.. esc(tostring(acc.username)) .. "') LIMIT 1")
	if existing then
		out(player, "Already blacklisted: " .. tostring(acc.username) .. " (row #" .. tostring(existing.id) .. ").",
			255, 194, 14)
		return
	end
	local serial = ""
	local ip = ""
	if online then
		serial = trim(getPlayerSerial(online))
		ip = trim(getPlayerIP(online))
	end
	if serial == "" then serial = trim(acc.mtaserial) end
	if ip == "" then ip = trim(acc.ip) end
	local email = trim(acc.email)
	-- [Fix #160] MTA only fingerprints the machine through the serial, so the
	-- device column carries it (falls back to the IP when there is no serial)
	local device = (serial ~= "") and serial or ip
	local addedBy = getElementData(player, "account:username") or getPlayerName(player) or "?"
	local adminID = tonumber(getElementData(player, "account:id")) or 0
	local rowID = mysql:query_insert_free("INSERT INTO blacklist (account, account_id, serial, ip, iprange,"
		.. " email, device, reason, addedby, date) VALUES ('" .. esc(tostring(acc.username)) .. "', "
		.. tonumber(acc.id) .. ", '" .. esc(serial) .. "', '" .. esc(ip) .. "', '" .. esc(ipRange(ip) or "")
		.. "', '" .. esc(email) .. "', '" .. esc(device) .. "', '" .. esc(reason) .. "', '" .. esc(tostring(addedBy))
		.. "', NOW())")
	if not rowID then
		out(player, "Database error - the blacklist entry was NOT saved.", 255, 0, 0)
		return
	end
	-- [Fix #160] mirror into the legacy tables so global's fetchIPs/
	-- fetchSerials caches (and every other consumer) cover it too
	if ip ~= "" and not mysql:query_fetch_assoc("SELECT id FROM bannedips WHERE ip='" .. esc(ip) .. "' LIMIT 1") then
		mysql:query_free("INSERT INTO bannedips (ip, serial, account, admin, reason, date) VALUES ('"
			.. esc(ip) .. "', '', " .. tonumber(acc.id) .. ", " .. adminID .. ", '[blacklist] "
			.. esc(reason) .. "', NOW())")
	end
	if serial ~= "" and not mysql:query_fetch_assoc("SELECT id FROM bannedserials WHERE serial='" .. esc(serial)
		.. "' LIMIT 1") then
		mysql:query_free("INSERT INTO bannedserials (serial, ip, account, admin, reason, date) VALUES ('"
			.. esc(serial) .. "', '', " .. tonumber(acc.id) .. ", " .. adminID .. ", '[blacklist] "
			.. esc(reason) .. "', NOW())")
	end
	pcall(function() exports.global:updateBans() end)
	blacklistReload()
	out(player, "BLACKLIST: added '" .. tostring(acc.username) .. "' (#" .. tostring(acc.id) .. ") row #" .. tostring(rowID) .. ".", 0, 255, 0)
	out(player, "تمت إضافة '" .. tostring(acc.username) .. "' إلى القائمة السوداء (السبب: " .. reason .. ").", 0, 255, 0)
	if serial ~= "" then out(player, "  serial: " .. serial, 200, 200, 200) end
	if ip ~= "" then out(player, "  ip: " .. ip .. "  (range " .. (ipRange(ip) or "-") .. ")", 200, 200, 200) end
	if email ~= "" then out(player, "  email: " .. email, 200, 200, 200) end
	if online and online ~= player then
		out(online, "تمت إضافتك إلى القائمة السوداء في هذا السيرفر.", 255, 0, 0)
		out(online, blacklistMessage({ reason = reason, account = acc.username }, "account", "الدخول إلى السيرفر"), 255, 0, 0)
		setTimer(function(pl)
			if isElement(pl) then
				kickPlayer(pl, "You are blacklisted from this server.")
			end
		end, 3000, 1, online)
	end
	blLog(player, "BLACKLISTADD " .. tostring(acc.username) .. " (#" .. tostring(acc.id) .. ") serial: "
		.. (serial ~= "" and serial or "-") .. " ip: " .. (ip ~= "" and ip or "-") .. " email: "
		.. (email ~= "" and email or "-") .. " reason: " .. reason, "account#" .. tostring(acc.id))
end, false, false)

-- [Fix #160] /blacklistremove <account> -> right blacklist.remove
addCommandHandler("blacklistremove", function(player, cmd, target)
	if not blCheck(player, "blacklistremove", "blacklist.remove") then return end
	target = trim(target)
	if target == "" then
		blSyntax(player, cmd, "[Account Username / ID / Player / Blacklist Row #]")
		return
	end
	ensureTable()
	local acc = blResolveAccount(target)
	local where
	if acc then
		where = "(account_id=" .. tonumber(acc.id) .. " OR LOWER(account)=LOWER('" .. esc(tostring(acc.username)) .. "'))"
	elseif target:match("^%d+$") then
		where = "id=" .. tonumber(target)
	end
	if not where then
		out(player, "No blacklist entry found for: " .. target, 255, 194, 14)
		return
	end
	local removed = {}
	local q = mysql:query("SELECT " .. BL_COLUMNS .. " FROM blacklist WHERE " .. where)
	if q then
		while true do
			local row = mysql:fetch_assoc(q)
			if not row then break end
			removed[#removed + 1] = row
		end
		mysql:free_result(q)
	end
	if #removed == 0 then
		out(player, "No blacklist entry found for: " .. target, 255, 194, 14)
		return
	end
	for _, row in ipairs(removed) do
		mysql:query_free("DELETE FROM blacklist WHERE id=" .. tonumber(row.id))
		-- [Fix #160] drop OUR legacy mirror rows, but only while no other
		-- blacklist entry still uses the same serial / IP
		local rip = trim(row.ip)
		if rip ~= "" and not mysql:query_fetch_assoc("SELECT id FROM blacklist WHERE ip='" .. esc(rip) .. "' LIMIT 1") then
			mysql:query_free("DELETE FROM bannedips WHERE ip='" .. esc(rip) .. "' AND reason LIKE '[blacklist]%'")
		end
		local rserial = trim(row.serial)
		if rserial ~= "" and not mysql:query_fetch_assoc("SELECT id FROM blacklist WHERE serial='" .. esc(rserial)
			.. "' LIMIT 1") then
			mysql:query_free("DELETE FROM bannedserials WHERE serial='" .. esc(rserial)
				.. "' AND reason LIKE '[blacklist]%'")
		end
	end
	pcall(function() exports.global:updateBans() end)
	blacklistReload()
	local name = acc and tostring(acc.username) or ("row #" .. tostring(removed[1].id))
	out(player, "BLACKLIST: removed " .. #removed .. " entry(ies) for '" .. name .. "'.", 0, 255, 0)
	out(player, "تم حذف '" .. name .. "' من القائمة السوداء، يمكنه الدخول مرة أخرى.", 0, 255, 0)
	blLog(player, "BLACKLISTREMOVE " .. name .. " (" .. #removed .. " row(s))", "account#"
		.. tostring(acc and acc.id or removed[1].account_id or 0))
end, false, false)

-- [Fix #160] build the table + load the cache as soon as this resource starts
addEventHandler("onResourceStart", resourceRoot, function()
	ensureTable()
	blacklistReload()
end)
