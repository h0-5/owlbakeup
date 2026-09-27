--[[ ------------------------------------------------------------------------
        Vortex scoreboard — account inspector (Fix #30).

        The user's spec for /checkid:
          "يطلب ايدي وحطه و منه تظهر قائمة فيها كل معلومات حساب:
           ايدي، اسماء الشخصيات، السريال، الايميل، اسم الحساب وغيره"

        => typing /checkid with NO argument opens an INPUT asking for the id
           (mod id / account id / session id / account or character name),
           and the answer opens a panel listing EVERYTHING the account owns:
             mod id, account id, username, email, serial, ip, register date,
             last login, rank, warns, characters (each with id / hours / ck),
             online session. Works for OFFLINE accounts too (pure DB read).

        Server side lives in s_tab.lua (checkid:lookup).
-------------------------------------------------------------------------- ]]

local eui

local WIN_W, WIN_H = 560, 540
local inputWin, inputEdit                        -- ask-for-id dialog
local okBtn, cancelBtn
local infoWin, infoGrid, closeBtn                -- result panel

local sx, sy = guiGetScreenSize()

local function ensureEui()
        if eui then return true end
        local UIKit = getResourceFromName("UIKit")
        if not UIKit or getResourceState(UIKit) ~= "running" then return false end
        eui = exports.UIKit
        return true
end

local function destroyInput()
        if inputWin and isElement(inputWin) then destroyElement(inputWin) end
        inputWin, inputEdit, okBtn, cancelBtn = nil, nil, nil, nil
end

local function destroyInfo()
        if infoWin and isElement(infoWin) then destroyElement(infoWin) end
        infoWin, infoGrid, closeBtn = nil, nil, nil
end

local function submitQuery()
        if not (inputWin and isElement(inputWin) and inputEdit and isElement(inputEdit)) then return end
        local q = tostring(eui:uiGetText(inputEdit) or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" then return end
        destroyInput()
        triggerServerEvent("checkid:lookup", localPlayer, q)
end

local function buildInputWindow()
        destroyInput()
        destroyInfo()
        if not ensureEui() then return false end

        inputWin = eui:uiCreateWindow((sx - 340) / 2, (sy - 170) / 2, 340, 170,
                { en = "Check ID", ar = "تشيك ايدي" })
        eui:uiBringToFront(inputWin)

        eui:uiCreateLabel(15, 45, 310, 22,
                { en = "Enter ID / account name:",
                  ar = "اكتب الايدي او اسم الحساب:" },
                tocolor(235, 238, 245, 235), "left", "center", inputWin)

        inputEdit = eui:uiCreateEdit(15, 75, 310, 30, "",
                { en = "mod id / account id / name", ar = "ايدي / حساب / اسم" },
                tocolor(9, 12, 17, 235), inputWin)

        okBtn = eui:uiCreateButton(15, 120, 145, 32,
                { en = "Search", ar = "بحث" }, "primary", inputWin)
        cancelBtn = eui:uiCreateButton(180, 120, 145, 32,
                { en = "Cancel", ar = "إلغاء" }, tocolor(10, 10, 10, 240), inputWin)
        return true
end

local function buildInfoWindow()
        if not ensureEui() then return false end
        destroyInfo()
        infoWin = eui:uiCreateWindow((sx - WIN_W) / 2, (sy - WIN_H) / 2, WIN_W, WIN_H,
                { en = "Account Info", ar = "معلومات الحساب" })
        eui:uiBringToFront(infoWin)

        infoGrid = eui:uiCreateGridList(10, 45, WIN_W - 20, WIN_H - 100,
                tocolor(0, 0, 0, 0), infoWin)
        eui:uiGridListAddColumn(infoGrid, "Field", 0.3)
        eui:uiGridListAddColumn(infoGrid, "Value", 0.7)
        eui:uiSetProperty(infoGrid, "row_height", 26)
        eui:uiSetProperty(infoGrid, "color_coded", true)

        closeBtn = eui:uiCreateButton(WIN_W - 130, WIN_H - 45, 115, 30,
                { en = "Close", ar = "إغلاق" }, tocolor(10, 10, 10, 240), infoWin)
        return true
end

addEvent("checkid:openInput", true)
addEventHandler("checkid:openInput", root, function(prefill)
        if prefill and prefill ~= "" then
                -- /checkid <query>: straight to the result (still shows the
                -- ask dialog first, prefilled, then submits - old client flow)
                if not buildInputWindow() then return end
                eui:uiSetText(inputEdit, tostring(prefill))
                submitQuery()
                return
        end
        buildInputWindow()
end)

addEvent("checkid:result", true)
addEventHandler("checkid:result", root, function(rows)
        if type(rows) ~= "table" then return end
        if rows.error then
                outputChatBox("[CHECKID] " .. tostring(rows.error), 255, 140, 60)
                -- let the ask dialog reopen for a corrected query
                if not (inputWin and isElement(inputWin)) then
                        buildInputWindow()
                end
                return
        end
        if not buildInfoWindow() then return end
        eui:uiGridListClear(infoGrid)
        for _, pair in ipairs(rows) do
                local row = eui:uiGridListAddRow(infoGrid)
                eui:uiGridListSetItemText(infoGrid, row, 1, tostring(pair[1] or ""))
                eui:uiGridListSetItemColor(infoGrid, row, 1, tocolor(140, 200, 255, 255))
                eui:uiGridListSetItemText(infoGrid, row, 2, tostring(pair[2] or "-"))
        end
end)

-- window buttons (UIKit click events)
addEventHandler("onClientUIClick", root, function()
        if not isElement(source) then return end
        if okBtn and source == okBtn then
                submitQuery()
        elseif cancelBtn and source == cancelBtn then
                destroyInput()
        elseif closeBtn and source == closeBtn then
                destroyInfo()
        end
end)

-- double click on the edit submits too
addEventHandler("onClientUIDoubleClick", root, function()
        if inputEdit and source == inputEdit then
                submitQuery()
        end
end)

-- enter submits while the ask dialog is up
addEventHandler("onClientKey", root, function(key, press)
        if not press or key ~= "enter" and key ~= "num_enter" then return end
        if inputWin and isElement(inputWin) and inputEdit and isElement(inputEdit) then
                submitQuery()
        end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        destroyInput()
        destroyInfo()
end)
