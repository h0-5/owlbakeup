--[[ =========================================================================
        permissions.lua — Vortex FACTION PERMISSIONS (Fix #56)

        Port of the OLD CLIENT faction permission model
        (backupm [rp]/faction-system/config_decompiled.lua):
            faction_permissions = {
                ["2"] = { "invoice", "rbs", "spikes" },
                ["3"] = { "invoice", "marry", "divorce" },
                ["4"] = { "invoice" },
                ["7"] = { "invoice", "mechanic_panel" },
                ["8"] = { "invoice" },
                ["9"] = { "invoice", "mechanic_panel" },
                ["6"] = { "invoice", "news" },
            }
        The old client and owl share the SAME faction type numbering
        (owl c_faction_uikit FACTION_TYPES / roadblock-system g_roadblocks):
            0 Gang, 1 Mafia, 2 Law, 3 Government, 4 Medical, 5 Other,
            6 News, 7 Mechanic, 8 Electric, 9 Traffic, 10 Business, 11 Family
        -> the config ports 1:1 (gangs/mafia got none in the old client).

        NEW per the user request ("صلاحيات مسعف شرطي الخ حسب رتبة بفاكشن
        وحسب تايب الفاكشن"): every permission also carries a MINIMUM RANK
        inside the faction (factionrank 1 = newest member, 20 = top; the
        factionleader flag always passes).  Everything is SERVER
        AUTHORITY - the client list is display only.

        exports:
            doesPlayerHaveFactionPermission(player, perm)  -> bool (server)
            getPlayerFactionPermissions(player)            -> table (server)
        client sync: triggerClientEvent("faction:permissions:sync", player,
            { { id, en, ar, allowed, minRank, minRankName } }, typeName)
========================================================================= ]]

local FACTION_PERMISSIONS = {
        [2] = { "invoice", "rbs", "spikes" },          -- Law (police)
        [3] = { "invoice", "marry", "divorce" },       -- Government / justice
        [4] = { "invoice" },                           -- Medical
        [7] = { "invoice", "mechanic_panel" },         -- Mechanic
        [8] = { "invoice" },                           -- Electric
        [9] = { "invoice", "mechanic_panel" },         -- Traffic
        [6] = { "invoice", "news" },                   -- News
}

local PERMISSION_INFO = {
        invoice        = { en = "Invoices",         ar = "الإيصالات",       minRank = 1 },
        rbs            = { en = "Road Blocks",      ar = "الحواجز المرورية", minRank = 3 },
        spikes         = { en = "Spike Strips",     ar = "أشواك الإطارات",   minRank = 3 },
        marry          = { en = "Marriage",         ar = "عقد القرآن",       minRank = 6 },
        divorce        = { en = "Divorce",          ar = "الطلاق",           minRank = 6 },
        news           = { en = "News Tools",       ar = "أدوات الإعلام",    minRank = 1 },
        mechanic_panel = { en = "Mechanic Panel",   ar = "لوحة الميكانيكي",  minRank = 3 },
}

local FACTION_TYPE_NAMES = {
        [0] = { en = "Gang", ar = "عصابة" },
        [1] = { en = "Mafia", ar = "مافيا" },
        [2] = { en = "Law", ar = "شرطي" },
        [3] = { en = "Government", ar = "حكومي" },
        [4] = { en = "Medical", ar = "مسعف" },
        [5] = { en = "Other", ar = "أخر" },
        [6] = { en = "News", ar = "إعلام" },
        [7] = { en = "Mechanic", ar = "ميكانيكي" },
        [8] = { en = "Electric", ar = "كهرباء" },
        [9] = { en = "Traffic", ar = "مرور" },
        [10] = { en = "Business", ar = "أعمال" },
        [11] = { en = "Family", ar = "عائلة" },
}

local function getPlayerFactionType(player)
        local team = getPlayerTeam(player)
        if not isElement(team) then return nil end
        return tonumber(getElementData(team, "type"))
end

local function getMinRankName(team, minRank)
        if not isElement(team) then return tostring(minRank) end
        local ranks = getElementData(team, "ranks")
        if type(ranks) == "table" and tonumber(ranks[minRank]) then
                return tostring(ranks[minRank])
        end
        return tostring(minRank)
end

-- list every permission of the player's faction type with its allowed flag
function getPlayerFactionPermissions(player)
        local out = {}
        if not isElement(player) or getElementType(player) ~= "player" then return out end
        local team = getPlayerTeam(player)
        local factionType = getPlayerFactionType(player)
        local typeName = FACTION_TYPE_NAMES[factionType or -1] or { en = "Unknown", ar = "غير معروف" }
        local permList = FACTION_PERMISSIONS[factionType or -1]
        if not permList then
                return out, typeName
        end
        local isLeader = tonumber(getElementData(player, "factionleader") or 0) == 1
        local rank = tonumber(getElementData(player, "factionrank") or 1) or 1
        for _, perm in ipairs(permList) do
                local info = PERMISSION_INFO[perm] or { en = perm, ar = perm, minRank = 1 }
                local allowed = isLeader or rank >= (tonumber(info.minRank) or 1)
                out[#out + 1] = {
                        id = perm,
                        en = info.en,
                        ar = info.ar,
                        allowed = allowed,
                        minRank = tonumber(info.minRank) or 1,
                        minRankName = getMinRankName(team, tonumber(info.minRank) or 1),
                }
        end
        return out, typeName
end

-- server-authoritative gate used by spike-system / roadblock-system / others
function doesPlayerHaveFactionPermission(player, perm)
        if not isElement(player) or getElementType(player) ~= "player" then return false end
        if getElementData(player, "loggedin") ~= 1 then return false end
        local factionType = getPlayerFactionType(player)
        local permList = FACTION_PERMISSIONS[factionType or -1]
        if not permList then return false end
        local granted = false
        for _, p in ipairs(permList) do
                if p == perm then granted = true break end
        end
        if not granted then return false end
        local info = PERMISSION_INFO[perm] or { minRank = 1 }
        if tonumber(getElementData(player, "factionleader") or 0) == 1 then return true end
        local rank = tonumber(getElementData(player, "factionrank") or 1) or 1
        return rank >= (tonumber(info.minRank) or 1)
end

-- push the player's permission list to his client (F3 Tools tab display)
function syncFactionPermissions(player)
        local perms, typeName = getPlayerFactionPermissions(player)
        if not perms then return end
        triggerClientEvent(player, "faction:permissions:sync", player, perms,
                { en = typeName.en or "", ar = typeName.ar or "" })
end

-- F3 open piggyback (called from s_faction_system.showFactionMenuEx)
addEvent("faction:permissions:request", true)
addEventHandler("faction:permissions:request", root, function()
        if client and getElementType(client) == "player" then
                syncFactionPermissions(client)
        end
end)

-- exports for other resources
function fsExportHasPermission(player, perm)
        return doesPlayerHaveFactionPermission(player, perm)
end

function fsExportGetPermissions(player)
        return getPlayerFactionPermissions(player)
end
