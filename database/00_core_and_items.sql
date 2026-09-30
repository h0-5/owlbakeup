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

-- [Fix #143] CREATE now mirrors the LIVE characters schema the code reads
-- (31 files use faction_id, 18 use faction_rank, 20 faction_leader, 9
-- faction_perks, 9 faction_phone, plus dutyskin/clothingid/lastlogin/...).
-- The previous DDL (faction/factionleader/factionrank, no faction_perks or
-- faction_phone) disagreed with the live table and broke ALL faction features
-- on a fresh import.
CREATE TABLE IF NOT EXISTS characters (
	id INT NOT NULL AUTO_INCREMENT,
	charactername TEXT,
	account INT DEFAULT 0,                   -- accounts.id
	x FLOAT DEFAULT 1770.02, y FLOAT DEFAULT -1860.91, z FLOAT DEFAULT 13.5782,
	rotation FLOAT DEFAULT 359.388,
	interior_id INT(5) DEFAULT 0,
	dimension_id INT(5) DEFAULT 0,
	health FLOAT DEFAULT 100,
	armor FLOAT DEFAULT 0,
	skin INT(3) DEFAULT 264,
	money BIGINT DEFAULT 500,
	gender INT(1) DEFAULT 0,
	cuffed INT(11) DEFAULT 0,
	duty INT(3) DEFAULT 0,
	fightstyle INT(2) DEFAULT 4,
	pdjail INT(1) DEFAULT 0,
	pdjail_time INT(11) DEFAULT 0,
	cked INT(1) DEFAULT 0,
	lastarea TEXT,
	age INT(3) DEFAULT 18,
	faction_id INT(11) DEFAULT -1,           -- factions.id (-1 = بدون)
	faction_rank INT(2) DEFAULT 1,
	faction_perks TEXT,                      -- JSON: صلاحيات ال duty
	faction_phone INT(3) UNSIGNED DEFAULT NULL,
	skincolor INT(1) DEFAULT 0,
	weight INT(3) DEFAULT 180,
	height INT(3) DEFAULT 180,
	description TEXT,
	deaths INT(11) DEFAULT 0,
	faction_leader INT(1) DEFAULT 0,
	fingerprint TEXT,
	casualskin INT(3) DEFAULT 0,
	bankmoney BIGINT DEFAULT 1000,           -- مدخرات الرواتب (paycheck savings)
	car_license INT(1) DEFAULT 0,
	bike_license INT(1) DEFAULT 0,
	pilot_license INT(1) DEFAULT 0,
	fish_license INT(1) DEFAULT 0,
	boat_license INT(1) DEFAULT 0,
	gun_license INT(1) DEFAULT 0,
	gun2_license INT(1) DEFAULT 0,
	tag INT(3) DEFAULT 1,
	hoursplayed INT(11) DEFAULT 0,           -- يغذي نظام المستويات في F1
	pdjail_station INT(1) DEFAULT 0,
	timeinserver INT(2) DEFAULT 0,
	restrainedobj INT(11) DEFAULT 0,
	restrainedby INT(11) DEFAULT 0,
	dutyskin INT(3) DEFAULT -1,
	fish INT(10) UNSIGNED NOT NULL DEFAULT 0,
	blindfold TINYINT(4) NOT NULL DEFAULT 0,
	lang1 TINYINT(2) DEFAULT 1,
	lang1skill TINYINT(3) DEFAULT 100,
	lang2 TINYINT(2) DEFAULT 0,
	lang2skill TINYINT(3) DEFAULT 0,
	lang3 TINYINT(2) DEFAULT 0,
	lang3skill TINYINT(3) DEFAULT 0,
	currlang TINYINT(1) DEFAULT 1,
	lastlogin DATETIME DEFAULT NULL,
	creationdate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	election_candidate TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
	election_canvote TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
	election_votedfor INT(10) UNSIGNED NOT NULL DEFAULT 0,
	marriedto INT(10) UNSIGNED NOT NULL DEFAULT 0,
	photos INT(10) UNSIGNED NOT NULL DEFAULT 0,
	maxvehicles INT(4) UNSIGNED NOT NULL DEFAULT 5,
	ck_info TEXT,
	alcohollevel FLOAT NOT NULL DEFAULT 0,
	active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
	recovery INT(1) DEFAULT 0,
	recoverytime BIGINT DEFAULT NULL,
	walkingstyle INT(3) NOT NULL DEFAULT 0,
	job INT(3) NOT NULL DEFAULT 0,           -- job/jobrank في الكود القديم
	day TINYINT(2) NOT NULL DEFAULT 1,
	month TINYINT(2) NOT NULL DEFAULT 1,
	maxinteriors INT(4) NOT NULL DEFAULT 10,
	clothingid INT(10) UNSIGNED DEFAULT NULL,
	death_date DATETIME DEFAULT NULL,
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- [Fix #144] أعمدة البطاقات/التفاصيل مفقودة قديماً والكود يستخدمها
-- (business.lua:421 يقرأ from_card/to_card/details) — الجدول الحي يحتويها.
CREATE TABLE IF NOT EXISTS wiretransfers (
	id INT NOT NULL AUTO_INCREMENT,
	`from` INT NOT NULL DEFAULT 0,
	`to` INT NOT NULL DEFAULT 0,
	amount BIGINT NOT NULL DEFAULT 0,        -- [Fix #145] كان INT — يفيض فوق 2^31
	reason VARCHAR(128) DEFAULT '',
	`type` INT NOT NULL DEFAULT 0,
	time DATETIME DEFAULT NOW(),
	from_card VARCHAR(45) DEFAULT NULL,
	to_card VARCHAR(45) DEFAULT NULL,
	details TEXT DEFAULT NULL,
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
