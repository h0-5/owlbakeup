--------------------------------------------------------------------------------
-- NPC ped names — client (Fix #32)
-- 1:1 port of the OLD CLIENT [rp]/ped-system drawPedsName (backupm):
-- every streamed ped with "ped:name" draws "<name> (NPC)" above its head
-- (white name, RED "(NPC)" suffix), within 15 units, with line of sight.
-- The old client gated on character:id (never restored in this stack) —
-- this server's synced loggedin=1 flag is used instead.
--------------------------------------------------------------------------------

local localPlayer = getLocalPlayer()
local peds = {}

-- [Fix #33] per-ped look-at throttle: the old client let named peds glance
-- at you, but calling setPedLookAt EVERY FRAME per ped resets the ped's
-- look-at task 60x/sec (CPU churn). Once per 2.5s is the same effect.
local lastLookAt = {}

-- [Fix #33] one-time error report: a silent per-frame abort killed NPC names
-- AND logged an error every frame (FPS). Wrap the draw, show it once.
-- [Fix #47] "once" became FOREVER - one transient error disabled NPC names
-- for the whole session. Report at most once per 30s, auto-recover instead.
local pedNameErrorShown = false
local pedLastError = 0

-- [Fix #35] one-time gate report: "NPC names never appear" was a silent
-- early return - say WHY the first time it happens (once per session)
local pedGateReported = {}
local function pedGateReport(reason)
        if pedGateReported[reason] then return end
        pedGateReported[reason] = true
        outputChatBox("[NPC names] hidden because: " .. reason, 255, 220, 120, false)
end

local function rebuildList()
        peds = {}
        for _, ped in ipairs(getElementsByType("ped", root, true)) do
                if isElement(ped) and getElementData(ped, "ped:name") then
                        peds[#peds + 1] = ped
                end
        end
end

addEventHandler("onClientElementDataChange", root, function(key, _, value)
        if key == "ped:name" then
                if value and isElement(source) then
                        if getElementType(source) == "ped" and isElementStreamedIn(source) then
                                local found = false
                                for _, ped in ipairs(peds) do
                                        if ped == source then found = true break end
                                end
                                if not found then peds[#peds + 1] = source end
                        end
                else
                        for i = #peds, 1, -1 do
                                if peds[i] == source then table.remove(peds, i) end
                        end
                end
        end
end)

addEventHandler("onClientElementStreamIn", root, function()
        if getElementType(source) == "ped" and getElementData(source, "ped:name") then
                peds[#peds + 1] = source
        end
end)

addEventHandler("onClientElementStreamOut", root, function()
        for i = #peds, 1, -1 do
                if peds[i] == source then table.remove(peds, i) end
        end
        lastLookAt[source] = nil
end)

addEventHandler("onClientPedQuit", root, function()
        for i = #peds, 1, -1 do
                if peds[i] == source then table.remove(peds, i) end
        end
        lastLookAt[source] = nil
end)

setTimer(rebuildList, 3000, 0)
addEventHandler("onClientResourceStart", resourceRoot, rebuildList)

addEventHandler("onClientRender", root, function()
        local ok, err = pcall(drawPedsName)
        if not ok then
                local now = getTickCount()
                if now - pedLastError > 30000 then
                        pedLastError = now
                        outputChatBox("[NPC names] " .. tostring(err), 255, 100, 100, false)
                end
        end
end, false, "high-2")

local function isPlayerMapVisibleSafe()
        if isPlayerMapVisible and isPlayerMapVisible() then return true end
        return false
end

function drawPedsName()
        if getElementData(localPlayer, "loggedin") ~= 1
                and not getElementData(localPlayer, "character:id") then
                pedGateReport("waiting for character select (loggedin="
                        .. tostring(getElementData(localPlayer, "loggedin")) .. ")")
                return
        end
        if isPlayerMapVisibleSafe() then return end
        if #peds == 0 then
                pedGateReport("no named NPC peds in range (nothing carries ped:name data)")
                return
        end

        local camX, camY, camZ = getCameraMatrix()
        local now = getTickCount()
        for i = 1, #peds do
                local ped = peds[i]
                if isElement(ped) and isElementOnScreen(ped) then
                        local name = getElementData(ped, "ped:name")
                        if name then
                                local hx, hy, hz = getPedBonePosition(ped, 8)
                                if hx then
                                        local dist = getDistanceBetweenPoints3D(camX, camY, camZ, hx, hy, hz)
                                        if dist <= 15 then
                                                -- old client: peds glance at you while named
                                                -- [Fix #33] throttled - the task must not be reset
                                                -- every frame
                                                if (lastLookAt[ped] or 0) + 2500 < now then
                                                        lastLookAt[ped] = now
                                                        setPedLookAt(ped, hx, hy, hz, -1, 500)
                                                end
                                                if isLineOfSightClear(camX, camY, camZ, hx, hy, hz,
                                                        true, false, false, true, false, false, false) then
                                                        local sX, sY = getScreenFromWorldPosition(hx, hy, hz)
                                                        if sX then
                                                                -- old: shadow pass + white pass with RED (NPC)
                                                                dxDrawText(name .. " (NPC)", sX + 2, sY + 2, sX + 2, sY + 2,
                                                                        tocolor(0, 0, 0, 255), 1, "default-bold", "center", "top")
                                                                dxDrawText(name .. " #FF0000(NPC)", sX, sY, sX, sY,
                                                                        tocolor(255, 255, 255, 255), 1, "default-bold",
                                                                        "center", "top", false, false, false, true)
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end
end
-- drawPedsName ends here; the pcall'd onClientRender handler above is the
-- only registration (Fix #33)
