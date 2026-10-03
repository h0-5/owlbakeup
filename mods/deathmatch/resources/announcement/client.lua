--MAXIME

-- ============================================================================
-- [Fix batch 171] /ann surface = the TOP-CENTER CARD from his picture 5.
-- The legacy surface (full-width dxDrawRectangle(0,0,sx,25) strip + 1px/frame
-- marquee, y 0-25) is REPLACED by one compact card:
--     centred x, top y = 14*scale  ->  14..60 at 1920x1080,
--     dark rounded box (18,18,22,235) r=6, megaphone icon left,
--     WHITE text (sender semantics live in the "Admin: "/"SUP: " prefix),
--     8s life, slide+fade in (280ms) / fade out (350ms), dx only - the card
--     never captures the mouse (no cursor, no gui element).
-- ============================================================================

local sx, sy = guiGetScreenSize()

local scale = sy / 1080

local localPlayer = getLocalPlayer()

local FONT       = "default-bold"
local CARD_TOP   = 14
local CARD_H     = 46
local ICON_SIZE  = 26
local ICON_PAD   = 12
local TEXT_GAP   = 12
local TEXT_PAD   = 16
local MIN_W      = 240
local MAX_W_FRAC = 0.85
local LIFETIME   = 8000
local IN_MS      = 280
local OUT_MS     = 350
local BG_A       = 235

local card = {
	active = false,
	fading = false,
	text   = "",
	cr = 255, cg = 255, cb = 255,
	tick    = 0,
	outTick = 0,
	hideAt  = 0,
	x = 0, y = 0, w = 0, h = 0,
	textRight = 0,
}

local function cutLastChar(s)
	local i = #s
	if i <= 1 then return "" end
	local b = s:byte(i)
	while i > 1 and b >= 0x80 and b < 0xC0 do
		i = i - 1
		b = s:byte(i)
	end
	return s:sub(1, i - 1)
end

local function trimToWidth(text, maxW)
	if (dxGetTextWidth(text, 1, FONT, true) or 0) <= maxW then
		return text
	end
	local out = text
	while #out > 1 and (dxGetTextWidth(out .. "...", 1, FONT, true) or 0) > maxW do
		out = cutLastChar(out)
	end
	return out .. "..."
end

local function layoutCard()
	local maxTextW = sx * MAX_W_FRAC - (ICON_PAD + ICON_SIZE + TEXT_GAP + TEXT_PAD) * scale
	card.text = trimToWidth(card.text, maxTextW)
	local textW = math.min(dxGetTextWidth(card.text, 1, FONT, true) or 0, maxTextW)
	card.w = math.max(MIN_W * scale, (ICON_PAD + ICON_SIZE + TEXT_GAP + TEXT_PAD) * scale + textW * scale)
	card.h = CARD_H * scale
	card.x = math.floor((sx - card.w) / 2)
	card.y = CARD_TOP * scale
	card.textRight = card.x + card.w - TEXT_PAD * scale
end

local function roundedRect(x, y, w, h, color, radius)
	local rw = w - radius * 2
	if rw < 1 or h < 1 then
		dxDrawRectangle(x, y, w, h, color, true)
		return
	end
	dxDrawRectangle(x + radius, y, rw, h, color, true)
	dxDrawRectangle(x, y + radius, w, h - radius * 2, color, true)
	dxDrawCircle(x + radius, y + radius, radius, 0, 360, color, color, 18, true)
	dxDrawCircle(x + w - radius, y + radius, radius, 0, 360, color, color, 18, true)
	dxDrawCircle(x + radius, y + h - radius, radius, 0, 360, color, color, 18, true)
	dxDrawCircle(x + w - radius, y + h - radius, radius, 0, 360, color, color, 18, true)
end

local function drawCard()
	if not card.active then return end

	-- camera in hand hides the card exactly like the old strip did
	if getPedWeapon(localPlayer) == 43 and getPedControlState(localPlayer, "aim_weapon") then
		return
	end

	local now = getTickCount()
	local pIn = (now - card.tick) / IN_MS
	if pIn < 0 then pIn = 0 elseif pIn > 1 then pIn = 1 end

	if not card.fading and now >= card.hideAt then
		card.fading = true
		card.outTick = now
	end

	local k = pIn
	local yOff = interpolateBetween(-(card.h + 24 * scale), 0, 0, 0, 0, 0, pIn, "OutQuad")

	if card.fading then
		local pOut = (now - card.outTick) / OUT_MS
		if pOut >= 1 then
			card.active = false
			card.fading = false
			setElementData(localPlayer, "annHeight", 0)
			return
		end
		k = k * (1 - pOut)
		yOff = yOff - pOut * 8 * scale
	end

	if k <= 0 then return end

	local x, y, w, h = card.x, card.y + yOff, card.w, card.h

	roundedRect(x, y, w, h, tocolor(18, 18, 22, math.floor(BG_A * k)), 6 * scale)

	dxDrawImage(x + ICON_PAD * scale, y + (h - ICON_SIZE * scale) / 2,
		ICON_SIZE * scale, ICON_SIZE * scale, "megaphone.png",
		0, 0, 0, tocolor(255, 255, 255, math.floor(255 * k)), true)

	dxDrawText(card.text, x + (ICON_PAD + ICON_SIZE + TEXT_GAP) * scale, y,
		card.textRight, y + h, tocolor(255, 255, 255, math.floor(255 * k)),
		scale, FONT, "left", "center", true, false, true, false, false)
end

addEventHandler("onClientRender", getRootElement(), drawCard)

local function handleClick(button, state, absX, absY)
	if button == "left" and state == "down" and card.active and #card.text > 0 then
		if absX >= card.x and absX <= card.x + card.w and absY >= card.y and absY <= card.y + card.h then
			local url = exports.global:getUrlFromString(card.text)
			if url and setClipboard(url) then
				outputChatBox('Copied "' .. url .. '".')
			end
		end
	end
end

addEventHandler("onClientClick", getRootElement(), handleClick)

function postAnn(msg, cr, cg, cb, playsound)
	if msg and (string.len(msg) > 0) then
		if playsound and tonumber(playsound) and (tonumber(playsound) > 0) then
			playSound(playsound .. ".mp3")
		end

		card.text = msg
		if cr and cg and cb then
			card.cr, card.cg, card.cb = cr, cg, cb
		end

		layoutCard()

		card.tick = getTickCount()
		card.hideAt = card.tick + IN_MS + LIFETIME
		card.fading = false
		card.active = true

		setElementData(localPlayer, "annHeight", card.y + card.h)
	end
end

addEvent("announcement:post", true)

addEventHandler("announcement:post", getRootElement(), postAnn)

function sendTopNotification(msg, r1, b1, g1, playsound)
	postAnn(msg, r1, b1, g1, playsound)
end
