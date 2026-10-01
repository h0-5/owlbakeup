--[[ [Fix #160] s_faction_fix160.lua - faction staff commands + FACTION BLACKLIST (agent A3)

        Rights that had NO handler anywhere now have one (the gate list lives in
        admin-system/staff_manager/gates_fix160_task3.lua):

          setfactionname         /setfactionname     (same rename /renamefaction does)
          setfactiontype         /setfactiontype     (factions.type 0..11)
          setfactionradio        /setfactionradio    (factions.radio, gate existed, handler did not)
          faction.givepoints     /givefactionpoints
          factions.check         /checkfaction       (plus the /check union in the gate)
          faction.checkinvoices  /checkinvoices      (pd_tickets issued by that faction)
          faction.clearinvoices  /clearinvoices
          factions.clearlogs     /clearfactionlogs   (owl_logs + factionlogs)
          faction.forcewage      /forcefactionwage   (pay the online members right now)
          faction.resetranks     /resetfactionranks  (rank names + wages back to defaults)
          factions.blacklist.*   /showfbl /addfbl /removefbl (NEW factions_blacklist table)

        /takemoney, /givemoney and /check are shared with admin-system: those rights
        are UNION-gated onto the existing handlers, no handler is duplicated here.

        Permission model (the same two layers as Fix #148 / Fix #157):
          1. staff_manager onPlayerCommand cancels the typed command for a Vortex
             rank that does not hold the right (gates_fix160_task3.lua);
          2. fix160Check() below: for a ranked staff the stored right is the ONLY
             truth, for everyone else the legacy integration ladder decides.

        The blacklist is enforced SERVER-SIDE in s_faction_system.lua
        callbackInvitePlayer (the F3 "+ add member" accept point): a blacklisted
        character is refused even when the leader is the one adding them.
]]

local mysql = exports.mysql

local FACTION_TYPES = {
        [0] = "Gang", [1] = "Mafia", [2] = "Law", [3] = "Government",
        [4] = "Medical", [5] = "Other", [6] = "News", [7] = "Mechanic",
        [8] = "Electric", [9] = "Traffic", [10] = "Business", [11] = "Family",
}

-- [Fix #160] right check: rank rights are the ONLY truth for ranked staff, the
-- legacy integration ladder decides for a player without a Vortex rank (the gate
-- deliberately returns "no opinion" there).
local function fix160HasRight(player, command)
        if not isElement(player) or getElementType(player) ~= "player" then
                return false
        end
        if getElementData(player, "rank:index") then
                local ok, allowed = pcall(function()
                        return exports["admin-system"]:hasCommandRight(player, command)
                end)
                if ok then
                        return allowed and true or false
                end
                outputDebugString("[Fix #160] hasCommandRight failed for /" .. tostring(command), 2)
        end
        return exports.integration:isPlayerAdmin(player) and true or false
end

local function fix160Check(player, command)
        if fix160HasRight(player, command) then
                return true
        end
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return false
end

local function fix160Syntax(player, command, args)
        outputChatBox("SYNTAX: /" .. tostring(command) .. " " .. tostring(args), player, 255, 194, 14)
end

-- [Fix #160] faction lookup by id: nil when the id is bogus or the team is gone
local function fix160GetTeam(factionID, thePlayer)
        factionID = tonumber(factionID)
        if not factionID or factionID <= 0 then
                if thePlayer then outputChatBox("Invalid Faction ID.", thePlayer, 255, 0, 0) end
                return nil, nil
        end
        local theTeam = exports.pool:getElement("team", factionID)
        if not theTeam then
                if thePlayer then outputChatBox("Invalid Faction ID.", thePlayer, 255, 0, 0) end
                return nil, nil
        end
        return theTeam, factionID
end

-- [Fix #160] COUNT(*) that never throws: a missing table (factionlogs is part of
-- database/10_factions_bank_staff.sql and may not be imported yet) counts as 0.
local function fix160SafeCount(sql)
        local ok, count = pcall(function()
                local row = mysql:query_fetch_assoc(sql)
                return tonumber(row and row.n) or 0
        end)
        if ok and type(count) == "number" then
                return count
        end
        return 0
end

-- ===========================================================================
-- [Fix #160] FACTION BLACKLIST storage. One row per blocked character per
-- faction. The CREATE is idempotent, runs at resource start and retries before
-- the first command, so a dropped table heals itself.
-- ===========================================================================

local blacklistReady = false

local function ensureFactionBlacklist()
        if blacklistReady then
                return true
        end
        local ok, created = pcall(function()
                return mysql:query_free([[CREATE TABLE IF NOT EXISTS factions_blacklist (
                        id INT NOT NULL AUTO_INCREMENT,
                        factionid INT NOT NULL,
                        characterid INT NOT NULL DEFAULT 0,
                        charactername VARCHAR(64) NOT NULL DEFAULT '',
                        reason VARCHAR(255) NOT NULL DEFAULT '',
                        addedby VARCHAR(64) NOT NULL DEFAULT '',
                        date DATETIME DEFAULT NULL,
                        PRIMARY KEY (id),
                        KEY factionid (factionid)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        end)
        blacklistReady = ok and created and true or false
        if not blacklistReady then
                outputDebugString("[Fix #160] could not create the factions_blacklist table", 2)
        end
        return blacklistReady
end

addEventHandler("onResourceStart", resourceRoot, function()
        ensureFactionBlacklist()
end)

-- [Fix #160] the blocking row (or nil) for a character inside one faction; the
-- lookup matches the character id first and falls back to the stored name.
local function getFactionBlacklistHit(factionID, characterID, characterName)
        factionID = tonumber(factionID)
        if not factionID or factionID < 1 then
                return nil
        end
        if not ensureFactionBlacklist() then
                return nil
        end
        local parts = {}
        if tonumber(characterID) then
                parts[#parts + 1] = "characterid='" .. mysql:escape_string(tonumber(characterID)) .. "'"
        end
        if characterName and characterName ~= "" then
                parts[#parts + 1] = "charactername='" .. mysql:escape_string(tostring(characterName)) .. "'"
        end
        if #parts == 0 then
                return nil
        end
        local result = mysql:query("SELECT id, reason FROM factions_blacklist WHERE factionid='"
                .. mysql:escape_string(factionID) .. "' AND (" .. table.concat(parts, " OR ") .. ") LIMIT 1")
        if not result then
                return nil
        end
        local row = mysql:fetch_assoc(result)
        mysql:free_result(result)
        if not row then
                return nil
        end
        return row
end

-- [Fix #160] server accept point helper, called by callbackInvitePlayer in
-- s_faction_system.lua: returns the blocking row (truthy) or nil.
function getFactionBlacklistHitForPlayer(factionID, playerElement)
        if not isElement(playerElement) then
                return nil
        end
        local characterID = getElementData(playerElement, "dbid") or getElementData(playerElement, "account:character:id")
        return getFactionBlacklistHit(factionID, characterID, getPlayerName(playerElement))
end

-- ===========================================================================
-- [Fix #160] factions.blacklist.show - /showfbl [Faction ID]
-- ===========================================================================

function showFactionBlacklist(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "showfbl") then return end
        if not ensureFactionBlacklist() then
                outputChatBox("The factions_blacklist table is not available.", thePlayer, 255, 0, 0)
                return
        end
        factionID = tonumber(factionID)
        local where = ""
        if factionID and factionID > 0 then
                where = " WHERE factionid='" .. mysql:escape_string(factionID) .. "'"
        else
                factionID = nil
        end
        local result = mysql:query("SELECT id, factionid, characterid, charactername, reason, addedby, date FROM factions_blacklist"
                .. where .. " ORDER BY id DESC LIMIT 30")
        if not result then
                outputChatBox("Could not read the faction blacklist.", thePlayer, 255, 0, 0)
                return
        end
        outputChatBox("========== FACTION BLACKLIST" .. (factionID and " - faction #" .. factionID or " (all factions)") .. " ==========",
                thePlayer, 60, 200, 120)
        local count = 0
        while true do
                local row = mysql:fetch_assoc(result)
                if not row then break end
                count = count + 1
                outputChatBox("#" .. tostring(row.id) .. " [f" .. tostring(row.factionid) .. "] "
                        .. tostring(tostring(row.charactername):gsub("_", " ")) .. " (char #" .. tostring(row.characterid) .. ") - "
                        .. tostring(row.reason) .. " | by " .. tostring(row.addedby) .. " | " .. tostring(row.date),
                        thePlayer, 220, 220, 220)
        end
        mysql:free_result(result)
        if count == 0 then
                outputChatBox("No blacklist entries found.", thePlayer, 255, 170, 60)
        end
end

addCommandHandler("showfbl", showFactionBlacklist, false, false)

-- ===========================================================================
-- [Fix #160] factions.blacklist.add - /addfbl [Faction ID] [Character Name] [Reason]
-- ===========================================================================

function addFactionBlacklist(thePlayer, commandName, factionID, characterName, ...)
        if not fix160Check(thePlayer, "addfbl") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end
        if not characterName or characterName == "" then
                fix160Syntax(thePlayer, commandName, "[Faction ID] [Character Name (use _)] [Reason]")
                return
        end
        if not ensureFactionBlacklist() then
                outputChatBox("The factions_blacklist table is not available.", thePlayer, 255, 0, 0)
                return
        end

        -- [Fix #160] resolve the character: online element first, then the
        -- characters table, so a member can be blocked before he ever joins.
        local characterID, resolvedName
        local online = getPlayerFromName(characterName)
        if online then
                characterID = getElementData(online, "dbid") or getElementData(online, "account:character:id")
                resolvedName = getPlayerName(online)
        else
                local row = mysql:query_fetch_assoc("SELECT id, charactername FROM characters WHERE charactername='"
                        .. mysql:escape_string(characterName) .. "' LIMIT 1")
                if not row or not tonumber(row.id) then
                        outputChatBox("Character '" .. characterName .. "' was not found.", thePlayer, 255, 0, 0)
                        return
                end
                characterID = tonumber(row.id)
                resolvedName = row.charactername
        end
        if not tonumber(characterID) then
                outputChatBox("Character data is not available yet, try again.", thePlayer, 255, 0, 0)
                return
        end

        if getFactionBlacklistHit(fid, characterID, resolvedName) then
                outputChatBox("That character is already blacklisted for this faction.", thePlayer, 255, 0, 0)
                return
        end

        local reasonArgs = { ... }
        local reason = #reasonArgs > 0 and table.concat(reasonArgs, " ") or "No reason given"
        local addedBy = getPlayerName(thePlayer)

        if mysql:query_free("INSERT INTO factions_blacklist (factionid, characterid, charactername, reason, addedby, date) VALUES ('"
                .. mysql:escape_string(fid) .. "', '" .. mysql:escape_string(tonumber(characterID)) .. "', '"
                .. mysql:escape_string(tostring(resolvedName)) .. "', '" .. mysql:escape_string(reason) .. "', '"
                .. mysql:escape_string(addedBy) .. "', NOW())") then
                local entryID = mysql:insert_id()
                outputChatBox("Blacklisted " .. tostring(tostring(resolvedName):gsub("_", " "))
                        .. " from faction '" .. getTeamName(theTeam) .. "' (#" .. fid .. ").", thePlayer, 0, 255, 0)
                outputChatBox("Entry #" .. tostring(entryID) .. " - reason: " .. reason .. ".", thePlayer, 220, 220, 220)
                logFactionAction(fid, addedBy, "blacklisted " .. resolvedName .. " (" .. reason .. ")") -- [Fix #146]

                -- [Fix #160] tell the leaders online so the blacklist is not silent
                for _, member in ipairs(getPlayersInTeam(theTeam)) do
                        if tonumber(getElementData(member, "factionleader") or 0) == 1 then
                                outputChatBox("Staff blacklisted " .. tostring(tostring(resolvedName):gsub("_", " "))
                                        .. " for your faction: " .. reason .. ".", member, 255, 170, 60)
                        end
                end

                local memberRow = mysql:query_fetch_assoc("SELECT faction_id FROM characters WHERE id='"
                        .. mysql:escape_string(tonumber(characterID)) .. "' LIMIT 1")
                if memberRow and tonumber(memberRow.faction_id) == fid then
                        outputChatBox("NOTE: that character is currently a MEMBER of this faction - remove him from the member list too.",
                                thePlayer, 255, 170, 60)
                end
        else
                outputChatBox("Error writing the blacklist entry, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("addfbl", addFactionBlacklist, false, false)

-- ===========================================================================
-- [Fix #160] factions.blacklist.delete - /removefbl [Entry ID]
-- ===========================================================================

function removeFactionBlacklist(thePlayer, commandName, entryID)
        if not fix160Check(thePlayer, "removefbl") then return end
        entryID = tonumber(entryID)
        if not entryID or entryID <= 0 then
                fix160Syntax(thePlayer, commandName, "[Entry ID]  (see /showfbl)")
                return
        end
        if not ensureFactionBlacklist() then
                outputChatBox("The factions_blacklist table is not available.", thePlayer, 255, 0, 0)
                return
        end
        local result = mysql:query("SELECT id, factionid, charactername FROM factions_blacklist WHERE id='"
                .. mysql:escape_string(entryID) .. "' LIMIT 1")
        local row = result and mysql:fetch_assoc(result)
        if result then mysql:free_result(result) end
        if not row then
                outputChatBox("No blacklist entry #" .. entryID .. ".", thePlayer, 255, 0, 0)
                return
        end
        if mysql:query_free("DELETE FROM factions_blacklist WHERE id='" .. mysql:escape_string(entryID) .. "'") then
                outputChatBox("Removed " .. tostring(tostring(row.charactername):gsub("_", " "))
                        .. " from the blacklist of faction #" .. tostring(row.factionid) .. ".", thePlayer, 0, 255, 0)
                logFactionAction(tonumber(row.factionid), getPlayerName(thePlayer),
                        "removed blacklist entry #" .. entryID .. " (" .. tostring(row.charactername) .. ")") -- [Fix #146]
        else
                outputChatBox("Error deleting the blacklist entry, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("removefbl", removeFactionBlacklist, false, false)

-- ===========================================================================
-- [Fix #160] setfactionradio - /setfactionradio [Faction ID] [Frequency]
-- the gate entry existed (command_gates_s.lua) but NO handler existed anywhere.
-- ===========================================================================

function adminSetFactionRadio(thePlayer, commandName, factionID, frequency)
        if not fix160Check(thePlayer, "setfactionradio") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end
        if frequency == nil then
                fix160Syntax(thePlayer, commandName, "[Faction ID] [Frequency, or - to clear]")
                return
        end
        local value = tostring(frequency)
        if value == "-" or value == "" then
                value = ""
        end
        if value ~= "" and (not value:match("^[%w%+%-%.%s%(%)%%]+$") or #value > 32) then
                outputChatBox("Invalid radio frequency - up to 32 characters, letters, digits and + - . ( ) % only.",
                        thePlayer, 255, 0, 0)
                return
        end
        if mysql:query_free("UPDATE factions SET radio='" .. mysql:escape_string(value) .. "' WHERE id='" .. fid .. "'") then
                setFactionProtectedData(theTeam, "radio", value, true)
                if value == "" then
                        outputChatBox("Cleared the radio frequency of faction '" .. getTeamName(theTeam) .. "'.", thePlayer, 0, 255, 0)
                        logFactionAction(fid, getPlayerName(thePlayer), "cleared the faction radio") -- [Fix #146]
                else
                        outputChatBox("Set the radio frequency of faction '" .. getTeamName(theTeam) .. "' to " .. value .. ".",
                                thePlayer, 0, 255, 0)
                        logFactionAction(fid, getPlayerName(thePlayer), "set the faction radio to " .. value) -- [Fix #146]
                end
        else
                outputChatBox("Error setting the faction radio, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("setfactionradio", adminSetFactionRadio, false, false)

-- ===========================================================================
-- [Fix #160] setfactiontype - /setfactiontype [Faction ID] [Type 0..11]
-- ===========================================================================

function adminSetFactionType(thePlayer, commandName, factionID, factionType)
        if not fix160Check(thePlayer, "setfactiontype") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end
        factionType = tonumber(factionType)
        if not factionType or factionType < 0 or factionType > 11 or factionType ~= math.floor(factionType) then
                fix160Syntax(thePlayer, commandName, "[Faction ID] [Type 0-11]")
                outputChatBox("0 Gang, 1 Mafia, 2 Law, 3 Government, 4 Medical, 5 Other, 6 News, 7 Mechanic, 8 Electric, 9 Traffic, 10 Business, 11 Family",
                        thePlayer, 255, 194, 14)
                return
        end
        if mysql:query_free("UPDATE factions SET type='" .. factionType .. "' WHERE id='" .. fid .. "'") then
                setFactionProtectedData(theTeam, "type", factionType, true)
                local typeName = FACTION_TYPES[factionType] or "Unknown"
                outputChatBox("Set the type of faction '" .. getTeamName(theTeam) .. "' (#" .. fid .. ") to "
                        .. factionType .. " (" .. typeName .. ").", thePlayer, 0, 255, 0)
                logFactionAction(fid, getPlayerName(thePlayer),
                        "set the faction type to " .. factionType .. " (" .. typeName .. ")") -- [Fix #146]
                pcall(syncFactionPermissions, thePlayer)
        else
                outputChatBox("Error setting the faction type, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("setfactiontype", adminSetFactionType, false, false)

-- ===========================================================================
-- [Fix #160] setfactionname - /setfactionname [Faction ID] [Name]. The same
-- rename /renamefaction performs, but done HERE instead of delegating to
-- adminRenameFaction: that handler wraps everything in a SILENT
-- isPlayerAdmin(...) if (no denial message), so a holder of this right below
-- the Moderator ladder would pass both gate layers and still get nothing.
-- ===========================================================================

function adminSetFactionName(thePlayer, commandName, factionID, ...)
        if not fix160Check(thePlayer, "setfactionname") then return end
        local nameParts = { ... }
        if not factionID or #nameParts == 0 then
                fix160Syntax(thePlayer, commandName, "[Faction ID] [Faction Name]")
                return
        end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end
        local factionName = table.concat(nameParts, " ")
        if mysql:query_free("UPDATE factions SET name='" .. mysql:escape_string(factionName) .. "' WHERE id='" .. fid .. "'") then
                local oldName = getTeamName(theTeam)
                setTeamName(theTeam, factionName)
                exports.global:sendMessageToAdmins(exports.global:getPlayerFullIdentity(thePlayer)
                        .. " renamed faction '" .. oldName .. "' to '" .. factionName .. "'.")
                exports.factions:sendNotiToAllFactionMembers(fid, "Your faction '" .. oldName
                        .. "' was renamed to '" .. factionName .. "' by "
                        .. exports.global:getPlayerFullIdentity(thePlayer, 1, true))
                logFactionAction(fid, getPlayerName(thePlayer), "renamed the faction to '" .. factionName .. "'") -- [Fix #146]
                outputChatBox("Renamed faction '" .. oldName .. "' to '" .. factionName .. "'.", thePlayer, 0, 255, 0)
        else
                outputChatBox("Error renaming the faction, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("setfactionname", adminSetFactionName, false, false)

-- ===========================================================================
-- [Fix #160] faction.givepoints - /givefactionpoints [Faction ID] [Points]
-- ===========================================================================

local function getFactionPoints(factionID)
        local row = mysql:query_fetch_assoc("SELECT value FROM settings WHERE name='faction_points_"
                .. mysql:escape_string(factionID) .. "' LIMIT 1")
        return tonumber(row and row.value) or 0
end

local function saveFactionPoints(factionID, points)
        local key = "faction_points_" .. mysql:escape_string(factionID)
        local row = mysql:query_fetch_assoc("SELECT id FROM settings WHERE name='" .. key .. "' LIMIT 1")
        if row then
                return mysql:query_free("UPDATE settings SET value='" .. tostring(points) .. "' WHERE name='" .. key .. "'")
        end
        return mysql:query_free("INSERT INTO settings (name, value) VALUES ('" .. key .. "', '" .. tostring(points) .. "')")
end

function giveFactionPoints(thePlayer, commandName, factionID, amount)
        if not fix160Check(thePlayer, "givefactionpoints") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end
        amount = tonumber(amount)
        if not amount or amount == 0 or amount ~= math.floor(amount) then
                fix160Syntax(thePlayer, commandName, "[Faction ID] [Points]   (a negative amount removes points)")
                return
        end
        local before = getFactionPoints(fid)
        local after = math.max(0, before + amount)
        if saveFactionPoints(fid, after) then
                outputChatBox("Faction '" .. getTeamName(theTeam) .. "' points: " .. before .. " -> " .. after .. ".",
                        thePlayer, 0, 255, 0)
                logFactionAction(fid, getPlayerName(thePlayer),
                        "set the faction points to " .. after .. " (" .. (amount > 0 and "+" or "") .. amount .. ")") -- [Fix #146]
        else
                outputChatBox("Error saving the faction points, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("givefactionpoints", giveFactionPoints, false, false)

-- ===========================================================================
-- [Fix #160] factions.check - /checkfaction [Faction ID] (one-faction dashboard)
-- ===========================================================================

function checkFactionInfo(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "checkfaction") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        local ftype = tonumber(getElementData(theTeam, "type") or -1)
        local money = tonumber(getElementData(theTeam, "money") or 0)
        local radio = tostring(getElementData(theTeam, "radio") or "")
        local hotline = tostring(getElementData(theTeam, "hotline") or "")
        local color = tostring(getElementData(theTeam, "color") or "#FFFFFF")
        local points = getFactionPoints(fid)

        local memberRow = mysql:query_fetch_assoc("SELECT COUNT(*) AS n, IFNULL(SUM(faction_leader = 1), 0) AS leaders FROM characters WHERE faction_id='"
                .. mysql:escape_string(fid) .. "'")
        local members = tonumber(memberRow and memberRow.n) or 0
        local leaders = tonumber(memberRow and memberRow.leaders) or 0
        local online = #getPlayersInTeam(theTeam)

        local blacklisted = 0
        if ensureFactionBlacklist() then
                blacklisted = fix160SafeCount("SELECT COUNT(*) AS n FROM factions_blacklist WHERE factionid='" .. mysql:escape_string(fid) .. "'")
        end

        local invoiceRow = mysql:query_fetch_assoc("SELECT COUNT(*) AS n, IFNULL(SUM(t.amount), 0) AS total FROM pd_tickets t LEFT JOIN characters c ON c.id = t.issuer WHERE c.faction_id='"
                .. mysql:escape_string(fid) .. "'")
        local invoices = tonumber(invoiceRow and invoiceRow.n) or 0
        local invoiceTotal = tonumber(invoiceRow and invoiceRow.total) or 0

        outputChatBox("========== FACTION CHECK #" .. fid .. " ==========", thePlayer, 60, 200, 120)
        outputChatBox("Name: " .. getTeamName(theTeam) .. " | Type: " .. ftype .. " (" .. (FACTION_TYPES[ftype] or "Unknown") .. ")",
                thePlayer, 220, 220, 220)
        outputChatBox("Bank: $" .. exports.global:formatMoney(money) .. " | Points: " .. points
                .. " | Members: " .. members .. " (" .. online .. " online, " .. leaders .. " leader(s))",
                thePlayer, 220, 220, 220)
        outputChatBox("Radio: " .. (radio ~= "" and radio or "-") .. " | Hotline: " .. (hotline ~= "" and hotline or "-")
                .. " | Color: " .. color, thePlayer, 220, 220, 220)
        outputChatBox("Blacklisted: " .. blacklisted .. " | Invoices: " .. invoices .. " ($" .. exports.global:formatMoney(invoiceTotal) .. ")",
                thePlayer, 220, 220, 220)
end

addCommandHandler("checkfaction", checkFactionInfo, false, false)

-- ===========================================================================
-- [Fix #160] faction.checkinvoices - /checkinvoices [Faction ID]
-- pd_tickets is the invoice this server has (Fix #110); the issuer column is
-- the character id, so the rows are matched through characters.faction_id.
-- ===========================================================================

function checkFactionInvoices(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "checkinvoices") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        local totalRow = mysql:query_fetch_assoc("SELECT COUNT(*) AS n, IFNULL(SUM(t.amount), 0) AS total FROM pd_tickets t LEFT JOIN characters c ON c.id = t.issuer WHERE c.faction_id='"
                .. mysql:escape_string(fid) .. "'")
        local count = tonumber(totalRow and totalRow.n) or 0
        local total = tonumber(totalRow and totalRow.total) or 0

        outputChatBox("========== INVOICES - faction '" .. getTeamName(theTeam) .. "' (#" .. fid .. ") ==========",
                thePlayer, 60, 200, 120)
        if count == 0 then
                outputChatBox("No outstanding invoices for this faction.", thePlayer, 255, 170, 60)
                return
        end

        local result = mysql:query("SELECT t.id, t.vehid, t.amount, t.reason, t.time, c.charactername FROM pd_tickets t LEFT JOIN characters c ON c.id = t.issuer WHERE c.faction_id='"
                .. mysql:escape_string(fid) .. "' ORDER BY t.id DESC LIMIT 15")
        if not result then
                outputChatBox("Could not read the invoices.", thePlayer, 255, 0, 0)
                return
        end
        local shown = 0
        while true do
                local row = mysql:fetch_assoc(result)
                if not row then break end
                shown = shown + 1
                outputChatBox("#" .. tostring(row.id) .. " $" .. exports.global:formatMoney(tonumber(row.amount) or 0)
                        .. " veh #" .. tostring(row.vehid) .. " by " .. tostring(tostring(row.charactername or "?"):gsub("_", " "))
                        .. " - " .. tostring(row.reason) .. " (" .. tostring(row.time) .. ")",
                        thePlayer, 220, 220, 220)
        end
        mysql:free_result(result)
        outputChatBox(shown .. " of " .. count .. " invoice(s) shown, total $" .. exports.global:formatMoney(total) .. ".",
                thePlayer, 0, 255, 0)
end

addCommandHandler("checkinvoices", checkFactionInvoices, false, false)

-- ===========================================================================
-- [Fix #160] faction.clearinvoices - /clearinvoices [Faction ID]
-- ===========================================================================

function clearFactionInvoices(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "clearinvoices") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        local where = " FROM pd_tickets t LEFT JOIN characters c ON c.id = t.issuer WHERE c.faction_id='"
                .. mysql:escape_string(fid) .. "'"
        local count = fix160SafeCount("SELECT COUNT(*) AS n" .. where)
        if count == 0 then
                outputChatBox("There are no invoices to clear for this faction.", thePlayer, 255, 170, 60)
                return
        end
        local ids = {}
        local result = mysql:query("SELECT t.id" .. where .. " ORDER BY t.id LIMIT 500")
        if result then
                while true do
                        local row = mysql:fetch_assoc(result)
                        if not row then break end
                        ids[#ids + 1] = tonumber(row.id)
                end
                mysql:free_result(result)
        end
        if #ids == 0 then
                outputChatBox("There are no invoices to clear for this faction.", thePlayer, 255, 170, 60)
                return
        end
        local deleted = 0
        for _, id in ipairs(ids) do
                if mysql:query_free("DELETE FROM pd_tickets WHERE id='" .. mysql:escape_string(id) .. "'") then
                        deleted = deleted + 1
                end
        end
        outputChatBox("Cleared " .. deleted .. " of " .. count .. " invoice(s) of faction '" .. getTeamName(theTeam) .. "'.",
                thePlayer, 0, 255, 0)
        logFactionAction(fid, getPlayerName(thePlayer), "cleared " .. deleted .. " faction invoice(s)") -- [Fix #146]
end

addCommandHandler("clearinvoices", clearFactionInvoices, false, false)

-- ===========================================================================
-- [Fix #160] factions.clearlogs - /clearfactionlogs [Faction ID]
-- ===========================================================================

function clearFactionLogs(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "clearfactionlogs") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        -- [Fix #160] owl_logs is the live audit trail: the affected column
        -- carries "fa<id>;" (the ';' keeps faction #1 apart from faction #11)
        local faTag = "fa" .. fid
        local owlWhere = " WHERE affected LIKE '" .. mysql:escape_string(faTag) .. ";%' OR affected LIKE '%;"
                .. mysql:escape_string(faTag) .. ";%'"
        local owlCount = fix160SafeCount("SELECT COUNT(*) AS n FROM owl_logs" .. owlWhere)

        -- [Fix #160] factionlogs is the F3 Logs tab store (Fix #146); best
        -- effort only - a not-imported table simply counts as 0 here
        local faWhere = " WHERE factionID='" .. mysql:escape_string(fid) .. "'"
        local faCount = fix160SafeCount("SELECT COUNT(*) AS n FROM factionlogs" .. faWhere)

        local cleared = 0
        if owlCount > 0 and mysql:query_free("DELETE FROM owl_logs" .. owlWhere) then
                cleared = cleared + owlCount
        end
        if faCount > 0 and mysql:query_free("DELETE FROM factionlogs" .. faWhere) then
                cleared = cleared + faCount
        end

        outputChatBox("Cleared " .. cleared .. " log row(s) of faction '" .. getTeamName(theTeam) .. "' (#" .. fid .. ").",
                thePlayer, 0, 255, 0)
        logFactionAction(fid, getPlayerName(thePlayer), "cleared the faction logs (" .. cleared .. " rows)") -- [Fix #146]
end

addCommandHandler("clearfactionlogs", clearFactionLogs, false, false)

-- ===========================================================================
-- [Fix #160] faction.forcewage - /forcefactionwage [Faction ID]
-- pays every ONLINE member right now out of the faction bank, the same wage the
-- payday code (s_payday.lua) would pay for his rank.
-- ===========================================================================

function forceFactionWage(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "forcefactionwage") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        local wages = getElementData(theTeam, "wages")
        if type(wages) ~= "table" then
                outputChatBox("The wage table of that faction is not loaded.", thePlayer, 255, 0, 0)
                return
        end

        local paid, total = 0, 0
        for _, member in ipairs(getPlayersInTeam(theTeam)) do
                if getElementData(member, "loggedin") == 1 then
                        local rank = tonumber(getElementData(member, "factionrank")) or 1
                        local wage = tonumber(wages[rank]) or 0
                        if wage > 0 then
                                if exports.global:takeMoney(theTeam, wage) then
                                        exports.global:giveMoney(member, wage)
                                        paid = paid + 1
                                        total = total + wage
                                        outputChatBox("Forced faction wage: $" .. exports.global:formatMoney(wage)
                                                .. " paid by staff.", member, 255, 194, 14)
                                else
                                        outputChatBox("The faction bank cannot cover the wages - stopped after "
                                                .. paid .. " payment(s).", thePlayer, 255, 0, 0)
                                        break
                                end
                        end
                end
        end

        outputChatBox("Paid $" .. exports.global:formatMoney(total) .. " to " .. paid
                .. " online member(s) of '" .. getTeamName(theTeam) .. "' (#" .. fid .. ").", thePlayer, 0, 255, 0)
        logFactionAction(fid, getPlayerName(thePlayer),
                "forced the faction wage ($" .. exports.global:formatMoney(total) .. " to " .. paid .. " member(s))") -- [Fix #146]
end

addCommandHandler("forcefactionwage", forceFactionWage, false, false)

-- ===========================================================================
-- [Fix #160] faction.resetranks - /resetfactionranks [Faction ID]
-- rank names + wages back to the same defaults /makefaction writes.
-- ===========================================================================

function resetFactionRanks(thePlayer, commandName, factionID)
        if not fix160Check(thePlayer, "resetfactionranks") then return end
        local theTeam, fid = fix160GetTeam(factionID, thePlayer)
        if not theTeam then return end

        local ranks, wages, sets = {}, {}, {}
        for i = 1, 20 do
                ranks[i] = "Dynamic Rank #" .. i
                wages[i] = 100
                sets[#sets + 1] = "rank_" .. i .. "='" .. mysql:escape_string(ranks[i]) .. "'"
                sets[#sets + 1] = "wage_" .. i .. "='" .. wages[i] .. "'"
        end

        if mysql:query_free("UPDATE factions SET " .. table.concat(sets, ", ") .. " WHERE id='" .. fid .. "'") then
                setFactionProtectedData(theTeam, "ranks", ranks, false)
                setFactionProtectedData(theTeam, "wages", wages, false)
                outputChatBox("Reset the rank names and wages of faction '" .. getTeamName(theTeam) .. "' (#" .. fid
                        .. ") to the defaults (wage $100).", thePlayer, 0, 255, 0)
                logFactionAction(fid, getPlayerName(thePlayer), "reset the faction ranks & wages to the defaults") -- [Fix #146]
                pcall(syncFactionPermissions, thePlayer)
        else
                outputChatBox("Error resetting the faction ranks, Contact an admin.", thePlayer, 255, 0, 0)
        end
end

addCommandHandler("resetfactionranks", resetFactionRanks, false, false)
