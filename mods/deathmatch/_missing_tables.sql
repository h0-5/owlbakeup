-- ============================================================
--  Missing tables for the PDZ / OwlGaming based roleplay server
--  (tables the scripts expect but which are not part of pdz.sql)
--  Import with:  mysql -u root pdz < _missing_tables.sql
-- ============================================================

-- used by resources/account/apps + resources/apps
CREATE TABLE IF NOT EXISTS `applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `applicant` int(11) DEFAULT NULL,
  `accountID` int(11) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `question1` text DEFAULT NULL,
  `question2` text DEFAULT NULL,
  `question3` text DEFAULT NULL,
  `question4` text DEFAULT NULL,
  `answer1` text DEFAULT NULL,
  `answer2` text DEFAULT NULL,
  `answer3` text DEFAULT NULL,
  `answer4` text DEFAULT NULL,
  `dateposted` datetime DEFAULT CURRENT_TIMESTAMP,
  `state` int(11) NOT NULL DEFAULT 0,
  `reviewer` int(11) DEFAULT NULL,
  `datereviewed` datetime DEFAULT NULL,
  `note` text DEFAULT NULL,
  `adminAction` int(11) NOT NULL DEFAULT 0,
  `adminNote` text DEFAULT NULL,
  `adminID` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `applications_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `part` int(11) NOT NULL DEFAULT 1,
  `question` text DEFAULT NULL,
  `key` varchar(20) DEFAULT '1',
  `answer1` varchar(255) DEFAULT NULL,
  `answer2` varchar(255) DEFAULT NULL,
  `answer3` varchar(255) DEFAULT NULL,
  `createdBy` int(11) DEFAULT NULL,
  `createDate` datetime DEFAULT NULL,
  `updatedBy` int(11) DEFAULT NULL,
  `updateDate` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by resources/dancer-system
CREATE TABLE IF NOT EXISTS `dancers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `x` float NOT NULL DEFAULT 0,
  `y` float NOT NULL DEFAULT 0,
  `z` float NOT NULL DEFAULT 0,
  `rotation` float NOT NULL DEFAULT 0,
  `skin` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  `dimension` int(11) NOT NULL DEFAULT 0,
  `offset` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by resources/global (fetchIPs / fetchSerials) and the ban commands
CREATE TABLE IF NOT EXISTS `bannedips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(45) DEFAULT NULL,
  `serial` varchar(32) DEFAULT NULL,
  `account` int(11) DEFAULT NULL,
  `admin` int(11) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bannedserials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(45) DEFAULT NULL,
  `serial` varchar(32) DEFAULT NULL,
  `account` int(11) DEFAULT NULL,
  `admin` int(11) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by resources/phone (s_gui_phone.lua)
CREATE TABLE IF NOT EXISTS `phone_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phonenumber` int(11) NOT NULL,
  `turnedon` smallint(1) NOT NULL DEFAULT 1,
  `secretnumber` smallint(1) NOT NULL DEFAULT 0,
  `phonebook` varchar(40) NOT NULL DEFAULT '0',
  `ringtone` smallint(1) NOT NULL DEFAULT 3,
  `contact_limit` int(5) NOT NULL DEFAULT 50,
  `boughtby` int(11) NOT NULL DEFAULT -1,
  `bought_date` datetime DEFAULT NULL,
  `sms_tone` smallint(1) NOT NULL DEFAULT 7,
  `keypress_tone` smallint(1) NOT NULL DEFAULT 1,
  `tone_volume` smallint(2) NOT NULL DEFAULT 10,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phonenumber` (`phonenumber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- used by the log resources (interior / vehicle logs)
CREATE TABLE IF NOT EXISTS `logtable` (
  `date` varchar(40) DEFAULT NULL,
  `action` text DEFAULT NULL,
  `source` text DEFAULT NULL,
  `affected` varchar(100) DEFAULT NULL,
  `data` text DEFAULT NULL,
  KEY `affected` (`affected`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- same structure, older log system name
CREATE TABLE IF NOT EXISTS `owl_logs` (
  `date` varchar(40) DEFAULT NULL,
  `action` text DEFAULT NULL,
  `source` text DEFAULT NULL,
  `affected` varchar(100) DEFAULT NULL,
  `data` text DEFAULT NULL,
  KEY `affected` (`affected`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
