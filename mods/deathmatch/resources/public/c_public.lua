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

-------------------------------------------------------------------------------
-- [Fix #63] colshape checker - the old Owl public resource shipped one (the
-- Fix #62 port deferred it: the decompile was too damaged). The contract is
-- recovered from the trucker job client:
--   exports.public:addColshapeChecker(shape, x, y, z) registers a colshape;
--   when the local player enters it, "onClientColshapeCheckerHit" fires with
--   the shape as source. One hit per entry (re-fires after leaving).
--   addColshapeChecker is used by jobs to gate deliveries at a polygon.
-------------------------------------------------------------------------------
local checkedShapes = {}
local insideShapes = {}
local checkerTimer = nil

local function checkShapes()
	for shape in pairs(checkedShapes) do
		if not isElement(shape) then
			checkedShapes[shape] = nil
			insideShapes[shape] = nil
		else
			local within = isElementWithinColShape(localPlayer, shape)
			if within and not insideShapes[shape] then
				insideShapes[shape] = true
				triggerEvent("onClientColshapeCheckerHit", shape)
			elseif not within and insideShapes[shape] then
				insideShapes[shape] = false
			end
		end
	end
	if next(checkedShapes) == nil and isTimer(checkerTimer) then
		killTimer(checkerTimer)
		checkerTimer = nil
	end
end

function addColshapeChecker(shape, x, y, z)
	if not isElement(shape) or getElementType(shape) ~= "colshape" then
		return false
	end
	checkedShapes[shape] = { x = x, y = y, z = z }
	if not checkerTimer then
		checkerTimer = setTimer(checkShapes, 250, 0)
	end
	return true
end

function removeColshapeChecker(shape)
	checkedShapes[shape] = nil
	insideShapes[shape] = nil
end

addEventHandler("onClientElementDestroy", root, function()
	if checkedShapes[source] then
		checkedShapes[source] = nil
		insideShapes[source] = nil
	end
end)
