-- anim-system - server (Fix #59)
-- Validates animation requests against the shared animation catalog and
-- applies them server-side (server peds sync natively to every client).

local validAnims = nil

local function buildCatalog()
	validAnims = {}
	local xml = xmlLoadFile("animations.xml")
	if xml then
		for _, groupNode in ipairs(xmlNodeGetChildren(xml) or {}) do
			for _, animNode in ipairs(xmlNodeGetChildren(groupNode) or {}) do
				local animName = xmlNodeGetAttribute(animNode, "name")
				if animName then
					validAnims[string.lower(animName)] = string.upper(xmlNodeGetAttribute(groupNode, "name"))
				end
			end
		end
		xmlUnloadFile(xml)
	end
end
addEventHandler("onResourceStart", getResourceRootElement(), buildCatalog)

local commandAliases = {
	fucku = "fucku", fu = "fucku", sit = "sit", getup = "getup", cover = "cover",
	wait = "idle_chat", think = "idle_chat", shake = "shake_cara", lean = "lean_idle",
	handsup = "handsup", heiltaxi = "hailtaxi", hailtaxi = "hailtaxi", heil = "heil",
	smoke = "smoke", lightup = "lightup", lay = "lay", cry = "cry",
	rap1 = "rap_a", rap2 = "rap_b", rap3 = "rap_c", salute = "salute", wave = "wave",
	never = "never", fall = "fall_wall", fallfront = "fall_front", backhands = "backhands",
	kiss = "kiss", crack = "crack", bye = "wave", cpr = "cpr", laugh = "laugh",
	tired = "tired", shove = "shove", what = "what", win = "win", strip = "strip_loops",
	scratch = "scratch", idle = "idle_stance", copcome = "cop_move_in",
	copleft = "cop_left", copstop = "cop_stop",
}

local function applyAnimationToPlayer(player, block, anim, loop)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	if getElementData(player, "temp:block.anims") then
		return false
	end
	setPedAnimation(player, block, anim, -1, loop and true or true, false, false, false)
	return true
end

addEvent("anims:applyAnimation", true)
addEventHandler("anims:applyAnimation", root, function(block, anim, loop)
	if type(block) ~= "string" or type(anim) ~= "string" then
		return
	end
	applyAnimationToPlayer(client, string.upper(block), anim, loop)
end)

addEvent("anims:command", true)
addEventHandler("anims:command", root, function(animName)
	if type(animName) ~= "string" then
		return
	end
	local alias = commandAliases[animName] or animName
	if validAnims and not validAnims[string.lower(alias)] then
		return
	end
	local block = validAnims and validAnims[string.lower(alias)] or "ped"
	applyAnimationToPlayer(client, block, alias, true)
end)
