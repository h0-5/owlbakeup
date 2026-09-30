--[[ =========================================================================
        c_radar.lua — Vortex RADAR (Fix #55, visual restore Fix #62)

        Faithful rebuild of the OLD CLIENT radar
        (backupm [rp]/radar/radar_c_decompiled.lua).  The decompile shipped
        NO images and its upvalues were mangled, so this is a clean-room
        rebuild with the SAME geometry, formulas, event names and behavior:

          * MINIMAP (camera-up, bottom-left): x=15, y = sh - 175*(sh/1080) - 25,
            290x175 (scaled), render-target clipped, dark map texture
            (images/map.jpg 1152px covering the 6000x6000 world), player
            anchored at 62% height, blips rotated by
            findRotation(blip) - camRot (old formula), player arrow
            camRot - pedRot (old formula), "N" compass on the edge,
            radar-area outlines within 600u, purple GPS route lines,
            dispatch elements with labels.
          * F11 BIG MAP: fullscreen dark overlay, grid 20x20 with labels,
            radar areas FILLED (+ optional "text" data), all named blips with
            hover tooltip (blip:name) + click sound (:assets), sidebar with
            the hovered blip + the full named-blip list (click = route to the
            nearest one), zone tooltip "City | Zone" at the cursor, white
            corner brackets, drag-pan, wheel zoom, double-click = GPS route.
          * GPS ROUTE: clean Dijkstra over the ORIGINAL nodes.lua vehicleNodes
            (64 areas of 750x750, id = area*65536 + local), purple way color
            (174, 0, 255 - old), invisible route markers that get consumed as
            you drive (old marker + colshape behavior).
          * owl adaptations (documented):
              - old gate "inventory-system:playerHasItem('GPS')" dropped ->
                the minimap shows for every logged-in character (owl has no
                GPS item; matches the approved reference screenshot)
              - island.png overlay dropped (owl has no custom island)
              - ":assets/sounds/plastic-bubble-click.wav" kept (exists here)
              - onClientCharacterSpawn / onClientPlayerQuitFromCharacter kept
                (both exist in owl: hud/account)
              - UIKit fonts resolved lazily (Fix #46 class: UIKit may not be
                running when this resource starts)
          * events kept: radar:showRadar, radar:onFindBestWay (server),
            radar:findBestWay:sync (server -> vehicle occupants)
          * Fix #62 (visual restore from the old decompile):
              - minimap blip hover scale 1.3x (old formula var31 * (zoom...*1.3-0.5))
              - minimap dispatch elements draw the black label strip with the
                dispatch text next to the icon (old unpack(dispatch) label)
              - minimap GPS route line width 8 (old)
              - big-map route line width scales with zoom (old)
              - big-map player arrow is plain white (old) - the pink tint was
                the rebuild's own addition
              - big-map sidebar: server logo (:assets/images/logo.png) behind
                the hovered blip icon at 1.5x size (old)
              - big-map min zoom 0.9 (old)
========================================================================= ]]

local localPlayer = getLocalPlayer()

local sx, sy = guiGetScreenSize()
local SCALE = sy / 1080

local WORLD = 6000                 -- world span covered by the map image
local MAP_IMG = 1152               -- images/map.jpg pixel size
local WAY_COLOR = tocolor(174, 0, 255, 255) -- old client purple

local RADAR = {
        x = 15,
        y = sy - 175 * SCALE - 25,
        w = 290 * SCALE,
        h = 175 * SCALE,
        visible = false,
        mapVisible = false,
        MINIMAP_UNITS = 700,       -- world units across the minimap width
        PLAYER_ANCHOR_Y = 0.62,    -- player sits at 62% of the minimap height
}

local ZONE_COLORS = {              -- dispatch blip colors (old list artifact)
        tocolor(255, 80, 80, 255),
        tocolor(90, 160, 255, 255),
        tocolor(255, 200, 80, 255),
}

--------------------------------------------------------------------------------
-- lazy UIKit fonts (Fix #46 class - UIKit may not be running at start)
--------------------------------------------------------------------------------
local fontMap, fontMapLarge = "default", "default-bold"
local themePrimary = tocolor(104, 102, 255, 255)

local function UIKitReady()
        pcall(function()
                fontMap = exports.UIKit:getUIFont("ui-default") or "default"
                fontMapLarge = exports.UIKit:getUIFont("default-large") or "default-bold"
        end)
        pcall(function()
                local c = exports.UIKit:uiGetThemeColor("primary")
                if type(c) == "table" and c.r then
                        themePrimary = tocolor(c.r, c.g, c.b, 255)
                end
        end)
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

--------------------------------------------------------------------------------
-- map texture + render target
--------------------------------------------------------------------------------
local mapTex, rt

local function ensureTexture()
        if not isElement(mapTex) then
                mapTex = dxCreateTexture("images/map.jpg", "argb", true, "clamp")
        end
end

--------------------------------------------------------------------------------
-- old client math helpers (verbatim)
--------------------------------------------------------------------------------
local function findRotation(x1, y1, x2, y2)
        return -math.deg(math.atan2(x2 - x1, y2 - y1)) + 360
end

local function getPointFromDistanceRotation(x, y, dist, angle)
        local a = math.rad(90 - angle)
        return x + math.cos(a) * dist, y + math.sin(a) * dist
end

local function getCamRotDeg()
        local ok, _, _, rz = pcall(getCameraRotation)
        if not ok then return 0 end
        return math.deg(rz or 0) % 360
end

local function worldToMapPx(wx, wy, drawSize)
        return (wx + WORLD / 2) / WORLD * drawSize, (WORLD / 2 - wy) / WORLD * drawSize
end

--------------------------------------------------------------------------------
-- blip icon resolution (elementData "icon" string OR MTA blip icon number)
--------------------------------------------------------------------------------
local iconCache = {}

local function iconPath(blip)
        local key = tostring(getElementData(blip, "icon") or getBlipIcon(blip) or 0)
        if iconCache[key] == nil then
                local path = "images/blip/" .. key .. ".png"
                iconCache[key] = fileExists(path) and path or "images/blip/0.png"
        end
        return iconCache[key]
end

local function blipColor(blip)
        local c = getElementData(blip, "blip:color")
        if type(c) == "string" and #c >= 7 and string.sub(c, 1, 1) == "#" then
                local r = tonumber(string.sub(c, 2, 3), 16) or 255
                local g = tonumber(string.sub(c, 4, 5), 16) or 255
                local b = tonumber(string.sub(c, 6, 7), 16) or 255
                return tocolor(r, g, b, 255)
        elseif type(c) == "table" and c[1] then
                return tocolor(c[1], c[2] or 255, c[3] or 255, 255)
        end
        return tocolor(255, 255, 255, 255)
end

--------------------------------------------------------------------------------
-- GPS route state
--------------------------------------------------------------------------------
local route = nil                 -- {{x,y,z}...}
local routeColor = WAY_COLOR
local routeMarkers = {}           -- consumed while driving (old behavior)
local lastMarkerX, lastMarkerY = 0, 0

local function destroyRouteMarkers()
        for i, m in ipairs(routeMarkers) do
                if isElement(m.marker) then destroyElement(m.marker) end
                if isElement(m.col) then destroyElement(m.col) end
        end
        routeMarkers = {}
end

--------------------------------------------------------------------------------
-- MINIMAP helpers
--------------------------------------------------------------------------------
local function minimapAnchor()
        return RADAR.w / 2, RADAR.h * RADAR.PLAYER_ANCHOR_Y
end

local function minimapBlipPoint(wx, wy, camRot, px, py)
        local pxPerUnit = RADAR.w / RADAR.MINIMAP_UNITS
        local d = getDistanceBetweenPoints2D(px, py, wx, wy) * pxPerUnit
        local bearing = findRotation(px, py, wx, wy) - camRot
        local ox, oy = getPointFromDistanceRotation(0, 0, d, bearing)
        local ax, ay = minimapAnchor()
        return ax + ox, ay - oy
end

--------------------------------------------------------------------------------
-- MINIMAP draw (into the render target, then blitted)
--------------------------------------------------------------------------------
local function drawMinimapContent()
        local camRot = getCamRotDeg()
        local px, py = getElementPosition(localPlayer)
        local ax, ay = minimapAnchor()
        local pxPerUnit = RADAR.w / RADAR.MINIMAP_UNITS
        local mapDrawSize = WORLD * pxPerUnit

        -- the map image, rotated with the camera (old: rot = camRot),
        -- pivoting around the player's own pixel inside the image
        local pimgx, pimgy = worldToMapPx(px, py, mapDrawSize)
        if isElement(mapTex) then
                dxDrawImage(ax - pimgx, ay - pimgy, mapDrawSize, mapDrawSize, mapTex,
                        camRot, pimgx, pimgy)
        else
                dxDrawRectangle(0, 0, RADAR.w, RADAR.h, tocolor(10, 10, 12, 255))
        end

        -- radar areas (turf etc.): outlined within 600u (old rule)
        local mx, my, _ = getElementPosition(localPlayer)
        for _, area in ipairs(getElementsByType("radararea")) do
                local axp, ayp = getRadarAreaPosition(area)
                local asx, asy = getRadarAreaSize(area)
                local cxp, cyp = axp + asx / 2, ayp + asy / 2
                if getDistanceBetweenPoints2D(mx, my, cxp, cyp) <= 600 then
                        local r, g, b, a = getRadarAreaColor(area)
                        local col = tocolor(r, g, b, math.min(a, 200))
                        local pts = {}
                        pts[1] = { minimapBlipPoint(axp, ayp, camRot, px, py) }
                        pts[2] = { minimapBlipPoint(axp + asx, ayp, camRot, px, py) }
                        pts[3] = { minimapBlipPoint(axp + asx, ayp + asy, camRot, px, py) }
                        pts[4] = { minimapBlipPoint(axp, ayp + asy, camRot, px, py) }
                        for i = 1, 4 do
                                local p1, p2 = pts[i], pts[i % 4 + 1]
                                dxDrawLine(p1[1], p1[2], p2[1], p2[2], col, 2)
                        end
                end
        end

        -- GPS route (purple, old; Fix #62: old minimap line was 8px wide)
        if route and #route > 1 then
                for i = 1, #route - 1 do
                        local x1, y1 = minimapBlipPoint(route[i][1], route[i][2], camRot, px, py)
                        local x2, y2 = minimapBlipPoint(route[i + 1][1], route[i + 1][2], camRot, px, py)
                        dxDrawLine(x1, y1, x2, y2, routeColor, 8 * SCALE)
                end
        end

        -- blips
        for _, blip in ipairs(getElementsByType("blip")) do
                if getElementDimension(blip) == getElementDimension(localPlayer)
                        and getElementInterior(blip) == 0 then
                        local bx, by, _ = getElementPosition(blip)
                        if getDistanceBetweenPoints2D(px, py, bx, by) <= getBlipVisibleDistance(blip) then
                                local ix, iy = minimapBlipPoint(bx, by, camRot, px, py)
                                -- Fix #62: old client scales the hovered blip by 1.3x
                                local hover = 1
                                if isCursorShowing() and getCursorPosition() then
                                        local cx, cy = getCursorPosition()
                                        cx, cy = cx * sx, cy * sy
                                        local hsz = 14 * SCALE
                                        if cx >= ix - hsz / 2 and cx <= ix + hsz / 2
                                                and cy >= iy - hsz / 2 and cy <= iy + hsz / 2 then
                                                hover = 1.3
                                        end
                                end
                                local size = getBlipSize(blip) * 8 * SCALE * hover
                                dxDrawImage(ix - size / 2, iy - size / 2, size, size,
                                        iconPath(blip), 0, 0, 0, blipColor(blip))
                        end
                end
        end

        -- dispatch elements (elementData "dispatch" = label parts)
        for _, elm in pairs(RADAR.dispatchElements or {}) do
            if isElement(elm) and getElementData(elm, "dispatch")
                and getElementDimension(elm) == getElementDimension(localPlayer) then
                local dxp, dyp, _ = getElementPosition(elm)
                if getDistanceBetweenPoints2D(px, py, dxp, dyp) <= 500 then
                        local ix, iy = minimapBlipPoint(dxp, dyp, camRot, px, py)
                        local size = 14 * SCALE
                        -- Fix #62: old client drew a black label strip with the
                        -- dispatch text (unpack(dispatch)) next to the blip icon
                        local parts = getElementData(elm, "dispatch")
                        local label = type(parts) == "table" and tostring(parts[1] or "") or ""
                        if label ~= "" then
                                local lw = dxGetTextWidth(label, 1, "default-bold") + 5
                                dxDrawRectangle(ix + size / 2 + 20 * SCALE, iy - size / 2 + 3 * SCALE,
                                        lw, 12 * SCALE, tocolor(0, 0, 0, 200), false)
                                dxDrawText(label, ix + size / 2 + 20 * SCALE, iy - size / 2,
                                        ix + size / 2 + 20 * SCALE + lw, iy - size / 2 + 14 * SCALE,
                                        tocolor(255, 255, 255, 255), 1, "default-bold", "left", "top", false, false, false, false, true)
                        end
                        dxDrawImage(ix - size / 2, iy - size / 2, size, size,
                                "images/blip/0.png", 0, 0, 0, ZONE_COLORS[1])
                end
            end
        end

        -- local player arrow (old rotation formula)
        local pedRot = getPedRotation(localPlayer)
        dxDrawImage(ax - 9 * SCALE, ay - 9 * SCALE, 18 * SCALE, 18 * SCALE,
                "images/player.png", camRot - pedRot, 0, 0, tocolor(255, 255, 255, 255))
end

local function drawMinimap()
        if not isElement(rt) then
                rt = dxCreateRenderTarget(RADAR.w, RADAR.h, true)
                if not rt then
                        -- old fallback: native radar when the RT cannot be created
                        setPlayerHudComponentVisible("radar", true)
                        return
                end
        end
        dxSetRenderTarget(rt, true)
        drawMinimapContent()
        dxSetRenderTarget()

        -- blit + frame (white hairlines like the old client; top+left brighter
        -- like the approved reference shot)
        local x, y, w, h = RADAR.x, RADAR.y, RADAR.w, RADAR.h
        dxDrawImage(x, y, w, h, rt)
        dxDrawRectangle(x, y, w, 1, tocolor(255, 255, 255, 40))
        dxDrawRectangle(x, y + h - 1, w, 1, tocolor(255, 255, 255, 40))
        dxDrawRectangle(x, y, 1, h, tocolor(255, 255, 255, 40))
        dxDrawRectangle(x + w - 1, y, 1, h, tocolor(255, 255, 255, 40))
        dxDrawRectangle(x, y, w, 2, tocolor(255, 255, 255, 130))
        dxDrawRectangle(x, y, 2, h, tocolor(255, 255, 255, 130))

        -- "N" compass pinned to the map edge along the north bearing (old look)
        local camRot = getCamRotDeg()
        local px, py = getElementPosition(localPlayer)
        local nx, ny = minimapBlipPoint(px, py - 1000, camRot, px, py)
        local ax, ay = minimapAnchor()
        local vx, vy = nx - ax, ny - ay
        local len = math.sqrt(vx * vx + vy * vy)
        if len > 1 then
                -- clamp to the rect edge
                local halfW, halfH = RADAR.w / 2 - 12 * SCALE, RADAR.h / 2 - 12 * SCALE
                local t = math.min(halfW / math.abs(vx), halfH / math.abs(vy))
                local ex, ey = ax + vx * t, ay + vy * t
                if ex < x + 8 * SCALE then ex = x + 8 * SCALE end
                if ex > x + w - 8 * SCALE then ex = x + w - 8 * SCALE end
                if ey < y + 8 * SCALE then ey = y + 8 * SCALE end
                if ey > y + h - 8 * SCALE then ey = y + h - 8 * SCALE end
                dxDrawText("N", ex - 10 * SCALE, ey - 10 * SCALE, ex + 10 * SCALE, ey + 10 * SCALE,
                        tocolor(255, 255, 255, 230), 1, fontMapLarge, "center", "center")
        end
end

--------------------------------------------------------------------------------
-- BIG MAP (F11)
--------------------------------------------------------------------------------
local BIG = {
        zoom = 1,
        minZoom = 0.9,             -- Fix #62: old client allowed zooming out to 0.9
        maxZoom = 3,
        mapH = 0,                  -- drawn map height in px (sy at zoom 1)
        offX = 0,                  -- top-left of the drawn map on screen
        offY = 0,
        dragging = false,
        dragX = 0,
        dragY = 0,
        anchorX = 0,
        anchorY = 0,
        hovered = false,
        sidebarList = {},
}

local function bigMapSize()
        BIG.mapH = sy * BIG.zoom
end

local function bigMapClamp()
        bigMapSize()
        local minX = sx - 300 * SCALE - BIG.mapH
        BIG.offX = math.min(math.max(BIG.offX, minX), sx - 300 * SCALE)
        BIG.offY = math.min(math.max(BIG.offY, sy - BIG.mapH), 0)
end

local function bigMapCenterOnPlayer()
        bigMapSize()
        local px, py = getElementPosition(localPlayer)
        local mx, my = worldToMapPx(px, py, BIG.mapH)
        BIG.offX = (sx - 300 * SCALE) / 2 - mx
        BIG.offY = sy / 2 - my
        bigMapClamp()
end

local function bigMapToWorld(cursX, cursY)
        return (cursX - BIG.offX) * WORLD / BIG.mapH - WORLD / 2,
               WORLD / 2 - (cursY - BIG.offY) * WORLD / BIG.mapH
end

local function bigMapIsHover(cursX, cursY)
        return cursX >= 0 and cursX <= sx - 300 * SCALE and cursY >= 0 and cursY <= sy
end

local function bigMapWorldPoint(wx, wy)
        local mx, my = worldToMapPx(wx, wy, BIG.mapH)
        return BIG.offX + mx, BIG.offY + my
end

local function bigMapDraw()
        local px, py = getElementPosition(localPlayer)
        dxDrawRectangle(0, 0, sx, sy, tocolor(2, 20, 48, 120), false)
        if isElement(mapTex) then
                dxDrawImage(BIG.offX, BIG.offY, BIG.mapH, BIG.mapH, mapTex, 0, 0, 0,
                        tocolor(255, 255, 255, 255), false)
        end

        -- 20x20 grid with labels (old)
        for i = 1, 19 do
                local gy = BIG.offY + BIG.mapH / 20 * i
                if gy > 0 and gy < sy then
                        dxDrawRectangle(0, gy, sx - 300 * SCALE, 1, tocolor(0, 0, 0, 50), false)
                        dxDrawText(tostring(i), 5, gy + 2, 60, gy + 20, tocolor(0, 0, 0, 255), 1, "default-bold", "left", "top", false, false, false, false, true)
                end
                local gx = BIG.offX + BIG.mapH / 20 * i
                if gx > 0 and gx < sx - 300 * SCALE then
                        dxDrawRectangle(gx, 0, 1, sy, tocolor(0, 0, 0, 50), false)
                        dxDrawText(tostring(20 + i), gx + 5, 2, gx + 60, 22, tocolor(0, 0, 0, 255), 1, "default-bold", "left", "top", false, false, false, false, true)
                end
        end

        -- radar areas filled + optional "text" (old)
        for _, area in ipairs(getElementsByType("radararea")) do
                local axp, ayp = getRadarAreaPosition(area)
                local asx, asy = getRadarAreaSize(area)
                local x1, y1 = bigMapWorldPoint(axp, ayp + asy)
                local x2, y2 = bigMapWorldPoint(axp + asx, ayp)
                local r, g, b, a = getRadarAreaColor(area)
                dxDrawRectangle(x1, y1, x2 - x1, y2 - y1, tocolor(r, g, b, math.min(a, 180)), false)
                local txt = getElementData(area, "text")
                if txt then
                        dxDrawText(txt, x1, y1, x2, y2, tocolor(0, 0, 0, 255), 1 * math.max(BIG.zoom / 2, 1),
                                "default-bold", "center", "center", false, false, false, false, true, -20)
                end
        end

        -- GPS route (Fix #62: old big-map route line = 6px scaled with zoom)
        if route and #route > 1 then
                for i = 1, #route - 1 do
                        local x1, y1 = bigMapWorldPoint(route[i][1], route[i][2])
                        local x2, y2 = bigMapWorldPoint(route[i + 1][1], route[i + 1][2])
                        dxDrawLine(x1, y1, x2, y2, routeColor, 6 * math.max(BIG.zoom / 2, 1), false)
                end
        end

        -- blips + tooltips + sidebar list collection
        local hoveredName = nil
        local seen = {}
        BIG.sidebarList = {}
        local cursX, cursY = -1, -1
        if isCursorShowing() then
                cursX, cursY = getCursorPosition()
                cursX, cursY = cursX * sx, cursY * sy
        end
        for _, blip in ipairs(getElementsByType("blip")) do
                if getElementDimension(blip) == 0 and getElementInterior(blip) == 0 then
                        local bx, by, _ = getElementPosition(blip)
                        local wx, wy = bigMapWorldPoint(bx, by)
                        local size = 14 * SCALE * math.max(BIG.zoom / 2, 1)
                        local name = getElementData(blip, "blip:name")
                        if name and not seen[name] then
                                seen[name] = true
                                table.insert(BIG.sidebarList, {
                                        icon = iconPath(blip),
                                        name = name,
                                        color = blipColor(blip),
                                        wx = bx, wy = by,
                                })
                        end
                        if cursX >= wx - size / 2 and cursX <= wx + size / 2
                                and cursY >= wy - size / 2 and cursY <= wy + size / 2 then
                                if BIG.hovered ~= blip then
                                        BIG.hovered = blip
                                        pcall(playSound, ":assets/sounds/plastic-bubble-click.wav")
                                end
                                if name then
                                        hoveredName = name
                                        local tw = dxGetTextWidth(name, 1, fontMap) + 10
                                        local th = dxGetFontHeight(1, fontMap) + 10
                                        dxDrawRectangle(wx - tw / 2, wy - size / 2 - th - 3, tw, th,
                                                tocolor(0, 0, 0, 230), false)
                                        dxDrawText(name, wx - tw / 2, wy - size / 2 - th - 3,
                                                wx + tw / 2, wy - size / 2 - 3,
                                                tocolor(255, 255, 255, 210), 1, fontMap, "center", "center")
                                end
                        end
                        dxDrawImage(wx - size / 2, wy - size / 2, size, size,
                                iconPath(blip), 0, 0, 0, blipColor(blip), false)
                end
        end

        -- player arrow (Fix #62: old client drew it plain white on the big map)
        local pwx, pwy = bigMapWorldPoint(px, py)
        local psize = 21 * SCALE
        dxDrawImage(pwx - psize / 2, pwy - psize / 2, psize, psize, "images/player.png",
                -getPedRotation(localPlayer), 0, 0, tocolor(255, 255, 255, 255), false)

        -- dispatch elements
        for _, elm in pairs(RADAR.dispatchElements or {}) do
            if isElement(elm) and getElementData(elm, "dispatch") then
                local dxp, dyp, _ = getElementPosition(elm)
                local wx, wy = bigMapWorldPoint(dxp, dyp)
                local size = 18 * SCALE
                dxDrawImage(wx - size / 2, wy - size / 2, size, size, "images/blip/0.png",
                        0, 0, 0, ZONE_COLORS[1], false)
            end
        end

        -- sidebar (old: 300px dark panel on the right)
        local sbx = sx - 300 * SCALE
        local sby = 60 * SCALE + 5 * SCALE
        local sbw = 300 * SCALE
        local sbh = sy - 60 * SCALE * 2 - 10 * SCALE
        dxDrawRectangle(sbx, sby, sbw, sbh, tocolor(1, 6, 13, 230), false)
        dxDrawRectangle(sbx + sbw, sby + (sbh - sbh / 1.5) / 2, 1, sbh / 1.5, themePrimary, false)
        dxDrawText("MAP", sbx + 15 * SCALE, sby + 12 * SCALE, sbx + sbw - 15 * SCALE,
                sby + 40 * SCALE, tocolor(255, 255, 255, 220), 1, fontMapLarge, "left", "center")
        if BIG.hovered and isElement(BIG.hovered) then
                -- Fix #62: old sidebar = server logo behind the hovered blip icon,
                -- blip icon over it, name below in the blip's own color
                local size = 50 * SCALE
                local hx = sbx + (sbw - size * 1.5) / 2
                local lsize = size * 1.5
                if fileExists(":assets/images/logo.png") then
                        dxDrawImage(hx, sby + 50 * SCALE, lsize, lsize,
                                ":assets/images/logo.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
                end
                dxDrawImage(sbx + (sbw - size) / 2, sby + 50 * SCALE, size, size,
                        iconPath(BIG.hovered), 0, 0, 0, blipColor(BIG.hovered), false)
                local nm = getElementData(BIG.hovered, "blip:name")
                if nm then
                        dxDrawText(nm, sbx, sby + 50 * SCALE + size + 10, sbx + sbw,
                                sby + 50 * SCALE + size + 40, blipColor(BIG.hovered), 1,
                                fontMapLarge, "center", "center")
                end
        end
        -- named blip list (click a row = route to the nearest blip with that name)
        local rowY = sby + 50 * SCALE + 80 * SCALE
        for idx, item in ipairs(BIG.sidebarList) do
                if rowY + 30 * SCALE > sy then break end
                local rowH = 30 * SCALE
                local hoveredRow = isCursorShowing()
                        and getCursorPosition() and
                        (getCursorPosition() * sx >= sbx + 20 * SCALE and getCursorPosition() * sy >= rowY
                        and getCursorPosition() * sx <= sbx + sbw and getCursorPosition() * sy <= rowY + rowH)
                if hoveredRow then
                        dxDrawRectangle(sbx + 10 * SCALE, rowY, sbw - 20 * SCALE, rowH,
                                tocolor(104, 102, 255, 60), false)
                        BIG.listHover = item.name
                end
                local iconSize = 22 * SCALE
                dxDrawImage(sbx + 25 * SCALE, rowY + (rowH - iconSize) / 2, iconSize, iconSize,
                        item.icon, 0, 0, 0, item.color, false)
                dxDrawText(item.name, sbx + 25 * SCALE + iconSize + 12 * SCALE, rowY,
                        sbx + sbw - 10 * SCALE, rowY + rowH, item.color, 1, fontMap, "left", "center")
                rowY = rowY + rowH + 2 * SCALE
        end

        -- zone tooltip at the cursor (old "City | Zone")
        if isCursorShowing() and cursX >= 0 and bigMapIsHover(cursX, cursY) then
                local wx, wy = bigMapToWorld(cursX, cursY)
                local _, _, pz = getElementPosition(localPlayer)
                local zone = getZoneName(wx, wy, pz, false)
                local city = getZoneName(wx, wy, pz, true)
                if zone ~= "" then
                        local label = city .. " | " .. zone
                        local tw = dxGetTextWidth(label, 1, fontMap) + 20 * SCALE
                        dxDrawRectangle(cursX - tw / 2, cursY - 30 * SCALE, tw, 24 * SCALE,
                                tocolor(0, 3, 8, 220), false)
                        dxDrawText(label, cursX - tw / 2, cursY - 30 * SCALE,
                                cursX + tw / 2, cursY - 6 * SCALE,
                                tocolor(255, 255, 255, 255), 1, fontMap, "center", "center")
                end
        end

        -- white corner brackets (old)
        local bx, by, bw, bh = 10, 10, sx - 300 * SCALE - 20, sy - 20
        dxDrawRectangle(bx, by, 20, 1, tocolor(255, 255, 255))
        dxDrawRectangle(bx, by, 1, 20, tocolor(255, 255, 255))
        dxDrawRectangle(bx + bw - 20, by, 20, 1, tocolor(255, 255, 255))
        dxDrawRectangle(bx + bw, by, 1, 20, tocolor(255, 255, 255))
        dxDrawRectangle(bx, by + bh, 20, 1, tocolor(255, 255, 255))
        dxDrawRectangle(bx, by + bh - 20, 1, 20, tocolor(255, 255, 255))
        dxDrawRectangle(bx + bw - 20, by + bh, 20, 1, tocolor(255, 255, 255))
        dxDrawRectangle(bx + bw, by + bh - 20, 1, 20, tocolor(255, 255, 255))
end

--------------------------------------------------------------------------------
-- GPS route (Dijkstra over the original vehicleNodes data)
--------------------------------------------------------------------------------
local function getAreaID(x, y)
        return math.floor((y + WORLD / 2) / 750) * 8 + math.floor((x + WORLD / 2) / 750)
end

local function getNodeByID(id)
        local area = math.floor(id / 65536)
        if vehicleNodes and vehicleNodes[area] then
                return vehicleNodes[area][id]
        end
end

local function findNodePosition(x, y)
        local area = vehicleNodes and vehicleNodes[getAreaID(x, y)]
        if not area then return nil end
        local best, bestD = nil, math.huge
        for _, node in pairs(area) do
                local d = getDistanceBetweenPoints2D(x, y, node.x, node.y)
                if d < bestD then
                        best, bestD = node, d
                end
        end
        return best
end

local function dijkstraPath(startNode, goalNode)
        if not startNode or not goalNode then return nil end
        local dist, prev, visited = {}, {}, {}
        dist[startNode.id] = 0
        local queue = { startNode.id }
        while #queue > 0 do
                -- pick the queue node with the smallest distance
                local bi, bd = 1, dist[queue[1]] or math.huge
                for i = 2, #queue do
                        local d = dist[queue[i]] or math.huge
                        if d < bd then bi, bd = i, d end
                end
                local current = queue[bi]
                table.remove(queue, bi)
                if visited[current] then
                else
                        visited[current] = true
                        if current == goalNode.id then break end
                        local node = getNodeByID(current)
                        if node then
                                for nid, ndist in pairs(node.neighbours) do
                                        if not visited[nid] then
                                                local nd = (dist[current] or math.huge) + ndist
                                                if dist[nid] == nil or nd < dist[nid] then
                                                        dist[nid] = nd
                                                        prev[nid] = current
                                                        table.insert(queue, nid)
                                                end
                                        end
                                end
                        end
                end
        end
        if dist[goalNode.id] == nil then return nil end
        local path = {}
        local cur = goalNode.id
        while cur do
                table.insert(path, 1, getNodeByID(cur))
                cur = prev[cur]
        end
        return path
end

function findBestWay(wx, wy, r, g, b)
        if r and g and b then
                routeColor = tocolor(r, g, b, 255)
        else
                routeColor = WAY_COLOR
        end
        lastMarkerX, lastMarkerY = getElementPosition(localPlayer)
        local startNode = findNodePosition(lastMarkerX, lastMarkerY)
        local goalNode = findNodePosition(wx, wy)
        if not startNode or not goalNode then
                route = nil
                return
        end
        local path = dijkstraPath(startNode, goalNode)
        if not path then route = nil return end
        destroyRouteMarkers()
        route = {}
        for i, node in ipairs(path) do
                route[i] = { node.x, node.y, node.z }
        end
        -- invisible route markers consumed on hit (old marker + colshape chain)
        for i, node in ipairs(path) do
                if i > 1 and i % 6 == 0 then
                        local col = createColSphere(node.x, node.y, node.z, 10)
                        setElementParent(col, resourceRoot)
                        addEventHandler("onClientColShapeHit", col, function(hitElm)
                                if hitElm == localPlayer then
                                        destroyElement(source)
                                end
                        end)
                        table.insert(routeMarkers, { col = col })
                end
        end
end

-- global getter (tests / other resources): current GPS route nodes
function getRadarRoute()
        return route
end

--------------------------------------------------------------------------------
-- visibility + input
--------------------------------------------------------------------------------
local function removeFrameHandlers()
        removeEventHandler("onClientRender", root, drawMinimap)
        removeEventHandler("onClientRender", root, bigMapDraw)
end

function showRadar(state, dispatchElements)
        if state then
                if not RADAR.visible then
                        rt = dxCreateRenderTarget(RADAR.w, RADAR.h, true)
                        addEventHandler("onClientRender", root, drawMinimap, false)
                        ensureTexture()
                        setPlayerHudComponentVisible("radar", false)
                        if not rt then
                                -- old fallback: native radar when the RT cannot be created
                                setPlayerHudComponentVisible("radar", true)
                        end
                end
        else
                forcePlayerMap(false)
                RADAR.mapVisible = false
                if RADAR.visible then
                        removeEventHandler("onClientRender", root, drawMinimap)
                        if isElement(rt) then destroyElement(rt) end
                        rt = nil
                end
        end
        RADAR.visible = state
        RADAR.dispatchElements = dispatchElements or RADAR.dispatchElements
end

function setRadarDispatchElements(elements)
        RADAR.dispatchElements = elements or RADAR.dispatchElements
end

local function toggleBigMap(state)
        BIG.mapVisible = state
        if state then
                bigMapCenterOnPlayer()
                addEventHandler("onClientRender", root, bigMapDraw, false)
                bindKey("mouse2", "down", function()
                        if RADAR.mapVisible then showCursor(not isCursorShowing()) end
                end)
                forcePlayerMap(false)
                showChat(false)
        else
                removeEventHandler("onClientRender", root, bigMapDraw)
                unbindKey("mouse2", "down")
                showCursor(false)
                showChat(true)
        end
end

addEventHandler("onClientKey", root, function(key, press)
        if key == "F11" and press and RADAR.visible then
                toggleBigMap(not RADAR.mapVisible)
                cancelEvent()
        elseif RADAR.mapVisible and press and (key == "mouse_wheel_up" or key == "mouse_wheel_down") then
                if bigMapIsHover(getCursorPosition() and getCursorPosition() * sx or 0,
                        getCursorPosition() and getCursorPosition() * sy or 0) then
                        local before = BIG.zoom
                        if key == "mouse_wheel_up" then
                                BIG.zoom = math.min(BIG.maxZoom, BIG.zoom + 0.1)
                        else
                                BIG.zoom = math.max(BIG.minZoom, BIG.zoom - 0.1)
                        end
                        if before ~= BIG.zoom then
                                bigMapClamp()
                        end
                end
                cancelEvent()
        end
end)

addEventHandler("onClientClick", root, function(button, state, absX, absY)
        if button ~= "left" or not RADAR.mapVisible then return end
        if state == "down" then
                if bigMapIsHover(absX, absY) then
                        BIG.dragging = true
                        BIG.dragX = absX - BIG.offX
                        BIG.dragY = absY - BIG.offY
                end
        else
                BIG.dragging = false
        end
end)

addEventHandler("onClientCursorMove", root, function(_, _, absX, absY)
        if RADAR.mapVisible and BIG.dragging then
                BIG.offX = absX - BIG.dragX
                BIG.offY = absY - BIG.dragY
                bigMapClamp()
        end
end)

-- double click = GPS route to the clicked point (old ChosePoint)
addEventHandler("onClientDoubleClick", root, function(button, absX, absY)
        if button == "left" and RADAR.mapVisible and bigMapIsHover(absX, absY) then
                local wx, wy = bigMapToWorld(absX, absY)
                findBestWay(wx, wy)
                if isPedInVehicle(localPlayer) then
                        triggerServerEvent("radar:onFindBestWay", localPlayer, wx, wy)
                end
        end
end)

-- sidebar row click = route to the nearest blip with the row name (old)
addEventHandler("onClientClick", root, function(button, state, absX, absY)
        if button ~= "left" or state ~= "up" or not RADAR.mapVisible then return end
        if BIG.listHover then
                local best, bestD = nil, math.huge
                for _, blip in ipairs(getElementsByType("blip")) do
                        if getElementData(blip, "blip:name") == BIG.listHover then
                                local bx, by = getElementPosition(blip)
                                local px, py = getElementPosition(localPlayer)
                                local d = getDistanceBetweenPoints2D(px, py, bx, by)
                                if d < bestD then best, bestD = { bx, by }, d end
                        end
                end
                if best then
                        findBestWay(best[1], best[2])
                        if isPedInVehicle(localPlayer) then
                                triggerServerEvent("radar:onFindBestWay", localPlayer, best[1], best[2])
                        end
                end
        end
end)

--------------------------------------------------------------------------------
-- lifecycle
--------------------------------------------------------------------------------
addEvent("radar:showRadar", true)
addEventHandler("radar:showRadar", localPlayer, function()
        showRadar(true)
end)

addEvent("radar:findBestWay:sync", true)
addEventHandler("radar:findBestWay:sync", root, function(wx, wy, r, g, b)
        findBestWay(wx, wy, r, g, b)
end)

addEvent("onClientCharacterSpawn", true)
addEventHandler("onClientCharacterSpawn", localPlayer, function()
        bigMapCenterOnPlayer()
        showRadar(true)
end)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
        showRadar(false)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
        ensureTexture()
        bigMapCenterOnPlayer()
        if tonumber(getElementData(localPlayer, "character:id") or 0) ~= 0
                and getElementData(localPlayer, "loggedin") == 1 then
                showRadar(true)
        end
end)

addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "loggedin" and not RADAR.visible then
                if getElementData(localPlayer, "loggedin") == 1 then
                        showRadar(true)
                end
        end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        setPlayerHudComponentVisible("radar", true)
end)

-- exports for other resources (old API surface)
function isRadarVisible()
        return RADAR.visible
end
