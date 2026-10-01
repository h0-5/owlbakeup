--------------------------------------------------------------------------------
-- [U4] REPORT ACCEPT / REJECT TOASTS (client side)
--
-- Server side (s_reports.lua -> sendReportToast) triggers
--     triggerClientEvent(player, "report-system:notify", player, payload)
-- with
--     payload = { text = "Report #12 accepted by Senior Admin Maxime",
--                 sub  = "Please wait for them to contact you.",  -- optional
--                 type = "accepted" | "rejected" | "info",
--                 reportId = 12 }
-- and this file draws it as a small timed box, stacked in the TOP-RIGHT:
--     x = screenW - boxW - 5                 (same right margin as the hud)
--     y = 195                                (below the status/clock/date/money
--                                             block, the stack grows downward)
-- The whole stack is pulled back on screen if it would not fit, so the box is
-- ALWAYS fully inside the viewport (never slanted / never cut off).
-- Look: dark background + 4px colour bar (green accepted / red rejected),
-- bold white title, grey sub line, 6 seconds life + fade out.
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

local MARGIN = 5
local MAX_W = 420
local LIFETIME = 6000
local FADE_MS = 600
local MAX_TOASTS = 4
local TOP_Y = 195

local toasts = {}

local palette = {
	accepted = { 0, 220, 90 },
	rejected = { 255, 84, 84 },
	info = { 255, 194, 14 },
}

local function accentFor(kind)
	return palette[kind] or palette.info
end

-- same rounded-rect style the green report panel uses (c_report_panel.lua)
local function drawRoundRect(x, y, w, h, color, r)
	r = r or 6
	w, h, x, y = w - r * 2, h - r * 2, math.floor(x + r), math.floor(y + r)
	dxDrawRectangle(x - r, y, w + r * 2, h, color)
	dxDrawRectangle(x, y - r, w, r, color)
	dxDrawRectangle(x, y + h, w, r, color)
	dxDrawCircle(x, y, r, 180, 270, color, color, 7)
	dxDrawCircle(x + w, y, r, 270, 360, color, color, 7)
	dxDrawCircle(x, y + h, r, 90, 180, color, color, 7)
	dxDrawCircle(x + w, y + h, r, 0, 90, color, color, 7)
end

addEvent("report-system:notify", true)
addEventHandler("report-system:notify", localPlayer, function(payload)
	if type(payload) ~= "table" then return end
	local text = tostring(payload.text or "")
	if text == "" then return end
	table.insert(toasts, 1, {
		text = text,
		sub = (payload.sub and tostring(payload.sub)) or false,
		kind = tostring(payload.type or "info"),
		reportId = payload.reportId,
		born = getTickCount(),
	})
	while #toasts > MAX_TOASTS do
		table.remove(toasts)
	end
	playSoundFrontEnd(101)
end)

local function toastHeight(t)
	return t.sub and 46 or 30
end

addEventHandler("onClientRender", root, function()
	if #toasts == 0 then return end
	if isPlayerMapVisible() then return end

	local now = getTickCount()
	for i = #toasts, 1, -1 do
		if now - toasts[i].born >= LIFETIME then
			table.remove(toasts, i)
		end
	end
	if #toasts == 0 then return end

	local w = math.min(MAX_W, sx - 2 * MARGIN - 10)
	if w < 120 then w = 120 end
	local gap = 6

	local totalH = -gap
	for i = 1, #toasts do
		totalH = totalH + toastHeight(toasts[i]) + gap
	end

	-- top of the stack: fixed spot below the money block; pulled back on
	-- screen if the stack would not fit
	local y = TOP_Y
	if y + totalH > sy - 10 then
		y = math.max(10, sy - 10 - totalH)
	end

	local x = sx - w - MARGIN
	for i = 1, #toasts do
		local t = toasts[i]
		local h = toastHeight(t)
		local alive = now - t.born
		local alpha = 255
		if alive > LIFETIME - FADE_MS then
			alpha = math.floor(255 * (1 - (alive - (LIFETIME - FADE_MS)) / FADE_MS))
			if alpha < 0 then alpha = 0 end
		end

		local acc = accentFor(t.kind)
		drawRoundRect(x, y, w, h, tocolor(12, 14, 18, math.floor(235 * alpha / 255)))
		dxDrawRectangle(x, y, 4, h, tocolor(acc[1], acc[2], acc[3], alpha))

		-- color codes OFF (last arg false): "Report #12" must print literally
		dxDrawText(t.text, x + 14, y + 7, x + w - 12, y + h - 4,
			tocolor(255, 255, 255, alpha), 1, "default-bold", "left", "top",
			false, true, false, false)
		if t.sub then
			dxDrawText(t.sub, x + 14, y + 26, x + w - 12, y + h - 4,
				tocolor(198, 204, 212, alpha), 0.92, "default", "left", "top",
				false, true, false, false)
		end

		y = y + h + gap
	end
end, false)
