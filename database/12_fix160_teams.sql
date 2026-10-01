-- ============================================================================
-- VORTEX — DATABASE SCHEMA part 4 (TEAMS / التيمات): حزم الصلاحيات
-- ============================================================================
-- التيمات هي حزم صلاحيات محفوظة تُضاف فوق سُلّم الرتب:
--   صلاحية اللاعب = صلاحيات رتبته  ∪  صلاحيات كل تيم هو عضو فيه (اتحاد/OR)
-- المنطق في admin-system/staff_manager/staff_manager_bridge_s.lua
-- (playerHasRight) والإدارة في staff_manager_teams_s.lua.
--
-- The two CREATE TABLE statements are idempotent, so this file is import-safe
-- before OR after the resource runs (the resource also runs the same
-- CREATE TABLE IF NOT EXISTS on start - staff_manager/staff_manager_teams_s.lua).
-- Member key = accounts.id, the SAME key staff_role_members uses for ranks
-- (staff_role_members: RoleID / AccountID -> staff_team_members: teamid /
-- account_id).

-- ---------------------------------------------------------------------------
-- STAFF TEAMS: التيمات (حزمة صلاحيات واحدة)
--   rights     = الصلاحيات مفصولة بفواصل (CSV) بنفس قيم AllRights
--                مثال: 'property.setowner,property.delete,interior.lock'
--   createdby  = اسم الحساب الذي أنشأ التيم
--   created    = تاريخ الإنشاء
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `staff_teams` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `rights` TEXT DEFAULT NULL,
  `createdby` VARCHAR(64) DEFAULT NULL,
  `created` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- STAFF TEAM MEMBERS: أعضاء التيمات (العضو = حساب)
--   UNIQUE(teamid, account_id) يمنع دخول العضو مرتين في نفس التيم
--   (نفس نمط staff_role_members: UNIQUE (RoleID, AccountID))
--   المفتاح المساعد stm_account للاستعلام السريع بالعكس
--   (كل تيمات هذا الحساب - يُستخدم عند تغيير صلاحيات اللاعب)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `staff_team_members` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `teamid` INT NOT NULL,
  `account_id` INT NOT NULL,
  `addedby` VARCHAR(64) DEFAULT NULL,
  `date` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `stm_team_account` (`teamid`, `account_id`),
  KEY `stm_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
