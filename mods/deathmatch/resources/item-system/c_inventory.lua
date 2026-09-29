--[[ =========================================================================
        c_inventory.lua — Vortex INVENTORY (Fix #37, MOD 2 part 1)

        1:1 visual port of the OLD CLIENT bag (backupm [rp]/inventory-system):
          * fullscreen dark backdrop, rounded (0,8,20,225) panels with a white 25
            edge, bottom accent line
          * 6-slot grid, empty tiles (27,37,49), white 10-alpha slot border that
            brightens to 100 on hover + white underline, xN / $ value badges
          * header: "Inventory" left, "#ff375f weight / max" right (colorCoded)
          * FOOTER: character info row + money row (green $, money icon) — the old
            client showed the local money inside the bag
          * bottom-centre DELETE CIRCLE (drag an item onto it to destroy it)
          * add/remove item toasts (green/red rounded squares, 5s, stacked)
          * dark (40,40,40,230) tooltip above the hovered slot
          * right-click (or short left-click) = USE, drag out = drop to world,
            drag onto element = move, drag to bin = destroy

        BACKEND UNCHANGED: OwlGaming items (getItems/useItem/dropItem/
        moveToElement/destroyItem/showItem server events + g_items helpers), so
        every /giveitem, shop, safe, vehicle and faction flow keeps working.
========================================================================= ]]

local sx, sy = guiGetScreenSize()
local scale = sy / 1080
local localPlayer = getLocalPlayer()

-- old client palette -------------------------------------------------------
-- [Fix #54 - user] تخفيف التغميق: the backdrop used to run 235->197 (nearly
-- opaque); 140->102 keeps the panel readable while the world stays visible.
local COL_BACKDROP_A = 140
local COL_PANEL      = tocolor(0, 8, 20, 225)
local COL_PANEL_EDGE = tocolor(255, 255, 255, 25)
local COL_SLOT_OUT   = tocolor(255, 255, 255, 10)
local COL_SLOT_OUT_H = tocolor(255, 255, 255, 100)
local COL_SLOT_IN    = tocolor(0, 8, 20, 230)
local COL_SLOT_EMPTY = tocolor(27, 37, 49, 255)
local COL_ACCENT     = tocolor(255, 255, 255, 50)
local COL_ACCENT_HI  = tocolor(255, 255, 255, 200)
local COL_TOOLTIP_BG = tocolor(40, 40, 40, 230)
local COL_MONEY      = tocolor(0, 255, 0, 210)
local COL_BADGE_BG   = tocolor(0, 0, 0, 240)
local COL_DRAG_BG    = tocolor(10, 10, 10, 180)
local COL_MOVE_OK    = tocolor(0, 250, 0, 40)
local COL_MOVE_NO    = tocolor(255, 0, 0, 127)

local splittableItem = { [30]=" gram(s)", [31]=" gram(s)", [32]=" gram(s)", [33]=" gram(s)", [34]=" gram(s)", [35]=" ml(s)", [36]=" tablet(s)", [37]=" gram(s)", [38]=" gram(s)", [39]=" gram(s)", [40]=" ml(s)", [41]=" tab(s)", [42]=" shroom(s)", [43]=" tablet(s)", [134] = " money" }
local calibreWeapons = { [22]=true, [23]=true, [24]=true, [25]=true, [26]=true, [27]=true, [28]=true, [29]=true, [30]=true, [31]=true, [32]=true, [33]=true, [34]=true }

-- geometry (old client proportions) ----------------------------------------
local COLS = 6
local SLOT = math.floor(62 * scale)
local GAP = 2
local PITCH = SLOT + GAP
local HEADER_H = math.floor(40 * scale)
local FOOTER_H = math.floor(66 * scale)
local PANEL_MARGIN_X = math.floor(50 * scale)
local PANEL_Y = math.floor(120 * scale)

-- state ---------------------------------------------------------------------
waitingForItemDrop = false
local savedArmor = false
local show = false
local inventory = false          -- flat slot entries { itemID, itemValue, index, arrIndex, false }
local snapshot = nil             -- last recieveItems signature (for add/remove toasts)
local hoverItemSlot = false      -- { x, y, slot }
local clickItemSlot = false
local clickDown = false
local hoverDelete = false
local hoverElement = false
local clickWorldItem = false
local hoverWorldItem = false
local cursorOverPanel = false

local notifications = {}

local COL_RUBBISH = { [1331]=true,[1332]=true,[1333]=true,[1334]=true,[1335]=true,[1336]=true,[1337]=true,[1339]=true,[1343]=true,[1344]=true,[1345]=true,[1347]=true,[1359]=true,[1365]=true,[1372]=true,[1439]=true,[1409]=true,[1415]=true,[1430]=true,[1574]=true,[933]=true,[1235]=true }

function explode(div, str)
        if (div == '') then return false end
        local pos, arr = 0, {}
        for st, sp in function() return string.find(str, div, pos, true) end do
                table.insert(arr, string.sub(str, pos, st - 1))
                pos = sp + 1
        end
        table.insert(arr, string.sub(str, pos))
        return arr
end

local function isMouseInPosition(x, y, w, h)
        if not isCursorShowing() then return false end
        local cx, cy = getCursorPosition()
        cx, cy = cx * sx, cy * sy
        return cx >= x and cy >= y and cx <= x + w and cy <= y + h
end

-- old client rounded rectangle (corner circles, postGUI)
local function dxDrawRoundedRectangle(x, y, w, h, color, radius, postGUI)
        radius = radius or 6
        local rw, rh = w - radius * 2, h - radius * 2
        local rx, ry = math.floor(x + radius), math.floor(y + radius)
        dxDrawRectangle(rx - radius, ry, rw + radius * 2, rh, color, postGUI)
        dxDrawRectangle(rx, ry - radius, rw, radius, color, postGUI)
        dxDrawRectangle(rx, ry + rh, rw, radius, color, postGUI)
        dxDrawCircle(rx, ry, radius, 180, 270, color, color, 7, nil, postGUI)
        dxDrawCircle(rx + rw, ry, radius, 270, 360, color, color, 7, nil, postGUI)
        dxDrawCircle(rx, ry + rh, radius, 90, 180, color, color, 7, nil, postGUI)
        dxDrawCircle(rx + rw, ry + rh, radius, 0, 90, color, color, 7, nil, postGUI)
end

local function convertNumber(n)
        local s = tostring(math.floor(tonumber(n) or 0))
        local k
        repeat
                s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
        until k == 0
        return s
end

-- item image resolver (kept from the working inventory)
local function getImage(itemID, itemValue)
        if not itemID or not tonumber(itemID) then
                return "images/nil.png"
        end
        itemID = tonumber(itemID)
        if itemID == 16 then -- clothes
                local tmp = ("%03d"):format(tonumber(tostring(itemValue):gsub(":(.*)$", ""), 10) or 999)
                if not tmp or not tonumber(tmp) or tonumber(tmp) == 999 then
                        return "images/nil.png"
                end
                return ":account/img/" .. tmp .. ".png"
        elseif itemID == 115 then -- weapon item
                local ex = explode(':', tostring(itemValue))
                return "images/-" .. (ex[1] or 0) .. ".png"
        elseif itemID == 147 then
                if (itemValue and itemValue ~= 1) then return "images/147b.png" end
                return "images/147.png"
        elseif itemID == 152 or itemID == 133 or itemID == 153 or itemID == 154 or itemID == 155 then
                return "images/149.png"
        elseif itemID == 165 then
                if (itemValue and itemValue ~= 1) then return "images/165b.png" end
                return "images/165.png"
        elseif itemID < 0 then -- negative pseudo ids (equipped pseudo items)
                return "images/" .. itemID .. ".png"
        end
        return "images/" .. itemID .. ".png"
end

-- small value badge inside a slot (money / ammo / grams)
local function getBadge(itemID, itemValue)
        itemID = tonumber(itemID) or 0
        if itemID == 134 then
                return "$" .. convertNumber(itemValue)
        elseif itemID == 116 then
                local s = explode(':', tostring(itemValue))
                if s and s[2] then return tostring(s[2]) end
        elseif splittableItem[itemID] then
                local v = tonumber(itemValue)
                if v and v ~= 1 and itemID ~= 134 then
                        return tostring(v)
                end
        end
        return nil
end

local function getItemDisplayName(item)
        local ok, name = pcall(getItemName, item[1], item[2])
        if ok and name then return tostring(name) end
        return "Item"
end

local function getItemDescText(item)
        local ok, desc = pcall(getItemDescription, item[1], getItemValue and getItemValue(item[1], item[2]) or item[2])
        if ok and desc and desc ~= "" then return tostring(desc) end
        return nil
end

-- inventory data ------------------------------------------------------------
local function buildInventory()
        local items = getItems(localPlayer)
        if not items then inventory = false return end
        local list = {}
        for k, v in ipairs(items) do
                list[#list + 1] = { v[1], v[2], v[3], k, false }
        end
        inventory = list
end

-- main panel geometry
local function panelLayout()
        local rows = inventory and math.max(3, math.ceil(#inventory / COLS)) or 3
        local w = COLS * PITCH + GAP * 2
        local h = HEADER_H + rows * PITCH + GAP * 2 + FOOTER_H
        return sx - w - PANEL_MARGIN_X, PANEL_Y, w, h, rows
end

-- Notifications (old client toasts) ----------------------------------------
local function notificationsRender()
        local n = #notifications
        if n == 0 then return end
        local size = math.floor(50 * scale)
        local gap = math.floor(5 * scale)
        local totalW = n * (size + gap) - gap
        local bx = (sx - totalW) / 2
        local by = sy - size - math.floor(160 * scale)
        for i = 1, n do
                local nf = notifications[i]
                local x = bx + (i - 1) * (size + gap)
                local col = nf.type == "add" and tocolor(0, 255, 0, 100) or tocolor(255, 0, 0, 100)
                local bar = nf.type == "add" and tocolor(0, 255, 0) or tocolor(255, 0, 0)
                local alpha = nf.type == "add" and 230 or 200
                dxDrawRoundedRectangle(x - 1, by - 1, size + 2, size + 2, col, 6, true)
                dxDrawRoundedRectangle(x, by, size, size, tocolor(0, 8, 20, alpha), 6, true)
                dxDrawImage(x + 4 * scale, by + 4 * scale, size - 8 * scale, size - 8 * scale, nf.image, 0, 0, 0, tocolor(255, 255, 255, 255), true)
                dxDrawRectangle(x + size / 4, by + size - 3 * scale, size / 2, 3 * scale, bar, true)
        end
end

local function pushNotification(nType, image)
        table.insert(notifications, { type = nType, image = image })
        if #notifications == 1 then
                addEventHandler("onClientRender", root, notificationsRender)
        end
        setTimer(function()
                table.remove(notifications, 1)
                if #notifications == 0 then
                        removeEventHandler("onClientRender", root, notificationsRender)
                end
        end, 5000, 1)
end

-- diff the item list on every server sync -> old client add/remove toasts
local function signature(items)
        local sig = {}
        for _, v in ipairs(items or {}) do
                local key = tostring(v[1]) .. ":" .. tostring(v[2])
                sig[key] = (sig[key] or 0) + 1
        end
        return sig
end

local function recieveItemsDiff()
        local items = getItems(localPlayer)
        if not items then return end
        local now = signature(items)
        if snapshot then
                -- additions
                for key, count in pairs(now) do
                        local before = snapshot[key] or 0
                        if count > before then
                                local id = tonumber(key:match("^(-?%d+):"))
                                pushNotification("add", getImage(id, key:match(":(.*)$")))
                        end
                end
                -- removals
                for key, count in pairs(snapshot) do
                        local after = now[key] or 0
                        if after < count then
                                local id = tonumber(key:match("^(-?%d+):"))
                                pushNotification("remove", getImage(id, key:match(":(.*)$")))
                        end
                end
        end
        snapshot = now
        if show then buildInventory() end
end
addEvent("recieveItems", true)
addEventHandler("recieveItems", getRootElement(), function()
        if source == localPlayer then
                recieveItemsDiff()
        end
end)

-- render ---------------------------------------------------------------------
local function drawTooltip(x, y, item)
        local name = getItemDisplayName(item)
        if item[1] == 134 then
                name = name .. " ($" .. convertNumber(item[2]) .. ")"
        elseif item[1] ~= 116 and splittableItem[tonumber(item[1])] then
                local v = tonumber(item[2])
                if v and v ~= 1 then
                        name = name .. " (" .. v .. splittableItem[tonumber(item[1])] .. ")"
                end
        end
        local desc = getItemDescText(item)
        local text = name .. (desc and ("\n" .. desc) or "")
        local lines = desc and 2 or 1
        local w = 0
        for line in text:gmatch("[^\n]*") do
                w = math.max(w, dxGetTextWidth(line, 1, "default") + 10)
        end
        local h = 14 * scale * lines + 10
        x = math.max(10, math.min(x, sx - w - 10))
        y = math.max(10, math.min(y - h - 6, sy - h - 10))
        dxDrawRectangle(x, y, w, h, COL_TOOLTIP_BG, true)
        dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255), 1, "default", "center", "center", false, false, true)
end

local function drawMoneyRow(x, y, w)
        local money = tonumber(getElementData(localPlayer, "money")) or getPlayerMoney(localPlayer) or 0
        local size = math.floor(20 * scale)
        dxDrawImage(x + 10 * scale, y + 4 * scale, size, size, "images/134.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
        dxDrawText("$" .. convertNumber(money), x + 40 * scale, y, x + w - 2, y + 27 * scale, COL_MONEY, scale * 1.05, "default-bold", "left", "center", true, false, true)
        if isMouseInPosition(x + 2, y + 2, w - 4, 28 * scale) then
                drawTooltip(x + w / 2, y, { 134, money, 0, 0, false })
        end
end

local function drawCharRow(x, y, w)
        local charID = getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "account:character:id") or "-"
        local name = getElementData(localPlayer, "character:name")
        if not name and type(charID) == "number" and exports.cache then
                local ok, n = pcall(function() return exports.cache:getCharacterNameFromID(charID) end)
                if ok then name = n end
        end
        if type(name) == "string" then name = name:gsub("_", " ") end
        dxDrawImage(x + 10 * scale, y + 3 * scale, 18 * scale, 18 * scale, "images/149.png", 0, 0, 0, tocolor(255, 255, 255, 230), true)
        dxDrawText(tostring(name or "Unknown") .. "  #8a93a5| ID: " .. tostring(charID),
                x + 40 * scale, y, x + w - 2, y + 26 * scale, tocolor(255, 255, 255, 235), scale, "default", "left", "center", true, false, true, true)
end

local function render()
        hoverItemSlot = false
        hoverDelete = false
        hoverElement = false
        cursorOverPanel = false
        if not isCursorShowing() then
                if clickWorldItem then hideNewInventory() end
                return
        end

        -- old client dark backdrop (vertical gradient, 180-rotated feel)
        for i = 0, 19 do
                local a = COL_BACKDROP_A - i * 2
                dxDrawRectangle(0, sy * i / 20, sx, sy / 20 + 1, tocolor(0, 3, 8, a), true)
        end

        if not inventory then buildInventory() end
        if not inventory then return end

        local px, py, pw, ph, rows = panelLayout()
        dxDrawRoundedRectangle(px - 1, py - 1, pw + 2, ph + 2, COL_PANEL_EDGE, 6, true)
        dxDrawRoundedRectangle(px, py, pw, ph, COL_PANEL, 6, true)

        -- header
        local carried = getCarriedWeight(localPlayer)
        local maxW = getMaxWeight(localPlayer)
        dxDrawText("Inventory", px + 10 * scale, py, px + pw, py + HEADER_H,
                tocolor(255, 255, 255, 255), scale * 1.1, "default-bold", "left", "center", true, false, true)
        dxDrawText("#ff375f" .. tonumber(carried or 0) .. "#ffffff / " .. tonumber(maxW or 0),
                px, py + 2, px + pw - 10 * scale, py + HEADER_H,
                tocolor(255, 255, 255, 230), scale, "default-bold", "right", "center", true, false, true, true)

        -- slot grid
        local gridTop = py + HEADER_H
        for row = 0, rows - 1 do
                for col = 0, COLS - 1 do
                        local i = row * COLS + col + 1
                        local x = px + GAP + col * PITCH
                        local y = gridTop + GAP + row * PITCH
                        local item = inventory[i]
                        if item then
                                local hovered = isMouseInPosition(x, y, SLOT, SLOT)
                                local isDragged = clickItemSlot and clickItemSlot.slot == i
                                if not isDragged then
                                        dxDrawRectangle(x, y, SLOT, SLOT, hovered and COL_SLOT_OUT_H or COL_SLOT_OUT, true)
                                        dxDrawRectangle(x + 1, y + 1, SLOT - 2, SLOT - 2, COL_SLOT_IN, true)
                                        dxDrawImage(x + 2, y + 2, SLOT - 4, SLOT - 4, getImage(item[1], item[2]), 0, 0, 0, tocolor(255, 255, 255, 255), true)
                                        local badge = getBadge(item[1], item[2])
                                        if badge then
                                                dxDrawRectangle(x + 1, y + SLOT - 15 * scale - 1, SLOT - 2, 15 * scale, COL_BADGE_BG, true)
                                                dxDrawText(badge, x + 2, y + SLOT - 16 * scale, x + SLOT - 3, y + SLOT - 1,
                                                        tocolor(255, 255, 255, 230), scale * 0.85, "default-bold", "right", "bottom", true, false, true)
                                        end
                                        if hovered then
                                                hoverItemSlot = { x = x, y = y, slot = i }
                                                dxDrawRectangle(x + (SLOT - SLOT / 2) / 2, y + SLOT - 4, SLOT / 2, 4, tocolor(255, 255, 255, 255), true)
                                        end
                                end
                        else
                                dxDrawRectangle(x, y, SLOT, SLOT, COL_SLOT_EMPTY, true)
                        end
                end
        end

        -- footer: accent line + character info + money (old client had money here)
        local footY = gridTop + rows * PITCH + GAP * 2
        dxDrawRectangle(px + pw / 4, footY, pw / 2, 2, COL_ACCENT, true)
        dxDrawRectangle(px + pw / 4, footY, pw / 8, 2, COL_ACCENT_HI, true)
        drawCharRow(px, footY + 4 * scale, pw)
        drawMoneyRow(px, footY + 30 * scale, pw)

        if isMouseInPosition(px, py, pw, ph) then
                cursorOverPanel = true
        end

        -- world item hover highlight (kept from the working flow)
        if hoverWorldItem and isElement(hoverWorldItem) then
                return
        end

        -- drag visual
        if clickItemSlot and inventory[clickItemSlot.slot] then
                local cx, cy = getCursorPosition()
                cx, cy = cx * sx - SLOT / 2, cy * sy - SLOT / 2
                local item = inventory[clickItemSlot.slot]
                local col = COL_DRAG_BG
                if hoverElement then
                        local ok = false
                        local t = getElementType(hoverElement)
                        if t == "vehicle" then ok = true
                        elseif t == "player" then ok = item[1] > 0
                        elseif getElementModel(hoverElement) == 2332 then ok = true
                        elseif getElementModel(hoverElement) == 3761 then ok = true
                        elseif getElementModel(hoverElement) == 2147 then ok = true
                        end
                        col = ok and COL_MOVE_OK or COL_MOVE_NO
                end
                dxDrawRectangle(cx, cy, SLOT, SLOT, col, true)
                dxDrawImage(cx, cy, SLOT, SLOT, getImage(item[1], item[2]), 0, 0, 0, tocolor(255, 255, 255, 220), true)
        end

        -- tooltip (old dark box above the slot)
        if hoverItemSlot and not clickItemSlot then
                drawTooltip(hoverItemSlot.x + SLOT / 2, hoverItemSlot.y, inventory[hoverItemSlot.slot])
        end

        -- bottom-centre delete circle (old client bin)
        local dcx, dcy, dr = sx / 2, sy - 100 * scale, 40 * scale
        hoverDelete = isMouseInPosition(dcx - dr, dcy - dr, dr * 2, dr * 2)
        dxDrawCircle(dcx, dcy, dr, 0, 360, tocolor(10, 10, 10, 240), nil, 32, 1, true)
        local s = 14 * scale
        local lcol = tocolor(255, 0, 0, hoverDelete and 255 or 240)
        dxDrawLine(dcx - s, dcy - s, dcx + s, dcy + s, lcol, 3, true)
        dxDrawLine(dcx + s, dcy - s, dcx - s, dcy + s, lcol, 3, true)
end
-- world item hover detection (kept from the working inventory)
function getHoverElement()
        local cursorX, cursorY, absX, absY, absZ = getCursorPosition()
        -- [Fix #54] pointing at the sky leaves the world coords false/nil -
        -- processLineOfSight would log "Bad argument ... argument 4, got nil"
        if not (absX and absY and absZ) then return false end
        local cameraX, cameraY, cameraZ = getWorldFromScreenPosition(cursorX, cursorY, 0.1)

        for _, acceptProtected in ipairs({ false, true }) do
                local a, b, c, d, element = processLineOfSight(cameraX, cameraY, cameraZ, absX, absY, absZ)
                if element and not acceptProtected and getElementData(element, "protected") then
                        element = nil
                end

                if element and getElementParent(getElementParent(element)) == getResourceRootElement(getResourceFromName("item-world")) then
                        return element
                elseif b and c and d then
                        element = nil
                        local x, y, z = nil
                        local maxdist = 0.34
                        for key, value in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
                                if isElementStreamedIn(value) and isElementOnScreen(value) then
                                        x, y, z = getElementPosition(value)
                                        local dist = getDistanceBetweenPoints3D(x, y, z, b, c, d)
                                        if dist < maxdist then
                                                element = value
                                                maxdist = dist
                                        end
                                end
                        end
                        if element then
                                local px, py, pz = getElementPosition(localPlayer)
                                return getDistanceBetweenPoints3D(px, py, pz, getElementPosition(element)) < 10 and element
                        end
                end
        end
end

-- click flow -----------------------------------------------------------------
addEventHandler("onClientClick", getRootElement(), function(button, state, cursorX, cursorY, worldX, worldY, worldZ)
        if not show or waitingForItemDrop then return end
        if isPedDead(localPlayer) then return end

        local dcx, dcy, dr = sx / 2, sy - 100 * scale, 40 * scale

        if button == "left" then
                if state == "down" then
                        -- world items keep their pickup flow
                        if hoverWorldItem and isElement(hoverWorldItem) and not cursorOverPanel then
                                local x, y, z = getElementPosition(localPlayer)
                                local eX, eY, eZ = getElementPosition(hoverWorldItem)
                                if getDistanceBetweenPoints3D(x, y, z, eX, eY, eZ) <= 5 then
                                        local itemID = getElementData(hoverWorldItem, "itemID")
                                        if itemID == 169 then
                                                if not getElementData(localPlayer, "exclusiveGUI") then
                                                        triggerServerEvent("openKeypadInterface", localPlayer, hoverWorldItem)
                                                end
                                        else
                                                for _, value in ipairs(getElementsByType("player")) do
                                                        if getPedContactElement(value) == hoverWorldItem then
                                                                return
                                                        end
                                                end
                                                clickDown = getTickCount()
                                                clickWorldItem = hoverWorldItem
                                                if not getElementData(clickWorldItem, "protected") then
                                                        setElementAlpha(clickWorldItem, 127)
                                                        setElementCollisionsEnabled(clickWorldItem, false)
                                                end
                                        end
                                end
                                return
                        end
                        if hoverItemSlot and inventory[hoverItemSlot.slot] then
                                clickItemSlot = { slot = hoverItemSlot.slot, x = hoverItemSlot.x, y = hoverItemSlot.y, sx = cursorX, sy = cursorY }
                                clickDown = getTickCount()
                        end
                elseif state == "up" then
                        if clickWorldItem and isElement(clickWorldItem) then
                                setElementAlpha(clickWorldItem, 255)
                                setElementCollisionsEnabled(clickWorldItem, true)
                                local wItemID = tonumber(getElementData(clickWorldItem, "itemID"))
                                local wDist = getDistanceBetweenPoints3D(getElementPosition(localPlayer), getElementPosition(clickWorldItem))
                                local clickedItem = clickWorldItem
                                clickWorldItem = false
                                if wDist <= 5 and (wItemID == 54 or wItemID == 176) then
                                        -- ghettoblaster / speaker context menu (kept from the working flow)
                                        showItemMenu()
                                -- [Fix #49 - user] FLOOR PICKUP FIX: the old UP path
                                -- handled ONLY ghettoblasters and silently swallowed
                                -- every other click, so "PICK UP" never fired. Any
                                -- other world item now goes through the normal
                                -- pickup flow (cooldown + full check + server event).
                                elseif wDist <= 5 and wItemID then
                                        pickupItem("left", "up", clickedItem)
                                end
                                return
                        end
                        if clickItemSlot then
                                local item = inventory[clickItemSlot.slot]
                                if item then
                                        local dragDist = math.abs(cursorX - clickItemSlot.sx) + math.abs(cursorY - clickItemSlot.sy)
                                        if hoverDelete and dragDist > 12 then
                                                -- drag to the bin = destroy (old client delete circle)
                                                if item[1] == 134 then
                                                        outputChatBox("You can't destroy money.", 255, 0, 0)
                                                elseif item[1] == 48 and countItems(localPlayer, 48) == 1 and getCarriedWeight(localPlayer) - getItemWeight(48, 1) > 10 then
                                                        outputChatBox("You have too much stuff in your inventory.", 255, 0, 0)
                                                else
                                                        triggerServerEvent("destroyItem", localPlayer, item[1] < 0 and item[1] or item[4])
                                                end
                                        elseif dragDist <= 12 then
                                                -- short click = use (kept from the working inventory)
                                                useItem(item[1] < 0 and item[3] or item[4])
                                        elseif hoverElement then
                                                -- dragged onto an element = move into it
                                                if item[1] > 0 then
                                                        waitingForItemDrop = true
                                                        triggerServerEvent("moveToElement", localPlayer, hoverElement, item[4], nil, "finishItemDrop")
                                                elseif item[1] == -100 then
                                                        triggerServerEvent("moveToElement", localPlayer, hoverElement, item[4], true, "finishItemDrop")
                                                end
                                        elseif not cursorOverPanel then
                                                -- dragged out into the world = drop at cursor
                                                if getDistanceBetweenPoints3D(worldX, worldY, worldZ, getElementPosition(localPlayer)) < 10 then
                                                        if item[1] > 0 then
                                                                waitingForItemDrop = true
                                                                triggerServerEvent("dropItem", localPlayer, item[4], worldX, worldY, worldZ)
                                                        elseif item[1] == -100 then
                                                                waitingForItemDrop = true
                                                                triggerServerEvent("dropItem", localPlayer, 100, worldX, worldY, worldZ, savedArmor)
                                                        else
                                                                local slot = -item[3]
                                                                if slot >= 2 and slot <= 9 then
                                                                        openWeaponDropGUI(-item[1], item[2], worldX, worldY, worldZ)
                                                                else
                                                                        waitingForItemDrop = true
                                                                        triggerServerEvent("dropItem", localPlayer, -item[1], worldX, worldY, worldZ, item[2])
                                                                end
                                                        end
                                                end
                                        end
                                end
                                clickItemSlot = false
                                clickDown = false
                        end
                end
        elseif button == "right" and state == "up" then
                if hoverItemSlot and inventory[hoverItemSlot.slot] then
                        -- old client: right-click = USE the item
                        local item = inventory[hoverItemSlot.slot]
                        useItem(item[1] < 0 and item[3] or item[4])
                end
        end
end)

-- world item hover scan (throttled - old client did it per frame too but the
-- modern server has 1000-player perf requirements)
local hoverScanTick = 0
addEventHandler("onClientRender", root, function()
        if not show or not isCursorShowing() then
                hoverWorldItem = false
                return
        end
        local now = getTickCount()
        if now - hoverScanTick < 120 then return end
        hoverScanTick = now

        hoverWorldItem = false
        if cursorOverPanel then return end
        -- [Fix #54] THE floor-pickup killer (clientscript.log:
        -- "getElementParent ... got number '12.3984375'"): this inline ray
        -- destructured processLineOfSight with FOUR values, but the FIRST
        -- return is `hit` (bool) - so `element` was actually hitZ, a world
        -- coordinate. getElementParent(number) errored every tick, the item
        -- check never passed and hoverWorldItem never got set, so clicking a
        -- dropped item did nothing (even after Fix #53 repaired the
        -- argument count). getHoverElement() (from the working inventory)
        -- destructures all five returns correctly AND keeps the 0.34-unit
        -- near-miss fallback when the ray hits the ground next to a small
        -- item - it existed all along but was never called.
        local _, _, wx, wy, wz = getCursorPosition()
        if not (wx and wy and wz) then return end
        hoverWorldItem = getHoverElement() or false
end)

-- show / hide ------------------------------------------------------------------
function hideNewInventory()
        clickItemSlot = false
        clickDown = false
        hoverElement = false
        if clickWorldItem then
                if isElement(clickWorldItem) then
                        setElementAlpha(clickWorldItem, 255)
                        setElementCollisionsEnabled(clickWorldItem, true)
                end
                clickWorldItem = false
        end
        if show then
                show = false
                showCursor(false)
                removeEventHandler("onClientRender", root, render)
                exports["realism-system"]:showSpeedo()
        end
end
addEvent("items:inventory:hideinv", true)
addEventHandler("items:inventory:hideinv", getLocalPlayer(), hideNewInventory)

addEvent("finishItemDrop", true)
addEventHandler("finishItemDrop", getLocalPlayer(), function()
        waitingForItemDrop = false
        inventory = false
end)

local function toggleInventoryState()
        if getElementData(localPlayer, "loggedin") ~= 1 then return end
        if show then
                hideNewInventory()
                playSoundInvClose()
        else
                if getElementData(localPlayer, "adminjailed") and not exports.integration:isPlayerTrialAdmin(localPlayer) then
                        outputChatBox("You can't access your inventory in jail.", 255, 0, 0)
                        return
                end
                if getElementData(localPlayer, "viewingInterior") == 1 then return end
                if getElementData(localPlayer, "exclusiveGUI") then return end
                show = true
                inventory = false
                buildInventory()
                showCursor(true)
                addEventHandler("onClientRender", root, render)
                exports["realism-system"]:hideSpeedo()
                playSoundInvOpen()
        end
end

bindKey("i", "down", function()
        if isPedDead(localPlayer) then return end
        if getElementHealth(localPlayer) == 0 then return end
        toggleInventoryState()
end)

function hideInventory()
        hideNewInventory()
end

addEventHandler("onClientPlayerWasted", localPlayer, hideNewInventory)

-- sounds + artifacts hook (kept) ----------------------------------------------
function playSoundInvOpen()
        if fileExists(":resources/inv_open.mp3") then
                setSoundVolume(playSound(":resources/inv_open.mp3"), 0.3)
        end
end

function playSoundInvClose()
        if fileExists(":resources/inv_close.mp3") then
                setSoundVolume(playSound(":resources/inv_close.mp3"), 0.3)
        end
end

-- split / rename dialogs (kept from the working inventory) ---------------------
function splitItem(itemID, itemName, itemValue)
        local width, height = 226, 78
        local x = sx / 2 - width / 2
        local y = sy / 2 - height / 2

        showCursor(true)
        guiSetInputEnabled(true)

        local wSplitting = guiCreateWindow(x, y, width, height, itemName .. " - " .. tostring(itemValue), false)
        guiWindowSetSizable(wSplitting, false)
        local GUIEditor_Label = guiCreateLabel(12, 20, 54, 24, "Amount:", false, wSplitting)
        guiLabelSetVerticalAlign(GUIEditor_Label, "center")
        guiSetFont(GUIEditor_Label, "default-bold-small")
        local eAmount = guiCreateEdit(66, 20, 146, 24, "an integer number", false, wSplitting)
        local bOK = guiCreateButton(12, 48, 100, 21, "OK", false, wSplitting)
        local bCancel = guiCreateButton(112, 48, 100, 21, "CANCEL", false, wSplitting)

        addEventHandler("onClientGUIClick", eAmount, function() guiSetText(eAmount, "") end, false)
        addEventHandler("onClientGUIClick", bCancel, function()
                destroyElement(wSplitting)
                guiSetInputEnabled(false)
        end, false)
        addEventHandler("onClientGUIClick", bOK, function()
                local amount = tonumber(guiGetText(eAmount))
                if not amount then
                        guiSetText(wSplitting, "Amount must be number!")
                        return false
                end
                if amount % 1 ~= 0 then
                        guiSetText(wSplitting, "Amount must be integer, like 1, 2, 3...")
                        return false
                elseif amount <= 0 then
                        guiSetText(wSplitting, "Amount must be greater than 0!")
                        return false
                end
                triggerServerEvent("drugsystem:splitItem", localPlayer, localPlayer, "split", itemID, amount)
                destroyElement(wSplitting)
                guiSetInputEnabled(false)
        end, false)
end

function resetPicFrame(itemID, itemValue)
        if itemValue == 1 then
                outputChatBox("This texture is already empty.", localPlayer, 255, 0, 0)
        else
                triggerServerEvent("resetFrame", localPlayer, localPlayer, itemID, itemValue)
        end
end

function openWeaponDropGUI(itemID, itemValue, x, y, z)
        waitingForItemDrop = true
        triggerServerEvent("dropItem", localPlayer, itemID, x, y, z, itemValue)
end

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), function()
        triggerServerEvent("item-system:addPlayerArtifacts", getLocalPlayer())
end)
