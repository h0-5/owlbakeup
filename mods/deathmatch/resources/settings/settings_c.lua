--------------------------------------------------------------------------------
-- VORTEX settings — client (Fix #18)
-- Restored from the old client (backupm [rp]/settings): per-client XML
-- settings with the exact old API — getSetting / setSetting / saveSettings /
-- getUserSetting — plus onClientSettingChange + onClientSettingsReady.
-- The hud (F4 hold/right/hideClock) and UIKit (language) consume this.
--------------------------------------------------------------------------------

local xml = nil

-- old client switch list: {id, default}
local DEFAULTS = {
        { id = "language",        default = true  }, -- true = Arabic UI (UIKit)
        { id = "Hud:hold",        default = false }, -- F4 press-hold instead of toggle
        { id = "Hud:right",       default = false }, -- strip hugs the right edge
        { id = "Hud:hideClock",   default = false }, -- hide clock/date block
        { id = "AntiLag",         default = false },
        { id = "Shader:Water",    default = false },
        { id = "Shader:Vehicles", default = false },
}

function getSetting(key)
        key = tostring(key)
        local node = xml and xmlFindChild(xml, key, 0)
        if not node then
                for _, def in ipairs(DEFAULTS) do
                        if def.id == key then
                                return def.default
                        end
                end
                return false
        end
        return xmlNodeGetValue(node) == "true"
end

function setSetting(key, value)
        if not xml then return false end
        key = tostring(key)
        local node = xmlFindChild(xml, key, 0) or xmlCreateChild(xml, key)
        if not node then return false end
        xmlNodeSetValue(node, tostring(value) == "true" and "true" or "false")
        local stored = xmlNodeGetValue(node) == "true"
        triggerEvent("onClientSettingChange", localPlayer, key, stored, value == true)
        return true
end

function saveSettings()
        if xml then
                xmlSaveFile(xml)
        end
end

-- per-user server-side extras (old settings:user:sync shape)
local userSettings = {}

function getUserSetting(key)
        return userSettings[key]
end

addEvent("settings:user:sync", true)
addEventHandler("settings:user:sync", localPlayer, function(list)
        userSettings = {}
        if type(list) == "table" then
                for _, pair in ipairs(list) do
                        if pair and pair.index ~= nil then
                                userSettings[pair.index] = pair.value
                        end
                end
        end
end)

--------------------------------------------------------------------------------
-- startup (old client exact): load or create settings.xml, then announce
--------------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
        xml = xmlLoadFile("settings.xml")
        if not xml then
                xml = xmlCreateFile("settings.xml", "settings")
                for _, def in ipairs(DEFAULTS) do
                        local node = xmlCreateChild(xml, def.id)
                        if node then
                                xmlNodeSetValue(node, def.default and "true" or "false")
                        end
                end
                xmlSaveFile(xml)
        end
        -- old client fired onClientSettingsReady on every resource start so
        -- libraries (UIKit language, hud config) pick their settings up
        addEventHandler("onClientResourceStart", root, function(res)
                triggerEvent("onClientSettingsReady", getResourceRootElement(res))
        end)
        triggerEvent("onClientSettingsReady", resourceRoot)
end)

-- AntiLag switch (old client onClientSettingChange handler, exact)
addEventHandler("onClientSettingChange", localPlayer, function(key, oldValue, newValue)
        if key == "AntiLag" then
                if newValue then
                        setFarClipDistance(130)
                        setVehiclesLODDistance(40)
                        setPedsLODDistance(50)
                        setCloudsEnabled(false)
                        setBirdsEnabled(false)
                        setWorldSpecialPropertyEnabled("randomfoliage", false)
                else
                        resetFarClipDistance()
                        resetVehiclesLODDistance()
                        resetPedsLODDistance()
                        setCloudsEnabled(true)
                        setBirdsEnabled(true)
                        setWorldSpecialPropertyEnabled("randomfoliage", true)
                end
        end
end)

-- [old client] premium theme cleanup — safe no-op until the membership
-- system returns (old code used exports.hud:isHudItemExists)
addEvent("onClientCharacterSpawn", true)
addEventHandler("onClientCharacterSpawn", localPlayer, function()
        local hudRes = getResourceFromName("hud")
        if hudRes and getResourceState(hudRes) == "running" then
                local ok, exists = pcall(function() return exports.hud:isHudItemExists("special_membership:Premium") end)
                if ok and not exists then
                        pcall(function() exports.UIKit:deleteCustomTheme() end)
                end
        end
end)
