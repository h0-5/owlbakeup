-- [Fix #160] gate table for task6 - A6 /h high staff chat + object/gate system - owner: chat-system/**, gate-manager/**
-- Owned EXCLUSIVELY by agent A6 /h high staff chat + object/gate system - owner: chat-system/**, gate-manager/**[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
staffRegisterGates({
        -- [Fix #160] /h HIGH STAFF CHAT - handler: chat-system/s_chat_system.lua (highStaffChat)
        ["h"]                 = "admin.highstaffchat",

        -- [Fix #160] OBJECT & GATE system (gate-manager) - creation
        -- /makeobj places a persistent object (s_object_tools_fix160.lua)
        ["makeobj"]           = "editor.editObjects",
        -- /newgate is already mapped to places.add in the base map; a TABLE
        -- union-merges so EITHER places.add OR makegate grants it.
        ["newgate"]           = { "makegate" },

        -- [Fix #160] gate/object editing, removal, locking (gate-manager)
        ["editobj"]           = "editObjectProperties",
        ["delobj"]            = "editor.removeObjects",
        ["lockgate"]          = "lockgate",
        ["unlockgate"]        = "lockgate",

        -- [Fix #160] map / creator tools (gate-manager)
        ["savemap"]           = "editor.savemap",
        ["checkcreator"]      = "editor.checkcreator",

        -- [Fix #160] keys - /copykey already lives in job-system/locksmith
        ["copykey"]           = "duplicate.keys",
        ["delkey"]            = "keys.delete",
})
