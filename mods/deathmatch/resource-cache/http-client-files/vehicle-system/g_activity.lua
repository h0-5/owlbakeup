--MAXIME / 2015.1.29

function isActive(veh)
	local job = getElementData(veh, "job") or 0
	local owner = getElementData(veh, "owner") or -1
	local faction = getElementData(veh, "faction") or -1
	local Impounded = getElementData(veh, "Impounded") or 0
	if job ~= 0 or owner <= 0 or faction ~= -1 or Impounded ~= 0 then
		return true
	elseif getVehicleType(veh) == "Trailer" then
		return true
	else
		local oneDay = 60*60*24
		local owner_last_login = getElementData(veh, "owner_last_login")
		if owner_last_login and tonumber(owner_last_login) then
			local owner_last_login_text, owner_last_login_sec = exports.datetime:formatTimeInterval(owner_last_login)
			if owner_last_login_sec > oneDay*30 then
				return false, "Inactive Vehicle | Owner is inactive ("..owner_last_login_text..")", owner_last_login_sec
			end
		end

		local int = getElementInterior(veh)
		local dim = getElementDimension(veh)
		if int == 0 and dim == 0 then
			local lastused = getElementData(veh, "lastused")
			if lastused and tonumber(lastused) then
				local lastusedText, lastusedSeconds = exports.datetime:formatTimeInterval(lastused)
				if lastusedSeconds > oneDay*14 then
					return false, "Inactive Vehicle | Last used "..lastusedText.." while parking outdoor", lastusedSeconds
				end
			end
		end
	end
	return true 
end

function isProtected(veh)
	local job = getElementData(veh, "job") or 0
	local owner = getElementData(veh, "owner") or -1
	local faction = getElementData(veh, "faction") or -1
	if job ~= 0 or owner <= 0 or faction ~= -1 then
		return false
	end
	local protected_until = getElementData(veh, "protected_until") or -1
	local protectText, protectSeconds = exports.datetime:formatFutureTimeInterval(protected_until)
	return protectSeconds > 0, protectText, protectSeconds
end