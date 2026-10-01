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

local function toggleWindows(wantUp)
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

	if wantUp then
		if windowState ~= 1 then
			return
		end
	elseif not (windowState == 0 and hasVehicleRoof(vehicle)) then
		return
	end

	triggerServerEvent("vehicle:togWindow", localPlayer)
end

bindKey("z", "down", function()
	toggleWindows(true)
end)

bindKey("x", "down", function()
	toggleWindows(false)
end)
