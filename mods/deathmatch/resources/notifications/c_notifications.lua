-- notifications - Owl old-client port (Fix #59)
-- Faithful reconstruction from arma-backupm/[rp]/notifications/noti_c_decompiled.lua
-- Systems: title/text notifications, bottom pill output(), directive banner,
--          key descriptions (E-hints). The F6 notification-center is NOT ported
--          (its server side did not survive the backup).
--
-- Exports (client): output, sendNotification, hideNotification,
--                   showDirective, hideDirective, showKeyDescription, hideKeyDescription

notifications = { list = {} }
directive = { state = false, text = "", color = tocolor(255, 255, 255, 255), font = "default-bold" }

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

local typeColors = {
	success = tocolor(46, 204, 113),
	error   = tocolor(231, 76, 60),
	info    = tocolor(52, 152, 219),
	police  = tocolor(59, 120, 195),
	danger  = tocolor(255, 59, 59),
}

local pills = {}          -- output() active pills
local pillTimers = {}     -- id -> kill timer
local pillSeq = 0
local pillRenderAttached = false

local keyDesc = { list = {}, renderAttached = false }

local eui = nil
local GRADIENT_BG = nil

function UIKitReady()
	eui = exports.UIKit
	directive.font = eui:getUIFont("default-large")
	GRADIENT_BG = eui:getUIImage("gradient_x")
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

language = "ar"
function updateTexturesSettings()
	if exports.settings:getSetting("language") then
		language = "ar"
	else
		language = "en"
	end
end
addEvent("onClientSettingsReady", true)
addEventHandler("onClientSettingsReady", resourceRoot, updateTexturesSettings)
addEvent("onClientSettingChange", false)
addEventHandler("onClientSettingChange", localPlayer, function(key, old, value)
	if key == "language" then
		if value then
			language = "ar"
		else
			language = "en"
		end
	end
end)

function dxDrawRoundedRectangle(x, y, w, h, color, radius, postGUI, corners)
	-- reconstructed: radius inset + 3 rects + 4 corner circles (lost corner
	-- flags in the decompile default to all-rounded, which is what Owl drew)
	radius = radius or 6
	local rx, ry = math.floor(x + radius), math.floor(y + radius)
	local rw, rh = math.floor(w - radius * 2), math.floor(h - radius * 2)
	if rw < 1 or rh < 1 then
		dxDrawRectangle(x, y, w, h, color, postGUI)
		return
	end
	dxDrawRectangle(rx - radius, ry, rw + radius * 2, rh, color, postGUI)
	dxDrawRectangle(rx, ry - radius, rw, radius, color, postGUI)
	dxDrawRectangle(rx, ry + rh, rw, radius, color, postGUI)
	dxDrawCircle(rx, ry, radius, 180, 270, color, color, 7, _, postGUI)
	dxDrawCircle(rx + rw, ry, radius, 270, 360, color, color, 7, _, postGUI)
	dxDrawCircle(rx, ry + rh, radius, 90, 180, color, color, 7, _, postGUI)
	dxDrawCircle(rx + rw, ry + rh, radius, 0, 90, color, color, 7, _, postGUI)
end

function isMouseInPosition(x, y, w, h)
	if not isCursorShowing() then
		return false
	end
	local cx, cy = getCursorPosition()
	if not cx then
		return false
	end
	cx, cy = cx * screenW, cy * screenH
	return x <= cx and cx <= x + w and y <= cy and cy <= y + h
end

function animation(tick, duration, from1, from2, from3, to1, to2, to3, easing)
	if duration < getTickCount() - tick then
		return to1, to2, to3
	end
	local progress = (getTickCount() - tick) / duration
	if progress < 0 then progress = 0 end
	return interpolateBetween(from1, from2, from3, to1, to2, to3, progress, easing)
end

-------------------------------------------------------------------------------
-- Title/Text notification box (sendNotification)
-------------------------------------------------------------------------------
function notifications.render()
	for index, noti in ipairs(notifications.list) do
		local width = math.max(350, dxGetTextWidth(split(tostring(noti.Text), "\n")[1], 1, directive.font) + 20, dxGetTextWidth(split(tostring(noti.Title), "\n")[1], 1, directive.font) + 20)
		local height = 25 * #split(tostring(noti.Title), "\n") + 20 * #split(tostring(noti.Text), "\n") + 20
		local x = math.floor(screenW - width - 10)
		local y = math.floor(120)
		dxDrawRoundedRectangle(x, y, width, height, tocolor(5, 5, 5, 230), 6, true)
		dxDrawText(tostring(noti.Title), x + 15, y + 10, x + width, y + 25, tocolor(255, 255, 255, 255), 1, directive.font, "left", "top", true, true, true, true, false)
		dxDrawText(tostring(noti.Text), x + 15, y + 28, x + width, y + height, tocolor(255, 255, 255, 255), 1, directive.font, "left", "top", true, true, true, true, false)
	end
end
addEventHandler("onClientRender", root, notifications.render)

function sendNotification(title, text, time, horizontalAlign, verticalAlign, id, width, font)
	if type(text) == "table" then text = text[language] end
	if type(title) == "table" then title = title[language] end
	if not id then
		for _, noti in ipairs(notifications.list) do
			if noti.Title == title and noti.Text == text then
				return false
			end
		end
	end
	local notiID = id or math.random(9999999)
	table.insert(notifications.list, {
		ID = notiID,
		Title = title,
		Text = text,
		Time = time or 5000,
		TickCount = getTickCount(),
		HorizontalAlign = horizontalAlign or "left",
		VerticalAlign = verticalAlign or "bottom",
		Width = width,
		NormalFont = font,
	})
	playSound("sounds/notification.wav")
	if time ~= -1 then
		setTimer(function(checkID)
			for index, noti in ipairs(notifications.list) do
				if noti.ID == checkID then
					table.remove(notifications.list, index)
					break
				end
			end
		end, time or 5000, 1, notiID)
	end
	return notiID
end
addEvent("notifications:sendNotification", true)
addEventHandler("notifications:sendNotification", root, sendNotification)

function hideNotification(title, text, id)
	for index, noti in ipairs(notifications.list) do
		if id and id == noti.ID then
			table.remove(notifications.list, index)
			return true
		end
		if noti.Title == title then
			if type(text) == "string" then
				if noti.Text == text then
					table.remove(notifications.list, index)
					break
				end
			else
				table.remove(notifications.list, index)
				break
			end
		end
	end
	return true
end
addEvent("notifications:hideNotification", true)
addEventHandler("notifications:hideNotification", root, hideNotification)

-------------------------------------------------------------------------------
-- Directive banner (center screen, below crosshair)
-------------------------------------------------------------------------------
function showDirective(text, color, timeout, font)
	if text == "" then
		directive.state = false
		return
	end
	if type(text) == "table" then text = text[language] or "" end
	if type(color) == "table" then color = tocolor(color[1], color[2], color[3], color[4]) end
	directive.state = true
	directive.text = tostring(text)
	directive.color = color or tocolor(255, 255, 255, 255)
	directive.font = font or directive.font
	if isTimer(directive.hideTimer) then
		killTimer(directive.hideTimer)
	end
	if timeout then
		directive.hideTimer = setTimer(function()
			directive.state = false
		end, timeout or 5000, 1)
	end
end
addEvent("notifications:showDirective", true)
addEventHandler("notifications:showDirective", root, showDirective)

function hideDirective()
	directive.state = false
end
addEvent("notifications:hideDirective", true)
addEventHandler("notifications:hideDirective", root, hideDirective)

local function renderDirective()
	if not directive.state then
		return
	end
	local y = screenH / 2 + 250 * scale
	local stripped = string.gsub(directive.text, "#%x%x%x%x%x%x", "")
	dxDrawText(stripped, 2, y, screenW, y + 20 * scale, tocolor(0, 0, 0, 255), 1, directive.font, "center", "center", true, true, false, true, false)
	dxDrawText(stripped, -2, y, screenW, y + 20 * scale, tocolor(0, 0, 0, 255), 1, directive.font, "center", "center", true, true, false, true, false)
	dxDrawText(stripped, 0, y + 2, screenW, y + 20 * scale, tocolor(0, 0, 0, 255), 1, directive.font, "center", "center", true, true, false, true, false)
	dxDrawText(stripped, 0, y - 2, screenW, y + 20 * scale, tocolor(0, 0, 0, 255), 1, directive.font, "center", "center", true, true, false, true, false)
	dxDrawText(directive.text, 0, y, screenW, y + 20 * scale, directive.color, 1, directive.font, "center", "center", true, true, false, true, false)
end
addEventHandler("onClientRender", root, renderDirective)

-------------------------------------------------------------------------------
-- output() pill notifications (bottom-center slide-in)
-------------------------------------------------------------------------------
local PILL_H = 40
local function renderPills()
	local stackBottom = screenH - 60 * scale
	local stackTop = 60 * scale
	for _, pill in ipairs(pills) do
		local progress = (getTickCount() - pill.tick) / 500
		if progress > 1 then progress = 1 end
		local px, py
		if pill.align == "top" then
			py = interpolateBetween(pill.y_i, 0, 0, pill.y, 0, 0, progress, "OutBack")
			px = screenW / 2 - pill.width / 2
		else
			px = interpolateBetween(screenW / 2 + pill.width, 0, 0, screenW / 2 - pill.width / 2, 0, 0, progress, "OutBack")
			py = pill.y
		end
		if pill.dying then
			px = pill.px or px
			py = pill.py or py
		else
			pill.px, pill.py = px, py
		end
		dxDrawRoundedRectangle(px, py, pill.width, PILL_H * scale, pill.color, 8, true)
		dxDrawCircle(px + 14 * scale, py + PILL_H * scale / 2, 10 * scale, 0, 360, pill.color_2, pill.color_2, 12, _, true)
		if pill.type then
			dxDrawImage(px + 4 * scale, py + 5 * scale, 25 * scale, 25 * scale, "icons/" .. pill.type .. ".png", 0, 0, 0, tocolor(255, 255, 255, 220), true)
		end
		dxDrawText(pill.text, px + 35 * scale, py, px + pill.width - 10 * scale, py + PILL_H * scale, tocolor(255, 255, 255, 255), 1, directive.font, "center", "center", true, true, false, true, false)
	end
end

local function reflowPills(align)
	local stack = 0
	for _, pill in ipairs(pills) do
		if pill.align == align and not pill.dying then
			if align == "top" then
				pill.y = stackTop + stack * (PILL_H * scale + 5 * scale)
			else
				pill.y = stackBottom - stack * (PILL_H * scale + 5 * scale)
			end
			stack = stack + 1
		end
	end
end

local function removePill(id)
	for index, pill in ipairs(pills) do
		if pill.id == id then
			table.remove(pills, index)
			break
		end
	end
	if #pills == 0 then
		removeEventHandler("onClientRender", root, renderPills)
		pillRenderAttached = false
	end
	reflowPills("bottom")
	reflowPills("top")
end

function output(text, duration, ntype, align, options)
	if type(text) == "table" then text = text[language] or text.en or "" end
	if type(text) ~= "string" then text = tostring(text) end
	duration = math.max(tonumber(duration) or 4000, 1000)
	align = align or "bottom"
	options = options or {}
	if not pillRenderAttached then
		addEventHandler("onClientRender", root, renderPills)
		pillRenderAttached = true
	end
	pillSeq = pillSeq + 1
	local pill = {
		id = pillSeq,
		text = text,
		duration = duration,
		type = ntype,
		width = math.max(140 * scale, (dxGetTextWidth(text, 1, directive.font, true) or 100) + 55 * scale),
		y = align == "top" and -PILL_H * scale or screenH - 60 * scale,
		y_i = align == "top" and -PILL_H * scale or screenH - 60 * scale,
		tick = getTickCount(),
		color = options.color or tocolor(0, 0, 0, 200),
		color_2 = options.color_2 or typeColors[ntype] or tocolor(255, 255, 255),
		align = align,
	}
	table.insert(pills, pill)
	reflowPills(align)
	playSound("sounds/notification.wav")
	pillTimers[pill.id] = setTimer(removePill, duration, 1, pill.id)
	return pill.id
end
addEvent("notifications:output", true)
addEventHandler("notifications:output", root, output)

-------------------------------------------------------------------------------
-- Key descriptions (E-hints)
-------------------------------------------------------------------------------
function showKeyDescription(code, keyText, text, color)
	for _, desc in ipairs(keyDesc.list) do
		if desc.code == code then
			return
		end
	end
	if type(text) == "table" then text = text[language] or "" end
	if type(color) == "table" then color = tocolor(color[1], color[2], color[3], color[4]) end
	if not keyDesc.renderAttached then
		addEventHandler("onClientRender", root, renderKeyDescriptions)
		keyDesc.renderAttached = true
	end
	table.insert(keyDesc.list, {
		state = true,
		code = code,
		key = keyText,
		text = tostring(text),
		color = color or tocolor(255, 255, 255, 255),
		key_w = math.max(40 * scale, (dxGetTextWidth(keyText, 1, directive.font) or 30) + 25 * scale),
	})
end

function renderKeyDescriptions()
	local baseX, baseY = 30 * scale, 450 * scale
	for index, desc in ipairs(keyDesc.list) do
		local y = baseY + (index - 1) * 40 * scale
		dxDrawRoundedRectangle(baseX, y, desc.key_w + 110 * scale, 35 * scale, tocolor(0, 8, 20, 200), 6, true)
		dxDrawRectangle(baseX, y + 35 * scale / 4, 2, 35 * scale / 2, tocolor(255, 255, 255, 255), true)
		dxDrawText(desc.key, baseX, y, baseX + desc.key_w, y + 35 * scale, desc.color, 1, directive.font, "center", "center", true, true, true, true, false)
		dxDrawText(desc.text, baseX + desc.key_w + 10 * scale, y, baseX + desc.key_w + 200 * scale, y + 35 * scale, desc.color, 1, directive.font, "left", "center", true, true, true, true, false)
	end
end

function hideKeyDescription(code)
	for index, desc in ipairs(keyDesc.list) do
		if desc.code == code then
			table.remove(keyDesc.list, index)
			break
		end
	end
	if #keyDesc.list == 0 and keyDesc.renderAttached then
		removeEventHandler("onClientRender", root, renderKeyDescriptions)
		keyDesc.renderAttached = false
	end
end
addEvent("notifications:showKeyDescription", true)
addEventHandler("notifications:showKeyDescription", root, showKeyDescription)
addEvent("notifications:hideKeyDescription", true)
addEventHandler("notifications:hideKeyDescription", root, hideKeyDescription)
