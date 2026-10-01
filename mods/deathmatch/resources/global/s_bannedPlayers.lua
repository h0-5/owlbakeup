-- [Fix #160] banned IP/serial caches consumed by account/s_login.lua
-- (fetchIPs / fetchSerials) and refreshed by /blacklistadd /blacklistremove.
local IPs = { }

local serials = { }

function fillBans(res)
	if res ~= getThisResource() then return end
	-- [Fix #160] the refill used to APPEND, so every updateBans() doubled the
	-- cache; clear first so the cache always mirrors the two tables.
	IPs = { }
	serials = { }
	-- [Fix #160] pcall-wrapped: mysql may still be starting when this runs,
	-- a dead export must not kill the resource start
	local ok, err = pcall(function()
		local ipCounter = 0
		local serialCounter = 0
		local result = exports.mysql:query("SELECT ip FROM bannedips")
		if result then
			while true do
				local row = exports.mysql:fetch_assoc(result)
				if not row then break end
				if row["ip"] and tostring(row["ip"]) ~= "" then
					table.insert(IPs, row["ip"])
					ipCounter = ipCounter + 1
				end
			end
			exports.mysql:free_result(result)
		end
		result = exports.mysql:query("SELECT serial FROM bannedserials")
		if result then
			while true do
				local row = exports.mysql:fetch_assoc(result)
				if not row then break end
				if row["serial"] and tostring(row["serial"]) ~= "" then
					table.insert(serials, row["serial"])
					serialCounter = serialCounter + 1
				end
			end
			exports.mysql:free_result(result)
		end
		outputDebugString(ipCounter .. " IP bans have been loaded")
		outputDebugString(serialCounter .. " serial bans have been loaded")
	end)
	if not ok then
		outputDebugString("[global] fillBans failed: " .. tostring(err), 2)
	end
end

-- [Fix #160] was commented out: after every restart the caches stayed empty,
-- so account/s_login.lua never kicked a banned IP/serial on join.
addEventHandler("onResourceStart", getRootElement(), fillBans)

-- [Fix #160] mysql may still be starting when this resource loads - one
-- delayed refill covers that window (fillBans is idempotent now).
setTimer(function()
	fillBans(getThisResource())
end, 5000, 1)

function fetchIPs()
	return IPs
end

function fetchSerials()
	return serials
end

function updateBans()
	-- [Fix #160] was getThisReasource() (typo) -> nil -> fillBans no-op'd
	fillBans(getThisResource())
end
