-- anim-system - Owl old-client port (Fix #59)
-- Reconstructed from arma-backupm/[rp]/anim-system/c_anims_decompiled.lua.
-- Ported here: the animation DATABASE + getAllAnimations export (consumed by
-- the ped editor), IFP replacement, chat animation commands, applyAnimation.
-- NOT ported yet: the /animselect UIKit window + N quick-menu (their decompile
-- lost the UI state tables; scheduled for a dedicated follow-up fix).

local animData = { groups = {}, anims = {}, ifp = { block = "ped", ifp = false } }
local lastAnimTick = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
	local xml = xmlLoadFile("animations.xml")
	if xml then
		for _, groupNode in ipairs(xmlNodeGetChildren(xml) or {}) do
			local groupName = xmlNodeGetAttribute(groupNode, "name")
			if groupName then
				table.insert(animData.groups, groupName)
				animData.anims[groupName] = {}
				for _, animNode in ipairs(xmlNodeGetChildren(groupNode) or {}) do
					local animName = xmlNodeGetAttribute(animNode, "name")
					if animName then
						table.insert(animData.anims[groupName], animName)
					end
				end
			end
		end
		xmlUnloadFile(xml)
	else
		outputDebugString("anim-system: animations.xml failed to load", 2)
	end

	-- custom IFP libraries (files were not part of the client backup; load
	-- is guarded so a missing .ifp never breaks the resource)
	animData.ifp.ifp = engineLoadIFP("ped.ifp", animData.ifp.block)
	engineLoadIFP("sword.ifp", "swordBIOS")
	engineLoadIFP("salute.ifp", "salute")
	engineLoadIFP("ghands.ifp", "salute2")

	for _, player in ipairs(getElementsByType("player")) do
		replacePedAnimations(player)
	end
end)

function replacePedAnimations(ped)
	if not animData.ifp.ifp then
		return false
	end
	for _, animName in ipairs(animData.anims["ifp"] or {}) do
		engineReplaceAnimation(ped, "ped", animName, animData.ifp.block, animName)
	end
	return true
end

addEventHandler("onClientPlayerJoin", root, function()
	replacePedAnimations(source)
end)

addEvent("anims:setPedCustomAnimation", true)
addEventHandler("anims:setPedCustomAnimation", root, function(block, anim, time, loop, updatePosition, interruptible, freezeLastFrame)
	if isElement(source) then
		setPedAnimation(source, block, anim, time, loop, updatePosition, interruptible, freezeLastFrame)
	end
end)

function getAllAnimations()
	return animData
end

function isAnimBlocked(ped)
	local block = getElementData(ped, "temp:block.anims")
	if type(block) == "table" then
		return getTickCount() - block[1] <= block[2]
	end
	return block and true or false
end

function applyAnimation(animName)
	if isPedInVehicle(localPlayer) then
		return
	end
	if isPedDead(localPlayer) then
		return
	end
	local moveState = getPedMoveState(localPlayer)
	if moveState == "walk" or moveState == "powerwalk" or moveState == "jog" or moveState == "sprint" or moveState == "jump" or moveState == "fall" then
		return
	end
	if isAnimBlocked(localPlayer) then
		return
	end
	if lastAnimTick and getTickCount() - lastAnimTick < 1000 then
		return
	end
	lastAnimTick = getTickCount()
	triggerLatentServerEvent("anims:command", 50000, localPlayer, animName)
end

for _, commandName in ipairs({
	"fucku", "fu", "sit", "getup", "cover", "wait", "think", "shake", "lean",
	"handsup", "heiltaxi", "hailtaxi", "heil", "smoke", "lightup", "lay",
	"cry", "rap1", "rap2", "rap3", "salute", "wave", "never", "fall",
	"fallfront", "backhands", "kiss", "crack", "bye", "cpr", "laugh",
	"tired", "shove", "what", "win", "strip", "scratch", "idle",
	"copcome", "copleft", "copstop",
}) do
	addCommandHandler(commandName, applyAnimation, false)
end
