-- [Fix #160] A8 - shops/interiors/peds/elevators/cleanstreets handlers
-- Owned exclusively by the matching Fix #160 task agent.

-- ===========================================================================
-- [Fix #160] Task 8 - the A8 domain rights had no working command behind
-- them. staff_manager/gates_fix160_task8.lua maps every right to a command;
-- this file supplies the commands that did not exist yet. They register
-- through the WRAPPED addCommandHandler (gate layer 1), and the helper below
-- is the legacy ladder for players without a Vortex rank (same rule as the
-- Fix #157 helpers in staff_manager_s.lua).
-- ===========================================================================

local FIX160_INTERIOR_OWNER = 4
local FIX160_INTERIOR_LOCKED = 3
local FIX160_BRIEFCASE_ITEM = 160

-- right check: rank rights are the ONLY truth for ranked staff, the legacy
-- integration ladder decides for everyone else
local function fix160HasRight(player, right)
        if not isElement(player) then return false end
        if getElementData(player, "rank:index") then
                if type(playerHasRight) == "function" then
                        return playerHasRight(player, right) and true or false
                end
                return false
        end
        return exports.integration:isPlayerSeniorAdmin(player) and true or false
end

local function fix160Check(player, right)
        if fix160HasRight(player, right) then return true end
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return false
end

local function fix160Syntax(player, cmd, args)
        outputChatBox("SYNTAX: /" .. tostring(cmd) .. " " .. tostring(args), player, 255, 194, 14)
end

local function fix160Escape(value)
        return exports.mysql:escape_string(tostring(value or ""))
end

local function fix160Log(player, actionID, data)
        exports.logs:dbLog(player, actionID, player, data)
end

-- resolves "[Player Partial Nick / ID]" or prints why it failed
local function fix160Target(player, cmd, arg)
        if not arg or arg == "" then
                fix160Syntax(player, cmd, "[Player Partial Nick / ID]")
                return nil
        end
        local target = exports.global:findPlayerByPartialNick(player, arg)
        if not target or not isElement(target) then
                outputChatBox("Player '" .. tostring(arg) .. "' was not found.", player, 255, 0, 0)
                return nil
        end
        return target
end

local function fix160Running(name)
        local res = getResourceFromName(name)
        if res and getResourceState(res) == "running" then return res end
        return nil
end

-- ===========================================================================
-- /cleanstreets  -  right: admin.cleanstreets (gate entry already existed,
-- the handler did not). Removes everything that lies ON THE STREET:
--   * worlditems rows in dimension 0 + their live item-world objects
--   * roadblock-system objects (and their spike shapes)
--   * spike-system spike strips
-- First run only warns and shows the counts, /cleanstreets confirm executes.
-- ===========================================================================
local fix160CleanPending = {}

local function fix160StreetItemIDs()
        local ids = {}
        local result = exports.mysql:query("SELECT id FROM worlditems WHERE dimension = 0")
        if not result then return ids end
        while true do
                local row = exports.mysql:fetch_assoc(result)
                if not row then break end
                ids[#ids + 1] = tonumber(row.id) or 0
        end
        exports.mysql:free_result(result)
        return ids
end

local function fix160RoadblockCount()
        local count = 0
        local res = getResourceFromName("roadblock-system")
        local root = res and getResourceRootElement(res)
        if root then
                for _, object in ipairs(getElementsByType("object", root)) do
                        if getElementData(object, "roadblock") then
                                count = count + 1
                        end
                end
        end
        return count
end

local function fix160SpikeCount()
        local count = 0
        local res = getResourceFromName("spike-system")
        local root = res and getResourceRootElement(res)
        if root then
                for _, object in ipairs(getElementsByType("object", root)) do
                        if getElementModel(object) == 2892 then
                                count = count + 1
                        end
                end
        end
        return count
end

local function fix160CleanStreets(player, cmd, arg)
        if not fix160Check(player, "admin.cleanstreets") then return end

        local streetIDs = fix160StreetItemIDs()
        local items = #streetIDs
        local rbs = fix160RoadblockCount()
        local spikes = fix160SpikeCount()

        if items == 0 and rbs == 0 and spikes == 0 then
                fix160CleanPending[player] = nil
                outputChatBox("The streets are already clean (no street items, roadblocks or spikes).", player, 0, 255, 0)
                return
        end

        if tostring(arg or ""):lower() ~= "confirm" then
                fix160CleanPending[player] = true
                setTimer(function(who)
                        if isElement(who) then fix160CleanPending[who] = nil end
                end, 30000, 1, player)
                outputChatBox("WARNING: /" .. cmd .. " removes from the street:", player, 255, 0, 0)
                outputChatBox(" * " .. items .. " dropped item(s) (worlditems, dimension 0, incl. dropped weapons)", player, 255, 194, 14)
                outputChatBox(" * " .. rbs .. " roadblock(s) and " .. spikes .. " spike strip(s)", player, 255, 194, 14)
                outputChatBox("Type /cleanstreets confirm within 30 seconds to proceed.", player, 255, 194, 14)
                return
        end

        if not fix160CleanPending[player] then
                outputChatBox("Run /cleanstreets first to see what would be removed, then type /cleanstreets confirm.", player, 255, 0, 0)
                return
        end
        fix160CleanPending[player] = nil

        -- 1) live street item objects (same id-matching pattern item-system
        --    uses in deleteAllItemsWithinInt) then 2) the rows themselves
        local idSet = {}
        for _, id in ipairs(streetIDs) do idSet[id] = true end
        local destroyed = 0
        local itemWorld = getResourceFromName("item-world")
        local itemRoot = itemWorld and getResourceRootElement(itemWorld)
        if itemRoot then
                for _, object in ipairs(getElementsByType("object", itemRoot)) do
                        local objectID = tonumber(getElementData(object, "id"))
                        if objectID and idSet[objectID] and isElement(object) then
                                destroyElement(object)
                                destroyed = destroyed + 1
                        end
                end
        end
        exports.mysql:query_free("DELETE FROM worlditems WHERE dimension = 0")

        -- 3) roadblocks + spikes (both functions log action 28 themselves,
        --    and both keep their own internal Trial Moderator+ check)
        local roadRes = fix160Running("roadblock-system")
        if roadRes then
                call(roadRes, "removeAllRoadblocks", player, cmd)
        end
        local spikeRes = fix160Running("spike-system")
        if spikeRes then
                call(spikeRes, "AdminRemovingSpikes", player, cmd)
        end
        if not canClearRoad and (rbs > 0 or spikes > 0) then
                outputChatBox("Street items were removed, but roadblocks/spikes were left: roadblock-system still asks for Trial Moderator+.",
                        player, 255, 194, 14)
        end

        fix160Log(player, 4, "/cleanstreets confirm: removed " .. items .. " street item(s) (" .. destroyed .. " live object(s)), "
                .. rbs .. " roadblock(s), " .. spikes .. " spike strip(s)")
        outputChatBox("Streets cleaned: " .. items .. " item(s), " .. rbs .. " roadblock(s), " .. spikes .. " spike strip(s) removed.",
                player, 0, 255, 0)
end
addCommandHandler("cleanstreets", fix160CleanStreets, false, false)

-- ===========================================================================
-- /showshops - right: showshops - flat list of every shop row
-- /shopitems  - right: shops.items   - the products on one shop
-- ===========================================================================
local function fix160ShowShops(player, cmd)
        if not fix160Check(player, "showshops") then return end

        local result = exports.mysql:query("SELECT s.id, s.pedName, s.shoptype, s.dimension, s.x, s.y, s.z, s.deletedBy, c.sOwner"
                .. " FROM shops s LEFT JOIN shop_contacts_info c ON s.id = c.npcID ORDER BY s.id ASC")
        if not result then
                outputChatBox("Failed to read the shops table.", player, 255, 0, 0)
                return
        end

        local total, shown = 0, 0
        while true do
                local row = exports.mysql:fetch_assoc(result)
                if not row then break end
                total = total + 1
                if shown < 20 then
                        shown = shown + 1
                        local flag = (tonumber(row.deletedBy) or 0) ~= 0 and " [deleted]" or ""
                        outputChatBox(string.format("#%s %s | type %s | dim %s | owner: %s | %.1f, %.1f, %.1f%s",
                                tostring(row.id), tostring(row.pedName or "?"), tostring(row.shoptype or "?"),
                                tostring(row.dimension or "?"), tostring(row.sOwner or "no owner contact"),
                                tonumber(row.x) or 0, tonumber(row.y) or 0, tonumber(row.z) or 0, flag),
                                player, 200, 200, 200)
                end
        end
        exports.mysql:free_result(result)
        outputChatBox("Shops: " .. total .. " total" .. (total > shown and (" (first " .. shown .. " shown)") or "") .. ".",
                player, 0, 255, 0)
end
addCommandHandler("showshops", fix160ShowShops, false, false)

local function fix160ShopItems(player, cmd, shopID)
        if not fix160Check(player, "shops.items") then return end
        shopID = tonumber(shopID)
        if not shopID then
                fix160Syntax(player, cmd, "[Shop ID]  (see /showshops)")
                return
        end

        local shop = exports.mysql:query_fetch_assoc("SELECT id, pedName FROM shops WHERE id = " .. shopID .. " LIMIT 1")
        if not shop then
                outputChatBox("Shop #" .. shopID .. " does not exist.", player, 255, 0, 0)
                return
        end

        local result = exports.mysql:query("SELECT pID, pItemID, pItemValue, pDesc, pPrice, pQuantity, pSetQuantity"
                .. " FROM shop_products WHERE npcID = " .. shopID .. " ORDER BY pID DESC")
        if not result then
                outputChatBox("Failed to read shop_products.", player, 255, 0, 0)
                return
        end

        local total, shown = 0, 0
        while true do
                local row = exports.mysql:fetch_assoc(result)
                if not row then break end
                total = total + 1
                if shown < 20 then
                        shown = shown + 1
                        local name = "?"
                        local ok, itemName = pcall(function()
                                return exports["item-system"]:getItemName(tonumber(row.pItemID), row.pItemValue)
                        end)
                        if ok and itemName then name = tostring(itemName) end
                        outputChatBox(string.format("pID %s | (%s) %s | price %s | qty %s/%s%s",
                                tostring(row.pID), tostring(row.pItemID), name, tostring(row.pPrice or "?"),
                                tostring(row.pQuantity or "?"), tostring(row.pSetQuantity or "?"),
                                (row.pDesc and row.pDesc ~= "") and (" | " .. tostring(row.pDesc)) or ""),
                                player, 200, 200, 200)
                end
        end
        exports.mysql:free_result(result)
        outputChatBox("Shop #" .. shopID .. " (" .. tostring(shop.pedName or "?") .. "): " .. total .. " product(s)"
                .. (total > shown and (" (first " .. shown .. " shown)") or "") .. ".", player, 0, 255, 0)
end
addCommandHandler("shopitems", fix160ShopItems, false, false)

-- ===========================================================================
-- /additeminshop  - right: additeminshop   - one product row
-- /additemsinshop - right: additemsinshop  - several item IDs at once
-- /shopquantity   - right: shops.changeQuantity - stock of one product
-- ===========================================================================
local function fix160ShopExists(shopID)
        return exports.mysql:query_fetch_assoc("SELECT id, pedName FROM shops WHERE id = " .. tonumber(shopID) .. " LIMIT 1")
end

local function fix160AddItemInShop(player, cmd, shopID, itemID, price, quantity, itemValue, ...)
        if not fix160Check(player, "additeminshop") then return end
        shopID, itemID, price = tonumber(shopID), tonumber(itemID), tonumber(price)
        quantity = tonumber(quantity) or 1
        if not shopID or not itemID or not price or price < 0 or quantity < 1 then
                fix160Syntax(player, cmd, "[Shop ID] [Item ID] [Price] [Quantity] [ItemValue] [Description]")
                outputChatBox("Item IDs are listed by /items (staff item list).", player, 150, 150, 50)
                return
        end

        local shop = fix160ShopExists(shopID)
        if not shop then
                outputChatBox("Shop #" .. shopID .. " does not exist.", player, 255, 0, 0)
                return
        end

        local value = itemValue
        if value == nil or value == "" then value = 1 end
        local desc = table.concat({...}, " ")
        if desc == "" then desc = "Added by " .. getPlayerName(player):gsub("_", " ") end

        local ok = exports.mysql:query_free("INSERT INTO shop_products SET npcID = " .. shopID
                .. ", pItemID = " .. itemID
                .. ", pItemValue = '" .. fix160Escape(value) .. "'"
                .. ", pPrice = '" .. fix160Escape(price) .. "'"
                .. ", pQuantity = " .. quantity
                .. ", pSetQuantity = " .. quantity
                .. ", pDesc = '" .. fix160Escape(desc) .. "'")
        if not ok then
                outputChatBox("Failed to insert the product.", player, 255, 0, 0)
                return
        end

        fix160Log(player, 4, "/additeminshop shop #" .. shopID .. " item " .. itemID .. " price " .. price .. " qty " .. quantity)
        outputChatBox("Product added to shop #" .. shopID .. " (" .. tostring(shop.pedName or "?") .. "): item "
                .. itemID .. " x" .. quantity .. " for $" .. price .. ".", player, 0, 255, 0)
end
addCommandHandler("additeminshop", fix160AddItemInShop, false, false)

local function fix160AddItemsInShop(player, cmd, shopID, price, quantity, itemIDs)
        if not fix160Check(player, "additemsinshop") then return end
        shopID, price, quantity = tonumber(shopID), tonumber(price), tonumber(quantity) or 1
        if not shopID or not price or not itemIDs or itemIDs == "" then
                fix160Syntax(player, cmd, "[Shop ID] [Price] [Quantity] [ItemID,ItemID,...]")
                outputChatBox("Example: /additemsinshop 7 250 5 1,2,3", player, 150, 150, 50)
                return
        end

        local shop = fix160ShopExists(shopID)
        if not shop then
                outputChatBox("Shop #" .. shopID .. " does not exist.", player, 255, 0, 0)
                return
        end

        local added = 0
        for _, chunk in ipairs(split(itemIDs, ",")) do
                local itemID = tonumber(chunk)
                if itemID then
                        local ok = exports.mysql:query_free("INSERT INTO shop_products SET npcID = " .. shopID
                                .. ", pItemID = " .. itemID
                                .. ", pItemValue = '1'"
                                .. ", pPrice = '" .. fix160Escape(price) .. "'"
                                .. ", pQuantity = " .. quantity
                                .. ", pSetQuantity = " .. quantity
                                .. ", pDesc = 'Added by " .. fix160Escape(getPlayerName(player)) .. "'")
                        if ok then added = added + 1 end
                end
        end

        if added == 0 then
                outputChatBox("No valid Item ID found in '" .. tostring(itemIDs) .. "'.", player, 255, 0, 0)
                return
        end
        fix160Log(player, 4, "/additemsinshop shop #" .. shopID .. " price " .. price .. " qty " .. quantity .. " -> " .. added .. " product(s)")
        outputChatBox(added .. " product(s) added to shop #" .. shopID .. " (" .. tostring(shop.pedName or "?") .. ").",
                player, 0, 255, 0)
end
addCommandHandler("additemsinshop", fix160AddItemsInShop, false, false)

local function fix160ShopQuantity(player, cmd, shopID, productID, quantity)
        if not fix160Check(player, "shops.changeQuantity") then return end
        shopID, productID, quantity = tonumber(shopID), tonumber(productID), tonumber(quantity)
        if not shopID or not productID or not quantity or quantity < 0 then
                fix160Syntax(player, cmd, "[Shop ID] [Product ID] [Quantity]   (IDs: /shopitems)")
                return
        end

        local product = exports.mysql:query_fetch_assoc("SELECT pID FROM shop_products WHERE pID = " .. productID
                .. " AND npcID = " .. shopID .. " LIMIT 1")
        if not product then
                outputChatBox("Product #" .. productID .. " does not belong to shop #" .. shopID .. ".", player, 255, 0, 0)
                return
        end

        if not exports.mysql:query_free("UPDATE shop_products SET pQuantity = " .. quantity
                .. ", pSetQuantity = " .. quantity .. " WHERE pID = " .. productID .. " AND npcID = " .. shopID) then
                outputChatBox("Failed to update the quantity.", player, 255, 0, 0)
                return
        end

        fix160Log(player, 4, "/shopquantity shop #" .. shopID .. " pID #" .. productID .. " -> " .. quantity)
        outputChatBox("Product #" .. productID .. " (shop #" .. shopID .. ") stock set to " .. quantity .. ".",
                player, 0, 255, 0)
end
addCommandHandler("shopquantity", fix160ShopQuantity, false, false)

-- ===========================================================================
-- /getshopowner - right: shops.getowner
-- /setshopowner - right: shops.setowner   (shop_contacts_info.sOwner)
-- ===========================================================================
local function fix160GetShopOwner(player, cmd, shopID)
        if not fix160Check(player, "shops.getowner") then return end
        shopID = tonumber(shopID)
        if not shopID then
                fix160Syntax(player, cmd, "[Shop ID]  (see /showshops)")
                return
        end

        local shop = exports.mysql:query_fetch_assoc("SELECT s.id, s.pedName, s.shoptype, s.dimension, c.sOwner, c.sPhone, c.sEmail, c.sForum"
                .. " FROM shops s LEFT JOIN shop_contacts_info c ON s.id = c.npcID WHERE s.id = " .. shopID .. " LIMIT 1")
        if not shop then
                outputChatBox("Shop #" .. shopID .. " does not exist.", player, 255, 0, 0)
                return
        end

        outputChatBox("Shop #" .. shop.id .. " (" .. tostring(shop.pedName or "?") .. "), type "
                .. tostring(shop.shoptype or "?") .. ", dim " .. tostring(shop.dimension or "?") .. ":", player, 255, 194, 14)
        if shop.sOwner and shop.sOwner ~= "" then
                outputChatBox("  owner contact: " .. tostring(shop.sOwner), player, 200, 200, 200)
                outputChatBox("  phone: " .. tostring(shop.sPhone ~= "" and shop.sPhone or "-")
                        .. " | e-mail: " .. tostring(shop.sEmail ~= "" and shop.sEmail or "-")
                        .. " | forum: " .. tostring(shop.sForum ~= "" and shop.sForum or "-"), player, 200, 200, 200)
        else
                outputChatBox("  no owner contact recorded (shop_contacts_info row missing).", player, 200, 200, 200)
        end
end
addCommandHandler("getshopowner", fix160GetShopOwner, false, false)

local function fix160SetShopOwner(player, cmd, shopID, ...)
        if not fix160Check(player, "shops.setowner") then return end
        shopID = tonumber(shopID)
        local owner = table.concat({...}, " ")
        if not shopID or owner == "" then
                fix160Syntax(player, cmd, "[Shop ID] [Owner Name]")
                return
        end

        local shop = fix160ShopExists(shopID)
        if not shop then
                outputChatBox("Shop #" .. shopID .. " does not exist.", player, 255, 0, 0)
                return
        end

        local existing = exports.mysql:query_fetch_assoc("SELECT npcID FROM shop_contacts_info WHERE npcID = " .. shopID .. " LIMIT 1")
        local ok
        if existing then
                ok = exports.mysql:query_free("UPDATE shop_contacts_info SET sOwner = '" .. fix160Escape(owner)
                        .. "' WHERE npcID = " .. shopID)
        else
                ok = exports.mysql:query_free("INSERT INTO shop_contacts_info SET npcID = " .. shopID
                        .. ", sOwner = '" .. fix160Escape(owner) .. "'")
        end
        if not ok then
                outputChatBox("Failed to save the owner contact.", player, 255, 0, 0)
                return
        end

        fix160Log(player, 4, "/setshopowner shop #" .. shopID .. " -> " .. owner)
        outputChatBox("Shop #" .. shopID .. " owner contact set to '" .. owner .. "'.", player, 0, 255, 0)
end
addCommandHandler("setshopowner", fix160SetShopOwner, false, false)

-- ===========================================================================
-- /setintowner    - right: setintowner
-- /removeintowner - right: removeintowner
-- /getpropertyowner - right: property.getowner
-- ===========================================================================
local function fix160ResolveInterior(player, cmd, intArg)
        local intID = tonumber(intArg)
        if not intID then
                fix160Syntax(player, cmd, "[Interior ID] ...")
                return nil
        end
        local row = exports.mysql:query_fetch_assoc("SELECT id, owner, faction, type, name, locked FROM interiors WHERE id = " .. intID .. " LIMIT 1")
        if not row then
                outputChatBox("Interior #" .. intID .. " does not exist.", player, 255, 0, 0)
                return nil
        end
        return intID, row
end

local function fix160SetIntOwner(player, cmd, intArg, ownerArg)
        if not fix160Check(player, "setintowner") then return end
        local intID, row = fix160ResolveInterior(player, cmd, intArg)
        if not intID then return end
        if not ownerArg or ownerArg == "" then
                fix160Syntax(player, cmd, "[Interior ID] [Character ID / Player]")
                return
        end

        local target, targetName = nil, nil
        local charID = tonumber(ownerArg)
        if charID then
                local char = exports.mysql:query_fetch_assoc("SELECT id, charactername FROM characters WHERE id = " .. charID .. " LIMIT 1")
                if not char then
                        outputChatBox("Character ID " .. charID .. " does not exist.", player, 255, 0, 0)
                        return
                end
                targetName = char.charactername
        else
                target = exports.global:findPlayerByPartialNick(player, ownerArg)
                if not target or not isElement(target) then
                        outputChatBox("Character/player '" .. tostring(ownerArg) .. "' was not found.", player, 255, 0, 0)
                        return
                end
                charID = tonumber(getElementData(target, "dbid"))
                targetName = getPlayerName(target):gsub("_", " ")
                if not charID then
                        outputChatBox("That player has no character ID yet.", player, 255, 0, 0)
                        return
                end
        end

        local previous = tonumber(row.owner) or -1
        if not exports.mysql:query_free("UPDATE interiors SET owner = '" .. charID .. "', faction = 0, locked = 0, lastused = NOW() WHERE id = " .. intID) then
                outputChatBox("Failed to update the interiors row.", player, 255, 0, 0)
                return
        end

        -- keys: drop the old owner's keys, hand one to the new owner if online
        local itemRes = fix160Running("item-system")
        if itemRes then
                call(itemRes, "deleteAll", 4, intID)
                call(itemRes, "deleteAll", 5, intID)
        end
        local keytype = (tonumber(row.type) == 1) and 5 or 4
        if target and isElement(target) then
                exports.global:giveItem(target, keytype, intID)
                outputChatBox("You are now the owner of interior #" .. intID .. ".", target, 0, 255, 0)
        end

        -- refresh the live element so the door/F1 see the new owner at once
        local _, _, _, _, intElement = exports["interior-system"]:findProperty(false, intID)
        if intElement and isElement(intElement) then
                local status = getElementData(intElement, "status")
                if type(status) == "table" then
                        status[FIX160_INTERIOR_OWNER] = charID
                        status[FIX160_INTERIOR_LOCKED] = false
                        exports.anticheat:changeProtectedElementDataEx(intElement, "status", status, false)
                end
        end

        fix160Log(player, 37, "/setintowner #" .. intID .. " -> " .. tostring(targetName or charID)
                .. " (was character " .. previous .. ")")
        exports["interior-manager"]:addInteriorLogs(intID, cmd .. " " .. tostring(targetName or charID), player)
        outputChatBox("Interior #" .. intID .. " owner set to " .. tostring(targetName or charID)
                .. " (character " .. charID .. ", was " .. previous .. ").", player, 0, 255, 0)
end
addCommandHandler("setintowner", fix160SetIntOwner, false, false)

local function fix160RemoveIntOwner(player, cmd, intArg)
        if not fix160Check(player, "removeintowner") then return end
        local intID, row = fix160ResolveInterior(player, cmd, intArg)
        if not intID then return end

        local previous = tonumber(row.owner) or -1
        local ok, err = exports["interior-system"]:unownProperty(intID, "Removed by " .. getPlayerName(player):gsub("_", " "))
        if not ok then
                outputChatBox("Failed to remove the owner: " .. tostring(err), player, 255, 0, 0)
                return
        end

        local _, _, _, _, intElement = exports["interior-system"]:findProperty(false, intID)
        if intElement and isElement(intElement) then
                local status = getElementData(intElement, "status")
                if type(status) == "table" then
                        status[FIX160_INTERIOR_OWNER] = -1
                        status[FIX160_INTERIOR_LOCKED] = true
                        exports.anticheat:changeProtectedElementDataEx(intElement, "status", status, false)
                end
        end

        fix160Log(player, 37, "/removeintowner #" .. intID .. " (was character " .. previous .. ")")
        exports["interior-manager"]:addInteriorLogs(intID, cmd .. " (was character " .. previous .. ")", player)
        outputChatBox("Interior #" .. intID .. " is now unowned (was character " .. previous .. "), keys destroyed.",
                player, 0, 255, 0)
end
addCommandHandler("removeintowner", fix160RemoveIntOwner, false, false)

local function fix160GetPropertyOwner(player, cmd, intArg)
        if not fix160Check(player, "property.getowner") then return end
        local intID, row = fix160ResolveInterior(player, cmd, intArg)
        if not intID then return end

        local ownerText = "none (for sale / unowned)"
        local owner = tonumber(row.owner) or -1
        if owner > 0 then
                local char = exports.mysql:query_fetch_assoc("SELECT charactername FROM characters WHERE id = " .. owner .. " LIMIT 1")
                ownerText = char and (tostring(char.charactername) .. " (character " .. owner .. ")")
                        or ("character " .. owner .. " (deleted?)")
        end
        local faction = tonumber(row.faction) or 0
        if faction > 0 then
                local fac = exports.mysql:query_fetch_assoc("SELECT name FROM factions WHERE id = " .. faction .. " LIMIT 1")
                ownerText = (fac and tostring(fac.name) or ("faction " .. faction)) .. " (faction " .. faction .. ")"
        end

        outputChatBox("Interior #" .. intID .. " '" .. tostring(row.name or "-") .. "' (type "
                .. tostring(row.type or "?") .. "):", player, 255, 194, 14)
        outputChatBox("  owner: " .. ownerText, player, 200, 200, 200)
        outputChatBox("  state: " .. ((tonumber(row.locked) or 0) == 1 and "locked" or "unlocked"), player, 200, 200, 200)
end
addCommandHandler("getpropertyowner", fix160GetPropertyOwner, false, false)

-- ===========================================================================
-- /delped  - right: delped   (ped-system deletePed - legacy Moderator+ inside)
-- /editped - right: editped  (opens the ped edit GUI, legacy check inside)
-- ===========================================================================
local function fix160FindPed(player, arg)
        if not arg or arg == "" or arg == "nearest" then
                local px, py, pz = getElementPosition(player)
                local best, bestDist = nil, 25
                for _, ped in ipairs(getElementsByType("ped")) do
                        local x, y, z = getElementPosition(ped)
                        local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
                        if dist < bestDist then
                                best, bestDist = ped, dist
                        end
                end
                if not best then
                        outputChatBox("No ped within 25m of you.", player, 255, 0, 0)
                end
                return best, bestDist
        end

        local pedID = tonumber(arg)
        if not pedID then
                outputChatBox("Ped ID must be a number (or 'nearest').", player, 255, 0, 0)
                return nil
        end
        for _, ped in ipairs(getElementsByType("ped")) do
                local id = tonumber(getElementData(ped, "rpp.npc.dbid")) or tonumber(getElementData(ped, "dbid"))
                if id == pedID then return ped, 0 end
        end
        outputChatBox("Ped #" .. pedID .. " is not loaded.", player, 255, 0, 0)
        return nil
end

local function fix160DelPed(player, cmd, arg)
        if not fix160Check(player, "delped") then return end
        local ped, dist = fix160FindPed(player, arg)
        if not ped then return end

        if getElementData(ped, "ped:type") == "shop" then
                outputChatBox("That is a shop NPC - use /delshop (shops.manager) instead.", player, 255, 194, 14)
                return
        end


        local res = fix160Running("ped-system")
        if not res then
                outputChatBox("ped-system is not running.", player, 255, 0, 0)
                return
        end

        local pedName = tostring(getElementData(ped, "rpp.npc.name") or getElementData(ped, "name") or "Unnamed")
        call(res, "deletePed", player, ped)
        fix160Log(player, 4, "/delped " .. pedName .. " at " .. string.format("%.1fm", dist or 0))
        outputChatBox("Ped '" .. pedName .. "' deleted.", player, 0, 255, 0)
end
addCommandHandler("delped", fix160DelPed, false, false)

local function fix160EditPed(player, cmd, arg)
        if not fix160Check(player, "editped") then return end
        local ped, dist = fix160FindPed(player, arg)
        if not ped then return end

        if getElementData(ped, "ped:type") == "shop" then
                outputChatBox("That is a shop NPC - use the shop commands (/renameshop, /moveshop...) instead.",
                        player, 255, 194, 14)
                return
        end


        triggerClientEvent(player, "peds:adminEdit", player, ped)
        fix160Log(player, 4, "/editped " .. (getElementData(ped, "rpp.npc.dbid") or "?") .. " at "
                .. string.format("%.1fm", dist or 0))
end
addCommandHandler("editped", fix160EditPed, false, false)

-- ===========================================================================
-- /setelevforveh    - right: elevator.setelevforveh    (car mode, default 1)
-- /setelevforplayer - right: elevator.setelevforplayer (car mode, default 0)
-- car modes: 0 players only | 1 players + vehicles | 2 vehicles only | 3 none
-- ===========================================================================
local FIX160_ELEVATOR_MODES = {
        [0] = "players only",
        [1] = "players and vehicles",
        [2] = "vehicles only",
        [3] = "no entrance",
}

local function fix160SetElevatorMode(player, cmd, right, defaultMode, elevArg, modeArg)
        if not fix160Check(player, right) then return end
        local elevID = tonumber(elevArg)
        if not elevID then
                fix160Syntax(player, cmd, "[Elevator ID] [Mode 0-3]  (mode defaults to " .. defaultMode .. ")")
                return
        end
        local mode = tonumber(modeArg)
        if mode == nil then
                mode = defaultMode
        end
        if mode < 0 or mode > 3 or mode % 1 ~= 0 then
                outputChatBox("Mode must be a whole number between 0 and 3.", player, 255, 0, 0)
                return
        end

        local found, _, _, status, elevElement = exports["elevator-system"]:findElevator(elevID)
        if not found or found == 0 or not elevElement then
                outputChatBox("Elevator #" .. elevID .. " was not found (not loaded).", player, 255, 0, 0)
                return
        end

        if not exports.mysql:query_free("UPDATE elevators SET car = " .. mode .. " WHERE id = " .. elevID) then
                outputChatBox("Failed to update the elevators row.", player, 255, 0, 0)
                return
        end
        if type(status) == "table" then
                status[1] = mode
                exports.anticheat:changeProtectedElementDataEx(elevElement, "status", status, false)
        end

        fix160Log(player, 4, "/" .. cmd .. " #" .. elevID .. " -> mode " .. mode .. " (" .. FIX160_ELEVATOR_MODES[mode] .. ")")
        outputChatBox("Elevator #" .. elevID .. " mode set to " .. mode .. " (" .. FIX160_ELEVATOR_MODES[mode] .. ").",
                player, 0, 255, 0)
end

addCommandHandler("setelevforveh", function(player, cmd, elevID, mode)
        fix160SetElevatorMode(player, cmd, "elevator.setelevforveh", 1, elevID, mode)
end, false, false)

addCommandHandler("setelevforplayer", function(player, cmd, elevID, mode)
        fix160SetElevatorMode(player, cmd, "elevator.setelevforplayer", 0, elevID, mode)
end, false, false)

-- ===========================================================================
-- /radiostations - right: radiostations.manager - opens the Radio Station
-- Manager (carradio server event openRadioManager, the same one /radios uses)
-- ===========================================================================
local function fix160RadioStations(player, cmd)
        if not fix160Check(player, "radiostations.manager") then return end
        if not fix160Running("carradio") then
                outputChatBox("carradio is not running.", player, 255, 0, 0)
                return
        end
        triggerEvent("openRadioManager", player, player)
        fix160Log(player, 4, "/radiostations - opened the Radio Station Manager")
end
addCommandHandler("radiostations", fix160RadioStations, false, false)

-- ===========================================================================
-- /vehtextures - right: Textures - list / add / remove vehicle textures
-- (same data the ADM:Textures right-click GUI writes: vehicles.textures +
--  item-texture streaming)
-- ===========================================================================
local function fix160Vehicle(player, vehArg)
        local vehID = tonumber(vehArg)
        if not vehID then return nil, nil end
        local veh = exports.pool:getElement("vehicle", vehID)
        if not veh or not isElement(veh) then return nil, vehID end
        return veh, vehID
end

local function fix160SaveVehicleTextures(veh, vehID, textures)
        if vehID and vehID > 0 then
                exports.mysql:query_free("UPDATE vehicles SET textures = '" .. fix160Escape(toJSON(textures))
                        .. "' WHERE id = " .. vehID)
        end
        exports.anticheat:changeProtectedElementDataEx(veh, "textures", textures, true)
end

local function fix160VehTextures(player, cmd, sub, vehArg, a, b)
        if not fix160Check(player, "Textures") then return end
        sub = tostring(sub or ""):lower()

        if sub == "" or sub == "list" or tonumber(sub) then
                local veh, vehID = fix160Vehicle(player, sub == "list" and vehArg or sub)
                if not veh then
                        fix160Syntax(player, cmd, "list [Vehicle ID]")
                        outputChatBox("       " .. cmd .. " add [Vehicle ID] [Texture Name] [URL]", player, 150, 150, 50)
                        outputChatBox("       " .. cmd .. " del [Vehicle ID] [Texture Name]", player, 150, 150, 50)
                        if vehID then outputChatBox("Vehicle #" .. vehID .. " was not found.", player, 255, 0, 0) end
                        return
                end
                local textures = getElementData(veh, "textures")
                if type(textures) ~= "table" or #textures == 0 then
                        outputChatBox("Vehicle #" .. vehID .. " has no custom textures.", player, 255, 194, 14)
                        return
                end
                outputChatBox("Vehicle #" .. vehID .. " textures (" .. #textures .. "):", player, 255, 194, 14)
                for index, texture in ipairs(textures) do
                        outputChatBox(" " .. index .. ". " .. tostring(texture[1]) .. " -> " .. tostring(texture[2]),
                                player, 200, 200, 200)
                end
                return
        end

        if sub == "add" then
                if not a or not b then
                        fix160Syntax(player, cmd, "add [Vehicle ID] [Texture Name] [URL]")
                        return
                end
                local veh, vehID = fix160Vehicle(player, vehArg)
                if not veh then
                        outputChatBox("Vehicle #" .. tostring(vehArg) .. " was not found.", player, 255, 0, 0)
                        return
                end
                local textures = getElementData(veh, "textures")
                if type(textures) ~= "table" then textures = {} end
                table.insert(textures, { a, b })
                fix160SaveVehicleTextures(veh, vehID, textures)
                local texRes = fix160Running("item-texture")
                if texRes then
                        call(texRes, "addTexture", veh, a, b)
                end
                fix160Log(player, 4, "/vehtextures add #" .. vehID .. " " .. a .. " " .. b)
                outputChatBox("Texture '" .. a .. "' applied to vehicle #" .. vehID .. ".", player, 0, 255, 0)
                return
        end

        if sub == "del" or sub == "remove" or sub == "delete" then
                if not a then
                        fix160Syntax(player, cmd, "del [Vehicle ID] [Texture Name]")
                        return
                end
                local veh, vehID = fix160Vehicle(player, vehArg)
                if not veh then
                        outputChatBox("Vehicle #" .. tostring(vehArg) .. " was not found.", player, 255, 0, 0)
                        return
                end
                local textures = getElementData(veh, "textures")
                if type(textures) ~= "table" then textures = {} end
                local removed = false
                for index, texture in ipairs(textures) do
                        if tostring(texture[1]):lower() == tostring(a):lower() then
                                table.remove(textures, index)
                                removed = true
                                break
                        end
                end
                if not removed then
                        outputChatBox("Vehicle #" .. vehID .. " has no texture named '" .. a .. "'.", player, 255, 0, 0)
                        return
                end
                fix160SaveVehicleTextures(veh, vehID, textures)
                local texRes = fix160Running("item-texture")
                if texRes then
                        call(texRes, "removeTexture", veh, a)
                end
                fix160Log(player, 4, "/vehtextures del #" .. vehID .. " " .. a)
                outputChatBox("Texture '" .. a .. "' removed from vehicle #" .. vehID .. ".", player, 0, 255, 0)
                return
        end

        fix160Syntax(player, cmd, "list|add|del ...")
        outputChatBox("       " .. cmd .. " list [Vehicle ID] | add [Vehicle ID] [Texture Name] [URL] | del [Vehicle ID] [Texture Name]",
                player, 150, 150, 50)
end
addCommandHandler("vehtextures", fix160VehTextures, false, false)

-- ===========================================================================
-- /givebc /takebc /checkbc /giveallbc - rights bc.givebc/takebc/checkbc/
-- giveallbc - the Briefcase item (item-system g_items 160), the item the
-- briefcase attach script is built around.
-- ===========================================================================
local function fix160GiveBC(player, cmd, targetArg)
        if not fix160Check(player, "bc.givebc") then return end
        local target = fix160Target(player, cmd, targetArg)
        if not target then return end

        if exports["item-system"]:hasItem(target, FIX160_BRIEFCASE_ITEM) then
                outputChatBox(getPlayerName(target):gsub("_", " ") .. " already carries a briefcase.", player, 255, 194, 14)
                return
        end
        if not exports.global:giveItem(target, FIX160_BRIEFCASE_ITEM, 1) then
                outputChatBox("Their inventory is full.", player, 255, 0, 0)
                return
        end

        fix160Log(player, 4, "/givebc -> " .. getPlayerName(target):gsub("_", " "))
        outputChatBox("Briefcase given to " .. getPlayerName(target):gsub("_", " ") .. ".", player, 0, 255, 0)
        outputChatBox("You were given a briefcase by staff.", target, 0, 255, 0)
end
addCommandHandler("givebc", fix160GiveBC, false, false)

local function fix160TakeBC(player, cmd, targetArg)
        if not fix160Check(player, "bc.takebc") then return end
        local target = fix160Target(player, cmd, targetArg)
        if not target then return end

        if not exports["item-system"]:hasItem(target, FIX160_BRIEFCASE_ITEM) then
                outputChatBox(getPlayerName(target):gsub("_", " ") .. " carries no briefcase.", player, 255, 194, 14)
                return
        end
        exports["item-system"]:takeItem(target, FIX160_BRIEFCASE_ITEM)

        fix160Log(player, 4, "/takebc -> " .. getPlayerName(target):gsub("_", " "))
        outputChatBox("Briefcase taken from " .. getPlayerName(target):gsub("_", " ") .. ".", player, 0, 255, 0)
        outputChatBox("Your briefcase was removed by staff.", target, 255, 194, 14)
end
addCommandHandler("takebc", fix160TakeBC, false, false)

local function fix160CheckBC(player, cmd, targetArg)
        if not fix160Check(player, "bc.checkbc") then return end
        local target = fix160Target(player, cmd, targetArg)
        if not target then return end

        local has = exports["item-system"]:hasItem(target, FIX160_BRIEFCASE_ITEM)
        outputChatBox(getPlayerName(target):gsub("_", " ") .. (has and " carries a briefcase (item "
                .. FIX160_BRIEFCASE_ITEM .. ")." or " carries NO briefcase."), player, has and 0 or 255, has and 255 or 0, 0)
        fix160Log(player, 4, "/checkbc " .. getPlayerName(target):gsub("_", " ") .. " -> " .. (has and "yes" or "no"))
end
addCommandHandler("checkbc", fix160CheckBC, false, false)

local function fix160GiveAllBC(player, cmd)
        if not fix160Check(player, "bc.giveallbc") then return end

        local given, skipped = 0, 0
        for _, target in ipairs(getElementsByType("player")) do
                if exports["item-system"]:hasItem(target, FIX160_BRIEFCASE_ITEM) then
                        skipped = skipped + 1
                elseif exports.global:giveItem(target, FIX160_BRIEFCASE_ITEM, 1) then
                        given = given + 1
                        outputChatBox("You were given a briefcase by staff.", target, 0, 255, 0)
                end
        end

        fix160Log(player, 4, "/giveallbc -> " .. given .. " briefcase(s), " .. skipped .. " already had one")
        outputChatBox("Briefcases given to " .. given .. " player(s) (" .. skipped .. " already had one).",
                player, 0, 255, 0)
end
addCommandHandler("giveallbc", fix160GiveAllBC, false, false)

-- ===========================================================================
-- /edithelp     - right: edithelp     - opens the command-help editor GUI
--                 (help resource sendCmdsHelpToClient with forceOpen)
-- /editcommands - right: editcommands - chat editor for the `commands` help
--                 rows (list / add / set / del)
-- ===========================================================================
local function fix160EditHelp(player, cmd)
        if not fix160Check(player, "edithelp") then return end
        local res = fix160Running("help")
        if not res then
                outputChatBox("The help resource is not running.", player, 255, 0, 0)
                return
        end
        call(res, "sendCmdsHelpToClient", player, true)
        fix160Log(player, 4, "/edithelp - opened the command help editor")
        outputChatBox("Command help opened in editor mode (the Edit tab needs Trial Moderator+ or Support).",
                player, 0, 255, 0)
end
addCommandHandler("edithelp", fix160EditHelp, false, false)

local function fix160EditCommands(player, cmd, sub, ...)
        if not fix160Check(player, "editcommands") then return end
        sub = tostring(sub or ""):lower()
        local args = {...}

        if sub == "list" then
                local filter = tostring(args[1] or "")
                local query = "SELECT id, command, category, permission FROM commands"
                if filter ~= "" then
                        query = query .. " WHERE command LIKE '%" .. fix160Escape(filter) .. "%'"
                end
                query = query .. " ORDER BY id DESC LIMIT 15"
                local result = exports.mysql:query(query)
                if not result then
                        outputChatBox("Failed to read the commands table.", player, 255, 0, 0)
                        return
                end
                local total = 0
                while true do
                        local row = exports.mysql:fetch_assoc(result)
                        if not row then break end
                        total = total + 1
                        outputChatBox(string.format("[%s] cat %s / perm %s: %s", tostring(row.id),
                                tostring(row.category), tostring(row.permission), tostring(row.command)),
                                player, 200, 200, 200)
                end
                exports.mysql:free_result(result)
                outputChatBox(total .. " help entr" .. (total == 1 and "y" or "ies") .. " listed.", player, 0, 255, 0)
                return
        end

        if sub == "add" then
                local category, commandName = args[1], args[2]
                local explanation = table.concat({ select(3, unpack(args)) }, " ")
                category = tonumber(category)
                if not category or not commandName or commandName == "" or explanation == "" then
                        fix160Syntax(player, cmd, "add [category] [command] [explanation]")
                        outputChatBox("Categories: 1 Chat, 2 Factions, 3 Vehicles, 4 Properties, 5 Items, 6 Jobs, 7 Admin.",
                                player, 150, 150, 50)
                        return
                end
                if not exports.mysql:query_free("INSERT INTO commands SET category = " .. category
                        .. ", permission = 0, command = '" .. fix160Escape(commandName)
                        .. "', hotkey = 'N/A', explanation = '" .. fix160Escape(explanation) .. "'") then
                        outputChatBox("Failed to insert the help entry.", player, 255, 0, 0)
                        return
                end
                fix160Log(player, 4, "/editcommands add " .. commandName .. " (category " .. category .. ")")
                outputChatBox("Help entry added: " .. commandName, player, 0, 255, 0)
                return
        end

        if sub == "set" then
                local id, field, value = tonumber(args[1]), tostring(args[2] or ""):lower(),
                        table.concat({ select(3, unpack(args)) }, " ")
                local allowed = { command = true, hotkey = true, explanation = true, category = true, permission = true }
                if not id or not allowed[field] or value == "" then
                        fix160Syntax(player, cmd, "set [ID] [command|hotkey|explanation|category|permission] [value]")
                        outputChatBox("List IDs with /editcommands list.", player, 150, 150, 50)
                        return
                end
                local stored = value
                if field == "category" or field == "permission" then
                        local number = tonumber(value)
                        if not number then
                                outputChatBox(field .. " must be a number.", player, 255, 0, 0)
                                return
                        end
                        stored = number
                end
                if not exports.mysql:query_free("UPDATE commands SET `" .. field .. "` = '"
                        .. fix160Escape(stored) .. "' WHERE id = " .. id) then
                        outputChatBox("Failed to update the help entry.", player, 255, 0, 0)
                        return
                end
                fix160Log(player, 4, "/editcommands set #" .. id .. " " .. field .. " = " .. value)
                outputChatBox("Help entry #" .. id .. ": " .. field .. " set to '" .. value .. "'.", player, 0, 255, 0)
                return
        end

        if sub == "del" or sub == "delete" then
                local id = tonumber(args[1])
                if not id then
                        fix160Syntax(player, cmd, "del [ID]     (list IDs with /editcommands list)")
                        return
                end
                local row = exports.mysql:query_fetch_assoc("SELECT id, command FROM commands WHERE id = " .. id .. " LIMIT 1")
                if not row then
                        outputChatBox("Help entry #" .. id .. " does not exist.", player, 255, 0, 0)
                        return
                end
                if not exports.mysql:query_free("DELETE FROM commands WHERE id = " .. id) then
                        outputChatBox("Failed to delete the help entry.", player, 255, 0, 0)
                        return
                end
                fix160Log(player, 4, "/editcommands del #" .. id .. " " .. tostring(row.command))
                outputChatBox("Help entry #" .. id .. " ('" .. tostring(row.command) .. "') deleted.", player, 0, 255, 0)
                return
        end

        fix160Syntax(player, cmd, "list [filter] | add [cat] [cmd] [text] | set [ID] [field] [value] | del [ID]")
end
addCommandHandler("editcommands", fix160EditCommands, false, false)
