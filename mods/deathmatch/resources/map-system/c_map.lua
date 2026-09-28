--------------------------------------------------------------------------------
-- Vortex map-system — client (Fix #31)
--
-- FULL rebuild on the old client file (backupm/[rp]/radar/radar_c_decompiled.lua),
-- line-for-line behaviour of the F11 big map:
--   * FULLSCREEN world map (map.jpg = world -3000..3000), size = sh * zoom
--   * LEFT MOUSE HOLD  = DRAG the map around (old client drag + clamps)
--   * mouse wheel      = zoom 0.9 .. 3 step 0.1 (old client values)
--   * mouse2           = toggle the cursor (old client)
--   * DOUBLE CLICK     = set the GPS waypoint -> route through the vehicle
--                        road nodes (gps-system A* export) drawn as the old
--                        client's PURPLE wayColor (174,0,255) width 6
--   * 20x20 numbered grid (rows 1-19, columns 21-39) like the old map
--   * radar areas with their colors + "text" data
--   * blips as colored markers sized by the old formula, hover = name
--     tooltip, the sidebar lists every named blip (dbl-click = route)
--   * LEFT sidebar (rounded 1,6,13,230) with the server logo + blip list
--   * zone/city name chip at the cursor, bottom-right
--   * the mini-radar viewport box bottom-left stays BRIGHT (map crop +
--     white corner brackets) while the rest is dimmed - old client look
--   * F11 toggles, chat hidden while open, player arrow (255,55,95)
--   * streamed player dots + staff names (map:seeNames permission)
--
-- Perf note (user rule: zero lag): the old client rendered the map into a
-- fullscreen render target every frame. We draw DIRECTLY on the screen and
-- only re-crop the small radar viewport box - one extra small
-- dxDrawImageSection instead of a fullscreen RT copy every frame.
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

local TEX_SIZE = 1152        -- map.jpg native pixels (6000 world units)
local WORLD = 6000

-- old client wayColor
local WAY_R, WAY_G, WAY_B = 174, 0, 255

local mapVisible = false
local zoom = 3               -- old client default
local offX, offY = 0, 0      -- top-left of the map texture on screen
local clickedCursor = nil    -- {cx, cy, offX, offY} drag anchor
local listRowStart = 1
local listHovered = nil
local hoveredBlip = nil

local waypoint = nil         -- {x, y} GPS target
local route = nil            -- {{x, y}, ...} A* node path

local mapTex, logoTex

-- old client geometry (sidebar on the LEFT of the screen)
local s = sy / 1080
local SB_W = 300 * s
local SB_X = 65 * s
local SB_Y = 65 * s
local SB_H = sy - 130 * s

addEventHandler("onClientResourceStart", resourceRoot, function()
        mapTex = dxCreateTexture("images/map.jpg", "argb", true, "clamp")
        if fileExists(":scoreboard/vortex_logo.png") then
                logoTex = dxCreateTexture(":scoreboard/vortex_logo.png", "argb", true, "clamp")
        end
end)

--------------------------------------------------------------------------------
-- world <-> map-screen mapping (old client: x = rel*6000-3000, y = 3000-rel*6000)
--------------------------------------------------------------------------------

local function mapSize()
        return sy * zoom, sy * zoom
end

local function worldToMap(wx, wy)
        local mw, mh = mapSize()
        return offX + (wx + WORLD / 2) / WORLD * mw,
               offY + (WORLD / 2 - wy) / WORLD * mh
end

local function mapToWorld(sxp, syp)
        local mw, mh = mapSize()
        return (sxp - offX) * WORLD / mw - WORLD / 2,
               WORLD / 2 - (syp - offY) * WORLD / mh
end

-- old client drag clamps: X in [sw/2 - mapW, sw/2 + 500*zoom],
-- Y in [sh/2 - mapH*2, sh/2]
local function clampOffsets()
        local mw, mh = mapSize()
        offX = math.min(math.max(offX, sx / 2 - mw), sx / 2 + 500 * zoom)
        offY = math.min(math.max(offY, sy / 2 - mh * 2), sy / 2)
end

-- open centered on the player (old client centerRadarWithPlayerLocation:
-- the player ends up mid-screen, shifted left by half the sidebar width)
local function centerOnPlayer()
        local px, py = getElementPosition(localPlayer)
        local mw, mh = mapSize()
        offX = sx / 2 - (px + WORLD / 2) / WORLD * mw - SB_W / 2
        offY = sy / 2 - (WORLD / 2 - py) / WORLD * mh
        clampOffsets()
end

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

local function isMouseInPosition(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        if not cx then return false end
        cx, cy = cx * sx, cy * sy
        return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function isHoverMap()
        -- right of the sidebar, whole screen height (old client)
        return isMouseInPosition(SB_X + SB_W, 0, sx - SB_X - SB_W, sy)
end

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY, postGUI)
        local black = tocolor(0, 0, 0, 200)
        dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY, false, false, postGUI)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY, false, false, postGUI)
end

local function playHoverSound()
        if fileExists(":assets/sounds/plastic-bubble-click.wav") then
                playSound(":assets/sounds/plastic-bubble-click.wav", false)
        end
end

--------------------------------------------------------------------------------
-- the big map draw
--------------------------------------------------------------------------------

local namedBlips = {}        -- {{icon, name, color}} for the sidebar list

local function draw()
        if isPlayerMapVisible() then forcePlayerMap(false) end
        if not (getElementData(localPlayer, "loggedin") == 1
                or getElementData(localPlayer, "account:character:id")) then return end

        local mw, mh = mapSize()

        -- old client drag: holding mouse1 over the map pans it
        if isCursorShowing() and getKeyState("mouse1") and isHoverMap() and clickedCursor then
                local dcx, dcy = getCursorPosition()
                if dcx then
                        dcx, dcy = dcx * sx, dcy * sy
                        offX = clickedCursor[3] + (dcx - clickedCursor[1])
                        offY = clickedCursor[4] + (dcy - clickedCursor[2])
                        clampOffsets()
                end
        end

        -- fullscreen tint under the map (old client 2,20,48,120)
        dxDrawRectangle(0, 0, sx, sy, tocolor(2, 20, 48, 120), true)

        -- the REAL world map texture
        if mapTex then
                dxDrawImage(offX, offY, mw, mh, mapTex, 0, 0, 0,
                        tocolor(255, 255, 255, 255), true)
        end

        -- 20x20 numbered grid (rows 1-19 left, columns 21-39 top)
        local gridColor = tocolor(0, 0, 0, 50)
        for i = 1, 19 do
                local gy = offY + mh / 20 * i
                dxDrawRectangle(offX, gy, mw, 1, gridColor, true)
                dxDrawText(tostring(i), offX + 5, gy, offX + mw / 20, gy + 20,
                        tocolor(0, 0, 0, 255), 1, "default-bold", "left", "center", false, false, true)
                local gx = offX + mw / 20 * i
                dxDrawRectangle(gx, offY, 1, mh, gridColor, true)
                dxDrawText(tostring(20 + i), gx + 5, offY, offX + mw / 20 * (i + 1), offY + 20,
                        tocolor(0, 0, 0, 255), 1, "default-bold", "left", "center", false, false, true)
        end

        -- radar areas (colors + optional "text" data)
        for _, area in ipairs(getElementsByType("radararea")) do
                if isElement(area) then
                        local ok, ax, ay = pcall(getElementPosition, area)
                        if ok then
                                local aw, ah = getRadarAreaSize(area)
                                local r, g, b, a = getRadarAreaColor(area)
                                local x0 = offX + (ax + WORLD / 2) / WORLD * mw
                                local y0 = offY + (WORLD / 2 - ay) / WORLD * mh
                                dxDrawRectangle(x0, y0 - ah / WORLD * mh, aw / WORLD * mw,
                                        ah / WORLD * mh, tocolor(r, g, b, a or 255), true)
                                local label = getElementData(area, "text")
                                if label then
                                        dxDrawText(tostring(label), x0, y0 - ah / WORLD * mh,
                                                x0 + aw / WORLD * mw, y0, tocolor(0, 0, 0, 255),
                                                math.max(zoom / 2, 1), "default-bold", "center",
                                                "center", false, false, true, false, true)
                                end
                        end
                end
        end

        -- GPS route: the old client's PURPLE polyline through the road nodes
        if route and #route > 0 then
                local prev = nil
                for _, node in ipairs(route) do
                        if node and node.x and node.y then
                                local nx, ny = worldToMap(node.x, node.y)
                                if prev then
                                        dxDrawLine(prev[1], prev[2], nx, ny,
                                                tocolor(WAY_R, WAY_G, WAY_B, 255), 6, true)
                                end
                                prev = { nx, ny }
                        end
                end
        end

        -- world blips (old formula sizing, hover = name tooltip) + collect
        -- the named ones for the sidebar list
        namedBlips = {}
        local seenNames = {}
        hoveredBlip = nil
        local cxp, cyp
        if isCursorShowing() then
                cxp, cyp = getCursorPosition()
                cxp, cyp = cxp * sx, cyp * sy
        end
        for _, blip in ipairs(getElementsByType("blip")) do
                if isElement(blip) then
                        local attachedTo = getElementAttachedTo(blip)
                        local isPlayerBlip = attachedTo and isElement(attachedTo)
                                and getElementType(attachedTo) == "player"
                        if not isPlayerBlip then
                                local be = (attachedTo and isElement(attachedTo)) and attachedTo or blip
                                local ok, bx, by = pcall(getElementPosition, be)
                                if ok then
                                        local sxp, syp = worldToMap(bx, by)
                                        local size = getBlipSize(blip) or 2
                                        local bsize = 20 * s * (size * math.max(zoom / 2, 1) * 1.3 - 0.5)
                                        local br, bg, bb = getBlipColor(blip)
                                        local bname = getElementData(blip, "blip:name")
                                        if bname and bname ~= "" and not seenNames[bname] then
                                                seenNames[bname] = true
                                                table.insert(namedBlips, {
                                                        icon = getElementData(blip, "icon"),
                                                        name = tostring(bname),
                                                        color = tocolor(br, bg, bb, 255),
                                                })
                                        end
                                        if cxp and isMouseInPosition(sxp - bsize / 2, syp - bsize / 2,
                                                bsize, bsize) and isHoverMap() then
                                                if hoveredBlip ~= blip then
                                                        hoveredBlip = blip
                                                        playHoverSound()
                                                end
                                                if bname and bname ~= "" then
                                                        local tw = dxGetTextWidth(tostring(bname), 1, "default") + 10
                                                        local rows = 1
                                                        local th = dxGetFontHeight(1, "default") * rows + 10
                                                        local tx = sxp - bsize / 2 + (bsize - tw) / 2
                                                        local ty = syp - bsize / 2 - th - 3
                                                        dxDrawRectangle(tx, ty, tw, th, tocolor(0, 0, 0, 230), true)
                                                        dxDrawText(tostring(bname), tx, ty, tx + tw, ty + th,
                                                                tocolor(255, 255, 255, 210), 1, "default",
                                                                "center", "center", false, false, true)
                                                end
                                        end
                                        dxDrawRectangle(sxp - bsize / 2, syp - bsize / 2,
                                                bsize, bsize, tocolor(br, bg, bb, 230), true)
                                end
                        end
                end
        end

        -- streamed players (names for staff only - map:seeNames permission)
        local seeNames = getElementData(localPlayer, "map:seeNames") == true
        for _, player in ipairs(getElementsByType("player")) do
                if player ~= localPlayer and isElement(player) and isElementStreamedIn(player) then
                        if getElementDimension(player) == getElementDimension(localPlayer) then
                                local wx, wy = getElementPosition(player)
                                local sxp, syp = worldToMap(wx, wy)
                                if sxp > 0 and sxp < sx and syp > 0 and syp < sy then
                                        dxDrawRectangle(sxp - 3, syp - 3, 6, 6,
                                                tocolor(255, 255, 255, 220), true)
                                        if seeNames then
                                                local nm = tostring(getElementData(player, "fakename")
                                                        or getPlayerName(player) or ""):gsub("_", " ")
                                                outlineText(nm, sxp - 70, syp - 22, 140, 14,
                                                        tocolor(255, 255, 255, 220), 1, "default-small",
                                                        "center", "top", true)
                                        end
                                end
                        end
                end
        end

        -- the local player: pink arrow (old player.png tint 255,55,95)
        do
                local px, py = getElementPosition(localPlayer)
                local mx, my = worldToMap(px, py)
                local rot = getPedRotation(localPlayer)
                local a = math.rad(-rot)
                local r1, r2 = 16 * s, 12 * s
                local p1x, p1y = mx + math.sin(a) * r1, my - math.cos(a) * r1
                local p2x, p2y = mx + math.sin(a + 2.5) * r2, my - math.cos(a + 2.5) * r2
                local p3x, p3y = mx + math.sin(a - 2.5) * r2, my - math.cos(a - 2.5) * r2
                dxDrawTriangle(p1x, p1y, p2x, p2y, p3x, p3y, tocolor(255, 55, 95, 255), true)
        end

        -- GPS target marker (purple square + live distance)
        if waypoint then
                local sxp, syp = worldToMap(waypoint.x, waypoint.y)
                dxDrawRectangle(sxp - 6, syp - 6, 12, 12,
                        tocolor(WAY_R, WAY_G, WAY_B, 240), true)
                local lpx, lpy = getElementPosition(localPlayer)
                local dist = math.floor(getDistanceBetweenPoints2D(lpx, lpy, waypoint.x, waypoint.y))
                outlineText("نقطة المسار (" .. dist .. " م)", sxp - 90, syp + 10, 180, 16,
                        tocolor(210, 170, 255, 240), 1, "default-bold", "center", "top", true)
        end

        -- ------------------------------------------------------------------
        -- the old client dims the map, then keeps the mini-radar viewport
        -- box BRIGHT with white corner brackets (map stays readable under
        -- the radar); the sidebar + zone chip draw AFTER this (postGUI),
        -- so they stay bright too - exactly the old F11 look
        -- ------------------------------------------------------------------
        dxDrawRectangle(0, 0, sx, sy, tocolor(0, 3, 8, 150), true)
        local bx, by = 15 * (sx / 1920), sy - 175 * (sy / 1080) - 25
        local bw, bh = 290 * (sx / 1920), 175 * (sy / 1080)
        dxDrawRectangle(bx, by, bw, bh, tocolor(2, 20, 48, 255), true)
        if mapTex then
                local texX = (bx - offX) / mw * TEX_SIZE
                local texY = (by - offY) / mh * TEX_SIZE
                local texW = bw / mw * TEX_SIZE
                local texH = bh / mh * TEX_SIZE
                -- clip the source to the texture, adjusting the destination
                local dx0, dy0 = 0, 0
                if texX < 0 then dx0 = -texX / TEX_SIZE * mw; texW = texW + texX; texX = 0 end
                if texY < 0 then dy0 = -texY / TEX_SIZE * mh; texH = texH + texY; texY = 0 end
                if texX + texW > TEX_SIZE then texW = TEX_SIZE - texX end
                if texY + texH > TEX_SIZE then texH = TEX_SIZE - texY end
                if texW > 0 and texH > 0 then
                        dxDrawImageSection(bx + dx0, by + dy0,
                                texW / TEX_SIZE * mw, texH / TEX_SIZE * mh,
                                texX, texY, texW, texH, mapTex, 0, 0, 0,
                                tocolor(255, 255, 255, 220), true)
                end
        end
        local wc = tocolor(255, 255, 255, 255)
        dxDrawRectangle(bx - 5, by - 5, 20, 1, wc, true)
        dxDrawRectangle(bx - 5, by - 5, 1, 20, wc, true)
        dxDrawRectangle(bx + bw - 15, by - 5, 20, 1, wc, true)
        dxDrawRectangle(bx + bw + 5, by - 5, 1, 20, wc, true)
        dxDrawRectangle(bx - 5, by + bh + 5, 20, 1, wc, true)
        dxDrawRectangle(bx - 5, by + bh - 15, 1, 20, wc, true)
        dxDrawRectangle(bx + bw - 15, by + bh + 5, 20, 1, wc, true)
        dxDrawRectangle(bx + bw + 5, by + bh - 15, 1, 20, wc, true)

        -- ------------------------------------------------------------------
        -- sidebar (old client: rounded 1,6,13,230 on the left + blip list)
        -- ------------------------------------------------------------------
        dxDrawRoundedRectangleC(SB_X, SB_Y, SB_W, SB_H, tocolor(1, 6, 13, 230), 8, true)
        dxDrawRectangle(SB_X + SB_W, SB_Y + (SB_H - SB_H / 1.5) / 2, 1, SB_H / 1.5,
                tocolor(104, 102, 255, 120), true)

        local previewY = SB_Y + 50 * s
        if hoveredBlip and isElement(hoveredBlip) then
                local br, bg, bb = getBlipColor(hoveredBlip)
                local size = 50 * s
                dxDrawRectangle(SB_X + (SB_W - size) / 2, previewY, size, size,
                        tocolor(br, bg, bb, 255), true)
                local bname = getElementData(hoveredBlip, "blip:name")
                if bname and bname ~= "" then
                        dxDrawText(tostring(bname), SB_X, previewY + size + 10,
                                SB_X + SB_W, previewY + size + 40,
                                tocolor(255, 255, 255, 255), 1.1, "default-bold",
                                "center", "center", false, false, true)
                end
        elseif logoTex then
                local size = 62 * s
                dxDrawImage(SB_X + (SB_W - size) / 2, previewY, size, size, logoTex,
                        0, 0, 0, tocolor(255, 255, 255, 255), true)
        else
                local size = 62 * s
                dxDrawRoundedRectangleC(SB_X + (SB_W - size) / 2, previewY, size, size,
                        tocolor(12, 16, 26, 220), 10, true)
        end

        -- named-blip list (click a row = route to the nearest such blip)
        listHovered = nil
        local rowY = SB_Y + 50 * s + 62 * s + 80 * s
        local maxRows = math.floor((SB_Y + SB_H - rowY) / (30 * s))
        if maxRows > 0 and listRowStart > math.max(1, #namedBlips - maxRows + 1) then
                listRowStart = math.max(1, #namedBlips - maxRows + 1)
        end
        if #namedBlips > 0 then
                for i = listRowStart, math.min(#namedBlips, listRowStart + maxRows - 1) do
                        local entry = namedBlips[i]
                        if not entry then break end
                        local ry = rowY + (i - listRowStart) * 30 * s
                        if ry + 30 * s > SB_Y + SB_H then break end
                        local hovered = isMouseInPosition(SB_X + 20 * s, ry, SB_W - 20 * s, 30 * s)
                        if hovered then
                                listHovered = entry.name
                                dxDrawRectangle(SB_X + 20 * s, ry, SB_W - 20 * s, 30 * s,
                                        tocolor(255, 255, 255, 24), true)
                        end
                        local cr, cg, cb = bitExtract(entry.color, 16, 8), bitExtract(entry.color, 8, 8), bitExtract(entry.color, 0, 8)
                        dxDrawRectangle(SB_X + 25 * s, ry + 3 * s, 24 * s, 24 * s,
                                tocolor(cr, cg, cb, 255), true)
                        dxDrawText(entry.name, SB_X + 25 * s + 24 * s + 12 * s, ry,
                                SB_X + SB_W, ry + 30 * s, tocolor(cr, cg, cb, 255),
                                1, "default", "left", "center", true, false, true)
                end
        else
                dxDrawText("لا توجد نقاط مسماة", SB_X + 20 * s, rowY, SB_X + SB_W - 20 * s,
                        rowY + 30 * s, tocolor(140, 148, 168, 200), 1, "default",
                        "center", "top", false, false, true)
        end

        -- zone | city chip at the cursor (bottom right, old client)
        if cxp then
                local wx, wy = mapToWorld(cxp, cyp)
                local lzx, lzy, lzz = getElementPosition(localPlayer)
                local zone = getZoneName(wx, wy, lzz)
                local city = getZoneName(wx, wy, lzz, true)
                local full = zone .. " | " .. city
                if full ~= " | " and full:gsub("%s", "") ~= "|" then
                        local tw = dxGetTextWidth(full, 1, "default") + 20 * s
                        local th = 26 * s
                        local tx = sx - tw - 12 * s
                        local ty = sy - th - 12 * s
                        dxDrawRoundedRectangleC(tx, ty, tw, th, tocolor(0, 3, 8, 220), 8, true)
                        dxDrawText(full, tx, ty, tx + tw, ty + th,
                                tocolor(255, 255, 255, 255), 1, "default", "center", "center",
                                false, false, true)
                end
        end
end

-- small rounded-rect helper (slice style, matches the HUD/tab family)
function dxDrawRoundedRectangleC(x, y, w, h, color, radius, postGUI)
        local r = math.min(radius or 8, h / 2, w / 2)
        if r < 2 then
                dxDrawRectangle(x, y, w, h, color, postGUI)
                return
        end
        dxDrawRectangle(x, y + r, w, h - 2 * r, color, postGUI)
        local step = math.max(1, r / 16)
        local i = 0
        while i < r do
                local dh = math.sqrt(r * r - (r - i) * (r - i))
                local sw = w - 2 * (r - dh)
                local th = step + 0.75
                dxDrawRectangle(x + r - dh, y + i, sw, th, color, postGUI)
                dxDrawRectangle(x + r - dh, y + h - i - th, sw, th, color, postGUI)
                i = i + step
        end
end

--------------------------------------------------------------------------------
-- GPS: double click = route (old client ChosePoint)
--------------------------------------------------------------------------------

local function setGPSClicked(wx, wy)
        waypoint = { x = wx, y = wy }
        route = nil
        local ok, err = pcall(function()
                local ex = exports["gps-system"]
                if ex and getResourceFromName("gps-system")
                        and getResourceState(getResourceFromName("gps-system")) == "running" then
                        local px2, py2, pz2 = getElementPosition(localPlayer)
                        local gz = getGroundPosition(wx, wy, 1500)
                        route = ex:calculatePathByCoords(wx, wy, gz or 0, px2, py2, pz2 or 0)
                end
        end)
        if not ok or not route or type(route) ~= "table" or #route == 0 then
                route = nil -- the purple target still works without the engine
        end
        outputChatBox("#a855f7[MAP]#ffffff تم تعيين نقطة المسار على الخريطة.", 255, 255, 255, true)
end

local function routeToNamedBlip(name)
        local px, py = getElementPosition(localPlayer)
        local best, bestDist = nil, math.huge
        for _, blip in ipairs(getElementsByType("blip")) do
                if isElement(blip) and getElementData(blip, "blip:name") == name then
                        local attachedTo = getElementAttachedTo(blip)
                        local be = (attachedTo and isElement(attachedTo)) and attachedTo or blip
                        local ok, bx, by = pcall(getElementPosition, be)
                        if ok then
                                local d = getDistanceBetweenPoints2D(px, py, bx, by)
                                if d < bestDist then bestDist = d; best = { bx, by } end
                        end
                end
        end
        if best then setGPSClicked(best[1], best[2]) end
end

--------------------------------------------------------------------------------
-- open / close (old client cancelRadar)
--------------------------------------------------------------------------------

local function onMapClick(button, press, ax, ay)
        if button ~= "left" or not press or not mapVisible then return end
        if isHoverMap() then
                -- drag anchor (old client click handler)
                clickedCursor = { ax, ay, offX, offY }
        elseif getKeyState("mouse1") == false then
                clickedCursor = nil
        end
end

local function setVisible(state)
        if state == mapVisible then return end
        mapVisible = state
        if mapVisible then
                forcePlayerMap(false)
                showCursor(true)
                showChat(false)
                centerOnPlayer()
                addEventHandler("onClientRender", root, draw, false, "low-20")
                addEventHandler("onClientClick", root, onMapClick)
        else
                removeEventHandler("onClientRender", root, draw)
                removeEventHandler("onClientClick", root, onMapClick)
                showCursor(false)
                showChat(true)
                clickedCursor = nil
        end
end

addEventHandler("onClientDoubleClick", root, function(button, ax, ay)
        if not mapVisible or button ~= "left" then return end
        if isHoverMap() then
                local wx, wy = mapToWorld(ax, ay)
                setGPSClicked(wx, wy)
        elseif listHovered then
                routeToNamedBlip(listHovered)
        end
end)

addEventHandler("onClientKey", root, function(key, press)
        -- F11 toggle (old client cancelRadar: onClientKey owns F11, no bindKey)
        if key == "F11" and press then
                if getElementData(localPlayer, "loggedin") ~= 1
                        and not getElementData(localPlayer, "account:character:id") then
                        return
                end
                setVisible(not mapVisible)
                cancelEvent()
                return
        end
        if not mapVisible or not press then return end
        if key == "mouse_wheel_down" or key == "mouse_wheel_up" then
                if isHoverMap() then
                        local oldW = select(1, mapSize())
                        if key == "mouse_wheel_down" then
                                zoom = math.max(0.9, zoom - 0.1)
                        else
                                zoom = math.min(3, zoom + 0.1)
                        end
                        local newW = select(1, mapSize())
                        offX = offX - (newW - oldW) / 2
                        offY = offY - (newW - oldW) / 2
                        clampOffsets()
                else
                        if key == "mouse_wheel_down" then
                                listRowStart = listRowStart + 1
                        else
                                listRowStart = math.max(1, listRowStart - 1)
                        end
                end
                cancelEvent()
        elseif key == "mouse2" then
                showCursor(not isCursorShowing())
                cancelEvent()
        end
end)

addCommandHandler("clearway", function()
        waypoint = nil
        route = nil
        outputChatBox("#a855f7[MAP]#ffffff تم حذف نقطة المسار.", 255, 255, 255, true)
end)

-- re-center when the character spawns (old client onClientCharacterSpawn)
addEvent("accounts:character:select", true)
addEventHandler("accounts:character:select", root, function()
        if mapVisible then centerOnPlayer() end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        if mapVisible then
                removeEventHandler("onClientRender", root, draw)
                showCursor(false)
                showChat(true)
        end
end)
