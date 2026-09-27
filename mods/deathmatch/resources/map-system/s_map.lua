--------------------------------------------------------------------------------
-- Vortex map-system — server (Fix #27)
--
-- F11 map companion for the HUD. Backend side:
--   * PERMISSIONS: "map:seeNames" element data decides who can see player
--     names on the big map. Staff only (trial admin / supporter on the
--     integration ladder, or anyone on admin duty). Everyone logged in can
--     see the map itself.
--   * The permission is pushed on login, on resource start for already
--     online players and on every admin-duty change, so going off duty
--     removes the names immediately (same rule as the nametag badge).
--------------------------------------------------------------------------------

local function isStaffPlayer(player)
        if (tonumber(getElementData(player, "duty_admin")) == 1)
                or (tonumber(getElementData(player, "duty_supporter")) == 1) then
                return true
        end
        local integ = getResourceFromName("integration")
        if integ and getResourceState(integ) == "running" then
                local okA, admin = pcall(function() return exports.integration:isPlayerTrialAdmin(player) end)
                local okS, sup = pcall(function() return exports.integration:isPlayerSupporter(player) end)
                if (okA and admin) or (okS and sup) then return true end
        end
        return (tonumber(getElementData(player, "admin_level")) or 0) > 0
                or (tonumber(getElementData(player, "account:gmlevel")) or 0) > 0
end

local function pushPerms(player)
        if not isElement(player) then return end
        setElementData(player, "map:seeNames", isStaffPlayer(player) and true or false)
end

addEventHandler("onPlayerLogin", root, function() pushPerms(source) end)
addEventHandler("onPlayerJoin", root, function() pushPerms(source) end)

addEventHandler("onResourceStart", resourceRoot, function()
        for _, player in ipairs(getElementsByType("player")) do
                pushPerms(player)
        end
end)

-- duty toggles re-evaluate the permission (badge rule: off duty = no names)
addEventHandler("onElementDataChange", root, function(key, _, newValue)
        if key ~= "duty_admin" and key ~= "duty_supporter" then return end
        if getElementType(source) ~= "player" then return end
        pushPerms(source)
end)
