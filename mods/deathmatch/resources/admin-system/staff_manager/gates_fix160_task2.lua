-- [Fix #160] gate table for task2 - A2 bank/character/gunlicense/weapons - owner: bank/**, Player/s_fix160_char.lua
-- Owned EXCLUSIVELY by agent A2 bank/character/gunlicense/weapons - owner: bank/**, Player/s_fix160_char.lua[0]. Do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
-- [Fix #160] none of these command names existed in the base map, so every
-- entry below is a fresh string mapping (no union needed):
--   bank/s_bank_admin.lua           -> /showbanklog /showbankbalance
--   Player/s_fix160_char.lua        -> /givegunlicense /cancelgunlicense
--                                       /addlanguage /setcharmoney
--                                       /setcountry /wgoto
staffRegisterGates({
        ["showbanklog"] = "bank.showlog",
        ["showbankbalance"] = "bank.showbalance",
        ["givegunlicense"] = "givegunlicense",
        ["cancelgunlicense"] = "cancelgunlicense",
        ["addlanguage"] = "character.addlanguage",
        ["setcharmoney"] = "character.setmoney",
        ["setcountry"] = "character.setcountry",
        ["wgoto"] = "weapons.goto",
})
