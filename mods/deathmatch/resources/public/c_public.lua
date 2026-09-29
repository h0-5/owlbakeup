-- Decompiled by Owl Decompiler v1.0 (public/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with decompiler artifacts repaired:
--   * formatNumber: the decompile collapsed the classic
--     `local left, num, right = match, '^(-?%d+)(%d%d%d)'` loop into an
--     infinite `while true` (gsub count assigned to the string var).
--     Restored with the gsub-count loop + the original tail gsub return.
--   * isASCII: the decompile lost the final `return true` (`return _FOR_`).

function formatNumber(amount)
	amount = tostring(amount)
	while true do
		local _, k = string.gsub(amount, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
		amount = string.gsub(amount, "^(-?%d+)(%d%d%d)", "%1,%2")
	end
	return (string.gsub(amount, "^(-?%d+)(%d%d%d)", "%1,%2"))
end

function isASCII(text)
	for i = 1, #text do
		if text:byte(i) < 33 or text:byte(i) > 126 then
			return false
		end
	end
	return true
end
