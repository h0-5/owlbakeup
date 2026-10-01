-- [Fix #160] gate table for task8 - A8 domain commands (shops/interiors/peds/elevators/cleanstreets)
-- Owned EXCLUSIVELY by agent A8 - do not edit from any other task.
-- Usage: staffRegisterGates({ [command] = right, ... })
--  * string right, command not yet mapped -> registered (first-wins vs base map)
--  * TABLE right -> union-merge with an existing mapping (shared commands)
staffRegisterGates({
        ------------------------------------------------------------ shops ----
        -- [Fix #160] /makeshop already = shops.manager -> union with makeshop
        ["makeshop"]              = {"shops.manager", "makeshop"},
        -- [Fix #160] new server commands (Player/s_fix160_domain.lua)
        ["showshops"]             = "showshops",
        ["shopitems"]             = "shops.items",
        -- [Fix #160] client ItemCreator aliases, kept alongside /shopitems
        ["items"]                 = "shops.items",
        ["additeminshop"]         = "additeminshop",
        ["additemsinshop"]        = "additemsinshop",
        ["shopquantity"]          = "shops.changeQuantity",
        ["getshopowner"]          = "shops.getowner",
        ["setshopowner"]          = "shops.setowner",
        -- [Fix #160] ATMs: /addatm already = intlib.add -> union with makeatm
        ["addatm"]                = {"intlib.add", "makeatm"},
        ["atmfast"]               = "makeatm",
        -- [Fix #160] /restartcarshops already = admin.restartres -> union
        ["restartcarshops"]       = {"admin.restartres", "restartcarshops"},
        ------------------------------------------------------ interiors ----
        ["setintowner"]           = "setintowner",
        ["removeintowner"]        = "removeintowner",
        ["getpropertyowner"]      = "property.getowner",
        -- [Fix #160] /delitemsfromint already = items.list.remove -> union
        ["delitemsfromint"]       = {"items.list.remove", "interior.deleteitems"},
        -- [Fix #160] deleteint family already mapped -> union property.delete
        ["delint"]                = {"deleteint", "property.delete"},
        ["delinterior"]           = {"deleteint", "property.delete"},
        ["delthisint"]            = {"deleteint", "property.delete"},
        ["delthisinterior"]       = {"deleteint", "property.delete"},
        ----------------------------------------------------------- peds ----
        -- [Fix #160] /makeped already = editor.editObjects -> union makeped
        ["makeped"]               = {"editor.editObjects", "makeped"},
        ["delped"]                = "delped",
        ["editped"]               = "editped",
        ----------------------------------------------------- elevators ----
        ["setelevforveh"]         = "elevator.setelevforveh",
        ["setelevforplayer"]      = "elevator.setelevforplayer",
        ------------------------------------------------- jobs / general ----
        ["setjob"]                = "jobs.setjob",
        -- [Fix #160] already mapped in the base table (first-wins -> no-op),
        -- kept here because the handler now really exists in task 8
        ["cleanstreets"]          = "admin.cleanstreets",
        ["radiostations"]         = "radiostations.manager",
        ["addphone"]              = "makephone",
        ["showinv"]               = "inventory.open",
        -- [Fix #160] /giveitem already = giveitem -> union items.list.add
        ["giveitem"]              = {"giveitem", "items.list.add"},
        -- [Fix #160] /setskin already = admin.skin -> union skins.makeskin
        ["setskin"]               = {"admin.skin", "skins.makeskin"},
        ["edithelp"]              = "edithelp",
        ["editcommands"]          = "editcommands",
        ----------------------------------------------------- textures ----
        ["vehtextures"]           = "Textures",
        --------------------------------------------------- briefcases ----
        ["givebc"]                = "bc.givebc",
        ["takebc"]                = "bc.takebc",
        ["checkbc"]               = "bc.checkbc",
        ["giveallbc"]             = "bc.giveallbc",
})
