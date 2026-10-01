-- [Fix #160] gate table for task5 - A5 checkc panel + staff panel sections - owner: staff_manager/staff_manager_c.lua + fix160_panel/checkc files
-- Owned EXCLUSIVELY by agent A5 checkc panel + staff panel sections - owner: staff_manager/staff_manager_c.lua + fix160_panel/checkc files[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
staffRegisterGates({
        -- [Fix #160] A5: /checkc character-info panel (s_checkc.lua + c_checkc.lua)
        ["checkc"] = "admin.checkc",
        -- [Fix #160] A5: /managepanel = the same staff panel as /staffs, but
        -- gated to admin.manager.panel (/staffs keeps admin.check in the base map)
        ["managepanel"] = "admin.manager.panel",
})
