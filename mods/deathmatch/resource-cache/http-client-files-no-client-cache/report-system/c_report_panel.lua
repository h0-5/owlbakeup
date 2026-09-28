--------------------------------------------------------------------------------
-- Report Center — LIVE REPORTS LIST (Fix #32)
-- 1:1 port of the OLD CLIENT [rp]/report-system drawReports (backupm):
--   * the F4 "Report Center" strip item toggles the panel through
--     reports:showUnansweredReportsPanel / reports:onHideUnansweredReportsPanel
--   * the server answers reports:sync with rows
--     { [1]=id, [2]=reporter, [7]=handler, [8]=timestring }
--   * every row draws as
--     [#00ff3c <id> #ffffff]  From '<name>' at <time> Handler: <name>.
--   * empty list reads "#a9a9a9No Reports"
-- The old panel geometry vars were lost to the decompiler - the panel sits
-- top-right under the status HUD, sized by the row count like the old
-- math (rows * 20 + 40, floor 50).
--------------------------------------------------------------------------------

local sx, sy = guiGetScreenSize()
local panelVisible = false
local reportText = "Reports\n#a9a9a9No Reports"
local panelW = 620
local ROW_H = 20

-- [Fix #47 - FPS] everything the draw loop needs is now precomputed:
-- the old loop counted rows with gmatch, read loggedin and hud:topRightBottom
-- via getElementData EVERY FRAME. Row count is computed once per sync; the
-- two element data reads are cached on data change.
local panelH = 50
local cachedLoggedin = false
local cachedMoneyBottom = nil

local function recalcHeight()
        local rows = 0
        for _ in reportText:gmatch("\n") do rows = rows + 1 end
        panelH = math.max(50, rows * ROW_H + 40)
end

local function cacheLoggedin()
        cachedLoggedin = (tonumber(getElementData(localPlayer, "loggedin")) == 1)
end

addEvent("reports:sync", true)
addEventHandler("reports:sync", root, function(rows)
        if type(rows) ~= "table" then return end
        local out = ""
        for i, row in ipairs(rows) do
                local reporter = isElement(row[2])
                        and (getElementData(row[2], "character:name") or getPlayerName(row[2]))
                        or "None"
                local handler = isElement(row[7])
                        and (getElementData(row[7], "character:name") or getPlayerName(row[7]))
                        or "None"
                local line = "#ffffff[#00ff3c " .. tostring(row[1]) .. " #ffffff]  From '"
                        .. tostring(reporter) .. "' at " .. tostring(row[8])
                        .. " Handler: " .. tostring(handler) .. "."
                out = (i == 1) and line or (out .. "\n" .. line)
        end
        if #rows == 0 then
                panelW = 320
        else
                panelW = 620
        end
        if out == "" then out = "#a9a9a9No Reports" end
        reportText = "Reports\n" .. out
        recalcHeight()
end)

addEvent("reports:togglePanel", true)
addEventHandler("reports:togglePanel", root, function(state)
        panelVisible = state and true or false
end)

addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "loggedin" then
                cacheLoggedin()
        elseif key == "hud:topRightBottom" then
                cachedMoneyBottom = tonumber(getElementData(localPlayer, "hud:topRightBottom"))
        end
end, false)

addEventHandler("onClientResourceStart", resourceRoot, function()
        cacheLoggedin()
        cachedMoneyBottom = tonumber(getElementData(localPlayer, "hud:topRightBottom"))
end)

-- old client: the staff panel closes the list too when the duty tag goes off
addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "duty_admin" or key == "duty_supporter" then
                if not (tonumber(getElementData(localPlayer, "duty_admin")) == 1
                        or tonumber(getElementData(localPlayer, "duty_supporter")) == 1) then
                        if panelVisible then
                                panelVisible = false
                                triggerServerEvent("reports:onHideUnansweredReportsPanel", localPlayer)
                        end
                end
        end
end)

local function drawRoundRect8(x, y, w, h, color)
        -- old client dxDrawRoundedRectangle (3 rects + 4 corner circles, r=8)
        local r = 8
        w, h, x, y = w - r * 2, h - r * 2, math.floor(x + r), math.floor(y + r)
        dxDrawRectangle(x - r, y, w + r * 2, h, color)
        dxDrawRectangle(x, y - r, w, r, color)
        dxDrawRectangle(x, y + h, w, r, color)
        dxDrawCircle(x, y, r, 180, 270, color, color, 7)
        dxDrawCircle(x + w, y, r, 270, 360, color, color, 7)
        dxDrawCircle(x, y + h, r, 90, 180, color, color, 7)
        dxDrawCircle(x + w, y + h, r, 0, 90, color, color, 7)
end

addEventHandler("onClientRender", root, function()
        if not panelVisible then return end
        if not cachedLoggedin then return end
        -- height precomputed at sync time (was: gmatch row count every frame)
        local h = panelH
        -- [Fix #33 - user] "قائمة ريبورتات خليها تحت الفلوس": dock the list
        -- UNDER the money block (the hud publishes its bottom edge) instead
        -- of overlapping the clock/date/money stack (cached on data change)
        local y = cachedMoneyBottom and (cachedMoneyBottom + 8) or 170
        local x, y = sx - panelW - 14, y
        drawRoundRect8(x, y, panelW, h, tocolor(0, 0, 0, 200))
        dxDrawText(reportText, x + 10, y + 10, x + panelW - 10, y + h - 10,
                tocolor(0, 255, 60, 255), 1, "default-bold", "left", "top",
                false, false, false, true)
end)
