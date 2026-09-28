-- ============================================================================
-- VORTEX — DATABASE SCHEMA part 2 (Fix #38): الفاكشنات والبنك والستاف
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 30 FACTIONS: الفاكشنات (faction-system)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS factions (
	id INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(64) NOT NULL,
	`type` INT NOT NULL DEFAULT 0,          -- 0=civ 1=police 2=gov 3=med ...
	color VARCHAR(16) DEFAULT '#FFFFFF',
	bank BIGINT NOT NULL DEFAULT 0,         -- الميزانية المالية للفاكشن
	welfare INT NOT NULL DEFAULT 0,
	hotline VARCHAR(32) DEFAULT '',
	radio VARCHAR(32) DEFAULT '',
	note VARCHAR(128) DEFAULT '',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS factionlogs (
	id INT NOT NULL AUTO_INCREMENT,
	factionID INT NOT NULL,
	date DATETIME DEFAULT NOW(),
	charactername VARCHAR(64) DEFAULT '',
	log TEXT,
	PRIMARY KEY (id),
	KEY factionID (factionID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 50 BANK: حسابات البنك (bank/s_bank_accounts.lua — نظام حسابات الكلاينت القديم)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bank_accounts (
	id INT NOT NULL AUTO_INCREMENT,
	code VARCHAR(16) NOT NULL UNIQUE,       -- رقم الحساب (7 خانات)
	ownerType VARCHAR(8) NOT NULL DEFAULT 'char',  -- char | faction
	ownerID INT NOT NULL,                   -- character.id أو factions.id
	ownerName VARCHAR(64) NOT NULL DEFAULT '',
	pin VARCHAR(64) NOT NULL DEFAULT '',    -- md5 للـ PIN (4 أرقام)
	balance BIGINT NOT NULL DEFAULT 0,
	created DATETIME DEFAULT NOW(),
	PRIMARY KEY (id),
	KEY owner (ownerType, ownerID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 60 STAFF: نظام الرتب (admin-system/staff_manager)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_roles (
	ID INT NOT NULL AUTO_INCREMENT,
	LevelName VARCHAR(64) NOT NULL,
	Rights TEXT,                            -- JSON { "admin.ban": true, ... }
	Color TEXT,                             -- JSON [r, g, b, a]
	PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS staff_role_members (
	RoleID INT NOT NULL,                    -- staff_roles.ID
	AccountID INT NOT NULL,                 -- accounts.id
	UNIQUE KEY ra (RoleID, AccountID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS staff_rank_changelogs (
	ID INT NOT NULL AUTO_INCREMENT,
	Date DATETIME DEFAULT NULL,
	cType VARCHAR(32),
	Username VARCHAR(64),
	FromR VARCHAR(64),
	ToR VARCHAR(64),
	By_ VARCHAR(64),
	PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 70 MISC: جداول من بقية المودات (من فحص CREATE TABLE في الكود)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedbacks (
	id INT NOT NULL AUTO_INCREMENT,
	userid INT,
	feedback TEXT,
	date DATETIME DEFAULT NOW(),
	handled INT DEFAULT 0,
	admin VARCHAR(64),
	adminnote TEXT,
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jailed (
	id INT NOT NULL AUTO_INCREMENT,
	character_id INT NOT NULL,
	reason VARCHAR(128),
	admin VARCHAR(64),
	seconds INT DEFAULT 0,
	date DATETIME DEFAULT NOW(),
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lifts (
	id INT NOT NULL AUTO_INCREMENT,
	x FLOAT, y FLOAT, z FLOAT,
	interior INT DEFAULT 0,
	dimension INT DEFAULT 0,
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lift_floors (
	id INT NOT NULL AUTO_INCREMENT,
	lift INT NOT NULL,
	f INT NOT NULL,
	x FLOAT, y FLOAT, z FLOAT,
	interior INT DEFAULT 0,
	dimension INT DEFAULT 0,
	name VARCHAR(32) DEFAULT '',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS owl_mta (
	`key` VARCHAR(64) NOT NULL,
	value TEXT,
	PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 99 PATCHES: توسعات لاحقة — أضف هنا ALTER TABLE الجديدة فقط
--   مثال:
--   ALTER TABLE characters ADD COLUMN IF NOT EXISTS newcolumn INT DEFAULT 0;
-- ---------------------------------------------------------------------------
