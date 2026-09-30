-- ============================================================================
-- skin-system / g_skins.lua                      (Fix #65)
-- ----------------------------------------------------------------------------
-- Shared config of the old Owl client's player-skin shop ("Fashion Dupont"),
-- restored from /home/daytona/backupm/[rp]/skin-system/skin_c_decompiled.lua.
--
-- The catalogue lives in the `clothing` table, the one the clothing shop
-- (mabako-clothingstore) and the texture/item pipeline already use:
--
--   clothing.id    -> the value of item 16 ("Clothes", value "skin:clothing.id")
--   clothing.skin  -> the ped model the buyer wears
--   clothing.url   -> the .png the clothing shader streams to the client
--   clothing.private / clothing.owner -> the old client's two extra fields,
--                     added by Fix #65 (see mods/deathmatch/pdz_missing_tables.sql)
--
-- Because a bought skin is handed out as item 16, wearing it reuses the exact
-- same code path as the clothing store (setElementModel + `clothing:id` + the
-- replacement shader) instead of the old client's own downloader.
-- ============================================================================

SKINS = {
	table = "clothing",
	-- the ped interact type that opens the shop (ped-system's interactTypes has
	-- "skins" in its list, exactly like the old client's `ped:interact`)
	pedInteract = "skins",
	-- talk range used to validate a purchase against the ped
	talkDistance = 5,
	-- accounts that may add skins for the shop (mirrors the old
	-- mabako-clothingstore/g_util.lua `canEdit` whitelist)
	shopOwners = {
		["MisterShmopie"] = true,
		["cigar"] = true,
	},
	events = {
		getDatabase = "skins:getSkinsDatabase",
		sendDatabase = "skins:sendSkinsDatabaseToClient",
		showAddWindow = "skins:showAddSkinWindow",
		buy = "skins:buySkin",
		add = "skins:addNewSkin",
		update = "skins:updateSkin",
		remove = "skins:removeSkin",
	},
}
