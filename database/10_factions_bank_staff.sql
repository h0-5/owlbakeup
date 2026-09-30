-- ============================================================================
-- VORTEX — DATABASE SCHEMA part 2 (Fix #38): الفاكشنات والبنك والستاف
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 30 FACTIONS: الفاكشنات (faction-system)
-- ---------------------------------------------------------------------------
-- [Fix #142] CREATE now matches the LIVE schema the code actually reads
-- (s_faction_system.lua: bankbalance, rank_1..20, wage_1..20, motd, note,
-- fnote, phone, max_interiors). The previous DDL (color/bank/welfare/hotline/
-- radio) disagreed with the live table, so on a fresh import whichever
-- CREATE ran first won and every faction query returned nil columns.
CREATE TABLE IF NOT EXISTS factions (
	id INT NOT NULL AUTO_INCREMENT,
	name TEXT,
	bankbalance BIGINT DEFAULT 0,           -- الميزانية المالية للفاكشن
	`type` INT DEFAULT 0,                   -- 0=civ 1=police 2=gov 3=med ...
	rank_1 TEXT, rank_2 TEXT, rank_3 TEXT, rank_4 TEXT, rank_5 TEXT,
	rank_6 TEXT, rank_7 TEXT, rank_8 TEXT, rank_9 TEXT, rank_10 TEXT,
	rank_11 TEXT, rank_12 TEXT, rank_13 TEXT, rank_14 TEXT, rank_15 TEXT,
	rank_16 TEXT, rank_17 TEXT, rank_18 TEXT, rank_19 TEXT, rank_20 TEXT,
	wage_1 INT DEFAULT 100, wage_2 INT DEFAULT 100, wage_3 INT DEFAULT 100,
	wage_4 INT DEFAULT 100, wage_5 INT DEFAULT 100, wage_6 INT DEFAULT 100,
	wage_7 INT DEFAULT 100, wage_8 INT DEFAULT 100, wage_9 INT DEFAULT 100,
	wage_10 INT DEFAULT 100, wage_11 INT DEFAULT 100, wage_12 INT DEFAULT 100,
	wage_13 INT DEFAULT 100, wage_14 INT DEFAULT 100, wage_15 INT DEFAULT 100,
	wage_16 INT DEFAULT 100, wage_17 INT DEFAULT 100, wage_18 INT DEFAULT 100,
	wage_19 INT DEFAULT 100, wage_20 INT DEFAULT 100,
	motd TEXT,
	note TEXT,
	fnote TEXT,
	phone VARCHAR(20),
	max_interiors INT DEFAULT 20,
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
--
-- [Fix #142] الأعمدة التصميمية (color/welfare/hotline/radio) كانت في القديم
--   ضمن CREATE لكنها غير موجودة في الجدول الحي — أضفها كـ ALTER لـ installs جديدة:
--   ALTER TABLE factions ADD COLUMN color VARCHAR(16) DEFAULT '#FFFFFF';
--   ALTER TABLE factions ADD COLUMN welfare INT NOT NULL DEFAULT 0;
--   ALTER TABLE factions ADD COLUMN hotline VARCHAR(32) DEFAULT '';
--   ALTER TABLE factions ADD COLUMN radio VARCHAR(32) DEFAULT '';
--
-- [Fix #118] إحداثيات duty_locations كانت INT والكود يكتب FLOAT:
--   ALTER TABLE duty_locations MODIFY x FLOAT, MODIFY y FLOAT,
--     MODIFY z FLOAT, MODIFY radius FLOAT;
--   (تم تنفيذه على الجدول الحي)
--
-- [Fix #145] wiretransfers.amount كان INT والتحويلات الكبيرة تفيض:
--   ALTER TABLE wiretransfers MODIFY amount BIGINT NOT NULL;
--   (تم تنفيذه على الجدول الحي)
-- ---------------------------------------------------------------------------
