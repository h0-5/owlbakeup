-- [Fix #160] A5 - /checkc client character-info panel (age/job)
-- Owned exclusively by the matching Fix #160 task agent.
--
-- Raw MTA GUI in the same shape as admin-system/c_check.lua ("Player Check"):
-- one small window, one label grid, one Close button. The command itself is
-- SERVER-side (Player/s_checkc.lua, right admin.checkc); this file only
-- renders the table the server sends on "checkc:show".

local checkcWindow = nil
local checkcClose = nil
local checkcLabels = {}

local function buildCheckcWindow()
        if checkcWindow and isElement(checkcWindow) then return end
        local width, height = guiGetScreenSize()
        checkcWindow = guiCreateWindow(width - 440, 0, 430, 420, "Character Info", false)
        guiWindowSetSizable(checkcWindow, false)

        checkcLabels = {
                name     = guiCreateLabel(15, 45, 400, 22, "Name: N/A", false, checkcWindow),
                account  = guiCreateLabel(15, 71, 400, 22, "Account: N/A", false, checkcWindow),
                status   = guiCreateLabel(15, 97, 400, 22, "Status: N/A", false, checkcWindow),
                age      = guiCreateLabel(15, 123, 205, 22, "Age: N/A", false, checkcWindow),
                birthday = guiCreateLabel(225, 123, 205, 22, "Birthday: N/A", false, checkcWindow),
                gender   = guiCreateLabel(15, 149, 205, 22, "Gender: N/A", false, checkcWindow),
                body     = guiCreateLabel(225, 149, 205, 22, "Height/Weight: N/A", false, checkcWindow),
                job      = guiCreateLabel(15, 175, 400, 22, "Job: N/A", false, checkcWindow),
                faction  = guiCreateLabel(15, 201, 400, 22, "Faction: N/A", false, checkcWindow),
                hours    = guiCreateLabel(15, 227, 205, 22, "Hours played: N/A", false, checkcWindow),
                deaths   = guiCreateLabel(225, 227, 205, 22, "Deaths: N/A", false, checkcWindow),
                money    = guiCreateLabel(15, 253, 205, 22, "Cash: N/A", false, checkcWindow),
                bank     = guiCreateLabel(225, 253, 205, 22, "Bank: N/A", false, checkcWindow),
                area     = guiCreateLabel(15, 279, 400, 44, "Area: N/A", false, checkcWindow),
        }

        checkcClose = guiCreateButton(0.85, 0.9, 0.12, 0.075, "Close", true, checkcWindow)
        addEventHandler("onClientGUIClick", checkcClose, function(button, state)
                if button ~= "left" or state ~= "up" then return end
                guiSetVisible(checkcWindow, false)
                showCursor(false)
        end, false)

        guiSetVisible(checkcWindow, false)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
        buildCheckcWindow()
end)

local function setText(key, text)
        local el = checkcLabels[key]
        if el and isElement(el) then
                guiSetText(el, tostring(text))
        end
end

addEvent("checkc:show", true)
addEventHandler("checkc:show", root, function(data)
        if type(data) ~= "table" then return end
        buildCheckcWindow()
        if not (checkcWindow and isElement(checkcWindow)) then return end

        local online = data.online and "Online" or "Offline"
        setText("name", "Name: " .. tostring(data.name or "N/A"))
        setText("account", "Account: " .. tostring(data.account or "N/A")
                .. (data.id and (" (character #" .. tostring(data.id) .. ")") or ""))
        setText("status", "Status: " .. tostring(data.status or "N/A") .. "  |  " .. online)
        setText("age", "Age: " .. tostring(data.age or "N/A"))
        setText("birthday", "Birthday: " .. tostring(data.birthday or "N/A"))
        setText("gender", "Gender: " .. tostring(data.gender or "N/A"))
        setText("body", "Height/Weight: " .. tostring(data.height or "?") .. " cm / "
                .. tostring(data.weight or "?") .. " kg")
        setText("job", "Job: " .. tostring(data.job or "N/A"))
        setText("faction", "Faction: " .. tostring(data.faction or "N/A")
                .. (data.factionRank and data.factionRank ~= "-" and (" - " .. tostring(data.factionRank)) or ""))
        setText("hours", "Hours played: " .. tostring(data.hours or "N/A"))
        setText("deaths", "Deaths: " .. tostring(data.deaths or "N/A"))
        setText("money", "Cash: $" .. tostring(data.money or "N/A"))
        setText("bank", "Bank: $" .. tostring(data.bank or "N/A"))
        setText("area", "Area: " .. tostring(data.area or "N/A"))

        guiSetVisible(checkcWindow, true)
        guiBringToFront(checkcWindow)
        showCursor(true)
end)
