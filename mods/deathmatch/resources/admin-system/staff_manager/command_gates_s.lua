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
                if type(playerHasRight) ~= "function" then return false end
                -- [Fix #160] a gate may list SEVERAL rights (shared commands
                -- like /takemoney): ANY of them grants access.
                if type(right) == "table" then
                        for _, r in ipairs(right) do
                                if playerHasRight(player, r) then return true end
                        end
                        return false
                end
                return playerHasRight(player, right)
        end
        -- no Vortex rank: the legacy ladder decides (unchanged behaviour)
        return true
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
        ["showfeedbacks"] = "admin.check", ["staffs"] = "admin.check",
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
        if allowed then return end
        cancelEvent()
        outputChatBox("You don't have permission to use this command.", source, 255, 0, 0)
end)
