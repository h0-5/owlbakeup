--[[ ------------------------------------------------------------------------
        Vortex Staff System — BACKEND-FIRST command gates (Fix #36, build v3).

        WHY THE OWNER COULD STILL USE CLOSED COMMANDS (root cause, found by
        auditing every addCommandHandler in the repo):
          The gate map covered pban/sban/oban/soban but NOT the rest of the
          ban family (banserial/serialban, banip/ipban, banaccount/accountban,
          showban/findban), NOT the resource controls (restartres/stopres/
          startres/resstate/reloadacl), NOT the vehicle admin family in
          vehicle-manager (fixvehs/fixvehvis/fuelvehs/delveh/makeveh/getcar/
          deletevehicle/enterveh/checkveh/findvehid/respawn*/unlockcivcars...)
          and NOT the item/interior/faction admin families. hasCommandRight
          returns true ("no opinion") for UNMAPPED commands, so every command
          we forgot passed the global gate and ran. The panel untick DID save
          - the gate just never asked about that command.

        FIX: the map below was built from a full repo scan (1040 distinct
        commands, every admin-relevant one mapped to the AllRights name the
        panel shows). Unmapped commands are now ONLY true player/RP commands.

        SELF-VERIFICATION (the user must be able to SEE the gate working):
          /staffver            -> build, mapped-command count, your rank,
                                  your live rights count, gate heartbeat
                                  (proves onPlayerCommand is firing)
          /staffver <command>  -> which right gates it + ALLOWED/DENIED for you
        Registered through the RAW addCommandHandler (never gated).

        Enforcement layers (unchanged):
          1. addCommandHandler wrapper - gates admin-system's own handlers.
          2. onPlayerCommand global gate - fires for EVERY typed command from
             ANY resource and cancelEvent() blocks it (vehicle-manager,
             bans, item-system, faction-system, interior-system...).
-------------------------------------------------------------------------- ]]

local GATES_VERSION = 3

local COMMAND_RIGHTS = {
        -------------------------------------------------------------- bans ----
        ["ban"]          = "admin.ban",
        ["pban"]         = "admin.ban",
        ["sban"]         = "admin.ban",
        ["oban"]         = "admin.ban",
        ["soban"]        = "admin.ban",
        ["kick"]         = "admin.pkick",
        ["banserial"]    = "admin.banserial",
        ["serialban"]    = "admin.banserial",
        ["banip"]        = "admin.banip",
        ["ipban"]        = "admin.banip",
        ["banaccount"]   = "admin.banaccount",
        ["accountban"]   = "admin.banaccount",
        ["unban"]        = "admin.unban",
        ["showban"]      = "admin.showban",
        ["findban"]      = "admin.showban",
        ---------------------------------------------------------- teleport ----
        ["goto"]         = "admin.goto",
        ["sendto"]       = "admin.sendto",
        ["gethere"]      = "admin.gethere",
        ["gotoplace"]    = "admin.gotoplace",
        ["places"]       = "places.access",
        ["osendtols"]    = "admin.sendtoplace",
        ["gotoveh"]      = "admin.gotoveh",
        ["gotocar"]      = "admin.gotoveh",
        ["gotoint"]      = "admin.gotoint",
        ["gotointi"]     = "admin.gotoint",
        ["gotohouse"]    = "admin.gotoint",
        ["gotoped"]      = "admin.gotoped",
        -------------------------------------------------------- punishment ----
        ["jail"]         = "admin.jail",
        ["sjail"]        = "admin.jail",
        ["ojail"]        = "admin.jail",
        ["sojail"]       = "admin.jail",
        ["unjail"]       = "admin.unjail",
        ["jailed"]       = "admin.show_jails",
        ["unbanip"]      = "admin.unban",
        ["unbanserial"]  = "admin.unban",
        ["pkick"]        = "admin.pkick",
        ["skick"]        = "admin.pkick",
        ["warn"]         = "admin.warn",
        ["changewarnstyle"] = "admin.warn",
        ["freeze"]       = "admin.freeze",
        ["unfreeze"]     = "admin.unfreeze",
        ["disarm"]       = "disarm",
        ["mute"]         = "admin.mute",
        ["unmute"]       = "admin.unmute",
        ["pmute"]        = "admin.mute",
        ["auncuff"]      = "admin.uncuffs",
        ["ck"]           = "admin.ck",
        ["unck"]         = "admin.unck",
        ["bury"]         = "admin.ck",
        ------------------------------------------------- character / account ----
        ["sethp"]        = "admin.sethp",
        ["aheal"]        = "admin.sethp",
        ["setarmor"]     = "admin.sethp",
        ["setskin"]      = "admin.skin",
        ["changename"]   = "admin.changename",
        ["setage"]       = "character.setage",
        ["setheight"]    = "character.setheight",
        ["setweight"]    = "character.setweight",
        ["setrace"]      = "character.setgender",
        ["setgender"]    = "character.setgender",
        ["setdob"]       = "character.setage",
        ["setdateofbirth"] = "character.setage",
        ["setlanguage"]  = "character.setlanguage",
        ["setlang"]      = "character.setlanguage",
        ["dellanguage"]  = "character.removelanguage",
        ["resetcharacter"] = "owner.removecharacter",
        ["resetaccount"] = "owner.removeaccount",
        ["rs"]           = "owner.removecharacter",
        ["resetpos"]     = "character.setposition",
        ["unrecovery"]   = "owner.removecharacter",
        ["findalts"]     = "admin.showalts",
        ["findalts2"]    = "admin.showalts",
        ["findip"]       = "owner.checkserial",
        ["findserial"]   = "owner.checkserial",
        ------------------------------------------------------------- economy ----
        ["setmoney"]     = "admin.setplayermoney",
        ["givemoney"]    = "admin.giveplayermoney",
        ["takemoney"]    = "admin.takeplayermoney",
        ["givegc"]       = "admin.giveallmoney",
        ["givegamecoins"] = "admin.giveallmoney",
        ["givegamecoin"] = "admin.giveallmoney",
        --------------------------------------------------- world / vehicles ----
        ["fixveh"]       = "admin.fixveh",
        ["fixvehs"]      = "vehicle.fixallveh",
        ["fixvehvis"]    = "vehicle.fixallveh",
        ["fuelveh"]      = "admin.fuelveh",
        ["fuelvehs"]     = "admin.fuelveh",
        ["giveveh"]      = "admin.giveveh",
        ["getveh"]       = "admin.getveh",
        ["getcar"]       = "admin.getveh",
        ["gotovehs"]     = "admin.gotoveh",
        ["destroyveh"]   = "admin.destroyveh",
        ["deletevehicle"] = "admin.destroyveh",
        ["blowveh"]      = "admin.destroyveh",
        ["delveh"]       = "delveh",
        ["delthisveh"]   = "delveh",
        ["delnearbyveh"] = "delveh",
        ["delnearbyvehs"] = "delveh",
        ["delnearbyvehicles"] = "delveh",
        ["makeveh"]      = "makeveh",
        ["editvehicle"]  = "editvehicle",
        ["editveh"]      = "editvehicle",
        ["edithandling"] = "editvehicle",
        ["setvehfaction"] = "setvehfaction",
        ["setvehiclefaction"] = "setvehfaction",
        ["setvehplate"]  = "editvehicle",
        ["setvehicleplate"] = "editvehicle",
        ["setpaintjob"]  = "editvehicle",
        ["setvariant"]   = "editvehicle",
        ["setcarhp"]     = "editvehicle",
        ["setdamageproof"] = "editvehicle",
        ["setbulletproof"] = "editvehicle",
        ["setodometer"]  = "editvehicle",
        ["setmilage"]    = "editvehicle",
        ["addupgrade"]   = "editvehicle",
        ["deleteupgrade"] = "editvehicle",
        ["delupgrade"]   = "editvehicle",
        ["resetupgrades"] = "editvehicle",
        ["setcolor"]     = "vehicle.setcolor",
        ["setvehtint"]   = "setvehtint",
        ["enterveh"]     = "admin.enterveh",
        ["entercar"]     = "admin.enterveh",
        ["entervehicle"] = "admin.enterveh",
        ["sendtoveh"]    = "admin.sendtoveh",
        ["sendveh"]      = "admin.sendtoveh",
        ["sendcar"]      = "admin.sendtoveh",
        ["sendvehto"]    = "admin.sendvehto",
        ["checkveh"]     = "admin.checkveh",
        ["checkvehicle"] = "admin.checkveh",
        ["findvehid"]    = "admin.checkveh",
        ["respawnall"]   = "vehicle.respawnallveh",
        ["respawnciv"]   = "vehicle.respawnallveh",
        ["respawndistrict"] = "vehicle.respawnallveh",
        ["respawnveh"]   = "vehicle.respawnallveh",
        ["respawnfaction"] = "vehicle.respawnallfactionveh",
        ["unlockcivcars"] = "vehicle.lock/unlock",
        ["vehiclelibrary"] = "vehicles.library",
        ["vehlib"]       = "vehicles.library",
        ["clearvehicleinventory"] = "giveitem",
        ["clearvehinv"]  = "giveitem",
        ["setvehlimit"]  = "setfactionvehlimit",
        ["setintlimit"]  = "setfactionvehlimit",
        ["setint"]       = "admin.setplayerint",
        ["setinterior"]  = "admin.setplayerint",
        ["setdim"]       = "admin.setplayerdim",
        ["setdimension"] = "admin.setplayerdim",
        ------------------------------------------------------------ items ----
        ["giveitem"]     = "giveitem",
        ["givepeditem"]  = "giveitem",
        ["makegeneric"]  = "makegeneric",
        ["makegenericitem"] = "makegeneric",
        ["cmg"]          = "makegeneric",
        ["cargomakegeneric"] = "makegeneric",
        ["takeitem"]     = "giveitem",
        ["makegun"]      = "giveitem",
        ["makeammo"]     = "giveitem",
        ["gunmaker"]     = "giveitem",
        ["fixinventory"] = "giveitem",
        ["delitem"]      = "items.list.remove",
        ["delallitems"]  = "items.list.remove",
        ["delitemsfromint"] = "items.list.remove",
        ["delnearbyitems"] = "items.list.remove",
        ["itemlist"]     = "items.list",
        ["itemprotect"]  = "items.list.edit",
        ------------------------------------------------------ server admin ----
        ["setweather"]   = "admin.setweather",
        ["settime"]      = "admin.settime",
        ["setfpslimit"]  = "admin.setfpslimit",
        ["setgametype"]  = "admin.setgametype",
        ["setserverpassword"] = "admin.setserverpassword",
        ["setserverpw"]  = "admin.setserverpassword",
        ["setpos"]       = "admin.setpos",
        ["pos"]          = "admin.pos",
        ["getpos"]       = "admin.pos",
        ["xyz"]          = "admin.xyz",
        ["ann"]          = "admin.ann",
        ["ooc"]          = "admin.ooc",
        ["clearchatforall"] = "admin.clearchatforall",
        ["forceapp"]     = "admin.forceapp",
        ["fa"]           = "admin.forceapp",
        ["unforceapp"]   = "admin.unforceapp",
        ["unfa"]         = "admin.unforceapp",
        ["freconnect"]   = "admin.forceapp",
        ["frec"]         = "admin.forceapp",
        ["hideadmin"]    = "admin.hide_admin",
        ["togmytag"]     = "admin.hide_admin",
        ["adminduty"]    = "duty.adminduty",
        ["aduty"]        = "duty.adminduty",
        ["sduty"]        = "duty.adminduty",
        ["dutyadmin"]    = "duty.adminduty",
        ["gduty"]        = "duty.showallonduty",
        ["earthquake"]   = "admin.makefire",
        ["makefire"]     = "admin.makefire",
        ["removefire"]   = "admin.removefire",
        ["cleanstreets"] = "admin.cleanstreets",
        ["nudge"]        = "admin.eject",
        ["slap"]         = "admin.eject",
        ["eject"]        = "admin.eject",
        ["togattach"]    = "admin.eject",
        ["toggleattach"] = "admin.eject",
        ["unmask"]       = "admin.eject",
        ["aunmask"]      = "admin.eject",
        ["unblindfold"]  = "admin.eject",
        ["aunblindfold"] = "admin.eject",
        ["supervise"]    = "admin.recon",
        ["recon"]        = "admin.recon",
        ["stoprecon"]    = "admin.recon",
        ["freecam"]      = "admin.freecam",
        ["fuckrecon"]    = "admin.recon",
        ["watch"]        = "admin.recon",
        ["autowatch"]    = "admin.recon",
        ["stopwatch"]    = "admin.recon",
        ["pausewatch"]   = "admin.recon",
        ["resumewatch"]  = "admin.recon",
        ["monitor"]      = "admin.recon",
        ["omonitor"]     = "admin.recon",
        ["omonitor2"]    = "admin.recon",
        ["snakecam"]     = "admin.recon",
        ["dropme"]       = "admin.fakeme",
        ["fakeme"]       = "admin.fakeme",
        ["disappear"]    = "admin.disappear",
        ["seefar"]       = "admin.disappear",
        ["info"]         = "admin.check",
        ["check"]        = "admin.check",
        ["checkvehc"]    = "admin.checkveh",
        ["history"]      = "admin.history",
        ["restartres"]   = "admin.restartres",
        ["stopres"]      = "admin.stopres",
        ["startres"]     = "admin.startres",
        ["resstate"]     = "admin.resstate",
        ["reloadacl"]    = "admin.resstate",
        ["restartgatekeepers"] = "admin.restartres",
        ["restartcarshops"] = "admin.restartres",
        ["staffdb"]      = "admin.manager.editranks",
        ["adminlounge"]  = "admin.isAdmin",
        ["gmlounge"]     = "admin.isAdmin",
        ["getkey"]       = "givekey",
        ["givelicense"]  = "givelicense",
        ["agivelicense"] = "givelicense",
        ["agl"]          = "givelicense",
        ["atakelicense"] = "givelicense",
        ["atl"]          = "givelicense",
        ["takelicense"]  = "givelicense",
        ["issuepilotcertificate"] = "givelicense",
        ["issuepilotcert"] = "givelicense",
        ["issuepc"]      = "givelicense",
        ["issuepilot"]   = "givelicense",
        ["oldpilot"]     = "givelicense",
        ["govlicense"]   = "givelicense",
        ["911"]          = "admin.ooc",
        --------------------------------------------------------- interiors ----
        ["addint"]       = "addint",
        ["addinterior"]  = "addint",
        ["addnewint"]    = "addint",
        ["delint"]       = "deleteint",
        ["delinterior"]  = "deleteint",
        ["delthisint"]   = "deleteint",
        ["delthisinterior"] = "deleteint",
        ["delnearbyints"] = "deleteint",
        ["delnearbyinteriors"] = "deleteint",
        ["removeint"]    = "deleteint",
        ["removeinterior"] = "deleteint",
        ["setintid"]     = "setintid",
        ["setinteriorid"] = "setintid",
        ["setintname"]   = "setintname",
        ["setinteriorname"] = "setintname",
        ["setintprice"]  = "setintprice",
        ["setinteriorprice"] = "setintprice",
        ["setintentrance"] = "setintenterance",
        ["setinteriorentrance"] = "setintenterance",
        ["setintexit"]   = "setintenterance",
        ["setinteriorexit"] = "setintenterance",
        ["setinteriortype"] = "setintid",
        ["setinttype"]   = "setintid",
        ["reloadint"]    = "addint",
        ["reloadinterior"] = "addint",
        ["restoreint"]   = "addint",
        ["restoreinterior"] = "addint",
        ["toggleinterior"] = "addint",
        ["togint"]       = "addint",
        ["forcesell"]    = "setintforsale",
        ["fsell"]        = "setintforsale",
        ["forcesellactiveinteriors"] = "setintforsale",
        ["forcesellactiveints"] = "setintforsale",
        ["cancelforcesellinactiveints"] = "cancelintsale",
        ["cancelremovedeletedints"] = "deleteint",
        ["cancelremoveforsaleints"] = "cancelintsale",
        ["cancelremoveinactiveints"] = "deleteint",
        ["removedeletedinteriors"] = "deleteint",
        ["removedeletedints"] = "deleteint",
        ["removeforsaleinteriors"] = "cancelintsale",
        ["removeforsaleints"] = "cancelintsale",
        ["removeinactiveinteriors"] = "deleteint",
        ["removeinactiveints"] = "deleteint",
        ["sellproperty"] = "property.setowner",
        ["interiordiff"] = "addint",
        ---------------------------------------------------------- factions ----
        ["makefaction"]  = "makefaction",
        ["delfaction"]   = "removefaction",
        ["setfactionleader"] = "setfactionleader",
        ["setfactionmoney"] = "faction.setmoney",
        ["setfactionrank"] = "faction.editranks",
        ["renamefaction"] = "setfaction",
        ["setfactioncolor"] = "setfactioncolor",
        ["setfactionradio"] = "setfactionradio",
        ["setfactionhotline"] = "setfactionhotline",
        ["showfactions"] = "factions.show",
        ["showfactionplayers"] = "factions.show",
        -------------------------------------------------------- diagnostics ----
        ["playthenoise"] = "debug",
        ["devmode"]      = "debug",
        ["fpsdiag"]      = "debug",
        ["911diag"]      = "debug",
}

local gateHeartbeat = { fired = 0, lastCommand = "-" }

-- ===========================================================================
-- Layer 1 (Fix #25): the addCommandHandler WRAPPER inside the admin-system
-- Lua VM. Every command registered by THIS resource gets the right check
-- inlined at the top of its handler. Layer 2 below covers every OTHER
-- resource through onPlayerCommand.
-- ===========================================================================
local rawAddCommandHandler = addCommandHandler

_G.addCommandHandler = function(commandName, handlerFunction, caseSensitive, restricted, ...)
        local gated = function(player, cmdName, ...)
                if player and isElement(player)
                        and not hasCommandRight(player, cmdName or commandName) then
                        outputChatBox("You don't have permission to use this command.",
                                player, 255, 0, 0)
                        return
                end
                return handlerFunction(player, cmdName, ...)
        end
        return rawAddCommandHandler(commandName, gated, caseSensitive, restricted, ...)
end

-- the exported gate. Returns true when the command is ALLOWED.
function hasCommandRight(player, commandName)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        local right = COMMAND_RIGHTS[tostring(commandName):lower()]
        -- an unmapped command is not restricted by this layer (the handler's
        -- own legacy check still applies); returning true means "no opinion".
        if not right then return true end
        -- a logged-in Vortex rank is decided SOLELY by its stored rights
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right)
                end
                return false
        end
        -- no Vortex rank: the legacy ladder decides (unchanged behaviour)
        return true
end

-- table lookup for the panel / debugging: which right gates this command
function getCommandRight(commandName)
        return COMMAND_RIGHTS[tostring(commandName):lower()] or false
end

local function countMap(t)
        local n = 0
        for _ in pairs(t) do n = n + 1 end
        return n
end

local function unwrapLiveRights(player)
        local raw = getElementData(player, "rank:rights")
        if type(raw) ~= "string" or raw == "" then return nil end
        local ok, parsed = pcall(fromJSON, raw)
        if not ok or type(parsed) ~= "table" then return nil end
        if type(parsed[1]) == "table" and next(parsed, 1) == nil then
                parsed = parsed[1]
        end
        if type(parsed) ~= "table" then return nil end
        return parsed
end

-- ===========================================================================
-- [Fix #36] SELF-VERIFICATION: /staffver proves the gate is alive ON THE
-- USER'S MACHINE and shows exactly which right gates a command. Registered
-- through the RAW handler so it can never be gated by itself.
-- ===========================================================================
addEventHandler("onPlayerCommand", root, function(commandName)
        gateHeartbeat.fired = gateHeartbeat.fired + 1
        gateHeartbeat.lastCommand = tostring(commandName)
end)

local function staffVerCommand(player, _, cmd)
        outputChatBox("========== STAFF GATES v" .. GATES_VERSION .. " ==========", player, 60, 200, 120)
        outputChatBox("mapped commands: " .. countMap(COMMAND_RIGHTS)
                .. " | onPlayerCommand ALIVE (fired " .. gateHeartbeat.fired
                .. "x, last: /" .. gateHeartbeat.lastCommand .. ")", player, 220, 220, 220)

        local idx = getElementData(player, "rank:index")
        local name = getElementData(player, "rank:name")
        if not idx then
                outputChatBox("your rank: NONE (no Vortex rank) - commands follow the legacy ladder",
                        player, 255, 170, 60)
        else
                local rights = unwrapLiveRights(player)
                outputChatBox("your rank: " .. tostring(name) .. " (#" .. tostring(idx) .. ")"
                        .. " | live rights on this rank: " .. (rights and countMap(rights) or "0"),
                        player, 220, 220, 220)
        end

        if cmd and cmd ~= "" then
                cmd = tostring(cmd):lower()
                local right = COMMAND_RIGHTS[cmd]
                if not right then
                        outputChatBox("/" .. cmd .. " is NOT gated (player command or unmapped).",
                                player, 255, 170, 60)
                        return
                end
                outputChatBox("/" .. cmd .. " -> right \"" .. right .. "\"", player, 120, 200, 255)
                if not idx then
                        outputChatBox("verdict for you: legacy ladder decides (no rank set)",
                                player, 255, 170, 60)
                        return
                end
                local allowed = hasCommandRight(player, cmd)
                outputChatBox("verdict for YOU: " .. (allowed and "ALLOWED" or "DENIED"),
                        player, allowed and 80 or 255, allowed and 255 or 80, 80)
                if not allowed then
                        outputChatBox("this command is CLOSED for your rank - onPlayerCommand will cancel it.",
                                player, 255, 120, 120)
                end
        else
                outputChatBox("usage: /staffver <command>  (e.g. /staffver fixveh, /staffver pban)",
                        player, 170, 170, 170)
        end
end
rawAddCommandHandler("staffver", staffVerCommand, false, false)

-- ===========================================================================
-- GLOBAL enforcement gate (Fix #25/#32/#34/#36). Fires before every typed
-- command from ANY resource; cancelEvent() blocks it. pcall-wrapped: a gate
-- error can never silently re-allow a closed command without a loud trace.
-- ===========================================================================
addEventHandler("onPlayerCommand", root, function(commandName)
        if not source or not isElement(source) or getElementType(source) ~= "player" then return end
        local ok, allowed = pcall(hasCommandRight, source, commandName)
        if not ok then
                outputDebugString("[Staff Gates] hasCommandRight ERROR on /" .. tostring(commandName)
                        .. ": " .. tostring(allowed), 1)
                return -- fail-open but LOUD (never lock the whole server out)
        end
        if allowed then return end
        cancelEvent()
        outputChatBox("You don't have permission to use this command.", source, 255, 0, 0)
end)
