-- owlbakeup Fix #61 - shared client helpers for the ported Owl job files.
-- The encrypted original shipped a shared helper file in the job-system
-- resource that the old-client dump does not include; the decompiled taxi
-- client calls the global split() (dxDrawInfo tooltip line count). This is
-- the exact split() implementation the rest of this server uses
-- (global/g_benchmark.lua) - MTA gives each resource its own VM, so the
-- job-system resource needs its own copy.

function split(str, pat)
	local t = {}
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t, cap)
		end
		last_end = e + 1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end
