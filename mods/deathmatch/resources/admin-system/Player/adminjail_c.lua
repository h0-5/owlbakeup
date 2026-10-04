--MAXIME / 2015.1.10

local sw, sh = guiGetScreenSize()
local lastJailtime = nil
local currentSecs = "Calculating.."
local timer = nil
local function drawRoundedRect(x, y, w, h, color, radius)
	local w2 = w - radius * 2
	local h2 = h - radius * 2
	if w2 >= 0 and h2 >= 0 then
		x = x + radius
		y = y + radius
		dxDrawRectangle(x, y, w2, h2, color)
		dxDrawRectangle(x, y - radius, w2, radius, color)
		dxDrawRectangle(x, y + h2, w2, radius, color)
		dxDrawRectangle(x - radius, y, radius, h2, color)
		dxDrawRectangle(x + w2, y, radius, h2, color)
		dxDrawCircle(x, y, radius, 180, 270, color, color, 7)
		dxDrawCircle(x + w2, y, radius, 270, 360, color, color, 7)
		dxDrawCircle(x + w2, y + h2, radius, 0, 90, color, color, 7)
		dxDrawCircle(x, y + h2, radius, 90, 180, color, color, 7)
	end
end

function showAdminJailCounter()
	local jailtime = getElementData(localPlayer, "jailtime")
	if jailtime and (tonumber(jailtime) and tonumber(jailtime) > 0) or jailtime == "permanently" then
		if lastJailtime ~= jailtime then
			currentSecs = tonumber(jailtime) and jailtime*60 or jailtime
			lastJailtime = jailtime
			if timer and isTimer(timer) then
				killTimer(timer)
				timer = nil
			end
			if tonumber(currentSecs) then
				timer = setTimer(function ()
					if tonumber(currentSecs) then
						currentSecs = currentSecs - 1
					end
				end, 1000, 59)
			end
		end

		local w, h = 430, 156
		local x, y = (sw - w) / 2, 45

		drawRoundedRect(x, y, w, h, tocolor(0, 0, 0, 180), 10)

		local shown = tonumber(currentSecs) and exports.datetime:formatSeconds(currentSecs) or tostring(jailtime)
		local reason = getElementData(localPlayer, "jailreason") or "Unknown"
		local admin = getElementData(localPlayer, "jailadmin") or "Unknown"

		dxDrawText("#ff0000Admin Jail\n\n(( #ffffff" .. tostring(shown) .. " #ff0000 ))\n\n#ff0000Reason: #ffffff" .. tostring(reason) .. "\n\n#ff0000Jailed by #ffffff" .. tostring(admin), x, y, x + w, y + h, tocolor(255, 255, 255, 255), 1.2, "default", "center", "center", false, false, true, true, false)
	else
		currentSecs = "Calculating.."
		lastJailtime = nil
	end
end
addEventHandler("onClientRender", root, showAdminJailCounter)

