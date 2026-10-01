-- [Fix #161] dedicated vehicle keys:
--   X = window up/down TOGGLE (was: Z only rolled up / X only rolled down)
--   Z = seatbelt on/off toggle (realism-system seatbelt server logic)

local function isWindowsKeyBlocked()
	if isChatBoxInputActive and isChatBoxInputActive() then
		return true
	end
	if guiGetFocusedElement then
		local ok, focused = pcall(guiGetFocusedElement)
		if ok and focused then
			return true
		end
	end
	if isCursorShowing() then
		return true
	end
	if getKeyState("lctrl") or getKeyState("rctrl") or getKeyState("lalt") or getKeyState("ralt") then
		return true
	end
	return false
end

-- vehicle:windowstat: 0 = windows UP, 1 = windows DOWN (s_windows.lua rolls
-- up from 1 and rolls down from 0). The server only rolls down when
-- isVehicleWindowUp() says so, which needs a roof (g_functions.lua) - roofless
-- models can never lower their windows, so the key must not ask for it.
local function toggleWindows()
	if isWindowsKeyBlocked() then
		return
	end

	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle or not isElement(vehicle) then
		return
	end

	if getVehicleOccupant(vehicle) ~= localPlayer and getVehicleOccupant(vehicle, 1) ~= localPlayer then
		return
	end

	if not hasVehicleWindows(vehicle) then
		return
	end

	local windowState = tonumber(getElementData(vehicle, "vehicle:windowstat")) or 0
	if windowState == 0 and not hasVehicleRoof(vehicle) then
		return
	end

	triggerServerEvent("vehicle:togWindow", localPlayer)
end

-- [Fix #161] Z: seatbelt toggle -> realism-system s_vehicle_crash.lua
-- seatbelt() through the realism:seatbelt:toggle event (same path the hud
-- seatbelt strip item uses). The state comes back synced as element data
-- "seatbelt", which the speedometer banner and the hud icon row read.
local function toggleSeatbelt()
	if isWindowsKeyBlocked() then
		return
	end

	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle or not isElement(vehicle) then
		return
	end

	triggerServerEvent("realism:seatbelt:toggle", localPlayer, localPlayer)
end

bindKey("x", "down", toggleWindows)
bindKey("z", "down", toggleSeatbelt)
