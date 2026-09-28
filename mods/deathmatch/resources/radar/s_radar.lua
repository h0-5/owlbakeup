--[[ =========================================================================
        s_radar.lua — Vortex RADAR server (Fix #55)

        * MAP BLIPS: the old client's resources each created their own blips
          with the 'icon' elementData + 'blip:name' labels - the decompile did
          not survive those, so the curated location set is rebuilt here
          (hospitals / police / banks / fuel / garages / airports / city hall /
          jobs / shops / clothes / food / ammu / taxi / news / mechanic).
          Every blip carries 'blip:name' so the big-map sidebar lists it and
          'icon' so the custom renderer picks the right PNG.
        * ROUTE SYNC: radar:onFindBestWay (double-click while driving) ->
          radar:findBestWay:sync to everyone in the same vehicle so the
          passengers see the driver's route (old behavior).
        * exports: createNamedBlip(x, y, z, icon, name, colorHex) so other
          resources can add map blips with the same contract.
========================================================================= ]]

local namedBlips = {}

-- {name, icon, color, blips = {{x, y, z}, ...}}  (GTA SA public landmarks)
local LOCATIONS = {
        { name = "All Saints Hospital", icon = "4", blips = { { 1173.9, -1323.3, 15.4 } } },
        { name = "County General Hospital", icon = "4", blips = { { 2029.8, -1420.5, 16.9 } } },
        { name = "San Fierro Medical", icon = "4", blips = { { -2655.0, 635.0, 14.4 } } },
        { name = "Redsands Hospital", icon = "4", blips = { { 1601.5, 1817.5, 12.5 } } },
        { name = "LSPD", icon = "1", blips = { { 1544.4, -1675.7, 13.5 } } },
        { name = "SFPD", icon = "1", blips = { { -2172.2, 244.6, 35.5 } } },
        { name = "LVPD", icon = "1", blips = { { 2289.9, 2430.0, 10.8 } } },
        { name = "City Hall", icon = "53", blips = { { 1481.1, -1746.5, 15.5 } } },
        { name = "Bank", icon = "10", blips = {
                { 596.2, -1243.0, 18.6 },
                { -1971.0, 459.2, 35.1 },
                { 2170.9, 1678.6, 11.2 },
        } },
        { name = "Jobs Center", icon = "27", blips = { { 1368.4, -1279.7, 13.5 } } },
        { name = "Airport", icon = "36", blips = {
                { 1952.9, -2214.6, 13.5 },
                { -1361.4, -230.8, 14.1 },
                { 1677.2, 1447.9, 10.8 },
        } },
        { name = "Fuel Station", icon = "49", blips = {
                { 1920.5, -1776.5, 13.5 },
                { 1001.5, -937.0, 42.1 },
                { -1670.5, 414.5, 7.3 },
                { 2200.0, 2474.5, 10.8 },
                { 1596.0, 2199.0, 10.8 },
                { 703.0, 1490.0, 5.5 },
        } },
        { name = "Garage", icon = "6", blips = {
                { 1024.9, -1024.9, 32.1 },
                { 487.5, -1738.5, 11.2 },
                { -1935.0, 235.0, 34.0 },
                { 2184.5, 1980.0, 10.8 },
        } },
        { name = "Ammu-Nation", icon = "55", blips = {
                { 1368.5, -1280.0, 13.5 },
                { -2625.5, 210.5, 4.6 },
                { 2400.0, 1980.0, 10.8 },
        } },
        { name = "Clothes Store", icon = "22", blips = {
                { 1457.0, -1137.5, 24.0 },
                { 2113.0, -1611.5, 13.5 },
                { -2048.5, 139.0, 29.0 },
        } },
        { name = "Restaurant", icon = "14", blips = {
                { 1372.5, -1278.5, 13.5 },
                { 2102.5, 2228.5, 11.0 },
                { -2335.5, 165.0, 35.5 },
                { 2362.5, 2068.5, 10.8 },
        } },
        { name = "General Store", icon = "30", blips = {
                { 1352.5, -1759.0, 13.5 },
                { 2090.5, 2241.5, 11.0 },
                { -2413.5, 331.5, 35.5 },
        } },
        { name = "Mechanic", icon = "41", blips = { { 1972.0, -2244.0, 13.5 } } },
        { name = "Taxi Company", icon = "56", blips = { { 1789.5, -1902.0, 13.5 } } },
        { name = "News Station", icon = "51", blips = { { 1653.5, -1655.5, 22.0 } } },
}

local function addNamedBlip(x, y, z, icon, name, colorHex)
        local blip = createBlip(x, y, z, 0, 2, 255, 255, 255, 255, 0, 6000)
        if not blip then return nil end
        setElementData(blip, "icon", tostring(icon), true)
        setElementData(blip, "blip:name", tostring(name), true)
        if colorHex then setElementData(blip, "blip:color", tostring(colorHex), true) end
        table.insert(namedBlips, blip)
        return blip
end

local function loadMapBlips()
        for _, loc in ipairs(LOCATIONS) do
                for _, pos in ipairs(loc.blips) do
                        addNamedBlip(pos[1], pos[2], pos[3], loc.icon, loc.name)
                end
        end
        outputDebugString("[radar] map blips loaded: " .. #namedBlips)
end
addEventHandler("onResourceStart", resourceRoot, loadMapBlips)

-- route sync: the driver's double-click route is shared with the vehicle
-- occupants so the whole car sees the same purple line (old behavior)
addEvent("radar:onFindBestWay", true)
addEventHandler("radar:onFindBestWay", root, function(wx, wy)
        if not isElement(client) or client ~= source then return end
        local veh = getPedOccupiedVehicle(client)
        if not veh then return end
        local occupants = getVehicleOccupants(veh)
        if not occupants then return end
        for _, occ in pairs(occupants) do
                if isElement(occ) and getElementType(occ) == "player" then
                        triggerClientEvent(occ, "radar:findBestWay:sync", client, wx, wy)
                end
            end
end)

-- API for other resources: a blip with a name + icon renders on both the
-- minimap and the F11 big map, and is listed in the big-map sidebar
function createNamedBlip(x, y, z, icon, name, colorHex)
        return addNamedBlip(x, y, z, icon, name, colorHex)
end

function getMapBlips()
        return namedBlips
end
