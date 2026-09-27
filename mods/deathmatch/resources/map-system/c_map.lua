--------------------------------------------------------------------------------
-- Vortex map-system — client (Fix #27)
--
-- F11 big map for the HUD family. The built-in player map is suppressed and
-- replaced by our own panel (no world texture available in this repo, so the
-- map is drawn as a clean tactical grid):
--   * SAFE / DANGER tint per the HUD zone rule: ALL of Los Santos is safe
--     (green), every other city / area is danger (red) - sampled with
--     getZoneName(x, y, z, true) on a coarse grid when the map opens
--   * local player arrow + streamed player dots (names for staff, pushed by
--     the server as map:seeNames)
--   * click = set a route waypoint (old client purple), /clearway clears it
--   * mouse wheel zooms, F11 closes
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

local visible = false
local zoom = 1
local waypoint = nil          -- {x, y}
local cityGrid = nil          -- sampled city grid
local GRID_N = 44             -- 44x44 samples over the 6000x6000 world
local WORLD = 6000

local PANEL_W = math.floor(sx * 0.74)
local PANEL_H = math.floor(sy * 0.76)

local function outlineText(text, x, y, w, h, color, scale, font, alignX, alignY)
        local black = tocolor(0, 0, 0, 200)
        dxDrawText(text, x - 1, y, x + w - 1, y + h, black, scale, font, alignX, alignY)
        dxDrawText(text, x + 1, y, x + w + 1, y + h, black, scale, font, alignX, alignY)
        dxDrawText(text, x, y - 1, x + w, y + h - 1, black, scale, font, alignX, alignY)
        dxDrawText(text, x, y + 1, x + w, y + h + 1, black, scale, font, alignX, alignY)
        dxDrawText(text, x, y, x + w, y + h, color, scale, font, alignX, alignY)
end

-- world (x, y) -> panel pixels (centered on the local player)
local function worldToPanel(wx, wy, px, py, pw, ph, cx, cy)
        local scale = (pw / WORLD) * zoom
        return px + pw / 2 + (wx - cx) * scale, py + ph / 2 - (wy - cy) * scale
end

-- panel pixels -> world (for the waypoint click)
local function panelToWorld(sxp, syp, px, py, pw, ph, cx, cy)
        local scale = (pw / WORLD) * zoom
        return cx + (sxp - px - pw / 2) / scale, cy - (syp - py - ph / 2) / scale
end

-- sample the world into city cells when the map opens (one-shot)
local function sampleCities()
        local grid = {}
        local step = WORLD / GRID_N
        for gx = 0, GRID_N - 1 do
                grid[gx] = {}
                for gy = 0, GRID_N - 1 do
                        local wx = -WORLD / 2 + step * (gx + 0.5)
                        local wy = -WORLD / 2 + step * (gy + 0.5)
                        local city = getZoneName(wx, wy, 3, true)
                        grid[gx][gy] = city
                end
        end
        cityGrid = grid
end

local function draw()
        -- keep the built-in map suppressed while ours is open
        if isPlayerMapVisible() then forcePlayerMap(false) end
        if not (getElementData(localPlayer, "loggedin") == 1
                or getElementData(localPlayer, "account:character:id")) then return end

        local px, py = (sx - PANEL_W) / 2, (sy - PANEL_H) / 2
        local cx, cy = getElementPosition(localPlayer)

        -- frame + background
        dxDrawRectangle(px - 4, py - 4, PANEL_W + 8, PANEL_H + 8, tocolor(8, 10, 16, 235))
        dxDrawRectangle(px, py, PANEL_W, PANEL_H, tocolor(14, 18, 26, 250))
        dxDrawRectangle(px - 4, py - 4, PANEL_W + 8, 2, tocolor(149, 84, 255, 160))
        dxDrawRectangle(px - 4, py + PANEL_H + 2, PANEL_W + 8, 2, tocolor(149, 84, 255, 160))

        local scale = (PANEL_W / WORLD) * zoom
        local stepPx = 1000 * scale

        -- safe/danger tint from the sampled grid (per the HUD zone rule)
        if cityGrid then
                -- Fix #28: cells are square in WORLD units, so the vertical
                -- pixel size must follow the world scale (PANEL_W based) and
                -- not PANEL_H - the old cellH rendered the tints as striped
                -- rows with gaps. Cells fully outside the panel are skipped
                -- (dxDrawRectangle does not clip).
                local cellW = PANEL_W / GRID_N * zoom
                local cellH = cellW
                local half = GRID_N / 2 / zoom
                local gx0 = math.floor((cx + WORLD / 2) / (WORLD / GRID_N) - half)
                local gy0 = math.floor((cy + WORLD / 2) / (WORLD / GRID_N) - half)
                for gx = gx0, gx0 + GRID_N - 1 do
                        local col = cityGrid[gx]
                        if col then
                                for gy = gy0, gy0 + GRID_N - 1 do
                                        local city = col[gy]
                                        if city then
                                                local wx = -WORLD / 2 + (WORLD / GRID_N) * (gx + 0.5)
                                                local wy = -WORLD / 2 + (WORLD / GRID_N) * (gy + 0.5)
                                                local sxp, syp = worldToPanel(wx, wy, px, py, PANEL_W, PANEL_H, cx, cy)
                                                if sxp > px - cellW and sxp < px + PANEL_W + cellW
                                                        and syp > py - cellH and syp < py + PANEL_H + cellH then
                                                        local tint = (city == "Los Santos")
                                                                and tocolor(153, 255, 0, 26) or tocolor(255, 40, 40, 26)
                                                        dxDrawRectangle(sxp - cellW / 2, syp - cellH / 2,
                                                                cellW + 1, cellH + 1, tint)
                                                end
                                        end
                                end
                        end
                end
        end

        -- grid lines every 1000 world units
        if stepPx > 14 then
                local startW = math.ceil((cx - (PANEL_W / 2) / scale) / 1000) * 1000
                for wx = startW, cx + (PANEL_W / 2) / scale, 1000 do
                        local sxp = px + PANEL_W / 2 + (wx - cx) * scale
                        dxDrawRectangle(sxp, py, 1, PANEL_H, tocolor(255, 255, 255, 12))
                end
                local startS = math.ceil((cy - (PANEL_H / 2) / scale) / 1000) * 1000
                for wy = startS, cy + (PANEL_H / 2) / scale, 1000 do
                        local syp = py + PANEL_H / 2 - (wy - cy) * scale
                        dxDrawRectangle(px, syp, PANEL_W, 1, tocolor(255, 255, 255, 12))
                end
        end

        -- streamed players (names for staff only - server permission)
        local seeNames = getElementData(localPlayer, "map:seeNames") == true
        for _, player in ipairs(getElementsByType("player")) do
                if player ~= localPlayer and isElement(player) and isElementStreamedIn(player) then
                        local dim = getElementDimension(player)
                        if dim == getElementDimension(localPlayer) then
                                local wx, wy = getElementPosition(player)
                                local sxp, syp = worldToPanel(wx, wy, px, py, PANEL_W, PANEL_H, cx, cy)
                                if sxp >= px and sxp <= px + PANEL_W and syp >= py and syp <= py + PANEL_H then
                                        dxDrawRectangle(sxp - 3, syp - 3, 6, 6, tocolor(255, 255, 255, 220))
                                        if seeNames then
                                                local nm = tostring(getElementData(player, "fakename")
                                                        or getPlayerName(player) or ""):gsub("_", " ")
                                                outlineText(nm, sxp - 70, syp - 22, 140, 14,
                                                        tocolor(255, 255, 255, 220), 1, "default-small",
                                                        "center", "top")
                                        end
                                end
                        end
                end
        end

        -- waypoint (old client purple)
        if waypoint then
                local sxp, syp = worldToPanel(waypoint.x, waypoint.y, px, py, PANEL_W, PANEL_H, cx, cy)
                if sxp >= px and sxp <= px + PANEL_W and syp >= py and syp <= py + PANEL_H then
                        dxDrawRectangle(sxp - 5, syp - 5, 10, 10, tocolor(174, 0, 255, 240), 45)
                        outlineText("نقطة المسار", sxp - 60, syp + 8, 120, 14,
                                tocolor(200, 130, 255, 240), 1, "default-small", "center", "top")
                end
        end

        -- local player arrow (green triangle, rotated like the ped)
        local rot = getPedRotation(localPlayer)
        local mx, my = px + PANEL_W / 2, py + PANEL_H / 2
        local r = math.rad(-rot)
        local p1x, p1y = mx + math.sin(r) * 9, my - math.cos(r) * 9
        local p2x, p2y = mx + math.sin(r + 2.5) * 7, my - math.cos(r + 2.5) * 7
        local p3x, p3y = mx + math.sin(r - 2.5) * 7, my - math.cos(r - 2.5) * 7
        dxDrawTriangle(p1x, p1y, p2x, p2y, p3x, p3y, tocolor(0, 255, 132, 255))

        -- header + legend
        outlineText("F11 — الخريطة | F11 للإغلاق | عجلة الماوس = تقريب | كلك يسار = نقطة مسار",
                px, py - 26, PANEL_W, 22, tocolor(235, 238, 245, 240), 1, "default-bold", "center", "top")
        local ly = py + PANEL_H + 10
        dxDrawRectangle(px, ly + 3, 12, 12, tocolor(153, 255, 0, 200))
        outlineText("Los Santos = SAFE ZONE", px + 18, ly, 220, 18,
                tocolor(200, 235, 180, 235), 1, "default", "left", "top")
        dxDrawRectangle(px + 250, ly + 3, 12, 12, tocolor(255, 40, 40, 200))
        outlineText("باقي المدن والمناطق = DANGER ZONE", px + 268, ly, 320, 18,
                tocolor(235, 180, 180, 235), 1, "default", "left", "top")
        if waypoint then
                dxDrawRectangle(px + 600, ly + 3, 12, 12, tocolor(174, 0, 255, 220))
                outlineText("نقطة مسار (/clearway للحذف)", px + 618, ly, 260, 18,
                        tocolor(210, 170, 255, 235), 1, "default", "left", "top")
        end
end

local function setVisible(state)
        if state == visible then return end
        visible = state
        if visible then
                forcePlayerMap(false)
                sampleCities()
                addEventHandler("onClientRender", root, draw, false, "low-20")
        else
                removeEventHandler("onClientRender", root, draw)
        end
end

bindKey("F11", "down", function()
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "account:character:id") then return end
        setVisible(not visible)
end)

addCommandHandler("clearway", function()
        waypoint = nil
        outputChatBox("#a855f7[MAP]#ffffff تم حذف نقطة المسار.", 255, 255, 255, true)
end)

addEventHandler("onClientClick", root, function(button, press)
        if not visible or not press or button ~= "left" then return end
        local cx, cy = getCursorPosition()
        if not cx then return end
        cx, cy = cx * sx, cy * sy
        local px, py = (sx - PANEL_W) / 2, (sy - PANEL_H) / 2
        if cx < px or cx > px + PANEL_W or cy < py or cy > py + PANEL_H then return end
        local lx, ly2 = getElementPosition(localPlayer)
        local wx, wy = panelToWorld(cx, cy, px, py, PANEL_W, PANEL_H, lx, ly2)
        waypoint = { x = wx, y = wy }
        outputChatBox("#a855f7[MAP]#ffffff تم تعيين نقطة المسار على الخريطة.", 255, 255, 255, true)
end)

addEventHandler("onClientKey", root, function(key, press)
        if not visible or not press then return end
        if key == "mouse_wheel_up" then
                zoom = math.min(6, zoom + 0.5)
        elseif key == "mouse_wheel_down" then
                zoom = math.max(1, zoom - 0.5)
        end
end)

-- reset when the resource stops
addEventHandler("onClientResourceStop", resourceRoot, function()
        if visible then removeEventHandler("onClientRender", root, draw) end
end)
