--MAXIME

-- ============================================================================
-- [Reference rebuild] /ann surface = the BRIGHT-RED TOP-CENTER PILL from the
-- owner's reference picture (owner: "match EXACTLY").
--
-- Geometry / colour, measured off the reference and expressed as fractions of
-- the screen so it is identical at every resolution:
--   * fill        rgb(222,42,42) - mid-point of the sampled band
--                  rgb(214,38,38)..rgb(230,45,45): a vivid classic red, NOT
--                  the old near-black (94,20,28) and not orange/grey.
--                  Solid (alpha 255), only the enter/exit fade modulates it.
--   * hairline    rgb(194,36,36), BORDER px (1 px at 1080p) - the very
--                  slightly darker edge the reference shows.
--   * size        width 48% of the screen (reference: 45-50%), height 5.5%
--                  of the screen, horizontally centred, top margin 2% of the
--                  screen - there is nothing above it.
--   * corners     radius 25% of the pill height (= 10 px at 720p).
--   * icon        megaphone.png (256x256 flat white silhouette, tilted 30
--                  degrees up-right, 2 sound arcs, baked anti-aliasing),
--                  LEFT inside, ICON_PAD from the left edge (12 px at 720p),
--                  vertically centred, ink height = 55% of the pill height.
--   * text        white default-bold, single line, CENTRED in the space right
--                  of the icon, UTF-8 ellipsis on overflow. No colour, no
--                  "Admin:"/"SUP:" prefix (server.lua sends the raw message).
--
-- [batch 172 kept - this is a restyle, not a rewrite] ALL layout
-- (dxGetTextWidth, UTF-8 ellipsis, box w/h, text edges) runs in postAnn ->
-- layoutCard, i.e. ONCE per announcement. onClientRender never measures text
-- and never builds a string: the ellipsis stays a binary search
-- (O(log n) measurements), the early-out at the top of drawCard is
-- unchanged, the sniper-scope test is still throttled to 60 ms and the
-- lifecycle bookkeeping still runs BEFORE that test (so weapon 43 can never
-- leave the card active). No timers exist on this path: the 8 s hold is tick
-- based (card.hideAt) and the sound element is tracked and destroyed on the
-- next announcement, so nothing piles up.
--
-- The rounded corners are the only thing that used to cost 4 x dxDrawCircle
-- per frame. They are now BAKED, once, into a 2x-supersampled render target
-- (buildPill, guarded by pcall - if the target cannot be created the card
-- falls back to the flat 2-rectangle box and still shows), so the per-frame
-- cost of the background is a single dxDrawImage.
--
-- Unchanged: slide-in 280 ms, hold 8 s, fade-out 350 ms, weapon-43 hide,
-- click-to-copy URL, the pcall-guarded right check in server.lua and the
-- announcement:post / sendTopNotification event contract.
-- ============================================================================

local sx, sy = guiGetScreenSize()

local scale = sy / 1080

local localPlayer = getLocalPlayer()

local FONT = "default-bold"

-- reference geometry -------------------------------------------------------
local CARD_TOP  = math.floor(sy * 0.02)          -- 2% of screen height
local CARD_W    = math.floor(sx * 0.48)           -- 48% of screen width
local CARD_H    = math.floor(sy * 0.055)          -- 5.5% of screen height
local RADIUS    = math.floor(CARD_H * 0.25 + 0.5) -- 10 px at 720p
local ICON_PAD  = CARD_H * 0.30                   -- 12 px at 720p
local ICON_SIZE = CARD_H * 0.61                   -- glyph ink = 55% of pill
local TEXT_GAP  = CARD_H * 0.20
local TEXT_PAD  = CARD_H * 0.30
local FONT_SCALE = CARD_H * 0.032                 -- ~1.9 at 1080p
local CHROME    = ICON_PAD + ICON_SIZE + TEXT_GAP + TEXT_PAD

local SS        = 2      -- supersample factor of the cached pill texture
local BORDER    = math.max(1, math.floor(scale))

local LIFETIME  = 8000
local IN_MS     = 280
local OUT_MS    = 350
local SNIPER_MS = 60

-- reference fill: bright vivid red (+ the very slightly darker hairline)
local BG_R, BG_G, BG_B       = 222, 42, 42
local EDGE_R, EDGE_G, EDGE_B = 194, 36, 36

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
	textLeft = 0, textRight = 0,
	sound = nil,
}

-- the pill background, built once (rounded corners baked in)
local pill = nil

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

-- [batch 172] runs ONLY from layoutCard (once per announcement).
-- One dxGetTextWidth per probe, and the probe count is O(log n) instead of
-- one measurement per removed character.
local function trimToWidth(text, maxW)
	if (dxGetTextWidth(text, FONT_SCALE, FONT, true) or 0) <= maxW then
		return text
	end
	local lo, hi = 1, #text
	local best = ""
	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		local cand = cutAtChar(text, mid)
		if (dxGetTextWidth(cand .. "...", FONT_SCALE, FONT, true) or 0) <= maxW then
			best = cand
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	if #best == 0 then
		local fc = firstChar(text)
		if #fc == 1 then
			best = fc
		end
	end
	return best .. "..."
end

-- rounded rectangle into the CURRENT target - only ever called while a render
-- target is bound, i.e. from buildPill, never per frame
local function roundedBox(x, y, w, h, r, col)
	if w <= 0 or h <= 0 then return end
	if r * 2 > w then r = w / 2 end
	if r * 2 > h then r = h / 2 end
	if r <= 0 then
		dxDrawRectangle(x, y, w, h, col, false)
		return
	end
	dxDrawRectangle(x + r, y, w - 2 * r, h, col, false)
	dxDrawRectangle(x, y + r, w, h - 2 * r, col, false)
	-- full discs at the four corners (the codebase idiom: hud/c_hud.lua
	-- dxDrawRoundedRectangle, adminjail_c.lua) - startAngle/stopAngle come
	-- BEFORE the colours in this client's dxDrawCircle
	dxDrawCircle(x + r, y + r, r, 0, 360, col, col, 64, false)
	dxDrawCircle(x + w - r, y + r, r, 0, 360, col, col, 64, false)
	dxDrawCircle(x + r, y + h - r, r, 0, 360, col, col, 64, false)
	dxDrawCircle(x + w - r, y + h - r, r, 0, 360, col, col, 64, false)
end

-- [reference] build the pill texture ONCE: hairline + fill + rounded corners,
-- drawn at SS x and downscaled by dxDrawImage, so the corners are
-- anti-aliased. Any failure (no VRAM, no RT support) leaves pill == nil and
-- drawCard uses the flat fallback - the card always shows.
local function buildPillAt(ss)
	local tw, th = CARD_W * ss, CARD_H * ss
	local b = BORDER * ss
	local r = RADIUS * ss
	local ok, tex = pcall(dxCreateRenderTarget, tw, th, true)
	if not ok or not isElement(tex) then
		return nil
	end
	local drawn = pcall(function()
		if not dxSetRenderTarget(tex, true) then
			error("cannot bind the pill render target")
		end
		roundedBox(0, 0, tw, th, r, tocolor(EDGE_R, EDGE_G, EDGE_B, 255))
		roundedBox(b, b, tw - 2 * b, th - 2 * b, math.max(0, r - b),
			tocolor(BG_R, BG_G, BG_B, 255))
		dxSetRenderTarget()
	end)
	if not drawn then
		-- never leave a foreign target bound, whatever went wrong
		pcall(dxSetRenderTarget)
		if isElement(tex) then
			destroyElement(tex)
		end
		return nil
	end
	return tex
end

local function buildPill()
	if pill and isElement(pill) then
		return true
	end
	-- 2x first (smooth corners), then a 1x attempt for exotic resolutions
	pill = buildPillAt(SS) or buildPillAt(1)
	return pill ~= nil
end

-- [batch 172] the ONLY place that measures text - once per announcement
local function layoutCard()
	local maxTextW = CARD_W - CHROME
	card.text = trimToWidth(card.text, maxTextW)

	card.x = math.floor((sx - CARD_W) / 2)
	card.y = CARD_TOP
	card.w = CARD_W
	card.h = CARD_H
	card.textLeft  = card.x + CHROME - TEXT_PAD
	card.textRight = card.x + CARD_W - TEXT_PAD
	card.hideY = -(CARD_H + 24 * scale)

	buildPill()
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

	-- [reference] one image for the whole pill: fill + hairline + rounding,
	-- all baked in. The fallback keeps the card visible if the target died.
	if pill and isElement(pill) then
		dxDrawImage(x, y, w, h, pill, 0, 0, 0,
			tocolor(255, 255, 255, a), true)
	else
		dxDrawRectangle(x - BORDER, y - BORDER, w + BORDER * 2, h + BORDER * 2,
			tocolor(EDGE_R, EDGE_G, EDGE_B, a), true)
		dxDrawRectangle(x, y, w, h,
			tocolor(BG_R, BG_G, BG_B, a), true)
	end

	dxDrawImage(x + ICON_PAD, y + (h - ICON_SIZE) / 2, ICON_SIZE, ICON_SIZE,
		"megaphone.png", 0, 0, 0, tocolor(255, 255, 255, a), true)

	dxDrawText(card.text, card.textLeft, y, card.textRight, y + h,
		tocolor(255, 255, 255, a),
		FONT_SCALE, FONT, "center", "center", true, false, true, false, false)
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
