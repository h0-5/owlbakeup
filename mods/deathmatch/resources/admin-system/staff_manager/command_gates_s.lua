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
        -- [user] the vehicle-library engine toggles were UNMAPPED (layer 2
        -- saw them as "no opinion" and the handlers checked nothing) - gate
        -- them like every other vehicle edit command
        ["setenginetype"] = "editvehicle",
        ["getenginetype"] = "editvehicle",
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
        ["fetchah"] = "admin.cmdlibrary.refresh",
        ["ah"] = "admin.cmdlibrary.view",
        ["fetchgh"] = "admin.gmcmdlibrary.refresh",
        ["gh"] = "admin.gmcmdlibrary.view",
        ["vehpost"] = "admin.vehtheft",
        ["aordersupplies"] = "admin.ordersupplies",
        ["checkactiveroutes"] = "trucker.manage",
        ["showactualorders"] = "trucker.manage",
        ["showalltruckmarkers"] = "trucker.manage",
        ["fetchactualorders"] = "trucker.manage",
        ["addactualorder"] = "trucker.manage",
        ["addtruckerjobmarker"] = "trucker.manage",
        ["show911"] = "admin.show911",
        ["poolsize"] = "pool.manage",
        ["cka"] = "admin.ckapprove",
        ["ckd"] = "admin.ckapprove",
        ["createemitter"] = "admin.emitter",
        ["nearbyemitters"] = "admin.emitter",
        ["delemitter"] = "admin.emitter",
        ["delemitters"] = "admin.emitter",
        ["delnearbytag"] = "admin.tagmanage",
        ["nearbytags"] = "admin.tagmanage",
        ["parkedlists"] = "admin.vehicleparking",
}

local gateHeartbeat = { fired = 0, lastCommand = "-" }

-- ===========================================================================
-- [Batch rule 5b] fix160:cmdok — the command-usage feed the admin-logs
-- resource consumes. Fires at the CENTRAL choke point whenever a GATED
-- (mapped) command is ALLOWED, carrying the command's arguments:
--   triggerEvent("fix160:cmdok", resourceRoot, player, cmdName, { args... })
-- Two layers, no double-fire:
--   layer 1 (the addCommandHandler wrapper below) fires for commands
--          registered by THIS resource and forwards the real varargs,
--   layer 2 (onPlayerCommand at the bottom) fires for every OTHER resource's
--          mapped commands with { } (typed commands carry no argument list).
-- Unmapped commands (pure player/RP commands, /hidelogs) never fire it.
-- ===========================================================================
-- [Batch rule 5b / user] the admin-logs feed follows STAFF/ADMIN actors only
-- (admin.isStaff / admin.isAdmin right) - a random player's command is not an
-- administrative log line.
local function actorIsStaffAdmin(player)
        if type(playerHasRight) ~= "function" then return false end
        local ok1, r1 = pcall(playerHasRight, player, "admin.isStaff")
        if ok1 and r1 then return true end
        local ok2, r2 = pcall(playerHasRight, player, "admin.isAdmin")
        return (ok2 and r2) and true or false
end

-- denial-coloured chat ("You don't have permission...", "...blocked..."):
-- red-dominant. A single tocolor()-packed first argument is unpacked the way
-- MTA packs it (0xRRGGBB).
local function chatColorIsDenial(r, g, b)
        if type(r) ~= "number" then return false end
        if type(g) ~= "number" or type(b) ~= "number" then
                local packed = r
                r = math.floor(packed / 65536) % 256
                g = math.floor(packed / 256) % 256
                b = packed % 256
        end
        return r >= 170 and g <= 110 and b <= 110
end

local function fireFix160CmdOk(player, cmdName, args)
        if not (isElement(player) and getElementType(player) == "player") then return end
        -- [user] only staff/admin actions belong in the admin-logs feed
        if not actorIsStaffAdmin(player) then return end
        triggerEvent("fix160:cmdok", resourceRoot, player, cmdName,
                type(args) == "table" and args or {})
end

-- [user] LAYER 2 (typed commands of OTHER resources) cannot judge the
-- outcome synchronously - those handlers may run after this gate inside the
-- same event pass. Queue the fire, watch THIS tick's chat for a denial
-- colour, then publish (or drop) on the next tick.
local cmdLogFrame = nil
local function queueCmdOk(player, key)
        local frame = cmdLogFrame
        -- the entry has to be queued BEFORE the watcher is scheduled: a
        -- setTimer(fn, 0, 1) may run before this function returns (it does on
        -- every synchronous timer implementation, and the publish loop only
        -- reads frame.pending), which would drop the command on the floor.
        if frame then
                frame.pending[#frame.pending + 1] = { player = player, key = key, args = {} }
                return
        end
        frame = { pending = { { player = player, key = key, args = {} } },
                  sawDenial = false, origOut = _G.outputChatBox }
        local origOut = frame.origOut
        _G.outputChatBox = function(text, to, r, g, b, ...)
                if chatColorIsDenial(r, g, b) then frame.sawDenial = true end
                return origOut(text, to, r, g, b, ...)
        end
        cmdLogFrame = frame
        setTimer(function()
                _G.outputChatBox = frame.origOut
                if cmdLogFrame == frame then cmdLogFrame = nil end
                -- a denial-coloured line in this tick = the handler said
                -- no (or the gate did) -> nothing to log
                if frame.sawDenial then return end
                for _, p in ipairs(frame.pending) do
                        fireFix160CmdOk(p.player, p.key, p.args)
                end
        end, 0, 1)
end

-- command names THIS resource registers (filled by the wrapper below, which
-- command_gates_s.lua installs FIRST in meta.xml - every admin-system
-- addCommandHandler call goes through it). Layer 2 uses the set to hand the
-- args-less fire to layer 1 instead of double-firing.
local adminSystemCommands = {}

-- ===========================================================================
-- Layer 1 (Fix #25): the addCommandHandler WRAPPER inside the admin-system
-- Lua VM. Every command registered by THIS resource gets the right check
-- inlined at the top of its handler. Layer 2 below covers every OTHER
-- resource through onPlayerCommand.
-- ===========================================================================
local rawAddCommandHandler = addCommandHandler

_G.addCommandHandler = function(commandName, handlerFunction, caseSensitive, restricted, ...)
        local cmdKey = tostring(commandName):lower()
        adminSystemCommands[cmdKey] = true
        local gated = function(player, cmdName, ...)
                local key = tostring(cmdKey)
                if player and isElement(player) then
                        if not hasCommandRight(player, cmdKey) then
                                outputChatBox("You don't have permission to use this command.",
                                        player, 255, 0, 0)
                                return
                        end
                        -- [Batch rule 5b / user] the gate ALLOWED a mapped
                        -- admin-system command -> run the handler, watch its
                        -- chat output and publish cmdok ONLY when it did NOT
                        -- answer with a denial colour (the gate is the choke
                        -- point, but the HANDLER knows whether the command
                        -- really ran). fireFix160CmdOk additionally binds the
                        -- line to a staff/admin actor.
                        local args = { ... }
                        local publish = COMMAND_RIGHTS[key] ~= nil
                        local sawDenial, origOut = false, _G.outputChatBox
                        if publish then
                                _G.outputChatBox = function(text, to, r, g, b, ...)
                                        if chatColorIsDenial(r, g, b) then sawDenial = true end
                                        return origOut(text, to, r, g, b, ...)
                                end
                        end
                        local results = { pcall(handlerFunction, player, cmdName, ...) }
                        if publish then _G.outputChatBox = origOut end
                        if not results[1] then
                                -- same visibility as calling the handler directly,
                                -- but a crash is never logged as a success
                                error(results[2], 0)
                        end
                        if publish and not sawDenial then
                                fireFix160CmdOk(player, key, args)
                        end
                        return (unpack or table.unpack)(results, 2)
                end
                return handlerFunction(player, cmdName, ...)
        end
        return rawAddCommandHandler(commandName, gated, caseSensitive, restricted, ...)
end

-- a gate may list SEVERAL rights (shared commands like /takemoney): ANY of
-- them grants access
local function gateAllows(player, right)
        if type(right) == "table" then
                for _, r in ipairs(right) do
                        if playerHasRight(player, r) then return true end
                end
                return false
        end
        return playerHasRight(player, right)
end

-- [Admin flight] rights authorised by the RIGHTS API (the rank's own rights
-- OR any held team's rights, plus the canFly give/revoke element data)
-- instead of by the rankPermits + team-scoping pipeline - see the check
-- inside hasCommandRight.
local FLIGHT_RIGHTS = {
        ["admin.superman"] = true,
        ["admin.freecam"]  = true,
}

-- ===========================================================================
-- [user rule #3] mapped commands that are PUBLIC player commands (they are
-- mapped only so STAFF can be gated on them). /911 keeps working for players
-- with no rank and no team - the handler owns it.
-- /ooc is NO LONGER here: the owner linked it to the admin.ooc right, so it
-- now goes through the normal mapping + right check like every other mapped
-- command (the chat handler re-checks the same right).
-- /eject stays because its handler is a mixed command: a player ejects a
-- passenger from HIS OWN vehicle, an admin ejects from any vehicle (the
-- handler still owns both halves - see ejectPlayer).
-- ===========================================================================
local PUBLIC_PLAYER_COMMANDS = {
        ["911"] = true,
        ["eject"] = true,
}

-- the exported gate. Returns true when the command is ALLOWED.
--
-- ===========================================================================
-- [Batch rule 1] COMMAND AUTHORIZATION MODEL (teams + ranks + Full Access):
--
--   allowed = rankPermits(command)
--             AND ( command has NO team requirement (commandNeedsTeam)
--                   OR viewer holds a team granting the command's right
--                   OR viewer holds the Full Access team )
--
-- with the rank-less special cases the owner spelled out:
--   * Full Access member  -> allowed, EVEN WITHOUT any admin rank,
--   * member of a normal team -> ONLY that team's commands are allowed,
--   * neither             -> a team-scoped command is DENIED (user rule #3);
--     a plain mapped command keeps the old "no opinion" behaviour (the
--     handler's own check decides), byte-identical to Fix #U4.
-- [user rule #3] PUBLIC_PLAYER_COMMANDS (911, eject) is the one
-- exception to that last line - their handlers own a PLAYER half, so this
-- layer never refuses a rank-less player on them. /ooc left that set on
-- purpose (admin.ooc now gates it).
--
-- A command is "team scoped" when SOME non-Full-Access team grants its
-- right (commandNeedsTeam in the bridge). rankPermits uses ONLY the rank's
-- own stored rights - a command the rank forbids stays forbidden even with
-- the team ("rank restrictions always win").
--
-- REPLACED: the four-domain vocabulary (rightInTeamDomain / TEAM_DOMAIN_RULES,
-- houses + vehicles + web + factions) and the rank >= 18 substitute. The
-- domain rule said "these four domains are the only team-scoped ones", which
-- both ways broke: a domain right NO team owns (property.*, web.*, makeveh...)
-- could not be won by anyone below rank 18 - only Full Access ran it - while
-- player-facing domain rights (places.access = /gate, /rbs, /nearbygates)
-- were refused to rank-less players who have always used them.
-- ===========================================================================
--
-- [Admin flight] ONE EXCEPTION to the pipeline: the rights admin.superman /
-- admin.freecam do not use it - they are authorised by the rights API
-- (playerHasRight = the rank's own rights OR any held team's rights) plus
-- the canFly element data /givesuperman sets. Some team bundles those two
-- rights (the owner's panel team does), which made the generic rule treat
-- them as "team scoped" and denied /superman and /freecam to every rank
-- below 18 that holds the right but belongs to no team - while the
-- rank-first step denied staff whose TEAM grants the flight right and whose
-- rank does not list it. See FLIGHT_RIGHTS inside hasCommandRight.
-- ===========================================================================
function hasCommandRight(player, commandName)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        local key = tostring(commandName):lower()
        local right = COMMAND_RIGHTS[key]
        -- an unmapped command is not restricted by this layer (the handler's
        -- own legacy check still applies); returning true means "no opinion".
        if not right then return true end

        -- [Admin flight] /superman and /freecam are authorised through the
        -- rights API instead of the Batch pipeline below: the flight right
        -- counts when it comes from the RANK (staff_roles rights), from any
        -- held TEAM (playerHasRight = rank OR team union) or from the canFly
        -- element data that /givesuperman grants (grant AND revoke keep
        -- working: revoking removes only the extra grant, not the rights).
        -- The pipeline could deny both kinds of holders - the team-
        -- requirement step refused ranks below 18 that hold the right but
        -- belong to no team (some team bundles admin.superman/admin.freecam,
        -- so the rights read as "team scoped"), and the rank-first step
        -- refused staff whose team grants the flight right while their rank
        -- does not list it - typed /superman and /freecam were cancelled by
        -- onPlayerCommand before the resource ever saw them, which is what
        -- made admin flight look broken. Non-staff stay locked out:
        -- playerHasRight is false for them, and the client side (canFly() in
        -- superman/c_superman.lua, toggleFreecam in freecam/c_freecam.lua)
        -- re-checks admin identity before flight actually starts.
        if type(right) == "string" and FLIGHT_RIGHTS[right] then
                if getElementData(player, "canFly") then return true end
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right)
                end
                return false -- rights API unavailable: fail closed
        end

        local rankIdx = tonumber(getElementData(player, "rank:index"))

        if not rankIdx then
                -- Full Access grants FULL permission even without any rank
                if type(playerTeamInFullAccess) == "function"
                        and playerTeamInFullAccess(player) then
                        return true
                end
                -- [Batch rule 1] a rank-less member of a NORMAL team may use
                -- THAT TEAM's commands only - he is invisible as staff
                -- (panel/TAB/badges) but his team keeps working
                if type(playerTeamHoldsNormalTeam) == "function"
                        and playerTeamHoldsNormalTeam(player) then
                        return type(playerTeamsGrantRight) == "function"
                                and playerTeamsGrantRight(player, right) or false
                end
                -- [Fix #U4] no live rank on the player: this branch used to blanket
                -- ALLOW, which made every revocation a no-op for staff whose
                -- staff_role_members row is missing while the accounts columns still
                -- say they are staff (admin_level > 0) - the handler's own legacy
                -- check then let every command through.
                -- Ask the rights API when the player looks like staff at all; keep the
                -- old allow ONLY when there is genuinely nothing to check against (no
                -- rank record and no live rights set), so a renamed/absent rank can
                -- never lock a legacy admin out of a mapped command. Players with no
                -- staff level at all keep the old path - and cost - untouched.
                if type(playerHasRight) == "function" then
                        local live = getElementData(player, "rank:rights")
                        local hasLive = type(live) == "string" and live ~= ""
                        local looksStaff = (tonumber(getElementData(player, "admin_level")) or 0) > 0
                                or (tonumber(getElementData(player, "supporter_level")) or 0) > 0
                                or (tonumber(getElementData(player, "scripter_level")) or 0) > 0
                        if hasLive then
                                return gateAllows(player, right)
                        end
                        if looksStaff and type(getPlayerRankRecord) == "function"
                                and getPlayerRankRecord(player) then
                                return gateAllows(player, right)
                        end
                end
                -- [user rule #3] no Vortex rank and no team: a mapped command
                -- SOME team grants (or that belongs to the four team domains)
                -- is staff territory - a plain player may not run it. Public
                -- player commands (911 / eject) stay open for everyone, a
                -- plain mapped command that is neither - /ooc included - still
                -- falls back to the legacy "no opinion" behaviour (the
                -- handler's own right check decides).
                if PUBLIC_PLAYER_COMMANDS[key] then return true end
                if type(commandNeedsTeam) == "function" and commandNeedsTeam(right) then
                        return false
                end
                -- no Vortex rank: the legacy ladder decides (unchanged behaviour)
                return true
        end

        -- ranked player ------------------------------------------------------
        -- 1) the rank's OWN stored rights decide FIRST (a command the rank
        --    forbids is denied no matter which team he holds)
        if type(staffRankPermits) ~= "function" then
                -- bridge not loaded (defensive): keep the old union check
                if type(playerHasRight) ~= "function" then return false end
                return gateAllows(player, right)
        end
        if not staffRankPermits(player, right) then return false end
        -- 2) the TEAM half: only a command SOME team on the server claims is
        --    team scoped (commandNeedsTeam in the bridge). A command no team
        --    grants is decided by the rank's own rights alone - which is why
        --    the old four-domain vocabulary and the rank>=18 substitute are
        --    both gone (a domain right no team owns used to be unwinnable
        --    below rank 18, and only Full Access could still run it).
        if type(commandNeedsTeam) ~= "function" then return true end
        if not commandNeedsTeam(right) then return true end
        -- 3) Full Access is exempt from the team requirement...
        if type(playerTeamInFullAccess) == "function"
                and playerTeamInFullAccess(player) then
                return true
        end
        -- 4) ...or he simply holds a team that grants the command's right
        if type(playerTeamsGrantRight) == "function"
                and playerTeamsGrantRight(player, right) then
                return true
        end
        return false
end

-- table lookup for the panel / debugging: which right gates this command
function getCommandRight(commandName)
        local right = COMMAND_RIGHTS[tostring(commandName):lower()]
        if type(right) == "table" then
                return table.concat(right, " | ")
        end
        return right or false
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
                outputChatBox("/" .. cmd .. " -> right \"" .. getCommandRight(cmd) .. "\"", player, 120, 200, 255)
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
-- [Fix #41] FULL-SERVER COVERAGE — the map above was built in rounds and left
-- whole admin families (vehicle-manager info/setters, shops, elevators, fuel,
-- gates, roadblocks, speedcams, weather, reports, resource tools...) unmapped,
-- and unmapped = allowed. The user's report: "the problem is with ALL server
-- commands". The block below was generated from a full repo scan (1042
-- distinct commands, scripts/scan_commands_fix41.py): EVERY command with
-- admin power is now mapped to a right that exists in AllRights, so the
-- staff panel can close it for any rank. Pure player/RP commands stay
-- unmapped on purpose (chat, animations, phone, jobs, realism...).
-- ===========================================================================

local GATES_V4_EXTENSION = {
        ------------------------------------------------ admin-system self ----
        ["atp"] = "admin.goto", ["dtp"] = "admin.goto",
        ["x"] = "admin.setpos", ["y"] = "admin.setpos", ["z"] = "admin.setpos",
        ["setx"] = "admin.setpos", ["sety"] = "admin.setpos", ["setz"] = "admin.setpos",
        ["setxy"] = "admin.setpos", ["setxz"] = "admin.setpos", ["setyz"] = "admin.setpos", ["setxyz"] = "admin.setpos",
        ["fetchnews"] = "admin.getsettings",
        ["showfeedbacks"] = "admin.check",
                -- [user rule #4] /staffs OPENS the staff panel and nothing else, so it
                -- is gated by admin.manager.panel - the right that means exactly "may
                -- see the panel". It used to borrow admin.check, which made a rank
                -- that may inspect players unable to open the panel and an
                -- admin.check holder able to open it without the panel right.
                ["staffs"] = "admin.manager.panel",
        ["gunchart"] = "weapons.search", ["gunids"] = "weapons.search",
        ["gunlist"] = "weapons.search", ["weaponchart"] = "weapons.search",
        ["cleardebugscript"] = "debug",
        ------------------------------------------------------ account ----
        ["loginto"] = "admin.playas",
        ["applications"] = "web.applications", ["apps"] = "web.applications",
        ["changeaccountpassword"] = "accounts.changepass", ["setaccountpassword"] = "accounts.changepass",
        ["fixmigration"] = "dev.fullstatus",
        ["updateadminrules"] = "web.rules", ["updategmrules"] = "web.rules",
        ["updatenews"] = "web.rules", ["updatepatchnotes"] = "web.rules", ["updaterules"] = "web.rules",
        ------------------------------------------------------ weather ----
        ["setfw"] = "admin.setweather", ["resetfw"] = "admin.setweather",
        ["setsnowlevel"] = "admin.setrain",
        ["sw"] = "admin.setweather", ["swb"] = "admin.setweather", ["swh"] = "admin.setweather",
        ["swl"] = "admin.setweather", ["swr"] = "admin.setweather", ["swv"] = "admin.setweather",
        ["sf"] = "admin.setweather", ["srl"] = "admin.setweather", ["shh"] = "admin.setweather",
        -- [Fix #160] /st is registered TWICE: weather-system (set time, guarded
        -- internally by isPlayerAdmin) and chat-system (staff chat). It used to
        -- be gated to admin.setweather, which left admin.staffchat /st dead.
        ["st"] = "admin.staffchat /st",
        ["setgametime"] = "admin.settime",
        ------------------------------------------------- vehicle-manager ----
        ["flip"] = "admin.flip", ["unflip"] = "admin.unflip",
        ["nearbyvehicles"] = "admin.checkveh", ["nearbyvehs"] = "admin.checkveh",
        ["veh"] = "admin.checkveh", ["vehicles"] = "admin.checkveh", ["vehs"] = "admin.checkveh", ["thiscar"] = "admin.checkveh",
        ["reloadveh"] = "admin.restartres", ["reloadvehicle"] = "admin.restartres",
        ["removeveh"] = "admin.destroyveh", ["removevehicle"] = "admin.destroyveh",
        ["restoreveh"] = "vehicle.restore_destroyed", ["restorevehicle"] = "vehicle.restore_destroyed", ["oldcar"] = "vehicle.restore_destroyed",
        ["respawnint"] = "vehicle.respawnallveh", ["respawnstop"] = "vehicle.respawnallveh",
        ["sll"] = "editvehicle", ["sdt"] = "editvehicle", ["resetdt"] = "editvehicle", ["resetsll"] = "editvehicle",
        ["sbp"] = "editvehicle", ["sdp"] = "editvehicle",
        ["togplate"] = "editvehicle", ["togreg"] = "editvehicle", ["togvin"] = "editvehicle", ["spinout"] = "editvehicle",
        ["gdt"] = "admin.checkveh", ["getdt"] = "admin.checkveh", ["getsdt"] = "admin.checkveh",
        ["getsll"] = "admin.checkveh", ["gsll"] = "admin.checkveh",
        ["getcolor"] = "admin.checkveh", ["getvehweight"] = "admin.checkveh",
        ------------------------------------------------- vehicle-system ----
        ["makecivveh"] = "makeveh",
        ["apark"] = "vehicle.park", ["fpark"] = "vehicle.park", ["toggleautopark"] = "vehicle.park",
        ["avehpos"] = "admin.pos", ["fvehpos"] = "admin.pos", ["vehpos"] = "admin.pos",
        ["settraindirection"] = "editvehicle", ["settrainrailed"] = "editvehicle",
        ["tempsell"] = "property.setowner",
        --------------------------------------------------------- shops ----
        ["makeshop"] = "shops.manager", ["delshop"] = "shops.manager", ["deleteshop"] = "shops.manager",
        ["delnearbyshops"] = "shops.manager", ["delnearbynpcs"] = "shops.manager",
        ["movenpc"] = "shops.manager", ["moveshop"] = "shops.manager",
        ["reloadnpc"] = "shops.manager", ["reloadped"] = "shops.manager", ["reloadshop"] = "shops.manager",
        ["removenpc"] = "shops.manager", ["removeped"] = "shops.manager", ["removeshop"] = "shops.manager",
        ["renamenpc"] = "shops.manager", ["renameped"] = "shops.manager", ["renameshop"] = "shops.setname",
        ["resetshopwage"] = "shops.manager", ["restorenpc"] = "shops.manager", ["restoreped"] = "shops.manager",
        ["restoreshop"] = "shops.manager", ["saveshopconfigs"] = "shops.manager",
        ["showallcustomshops"] = "shops.list", ["forceupdateshopwage"] = "shops.manager", ["checksupplies"] = "shops.manager",
        ----------------------------------------------------- interiors ----
        ["forcepickupspawn"] = "addint", ["movesafe"] = "addint",
        ["nearbyinteriors"] = "admin.checkint", ["nearbyints"] = "admin.checkint",
        ["setcamint"] = "addint", ["setfee"] = "setintprice",
        ["debugme"] = "debug", ["stopfakerot"] = "debug", ["getloaded"] = "debug",
        ---------------------------------------------------- elevators ----
        ["adde"] = "elevator.addelev", ["adde2"] = "elevator.addelev",
        ["addelevator"] = "elevator.addelev", ["addlift"] = "elevator.addelev",
        ["dele"] = "elevator.delelev", ["delefromint"] = "elevator.delelev",
        ["delelevator"] = "elevator.delelev", ["delelevatorsfrominterior"] = "elevator.delelev",
        ["dellift"] = "elevator.delelev", ["delnearbye"] = "elevator.delelev", ["delnearbyelevators"] = "elevator.delelev",
        ["fixnearbye"] = "elevator.addelev", ["fixnearbyelevators"] = "elevator.addelev",
        ["togglee"] = "elevator.lock", ["toggleelevator"] = "elevator.lock", ["togglelift"] = "elevator.lock",
        ["nearbye"] = "admin.checkint", ["nearbyelevators"] = "admin.checkint", ["nearbylifts"] = "admin.checkint",
        -------------------------------------------------------- fuel ----
        ["makefuel"] = "intlib.add", ["makefuelnpc"] = "intlib.add", ["makefuelped"] = "intlib.add",
        ["setfuel"] = "intlib.add", ["setfuelpedlink"] = "intlib.add", ["fuelped"] = "intlib.add",
        ["delfuel"] = "intlib.remove", ["deletefuel"] = "intlib.remove",
        ["delfuelped"] = "intlib.remove", ["deletefuelped"] = "intlib.remove",
        ["gotofuel"] = "admin.gotoplace", ["gotofuelnpc"] = "admin.gotoplace", ["gotofuelped"] = "admin.gotoplace",
        ["nearbyfuels"] = "admin.checkint", ["nearbynpcs"] = "admin.checkint",
        ------------------------------------------- gates / roadblocks / cams ----
        ["newgate"] = "places.add", ["delgate"] = "places.remove",
        ["gate"] = "places.access", ["gates"] = "places.access", ["nearbygates"] = "places.access",
        ["gotogate"] = "admin.gotoplace",
        ["delallrbs"] = "editor.removeRBS", ["delallroadblocks"] = "editor.removeRBS",
        ["delrb"] = "editor.removeRBS", ["delroadblock"] = "editor.removeRBS",
        ["rbs"] = "places.access", ["nearbyrb"] = "places.access", ["nearbyrbs"] = "places.access",
        ["aremovespikes"] = "editor.removeRBS",
        ["addspeedcam"] = "places.add", ["delspeedcam"] = "places.remove",
        ["nearbyspeedcams"] = "places.access", ["setradius"] = "places.add", ["togglespeedcam"] = "places.access",
        ----------------------------------------------------------- tow ----
        ["addlane"] = "places.add", ["fixlanes"] = "places.add", ["resettowbackup"] = "places.add",
        ["aunimpound"] = "vehicle.unhide", ["impoundbike"] = "vehicle.hide",
        ["unimp"] = "vehicle.unhide", ["unimpound"] = "vehicle.unhide",
        -------------------------------------------------------- payday ----
        ["forcepayday"] = "admin.forcepayday", ["forcepaydayall"] = "admin.forcepayday",
        --------------------------------------------------------- bank ----
        ["addatm"] = "intlib.add", ["delatm"] = "intlib.remove",
        ["nearbyatms"] = "bank.showaccounts", ["iamtester"] = "debug",
        ------------------------------------------- icons / dancers / peds ----
        ["addii"] = "blip.make", ["delii"] = "blip.remove", ["nearbyii"] = "places.access",
        ["adddancer"] = "intlib.add", ["deldancer"] = "intlib.remove",
        ["nearbydancers"] = "admin.checkint", ["updatedancers"] = "intlib.add",
        ["makeped"] = "editor.editObjects", ["ped"] = "editor.editObjects",
        ------------------------------------------------------- reports ----
        ["acceptreport"] = "access.reports", ["ar"] = "access.reports", ["ara"] = "access.reports",
        ["closeallreports"] = "access.reports", ["closereport"] = "access.reports",
        ["cr"] = "access.reports", ["dr"] = "access.reports", ["dropreport"] = "access.reports",
        ["endreport"] = "access.reports", ["er"] = "access.reports", ["falsereport"] = "access.reports",
        ["fr"] = "access.reports", ["getsavedreports"] = "access.reports", ["reportinfo"] = "access.reports",
        ["reportlazyfix"] = "access.reports", ["ri"] = "access.reports", ["setsavedreports"] = "access.reports",
        ["showadminreports"] = "access.reports", ["togautocheck"] = "access.reports",
        ["toggleautocheck"] = "access.reports", ["tr"] = "access.reports",
        ["transferreport"] = "access.reports", ["ur"] = "access.reports", ["changereport"] = "access.reports",
        ["reports"] = "access.reports", ["cp"] = "access.reports", ["cks"] = "access.reports",
        ---------------------------------------------------- mdc / misc ----
        ["giveziadadmin"] = "owner.giverole", ["refreshpilotlicenses"] = "givelicense",
        ["dbrun"] = "debug",
        ["debugres"] = "admin.restartres", ["debugresource"] = "admin.restartres",
        ["countobjects"] = "dev.fullstatus", ["getresourcestate"] = "dev.fullstatus",
        ["debugfakevideo"] = "debug", ["setdxtestmode"] = "debug", ["debugitemtexture"] = "debug",
        ["debugmodeloutput"] = "debug",
        ["rcs"] = "admin.resstate", ["rescheck"] = "admin.resstate",
        ["resrestart"] = "admin.restartres", ["resstart"] = "admin.startres",
        ["saveall"] = "dev.fullstatus",
        ["ipb"] = "dev.fullstatus", ["perfbrowse"] = "dev.fullstatus",
        ["electionvotes"] = "admin.check", ["astats"] = "admin.check",
        ["setdrunklevel"] = "admin.check", ["resetdrunk"] = "admin.check",
        ---------------------------------------------------- faction ----
        ["setfaction"] = "setfaction", ["setbudget"] = "faction.setmoney",
        ["settax"] = "faction.edit", ["setincometax"] = "faction.edit", ["setwelfare"] = "faction.edit",
        ------------------------------------------ interior-manager / misc ----
        ["checkint"] = "admin.checkint", ["checkinterior"] = "admin.checkint",
        ["restock"] = "shops.manager",
        ["setintfaction"] = "property.setowner", ["setinttomyfaction"] = "property.setowner",
        ------------------------------------------------------ LSFD / PD ----
        ["randomfire"] = "admin.makefire", ["cancelfire"] = "admin.removefire",
        ------------------------------------------------- events / freecam ----
        ["aaddclubpoi"] = "editor.editObjects", ["aclubrotstyle"] = "editor.editObjects",
        ["adelclubrot"] = "editor.editObjects", ["aloadclubrot"] = "editor.editObjects",
        ["astartclubrot"] = "editor.editObjects", ["astopclubrot"] = "editor.editObjects",
        ["starttv"] = "admin.freecam", ["endtv"] = "admin.freecam",
        ["movetv"] = "admin.freecam", ["watchers"] = "admin.freecam", ["tv"] = "admin.freecam",
        ----------------------------------------------------- scoreboard ----
        ["checkid"] = "owner.checkid", ["changeid"] = "admin.check",
        ----------------------------------------------------- clothing ----
        ["gskin"] = "admin.skin", ["getskin"] = "admin.skin",
        -------------------------------------------------- paynspray/toll ----
        ["makepaynspray"] = "intlib.add", ["delpaynspray"] = "intlib.remove",
        ["tolllock"] = "interior.lock",
        -------------------------------------------------- chat staff tools ----
        ["bigears"] = "admin.recon", ["bigearsf"] = "admin.recon", ["showdata"] = "admin.check",
        ["issuebadge"] = "admin.badge",
        ["superman"] = "admin.superman",
        ["forcesetwalk"] = "admin.check", ["forcesetwalkingstyle"] = "admin.check", ["fsetwalkingstyle"] = "admin.check",
        -------------------------------------------------- announcements ----
        ["opm"] = "admin.ann", ["setserverip"] = "admin.setsettings",
        ["guied"] = "editor.editObjects", ["hws"] = "editor.editObjects", ["redo"] = "editor.editObjects", ["undo"] = "editor.editObjects",
        ["deltestinterior"] = "editor.editObjects", ["savetestinterior"] = "editor.editObjects",
        ["processcustominterior"] = "editor.editObjects", ["testinterior"] = "editor.editObjects",
        ["reposclock"] = "debug",
        ------------------------------------------------- phone moderation ----
        ["delad"] = "admin.ann", ["deletead"] = "admin.ann",
        ["freezead"] = "admin.ann", ["unfreezead"] = "admin.ann",
}

for cmd, right in pairs(GATES_V4_EXTENSION) do
        if COMMAND_RIGHTS[cmd] == nil then
                COMMAND_RIGHTS[cmd] = right
        end
end
GATES_VERSION = 4

-- ===========================================================================
-- [Fix #157] RIGHTS THAT HAD NO COMMAND BEHIND THEM. The panel listed these
-- rights (and the seed granted them), but nothing anywhere in the server
-- registered a handler for them, so ticking/unticking changed nothing. The
-- matching handlers now live at the end of staff_manager_s.lua; this map is
-- what makes the tick actually enforce them.
--   NOTE: the setid -> changeid rename above is the owner's exact call
--   (admin.check, NOT accounts.changeid) - reported, not second-guessed.
-- ===========================================================================
local GATES_FIX157 = {
        ----------------------------------------------------- accounts ----
        ["changepass"]        = "accounts.changepass",
        ["changeemail"]       = "accounts.changeemail",
        ["changeserial"]      = "accounts.changeserial",
        ["changeaccountname"] = "accounts.changeaccountname",
        --------------------------------------------------------- owner ----
        ["checkserial"]       = "owner.checkserial",
        ["checkaccount"]      = "owner.checkaccount",
        ["checkemail"]        = "owner.checkemail",
        ["setactivestatus"]   = "owner.setactivestatus",
        ["changemode"]        = "owner.changemode",
        ["giverole"]          = "owner.giverole",
        ["takerole"]          = "owner.takerole",
        ["setroleid"]         = "owner.setroleid",
        -------------------------------------------- read-only helpers ----
        ["showbans"]          = "admin.showbans",
        ["showsettings"]      = "admin.showsettings",
        ["getaccount"]        = "admin.getaccount",
        -------------------------------- chat rights the gate ignored ----
        -- chat-system owns the handlers (/a, /g); before this they were
        -- unmapped = "no opinion" = the panel tick did nothing for them
        ["a"]                 = "admin.chat /a",
        ["g"]                 = "support.chat /g",
}

for cmd, right in pairs(GATES_FIX157) do
        if COMMAND_RIGHTS[cmd] == nil then
                COMMAND_RIGHTS[cmd] = right
        end
end

-- ===========================================================================
-- [Fix #160] EXTENSION POINT. Per-task gate tables live in their own files
-- (staff_manager/gates_fix160_taskN.lua, registered below this script in
-- meta.xml) so parallel work never edits this shared map.
--   * first-wins on a single right: an entry already mapped here is never
--     overridden by a task stub.
--   * a task may pass a LIST of rights for a shared command; the list is
--     merged (dedup) with an existing mapping, and hasCommandRight grants
--     access when the player holds ANY right in the list.
-- ===========================================================================
function staffRegisterGates(tbl)
        if type(tbl) ~= "table" then return end
        local added = 0
        for cmdKey, right in pairs(tbl) do
                local cmd = tostring(cmdKey):lower()
                local wanted = {}
                if type(right) == "string" then
                        if right ~= "" then wanted[1] = right end
                elseif type(right) == "table" then
                        for _, r in ipairs(right) do
                                if type(r) == "string" and r ~= "" then wanted[#wanted + 1] = r end
                        end
                end
                if #wanted > 0 then
                        local existing = COMMAND_RIGHTS[cmd]
                        if existing == nil then
                                COMMAND_RIGHTS[cmd] = (#wanted == 1) and wanted[1] or wanted
                                added = added + #wanted
                        elseif type(right) == "table" then
                                -- merge mode: shared command, union of rights
                                local set = {}
                                if type(existing) == "table" then
                                        for _, r in ipairs(existing) do set[#set + 1] = r end
                                else
                                        set[1] = existing
                                end
                                local seen = {}
                                for _, r in ipairs(set) do seen[r] = true end
                                local grew = false
                                for _, r in ipairs(wanted) do
                                        if not seen[r] then set[#set + 1] = r; seen[r] = true; grew = true end
                                end
                                if grew then
                                        COMMAND_RIGHTS[cmd] = set
                                        added = added + 1
                                end
                        end
                        -- string value for an already-mapped command: first-wins
                end
        end
        if added > 0 then
                outputDebugString("[Staff Gates] Fix #160: +" .. added .. " gate right(s) registered, total "
                        .. countMap(COMMAND_RIGHTS))
        end
end

-- resources whose commands are admin tools by nature; /staffscan flags any
-- command they register that the map above still does not cover
local ADMIN_RESOURCES = {
        ["admin-system"] = true, ["account"] = true, ["vehicle-manager"] = true,
        ["vehicle-system"] = true, ["shop-system"] = true, ["interior-system"] = true,
        ["interior-manager"] = true, ["elevator-system"] = true, ["fuel-system"] = true,
        ["gate-manager"] = true, ["roadblock-system"] = true, ["camera-system"] = true,
        ["weather-system"] = true, ["realtime-system"] = true, ["faction-system"] = true,
        ["report-system"] = true, ["mdc-system"] = true, ["resource-keeper"] = true,
        ["payday"] = true, ["bank"] = true, ["event-system"] = true, ["freecam-tv"] = true,
        ["tow-system"] = true, ["paynspray-system"] = true, ["informationicon-system"] = true,
        ["dancer-system"] = true, ["ped-system"] = true, ["toll"] = true, ["LSFD"] = true,
        ["job-system-trucker"] = true, ["debug"] = true, ["dbrun"] = true, ["dev"] = true,
}

local function staffScanCommand(player)
        outputChatBox("========== STAFF SCAN (gate v" .. GATES_VERSION .. ") ==========", player, 60, 200, 120)
        local handlers = getCommandHandlers and getCommandHandlers() or {}
        local total, suspects = 0, {}
        for _, entry in ipairs(handlers) do
                local cmd, res = tostring(entry[1] or entry.command or ""), tostring(entry[2] or entry.resource or "")
                total = total + 1
                if ADMIN_RESOURCES[res] and not COMMAND_RIGHTS[cmd:lower()] then
                        table.insert(suspects, "/" .. cmd .. " (" .. res .. ")")
                end
        end
        outputChatBox("registered commands: " .. total .. " | gated: " .. countMap(COMMAND_RIGHTS)
                .. " | UNMAPPED admin-resource commands: " .. #suspects, player, 220, 220, 220)
        if #suspects == 0 then
                outputChatBox("full coverage - every admin-resource command is gated.", player, 80, 255, 120)
        else
                outputChatBox("suspects (need mapping):", player, 255, 170, 60)
                for i = 1, math.min(#suspects, 40) do
                        outputChatBox("  " .. suspects[i], player, 255, 170, 60)
                end
                if #suspects > 40 then
                        outputChatBox("  ... and " .. (#suspects - 40) .. " more", player, 255, 170, 60)
                end
        end
end
rawAddCommandHandler("staffscan", staffScanCommand, false, false)


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
        if not allowed then
                cancelEvent()
                outputChatBox("You don't have permission to use this command.", source, 255, 0, 0)
                return
        end
        -- [Batch rule 5b] the command is ALLOWED: publish it for the
        -- admin-logs feed - but ONLY when layer 1 will not fire it (layer 1
        -- forwards the real arguments for every command THIS resource
        -- registers) and only for a MAPPED command. Typed commands carry no
        -- argument list here, so this fire always ships { }.
        local key = tostring(commandName):lower()
        if COMMAND_RIGHTS[key] and not adminSystemCommands[key] then
                -- [user] layered fire: the other resource's handler answers
                -- DURING this event pass (possibly after this gate ran), so the
                -- decision - and the staff/admin binding - happen on the next
                -- tick inside queueCmdOk
                queueCmdOk(source, key)
        end
end)
