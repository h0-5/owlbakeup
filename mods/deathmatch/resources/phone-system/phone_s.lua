--------------------------------------------------------------------------------
-- phone-system / phone_s.lua  (server)
--
-- [Fix #54] The NEW Owl iPhone (old-client phone-system v1.0, decompiled
-- reference: backupm/[rp]/phone-system) - server side written to serve EXACTLY
-- the events the original client used, on TOP of the existing Owl data:
--   * item 2 ("Cellphone") = the phone; its itemValue = the phone number
--   * phones / phone_contacts / phone_sms tables reused 1:1 (same columns)
--   * bank_accounts + wiretransfers reused for the Wallet app
-- New tables (auto-created, zero manual SQL for the deploy):
--   phone_system_data    (per number: voucher = internet credit + notes)
--   phone_whatsapp       (persistent whatsapp messages)
--   phone_travel_tickets (airport app)
--   phone_call_log       (recents)
-- The OLD phone resource is disabled in mtaserver.conf - this resource takes
-- over the item-2 entry point (item-system useItem branch fires phone:itemUse).
--------------------------------------------------------------------------------

local CHAR_ID_KEYS = { "account:character:id", "dbid", "character:id" }

local function charID(p)
    for _, k in ipairs(CHAR_ID_KEYS) do
        local v = tonumber(getElementData(p, k))
        if v then return v end
    end
    return nil
end

local function logErr(msg)
    outputDebugString("[phone-system] " .. tostring(msg), 1, 255, 100, 100)
end

-- every mysql touch goes through here: a stopped mysql resource can never
-- kill a handler mid-way (same resilience class as Fix #46/#49)
local function db(fn, ...)
    local m = getResourceFromName("mysql")
    if not m or getResourceState(m) ~= "running" then
        logErr("mysql not running")
        return nil
    end
    local ok, a, b, c = pcall(fn, exports.mysql, ...)
    if not ok then
        logErr(a)
        return nil
    end
    return a, b, c
end

local function esc(s)
    local m = getResourceFromName("mysql")
    if m and getResourceState(m) == "running" then
        local ok, r = pcall(function() return exports.mysql:escape_string(tostring(s)) end)
        if ok then return r end
    end
    return (tostring(s):gsub("'", "''"))
end

local function q(sql)    return db(function(m) return m:query_free(sql) end) end
local function qi(sql)   return db(function(m) return m:query_insert_free(sql) end) end
local function q1(sql)   return db(function(m) return m:query_fetch_assoc(sql) end) end
local function qAll(sql)
    local handle = db(function(m) return m:query(sql) end)
    if not handle then return nil end
    local out, row = {}, nil
    while true do
        row = db(function(m) return m:fetch_assoc(handle) end)
        if not row then break end
        out[#out + 1] = row
    end
    return out
end

local function ensureTables()
    q([[CREATE TABLE IF NOT EXISTS phone_system_data (
        phonenumber VARCHAR(20) NOT NULL PRIMARY KEY,
        voucher INT NOT NULL DEFAULT 100,
        notes TEXT NULL
    ) DEFAULT CHARSET=utf8 ]])
    q([[CREATE TABLE IF NOT EXISTS phone_whatsapp (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        from_number VARCHAR(20) NOT NULL,
        to_number VARCHAR(20) NOT NULL,
        content TEXT NULL,
        message_type VARCHAR(16) NOT NULL DEFAULT 'text',
        loc_x DOUBLE NULL, loc_y DOUBLE NULL, loc_z DOUBLE NULL,
        sent_at DATETIME NOT NULL DEFAULT NOW()
    ) DEFAULT CHARSET=utf8 ]])
    q([[CREATE TABLE IF NOT EXISTS phone_travel_tickets (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        owner INT NOT NULL,
        code VARCHAR(16) NOT NULL,
        src VARCHAR(32) NOT NULL,
        dst VARCHAR(32) NOT NULL,
        price INT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT NOW()
    ) DEFAULT CHARSET=utf8 ]])
    q([[CREATE TABLE IF NOT EXISTS phone_call_log (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        from_number VARCHAR(20) NOT NULL,
        to_number VARCHAR(20) NOT NULL,
        duration INT NOT NULL DEFAULT 0,
        ended_at INT NOT NULL DEFAULT 0
    ) DEFAULT CHARSET=utf8 ]])
end
addEventHandler("onResourceStart", resourceRoot, ensureTables)

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------
local TRAVEL_PRICES = {
    ["Los Santos|San Fierro"] = 2000,  ["San Fierro|Los Santos"] = 2000,
    ["Los Santos|Las Venturas"] = 2500, ["Las Venturas|Los Santos"] = 2500,
    ["Los Santos|Cayo Perico"] = 8000,  ["Cayo Perico|Los Santos"] = 8000,
    ["San Fierro|Las Venturas"] = 2200, ["Las Venturas|San Fierro"] = 2200,
    ["San Fierro|Cayo Perico"] = 8000,  ["Cayo Perico|San Fierro"] = 8000,
    ["Las Venturas|Cayo Perico"] = 8500, ["Cayo Perico|Las Venturas"] = 8500,
}

local HOTLINES = { ["911"] = "Emergency", ["912"] = "Police", ["913"] = "Medic" }

local function moneyOK(p, amount)
    local ok, res = pcall(function() return exports.global:hasMoney(p, amount) end)
    return ok and res == true
end

local function takeCash(p, amount)
    local ok, res = pcall(function() return exports.global:takeMoney(p, amount) end)
    return ok and res == true
end

local function phoneNumbersOnPlayer(p)
    local out = {}
    pcall(function()
        local items = exports['item-system']:getItems(p)
        for _, v in ipairs(items or {}) do
            if tonumber(v[1]) == 2 and tonumber(v[2]) and tonumber(v[2]) > 0 then
                out[#out + 1] = tostring(tonumber(v[2]))
            end
        end
    end)
    return out
end

local function ownsNumber(p, number)
    number = tostring(number)
    for _, n in ipairs(phoneNumbersOnPlayer(p)) do
        if n == number then return true end
    end
    return false
end

local function onlinePlayerByNumber(number)
    number = tostring(number)
    for _, p in ipairs(getElementsByType("player")) do
        if isElement(p) and tonumber(getElementData(p, "loggedin")) == 1 and ownsNumber(p, number) then
            return p
        end
    end
    return nil
end

-- descriptor in the exact shape the decompiled client expects
-- (item.SpecialProperties.{serial, phone_number, voucher})
local function buildPhoneDescriptor(p)
    local number, hasPhoneItem = false, false
    pcall(function()
        local items = exports['item-system']:getItems(p)
        for _, v in ipairs(items or {}) do
            if tonumber(v[1]) == 2 then
                hasPhoneItem = true
                if tonumber(v[2]) and tonumber(v[2]) > 0 then
                    number = tostring(tonumber(v[2]))
                    break
                end
            end
        end
    end)
    if not hasPhoneItem then return nil end
    local voucher = 0
    if number then
        local row = q1("SELECT voucher FROM phone_system_data WHERE phonenumber='" .. esc(number) .. "' LIMIT 1")
        voucher = row and (tonumber(row.voucher) or 0) or 0
    end
    return {
        id = number or ("sim" .. tostring(math.random(100000, 999999))),
        serial = number or "N/A",
        phone_number = number,
        voucher = voucher,
    }
end

-- full payload for phone:data:request:callback
local function buildPhoneData(number)
    local data = { id = number, notes = "", contacts = {}, sms = {}, recents = {} }
    local row = q1("SELECT notes FROM phone_system_data WHERE phonenumber='" .. esc(number) .. "' LIMIT 1")
    if row then data.notes = row.notes or "" end
    local cs = qAll("SELECT entryName, entryNumber FROM phone_contacts WHERE phone='" ..
        esc(number) .. "' ORDER BY entryName LIMIT 100")
    for _, c in ipairs(cs or {}) do
        data.contacts[#data.contacts + 1] = { tostring(c.entryName), tostring(c.entryNumber) }
    end
    local sms = qAll("SELECT id, `from`, content, DATE_FORMAT(`date`,'%h:%i:%s') AS ttime FROM phone_sms " ..
        "WHERE `to`='" .. esc(number) .. "' ORDER BY id DESC LIMIT 30")
    for _, s in ipairs(sms or {}) do
        data.sms[#data.sms + 1] = {
            id = tonumber(s.id),
            from = tostring(s.from),
            text = tostring(s.content or ""),
            time = { hour = 0, minute = 0, second = 0, str = tostring(s.ttime or "") },
        }
    end
    local rc = qAll("SELECT from_number, to_number, duration, ended_at FROM phone_call_log " ..
        "WHERE from_number='" .. esc(number) .. "' OR to_number='" .. esc(number) ..
        "' ORDER BY id DESC LIMIT 20")
    for _, r in ipairs(rc or {}) do
        data.recents[#data.recents + 1] = {
            outgoing = (r.from_number == number),
            number = (r.from_number == number) and tostring(r.to_number) or tostring(r.from_number),
            duration = tonumber(r.duration) or 0,
            end_at = tonumber(r.ended_at) or 0,
        }
    end
    return data
end

--------------------------------------------------------------------------------
-- call state:  calls[player] = live call,  pending[caller] = ringing outgoing
--------------------------------------------------------------------------------
local calls, pending = {}, {}

local function endCallInternal(p)
    local c = calls[p]
    if not c then return end
    calls[p] = nil
    local peer = c.peer
    if isElement(peer) and calls[peer] and calls[peer].peer == p then
        calls[peer] = nil
        setElementData(peer, "phone:inCall", false, false)
        triggerClientEvent(peer, "onClientPlayerEndCall", peer)
    end
    setElementData(p, "phone:inCall", false, false)
    if not c.hotline and c.from and c.to then
        local dur = math.floor((getTickCount() - (c.startedAt or getTickCount())) / 1000)
        qi(string.format(
            "INSERT INTO phone_call_log (from_number, to_number, duration, ended_at) VALUES ('%s','%s',%d,%d)",
            esc(c.from), esc(c.to), dur, getRealTime().timestamp))
    end
    triggerClientEvent(p, "onClientPlayerEndCall", p)
end

addEventHandler("onPlayerQuit", root, function()
    if calls[source] then endCallInternal(source) end
    if pending[source] then pending[source] = nil end
end)
addEventHandler("onPlayerWasted", root, function() if calls[source] then endCallInternal(source) end end)

--------------------------------------------------------------------------------
-- open / data
--------------------------------------------------------------------------------
addEvent("phone:requestOpen", true)
addEventHandler("phone:requestOpen", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    if isPedDead(client) then return end
    local desc = buildPhoneDescriptor(client)
    if not desc then
        outputChatBox("ليس لديك جوال / You don't have a phone", client, 255, 120, 120)
        return
    end
    local data = desc.phone_number
        and buildPhoneData(desc.phone_number)
        or { id = desc.id, notes = "", contacts = {}, sms = {}, recents = {} }
    triggerClientEvent(client, "phone:data:request:callback", client, desc, data)
end)

-- original decompiled event name (kept so both flows work)
addEvent("phone:data:request", true)
addEventHandler("phone:data:request", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local desc = buildPhoneDescriptor(client)
    if desc and desc.phone_number then
        triggerClientEvent(client, "phone:data:request:callback", client, desc, buildPhoneData(desc.phone_number))
    end
end)

addEvent("phone:onOpen", true)
addEventHandler("phone:onOpen", root, function() end)

addEvent("phone:onClose", true)
addEventHandler("phone:onClose", root, function() end)

--------------------------------------------------------------------------------
-- telecom: SIM window (numbers registered in your name)
--------------------------------------------------------------------------------
local function sendNumberList(p)
    local cid = charID(p)
    local list = {}
    if cid then
        local rows = qAll("SELECT phonenumber FROM phones WHERE boughtby=" .. tonumber(cid) .. " LIMIT 50")
        for _, r in ipairs(rows or {}) do
            list[#list + 1] = { phone_number = tostring(r.phonenumber) }
        end
    end
    for _, n in ipairs(phoneNumbersOnPlayer(p)) do
        local dup = false
        for _, e in ipairs(list) do if e.phone_number == n then dup = true break end end
        if not dup then list[#list + 1] = { phone_number = n } end
    end
    triggerClientEvent(p, "telecom:showPhoneNumbers", p, list)
end

addEvent("telecom:requestNumbers", true)
addEventHandler("telecom:requestNumbers", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    sendNumberList(client)
end)

local function generateFreeNumber()
    for _ = 1, 40 do
        local n = "5"
        for _ = 1, 9 do n = n .. tostring(math.random(0, 9)) end
        local row = q1("SELECT phonenumber FROM phones WHERE phonenumber='" .. n .. "' LIMIT 1")
        if not row then return n end
    end
    return nil
end

addEvent("telecom:buyPhoneNumber", true)
addEventHandler("telecom:buyPhoneNumber", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local cid = charID(client)
    if not cid then return end
    if not moneyOK(client, 500) then
        outputChatBox("تحتاج $500 لشراء رقم جديد / You need $500 for a new number", client, 255, 120, 120)
        return
    end
    local number = generateFreeNumber()
    if not number then
        outputChatBox("لا توجد أرقام متاحة حالياً / No free numbers right now", client, 255, 120, 120)
        return
    end
    if not takeCash(client, 500) then return end
    qi("INSERT INTO phones (phonenumber, boughtby, secretnumber, turnedon, ringtone, phonebook) VALUES ('" ..
        number .. "'," .. tonumber(cid) .. ",0,1,1,1)")
    qi("INSERT INTO phone_system_data (phonenumber, voucher, notes) VALUES ('" .. number .. "',100,'')")
    -- the SIM card in owlbakeup terms = a Cellphone item whose value IS the number
    local given = false
    pcall(function() exports['item-system']:giveItem(client, 2, tonumber(number)) given = true end)
    if not given then
        outputChatBox("فشل تسليم الشريحة، تواصل مع الإدارة / SIM delivery failed", client, 255, 120, 120)
        return
    end
    outputChatBox("تم شراء الرقم " .. number .. " مقابل $500 / New number purchased", client, 120, 220, 120)
    sendNumberList(client)
end)

addEvent("telecom:requestSIMCard", true)
addEventHandler("telecom:requestSIMCard", root, function(number)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    number = tostring(tonumber(number) or "")
    if number == "" then return end
    local cid = charID(client)
    local owned = false
    if cid then
        local row = q1("SELECT boughtby FROM phones WHERE phonenumber='" .. esc(number) .. "' LIMIT 1")
        owned = row and (tonumber(row.boughtby) == tonumber(cid))
    end
    if not owned then owned = ownsNumber(client, number) end
    if not owned then
        outputChatBox("هذا الرقم غير مسجل باسمك / Not your number", client, 255, 120, 120)
        return
    end
    if ownsNumber(client, number) then
        outputChatBox("تملك هذه الشريحة أصلاً / You already hold this SIM", client, 255, 180, 90)
        return
    end
    if not moneyOK(client, 100) then
        outputChatBox("تحتاج $100 لشريحة جديدة / You need $100 for a SIM card", client, 255, 120, 120)
        return
    end
    if not takeCash(client, 100) then return end
    pcall(function() exports['item-system']:giveItem(client, 2, tonumber(number)) end)
    outputChatBox("تم إصدار شريحة بالرقم " .. number .. " مقابل $100 / SIM card issued", client, 120, 220, 120)
end)

addEvent("phone:SIM:remove", true)
addEventHandler("phone:SIM:remove", root, function()
    -- owlbakeup keeps the number ON the item value; physically detaching a SIM
    -- is disabled in this build until a dedicated SIM item exists
    outputChatBox("إزالة الشريحة غير متاحة حالياً / SIM removal disabled in this build", client, 255, 180, 90)
end)

--------------------------------------------------------------------------------
-- notes / contacts
--------------------------------------------------------------------------------
addEvent("phone:notes:save", true)
addEventHandler("phone:notes:save", root, function(number, text)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    number = tostring(tonumber(number) or "")
    if number == "" or not ownsNumber(client, number) then return end
    text = tostring(text or ""):sub(1, 2000)
    local row = q1("SELECT phonenumber FROM phone_system_data WHERE phonenumber='" .. esc(number) .. "' LIMIT 1")
    if row then
        q("UPDATE phone_system_data SET notes='" .. esc(text) .. "' WHERE phonenumber='" .. esc(number) .. "'")
    else
        qi("INSERT INTO phone_system_data (phonenumber, voucher, notes) VALUES ('" ..
            esc(number) .. "',100,'" .. esc(text) .. "')")
    end
end)

addEvent("phone:contacts:add", true)
addEventHandler("phone:contacts:add", root, function(number, name, phone)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    number = tostring(tonumber(number) or "")
    name = tostring(name or ""):sub(1, 25)
    phone = tostring(tonumber(phone) or "")
    if number == "" or phone == "" or not ownsNumber(client, number) then return end
    local dup = q1("SELECT id FROM phone_contacts WHERE phone='" .. esc(number) ..
        "' AND entryNumber='" .. esc(phone) .. "' LIMIT 1")
    if dup then return end
    qi("INSERT INTO phone_contacts (entryName, entryNumber, phone) VALUES ('" ..
        esc(name) .. "','" .. esc(phone) .. "','" .. esc(number) .. "')")
    triggerClientEvent(client, "phone:contacts:add:callback", client, name, phone)
end)

addEvent("phone:contacts:remove", true)
addEventHandler("phone:contacts:remove", root, function(number, phone)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    number = tostring(tonumber(number) or "")
    phone = tostring(tonumber(phone) or "")
    if number == "" or phone == "" or not ownsNumber(client, number) then return end
    q("DELETE FROM phone_contacts WHERE phone='" .. esc(number) ..
        "' AND entryNumber='" .. esc(phone) .. "' LIMIT 1")
end)

--------------------------------------------------------------------------------
-- wallet (bank_accounts reuse)
--------------------------------------------------------------------------------
addEvent("phone:requestBankAccounts", true)
addEventHandler("phone:requestBankAccounts", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local cid = charID(client)
    if not cid then return end
    local rows = qAll("SELECT code, balance FROM bank_accounts WHERE ownerType='char' AND ownerID=" ..
        tonumber(cid) .. " LIMIT 20")
    local list = {}
    for _, r in ipairs(rows or {}) do
        list[#list + 1] = { code = tostring(r.code), amount = tonumber(r.balance) or 0 }
    end
    triggerClientEvent(client, "phone:requestBankAccounts:callback", client, list)
end)

addEvent("phone:wallet:transfer", true)
addEventHandler("phone:wallet:transfer", root, function(fromAcc, toAcc, amount)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local cid = charID(client)
    if not cid then return end
    fromAcc, toAcc = tostring(fromAcc or ""), tostring(toAcc or "")
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > 20000 then
        outputChatBox("الحد الأقصى للتحويل $20000 / Max transfer is $20000", client, 255, 120, 120)
        return
    end
    local own = q1("SELECT balance FROM bank_accounts WHERE code='" .. esc(fromAcc) ..
        "' AND ownerType='char' AND ownerID=" .. tonumber(cid) .. " LIMIT 1")
    if not own then
        outputChatBox("تحويل من حسابك فقط / You can only transfer from YOUR account", client, 255, 120, 120)
        return
    end
    if (tonumber(own.balance) or 0) < amount then
        outputChatBox("الرصيد غير كافٍ / Not enough balance", client, 255, 120, 120)
        return
    end
    local target = q1("SELECT id FROM bank_accounts WHERE code='" .. esc(toAcc) .. "' LIMIT 1")
    if not target then
        outputChatBox("حساب المستلم غير موجود / Target account not found", client, 255, 120, 120)
        return
    end
    q("UPDATE bank_accounts SET balance=balance-" .. amount ..
        " WHERE code='" .. esc(fromAcc) .. "' AND ownerType='char' AND ownerID=" ..
        tonumber(cid) .. " AND balance>=" .. amount)
    q("UPDATE bank_accounts SET balance=balance+" .. amount .. " WHERE code='" .. esc(toAcc) .. "'")
    qi("INSERT INTO wiretransfers (`from`, `to`, `amount`, `reason`, `type`) VALUES ('" ..
        esc(fromAcc) .. "','" .. esc(toAcc) .. "'," .. amount .. ",'phone transfer','phone')")
    outputChatBox("تم تحويل $" .. amount .. " إلى " .. toAcc .. " / Transfer complete", client, 120, 220, 120)
end)

--------------------------------------------------------------------------------
-- whatsapp
--------------------------------------------------------------------------------
addEvent("phone:whatsapp:send", true)
addEventHandler("phone:whatsapp:send", root, function(fromNumber, toNumber, text, data)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    fromNumber = tostring(tonumber(fromNumber) or "")
    toNumber = tostring(tonumber(toNumber) or "")
    if fromNumber == "" or toNumber == "" or not ownsNumber(client, fromNumber) then return end
    text = tostring(text or ""):sub(1, 300)
    local mtype = "text"
    local lx, ly, lz = "NULL", "NULL", "NULL"
    if type(data) == "table" and data.message_type == "location" and type(data.location) == "table" then
        mtype = "location"
        lx, ly, lz = tonumber(data.location[1]) or 0, tonumber(data.location[2]) or 0, tonumber(data.location[3]) or 0
    end
    -- voucher = internet credit, server-side authority
    local row = q1("SELECT voucher FROM phone_system_data WHERE phonenumber='" .. esc(fromNumber) .. "' LIMIT 1")
    local voucher = row and (tonumber(row.voucher) or 0) or 0
    if voucher <= 0 then
        triggerClientEvent(client, "phone:whatsapp:noInternet", client)
        return
    end
    q("UPDATE phone_system_data SET voucher=voucher-1 WHERE phonenumber='" .. esc(fromNumber) .. "' AND voucher>0")
    qi(string.format(
        "INSERT INTO phone_whatsapp (from_number, to_number, content, message_type, loc_x, loc_y, loc_z) " ..
        "VALUES ('%s','%s','%s','%s',%s,%s,%s)",
        esc(fromNumber), esc(toNumber), esc(text), mtype, tostring(lx), tostring(ly), tostring(lz)))
    local target = onlinePlayerByNumber(toNumber)
    if target then
        triggerClientEvent(target, "phone:whatsapp:receive", target, toNumber, fromNumber, text,
            mtype == "location" and { message_type = "location", location = { lx, ly, lz } } or nil)
    end
end)

addEvent("phone:whatsapp:history", true)
addEventHandler("phone:whatsapp:history", root, function(number)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    number = tostring(tonumber(number) or "")
    if number == "" then return end
    local rows = qAll("SELECT id, from_number, to_number, content, message_type, loc_x, loc_y, loc_z, " ..
        "UNIX_TIMESTAMP(sent_at) AS ts FROM phone_whatsapp WHERE from_number='" .. esc(number) ..
        "' OR to_number='" .. esc(number) .. "' ORDER BY id ASC LIMIT 200")
    local out = {}
    for _, r in ipairs(rows or {}) do
        out[#out + 1] = {
            id = tonumber(r.id),
            from = tostring(r.from_number),
            to = tostring(r.to_number),
            text = tostring(r.content or ""),
            type = tostring(r.message_type or "text"),
            loc = { tonumber(r.loc_x) or 0, tonumber(r.loc_y) or 0, tonumber(r.loc_z) or 0 },
        }
    end
    triggerClientEvent(client, "phone:whatsapp:history:callback", client, number, out)
end)

--------------------------------------------------------------------------------
-- airport / travel tickets
--------------------------------------------------------------------------------
addEvent("airport:get_travel_tickets", true)
addEventHandler("airport:get_travel_tickets", root, function()
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local cid = charID(client)
    if not cid then return end
    local rows = qAll("SELECT code, src, dst, DATE_FORMAT(created_at,'%b %d %Y') AS created " ..
        "FROM phone_travel_tickets WHERE owner=" .. tonumber(cid) .. " ORDER BY id DESC LIMIT 30")
    local list = {}
    for _, r in ipairs(rows or {}) do
        list[#list + 1] = { code = tostring(r.code), from = tostring(r.src),
            to = tostring(r.dst), createdAt = tostring(r.created) }
    end
    triggerClientEvent(client, "airport:get_travel_tickets:callback", client, list)
end)

addEvent("airport:buy_ticket", true)
addEventHandler("airport:buy_ticket", root, function(src, dst)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    local cid = charID(client)
    if not cid then return end
    src, dst = tostring(src or ""), tostring(dst or "")
    local price = TRAVEL_PRICES[src .. "|" .. dst]
    if not price then return end
    if not moneyOK(client, price) then
        outputChatBox("لا تملك $" .. price .. " للتذكرة / Not enough money for the ticket", client, 255, 120, 120)
        return
    end
    if not takeCash(client, price) then return end
    local code = "WT-" .. string.format("%06d", math.random(0, 999999))
    qi("INSERT INTO phone_travel_tickets (owner, code, src, dst, price) VALUES (" ..
        tonumber(cid) .. ",'" .. esc(code) .. "','" .. esc(src) .. "','" .. esc(dst) .. "'," .. price .. ")")
    outputChatBox("تم شراء تذكرة " .. src .. " -> " .. dst .. " (" .. code .. ") / Ticket purchased", client, 120, 220, 120)
end)

--------------------------------------------------------------------------------
-- calls
--------------------------------------------------------------------------------
local function isHotline(n) return HOTLINES[tostring(n)] ~= nil end

local function dispatchHotline(p, c, msg)
    -- 911-family light dispatch: police + medic + government teams + staff
    local username = getPlayerName(p):gsub("_", " ")
    local text = "[" .. tostring(HOTLINES[tostring(c.otherNumber)] or c.otherNumber) .. "] " .. username .. ": " .. msg
    local sentTo = { [p] = true }
    for _, t in ipairs({ "Los Santos Police Department", "Los Santos Fire Department",
        "Los Santos Emergency Services", "San Andreas Highway Patrol", "Government of Los Santos" }) do
        local team = getTeamFromName(t)
        if team then
            for _, pl in ipairs(getPlayersInTeam(team)) do
                if isElement(pl) and tonumber(getElementData(pl, "loggedin")) == 1 then
                    outputChatBox(text, pl, 255, 150, 150)
                    sentTo[pl] = true
                end
            end
        end
    end
    pcall(function() exports.global:sendMessageToAdmins(text) end)
    outputChatBox("You [" .. tostring(HOTLINES[tostring(c.otherNumber)] or "911") .. "]: " .. msg, p, 180, 220, 255)
end

addEvent("phone:phoneCall", true)
addEventHandler("phone:phoneCall", root, function(toNumber, fromNumber)
    if tonumber(getElementData(client, "loggedin")) ~= 1 then return end
    if calls[client] or pending[client] then return end
    fromNumber = tostring(tonumber(fromNumber) or "")
    toNumber = tostring(tonumber(toNumber) or "")
    if fromNumber == "" then
        outputChatBox("الجوال بدون شريحة / The phone has no SIM card", client, 255, 120, 120)
        return
    end
    -- hotline: auto-accept (decompile: onClientReceiveCall type "hotline")
    if isHotline(toNumber) then
        calls[client] = { peer = client, my = fromNumber, other = toNumber,
            from = fromNumber, to = toNumber, startedAt = getTickCount(), hotline = true }
        setElementData(client, "phone:inCall", toNumber, false)
        triggerClientEvent(client, "onClientReceiveCall", client, client, toNumber,
            { client, client, toNumber, fromNumber }, "hotline")
        setTimer(function(p, num)
            if isElement(p) and calls[p] and calls[p].hotline then
                triggerClientEvent(p, "onClientPlayerStartCall", p,
                    { p, p, num, calls[p].my }, num)
                outputChatBox(tostring(HOTLINES[num]) .. " Operator: State your emergency using /p <text>.",
                    p, 180, 220, 255)
            end
        end, 1200, 1, client, toNumber)
        return
    end
    local target = onlinePlayerByNumber(toNumber)
    if not target or target == client then
        triggerClientEvent(client, "onClientNotFoundPhoneNumber", client)
        return
    end
    if calls[target] or pending[target] then
        triggerClientEvent(client, "onClientNotFoundPhoneNumber", client) -- busy
        return
    end
    pending[client] = {
        to = target, from = fromNumber, toN = toNumber, startedAt = getTickCount(),
        data = { client, target, toNumber, fromNumber },
    }
    triggerClientEvent(target, "onClientReceiveCall", target, client, fromNumber,
        pending[client].data, nil)
    -- 30s unanswered = drop the ring
    setTimer(function(caller)
        local pd = pending[caller]
        if pd then
            pending[caller] = nil
            if isElement(pd.to) then
                triggerClientEvent(pd.to, "onClientPlayerEndCall", pd.to)
            end
            triggerClientEvent(caller, "onClientNotFoundPhoneNumber", caller)
        end
    end, 30000, 1, client)
end)

addEvent("onPlayerAcceptCall", true)
addEventHandler("onPlayerAcceptCall", root, function(currentCaller, callData, callType)
    if callType == "hotline" then return end -- auto-accepted already
    local callee = client
    -- find who is ringing us
    local caller = nil
    for el, pd in pairs(pending) do
        if pd.to == callee then caller = el break end
    end
    if not caller then return end
    local pd = pending[caller]
    pending[caller] = nil
    calls[caller] = { peer = callee, my = pd.from, other = pd.toN,
        from = pd.from, to = pd.toN, startedAt = getTickCount(), data = pd.data }
    calls[callee] = { peer = caller, my = pd.toN, other = pd.from,
        from = pd.from, to = pd.toN, startedAt = getTickCount(), data = pd.data }
    setElementData(caller, "phone:inCall", pd.from, false)
    setElementData(callee, "phone:inCall", pd.toN, false)
    triggerClientEvent(caller, "onClientPlayerStartCall", caller, pd.data, pd.toN)
    triggerClientEvent(callee, "onClientPlayerStartCall", callee, pd.data, pd.from)
    local hint = "يمكنك التحدث عبر /p <نص> / Talk using /p <text>"
    outputChatBox(hint, caller, 180, 180, 180)
    outputChatBox(hint, callee, 180, 180, 180)
end)

addEvent("onPlayerEndCall", true)
addEventHandler("onPlayerEndCall", root, function()
    if calls[client] then
        endCallInternal(client)
        return
    end
    -- cancel an outgoing ring
    if pending[client] then
        local pd = pending[client]
        pending[client] = nil
        if isElement(pd.to) then
            triggerClientEvent(pd.to, "onClientPlayerEndCall", pd.to)
        end
        triggerClientEvent(client, "onClientPlayerEndCall", client)
    end
end)

-- /p <text>: talk on the current call (ported from the old talkPhone)
addCommandHandler("p", function(thePlayer, _, ...)
    local msg = table.concat({ ... }, " ")
    if msg == "" then return end
    local c = calls[thePlayer]
    if not c then
        outputChatBox("أنت لست في مكالمة / You are not on a call", thePlayer, 255, 120, 120)
        return
    end
    if c.hotline then
        dispatchHotline(thePlayer, c, msg)
        return
    end
    local other = c.peer
    if not isElement(other) or not calls[other] then
        endCallInternal(thePlayer)
        return
    end
    local username = getPlayerName(thePlayer):gsub("_", " ")
    outputChatBox("You [Cellphone]: " .. msg, thePlayer, 210, 210, 210)
    outputChatBox("(" .. username .. ") [Cellphone]: " .. msg, other, 210, 210, 210)
    -- nearby players of the speaker hear one side
    local x, y, z = getElementPosition(thePlayer)
    for _, near in ipairs(getElementsByType("player")) do
        if near ~= thePlayer and near ~= other and isElement(near)
            and getDistanceBetweenPoints3D(x, y, z, getElementPosition(near)) < 10
            and getElementDimension(near) == getElementDimension(thePlayer) then
            outputChatBox("(" .. username .. ") [Cellphone]: " .. msg, near, 180, 180, 180)
        end
    end
end)

--------------------------------------------------------------------------------
-- export for other systems (admin tools, shops, dispatchers...)
--------------------------------------------------------------------------------
function sendSystemSMS(fromName, toNumber, text)
    toNumber = tostring(tonumber(toNumber) or "")
    if toNumber == "" then return false end
    qi("INSERT INTO phone_sms (`from`, `to`, content, private) VALUES ('" ..
        esc(tostring(fromName or "System")) .. "','" .. esc(toNumber) .. "','" ..
        esc(tostring(text or "")) .. "',1)")
    local target = onlinePlayerByNumber(toNumber)
    if target then
        local rt = getRealTime()
        triggerClientEvent(target, "phone:receiveSMS", target, tostring(fromName or "System"),
            tostring(text or ""), { hour = rt.hour, minute = rt.minute, second = rt.second }, 0)
    end
    return true
end
