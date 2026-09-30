-- --------------------------------------------------------
-- Extra tables for local development
-- --------------------------------------------------------
-- These tables are used by the scripts but were missing from the
-- original pdz.sql dump. Import them into the same database:
--   mysql -u root pdz < pdz_missing_tables.sql
-- --------------------------------------------------------

-- used by the 'apps' resource (job / faction applications)
CREATE TABLE IF NOT EXISTS `applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `applicant` int(11) NOT NULL DEFAULT 0,
  `question1` text DEFAULT NULL,
  `question2` text DEFAULT NULL,
  `question3` text DEFAULT NULL,
  `question4` text DEFAULT NULL,
  `answer1` text DEFAULT NULL,
  `answer2` text DEFAULT NULL,
  `answer3` text DEFAULT NULL,
  `answer4` text DEFAULT NULL,
  `dateposted` datetime DEFAULT current_timestamp(),
  `state` int(11) NOT NULL DEFAULT 0,
  `reviewer` int(11) NOT NULL DEFAULT 0,
  `note` text DEFAULT NULL,
  `datereviewed` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `applicant` (`applicant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by the 'apps' resource (questions shown in the application form)
CREATE TABLE IF NOT EXISTS `applications_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question` text DEFAULT NULL,
  `key` varchar(50) DEFAULT '1',
  `answer1` text DEFAULT NULL,
  `answer2` text DEFAULT NULL,
  `answer3` text DEFAULT NULL,
  `part` int(11) NOT NULL DEFAULT 1,
  `createdBy` int(11) NOT NULL DEFAULT 0,
  `createDate` datetime DEFAULT current_timestamp(),
  `updatedBy` int(11) NOT NULL DEFAULT 0,
  `updateDate` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `part` (`part`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by the 'dancer-system' resource
CREATE TABLE IF NOT EXISTS `dancers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `x` float NOT NULL DEFAULT 0,
  `y` float NOT NULL DEFAULT 0,
  `z` float NOT NULL DEFAULT 0,
  `rotation` float NOT NULL DEFAULT 0,
  `skin` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 1,
  `interior` int(11) NOT NULL DEFAULT 0,
  `dimension` int(11) NOT NULL DEFAULT 0,
  `offset` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by the 'logs', 'interior-manager' and 'vehicle-manager' resources
CREATE TABLE IF NOT EXISTS `logtable` (
  `time` datetime DEFAULT NULL,
  `action` text DEFAULT NULL,
  `source` text DEFAULT NULL,
  `affected` text DEFAULT NULL,
  `data` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by the 'logs' resource (same layout as logtable)
CREATE TABLE IF NOT EXISTS `owl_logs` (
  `time` datetime DEFAULT NULL,
  `action` text DEFAULT NULL,
  `source` text DEFAULT NULL,
  `affected` text DEFAULT NULL,
  `data` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Default application questions (required by the 'apps' resource)
-- --------------------------------------------------------
-- app_step1_s.lua picks 6 random questions of part 1 and app_step2_s.lua
-- picks 4 random questions of part 2, so the tables must not be empty.
-- `key` is the correct answer of a part 1 question ('1' / '2' / '3').
-- INSERT IGNORE + fixed ids keep this file re-runnable.
INSERT IGNORE INTO `applications_questions`
  (`id`, `question`, `key`, `answer1`, `answer2`, `answer3`, `part`, `createdBy`, `createDate`, `updatedBy`, `updateDate`) VALUES
  (1, 'You crash into another player by accident. What do you do?', '2', 'Ignore the crash and keep driving', 'Roleplay the accident, check the other player and exchange details', 'Disconnect from the server', 1, 1, NOW(), 1, NOW()),
  (2, 'A friend gives you $500,000 with no roleplay reason. What is that called?', '1', 'Powergaming', 'Metagaming', 'Random deathmatch', 1, 1, NOW(), 1, NOW()),
  (3, 'You use information read in OOC chat to act in character. This is:', '2', 'Good roleplay', 'Metagaming', 'Powergaming', 1, 1, NOW(), 1, NOW()),
  (4, 'Someone kills you because you insulted them without any roleplay build up. This is:', '1', 'Random Deathmatch (RDM)', 'Vehicle Deathmatch (VDM)', 'Fair roleplay', 1, 1, NOW(), 1, NOW()),
  (5, 'What does CK mean?', '1', 'Character Kill', 'Car Kill', 'Cash Kit', 1, 1, NOW(), 1, NOW()),
  (6, 'You are robbed at gunpoint and instantly run away and log off. Which rule are you breaking?', '1', 'Fail roleplay', 'Metagaming', 'None of the above', 1, 1, NOW(), 1, NOW()),
  (7, 'How should you behave when a police faction stops your vehicle?', '2', 'Ignore them and drive away', 'Roleplay the traffic stop realistically', 'Complain in OOC chat', 1, 1, NOW(), 1, NOW()),
  (8, 'What is the correct way to react to a bug that gives you free money?', '2', 'Keep the money and never tell anyone', 'Report it in game with /report or to an admin', 'Share the bug with your friends', 1, 1, NOW(), 1, NOW()),
  (9, 'Write a short background story for your character (at least 3 sentences).', '', '', '', '', 2, 1, NOW(), 1, NOW()),
  (10, 'Why do you want to join our community and what can you offer to it?', '', '', '', '', 2, 1, NOW(), 1, NOW()),
  (11, 'Give an example of a realistic roleplay scenario you have created or joined.', '', '', '', '', 2, 1, NOW(), 1, NOW()),
  (12, 'What will you do when your character gets permanently killed (CK)?', '', '', '', '', 2, 1, NOW(), 1, NOW()),
  (13, 'Explain the difference between IC (in character) and OOC (out of character).', '', '', '', '', 2, 1, NOW(), 1, NOW()),
  (14, 'How would you handle an OOC conflict with another player?', '', '', '', '', 2, 1, NOW(), 1, NOW());

-- --------------------------------------------------------
-- Fix #63 / #64 - vehicle tuning (مودات السيارات) + player vehicle parking
-- (سكنات اللاعبين).  Re-import this file once after updating:
--   mysql -u root pdz < pdz_missing_tables.sql
-- MariaDB (what XAMPP ships) understands ADD COLUMN IF NOT EXISTS, so this
-- file stays re-runnable.
-- --------------------------------------------------------

-- Per vehicle tuning state written by the `vehicle-tuning` resource:
--   {"engine":1,"neon":0,"neonOn":false,"backfire":false}
-- (the engine preset also rewrites `handling`, which already existed)
ALTER TABLE `vehicles_custom` ADD COLUMN IF NOT EXISTS `tuning` varchar(500) DEFAULT NULL;

-- Player vehicle storage used by the `vehicle-parking` resource.
-- A row means the vehicle is parked (hidden in the lot's private dimension).
CREATE TABLE IF NOT EXISTS `vehicle_parking` (
  `vehicleID` int(11) NOT NULL,
  `lot` int(11) NOT NULL DEFAULT 0,
  `slot` int(11) NOT NULL DEFAULT 1,
  `parked` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`vehicleID`),
  KEY `lot` (`lot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Fix #65 - player skins (سكنات اللاعبين), old client's "Fashion Dupont" shop
-- (`skin-system`).  The catalogue is the `clothing` table the clothing shop
-- and the item/texture pipeline already use (item 16 = "Clothes", value
-- "skin:clothing.id"); the old client's two extra fields are added here.
--   `private` = 1 -> only the owner sees it in the shop
--   `owner`      -> the character id of the player who added it
-- --------------------------------------------------------
ALTER TABLE `clothing`
  ADD COLUMN IF NOT EXISTS `private` tinyint(1) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `owner` int(10) UNSIGNED NOT NULL DEFAULT 0;

-- `clothing.id` has no AUTO_INCREMENT in this schema, so skins are inserted
-- with an explicit id (MAX(id) + 1) by the resource.  IMPORTANT: if the live
-- table still has no primary key, add one so two players cannot pick the same
-- id at the same time:
--   ALTER TABLE `clothing` ADD PRIMARY KEY (`id`), MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

-- The shop itself is a normal ped: create it from the in-game ped editor and
-- pick interact type "skins" (the editor already lists it), or use:
-- INSERT INTO `peds` (`name`, `type`, `x`, `y`, `z`, `rotation`, `interior`, `dimension`, `skin`, `gender`, `created_by`, `created_at`)
--   VALUES ('Fashion Dupont', 'skins', 0, 0, 0, 0, 0, 0, 158, 1, 1, NOW());

-- --------------------------------------------------------
-- Fix #66 - housing panels (لوحات البيوت), old client's Property Panel
-- (`interior-system`).  The panel shows what a house was bought for and when,
-- which this schema never stored:
--   `purchaseprice` -> what the current owner paid
--   `purchasedate`  -> when he bought it
--   `originalowner` -> the character that owned it before him (0/-1 = nobody)
-- Without these columns the panel falls back to the listing price.
-- --------------------------------------------------------
ALTER TABLE `interiors`
  ADD COLUMN IF NOT EXISTS `purchaseprice` int(11) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `purchasedate` datetime DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `originalowner` int(11) NOT NULL DEFAULT 0;

-- The Check Interior panel lists the last ENTER / EXIT / LOCK / UNLOCK action
-- of a house (written by interior-system/s_interior_ui.lua).  Those rows are
-- inserted without `log_id`, exactly like the interior admin tool does, so the
-- live table needs its auto increment:
--   ALTER TABLE `interior_logs` MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (`log_id`);

