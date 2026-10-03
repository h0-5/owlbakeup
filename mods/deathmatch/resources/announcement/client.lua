--MAXIME

-- ============================================================================
-- [Fix batch 172] /ann surface = the TOP-CENTER CARD from his picture 5.
--
-- Owner feedback (3 problems), all addressed here:
--   1) LAG  - ALL layout (dxGetTextWidth, UTF-8 ellipsis, box w/h, text right
--              edge) runs in postAnn -> layoutCard, i.e. ONCE per
--              announcement. onClientRender never measures text and never
--              builds a string. The ellipsis is a binary search (O(log n)
--              measurements) instead of one measurement per removed character,
--              so a long announcement can no longer stall the frame it pops
--              on. Per frame: one boolean test when there is no card; while a
--              card is up, a FLAT box (2 x dxDrawRectangle) replaces the old
--              4 x dxDrawCircle + 2 x dxDrawRectangle, and the sniper-scope
--              test is throttled to 60 ms instead of running every frame. The
--              lifecycle bookkeeping was moved IN FRONT of that test - the old
--              code returned before it, so aiming with weapon 43 kept the card
--              active forever (per-frame block never ended, annHeight never
--              reset). No timers exist on this path: the 8s hold is tick based
--              (card.hideAt) and the sound element is tracked and destroyed on
--              the next announcement, so nothing piles up.
--   2) RED  - background is dark red (94,20,28,245) with a brighter red
--              hairline (168,44,54,255); it was near-black (18,18,22,235).
--   3) WORD - the "Admin: "/"SUP: " prefix is gone (announcement/server.lua
--              sends the raw message), the card draws the text as-is.
--
-- Card: centred x, top y = 14*scale -> 14..60 at 1920x1080, megaphone icon
-- left, WHITE default-bold text, 8s life, slide+fade in (280ms) / fade out
-- (350ms), dx only - the card never captures the mouse (no cursor, no gui).
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
local BG_A       = 245
local SNIPER_MS  = 60
local TEXT_X     = (ICON_PAD + ICON_SIZE + TEXT_GAP) * scale
local CHROME_W   = (ICON_PAD + ICON_SIZE + TEXT_GAP + TEXT_PAD) * scale
local BORDER     = math.max(1, math.floor(scale))

-- [Fix batch 172] the card must read as RED, not near-black.
local BG_R, BG_G, BG_B       = 94, 20, 28
local EDGE_R, EDGE_G, EDGE_B = 168, 44, 54

local card = {
	active   = false,
	fading   = false,
	hidden   = false,
	text     = "",
	cr = 255, cg = 255, cb = 255,
	tick     = 0,
	outTick  = 0,
	hideAt   = 0,
	sniperAt = 0,
	hideY    = 0,
	x = 0, y = 0, w = 0, h = 0,
	textRight = 0,
	sound = nil,
}

-- prefix of at most n bytes that ends on a UTF-8 character boundary
local function cutAtChar(s, n)
	if n >= #s then return s end
	local i = n + 1
	while i > 1 do
		local b = s:byte(i)
		if b < 0x80 or b >= 0xC0 then break end
		i = i - 1
	end
	return s:sub(1, i - 1)
end

local function firstChar(s)
	local i = 2
	while i <= #s do
		local b = s:byte(i)
		if b < 0x80 or b >= 0xC0 then break end
		i = i + 1
	end
	return s:sub(1, i - 1)
end

-- [Fix batch 172] runs ONLY from layoutCard (once per announcement).
-- Was: one dxGetTextWidth per character removed, each on a freshly
-- concatenated string - hundreds of measurements inside a single frame.
local function trimToWidth(text, maxW)
	if (dxGetTextWidth(text, 1, FONT, true) or 0) <= maxW then
		return text
	end
	local lo, hi = 1, #text
	local best = ""
	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		local cand = cutAtChar(text, mid)
		if (dxGetTextWidth(cand .. "...", 1, FONT, true) or 0) <= maxW then
			best = cand
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	if #best == 0 then
		-- mirror the old loop's floor: it stopped on a 1-byte prefix and never
		-- went below it, but dropped a multi-byte first character to ""
		local fc = firstChar(text)
		if #fc == 1 then
			best = fc
		end
	end
	return best .. "..."
end

local function layoutCard()
	local maxTextW = sx * MAX_W_FRAC - CHROME_W
	card.text = trimToWidth(card.text, maxTextW)
	local textW = math.min(dxGetTextWidth(card.text, 1, FONT, true) or 0, maxTextW)
	card.w = math.max(MIN_W * scale, CHROME_W + textW * scale)
	card.h = CARD_H * scale
	card.x = math.floor((sx - card.w) / 2)
	card.y = CARD_TOP * scale
	card.textRight = card.x + card.w - TEXT_PAD * scale
	card.hideY = -(card.h + 24 * scale)
end

local function drawCard()
	-- instant early-out: no allocation, no native call, no string work while
	-- there is no card (this is the state between announcements)
	if not card.active then return end

	local now = getTickCount()

	-- lifecycle FIRST, so the card always reaches active=false even while it
	-- is hidden by the sniper scope (the old order returned above this point
	-- and left the per-frame block running for as long as he kept aiming)
	if not card.fading and now >= card.hideAt then
		card.fading = true
		card.outTick = now
	end

	local pOut = 0
	if card.fading then
		pOut = (now - card.outTick) / OUT_MS
		if pOut >= 1 then
			card.active = false
			card.fading = false
			card.hidden = false
			setElementData(localPlayer, "annHeight", 0)
			return
		end
	end

	-- 2 element natives, re-checked at most every 60 ms instead of every frame
	if now >= card.sniperAt then
		card.sniperAt = now + SNIPER_MS
		card.hidden = (getPedWeapon(localPlayer) == 43
			and getPedControlState(localPlayer, "aim_weapon")) and true or false
	end
	if card.hidden then return end

	local pIn = (now - card.tick) / IN_MS
	if pIn < 0 then pIn = 0 elseif pIn > 1 then pIn = 1 end

	local k = pIn
	if card.fading then
		k = k * (1 - pOut)
	end
	if k <= 0 then return end

	local yOff = interpolateBetween(card.hideY, 0, 0, 0, 0, 0, pIn, "OutQuad")
	if card.fading then
		yOff = yOff - pOut * 8 * scale
	end

	local x, y, w, h = card.x, card.y + yOff, card.w, card.h
	local a = math.floor(255 * k)

	-- flat box: 2 rectangles total (hairline frame + fill). The corners used
	-- to cost 4 dxDrawCircle - the expensive part of this function - and the
	-- owner does not care about rounding, only about the red look.
	dxDrawRectangle(x - BORDER, y - BORDER, w + BORDER * 2, h + BORDER * 2,
		tocolor(EDGE_R, EDGE_G, EDGE_B, a), true)
	dxDrawRectangle(x, y, w, h, tocolor(BG_R, BG_G, BG_B, math.floor(BG_A * k)), true)

	dxDrawImage(x + ICON_PAD * scale, y + (h - ICON_SIZE * scale) / 2,
		ICON_SIZE * scale, ICON_SIZE * scale, "megaphone.png",
		0, 0, 0, tocolor(255, 255, 255, a), true)

	dxDrawText(card.text, x + TEXT_X, y, card.textRight, y + h,
		tocolor(255, 255, 255, a),
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
			-- one live sound element: never stack alerts on top of each other
			if card.sound and isElement(card.sound) then
				destroyElement(card.sound)
			end
			card.sound = playSound(playsound .. ".mp3")
		end

		card.text = msg
		if cr and cg and cb then
			card.cr, card.cg, card.cb = cr, cg, cb
		end

		-- every layout value below is computed HERE, once per announcement
		layoutCard()

		card.tick = getTickCount()
		card.hideAt = card.tick + IN_MS + LIFETIME
		card.outTick = 0
		card.sniperAt = 0
		card.hidden = false
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
