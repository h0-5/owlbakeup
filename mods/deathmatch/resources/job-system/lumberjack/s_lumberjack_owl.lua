-- owlbakeup Fix #63 - Lumberjack SERVER, rebuilt from the client contract
-- ([jobs]/lumberjack/client_decompiled.lua, Fix #54 pattern):
--   Lumberjack:ProgressState ("Show"/"Hide") + "WM:CutProgress" elementData
--   are driven by the cutting loop below - RECONSTRUCTED server data (the
--   old server was lost; the decompiled client ships the progress display
--   only). Trees carry a right-click "Chop" option (the Fix #60 interaction
--   menu shows rightclick:menu objects), cutting runs progress mirrored onto
--   the tree's WM:CutProgress exactly the way the decompiled bar reads it,
--   then grants Wood (#227 - the gunsmith factory consumes it).
--   No job gating / no givePlayerJobEXP call exists in the decompile - it
--   is an open site flow like the miner, so there is no jobs_data entry.

local TREE_RESPAWN_MS = 20000

-- reconstructed tree patch (forest west of the LV quarry)
local TREE_SPOTS = {
	{ 2050.5, 742.2, 0, 615 },
	{ 2078.3, 761.9, 0, 615 },
	{ 2096.8, 733.5, 0, 615 },
	{ 2123.4, 758.8, 0, 615 },
	{ 2041.7, 780.4, 0, 615 },
	{ 2110.2, 792.6, 0, 615 },
	{ 2064.9, 805.3, 0, 615 },
	{ 2135.8, 727.1, 0, 615 }
}

local trees = {} -- [tree element] = entry

local function spawnTrees()
	for _, spot in ipairs(TREE_SPOTS) do
		local z = getGroundPosition(spot[1], spot[2], 30)
		if not z or z == 0 then
			z = 12
		end
		local tree = createObject(spot[4], spot[1], spot[2], z)
		if tree then
			setElementData(tree, "rightclick:title", "Tree")
			setElementData(tree, "rightclick:menu", { { Text = "Chop" } })
			setElementData(tree, "WM:CutProgress", 0)
			trees[tree] = { element = tree }
		end
	end
end

local function stopCutting(entry)
	if entry.timer and isTimer(entry.timer) then
		killTimer(entry.timer)
	end
	entry.timer = nil
	entry.worker = nil
	setElementData(entry.element, "WM:CutProgress", 0)
end

addEventHandler("onClientElementMenuClick:Server", root, function(element, optionText)
	local player = client
	if not player or optionText ~= "Chop" then
		return
	end
	local entry = trees[element]
	if not entry or entry.worker then
		return
	end
	local px, py, pz = getElementPosition(player)
	local tx, ty, tz = getElementPosition(element)
	if getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) > 5 then
		return
	end
	entry.worker = player
	setElementData(element, "WM:CutProgress", 0)
	triggerClientEvent(player, "Lumberjack:ProgressState", player, "Show", element)
	local progress = 0
	entry.timer = setTimer(function(entry)
		if not isElement(entry.element) or not isElement(entry.worker) then
			stopCutting(entry)
			return
		end
		progress = progress + 2
		if progress >= 100 then
			setElementData(entry.element, "WM:CutProgress", 100)
			local worker = entry.worker
			triggerClientEvent(worker, "Lumberjack:ProgressState", worker, "Hide", entry.element)
			stopCutting(entry)
			setElementData(entry.element, "rightclick:menu", {})
			setTimer(function(entry)
				if isElement(entry.element) then
					setElementData(entry.element, "rightclick:menu", { { Text = "Chop" } })
				end
			end, TREE_RESPAWN_MS, 1, entry)
			exports["item-system"]:giveItem(worker, 227, 1) -- Wood
			exports.notifications:outputToPlayer(worker, "حصلت على خشب", 5000, "info")
			return
		end
		setElementData(entry.element, "WM:CutProgress", progress)
	end, 200, 50, entry)
end)

addEventHandler("onPlayerQuit", root, function()
	for _, entry in pairs(trees) do
		if entry.worker == source then
			triggerClientEvent(entry.worker, "Lumberjack:ProgressState", entry.worker, "Hide", entry.element)
			stopCutting(entry)
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	spawnTrees()
end)

addEventHandler("onResourceStop", resourceRoot, function()
	for tree, _ in pairs(trees) do
		if isElement(tree) then
			destroyElement(tree)
		end
	end
end)
