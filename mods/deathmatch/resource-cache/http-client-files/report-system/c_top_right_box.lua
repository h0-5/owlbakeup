local localPlayer = getLocalPlayer()
local show = false
local width, height = 500,300

local sx, sy = guiGetScreenSize()
local content = {}
local thisResourceElement = getResourceRootElement(getThisResource())

--------------------------------------------------------------------------------
-- [Fix #47 - FPS] THIS WAS THE #1 fpsdiag CULPRIT (75 FPS with the resource
-- stopped vs 32 baseline). The old handler cost EVERY player EVERY frame:
--   * 2 export calls (integration:isPlayerTrialAdmin/isPlayerSupporter) via
--     showTopRightReportBox + exports.hud:isActive
--   * 4 getElementData reads
--   * setElementData("report-system:dxBoxHeight", ...) EVERY FRAME - and in
--     the hidden branch a 0-write EVERY FRAME for every player on the server
--     (per-frame element-data sync + onClientElementDataChange storm).
-- Everything that rarely changes is now cached (500ms refresh + instant
-- refresh on the data keys that matter) and the dxBoxHeight write only
-- happens when the value actually changes.
--------------------------------------------------------------------------------

local gate = { ok = false }
local lastHeight = nil
local cachedLoggedin = false
local cachedPMPreview = false
local cachedHudOffsetY = 0

local function refreshGate()
        local ok, res = pcall(showTopRightReportBox, localPlayer)
        if not ok then res = false end
        if res then
                local okH, active = pcall(function() return exports.hud:isActive() end)
                if not okH then active = false end
                res = active and true or false
        end
        gate.ok = res and true or false
end
setTimer(refreshGate, 500, 0)

addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "report:topRight" or key == "report_panel_mod" then
                refreshGate()
        elseif key == "loggedin" then
                cachedLoggedin = (tonumber(getElementData(localPlayer, "loggedin")) == 1)
        elseif key == "integration:previewPMShowing" then
                cachedPMPreview = getElementData(localPlayer, "integration:previewPMShowing") == true
        elseif key == "hud:whereToDisplayY" then
                cachedHudOffsetY = tonumber(getElementData(localPlayer, "hud:whereToDisplayY")) or 0
        end
end, false)

addEventHandler("onClientResourceStart", resourceRoot, function()
        cachedLoggedin = (tonumber(getElementData(localPlayer, "loggedin")) == 1)
        cachedPMPreview = getElementData(localPlayer, "integration:previewPMShowing") == true
        cachedHudOffsetY = tonumber(getElementData(localPlayer, "hud:whereToDisplayY")) or 0
        refreshGate()
end)

function drawOverlayTopRight(info, widthNew, woffsetNew, hoffsetNew, cooldown)
        if showTopRightReportBox(localPlayer) then
                content = info
                if tonumber(widthNew) then
                        width = tonumber(widthNew)
                end
        end
end
addEvent("report-system:drawOverlayTopRight", true)
addEventHandler("report-system:drawOverlayTopRight", localPlayer, drawOverlayTopRight)

addEventHandler("onClientRender", getRootElement(), function()
        if not gate.ok or cachedPMPreview or not cachedLoggedin or isPlayerMapVisible() then
                -- hidden: publish 0 exactly ONCE instead of every frame
                if lastHeight ~= 0 then
                        lastHeight = 0
                        setElementData(localPlayer, "report-system:dxBoxHeight", 0)
                end
                return
        end
        if getPedWeapon(localPlayer) == 43 and getControlState("aim_weapon") then
                return -- camera mode: box suppressed (old rule), keep last height
        end

        local woffset, hoffset = 0, 40 + cachedHudOffsetY
        local heightTemp = 16*(#content)+30
        dxDrawRectangle(sx-width-5+woffset, 5+hoffset, width, heightTemp, tocolor(0, 0, 0, 100), false)

        for i=1, #content do
                if content[i] then
                        dxDrawText(content[i][1] or "", sx-width+10+woffset, (16*i)+hoffset, width-5, 15,
                                tocolor(content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, content[i][5] or 255),
                                content[i][6] or 1, content[i][7] or "default")
                end
        end

        local newHeight = heightTemp + hoffset - 35
        if newHeight ~= lastHeight then
                lastHeight = newHeight
                setElementData(localPlayer, "report-system:dxBoxHeight", newHeight)
        end
end, false)

addEventHandler( "onClientElementDataChange", getResourceRootElement(getThisResource()) ,
        function(n)
                if n == "urAdmin" or n == "urGM" or n == "allReports" then
                        if getElementData(localPlayer,"report:topRight") == 1 then
                                drawOverlayTopRight(getElementData(thisResourceElement, "urAdmin") or false, 550)
                        elseif getElementData(localPlayer,"report:topRight") == 2 then
                                drawOverlayTopRight(getElementData(thisResourceElement, "urGM") or false, 550)
                        elseif getElementData(localPlayer,"report:topRight") == 3 then
                                drawOverlayTopRight(getElementData(thisResourceElement, "allReports") or false, 600)
                        end
                end
        end, false
)

function startAutoUpdate()
        if exports.integration:isPlayerTrialAdmin(localPlayer) then
                setElementData(localPlayer, "report:topRight", 1, true)
        elseif exports.integration:isPlayerSupporter(localPlayer) then
                setElementData(localPlayer, "report:topRight", 2, true)
        else
                setElementData(localPlayer, "report:topRight", 3, true)
        end
end
addEventHandler("onClientResourceStart", thisResourceElement, startAutoUpdate)
