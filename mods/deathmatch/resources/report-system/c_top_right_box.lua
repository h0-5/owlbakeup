--------------------------------------------------------------------------------
-- [U4] THE ORANGE TOP-RIGHT "UNANSWERED REPORTS" BOX IS GONE.
--
-- This file used to draw the orange (255,194,14 header) reports rectangle in
-- the top-right corner: the rows were pushed by s_top_right_box.lua (element
-- data "urAdmin" / "urGM" / "allReports") and painted by the onClientRender
-- handler that ran dxDrawRectangle(..., tocolor(0,0,0,100)) + dxDrawText.
-- The widget, its render handler, its gates and the "report:topRight" toggles
-- have all been removed together with the server feed.
--
-- All that is left is this stub, which resets "report-system:dxBoxHeight" to
-- 0: the other top-right overlays (hud/c_overlay_top_right.lua and
-- job-system-tracker) read that hint to stack UNDER this box, so a stale
-- non-zero value left over from before the removal would push them down.
--
-- NOTE: the green report panel below is a SEPARATE file - c_report_panel.lua
-- (reports:sync / reports:togglePanel / tocolor(0,255,60)) - untouched.
--------------------------------------------------------------------------------

local localPlayer = getLocalPlayer()

local function clearBoxHeight()
        if getElementData(localPlayer, "report-system:dxBoxHeight") ~= 0 then
                setElementData(localPlayer, "report-system:dxBoxHeight", 0)
        end
end

addEventHandler("onClientResourceStart", resourceRoot, clearBoxHeight)
