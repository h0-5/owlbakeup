-- [Fix #160] A2 - gunlicense/character/weapons command handlers
-- Owned exclusively by the matching Fix #160 task agent.
--
-- Rights that get their FIRST command behind them here (the gate keys live in
-- staff_manager/gates_fix160_task2.lua):
--   givegunlicense        -> /givegunlicense
--   cancelgunlicense      -> /cancelgunlicense
--   character.addlanguage -> /addlanguage
--   character.setmoney    -> /setcharmoney   (DB-DIRECT, NOT the live /setmoney)
--   character.setcountry  -> /setcountry
--   weapons.goto          -> /wgoto
-- They register through the WRAPPED addCommandHandler (command_gates_s.lua is
-- the first script of admin-system), so ranked staff are already refused by
-- the gate itself; the helper below is the legacy ladder for players without a
-- Vortex rank, which the gate deliberately lets through (same rule as Fix #157).

local mysql = exports.mysql

local function fix160CharTrim(s)
        s = tostring(s or "")
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fix160CharSyntax(player, cmd, args)
        outputChatBox("SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), player, 255, 194, 14)
end

local function fix160CharHasRight(player, right)
        if not isElement(player) then return false end
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right) and true or false
                end
                return false
        end
        local prefix = tostring(right):match("^([%w]+)%.") or ""
        if prefix == "owner" or prefix == "accounts" then
                return exports.integration:isPlayerLeadAdmin(player) and true or false
        end
        if prefix == "character" then
                return exports.integration:isPlayerTrialAdmin(player) and true or false
        end
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function fix160CharCheck(player, right)
        if fix160CharHasRight(player, right) then return true end
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return false
end

-- admin-command log (action 4 = "Admin command"); affected may be an element
-- or, for offline rows, any string
local function fix160CharLog(actor, data, affected)
        pcall(function()
                exports.logs:dbLog(actor, 4, affected or actor, data)
        end)
end

-- resolve an ONLINE target; findPlayerByPartialNick prints its own miss msg
local function fix160CharTarget(player, query)
        local target, targetName = exports.global:findPlayerByPartialNick(player, query)
        if not isElement(target) then return nil, nil end
        if tonumber(getElementData(target, "loggedin") or 0) ~= 1 then
                outputChatBox("Player is not logged in.", player, 255, 0, 0)
                return nil, nil
        end
        return target, targetName
end

-- ==================================================== gun license (DB) ====
-- characters.gun_license / characters.gun2_license (int 0/1) + the live
-- license.gun / license.gun2 element data the shops and MDC read.

local function fix160GunLicense(player, cmd, targetQuery, state, revoke)
        if not fix160CharCheck(player, revoke and "cancelgunlicense" or "givegunlicense") then return end
        if not targetQuery then
                fix160CharSyntax(player, cmd, "[Player Partial Nick / ID] "
                        .. (revoke and "[1 = Tier 1, 2 = Tier 2, 0/none = both]"
                                or "[1 = Tier 1 (default), 2 = Tier 2, 0 = revoke]"))
                return
        end
        local target, targetName = fix160CharTarget(player, targetQuery)
        if not target then return end
        local dbid = tonumber(getElementData(target, "dbid"))
        if not dbid then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end

        local tier = tonumber(fix160CharTrim(state)) or (revoke and 0 or 1)
        if tier ~= 0 and tier ~= 1 and tier ~= 2 then
                outputChatBox("Tier must be 1 (Tier 1 firearms), 2 (Tier 2 firearms)"
                        .. (revoke and "" or " or 0 (revoke)") .. ".", player, 255, 0, 0)
                return
        end

        -- /givegunlicense <p> 0 is the revoke spelling of the [0/1] syntax
        if not revoke and tier == 0 then revoke = true end

        local cols, labels, keys = {}, {}, {}
        if tier == 0 then
                cols, labels, keys = { "gun_license", "gun2_license" },
                        { "Tier 1", "Tier 2" }, { "license.gun", "license.gun2" }
        elseif tier == 1 then
                cols, labels, keys = { "gun_license" }, { "Tier 1" }, { "license.gun" }
        else
                cols, labels, keys = { "gun2_license" }, { "Tier 2" }, { "license.gun2" }
        end

        local value = revoke and 0 or 1
        local updates = {}
        for _, col in ipairs(cols) do
                updates[#updates + 1] = "`" .. col .. "`='" .. value .. "'"
        end
        if not mysql:query_free("UPDATE characters SET " .. table.concat(updates, ", ")
                .. " WHERE id=" .. dbid .. " LIMIT 1") then
                outputChatBox("Database error - the license was not changed.", player, 255, 0, 0)
                return
        end
        for i, key in ipairs(keys) do
                exports.anticheat:changeProtectedElementDataEx(target, key, value, false)
        end

        local what = table.concat(labels, " + ") .. " firearms license "
                .. (revoke and "revoked" or "granted")
        outputChatBox(targetName .. ": " .. what .. ".", player, 0, 255, 0)
        if target ~= player then
                outputChatBox("Your " .. table.concat(labels, " + ")
                        .. " firearms license was " .. (revoke and "revoked" or "granted")
                        .. " by " .. exports.global:getPlayerAdminTitle(player) .. " "
                        .. getPlayerName(player):gsub("_", " ") .. ".", target,
                        revoke and 255 or 0, revoke and 100 or 255, revoke and 100 or 0)
        end
        fix160CharLog(player, (revoke and "CANCELGUNLICENSE " or "GIVEGUNLICENSE ")
                .. (revoke and "REMOVE " or "SET ") .. tostring(value) .. " tier "
                .. tostring(tier), target)
end

addCommandHandler("givegunlicense", function(player, cmd, targetQuery, state)
        fix160GunLicense(player, cmd, targetQuery, state, false)
end, false, false)

addCommandHandler("cancelgunlicense", function(player, cmd, targetQuery, state)
        fix160GunLicense(player, cmd, targetQuery, state, true)
end, false, false)

-- ========================================================== languages =====
-- characters.lang1/lang2/lang3 (+langNskill). language-system's learnLanguage
-- already writes the FIRST FREE slot and syncs the element data, so this is
-- the admin-facing entry point the character.addlanguage right promised.

addCommandHandler("addlanguage", function(player, cmd, targetQuery, language)
        if not fix160CharCheck(player, "character.addlanguage") then return end
        if not targetQuery or not language then
                fix160CharSyntax(player, cmd, "[Player Partial Nick / ID] [Language]")
                outputChatBox("Example: /" .. cmd .. " John English   (name or language number)",
                        player, 170, 170, 170)
                return
        end
        local target, targetName = fix160CharTarget(player, targetQuery)
        if not target then return end

        local langRes = getResourceFromName("language-system")
        if not langRes or getResourceState(langRes) ~= "running" then
                outputChatBox("The language-system resource is not running.", player, 255, 0, 0)
                return
        end
        local lang = tonumber(language) or getLanguageByName(language)
        if not lang then
                outputChatBox(tostring(language) .. " is not a valid language.", player, 255, 0, 0)
                return
        end
        local langname = call(langRes, "getLanguageName", lang)
        if not langname or langname == "" or langname == "<Invalid/Bugged Language>" then
                outputChatBox(tostring(language) .. " is not a valid language.", player, 255, 0, 0)
                return
        end

        local success, reason = call(langRes, "learnLanguage", target, lang, false, 100)
        if not success then
                outputChatBox(targetName .. " could not learn " .. tostring(langname)
                        .. ": " .. tostring(reason), player, 255, 0, 0)
                return
        end
        outputChatBox(targetName .. " now speaks " .. tostring(langname)
                .. " (first free lang slot, skill 100).", player, 0, 255, 0)
        if target ~= player then
                outputChatBox("Staff added " .. tostring(langname) .. " to your languages.",
                        target, 0, 255, 0)
        end
        fix160CharLog(player, "ADDLANGUAGE " .. tostring(langname) .. " 100", target)
end, false, false)

-- ================================================= DB-direct character money
-- /setmoney stays gated to admin.setplayermoney and keeps moving the LIVE
-- cash (element data + wallet). This one is deliberately DB-DIRECT on
-- characters.money only (owner's call in Fix #160): it changes the stored
-- row and never touches the running session's cash.

addCommandHandler("setcharmoney", function(player, cmd, targetQuery, amount)
        if not fix160CharCheck(player, "character.setmoney") then return end
        if not targetQuery or not amount then
                fix160CharSyntax(player, cmd, "[Player Partial Nick / ID] [Amount]")
                outputChatBox("Writes characters.money in the database only - the live "
                        .. "/setmoney command is a different right (admin.setplayermoney).",
                        player, 170, 170, 170)
                return
        end
        local n = tonumber(amount)
        if not n or n < 0 or n % 1 ~= 0 then
                outputChatBox("Amount must be a whole number of 0 or more.", player, 255, 0, 0)
                return
        end
        local target, targetName = fix160CharTarget(player, targetQuery)
        if not target then return end
        local dbid = tonumber(getElementData(target, "dbid"))
        if not dbid then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end

        local row = mysql:query_fetch_assoc("SELECT money FROM characters WHERE id=" .. dbid .. " LIMIT 1")
        local before = row and tonumber(row.money) or 0
        if before == n then
                outputChatBox("characters.money for " .. targetName .. " is already "
                        .. exports.global:formatMoney(n) .. ".", player, 255, 194, 14)
                return
        end
        if not mysql:query_free("UPDATE characters SET money='" .. n .. "' WHERE id="
                .. dbid .. " LIMIT 1") then
                outputChatBox("Database error - characters.money was not changed.", player, 255, 0, 0)
                return
        end
        outputChatBox("characters.money for " .. targetName .. " (#" .. dbid .. "): "
                .. exports.global:formatMoney(before) .. " -> " .. exports.global:formatMoney(n)
                .. "  (database row only, live cash untouched)", player, 0, 255, 0)
        fix160CharLog(player, "SETCHARMONEY " .. exports.global:formatMoney(before) .. " -> "
                .. exports.global:formatMoney(n), target)
end, false, false)

-- ============================================================= country =====
-- characters.country did not exist - the column was added by this task.
-- Codes are the same 2-letter set global/s_country_globals.lua resolves
-- through its ip2c XML files (getPlayerCountry / getPlayerCountryByIP).

local FIX160_COUNTRY_CODES = {}
for code in ([=[
AD AE AF AG AI AL AM AN AO AP AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ
CA CD CF CH CI CK CL CM CN CO CR CS CU CY CZ DE DJ DK DO DZ EC EE EG ER ES ET EU FI FJ FM FO FR GA GB GD GE
GF GH GI GL GM GP GR GT GU GW GY HK HN HR HT HU ID IE IL IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KN KR KW
KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD MG MH MK ML MM MN MO MP MR MT MU MV MW MX MY MZ NA NC NF NG
NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN
SR SV SZ TG TH TJ TM TN TO TR TT TV TW TZ UA UG US UY UZ VA VE VG VI VN VU WF WS YE ZA ZM ZW ZZ
]=]):gmatch("%a+") do
        FIX160_COUNTRY_CODES[code] = true
end

addCommandHandler("setcountry", function(player, cmd, targetQuery, country)
        if not fix160CharCheck(player, "character.setcountry") then return end
        if not targetQuery then
                fix160CharSyntax(player, cmd, "[Player Partial Nick / ID] [Country Code]")
                outputChatBox("Country code = the 2-letter code the server's own IP-to-country "
                        .. "data uses (e.g. US, GB, SA, DE, EG, TR).", player, 170, 170, 170)
                return
        end
        local target, targetName = fix160CharTarget(player, targetQuery)
        if not target then return end
        local dbid = tonumber(getElementData(target, "dbid"))
        if not dbid then
                outputChatBox("That player has no character loaded.", player, 255, 0, 0)
                return
        end
        local row = mysql:query_fetch_assoc("SELECT country FROM characters WHERE id="
                .. dbid .. " LIMIT 1")
        if not row then
                outputChatBox("Character row not found.", player, 255, 0, 0)
                return
        end
        local before = (row.country and tostring(row.country) ~= "") and tostring(row.country) or "-"

        if not country or fix160CharTrim(country) == "" then
                outputChatBox(targetName .. "'s country: " .. before, player, 120, 200, 255)
                return
        end
        local code = fix160CharTrim(country):upper()
        if not code:match("^%a%a$") or not FIX160_COUNTRY_CODES[code] then
                outputChatBox(tostring(country) .. " is not a valid country code "
                        .. "(2 letters, e.g. US / GB / SA / DE).", player, 255, 0, 0)
                return
        end
        if before == code then
                outputChatBox(targetName .. "'s country is already " .. code .. ".",
                        player, 255, 194, 14)
                return
        end
        if not mysql:query_free("UPDATE characters SET country='" .. code .. "' WHERE id="
                .. dbid .. " LIMIT 1") then
                outputChatBox("Database error - characters.country was not changed "
                        .. "(is the column added?).", player, 255, 0, 0)
                return
        end
        outputChatBox(targetName .. "'s country: " .. before .. " -> " .. code, player, 0, 255, 0)
        fix160CharLog(player, "SETCOUNTRY " .. before .. " -> " .. code, target)
end, false, false)

-- ==================================================== weapons.goto (/wgoto)
-- BEST INTERPRETATION, flagged for the owner: there is NO weapon spawn /
-- pickup coordinate table anywhere in the repo (c_weapon_creator.lua is a
-- pure spawn GUI, gunmaker/gunids/gunchart are stat charts, the weapon
-- libraries hold stats, not positions). The only weapon LOCATIONS the server
-- stores are weapon world items - worlditems rows with itemid 115 (Weapon)
-- and 116 (Ammopack) plus rows with a NEGATIVE itemid (a weapon dropped from
-- hand stores -<gta weapon id>, see item-world/s_load_items.lua). So
-- /wgoto <id> goes to a weapon lying on the ground, and bare /wgoto lists
-- those ids.

local function fix160WorldItemElement(id)
        local res = getResourceFromName("item-world")
        if res and getResourceState(res) == "running" then
                for _, obj in ipairs(getElementsByType("object", getResourceRootElement(res))) do
                        if tonumber(getElementData(obj, "id")) == id then
                                return obj
                        end
                end
        end
        return nil
end

local function fix160ItemName(itemID)
        itemID = tonumber(itemID)
        if itemID and itemID < 0 then
                local weaponName = getWeaponNameFromID(-itemID)
                if weaponName and weaponName ~= "" and weaponName ~= "Unknown" then
                        return tostring(weaponName)
                end
        end
        local ok, name = pcall(function()
                return exports["item-system"]:getItemName(itemID)
        end)
        if ok and name and tostring(name) ~= "" then
                return tostring(name)
        end
        return "item #" .. tostring(itemID)
end

-- worlditems convention (item-system/s_world_items.lua + item-world/s_load_items.lua):
--   > 0  normal inventory item on the ground (115 = Weapon, 116 = Ammopack)
--   < 0  weapon dropped from hand -> the row stores the NEGATED gta weapon id
local function fix160IsWeaponItem(itemID)
        itemID = tonumber(itemID)
        return itemID == 115 or itemID == 116 or (itemID ~= nil and itemID < 0)
end


addCommandHandler("wgoto", function(player, cmd, id)
        if not fix160CharCheck(player, "weapons.goto") then return end
        id = tonumber(id)
        if not id then
                fix160CharSyntax(player, cmd, "[World Item ID]  (no argument = list weapon items)")
                local res = getResourceFromName("item-world")
                local list = {}
                if res and getResourceState(res) == "running" then
                        local px, py, pz = getElementPosition(player)
                        for _, obj in ipairs(getElementsByType("object", getResourceRootElement(res))) do
                                local itemID = tonumber(getElementData(obj, "itemID"))
                                if fix160IsWeaponItem(itemID) then
                                        local x, y, z = getElementPosition(obj)
                                        list[#list + 1] = {
                                                id = tonumber(getElementData(obj, "id")),
                                                itemID = itemID,
                                                x = x, y = y, z = z,
                                                dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z),
                                        }
                                end
                        end
                else
                        local q = mysql:query("SELECT id, itemid, x, y, z FROM worlditems"
                                .. " WHERE itemid IN (115,116) OR itemid < 0 LIMIT 100")
                        if q then
                                while true do
                                        local row = mysql:fetch_assoc(q)
                                        if not row then break end
                                        local x, y, z = tonumber(row.x), tonumber(row.y), tonumber(row.z)
                                        if x and y and z then
                                                local px, py, pz = getElementPosition(player)
                                                list[#list + 1] = {
                                                        id = tonumber(row.id),
                                                        itemID = tonumber(row.itemid),
                                                        x = x, y = y, z = z,
                                                        dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z),
                                                }
                                        end
                                end
                                mysql:free_result(q)
                        end
                end
                table.sort(list, function(a, b) return a.dist < b.dist end)
                outputChatBox("Weapon/ammo items on the ground (115 = Weapon, 116 = Ammopack, negative = dropped weapon):",
                        player, 60, 200, 120)
                if #list == 0 then
                        outputChatBox("  none - no weapon/ammo world items exist right now.",
                                player, 255, 194, 14)
                        return
                end
                for i = 1, math.min(#list, 15) do
                        local e = list[i]
                        outputChatBox("  #" .. tostring(e.id) .. "  " .. fix160ItemName(e.itemID)
                                .. " (" .. tostring(e.itemID) .. ")  at "
                                .. string.format("%.1f, %.1f, %.1f", e.x, e.y, e.z)
                                .. "  " .. math.floor(e.dist) .. " m", player, 220, 220, 220)
                end
                if #list > 15 then
                        outputChatBox("  ... and " .. (#list - 15) .. " more (showing nearest 15).",
                                player, 170, 170, 170)
                end
                outputChatBox("Usage: /" .. cmd .. " [ID]", player, 170, 170, 170)
                return
        end

        local obj = fix160WorldItemElement(id)
        local x, y, z, int, dim, itemID
        if isElement(obj) then
                x, y, z = getElementPosition(obj)
                int = getElementInterior(obj)
                dim = getElementDimension(obj)
                itemID = tonumber(getElementData(obj, "itemID"))
        else
                local row = mysql:query_fetch_assoc("SELECT id, itemid, x, y, z, interior, dimension"
                        .. " FROM worlditems WHERE id=" .. id .. " LIMIT 1")
                if not row then
                        outputChatBox("No world item #" .. id .. " found.", player, 255, 0, 0)
                        return
                end
                x, y, z = tonumber(row.x), tonumber(row.y), tonumber(row.z)
                int = tonumber(row.interior) or 0
                dim = tonumber(row.dimension) or 0
                itemID = tonumber(row.itemid)
        end
        if not x then
                outputChatBox("World item #" .. id .. " has no position.", player, 255, 0, 0)
                return
        end

        detachElements(player)
        setElementInterior(player, int)
        setElementDimension(player, dim)
        setElementPosition(player, x, y, z + 0.5)
        setCameraInterior(player, int)
        outputChatBox("Teleported to world item #" .. id .. " - " .. fix160ItemName(itemID)
                .. " (" .. tostring(itemID) .. ") at "
                .. string.format("%.1f, %.1f, %.1f", x, y, z)
                .. "  int " .. int .. "/" .. "dim " .. dim .. ".", player, 0, 255, 0)
        if not fix160IsWeaponItem(itemID) then
                outputChatBox("Note: that item is not a weapon/ammo item (115 = Weapon, 116 = Ammopack, negative = dropped weapon).",
                        player, 255, 194, 14)
        end
        fix160CharLog(player, "WGOTO worlditem #" .. id .. " item " .. tostring(itemID), player)
end, false, false)
