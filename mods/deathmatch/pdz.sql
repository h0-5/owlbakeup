-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jun 09, 2024 at 10:17 PM
-- Server version: 10.5.18-MariaDB-0+deb11u1
-- PHP Version: 7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `stdb_user_8796_178`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `username` mediumtext DEFAULT NULL,
  `password` varchar(32) NOT NULL,
  `salt` varchar(30) NOT NULL DEFAULT '1234567890',
  `email` varchar(100) NOT NULL,
  `registerdate` mediumtext DEFAULT NULL,
  `lastlogin` datetime DEFAULT NULL,
  `ip` mediumtext DEFAULT NULL,
  `admin` float NOT NULL DEFAULT 0,
  `supporter` float NOT NULL DEFAULT 0,
  `vct` float NOT NULL DEFAULT 0,
  `mapper` float NOT NULL DEFAULT 0,
  `scripter` float NOT NULL DEFAULT 0,
  `warn_style` int(1) NOT NULL DEFAULT 1,
  `hiddenadmin` tinyint(3) UNSIGNED DEFAULT 0,
  `adminjail` tinyint(3) UNSIGNED DEFAULT 0,
  `adminjail_time` int(11) DEFAULT NULL,
  `adminjail_by` mediumtext DEFAULT NULL,
  `adminjail_reason` mediumtext DEFAULT NULL,
  `muted` tinyint(3) UNSIGNED DEFAULT 0,
  `globalooc` tinyint(3) UNSIGNED DEFAULT 1,
  `friendsmessage` varchar(255) NOT NULL DEFAULT 'Hi!',
  `adminjail_permanent` tinyint(3) UNSIGNED DEFAULT 0,
  `adminreports` int(11) DEFAULT 0,
  `warns` tinyint(3) UNSIGNED DEFAULT 0,
  `chatbubbles` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `adminnote` mediumtext DEFAULT NULL,
  `appstate` tinyint(1) DEFAULT 3,
  `appdatetime` datetime DEFAULT NULL,
  `appreason` longtext DEFAULT NULL,
  `help` int(1) NOT NULL DEFAULT 1,
  `adblocked` int(1) NOT NULL DEFAULT 0,
  `newsblocked` int(1) DEFAULT 0,
  `mtaserial` mediumtext DEFAULT NULL,
  `d_addiction` mediumtext DEFAULT NULL,
  `loginhash` varchar(64) DEFAULT NULL,
  `credits` int(11) NOT NULL DEFAULT 0,
  `transfers` int(11) DEFAULT 0,
  `monitored` varchar(255) NOT NULL DEFAULT '',
  `autopark` int(1) NOT NULL DEFAULT 1,
  `forceUpdate` smallint(1) NOT NULL DEFAULT 0,
  `anotes` mediumtext DEFAULT NULL,
  `oldAdminRank` int(11) DEFAULT 0,
  `suspensionTime` bigint(20) DEFAULT NULL,
  `car_license` int(1) NOT NULL DEFAULT 0,
  `adminreports_saved` int(3) DEFAULT 0,
  `cpa_earned` double DEFAULT 0,
  `electionsvoted` int(11) NOT NULL DEFAULT 0,
  `referrer` int(11) DEFAULT 0,
  `activated` tinyint(1) NOT NULL DEFAULT 1,
  `serial_whitelist_cap` int(2) NOT NULL DEFAULT 2,
  `tc_backend` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_settings`
--

CREATE TABLE `account_settings` (
  `id` int(11) DEFAULT NULL,
  `name` varchar(45) DEFAULT NULL,
  `value` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminhistory`
--

CREATE TABLE `adminhistory` (
  `id` int(10) NOT NULL,
  `user` int(10) NOT NULL,
  `user_char` int(11) NOT NULL DEFAULT 0,
  `admin` int(10) NOT NULL DEFAULT 0,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  `action` tinyint(3) NOT NULL DEFAULT 6,
  `duration` int(10) NOT NULL DEFAULT 0,
  `reason` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `advertisements`
--

CREATE TABLE `advertisements` (
  `id` int(11) NOT NULL,
  `phone` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `address` varchar(100) NOT NULL,
  `advertisement` text NOT NULL,
  `start` int(11) NOT NULL,
  `expiry` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `section` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `apb`
--

CREATE TABLE `apb` (
  `id` int(11) NOT NULL,
  `description` text NOT NULL,
  `doneby` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `atms`
--

CREATE TABLE `atms` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `rotation` decimal(10,6) DEFAULT 0.000000,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `deposit` tinyint(3) UNSIGNED DEFAULT 0,
  `limit` int(10) UNSIGNED DEFAULT 5000
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `atms`
--

INSERT INTO `atms` (`id`, `x`, `y`, `z`, `rotation`, `dimension`, `interior`, `deposit`, `limit`) VALUES
(2, 1347.832031, -1759.237305, 13.215581, 1.134369, 0, 0, 1, 0),
(3, 1268.310547, -1644.122070, 13.546875, 92.833160, 0, 0, 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `atm_cards`
--

CREATE TABLE `atm_cards` (
  `card_id` int(11) NOT NULL,
  `card_owner` int(11) DEFAULT NULL,
  `card_number` text DEFAULT NULL,
  `card_pin` varchar(4) NOT NULL DEFAULT '0000',
  `card_locked` tinyint(1) NOT NULL DEFAULT 0,
  `card_type` tinyint(1) NOT NULL DEFAULT 1,
  `limit_type` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bans`
--

CREATE TABLE `bans` (
  `id` int(11) NOT NULL,
  `serial` varchar(32) DEFAULT NULL,
  `ip` varchar(15) DEFAULT NULL,
  `account` int(11) DEFAULT NULL,
  `admin` int(11) DEFAULT NULL,
  `reason` text NOT NULL,
  `date` text DEFAULT NULL,
  `threadid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Handle serial bans instead of using MTA built-in / Maxime';

-- --------------------------------------------------------

--
-- Table structure for table `books`
--

CREATE TABLE `books` (
  `id` int(11) NOT NULL,
  `title` text DEFAULT NULL,
  `author` text DEFAULT NULL,
  `book` longtext DEFAULT NULL,
  `readOnly` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='This is used for the book system. // Chaos';

-- --------------------------------------------------------

--
-- Table structure for table `businesses`
--

CREATE TABLE `businesses` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `bank_card` varchar(100) NOT NULL DEFAULT '0000 0000 0000 0000',
  `created_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `business_accounts`
--

CREATE TABLE `business_accounts` (
  `id` int(11) NOT NULL,
  `recipient` varchar(250) NOT NULL,
  `recipient_type` int(11) NOT NULL,
  `amount` int(11) NOT NULL,
  `description` varchar(250) NOT NULL,
  `business` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `business_members`
--

CREATE TABLE `business_members` (
  `id` int(11) NOT NULL,
  `character` int(11) NOT NULL,
  `business` int(11) NOT NULL,
  `rank` varchar(200) NOT NULL,
  `wage` int(11) NOT NULL,
  `leader` int(11) NOT NULL,
  `phone` varchar(30) NOT NULL DEFAULT '0',
  `address` varchar(200) NOT NULL DEFAULT 'None',
  `date_hired` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `business_rentals`
--

CREATE TABLE `business_rentals` (
  `id` int(11) NOT NULL,
  `business` int(11) NOT NULL,
  `rental_id` int(11) NOT NULL,
  `rental_type` int(11) NOT NULL,
  `rental_price` int(11) NOT NULL,
  `rented_to` int(11) NOT NULL,
  `rented_time` int(11) NOT NULL,
  `rented_phone` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `characters`
--

CREATE TABLE `characters` (
  `id` int(11) NOT NULL,
  `charactername` text DEFAULT NULL,
  `account` int(11) DEFAULT 0,
  `x` float DEFAULT 1770.02,
  `y` float DEFAULT -1860.91,
  `z` float DEFAULT 13.5782,
  `rotation` float DEFAULT 359.388,
  `interior_id` int(5) DEFAULT 0,
  `dimension_id` int(5) DEFAULT 0,
  `health` float DEFAULT 100,
  `armor` float DEFAULT 0,
  `skin` int(3) DEFAULT 264,
  `money` bigint(20) DEFAULT 500,
  `gender` int(1) DEFAULT 0,
  `cuffed` int(11) DEFAULT 0,
  `duty` int(3) DEFAULT 0,
  `fightstyle` int(2) DEFAULT 4,
  `pdjail` int(1) DEFAULT 0,
  `pdjail_time` int(11) DEFAULT 0,
  `cked` int(1) DEFAULT 0,
  `lastarea` text DEFAULT NULL,
  `age` int(3) DEFAULT 18,
  `faction_id` int(11) DEFAULT -1,
  `faction_rank` int(2) DEFAULT 1,
  `faction_perks` text DEFAULT NULL,
  `faction_phone` int(3) UNSIGNED DEFAULT NULL,
  `skincolor` int(1) DEFAULT 0,
  `weight` int(3) DEFAULT 180,
  `height` int(3) DEFAULT 180,
  `description` text DEFAULT NULL,
  `deaths` int(11) DEFAULT 0,
  `faction_leader` int(1) DEFAULT 0,
  `fingerprint` text DEFAULT NULL,
  `casualskin` int(3) DEFAULT 0,
  `bankmoney` bigint(20) DEFAULT 1000,
  `car_license` int(1) DEFAULT 0,
  `bike_license` int(1) DEFAULT 0,
  `pilot_license` int(1) DEFAULT 0,
  `fish_license` int(1) DEFAULT 0,
  `boat_license` int(1) DEFAULT 0,
  `gun_license` int(1) DEFAULT 0,
  `gun2_license` int(1) DEFAULT 0,
  `tag` int(3) DEFAULT 1,
  `hoursplayed` int(11) DEFAULT 0,
  `pdjail_station` int(1) DEFAULT 0,
  `timeinserver` int(2) DEFAULT 0,
  `restrainedobj` int(11) DEFAULT 0,
  `restrainedby` int(11) DEFAULT 0,
  `dutyskin` int(3) DEFAULT -1,
  `fish` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `blindfold` tinyint(4) NOT NULL DEFAULT 0,
  `lang1` tinyint(2) DEFAULT 1,
  `lang1skill` tinyint(3) DEFAULT 100,
  `lang2` tinyint(2) DEFAULT 0,
  `lang2skill` tinyint(3) DEFAULT 0,
  `lang3` tinyint(2) DEFAULT 0,
  `lang3skill` tinyint(3) DEFAULT 0,
  `currlang` tinyint(1) DEFAULT 1,
  `lastlogin` datetime DEFAULT NULL,
  `creationdate` timestamp NOT NULL DEFAULT current_timestamp(),
  `election_candidate` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `election_canvote` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `election_votedfor` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `marriedto` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `photos` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `maxvehicles` int(4) UNSIGNED NOT NULL DEFAULT 5,
  `ck_info` text DEFAULT NULL,
  `alcohollevel` float NOT NULL DEFAULT 0,
  `active` tinyint(1) UNSIGNED NOT NULL DEFAULT 1,
  `recovery` int(1) DEFAULT 0,
  `recoverytime` bigint(20) DEFAULT NULL,
  `walkingstyle` int(3) NOT NULL DEFAULT 0,
  `job` int(3) NOT NULL DEFAULT 0,
  `day` tinyint(2) NOT NULL DEFAULT 1,
  `month` tinyint(2) NOT NULL DEFAULT 1,
  `maxinteriors` int(4) NOT NULL DEFAULT 10,
  `clothingid` int(10) UNSIGNED DEFAULT NULL,
  `death_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `character_settings`
--

CREATE TABLE `character_settings` (
  `id` int(11) DEFAULT NULL,
  `name` varchar(45) DEFAULT NULL,
  `value` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clothing`
--

CREATE TABLE `clothing` (
  `id` int(11) UNSIGNED NOT NULL,
  `skin` int(11) UNSIGNED NOT NULL,
  `url` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `price` int(11) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `clothing`
--

INSERT INTO `clothing` (`id`, `skin`, `url`, `description`, `price`) VALUES
(1, 158, 'https://media.discordapp.net/attachments/817035130781958164/823495923602030592/CWMOFR2.png', 'ÙÙ„Ø§Ø­ Ø§Ø¨ÙŠØ¶ ÙˆØ§Ø³ÙˆØ¯', 1),
(2, 306, 'https://cdn.discordapp.com/attachments/1109888962924912690/1125603946766016522/zero_custom.png', 'Ø³ÙƒÙ† Ø¹ØµØ§Ø¨Ø§Øª', 1),
(3, 186, 'https://media.discordapp.net/attachments/817035130781958164/817796424330379274/somyri.png?width=338&height=676', 'Ø¬ÙˆÙƒØ±', 1),
(4, 186, 'https://e.top4top.io/p_1910fe4wp1.png', 'Ø¨Ø¯Ù„Ø© Ø³ÙˆØ¯Ø§', 1),
(7, 186, 'https://media.discordapp.net/attachments/763867032180883518/824511777294254099/p_1910hvpmk1.png?width=338&height=676', 'Ø±ØµØ§ØµÙŠ', 1),
(8, 306, 'https://h.top4top.io/p_27409yafe1.png', 'سكن بريدزوب ازرق', 2500000),
(9, 306, 'https://cdn.discordapp.com/attachments/1109888962924912690/1125603946766016522/zero_custom.png', 'predzop Costum', 2500000);

-- --------------------------------------------------------

--
-- Table structure for table `commands`
--

CREATE TABLE `commands` (
  `id` int(11) NOT NULL,
  `command` text DEFAULT NULL,
  `hotkey` text DEFAULT NULL,
  `explanation` text DEFAULT NULL,
  `permission` int(3) NOT NULL DEFAULT 0,
  `category` int(2) NOT NULL DEFAULT 1,
  `last_update` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves all info about all kinds of supported commands and con';

--
-- Dumping data for table `commands`
--

INSERT INTO `commands` (`id`, `command`, `hotkey`, `explanation`, `permission`, `category`, `last_update`) VALUES
(2, 'getkey', 'N/A', 'Spawns yourself a key of interior or vehicle that you\'re currently in.', 1, 3, '2014-06-19 13:42:52'),
(3, 'cr', 'N/A', 'without specified ID will close all your own accepted reports.', 21, 7, '2014-11-23 12:51:19'),
(4, 'createemitter [Emitter Type]', 'N/A', 'Spawns Synced Fire/Water Emitters', 1, 5, '2014-06-15 00:29:28'),
(5, 'nearbyemitters', 'N/A', 'Shows all nearby Fire/Water emitters.', 1, 5, '2014-06-26 08:42:01'),
(6, 'delemitters', 'N/A', 'Deletes all nearby Fire/Water emitters.', 1, 7, '2014-06-15 16:14:33'),
(7, 'delemitter [Emitter ID]', 'N/A', 'Deletes a Fire/Water emitters.', 1, 7, '2014-06-15 16:14:19'),
(8, 'delnearbyshops', 'N/A', 'Deletes nearby shops.', 1, 7, '2014-06-15 16:21:37'),
(9, 'reloadshop', 'N/A', 'Reloads a bugged shop.', 1, 4, '2014-06-26 09:02:29'),
(10, 'restoreshop', 'N/A', 'Restores a deleted NPC from SQL.', 1, 4, '2014-06-26 09:02:24'),
(11, 'delshop', 'N/A', 'Deletes a NPC from game, still exist in SQL.', 1, 4, '2014-06-15 16:23:02'),
(12, 'showallcustomshops', 'N/A', 'Shows all custom shops parameters and settings.', 1, 6, '2014-06-17 18:32:04'),
(13, 'fixnearbye', 'N/A', 'Fixes near by elevators. Players can use too.', 0, 7, '2014-06-26 08:58:47'),
(15, 'findvehid', 'N/A', 'Gets car\'s Model ID from Name.', 0, 3, '2014-06-26 08:57:13'),
(17, 'respawnint', 'N/A', 'Respawns all vehicle within current interior/dimension.', 0, 3, '2014-06-26 08:48:41'),
(18, 'restock', 'N/A', 'Restocks businesses, you must be inside an interior to restock. Or use SYNTAX: /restock [Interior ID] [Amount 1~300]', 1, 4, '2014-06-26 08:49:21'),
(19, 'ojail [Exact Username] [Minutes(>=1) 999=Perm] [Reason]', 'N/A', 'Jails an offline player.', 1, 7, '2014-06-26 08:43:48'),
(20, 'sojail', 'N/A', 'Silently jail an offline player, only informs other administrators', 1, 7, '2014-06-17 18:25:36'),
(21, 'oban [Exact Username] [Time in Hours, 0 = Infinite] [Reason]', 'N/A', 'Bans an offline player.', 1, 7, '2014-06-26 08:43:38'),
(22, 'delefromint [Interior ID, 0 = world map]', 'N/A', 'Deletes all elevators that connect to a specified interior.', 3, 7, '2014-06-15 16:12:33'),
(23, 'delnearbye', 'N/A', 'Deletes all nearby elevators.', 11, 7, '2015-01-21 21:08:27'),
(24, 'srd', 'N/A', 'stops all radios in the district you\'re in.', 1, 3, '2014-06-17 18:22:41'),
(25, 'adde', 'N/A', 'creates an elevator', 1, 7, '2014-06-19 13:30:30'),
(26, 'adde2', 'N/A', 'Create an elevator between you and another player', 1, 7, '2014-06-19 13:30:39'),
(27, 'dele', 'N/A', 'deletes an elevator', 0, 7, '2015-01-21 21:09:08'),
(28, 'nearbye', 'N/A', 'shows nearby elevators', 1, 4, '2014-06-26 08:41:51'),
(29, 'togglee', 'N/A', 'enables/disables an elevator', 1, 7, '2014-06-17 18:14:38'),
(30, 'togautocheck', 'N/A', 'Toogles auto opening player /check on /ar reports.', 11, 1, '2014-06-17 18:15:56'),
(31, 'changewarnstyle', 'N/A', 'changes warning message displaying style.', 1, 7, '2014-07-17 23:42:56'),
(32, 'ur', 'N/A', 'Просмотреть неотвеченные репорты', 11, 1, '2016-10-23 01:52:13'),
(34, 'adminlounge', 'N/A', 'Chill out in the lounge', 1, 7, '2014-06-15 00:08:12'),
(35, 'check', 'N/A', 'retrieves specified player\'s information', 11, 7, '2014-06-15 16:07:21'),
(36, 'stats', 'N/A', 'shows players vehicle id\'s, languages etc', 1, 7, '2014-06-15 00:21:44'),
(37, 'history', 'N/A', 'Checks your own admin history', 0, 7, '2014-06-26 08:59:30'),
(38, 'auncuff', 'N/A', 'Развязать игрока', 1, 5, '2016-10-23 01:58:28'),
(39, 'revive', 'N/A', 'revives a player that has been PKd.', 1, 7, '2014-06-26 08:49:53'),
(40, 'pmute', 'N/A', 'Мут', 21, 1, '2016-10-23 01:52:44'),
(41, 'togooc', 'N/A', 'Toggles global OOC chat.', 1, 1, '2014-06-17 18:11:56'),
(42, 'stogooc', 'N/A', 'Silently toggles global OOC and only informs other administrators', 1, 1, '2014-06-17 18:24:31'),
(43, 'disarm', 'N/A', 'takes all weapon from the player', 1, 5, '2014-06-19 13:35:32'),
(44, 'freconnect', 'N/A', 'reconnects the player', 1, 7, '2014-06-15 13:06:40'),
(45, 'giveitem', 'N/A', 'gives the player the specified item, see /items for ids', 1, 5, '2014-06-21 11:41:56'),
(46, 'sethp', 'N/A', 'sets the health of the player', 1, 7, '2014-06-26 08:52:51'),
(47, 'setarmor', 'N/A', 'sets the armor of the player', 1, 5, '2014-11-02 15:16:47'),
(48, 'setskin', 'N/A', 'sets the skin of a player', 1, 7, '2014-06-26 08:54:47'),
(49, 'changename', 'N/A', 'Renames a player if they have less than (or) 5 hours player on it.', 11, 7, '2014-07-17 23:43:13'),
(50, 'slap', 'N/A', 'drops the player from a height of 15', 1, 7, '2014-06-17 18:26:58'),
(51, 'recon', 'N/A', 'spectate a player', 1, 7, '2014-06-26 08:44:58'),
(52, 'fuckrecon', 'N/A', 'forces recon to stop', 1, 7, '2014-06-19 13:40:43'),
(53, 'pkick', 'N/A', 'kicks the player from the server', 1, 7, '2014-06-26 08:44:24'),
(54, 'pban', 'N/A', 'bans the player for the given time, specify 0 as hours for permanent ban', 1, 7, '2014-06-26 08:44:16'),
(55, 'unban', 'N/A', 'unbans the player with the given character name', 1, 7, '2014-06-17 18:05:55'),
(58, 'gotoplace', 'N/A', 'Teleports you to a preset places', 11, 7, '2014-06-26 08:36:58'),
(59, 'jail', 'N/A', 'jails the player, if minutes >= 999 it\'s permanent', 1, 7, '2014-06-26 08:39:13'),
(60, 'unjail', 'N/A', 'unjails the player', 1, 7, '2014-06-15 00:04:53'),
(61, 'jailed', 'N/A', 'shows a list of players that are in adminjail, including time left and reason', 1, 7, '2014-06-26 08:39:21'),
(62, 'goto', 'N/A', 'Teleports you to another player [id/name]', 11, 7, '2014-06-26 08:35:42'),
(64, 'sendto', 'N/A', 'teleports a player to another one', 11, 7, '2014-06-26 08:50:35'),
(69, 'adminduty', 'N/A', 'Админдюти', 1, 1, '2016-10-23 01:46:54'),
(70, 'setmotd', 'N/A', 'Изменить сообщение при входе', 21, 1, '2016-10-23 01:52:24'),
(72, 'amotd', 'N/A', 'ААмотд', 1, 1, '2016-10-23 01:47:13'),
(73, 'warn', 'N/A', 'issues a warning, player is banned when having 3 warnings', 1, 7, '2014-06-15 12:44:51'),
(74, 'showinv', 'N/A', 'views the inventory of the player', 1, 5, '2014-06-17 18:29:22'),
(75, 'togmytag', 'N/A', 'toggles your nametag on and off', 41, 7, '2014-06-17 18:12:38'),
(76, 'dropme', 'N/A', 'drops you off at the current freecam position', 1, 7, '2014-07-07 15:38:13'),
(77, 'disappear', 'N/A', 'disappear', 1, 7, '2014-06-19 13:35:23'),
(79, 'findalts', 'N/A', 'shows all characters the player has', 1, 7, '2014-06-19 13:36:55'),
(80, 'findip', 'N/A', 'shows all accounts the player has', 1, 7, '2014-06-19 13:37:03'),
(81, 'findserial', 'N/A', 'shows all accounts the player has', 1, 7, '2014-06-19 13:37:13'),
(82, 'setlanguage or /setlang', 'N/A', 'adjusts the skill of a player\'s language, or learns it to him', 1, 1, '2014-06-26 08:54:05'),
(83, 'dellanguage', 'N/A', 'deletes a language from the player\'s knowledge', 1, 7, '2014-06-15 16:16:50'),
(84, 'aunblindfold', 'N/A', 'unblindfold the player', 1, 5, '2014-06-15 16:05:37'),
(85, 'agivelicense', 'N/A', 'Дать лицензии игроку', 1, 5, '2016-10-23 01:58:10'),
(86, 'resetcontract', 'N/A', 'resets the job time limit for a person.', 1, 6, '2014-06-26 08:47:40'),
(88, 'freezead', 'N/A', 'Заморозить рекламу', 1, 1, '2016-10-23 01:50:25'),
(89, 'unfreeze', 'N/A', 'Unfreeze a frozen advertisement', 11, 7, '2014-06-16 21:55:54'),
(90, 'deletead', 'N/A', 'Удалить рекламу', 1, 1, '2016-10-23 01:47:59'),
(92, 'itemprotect', 'P', 'Sets the value you set the items to. -100 (locked) or faction id', 11, 5, '2014-06-26 08:58:02'),
(94, 'delii', 'N/A', 'Deletes an information marker', 2, 7, '2014-06-19 13:33:41'),
(95, 'nearbyii', 'N/A', 'Shows all nearby information markers', 2, 7, '2014-06-26 08:42:18'),
(96, 'makeshop ', 'N/A', 'Creates a NPC.', 1, 4, '2014-06-26 08:40:38'),
(97, 'nearbyshops ', 'N/A', 'Shows all near by NPCs.', 1, 4, '2014-06-26 08:43:06'),
(98, 'gunlist or /gunchart', 'N/A', 'Showing a details weapon\'s properties table with IDs.', 2, 5, '2014-06-26 08:37:14'),
(99, 'setage ', 'N/A', 'Change player\'s age', 1, 7, '2014-06-26 08:50:55'),
(100, 'setrace ', 'N/A', 'Change player\'s race', 1, 7, '2014-06-26 08:54:42'),
(101, 'setheight  ', 'N/A', 'Change player\'s height', 1, 7, '2014-06-26 08:52:44'),
(102, 'setgender  ', 'N/A', 'Change player\'s gender', 1, 7, '2014-06-26 08:52:37'),
(109, 'skick', 'N/A', 'Silently kick a player, only informs lead administrators', 1, 7, '2014-06-17 18:27:53'),
(110, 'sjail  ', 'N/A', 'Silently jail a player, only informs other administrators', 1, 7, '2014-06-17 18:28:31'),
(113, 'setjob  ', 'N/A', 'Sets player job.', 1, 6, '2014-06-26 08:53:54'),
(114, 'deljob  ', 'N/A', 'Deletes player job.', 1, 6, '2014-06-15 16:21:23'),
(116, 'issuepc  ', 'N/A', 'Issues player a pilot license', 1, 3, '2014-06-26 08:38:31'),
(117, 'items or /itemlist ', 'N/A', 'Opens Item Creator.', 1, 5, '2014-06-26 08:39:02'),
(118, 'settrainrailed ', 'N/A', 'Sets a train off/on the rail.', 2, 3, '2014-06-26 08:55:27'),
(119, 'settraindirection', 'N/A', 'Sets a train direction to (counter)clockwise.', 2, 3, '2014-06-26 08:55:19'),
(121, 'unflip', 'N/A', 'unflips the vehicle you\'re in.', 11, 3, '2014-06-17 18:03:24'),
(122, 'unlockcivcars', 'N/A', 'unlocks all civilian vehicles', 1, 3, '2014-06-15 12:49:23'),
(123, 'oldcar', 'N/A', 'retrieves the id of the last car you drove', 0, 3, '2014-06-26 08:43:52'),
(124, 'thiscar', 'N/A', 'retrieves the id of the car you\'re in', 0, 3, '2014-06-17 18:16:20'),
(125, 'gotocar', 'N/A', 'teleports you to the car with that id', 11, 3, '2014-06-26 08:35:48'),
(126, 'getcar', 'N/A', 'teleports the car to you', 1, 3, '2014-06-19 13:41:45'),
(127, 'nearbyvehicles', 'N/A', 'shows all vehicles within a radius of 20', 1, 3, '2014-06-26 08:43:24'),
(128, 'respawnveh', 'N/A', 'respawns the vehicle with that id', 11, 3, '2014-10-01 19:15:26'),
(129, 'respawnall', 'N/A', 'respawns all vehicles', 1, 3, '2014-06-26 08:48:17'),
(130, 'respawndistrict', 'N/A', 'respawns all vehicles in the district you are in', 1, 3, '2014-06-26 08:48:31'),
(131, 'respawnciv', 'N/A', 'respawns all civilian (job) vehicles', 1, 3, '2014-06-26 08:48:22'),
(132, 'findveh', 'N/A', 'retrieves the model for that vehicle name', 0, 3, '2014-06-19 13:37:30'),
(134, 'fixvehs', 'N/A', 'repairs all vehicles', 1, 3, '2014-06-19 13:38:16'),
(135, 'fixvehis', 'N/A', 'fixes the vehicles look, engine may remain broken', 1, 3, '2014-06-19 13:38:10'),
(136, 'blowveh', 'N/A', 'blows up a players car', 1, 3, '2014-06-15 00:11:12'),
(137, 'setcarhp', 'N/A', 'sets the health of a car, full health is 1000.', 1, 3, '2014-06-26 08:51:32'),
(139, 'fuelvehs', 'N/A', 'refills all vehicles', 1, 3, '2014-06-19 13:41:02'),
(140, 'setcolor', 'N/A', 'changes the players vehicle colors', 1, 3, '2014-06-26 08:51:36'),
(141, 'getcolor', 'N/A', 'returns the colors of a vehicle', 1, 3, '2014-06-19 13:41:56'),
(142, 'entercar', 'N/A', 'puts the player into the given vehicle at either the specified seat, or if none then the first free seat', 11, 3, '2014-10-03 03:04:06'),
(143, 'getpos', 'N/A', 'outputs your current position, interior and dimension', 1, 7, '2014-06-19 13:42:58'),
(144, 'x', 'N/A', 'increases your x-coordinate by the given value', 1, 7, '2014-06-15 12:44:04'),
(145, 'y', 'N/A', 'increases your y-coordinate by the given value', 1, 7, '2014-06-15 12:43:53'),
(146, 'z', 'N/A', 'increases your z-coordinate by the given value', 1, 7, '2014-06-15 12:43:22'),
(147, 'set*', 'N/A', 'sets your coordinates - available combinations: x, y, z, xyz, xy, xz, yz', 1, 7, '2014-06-26 08:50:46'),
(148, 'reloadint', 'N/A', 'reloads an interior from the database', 1, 4, '2014-06-26 08:45:09'),
(149, 'nearbyints', 'N/A', 'shows nearby interiors', 1, 4, '2014-06-26 08:42:26'),
(150, 'setintname', 'N/A', 'changes an interior name', 1, 4, '2014-06-26 08:53:44'),
(151, 'setfee', 'N/A', 'sets an fee on entering the interior', 1, 4, '2014-06-26 08:52:28'),
(152, 'getintid', 'N/A', 'Gets the interior id', 1, 4, '2014-06-19 13:42:25'),
(153, 'setdim or /setdimension', 'N/A', 'Sets the players dimension id', 1, 7, '2014-06-26 08:51:51'),
(154, 'setint or /setinterior', 'N/A', 'Sets the players interior id', 1, 4, '2014-06-26 08:53:05'),
(158, 'showfactions', 'N/A', 'shows a list with factions', 11, 2, '2014-06-17 18:29:41'),
(159, 'respawnfaction', 'N/A', 'respawns faction vehicles', 1, 2, '2014-06-19 13:43:35'),
(160, 'resetbackup', 'N/A', 'Resets PD\'s backup unit', 1, 2, '2014-06-26 08:47:20'),
(161, 'resetassist', 'N/A', 'Resets ES\'s assist system', 1, 6, '2014-06-26 08:47:12'),
(162, 'resettowbackup', 'N/A', 'Resets towing backup system', 1, 2, '2014-06-26 08:48:03'),
(163, 'aremovespikes', 'N/A', 'Removes all the PD spikes', 1, 2, '2014-06-15 16:08:21'),
(164, 'clearnearbytag', 'N/A', 'Clears nearby tags', 1, 5, '2014-06-15 00:26:49'),
(165, 'nearbytags', 'N/A', 'Shows nearby tag and its creators', 1, 6, '2014-06-26 08:43:15'),
(166, 'changelock', 'N/A', 'changes the lock from the vehicle/interior', 1, 3, '2014-06-15 00:23:00'),
(167, 'restartgatekeepers', 'N/A', 'restarts the gatekeepers resource', 1, 7, '2014-06-26 08:49:08'),
(168, 'bury', 'N/A', 'buries the player; removes the ck corpse', 1, 7, '2014-06-15 00:22:53'),
(173, 'resetpos', 'N/A', 'Reset player\'s position, works when player\'s offline.', 1, 7, '2014-06-26 08:47:50'),
(174, 'delsupercar', 'N/A', 'deletes the supercar you\'re in, given that it meets the criteria for deletion.', 1, 3, '2014-06-19 13:34:26'),
(175, 'setbiznote', 'N/A', 'Добавить описание бизнеса при входе', 0, 4, '2016-10-23 01:57:43'),
(177, 'ints or /interiors', 'N/A', 'Opens Interior Manager.', 2, 4, '2014-07-03 01:32:49'),
(178, 'delint', 'N/A', 'Deletes the interior from game and disables it from loading in next server/resource restarts.', 2, 4, '2014-06-19 13:33:51'),
(179, 'delthisint or /delthisinterior', 'N/A', 'Deletes the interior you\'re currently in it from game and disables it from loading in next server/resource restarts.', 2, 4, '2014-06-19 13:34:48'),
(180, 'restoreint ', 'N/A', 'Restores a deleted interior included safe, items and NPCs inside it.', 2, 4, '2014-06-26 08:49:28'),
(181, 'gotohouse', 'N/A', 'teleports to the house', 1, 4, '2014-06-26 08:36:12'),
(182, 'gotoint', 'N/A', 'teleports to the interior', 1, 4, '2014-06-26 08:36:19'),
(183, 'gotointi', 'N/A', 'teleports inside of an interior', 1, 4, '2014-06-26 08:36:25'),
(184, 'veh', 'N/A', 'spawns a temporary vehicle', 1, 3, '2014-06-15 12:47:50'),
(185, 'resetshopwage', 'N/A', 'Resets all shops wages to $0.', 1, 4, '2014-06-26 08:47:56'),
(186, 'forceupdateshopwage', 'N/A', 'Forces update all shop wages.', 2, 4, '2014-06-19 13:39:37'),
(187, 'delnearbyvehs', 'N/A', 'Deletes all the nearby (temporary) vehicles.', 2, 3, '2014-06-15 16:21:58'),
(188, 'delveh', 'N/A', 'Deletes the (temporary) vehicle with that id', 1, 3, '2014-06-19 13:35:15'),
(189, 'delthisveh', 'N/A', 'Deletes the (temporary) vehicle', 2, 3, '2014-06-19 13:34:53'),
(190, 'restoreveh', 'N/A', 'Restores a deleted vehicle.', 1, 3, '2014-09-07 18:25:46'),
(191, 'makeveh', 'N/A', 'creates a new permanent vehicle', 2, 3, '2014-06-26 08:40:51'),
(192, 'makecivveh', 'N/A', 'creates a new permanent civilian vehicle', 1, 3, '2014-06-26 08:40:11'),
(193, 'addupgrade', 'N/A', 'upgrades a players car', 1, 3, '2014-06-15 00:08:48'),
(194, 'setpaintjob', 'N/A', 'set another paintjob on a vehicle', 1, 3, '2014-06-26 08:54:30'),
(195, 'setvariant', 'N/A', 'set another variant on a vehicle', 1, 3, '2014-06-21 11:46:34'),
(196, 'delupgrade', 'N/A', 'removes a specific upgrade from the player\'s car', 1, 3, '2014-06-19 13:35:08'),
(197, 'resetupgrades', 'N/A', 'removes all upgrades on the player\'s car', 1, 3, '2014-06-26 08:48:09'),
(198, 'aunimpound', 'N/A', 'unimpounds the vehicle from the RT lot', 1, 3, '2014-12-31 17:58:12'),
(199, 'setvehtint', 'N/A', 'adds or removes vehicle tint', 1, 3, '2014-06-17 18:41:42'),
(200, 'atakelicense', 'N/A', 'revokes the player a license (use full name for offline players', 1, 5, '2014-06-15 16:08:03'),
(201, 'setvehplate', 'N/A', 'changes the plate of a vehicle', 1, 3, '2014-06-17 18:42:25'),
(202, 'setvehfaction', 'N/A', 'add a vehicle to faction, use -1 to remove (sets to you)', 1, 3, '2014-06-21 11:46:13'),
(203, 'gates', 'N/A', 'Opens Gate Manager', 2, 7, '2014-12-29 16:35:15'),
(204, 'gotogate', 'N/A', 'Teleports to a gate.', 2, 4, '2014-06-26 08:36:03'),
(205, 'delgate', 'N/A', 'Deletes to a gate.', 2, 7, '2014-06-19 13:33:32'),
(206, 'loginto [Exact Character Name] ', 'N/A', 'Logs into an other account\'s character.', 3, 7, '2014-06-15 00:05:11'),
(207, 'forcepayday [Player ID/Name] ', 'N/A', 'Forces a player to get payday.', 2, 7, '2014-06-19 13:39:06'),
(208, 'forcepaydayall ', 'N/A', 'Forces all players to get paydays.', 2, 7, '2014-06-19 13:39:17'),
(209, 'rwarn [warn #]', 'N/A', 'sends a predefined admin warnings or custom admin warning.', 1, 1, '2014-06-26 08:50:03'),
(210, 'soban', 'N/A', 'Silently ban an offline player, only notifies other administrators', 1, 7, '2014-06-17 18:26:19'),
(211, 'givesuperman', 'N/A', 'Allows a player the temp. ability to use superman. Use command again to remove, reconnects player.', 1, 7, '2014-09-23 17:30:27'),
(212, 'sw', 'N/A', 'changes the weather', 1, 1, '2014-12-08 23:46:17'),
(213, 'addatm', 'N/A', 'adds an ATM at this spot', 1, 7, '2014-12-08 23:43:21'),
(214, 'delatm [id]', 'N/A', 'deletes an ATM with the id', 1, 7, '2014-12-08 23:43:43'),
(215, 'nearbyatms', 'N/A', 'shows the nearby ATMs', 2, 5, '2014-06-26 08:41:42'),
(216, 'bigears', 'N/A', 'hook yourself between someone\'s chats', 2, 1, '2014-06-15 00:10:49'),
(217, 'bigearsf', 'N/A', 'hook yourself between faction chats', 2, 1, '2014-06-15 00:10:58'),
(219, 'gunmaker', 'N/A', 'Opens Weapon Creator', 2, 5, '2014-06-26 08:37:22'),
(220, 'makepaynspray', 'N/A', 'creates an pay n spray', 2, 3, '2014-06-26 08:40:28'),
(221, 'nearbypaynsprays', 'N/A', 'shows nearby pay n sprays', 1, 3, '2014-06-26 08:42:33'),
(222, 'delpaynspray', 'N/A', 'deletes an pay n spray', 2, 3, '2014-06-15 16:22:24'),
(223, 'addphone', 'N/A', 'Добавить телефон', 1, 5, '2016-10-23 01:57:56'),
(224, 'nearbyphones', 'N/A', 'shows nearby public phone', 1, 7, '2014-06-26 08:42:41'),
(225, 'delphone', 'N/A', 'deletes a public phone', 1, 7, '2014-06-15 16:22:32'),
(226, 'enableallelevators', 'N/A', 'enables all elevators', 1, 7, '2014-06-19 13:36:24'),
(227, 'addint', 'N/A', 'adds an interior', 2, 4, '2014-06-15 00:13:38'),
(228, 'sellproperty', 'N/A', 'Продать дом/бизнес игроку', 0, 4, '2016-10-23 01:57:00'),
(230, 'getintid', 'N/A', 'shows the current interior', 1, 4, '2014-06-15 18:04:32'),
(231, 'setintid', 'N/A', 'changes the interior', 2, 4, '2014-06-26 08:53:27'),
(232, 'getintprice', 'N/A', 'shows the interiors price', 1, 4, '2014-06-19 13:42:34'),
(233, 'setintprice', 'N/A', 'changes the interiors price', 2, 4, '2014-06-21 11:46:57'),
(234, 'getinttype', 'N/A', 'shows the interiors type', 1, 4, '2014-06-19 13:42:40'),
(235, 'setinttype', 'N/A', 'changes the interiors type', 2, 4, '2014-06-21 11:47:19'),
(236, 'togint', 'N/A', 'sets the interior enabled or disabled', 2, 4, '2014-06-17 18:12:54'),
(237, 'enableallinteriors', 'N/A', 'enables all the interiors', 2, 4, '2014-06-19 13:36:31'),
(238, 'setintexit', 'N/A', 'changes an interior exit marker', 2, 4, '2014-06-26 08:53:20'),
(239, 'setintentrance', 'N/A', 'changes an interior entrance marker', 2, 4, '2014-06-26 08:53:14'),
(240, 'fsell', 'N/A', 'force-sells an interior', 2, 4, '2014-06-19 13:40:34'),
(241, 'setfactionleader', 'N/A', 'puts a player into a faction and makes the player leader', 2, 2, '2016-10-24 17:39:09'),
(242, 'setfactionrank', 'N/A', 'sets a player to a specific faction rank', 2, 2, '2014-06-26 22:43:02'),
(243, 'makefaction', 'N/A', 'creates a faction', 2, 2, '2014-06-19 13:44:28'),
(244, 'renamefaction', 'N/A', 'renames a faction', 2, 2, '2014-06-19 13:45:26'),
(245, 'sf', 'N/A', 'puts an player into a faction', 1, 2, '2016-10-18 23:36:40'),
(246, 'delfaction', 'N/A', 'deletes a faction', 2, 2, '2014-06-19 13:33:04'),
(247, 'makefuel [skin, default = 50, -1 = random] [Firstname Lastname, -1 = random]', 'N/A', 'creates a new fuel NPC.', 1, 7, '2014-09-23 17:31:36'),
(248, 'nearbyfuelpoints', 'N/A', 'shows nearby fuelpoints', 2, 3, '2014-06-26 08:42:09'),
(249, 'delfuelpoint', 'N/A', 'deletes a fuelpoint', 2, 3, '2014-06-26 08:59:39'),
(250, 'ck', 'N/A', 'permanently kills the character; spawns a corpse at the location the player is at', 2, 7, '2014-06-19 13:32:27'),
(251, 'unck', 'N/A', 'reverts a character kill', 1, 7, '2014-06-17 18:03:45'),
(254, 'setmoney', 'N/A', 'sets the players money to that value', 2, 5, '2014-06-26 08:54:12'),
(255, 'givemoney', 'N/A', 'gives the player money in addition to his current cash', 2, 5, '2014-07-15 08:36:27'),
(256, 'resetcharacter', 'N/A', 'fully resets the character', 2, 7, '2014-06-26 08:47:33'),
(257, 'setvehlimit', 'N/A', 'Set the player\'s max vehicle slots limit.', 3, 3, '2014-06-17 18:42:00'),
(258, 'adminstats', 'N/A', 'shows admin stats', 3, 7, '2014-06-15 00:07:54'),
(259, 'removeshop', 'N/A', 'Deletes a NPC from SQL.', 3, 4, '2014-06-26 08:46:06'),
(260, 'forcesellinactiveints', 'N/A', 'Force-sells All inactive interiors.', 2, 4, '2014-06-19 13:39:26'),
(261, 'removeinactiveints', 'N/A', 'Removes All inactive interiors completedly and permanently from SQL.', 3, 4, '2014-06-26 08:45:51'),
(262, 'removedeletedints', 'N/A', 'Removes All deleted interiors completedly and permanently from SQL.', 3, 4, '2014-06-26 08:45:36'),
(263, 'removeforsaleints', 'N/A', 'Removes All for-sale interiors completedly and permanently from SQL.', 3, 4, '2014-06-26 08:45:42'),
(264, 'delallitems [Item ID] [Item Value]', 'N/A', 'Deletes all the item instances from everywhere in game.', 3, 5, '2014-06-15 00:32:11'),
(265, 'removeint [ID]', 'N/A', 'Deletes the interior from game and erases all the data from database completely and permanently include NPCs, items, safe and items inside the safe. If the deleted interior is a custom interior, the custom map will be gone forever.', 3, 4, '2014-06-26 08:45:58'),
(266, 'removeveh [ID]', 'N/A', 'Removes the vehicle from game and erases all the data from database completely and permanently include items inside. ', 3, 3, '2014-06-26 08:46:15'),
(269, 'hideadmin', 'N/A', 'toggles hidden/visible the admin status', 3, 7, '2014-06-26 08:37:35'),
(270, 'ho', 'N/A', 'надо проверть', 3, 1, '2016-10-23 01:51:15'),
(271, 'hw', 'N/A', 'надо провериь', 3, 1, '2016-10-23 01:51:23'),
(274, 'toga', 'N/A', 'Toggles admin chat.', 3, 1, '2014-06-15 23:02:53'),
(275, 'togg', 'N/A', 'Toggles gamemaster chat.', 3, 1, '2014-06-17 18:14:57'),
(276, 'startres', 'N/A', 'starts a resource', 41, 7, '2014-06-17 18:25:04'),
(277, 'stopres', 'N/A', 'stops the resource', 41, 7, '2014-06-17 18:21:19'),
(278, 'restartres', 'N/A', 'restarts the resource', 1, 7, '2014-06-26 08:49:15'),
(279, 'rescheck', 'N/A', 'checks for certain down resources and starts them', 1, 7, '2014-06-26 08:46:57'),
(280, 'rcs', 'N/A', 'check if the resource \"Resource-Keeper\" is running', 41, 7, '2014-06-26 08:44:47'),
(281, 'generatecode', 'N/A', 'generates a donation code', 3, 7, '2014-06-19 13:41:37'),
(282, 'setdamageproof', 'N/A', 'makes a vehicle damageproof', 2, 3, '2014-06-26 08:51:44'),
(283, 'delitemsfromint', 'N/A', 'Deletes all the items within a specified interior that older than an interval of item\'s day old.', 1, 5, '2014-06-19 13:34:08'),
(285, 'aordersupplies', 'N/A', 'Orders supplies from RS Haul for the current interior without yourself being charged.', 1, 4, '2014-06-15 00:07:06'),
(286, 'setjoblevel', 'N/A', 'Sets player\'s city hall job\'s level and progress', 1, 6, '2014-06-26 08:53:59'),
(287, 'respawntrucks', 'N/A', 'Respawns all unoccupied Delivery Trucks', 1, 3, '2014-06-26 08:48:49'),
(288, 'checkactiveroutes', 'N/A', 'Shows all Delivery Job\'s routes that players are on', 41, 6, '2015-01-24 18:28:17'),
(289, 'fetchactualorders', 'N/A', 'Fetches player\'s Supplies Orders from SQL to game manually (Normally it\'s auto-fetched every 10 minutes)', 41, 6, '2015-01-24 18:28:26'),
(290, 'addactualorder', 'N/A', 'Creates a marker for Delivery Job, it looks exactly the same as actual order from other player.', 41, 6, '2015-01-24 18:28:04'),
(291, 'addtruckerjobmarker', 'N/A', 'Creates a generic drop-off marker for Delivery Driver job.', 41, 6, '2015-01-24 18:28:10'),
(292, 'showactualorders', 'N/A', 'Shows Delivery Job\'s actual supply orders from players.', 41, 6, '2015-01-24 18:28:40'),
(293, 'showalltruckmarkers', 'N/A', 'Shows all Delivery Job drop-off markers (both generic markers and actual order markers)', 41, 6, '2015-01-24 18:28:46'),
(294, 'skiproute', 'N/A', 'Skips Delivery Job\'s current route, jump instantly to next spot (useful when creating job markers)', 1, 6, '2014-06-17 18:27:18'),
(295, 'resetaccount', 'N/A', 'Reset one character or all characters within an account.', 2, 7, '2014-06-26 08:47:03'),
(296, 'deltruckmarker', 'N/A', 'Deletes a Delivery Job\'s marker', 41, 6, '2015-01-24 18:28:21'),
(297, 'aheal', 'N/A', 'Gives yourself full HP, or /aheal [ID] to give it someone else', 11, 7, '2014-06-15 00:05:38'),
(298, 'showadminreports', 'N/A', 'Subscribes to administrator reports, showing them as well.', 1, 1, '2014-06-26 08:55:33'),
(304, 'gmlounge', 'N/A', 'Teleports you to the staff lounge.', 11, 7, '2014-06-21 11:50:28'),
(305, 'g [Text]', 'N/A', 'g чате', 11, 1, '2016-10-23 01:50:48'),
(306, 'ar', 'N/A', 'Accept a report.', 21, 7, '2014-11-23 12:51:14'),
(308, 'dr', 'N/A', 'Drop a report, leaving it unanswered.', 11, 7, '2014-06-19 13:35:43'),
(309, 'fr', 'N/A', 'Mark a report false', 11, 7, '2014-06-19 13:39:46'),
(311, 'sduty, gduty', 'N/A', 'Toggles Supporter duty (On/off)', 11, 7, '2014-06-26 08:50:23'),
(314, 'mark', 'N/A', 'Create a mark for you to teleport to using /gotomark (doing /mark without a specified name will create a temporary one)', 11, 7, '2014-06-26 08:41:01'),
(316, 'gotomark', 'N/A', 'Teleport to a pre-made /mark (/gotomark without a mark name teleports to a temporary one)', 11, 7, '2014-06-26 08:36:33'),
(335, 'forceapp', 'N/A', 'Force player that doesn\'t meet server standards -and- not willing to improve out of game.', 11, 7, '2014-06-19 13:38:51'),
(342, 'renameshop', 'N/A', 'or /renameped or /renamenpc, it renames NPCs in format of \'First Lastname\'', 1, 4, '2014-06-26 08:46:30'),
(345, 'togoverlay', 'N/A', 'Toggles overlay menus on top or buttom of screen. If it\'s disabled, the content will be all printed to chatbox.', 0, 7, '2014-06-17 18:11:09'),
(351, 'settrackingloc', 'N/A', 'Use this command to define where the tracking device in the vehicle is installed.', 1, 3, '2014-06-26 08:55:12'),
(358, 'hashtransactionid', 'N/A', 'Hashes a transaction ID from PayPal into the proper format for donation key.', 3, 7, '2014-06-26 08:37:28'),
(360, 'togreg', 'N/A', 'Toggle the registration of a vehicle.', 1, 3, '2014-06-17 18:08:51'),
(361, 'togplate', 'N/A', 'Toggle the plate visibility of a vehicle.', 1, 3, '2014-06-17 18:09:10'),
(362, 'togvin', 'N/A', 'Toggle the VIN visibility of a vehicle.', 1, 3, '2014-06-17 18:08:26'),
(363, 'addramp', 'N/A', 'Add a vehicle lift (requires a lift remote)', 1, 3, '2014-06-15 00:14:51'),
(364, 'delramp', 'N/A', 'Delete a vehicle lift.', 1, 3, '2014-06-15 16:22:47'),
(365, 'nearbyramps', 'N/A', 'Fetch all nearby vehicle lifts.', 1, 5, '2014-06-26 08:42:56'),
(368, 'vehlib', 'N/A', 'Opens vehicle library', 11, 3, '2014-10-01 19:36:44'),
(369, 'editveh', 'N/A', 'Create/Update Unique Properties for Vehicle.', 21, 3, '2015-01-09 15:50:49'),
(370, 'setdob', 'N/A', 'Set player\'s date of birth', 1, 7, '2014-06-26 08:51:57'),
(372, 'setintlimit', 'N/A', 'Set character\'s max interior slots', 3, 7, '2014-06-26 08:53:34'),
(373, 'setamotd', 'N/A', 'Set the admin message of the day', 3, 1, '2014-06-26 08:51:05'),
(376, 'delad', 'N/A', 'Stops an Advertisement from being aired.', 1, 1, '2015-01-08 15:33:35'),
(377, 'gethere', 'N/A', 'Teleports a player to you.', 11, 7, '2014-06-19 13:42:14'),
(379, 'freeze', 'N/A', 'Freeze a player.', 1, 7, '2014-06-19 13:40:15'),
(381, 'stats', 'N/A', 'Shows a GUI with your character\'s statistics.', 0, 7, '2014-06-15 00:21:18'),
(389, 'nudge', 'N/A', 'Nudges a player, getting their attention.', 11, 7, '2014-06-26 08:43:30'),
(390, 'places', 'N/A', 'Shows you a list of valid places you can /gotoplace.', 11, 7, '2014-06-26 08:44:30'),
(391, 'marks', 'N/A', 'Views all /mark\'s', 11, 7, '2014-06-26 08:41:12'),
(392, 'delmark', 'N/A', 'Deletes a mark, usage: \"/delmark [MARKNAME]\" Not ID', 11, 7, '2014-06-15 16:15:37'),
(393, 'ann', 'N/A', 'Отправить сообщение сверху экрана ', 11, 1, '2016-10-23 01:47:30'),
(394, 'togpm', 'N/A', 'Toggles your private messages if you have the perk.', 0, 1, '2014-06-26 09:01:21'),
(395, 'monitor', 'N/A', 'Toggles monitor window.', 11, 7, '2014-10-05 10:10:22'),
(397, 'omonitor', 'N/A', 'Add an offline player to the monitor', 1, 7, '2014-06-26 08:43:58'),
(400, '\'F7\'', 'F7', 'Toggles the application panel.', 11, 7, '2014-12-16 19:26:43'),
(404, 'checkveh', 'N/A', 'Display details information of a vehicle', 11, 3, '2014-06-15 16:05:50'),
(405, 'makegeneric', 'N/A', 'or makegenericitem, creates to yourself a generic item', 11, 5, '2014-06-26 08:40:17'),
(406, 'unlock', 'K', '(Un)locks the closest vehicle to you, of which you have the key.', 0, 3, '2014-06-26 08:56:44'),
(410, 'fuelveh', 'N/A', 'Fuel a vehicle', 1, 3, '2014-06-19 13:40:56'),
(412, 'flip', 'N/A', 'Flip a vehicle', 11, 3, '2014-10-01 19:14:55'),
(413, 'park', 'N/A', 'Parks the vehicle you\'re in', 0, 3, '2014-06-26 08:44:07'),
(415, 'ed', 'N/A', 'Edit the vehicle description', 0, 3, '2014-06-19 13:35:58'),
(416, 'changename', 'N/a', 'Changes a player\'s character name.', 3, 7, '2014-06-15 00:24:26'),
(418, 'vehlib', 'N/A', 'Allows you to control aspects of custom vehicles in the library', 21, 1, '2014-06-15 12:46:39'),
(419, 'moveitem', 'N', 'Opens a panel for you to control position of an item', 1, 5, '2014-06-26 09:01:41'),
(420, 'apark', 'N/A', 'parks a vehicle without being inside', 1, 3, '2014-06-18 22:16:39'),
(421, 'cks', 'N/A', 'shows character kill requests', 1, 7, '2014-06-26 08:35:28'),
(422, 'advertisements', 'N/A', 'shows a list of post-listing advertisments', 0, 7, '2014-06-21 14:29:15'),
(423, 'showcol', 'N/A', 'show the collide objects in the world. Speed zone (yellow), Speedcam (blue), Restricted parking (Pink), Police Cars (Large Red), Normal (red)', 1, 7, '2014-06-21 21:23:51'),
(424, 'rf', 'N/A', 'restricted frequency database', 1, 2, '2014-10-05 10:12:48'),
(425, 'quitjob', 'N/A', 'Quits the job you currently have', 0, 6, '2014-06-26 09:01:33'),
(426, 'F [message]', 'N/A', 'Out of Character faction chat', 0, 2, '2014-07-06 11:41:50'),
(427, 'N/A', 'F3', 'Faction menu', 0, 2, '2014-06-26 09:03:42'),
(429, 'sendtovct', 'N/A', 'Sends a specific report to the VCT team (regarding request, questions,...)', 11, 3, '2014-07-06 11:39:51'),
(430, 'mt [message]', 'N/A', 'Mapping Team chat', 31, 7, '2014-08-23 15:40:58'),
(431, 'vct [message]', 'N/A', 'Vehicle Consultation Team chat', 21, 1, '2014-07-06 11:43:02'),
(432, 'sell [player name]', 'N/A', 'Продать автомобиль или недвижимость игроку', 0, 4, '2016-10-23 01:57:29'),
(433, 'showadminreports', 'N/A', 'Reveals reports sent out to the admin team, to supporters.', 11, 7, '2014-07-15 08:34:58'),
(434, 'supervise', 'N/A', 'Turns you half invisible, in order to supervise a roleplay.', 11, 7, '2014-07-15 08:35:16'),
(435, 'enterveh [player][car ID][seat]', 'N/A', 'Warps a player into a car.', 11, 3, '2014-07-15 08:35:48'),
(436, 'sendveh', 'N/A', 'Sends a vehicle to a player', 11, 7, '2014-07-15 08:35:08'),
(437, 'getvehweight', 'N/A', 'gives you the weight of a car and the price for the chopping', 1, 3, '2014-07-09 08:15:42'),
(438, 'texlist', 'N/A', 'shecks the textures in an interior, gives ability to edit and delete. ', 0, 4, '2014-08-12 08:08:37'),
(439, 'ads', 'N/A', 'Рекламные объявления', 11, 1, '2016-10-23 01:47:06'),
(440, 'getcar', 'N/A', 'Warps a car to the player.', 11, 3, '2014-08-03 10:45:23'),
(441, 'findalts2', 'N/A', 'More information than a /findalts', 1, 7, '2014-08-05 20:42:19'),
(442, 'ri', 'N/A', 'read a report', 21, 7, '2014-11-23 12:53:19'),
(443, 'srl', '', 'Set\'s the rain level of the current weather', 1, 7, '2014-08-09 23:41:56'),
(444, 'sms [contact_name/number] [message]', 'N/A', 'Отправить смску', 21, 1, '2016-10-23 01:52:36'),
(447, 'fixveh', 'N/A', 'Fixes the vehicle of the player who is in it.', 11, 3, '2014-08-12 08:11:07'),
(448, 'gate [password]', 'N/A', 'opens a gate near you, with or without a password.', 0, 7, '2014-08-12 08:12:00'),
(451, 'call [id игрока или номер]', 'N/A', 'Позвонить игроку', 0, 1, '2016-10-23 01:47:52'),
(452, 'anims', 'N/A', 'opens a list of anims on your chatbox.', 0, 7, '2014-08-12 08:16:08'),
(453, 'animselect', 'N/A', 'opens a full list of animations.', 0, 7, '2014-08-12 08:16:14'),
(455, 'writenote [text]', 'N/A', 'Writes a note that will spawn on your inventory.', 0, 5, '2014-08-16 07:28:40'),
(456, 'fish', 'N/A', 'Starts fishing', 0, 6, '2015-02-04 08:14:42'),
(457, 'totalcatch', 'N/A', 'Displays how much lbs of fishes you have caught so far', 0, 6, '2015-02-04 08:14:57'),
(458, 'sellFish', 'N/A', 'To sell your caught fish', 0, 6, '2015-02-04 08:14:47'),
(459, '911', 'N/A', 'Submit an NPC 911 call.', 11, 1, '2014-10-13 11:55:38'),
(460, 'tempsell', 'N/A', 'gives temporary selling ability like old /sell', 11, 3, '2014-10-01 19:36:33'),
(462, 'arrest', 'N/A', 'for administrators, you have full access to the arrest and management within arrest', 1, 2, '2014-08-25 18:55:01'),
(463, 'items', 'N/A', 'Shows a list of items - (spawning is disabled?)', 11, 5, '2015-02-04 08:15:13'),
(464, 'setjob [player] [job id]', 'N/A', 'Sets a job to a player, leave arguments blank to see ID\'s', 11, 6, '2015-02-04 08:15:01'),
(465, 'setvol [0-100]', 'N/A', 'Sets the radio volume', 0, 3, '2015-02-04 08:12:20'),
(468, 'nearbyshops', 'N/A', 'Shows any near by shop NPC\'s, along with their ID', 0, 7, '2015-02-04 08:13:19'),
(469, 'moveshop', 'N/A', 'Moves a shop NPC to your location', 11, 7, '2014-11-29 09:14:15'),
(471, 'unforceapp [Partial Username]', 'N/A', 'Unforceapp a player.', 11, 7, '2015-02-06 19:00:48'),
(473, 'nearbyfuels', 'N/A', 'Find nearby fuel NPCs.', 0, 7, '2015-02-04 08:13:10'),
(474, 'delfuel [id]', 'N/A', 'Delete a fuel NPC.', 1, 7, '2014-11-29 09:14:09'),
(477, 'nearbyitems', 'N/A', 'Shows nearby items.', 11, 5, '2015-02-04 08:15:18'),
(480, 'sw', '', 'Possibility to change the wather.', 3, 7, '2014-10-04 21:30:54'),
(481, 'srl ', '', 'Sets the amount of rain.', 3, 7, '2014-10-04 21:31:18'),
(482, 'delitem', '', 'Удалить вещь', 1, 5, '2016-10-23 01:58:36'),
(486, 'processcustominterior [interior ID]', '', 'Manually process a custom interior upload', 3, 4, '2014-10-19 08:24:14'),
(487, 'processcustominterior [interior ID]', '', 'Manually process a custom interior upload', 41, 4, '2014-10-19 08:24:41'),
(488, 'showkills', '', 'Show the latest kills', 1, 7, '2014-10-19 18:36:23'),
(489, 'setserverpassword [Пароль или оставьте пустым - удалить пароль]', '', 'Установить пароль на сервер', 1, 7, '2016-10-23 01:59:37'),
(490, 'setintfaction [Faction Name or Faction ID]', '', 'Transfer an interior\'s ownership to a faction. ', 2, 2, '2014-10-25 18:44:56'),
(491, 'setinttomyfaction ', 'N/A', 'Transfer an interior\'s ownership from a faction leader to his faction.', 0, 2, '2015-02-04 08:12:30'),
(493, 'fuelveh [ID] [Liters, 0=full]', 'N/A', 'Refills the fuel tank of the given player ID', 11, 3, '2015-02-04 08:12:14'),
(494, 'delemitters', '', 'Deletes all emitters', 1, 5, '2015-01-01 11:53:02'),
(502, 'adddancer', 'N/A', 'Adds an NPC dancer', 2, 7, '2014-12-03 14:34:46'),
(503, 'fixinventory', 'N/A', 'Fixes your inventory client-side, for when it gets bugged.', 0, 5, '2014-12-06 12:10:42'),
(504, 'setinttomyfaction', 'N/A', 'Set an interior you own to your faction ', 0, 4, '2014-12-06 16:25:25'),
(506, 'groundsnow', 'N/A', 'Toggle the snow shader', 0, 7, '2014-12-06 23:37:56'),
(507, 'whitelists', 'N/A', 'List all staff serial whitelist', 0, 7, '2015-02-04 08:13:14'),
(508, 'addserialwl [Username] [Serial]', '', 'Add new item to serial whitelist.', 3, 7, '2014-12-13 18:07:16'),
(509, 'delserialwl [Whitelist ID]', '', 'Remove a staff from serial whitelist', 3, 7, '2014-12-13 18:07:47'),
(510, 'banserial [Serial Number] [Reason]', '', 'Ban a serial number.', 1, 7, '2014-12-29 21:45:41'),
(511, 'banip [IP Address] [Reason]', '', 'Ban an IP address.', 1, 7, '2015-01-07 19:25:29'),
(512, 'showban', '', 'Show details of a ban.', 1, 7, '2014-12-29 21:47:02'),
(513, 'staffs', '', 'Opens staff manager', 3, 7, '2015-01-08 01:30:50'),
(514, 'adde', 'N/A', 'adds an elevator your current spot. Type it again to set the second spot.', 11, 7, '2015-01-08 03:02:07'),
(515, 'entercar [player] [car ID] [seat]', 'N/A', 'ТП в автомобиль', 11, 1, '2016-10-23 01:50:36'),
(516, 'dutyadmin', '', 'Manages /duty systems', 3, 2, '2015-01-09 15:23:54'),
(517, 'watch [ID]', '', 'Watches another player', 1, 7, '2015-01-09 15:24:29'),
(518, 'autowatch [Time Interval]', '', 'it\'s like /watch, but scrolls through everyone online. Interval is in seconds', 1, 7, '2015-01-13 20:21:36'),
(519, 'injure', 'N/A', 'Base command for the \"Health\" System. It allows you to add an injury to yourself or another.', 0, 7, '2015-02-04 08:13:02'),
(520, 'irespond', 'N/A', 'Allows you to respond with either (y)es or (n)o to a request from /injure', 11, 7, '2015-02-04 08:12:52'),
(521, 'diagnose', 'N/A', 'Used to open the GUI of a player to view their current injuries. RP this accordingly.', 0, 7, '2015-02-04 08:13:32'),
(522, 'treat', 'N/A', 'Allows you to treat a person of an injury. This has an associated money cost. RP it accordingly.', 0, 7, '2015-02-04 08:12:57'),
(523, '/dele', 'N/A', 'Deletes an elevator ', 11, 7, '2015-02-04 08:13:06'),
(524, 'startbus', 'N/A', 'Begins a bus route if you are inside a bus as a driver.', 0, 6, '2015-01-29 05:31:10'),
(526, 'handbrake', 'G', 'Applies the handbrake or kickstand to vehicles.', 0, 3, '2015-01-29 05:36:46'),
(527, 'movesafe', 'N/A', 'Moves a safe placed in an interior. (Key holders only)', 0, 5, '2015-01-29 05:39:00'),
(528, 'ri [ID]', 'N/A', 'Shows report information.', 11, 7, '2015-01-29 05:42:06'),
(530, 'fp', 'N/A', 'Toggles first person view, type it again to switch back.', 0, 7, '2015-01-29 05:50:04'),
(531, 'togg', 'N/A', 'Toggle supporter chat on/off.', 11, 1, '2015-01-29 05:53:56'),
(532, '=', '=', 'Toggles hazard lights/flashers.', 0, 3, '2015-02-06 06:31:02'),
(533, '[', '[', 'Turns on a vehicle\'s left directional.', 0, 3, '2015-02-04 08:14:06'),
(534, ']', ']', 'Turns on a vehicle\'s right directional.', 0, 3, '2015-02-04 08:14:02'),
(535, 'radio [Message]', 'Y', 'Sends a message via radio to everyone on that frequency.', 0, 1, '2015-01-29 05:58:09'),
(537, 'say [Text]', 'T', 'To use in character chat.', 0, 1, '2015-01-29 06:04:06'),
(538, 'I', 'I', 'Opens your inventory.', 0, 5, '2015-02-04 08:14:33'),
(539, 'p [Text]', 'N/A', 'Send an in character message during a phone call.', 0, 1, '2015-01-29 06:03:16'),
(540, 'b [текст]', 'B', 'OOC чат', 0, 4, '2016-10-23 01:56:17'),
(541, 'ooc [Text]', 'N/A', 'To use global out of character chat when enabled.', 0, 1, '2015-01-29 06:04:33'),
(542, 'seatbelt', 'Z', 'Buckles in your seatbelt.', 0, 3, '2015-01-29 06:06:24'),
(543, 'togwindow', 'X', 'Opens/Closes vehicle windows.', 0, 3, '2015-01-29 06:07:05'),
(544, 'pay [Player name/ID]', 'N/A', 'Sends money to another player. (Requires 10 hours on any character)', 0, 7, '2015-01-29 06:11:26'),
(545, 'banaccount', '', 'Ban an account permanently. (Excluding IP and serial)', 1, 7, '2015-02-03 07:18:31'),
(546, 'jailtime', 'N/A', 'Shows the time that you are jailed for.', 0, 7, '2015-02-04 06:22:44'),
(547, 'seefar [250 - 20000]', 'N/A', 'Changes the clip distance of the client to the selected value.', 0, 7, '2015-02-04 06:24:54'),
(548, 'clearchat', 'N/A', 'Clears your entire chatbox.', 0, 7, '2015-02-04 06:25:51'),
(549, 'togglehud', 'N/A', 'Toggles the in game HUD on or off.', 0, 7, '2015-02-04 06:26:42'),
(550, 'showfeedbacks', 'N/A', 'Shows your recieved feedback.', 11, 7, '2015-02-04 06:29:29'),
(551, 'staffs', 'N/A', 'A quick command to open up staff manager.', 11, 7, '2015-02-04 06:30:03'),
(552, 'findalts [Name/ID]', 'N/A', 'Shows the selected player\'s other characters as well as hours played on them.', 11, 7, '2015-02-08 15:21:25'),
(553, 'staff', 'N/A', 'Opens up a menu showing online staff members.', 0, 7, '2015-02-07 18:40:48');

-- --------------------------------------------------------

--
-- Table structure for table `commands_library`
--

CREATE TABLE `commands_library` (
  `cmID` int(11) NOT NULL,
  `cmType` int(3) NOT NULL DEFAULT 1,
  `cmLevel` int(3) NOT NULL DEFAULT 0,
  `cmSubType` int(3) NOT NULL DEFAULT 0,
  `cmName` text DEFAULT NULL,
  `cmExplanation` text DEFAULT NULL,
  `cmCreationDate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves all info about all kinds of commands in /cmds, /gh and';

--
-- Dumping data for table `commands_library`
--

INSERT INTO `commands_library` (`cmID`, `cmType`, `cmLevel`, `cmSubType`, `cmName`, `cmExplanation`, `cmCreationDate`) VALUES
(1, 1, 0, 0, 'trace', 'traces a phone number and tells you who owns it. Player must be online.', '2013-06-29 14:10:19'),
(2, 1, 0, 0, 'getkey', 'Spawns yourself a key of interior or vehicle that you\'re currently in.', '2013-06-29 14:10:19'),
(3, 1, 0, 0, 'cr', 'without specified ID will closes all your own accepted reports.', '2013-06-29 14:10:19'),
(4, 1, 0, 0, 'createemitter [Emitter Type]', 'Spawns Synced Fire/Water Emitters', '2013-06-29 14:10:19'),
(5, 1, 0, 0, 'nearbyemitters', 'Shows all nearby Fire/Water emitters.', '2013-06-29 14:10:19'),
(6, 1, 0, 0, 'delemitters', 'Deletes all nearby Fire/Water emitters.', '2013-06-29 14:10:19'),
(7, 1, 0, 0, 'delemitter [Emitter ID]', 'Deletes a Fire/Water emitters.', '2013-06-29 14:10:19'),
(8, 1, 0, 0, 'delnearbyshops', 'Deletes nearby shops.', '2013-06-29 14:10:19'),
(9, 1, 0, 0, 'reloadshop [ID]', 'Reloads a bugged shop.', '2013-06-29 14:10:19'),
(10, 1, 0, 0, 'restoreshop [ID]', 'Restores a deleted NPC from SQL.', '2013-06-29 14:10:19'),
(11, 1, 0, 0, 'delshop [ID]', 'Deletes a NPC from game, still exist in SQL.', '2013-06-29 14:10:19'),
(12, 1, 0, 0, 'showallcustomshops', 'Shows all custom shops parameters and settings.', '2013-06-29 14:10:19'),
(13, 1, 0, 0, 'fixnearbyeleators', 'Fixes near by elevators. Players can use too.', '2013-06-29 14:10:19'),
(14, 1, 0, 0, 'fixvehvis [Driver\'s partial Name/ID]', 'Fixes player\'s car\'s visual, leave the engine\'s health.', '2013-06-29 14:10:19'),
(15, 1, 0, 0, 'findvehid [Veh Name]', 'Gets car\'s Model ID from Name.', '2013-06-29 14:10:19'),
(16, 1, 0, 0, 'getcolor [Veh ID]', 'Gets car\'s color.', '2013-06-29 14:10:19'),
(17, 1, 0, 0, 'respawnint', 'Respawns all vehicle within current interior/dimension.', '2013-06-29 14:10:19'),
(18, 1, 0, 0, 'restock', 'Restocks businesses, you must be inside an interior to restock. Or use SYNTAX: /restock [Interior ID] [Amount 1~300]', '2013-06-29 14:10:19'),
(19, 1, 0, 0, 'ojail [Exact Username] [Minutes(>=1) 999=Perm] [Reason]', 'Jails an offline player.', '2013-06-29 14:10:19'),
(20, 1, 0, 0, 'sojail [Exact Username] [Minutes(>=1) 999=Perm] [Reason]', 'Silently jails an offline player.', '2013-06-29 14:10:19'),
(21, 1, 0, 0, 'oban [Exact Username] [Time in Hours, 0 = Infinite] [Reason]', 'Bans an offline player.', '2013-06-29 14:10:19'),
(22, 1, 0, 0, 'delefromint [Interior ID, 0 = world map]', 'Deletes all elevators that connect to a specified interior.', '2013-06-29 14:10:19'),
(23, 1, 0, 0, 'delnearbye', 'Deletes all nearby elevators.', '2013-06-29 14:10:19'),
(24, 1, 0, 0, 'stopradiodistrict', 'Stops all car radios within current district.', '2013-06-29 14:10:19'),
(25, 1, 0, 0, 'adde', 'creates an elevator', '2013-06-29 14:10:19'),
(26, 1, 0, 0, 'adde2', 'Create an elevator between you and another player', '2013-06-29 14:10:19'),
(27, 1, 0, 0, 'dele', 'deletes an elevator', '2013-06-29 14:10:19'),
(28, 1, 0, 0, 'nearbye', 'shows nearby elevators', '2013-06-29 14:10:19'),
(29, 1, 0, 0, 'togglee', 'enables/disables an elevator', '2013-06-29 14:10:19'),
(30, 1, 0, 0, 'togautocheck', 'Toogles auto opening player /check on /ar reports.', '2013-06-29 14:10:19'),
(31, 1, 0, 0, 'changewarnstyle', 'changes admin warning message displaying style.', '2013-06-29 14:10:19'),
(32, 1, 0, 0, 'ur', 'view unanswered reports.', '2013-06-29 14:10:19'),
(34, 1, 0, 0, 'adminlounge', 'Chill out in the lounge', '2013-06-29 14:10:19'),
(35, 1, 0, 0, 'check', 'retrieves specified player\'s information', '2013-06-29 14:10:19'),
(36, 1, 0, 0, 'stats', 'shows players vehicle id\'s, languages etc', '2013-06-29 14:10:19'),
(37, 1, 0, 0, 'history', 'checks the admin history of the player, works also when offline.', '2013-06-29 14:10:19'),
(38, 1, 0, 0, 'auncuff', 'uncuffs the player', '2013-06-29 14:10:19'),
(39, 1, 0, 0, 'revive', 'revives a player that has been PKd.', '2013-06-29 14:10:19'),
(40, 1, 0, 0, 'pmute', 'mutes the player', '2013-06-29 14:10:19'),
(41, 1, 0, 0, 'togooc', 'Toggles OOC on/off', '2013-06-29 14:10:19'),
(42, 1, 0, 0, 'stogooc', 'Siently Toggles OOC on/off', '2013-06-29 14:10:19'),
(43, 1, 0, 0, 'disarm', 'takes all weapon from the player', '2013-06-29 14:10:19'),
(44, 1, 0, 0, 'freconnect', 'reconnects the player', '2013-06-29 14:10:19'),
(45, 1, 0, 0, 'giveitem', 'gives the player the specified item, see /itemlist for ids', '2013-06-29 14:10:19'),
(46, 1, 0, 0, 'sethp', 'sets the health of the player', '2013-06-29 14:10:19'),
(47, 1, 0, 0, 'setarmor', 'sets the armor of the player', '2013-06-29 14:10:19'),
(48, 1, 0, 0, 'setskin', 'sets the skin of a player', '2013-06-29 14:10:19'),
(49, 1, 0, 0, 'changename', 'changes the character name', '2013-06-29 14:10:19'),
(50, 1, 0, 0, 'slap', 'drops the player from a height of 15', '2013-06-29 14:10:19'),
(51, 1, 0, 0, 'recon', 'spectate a player', '2013-06-29 14:10:19'),
(52, 1, 0, 0, 'fuckrecon', 'forces recon to stop', '2013-06-29 14:10:19'),
(53, 1, 0, 0, 'pkick', 'kicks the player from the server', '2013-06-29 14:10:19'),
(54, 1, 0, 0, 'pban', 'bans the player for the given time, specify 0 as hours for permanent ban', '2013-06-29 14:10:19'),
(55, 1, 0, 0, 'unban', 'unbans the player with the given character name', '2013-06-29 14:10:19'),
(56, 1, 0, 0, 'unbanip', 'unbans the specified ip', '2013-06-29 14:10:19'),
(57, 1, 0, 0, 'unbanserial', 'unbans the specified serial', '2013-06-29 14:10:19'),
(58, 1, 0, 0, 'gotoplace', 'teleports you to one of those 4 places', '2013-06-29 14:10:19'),
(59, 1, 0, 0, 'jail', 'jails the player, if minutes >= 999 it\'s permanent', '2013-06-29 14:10:19'),
(60, 1, 0, 0, 'unjail', 'unjails the player', '2013-06-29 14:10:19'),
(61, 1, 0, 0, 'jailed', 'shows a list of players that are in adminjail, including time left and reason', '2013-06-29 14:10:19'),
(62, 1, 0, 0, 'goto', 'teleport to another player', '2013-06-29 14:10:19'),
(63, 1, 0, 0, 'gethere', 'teleports the player to you', '2013-06-29 14:10:19'),
(64, 1, 0, 0, 'sendto', 'teleports a player to another one', '2013-06-29 14:10:19'),
(65, 1, 0, 0, 'freeze', 'freezes the player', '2013-06-29 14:10:19'),
(66, 1, 0, 0, 'unfreeze', 'unfreezes the player', '2013-06-29 14:10:19'),
(67, 1, 0, 0, 'mark', 'saves your current position', '2013-06-29 14:10:19'),
(68, 1, 0, 0, 'gotomark', 'teleports to the position where you did /mark [label]', '2013-06-29 14:10:19'),
(69, 1, 0, 0, 'adminduty', '(un)marks you as admin on duty', '2013-06-29 14:10:19'),
(70, 1, 0, 0, 'setmotd', 'updates the message of the day', '2013-06-29 14:10:19'),
(71, 1, 0, 0, 'setamotd', 'updates the admin message of the day', '2013-06-29 14:10:19'),
(72, 1, 0, 0, 'amotd', 'shows the current admin message of the day', '2013-06-29 14:10:19'),
(73, 1, 0, 0, 'warn', 'issues a warning, player is banned when having 3 warnings', '2013-06-29 14:10:19'),
(74, 1, 0, 0, 'showinv', 'views the inventory of the player', '2013-06-29 14:10:19'),
(75, 1, 0, 0, 'togmytag', 'toggles your nametag on and off', '2013-06-29 14:10:19'),
(76, 1, 0, 0, 'dropme', 'drops you off at the current freecam position', '2013-06-29 14:10:19'),
(77, 1, 0, 0, 'disappear', 'disappear', '2013-06-29 14:10:19'),
(78, 1, 0, 0, 'listcarprices', 'shows list with carprices in dealerships', '2013-06-29 14:10:19'),
(79, 1, 0, 0, 'findalts', 'shows all characters the player has', '2013-06-29 14:10:19'),
(80, 1, 0, 0, 'findip', 'shows all accounts the player has', '2013-06-29 14:10:19'),
(81, 1, 0, 0, 'findserial', 'shows all accounts the player has', '2013-06-29 14:10:19'),
(82, 1, 0, 0, 'setlanguage or /setlang', 'adjusts the skill of a player\'s language, or learns it to him', '2013-06-29 14:10:19'),
(83, 1, 0, 0, 'dellanguage', 'deletes a language from the player\'s knowledge', '2013-06-29 14:10:19'),
(84, 1, 0, 0, 'aunblindfold', 'unblindfold the player', '2013-06-29 14:10:19'),
(85, 1, 0, 0, 'agivelicense', 'gives the player a license', '2013-06-29 14:10:19'),
(86, 1, 0, 0, 'resetcontract', 'resets the job time limit for a person.', '2013-06-29 14:10:19'),
(87, 1, 0, 0, 'ads', 'Shows all pending adverts.', '2013-06-29 14:10:19'),
(88, 1, 0, 0, 'freezead', 'Freeze an advert.', '2013-06-29 14:10:19'),
(89, 1, 0, 0, 'unfreezead', 'Unfreeze an advert', '2013-06-29 14:10:19'),
(90, 1, 0, 0, 'deletead', 'Delete an advert', '2013-06-29 14:10:19'),
(91, 1, 0, 0, '\'P\'', 'Locks a world item. Make it unpickable.', '2013-06-29 14:10:19'),
(92, 1, 0, 0, 'itemprotect', 'Sets locked world item pickable by faction members.', '2013-06-29 14:10:19'),
(93, 1, 0, 0, 'addii', 'Adds an information marker', '2013-06-29 14:10:19'),
(94, 1, 0, 0, 'delii', 'Deletes an information marker', '2013-06-29 14:10:19'),
(95, 1, 0, 0, 'nearbyii', 'Shows all nearby information markers', '2013-06-29 14:10:19'),
(96, 1, 0, 0, 'makeshop ', 'Creates a NPC.', '2013-06-29 14:10:19'),
(97, 1, 0, 0, 'nearbyshops ', 'Shows all near by NPCs.', '2013-06-29 14:10:19'),
(98, 1, 0, 0, 'gunlist or /gunchart', 'Showing a details weapon\'s properties table with IDs.', '2013-06-29 14:10:19'),
(99, 1, 0, 0, 'setage ', 'Change player\'s age', '2013-06-29 14:10:19'),
(100, 1, 0, 0, 'setrace ', 'Change player\'s race', '2013-06-29 14:10:19'),
(101, 1, 0, 0, 'setheight  ', 'Change player\'s height', '2013-06-29 14:10:19'),
(102, 1, 0, 0, 'setgender  ', 'Change player\'s gender', '2013-06-29 14:10:19'),
(103, 1, 0, 0, 'sll  ', 'Change suspension\'s height', '2013-06-29 14:10:19'),
(104, 1, 0, 0, 'getsll  ', 'Gets suspension\'s height', '2013-06-29 14:10:19'),
(105, 1, 0, 0, 'resetsll', 'Resets suspension\'s height for the current vehicle.', '2013-06-29 14:10:19'),
(106, 1, 0, 0, 'sdt  ', 'Change drivetrain type', '2013-06-29 14:10:19'),
(107, 1, 0, 0, 'getsdt  ', 'Gets drivetrain type', '2013-06-29 14:10:19'),
(108, 1, 0, 0, 'resetsdt', 'Resets drive type for the current vehicle.', '2013-06-29 14:10:19'),
(109, 1, 0, 0, 'skick', 'Silently kick a player', '2013-06-29 14:10:19'),
(110, 1, 0, 0, 'sjail  ', 'Silently jail a player', '2013-06-29 14:10:19'),
(111, 1, 0, 0, 'sjail  ', 'Silently jail a player', '2013-06-29 14:10:19'),
(112, 1, 0, 0, 'stogooc  ', 'Silently toggle global OOC chat', '2013-06-29 14:10:19'),
(113, 1, 0, 0, 'setjob  ', 'Sets player job.', '2013-06-29 14:10:19'),
(114, 1, 0, 0, 'deljob  ', 'Deletes player job.', '2013-06-29 14:10:19'),
(115, 1, 0, 0, 'issuepilotcertificate  ', 'Issues player a pilot license', '2013-06-29 14:10:19'),
(116, 1, 0, 0, 'issuepc  ', 'Issues player a pilot license', '2013-06-29 14:10:19'),
(117, 1, 0, 0, 'items or /itemlist ', 'Opens Item Creator.', '2013-06-29 14:10:19'),
(118, 1, 0, 0, 'settrainrailed ', 'Sets a train off/on the rail.', '2013-06-29 14:10:19'),
(119, 1, 0, 0, 'settraindirection', 'Sets a train direction to (counter)clockwise.', '2013-06-29 14:10:19'),
(120, 1, 0, 0, 'listcarprices', 'Shows an list of vehicles in car dealerships', '2013-06-29 14:10:19'),
(121, 1, 0, 0, 'unflip', 'unflips the car', '2013-06-29 14:10:19'),
(122, 1, 0, 0, 'unlockcivcars', 'unlocks all civilian vehicles', '2013-06-29 14:10:19'),
(123, 1, 0, 0, 'oldcar', 'retrieves the id of the last car you drove', '2013-06-29 14:10:19'),
(124, 1, 0, 0, 'thiscar', 'retrieves the id of your current car', '2013-06-29 14:10:19'),
(125, 1, 0, 0, 'gotocar', 'teleports you to the car with that id', '2013-06-29 14:10:19'),
(126, 1, 0, 0, 'getcar', 'teleports the car to you', '2013-06-29 14:10:19'),
(127, 1, 0, 0, 'nearbyvehicles', 'shows all vehicles within a radius of 20', '2013-06-29 14:10:19'),
(128, 1, 0, 0, 'respawnveh', 'respawns the vehicle with that id', '2013-06-29 14:10:19'),
(129, 1, 0, 0, 'respawnall', 'respawns all vehicles', '2013-06-29 14:10:19'),
(130, 1, 0, 0, 'respawndistrict', 'respawns all vehicles in the district you are in', '2013-06-29 14:10:19'),
(131, 1, 0, 0, 'respawnciv', 'respawns all civilian (job) vehicles', '2013-06-29 14:10:19'),
(132, 1, 0, 0, 'findveh', 'retrieves the model for that vehicle name', '2013-06-29 14:10:19'),
(133, 1, 0, 0, 'fixveh', 'repairs a player\'s vehicle', '2013-06-29 14:10:19'),
(134, 1, 0, 0, 'fixvehs', 'repairs all vehicles', '2013-06-29 14:10:19'),
(135, 1, 0, 0, 'fixvehis', 'fixes the vehicles look, engine may remain broken', '2013-06-29 14:10:19'),
(136, 1, 0, 0, 'blowveh', 'blows up a players car', '2013-06-29 14:10:19'),
(137, 1, 0, 0, 'setcarhp', 'sets the health of a car, full health is 1000.', '2013-06-29 14:10:19'),
(138, 1, 0, 0, 'fuelveh', 'refills a players vehicle', '2013-06-29 14:10:19'),
(139, 1, 0, 0, 'fuelvehs', 'refills all vehicles', '2013-06-29 14:10:19'),
(140, 1, 0, 0, 'setcolor', 'changes the players vehicle colors', '2013-06-29 14:10:19'),
(141, 1, 0, 0, 'getcolor', 'returns the colors of a vehicle', '2013-06-29 14:10:19'),
(142, 1, 0, 0, 'entercar', 'puts the player into the given vehicle at either the specified seat, or if none then the first free seat', '2013-06-29 14:10:19'),
(143, 1, 0, 0, 'getpos', 'outputs your current position, interior and dimension', '2013-06-29 14:10:19'),
(144, 1, 0, 0, 'x', 'increases your x-coordinate by the given value', '2013-06-29 14:10:19'),
(145, 1, 0, 0, 'y', 'increases your y-coordinate by the given value', '2013-06-29 14:10:19'),
(146, 1, 0, 0, 'z', 'increases your z-coordinate by the given value', '2013-06-29 14:10:19'),
(147, 1, 0, 0, 'set*', 'sets your coordinates - available combinations: x, y, z, xyz, xy, xz, yz', '2013-06-29 14:10:19'),
(148, 1, 0, 0, 'reloadint', 'reloads an interior from the database', '2013-06-29 14:10:19'),
(149, 1, 0, 0, 'nearbyints', 'shows nearby interiors', '2013-06-29 14:10:19'),
(150, 1, 0, 0, 'setintname', 'changes an interior name', '2013-06-29 14:10:19'),
(151, 1, 0, 0, 'setfee', 'sets an fee on entering the interior', '2013-06-29 14:10:19'),
(152, 1, 0, 0, 'getintid', 'Gets the interior id', '2013-06-29 14:10:19'),
(153, 1, 0, 0, 'setdim or /setdimension', 'Sets the players dimension id', '2013-06-29 14:10:19'),
(154, 1, 0, 0, 'setint or /setinterior', 'Setst he players interior id', '2013-06-29 14:10:19'),
(155, 1, 0, 0, 'addcandidate', 'add\'s player to election vote list', '2013-06-29 14:10:19'),
(156, 1, 0, 0, 'delcandidate', 'deletes a player to election vote list', '2013-06-29 14:10:19'),
(157, 1, 0, 0, 'showresults', 'shows the results of the election', '2013-06-29 14:10:19'),
(158, 1, 0, 0, 'showfactions', 'shows a list with factions', '2013-06-29 14:10:19'),
(159, 1, 0, 0, ' /respawnfaction', 'respawns faction vehicles', '2013-06-29 14:10:19'),
(160, 1, 0, 0, 'resetbackup', 'Resets PD\'s backup unit', '2013-06-29 14:10:19'),
(161, 1, 0, 0, 'resetassist', 'Resets ES\'s assist system', '2013-06-29 14:10:19'),
(162, 1, 0, 0, 'resettowbackup', 'Resets towing backup system', '2013-06-29 14:10:19'),
(163, 1, 0, 0, 'aremovespikes', 'Removes all the PD spikes', '2013-06-29 14:10:19'),
(164, 1, 0, 0, 'clearnearbytag', 'Clears nearby tag', '2013-06-29 14:10:19'),
(165, 1, 0, 0, 'nearbytags', 'Shows nearby tag and its creators', '2013-06-29 14:10:19'),
(166, 1, 0, 0, 'changelock', 'changes the lock from the vehicle/interior', '2013-06-29 14:10:19'),
(167, 1, 0, 0, 'restartgatekeepers', 'restarts the gatekeepers resource', '2013-06-29 14:10:19'),
(168, 1, 0, 0, 'bury', 'buries the player; removes the ck corpse', '2013-06-29 14:10:19'),
(169, 1, 0, 0, 'listadverts', 'gives a list with recently ran and pending adverts', '2013-06-29 14:10:19'),
(170, 1, 0, 0, 'freeze', 'prevents an ad from being aired, max is 10 minutes.', '2013-06-29 14:10:19'),
(171, 1, 0, 0, 'unfreeze', 'Unfreezes an advert', '2013-06-29 14:10:19'),
(172, 1, 0, 0, 'deletead', 'Marks an ad as aired', '2013-06-29 14:10:19'),
(173, 1, 0, 0, 'resetpos', 'Reset player\'s position, works when player\'s offline.', '2013-06-29 14:10:19'),
(174, 1, 0, 0, 'delsupercar', 'deletes the supercar you\'re in, given that it meets the criteria for deletion.', '2013-06-29 14:07:57'),
(175, 1, 0, 0, 'setbiznote', 'Sets business greeting/notification message.', '2013-06-29 14:07:57'),
(176, 1, 0, 0, 'delitemsfromint [Int ID] [Day old of Items]', 'Deletes all the items within a specified interior that older than an interval of item\'s day old.', '2013-06-29 14:07:57'),
(177, 1, 0, 0, 'ints or /interiors', 'Opens Interior Manager.', '2013-06-29 14:07:57'),
(178, 1, 0, 0, 'delint', 'Deletes the interior from game and disables it from loading in next server/resource restarts.', '2013-06-29 14:07:57'),
(179, 1, 0, 0, 'delthisint or /delthisinterior', 'Deletes the interior you\'re currently in it from game and disables it from loading in next server/resource restarts.', '2013-06-29 14:07:57'),
(180, 1, 0, 0, 'restoreint ', 'Restores a deleted interior included safe, items and NPCs inside it.', '2013-06-29 14:07:57'),
(181, 1, 0, 0, 'gotohouse', 'teleports to the house', '2013-06-29 14:07:57'),
(182, 1, 0, 0, 'gotoint', 'teleports to the interior', '2013-06-29 14:07:57'),
(183, 1, 0, 0, 'gotointi', 'teleports inside of an interior', '2013-06-29 14:07:57'),
(184, 1, 0, 0, 'veh', 'spawns a temporary vehicle', '2013-06-29 14:07:57'),
(185, 1, 0, 0, 'resetshopwage', 'Resets all shops wages to $0.', '2013-06-29 14:07:57'),
(186, 1, 0, 0, 'forceupdateshopwage', 'Forces update all shop wages.', '2013-06-29 14:07:57'),
(187, 1, 0, 0, 'delnearbyvehs', 'Deletes all the nearby (temporary) vehicles.', '2013-06-29 14:07:57'),
(188, 1, 0, 0, 'delveh', 'Deletes the (temporary) vehicle with that id', '2013-06-29 14:07:57'),
(189, 1, 0, 0, 'delthisveh', 'Deletes the (temporary) vehicle', '2013-06-29 14:07:57'),
(190, 1, 0, 0, 'restoreveh', 'Restores a deleted vehicle.', '2013-06-29 14:07:57'),
(191, 1, 0, 0, 'makeveh', 'creates a new permanent vehicle', '2013-06-29 14:07:57'),
(192, 1, 0, 0, 'makecivveh', 'creates a new permanent civilian vehicle', '2013-06-29 14:07:57'),
(193, 1, 0, 0, 'addupgrade', 'upgrades a players car', '2013-06-29 14:07:57'),
(194, 1, 0, 0, 'setpaintjob', 'set another paintjob on a vehicle', '2013-06-29 14:07:57'),
(195, 1, 0, 0, 'setvariant', 'set another variant on a vehicle', '2013-06-29 14:07:57'),
(196, 1, 0, 0, 'delupgrade', 'removes a specific upgrade from the player\'s car', '2013-06-29 14:07:57'),
(197, 1, 0, 0, 'resetupgrades', 'removes all upgrades on the player\'s car', '2013-06-29 14:07:57'),
(198, 1, 0, 0, 'aunimpound', 'unimpounds the vehicle from the BTR lot', '2013-06-29 14:07:57'),
(199, 1, 0, 0, 'setvehtint', 'adds or removes vehicle tint', '2013-06-29 14:07:57'),
(200, 1, 0, 0, 'atakelicense', 'revokes the player a license (use full name for offline players', '2013-06-29 14:07:57'),
(201, 1, 0, 0, 'setvehplate', 'changes the plate of a vehicle', '2013-06-29 14:07:57'),
(202, 1, 0, 0, 'setvehfaction', 'changes the owner of a vehicle to a faction, use factionid -1 to set it to yourself', '2013-06-29 14:07:57'),
(203, 1, 0, 0, 'gates', 'Opens Gate Manager', '2013-06-29 14:07:57'),
(204, 1, 0, 0, 'gotogate', 'Teleports to a gate.', '2013-06-29 14:07:57'),
(205, 1, 0, 0, 'delgate', 'Deletes to a gate.', '2013-06-29 14:07:57'),
(206, 1, 0, 0, 'loginto [Exact Character Name] ', 'Logs into an other account\'s character.', '2013-06-29 14:07:57'),
(207, 1, 0, 0, 'forcepayday [Player ID/Name] ', 'Forces a player to get payday.', '2013-06-29 14:04:41'),
(208, 1, 0, 0, 'forcepaydayall ', 'Forces all players to get paydays.', '2013-06-29 14:04:38'),
(209, 1, 0, 0, 'rwarn [warn #]', 'sends a predefined admin warnings or custom admin warning.', '2013-06-29 14:07:57'),
(210, 1, 0, 0, 'soban [Player Username] [Time in Hours, 0 = Infinite] [Reason]', 'Silently bans an offline player.', '2013-06-29 14:07:57'),
(211, 1, 0, 0, 'givesuperman [Player Partial Nick / ID]', 'Gives player temporary ability to fly. Execute the cmd again to revoke the ability. Ability will be automatically gone after player relogs.', '2013-06-29 14:06:01'),
(212, 1, 0, 0, 'sw', 'change the weather', '2013-06-29 14:07:57'),
(213, 1, 0, 0, 'addatm', 'adds an ATM at this spot', '2013-06-29 14:07:57'),
(214, 1, 0, 0, 'delatm', 'deletes an ATM with the id', '2013-06-29 14:07:57'),
(215, 1, 0, 0, 'nearbyatms', 'shows the nearby ATMs', '2013-06-29 14:07:57'),
(216, 1, 0, 0, 'bigears', 'hook yourself between someone\'s chats', '2013-06-29 14:07:57'),
(217, 1, 0, 0, 'bigearsf', 'hook yourself between faction chats', '2013-06-29 14:07:57'),
(218, 1, 0, 0, 'nearbyatms', 'shows the nearby ATMs', '2013-06-29 14:07:57'),
(219, 1, 0, 0, 'gunmaker', 'Opens Weapon Creator', '2013-06-29 14:04:50'),
(220, 1, 0, 0, 'makepaynspray', 'creates an pay n spray', '2013-06-29 14:07:57'),
(221, 1, 0, 0, 'nearbypaynsprays', 'shows nearby pay n sprays', '2013-06-29 14:07:57'),
(222, 1, 0, 0, 'delpaynspray', 'deletes an pay n spray', '2013-06-29 14:07:57'),
(223, 1, 0, 0, 'addphone', 'creates a public phone', '2013-06-29 14:07:57'),
(224, 1, 0, 0, 'nearbyphones', 'shows nearby public phone', '2013-06-29 14:07:57'),
(225, 1, 0, 0, 'delphone', 'deletes a public phone', '2013-06-29 14:07:57'),
(226, 1, 0, 0, 'enableallelevators', 'enables all elevators', '2013-06-29 14:07:57'),
(227, 1, 0, 0, 'addint', 'adds an interior', '2013-06-29 14:07:57'),
(228, 1, 0, 0, 'sellproperty', 'sells an interior', '2013-06-29 14:07:57'),
(229, 1, 0, 0, 'delint', 'deletes an interior', '2013-06-29 14:07:57'),
(230, 1, 0, 0, 'getintid', 'shows the current interior', '2013-06-29 14:07:57'),
(231, 1, 0, 0, 'setintid', 'changes the interior', '2013-06-29 14:07:57'),
(232, 1, 0, 0, 'getintprice', 'shows the interiors price', '2013-06-29 14:07:57'),
(233, 1, 0, 0, 'setintprice', 'changes the interiors price', '2013-06-29 14:07:57'),
(234, 1, 0, 0, 'getinttype', 'shows the interiors type', '2013-06-29 14:07:57'),
(235, 1, 0, 0, 'setinttype', 'changes the interiors type', '2013-06-29 14:07:57'),
(236, 1, 0, 0, 'togint', 'sets the interior enabled or disabled', '2013-06-29 14:07:57'),
(237, 1, 0, 0, 'enableallinteriors', 'enables all the interiors', '2013-06-29 14:07:57'),
(238, 1, 0, 0, 'setintexit', 'changes an interior exit marker', '2013-06-29 14:07:57'),
(239, 1, 0, 0, 'setintentrance', 'changes an interior entrance marker', '2013-06-29 14:07:57'),
(240, 1, 0, 0, 'fsell', 'force-sells an interior', '2013-06-29 14:07:57'),
(241, 1, 0, 0, 'setfactionleader', 'puts a player into a faction and makes the player leader', '2013-06-29 14:07:57'),
(242, 1, 0, 0, 'setfactionrank', 'sets a player to a specific faction rank', '2013-06-29 14:07:57'),
(243, 1, 0, 0, 'makefaction', 'creates a faction', '2013-06-29 14:07:57'),
(244, 1, 0, 0, 'renamefaction', 'renames a faction', '2013-06-29 14:07:57'),
(245, 1, 0, 0, 'setfaction', 'puts an player into a faction', '2013-06-29 14:07:57'),
(246, 1, 0, 0, 'delfaction', 'deletes a faction', '2013-06-29 14:07:57'),
(247, 1, 0, 0, 'addfuelpoint', 'creates a new fuelpoint', '2013-06-29 14:07:57'),
(248, 1, 0, 0, 'nearbyfuelpoints', 'shows nearby fuelpoints', '2013-06-29 14:07:57'),
(249, 1, 0, 0, 'delfuelpoint', 'deletes a fuelpoint', '2013-06-29 14:07:57'),
(250, 1, 0, 0, 'ck', 'permanently kills the character; spawns a corpse at the location the player is at', '2013-06-29 14:07:57'),
(251, 1, 0, 0, 'unck', 'reverts a character kill', '2013-06-29 14:07:57'),
(252, 1, 0, 0, 'makegun', 'gives the player the specified weapon item', '2013-06-29 14:07:57'),
(253, 1, 0, 0, 'makeammo', 'gives the player the specified ammo item', '2013-06-29 14:07:57'),
(254, 1, 0, 0, 'setmoney', 'sets the players money to that value', '2013-06-29 14:07:57'),
(255, 1, 0, 0, 'givemoney', 'gives the player money in addition to his current cash', '2013-06-29 14:07:57'),
(256, 1, 0, 0, 'resetcharacter', 'fully resets the character', '2013-06-29 14:07:57'),
(257, 1, 0, 0, 'setvehlimit', 'Set the players vehicle limit.', '2013-06-29 14:07:57'),
(258, 1, 0, 0, 'adminstats', 'shows admin stats', '2013-06-29 14:07:57'),
(259, 1, 0, 0, 'removeshop', 'Deletes a NPC from SQL.', '2013-06-29 14:07:57'),
(260, 1, 0, 0, 'forcesellinactiveints', 'Force-sells All inactive interiors.', '2013-06-29 14:07:57'),
(261, 1, 0, 0, 'removeinactiveints', 'Removes All inactive interiors completedly and permanently from SQL.', '2013-06-29 14:07:57'),
(262, 1, 0, 0, 'removedeletedints', 'Removes All deleted interiors completedly and permanently from SQL.', '2013-06-29 14:07:57'),
(263, 1, 0, 0, 'removeforsaleints', 'Removes All for-sale interiors completedly and permanently from SQL.', '2013-06-29 14:07:57'),
(264, 1, 0, 0, 'delallitems [Item ID] [Item Value]', 'Deletes all the item instances from everywhere in game.', '2013-06-29 14:07:57'),
(265, 1, 0, 0, 'removeint [ID]', 'Deletes the interior from game and erases all the data from database completely and permanently include NPCs, items, safe and items inside the safe. If the deleted interior is a custom interior, the custom map will be gone forever.', '2013-06-29 14:07:57'),
(266, 1, 0, 0, 'removeveh [ID]', 'Removes the vehicle from game and erases all the data from database completely and permanently include items inside. ', '2013-06-29 14:07:57'),
(267, 1, 0, 0, 'givedonPoints', 'awards a player donPoints', '2013-06-29 14:07:57'),
(268, 1, 0, 0, 'givestattransfer', 'awards a player stat transfers', '2013-06-29 14:07:57'),
(269, 1, 0, 0, 'hideadmin', 'toggles hidden/visible the admin status', '2013-06-29 14:07:57'),
(270, 1, 0, 0, 'ho', 'send global ooc as hidden admin', '2013-06-29 14:07:57'),
(271, 1, 0, 0, 'hw', 'send a pm as hidden admin', '2013-06-29 14:07:57'),
(272, 1, 0, 0, 'makeadmin', 'gives the player an admin rank', '2013-06-29 14:07:57'),
(273, 1, 0, 0, 'setaccountpassword', 'sets player\'s account password', '2013-06-29 14:07:57'),
(274, 1, 0, 0, 'toga', 'Toggles admin chat.', '2013-06-29 14:07:57'),
(275, 1, 0, 0, 'togg', 'Toggles gamemaster chat.', '2013-06-29 14:07:57'),
(276, 1, 0, 0, 'startres', 'starts the resource', '2013-06-29 14:07:57'),
(277, 1, 0, 0, 'stopres', 'stops the resource', '2013-06-29 14:07:57'),
(278, 1, 0, 0, 'restartres', 'restarts the resource', '2013-06-29 14:07:57'),
(279, 1, 0, 0, 'rescheck', 'checks for ceatain down resources and startes them', '2013-06-29 14:07:57'),
(280, 1, 0, 0, 'rcs', 'check if the resource \"Resource-Keeper\" is running', '2013-06-29 14:07:57'),
(281, 1, 0, 0, 'generatecode', 'generates a donation code', '2013-06-29 14:03:22'),
(282, 1, 0, 0, 'setdamageproof', 'makes a vehicle damageproof', '2013-06-29 14:07:57'),
(283, 0, 0, 0, 'delitemsfromint', 'Deletes all the items within a specified interior that older than an interval of item\'s day old.', '2013-06-29 14:07:57'),
(285, 1, 0, 0, 'aordersupplies', 'Orders supplies from RS Haul for the current interior without yourself being charged.', '2013-06-29 14:10:19'),
(286, 1, 0, 0, 'setjoblevel', 'Sets player\'s city hall job\'s level and progress', '2013-06-29 14:07:57'),
(287, 1, 0, 0, 'respawntrucks', 'Respawns all unoccupied Delivery Trucks', '2013-06-29 14:10:19'),
(288, 1, 0, 0, 'checkactiveroutes', 'Shows all Delivery Job\'s routes that has player working on', '2013-06-29 14:07:57'),
(289, 1, 0, 0, 'fetchactualorders', 'Fetches player\'s Supplies Orders from SQL to game manually (Normally it\'s auto-fetched every 10 minutes)', '2013-06-29 14:07:57'),
(290, 1, 0, 0, 'addactualorder', 'Creates a marker for Delivery Job, it looks exactly the same as actual order from other player.', '2013-06-29 14:07:57'),
(291, 1, 0, 0, 'addtruckerjobmarker', 'Creates a generic drop-off marker for Delivery Driver job.', '2013-06-29 14:07:57'),
(292, 1, 0, 0, 'showactualorders', 'Shows Delivery Job\'s actual supply orders from players.', '2013-06-29 14:07:57'),
(293, 1, 0, 0, 'showalltruckmarkers', 'Shows all Delivery Job drop-off markers (both generic markers and actual order markers)', '2013-06-29 14:07:57'),
(294, 1, 0, 0, 'skiproute', 'Skips Delivery Job\'s current route, jump instantly to next spot (Useful when creating job markers)', '2013-06-29 14:07:57'),
(295, 1, 0, 0, 'resetaccount', 'Reset one character or all characters within an account.', '2013-06-29 14:07:57'),
(296, 1, 0, 0, 'deltruckmarker', 'Deletes a Delivery Job\'s marker', '2013-06-29 14:07:57'),
(297, 1, 0, 0, 'aheal', 'Gives yourself full HP, or /aheal [ID] to give it someone else', '2013-06-29 14:10:19'),
(298, 2, 0, 0, 'showadminreports', 'Subscribes to admin reports.', '2013-06-29 14:10:19'),
(300, 2, 0, 0, 'ads', 'Shows all pending adverts.', '2013-06-29 14:10:19'),
(301, 2, 0, 0, 'freezead', 'Freeze an advert.', '2013-06-29 14:10:19'),
(302, 2, 0, 0, 'unfreezead', 'Unfreeze an advert', '2013-06-29 14:10:19'),
(303, 2, 0, 0, 'deletead', 'Delete an advert', '2013-06-29 14:10:19'),
(304, 2, 0, 0, 'gmlounge', 'Teleports you to the GM lounge.', '2013-06-29 14:10:19'),
(305, 2, 0, 0, 'g [Text]', 'Talk in GM chat for communication with admins.', '2013-06-29 14:10:19'),
(306, 2, 0, 0, 'ar', 'Accept a report.', '2013-06-29 14:10:19'),
(307, 2, 0, 0, 'cr', 'Close a report.', '2013-06-29 14:10:19'),
(308, 2, 0, 0, 'dr', 'Drop a report, leaving it unanswered.', '2013-06-29 14:10:19'),
(309, 2, 0, 0, 'fr', 'Mark a report false', '2013-06-29 14:10:19'),
(310, 2, 0, 0, 'ur', 'Shows all unanswered reports.', '2013-06-29 14:10:19'),
(311, 2, 0, 0, 'gmduty', 'Toggles GM duty (On/off)', '2013-06-29 14:10:19'),
(312, 2, 0, 0, 'goto', 'Teleport to a player\'s location.', '2013-06-29 14:10:19'),
(313, 2, 0, 0, 'gotoplace', 'Teleport to a pre-determined place.', '2013-06-29 14:10:19'),
(314, 2, 0, 0, 'mark', 'Create a mark for you to teleport to (doing /mark without a name will create a temporary one)', '2013-06-29 14:10:19'),
(315, 2, 0, 0, 'togautocheck', 'Toogles auto opening player /check on /ar reports.', '2013-06-29 14:10:19'),
(316, 2, 0, 0, 'gotomark', 'Teleport to a pre-made mark (/gotomark without a mark name teleports to a temporary one)', '2013-06-29 14:10:19'),
(317, 2, 0, 0, 'setjob', 'Sets player job.', '2013-06-29 14:10:19'),
(318, 2, 0, 0, 'deljob', 'Deletes player job', '2013-06-29 14:10:19'),
(319, 2, 0, 0, 'freeze', 'Freeze a player.', '2013-06-29 14:07:57'),
(320, 2, 0, 0, 'unfreeze', 'Unfreeze a frozen player.', '2013-06-29 14:07:57'),
(321, 2, 0, 0, 'gethere', 'Teleports a player to your location.', '2013-06-29 14:07:57'),
(322, 2, 0, 0, 'togpm', 'Disables your pm\'s.', '2013-06-29 14:07:57'),
(332, 2, 0, 0, 'makeadmin', 'gives the player an gm rank', '2013-06-29 14:07:57'),
(335, 1, 0, 0, 'forceapp', 'Force player that doesn\'t meet server standards -and- not willing to improve out of game.', '2013-06-29 14:10:19'),
(336, 2, 0, 0, 'forceapp', 'Force player that doesn\'t meet server standards -and- not willing to improve out of game.', '2013-06-29 14:07:57'),
(337, 2, 0, 0, 'check', 'Display details information of a player', '2013-06-29 14:10:19'),
(338, 1, 0, 0, 'checkinteriors', 'To check for custom int requests', '2013-06-29 14:07:57'),
(339, 1, 0, 0, 'testinterior', 'Test the custom interior', '2013-06-29 14:07:57'),
(340, 1, 0, 0, 'Savetestinterior', 'Save the tested interior', '2013-06-29 14:07:57'),
(341, 1, 0, 0, 'deltestinterior', 'Deletes the tested interior', '2013-06-29 14:07:57'),
(342, 1, 0, 0, 'renameshop', 'or /renameped or /renamenpc, it renames NPCs in format of \'First Lastname\'', '2013-06-29 14:10:19'),
(343, 2, 0, 0, 'renameshop', 'or /renameped or /renamenpc, it renames NPCs in format of \'First Lastname\'', '2013-06-29 14:10:19'),
(344, 2, 0, 0, 'nearbyshops', 'Gets near by NPC\'s info', '2013-06-29 14:10:19'),
(345, 1, 0, 0, 'togoverlay', 'Toggles overlay menus on top or buttom of screen. If it\'s disabled, the content will be all printed to chatbox.', '2013-06-29 14:10:19'),
(346, 2, 0, 0, 'togoverlay', 'Toggles overlay menus on top or buttom of screen. If it\'s disabled, the content will be all printed to chatbox.', '2013-06-29 14:10:19'),
(347, 1, 0, 0, 'iastats', 'Returns reports done and hours played for specified user. Makes inputting to IA website easier.', '2013-06-29 14:07:57'),
(348, 1, 0, 0, '\'F5\'', 'Toggles Report Panel', '2013-06-29 14:10:19'),
(349, 2, 0, 0, '\'F5\'', 'Toggles Report Panel', '2013-06-29 14:10:19'),
(350, 1, 0, 0, 'settrackingloc', 'Use this command to define where the tracking device in the vehicle is installed.', '2013-06-29 14:10:19'),
(351, 3, 0, 0, 'settrackingloc', 'Use this command to define where the tracking device in the vehicle is installed.', '2013-06-29 14:10:19'),
(352, 1, 0, 0, 'gettrackingloc', 'Use this command to check where a tracking device has been installed.', '2013-06-29 14:10:19'),
(353, 1, 0, 0, 'infract', 'Gives an infraction to an administrator.', '2013-06-29 14:07:57'),
(354, 1, 0, 0, 'iahistory', 'View an administrators IA history.', '2013-06-29 14:07:57'),
(355, 1, 0, 0, 'Double right click an IA history entry', 'Removes an IA history entry.', '2013-06-29 14:10:19'),
(356, 1, 0, 0, 'awarn', 'Gives an warning to an administrator.', '2013-06-29 14:07:57'),
(357, 1, 0, 0, 'suspend [player] [hours]', 'Use this command to suspend an administrator.', '2013-06-29 14:07:57'),
(358, 1, 0, 0, 'hashtransactionid', 'Hashes a transaction ID from PayPal into the proper format for donation key.', '2013-06-29 14:07:57'),
(359, 1, 0, 0, 'unsuspend', 'Unsuspends an administrator.', '2013-06-29 14:07:57'),
(360, 2, 0, 0, 'respawnveh', '/respawnveh [Vehicle ID] - To respawn a vehicle', '2013-06-29 14:07:57'),
(361, 1, 1, 0, '/check', 'Checks a players information', '2013-07-04 22:49:57'),
(362, 1, 1, 0, '/gethere', 'Teleports a player to you.', '2013-07-04 22:50:33'),
(363, 1, 1, 0, '/goto', 'Teleports you to a player', '2013-07-04 22:50:43'),
(364, 1, 1, 0, '/adminduty', 'Places you on/off Admin duty', '2013-07-04 22:52:24'),
(365, 1, 1, 0, '/warn', 'Warns a player (3 warns = perm ban)', '2013-07-04 22:52:39'),
(366, 1, 1, 0, '/jail', 'Jails a naughty player', '2013-07-04 22:52:58'),
(367, 1, 1, 0, '/sjail', 'Silently jails a player', '2013-07-04 22:53:53'),
(368, 1, 1, 0, '/ojail', 'Offline jails a player', '2013-07-04 22:54:11'),
(369, 1, 1, 0, '/sojail', 'Silently Offline jails a player', '2013-07-04 22:54:36'),
(370, 1, 1, 0, '/unjail', 'Unjails a player from admin jail.', '2013-07-04 22:54:53'),
(371, 1, 1, 0, '/sban [Player Partial Nick / ID] [Time in Hours, 0 = Infinite] [Reason]', 'Silently bans a player', '2013-07-04 22:59:25'),
(372, 1, 1, 0, '/soban', 'Silently offline bans a player', '2013-07-04 22:57:26'),
(373, 1, 1, 0, '/Trace', 'traces a phone number and tells you who owns it. Player must be online.', '2013-07-04 22:57:26'),
(374, 1, 1, 0, '/oban [Player Partial Nick / ID] [Time in Hours (0 = Perma)] [Reason]', 'Offline Bans a player', '2013-07-04 23:00:24'),
(375, 1, 1, 0, '/getkey', 'Spawns yourself a key of interior or vehicle that you\'re currently in.', '2013-07-04 22:57:47'),
(376, 1, 1, 0, '/cr [Report ID]', 'without specified ID will closes all your own accepted reports.', '2013-07-04 23:00:03'),
(377, 1, 1, 0, '/createemitter [Emitter Type]', 'Spawns Synced Fire/Water Emitters', '2013-07-04 22:58:32'),
(378, 1, 1, 0, '/history [Partial Player Nick / ID]', 'Checks a players admin history', '2013-07-04 22:59:53'),
(379, 1, 3, 0, '/makeveh', 'Makes a permanent vehicle.', '2013-07-04 22:59:32'),
(380, 1, 3, 0, '/makecivveh', 'Makes a civillian vehicle.', '2013-07-04 23:13:24'),
(381, 1, 1, 0, '/respawnall', 'Respawns all vehicles in the server (/respawnall', '2013-07-04 23:01:48'),
(382, 1, 1, 0, '/respawnciv', 'Respawns all civilian vehicles in the server (/respawnciv)', '2013-07-04 23:01:39'),
(383, 1, 1, 0, '/superman', 'Makes you superman! ', '2013-07-05 19:30:51'),
(384, 1, 5, 0, '/iahistory', 'Checks a administrators IA history', '2013-07-04 23:03:01'),
(385, 1, 5, 0, '/makeadmin ', 'Sets a players admin level ', '2013-07-04 23:03:27'),
(386, 1, 2, 0, '/delsupercar', 'deletes the supercar you\'re in, given that it meets the criteria for deletion.', '2013-07-04 23:03:41'),
(387, 1, 5, 0, '/generatecode', 'Generates a donation code', '2013-07-04 23:03:53'),
(388, 1, 2, 0, '/setbiznote [Message]', 'Sets business greeting/notification message.', '2013-07-04 23:03:58'),
(389, 1, 2, 0, '/delitemsfromint [Int ID] [Day old of Items]', 'Deletes all the items within a specified interior that older than an interval of item\'s day old.', '2013-07-04 23:04:14'),
(390, 1, 2, 0, '/ints or /interiors', 'Opens Interior Manager.', '2013-07-04 23:04:30'),
(391, 1, 2, 0, '/delint', 'Deletes the interior from game and disables it from loading in next server/resource restarts.', '2013-07-04 23:04:40'),
(392, 1, 2, 0, '/delthisint or /delthisinterior', 'Deletes the interior you\'re currently in it from game and disables it from loading in next server/resource restarts.', '2013-07-04 23:04:56'),
(393, 1, 2, 0, '/restoreint', 'Restores a deleted interior included safe, items and NPCs inside it.', '2013-07-04 23:05:12'),
(394, 1, 2, 0, '/gotohouse', 'teleports to the house', '2013-07-04 23:05:26'),
(395, 1, 2, 0, '/gotoint', 'teleports to the interior', '2013-07-04 23:05:38'),
(396, 1, 2, 0, '/gotointi', 'teleports inside of an interior', '2013-07-04 23:05:52'),
(397, 1, 2, 0, '/veh', 'spawns a temporary vehicle', '2013-07-04 23:06:03'),
(398, 1, 1, 0, '/nearbyvehicles', 'Gets nearbyvehicles ID - MODEL - OWNER', '2013-07-04 23:06:29'),
(399, 1, 1, 0, '/nearbyitems', 'Gets nearby items', '2013-07-04 23:07:14'),
(400, 1, 1, 0, '/entercar', 'Enters you into a vehicles seat. 0 - Driver', '2013-07-04 23:07:50'),
(401, 1, 1, 0, '/ann', 'Makes an admin announcement to the server', '2013-07-04 23:12:46'),
(402, 1, 1, 0, '/fuelveh ', 'Fuels a players vehicle', '2013-07-04 23:17:38'),
(403, 1, 1, 0, '/fuelvehs', 'Fuels all the vehicles in the server', '2013-07-04 23:18:00'),
(404, 1, 1, 0, '/fixveh', 'Fixes a players vehicle', '2013-07-04 23:18:20'),
(405, 1, 1, 0, '/fixvehs', 'Fixes all the vehicles in the server.', '2013-07-04 23:18:29'),
(407, 1, 1, 0, '/checkveh', 'Checks a vehicles note', '2013-07-04 23:29:34'),
(408, 1, 1, 0, '/checkint', 'Checks the interiors note.', '2013-07-04 23:29:42'),
(409, 1, 5, 0, '/loginto', 'Logs into a players character', '2013-07-04 23:30:19'),
(410, 1, 4, 0, '/bigears', 'Listens to a players PM\'s', '2013-07-04 23:42:16'),
(411, 1, 4, 0, '/bigearsf', 'Listens to a faction\'s OOC /f chat', '2013-07-04 23:42:32'),
(412, 1, 4, 0, '/resetaccount', 'Resets the entire account of a player', '2013-07-04 23:42:53'),
(413, 1, 4, 0, '/resetcharacter', 'Resets a players character', '2013-07-04 23:44:09'),
(414, 1, 4, 0, '/adminstats', 'Checks the admin statistics', '2013-07-04 23:45:43'),
(415, 1, 2, 0, '/addinterior', 'Creates an interior', '2013-07-04 23:57:02'),
(416, 1, 2, 0, '/setinteriorid', 'Sets the interiors ID', '2013-07-04 23:57:22'),
(417, 1, 2, 0, '/setinteriorprice', 'Sets the interiors price.', '2013-07-04 23:57:33'),
(418, 1, 5, 0, '/hideadmin', 'Appears hidden on /admin list.', '2013-07-05 00:10:02'),
(419, 1, 5, 0, '/ho', 'Sends a hidden announcement.', '2013-07-05 00:10:13'),
(420, 1, 1, 0, '/sdt', 'Sets a vehicle\'s drive terrain', '2013-07-05 11:31:47'),
(421, 1, 1, 0, '/sll', 'Sets a vehicle\'s height', '2013-07-05 11:32:09'),
(422, 1, 1, 0, '/adminlounge', 'Teleports you to the administration lounge', '2013-07-05 11:32:29'),
(423, 1, 1, 0, '/stopradiodistrict', 'Turns the radio off for all cars in a district.', '2013-07-05 11:33:13'),
(424, 1, 1, 0, '/findserial', 'Finds a players MTA Serial', '2013-07-05 11:33:27'),
(425, 1, 1, 0, '/findip ', 'Finds a players IP', '2013-07-05 11:33:36'),
(426, 1, 1, 0, '/findalts', 'Finds all charracters of a players account', '2013-07-05 11:33:54'),
(427, 1, 1, 0, '/restartcarshops', 'Resets the vehicles at the carshops', '2013-08-18 19:08:15'),
(428, 1, 1, 0, '/listcarprices', 'Lists all the vehicles spawned at the dealerships', '2013-07-05 11:37:32'),
(429, 1, 1, 0, '/makeshop', 'Creates an NPC', '2013-07-05 11:38:06'),
(430, 1, 1, 0, '/restartparachute', 'Restarts the parachute resource.', '2013-07-05 11:44:06'),
(431, 1, 3, 0, '/setpaintjob', 'Sets a vehicles paintjob', '2013-07-05 11:47:12'),
(432, 1, 3, 0, '/setvehtint', 'Sets a vehicles tint', '2013-07-05 11:47:21'),
(433, 1, 5, 0, '/hw', 'Sends a hidden admin PM', '2013-07-05 17:45:43'),
(434, 1, 1, 0, '/slap', 'Slaps a player', '2013-07-05 11:53:08'),
(435, 1, 1, 0, '/sethp', 'Sets a players HP', '2013-07-05 11:53:17'),
(436, 1, 1, 0, '/setcarhp', 'Sets a vehicle HP', '2013-07-05 11:53:30'),
(437, 1, 1, 0, '/aheal', 'Heals a player', '2013-07-05 11:53:39'),
(438, 1, 1, 0, '/togooc', 'Toggles the global OOC Chat', '2013-07-05 11:54:38'),
(439, 1, 1, 0, '/stogooc', 'Silently toggles the global OOC Chat', '2013-07-05 11:54:48'),
(440, 1, 1, 0, '/freconnect', 'Force reconnects a player', '2013-07-05 11:56:40'),
(441, 1, 1, 0, '/pkick', 'Kicks a player from the server', '2013-07-05 11:56:52'),
(442, 1, 1, 0, '/skick', 'Kicks a player from the server silently', '2013-07-05 11:57:00'),
(443, 1, 1, 0, '/delshop', 'Removes a NPC Shop', '2013-07-05 12:07:08'),
(444, 1, 4, 0, '/makepaynspray', 'Creates a pay n spray', '2013-07-05 12:07:54'),
(445, 1, 4, 0, '/delpaynspray', 'Deletes a pay n spray', '2013-07-05 12:08:08'),
(446, 1, 4, 0, '/addspeedcam', 'Creates a speedcam', '2013-07-05 12:08:26'),
(447, 1, 1, 0, '/togoverlay', 'Moves the GUI of /admins to your chatbox', '2013-07-05 12:10:59'),
(448, 1, 1, 0, '/changewarnstyle', 'Moves the warning style to your chatbox or right side of the screen', '2013-07-05 12:11:27'),
(449, 1, 1, 0, '/getpos', 'Gets your position', '2013-07-05 12:14:35'),
(452, 1, 1, 0, '/itemprotect', 'Sets locked world item pickable by..', '2013-07-05 12:15:33'),
(453, 1, 1, 0, '/ads', 'Shows all pending adverts.', '2013-07-05 12:15:57'),
(454, 1, 1, 0, '/delad', 'Deletes an advert', '2013-07-05 12:16:17'),
(455, 1, 1, 0, '/freezead', 'Freezes an advert', '2013-07-05 12:16:31'),
(456, 1, 1, 0, '/unfreezead', 'Unfreezes an advert', '2013-07-05 12:16:42'),
(457, 1, 1, 0, '/agivelicense', 'Gives a player a license', '2013-07-05 12:16:58'),
(458, 1, 1, 0, '/mark', 'Marks a position ', '2013-07-05 12:17:36'),
(459, 1, 1, 0, '/gotomark', 'TP\'s you to that mark', '2013-07-05 12:17:52'),
(460, 1, 1, 0, '/amotd', 'Displays the admin message of the day', '2013-07-05 12:18:10'),
(461, 1, 1, 0, '/setamotd', 'Sets the admin message of the day', '2013-07-05 12:18:20'),
(462, 1, 1, 0, '/setmotd', 'Sets the message of the day', '2013-07-05 12:18:37'),
(463, 1, 1, 0, '/disappear', 'Turns you invisible', '2013-07-05 12:19:28'),
(464, 1, 1, 0, '/jailed', 'Shows all players in admin & PD Jail', '2013-07-05 12:19:47'),
(465, 1, 1, 0, '/unjail', 'Releases a player from admin jail.', '2013-07-05 12:19:56'),
(466, 1, 1, 0, '/changename', 'Changes the name of a character.', '2013-07-05 12:20:18'),
(467, 1, 1, 0, '/bury', 'Removes a CK\'ed body', '2013-07-05 12:20:35'),
(468, 1, 1, 0, '/gotoplace', 'Teleports you to several marked places.', '2013-07-05 12:20:54'),
(469, 1, 1, 0, '/freeze', 'Freezes a player', '2013-07-05 12:21:09'),
(470, 1, 1, 0, '/unfreeze', 'unfreezes a player', '2013-07-05 12:21:23'),
(471, 1, 1, 0, '/stats', 'Checks a players stats.', '2013-07-05 12:22:01'),
(472, 1, 1, 0, '/auncuff', 'Uncuffs a player', '2013-07-05 12:22:28'),
(473, 1, 1, 0, '/spinout', 'Spins a players vehicle out.', '2013-07-05 12:42:06'),
(474, 1, 1, 0, '/recon', 'Recons a player', '2013-07-05 13:12:04'),
(475, 1, 1, 0, '/fuckrecon', 'Stops reconning a player', '2013-07-05 13:12:20'),
(476, 1, 2, 0, '/forcesell', 'Force sells an inactive interior', '2013-07-05 13:28:11'),
(477, 1, 3, 0, '/setvarient', 'Sets different varibles for a vehicle', '2013-07-05 13:46:14'),
(479, 1, 1, 0, '/setcolor', 'Sets the vehicles color', '2013-07-05 13:46:40'),
(480, 1, 1, 0, '/getcolor', 'Gets the vehicles color', '2013-07-05 13:46:49'),
(481, 1, 5, 0, '/restartres', 'Restarts a resource', '2013-07-05 13:58:01'),
(482, 1, 5, 0, '/rescheck', 'Runs the resource checker', '2013-07-05 13:58:17'),
(483, 1, 1, 0, '/itemlist', 'Displays all items.', '2013-07-05 14:01:44'),
(484, 1, 1, 0, '/delnearbyitems', 'Deletes all the items near you.', '2013-07-05 14:02:17'),
(485, 1, 1, 0, '/delitem', '/delitem <ID> ', '2013-07-05 14:02:34'),
(486, 1, 1, 0, '/showfactions', 'Displays a list of all factions.', '2013-07-05 14:03:26'),
(487, 1, 1, 0, '/respawnfaction', 'Respawns all vehicles for that faction.', '2013-07-05 14:03:45'),
(488, 1, 1, 0, '/blowveh', 'Blows the players vehicle up.', '2013-07-05 14:04:19'),
(489, 1, 1, 0, '/setheight', 'Sets a players character height', '2013-07-05 14:04:36'),
(490, 1, 1, 0, '/setrace', 'Sets a players character race', '2013-07-05 14:04:48'),
(491, 1, 1, 0, '/setage', 'Sets a players character age', '2013-07-05 14:04:55'),
(492, 1, 4, 0, '/gunmaker or \"F4\"', 'Displays the weapon creator', '2013-07-05 14:05:39'),
(493, 1, 1, 0, '/freecam', 'Sets you to freecam mode.', '2013-07-05 14:05:56'),
(494, 1, 1, 0, '/dropme', 'Drops you where you freecam', '2013-07-05 14:06:06'),
(495, 1, 1, 0, 'Hold P and click', 'Locks a world item. Make it unpickable', '2013-07-05 14:06:38'),
(496, 1, 1, 0, '/unban', 'Unbans a player', '2013-07-05 14:07:13'),
(497, 1, 1, 0, '/unbanserial', 'Unbans a players serial', '2013-07-05 14:07:21'),
(498, 1, 1, 0, '/unbanip', 'Unbans a players IP', '2013-07-05 14:07:28'),
(499, 1, 1, 0, '/ar', 'Accepts a report', '2013-07-05 14:07:57'),
(500, 1, 1, 0, '/cr', 'Closes a report', '2013-07-05 14:08:04'),
(501, 1, 1, 0, '/fr', 'Falses a report', '2013-07-05 14:08:12'),
(502, 1, 4, 0, '/hashtransactionid', 'Hashes a transaction IDI', '2013-07-05 14:09:18'),
(503, 1, 1, 0, '/giveitem', 'Gives a player an item.', '2013-07-05 14:09:42'),
(504, 1, 1, 0, '/takeitem', 'Takes a item from a players inventory', '2013-07-05 14:09:53'),
(505, 1, 1, 0, '/setskin ', 'Sets a players skin.', '2013-07-05 14:10:06'),
(506, 1, 1, 0, '/setarmor', 'Sets a players armor.', '2013-07-05 14:10:25'),
(507, 1, 1, 0, '/disarm', 'Disarms a player.', '2013-07-05 14:10:36'),
(508, 1, 1, 0, '/sendto', 'Sends a player to another player', '2013-07-05 14:12:51'),
(509, 1, 1, 0, '/showinv', 'Shows the inventory of a player.', '2013-07-05 14:13:24'),
(510, 1, 2, 0, '/restoreveh', 'Restores a deleted vehicle.', '2013-07-05 14:15:36'),
(511, 1, 1, 0, '/addelevator', 'Adds a elevator from A to B', '2013-07-05 14:21:18'),
(512, 1, 1, 0, '/restartgatekeepers', 'Restarts the gatekeepers resource', '2013-07-05 14:17:30'),
(513, 1, 1, 0, '/changelock', 'Deletes all old keys and gives you a new one', '2013-07-05 14:17:53'),
(514, 1, 2, 0, '/createemitter', 'Creates a fire/water emitter', '2013-07-05 14:25:41'),
(515, 1, 4, 0, '/delspeedcam', 'Deletes a speedcam', '2013-07-05 14:30:08'),
(516, 1, 1, 0, '/delallrbs', 'Deletes all roadblocks in the server', '2013-07-05 14:30:52'),
(517, 1, 1, 0, '/aremovespikes', 'Deletes all roadspikes in the server.', '2013-07-05 14:31:03'),
(518, 1, 1, 0, '/reloadint', 'Reloads a bugged interior.', '2013-07-05 14:31:34'),
(519, 1, 1, 0, '/respawndistrict', 'Respawns the vehicles in a district', '2013-07-05 14:33:02'),
(520, 1, 1, 0, '/unflip', 'Unflips a players vehicle', '2013-07-05 14:33:24'),
(521, 1, 1, 0, '/issuepc', 'Issues a pilot certificate to a player.', '2013-07-05 14:34:11'),
(522, 1, 1, 0, '/setjob', 'Sets a players job', '2013-07-05 14:34:38'),
(523, 1, 1, 0, '/deljob', 'Deletes a players job', '2013-07-05 14:34:53'),
(524, 1, 1, 0, '/setlanguage', 'Sets a players language', '2013-07-05 14:35:16'),
(525, 1, 1, 0, '/aunblindfold', 'Unblindfolds a player', '2013-07-05 14:35:51'),
(526, 1, 1, 0, '/pmute', 'Mutes a player from OOC Chat.', '2013-07-05 14:36:42'),
(527, 1, 4, 0, '/l ', 'Lead Admin Chat', '2013-07-05 14:37:16'),
(528, 1, 5, 0, '/h', 'Head Admin Chat', '2013-07-05 14:37:24'),
(529, 1, 1, 0, '/ur', 'Displays unawnsered reports.', '2013-07-05 14:37:58'),
(530, 1, 2, 0, '/togint', 'Toggles the interior to disabled', '2013-07-08 16:06:04'),
(532, 1, 1, 0, '/togautocheck', 'Toggles the /check to appear upon accepting a report.', '2013-07-05 15:06:15'),
(533, 1, 2, 0, '/restoreint', 'Restores a deleted interior', '2013-07-05 15:14:52'),
(534, 1, 1, 0, '/aordersupplies', 'Orders supplies to a shop', '2013-07-05 15:19:47'),
(535, 1, 1, 0, '/cleannearbytag', 'Cleans a nearby spray tag', '2013-07-05 16:21:19'),
(536, 1, 1, 0, '/nearbytags', 'Shows all nearby tags.', '2013-07-05 16:25:34'),
(537, 1, 1, 0, '/findveh', 'retrieves the model for that vehicle name', '2013-07-05 16:29:05'),
(538, 1, 1, 0, '/unlockcivcars', 'unlocks all civilian vehicles', '2013-07-05 16:33:50'),
(541, 1, 1, 0, '/restoreshop', '\"Restores a deleted NPC from SQL.', '2013-07-05 16:38:54'),
(542, 1, 1, 0, '/fixvehvis [Driver\'s partial Name/ID]', '\"Fixes player\'s car\'s visual, leave the engine\'s health.', '2013-07-05 16:41:18'),
(543, 1, 5, 0, '/givestattransfer', 'Gives a player a stat transfer.', '2013-07-05 16:47:23'),
(544, 1, 5, 0, '/givedontpoints', 'Gives a player donator points ', '2013-07-05 16:49:03'),
(546, 1, 1, 0, '/restock', 'Restocks businesses, you must be inside an interior to restock. Or use SYNTAX: /restock [Interior ID] [Amount 1~300]', '2013-07-05 16:58:05'),
(548, 1, 2, 0, '/nearbyemitters', 'Shows all nearby Fire/Water emitters.', '2013-07-05 17:08:38'),
(549, 1, 2, 0, '/delemitters', 'Deletes all nearby Fire/Water emitters.', '2013-07-05 17:09:10'),
(550, 1, 1, 0, '/delnearbyshops', 'Deletes nearby shops.', '2013-07-05 17:09:53'),
(551, 1, 4, 0, '/forcepayday', 'Forces a player to get payday.', '2013-07-05 17:15:57'),
(552, 1, 4, 0, '/forcepaydayall', 'Forces all players to get paydays.', '2013-07-05 17:18:05'),
(553, 1, 4, 0, '/givesuperman', 'Gives player temporary ability to fly. Execute the cmd again to revoke the ability. Ability will be automatically gone after player relogs.', '2013-07-05 17:18:55'),
(554, 1, 4, 0, '/addatm', 'adds an ATM at this spot', '2013-07-05 17:19:17'),
(555, 1, 4, 0, '/delatm', 'Deletes an ATM with that id.', '2013-07-05 17:19:29'),
(556, 1, 1, 0, '/nearbyatms', 'shows the nearby ATMs', '2013-07-05 17:19:56'),
(557, 1, 4, 0, '/setfactionleader', 'puts a player into a faction and makes the player leader', '2013-07-05 17:22:07'),
(558, 1, 4, 0, '/setfactionrank', 'Sets the players faction rank.', '2013-07-05 17:22:25'),
(559, 1, 4, 0, '/makefaction', 'Creates a faction.', '2013-07-05 17:22:53'),
(560, 1, 4, 0, '/renamefaction', 'Renames a faction.', '2013-07-05 17:23:12'),
(561, 1, 4, 0, '/delfaction', 'Deletes a faction.', '2013-07-05 17:23:33'),
(562, 1, 4, 0, '/ck', 'permanently kills the character; spawns a corpse at the location the player is a', '2013-07-05 17:24:47'),
(563, 1, 4, 0, '/unck', 'reverts a character kill', '2013-07-05 17:25:17'),
(564, 1, 4, 0, '/givemoney', 'gives the player money in addition to his current cash', '2013-07-05 17:25:46'),
(566, 1, 5, 0, '/forcesellinactiveints', 'Force-sells All inactive interiors.', '2013-07-05 17:40:22'),
(567, 1, 5, 0, '/delallitems [Item ID] [Item Value]', 'Deletes all the item instances from everywhere in game.', '2013-07-05 17:40:47'),
(568, 1, 5, 0, '/setdamageproof', 'makes a vehicle damageproof', '2013-07-05 17:41:30');
INSERT INTO `commands_library` (`cmID`, `cmType`, `cmLevel`, `cmSubType`, `cmName`, `cmExplanation`, `cmCreationDate`) VALUES
(569, 1, 5, 0, '/rcs', 'check if the resource \"Resource-Keeper\" is running', '2013-07-05 17:41:49'),
(570, 1, 5, 0, '/stopres', 'Stops the resource', '2013-07-05 17:42:34'),
(571, 1, 5, 0, '/togg', 'Toggles gamemaster chat.', '2013-07-05 17:44:02'),
(572, 1, 5, 0, '/toga', 'Toggles administrator chat.', '2013-07-05 17:44:19'),
(574, 1, 5, 0, '/setaccountpassword', 'sets player\'s account password', '2013-07-05 17:44:36'),
(575, 1, 5, 0, '/removeveh [ID]', 'Removes the vehicle from game and erases all the data from database completely and permanently include items inside.', '2013-07-05 17:46:52'),
(576, 1, 4, 0, '/setmoney', 'Sets a players on hand money', '2013-07-05 18:26:14'),
(577, 1, 5, 0, '/removeint [ID]', 'Deletes the interior from game and erases all the data from database completely and permanently include NPCs, items, safe and items inside the safe. If the deleted interior is a custom interior, the custom map will be gone forever.', '2013-07-05 19:25:00'),
(578, 1, 1, 0, '/srd', 'Turns off all vehicle radios in a district', '2013-07-05 19:48:52'),
(580, 1, 1, 0, '/ah', 'Displays the index of admin commands', '2013-07-05 21:02:50'),
(581, 1, 4, 0, '/setfactiontype', 'Sets the type of a faction', '2013-07-05 21:09:01'),
(582, 1, 1, 0, '/setfaction', 'Sets you to a faction', '2013-07-06 14:36:04'),
(583, 1, 3, 0, '/setvehiclefaction', 'Sets a specific vehicle to a faction ', '2013-07-06 14:37:06'),
(584, 1, 3, 0, '/setvehicleplate', 'Sets a vehicle\'s plate', '2013-07-06 14:55:06'),
(585, 1, 4, 0, '/renamefaction', 'Changes the name of a faction', '2013-07-06 14:55:36'),
(586, 1, 4, 0, '/nearbyatms', 'Shows all nearby ATM\'s', '2013-07-06 15:53:38'),
(587, 1, 4, 0, '/nearbypaynsprays', 'Shows all nearby pay n sprays', '2013-07-06 15:54:09'),
(588, 1, 5, 0, '/delitemsfromint', 'Deletes all the items within a specified interior or world map that older than an interval of item\'s day old.', '2013-07-06 16:19:25'),
(589, 1, 4, 0, '/sw', 'Sets the weather.', '2013-07-06 20:43:46'),
(590, 1, 1, 0, '/srl', 'Sets the rain level.', '2013-07-06 20:44:13'),
(591, 1, 4, 0, '/etanow ', 'Sets the weather', '2013-07-06 22:45:15'),
(592, 1, 3, 0, '/aunimpound', 'Unimpounds a vehicle admin wise', '2013-07-07 05:34:41'),
(593, 1, 5, 0, '/delallitems', 'Deletes all the item instances from everywhere in game.', '2013-07-07 06:00:27'),
(594, 1, 5, 0, '/removeshop', 'Removes a shop from the datebase', '2013-07-07 16:18:37'),
(595, 1, 1, 0, '/vehpost', 'Creates an automatic forum post for vehicle thefts', '2013-07-08 15:55:01'),
(596, 1, 1, 0, '/intpost', 'Creates an automatic forum post for interior thefts.', '2013-07-08 15:59:14'),
(597, 1, 1, 0, '/forceapp', 'Sends a player back to the application stage.', '2013-07-09 18:42:10'),
(598, 1, 4, 0, '/setfactionmoney', 'Sets the faction bank money', '2013-07-11 07:35:34'),
(602, 2, 1, 0, '/gethere ', 'Teleports a player to you.', '2013-07-15 23:52:36'),
(603, 2, 1, 0, '/goto', 'Teleports you to a player.', '2013-07-15 23:52:52'),
(604, 2, 1, 0, '/forceapp', 'Sends a player to the application stage.', '2013-07-15 23:53:45'),
(605, 2, 5, 0, '/makeadmin', 'Set\'s a players Gamemaster rank.', '2013-07-15 23:54:05'),
(606, 2, 1, 0, '/gotoplace', 'Teleports you to a premade mark.', '2013-07-16 16:24:18'),
(607, 2, 1, 0, '/check', 'Shows you a players /check.', '2013-07-16 16:24:29'),
(608, 1, 4, 0, '/marry', 'Marrys two players', '2013-07-16 16:25:38'),
(609, 1, 4, 0, '/divorce', 'Divorces a married couple.', '2013-07-16 16:25:49'),
(611, 2, 1, 0, '/gh', 'Gamemaster Help', '2013-07-17 16:09:37'),
(612, 2, 1, 0, '/mark', 'Marks a specific point.', '2013-07-17 16:09:46'),
(613, 2, 1, 0, '/gotomark', 'Teleports you to that mark', '2013-07-17 16:10:04'),
(614, 2, 1, 0, '/delmark', 'Deletes a mark.', '2013-07-17 16:10:14'),
(615, 2, 1, 0, '/resetcontract', 'Resets a players contract so they can /quitjob', '2013-07-22 17:23:45'),
(616, 2, 1, 0, '/setjob', 'Sets a players job manually', '2013-07-23 17:12:05'),
(617, 2, 1, 0, '/ar ', 'Accept\'s a report', '2013-07-24 17:41:28'),
(618, 2, 1, 0, '/cr', 'Closes a report', '2013-07-24 17:41:39'),
(619, 2, 1, 0, '/fr', 'False\'s a report', '2013-07-24 17:41:47'),
(620, 2, 1, 0, '/ann', 'Makes a GM Announcement', '2013-07-25 00:12:33'),
(621, 1, 5, 0, '/infract', 'Infracts an administrator', '2013-07-26 14:35:02'),
(622, 1, 5, 0, '/suspend', 'Suspends an Administrator', '2013-07-31 05:57:36'),
(623, 1, 5, 0, '/acheck', 'Brings up an admins Internal Affairs check', '2013-07-31 06:18:58'),
(624, 1, 5, 0, '/tr', 'Transfers a report to an admin', '2013-08-02 16:39:48'),
(625, 1, 1, 0, '/addii', 'Add\'s a information Icon', '2013-08-05 23:11:51'),
(626, 1, 1, 0, '/delii', 'delete\'s a information Icon', '2013-08-05 23:12:00'),
(627, 1, 1, 0, '/nearbyii', 'Show\'s nearby Information Icons.', '2013-08-05 23:12:13'),
(628, 1, 3, 0, '/licensemonitor', 'Check who owns what firearms licenses', '2013-08-26 02:16:02'),
(629, 1, 1, 0, '/vginfo', 'or /serverinfo - Displays all Server Information', '2014-05-01 19:04:15');

-- --------------------------------------------------------

--
-- Table structure for table `computers`
--

CREATE TABLE `computers` (
  `id` int(11) NOT NULL,
  `posX` float(10,5) NOT NULL,
  `posY` float(10,5) NOT NULL,
  `posZ` float(10,5) NOT NULL,
  `rotX` float(10,5) NOT NULL,
  `rotY` float(10,5) NOT NULL,
  `rotZ` float(10,5) NOT NULL,
  `interior` int(8) NOT NULL,
  `dimension` int(8) NOT NULL,
  `model` int(8) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `cpa_postbacks`
--

CREATE TABLE `cpa_postbacks` (
  `id` int(11) NOT NULL,
  `tracking_id` int(11) NOT NULL,
  `payout` double DEFAULT 0,
  `message` text DEFAULT NULL,
  `offer_id` int(11) DEFAULT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `donates`
--

CREATE TABLE `donates` (
  `order_id` int(11) NOT NULL,
  `txn_id` varchar(19) NOT NULL,
  `payer_email` varchar(75) NOT NULL,
  `mc_gross` float(9,2) NOT NULL,
  `donor` int(11) DEFAULT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  `donated_for` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `donators`
--

CREATE TABLE `donators` (
  `id` int(11) NOT NULL,
  `accountID` int(11) NOT NULL,
  `charID` int(11) NOT NULL DEFAULT -1,
  `perkID` int(4) NOT NULL,
  `perkValue` varchar(10) NOT NULL DEFAULT '1',
  `expirationDate` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `don_purchases`
--

CREATE TABLE `don_purchases` (
  `id` int(11) NOT NULL,
  `name` text DEFAULT NULL,
  `cost` int(11) DEFAULT 0,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `account` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `don_purchases`
--

INSERT INTO `don_purchases` (`id`, `name`, `cost`, `date`, `account`) VALUES
(1, 'FREE GAMECOINS AWARD! (LEAD SCRIPTER PREDZOP)', 5000, '2023-06-27 22:36:46', 1),
(2, 'Increase vehicle slots to  (6)', -4, '2023-06-27 22:37:24', 1),
(3, 'Increase vehicle slots to  (7)', -8, '2023-06-27 22:37:26', 1),
(4, 'Increase vehicle slots to  (8)', -12, '2023-06-27 22:37:29', 1),
(5, 'Increase vehicle slots to  (9)', -16, '2023-06-27 22:37:31', 1),
(6, 'Increase vehicle slots to  (10)', -20, '2023-06-27 22:37:33', 1),
(7, 'Increase vehicle slots to  (11)', -24, '2023-06-27 22:37:35', 1),
(8, 'Increase vehicle slots to  (12)', -28, '2023-06-27 22:37:37', 1),
(9, 'Increase vehicle slots to  (13)', -32, '2023-06-27 22:37:39', 1),
(10, 'Increase vehicle slots to  (14)', -36, '2023-06-27 22:37:42', 1),
(11, 'Increase vehicle slots to  (15)', -40, '2023-06-27 22:37:44', 1),
(12, 'Increase vehicle slots to  (16)', -44, '2023-06-27 22:37:46', 1),
(13, 'Increase vehicle slots to  (17)', -48, '2023-06-27 22:37:48', 1),
(14, 'Increase vehicle slots to  (18)', -52, '2023-06-27 22:37:50', 1),
(15, 'Increase vehicle slots to  (19)', -56, '2023-06-27 22:37:53', 1),
(16, 'Increase vehicle slots to  (20)', -60, '2023-06-27 22:37:55', 1),
(17, 'Increase vehicle slots to  (21)', -64, '2023-06-27 22:37:57', 1),
(18, 'Increase vehicle slots to  (22)', -68, '2023-06-27 22:37:59', 1),
(19, 'Increase vehicle slots to  (23)', -72, '2023-06-27 22:38:05', 1),
(20, 'Increase vehicle slots to  (24)', -76, '2023-06-27 22:38:07', 1),
(21, 'Increase vehicle slots to  (25)', -80, '2023-06-27 22:38:09', 1),
(22, 'Increase vehicle slots to  (26)', -84, '2023-06-27 22:38:12', 1),
(23, 'Increase vehicle slots to  (27)', -88, '2023-06-27 22:38:14', 1),
(24, 'Increase vehicle slots to  (28)', -92, '2023-06-27 23:10:59', 1),
(25, 'Increase vehicle slots to  (29)', -96, '2023-06-27 23:11:01', 1),
(26, 'Increase vehicle slots to  (30)', -100, '2023-06-27 23:11:03', 1),
(27, 'Increase vehicle slots to  (31)', -104, '2023-06-27 23:11:05', 1),
(28, 'Increase vehicle slots to  (32)', -108, '2023-06-27 23:11:08', 1),
(29, 'Increase vehicle slots to  (33)', -112, '2023-06-27 23:11:10', 1),
(30, 'Increase vehicle slots to  (34)', -116, '2023-06-27 23:11:12', 1),
(31, 'Increase vehicle slots to  (35)', -120, '2023-06-27 23:11:14', 1),
(32, 'Increase vehicle slots to  (36)', -124, '2023-06-27 23:11:16', 1),
(33, 'Increase vehicle slots to  (37)', -128, '2023-06-27 23:11:18', 1),
(34, 'Increase vehicle slots to  (38)', -132, '2023-06-27 23:11:20', 1),
(35, 'Increase vehicle slots to  (39)', -136, '2023-06-27 23:11:23', 1),
(36, 'Increase vehicle slots to  (40)', -140, '2023-06-27 23:11:25', 1),
(37, 'Increase vehicle slots to  (41)', -144, '2023-06-27 23:11:27', 1),
(38, 'Increase vehicle slots to  (42)', -148, '2023-06-27 23:11:29', 1),
(39, 'Increase vehicle slots to  (43)', -152, '2023-06-27 23:11:31', 1),
(40, 'Increase vehicle slots to  (44)', -156, '2023-06-27 23:11:33', 1),
(41, 'Increase vehicle slots to  (45)', -160, '2023-06-27 23:11:36', 1),
(42, 'Increase vehicle slots to  (46)', -164, '2023-06-27 23:11:38', 1),
(43, 'Increase vehicle slots to  (47)', -168, '2023-06-27 23:11:39', 1),
(44, 'Increase vehicle slots to  (48)', -172, '2023-06-27 23:11:41', 1),
(45, 'Increase vehicle slots to  (49)', -176, '2023-06-27 23:11:44', 1),
(46, 'Increase vehicle slots to  (50)', -180, '2023-06-27 23:11:47', 1),
(47, 'Increase vehicle slots to  (51)', -184, '2023-06-27 23:11:49', 1),
(48, 'Increase vehicle slots to  (52)', -188, '2023-06-27 23:11:51', 1),
(49, 'Increase vehicle slots to  (53)', -192, '2023-06-27 23:11:52', 1),
(50, 'Increase vehicle slots to  (54)', -196, '2023-06-27 23:11:56', 1);

-- --------------------------------------------------------

--
-- Table structure for table `don_transactions`
--

CREATE TABLE `don_transactions` (
  `id` int(11) NOT NULL,
  `transaction_id` varchar(64) NOT NULL,
  `donator_email` varchar(255) NOT NULL,
  `amount` double NOT NULL,
  `original_request` text DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `handled` smallint(1) DEFAULT 0,
  `username` varchar(50) NOT NULL,
  `realamount` double NOT NULL DEFAULT 0,
  `item_number` int(11) NOT NULL DEFAULT 0,
  `validated` smallint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `don_transaction_failed`
--

CREATE TABLE `don_transaction_failed` (
  `id` int(11) NOT NULL,
  `output` text NOT NULL,
  `ip` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `duty_allowed`
--

CREATE TABLE `duty_allowed` (
  `id` int(11) NOT NULL,
  `faction` int(11) NOT NULL,
  `itemID` int(11) NOT NULL,
  `itemValue` varchar(45) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Used for an admin allow list.';

-- --------------------------------------------------------

--
-- Table structure for table `duty_custom`
--

CREATE TABLE `duty_custom` (
  `id` int(11) NOT NULL,
  `factionid` int(11) NOT NULL,
  `name` text NOT NULL,
  `skins` text NOT NULL,
  `locations` text NOT NULL,
  `items` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Used for custom duties.';

-- --------------------------------------------------------

--
-- Table structure for table `duty_locations`
--

CREATE TABLE `duty_locations` (
  `id` int(11) NOT NULL,
  `factionid` int(11) NOT NULL,
  `name` text NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `z` int(11) DEFAULT NULL,
  `radius` int(11) DEFAULT NULL,
  `dimension` int(11) DEFAULT 0,
  `interior` int(11) DEFAULT 0,
  `vehicleid` int(11) DEFAULT NULL,
  `model` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Used for custom duty locations.';

-- --------------------------------------------------------

--
-- Table structure for table `elections`
--

CREATE TABLE `elections` (
  `idelections` varchar(45) NOT NULL,
  `Votes` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `elevators`
--

CREATE TABLE `elevators` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `tpx` decimal(10,6) DEFAULT 0.000000,
  `tpy` decimal(10,6) DEFAULT 0.000000,
  `tpz` decimal(10,6) DEFAULT 0.000000,
  `dimensionwithin` int(5) DEFAULT 0,
  `interiorwithin` int(5) DEFAULT 0,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `car` tinyint(3) UNSIGNED DEFAULT 0,
  `disabled` tinyint(3) UNSIGNED DEFAULT 0,
  `rot` decimal(10,6) DEFAULT 0.000000,
  `tprot` decimal(10,6) DEFAULT 0.000000,
  `oneway` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `emailaccounts`
--

CREATE TABLE `emailaccounts` (
  `id` int(11) NOT NULL,
  `username` text DEFAULT NULL,
  `password` text DEFAULT NULL,
  `creator` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emails`
--

CREATE TABLE `emails` (
  `id` int(11) NOT NULL,
  `date` datetime NOT NULL,
  `sender` text DEFAULT NULL,
  `receiver` text DEFAULT NULL,
  `subject` text DEFAULT NULL,
  `message` text DEFAULT NULL,
  `inbox` int(1) NOT NULL DEFAULT 0,
  `outbox` int(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `factions`
--

CREATE TABLE `factions` (
  `id` int(11) NOT NULL,
  `name` text DEFAULT NULL,
  `bankbalance` bigint(20) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `rank_1` text DEFAULT NULL,
  `rank_2` text DEFAULT NULL,
  `rank_3` text DEFAULT NULL,
  `rank_4` text DEFAULT NULL,
  `rank_5` text DEFAULT NULL,
  `rank_6` text DEFAULT NULL,
  `rank_7` text DEFAULT NULL,
  `rank_8` text DEFAULT NULL,
  `rank_9` text DEFAULT NULL,
  `rank_10` text DEFAULT NULL,
  `rank_11` text DEFAULT NULL,
  `rank_12` text DEFAULT NULL,
  `rank_13` text DEFAULT NULL,
  `rank_14` text DEFAULT NULL,
  `rank_15` text DEFAULT NULL,
  `rank_16` text DEFAULT NULL,
  `rank_17` text DEFAULT NULL,
  `rank_18` text DEFAULT NULL,
  `rank_19` text DEFAULT NULL,
  `rank_20` text DEFAULT NULL,
  `wage_1` int(11) DEFAULT 100,
  `wage_2` int(11) DEFAULT 100,
  `wage_3` int(11) DEFAULT 100,
  `wage_4` int(11) DEFAULT 100,
  `wage_5` int(11) DEFAULT 100,
  `wage_6` int(11) DEFAULT 100,
  `wage_7` int(11) DEFAULT 100,
  `wage_8` int(11) DEFAULT 100,
  `wage_9` int(11) DEFAULT 100,
  `wage_10` int(11) DEFAULT 100,
  `wage_11` int(11) DEFAULT 100,
  `wage_12` int(11) DEFAULT 100,
  `wage_13` int(11) DEFAULT 100,
  `wage_14` int(11) DEFAULT 100,
  `wage_15` int(11) DEFAULT 100,
  `wage_16` int(11) DEFAULT 100,
  `wage_17` int(11) DEFAULT 100,
  `wage_18` int(11) DEFAULT 100,
  `wage_19` int(11) DEFAULT 100,
  `wage_20` int(11) DEFAULT 100,
  `motd` text DEFAULT NULL,
  `note` text DEFAULT NULL,
  `fnote` text DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `max_interiors` int(11) DEFAULT 20
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `factions`
--

INSERT INTO `factions` (`id`, `name`, `bankbalance`, `type`, `rank_1`, `rank_2`, `rank_3`, `rank_4`, `rank_5`, `rank_6`, `rank_7`, `rank_8`, `rank_9`, `rank_10`, `rank_11`, `rank_12`, `rank_13`, `rank_14`, `rank_15`, `rank_16`, `rank_17`, `rank_18`, `rank_19`, `rank_20`, `wage_1`, `wage_2`, `wage_3`, `wage_4`, `wage_5`, `wage_6`, `wage_7`, `wage_8`, `wage_9`, `wage_10`, `wage_11`, `wage_12`, `wage_13`, `wage_14`, `wage_15`, `wage_16`, `wage_17`, `wage_18`, `wage_19`, `wage_20`, `motd`, `note`, `fnote`, `phone`, `max_interiors`) VALUES
(1, '|| L.S.P.D ||', 1083237, 2, 'On Leave/Suspended/FMT Member', 'Academy Student', 'Cadet', 'Police Officer I', 'Police Officer II', 'Police Officer III', 'Senior Lead Officer', 'Detective I', 'Detective II', 'Detective III', 'Sergeant I', 'Sergeant II', 'Sergeant III', 'Lieutenant I', 'Lieutenant II', 'Lieutenant III', 'Captain', 'Deputy Chief of Police', 'Assistant Chief Of Police', 'Chief Of Police', 0, 250, 350, 550, 650, 750, 950, 1000, 1100, 1200, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1800, 1900, 2000, 'Radio Channel : 911.311', '~~~~~~~~~~~~~\nRoster\n~~~~~~~~~~~~~\n#001 - Cody Stewart\n#002 - Jason DeShaw\n', '                                               -Ø§Ù‡Ù„Ø§ Ø¨ÙƒÙ… ÙÙŠ Ù…Ø±ÙƒØ² ÙˆØ²Ø§Ø±Ø© Ø§Ù„Ø¯Ø§Ø®Ù„ÙŠØ© Ù„Ù„Ù…Ø¯ÙŠÙ†Ø©-\r\n                                               ===================================\r\nÙŠØ±Ø¬Ù‰ Ø§ØªØ¨Ø§Ø¹ Ø§Ù„Ù‚ÙˆØ§Ù†ÙŠÙ† Ø§Ù„ØªØ§Ù„ÙŠØ© ÙˆØ§Ø­ØªØ±Ø§Ù…Ù‡Ø§ Ù„ØªØ¬Ù†Ø¨ Ø§Ù„Ø·Ø±Ø¯ Ù…Ù† Ø§Ù„ÙˆØ²Ø§Ø±Ø©\r\n=======================================\r\nÙ‚ÙˆØ§Ù†ÙŠÙ† Ø§Ù„Ø´Ø±Ø·Ø© Ø§ØªØ¬Ø§Ù‡ Ø§Ù„Ù…ÙˆØ§Ø·Ù†ÙŠÙ†\r\n===================\r\n.ÙŠØ¬Ø¨ Ø¹Ù„Ù‰ Ø¬Ù…ÙŠØ¹ Ù…Ù†Ø³ÙˆØ¨ÙŠ ÙˆØ²Ø§Ø±Ø© Ø§Ù„Ø¯Ø§Ø®Ù„ÙŠØ© Ø§Ø­ØªØ±Ø§Ù… Ø¬Ù…ÙŠØ¹ Ø§Ù„Ù…ÙˆØ§Ø·Ù†ÙŠÙ†â€¦â€.\r\n.Ø¹Ø¯Ù… Ø±ÙØ¹ Ø§Ù„Ø³Ù„Ø§Ø­ Ø§Ù„Ù†Ø§Ø±ÙŠ Ø¹Ù„Ù‰ Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø¨Ø¯ÙˆÙ† Ø§Ù‰ Ø³Ø¨Ø¨ Ù…Ù‚Ù†Ø¹â€¦â€\r\n.Ø¹Ø¯Ù… Ø£Ø®Ø° Ø§Ù‰ Ù…ÙˆØ§Ø·Ù† Ø§Ù„Ù‰ Ù‚Ø³Ù… Ø§Ù„Ø´Ø±Ø·Ø© Ø¨Ø¯ÙˆÙ† Ø¯Ù„ÙŠÙ„ Ù‚Ø§Ø·Ø¹â€.\r\n.Ø£Ø­ØªØ±Ø§Ù… Ø§Ù„Ù…Ø¬Ø±Ù… Ø§Ùˆ Ø§Ù„Ù…ÙˆØ§Ø·Ù† ÙÙŠ Ù‚Ø³Ù… Ø§Ù„Ø´Ø±Ø·Ø© Ø­ØªÙŠ Ø§Ø°Ø§ ÙƒØ§Ù† Ù…ØªÙ‡Ù… Ø±Ø¦ÙŠØ³ÙŠ ÙÙŠ Ø§Ù„Ù‚Ø¶ÙŠÙ‡â€¦â€\r\n.Ù…Ù…Ù†ÙˆØ¹ Ø³Ø¬Ù† Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø§Ù„Ø§ Ø¨Ø¹Ø¯ Ø£Ø«Ø¨Ø§Øª Ù‚Ø§Ø·Ø¹ ÙˆØ³Ù…Ø§Ø¹ Ø¬Ù…ÙŠØ¹ Ø§Ù‚ÙˆØ§Ù„Ù‡â€¦â€\r\n.Ø¹Ø¯Ù… Ø§Ù„ØªØ­Ø¯Ø« Ù…Ø¹ Ø§Ù„Ù…ÙˆØ§Ø·Ù†ÙŠÙ† Ø¨ØªÙƒØ¨Ø± Ø£Ùˆ Ø§Ù„ØªØ¯Ø®Ù„ ÙÙŠ Ø´Ø¦ÙˆÙ† Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø§Ù„Ø§ Ø§Ø°Ø§ ÙƒØ§Ù† Ø§Ù„Ù…ÙˆØ§Ø·Ù† ÙŠÙ‚ÙˆÙ… Ø¨Ø§Ù„Ø´ØºØ¨ Ø£Ùˆ Ø§Ø²Ø¹Ø§Ø¬ Ø§Ù„Ù…ÙˆØ§Ø·Ù†ÙŠÙ† â€ ØªÙ‚Ø¯Ø± ØªØ­Ø±Ùƒ Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø¨Ø§Ù„Ù‚ÙˆØ© Ø§Ù„Ø¬Ø¨Ø±ÙŠØ©â€\r\n.ÙŠÙ…Ù†Ø¹ Ù…Ù† Ø§Ù‰ Ø´Ø±Ø·ÙŠ ØªÙØªÙŠØ´ Ø£Ù‰ Ù…ÙˆØ§Ø·Ù† Ø§Ù„Ø£ Ø£Ù† ÙŠÙƒÙˆÙ† Ù„Ø¯ÙŠÙ‡ Ø³Ø¨Ø¨ ÙƒØ§ÙÙŠ Ù…Ø«Ø§Ù„ â€ ÙŠØ±ØªØ¯ÙŠ Ù…Ø§Ø³Ùƒ, ØªÙˆØ§Ø¬Ø¯ ÙÙŠ Ù…ÙˆÙ‚Ø¹ Ù…Ø´Ø¨ÙˆØ©, ÙÙŠ Ù‚Ø¶ÙŠØ© Ø¬Ù†Ø§Ø¦Ø¨Ø©â€¦â€\r\n.Ù„Ø§ ÙŠØ­Ù‚ Ù„Ù„Ø´Ø±Ø·Ù‰ Ø£Ù† ÙŠØ£Ø®Ø° Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø§Ù„Ù‰ Ù‚Ø³Ù… Ø§Ù„Ø´Ø±Ø·Ø© Ù„Ø£ÙŠ Ù…Ø®Ø§Ù„ÙØ© Ù…Ø±ÙˆØ±ÙŠØ© â€Ø§Ù„Ø§ ÙÙŠ Ø­Ø§Ù„Ø© Ø¹Ø¯Ù… Ø§Ù„ØªØ¹Ø§ÙˆÙ†â€\r\n.ÙŠÙ…Ù†Ø¹ Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ Ø§Ø¹Ø·Ø§Ø¡ Ø£ÙŠ Ù…ÙˆØ§Ø·Ù† Ø£ÙŠ Ø£ØºØ±Ø§Ø¶ ØªØ®Øµ Ø¬Ù‡Ø§Ø² Ø§Ù„Ø´Ø±Ø·Ø©â€¦â€\r\n.ÙŠÙ…Ù†Ø¹ Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø±Ø·ÙŠ Ø§Ù„Ø®Ø±ÙˆØ¬ Ù…Ù† Ø¯ÙŠÙˆØªÙŠ Ø§Ù„Ø§ ÙÙŠ Ø­Ø§Ù„Ø© Ø§Ø®Ø° Ø§Ø°Ù† Ù…Ù† Ø§Ù„Ø±Ø¦ÙŠØ³ Ø§Ùˆ Ø§Ù„Ù†Ø§Ø¦Ø¨ÙŠÙ† Ø§Ù„Ø®Ø§ØµÙŠÙŠÙ† Ø¨Ù‡â€¦â€\r\n.Ø¨ÙŠÙ…Ù†Ø¹ ÙƒÙ„Ø¨Ø´Ø© Ø§ÙŠ ÙØ±Ø¯ Ù…Ù† Ø§Ù„Ø§ÙØ±Ø§Ø¯ Ø§Ù„Ø­ÙƒÙˆÙ…ÙŠØ©â€¦ Ø§Ù„Ø§ Ø¨Ø³Ø¨Ø¨ Ù…Ù‚Ù†Ø¹ ÙŠØ¯Ù„ Ø¹Ù„Ù‰ ÙØ³Ø§Ø¯Ù‡â€\r\n.ÙŠØ³Ù…Ø­ Ù„Ù„Ø´Ø±Ø·Ø© Ø§Ù„Ù‚ÙŠØ§Ù… Ø¨Ø¯ÙˆØ±ÙŠØ§Øª ØªÙØªÙŠØ´ Ø¯Ø§Ø®Ù„ Ø§Ù„Ù…Ø¯ÙŠÙ†Ø© ÙÙ‚Ø·â€¦â€\r\n.ÙŠÙ…Ù†Ø¹ Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø±Ø·Ø© Ø§Ù„ØªÙƒØ¨Ø± Ø¹Ù„Ù‰ Ø§Ù„Ù…ÙˆØ§Ø·Ù†ÙŠÙ†â€¦â€\r\n.Ø¹Ù†Ø¯ ØªÙØªÙŠØ´ Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø¨Ø¹Ø¯ Ø§Ù„Ø­ØµÙˆÙ„ Ø¹Ù„Ù‰ Ø³Ø¨Ø¨ Ø§Ù„ØªÙØªÙŠØ´ ÙÙŠ Ø­Ø§Ù„Ø© Ø§ÙŠØ¬Ø§Ø¯ Ø§ÙŠ Ø§Ø´ÙŠØ§Ø¡ ØºÙŠØ± Ù…Ø±Ø®ØµØ© ÙŠÙ„Ø²Ù… Ø¹Ù„ÙŠÙƒ Ù…ØµØ§Ø¯Ø±ØªÙ‡Ø§ ÙˆØ§Ø±Ø³Ø§Ù„Ù‡Ø§ Ù„Ù„Ù…Ø³Ø¤ÙˆÙ„ Ø§Ù„Ø¹Ø§Ù…â€¦â€\r\n.Ù„ØªØ³Ù‡ÙŠÙ„ Ø¹Ù…Ù„ÙŠØ© Ø§Ù„ØªÙˆØ§ØµÙ„ ÙŠØ±Ø¬Ù‰ Ù…Ù† Ø¬Ù…ÙŠØ¹ Ø§ÙØ±Ø§Ø¯ Ø§Ù„Ø´Ø±Ø·Ø© Ø§Ø®Ø° Ø±Ù‚Ù… Ø§Ù„Ù‚Ù‡Ø§ØªÙ Ø§Ù„Ø®Ø§Øµ Ø¨Ù…Ø¯ÙŠØ±Ù‡Ù…â€¦â€\r\n.Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ù…Ø³Ø¯Ø³ ÙÙŠ Ø§ÙŠÙ‚Ø§Ù Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª Ø¹Ù†Ø¯ Ø§Ù„ØªÙØªÙŠØ´ Ø¹Ù„ÙŠÙ‡ Ø¹Ù‚ÙˆØ¨Ø© ØºØ±Ø§Ù…ÙŠØ©â€¦â€\r\n.Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø±Ø·ÙŠ Ø§Ù„ØªÙˆØ§Ø¬Ø¯ ÙÙŠ Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø¨Ù„Ø§ØºØ§Øª ÙˆØ§Ù„ØªÙˆØ¬Ù‡ Ø§Ù„Ù‰ Ø®Ø§Ù†Ø© Ø§Ù„Ø¨Ù„Ø§Øº ÙÙˆØ±Ø§ Ø¹Ù†Ø¯ Ø³Ù…Ø§Ø¹Ù‡â€¦â€\r\n.Ø¹Ø¯Ù… ØªÙˆØ§Ø¬Ø¯ Ø§Ù„Ø´Ø±Ø·ÙŠ ÙÙŠ Ø§ÙŠ Ø¨Ù„Ø§Øº ÙŠØ¹Ø±Ø¶Ù‡ Ù„Ù„Ø·Ø±Ø¯ Ù…Ù† Ø§Ù„ÙˆØ²Ø§Ø±Ø© ÙÙˆØ±Ø§â€¦â€\r\n.Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ø±Ø§Ø¯ÙŠÙˆ ÙÙŠ Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø¯ÙˆØ±ÙŠØ§Øª Ù…Ù‡Ù… Ø¬Ø¯Ø§â€¦â€\r\n.ÙÙŠ Ø­Ø§Ù„Ø© Ù‚Ø§Ù… Ø§Ù„Ù…ÙˆØ§Ø·Ù† Ø¨Ø§Ù„ØªØ¨Ù„ÙŠØº Ø¹Ù† Ø¬Ø±ÙŠÙ…Ø© Ø§Ùˆ Ø¹Ù† Ø­Ø§Ù„Ø© Ø§Ø®ØªØ·Ø§Ù Ø§Ùˆ Ø³Ø±Ù‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø±Ø·ÙŠ Ø§Ù„ØªØ¹Ø§Ù…Ù„ Ù…Ø¹Ù‡ Ø§Ù„Ù‰ Ø§Ø®Ø± Ø§Ù„Ø¨Ù„Ø§Øº Ù„Ø§Ø³ØªØ±Ø¬Ø§Ø¹ Ø­Ù‚ Ø§Ù„Ù…ÙˆØ§Ø·Ù†â€¦â€\r\n.ÙŠÙ…Ù†Ø¹ Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø±Ø·ÙŠÙŠÙ† Ø§Ù„ØµØ±Ø§Ø® ÙÙŠ Ø§Ù„Ø±Ø§Ø¯ÙŠÙˆ Ø§Ùˆ Ø§Ù„ØºÙ†Ø§Ø¡ Ø§Ùˆ Ø§Ù„ØªÙƒÙ„Ù… Ø¨ØµÙˆØª Ù…Ø±ØªÙØ¹â€¦â€\r\n.Ù„Ø§ ÙŠØ³Ù…Ø­ Ù„Ùƒ Ø§Ù„Ø®Ø±ÙˆØ¬ Ù…Ù† Ø§Ù„ÙˆØ²Ø§Ø±Ø© Ø§Ùˆ Ø·Ù„Ø¨ Ø§Ø³ØªÙ‚Ø§Ù„Ø© Ø§Ù„Ø§ Ø¨Ø¹Ø¯ Ù…Ø±ÙˆØ± 5 Ø§ÙŠØ§Ù… Ù…Ù† ØªÙˆØ¸ÙŠÙÙƒâ€¦â€\r\n.Ø¹Ù†Ø¯ ÙØµÙ„Ùƒ Ù…Ù† Ø§Ù„Ø´Ø±Ø·Ø© Ø§Ùˆ Ø§Ù„Ø§Ø³ØªÙ‚Ø§Ù„Ø© ÙŠØªÙ… Ø§Ø¹Ø·Ø§Ø¦Ùƒ ØªØ¹Ù‡Ø¯Ø§ Ø¨Ø¹Ø¯Ù… ØªØ³Ù„ÙŠÙ… Ø§ÙŠ Ù…Ø¹Ù„ÙˆÙ…Ø§Øª Ù…Ù† Ø§Ù„ÙˆØ²Ø§Ø±Ø© ÙˆØ¹Ù‚ÙˆØ¨ØªÙ‡Ø§ Ø§Ù„Ø³Ø¬Ù† Ø§Ùˆ Ø§Ù„Ø§Ø¹Ø¯Ø§Ù…â€¦â€\r\n.Ø§Ø®ÙŠØ±Ø§ ÙˆÙ„ÙŠØ³ Ø§Ø®Ø±Ø§ ÙŠÙ„Ø²Ù… Ø¹Ù„ÙŠÙƒ Ø§Ø­ØªØ±Ø§Ù… Ø¬Ù…ÙŠØ¹ Ø§ÙØ±Ø§Ø¯ Ø§Ù„Ø´Ø±Ø·Ø© ÙˆØ§Ù„Ø§Ø³ØªÙ…Ø§Ø¹ Ø§Ù„Ù‰ Ø§Ù„Ø§ÙˆØ§Ù…Ø± Ø§Ù„Ù…ÙˆØ¬Ù‡Ø© Ù„Ùƒ Ù…Ù† Ù‚Ø¨Ù„ Ø§Ù„Ù‚Ø§Ø¦Ø¯ Ø§Ùˆ Ù†Ø§Ø¦Ø¨ÙŠÙ‡â€¦â€\r\n====================================================================\r\n\r\nØ§Ù„Ø§ÙˆØ§Ù…Ø± Ø§Ù„ØªÙŠ Ø³ØªØ³Ø§Ø¹Ø¯Ùƒ Ø¯Ø§Ø®Ù„ Ø§Ù„ÙˆØ²Ø§Ø±Ø©\r\n=======================\r\n/tunerradio 511.115 = Ù„Ù„Ø¯Ø®ÙˆÙ„ ÙÙŠ ØªØ±Ø¯Ø¯ Ø§Ù„Ø±Ø§Ø¯ÙŠÙˆ\r\n/backup = Ù„Ø·Ù„Ø¨ Ø§Ù„Ø¯Ø¹Ù…\r\n/copstop = Ø­Ø±ÙƒØ© Ù„Ø§ÙŠÙ‚Ø§Ù Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª\r\n/dep = Ù„ÙˆØµÙ Ø­Ø§Ù„Ø© Ø§Ù„Ø¨Ù„Ø§Øº ÙˆØ·Ù„Ø¨ Ø§Ù„Ø¯Ø¹Ù…\r\n\n', NULL, 20),
(2, '|| Emergency Hospital ||', 579367, 4, '(( FMT ))', 'Supervisory Commissioner', 'Suspended', 'Vacation', 'On Leave', 'Paid Vacation', 'Academy Student', 'Probationary FF / EMT', 'FF / EMT - B', 'FF / EMT - I', 'FF / EMT - A', 'FF / Paramedic I', 'FF / Paramedic II', '', '', 'G1 Lieutenant', 'G2 Lieutenant', 'Captain', 'Deputy Commissioner', 'Commissioner', 0, 1250, 0, 0, 75, 350, 200, 500, 600, 675, 750, 800, 1650, 0, 0, 1800, 1800, 2000, 2250, 2500, 'Radio Frequency: 115.001 || Remember to show the best whilst on duty, failure to do so will result in disciplinary action || 7+ days of inactivity = boot || Training date TBA - Check the forums daily!', '----------\nBadges\n---------\nissuebadge ID RANK - #BADGENUMBER\nissuebadge ID LSFD || Search and Rescue || NICKNAME\n---------\nLogins\nEMAL: lsfdacademy@gmail.com\nPassword: LSFDAcademy2014\nDetails: Create examinations for students/special units there. Remember to go to http://www.google.co.uk/drive/ to find the exam!\nLSFD Examination (Fire/Rescue): https://docs.google.com/forms/d/1rhDcypUeH-Q7GkgCg0qshK5a3HXN90KaKkeMp3w0mIQ/viewform \n----------\nTraining\n-----------\nTo be held AS SOON AS POSSIBLE - conducted by Medical and Fire Captains and Lieutenants.\n\n-------------------------------\nPromotion Suggestions\n-------------------------------\n\n\n\n-----------------------------\nAdministrative Details\n-----------------------------\n\n\n----------------------------\nAdvertisements\n-----------------------------\nLos Santos Fire Department | Applications are now open! | Hiring loyal and hard-working people to serve our community | Visit fd.lossantos.us and apply now!\nThe Los Santos Fire Department will be hosting a Live Recruitment tomorrow. Time is not exact at this moment. Ever want to be a Hero? Come on down tomorrow! We are looking to fill multiple of openings of Fire Fighters and EMT\'s.\n\n--------------------------------------\nAuthorised Strobes\n--------------------------------------\nAdriana Martin - 2011 Ford Crown Victoria - Plates: VS4 4521 - VIN: 13700 (RPly signed for rights waver)\n', 'PRESS RELEASES\nFebruary 2015 - Press Release: http://fd.lossantos.us/viewtopic.php?f=48&t=178\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nDon\'t sell faction equipment (Gas masks, medical bags, duty belt\'s) You will be removed from LSFD and administrative action will be taken I.E. Jails/Warns/Bans.\nIMPORTANT: If you want to request strobbes for your personal vehicle, talk to Jason Heywood first!! Only FF/EMT B+ can apply for those.\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nBadge numbers:\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n#001 - Katie Hammond - Supervisory Commissoner\n#002 - Jayson Heywood - Fire Chief\n#003 - Evelyn Reid\n#105 - Adrian Grey\n#066 - Michael Hopkins\n#007 - Sean O\'Connor\n#008 - Kenzie McLaughlin\n#013 - Khalil Martinez\n#036 - Jane Matthews\n#064 - Mona McLaughlin\n#069 - Antonio Johnson\n#088 - David Maraz\n#101 - Lindsey Walker\n#023 - Somaya Ghaffar\n#142 - Jessica Maddison\n#015 - Alexander Reason\n#010 - Ariana Martin\n#021 - Tyrese Tyrone\n#025 - Niriliq Meekitjuk\n#026 - Daniel Parker\n#027 - Michael Coleman\n#035 - Ryan Fowler\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nSub Units/Requirments:\n\nSearch and Rescue - Firefighter/EMT B\nHazardous Materials - Firefighter/EMT A\nFire Inspection Unit - Firefighter/EMT I\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nRadio Communications\n\nFrequency: 115.001\n\n10-CODES/Radio Codes:\r\n\r\n\r10-1: Roll Call, all units respond to said location.\r\n\r\r10-2: Arrived on scene.\r\n\r10-3: Negative / No\r\n\r10-4: Acknowledgement / Affirmative / Yes\r\n\r10-5: Repeat last transmission\r\n\r10-6: Stand-by\r\n\r10-7: Unavailable for calls\r\n\r10-8: Available for calls\r\n\r10-9: Suspect Lost (Usually followed by a 10-17 and 10-22)\r\n\r10-10: (Supervisors only) requesting activity update along with giving your current position\r\n\r10-12: Backup Required (Specify situation and location)\r\n\r10-13: Requesting specific unit (specify) \r\n\r10-17: Requesting description on the suspect\r\n\r10-20: Requesting Location\r\n\r10-22: Disregard last transmission\r\n\r10-30: Starting Patrol/Resuming patrol after Code 7\r\n\r\r10-31: Returning to Station\r\n\r10-44: Coffee Break\r\n\r10-50: Car accident\r\n\r10-55: Traffic Stop\r\n\r10-57 Victor: Vehicle pursuit.\r\n\r\r10-57 Foxtrot: Foot pursuit.\r\n\r10-66: Felony Stop\r\n\r10-88 Suspicious Person(s)\r\n\r10-99: Assignment complete (State condition and at what call)\r\n\r\r11-99: Officer requires help, Emergency\r\n\r\n\rStatus-codes:\r\n\rStatus 1: In Service\r\n\rStatus 2: Out of Service\r\n\r\n\r\rIdentity Codes:\r\n\r\rIC-1: White\r\n\r\rIC-2: Black\r\n\r\rIC-3: Latino or Mexican\r\n\r\rIC-4: Middle-Eastern\r\n\r\rIC-5: Asian\r\n\r\rIC-6: Unknown ethnicity.\r\n\r\nSituation codes:\r\n\r\rCode 0: Absolute emergency, drop everything you’re doing and respond immediately.\r\n\r\rCode 1: Non-emergency. If you\'re doing something, deal with it first. Respond without lights or sirens.\r\n\r\rCode 2: Non-emergency. If you\'re doing something, drop it and respond. Respond with lights only.\r\n\r\rCode 3: There is an emergency. Respond with lights and sirens.\r\n\r\rCode 4: No assistance required, situation under control.\r\n\r\rCode 5: All units stay out of <location>.\r\n\r\rCode 6: Out of car at <location>.\r\n\rCode 7: Meal break.\r\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n\nBASIC LIFE SUPPORT (BLS)\n\nBasic life support (BLS) is the level of medical care which is used for victims of life-threatening illnesses or injuries until they can be given full medical care at a hospital. It can be provided by trained medical personnel, including emergency medical technicians, paramedics, and by laypersons who have received BLS training. BLS is generally used in the pre-hospital setting, and can be provided without medical equipment.\n\nCirculation: providing an adequate blood supply to tissue, especially critical organs, so as to deliver oxygen to all cells and remove metabolic waste, via the perfusion of blood throughout the body.\r\n\nAirway: the protection and maintenance of a clear passageway for gases (principally oxygen and carbon dioxide) to pass between the lungs and the atmosphere.\r\n\nBreathing: inflation and deflation of the lungs (respiration) via the airway\r\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n\nADVANCED LIFE SUPPORT (ALS)\n\nAdvanced Life Support (ALS) is a set of life-saving protocols and skills that extend Basic Life Support to further support the circulation and provide an open airway and adequate ventilation (breathing).\nBLS Includes But Is NOT Limited To:\n\nTracheal intubation\r\n\nRapid sequence intubation\r\n\nCardiac monitoring\r\n\nCardiac defibrillation\r\n\nTranscutaneous pacing\r\n\nIntravenous cannulation (IV)\r\n\nIntraosseous (IO) access and intraosseous infusion\r\n\nSurgical cricothyrotomy\r\n\nNeedle cricothyrotomy\r\n\nNeedle decompression of tension pneumothorax\r\n\nAdvanced medication administration through parenteral and enteral routes (IV, IO, PO, PR, ET, SL, topical, and transdermal)\r\n\nAdvanced Cardiac Life Support (ACLS)\r\n\nPediatric Advanced Life Support (PALS) or Pediatric Education for Pre-Hospital Providers (PEPP)\r\n\nPre-Hospital Trauma Life Support (PHTLS), Basic Trauma Life Support (BTLS) or International Trauma Life Support (ITLS)\r\n\n----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nFIREFIGHTERS TOOLS\n\n((The Chainsaw acts as most of the cutting/breaking tools below))\n\nBasic:\n\nFire Extinguisher (Portable device used to extinguish small fires)\nAxe (Used to break doors down)\nSCBA Gear(Self-Contained Breathing Apparatus) (Compressed air that MUST be worn when dealing with a fire)\nLadder (Used to climb up places)\nSand Bucket (Used to spread on the floor to prevent fire spreading I.E. Fuel. Also used to dry oil up)\nJaws of Life ((Chainsaw)) (Used to cut metal or other materials)\nHalligan Tool (Sharp Iron bar used to break things open (can be classed as advanced)\n\nAdvanced:\n\nHoseline (A long rubber, flexible tube used to run water though)\nFemale-Male Link (Used to connect another female-male hoseline to allow water to run though)\nHalligan Tool (Sharp Iron bar used to break things open (can be classed as basic)\n\n---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n\n\n\n\n\n\n\n\n', NULL, 20),
(3, 'Government of Los Santos', 29166057, 3, '(( FMT Liaison )) Suspended/Leave', 'Intern', 'Trainee Licensing Officer', 'Licensing Officer', 'P.A', 'Planning Supervisor', 'Trainee Planning Supervisor', 'Director of Licensing / Planning', 'Public Safety Representative', 'Trainee Security Officer', 'Security Officer', 'Director of Security', 'Director of Public Safety', 'Press Secretary', 'Staff Secretary', 'City District Manager', 'Chief of Staff', 'Council(wo)man', 'Deputy Mayor', 'Mayor', 0, 250, 470, 800, 800, 800, 470, 1050, 900, 470, 800, 1050, 1050, 900, 1100, 1200, 2500, 0, 2500, 2500, 'Radio frequency: 316.95 ||. Please read the note for further information.  ||  We now have our own forums. Check the note for further information. ||', '-700grands from faction bank = For SAPT\n\nLeader Rules:\n- No OOC promotions, demotions, removals or recruitments;\n- Do not change wages without approval of the FMT;\n- Do add, remove or move faction vehicles without approval of the factionleader\n_______________________________________________\n\nInactive Member discussion. 3 Days unnotified inactivity limit for dismissal of rank, 6 Days full removal of the faction!!\nPlease write here if members are suspended and what reason they are suspended for!\n\n\n_______________________________________________\n\n~ Executive Cabinet\n- Mayor: Daniel Levi (active)\n- Deputy Mayor: Rebecca Glauber (active)\n- Chief of Staff: Taro Watanabe (active)\n- Press Secretary: VACANT\n-- Department of Licensing: Sicilia Holson (active)\n-- Department of Planning: Sicilia Holson (active)\n-- Department of Public Safety: Ryan McCarthy (active)\n-- Department of Security: VACANT\n\n~ City Council\nMayor: Daniel Levi\nDeputy Mayor: Rebecca Glauber\nChief of Police: Thor Askeland\nCommissioner of Fire Department: Jason Heywood\nTaro Watanabe\nEdison Best\nRyan McCarthy\n__________________________________________________\n\nHanding out phone numbers:\n51-xy\nx:\n- 0 = Mayor, Deputy & Chief of Staff\n- 1 = Secretaries\n- 2 = Licensing Dep\n- 3 = Planning Dep\n- 4 = Security\n- 8 = Public Safety\n- 9 = Councilmembers\n\ny: \n- Given in random order.\n\n', 'EVERYONE MUST REQUEST TO JOIN THE GOV USERGROUP ON THE FORUMS!!!!\n\nWe now have our own Government forums! YOU MUST GO THERE AND REGISTER!!!!\nhttp://gov.blankworld.org/\n\nFaction Rules ((OOC and IC))\n\n1) Inactivity:\n1.1) Inactivity of 3 days or more will lead to a removal of wage and you will be set to \"Suspended/Leave\".\n1.2) Inactivity of 6 days or more will lead to a full removal.\n\n2) Corruption:\n2.1) Any form of OOC corruption is strictly forbidden. It will reported to administrators and punished harshly.\n2.2) Any for of IC financial corruption is forbidden unless approved by the FMT leader.\n2.3) IC corruption is allowed if it has no consequnces for the faction, but for you as a member (such as drugs)\n\n3) Behavior:\n3.1) You are expected to behave proffesionally both IC\'ly and OOC\'ly. This includes being formal.\n\n4) Infrastructure & vehicles:\n4.1) The private parking lot is expected to be kept neatly and organized. Only certain members can have reserved parking spots.\n4.2) Helicopter parkings are only for governmental vehicles.\n4.3) /dep is only to be used when approved by a faction leader.\n4.4) Special vehicles may not be used for recreational goals.\n\n5) Badges:\n5.1) Badges are only to be worn in situations related to the faction or in faction-vehicles.\n\n6) A Recruitment Review team is being established by CoS Gregory Holson.  The Recruitment Review team will help to review all Employment applications that players send in on the forums. This team\nis required to review the applications and you will get back to Gregory Holson to let him know what you think on the application, whether it\'s to be accepted or denied.  If you would like to be apart\nof the Recruitment Review team, PM Gregory Holson on the forums @Behr and explain to him why you would like to be apart of the team and what makes you fit for the team.\n(( P.S: Gregory Holson actually wrote this ))\n\n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n~ Department of Licensing: Phone number 20-29.\nWorks on Forums and IG. Respond to license applications. After application is accepted, respond to licensing calls and grant the license IG and inspect the business.\n(( Trainee Licensing Officers are not allowed to do forum work!  You must do a license with a Licensing Officer IG.  Just go with them and take note of what they do and how they work. ))\n\n~ Department of Planning: Phone number 30-39.\nWorks on Forums and IG. Respond to planning applications. After application is accepted, ensure payments are made and approval is clear.\n', '51', 20),
(4, '|| Rapid Town ||', 1001917, 7, 'UnRanked/Suspended', 'Sales Contact', 'On Leave (with report)', 'On Leave (no report)', 'Student', 'Department Coordinator', 'Probationary Driver', 'Driver I', 'Driver II', 'Driver III', 'Driver IV', 'Driver V (Lead Driver)', 'Impound Manager', 'Instructor', 'Head Instructor', 'Sales Representative', 'Sales Manager', 'Supervisor', 'Assis. Chief Executive Officer', 'Chief Executive Officer', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1800, 2000, 2200, 2500, 'Radio: 324.842 | Inactivity = Kick | On duty = badge and uniform. | Screenshot vehicles before impound | Minor corruption allowed, major = a kick |', '---- General ----\n- Only HC are supposed to have their own assigned phonenumber.\n- No member is not allowed to keep an income of sales earned.\n- Do not leak any info that is not supposed to get out.\n- Be sure to post in the following thread when you demote/promote/accept/fire/suspend anyone: http://forums.owlgaming.net/showthread.php?8617-Rapid-Towing-High-Command-Arrivals-Departures-Promotions-Demotions-Logbook\n\n\n---- MDC ----\nThis can be used for background checks only.\nName: RapidTow\nPW: rapidtowingleader\n\n\n---- Badge ----\nBe sure to follow the format below.\n/issuebadge id Rapid Towing - Rank - F.Lastname\n\n\n---- Faction Vehicles ----\nFaction vehicles do NOT get purchased without the approval of the CEO or Assistant CEO.\n\nCAR COLOR CODES:\nsetcolor * 000000 00D300\nFirst: 000000\nSecond: 00D300\n\nRapid towing colors:\nsetcolor * 000000 002144\n2nd 002144\n', 'ALL MEMBERS READ THIS IMMEDIATLY.\nhttp://forums.owlgaming.net/showthread.php?13183-Issues\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n---- General Notes ----\n- Received #9021 calls must be answered. Failure to respond will be result in a punishment. We need to show the server that we\'re active!\n- Fuel and fix the vehicles before returning.\n- Only English is allowed in /f. Talking foreign will result in a punishment of 1 hour.\n- Do not restock the dealership unless told by the CEO, Assistant CEO or Sales Manager.\n- Badges are not to be given out unless approved by a faction leader.\n- Upon leaving the faction, badges must be deleted.\n\n\n---- Faction Vehicles ----\n- Buckle up.\n- Lock the doors.\n- Wear your badge and uniform. Failure to wear so will result in a punishment.\n\n\n---- Impounding Cars ----\n- Find an empty space on the first floor.\n- Place it.\n- /park, /handbrake and /setvol 0 it.\n\n\n---- Impounding Bikes ----\n- Use the DFT to bring the bikes inside.\n- Have an administrator /start it.\n- Place it properly on the top floor.\n- /park and /impoundbike it.\n\n\n---- Phonenumbers ----\n- 9022 <-> 9029 = Main Department\n- 9030 <-> 9039 = Instruction Department\n- 9040 <-> 9049 = Sales Department\n\n\n---- Sales Department ----\n- All the money goes to the faction bank. Account name is Rapid Towing, have your reason like this: \"Sales - [Vehicle ID], [Buyer Name]\" (requirement from FMT)\n- You are not allowed to keep a cut of the money. This is an OOC rule which will receive OOC punishment when caught. Keeping cash will result in a kick and a reset of your account.\n- Price: to a non-employee: VehiclePrice x 0.45.\n- Contact for sales department: http://bit.ly/SalesDepartment\n\n\n---- Corruption ----\n- ALLOWED: minor corruption. Example: speeding, drugs.\n- NOT ALLOWED: major corruption. Robbery, kidnapping. Doing it will result in a faction removal.\n\n\n---- Handy Links ----\n- Picture of the 2014 Ford F-350 Towtruck equipped with a stinger towing kit. (more the less) : http://www.southbayford.com/img/layout/towtruck/specPhoto_towtruckF350.jpg\n- The trucks have something similair to this attached to their towing boom (NO HOOK!): http://www.youtube.com/watch?v=V9XVA2rvNek\n- USERGROUP: http://forums.owlgaming.net/profile.php?do=editusergroups\n\n---- Commands ----\n/rbs - Opens the roadblock HUD. \n/nearbyrbs - Find nearby roadblocks and their ID.\n/delrb (ID) - Deletes the roadblock with \'ID\'.\n/ed and add Õ $RetailPrice x 0.45\n\n----Student Training & Exams----\nFirst of all, if you\'re a Student, welcome to Rapid Towing, hope your career at this company will be full of positive results.\nNow, this section will be more of a feedback section for all the Students that want to know how this phase works.\nAs a Student you\'re not allowed to go on patrol by yourself neither are you allowed to answer to either Departmental or Hotline calls.\nAs you should know, the Rapid Towing\'s Forum Section has everything you need to successfully pass on your exam. Below this you\'ll find a hand full of links that will help you out:\n- http://forums.owlgaming.net/showthread.php?18403-Rapid-Towing-Student-Handbook-(MUST-READ!)\n- http://forums.owlgaming.net/showthread.php?17337-Rapid-Towing-General-Rules\n- http://forums.owlgaming.net/showthread.php?23340-Rapid-Towing-Official-Parking-Rules\n- http://forums.owlgaming.net/showthread.php?26560-Security-at-Rapid-Towing\n- http://forums.owlgaming.net/showthread.php?19576-Rapid-Towing-Sales-Department\n- http://forums.owlgaming.net/showthread.php?24075-Rapid-Towing-Radio-Usage\n- http://forums.owlgaming.net/showthread.php?27064-Idlewood-Gasstation-towing-not-allowed\n- http://forums.owlgaming.net/forumdisplay.php?729-Unlawful-Impoundment-Reports\n\nOnce you\'ve read those links, I believe you will be almost ready to take your exam.\nAll you need now is to go out on ride-alongs with your partners and ask them any questions you have about the company and how this works.\nBelow you will find a link of what us, Instructors, take in mind in your exams.\n- http://forums.owlgaming.net/showthread.php?31476-Rapid-Towing-Student-Training-amp-Exams&p=194304#post194304\n\n----Probationary Phase----\nCongratulations to all the new Probationary Drivers, this is the part where you will be doing the best you can and will be under eye of other higher ranks.\nFrom now on, you\'re allowed to go on solo patrol and answer to Departmental and Hotline calls.\nNow you have even more responsibility from your acts while on duty.\nDon\'t stick to the fifteen (15) minimum impound mark as it will make your promotion hard to appear as soon as you want. Try getting a higher amount than fifteen (15) impounds.\nKeep your attitude the best. Do not misbehave with any other employee at Rapid Towing nor with customers/civilians.\nRemember to always to pictures (screenshots) if the vehicles you impound with the plates in sight.\nWe expect you to show dedication towards the company.\nThese simple facts will make your future in Rapid Towing positive.\n\n----Behavior/Attitude----\n(( Link is coming soon... ))\n', '90', 20),
(20, '|| BBC News ||', 874241, 6, 'Intern', '((FMT))', 'On Leave', 'Suspended', 'Junior Anchor ', 'Junior Journalist', 'Anchor ', 'Journalist', 'Senior Journalist', 'Senior Anchor ', 'Journalist + Anchor', 'Phil', 'Head of Technical Staff ', 'Head Journalist ', 'Head Anchor ', 'Office Supervisor ', 'Manager ', 'Chief Financial Officer', 'Chief Operating Officer ', 'Chief Executive Officer ', 200, 0, 0, 0, 250, 250, 600, 600, 600, 900, 650, 1000, 650, 950, 950, 700, 1000, 1300, 1500, 1500, 'Apply for the LSN usergroup, and check the new obligations in the employee handbook. They will go in place today Frequency: 456.709 ', 'Ranks ( These are the Standard Rate ranks which may change due to promotion of pay not rank)\n\nChief Executive Officer - 1500\r\nChief Operating Officer - 1500\r\nChief Financial Officer - 1300\r\nManager - 1000\r\nOffice Supervisor - 700\r\n\nHead Journalist - 1000\r\nSenior Journalist - 900\r\nJournalist -  600\r\nTrial Journalist - 400\r\n\r\n\n\nHead Anchor - 1200\r\nSenior Anchor - 900\r\nAnchor - 600\r\nTrial Anchor - 400\r\n\r\nJanitor - 300\n', '\n\n\n/movetv - moves the camera to your position\n/starttv - starts the show\n/endtv - ends the show\n\n/interview name - starts interview\n/i text - to speak via the radio system\n/endinterview name - ends the interview\n\n\n\n\n\n\nRadio Channel #456.709 \n5 days of  inactivity=suspended,\n 7 days=kick!!\nIC Email: firstname.lastname@LSNetwork.sa| \n\n\n', NULL, 20),
(47, '|| F.B.I ||', 861722, 2, 'On Leave / Suspended', '[ANG] Airman', '[ANG] Master Sergeant', '[ANG] Lieutenant', '[ANG] Major', 'Trainee', 'Security Guard', 'Crew Chief', 'ATC Officer', 'Agent', 'Special Agent', 'ROT Instructor', 'SER Instructor', 'MER Instructor', 'TER Instructor', 'Chief Investigator', 'Operations Manager', 'Head Instructor', 'FAA Deputy Administrator', 'FAA Administrator', 0, 650, 800, 1000, 1200, 200, 550, 550, 550, 750, 1000, 650, 750, 900, 1100, 1000, 1100, 1200, 1200, 1400, 'Internal channel: 951.159 | Remember to apply to the usergroup on forums! | Going away? Post a inactivity notification @ FAA Staff forum & notify a HC.', '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nBadge format:\n\nFAA <Rank> - <F.Lastname> - <badge>\nExample: FAA Administrator - D.Bryant - #100\n\n\nShort links:\nhttp://tiny.cc/faacareer - Career Apps\nhttp://tiny.cc/flightschool - Flight School apps\nhttp://tiny.cc/flightinstructor - Instructor apps\n\nLos Santos Flight School is looking for instructors! Get free education into a lucrative and challenging job. Apply today! http://www.lossantosflightschool.tk/\n\n', 'NOTICE!: 1- Upon leaving the faction/being kicked or removed from it, you\'ll need to delete your badge and possible uniform.\n              2-Don\'t forget to apply for our Usergroup on the forums!\n\n_____________________________________________________________________________________________________________________\n\nIMPORTANT RULES: whoever break any of these rules will be suspended and charged with a crime.\n1) NO guns are allowed inside the airport field, unless the holder is a cop or FAA Agents+, unauthorized personnels will be charged with crime APC112.\n\n2) Cruisers are NOT allowed out of the airport gates for repairs etc. Unless authorised by HR - HR can also go out in the black cars. DO NOT ABUSE THE SIRENS!\n\n3) NO personal vehicles are allowed to pass from the second gates, ONLY faction vehicles.\n\n4) Driving on the runways will lead to an immediate suspension and charging with crime APC 113.\n\n5) Instructing any kind of pilot licenses or typerating without a valid CFI license will lead to charging crime APC107.\n\n6) NO vehicles are allowed to park on the airport\'s sidewalk.\n\n7) ONLY one vehicle is allowed to park inside the parking area per member.\n\n\n-----to be continued-----\n\n\n', '55', 20),
(50, '|| Court Of Blaze ||', 485483, 2, 'On Leave/Suspended', 'Janitor', '', 'SADLE Special Agent in Training', 'SADLE Special Agent', 'SADLE Supervisory Special Agent', 'SADLE Special Agent in Charge', 'SADLE Commissioner', '', 'Public Relations Officer', 'Special Assistant', 'Public Defender', 'Magistrate Judge', 'Prosecutor In Training', 'Prosecutor', 'Assistant District Attorney', 'District Attorney', 'Attorney General', 'Associate Justice', 'Chief Justice', 0, 250, 0, 700, 800, 900, 1000, 1100, 850, 650, 1000, 0, 650, 600, 650, 700, 900, 1000, 1250, 1500, 'DLE frequency - 132.2 | TS Password = cat', 'BADGE FORMAT:\n[Rank - Individual name]\n\nUse /issuebadge [ID] then the badge format above to issue an individual their badge.\n\nFACTION EXPENSES:\n\n', 'Badges:\n\n1 - Special Agent - #BADGENUMBER\n2 - POLICE || SPECIAL AGENT *Plate Carrier*\n3 - || SADLE/POLICE - \"NICKNAME\" ||\n4 - || POLICE - SPECIAL AGENT ||\n\n1 - General Duty bdge\n2 - Plate Carrier badge\n3 - Rapid Response Team, Marked\n4 - Rapid Response Team, unmarked\n\nRapid Response Team nicknames\n\nMiles Morrison -  \"TAILS\"\nJason Gordon - \"LOCKS\"\nDavid Ellsworth  - \"IRONMAIDEN\"\nDwayne Matheson - \"GRAVEDIGGER\"\n\nRadio Codes:\r\n10-1: Roll Call, all units respond to said location.\r\n10-2: Arrived on scene.\r\n10-3: Negative / No\r\n10-4: Acknowledgement / Affirmative / Yes\r\n10-5: Repeat last transmission\r\n10-6: Stand-by\r\n10-7: Unavailable for calls\r\n10-8: Available for calls\r\n10-9: Suspect Lost (Usually followed by a 10-17 and last known 10-20)\r\n10-10: (Supervisors only) requesting activity update along with giving your current position\r\n10-12: Backup Required (Specify situation and location)\r\n10-13: Requesting specific unit (specify)\r\n10-17: Requesting description on the suspect\r\n10-20: Requesting Location\r\n10-22: Disregard last transmission\r\n10-30: Starting Patrol/Resuming patrol after Code 7\r\n10-31: Returning to Station\r\n10-50: Car accident\r\n10-55: Traffic Stop\r\n10-57 Victor: Vehicle pursuit.\r\n10-57 Foxtrot: Foot pursuit.\r\n10-66: Felony Stop\r\n10-88 Suspicious Person(s)\r\n10-99: Assignment complete (State condition and at what call)\r\n11-99: Officer requires help, Emergency\r\n \r\n \r\n \r\nStatus-codes:\r\nStatus 1: In Service\r\nStatus 2: Out of Service\r\n \r\nIdentity Codes:\r\nIC-1: White\r\nIC-2: Black\r\nIC-3: Latino or Mexican\r\nIC-4: Middle-Eastern\r\nIC-5: Asian\r\nIC-6: Unknown ethnicity.\r\n \r\n \r\nSituation codes:\r\nCode 0: Absolute emergency, drop everything you’re doing and respond immediately.\r\nCode 1: Non-emergency. If you\'re doing something, deal with it first. Respond without lights or sirens.\r\nCode 2: Non-emergency. If you\'re doing something, drop it and respond. Respond with lights only.\r\nCode 3: There is an emergency. Respond with lights and sirens.\r\nCode 4: No assistance required, situation under control.\r\nCode 5: All units stay out of <location>.\r\nCode 6: Out of car at <location>.\r\nCode 7: Meal break.\r\n \r\n \r\nCriminal Codes:\r\n148: Resisting Arrest\r\n187: Homicide\r\n207: Kidnapping\r\n211: Robbery\r\n240: Assault\r\n417: Brandishing a weapon\r\n459: Burglary\r\n487: Petty Theft\r\n602: Trespass/Fraud\n', NULL, 20),
(77, 'Black Market', 9450, 1, 'Ø¹Ø§Ø¦Ù„Ø© Ø§Ø® Ø¬Ø¯ÙŠØ¯', 'ÙØ§ØªÙ„ Ù„Ø§ ÙŠØ±Ø­Ù… Ø§Ø­Ø¯', 'Ù‚Ø§ØªÙ„ Ø¬ÙˆÙƒØ±', 'Ù‚Ø§ØªÙ„ Ù…Ø§Ø¬ÙˆØ±', 'Ù‚Ø§ØªÙ„ Ùˆ Ù‚Ø§Ù‡Ø± ÙŠØ§ ÙŠØ¶Ù‡Ø± ÙÙŠ ØµØ¨Ø§Ø­', 'Underboss', 'Boss', 'Godfather', '', '', '', '', '', '', '', '', 'Ø§Ø® ØµØºÙŠØ± ÙÙŠ Ø¹Ø§ØªØ¦Ù„Ù‡', 'Ø§Ø® Ù…ØªÙˆØ³Ø· ÙÙŠ Ø¹Ø§Ø¦Ù„Ù‡', 'Ø§Ø® Ø§ÙƒØ¨Ø± ÙÙŠ Ø¹Ø§Ø¦Ù„Ù‡', 'Ø²Ø¹ÙŠÙ… Ù…Ø§ÙÙŠØ§ Ø¨Ù„Ø§Ùƒ Ù…Ø§Ø±ÙƒØª', 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 'Welcome to the faction. /tuneradio 123.92', 'Colt + 2 ammopacks = 4k  - last price = 3.5k\n\nAmmo packs For Colt  500 Per one \n\n per 2 1000$\n\n...............................................................\nDeagle + 2ammopacks = 5k last price 4.5k\n\n 1 ammopacks 650$ \n\n 2 ammopacks 1200$\n......................................................\n\nMarjuana 1gram = 250$\n\n10 gram = 1000$\n\nHeroine 1gram = 150$\n\n10 gram = 800$\n\n..................................................\n', 'Colt + 2 ammopacks = 4k  - last price = 3.5k\n\nAmmo packs For Colt  500 Per one \n\n per 2 1000$\n\n...............................................................\nDeagle + 2ammopacks = 5k last price 4.5k\n\n 1 ammopacks 650$ \n\n 2 ammopacks 1200$\n......................................................\n\nMarjuana 1gram = 250$\n\n10 gram = 2500$\n\nHeroine 1gram = 150$\n\n10 gram = 800$\n\n..................................................\n\nDid You Sell ? type it Â¬\n1 Colt with 2 Magazines - Nikolai\n1Deagle with 7 Magazines - Nikolai\n2Grams of weed - Nikolai\n---------------------------------------------------\n\n\n', NULL, 20),
(81, '|| Fringe Devision ||', 999984, 2, 'Dynamic Rank #1', 'Dynamic Rank #2', 'Dynamic Rank #3', 'Dynamic Rank #4', 'Dynamic Rank #5', 'Dynamic Rank #6', 'Dynamic Rank #7', 'Dynamic Rank #8', 'Dynamic Rank #9', 'Dynamic Rank #10', 'Dynamic Rank #11', 'Dynamic Rank #12', 'Dynamic Rank #13', 'Dynamic Rank #14', 'Dynamic Rank #15', 'Dynamic Rank #16', 'Dynamic Rank #17', 'Dynamic Rank #18', 'Dynamic Rank #19', 'Dynamic Rank #20', 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 'Welcome to the faction.', '', NULL, NULL, 20),
(82, 'San Andreas Public Transport', 999989, 5, 'Dynamic Rank #1', 'Dynamic Rank #2', 'Dynamic Rank #3', 'Dynamic Rank #4', 'Dynamic Rank #5', 'Dynamic Rank #6', 'Dynamic Rank #7', 'Dynamic Rank #8', 'Dynamic Rank #9', 'Dynamic Rank #10', 'Dynamic Rank #11', 'Dynamic Rank #12', 'Dynamic Rank #13', 'Dynamic Rank #14', 'Dynamic Rank #15', 'Dynamic Rank #16', 'Dynamic Rank #17', 'Dynamic Rank #18', 'Dynamic Rank #19', 'Dynamic Rank #20', 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 'Welcome to the faction.', '', NULL, NULL, 20),
(83, '|| Blaze_AirPort ||', 999992, 2, 'Dynamic Rank #1', 'Dynamic Rank #2', 'Dynamic Rank #3', 'Dynamic Rank #4', 'Dynamic Rank #5', 'Dynamic Rank #6', 'Dynamic Rank #7', 'Dynamic Rank #8', 'Dynamic Rank #9', 'Dynamic Rank #10', 'Dynamic Rank #11', 'Dynamic Rank #12', 'Dynamic Rank #13', 'Dynamic Rank #14', 'Dynamic Rank #15', 'Dynamic Rank #16', 'Dynamic Rank #17', 'Dynamic Rank #18', 'Dynamic Rank #19', 'Dynamic Rank #20', 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 'Welcome to the faction.', '', NULL, NULL, 20),
(85, 'Ø§Ù„Ù…Ø¹Ø±Ø¶ Ø§Ù„Ù…Ø·ÙˆØ±', 0, 5, 'Dynamic Rank #1', 'Dynamic Rank #2', 'Dynamic Rank #3', 'Dynamic Rank #4', 'Dynamic Rank #5', 'Dynamic Rank #6', 'Dynamic Rank #7', 'Dynamic Rank #8', 'Dynamic Rank #9', 'Dynamic Rank #10', 'Dynamic Rank #11', 'Dynamic Rank #12', 'Dynamic Rank #13', 'Dynamic Rank #14', 'Dynamic Rank #15', 'Dynamic Rank #16', 'Dynamic Rank #17', 'Dynamic Rank #18', 'Dynamic Rank #19', 'Dynamic Rank #20', 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 'Welcome to the faction.', '', NULL, NULL, 20);

-- --------------------------------------------------------

--
-- Table structure for table `feedbacks`
--

CREATE TABLE `feedbacks` (
  `id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `from_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL DEFAULT 3,
  `comment` varchar(500) DEFAULT NULL,
  `date` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `force_apps`
--

CREATE TABLE `force_apps` (
  `id` int(11) NOT NULL,
  `account` int(11) DEFAULT NULL,
  `forceapp_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Save forceapped players information to keep them from resubm' ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `friends`
--

CREATE TABLE `friends` (
  `id` int(10) UNSIGNED NOT NULL,
  `friend` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `fuelpeds`
--

CREATE TABLE `fuelpeds` (
  `id` int(11) NOT NULL,
  `posX` float NOT NULL,
  `posY` float NOT NULL,
  `posZ` float NOT NULL,
  `rotZ` float NOT NULL,
  `interior` int(11) NOT NULL DEFAULT 0,
  `dimension` int(11) NOT NULL DEFAULT 0,
  `skin` int(3) DEFAULT 50,
  `name` varchar(50) NOT NULL,
  `deletedBy` int(11) DEFAULT 0,
  `shop_link` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fuelstations`
--

CREATE TABLE `fuelstations` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `interior` int(5) DEFAULT 0,
  `dimension` int(5) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `gates`
--

CREATE TABLE `gates` (
  `id` int(11) NOT NULL,
  `objectID` int(11) NOT NULL,
  `startX` float NOT NULL,
  `startY` float NOT NULL,
  `startZ` float NOT NULL,
  `startRX` float NOT NULL,
  `startRY` float NOT NULL,
  `startRZ` float NOT NULL,
  `endX` float NOT NULL,
  `endY` float NOT NULL,
  `endZ` float NOT NULL,
  `endRX` float NOT NULL,
  `endRY` float NOT NULL,
  `endRZ` float NOT NULL,
  `gateType` tinyint(3) UNSIGNED NOT NULL,
  `autocloseTime` int(4) NOT NULL,
  `movementTime` int(4) NOT NULL,
  `objectDimension` int(11) NOT NULL,
  `objectInterior` int(11) NOT NULL,
  `gateSecurityParameters` text DEFAULT NULL,
  `creator` varchar(50) NOT NULL DEFAULT '',
  `createdDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `adminNote` varchar(300) NOT NULL DEFAULT '',
  `triggerDistance` float DEFAULT NULL,
  `triggerDistanceVehicle` float DEFAULT NULL,
  `sound` varchar(50) DEFAULT 'metalgate'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `gates`
--

INSERT INTO `gates` (`id`, `objectID`, `startX`, `startY`, `startZ`, `startRX`, `startRY`, `startRZ`, `endX`, `endY`, `endZ`, `endRX`, `endRY`, `endRZ`, `gateType`, `autocloseTime`, `movementTime`, `objectDimension`, `objectInterior`, `gateSecurityParameters`, `creator`, `createdDate`, `adminNote`, `triggerDistance`, `triggerDistanceVehicle`, `sound`) VALUES
(4, 3055, 1588.5, -1637.8, 14.6, 0, 0, 0, 1588.5, -1640, 16.5, 270, 0, 0, 7, 50, 25, 0, 0, '1', 'MishaKonsta', '2014-02-06 14:14:12', 'LSPD Ворота парковки', 20, 20, 'metalgate'),
(5, 10184, 1534.1, -1451.4, 14.9, 0, 0, 270, 1535.2, -1451.7, 19.7, 0, 0, 270, 7, 50, 30, 0, 0, '1', 'Franco', '2014-02-06 00:07:28', 'Detectives Gates', NULL, NULL, 'metalgate'),
(6, 988, 2639.8, -2582.4, 13.7, 0, 0, 180, 2642.4, -2582.4, 13.7, 0, 0, 179.995, 3, 30, 20, 0, 0, '82', 'Weimy', '2014-07-10 09:34:02', 'TTR Gate #1', NULL, NULL, 'metalgate'),
(7, 988, 2634.3, -2582.4, 13.7, 0, 0, 179.995, 2630.2, -2582.4, 13.7, 0, 0, 179.995, 3, 30, 20, 0, 0, '82', 'Weimy', '2014-07-10 09:35:31', 'TTR Gate #2', NULL, NULL, 'metalgate'),
(8, 2949, 1584.12, -1638.07, 12.37, 0, 0, 270, 1582.65, -1638.07, 12.37, 0, 0, 270, 7, 50, 15, 0, 0, '1', 'MishaKonsta', '2015-01-08 05:24:24', 'LSPD Дверь', 10, 0, 'metalgate'),
(9, 968, 1544.7, -1630.9, 13.1, 0, 270, 270, 1544.7, -1630.7, 13, 0, 180, 270, 7, 40, 15, 0, 0, '1', 'Maxime', '2014-04-08 04:17:41', 'LSPD ex-gate', NULL, NULL, NULL),
(10, 976, 1643.6, -1718.3, 14.6, 0, 0, 90, 1643.6, -1711.22, 14.6, 0, 0, 90, 7, 40, 45, 0, 0, '20', 'MishaKonsta', '2014-02-07 09:14:05', 'LSN Gate', NULL, NULL, 'metalgate'),
(11, 1495, 249.4, -1725.85, 5113, 0, 0, 0, 249.399, -1725.85, 5113, 0, 0, 90, 3, 15, 30, 6, 1, '86', 'Tylerc010', '2014-02-07 21:20:20', 'LSN INT GATE - SET', NULL, NULL, 'metalgate'),
(12, 2634, 1384.7, 1466.5, 11.4, 0, 0, 180, 1383.6, 1467.5, 11.4, 0, 0, 90, 2, 0, 30, 1575, 45, 'underground123', 'Belgica', '2014-07-14 12:59:35', 'vaultcollins', NULL, NULL, 'metalgate'),
(13, 1495, 1371.8, 1458.9, 10.6, 0, 0, 0, 1371.8, 1458.9, 10.6, 0, 0, 270, 10, 20, 20, 249, 1, 'ClubTec', 'Exciter', '2014-08-27 14:29:14', 'Blueberry Factory', NULL, NULL, 'metalgate'),
(14, 2957, 2054.9, -1694.8, 14.2, 0, 0, 90, 2053.4, -1694.8, 15.5, 90, 0, 90, 2, 0, 30, 0, 0, '2616', 'Firebird', '2014-02-27 18:45:08', '8, Washington Street - Garage', NULL, NULL, NULL),
(17, 1569, 1391.8, 1490.2, 9.8, 0, 0, 180.495, 1391.8, 1490.2, 9.8, 0, 0, 270.495, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 15:54:17', 'LSFD int2', NULL, NULL, NULL),
(18, 985, 2680.1, -2565, 14.4, 0, 0, 0, 2687, -2565, 14.4, 0, 0, 0, 3, 15, 30, 0, 0, '82', 'BrukONE', '2014-11-10 09:51:46', 'RT Main Gate 1', 9, 9, 'metalgate'),
(19, 986, 2673.8, -2565, 14.4, 0, 0, 0, 2687.1, -2565, 14.4, 0, 0, 0, 3, 15, 30, 0, 0, '82', 'BrukONE', '2014-11-10 09:53:32', 'RT Main Gate 2', 9, 9, 'metalgate'),
(20, 969, 2543.7, 0.7, 25.2, 0, 0, 270, 2543.7, -8.3, 25.2, 0, 0, 270, 2, 30, 30, 0, 0, 'wutwutindabutt', 'Manjot', '2015-02-01 16:37:40', 'Zackary private', 10, 10, 'metalgate'),
(21, 989, 1964.3, -2189.8, 14.4, 0, 0, 106.745, 1968.8, -2189.8, 14.4, 0, 0, 106.743, 8, 50, 30, 0, 0, 'F=47 OR PILOT OR 64 OR 65', 'Exciter', '2014-02-25 20:49:58', 'LSIA Entrance Left', NULL, NULL, 'metalgate'),
(22, 989, 1958.8, -2189.8, 14.4, 0, 0, 106.743, 1954.3, -2189.8, 14.4, 0, 0, 106.743, 8, 50, 30, 0, 0, 'F=47 OR PILOT OR 64 OR 65', 'Exciter', '2014-02-25 20:52:15', 'LSIA Entrance Right', NULL, NULL, 'metalgate'),
(23, 980, -495.1, -562.8, 27.1, 0, 0, 180, -503.1, -562.8, 27.1, 0, 0, 180, 10, 0, 50, 0, 0, 'hydraStrike', 'Keksii', '2014-05-30 20:10:27', 'Flint County DragTrack2', 9, 9, 'metalgate'),
(24, 1536, 2088, 475.8, 0.8, 0, 0, 268, 2088, 475.8, 0.8, 0, 0, 0, 2, 0, 30, 1787, 2, 'Throttle', 'Belgica', '2014-07-30 13:51:30', '1, Mint Street1', NULL, NULL, 'metalgate'),
(25, 9625, 1725.5, -1142.2, 25.9, 0, 0, 270, 1725.5, -1142.2, 31.6, 0, 0, 270, 3, 50, 50, 0, 0, '65', 'Manjot', '2014-03-12 15:36:22', 'LSFD ex', NULL, NULL, NULL),
(26, 9625, 1733.8, -1142.2, 25.9, 0, 0, 270, 1733.8, -1142.2, 31.6, 0, 0, 270, 7, 50, 50, 0, 0, '2', 'MishaKonsta', '2014-03-12 15:38:38', 'Fire Deportament Gate', NULL, NULL, 'metalgate'),
(27, 9625, 1742.9, -1142.2, 25.9, 0, 0, 270, 1742.9, -1142.2, 31.6, 0, 0, 270, 3, 50, 50, 0, 0, '65', 'Manjot', '2014-03-12 15:40:32', 'LSFD ex3', NULL, NULL, NULL),
(28, 9625, 1751.1, -1142.2, 25.9, 0, 0, 270, 1751.1, -1142.2, 31.6, 0, 0, 270, 3, 50, 50, 0, 0, '65', 'Manjot', '2014-03-12 15:41:18', 'LSFD ex4', NULL, NULL, NULL),
(29, 9625, 1759.8, -1142.2, 25.9, 0, 0, 270, 1759.8, -1142.2, 31.6, 0, 0, 270, 3, 50, 50, 0, 0, '65', 'DutchLars', '2014-03-12 15:41:54', 'LSFD ex5', NULL, NULL, NULL),
(30, 9625, 1768, -1142.2, 25.9, 0, 0, 270, 1768, -1142.2, 31.6, 0, 0, 270, 3, 50, 50, 0, 0, '65', 'DutchLars', '2014-03-12 15:42:40', 'LSFD ex6', NULL, NULL, NULL),
(31, 9625, 1733.3, -1108.8, 25.9, 0, 0, 90, 1733.3, -1108.8, 31.6, 0, 0, 90, 3, 50, 50, 0, 0, '65', 'Err0r', '2014-04-08 04:40:04', 'LSFD ex7', NULL, NULL, NULL),
(32, 9625, 1723.9, -1108.8, 25.9, 0, 0, 90, 1723.9, -1108.8, 31.6, 0, 0, 90, 3, 50, 50, 0, 0, '65', 'Err0r', '2014-04-08 04:50:52', 'LSFD ex8', NULL, NULL, NULL),
(33, 1536, 2088, 472.8, 0.8, 0, 0, 89.995, 2088, 472.8, 0.8, 0, 0, 359.995, 2, 0, 30, 1787, 2, 'Throttle', 'Belgica', '2014-07-30 13:52:07', '1, Mint Street2', NULL, NULL, 'metalgate'),
(35, 2948, 1901.1, -2441.53, 15.03, 0, 0, 0, 1901.1, -2441.53, 15.03, 0, 0, 270, 7, 25, 20, 1806, 5, '59', 'Nadr', '2014-07-31 12:16:12', 'San Andreas County Jail', 3, NULL, NULL),
(36, 2948, 1901.1, -2443.45, 15.03, 0, 0, 180, 1901.1, -2443.4, 15.03, 0, 0, 270, 7, 25, 20, 1806, 5, '59', 'Nadr', '2014-07-31 12:16:40', 'San Andreas Count Jail', 3, NULL, NULL),
(37, 1569, 1897.33, -2418.2, 16.465, 0, 0, 270, 1897.33, -2418.2, 16.465, 0, 0, 180, 1, 30, 25, 1806, 5, '', 'Nadr', '2014-07-31 12:17:21', 'San Andreas County Jail', 3, NULL, NULL),
(38, 1566, -1792.95, 649.257, 960.55, 0, 0, 0, -1792.95, 649.257, 960.55, 0, 0, 270, 3, 30, 30, 617, 1, '65', 'Theno', '2014-03-13 08:22:40', 'LSFD - Internal Door', NULL, NULL, 'metalgate'),
(39, 3089, 1556, -1679.5, 64.8, 0, 0, 0, 1555.9, -1679.5, 64.8, 0, 0, 90, 7, 30, 30, 1225, 3, '50', 'Belgica', '2014-04-29 01:23:38', 'Court Door 1', NULL, NULL, 'metalgate'),
(40, 971, 1577.5, -1695.3, 60.2, 0, 0, 0, 1577.4, -1694.7, 67.5, 0, 0, 0, 7, 20, 20, 1225, 3, '50', 'Belgica', '2014-04-29 00:58:03', 'Celldoor 2', NULL, NULL, 'metalgate'),
(41, 3037, -401.5, -1443.3, 28.2, 0, 0, 90, -401.5, -1445.6, 30, 0, 90, 90, 2, 0, 40, 0, 0, 'niggerhatinme', 'CharChar', '2015-01-25 04:52:21', 'FCRG', 10, 10, 'metalgate'),
(42, 971, 961.2, -942.1, 39.2, 0, 0, 0, 971.2, -942.1, 39.2, 0, 0, 0, 10, 30, 50, 0, 0, 'hotc2015', 'BrukONE', '2014-10-17 20:33:05', 'elizabethstarks', NULL, NULL, 'metalgate'),
(43, 2948, 1892.8, -2446.7, 15.2, 0, 0, 270, 1892.8, -2446.7, 15.2, 0, 0, 180, 7, 25, 20, 1806, 5, '59', 'Nadr', '2014-07-31 12:17:49', 'San Andreas County Jail', 3, NULL, NULL),
(44, 2948, 1890.9, -2446.7, 15.2, 0, 0, 90, 1890.9, -2446.7, 15.2, 0, 0, 180, 7, 25, 20, 1806, 5, '59', 'Nadr', '2014-07-31 12:18:13', 'San Andreas County Jail', 3, NULL, NULL),
(45, 14843, 1912.8, -2418.3, 17.8, 0, 0, 0, 1910, -2418.3, 17.8, 0, 0, 0, 7, 50, 25, 1158, 10, '1', 'Franco', '2014-03-27 11:14:30', 'lspd de1', NULL, NULL, 'metalgate'),
(46, 1569, 1897.33, -2418.2, 16.465, 0, 0, 0, 1897.33, -2418.2, 16.465, 0, 0, -90, 7, 50, 25, 785, 2, '1', 'Franco', '2014-03-27 11:17:37', 'LSPD de2', NULL, NULL, 'metalgate'),
(47, 2948, 1901.1, -2441.53, 15.03, 0, 0, 0, 1901.1, -2441.53, 15.03, 0, 0, 90, 7, 50, 25, 785, 2, '1', 'Franco', '2014-03-27 11:27:16', 'LSPD de 3', NULL, NULL, 'metalgate'),
(48, 2948, 1901.1, -2443.45, 15.03, 0, 0, 180, 1901.1, -2443.45, 15.03, 0, 0, 90, 7, 50, 25, 785, 2, '1', 'Franco', '2014-03-27 11:29:50', 'LSPD de 4', NULL, NULL, 'metalgate'),
(49, 16773, 1385.4, 1820.7, 25, 0, 0, 90, 1385.4, 1820.7, 17, 0, 0, 90, 7, 30, 30, 17, 18, '56', 'AndreC', '2014-08-10 11:20:22', 'Cargo group int gate', 9, 9, 'metalgate'),
(50, 3095, -1346.2, 928.1, 809.2, 270, 0, 0, -1346.2, 924.7, 809.2, 270, 0, 0, 10, 10, 15, 2145, 1, 'Falafel69', 'Weedex', '2014-12-07 16:11:02', 'Warehouse Gate', NULL, NULL, NULL),
(51, 1496, 1564.1, -1662.7, 27.4, 0, 0, 0, 1564.1, -1662.7, 27.4, 0, 0, 270, 7, 20, 40, 0, 0, '1', 'CharChar', '2014-12-10 14:51:33', 'LSPD Roof Gate', 9, 9, 'metalgate'),
(52, 1497, 1933.03, -2397.94, 32.8, 0, 0, 0, 1933.03, -2397.94, 32.8, 0, 0, 90, 2, 50, 30, 1129, 5, 'phillipisthebest', 'Theno', '2014-06-05 14:33:14', 'Interior 1129 Internal Door', NULL, NULL, 'metalgate'),
(53, 988, 4002.14, 1930.38, 10.9375, 0, 0, 45, 3995.14, 1924.38, 10.9375, 0, 0, 45, 7, 30, 30, 0, 0, 'F=47 OR 170=FAA access card for flyUS', 'Exciter', '2014-08-19 10:47:18', 'San Tortuguilla', 9, 9, 'metalgate'),
(54, 5422, 2692.6, -1466, 1153.2, 0, 0, 89.75, 2692.6, -1466, 1156, 0, 0, 89.75, 3, 50, 30, 264, 56, '156', 'Theno', '2014-04-24 17:40:15', 'Court Evidence room', NULL, NULL, 'metalgate'),
(55, 971, 1568.5, -1695.3, 60.3, 0, 0, 0, 1568.5, -1695.3, 67.5, 0, 0, 0, 7, 20, 20, 1225, 3, '50', 'Belgica', '2014-04-29 00:59:06', 'Celldoor', NULL, NULL, 'metalgate'),
(56, 3089, 1565.6, -1674.7, 64.8, 0, 0, 270, 1565.6, -1674.7, 64.8, 0, 0, 178, 7, 30, 30, 1225, 3, '50', 'Belgica', '2014-04-29 01:16:17', 'Court Door 2', NULL, NULL, 'metalgate'),
(57, 3089, 1582.98, -1691.3, 62.2, 0, 0, 0, 1583.1, -1691.3, 62.3, 0, 0, 102, 7, 30, 30, 1225, 3, '50', 'Belgica', '2014-04-29 01:45:11', 'Court Door 3', NULL, NULL, 'metalgate'),
(58, 3089, 2700.5, -1466.2, 1152.5, 0, 0, 0, 2702, -1466.2, 1152.5, 0, 0, 52, 3, 30, 30, 264, 56, '156', 'Max1', '2014-04-29 02:01:30', 'Court Door 4', NULL, NULL, 'metalgate'),
(59, 9625, 1780.9, -1094.8, 25.9, 0, 0, 270, 1780.9, -1094.9, 31.2, 0, 0, 270, 3, 30, 30, 0, 0, '65', 'anumaz', '2014-04-29 16:44:42', 'FD Employee Parking', NULL, NULL, 'metalgate'),
(60, 2948, 1901.1, -2441.53, 15.03, 0, 0, 0, 1901.1, -2441.53, 15.03, 0, 0, 270, 7, 20, 13, 18, 10, '59', 'anumaz', '2014-07-25 02:11:30', 'SASD', 3, NULL, NULL),
(61, 2948, 1901.1, -2443.45, 15.03, 0, 0, 180, 1901.1, -2443.4, 15.03, 0, 0, 270, 7, 20, 13, 18, 10, '59', 'anumaz', '2014-07-25 02:16:51', 'SASD', 3, NULL, NULL),
(62, 1569, 1897.33, -2418.2, 16.465, 0, 0, 0, 1897.33, -2418.2, 16.465, 0, 0, 270, 1, 0, 13, 18, 10, '', 'Nadr', '2014-07-25 02:18:39', 'SASD', 3, NULL, NULL),
(63, 1569, 1395.8, 1490.2, 9.8, 0, 0, 179.744, 1395.8, 1490.2, 9.8, 0, 0, 269.744, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 15:54:44', 'LSFD int1', NULL, NULL, NULL),
(64, 1569, 1388.8, 1490.2, 9.8, 0, 0, 0.245, 1388.8, 1490.2, 9.8, 0, 0, 270.245, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:01:00', 'LSFD int3', NULL, NULL, NULL),
(65, 1569, 1392.8, 1490.2, 9.8, 0, 0, 359.995, 1392.8, 1490.2, 9.8, 0, 0, 270.995, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:01:30', 'LSFD int4', NULL, NULL, NULL),
(66, 1569, 1392.8, 1507, 9.8, 0, 0, 359.498, 1392.8, 1507, 9.8, 0, 0, 270.498, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:10:01', 'LSFD int5', NULL, NULL, NULL),
(67, 1569, 1395.8, 1507, 9.8, 0, 0, 179.248, 1395.8, 1507, 9.8, 0, 0, 270.248, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:10:32', 'LSFD int6', NULL, NULL, NULL),
(68, 1569, 1391.8, 1507, 9.8, 0, 0, 180.248, 1391.8, 1507, 9.8, 0, 0, 270.248, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:11:06', 'LSFD int7', NULL, NULL, NULL),
(69, 1569, 1388.8, 1507, 9.8, 0, 0, 359.5, 1388.8, 1507, 9.8, 0, 0, 270.5, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:11:59', 'LSFD int8', NULL, NULL, NULL),
(70, 1569, 1385.8, 1511.2, 9.8, 0, 0, 0, 1385.8, 1511.2, 9.8, 0, 0, 270, 3, 0, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:15:02', 'LSFD int9', NULL, NULL, NULL),
(71, 1569, 1393.8, 1511.2, 9.8, 0, 0, 0, 1393.8, 1511.2, 9.8, 0, 0, 90, 3, 30, 30, 617, 1, '65', 'Err0r', '2014-05-06 16:17:18', 'LSFD int10', NULL, NULL, NULL),
(72, 1569, 1397.9, 1511.2, 9.8, 0, 0, 0, 1397.9, 1511.2, 9.8, 0, 0, 270, 3, 0, 15, 617, 1, '65', 'Err0r', '2014-05-06 16:17:54', 'LSFD int11', NULL, NULL, NULL),
(73, 3037, -402.3, -1443.3, 26.9, 0, 0, 90, -402.3, -1445.5, 30, 0, 90, 90, 2, 0, 40, 0, 0, 'niggerhatinme', 'CharChar', '2015-01-25 04:53:01', 'FCRG', 10, 10, 'metalgate'),
(74, 1557, 1992.3, -2220.7, 13.2, 0, 0, 0, 1992.3, -2220.7, 13.2, 0, 0, 290, 3, 0, 20, 0, 0, '127', 'anumaz', '2014-07-06 08:40:39', 'LSIA - Aeroclub in', NULL, NULL, NULL),
(75, 1557, 1989.1, -2232.5, 13.2, 0, 0, 357.995, 1989.1, -2232.5, 13.2, 0, 0, 279.989, 3, 0, 20, 0, 0, '127', 'anumaz', '2014-07-06 08:41:41', 'LSIA - Aeroclub out', NULL, NULL, NULL),
(76, 2930, 2077, -2231.2, 15.2, 0, 0, 0, 2077, -2231.2, 15.2, 0, 0, 90, 8, 20, 20, 0, 0, 'F=47 OR PILOT OR 64 OR 65', 'Exciter', '2014-07-06 08:43:10', 'LSIA - Pilots entrance', 5, 5, 'metalgate'),
(77, 988, 2080.2, -2333, 13.6, 0, 0, 179.995, 2085.5, -2333, 13.6, 0, 0, 179.995, 8, 40, 30, 0, 0, 'F=47 OR 64 OR 65 OR 127', 'einschtein', '2014-07-06 08:44:52', 'LSIA - MIL area', NULL, NULL, 'metalgate'),
(78, 988, 1946.7, -2204.1, 13.6, 0, 0, 89.995, 1946.7, -2198.8, 13.6, 0, 0, 89.995, 8, 40, 30, 0, 0, 'F=47 OR PILOT OR 64 OR 65', 'einschtein', '2014-07-06 08:47:02', 'LSIA - Apron entrance', 9, 9, 'metalgate'),
(79, 969, -943.1, -1723.9, 76.6, 0, 0, 90, -943.1, -1733, 76.6, 0, 0, 90, 10, 40, 40, 0, 0, 'creamcorn', 'dfajoe', '2014-08-13 20:03:46', 'The McCullah Ranch', 12, 12, 'metalgate'),
(80, 3089, 1917.1, 100.2, 951.1, 0, 0, 0, 1918.6, 101.5, 951.1, 0, 0, 90, 7, 50, 30, 1225, 3, '1 50 59', 'Belgica', '2014-05-11 21:25:21', '', NULL, NULL, NULL),
(81, 3089, 1938.5, 88, 946.7, 0, 0, 0, 1940.1, 88.1, 946.7, 0, 0, 52, 7, 20, 20, 1225, 3, '50', 'Belgica', '2014-05-11 19:46:16', '', NULL, NULL, 'metalgate'),
(82, 2930, 1913.4, 89, 952.4, 0, 0, 0, 1913.4, 88.9, 949.7, 0, 0, 0, 7, 20, 20, 1225, 3, '1 50 59', 'Belgica', '2014-05-11 21:43:25', 'Marshal Office Gate', NULL, NULL, 'metalgate'),
(83, 2930, 1364.1, 382, 21.4, 0, 0, 337.497, 1364.1, 382, 21.4, 0, 0, 425, 7, 30, 20, 0, 0, '59', 'Nadr', '2015-01-28 01:29:36', 'SAHP Monty Station', 4, 5, 'metalgate'),
(84, 1553, 2094.5, -1310.8, 24.2, 0, 0, 0, 2092.6, -1310.8, 24.2, 0, 0, 0, 10, 0, 30, 0, 0, 'daughertyfgt', 'Lemonth', '2014-07-06 11:33:25', '2, Belview Road', NULL, NULL, 'metalgate'),
(85, 969, 841.9, -577, 15.6, 0, 0, 0, 841.9, -577, 11.6, 0, 0, 0, 8, 30, 30, 0, 0, '5=1597', 'Lemonth', '2014-05-14 17:41:19', 'Old IHMC legal gate', NULL, NULL, 'metalgate'),
(86, 3089, 2749.7, -2373.1, 819.6, 0, 0, 269.496, 2749.7, -2373.1, 819.6, 0, 0, 359.495, 3, 30, 15, 220, 2, '156', 'Nadr', '2014-05-15 07:19:15', 'SCOSA Gate 1', NULL, NULL, NULL),
(87, 3089, 2750.7, -2371.1, 819.6, 0, 0, 226.243, 2750.7, -2371.1, 819.6, 0, 0, 308.241, 3, 30, 15, 220, 2, '156', 'Nadr', '2014-05-15 07:20:10', 'SCOSA Gate 2', NULL, NULL, NULL),
(88, 3089, 2767.4, -2371.3, 819.6, 0, 0, 329.996, 2767.4, -2371.4, 819.6, 0, 0, 225.991, 3, 30, 15, 220, 2, '156', 'Nadr', '2014-05-15 07:20:46', 'SCOSA Gate 3', NULL, NULL, NULL),
(89, 980, 952.5, -1383.7, 13.5, 0, 0, 0, 952.5, -1383.7, 9.5, 0, 0, 0, 2, 0, 30, 0, 0, 'sacmastaff', 'BrukONE', '2014-05-15 14:50:30', 'Pasadena Blvd - Garage2', NULL, NULL, 'metalgate'),
(90, 980, 964.7, -1383.7, 13.5, 0, 0, 0, 964.7, -1383.7, 9.5, 0, 0, 0, 2, 0, 30, 0, 0, 'sacmastaff', 'BrukONE', '2014-05-15 14:52:12', 'Pasadena Blvd - Garage1', NULL, NULL, 'metalgate'),
(91, 2948, 1892.8, -2446.7, 15.2, 0, 0, 270, 1892.8, -2446.7, 15.2, 0, 0, 180, 7, 10, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:22:22', 'SASD', 3, NULL, NULL),
(92, 10575, 1549.9, 17.4, 25.1, 0, 0, 190, 1549.9, 17.4, 21.1, 0, 0, 190, 2, 0, 10, 0, 0, 'JalluK0la', 'Keksii', '2014-05-15 18:15:34', 'Red County - Wooden House', NULL, NULL, 'metalgate'),
(93, 11102, 161.19, -22.25, 2.67, 0, 0, 180, 161.19, -22.25, 6.6, 0, 0, 179.995, 2, 45, 45, 0, 0, 'anumaz', 'anumaz', '2014-05-17 04:17:32', 'Dennis Simmons\' garage', NULL, NULL, 'metalgate'),
(94, 985, 318.366, -1190.6, 75.671, 0, 0, 218, 315.688, -1192.59, 75.671, 0, 0, 217.996, 5, 30, 30, 0, 0, '2632', 'Kermoo', '2015-01-19 15:29:30', 'Mansion gate', 55, 55, 'metalgate'),
(95, 11102, 1554.3, -27.6, 22.5, 0, 0, 0, 1554.3, -27.6, 17.5, 0, 0, 0, 2, 0, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:48:21', 'Red County - Wooden House', NULL, NULL, 'metalgate'),
(96, 11102, 1524.3, 13.1, 23.5, 0, 0, 10.75, 1524.3, 13.1, 17.5, 0, 0, 10.75, 2, 0, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:55:27', 'test1', NULL, NULL, 'metalgate'),
(97, 11102, 1522.6, 23.4, 23.6, 0, 0, 10.75, 1522.6, 23.4, 17.6, 0, 0, 10.75, 2, 0, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:55:56', 'test2', NULL, NULL, 'metalgate'),
(98, 11102, 1545.5, -27.4, 22.5, 0, 0, 0, 1545.5, -27.4, 17.5, 0, 0, 0, 2, 0, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:56:25', 'test3', NULL, NULL, 'metalgate'),
(99, 11102, 1509.7, 10.4, 23.9, 0, 0, 11, 1509.7, 10.4, 17.9, 0, 0, 11, 2, 20, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:56:49', 'test4', NULL, NULL, 'metalgate'),
(100, 11102, 1508.1, 20.5, 23.9, 0, 0, 10.9973, 1508.1, 20.5, 17.9, 0, 0, 10.9973, 2, 20, 20, 0, 0, 'JalluK0la', 'Keksii', '2014-05-17 16:57:27', 'test5', NULL, NULL, 'metalgate'),
(101, 968, 2808.39, -1468.68, 16, 0, 90, 1, 2808.39, -1468.68, 16, 0, 180, 1, 8, 0, 30, 0, 0, '170 = 7335', 'Belgica', '2014-06-01 17:56:33', 'Tay Automobiles Parking ', NULL, NULL, 'metalgate'),
(102, 1569, 444.3, 93.5, 1060.3, 0, 0, 0, 442.8, 93.5, 1060.3, 0, 0, 0, 1, 30, 30, 550, 3, '19', 'Poffy', '2014-05-20 13:21:42', 'KingEnt 1', NULL, NULL, 'metalgate'),
(103, 2773, 1451.68, 1448.45, 26.5, 0, 0, 90, 1452.68, 1448.45, 26.5, 0, 0, 0, 2, 0, 30, 731, 22, 'entrance', 'anumaz', '2014-05-22 14:45:03', 'Peacock entrance', NULL, NULL, 'metalgate'),
(104, 1569, 472.7, 89.1, 1059.3, 0, 0, 0, 471.2, 89.1, 1059.3, 0, 0, 0, 2, 30, 30, 550, 3, 'SupDean', 'Keksii', '2014-05-20 13:27:05', 'KingEnt 2', NULL, NULL, 'metalgate'),
(105, 1569, 493.7, 89.2, 1059.3, 0, 0, 0, 492.3, 89.2, 1059.3, 0, 0, 0, 2, 30, 30, 550, 3, 'SupDean', 'Keksii', '2014-05-20 13:29:52', 'KingEnt 3', NULL, NULL, 'metalgate'),
(106, 1569, 463.1, 92, 1060.3, 0, 0, 270, 463.1, 93.4, 1060.3, 0, 0, 270, 2, 30, 30, 550, 3, 'SupDean', 'Keksii', '2014-05-20 13:31:10', 'KingEnt 4', NULL, NULL, 'metalgate'),
(107, 1569, 469.2, 90.7, 1060.3, 0, 0, 270, 469.2, 90.7, 1060.3, 0, 0, 90, 2, 30, 30, 550, 3, 'SupDean', 'Keksii', '2014-05-20 13:38:12', 'KingEnt 5', NULL, NULL, 'metalgate'),
(108, 2773, 1553.8, 1541.42, 19.8, 0, 0, 0, 1552.86, 1540.45, 19.8, 0, 0, 90, 2, 20, 20, 2015, 21, 'sushi', 'FAILCAKEZ', '2014-10-19 22:32:10', 'Restaurant pole', 5, 5, NULL),
(110, 1557, 1458.1, 1461.3, 26, 0, 0, 90, 1458.1, 1461.3, 26, 0, 0, 180, 2, 30, 30, 731, 22, 'pcprivate', 'Rilind', '2014-05-22 14:49:55', 'ElizabethStarks', NULL, NULL, NULL),
(111, 1557, 1458.1, 1464.3, 26, 0, 0, 270, 1458.1, 1464.3, 26, 0, 0, 180, 2, 30, 30, 731, 22, 'pcprivate', 'Rilind', '2014-05-22 14:50:53', 'ElizabethStarks', NULL, NULL, NULL),
(112, 2634, 1526, 1333.67, 12, 0, 0, 180, 1526.8, 1332.6, 12, 0, 0, 90, 8, 0, 90, 732, 24, '4=732', 'AndreC', '2014-05-22 15:03:53', 'Peacock vault', NULL, NULL, 'metalgate'),
(113, 1495, 1532.3, 1330.3, 10.3, 0, 0, 90, 1532.3, 1330.3, 10.3, 0, 0, 0, 2, 30, 30, 732, 24, 'test', 'anumaz', '2014-05-22 15:08:56', 'Peacock vault 1', NULL, NULL, 'metalgate'),
(114, 1495, 1532.4, 1325.8, 10.3, 0, 0, 90, 1532.4, 1325.8, 10.3, 0, 0, 0, 2, 30, 30, 732, 24, 'test', 'anumaz', '2014-05-22 15:10:21', 'Peacock vault 2', NULL, NULL, 'metalgate'),
(115, 1495, 1532.4, 1321.2, 10.3, 0, 0, 90, 1532.4, 1321.2, 10.3, 0, 0, 0, 2, 30, 30, 732, 24, 'test', 'anumaz', '2014-05-22 15:10:45', 'Peacock vault 3', NULL, NULL, 'metalgate'),
(116, 1495, 1532.4, 1316.5, 10.3, 0, 0, 90, 1532.4, 1316.5, 10.3, 0, 0, 0, 2, 30, 30, 732, 24, 'test', 'anumaz', '2014-05-22 15:11:11', 'Peacock vault 4', NULL, NULL, 'metalgate'),
(117, 8673, -87.3, -1126.2, -5, 0, 0, 70.5, -87.3, -1126.2, -5, 0, 0, 70.5, 2, 0, 300, 0, 0, 'rshaul', 'Nadr', '2014-06-08 12:39:32', 'RS HAUL', NULL, NULL, 'metalgate'),
(118, 3037, -401.5, -1443.2, 26.9, 0, 0, 90, -401.5, -1445.6, 30, 0, 90, 90, 2, 0, 40, 0, 0, 'niggerhatinme', 'CharChar', '2015-01-25 04:53:39', 'FCRG', 10, 10, 'metalgate'),
(119, 980, -483.6, -562.8, 27.1, 0, 0, 179.997, -475.6, -562.8, 27.1, 0, 0, 179.997, 10, 0, 50, 0, 0, 'hydraStrike', 'Keksii', '2014-05-30 20:19:57', 'Flint County DragTrack1', 9, 9, 'metalgate'),
(120, 2930, 1913.8, -2449.9, 16.6, 0, 0, 2, 1913.8, -2448.3, 16.6, 0, 0, 0.25, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 12:18:50', 'San Andreas County Jail', 3, NULL, 'metalgate'),
(121, 1553, 2222.2, -1230.7, 24.2, 0, 0, 0, 2220.9, -1229.4, 24.2, 0, 0, -90, 8, 0, 30, 0, 0, '170=65891', 'Belgica', '2014-07-31 12:45:30', 'mabako1', NULL, NULL, 'metalgate'),
(122, 1569, 222.13, 79.3, 1004, 0, 0, 90, 222.2, 79.37, 1004, 0, 0, 180, 7, 0, 20, 624, 6, '1', 'Jevi', '2014-08-11 15:28:35', '', 4, NULL, 'metalgate'),
(123, 975, 1092.3, -628.4, 111.8, 0, 14, 353.25, 1091.6, -628.4, 108, 0, 14, 353.25, 10, 25, 25, 0, 0, 'Almeida', 'Lewis', '2015-01-29 14:48:13', 'Almeida House Gate', 10, 10, 'metalgate'),
(124, 968, 1578.8, 711.1, 10.6, 1, 270, 270, 1578.8, 711.1, 10.6, 1, 180, 270, 8, 30, 30, 0, 0, 'F=59 OR F=1', 'anumaz', '2014-09-12 00:07:09', 'PD-SD training grounds', 9, 9, 'metalgate'),
(125, 980, 984.6, -1585.1, 15.3, 0, 0, 0, 984.6, -1585.1, 9.7, 0, 0, 0, 8, 35, 30, 0, 0, '170=556847', 'Belgica', '2014-09-26 12:34:10', 'Panopticon Avenue Garage', NULL, NULL, 'metalgate'),
(126, 2774, 1101.3, -630, 102.1, 0, 0, 0, 1101.3, -630, 102.1, 0, 0, 0, 10, 25, 25, 0, 0, 'Almeida', 'Lewis', '2015-01-29 14:50:18', 'Almeida House', 10, 10, NULL),
(127, 3037, -402.3, -1443.4, 28.2, 0, 0, 90, -402.3, -1445.6, 30, 0, 90, 90, 2, 0, 40, 0, 0, 'niggerhatinme', 'CharChar', '2015-01-25 04:54:05', 'FCRG', 10, 10, 'metalgate'),
(128, 4084, -2104.04, -2404.82, 32.24, 0, 0, 321, -2104.04, -2404.82, 35.62, 0, 0, 321, 10, 0, 40, 0, 0, 'bratva', 'BrukONE', '2015-01-25 12:39:29', 'Bratva', 15, 15, 'metalgate'),
(129, 971, 923.55, -1216.5, 17.7, 0, 0, 90, 923.2, -1216.2, 11.4, 0, 0, 90.2, 5, 60, 25, 0, 0, '1', 'Kermoo', '2014-06-18 00:56:59', 'Gated Community in Vinewood', NULL, NULL, 'metalgate'),
(130, 971, 923.55, -1226.3, 17.7, 0, 0, 90, 923.3, -1226.8, 11.4, 0, 0, 270.25, 10, 50, 25, 0, 0, 'VinewoodGardens', 'Mirazoka', '2014-06-18 00:59:11', 'Gated Community in Vinewood', NULL, NULL, 'metalgate'),
(131, 2948, 1890.9, -2446.7, 15.2, 0, 0, 90, 1890.9, -2446.7, 15.2, 0, 0, 180, 7, 10, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:24:45', 'SASD', 3, NULL, NULL),
(132, 2930, 1917, -2462.4, 15.2, 0, 0, 270, 1915.4, -2462.4, 15.2, 0, 0, 270, 7, 0, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:26:27', 'SASD', 2, NULL, 'metalgate'),
(133, 2930, 1912.5, -2462.4, 15.2, 0, 0, 270, 1910.9, -2462.4, 15.2, 0, 0, 270, 7, 0, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:28:06', 'SASD', 2, NULL, 'metalgate'),
(134, 1569, 1615.07, 1569.4, 9.9, 0, 0, 0, 1615.07, 1569.4, 9.9, 0, 0, 90, 3, 40, 20, 6, 24, '86', 'Lewis', '2014-06-11 18:32:57', 'LSN Door', NULL, NULL, NULL),
(135, 1536, 1420.5, 1394.8, 12.3, 0, 0, 270, 1420.5, 1394.8, 12.3, 0, 0, 347.061, 3, 35, 18, 785, 2, '64', 'Ron', '2014-06-12 17:20:58', 'OCI Main door', NULL, NULL, NULL),
(136, 14843, 1432, 1418.2, 15, 0, 0, 0, 1433.5, 1418.2, 15, 0, 0, 0, 3, 30, 30, 785, 2, '64', 'Theno', '2014-06-12 17:21:19', 'OCI Cell door', NULL, NULL, 'metalgate'),
(137, 971, 2071.3, -2533.8, 25.7, 0, 0, 90, 2071.3, -2525, 25.7, 0, 0, 90, 10, 30, 30, 1123, 56, 'Metro - I', 'Sloth', '2014-06-12 20:04:15', 'PD Metro Garage', NULL, NULL, NULL),
(138, 3089, 1810.07, -2499.68, 13.888, 0, 0, 90, 1810.07, -2499.68, 13.888, 0, 0, 180, 10, 20, 10, 1529, 23, 'Metro - I', 'Sloth', '2014-06-12 20:16:50', 'Metro Int Door 1', NULL, NULL, NULL),
(139, 3089, 1810.07, -2509.68, 13.899, 0, 0, 90, 1810.07, -2509.68, 13.899, 0, 0, 180, 10, 20, 10, 1529, 23, 'Metro - I', 'Sloth', '2014-06-12 20:22:54', 'Metro Int Door 2', NULL, NULL, NULL),
(140, 3089, 1799.59, -2478.67, 13.89, 0, 0, 0, 1799.59, -2478.67, 13.89, 0, 0, -90, 10, 20, 10, 1529, 23, 'Metro - I', 'Sloth', '2014-06-12 20:24:44', 'Metro Int Door 3', NULL, NULL, NULL),
(141, 11313, 1574.1, 1582.6, 20.1, 0, 0, 90, 1574, 1584.7, 21.584, 0, -90, 90, 7, 0, 30, 1220, 25, '56', 'AndreC', '2014-06-14 14:22:16', 'Cargo Group Interior', NULL, NULL, 'metalgate'),
(143, 2930, 923.6, -1209.1, 18.6, 0, 0, 0, 923.6, -1209.1, 18.6, 0, 0, 260, 10, 45, 15, 0, 0, 'VinewoodGardens', 'Mirazoka', '2014-06-18 01:13:58', 'Gated Community in Vinewood  - Foot Entrance', NULL, NULL, 'metalgate'),
(144, 2930, 923.53, -1209.1, 18.6, 0, 0, 180, 923.53, -1209.1, 18.6, 0, 0, 180, 10, 0, 0, 0, 0, 'VinewoodGardens', 'Mirazoka', '2014-06-18 01:15:27', 'Gated Community in Vinewood - Null', NULL, NULL, 'metalgate'),
(145, 1569, 246.94, 72.55, 1002.6, 0, 0, 0, 246.94, 72.55, 1002.6, 0, 0, 90, 7, 0, 20, 624, 6, '1', 'Jevi', '2014-08-11 15:47:32', '', 4, NULL, NULL),
(146, 1569, 248.1, 76.4, 1002.6, 0, 0, 270, 248.05, 76.34, 1002.6, 0, 0, 0, 7, 0, 20, 264, 6, '1', 'Jevi', '2014-08-11 15:54:54', '', 4, NULL, NULL),
(147, 1569, -2223.1, 135.4, 1034.4, 0, 0, 91.999, -2223.1, 135.4, 1034.4, 0, 0, 181.994, 2, 30, 30, 414, 6, 'Snipes316', 'Belgica', '2014-06-26 14:21:06', 'Vinewood Pawns - Interior', NULL, NULL, NULL),
(148, 2930, 1512.84, 1497.22, 25.9, 0, 0, 0, 1512.84, 1497.22, 25.9, 0, 0, 270, 2, 30, 30, 993, 29, 'IHMC', 'DutchLars', '2014-07-01 11:49:35', 'IHMC Club House ', NULL, NULL, 'metalgate'),
(149, 2933, 2446.6, -1461.2, 24.7, 0, 0, 270, 2449, -1461.2, 27.45, 90, 0, 269.995, 8, 0, 30, 0, 0, '170=7335', 'Belgica', '2014-07-01 12:46:01', 'CarWash Front', NULL, NULL, 'metalgate'),
(150, 988, 2506.9, -1457.6, 23.9, 0, 0, 90, 2506.9, -1467.1, 23.9, 0, 0, 90, 8, 0, 30, 0, 0, '170=7335', 'Belgica', '2014-07-01 12:49:09', 'CarWash Back Right', NULL, NULL, 'metalgate'),
(151, 988, 2506.8, -1463, 23.9, 0, 0, 90, 2506.8, -1467.1, 23.9, 0, 0, 90, 8, 0, 30, 0, 0, '170=7335', 'Belgica', '2014-07-01 12:50:13', 'Carwash Back Left', NULL, NULL, 'metalgate'),
(152, 3095, 2457.6, -1461.3, 27.1, 0, 0, 0, 2457.8, -1461.2, 24, 0, 0, 0, 2, 0, 100, 0, 0, '241996a', 'Belgica', '2014-07-01 12:51:22', 'Crusher', NULL, NULL, 'metalgate'),
(153, 1569, -62.57, 129.31, 1007.2, 0, 0, 90, -62.57, 129.31, 1007.2, 0, 0, 180, 7, 30, 20, 1614, 3, '1 or 59', 'Nadr', '2014-11-29 16:13:45', 'Training Grounds', 4, NULL, NULL),
(154, 1553, 2097.3, -1310.8, 24.2, 0, 0, 0, 2099.4, -1310.8, 24.2, 0, 0, 0, 10, 0, 30, 0, 0, 'daughertyfgt', 'Lemonth', '2014-07-06 11:34:11', '2, Belview Road2', NULL, NULL, 'metalgate'),
(155, 2930, 1908, -2462.4, 15.2, 0, 0, 270, 1906.4, -2462.4, 15.2, 0, 0, 270, 7, 0, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:30:09', 'SASD', 2, NULL, 'metalgate'),
(156, 2930, 1913.8, -2449.9, 16.6, 0, 0, 2, 1913.8, -2448.3, 16.6, 0, 0, 0.25, 7, 0, 13, 18, 10, '59', 'Nadr', '2014-07-25 02:31:49', 'SASD', 2, NULL, 'metalgate'),
(157, 3037, -261.6, -2169.4, 30.3, 0, 0, 56, -261.6, -2169.4, 26.1, 0, 0, 55.997, 7, 30, 20, 0, 0, '59', 'Nadr', '2014-11-10 00:03:09', 'SAHP Gate 1', 7, 9, 'metalgate'),
(158, 974, 1896.5, -2446.6, 19.1, 0, 0, 0, 1896.5, -2446.6, 20.3, 0, 0, 0, 7, 0, 30, 18, 10, '59', 'Nadr', '2014-07-25 03:55:24', 'SASD', 5, NULL, 'metalgate'),
(159, 10184, 1905, -2428.9, 16.9, 0, 0, 357.995, 1905.1, -2427.9, 21.9, 0, 0, 357.995, 7, 45, 40, 2248, 21, '1 or 50 or 59', 'Nadr', '2014-12-01 01:41:27', 'PD/HP/CoSA Impound', 4, 7, 'metalgate'),
(160, 1553, 2225, -1230.7, 24.2, 0, 0, 0, 2226.3, -1229.4, 24.2, 0, 0, 90, 8, 0, 30, 0, 0, '170=65891', 'Belgica', '2014-07-31 12:45:54', 'mabako2', NULL, NULL, 'metalgate'),
(161, 1553, 2050.5, -1126, 24.2, 0, 0, 0, 2047.5, -1126, 24.2, 0, 0, 0, 10, 40, 40, 0, 0, 'rip187', 'Nadr', '2014-07-26 17:23:43', 'Park Avenue 1 - Glenpark', 5, 7, NULL),
(162, 1553, 2053.3, -1126, 24.2, 0, 0, 0, 2056.3, -1126, 24.2, 0, 0, 0, 10, 40, 40, 0, 0, 'rip187', 'Nadr', '2014-07-26 17:25:34', 'Park Avenue 1 - Glenpark (2)', 5, 7, NULL),
(163, 1569, 1394, 1843.5, 13.86, 0, 0, 0, 1394.1, 1843.5, 13.86, 0, 0, 90, 7, 0, 20, 624, 6, '1', 'Franco', '2014-08-11 18:37:29', '', 4, NULL, NULL),
(164, 2930, 1918.4, -2455, 16.5, 0, 0, 90, 1916.7, -2455, 16.5, 0, 0, 90, 7, 25, 20, 18, 10, '59', 'Nadr', '2014-07-28 08:09:19', 'SASD', 3, NULL, 'metalgate'),
(165, 2930, 1920.1, -2455, 16.5, 0, 0, 90, 1920.1, -2455, 16.5, 0, 0, 90, 7, 25, 20, 18, 10, '59', 'Nadr', '2014-07-28 08:17:30', 'SASD', 3, NULL, 'metalgate'),
(166, 2930, 1914.35, -2446.8, 16.5, 0, 0, 90, 1912.7, -2446.8, 16.5, 0, 0, 90, 7, 25, 20, 18, 10, '59', 'Nadr', '2014-07-28 08:26:15', 'SASD', 3, NULL, NULL),
(167, 2930, 1916, -2446.8, 16.5, 0, 0, 90, 1916, -2446.8, 16.5, 0, 0, 90, 7, 25, 20, 18, 10, '59', 'Nadr', '2014-07-28 08:30:53', 'SASD', 3, NULL, 'metalgate'),
(168, 2930, 1914, -2442.4, 17.8, 0, 0, 0.75, 1914, -2443.8, 17.8, 0, 0, 0.75, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:05:06', 'San Andreas County Jail', 3, NULL, 'metalgate'),
(169, 2930, 1914, -2440.7, 17.8, 0, 0, 0.747, 1914, -2439.3, 17.8, 0, 0, 0.747, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:05:36', 'San Andreas County Jail', 3, NULL, 'metalgate'),
(170, 2930, 1914, -2443.45, 19.5, 87.984, 277.122, 84.371, 1914, -2443.45, 19.5, 87.984, 277.122, 84.371, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:06:08', 'San Andreas County Jail', 3, NULL, NULL),
(171, 2930, 1916.4, -2446.7, 16.6, 0, 0, 270.497, 1918, -2446.7, 16.6, 0, 0, 270.497, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:06:31', 'San Andreas County Jail', 3, NULL, 'metalgate'),
(172, 2930, 1914.7, -2446.7, 16.6, 0, 0, 270.494, 1914.7, -2446.7, 16.6, 0, 0, 270.494, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:06:58', 'San Andreas County Jail', 3, NULL, NULL),
(173, 2930, 1920.1, -2455, 16.6, 0, 0, 270.494, 1918.5, -2455, 16.6, 0, 0, 270.494, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:08:18', 'San Andreas County Jail', 3, NULL, 'metalgate'),
(174, 2930, 1921.8, -2455, 16.6, 0, 0, 270.494, 1921.8, -2455, 16.6, 0, 0, 270.494, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:08:38', 'San Andreas County Jail', 3, NULL, NULL),
(175, 2930, 1914.05, -2446.1, 19.5, 87.984, 277.119, 84.37, 1914.05, -2446.1, 19.5, 87.984, 277.119, 84.37, 3, 30, 20, 1806, 5, '64 112', 'Nadr', '2014-07-31 13:09:19', 'San Andreas County Jail', 3, NULL, NULL),
(176, 1742, 1395.3, 1802.85, 9.8, 0, 0, 179.995, 1395.9, 1804, 9.8, 0, 0, 90, 10, 20, 20, 1796, 10, 'usa', 'Mirazoka', '2014-07-31 15:23:25', '', NULL, NULL, 'metalgate'),
(177, 10154, 1911.67, -2295.73, 15.37, 0, 0, 0, 1911.67, -2295.73, 17, 0, 90, 0, 7, 30, 20, 1081, 56, '59', 'Nadr', '2014-08-01 20:43:24', 'SASD', 5, 6, 'metalgate'),
(178, 10154, 1911.67, -2290.2, 15.37, 0, 0, 0, 1911.67, -2290.2, 15.37, 0, 0, 0, 7, 30, 20, 1081, 56, '59', 'Maxime', '2014-08-01 20:45:24', 'SASD', 5, 6, 'metalgate'),
(179, 1569, 2148.2, -1415.9, 292.69, 0, 0, 0, 2148.2, -1415.9, 292.69, 0, 0, 85, 7, 25, 20, 1397, 2, '59', 'Nadr', '2014-08-01 21:17:46', 'SASD', 4, NULL, NULL),
(180, 976, 1283.2, -621.8, 102, 357.75, 0.25, 31.01, 1290, -617.8, 102, 357.75, 0.25, 31.01, 10, 0, 45, 0, 0, 'snipesmotherfuckinggate', 'BlueBerry', '2014-11-14 11:28:02', 'Snipes', 9, 9, 'metalgate'),
(181, 968, 2702.4, -2534.1, 13.3, 0, 270, 0, 2702.4, -2534.1, 13.3, 0, 182, 0, 3, 0, 30, 0, 0, '82', 'BrukONE', '2014-11-10 09:35:40', 'RT Auction Lot 1', 9, 9, NULL),
(182, 968, 2736.8, -2564.3, 13.3, 0, 270, 0, 2736.8, -2564.3, 13.3, 0, 182, 0, 3, 0, 30, 0, 0, '82', 'BrukONE', '2014-11-10 09:38:11', 'RT Auction Lot 2', 9, 9, 'metalgate'),
(183, 985, 2664.3, -2688.8, 14.4, 0, 0, 270, 2664.3, -2696.6, 14.4, 0, 0, 270, 3, 15, 30, 0, 0, '82', 'BrukONE', '2014-11-10 10:48:01', 'RT Inside Gate', 9, 9, 'metalgate'),
(184, 969, 1342.4, -912.1, 34.9, 0, 0, 179.995, 1335, -912.09, 34.9, 0, 0, 180, 8, 0, 30, 0, 0, '170=7636', 'Belgica', '2014-08-05 12:37:15', 'Peckers Pawnshop', NULL, NULL, 'metalgate'),
(185, 988, -265.7, -255.8, 999.8, 0, 0, 270, -265.7, -260.8, 999.8, 0, 0, 270, 2, 0, 30, 1793, 38, 'pooop', 'BrukONE', '2014-08-07 08:08:14', '37 Auto\'s Building Facility', 30, 30, 'metalgate'),
(186, 986, 2676, -2704.8, 14.4, 0, 0, 180, 2684, -2704.8, 14.4, 0, 0, 180, 3, 15, 30, 0, 0, '82', 'BrukONE', '2014-11-09 18:19:15', 'RT Back Gate 1', 9, 9, 'metalgate'),
(187, 985, 2668.1, -2704.8, 14.4, 0, 0, 180, 2660.1, -2704.8, 14.4, 0, 0, 180, 3, 15, 30, 0, 0, '82', 'BrukONE', '2014-11-09 18:20:03', 'RT Back Gate 2', 9, 9, 'metalgate'),
(189, 1569, 1577.3, -1637.33, 12.54, 0, 0, 90, 1577.3, -1637.33, 12.54, 0, 0, 180, 7, 30, 20, 0, 0, '1', 'Lemonth', '2015-01-09 16:03:19', 'LSPD Side Door', 5, 0, 'metalgate'),
(190, 988, 1386.9, 1328.99, 21.6, 0, 0, 270, 1386.9, 1324, 21.6, 0, 0, 269.995, 2, 100, 30, 1810, 3, 'rafiko', 'Belgica', '2014-08-09 07:38:50', 'IdlewoodMall', NULL, NULL, 'metalgate'),
(191, 988, 1386.8, 1334.4, 21.6, 0, 0, 269.995, 1386.8, 1323.99, 21.6, 0, 0, 269.995, 2, 100, 30, 1810, 3, 'rafiko', 'Belgica', '2014-08-09 07:39:28', 'IdlewoodMall2', NULL, NULL, 'metalgate'),
(192, 1569, 1387.6, 1820.3, 12.45, 0, 0, 270, 1387.6, 1820.2, 12.45, 0, 0, 0, 7, 10, 20, 624, 6, '1', 'Lewis', '2014-08-11 18:39:39', '', 4, NULL, NULL),
(193, 986, 324.606, -1185.66, 75.671, 0, 0, 218.726, 326.953, -1183.72, 75.671, 0, 0, 218.721, 5, 30, 30, 0, 0, '2632', 'Kermoo', '2015-01-19 15:31:53', '', 55, 55, 'metalgate'),
(194, 988, -113.5, 173.6, 1016.1, 0, 0, 88, -113.5, 179.6, 1016.1, 0, 0, 88, 2, 0, 30, 1861, 38, '37a', 'Belgica', '2014-08-12 08:24:22', '37 Auto\'s (Int 1861)', NULL, NULL, 'metalgate'),
(195, 2885, 1064.4, -309.3, 78.49, 0, 0, 0, 1064.4, -309.3, 72.99, 0, 0, 0, 5, 0, 30, 0, 0, '1996', 'Kermoo', '2014-08-15 20:24:33', 'Hiltop Farms', 9, 9, 'metalgate'),
(196, 968, 391.6, 2553.94, 16.3, 0, 90, 0, 391.6, 2553.94, 16.11, 0, 160, 0, 10, 0, 30, 0, 0, 'hydraStrike', 'Keksii', '2014-08-13 19:11:27', 'Drag Track Bone County', 5, 5, 'metalgate'),
(197, 968, 427.9, 2504.4, 16.2, 0, 90, 180, 427.9, 2504.4, 16.2, 0, 160, 180, 10, 0, 30, 0, 0, 'hydraStrike', 'Keksii', '2014-08-13 19:13:31', 'Drag Track Bone County', 5, 5, 'metalgate'),
(198, 968, 17, 2504.6, 16.2, 355, 270, 0, 17, 2504.6, 16.11, 355, 200, 0, 10, 0, 30, 0, 0, 'hydraStrike', 'Keksii', '2014-08-13 19:19:30', 'Drag Track Bone County', 5, 5, 'metalgate'),
(199, 968, 17, 2484, 16.2, 355, 270, 0, 17, 2484, 16.12, 355, 200, 0, 10, 0, 30, 0, 0, 'hydraStrike', 'Keksii', '2014-08-13 19:23:05', 'Drag Track Bone County', 5, 5, 'metalgate'),
(200, 988, 4006.14, 1934.38, 10.9375, 0, 0, 45, 4010.14, 1938.38, 10.9375, 0, 0, 45, 8, 30, 30, 0, 0, 'F=47 OR 170=FAA access card for flyUS', 'Exciter', '2014-08-19 10:50:42', 'San Tortuguilla 2', 9, 9, 'metalgate'),
(201, 1495, 1652.2, -2291.4, 1276, 0, 0, 180, 1652.2, -2291.4, 1276, 0, 0, 90, 8, 0, 20, 2337, 4, 'F=47 OR 170=FAA access card for flyUS', 'Exciter', '2014-08-25 12:41:52', 'LSIA terminal - Gate C', NULL, NULL, NULL),
(202, 1495, 1673, -2291.4, 1276, 0, 0, 0, 1673, -2291.4, 1276, 0, 0, 90, 8, 0, 20, 2337, 4, 'F=47 OR 170=FAA access card for flyUS', 'Exciter', '2014-08-25 12:43:47', 'LSIA terminal - Gate D', NULL, NULL, NULL),
(203, 1495, 1694.1, -2291.2, 1276, 0, 0, 0, 1694.1, -2291.2, 1276, 0, 0, 90, 8, 0, 20, 2337, 4, 'F=47 OR 170=FAA access card for flyUS', 'Exciter', '2014-08-25 12:45:56', 'LSIA terminal - Gate E', NULL, NULL, NULL),
(204, 985, -1041.04, -587.749, 31.9592, 0, 0, 0, -1041.04, -587.749, 25, 0, 0, 0, 8, 30, 30, 0, 0, 'F=59 OR F=1 OR F=50', 'Err0r', '2014-08-29 12:22:25', 'Prison EXT gate 2', 20, 20, 'metalgate'),
(205, 2930, -980.615, -655.193, 34.0157, 0, 0, 270, -980.615, -655.193, 34.0157, 0, 0, 0, 8, 30, 30, 0, 0, 'F=59 OR F=1 OR F=50', 'Nadr', '2014-08-29 12:24:45', 'Prison EXT gate 3', 3, 9, 'metalgate'),
(206, 971, -1112.86, -677.301, 32.9681, 0, 0, 359.742, -1112.86, -677.301, 25, 0, 0, 359.742, 8, 30, 30, 0, 0, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:30:02', 'Prison EXT gate 4', 3, 9, 'metalgate'),
(207, 971, -1043.83, -744.119, 32.9681, 0, 0, 359.742, -1043.83, -744.119, 25, 0, 0, 359.742, 8, 30, 30, 0, 0, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:31:36', 'Prison EXT gate 5', 3, 9, 'metalgate'),
(208, 2930, -1071.44, -690.959, 33.6659, 0, 0, 270, -1071.44, -690.959, 33.6659, 0, 0, 0, 8, 30, 30, 0, 0, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:32:57', 'Prison EXT gate 6', 3, 9, 'metalgate'),
(209, 2930, -1023.91, -691.882, 33.6659, 0, 0, 270, -1023.91, -691.882, 33.6659, 0, 0, 0, 8, 30, 30, 0, 0, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:33:46', 'Prison EXT gate 7', 3, 9, 'metalgate'),
(210, 2930, 1498.29, 1532.13, 12.6085, 0, 0, 0, 1498.29, 1532.13, 12.6085, 0, 0, 90, 8, 30, 30, 861, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:41:13', 'Prison INT Eating Hall 1', 3, 9, 'metalgate'),
(211, 2930, 1438.72, 1542.06, 12.4966, 0, 0, 0, 1438.72, 1542.06, 12.4966, 0, 0, 90, 8, 30, 30, 881, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 12:43:24', 'Prison INT Christian 1', 3, 9, 'metalgate'),
(212, 2930, 1436.06, 1544.14, 12.4966, 0, 0, 90, 1436.06, 1544.14, 12.4966, 0, 0, 0, 8, 0, 30, 881, 3, 'F=59 OR 64=prison access', 'tomtiger11', '2014-08-29 12:44:26', 'Prison INT Christian 2', 3, 9, 'metalgate'),
(213, 2930, 1410.27, 1543.9, 12.4754, 0, 0, 90, 1410.27, 1543.9, 12.4754, 0, 0, 0, 8, 0, 30, 881, 3, 'F=59 OR 64=prison access', 'tomtiger11', '2014-08-29 12:45:20', 'Prison INT Christian 3', 3, 9, 'metalgate'),
(214, 1569, 1468.66, 1546.02, 12.4531, 0, 0, 0, 1468.66, 1546.02, 12.4531, 0, 0, 90, 8, 30, 30, 812, 3, 'F=59', 'anumaz', '2014-08-29 12:54:06', 'Prison INT lobby 1', 3, 9, NULL),
(215, 1569, 1478.45, 1551.09, 12.4531, 0, 0, 269.989, 1478.45, 1551.09, 12.4531, 0, 0, 0, 8, 30, 30, 812, 3, 'F=59', 'anumaz', '2014-08-29 12:57:10', 'Prison INT lobby 2', 3, 9, NULL),
(216, 1569, 1478.76, 1544.47, 12.4531, 0, 0, 0, 1478.76, 1544.47, 12.4531, 0, 0, 90, 8, 30, 30, 812, 3, 'F=59', 'anumaz', '2014-08-29 12:58:40', 'Prison INT lobby 3', 3, 9, NULL),
(217, 2930, 1470.93, 1516.2, 12.59, 0, 0, 270, 1470.93, 1516.2, 12.59, 0, 0, 0, 8, 30, 30, 851, 3, 'F=59', 'Nadr', '2014-08-29 13:10:08', 'Prison INT visit 1', 3, 9, 'metalgate'),
(218, 2930, 1452.76, 1503.41, 12.5158, 0, 0, 270, 1452.76, 1503.41, 12.5158, 0, 0, 0, 8, 30, 30, 851, 3, 'F=59', 'Nadr', '2014-08-29 13:14:34', 'Prison INT visit 2', 3, 9, 'metalgate'),
(219, 2930, 1448.36, 1503.66, 12.5158, 0, 0, 270, 1448.36, 1503.66, 12.5158, 0, 0, 0, 8, 30, 30, 851, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 13:32:44', 'Prison INT visit 3', 3, 9, 'metalgate'),
(220, 2930, 1443.87, 1518.11, 12.5158, 0, 0, 180, 1443.87, 1518.11, 12.5158, 0, 0, 270, 8, 30, 30, 851, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 13:33:36', 'Prison INT visit 4', 3, 9, 'metalgate'),
(221, 2930, 1434.56, 1504.29, 12.4416, 0, 0, 180, 1434.56, 1504.29, 12.4416, 0, 0, 270, 8, 30, 30, 851, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 13:34:56', 'Prison INT process 1', 3, 0, 'metalgate'),
(222, 2930, 1432.16, 1508.2, 12.4522, 0, 0, 270, 1432.16, 1508.2, 12.4522, 0, 0, 180, 8, 30, 30, 851, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 13:36:18', 'Prison INT process 2', 3, 9, 'metalgate'),
(223, 13817, 1483.51, 1530.3, 11.1369, 0, 0, 270, 1483.51, 1530.3, 7, 0, 0, 270, 8, 30, 30, 812, 3, 'F=59', 'Nadr', '2014-08-29 13:59:13', 'Prison INT hole 1', 3, 9, 'metalgate'),
(224, 13817, 1487.93, 1530.32, 11.1369, 0, 0, 270, 1487.93, 1530.32, 7, 0, 0, 270, 8, 30, 30, 812, 3, 'F=59', 'Nadr', '2014-08-29 14:00:18', 'Prison INT hole 2', 3, 9, 'metalgate'),
(225, 13817, 1492.44, 1530.4, 11.1369, 0, 0, 270, 1492.44, 1530.4, 7, 0, 0, 270, 8, 30, 30, 812, 3, 'F=59', 'Nadr', '2014-08-29 14:02:10', 'Prison INT hole 3', 3, 9, 'metalgate'),
(226, 1495, 1491.68, 1539.43, 11.175, 0, 0, 90, 1491.68, 1539.43, 11.175, 0, 0, 0, 8, 30, 30, 812, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 14:08:16', 'Prison INT lobby 4', 3, 9, 'metalgate'),
(227, 1495, 1497.5, 1534, 10, 0, 0, 180, 1497.5, 1534, 10, 0, 0, 90, 8, 30, 30, 812, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-29 14:11:34', 'Prison INT lobby 5', 3, 9, 'metalgate'),
(228, 3115, -408.4, 1000.7, 390.5, 0, 0, 0, -408.4, 1000.7, 369.9, 0, 0, 0, 0, 1, 1, 0, 18, '', 'Poffy', '2014-08-31 16:16:54', '', NULL, NULL, 'metalgate'),
(229, 2930, 1039.2, 1224.55, 1494.7, 0, 180, 0, 1039.2, 1224.55, 1494.7, 0, 180, 270, 8, 30, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-08-31 19:09:14', 'Prison INT Block 1', 3, NULL, 'metalgate'),
(230, 2930, 1035.25, 1224.6, 1494.7, 0, 180, 0, 1035.25, 1224.6, 1494.7, 0, 180, 90, 8, 30, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 01:45:31', 'Prison INT Block 2', 3, NULL, 'metalgate'),
(231, 2930, 1027, 1249.85, 1493, 0, 0, 0, 1027, 1249.85, 1493, 0, 0, 90, 8, 0, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 01:54:35', 'Prison INT Block 3', 4, NULL, 'metalgate'),
(232, 2930, 1027, 1248.15, 1493, 0, 0, 0, 1027, 1248.15, 1493, 0, 0, 0, 8, 0, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 02:03:08', 'Prison INT Block 3 Spacer', 4, NULL, NULL),
(233, 2930, 1027, 1256.4, 1493, 0, 0, 180, 1027, 1256.4, 1493, 0, 0, 90, 8, 0, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 02:09:03', 'Prison INT Block 4', 4, NULL, 'metalgate'),
(234, 2930, 1027.07, 1259.8, 1493, 0, 0, 0, 1027.07, 1259.8, 1493, 0, 0, 90, 8, 0, 20, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 02:31:06', 'Prison INT Block 4', 4, NULL, 'metalgate'),
(235, 2930, 1035.5, 1261.15, 1492.98, 0, 0, 90, 1035.5, 1261.15, 1492.98, 0, 0, 270, 8, 0, 40, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 03:59:07', 'Prison INT Block 5', 4, NULL, 'metalgate'),
(236, 2930, 1038.94, 1261.08, 1492.98, 0, 0, 270, 1038.94, 1261.08, 1492.98, 0, 0, 90, 8, 0, 40, 880, 3, 'F=59 OR 64=prison access', 'Nadr', '2014-09-01 04:07:09', 'Prison INT Block 5', 4, NULL, 'metalgate'),
(237, 3115, -407.9, 1001.7, 390.5, 0, 0, 0, -407.9, 1001.7, 369.9, 0, 0, 0, 2, 0, 100, 218, 6, 'mansack', 'Capone', '2014-09-01 14:33:42', 'Interior 218', 9.9, 9.9, 'metalgate'),
(238, 3089, 1806.87, -1374.11, 29.6, 0, 0, 0, 1806.87, -1374.11, 29.6, 0, 0, 96.75, 7, 30, 20, 14, 3, '4', 'DutchLars', '2014-09-01 19:33:48', 'Chase INT', 3, NULL, NULL),
(239, 971, 263.8, -1333.4, 55.1, 0, 0.648, 216.749, 263.8, -1333.4, 47.2, 0, 0.643, 216.744, 5, 30, 20, 0, 0, 'parool123', 'Kermoo', '2014-09-04 14:30:12', 'Russel House', NULL, NULL, 'metalgate'),
(240, 968, 1578.8, 710.9, 10.65, 0, 90, 270, 1578.8, 710.9, 10.65, 0, 180, 270, 8, 30, 30, 0, 0, 'F=59 OR F=1', 'anumaz', '2014-09-12 00:07:33', 'PD-SD training grounds', 9, 9, 'metalgate'),
(241, 980, -491.6, -527.9, 26.3, 0, 0, 89.5, -496, -532.2, 26.3, 0, 0, 180.245, 10, 0, 60, 0, 0, 'hydraStrike', 'Keksii', '2014-09-15 07:07:00', 'Gate to enter race track in Doriland', 9, 9, 'metalgate'),
(242, 968, 2100.37, -1374.47, 23.73, 0, 90, 180, 2100.37, -1374.47, 23.73, 0, 180, 180, 10, 0, 30, 0, 0, 'cunt', 'CharChar', '2015-01-05 07:10:54', 'Tel-Aviv Motors', 30, 30, NULL),
(243, 2930, 1381.4, 374.5, 21.5, 0, 0, 337.247, 1381.4, 374.5, 21.5, 0, 0, 248, 7, 30, 20, 0, 0, '59', 'Nadr', '2015-01-28 01:31:18', 'SAHP Monty Station', 3, 4, 'metalgate'),
(244, 11327, 1481.4, 1313.1, 12.9, 0, 0, 0, 1481.4, 1313.09, 16.8, 0, 0, 0, 8, 0, 30, 822, 27, '170 = 7335', 'Belgica', '2014-12-02 15:55:43', 'Belgica', 9, 9, 'metalgate'),
(245, 11102, 958, -1179.1, 18.1, 0, 0, 90, 961.8, -1210.6, 16.1, 0, 0, 180, 2, 30, 30, 0, 0, '0143', 'Rilind', '2014-12-06 18:02:56', '30', NULL, NULL, 'metalgate'),
(246, 1569, 1513.8, 1348.5, 10, 0, 0, 0, 1513.8, 1348.5, 10, 0, 0, -90, 7, 20, 20, 617, 1, '2', 'Rilind', '2015-01-11 10:41:51', 'lsfdlobby', NULL, NULL, NULL),
(247, 975, 2453.87, 85.269, 25, 0, 0, 270, 2453.87, 85.269, 22, 0, 0, 270, 10, 10, 50, 0, 0, 'Sarah123', 'CharChar', '2015-01-21 12:01:55', '9', 9, 9, 'metalgate'),
(248, 968, 988.8, -1776.5, 13.97, 0, 270, 346, 988.8, -1776.5, 13.97, 0, 180, 346, 10, 0, 30, 0, 0, 'sadiqsos', 'Weedex', '2014-09-18 14:55:44', 'Marina garage', 9, 9, 'metalgate'),
(249, 2930, 1861.4, -2461, 19.7, 0, 0, 270, 1859.8, -2461, 19.7, 0, 0, 270, 5, 30, 20, 630, 27, '', 'Lewis', '2014-09-19 17:56:57', 'LSPD Evidence', 3, NULL, 'metalgate'),
(250, 2957, 2494.3, 90.8, 26.3, 0, 0, 0, 2494.3, 89.1, 27.9, 85.93, 0, 0, 10, 0, 25, 0, 0, 'lennox', 'ron', '2014-09-23 18:05:26', 'Palo3', NULL, NULL, 'metalgate'),
(251, 17951, 100, -164.8, 3.4, 0, 0, 0, 97.9, -164.8, 4.5, 0, 267.5, 1.5, 2, 0, 25, 0, 0, 'lennox', 'Rilind', '2014-09-27 03:05:26', 'blueberry garage', NULL, NULL, 'metalgate'),
(252, 968, 1407.1, 423.7, 20, 0, 90, 335.24, 1407.1, 423.7, 20, 0, 155, 335.24, 7, 40, 30, 0, 0, '59', 'BrukONE', '2015-01-28 01:33:32', 'SAHP Monty Station', 7, 9, 'metalgate'),
(253, 1553, 2329, -108.4, 26, 0, 0, 179.995, 2329, -108.4, 24, 0, 0, 179.995, 10, 15, 40, 0, 0, 'Konjamani-69', 'BrukONE', '2015-01-28 09:41:46', 'Palo Gate', 10, 10, 'metalgate'),
(254, 3037, -279.1, -2170.5, 30.3, 0, 0, 109.747, -279.1, -2170.5, 26.1, 0, 0, 109.742, 7, 30, 20, 0, 0, '59', 'Nadr', '2014-11-10 00:03:51', 'SAHP Gate 2', 7, 9, 'metalgate'),
(255, 1553, 2326.2, -108.4, 26, 0, 0, 179.995, 2326.2, -108.4, 24, 0, 0, 179.995, 10, 15, 40, 0, 0, 'Konjamani-69', 'BrukONE', '2015-01-28 09:42:29', 'Palo Gate 2', 10, 10, 'metalgate'),
(256, 2933, 200.6, -1386.6, 48.9, 0, 359.25, 226, 206.8, -1380.4, 48.9, 0, 359.247, 226, 8, 32, 30, 0, 0, '4=1979', 'tomtiger11', '2014-10-04 13:45:22', 'Richman-garage gate', NULL, NULL, 'metalgate'),
(257, 4100, 2039.4, 1452.1, 972.5, 39.998, 270.42, 359.593, 2039.4, 1452.1, 968, 39.998, 270.42, 359.593, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:17:55', 'Metro Evidence - 1', 6, 1, NULL),
(258, 4100, 2039, 1457.4, 971.2, 39.996, 270.417, 359.588, 2039, 1457.4, 968, 39.996, 270.417, 359.588, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:20:46', 'Metro evidence 2', 6, NULL, NULL),
(260, 1553, 2149.7, -1230.8, 24.2, 0, 0, 180.5, 2150.7, -1229.6, 24.2, 0, 0, 107.25, 2, 30, 30, 0, 0, 'Richie', 'BlueBerry', '2014-11-26 15:42:30', 'Richard Barbero', 9, 9, 'metalgate'),
(261, 1553, 2146.9, -1230.8, 24.2, 0, 0, 178.75, 2146, -1229.6, 24.2, 0, 0, 252.5, 2, 30, 30, 0, 0, 'Richie', 'BlueBerry', '2014-11-26 15:43:09', 'Richard Barbero', 9, 9, 'metalgate'),
(262, 1569, 1635.2, -1674.2, 13.5, 0, 0, 269.25, 1635.2, -1674.2, 13.5, 0, 0, 180.497, 7, 15, 15, 0, 0, '20', 'MishaKonsta', '2014-10-21 15:50:42', 'lsnGate', NULL, NULL, 'metalgate'),
(263, 1569, 1635.2, -1677.2, 13.5, 0, 0, 90.5, 1635.2, -1677.2, 13.5, 0, 0, 180.744, 7, 15, 15, 0, 0, '20', 'MishaKonsta', '2014-10-21 15:51:45', 'lsnGate2', NULL, NULL, 'metalgate'),
(264, 976, 2747.9, -1182.1, 66.3, 0, 0, 90, 2747.9, -1188.4, 66.3, 0, 0, 90, 2, 50, 50, 0, 0, 'test', 'BlueBerry', '2014-10-23 12:20:49', 'Holson House', 9, 9, 'metalgate'),
(265, 2708, 802.3, -1390.3, 2968.4, 0, 0, 270, 802.3, -1388.9, 2968.4, 0, 0, 270, 2, 0, 30, 1846, 1, 'JalluK0la', 'Rilind', '2014-10-24 19:18:16', 'MonaMcLaughlin', NULL, NULL, NULL),
(266, 2708, 802.3, -1392.7, 2968.4, 0, 0, 270, 802.3, -1394.3, 2968.4, 0, 0, 270, 2, 0, 30, 1846, 1, 'JalluK0la', 'Rilind', '2014-10-24 19:20:03', 'MonaMcLaughlin', NULL, NULL, NULL),
(267, 988, 1378.4, -1821, 13.6, 0, 0, 90.5, 1375.8, -1823.7, 13.6, 0, 0, 359.25, 8, 30, 30, 0, 0, '5=2009', 'AndreC', '2014-10-26 13:31:19', 'personalgatedylanjeter', NULL, NULL, 'metalgate'),
(268, 980, 1812.8, -2071.7, 13.6, 0, 0, 270, 1812.8, -2062, 13.6, 0, 0, 270, 2, 0, 30, 0, 0, 'mickeyswarehouse', 'einschtein', '2014-10-27 18:11:16', '1', 9, 9, 'metalgate'),
(269, 2933, 895.9, -717.03, 107.06, 0, 347.7, 67.8, 895.92, -716.89, 105.92, 0, 347.7, 67.8, 10, 0, 15, 0, 0, 'einschtein', 'einschtein', '2014-10-29 17:49:46', '8, Palin Street', 9, 9, 'metalgate'),
(272, 1495, 2248.45, 168.915, 26.4, 0, 0, 180, 2248.45, 168.915, 26.4, 0, 0, 90, 8, 12, 12, 0, 0, '', 'AndreC', '2014-11-15 20:10:22', 'Jay walters palomino house', NULL, NULL, NULL),
(274, 1569, 1543.9, 1486.4, 28.1, 0, 0, 180, 1543.9, 1486.4, 28.1, 0, 0, 90, 1, 30, 20, 2695, 21, '', 'MishaKonsta', '2015-01-17 13:01:10', 'GovDoorleft', NULL, NULL, 'metalgate'),
(275, 1569, 1540.9, 1486.4, 28.1, 0, 0, 0, 1540.9, 1486.4, 28.1, 0, 0, 90, 7, 30, 20, 2695, 21, '3', 'tomtiger11', '2015-01-17 13:02:03', 'GovDoorRight', NULL, NULL, NULL),
(276, 975, 1117.5, -1222.6, 18.6, 0, 0, 0, 1126, -1222.6, 18.6, 0, 0, 0, 8, 0, 30, 0, 0, '5=972', 'AndreC', '2014-11-01 22:43:08', 'Creason and Creason back lot gate', 22, 22, 'metalgate'),
(277, 980, 2131.87, -1869.35, 13, 0, 0, 90, 2131.87, -1869.35, 9.77, 0, 0, 90, 8, 30, 30, 0, 0, '170=JohnstreetGate', 'BlueBerry', '2014-11-02 07:02:48', 'Johnstreet, back entrance', NULL, NULL, 'metalgate'),
(278, 16773, 1924.21, -2406.98, 14.21, 0, 0, 90, 1924.21, -2406.98, 8.6, 0, 0, 90, 8, 30, 30, 2140, 56, '170=PantopicanAvenueHotel', 'BlueBerry', '2014-11-02 13:44:15', 'Pantopican Avenue Hotel', NULL, NULL, 'metalgate'),
(279, 2634, 2039, 1477.8, 976.7, 0, 0, 180, 2040, 1478.6, 976.7, 0, 0, 270, 10, 30, 40, 2250, 10, 'Metro - IV', 'Sloth', '2015-02-03 16:22:51', 'Metro evidence 3', 30, 40, NULL),
(280, 3089, 2759.7, -2379.9, 819.6, 0, 0, 180, 2759.7, -2379.9, 819.6, 0, 0, 270, 7, 0, 20, 220, 2, '50', 'Nadr', '2014-11-04 04:23:49', 'SCoSA', 4, NULL, NULL),
(282, 1553, 1909.03, -1123.39, 25.49, 0, 0, 0, 1909.03, -1123.39, 23.3, 0, 0, 0, 8, 0, 30, 0, 0, '4=998', 'BrukONE', '2015-01-22 20:47:10', 'Park Avenue - House 2', 15, 15, 'metalgate'),
(283, 1553, 1911.85, -1123.39, 25.49, 0, 0, 0, 1911.85, -1123.39, 23.3, 0, 0, 0, 8, 0, 30, 0, 0, '4=998', 'BrukONE', '2015-01-22 20:49:54', 'Park Avenue - House 2', 15, 15, NULL),
(284, 2946, 2120.8, -2442.25, 12.658, 0, 0, 180, 2120.8, -2442.25, 12.658, 0, 0, 95, 3, 0, 30, 1637, 56, '82', 'BrukONE', '2014-11-11 11:26:07', 'RT Auction Lot Office Door', 9, 9, NULL),
(285, 980, 1042.99, 806.12, -73.2, 0, 0, 0, 1042.99, 806.12, -83.2, 0, 0, 0, 8, 30, 50, 1452, 17, '170=1452', 'Belgica', '2015-01-25 13:21:10', 'gate', 9, 9, 'metalgate'),
(286, 988, 2044.8, 1471.1, 976, 0, 0, 270, 2044.8, 1474.5, 976, 0, 0, 270, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:24:31', 'Metro evidence 4', 6, NULL, NULL),
(287, 2948, 489.855, -61.04, 975.1, 0, 0, 270, 489.855, -61.04, 975.1, 0, 0, 0, 8, 0, 30, 2090, 29, '55=Whispers', 'Belgica', '2014-11-22 07:14:26', 'IntID2090', 9, 9, NULL),
(288, 2988, 480, -81.8, 975.2, 0, 0, 0, 480, -81.8, 975.2, 0, 0, -90, 2, 0, 30, 2090, 29, 's14', 'Belgica', '2014-11-22 07:17:05', 'Int2090Ext', 9, 9, 'metalgate');
INSERT INTO `gates` (`id`, `objectID`, `startX`, `startY`, `startZ`, `startRX`, `startRY`, `startRZ`, `endX`, `endY`, `endZ`, `endRX`, `endRY`, `endRZ`, `gateType`, `autocloseTime`, `movementTime`, `objectDimension`, `objectInterior`, `gateSecurityParameters`, `creator`, `createdDate`, `adminNote`, `triggerDistance`, `triggerDistanceVehicle`, `sound`) VALUES
(289, 2988, 480, -90.2, 975.2, 0, 0, 180, 480, -90.2, 975.2, 0, 0, -90, 2, 0, 30, 2090, 29, 's14', 'Belgica', '2014-11-22 07:20:22', 'Int2090Ext2', 9, 9, 'metalgate'),
(290, 988, 2044.8, 1465.2, 976, 0, 0, 270, 2044.8, 1462, 976, 0, 0, 270, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:26:31', 'Metro evidence 5', 6, NULL, NULL),
(291, 980, -128.357, -179.24, 0.847, 0, 0, 350.25, -128.357, -179.241, -1.66777, 0, 0, 350.25, 10, 75, 15, 0, 0, 'loser_poop69', 'BrukONE', '2014-11-28 15:16:19', 'farmgate1', 15, 30, 'metalgate'),
(292, 980, -26.9634, 163.081, 1.3706, 0, 0, 328.703, -26.9639, 163.081, -1.2552, 0, 0, 328.7, 10, 75, 20, 0, 0, 'loser_poop69', 'BrukONE', '2014-11-28 17:09:19', 'farmgate2', 15, 30, 'metalgate'),
(293, 1569, -27.96, 123.73, 1006.2, 0, 0, 0, -27.96, 123.73, 1006.2, 0, 0, 270, 7, 30, 20, 1614, 3, '1 or 59', 'Nadr', '2014-11-29 16:17:05', 'Training Grounds', 4, NULL, NULL),
(294, 1569, -6.99, 123.7, 1006.2, 0, 0, 0, -6.99, 123.7, 1006.2, 0, 0, 270, 7, 30, 20, 1614, 3, '1 or 59', 'Nadr', '2014-11-29 16:20:04', 'Training Grounds', 4, NULL, NULL),
(295, 4100, 2039.4, 1452.1, 972.5, 39.998, 270.42, 359.593, 2039.4, 1452.1, 968, 39.998, 270.42, 359.593, 7, 30, 40, 2247, 2, '59', 'Nadr', '2014-12-01 00:51:45', 'SAHP', 6, NULL, 'metalgate'),
(296, 4100, 2039, 1457.4, 971.2, 39.996, 270.417, 359.588, 2039, 1457.4, 968, 39.996, 270.417, 359.588, 7, 30, 40, 2247, 2, '59', 'Nadr', '2014-12-01 00:52:35', 'SAHP', 6, NULL, 'metalgate'),
(297, 2634, 2039, 1477.8, 976.7, 0, 0, 180, 2040, 1478.6, 976.7, 0, 0, 270, 7, 60, 40, 2247, 2, '59', 'Nadr', '2014-12-01 00:57:36', 'SAHP', 2, NULL, 'metalgate'),
(298, 988, 2044.8, 1471.1, 976, 0, 0, 270, 2044.8, 1474.5, 976, 0, 0, 270, 7, 60, 40, 2247, 2, '59', 'Nadr', '2014-12-01 01:02:16', 'SAHP', 3, NULL, 'metalgate'),
(299, 988, 2044.8, 1465.2, 976, 0, 0, 270, 2044.8, 1462, 976, 0, 0, 270, 7, 60, 40, 2247, 2, '59', 'Nadr', '2014-12-01 01:02:56', 'SAHP', 3, NULL, 'metalgate'),
(300, 988, 2031.7, 1465.4, 976, 0, 0, 90, 2031.7, 1462, 976, 0, 0, 90, 2, 60, 40, 2247, 2, 'deltaseven', 'Nadr', '2014-12-01 01:03:17', 'SAHP', 3, NULL, 'metalgate'),
(301, 988, 2031.7, 1471.2, 976, 0, 0, 90, 2031.7, 1474.5, 976, 0, 0, 90, 7, 60, 40, 2247, 2, '59', 'Nadr', '2014-12-01 01:03:39', 'SAHP', 3, NULL, 'metalgate'),
(302, 3036, 2197.95, -1001.27, 61.4, 0, 0, 339.311, 2197.95, -1001.27, 61.4, 0, 0, -106, 2, 30, 30, 0, 0, '0143', 'Rilind', '2014-12-01 04:16:52', 'Dominick Carter', 9, 9, 'metalgate'),
(303, 3089, 1565.6, -1674.7, 64.8, 0, 0, 270, 1565.5, -1674.7, 64.8, 0, 0, 144, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-01 23:46:28', 'Superior Court of San Andreas', 2, 2, NULL),
(304, 3089, 1555.9, -1679.5, 64.8, 0, 0, 0, 1555.9, -1679.5, 64.8, 0, 0, 132, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-01 23:56:56', 'Superior Court of San Andreas', 2, 2, NULL),
(305, 3089, 1583.3, -1688.3, 63.6, 0, 0, 0, 1583.3, -1688.3, 63.6, 0, 0, 110, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-01 23:59:19', 'Superior Court of San Andreas', 2, 2, NULL),
(306, 3089, 1565.7, -1655.3, 66.2, 0, 0, 179.995, 1565.7, -1655.3, 66.2, 0, 0, 301.995, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-02 00:01:12', 'Superior Court of San Andreas', 2, 2, NULL),
(307, 2963, 1562, -1651, 66.1, 0, 0, 90, 1559.2, -1651.1, 66.3, 0, 0, 90, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-02 00:02:49', 'Superior Court of San Andreas', 2, 2, 'metalgate'),
(308, 3089, 1569.7, -1655.3, 66.2, 0, 0, 179.995, 1569.7, -1655.3, 66.2, 0, 0, 305.995, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-02 00:04:12', 'Superior Court of San Andreas', 2, 2, NULL),
(309, 3089, 1567.94, -1663.2, 66.2, 0, 0, 90, 1568, -1663.2, 66.2, 0, 0, 320, 8, 30, 30, 2249, 7, 'F=50', 'dfajoe', '2014-12-02 00:05:10', 'Superior Court of San Andreas', 2, 2, NULL),
(310, 2774, 1084.9, -627.9, 105.8, 0, 0, 0, 1084.9, -627.9, 105.8, 0, 0, 0, 10, 25, 25, 0, 0, 'Almeida', 'Lewis', '2015-01-29 14:51:15', 'Almeida House ', 10, 10, NULL),
(311, 3109, -1337.2, 932.1, 794, 0, 0, 0, -1337.2, 930.6, 794, 0, 0, 0, 10, 10, 10, 2145, 1, 'Falafel96', 'Weedex', '2014-12-07 16:05:57', 'Gate.', NULL, NULL, NULL),
(312, 1553, 2093.69, -1290.98, 24.16, 0, 0, 0, 2091.49, -1290.98, 24.16, 0, 0, 0, 10, 0, 30, 0, 0, 'vladim_belview', 'BrukONE', '2014-12-19 06:51:29', '1, Belview Road', NULL, NULL, 'metalgate'),
(313, 1505, 1335.75, 1382.85, 10.3, 0, 0, 0, 1336, 1383.2, 10.3, 0, 0, -272, 3, 30, 30, 1883, 24, '180', 'Rilind', '2014-12-14 10:36:16', 'sapthqgate', NULL, NULL, NULL),
(314, 1553, 2096.51, -1290.98, 24.16, 0, 0, 0, 2098.71, -1290.98, 24.16, 0, 0, 0, 10, 0, 30, 0, 0, 'vladim_belview', 'BrukONE', '2014-12-19 06:53:20', '1, Belview Road', NULL, NULL, 'metalgate'),
(315, 3089, 1867.8, -2241.4, 1359.7, 0, 0, 270, 1867.8, -2241.4, 1359.7, 0, 0, 170, 8, 20, 20, 2340, 4, 'F=47', 'Exciter', '2014-12-19 13:03:10', 'LSIA - ATC', NULL, NULL, 'metalgate'),
(316, 3089, 1735.4, -1637.6, 1521.4, 0, 0, 270, 1735.4, -1637.6, 1521.4, 0, 0, 180, 8, 20, 20, 1462, 3, '170=ClubX 150207 OR 170=ClubX 1502', 'Exciter', '2014-12-21 20:07:11', 'Club X - VIP', NULL, NULL, NULL),
(317, 1497, 2640.92, -1343.48, 1010.17, 0, 0, 90, 2640.92, -1343.48, 1010.17, 0, 0, 0, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 14:54:58', '2219', 5, 6, NULL),
(318, 3055, 2595.7, -1320.5, 997.9, 0, 0, 0, 2595.7, -1320.5, 994.67, 0, 0, 0, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:10:07', '2219', 15, 20, NULL),
(319, 3055, 2608.41, -1324.5, 997.9, 0, 0, 90, 2608.41, -1324.5, 994.66, 0, 0, 90, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:11:33', '2219', 5, 7, NULL),
(320, 2988, 2630.9, -1321.05, 1003.8, 0, 0, 90, 2630.9, -1321.05, 1003.8, 0, 0, 150, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:15:11', '2219', 5, 4, NULL),
(321, 1497, 2641.25, -1324.96, 1003.84, 0, 0, 270, 2641.25, -1324.96, 1003.84, 0, 0, 0, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:17:31', '2219', 3, 3, NULL),
(322, 1497, 2641.27, -1327.97, 1003.84, 0, 0, 90, 2641.28, -1327.97, 1003.84, 0, 0, 0, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:18:41', '2219', 5, 1, NULL),
(323, 1497, 2628.81, -1324.25, 997.5, 0, 0, 90, 2628.81, -1324.25, 997.5, 0, 0, 180, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:22:50', '2219', 4, 4, NULL),
(324, 1497, 2628.78, -1321.24, 997.5, 0, 0, 270, 2628.78, -1321.24, 997.5, 0, 0, 180, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:24:04', '2219', 5, 5, NULL),
(325, 1497, 2640.89, -1340.47, 1010.17, 0, 0, 270, 2640.89, -1340.47, 1010.17, 0, 0, 0, 2, 0, 50, 2219, 1, 's14', 'Err0r', '2014-12-23 15:31:34', '2219', 5, 5, NULL),
(326, 976, 2609, -1332.23, 1010.13, 0, 0, 0, 2609, -1332.23, 1006, 0, 0, 0, 2, 0, 50, 2219, 1, 's11', 'CharChar', '2014-12-23 20:28:57', 's14', 90, 5, NULL),
(327, 985, 1081.57, -1301.25, 79.0625, 0, 0, 90, 1081.57, -1292.56, 79.0625, 0, 0, 90, 7, 30, 22, 1060, 1, '1', 'AndreC', '2014-12-23 21:58:13', 'LSPD Impound Gate', 50, 50, 'metalgate'),
(328, 3089, 450.3, 188.05, 1016.8, 0, 0, 90, 450.3, 188.05, 1016.8, 0, 0, 10, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:23:08', 'SAHP Meeting', 2, NULL, NULL),
(330, 3089, 450.4, 176.57, 1016.8, 0, 0, 90, 450.4, 176.57, 1016.8, 0, 0, 170, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:24:03', 'SAHP Interrogation', 2, 0, NULL),
(331, 2930, 463.8, 179.7, 1018.08, 0, 0, 270, 465.3, 179.7, 1018.08, 0, 0, 270, 7, 30, 30, 2380, 5, '59', 'Nadr', '2014-12-24 00:26:20', 'SAHP Cell', 2, NULL, 'metalgate'),
(332, 3089, 470, 201.7, 1028.6, 0, 0, 90, 470, 201.7, 1028.6, 0, 0, 170, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:27:10', 'SAHP Rec Room', 2, NULL, NULL),
(333, 3089, 449.775, 175.4, 1016.64, 0, 0, 180, 449.775, 175.4, 1016.64, 0, 0, 100, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:28:00', 'SAHP Private Interrogation', 2, NULL, NULL),
(334, 3089, 450.3, 191.5, 1016.8, 0, 0, 90, 450.3, 191.5, 1016.8, 0, 0, 170, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:28:48', 'SAHP Side', 2, NULL, NULL),
(335, 3089, 458.3, 191.5, 1016.8, 0, 0, 90, 458.3, 191.5, 1016.8, 0, 0, 10, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:29:23', 'SAHP Main', 2, NULL, NULL),
(336, 3089, 462.24, 176.4, 1016.8, 0, 0, 0, 462.24, 176.4, 1016.8, 0, 0, 280, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:29:45', 'SAHP Back', 2, NULL, NULL),
(337, 3089, 480.4, 191.4, 1016.8, 0, 0, 180, 480.4, 191.4, 1016.8, 0, 0, 100, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:30:19', 'SAHP Office', 2, NULL, NULL),
(338, 3089, 449.4, 182.8, 1028.5, 0, 0, 90, 449.4, 182.8, 1028.5, 0, 0, 170, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:30:57', 'SAHP Cubicles', 2, NULL, NULL),
(339, 3089, 445.48, 189.2, 1028.6, 0, 0, 180, 445.48, 189.2, 1028.6, 0, 0, 100, 7, 30, 20, 2380, 5, '59', 'Nadr', '2014-12-24 00:31:24', 'SAHP Duty', 2, NULL, NULL),
(340, 975, 2178.06, -1918.32, 14.2, 0, 0, 180, 2171, -1918.32, 14.2, 0, 0, 180, 8, 30, 30, 0, 0, '5=2381', 'AndreC', '2014-12-24 23:25:47', 'Standards shop gate', 22, 22, 'metalgate'),
(341, 3475, 1084.9, -627.9, 113.2, 348, 0, 272, 1084.9, -627.9, 113.2, 348, 0, 272, 10, 25, 25, 0, 0, 'Almeida', 'Lewis', '2015-01-29 14:51:41', 'Almeida House', 10, 10, NULL),
(342, 10184, 2235.3, 2457.5, -5.94, 0, 0, 180, 2235.3, 2457.5, -11, 0, 0, 180, 8, 50, 40, 2399, 0, 'F=59 AND 170=authorized', 'Nadr', '2014-12-28 01:20:59', 'SAHP Garage', 4, 7, 'metalgate'),
(343, 2933, 518, -48.17, 979.1, 0, 0, 180, 518, -48.17, 976.4, 0, 0, 180, 10, 0, 30, 2090, 29, 'workplease', 'dfajoe', '2014-12-25 20:23:28', '', 9, 9, NULL),
(344, 988, 2609.45, -1314.1, 1003.53, 270, 90, 0, 2609.45, -1314.1, 997.5, 270, 90, 0, 10, 0, 30, 2219, 1, 'workplease', 'dfajoe', '2014-12-25 20:43:38', '', 11, 11, NULL),
(345, 1536, 1483.62, -1928.12, 290.15, 0, 0, 270, 1483.62, -1928.12, 290.15, 0, 0, 0, 7, 15, 30, 9, 1, '3', 'BrukONE', '2015-01-02 13:19:12', 'Gov door', 15, 15, NULL),
(346, 16775, 1500.36, -568.762, 408.413, 0, 0, 0, 1500.36, -568.762, 412.371, 0, 0, 0, 8, 0, 30, 972, 1, '5=972', 'AndreC', '2014-12-28 22:41:54', 'Creason and Creason int Garage', 15, 15, NULL),
(347, 9020, 1514.6, -539.8, 427.8, 270, 180, 270, 1514.6, -539.8, 431.457, 270, 179.995, 270, 8, 0, 30, 972, 1, '5=972', 'Lemonth', '2014-12-28 22:44:27', 'Creason and creason int gate', 30, 30, 'metalgate'),
(348, 10671, -1348.4, -1995.3, 2.5, 0, 0, 103.997, -1348.4, -1995.3, 4, 0, 90, 103.997, 10, 0, 80, 0, 0, 'riptom', 'CharChar', '2014-12-31 11:00:19', '', 20, 20, 'metalgate'),
(349, 8957, 2614.2, -1338.07, 1011.9, 0, 0, 270, 2614.2, -1338.07, 1007.28, 0, 0, 270, 8, 0, 30, 0, 2, '5=972', 'Weedex', '2014-12-31 11:39:22', 'Creason and Creason int Garage', 15, 15, NULL),
(350, 8957, 2614.2, -1338.07, 1011.9, 0, 0, 270, 2614.2, -1338.07, 1007.28, 0, 0, 270, 10, 0, 30, 0, 2, 'xmax12', 'Weedex', '2014-12-31 11:42:36', 'House gate.', 15, 15, 'alarmbell'),
(351, 3109, 2169.2, -1435.1, 299.2, 0, 0, 0, 2169.2, -1435.1, 299.2, 0, 0, -90, 10, 30, 40, 2138, 2, 'Metro - I', 'Sloth', '2015-01-01 20:03:12', 'LSPD Metro Staircase', 5, NULL, NULL),
(352, 971, 2093.85, -2590.1, 26.46, 0, 0, 90, 2093.85, -2590.1, 17, 0, 0, 90, 10, 0, 20, 1123, 56, 'Metro - II', 'Sloth', '2015-01-01 20:25:53', 'Metro SWAT garage', 10, 10, NULL),
(353, 16775, 629.7, -1115.8, 44.5, 0, 180, 213.25, 629.7, -1115.8, 41.7, 0, 180, 213.25, 10, 0, 30, 0, 0, 'gottschalk', 'BrukONE', '2015-01-01 20:47:32', 'MisterClane\'s house', 15, 15, 'metalgate'),
(354, 8957, 2614.2, -1338.07, 1011.9, 0, 0, 270, 2614.2, -1338.07, 1007.28, 0, 0, 270, 2, 0, 30, 2219, 1, 's14', 'Rilind', '2015-01-01 20:52:14', '', NULL, NULL, NULL),
(355, 3276, -1289.8, -2160, 23.299, 0, 13.236, 160.223, -1289.8, -2160, 20.29, 0, 13.236, 160.223, 10, 0, 30, 0, 0, 'riptom', 'CharChar', '2015-01-02 05:57:30', '', 20, 20, 'metalgate'),
(356, 989, 855.1, -894.3, 65.4, 0, 0, 70, 849.6, -890.5, 65.4, 2, 0, 76, 2, 30, 30, 0, 0, 'singhisking', 'Manjot', '2015-01-02 16:35:46', 'ManjotPrivate', 10, 10, 'metalgate'),
(357, 1536, -37.5, -99.91, 1014.32, 0, 0, 270, -37.5, -99.91, 1014.32, 0, 0, 173, 10, 45, 15, 2517, 22, 'REALTY', 'CharChar', '2015-01-03 03:49:23', 'Interior door', 5, 5, 'metalgate'),
(358, 970, 2850.9, -1309.55, 14.17, 0, 346, 99, 2851.25, -1312.15, 13.51, 0, 346, 99, 8, 22, 22, 0, 0, '4=1306', 'AndreC', '2015-01-03 03:59:04', 'Interior id 2481 front gate', NULL, NULL, NULL),
(359, 11319, 1519.69, -507.07, 407.57, 0, 0, 0, 1519.69, -507.07, 413.03, 0, 0, 0, 8, 0, 55, 972, 1, '5=972', 'Lemonth', '2015-01-03 15:30:43', 'C&C Paint Booth', 12, 15, NULL),
(360, 1497, 2618.8, -1332.08, 1013.7, 0, 0, 0, 2618.8, -1332.08, 1013.7, 0, 0, 90, 10, 0, 15, 2253, 3, 'S14', 'Kamil3052', '2015-01-03 20:24:33', '-', NULL, NULL, NULL),
(361, 3117, 2611.6, -1331.1, 1013.6, 0, 0, 0, 2611.6, -1331.1, 1010.1, 0, 0, 0, 10, 0, 15, 2253, 3, 'S14', 'Kamil3052', '2015-01-03 20:25:52', '-', NULL, NULL, NULL),
(362, 2909, -367.97, 1580.99, 76.32, 0, 0, 225, -362.44, 1575.38, 76.32, 0, 0, 225, 9, 37, 30, 0, 0, '13534', 'L3mon', '2015-01-28 13:30:53', 'Sat Gate', 15, 15, 'metalgate'),
(363, 976, 62.5, -241.6, 0.6, 0, 0, 0, 53.5, -241.6, 0.6, 0, 0, 0, 10, 0, 30, 0, 0, 'FinalCons', 'BrukONE', '2015-01-28 18:21:29', 'Final Construction', 15, 15, 'metalgate'),
(364, 8378, 2009.3, -2388, 22.5, 0, 0, 90, 2009.3, -2388, 3.1, 0, 0, 90, 7, 0, 100, 0, 0, '47', 'anumaz', '2015-01-04 15:57:12', 'LSIA Hangar A', 15, 15, 'alarmbell'),
(365, 1553, 2470.5, 121.8, 26.7, 0, 0, 0, 2472.8, 121.7, 26.7, 0, 0, 0, 8, 60, 30, 0, 0, '4=2315', 'Lemonth', '2015-01-06 18:19:17', '22. Clean St.', NULL, NULL, 'metalgate'),
(366, 2933, 1924.56, -2427.8, 14.25, 0, 0, 90, 1924.56, -2463.5, 14.25, 0, 0, 90, 10, 30, 40, 2167, 56, 'TheMonopoly', 'Lemonth', '2015-01-08 23:07:59', 'The Monopoly', 5, 5, 'metalgate'),
(367, 2933, 1924.56, -2427.8, 14.25, 0, 0, 90, 1924.56, -2436.5, 14.25, 0, 0, 90, 7, 30, 40, 693, 56, '1', 'tomtiger11', '2015-01-05 14:56:56', 'CTUGate', NULL, NULL, 'metalgate'),
(368, 1495, 522.63, 68.7, 1043.49, 0, 0, 270, 522.63, 68.7, 1043.49, 0, 0, 170, 8, 50, 15, 2580, 24, '4=2580', 'Lemonth', '2015-01-06 16:17:17', 'Titan Protection and Consulting Garage', NULL, NULL, 'metalgate'),
(369, 969, 875.6, -1046.61, 24.3, 0, 0, 179, 871.6, -1046.44, 24.3, 0, 0, 179, 8, 60, 30, 0, 0, '4=2580', 'BrukONE', '2015-01-06 16:42:50', 'Titan Protection and Consulting', NULL, NULL, 'metalgate'),
(370, 1553, 2467.7, 121.8, 26.7, 0, 0, 0, 2465.5, 121.8, 26.7, 0, 0, 0, 8, 60, 30, 0, 0, '4=2315', 'Lemonth', '2015-01-06 18:19:43', '22. Clean St.', NULL, NULL, 'metalgate'),
(371, 16773, 530.7, 87.63, 1047.42, 0, 0, 270, 530.7, 87.63, 1051.42, 0, 0, 270, 8, 60, 30, 2580, 24, '4=2580', 'Lemonth', '2015-01-06 18:41:03', 'Titan Protection and Consulting Garage', NULL, NULL, 'metalgate'),
(372, 16773, -3.1, -268.2, 8.4, 0, 0, 180, -3, -264.5, 10.4, 270, 0, 180, 10, 0, 50, 0, 0, 'JGC HQ', 'Exciter', '2015-01-06 19:47:25', 'Blueberry Factory parking', 10, NULL, 'metalgate'),
(373, 968, -1182.3, 7.9, 2486.2, 0, 90, 0, -1182.3, 7.90039, 2486.2, 0, 180, 0, 10, 0, 30, 1061, 2, 'Monarch Staff', 'Kamil3052', '2015-01-10 15:32:01', 'Monarch Gate', 2, NULL, NULL),
(374, 971, 1098.79, -1727.4, 1145.9, 0, 0, 90, 1098.79, -1722.2, 1145.9, 0, 0, 90, 10, 0, 30, 1924, 24, 'ikeia', 'BrukONE', '2015-01-10 18:35:30', 'IKEA Interior gate', 15, 15, 'metalgate'),
(375, 1569, 1512.3, 1352.9, 10, 0, 0, 90, 1512.3, 1352.9, 10, 0, 0, 0, 7, 20, 20, 617, 1, '2', 'Rilind', '2015-01-11 10:44:07', 'lsfdoffice1', NULL, NULL, NULL),
(376, 1569, 1512.3, 1361, 10, 0, 0, 90, 1512.3, 1361, 10, 0, 0, 0, 7, 20, 20, 617, 1, '2', 'Rilind', '2015-01-11 10:47:45', 'lsfdoffice2', NULL, NULL, NULL),
(377, 1569, 1522.1, 1353.2, 10, 0, 0, 0, 1522.1, 1353.2, 10, 0, 0, -90, 7, 20, 20, 617, 1, '2', 'Rilind', '2015-01-11 10:50:00', 'lsfdacademy', NULL, NULL, NULL),
(378, 1569, 1526.5, 1348.5, 10, 0, 0, 0, 1526.5, 1348.5, 10, 0, 0, -270, 7, 20, 20, 617, 1, '2', 'Rilind', '2015-01-11 10:52:05', 'lsfdlounge', NULL, NULL, NULL),
(379, 975, 2544.12, 11.79, 25.33, 0, 0, 90, 2543.98, 20.72, 25.33, 0, 0, 90, 8, 60, 35, 0, 0, '4=2674', 'Lemonth', '2015-01-11 17:33:23', '35. Crest St. Palamino', NULL, NULL, 'metalgate'),
(380, 969, 1937.4, -2039.7, 12.5, 0, 0, 180, 1945.7, -2039.7, 12.5, 0, 0, 180, 2, 30, 30, 0, 0, 'hba', 'Rilind', '2015-01-12 19:15:59', '1', NULL, NULL, 'metalgate'),
(381, 969, 1929, -2008.3, 12.5, 0, 0, 0, 1936.2, -2008.3, 12.5, 0, 0, 0, 2, 30, 30, 0, 0, 'hba', 'Rilind', '2015-01-12 19:16:31', '2', NULL, NULL, 'metalgate'),
(382, 969, -386.3, -1054.8, 58.1, 0, 0, 300, -389.6, -1047.3, 58.1, 0, 0, 300, 8, 60, 20, 0, 0, '4=510', 'Lemonth', '2015-01-13 20:39:04', 'The Ranch - Flint County (#510)', 5, 15, 'metalgate'),
(383, 1553, 2359.44, -38.15, 25.76, 0, 0, 180, 2359.44, -38.15, 24.18, 0, 0, 180, 10, 0, 30, 0, 0, 'errorsucks', 'Err0r', '2015-01-13 23:24:24', '', NULL, NULL, NULL),
(384, 1553, 2356.61, -38.15, 25.76, 0, 0, 180, 2356.61, -38.15, 24.24, 0, 0, 180, 10, 0, 30, 0, 0, 'errorsucks', 'Err0r', '2015-01-13 23:29:46', '', NULL, NULL, NULL),
(385, 968, 1973.11, -2057.38, 13.07, 0, 270, 90, 1973.11, -2057.38, 13.07, 0, 200, 90, 10, 0, 25, 0, 0, 'RPMF', 'BrukONE', '2015-01-14 19:43:07', 'RPMF', 15, 15, NULL),
(386, 16773, 90.25, -294.6, 4.1, 0, 0, 358.4, 90.25, -298.3, 6, -90, 0, 358.396, 10, 0, 50, 0, 0, 'FinalCons', 'BrukONE', '2015-01-28 18:23:33', 'Final Construction', 15, 15, 'metalgate'),
(387, 976, 197.9, -316.9, 0.6, 0, 0, 276, 197.9, -316.9, -3, 0, 0, 275.999, 10, 0, 30, 0, 0, 'FinalCons', 'BrukONE', '2015-01-28 18:26:05', 'Final Construction', 15, 15, 'metalgate'),
(388, 3475, 1099.7, -629.2, 110.5, 12, 0, 84, 1099.7, -629.2, 110.5, 12, 0, 84, 10, 25, 25, 0, 0, 'Almeida', 'Lewis', '2015-01-29 14:52:02', 'Almeida House', 10, 10, NULL),
(389, 2909, 1746.2, -1581.6, 13.8, 0, 0, 88.748, 1746.2, -1581.6, 10.8, 0, 0, 88.748, 10, 15, 40, 0, 0, 'babyboy', 'CharChar', '2015-01-30 06:54:54', 'Panopticon Gate', 10, 10, 'metalgate'),
(390, 1553, 2139.3, -1290.7, 24.2, 0, 0, 0, 2141.9, -1290.7, 24.2, 0, 0, 0, 2, 0, 30, 0, 0, 'nganmengzeferino', 'BrukONE', '2015-01-30 09:24:22', 'Jefferson house', 15, 15, 'metalgate'),
(391, 1553, 2136.45, -1290.7, 24.2, 0, 0, 0, 2133.65, -1290.7, 24.2, 0, 0, 0, 2, 0, 30, 0, 0, 'nganmengzeferino', 'BrukONE', '2015-01-30 09:25:12', 'Jefferson house', 15, 15, 'metalgate'),
(392, 10671, 29.1, 2023.52, 1040.8, 0, 0, 89.5, 29.1, 2023.5, 1038.6, 0, 0, 89.495, 10, 30, 16, 95, 3, 'AccessHouse1', 'Err0r', '2015-02-01 17:18:44', 'AccessHouse1 - 12 Grove Street', 10, 10, NULL),
(393, 10671, 35.2, 2016.9, 1040.59, 0, 0, 0, 35.2, 2016.9, 1038.6, 0, 0, 0, 10, 30, 16, 95, 3, 'AccessHouse2', 'Err0r', '2015-02-01 17:21:16', 'AccessHouse2 - 12 Grove Street', 10, 10, NULL),
(394, 980, 282.4, -1319.9, 55.1, 0, 0, 34.7, 282.4, -1319.9, 49.1, 0, 0, 34.7, 5, 20, 60, 0, 0, 'parool', 'Kermoo', '2015-02-01 23:33:04', 'Richman Gate', 10, 10, 'metalgate'),
(395, 10184, 1951, -2317, 16.5, 0, 0, 0, 1951, -2317, 20.2, 0, 0, 0, 7, 70, 40, 1705, 25, '59', 'Nadr', '2015-02-02 21:25:43', 'Seized Cars', 5, 9, 'metalgate'),
(396, 988, 2031.7, 1465.4, 976, 0, 0, 90, 2031.7, 1462, 976, 0, 0, 90, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:27:50', 'Metro evidence 6', 6, NULL, NULL),
(397, 988, 2031.7, 1471.2, 976, 0, 0, 90, 2031.7, 1474.5, 976, 0, 0, 90, 10, 30, 40, 2250, 10, 'Metro - III', 'Sloth', '2015-02-03 16:29:55', 'Metro evidence 7', 6, NULL, NULL),
(398, 2949, 2006.9, -1688.5, 0.6, 0, 0, 90, 2005, -1688.5, 0.6, 0, 0, 90, 10, 0, 30, 407, 27, 'williamson12', 'BlueBerry', '2015-02-04 13:25:25', 'TWC Jewelry store storage gate', 9, 9, 'metalgate'),
(399, 1553, 2213.9, -45.1, 26.7, 0, 0, 90.246, 2213.9, -45.1, 23, 0, 0, 90.246, 10, 30, 37, 0, 0, 'babyboy', 'dfajoe', '2015-02-04 15:30:58', '', 6, 7, 'metalgate'),
(400, 1553, 2213.9, -47.9, 26.7, 0, 0, 90.246, 2213.9, -47.9, 23, 0, 0, 90.246, 10, 30, 37, 0, 0, 'babyboy', 'dfajoe', '2015-02-04 15:33:03', '', 6, 7, 'metalgate'),
(401, 2930, -141.861, 97.5, 999.51, 0, 0, 180, -141.861, 99.0634, 999.51, 0, 0, 180, 7, 40, 20, 1614, 3, '59', 'dfajoe', '2015-02-05 18:23:47', 'SAHP LV HQ', 3, 5, NULL),
(402, 3037, 2025.3, -132, -1.4, 0, 0, 0, 2025.3, -132, -3.5, 0, 0, 0, 7, 75, 45, 633, 1, '59', 'Nadr', '2015-02-06 05:52:51', 'SAHP Boat Impound Bottom', 9, 9, 'metalgate'),
(403, 3037, 2025.3, -132, 3, 0, 0, 0, 2024.9, -132, 7.4, 0, 10, 0, 7, 60, 60, 633, 1, '59', 'Nadr', '2015-02-06 05:53:55', 'SAHP Boat Impound Top', 9, 9, 'metalgate'),
(404, 3050, 2544.1, 83.5996, 24.5, 179.995, 0, 90, 2544.1, 83.6, 22.8, 179.995, 0, 90, 10, 20, 40, 0, 0, 'Kasnakalle', 'dfajoe', '2015-02-06 18:36:12', 'Enrique E. Young House Gate', 4, 6, 'metalgate'),
(405, 980, 617.1, -1640.6, 15, 0, 0, 290, 619.078, -1651.77, 15, 0, 0, 90, 1, 30, 40, 2, 0, '', 'Nadr', '2015-02-07 03:22:25', 'Test', NULL, NULL, 'metalgate'),
(406, 2949, 1383.9, 1466.44, 9.91, 0, 0, 90, 1383.9, 1466.58, 9.91, 0, 0, 0, 10, 0, 20, 27654, 31, 'Metro - II', 'Sloth', '2015-02-08 17:58:03', 'PD Rescue 1', 5, NULL, NULL),
(407, 976, 1413.9, 242, 18.34, 0, 0, 65.995, 1412.12, 238, 18.34, 0, 0, 66, 2, 0, 30, 0, 0, 'sacmastaff', 'Belgica', '2015-02-09 16:56:56', 'Warehouse Blueberry', 20, 20, 'metalgate'),
(408, 3050, -470.7, -183.1, 79.7, 0, 0, 0, -466.1, -183.1, 79.7, 0, 0, 0, 10, 0, 15, 0, 0, 'Milesliveshere', 'Err0r', '2015-02-10 20:06:19', 'Miles Morrison', 10, 10, 'metalgate'),
(409, 3050, -485.7, -182.9, 79.7, 0, 0, 0, -481.1, -182.9, 79.7, 0, 0, 0, 10, 0, 15, 0, 0, 'Mileslivesherealso', 'Err0r', '2015-02-10 20:05:16', 'Miles Morrison ', 10, 10, 'metalgate'),
(410, 1553, 141.15, -1787.35, 2.29, 0, 0, 299.3, 141.15, -1787.35, 1.18, 0, 0, 299.3, 10, 0, 15, 0, 0, 'dockshop', 'einschtein', '2015-02-10 13:03:32', 'Verona Beach Store Supply', 9, 9, NULL),
(411, 969, 999.9, -645.2, 120.5, 0, 0, 25, 992, -649, 120.5, 0, 0, 25, 5, 30, 50, 0, 0, '1996', 'Kermoo', '2015-02-18 18:19:51', 'Kermoo', 10, 10, 'metalgate');

-- --------------------------------------------------------

--
-- Table structure for table `health_diagnose`
--

CREATE TABLE `health_diagnose` (
  `uniqueID` int(11) DEFAULT NULL,
  `int_diagnose` varchar(255) DEFAULT NULL,
  `ext_diagnose` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `informationicons`
--

CREATE TABLE `informationicons` (
  `id` int(10) DEFAULT NULL,
  `createdby` text DEFAULT NULL,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  `rx` float DEFAULT NULL,
  `ry` float DEFAULT NULL,
  `rz` float DEFAULT NULL,
  `interior` float DEFAULT NULL,
  `dimension` float DEFAULT NULL,
  `information` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `insurance_data`
--

CREATE TABLE `insurance_data` (
  `policyid` int(11) NOT NULL,
  `customername` varchar(45) NOT NULL,
  `vehicleid` int(11) NOT NULL,
  `protection` varchar(45) NOT NULL,
  `deductible` int(11) NOT NULL,
  `date` date NOT NULL,
  `claims` float NOT NULL,
  `cashout` float NOT NULL,
  `premium` int(11) NOT NULL,
  `insurancefaction` int(10) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `insurance_factions`
--

CREATE TABLE `insurance_factions` (
  `factionID` int(11) NOT NULL,
  `name` varchar(45) NOT NULL,
  `gen_maxi` float NOT NULL DEFAULT 0.005,
  `news` text DEFAULT NULL,
  `subscription` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `interiors`
--

CREATE TABLE `interiors` (
  `id` int(11) NOT NULL,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 0,
  `type` int(1) DEFAULT 0,
  `owner` int(11) DEFAULT -1,
  `locked` int(1) DEFAULT 0,
  `cost` int(11) DEFAULT 0,
  `name` text DEFAULT NULL,
  `interior` int(5) DEFAULT 0,
  `interiorx` float DEFAULT 0,
  `interiory` float DEFAULT 0,
  `interiorz` float DEFAULT 0,
  `dimensionwithin` int(5) DEFAULT 0,
  `interiorwithin` int(5) DEFAULT 0,
  `angle` float DEFAULT 0,
  `angleexit` float DEFAULT 0,
  `supplies` int(11) DEFAULT 100,
  `safepositionX` float DEFAULT NULL,
  `safepositionY` float DEFAULT NULL,
  `safepositionZ` float DEFAULT NULL,
  `safepositionRZ` float DEFAULT NULL,
  `disabled` tinyint(3) UNSIGNED DEFAULT 0,
  `lastused` datetime NOT NULL DEFAULT current_timestamp(),
  `deleted` varchar(45) NOT NULL DEFAULT '0',
  `createdDate` datetime NOT NULL DEFAULT current_timestamp(),
  `creator` varchar(45) DEFAULT NULL,
  `isLightOn` tinyint(4) NOT NULL DEFAULT 0,
  `keypad_lock` int(11) DEFAULT NULL,
  `keypad_lock_pw` varchar(32) DEFAULT NULL,
  `keypad_lock_auto` tinyint(1) DEFAULT NULL,
  `uploaded_interior` datetime DEFAULT NULL,
  `faction` int(11) DEFAULT 0,
  `protected_until` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `interior_business`
--

CREATE TABLE `interior_business` (
  `intID` int(11) NOT NULL,
  `businessNote` varchar(101) NOT NULL DEFAULT 'Welcome to our business!'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves info about businesses - Maxime';

-- --------------------------------------------------------

--
-- Table structure for table `interior_logs`
--

CREATE TABLE `interior_logs` (
  `log_id` int(11) NOT NULL,
  `date` text DEFAULT NULL,
  `intID` int(11) DEFAULT NULL,
  `action` text DEFAULT NULL,
  `actor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Stores all admin actions on interiors - Monitored by Interio';

-- --------------------------------------------------------

--
-- Table structure for table `interior_notes`
--

CREATE TABLE `interior_notes` (
  `id` int(11) NOT NULL,
  `intid` int(11) NOT NULL,
  `creator` int(11) NOT NULL DEFAULT 0,
  `note` text NOT NULL,
  `date` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `interior_textures`
--

CREATE TABLE `interior_textures` (
  `id` int(11) NOT NULL,
  `interior` int(11) NOT NULL,
  `texture` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `index` int(10) UNSIGNED NOT NULL,
  `type` tinyint(3) UNSIGNED NOT NULL,
  `owner` int(10) UNSIGNED NOT NULL,
  `itemID` int(10) NOT NULL,
  `itemValue` text NOT NULL,
  `protected` int(100) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jailed`
--

CREATE TABLE `jailed` (
  `id` int(11) NOT NULL,
  `charid` int(11) NOT NULL,
  `charactername` text NOT NULL,
  `jail_time` bigint(12) NOT NULL,
  `convictionDate` datetime DEFAULT NULL,
  `updatedBy` text NOT NULL,
  `charges` text NOT NULL,
  `cell` text NOT NULL,
  `fine` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `jobID` int(11) NOT NULL DEFAULT 0,
  `jobCharID` int(11) NOT NULL DEFAULT -1,
  `jobLevel` int(11) NOT NULL DEFAULT 1,
  `jobProgress` int(11) NOT NULL DEFAULT 0,
  `jobTruckingRuns` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves job info, skill level and progress - Maxime' ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `jobs`
--

INSERT INTO `jobs` (`jobID`, `jobCharID`, `jobLevel`, `jobProgress`, `jobTruckingRuns`) VALUES
(4, 3, 1, 0, 0),
(2, 3, 1, 0, 0),
(3, 3, 1, 0, 0),
(2, 1, 1, 0, 0),
(3, 1, 11, 11, 0),
(5, 1, 1, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `jobs_trucker_orders`
--

CREATE TABLE `jobs_trucker_orders` (
  `orderID` int(11) NOT NULL,
  `orderX` float NOT NULL DEFAULT 0,
  `orderY` float NOT NULL DEFAULT 0,
  `orderZ` float NOT NULL DEFAULT 0,
  `orderWeight` int(11) NOT NULL DEFAULT 0,
  `orderName` text NOT NULL,
  `orderInterior` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves info about customer orders to create markers for truck';

--
-- Dumping data for table `jobs_trucker_orders`
--

INSERT INTO `jobs_trucker_orders` (`orderID`, `orderX`, `orderY`, `orderZ`, `orderWeight`, `orderName`, `orderInterior`) VALUES
(1, 1177.36, -1324.32, 14.067, 1, '1', 11),
(2, 1776.94, -1898.49, 13.3871, 0, 'LS', 0);

-- --------------------------------------------------------

--
-- Table structure for table `leo_impound_lot`
--

CREATE TABLE `leo_impound_lot` (
  `lane` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `rx` float NOT NULL,
  `ry` float NOT NULL,
  `rz` float NOT NULL,
  `int` float NOT NULL,
  `dim` float NOT NULL,
  `faction` int(11) NOT NULL,
  `veh` int(11) NOT NULL DEFAULT 0,
  `fine` int(11) NOT NULL DEFAULT 0,
  `release_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lifts`
--

CREATE TABLE `lifts` (
  `id` int(11) NOT NULL,
  `disabled` tinyint(1) NOT NULL DEFAULT 0,
  `comment` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lift_floors`
--

CREATE TABLE `lift_floors` (
  `id` int(11) NOT NULL,
  `lift` int(11) NOT NULL,
  `x` float(10,6) DEFAULT 0.000000,
  `y` float(10,6) DEFAULT 0.000000,
  `z` float(10,6) DEFAULT 0.000000,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `floor` varchar(3) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lottery`
--

CREATE TABLE `lottery` (
  `characterid` int(255) NOT NULL,
  `ticketnumber` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `mdcusers`
--

CREATE TABLE `mdcusers` (
  `user_name` varchar(20) NOT NULL,
  `password` varchar(20) NOT NULL DEFAULT '123',
  `high_command` int(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_apb`
--

CREATE TABLE `mdc_apb` (
  `id` int(11) NOT NULL,
  `person_involved` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `doneby` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `organization` varchar(10) NOT NULL DEFAULT 'LSPD'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_calls`
--

CREATE TABLE `mdc_calls` (
  `id` int(11) NOT NULL,
  `caller` varchar(50) NOT NULL,
  `number` varchar(10) NOT NULL,
  `description` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_crimes`
--

CREATE TABLE `mdc_crimes` (
  `id` int(11) NOT NULL,
  `crime` varchar(255) NOT NULL,
  `punishment` varchar(255) NOT NULL,
  `character` int(11) NOT NULL,
  `officer` int(11) NOT NULL,
  `timestamp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_criminals`
--

CREATE TABLE `mdc_criminals` (
  `character` int(11) NOT NULL,
  `dob` varchar(10) NOT NULL DEFAULT 'mm/dd/yyyy',
  `ethnicity` varchar(50) NOT NULL DEFAULT 'Unknown',
  `phone` varchar(10) NOT NULL DEFAULT 'Unknown',
  `occupation` varchar(50) NOT NULL DEFAULT 'Unknown',
  `address` varchar(50) NOT NULL DEFAULT 'Unknown',
  `photo` int(11) NOT NULL DEFAULT -1,
  `details` varchar(255) NOT NULL DEFAULT 'None',
  `created_by` int(11) NOT NULL DEFAULT 0,
  `wanted` int(11) NOT NULL DEFAULT 0,
  `wanted_by` int(11) NOT NULL DEFAULT 0,
  `wanted_details` varchar(255) DEFAULT NULL,
  `pilot_details` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_faa_events`
--

CREATE TABLE `mdc_faa_events` (
  `id` int(11) NOT NULL,
  `crime` varchar(255) NOT NULL,
  `punishment` varchar(255) NOT NULL,
  `character` int(11) NOT NULL,
  `officer` int(11) NOT NULL,
  `timestamp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_faa_licenses`
--

CREATE TABLE `mdc_faa_licenses` (
  `id` int(11) NOT NULL,
  `character` int(11) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `license` int(2) NOT NULL,
  `value` int(4) DEFAULT NULL,
  `officer` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_impounds`
--

CREATE TABLE `mdc_impounds` (
  `id` int(11) NOT NULL,
  `veh` int(11) NOT NULL,
  `content` text DEFAULT NULL,
  `reporter` text DEFAULT NULL,
  `date` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mdc_users`
--

CREATE TABLE `mdc_users` (
  `id` int(11) NOT NULL,
  `user` varchar(30) NOT NULL,
  `pass` varchar(30) NOT NULL,
  `level` int(11) NOT NULL,
  `organization` varchar(30) NOT NULL DEFAULT 'LSPD'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `mdc_users`
--

INSERT INTO `mdc_users` (`id`, `user`, `pass`, `level`, `organization`) VALUES
(1, 'LSPD', 'qwe', 2, 'LSPD');

-- --------------------------------------------------------

--
-- Table structure for table `motds`
--

CREATE TABLE `motds` (
  `id` int(11) NOT NULL,
  `title` varchar(70) NOT NULL,
  `content` text NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `expiration_date` datetime DEFAULT NULL,
  `author` int(11) DEFAULT NULL,
  `dismissable` tinyint(1) NOT NULL DEFAULT 1,
  `audiences` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `motds`
--

INSERT INTO `motds` (`id`, `title`, `content`, `creation_date`, `expiration_date`, `author`, `dismissable`, `audiences`) VALUES
(2, 'Добро пожаловать', 'Добро пожаловать на United RolePlay 2.0\n\nВ этом обновлении большая часть работы была сконцентрирована на исправлении серверных ошибок, приводящих к нестабильной работе мода, а так же перевода другой части мода, и небольших визуальных изменений.\n\nВесь список изменений, а так же помощь по моду вы можете посмотреть на https://SEEGame.ru/united', NULL, NULL, 1, 1, '[ [ [ 0, 0 ] ] ]');

-- --------------------------------------------------------

--
-- Table structure for table `motd_read`
--

CREATE TABLE `motd_read` (
  `id` int(11) NOT NULL,
  `motdid` int(11) NOT NULL,
  `userid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Note down everyone that read and dismissed the motd.';

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `title` text DEFAULT NULL,
  `details` text DEFAULT NULL,
  `date` text DEFAULT NULL,
  `read` tinyint(1) NOT NULL DEFAULT 0,
  `offline_pm` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `objects`
--

CREATE TABLE `objects` (
  `id` int(11) NOT NULL,
  `model` int(6) NOT NULL DEFAULT 0,
  `posX` float(12,7) NOT NULL DEFAULT 0.0000000,
  `posY` float(12,7) NOT NULL DEFAULT 0.0000000,
  `posZ` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotX` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotY` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotZ` float(12,7) NOT NULL DEFAULT 0.0000000,
  `interior` int(5) NOT NULL,
  `dimension` int(5) NOT NULL,
  `comment` varchar(50) DEFAULT NULL,
  `solid` int(1) NOT NULL DEFAULT 1,
  `doublesided` int(1) NOT NULL DEFAULT 0,
  `scale` float(12,7) DEFAULT NULL,
  `breakable` int(1) NOT NULL DEFAULT 0,
  `alpha` int(11) NOT NULL DEFAULT 255
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(6) NOT NULL,
  `txnid` varchar(20) NOT NULL,
  `payment_amount` decimal(7,2) NOT NULL,
  `payment_status` varchar(25) NOT NULL,
  `itemid` varchar(25) NOT NULL,
  `createdtime` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `paynspray`
--

CREATE TABLE `paynspray` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `paynspray`
--

INSERT INTO `paynspray` (`id`, `x`, `y`, `z`, `dimension`, `interior`) VALUES
(1, 1911.106445, -1776.103516, 13.411722, 0, 0),
(2, 2064.333984, -1831.360352, 13.546875, 0, 0),
(3, 1850.312500, -1856.445313, 13.382813, 0, 0),
(4, 538.561523, 87.181641, 1044.474609, 8, 24);

-- --------------------------------------------------------

--
-- Table structure for table `pd_tickets`
--

CREATE TABLE `pd_tickets` (
  `id` int(11) NOT NULL,
  `vehid` int(11) NOT NULL,
  `reason` text NOT NULL,
  `amount` int(11) NOT NULL,
  `issuer` int(11) DEFAULT NULL,
  `time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `peds`
--

CREATE TABLE `peds` (
  `id` int(11) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `type` varchar(100) DEFAULT NULL,
  `behaviour` int(3) DEFAULT 1,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `rotation` float NOT NULL,
  `interior` int(5) NOT NULL,
  `dimension` int(5) NOT NULL,
  `skin` int(1) DEFAULT NULL,
  `money` bigint(20) NOT NULL DEFAULT 0,
  `gender` int(1) DEFAULT NULL,
  `stats` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `owner_type` int(1) NOT NULL DEFAULT 0,
  `owner` int(11) DEFAULT NULL,
  `animation` varchar(255) DEFAULT NULL,
  `synced` tinyint(1) NOT NULL DEFAULT 0,
  `nametag` tinyint(1) NOT NULL DEFAULT 1,
  `frozen` tinyint(1) NOT NULL DEFAULT 0,
  `comment` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ped_inventory`
--

CREATE TABLE `ped_inventory` (
  `index` int(10) UNSIGNED NOT NULL,
  `type` tinyint(3) UNSIGNED NOT NULL,
  `owner` int(10) UNSIGNED NOT NULL,
  `itemID` int(10) NOT NULL,
  `itemValue` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ped_mission`
--

CREATE TABLE `ped_mission` (
  `char_id` int(11) NOT NULL,
  `mission` varchar(255) NOT NULL,
  `value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phones`
--

CREATE TABLE `phones` (
  `phonenumber` int(1) NOT NULL,
  `turnedon` smallint(1) NOT NULL DEFAULT 1,
  `secretnumber` smallint(1) NOT NULL DEFAULT 0,
  `phonebook` varchar(40) NOT NULL DEFAULT '0',
  `ringtone` smallint(1) NOT NULL DEFAULT 3,
  `contact_limit` int(5) NOT NULL DEFAULT 50,
  `boughtby` int(11) NOT NULL DEFAULT -1,
  `bought_date` datetime DEFAULT NULL,
  `sms_tone` smallint(1) NOT NULL DEFAULT 7,
  `keypress_tone` smallint(1) NOT NULL DEFAULT 1,
  `tone_volume` smallint(2) NOT NULL DEFAULT 10
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `phones`
--

INSERT INTO `phones` (`phonenumber`, `turnedon`, `secretnumber`, `phonebook`, `ringtone`, `contact_limit`, `boughtby`, `bought_date`, `sms_tone`, `keypress_tone`, `tone_volume`) VALUES
(409143, 1, 0, '0', 1, 50, -1, NULL, 7, 1, 10),
(488794, 1, 0, '1', 14, 50, 1, NULL, 7, 0, 10);

-- --------------------------------------------------------

--
-- Table structure for table `phone_contacts`
--

CREATE TABLE `phone_contacts` (
  `id` int(11) NOT NULL,
  `phone` bigint(20) NOT NULL,
  `entryName` varchar(50) DEFAULT NULL,
  `entryNumber` bigint(20) NOT NULL,
  `entryEmail` varchar(60) DEFAULT NULL,
  `entryAddress` varchar(100) DEFAULT NULL,
  `entryFavorited` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_history`
--

CREATE TABLE `phone_history` (
  `id` int(11) NOT NULL,
  `from` bigint(20) NOT NULL,
  `to` bigint(20) NOT NULL,
  `state` tinyint(1) NOT NULL DEFAULT 1,
  `date` text DEFAULT NULL,
  `private` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_sms`
--

CREATE TABLE `phone_sms` (
  `id` int(11) NOT NULL,
  `from` bigint(20) NOT NULL,
  `to` bigint(20) NOT NULL,
  `content` varchar(200) NOT NULL,
  `date` text DEFAULT NULL,
  `viewed` tinyint(1) NOT NULL DEFAULT 0,
  `private` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pilot_notams`
--

CREATE TABLE `pilot_notams` (
  `id` int(11) NOT NULL,
  `information` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `publicphones`
--

CREATE TABLE `publicphones` (
  `id` int(10) UNSIGNED NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `dimension` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `publicphones`
--

INSERT INTO `publicphones` (`id`, `x`, `y`, `z`, `dimension`) VALUES
(1, 1197.78, -1331.22, 13.3984, 0),
(2, 1184.94, -1330.17, 13.5749, 0);

-- --------------------------------------------------------

--
-- Table structure for table `radio_stations`
--

CREATE TABLE `radio_stations` (
  `id` int(11) NOT NULL,
  `station_name` varchar(64) DEFAULT NULL,
  `source` text DEFAULT NULL,
  `owner` int(11) NOT NULL DEFAULT 0,
  `register_date` datetime DEFAULT NULL,
  `expire_date` datetime DEFAULT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `order` int(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Dynamic radio stations.';

--
-- Dumping data for table `radio_stations`
--

INSERT INTO `radio_stations` (`id`, `station_name`, `source`, `owner`, `register_date`, `expire_date`, `enabled`, `order`) VALUES
(1, 'DEFJAY', 'http://he-srv1.defjay.com:80', 0, NULL, NULL, 1, 12),
(2, 'Black Beats FM', 'http://stream3.blackbeats.fm/', 0, NULL, NULL, 1, 14),
(3, 'Радио Рекорд', 'http://air.radiorecord.ru:8101/rr_320', 0, NULL, NULL, 1, 12),
(4, 'Vice City 80s Hits', 'http://us1.internet-radio.com:8180/', 0, NULL, NULL, 1, NULL),
(5, 'Ultra Radio', 'http://uk5.internet-radio.com:8233/', 0, NULL, NULL, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `ramps`
--

CREATE TABLE `ramps` (
  `id` int(2) NOT NULL,
  `position` text DEFAULT NULL,
  `interior` int(2) DEFAULT NULL,
  `dimension` int(2) DEFAULT NULL,
  `rotation` int(5) DEFAULT NULL,
  `creator` text DEFAULT NULL,
  `state` int(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `ramps`
--

INSERT INTO `ramps` (`id`, `position`, `interior`, `dimension`, `rotation`, `creator`, `state`) VALUES
(2, '[ [ 1620.485595703125, 61.808090209960938, 35.615306854248047 ] ]', 0, 0, 15, 'Bratila Cristian', 0),
(3, '[ [ 205.5168604204088, -1865.716051453001, 1.458645439147949 ] ]', 0, 0, 324, 'Misha Popka', 0);

-- --------------------------------------------------------

--
-- Table structure for table `restricted_freqs`
--

CREATE TABLE `restricted_freqs` (
  `id` int(11) NOT NULL,
  `frequency` text DEFAULT NULL,
  `limitedto` int(5) DEFAULT NULL,
  `addedby` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sapt_destinations`
--

CREATE TABLE `sapt_destinations` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `destinationID` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `sapt_destinations`
--

INSERT INTO `sapt_destinations` (`id`, `name`, `destinationID`) VALUES
(1, 'San Andreas Public Transport', '001'),
(2, 'To Depot', '005'),
(3, 'Charter', '010'),
(4, 'Not on Route', '013'),
(5, 'Test drive', '014'),
(6, 'Central Bus Station', '100'),
(7, 'East LS Beach', '101'),
(8, 'RS Haul', '102'),
(9, 'Ocean Docks', '103'),
(10, 'Los Santos', '901'),
(11, 'Dillimore', '902');

-- --------------------------------------------------------

--
-- Table structure for table `sapt_locations`
--

CREATE TABLE `sapt_locations` (
  `id` int(11) NOT NULL,
  `route` int(11) NOT NULL,
  `stopID` int(11) NOT NULL,
  `name` text NOT NULL,
  `posX` float NOT NULL,
  `posY` float NOT NULL,
  `posZ` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `sapt_locations`
--

INSERT INTO `sapt_locations` (`id`, `route`, `stopID`, `name`, `posX`, `posY`, `posZ`) VALUES
(1, 1, 1, 'Ocean Docks', 2680.2, -2481.6, 13.5),
(2, 1, 2, 'Industrial', 2302.7, -2095.8, 13.3),
(3, 1, 3, 'Ganton', 2283.9, -1734.6, 13.4),
(4, 1, 4, 'Sea Street', 2739.2, -1442.4, 30.3),
(5, 1, 5, 'Jefferson', 2173.4, -1158.7, 24.7),
(6, 1, 6, 'Los Santos Hospital', 2110.1, -1439.6, 23.8),
(7, 1, 7, 'Idlewood Gas Station', 1922.3, -1749.1, 13.4),
(8, 1, 8, 'City Hall', 1467.2, -1729.5, 13.4),
(9, 1, 9, 'Star Tower', 1563.7, -1295.9, 16.9),
(10, 1, 10, 'St. Lawrence', 1340.3, -1176, 23.1),
(11, 1, 11, 'Commerce Mall', 1132.2, -1393, 13.5),
(12, 1, 12, 'Department of Motor Vehicles', 1035.2, -1733, 13.4),
(13, 1, 13, 'Expressway 425-West', 735.2, -1757.6, 14),
(14, 1, 14, 'RS Haul', -124.5, -1201.7, 2.7),
(15, 2, 1, 'RS Haul', -117.8, -1169, 2.7),
(16, 2, 2, 'Expressway 425-West', 714, -1772, 13.8),
(17, 2, 3, 'Department of Motor Vehicles', 1039.8, -1738.5, 13.4),
(18, 2, 4, 'Commerce Mall', 1121.5, -1408.1, 13.4),
(19, 2, 5, 'St. Lawrence', 1359.8, -1175.6, 23.2),
(20, 2, 6, 'Star Tower', 1569.6, -1304.7, 17.1),
(21, 2, 7, 'City Hall', 1451.4, -1734.6, 13.4),
(22, 2, 8, 'Idlewood Gas Station', 1921.1, -1754.9, 13.4),
(23, 2, 9, 'Los Santos Hospital', 2114.7, -1445.6, 23.8),
(24, 2, 10, 'Jefferson', 2178, -1160.2, 24.6),
(25, 2, 11, 'Sea Street', 2720.3, -1477.5, 30.3),
(26, 2, 12, 'Ganton', 2276.4, -1730, 13.4),
(27, 2, 13, 'Industrial', 2300.6, -2101.3, 13.3),
(28, 2, 14, 'Ocean Docks', 2680.4, -2472.4, 13.5),
(29, 3, 1, 'Central Bus Station', 1939.3, -1727.2, 13.4),
(30, 3, 2, 'Dillimore', 684.6, -506.7, 16.2),
(31, 4, 1, 'Dillimore', 684.4, -506.1, 16.2),
(32, 4, 2, 'Central Bus Station', 1939, -1725, 13.4);

-- --------------------------------------------------------

--
-- Table structure for table `sapt_routes`
--

CREATE TABLE `sapt_routes` (
  `id` int(11) NOT NULL,
  `line` int(11) NOT NULL,
  `route` int(11) NOT NULL,
  `destination` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `sapt_routes`
--

INSERT INTO `sapt_routes` (`id`, `line`, `route`, `destination`) VALUES
(1, 901, 1, '102'),
(2, 901, 2, '103'),
(3, 101, 1, '902'),
(4, 101, 2, '901');

-- --------------------------------------------------------

--
-- Table structure for table `serial_whitelist`
--

CREATE TABLE `serial_whitelist` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `serial` varchar(32) NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `last_login_ip` varchar(15) DEFAULT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `id` int(11) NOT NULL,
  `name` text DEFAULT NULL,
  `value` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sfia_pilots`
--

CREATE TABLE `sfia_pilots` (
  `id` int(11) NOT NULL,
  `charactername` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shops`
--

CREATE TABLE `shops` (
  `id` int(11) NOT NULL,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 0,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `shoptype` tinyint(4) DEFAULT 0,
  `rotationz` float NOT NULL DEFAULT 0,
  `skin` int(11) DEFAULT -1,
  `sPendingWage` int(11) NOT NULL DEFAULT 0,
  `sIncome` bigint(20) NOT NULL DEFAULT 0,
  `sCapacity` int(11) NOT NULL DEFAULT 10,
  `sSales` varchar(5000) NOT NULL DEFAULT '',
  `pedName` text DEFAULT NULL,
  `deletedBy` int(11) NOT NULL DEFAULT 0,
  `faction_belong` int(11) NOT NULL DEFAULT 0,
  `faction_access` tinyint(3) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shop_contacts_info`
--

CREATE TABLE `shop_contacts_info` (
  `npcID` int(11) NOT NULL,
  `sOwner` text DEFAULT NULL,
  `sPhone` text DEFAULT NULL,
  `sEmail` text DEFAULT NULL,
  `sForum` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves data about business''s owners in shop system - MAXIME';

-- --------------------------------------------------------

--
-- Table structure for table `shop_products`
--

CREATE TABLE `shop_products` (
  `npcID` int(11) DEFAULT NULL,
  `pItemID` int(11) DEFAULT NULL,
  `pItemValue` text DEFAULT NULL,
  `pDesc` text DEFAULT NULL,
  `pPrice` text DEFAULT NULL,
  `pDate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `pID` int(11) NOT NULL,
  `pQuantity` int(11) NOT NULL DEFAULT 1,
  `pSetQuantity` int(11) NOT NULL DEFAULT 1,
  `pRestockInterval` int(11) DEFAULT 0,
  `pRestockedDate` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Saves on-sale products from players, business system by Maxi';

-- --------------------------------------------------------

--
-- Table structure for table `slotmachines`
--

CREATE TABLE `slotmachines` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `rotation` decimal(10,6) DEFAULT 0.000000,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `slotmachines`
--

INSERT INTO `slotmachines` (`id`, `x`, `y`, `z`, `rotation`, `dimension`, `interior`) VALUES
(9, 1562.783203, -1707.068359, 28.094810, 5.660797, 0, 0),
(10, 1549.998047, -1650.479492, 13.257520, 179.203491, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `speedcams`
--

CREATE TABLE `speedcams` (
  `id` int(11) NOT NULL,
  `x` float(11,7) NOT NULL DEFAULT 0.0000000,
  `y` float(11,7) NOT NULL DEFAULT 0.0000000,
  `z` float(11,7) NOT NULL DEFAULT 0.0000000,
  `interior` int(3) NOT NULL DEFAULT 0 COMMENT 'Stores the location of the pernament speedcams',
  `dimension` int(5) NOT NULL DEFAULT 0,
  `maxspeed` int(4) NOT NULL DEFAULT 120,
  `radius` int(4) NOT NULL DEFAULT 2,
  `enabled` smallint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

--
-- Dumping data for table `speedcams`
--

INSERT INTO `speedcams` (`id`, `x`, `y`, `z`, `interior`, `dimension`, `maxspeed`, `radius`, `enabled`) VALUES
(1, 1596.5605469, -1732.1796875, 13.3828125, 0, 0, 60, 5, 1),
(2, 1349.2324219, -1426.7968750, 19.2979889, 0, 0, 90, 0, 1),
(3, 1350.1357422, -1425.3466797, 18.4534512, 0, 0, 90, 0, 1),
(5, 1349.9257812, -1418.9873047, 13.6863728, 0, 0, 90, 30, 1);

-- --------------------------------------------------------

--
-- Table structure for table `speedingviolations`
--

CREATE TABLE `speedingviolations` (
  `id` int(11) NOT NULL,
  `carID` int(11) NOT NULL,
  `time` datetime NOT NULL,
  `speed` int(5) NOT NULL,
  `area` varchar(50) NOT NULL,
  `personVisible` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `staff_changelogs`
--

CREATE TABLE `staff_changelogs` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `team` int(11) NOT NULL,
  `from_rank` int(11) NOT NULL,
  `to_rank` int(11) DEFAULT NULL,
  `by` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `date` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stats`
--

CREATE TABLE `stats` (
  `district` varchar(45) NOT NULL,
  `deaths` double DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suspectcrime`
--

CREATE TABLE `suspectcrime` (
  `id` int(11) NOT NULL,
  `suspect_name` text DEFAULT NULL,
  `time` text DEFAULT NULL,
  `date` text DEFAULT NULL,
  `officers` text DEFAULT NULL,
  `ticket` int(11) DEFAULT NULL,
  `arrest` int(11) DEFAULT NULL,
  `fine` int(11) DEFAULT NULL,
  `ticket_price` text DEFAULT NULL,
  `arrest_price` text DEFAULT NULL,
  `fine_price` text DEFAULT NULL,
  `illegal_items` text DEFAULT NULL,
  `details` text DEFAULT NULL,
  `done_by` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suspectdetails`
--

CREATE TABLE `suspectdetails` (
  `suspect_name` text DEFAULT NULL,
  `birth` text DEFAULT NULL,
  `gender` text DEFAULT NULL,
  `ethnicy` text DEFAULT NULL,
  `cell` int(5) DEFAULT 0,
  `occupation` text DEFAULT NULL,
  `address` text DEFAULT NULL,
  `other` text DEFAULT NULL,
  `is_wanted` int(1) DEFAULT 0,
  `wanted_reason` text DEFAULT NULL,
  `wanted_punishment` text DEFAULT NULL,
  `wanted_by` text DEFAULT NULL,
  `photo` text DEFAULT NULL,
  `done_by` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tags`
--

CREATE TABLE `tags` (
  `id` int(11) NOT NULL,
  `x` decimal(10,6) DEFAULT NULL,
  `y` decimal(10,6) DEFAULT NULL,
  `z` decimal(10,6) DEFAULT NULL,
  `interior` int(5) DEFAULT NULL,
  `dimension` int(5) DEFAULT NULL,
  `rx` decimal(10,6) DEFAULT NULL,
  `ry` decimal(10,6) DEFAULT NULL,
  `rz` decimal(10,6) DEFAULT NULL,
  `modelid` int(5) DEFAULT NULL,
  `creationdate` datetime DEFAULT NULL,
  `creator` int(11) NOT NULL DEFAULT -1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `tc_comments`
--

CREATE TABLE `tc_comments` (
  `id` int(11) NOT NULL,
  `poster` varchar(200) NOT NULL,
  `comment` text NOT NULL,
  `date` text DEFAULT NULL,
  `internal` tinyint(1) NOT NULL DEFAULT 0,
  `tcid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tc_tickets`
--

CREATE TABLE `tc_tickets` (
  `id` int(11) NOT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `assign_to` int(11) NOT NULL DEFAULT 0,
  `subcribers` varchar(500) NOT NULL DEFAULT ',',
  `date` text DEFAULT NULL,
  `creator` varchar(200) NOT NULL DEFAULT '0',
  `subject` text NOT NULL,
  `content` text NOT NULL,
  `private` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tempinteriors`
--

CREATE TABLE `tempinteriors` (
  `id` int(11) NOT NULL,
  `posX` float NOT NULL,
  `posY` float DEFAULT NULL,
  `posZ` float DEFAULT NULL,
  `interior` int(5) DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT 0,
  `uploaded_at` datetime DEFAULT NULL,
  `amount_paid` int(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `tempobjects`
--

CREATE TABLE `tempobjects` (
  `id` int(11) NOT NULL,
  `model` int(6) NOT NULL DEFAULT 0,
  `posX` float(12,7) NOT NULL DEFAULT 0.0000000,
  `posY` float(12,7) NOT NULL DEFAULT 0.0000000,
  `posZ` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotX` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotY` float(12,7) NOT NULL DEFAULT 0.0000000,
  `rotZ` float(12,7) NOT NULL DEFAULT 0.0000000,
  `interior` int(5) NOT NULL,
  `dimension` int(5) NOT NULL,
  `comment` varchar(50) DEFAULT NULL,
  `solid` int(1) DEFAULT 1,
  `doublesided` int(1) DEFAULT 0,
  `scale` float(12,7) DEFAULT 1.0000000,
  `breakable` int(1) DEFAULT 0,
  `alpha` int(11) NOT NULL DEFAULT 255
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `textures_animated`
--

CREATE TABLE `textures_animated` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `frames` text NOT NULL,
  `speed` int(4) NOT NULL,
  `createdBy` int(11) NOT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ticketreplies`
--

CREATE TABLE `ticketreplies` (
  `rid` int(11) NOT NULL,
  `tid` int(11) NOT NULL,
  `text` text NOT NULL,
  `by` text NOT NULL,
  `rank` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `tid` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `name` text NOT NULL,
  `status` text NOT NULL,
  `subject` text NOT NULL,
  `assigned` text NOT NULL,
  `priority` text NOT NULL,
  `username` text NOT NULL,
  `gamename` text NOT NULL,
  `text` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tokens`
--

CREATE TABLE `tokens` (
  `id` int(11) NOT NULL,
  `userid` int(11) DEFAULT NULL,
  `action` varchar(32) DEFAULT NULL,
  `token` varchar(32) NOT NULL,
  `data` varchar(500) DEFAULT NULL,
  `date` varchar(500) DEFAULT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Random token, used for security and validations - MAXIME';

-- --------------------------------------------------------

--
-- Table structure for table `towstats`
--

CREATE TABLE `towstats` (
  `id` int(11) NOT NULL,
  `character` int(11) NOT NULL,
  `vehicle` int(11) DEFAULT NULL,
  `vehicle_plate` varchar(8) DEFAULT NULL COMMENT 'vehicle plate at the time of towing, if any',
  `date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'date of towing'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Detailed information for TTR leaders who towed what and when';

-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `id` int(11) NOT NULL,
  `model` int(3) DEFAULT 0,
  `x` decimal(10,6) DEFAULT 0.000000,
  `y` decimal(10,6) DEFAULT 0.000000,
  `z` decimal(10,6) DEFAULT 0.000000,
  `rotx` decimal(10,6) DEFAULT 0.000000,
  `roty` decimal(10,6) DEFAULT 0.000000,
  `rotz` decimal(10,6) DEFAULT 0.000000,
  `currx` decimal(10,6) DEFAULT 0.000000,
  `curry` decimal(10,6) DEFAULT 0.000000,
  `currz` decimal(10,6) DEFAULT 0.000000,
  `currrx` decimal(10,6) DEFAULT 0.000000,
  `currry` decimal(10,6) DEFAULT 0.000000,
  `currrz` decimal(10,6) NOT NULL DEFAULT 0.000000,
  `fuel` int(3) DEFAULT 100,
  `engine` int(1) DEFAULT 0,
  `locked` int(1) DEFAULT 0,
  `lights` int(1) DEFAULT 0,
  `sirens` int(1) DEFAULT 0,
  `paintjob` int(11) DEFAULT 0,
  `hp` float DEFAULT 1000,
  `color1` varchar(50) DEFAULT '0',
  `color2` varchar(50) DEFAULT '0',
  `color3` varchar(50) DEFAULT NULL,
  `color4` varchar(50) DEFAULT NULL,
  `plate` text DEFAULT NULL,
  `faction` int(11) DEFAULT -1,
  `owner` int(11) DEFAULT -1,
  `job` int(11) DEFAULT -1,
  `tintedwindows` int(1) DEFAULT 0,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `currdimension` int(5) DEFAULT 0,
  `currinterior` int(5) DEFAULT 0,
  `enginebroke` int(1) DEFAULT 0,
  `items` text DEFAULT NULL,
  `itemvalues` text DEFAULT NULL,
  `Impounded` int(3) DEFAULT 0,
  `handbrake` int(1) DEFAULT 0,
  `safepositionX` float DEFAULT NULL,
  `safepositionY` float DEFAULT NULL,
  `safepositionZ` float DEFAULT NULL,
  `safepositionRZ` float DEFAULT NULL,
  `upgrades` varchar(150) DEFAULT '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]',
  `wheelStates` varchar(30) DEFAULT '[ [ 0, 0, 0, 0 ] ]',
  `panelStates` varchar(40) DEFAULT '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]',
  `doorStates` varchar(30) DEFAULT '[ [ 0, 0, 0, 0, 0, 0 ] ]',
  `odometer` int(15) DEFAULT 0,
  `headlights` varchar(30) DEFAULT '[ [ 255, 255, 255 ] ]',
  `variant1` int(3) DEFAULT NULL,
  `variant2` int(3) DEFAULT NULL,
  `description1` varchar(300) NOT NULL DEFAULT '',
  `description2` varchar(300) NOT NULL DEFAULT '',
  `description3` varchar(300) NOT NULL DEFAULT '',
  `description4` varchar(300) NOT NULL DEFAULT '',
  `description5` varchar(300) NOT NULL DEFAULT '',
  `suspensionLowerLimit` float DEFAULT NULL,
  `driveType` char(5) DEFAULT NULL,
  `deleted` int(11) NOT NULL DEFAULT 0,
  `chopped` tinyint(4) NOT NULL DEFAULT 0,
  `stolen` tinyint(4) NOT NULL DEFAULT 0,
  `lastUsed` datetime DEFAULT NULL,
  `creationDate` datetime DEFAULT NULL,
  `createdBy` int(11) DEFAULT NULL,
  `trackingdevice` text DEFAULT NULL,
  `registered` int(2) NOT NULL DEFAULT 1,
  `show_plate` int(2) NOT NULL DEFAULT 1,
  `show_vin` int(2) NOT NULL DEFAULT 1,
  `paintjob_url` varchar(255) DEFAULT NULL,
  `vehicle_shop_id` int(11) NOT NULL DEFAULT 0,
  `bulletproof` tinyint(4) NOT NULL DEFAULT 0,
  `textures` varchar(300) NOT NULL DEFAULT '[ [ ] ]',
  `business` int(11) NOT NULL DEFAULT -1,
  `protected_until` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `vehicles`
--

INSERT INTO `vehicles` (`id`, `model`, `x`, `y`, `z`, `rotx`, `roty`, `rotz`, `currx`, `curry`, `currz`, `currrx`, `currry`, `currrz`, `fuel`, `engine`, `locked`, `lights`, `sirens`, `paintjob`, `hp`, `color1`, `color2`, `color3`, `color4`, `plate`, `faction`, `owner`, `job`, `tintedwindows`, `dimension`, `interior`, `currdimension`, `currinterior`, `enginebroke`, `items`, `itemvalues`, `Impounded`, `handbrake`, `safepositionX`, `safepositionY`, `safepositionZ`, `safepositionRZ`, `upgrades`, `wheelStates`, `panelStates`, `doorStates`, `odometer`, `headlights`, `variant1`, `variant2`, `description1`, `description2`, `description3`, `description4`, `description5`, `suspensionLowerLimit`, `driveType`, `deleted`, `chopped`, `stolen`, `lastUsed`, `creationDate`, `createdBy`, `trackingdevice`, `registered`, `show_plate`, `show_vin`, `paintjob_url`, `vehicle_shop_id`, `bulletproof`, `textures`, `business`, `protected_until`) VALUES
(1, 497, 1549.994141, -1708.051758, 28.517839, 359.967041, 359.736328, 90.093384, 1549.994141, -1708.051758, 28.517839, 359.967041, 359.736328, 90.093384, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'EO0 7122', 1, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 552, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:51:58', '2023-06-23 13:29:41', 1, NULL, 1, 1, 1, NULL, 1, 0, '[ [ ] ]', -1, NULL),
(2, 497, 1547.413086, -1644.840820, 28.480495, 359.983521, 359.857178, 88.659668, 1547.414063, -1644.839844, 28.481110, 359.989014, 359.417725, 88.692627, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'YN6 5208', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:52:55', '2023-06-23 13:52:41', 1, NULL, 1, 1, 1, NULL, 1, 0, '[ [ ] ]', -1, NULL),
(3, 596, 2401.958984, 2529.550781, 10.583822, 359.708862, 0.000000, 359.099121, 2401.958984, 2529.550781, 10.583822, 359.708862, 0.000000, 359.099121, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'EQ9 5023', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 44, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:57:10', '2023-06-23 13:54:50', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(4, 596, 2406.778320, 2529.636719, 10.581859, 359.703369, 0.000000, 0.736084, 2406.778320, 2529.636719, 10.582411, 359.703369, 0.027466, 0.763550, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LO0 5704', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:57:26', '2023-06-23 13:55:17', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(5, 596, 2412.459961, 2529.573242, 10.585162, 359.714355, 0.000000, 0.318604, 2412.459961, 2529.573242, 10.585162, 359.714355, 0.000000, 0.318604, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GI2 9206', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:57:54', '2023-06-23 13:55:20', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(6, 596, 2417.322266, 2529.826172, 10.582650, 359.708862, 0.000000, 1.104126, 2417.322266, 2529.826172, 10.582650, 359.708862, 0.000000, 1.104126, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZJ8 5065', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 8, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:58:15', '2023-06-23 13:55:23', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(7, 596, 2423.189453, 2529.763672, 10.583053, 359.708862, 0.000000, 0.917358, 2423.189453, 2529.763672, 10.583053, 359.708862, 0.000000, 0.917358, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WL8 3625', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 1, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:58:36', '2023-06-23 13:55:27', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(8, 596, 2428.461914, 2529.608398, 10.585604, 359.714355, 0.000000, 1.966553, 2428.462891, 2529.609375, 10.586143, 359.714355, 0.000000, 1.999512, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZH7 1561', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:58:58', '2023-06-23 13:55:30', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(9, 596, 2433.784180, 2529.359375, 10.583338, 359.708862, 359.994507, 359.110107, 2433.784180, 2529.359375, 10.583338, 359.708862, 359.994507, 359.110107, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KC8 7210', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 13:59:23', '2023-06-23 13:55:33', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(10, 596, 2439.046875, 2529.394531, 10.582055, 359.703369, 0.000000, 0.862427, 1586.414063, -1677.341797, 5.655509, 359.324341, 1.021729, 22.186890, 55, 1, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KC8 5123', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 58, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:19:07', '2023-06-23 13:55:38', 1, NULL, 1, 1, 1, NULL, 2, 0, '[ [ ] ]', -1, NULL),
(11, 597, 2450.040039, 2529.134766, 10.761975, 359.879150, 359.983521, 1.203003, 1583.757813, -1677.982422, 5.837775, 359.862671, 0.027466, 110.044556, 55, 1, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZX7 4931', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 13:40:32', '2023-06-23 14:01:41', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(12, 597, 2482.320313, 2528.428711, 10.762476, 359.879150, 359.983521, 0.477905, 2482.321289, 2528.428711, 10.762972, 359.884644, 0.082397, 0.505371, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QD6 4701', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:04:40', '2023-06-23 14:01:43', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(13, 597, 2487.625000, 2528.285156, 10.763583, 359.879150, 359.983521, 2.378540, 2487.625977, 2528.285156, 10.764111, 359.879150, 0.010986, 2.406006, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CF4 9147', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 4, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:05:14', '2023-06-23 14:01:47', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(14, 597, 2444.829102, 2529.582031, 10.762568, 359.879150, 359.983521, 0.252686, 2444.829102, 2529.583008, 10.762924, 359.879150, 0.021973, 0.280151, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AN8 8019', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:02:26', '2023-06-23 14:01:50', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(15, 597, 2455.263672, 2528.947266, 10.762646, 359.879150, 359.983521, 1.977539, 2455.263672, 2528.947266, 10.763093, 359.879150, 0.010986, 2.005005, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BM2 8862', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:02:59', '2023-06-23 14:01:52', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(16, 597, 2460.522461, 2528.706055, 10.762850, 359.879150, 359.983521, 0.444946, 2460.523438, 2528.706055, 10.763258, 359.879150, 0.032959, 0.472412, 100, 0, 0, 1, 0, 0, 998, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KE5 3393', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 1 ] ]', '[ [ 0, 2, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:03:18', '2023-06-23 14:01:55', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(17, 597, 2471.158203, 2528.370117, 10.762498, 359.879150, 359.983521, 1.285400, 2471.159180, 2528.370117, 10.762898, 359.879150, 0.021973, 1.312866, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZX4 7664', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:03:58', '2023-06-23 14:01:57', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(18, 597, 2476.645508, 2528.621094, 10.762368, 359.879150, 359.983521, 0.395508, 2476.646484, 2528.621094, 10.762861, 359.879150, 0.021973, 0.428467, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DF8 7151', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:04:17', '2023-06-23 14:02:00', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(19, 597, 2466.121094, 2528.763672, 10.761845, 359.879150, 359.983521, 0.917358, 2466.122070, 2528.764648, 10.762320, 359.879150, 0.021973, 0.944824, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GV4 3751', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:03:39', '2023-06-23 14:02:03', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(20, 597, 2492.421875, 2528.218750, 10.762531, 359.879150, 359.983521, 359.126587, 2492.421875, 2528.218750, 10.762531, 359.879150, 359.983521, 359.126587, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LE6 7517', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:05:57', '2023-06-23 14:02:07', 1, NULL, 1, 1, 1, NULL, 3, 0, '[ [ ] ]', -1, NULL),
(21, 523, 2463.938477, 2483.895508, 10.388419, 359.214478, 0.000000, 88.758545, 2463.938477, 2483.895508, 10.388419, 359.214478, 0.000000, 88.758545, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FL4 7431', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:10:34', '2023-06-23 14:07:31', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(22, 523, 2464.834961, 2488.584961, 10.392137, 359.252930, 359.994507, 89.923096, 2464.834961, 2488.584961, 10.392137, 359.252930, 359.994507, 89.923096, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'YU4 1290', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:05:35', '2023-06-23 14:07:33', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(23, 523, 2461.164063, 2485.472656, 10.392704, 359.280396, 0.000000, 90.769043, 2461.164063, 2485.472656, 10.392704, 359.280396, 0.000000, 90.769043, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'US0 1061', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:08:52', '2023-06-23 14:07:33', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(24, 523, 2464.155273, 2485.454102, 10.383993, 359.121094, 359.961548, 88.137817, 2464.155273, 2485.454102, 10.383993, 359.121094, 359.961548, 88.137817, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WP4 4875', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 89, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 18:24:01', '2023-06-23 14:07:33', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(25, 523, 2461.208008, 2490.153320, 10.386471, 359.197998, 0.000000, 92.032471, 2461.208008, 2490.153320, 10.386471, 359.197998, 0.000000, 92.032471, 100, 0, 0, 1, 0, 0, 996, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BP1 2007', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 71, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:10:10', '2023-06-23 14:07:33', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(26, 523, 2464.334961, 2487.075195, 10.389839, 359.121094, 359.994507, 88.725586, 1157.720703, -1838.012695, 13.193903, 0.208740, 0.527344, 285.012817, 10, 1, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GP6 9321', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 11:47:46', '2023-06-23 14:07:34', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(27, 523, 2461.208984, 2487.091797, 10.390234, 359.230957, 359.994507, 91.016235, 2461.208984, 2487.091797, 10.390234, 359.230957, 359.994507, 91.016235, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KS3 7095', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:09:21', '2023-06-23 14:07:42', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(28, 523, 2461.386719, 2488.447266, 10.391303, 359.230957, 0.016479, 93.625488, 2461.386719, 2488.447266, 10.391303, 359.230957, 0.016479, 93.625488, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AB8 5199', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:09:42', '2023-06-23 14:07:42', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(29, 523, 2460.633789, 2483.855469, 10.392672, 359.258423, 0.000000, 90.862427, 2460.633789, 2483.855469, 10.392672, 359.258423, 0.000000, 90.862427, 100, 0, 0, 1, 0, 0, 999, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PC1 2031', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 105, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-23 14:08:55', '2023-06-23 14:07:42', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(30, 523, 2464.726563, 2489.962891, 10.385961, 359.181519, 0.000000, 88.456421, 2464.726563, 2489.962891, 10.385961, 359.181519, 0.000000, 88.456421, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'TO4 6709', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:06:15', '2023-06-25 22:06:03', 1, NULL, 1, 1, 1, NULL, 4, 0, '[ [ ] ]', -1, NULL),
(31, 525, 1570.496094, -1694.174805, 5.767666, 358.126831, 0.000000, 181.384277, 1570.497070, -1694.173828, 5.768112, 358.159790, 359.901123, 181.417236, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HN7 8772', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:17:18', '2023-06-25 22:08:12', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(32, 525, 1565.523438, -1694.250977, 5.765931, 358.099365, 0.000000, 181.961060, 1565.524414, -1694.250977, 5.766413, 358.110352, 0.038452, 181.988525, 100, 0, 0, 1, 0, 0, 999, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BQ0 4111', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 2, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:17:41', '2023-06-25 22:15:19', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(33, 525, 1560.538086, -1694.426758, 5.819488, 359.022217, 0.000000, 182.125854, 341.347656, -1492.865234, 76.401268, 357.879639, 359.994507, 255.195923, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PY9 4098', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 22:10:10', '2023-06-25 22:17:41', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(34, 416, 1232.154297, -1803.454102, 13.760587, 359.989014, 359.609985, 0.560303, 1232.155273, -1803.453125, 13.761120, 359.989014, 359.725342, 0.593262, 100, 0, 0, 1, 0, 3, 1000, '[ [ 179, 0, 0 ] ]', '[ [ 255, 255, 255 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'EX5 2581', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:22:01', '2023-06-25 22:21:14', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(35, 416, 1224.690430, -1803.382813, 13.758454, 0.038452, 359.609985, 0.554810, 1224.690430, -1803.381836, 13.759107, 0.038452, 359.758301, 0.593262, 100, 0, 0, 1, 0, 3, 984, '[ [ 208, 0, 0 ] ]', '[ [ 255, 255, 255 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'SQ0 7380', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 2, 2 ] ]', 53, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:22:33', '2023-06-25 22:21:16', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(36, 416, 1236.441406, -1803.258789, 13.758620, 0.038452, 359.609985, 1.115112, 1236.442383, -1803.257813, 13.759174, 0.038452, 359.719849, 1.142578, 100, 0, 0, 1, 0, 3, 995.5, '[ [ 222, 0, 0 ] ]', '[ [ 242, 242, 242 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZO9 3474', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 2, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:21:40', '2023-06-25 22:21:21', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(37, 416, 1221.377930, -1803.544922, 13.758715, 0.038452, 359.609985, 359.236450, 1221.377930, -1803.544922, 13.759214, 0.043945, 359.736328, 359.263916, 100, 0, 0, 1, 0, 3, 1000, '[ [ 186, 0, 0 ] ]', '[ [ 255, 255, 255 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CU5 6324', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:22:58', '2023-06-25 22:22:05', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(38, 416, 1236.103516, -1788.350586, 13.758485, 0.038452, 359.609985, 180.851440, 1236.104492, -1788.349609, 13.759068, 0.032959, 359.489136, 180.884399, 100, 0, 0, 1, 0, 3, 994.5, '[ [ 171, 0, 0 ] ]', '[ [ 255, 255, 255 ] ]', '[ [ 129, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CQ8 8924', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 2 ] ]', 51, '[ [ 20, 255, 252 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:23:27', '2023-06-25 22:23:03', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(39, 416, 1210.651367, -1803.499023, 13.759029, 0.038452, 359.609985, 359.384766, 1210.652344, -1803.499023, 13.759537, 0.038452, 359.725342, 359.412231, 100, 0, 0, 1, 0, 3, 980.5, '[ [ 208, 0, 0 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JI3 4355', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 2, 2 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:23:50', '2023-06-25 22:23:06', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(40, 416, 1206.359375, -1803.844727, 13.759042, 0.060425, 359.555054, 178.851929, 1206.360352, -1803.843750, 13.759549, 0.065918, 359.472656, 178.879395, 100, 0, 0, 1, 0, 3, 989.5, '[ [ 206, 4, 4 ] ]', '[ [ 253, 250, 250 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JP3 9381', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 1, 0 ] ]', '[ [ 2, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:24:13', '2023-06-25 22:23:52', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(41, 416, 1201.574219, -1787.927734, 13.758722, 0.038452, 359.609985, 180.532837, 1201.574219, -1787.927734, 13.758722, 0.038452, 359.609985, 180.532837, 100, 0, 0, 1, 0, 3, 997, '[ [ 180, 4, 4 ] ]', '[ [ 254, 253, 253 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CE3 4177', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 2, 0 ] ]', 11, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:24:34', '2023-06-25 22:23:55', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(42, 416, 1206.608398, -1788.118164, 13.758179, 0.038452, 359.609985, 180.483398, 1206.608398, -1788.118164, 13.758179, 0.038452, 359.609985, 180.483398, 100, 0, 0, 1, 0, 3, 1000, '[ [ 186, 0, 0 ] ]', '[ [ 255, 255, 255 ] ]', '[ [ 130, 0, 0 ] ]', '[ [ 79, 0, 0 ] ]', 'YK0 7813', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:24:55', '2023-06-25 22:24:16', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(43, 416, 1267.110265, -2063.005067, 59.577850, 0.000000, 0.000000, 359.662170, 1267.110229, -2063.005127, 59.577850, 0.000000, 0.000000, 359.662170, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AQ9 4378', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-25 22:41:12', '2023-06-25 22:41:12', 1, NULL, 1, 1, 1, NULL, 6, 0, '[ [ ] ]', -1, NULL),
(44, 470, 347.173828, -1472.982422, 76.672920, 359.873657, 0.016479, 218.292847, 347.173828, -1472.981445, 76.673424, 359.807739, 359.989014, 218.320313, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'SK3 5033', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:11:31', '2023-06-27 22:11:11', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(45, 507, 343.792969, -1474.806641, 76.289955, 359.450684, 359.967041, 214.568481, 343.793945, -1474.806641, 76.290474, 359.456177, 359.950562, 214.595947, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HX2 4062', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:32:57', '2023-06-27 22:32:40', 1, NULL, 1, 1, 1, NULL, 8, 0, '[ [ ] ]', -1, NULL),
(46, 425, 301.958008, -1555.908203, 77.053841, 2.010498, 0.000000, 344.729004, 301.958008, -1555.908203, 77.053841, 2.010498, 0.000000, 344.729004, 99, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'MM2 8895', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 135, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:34:22', '2023-06-27 22:33:40', 1, NULL, 1, 1, 1, NULL, 9, 0, '[ [ ] ]', -1, NULL),
(47, 487, 290.689453, -1550.911133, 76.718048, 0.258179, 359.692383, 348.975220, 290.690430, -1550.910156, 76.718552, 0.280151, 359.846191, 349.002686, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'IJ1 6550', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:35:49', '2023-06-27 22:35:04', 1, NULL, 1, 1, 1, NULL, 10, 0, '[ [ ] ]', -1, NULL),
(48, 400, 340.465820, -1476.737305, 76.299881, 0.115356, 359.994507, 215.557251, 340.466797, -1476.736328, 76.300385, 0.115356, 0.010986, 215.584717, 100, 0, 0, 1, 0, 3, 1000, '[ [ 255, 255, 255 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XD6 4230', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:38:56', '2023-06-27 22:38:33', 1, NULL, 1, 1, 1, NULL, 11, 0, '[ [ ] ]', -1, NULL),
(49, 602, 337.303711, -1478.964844, 76.321602, 0.225220, 0.000000, 217.688599, 337.303711, -1478.964844, 76.322044, 0.219727, 359.994507, 217.721558, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'RT6 7042', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:39:47', '2023-06-27 22:39:28', 1, NULL, 1, 1, 1, NULL, 12, 0, '[ [ ] ]', -1, NULL),
(50, 477, 334.202148, -1481.430664, 76.277237, 0.225220, 0.000000, 219.078369, 334.203125, -1481.430664, 76.277809, 0.225220, 359.994507, 219.105835, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PA5 9633', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:40:39', '2023-06-27 22:40:22', 1, NULL, 1, 1, 1, NULL, 13, 0, '[ [ ] ]', -1, NULL),
(51, 506, 1236.203125, -1665.219727, 11.488553, 0.362549, 0.000000, 185.839233, 1157.284180, -1837.871094, 13.605379, 0.362549, 0.000000, 185.839233, 45, 0, 1, 1, 0, 3, 1000, '[ [ 243, 142, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AN4 6576', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 1, '[ [ 255, 255, 255 ] ]', 255, 255, 'Price: 4.800.000$', 'X3', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 11:46:03', '2023-06-27 22:41:29', 1, NULL, 1, 1, 1, NULL, 14, 0, '[ [ ] ]', -1, NULL),
(52, 577, 303.567383, -1521.648438, 76.913582, 358.862915, 0.406494, 323.003540, 303.567383, -1521.648438, 76.913582, 358.862915, 0.406494, 323.003540, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KN0 4920', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:48:00', '2023-06-27 22:48:00', 1, NULL, 1, 1, 1, NULL, 15, 0, '[ [ ] ]', -1, NULL),
(53, 522, 355.075195, -1488.084961, 76.119919, 358.467407, 359.950562, 32.156982, 355.075195, -1488.084961, 76.119919, 358.467407, 359.950562, 32.156982, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HY2 2097', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 33, '[ [ 255, 255, 255 ] ]', 1, 3, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:49:16', '2023-06-27 22:49:01', 1, NULL, 1, 1, 1, NULL, 16, 0, '[ [ ] ]', -1, NULL),
(54, 496, 326.339844, -1486.722656, 76.311844, 359.972534, 359.983521, 209.064331, 326.339844, -1486.721680, 76.312355, 359.972534, 359.956055, 209.091797, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WP5 6277', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 38, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:50:15', '2023-06-27 22:49:51', 1, NULL, 1, 1, 1, NULL, 17, 0, '[ [ ] ]', -1, NULL),
(55, 554, 1896.004883, -1775.805664, 13.838658, 359.571533, 0.005493, 90.664673, 1896.005859, -1775.804688, 13.839217, 359.571533, 359.956055, 90.697632, 75, 0, 0, 1, 0, 3, 1000, '[ [ 36, 2, 2 ] ]', '[ [ 186, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GB6 7721', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 9180, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-07-10 02:24:48', '2023-06-27 22:50:43', 1, NULL, 1, 1, 1, NULL, 18, 0, '[ [ ] ]', -1, NULL),
(56, 526, 320.265625, -1492.858398, 76.007767, 0.175781, 359.994507, 220.006714, 320.265625, -1492.858398, 76.008270, 0.186768, 0.000000, 220.034180, 100, 0, 0, 1, 0, 3, 1000, '[ [ 80, 80, 80 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HL0 4736', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:52:05', '2023-06-27 22:51:51', 1, NULL, 1, 1, 1, NULL, 19, 0, '[ [ ] ]', -1, NULL),
(57, 402, 1895.912109, -1785.797852, 13.333060, 359.961548, 359.994507, 271.538086, 1895.912109, -1785.797852, 13.333060, 359.961548, 359.994507, 271.538086, 1, 0, 1, 2, 0, 3, 941.5, '[ [ 150, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QV1 2517', -1, 10, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 1, 0, 0, 0, 0, 1, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 5383, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-07-09 19:58:16', '2023-06-27 22:52:36', 1, NULL, 1, 1, 1, NULL, 20, 0, '[ [ ] ]', -1, NULL),
(58, 401, 313.238281, -1499.716797, 76.289719, 0.170288, 359.560547, 234.838257, 313.238281, -1499.716797, 76.289719, 0.170288, 359.560547, 234.838257, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DP0 9055', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:53:50', '2023-06-27 22:53:23', 1, NULL, 1, 1, 1, NULL, 21, 0, '[ [ ] ]', -1, NULL),
(59, 462, 353.275391, -1489.263672, 76.050034, 359.241943, 359.978027, 33.491821, 353.275391, -1489.263672, 76.050034, 359.241943, 359.978027, 33.491821, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DU7 3079', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:54:38', '2023-06-27 22:54:24', 1, NULL, 1, 1, 1, NULL, 22, 0, '[ [ ] ]', -1, NULL),
(60, 415, 1263.319336, -1644.701172, 13.159397, 0.170288, 359.983521, 168.316040, 1263.319336, -1644.701172, 13.159397, 0.164795, 359.983521, 168.316040, 45, 0, 1, 1, 0, 3, 1000, '[ [ 6, 1, 46 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WH2 9692', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 1, '[ [ 255, 255, 255 ] ]', 255, 255, 'Price: 3.800.000$', 'X15', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 13:24:01', '2023-06-27 22:55:07', 1, NULL, 1, 1, 1, NULL, 23, 0, '[ [ ] ]', -1, NULL),
(61, 550, 350.193359, -1491.372070, 76.332947, 0.109863, 0.021973, 34.628906, 350.194336, -1491.371094, 76.333488, 0.115356, 0.054932, 34.667358, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JR8 1156', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:56:27', '2023-06-27 22:56:09', 1, NULL, 1, 1, 1, NULL, 24, 0, '[ [ ] ]', -1, NULL),
(62, 479, 346.327148, -1494.353516, 76.517662, 0.741577, 0.021973, 38.638916, 346.327148, -1494.352539, 76.518250, 0.747070, 0.043945, 38.671875, 100, 0, 0, 1, 0, 3, 1000, '[ [ 188, 252, 197 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XE2 7372', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 22:58:02', '2023-06-27 22:57:39', 1, NULL, 1, 1, 1, NULL, 25, 0, '[ [ ] ]', -1, NULL),
(63, 545, 343.196289, -1497.244141, 75.985580, 0.307617, 0.021973, 41.154785, 343.197266, -1497.244141, 75.986084, 0.274658, 0.032959, 41.182251, 100, 0, 0, 1, 0, 3, 1000, '[ [ 255, 255, 255 ] ]', '[ [ 54, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GB0 6642', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 19, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:00:18', '2023-06-27 23:00:02', 1, NULL, 1, 1, 1, NULL, 26, 0, '[ [ ] ]', -1, NULL),
(64, 490, 339.773438, -1499.277344, 76.627052, 0.313110, 359.989014, 49.103394, 339.774414, -1499.277344, 76.627556, 0.362549, 0.005493, 49.130859, 100, 0, 0, 1, 0, 0, 997, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'MY9 4649', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 2, 0, 0, 0, 0, 2, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:04:32', '2023-06-27 23:03:28', 1, NULL, 1, 1, 1, NULL, 28, 0, '[ [ ] ]', -1, NULL),
(65, 587, 336.525391, -1503.064453, 76.253365, 359.972534, 359.972534, 44.423218, 336.525391, -1503.064453, 76.253922, 359.972534, 359.978027, 44.450684, 100, 0, 0, 1, 0, 0, 959, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FF4 9453', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 1, 0, 0, 0, 2, 1 ] ]', '[ [ 0, 2, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:05:29', '2023-06-27 23:05:11', 1, NULL, 1, 1, 1, NULL, 29, 0, '[ [ ] ]', -1, NULL),
(66, 521, 354.249023, -1488.623047, 76.213394, 358.835449, 0.560303, 39.331055, 354.249023, -1488.623047, 76.213394, 358.835449, 0.560303, 39.331055, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WJ2 6052', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 39, '[ [ 255, 255, 255 ] ]', 0, 3, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:06:17', '2023-06-27 23:06:03', 1, NULL, 1, 1, 1, NULL, 30, 0, '[ [ ] ]', -1, NULL),
(67, 520, 305.351563, -1540.569336, 77.188713, 0.346069, 359.994507, 74.871826, 305.351563, -1540.569336, 77.188713, 0.351563, 0.000000, 74.871826, 98, 0, 0, 1, 0, 0, 976, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'UK9 9802', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 3, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:08:05', '2023-06-27 23:07:00', 1, NULL, 1, 1, 1, NULL, 31, 0, '[ [ ] ]', -1, NULL),
(68, 565, 1225.834961, -1671.719727, 11.420873, 359.840698, 359.978027, 0.653687, 1225.835938, -1671.719727, 11.421467, 359.840698, 359.967041, 0.686646, 100, 0, 0, 1, 0, 0, 1000, '[ [ 72, 31, 30 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', 'RT2 6424', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:57:39', '2023-06-27 23:08:36', 1, NULL, 1, 1, 1, NULL, 32, 0, '[ [ ] ]', -1, NULL),
(69, 411, 1237.791016, -1648.344727, 11.244977, 0.543823, 0.071411, 258.420410, 1237.739258, -1648.333008, 11.244811, 0.543823, 0.071411, 258.475342, 45, 0, 1, 1, 0, 3, 1000, '[ [ 216, 82, 85 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KZ5 5556', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 2, '[ [ 255, 255, 255 ] ]', 255, 255, 'Price: 12.000.000$', 'X2', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 13:35:42', '2023-06-27 23:09:25', 1, NULL, 1, 1, 1, NULL, 33, 0, '[ [ ] ]', -1, NULL),
(70, 405, 327.142578, -1512.080078, 76.332603, 0.120850, 359.994507, 54.728394, 327.142578, -1512.080078, 76.333107, 0.115356, 359.989014, 54.755859, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LM2 9428', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:12:30', '2023-06-27 23:12:13', 1, NULL, 1, 1, 1, NULL, 34, 0, '[ [ ] ]', -1, NULL),
(71, 560, 324.777344, -1515.112305, 76.174431, 0.153809, 359.994507, 53.223267, 324.778320, -1515.112305, 76.175148, 0.153809, 359.994507, 53.261719, 100, 0, 0, 1, 0, 0, 983, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AK9 6314', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 28, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:13:20', '2023-06-27 23:13:00', 1, NULL, 1, 1, 1, NULL, 35, 0, '[ [ ] ]', -1, NULL),
(72, 451, 1262.864258, -1670.623047, 13.335501, 359.945068, 359.989014, 352.556763, 1262.865234, -1670.623047, 13.336160, 359.945068, 359.989014, 352.595215, 100, 0, 0, 1, 0, 3, 969, '[ [ 82, 52, 52 ] ]', '[ [ 151, 49, 49 ] ]', '[ [ 139, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZB8 6849', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 1, 2 ] ]', '[ [ 0, 0, 0, 0, 0, 1 ] ]', 66, '[ [ 255, 255, 255 ] ]', 255, 255, 'Price: 4.900.000$', 'X5', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:58:57', '2023-06-27 23:13:50', 1, NULL, 1, 1, 1, NULL, 36, 0, '[ [ ] ]', -1, NULL),
(73, 562, 319.889648, -1522.252930, 76.258980, 359.417725, 359.989014, 54.475708, 319.890625, -1522.252930, 76.259483, 359.417725, 359.989014, 54.508667, 100, 0, 0, 1, 0, 0, 999.5, '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', 'HV7 8011', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 1, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 30, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:15:16', '2023-06-27 23:14:53', 1, NULL, 1, 1, 1, NULL, 37, 0, '[ [ ] ]', -1, NULL),
(74, 579, 316.613281, -1525.821289, 76.542305, 359.879150, 359.296875, 48.482666, 316.613281, -1525.821289, 76.542999, 359.868164, 359.302368, 48.526611, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZR5 8955', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:15:59', '2023-06-27 23:15:41', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL);
INSERT INTO `vehicles` (`id`, `model`, `x`, `y`, `z`, `rotx`, `roty`, `rotz`, `currx`, `curry`, `currz`, `currrx`, `currry`, `currrz`, `fuel`, `engine`, `locked`, `lights`, `sirens`, `paintjob`, `hp`, `color1`, `color2`, `color3`, `color4`, `plate`, `faction`, `owner`, `job`, `tintedwindows`, `dimension`, `interior`, `currdimension`, `currinterior`, `enginebroke`, `items`, `itemvalues`, `Impounded`, `handbrake`, `safepositionX`, `safepositionY`, `safepositionZ`, `safepositionRZ`, `upgrades`, `wheelStates`, `panelStates`, `doorStates`, `odometer`, `headlights`, `variant1`, `variant2`, `description1`, `description2`, `description3`, `description4`, `description5`, `suspensionLowerLimit`, `driveType`, `deleted`, `chopped`, `stolen`, `lastUsed`, `creationDate`, `createdBy`, `trackingdevice`, `registered`, `show_plate`, `show_vin`, `paintjob_url`, `vehicle_shop_id`, `bulletproof`, `textures`, `business`, `protected_until`) VALUES
(75, 541, 1217.081055, -1654.781250, 11.420135, 359.494629, 359.857178, 268.786011, 1217.248047, -1654.757813, 11.403920, 359.450684, 359.824219, 268.577271, 44, 1, 0, 1, 0, 3, 950, '[ [ 0, 93, 99 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PS8 4971', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 1, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:56:59', '2023-06-27 23:16:23', 1, NULL, 1, 1, 1, NULL, 39, 0, '[ [ ] ]', -1, NULL),
(76, 488, 1174.842773, -1796.426758, 33.623447, 0.000000, 0.000000, 2.329102, 1174.842773, -1796.426758, 33.623447, 0.000000, 0.000000, 2.329102, 100, 0, 0, 1, 0, 0, 857, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XL5 8515', 2, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:39:55', '2023-06-27 23:18:26', 1, NULL, 1, 1, 1, NULL, 40, 0, '[ [ ] ]', -1, NULL),
(77, 475, 310.537109, -1503.397461, 76.334824, 0.098877, 359.994507, 233.563843, 310.537109, -1503.396484, 76.335571, 0.098877, 359.994507, 233.602295, 100, 0, 0, 1, 0, 0, 990.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WY5 3049', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:20:09', '2023-06-27 23:19:53', 1, NULL, 1, 1, 1, NULL, 41, 0, '[ [ ] ]', -1, NULL),
(78, 436, 355.109375, -1477.971680, 76.163216, 359.719849, 0.340576, 123.876343, 355.109375, -1477.971680, 76.163689, 359.774780, 0.115356, 123.920288, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'MR0 6712', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:20:58', '2023-06-27 23:20:37', 1, NULL, 1, 1, 1, NULL, 42, 0, '[ [ ] ]', -1, NULL),
(79, 429, 350.212891, -1481.325195, 76.020943, 359.505615, 0.032959, 124.365234, 350.212891, -1481.324219, 76.021690, 359.511108, 0.120850, 124.409180, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FV5 6970', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:21:42', '2023-06-27 23:21:23', 1, NULL, 1, 1, 1, NULL, 43, 0, '[ [ ] ]', -1, NULL),
(80, 599, 313.416992, -1529.643555, 76.593933, 359.928589, 359.983521, 43.835449, 313.417969, -1529.643555, 76.594696, 359.934082, 0.027466, 43.879395, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DQ8 4446', 1, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:23:56', '2023-06-27 23:23:28', 1, NULL, 1, 1, 1, NULL, 44, 0, '[ [ ] ]', -1, NULL),
(81, 437, 304.761719, -1532.482422, 76.918282, 359.989014, 359.978027, 291.456299, 304.761719, -1532.482422, 76.918282, 359.989014, 359.983521, 291.456299, 95, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'RF7 3498', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:25:01', '2023-06-27 23:24:32', 1, NULL, 1, 1, 1, NULL, 45, 0, '[ [ ] ]', -1, NULL),
(82, 580, 1252.314453, -1669.802734, 12.444401, 0.000000, 0.000000, 9.349365, 1252.314453, -1669.801758, 12.445146, 0.000000, 0.043945, 9.393311, 100, 0, 1, 1, 0, 3, 967.5, '[ [ 255, 255, 255 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LW9 8784', 85, -1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 2, 0, 0, 0, 2, 1 ] ]', '[ [ 0, 2, 0, 0, 0, 2 ] ]', 8, '[ [ 255, 255, 255 ] ]', 255, 255, 'Price: 5.600.000$', 'X5', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 13:38:45', '2023-06-27 23:25:37', 1, NULL, 1, 1, 1, NULL, 46, 0, '[ [ ] ]', -1, NULL),
(83, 519, 287.155449, -1611.966396, 114.416260, 0.000000, 0.000000, 91.822357, 287.155457, -1611.966431, 114.416260, 0.000000, 0.000000, 91.822357, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CU4 6015', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:26:44', '2023-06-27 23:26:44', 1, NULL, 1, 1, 1, NULL, 47, 0, '[ [ ] ]', -1, NULL),
(84, 558, 339.911133, -1488.402344, 76.303436, 359.879150, 0.000000, 121.080322, 339.911133, -1488.402344, 76.304054, 359.879150, 0.038452, 121.113281, 100, 0, 0, 1, 0, 0, 1000, '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', '[ [ 245, 245, 245 ] ]', 'WK8 3590', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:27:58', '2023-06-27 23:27:23', 1, NULL, 1, 1, 1, NULL, 48, 0, '[ [ ] ]', -1, NULL),
(85, 422, 334.333008, -1492.042969, 76.464363, 358.626709, 359.928589, 122.239380, 334.333008, -1492.042969, 76.465027, 358.632202, 359.901123, 122.277832, 100, 0, 0, 1, 0, 3, 1000, '[ [ 236, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OW7 3421', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:28:40', '2023-06-27 23:28:26', 1, NULL, 1, 1, 1, NULL, 49, 0, '[ [ ] ]', -1, NULL),
(86, 469, 297.160156, -1545.510742, 76.621376, 0.653687, 359.708862, 28.987427, 297.160156, -1545.510742, 76.621376, 0.653687, 359.708862, 28.987427, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OI9 2224', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:30:03', '2023-06-27 23:29:16', 1, NULL, 1, 1, 1, NULL, 50, 0, '[ [ ] ]', -1, NULL),
(87, 461, 352.343750, -1489.860352, 76.106812, 359.197998, 0.038452, 32.431641, 352.343750, -1489.860352, 76.106812, 359.197998, 0.038452, 32.431641, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AM9 7982', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:30:51', '2023-06-27 23:30:36', 1, NULL, 1, 1, 1, NULL, 51, 0, '[ [ ] ]', -1, NULL),
(88, 420, 329.872070, -1495.758789, 76.382362, 359.939575, 0.016479, 130.149536, 329.872070, -1495.758789, 76.383179, 359.945068, 0.060425, 130.193481, 100, 0, 0, 1, 0, 3, 1000, '[ [ 217, 204, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GZ8 4068', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:31:46', '2023-06-27 23:31:23', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(89, 468, 355.989258, -1487.167969, 76.096779, 359.252930, 0.076904, 34.211426, 355.989258, -1487.167969, 76.096779, 359.252930, 0.076904, 34.211426, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'EJ8 6110', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:32:44', '2023-06-27 23:32:25', 1, NULL, 1, 1, 1, NULL, 53, 0, '[ [ ] ]', -1, NULL),
(90, 454, 186.490234, -1943.787109, -0.009038, 1.082153, 359.967041, 99.393311, 186.014648, -1943.866211, 0.036599, 1.142578, 359.879150, 99.266968, 100, 0, 0, 1, 0, 0, 991, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OY1 2055', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 375, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:54:04', '2023-06-27 23:33:27', 1, NULL, 1, 1, 1, NULL, 54, 0, '[ [ ] ]', -1, NULL),
(91, 450, -26.980077, -1594.952582, 3.306514, 0.000000, 0.000000, 332.256348, -26.980078, -1594.952637, 3.306514, 0.000000, 0.000000, 332.256348, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LN6 8997', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:34:12', '2023-06-27 23:34:12', 1, NULL, 1, 1, 1, NULL, 55, 0, '[ [ ] ]', -1, NULL),
(92, 551, 325.392578, -1499.935547, 76.359467, 0.126343, 0.000000, 133.934326, 325.392578, -1499.935547, 76.360016, 0.120850, 359.978027, 133.972778, 100, 0, 0, 1, 0, 3, 1000, '[ [ 77, 15, 15 ] ]', '[ [ 168, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GI6 1569', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:36:04', '2023-06-27 23:35:39', 1, NULL, 1, 1, 1, NULL, 56, 0, '[ [ ] ]', -1, NULL),
(93, 595, 5.444336, -1552.532227, -0.340471, 3.087158, 0.076904, 309.880371, -415.335938, -1873.276367, -0.383286, 3.004761, 0.076904, 136.999512, 83, 1, 0, 1, 0, 0, 549.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FP1 6900', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 330, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:27:02', '2023-06-27 23:36:26', 1, NULL, 1, 1, 1, NULL, 57, 0, '[ [ ] ]', -1, NULL),
(94, 488, 1254.092773, -1750.087891, 33.797817, 359.923096, 0.087891, 1.389771, 1254.092773, -1750.087891, 33.797817, 359.923096, 0.087891, 1.389771, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FY8 8737', 2, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:38:39', '2023-06-27 23:38:39', 1, NULL, 1, 1, 1, NULL, 40, 0, '[ [ ] ]', -1, NULL),
(95, 519, 1118.012881, -2020.018204, 74.429688, 0.000000, 0.000000, 272.621643, 1118.012939, -2020.018188, 74.429688, 0.000000, 0.000000, 272.621643, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'YJ4 7764', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:46:09', '2023-06-27 23:46:09', 1, NULL, 1, 1, 1, NULL, 47, 0, '[ [ ] ]', -1, NULL),
(96, 519, 1117.422255, -2018.499580, 74.429688, 0.000000, 0.000000, 270.742950, 1117.422241, -2018.499634, 74.429688, 0.000000, 0.000000, 270.742950, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'IP0 9637', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:47:11', '2023-06-27 23:47:11', 1, NULL, 1, 1, 1, NULL, 47, 0, '[ [ ] ]', -1, NULL),
(97, 487, 1117.541992, -2019.916992, 74.589584, 0.313110, 359.857178, 270.109863, 1117.541992, -2019.916992, 74.589584, 0.313110, 359.857178, 270.109863, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WC4 7448', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:48:05', '2023-06-27 23:48:05', 1, NULL, 1, 1, 1, NULL, 10, 0, '[ [ ] ]', -1, NULL),
(98, 487, 1116.626953, -2055.694336, 74.599579, 0.351563, 359.780273, 270.109863, 1116.626953, -2055.694336, 74.599579, 0.351563, 359.780273, 270.109863, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'VG1 3449', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:48:24', '2023-06-27 23:48:24', 1, NULL, 1, 1, 1, NULL, 10, 0, '[ [ ] ]', -1, NULL),
(99, 437, 1264.581514, -2028.457050, 59.136047, 0.000000, 0.000000, 181.779800, 1264.581543, -2028.457031, 59.136047, 0.000000, 0.000000, 181.779800, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QX5 4888', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-27 23:48:56', '2023-06-27 23:48:56', 1, NULL, 1, 1, 1, NULL, 45, 0, '[ [ ] ]', -1, NULL),
(100, 507, 1247.832031, -2043.962891, 59.525894, 357.753296, 359.939575, 269.126587, 1247.832031, -2043.962891, 59.525894, 357.753296, 359.939575, 269.126587, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OY4 5707', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 22, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:55:01', '2023-06-27 23:50:22', 1, NULL, 1, 1, 1, NULL, 8, 0, '[ [ ] ]', -1, NULL),
(101, 507, 1254.835938, -2044.107422, 59.319588, 357.626953, 359.928589, 268.714600, 1254.836914, -2044.106445, 59.320202, 357.637939, 359.972534, 268.747559, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BK7 5899', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:54:47', '2023-06-27 23:50:38', 1, NULL, 1, 1, 1, NULL, 8, 0, '[ [ ] ]', -1, NULL),
(102, 405, 1260.347656, -2010.355469, 59.200432, 0.170288, 358.253174, 178.500366, 1260.348633, -2010.354492, 59.200924, 0.170288, 358.209229, 178.533325, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QC8 7928', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:53:41', '2023-06-27 23:51:46', 1, NULL, 1, 1, 1, NULL, 34, 0, '[ [ ] ]', -1, NULL),
(103, 405, 1255.748047, -2010.333984, 59.337349, 0.115356, 358.253174, 180.153809, 1255.749023, -2010.333984, 59.337826, 0.115356, 358.209229, 180.181274, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XH2 2576', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:53:25', '2023-06-27 23:51:53', 1, NULL, 1, 1, 1, NULL, 34, 0, '[ [ ] ]', -1, NULL),
(104, 405, 1265.083008, -2010.325195, 59.075386, 0.164795, 358.253174, 178.324585, 1265.084961, -2010.325195, 59.075962, 0.164795, 358.209229, 178.357544, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'MR0 3192', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:54:01', '2023-06-27 23:51:58', 1, NULL, 1, 1, 1, NULL, 34, 0, '[ [ ] ]', -1, NULL),
(105, 579, 1269.810823, -2026.982807, 59.254044, 0.000000, 0.000000, 36.752563, 1245.716797, -2009.664063, 59.833122, 359.912109, 357.396240, 179.022217, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'UM5 9031', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:52:49', '2023-06-27 23:52:11', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(106, 579, 1250.877930, -2010.084961, 59.683807, 359.917603, 357.528076, 178.698120, 1250.878906, -2010.084961, 59.684296, 359.923096, 357.462158, 178.731079, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PA2 4123', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:53:09', '2023-06-27 23:52:17', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(107, 579, 1270.119141, -2010.076172, 59.135056, 359.862671, 357.528076, 180.549316, 1270.120117, -2010.075195, 59.135540, 359.873657, 357.445679, 180.576782, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'UK7 2270', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:55:40', '2023-06-27 23:55:09', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(108, 579, 1275.206055, -2010.093750, 58.989704, 359.851685, 357.528076, 181.043701, 1275.208008, -2010.093750, 58.990215, 359.857178, 357.445679, 181.071167, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PI2 3349', 3, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:56:00', '2023-06-27 23:55:14', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(109, 525, 2629.303711, -2100.153320, 13.422357, 358.099365, 0.000000, 269.560547, 2629.304688, -2100.153320, 13.422782, 358.099365, 359.967041, 269.588013, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'CM2 3225', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:02:41', '2023-06-27 23:58:05', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(110, 525, 2629.151367, -2107.521484, 13.432751, 358.275146, 0.000000, 270.043945, 2629.152344, -2107.521484, 13.433702, 358.181763, 0.093384, 270.071411, 100, 0, 0, 1, 0, 0, 999, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LR1 6551', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:01:34', '2023-06-27 23:58:08', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(111, 525, 2693.993164, -2119.456055, 13.447398, 358.126831, 359.978027, 89.653931, 2693.995117, -2119.454102, 13.446793, 358.110352, 0.131836, 89.703369, 100, 0, 0, 1, 0, 0, 972, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ID4 1727', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 1, 0, 0, 0, 1, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:01:10', '2023-06-27 23:58:10', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(112, 525, 2629.211914, -2093.318359, 13.418561, 358.038940, 0.000000, 270.291138, 2629.212891, -2093.318359, 13.419053, 358.049927, 359.956055, 270.318604, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DU2 6301', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:03:10', '2023-06-27 23:58:12', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(113, 525, 2629.057617, -2087.386719, 13.423999, 358.126831, 0.000000, 271.268921, 2629.057617, -2087.386719, 13.423999, 358.126831, 0.000000, 271.268921, 100, 0, 0, 2, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OO9 7220', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 320, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:02:20', '2023-06-27 23:58:15', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(114, 525, 2447.002930, -2135.677734, 13.551275, 358.192749, 359.994507, 359.697876, 2447.003906, -2135.677734, 13.551771, 358.198242, 359.967041, 359.730835, 100, 0, 0, 1, 0, 0, 997.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'UI4 2480', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:00:01', '2023-06-27 23:58:18', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(115, 525, 2693.753906, -2088.199219, 13.459606, 358.330078, 0.000000, 90.785522, 2693.754883, -2088.199219, 13.460014, 358.335571, 0.027466, 90.812988, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WM2 3266', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 44, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:00:30', '2023-06-27 23:58:21', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(116, 525, 2488.563477, -2134.380859, 13.544867, 358.082886, 0.000000, 359.285889, 2488.564453, -2134.380859, 13.545419, 358.093872, 359.961548, 359.318848, 100, 0, 0, 1, 0, 0, 991, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BE2 4861', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 79, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:59:17', '2023-06-27 23:58:23', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(117, 525, 2477.783203, -2135.309570, 13.545445, 358.093872, 0.000000, 359.923096, 2477.786133, -2135.309570, 13.546149, 358.104858, 359.967041, 359.961548, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'GK1 9081', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:59:38', '2023-06-27 23:58:26', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(118, 525, 2435.861328, -2135.020508, 13.544155, 358.071899, 0.000000, 1.181030, 2435.863281, -2135.020508, 13.544688, 358.077393, 359.961548, 1.208496, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JP9 7096', 4, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-27 23:58:51', '2023-06-27 23:58:29', 1, NULL, 1, 1, 1, NULL, 5, 0, '[ [ ] ]', -1, NULL),
(119, 488, 441.942601, -1420.104013, 45.337986, 0.000000, 0.000000, 39.279480, 441.942596, -1420.104004, 45.337986, 0.000000, 0.000000, 39.279480, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'NA3 5372', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-28 00:05:36', '2023-06-28 00:05:36', 1, NULL, 1, 1, 1, NULL, 40, 0, '[ [ ] ]', -1, NULL),
(120, 563, 1111.330078, -1688.313477, 24.288815, 3.570557, 0.000000, 176.539307, 1586.452148, -1678.258789, 6.615824, 3.455200, 359.994507, 176.533813, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'UY7 2109', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:32:00', '2023-06-28 00:07:54', 1, NULL, 1, 1, 1, NULL, 58, 0, '[ [ ] ]', -1, NULL),
(121, 582, 1132.045898, -1671.685547, 13.733419, 1.543579, 359.967041, 270.379028, 1132.046875, -1671.685547, 13.734118, 1.543579, 0.010986, 270.417480, 100, 0, 0, 1, 0, 0, 998, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'IS8 4418', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 2, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:12:13', '2023-06-28 00:09:32', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(122, 582, 1132.051758, -1676.268555, 13.733577, 1.532593, 359.928589, 271.510620, 1132.051758, -1676.268555, 13.734170, 1.538086, 359.978027, 271.543579, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QQ0 4315', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:12:01', '2023-06-28 00:09:36', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(123, 582, 1132.327148, -1680.893555, 13.742643, 1.499634, 359.906616, 272.274170, 1132.328125, -1680.893555, 13.743144, 1.499634, 359.950562, 272.301636, 100, 0, 0, 1, 0, 0, 969, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'TE9 1749', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 2, 0, 0, 0, 2, 0 ] ]', '[ [ 0, 0, 2, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:11:45', '2023-06-28 00:09:39', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(124, 582, 1132.302734, -1685.996094, 13.745917, 1.510620, 359.989014, 270.214233, 1132.303711, -1685.995117, 13.746418, 1.510620, 0.043945, 270.241699, 100, 0, 0, 1, 0, 0, 990, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'VE2 7065', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 2, 0, 0, 0, 0, 2, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:11:34', '2023-06-28 00:09:41', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(125, 582, 1132.419922, -1690.627930, 13.741255, 1.499634, 359.978027, 270.966797, 1585.012695, -1675.320313, 5.942671, 359.566040, 0.208740, 3.015747, 98, 1, 0, 1, 0, 0, 979.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'MC7 2419', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 1 ] ]', '[ [ 0, 2, 0, 0, 0, 0 ] ]', 29, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:32:28', '2023-06-28 00:09:43', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(126, 582, 1132.501953, -1695.626953, 13.763742, 1.614990, 359.994507, 270.988770, 1132.501953, -1695.626953, 13.763742, 1.614990, 359.994507, 270.988770, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WW4 5206', 20, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:12:43', '2023-06-28 00:12:43', 1, NULL, 1, 1, 1, NULL, 59, 0, '[ [ ] ]', -1, NULL),
(127, 410, 1354.358398, -1565.696289, 13.198939, 359.406738, 0.000000, 344.102783, 1354.359375, -1565.696289, 13.199492, 359.406738, 0.010986, 344.135742, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'YS3 6918', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:17:45', '2023-06-28 00:15:09', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(128, 410, 1349.688477, -1564.429688, 13.200395, 359.417725, 0.000000, 344.586182, 1349.688477, -1564.429688, 13.200395, 359.417725, 0.000000, 344.586182, 100, 0, 0, 0, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'JU3 7611', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:17:25', '2023-06-28 00:15:18', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(129, 410, 1345.083008, -1563.111328, 13.200991, 359.417725, 0.000000, 345.108032, 1345.083008, -1563.111328, 13.200991, 359.417725, 0.000000, 345.108032, 100, 0, 0, 0, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'AM1 6201', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:17:01', '2023-06-28 00:15:27', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(130, 410, 1340.397461, -1561.662109, 13.195993, 359.390259, 0.000000, 344.981689, 1340.397461, -1561.662109, 13.195993, 359.390259, 0.000000, 344.981689, 100, 0, 0, 0, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'MR2 8048', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:16:50', '2023-06-28 00:15:35', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(131, 410, 1335.987305, -1560.455078, 13.195772, 359.406738, 359.719849, 346.107788, 1335.988281, -1560.454102, 13.196280, 359.412231, 359.719849, 346.140747, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'JM3 8029', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:16:44', '2023-06-28 00:15:41', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(132, 410, 1330.910156, -1559.236328, 13.198623, 359.406738, 0.000000, 345.728760, 1330.910156, -1559.235352, 13.199163, 359.406738, 0.000000, 345.756226, 100, 0, 0, 1, 0, 0, 988, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'ZQ7 7453', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 1 ] ]', '[ [ 0, 2, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:16:28', '2023-06-28 00:15:45', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(133, 462, 1341.764648, -1516.114258, 13.047750, 359.208984, 0.005493, 260.090332, 1341.764648, -1516.114258, 13.047750, 359.208984, 0.005493, 260.090332, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'VJ8 9944', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 31, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:19:36', '2023-06-28 00:18:59', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(134, 462, 1346.407227, -1507.852539, 13.050203, 359.401245, 359.967041, 258.991699, 1346.407227, -1507.852539, 13.050203, 359.401245, 359.967041, 258.991699, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'HI9 3323', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:20:36', '2023-06-28 00:19:03', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(135, 462, 1344.073242, -1512.034180, 13.048659, 359.219971, 359.967041, 256.810913, 1344.073242, -1512.034180, 13.048659, 359.219971, 359.967041, 256.810913, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [0, 0, 0] ]', 'SN6 3570', -1, -2, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:20:10', '2023-06-28 00:19:04', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(136, 470, 80.687500, -1519.422852, 4.803943, 2.021484, 356.704102, 250.279541, 80.687500, -1519.421875, 4.804443, 1.994019, 356.764526, 250.307007, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OR8 9613', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:48:41', '2023-06-28 00:48:23', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(137, 470, 77.583984, -1550.118164, 5.594070, 5.751343, 10.486450, 274.053955, 77.583984, -1550.118164, 5.594070, 5.751343, 10.486450, 274.053955, 75, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZO5 3949', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 58, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:05:25', '2023-06-28 00:48:52', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(138, 470, 80.223633, -1535.416992, 5.493515, 0.895386, 359.708862, 263.292847, 80.223633, -1535.416992, 5.493515, 0.895386, 359.708862, 263.292847, 75, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XZ4 2474', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:05:06', '2023-06-28 00:49:20', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(139, 470, 24.447266, -1526.609375, 4.877016, 355.973511, 359.165039, 78.107300, 24.447266, -1526.609375, 4.877516, 355.984497, 359.104614, 78.134766, 100, 0, 0, 1, 0, 0, 951, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PE2 7065', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:49:59', '2023-06-28 00:49:25', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(140, 470, 23.492188, -1515.399414, 4.676897, 353.891602, 353.946533, 93.543091, 23.492188, -1515.398438, 4.677397, 353.902588, 353.869629, 93.570557, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HH1 1231', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 2, '[ [ 255, 255, 255 ] ]', 0, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:50:27', '2023-06-28 00:50:07', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(141, 470, 18.892578, -1538.348633, 4.377889, 357.863159, 347.821655, 71.240845, 2109.393555, -1772.812500, 13.534085, 359.912109, 0.093384, 331.149902, 74, 1, 0, 1, 0, 0, 864.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BZ4 4235', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 1, 1, 0, 0, 1, 2, 0 ] ]', '[ [ 0, 0, 0, 3, 2, 1 ] ]', 192, '[ [ 255, 255, 255 ] ]', 2, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:27:58', '2023-06-28 00:50:36', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(142, 437, 202.034180, 1886.952148, 18.026588, 359.989014, 359.912109, 3.784790, 1585.931641, -1678.109375, 5.896991, 359.989014, 359.912109, 3.784790, 900, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'NP1 5871', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 13:40:39', '2023-06-28 00:54:27', 1, NULL, 1, 1, 1, NULL, 45, 0, '[ [ ] ]', -1, NULL),
(143, 437, 226.465820, 1886.905273, 17.944864, 359.989014, 0.000000, 2.158813, 226.465820, 1886.905273, 17.944864, 359.989014, 0.000000, 2.158813, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'LU6 4092', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 1, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:54:33', '2023-06-28 00:54:33', 1, NULL, 1, 1, 1, NULL, 45, 0, '[ [ ] ]', -1, NULL),
(144, 520, 331.483398, 1938.222656, 18.290154, 0.351563, 0.000000, 90.258179, 154.090820, 1647.586914, 36.004120, 68.400879, 331.342163, 190.651245, 95, 1, 0, 1, 0, 0, 618, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BZ6 8884', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 1, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 3516, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:42:58', '2023-06-28 00:54:41', 1, NULL, 1, 1, 1, NULL, 31, 0, '[ [ ] ]', -1, NULL),
(145, 520, 331.876953, 1973.101563, 18.290279, 0.351563, 0.000000, 89.730835, 331.876953, 1973.101563, 18.290279, 0.351563, 0.000000, 89.730835, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HI4 6434', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 2693, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 14:43:33', '2023-06-28 00:56:03', 1, NULL, 1, 1, 1, NULL, 31, 0, '[ [ ] ]', -1, NULL),
(146, 470, 202.505859, 1918.125977, 17.774542, 359.873657, 0.000000, 181.082153, 202.506836, 1918.126953, 17.775042, 359.868164, 359.906616, 181.115112, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'EG8 8703', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:59:44', '2023-06-28 00:58:29', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(147, 470, 211.686523, 1918.218750, 17.772327, 359.873657, 0.000000, 181.032715, 211.686523, 1918.219727, 17.772835, 359.873657, 359.934082, 181.060181, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'SS7 8982', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 22, '[ [ 255, 255, 255 ] ]', 2, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:59:23', '2023-06-28 00:58:37', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL),
(148, 470, 220.743164, 1918.001953, 17.775671, 359.873657, 0.010986, 180.615234, 220.743164, 1918.002930, 17.776201, 359.873657, 359.934082, 180.648193, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JB9 3598', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 2, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:59:02', '2023-06-28 00:58:42', 1, NULL, 1, 1, 1, NULL, 7, 0, '[ [ ] ]', -1, NULL);
INSERT INTO `vehicles` (`id`, `model`, `x`, `y`, `z`, `rotx`, `roty`, `rotz`, `currx`, `curry`, `currz`, `currrx`, `currry`, `currrz`, `fuel`, `engine`, `locked`, `lights`, `sirens`, `paintjob`, `hp`, `color1`, `color2`, `color3`, `color4`, `plate`, `faction`, `owner`, `job`, `tintedwindows`, `dimension`, `interior`, `currdimension`, `currinterior`, `enginebroke`, `items`, `itemvalues`, `Impounded`, `handbrake`, `safepositionX`, `safepositionY`, `safepositionZ`, `safepositionRZ`, `upgrades`, `wheelStates`, `panelStates`, `doorStates`, `odometer`, `headlights`, `variant1`, `variant2`, `description1`, `description2`, `description3`, `description4`, `description5`, `suspensionLowerLimit`, `driveType`, `deleted`, `chopped`, `stolen`, `lastUsed`, `creationDate`, `createdBy`, `trackingdevice`, `registered`, `show_plate`, `show_vin`, `paintjob_url`, `vehicle_shop_id`, `bulletproof`, `textures`, `business`, `protected_until`) VALUES
(149, 425, 303.016602, 2075.954102, 20.752344, 2.005005, 0.131836, 182.664185, 303.016602, 2075.954102, 20.752344, 2.005005, 0.131836, 182.664185, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BY7 8990', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 00:59:50', '2023-06-28 00:59:49', 1, NULL, 1, 1, 1, NULL, 9, 0, '[ [ ] ]', -1, NULL),
(150, 425, 270.719727, 1883.417969, 20.644030, 1.966553, 0.049438, 179.791260, 270.719727, 1883.417969, 20.644030, 1.966553, 0.049438, 179.791260, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WB9 6575', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:01:46', '2023-06-28 01:01:46', 1, NULL, 1, 1, 1, NULL, 9, 0, '[ [ ] ]', -1, NULL),
(151, 405, 117.495117, 1886.098633, 17.883896, 4.218750, 0.038452, 359.434204, 117.495117, 1886.098633, 17.883896, 4.235229, 0.038452, 359.434204, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZJ1 6491', 81, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, 'Ø³ÙŠØ§Ø±Ø© ÙˆØ²ÙŠØ± Ø§Ù„Ø®Ø§Ø±Ø¬ÙŠØ©', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:03:11', '2023-06-28 01:02:19', 1, NULL, 1, 1, 1, NULL, 34, 0, '[ [ ] ]', -1, NULL),
(152, 420, 1804.147461, -1932.559570, 13.229192, 359.967041, 0.016479, 359.263916, 1804.148438, -1932.559570, 13.229748, 359.967041, 359.945068, 359.291382, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'OC2 6141', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:08:44', '2023-06-28 01:08:04', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(153, 420, 1796.637695, -1932.531250, 13.229264, 359.967041, 0.016479, 357.967529, 1796.637695, -1932.531250, 13.229264, 359.967041, 0.016479, 357.967529, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BQ1 5438', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 25, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:09:19', '2023-06-28 01:08:06', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(154, 420, 1777.469727, -1917.762695, 13.230139, 359.983521, 0.016479, 270.285645, 1777.470703, -1917.762695, 13.230647, 359.983521, 0.120850, 270.318604, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'NL8 3030', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 20, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:11:23', '2023-06-28 01:08:08', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(155, 420, 1785.010742, -1932.612305, 13.229216, 359.967041, 0.021973, 357.473145, 1785.012695, -1932.612305, 13.229883, 359.972534, 359.989014, 357.506104, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'JF0 1085', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 42, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:10:23', '2023-06-28 01:08:09', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(156, 420, 1800.435547, -1932.451172, 13.229093, 359.967041, 0.016479, 357.923584, 1800.437500, -1932.451172, 13.229656, 359.967041, 0.010986, 357.956543, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'BY8 7880', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:09:01', '2023-06-28 01:08:12', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(157, 420, 1792.763672, -1932.625977, 13.229115, 359.967041, 0.016479, 358.714600, 1792.763672, -1932.625977, 13.229115, 359.967041, 0.016479, 358.714600, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'ZI8 5421', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:09:41', '2023-06-28 01:08:14', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(158, 420, 1788.793945, -1932.658203, 13.229274, 359.967041, 0.016479, 0.236206, 1788.794922, -1932.658203, 13.229792, 359.972534, 359.994507, 0.263672, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FM3 1345', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:10:00', '2023-06-28 01:08:16', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(159, 420, 1777.641602, -1926.241211, 13.230368, 359.983521, 0.016479, 270.516357, 1777.642578, -1926.241211, 13.230886, 359.983521, 0.000000, 270.543823, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'RB9 2803', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:10:46', '2023-06-28 01:08:18', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(160, 420, 1777.788086, -1922.052734, 13.230204, 359.983521, 0.016479, 270.093384, 1777.789063, -1922.053711, 13.230602, 359.983521, 0.000000, 270.120850, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KI0 1972', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:11:04', '2023-06-28 01:08:22', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(161, 420, 1777.352539, -1913.472656, 13.230190, 359.983521, 0.016479, 269.752808, 1777.352539, -1913.472656, 13.230190, 359.983521, 0.016479, 269.752808, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'KS9 2673', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:11:42', '2023-06-28 01:08:24', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(162, 420, 1777.304688, -1909.078125, 13.230003, 359.983521, 0.016479, 270.911865, 1777.305664, -1909.078125, 13.230900, 359.917603, 0.175781, 270.939331, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'WB4 4969', 82, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:12:02', '2023-06-28 01:11:46', 1, NULL, 1, 1, 1, NULL, 52, 0, '[ [ ] ]', -1, NULL),
(163, 577, 1839.794922, -2435.837891, 13.920407, 358.939819, 0.000000, 56.222534, 1839.794922, -2435.837891, 13.920407, 358.939819, 0.000000, 56.222534, -6176, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DP8 3555', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 73, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:21:26', '2023-06-28 01:19:45', 1, NULL, 1, 1, 1, NULL, 15, 0, '[ [ ] ]', -1, NULL),
(164, 519, 1825.233569, -2453.064648, 13.554688, 0.000000, 0.000000, 219.304184, 1825.256836, -2453.096680, 14.099159, 0.791016, 359.994507, 219.089355, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'XP4 3541', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:23:00', '2023-06-28 01:22:13', 1, NULL, 1, 1, 1, NULL, 47, 0, '[ [ ] ]', -1, NULL),
(165, 550, 209.662509, 1906.598692, 17.640625, 0.000000, 0.000000, 178.242126, 209.662506, 1906.598633, 17.640625, 0.000000, 0.000000, 178.242126, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'AK4 3886', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-28 01:27:49', '2023-06-28 01:27:48', 1, NULL, 1, 1, 1, NULL, 24, 0, '[ [ ] ]', -1, NULL),
(166, 490, 213.935547, 1854.611328, 13.008188, 5.899658, 0.911865, 359.099121, 213.936523, 1854.611328, 13.008723, 5.833740, 1.027222, 359.126587, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'PI4 3782', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 46, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:28:33', '2023-06-28 01:28:05', 1, NULL, 1, 1, 1, NULL, 28, 0, '[ [ ] ]', -1, NULL),
(167, 490, 222.227539, 1854.946289, 13.012267, 4.998779, 359.631958, 3.982544, 222.229492, 1854.947266, 13.012972, 4.927368, 359.741821, 4.020996, 100, 0, 0, 1, 0, 0, 987.5, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DB4 6853', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 1, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:28:56', '2023-06-28 01:28:39', 1, NULL, 1, 1, 1, NULL, 28, 0, '[ [ ] ]', -1, NULL),
(168, 579, 114.486328, 1856.110352, 17.734711, 359.901123, 358.736572, 87.511597, 114.487305, 1856.110352, 17.735201, 359.895630, 358.665161, 87.539063, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'DW3 9540', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:29:46', '2023-06-28 01:29:20', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(169, 579, 114.344727, 1861.070313, 17.779894, 359.868164, 358.736572, 91.406250, 114.345703, 1861.070313, 17.780411, 359.862671, 358.654175, 91.433716, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'QT4 3178', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:30:40', '2023-06-28 01:29:52', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(170, 579, 114.200195, 1851.378906, 17.694416, 359.879150, 358.818970, 85.957031, 114.200195, 1851.378906, 17.694416, 359.879150, 358.818970, 85.957031, 100, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'IA5 2464', 83, -1, -1, 1, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 15, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 0, 0, 0, '2023-06-28 01:30:24', '2023-06-28 01:30:07', 1, NULL, 1, 1, 1, NULL, 38, 0, '[ [ ] ]', -1, NULL),
(171, 578, 1528.737728, -1702.661107, 13.382813, 0.000000, 0.000000, 269.814606, 1528.737671, -1702.661133, 13.382813, 0.000000, 0.000000, 269.814606, 100, 0, 1, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'HR6 2820', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-28 02:40:30', '2023-06-28 02:40:30', 1, NULL, 1, 1, 1, NULL, 60, 0, '[ [ ] ]', -1, NULL),
(172, 411, 1187.263672, -1180.376953, 86.778870, 0.000000, 0.000000, 90.000000, 1527.078125, -1668.161133, 12.829433, 0.499878, 359.989014, 187.893677, 100, 1, 0, 1, 0, 0, 1000, '[ [ 16 ] ]', '[ [ 0, 0, 0 ]]', '[ [ 0, 0, 0 ] ] ', '[ [ 0, 0, 0 ] ]', '34 SC 4987', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-28 13:42:56', '2023-06-28 12:33:07', 1, NULL, 1, 1, 1, NULL, 0, 0, '[ [ ] ]', -1, NULL),
(173, 443, 1696.865245, -1300.714282, 13.507797, 0.000000, 0.000000, 279.658508, 1682.032227, -1306.912109, 14.004416, 357.923584, 0.027466, 270.439453, 78, 0, 0, 1, 0, 0, 1000, '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', '[ [ 0, 0, 0 ] ]', 'FP8 1301', -1, 1, -1, 0, 0, 0, 0, 0, 0, NULL, NULL, 0, 1, NULL, NULL, NULL, NULL, '[ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0, 0 ] ]', '[ [ 0, 0, 0, 0, 0, 0 ] ]', 0, '[ [ 255, 255, 255 ] ]', 255, 255, '', '', '', '', '', NULL, NULL, 1, 0, 0, '2023-06-30 12:14:58', '2023-06-30 11:51:48', 1, NULL, 1, 1, 1, NULL, 61, 0, '[ [ ] ]', -1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `vehicles_custom`
--

CREATE TABLE `vehicles_custom` (
  `id` int(11) NOT NULL,
  `brand` text DEFAULT NULL,
  `model` text DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `handling` varchar(1000) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `tax` int(11) DEFAULT NULL,
  `createdate` timestamp NOT NULL DEFAULT current_timestamp(),
  `createdby` int(11) NOT NULL DEFAULT 0,
  `updatedate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` int(11) NOT NULL DEFAULT 0,
  `notes` text DEFAULT NULL,
  `doortype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vehicles_shop`
--

CREATE TABLE `vehicles_shop` (
  `id` int(11) NOT NULL,
  `vehmtamodel` int(11) DEFAULT 0,
  `vehbrand` text DEFAULT NULL,
  `vehmodel` text DEFAULT NULL,
  `vehyear` int(11) DEFAULT 2014,
  `vehprice` int(11) DEFAULT 0,
  `vehtax` int(11) DEFAULT 0,
  `createdate` timestamp NOT NULL DEFAULT current_timestamp(),
  `createdby` int(11) NOT NULL DEFAULT 0,
  `updatedate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updatedby` int(11) NOT NULL DEFAULT 0,
  `notes` text DEFAULT NULL,
  `handling` varchar(1000) DEFAULT NULL,
  `duration` int(11) NOT NULL DEFAULT 1000,
  `enabled` int(1) NOT NULL DEFAULT 0,
  `spawnto` tinyint(2) NOT NULL DEFAULT 0,
  `doortype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vehicles_shop`
--

INSERT INTO `vehicles_shop` (`id`, `vehmtamodel`, `vehbrand`, `vehmodel`, `vehyear`, `vehprice`, `vehtax`, `createdate`, `createdby`, `updatedate`, `updatedby`, `notes`, `handling`, `duration`, `enabled`, `spawnto`, `doortype`) VALUES
(1, 497, 'X1', '497', 1995, 5000000, 5, '2023-06-23 13:28:56', 1, '0000-00-00 00:00:00', 0, 'Police Copter LSPD\n', NULL, 1000, 0, 0, NULL),
(2, 596, 'X6', '596', 1995, 2500000, 5, '2023-06-23 13:54:39', 1, '0000-00-00 00:00:00', 0, 'Police Vehicle\n', NULL, 1000, 0, 0, NULL),
(3, 597, 'X7', '597', 1995, 2500000, 5, '2023-06-23 14:01:15', 1, '2023-06-23 14:01:29', 1, 'Police SF\n', NULL, 1000, 0, 0, NULL),
(4, 523, 'X8', '523', 1995, 1500000, 5, '2023-06-23 14:07:10', 1, '0000-00-00 00:00:00', 0, 'Police Bike\n', NULL, 1000, 0, 0, NULL),
(5, 525, 'X8', '525', 1995, 450000, 5, '2023-06-25 22:08:00', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(7, 470, 'Army Patriot', 'x470', 1995, 4200000, 5, '2023-06-27 22:10:56', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(8, 507, 'Audi Berline', 'x507', 2022, 95000, 5, '2023-06-27 22:32:29', 1, '2023-07-07 13:44:38', 1, '\n', NULL, 1000, 1, 4, NULL),
(9, 425, 'Akula Stealth', 'x425', 2022, 1200000, 5, '2023-06-27 22:33:30', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(10, 487, 'Army Maverick', 'x487', 2022, 1200000, 5, '2023-06-27 22:34:51', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(11, 400, 'Audi Sportback', 'x400', 2022, 400000, 5, '2023-06-27 22:36:27', 1, '2023-07-07 13:47:30', 1, '\n', NULL, 1000, 1, 1, NULL),
(12, 602, 'BMW SerieM5', 'x602', 2022, 1200000, 5, '2023-06-27 22:39:22', 1, '2023-07-07 13:45:27', 1, '\n', NULL, 1000, 1, 4, NULL),
(13, 477, 'BMW M850i', 'x477', 2022, 350000, 5, '2023-06-27 22:40:18', 1, '2023-07-07 13:47:25', 1, '\n', NULL, 1000, 1, 1, NULL),
(14, 506, 'BMW i8', 'x506', 2022, 1200000, 5, '2023-06-27 22:41:22', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(15, 577, 'Boeing AT-400', 'x577', 2022, 1200000, 5, '2023-06-27 22:47:51', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(16, 522, 'CBR 600', 'x522', 2022, 120000, 5, '2023-06-27 22:48:54', 1, '2023-06-30 10:24:15', 1, '\n', NULL, 1000, 1, 3, NULL),
(17, 496, 'Chefrolet Celta', 'x496', 2022, 56000, 5, '2023-06-27 22:49:42', 1, '2023-07-07 13:44:49', 1, '\n', NULL, 1000, 1, 4, NULL),
(18, 554, 'Chevrolet S10', 'x554', 2022, 1200000, 5, '2023-06-27 22:50:38', 1, '2023-07-07 13:44:58', 1, '\n', NULL, 1000, 1, 4, NULL),
(19, 526, 'Camaro X320', 'x526', 2022, 1200000, 5, '2023-06-27 22:51:45', 1, '2023-07-07 13:46:50', 1, '\n', NULL, 1000, 1, 1, NULL),
(20, 402, 'Dodg Bullet', 'x402', 2022, 450000, 5, '2023-06-27 22:52:27', 1, '2023-07-07 13:46:06', 1, '\n', NULL, 1000, 1, 1, NULL),
(21, 401, 'Elegy Retro', 'x401', 2022, 80000, 5, '2023-06-27 22:53:17', 1, '2023-07-07 13:45:20', 1, '\n', NULL, 1000, 1, 4, NULL),
(22, 462, 'Faggio Pegassi', 'x462', 2022, 27000, 5, '2023-06-27 22:54:19', 1, '2023-06-30 10:25:16', 1, '\n', NULL, 1000, 1, 3, NULL),
(23, 415, 'Ferrari Release', 'x415', 2022, 1200000, 5, '2023-06-27 22:55:02', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(24, 550, 'Fiat Siena', 'x550', 2022, 60000, 5, '2023-06-27 22:56:04', 1, '2023-06-28 02:30:17', 1, '\n', NULL, 1000, 0, 0, NULL),
(25, 479, 'Fiat Toro', 'x479', 2022, 85000, 5, '2023-06-27 22:57:34', 1, '2023-07-07 13:45:35', 1, '\n', NULL, 1000, 1, 4, NULL),
(26, 545, 'Fusca Leads', 'x545', 2022, 50000, 5, '2023-06-27 22:59:57', 1, '2023-07-07 13:45:41', 1, '\n', NULL, 1000, 1, 4, NULL),
(27, 427, 'FBI Enforcer', 'x427', 2022, 1200000, 5, '2023-06-27 23:00:42', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(28, 490, 'FBI Rancher', 'x490', 2022, 1200000, 5, '2023-06-27 23:03:22', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(29, 587, 'Golf Volkswagen', 'x587', 2022, 55000, 5, '2023-06-27 23:05:07', 1, '2023-07-07 13:45:46', 1, '\n', NULL, 1000, 1, 4, NULL),
(30, 521, 'Honda CG160', 'x521', 2022, 45000, 5, '2023-06-27 23:05:52', 1, '2023-06-30 10:25:05', 1, '\n', NULL, 1000, 1, 3, NULL),
(31, 520, 'Hydra Tursan', 'x520', 2022, 1200000, 5, '2023-06-27 23:06:40', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(32, 565, 'Lamborghiny Gallardo', 'x565', 2022, 1200000, 5, '2023-06-27 23:08:30', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(33, 411, 'Lamborghini Terzo', 'x411', 2022, 1200000, 5, '2023-06-27 23:09:20', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(34, 405, 'Lincoln Town', 'x405', 2022, 250000, 5, '2023-06-27 23:10:32', 1, '2023-07-07 13:47:07', 1, '\n', NULL, 1000, 1, 1, NULL),
(35, 560, 'Maserati Luex', 'x560', 2022, 110000, 5, '2023-06-27 23:12:49', 1, '2023-07-07 13:45:53', 1, '\n', NULL, 1000, 1, 4, NULL),
(36, 451, 'McLaren Sabre', 'x451', 2022, 1200000, 5, '2023-06-27 23:13:44', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(37, 562, 'Mercedes Classe', 'x562', 2022, 480000, 5, '2023-06-27 23:14:45', 1, '2023-07-07 13:47:14', 1, '\n', NULL, 1000, 1, 1, NULL),
(38, 579, 'Mercedes Benz', 'x579', 2022, 1200000, 5, '2023-06-27 23:15:33', 1, '2023-07-07 13:47:20', 1, '\n', NULL, 1000, 1, 1, NULL),
(39, 541, 'Nissan GTR', 'x541', 2022, 1200000, 5, '2023-06-27 23:16:16', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(40, 488, 'News Chopper', 'x488', 2022, 1200000, 5, '2023-06-27 23:18:08', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(41, 475, 'Opala Chevrolet', 'x475', 2022, 350000, 5, '2023-06-27 23:19:47', 1, '2023-07-07 13:46:16', 1, '\n', NULL, 1000, 1, 1, NULL),
(42, 436, 'Peugeot Occasion', 'x436', 2022, 65000, 5, '2023-06-27 23:20:29', 1, '2023-07-07 13:45:59', 1, '\n', NULL, 1000, 1, 4, NULL),
(43, 429, 'Porsche Turbo', 'x429', 2022, 850000, 5, '2023-06-27 23:21:18', 1, '2023-07-07 13:46:56', 1, '\n', NULL, 1000, 1, 1, NULL),
(44, 599, 'Police Ranger', 'x599', 2022, 1200000, 5, '2023-06-27 23:23:12', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(45, 437, 'Prision Bus', 'x437', 2022, 1200000, 5, '2023-06-27 23:24:25', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(46, 580, 'Rolls Royce', 'x580', 2022, 1200000, 5, '2023-06-27 23:25:31', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(47, 519, 'Shamal Airport', 'x519', 2022, 1200000, 5, '2023-06-27 23:26:30', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(48, 558, 'Sanchez Koenig', 'x558', 2022, 650000, 5, '2023-06-27 23:27:09', 1, '2023-07-07 13:47:01', 1, '\n', NULL, 1000, 1, 1, NULL),
(49, 422, 'Saveiro Volkswagen', 'x422', 2022, 45000, 5, '2023-06-27 23:28:19', 1, '2023-07-07 13:45:05', 1, '\n', NULL, 1000, 1, 4, NULL),
(50, 469, 'Sparrow H251', 'x469', 2022, 1200000, 5, '2023-06-27 23:29:11', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(51, 461, 'Suzuki A100', 'x461', 2022, 95000, 5, '2023-06-27 23:30:28', 1, '2023-06-30 10:24:44', 1, '\n', NULL, 1000, 1, 3, NULL),
(52, 420, 'Taxi Ducty', 'x420', 2022, 1200000, 5, '2023-06-27 23:31:11', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(53, 468, 'Tiger Trimp', 'x468', 2022, 70000, 5, '2023-06-27 23:32:14', 1, '2023-06-30 10:24:56', 1, '\n', NULL, 1000, 1, 3, NULL),
(54, 454, 'Tropic Boat', 'x454', 2022, 1200000, 5, '2023-06-27 23:33:09', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(55, 450, 'Trailer', 'x450', 2022, 120000, 5, '2023-06-27 23:34:07', 1, '2023-06-27 23:34:48', 1, '\n', NULL, 1000, 0, 0, NULL),
(56, 551, 'Toyota Corolla', 'x551', 2022, 95000, 5, '2023-06-27 23:35:16', 1, '2023-07-07 13:45:11', 1, '\n', NULL, 1000, 1, 4, NULL),
(57, 595, 'Launch Marin', 'x595', 2022, 1200000, 5, '2023-06-27 23:36:21', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(58, 563, 'Raindance', 'x563', 2022, 1200000, 5, '2023-06-28 00:07:47', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(59, 582, 'News Van', 'x582', 2022, 1200000, 5, '2023-06-28 00:09:25', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(60, 578, 'micano', '578', 2022, 120000, 5, '2023-06-28 02:40:17', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL),
(61, 443, 'Micano Truck', '443', 1995, 250000, 5, '2023-06-30 11:51:41', 1, '0000-00-00 00:00:00', 0, '\n', NULL, 1000, 0, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_logs`
--

CREATE TABLE `vehicle_logs` (
  `log_id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `vehID` int(11) DEFAULT NULL,
  `action` text DEFAULT NULL,
  `actor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Stores all admin actions on vehicles - Monitored by Vehicle ';

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_notes`
--

CREATE TABLE `vehicle_notes` (
  `id` int(11) NOT NULL,
  `vehid` int(11) NOT NULL,
  `creator` int(11) NOT NULL DEFAULT 0,
  `note` text NOT NULL,
  `date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wiretransfers`
--

CREATE TABLE `wiretransfers` (
  `id` int(10) UNSIGNED NOT NULL,
  `from` int(11) DEFAULT 0,
  `to` int(11) DEFAULT 0,
  `amount` int(11) NOT NULL,
  `reason` text DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  `type` int(11) NOT NULL,
  `from_card` varchar(45) DEFAULT NULL,
  `to_card` varchar(45) DEFAULT NULL,
  `details` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `wiretransfers`
--

INSERT INTO `wiretransfers` (`id`, `from`, `to`, `amount`, `reason`, `time`, `type`, `from_card`, `to_card`, `details`) VALUES
(80, 0, 10, 100000, '', '2023-07-09 19:56:31', 1, NULL, NULL, NULL),
(81, 0, 10, 45000, '', '2023-07-09 19:56:38', 1, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `worlditems`
--

CREATE TABLE `worlditems` (
  `id` int(11) NOT NULL,
  `itemid` int(11) DEFAULT 0,
  `itemvalue` text DEFAULT NULL,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 0,
  `dimension` int(5) DEFAULT 0,
  `interior` int(5) DEFAULT 0,
  `creationdate` datetime DEFAULT NULL,
  `rx` float DEFAULT 0,
  `ry` float DEFAULT 0,
  `rz` float DEFAULT 0,
  `creator` int(10) UNSIGNED DEFAULT 0,
  `protected` int(100) NOT NULL DEFAULT 0,
  `perm_use` int(2) NOT NULL DEFAULT 1,
  `perm_move` int(2) NOT NULL DEFAULT 1,
  `perm_pickup` int(2) NOT NULL DEFAULT 1,
  `perm_use_data` text DEFAULT NULL,
  `perm_move_data` text DEFAULT NULL,
  `perm_pickup_data` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worlditems_data`
--

CREATE TABLE `worlditems_data` (
  `id` int(11) NOT NULL,
  `item` int(11) NOT NULL,
  `key` varchar(100) NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `adminhistory`
--
ALTER TABLE `adminhistory`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `advertisements`
--
ALTER TABLE `advertisements`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `apb`
--
ALTER TABLE `apb`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `atms`
--
ALTER TABLE `atms`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `atm_cards`
--
ALTER TABLE `atm_cards`
  ADD PRIMARY KEY (`card_id`),
  ADD UNIQUE KEY `card_id_UNIQUE` (`card_id`);

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `businesses`
--
ALTER TABLE `businesses`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `business_accounts`
--
ALTER TABLE `business_accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `business_members`
--
ALTER TABLE `business_members`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `business_rentals`
--
ALTER TABLE `business_rentals`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `characters`
--
ALTER TABLE `characters`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `clothing`
--
ALTER TABLE `clothing`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `commands`
--
ALTER TABLE `commands`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `commands_library`
--
ALTER TABLE `commands_library`
  ADD PRIMARY KEY (`cmID`);

--
-- Indexes for table `computers`
--
ALTER TABLE `computers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cpa_postbacks`
--
ALTER TABLE `cpa_postbacks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `donates`
--
ALTER TABLE `donates`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `txn_id` (`txn_id`);

--
-- Indexes for table `donators`
--
ALTER TABLE `donators`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `don_purchases`
--
ALTER TABLE `don_purchases`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `don_transactions`
--
ALTER TABLE `don_transactions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `don_transaction_failed`
--
ALTER TABLE `don_transaction_failed`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `duty_allowed`
--
ALTER TABLE `duty_allowed`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `duty_custom`
--
ALTER TABLE `duty_custom`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `duty_locations`
--
ALTER TABLE `duty_locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `elections`
--
ALTER TABLE `elections`
  ADD PRIMARY KEY (`idelections`);

--
-- Indexes for table `elevators`
--
ALTER TABLE `elevators`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailaccounts`
--
ALTER TABLE `emailaccounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emails`
--
ALTER TABLE `emails`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `factions`
--
ALTER TABLE `factions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `force_apps`
--
ALTER TABLE `force_apps`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `friends`
--
ALTER TABLE `friends`
  ADD PRIMARY KEY (`id`,`friend`);

--
-- Indexes for table `fuelpeds`
--
ALTER TABLE `fuelpeds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fuelstations`
--
ALTER TABLE `fuelstations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gates`
--
ALTER TABLE `gates`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `insurance_data`
--
ALTER TABLE `insurance_data`
  ADD PRIMARY KEY (`policyid`);

--
-- Indexes for table `insurance_factions`
--
ALTER TABLE `insurance_factions`
  ADD PRIMARY KEY (`factionID`);

--
-- Indexes for table `interiors`
--
ALTER TABLE `interiors`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `interior_business`
--
ALTER TABLE `interior_business`
  ADD PRIMARY KEY (`intID`),
  ADD UNIQUE KEY `intID_UNIQUE` (`intID`);

--
-- Indexes for table `interior_notes`
--
ALTER TABLE `interior_notes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `interior_textures`
--
ALTER TABLE `interior_textures`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`index`);

--
-- Indexes for table `jailed`
--
ALTER TABLE `jailed`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jobs_trucker_orders`
--
ALTER TABLE `jobs_trucker_orders`
  ADD PRIMARY KEY (`orderID`);

--
-- Indexes for table `leo_impound_lot`
--
ALTER TABLE `leo_impound_lot`
  ADD PRIMARY KEY (`lane`);

--
-- Indexes for table `lifts`
--
ALTER TABLE `lifts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lift_floors`
--
ALTER TABLE `lift_floors`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_apb`
--
ALTER TABLE `mdc_apb`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_calls`
--
ALTER TABLE `mdc_calls`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_crimes`
--
ALTER TABLE `mdc_crimes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_criminals`
--
ALTER TABLE `mdc_criminals`
  ADD UNIQUE KEY `name` (`character`),
  ADD KEY `phone` (`phone`);

--
-- Indexes for table `mdc_faa_events`
--
ALTER TABLE `mdc_faa_events`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_faa_licenses`
--
ALTER TABLE `mdc_faa_licenses`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_impounds`
--
ALTER TABLE `mdc_impounds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mdc_users`
--
ALTER TABLE `mdc_users`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `motds`
--
ALTER TABLE `motds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `motd_read`
--
ALTER TABLE `motd_read`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `objects`
--
ALTER TABLE `objects`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `paynspray`
--
ALTER TABLE `paynspray`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pd_tickets`
--
ALTER TABLE `pd_tickets`
  ADD PRIMARY KEY (`id`,`time`);

--
-- Indexes for table `peds`
--
ALTER TABLE `peds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ped_inventory`
--
ALTER TABLE `ped_inventory`
  ADD PRIMARY KEY (`index`);

--
-- Indexes for table `phones`
--
ALTER TABLE `phones`
  ADD PRIMARY KEY (`phonenumber`),
  ADD UNIQUE KEY `phonenumber_UNIQUE` (`phonenumber`);

--
-- Indexes for table `phone_contacts`
--
ALTER TABLE `phone_contacts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `phone_history`
--
ALTER TABLE `phone_history`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ID_UNIQUE` (`id`);

--
-- Indexes for table `phone_sms`
--
ALTER TABLE `phone_sms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ID_UNIQUE` (`id`);

--
-- Indexes for table `pilot_notams`
--
ALTER TABLE `pilot_notams`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `publicphones`
--
ALTER TABLE `publicphones`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `radio_stations`
--
ALTER TABLE `radio_stations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `ramps`
--
ALTER TABLE `ramps`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `restricted_freqs`
--
ALTER TABLE `restricted_freqs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sapt_destinations`
--
ALTER TABLE `sapt_destinations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sapt_locations`
--
ALTER TABLE `sapt_locations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sapt_routes`
--
ALTER TABLE `sapt_routes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `serial_whitelist`
--
ALTER TABLE `serial_whitelist`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sfia_pilots`
--
ALTER TABLE `sfia_pilots`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shops`
--
ALTER TABLE `shops`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shop_contacts_info`
--
ALTER TABLE `shop_contacts_info`
  ADD PRIMARY KEY (`npcID`);

--
-- Indexes for table `shop_products`
--
ALTER TABLE `shop_products`
  ADD PRIMARY KEY (`pID`),
  ADD UNIQUE KEY `pID_UNIQUE` (`pID`);

--
-- Indexes for table `slotmachines`
--
ALTER TABLE `slotmachines`
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `speedcams`
--
ALTER TABLE `speedcams`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `speedingviolations`
--
ALTER TABLE `speedingviolations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stats`
--
ALTER TABLE `stats`
  ADD PRIMARY KEY (`district`);

--
-- Indexes for table `suspectcrime`
--
ALTER TABLE `suspectcrime`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tags`
--
ALTER TABLE `tags`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tc_comments`
--
ALTER TABLE `tc_comments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tc_tickets`
--
ALTER TABLE `tc_tickets`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tempobjects`
--
ALTER TABLE `tempobjects`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `textures_animated`
--
ALTER TABLE `textures_animated`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ticketreplies`
--
ALTER TABLE `ticketreplies`
  ADD PRIMARY KEY (`rid`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`tid`);

--
-- Indexes for table `tokens`
--
ALTER TABLE `tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token_UNIQUE` (`token`);

--
-- Indexes for table `towstats`
--
ALTER TABLE `towstats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `character_idx` (`character`),
  ADD KEY `vehicle_idx` (`vehicle`);

--
-- Indexes for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_2` (`id`),
  ADD KEY `id` (`id`);

--
-- Indexes for table `vehicles_custom`
--
ALTER TABLE `vehicles_custom`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `vehicles_shop`
--
ALTER TABLE `vehicles_shop`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indexes for table `vehicle_logs`
--
ALTER TABLE `vehicle_logs`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `vehicle_notes`
--
ALTER TABLE `vehicle_notes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `wiretransfers`
--
ALTER TABLE `wiretransfers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `worlditems`
--
ALTER TABLE `worlditems`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `worlditems_data`
--
ALTER TABLE `worlditems_data`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminhistory`
--
ALTER TABLE `adminhistory`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `advertisements`
--
ALTER TABLE `advertisements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `apb`
--
ALTER TABLE `apb`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `atms`
--
ALTER TABLE `atms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `atm_cards`
--
ALTER TABLE `atm_cards`
  MODIFY `card_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bans`
--
ALTER TABLE `bans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `books`
--
ALTER TABLE `books`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `business_accounts`
--
ALTER TABLE `business_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `business_members`
--
ALTER TABLE `business_members`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `business_rentals`
--
ALTER TABLE `business_rentals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `characters`
--
ALTER TABLE `characters`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `commands`
--
ALTER TABLE `commands`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=554;

--
-- AUTO_INCREMENT for table `commands_library`
--
ALTER TABLE `commands_library`
  MODIFY `cmID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=630;

--
-- AUTO_INCREMENT for table `computers`
--
ALTER TABLE `computers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cpa_postbacks`
--
ALTER TABLE `cpa_postbacks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donates`
--
ALTER TABLE `donates`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donators`
--
ALTER TABLE `donators`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `don_purchases`
--
ALTER TABLE `don_purchases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `don_transactions`
--
ALTER TABLE `don_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `don_transaction_failed`
--
ALTER TABLE `don_transaction_failed`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `duty_allowed`
--
ALTER TABLE `duty_allowed`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `duty_custom`
--
ALTER TABLE `duty_custom`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `duty_locations`
--
ALTER TABLE `duty_locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `elevators`
--
ALTER TABLE `elevators`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `emailaccounts`
--
ALTER TABLE `emailaccounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `emails`
--
ALTER TABLE `emails`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `factions`
--
ALTER TABLE `factions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=86;

--
-- AUTO_INCREMENT for table `force_apps`
--
ALTER TABLE `force_apps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fuelpeds`
--
ALTER TABLE `fuelpeds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fuelstations`
--
ALTER TABLE `fuelstations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gates`
--
ALTER TABLE `gates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=412;

--
-- AUTO_INCREMENT for table `insurance_data`
--
ALTER TABLE `insurance_data`
  MODIFY `policyid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `interiors`
--
ALTER TABLE `interiors`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `interior_notes`
--
ALTER TABLE `interior_notes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `interior_textures`
--
ALTER TABLE `interior_textures`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `index` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jailed`
--
ALTER TABLE `jailed`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs_trucker_orders`
--
ALTER TABLE `jobs_trucker_orders`
  MODIFY `orderID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `leo_impound_lot`
--
ALTER TABLE `leo_impound_lot`
  MODIFY `lane` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lifts`
--
ALTER TABLE `lifts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lift_floors`
--
ALTER TABLE `lift_floors`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_apb`
--
ALTER TABLE `mdc_apb`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_calls`
--
ALTER TABLE `mdc_calls`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_crimes`
--
ALTER TABLE `mdc_crimes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_faa_events`
--
ALTER TABLE `mdc_faa_events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_faa_licenses`
--
ALTER TABLE `mdc_faa_licenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_impounds`
--
ALTER TABLE `mdc_impounds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mdc_users`
--
ALTER TABLE `mdc_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `motds`
--
ALTER TABLE `motds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `motd_read`
--
ALTER TABLE `motd_read`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `objects`
--
ALTER TABLE `objects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `paynspray`
--
ALTER TABLE `paynspray`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `pd_tickets`
--
ALTER TABLE `pd_tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `peds`
--
ALTER TABLE `peds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ped_inventory`
--
ALTER TABLE `ped_inventory`
  MODIFY `index` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_contacts`
--
ALTER TABLE `phone_contacts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_history`
--
ALTER TABLE `phone_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_sms`
--
ALTER TABLE `phone_sms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `publicphones`
--
ALTER TABLE `publicphones`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `radio_stations`
--
ALTER TABLE `radio_stations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `ramps`
--
ALTER TABLE `ramps`
  MODIFY `id` int(2) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `restricted_freqs`
--
ALTER TABLE `restricted_freqs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sapt_destinations`
--
ALTER TABLE `sapt_destinations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `sapt_locations`
--
ALTER TABLE `sapt_locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `sapt_routes`
--
ALTER TABLE `sapt_routes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `serial_whitelist`
--
ALTER TABLE `serial_whitelist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sfia_pilots`
--
ALTER TABLE `sfia_pilots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shops`
--
ALTER TABLE `shops`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shop_products`
--
ALTER TABLE `shop_products`
  MODIFY `pID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `slotmachines`
--
ALTER TABLE `slotmachines`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `speedcams`
--
ALTER TABLE `speedcams`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `speedingviolations`
--
ALTER TABLE `speedingviolations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `suspectcrime`
--
ALTER TABLE `suspectcrime`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tags`
--
ALTER TABLE `tags`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tc_comments`
--
ALTER TABLE `tc_comments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tc_tickets`
--
ALTER TABLE `tc_tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tempobjects`
--
ALTER TABLE `tempobjects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `textures_animated`
--
ALTER TABLE `textures_animated`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ticketreplies`
--
ALTER TABLE `ticketreplies`
  MODIFY `rid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `tid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tokens`
--
ALTER TABLE `tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `towstats`
--
ALTER TABLE `towstats`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=174;

--
-- AUTO_INCREMENT for table `vehicles_custom`
--
ALTER TABLE `vehicles_custom`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vehicles_shop`
--
ALTER TABLE `vehicles_shop`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `vehicle_logs`
--
ALTER TABLE `vehicle_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vehicle_notes`
--
ALTER TABLE `vehicle_notes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wiretransfers`
--
ALTER TABLE `wiretransfers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=82;

--
-- AUTO_INCREMENT for table `worlditems`
--
ALTER TABLE `worlditems`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `worlditems_data`
--
ALTER TABLE `worlditems_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `towstats`
--
ALTER TABLE `towstats`
  ADD CONSTRAINT `character` FOREIGN KEY (`character`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `vehicle` FOREIGN KEY (`vehicle`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
