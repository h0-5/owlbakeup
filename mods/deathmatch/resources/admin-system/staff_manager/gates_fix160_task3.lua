-- [Fix #160] gate table for task3 - A3 faction commands + faction blacklist - owner: faction-system/**
-- Owned EXCLUSIVELY by agent A3 faction commands + faction blacklist - owner: faction-system/**[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
-- [Fix #160] A3 - handlers live in faction-system/s_faction_fix160.lua:
--   /setfactionname /setfactiontype /givefactionpoints /checkfaction
--   /checkinvoices /clearinvoices /clearfactionlogs /forcefactionwage
--   /resetfactionranks /showfbl /addfbl /removefbl
--   NOT listed below: /setfactionradio - the base map already maps it to the
--   right "setfactionradio", so a string entry here would be a no-op.
--   Shared commands are TABLE entries -> union (the admin handler still
--   enforces its own right, the extra right only widens the gate).
staffRegisterGates({
        -- shared with admin-system (union-merge, ANY right grants access)
        ["takemoney"]     = { "admin.takeplayermoney", "faction.takemoney" },
        ["givemoney"]     = { "admin.giveplayermoney", "faction.givemoney" },
        ["check"]         = { "admin.check", "faction.check", "factions.check" },
        ["renamefaction"] = { "setfaction", "setfactionname" },

        -- fresh mappings (no base entry -> plain string register)
        ["setfactionname"]     = "setfactionname",
        ["setfactiontype"]     = "setfactiontype",
        ["givefactionpoints"]  = "faction.givepoints",
        ["checkfaction"]       = "factions.check",
        ["checkinvoices"]      = "faction.checkinvoices",
        ["clearinvoices"]      = "faction.clearinvoices",
        ["clearfactionlogs"]   = "factions.clearlogs",
        ["forcefactionwage"]   = "faction.forcewage",
        ["resetfactionranks"]  = "faction.resetranks",

        -- faction blacklist (the new factions_blacklist table)
        ["showfbl"]            = "factions.blacklist.show",
        ["addfbl"]             = "factions.blacklist.add",
        ["removefbl"]          = "factions.blacklist.delete",
})
