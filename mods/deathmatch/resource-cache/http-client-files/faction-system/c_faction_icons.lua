-- ============================================================
-- Icon system - vector-drawn icons (no image files needed)
-- Draws simple line icons matching the reference style
-- ============================================================

ICON = {}

local function ic(x, y, w, h, color, thick)
    thick = thick or 2
    return { x = x, y = y, w = w, h = h, color = color, thick = thick }
end

-- draw a stroked line (as a thin rectangle; approximation for slopes)
local function line(x1, y1, x2, y2, color, thick)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.1 then return end
    local ang = math.atan2(dy, dx)
    local mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    -- axis-aligned fast path
    if math.abs(dy) < 0.5 then
        dxDrawRectangle(math.min(x1, x2), y1 - thick / 2, len, thick, color, true)
    elseif math.abs(dx) < 0.5 then
        dxDrawRectangle(x1 - thick / 2, math.min(y1, y2), thick, len, color, true)
    else
        -- rotated: draw small squares along the line for smooth appearance
        local steps = math.max(2, math.floor(len / (thick * 0.7)))
        for i = 0, steps do
            local t = i / steps
            local px = x1 + dx * t
            local py = y1 + dy * t
            dxDrawRectangle(px - thick / 2, py - thick / 2, thick, thick, color, true)
        end
    end
end

function drawIcon(name, x, y, size, color)
    color = color or tocolor(255, 255, 255, 220)
    local s = size
    local cx, cy = x + s / 2, y + s / 2
    local t = math.max(1.5, s * 0.08)

    if name == "group" or name == "members" then
        -- two person silhouettes
        dxDrawCircle(cx - s * 0.18, y + s * 0.28, s * 0.12, 0, 360, color, color, 16, 1, true)
        dxDrawCircle(cx + s * 0.18, y + s * 0.28, s * 0.12, 0, 360, color, color, 16, 1, true)
        dxDrawRectangle(x + s * 0.22, y + s * 0.42, s * 0.2, s * 0.16, color)
        dxDrawRectangle(x + s * 0.58, y + s * 0.42, s * 0.2, s * 0.16, color)
    elseif name == "star" or name == "ranks" then
        -- star (filled triangle approximation)
        local r1 = s * 0.36
        local pts = {}
        for i = 0, 9 do
            local r = (i % 2 == 0) and r1 or (r1 * 0.45)
            local a = -math.pi / 2 + i * math.pi / 5
            table.insert(pts, { x = cx + r * math.cos(a), y = cy + r * math.sin(a) })
        end
        -- draw as filled polygon using triangles from center
        for i = 1, #pts do
            local p1, p2 = pts[i], pts[i % #pts + 1]
            -- draw a thick line segment between consecutive points
            line(p1.x, p1.y, p2.x, p2.y, color, t * 1.2)
        end
        -- fill center
        dxDrawCircle(cx, cy, r1 * 0.5, 0, 360, color, color, 14, 1, true)
    elseif name == "car" or name == "vehicles" then
        -- car body
        dxDrawRectangle(x + s * 0.1, y + s * 0.38, s * 0.8, s * 0.22, color)
        dxDrawRectangle(x + s * 0.22, y + s * 0.24, s * 0.56, s * 0.16, color)
        line(x + s * 0.22, y + s * 0.4, x + s * 0.78, y + s * 0.4, color, t * 0.6)
        -- wheels
        dxDrawCircle(x + s * 0.26, y + s * 0.66, s * 0.09, 0, 360, color, color, 12, 1, true)
        dxDrawCircle(x + s * 0.74, y + s * 0.66, s * 0.09, 0, 360, color, color, 12, 1, true)
    elseif name == "box" or name == "duty" then
        -- box
        line(x + s * 0.15, y + s * 0.3, cx, y + s * 0.15, color, t)
        line(cx, y + s * 0.15, x + s * 0.85, y + s * 0.3, color, t)
        line(x + s * 0.15, y + s * 0.3, x + s * 0.15, y + s * 0.6, color, t)
        line(x + s * 0.85, y + s * 0.3, x + s * 0.85, y + s * 0.6, color, t)
        line(cx, y + s * 0.15, cx, y + s * 0.45, color, t)
        line(x + s * 0.15, y + s * 0.6, cx, y + s * 0.45, color, t)
        line(cx, y + s * 0.45, x + s * 0.85, y + s * 0.6, color, t)
    elseif name == "pin" or name == "dutylocations" then
        -- map pin: circle + triangle tail
        dxDrawCircle(cx, y + s * 0.32, s * 0.2, 0, 360, color, color, 18, 1, true)
        local p1 = { x = cx - s * 0.14, y = y + s * 0.42 }
        local p2 = { x = cx + s * 0.14, y = y + s * 0.42 }
        local p3 = { x = cx, y = y + s * 0.82 }
        line(p1.x, p1.y, p3.x, p3.y, color, t)
        line(p2.x, p2.y, p3.x, p3.y, color, t)
        line(p1.x, p1.y, p2.x, p2.y, color, t)
    elseif name == "truck" or name == "dutyvehicles" then
        -- truck
        dxDrawRectangle(x + s * 0.08, y + s * 0.3, s * 0.5, s * 0.3, color)
        dxDrawRectangle(x + s * 0.58, y + s * 0.38, s * 0.34, s * 0.22, color)
        dxDrawCircle(x + s * 0.24, y + s * 0.68, s * 0.08, 0, 360, color, color, 12, 1, true)
        dxDrawCircle(x + s * 0.76, y + s * 0.68, s * 0.08, 0, 360, color, color, 12, 1, true)
    elseif name == "cog" or name == "management" then
        -- gear
        dxDrawCircle(cx, cy, s * 0.2, 0, 360, color, color, 18, 1, true)
        for i = 0, 7 do
            local a = i * math.pi / 4
            local x1, y1 = cx + s * 0.24 * math.cos(a), cy + s * 0.24 * math.sin(a)
            local x2, y2 = cx + s * 0.36 * math.cos(a), cy + s * 0.36 * math.sin(a)
            line(x1, y1, x2, y2, color, t * 1.2)
        end
    elseif name == "bank" or name == "finance" then
        -- bank columns
        line(x + s * 0.1, y + s * 0.28, x + s * 0.9, y + s * 0.28, color, t)
        line(x + s * 0.1, y + s * 0.28, cx, y + s * 0.12, color, t)
        line(cx, y + s * 0.12, x + s * 0.9, y + s * 0.28, color, t)
        for i = 0, 2 do
            local px = x + s * 0.2 + i * s * 0.3
            line(px, y + s * 0.3, px, y + s * 0.62, color, t)
        end
        line(x + s * 0.08, y + s * 0.64, x + s * 0.92, y + s * 0.64, color, t)
    elseif name == "note" then
        -- note with lines
        line(x + s * 0.2, y + s * 0.12, x + s * 0.8, y + s * 0.12, color, t)
        line(x + s * 0.2, y + s * 0.12, x + s * 0.2, y + s * 0.88, color, t)
        line(x + s * 0.8, y + s * 0.12, x + s * 0.8, y + s * 0.88, color, t)
        line(x + s * 0.2, y + s * 0.88, x + s * 0.8, y + s * 0.88, color, t)
        line(x + s * 0.3, y + s * 0.32, x + s * 0.7, y + s * 0.32, color, t * 0.7)
        line(x + s * 0.3, y + s * 0.46, x + s * 0.7, y + s * 0.46, color, t * 0.7)
        line(x + s * 0.3, y + s * 0.6, x + s * 0.55, y + s * 0.6, color, t * 0.7)
    elseif name == "log" then
        -- document
        line(x + s * 0.22, y + s * 0.1, x + s * 0.68, y + s * 0.1, color, t)
        line(x + s * 0.22, y + s * 0.1, x + s * 0.22, y + s * 0.9, color, t)
        line(x + s * 0.68, y + s * 0.1, x + s * 0.78, y + s * 0.2, color, t)
        line(x + s * 0.68, y + s * 0.1, x + s * 0.68, y + s * 0.2, color, t)
        line(x + s * 0.68, y + s * 0.2, x + s * 0.78, y + s * 0.2, color, t)
        line(x + s * 0.78, y + s * 0.2, x + s * 0.78, y + s * 0.9, color, t)
        line(x + s * 0.22, y + s * 0.9, x + s * 0.78, y + s * 0.9, color, t)
        line(x + s * 0.32, y + s * 0.36, x + s * 0.68, y + s * 0.36, color, t * 0.7)
        line(x + s * 0.32, y + s * 0.5, x + s * 0.68, y + s * 0.5, color, t * 0.7)
        line(x + s * 0.32, y + s * 0.64, x + s * 0.55, y + s * 0.64, color, t * 0.7)
    elseif name == "shield" or name == "permissions" then
        -- shield
        local pts = {
            { x = cx, y = y + s * 0.1 },
            { x = x + s * 0.82, y = y + s * 0.22 },
            { x = x + s * 0.82, y = y + s * 0.5 },
            { x = cx, y = y + s * 0.9 },
            { x = x + s * 0.18, y = y + s * 0.5 },
            { x = x + s * 0.18, y = y + s * 0.22 },
        }
        for i = 1, #pts do
            local p1, p2 = pts[i], pts[i % #pts + 1]
            line(p1.x, p1.y, p2.x, p2.y, color, t)
        end
        line(cx - s * 0.14, cy, cx - s * 0.02, cy + s * 0.14, color, t)
        line(cx - s * 0.02, cy + s * 0.14, cx + s * 0.18, cy - s * 0.1, color, t)
    elseif name == "users" or name == "applications" then
        -- person + plus
        dxDrawCircle(cx - s * 0.1, y + s * 0.26, s * 0.13, 0, 360, color, color, 14, 1, true)
        dxDrawRectangle(x + s * 0.27, y + s * 0.4, s * 0.26, s * 0.18, color)
        line(x + s * 0.62, y + s * 0.5, x + s * 0.82, y + s * 0.5, color, t * 1.3)
        line(x + s * 0.72, y + s * 0.4, x + s * 0.72, y + s * 0.6, color, t * 1.3)
    elseif name == "close" then
        line(x + s * 0.22, y + s * 0.22, x + s * 0.78, y + s * 0.78, color, t * 1.4)
        line(x + s * 0.78, y + s * 0.22, x + s * 0.22, y + s * 0.78, color, t * 1.4)
    elseif name == "more" then
        -- three dots vertical
        dxDrawCircle(cx, y + s * 0.24, s * 0.07, 0, 360, color, color, 10, 1, true)
        dxDrawCircle(cx, cy, s * 0.07, 0, 360, color, color, 10, 1, true)
        dxDrawCircle(cx, y + s * 0.76, s * 0.07, 0, 360, color, color, 10, 1, true)
    elseif name == "plus" then
        line(x + s * 0.2, cy, x + s * 0.8, cy, color, t * 1.5)
        line(cx, y + s * 0.2, cx, y + s * 0.8, color, t * 1.5)
    elseif name == "check" then
        line(x + s * 0.2, cy, x + s * 0.42, y + s * 0.68, color, t * 1.4)
        line(x + s * 0.42, y + s * 0.68, x + s * 0.82, y + s * 0.28, color, t * 1.4)
    elseif name == "trophy" then
        -- trophy
        line(cx - s * 0.2, y + s * 0.16, cx + s * 0.2, y + s * 0.16, color, t)
        line(cx - s * 0.2, y + s * 0.16, cx - s * 0.2, y + s * 0.4, color, t)
        line(cx + s * 0.2, y + s * 0.16, cx + s * 0.2, y + s * 0.4, color, t)
        line(cx - s * 0.2, y + s * 0.4, cx + s * 0.2, y + s * 0.4, color, t)
        line(cx - s * 0.12, y + s * 0.4, cx - s * 0.12, y + s * 0.58, color, t)
        line(cx + s * 0.12, y + s * 0.4, cx + s * 0.12, y + s * 0.58, color, t)
        line(cx - s * 0.28, y + s * 0.58, cx + s * 0.28, y + s * 0.58, color, t)
        line(cx - s * 0.28, y + s * 0.58, cx - s * 0.28, y + s * 0.68, color, t)
        line(cx + s * 0.28, y + s * 0.58, cx + s * 0.28, y + s * 0.68, color, t)
        line(cx - s * 0.28, y + s * 0.68, cx + s * 0.28, y + s * 0.68, color, t)
    end
end
