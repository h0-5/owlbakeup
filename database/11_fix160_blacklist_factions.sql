-- ============================================================================
-- VORTEX — DATABASE SCHEMA part 3 (Fix #160): البلاك ليست والفاكشن
-- ============================================================================
-- The two CREATE TABLE statements are idempotent; the ALTER at the bottom
-- errors harmlessly ("Duplicate column") if `country` already exists.
-- (The runtime resources also run these themselves: account/s_blacklist.lua
--  and faction-system/s_faction_fix160.lua create them lazily if missing.)

-- ---------------------------------------------------------------------------
-- BLACKLIST: البلاك ليست (account/s_blacklist.lua)
--   /blacklistadd  -> row here + mirror into bannedips/bannedserials with
--                     the "[blacklist] " prefix (see global/s_bannedPlayers.lua)
--   /blacklistremove -> delete row + unmirror
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `blacklist` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `account` VARCHAR(64) DEFAULT NULL,
  `account_id` INT DEFAULT NULL,
  `serial` VARCHAR(32) DEFAULT NULL,
  `ip` VARCHAR(45) DEFAULT NULL,
  `iprange` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `device` VARCHAR(64) DEFAULT NULL,
  `reason` TEXT DEFAULT NULL,
  `addedby` VARCHAR(64) DEFAULT NULL,
  `date` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `bl_account` (`account`),
  KEY `bl_serial` (`serial`),
  KEY `bl_ip` (`ip`),
  KEY `bl_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- FACTIONS BLACKLIST: قائمة حظر الفاكشن (faction-system/s_faction_fix160.lua)
--   يمنع اللاعب من الدخول للفاكشن بعد طرده (/addfbl /removefbl /showfbl)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `factions_blacklist` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `factionid` INT NOT NULL,
  `characterid` INT NOT NULL DEFAULT 0,
  `charactername` VARCHAR(64) NOT NULL DEFAULT '',
  `reason` VARCHAR(255) NOT NULL DEFAULT '',
  `addedby` VARCHAR(64) NOT NULL DEFAULT '',
  `date` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `factionid` (`factionid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- CHARACTERS: عمود الدولة /setcountry  (admin-system/Player/s_fix160_char.lua)
-- ---------------------------------------------------------------------------
ALTER TABLE `characters` ADD COLUMN `country` VARCHAR(8) DEFAULT NULL;
