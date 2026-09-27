--[[ ------------------------------------------------------------------------
        Vortex Staff System — BACKEND-FIRST command gates (Fix #19).

        The problem: /staffs lets an owner untick a right for a rank, but
        nothing enforced it. Every admin command checked only the coarse
        numeric ladder (isPlayerTrialAdmin / isPlayerSeniorAdmin ...), so a
        rank with "admin.ban" unticked could still /ban. The panel toggles
        were decoration.

        This file is THE enforcement layer. It is a shared, server-side map
        from COMMAND NAME -> RIGHT NAME. One gate (hasCommandRight) is used
        by every command handler that opts in, and it consults the rank's
        stored Rights JSON first (the same set the panel edits), falling back
        to the legacy ladder only when the player has no Vortex rank.

        Wiring: each command handler calls
            if not exports.admin_system:hasCommandRight(thePlayer, "goto") then
                outputChatBox("You don't have permission to use this command.", thePlayer, 255, 0, 0)
                return
            end
        at the top. The handler keeps its legacy check too (defense in
        depth); the right check is ADDITIVE and never grants more than the
        ladder already did — it can only RESTRICT, which is exactly what the
        panel toggles are for.

        NOTE: this resource is loaded in the admin-system Lua state, so it
        sees the globals playerHasRight / getPlayerRankRecord defined by the
        staff_manager bridge (same state, no export needed for the call
        itself; the export below is for other resources).
-------------------------------------------------------------------------- ]]

local COMMAND_RIGHTS = {
        -- teleport
        ["goto"]         = "admin.goto",
        ["sendto"]       = "admin.sendto",
        ["gethere"]      = "admin.gethere",
        ["gotoplace"]    = "admin.gotoplace",
        ["places"]       = "places.access",
        ["osendtols"]    = "admin.sendtoplace",
        -- punishment
        ["jail"]         = "admin.jail",
        ["sjail"]        = "admin.jail",
        ["ojail"]        = "admin.jail",
        ["sojail"]       = "admin.jail",
        ["unjail"]       = "admin.unjail",
        ["jailed"]       = "admin.show_jails",
        ["pban"]         = "admin.ban",
        ["sban"]         = "admin.ban",
        ["oban"]         = "admin.ban",
        ["soban"]        = "admin.ban",
        ["unban"]        = "admin.unban",
        ["unbanip"]      = "admin.unban",
        ["unbanserial"]  = "admin.unban",
        ["pkick"]        = "admin.pkick",
        ["skick"]        = "admin.pkick",
        ["warn"]         = "admin.warn",
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
        -- character / account
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
        -- economy
        ["setmoney"]     = "admin.setplayermoney",
        ["givemoney"]    = "admin.giveplayermoney",
        ["takemoney"]    = "admin.takeplayermoney",
        ["givegc"]       = "admin.giveallmoney",
        ["givegamecoins"] = "admin.giveallmoney",
        ["givegamecoin"] = "admin.giveallmoney",
        -- world / vehicles
        ["fixveh"]       = "admin.fixveh",
        ["fuelveh"]      = "admin.fuelveh",
        ["giveveh"]      = "admin.giveveh",
        ["getveh"]       = "admin.getveh",
        ["gotoveh"]      = "admin.gotoveh",
        ["destroyveh"]   = "admin.destroyveh",
        ["setvehlimit"]  = "setfactionvehlimit",
        ["setintlimit"]  = "setfactionvehlimit",
        ["setint"]       = "admin.setplayerint",
        ["setinterior"]  = "admin.setplayerint",
        ["setdim"]       = "admin.setplayerdim",
        ["setdimension"] = "admin.setplayerdim",
        -- items
        ["giveitem"]     = "giveitem",
        ["givepeditem"]  = "giveitem",
        ["makegeneric"]  = "makegeneric",
        ["makegenericitem"] = "makegeneric",
        ["cmg"]          = "makegeneric",
        ["cargomakegeneric"] = "makegeneric",
        ["takeitem"]     = "giveitem",
        ["makegun"]      = "giveitem",
        ["makeammo"]     = "giveitem",
        -- server admin
        ["setweather"]   = "admin.setweather",
        ["settime"]      = "admin.settime",
        ["setfpslimit"]  = "admin.setfpslimit",
        ["setgametype"]  = "admin.setgametype",
        ["setserverpassword"] = "admin.setserverpassword",
        ["setpos"]       = "admin.setpos",
        ["pos"]          = "admin.pos",
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
        ["adminduty"]    = "duty.adminduty",
        ["aduty"]        = "duty.adminduty",
        ["sduty"]        = "duty.adminduty",
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
        ["unblindfold"]  = "admin.eject",
        ["togmytag"]     = "admin.hide_admin",
        ["supervise"]    = "admin.recon",
        ["recon"]        = "admin.recon",
        ["stoprecon"]    = "admin.recon",
        ["freecam"]      = "admin.freecam",
        ["dropme"]       = "admin.fakeme",
        ["disappear"]    = "admin.disappear",
        ["info"]         = "admin.check",
        ["getid"]        = "owner.checkid",
        ["id"]           = "owner.checkid",
        ["charid"]       = "owner.checkid",
        ["playthenoise"] = "debug",
        ["devmode"]      = "debug",
        ["seefar"]       = "admin.disappear",
        ["911"]          = "admin.ooc",
}

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

-- ===========================================================================
-- Fix #25 (user): "تعديل صلاحيات من قسم الرتب لازم يكون حقيقي مو مجرد منظر"
-- GLOBAL enforcement gate. This file is loaded FIRST in meta.xml, so we can
-- wrap addCommandHandler once and every admin-system command (jail, ban,
-- teleport, items, economy, vehicles, character...) now consults the rank's
-- stored Rights through hasCommandRight. Unmapped commands pass untouched;
-- the server console (player == nil) always passes.
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
