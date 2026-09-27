--------------------------------------------------------------------------------
-- Vortex map-system — client (Fix #29 rewrite)
--
-- Complete map mod rebuilt from the OLD CLIENT file (backupm/[rp]/radar +
-- gps-system): the F11 map is now the REAL world map texture (map.jpg, the
-- same one the old GPS GUI used, covering -3000..3000 on both axes) with
-- the old-client GPS:
--   * LEFT CLICK  = set GPS target -> route calculated through the vehicle
--     road nodes via gps-system's A* engine (calculatePathByCoords, exported)
--     and drawn as the old client's ORANGE route lines (251,139,0,180)
--   * RIGHT CLICK = clear GPS target + route (old client behaviour)
--   * /clearway   = same as right click
--   * mouse wheel zooms (1..6), F11 closes
--   * purple waypoint marker at the target (old client wayColor 174,0,255)
--   * local player arrow + streamed player dots (names for staff only -
--     map:seeNames pushed by s_map.lua) + world blips as colored dots
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

local visible = false
local zoom = 1
local waypoint = nil         -- {x, y}   GPS target / purple marker
local route = nil            -- {{x, y}, ...} A* node path (old client)
local mapTex                 -- images/map.jpg

local PANEL_W = math.floor(sx * 0.74)
local PANEL_H = math.floor(sy * 0.76)
local TEX_SIZE = 1152        -- map.jpg native size (6000 world units)
local WORLD = 6000

-- old client constants
local WAY_COLOR_R, WAY_COLOR_G, WAY_COLOR_B = 174, 0, 255     -- wayColor
local ROUTE_COLOR_R, ROUTE_COLOR_G, ROUTE_COLOR_B = 251, 139, 0 -- old GPS orange

addEventHandler("onClientResourceStart", resourceRoot, function()
        mapTex = dxCreateTexture("images/map.jpg", "argb", true, "clamp")
end)

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

-- panel pixels -> world (for the GPS click)
local function panelToWorld(sxp, syp, px, py, pw, ph, cx, cy)
        local scale = (pw / WORLD) * zoom
        return cx + (sxp - px - pw / 2) / scale, cy - (syp - py - ph / 2) / scale
end

local function draw()
        -- keep the built-in map suppressed while ours is open
        if isPlayerMapVisible() then forcePlayerMap(false) end
        if not (getElementData(localPlayer, "loggedin") == 1
                or getElementData(localPlayer, "account:character:id")) then return end

        local px, py = (sx - PANEL_W) / 2, (sy - PANEL_H) / 2
        local cx, cy = getElementPosition(localPlayer)

        -- frame + background (HUD family: dark panel, purple edges)
        dxDrawRectangle(px - 4, py - 4, PANEL_W + 8, PANEL_H + 8, tocolor(8, 10, 16, 235))
        dxDrawRectangle(px, py, PANEL_W, PANEL_H, tocolor(14, 18, 26, 250))
        dxDrawRectangle(px - 4, py - 4, PANEL_W + 8, 2, tocolor(149, 84, 255, 160))
        dxDrawRectangle(px - 4, py + PANEL_H + 2, PANEL_W + 8, 2, tocolor(149, 84, 255, 160))

        -- the REAL map: crop the visible world window out of map.jpg.
        -- map.jpg covers world (-3000,-3000)..(3000,3000), pixel (0,0) = top
        -- left = world (-3000, +3000) - the exact mapping the old GPS used
        -- (x = rel*6000 - 3000, y = 3000 - rel*6000). The window is clamped
        -- to the world bounds so we never sample outside the texture - the
        -- area beyond stays the dark panel (old client behaviour).
        if mapTex then
                local scale = (PANEL_W / WORLD) * zoom
                local halfW = (PANEL_W / 2) / scale
                local halfH = (PANEL_H / 2) / scale
                local wx0 = math.max(-WORLD / 2, cx - halfW)
                local wx1 = math.min(WORLD / 2, cx + halfW)
                local wy1 = math.min(WORLD / 2, cy + halfH)   -- top row = +Y
                local wy0 = math.max(-WORLD / 2, cy - halfH)
                if wx1 > wx0 and wy1 > wy0 then
                        local x0s, y0s = worldToPanel(wx0, wy1, px, py, PANEL_W, PANEL_H, cx, cy)
                        local texX = (wx0 + WORLD / 2) / WORLD * TEX_SIZE
                        local texY = (WORLD / 2 - wy1) / WORLD * TEX_SIZE
                        local texW = (wx1 - wx0) / WORLD * TEX_SIZE
                        local texH = (wy1 - wy0) / WORLD * TEX_SIZE
                        dxDrawImageSection(x0s, y0s, (wx1 - wx0) * scale, (wy1 - wy0) * scale,
                                texX, texY, texW, texH, mapTex, 0, 0, 0, tocolor(255, 255, 255, 255))
                end
        end

        -- world blips (colored squares - the old client used icon pngs that
        -- are not in the backup, the data comes from the same blip elements;
        -- blips attached to players are skipped, players draw their own dots)
        for _, blip in ipairs(getElementsByType("blip")) do
                if isElement(blip) then
                        local attachedTo = getElementAttachedTo(blip)
                        local isPlayerBlip = attachedTo and isElement(attachedTo)
                                and getElementType(attachedTo) == "player"
                        if not isPlayerBlip then
                                local be = (attachedTo and isElement(attachedTo)) and attachedTo or blip
                                local ok, bx, by = pcall(getElementPosition, be)
                                if ok and getDistanceBetweenPoints2D(cx, cy, bx, by) <= (getBlipVisibleDistance(blip) or 500) + 2500 / zoom then
                                        local sxp, syp = worldToPanel(bx, by, px, py, PANEL_W, PANEL_H, cx, cy)
                                        if sxp >= px and sxp <= px + PANEL_W and syp >= py and syp <= py + PANEL_H then
                                                local br, bg, bb = getBlipColor(blip)
                                                local bsize = math.max(4, math.min((getBlipSize(blip) or 2) * 2.6 * zoom, 16))
                                                dxDrawRectangle(sxp - bsize / 2, syp - bsize / 2, bsize, bsize,
                                                        tocolor(br, bg, bb, 230))
                                        end
                                end
                        end
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

        -- GPS route: the old client's orange polyline through the road nodes
        if route and #route > 0 then
                local prev = nil
                for _, node in ipairs(route) do
                        if node and node.x and node.y then
                                local sxp, syp = worldToPanel(node.x, node.y, px, py, PANEL_W, PANEL_H, cx, cy)
                                if prev then
                                        dxDrawLine(prev[1], prev[2], sxp, syp,
                                                tocolor(ROUTE_COLOR_R, ROUTE_COLOR_G, ROUTE_COLOR_B, 180), 5, true)
                                end
                                prev = { sxp, syp }
                        end
                end
        end

        -- waypoint / GPS target (old client purple) + live distance
        if waypoint then
                local sxp, syp = worldToPanel(waypoint.x, waypoint.y, px, py, PANEL_W, PANEL_H, cx, cy)
                if sxp >= px and sxp <= px + PANEL_W and syp >= py and syp <= py + PANEL_H then
                        dxDrawRectangle(sxp - 5, syp - 5, 10, 10, tocolor(WAY_COLOR_R, WAY_COLOR_G, WAY_COLOR_B, 240))
                        local dist = math.floor(getDistanceBetweenPoints2D(cx, cy, waypoint.x, waypoint.y))
                        outlineText("نقطة المسار (" .. dist .. " م)", sxp - 80, syp + 8, 160, 14,
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

        -- header + legend (old client: "Left click to set GPS Target -
        -- Right click to disable GPS")
        outlineText("F11 — الخريطة | كلك يسار: تحديد هدف GPS | كلك يمين: حذف | عجلة الماوس = تقريب",
                px, py - 26, PANEL_W, 22, tocolor(235, 238, 245, 240), 1, "default-bold", "center", "top")
        local ly = py + PANEL_H + 10
        dxDrawRectangle(px, ly + 3, 12, 12, tocolor(ROUTE_COLOR_R, ROUTE_COLOR_G, ROUTE_COLOR_B, 200))
        outlineText("مسار GPS", px + 18, ly, 130, 18,
                tocolor(255, 210, 160, 235), 1, "default", "left", "top")
        dxDrawRectangle(px + 160, ly + 3, 12, 12, tocolor(WAY_COLOR_R, WAY_COLOR_G, WAY_COLOR_B, 220))
        outlineText("نقطة المسار", px + 178, ly, 140, 18,
                tocolor(210, 170, 255, 235), 1, "default", "left", "top")
        dxDrawRectangle(px + 330, ly + 3, 12, 12, tocolor(0, 255, 132, 220))
        outlineText("موقعك", px + 348, ly, 90, 18,
                tocolor(180, 255, 210, 235), 1, "default", "left", "top")
        if seeNames then
                dxDrawRectangle(px + 450, ly + 3, 12, 12, tocolor(255, 255, 255, 220))
                outlineText("اللاعبين (ستاف)", px + 468, ly, 170, 18,
                        tocolor(220, 225, 235, 235), 1, "default", "left", "top")
        end
end

-- GPS: left click sets the target and routes through the road nodes with
-- the old client's A* engine (gps-system export)
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
                route = nil -- target marker still works without the A* engine
        end
        outputChatBox("#a855f7[MAP]#ffffff تم تعيين نقطة المسار على الخريطة.", 255, 255, 255, true)
end

local function setVisible(state)
        if state == visible then return end
        visible = state
        if visible then
                forcePlayerMap(false)
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
        route = nil
        outputChatBox("#a855f7[MAP]#ffffff تم حذف نقطة المسار.", 255, 255, 255, true)
end)

addEventHandler("onClientClick", root, function(button, press)
        if not visible or not press then return end
        local cxp, cyp = getCursorPosition()
        if not cxp then return end
        cxp, cyp = cxp * sx, cyp * sy
        local px, py = (sx - PANEL_W) / 2, (sy - PANEL_H) / 2
        if cxp < px or cxp > px + PANEL_W or cyp < py or cyp > py + PANEL_H then return end
        local lx, ly2 = getElementPosition(localPlayer)
        local wx, wy = panelToWorld(cxp, cyp, px, py, PANEL_W, PANEL_H, lx, ly2)
        if button == "left" then
                setGPSClicked(wx, wy)
        elseif button == "right" then
                waypoint = nil
                route = nil
                outputChatBox("#a855f7[MAP]#ffffff تم حذف نقطة المسار.", 255, 255, 255, true)
        end
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
