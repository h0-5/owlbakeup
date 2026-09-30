--[[ =========================================================================
        c_turf.lua — Vortex TURF SYSTEM client (Fix #57)

        1:1 port of the OLD CLIENT turf-system client_decompiled.lua
        (the only file that survived the decompile):

          * circular SVG progress ring (r=50 -> stroke-dasharray 315,
            setProgress clamps 0..100 and writes stroke-dashoffset
            315 - pct/100*315 - the exact old math, same pattern as the
            owl hud status rings)
          * TurfArea draw: ring + turf ID centered (white shadow + colored
            duplicate = old double-draw), "pct%\nGroup" under the ring
            (white shadow + colored = old double-draw)
          * events kept EXACTLY:
              OS:AREA.ShowProgress  (turf data table)
              OS:AREA.UpdateAreaDB  (Turf, MaxTurf, Group, TurfGroup, OldTurf, ID)
              OS:AREA.HideProgress
          * export kept: getGroupTurfAreas(group)
          * adaptation: the decompile's svgCreate(...) source XML was lost,
            so the same ring is rebuilt here as an inline SVG document
            (identical geometry), drawn top-center of the screen
========================================================================= ]]

local SVG_SIZE = 120
local SVG_XML = string.format(
        [[<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">
<circle cx="60" cy="60" r="50" fill="rgba(0,0,0,0.55)"/>
<circle cx="60" cy="60" r="50" fill="none" stroke="rgba(255,255,255,0.14)" stroke-width="8"/>
<circle id="progress" cx="60" cy="60" r="50" fill="none" stroke="#ff375f" stroke-width="8" stroke-linecap="round" stroke-dasharray="315" stroke-dashoffset="315" transform="rotate(-90 60 60)"/>
</svg>]], SVG_SIZE, SVG_SIZE)

local ring, ringXml, progressNode
local turfData = false -- { ID, Turf, MaxTurf, Group, TurfGroup, OldTurf }
local drawing = false

local function init()
        if isElement(ring) then return end
        ring = svgCreate(SVG_SIZE, SVG_SIZE, SVG_XML, function()
                if not ring then return end
                ringXml = svgGetDocumentXML(ring)
                if ringXml then
                        progressNode = xmlFindChild(ringXml, "circle", 2)
                end
        end)
end
addEventHandler("onClientResourceStart", resourceRoot, init)

function setProgress(pct)
        pct = math.max(0, math.min(pct, 100))
        if progressNode and ringXml then
                xmlNodeSetAttribute(progressNode, "stroke-dashoffset", 315 - pct / 100 * 315)
                svgSetDocumentXML(ring, ringXml)
        end
end

function TurfArea()
        if not isElement(ring) then return end
        if not turfData then return end
        local _, sh = guiGetScreenSize()
        local s = 130
        local x, y = guiGetScreenSize() -- anchor top-center
        x = (x - s) / 2
        y = 18
        local r, g, b = 255, 55, 95 -- old accent (255, 55, 95)
        if turfData.TurfGroup and turfData.Group and turfData.TurfGroup ~= turfData.Group then
                r, g, b = 174, 0, 255 -- attacker color (old radar wayColor purple)
        end
        local pct = math.floor(turfData.Turf / math.max(turfData.MaxTurf, 1) * 100)
        dxDrawImage(x, y, s, s, ring, 0, 0, 0, tocolor(255, 255, 255, 255), false)
        -- ID (white shadow then colored, old double-draw)
        dxDrawText(tostring(turfData.ID), x + 2, y + 2, x + s, y + s,
                tocolor(255, 255, 255, 255), 1.1, "default-bold", "center", "center", false, false, false, false, false)
        dxDrawText(tostring(turfData.ID), x, y, x + s, y + s,
                tocolor(r, g, b, 255), 1.1, "default-bold", "center", "center", false, false, false, false, false)
        -- pct + group (white shadow then colored, old double-draw)
        local label = tostring(pct) .. "%\n" .. tostring(turfData.Group or "")
        dxDrawText(label, 1, y + s + 11 * (sh / 1080), sh, 270 * (sh / 1080),
                tocolor(255, 255, 255, 255), 0.9, "default-bold", "center", "top", false, false, false, false, false)
        dxDrawText(label, 0, y + s + 10 * (sh / 1080), sh, 270 * (sh / 1080),
                tocolor(r, g, b, 255), 0.9, "default-bold", "center", "top", false, false, false, false, false)
end

addEvent("OS:AREA.ShowProgress", true)
addEventHandler("OS:AREA.ShowProgress", root, function(data)
        turfData = data
        if data then
                setProgress((data.Turf or 0) / math.max(data.MaxTurf or 1, 1) * 100)
        end
        if not drawing then
                addEventHandler("onClientRender", root, TurfArea, false)
                drawing = true
        end
end)

addEvent("OS:AREA.UpdateAreaDB", true)
addEventHandler("OS:AREA.UpdateAreaDB", root, function(Turf, MaxTurf, Group, TurfGroup, OldTurf, ID)
        turfData = {
                ID = ID, Turf = Turf, MaxTurf = MaxTurf,
                Group = Group, TurfGroup = TurfGroup, OldTurf = OldTurf,
        }
        setProgress((Turf or 0) / math.max(MaxTurf or 1, 1) * 100)
end)

addEvent("OS:AREA.HideProgress", true)
addEventHandler("OS:AREA.HideProgress", root, function()
        if drawing then
                removeEventHandler("onClientRender", root, TurfArea)
                drawing = false
        end
        turfData = false
end)

-- old export: every colshape of this resource carrying OS:AREA.DB with the
-- given owner group -> { {colshape, db}, ... }
function getGroupTurfAreas(group)
        local out = {}
        for _, col in ipairs(getElementsByType("colshape", resourceRoot)) do
                local db = getElementData(col, "OS:AREA.DB")
                if db and db.Group == group then
                        table.insert(out, { col, db })
                end
        end
        return out
end
