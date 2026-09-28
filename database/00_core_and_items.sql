-- ============================================================================
-- VORTEX OWLBAKEUP — DATABASE SCHEMA (Fix #38, MOD 2 part 3)
-- ملفات قاعدة البيانات الكاملة — تُستورد بالترتيب:
--   mysql -u root -p < 00_core.sql
--   mysql -u root -p < 10_items.sql
--   ... إلخ
--
-- كل الجداول تستخدم CREATE TABLE IF NOT EXISTS فاستيرادها آمن على قاعدة
-- موجودة (لن يمس صفوفاً ولا أعمدة موجودة). للتوسعة: أضف الأعمدة الجديدة في
-- 99_alter_patches.sql على شكل ALTER TABLE ... ADD COLUMN IF NOT EXISTS.
--
-- المعرف في الكود (mysql resource) يقرأ الإعدادات من:
--   mods/deathmatch/resources/mysql/settings.lua  (host/user/pass/dbname)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 00 CORE: الحسابات والشخصيات (accounts / characters)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS accounts (
	id INT NOT NULL AUTO_INCREMENT,
	username VARCHAR(32) NOT NULL,
	password VARCHAR(128) NOT NULL,
	email VARCHAR(64) DEFAULT '',
	serial VARCHAR(64) DEFAULT '',
	mtaserial VARCHAR(64) DEFAULT '',
	admin INT NOT NULL DEFAULT 0,          -- سلم الرتب القديم (يهاجر لـ staff_roles)
	supporter INT NOT NULL DEFAULT 0,
	scripter INT NOT NULL DEFAULT 0,
	hiddenadmin INT NOT NULL DEFAULT 0,
	appstate INT NOT NULL DEFAULT 1,
	forumid INT DEFAULT NULL,
	registerdate DATETIME DEFAULT NOW(),
	lastlogin DATETIME DEFAULT NULL,
	lastip VARCHAR(32) DEFAULT '',
	PRIMARY KEY (id),
	UNIQUE KEY username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS characters (
	id INT NOT NULL AUTO_INCREMENT,
	account INT NOT NULL,                   -- accounts.id
	charactername VARCHAR(32) NOT NULL,
	gender INT NOT NULL DEFAULT 0,
	age INT NOT NULL DEFAULT 18,
	weight INT NOT NULL DEFAULT 70,
	height INT NOT NULL DEFAULT 180,
	race INT NOT NULL DEFAULT 0,
	skin INT NOT NULL DEFAULT 0,
	x FLOAT DEFAULT 0, y FLOAT DEFAULT 0, z FLOAT DEFAULT 0,
	rotation FLOAT DEFAULT 0,
	interior INT NOT NULL DEFAULT 0,
	dimension INT NOT NULL DEFAULT 0,
	money INT NOT NULL DEFAULT 0,
	bankmoney INT NOT NULL DEFAULT 0,       -- مدخرات الرواتب (paycheck savings)
	faction INT NOT NULL DEFAULT 0,         -- factions.id (0 = بدون)
	factionleader INT NOT NULL DEFAULT 0,
	factionrank INT NOT NULL DEFAULT 0,
	job INT NOT NULL DEFAULT 0,
	jobrank INT NOT NULL DEFAULT 0,
	hoursplayed INT NOT NULL DEFAULT 0,     -- يغذي نظام المستويات في F1
	timeinserver INT NOT NULL DEFAULT 0,
	duty INT NOT NULL DEFAULT 0,
	lastarea VARCHAR(64) DEFAULT '',
	description VARCHAR(128) DEFAULT '',
	PRIMARY KEY (id),
	KEY account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS wiretransfers (
	id INT NOT NULL AUTO_INCREMENT,
	`from` INT NOT NULL DEFAULT 0,
	`to` INT NOT NULL DEFAULT 0,
	amount BIGINT NOT NULL DEFAULT 0,
	reason VARCHAR(128) DEFAULT '',
	`type` INT NOT NULL DEFAULT 0,
	time DATETIME DEFAULT NOW(),
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 10 ITEMS: الانفتوري والايتمز (item-system / item-world)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS items (
	id INT NOT NULL AUTO_INCREMENT,
	`type` INT NOT NULL,                    -- 1=player 2=vehicle 3=safe ...
	owner INT NOT NULL,                     -- معرف المالك حسب type
	itemID INT NOT NULL,                    -- رقم الايتم (g_items.lua)
	itemValue TEXT,                         -- قيمة الايتم (قد تكون نص طويل)
	`index` INT NOT NULL DEFAULT 1,         -- ترتيب داخل الشنطة
	protected INT NOT NULL DEFAULT 0,       -- 1 = محمي من الحذف
	created DATETIME DEFAULT NOW(),
	PRIMARY KEY (id),
	KEY owner (type, owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS worlditems (
	id INT NOT NULL AUTO_INCREMENT,
	itemID INT NOT NULL,
	itemValue TEXT,
	x FLOAT, y FLOAT, z FLOAT,
	rotation FLOAT DEFAULT 0,
	interior INT DEFAULT 0,
	dimension INT DEFAULT 0,
	created DATETIME DEFAULT NOW(),
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
