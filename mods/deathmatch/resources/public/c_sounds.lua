-- Decompiled by Owl Decompiler v1.0 (public/sounds_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with one artifact repair:
--   * the decompile called playSound3D twice (inside setSoundMaxDistance
--     and setSoundPosition) which spawned two overlapping sounds - the
--     original held one local sound element.

local sounds3D = {}

addEvent("sounds:3D:play", true)
addEventHandler("sounds:3D:play", root, function(id, data, position)
	local sound = playSound3D(data.path, data.x, data.y, data.z, data.looped)
	setSoundMaxDistance(sound, data.maxDistance)
	setSoundPosition(sound, position)
	sounds3D[id] = sound
end)

addEvent("sounds:3D:stop", true)
addEventHandler("sounds:3D:stop", root, function(id)
	if sounds3D[id] then
		stopSound(sounds3D[id])
	end
	sounds3D[id] = nil
end)

addEvent("sounds:play", true)
addEventHandler("sounds:play", root, function(path, looped, volume)
	playSound(path, looped, volume)
end)
