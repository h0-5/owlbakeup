DutyColShapes = { }
function createDutyColShape(posX, posY, posZ, size, interior, dimension, factionID, locationID)
    tempShape = createColSphere(tonumber(posX), tonumber(posY), tonumber(posZ), tonumber(size))
	setElementDimension(tempShape, tonumber(dimension) or 0)
	setElementInterior(tempShape, tonumber(interior) or 0)
	if tempShape then
		if type(DutyColShapes[tonumber(factionID)]) ~= "table" then
			DutyColShapes[tonumber(factionID)] = { }
		end
    	DutyColShapes[tonumber(factionID)][tonumber(locationID)] = tempShape
    	setElementData(resourceRoot, "DutyColShapes", DutyColShapes)
    	return true
    end
end

function destroyDutyColShape(factionID, locationID)
	if DutyColShapes[tonumber(factionID)][tonumber(locationID)] then
		destroyElement(DutyColShapes[tonumber(factionID)][tonumber(locationID)])
		DutyColShapes[tonumber(factionID)][tonumber(locationID)] = nil
		setElementData(resourceRoot, "DutyColShapes", DutyColShapes)
		return true
	end
end

-- -------------------------- --
-- General checking functions -- Revised by Chaos for OwlGaming < Old way was shitty less loops now
-- -------------------------- --

function fetchAvailablePackages( targetPlayer )
    local availablePackages = { }
    local factionID = tonumber(getElementData(targetPlayer, "faction"))
    local factionDuty = getElementData(resourceRoot, "factionDuty")
    local factionLocations = getElementData(resourceRoot, "factionLocations") or { } -- [Fix #126] element data may not have arrived yet
    local DutyColShapes = getElementData(resourceRoot, "DutyColShapes") or { } -- [Fix #126] element data may not have arrived yet

        if type(factionDuty) == "table" and factionDuty[factionID] then -- [Fix #126] nil-guard
            for i, factionPackage in pairs ( factionDuty[factionID] ) do -- Loop all the faction packages
                local found = false
                for index, v in pairs ( factionPackage[4] or { } ) do -- [Fix #126] nil-guard -- Loop all the colshapes of the factionpackage
                	if type(DutyColShapes[factionID]) == "table" and isElement(DutyColShapes[factionID][tonumber(index)]) then -- [Fix #126]
                    	if isElementWithinColShape( targetPlayer, DutyColShapes[factionID][tonumber(index)] ) then
                      	  found = true
                      	  break  -- We found this package already, no need to search the other colshapes
                   	 	end
                   	end
                end

                local veh = getPedOccupiedVehicle(targetPlayer) -- Still can't find it? Lets see if they are in a duty vehicle
                if not found and veh then
                	local vehid = getElementData(veh, "dbid")
                	for k,v in pairs(factionLocations[factionID] or { }) do -- [Fix #126] nil-guard
                		if tonumber(vehid) == tonumber(v[9]) then -- Yep vehicle ID matches!
                    		found = true
                    	end
                    end
                end

                if found and canPlayerUseDutyPackage(targetPlayer, i) then
                    table.insert(availablePackages, factionPackage)
                end
            end
        end
    local resource = getResourceRootElement(getResourceFromName("faction-system"))
    local allowList = nil -- [Fix #125] local and recomputed on every call, never a stale global
	if resource then
		local allowTable = getElementData(resource, "dutyAllowTable") -- [Fix #125] renamed so the raw table is never clobbered
		local key = nil -- [Fix #125] recomputed per call, never a stale global
		if type(allowTable) == "table" then
		for k,v in pairs(allowTable) do -- [Fix #125] was the already-resolved allowList
			if type(v) == "table" and tonumber(v[1]) == factionID then -- [Fix #125] nil-guard every index
				key = k
				break
			end
		end
		if key ~= nil and type(allowTable[key]) == "table" then -- [Fix #125] no row / no key must not throw
			allowList = allowTable[key][3] -- [Fix #125] nil-guarded index
		end
	end
	end
    return availablePackages, allowList or { } -- [Fix #125] never return nil, consumers pairs() this
end

function getGrant(thePlayer, grantID, factionID)
	local factionID = tonumber(factionID)
	local factionDuty = getElementData(resourceRoot, "factionDuty")
	if type(factionDuty) ~= "table" or type(factionDuty[factionID]) ~= "table" then -- [Fix #106] faction data not loaded yet
		return nil
	end

	return factionDuty[factionID][tonumber(grantID)]
end

function canPlayerUseDutyPackage(targetPlayer, packageID)
	local package = tonumber(packageID)
    local playerPackagePermission = getElementData(targetPlayer, "factionPackages")
    if type(playerPackagePermission) == "string" then -- [Fix #119] payload may be raw JSON
		playerPackagePermission = fromJSON(playerPackagePermission)
	end

	if package and type(playerPackagePermission) == "table" then -- [Fix #119]
        for key, permissionID in pairs(playerPackagePermission) do -- [Fix #119] pairs() covers arrays AND objects
            if tonumber(key) == package or tonumber(permissionID) == package then -- [Fix #119] numeric key or value; {["1"]=true} works, text keys ignored
                return true
            end
        end
    end
    return false
end

function getFactionPackages( factionID )
    if not factionID or not tonumber( factionID ) then
        return false
    end
    local factionDuty = getElementData(resourceRoot, "factionDuty")

    return factionDuty[tonumber(factionID)]
end
addEvent("onPlayerDuty", true)
