-- [Fix #160] gate table for task7 - A7 admin misc commands - owner: Player/s_fix160_misc.lua
-- Owned EXCLUSIVELY by agent A7 admin misc commands - owner: Player/s_fix160_misc.lua[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
-- [Fix #160] A7 covers 32 rights. Group 1 = commands that already exist in
-- other resources, wired by mapping only (TABLE entries union-merge with the
-- base map, so the pre-existing right keeps working AND the new right grants):
--   scoreboard/s_tab.lua:486          /changeid    base admin.check  -> + accounts.changeid
--   es-system/s_es_system.lua:1913    /revive      was unmapped      ->   admin.revive
--   hud/s_overlay_show_admins.lua:639 /staff
--                       and  :635     /admins      was unmapped      ->   admin.isStaff
--   apps/app_manager_c.lua:509 + account/apps/app_manager_c.lua:255
--            /applications, /apps     base web.applications -> + applications.access
--   weather-system/s_weather_system.lua:625
--                                      /swh        base admin.setweather -> + admin.setwave
--   item-system/s_commands.lua:169    /issuebadge  already mapped admin.badge (base line 650)
-- Group 2 = NEW commands, handlers all live in Player/s_fix160_misc.lua.
-- /gms is deliberately NOT gated: it also registers chat-system's GM chat.
-- NOT MAPPED on purpose - no command/system exists in this server, each one is
-- reported NOT DONE in the A7 report instead of inventing a command:
--   admin.remove_gov, admin.voice_mute, admin.voice_unmute,
--   cinema, mechanic.panel, activity.create, activity.end
-- (admin.hide_logs WAS in this list; /hiddenlogs exists now - the gate entry
-- below maps it, matching the right its handler enforces.)
if rawget(_G, "FIX160_GATES_TASK7") then return end
_G.FIX160_GATES_TASK7 = true
staffRegisterGates({
        -- existing handlers, gate-only (union with the base map)
        ["changeid"]             = { "accounts.changeid" },
        ["revive"]               = "admin.revive",
        ["staff"]                = "admin.isStaff",
        ["admins"]               = "admin.isStaff",
        ["apps"]                 = { "applications.access" },
        ["applications"]         = { "applications.access" },
        ["swh"]                  = { "admin.setwave" },

        -- adminhistory family (s_check.lua owns /history + removeAdminHistoryLine)
        ["clearhistory"]         = "admin.clearhistory",
        ["clearhistoryforallonline"] = "admin.clearhistoryforallonline",
        ["removehistory"]        = "admin.removehistory",

        -- bulk resource / map tools (the single-resource tools stay base-mapped)
        ["restartallres"]        = "admin.restartallres",
        ["stopallres"]           = "admin.stopallres",
        ["startallmaps"]         = "admin.startallmaps",
        ["stopallmaps"]          = "admin.stopallmaps",

        -- misc staff tools
        ["pkickall"]             = "admin.pkickall",
        ["bc"]                   = "admin.bc_chat",
        ["togdevbadge"]          = "admin.badge.developer",
        ["togsupportbadge"]      = "admin.badge.support",

        -- panel / system rights with a real in-game handler
        ["appstate"]             = "applications.edit",
        ["addspecial"]           = "special_membership.add",
        ["removespecial"]        = "special_membership.remove",
        ["giveexp"]              = "level.give_exp",
        ["levelboost"]           = "level.boost",
        -- [Fix #160 5d] /hiddenlogs = GLOBAL hide toggle, right admin.hide_logs
        -- (the handler in Player/s_fix160_misc.lua checks exactly that right;
        -- the old mapping hidden.logs belonged to the pre-repurpose viewer and
        -- forced staff to hold BOTH rights to reach the command).
        ["hiddenlogs"]           = "admin.hide_logs",
        ["givefeature"]          = "feature.give",
})
