--MAXIME
function debugResource(thePlayer, commandName, ...)
	if not exports.integration:isPlayerScripter(thePlayer) then
		return false
	end
	
	if not (...) then
		outputChatBox("SYNTAX: /" .. commandName .. " [Resource Name]", thePlayer, 255, 194, 14)
		outputChatBox("Toggle resource's debug mode.", thePlayer, 200, 200, 200)
		return false
	end
	
	local resName = table.concat({...}, "-")
	local resourceRoot = getResourceFromName( resName )
	
	if not resourceRoot then
		outputChatBox("Resource '"..resName.."' isn't running.", thePlayer, 255, 0, 0)
		return false
	end
	
	resourceRoot = getResourceRootElement(resourceRoot)
	
	if getElementData(resourceRoot, "debug_enabled") then
		if setElementData(resourceRoot, "debug_enabled", false, true) then
			for i, player in pairs(getElementsByType("player")) do
				if exports.global:isPlayerScripter(player) then
					outputChatBox("[SCRIPT] "..exports.global:getPlayerFullIdentity(thePlayer, nil, true).. " has deactivated debug mode on resource '"..resName.."'.", player, 255, 0, 0)
				end
			end
		end
	else
		if setElementData(resourceRoot, "debug_enabled", true, true) then
			for i, player in pairs(getElementsByType("player")) do
				if exports.global:isPlayerScripter(player) then
					outputChatBox("[SCRIPT] "..exports.global:getPlayerFullIdentity(thePlayer, nil, true).. " has activated debug mode on resource '"..resName.."'.", player, 255, 0, 0)
				end
			end
		end
	end
end
addCommandHandler("debugresource", debugResource)
addCommandHandler("debugres", debugResource)