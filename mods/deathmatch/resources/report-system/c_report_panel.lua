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
--   * [Fix #167] STAFF ONLY: everything below is gated on the
--     hud:reportsright mirror of the access.reports right (pushed by
--     hud/s_hud.lua, re-checked server-side on every open) - no right, no
--     panel: nothing renders and report_panel_state true is treated as closed
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

-- [Fix #167 - user] "لوحة ريبورتات من f4 ظاهرة للكل": this list is STAFF
-- only. hud/s_hud.lua pushes the access.reports answer as the synced
-- hud:reportsright mirror (1/0) and the server re-checks the right on every
-- reports:showUnansweredReportsPanel. Cached on data change like the other
-- per-frame inputs above, consumed by the draw gate, by reports:sync and by
-- reports:togglePanel - a viewer without the right NEVER renders the panel,
-- and a report_panel_state that says "open" without the right is treated as
-- CLOSED (the local mirror is corrected below).
local cachedReportsRight = false

local function cacheReportsRight()
        cachedReportsRight = (tonumber(getElementData(localPlayer, "hud:reportsright")) == 1)
end

-- drop everything on screen the moment the right is gone (or was never
-- there): close the panel, tell the server to unregister this viewer and
-- correct the client-local report_panel_state mirror
local function closeWithoutRight()
        if panelVisible then
                panelVisible = false
                triggerServerEvent("reports:onHideUnansweredReportsPanel", localPlayer)
        end
        if getElementData(localPlayer, "report_panel_state") then
                setElementData(localPlayer, "report_panel_state", false, false)
        end
end

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
        -- [Fix #167] no right -> no list: ignore a feed that arrives without
        -- the entitlement (and close anything that was on screen)
        if not cachedReportsRight then
                closeWithoutRight()
                return
        end
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
        -- [Fix #167] the server owns the answer: a "true" it sends (or a
        -- local optimistic open) without the right is treated as CLOSED, and
        -- the client-local report_panel_state mirror is written to match so
        -- no other reader of this resource treats the list as open
        if state and not cachedReportsRight then
                closeWithoutRight()
                return
        end
        panelVisible = state and true or false
        setElementData(localPlayer, "report_panel_state", panelVisible, false)
end)

addEvent("hud:onClientHudItemClick", false)
addEventHandler("hud:onClientHudItemClick", localPlayer, function(id, value)
        if id == "admintag" and not value then
                if panelVisible then
                        panelVisible = false
                        triggerServerEvent("reports:onHideUnansweredReportsPanel", localPlayer)
                end
        end
end)

addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "loggedin" then
                cacheLoggedin()
        elseif key == "hud:topRightBottom" then
                cachedMoneyBottom = tonumber(getElementData(localPlayer, "hud:topRightBottom"))
        elseif key == "hud:reportsright" then
                -- [Fix #167] a live rights change closes the list at once
                cacheReportsRight()
                if not cachedReportsRight then
                        closeWithoutRight()
                end
        elseif key == "report_panel_state" then
                -- [Fix #167] report_panel_state true WITHOUT the right = closed
                if getElementData(localPlayer, "report_panel_state")
                        and not cachedReportsRight then
                        closeWithoutRight()
                end
        end
end, false)

addEventHandler("onClientResourceStart", resourceRoot, function()
        cacheLoggedin()
        cacheReportsRight()
        cachedMoneyBottom = tonumber(getElementData(localPlayer, "hud:topRightBottom"))
        if not cachedReportsRight then
                closeWithoutRight()
        end
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
        -- [Fix #167] belt and braces: never paint the staff list for a viewer
        -- without access.reports (report_panel_state true without the right
        -- is treated as closed above, this covers a panelVisible that slipped
        -- through anyway - the draw costs nothing but the entitlement check)
        if not cachedReportsRight then return end
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
